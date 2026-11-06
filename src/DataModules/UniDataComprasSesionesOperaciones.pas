{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesOperaciones                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de las operaciones de las sesiones de compra.            }
{******************************************************************************}
unit UniDataComprasSesionesOperaciones;

interface

uses
  System.SysUtils, System.Classes,
  DBAccess, Uni,
  UniDataComprasSesiones, inLibGridTallasInline,
  inLibComprasSesiones, inLibComprasSesionesIntf,
  Data.DB;

function BuscarColorRepetidoSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: TDataSet): Integer;
procedure ValidarColoresSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; AIncidencias: TStrings);

// Comprueba que el kit del proveedor se puede aplicar sobre la linea con
// foco: sesion activa, linea con numero, sistema de tallas asignado, kit
// existente y tallaje del kit IGUAL al de la linea (ID_AC_TALLAS_PRVKIT =
// ID_AC_PIVOT_SESLIN). Con False, AResumen lleva la advertencia para el
// usuario. Lo usan AplicarKitProveedorALinea y el form antes de abrir el
// distribuidor en modo kit (formato distribuido).
function ValidarKitSobreLineaActual(
  ADM: TdmComprasSesiones;
  AServicio: TServicioComprasSesiones;
  const ACodigoPrv, ACodigoKit: string;
  out AResumen: string): Boolean;

// Aplica un kit del proveedor (fza_proveedores_kits_det) sobre la linea
// con foco de la sesion. REGLA: el tallaje del kit (ID_AC_TALLAS_PRVKIT)
// debe COINCIDIR con el de la linea (ID_AC_PIVOT_SESLIN); si no coincide
// (o el kit no tiene sistema) devuelve False con la advertencia en
// AResumen y no aplica nada. Si coincide, cada VALOR_DESTINO_PRVKITD se
// casa por texto contra los valores del sistema para mapear su columna y
// se persiste con el mismo UPSERT que el tecleo manual en la celda
// (PersistirCantidad; cantidad 0 borra la celda). NO repinta el grid:
// tras un True el form debe RefrescarTotalesLineaActual +
// CargarCantidadesUnaLinea.
// Devuelve False si no se aplico nada; AResumen lleva el motivo o, con
// True, el detalle de tallas sin correspondencia (vacio si caso todo).
function AplicarKitProveedorALinea(
  ADM: TdmComprasSesiones;
  AGestor: TGestorGridTallas;
  AServicio: TServicioComprasSesiones;
  const ACodigoPrv, ACodigoKit: string;
  out AResumen: string): Boolean;

// Normaliza duplicados intra-sesion: para cada CODIGO_ART_TENTATIVO que
// aparece en >1 lineas, deja la primera (LINEA_SESLIN minimo) tal cual
// y marca las demas con ESDUPLICADO_SESLIN='S', ACCION='REUSAR',
// CODIGO_ART_REUSAR=el mismo codigo, para que la materializacion solo
// haga INSERT en fza_articulos una vez (la primera) y las variantes
// del mismo articulo (distinto color/SKU) reusen la cabecera. Devuelve
// el numero de lineas marcadas. Idempotente: si todas estan ya
// resueltas, devuelve 0.
function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;

// Si ACodigoTecleado coincide exactamente con una familia que tiene el
// contador activo (ESCONTADOR_ART_FAM = 'S'), genera el siguiente codigo
// de articulo (FAMILIA + relleno de PAD_ART_FAM digitos del CONTADOR_ART_FAM
// incrementado), incrementa el contador en fza_articulos_familias y
// devuelve True con ACodigoGenerado lleno.
// Si no es una familia, o la familia no tiene contador activo, devuelve
// False y ACodigoGenerado queda vacio.
function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;

// Aplica el resultado de ResolverDuplicadoSesion a la linea de sesion
// activa (debe estar en dsEdit o dsInsert):
//   - ACCION_DUPLICADO_SESLIN = 'REUSAR'
//   - CODIGO_ART_REUSAR_SESLIN / CODIGO_ART_TENTATIVO_SESLIN = CodigoArt
//   - DESCRIPCION_SESLIN, CODIGO_FAM_SESLIN, ID_AC_PIVOT_SESLIN,
//     ID_VA_PIVOT_SESLIN, ID_AC_FILA_SESLIN, ID_VA_FILA_SESLIN,
//     TIPO_LINEA_SESLIN, TIPO_ART_SESLIN, ESTRAZABLE_SESLIN,
//     TIPO_IVA_SESLIN, TIPO_CANTIDAD_SESLIN, CODIGO_VAR_SESLIN,
//     PRECIO_COMPRA_SESLIN, PRECIO_VENTA_SESLIN, REF_PRV_SESLIN
//     (si el origen NO es REF y hay RefProveedor del proveedor de la
//     cabecera).
procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);

procedure BorrarCeldasLineaSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
procedure CopiarCeldasDistribuidasSesion(AConn: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);

implementation

uses
  System.StrUtils, inLibComprasSesionesReglas,
  inLibMsgArticulos, inLibMsgCompras, UniDataCodigosBarrasSesion;

function ClaveColorDataSet(ALinea: TDataSet): string;
var
  Articulo: string;
begin
  Articulo := ALinea.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString;
  if SameText(ALinea.FieldByName('ACCION_DUPLICADO_SESLIN').AsString,
    'REUSAR') and (Trim(ALinea.FieldByName(
    'CODIGO_ART_REUSAR_SESLIN').AsString) <> '') then
    Articulo := ALinea.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString;
  Result := ClaveColorLineaSesion(Articulo,
    ALinea.FieldByName('COLOR_TEXTO_SESLIN').AsString,
    ALinea.FieldByName('PESTANA_TEXTO_SESLIN').AsString,
    ALinea.FieldByName('CODIGO_VAR_SESLIN').AsString,
    ALinea.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger);
end;

function ConsultarColoresSesion(AConn: TUniConnection;
  const ASerie, ANumero: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConn;
    Result.SQL.Text :=
      'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN, ' +
      'CODIGO_ART_REUSAR_SESLIN, ACCION_DUPLICADO_SESLIN, ' +
      'COLOR_TEXTO_SESLIN, PESTANA_TEXTO_SESLIN, ' +
      'CODIGO_VAR_SESLIN, ID_AC_PIVOT_SESLIN ' +
      'FROM fza_compras_sesiones_lineas ' +
      'WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      'ORDER BY LINEA_SESLIN';
    Result.ParamByName('s').AsString := ASerie;
    Result.ParamByName('n').AsString := ANumero;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

function BuscarColorRepetidoSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: TDataSet): Integer;
var
  Consulta: TUniQuery;
  Clave: string;
begin
  Result := 0;
  Clave := ClaveColorDataSet(ALinea);
  if Clave <> '' then
  begin
    Consulta := ConsultarColoresSesion(AConn, ASerie, ANumero);
    try
      while not Consulta.Eof and (Result = 0) do
      begin
        if (Consulta.FieldByName('LINEA_SESLIN').AsInteger <>
            ALinea.FieldByName('LINEA_SESLIN').AsInteger) and
           (ClaveColorDataSet(Consulta) = Clave) then
          Result := Consulta.FieldByName('LINEA_SESLIN').AsInteger;
        Consulta.Next;
      end;
    finally
      Consulta.Free;
    end;
  end;
end;

procedure ValidarColoresSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; AIncidencias: TStrings);
var
  Consulta: TUniQuery;
  Claves: TStringList;
  Clave: string;
  Indice: Integer;
begin
  Consulta := ConsultarColoresSesion(AConn, ASerie, ANumero);
  Claves := TStringList.Create;
  try
    while not Consulta.Eof do
    begin
      Clave := ClaveColorDataSet(Consulta);
      if Clave <> '' then
      begin
        Indice := Claves.IndexOfName(Clave);
        if Indice >= 0 then
          AIncidencias.Add(Format('Línea %d: ' +
            SErrorColorRepetidoSesion,
            [Consulta.FieldByName('LINEA_SESLIN').AsInteger,
             StrToInt(Claves.ValueFromIndex[Indice])]))
        else
          Claves.Values[Clave] :=
            Consulta.FieldByName('LINEA_SESLIN').AsString;
      end;
      Consulta.Next;
    end;
  finally
    Claves.Free;
    Consulta.Free;
  end;
end;

procedure BorrarCeldasLineaSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConn;
    Consulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s ' +
      '   AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ExecSQL;
    // Sin celdas, el coste y el PVP de sus tallas tampoco valen
    // (FZ-ISSUE-638).
    Consulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_lineas_skus_precios ' +
      ' WHERE SERIE_SES_SESLINSKU = :s ' +
      '   AND NUMERO_SES_SESLINSKU = :n ' +
      '   AND LINEA_SES_SESLINSKU = :l';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ExecSQL;
    BorrarBarrasSesion(AConn, ASerie, ANumero, ALinea);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure CopiarCeldasDistribuidasSesion(AConn: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
var
  Consulta: TUniQuery;
  bTxOwned: Boolean;
begin
  bTxOwned := not AConn.InTransaction;
  if bTxOwned then
    AConn.StartTransaction;
  try
    BorrarCeldasLineaSesion(
      AConn, ASerie, ANumero, ALineaDestino);
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConn;
      Consulta.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, ' +
        '   LINEA_SES_SESCEL, ID_FILA_SES_SESCEL, ' +
        '   CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, ' +
        '   CANTIDAD_SESCEL, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'SELECT SERIE_SES_SESCEL, NUMERO_SES_SESCEL, :ldst, ' +
        '       ID_FILA_SES_SESCEL, ' +
        '       IFNULL(NULLIF(CODIGO_ALM_SESCEL, ''''), :alm_cab), ' +
        '       ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL, ' +
        '       NOW(), :u, NOW(), :u ' +
        '  FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s ' +
        '   AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :lsrc ' +
        '   AND CANTIDAD_SESCEL > 0';
      Consulta.ParamByName('s').AsString := ASerie;
      Consulta.ParamByName('n').AsString := ANumero;
      Consulta.ParamByName('lsrc').AsInteger := ALineaOrigen;
      Consulta.ParamByName('ldst').AsInteger := ALineaDestino;
      Consulta.ParamByName('alm_cab').AsString := AAlmacenCabecera;
      Consulta.ParamByName('u').AsString := AUsuario;
      Consulta.ExecSQL;
      Consulta.SQL.Text :=
        'UPDATE fza_compras_sesiones_lineas ' +
        '   SET TOTAL_UNIDADES_SESLIN = ' +
        '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
        '            FROM fza_compras_sesiones_celdas ' +
        '           WHERE SERIE_SES_SESCEL = :s ' +
        '             AND NUMERO_SES_SESCEL = :n ' +
        '             AND LINEA_SES_SESCEL = :l), ' +
        '       TOTAL_LINEA_SESLIN = ' +
        '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
        '            FROM fza_compras_sesiones_celdas ' +
        '           WHERE SERIE_SES_SESCEL = :s ' +
        '             AND NUMERO_SES_SESCEL = :n ' +
        '             AND LINEA_SES_SESCEL = :l) * ' +
        '         PRECIO_COMPRA_SESLIN, ' +
        '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
        ' WHERE SERIE_SES_SESLIN = :s ' +
        '   AND NUMERO_SES_SESLIN = :n ' +
        '   AND LINEA_SESLIN = :l';
      Consulta.ParamByName('s').AsString := ASerie;
      Consulta.ParamByName('n').AsString := ANumero;
      Consulta.ParamByName('l').AsInteger := ALineaDestino;
      Consulta.ParamByName('u').AsString := AUsuario;
      Consulta.ExecSQL;
    finally
      FreeAndNil(Consulta);
    end;
    if bTxOwned and AConn.InTransaction then
      AConn.Commit;
  except
    if bTxOwned and AConn.InTransaction then
      AConn.Rollback;
    raise;
  end;
end;
function ValidarKitSobreLineaActual(
  ADM: TdmComprasSesiones;
  AServicio: TServicioComprasSesiones;
  const ACodigoPrv, ACodigoKit: string;
  out AResumen: string): Boolean;
var
  iAc: Integer;
  iLinea: Integer;
  oKit: TKitProveedorSesion;
  sNomKit: string;
  sNomLin: string;
begin
  Result := False;
  AResumen := '';
  if (ADM = nil) or ADM.unqryTablaG.IsEmpty then
    AResumen := SErrorSesionCompraNoActiva
  else if ADM.unqrySesionLin.IsEmpty then
    AResumen := SErrorLineaArticuloSesionNoSeleccionada
  else if not Assigned(AServicio) then
    AResumen := SErrorSesionCompraNoActiva
  else
  begin
    iLinea := ADM.unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    iAc := ADM.unqrySesionLin.FieldByName(
      'ID_AC_PIVOT_SESLIN').AsInteger;
    if iLinea <= 0 then
      AResumen := SErrorLineaSesionSinNumero
    else if iAc <= 0 then
      AResumen := SErrorSistemaTallasLineaSesionObligatorio
    else
    begin
      oKit := AServicio.ConsultarKitProveedor(
        ACodigoPrv,
        ACodigoKit,
        iAc);
      if not oKit.Encontrado then
        AResumen := Format(
          SErrorKitProveedorNoExiste,
          [ACodigoKit, ACodigoPrv])
      else
      begin
        sNomKit := Trim(oKit.NombreTallasKit);
        sNomLin := Trim(oKit.NombreTallasLinea);
        if sNomKit = '' then
          sNomKit := IntToStr(oKit.IdAcTallas);
        if sNomLin = '' then
          sNomLin := IntToStr(iAc);
        if oKit.IdAcTallas <= 0 then
          AResumen := Format(
            SErrorKitSinSistemaTallas,
            [ACodigoKit])
        else if oKit.IdAcTallas <> iAc then
          AResumen := Format(
            SErrorTallajeKitNoCoincide,
            [sNomKit, sNomLin])
        else
          Result := True;
      end;
    end;
  end;
end;

function AplicarKitProveedorALinea(
  ADM: TdmComprasSesiones;
  AGestor: TGestorGridTallas;
  AServicio: TServicioComprasSesiones;
  const ACodigoPrv, ACodigoKit: string;
  out AResumen: string): Boolean;
var
  arr: TArrPosConjunto;
  bCasada: Boolean;
  i: Integer;
  iAc: Integer;
  iAplicadas: Integer;
  iDetalle: Integer;
  iLinea: Integer;
  oDetalles: TDetallesKitProveedorSesion;
  rCantidad: Double;
  sSinCasar: string;
  sValor: string;
begin
  Result := False;
  AResumen := '';
  if AGestor = nil then
    AResumen := SErrorGestorTallasNoInicializado
  else if ValidarKitSobreLineaActual(
    ADM,
    AServicio,
    ACodigoPrv,
    ACodigoKit,
    AResumen) then
  begin
    iLinea := ADM.unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    iAc := ADM.unqrySesionLin.FieldByName(
      'ID_AC_PIVOT_SESLIN').AsInteger;
    arr := AGestor.GetPosicionesConjunto(iAc);
    iAplicadas := 0;
    sSinCasar := '';
    oDetalles := AServicio.ConsultarDetallesKitProveedor(
      ACodigoPrv,
      ACodigoKit);
    if Length(oDetalles) = 0 then
      AResumen := Format(
        SErrorKitSinTallasDefinidas,
        [ACodigoKit])
    else
    begin
      for iDetalle := 0 to High(oDetalles) do
      begin
        sValor := Trim(oDetalles[iDetalle].ValorDestino);
        rCantidad := oDetalles[iDetalle].Cantidad;
        bCasada := False;
        for i := 0 to High(arr) do
        begin
          if SameText(Trim(arr[i].Valor), sValor) then
          begin
            AGestor.PersistirCantidad(
              iLinea,
              arr[i].IdAv,
              rCantidad);
            bCasada := True;
            Inc(iAplicadas);
            Break;
          end;
        end;
        if (not bCasada) and
           (rCantidad > 0) then
        begin
          if sSinCasar <> '' then
            sSinCasar := sSinCasar + ', ';
          sSinCasar := sSinCasar + Format(
            '%s (%g)',
            [sValor, rCantidad]);
        end;
      end;
    end;
    if iAplicadas > 0 then
    begin
      Result := True;
      if sSinCasar <> '' then
        AResumen := Format(
          SAvisoTallasKitSinCorrespondencia,
          [sSinCasar]);
    end
    else if AResumen = '' then
      AResumen := SErrorTallasKitSinCorrespondencia;
  end;
end;


function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;
begin
  Result := TdmComprasSesiones.ResolverCodigoFamiliaConexion(AConn,
    ACodigoTecleado, AUsuario, ACodigoGenerado);
end;

// ---------------------------------------------------------------------------
// Reutilizacion de articulos ya existentes (ACCION_DUPLICADO=REUSAR)
// ---------------------------------------------------------------------------


procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);
var
  ds: TDataSet;
  sTipoLinea: string;
begin
  ds := nil;
  if ADM <> nil then
    ds := ADM.unqrySesionLin;
  if AResul.Encontrado and (ds <> nil) and (not ds.IsEmpty) then
  begin
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;

  // Marca REUSAR + codigo del articulo a reutilizar.
  ds.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
  ds.FieldByName('ACCION_DUPLICADO_SESLIN').AsString  := 'REUSAR';
  ds.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString := AResul.CodigoArt;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := AResul.CodigoArt;

  // El mismo modelo de otra línea de la sesión es el mismo artículo: su
  // descripción se copia aunque la sesión deje en blanco las nuevas.
  if AResul.Origen = 'SES' then
    ds.FieldByName('DESCRIPCION_SESLIN').AsString := AResul.DescripcionArt
  else
    ds.FieldByName('DESCRIPCION_SESLIN').AsString :=
      ADM.DescripcionParaLinea(AResul.DescripcionArt);
  if AResul.CodigoFam <> '' then
    ds.FieldByName('CODIGO_FAM_SESLIN').AsString := AResul.CodigoFam;
  if AResul.TipoArt <> '' then
    ds.FieldByName('TIPO_ART_SESLIN').AsString := AResul.TipoArt;
  if AResul.TipoIva <> '' then
    ds.FieldByName('TIPO_IVA_SESLIN').AsString := AResul.TipoIva;
  if AResul.TipoCantidad <> '' then
    ds.FieldByName('TIPO_CANTIDAD_SESLIN').AsString := AResul.TipoCantidad;
  if AResul.TipoVariacion <> '' then
    ds.FieldByName('CODIGO_VAR_SESLIN').AsString := AResul.TipoVariacion;
  ds.FieldByName('ESTRAZABLE_SESLIN').AsString :=
                                 IfThen(AResul.EsTrazable, 'S', 'N');

  // TIPO_LINEA segun ESVARIACION.
  if AResul.EsVariacion then sTipoLinea :=
    'MATRIZ' else sTipoLinea := 'ESCALAR';
  ds.FieldByName('TIPO_LINEA_SESLIN').AsString := sTipoLinea;

  // Ejes de variacion (pivot=tallas, fila=color). Sin tallaje en el
  // articulo no se deja el sistema por defecto del documento: no seria
  // el suyo (FZ-ISSUE-138).
  if AResul.IdAcPivot > 0 then
    ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := AResul.IdAcPivot
  else
    ds.FieldByName('ID_AC_PIVOT_SESLIN').Clear;
  if AResul.IdVaPivot <> '' then
    ds.FieldByName('ID_VA_PIVOT_SESLIN').AsString := AResul.IdVaPivot;
  if AResul.IdAcFila > 0 then
    ds.FieldByName('ID_AC_FILA_SESLIN').AsInteger := AResul.IdAcFila;
  if AResul.IdVaFila <> '' then
    ds.FieldByName('ID_VA_FILA_SESLIN').AsString := AResul.IdVaFila;

  // Coste del proveedor del modelo resuelto. Se sobrescribe siempre para
  // no dejar valores de un modelo anterior en la misma linea.
  ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := AResul.UltimoCoste;

  // PVP de referencia: precio de la tarifa de venta de la cabecera para el
  // articulo reusado. Tambien se sobrescribe siempre para que al cambiar
  // de modelo no sobreviva el precio del articulo anterior.
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat :=
    AResul.PrecioVenta;

  // Si el match vino por CODIGO_ART y conocemos la REF del proveedor
  // de la cabecera, rellenamos REF_PRV_SESLIN para la traza.
  // Si el match vino por REF, el campo ya lleva lo que el usuario
  // tecleo (y coincide con lo que hay en la BBDD).
  if (AResul.Origen = 'ART') and (AResul.RefProveedor <> '') and
     (Trim(ds.FieldByName('REF_PRV_SESLIN').AsString) = '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
  if (AResul.Origen = 'SES') and (AResul.RefProveedor <> '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
  end;
end;

function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;
var
  q : TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // Para cada (CODIGO_ART_TENTATIVO_SESLIN) que aparece >1 veces en la
    // sesion, dejamos la primera linea (LINEA_SESLIN minimo) intacta y
    // marcamos el resto como REUSAR del mismo codigo. Asi InsertarArticulo
    // solo se ejecuta una vez por codigo durante la materializacion y las
    // demas lineas (variantes color/SKU) comparten la cabecera del
    // articulo en fza_articulos.
    //
    // Solo tocamos lineas que NO tienen ACCION_DUPLICADO ya resuelta
    // (NULL / vacia / distinta de REUSAR) — respetamos elecciones del
    // usuario (p. ej. si decidio RENOMBRAR alguna ya estara con su
    // codigo final distinto, no entra en este grupo).
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones_lineas L ' +
      '  JOIN ( ' +
      '       SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '              CODIGO_ART_TENTATIVO_SESLIN, ' +
      '              MIN(LINEA_SESLIN) AS PRIMERA, ' +
      '              COUNT(*)          AS N ' +
      '         FROM fza_compras_sesiones_lineas ' +
      '        WHERE SERIE_SES_SESLIN = :s ' +
      '          AND NUMERO_SES_SESLIN = :n ' +
      '          AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
      '          AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '        GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '                 CODIGO_ART_TENTATIVO_SESLIN ' +
      '       HAVING COUNT(*) > 1 ' +
      '  ) AS G ' +
      '    ON G.SERIE_SES_SESLIN            = L.SERIE_SES_SESLIN ' +
      '   AND G.NUMERO_SES_SESLIN           = L.NUMERO_SES_SESLIN ' +
      '   AND G.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      '   SET L.ESDUPLICADO_SESLIN       = ''S'', ' +
      '       L.ACCION_DUPLICADO_SESLIN  = ''REUSAR'', ' +
      '       L.CODIGO_ART_REUSAR_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.USUARIO_MODIF            = :u, ' +
      '       L.INSTANTE_MODIF           = NOW() ' +
      ' WHERE L.SERIE_SES_SESLIN  = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
    q.ParamByName('s').AsString := ASerieSes;
    q.ParamByName('n').AsString := ANumSes;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
    Result := q.RowsAffected;
  finally
    FreeAndNil(q);
  end;
end;

end.

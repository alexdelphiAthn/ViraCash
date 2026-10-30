{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesRepositorio                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia UniDAC de las reparaciones dentro de las garantías:          }
{    fza_garantias_reclamaciones (expediente), fza_garantias_lineas,           }
{    fza_garantias_tipos y fza_garantias_liquidaciones. Cada cambio exige la   }
{    situación de partida en el WHERE y falla si no cambia ninguna fila.       }
{******************************************************************************}
unit UniDataReparacionesRepositorio;

interface

uses
  System.SysUtils, Uni, inLibReparaciones, inLibReparacionesIntf;

type
  TRepositorioReparacionesUniDAC = class(TInterfacedObject,
    ICatalogoReparaciones, IRepositorioReparaciones,
    ILiquidacionesReparaciones)
  private
    FConexion: TUniConnection;
    function NuevaConsulta(const ASql: string): TUniQuery;
    procedure Ejecutar(AConsulta: TUniQuery; AId: Int64;
      const AMensaje: string);
    procedure EnTransaccion(AAccion: TProc);
    procedure ComprobarTicketCobro(const ASerie, ANumero: string);
    procedure ComprobarSkuMaterial(const ALinea: TLineaReparacion);
    function Situacion(AReparacion: Int64;
      out ATieneLiquidaciones: Boolean): TSituacionReparacion;
    procedure InsertarPrimeraLinea(AReparacion: Int64;
      const AReparacionNueva: TReparacionNueva);
    function InsertarLinea(const ALinea: TLineaReparacion): Int64;
    procedure ModificarLinea(const ALinea: TLineaReparacion);
    function CrearLiquidacion(const ASentido, AEmpresa, AProveedor: string;
      AHasta: TDateTime; ALinea: Int64;
      const AUsuario: string): TLiquidacionReparaciones;
  public
    constructor Create(AConexion: TUniConnection);
    // ICatalogoReparaciones
    function Tipos(const ACategoria: string): TArray<TTipoServicio>;
    function Ejecutores: TArray<TEjecutorServicio>;
    // IRepositorioReparaciones
    function Alta(const AReparacion: TReparacionNueva): Int64;
    function GuardarLinea(const ALinea: TLineaReparacion): Int64;
    procedure BorrarLinea(ALinea: Int64; const AUsuario: string);
    procedure EmpezarLinea(ALinea: Int64; AFecha: TDateTime;
      const AUsuario: string);
    function TerminarLinea(ALinea: Int64; AFecha: TDateTime;
      const AUsuario: string): Int64;
    procedure DevolverLinea(ALinea: Int64; AFecha: TDateTime;
      const AIncidencia, AUsuario: string);
    procedure Presupuestar(AReparacion: Int64; ATotal: Currency;
      AFecha: TDateTime; const AUsuario: string);
    procedure ResponderPresupuesto(AReparacion: Int64; AAceptado: Boolean;
      AFecha: TDateTime; const AUsuario: string);
    procedure Entregar(AReparacion: Int64; AFecha: TDateTime;
      AEsCobrado: Boolean; const ASerieCobro, ANumeroCobro,
      AUsuario: string);
    procedure Anular(AReparacion: Int64; const AMotivo, AUsuario: string);
    // ILiquidacionesReparaciones
    function Liquidar(const ASentido, AEmpresa, AProveedor: string;
      AHasta: TDateTime; const AUsuario: string): TLiquidacionReparaciones;
    procedure EnlazarDocumento(ALiquidacion: Int64;
      const ATipoDoc, ASerie, ANumero, AUsuario: string);
    procedure AnotarAbono(ALiquidacion: Int64; AFecha: TDateTime;
      const AUsuario: string);
  end;

const
  // Expediente abierto (alias G): sin entregar ni cerrar.
  SQL_REPARACION_ABIERTA =
    'G.ESTADO_GAR IN (''ABIERTA'', ''EN_SAT'') ' +
    'AND G.FECHA_ENTREGA_CLI_GAR IS NULL';
  // Sin presupuesto o con él aceptado (alias G).
  SQL_REPARACION_PUEDE_EMPEZAR =
    '(G.ESPRESUPUESTO_GAR = ''N'' OR G.ESTADO_PRESUPUESTO_GAR = ''' +
    PRESUPUESTO_ACEPTADO + ''')';
  // Empresa del expediente: la de su tienda.
  SQL_EMPRESA_REPARACION =
    '(SELECT M.CODIGO_EMP_ALM FROM fza_almacenes M ' +
    ' WHERE M.CODIGO_ALM_ALM = G.CODIGO_ALM_GAR)';
  // Resumen de líneas por expediente (alias R) para unir a G con
  // LEFT JOIN ... R ON R.ID_GAR_GARLIN = G.ID_GAR.
  SQL_RESUMEN_LINEAS_REPARACION =
    '(SELECT L.ID_GAR_GARLIN, ' +
    '   SUM(L.TIPO_LINEA_GARLIN = ''' + LINEA_REPARACION_MANO_OBRA +
    ''') AS LINEAS_MANO_OBRA, ' +
    '   SUM(L.FECHA_INICIO_GARLIN IS NOT NULL) AS LINEAS_INICIADAS, ' +
    '   SUM(L.FECHA_FIN_GARLIN IS NOT NULL) AS LINEAS_TERMINADAS, ' +
    '   SUM(L.CANTIDAD_GARLIN * L.PRECIO_CLIENTE_GARLIN) AS TOTAL_CLIENTE, ' +
    '   SUM(L.CANTIDAD_GARLIN * L.PRECIO_COSTE_GARLIN) AS TOTAL_COSTE ' +
    '  FROM fza_garantias_lineas L GROUP BY L.ID_GAR_GARLIN)';
  // Fase del expediente (alias G y R): mismo criterio que FaseReparacion.
  SQL_FASE_REPARACION =
    'CASE WHEN G.ESTADO_GAR = ''' + ESTADO_REPARACION_ANULADA +
    ''' THEN ''' + FASE_REPARACION_ANULADO + ''' ' +
    'WHEN G.FECHA_ENTREGA_CLI_GAR IS NOT NULL THEN ''' +
    FASE_REPARACION_ENTREGADO + ''' ' +
    'WHEN G.ESPRESUPUESTO_GAR = ''S'' AND G.ESTADO_PRESUPUESTO_GAR = ''' +
    PRESUPUESTO_RECHAZADO + ''' THEN ''' + FASE_REPARACION_RECHAZADO +
    ''' ' +
    'WHEN G.ESPRESUPUESTO_GAR = ''S'' AND ' +
    'COALESCE(G.ESTADO_PRESUPUESTO_GAR, '''') <> ''' + PRESUPUESTO_ACEPTADO +
    ''' THEN ''' + FASE_REPARACION_PRESUPUESTO + ''' ' +
    'WHEN COALESCE(R.LINEAS_MANO_OBRA, 0) > 0 ' +
    ' AND R.LINEAS_TERMINADAS >= R.LINEAS_MANO_OBRA THEN ''' +
    FASE_REPARACION_REPARADO + ''' ' +
    'WHEN COALESCE(R.LINEAS_INICIADAS, 0) > 0 ' +
    '  OR G.ESTADO_GAR = ''EN_SAT'' THEN ''' +
    FASE_REPARACION_EN_REPARACION + ''' ' +
    'ELSE ''' + FASE_REPARACION_RECIBIDO + ''' END';

implementation

uses
  System.Generics.Collections, Data.DB, inLibGarantias,
  inLibMsgReparaciones;

const
  SQL_ALTA_REPARACION =
    'INSERT INTO fza_garantias_reclamaciones (' +
    'CODIGO_UNIDAD_GAR, LOTE_GAR, CODIGO_ART_GAR, CODIGO_CLI_GAR, ' +
    'SERIE_DOC_VENTA_GAR, NUMERO_DOC_VENTA_GAR, FECHA_RECLAMACION_GAR, ' +
    'MOTIVO_GAR, ESTADO_GAR, CODIGO_ALM_GAR, OBSERVACIONES_GAR, ' +
    'CODIGO_PRV_GAR, NOMBRE_CLIENTE_GAR, TELEFONO_CLIENTE_GAR, ' +
    'FECHA_RECEPCION_GAR, MODALIDAD_GAR, CODIGO_GARTIP_GAR, CATEGORIA_GAR, ' +
    'ORIGEN_OBJETO_GAR, DESCRIPCION_OBJETO_GAR, REFERENCIA_OBJETO_GAR, ' +
    'DETALLES_GAR, FECHA_PREVISTA_GAR, ESPRESUPUESTO_GAR, ' +
    'ESTADO_PRESUPUESTO_GAR, MODO_COBRO_GAR, ESCOBRADO_GAR, ' +
    'SERIE_COBRO_GAR, NUMERO_COBRO_GAR, USUARIO_ALTA) ' +
    'SELECT NULLIF(:SKU, ''''), NULLIF(:SERIE, ''''), ' +
    '(SELECT K.CODIGO_ART_SKU FROM fza_articulos_skus K ' +
    '  WHERE K.CODIGO_UNIDAD_SKU = :SKU), NULLIF(:CLIENTE, ''''), ' +
    'NULLIF(:SERIE_VENTA, ''''), NULLIF(:NUMERO_VENTA, ''''), NOW(), ' +
    ':TRABAJO, ''' + ESTADO_GARANTIA_ABIERTA + ''', :ALMACEN, ' +
    'NULLIF(:OBSERVACIONES, ''''), NULLIF(:FABRICANTE, ''''), ' +
    'NULLIF(:NOMBRE, ''''), NULLIF(:TELEFONO, ''''), :FECHA, ' +
    ':MODALIDAD, NULLIF(:TIPO, ''''), NULLIF(:CATEGORIA, ''''), :ORIGEN, ' +
    'NULLIF(:OBJETO, ''''), NULLIF(:REFERENCIA, ''''), ' +
    'NULLIF(:DETALLES, ''''), :PREVISTA, :PRESUPUESTO, ' +
    'IF(:PRESUPUESTO = ''S'', ''' + PRESUPUESTO_PENDIENTE + ''', NULL), ' +
    ':MODO_COBRO, :COBRADO, NULLIF(:SERIE_COBRO, ''''), ' +
    'NULLIF(:NUMERO_COBRO, ''''), :USUARIO';

  SQL_INSERTAR_LINEA =
    'INSERT INTO fza_garantias_lineas (ID_GAR_GARLIN, LINEA_GARLIN, ' +
    'TIPO_LINEA_GARLIN, CODIGO_GARTIP_GARLIN, DESCRIPCION_GARLIN, ' +
    'TIPO_EJECUTOR_GARLIN, CODIGO_EMPL_GARLIN, CODIGO_PRV_GARLIN, ' +
    'CODIGO_UNIDAD_GARLIN, CANTIDAD_GARLIN, PRECIO_CLIENTE_GARLIN, ' +
    'PRECIO_COSTE_GARLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT G.ID_GAR, COALESCE((SELECT MAX(L.LINEA_GARLIN) ' +
    '  FROM fza_garantias_lineas L WHERE L.ID_GAR_GARLIN = G.ID_GAR), 0) ' +
    '  + 1, :TIPO_LINEA, NULLIF(:TIPO, ''''), :DESCRIPCION, ' +
    'NULLIF(:EJECUTOR, ''''), NULLIF(:EMPLEADO, ''''), ' +
    'NULLIF(:PROVEEDOR, ''''), NULLIF(:SKU, ''''), :CANTIDAD, ' +
    ':PRECIO_CLIENTE, :PRECIO_COSTE, NOW(), :USUARIO ' +
    '  FROM fza_garantias_reclamaciones G ' +
    ' WHERE G.ID_GAR = :REPARACION AND ' + SQL_REPARACION_ABIERTA;

  // Línea editable: no empezada, sin liquidar, de un expediente abierto.
  SQL_LINEA_EDITABLE =
    ' L.FECHA_INICIO_GARLIN IS NULL AND L.FECHA_FIN_GARLIN IS NULL ' +
    'AND L.ID_GARLIQ_GARLIN IS NULL AND L.ID_GARLIQ_CARGO_GARLIN IS NULL ' +
    'AND ' + SQL_REPARACION_ABIERTA;

constructor TRepositorioReparacionesUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioReparacionesUniDAC.NuevaConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TRepositorioReparacionesUniDAC.Ejecutar(AConsulta: TUniQuery;
  AId: Int64; const AMensaje: string);
begin
  AConsulta.ParamByName('ID').AsLargeInt := AId;
  AConsulta.ExecSQL;
  if AConsulta.RowsAffected = 0 then
    raise EFaseReparacion.CreateFmt(AMensaje, [AId]);
end;

// Propietario de la transacción solo si no hay una abierta.
procedure TRepositorioReparacionesUniDAC.EnTransaccion(AAccion: TProc);
var
  bPropia: Boolean;
begin
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    AAccion();
    if bPropia then
      FConexion.Commit;
  except
    if bPropia then
      FConexion.Rollback;
    raise;
  end;
end;

function FechaOpcional(AParametro: TUniParam; AFecha: TDateTime): TUniParam;
begin
  Result := AParametro;
  Result.DataType := ftDate;
  if AFecha > 0 then
    Result.AsDate := AFecha
  else
    Result.Clear;
end;

function SN(AValor: Boolean): string;
begin
  Result := Copy('NS', Ord(AValor) + 1, 1);
end;

// ---------------------------------------------------------------------------
// Catálogo
// ---------------------------------------------------------------------------

function TRepositorioReparacionesUniDAC.Tipos(
  const ACategoria: string): TArray<TTipoServicio>;
var
  oConsulta: TUniQuery;
  oLista: TList<TTipoServicio>;
  Tipo: TTipoServicio;
begin
  oConsulta := NuevaConsulta(
    'SELECT T.CODIGO_GARTIP, T.CATEGORIA_GARTIP, T.DESCRIPCION_GARTIP, ' +
    '       T.MODALIDAD_GARTIP, T.ESPRESUPUESTO_GARTIP, ' +
    '       T.PRECIO_CLIENTE_GARTIP, T.PRECIO_COSTE_GARTIP, ' +
    '       T.CANTIDAD_GARTIP, T.MODO_COBRO_GARTIP, T.DIAS_PLAZO_GARTIP, ' +
    '       T.CODIGO_ART_GARTIP, T.TIPO_EJECUTOR_GARTIP, ' +
    '       T.CODIGO_EMPL_GARTIP, T.CODIGO_PRV_GARTIP ' +
    '  FROM fza_garantias_tipos T ' +
    ' WHERE T.ESACTIVO_GARTIP = ''S'' ' +
    '   AND (:CATEGORIA = '''' OR T.CATEGORIA_GARTIP = :CATEGORIA) ' +
    ' ORDER BY T.CATEGORIA_GARTIP, T.ORDEN_GARTIP, T.DESCRIPCION_GARTIP');
  oLista := TList<TTipoServicio>.Create;
  try
    oConsulta.ParamByName('CATEGORIA').AsString := Trim(ACategoria);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Tipo.Codigo := oConsulta.FieldByName('CODIGO_GARTIP').AsString;
      Tipo.Categoria := oConsulta.FieldByName('CATEGORIA_GARTIP').AsString;
      Tipo.Descripcion :=
        oConsulta.FieldByName('DESCRIPCION_GARTIP').AsString;
      Tipo.Modalidad := oConsulta.FieldByName('MODALIDAD_GARTIP').AsString;
      Tipo.EsPresupuesto :=
        oConsulta.FieldByName('ESPRESUPUESTO_GARTIP').AsString = 'S';
      Tipo.PrecioCliente :=
        oConsulta.FieldByName('PRECIO_CLIENTE_GARTIP').AsCurrency;
      Tipo.PrecioCoste :=
        oConsulta.FieldByName('PRECIO_COSTE_GARTIP').AsCurrency;
      Tipo.Cantidad := oConsulta.FieldByName('CANTIDAD_GARTIP').AsFloat;
      Tipo.ModoCobro := oConsulta.FieldByName('MODO_COBRO_GARTIP').AsString;
      Tipo.DiasPlazo := oConsulta.FieldByName('DIAS_PLAZO_GARTIP').AsInteger;
      Tipo.Articulo := oConsulta.FieldByName('CODIGO_ART_GARTIP').AsString;
      Tipo.TipoEjecutor :=
        oConsulta.FieldByName('TIPO_EJECUTOR_GARTIP').AsString;
      Tipo.Empleado := oConsulta.FieldByName('CODIGO_EMPL_GARTIP').AsString;
      Tipo.Proveedor := oConsulta.FieldByName('CODIGO_PRV_GARTIP').AsString;
      oLista.Add(Tipo);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
    FreeAndNil(oConsulta);
  end;
end;

// Externos: proveedores activos con facturación directa (modistas,
// autónomos) o con modo de liquidación de servicios (talleres, SAT).
function TRepositorioReparacionesUniDAC.Ejecutores:
  TArray<TEjecutorServicio>;
var
  oConsulta: TUniQuery;
  oLista: TList<TEjecutorServicio>;
  Ejecutor: TEjecutorServicio;
begin
  oConsulta := NuevaConsulta(
    'SELECT ''' + EJECUTOR_REPARACION_OPERARIO + ''' AS TIPO, ' +
    '       E.CODIGO_EMPL AS CODIGO, ' +
    '       COALESCE(NULLIF(E.NOMBRE_EMPL, ''''), E.CODIGO_EMPL) AS NOMBRE, ' +
    '       '''' AS MODO ' +
    '  FROM fza_empleados E WHERE E.ESACTIVO_EMPL = ''S'' ' +
    'UNION ALL ' +
    'SELECT ''' + EJECUTOR_REPARACION_EXTERNO + ''', P.CODIGO_PRV_PRV, ' +
    '       P.RAZON_SOCIAL_PRV, ' +
    '       COALESCE(P.MODO_LIQUIDACION_SERVICIOS_PRV, ''' +
    MODO_LIQUIDACION_PERIODICA + ''') ' +
    '  FROM fza_proveedores P ' +
    ' WHERE P.ESACTIVO_PRV = ''S'' ' +
    '   AND (P.ESFACTURACION_DIRECTA_PRV = ''S'' ' +
    '        OR P.MODO_LIQUIDACION_SERVICIOS_PRV IS NOT NULL) ' +
    'ORDER BY 1, 3');
  oLista := TList<TEjecutorServicio>.Create;
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Ejecutor.Tipo := oConsulta.FieldByName('TIPO').AsString;
      Ejecutor.Codigo := oConsulta.FieldByName('CODIGO').AsString;
      Ejecutor.Nombre := oConsulta.FieldByName('NOMBRE').AsString;
      Ejecutor.ModoLiquidacion := oConsulta.FieldByName('MODO').AsString;
      oLista.Add(Ejecutor);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
    FreeAndNil(oConsulta);
  end;
end;

// ---------------------------------------------------------------------------
// Expediente
// ---------------------------------------------------------------------------

function TRepositorioReparacionesUniDAC.Alta(
  const AReparacion: TReparacionNueva): Int64;
var
  sError: string;
  iId: Int64;
begin
  sError := ValidarReparacionNueva(AReparacion);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  if AReparacion.EsCobrado then
    ComprobarTicketCobro(AReparacion.SerieCobro, AReparacion.NumeroCobro);
  iId := 0;
  EnTransaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := NuevaConsulta(SQL_ALTA_REPARACION);
      try
        oConsulta.ParamByName('SKU').AsString := Trim(AReparacion.Sku);
        oConsulta.ParamByName('SERIE').AsString := Trim(AReparacion.Serie);
        oConsulta.ParamByName('CLIENTE').AsString :=
          Trim(AReparacion.Cliente);
        oConsulta.ParamByName('SERIE_VENTA').AsString :=
          Trim(AReparacion.SerieVenta);
        oConsulta.ParamByName('NUMERO_VENTA').AsString :=
          Trim(AReparacion.NumeroVenta);
        oConsulta.ParamByName('TRABAJO').AsString :=
          Copy(Trim(AReparacion.Trabajo), 1, 500);
        oConsulta.ParamByName('ALMACEN').AsString :=
          Trim(AReparacion.Almacen);
        oConsulta.ParamByName('OBSERVACIONES').AsString :=
          Copy(Trim(AReparacion.Observaciones), 1, 500);
        oConsulta.ParamByName('FABRICANTE').AsString :=
          Trim(AReparacion.Fabricante);
        oConsulta.ParamByName('NOMBRE').AsString :=
          Copy(Trim(AReparacion.NombreCliente), 1, 200);
        oConsulta.ParamByName('TELEFONO').AsString :=
          Copy(Trim(AReparacion.TelefonoCliente), 1, 40);
        oConsulta.ParamByName('FECHA').AsDate := AReparacion.Fecha;
        oConsulta.ParamByName('MODALIDAD').AsString := AReparacion.Modalidad;
        oConsulta.ParamByName('TIPO').AsString := AReparacion.Tipo;
        oConsulta.ParamByName('CATEGORIA').AsString := AReparacion.Categoria;
        oConsulta.ParamByName('ORIGEN').AsString := AReparacion.Origen;
        oConsulta.ParamByName('OBJETO').AsString :=
          Copy(Trim(AReparacion.DescripcionObjeto), 1, 200);
        oConsulta.ParamByName('REFERENCIA').AsString :=
          Copy(Trim(AReparacion.ReferenciaObjeto), 1, 100);
        oConsulta.ParamByName('DETALLES').AsString :=
          Copy(Trim(AReparacion.Detalles), 1, 500);
        FechaOpcional(oConsulta.ParamByName('PREVISTA'),
          AReparacion.FechaPrevista);
        oConsulta.ParamByName('PRESUPUESTO').AsString :=
          SN(AReparacion.EsPresupuesto);
        oConsulta.ParamByName('MODO_COBRO').AsString := AReparacion.ModoCobro;
        oConsulta.ParamByName('COBRADO').AsString :=
          SN(AReparacion.EsCobrado);
        oConsulta.ParamByName('SERIE_COBRO').AsString :=
          Trim(AReparacion.SerieCobro);
        oConsulta.ParamByName('NUMERO_COBRO').AsString :=
          Trim(AReparacion.NumeroCobro);
        oConsulta.ParamByName('USUARIO').AsString :=
          Copy(AReparacion.Usuario, 1, 50);
        oConsulta.ExecSQL;
        oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
        oConsulta.Open;
        iId := oConsulta.FieldByName('ID').AsLargeInt;
      finally
        FreeAndNil(oConsulta);
      end;
      InsertarPrimeraLinea(iId, AReparacion);
    end);
  Result := iId;
end;

// Solo si el alta trae algo que hacer: ejecutor o importes.
procedure TRepositorioReparacionesUniDAC.InsertarPrimeraLinea(
  AReparacion: Int64; const AReparacionNueva: TReparacionNueva);
var
  Linea: TLineaReparacion;
begin
  if (AReparacionNueva.TipoEjecutor <> '') or
     (AReparacionNueva.PrecioCliente > 0) or
     (AReparacionNueva.PrecioCoste > 0) then
  begin
    Linea := Default(TLineaReparacion);
    Linea.Reparacion := AReparacion;
    Linea.TipoLinea := LINEA_REPARACION_MANO_OBRA;
    Linea.Tipo := AReparacionNueva.Tipo;
    Linea.Descripcion := AReparacionNueva.Trabajo;
    Linea.TipoEjecutor := AReparacionNueva.TipoEjecutor;
    Linea.Empleado := AReparacionNueva.Empleado;
    Linea.Proveedor := AReparacionNueva.Proveedor;
    Linea.Cantidad := AReparacionNueva.Cantidad;
    if Linea.Cantidad <= 0 then
      Linea.Cantidad := 1;
    Linea.PrecioCliente := AReparacionNueva.PrecioCliente;
    Linea.PrecioCoste := AReparacionNueva.PrecioCoste;
    Linea.Usuario := AReparacionNueva.Usuario;
    InsertarLinea(Linea);
  end;
end;

procedure AsignarLinea(AConsulta: TUniQuery; const ALinea: TLineaReparacion);
begin
  AConsulta.ParamByName('TIPO_LINEA').AsString := ALinea.TipoLinea;
  AConsulta.ParamByName('TIPO').AsString := ALinea.Tipo;
  AConsulta.ParamByName('DESCRIPCION').AsString :=
    Copy(Trim(ALinea.Descripcion), 1, 200);
  AConsulta.ParamByName('EJECUTOR').AsString := ALinea.TipoEjecutor;
  AConsulta.ParamByName('EMPLEADO').AsString := Trim(ALinea.Empleado);
  AConsulta.ParamByName('PROVEEDOR').AsString := Trim(ALinea.Proveedor);
  AConsulta.ParamByName('SKU').AsString := Trim(ALinea.Sku);
  AConsulta.ParamByName('CANTIDAD').AsFloat := ALinea.Cantidad;
  AConsulta.ParamByName('PRECIO_CLIENTE').AsCurrency := ALinea.PrecioCliente;
  AConsulta.ParamByName('PRECIO_COSTE').AsCurrency := ALinea.PrecioCoste;
  AConsulta.ParamByName('USUARIO').AsString := Copy(ALinea.Usuario, 1, 100);
end;

function TRepositorioReparacionesUniDAC.InsertarLinea(
  const ALinea: TLineaReparacion): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(SQL_INSERTAR_LINEA);
  try
    AsignarLinea(oConsulta, ALinea);
    oConsulta.ParamByName('REPARACION').AsLargeInt := ALinea.Reparacion;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected = 0 then
      raise EFaseReparacion.CreateFmt(SErrorReparacionCerrada,
        [ALinea.Reparacion]);
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioReparacionesUniDAC.ModificarLinea(
  const ALinea: TLineaReparacion);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_lineas L ' +
    '  JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    '   SET L.TIPO_LINEA_GARLIN = :TIPO_LINEA, ' +
    '       L.CODIGO_GARTIP_GARLIN = NULLIF(:TIPO, ''''), ' +
    '       L.DESCRIPCION_GARLIN = :DESCRIPCION, ' +
    '       L.TIPO_EJECUTOR_GARLIN = NULLIF(:EJECUTOR, ''''), ' +
    '       L.CODIGO_EMPL_GARLIN = NULLIF(:EMPLEADO, ''''), ' +
    '       L.CODIGO_PRV_GARLIN = NULLIF(:PROVEEDOR, ''''), ' +
    '       L.CODIGO_UNIDAD_GARLIN = NULLIF(:SKU, ''''), ' +
    '       L.CANTIDAD_GARLIN = :CANTIDAD, ' +
    '       L.PRECIO_CLIENTE_GARLIN = :PRECIO_CLIENTE, ' +
    '       L.PRECIO_COSTE_GARLIN = :PRECIO_COSTE, ' +
    '       L.INSTANTE_MODIF = NOW(), L.USUARIO_MODIF = :USUARIO ' +
    ' WHERE L.ID_GARLIN = :ID AND L.ID_GAR_GARLIN = :REPARACION AND' +
    SQL_LINEA_EDITABLE);
  try
    AsignarLinea(oConsulta, ALinea);
    oConsulta.ParamByName('REPARACION').AsLargeInt := ALinea.Reparacion;
    Ejecutar(oConsulta, ALinea.Id, SErrorLineaNoEditableReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioReparacionesUniDAC.GuardarLinea(
  const ALinea: TLineaReparacion): Int64;
var
  sError: string;
begin
  sError := ValidarLineaReparacion(ALinea);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  ComprobarSkuMaterial(ALinea);
  Result := ALinea.Id;
  if ALinea.Id = 0 then
    Result := InsertarLinea(ALinea)
  else
    ModificarLinea(ALinea);
end;

procedure TRepositorioReparacionesUniDAC.BorrarLinea(ALinea: Int64;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'DELETE L FROM fza_garantias_lineas L ' +
    '  JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    ' WHERE L.ID_GARLIN = :ID AND' + SQL_LINEA_EDITABLE);
  try
    Ejecutar(oConsulta, ALinea, SErrorLineaNoEditableReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioReparacionesUniDAC.EmpezarLinea(ALinea: Int64;
  AFecha: TDateTime; const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_lineas L ' +
    '  JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    '   SET L.FECHA_INICIO_GARLIN = :FECHA, L.INSTANTE_MODIF = NOW(), ' +
    '       L.USUARIO_MODIF = :USUARIO ' +
    ' WHERE L.ID_GARLIN = :ID ' +
    '   AND L.TIPO_LINEA_GARLIN = ''' + LINEA_REPARACION_MANO_OBRA + ''' ' +
    '   AND L.FECHA_INICIO_GARLIN IS NULL AND L.FECHA_FIN_GARLIN IS NULL ' +
    '   AND ' + SQL_REPARACION_ABIERTA +
    '   AND ' + SQL_REPARACION_PUEDE_EMPEZAR);
  try
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
    Ejecutar(oConsulta, ALinea, SErrorEmpezarLineaReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Un operario puede terminar sin haber marcado el inicio. Si el externo
// cobra por línea, la liquidación va en la misma transacción.
function TRepositorioReparacionesUniDAC.TerminarLinea(ALinea: Int64;
  AFecha: TDateTime; const AUsuario: string): Int64;
var
  iLiquidacion: Int64;
begin
  iLiquidacion := 0;
  EnTransaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := NuevaConsulta(
        'UPDATE fza_garantias_lineas L ' +
        '  JOIN fza_garantias_reclamaciones G ' +
        '    ON G.ID_GAR = L.ID_GAR_GARLIN ' +
        '   SET L.FECHA_INICIO_GARLIN = COALESCE(L.FECHA_INICIO_GARLIN, ' +
        '         :FECHA), L.FECHA_FIN_GARLIN = :FECHA, ' +
        '       L.INSTANTE_MODIF = NOW(), L.USUARIO_MODIF = :USUARIO ' +
        ' WHERE L.ID_GARLIN = :ID ' +
        '   AND L.TIPO_LINEA_GARLIN = ''' + LINEA_REPARACION_MANO_OBRA +
        ''' AND L.FECHA_FIN_GARLIN IS NULL ' +
        '   AND ' + SQL_REPARACION_ABIERTA +
        '   AND ' + SQL_REPARACION_PUEDE_EMPEZAR);
      try
        oConsulta.ParamByName('FECHA').AsDate := AFecha;
        oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
        Ejecutar(oConsulta, ALinea, SErrorTerminarLineaReparacion);
        oConsulta.SQL.Text :=
          'SELECT L.TIPO_EJECUTOR_GARLIN, L.CODIGO_PRV_GARLIN, ' +
          '       ' + SQL_EMPRESA_REPARACION + ' AS EMPRESA, ' +
          '       COALESCE(P.MODO_LIQUIDACION_SERVICIOS_PRV, ''' +
          MODO_LIQUIDACION_PERIODICA + ''') AS MODO ' +
          '  FROM fza_garantias_lineas L ' +
          '  JOIN fza_garantias_reclamaciones G ' +
          '    ON G.ID_GAR = L.ID_GAR_GARLIN ' +
          '  LEFT JOIN fza_proveedores P ' +
          '    ON P.CODIGO_PRV_PRV = L.CODIGO_PRV_GARLIN ' +
          ' WHERE L.ID_GARLIN = :ID';
        oConsulta.ParamByName('ID').AsLargeInt := ALinea;
        oConsulta.Open;
        if LiquidaAlTerminarLinea(
          oConsulta.FieldByName('TIPO_EJECUTOR_GARLIN').AsString,
          oConsulta.FieldByName('MODO').AsString) then
          iLiquidacion := CrearLiquidacion(LIQUIDACION_REPARACION_PAGO,
            oConsulta.FieldByName('EMPRESA').AsString,
            oConsulta.FieldByName('CODIGO_PRV_GARLIN').AsString,
            AFecha, ALinea, AUsuario).Id;
      finally
        FreeAndNil(oConsulta);
      end;
    end);
  Result := iLiquidacion;
end;

procedure TRepositorioReparacionesUniDAC.DevolverLinea(ALinea: Int64;
  AFecha: TDateTime; const AIncidencia, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_lineas L ' +
    '  JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    '   SET L.FECHA_FIN_GARLIN = NULL, L.FECHA_INICIO_GARLIN = :FECHA, ' +
    '       L.ESINCIDENCIA_GARLIN = ''S'', ' +
    '       L.INCIDENCIA_GARLIN = LEFT(CONCAT_WS('' / '', ' +
    '         NULLIF(L.INCIDENCIA_GARLIN, ''''), :INCIDENCIA), 500), ' +
    '       L.INSTANTE_MODIF = NOW(), L.USUARIO_MODIF = :USUARIO ' +
    ' WHERE L.ID_GARLIN = :ID ' +
    '   AND L.TIPO_EJECUTOR_GARLIN = ''' + EJECUTOR_REPARACION_EXTERNO +
    ''' AND L.FECHA_FIN_GARLIN IS NOT NULL ' +
    '   AND ' + SQL_REPARACION_ABIERTA);
  try
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('INCIDENCIA').AsString :=
      Copy(Trim(AIncidencia), 1, 500);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
    Ejecutar(oConsulta, ALinea, SErrorDevolverLineaReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Un presupuesto nuevo sustituye al pendiente o rechazado; uno aceptado
// ya no se cambia. Solo en reparaciones que paga el cliente.
procedure TRepositorioReparacionesUniDAC.Presupuestar(AReparacion: Int64;
  ATotal: Currency; AFecha: TDateTime; const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if ATotal < 0 then
    raise EArgumentException.Create(SErrorImporteReparacion);
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_reclamaciones G ' +
    '   SET G.ESPRESUPUESTO_GAR = ''S'', G.TOTAL_PRESUPUESTO_GAR = :TOTAL, ' +
    '       G.FECHA_PRESUPUESTO_GAR = :FECHA, ' +
    '       G.ESTADO_PRESUPUESTO_GAR = ''' + PRESUPUESTO_PENDIENTE + ''', ' +
    '       G.FECHA_RESPUESTA_PRESUPUESTO_GAR = NULL, ' +
    '       G.INSTANTE_MODIF = NOW(), G.USUARIO_MODIF = :USUARIO ' +
    ' WHERE G.ID_GAR = :ID ' +
    '   AND G.MODALIDAD_GAR = ''' + MODALIDAD_REPARACION_PAGO + ''' ' +
    '   AND COALESCE(G.ESTADO_PRESUPUESTO_GAR, '''') <> ''' +
    PRESUPUESTO_ACEPTADO + ''' AND ' + SQL_REPARACION_ABIERTA);
  try
    oConsulta.ParamByName('TOTAL').AsCurrency := ATotal;
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    Ejecutar(oConsulta, AReparacion, SErrorPresupuestarReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioReparacionesUniDAC.ResponderPresupuesto(
  AReparacion: Int64; AAceptado: Boolean; AFecha: TDateTime;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_reclamaciones G ' +
    '   SET G.ESTADO_PRESUPUESTO_GAR = :ESTADO, ' +
    '       G.FECHA_RESPUESTA_PRESUPUESTO_GAR = :FECHA, ' +
    '       G.INSTANTE_MODIF = NOW(), G.USUARIO_MODIF = :USUARIO ' +
    ' WHERE G.ID_GAR = :ID AND G.ESPRESUPUESTO_GAR = ''S'' ' +
    '   AND G.ESTADO_PRESUPUESTO_GAR = ''' + PRESUPUESTO_PENDIENTE + ''' ' +
    '   AND ' + SQL_REPARACION_ABIERTA);
  try
    oConsulta.ParamByName('ESTADO').AsString := PRESUPUESTO_RECHAZADO;
    if AAceptado then
      oConsulta.ParamByName('ESTADO').AsString := PRESUPUESTO_ACEPTADO;
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    Ejecutar(oConsulta, AReparacion, SErrorResponderPresupuesto);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioReparacionesUniDAC.Situacion(AReparacion: Int64;
  out ATieneLiquidaciones: Boolean): TSituacionReparacion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TSituacionReparacion);
  oConsulta := NuevaConsulta(
    'SELECT G.ESTADO_GAR, G.FECHA_ENTREGA_CLI_GAR, G.ESPRESUPUESTO_GAR, ' +
    '       G.ESTADO_PRESUPUESTO_GAR, ' +
    '       COALESCE(SUM(L.TIPO_LINEA_GARLIN = ''' +
    LINEA_REPARACION_MANO_OBRA + '''), 0) AS MANO_OBRA, ' +
    '       COALESCE(SUM(L.FECHA_INICIO_GARLIN IS NOT NULL), 0) ' +
    '         AS INICIADAS, ' +
    '       COALESCE(SUM(L.FECHA_FIN_GARLIN IS NOT NULL), 0) AS TERMINADAS, ' +
    '       COALESCE(SUM(L.ID_GARLIQ_GARLIN IS NOT NULL ' +
    '         OR L.ID_GARLIQ_CARGO_GARLIN IS NOT NULL), 0) AS LIQUIDADAS ' +
    '  FROM fza_garantias_reclamaciones G ' +
    '  LEFT JOIN fza_garantias_lineas L ON L.ID_GAR_GARLIN = G.ID_GAR ' +
    ' WHERE G.ID_GAR = :ID ' +
    ' GROUP BY G.ID_GAR');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EFaseReparacion.CreateFmt(SErrorReparacionNoExiste,
        [AReparacion]);
    Result.Estado := oConsulta.FieldByName('ESTADO_GAR').AsString;
    Result.Entregado :=
      not oConsulta.FieldByName('FECHA_ENTREGA_CLI_GAR').IsNull;
    Result.EsPresupuesto :=
      oConsulta.FieldByName('ESPRESUPUESTO_GAR').AsString = 'S';
    Result.EstadoPresupuesto :=
      oConsulta.FieldByName('ESTADO_PRESUPUESTO_GAR').AsString;
    Result.LineasManoObra := oConsulta.FieldByName('MANO_OBRA').AsInteger;
    Result.LineasIniciadas := oConsulta.FieldByName('INICIADAS').AsInteger;
    Result.LineasTerminadas := oConsulta.FieldByName('TERMINADAS').AsInteger;
    ATieneLiquidaciones := oConsulta.FieldByName('LIQUIDADAS').AsInteger > 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Se entrega reparado (RESUELTA / REPARADA) o con el presupuesto rechazado
// (RECHAZADA). El cobro al recoger se anota con su ticket.
procedure TRepositorioReparacionesUniDAC.Entregar(AReparacion: Int64;
  AFecha: TDateTime; AEsCobrado: Boolean; const ASerieCobro, ANumeroCobro,
  AUsuario: string);
var
  oConsulta: TUniQuery;
  sFase: string;
  bLiquidada: Boolean;
begin
  sFase := FaseReparacion(Situacion(AReparacion, bLiquidada));
  if not PuedeEntregarReparacion(sFase) then
    raise EFaseReparacion.CreateFmt(SErrorEntregarReparacion, [AReparacion]);
  ComprobarTicketCobro(ASerieCobro, ANumeroCobro);
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_reclamaciones G ' +
    '   SET G.FECHA_ENTREGA_CLI_GAR = :FECHA, G.ESTADO_GAR = :ESTADO, ' +
    '       G.RESOLUCION_GAR = NULLIF(:RESOLUCION, ''''), ' +
    '       G.FECHA_RESOLUCION_GAR = NOW(), ' +
    '       G.ESCOBRADO_GAR = IF(:COBRADO = ''S'', ''S'', G.ESCOBRADO_GAR), ' +
    '       G.SERIE_COBRO_GAR = COALESCE(NULLIF(:SERIE, ''''), ' +
    '         G.SERIE_COBRO_GAR), ' +
    '       G.NUMERO_COBRO_GAR = COALESCE(NULLIF(:NUMERO, ''''), ' +
    '         G.NUMERO_COBRO_GAR), ' +
    '       G.INSTANTE_MODIF = NOW(), G.USUARIO_MODIF = :USUARIO ' +
    ' WHERE G.ID_GAR = :ID AND ' + SQL_REPARACION_ABIERTA);
  try
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('ESTADO').AsString := ESTADO_GARANTIA_RESUELTA;
    oConsulta.ParamByName('RESOLUCION').AsString :=
      RESOLUCION_GARANTIA_REPARADA;
    if sFase = FASE_REPARACION_RECHAZADO then
    begin
      oConsulta.ParamByName('ESTADO').AsString := ESTADO_GARANTIA_RECHAZADA;
      oConsulta.ParamByName('RESOLUCION').AsString := '';
    end;
    oConsulta.ParamByName('COBRADO').AsString := SN(AEsCobrado);
    oConsulta.ParamByName('SERIE').AsString := Trim(ASerieCobro);
    oConsulta.ParamByName('NUMERO').AsString := Trim(ANumeroCobro);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    Ejecutar(oConsulta, AReparacion, SErrorEntregarReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// El material sale del stock: su SKU tiene que existir.
procedure TRepositorioReparacionesUniDAC.ComprobarSkuMaterial(
  const ALinea: TLineaReparacion);
var
  oConsulta: TUniQuery;
begin
  if ALinea.TipoLinea <> LINEA_REPARACION_MATERIAL then
    Exit;
  oConsulta := NuevaConsulta(
    'SELECT 1 FROM fza_articulos_skus S ' +
    ' WHERE S.CODIGO_UNIDAD_SKU = :SKU LIMIT 1');
  try
    oConsulta.ParamByName('SKU').AsString := Trim(ALinea.Sku);
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.CreateFmt(SErrorSkuMaterialNoExiste,
        [Trim(ALinea.Sku)]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// El ticket o factura del cobro tiene que existir; vacío no se comprueba.
procedure TRepositorioReparacionesUniDAC.ComprobarTicketCobro(
  const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
begin
  if Trim(ASerie) + Trim(ANumero) = '' then
    Exit;
  oConsulta := NuevaConsulta(
    'SELECT 1 FROM fza_facturas F ' +
    ' WHERE F.SERIE_FAC = :SERIE AND F.NUMERO_FAC = :NUMERO LIMIT 1');
  try
    oConsulta.ParamByName('SERIE').AsString := Trim(ASerie);
    oConsulta.ParamByName('NUMERO').AsString := Trim(ANumero);
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.CreateFmt(SErrorTicketCobroNoExiste,
        [Trim(ASerie), Trim(ANumero)]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioReparacionesUniDAC.Anular(AReparacion: Int64;
  const AMotivo, AUsuario: string);
var
  oConsulta: TUniQuery;
  bLiquidada: Boolean;
begin
  if not PuedeAnularReparacion(FaseReparacion(Situacion(AReparacion,
    bLiquidada)), bLiquidada) then
    raise EFaseReparacion.CreateFmt(SErrorAnularReparacion, [AReparacion]);
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_reclamaciones G ' +
    '   SET G.ESTADO_GAR = ''' + ESTADO_REPARACION_ANULADA + ''', ' +
    '       G.FECHA_RESOLUCION_GAR = NOW(), ' +
    '       G.OBSERVACIONES_GAR = LEFT(CONCAT_WS('' / '', ' +
    '         NULLIF(G.OBSERVACIONES_GAR, ''''), :MOTIVO), 500), ' +
    '       G.INSTANTE_MODIF = NOW(), G.USUARIO_MODIF = :USUARIO ' +
    ' WHERE G.ID_GAR = :ID AND ' + SQL_REPARACION_ABIERTA);
  try
    oConsulta.ParamByName('MOTIVO').AsString :=
      Format(SMotivoAnulacionReparacion, [Trim(AMotivo)]);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    Ejecutar(oConsulta, AReparacion, SErrorAnularReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// ---------------------------------------------------------------------------
// Liquidaciones
// ---------------------------------------------------------------------------

// Líneas pendientes de una liquidación (alias L y G).
// PAGO: mano de obra del externo terminada, sin pagar.
// CARGO: coste de reparaciones en garantía del fabricante (mano de obra
// terminada o material de expedientes entregados), sin cargar.
function SqlLineasPendientes(const ASentido: string): string;
begin
  if ASentido = LIQUIDACION_REPARACION_PAGO then
    Result :=
      ' L.TIPO_EJECUTOR_GARLIN = ''' + EJECUTOR_REPARACION_EXTERNO + ''' ' +
      'AND L.CODIGO_PRV_GARLIN = :PROVEEDOR ' +
      'AND L.FECHA_FIN_GARLIN <= :HASTA AND L.ID_GARLIQ_GARLIN IS NULL '
  else
    Result :=
      ' G.MODALIDAD_GAR = ''' + MODALIDAD_REPARACION_GARANTIA + ''' ' +
      'AND G.CODIGO_PRV_GAR = :PROVEEDOR AND L.PRECIO_COSTE_GARLIN > 0 ' +
      'AND (L.FECHA_FIN_GARLIN <= :HASTA OR (L.TIPO_LINEA_GARLIN = ''' +
      LINEA_REPARACION_MATERIAL + ''' ' +
      '     AND G.FECHA_ENTREGA_CLI_GAR <= :HASTA)) ' +
      'AND L.ID_GARLIQ_CARGO_GARLIN IS NULL ';
  Result := Result +
    'AND G.ESTADO_GAR <> ''' + ESTADO_REPARACION_ANULADA + ''' ' +
    'AND ' + SQL_EMPRESA_REPARACION + ' = :EMPRESA ' +
    'AND (:LINEA = 0 OR L.ID_GARLIN = :LINEA)';
end;

function CampoLiquidacion(const ASentido: string): string;
begin
  if ASentido = LIQUIDACION_REPARACION_PAGO then
    Result := 'ID_GARLIQ_GARLIN'
  else
    Result := 'ID_GARLIQ_CARGO_GARLIN';
end;

procedure ParametrosPendientes(AConsulta: TUniQuery;
  const AEmpresa, AProveedor: string; AHasta: TDateTime; ALinea: Int64);
begin
  AConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
  AConsulta.ParamByName('PROVEEDOR').AsString := AProveedor;
  AConsulta.ParamByName('HASTA').AsDate := AHasta;
  AConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
end;

// La transacción la pone quien llama.
function TRepositorioReparacionesUniDAC.CrearLiquidacion(
  const ASentido, AEmpresa, AProveedor: string; AHasta: TDateTime;
  ALinea: Int64; const AUsuario: string): TLiquidacionReparaciones;
const
  SQL_DESDE =
    ' FROM fza_garantias_lineas L ' +
    ' JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    'WHERE';
var
  oConsulta: TUniQuery;
begin
  Result := Default(TLiquidacionReparaciones);
  Result.Sentido := ASentido;
  Result.Proveedor := AProveedor;
  Result.Hasta := AHasta;
  oConsulta := NuevaConsulta('SELECT COUNT(*) AS LINEAS, COALESCE(SUM(' +
    'L.CANTIDAD_GARLIN * L.PRECIO_COSTE_GARLIN), 0) AS TOTAL' + SQL_DESDE +
    SqlLineasPendientes(ASentido) + ' FOR UPDATE');
  try
    ParametrosPendientes(oConsulta, AEmpresa, AProveedor, AHasta, ALinea);
    oConsulta.Open;
    Result.Lineas := oConsulta.FieldByName('LINEAS').AsInteger;
    Result.Total := oConsulta.FieldByName('TOTAL').AsCurrency;
    if Result.Lineas > 0 then
    begin
      oConsulta.SQL.Text :=
        'INSERT INTO fza_garantias_liquidaciones (SENTIDO_GARLIQ, ' +
        'CODIGO_EMP_GARLIQ, CODIGO_PRV_GARLIQ, FECHA_GARLIQ, ' +
        'FECHA_HASTA_GARLIQ, CANTIDAD_LINEAS_GARLIQ, TOTAL_GARLIQ, ' +
        'INSTANTE_ALTA, USUARIO_ALTA) VALUES (:SENTIDO, :EMPRESA, ' +
        ':PROVEEDOR, CURDATE(), :HASTA, :LINEAS, :TOTAL, NOW(), :USUARIO)';
      oConsulta.ParamByName('SENTIDO').AsString := ASentido;
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.ParamByName('PROVEEDOR').AsString := AProveedor;
      oConsulta.ParamByName('HASTA').AsDate := AHasta;
      oConsulta.ParamByName('LINEAS').AsInteger := Result.Lineas;
      oConsulta.ParamByName('TOTAL').AsCurrency := Result.Total;
      oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
      oConsulta.ExecSQL;
      oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
      oConsulta.Open;
      Result.Id := oConsulta.FieldByName('ID').AsLargeInt;
      oConsulta.SQL.Text := 'UPDATE fza_garantias_lineas L ' +
        'JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
        'SET L.' + CampoLiquidacion(ASentido) + ' = :LIQUIDACION, ' +
        'L.INSTANTE_MODIF = NOW(), L.USUARIO_MODIF = :USUARIO WHERE' +
        SqlLineasPendientes(ASentido);
      ParametrosPendientes(oConsulta, AEmpresa, AProveedor, AHasta, ALinea);
      oConsulta.ParamByName('LIQUIDACION').AsLargeInt := Result.Id;
      oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
      oConsulta.ExecSQL;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioReparacionesUniDAC.Liquidar(const ASentido, AEmpresa,
  AProveedor: string; AHasta: TDateTime;
  const AUsuario: string): TLiquidacionReparaciones;
var
  Liquidacion: TLiquidacionReparaciones;
begin
  if (ASentido <> LIQUIDACION_REPARACION_PAGO) and
     (ASentido <> LIQUIDACION_REPARACION_CARGO) then
    raise EArgumentException.Create(SErrorSentidoLiquidacion);
  EnTransaccion(
    procedure
    begin
      Liquidacion := CrearLiquidacion(ASentido, AEmpresa, AProveedor,
        AHasta, 0, AUsuario);
    end);
  Result := Liquidacion;
end;

// Un pago se salda con una factura o autofactura de compra (FP) del mismo
// proveedor y empresa; un cargo, con una factura de venta (FA) de la
// empresa o con un abono de compra (FP) del fabricante. Nunca cancelados.
procedure TRepositorioReparacionesUniDAC.EnlazarDocumento(
  ALiquidacion: Int64; const ATipoDoc, ASerie, ANumero, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_liquidaciones Q ' +
    '   SET Q.TIPO_DOC_GARLIQ = :TIPO, Q.SERIE_DOC_GARLIQ = :SERIE, ' +
    '       Q.NUMERO_DOC_GARLIQ = :NUMERO, Q.INSTANTE_MODIF = NOW(), ' +
    '       Q.USUARIO_MODIF = :USUARIO ' +
    ' WHERE Q.ID_GARLIQ = :ID ' +
    '   AND ((:TIPO = ''FP'' AND EXISTS (SELECT 1 FROM fza_facturas_compra F ' +
    '          WHERE F.SERIE_FACC = :SERIE AND F.NUMERO_FACC = :NUMERO ' +
    '            AND F.CODIGO_PRV_FACC = Q.CODIGO_PRV_GARLIQ ' +
    '            AND F.CODIGO_EMP_FACC = Q.CODIGO_EMP_GARLIQ ' +
    '            AND COALESCE(F.ESTADO_FACC, '''') <> ''CANCELADA'')) ' +
    '     OR (:TIPO = ''FA'' AND Q.SENTIDO_GARLIQ = ''' +
    LIQUIDACION_REPARACION_CARGO + ''' ' +
    '         AND EXISTS (SELECT 1 FROM fza_facturas F ' +
    '          WHERE F.SERIE_FAC = :SERIE AND F.NUMERO_FAC = :NUMERO ' +
    '            AND F.CODIGO_EMP_FAC = Q.CODIGO_EMP_GARLIQ)))');
  try
    oConsulta.ParamByName('TIPO').AsString := UpperCase(Trim(ATipoDoc));
    oConsulta.ParamByName('SERIE').AsString := Trim(ASerie);
    oConsulta.ParamByName('NUMERO').AsString := Trim(ANumero);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
    Ejecutar(oConsulta, ALiquidacion, SErrorDocumentoLiquidacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioReparacionesUniDAC.AnotarAbono(ALiquidacion: Int64;
  AFecha: TDateTime; const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'UPDATE fza_garantias_liquidaciones Q ' +
    '   SET Q.FECHA_ABONO_GARLIQ = :FECHA, Q.INSTANTE_MODIF = NOW(), ' +
    '       Q.USUARIO_MODIF = :USUARIO ' +
    ' WHERE Q.ID_GARLIQ = :ID AND Q.SENTIDO_GARLIQ = ''' +
    LIQUIDACION_REPARACION_CARGO + ''' AND Q.FECHA_ABONO_GARLIQ IS NULL');
  try
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 100);
    Ejecutar(oConsulta, ALiquidacion, SErrorAbonoLiquidacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

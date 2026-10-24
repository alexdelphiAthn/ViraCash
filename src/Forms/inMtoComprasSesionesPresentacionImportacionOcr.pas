{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionImportacionOcr                }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la importacion de un pedido OCR sobre una sesion de compra.      }
{    Recibe datasets, vista y callbacks concretos; no conserva una referencia  }
{    al formulario. Los refrescos visuales quedan en su propietario.           }
{    en el formulario propietario.                                             }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionImportacionOcr;

interface

uses
  System.SysUtils,
  Uni,
  cxGridDBTableView,
  inLibComprasSesionesIntf,
  inLibFotosSesion,
  UniDataComprasSesiones;

type
  TAplicarDuplicadoPedidoOcr = reference to procedure(
    const AResultado: TResolverDuplicadoSesion);
  TCambiarEstadoColorPedidoOcr = reference to procedure(
    AAplicando: Boolean);
  TAsignarColorPedidoOcr = reference to procedure(
    const ALiteral: string);
  TGuardarFotosPedidoOcr = reference to procedure(
    const ASerie, ANumero: string;
    const ASolicitudes: TSolicitudesFotosSesion;
    const AUsuario: string);

  TEntornoImportacionPedidoOcr = record
    Conexion: TUniConnection;
    Datos: TdmComprasSesiones;
    Vista: TcxGridDBTableView;
    Usuario: string;
    MaximoTallas: Integer;
    ObtenerDirectorioFotos: TFunc<string>;
    AplicarDuplicado: TAplicarDuplicadoPedidoOcr;
    CambiarEstadoColor: TCambiarEstadoColorPedidoOcr;
    AsignarColorLiteral: TAsignarColorPedidoOcr;
    AsignarColorCoincidente: TProc;
    PuedeGuardarFotos: TFunc<Boolean>;
    GuardarFotos: TGuardarFotosPedidoOcr;
  end;

  TResultadoImportacionPedidoOcr = record
    Lineas: Integer;
    Fotos: Integer;
    Paginas: Integer;
    LineasSinCodigo: Integer;
    Advertencias: string;
  end;

  TCoordinadorImportacionPedidoOcr = class
  private
    FEntorno: TEntornoImportacionPedidoOcr;
  public
    constructor Create(const AEntorno: TEntornoImportacionPedidoOcr);
    function Ejecutar(
      const AFicheroJson: string): TResultadoImportacionPedidoOcr;
  end;

function FormatearResultadoImportacionPedidoOcr(
  const AResultado: TResultadoImportacionPedidoOcr): string;

implementation

uses
  System.Classes,
  System.IOUtils,
  Data.DB,
  inLibPedidoOcr,
  inLibArchivosPedidoSesion,
  inLibComprasSesiones,
  inLibComprasSesionesCodigoArticulo,
  inLibComprasSesionesReglas,
  inLibMsgCompras,
  UniDataPedidoOcr;

resourcestring
  SErrorImportacionOcrSesionConLineas =
    'La importación OCR requiere una sesión sin líneas.';
  SErrorImportacionOcrSesionNoBorrador =
    'Solo se puede importar sobre una sesión en borrador.';
  SErrorImportacionOcrProveedorNoSeleccionado =
    'Selecciona el proveedor de la sesión antes de importar.';
  SErrorImportacionOcrDirectorioFotosNoConfigurado =
    'El parámetro appDirFotos no está configurado.';
  SErrorLineaOcrSinModelo = 'La línea OCR %d no tiene modelo.';
  SErrorTallasOcrNoEncontradas =
    'Ningún sistema de hasta %d posiciones contiene las tallas ' +
    'del modelo %s: %s.';
  SErrorReservarLineasImportacionOcr =
    'No se pudo reservar el bloque de líneas de la sesión.';

const
  EXTENSIONES_FOTO_PEDIDO_OCR: array[0..5] of string = (
    '.png', '.jpg', '.jpeg', '.webp', '.bmp', '.avif');

type
  TLineaPreparadaPedidoOcr = record
    Datos: TLineaPedidoOcr;
    Tallas: TResolucionTallasPedidoOcr;
    LineaSesion: Integer;
    CodigoArticulo: string;
  end;
  TLineasPreparadasPedidoOcr = TArray<TLineaPreparadaPedidoOcr>;

  TTrabajoImportacionPedidoOcr = record
    Pedido: TPedidoOcr;
    Lineas: TLineasPreparadasPedidoOcr;
    Celdas: TCeldasPedidoOcr;
    Paginas: TArray<string>;
    Serie: string;
    Numero: string;
    Proveedor: string;
    Tarifa: string;
    DirectorioJson: string;
    DirectorioFotos: string;
    LineasSinCodigo: Integer;
  end;

function FormatearResultadoImportacionPedidoOcr(
  const AResultado: TResultadoImportacionPedidoOcr): string;
begin
  Result := Format(
    'Pedido importado: %d líneas, %d fotos y %d páginas TIFF.',
    [AResultado.Lineas, AResultado.Fotos, AResultado.Paginas]);
  if AResultado.LineasSinCodigo > 0 then
    Result := Result + sLineBreak + Format(
      '%d líneas quedan pendientes de familia y código interno.',
      [AResultado.LineasSinCodigo]);
  if Trim(AResultado.Advertencias) <> '' then
    Result := Result + sLineBreak + sLineBreak +
      'Advertencias:' + sLineBreak + Trim(AResultado.Advertencias);
end;

function ListaTallasPedidoOcr(const ALinea: TLineaPedidoOcr): string;
var
  iTalla: Integer;
begin
  Result := '';
  for iTalla := 0 to High(ALinea.Tallas) do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ALinea.Tallas[iTalla].Talla;
  end;
end;

function ResolverFotoPedidoOcr(const ADirectorio,
  ACodigo: string): string;
var
  iExtension: Integer;
  sCandidata: string;
begin
  Result := '';
  iExtension := Low(EXTENSIONES_FOTO_PEDIDO_OCR);
  while (iExtension <= High(EXTENSIONES_FOTO_PEDIDO_OCR)) and
        (Result = '') do
  begin
    sCandidata := TPath.Combine(
      TPath.Combine(ADirectorio, 'fotos'),
      ACodigo + EXTENSIONES_FOTO_PEDIDO_OCR[iExtension]);
    if TFile.Exists(sCandidata) then
      Result := sCandidata;
    Inc(iExtension);
  end;
end;

function PuedeGuardarFotosPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr): Boolean;
begin
  Result := Assigned(AEntorno.GuardarFotos);
  if Result and Assigned(AEntorno.PuedeGuardarFotos) then
    Result := AEntorno.PuedeGuardarFotos();
end;

procedure ValidarEntornoImportacionPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr);
begin
  if not Assigned(AEntorno.Conexion) then
    raise EArgumentNilException.Create('AEntorno.Conexion');
  if not Assigned(AEntorno.Datos) then
    raise EArgumentNilException.Create('AEntorno.Datos');
  if not Assigned(AEntorno.Vista) then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if not Assigned(AEntorno.AplicarDuplicado) then
    raise EArgumentNilException.Create('AEntorno.AplicarDuplicado');
  if not Assigned(AEntorno.ObtenerDirectorioFotos) then
    raise EArgumentNilException.Create(
      'AEntorno.ObtenerDirectorioFotos');
  if AEntorno.MaximoTallas <= 0 then
    raise EArgumentException.Create('AEntorno.MaximoTallas');
end;

procedure ValidarSesionImportacionPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
begin
  if AEntorno.Datos.unqryTablaG.IsEmpty then
    raise Exception.Create(SErrorSesionCompraNoActiva);
  if not AEntorno.Datos.unqrySesionLin.IsEmpty then
    raise Exception.Create(
      SErrorImportacionOcrSesionConLineas);
  if not SameText(
    Trim(AEntorno.Datos.unqryTablaG.FieldByName(
      'ESTADO_SES').AsString),
    'BORRADOR') then
    raise Exception.Create(
      SErrorImportacionOcrSesionNoBorrador);
  ATrabajo.Proveedor := Trim(
    AEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_PRV_SES').AsString);
  if ATrabajo.Proveedor = '' then
    raise Exception.Create(
      SErrorImportacionOcrProveedorNoSeleccionado);
  ATrabajo.DirectorioFotos := Trim(
    AEntorno.ObtenerDirectorioFotos());
  if ATrabajo.DirectorioFotos = '' then
    raise Exception.Create(
      SErrorImportacionOcrDirectorioFotosNoConfigurado);
  if AEntorno.Datos.unqryTablaG.State in [dsEdit, dsInsert] then
    AEntorno.Datos.unqryTablaG.Post;
  ATrabajo.Serie := AEntorno.Datos.unqryTablaG.FieldByName(
    'SERIE_SES').AsString;
  ATrabajo.Numero := AEntorno.Datos.unqryTablaG.FieldByName(
    'NUMERO_SES').AsString;
  ATrabajo.Tarifa := Trim(
    AEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_TAR_SES').AsString);
end;

procedure PrepararLineasPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
var
  iLinea: Integer;
  oCatalogo: TCatalogoTallasPedidoOcr;
begin
  SetLength(ATrabajo.Lineas, Length(ATrabajo.Pedido.Lineas));
  oCatalogo := TCatalogoTallasPedidoOcr.Create(
    AEntorno.Conexion,
    AEntorno.MaximoTallas);
  try
    for iLinea := 0 to High(ATrabajo.Pedido.Lineas) do
    begin
      if Trim(ATrabajo.Pedido.Lineas[iLinea].Modelo) = '' then
        raise Exception.CreateFmt(
          SErrorLineaOcrSinModelo, [iLinea + 1]);
      ATrabajo.Lineas[iLinea].Datos :=
        ATrabajo.Pedido.Lineas[iLinea];
      ATrabajo.Lineas[iLinea].Tallas := oCatalogo.Resolver(
        ATrabajo.Pedido.Lineas[iLinea].Tallas);
      if not ATrabajo.Lineas[iLinea].Tallas.Encontrada then
        raise Exception.CreateFmt(
          SErrorTallasOcrNoEncontradas,
          [AEntorno.MaximoTallas,
           ATrabajo.Pedido.Lineas[iLinea].Modelo,
           ListaTallasPedidoOcr(ATrabajo.Pedido.Lineas[iLinea])]);
    end;
  finally
    oCatalogo.Free;
  end;
end;

procedure PrepararTrabajoPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  const AFicheroJson: string;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
begin
  ATrabajo.Pedido := TLectorPedidoOcr.Cargar(AFicheroJson);
  ATrabajo.DirectorioJson := TPath.GetDirectoryName(
    ATrabajo.Pedido.FicheroJson);
  PrepararLineasPedidoOcr(AEntorno, ATrabajo);
  ATrabajo.Paginas := ResolverPaginasFuentePedido(ATrabajo.Pedido);
end;

function CalcularPvpPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  const ALinea: TLineaPedidoOcr): Double;
begin
  if ALinea.TienePvp then
    Result := ALinea.Pvp
  else
    Result := CalcularPrecioVenta(
      ALinea.PrecioCompra,
      AEntorno.Datos.unqryTablaG.FieldByName(
        'PORCENTAJE_MARGEN_SES').AsFloat,
      AEntorno.Datos.unqryTablaG.FieldByName(
        'MULTIPLO_REDONDEO_SES').AsFloat,
      AEntorno.Datos.unqryTablaG.FieldByName(
        'AJUSTE_FINAL_SES').AsFloat);
end;

procedure AplicarColorPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  ACatalogo: TCatalogoColoresPedidoOcr;
  const ALinea: TLineaPedidoOcr;
  const AResolucion: TResolverDuplicadoSesion);
var
  sColorBasico: string;
begin
  sColorBasico := '';
  if AResolucion.Encontrado and
     SameText(
       SanearColorSku(AResolucion.ColorTexto),
       SanearColorSku(ALinea.Color)) then
    sColorBasico := Trim(AResolucion.CodigoAtbColor);
  if sColorBasico = '' then
    ACatalogo.Resolver(ALinea.Color, sColorBasico);
  if (sColorBasico <> '') and
     Assigned(AEntorno.AsignarColorLiteral) then
    AEntorno.AsignarColorLiteral(sColorBasico)
  else if (ALinea.ColorDetectado <> '') and
          Assigned(AEntorno.AsignarColorLiteral) then
    AEntorno.AsignarColorLiteral(ALinea.ColorDetectado)
  else if Assigned(AEntorno.AsignarColorCoincidente) then
    AEntorno.AsignarColorCoincidente();
end;

procedure AnadirCeldasPedidoOcr(
  var ACeldas: TCeldasPedidoOcr;
  const ALinea: TLineaPreparadaPedidoOcr);
var
  iCelda: Integer;
  iTalla: Integer;
begin
  for iTalla := 0 to High(ALinea.Datos.Tallas) do
  begin
    iCelda := Length(ACeldas);
    SetLength(ACeldas, iCelda + 1);
    ACeldas[iCelda].Linea := ALinea.LineaSesion;
    ACeldas[iCelda].IdAv := ALinea.Tallas.IdsAv[iTalla];
    ACeldas[iCelda].Cantidad := ALinea.Datos.Tallas[iTalla].Cantidad;
  end;
end;

procedure PersistirLineaPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  ACatalogoArticulos: TCatalogoArticulosPedidoOcr;
  ACatalogoColores: TCatalogoColoresPedidoOcr;
  var ALinea: TLineaPreparadaPedidoOcr;
  var ACeldas: TCeldasPedidoOcr;
  var ALineasSinCodigo: Integer);
var
  oResolucion: TResolverDuplicadoSesion;
begin
  if Assigned(AEntorno.CambiarEstadoColor) then
    AEntorno.CambiarEstadoColor(True);
  AEntorno.Datos.PermitirLineasSinCodigoArticulo := True;
  try
    AEntorno.Datos.unqrySesionLin.Insert;
    ALinea.LineaSesion := AEntorno.Datos.unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    oResolucion := ACatalogoArticulos.Resolver(ALinea.Datos.Modelo);
    if oResolucion.Encontrado then
      AEntorno.AplicarDuplicado(oResolucion)
    else
      AEntorno.Datos.unqrySesionLin.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString := '';
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'REF_PRV_SESLIN').AsString := Copy(ALinea.Datos.Modelo, 1, 100);
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'DESCRIPCION_SESLIN').AsString :=
        AEntorno.Datos.DescripcionParaLinea(ALinea.Datos.Descripcion);
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'COLOR_TEXTO_SESLIN').AsString := ALinea.Datos.Color;
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'PRECIO_COMPRA_SESLIN').AsFloat := ALinea.Datos.PrecioCompra;
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'PRECIO_VENTA_SESLIN').AsFloat := CalcularPvpPedidoOcr(
        AEntorno, ALinea.Datos);
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'ID_AC_PIVOT_SESLIN').AsInteger := ALinea.Tallas.IdAc;
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'TOTAL_UNIDADES_SESLIN').AsFloat := ALinea.Datos.Cantidad;
    AEntorno.Datos.unqrySesionLin.FieldByName(
      'TOTAL_LINEA_SESLIN').AsFloat :=
        ALinea.Datos.Cantidad * ALinea.Datos.PrecioCompra;
    // Sin formula evaluable (familia sin contador) la linea entra sin
    // codigo y se cuenta en el resumen, como cualquier otra sin codigo.
    try
      AEntorno.Datos.GenerarCodigoArticuloLineaActual(False);
    except
      on EFormulaCodigoArticuloSesion do
        AEntorno.Datos.unqrySesionLin.FieldByName(
          'CODIGO_ART_TENTATIVO_SESLIN').AsString := '';
    end;
    ALinea.CodigoArticulo := Trim(
      AEntorno.Datos.unqrySesionLin.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString);
    if ALinea.CodigoArticulo = '' then
      Inc(ALineasSinCodigo);
    AplicarColorPedidoOcr(
      AEntorno,
      ACatalogoColores,
      ALinea.Datos,
      oResolucion);
    AEntorno.Datos.unqrySesionLin.Post;
    AnadirCeldasPedidoOcr(ACeldas, ALinea);
  finally
    AEntorno.Datos.PermitirLineasSinCodigoArticulo := False;
    if Assigned(AEntorno.CambiarEstadoColor) then
      AEntorno.CambiarEstadoColor(False);
  end;
end;

procedure PersistirLineasPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  ACatalogoArticulos: TCatalogoArticulosPedidoOcr;
  ACatalogoColores: TCatalogoColoresPedidoOcr;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
var
  iLinea: Integer;
begin
  AEntorno.Vista.BeginUpdate;
  AEntorno.Datos.unqrySesionLin.DisableControls;
  try
    for iLinea := 0 to High(ATrabajo.Lineas) do
      PersistirLineaPedidoOcr(
        AEntorno,
        ACatalogoArticulos,
        ACatalogoColores,
        ATrabajo.Lineas[iLinea],
        ATrabajo.Celdas,
        ATrabajo.LineasSinCodigo);
    TPersistenciaPedidoOcr.GuardarCeldas(
      AEntorno.Conexion,
      ATrabajo.Serie,
      ATrabajo.Numero,
      AEntorno.Usuario,
      ATrabajo.Celdas);
    if AEntorno.Datos.unqryTablaG.State in [dsEdit, dsInsert] then
      AEntorno.Datos.unqryTablaG.Post;
  finally
    AEntorno.Datos.FinalizarImportacionMasiva;
    AEntorno.Datos.unqrySesionLin.EnableControls;
    AEntorno.Vista.EndUpdate;
  end;
end;

procedure RevertirImportacionPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr);
begin
  if AEntorno.Datos.unqrySesionLin.State in [dsEdit, dsInsert] then
    AEntorno.Datos.unqrySesionLin.Cancel;
  if AEntorno.Datos.unqryTablaG.State in [dsEdit, dsInsert] then
    AEntorno.Datos.unqryTablaG.Cancel;
  AEntorno.Datos.RevertirUnidadTrabajoImportacionOcr;
  if AEntorno.Datos.unqrySesionLin.Active then
    AEntorno.Datos.unqrySesionLin.Refresh;
end;

procedure EjecutarUnidadTrabajoPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  ACatalogoArticulos: TCatalogoArticulosPedidoOcr;
  ACatalogoColores: TCatalogoColoresPedidoOcr;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
var
  iPrimeraLinea: Integer;
begin
  AEntorno.Datos.IniciarUnidadTrabajoImportacionOcr;
  try
    if ATrabajo.Pedido.ReferenciaDocumento <> '' then
    begin
      AEntorno.Datos.unqryTablaG.Edit;
      AEntorno.Datos.unqryTablaG.FieldByName(
        'REF_PRV_SES').AsString := ATrabajo.Pedido.ReferenciaDocumento;
      AEntorno.Datos.unqryTablaG.Post;
    end;
    iPrimeraLinea := TPersistenciaPedidoOcr.ReservarLineas(
      AEntorno.Conexion,
      ATrabajo.Serie,
      ATrabajo.Numero,
      Length(ATrabajo.Lineas));
    if iPrimeraLinea <= 0 then
      raise Exception.Create(
        SErrorReservarLineasImportacionOcr);
    AEntorno.Datos.IniciarImportacionMasiva(
      iPrimeraLinea,
      Length(ATrabajo.Lineas));
    PersistirLineasPedidoOcr(
      AEntorno,
      ACatalogoArticulos,
      ACatalogoColores,
      ATrabajo);
    AEntorno.Datos.ConfirmarUnidadTrabajoImportacionOcr;
  except
    RevertirImportacionPedidoOcr(AEntorno);
    raise;
  end;
end;

procedure PersistirPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  var ATrabajo: TTrabajoImportacionPedidoOcr);
var
  oCatalogoArticulos: TCatalogoArticulosPedidoOcr;
  oCatalogoColores: TCatalogoColoresPedidoOcr;
begin
  oCatalogoArticulos := TCatalogoArticulosPedidoOcr.Create(
    AEntorno.Conexion,
    ATrabajo.Proveedor,
    ATrabajo.Tarifa,
    ATrabajo.Pedido.Lineas);
  try
    oCatalogoColores := TCatalogoColoresPedidoOcr.Create(
      AEntorno.Conexion,
      ATrabajo.Proveedor,
      ATrabajo.Pedido.Lineas);
    try
      EjecutarUnidadTrabajoPedidoOcr(
        AEntorno,
        oCatalogoArticulos,
        oCatalogoColores,
        ATrabajo);
    finally
      oCatalogoColores.Free;
    end;
  finally
    oCatalogoArticulos.Free;
  end;
end;

procedure PrepararFotosPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  const ATrabajo: TTrabajoImportacionPedidoOcr;
  AAdvertencias: TStrings;
  out AFotos: TSolicitudesFotosSesion);
var
  iFoto: Integer;
  iLinea: Integer;
  sFichero: string;
begin
  SetLength(AFotos, 0);
  for iLinea := 0 to High(ATrabajo.Lineas) do
  begin
    sFichero := '';
    if ATrabajo.Lineas[iLinea].Datos.CodigoFoto <> '' then
      sFichero := ResolverFotoPedidoOcr(
        ATrabajo.DirectorioJson,
        ATrabajo.Lineas[iLinea].Datos.CodigoFoto);
    if (ATrabajo.Lineas[iLinea].Datos.CodigoFoto <> '') and
       (sFichero = '') then
      AAdvertencias.Add(Format(
        'No se encontró la foto %s.',
        [ATrabajo.Lineas[iLinea].Datos.CodigoFoto]));
    if (sFichero <> '') and PuedeGuardarFotosPedidoOcr(AEntorno) then
    begin
      iFoto := Length(AFotos);
      SetLength(AFotos, iFoto + 1);
      AFotos[iFoto].Linea := ATrabajo.Lineas[iLinea].LineaSesion;
      AFotos[iFoto].CodigoArticuloTentativo :=
        ATrabajo.Lineas[iLinea].CodigoArticulo;
      AFotos[iFoto].CodigoUnidad := '';
      AFotos[iFoto].FicheroOrigen := sFichero;
    end;
  end;
end;

procedure GuardarComplementosPedidoOcr(
  const AEntorno: TEntornoImportacionPedidoOcr;
  const ATrabajo: TTrabajoImportacionPedidoOcr;
  var AResultado: TResultadoImportacionPedidoOcr);
var
  aFotos: TSolicitudesFotosSesion;
  oAdvertencias: TStringList;
begin
  oAdvertencias := TStringList.Create;
  try
    if Trim(AResultado.Advertencias) <> '' then
      oAdvertencias.Add(Trim(AResultado.Advertencias));
    PrepararFotosPedidoOcr(
      AEntorno,
      ATrabajo,
      oAdvertencias,
      aFotos);
    if (Length(aFotos) > 0) and PuedeGuardarFotosPedidoOcr(AEntorno) then
    begin
      try
        AEntorno.GuardarFotos(
          ATrabajo.Serie,
          ATrabajo.Numero,
          aFotos,
          AEntorno.Usuario);
        AResultado.Fotos := Length(aFotos);
      except
        on E: Exception do
          oAdvertencias.Add('Fotos del pedido: ' + E.Message);
      end;
    end;
    try
      GuardarArchivosPedidoSesion(
        ATrabajo.DirectorioFotos,
        ATrabajo.Serie,
        ATrabajo.Numero,
        ATrabajo.Pedido,
        ATrabajo.Paginas);
    except
      on E: Exception do
        oAdvertencias.Add('Pedido original: ' + E.Message);
    end;
    AResultado.Advertencias := Trim(oAdvertencias.Text);
  finally
    oAdvertencias.Free;
  end;
end;

constructor TCoordinadorImportacionPedidoOcr.Create(
  const AEntorno: TEntornoImportacionPedidoOcr);
begin
  inherited Create;
  ValidarEntornoImportacionPedidoOcr(AEntorno);
  FEntorno := AEntorno;
end;

function TCoordinadorImportacionPedidoOcr.Ejecutar(
  const AFicheroJson: string): TResultadoImportacionPedidoOcr;
var
  Trabajo: TTrabajoImportacionPedidoOcr;
begin
  Result := Default(TResultadoImportacionPedidoOcr);
  Trabajo := Default(TTrabajoImportacionPedidoOcr);
  ValidarSesionImportacionPedidoOcr(FEntorno, Trabajo);
  PrepararTrabajoPedidoOcr(FEntorno, AFicheroJson, Trabajo);
  if Trabajo.Pedido.RequiereRevision then
  begin
    Result.Advertencias :=
      'El OCR ha completado algunas cantidades mediante inferencias ' +
      'seguras. Revise estas líneas:';
    if Trim(Trabajo.Pedido.InferenciasValidacion) <> '' then
      Result.Advertencias := Result.Advertencias + sLineBreak +
        Trim(Trabajo.Pedido.InferenciasValidacion);
  end;
  PersistirPedidoOcr(FEntorno, Trabajo);
  Result.Lineas := Length(Trabajo.Lineas);
  Result.LineasSinCodigo := Trabajo.LineasSinCodigo;
  GuardarComplementosPedidoOcr(FEntorno, Trabajo, Result);
end;

end.

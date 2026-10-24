{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosPresentacion                                  }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones de presentacion del grid de lineas de inventario: plan de      }
{    columnas de atributo, modo de entrada Auto/SKU/Tallas y calculos de       }
{    linea. Sin VCL, sin datasets y sin SQL: todo es funcion pura.             }
{******************************************************************************}
unit inLibInventariosPresentacion;

interface

uses
  inLibColumnasSkuIntf,
  inLibInventariosAplicacionIntf,
  inLibInventariosPresentacionIntf;

const
  // Cuadrado de color (18) + separacion (6) + margenes (10) + aire (10).
  MARGEN_SWATCH_INVENTARIO = 44;

type
  TConsultaNombresAtributosInventario = reference to function(
    const ACodigoArticulo: string): TArray<string>;

// Envuelve la lectura concreta de la definicion de atributos en el puerto
// que consume la presentacion de columnas.
function CrearLookupAtributosInventario(
  const AConsulta: TConsultaNombresAtributosInventario):
  IAtributosInventarioLookup;

// Columnas de atributo visibles segun los nombres disponibles.
function PlanColumnasAtributosInventario(
  const ANombres: TArray<string>;
  ANumeroVisibles: Integer): TPlanColumnasAtributosInventario;
// Traduce el estado del grid en la unica accion que debe ejecutarse.
function DecidirAccionColumnasInventario(
  const ASituacion: TSituacionColumnasInventario):
  TAccionColumnasInventario;
// El ancho de una columna de atributo solo crece, nunca encoge.
function AnchoColumnaAtributoInventario(
  AAnchoTexto, AAnchoActual: Integer): Integer;
// SKU cerrado: tantos separadores como atributos exige la linea. Con el
// codigo de articulo se cuentan solo los separadores posteriores a el,
// porque el propio codigo puede llevar '/' ('2354/A-158').
function EsSkuCompletoInventario(
  const ASku: string; ANumeroAtributosRequeridos: Integer;
  const ACodigoArticulo: string = ''): Boolean;
// Valores de atributo que lleva un SKU: lo que sigue al codigo de
// articulo y su separador ('2354/A-158/375/40' con articulo '2354/A-158'
// da ['375', '40']). Trocear el SKU entero por '/' partia los codigos de
// articulo con barra. Sin articulo, o si el SKU no lo lleva de prefijo,
// se descarta solo el primer tramo.
function AtributosDesdeSkuInventario(
  const ACodigoArticulo, ASku: string): TArray<string>;
// CODIGO_UNIDAD_INVLIN es NOT NULL: nunca puede quedar vacio.
function SkuEfectivoInventario(
  const ASkuGenerado, ACodigoArticulo: string): string;
function DiferenciaUnidadesInventario(
  AFisicas, ATeoricas: Currency): Currency;
function DiferenciaCosteInventario(
  AFisicas, ATeoricas, APrecioNuevo, APrecioActual: Currency): Currency;
// El ciclo de F1 en inventarios: solo Auto y SKU. Los modos de tallas en
// horizontal quedaron descartados porque cada linea lleva DOS cantidades
// (teorica y recuento) y una celda de pivote solo representa una.
function ModoEntradaInventarioSoportado(
  AModo: TModoColumnasSku): Boolean;
function ModoEntradaInventarioSiguiente(
  AModo: TModoColumnasSku): TModoColumnasSku;
function MuestraAtributosEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
function DesempaquetarAlCargarEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
function CaptionDetalleInventario(
  AModoDetectado: TModoColumnasSku): string;
// Mensaje para el usuario del resultado de resolver una entrada.
function MensajeErrorEntradaInventario(
  const AResultado: TResultadoEntradaInventario): string;
// Tooltip explicativo de las columnas clave del grid de lineas. Se
// resuelve por campo para seguir vivo tras el ClearItems del contrato.
function HintCeldaInventario(const ACampo: string): string;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  inLibMsgArticulos,
  inLibRedondeo;

type
  TLookupAtributosInventario = class(
    TInterfacedObject,
    IAtributosInventarioLookup)
  private
    FConsulta: TConsultaNombresAtributosInventario;
  public
    constructor Create(
      const AConsulta: TConsultaNombresAtributosInventario);
    function NombresAtributosArticulo(
      const ACodigoArticulo: string): TArray<string>;
  end;

constructor TLookupAtributosInventario.Create(
  const AConsulta: TConsultaNombresAtributosInventario);
begin
  inherited Create;
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  FConsulta := AConsulta;
end;

function TLookupAtributosInventario.NombresAtributosArticulo(
  const ACodigoArticulo: string): TArray<string>;
begin
  Result := FConsulta(ACodigoArticulo);
end;

function CrearLookupAtributosInventario(
  const AConsulta: TConsultaNombresAtributosInventario):
  IAtributosInventarioLookup;
begin
  Result := TLookupAtributosInventario.Create(AConsulta);
end;

function PlanColumnasAtributosInventario(
  const ANombres: TArray<string>;
  ANumeroVisibles: Integer): TPlanColumnasAtributosInventario;
var
  iColumna: Integer;
  iVisibles: Integer;
begin
  iVisibles := ANumeroVisibles;
  if iVisibles > MAX_ATRIBUTOS_INVENTARIO then
    iVisibles := MAX_ATRIBUTOS_INVENTARIO;
  if iVisibles < 0 then
    iVisibles := 0;
  for iColumna := 1 to MAX_ATRIBUTOS_INVENTARIO do
  begin
    if iColumna <= iVisibles then
    begin
      if iColumna <= Length(ANombres) then
        Result[iColumna].Caption := ANombres[iColumna - 1]
      else
        Result[iColumna].Caption := Format(SCaptionAtributoN, [iColumna]);
      Result[iColumna].Visible := True;
      Result[iColumna].Editable := True;
    end
    else
    begin
      Result[iColumna].Caption := '-';
      Result[iColumna].Visible := False;
      Result[iColumna].Editable := False;
    end;
  end;
end;

function DecidirAccionColumnasInventario(
  const ASituacion: TSituacionColumnasInventario):
  TAccionColumnasInventario;
begin
  // El orden reproduce el de la pantalla: el contrato de entrada manda
  // sobre todo lo demas y la memoizacion por articulo padre es la ultima
  // puerta antes de repintar.
  if ASituacion.ContratoConstruido then
    Result := aciNinguna
  else if not ASituacion.MostrarAtributos then
    Result := aciOcultarTodas
  else if not ASituacion.HayOrigenDeDatos then
    Result := aciOcultarTodas
  else if ASituacion.LineasEnEdicion then
    Result := aciColumnasDelArticulo
  else if ASituacion.MismoArticuloPadre then
    Result := aciNinguna
  else if not ASituacion.VistaAplicada then
    Result := aciColumnasDeLaVista
  else
    Result := aciSoloModoEntrada;
end;

function AnchoColumnaAtributoInventario(
  AAnchoTexto, AAnchoActual: Integer): Integer;
begin
  Result := AAnchoActual;
  if AAnchoActual < AAnchoTexto + MARGEN_SWATCH_INVENTARIO then
    Result := AAnchoTexto + MARGEN_SWATCH_INVENTARIO;
end;

// True si el SKU lleva el codigo de articulo como prefijo; ATramo es lo
// que sigue al separador (o el SKU entero si no hay prefijo).
function TramoAtributosSkuInventario(
  const ACodigoArticulo, ASku: string; out ATramo: string): Boolean;
begin
  Result := (ACodigoArticulo <> '') and
            StartsText(ACodigoArticulo + '/', ASku);
  if Result then
    ATramo := Copy(ASku, Length(ACodigoArticulo) + 2, MaxInt)
  else
    ATramo := ASku;
end;

function ContarSeparadoresSku(const ATexto: string): Integer;
var
  iCaracter: Integer;
begin
  Result := 0;
  for iCaracter := 1 to Length(ATexto) do
  begin
    if ATexto[iCaracter] = '/' then
      Inc(Result);
  end;
end;

function EsSkuCompletoInventario(
  const ASku: string; ANumeroAtributosRequeridos: Integer;
  const ACodigoArticulo: string): Boolean;
var
  sTramo: string;
  iSeparadores: Integer;
begin
  iSeparadores := ContarSeparadoresSku(ASku);
  if TramoAtributosSkuInventario(ACodigoArticulo, ASku, sTramo) then
    iSeparadores := 1 + ContarSeparadoresSku(sTramo);
  Result := (ANumeroAtributosRequeridos > 0) and
            (iSeparadores = ANumeroAtributosRequeridos);
end;

function AtributosDesdeSkuInventario(
  const ACodigoArticulo, ASku: string): TArray<string>;
var
  sTramo: string;
begin
  SetLength(Result, 0);
  if TramoAtributosSkuInventario(ACodigoArticulo, ASku, sTramo) then
  begin
    if sTramo <> '' then
      Result := sTramo.Split(['/']);
  end
  else if ASku <> '' then
  begin
    Result := ASku.Split(['/']);
    Delete(Result, 0, 1);
  end;
end;

function SkuEfectivoInventario(
  const ASkuGenerado, ACodigoArticulo: string): string;
begin
  Result := ASkuGenerado;
  if Trim(ASkuGenerado) = '' then
    Result := ACodigoArticulo;
end;

function DiferenciaUnidadesInventario(
  AFisicas, ATeoricas: Currency): Currency;
begin
  Result := AFisicas - ATeoricas;
end;

function DiferenciaCosteInventario(
  AFisicas, ATeoricas, APrecioNuevo, APrecioActual: Currency): Currency;
begin
  // A centimos, como PRC_FZA_INVENTARIOS_CALCULAR_LINEAS (script 768): la
  // cabecera suma las lineas y debe cuadrar con lo que se ve (FZ-ISSUE-250).
  Result := RedondearACentimos(
    (AFisicas * APrecioNuevo) - (ATeoricas * APrecioActual));
end;

function ModoEntradaInventarioSoportado(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo in [mcsAuto, mcsSku];
end;

function ModoEntradaInventarioSiguiente(
  AModo: TModoColumnasSku): TModoColumnasSku;
begin
  // Ciclo real de la pantalla: Auto -> SKU -> Auto. Cualquier modo no
  // soportado vuelve al primero del ciclo.
  if AModo = mcsAuto then
    Result := mcsSku
  else
    Result := mcsAuto;
end;

function MuestraAtributosEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo <> mcsSku;
end;

function DesempaquetarAlCargarEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo <> mcsSku;
end;

function CaptionDetalleInventario(
  AModoDetectado: TModoColumnasSku): string;
begin
  if AModoDetectado = mcsSku then
    Result := SCaptionTabDetalleInventarioSku
  else
    Result := SCaptionTabDetalleInventarioDesglose;
end;

function MensajeErrorEntradaInventario(
  const AResultado: TResultadoEntradaInventario): string;
begin
  Result := '';
  case AResultado.Error of
    eeiArticuloNoEncontrado:
      Result := SErrorArticuloInventarioNoEncontrado;
    eeiTipoArticuloSinStock:
      Result := Format(SErrorArticuloInventarioTipoSinStock,
        [AResultado.CodigoArticulo, AResultado.TipoArticulo]);
    eeiAtributosRequierenSku:
      Result := Format(SErrorArticuloInventarioAtributosSinSku,
        [AResultado.CodigoArticulo]);
    eeiLineasNoAbiertas:
      Result := SErrorLineasInventarioNoAbiertas;
    eeiLineaNoEditable:
      Result := SErrorLineaInventarioNoEditable;
  end;
end;

function HintCeldaInventario(const ACampo: string): string;
begin
  Result := '';
  if ACampo = 'CANTIDAD_TEORICA_INVLIN' then
    Result := SHintStockTeoricoInventario
  else if ACampo = 'CANTIDAD_FISICA_INVLIN' then
    Result := SHintRecuentoInventario
  else if ACampo = 'PRECIO_MEDIO_NUEVO_INVLIN' then
    Result := SHintPmpNuevoInventario
  else if ACampo = 'UDS_REGULARIZADAS' then
    Result := SHintUnidadesRegularizadasInventario;
end;

end.

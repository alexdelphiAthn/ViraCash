{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaOpePresentacion                                      }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Entrada por teclado de la línea de venta de caja. Recoge la decisión     }
{    que antes vivía dentro del OnEditKeyDown de la rejilla: reactivar la     }
{    búsqueda incremental, retirar una línea en blanco, confirmar el          }
{    artículo y elegir a dónde salta el foco.                                 }
{                                                                              }
{    Trabaja solo contra los puertos de inLibCajaOpePresentacionIntf, así     }
{    que se prueba sin formulario y sin conexión                              }
{    (LIBRO_DE_ESTILO_DELPHI.md 14.1 y 14.4).                                 }
{******************************************************************************}
unit inLibCajaOpePresentacion;

interface

uses
  Data.DB,
  inLibCajaOpePresentacionIntf;

// Adaptador de la línea de venta sobre su dataset. No conoce la rejilla
// ni el formulario: solo el juego de campos de fza_facturas_lineas.
function CrearLineaVentaCajaDataSet(
  ALineas: TDataSet): ILineaVentaCaja;

function CrearProcesadorTeclaLineaCaja(
  const ARejilla: IRejillaLineaCaja;
  const ALinea: ILineaVentaCaja;
  const AArticulo: IArticuloLineaCaja;
  const AAvisos: IAvisosOperacionCaja
): IProcesadorTeclaLineaCaja;

// Atributos ya incorporados al SKU compuesto (ART/COLOR/TALLA cuenta
// dos). Es el separador el que marca cada atributo resuelto.
function AtributosResueltosSkuCaja(const ASku: string): Integer;

// El SKU ya no es el artículo padre y lleva todos los atributos que la
// línea exige: la venta puede cerrarse.
function SkuLineaCajaCompleto(
  const AArticulo, ASku: string;
  ANumAtributos: Integer): Boolean;

// Tras elegir un valor, el SKU queda cerrado y admite recálculo de
// precio de tarifa.
function SkuLineaCajaAdmitePrecio(
  const ASku: string;
  ANumAtributos: Integer): Boolean;

// Después del atributo AOrden queda otro por pedir, salvo que sea el
// último de la línea.
function PasoTrasAtributoLineaCaja(
  AOrden, ANumAtributos: Integer): TPasoAtributoLineaCaja;

// FZ-ISSUE-618: un lector sin trama STX/ETX teclea el código en la celda
// numérica que esté en edición. Ningún importe, cantidad ni porcentaje
// lleva tantas cifras seguidas: si el texto tiene una racha de dígitos
// de longitud de código de barras, se devuelve en ACodigo.
function ExtraerLecturaCeldaNumericaCaja(const ATexto: string;
  out ACodigo: string): Boolean;

// FZ-ISSUE-618: el porcentaje de descuento tecleado admite de 0 a 100.
// Un texto que no es un número se deja a la validación del editor.
function PorcentajeDtoCajaFueraDeRango(const ATexto: string): Boolean;

implementation

uses
  System.SysUtils,
  inLibCajaVentaOperacion,
  inLibMsgCaja;

type
  TLineaVentaCajaDataSet = class(
    TInterfacedObject,
    ILineaVentaCaja)
  private
    FLineas: TDataSet;
    function Disponible: Boolean;
  public
    constructor Create(ALineas: TDataSet);
    function EstaInsertando: Boolean;
    function CodigoArticulo: string;
    procedure EscribirCodigoArticulo(const ACodigo: string);
    function CodigoSku: string;
    procedure AsegurarEdicion;
    procedure CancelarLinea;
    procedure GrabarYAnadirLinea;
    procedure ConservarLineaRechazada;
  end;

  TProcesadorTeclaLineaCaja = class(
    TInterfacedObject,
    IProcesadorTeclaLineaCaja)
  private
    FRejilla: IRejillaLineaCaja;
    FLinea: ILineaVentaCaja;
    FArticulo: IArticuloLineaCaja;
    FAvisos: IAvisosOperacionCaja;
    procedure ActualizarBusquedaIncremental(
      ATecla: TTeclaOperacionCaja);
    function RetirarLineaEnBlanco(
      ATecla: TTeclaOperacionCaja): Boolean;
    function EsEntradaDeArticulo(
      ATecla: TTeclaOperacionCaja): Boolean;
    function ConfirmarArticulo: Boolean;
    function AsegurarCodigoEnEditor: Boolean;
    function MensajeRechazoArticulo: string;
    function CerrarLineaDeArticulo: Boolean;
    function ResolverArticuloDeLinea: string;
    function CerrarConSkuResuelto(const ASku: string): Boolean;
    function AbrirPrimerAtributo(const ASku: string): Boolean;
    procedure AvanzarTrasLineaCompleta;
  public
    constructor Create(
      const ARejilla: IRejillaLineaCaja;
      const ALinea: ILineaVentaCaja;
      const AArticulo: IArticuloLineaCaja;
      const AAvisos: IAvisosOperacionCaja);
    function Procesar(ATecla: TTeclaOperacionCaja): Boolean;
  end;

// El SKU es propio de la línea cuando ya no es el artículo padre a la
// espera de talla o color.
function EsSkuPropioLineaCaja(
  const ASku, AArticulo: string): Boolean;
begin
  Result := (Trim(ASku) <> '') and (ASku <> AArticulo);
end;

constructor TLineaVentaCajaDataSet.Create(ALineas: TDataSet);
begin
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  inherited Create;
  FLineas := ALineas;
end;

function TLineaVentaCajaDataSet.Disponible: Boolean;
begin
  Result := Assigned(FLineas) and FLineas.Active;
end;

function TLineaVentaCajaDataSet.EstaInsertando: Boolean;
begin
  Result := Disponible and (FLineas.State = dsInsert);
end;

function TLineaVentaCajaDataSet.CodigoArticulo: string;
begin
  Result := '';
  if Disponible then
    Result := FLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
end;

procedure TLineaVentaCajaDataSet.EscribirCodigoArticulo(
  const ACodigo: string);
begin
  if Disponible and (FLineas.State in [dsEdit, dsInsert]) then
    FLineas.FieldByName('CODIGO_ART_FACLIN').AsString := ACodigo;
end;

function TLineaVentaCajaDataSet.CodigoSku: string;
begin
  Result := '';
  if Disponible then
    Result := FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
end;

procedure TLineaVentaCajaDataSet.AsegurarEdicion;
begin
  if Disponible and (FLineas.State = dsBrowse) then
    FLineas.Edit;
end;

procedure TLineaVentaCajaDataSet.CancelarLinea;
begin
  if Disponible and (FLineas.State in [dsEdit, dsInsert]) then
    FLineas.Cancel;
end;

procedure TLineaVentaCajaDataSet.GrabarYAnadirLinea;
begin
  if Disponible then
  begin
    if FLineas.State in [dsEdit, dsInsert] then
      FLineas.Post;
    FLineas.Append;
  end;
end;

procedure TLineaVentaCajaDataSet.ConservarLineaRechazada;
begin
  ConservarLineaVentaPorValidacion(FLineas);
end;

constructor TProcesadorTeclaLineaCaja.Create(
  const ARejilla: IRejillaLineaCaja;
  const ALinea: ILineaVentaCaja;
  const AArticulo: IArticuloLineaCaja;
  const AAvisos: IAvisosOperacionCaja);
begin
  if not Assigned(ARejilla) then
    raise EArgumentNilException.Create('ARejilla');
  if not Assigned(ALinea) then
    raise EArgumentNilException.Create('ALinea');
  if not Assigned(AArticulo) then
    raise EArgumentNilException.Create('AArticulo');
  if not Assigned(AAvisos) then
    raise EArgumentNilException.Create('AAvisos');
  inherited Create;
  FRejilla := ARejilla;
  FLinea := ALinea;
  FArticulo := AArticulo;
  FAvisos := AAvisos;
end;

function TProcesadorTeclaLineaCaja.Procesar(
  ATecla: TTeclaOperacionCaja): Boolean;
begin
  ActualizarBusquedaIncremental(ATecla);
  Result := RetirarLineaEnBlanco(ATecla);
  if (not Result) and EsEntradaDeArticulo(ATecla) then
    Result := ConfirmarArticulo;
end;

// Cualquier tecla de contenido sobre la columna de artículo relanza el
// temporizador de búsqueda incremental.
procedure TProcesadorTeclaLineaCaja.ActualizarBusquedaIncremental(
  ATecla: TTeclaOperacionCaja);
begin
  if (ATecla = tocOtra) and
     (FRejilla.RolColumnaActiva = rclArticulo) then
    FRejilla.ReactivarBusquedaIncremental;
end;

// Subir desde una línea recién abierta y sin artículo la descarta en
// lugar de dejar una fila en blanco en la venta.
function TProcesadorTeclaLineaCaja.RetirarLineaEnBlanco(
  ATecla: TTeclaOperacionCaja): Boolean;
begin
  Result := (ATecla = tocArriba) and
            FLinea.EstaInsertando and
            (Trim(FLinea.CodigoArticulo) = '');
  if Result then
    FLinea.CancelarLinea;
end;

function TProcesadorTeclaLineaCaja.EsEntradaDeArticulo(
  ATecla: TTeclaOperacionCaja): Boolean;
begin
  Result := (ATecla = tocIntro) and
            (FRejilla.RolColumnaActiva = rclArticulo);
end;

function TProcesadorTeclaLineaCaja.ConfirmarArticulo: Boolean;
begin
  FRejilla.DetenerBusquedaIncremental;
  // El desplegable del lookup se traga el primer Intro; cerrarlo aquí
  // deja que un solo Intro confirme la línea.
  FRejilla.CerrarDesplegable;
  Result := True;
  if AsegurarCodigoEnEditor then
    Result := CerrarLineaDeArticulo;
end;

// Deja en el editor un código utilizable. False cuando la pulsación ya
// queda resuelta: buscador cancelado o artículo rechazado.
function TProcesadorTeclaLineaCaja.AsegurarCodigoEnEditor: Boolean;
var
  sCodigo: string;
begin
  Result := True;
  if Trim(FRejilla.TextoEditor) = '' then
  begin
    sCodigo := FArticulo.BuscarArticulo;
    Result := sCodigo <> '';
    if Result then
    begin
      FRejilla.EscribirEditor(sCodigo);
      Result := FArticulo.CargarArticulo(sCodigo);
      if not Result then
        FAvisos.Avisar(MensajeRechazoArticulo);
    end;
  end;
end;

function TProcesadorTeclaLineaCaja.MensajeRechazoArticulo: string;
begin
  Result := FArticulo.MotivoRechazo;
  if Trim(Result) = '' then
    Result := SErrorArticuloVentaCajaNoEncontrado;
end;

// Publica el valor del editor, fija el artículo de la línea y decide el
// desenlace: SKU cerrado, línea sin atributos o salto al primero.
function TProcesadorTeclaLineaCaja.CerrarLineaDeArticulo: Boolean;
var
  sArticulo: string;
  sSku: string;
  iAtributos: Integer;
begin
  FArticulo.OlvidarArticuloResuelto;
  FRejilla.PublicarValorEditor;
  FLinea.AsegurarEdicion;
  sArticulo := ResolverArticuloDeLinea;
  iAtributos := FArticulo.PrepararColumnasAtributos(sArticulo);
  sSku := FLinea.CodigoSku;
  Result := True;
  if EsSkuPropioLineaCaja(sSku, sArticulo) then
    Result := CerrarConSkuResuelto(sSku)
  else if iAtributos = 0 then
    AvanzarTrasLineaCompleta
  else
    Result := AbrirPrimerAtributo(sSku);
end;

// El lookup puede dejar vacío el código durante la publicación del
// editor; el artículo que resolvió la validación manda.
function TProcesadorTeclaLineaCaja.ResolverArticuloDeLinea: string;
begin
  Result := FLinea.CodigoArticulo;
  if (Trim(Result) = '') and
     (Trim(FArticulo.ArticuloResuelto) <> '') then
  begin
    Result := FArticulo.ArticuloResuelto;
    FLinea.EscribirCodigoArticulo(Result);
  end;
end;

// SKU ya cerrado: se valida contra la política de stock y, si pasa, la
// línea queda terminada.
function TProcesadorTeclaLineaCaja.CerrarConSkuResuelto(
  const ASku: string): Boolean;
begin
  Result := True;
  if not FArticulo.SkuVendible(ASku) then
  begin
    FLinea.ConservarLineaRechazada;
    FArticulo.VolcarAtributosDeSku(ASku);
  end
  else
  begin
    FArticulo.VolcarAtributosDeSku(ASku);
    AvanzarTrasLineaCompleta;
  end;
end;

// La línea exige atributos: se vuelcan los que ya trae el SKU y el foco
// baja a la primera columna dinámica.
function TProcesadorTeclaLineaCaja.AbrirPrimerAtributo(
  const ASku: string): Boolean;
begin
  if Trim(ASku) <> '' then
    FArticulo.VolcarAtributosDeSku(ASku);
  Result := FRejilla.EnfocarYEditar(dflPrimerAtributo);
end;

procedure TProcesadorTeclaLineaCaja.AvanzarTrasLineaCompleta;
begin
  if FArticulo.AvanzarDeLinea then
  begin
    FLinea.GrabarYAnadirLinea;
    FRejilla.EnfocarYEditar(dflArticulo);
  end
  else
    FRejilla.EnfocarYEditar(dflDescripcion);
end;

function AtributosResueltosSkuCaja(const ASku: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(ASku) do
  begin
    if ASku[i] = '/' then
      Inc(Result);
  end;
end;

function SkuLineaCajaCompleto(
  const AArticulo, ASku: string;
  ANumAtributos: Integer): Boolean;
var
  sArticulo: string;
  sSku: string;
begin
  sArticulo := Trim(AArticulo);
  sSku := Trim(ASku);
  Result := (sArticulo <> '') and
            (sSku <> sArticulo) and
            SkuLineaCajaAdmitePrecio(sSku, ANumAtributos);
end;

function SkuLineaCajaAdmitePrecio(
  const ASku: string;
  ANumAtributos: Integer): Boolean;
begin
  Result := (ANumAtributos > 0) and
            (AtributosResueltosSkuCaja(ASku) = ANumAtributos);
end;

function PasoTrasAtributoLineaCaja(
  AOrden, ANumAtributos: Integer): TPasoAtributoLineaCaja;
begin
  Result := palAvanzar;
  if (ANumAtributos > 0) and (AOrden = ANumAtributos) then
    Result := palFinalizar;
end;

const
  // EAN-8 es el código de barras más corto que lee la caja.
  LONGITUD_MINIMA_LECTURA_CELDA_CAJA = 8;
  PORCENTAJE_DTO_MAXIMO_CAJA = 100;

function ExtraerLecturaCeldaNumericaCaja(const ATexto: string;
  out ACodigo: string): Boolean;
var
  sRacha: string;
  sCaracter: Char;
begin
  ACodigo := '';
  sRacha := '';
  // El espacio final cierra la última racha de dígitos.
  for sCaracter in ATexto + ' ' do
  begin
    if CharInSet(sCaracter, ['0'..'9']) then
      sRacha := sRacha + sCaracter
    else
    begin
      if Length(sRacha) > Length(ACodigo) then
        ACodigo := sRacha;
      sRacha := '';
    end;
  end;
  Result := Length(ACodigo) >= LONGITUD_MINIMA_LECTURA_CELDA_CAJA;
  if not Result then
    ACodigo := '';
end;

function PorcentajeDtoCajaFueraDeRango(const ATexto: string): Boolean;
var
  sTexto: string;
  dPorcentaje: Double;
  bNumero: Boolean;
begin
  // El editor muestra el valor con la máscara '0.00 %'.
  sTexto := StringReplace(ATexto, '%', '', [rfReplaceAll]);
  sTexto := StringReplace(sTexto, ' ', '', [rfReplaceAll]);
  sTexto := StringReplace(sTexto, string(Char($00A0)), '', [rfReplaceAll]);
  dPorcentaje := 0;
  bNumero := (sTexto = '') or TryStrToFloat(sTexto, dPorcentaje);
  if not bNumero then
  begin
    // Se admite el punto o la coma como separador decimal.
    sTexto := StringReplace(sTexto, '.',
      FormatSettings.DecimalSeparator, [rfReplaceAll]);
    sTexto := StringReplace(sTexto, ',',
      FormatSettings.DecimalSeparator, [rfReplaceAll]);
    bNumero := TryStrToFloat(sTexto, dPorcentaje);
  end;
  Result := bNumero and
    ((dPorcentaje < 0) or (dPorcentaje > PORCENTAJE_DTO_MAXIMO_CAJA));
end;

function CrearLineaVentaCajaDataSet(
  ALineas: TDataSet): ILineaVentaCaja;
begin
  Result := TLineaVentaCajaDataSet.Create(ALineas);
end;

function CrearProcesadorTeclaLineaCaja(
  const ARejilla: IRejillaLineaCaja;
  const ALinea: ILineaVentaCaja;
  const AArticulo: IArticuloLineaCaja;
  const AAvisos: IAvisosOperacionCaja
): IProcesadorTeclaLineaCaja;
begin
  Result := TProcesadorTeclaLineaCaja.Create(
    ARejilla,
    ALinea,
    AArticulo,
    AAvisos);
end;

end.

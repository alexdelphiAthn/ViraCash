{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorCopiaLineasCompra                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona la copia comercial de líneas de sesiones de compra sin conocer  }
{    el formulario, el grid ni la persistencia de cantidades por talla.       }
{******************************************************************************}
unit inLibGestorCopiaLineasCompra;

interface

uses
  Data.DB;

type
  // «Otro color»: mismos precios, cantidades y copa, color vacío. «Otro
  // valor de pestañas» (tercera dimensión, «Otra copa»): mismo color y la
  // copa que se indique, vacía para teclearla. Los precios distintos por talla
  // se dan con F1 en la línea.
  TModoCopiaLineaCompra = (mclOtroColor, mclOtroValorPestana);

  TResultadoCopiaLineaCompra = record
    Aplicada: Boolean;
    LineaOrigen: Integer;
    LineaDestino: Integer;
    IdConjuntoPivot: Integer;
  end;

  TObtenerSiguienteLineaCompra = function(
    ALineaOrigen: Integer
  ): Integer of object;

  TDatosLineaOrigenCompra = record
    Linea: Integer;
    CodigoFamilia: string;
    CodigoArticulo: string;
    ReferenciaProveedor: string;
    Descripcion: string;
    PrecioCompra: Double;
    PrecioVenta: Double;
    IdConjuntoPivot: Integer;
    CodigoVariacion: string;
    IdAtributoPivot: string;
    TipoLinea: string;
    Margen: Double;
    TipoIva: string;
    ColorTexto: string;
    CodigoColorBasico: string;
    Pestana: string;
  end;

  TGestorCopiaLineasCompra = class
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FObtenerSiguienteLinea: TObtenerSiguienteLineaCompra;
    function PuedeDuplicar: Boolean;
    function CapturarLineaActual: TDatosLineaOrigenCompra;
    procedure InsertarLineaCopiada(
      const ADatos: TDatosLineaOrigenCompra;
      ALineaSiguiente: Integer;
      AModo: TModoCopiaLineaCompra;
      const APestana: string);
  public
    constructor Create(
      ACabecera: TDataSet;
      ALineas: TDataSet;
      AObtenerSiguienteLinea: TObtenerSiguienteLineaCompra);
    function DuplicarLineaActual: TResultadoCopiaLineaCompra; overload;
    function DuplicarLineaActual(AModo: TModoCopiaLineaCompra;
      const APestana: string): TResultadoCopiaLineaCompra; overload;
  end;

const
  CAMPO_PESTANA_LINEA_SESION = 'PESTANA_TEXTO_SESLIN';

// Valores de pestañas que todavía no tiene el modelo y color de la línea,
// en el orden de ATodos (sin distinguir mayúsculas ni espacios).
function ValoresPestanaQueFaltan(const ATodos, AExistentes: TArray<string>):
  TArray<string>;

implementation

uses
  System.SysUtils;

constructor TGestorCopiaLineasCompra.Create(
  ACabecera: TDataSet;
  ALineas: TDataSet;
  AObtenerSiguienteLinea: TObtenerSiguienteLineaCompra);
begin
  inherited Create;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FObtenerSiguienteLinea := AObtenerSiguienteLinea;
end;

function TGestorCopiaLineasCompra.PuedeDuplicar: Boolean;
begin
  Result := Assigned(FCabecera) and Assigned(FLineas);
  if Result then
    Result := FCabecera.Active and FLineas.Active;
  if Result then
    Result := (not FCabecera.IsEmpty) and (not FLineas.IsEmpty);
end;

function TGestorCopiaLineasCompra.CapturarLineaActual:
  TDatosLineaOrigenCompra;
begin
  Result := Default(TDatosLineaOrigenCompra);
  if FLineas.FindField('CODIGO_VAR_SESLIN') <> nil then
    Result.CodigoVariacion :=
      FLineas.FieldByName('CODIGO_VAR_SESLIN').AsString;
  if FLineas.FindField('ID_VA_PIVOT_SESLIN') <> nil then
    Result.IdAtributoPivot :=
      FLineas.FieldByName('ID_VA_PIVOT_SESLIN').AsString;
  if FLineas.FindField('TIPO_LINEA_SESLIN') <> nil then
    Result.TipoLinea :=
      FLineas.FieldByName('TIPO_LINEA_SESLIN').AsString;
  Result.Linea :=
    FLineas.FieldByName('LINEA_SESLIN').AsInteger;
  Result.CodigoFamilia :=
    FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString;
  Result.CodigoArticulo :=
    FLineas.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
  Result.ReferenciaProveedor :=
    FLineas.FieldByName('REF_PRV_SESLIN').AsString;
  Result.Descripcion :=
    FLineas.FieldByName('DESCRIPCION_SESLIN').AsString;
  Result.PrecioCompra :=
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  Result.PrecioVenta :=
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
  Result.IdConjuntoPivot :=
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  Result.Margen :=
    FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  Result.TipoIva :=
    FLineas.FieldByName('TIPO_IVA_SESLIN').AsString;
  Result.ColorTexto :=
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString;
  Result.CodigoColorBasico :=
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
  // Opcional: las líneas de antes de la tercera dimensión no la tienen.
  Result.Pestana := '';
  if FLineas.FindField(CAMPO_PESTANA_LINEA_SESION) <> nil then
    Result.Pestana :=
      FLineas.FieldByName(CAMPO_PESTANA_LINEA_SESION).AsString;
end;

procedure TGestorCopiaLineasCompra.InsertarLineaCopiada(
  const ADatos: TDatosLineaOrigenCompra;
  ALineaSiguiente: Integer;
  AModo: TModoCopiaLineaCompra;
  const APestana: string);
begin
  FLineas.Insert;
  // Las copias conservan el tipo de la linea, aunque difiera del defecto.
  if FLineas.FindField('CODIGO_VAR_SESLIN') <> nil then
    FLineas.FieldByName('CODIGO_VAR_SESLIN').AsString :=
      ADatos.CodigoVariacion;
  if FLineas.FindField('ID_VA_PIVOT_SESLIN') <> nil then
    FLineas.FieldByName('ID_VA_PIVOT_SESLIN').AsString :=
      ADatos.IdAtributoPivot;
  if FLineas.FindField('TIPO_LINEA_SESLIN') <> nil then
    FLineas.FieldByName('TIPO_LINEA_SESLIN').AsString :=
      ADatos.TipoLinea;
  FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString :=
    ADatos.CodigoFamilia;
  FLineas.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString :=
    ADatos.CodigoArticulo;
  FLineas.FieldByName('REF_PRV_SESLIN').AsString :=
    ADatos.ReferenciaProveedor;
  if not SameText(Trim(FCabecera.FieldByName(
    'ESDESCRIPCION_BLANCO_SES').AsString), 'S') then
    FLineas.FieldByName('DESCRIPCION_SESLIN').AsString :=
      ADatos.Descripcion;
  if ADatos.IdConjuntoPivot > 0 then
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger :=
      ADatos.IdConjuntoPivot;
  if ADatos.Margen > 0 then
    FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat :=
      ADatos.Margen;
  if ADatos.TipoIva <> '' then
    FLineas.FieldByName('TIPO_IVA_SESLIN').AsString :=
      ADatos.TipoIva;
  FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat :=
    ADatos.PrecioCompra;
  FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat :=
    ADatos.PrecioVenta;
  if AModo = mclOtroValorPestana then
  begin
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString := ADatos.ColorTexto;
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString :=
      ADatos.CodigoColorBasico;
    if Trim(APestana) <> '' then
      FLineas.FieldByName(CAMPO_PESTANA_LINEA_SESION).AsString :=
        Trim(APestana);
  end
  else
  begin
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').Clear;
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
    if (ADatos.Pestana <> '') and
       (FLineas.FindField(CAMPO_PESTANA_LINEA_SESION) <> nil) then
      FLineas.FieldByName(CAMPO_PESTANA_LINEA_SESION).AsString :=
        ADatos.Pestana;
  end;
  FLineas.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
  FLineas.FieldByName('ACCION_DUPLICADO_SESLIN').AsString :=
    'REUSAR';
  FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString :=
    ADatos.CodigoArticulo;
  if (ALineaSiguiente > 0) and
     ((ALineaSiguiente - ADatos.Linea) > 1) then
    FLineas.FieldByName('LINEA_SESLIN').AsInteger :=
      (ADatos.Linea + ALineaSiguiente) div 2;
  FLineas.Post;
end;

function TGestorCopiaLineasCompra.DuplicarLineaActual:
  TResultadoCopiaLineaCompra;
begin
  Result := DuplicarLineaActual(mclOtroColor, '');
end;

function TGestorCopiaLineasCompra.DuplicarLineaActual(
  AModo: TModoCopiaLineaCompra;
  const APestana: string): TResultadoCopiaLineaCompra;
var
  iLineaSiguiente: Integer;
  oDatos: TDatosLineaOrigenCompra;
begin
  Result.Aplicada := False;
  Result.LineaOrigen := 0;
  Result.LineaDestino := 0;
  Result.IdConjuntoPivot := 0;
  if PuedeDuplicar then
  begin
    oDatos := CapturarLineaActual;
    iLineaSiguiente := 0;
    if Assigned(FObtenerSiguienteLinea) then
      iLineaSiguiente := FObtenerSiguienteLinea(oDatos.Linea);
    if FCabecera.State in [dsInsert, dsEdit] then
      FCabecera.Post;
    if FLineas.State in [dsEdit, dsInsert] then
      FLineas.Post;
    FCabecera.Edit;
    InsertarLineaCopiada(oDatos, iLineaSiguiente, AModo, APestana);
    Result.Aplicada := True;
    Result.LineaOrigen := oDatos.Linea;
    Result.LineaDestino :=
      FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    Result.IdConjuntoPivot := oDatos.IdConjuntoPivot;
  end;
end;

function ValoresPestanaQueFaltan(const ATodos, AExistentes: TArray<string>):
  TArray<string>;
var
  sValor: string;
  sExistente: string;
  bExiste: Boolean;
begin
  Result := nil;
  for sValor in ATodos do
  begin
    bExiste := Trim(sValor) = '';
    for sExistente in AExistentes do
      bExiste := bExiste or SameText(Trim(sExistente), Trim(sValor));
    if not bExiste then
      Result := Result + [Trim(sValor)];
  end;
end;

end.

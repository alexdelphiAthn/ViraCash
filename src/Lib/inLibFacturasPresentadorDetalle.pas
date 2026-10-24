{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasPresentadorDetalle                               }
{    Tipo:       Presentador (sin VCL)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de visibilidad del detalle de factura y del modo de entrada.       }
{******************************************************************************}
unit inLibFacturasPresentadorDetalle;

interface

type
  // Puerto estrecho sobre las columnas del detalle. Lo implementa el
  // adaptador VCL; el presentador nunca conoce la rejilla.
  IColumnasDetalleFactura = interface
    ['{4F1B7C02-9D5E-4A6B-8C31-2A7D9E63B510}']
    procedure OcultarColumnasCatalogo;
    procedure MostrarColumnaSku(AVisible: Boolean);
    function SkuVisible: Boolean;
    function TotalLineas: Integer;
    function ArticuloLinea(AIndice: Integer): string;
  end;
  // Regla de negocio del SKU por linea: solo procede cuando el articulo
  // tiene variacion (tallas/colores).
  IReglaSkuFactura = interface
    ['{9C6E0B44-1F27-45D8-9E0A-6B8F3C21D774}']
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
  end;
  TSituacionDetalleFactura = record
    ContratoActivo: Boolean;
    Construyendo: Boolean;
  end;
  // Reconstruccion del contrato de entrada al navegar de factura.
  TDecisionModoEntradaFactura = (
    dmefNinguna,
    dmefConstruir,
    dmefDesempaquetar);
  TSituacionModoEntradaFactura = record
    Construido: Boolean;
    ContratoActivo: Boolean;
    ModoTallas: Boolean;
    ModoSku: Boolean;
  end;
  TPresentadorDetalleFactura = class
  private
    FColumnas: IColumnasDetalleFactura;
    FRegla: IReglaSkuFactura;
    FReaplicando: Boolean;
  public
    constructor Create(
      const AColumnas: IColumnasDetalleFactura;
      const ARegla: IReglaSkuFactura);
    destructor Destroy; override;
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
    procedure OcultarColumnasCatalogo;
    procedure SincronizarColumnaSku(
      const ASituacion: TSituacionDetalleFactura);
    procedure Reaplicar(const ASituacion: TSituacionDetalleFactura);
    property Reaplicando: Boolean read FReaplicando;
  end;

function CrearSituacionDetalleFactura(
  AContratoActivo, AConstruyendo: Boolean): TSituacionDetalleFactura;
function DecidirModoEntradaFactura(
  const ASituacion: TSituacionModoEntradaFactura
): TDecisionModoEntradaFactura;

implementation

function CrearSituacionDetalleFactura(
  AContratoActivo, AConstruyendo: Boolean): TSituacionDetalleFactura;
begin
  Result := Default(TSituacionDetalleFactura);
  Result.ContratoActivo := AContratoActivo;
  Result.Construyendo := AConstruyendo;
end;

function DecidirModoEntradaFactura(
  const ASituacion: TSituacionModoEntradaFactura
): TDecisionModoEntradaFactura;
begin
  // Red de seguridad: con la apertura asincrona el detalle aun no estaba
  // abierto al crear la pantalla y la construccion inicial se saltaba.
  // Sin contrato activo la construccion quedo a medias: se repite.
  if (not ASituacion.Construido) or (not ASituacion.ContratoActivo) or
     ASituacion.ModoTallas then
    Result := dmefConstruir
  else if not ASituacion.ModoSku then
    // En desglose basta desempaquetar SKU->ATTR de las lineas nuevas.
    Result := dmefDesempaquetar
  else
    Result := dmefNinguna;
end;

constructor TPresentadorDetalleFactura.Create(
  const AColumnas: IColumnasDetalleFactura;
  const ARegla: IReglaSkuFactura);
begin
  inherited Create;
  FColumnas := AColumnas;
  FRegla := ARegla;
  FReaplicando := False;
end;

destructor TPresentadorDetalleFactura.Destroy;
begin
  FColumnas := nil;
  FRegla := nil;
  inherited;
end;

function TPresentadorDetalleFactura.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Assigned(FRegla) and FRegla.DebeMostrarSku(ACodigoArticulo);
end;

procedure TPresentadorDetalleFactura.OcultarColumnasCatalogo;
begin
  if Assigned(FColumnas) then
    FColumnas.OcultarColumnasCatalogo;
end;

procedure TPresentadorDetalleFactura.SincronizarColumnaSku(
  const ASituacion: TSituacionDetalleFactura);
var
  bMostrar: Boolean;
  iLinea: Integer;
begin
  // Con un modo del contrato construido, la columna SKU es del modo.
  if Assigned(FColumnas) and (not ASituacion.ContratoActivo) then
  begin
    // La columna solo aparece si alguna linea la necesita (variacion /
    // varios SKUs).
    bMostrar := False;
    iLinea := 0;
    while (not bMostrar) and (iLinea < FColumnas.TotalLineas) do
    begin
      bMostrar := DebeMostrarSku(FColumnas.ArticuloLinea(iLinea));
      Inc(iLinea);
    end;
    if FColumnas.SkuVisible <> bMostrar then
      FColumnas.MostrarColumnaSku(bMostrar);
  end;
end;

procedure TPresentadorDetalleFactura.Reaplicar(
  const ASituacion: TSituacionDetalleFactura);
begin
  // Durante la reconstruccion del modo las columnas estan muertas
  // (ClearItems) hasta que el adaptador las reasigna.
  if (not ASituacion.Construyendo) and (not FReaplicando) then
  begin
    FReaplicando := True;
    try
      // Columnas de catalogo (familia, proveedor, coste): datos
      // internos de la linea, siempre ocultos.
      // SKU: solo si alguna linea lo necesita.
      // Estas reglas mandan sobre el perfil de usuario.
      OcultarColumnasCatalogo;
      SincronizarColumnaSku(ASituacion);
    finally
      FReaplicando := False;
    end;
  end;
end;

end.

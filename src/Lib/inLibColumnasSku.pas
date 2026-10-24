{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSku                                              }
{    Tipo:       Libreria (factoria)                                           }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: factoria de modos de entrada. El documento        }
{    construye un TConfigColumnasSku (View + cds + nombres de campos) y        }
{    recibe el IModoEntradaGrid adecuado:                                      }
{                                                                              }
{      - mcsAuto: si el cds tiene columnas de atributo (ATTR1_VALOR...)        }
{        se elige desglose; si no, modo SKU (una columna).                     }
{      - mcsSku / mcsDesglose: se respeta lo pedido.                           }
{                                                                              }
{******************************************************************************}
unit inLibColumnasSku;

interface

uses
  System.SysUtils, Data.DB,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibGridPivoteVenta,
  inLibModoTallasIntf;

// Modo efectivo a partir de la configuracion (resuelve mcsAuto).
function DetectarModoColumnasSku(const AConfig: TConfigColumnasSku)
                                                     : TModoColumnasSku;

// Crea el modo de entrada adecuado ya construible sobre el View.
function CrearModoEntradaGrid(const AConfig: TConfigColumnasSku)
                                                     : IModoEntradaGrid;

// Modo tallas en horizontal (pivote de compras): necesita ademas la
// TGridTallasConfig del documento (tabla de celdas, campos de pivote).
// Los adaptadores de búsqueda y persistencia llegan en AConfig.Servicios.
function CrearModoEntradaGridTallas(const AConfig: TConfigColumnasSku;
                                    const ACfgTallas: TGridTallasConfig)
                                                     : IModoEntradaGrid;

// Modo tallas horizontal de pedidos de venta: no usa tabla de celdas.
function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;


implementation

uses
  inLibColumnasSkuModoSku,
  inLibColumnasSkuModoDesglose,
  inLibColumnasSkuModoTallas,
  inLibMsgArticulos;

function DetectarModoColumnasSku(const AConfig: TConfigColumnasSku)
                                                     : TModoColumnasSku;
begin
  if AConfig.Modo <> mcsAuto then
    Result := AConfig.Modo
  // Auto: hay desglose si el documento definio la primera columna de
  // atributo Y el campo existe de verdad en su cds.
  else if (AConfig.Campos.AttrValor[1] <> '') and
          (AConfig.Cds <> nil) and
          (AConfig.Cds.FindField(AConfig.Campos.AttrValor[1]) <> nil) then
    Result := mcsDesglose
  else
    Result := mcsSku;
end;

function CrearModoEntradaGrid(const AConfig: TConfigColumnasSku)
                                                     : IModoEntradaGrid;
var
  Cfg: TConfigColumnasSku;
begin
  Cfg := AConfig;
  Cfg.Modo := DetectarModoColumnasSku(AConfig);
  if Cfg.Modo in [mcsTallasInline, mcsTallasHorPed] then
    // Estos modos necesitan configuracion propia del documento.
    raise Exception.Create(SErrorFactoriaTallasHorizontalObligatoria);
  if Cfg.Modo = mcsDesglose then
  begin
    if not Assigned(Cfg.Servicios.ModoDesglose) then
      raise EArgumentNilException.Create('Servicios.ModoDesglose');
    Result := Cfg.Servicios.ModoDesglose.CrearModoDesglose(Cfg);
  end
  else
    Result := TModoEntradaSku.Create(Cfg);
end;

function CrearModoEntradaGridTallas(const AConfig: TConfigColumnasSku;
                                    const ACfgTallas: TGridTallasConfig)
                                                     : IModoEntradaGrid;
var
  Cfg: TConfigColumnasSku;
begin
  Cfg := AConfig;
  Cfg.Modo := mcsTallasInline;
  Result := TModoEntradaTallas.Create(Cfg, ACfgTallas);
end;

function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;
var
  Cfg: TConfigColumnasSku;
begin
  Cfg := AConfig;
  Cfg.Modo := mcsTallasHorPed;
  Result := inLibGridPivoteVenta.CrearModoEntradaGridPivoteVenta(
    Cfg, ACfgPivote);
end;

end.

{******************************************************************************}
{  Módulo:       inLibComprasSesionesTrazabilidad                            }
{    Tipo:       Librería                                                    }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Lotes y series por celda y almacén de la sesión (FZ-ISSUE-304).}
{******************************************************************************}
unit inLibComprasSesionesTrazabilidad;

interface

uses
  inLibComprasSesionesLecturasIntf;

// Validar antes de filtrar por almacén evita repetir una serie entre destinos.
// AExigirDatos = False (pedido: no da entrada al stock, FZ-ISSUE-425) admite
// la celda sin lote, caducidad ni series; si trae alguno, se valida igual.
function PrepararTrazabilidadSesion(
  const ALineas: TLineasDocumentoCompraMaterializacion;
  const AFiltroAlmacen: string;
  AExigirDatos: Boolean = True): TLineasDocumentoCompraMaterializacion;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  inLibTrazabilidad, inLibTrazabilidadAlta, inLibSeriesCodigosBarras,
  inLibMsgTrazabilidad;

procedure ValidarDatosLote(const ALinea: TLineaDocumentoCompraMaterializacion;
  const AAlta: TTrazabilidadAlta);
begin
  if (AAlta.Modo = mtLote) and (Trim(ALinea.Lote) = '') then
    raise EArgumentException.CreateFmt(SErrorSesionFaltaLote,
      [ALinea.CodigoArticulo, ALinea.Almacen]);
  if Length(Trim(ALinea.Lote)) > LONGITUD_MAXIMA_LOTE then
    raise EArgumentException.CreateFmt(SErrorSesionLoteLargo,
      [ALinea.CodigoArticulo]);
  if AAlta.ExigeCaducidad and (ALinea.Caducidad = 0) then
    raise EArgumentException.CreateFmt(SErrorSesionFaltaCaducidad,
      [ALinea.CodigoArticulo, ALinea.Almacen]);
  if (AAlta.Modo = mtNinguna) and
     ((Trim(ALinea.Lote) <> '') or (ALinea.Caducidad <> 0) or
      (Trim(ALinea.Series) <> '')) then
    raise EArgumentException.CreateFmt(SErrorAltaTrazabilidadNoCoincideFamilia,
      [ALinea.CodigoFamilia]);
  if (AAlta.Modo = mtSerie) and
     ((Trim(ALinea.Lote) <> '') or (ALinea.Caducidad <> 0)) then
    raise EArgumentException.CreateFmt(SErrorAltaTrazabilidadNoCoincideFamilia,
      [ALinea.CodigoFamilia]);
  if (AAlta.Modo <> mtSerie) and (Trim(ALinea.Series) <> '') then
    raise EArgumentException.CreateFmt(SErrorAltaTrazabilidadNoCoincideFamilia,
      [ALinea.CodigoFamilia]);
end;

function SinDatosTrazabilidad(
  const ALinea: TLineaDocumentoCompraMaterializacion): Boolean;
begin
  Result := (Trim(ALinea.Lote) = '') and (ALinea.Caducidad = 0) and
    (Trim(ALinea.Series) = '');
end;

procedure AgregarSeries(const ALinea: TLineaDocumentoCompraMaterializacion;
  ASeriesUsadas: TDictionary<string, Boolean>;
  AResultado: TList<TLineaDocumentoCompraMaterializacion>;
  const AFiltroAlmacen: string);
var
  rSeries: TSeriesPreparadas;
  rLinea: TLineaDocumentoCompraMaterializacion;
  sSerie, sClave: string;
begin
  rSeries := PrepararSeries(ALinea.Series);
  if not rSeries.EsCorrecta or
     not SameValue(ALinea.Cantidad, Length(rSeries.Series), 0.000001) then
    raise EArgumentException.CreateFmt(SErrorSesionSeriesCantidad,
      [ALinea.CodigoArticulo, ALinea.Almacen]);
  for sSerie in rSeries.Series do
  begin
    sClave := UpperCase(sSerie);
    if ASeriesUsadas.ContainsKey(sClave) then
      raise EArgumentException.CreateFmt(SErrorSesionSerieRepetida, [sSerie]);
    ASeriesUsadas.Add(sClave, True);
    rLinea := ALinea;
    rLinea.Lote := sSerie;
    rLinea.Caducidad := 0;
    rLinea.Cantidad := 1;
    rLinea.Series := '';
    if (AFiltroAlmacen = '') or
       SameText(rLinea.Almacen, AFiltroAlmacen) then
      AResultado.Add(rLinea);
  end;
end;

function PrepararTrazabilidadSesion(
  const ALineas: TLineasDocumentoCompraMaterializacion;
  const AFiltroAlmacen: string;
  AExigirDatos: Boolean): TLineasDocumentoCompraMaterializacion;
var
  oResultado: TList<TLineaDocumentoCompraMaterializacion>;
  oSeriesUsadas: TDictionary<string, Boolean>;
  rLinea: TLineaDocumentoCompraMaterializacion;
  rAlta: TTrazabilidadAlta;
  bPendiente: Boolean;
begin
  oResultado := TList<TLineaDocumentoCompraMaterializacion>.Create;
  oSeriesUsadas := TDictionary<string, Boolean>.Create;
  try
    for rLinea in ALineas do
    begin
      rAlta := TrazabilidadAltaFamilia(rLinea.Trazabilidad);
      // Pendiente: la trazabilidad se pedirá al recibir la mercancía.
      bPendiente := not AExigirDatos and SinDatosTrazabilidad(rLinea);
      if not bPendiente then
        ValidarDatosLote(rLinea, rAlta);
      if (rAlta.Modo = mtSerie) and not bPendiente then
        AgregarSeries(rLinea, oSeriesUsadas, oResultado, AFiltroAlmacen)
      else if (AFiltroAlmacen = '') or
              SameText(rLinea.Almacen, AFiltroAlmacen) then
        oResultado.Add(rLinea);
    end;
    Result := TLineasDocumentoCompraMaterializacion(oResultado.ToArray);
  finally
    FreeAndNil(oSeriesUsadas);
    FreeAndNil(oResultado);
  end;
end;

end.

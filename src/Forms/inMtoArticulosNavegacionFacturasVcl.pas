{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosNavegacionFacturasVcl                           }
{    Tipo:       Presentacion VCL                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Navegacion desde las lineas de un articulo a su factura de origen.        }
{******************************************************************************}
unit inMtoArticulosNavegacionFacturasVcl;

interface

uses
  System.Classes,
  cxGridDBTableView,
  inLibDestinoFacturaPersistenciaIntf;

function IntentarAbrirFacturaLineaActiva(
  AOwner: TComponent;
  AVistaLineas: TcxGridDBTableView;
  const AResolutorDestino: IResolutorDestinoFactura): Boolean;

implementation

uses
  Data.DB,
  System.SysUtils,
  inLibShowMto;

function ObtenerFacturaLineaActiva(
  AVistaLineas: TcxGridDBTableView;
  out ANumero, ASerie: string): Boolean;
var
  DataSetLineas: TDataSet;
  CampoNumero: TField;
  CampoSerie: TField;
begin
  Result := False;
  ANumero := '';
  ASerie := '';
  DataSetLineas := nil;
  if Assigned(AVistaLineas) and
     Assigned(AVistaLineas.DataController) and
     Assigned(AVistaLineas.DataController.DataSource) then
    DataSetLineas := AVistaLineas.DataController.DataSource.DataSet;
  if Assigned(DataSetLineas) and DataSetLineas.Active and
     (not DataSetLineas.IsEmpty) then
  begin
    CampoNumero := DataSetLineas.FindField('NUMERO_FAC_FACLIN');
    CampoSerie := DataSetLineas.FindField('SERIE_FAC_FACLIN');
    if Assigned(CampoNumero) and Assigned(CampoSerie) and
       (not CampoNumero.IsNull) and (not CampoSerie.IsNull) then
    begin
      ANumero := Trim(CampoNumero.AsString);
      ASerie := Trim(CampoSerie.AsString);
      Result := (ANumero <> '') and (ASerie <> '');
    end;
  end;
end;

function IntentarAbrirFacturaLineaActiva(
  AOwner: TComponent;
  AVistaLineas: TcxGridDBTableView;
  const AResolutorDestino: IResolutorDestinoFactura): Boolean;
var
  Numero: string;
  Serie: string;
begin
  Result := ObtenerFacturaLineaActiva(AVistaLineas, Numero, Serie);
  if Result then
    ShowMto(
      AOwner,
      ResolverCallFactura(AResolutorDestino, Numero, Serie),
      Numero + ',' + Serie);
end;

end.

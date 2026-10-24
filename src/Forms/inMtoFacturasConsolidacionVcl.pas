{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasConsolidacionVcl                                 }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       2.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge la factura seleccionada y delega en la aplicación de consolidar.  }
{******************************************************************************}
unit inMtoFacturasConsolidacionVcl;

interface

uses
  System.Classes,
  Data.DB,
  inLibOpcionesDocumentoIntf,
  inLibParametrosIntf,
  inLibDestinoFacturaPersistenciaIntf,
  inLibFacturasAplicacionIntf;

type
  TContextoConsolidacionFacturaVcl = record
    Facturas: TDataSet;
    Aplicacion: IAplicacionConsolidacionFactura;
    Vista: IVistaFactura;
    Usuario: string;
  end;
  TCoordinadorConsolidacionFacturaVcl = class
  public
    class procedure Ejecutar(
      const AContexto: TContextoConsolidacionFacturaVcl); static;
  end;

procedure ConfigurarConsolidacionCreacion(
  var AConfiguracion: TConfiguracionOpcionesDocumento;
  const AParametros: IParametrosAplicacion);
procedure AbrirFacturaCreadaVcl(AOwner: TComponent;
  const AResolutor: IResolutorDestinoFactura;
  const ASerie, ANumero: string; AConsolidar: Boolean);
procedure MostrarFacturaCreadaVcl(AOwner: TComponent;
  const AResolutor: IResolutorDestinoFactura;
  const ASerie, ANumero, AAlmacen: string; AConsolidar: Boolean);

implementation

uses
  System.SysUtils, Vcl.Forms,
  inMtoFacturasBase, inLibShowMto, inLibVerifactu,
  inMtoModalDocsCreados,
  inLibMensajesVcl, inLibMsgOpcionesDocumento,
  inLibMsgFacturas;

procedure ConfigurarConsolidacionCreacion(
  var AConfiguracion: TConfiguracionOpcionesDocumento;
  const AParametros: IParametrosAplicacion);
begin
  Include(AConfiguracion.Visibles, codConsolidar);
  AConfiguracion.Propuesta.ConsolidarAlCrear := False;
  if VerifactuActivo(AParametros) then
    AConfiguracion.TextoConsolidar :=
      SCaptionConsolidarEnviarOpcionesDocumento
  else if SiiActivo(AParametros) then
    AConfiguracion.TextoConsolidar :=
      SCaptionConsolidarEnviarSiiOpcionesDocumento
  else
    AConfiguracion.TextoConsolidar :=
      SCaptionConsolidarAlCrearOpcionesDocumento;
end;

procedure AbrirFacturaCreadaVcl(AOwner: TComponent;
  const AResolutor: IResolutorDestinoFactura;
  const ASerie, ANumero: string; AConsolidar: Boolean);
var
  bIniciada: Boolean;
begin
  bIniciada := False;
  ShowMto(AOwner, ResolverCallFactura(AResolutor, ANumero, ASerie),
    ANumero + ',' + ASerie,
    procedure(AFormulario: TForm)
    var
      oFactura: TfrmMtoFacturasBase;
      ds: TDataSet;
    begin
      if AConsolidar and (AFormulario is TfrmMtoFacturasBase) then
      begin
        oFactura := TfrmMtoFacturasBase(AFormulario);
        ds := oFactura.dsTablaG.DataSet;
        // La búsqueda puede fallar o dejar otro registro seleccionado.
        // Sólo se consolida el borrador que acabamos de crear.
        if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
           (ds.State = dsBrowse) and
           SameText(ds.FieldByName('SERIE_FAC').AsString, ASerie) and
           SameText(ds.FieldByName('NUMERO_FAC').AsString, ANumero) and
           oFactura.btnConsolidar.Visible and
           oFactura.btnConsolidar.Enabled then
        begin
          bIniciada := True;
          oFactura.btnConsolidarClick(oFactura.btnConsolidar);
        end;
      end;
    end);
  if AConsolidar and (not bIniciada) then
    ShowMessageFmt_fza(SAvisoConsolidarBorradorCreadoOpcionesDocumento,
      [ASerie, ANumero]);
end;

procedure MostrarFacturaCreadaVcl(AOwner: TComponent;
  const AResolutor: IResolutorDestinoFactura;
  const ASerie, ANumero, AAlmacen: string; AConsolidar: Boolean);
begin
  if AConsolidar then
    AbrirFacturaCreadaVcl(AOwner, AResolutor, ASerie, ANumero, True);
  if TfrmModalDocsCreados.MostrarDocumento(AOwner, SNombreFacturaCreada,
    ASerie, ANumero, AAlmacen) then
    AbrirFacturaCreadaVcl(AOwner, AResolutor, ASerie, ANumero, False);
end;

class procedure TCoordinadorConsolidacionFacturaVcl.Ejecutar(
  const AContexto: TContextoConsolidacionFacturaVcl);
var
  sNumero: string;
  sSerie: string;
begin
  if Assigned(AContexto.Facturas) and
     AContexto.Facturas.Active and
     (not AContexto.Facturas.IsEmpty) then
  begin
    sSerie := AContexto.Facturas.FieldByName('SERIE_FAC').AsString;
    sNumero := AContexto.Facturas.FieldByName('NUMERO_FAC').AsString;
    AContexto.Aplicacion.Ejecutar(
      sSerie,
      sNumero,
      AContexto.Usuario);
  end
  else
    AContexto.Vista.MostrarError(SErrorBorradorListaNoSeleccionado);
end;

end.

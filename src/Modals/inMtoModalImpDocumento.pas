{******************************************************************************}
{                                                                              }
{                        Módulo: inMtoModalImpDocumento                        }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inMtoModalImpDocumento;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Data.DB, frxClass,
  inMtoModalGenImp, inLibDocumentoIntf, UniDataInformeDocumento;

type
  TfrmPrintDocumento = class(TfrmPrint)
  private
    FDatos: TDatosInformeDocumento;
    FConfiguracion: TConfiguracionDocumento;
    FSerie: string;
    FNumero: string;
    procedure CrearInforme;
  protected
    procedure PrepararDatosEdicion; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    class procedure Ejecutar(AOwner: TComponent;
      ATipo: TTipoDocumento; ASentido: TSentidoDocumento;
      ACabecera: TDataSet; ALineas: TDataSet = nil);
    class procedure EjecutarReferencia(AOwner: TComponent;
      ATipo: TTipoDocumento; ASentido: TSentidoDocumento;
      const ASerie, ANumero: string);
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, inLibInformeDocumento,
  inLibDocumento, inLibCorreoTickets, UniDataFacturas, inMtoModalImpFac;

{$R *.dfm}

procedure ImprimirFactura(AOwner: TComponent;
  const ASerie, ANumero: string);
var
  oDatos: TdmFacturas;
  oFormulario: TfrmPrintFac;
begin
  oDatos := TdmFacturas.Create(AOwner);
  try
    oFormulario := TfrmPrintFac.Create(AOwner);
    try
      oFormulario.ConfigurarDataModule(oDatos);
      oFormulario.edtSerie.Text := ASerie;
      oFormulario.edtNroFac.Text := ANumero;
      oFormulario.ShowModal;
    finally
      FreeAndNil(oFormulario);
    end;
  finally
    FreeAndNil(oDatos);
  end;
end;

class procedure TfrmPrintDocumento.Ejecutar(AOwner: TComponent;
  ATipo: TTipoDocumento; ASentido: TSentidoDocumento;
  ACabecera: TDataSet; ALineas: TDataSet);
var
  oConfig: TConfiguracionDocumento;
begin
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) then
  begin
    oConfig := CrearConfiguracionDocumento(ATipo, ASentido);
    if Assigned(ALineas) and (ALineas.State in dsEditModes) then
    begin
      if (ALineas.State = dsInsert) and
         (Trim(ALineas.FieldByName(
           oConfig.CampoArticuloLinea).AsString) = '') and
         (Trim(ALineas.FieldByName(
           oConfig.CampoUnidadLinea).AsString) = '') then
        ALineas.Cancel
      else
        ALineas.Post;
    end;
    ACabecera.CheckBrowseMode;
    EjecutarReferencia(AOwner, ATipo, ASentido,
      ACabecera.FieldByName(oConfig.CampoSerieCabecera).AsString,
      ACabecera.FieldByName(oConfig.CampoNumeroCabecera).AsString);
  end;
end;

function NombreInformeDocumento(ATipo: TTipoDocumento;
  ASentido: TSentidoDocumento): string;
begin
  Result := SNombrePresupuestoVenta;
  case ATipo of
    tdPedido:
      if ASentido = sdCompra then
        Result := SNombrePedidoCompra
      else
        Result := SNombrePedidoVenta;
    tdAlbaran:
      if ASentido = sdCompra then
        Result := SNombreAlbaranCompra
      else
        Result := SNombreAlbaranVenta;
  end;
end;

function TipoDocumentoCorreo(ATipo: TTipoDocumento;
  ASentido: TSentidoDocumento;
  out ATipoCorreo: TTipoDocumentoCorreo): Boolean;
begin
  Result := True;
  ATipoCorreo := tdcPresupuesto;
  case ATipo of
    tdPedido:
      if ASentido = sdCompra then
        ATipoCorreo := tdcPedidoCompra
      else
        ATipoCorreo := tdcPedido;
    tdAlbaran:
      if ASentido = sdCompra then
        ATipoCorreo := tdcAlbaranCompra
      else
        ATipoCorreo := tdcAlbaran;
    tdPresupuesto:
      ATipoCorreo := tdcPresupuesto;
  else
    Result := False;
  end;
end;

class procedure TfrmPrintDocumento.EjecutarReferencia(AOwner: TComponent;
  ATipo: TTipoDocumento; ASentido: TSentidoDocumento;
  const ASerie, ANumero: string);
var
  eTipoCorreo: TTipoDocumentoCorreo;
  oFormulario: TfrmPrintDocumento;
begin
  if ATipo = tdFactura then
    ImprimirFactura(AOwner, ASerie, ANumero)
  else
  begin
    oFormulario := TfrmPrintDocumento.Create(AOwner);
    try
      oFormulario.FConfiguracion :=
        CrearConfiguracionDocumento(ATipo, ASentido);
      oFormulario.Name := 'frmPrintDocumento' +
        oFormulario.FConfiguracion.PrefijoCabecera;
      oFormulario.FSerie := ASerie;
      oFormulario.FNumero := ANumero;
      oFormulario.FDatos := TDatosInformeDocumento.Create(oFormulario);
      oFormulario.Caption := Format(STituloImprimirDocumento,
        [NombreInformeDocumento(ATipo, ASentido)]);
      oFormulario.CrearInforme;
      if TipoDocumentoCorreo(ATipo, ASentido, eTipoCorreo) then
        oFormulario.ConfigurarDocumentoCorreo(eTipoCorreo, ASerie, ANumero);
      oFormulario.ShowModal;
    finally
      FreeAndNil(oFormulario);
    end;
  end;
end;

procedure TfrmPrintDocumento.CrearInforme;
var
  sTercero: string;
begin
  sTercero := SInformeClienteDocumento;
  if FConfiguracion.Sentido = sdCompra then
    sTercero := SInformeProveedorDocumento;
  CrearInformeDocumento(frxrprt1, FDatos.Cabecera, FDatos.Lineas,
    FDatos.Impuestos, NombreInformeDocumento(
      FConfiguracion.TipoDocumento, FConfiguracion.Sentido), sTercero);
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintDocumento.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintDocumento.preparar_consulta;
begin
  FDatos.Abrir(ConexionPrincipal, FConfiguracion, FSerie, FNumero);
end;

procedure TfrmPrintDocumento.AfterReportLoaded;
var
  iObjeto: Integer;
  oObjeto: TfrxComponent;
begin
  inherited;
  frxrprt1.EnabledDataSets.Clear;
  frxrprt1.EnabledDataSets.Add(FDatos.Cabecera);
  frxrprt1.EnabledDataSets.Add(FDatos.Lineas);
  frxrprt1.EnabledDataSets.Add(FDatos.Impuestos);
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(FDatos.Cabecera);
  frxrprt1.DataSets.Add(FDatos.Lineas);
  frxrprt1.DataSets.Add(FDatos.Impuestos);
  for iObjeto := 0 to frxrprt1.AllObjects.Count - 1 do
  begin
    oObjeto := TfrxComponent(frxrprt1.AllObjects[iObjeto]);
    if (oObjeto is TfrxDataBand) and
       SameText(TfrxDataBand(oObjeto).DataSetName, 'Lineas') then
      TfrxDataBand(oObjeto).DataSet := FDatos.Lineas
    else if (oObjeto is TfrxDataBand) and
       SameText(TfrxDataBand(oObjeto).DataSetName, 'Impuestos') then
      TfrxDataBand(oObjeto).DataSet := FDatos.Impuestos;
  end;
end;

end.

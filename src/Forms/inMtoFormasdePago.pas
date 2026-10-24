{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFormasdePago                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de formas de pago.                                          }
{    Configuracion de medios de cobro y plazos asociados.                      }
{******************************************************************************}
unit inMtoFormasdePago;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
   cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataFormasdePago,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, Vcl.AppEvnts, JvComponentBase, JvEnterTab, System.Actions,
  Vcl.ActnList, dxShellDialogs;

type
  TfrmMtoFormasdePago = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
    pcPestana: TcxPageControl;
    tsMasDatos: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlInnerHeader: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsOtros: TcxTabSheet;
    pnlBotonera: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    chkActivo: TcxDBCheckBox;
    txtNOMBRE_FORMAPAGO: TcxDBTextEdit;
    txtCODIGO_FORMAPAGO: TcxDBTextEdit;
    tsVentas: TcxTabSheet;
    splFicha: TcxSplitter;
    lblOrden: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    cxGrdDBTabPrinCODIGO_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinACTIVO_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinORDEN_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinN_PLAZOS_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinDIAS_ENTRE_PLAZOS_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinDEFAULT_FORMAPAGO: TcxGridDBColumn;
    lblNPlazos: TcxLabel;
    spnN_PLAZOS_FORMA_PAGO_FP: TcxDBSpinEdit;
    lblDiasEntrePlazos: TcxLabel;
    spnN_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP: TcxDBSpinEdit;
    lblPctAdelanto: TcxLabel;
    spnPORCENTAJE_ANTICIPO_FORMA_PAGO_FP: TcxDBSpinEdit;
    pnlFactura: TPanel;
    cxgrdFacturas: TcxGrid;
    tvFacturacion: TcxGridDBTableView;
    tvFacturacionFECHA_FACTURA: TcxGridDBColumn;
    tvFacturacionNRO_FACTURA: TcxGridDBColumn;
    tvFacturacionSERIE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn;
    tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvLineasFacturacion: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn;
    tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn;
    tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlFacturas: TcxGridLevel;
    cxgrdlvlLineas: TcxGridLevel;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    btnIraCliente: TcxButton;
    btnExportarExcel: TcxButton;
    cxGrdDBTabPrinPORCEN_ANTICIPO_FORMAPAGO: TcxGridDBColumn;
    alFormasdePago: TActionList;
    actClientes: TAction;
    actArticulos: TAction;
    actFacturas: TAction;
    actEmpresas: TAction;
    btnIraEmpresa: TcxButton;
    btnIraArticulo: TcxButton;
    tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn;
    tvLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESVERBANCOEMPRESA_FORMAPAGO: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    chkESVERBANCOEMPRESA_FORMA_PAGO_FP: TcxDBCheckBox;
    cxGrdDBTabPrinCODIGO_FACTURAE_FP: TcxGridDBColumn;
    lblCodigoFacturae: TcxLabel;
    txtCODIGO_FACTURAE_FP: TcxDBTextEdit;
    procedure btnGrabarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure actEmpresasExecute(Sender: TObject);
    procedure btnIraEmpresaClick(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
  public
    dmmFormasdePago: TdmFormasdePago;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibWin, inLibUser, inLibDevExp, inLibShowMto, inLibFotos,
  UniDataDestinoFacturaRepositorio;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// La pestana de ventas muestra lineas con articulo
// (tvLineasFacturacion, CODIGO_ART_FACLIN); ese es el articulo activo.
procedure TfrmMtoFormasdePago.ResolverArtSkuActivo(out ACodArt,
                                                       ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasFacturacion.DataController.DataSource) then
  begin
    ds := tvLineasFacturacion.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoFormasdePago.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmFormasdePago) then
    Result := [dsTablaG, dmmFormasdePago.dsFacturasLineas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoFormasdePago.actArticulosExecute(Sender: TObject);
begin
  inherited;
  if (pcPestana.ActivePage = tsVentas) then
     btnIraArticuloClick(Sender)
   else
     ShowMto(Self.Owner,
             'Articulos');
end;

procedure TfrmMtoFormasdePago.actClientesExecute(Sender: TObject);
begin
  inherited;
    if ((pcPestana.ActivePage = tsVentas)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoFormasdePago.actEmpresasExecute(Sender: TObject);
begin
  inherited;
  if (pcPestana.ActivePage = tsVentas) then
    btnIraEmpresaClick(Sender)
  else
    ShowMto(Self.Owner,
            'Empresas');
end;

procedure TfrmMtoFormasdePago.btnIraFacturaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          ResolverCallFactura(
            CrearResolutorDestinoFacturaUniDAC(
              ConexionPrincipal),
            tvFacturacion.DataController.DataSource.DataSet.FieldByName(
              'NUMERO_FAC').AsString,
            tvFacturacion.DataController.DataSource.DataSet.FieldByName(
              'SERIE_FAC').AsString),
          tvFacturacion.DataController.DataSource.DataSet.FieldByName(
            'NUMERO_FAC').AsString + ',' +
          tvFacturacion.DataController.DataSource.DataSet.FieldByName(
            'SERIE_FAC').AsString);
end;

procedure TfrmMtoFormasdePago.actFacturasExecute(Sender: TObject);
begin
  inherited;
  if (
        (pcPestana.ActivePage = tsVentas)        and
        (not(tvFacturacion.DataController.DataSet.FieldByName(
          'NUMERO_FAC').IsNull)) and
        (not(tvFacturacion.DataController.DataSet.FieldByName(
          'SERIE_FAC').IsNull))
       ) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoFormasdePago.btnExportarExcelClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdFacturas,
                'Historico_Formas_de_pago' +
                dsTablaG.Dataset.FieldByName(
                  'DESCRIPCION_FORMA_PAGO_FP').AsString);
end;

procedure TfrmMtoFormasdePago.btnGrabarClick(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoFormasdePago.btnIraArticuloClick(Sender: TObject);
var
  sCodArt: string;
  vw: TcxCustomGridView;
  dbView: TcxGridDBTableView;
  col: TcxGridDBColumn;
begin
  inherited;
  sCodArt := '';
  vw := cxgrdFacturas.FocusedView;
  if (vw <> nil) and (vw is TcxGridDBTableView) then
  begin
    dbView := TcxGridDBTableView(vw);
    col := dbView.GetColumnByFieldName('CODIGO_ART_FACLIN');
    if Assigned(col) and Assigned(dbView.Controller.FocusedRecord) then
      sCodArt := VarToStr(
        dbView.Controller.FocusedRecord.Values[col.Index]);
  end;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

procedure TfrmMtoFormasdePago.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Clientes',
          tvFacturacion.DataController.DataSet.FieldByName(
            'CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoFormasdePago.btnIraEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          tvFacturacion.DataController.DataSet.FieldByName(
                                            'CODIGO_EMP_FAC').AsString);

end;

procedure TfrmMtoFormasdePago.CrearTablaPrincipal;
begin
  inherited;
  dmmFormasdePago := tdmDataModule as TdmFormasdePago;
  tvFacturacion.DataController.DataSource := dmmFormasdePago.dsFacturas;
  tvLineasFacturacion.DataController.DataSource :=
                                               dmmFormasdePago.dsFacturasLineas;
  pcPestana.ActivePage := tsMasDatos;
  pkFieldName := 'CODIGO_FP_FP';
end;

procedure TfrmMtoFormasdePago.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoFormasdePago.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_FORMAPAGO.Enabled := True
  else
  begin
    txtCODIGO_FORMAPAGO.Enabled := False;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoFormasdePago);
  ForceReferenceToClass(TfrmMtoFormasdePago);
end.

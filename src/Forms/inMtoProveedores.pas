{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoProveedores                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de proveedores.                                             }
{    CRUD sobre fza_proveedores con datos fiscales y comerciales.              }
{******************************************************************************}
unit inMtoProveedores;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, inMtoGen,
  dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  Vcl.Menus, cxContainer, dxSkinsForm, cxClasses, cxLocalization, cxDBNavigator,
  cxLabel, Vcl.StdCtrls, cxButtons, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  Vcl.ExtCtrls, UniDataConn, UniDataProveedores, Vcl.ToolWin,
  Vcl.ActnMan, Vcl.ActnCtrls, cxTextEdit, Vcl.Buttons, dxBevel, cxCurrencyEdit,
  cxCalendar, cxMaskEdit, cxDropDownEdit, cxDBEdit, dxGDIPlusClasses, cxImage,
  cxCustomListBox, cxCheckListBox, cxDBCheckListBox, cxCheckBox, cxMemo,
  inLibDevExp, cxBlobEdit, ClipBrd, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  cxSplitter, cxSpinEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxGroupBox, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, inLibFotoMiniaturaMtoVcl;

type
  TfrmMtoProveedores = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn;
    pnlCabFicha: TPanel;
    txtCODIGO_PROVEEDOR: TcxDBTextEdit;
    lblCodigo: TcxLabel;
    txtRAZONSOCIAL_PROVEEDOR: TcxDBTextEdit;
    lblRazonSocial: TcxLabel;
    txtNOMBRE_PROVEEDOR: TcxDBTextEdit;
    lblNombreComercial: TcxLabel;
    cxdbtxtdtTELEFONO2: TcxDBTextEdit;
    lblEmail: TcxLabel;
    cxdbtxtdtEMAIL: TcxDBTextEdit;
    lblNif: TcxLabel;
    cxdbtxtdtNIF: TcxDBTextEdit;
    cxdbtxtdtMOVIL_CLIENTE: TcxDBTextEdit;
    pnlDetailFicha: TPanel;
    pcPestanas: TcxPageControl;
    tsPagos: TcxTabSheet;
    lblFormaPagoPrv: TcxLabel;
    cbbFormaPagoPrv: TcxDBLookupComboBox;
    lblEmpBanPrv: TcxLabel;
    cbbEmpBanPrv: TcxDBLookupComboBox;
    tsDomicilioFiscal: TcxTabSheet;
    cxdbtxtdt7: TcxDBTextEdit;
    lblDireccion1: TcxLabel;
    lblCodPostal: TcxLabel;
    cxdbtxtdt8: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    cxdbtxtdt9: TcxDBTextEdit;
    cxdbtxtdt10: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    cxdbtxtdt16: TcxDBTextEdit;
    chkESIVA_EXENTO_INTRACOMUNITARIO_PRV: TcxDBCheckBox;
    chkESFACTURACION_DIRECTA_PRV: TcxDBCheckBox;
    lblPais: TcxLabel;
    // Combo de pais (fza_paises via vi_paises). cxdbtxtdt16 (PAIS_PRV)
    // queda oculto: sigue guardando el nombre denormalizado que usan
    // impresos y ActualizarIvaExentoIntracomunitarioPorPais.
    cbbPaisPrv: TcxDBLookupComboBox;
    cxdbtxtdtDireccion: TcxDBTextEdit;
    lblDireccion2: TcxLabel;
    tsMasDatos: TcxTabSheet;
    lblObservaciones: TcxLabel;
    lblReferencia: TcxLabel;
    cxdbtxtdtREFERENCIA_CLIENTE: TcxDBTextEdit;
    lblContacto: TcxLabel;
    cxdbtxtdtREFERENCIA_CLIENTE1: TcxDBTextEdit;
    cxdbtxtdtIBAN: TcxDBTextEdit;
    lblNroCuenta: TcxLabel;
    lblTelefonoContacto: TcxLabel;
    cxdbtxtdtCONTACTO_CLIENTE: TcxDBTextEdit;
    tsOtros: TcxTabSheet;
    pnl3: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxdbm2: TcxDBMemo;
    chkActivo: TcxDBCheckBox;
    cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinVARIOS_TIPOS_IVA_PRV: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    pnl6: TPanel;
    btnIraArticulo: TcxButton;
    pnl61: TPanel;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnArticulosESPROVEEDORPRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn;
    tsVentas: TcxTabSheet;
    cxgrdLinFac: TcxGrid;
    tvLinFac: TcxGridDBTableView;
    cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlLinFac: TcxGridLevel;
    cxspltr1: TcxSplitter;
    lblTextoLegal11: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevoProveedor: TcxButton;
    dbcLinFacNOMBRE_TIPO_IVA: TcxGridDBColumn;
    dbcLinFacCODIGO_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    pnl62: TPanel;
    btnIraFactura: TcxButton;
    btnIraCliente: TcxButton;
    dbcLinFacCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    btnExportar: TcxButton;
    btnIraArticuloVentas: TcxButton;
    ActionListProveedores: TActionList;
    actArticulos: TAction;
    actFacturas: TAction;
    actClientes: TAction;
    // Pestaña Compras: defectos para sesiones de compra + kits por talla
    tsCompras: TcxTabSheet;
    gbDefectosCompras: TcxGroupBox;
    rbCoeficientePrv: TcxRadioButton;
    rbMargenVentaPrv: TcxRadioButton;
    spnMargenVentaPrv: TcxSpinEdit;
    spnMargenPrv: TcxDBSpinEdit;
    chkVariosTiposIvaPrv: TcxDBCheckBox;
    chkESDESCRIPCION_BLANCO_PRV: TcxDBCheckBox;
    lblSistemaTallasPrv: TcxLabel;
    cbbSistemaTallasPrv: TcxDBLookupComboBox;
    lblDefectosInfo: TcxLabel;
    gbKitsPrv: TcxGroupBox;
    pnlKitsTop: TPanel;
    btnAddKit: TcxButton;
    btnDelKit: TcxButton;
    btnGenerarTallasKit: TcxButton;
    btnAddKitDet: TcxButton;
    btnDelKitDet: TcxButton;
    cxgrdKits: TcxGrid;
    tvKits: TcxGridDBTableView;
    dbcKitCodigo: TcxGridDBColumn;
    dbcKitNombre: TcxGridDBColumn;
    dbcKitSistema: TcxGridDBColumn;
    glKits: TcxGridLevel;
    cxgrdKitsDet: TcxGrid;
    tvKitsDet: TcxGridDBTableView;
    dbcKitDetValor: TcxGridDBColumn;
    dbcKitDetCantidad: TcxGridDBColumn;
    dbcKitDetOrden: TcxGridDBColumn;
    glKitsDet: TcxGridLevel;
    tsPedidosCompra: TcxTabSheet;
    tsAlbaranesCompra: TcxTabSheet;
    tsFacturasCompra: TcxTabSheet;
    tsEfectosCompra: TcxTabSheet;
    procedure btnGrabarClick(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure btnNuevoProveedorClick(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnAddKitClick(Sender: TObject);
    procedure btnDelKitClick(Sender: TObject);
    procedure btnGenerarTallasKitClick(Sender: TObject);
    procedure btnAddKitDetClick(Sender: TObject);
    procedure btnDelKitDetClick(Sender: TObject);
    procedure cxdbtxtdt16PropertiesChange(Sender: TObject);
    procedure cbbPaisPrvPropertiesChange(Sender: TObject);
    procedure CambiarModoPrecio(Sender: TObject);
    procedure CambiarMargenVenta(Sender: TObject);
    procedure ActualizarMargenVenta(Sender: TObject);
  private
    FSincronizandoPrecio: Boolean;
    FDmmProveedores: TDMProveedores;
    FMiniaturaFoto: TMiniaturaFotoMto;
    FPestanasDocumentos: array[TDocumentoCompraProveedor] of TcxTabSheet;
    FBotonesDocumentos: array[TDocumentoCompraProveedor] of TcxButton;
    FFacturasOrdinarias: Boolean;
    FComprasDirectas: Boolean;
    function PuedeConsultarDocumento(const APantalla: string): Boolean;
    function CrearVistaDocumentos(AContenedor: TWinControl; AAlineacion: TAlign;
      AFuente: TDataSource): TcxGridDBTableView;
    procedure CrearPestanasDocumentos;
    procedure CrearContenidoDocumentos(ATipo: TDocumentoCompraProveedor);
    procedure ActualizarBotonDocumento(Sender: TObject; Field: TField);
    procedure AbrirDocumentoSeleccionado(Sender: TObject);
    procedure PcPestanasChange(Sender: TObject);
    procedure ActualizarFotoProveedor(Sender: TObject);
    // Evita que el Enter del formulario (tvEnterAsTab) se coma la
    // seleccion con Enter dentro de un combo desplegado.
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
  public
    procedure CrearTablaPrincipal; override;
    procedure AplicarEtiquetas; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibMensajesVcl, inLibComprasSesiones,
  inLibComboPais,
  inLibWin,
  inLibUser,
  inLibShowMto,
  inLibFotos,
  inLibMsgCompras,
  UniDataDestinoFacturaRepositorio, inLibUnitForm, inLibComprasDirectas,
  inLibFormatoMonetario;

{$R *.dfm}

const
  PantallasCompra: array[TDocumentoCompraProveedor] of string =
    ('PedidosCompra', 'AlbaranesCompra', 'FacturasCompra', 'EfectosCompra');
  PantallaCompraDirecta = 'ComprasDirectasTerceros';

resourcestring
  SAbrirDocumentoCompra = 'Abrir para editar';
  SAbrirEfectoCompra = 'Abrir efecto';
  SLineasDocumentoCompra = 'Líneas del documento';
  SPagosDelEfecto = 'Pagos del efecto';

procedure TfrmMtoProveedores.CambiarModoPrecio(Sender: TObject);
begin
  ActualizarMargenVenta(Sender);
  spnMargenPrv.Enabled := rbCoeficientePrv.Checked;
  spnMargenVentaPrv.Enabled := rbMargenVentaPrv.Checked;
end;

procedure TfrmMtoProveedores.ActualizarMargenVenta(Sender: TObject);
begin
  if Assigned(spnMargenVentaPrv) and not FSincronizandoPrecio then
  begin
    FSincronizandoPrecio := True;
    try
      spnMargenVentaPrv.Value := MargenVentaDesdeCoeficiente(
        StrToFloatDef(VarToStr(spnMargenPrv.EditValue), 0));
    finally
      FSincronizandoPrecio := False;
    end;
  end;
end;

procedure TfrmMtoProveedores.CambiarMargenVenta(Sender: TObject);
var
  Campo: TField;
  Valor: Variant;
begin
  if rbMargenVentaPrv.Checked and not FSincronizandoPrecio then
  begin
    Campo := spnMargenPrv.DataBinding.Field;
    Valor := spnMargenVentaPrv.Value;
    if Assigned(Campo) and Campo.DataSet.CanModify and
       not VarIsNull(Valor) and not VarIsEmpty(Valor) then
    begin
      FSincronizandoPrecio := True;
      try
        Campo.DataSet.Edit;
        Campo.AsFloat := CoeficienteDesdeMargenVenta(Valor);
        spnMargenPrv.EditValue := Campo.AsFloat;
      finally
        FSincronizandoPrecio := False;
      end;
    end;
  end;
end;


procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoProveedores.ResolverArtSkuActivo(
  out ACodArt, ACodSku: string);
var
  Fuente: TDataSource;
  Tipo: TDocumentoCompraProveedor;
begin
  ACodArt := '';
  ACodSku := '';
  Fuente := nil;
  if Assigned(FDmmProveedores) and (pcPantalla.ActivePage = tsFicha) then
  begin
    if pcPestanas.ActivePage = tsArticulos then
      Fuente := FDmmProveedores.dsArticulos
    else if pcPestanas.ActivePage = tsVentas then
      Fuente := FDmmProveedores.dsLinFacturasArticulos
    else
      for Tipo := dcpPedido to dcpFactura do
        if pcPestanas.ActivePage = FPestanasDocumentos[Tipo] then
          Fuente := FDmmProveedores.LineasDocumento[Tipo];
  end;
  if Assigned(Fuente) then
    inLibFotos.LeerArtSkuDeDataSet(Fuente.DataSet, ACodArt, ACodSku);
end;

function TfrmMtoProveedores.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := [dsTablaG];
  if Assigned(FDmmProveedores) then
    Result := Result + [
      FDmmProveedores.dsArticulos, FDmmProveedores.dsLinFacturasArticulos,
      FDmmProveedores.LineasDocumento[dcpPedido],
      FDmmProveedores.LineasDocumento[dcpAlbaran],
      FDmmProveedores.LineasDocumento[dcpFactura]];
end;

procedure TfrmMtoProveedores.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  if pcPestanas.ActivePage = tsArticulos then
    ShowMto(Self.Owner,
            'Articulos',
            FDmmProveedores.unqryArticulos.FieldByName(
              'CODIGO_ART_ART').AsString)
  else
    if pcPestanas.ActivePage = tsVentas then
      ShowMto(Self.Owner,
              'Articulos',
              FDmmProveedores.unqryLinFacturasArticulos.FieldByName(
                'CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoProveedores.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Clientes',
          FDmmProveedores.unqryLinFacturasArticulos.FieldByName(
                                            'CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoProveedores.btnIraFacturaClick(Sender: TObject);
var
  sNroFactura, sSerieFactura:String;
begin
  inherited;
  sNroFactura := tvLinFac.DataController.DataSet.FieldByName(
                                                  'NUMERO_FAC_FACLIN').AsString;
  sSerieFactura := tvLinFac.DataController.DataSet.FieldByName(
                                                'SERIE_FAC_FACLIN').AsString;
  // Las ventas de caja son simplificadas: viven en otra pantalla.
  ShowMto(Self.Owner,
          ResolverCallFactura(
            CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
            sNroFactura,
            sSerieFactura),
          sNroFactura +','+ sSerieFactura);
end;

procedure TfrmMtoProveedores.btnNuevoProveedorClick(Sender: TObject);
begin
  inherited;
  if ( (FDmmProveedores.unqryTablaG.State = dsInsert) or
       (FDmmProveedores.unqryTablaG.State = dsEdit)) then
  begin
    FDmmProveedores.unqryTablaG.Post;
  end;
  FDmmProveedores.unqryTablaG.Insert;
  tsFicha.SetFocus;
  pcPestanas.ActivePageIndex := tsDomicilioFiscal.PageIndex;
  txtRAZONSOCIAL_PROVEEDOR.SetFocus;
end;

procedure TfrmMtoProveedores.actClientesExecute(Sender: TObject);
begin
  inherited;
  //Control + K
    if (
      (pcPestanas.ActivePage = tsVentas)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoProveedores.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F
    if (
        (pcPestanas.ActivePage = tsVentas)) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoProveedores.actArticulosExecute(Sender: TObject);
begin
  inherited;
  // Control + R
  btnIraArticuloClick(Sender);
end;

procedure TfrmMtoProveedores.btnExportarClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdLinFac,
                'Ventas de artículos por proveedor_' +
                     dsTablaG.DataSet.FieldByName('CODIGO_PRV_PRV').AsString);
end;

procedure TfrmMtoProveedores.btnGrabarClick(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoProveedores.AplicarEtiquetas;

  procedure RestaurarPrefijo(APestana: TcxTabSheet; const APrefijo: string);
  var
    Titulo: string;
    Separador, Numero: Integer;
  begin
    Titulo := APestana.Caption;
    Separador := Pos('_', Titulo);
    if (Separador > 0) and TryStrToInt(
      StringReplace(Copy(Titulo, 1, Separador - 1), '&', '', []), Numero) then
      Delete(Titulo, 1, Separador);
    if Titulo.StartsWith('&') then
      Delete(Titulo, 1, 1);
    APestana.Caption := APrefijo + Titulo;
  end;

begin
  inherited;
  // Los textos de traducciones existentes pueden traer la numeración anterior.
  RestaurarPrefijo(tsCompras, '&5_');
  RestaurarPrefijo(tsPagos, '10_&');
  RestaurarPrefijo(tsOtros, '11_&');
end;

function TfrmMtoProveedores.PuedeConsultarDocumento(
  const APantalla: string): Boolean;
var
  Anfitrion: IAnfitrionPantallas;
  Pantalla: TfzaForm;
begin
  Result := False;
  if Supports(Owner, IAnfitrionPantallas, Anfitrion) then
  begin
    Pantalla := Anfitrion.RegistroPantallas.GetElement(APantalla);
    Result := Assigned(Pantalla) and
      (not Assigned(Pantalla.mnMenuItem) or
       (Pantalla.mnMenuItem.Visible and Pantalla.mnMenuItem.Enabled));
  end;
end;

procedure TfrmMtoProveedores.CrearPestanasDocumentos;
var
  Tipo: TDocumentoCompraProveedor;
begin
  FPestanasDocumentos[dcpPedido] := tsPedidosCompra;
  FPestanasDocumentos[dcpAlbaran] := tsAlbaranesCompra;
  FPestanasDocumentos[dcpFactura] := tsFacturasCompra;
  FPestanasDocumentos[dcpEfecto] := tsEfectosCompra;
  FFacturasOrdinarias := PuedeConsultarDocumento(PantallasCompra[dcpFactura]);
  FComprasDirectas := PuedeConsultarDocumento(PantallaCompraDirecta);
  for Tipo := Low(Tipo) to High(Tipo) do
    if Tipo = dcpFactura then
      FPestanasDocumentos[Tipo].TabVisible :=
        FFacturasOrdinarias or FComprasDirectas
    else
      FPestanasDocumentos[Tipo].TabVisible :=
        PuedeConsultarDocumento(PantallasCompra[Tipo]);
end;

function TfrmMtoProveedores.CrearVistaDocumentos(AContenedor: TWinControl;
  AAlineacion: TAlign; AFuente: TDataSource): TcxGridDBTableView;
var
  Rejilla: TcxGrid;
begin
  Rejilla := TcxGrid.Create(AContenedor);
  Rejilla.Parent := AContenedor;
  Rejilla.Top := 1;
  Rejilla.Height := ScaleValue(145);
  Rejilla.Align := AAlineacion;
  Result := Rejilla.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  Rejilla.Levels.Add.GridView := Result;
  Result.DataController.DataSource := AFuente;
  Result.OptionsData.Editing := False;
  Result.OptionsData.Inserting := False;
  Result.OptionsData.Deleting := False;
  Result.OptionsSelection.CellSelect := False;
  Result.OptionsView.GroupByBox := False;
end;

procedure TfrmMtoProveedores.CrearContenidoDocumentos(
  ATipo: TDocumentoCompraProveedor);
var
  Pestana: TcxTabSheet;
  Barra: TPanel;
  Boton: TcxButton;
  Separador: TcxSplitter;
  Detalle: TcxGroupBox;
  Cabecera, Lineas: TcxGridDBTableView;

  procedure Columna(AVista: TcxGridDBTableView;
    const ACampo, ATitulo: string; AAncho: Integer;
    AMonetaria: Boolean = False);
  var
    Nueva: TcxGridDBColumn;
  begin
    Nueva := AVista.CreateColumn;
    Nueva.Caption := ATitulo;
    Nueva.DataBinding.FieldName := ACampo;
    Nueva.Width := ScaleValue(AAncho);
    if AMonetaria then
      FormatearColumnaMonetaria(Nueva);
  end;

begin
  Pestana := FPestanasDocumentos[ATipo];
  Pestana.DisableAlign;
  try
    Barra := TPanel.Create(Pestana);
    Barra.Parent := Pestana;
    Barra.Align := alTop;
    Barra.BevelOuter := bvNone;
    Barra.Height := ScaleValue(32);
    Boton := TcxButton.Create(Barra);
    Boton.Parent := Barra;
    Boton.SetBounds(ScaleValue(4), ScaleValue(2), ScaleValue(155),
      ScaleValue(28));
    Boton.Caption := SAbrirDocumentoCompra;
    if ATipo = dcpEfecto then
      Boton.Caption := SAbrirEfectoCompra;
    Boton.Tag := Ord(ATipo);
    Boton.Enabled := False;
    Boton.OnClick := AbrirDocumentoSeleccionado;
    FBotonesDocumentos[ATipo] := Boton;

    Cabecera := CrearVistaDocumentos(Pestana, alTop,
      FDmmProveedores.Documentos[ATipo]);
    Columna(Cabecera, 'SERIE', 'Serie', 55);
    Columna(Cabecera, 'NUMERO', 'Número', 85);
    if ATipo = dcpEfecto then
    begin
      Columna(Cabecera, 'EFECTO', 'Efecto', 55);
      Columna(Cabecera, 'FECHA', 'Vencimiento', 100);
    end
    else
      Columna(Cabecera, 'FECHA', 'Fecha', 91);
    Columna(Cabecera, 'ESTADO', 'Estado', 100);
    if ATipo <> dcpEfecto then
      Columna(Cabecera, 'REFERENCIA', 'Referencia proveedor', 135);
    Columna(Cabecera, 'IMPORTE', 'Importe', 105, True);
    if ATipo = dcpFactura then
      Columna(Cabecera, 'MODALIDAD', 'Modalidad', 95)
    else if ATipo = dcpEfecto then
    begin
      Columna(Cabecera, 'PAGADO', 'Pagado', 105, True);
      Columna(Cabecera, 'PENDIENTE', 'Pendiente', 105, True);
    end;

    Separador := TcxSplitter.Create(Pestana);
    Separador.Parent := Pestana;
    Separador.Top := 2;
    Separador.Height := ScaleValue(6);
    Separador.AlignSplitter := salTop;
    Separador.Control := Cabecera.Control;

    Detalle := TcxGroupBox.Create(Pestana);
    Detalle.Parent := Pestana;
    Detalle.Align := alClient;
    Detalle.Caption := SLineasDocumentoCompra;
    if ATipo = dcpEfecto then
      Detalle.Caption := SPagosDelEfecto;
    Lineas := CrearVistaDocumentos(Detalle, alClient,
      FDmmProveedores.LineasDocumento[ATipo]);
    if ATipo = dcpEfecto then
    begin
      Columna(Lineas, 'LINEA', 'Pago', 52);
      Columna(Lineas, 'FECHA', 'Fecha', 96);
      Columna(Lineas, 'TIPO_PAGO', 'Tipo de pago', 140);
      Columna(Lineas, 'REFERENCIA', 'Referencia', 175);
    end
    else
    begin
      Columna(Lineas, 'LINEA', 'Línea', 52);
      Columna(Lineas, 'CODIGO_UNIDAD_SKU', 'SKU', 95);
      Columna(Lineas, 'DESCRIPCION', 'Descripción', 195);
      Columna(Lineas, 'CANTIDAD', 'Cantidad', 68);
      Columna(Lineas, 'PRECIO', 'Precio sin IVA', 105, True);
      Columna(Lineas, 'IVA', '% IVA', 54);
    end;
    Columna(Lineas, 'IMPORTE', 'Importe', 105, True);
    FDmmProveedores.Documentos[ATipo].OnDataChange := ActualizarBotonDocumento;
  finally
    Pestana.EnableAlign;
  end;
end;

procedure TfrmMtoProveedores.ActualizarBotonDocumento(Sender: TObject;
  Field: TField);
var
  Tipo: TDocumentoCompraProveedor;
  Datos: TDataSet;
begin
  if not (csDestroying in ComponentState) then
    for Tipo := Low(Tipo) to High(Tipo) do
      if Assigned(FBotonesDocumentos[Tipo]) and
         (Sender = FDmmProveedores.Documentos[Tipo]) then
      begin
        Datos := FDmmProveedores.Documentos[Tipo].DataSet;
        FBotonesDocumentos[Tipo].Enabled :=
          Assigned(Datos) and Datos.Active and not Datos.IsEmpty;
      end;
end;

procedure TfrmMtoProveedores.AbrirDocumentoSeleccionado(Sender: TObject);
var
  Tipo: TDocumentoCompraProveedor;
  Datos: TDataSet;
  Pantalla, Clave: string;
begin
  Tipo := TDocumentoCompraProveedor(TcxButton(Sender).Tag);
  Datos := FDmmProveedores.Documentos[Tipo].DataSet;
  Clave := ClaveMtoDataSet(Datos, 'SERIE', 'NUMERO');
  if Clave <> '' then
  begin
    Pantalla := PantallasCompra[Tipo];
    if Tipo = dcpEfecto then
      Clave := Clave + ',' + Datos.FieldByName('EFECTO').AsString
    else if (Tipo = dcpFactura) and
      (ModalidadCompra(Datos.FieldByName('MODALIDAD').AsString) <>
        mcdOrdinaria) then
      Pantalla := PantallaCompraDirecta;
    ShowMto(Owner, Pantalla, Clave);
  end;
end;

procedure TfrmMtoProveedores.CrearTablaPrincipal;
begin
  inherited;
  FDmmProveedores := tdmDataModule as TdmProveedores;
  chkESDESCRIPCION_BLANCO_PRV.Caption :=
    SComprasDejarDescripcionBlanco;
  tvArticulos.DataController.DataSource := FDmmProveedores.dsArticulos;
  tvLinFac.DataController.DataSource :=
    FDmmProveedores.dsLinFacturasArticulos;
  // Pestaña Compras: kits de cantidades por talla. Cada kit lleva su
  // sistema de tallas (lookup sobre conjuntos TAL). Mismo patron runtime
  // que Articulos/Ventas.
  tvKits.DataController.DataSource    := FDmmProveedores.dsKits;
  tvKitsDet.DataController.DataSource := FDmmProveedores.dsKitsDet;
  TcxLookupComboBoxProperties(dbcKitSistema.Properties).ListSource :=
    FDmmProveedores.dsConjuntosTallas;
  // Sistema de tallas por defecto del proveedor (cabecera): se copia a la
  // sesion de compra al elegir este proveedor (ver CopiarDefectosProveedor
  // en inMtoComprasSesiones). Mismo lookup que el de los kits.
  TcxLookupComboBoxProperties(cbbSistemaTallasPrv.Properties).ListSource :=
    FDmmProveedores.dsConjuntosTallas;
  // Pestaña Pagos: combos de forma de pago y banco de empresa por defecto.
  TcxLookupComboBoxProperties(cbbFormaPagoPrv.Properties).ListSource :=
    FDmmProveedores.dsFormasPago;
  TcxLookupComboBoxProperties(cbbEmpBanPrv.Properties).ListSource :=
    FDmmProveedores.dsEmpresasBancos;
  // Pais del domicilio fiscal: combo sobre fza_paises (vi_paises).
  TcxLookupComboBoxProperties(cbbPaisPrv.Properties).ListSource :=
    FDmmProveedores.dsPaises;
  ConfigurarComboPaisNumerico(cbbPaisPrv);
  // El Enter del formulario mueve el foco al siguiente control
  // (tvEnterAsTab): dentro de un combo desplegado eso impide seleccionar
  // con Enter. Lo desactivamos mientras el combo tiene foco o esta abierto.
  DesactivarEnterAsTabEnCombo(cbbSistemaTallasPrv);
  DesactivarEnterAsTabEnCombo(cbbFormaPagoPrv);
  DesactivarEnterAsTabEnCombo(cbbEmpBanPrv);
  DesactivarEnterAsTabEnCombo(cbbPaisPrv);
  CrearPestanasDocumentos;
  // Otros, la menos usada, va la última.
  tsOtros.PageIndex := pcPestanas.PageCount - 1;
  pcPestanas.ActivePage := tsDomicilioFiscal;
  pkFieldName := 'CODIGO_PRV_PRV';
  // Las consultas de detalle se abren al entrar en su pestaña.
  pcPestanas.OnChange := PcPestanasChange;
  pcPantalla.OnChange := ActualizarFotoProveedor;
  if not Assigned(FMiniaturaFoto) and Assigned(FotosArticulos) then
    FMiniaturaFoto := TMiniaturaFotoMto.Create(Self, pButtonRightBar,
      pButtonBDStat, FotosArticulos, ResolverArtSkuActivo,
      DataSourcesParaFoto, actFotoArticulo);
end;

procedure TfrmMtoProveedores.ActualizarFotoProveedor(Sender: TObject);
begin
  if Assigned(FMiniaturaFoto) then
    FMiniaturaFoto.Actualizar;
  RefrescarFotoArticulo;
end;

procedure TfrmMtoProveedores.PcPestanasChange(Sender: TObject);
var
  Tipo: TDocumentoCompraProveedor;
begin
  if Assigned(FDmmProveedores) then
  begin
    if pcPestanas.ActivePage = tsArticulos then
      FDmmProveedores.AsegurarArticulosAbierta
    else if pcPestanas.ActivePage = tsVentas then
      FDmmProveedores.AsegurarVentasAbierta
    else if pcPestanas.ActivePage = tsCompras then
      FDmmProveedores.AsegurarComprasAbierta
    else if pcPestanas.ActivePage = tsPagos then
      FDmmProveedores.AsegurarPagosAbierta
    else
      for Tipo := Low(Tipo) to High(Tipo) do
        if (pcPestanas.ActivePage = FPestanasDocumentos[Tipo]) and
           FPestanasDocumentos[Tipo].TabVisible then
        begin
          if not Assigned(FBotonesDocumentos[Tipo]) then
            CrearContenidoDocumentos(Tipo);
          FDmmProveedores.AbrirDocumentos(Tipo,
            FFacturasOrdinarias, FComprasDirectas);
        end;
    ActualizarFotoProveedor(Sender);
  end;
end;

// ===========================================================================
//   Pestaña Compras — kits de cantidades por talla
// ===========================================================================

procedure TfrmMtoProveedores.btnAddKitClick(Sender: TObject);
begin
  inherited;
  FDmmProveedores.unqryKits.Insert;
  cxgrdKits.SetFocus;
  tvKits.Controller.FocusedColumn := dbcKitCodigo;
  if tvKits.Controller.EditingController <> nil then
    tvKits.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoProveedores.btnDelKitClick(Sender: TObject);
begin
  inherited;
  if FDmmProveedores.unqryKits.State = dsInsert then
    FDmmProveedores.unqryKits.Cancel
  else if not FDmmProveedores.unqryKits.IsEmpty then
  begin
    if MessageDlg_fza(SPreguntaBorrarKitProveedor,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      FDmmProveedores.unqryKits.Delete;
  end;
end;

procedure TfrmMtoProveedores.btnGenerarTallasKitClick(Sender: TObject);
begin
  inherited;
  // Una fila de detalle por cada talla del sistema del kit (cantidad 0).
  FDmmProveedores.GenerarTallasKitActual;
end;

procedure TfrmMtoProveedores.btnAddKitDetClick(Sender: TObject);
begin
  inherited;
  FDmmProveedores.unqryKitsDet.Insert;
  cxgrdKitsDet.SetFocus;
  tvKitsDet.Controller.FocusedColumn := dbcKitDetValor;
  if tvKitsDet.Controller.EditingController <> nil then
    tvKitsDet.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoProveedores.btnDelKitDetClick(Sender: TObject);
begin
  inherited;
  if FDmmProveedores.unqryKitsDet.State = dsInsert then
    FDmmProveedores.unqryKitsDet.Cancel
  else if not FDmmProveedores.unqryKitsDet.IsEmpty then
    FDmmProveedores.unqryKitsDet.Delete;
end;

procedure TfrmMtoProveedores.cxdbtxtdt16PropertiesChange(Sender: TObject);
var
  ePais: TcxCustomEdit;
begin
  inherited;
  if Assigned(FDmmProveedores) and
     ((dsTablaG.State = dsInsert) or (dsTablaG.State = dsEdit)) then
  begin
    ePais := Sender as TcxCustomEdit;
    FDmmProveedores.ActualizarIvaExentoIntracomunitarioPorPais(
      VarToStr(ePais.EditingValue));
  end;
end;

// Al elegir un pais en el combo, cbbPaisPrv posiciona FDmmProveedores.
// unqryPaises en la fila elegida: aprovechamos esa fila para refrescar
// PAIS_PRV (nombre denormalizado, oculto en cxdbtxtdt16) y el IVA exento
// intracomunitario, igual que hacia el texto libre antes del combo.
procedure TfrmMtoProveedores.cbbPaisPrvPropertiesChange(Sender: TObject);
var
  eCombo: TcxCustomEdit;
begin
  inherited;
  if Assigned(FDmmProveedores) and
     ((dsTablaG.State = dsInsert) or (dsTablaG.State = dsEdit)) then
  begin
    eCombo := Sender as TcxCustomEdit;
    dsTablaG.DataSet.FieldByName('PAIS_PRV').AsString :=
      FDmmProveedores.unqryPaises.FieldByName('NOMBRE').AsString;
    FDmmProveedores.ActualizarIvaExentoIntracomunitarioPorPais(
      VarToStr(eCombo.EditingValue));
  end;
end;

procedure TfrmMtoProveedores.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoProveedores.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoProveedores.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_PROVEEDOR.Enabled := True
  else
  begin
    txtCODIGO_PROVEEDOR.Enabled := False;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoProveedores);
  ForceReferenceToClass(TfrmMtoProveedores);
end.

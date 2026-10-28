{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasBase                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de facturas de venta.                                       }
{    Cabecera, lineas, impuestos y totales sobre fza_facturas.                 }
{******************************************************************************}
unit inMtoFacturasBase;

interface

uses
  inLibPivoteVentaCalculo,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoDocumento, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,  System.StrUtils,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, System.UITypes,
  System.Generics.Collections,
  inMtoFacturasIncidenciaFiscalVcl,
  inMtoFacturasSubsanacionVcl,
  inMtoModalMensajeTexto,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxSplitter, cxImage, cxDBEdit, cxPC, cxLabel, cxScrollBox,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxMemo, cxDBLookupComboBox,
  cxGridBandedTableView, cxGridDBBandedTableView, cxLocalization,
  cxGroupBox, DBCtrls, cxCurrencyEdit, Menus, cxButtons, cxButtonEdit,
  inlibDevExp, cxLookupEdit, cxDBLookupEdit, Uni, cxSpinEdit, cxCalc,
  cxDataControllerConditionalFormattingRulesManagerDialog, dxBevel,
  cxDBNavigator, dxNumericWheelPicker, dxDateRanges, cxDataUtils, cxVariants,
  cxDBLabel, dxGDIPlusClasses, dxSkinsForm, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, System.Actions, Vcl.ActnList,
  Vcl.ActnMan, Vcl.StdStyleActnCtrls, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, UniDataFacturas, dxShellDialogs, JvBaseDlg,
  dxDateTimeWheelPicker, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridPivoteVenta, inLibLectorDocumento,
  inLibArticulosValidadorIntf,
  inLibFacturasServiciosIntf,
  inLibFacturasAplicacionIntf,
  inLibComandoImprimirFacturas,
  inLibDocumento, inLibDocumentoIntf,
  inLibFacturasColumnasPresentacion,
  inLibFacturasLineasEdicion,
  inLibFacturasInyeccion,
  inLibPermisosIntf,
  inMtoFacturasPresentadorCabeceraVcl,
  inMtoFacturasPresentadorLineasVcl;

const
  WM_REVISAR_ENTER_AS_TAB_FACTURA = WM_APP + 256;

type
  TDependenciasPresentacionFacturas = record
    Vista: IVistaFactura;
    Consolidacion: IAplicacionConsolidacionFactura;
    OperacionFiscal: IAplicacionOperacionFiscalFactura;
    Cobros: IAplicacionCobrosFactura;
    Estado: IPresentadorEstadoFactura;
    ModoEntrada: IGestorModoEntradaFactura;
  end;

  TfrmMtoFacturasBase = class(TfrmMtoDocumento)
    lblVentaDtoComercial: TcxLabel;
    spnVentaPORCENTAJE_DTO_COMERCIAL_FAC: TcxDBSpinEdit;
    curVentaTOTAL_DTO_COMERCIAL_FAC: TcxDBCurrencyEdit;
    lblVentaDtoFinanciero: TcxLabel;
    spnVentaPORCENTAJE_DTO_FINANCIERO_FAC: TcxDBSpinEdit;
    curVentaTOTAL_DTO_FINANCIERO_FAC: TcxDBCurrencyEdit;
    pnlResumenBorrador: TcxGroupBox;
    lblResumenBases: TcxLabel;
    lblResumenImpuestos: TcxLabel;
    lblResumenLiquido: TcxLabel;
    curResumenBases: TcxDBCurrencyEdit;
    curResumenImpuestos: TcxDBCurrencyEdit;
    curResumenLiquido: TcxDBCurrencyEdit;
    pnlVerifactu: TPanel;
    cxgrdbclmnGrdDBTabPrinESTADO_VERIFACTU: TcxGridDBColumn;
    pcDetail: TcxPageControl;
    tsLineasFactura: TcxTabSheet;
    tsTotales: TcxTabSheet;
    scrTotales: TcxScrollBox;
    lblTotalaPagar: TcxLabel;
    cxgrdLineasFactura: TcxGrid;
    tvLineasFactura: TcxGridDBTableView;
    cxgrdlvlLineasFactura: TcxGridLevel;
    curTotalAPagar: TcxDBCurrencyEdit;
    tsOtros: TcxTabSheet;
    lblComentarios: TcxLabel;
    cxgrdbclmnGrdDBTabPrinNRO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSERIE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinFECHA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinFORMA_PAGO_FACTURA: TcxGridDBColumn;
    mmodbComentarios: TcxDBMemo;
    lblTipoOperVerifactu: TcxLabel;
    cbbTipoOperVerifactu: TcxDBLookupComboBox;
    lblTipoOperVerifactuAyuda: TcxLabel;
    scrOtros: TcxScrollBox;
    tsRecibos: TcxTabSheet;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    lblNroFactura: TcxLabel;
    lblFechaFactura: TcxLabel;
    dteFECHA_FACTURA: TcxDBDateEdit;
    lblSerieFactura: TcxLabel;
    btnCODIGO_CLIENTE: TcxDBButtonEdit;
    lblCodigoCliente: TcxLabel;
    lbldbRAZONSOCIAL_EMPRESA_FACTURA: TcxDBLabel;
    tsEmpresa: TcxTabSheet;
    grpEmpresa: TcxGroupBox;
    txtDIRECCION1_EMPRESA_FACTURA: TcxDBTextEdit;
    txtCPOSTAL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_FACTURA: TcxDBTextEdit;
    txtPAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_FACTURA: TcxDBTextEdit;
    lblProvinciaEmpresa: TcxLabel;
    lblPaisEmpresa: TcxLabel;
    txtRAZONSOCIAL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtNIF_EMPRESA_FACTURA: TcxDBTextEdit;
    lblNIFEmpresa: TcxLabel;
    lblMovilEmpresa: TcxLabel;
    txtMOVIL_EMPRESA_FACTURA: TcxDBTextEdit;
    txtEMAIL_EMPRESA_FACTURA: TcxDBTextEdit;
    lblEmailEmpresa: TcxLabel;
    tsDatosCliente: TcxTabSheet;
    grpCliente: TcxGroupBox;
    txtDIRECCION1_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtCPOSTAL_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtPAIS_CLIENTE_FACTURA1: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_FACTURA1: TcxDBTextEdit;
    lblExtra6: TcxLabel;
    lblExtra13: TcxLabel;
    txtRAZONSOCIAL_CLIENTE_FACTURA: TcxDBTextEdit;
    txtNIF_CLIENTE_FACTURA: TcxDBTextEdit;
    lblNif: TcxLabel;
    lblTelefonoMovil: TcxLabel;
    txtMOVIL_CLIENTE_FACTURA: TcxDBTextEdit;
    txtEMAIL_CLIENTE_FACTURA: TcxDBTextEdit;
    lblEmail: TcxLabel;
    btnUpdateCliente: TcxButton;
    curTOTAL_LIQUIDO_FACTURA: TcxDBCurrencyEdit;
    lblTotalRetencionFactura: TcxLabel;
    lblPorcRetencionFactura: TcxLabel;
    lbldbRAZONSOCIAL_CLIENTE_FACTURA: TcxDBLabel;
    btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit;
    lblCodigoEmpresa: TcxLabel;
    lblAlmacenFactura: TcxLabel;
    cbbAlmacenFactura: TcxDBLookupComboBox;
    btnUpdateEmpresa: TcxButton;
    cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_ZONA_IVA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_REN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_REN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RER_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RER_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RES_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RES_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_IVAE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_REE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_REE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNRO_FACTURA_ABONO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSERIE_FACTURA_ABONO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDOCUMENTO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCOMENTARIOS_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox;
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox;
    chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox;
    chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox;
    chkEXTRANJERO: TcxDBCheckBox;
    ctbCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    ctbTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    txtNRO_FACTURA: TcxDBTextEdit;
    cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox;
    lblTarifaArticulosCliente: TcxLabel;
    ctbLINEA_FACTURA_LINEA: TcxGridDBColumn;
    spnRetencion: TcxDBSpinEdit;
    curTOTAL_RETENCION_FACTURA: TcxDBCurrencyEdit;
    lblTotalBaseImponible: TcxLabel;
    curTOTAL_BASES_FACTURA: TcxDBCurrencyEdit;
    lbl1TotalImpuestos: TcxLabel;
    chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox;
    ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox;
    ctbIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    cxGrdDBTabPrinGRUPO_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_IVA_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_BASES_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinCONTADOR_LINEAS_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn;
    cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn;
    splSplitterFicha: TcxSplitter;
    mPOBLACION_EMPRESA_FACTURA: TcxDBMemo;
    pnlRightRecibos: TPanel;
    pnlBodyRecibos: TPanel;
    cxgrdRecibos: TcxGrid;
    tvRecibos: TcxGridDBTableView;
    cxgrdlvlRecibos: TcxGridLevel;
    cxgrdbclmnRecibosNRO_FACTURA_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosSERIE_FACTURA_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosNRO_PLAZO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosEUROS_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosESTADO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosFECHA_PAGO_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO: TcxGridDBColumn;
    cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO: TcxGridDBColumn;
    btnReciboDevuelto: TcxButton;
    btnImprimirRecibo: TcxButton;
    btnReciboEmitido: TcxButton;
    btnReciboPagado: TcxButton;
    pnlRightLineas: TPanel;
    pnlBotonesAcciones: TPanel;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    splLineasDerecha: TcxSplitter;
    chkFechaEntrega: TcxDBCheckBox;
    chkDescripcion_ampliada: TcxDBCheckBox;
    cbbSerieFactura: TcxDBLookupComboBox;
    cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA:
                                                                TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESDESCRIPCIONES_AMP_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESFECHADEENTREGA_FACTURA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA:
                                                                TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn;
    lblFormadePago: TcxLabel;
    cbbFORMAPAGO: TcxDBLookupComboBox;
    btnGenerarRecibos: TcxButton;
    cbbCanalIVA: TcxDBLookupComboBox;
    lblCanalIVA: TcxLabel;
    ctbCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    ctbCODIGO_UNIDAD_FACTURA_LINEA: TcxGridDBColumn;
    ctbNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    ctbFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    btnExportarLineas: TcxButton;
    btnExportarRecibos: TcxButton;
    btnIraArticulo: TcxButton;
    btnIrAEmpresa: TcxButton;
    btnIrACliente: TcxButton;
    btnNuevaFactura: TcxButton;
    btnRectificar: TcxButton;
    btnImprimir: TcxButton;
    ActionListFacturas: TActionList;
    actArticulo: TAction;
    actEmpresa: TAction;
    actCliente: TAction;
    actMovimiento: TAction;
    lbldbCODIGO_CLIENTE_FACTURA: TcxDBLabel;
    lbldbCODIGO_CLIENTE: TcxDBLabel;
    chkImpIncl: TcxDBCheckBox;
    ctbPRECIOSALIDA_FACTURA_LINEA: TcxGridDBColumn;
    ctbPORCEN_DTO_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_DTO_FACTURA_LINEA: TcxGridDBColumn;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasFactura: TcxLabel;
    grpDesgloseImpuestos: TcxGroupBox;
    lblTotRE: TcxLabel;
    PorRE: TcxLabel;
    lblTotIVA: TcxLabel;
    lblPorIVA: TcxLabel;
    lblBaseNeta: TcxLabel;
    lblNormal: TcxLabel;
    lblReducido: TcxLabel;
    lblSReducido: TcxLabel;
    lblExento: TcxLabel;
    curTOTAL_BASEI_IVAN_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAR_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAS_FAC: TcxDBCurrencyEdit;
    curTOTAL_BASEI_IVAE_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAN_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAR_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAS_FAC: TcxDBCurrencyEdit;
    curTOTAL_IVAE_FAC: TcxDBCurrencyEdit;
    curTOTAL_REN_FAC: TcxDBCurrencyEdit;
    curTOTAL_RER_FAC: TcxDBCurrencyEdit;
    curTOTAL_RES_FAC: TcxDBCurrencyEdit;
    curTOTAL_REE_FAC: TcxDBCurrencyEdit;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;
    spnPORCENTAJE_IVAN_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAR_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAS_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_IVAE_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_RER_FAC: TcxDBSpinEdit;
    shpSeparador6: TShape;
    spnPORCENTAJE_REN_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_RES_FAC: TcxDBSpinEdit;
    spnPORCENTAJE_REE_FAC: TcxDBSpinEdit;
    ctbTOTAL_FACTURASIVA_LINEA: TcxGridDBColumn;
    ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA: TcxGridDBColumn;
    ctbCODIGO_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn;
    ctbPRECIO_ULT_COMPRA_FACTURA_LINEA: TcxGridDBColumn;
    btnCalculator: TcxButton;
    txtNOMBRE_PAIS_CLIENTE_FACTURA: TcxDBTextEdit;
    txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit;
    cbbPaisesCli: TcxDBLookupComboBox;
    cbbPaisesEmp: TcxDBLookupComboBox;
    chkConsolidada: TcxDBCheckBox;
    chkMueveStock: TcxDBCheckBox;
    pnlUserInstantBottom: TcxGroupBox;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    txtINSTANTEMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtINSTANTECONSOLIDACION: TcxDBTextEdit;
    btnConsolidar: TcxButton;
    dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    dbcGrdDBTabPrinESCONSOLIDADA_FACTURA: TcxGridDBColumn;
    dbcGrdDBTabPrinINSTANTECONSO_FACTURA: TcxGridDBColumn;
    tsVerifactu: TcxTabSheet;
    tsRegistro: TcxTabSheet;
    tsMovimientosFac: TcxTabSheet;
    cxGrdMovimientosFac: TcxGrid;
    tvMovimientosFac: TcxGridDBTableView;
    cxGrdMovimientosFacLevel: TcxGridLevel;
    scrlbxVerifactu: TcxScrollBox;
    lblPETICION_COMPLETA: TcxLabel;
    lblRESPUESTA_COMPLETA: TcxLabel;
    lblQRCODE_BASE64: TcxLabel;
    lblVERIFACTU_URL: TcxLabel;
    lblCHAIN_HASH: TcxLabel;
    lblCHAIN_NUMBER: TcxLabel;
    lblISSUED_TIME: TcxLabel;
    lblISSUER_IRS_ID: TcxLabel;
    lblQUEUE_ID: TcxLabel;
    lblREQUEST_ID: TcxLabel;
    lbl: TcxLabel;
    lblFECHA_PROCESAMIENTO: TcxLabel;
    lblESTADO: TcxLabel;
    spQUEUE_ID: TcxDBSpinEdit;
    cxdbmRESPUESTA_COMPLETA: TcxDBMemo;
    cxdbmQRCODE_BASE64: TcxDBMemo;
    cxdbmVERIFACTU_URL: TcxDBMemo;
    txtCHAIN_HASH: TcxDBTextEdit;
    txtCHAIN_NUMBER: TcxDBTextEdit;
    dteISSUED_TIME: TcxDBDateEdit;
    txtISSUER_IRS_ID: TcxDBTextEdit;
    imgQRCODE_PNG: TcxDBImage;
    txtREQUEST_ID: TcxDBTextEdit;
    spID_CONSOLIDACION: TcxDBSpinEdit;
    cxdbmPETICION_COMPLETA_FACCON: TcxDBMemo;
    dteFECHA_PROCESAMIENTO: TcxDBDateEdit;
    txtESTADO: TcxDBTextEdit;
    cxgrdLogVerifactu: TcxGrid;
    tvLogVerifactu: TcxGridDBTableView;
    cxgrdlvlLogVerifactu: TcxGridLevel;
    tvLogVerifactuTIMESTAMP_LOG: TcxGridDBColumn;
    tvLogVerifactuDESCRIPCION_LOG: TcxGridDBColumn;
    tvLogVerifactuDATOS_ADICIONALES_LOG: TcxGridDBColumn;
    tvLogVerifactuNRO_FACTURA_LOG: TcxGridDBColumn;
    tvLogVerifactuSERIE_FACTURA_LOG: TcxGridDBColumn;
    lblTipoFactura: TcxLabel;
    txtTIPO_FAC: TcxDBTextEdit;
    lblVendedorFactura: TcxLabel;
    txtCODIGO_CAJERO_FAC: TcxDBTextEdit;
    txtFASE_FAC: TcxDBTextEdit;
    lblFaseFactura: TcxLabel;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox;
    chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox;
    btnGenerarRecibos2: TcxButton;
    btnVerifactuAnular: TcxButton;
    btnIrAVerifactu: TcxButton;
    btnVerifactuFacturar: TcxButton;
    btnVolverBorrador: TcxButton;
    btnVerifactuResolverIncidencia: TcxButton;
    btnVerifactuSubsanar: TcxButton;
    btnVerifactuCancelarSubsanacion: TcxButton;
    cxGrdDBTabPrinFASE_FAC: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_FAC: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_RECTIFICADA_FAC: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_RECTIFICADA_FAC: TcxGridDBColumn;
    procedure sbGrabarClick(Sender: TObject);
    procedure btnUpdateClienteClick(Sender: TObject);
    procedure sbNuevaFacturaClick(Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesEditValueChanged(Sender: TObject);
    procedure tvLineasFacturaKeyDown(Sender: TObject;
                                     var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLIENTEKeyUp( Sender: TObject;
                                      var Key: Word;
                                      Shift: TShiftState);
    procedure cbbSerieFacturaKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbbSerieFacturaPropertiesChange(Sender: TObject);
    procedure dteFECHA_FACTURAKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnCODIGO_CLIENTEPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnGenerarRecibosClick(Sender: TObject);
    procedure btnReciboPagadoClick(Sender: TObject);
    procedure btnReciboEmitidoClick(Sender: TObject);
    procedure btnReciboDevueltoClick(Sender: TObject);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnUpdateEmpresaClick(Sender: TObject);
    procedure cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup(
      Sender: TObject);
    procedure ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure sbRectificarClick(Sender: TObject);
    procedure sbImprimirClick(Sender: TObject);
    procedure btnImprimirReciboClick(Sender: TObject);
    procedure chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange(
      Sender: TObject);
    procedure btnCODIGO_EMPRESA_FACTURAPropertiesChange(Sender: TObject);
    procedure dteFECHA_FACTURAPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_CLIENTEPropertiesChange(Sender: TObject);
    procedure cbbCanalIVAPropertiesChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnConsolidarClick(Sender: TObject);
    procedure btnVolverBorradorClick(Sender: TObject);
    procedure chkFechaEntregaPropertiesChange(Sender: TObject);
    procedure chkDescripcion_ampliadaPropertiesChange(Sender: TObject);
    procedure btnExportarLineasClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnVerifactuAnularClick(Sender: TObject);
    procedure btnIrAVerifactuClick(Sender: TObject);
    procedure btnVerifactuResolverIncidenciaClick(Sender: TObject);
    procedure btnVerifactuSubsanarClick(Sender: TObject);
    procedure btnVerifactuCancelarSubsanacionClick(Sender: TObject);
    procedure btnVerifactuFacturarClick(Sender: TObject);
    procedure btnExportarRecibosClick(Sender: TObject);
    procedure actArticuloExecute(Sender: TObject);
    procedure actMovimientoExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actClienteExecute(Sender: TObject);
    procedure actEmpresaExecute(Sender: TObject);
    procedure btnIrAClienteClick(Sender: TObject);
    procedure btnIrAEmpresaClick(Sender: TObject);
    procedure cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
      Sender: TObject);
    procedure
      tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnCalculatorClick(Sender: TObject);
    procedure cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(Sender: TObject);
    procedure ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
      Sender: TObject);
    procedure DescuentosDocumentoCambiados(Sender: TObject);
  public
    destructor Destroy; override;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    function  ContarHijosActivos: Integer; override;
    // Nombre de la vista SQL a consultar en el listado principal.
    // La filtra el propio motor de BD (vi_facturas_normales /
    // vi_facturas_simplificadas), no toca al codigo.
    function NombreVistaListado: string; virtual;
    // TIPO_FAC que el descendiente quiere por defecto en los inserts
    function TipoFacturaFiltro: string; virtual;
    // Si el descendiente precarga la lista con filtros propios (p.ej.
    // simplificadas por año/almacen), devuelve False para que
    // CrearTablaPrincipal NO abra la vista completa; el descendiente la
    // abre ya filtrada y con barra de progreso en ResetForm.
    function AbrirListadoAlCrear: Boolean; virtual;
  private
    FColsModoConstruido: Boolean;
    FConstruyendoModo: Boolean;
    FDependencias: TDependenciasPresentacionFacturas;
    FDependenciasInyeccion: TDependenciasFacturas;
    FEditorLineas: TEditorLineasFactura;
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FPresentadorCabecera: TPresentadorCabeceraFacturaVcl;
    FPresentadorLineas: TPresentadorLineasFacturaVcl;
    FLectorDocumento: TLectorDocumento;
    FVerificacionNif: TComponent;
    FBotonAvisosReferencias: TcxButton;
    FVentanaReferencias: TfrmModalMensajeTexto;
    FDetalleReferencias: string;
    FEstiloReferenciaAusente: TcxStyle;
    FArticulosAusentes, FSkusAusentes: TArray<string>;
    FColorCliente, FColorFormaPago, FColorAlmacen: TColor;
    FTextoCliente, FTextoFormaPago, FTextoAlmacen: TColor;
    FAsignadosCliente, FAsignadosFormaPago,
      FAsignadosAlmacen: TcxContainerStyleValues;
    procedure PrepararAvisosReferencias;
    procedure PrepararVentanaReferencias;
    procedure ActualizarVentanaReferencias;
    procedure MostrarAvisosReferencias(Sender: TObject);
    procedure CerrarAvisosReferencias(Sender: TObject);
    procedure ActualizarReferenciasAusentes;
    procedure EstiloReferenciaAusente(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure InstalarVerificacionNif;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal con las
    // lineas de la factura a la vista. El Construir hace ClearItems:
    // las columnas del dfm mueren y las propias se recrean en runtime
    // reasignando las referencias ctb* para que la logica existente
    // (visibilidad, ImpIncl, recalculo) siga funcionando. El modo tallas
    // es inLibGridPivoteVenta con BandaUnica: pivot SOLO visual, las
    // lineas fiscales no se tocan.
    procedure ConfigurarLectorDocumento;
    procedure ConfigurarTrazabilidadVenta;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostFactura;
    procedure cxgrdLineasFacturaEnter(Sender: TObject);
    procedure cxgrdLineasFacturaExit(Sender: TObject);
    // Salida del editor de articulo/atributo/SKU: restaura el EnterAsTab
    // y, si el foco sigue en la rejilla, lo vuelve a apagar (diferido).
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabFactura(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_FACTURA;
    procedure ActualizarDesgloseRecargo;
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    // Graba el borrador pendiente antes de sacar la copia impresa.
    procedure GuardarPendienteAntesDeImprimir;
    procedure GuardarCambiosFactura;
    function ObtenerReferenciasFiltradas:
      TReferenciasComandoFactura;
    // Carga perezosa de sub-pestañas detail. Cada pestaña abre su query
    // solo cuando el usuario la activa.
    procedure PcDetailChange(Sender: TObject);
    // Subsanación del registro fiscal (fase SUBSANACION).
    procedure ActualizarBotonesSubsanacion;
    function CrearContextoSubsanacion: TContextoSubsanacionFacturaVcl;
    // Identidad (fecha, emisor) y resto de la cabecera bloqueados
    // mientras se subsana: sólo datos del cliente, cantidades y precios.
    procedure AplicarBloqueoSubsanacion(ASubsanando: Boolean);
  protected
    procedure DoHide; override;
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmFacturas : TdmFacturas;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasFacturas); reintroduce; overload;
  end;

//var
//  //frmMtoFacturasBase: TfrmMtoFacturasBase;
//  dmmFacturas : TdmFacturas;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMensajesVcl,
  inLibComboPais,
  inLibCalculadoraVcl,
  inLibWin,
  inLibMsgComun, inLibMsgFacturas,
  inLibMsgVentas,
  inLibImpuestosComun,
  inLibGenBusq,
  inLibShowMto,
  inLibFacturas,
  inLibFacturasCobrosPresentacion,
  inLibFacturasEstadoFiscalPresentacion,
  inLibFacturasOperacionFiscal,
  inLibFacturasConsolidacionPresentacion,
  inLibFacturasPresentadorDetalle,
  inLibGridCantidad,
  inLibArticulosResolverIntf,
  inMtoGenSearch,
  inLibVerifactu,
  inLibFacturasAplicacion,
  inMtoFacturasVistaVcl,
  inMtoFacturasConsolidacionVcl,
  inMtoFacturasCobrosVcl,
  inMtoFacturasAccionesVcl,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku, inLibColumnasDocumento, inLibReagpVcl,
  UniDataArticulosValidadorRepositorio, UniDataFacturasConfiguracion,
  UniDataGen, UniDataNumeracionDocumentos,
  inLibVerificacionNifAeat, inLibVerificacionNifRoi, inMtoVerificacionNifVcl,
  inLibGestorGuardianBorradoMto,
  inLibPresentacionDocumento, inMtoModalAyudaWeb,
  inLibTrazabilidad, inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibTrazabilidadDocumento, inLibTrazabilidadDocumentoUniDAC;

resourcestring
  STituloBuscarClientesBorradoresFactura =
    'Búsqueda de Clientes en Borradores';
  STituloBuscarEmpresasBorradoresFactura =
    'Búsqueda de Empresas en Borradores';

function CrearContextoConsolidacionFacturaVcl(
  AFormulario: TfrmMtoFacturasBase
): TContextoConsolidacionFacturaVcl;
begin
  Result := Default(TContextoConsolidacionFacturaVcl);
  Result.Facturas := AFormulario.dsTablaG.DataSet;
  Result.Aplicacion := AFormulario.FDependencias.Consolidacion;
  Result.Vista := AFormulario.FDependencias.Vista;
  Result.Usuario := AFormulario.IdentidadSesion.Usuario;
end;

// FZ-ISSUE-102.14: NUMERO_EFV de los efectos seleccionados en la rejilla
// de cobros, separados por comas ('' si no hay selección).
function EfectosSeleccionadosVcl(AFormulario: TfrmMtoFacturasBase): string;
var
  iRegistro: Integer;
  vValor: Variant;
  Controlador: TcxGridTableController;
begin
  Result := '';
  Controlador := AFormulario.tvRecibos.Controller;
  for iRegistro := 0 to Controlador.SelectedRecordCount - 1 do
  begin
    vValor := Controlador.SelectedRecords[iRegistro].Values[
      AFormulario.cxgrdbclmnRecibosNRO_PLAZO_RECIBO.Index];
    if not VarIsNull(vValor) then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + VarToStr(vValor);
    end;
  end;
end;

function CrearContextoCobrosFacturaVcl(
  AFormulario: TfrmMtoFacturasBase): TContextoCobrosFacturaVcl;
begin
  Result := Default(TContextoCobrosFacturaVcl);
  Result.Aplicacion := AFormulario.FDependencias.Cobros;
  Result.Cabecera := AFormulario.dsTablaG.DataSet;
  Result.Efectos := AFormulario.dmmFacturas.unqryEfectosVenta;
  Result.Recibos := AFormulario.dmmFacturas.unqryRecibos;
  Result.DataModule := AFormulario.dmmFacturas;
  Result.Conexion := AFormulario.ConexionPrincipal;
  Result.PropietarioVisual := AFormulario;
  Result.Usuario := AFormulario.IdentidadSesion.Usuario;
  Result.SeleccionBanco :=
    AFormulario.FDependenciasInyeccion.SeleccionBanco;
  Result.EsVentaMayor := SameText(
    AFormulario.TipoFacturaFiltro,
    'NORMAL');
  if Result.EsVentaMayor then
    Result.EfectosSeleccionados := EfectosSeleccionadosVcl(AFormulario);
  Result.AsegurarEfectos :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarEfectosVentaAbierta;
    end;
  Result.AsegurarRecibos :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarRecibosAbierta;
    end;
  Result.GenerarRecibos :=
    procedure
    begin
      AFormulario.dmmFacturas.unstrdprcGetRecibos.ParamByName(
        'pNRO_FACTURA').AsString :=
          AFormulario.dsTablaG.DataSet.FieldByName(fnrofac).AsString;
      AFormulario.dmmFacturas.unstrdprcGetRecibos.ParamByName(
        'pSERIE_FACTURA').AsString :=
          AFormulario.dsTablaG.DataSet.FieldByName(fseriefac).AsString;
      AFormulario.dmmFacturas.unstrdprcGetRecibos.ParamByName(
        'pUSUARIO').AsString := AFormulario.IdentidadSesion.Usuario;
      AFormulario.dmmFacturas.unstrdprcGetRecibos.ExecProc;
      AFormulario.dmmFacturas.unqryRecibos.Close;
      AFormulario.dmmFacturas.unqryRecibos.Open;
    end;
  Result.RefrescarEfectos :=
    procedure
    begin
      AFormulario.dmmFacturas.unqryEfectosVenta.Close;
      AFormulario.dmmFacturas.unqryEfectosVenta.Open;
    end;
  Result.MarcarReciboPagado :=
    procedure
    begin
      AFormulario.FPresentadorCabecera.CambiarEstadoRecibo('Pagado');
    end;
  Result.MarcarReciboPendiente :=
    procedure
    begin
      AFormulario.FPresentadorCabecera.CambiarEstadoRecibo('Emitido');
    end;
  Result.MarcarReciboDevuelto :=
    procedure
    begin
      AFormulario.FPresentadorCabecera.CambiarEstadoRecibo('Devuelto');
    end;
end;

procedure AplicarOrigenCobrosFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
var
  Configuracion: TConfiguracionCobrosFactura;
  Controles: TControlesCobrosFactura;
begin
  Configuracion := CrearConfiguracionCobrosFactura(
    AFormulario.TipoFacturaFiltro);
  Controles := Default(TControlesCobrosFactura);
  Controles.AplicarOrigenDatos := Assigned(AFormulario.dmmFacturas);
  Controles.Vista := AFormulario.tvRecibos;
  if Assigned(AFormulario.dmmFacturas) then
  begin
    Controles.DataSourceRecibos := AFormulario.dmmFacturas.dsRecibos;
    Controles.DataSourceEfectos := AFormulario.dmmFacturas.dsEfectosVenta;
  end;
  Controles.Pestana := AFormulario.tsRecibos;
  Controles.BotonGenerar := AFormulario.btnGenerarRecibos;
  Controles.BotonGenerarSecundario := AFormulario.btnGenerarRecibos2;
  Controles.BotonImprimir := AFormulario.btnImprimirRecibo;
  Controles.BotonPendiente := AFormulario.btnReciboEmitido;
  Controles.BotonCobrado := AFormulario.btnReciboPagado;
  Controles.BotonDevuelto := AFormulario.btnReciboDevuelto;
  Controles.Columnas[ccfNumeroFactura] :=
    AFormulario.cxgrdbclmnRecibosNRO_FACTURA_RECIBO;
  Controles.Columnas[ccfSerieFactura] :=
    AFormulario.cxgrdbclmnRecibosSERIE_FACTURA_RECIBO;
  Controles.Columnas[ccfNumeroPlazo] :=
    AFormulario.cxgrdbclmnRecibosNRO_PLAZO_RECIBO;
  Controles.Columnas[ccfFormaPago] :=
    AFormulario.cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO;
  Controles.Columnas[ccfDescripcionFormaPago] :=
    AFormulario.cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO;
  Controles.Columnas[ccfImporte] :=
    AFormulario.cxgrdbclmnRecibosEUROS_RECIBO;
  Controles.Columnas[ccfEstado] :=
    AFormulario.cxgrdbclmnRecibosESTADO_RECIBO;
  Controles.Columnas[ccfFechaExpedicion] :=
    AFormulario.cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO;
  Controles.Columnas[ccfFechaVencimiento] :=
    AFormulario.cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO;
  Controles.Columnas[ccfIban] :=
    AFormulario.cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO;
  Controles.Columnas[ccfFechaPago] :=
    AFormulario.cxgrdbclmnRecibosFECHA_PAGO_RECIBO;
  Controles.Columnas[ccfLocalidad] :=
    AFormulario.cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO;
  Controles.Columnas[ccfCodigoCliente] :=
    AFormulario.cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO;
  Controles.Columnas[ccfRazonSocialCliente] :=
    AFormulario.cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO;
  Controles.Columnas[ccfDireccionCliente] :=
    AFormulario.cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO;
  Controles.Columnas[ccfPoblacionCliente] :=
    AFormulario.cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO;
  Controles.Columnas[ccfProvinciaCliente] :=
    AFormulario.cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO;
  Controles.Columnas[ccfCodigoPostalCliente] :=
    AFormulario.cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO;
  Controles.Columnas[ccfImporteLetra] :=
    AFormulario.cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO;
  TPresentacionCobrosFactura.Aplicar(Configuracion, Controles);
end;

function CrearContextoDetalleFacturaVcl(
  AFormulario: TfrmMtoFacturasBase
): TContextoDetalleFacturaVcl;
begin
  Result := Default(TContextoDetalleFacturaVcl);
  Result.EsVentaMayor := SameText(
    AFormulario.TipoFacturaFiltro,
    'NORMAL');
  if AFormulario.pcDetail.ActivePage = AFormulario.tsRecibos then
    Result.Detalle := dfvCobros
  else if AFormulario.pcDetail.ActivePage = AFormulario.tsVerifactu then
    Result.Detalle := dfvConsolidacion
  else if AFormulario.pcDetail.ActivePage = AFormulario.tsRegistro then
    Result.Detalle := dfvRegistro
  else if AFormulario.pcDetail.ActivePage =
          AFormulario.tsMovimientosFac then
    Result.Detalle := dfvMovimientos;
  Result.AsegurarEfectos :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarEfectosVentaAbierta;
    end;
  Result.AsegurarRecibos :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarRecibosAbierta;
    end;
  Result.AsegurarConsolidacion :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarConsolidacionAbierta;
    end;
  Result.AsegurarRegistro :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarErroresAbierta;
    end;
  Result.AsegurarMovimientos :=
    procedure
    begin
      AFormulario.dmmFacturas.AsegurarMovimientosFacAbierta;
    end;
end;

function CrearContextoOperacionFiscalFacturaVcl(
  AFormulario: TfrmMtoFacturasBase;
  const ATipoOperacion, AAccion: string
): TContextoOperacionFiscalFactura;
begin
  Result := Default(TContextoOperacionFiscalFactura);
  Result.Serie := AFormulario.dsTablaG.DataSet.FieldByName(
    'SERIE_FAC').AsString;
  Result.Numero := AFormulario.dsTablaG.DataSet.FieldByName(
    'NUMERO_FAC').AsString;
  Result.FormatoDocumento := CrearFormatoDocumentoLecturas(
    AFormulario.ConexionPrincipal).LeerFormatoFactura(
      Result.Serie, Result.Numero);
  Result.TipoFactura := AFormulario.dsTablaG.DataSet.FieldByName(
    ftipofac).AsString;
  Result.Fase := AFormulario.dsTablaG.DataSet.FieldByName(
    ffasefac).AsString;
  Result.TipoOperacion := ATipoOperacion;
  Result.Accion := AAccion;
  Result.Usuario := AFormulario.IdentidadSesion.Usuario;
  Result.Consolidada := AFormulario.dsTablaG.DataSet.FieldByName(
    'ESCONSOLIDADA_FAC').AsString = 'S';
end;

function ColumnasDetalleFacturaActuales(
  AFormulario: TfrmMtoFacturasBase): TColumnasDetalleFacturaVcl;
begin
  Result := Default(TColumnasDetalleFacturaVcl);
  Result.Articulo := AFormulario.ctbCODIGO_ARTICULO_FACTURA_LINEA;
  Result.Sku := AFormulario.ctbCODIGO_UNIDAD_FACTURA_LINEA;
  Result.CodigoFamilia := AFormulario.ctbCODIGO_FAMILIA_FACTURA_LINEA;
  Result.NombreFamilia := AFormulario.ctbNOMBRE_FAMILIA_FACTURA_LINEA;
  Result.EsProveedorPrincipal :=
    AFormulario.ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA;
  Result.CodigoProveedor :=
    AFormulario.ctbCODIGO_PROVEEDOR_FACTURA_LINEA;
  Result.RazonSocialProveedor :=
    AFormulario.ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA;
  Result.PrecioUltimaCompra :=
    AFormulario.ctbPRECIO_ULT_COMPRA_FACTURA_LINEA;
  Result.PrecioSinIva :=
    AFormulario.ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA;
  Result.PrecioConIva :=
    AFormulario.ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA;
  Result.TotalSinIva := AFormulario.ctbTOTAL_FACTURASIVA_LINEA;
  Result.TotalConIva := AFormulario.ctbTOTAL_FACTURA_LINEA;
end;

function CrearContextoLineasFacturaVcl(
  AFormulario: TfrmMtoFacturasBase): TContextoLineasFacturaVcl;
begin
  Result := Default(TContextoLineasFacturaVcl);
  Result.Vista := AFormulario.tvLineasFactura;
  Result.Cabecera := AFormulario.dsTablaG;
  Result.DataModule := AFormulario.dmmFacturas;
  Result.Conexion := AFormulario.ConexionPrincipal;
  Result.Lecturas := AFormulario.FDependenciasInyeccion.Lineas.Lecturas;
  Result.RegistroLog := AFormulario.RegistroLog;
  Result.ParametrosApp := AFormulario.ParametrosApp;
  Result.BusquedaVisual := AFormulario.BusquedaVisual;
  Result.CrearResolver :=
    function: IArticulosResolver
    begin
      Result := AFormulario.FDependenciasInyeccion.Lineas.Articulos.Resolver;
    end;
  Result.EtiquetaPrendas := AFormulario.lblTotalPrendasFactura;
  Result.PestanaLineas := AFormulario.tsLineasFactura;
  // El formulario sigue siendo dueño del modo de entrada; el detalle
  // solo consulta su estado.
  Result.ContratoActivo :=
    function: Boolean
    begin
      Result := AFormulario.FModoEntrada <> nil;
    end;
  Result.Construyendo :=
    function: Boolean
    begin
      Result := AFormulario.FConstruyendoModo;
    end;
  Result.DesactivarEnterAsTab := AFormulario.DesactivarEnterAsTabTemporal;
  Result.RestaurarEnterAsTab := AFormulario.SalirEdicionModoEntrada;
end;

function CrearContextoCabeceraFacturaVcl(
  AFormulario: TfrmMtoFacturasBase): TContextoCabeceraFacturaVcl;
begin
  Result := Default(TContextoCabeceraFacturaVcl);
  Result.Cabecera := AFormulario.dsTablaG;
  Result.DataModule := AFormulario.dmmFacturas;
  Result.ParametrosApp := AFormulario.ParametrosApp;
  Result.Estado := AFormulario.FDependencias.Estado;
  Result.Lecturas := AFormulario.FDependenciasInyeccion.Lineas.Lecturas;
  Result.Numero := AFormulario.txtNRO_FACTURA;
  Result.Serie := AFormulario.cbbSerieFactura;
  Result.Tarifa := AFormulario.cbbTARIFA_ARTICULOS_CLIENTES;
  Result.CanalIva := AFormulario.cbbCanalIVA;
  Result.TipoOperacion := AFormulario.cbbTipoOperVerifactu;
  Result.BotonNuevaFactura := AFormulario.btnNuevaFactura;
  Result.BotonRectificar := AFormulario.btnRectificar;
  Result.BotonConsolidar := AFormulario.btnConsolidar;
  Result.BotonImprimir := AFormulario.btnImprimir;
  Result.PaginasCabecera := AFormulario.pcCab;
  Result.PestanaCabecera := AFormulario.tsCabecera;
  Result.PestanaCliente := AFormulario.tsDatosCliente;
  Result.PestanaEmpresa := AFormulario.tsEmpresa;
  Result.PaginasDetalle := AFormulario.pcDetail;
  Result.PestanaLineas := AFormulario.tsLineasFactura;
  Result.RazonSocialCliente :=
    AFormulario.txtRAZONSOCIAL_CLIENTE_FACTURA;
  Result.RazonSocialEmpresa :=
    AFormulario.txtRAZONSOCIAL_EMPRESA_FACTURA;
  Result.NifCliente := AFormulario.txtNIF_CLIENTE_FACTURA;
  Result.NifEmpresa := AFormulario.txtNIF_EMPRESA_FACTURA;
  Result.PaisCliente := AFormulario.cbbPaisesCli;
end;

function ControlesRegistroFacturaVcl(
  AFormulario: TfrmMtoFacturasBase): TControlesRegistroFacturaVcl;
begin
  Result := Default(TControlesRegistroFacturaVcl);
  Result.IdConsolidacion := AFormulario.spID_CONSOLIDACION;
  Result.Estado := AFormulario.txtESTADO;
  Result.RespuestaCompleta := AFormulario.cxdbmRESPUESTA_COMPLETA;
  Result.ImagenQr := AFormulario.imgQRCODE_PNG;
  Result.IdCola := AFormulario.spQUEUE_ID;
  Result.FechaProcesamiento := AFormulario.dteFECHA_PROCESAMIENTO;
  Result.EmisorIrs := AFormulario.txtISSUER_IRS_ID;
  Result.InstanteEmision := AFormulario.dteISSUED_TIME;
  Result.NumeroCadena := AFormulario.txtCHAIN_NUMBER;
  Result.HashCadena := AFormulario.txtCHAIN_HASH;
  Result.UrlVerifactu := AFormulario.cxdbmVERIFACTU_URL;
  Result.QrBase64 := AFormulario.cxdbmQRCODE_BASE64;
  Result.PeticionCompleta := AFormulario.cxdbmPETICION_COMPLETA_FACCON;
  Result.IdPeticion := AFormulario.txtREQUEST_ID;
  Result.VistaLog := AFormulario.tvLogVerifactu;
end;

procedure PrepararDependenciasFacturas(
  AFormulario: TfrmMtoFacturasBase);
var
  oOperacionesVista: TOperacionesVistaFacturaVcl;
begin
  if AFormulario.FDependencias.Vista = nil then
  begin
    oOperacionesVista := Default(TOperacionesVistaFacturaVcl);
    oOperacionesVista.Confirmar :=
      function(const APregunta: string): Boolean
      begin
        Result := MessageDlg_fza(
          APregunta,
          mtConfirmation,
          [mbYes, mbNo],
          0) = mrYes;
      end;
    oOperacionesVista.MostrarInformacion :=
      procedure(const AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
    oOperacionesVista.MostrarError :=
      procedure(const AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
    oOperacionesVista.RefrescarFactura :=
      procedure
      begin
        if Assigned(AFormulario.dsTablaG.DataSet) and
           AFormulario.dsTablaG.DataSet.Active then
          AFormulario.dsTablaG.DataSet.Refresh;
      end;
    oOperacionesVista.RefrescarMovimientos :=
      procedure
      begin
        if Assigned(AFormulario.dmmFacturas) and
           Assigned(AFormulario.dmmFacturas.unqryMovimientosFac) and
           AFormulario.dmmFacturas.unqryMovimientosFac.Active then
          AFormulario.dmmFacturas.unqryMovimientosFac.Refresh;
      end;
    oOperacionesVista.ArchivarFactura :=
      procedure(const ASerie, ANumero: string)
      begin
        ArchivarFacturaConsolidadaVcl(
          AFormulario.dmmFacturas,
          ASerie,
          ANumero,
          AFormulario.RegistroLog);
      end;
    oOperacionesVista.AplicarEstado :=
      procedure(const AEstado: TEstadoVisualFactura)
      var
        Configuracion: TConfiguracionEstadoFiscalFactura;
        Controles: TControlesEstadoFiscalFactura;
      begin
        if Assigned(AFormulario.dmmFacturas) then
          AFormulario.dmmFacturas.unqryLinFac.ReadOnly :=
            not AEstado.Editable;
        // En subsanación la estructura de las líneas no cambia.
        AFormulario.btnAnadirLinea.Enabled :=
          AEstado.Editable and not AEstado.Subsanando;
        AFormulario.btnBorrarLinea.Enabled :=
          AFormulario.btnAnadirLinea.Enabled;
        Configuracion := Default(TConfiguracionEstadoFiscalFactura);
        Configuracion.Editable := AEstado.Editable;
        Configuracion.ActualizarAcciones := AEstado.ActualizarAcciones;
        Configuracion.PuedeConsolidar := AEstado.PuedeConsolidar;
        // El modal permite actuar sobre todas las filas filtradas aunque la
        // fila enfocada sea todavía un borrador. La opción "Actual" se
        // deshabilita después si esa fila no cumple la política fiscal.
        Configuracion.PuedeImprimir :=
          AFormulario.PuedeImprimir and
          Assigned(AFormulario.dsTablaG.DataSet) and
          AFormulario.dsTablaG.DataSet.Active and
          not AFormulario.dsTablaG.DataSet.IsEmpty;
        Configuracion.EstructuraLineasBloqueada := AEstado.Subsanando;
        Controles := Default(TControlesEstadoFiscalFactura);
        Controles.DataSourceCabecera := AFormulario.dsTablaG;
        Controles.VistaLineas := AFormulario.tvLineasFactura;
        Controles.BotonConsolidar := AFormulario.btnConsolidar;
        Controles.BotonImprimir := AFormulario.btnImprimir;
        TPresentacionEstadoFiscalFactura.Aplicar(
          Configuracion,
          Controles);
        AFormulario.AplicarBloqueoSubsanacion(AEstado.Subsanando);
      end;
    oOperacionesVista.AplicarModoEntrada :=
      procedure(AModo: TModoEntradaFactura)
      begin
        case AModo of
          mefAutomatico:
            AFormulario.FModoEntradaSel := mcsAuto;
          mefSku:
            AFormulario.FModoEntradaSel := mcsSku;
          mefTallas:
            AFormulario.FModoEntradaSel := mcsTallasHorPed;
        end;
        AFormulario.ConstruirModoEntrada;
      end;
    AFormulario.FDependencias.Vista := CrearVistaFacturaVcl(
      oOperacionesVista);
    AFormulario.FDependencias.Estado := CrearPresentadorEstadoFactura(
      AFormulario.FDependencias.Vista);
    AFormulario.FDependencias.ModoEntrada :=
      CrearGestorModoEntradaFactura(
      AFormulario.FDependencias.Vista,
      mefAutomatico);
    AFormulario.FDependencias.Consolidacion :=
      CrearAplicacionConsolidacionFactura(
        AFormulario.FDependenciasInyeccion.Consolidacion,
        AFormulario.FDependencias.Vista);
    AFormulario.FDependencias.OperacionFiscal :=
      CrearAplicacionOperacionFiscalFactura(
        AFormulario.FDependenciasInyeccion.EmisionFiscal,
        AFormulario.FDependencias.Vista);
    AFormulario.FDependencias.Cobros :=
      CrearAplicacionCobrosFactura(
        AFormulario.FDependenciasInyeccion.Cobros);
  end;
end;

procedure ComponerPresentadoresFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
begin
  // Composicion de la pantalla: los presentadores reciben controles y
  // puertos concretos, nunca el formulario completo.
  FreeAndNil(AFormulario.FEditorLineas);
  AFormulario.FEditorLineas := TEditorLineasFactura.Create(
    AFormulario.ConexionPrincipal,
    AFormulario.dmmFacturas.unqryTablaG,
    AFormulario.dmmFacturas.unqryLinFac,
    AFormulario.FDependenciasInyeccion.Lineas.Articulos.Validador,
    AFormulario.FDependenciasInyeccion.Lineas.Articulos.Resolver,
    AFormulario.FDependenciasInyeccion.Lineas.Articulos.Atributos,
    AFormulario.FDependenciasInyeccion.Lineas.Lecturas);
  FreeAndNil(AFormulario.FPresentadorLineas);
  AFormulario.FPresentadorLineas := TPresentadorLineasFacturaVcl.Create(
    CrearContextoLineasFacturaVcl(AFormulario));
  AFormulario.FPresentadorLineas.ActualizarEditor(
    AFormulario.FEditorLineas);
  AFormulario.FPresentadorLineas.ActualizarColumnas(
    ColumnasDetalleFacturaActuales(AFormulario));
  FreeAndNil(AFormulario.FPresentadorCabecera);
  AFormulario.FPresentadorCabecera := TPresentadorCabeceraFacturaVcl.Create(
    CrearContextoCabeceraFacturaVcl(AFormulario));
end;

procedure EnlazarAvisosFacturaVcl(AFormulario: TfrmMtoFacturasBase);
begin
  // Avisos y validaciones que el data module delega en la pantalla.
  AFormulario.dmmFacturas.OnResultadoOperacion :=
    AFormulario.FPresentadorCabecera.MostrarResultadoOperacion;
  AFormulario.dmmFacturas.OnResultadoBorrado :=
    AFormulario.FPresentadorCabecera.MostrarResultadoBorrado;
  AFormulario.dmmFacturas.OnAdvertencia :=
    AFormulario.FPresentadorCabecera.MostrarAdvertencia;
  AFormulario.dmmFacturas.OnValidacion :=
    AFormulario.FPresentadorCabecera.MostrarErrorValidacion;
  AFormulario.dmmFacturas.OnConfirmarBorrado :=
    AFormulario.FPresentadorCabecera.ConfirmarBorrado;
  AFormulario.dmmFacturas.OnNuevaFactura :=
    AFormulario.sbNuevaFacturaClick;
  AFormulario.dmmFacturas.OnSeriesCambiadas :=
    AFormulario.FPresentadorCabecera.SeriesCambiadas;
  AFormulario.dmmFacturas.OnLinFacEstado :=
    AFormulario.FPresentadorLineas.AplicarEdicionPrecios;
end;

procedure EnlazarOrigenesDatosFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
begin
  AFormulario.cbbTARIFA_ARTICULOS_CLIENTES.Properties.ListSource :=
    AFormulario.dmmFacturas.dsTarifas;
  AFormulario.cbbAlmacenFactura.Properties.ListSource :=
    AFormulario.dmmFacturas.dsAlmacenesFac;
  AplicarOrigenCobrosFacturaVcl(AFormulario);
  AFormulario.btnReciboEmitido.OnClick :=
    AFormulario.btnReciboEmitidoClick;
  AFormulario.btnReciboDevuelto.OnClick :=
    AFormulario.btnReciboDevueltoClick;
  AFormulario.tvMovimientosFac.DataController.DataSource :=
    AFormulario.dmmFacturas.dsMovimientosFac;
  AFormulario.cbbPaisesEmp.Properties.ListSource :=
    AFormulario.dmmFacturas.dsPaisesEmp;
  AFormulario.cbbPaisesCli.Properties.ListSource :=
    AFormulario.dmmFacturas.dsPaisesCli;
  ConfigurarComboPaisNumerico(AFormulario.cbbPaisesCli);
  ConfigurarComboPaisNumerico(AFormulario.cbbPaisesEmp);
  AFormulario.cbbTipoOperVerifactu.Properties.ListSource :=
    AFormulario.dmmFacturas.dsVerifactuOpe;
  (AFormulario.ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties as
    TcxLookupComboBoxProperties).ListSource :=
    AFormulario.dmmFacturas.dsIvasTipos;
end;

procedure EnlazarEdicionDetalleFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
var
  PropiedadesSku: TcxComboBoxProperties;
begin
  // Cantidad con decimales segun la unidad de cada linea (telas por
  // metros...).
  VincularCantidadGrid(AFormulario.ctbCANTIDAD_FACTURA_LINEA,
                       AFormulario.ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA,
                       AFormulario.UnidadesMedida);
  // Regla del SKU por linea: no se puede ocultar una columna por fila,
  // asi que se vacia su texto (OnGetDataText) y se bloquea su edicion
  // (OnEditing) segun el articulo de cada linea.
  AFormulario.FEditorLineas.VaciarCache;
  AFormulario.ctbCODIGO_UNIDAD_FACTURA_LINEA.OnGetDataText :=
    AFormulario.FPresentadorLineas.TextoSkuLinea;
  PropiedadesSku := TcxComboBoxProperties(
    AFormulario.ctbCODIGO_UNIDAD_FACTURA_LINEA.Properties);
  PropiedadesSku.ImmediatePost := True;
  PropiedadesSku.PostPopupValueOnTab := True;
  PropiedadesSku.OnCloseUp := AFormulario.FPresentadorLineas.CerrarPopupSku;
  AFormulario.tvLineasFactura.OnInitEdit :=
    AFormulario.FPresentadorLineas.IniciarEdicion;
  AFormulario.tvLineasFactura.OnEditKeyDown :=
    AFormulario.FPresentadorLineas.TeclaEnEdicion;
  AFormulario.tvLineasFactura.OnEditing :=
    AFormulario.FPresentadorLineas.PermitirEdicion;
  // La visibilidad del detalle se recalcula al cambiar/recargar lineas.
  AFormulario.dmmFacturas.dsLinFac.OnDataChange :=
    AFormulario.FPresentadorLineas.CambioEnLineas;
end;

procedure EnlazarRegistroFacturaVcl(AFormulario: TfrmMtoFacturasBase);
begin
  AsignarOrigenesRegistroFacturaVcl(
    ControlesRegistroFacturaVcl(AFormulario),
    AFormulario.dmmFacturas.dsConsolidacion,
    AFormulario.dmmFacturas.dsErrores);
  // El check de mover stock solo aplica a facturas NORMAL: en
  // SIMPLIFICADA se generan movimientos siempre.
  AFormulario.chkMueveStock.Visible := SameText(
    AFormulario.TipoFacturaFiltro, 'NORMAL');
  // Convertir en normal solo aplica a facturas simplificadas (F3 AEAT).
  AFormulario.btnVerifactuFacturar.Visible := SameText(
    AFormulario.TipoFacturaFiltro, 'SIMPLIFICADA');
  AplicarOrigenCobrosFacturaVcl(AFormulario);
end;

procedure PrepararConsultaListadoFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
var
  sVista: string;
  sAviso: string;
  bEstadoCola: Boolean;
begin
  // El adaptador usa la vista de cada descendiente para clasificar las
  // facturas y sus rectificativas. La pantalla no arma SQL.
  sVista := AFormulario.NombreVistaListado;
  bEstadoCola := AFormulario.FDependenciasInyeccion.Listado.
    EstadoColaDisponible(sAviso);
  if sAviso <> '' then
    AFormulario.RegistroLog.RegistrarAviso(sAviso);
  AFormulario.dmmFacturas.unqryTablaG.DisableControls;
  try
    AFormulario.dmmFacturas.unqryTablaG.Close;
    AFormulario.FDependenciasInyeccion.Listado.PrepararListado(
      AFormulario.dmmFacturas.unqryTablaG,
      sVista,
      bEstadoCola);
    // Los descendientes que precargan con filtros propios devuelven
    // False y abren ellos la lista (filtrada, con progreso) en
    // ResetForm. La base (vi_facturas) tampoco abre aqui: lo hace el
    // open asincrono de TfrmMtoGen con overlay.
    if AFormulario.AbrirListadoAlCrear and
       (not SameText(sVista, 'vi_facturas')) then
      AFormulario.dmmFacturas.unqryTablaG.Open;
  finally
    AFormulario.dmmFacturas.unqryTablaG.EnableControls;
  end;
end;

function CrearConfigColumnasSkuFacturaVcl(
  AFormulario: TfrmMtoFacturasBase;
  ALineas: TDataSet): TConfigColumnasSku;
begin
  Result := CrearConfigColumnasSkuDocumento(
    AFormulario.FDependenciasInyeccion.Lineas.ColumnasSku,
    AFormulario.ContextoSesion,
    AFormulario.tvLineasFactura, ALineas,
    AFormulario.FModoEntradaSel, '', 'FACLIN');
  Result.RegistroLog := AFormulario.RegistroLog;
  Result.BusquedaVisual := AFormulario.BusquedaVisual;
  Result.DistribuidorTallasVisual := AFormulario.DistribuidorTallasVisual;
  Result.ValidadorArticulos :=
    AFormulario.FDependenciasInyeccion.Lineas.Articulos.Validador;
  Result.LookupAtributos :=
    AFormulario.FDependenciasInyeccion.Lineas.Articulos.Atributos;
  Result.UsarCombosAtributos := True;
  Result.BuscarSoloPadresEnDesglose := True;
  if AFormulario.dmmFacturas.unqryTablaG.FindField(
    'CODIGO_ALM_FAC') <> nil then
    Result.AlmacenStock := Trim(
      AFormulario.dmmFacturas.unqryTablaG.FieldByName(
        'CODIGO_ALM_FAC').AsString);
  // La venta mayor factura tambien articulos fuera de catalogo: el modo
  // acepta el codigo tecleado como linea libre (sin SKU).
  Result.AceptarNoCatalogo := SameText(
    AFormulario.TipoFacturaFiltro, 'NORMAL');
  Result.Campos.Almacen := '';
  // Precio por SKU para la consolidacion VISUAL del modo tallas: filas
  // con precio distinto no fusionan.
  Result.ObtenerPrecioSku := AFormulario.FPresentadorLineas.PrecioSku;
end;

function CrearConfigPivoteVentaFacturaVcl(
  AFormulario: TfrmMtoFacturasBase): TGridPivoteVentaConfig;
begin
  Result := Default(TGridPivoteVentaConfig);
  Result.UnidadesMedida := AFormulario.UnidadesMedida;
  Result.Conexion := AFormulario.dmmFacturas.unqryTablaG.Connection;
  Result.Usuario := AFormulario.IdentidadSesion.Usuario;
  Result.SourceMaster := AFormulario.dsTablaG;
  Result.SourceLineas := AFormulario.dmmFacturas.dsLinFac;
  Result.FieldSerieMaster := 'SERIE_FAC';
  Result.FieldNumeroMaster := 'NUMERO_FAC';
  Result.FieldLinea := 'LINEA_FACLIN';
  Result.FieldArt := 'CODIGO_ART_FACLIN';
  Result.FieldSku := 'CODIGO_UNIDAD_FACLIN';
  Result.FieldDescripcion := 'DESCRIPCION_ARTICULO_FACLIN';
  Result.FieldTipoCantidad := 'TIPO_CANTIDAD_ARTICULO_FACLIN';
  // Factura: UNA sola cantidad por linea -> banda unica.
  Result.FieldCantidadPedida := 'CANTIDAD_FACLIN';
  Result.FieldCantidadEntregada := '';
  Result.FieldCantidadAAlbaranar := '';
  Result.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN';
  Result.FieldAlmacen := '';
  Result.FieldAlmacenMaster := '';
  Result.MaxColumnas := MAX_TALLAS_HORIZONTAL;
  Result.BandaUnica := True;
  Result.Repositorios := AFormulario.FDependenciasInyeccion.Lineas.Pivote.
    Crear(Result.Usuario, AFormulario.BusquedaVisual);
  Result.OnCrearLineaSku :=
    AFormulario.FPresentadorLineas.PivoteCrearLineaSku;
  Result.OnBandaCambiada :=
    AFormulario.FPresentadorLineas.PivoteBandaCambiada;
end;

procedure AplicarTituloModoEntradaFacturaVcl(
  AFormulario: TfrmMtoFacturasBase;
  const AConfig: TConfigColumnasSku);
begin
  case DetectarModoColumnasSku(AConfig) of
    mcsSku:
      AFormulario.tsLineasFactura.Caption :=
        SCaptionTabLineasBorradorSku;
    mcsTallasHorPed:
      AFormulario.FPresentadorLineas.PivoteBandaCambiada(bpvPedida);
  else
    begin
      AFormulario.tsLineasFactura.Caption :=
        SCaptionTabLineasBorradorDesglose;
      AplicarNombresAtributosGlobalesDocumento(
        AFormulario.tvLineasFactura,
        AFormulario.FDependenciasInyeccion.Lineas.AtributosGlobales.
          ListarNombresAtributosGlobales);
    end;
  end;
end;

procedure AsignarColumnasFacturaVcl(
  AFormulario: TfrmMtoFacturasBase;
  const AColumnas: TColumnasFactura);
begin
  AFormulario.ctbLINEA_FACTURA_LINEA := AColumnas.Linea;
  AFormulario.ctbCODIGO_ARTICULO_FACTURA_LINEA := AColumnas.Articulo;
  AFormulario.ctbCODIGO_UNIDAD_FACTURA_LINEA := AColumnas.Sku;
  AFormulario.ctbCODIGO_FAMILIA_FACTURA_LINEA := AColumnas.CodigoFamilia;
  AFormulario.ctbNOMBRE_FAMILIA_FACTURA_LINEA := AColumnas.NombreFamilia;
  AFormulario.ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA :=
    AColumnas.EsProveedorPrincipal;
  AFormulario.ctbCODIGO_PROVEEDOR_FACTURA_LINEA :=
    AColumnas.CodigoProveedor;
  AFormulario.ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA :=
    AColumnas.RazonSocialProveedor;
  AFormulario.ctbPRECIO_ULT_COMPRA_FACTURA_LINEA :=
    AColumnas.PrecioUltimaCompra;
  AFormulario.ctbDESCRIPCION_ARTICULO_FACTURA_LINEA :=
    AColumnas.DescripcionArticulo;
  AFormulario.ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA :=
    AColumnas.TipoCantidad;
  AFormulario.ctbCANTIDAD_FACTURA_LINEA := AColumnas.Cantidad;
  AFormulario.ctbPRECIOSALIDA_FACTURA_LINEA := AColumnas.PrecioSalida;
  AFormulario.ctbPORCEN_DTO_FACTURA_LINEA :=
    AColumnas.PorcentajeDescuento;
  AFormulario.ctbPRECIO_DTO_FACTURA_LINEA := AColumnas.PrecioDescuento;
  AFormulario.ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA :=
    AColumnas.PrecioVentaSinIva;
  AFormulario.ctbIMP_INCL_TARIFA_FACTURA_LINEA :=
    AColumnas.ImpuestosIncluidos;
  AFormulario.ctbTIPOIVA_ARTICULO_FACTURA_LINEA := AColumnas.TipoIva;
  AFormulario.ctbPORCEN_IVA_FACTURA_LINEA := AColumnas.PorcentajeIva;
  AFormulario.ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA :=
    AColumnas.PrecioVentaConIva;
  AFormulario.ctbTOTAL_FACTURA_LINEA := AColumnas.TotalConIva;
  AFormulario.ctbTOTAL_FACTURASIVA_LINEA := AColumnas.TotalSinIva;
  AFormulario.ctbFECHA_ENTREGA_FACTURA_LINEA := AColumnas.FechaEntrega;
end;

procedure EnlazarHandlersColumnasFacturaVcl(
  AFormulario: TfrmMtoFacturasBase);
begin
  if Assigned(AFormulario.ctbCANTIDAD_FACTURA_LINEA) then
    TcxSpinEditProperties(
      AFormulario.ctbCANTIDAD_FACTURA_LINEA.Properties).
      OnEditValueChanged := AFormulario.
        cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(
    AFormulario.ctbPRECIOSALIDA_FACTURA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
      tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged;
  TcxSpinEditProperties(
    AFormulario.ctbPORCEN_DTO_FACTURA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
      tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(
    AFormulario.ctbPRECIO_DTO_FACTURA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
      tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(
    AFormulario.ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxLookupComboBoxProperties(
    AFormulario.ctbTIPOIVA_ARTICULO_FACTURA_LINEA.Properties).
    OnChange := AFormulario.
      cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange;
  TcxCurrencyEditProperties(
    AFormulario.ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged;
  TcxCurrencyEditProperties(
    AFormulario.ctbTOTAL_FACTURASIVA_LINEA.Properties).
    OnEditValueChanged := AFormulario.
      ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged;
end;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoFacturasBase.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasFacturas);
begin
  ADependencias.Validar;
  FDependenciasInyeccion := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoFacturasBase.ResetForm;
begin
  inherited;
  if Assigned(dmmFacturas) and Assigned(pcCab) and Assigned(pcDetail) then
  begin
    pcCab.ActivePage := tsCabecera;
    pcDetail.ActivePage := tsLineasFactura;
  end;
end;
destructor TfrmMtoFacturasBase.Destroy;
begin
  FreeAndNil(FVentanaReferencias);
  FreeAndNil(FLectorDocumento);
  // El modo del contrato se libera ANTES del inherited: su teardown
  // (Desmontar/destructor) toca el view y el dataset de lineas, que
  // deben seguir vivos. Si se dejara a la finalizacion de la interfaz,
  // correria con el DM ya destruido.
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      // Teardown defensivo en cierre: nada que hacer si el grid ya
      // esta a medio destruir.
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'FacturasBase.Destroy: Desmontar fallo: ' + E.Message);
    end;
    FModoEntrada := nil;
  end;
  if Assigned(FPresentadorLineas) then
    FPresentadorLineas.RestaurarEnterSku(Self);
  FreeAndNil(FPresentadorLineas);
  FreeAndNil(FPresentadorCabecera);
  FreeAndNil(FEditorLineas);
  FDependencias := Default(TDependenciasPresentacionFacturas);
  FDependenciasInyeccion.Liberar;
  inherited;
end;
procedure TfrmMtoFacturasBase.btnUpdateClienteClick(Sender: TObject);
begin
  inherited;
  if dmmFacturas.unqryTablaG.FieldByName(
       'CODIGO_CLI_FAC').AsString = '0' then
    dmmFacturas.GetCodigoAutoCliente;
  dmmFacturas.CrearCliente;
  ShowMessageFmt_fza(SCliToTbl,
    [dmmFacturas.unqryTablaG.FieldByName('CODIGO_CLI_FAC').AsString]);
end;
procedure TfrmMtoFacturasBase.btnUpdateEmpresaClick(Sender: TObject);
begin
  inherited;
  if dmmFacturas.unqryTablaG.FieldByName(
       'CODIGO_EMP_FAC').AsString = '0' then
    dmmFacturas.GetCodigoAutoEmpresa;
  dmmFacturas.CrearEmpresa;
  ShowMessageFmt_fza(SEmpToTbl,
    [dmmFacturas.unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString]);
end;
procedure TfrmMtoFacturasBase.sbNuevaFacturaClick(Sender: TObject);
var
  sEmpresaDef:String;
begin
  inherited;
  dmmFacturas.unqryTablaG.ReadOnly := False;
  if (dmmFacturas.unqryTablaG.State <> dsEdit) then
  begin
    if (dmmFacturas.unqryTablaG.State <> dsInsert) then
    begin
      dmmFacturas.unqryTablaG.Insert;
    end;
    txtNRO_FACTURA.Properties.ReadOnly := False;
    cbbSerieFactura.Properties.ReadOnly := False;
    cbbTARIFA_ARTICULOS_CLIENTES.Properties.ReadOnly := False;
    cbbCanalIVA.Properties.ReadOnly := False;
    Self.ResetForm;
    pcPantalla.ActivePage := tsFicha;
    pcCab.ActivePage := tsCabecera;
    btnCODIGO_EMPRESA_FACTURA.SetFocus;
    sEmpresaDef := dmmFacturas.GetUserEmpresaDef;
    if (sEmpresaDef <> '') then
    begin
      dsTablaG.DataSet.FindField('CODIGO_EMP_FAC').AsString :=
                                                                    sEmpresaDef;
    end;
  end;
end;


procedure TfrmMtoFacturasBase.btnImprimirReciboClick(Sender: TObject);
begin
  inherited;
  TCoordinadorCobrosFacturaVcl.ImprimirRecibo(
    CrearContextoCobrosFacturaVcl(Self),
    PuedeImprimir);
end;
procedure TfrmMtoFacturasBase.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasFactura.DataController.DataSet, fcodart);
end;
procedure TfrmMtoFacturasBase.actArticuloExecute(Sender: TObject);
begin
  inherited;
    if ((pcDetail.ActivePage = tsLineasFactura)) then
       btnIraArticuloClick(Sender)
    else
      ShowMto(Self.Owner, 'Articulos');
end;
procedure TfrmMtoFacturasBase.actClienteExecute(Sender: TObject);
begin
  inherited;
  btnIraClienteClick(Sender);
end;
procedure TfrmMtoFacturasBase.actEmpresaExecute(Sender: TObject);
begin
  inherited;
  btnIrAEmpresaClick(Sender);
end;
procedure TfrmMtoFacturasBase.actMovimientoExecute(Sender: TObject);
var
  ds: TDataSet;
begin
  inherited;
  // Ctrl+M: ir al movimiento de almacen seleccionado en la pestaña
  // Movimientos. Navegamos a 'MovimientosAlmacen' por PK (NUMERO_MOV) via
  // ShowMto. Fuera de esa pestaña, abrimos el listado sin localizar.
  ds := nil;
  if (pcDetail.ActivePage = tsMovimientosFac) and
     Assigned(tvMovimientosFac.DataController.DataSet) then
    ds := tvMovimientosFac.DataController.DataSet;
  ShowMtoCodigoDataSet(Self.Owner, 'MovimientosAlmacen',
    ds, 'NUMERO_MOV');
end;

procedure TfrmMtoFacturasBase.btnExportarLineasClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdLineasFactura, 'Lineas_Borrador_' +
                dsTablaG.Dataset.FieldByName(fseriefac).AsString +
                '_' +
                dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturasBase.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  // El OnEnter de la rejilla graba la cabecera, abre las líneas y
  // construye el modo de entrada: sin él, el alta se haría sobre las
  // columnas del dfm. FZ-ISSUE-422: con otra pestaña activa la rejilla
  // no puede recibir el foco y lo tecleado iba a los aceleradores.
  pcDetail.ActivePage := tsLineasFactura;
  if cxgrdLineasFactura.CanFocus then
    cxgrdLineasFactura.SetFocus;
  // Graba antes la línea en edición (con lo tecleado en la celda): si no,
  // la nueva heredaba lo que se tecleaba y la anterior se grababa con otro
  // artículo y precio 0 (FZ-ISSUE-743).
  ConfirmarLineaDocumento(tvLineasFactura);
  AnadirLineaDocumento(dmmFacturas.unqryLinFac, FModoEntrada);
end;

procedure TfrmMtoFacturasBase.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  BorrarLineaDocumento(dmmFacturas.unqryLinFac, FModoEntrada,
    SPreguntaEliminarLineaAlbaranVenta);
end;

procedure TfrmMtoFacturasBase.btnCalculatorClick(Sender: TObject);
begin
  inherited;
  MostrarCalculadora(Self);
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEKeyUp(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  inherited;
//  if ((Key = VK_RETURN) and (Shift = [ssCtrl])) then
//    btnBuscar_Clientes_ActivosClick(nil);
  if (Key = VK_RETURN) then
  begin
    //bKeyCODIGO_CLIENTEStroked := True;
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesButtonClick(
                                                         Sender: TObject;
                                                         AButtonIndex: Integer);
begin
  if SinVerifactuActivo(ParametrosApp) or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if BusquedaVisual.EjecutarBusqueda(
      ConexionPrincipal,
      STituloBuscarClientesBorradoresFactura,
                                       dmmFacturas.unqryCliDataFac,
                                       'frmMtoCliFacSearch') then
     begin
       dmmFacturas.CopiarClienteaFactura(dmmFacturas.unqryClidataFac);
     end;
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesChange(
  Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_CLIENTEPropertiesEditValueChanged(
  Sender: TObject);
  var
    e: TcxCustomEdit;
    sCodigo:String;
begin
  inherited;
  if (Assigned(dsTablaG.DataSet)) then
    if (        ((dsTablaG.DataSet.State = dsInsert) or
                 (dsTablaG.Dataset.State = dsEdit))
       ) then
    begin
      e := Sender as TcxCustomEdit;
      sCodigo := VarToStr(e.EditingValue);
      if ((sCodigo <> '') and (sCodigo <> '0')) then
      begin
        dmmFacturas.BuscarCliente(VarToStr(e.EditingValue));
      end;
    end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if SinVerifactuActivo(ParametrosApp) or
     (dmmFacturas.unqryTablaG.FieldByName(fescon).AsString <> 'S') then
  begin
    if BusquedaVisual.EjecutarBusqueda(
      ConexionPrincipal,
      STituloBuscarEmpresasBorradoresFactura,
                                       dmmFacturas.unqryEmpDataFac,
                                       'frmMtoEmpFacSearch') then
      dmmFacturas.CopiarEmpresaaFactura(dmmFacturas.unqryEmpDataFac);
  end;
end;

procedure TfrmMtoFacturasBase.btnCODIGO_EMPRESA_FACTURAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  //ActualizarComboSeries;
end;

procedure TfrmMtoFacturasBase.btnExportarRecibosClick(Sender: TObject);
var
  Configuracion: TConfiguracionCobrosFactura;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  Configuracion := CrearConfiguracionCobrosFactura(TipoFacturaFiltro);
  ExportarExcel(
    ParametrosApp,
    cxgrdRecibos,
    Configuracion.PrefijoExportacion +
      dsTablaG.Dataset.FieldByName(fseriefac).AsString + '_' +
      dsTablaG.Dataset.FieldByName(fnrofac).AsString);
end;

procedure TfrmMtoFacturasBase.GuardarCambiosFactura;
begin
  GuardarConRecuperacionNumeracion(dmmFacturas.unqryTablaG.Connection,
    dmmFacturas,
    procedure
    begin
      inLibFacturas.GuardarCambiosPendientesFactura(
        dmmFacturas.unqryTablaG.Connection,
        dmmFacturas.unqryTablaG,
        dmmFacturas.dsLinFac.DataSet,
        dmmFacturas.dsRecibos.DataSet);
    end);
end;

procedure TfrmMtoFacturasBase.GuardarPendienteAntesDeImprimir;
begin
  if Assigned(dmmFacturas) then
  begin
    try
      GuardarCambiosFactura;
    except
      on E: EAbort do
        raise;
      on E: Exception do
        raise Exception.Create(Format(
          SErrorGuardarFacturaAntesImprimir,
          [E.Message]));
    end;
  end;
end;

function CrearReferenciasFacturasFiltradas(
  AView: TcxGridDBTableView;
  AIndiceSerie, AIndiceNumero: Integer): TReferenciasComandoFactura;
var
  iFila: Integer;
  iRegistro: Integer;
  oClaves: TStringList;
  oLista: TList<TReferenciaComandoFactura>;
  oReferencia: TReferenciaComandoFactura;
  sClave: string;
  sNumero: string;
  sSerie: string;
begin
  oLista := TList<TReferenciaComandoFactura>.Create;
  oClaves := TStringList.Create;
  try
    oClaves.CaseSensitive := False;
    oClaves.Sorted := True;
    for iFila := 0 to AView.DataController.FilteredRecordCount - 1 do
    begin
      iRegistro := AView.DataController.FilteredRecordIndex[iFila];
      sSerie := Trim(VarToStr(AView.DataController.Values[
        iRegistro, AIndiceSerie]));
      sNumero := Trim(VarToStr(AView.DataController.Values[
        iRegistro, AIndiceNumero]));
      if (sSerie <> '') and (sNumero <> '') then
      begin
        oReferencia := TReferenciaComandoFactura.Crear(
          sSerie, sNumero);
        sClave := UpperCase(sSerie) + #1 + UpperCase(sNumero);
        if oClaves.IndexOf(sClave) < 0 then
        begin
          oClaves.Add(sClave);
          oLista.Add(oReferencia);
        end;
      end;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oClaves);
    FreeAndNil(oLista);
  end;
end;

function TfrmMtoFacturasBase.ObtenerReferenciasFiltradas:
  TReferenciasComandoFactura;
var
  oDataSet: TDataSet;
  oMarcador: TBookmark;
begin
  Result := nil;
  oDataSet := cxGrdDBTabPrin.DataController.DataSet;
  if (oDataSet <> nil) and oDataSet.Active then
  begin
    if (oDataSet.State in dsEditModes) or
       (Assigned(dmmFacturas) and
        Assigned(dmmFacturas.unqryLinFac) and
        (dmmFacturas.unqryLinFac.State in dsEditModes)) or
       (Assigned(dmmFacturas) and
        Assigned(dmmFacturas.unqryRecibos) and
        (dmmFacturas.unqryRecibos.State in dsEditModes)) then
      raise EInvalidOpException.Create(
        SErrorCambiosPendientesProcesarFiltradas);
    if tmrBusqGlobal.Enabled then
      tmrBusqGlobalTimer(tmrBusqGlobal);
    oDataSet := cxGrdDBTabPrin.DataController.DataSet;
    if (oDataSet <> nil) and oDataSet.Active then
    begin
      if oDataSet.State in dsEditModes then
        raise EInvalidOpException.Create(
          SErrorCambiosPendientesProcesarFiltradas);
      oMarcador := nil;
      if not oDataSet.IsEmpty then
      begin
        oMarcador := oDataSet.GetBookmark;
        oDataSet.DisableControls;
        try
          // UniDAC obtiene la consulta por bloques. Last fuerza que el filtro
          // local del grid pueda evaluar también los registros aún no leídos.
          oDataSet.Last;
          if oDataSet.BookmarkValid(oMarcador) then
            oDataSet.GotoBookmark(oMarcador);
        finally
          oDataSet.EnableControls;
          oDataSet.FreeBookmark(oMarcador);
        end;
        cxGrdDBTabPrin.DataController.Refresh;
      end;
      Result := CrearReferenciasFacturasFiltradas(
        cxGrdDBTabPrin,
        cxgrdbclmnGrdDBTabPrinSERIE_FACTURA.Index,
        cxgrdbclmnGrdDBTabPrinNRO_FACTURA.Index);
    end;
  end;
end;

procedure TfrmMtoFacturasBase.sbImprimirClick(Sender: TObject);
begin
  inherited;
  ImprimirFacturaVcl(
    Self,
    dmmFacturas,
    dsTablaG.DataSet,
    Conexiones,
    ContextoSesion,
    ParametrosApp,
    Permisos,
    RegistroLog,
    PuedeImprimir,
    procedure
    begin
      GuardarPendienteAntesDeImprimir;
    end,
    function: TReferenciasComandoFactura
    begin
      Result := ObtenerReferenciasFiltradas;
    end);
end;

procedure TfrmMtoFacturasBase.btnReciboDevueltoClick(Sender: TObject);
begin
  inherited;
  TCoordinadorCobrosFacturaVcl.MarcarDevuelto(
    CrearContextoCobrosFacturaVcl(Self));
end;

procedure TfrmMtoFacturasBase.btnReciboEmitidoClick(Sender: TObject);
begin
  inherited;
  TCoordinadorCobrosFacturaVcl.MarcarPendiente(
    CrearContextoCobrosFacturaVcl(Self));
end;

procedure TfrmMtoFacturasBase.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.PrepararPopupSku(Sender);
end;

procedure TfrmMtoFacturasBase.
  ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.ConsolidarSku(Sender);
end;

procedure TfrmMtoFacturasBase.sbRectificarClick(Sender: TObject);
begin
  inherited;
  RectificarFacturaVcl(Self, dmmFacturas,
    FDependenciasInyeccion.Rectificativa);
end;

procedure TfrmMtoFacturasBase.cbbCanalIVAPropertiesChange(Sender: TObject);
var
 Edit: TcxCustomEdit;
 NewValue: Variant;
begin
  inherited;
  Edit := Sender as TcxCustomEdit;
  NewValue := Edit.EditingValue;
  if (NewValue <> null) then
  begin
    if ((dsTablaG.DataSet.State = dsEdit) or
        (dsTablaG.DataSet.State = dsInsert)) then
    begin
      dsTablaG.DataSet.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString :=
                                                             VarToStr(NewValue);
      FPresentadorCabecera.CambiarIVA;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.cbbSerieFacturaKeyUp(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    cbbSerieFactura.DroppedDown := True;
end;

procedure TfrmMtoFacturasBase.cbbSerieFacturaPropertiesChange(Sender: TObject);
var
  sSubtipo: string;
  sFiltro: string;
begin
  inherited;
  if (dsTablaG.Dataset <> nil) and
     (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
  begin
    // El formulario descendiente fija el tipo y manda sobre la serie.
    sFiltro := TipoFacturaFiltro;
    if sFiltro <> '' then
      sSubtipo := sFiltro
    else
    begin
      sSubtipo := dmmFacturas.GetSubtipoSerieEmpresa(
        dsTablaG.DataSet.FindField(fseriefac).AsString,
        dsTablaG.DataSet.FindField(fcodemp).AsString,
        dsTablaG.DataSet.FindField(ffechfac).AsDateTime);
      if sSubtipo = '' then
        sSubtipo := 'NORMAL';
    end;
    dsTablaG.DataSet.FindField(ftipofac).AsString := sSubtipo;
  end;
end;

procedure TfrmMtoFacturasBase.cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if dsTablaG.DataSet.State = dsInsert then
  begin
    e := Sender as TcxCustomEdit;
    sTarifa := VarToStr(e.EditingValue);
    // Sin tarifa elegida no hay nada que propagar a la cabecera.
    if sTarifa <> '' then
      FPresentadorCabecera.AplicarTarifa(sTarifa);
  end;
end;

// El borrado lo valida y lo confirma el data module (fase, rectificativa,
// «¿Borrar la factura...? Se eliminarán sus líneas...»): sin la pregunta
// genérica del guardián, que hablaba de «registros hijos» y salía antes
// incluso en facturas que no se pueden borrar (FZ-ISSUE-132).
function TfrmMtoFacturasBase.ContarHijosActivos: Integer;
begin
  Result := cBorradoConConfirmacionPropia;
end;

procedure TfrmMtoFacturasBase.CrearTablaPrincipal;
begin
  FDependenciasInyeccion.Validar;
  PrepararDependenciasFacturas(Self);
  InicializarDocumento(
    CrearConfiguracionDocumento(tdFactura, sdVenta));
  AsignarVistaLineasDocumento(tvLineasFactura);
  inherited;
  // Otros, la menos usada, va la última.
  tsOtros.PageIndex := pcDetail.PageCount - 1;
  dmmFacturas := TdmFacturas(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmFacturas));
  dmmFacturas.ConfigurarServicios(
    FDependenciasInyeccion.ServiciosDataModule);
  dmmFacturas.TipoFacturaDefecto := TipoFacturaFiltro;
  ComponerPresentadoresFacturaVcl(Self);
  EnlazarAvisosFacturaVcl(Self);
  ConfigurarTablaPrincipalDocumento(
    dmmFacturas, dsTablaG, tvLineasFactura,
    dmmFacturas.dsLinFac, [], pkFieldName,
    'NUMERO_FAC; SERIE_FAC');
  cbbSerieFactura.Properties.ListSource := dmmFacturas.dsSeries;
  cbbCanalIVA.Properties.ListSource := dmmFacturas.dsIvas;
  cbbFORMAPAGO.Properties.ListSource := dmmFacturas.dsFormasPago;
  cxgrdLineasFactura.OnEnter := cxgrdLineasFacturaEnter;
  cxgrdLineasFactura.OnExit := cxgrdLineasFacturaExit;
  // Contrato de entrada ColumnSKUcxGrid: Auto (desglose) por defecto;
  // F1 cicla los modos. La primera construccion se hace al abrir la
  // pantalla.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  FConstruyendoModo := False;
  if dmmFacturas.unqryLinFac.Active then
    ConstruirModoEntrada;
  EnlazarOrigenesDatosFacturaVcl(Self);
  EnlazarEdicionDetalleFacturaVcl(Self);
  // Estado inicial: SKU segun las lineas.
  FPresentadorLineas.ReaplicarVisibilidad;
  FPresentadorLineas.ActualizarTotalPrendas;
  EnlazarRegistroFacturaVcl(Self);
  // Carga perezosa de sub-pestañas detail (Recibos, Consolidacion,
  // Errores, Movimientos) y bloqueo por fase al cambiar de registro.
  pcDetail.OnChange := PcDetailChange;
  dsTablaG.OnDataChange := dsTablaGDataChange;
  ActualizarDesgloseRecargo;
  PrepararConsultaListadoFacturaVcl(Self);
  FPresentadorCabecera.ActualizarBloqueoEdicion;
  if FLectorDocumento = nil then
  begin
    ConfigurarLectorDocumento;
    ConfigurarTrazabilidadVenta;
  end;
  InstalarVerificacionNif;
  ActualizarReferenciasAusentes;
end;
procedure TfrmMtoFacturasBase.DoHide;
begin
  if Assigned(FVentanaReferencias) then
    FVentanaReferencias.Hide;
  inherited;
end;

procedure TfrmMtoFacturasBase.PrepararAvisosReferencias;
begin
  if FBotonAvisosReferencias = nil then
  begin
    FAsignadosCliente := btnCODIGO_CLIENTE.Style.AssignedValues;
    FAsignadosFormaPago := cbbFORMAPAGO.Style.AssignedValues;
    FAsignadosAlmacen := cbbAlmacenFactura.Style.AssignedValues;
    FTextoCliente := btnCODIGO_CLIENTE.Style.TextColor;
    FTextoFormaPago := cbbFORMAPAGO.Style.TextColor;
    FTextoAlmacen := cbbAlmacenFactura.Style.TextColor;
    FColorCliente := btnCODIGO_CLIENTE.Style.Color;
    FColorFormaPago := cbbFORMAPAGO.Style.Color;
    FColorAlmacen := cbbAlmacenFactura.Style.Color;
    FBotonAvisosReferencias := TcxButton.Create(Self);
    FBotonAvisosReferencias.Visible := False;
    FBotonAvisosReferencias.Parent := pButtonRightBar;
    // FZ-ISSUE-564: mismo alto que el resto de la botonera derecha.
    FBotonAvisosReferencias.Height := btnGrabar.Height;
    FBotonAvisosReferencias.Top := pButtonGen.Top -
      FBotonAvisosReferencias.Height;
    FBotonAvisosReferencias.Align := alBottom;
    FBotonAvisosReferencias.AlignWithMargins := True;
    FBotonAvisosReferencias.Caption := SBotonAvisosReferenciasFactura;
    FBotonAvisosReferencias.Hint := SHintAvisosReferenciasFactura;
    FBotonAvisosReferencias.ShowHint := True;
    FBotonAvisosReferencias.Colors.Normal := clInfoBk;
    FBotonAvisosReferencias.OnClick := MostrarAvisosReferencias;
    FEstiloReferenciaAusente := TcxStyle.Create(Self);
    FEstiloReferenciaAusente.Color := clInfoBk;
    FEstiloReferenciaAusente.TextColor := clInfoText;
    tvLineasFactura.Styles.OnGetContentStyle := EstiloReferenciaAusente;
  end;
end;

procedure TfrmMtoFacturasBase.PrepararVentanaReferencias;
begin
  if FVentanaReferencias = nil then
  begin
    FVentanaReferencias := TfrmModalMensajeTexto.Create(Self);
    FVentanaReferencias.PopupMode := pmExplicit;
    FVentanaReferencias.PopupParent := Self;
    FVentanaReferencias.btnCerrar.ModalResult := mrNone;
    FVentanaReferencias.btnCerrar.OnClick := CerrarAvisosReferencias;
    FVentanaReferencias.mTexto.Style.Color := clInfoBk;
    FVentanaReferencias.mTexto.Style.TextColor := clInfoText;
  end;
end;

procedure TfrmMtoFacturasBase.ActualizarVentanaReferencias;
begin
  if Assigned(FVentanaReferencias) then
  begin
    if FDetalleReferencias = '' then
      FVentanaReferencias.Hide
    else
    begin
      FVentanaReferencias.Caption := Format(STituloAvisosReferenciasFactura,
        [dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString,
         dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString]);
      if FVentanaReferencias.mTexto.Text <> FDetalleReferencias then
      begin
        FVentanaReferencias.mTexto.Text := FDetalleReferencias;
        FVentanaReferencias.mTexto.SelStart := 0;
        FVentanaReferencias.mTexto.SelLength := 0;
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.MostrarAvisosReferencias(Sender: TObject);
begin
  if FDetalleReferencias <> '' then
  begin
    PrepararVentanaReferencias;
    ActualizarVentanaReferencias;
    FVentanaReferencias.Show;
    FVentanaReferencias.BringToFront;
  end;
end;

procedure TfrmMtoFacturasBase.CerrarAvisosReferencias(Sender: TObject);
begin
  FVentanaReferencias.Close;
end;

procedure TfrmMtoFacturasBase.ActualizarReferenciasAusentes;
var
  Referencias: TReferenciasFacturaAusentes;
begin
  if (csDestroying in ComponentState) or (dmmFacturas = nil) or
     (dsTablaG.DataSet = nil) or not dsTablaG.DataSet.Active then
  begin
    FDetalleReferencias := '';
    if Assigned(FBotonAvisosReferencias) then
      FBotonAvisosReferencias.Visible := False;
    ActualizarVentanaReferencias;
    Exit;
  end;
  if dsTablaG.State in dsEditModes then
    Exit;
  PrepararAvisosReferencias;
  Referencias := Default(TReferenciasFacturaAusentes);
  if not dsTablaG.DataSet.IsEmpty then
  try
    Referencias := ConsultarReferenciasFacturaAusentes(
      dmmFacturas.unqryTablaG.Connection,
      dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString,
      dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString);
  except
    on E: Exception do
    begin
      Referencias.Mensaje := Format(SErrorConsultarReferenciasFactura,
        [E.Message]);
      RegistroLog.RegistrarError(Referencias.Mensaje);
    end;
  end;
  FDetalleReferencias := Referencias.Mensaje;
  FBotonAvisosReferencias.Visible := FDetalleReferencias <> '';
  ActualizarVentanaReferencias;
  btnCODIGO_CLIENTE.Style.Color := FColorCliente;
  cbbFORMAPAGO.Style.Color := FColorFormaPago;
  cbbAlmacenFactura.Style.Color := FColorAlmacen;
  btnCODIGO_CLIENTE.Style.TextColor := FTextoCliente;
  cbbFORMAPAGO.Style.TextColor := FTextoFormaPago;
  cbbAlmacenFactura.Style.TextColor := FTextoAlmacen;
  // Restaurar la herencia del skin, no fijar el color efectivo anterior.
  btnCODIGO_CLIENTE.Style.AssignedValues := FAsignadosCliente;
  cbbFORMAPAGO.Style.AssignedValues := FAsignadosFormaPago;
  cbbAlmacenFactura.Style.AssignedValues := FAsignadosAlmacen;
  if Referencias.Cliente then
  begin
    btnCODIGO_CLIENTE.Style.Color := clInfoBk;
    btnCODIGO_CLIENTE.Style.TextColor := clInfoText;
  end;
  if Referencias.FormaPago then
  begin
    cbbFORMAPAGO.Style.Color := clInfoBk;
    cbbFORMAPAGO.Style.TextColor := clInfoText;
  end;
  if Referencias.Almacen then
  begin
    cbbAlmacenFactura.Style.Color := clInfoBk;
    cbbAlmacenFactura.Style.TextColor := clInfoText;
  end;
  FArticulosAusentes := Referencias.Articulos;
  FSkusAusentes := Referencias.Skus;
  cxgrdLineasFactura.Invalidate;
end;

procedure TfrmMtoFacturasBase.EstiloReferenciaAusente(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  Columna: TcxGridDBColumn;
  Codigo: string;
begin
  if (ARecord = nil) or not (ARecord is TcxGridDataRow) then
    Exit;
  Columna := tvLineasFactura.GetColumnByFieldName('CODIGO_ART_FACLIN');
  if Columna <> nil then
    for Codigo in FArticulosAusentes do
      if VarToStr(ARecord.Values[Columna.Index]) = Codigo then
        AStyle := FEstiloReferenciaAusente;
  Columna := tvLineasFactura.GetColumnByFieldName('CODIGO_UNIDAD_FACLIN');
  if Columna <> nil then
    for Codigo in FSkusAusentes do
      if VarToStr(ARecord.Values[Columna.Index]) = Codigo then
        AStyle := FEstiloReferenciaAusente;
end;

// FZ-ISSUE-131: botón «AEAT» junto al NIF de Datos Cliente; firma con
// el certificado de la empresa emisora de la factura.
procedure TfrmMtoFacturasBase.InstalarVerificacionNif;
var
  Contexto: TContextoVerificacionNifVcl;
begin
  if not Assigned(FVerificacionNif) then
  begin
    Contexto := Default(TContextoVerificacionNifVcl);
    Contexto.EditorNif := txtNIF_CLIENTE_FACTURA;
    Contexto.DataSource := dsTablaG;
    Contexto.CampoNif := 'NIF_CLIENTE_FAC';
    Contexto.CampoNombre := 'RAZON_SOCIAL_CLIENTE_FAC';
    Contexto.CampoCliente := 'CODIGO_CLI_FAC';
    Contexto.CampoEmpresa := 'CODIGO_EMP_FAC';
    Contexto.EmpresaDefecto :=
      function: string
      begin
        Result := UbicacionSesion.Empresa;
      end;
    Contexto.Conexion := ConexionPrincipal;
    Contexto.Url := ParametrosApp.GetString('appVerificacionNifUrl',
      cUrlVerificacionNifAeat);
    // Facturas intracomunitarias: «ROI» (VIES) en lugar de «AEAT».
    Contexto.CampoIntracomunitario := 'ESINTRACOMUNITARIO_CLIENTE_FAC';
    Contexto.CampoPais := 'CODIGO_PAI_CLIENTE_FAC';
    Contexto.UrlRoi := ParametrosApp.GetString('appVerificacionRoiUrl',
      cUrlVerificacionNifRoi);
    FVerificacionNif := InstalarVerificacionNifVcl(Self, Contexto);
  end;
end;
function TfrmMtoFacturasBase.NombreVistaListado: string;
begin
  Result := 'vi_facturas';
end;
procedure TfrmMtoFacturasBase.btnVolverBorradorClick(Sender: TObject);
var
  sSerie: string;
  sNumero: string;
  Validacion: TResultadoOperacionFactura;
begin
  // Deshace un lanzamiento que la AEAT aún NO ha aceptado (p. ej. NIF
  // erróneo detectado tras Consolidar): aparca la fila ALTA de la cola
  // y devuelve la factura a BORRADOR para poder corregirla y relanzar.
  // Si el alta ya fue aceptada no hay vuelta atrás: el registro existe
  // en la AEAT y solo cabe Anular o Rectificar.
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage_fza(SErrorBorradorListaNoSeleccionado);
    Abort;
  end;
  sSerie  := dsTablaG.DataSet.FieldByName(fseriefac).AsString;
  sNumero := dsTablaG.DataSet.FieldByName(fnrofac).AsString;
  Validacion := FDependenciasInyeccion.Reapertura.Validar(
    sSerie,
    sNumero);
  if not Validacion.Exito then
    ShowMessage_fza(Validacion.Mensaje)
  else if MessageDlg_fza(FormatearMensajeDocumentos(
    CrearFormatoDocumentoLecturas(ConexionPrincipal)
    .LeerFormatoFactura(sSerie, sNumero),
    SPreguntaDevolverBorrador, [sSerie, sNumero]),
                     mtConfirmation, [mbYes, mbNo], 0) =
          mrYes then
  begin
    try
      FDependenciasInyeccion.Reapertura.Reabrir(
        sSerie,
        sNumero,
        IdentidadSesion.Usuario);
      dsTablaG.DataSet.Refresh;
      ShowMessage_fza(FormatearMensajeDocumentos(
        CrearFormatoDocumentoLecturas(ConexionPrincipal)
        .LeerFormatoFactura(sSerie, sNumero),
        SInfoBorradorReabierto, [sSerie, sNumero]));
    except
      on E: EReaperturaBorrador do
        ShowMessage_fza(E.Message);
    end;
  end;
end;
procedure TfrmMtoFacturasBase.btnIrAVerifactuClick(Sender: TObject);
var
  oConsolidacion: TDataSet;
  sUrl: string;
begin
  sUrl := '';
  if Assigned(dmmFacturas) and
     Assigned(dmmFacturas.unqryConsolidacion) and
     dmmFacturas.unqryConsolidacion.Active and
     (not dmmFacturas.unqryConsolidacion.IsEmpty) then
  begin
    oConsolidacion := dmmFacturas.unqryConsolidacion;
    sUrl := Trim(
      oConsolidacion.FieldByName('VERIFACTU_URL_FACCON').AsString);
  end;
  // Se abre en una ventana interna (WebView2): muchos puestos no
  // tienen permitido el navegador. Solo direcciones web.
  if (sUrl <> '') and
     (StartsText('http://', sUrl) or StartsText('https://', sUrl)) then
    TfrmModalAyudaWeb.Ejecutar(Self,
      StripHotKey(btnIrAVerifactu.Caption), sUrl)
  else
    MessageDlg_fza(
      SInfoVerifactuUrlNoDisponible, mtInformation, [mbOk], 0);
end;

procedure TfrmMtoFacturasBase.btnVerifactuAnularClick(Sender: TObject);
begin
  // Anulación fiscal de la factura activa según modo Verifactu.
  if Assigned(FDependencias.OperacionFiscal) then
    FDependencias.OperacionFiscal.Ejecutar(
      CrearContextoOperacionFiscalFacturaVcl(
        Self,
        'ANULACION',
        'Anulación'));
end;
procedure TfrmMtoFacturasBase.btnVerifactuResolverIncidenciaClick(
  Sender: TObject);
var
  Correccion: TCorreccionRechazoAeatVcl;
begin
  Correccion := Default(TCorreccionRechazoAeatVcl);
  Correccion.Reapertura := FDependenciasInyeccion.Reapertura;
  Correccion.Usuario := IdentidadSesion.Usuario;
  Correccion.IrADatosCliente :=
    procedure
    begin
      pcCab.ActivePage := tsDatosCliente;
    end;
  ResolverIncidenciaVerifactuVcl(
    Self,
    btnVerifactuResolverIncidencia,
    dsTablaG.DataSet,
    FDependenciasInyeccion.IncidenciaFiscal,
    Correccion);
end;
procedure TfrmMtoFacturasBase.ActualizarBotonesSubsanacion;
begin
  ActualizarBotonesSubsanacionVcl(
    btnVerifactuSubsanar,
    btnVerifactuCancelarSubsanacion,
    TipoFacturaFiltro,
    dsTablaG.DataSet,
    ParametrosApp);
  // Mientras se subsana no cabe otra corrección del registro: la
  // incidencia se resuelve al registrar la subsanación.
  if btnVerifactuCancelarSubsanacion.Visible then
    btnVerifactuResolverIncidencia.Visible := False;
end;
function TfrmMtoFacturasBase.CrearContextoSubsanacion:
  TContextoSubsanacionFacturaVcl;
begin
  Result := Default(TContextoSubsanacionFacturaVcl);
  Result.Propietario := Self;
  Result.Cabecera := dsTablaG.DataSet;
  Result.Servicio := FDependenciasInyeccion.Subsanacion;
  Result.ParametrosApp := ParametrosApp;
  Result.RegistroLog := RegistroLog;
  Result.GuardarPendiente :=
    procedure
    begin
      GuardarCambiosFactura;
    end;
  Result.DescartarPendiente :=
    procedure
    begin
      if dmmFacturas.dsLinFac.DataSet.State in dsEditModes then
        dmmFacturas.dsLinFac.DataSet.Cancel;
      if dmmFacturas.unqryTablaG.State in dsEditModes then
        dmmFacturas.unqryTablaG.Cancel;
    end;
end;
procedure TfrmMtoFacturasBase.AplicarBloqueoSubsanacion(
  ASubsanando: Boolean);
begin
  // El registro de subsanación conserva la identidad de la factura
  // (número, fecha de expedición y emisor) y, como en Caja, sólo admite
  // corregir los datos del cliente y las cantidades y precios de las
  // líneas. El resto de la cabecera se bloquea aquí (el data module lo
  // vuelve a comprobar al grabar) y las columnas de las líneas las
  // filtra el presentador al entrar en edición.
  dteFECHA_FACTURA.Properties.ReadOnly := ASubsanando;
  btnCODIGO_EMPRESA_FACTURA.Properties.ReadOnly := ASubsanando;
  btnUpdateEmpresa.Enabled := not ASubsanando;
  cbbFORMAPAGO.Properties.ReadOnly := ASubsanando;
  cbbTipoOperVerifactu.Properties.ReadOnly := ASubsanando;
  mmodbComentarios.Properties.ReadOnly := ASubsanando;
  chkMueveStock.Properties.ReadOnly := ASubsanando;
  chkESVENTA_ACTIVO_FIJO_FACTURA.Properties.ReadOnly := ASubsanando;
  chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA.Properties.ReadOnly := ASubsanando;
end;
procedure TfrmMtoFacturasBase.btnVerifactuSubsanarClick(Sender: TObject);
begin
  SubsanarFacturaVcl(CrearContextoSubsanacion);
end;
procedure TfrmMtoFacturasBase.btnVerifactuCancelarSubsanacionClick(
  Sender: TObject);
begin
  CancelarSubsanacionFacturaVcl(CrearContextoSubsanacion);
end;
procedure TfrmMtoFacturasBase.btnVerifactuFacturarClick(Sender: TObject);
begin
  FacturarTicketVcl(Self, dsTablaG.DataSet, ParametrosApp);
end;
function TfrmMtoFacturasBase.TipoFacturaFiltro: string;
begin
  Result := '';
end;
function TfrmMtoFacturasBase.AbrirListadoAlCrear: Boolean;
begin
  Result := True;
end;
procedure TfrmMtoFacturasBase.AplicarEtiquetas;
begin
  inherited;
  // Corrige también los perfiles que guardaron el nombre técnico del país.
  dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FACTURA.Caption :=
    SCaptionPaisClienteBorrador;
  // inherited -> PonerAnchosTitulos repuso la visibilidad de las columnas
  // desde el perfil (por defecto visibles). Reimponemos nuestras reglas.
  if Assigned(FPresentadorLineas) then
    FPresentadorLineas.ReaplicarVisibilidad;
  AplicarOrigenCobrosFacturaVcl(Self);
  // La traducción repone los títulos del DFM (&4_Otros...).
  NumerarPestanasAtajo(pcDetail);
end;
procedure TfrmMtoFacturasBase.chkDescripcion_ampliadaPropertiesChange(
  Sender: TObject);
var
  PropiedadesMemo: TcxMemoProperties;
begin
  inherited;
  if chkDescripcion_ampliada.Checked then
  begin
    ctbDESCRIPCION_ARTICULO_FACTURA_LINEA.PropertiesClassName :=
      'TcxMemoProperties';
    PropiedadesMemo := TcxMemoProperties(
      ctbDESCRIPCION_ARTICULO_FACTURA_LINEA.Properties);
    PropiedadesMemo.VisibleLineCount := 3;
    PropiedadesMemo.MaxLength := 1000;
    PropiedadesMemo.ScrollBars := ssBoth;
  end
  else
    ctbDESCRIPCION_ARTICULO_FACTURA_LINEA.PropertiesClassName :=
      'TcxTextEditProperties';
end;
procedure TfrmMtoFacturasBase.
                   chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange(
  Sender: TObject);
var
  bReagp: Boolean;
begin
  inherited;
  if chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA.Checked = True then
  begin
    // Sin REAGP en la instalación (appUsarReagp) no se enseñan nunca.
    bReagp := ReagpEnUso(ParametrosApp);
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA.Visible := bReagp;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA.Visible := bReagp;
    //dsTablaG.DataSet.FieldByName(
    //                      'ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString := 'S';
    chkESVENTA_ACTIVO_FIJO_FACTURA.Visible := bReagp;
  end
  else
  begin
    chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA.Visible := False;
    chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA.Visible := False;
    chkESVENTA_ACTIVO_FIJO_FACTURA.Visible := False;
  end;
end;

procedure TfrmMtoFacturasBase.chkFechaEntregaPropertiesChange(Sender: TObject);
begin
  inherited;
  if (chkFechaEntrega.Checked = True) then
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := True
  else
    ctbFECHA_ENTREGA_FACTURA_LINEA.Visible := False;
end;

procedure TfrmMtoFacturasBase.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if Assigned(FPresentadorCabecera) then
    FPresentadorCabecera.AplicarEstadoDatos;
end;

procedure TfrmMtoFacturasBase.ActualizarDesgloseRecargo;
begin
  MostrarRecargoDocumento(dsTablaG.DataSet, 'FAC',
    [lblTotRE, PorRE,
     spnPORCENTAJE_REN_FAC, curTOTAL_REN_FAC,
     spnPORCENTAJE_RER_FAC, curTOTAL_RER_FAC,
     spnPORCENTAJE_RES_FAC, curTOTAL_RES_FAC,
     spnPORCENTAJE_REE_FAC, curTOTAL_REE_FAC]);
end;

procedure TfrmMtoFacturasBase.dsTablaGDataChange(Sender: TObject;
                                                 Field: TField);
var
  Situacion: TSituacionModoEntradaFactura;
begin
  ActualizarDesgloseRecargo;
  if Assigned(FPresentadorCabecera) then
    FPresentadorCabecera.RefrescarAlmacenes(Field);
  // Field = nil: cambio de registro (scroll) o refresco completo.
  if (Field = nil) and Assigned(FPresentadorCabecera) and
     Assigned(FPresentadorLineas) then
  begin
    FPresentadorCabecera.ActualizarBloqueoEdicion;
    ActualizarBotonResolverIncidenciaVcl(
      btnVerifactuResolverIncidencia,
      TipoFacturaFiltro,
      dmmFacturas.unqryConsolidacion,
      dsTablaG.DataSet);
    ActualizarReferenciasAusentes;
    ActualizarBotonesSubsanacion;
    // Cada factura lleva sus propias lineas y su propio total de
    // prendas: se re-evaluan al navegar.
    FPresentadorLineas.ReaplicarVisibilidad;
    FPresentadorLineas.ActualizarTotalPrendas;
    // Contrato de entrada: al navegar de factura las lineas llegan
    // recargadas por el master-detail. Se reconstruye si el modo tallas
    // debe re-pivotar; en desglose basta desempaquetar SKU->ATTR.
    if (not FConstruyendoModo) and
       Assigned(dmmFacturas) and dmmFacturas.unqryLinFac.Active and
       (not (dsTablaG.State in dsEditModes)) then
    begin
      Situacion := Default(TSituacionModoEntradaFactura);
      Situacion.Construido := FColsModoConstruido;
      Situacion.ContratoActivo := FModoEntrada <> nil;
      Situacion.ModoTallas := FModoEntradaSel = mcsTallasHorPed;
      Situacion.ModoSku := FModoEntradaSel = mcsSku;
      case DecidirModoEntradaFactura(Situacion) of
        dmefConstruir:
          ConstruirModoEntrada;
        dmefDesempaquetar:
          dmmFacturas.DesempaquetarAtributosLineas;
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.dteFECHA_FACTURAKeyUp(Sender: TObject;
                                                     var Key: Word;
                                                     Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_DOWN) and (Shift = [ssShift])) then
    dteFECHA_FACTURA.DroppedDown := True;
end;

procedure TfrmMtoFacturasBase.dteFECHA_FACTURAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  NewValue : Variant;
begin
  inherited;
  // OnEditValueChanged y no OnChange: OnChange saltaba con cada tecla y
  // grababa la fecha a medio escribir (02/1 -> 1900), que el editor
  // enlazado volvía a pintar; también cerraba el calendario al cambiar
  // de mes.
  if Assigned(dsTablaG.DataSet) then
  if ((dsTablaG.DataSet.State = dsInsert) or
      (dsTablaG.DataSet.State = dsEdit)
     ) then
  begin
    e := Sender as TcxCustomEdit;
    NewValue := e.EditValue;
    if (NewValue <> null) then
    begin
      dmmFacturas.unqryTablaG.FindField('FECHA_FAC').AsDateTime :=
                                                      VarToDateTime(NewValue);
      FPresentadorCabecera.CambiarIVA;
      dmmFacturas.CalcularRetencionesEmpresa;
      if (dsTablaG.DataSet.State = dsInsert) then
        FPresentadorCabecera.ActualizarComboSeries;
    end;
  end;
end;

procedure TfrmMtoFacturasBase.btnIrAClienteClick(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Clientes',
    cxGrdDBTabPrin.DataController.DataSet,
    'CODIGO_CLI_FAC');
end;

procedure TfrmMtoFacturasBase.btnIrAEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Empresas',
    cxGrdDBTabPrin.DataController.DataSet,
    'CODIGO_EMP_FAC');
end;

procedure TfrmMtoFacturasBase.
                cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  FPresentadorLineas.BuscarArticuloLinea;
end;

procedure TfrmMtoFacturasBase.
           cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  FPresentadorLineas.AplicarArticuloDesdeEditor(Sender);
end;

procedure TfrmMtoFacturasBase.sbGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FDependenciasInyeccion.Lineas.Articulos.Validador,
    dmmFacturas.unqryLinFac, 'FACLIN');
  if (sLineasSinSku = '') or
     (MessageDlg_fza(Format(SPreguntaGrabarFacturaVentaSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    GuardarCambiosFactura;
    if dmmFacturas.dsRecibos.DataSet.Active then
      dmmFacturas.dsRecibos.DataSet.Refresh;
  end;
end;

procedure TfrmMtoFacturasBase.tvLineasFacturaKeyDown(Sender: TObject;
                                                 var Key: Word;
                                                 Shift: TShiftState);
var
  bInsertar: Boolean;
begin
  inherited;
  // Defensa: el editor inplace del cxGrid puede llegar sin Parent durante
  // transiciones de celda; tocar Insert/Post sobre el datacontroller puede
  // disparar EInvalidOperation "no tiene ventana principal" via refresh de
  // controles ligados. Mismo patron que en inMtoCajaOpe.
  try
    // Antes de insertar nueva línea, asegurar que la cabecera está grabada
    if (Key = VK_RETURN) and (Shift <> [ssCtrl]) and
       (dmmFacturas.dsLinFac.DataSet.RecordCount = 0) then
    begin
      bInsertar := True;
      if dmmFacturas.unqryTablaG.State in [dsInsert, dsEdit] then
      begin
        try
          dmmFacturas.unqryTablaG.Post;
        except
          on E: Exception do
          begin
            ShowMessage_fza(Format(SErrorCompletarDatosBorrador, [E.Message]));
            bInsertar := False;
          end;
        end;
      end;
      if bInsertar then
        tvLineasFactura.DataController.Insert;
    end;
  except
    on E: EInvalidOperation do
      // Solo el caso del editor inplace sin Parent; queda en el log.
      RegistroLog.RegistrarAviso(
        'FacturasBase.tvLineasFacturaKeyDown: EInvalidOperation ' +
        'ignorada: ' + E.Message);
  end;
end;

procedure TfrmMtoFacturasBase.cxgrdLineasFacturaEnter(Sender: TObject);
begin
  // Rejilla solo en edicion (sin busqueda incremental) y Enter de celda
  // en celda: con el EnterAsTab del formulario activo, el Enter en una
  // cantidad sacaba el foco de la rejilla y la linea se perdia.
  DesactivarEnterAsTabTemporal(Sender);
  ConfigurarEdicionExcelLineasDocumento(tvLineasFactura);
  FPresentadorLineas.AsegurarPrimeraLinea;
  // Contrato de entrada: primera construccion al entrar en el grid (las
  // lineas ya estan abiertas como detail de la factura). El teardown
  // cancela la linea vacia auto-anadida: se recrea despues.
  if not FColsModoConstruido then
  begin
    ConstruirModoEntrada;
    FPresentadorLineas.AsegurarPrimeraLinea;
  end;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoFacturasBase.cxgrdLineasFacturaExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  Editor := nil;
  if Assigned(tvLineasFactura.Controller.EditingController) and
     tvLineasFactura.Controller.EditingController.IsEditing then
    Editor := tvLineasFactura.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoFacturasBase.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_FACTURA, 0, 0);
end;

procedure TfrmMtoFacturasBase.WMRevisarEnterAsTabFactura(var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasFactura) or
      cxgrdLineasFactura.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoFacturasBase.
              tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
            tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
  tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
 cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
 cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged(
                                                               Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
                    cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange(
                                                               Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
  ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

procedure TfrmMtoFacturasBase.
                  cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresentadorLineas.Recalcular(Sender);
end;

(*-AÑADIR CAMPO EN FACTURAS
-AÑADIR EL CAMPO EN FZA_FACTURAS
-AÑADIR EN LA VISTA VI_FACTURAS
-REVISAR EL DATASET EN UNIDATAFACTURAS
-REVISAR LOS PROCEDIMIENTOS ABONAR Y DUPLICAR
-REVISAR EL AFTERINSERT PARA PONER UN VALOR POR DEFECTO*)

// ===========================================================================
// CONTRATO DE ENTRADA ColumnSKUcxGrid (Auto / SKU / Tallas horizontal + F1)
// ===========================================================================

procedure TfrmMtoFacturasBase.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoFacturaVcl(
    Key,
    Shift,
    (pcPantalla.ActivePage = tsFicha) and
    (pcDetail.ActivePage = tsLineasFactura) and
    Assigned(FPresentadorLineas),
    FDependencias.ModoEntrada,
    procedure
    begin
      ConfirmarLineaDocumento(tvLineasFactura);
    end);
  inherited;
end;

// Lector de codigo de barras a nivel de formulario: al leer, activa la
// pestana de lineas, enfoca la rejilla (su OnEnter persiste la cabecera,
// deja la primera linea y construye el modo) y da de alta la linea dejando
// otra en blanco con el editor abierto, como en caja. Mientras no hay
// modo de entrada construido aplica la entrada el editor de lineas del
// presentador.
procedure TfrmMtoFacturasBase.ConfigurarLectorDocumento;
var
  Contexto: TContextoLectorDocumento;
begin
  Contexto := Default(TContextoLectorDocumento);
  Contexto.Formulario := Self;
  Contexto.Rejilla := cxgrdLineasFactura;
  Contexto.PuedeLeer :=
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmFacturas) and
        CabeceraDocumentoDisponible(dmmFacturas.unqryTablaG);
    end;
  Contexto.PrepararAlta :=
    procedure
    begin
      pcDetail.ActivePage := tsLineasFactura;
      if cxgrdLineasFactura.CanFocus then
        cxgrdLineasFactura.SetFocus;
    end;
  Contexto.Lineas :=
    function: TDataSet
    begin
      Result := dmmFacturas.unqryLinFac;
    end;
  Contexto.CamposArticulo := ['CODIGO_ART_FACLIN', 'CODIGO_UNIDAD_FACLIN'];
  Contexto.Validador :=
    function: IArticulosValidador
    begin
      Result := FDependenciasInyeccion.Lineas.Articulos.Validador;
    end;
  Contexto.Resolver :=
    function(const ACodigo: string): Boolean
    begin
      if FModoEntrada <> nil then
        Result := FModoEntrada.ResolverEntrada(ACodigo)
      else
        Result := Assigned(FPresentadorLineas) and
          FPresentadorLineas.AplicarEntradaLectura(ACodigo);
    end;
  // F-LOTEC-016: cada lote o serie en su línea (sin acumular).
  Contexto.ResolverLinea :=
    function(const ACodigo: string): Boolean
    begin
      if FModoEntrada <> nil then
        Result := FModoEntrada.ResolverEntrada(ACodigo)
      else
        Result := Assigned(FPresentadorLineas) and
          FPresentadorLineas.AplicarEntradaLectura(ACodigo);
    end;
  Contexto.MostrarEditor :=
    procedure
    begin
      if FModoEntrada <> nil then
        FModoEntrada.MostrarEditor;
    end;
  Contexto.RegistroLog := RegistroLog;
  FLectorDocumento := TLectorDocumento.Create(Contexto);
end;

procedure TfrmMtoFacturasBase.ConfigurarTrazabilidadVenta;
var
  rDocumento: TDocumentoTrazabilidad;
begin
  // La conexión del módulo de datos: la de su transacción y bloqueos.
  rDocumento := DocumentoTrazabilidadUniDAC(Self,
    dmmFacturas.unqryTablaG.Connection as TUniConnection, ParametrosApp,
    sllSalida, TablaLineasLote('FACLIN', 'fza_facturas_lineas',
                               'SERIE_FAC_FACLIN', 'NUMERO_FAC_FACLIN'));
  if rDocumento.Activacion.AlgunModoActivo then
  begin
    rDocumento.Documento :=
      function: TDocumentoLineaLote
      begin
        Result := dmmFacturas.DocumentoLotes;
      end;
    rDocumento.Lineas :=
      function: TDataSet
      begin
        Result := dmmFacturas.unqryLinFac;
      end;
    rDocumento.Lector :=
      function: TLectorDocumento
      begin
        Result := FLectorDocumento;
      end;
    dmmFacturas.ConfigurarLotesLineas(
      ConfiguracionLotesLineasDocumento(rDocumento));
    if Assigned(FLectorDocumento) then
      FLectorDocumento.ConfigurarTrazabilidad(
        TrazabilidadLectorDocumento(rDocumento));
  end;
end;

procedure TfrmMtoFacturasBase.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  ds: TDataSet;
begin
  if (dmmFacturas <> nil) and (not (csDestroying in ComponentState)) and
     dmmFacturas.unqryLinFac.Active then
  begin
    ds := dmmFacturas.unqryLinFac;
    FConstruyendoModo := True;
    // dsLinFacStateChange (DM) y CambioEnLineas tocan columnas ctb* que
    // mueren en el ClearItems: se desenganchan durante el rebuild.
    dmmFacturas.dsLinFac.OnStateChange := nil;
    dmmFacturas.dsLinFac.OnDataChange := nil;
    try
      DesmontarModoEntradaDocumento(tvLineasFactura, ds, FModoEntrada);
      // El flag ANTES del Construir: si algo aborta a medias, nadie debe
      // tocar las columnas del dfm, muertas en el ClearItems.
      FColsModoConstruido := True;
      // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
      // (columnas reales _FACLIN; idempotente por linea).
      if FModoEntradaSel <> mcsSku then
        dmmFacturas.DesempaquetarAtributosLineas;
      Cfg := CrearConfigColumnasSkuFacturaVcl(Self, ds);
      if FModoEntradaSel = mcsTallasHorPed then
        FModoEntrada := CrearModoEntradaGridPivoteVenta(
          Cfg, CrearConfigPivoteVentaFacturaVcl(Self))
      else
        FModoEntrada := CrearModoEntradaGrid(Cfg);
      // SIEMPRE primero el bloque del modo (articulo/color/tallas o
      // SKU) y detras las columnas del documento. El pivote publica sus
      // Values[] no-bound en diferido, asi que crear las columnas del
      // host despues no los pisa.
      ConstruirModoEntradaDocumento(FModoEntrada,
        FPresentadorLineas.ModoEntradaResuelto,
        DesactivarEnterAsTabTemporal, SalirEdicionModoEntrada,
        FModoEntradaSel, [], '');
      CrearColumnasHostFactura;
      FPresentadorLineas.EnvolverEdicionModo(tvLineasFactura);
      AplicarTituloModoEntradaFacturaVcl(Self, Cfg);
    finally
      FConstruyendoModo := False;
      dmmFacturas.dsLinFac.OnDataChange := FPresentadorLineas.CambioEnLineas;
      dmmFacturas.dsLinFac.OnStateChange := dmmFacturas.dsLinFacStateChange;
    end;
    // Reglas de visibilidad e ImpIncl sobre las columnas recreadas.
    FPresentadorLineas.ReaplicarVisibilidad;
    dmmFacturas.dsLinFacStateChange(dmmFacturas.dsLinFac);
  end;
end;

procedure TfrmMtoFacturasBase.CrearColumnasHostFactura;
var
  Configuracion: TConfiguracionColumnasFactura;
begin
  Configuracion := Default(TConfiguracionColumnasFactura);
  Configuracion.Vista := tvLineasFactura;
  Configuracion.DataSourceIvas := dmmFacturas.dsIvasTipos;
  // Vendedor por línea para liquidar comisiones (venta mayor).
  if SameText(TipoFacturaFiltro, 'NORMAL') then
    Configuracion.DataSourceVendedores := dmmFacturas.dsVendedoresFac;
  Configuracion.Tallas := FModoEntradaSel = mcsTallasHorPed;
  Configuracion.Simplificada :=
    SameText(TipoFacturaFiltro, 'SIMPLIFICADA');
  Configuracion.DescripcionAmpliada := chkDescripcion_ampliada.Checked;
  Configuracion.MostrarFechaEntrega := chkFechaEntrega.Checked;
  Configuracion.UnidadesMedida := UnidadesMedida;
  AsignarColumnasFacturaVcl(Self, CrearColumnasFactura(Configuracion));
  EnlazarHandlersColumnasFacturaVcl(Self);
  // El detalle vuelve a apuntar a las columnas recien creadas.
  FPresentadorLineas.ActualizarColumnas(
    ColumnasDetalleFacturaActuales(Self));
  // F-LOTEC-016: Lote / Serie y F. caducidad, con botón al modal.
  if Assigned(ParametrosApp) then
    CrearColumnasLoteDocumento(tvLineasFactura, 'FACLIN',
      TActivacionTrazabilidad.Leer(ParametrosApp),
      procedure
      begin
        dmmFacturas.ElegirLoteLinea;
      end);
end;

procedure TfrmMtoFacturasBase.
  btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if Assigned(dsTablaG.DataSet) and
     (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := VarToStr(e.EditingValue);
    if (sCodigo <> '') and (sCodigo <> '0') then
      FPresentadorCabecera.CopiarEmpresa(sCodigo);
  end;
end;

procedure TfrmMtoFacturasBase.btnConsolidarClick(Sender: TObject);
begin
  dmmFacturas.CompletarClienteBorrador;
  // Intracomunitaria: el NIF-IVA tiene que figurar en VIES (ROI).
  if (not (FVerificacionNif is TVerificacionNifVcl)) or
     TVerificacionNifVcl(FVerificacionNif).
       ComprobarRoiAntesDeConsolidar then
    TCoordinadorConsolidacionFacturaVcl.Ejecutar(
      CrearContextoConsolidacionFacturaVcl(Self));
end;

procedure TfrmMtoFacturasBase.btnGenerarRecibosClick(Sender: TObject);
begin
  inherited;
  TCoordinadorCobrosFacturaVcl.Generar(
    CrearContextoCobrosFacturaVcl(Self));
end;

procedure TfrmMtoFacturasBase.btnReciboPagadoClick(Sender: TObject);
begin
  inherited;
  TCoordinadorCobrosFacturaVcl.MarcarCobrado(
    CrearContextoCobrosFacturaVcl(Self));
end;

procedure TfrmMtoFacturasBase.PcDetailChange(Sender: TObject);
begin
  if Assigned(dmmFacturas) then
  begin
    ActivarDetalleFacturaVcl(
      CrearContextoDetalleFacturaVcl(Self));
    ActualizarBotonResolverIncidenciaVcl(
      btnVerifactuResolverIncidencia,
      TipoFacturaFiltro,
      dmmFacturas.unqryConsolidacion,
      dsTablaG.DataSet);
    ActualizarBotonesSubsanacion;
  end;
end;

procedure TfrmMtoFacturasBase.DescuentosDocumentoCambiados(Sender: TObject);
begin
  if Assigned(dmmFacturas) then
    dmmFacturas.RecalcularDescuentosDocumento;
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasBase);
end.

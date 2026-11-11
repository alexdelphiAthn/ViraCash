{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoClientes                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de clientes.                                                }
{    CRUD sobre fza_clientes con datos fiscales y delegaciones.                }
{******************************************************************************}
unit inMtoClientes;

interface

uses
  inLibRegistroPantallas, inLibClientesCoincidencias,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  Vcl.Menus, cxContainer, dxSkinsForm, cxClasses, cxLocalization, cxDBNavigator,
  cxLabel, cxScrollBox, Vcl.StdCtrls, cxButtons, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  Vcl.ExtCtrls, UniDataConn, UniDataClientes,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, cxTextEdit, Vcl.Buttons, dxBevel,
  cxCurrencyEdit, cxCalendar, cxMaskEdit, cxDropDownEdit, cxDBEdit,
  dxGDIPlusClasses, cxImage, cxCustomListBox, cxCheckListBox, cxDBCheckListBox,
  cxCheckBox, cxMemo, inLibDevExp, cxBlobEdit, ClipBrd, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, dxScrollbarAnnotations, dxCore,
  cxSpinEdit,
  cxRadioGroup, cxGridExportLink,  System.UITypes, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, cxSplitter,
  cxDBExtLookupComboBox, cxGroupBox, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  inLibClientesPersistenciaIntf;

type
  TfrmMtoClientes = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
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
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    pcPestanas: TcxPageControl;
    tsDomicilioFiscal: TcxTabSheet;
    tsMasDatos: TcxTabSheet;
    scrDomicilioFiscal: TcxScrollBox;
    scrMasDatos: TcxScrollBox;
    tsParametrosEDoc: TcxTabSheet;
    tsHistoriaFacturacion: TcxTabSheet;
    tsPresupuestos: TcxTabSheet;
    cxgrdPresupuestos: TcxGrid;
    tvPresupuestos: TcxGridDBTableView;
    tvPresupuestosFECHA_FAC: TcxGridDBColumn;
    tvPresupuestosNUMERO_FAC: TcxGridDBColumn;
    tvPresupuestosSERIE_FAC: TcxGridDBColumn;
    tvPresupuestosCODIGO_CLI_FAC: TcxGridDBColumn;
    tvPresupuestosRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosNIF_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosMOVIL_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosEMAIL_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosDIRECCION1_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosDIRECCION2_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosPOBLACION_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosPROVINCIA_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn;
    tvPresupuestosPAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    tvPresupuestosTOTAL_LIQUIDO_FAC: TcxGridDBColumn;
    tvPresupuestosFORMA_PAGO_FAC: TcxGridDBColumn;
    tvPresupuestosCOMENTARIOS_FAC: TcxGridDBColumn;
    tvLineasPresupuesto: TcxGridDBTableView;
    tvLineasPresupuestoLINEA_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoCODIGO_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoDESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoZONA: TcxGridDBColumn;
    tvLineasPresupuestoPRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoCANTIDAD_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoSUM_TOTAL_LINEA: TcxGridDBColumn;
    tvLineasPresupuestoODONTOLOGO: TcxGridDBColumn;
    cxgrdlvlPresupuestos: TcxGridLevel;
    cxgrdlvlLineasPresupuesto: TcxGridLevel;
    tsOtros: TcxTabSheet;
    pnlUserInstantBottom: TcxGroupBox;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    txtINSTANTEMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRETENCIONES_CLIENTE: TcxGridDBColumn;
    mTEXTO_LEGAL_FACTURA_CLIENTE: TcxDBMemo;
    lblTextoLegal: TcxLabel;
    lblSerieDefault: TcxLabel;
    txtSERIE_CONTADOR: TcxDBTextEdit;
    btnNuevoCliente: TcxButton;
    cxGrdDBTabPrinESIVA_EXENTO_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_FORMA_PAGO_CLIENTE: TcxGridDBColumn;
    pnlFacturaCli: TPanel;
    cxgrdClientesFacturas: TcxGrid;
    tvFacturacion: TcxGridDBTableView;
    tvLineasFacturacion: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA:
                                                                TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn;
    tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn;
    tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlClientesFacturasMaster: TcxGridLevel;
    cxgrdlvlClientesFacturasDetail: TcxGridLevel;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    btnIraEmpresa: TcxButton;
    btnExportar: TcxButton;
    tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    tvFacturacionFECHA_FACTURA: TcxGridDBColumn;
    tvFacturacionNRO_FACTURA: TcxGridDBColumn;
    tvFacturacionSERIE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn;
    tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn;
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
    splFicha: TcxSplitter;
    lblOrdenListado: TcxLabel;
    spORDEN_CLIENTE: TcxDBSpinEdit;
    btnIraArticulo: TcxButton;
    dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxgrpbxIdentificacion: TcxGroupBox;
    lblDireccion1Texto: TcxLabel;
    txtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblDireccion2Texto: TcxLabel;
    txtDIRECCION2_CLIENTE: TcxDBTextEdit;
    lblCodPostal: TcxLabel;
    txtCPOSTAL_CLIENTE: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    txtPOBLACION_CLIENTE: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    txtPROVINCIA_CLIENTE: TcxDBTextEdit;
    lblPais: TcxLabel;
    txtPAIS_CLIENTE: TcxDBTextEdit;
    cxgrpbxTratamientoFiscal: TcxGroupBox;
    chkREGIMENAGRICOLA: TcxDBCheckBox;
    chkINTRACOMUNITARIO: TcxDBCheckBox;
    chkIVAEXENTO: TcxDBCheckBox;
    chkRECARGO_EQUIV: TcxDBCheckBox;
    chkRETENCIONES: TcxDBCheckBox;
    cxgrpbxDomicilio: TcxGroupBox;
    lblContacto: TcxLabel;
    txtCONTACTO_CLIENTE: TcxDBTextEdit;
    lblTelefonoContacto: TcxLabel;
    txtTELEFONO_CONTACTO_CLIENTE: TcxDBTextEdit;
    lblReferencia: TcxLabel;
    txtREFERENCIA_CLIENTE: TcxDBTextEdit;
    lblObservaciones: TcxLabel;
    cxdbmOBSERVACIONES_CLIENTE: TcxDBMemo;
    lblFormadePago: TcxLabel;
    cbbFORMAPAGO: TcxDBLookupComboBox;
    lblVendedorCliente: TcxLabel;
    cbbCODIGO_VENDEDOR_CLI: TcxDBLookupComboBox;
    lblBancoCobroCli: TcxLabel;
    cbbBancoCobroCli: TcxDBLookupComboBox;
    lblNroCuenta: TcxLabel;
    lblTextoLegalAlt: TcxLabel;
    cbbTARIFA: TcxDBLookupComboBox;
    txtTARIFA_ARTICULO_CLIENTE: TcxDBTextEdit;
    cxgrpbxObservaciones: TcxGroupBox;
    lblRazonSocial: TcxLabel;
    lblCodigoCliente: TcxLabel;
    txtCODIGO_CLIENTE: TcxDBTextEdit;
    txtRAZONSOCIAL_CLIENTE: TcxDBTextEdit;
    chkActivo: TcxDBCheckBox;
    lblEmail: TcxLabel;
    txtEMAIL_CLIENTE: TcxDBTextEdit;
    lblNif: TcxLabel;
    txtNIF_CLIENTE: TcxDBTextEdit;
    lblTelefonos: TcxLabel;
    txtMOVIL_CLIENTE: TcxDBTextEdit;
    txtTELEFONO_CLIENTE: TcxDBTextEdit;
    ActionListClientes: TActionList;
    actEmpresas: TAction;
    actFacturas: TAction;
    actArticulos: TAction;
    tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn;
    txtIBAN_CLIENTE: TcxDBMaskEdit;
    btnValidar: TcxButton;
    btnImprimirEtiqueta: TcxButton;
    txtNOMBRE_PAIS_CLIENTE: TcxDBTextEdit;
    cbbPaises: TcxDBLookupComboBox;
    lblExtra1: TcxLabel;
    curTOTAL_LIMITE_CREDITO_CLI: TcxDBCurrencyEdit;
    chkESPERMITE_DEUDA_CLI: TcxDBCheckBox;
    curTOTAL_DEUDA_CLI: TcxDBCurrencyEdit;
    chkESVARIOS_CLI: TcxDBCheckBox;
    lblExtra2: TcxLabel;
    cxgrpbxParametrosEDoc: TcxGroupBox;
    lblCodigoOficinaContable: TcxLabel;
    txtCODIGO_OFICINA_CONTABLE_CLIENTE: TcxDBTextEdit;
    lblCodigoOrganoGestor: TcxLabel;
    txtCODIGO_ORGANO_GESTOR_CLIENTE: TcxDBTextEdit;
    lblCodigoUnidadTramitadora: TcxLabel;
    txtCODIGO_UNIDAD_TRAMITADORA_CLIENTE: TcxDBTextEdit;
    lblNombrePersonaCliente: TcxLabel;
    txtNOMBRE_PERSONA_CLIENTE: TcxDBTextEdit;
    lblApellidosPersonaCliente: TcxLabel;
    txtAPELLIDOS_PERSONA_CLIENTE: TcxDBTextEdit;
    tsPrestamos: TcxTabSheet;
    pnlPrestamosBody: TPanel;
    cxgrdPrestamosCliente: TcxGrid;
    tvFacturasCliente: TcxGridDBTableView;
    tvFacturasClienteFECHA_FAC: TcxGridDBColumn;
    tvFacturasClienteNUMERO_FAC: TcxGridDBColumn;
    tvFacturasClienteSERIE_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_LIQUIDO_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_RETENCION_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_RETENCION_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_IMPUESTOS_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_BASES_FAC: TcxGridDBColumn;
    tvFacturasClienteFORMA_PAGO_FAC: TcxGridDBColumn;
    tvFacturasClienteDESCRIPCION_FORMA_PAGO_FP: TcxGridDBColumn;
    tvFacturasClienteCODIGO_EMP_FAC: TcxGridDBColumn;
    tvFacturasClienteRAZON_SOCIAL_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteNIF_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteMOVIL_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteEMAIL_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteDIRECCION1_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteDIRECCION2_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClientePOBLACION_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClientePROVINCIA_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClientePAIS_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturasClienteCODIGO_POSTAL_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteESRETENCIONES_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturasClienteDESCRIPCION_IVA_IVAGRP: TcxGridDBColumn;
    tvFacturasClienteESREGIMENESPECIALAGRICOLA_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteESIRPF_IMP_INCL_ZONA_IVA_FAC: TcxGridDBColumn;
    tvFacturasClienteESAPLICA_RE_ZONA_IVA_FAC: TcxGridDBColumn;
    tvFacturasClienteESIVAAGRICOLA_ZONA_IVA_FAC: TcxGridDBColumn;
    tvFacturasClientePALABRA_REPORTS_ZONA_IVA_FAC: TcxGridDBColumn;
    tvFacturasClienteESVENTA_ACTIVO_FIJO_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_IVAN_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_IVAN_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_REN_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_REN_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_BASEI_IVAN_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_IVAR_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_IVAR_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_RER_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_RER_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_BASEI_IVAR_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_IVAS_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_IVAS_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_RES_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_RES_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_BASEI_IVAS_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_IVAE_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_IVAE_FAC: TcxGridDBColumn;
    tvFacturasClientePORCENTAJE_REE_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_REE_FAC: TcxGridDBColumn;
    tvFacturasClienteTOTAL_BASEI_IVAE_FAC: TcxGridDBColumn;
    tvFacturasClienteCODIGO_CLI_FAC: TcxGridDBColumn;
    tvFacturasClienteRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteNIF_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteMOVIL_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteEMAIL_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteDIRECCION1_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteDIRECCION2_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClientePOBLACION_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClientePROVINCIA_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClientePAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturasClienteESIVA_RECARGO_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteESIVA_EXENTO_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteESREGIMENESPECIALAGRICOLA_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteESRETENCIONES_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn;
    tvFacturasClienteESIMP_INCL_TARIFA_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteESINTRACOMUNITARIO_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteGRUPO_ZONA_IVA_EMPRESA_FAC: TcxGridDBColumn;
    tvFacturasClienteTARIFA_ARTICULO_CLIENTE_FAC: TcxGridDBColumn;
    tvFacturasClienteCODIGO_IVA_FAC: TcxGridDBColumn;
    tvLineasFacturaCliente: TcxGridDBTableView;
    tvLineasFacturaClienteLINEA_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteCODIGO_ART_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteDESCRIPCION_ARTICULO_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteTIPO_CANTIDAD_ARTICULO_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteCANTIDAD_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClientePRECIO_VENTA_SIVA_ARTICULO_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteNOMBRE_TIPO_IVA_IVATIP: TcxGridDBColumn;
    tvLineasFacturaClientePORCENTAJE_IVA_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClientePRECIO_VENTA_CIVA_ARTICULO_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteTOTAL_FACLIN: TcxGridDBColumn;
    tvLineasFacturaClienteFECHA_ENTREGA_FACLIN: TcxGridDBColumn;
    pnlPrestamosBotones: TPanel;
    btnExportarExcelPrestamos: TcxButton;
    btnIrAArticuloPres: TcxButton;
    cxgrdlvlPrestamos: TcxGridLevel;
    tvDepositosCliente: TcxGridDBTableView;
    tvDepositosClienteID_DEPOSITO_DEP: TcxGridDBColumn;
    tvDepositosClienteCODIGO_EMPRESA_DEP: TcxGridDBColumn;
    tvDepositosClienteCODIGO_CLIENTE_DEP: TcxGridDBColumn;
    tvDepositosClienteCODIGO_ARTICULO_DEP: TcxGridDBColumn;
    tvDepositosClienteCODIGO_UNIDAD_DEP: TcxGridDBColumn;
    tvDepositosClientePRECIO_VENTA_DEP: TcxGridDBColumn;
    tvDepositosClienteIMPORTE_ANTICIPO_DEP: TcxGridDBColumn;
    tvDepositosClienteESTADO_DEP: TcxGridDBColumn;
    tvDepositosClienteFECHA_CREACION_DEP: TcxGridDBColumn;
    tvDepositosClienteINSTANTEMODIF: TcxGridDBColumn;
    tvDepositosClienteINSTANTEALTA: TcxGridDBColumn;
    tvDepositosClienteUSUARIOALTA: TcxGridDBColumn;
    tvDepositosClienteUSUARIOMODIF: TcxGridDBColumn;
    tvDepositosClienteTIPO_IVA_DEP: TcxGridDBColumn;
    tvDepositosClientePORCEN_IVA_DEP: TcxGridDBColumn;
    tvDepositosClienteESIMP_INCL_DEP: TcxGridDBColumn;
    tvDepositosClienteCANTIDAD_PENDIENTE_DEP: TcxGridDBColumn;
    tvDepositosClienteFECHA_ENTREGA_DEP: TcxGridDBColumn;
    tvDepositosClienteDESCRIPCION_ARTICULO: TcxGridDBColumn;
    procedure btnNuevoClienteClick(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnIraEmpresaClick(Sender: TObject);
    procedure actEmpresasExecute(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
//    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnValidarClick(Sender: TObject);
    procedure blbEtiquetaClick(Sender: TObject);
    procedure txtNOMBRE_PAIS_CLIENTEPropertiesChange(Sender: TObject);
    procedure btnIrAArticuloPresClick(Sender: TObject);
    procedure cxButton4Click(Sender: TObject);
    // Carga perezosa de sub-pestañas detail (Historia, Prestamos).
    procedure PcPestanasChange(Sender: TObject);
    procedure CasillaFiscalMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DesplazarFichaMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    FDmmClientes: TDMClientes;
    FRepositorioClientes: IRepositorioClientes;
    FVerificacionNif: TComponent;
    FCoincidenciaAbrir: string;
    FTabMedidas: TcxTabSheet;
    procedure CrearAccesoMedidas;
    procedure MedidasClienteClick(Sender: TObject);
    function ConfirmarCoincidenciasCliente(
      const ACandidatos: TCandidatosCliente;
      out AMotivo: string): Boolean;
    procedure ElegirCoincidenciaCliente(
      const ACandidatos: TCandidatosCliente);
    procedure AbrirCoincidenciaCliente(var AMensaje: TMessage);
      message WM_APP + $752;
    procedure InstalarVerificacionNif;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    function  NombreCampoESACTIVO: string; override;
    function  ContarHijosActivos: Integer; override;
    function  DescripcionHijos: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgMedidasCliente, inMtoModalMedidasCliente,
  inLibComboPais,
  inLibWin,
  inLibUser,
  inLibShowMto,
  inLibFotos,
  inMtoModalCliEti,
  inLibDir,
  inLibIBAN,
  inLibMsgVentas,
  inLibPermisosIntf,
  inLibVentasPantallaIntf,
  inLibVerificacionNifAeat,
  inMtoVerificacionNifVcl,
  UniDataDestinoFacturaRepositorio,
  UniDataVentasPantallaComposicion;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoClientes.DesplazarFichaMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
var
  oDesplazamiento: TcxScrollBox;
begin
  if Sender is TcxScrollBox then
  begin
    oDesplazamiento := TcxScrollBox(Sender);
    Handled := oDesplazamiento.VertScrollBar.Range >
      oDesplazamiento.ClientHeight;
    if Handled then
      oDesplazamiento.VertScrollBar.Position :=
        oDesplazamiento.VertScrollBar.Position -
        MulDiv(MulDiv(48, CurrentPPI, 96), WheelDelta, WHEEL_DELTA);
  end;
end;

// El cliente tiene articulo en dos pestanas: la historia de facturacion
// (tsHistoriaFacturacion / tvLineasFacturacion, CODIGO_ART_FACLIN) y los
// depositos (tsPrestamos / tvDepositosCliente, CODIGO_ART_DEP). Manda la
// rejilla de la pestana visible.
procedure TfrmMtoClientes.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  ds := nil;
  if pcPestanas.ActivePage = tsHistoriaFacturacion then
  begin
    if Assigned(tvLineasFacturacion.DataController.DataSource) then
      ds := tvLineasFacturacion.DataController.DataSource.DataSet;
  end
  else if pcPestanas.ActivePage = tsPrestamos then
  begin
    if Assigned(tvDepositosCliente.DataController.DataSource) then
      ds := tvDepositosCliente.DataController.DataSource.DataSet;
  end;
  if ds <> nil then
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
end;

function TfrmMtoClientes.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(FDmmClientes) then
    Result := [dsTablaG, FDmmClientes.dsFacturasLineasClientes,
               FDmmClientes.dsDepositos]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoClientes.actArticulosExecute(Sender: TObject);
begin
  inherited;
  //Control + A
  if (pcPestanas.ActivePage = tsHistoriaFacturacion) then
    btnIraArticuloClick(Sender)
  else
    if  (pcPestanas.ActivePage = tsPrestamos) then
      btnIrAArticuloPresClick(Sender)
    else
      ShowMto(Self.Owner,
              'Articulos' );
end;

procedure TfrmMtoClientes.actEmpresasExecute(Sender: TObject);
begin
  // Ctrl+Alt+E -> Empresas.
  inherited;
    if (
        (pcPestanas.ActivePage = tsHistoriaFacturacion)) then
      btnIraEmpresaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Empresas');
end;

procedure TfrmMtoClientes.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F
  if (
        (pcPestanas.ActivePage = tsHistoriaFacturacion)) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoClientes.blbEtiquetaClick(Sender: TObject);
var
  formulario : TfrmPrintCliEti;
begin
  inherited;
  if PuedeImprimir then
  begin
    formulario := TfrmPrintCliEti.Create(Application);
    try
      formulario.Preparar(FDmmClientes);
      formulario.edtCodCli.Text :=
        dsTablaG.Dataset.FieldByName('CODIGO_CLI_CLI').AsString;
      formulario.ShowModal;
    finally
      FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoClientes.btnExportarClick(Sender: TObject);
begin
  if PuedeAccionMto(apmExcel) then
    ExportarExcel(
      ParametrosApp,
      cxgrdClientesFacturas,
      'Historico_Borradores_Cliente_' +
      dsTablaG.Dataset.FieldByName('CODIGO_CLI_CLI').AsString);
end;

procedure TfrmMtoClientes.btnIraEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          tvFacturacion.DataController.DataSet.FieldByName(
                                            'CODIGO_EMP_FAC').AsString);
end;

procedure TfrmMtoClientes.btnIraFacturaClick(Sender: TObject);
var
  sNroFactura, sSerieFactura:String;
begin
  inherited;
  sNroFactura := tvFacturacion.DataController.DataSet.FieldByName(
                                                        'NUMERO_FAC').AsString;
  sSerieFactura := tvFacturacion.DataController.DataSet.FieldByName(
                                                      'SERIE_FAC').AsString;
  ShowMto(Self.Owner,
          ResolverCallFactura(
            CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
            sNroFactura,
            sSerieFactura),
          sNroFactura + ',' + sSerieFactura);
end;

procedure TfrmMtoClientes.btnIraArticuloClick(Sender: TObject);
var
  sCodArt: string;
  vw: TcxCustomGridView;
  dbView: TcxGridDBTableView;
  col: TcxGridDBColumn;
begin
  inherited;
  sCodArt := '';
  vw := cxgrdClientesFacturas.FocusedView;
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

procedure TfrmMtoClientes.btnNuevoClienteClick(Sender: TObject);
begin
  inherited;
  if PuedeAccionMto(apmInsertar) then
  begin
    if ((FDmmClientes.unqryTablaG.State = dsInsert) or
        (FDmmClientes.unqryTablaG.State = dsEdit)) then
    begin
      FDmmClientes.unqryTablaG.Post;
    end;
    FDmmClientes.unqryTablaG.Insert;
    pcPantalla.Properties.ActivePage := tsFicha;
    tsFicha.SetFocus;
    pcPestanas.Properties.ActivePage := tsDomicilioFiscal;
    tsDomicilioFiscal.SetFocus;
    txtRAZONSOCIAL_CLIENTE.SetFocus;
  end;
end;

procedure TfrmMtoClientes.btnValidarClick(Sender: TObject);
var
  sIBAN, sPref, sPref4:String;
  iLen:Integer;
  sErr:String;
  EsIBANErr:boolean;
  stErr:TStringList;
begin
  inherited;
  EsIBANErr := False;
  stErr := TStringList.Create;
  try
    sIBAN := StringReplace(dsTablaG.DataSet.FieldByName('IBAN_CLI').Text,
                           ' ', '', [rfReplaceAll]);
    iLen := Length(sIBAN);
    sPref := (Copy(sIBAN, 1, 2));
    if ((sPref = 'ES') or (iLen = 20)) then
    begin
      TIBAN.ValidarCCC(sIBAN, stErr);
      sErr := stErr.Text;
      if (sErr <> '') then
      begin
        ShowMessage_fza(sErr);
        EsIBANErr := True;
      end;
    end;
    if ((iLen = 20) and
        (StrToIntDef(sPref, 0) <> 0) and
        not(EsIBANErr)) then
    begin
      sPref4 := TIBAN.GenerarIBAN('ES', sIBAN);
      if (dsTablaG.State = dsBrowse) then
        dsTablaG.DataSet.Edit;
      dsTablaG.DataSet.FieldByName('IBAN_CLI').Text := sPref4 + sIBAN;
    end;
    if (not(EsIBANErr) and (StrToIntDef(sPref, 0) = 0)) then
    begin
      TIBAN.ValidarIBAN(sIBAN, stErr);
      sErr := stErr.Text;
      if (sErr <> '') then
      begin
        ShowMessage_fza(sErr);
        EsIBANErr := True;
      end;
    end;
    if not(EsIBANErr) then
      ShowMessage_fza(SInfoIbanValidado);
  finally
    FreeAndNil(stErr);
  end;
end;

procedure TfrmMtoClientes.CrearTablaPrincipal;
var
  oContexto: TContextoClientesVentasPantalla;
begin
  inherited;
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FRepositorioClientes := oContexto.Repositorio;
  FDmmClientes := tdmDataModule as TdmClientes;
  FDmmClientes.ConfirmarCoincidencias := ConfirmarCoincidenciasCliente;
  tvFacturacion.DataController.DataSource := FDmmClientes.dsFacturasClientes;
  tvLineasFacturacion.DataController.DataSource :=
    FDmmClientes.dsFacturasLineasClientes;
  tvDepositosCliente.DataController.DataSource := FDmmClientes.dsDepositos;
  cbbFORMAPAGO.Properties.ListSource := FDmmClientes.dsFormasPago;
  cbbCODIGO_VENDEDOR_CLI.Properties.ListSource := FDmmClientes.dsVendedores;
  cbbBancoCobroCli.Properties.ListSource := FDmmClientes.dsEmpresasBancos;
  cbbTARIFA.Properties.ListSource := FDmmClientes.dsTarifas;
  cbbPaises.Properties.ListSource := FDmmClientes.dsPaises;
  ConfigurarComboPaisNumerico(cbbPaises);
  pcPestanas.ActivePage := tsDomicilioFiscal;
  Self.pkFieldName := 'CODIGO_CLI_CLI';
  // Carga perezosa de sub-pestañas detail (default = tsDomicilioFiscal,// que
  // no usa query detail). Historia/Depositos se abren solo cuando
  // el usuario activa su pestaña.
  pcPestanas.OnChange := PcPestanasChange;
  btnNuevoCliente.Enabled := PuedeAccionMto(apmInsertar);
  btnExportar.Visible := PuedeAccionMto(apmExcel);
  btnExportarExcelPrestamos.Visible := PuedeAccionMto(apmExcel);
  btnImprimirEtiqueta.Visible := PuedeImprimir;
  InstalarVerificacionNif;
  CrearAccesoMedidas;
end;

procedure TfrmMtoClientes.CrearAccesoMedidas;
var
  oBoton: TcxButton;
begin
  if FTabMedidas = nil then
  begin
    FTabMedidas := TcxTabSheet.Create(Self);
    FTabMedidas.PageControl := pcPestanas;
    FTabMedidas.Caption := SMedidasTitulo;
    oBoton := TcxButton.Create(Self);
    oBoton.Parent := FTabMedidas;
    oBoton.Align := alTop;
    oBoton.Height := ScaleValue(44);
    oBoton.Caption := SMedidasTitulo;
    oBoton.OnClick := MedidasClienteClick;
  end;
  tsOtros.PageIndex := pcPestanas.PageCount - 1;
  NumerarPestanasAtajo(pcPestanas);
end;

procedure TfrmMtoClientes.MedidasClienteClick(Sender: TObject);
begin
  FDmmClientes.unqryTablaG.CheckBrowseMode;
  TfrmModalMedidasCliente.Ejecutar(Self,
    FDmmClientes.unqryTablaG.FieldByName('CODIGO_CLI_CLI').AsString);
end;

// FZ-ISSUE-131: botón «AEAT» junto al NIF; firma con el certificado de
// la empresa de la sesión.
function TfrmMtoClientes.ConfirmarCoincidenciasCliente(
  const ACandidatos: TCandidatosCliente;
  out AMotivo: string): Boolean;
var
  sResumen, sClase: string;
  iIndice, iRespuesta: Integer;
begin
  Result := False;
  AMotivo := '';
  sResumen := Format(SResumenCoincidenciasCliente,
    [Length(ACandidatos)]) + sLineBreak;
  for iIndice := 0 to Length(ACandidatos) - 1 do
    if iIndice < 20 then
    begin
      sClase := SContactoCoincidenteCliente;
      if ACandidatos[iIndice].MismoNif then
        sClase := SIdentificacionCoincidenteCliente;
      sResumen := sResumen + sLineBreak +
        ACandidatos[iIndice].Codigo + ' - ' +
        ACandidatos[iIndice].Nombre + ' (' + sClase + ')';
    end;
  iRespuesta := MessageDlg_fza(sResumen + sLineBreak + sLineBreak +
    SPreguntaCoincidenciasCliente, mtWarning, [mbYes, mbNo, mbCancel],
    0, mbCancel);
  if iRespuesta = mrYes then
    Result := InputQuery_fza(STituloCoincidenciasCliente,
      SPreguntaMotivoCoincidenciasCliente, AMotivo)
  else if iRespuesta = mrNo then
    ElegirCoincidenciaCliente(ACandidatos);
end;

procedure TfrmMtoClientes.ElegirCoincidenciaCliente(
  const ACandidatos: TCandidatosCliente);
var
  sCodigo: string;
  rCandidato: TCandidatoCliente;
begin
  sCodigo := '';
  if PuedeAccionMto(apmConsultar) and
     InputQuery_fza(STituloCoincidenciasCliente,
       SPreguntaAbrirCoincidenciaCliente, sCodigo) then
  begin
    FCoincidenciaAbrir := '';
    for rCandidato in ACandidatos do
      if SameText(Trim(sCodigo), rCandidato.Codigo) then
        FCoincidenciaAbrir := rCandidato.Codigo;
    if FCoincidenciaAbrir <> '' then
      PostMessage(Handle, WM_APP + $752, 0, 0);
  end;
end;

procedure TfrmMtoClientes.AbrirCoincidenciaCliente(var AMensaje: TMessage);
var
  sCodigo: string;
begin
  sCodigo := FCoincidenciaAbrir;
  FCoincidenciaAbrir := '';
  if (sCodigo <> '') and PuedeAccionMto(apmConsultar) then
  begin
    FDmmClientes.unqryTablaG.Cancel;
    ShowMto(Self.Owner, 'Clientes', sCodigo);
  end;
end;

procedure TfrmMtoClientes.InstalarVerificacionNif;
var
  Contexto: TContextoVerificacionNifVcl;
begin
  if not Assigned(FVerificacionNif) then
  begin
    Contexto := Default(TContextoVerificacionNifVcl);
    Contexto.EditorNif := txtNIF_CLIENTE;
    Contexto.DataSource := dsTablaG;
    Contexto.CampoNif := 'NIF_CLI';
    Contexto.CampoNombre := 'RAZON_SOCIAL_CLI';
    Contexto.CampoCliente := 'CODIGO_CLI_CLI';
    Contexto.EmpresaDefecto :=
      function: string
      begin
        Result := UbicacionSesion.Empresa;
      end;
    Contexto.Conexion := ConexionPrincipal;
    Contexto.Url := ParametrosApp.GetString('appVerificacionNifUrl',
      cUrlVerificacionNifAeat);
    FVerificacionNif := InstalarVerificacionNifVcl(Self, Contexto);
  end;
end;

procedure TfrmMtoClientes.CasillaFiscalMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Al tomar foco puede perderse el seguimiento del ratón. Reponerlo
  // permite que DevExpress procese también este primer clic (922).
  if (Button = mbLeft) and (Sender is TcxDBCheckBox) then
    TcxDBCheckBox(Sender).Perform(WM_MOUSEMOVE, MK_LBUTTON,
      MakeLParam(X, Y));
end;

procedure TfrmMtoClientes.PcPestanasChange(Sender: TObject);
begin
  if Assigned(FDmmClientes) then
  begin
    if pcPestanas.ActivePage = tsHistoriaFacturacion then
      FDmmClientes.AsegurarHistoriaFacturacionAbierta
    else if pcPestanas.ActivePage = tsPrestamos then
      FDmmClientes.AsegurarDepositosAbierta;
  end;
  // El artículo del visor Ctrl+F sale de la rejilla de la pestaña activa.
  RefrescarFotoArticulo;
end;

procedure TfrmMtoClientes.cxButton4Click(Sender: TObject);
begin
  inherited;
  if PuedeAccionMto(apmExcel) then
    ExportarExcel(
      ParametrosApp,
      cxgrdPrestamosCliente,
      'Historico_Prestamos_Cliente_' +
      dsTablaG.Dataset.FieldByName('CODIGO_CLI_CLI').AsString);
end;

procedure TfrmMtoClientes.btnIrAArticuloPresClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Articulos',
          tvDepositosCliente.DataController.DataSet.FieldByName(
            'CODIGO_ART_DEP').AsString);
end;

procedure TfrmMtoClientes.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.state = dsInsert) then
    txtCODIGO_CLIENTE.Enabled := True
  else
    txtCODIGO_CLIENTE.Enabled := False;
end;

procedure TfrmMtoClientes.ResetForm;
begin
  inherited;
  pcPestanas.ActivePage := tsDomicilioFiscal;
end;

function TfrmMtoClientes.NombreCampoESACTIVO: string;
begin
  Result := 'ESACTIVO_CLI';
end;

function TfrmMtoClientes.ContarHijosActivos: Integer;
var
  sCodCli: string;
begin
  Result := 0;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
  begin
    sCodCli := dsTablaG.DataSet.FieldByName('CODIGO_CLI_CLI').AsString;
    if sCodCli <> '' then
      Result := FRepositorioClientes.ContarDocumentos(sCodCli);
  end;
end;

function TfrmMtoClientes.DescripcionHijos: string;
begin
  Result := 'borradores y albaranes del cliente';
end;

procedure TfrmMtoClientes.txtNOMBRE_PAIS_CLIENTEPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) or (dsTablaG.State = dsEdit) then
  begin
    dsTablaG.DataSet.FieldByName('NOMBRE_PAI_CLI').AsString :=
                        FDmmClientes.unqryPaises.FieldByName('NOMBRE').AsString;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoClientes);
  ForceReferenceToClass(TfrmMtoClientes);
end.

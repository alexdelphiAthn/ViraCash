{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoArticulos                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de articulos.                                               }
{    Gestion de articulos con variaciones, atributos, propiedades y tarifas.   }
{******************************************************************************}
unit inMtoArticulos;

interface

uses
  inLibRegistroPantallas, inLibArticuloTrazabilidadVcl,
  inLibArticuloLotesVcl, inLibTrazabilidad, inLibLotesPersistenciaIntf,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer, Generics.Collections,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel, cxScrollBox,
  inMtoModalArticulosPropiedades,
  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataArticulos, inLibPerfilesUsuarioIntf,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, Vcl.DBCtrls, cxCheckComboBox, cxDBCheckComboBox,
  cxGroupBox, cxCheckGroup, cxDBCheckGroup, cxRadioGroup,
  dxScrollbarAnnotations, dxCore, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, cxButtonEdit, cxSplitter,
  cxDBExtLookupComboBox, cxListView, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  cxDBLabel, dxShellDialogs, inLibArticulosVariaciones, inMtoModalAceptCancel,
  cxCustomListBox, cxCheckListBox, System.UITypes, System.Types,
  inLibArticulosGuardadoIntf,
  inLibArticulosInyeccion,
  inLibArticulosCodigosBarrasPersistenciaIntf,
  inLibArticulosPresentacionIntf,
  inLibArticulosVariacionesIntf,
  inLibDestinoFacturaPersistenciaIntf,
  inLibPermisosIntf,
  inMtoArticulosPresentacionAtributos,
  inMtoArticulosStockVcl,
  inMtoArticulosPresentacionTarifas, inLibMargenTarifa,
  inMtoArticulosPresentacionFiltros,
  inLibFotoMiniaturaMtoVcl;

type
  TfrmMtoArticulos = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    txtDESCRIPCION_ARTICULO: TcxDBTextEdit;
    txtCODIGO_ARTICULO: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
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
    chkActivo: TcxDBCheckBox;
    chkEnWeb: TcxDBCheckBox;
    cbbFamilia: TcxDBLookupComboBox;
    btnSeleccionarFamilia: TcxButton;
    btnQuitarFamilia: TcxButton;
    lblFamilia: TcxLabel;
    tsTarifas: TcxTabSheet;
    cxgrdbclmnGrdDBTabPrinCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTIPOIVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdTarifas: TcxGrid;
    tvTarifas: TcxGridDBTableView;
    cxgrdlvlTarifas: TcxGridLevel;
    chkACTIVO_ARTICULO: TcxDBCheckBox;
    tsProveedores: TcxTabSheet;
    tsLineasFactura: TcxTabSheet;
    cxgrdProveedores: TcxGrid;
    tvProveedores: TcxGridDBTableView;
    cxgrdlvlProveedores: TcxGridLevel;
    grpComprasTarifas: TcxGroupBox;
    cxgrdComprasTarifas: TcxGrid;
    tvComprasTarifas: TcxGridDBTableView;
    lvlComprasTarifas: TcxGridLevel;
    colCompraProveedor: TcxGridDBColumn;
    colCompraNombreProveedor: TcxGridDBColumn;
    colCompraSku: TcxGridDBColumn;
    colCompraCoste: TcxGridDBColumn;
    colCompraFecha: TcxGridDBColumn;
    cxgrdLinFac: TcxGrid;
    tvLinFac: TcxGridDBTableView;
    cxgrdlvlLinFac: TcxGridLevel;
    cxgrdbclmnProveedoresCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnProveedoresCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnProveedoresINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnProveedoresINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnProveedoresUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnProveedoresUSUARIOMODIF: TcxGridDBColumn;
    cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    btnIraEmpresa: TcxButton;
    btnExportarLineas: TcxButton;
    pnlFacturaOpts1: TPanel;
    btnIraProveedor: TcxButton;
    btnExportarProveedor: TcxButton;
    pnlFacturaOpts2: TPanel;
    btnIraTarifa: TcxButton;
    btnExportarTarifa: TcxButton;
    btnIraCliente: TcxButton;
    cxgrdbclmnProveedoresRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    btnAddProveedor: TcxButton;
    cxgrdbclmnProveedoresESPROVEEDORPRINCIPAL: TcxGridDBColumn;
    splSplitterFicha: TcxSplitter;
    cxgrdbclmnTarifasCODIGO_ARTICULO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasTIPO_IVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_DESDE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_HASTA_TARIFA: TcxGridDBColumn;
    dbcTarifasPRECIOFINAL: TcxGridDBColumn;
    dbcTarifasMARGEN: TcxGridDBColumn;
    dbcTarifasPRECIOSALIDA: TcxGridDBColumn;
    dbcTarifasPORCEN_DTO_TARIFA: TcxGridDBColumn;
    dbcTarifasPRECIO_DTO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnTarifasRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnTarifasPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnTarifasFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnTarifasCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnTarifasDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnTarifasINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnTarifasINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnTarifasUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnTarifasUSUARIOMODIF: TcxGridDBColumn;
    cxgrdbclmnTarifasNOMBRE_TARIFA: TcxGridDBColumn;
    lblTextoLegal11: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevoArticulo: TcxButton;
    ActionListArticulos: TActionList;
    actEmpresas: TAction;
    actFacturas: TAction;
    actClientes: TAction;
    actProveedores: TAction;
    actTarifas: TAction;
    dbcTarifasESIMP_INCL_TARIFA: TcxGridDBColumn;
    dbcDESCRIPCION_FAM: TcxDBLabel;
    dbcNOMBRE_FAM_FAM: TcxDBLabel;
    tsGeneral: TcxTabSheet;
    sbGeneral: TcxScrollBox;
    pnlContenidoGeneral: TPanel;
    rgTipoIVA: TcxDBRadioGroup;
    cxGroupBox2: TcxGroupBox;
    chkESSERVICIO_REPARACION_ART: TcxDBCheckBox;
    lblNombre1: TcxLabel;
    cbbTipoCantidad: TcxDBLookupComboBox;
    lblTipoArticulo: TcxLabel;
    cbbTIPO_ART: TcxDBComboBox;
    tvProveedoresREF_PROVEEDOR: TcxGridDBColumn;
    chkESVARIACION_ART: TcxDBCheckBox;
    tsSkuMto: TcxTabSheet;
    pnlTopSkus: TPanel;
    pnlSkuMto: TPanel;
    addSkuAll: TcxButton;
    cxgrdSkuMto: TcxGrid;
    tvSkuMto: TcxGridDBTableView;
    tvSkuMtoCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkuMtoCODIGO_VAR_SKU: TcxGridDBColumn;
    tvSkuMtoESACTIVO_SKU: TcxGridDBColumn;
    tvSkuMtoCODIGO_ART_SKU: TcxGridDBColumn;
    tvSkuMtoPRECIO_ULT_COMPRA_SKUC: TcxGridDBColumn;
    tvSkuMtoFECHA_ULT_COMPRA_SKUC: TcxGridDBColumn;
    cxgrdSkuMtoLevel: TcxGridLevel;
    splSkuAtributosBasicos: TcxSplitter;
    gbSkuAtributosBasicos: TcxGroupBox;
    cxgrdSkuAtributosBasicos: TcxGrid;
    tvSkuAtributosBasicos: TcxGridDBTableView;
    tvSkuAtributosBasicosID_VA_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosNOMBRE_ATRIBUTO: TcxGridDBColumn;
    tvSkuAtributosBasicosVALOR_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosID_ATB_AV: TcxGridDBColumn;
    tvSkuAtributosBasicosDESCRIPCION_AAB: TcxGridDBColumn;
    tvSkuAtributosBasicosNOMBRE_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosHEX_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosVALOR_NUM_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosUNIDAD_ATB: TcxGridDBColumn;
    tvSkuAtributosBasicosETIQUETA_BASICO: TcxGridDBColumn;
    tvSkuAtributosBasicosFUENTE_ATB: TcxGridDBColumn;
    cxgrdSkuAtributosBasicosLevel: TcxGridLevel;
    tsSKUs: TcxTabSheet;
    pnlBotonesCB: TPanel;
    btnExportarExcelCB: TcxButton;
    cxgrdSkus: TcxGrid;
    tvSkus: TcxGridDBTableView;
    tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkusCODIGO_ARTICULO_SKU: TcxGridDBColumn;
    tvSkusESACTIVO_SKU: TcxGridDBColumn;
    tvSkusINSTANTEMODIF: TcxGridDBColumn;
    tvSkusINSTANTEALTA: TcxGridDBColumn;
    tvSkusUSUARIOALTA: TcxGridDBColumn;
    tvSkusUSUARIOMODIF: TcxGridDBColumn;
    cxgrdlvlSkus: TcxGridLevel;
    cxTabSheet3: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tvSkusCODIGO_BARRAS_CB: TcxGridDBColumn;
    tvSkusTIPO_CODIGO_CB: TcxGridDBColumn;
    tvSkusESPRINCIPAL_CB: TcxGridDBColumn;
    tvSkusID_CB: TcxGridDBColumn;
    tvSkusSTOCK_TOTAL: TcxGridDBColumn;
    btnGenerarCB: TcxButton;
    btnVerificarCB: TcxButton;
    cxGrdStock: TcxGrid;
    tvStock: TcxGridDBTableView;
    cxgrdlvlStock: TcxGridLevel;
    pnlBotonesTarifas: TPanel;
    btnStockExportarExcel: TcxButton;
    btnReconstruirStock: TcxButton;
    btnImprimirEtiquetas: TcxButton;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxgrdlvlStockAlt: TcxGridLevel;
    pnlBotonesStock: TPanel;
    btnExportarExcelStock: TcxButton;
    tvStockAlmacen: TcxGridDBColumn;
    tvStockColor: TcxGridDBColumn;
    tvStockDBColumn42: TcxGridDBColumn;
    tvStockDBColumn43: TcxGridDBColumn;
    tvStockTotal: TcxGridDBColumn;
    tvMovimientosNUMERO_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosSERIE_DOC_MOV: TcxGridDBColumn;
    tvMovimientosNRO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_EMPRESA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALMACEN_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ARTICULO_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    tvMovimientosDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_MOVIMIENTO_MOV: TcxGridDBColumn;
    tvMovimientosCANTIDAD_MOV: TcxGridDBColumn;
    tvMovimientosPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn;
    tvMovimientosTOTAL_COSTE_MOV: TcxGridDBColumn;
    tvMovimientosPRECIO_MEDIO_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_CLIENTE_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_PROVEEDOR_MOV: TcxGridDBColumn;
    tvMovimientosESACTIVO_MOV: TcxGridDBColumn;
    tvMovimientosINSTANTEMODIF: TcxGridDBColumn;
    tvMovimientosINSTANTEALTA: TcxGridDBColumn;
    tvMovimientosUSUARIOALTA: TcxGridDBColumn;
    tvMovimientosUSUARIOMODIF: TcxGridDBColumn;
    tvMovimientosTIPO_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosSERIE_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosNRO_DOC_REF_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_REF_MOV: TcxGridDBColumn;
    tvMovimientosLOTE_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_CADUCIDAD_MOV: TcxGridDBColumn;
    tvMovimientosNOMBRE_ALMACEN_ORIGEN: TcxGridDBColumn;
    tvMovimientosNOMBRE_ALMACEN_DESTINO: TcxGridDBColumn;
    tvMovimientosDESCRIPCION_TIPODOCUMENTO: TcxGridDBColumn;
    tvMovimientosRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
    tvMovimientosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    tsPropiedades: TcxTabSheet;
    chkESTRAZABLE_ART: TcxDBCheckBox;
    tvTarifasCODIGO_UNIDAD_TARIFA: TcxGridDBColumn;
    tvTarifasESVARIACION_ARTICULO: TcxGridDBColumn;
    tvTarifasNUM_ATRIBUTOS_REQ: TcxGridDBColumn;
    btnAddSKU: TcxButton;
    btnColorSkus: TcxButton;
    pmColorSkus: TPopupMenu;
    miActivarColor: TMenuItem;
    miDesactivarColor: TMenuItem;
    tvLinFacNOMBRE_TIPO_IVA_IVATIP: TcxGridDBColumn;
    tvLinFacCODIGO_TAR_FACLIN: TcxGridDBColumn;
    tvLinFacPRECIO_SALIDA_FACLIN: TcxGridDBColumn;
    tvLinFacPORCENTAJE_DTO_FACLIN: TcxGridDBColumn;
    tvLinFacPRECIO_DTO_FACLIN: TcxGridDBColumn;
    tvLinFacTOTAL_FAC_SIVA_FACLIN: TcxGridDBColumn;
    tvLinFacCODIGO_CLIENTE_FACTURA_LINEA: TcxGridDBColumn;
    tvLinFacCODIGO_EMP_FACLIN: TcxGridDBColumn;
    tvLinFacFECHA_FAC: TcxGridDBColumn;
    tvLinFacNUMERO_FAC: TcxGridDBColumn;
    tvLinFacSERIE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_LIQUIDO_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RETENCION_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RETENCION_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IMPUESTOS_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASES_FAC: TcxGridDBColumn;
    tvLinFacFORMA_PAGO_FAC: TcxGridDBColumn;
    tvLinFacDESCRIPCION_FORMA_PAGO_FP: TcxGridDBColumn;
    tvLinFacCODIGO_EMP_FAC: TcxGridDBColumn;
    tvLinFacRAZON_SOCIAL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacNIF_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacMOVIL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacEMAIL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION1_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION2_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacPOBLACION_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacPROVINCIA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacNOMBRE_PAI_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_POSTAL_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacESRETENCIONES_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacGRUPO_ZONA_IVA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacESREGIMENESPECIALAGRICOLA_EMPRESA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_CLI_FAC: TcxGridDBColumn;
    tvLinFacRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacNIF_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacMOVIL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacEMAIL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION1_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacDIRECCION2_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacPOBLACION_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacPROVINCIA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacNOMBRE_PAI_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIVA_RECARGO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIVA_EXENTO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESREGIMENESPECIALAGRICOLA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESRETENCIONES_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacTARIFA_ARTICULO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIMP_INCL_TARIFA_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESINTRACOMUNITARIO_CLIENTE_FAC: TcxGridDBColumn;
    tvLinFacESIRPF_IMP_INCL_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacESAPLICA_RE_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacESIVAAGRICOLA_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacPALABRA_REPORTS_ZONA_IVA_FAC: TcxGridDBColumn;
    tvLinFacCODIGO_IVA_FAC: TcxGridDBColumn;
    tvLinFacESVENTA_ACTIVO_FIJO_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAN_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_REN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_REN_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAN_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAR_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAR_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RER_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RER_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAR_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAS_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAS_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_RES_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_RES_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAS_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_IVAE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_IVAE_FAC: TcxGridDBColumn;
    tvLinFacPORCENTAJE_REE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_REE_FAC: TcxGridDBColumn;
    tvLinFacTOTAL_BASEI_IVAE_FAC: TcxGridDBColumn;
    pnlFiltrosArt: TPanel;
    btnToggleFiltrosArt: TcxButton;
    pnlContFiltrosArt: TPanel;
    lblFiltroEstadoArt: TcxLabel;
    cbbFiltroEstadoArt: TcxComboBox;
    chkFiltroConStockArt: TcxCheckBox;
    lblFiltroTemporadaArt: TcxLabel;
    ccbFiltroTemporadaArt: TcxCheckComboBox;
    btnCargarAhoraArt: TcxButton;
    btnGuardarPrecargaArt: TcxButton;
    actFamilias: TAction;
    procedure btnToggleFiltrosArtClick(Sender: TObject);
    procedure cbbFiltroEstadoArtPropertiesEditValueChanged(Sender: TObject);
    procedure chkFiltroConStockArtPropertiesEditValueChanged(Sender: TObject);
    procedure ccbFiltroTemporadaArtPropertiesCloseUp(Sender: TObject);
    procedure btnCargarAhoraArtClick(Sender: TObject);
    procedure btnGuardarPrecargaArtClick(Sender: TObject);
    procedure btnAddProveedorClick(Sender: TObject);
    procedure cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure btnIraProveedorClick(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure actTarifasExecute(Sender: TObject);
    procedure btnNuevoArticuloClick(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure actFamiliasExecute(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnIraEmpresaClick(Sender: TObject);
    procedure btnCrearTarifaClick(Sender: TObject);
    procedure btnExportarTarifaClick(Sender: TObject);
    procedure btnExportarProveedorClick(Sender: TObject);
    procedure btnIraTarifaClick(Sender: TObject);
    procedure dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIOSALIDAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged(
      Sender: TObject);
    procedure dbcTarifasPRECIOFINALPropertiesEditValueChanged(
      Sender: TObject);
    procedure actEmpresasExecute(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure txtCODIGO_ARTICULOExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cxDBCheckBox1PropertiesEditValueChanged(Sender: TObject);
    procedure cxDBComboBox1PropertiesEditValueChanged(Sender: TObject);
    procedure cbbFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure btnSeleccionarFamiliaClick(Sender: TObject);
    procedure btnQuitarFamiliaClick(Sender: TObject);
    procedure addSkuAllClick(Sender: TObject);
    procedure btnAddSKUClick(Sender: TObject);
    procedure cxButton11Click(Sender: TObject);
    procedure btnStockExportarExcelClick(Sender: TObject);
    procedure btnReconstruirStockClick(Sender: TObject);
    procedure btnImprimirEtiquetasClick(Sender: TObject);
    procedure btnGenerarCBClick(Sender: TObject);
    procedure btnVerificarCBClick(Sender: TObject);
    procedure tvTarifasCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo;
      AButton: TMouseButton; AShift: TShiftState;
      var AHandled: Boolean);
    procedure tvTarifasKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MostrarFechaCompraTarifa(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure MostrarProveedorCompraTarifa(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure MostrarCosteTarifa(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure dbcTarifasMARGENGetDisplayText(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AText: string);
    procedure tvSkuAtributosBasicosHEX_ATBCustomDrawCell(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp(
      Sender: TObject);
    procedure tvSkuAtributosBasicosID_ATB_AVPropertiesValidate(
      Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick(
      Sender: TObject; AButtonIndex: Integer);
    procedure tvSkuAtributosBasicosDblClick(Sender: TObject);
    procedure tvSkuAtributosBasicosFUENTE_ATBGetDisplayText(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AText: string);
    procedure tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged(
      Sender: TObject);
    procedure tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnColorSkusClick(Sender: TObject);
    procedure miActivarColorClick(Sender: TObject);
    procedure miDesactivarColorClick(Sender: TObject);
    procedure tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tvStockGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
  private
     procedure BuscarProveedores;
     // Carga perezosa de la pestaña Tarifas: vi_articulos_tarifas tarda
     // ~6s por subqueries DEPENDENT. La abrimos solo cuando el usuario
     // pasa a tsTarifas (ver dmmArticulos.AsegurarTarifasAbiertas).
     procedure PcDetailChange(Sender: TObject);
     procedure ActualizarCargaTarifas;
  public
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure AplicarEtiquetas; override;
    procedure TrasPrecargaAsync; override;
  private
    FGestorProp  : TGestorPropiedades;
    // Alta: las propiedades esperan a que la ficha tenga Post (no hay
    // código de artículo con el que grabarlas hasta entonces).
    FPropiedadesAltaPendientes: Boolean;
    FErrorPropiedadesAlta: Boolean;
    FArticuloCargado: string;
    FScrollProp  : TcxScrollBox;
    FBtnAddProp  : TcxButton;
    FGestorVar      : TGestorVariaciones;
    // Zona inferior de la pestaña General (tipo de variación + tallas y
    // colores) con su divisor: se encoge o minimiza en pantallas pequeñas.
    FPnlVariaciones: TPanel;
    FSplVariaciones: TcxSplitter;
    FVariacionesMinimizadas: Boolean;
    FPnlTopVariaciones:TPanel;
    FScrollVarAtrib : TScrollBox;
    FCbbTipoVariacion   : TcxDBLookupComboBox;
    // Colaboradores de presentacion. Cada uno recibe solo los controles,
    // datasets y puertos que necesita; ninguno conoce el formulario.
    FPresAtributos: TPresentadorAtributosBasicosArticulo;
    FStock: TCoordinadorStockArticuloVcl;
    FPresTarifas: TPresentadorTarifasArticulo;
    FPresFiltros: TPresentadorFiltrosArticulos;
    FCodigosBarras: ILecturaCodigosBarrasArticulo;
    FAplicacionGuardado: IAplicacionGuardadoArticulo;
    FDependencias: TContextoDependenciasArticulos;
    FCodigosBarrasPersistencia: IArticulosCodigosBarrasPersistencia;
    FResolutorDestinoFactura: IResolutorDestinoFactura;
    FPuedeCambiarMarcaWeb: Boolean;
    FActualizandoFamiliaDesdeArbol: Boolean;
    FMiniaturaFoto: TMiniaturaFotoMto;
    // F-LOTEC-011: grupo «Trazabilidad» de la pestaña General.
    FTrazabilidadFicha: TFichaTrazabilidadArticuloVcl;
    // F-LOTEC-011: pestaña «Lotes / Series» (solo con interruptores).
    FLotesFicha: TPestanaLotesArticuloVcl;
    procedure ConstruirTrazabilidadFicha;
    procedure ImprimirEtiquetaLote(const ALote: TLoteArticulo);
    procedure RetirarLotesFicha(const ALotes: TArray<TLoteArticulo>);
    procedure ReimprimirRetiradaLote(const AMovimiento: string);
    procedure ConstruirLotesFicha(
      const AActivacion: TActivacionTrazabilidad);
    procedure AnadirColumnaLoteCodigos;
    procedure ColocarColumnaLoteCodigos;
    procedure RefrescarLotesFicha;
    function ConfirmarDesactivacionWebArticulo(
      const ACodigoArticulo, ADescripcionArticulo: string):
      TDecisionDesactivacionWebArticulo;
    procedure CargarPropiedadesFamiliaActual;
    procedure CambiarFamiliaArticulo(const ACodigoFamilia: string;
      ALimpiar: Boolean);
    procedure InicializarPestanyaVariaciones;
    procedure InicializarPestanyaPropiedades;
    procedure InicializarPresentadores;
    function ModoMargenTarifas: TModoMargenTarifa;
    function ModoVariantesActivo: Boolean;
    procedure MostrarZonaVariaciones(AVisible: Boolean);
    procedure OnAfterScrollArticulos(DataSet: TDataSet);
    procedure BtnAddPropClick(Sender: TObject);
    function AltaArticuloEnCurso: Boolean;
    function CodigoArticuloStock: string;
    procedure ComprobarCodigoArticuloDiferido;
    procedure PresentarValidacionDatosArticulo(const AMensaje: string;
      ACampo: TCampoValidacionArticulo);
    // FZ-ISSUE-172: True si el usuario acepta el código libre propuesto.
    function AvisarCodigoArticuloDuplicado(const AMensaje: string): Boolean;
    // FZ-ISSUE-439: el menú nombra el eje de fila del artículo en pantalla.
    procedure AjustarMenuColorSkus(Sender: TObject);
    procedure AvisarCodigoBarrasRepetido(
      const AExistente: TCodigoBarrasRepetido);
    procedure AvisarCodigoBarrasGs1(const ACodigo: string);
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasArticulos); reintroduce;
      overload;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure ActualizarVisibilidadVariaciones;
    procedure TipoVariacionEditValueChanged(Sender: TObject);
    procedure ActualizarVisibilidadColumnaSku;
    procedure AsegurarSkuArticuloSinVariaciones(const aCodArticulo: string);
    procedure AsegurarSkuArticulo(const aCodArticulo: string);
    procedure SolicitarDatosFormulaAlta(Sender: TObject);
    procedure CrearTablaPrincipal; override;
    procedure PestanaActivada; override;
    procedure ResetForm;  override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
    // Recorre las columnas de tvStock y, para las que contienen valores que
    // casan con la paleta basica del articulo, añade ANCHO_SWATCH_PX al
    // ancho — necesario porque ApplyBestFit mide solo el texto y no el
    // cuadradito que pinta tvStockCustomDrawCell.
    procedure EnsancharColumnasStockParaSwatch;
    // FZ-ISSUE-251: doble clic en Pte. traspasar / Pte. recibir trasp. /
    // Disponible = documentos pendientes del almacen; en el resto, lo de
    // siempre (cxGrdDBTabPrinDblClick).
    procedure tvStockDblClickPendiente(Sender: TObject);
  public
    // Data module de ESTA instancia (campo de instancia, no variable
    // global, asi no se pisa cuando hay dos Mtos Articulos abiertos a
    // la vez). Mismo patron que TfrmMtoFacturasBase.dmmFacturas.
    dmmArticulos: TdmArticulos;
  end;

implementation

uses
  inLibBotonesDetalle,
  inLibTraspasosPendientesTexto, UniDataTraspasosPendientesConsulta,
  inMtoModalMensajeTexto,
  inLibMsgTrazabilidad,
  inLibVariacionesRotulos, cxLookupDBGrid,
  UniDataComprasSesionesPresentacionRepositorio,
  UniDataLotesRepositorio, inMtoModalSeleccionLote,
  inLibRetiradaLotesIntf, inMtoModalRetiradaLotes,
  inLibMensajesVcl,
  inLibWin,
  inLibUser,
  inLibDevExp,
  inLibShowMto,
  inLibCodigosSinBarra,
  inLibFotos,
  inLibGenBusq,
  inMtoModalSelFamilia,
  inMtoModalGenerarSKUs,
  inMtoModalEtiqArt,
  inLibEtiquetasLotes,
  inLibMsgLotesConsultas,
  inLibArticulosCodigosBarras, inLibComprasSesionesCodigoArticulo,
  inLibMsgCompras,
  inLibArticulosAtributosBasicos,
  inLibArticulosAtributosBasicosIntf,
  inMtoArticulosGuardadoVcl,
  inLibArticulosVisibilidad,
  inLibArticulosPresentacion,
  UniDataArticulosAtributosBasicosRepositorio,
  UniDataArticulosPresentacionRepositorio,
  UniDataArticulosCodigosBarrasRepositorio,
  UniDataColumnasDocumentoRepositorio,
  UniDataDestinoFacturaRepositorio,
  UniDataFiltroArticulosRepositorio,
  inMtoArticulosNavegacionFacturasVcl,
  inLibMenuColumnasRejillaVcl,
  System.Diagnostics,   // TStopwatch
  inLibMsgArticulos, inLibMsgComun, inLibErroresBBDD;

{$R *.dfm}

resourcestring
  STituloBuscarProveedoresArticulos =
    'Búsqueda de Proveedores en Articulos';

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoArticulos.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasArticulos);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure InicializarGuardadoArticuloVcl(AFormulario: TfrmMtoArticulos);
var
  Callbacks: TCallbacksGuardadoArticulo;
  Operaciones: IOperacionesGuardadoArticulo;
begin
  Callbacks := Default(TCallbacksGuardadoArticulo);
  Callbacks.ValidarPropiedades :=
    function: string
    begin
      Result := '';
      if Assigned(AFormulario.FGestorProp) then
        Result := AFormulario.FGestorProp.Validar;
    end;
  Callbacks.GuardarPropiedades :=
    function(out AMensajeError: string): Boolean
    begin
      Result := True;
      AMensajeError := '';
      AFormulario.FPropiedadesAltaPendientes :=
        AFormulario.dmmArticulos.unqryTablaG.State = dsInsert;
      if Assigned(AFormulario.FGestorProp) and
         not AFormulario.FPropiedadesAltaPendientes then
      begin
        try
          AFormulario.FGestorProp.GuardarPropiedades;
        except
          on E: Exception do
          begin
            Result := False;
            AMensajeError := E.Message;
          end;
        end;
      end;
    end;
  Callbacks.GuardarEdicionesPendientes :=
    procedure
    begin
      if AFormulario.dmmArticulos.unqryProveedoresArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryProveedoresArticulos.Post;
      if AFormulario.dmmArticulos.unqryTarifasArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryTarifasArticulos.Post;
      if AFormulario.dmmArticulos.unqryVariacionesArticulos.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqryVariacionesArticulos.Post;
      if AFormulario.dmmArticulos.unqrySkus.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.unqrySkus.Post;
      if AFormulario.dmmArticulos.unqryTablaG.State in
        [dsInsert, dsEdit] then
        AFormulario.dmmArticulos.GuardarArticulo;
    end;
  Callbacks.GuardarVariaciones :=
    function(out AMensajeError: string): Boolean
    begin
      Result := True;
      AMensajeError := '';
      // Propiedades de un alta, ya con la ficha grabada y su código.
      if AFormulario.FPropiedadesAltaPendientes then
      begin
        AFormulario.FPropiedadesAltaPendientes := False;
        if Assigned(AFormulario.FGestorProp) then
        begin
          AFormulario.FGestorProp.AsignarCodigoArticulo(
            AFormulario.dmmArticulos.unqryTablaG.FieldByName(
              'CODIGO_ART_ART').AsString);
          try
            AFormulario.FGestorProp.GuardarPropiedades;
          except
            on E: Exception do
            begin
              Result := False;
              AMensajeError := E.Message;
              AFormulario.FErrorPropiedadesAlta := True;
            end;
          end;
        end;
      end;
      if Result and Assigned(AFormulario.FGestorVar) then
      begin
        try
          // En un alta el gestor aún no sabe el código: la ficha ya tiene
          // Post (GuardarEdicionesPendientes) y el código es el definitivo.
          AFormulario.FGestorVar.AsignarCodigoArticulo(
            AFormulario.dmmArticulos.unqryTablaG.FieldByName(
              'CODIGO_ART_ART').AsString);
          AFormulario.FGestorVar.GuardarVariaciones;
        except
          on E: Exception do
          begin
            Result := False;
            AMensajeError := E.Message;
          end;
        end;
      end;
    end;
  Operaciones := TAdaptadorGuardadoArticuloVcl.Create(Callbacks);
  AFormulario.FAplicacionGuardado :=
    AFormulario.FDependencias.CrearGuardado(Operaciones);
end;

procedure TfrmMtoArticulos.ActualizarVisibilidadVariaciones;
var
  HayVars, EsEstandar: Boolean;
  Tipo, CodArticulo: string;
begin
  HayVars := False;
  EsEstandar := True;
  if Assigned(dmmArticulos) and (dmmArticulos.unqryTablaG.Active = True) and
     (not dmmArticulos.unqryTablaG.IsEmpty) then
  begin
    HayVars := dmmArticulos.unqryTablaG.FieldByName(
                                     'ESVARIACION_ART').AsWideString = 'S';
    Tipo := Trim(dmmArticulos.unqryTablaG.FieldByName('TIPO_ART').AsString);
    // Por defecto se considera ESTANDAR si está vacío (compat. con altas)
    EsEstandar := (Tipo = '') or SameText(Tipo, 'ESTANDAR');
  end;
  // Sin modo variantes (parámetro appModoVariantes) la opción no se
  // ofrece; un artículo que ya tiene variaciones la conserva.
  chkESVARIACION_ART.Visible := HayVars or ModoVariantesActivo;
  MostrarZonaVariaciones(HayVars);
  // Selectores de tallaje según la ficha en pantalla, no según la BBDD:
  // en un alta el artículo aún no existe y antes solo salían tras grabar
  // y mover el dataset. Si no cambia nada, el gestor no repinta.
  if Assigned(FGestorVar) and Assigned(dmmArticulos) and
     dmmArticulos.unqryTablaG.Active and
     not dmmArticulos.unqryTablaG.IsEmpty then
  begin
    if dmmArticulos.unqryTablaG.State = dsInsert then
      CodArticulo := ''
    else
      CodArticulo := dmmArticulos.unqryTablaG.FieldByName(
        'CODIGO_ART_ART').AsString;
    if HayVars then
      FGestorVar.MostrarTipoVariacion(CodArticulo,
        dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ART').AsString)
    else
      FGestorVar.MostrarTipoVariacion(CodArticulo, '');
  end;
  // Pestaña "Códigos de Barras" siempre visible (incluso para artículos
  // sin variaciones, con un único SKU = código del artículo).
  tsSKUS.TabVisible  := True;
  // Pestaña dedicada a SKUs sólo si el artículo usa variaciones.
  tsSkuMto.TabVisible := HayVars;
  // Generación masiva de SKUs únicamente con variaciones.
  addSkuAll.Visible  := HayVars;
  // Stock y movimientos sólo aplican a artículos físicos (ESTANDAR)
  tvSkusSTOCK_TOTAL.Visible := EsEstandar;
  tsMovimientos.TabVisible  := EsEstandar;
  cxTabSheet3.TabVisible    := EsEstandar; // pestaña Stock
  AjustarMenuColorSkus(nil);
end;

function TfrmMtoArticulos.ModoVariantesActivo: Boolean;
begin
  Result := Assigned(ParametrosApp) and
    ParametrosApp.GetBool('appModoVariantes', True);
end;

procedure TfrmMtoArticulos.MostrarZonaVariaciones(AVisible: Boolean);
begin
  if FSplVariaciones.Visible <> AVisible then
  begin
    if AVisible then
    begin
      FPnlVariaciones.Visible := True;
      // La alineación inferior ordena por posición: el divisor tiene que
      // reaparecer justo encima del panel.
      FSplVariaciones.Top :=
        FPnlVariaciones.Top - FSplVariaciones.Height;
      FSplVariaciones.Visible := True;
      // Si el usuario la dejó minimizada, sigue minimizada al cambiar
      // de artículo.
      if FVariacionesMinimizadas then
        FSplVariaciones.CloseSplitter;
    end
    else
    begin
      // Se oculta abierta para que el divisor no pierda la altura.
      FVariacionesMinimizadas := FSplVariaciones.State = ssClosed;
      if FVariacionesMinimizadas then
        FSplVariaciones.OpenSplitter;
      FSplVariaciones.Visible := False;
      FPnlVariaciones.Visible := False;
    end;
  end;
end;

// FZ-ISSUE-445: un tipo de variacion creado en otra pestaña debe salir
// en el desplegable al volver a esta.
procedure TfrmMtoArticulos.PestanaActivada;
begin
  inherited;
  if Assigned(dmmArticulos) and dmmArticulos.unqryVariaciones.Active then
    dmmArticulos.unqryVariaciones.Refresh;
end;

procedure TfrmMtoArticulos.TipoVariacionEditValueChanged(Sender: TObject);
begin
  // Solo cambios del usuario: al navegar el dataset ya repinta el
  // AfterScroll.
  if Assigned(dmmArticulos) and dmmArticulos.unqryTablaG.Active and
     not dmmArticulos.unqryTablaG.ControlsDisabled and
     (dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    FCbbTipoVariacion.PostEditValue;
    ActualizarVisibilidadVariaciones;
  end;
end;

procedure TfrmMtoArticulos.ActualizarVisibilidadColumnaSku;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  if Assigned(dmmArticulos) then
  begin
    Visibilidad := EvaluarVisibilidadColumnasArticulo(
      dmmArticulos.unqryTarifasArticulos,
      dmmArticulos.unqrySkus);
    tvTarifasCODIGO_UNIDAD_TARIFA.Visible :=
      Visibilidad.MostrarSkuTarifa;
    tvSkuMtoPRECIO_ULT_COMPRA_SKUC.Visible :=
      Visibilidad.MostrarCompraSku;
    tvSkuMtoFECHA_ULT_COMPRA_SKUC.Visible :=
      Visibilidad.MostrarCompraSku;
  end;
end;

procedure TfrmMtoArticulos.AsegurarSkuArticuloSinVariaciones(
  const aCodArticulo: string);
begin
  inLibArticulosVariaciones.AsegurarSkuArticuloSinVariaciones(
    FDependencias.Variaciones,
    aCodArticulo, IdentidadSesion.Usuario);
end;
procedure TfrmMtoArticulos.AsegurarSkuArticulo(
  const aCodArticulo: string);
begin
  inLibArticulosVariaciones.AsegurarSkuArticuloActivo(
    FDependencias.Variaciones,
    aCodArticulo, IdentidadSesion.Usuario);
end;
procedure TfrmMtoArticulos.addSkuAllClick(Sender: TObject);
var
  CodArticulo, TipoVariacion: string;
begin
  // 1. Nos aseguramos de que el artículo no esté a medias de editar
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;

  // 2. Leemos los datos clave del dataset principal
  CodArticulo   :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  TipoVariacion :=
    dmmArticulos.unqryTablaG.FieldByName('TIPO_VARIACION_ART').AsString;

  // 3. Validamos que haya un esquema de variación asignado
  if (CodArticulo = '') or (TipoVariacion = '') then
  begin
    ShowMessage_fza(SErrorArticuloSinTipoVariacion);
    // Mandamos al usuario al combo para que lo elija
    FCbbTipoVariacion.SetFocus;
  end;
  if (CodArticulo <> '') and (TipoVariacion <> '') then
  begin
    // El tallaje elegido en General no es DB-aware: solo se grababa con
    // Grabar. Se persiste antes para que el modal lo lea como conjunto por
    // defecto y el CargarVariaciones posterior no lo borre de pantalla.
    if Assigned(FGestorVar) then
    begin
      FGestorVar.AsignarCodigoArticulo(CodArticulo);
      FGestorVar.GuardarVariaciones;
    end;
    dmmArticulos.RecargarSkusGenerados(
      TfrmMtoModalGenerarSKUs.Ejecutar(
        Self,
        CodArticulo,
        TipoVariacion,
        FDependencias.GeneracionSkus).SkusCreados);
    // El modal puede haber asignado el tallaje: la pestaña General lo
    // enseña al día (y no lo pisa al grabar con lo que tenía antes).
    if Assigned(FGestorVar) then
      FGestorVar.CargarVariaciones(CodArticulo);
  end;
end;

procedure TfrmMtoArticulos.actClientesExecute(Sender: TObject);
begin
  inherited;
  //Control + K
  //https://stackoverflow.com/questions/2317208/
  //how-to-fire-keypreview-event-when-form-has-a-tactionmainmenubar
  if ((pcDetail.ActivePage = tsLineasFactura)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoArticulos.actEmpresasExecute(Sender: TObject);
begin
  inherited;
  // Ctrl+Alt+E -> Empresas.
    if (
        (pcDetail.ActivePage = tsLineasFactura)        and
        (not(tvLinFac.DataController.DataSet.FieldByName(
          'CODIGO_EMP_FACLIN').IsNull))
       ) then
      btnIraEmpresaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Empresas');
end;

procedure TfrmMtoArticulos.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F   -> Facturas
  if pcDetail.ActivePage = tsLineasFactura then
  begin
    if not IntentarAbrirFacturaLineaActiva(
         Self.Owner, tvLinFac, FResolutorDestinoFactura) then
      ShowMto(Self.Owner,
              'Facturas');
  end
  else
    ShowMto(Self.Owner,
            'Facturas');
end;

procedure TfrmMtoArticulos.actFamiliasExecute(Sender: TObject);
begin
  inherited;
  //Control + N     -> Familias
    if ((not(dsTablaG.DataSet.FieldByName('CODIGO_FAM_ART').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              dsTablaG.DataSet.FieldByName('CODIGO_FAM_ART').AsString)
    else
      ShowMto(Self.Owner,
              'Familias');
end;

procedure TfrmMtoArticulos.actProveedoresExecute(Sender: TObject);
begin  //control + P -> proveedores
  inherited;
    if (
        (pcDetail.ActivePage = tsProveedores) and
        (not(tvProveedores.DataController.DataSet.FieldByName(
          'CODIGO_PRV_PRV').IsNull))
       ) then
      btnIraProveedorClick(Sender)
    else
      ShowMto(Self.Owner,
              'Proveedores');
end;

procedure TfrmMtoArticulos.actTarifasExecute(Sender: TObject);
begin
  inherited;
  //Control + T -> Tarifas
    if (
        (pcDetail.ActivePage = tsTarifas) and
        (not(tvTarifas.DataController.DataSet.FieldByName(
          'CODIGO_TAR_ARTTAR').IsNull))
       ) then
      btnIraTarifaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Tarifas');
end;

procedure TfrmMtoArticulos.btnAddProveedorClick(Sender: TObject);
begin
  if (dmmArticulos.unqryTablaG.State = dsInsert) or
     (dmmArticulos.unqryTablaG.State = dsEdit) then
    dmmArticulos.unqryTablaG.Post;
  BuscarProveedores;
end;

procedure TfrmMtoArticulos.btnAddSKUClick(Sender: TObject);
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  FPresTarifas.AltaMasivaPrecios(Self,
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.tvTarifasCellDblClick(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton; AShift: TShiftState;
  var AHandled: Boolean);
begin
  // El margen no se teclea: sale de coste y precio de salida, así que
  // editarlo es abrir la calculadora.
  if (AButton = mbLeft) and (ACellViewInfo.Item = dbcTarifasMARGEN) then
  begin
    AHandled := True;
    FPresTarifas.AbrirCalculadoraMargen(Self);
  end;
end;

procedure TfrmMtoArticulos.tvTarifasKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if (Key = VK_F2) and (Shift = []) and
     (tvTarifas.Controller.FocusedColumn = dbcTarifasMARGEN) then
  begin
    Key := 0;
    FPresTarifas.AbrirCalculadoraMargen(Self);
  end;
end;

procedure TfrmMtoArticulos.MostrarCosteTarifa(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if Assigned(FPresTarifas) then
    FPresTarifas.MostrarCoste(ARecord, AText);
end;

procedure TfrmMtoArticulos.MostrarFechaCompraTarifa(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if Assigned(FPresTarifas) then
    FPresTarifas.MostrarFechaCompra(ARecord, AText);
end;

procedure TfrmMtoArticulos.MostrarProveedorCompraTarifa(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if Assigned(FPresTarifas) then
    FPresTarifas.MostrarProveedorCompra(ARecord, AText);
end;

procedure TfrmMtoArticulos.dbcTarifasMARGENGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  // La rejilla de tarifas se pinta al cargar el DFM (TcxCustomGrid.Loaded),
  // antes de InicializarPresentadores, y también al destruir el formulario:
  // sin presentador no hay margen que mostrar.
  if FPresTarifas <> nil then
    FPresTarifas.MostrarMargen(ARecord, AText)
  else
    AText := '';
end;

procedure TfrmMtoArticulos.btnBuscarClick(Sender: TObject);
begin
  inherited;
  sleep(0);
end;

procedure TfrmMtoArticulos.btnCrearTarifaClick(Sender: TObject);
begin
  inherited;
  if ( (dmmArticulos.unqryTablaG.State = dsInsert) or
       (dmmArticulos.unqryTablaG.State = dsEdit)) then
    dmmArticulos.unqryTablaG.Post;
  if ( (dmmArticulos.unqryTarifasArticulos.State = dsInsert) or
       (dmmArticulos.unqryTarifasArticulos.State = dsEdit)) then
  begin
    dmmArticulos.unqryTarifasArticulos.Post;
  end;
  FPresTarifas.IncorporarTarifas(Self.Owner);
end;

procedure TfrmMtoArticulos.btnExportarProveedorClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdProveedores,
                'Historico_Proveedores_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnExportarTarifaClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdTarifas,
                'Historico_Tarifas_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Clientes',
          tvLinFac.DataController.DataSet.FieldByName(
            'CODIGO_CLIENTE_FACTURA_LINEA').AsString);
end;

procedure TfrmMtoArticulos.btnIraEmpresaClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Empresas',
          tvLinfac.DataController.DataSet.FieldByName(
                                      'CODIGO_EMP_FACLIN').AsString);
end;

procedure TfrmMtoArticulos.btnIraFacturaClick(Sender: TObject);
begin
  inherited;
  if not IntentarAbrirFacturaLineaActiva(
           Self.Owner, tvLinFac, FResolutorDestinoFactura) then
    ShowMto(Self.Owner,
            'Facturas');
end;

procedure TfrmMtoArticulos.btnIraProveedorClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
    'Proveedores',
    tvProveedores.DataController.DataSet.FieldByName(
                                                  'CODIGO_PRV_PRV').AsString);
end;

procedure TfrmMtoArticulos.btnIraTarifaClick(Sender: TObject);
begin
  inherited;
    ShowMto(Self.Owner,
            'Tarifas',
            dmmArticulos.unqryTarifasArticulos.FieldByName(
                                                 'CODIGO_TAR_ARTTAR').AsString);
end;

function TfrmMtoArticulos.ConfirmarDesactivacionWebArticulo(
  const ACodigoArticulo, ADescripcionArticulo: string):
  TDecisionDesactivacionWebArticulo;
var
  Identificacion: string;
  Respuesta: Integer;
begin
  Identificacion := Trim(ACodigoArticulo);
  if Trim(ADescripcionArticulo) <> '' then
    Identificacion := Identificacion + ' - ' +
      Trim(ADescripcionArticulo);
  Respuesta := MessageDlg_fza(
    Format(
      SPreguntaDesactivarArticuloPrestaShop,
      [Identificacion]),
    mtConfirmation,
    [mbYes, mbNo, mbCancel],
    0);
  case Respuesta of
    mrYes:
      Result := ddwDesactivarEnPrestaShop;
    mrNo:
      Result := ddwSoloDejarDeSincronizar;
  else
    Result := ddwCancelar;
  end;
end;

procedure TfrmMtoArticulos.PresentarValidacionDatosArticulo(
  const AMensaje: string; ACampo: TCampoValidacionArticulo);
begin
  ShowMessage_fza(AMensaje);
  pcPantalla.Properties.ActivePage := tsFicha;
  if ACampo = cvaNombre then
  begin
    if txtDESCRIPCION_ARTICULO.CanFocus then
      txtDESCRIPCION_ARTICULO.SetFocus;
  end
  else if ACampo = cvaTrazabilidad then
  begin
    pcDetail.ActivePage := tsGeneral;
    if Assigned(FTrazabilidadFicha) then
      FTrazabilidadFicha.Enfocar;
  end
  else
  begin
    if cbbFamilia.CanFocus then
      cbbFamilia.SetFocus;
  end;
end;

function TfrmMtoArticulos.IsShortCut(var Message: TWMKey): Boolean;
var
  Permitido: Boolean;
begin
  Result := (Message.CharCode = VK_F12) and
    (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
    (GetKeyState(VK_SHIFT) >= 0);
  if Result then
  begin
    Permitido := False;
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
      if dsTablaG.DataSet.State = dsInsert then
        Permitido := PuedeAccionMto(apmInsertar)
      else
        Permitido := PuedeAccionMto(apmModificar);
    if Permitido and Assigned(btnGrabar) and btnGrabar.Enabled then
    begin
      if tvTarifas.Controller.EditingController.IsEditing then
        tvTarifas.Controller.EditingController.HideEdit(True);
      btnGrabar.Click;
    end;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmMtoArticulos.btnGrabarClick(Sender: TObject);
var
  Resultado: TResultadoGuardadoArticulo;
  bReintentar: Boolean;
begin
  bReintentar := False;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
  begin
    chkEnWeb.PostEditValue;
    txtCODIGO_ARTICULO.PostEditValue;
    txtDESCRIPCION_ARTICULO.PostEditValue;
    cbbFamilia.PostEditValue;
  end;
  try
    try
      dmmArticulos.ValidarDatosArticulo;
      dmmArticulos.ValidarCodigoArticuloDisponible;
      dmmArticulos.PrepararCambioMarcaWeb;
      dmmArticulos.IniciarAplazamientoVisibilidadPrestaShop;
      FPropiedadesAltaPendientes := False;
      FErrorPropiedadesAlta := False;
      Resultado := FAplicacionGuardado.Ejecutar;
      case Resultado.Error of
        egaRevisionPropiedades:
          begin
            ShowMessage_fza(Format(
              SAvisoRevisionArticulo,
              [Resultado.Mensaje]));
            pcDetail.ActivePage := tsPropiedades;
          end;
        egaGuardadoPropiedades:
          ShowMessage_fza(Format(
            SErrorGuardarPropiedadesArticulo,
            [Resultado.Mensaje]));
        egaGuardadoVariaciones:
          if FErrorPropiedadesAlta then
            ShowMessage_fza(Format(
              SErrorGuardarPropiedadesArticulo,
              [Resultado.Mensaje]))
          else
            ShowMessage_fza(Format(
              SErrorGuardarVariacionesArticulo,
              [Resultado.Mensaje]));
      end;
      dmmArticulos.FinalizarVisibilidadPrestaShopAplazada(
        Resultado.Error = egaNinguno,
        Resultado.Mensaje);
      if Resultado.Error = egaNinguno then
        inherited;
    except
      on E: ECodigoArticuloDuplicado do
        bReintentar := AvisarCodigoArticuloDuplicado(E.Message);
      on E: EValidacionDatosArticulo do
        PresentarValidacionDatosArticulo(E.Message, E.Campo);
    end;
  finally
    dmmArticulos.DescartarVisibilidadPrestaShopAplazada;
    dmmArticulos.LimpiarCambioMarcaWebPreparado;
  end;
  // Con el código libre ya puesto se graba sin volver a pulsar Grabar. La
  // comprobación del código va antes de grabar nada.
  if bReintentar then
    btnGrabarClick(Sender);
end;

procedure TfrmMtoArticulos.btnNuevoArticuloClick(Sender: TObject);
begin
  inherited;
  if ( (dmmArticulos.unqryTablaG.State = dsInsert) or
       (dmmArticulos.unqryTablaG.State = dsEdit)) then
  begin
    dmmArticulos.unqryTablaG.Post;
  end;
  dmmArticulos.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
  tsFicha.SetFocus;
  txtCODIGO_ARTICULO.SetFocus;
end;

procedure TfrmMtoArticulos.btnStockExportarExcelClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxgrdStock, 'Stock_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.btnReconstruirStockClick(Sender: TObject);
begin
  inherited;
  FStock.Reconstruir(FArticuloCargado);
end;

procedure TfrmMtoArticulos.btnImprimirEtiquetasClick(Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if (not dsTablaG.Dataset.Active) or dsTablaG.Dataset.IsEmpty then
    ShowMessage_fza(SErrorArticuloNoSeleccionadoImprimirEtiquetas)
  else
  begin
    formulario := TfrmPrintEtiqArt.Create(Application);
    try
      formulario.DM := dmmArticulos;
      formulario.edtCodArt.Text := dsTablaG.Dataset.FieldByName(
        'CODIGO_ART_ART').AsString;
      formulario.ShowModal;
    finally
      FreeAndNil(formulario);
    end;
  end;
end;

procedure TfrmMtoArticulos.btnGenerarCBClick(Sender: TObject);
var
  sCodigoArticulo: string;
  bGenerado: Boolean;
  Resultado: TResultadoCodigosBarrasArticulo;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  sCodigoArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if sCodigoArticulo = '' then
    ShowMessage_fza(SErrorArticuloNoSeleccionadoGenerarCodigos)
  else if MessageDlg_fza(
    Format(SPreguntaGenerarCodigosBarras, ['21']),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      bGenerado := GenerarCodigosBarrasArticulo(
        FCodigosBarrasPersistencia,
        FDependencias.Variaciones,
        sCodigoArticulo,
        IdentidadSesion.Usuario,
        Resultado);
    finally
      Screen.Cursor := crDefault;
    end;
    if not bGenerado then
      ShowMessage_fza(SErrorArticuloSinSkusActivosGenerarCodigos)
    else
    begin
      dmmArticulos.unqryVariacionesArticulos.Close;
      dmmArticulos.unqryVariacionesArticulos.Open;
      ActualizarVisibilidadVariaciones;
      ShowMessage_fza(Format(
        SInfoGeneracionCodigosBarras,
        [Resultado.PrincipalesGenerados,
         Resultado.FilasFabricanteCreadas,
         Resultado.SkusSinCambios,
         Resultado.MarcadoresAntiguosEliminados]));
    end;
  end;
end;
procedure TfrmMtoArticulos.btnVerificarCBClick(Sender: TObject);
var
  sCodArticulo: string;
  oResumen: TResumenCodigosBarrasArticulo;
begin
  inherited;
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    dmmArticulos.unqryTablaG.Post;
  sCodArticulo :=
    dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if sCodArticulo = '' then
    ShowMessage_fza(SErrorArticuloNoSeleccionadoVerificarCodigos)
  else
  begin
    AsegurarSkuArticulo(sCodArticulo);
    oResumen := VerificarCodigosBarrasArticulo(
      FCodigosBarras.ListarCodigosBarras(sCodArticulo));
    if oResumen.Invalidos = 0 then
      ShowMessage_fza(Format(SInfoVerificacionCodigosBarrasCorrecta,
        [oResumen.Ean13Correctos, oResumen.Ean8Correctos,
         oResumen.Omitidos]))
    else
      ShowMessage_fza(Format(SAvisoVerificacionCodigosBarras,
        [oResumen.Ean13Correctos, oResumen.Ean8Correctos,
         oResumen.Invalidos, oResumen.Omitidos,
         oResumen.DetalleErrores]));
  end;
end;

// El articulo activo siempre viene de dsTablaG (CODIGO_ART_ART). El
// SKU activo depende de la pestana visible: cuando el usuario esta en
// la pestana 2_SKUs, 8_Stock o 9_Movimientos, la fila activa del
// sub-grid correspondiente lleva el CODIGO_UNIDAD_*; en otras pestanas
// no hay SKU activo y se trabaja a nivel articulo.
procedure TfrmMtoArticulos.ResolverArtSkuActivo(out ACodArt,
                                                ACodSku: string);

  function LeerSkuDeGrid(AGrid: TcxGridDBTableView): string;
  var
    ds: TDataSet;
  begin
    Result := '';
    if Assigned(AGrid.DataController.DataSource) then
    begin
      ds := AGrid.DataController.DataSource.DataSet;
      // Reutilizamos la lista canonica de aliases (CODIGO_UNIDAD_*).
      var sArt: string := '';
      inLibFotos.LeerArtSkuDeDataSet(ds, sArt, Result);
    end;
  end;

begin
  inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  // Si el inherited ya devolvio SKU (improbable en este Mto), no
  // tocamos. Si no, miramos la pestana activa.
  if ACodSku = '' then
  begin
    if pcDetail.ActivePage = tsSkuMto then
      ACodSku := LeerSkuDeGrid(tvSkuMto)
    else if pcDetail.ActivePage = cxTabSheet3 then
      ACodSku := LeerSkuDeGrid(tvStock)
    else if pcDetail.ActivePage = tsMovimientos then
      ACodSku := LeerSkuDeGrid(tvMovimientos);
  end;
end;

function TfrmMtoArticulos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  // El articulo viene de dsTablaG; el SKU puede venir de cualquiera
  // de los tres sub-grids segun la pestana activa. Enganchamos los
  // cuatro DataSources para que la pantalla flotante refresque al
  // navegar en cualquiera de ellos.
  Result := [dsTablaG,
             dmmArticulos.dsSkus,            // pestaña 2_SKUs
             dmmArticulos.dsStockArticulos,  // pestaña 8_Stock
             dmmArticulos.dsMovimientosArticulos]; // pestaña 9_Movimientos
end;


procedure TfrmMtoArticulos.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsGeneral;
end;

procedure TfrmMtoArticulos.BuscarProveedores;
begin
  if BusquedaVisual.EjecutarBusqueda(
    ConexionPrincipal,
    STituloBuscarProveedoresArticulos,
                                     dmmArticulos.unqryProveedores,
                                     'frmMtoArtProvSearch') then
    dmmArticulos.CopiarProveedoraArticulo(dmmArticulos.unqryProveedores);
end;

procedure TfrmMtoArticulos.cbbFamiliaPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if not FActualizandoFamiliaDesdeArbol then
    CargarPropiedadesFamiliaActual;
end;

procedure TfrmMtoArticulos.CargarPropiedadesFamiliaActual;
var
  oCampoFamilia: TField;
begin
  if Assigned(FGestorProp) and
     Assigned(dmmArticulos) and
     (dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    oCampoFamilia := dmmArticulos.unqryTablaG.FindField('CODIGO_FAM_ART');
    if Assigned(oCampoFamilia) and
       (not oCampoFamilia.IsNull) then
      FGestorProp.CargarPropiedadesPorFamilia(oCampoFamilia.AsString);
  end;
end;

procedure TfrmMtoArticulos.CambiarFamiliaArticulo(
  const ACodigoFamilia: string; ALimpiar: Boolean);
var
  bHayCambio: Boolean;
  oCampoFamilia: TField;
  oDatos: TDataSet;
begin
  oDatos := dmmArticulos.unqryTablaG;
  oCampoFamilia := oDatos.FieldByName('CODIGO_FAM_ART');
  if ALimpiar then
    bHayCambio := not oCampoFamilia.IsNull
  else
    bHayCambio := oCampoFamilia.IsNull or
      (oCampoFamilia.AsString <> ACodigoFamilia);
  if bHayCambio then
  begin
    if not (oDatos.State in [dsInsert, dsEdit]) then
      oDatos.Edit;
    if oDatos.State in [dsInsert, dsEdit] then
    begin
      FActualizandoFamiliaDesdeArbol := True;
      try
        if ALimpiar then
          oCampoFamilia.Clear
        else
          oCampoFamilia.AsString := ACodigoFamilia;
      finally
        FActualizandoFamiliaDesdeArbol := False;
      end;
      if not ALimpiar then
        CargarPropiedadesFamiliaActual;
    end;
  end;
end;

procedure TfrmMtoArticulos.btnSeleccionarFamiliaClick(Sender: TObject);
var
  oDatos: TDataSet;
  oModal: TfrmModalSelFamilia;
begin
  inherited;
  if Assigned(dmmArticulos) then
  begin
    oDatos := dmmArticulos.unqryTablaG;
    if oDatos.Active and
       (not oDatos.IsEmpty) and
       oDatos.CanModify then
    begin
      oModal := TfrmModalSelFamilia.Create(Self);
      try
        oModal.CodigoFamiliaInicial :=
          oDatos.FieldByName('CODIGO_FAM_ART').AsString;
        if oModal.ShowModal = mrOk then
          CambiarFamiliaArticulo(oModal.CodigoFamilia, False);
      finally
        FreeAndNil(oModal);
      end;
    end;
  end;
end;

procedure TfrmMtoArticulos.btnQuitarFamiliaClick(Sender: TObject);
var
  oDatos: TDataSet;
begin
  inherited;
  if Assigned(dmmArticulos) then
  begin
    oDatos := dmmArticulos.unqryTablaG;
    if oDatos.Active and
       (not oDatos.IsEmpty) and
       oDatos.CanModify then
      CambiarFamiliaArticulo('', True);
  end;
end;

procedure TfrmMtoArticulos.ConstruirTrazabilidadFicha;
var
  rActivacion: TActivacionTrazabilidad;
begin
  // La casilla «Trazable» se sustituye por el modo; sin interruptores
  // encendidos no se ve nada de F-LOTEC.
  rActivacion := TActivacionTrazabilidad.Apagada;
  if Assigned(ParametrosApp) then
    rActivacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  if not Assigned(FTrazabilidadFicha) then
    FTrazabilidadFicha := TFichaTrazabilidadArticuloVcl.CreateFicha(Self,
      chkESTRAZABLE_ART.Parent, chkESTRAZABLE_ART, dsTablaG, rActivacion);
  if rActivacion.AlgunModoActivo and not Assigned(FLotesFicha) then
  begin
    ConstruirLotesFicha(rActivacion);
    AnadirColumnaLoteCodigos;
  end;
end;

procedure TfrmMtoArticulos.ConstruirLotesFicha(
  const AActivacion: TActivacionTrazabilidad);
var
  oRepositorio: IRepositorioLotes;
begin
  oRepositorio := CrearRepositorioLotesUniDAC(ConexionPrincipal);
  FLotesFicha := TPestanaLotesArticuloVcl.CreatePestana(Self, pcDetail,
    AActivacion, CrearConsultaLotesArticuloUniDAC(ConexionPrincipal),
    oRepositorio, CrearSelectorLotesVisual(Self, oRepositorio,
      procedure(AMovimiento: string)
      begin
        ReimprimirRetiradaLote(AMovimiento);
      end),
    IdentidadSesion.Usuario,
    ParametrosApp.GetInt(PARAMETRO_CADUCIDAD_DIAS_AVISO,
                         CADUCIDAD_DIAS_AVISO_DEFECTO));
  FLotesFicha.AlRetirar :=
    procedure(ALotes: TArray<TLoteArticulo>)
    begin
      RetirarLotesFicha(ALotes);
    end;
  FLotesFicha.AlImprimirEtiqueta :=
    procedure(ALote: TLoteArticulo)
    begin
      ImprimirEtiquetaLote(ALote);
    end;
end;

// F-LOTEC-022: etiquetas del lote o serie enfocado en la pestaña Lotes /
// Series: una por unidad en stock de esa fila (una si es serie o no hay).
procedure TfrmMtoArticulos.RetirarLotesFicha(
  const ALotes: TArray<TLoteArticulo>);
var
  Orden: TOrdenRetiradaLotes;
  Lote: TLoteArticulo;
  Linea: TLineaRetiradaLote;
begin
  if PuedeAccionMto(apmModificar) then
  begin
    Orden := Default(TOrdenRetiradaLotes);
    Orden.Empresa := UbicacionSesion.Empresa;
    Orden.Usuario := IdentidadSesion.Usuario;
    Orden.Empleado := Orden.Usuario;
    Orden.EsUrgente := True;
    for Lote in ALotes do
    begin
      Linea := Default(TLineaRetiradaLote);
      Linea.CodigoSku := Lote.CodigoSku;
      Linea.Lote := Lote.Lote;
      Linea.CodigoAlmacen := Lote.CodigoAlmacen;
      Linea.Cantidad := Lote.Stock;
      Orden.Lineas := Orden.Lineas + [Linea];
    end;
    if TfrmModalRetiradaLotes.Ejecutar(Self, ConexionPrincipal, Orden) then
      RefrescarLotesFicha;
  end;
end;

procedure TfrmMtoArticulos.ReimprimirRetiradaLote(
  const AMovimiento: string);
begin
  if PuedeImprimir then
    TfrmModalRetiradaLotes.Reimprimir(Self, ConexionPrincipal,
      UbicacionSesion.Empresa, AMovimiento);
end;

procedure TfrmMtoArticulos.ImprimirEtiquetaLote(const ALote: TLoteArticulo);
begin
  MostrarEtiquetasLotes([LoteEtiquetaDeArticulo(ALote)],
    Format(STituloEtiquetasLote, [ALote.Lote]),
    ALote.CodigoSku + ' · ' + ALote.Lote);
end;

// Pestaña 4_CB: lote o serie de los códigos por unidad o por lote (783).
procedure TfrmMtoArticulos.AnadirColumnaLoteCodigos;
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := tvSkus.CreateColumn;
  oColumna.Name := 'tvSkusLOTE_CB';
  oColumna.Caption := SCaptionColumnaLoteSerie;
  oColumna.DataBinding.FieldName := 'LOTE_CB';
  oColumna.Options.Editing := False;
  oColumna.Width := tvSkusTIPO_CODIGO_CB.Width + 20;
  ColocarColumnaLoteCodigos;
end;

// Junto al código de barras: al final de la rejilla (tras Etiqueta y Stock
// total) quedaba fuera de la vista con los anchos de siempre. Se repite
// tras aplicar el perfil, que recoloca las columnas que tiene guardadas.
procedure TfrmMtoArticulos.ColocarColumnaLoteCodigos;
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := tvSkus.GetColumnByFieldName('LOTE_CB');
  if Assigned(oColumna) then
    oColumna.Index := tvSkusCODIGO_BARRAS_CB.Index + 1;
end;

procedure TfrmMtoArticulos.RefrescarLotesFicha;
var
  iDiasAviso: Integer;
  oArticulo: TDataSet;
begin
  if Assigned(FLotesFicha) and Assigned(dmmArticulos) and
     (pcDetail.ActivePage = FLotesFicha.Pestana) and
     dmmArticulos.unqryTablaG.Active then
  begin
    oArticulo := dmmArticulos.unqryTablaG;
    iDiasAviso := DIAS_AVISO_SIN_VALOR;
    if not oArticulo.FieldByName('DIAS_AVISO_CADUCIDAD_ART').IsNull then
      iDiasAviso :=
        oArticulo.FieldByName('DIAS_AVISO_CADUCIDAD_ART').AsInteger;
    FLotesFicha.Cargar(oArticulo.FieldByName('CODIGO_ART_ART').AsString,
      oArticulo.FieldByName('DESCRIPCION_ART').AsString,
      ModoDesdeCadena(
        oArticulo.FieldByName('TIPO_TRAZABILIDAD_ART').AsString),
      iDiasAviso, Date,
      oArticulo.FieldByName('ESCADUCIDAD_ART').AsString = 'S');
  end;
end;

procedure TfrmMtoArticulos.SolicitarDatosFormulaAlta(Sender: TObject);
var
  Formula, Modelo, Proveedor: string;
  Preguntas, Valores: TArray<string>;
  UsaModelo, UsaProveedor: Boolean;
  IndiceProveedor: Integer;
begin
  // Cada alta comienza sin los valores visuales del artículo anterior.
  if Assigned(FGestorProp) then
    FGestorProp.CargarPropiedades('');
  FArticuloCargado := '';
  Formula := dmmArticulos.FormulaCodigoArticulo;
  UsaModelo := TFormulaCodigoArticuloSesion.UsaModeloProveedor(Formula);
  UsaProveedor := TFormulaCodigoArticuloSesion.UsaCodigoProveedor(Formula);
  if UsaModelo or UsaProveedor then
  begin
    SetLength(Preguntas, Ord(UsaModelo) + Ord(UsaProveedor));
    SetLength(Valores, Length(Preguntas));
    if UsaModelo then
      Preguntas[0] := SPreguntaModeloProveedorAltaArticulo;
    IndiceProveedor := Ord(UsaModelo);
    if UsaProveedor then
      Preguntas[IndiceProveedor] := SPreguntaCodigoProveedorAltaArticulo;
    if not InputQuery_fza(Caption, Preguntas, Valores,
      function(const AValores: array of string): Boolean
      var
        Valor: string;
      begin
        Result := True;
        for Valor in AValores do
          Result := Result and (Trim(Valor) <> '');
        if not Result then
          ShowMessage_fza(SErrorFormulaCodigoArticuloDatos);
        if Result and UsaProveedor then
        begin
          try
            dmmArticulos.ValidarProveedorCodigoAlta(
              AValores[IndiceProveedor]);
          except
            on E: EValidacionBBDD do
            begin
              Result := False;
              ShowMessage_fza(E.Message);
            end;
          end;
        end;
      end) then
      Abort;
    Modelo := '';
    Proveedor := '';
    if UsaModelo then
      Modelo := Valores[0];
    if UsaProveedor then
      Proveedor := Valores[IndiceProveedor];
    dmmArticulos.AsignarDatosCodigoAlta(Modelo, Proveedor);
  end;
end;

procedure TfrmMtoArticulos.CrearTablaPrincipal;
begin
  FDependencias.Validar;
  inherited;
  dmmArticulos := tdmDataModule as TdmArticulos;
  dmmArticulos.OnPrepararAlta := SolicitarDatosFormulaAlta;
  dmmArticulos.OnValidacionDatosArticulo := PresentarValidacionDatosArticulo;
  FPuedeCambiarMarcaWeb := Assigned(Permisos) and
    Permisos.TienePermiso(
      PERMISO_ARTICULOS_ACTIVAR_DESACTIVAR_WEB,
      paDenegar);
  chkEnWeb.Properties.ReadOnly := not FPuedeCambiarMarcaWeb;
  dmmArticulos.AsignarPermisoCambioMarcaWeb(
    FPuedeCambiarMarcaWeb);
  dmmArticulos.AsignarConfirmacionDesactivacionWeb(
    ConfirmarDesactivacionWebArticulo);
  dmmArticulos.OnCodigoBarrasRepetido := AvisarCodigoBarrasRepetido;
  dmmArticulos.OnCodigoBarrasGs1 := AvisarCodigoBarrasGs1;
  FCodigosBarrasPersistencia :=
    CrearArticulosCodigosBarrasPersistenciaUniDAC(ConexionPrincipal);
  pmColorSkus.OnPopup := AjustarMenuColorSkus;
  FResolutorDestinoFactura :=
    CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal);
  // La vista de stock se empuja al DM (ya no la busca con GetOwnerForm).
  dmmArticulos.AsignarVistaStock(tvStock);
  cbbFamilia.Properties.ListSource := dmmArticulos.dsFamiliaArticulos;
  cbbTipoCantidad.Properties.ListSource := dmmArticulos.dsUnidadesMedidaLookup;
  tvTarifas.DataController.DataSource := dmmArticulos.dsTarifasArticulos;
  tvComprasTarifas.DataController.DataSource :=
    dmmArticulos.dsUltimasComprasProveedor;
  // Botón derecho con las columnas, como en la lista. Lo libera Self.
  TMenuColumnasRejilla.Create(Self, cxgrdTarifas, tvTarifas);
  tvProveedores.DataController.DataSource :=
                                            dmmArticulos.dsProveedoresArticulos;
  tvLinFac.DataController.DataSource := dmmArticulos.dsLinFacturasArticulos;
  tvSkus.DataController.DataSource := dmmArticulos.dsVariacionesArticulos;
  tvStock.DataController.DataSource := dmmArticulos.dsStockArticulos;
  // Estos cuatro grids/lookup vienen cableados en el DFM contra el componente
  // 'dmArticulos'. Con varias pestañas de Articulos abiertas la VCL resuelve
  // ese nombre al PRIMER data module creado, asi que la segunda pestaña
  // mostraba los SKUs / atributos / movimientos del articulo de la primera.
  // Los rebindeamos a la instancia local del Mto.
  tvSkuMto.DataController.DataSource := dmmArticulos.dsSkus;
  tvSkuAtributosBasicos.DataController.DataSource :=
                                            dmmArticulos.dsDetallesAtributos;
  (tvSkuAtributosBasicosID_ATB_AV.Properties as TcxLookupComboBoxProperties)
                          .ListSource := dmmArticulos.dsAtributosBasicosLookup;
  tvMovimientos.DataController.DataSource :=
    dmmArticulos.dsMovimientosArticulos;
  pkFieldName := 'CODIGO_ART_ART';
  ConstruirTrazabilidadFicha;
  dmmArticulos.unqryTablaG.AfterScroll := OnAfterScrollArticulos;
  // Carga perezosa de Tarifas: solo abrir unqryTarifasArticulos cuando
  // el usuario pase a esa pestaña. Asi quitamos los ~6s de la
  // apertura inicial del Mto.
  pcDetail.OnChange := PcDetailChange;
  InicializarPestanyaPropiedades;
  InicializarPestanyaVariaciones;
  InicializarPresentadores;
  InicializarGuardadoArticuloVcl(Self);
  // Filtros de carga (estado, stock, temporadas): poblar la lista de
  // temporadas, leer las preferencias guardadas por usuario y aplicar
  // el filtro parametrizado antes de que el resto de
  // la rutina lea FArticuloCargado / el primer registro.
  FPresFiltros.Colapsar;
  FPresFiltros.CargarTemporadas;
  FPresFiltros.LeerPerfil(oPerfilDic);
  // Precarga: DE MOMENTO sin dialogo de acotado. Dejamos la lista CERRADA
  // con el filtro aplicado (por defecto solo activos) y que la carga la haga
  // AbrirTablaPrincipalAsync en segundo plano, mostrando el overlay
  // "Cargando datos..." con barra de progreso.
  FPresFiltros.AplicarFiltroEnLista;
  // Foto del articulo (o del SKU de la pestana activa) bajo el icono de
  // la barra derecha; sigue al registro y abre el visor igual que Ctrl+F.
  if not Assigned(FMiniaturaFoto) and Assigned(FotosArticulos) then
    FMiniaturaFoto := TMiniaturaFotoMto.Create(Self, pButtonRightBar,
      pButtonBDStat, FotosArticulos, ResolverArtSkuActivo,
      DataSourcesParaFoto, actFotoArticulo);
  // Botones «Añadir» y «Borrar» sobre las rejillas de detalle, además
  // de los «+» y «-» del navegador.
  AnadirBotonesDetalle(tvSkus);
  AnadirBotonesDetalle(tvSkuMto);
  AnadirBotonesDetalle(tvTarifas);
  AnadirBotonesDetalle(tvProveedores);
end;

procedure TfrmMtoArticulos.InicializarPresentadores;
// Raiz de composicion de la pantalla: aqui se resuelven los adaptadores
// UniDAC y se inyectan a cada colaborador. Las lambdas capturan el data
// module (oDatos), no el formulario, salvo los dos avisos de vista.
var
  oControlesFiltro: TControlesFiltroCargaArticulos;
  oContextoStock: TContextoStockArticuloVcl;
  oDatos: TdmArticulos;
begin
  oDatos := dmmArticulos;
  FCodigosBarras :=
    CrearLecturaCodigosBarrasArticuloUniDAC(ConexionPrincipal);
  FPresAtributos := TPresentadorAtributosBasicosArticulo.Create(
    oDatos.unqryDetallesAtributos,
    oDatos.unqryAtributosBasicosLookup,
    oDatos.unqrySkus,
    TGestorAtributosBasicosSku.Create(
      TRepositorioAtributosBasicosSku.Create(ConexionPrincipal)),
    IdentidadSesion.Usuario,
    function(const ACodArt, AColor, AActivo: string): Integer
    begin
      Result := oDatos.ActualizarSkusColorActivo(ACodArt, AColor, AActivo);
    end);
  FPresAtributos.PrepararListaBasicos(
    tvSkuAtributosBasicosID_ATB_AV.Properties as TcxLookupComboBoxProperties);
  oContextoStock := Default(TContextoStockArticuloVcl);
  oContextoStock.Vista := tvStock;
  oContextoStock.Conexion := ConexionPrincipal;
  oContextoStock.Articulos := oDatos.unqryTablaG;
  oContextoStock.ConsultaStock := oDatos.unqryStockArticulos;
  oContextoStock.Recargar :=
    procedure
    begin
      oDatos.unqryStockArticulosAfterScroll(oDatos.unqryTablaG);
    end;
  oContextoStock.Reconstruir :=
    function: string
    begin
      Result := oDatos.ReconstruirStock;
    end;
  oContextoStock.PreguntaReconstruir := SPreguntaReconstruirStock;
  oContextoStock.TituloReconstruir := STituloReconstruirStock;
  oContextoStock.ErrorReconstruir := SErrorReconstruirStock;
  oContextoStock.InfoReconstruido := SInfoStockReconstruido;
  FStock := TCoordinadorStockArticuloVcl.Create(oContextoStock);
  tvStock.OnDblClick := tvStockDblClickPendiente;
  FPresTarifas := TPresentadorTarifasArticulo.Create(
    oDatos.unqryTarifasArticulos,
    tvTarifas,
    dbcTarifasPRECIOSALIDA,
    ConexionPrincipal,
    CrearCatalogoAltaTarifasArticuloUniDAC(ConexionPrincipal),
    function(const ACodArt, ACodTar: string): Double
    begin
      Result := oDatos.ObtenerPrecioTarifaPadre(ACodArt, ACodTar);
    end,
    procedure(ALista: TcxListView)
    begin
      oDatos.FillTarifas(ALista);
    end,
    procedure
    begin
      ActualizarVisibilidadColumnaSku;
    end,
    FDependencias.Margen,
    ModoMargenTarifas);
  dbcTarifasMARGEN.Caption := FPresTarifas.CaptionColumnaMargen;
  oControlesFiltro.Estado := cbbFiltroEstadoArt;
  oControlesFiltro.ConStock := chkFiltroConStockArt;
  oControlesFiltro.Temporadas := ccbFiltroTemporadaArt;
  oControlesFiltro.Persiana := pnlFiltrosArt;
  oControlesFiltro.Contenido := pnlContFiltrosArt;
  oControlesFiltro.Cabecera := btnToggleFiltrosArt;
  FPresFiltros := TPresentadorFiltrosArticulos.Create(
    oControlesFiltro,
    CrearRepositorioFiltroArticulosUniDAC(ConexionPrincipal),
    CrearListaArticulosPantallaUniDAC(oDatos.unqryTablaG),
    CrearEscrituraPrecargaArticulosUniDAC(
      ConexionPrincipal, PerfilesEscritura),
    procedure
    begin
      AbrirTablaPrincipalAsync;
    end);
end;

procedure TfrmMtoArticulos.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                     const sPermisos: string);
begin
  // Los filtros de carga se vuelcan al batch del sbGrabarGridClick para
  // grabarse junto con el resto de preferencias del Mto.
  if Assigned(FPresFiltros) then
    FPresFiltros.VolcarPerfil(oList, sPermisos, Self.Name);
end;

procedure TfrmMtoArticulos.TrasPrecargaAsync;
begin
  inherited;
  // Dialogo de precarga DESACTIVADO de momento: la lista se carga entera
  // (overlay con barra de progreso). El Open async corre con
  // DisableControls (el AfterScroll en el hilo de trabajo se autoexcluye),
  // asi que este es el punto canonico donde queda cargada la ficha del
  // registro actual. El escudo de OnAfterScrollArticulos evita recargarla
  // si RestaurarFocoGrid ya la fijo o si el articulo no cambio.
  if dmmArticulos.unqryTablaG.Active
     and (not dmmArticulos.unqryTablaG.IsEmpty) then
    OnAfterScrollArticulos(dmmArticulos.unqryTablaG);
end;

procedure TfrmMtoArticulos.PrepararBusquedaExterna(const ABusq: string);
begin
  // Búsqueda externa (Ctrl+R desde otro Mto): sin filtros de carga
  // para que salgan todos los artículos. Resetear controles y SQL
  // antes de que inherited añada el WHERE de búsqueda vía parser.
  if Assigned(FPresFiltros) then
    FPresFiltros.ReiniciarParaBusquedaExterna;
  inherited;
end;

procedure TfrmMtoArticulos.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  // Precarga: oculta el panel de Filtros de carga (cabecera + contenido).
  // En instancia 1 ya viene precargado el articulo concreto de la busqueda,
  // no tiene sentido permitir reabrir la lista con otros filtros.
  pnlFiltrosArt.Visible := False;
end;

procedure TfrmMtoArticulos.btnToggleFiltrosArtClick(Sender: TObject);
begin
  FPresFiltros.AlternarPersiana;
end;

procedure TfrmMtoArticulos.cbbFiltroEstadoArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  // Aplicamos el filtro inmediatamente, pero NO persistimos: la grabacion
  // a fza_usuarios_perfiles se hace explicitamente desde sbGrabarGridClick
  // (mismo patron que el resto de ajustes del Mto: ancho de columnas,
  // captions, etc.).
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.chkFiltroConStockArtPropertiesEditValueChanged(
                                                              Sender: TObject);
begin
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.ccbFiltroTemporadaArtPropertiesCloseUp(
                                                              Sender: TObject);
begin
  if not FPresFiltros.Cargando then
    FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.btnCargarAhoraArtClick(Sender: TObject);
begin
  // Dispara la carga de la lista con los filtros actuales del panel
  // (estado/stock/temporadas) de forma explicita, sin depender del
  // auto-aplicado al cerrar el desplegable de temporadas.
  FPresFiltros.AplicarFiltros;
end;

procedure TfrmMtoArticulos.btnGuardarPrecargaArtClick(Sender: TObject);
begin
  FPresFiltros.GuardarPrecarga(Application, Self.Name);
end;

procedure TfrmMtoArticulos.InicializarPestanyaPropiedades;
var
  pnlTop: TPanel;
begin
  // Ocultar el grid estático si existe en el DFM

  // Panel superior con botón "+ Añadir propiedad"
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent     := tsPropiedades;
  pnlTop.Align      := alTop;
  pnlTop.Height     := 36;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color      := tsPropiedades.Color;

  FBtnAddProp := TcxButton.Create(Self);
  FBtnAddProp.Parent  := pnlTop;
  FBtnAddProp.Caption := SCaptionAnadirPropiedad;
  FBtnAddProp.Left    := 8;
  FBtnAddProp.Top     := 4;
  FBtnAddProp.Width   := 200;
  FBtnAddProp.Height  := 26;
  FBtnAddProp.OnClick := BtnAddPropClick;   // ver punto 7

  // ScrollBox que ocupa el resto de la pestaña
  FScrollProp := TcxScrollBox.Create(Self);
  FScrollProp.Parent      := tsPropiedades;
  FScrollProp.Align       := alClient;
  FScrollProp.BorderStyle := cxcbsNone;

  // Crear el gestor
  FGestorProp := TGestorPropiedades.Create(
    FScrollProp,
    FDependencias.Propiedades,
    IdentidadSesion.Usuario
  );
end;

procedure TfrmMtoArticulos.InicializarPestanyaVariaciones;
var
  lbl     : TcxLabel;
begin

  // ── Zona de variaciones: un único panel inferior con su divisor ──
  // El divisor (arrastrar para encoger, zona central para minimizar)
  // deja ver el resto de la pestaña General en pantallas pequeñas.
  FVariacionesMinimizadas := False;
  FPnlVariaciones := TPanel.Create(Self);
  FPnlVariaciones.Parent     := tsGeneral;
  FPnlVariaciones.Align      := alBottom;
  FPnlVariaciones.Height     := 160;
  FPnlVariaciones.BevelOuter := bvNone;
  FPnlVariaciones.Caption    := '';

  FSplVariaciones := TcxSplitter.Create(Self);
  FSplVariaciones.Parent           := tsGeneral;
  FSplVariaciones.Height           := 8;
  FSplVariaciones.AlignSplitter    := salBottom;
  FSplVariaciones.HotZoneClassName := 'TcxMediaPlayer9Style';
  // Al encoger queda, como mínimo, la fila del tipo de variación.
  FSplVariaciones.MinSize          := 40;
  FSplVariaciones.Control          := FPnlVariaciones;

  // ── Panel superior con label + combo de tipo variación ──
  FPnlTopVariaciones := TPanel.Create(Self);
  FPnlTopVariaciones.Parent     := FPnlVariaciones;
  FPnlTopVariaciones.Align      := alTop;
  FPnlTopVariaciones.Height     := 40;
  FPnlTopVariaciones.BevelOuter := bvNone;
  FPnlTopVariaciones.Caption    := '';

  lbl := TcxLabel.Create(Self);
  lbl.Parent  := FPnlTopVariaciones;
  lbl.Transparent := True;
  lbl.Left    := 8;
  lbl.Top     := 10;
  lbl.Caption := SCaptionTipoVariacion;
  lbl.AutoSize:= True;

  // Combo enlazado al campo TIPO_VARIACION_ART del dataset principal
  FCbbTipoVariacion := TcxDBLookupComboBox.Create(Self);
  FCbbTipoVariacion.Parent          := FPnlTopVariaciones;
  FCbbTipoVariacion.Left            := 170;
  FCbbTipoVariacion.Top             := 6;
  FCbbTipoVariacion.Width           := 260;
  FCbbTipoVariacion.Height          := 26;
  FCbbTipoVariacion.DataBinding.DataSource := dsTablaG;
  FCbbTipoVariacion.DataBinding.DataField  := 'TIPO_VARIACION_ART';
  // ListSource apunta a un dataset con las variaciones activas
  FCbbTipoVariacion.Properties.ListSource     := dmmArticulos.dsVariaciones;
  FCbbTipoVariacion.Properties.KeyFieldNames  := 'CODIGO_VAR';
  FCbbTipoVariacion.Properties.ListFieldNames := 'NOMBRE_VAR';
  // FZ-ISSUE-444: editable tambien al navegar, como el resto de la
  // ficha; con SKU generados el cambio se rechaza al grabar.
  FCbbTipoVariacion.Properties.ReadOnly       := False;
  FCbbTipoVariacion.Properties.ListOptions.ShowHeader := False;
  FCbbTipoVariacion.Properties.OnEditValueChanged :=
    TipoVariacionEditValueChanged;
  // ── Zona atributos (scroll) ──
  FScrollVarAtrib := TScrollBox.Create(Self);
  FScrollVarAtrib.Parent      := FPnlVariaciones;
  FScrollVarAtrib.Align       := alClient;
  FScrollVarAtrib.BorderStyle := bsNone;
  FScrollVarAtrib.Color       := clWindow;
  FScrollVarAtrib.AutoScroll  := True;


  FGestorVar := TGestorVariaciones.Create(
    FScrollVarAtrib,
//    FScrollVarSkus,
    FDependencias.Variaciones,
    IdentidadSesion.Usuario
  );
end;

procedure TfrmMtoArticulos.BtnAddPropClick(Sender: TObject);
begin
  // Si hay cambios no guardados en el artículo, grabar primero
  if (dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit]) then
    dmmArticulos.unqryTablaG.Post;

  // Tras el alta el gestor aún tiene el código vacío (no ha habido
  // AfterScroll): se le da el grabado, sin recargar lo que hay en pantalla.
  if Assigned(FGestorProp) then
  begin
    if not dmmArticulos.unqryTablaG.IsEmpty then
      FGestorProp.AsignarCodigoArticulo(
        dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART').AsString);
    FGestorProp.AbrirSelectorPropiedades;
  end;
end;

procedure TfrmMtoArticulos.OnAfterScrollArticulos(DataSet: TDataSet);
var
  CodArticulo: string;
  swTotal, swTramo: TStopwatch;
  msCargarProp, msCargarVar, msActVisVar, msAseguraSku,
  msRefSkus, msRefVarArt, msMapaAtr, msStockAS, msActVisCol: Int64;
  bProcesar: Boolean;
begin
  bProcesar := not DataSet.ControlsDisabled and
    dmmArticulos.unqrySkus.Active;
  if bProcesar then
    RefrescarLotesFicha;
  // 1. Si estamos creando un artículo nuevo, limpiamos la pantalla una sola vez
  // y salimos
  if bProcesar and (DataSet.State = dsInsert) then
  begin
    dmmArticulos.unqryUltimasComprasProveedor.Close;
    if Assigned(FStock) then
      FStock.AsegurarAlDia('');
    if FArticuloCargado <> '' then
    begin
      FArticuloCargado := ''; // Marcamos como vacío
      if Assigned(FGestorProp) then
        FGestorProp.CargarPropiedades('');
      if Assigned(FGestorVar) then
        FGestorVar.CargarVariaciones('');
      ActualizarVisibilidadVariaciones;
    end;
    bProcesar := False;
  end;
  // 2. Si estamos editando, ignoramos los scrolls fantasma
  if bProcesar and (DataSet.State = dsEdit) then
    bProcesar := False;
  CodArticulo := '';
  if bProcesar then
    CodArticulo := DataSet.FieldByName('CODIGO_ART_ART').AsString;
  // 3. EL ESCUDO: Si el artículo es exactamente el mismo que ya está dibujado,
  // ¡no hagas nada!
  if bProcesar and (FArticuloCargado = CodArticulo) then
    bProcesar := False;
  if bProcesar then
  begin
  // Actualizamos nuestra memoria
  FArticuloCargado := CodArticulo;

  // [PERF] Cronometros por tramo. Este handler es el sospechoso principal
  // de los gaps de 5s que se ven al abrir/navegar Articulos. Cada
  // sub-tarea se mide independientemente y se vuelca al log+memo SQL.
  swTotal := TStopwatch.StartNew;
  msCargarProp := 0;
  msCargarVar := 0;
  msMapaAtr := 0;

  // 4. Ahora sí, cargamos la interfaz visual de forma segura
  if Assigned(FGestorProp) then
  begin
    swTramo := TStopwatch.StartNew;
    FGestorProp.CargarPropiedades(CodArticulo);
    msCargarProp := swTramo.ElapsedMilliseconds;
  end;

  if Assigned(FGestorVar) then
  begin
    swTramo := TStopwatch.StartNew;
    FGestorVar.CargarVariaciones(CodArticulo);
    msCargarVar := swTramo.ElapsedMilliseconds;
  end;

  swTramo := TStopwatch.StartNew;
  ActualizarVisibilidadVariaciones;
  msActVisVar := swTramo.ElapsedMilliseconds;

  // Si el artículo no tiene variaciones, garantizamos un SKU = código artículo
  // para que la rejilla SKUs y CB tenga al menos una fila editable
  swTramo := TStopwatch.StartNew;
  AsegurarSkuArticuloSinVariaciones(CodArticulo);
  msAseguraSku := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  dmmArticulos.unqrySkus.Refresh;
  msRefSkus := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  dmmArticulos.unqryVariacionesArticulos.Refresh;
  msRefVarArt := swTramo.ElapsedMilliseconds;

  // Refrescamos el mapa NOMBRE_ATRIBUTO -> ID_VA ANTES de
  // unqryStockArticulosAfterScroll: el bestfit que hace ese metodo necesita
  // saber qué columnas pintaran swatch para reservarles el ancho del
  // cuadradito.
  if Assigned(FStock) then
  begin
    swTramo := TStopwatch.StartNew;
    FStock.CargarMapaArticulo(CodArticulo);
    msMapaAtr := swTramo.ElapsedMilliseconds;
  end;

  // Stock perezoso: solo recargar el SP si la pestaña Stock esta
  // visible. El coordinador evita reejecutar si el articulo
  // no ha cambiado.
  swTramo := TStopwatch.StartNew;
  if pcDetail.ActivePage = cxTabSheet3 then
    FStock.AsegurarAlDia(CodArticulo);
  msStockAS := swTramo.ElapsedMilliseconds;

  // Recargar los costes del artículo actual en la pestaña visible.
  ActualizarCargaTarifas;

  swTramo := TStopwatch.StartNew;
  ActualizarVisibilidadColumnaSku;
  msActVisCol := swTramo.ElapsedMilliseconds;

  RegistroLog.RegistrarRendimiento('Articulos.AfterScroll',
    Format('art=%s | Prop=%d | Var=%d | ActVar=%d | Sku=%d | RefSkus=%d | ' +
           'RefVarArt=%d | MapaAtr=%d | StockAS=%d | ActColSku=%d',
           [CodArticulo, msCargarProp, msCargarVar, msActVisVar,
            msAseguraSku, msRefSkus, msRefVarArt, msMapaAtr, msStockAS,
            msActVisCol]),
    swTotal.ElapsedMilliseconds);
  end;
end;

procedure TfrmMtoArticulos.cxButton11Click(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  ExportarExcel(ParametrosApp, cxGrdMovimientos,
                'Movimientos_Artículo_' +
                dsTablaG.Dataset.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TfrmMtoArticulos.cxDBComboBox1PropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) and Assigned(dmmArticulos) and
     Assigned(dmmArticulos.unqryTablaG) and
     dmmArticulos.unqryTablaG.Active then
    ActualizarVisibilidadVariaciones;
end;

procedure TfrmMtoArticulos.cxDBCheckBox1PropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) and Assigned(dmmArticulos) and
     Assigned(dmmArticulos.unqryTablaG) and
     dmmArticulos.unqryTablaG.Active and
     not dmmArticulos.unqryTablaG.IsEmpty and
     not dmmArticulos.unqryTablaG.ControlsDisabled and
     (dmmArticulos.unqryTablaG.State in [dsEdit, dsInsert]) then
  begin
    // El Focus garantiza que el evento lo ha disparado el usuario y no un
    // refresco del dataset
    if (Sender as TcxDBCheckBox).Focused then
    begin
      (Sender as TcxDBCheckBox).PostEditValue;
      ActualizarVisibilidadVariaciones;
    end;
  end;
end;

procedure
    TfrmMtoArticulos.cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  inherited;
  BuscarProveedores;
end;

procedure TfrmMtoArticulos.
                          dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePorcentajeDto(Sender);
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOFINALPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioFinal(Sender);
end;

procedure TfrmMtoArticulos.dbcTarifasPRECIOSALIDAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioSalida(Sender);
end;

procedure TfrmMtoArticulos.
                          dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FPresTarifas.RecalcularDesdePrecioDto(Sender);
end;

procedure TfrmMtoArticulos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.state = dsInsert) then
  begin
    txtCODIGO_ARTICULO.Properties.ReadOnly := False;
    // Alta desde la lista o el navegador: el BeforeInsert ya ha llevado a
    // la Ficha y tsFichaShow enfoca el primer control; aquí se corrige al
    // Código, que es lo primero que se teclea en un artículo nuevo.
    if (pcPantalla.ActivePage = tsFicha) and
       txtCODIGO_ARTICULO.CanFocus then
      txtCODIGO_ARTICULO.SetFocus;
  end
  else
  begin
    txtCODIGO_ARTICULO.Properties.ReadOnly := True;
  end;
end;

procedure TfrmMtoArticulos.txtCODIGO_ARTICULOExit(Sender: TObject);
begin
  inherited;
  // Código repetido: en un alta se avisa al salir del campo, antes de
  // rellenar el resto de la ficha (al grabar se vuelve a comprobar). Solo si
  // el foco sigue en la ficha: Cancelar, Salir o la lista no deben quedar
  // atrapados por el aviso. Se difiere para no abrir el mensaje ni devolver
  // el foco en mitad del cambio de foco del editor.
  if AltaArticuloEnCurso and
     Assigned(Screen.ActiveControl) and
     tsFicha.ContainsControl(Screen.ActiveControl) then
  begin
    TThread.RemoveQueuedEvents(ComprobarCodigoArticuloDiferido);
    TThread.ForceQueue(nil, ComprobarCodigoArticuloDiferido);
  end;
end;

function TfrmMtoArticulos.AltaArticuloEnCurso: Boolean;
begin
  Result := not (csDestroying in ComponentState) and
            Assigned(dmmArticulos) and
            (dmmArticulos.unqryTablaG.State = dsInsert);
end;

// FZ-ISSUE-201: el articulo de la ficha, no FArticuloCargado. Grabar un
// alta no dispara AfterScroll y FArticuloCargado se queda vacio: la
// pestana Stock seguia con la consulta del ultimo articulo cargado.
function TfrmMtoArticulos.CodigoArticuloStock: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmArticulos) then
  begin
    ds := dmmArticulos.unqryTablaG;
    if ds.Active and (not ds.IsEmpty) and (ds.State <> dsInsert) then
      Result := ds.FieldByName('CODIGO_ART_ART').AsString;
  end;
end;

procedure TfrmMtoArticulos.ComprobarCodigoArticuloDiferido;
begin
  if AltaArticuloEnCurso then
  begin
    try
      dmmArticulos.ValidarCodigoArticuloDisponible;
    except
      on E: ECodigoArticuloDuplicado do
        AvisarCodigoArticuloDuplicado(E.Message);
    end;
  end;
end;

function TfrmMtoArticulos.AvisarCodigoArticuloDuplicado(
  const AMensaje: string): Boolean;
var
  fCodigo: TField;
  sCodigo, sLibre: string;
begin
  Result := False;
  // FZ-ISSUE-172: se ofrece el siguiente código libre.
  fCodigo := dmmArticulos.unqryTablaG.FieldByName('CODIGO_ART_ART');
  sCodigo := SinBarraSku(Trim(fCodigo.AsString));
  sLibre := '';
  if dmmArticulos.unqryTablaG.State in [dsInsert, dsEdit] then
    sLibre := dmmArticulos.ProponerCodigoArticuloLibre(sCodigo);
  if sLibre = '' then
    ShowMessage_fza(AMensaje)
  else if MessageDlgTextos_fza(
            Format(SPreguntaCodigoArticuloDuplicadoLibre, [sCodigo, sLibre]),
            mtWarning, [mbYes, mbCancel],
            [Format(SBotonUsarCodigoArticulo, [sLibre]),
             SBotonIndicarOtroCodigoArticulo],
            mbYes) = mrYes then
  begin
    fCodigo.AsString := sLibre;
    Exit(True);
  end;
  if txtCODIGO_ARTICULO.CanFocus then
  begin
    txtCODIGO_ARTICULO.SetFocus;
    txtCODIGO_ARTICULO.SelectAll;
  end;
end;

// FZ-ISSUE-172: el DM aborta el Post de la fila; aquí solo se avisa y, si
// se pide, se abre el artículo que ya tiene el código (fuera del evento del
// dataset).
procedure TfrmMtoArticulos.AvisarCodigoBarrasRepetido(
  const AExistente: TCodigoBarrasRepetido);
var
  sArticulo: string;
begin
  if MessageDlgTextos_fza(
       Format(SErrorCodigoBarrasRepetido,
         [AExistente.CodigoBarras, AExistente.Sku, AExistente.Articulo,
          AExistente.Descripcion]),
       mtWarning, [mbYes, mbCancel],
       [SBotonAbrirArticuloCodigoBarras, SBotonSeguirEditandoCodigoBarras],
       mbCancel) = mrYes then
  begin
    sArticulo := AExistente.Articulo;
    TThread.ForceQueue(nil,
      procedure
      begin
        if dmmArticulos.unqryVariacionesArticulos.State in dsEditModes then
          dmmArticulos.unqryVariacionesArticulos.Cancel;
        ShowMto(Self.Owner, 'Articulos', sArticulo);
      end);
  end;
end;

// FZ-ISSUE-307: informativo y diferido (fuera del BeforePost); la fila
// se graba igual.
procedure TfrmMtoArticulos.AvisarCodigoBarrasGs1(const ACodigo: string);
var
  sCodigo: string;
begin
  sCodigo := ACodigo;
  TThread.ForceQueue(nil,
    procedure
    begin
      MessageDlg_fza(Format(SAvisoCodigoBarrasGs1, [sCodigo]),
        mtInformation, [mbOK], 0);
    end);
end;

procedure TfrmMtoArticulos.FormDestroy(Sender: TObject);
begin
  TThread.RemoveQueuedEvents(ComprobarCodigoArticuloDiferido);
  if Assigned(dmmArticulos) then
  begin
    dmmArticulos.AsignarConfirmacionDesactivacionWeb(nil);
    dmmArticulos.OnCodigoBarrasRepetido := nil;
    dmmArticulos.OnCodigoBarrasGs1 := nil;
    dmmArticulos.OnValidacionDatosArticulo := nil;
    dmmArticulos.OnPrepararAlta := nil;
  end;
  FAplicacionGuardado := nil;
  FCodigosBarrasPersistencia := nil;
  FResolutorDestinoFactura := nil;
  FDependencias.Liberar;
  FCodigosBarras := nil;
  inherited;
  if Assigned(FGestorProp) then
    FreeAndNil(FGestorProp);
  if Assigned(FGestorVar) then
    FreeAndNil(FGestorVar);
  FreeAndNil(FPresFiltros);
  FreeAndNil(FPresTarifas);
  FreeAndNil(FStock);
  FreeAndNil(FPresAtributos);
  dmmArticulos := nil;
end;

procedure TfrmMtoArticulos.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
end;

procedure TfrmMtoArticulos.AplicarEtiquetas;
var
  oColumna: TcxGridDBColumn;
  iColumna: Integer;
begin
  inherited;
  // El perfil restaura los títulos después de la traducción inicial.
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
  if Assigned(FPresFiltros) then
    FPresFiltros.Traducir(Traducciones);
  if Assigned(FGestorVar) then
    FGestorVar.ActualizarIdioma;
  for iColumna := 0 to tvStock.ColumnCount - 1 do
  begin
    oColumna := tvStock.Columns[iColumna];
    oColumna.Caption := RotuloColumnaStock(
      oColumna.DataBinding.FieldName, oColumna.Caption);
  end;
  // Los perfiles antiguos pueden recrear columnas y restaurar sus títulos.
  oColumna := tvProveedores.GetColumnByFieldName('PRECIO_ULT_COMPRA');
  if Assigned(oColumna) then
    oColumna.Free;
  oColumna := tvProveedores.GetColumnByFieldName('FECHA_VALIDEZ');
  if Assigned(oColumna) then
    oColumna.Free;
  cxgrdbclmnTarifasFECHA_VALIDEZ.Caption := STituloFechaUltimaCompra;
  colCompraFecha.Caption := STituloFechaUltimaCompra;
  if Assigned(FPresTarifas) then
    dbcTarifasMARGEN.Caption := FPresTarifas.CaptionColumnaMargen;
  ColocarColumnaLoteCodigos;
end;

function TfrmMtoArticulos.ModoMargenTarifas: TModoMargenTarifa;
begin
  Result := mmtCoeficiente;
  if Assigned(ParametrosApp) then
    Result := ModoCalculoPrecio(ParametrosApp.GetString(
      PARAMETRO_MARGEN_TARIFAS_COEFICIENTE,
      MODO_CALCULO_PRECIO_COEFICIENTE));
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosFUENTE_ATBGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  FPresAtributos.MostrarFuente(AText);
end;

procedure TfrmMtoArticulos.
              tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarNombre(Sender);
end;

procedure TfrmMtoArticulos.
           tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarValorNumerico(Sender);
end;

procedure TfrmMtoArticulos.
              tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarUnidad(Sender);
end;

procedure TfrmMtoArticulos.
         tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarDescripcion(Sender);
end;

procedure TfrmMtoArticulos.btnColorSkusClick(Sender: TObject);
// Despliega el mismo menú de activación por fila que el clic derecho
// sobre el panel de atributos, anclado bajo el boton lateral.
var
  pt: TPoint;
begin
  pt := btnColorSkus.ClientToScreen(Point(0, btnColorSkus.Height));
  pmColorSkus.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoArticulos.AjustarMenuColorSkus(Sender: TObject);
var
  oRotulos: TRotulosVariacion;
  sTipo, sEje: string;
  oLista: TcxLookupComboBoxProperties;
  oPaleta: TcxLookupDBGridColumn;
begin
  oRotulos := Default(TRotulosVariacion);
  if Assigned(dmmArticulos) and dmmArticulos.unqryTablaG.Active and
     not dmmArticulos.unqryTablaG.IsEmpty then
  begin
    sTipo := dmmArticulos.unqryTablaG.FieldByName(
      'TIPO_VARIACION_ART').AsString;
    if Trim(sTipo) <> '' then
      oRotulos := CargarRotulosVariacionUniDAC(ConexionPrincipal, sTipo);
  end;
  sEje := oRotulos.EjeFila;
  if sEje = '' then
    sEje := SRotuloValorFilaSku;
  miActivarColor.Caption := Format(SCaptionActivarSkusValorEje,
    [LowerCase(sEje)]);
  miDesactivarColor.Caption := Format(SCaptionDesactivarSkusValorEje,
    [LowerCase(sEje)]);
  btnColorSkus.Enabled := oRotulos.TieneEjeFila;
  miActivarColor.Enabled := oRotulos.TieneEjeFila;
  miDesactivarColor.Enabled := oRotulos.TieneEjeFila;
  tvSkuAtributosBasicosHEX_ATB.Visible := oRotulos.EsColorBasico;
  oLista := tvSkuAtributosBasicosID_ATB_AV.Properties as
    TcxLookupComboBoxProperties;
  oPaleta := oLista.ListColumns.ColumnByFieldName('HEX_ATB');
  if not oRotulos.EsColorBasico and Assigned(oPaleta) then
    oPaleta.Free
  else if oRotulos.EsColorBasico and not Assigned(oPaleta) then
  begin
    oPaleta := oLista.ListColumns.Add;
    oPaleta.FieldName := 'HEX_ATB';
    oPaleta.Caption := tvSkuAtributosBasicosHEX_ATB.Caption;
    oPaleta.Width := 32;
    if Assigned(FPresAtributos) then
      FPresAtributos.PrepararListaBasicos(oLista);
  end;
  if Assigned(FPresAtributos) then
    FPresAtributos.IdAtributoFila := oRotulos.AtributoFila;
end;

procedure TfrmMtoArticulos.miActivarColorClick(Sender: TObject);
begin
  FPresAtributos.CambiarActivoColorSkus('S');
end;

procedure TfrmMtoArticulos.miDesactivarColorClick(Sender: TObject);
begin
  FPresAtributos.CambiarActivoColorSkus('N');
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup(
  Sender: TObject);
begin
  FPresAtributos.AbrirDesplegableBasico;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp(
  Sender: TObject);
begin
  FPresAtributos.CerrarDesplegableBasico;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosID_ATB_AVPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  FPresAtributos.ValidarBasico(DisplayValue, ErrorText, Error);
end;

procedure TfrmMtoArticulos.
             tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged(
  Sender: TObject);
begin
  FPresAtributos.CambiarBasico(Sender);
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FPresAtributos.ElegirColor;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosDblClick(Sender: TObject);
begin
  FPresAtributos.ElegirColor;
end;

procedure TfrmMtoArticulos.tvSkuAtributosBasicosHEX_ATBCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FPresAtributos.PintarCeldaHex(ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoArticulos.tvStockDblClickPendiente(Sender: TObject);
var
  oColumna: TcxGridDBColumn;
  oCampo: TField;
  sArticulo, sAlmacen: string;
begin
  oColumna := nil;
  if tvStock.Controller.FocusedColumn is TcxGridDBColumn then
    oColumna := TcxGridDBColumn(tvStock.Controller.FocusedColumn);
  if (oColumna = nil) or
     not EsColumnaPendienteTraspasoStock(oColumna.DataBinding.FieldName) or
     (dsTablaG.DataSet = nil) or (tvStock.DataController.DataSet = nil) then
  begin
    cxGrdDBTabPrinDblClick(Sender);
    Exit;
  end;
  sArticulo := dsTablaG.DataSet.FieldByName('CODIGO_ART_ART').AsString;
  sAlmacen := '';
  oCampo := tvStock.DataController.DataSet.FindField(
    CAMPO_STOCK_CODIGO_ALMACEN);
  if oCampo <> nil then
    sAlmacen := oCampo.AsString;
  TfrmModalMensajeTexto.Mostrar(Self, STituloTraspasosPendientesStock,
    TextoTraspasosPendientes(
      ConsultarTraspasosPendientes(ConexionPrincipal, sArticulo, sAlmacen,
        ''),
      sArticulo, sAlmacen));
end;

procedure TfrmMtoArticulos.tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  FStock.PintarCelda(ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoArticulos.PcDetailChange(Sender: TObject);
begin
  if Assigned(dmmArticulos) then
  begin
    ActualizarCargaTarifas;
    if pcDetail.ActivePage = tsTarifas then
    begin
      // Al cambiar de artículo las tarifas estaban cerradas y la columna
      // Sku quedó oculta: se decide ahora con las tarifas cargadas.
      ActualizarVisibilidadColumnaSku;
    end;
    // Stock: si activan la pestaña, refrescar solo si cambio el articulo.
    if pcDetail.ActivePage = cxTabSheet3 then
      FStock.AsegurarAlDia(CodigoArticuloStock);
    RefrescarLotesFicha;
  end;
  // El SKU de la miniatura y del visor Ctrl+F depende de la pestana activa.
  if Assigned(FMiniaturaFoto) then
    FMiniaturaFoto.Actualizar;
  RefrescarFotoArticulo;
end;

procedure TfrmMtoArticulos.ActualizarCargaTarifas;
begin
  if pcDetail.ActivePage = tsTarifas then
    dmmArticulos.AsegurarTarifasAbiertas
  else if dmmArticulos.unqryTarifasArticulos.Active then
  begin
    dmmArticulos.unqryTarifasArticulos.CheckBrowseMode;
    dmmArticulos.unqryTarifasArticulos.Close;
  end;
  if pcDetail.ActivePage = tsProveedores then
    dmmArticulos.CargarUltimasComprasProveedor
  else
    dmmArticulos.unqryUltimasComprasProveedor.Close;
end;

procedure TfrmMtoArticulos.EnsancharColumnasStockParaSwatch;
begin
  FStock.EnsancharColumnasParaSwatch;
end;

procedure TfrmMtoArticulos.tvStockGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
var
  sHint: string;
begin
  if FStock.ObtenerHint(ACellViewInfo, sHint) then
    AHintText := sHint;
end;

initialization
  RegistrarPantalla(TfrmMtoArticulos);
  ForceReferenceToClass(TfrmMtoArticulos);
end.

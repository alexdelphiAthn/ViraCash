{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComprasSesiones                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sesión de compra: crear artículos en lote y un pedido o un albarán        }
{    contra un proveedor. Variante grid plano con edición INLINE de            }
{    cantidades por talla.                                                     }
{                                                                              }
{      - Cabecera: Empresa, Proveedor, Tarifa venta, Margen,                   }
{        Multiplo redondeo, Ajuste final.                                      }
{      - Una linea = un articulo. Columnas: Familia (F3 -> picker),            }
{        Codigo articulo (editable; si lo tecleado coincide con una            }
{        familia con contador activo se expande a FAMILIA+RELLENO,             }
{        p. ej. '0101' -> '0101003'), Descripcion, Color (libre),              }
{        Color basico (selector paleta), Pr. compra, Pr. venta                 }
{        (propuesto al teclear coste), Sistema tallas, N columnas              }
{        TALLA inline, Total tallas, Importe s/IVA.                            }
{      - Boton 'Arbol familias' en la barra de lineas abre el mismo            }
{        modal jerarquico que F3 sobre la columna Familia.                     }
{                                                                              }
{    Las columnas TALLA son no-bound: su valor vive en                         }
{    tvLineas.DataController.Values y se sincroniza con                        }
{    fza_compras_sesiones_celdas via SQL. El numero de columnas visibles       }
{    = max valores entre los conjuntos referenciados en la sesion.             }
{    Los rotulos (captions) reflejan el sistema de la linea con foco.          }
{                                                                              }
{    El formulario recoge la entrada, delega en un colaborador y presenta      }
{    el resultado. Los colaboradores se inyectan por constructor con un        }
{    entorno explicito (datasets, columnas y callbacks); ninguno recibe        }
{    este formulario ni el contexto general de repositorios:                   }
{      - TCoordinadorTallasSesion   columnas inline, catalogo de sistemas,     }
{        selector, pintado, bloqueo y distribuidor por almacen.                }
{      - TBuscadorModeloProveedorSesion  busqueda incremental de modelos y     }
{        reutilizacion de articulos al teclear familia / codigo / modelo.      }
{      - TCoordinadorCopiaLineasSesion   "Otro color" con sus precios por      }
{        talla.                                                                }
{      - TCoordinadorProveedorSesion  ficha, defectos, kits y color basico.    }
{      - TCoordinadorFotosProvisionalesSesion  fotos de lineas y visor.        }
{      - TCoordinadorNavegacionComprasSesion  maestros y documentos.          }
{      - TCoordinadorImportacionPedidoOcr  valida, importa y archiva pedidos.  }
{      - TVisorPedidoOriginalSesion  navegacion, zoom y arrastre del TIFF.     }
{      - IAplicacionMaterializacionCompraSesion  orquesta la materializacion.  }
{    Los tiempos de espera (debounce y aperturas diferidas) viven en           }
{    IPlanificadorDiferido; aqui no queda ningun TTimer.                       }
{                                                                              }
{    Reutiliza:                                                                }
{      - TdmComprasSesiones (mapeado en fza_winforms).                         }
{      - inLibComprasSesiones.ResolverCodigoFamilia (atajo familia->codigo).   }
{      - inLibComprasSesiones.CalcularPrecioVenta (PVP propuesto).             }
{      - inLibAtributosPaleta.PintarOpcionComboConSwatch (combo de color       }
{        basico con busqueda incremental y cuadradito de paleta).              }
{      - TfrmModalSelFamilia (picker jerarquico, tecla F3).                    }
{                                                                              }
{    Documentado en DESARROLLOS EN CURSO/compras_sesiones.md.                  }
{******************************************************************************}
unit inMtoComprasSesiones;

interface

uses
  cxScrollBox,
  inLibRegistroPantallas, inLibPivoteVentaCalculo,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils,
  System.Variants, System.types,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.UITypes, System.Actions,
  Vcl.ActnList, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  cxDBNavigator, cxMemo, cxCheckBox, cxGroupBox, cxLocalization, cxGraphics,
  cxButtonEdit, cxEditRepositoryItems, cxDBExtLookupComboBox,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoGen,
  inLibGridTallasInline,
  inLibComprasSesiones,
  inLibComprasSesionesAplicacionIntf,
  inLibComprasSesionesInyeccion,
  inLibPermisosIntf,
  inMtoComprasSesionesPresentacionCopiaLineas,
  inMtoComprasSesionesPresentacionPestanas,
  inMtoComprasSesionesPresentacionFotos,
  inMtoComprasSesionesPresentacionImportacionOcr,
  inMtoComprasSesionesPresentacionModelo,
  inMtoComprasSesionesPresentacionNavegacion,
  inMtoComprasSesionesPresentacionPedidoOriginal,
  inMtoComprasSesionesPresentacionProveedor,
  inMtoComprasSesionesPresentacionTallas,
  inMtoComprasSesionesPropiedadesVcl,
  inLibArticulosPropiedadesPersistenciaIntf,
  UniDataComprasSesionesPropiedades,
  inMtoComprasSesionesTrazabilidadVcl, inLibTrazabilidadAlta,
  inLibVariacionesRotulos,
  UniDataComprasSesiones, cxBlobEdit, dxShellDialogs, cxRadioGroup, Vcl.Buttons,
  dxDateRanges, cxSplitter, cxImage, cxImageComboBox;

const
  NOMBRE_PANTALLA_COMPRAS_SESIONES = 'frmMtoComprasSesiones';
  // Numero maximo de columnas de talla inline. Subido a 20, y a 21 el
  // 10/10/2026 (MAX_TALLAS_HORIZONTAL, comun a todas las rejillas), a peticion
  // de un cliente con sistemas extensos (rangos de calzado largos,
  // tallas internacionales niño+adulto, etc.).
  CANT_TALLAS_MAX = MAX_TALLAS_HORIZONTAL;
  WM_RECARGAR_TALLAS_SESION = WM_APP + 247;
  WM_SELECCIONAR_CELDA_SESION = WM_APP + 248;
  WM_REORDENAR_LINEAS_SESION = WM_APP + 249;

type
  // Los tipos TPosConjunto / TArrPosConjunto viven ahora en
  // inLibGridTallasInline (compartidos con futuros Mtos de Pedidos
  // / Albaranes / Facturas que reusen el patron).

  TfrmMtoComprasSesiones = class(TfrmMtoGen)
    // ------------------------------------------------------------------
    // Columnas grid lista (tsLista, heredada)
    // ------------------------------------------------------------------
    dbcSerieSes              : TcxGridDBColumn;
    dbcNumeroSes             : TcxGridDBColumn;
    dbcFechaSes              : TcxGridDBColumn;
    dbcTemporadaSes          : TcxGridDBColumn;
    dbcFechaEfectoStockSes   : TcxGridDBColumn;
    dbcFechaTopeRecepcionSes : TcxGridDBColumn;
    dbcTotalPrendasSes       : TcxGridDBColumn;
    dbcTotalLineasSes        : TcxGridDBColumn;
    dbcTotalDocumentoSes     : TcxGridDBColumn;
    dbcCantidadPedidaSes     : TcxGridDBColumn;
    dbcCantidadRecibidaSes   : TcxGridDBColumn;
    dbcCantidadPendienteSes  : TcxGridDBColumn;
    dbcEstadoSes             : TcxGridDBColumn;
    dbcCodigoEmpSes          : TcxGridDBColumn;
    dbcCodigoPrvSes          : TcxGridDBColumn;
    dbcRazonSocialPrvSes     : TcxGridDBColumn;
    dbcNombrePrvSes          : TcxGridDBColumn;
    dbcCodigoTarSes          : TcxGridDBColumn;
    dbcUsuarioAltaSes        : TcxGridDBColumn;
    dlgFoto                  : TOpenDialog;
    dlgImportarPedido        : TOpenDialog;
    btnImprimir: TcxButton;
    btnCrear: TcxButton;
    btnReintentarFotos: TcxButton;
    btnRevertir: TcxButton;
    btnImportarPedido: TcxButton;

    // ------------------------------------------------------------------
    // Navegacion rapida via TActionList. Los shortcuts SOLO disparan
    // cuando este form esta activo (cxTabSheet enfocada), asi evitamos
    // que un KeyDown se filtre a otra instancia abierta. Patron
    // recomendado en VCL frente a Form.OnKeyDown global.
    // ------------------------------------------------------------------
    alNavegacion         : TActionList;
    actIrArticulos       : TAction;
    actIrAlbaranesCompra : TAction;
    actIrPedidosCompra   : TAction;
    actIrProveedor       : TAction;
    pnlBottFich: TPanel;
    splSplitterFicha: TcxSplitter;
    cxPageControl2: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    dbcLinFamilia: TcxGridDBColumn;
    dbcLinCodArt: TcxGridDBColumn;
    dbcLinRefPrv: TcxGridDBColumn;
    dbcLinDescripcion: TcxGridDBColumn;
    dbcLinTipoIva: TcxGridDBColumn;
    dbcLinColor: TcxGridDBColumn;
    dbcLinColorBasico: TcxGridDBColumn;
    dbcLinPestana: TcxGridDBColumn;
    dbcLinPrecioCompra: TcxGridDBColumn;
    dbcLinPrecioVenta: TcxGridDBColumn;
    dbcLinTallas: TcxGridDBColumn;
    dbcLinVariacion: TcxGridDBColumn;
    dbcLinTotalTallas: TcxGridDBColumn;
    dbcLinImporteTotal: TcxGridDBColumn;
    dbcLinNumero: TcxGridDBColumn;
    // Oculta: el gestor de tallas lee de la rejilla el articulo reusado
    // de cada fila al pintar, sin tocar el dataset (FZ-ISSUE-105).
    dbcLinArtReusar: TcxGridDBColumn;
    glLineas: TcxGridLevel;
    pnlLineasTop: TPanel;
    btnAddLinea: TcxButton;
    btnDelLinea: TcxButton;
    btnNuevoColor: TcxButton;
    btnPreciosTalla: TcxButton;
    btnFoto: TcxButton;
    btnArbolFamilias: TcxButton;
    btnDescargarFotos: TcxButton;
    lblHint: TcxLabel;
    tsTotales: TcxTabSheet;
    pnlTotales: TcxScrollBox;
    lblTotalBasesSes: TcxLabel;
    curTotalesTOTAL_BASES_SES: TcxDBCurrencyEdit;
    lblTotalImpuestosSes: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_SES: TcxDBCurrencyEdit;
    lblPorcRetencionSes: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_SES: TcxDBSpinEdit;
    lblTotalRetencionSes: TcxLabel;
    curTotalesTOTAL_RETENCION_SES: TcxDBCurrencyEdit;
    lblTotalLiquidoSes: TcxLabel;
    curTotalesTOTAL_LIQUIDO_SES: TcxDBCurrencyEdit;
    lblTotalesFormaPagoSes: TcxLabel;
    cbbTotalesFORMA_PAGO_SES: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_COMPRAS_SES: TcxDBCheckBox;
    lblDtoComercialSes: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_SES: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_SES: TcxDBCurrencyEdit;
    lblDtoFinancieroSes: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_SES: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_SES: TcxDBCurrencyEdit;
    grpDesgloseIvaSes: TGroupBox;
    lblTotSesBase: TcxLabel;
    lblTotSesPorIva: TcxLabel;
    lblTotSesTotalIva: TcxLabel;
    lblTotSesPorRe: TcxLabel;
    lblTotSesTotalRe: TcxLabel;
    lblTotSesIVAN: TcxLabel;
    lblTotSesIVAR: TcxLabel;
    lblTotSesIVAS: TcxLabel;
    lblTotSesIVAE: TcxLabel;
    curTotSesTOTAL_BASEI_IVAN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAR_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAS_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_BASEI_IVAE_SES: TcxDBCurrencyEdit;
    spnTotSesPORCENTAJE_IVAN_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAR_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAS_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_IVAE_SES: TcxDBSpinEdit;
    curTotSesTOTAL_IVAN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAR_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAS_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_IVAE_SES: TcxDBCurrencyEdit;
    spnTotSesPORCENTAJE_REN_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_RER_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_RES_SES: TcxDBSpinEdit;
    spnTotSesPORCENTAJE_REE_SES: TcxDBSpinEdit;
    curTotSesTOTAL_REN_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_RER_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_RES_SES: TcxDBCurrencyEdit;
    curTotSesTOTAL_REE_SES: TcxDBCurrencyEdit;
    tsDocumentos: TcxTabSheet;
    pnlDocsTop: TPanel;
    btnIrADoc: TcxButton;
    // Boton del lateral derecho: navega al pedido / albaran seleccionado
    // en la pestania Documentos (sustituye al antiguo atajo F12, que
    // chocaba con el F12 de grabar registro del Mto base).
    btnIrPedAlb: TcxButton;
    lblDocsInfo: TcxLabel;
    cxgrdDocs: TcxGrid;
    tvDocs: TcxGridDBTableView;
    dbcDocTipo: TcxGridDBColumn;
    dbcDocSerie: TcxGridDBColumn;
    dbcDocNumero: TcxGridDBColumn;
    dbcDocAlmacen: TcxGridDBColumn;
    dbcDocInstante: TcxGridDBColumn;
    dbcDocUsuario: TcxGridDBColumn;
    glDocs: TcxGridLevel;

    // ------------------------------------------------------------------
    // Pestaña Proveedor: ficha del proveedor de la sesion (solo lectura),
    // sus defectos (margen, sistema de tallas) y su biblioteca de kits.
    // ------------------------------------------------------------------
    tsProveedor          : TcxTabSheet;
    dsPrvFicha           : TDataSource;
    pnlProvIzq           : TPanel;
    gbProvFicha          : TcxGroupBox;
    lblProvCodigo        : TcxLabel;
    txtProvCodigo        : TcxDBTextEdit;
    lblProvNif           : TcxLabel;
    txtProvNif           : TcxDBTextEdit;
    lblProvRazon         : TcxLabel;
    txtProvRazon         : TcxDBTextEdit;
    lblProvNombre        : TcxLabel;
    txtProvNombre        : TcxDBTextEdit;
    lblProvTelefono      : TcxLabel;
    txtProvTelefono      : TcxDBTextEdit;
    lblProvMovil         : TcxLabel;
    txtProvMovil         : TcxDBTextEdit;
    lblProvEmail         : TcxLabel;
    txtProvEmail         : TcxDBTextEdit;
    lblProvDireccion     : TcxLabel;
    txtProvDireccion     : TcxDBTextEdit;
    lblProvPoblacion     : TcxLabel;
    txtProvPoblacion     : TcxDBTextEdit;
    lblProvProvincia     : TcxLabel;
    txtProvProvincia     : TcxDBTextEdit;
    lblProvCPostal       : TcxLabel;
    txtProvCPostal       : TcxDBTextEdit;
    lblProvPais          : TcxLabel;
    txtProvPais          : TcxDBTextEdit;
    lblProvContacto      : TcxLabel;
    txtProvContacto      : TcxDBTextEdit;
    lblProvTelContacto   : TcxLabel;
    txtProvTelContacto   : TcxDBTextEdit;
    lblProvMargen        : TcxLabel;
    txtProvMargen        : TcxDBTextEdit;
    btnIrProveedor       : TcxButton;
    gbProvKits           : TcxGroupBox;
    pnlProvKitsTop       : TPanel;
    btnAplicarKitProv    : TcxButton;
    lblProvKitsHint      : TcxLabel;
    cxgrdPrvKits         : TcxGrid;
    tvPrvKits            : TcxGridDBTableView;
    dbcPrvKitCodigo      : TcxGridDBColumn;
    dbcPrvKitNombre      : TcxGridDBColumn;
    dbcPrvKitSistema     : TcxGridDBColumn;
    glPrvKits            : TcxGridLevel;
    cxgrdPrvKitsDet      : TcxGrid;
    tvPrvKitsDet         : TcxGridDBTableView;
    dbcPrvKitDetValor    : TcxGridDBColumn;
    dbcPrvKitDetCantidad : TcxGridDBColumn;
    glPrvKitsDet         : TcxGridLevel;
    // Boton "Aplicar kit" de la barra de Lineas (popup con los kits del
    // proveedor; aplica sobre la linea con foco).
    btnAplicarKit        : TcxButton;
    gbFotoProvisional              : TcxGroupBox;
    imgFotoProvisional             : TImage;
    lblFotoProvisionalAsignacion   : TcxLabel;
    tsFotosProvisionales           : TcxTabSheet;
    cxgrdFotosProvisionales        : TcxGrid;
    tvFotosProvisionales           : TcxGridDBTableView;
    dbcFotoLinea                   : TcxGridDBColumn;
    dbcFotoArticulo                : TcxGridDBColumn;
    dbcFotoModeloProveedor         : TcxGridDBColumn;
    dbcFotoDescripcion             : TcxGridDBColumn;
    dbcFotoColor                   : TcxGridDBColumn;
    dbcFotoUnidad                  : TcxGridDBColumn;
    dbcFotoFichero                 : TcxGridDBColumn;
    dbcFotoInstante                : TcxGridDBColumn;
    dbcFotoUsuario                 : TcxGridDBColumn;
    glFotosProvisionales           : TcxGridLevel;
    tsPedidoOriginal               : TcxTabSheet;
    pnlPedidoOriginalTop           : TPanel;
    btnPaginaAnteriorPedido        : TcxButton;
    btnPaginaSiguientePedido       : TcxButton;
    btnAlejarPedido                : TcxButton;
    btnAcercarPedido               : TcxButton;
    btnAjustarPedido               : TcxButton;
    btnZoomRealPedido              : TcxButton;
    btnFijarZoomPedido             : TcxButton;
    lblPaginaPedido                : TcxLabel;
    scrPedidoOriginal              : TScrollBox;
    imgPedidoOriginal              : TImage;
    cxPageControl1: TcxPageControl;
    cxTabSheet2: TcxTabSheet;
    gbCabecera: TcxGroupBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxDBComboBox;
    lblNumero: TcxLabel;
    txtNumero: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFecha: TcxDBDateEdit;
    lblFechaTopeRecepcion: TcxLabel;
    dteFechaTopeRecepcion: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtEstado: TcxDBTextEdit;
    lblEmpresa: TcxLabel;
    cbbEmpresa: TcxDBLookupComboBox;
    lblProveedor: TcxLabel;
    cbbProveedor: TcxDBLookupComboBox;
    lblRefPrv: TcxLabel;
    txtRefPrv: TcxDBTextEdit;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxDBLookupComboBox;
    chkFormatoDistribuido: TcxDBCheckBox;
    lblProveedorNombre: TcxLabel;
    lblVariacion: TcxLabel;
    cbbVariacion: TcxDBLookupComboBox;
    cxTabSheet3: TcxTabSheet;
    lblTemporada: TcxLabel;
    cbbTemporada: TcxDBLookupComboBox;
    cbbTarifa: TcxDBLookupComboBox;
    lblTarifa: TcxLabel;
    rbCoeficiente: TcxRadioButton;
    rbMargenVenta: TcxRadioButton;
    spnMargenVenta: TcxSpinEdit;
    spnMargen: TcxDBSpinEdit;
    lblMultiploRedondeo: TcxLabel;
    spnMultiploRedondeo: TcxDBSpinEdit;
    lblAjusteFinal: TcxLabel;
    spnAjusteFinal: TcxDBSpinEdit;
    chkVariosTiposIva: TcxDBCheckBox;
    chkESVARIOS_TIPOS_VARIACION_SES: TcxDBCheckBox;
    lblTipoIvaDefecto: TcxLabel;
    cbbTipoIvaDefecto: TcxDBComboBox;
    chkCopiarDescripcionFamilia: TcxDBCheckBox;
    chkDescripcionBlanco: TcxDBCheckBox;

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure dbcFotoUnidadGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var ATexto: string);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure btnNuevoColorClick(Sender: TObject);
    procedure btnPreciosTallaClick(Sender: TObject);
    procedure btnArbolFamiliasClick(Sender: TObject);
    procedure btnCrearClick(Sender: TObject);
    procedure btnReintentarFotosClick(Sender: TObject);
    procedure btnRevertirClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure tvLineasEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cbbProveedorPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnAplicarKitClick(Sender: TObject);
    procedure btnAplicarKitCabClick(Sender: TObject);
    procedure btnAplicarKitProvClick(Sender: TObject);
    procedure tvPrvKitsDblClick(Sender: TObject);
    procedure dbcLinColorBasicoPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure dbcLinPrecioCompraPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinCodArtPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure dbcLinRefPrvPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure cbbTipoIvaDefectoPropertiesChange(Sender: TObject);
    procedure chkVariosTiposIvaPropertiesChange(Sender: TObject);
    procedure chkRecargoComprasPropertiesChange(Sender: TObject);
    procedure cxgrdLineasEnter(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure cxPageControl1Change(Sender: TObject);
    procedure cxPageControl2Change(Sender: TObject);
    procedure btnImportarPedidoClick(Sender: TObject);
    procedure CambiarModoPrecio(Sender: TObject);
    procedure CambiarMargenVenta(Sender: TObject);
    procedure ActualizarMargenVenta(Sender: TObject);
    procedure ValidarVariacionLinea(Sender: TObject;
      var DisplayValue: TcxEditValue; var ErrorText: TCaption;
      var Error: Boolean);
  private
    FSincronizandoPrecio: Boolean;
    Dmm: TdmComprasSesiones;
    FServicioComprasSesiones: TServicioComprasSesiones;
    FTrazabilidadSesion: TFichaTrazabilidadSesion;
    FPropiedadesFamilia: TPropiedadesFamiliaSesion;
    FDependencias: TContextoDependenciasComprasSesiones;
    FAplicacionMaterializacion:
      IAplicacionMaterializacionCompraSesion;
    FEstiloRecepcionVencida: TcxStyle;
    // Colaboradores de presentacion. Cada uno recibe por constructor
    // solo las capacidades que usa (datasets, columnas y callbacks);
    // ninguno conserva una referencia a este formulario completo.
    FTallas: TCoordinadorTallasSesion;
    FModeloPrv: TBuscadorModeloProveedorSesion;
    FCopiaLineas: TCoordinadorCopiaLineasSesion;
    // Copa (eje de pestañas): columna, botones y pestañas de las líneas.
    FPestanasSesion: TPresentadorPestanasSesion;
    FProveedor: TCoordinadorProveedorSesion;
    FFotos: TCoordinadorFotosProvisionalesSesion;
    FNavegacion: TCoordinadorNavegacionComprasSesion;
    FImportadorOcr: TCoordinadorImportacionPedidoOcr;
    FVisorPedidoOriginal: TVisorPedidoOriginalSesion;
    FAplicandoColorOcr: Boolean;
    FRecargaTallasPendiente: Boolean;
    FReordenacionPendiente: Boolean;
    FEditorSeleccionPendiente: TcxCustomEdit;
    // Rótulos de la variación de la sesión activa (FZ-ISSUE-420).
    FRotulosVariacion: TRotulosVariacion;
    FRotulosCargados: Boolean;
    FRefrescandoRotulos: Boolean;
    procedure AplicarModoPrecioDefecto;
    procedure ReintentarFotosSesion;
    procedure EditarPreciosTallaLinea;
    procedure CopiarPreciosTallaCopia(ALineaOrigen,
      ALineaDestino: Integer);
    procedure RefrescarRotulosVariacion(AForzar: Boolean = False);
    procedure VariacionSesionCambiada;
    procedure ConfigurarVariacionesLinea;
    function  GestorTallas: TGestorGridTallas;
    procedure RecargarTallasVisibles;
    procedure RecargarTallasDiferido;
    procedure RefrescarColumnasTallas;
    procedure ReconstruirTallas;
    function ReordenarLineasSesion(ALineaFoco: Integer): Integer;
    procedure ReordenarLineasDiferido;
    procedure CrearColaboradorTallas;
    procedure CrearColaboradorMaterializacion;
    procedure CrearColaboradorCopiaLineas;
    procedure CrearColaboradorPestanas;
    procedure CrearColaboradorModelo;
    procedure CrearColaboradorProveedor;
    procedure CrearColaboradores;
    procedure CrearServicioSesion;
    procedure EnlazarListasCabecera;
    procedure EnlazarDetalleSesion;
    procedure EnlazarPestanaProveedor;
    procedure LogSes(const ATexto: string);
    procedure RefrescarVisibilidadTipoIva;
    procedure RefrescarOpcionesDescripcion;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure dsTablaGStateChangeHook(Sender: TObject);
    procedure GridListaGetContentStyle(Sender: TcxCustomGridTableView;
                ARecord: TcxCustomGridRecord;
                AItem: TcxCustomGridTableItem;
                var AStyle: TcxStyle);
    procedure dsSesionLinDataChangeHook(Sender: TObject; Field: TField);
    procedure unqrySesionLinBeforePostHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterPostHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeInsertHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterInsertHook(DataSet: TDataSet);
    procedure EditarModeloLineaNuevaDiferido;
    procedure unqrySesionLinAfterCancelHook(DataSet: TDataSet);
    procedure unqrySesionLinBeforeDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinAfterDeleteHook(DataSet: TDataSet);
    procedure unqrySesionLinRecargarTallasHook(DataSet: TDataSet);
    function DirectorioFotosAplicacion: string;
    procedure ImportarPedidoOcr(const AFicheroJson: string);
    procedure WMRecargarTallasSesion(var AMensaje: TMessage);
      message WM_RECARGAR_TALLAS_SESION;
    procedure WMSeleccionarCeldaSesion(var AMensaje: TMessage);
      message WM_SELECCIONAR_CELDA_SESION;
    procedure WMReordenarLineasSesion(var AMensaje: TMessage);
      message WM_REORDENAR_LINEAS_SESION;
  public
    function CloseQuery: Boolean; override;
    function CancelarEdicionConEscape: Boolean; override;
  protected
    procedure AsegurarColumnaVariacionLinea;
    // Interceptamos a nivel de form (KeyPreview heredado = True) para
    // que Ctrl+Enter abra el selector de la columna editbutton enfocada
    // ANTES de que la navegacion Enter->Tab del grid / FormKeyDown base
    // mueva el foco a otra pestania.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure BuscarProveedor; virtual;
  public
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure AplicarEtiquetas; override;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasComprasSesiones);
      reintroduce; overload;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    procedure PestanaActivada; override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibMensajesVcl, inLibTrazabilidad, inLibMargenTarifa,
  inLibUser,
  inLibFiltroUsuario,
  inLibGenBusq,
  inLibShowMto,
  inLibFotos,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inMtoModalImpSesion,
  inMtoModalPreciosTallaSesion,
  UniDataComprasSesionesPreciosLinea,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibMsgArticulos, inLibMsgCompras,
  inLibContextoSesionIntf,
  inLibProcesoPedidoOcr,
  inLibComprasSesionesIntf,
  inLibComprasSesionesReglas,
  inLibDatasets,
  inLibEnterComoTabDesplegables,
  inLibMtoGenAplicacionIntf,
  UniDataGen,
  inMtoComprasSesionesPresentacionMaterializacion,
  UniDataComprasSesionesComposicion,
  UniDataComprasSesionesPresentacionRepositorio;

{$R *.dfm}

procedure TfrmMtoComprasSesiones.AplicarModoPrecioDefecto;
var
  Modo: TModoMargenTarifa;
begin
  Modo := mmtCoeficiente;
  if Assigned(ParametrosApp) then
    Modo := ModoCalculoPrecio(ParametrosApp.GetString(
      PARAMETRO_MARGEN_TARIFAS_COEFICIENTE,
      MODO_CALCULO_PRECIO_COEFICIENTE));
  // Seleccionar el modo no debe modificar el margen guardado de la sesión.
  FSincronizandoPrecio := True;
  try
    rbCoeficiente.Checked := Modo = mmtCoeficiente;
    rbMargenVenta.Checked := Modo = mmtMargenVenta;
  finally
    FSincronizandoPrecio := False;
  end;
  CambiarModoPrecio(nil);
end;

procedure TfrmMtoComprasSesiones.CambiarModoPrecio(Sender: TObject);
begin
  ActualizarMargenVenta(Sender);
  spnMargen.Enabled := rbCoeficiente.Checked;
  spnMargenVenta.Enabled := rbMargenVenta.Checked;
end;

procedure TfrmMtoComprasSesiones.ActualizarMargenVenta(Sender: TObject);
begin
  if Assigned(spnMargenVenta) and not FSincronizandoPrecio then
  begin
    FSincronizandoPrecio := True;
    try
      spnMargenVenta.Value := MargenVentaDesdeCoeficiente(
        StrToFloatDef(VarToStr(spnMargen.EditValue), 0));
    finally
      FSincronizandoPrecio := False;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.CambiarMargenVenta(Sender: TObject);
var
  Campo: TField;
  Valor: Variant;
begin
  if rbMargenVenta.Checked and not FSincronizandoPrecio then
  begin
    Campo := spnMargen.DataBinding.Field;
    Valor := spnMargenVenta.Value;
    if Assigned(Campo) and Campo.DataSet.CanModify and
       not VarIsNull(Valor) and not VarIsEmpty(Valor) then
    begin
      FSincronizandoPrecio := True;
      try
        Campo.DataSet.Edit;
        Campo.AsFloat := CoeficienteDesdeMargenVenta(Valor);
        spnMargen.EditValue := Campo.AsFloat;
      finally
        FSincronizandoPrecio := False;
      end;
    end;
  end;
end;


resourcestring
  SErrorImportarPedidoSesionCompra =
    'No se pudo importar el pedido: %s';
  SFiltroDocumentoPdfPedidoSesionCompra =
    'Documento PDF (*.pdf)|*.pdf';
  SErrorImportacionOcrSesionConLineas =
    'La importación OCR requiere una sesión sin líneas.';
  SErrorUsuarioSinEmpresaImportacionOcr =
    'El usuario actual no tiene empresa asignada.';
  SErrorUsuarioSinAlmacenImportacionOcr =
    'El usuario actual no tiene almacén asignado.';
  SErrorEmpresaSinSerieSesionesImportacionOcr =
    'La empresa %s no tiene una serie de sesiones configurada.';
  SErrorGuardarSesionAntesImportacionOcr =
    'No se pudo guardar la sesión antes de importar el pedido.';

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoComprasSesiones.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasComprasSesiones);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoComprasSesiones.LogSes(const ATexto: string);
begin
  if Assigned(ContextoSesion) then
    ContextoSesion.LogSesion(ATexto);
end;

// ===========================================================================
//   Colaboradores de presentacion
// ===========================================================================
// El formulario recoge la entrada, delega en el colaborador que
// corresponde y presenta el resultado. Estos accesores concentran el
// unico punto por el que se llega al gestor de tallas pivotadas.

function TfrmMtoComprasSesiones.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if FTallas <> nil then
    Result := FTallas.Gestor;
end;

procedure TfrmMtoComprasSesiones.RecargarTallasVisibles;
begin
  if GestorTallas <> nil then
    GestorTallas.CargarCantidadesTodasLineas;
end;

// El DataController puede repintar la fila DESPUES del hook y borrar los
// Values[] no-bound recien cargados: la recarga diferida tiene la ultima
// palabra.
procedure TfrmMtoComprasSesiones.RecargarTallasDiferido;
begin
  // Un unico mensaje aplaza y agrupa los repintados que genera una misma
  // operacion Insert/Cancel/Post. Al destruir la ventana Windows descarta
  // el mensaje, evitando callbacks anonimos sobre un formulario liberado.
  if not FRecargaTallasPendiente then
  begin
    FRecargaTallasPendiente := True;
    PostMessage(Handle, WM_RECARGAR_TALLAS_SESION, 0, 0);
  end;
end;

// Solo si el editor sigue siendo el de la celda en la que se entro.
procedure TfrmMtoComprasSesiones.WMSeleccionarCeldaSesion(
  var AMensaje: TMessage);
var
  Editor: TcxCustomEdit;
begin
  Editor := FEditorSeleccionPendiente;
  FEditorSeleccionPendiente := nil;
  if (Editor <> nil) and not (csDestroying in ComponentState) and
     tvLineas.Controller.EditingController.IsEditing and
     (tvLineas.Controller.EditingController.Edit = Editor) then
    SeleccionarTodoEnEditor(Editor);
  AMensaje.Result := 0;
end;

procedure TfrmMtoComprasSesiones.WMRecargarTallasSesion(
  var AMensaje: TMessage);
begin
  FRecargaTallasPendiente := False;
  if not (csDestroying in ComponentState) then
  begin
    RecargarTallasVisibles;
    if GestorTallas <> nil then
      GestorTallas.ActualizarCaptionsLineaActiva;
  end;
  AMensaje.Result := 0;
end;

procedure TfrmMtoComprasSesiones.RefrescarColumnasTallas;
begin
  if GestorTallas <> nil then
  begin
    GestorTallas.RecalcularMaxColumnas;
    GestorTallas.CargarCantidadesTodasLineas;
    GestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoComprasSesiones.ReconstruirTallas;
begin
  if GestorTallas <> nil then
  begin
    GestorTallas.InvalidarCache;
    RefrescarColumnasTallas;
  end;
end;

// FZ-ISSUE-416: las líneas del mismo artículo quedan juntas (artículo,
// color, línea) y numeradas de 10 en 10 en ese orden, que es el de la
// rejilla, el de las incidencias y el del documento que se genere. Solo
// con la sesión en borrador y sin ninguna línea a medio teclear: mientras
// se escribe la rejilla no cambia de orden. La cabecera puede seguir en
// edición (el alta de una línea la deja así): su contador en memoria
// nunca es menor que el que se graba aquí. Devuelve el número nuevo de
// ALineaFoco y deja el cursor en ella.
function TfrmMtoComprasSesiones.ReordenarLineasSesion(
  ALineaFoco: Integer): Integer;
var
  aCambios: TCambiosLineaSesion;
begin
  Result := ALineaFoco;
  if (Dmm <> nil) and Dmm.unqryTablaG.Active and
     (Dmm.unqryTablaG.State in [dsBrowse, dsEdit]) and
     (not Dmm.unqryTablaG.IsEmpty) and Dmm.unqrySesionLin.Active and
     (Dmm.unqrySesionLin.State = dsBrowse) and
     (not Dmm.unqrySesionLin.IsEmpty) and
     SameText(Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString,
       'BORRADOR') then
  begin
    aCambios := FServicioComprasSesiones.RenumerarLineas(
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString);
    if Length(aCambios) > 0 then
    begin
      Result := LineaTrasRenumerar(aCambios, ALineaFoco);
      LogSes(Format('ReordenarLineasSesion: %d lineas, foco %d -> %d',
        [Length(aCambios), ALineaFoco, Result]));
      Dmm.unqrySesionLin.Refresh;
      Dmm.unqrySesionLin.Locate('LINEA_SESLIN', Result, []);
      ReconstruirTallas;
      if FFotos <> nil then
        FFotos.RefrescarLista;
    end;
  end;
end;

// Tras borrar una línea: fuera del evento del dataset, que no admite
// que se le refresque desde dentro.
procedure TfrmMtoComprasSesiones.ReordenarLineasDiferido;
begin
  if not FReordenacionPendiente then
  begin
    FReordenacionPendiente := True;
    PostMessage(Handle, WM_REORDENAR_LINEAS_SESION, 0, 0);
  end;
end;

procedure TfrmMtoComprasSesiones.WMReordenarLineasSesion(
  var AMensaje: TMessage);
begin
  FReordenacionPendiente := False;
  if not (csDestroying in ComponentState) and (Dmm <> nil) and
     Dmm.unqrySesionLin.Active then
    ReordenarLineasSesion(
      Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger);
  AMensaje.Result := 0;
end;

// Se crea ANTES del inherited: el gestor de tallas necesita sus columnas
// creadas cuando el ancestro abre el detalle.
procedure TfrmMtoComprasSesiones.CrearColaboradorTallas;
var
  Entorno: TEntornoTallasSesion;
begin
  Entorno := Default(TEntornoTallasSesion);
  Entorno.Conexion := ConexionPrincipal;
  Entorno.ContextoSesion := ContextoSesion;
  Entorno.Usuario := IdentidadSesion.Usuario;
  Entorno.Unidades := UnidadesMedida;
  Entorno.Contenedor := cxgrdLineas;
  Entorno.Vista := tvLineas;
  Entorno.ColumnaSelector := dbcLinTallas;
  Entorno.FuenteCabecera := dsTablaG;
  Entorno.MaxColumnas := CANT_TALLAS_MAX;
  Entorno.FijarTallajeDefecto :=
    procedure(AIdConjunto: Integer)
    begin
      if Dmm <> nil then
        Dmm.TallajeDefectoActual := AIdConjunto;
    end;
  Entorno.DefinirVariacionLinea :=
    procedure(ACodigo: string)
    begin
      Dmm.ConfigurarVariacionLinea(ACodigo);
    end;
  Entorno.ReiniciarCantidadesLinea :=
    procedure(ALinea: Integer)
    begin
      FServicioComprasSesiones.BorrarCeldasLinea(
        Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
        Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
        ALinea);
    end;
  Entorno.RefrescarTotalesSesion :=
    procedure
    begin
      if Dmm <> nil then
        Dmm.RefrescarTotalesSesion;
    end;
  Entorno.RepositorioDistribuidor := FDependencias.Distribuidor;
  FTallas := TCoordinadorTallasSesion.Create(Entorno);
end;

// El orden importa: el buscador de modelos pide copias de linea al
// coordinador de copia, y el de proveedor abre el distribuidor del de
// tallas (ya creado antes del inherited).
procedure TfrmMtoComprasSesiones.CrearColaboradores;
var
  EntornoFotos: TEntornoFotosProvisionalesSesion;
  EntornoImportacion: TEntornoImportacionPedidoOcr;
  EntornoNavegacion: TEntornoNavegacionComprasSesion;
  ConexionSeries: TUniConnection;
begin
  FreeAndNil(FFotos);
  EntornoFotos := Default(TEntornoFotosProvisionalesSesion);
  EntornoFotos.Propietario := Self;
  EntornoFotos.AccionFoto := actFotoArticulo;
  EntornoFotos.BotonAsignar := btnFoto;
  EntornoFotos.BotonDescargar := btnDescargarFotos;
  EntornoFotos.DialogoFoto := dlgFoto;
  EntornoFotos.GrupoCabecera := gbCabecera;
  EntornoFotos.GrupoFoto := gbFotoProvisional;
  EntornoFotos.Imagen := imgFotoProvisional;
  EntornoFotos.Etiqueta := lblFotoProvisionalAsignacion;
  EntornoFotos.PaginasFicha := cxPageControl1;
  EntornoFotos.PaginaPedidoOriginal := tsPedidoOriginal;
  EntornoFotos.PaginasDetalle := cxPageControl2;
  btnReintentarFotos.Caption := SCaptionReintentarFotosSesion;
  EntornoFotos.PaginaFotos := tsFotosProvisionales;
  EntornoFotos.VistaFotos := tvFotosProvisionales;
  EntornoFotos.FuenteCabecera := dsTablaG;
  EntornoFotos.FuenteLineas := Dmm.dsSesionLin;
  EntornoFotos.FuenteFotos := Dmm.dsSesionFotos;
  EntornoFotos.Parametros := ParametrosApp;
  EntornoFotos.Fotos := FotosArticulos;
  EntornoFotos.Usuario := IdentidadSesion.Usuario;
  FFotos := TCoordinadorFotosProvisionalesSesion.Create(
    EntornoFotos);
  FreeAndNil(FNavegacion);
  ConexionSeries := ConexionPrincipal;
  EntornoNavegacion := TEntornoNavegacionComprasSesion.Crear(
    Self.Owner,
    actIrArticulos,
    actIrAlbaranesCompra,
    actIrPedidosCompra,
    actIrProveedor,
    btnIrADoc,
    btnIrPedAlb,
    btnIrProveedor,
    tvDocs,
    cbbSerie,
    Dmm.unqrySesDocs,
    Dmm.unqrySesionLin,
    Dmm.unqryTablaG,
    UbicacionSesion.Empresa,
    procedure(const AEmpresa: string; AItems: TStrings)
    begin
      CargarSeriesEmpresa(
        ConexionSeries,
        AEmpresa,
        'SE',
        AItems);
    end);
  EntornoNavegacion.ExisteArticulo :=
    function(ACodigo: string): Boolean
    var
      Duplicado: TResolverDuplicadoSesion;
    begin
      Duplicado := FServicioComprasSesiones.ResolverDuplicado(ACodigo, '');
      Result := Duplicado.Encontrado and
        SameText(Duplicado.CodigoArt, ACodigo);
    end;
  FNavegacion := TCoordinadorNavegacionComprasSesion.Create(
    EntornoNavegacion);
  CrearColaboradorMaterializacion;
  CrearColaboradorCopiaLineas;
  CrearColaboradorPestanas;
  CrearColaboradorModelo;
  CrearColaboradorProveedor;
  FreeAndNil(FImportadorOcr);
  EntornoImportacion := Default(TEntornoImportacionPedidoOcr);
  EntornoImportacion.Conexion := ConexionTrabajo;
  EntornoImportacion.Datos := Dmm;
  EntornoImportacion.Vista := tvLineas;
  EntornoImportacion.Usuario := IdentidadSesion.Usuario;
  EntornoImportacion.MaximoTallas := Length(FTallas.Columnas);
  EntornoImportacion.ObtenerDirectorioFotos :=
    function: string
    begin
      Result := DirectorioFotosAplicacion;
    end;
  EntornoImportacion.AplicarDuplicado :=
    procedure(const AResultado: TResolverDuplicadoSesion)
    begin
      FServicioComprasSesiones.AplicarDuplicadoEnLinea(AResultado);
    end;
  EntornoImportacion.CambiarEstadoColor :=
    procedure(AAplicando: Boolean)
    begin
      FAplicandoColorOcr := AAplicando;
    end;
  EntornoImportacion.AsignarColorLiteral :=
    procedure(const ALiteral: string)
    begin
      if FProveedor <> nil then
        FProveedor.AsignarColorBasicoLiteral(ALiteral);
    end;
  EntornoImportacion.AsignarColorCoincidente :=
    procedure
    begin
      if FProveedor <> nil then
        FProveedor.AsignarColorBasicoCoincidente;
    end;
  EntornoImportacion.PuedeGuardarFotos :=
    function: Boolean
    begin
      Result := Assigned(FotosArticulos);
    end;
  EntornoImportacion.GuardarFotos :=
    procedure(const ASerie, ANumero: string;
      const ASolicitudes: TSolicitudesFotosSesion;
      const AUsuario: string)
    begin
      FotosArticulos.Sesion.GuardarNuevasLote(
        ASerie,
        ANumero,
        ASolicitudes,
        AUsuario);
    end;
  FImportadorOcr := TCoordinadorImportacionPedidoOcr.Create(
    EntornoImportacion);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorMaterializacion;
var
  EntornoMaterializacion: TEntornoMaterializacionCompraSesion;
begin
  EntornoMaterializacion :=
    Default(TEntornoMaterializacionCompraSesion);
  EntornoMaterializacion.Propietario := Self;
  EntornoMaterializacion.Conexion := ConexionTrabajo;
  EntornoMaterializacion.Servicio := FServicioComprasSesiones;
  EntornoMaterializacion.Usuario := IdentidadSesion.Usuario;
  EntornoMaterializacion.Cabecera := Dmm.unqryTablaG;
  EntornoMaterializacion.Lineas := Dmm.unqrySesionLin;
  EntornoMaterializacion.Celdas := Dmm.unqrySesionCel;
  EntornoMaterializacion.Documentos := Dmm.unqrySesDocs;
  EntornoMaterializacion.FuenteAlmacenes := Dmm.dsAlmacenes;
  EntornoMaterializacion.FuenteTarifas := Dmm.dsTarifas;
  EntornoMaterializacion.FuenteTemporadas := Dmm.dsTemporadas;
  EntornoMaterializacion.Registrar :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  EntornoMaterializacion.GuardarPropiedades :=
    procedure
    begin
      if FPropiedadesFamilia <> nil then
      begin
        FPropiedadesFamilia.GuardarBorrador;
        FPropiedadesFamilia.Actualizar;
      end;
    end;
  EntornoMaterializacion.RefrescarFotos :=
    procedure
    begin
      if FFotos <> nil then
        FFotos.RefrescarLista;
    end;
  FAplicacionMaterializacion :=
    CrearAplicacionMaterializacionCompraSesionVcl(EntornoMaterializacion);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorCopiaLineas;
var
  EntornoCopia: TEntornoCopiaLineasSesion;
begin
  // CrearTablaPrincipal puede repetirse al reprocesar perfiles.
  FreeAndNil(FCopiaLineas);
  EntornoCopia := Default(TEntornoCopiaLineasSesion);
  EntornoCopia.Servicio := FServicioComprasSesiones;
  EntornoCopia.Usuario := IdentidadSesion.Usuario;
  EntornoCopia.Cabecera := Dmm.unqryTablaG;
  EntornoCopia.Lineas := Dmm.unqrySesionLin;
  EntornoCopia.Vista := tvLineas;
  EntornoCopia.ColumnasTallas := FTallas.Columnas;
  EntornoCopia.ColumnaColor := dbcLinColor;
  EntornoCopia.ColumnaPestana := dbcLinPestana;
  EntornoCopia.ObtenerGestorTallas :=
    function: TGestorGridTallas
    begin
      Result := GestorTallas;
    end;
  EntornoCopia.RefrescarTotalesSesion :=
    procedure
    begin
      Dmm.RefrescarTotalesSesion;
    end;
  EntornoCopia.ReordenarLineas :=
    function(ALinea: Integer): Integer
    begin
      Result := ReordenarLineasSesion(ALinea);
    end;
  EntornoCopia.CopiarPreciosTalla :=
    procedure(ALineaOrigen, ALineaDestino: Integer)
    begin
      CopiarPreciosTallaCopia(ALineaOrigen, ALineaDestino);
    end;
  FCopiaLineas := TCoordinadorCopiaLineasSesion.Create(EntornoCopia);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorPestanas;
var
  EntornoPestanas: TEntornoPestanasSesion;
begin
  FreeAndNil(FPestanasSesion);
  EntornoPestanas := Default(TEntornoPestanasSesion);
  EntornoPestanas.Vista := tvLineas;
  EntornoPestanas.Columna := dbcLinPestana;
  EntornoPestanas.Lineas := Dmm.unqrySesionLin;
  EntornoPestanas.BotonReferencia := btnNuevoColor;
  EntornoPestanas.Contenedor := cxgrdLineas.Parent;
  EntornoPestanas.Rejilla := cxgrdLineas;
  EntornoPestanas.ObtenerCopia :=
    function: TCoordinadorCopiaLineasSesion
    begin
      Result := FCopiaLineas;
    end;
  EntornoPestanas.LeerValores :=
    function(AIdAtributo: string): TArray<string>
    begin
      Result := ValoresAtributoUniDAC(ConexionTrabajo, AIdAtributo);
    end;
  EntornoPestanas.RecargarCantidades :=
    procedure
    begin
      RecargarTallasDiferido;
    end;
  EntornoPestanas.Avisar :=
    procedure(AMensaje: string)
    begin
      ShowMessage_fza(AMensaje);
    end;
  FPestanasSesion := TPresentadorPestanasSesion.Create(Self,
    EntornoPestanas);
  FRotulosCargados := False;
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorModelo;
var
  EntornoModelo: TEntornoModeloProveedorSesion;
begin
  FreeAndNil(FModeloPrv);
  EntornoModelo := Default(TEntornoModeloProveedorSesion);
  EntornoModelo.Propietario := Self;
  EntornoModelo.Conexion := ConexionTrabajo;
  EntornoModelo.Servicio := FServicioComprasSesiones;
  EntornoModelo.Usuario := IdentidadSesion.Usuario;
  EntornoModelo.Cabecera := Dmm.unqryTablaG;
  EntornoModelo.Lineas := Dmm.unqrySesionLin;
  EntornoModelo.Vista := tvLineas;
  EntornoModelo.ColumnaModelo := dbcLinRefPrv;
  EntornoModelo.RefrescarTallas :=
    procedure
    begin
      if GestorTallas <> nil then
      begin
        GestorTallas.RecalcularMaxColumnas;
        GestorTallas.ActualizarCaptionsLineaActiva;
      end;
    end;
  EntornoModelo.FijarTallajeDefecto :=
    procedure(AIdConjunto: Integer)
    begin
      Dmm.TallajeDefectoActual := AIdConjunto;
    end;
  EntornoModelo.OfrecerDistribucion :=
    procedure(ALineaOrigen: Integer)
    begin
      FCopiaLineas.OfrecerDistribucion(ALineaOrigen);
    end;
  EntornoModelo.GenerarCodigoArticulo :=
    function(
      AOrigen: TOrigenGeneracionCodigoArticuloSesion): Boolean
    begin
      if AOrigen = ogcaFamilia then
        Result := Dmm.GenerarCodigoArticuloTrasCambiarFamilia
      else
        Result := Dmm.GenerarCodigoArticuloTrasCambiarModelo;
    end;
  EntornoModelo.RegistrarAviso :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  FModeloPrv := TBuscadorModeloProveedorSesion.Create(EntornoModelo);
end;

procedure TfrmMtoComprasSesiones.CrearColaboradorProveedor;
var
  EntornoProveedor: TEntornoProveedorSesion;
begin
  FreeAndNil(FProveedor);
  EntornoProveedor := Default(TEntornoProveedorSesion);
  EntornoProveedor.Conexion := ConexionTrabajo;
  EntornoProveedor.Servicio := FServicioComprasSesiones;
  EntornoProveedor.Datos := Dmm;
  EntornoProveedor.BusquedaVisual := BusquedaVisual;
  EntornoProveedor.Vista := tvLineas;
  EntornoProveedor.ColumnaColor := dbcLinColor;
  EntornoProveedor.ColumnaColorBasico := dbcLinColorBasico;
  EntornoProveedor.BotonKits := btnAplicarKit;
  EntornoProveedor.ObtenerGestorTallas :=
    function: TGestorGridTallas
    begin
      Result := GestorTallas;
    end;
  EntornoProveedor.MostrarNombreProveedor :=
    procedure(ATexto: string)
    begin
      lblProveedorNombre.Caption := ATexto;
    end;
  EntornoProveedor.RefrescarVisibilidadTipoIva :=
    procedure
    begin
      RefrescarVisibilidadTipoIva;
    end;
  EntornoProveedor.AbrirDistribuidor :=
    procedure(ACodigoKit: string)
    begin
      FTallas.AbrirDistribuidor(ACodigoKit);
    end;
  EntornoProveedor.Registrar :=
    procedure(ATexto: string)
    begin
      LogSes(ATexto);
    end;
  FProveedor := TCoordinadorProveedorSesion.Create(EntornoProveedor);
end;

// ===========================================================================
//   TJvEnterAsTab — apagar mientras el grid tiene foco
// ===========================================================================
// TJvEnterAsTab heredado de TfrmBase convierte VK_RETURN en VK_TAB a nivel
// de mensaje. Lo apagamos al entrar al grid y reactivamos al salir, asi
// Enter navega celda a celda (combinado con FocusCellOnTab del grid).
// La logica vive en inLibGridTallasInline.ActivarEnterComoTab — funciona
// igual para cualquier Mto que use el patron.
procedure TfrmMtoComprasSesiones.cxgrdLineasEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;
procedure TfrmMtoComprasSesiones.btnGrabarClick(Sender: TObject);
begin
  LogSes('btnGrabarClick INICIO (delega al inherited)');
  inherited;
  LogSes('btnGrabarClick FIN. master/detail han hecho Post.');
  if FPropiedadesFamilia <> nil then
    FPropiedadesFamilia.GuardarBorrador;
  if (Dmm <> nil) and Dmm.unqrySesionLin.Active then
    ReordenarLineasSesion(
      Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger);
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar la
  // fila (los Posts del master/detail provocan re-fetch).
  RecargarTallasVisibles;
  RecargarTallasDiferido;
end;

// ===========================================================================
//   Bootstrapping
// ===========================================================================

//function TfrmMtoComprasSesiones.Dmm: TdmComprasSesiones;
//begin
//  Result := tdmDataModule as TdmComprasSesiones;
//end;

// La foto sigue al articulo de la linea activa de la sesion
// (CODIGO_ART_TENTATIVO_SESLIN; las sesiones trabajan a nivel articulo,
// sin SKU). Las fotos propias de la sesion se guardan en
// fza_compras_sesiones_fotos y Ctrl+F abre su visor grande editable.
procedure TfrmMtoComprasSesiones.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineas.DataController.DataSource) then
  begin
    ds := tvLineas.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Ademas de dsTablaG (cabecera de sesion) enganchamos dsSesionLin para
// que la foto flotante refresque al moverse entre lineas.
function TfrmMtoComprasSesiones.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmm) then
    Result := [dsTablaG, dmm.dsSesionLin]
  else
    Result := [dsTablaG];
end;

function TfrmMtoComprasSesiones.DirectorioFotosAplicacion: string;
begin
  Result := '';
  if Assigned(ParametrosApp) then
    Result := Trim(ParametrosApp.GetPath('appDirFotos'));
end;

procedure TfrmMtoComprasSesiones.ImportarPedidoOcr(
  const AFicheroJson: string);
var
  Resultado: TResultadoImportacionPedidoOcr;
begin
  Resultado := FImportadorOcr.Ejecutar(AFicheroJson);
  Dmm.unqrySesionLin.Refresh;
  Dmm.RefrescarTotalesSesion;
  ReconstruirTallas;
  if FFotos <> nil then
    FFotos.RefrescarLista;
  FVisorPedidoOriginal.Cargar;
  Resultado.Paginas := FVisorPedidoOriginal.CantidadPaginas;
  cxPageControl1.ActivePage := tsPedidoOriginal;
  cxPageControl1Change(cxPageControl1);
  ShowMessage_fza(FormatearResultadoImportacionPedidoOcr(Resultado));
end;
procedure TfrmMtoComprasSesiones.btnImportarPedidoClick(
  Sender: TObject);
var
  CasoGuardado: ICasoUsoGuardadoMtoGen;
  ResultadoOcr: TResultadoProcesoPedidoOcr;
  ResultadoGuardado: TResultadoGuardadoMtoGen;
  sAlmacen: string;
  sEmpresa: string;
  sSerie: string;
begin
  inherited;
  dlgImportarPedido.Filter := SFiltroDocumentoPdfPedidoSesionCompra;
  dlgImportarPedido.Options := dlgImportarPedido.Options +
    [ofPathMustExist, ofFileMustExist];
  if dlgImportarPedido.Execute then
  begin
    if (Dmm = nil) or Dmm.unqryTablaG.IsEmpty then
      raise Exception.Create(SErrorSesionCompraNoActiva);
    if not Dmm.unqrySesionLin.IsEmpty then
      raise Exception.Create(
        SErrorImportacionOcrSesionConLineas);
    if Dmm.unqryTablaG.State = dsInsert then
    begin
      sEmpresa := Trim(UbicacionSesion.Empresa);
      sAlmacen := Trim(UbicacionSesion.Almacen);
      if sEmpresa = '' then
        raise Exception.Create(
          SErrorUsuarioSinEmpresaImportacionOcr);
      if sAlmacen = '' then
        raise Exception.Create(
          SErrorUsuarioSinAlmacenImportacionOcr);
      sSerie := ObtenerSerieDefecto(
        ConexionTrabajo,
        sEmpresa,
        'SE',
        sAlmacen);
      if sSerie = '' then
        raise Exception.CreateFmt(
          SErrorEmpresaSinSerieSesionesImportacionOcr,
          [sEmpresa]);
      Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString :=
        sEmpresa;
      Dmm.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString :=
        sAlmacen;
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString := sSerie;
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').Clear;
    end;
    if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      CasoGuardado := CrearCasoUsoGuardadoMtoGenUniDAC(
        ConexionTrabajo);
      ResultadoGuardado := CasoGuardado.Ejecutar(
        procedure
        begin
          GrabarDatasets(Dmm);
        end);
      if ResultadoGuardado = rgmAbortado then
        raise Exception.Create(
          SErrorGuardarSesionAntesImportacionOcr);
    end;
    Screen.Cursor := crHourGlass;
    btnImportarPedido.Enabled := False;
    try
      try
        ResultadoOcr := TProcesoPedidoOcr.Ejecutar(
          dlgImportarPedido.FileName,
          procedure
          begin
            Application.ProcessMessages;
          end);
        try
          ImportarPedidoOcr(ResultadoOcr.FicheroJson);
        finally
          TProcesoPedidoOcr.EliminarTrabajo(
            ResultadoOcr.DirectorioTrabajo);
        end;
      except
        on E: Exception do
          ShowMessage_fza(
            Format(SErrorImportarPedidoSesionCompra, [E.Message]));
      end;
    finally
      btnImportarPedido.Enabled := True;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.cxPageControl2Change(Sender: TObject);
begin
  if FPropiedadesFamilia <> nil then
    FPropiedadesFamilia.Actualizar;
  if Assigned(FTrazabilidadSesion) then
    FTrazabilidadSesion.ActualizarPagina;
  if FFotos <> nil then
    FFotos.ActualizarPaginaDetalle;
  if cxPageControl2.ActivePage = cxTabSheet1 then
  begin
    // Las tallas son columnas no-bound. Al volver a Lineas se publican
    // de nuevo por si un cambio de estado de la cabecera limpio Values[].
    RecargarTallasVisibles;
    RecargarTallasDiferido;
  end;
end;

procedure TfrmMtoComprasSesiones.cxPageControl1Change(Sender: TObject);
begin
  if FFotos <> nil then
    FFotos.ActualizarPaginaFicha;
  if cxPageControl1.ActivePage = tsPedidoOriginal then
  begin
    FVisorPedidoOriginal.CargarSiVacio;
    // Si la imagen ya esta cargada se conserva la vista actual: pagina,
    // zoom y desplazamiento. Con el boton Fijar zoom pulsado el zoom se
    // mantiene tambien al cambiar de sesion; suelto, cada pedido se
    // encaja en el visor al cargarse.
  end
  else
  begin
    // Cancelar una linea puede reconstruir el DataController mientras se
    // consulta el documento. Al volver se restauran los Values[] de tallas.
    RecargarTallasDiferido;
  end;
end;

function TfrmMtoComprasSesiones.SqlRestriccionUsuario: string;
begin
  // Sesiones de compra: empresa y almacén destino (no llevan caja)
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_SES',
    'CODIGO_ALM_SES',
    '');
end;

procedure TfrmMtoComprasSesiones.CrearTablaPrincipal;
var
  rTrazabilidad: TEntornoTrazabilidadSesion;
begin
  FDependencias.Validar;
  inherited;
  if tdmDataModule <> nil then
  begin
    Dmm := tdmDataModule as TdmComprasSesiones;
    if Assigned(ParametrosApp) then
      Dmm.ActivacionTrazabilidad :=
        TActivacionTrazabilidad.Leer(ParametrosApp);
    CrearServicioSesion;
    CrearColaboradores;
    EnlazarListasCabecera;
    EnlazarDetalleSesion;
    rTrazabilidad := Default(TEntornoTrazabilidadSesion);
    rTrazabilidad.Lineas := Dmm.dsSesionLin;
    rTrazabilidad.RecargarCeldas :=
      procedure
      begin
        Dmm.RefrescarCeldasLineaActual;
      end;
    rTrazabilidad.OtroLote :=
      procedure
      begin
        // La copia lee cantidades y coloca el editor en el grid visible.
        cxPageControl2.ActivePage := cxTabSheet1;
        FCopiaLineas.DuplicarLineaOtroLote;
      end;
    rTrazabilidad.MarcarLotes :=
      procedure(AActivar: Boolean)
      begin
        Dmm.MarcarArticuloPorLotes(AActivar);
      end;
    FreeAndNil(FTrazabilidadSesion);
    FTrazabilidadSesion := TFichaTrazabilidadSesion.Crear(Self,
      cxPageControl2, Dmm.dsSesionCel,
      function: TTrazabilidadAlta
      begin
        Result := Dmm.TrazabilidadLineaActual;
      end,
      function: Boolean
      begin
        Result := SameText(Dmm.unqryTablaG.FieldByName(
          'ESTADO_SES').AsString, 'BORRADOR');
      end, rTrazabilidad);
    EnlazarPestanaProveedor;
  end;
end;

procedure TfrmMtoComprasSesiones.CrearServicioSesion;
begin
  FreeAndNil(FServicioComprasSesiones);
  FServicioComprasSesiones := CrearServicioComprasSesiones(
    ConexionTrabajo, Dmm, FotosArticulos,
    FDependencias.CatalogoSql,
    FDependencias.IncidenciasSql);
  pkFieldName := 'SERIE_SES;NUMERO_SES';
end;

procedure TfrmMtoComprasSesiones.EnlazarListasCabecera;
begin
  cbbEmpresa.Properties.ListSource   := Dmm.dsEmpresas;
  cbbAlmacen.Properties.ListSource   := Dmm.dsAlmacenes;
  cbbTarifa.Properties.ListSource    := Dmm.dsTarifas;
  cbbTemporada.Properties.ListSource := Dmm.dsTemporadas;
  cbbTotalesFORMA_PAGO_SES.Properties.ListSource := Dmm.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por nombre).
  // Reutiliza el lookup Dmm.unqryProveedores, ya cargado para el rotulo.
  cbbProveedor.Properties.ListSource := Dmm.dsProveedores;
  cbbVariacion.Properties.ListSource := Dmm.dsVariaciones;
  ConfigurarVariacionesLinea;
end;

procedure TfrmMtoComprasSesiones.AsegurarColumnaVariacionLinea;
var
  oCabecera: TDataSet;
  bVariosTipos: Boolean;
begin
  oCabecera := dsTablaG.DataSet;
  bVariosTipos := Assigned(oCabecera) and oCabecera.Active and
    ((oCabecera.State in dsEditModes) or not oCabecera.IsEmpty);
  if bVariosTipos then
    bVariosTipos := SameText(oCabecera.FieldByName(
      'ESVARIOS_TIPOS_VARIACION_SES').AsString, 'S');
  if dbcLinVariacion = nil then
  begin
    dbcLinVariacion := tvLineas.CreateColumn;
    dbcLinVariacion.Name := 'dbcLinVariacion';
  end;
  dbcLinVariacion.Caption := SCaptionVariacionLineaSesion;
  dbcLinVariacion.DataBinding.FieldName := 'CODIGO_VAR_SESLIN';
  if not (dbcLinVariacion.Properties is TcxImageComboBoxProperties) then
    dbcLinVariacion.PropertiesClass := TcxImageComboBoxProperties;
  dbcLinVariacion.Properties.OnValidate := ValidarVariacionLinea;
  dbcLinVariacion.Visible := bVariosTipos;
  dbcLinVariacion.VisibleForCustomization := bVariosTipos;
  dbcLinVariacion.Options.Editing := bVariosTipos;
  dbcLinVariacion.Options.Focusing := bVariosTipos;
  if dbcLinVariacion.Width < 120 then
    dbcLinVariacion.Width := 120;
  dbcLinVariacion.Index := dbcLinPrecioVenta.Index + 1;
end;

procedure TfrmMtoComprasSesiones.ConfigurarVariacionesLinea;
var
  oPropiedades: TcxImageComboBoxProperties;
  oItem: TcxImageComboBoxItem;
begin
  AsegurarColumnaVariacionLinea;
  oPropiedades := TcxImageComboBoxProperties(dbcLinVariacion.Properties);
  oPropiedades.Items.Clear;
  oItem := oPropiedades.Items.Add;
  oItem.Value := '';
  oItem.Description := SCaptionSinVariacionSesion;
  Dmm.unqryVariaciones.First;
  while not Dmm.unqryVariaciones.Eof do
  begin
    oItem := oPropiedades.Items.Add;
    oItem.Value := Dmm.unqryVariaciones.FieldByName('CODIGO_VAR').AsString;
    oItem.Description := Dmm.unqryVariaciones.FieldByName(
      'NOMBRE_VAR').AsString;
    Dmm.unqryVariaciones.Next;
  end;
end;

procedure TfrmMtoComprasSesiones.ValidarVariacionLinea(Sender: TObject;
  var DisplayValue: TcxEditValue; var ErrorText: TCaption;
  var Error: Boolean);
begin
  FTallas.ValidarVariacionLinea(Sender, DisplayValue, ErrorText, Error);
  if not Error then
    RefrescarRotulosVariacion;
end;

procedure TfrmMtoComprasSesiones.EnlazarDetalleSesion;
begin
  Dmm.unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesionLin.MasterSource := dsTablaG;
  // Hooks del detalle: al cambiar de fila el dataset hace Post
  // automatico, cxGrid repinta desde el dataset y pierde los Values[]
  // no-bound de las tallas; hay que volver a publicarlos.
  Dmm.unqrySesionLin.BeforePost   := unqrySesionLinBeforePostHook;
  Dmm.unqrySesionLin.AfterPost    := unqrySesionLinAfterPostHook;
  Dmm.unqrySesionLin.BeforeInsert := unqrySesionLinBeforeInsertHook;
  Dmm.unqrySesionLin.AfterInsert  := unqrySesionLinAfterInsertHook;
  Dmm.unqrySesionLin.AfterCancel  := unqrySesionLinAfterCancelHook;
  Dmm.unqrySesionLin.BeforeDelete := unqrySesionLinBeforeDeleteHook;
  Dmm.unqrySesionLin.AfterDelete  := unqrySesionLinAfterDeleteHook;
  // Cualquier re-fetch (Refresh explicito, master/detail, navegador)
  // resetea los Values[] no-bound: se recargan tras el re-fetch.
  Dmm.unqrySesionLin.AfterRefresh := unqrySesionLinRecargarTallasHook;
  Dmm.unqrySesionLin.AfterOpen    := unqrySesionLinRecargarTallasHook;
  if not Dmm.unqrySesionLin.Active then
    Dmm.unqrySesionLin.Open;
  if not Dmm.unqrySesionCel.Active then
    Dmm.unqrySesionCel.Open;
  // Master/detail de la pestania 'Documentos'.
  Dmm.unqrySesDocs.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesDocs.MasterSource := dsTablaG;
  if not Dmm.unqrySesDocs.Active then
    Dmm.unqrySesDocs.Open;
  // Master/detail de la pestania de fotos provisionales.
  Dmm.unqrySesionFotos.MasterFields := 'SERIE_SES;NUMERO_SES';
  Dmm.unqrySesionFotos.MasterSource := dsTablaG;
  if not Dmm.unqrySesionFotos.Active then
    Dmm.unqrySesionFotos.Open;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;
  Dmm.dsSesionLin.OnDataChange := dsSesionLinDataChangeHook;
  tvDocs.DataController.DataSource := Dmm.dsSesDocs;
  tvFotosProvisionales.DataController.DataSource := Dmm.dsSesionFotos;
  // Las lineas son una hoja de edicion: al teclear en Modelo prov. la
  // tecla debe entrar al editor/lookup, no a la navegacion incremental.
  tvLineas.OptionsBehavior.AlwaysShowEditor := True;
  tvLineas.OptionsBehavior.IncSearch := False;
  FTallas.ConfigurarDatos(
    Dmm.unqryTablaG,
    Dmm.unqrySesionLin,
    Dmm.dsSesionLin);
  FModeloPrv.RecargarModelos;
  // Al navegar de una sesion a otra hay que recargar las cantidades de
  // tallas: sin esto las celdas no-bound quedan vacias.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  dsTablaG.OnStateChange := dsTablaGStateChangeHook;
  RefrescarRotulosVariacion;
  RefrescarColumnasTallas;
end;

// Los letreros de color, sistema de tallas y «Otro color» siguen al tipo
// de variación de la sesión (FZ-ISSUE-420): con «Aroma y medida» dicen
// Aroma, Medidas y Otro aroma, la lista de sistemas solo ofrece sus
// colecciones y «C. básico» solo se muestra cuando la fila es un color.
// AForzar (FZ-ISSUE-435): relee los rótulos aunque la variación sea la
// misma, porque pueden haberse cambiado en Tipos de Variaciones; la lista
// de sistemas solo se vuelve a filtrar si cambia la variación.
procedure TfrmMtoComprasSesiones.AplicarEtiquetas;
begin
  inherited;
  // El perfil antiguo no contiene la columna y puede ocultarla.
  AsegurarColumnaVariacionLinea;
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
  lblVariacion.Caption := SCaptionSesionVariacionDefecto;
  // Pestañas creadas en código: no las recoge Traducciones.Aplicar
  // (FZ-ISSUE-739).
  if Assigned(FTrazabilidadSesion) then
    FTrazabilidadSesion.AplicarTraduccion;
  if Assigned(FPropiedadesFamilia) then
    FPropiedadesFamilia.AplicarTraduccion;
  // Los nombres de ejes y el botón Otro valor pertenecen a la variación.
  if Assigned(Dmm) then
    RefrescarRotulosVariacion(True);
end;

procedure TfrmMtoComprasSesiones.RefrescarRotulosVariacion(
  AForzar: Boolean);
var
  bCambiaVariacion: Boolean;
  sCodigo: string;
begin
  if not FRefrescandoRotulos then
  begin
    FRefrescandoRotulos := True;
    try
      sCodigo := '';
      if (Dmm <> nil) and Dmm.unqryTablaG.Active and
         (not Dmm.unqryTablaG.IsEmpty) then
        sCodigo := Trim(Dmm.unqryTablaG.FieldByName(
          'CODIGO_VAR_SES').AsString);
      if (Dmm <> nil) and Dmm.unqrySesionLin.Active and
         ((Dmm.unqrySesionLin.State in dsEditModes) or
          not Dmm.unqrySesionLin.IsEmpty) then
      begin
        if Dmm.unqrySesionLin.FieldByName(
             'TIPO_LINEA_SESLIN').AsString = 'ESCALAR' then
        begin
          sCodigo := '';
          if SameText(Dmm.unqryTablaG.FieldByName(
               'ESVARIOS_TIPOS_VARIACION_SES').AsString, 'S') then
            sCodigo := Dmm.unqrySesionLin.FieldByName(
              'CODIGO_VAR_SESLIN').AsString;
        end
        else if Dmm.unqrySesionLin.FieldByName(
          'CODIGO_VAR_SESLIN').AsString <> '' then
          sCodigo := Dmm.unqrySesionLin.FieldByName(
            'CODIGO_VAR_SESLIN').AsString;
      end;
      bCambiaVariacion := (not FRotulosCargados) or
        (sCodigo <> FRotulosVariacion.CodigoVariacion);
      if bCambiaVariacion or AForzar then
      begin
        FRotulosVariacion := CargarRotulosVariacionUniDAC(
          ConexionTrabajo, sCodigo);
        FRotulosCargados := True;
        dbcLinColor.Caption := FRotulosVariacion.EjeFila;
        dbcFotoColor.Caption := FRotulosVariacion.EjeFila;
        dbcLinTallas.Caption := FRotulosVariacion.SistemaPivote;
        dbcPrvKitSistema.Caption := FRotulosVariacion.SistemaPivote;
        dbcPrvKitDetValor.Caption := FRotulosVariacion.EjePivote;
        btnNuevoColor.Caption := FRotulosVariacion.OtroValorFila;
        // FZ-ISSUE-451: un tipo de un solo eje («Solo medida») no tiene
        // valor de fila; sin su columna, el Tab pasa de la descripción al
        // precio y no hay dónde teclearlo por error.
        dbcLinColor.Visible := FRotulosVariacion.TieneEjeFila;
        dbcLinColor.VisibleForCustomization := FRotulosVariacion.TieneEjeFila;
        dbcFotoColor.Visible := FRotulosVariacion.TieneEjeFila;
        btnNuevoColor.Visible := FRotulosVariacion.TieneEjeFila;
        dbcLinColorBasico.Visible := FRotulosVariacion.EsColorBasico and
          FRotulosVariacion.TieneEjeFila;
        if FPestanasSesion <> nil then
          FPestanasSesion.AplicarRotulos(FRotulosVariacion);
        if bCambiaVariacion then
          FTallas.FiltrarPorVariacion(sCodigo);
      end;
    finally
      FRefrescandoRotulos := False;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.PestanaActivada;
begin
  inherited;
  if FRotulosCargados and Assigned(FTallas) then
    RefrescarRotulosVariacion(True);
end;

// El usuario cambia el tipo de variación de la sesión que edita: además
// de los rótulos, se descarta un tallaje por defecto de otro tipo.
// Las líneas existentes conservan la variación que ya tenían.
procedure TfrmMtoComprasSesiones.VariacionSesionCambiada;
begin
  if (Dmm <> nil) and (FTallas <> nil) then
  begin
    FTallas.FiltrarPorVariacion(
      Dmm.unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString);
    if not FTallas.ContieneSistema(Dmm.TallajeDefectoActual) then
      Dmm.TallajeDefectoActual := 0;
  end;
  RefrescarRotulosVariacion(True);
end;

procedure TfrmMtoComprasSesiones.EnlazarPestanaProveedor;
begin
  dsPrvFicha.DataSet := Dmm.unqryPrvFicha;
  tvPrvKits.DataController.DataSource    := Dmm.dsPrvKits;
  tvPrvKitsDet.DataController.DataSource := Dmm.dsPrvKitsDet;
  // Desplegable de kits de la cabecera: etiqueta descriptiva por kit.
  //cbbKitProv.Properties.ListSource := Dmm.dsPrvKitsCombo;
  FProveedor.ActualizarRotuloProveedor;
  FProveedor.RecargarProveedorSesion;
  RefrescarVisibilidadTipoIva;
  if FFotos <> nil then
    FFotos.Refrescar;
end;

procedure TfrmMtoComprasSesiones.dsTablaGDataChangeHook(Sender: TObject;
                                                          Field: TField);
begin
  if ((Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_SES')) and
     (Dmm <> nil) and Dmm.unqryTablaG.Active and
     (not Dmm.unqryTablaG.IsEmpty) then
    Dmm.RefrescarAlmacenes(
      Dmm.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  if (Field <> nil) and (Dmm <> nil) and
     (SameText(Field.FieldName, 'CODIGO_EMP_SES') or
      SameText(Field.FieldName, 'CODIGO_ALM_SES')) then
    Dmm.ProponerSerieNuevaSesion;
  // Refrescar el rotulo del proveedor al navegar entre sesiones (Field=nil)
  // o al cambiar CODIGO_PRV_SES tecleado directamente en el ButtonEdit.
  // Otra sesión: sus líneas tienen otras copas.
  if (Field = nil) and (FPestanasSesion <> nil) then
    FPestanasSesion.RefrescarPestanas;
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_SES') then
  begin
    FProveedor.ActualizarRotuloProveedor;
    // Lista de modelos del desplegable "Modelo prov." acotada al proveedor.
    FModeloPrv.RecargarModelos;
    // Pestana Proveedor: ficha + kits del proveedor de la sesion.
    FProveedor.RecargarProveedorSesion;
    // Defectos del proveedor (margen %, sistema de tallas) solo cuando el
    // usuario esta cambiando el proveedor en la cabecera, no al navegar.
    if (Field <> nil) and (Dmm <> nil) and
       (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
    begin
      FProveedor.CopiarDefectosProveedor;
      RefrescarVisibilidadTipoIva;
    end;
  end;
  if (Field <> nil) and SameText(Field.FieldName, 'CODIGO_EMP_SES') and
     (Dmm <> nil) and (Dmm.unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionPrincipal), Dmm.unqryTablaG,
      'CODIGO_EMP_SES', 'ESIVA_RECARGO_COMPRAS_SES');
    Dmm.RefrescarTotalesSesion;
  end;
  if (Field <> nil) and
     (SameText(Field.FieldName, 'TIPO_IVA_SES') or
      SameText(Field.FieldName, 'ESIVA_RECARGO_COMPRAS_SES')) and
     (Dmm <> nil) then
  begin
    Dmm.RefrescarTotalesSesion;
    RefrescarVisibilidadTipoIva;
  end;
  if (Field <> nil) and SameText(Field.FieldName,
     'ESVARIOS_TIPOS_IVA_SES') then
    RefrescarVisibilidadTipoIva;
  if (Field <> nil) and SameText(Field.FieldName, 'CODIGO_VAR_SES') then
    VariacionSesionCambiada;
  if (Field = nil) or SameText(Field.FieldName,
    'ESVARIOS_TIPOS_VARIACION_SES') then
    AsegurarColumnaVariacionLinea;
  // FIX: El formato distribuido solo se puede cambiar al crear la sesión.
  // Si el estado no es dsInsert, ponemos el check como ReadOnly.
  if (Field = nil) and (Dmm <> nil) and (Dmm.unqryTablaG <> nil) then
    chkFormatoDistribuido.Properties.ReadOnly :=
                                            (Dmm.unqryTablaG.State <> dsInsert);
  // Field = nil => cambio de record activo en el master (no es un cambio
  // puntual de un campo del registro actual). Es el momento de
  // recalcular columnas y volver a publicar las cantidades de las
  // lineas de esta sesion.
  if Field = nil then
  begin
    RefrescarVisibilidadTipoIva;
    if FFotos <> nil then
      FFotos.Refrescar;
    FVisorPedidoOriginal.Cargar;
    RefrescarRotulosVariacion;
    ReconstruirTallas;
  end;
  RefrescarOpcionesDescripcion;
end;

procedure TfrmMtoComprasSesiones.dsTablaGStateChangeHook(Sender: TObject);
begin
  // Conserva la gestion de botones y el rotulo Editando/Navegando del
  // mantenimiento base.
  inherited dsTablaGStateChange(Sender);
  if (Dmm <> nil) and Dmm.unqrySesionLin.Active and
     not Dmm.unqrySesionLin.IsEmpty then
  begin
    // Edit/Insert/Post del maestro resincroniza el detalle en cxGrid y
    // borra las columnas no-bound aunque las cantidades sigan en SESCEL.
    RecargarTallasVisibles;
    RecargarTallasDiferido;
  end;
end;

procedure TfrmMtoComprasSesiones.RefrescarOpcionesDescripcion;
begin
  chkCopiarDescripcionFamilia.Enabled :=
    (Dmm = nil) or (not Dmm.DejarDescripcionEnBlanco);
end;

procedure TfrmMtoComprasSesiones.RefrescarVisibilidadTipoIva;
var
  sVarios : string;
begin
  if dbcLinTipoIva <> nil then
  begin
    dbcLinTipoIva.Visible := False;
    if (Dmm <> nil) and Dmm.unqryTablaG.Active and
       (Dmm.unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) then
    begin
      sVarios := UpperCase(Trim(
        Dmm.unqryTablaG.FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString));
      dbcLinTipoIva.Visible := sVarios = 'S';
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.cbbTipoIvaDefectoPropertiesChange(
  Sender: TObject);
begin
  inherited;
  RefrescarVisibilidadTipoIva;
  if Dmm <> nil then
    Dmm.RefrescarTotalesSesion;
end;

procedure TfrmMtoComprasSesiones.chkVariosTiposIvaPropertiesChange(
  Sender: TObject);
begin
  inherited;
  RefrescarVisibilidadTipoIva;
end;

procedure TfrmMtoComprasSesiones.chkRecargoComprasPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if Dmm <> nil then
    Dmm.RefrescarTotalesSesion;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterPostHook(
                                                      DataSet: TDataSet);
begin
  Dmm.unqrySesionLinAfterPost(DataSet);
  RefrescarVisibilidadTipoIva;
  // Al cambiar de fila el dataset hace Post automatico y cxGrid repinta
  // la fila abandonada, borrando sus Values[] no-bound.
  RecargarTallasVisibles;
  RecargarTallasDiferido;
end;

procedure TfrmMtoComprasSesiones.dsSesionLinDataChangeHook(
  Sender: TObject; Field: TField);
begin
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_VAR_SESLIN') then
    RefrescarRotulosVariacion;
  // Sin color básico en la variación (p. ej. aromas) no hay nada que
  // proponer a partir del texto de la fila.
  if (Field <> nil) and
     SameText(Field.FieldName, 'COLOR_TEXTO_SESLIN') and
     (not FAplicandoColorOcr) and
     FRotulosVariacion.EsColorBasico and
     (FProveedor <> nil) then
    FProveedor.AsignarColorBasicoCoincidente;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforePostHook(
  DataSet: TDataSet);
var
  sCodigo: string;
  sLiteral: string;
begin
  // El texto propone el basico en DataChange. Al guardar se respeta la
  // eleccion posterior del usuario y solo se valida su codigo.
  if FProveedor <> nil then
  begin
    sLiteral := DataSet.FieldByName(
      'CODIGO_ATB_COLOR_SESLIN').AsString;
    if not FProveedor.ResolverColorBasicoLiteral(sLiteral, sCodigo) then
      raise Exception.CreateFmt(
        SErrorColorBasicoCompraNoExiste, [sLiteral]);
    if not SameText(sLiteral, sCodigo) then
      DataSet.FieldByName(
        'CODIGO_ATB_COLOR_SESLIN').AsString := sCodigo;
  end;
  Dmm.unqrySesionLinBeforePost(DataSet);
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinRecargarTallasHook(
                                                      DataSet: TDataSet);
begin
  // AfterRefresh / AfterOpen comparten handler. La tabla de celdas ya
  // tiene la cantidad correcta: lo unico que falta es volver a pintarla
  // DESPUES de que el DataController procese el re-fetch.
  TThread.ForceQueue(nil,
    TThreadProcedure(
    procedure
    begin
      RecargarTallasVisibles;
      RefrescarVisibilidadTipoIva;
    end));
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeInsertHook(
  DataSet: TDataSet);
begin
  // Preparar master antes de insertar en el detail. Dispara tanto
  // desde btnAddLinea / btnNuevoColor como desde el navigator del grid.
  if Dmm.unqryTablaG.IsEmpty then
  begin
    MessageDlg_fza(SErrorCabeceraSesionAntesLineas,
               mtInformation, [mbOk], 0);
    Abort;
  end;
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  if Dmm.unqryTablaG.State = dsBrowse then
    Dmm.unqryTablaG.Edit;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterInsertHook(
  DataSet: TDataSet);
begin
  // Delegar al handler del DM (asigna FKs y numero de linea)
  Dmm.unqrySesionLinAfterInsert(DataSet);
  ReconstruirTallas;
  RecargarTallasDiferido;
  // Foco en Modelo prov. (primer campo de la linea)
  tvLineas.Controller.FocusedColumn := dbcLinRefPrv;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterCancelHook(
  DataSet: TDataSet);
begin
  // Cancel elimina el registro de insercion y cxGrid vuelve a construir su
  // buffer. Las cantidades persisten en SESCEL, pero hay que republicarlas.
  RecargarTallasDiferido;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinBeforeDeleteHook(
  DataSet: TDataSet);
var
  iLinea : Integer;
begin
  // Limpiar SESCEL de la linea ANTES del delete. No hay FK cascade
  // en BBDD; el patron es delete-on-app. Idempotente.
  iLinea := DataSet.FieldByName('LINEA_SESLIN').AsInteger;
  if iLinea > 0 then
  begin
    BorrarPropiedadesLineaSesion(ConexionTrabajo,
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString, iLinea);
    LogSes(Format('BeforeDelete: limpiando SESCEL linea=%d', [iLinea]));
    FServicioComprasSesiones.BorrarCeldasLinea(
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
      iLinea);
  end;
end;

procedure TfrmMtoComprasSesiones.unqrySesionLinAfterDeleteHook(
  DataSet: TDataSet);
begin
  LogSes('AfterDelete: RefrescarTotalesSesion + RecalcularMaxColumnas');
  Dmm.RefrescarTotalesSesion;
  RefrescarVisibilidadTipoIva;
  // Tras el delete el grid se repinta y borra los Values[] no ligados:
  // hay que recalcular columnas, cantidades y captions de lo que queda.
  ReconstruirTallas;
  ReordenarLineasDiferido;
end;

procedure TfrmMtoComprasSesiones.ResetForm;
begin
  inherited;
  FVisorPedidoOriginal.Cargar;
end;

procedure TfrmMtoComprasSesiones.FormCreate(Sender: TObject);
var
  EntornoVisor: TEntornoVisorPedidoOriginalSesion;
  GestorContexto: IGestorContextoSesion;
  i, IdxBase: Integer;
begin
  // OJO: TODO lo que vaya a usar el `inherited` (que ejecuta
  // ProcesarPerfiles -> CrearTablaPrincipal -> abre unqrySesionLin -> el
  // grid dispara OnFocusedRecordChanged sobre el gestor de tallas) tiene
  // que estar creado ANTES del inherited. Las columnas de talla se crean
  // aqui: si no existen, el recalculo del gestor seria un no-op.
  EntornoVisor := Default(TEntornoVisorPedidoOriginalSesion);
  EntornoVisor.Contenedor := scrPedidoOriginal;
  EntornoVisor.Imagen := imgPedidoOriginal;
  EntornoVisor.EtiquetaPagina := lblPaginaPedido;
  EntornoVisor.BotonAnterior := btnPaginaAnteriorPedido;
  EntornoVisor.BotonSiguiente := btnPaginaSiguientePedido;
  EntornoVisor.BotonAlejar := btnAlejarPedido;
  EntornoVisor.BotonAcercar := btnAcercarPedido;
  EntornoVisor.BotonAjustar := btnAjustarPedido;
  EntornoVisor.BotonZoomReal := btnZoomRealPedido;
  EntornoVisor.BotonFijarZoom := btnFijarZoomPedido;
  EntornoVisor.ObtenerDirectorio :=
    function: string
    begin
      Result := DirectorioFotosAplicacion;
    end;
  EntornoVisor.ObtenerSesion :=
    function(out ASerie, ANumero: string): Boolean
    begin
      ASerie := '';
      ANumero := '';
      Result := (Dmm <> nil) and Dmm.unqryTablaG.Active and
        (not Dmm.unqryTablaG.IsEmpty);
      if Result then
      begin
        ASerie := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
        ANumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
      end;
    end;
  FVisorPedidoOriginal := TVisorPedidoOriginalSesion.Create(
    EntornoVisor);
  CrearColaboradorTallas;
  FTallas.CrearColumnas;
  FRotulosVariacion := RotulosVariacionPorDefecto;
  inherited;
  FPropiedadesFamilia := TPropiedadesFamiliaSesion.Create(Self,
    cxPageControl2, Dmm.unqryTablaG, Dmm.unqrySesionLin,
    IdentidadSesion.Usuario,
    function(const ASerie, ANumero: string; ALinea: Integer):
      TServiciosPropiedadesArticulo
    begin
      Result := CrearServiciosPropiedadesSesion(
        ConexionTrabajo, ASerie, ANumero, ALinea);
    end);
  AplicarModoPrecioDefecto;
  chkDescripcionBlanco.Caption := SComprasDejarDescripcionBlanco;
  chkESVARIOS_TIPOS_VARIACION_SES.Caption :=
    SCaptionSesionVariosTiposVariacion;
  ConfigurarBotonBusquedaDesplegable(
    cbbProveedor,
    cbbProveedorPropertiesButtonClick);
  FFotos.ConfigurarCabecera;
  cxPageControl2.OnChange := cxPageControl2Change;
  FEstiloRecepcionVencida := TcxStyle.Create(Self);
  FEstiloRecepcionVencida.AssignedValues := [svTextColor];
  FEstiloRecepcionVencida.TextColor := clRed;
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;
  // Orden visual fijo de las columnas de lineas. Se hace DESPUES del
  // inherited porque el ancestro restaura el layout guardado y podria
  // alterar los Index. El bloque de tallas queda contiguo tras "Sistema
  // tallas"; totales y nro de linea al final.
  dbcLinRefPrv.Index       := 0;  // Modelo prov.
  dbcLinCodArt.Index       := 1;  // Codigo de articulo
  dbcLinFamilia.Index      := 2;  // Familia
  dbcLinDescripcion.Index  := 3;  // Descripcion
  dbcLinColor.Index        := 4;  // Color
  dbcLinColorBasico.Index  := 5;  // Color basico
  dbcLinPestana.Index      := 6;  // Valor de pestañas (oculta sin ellas)
  dbcLinPrecioCompra.Index := 7;  // Precio de compra
  dbcLinPrecioVenta.Index  := 8;  // Precio de venta
  AsegurarColumnaVariacionLinea;
  dbcLinTallas.Index       := 10; // Sistema de tallas
  IdxBase := dbcLinTallas.Index;
  FTallas.ReindexarColumnas(IdxBase);
  // Totales y nro de linea, tras el bloque de tallas pivotadas.
  dbcLinTotalTallas.Index  := IdxBase + Length(FTallas.Columnas) + 1;
  dbcLinImporteTotal.Index := IdxBase + Length(FTallas.Columnas) + 2;
  dbcLinNumero.Index       := IdxBase + Length(FTallas.Columnas) + 3;
  if FProveedor <> nil then
    FProveedor.CargarBasicosColor;
  // El contexto distribuye el log de la sesion sin estado global mutable.
  if Supports(ContextoSesion, IGestorContextoSesion, GestorContexto) then
    GestorContexto.AsignarLogSesion(nil);
end;

procedure TfrmMtoComprasSesiones.GridListaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  colFecha: TcxGridDBColumn;
  colPdte : TcxGridDBColumn;
  vFecha  : Variant;
  vPdte   : Variant;
  dFecha  : TDateTime;
  rPdte   : Double;
begin
  if (ARecord <> nil) and (Sender is TcxGridDBTableView) then
  begin
    colFecha :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'FECHA_TOPE_RECEPCION_SES');
    colPdte :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'CANTIDAD_PENDIENTE_RECEPCION_SES');
    if (colFecha <> nil) and (colPdte <> nil) then
    begin
      vFecha := ARecord.Values[colFecha.Index];
      vPdte := ARecord.Values[colPdte.Index];
      if not (VarIsNull(vFecha) or VarIsEmpty(vFecha) or
              VarIsNull(vPdte) or VarIsEmpty(vPdte)) then
      begin
        dFecha := VarToDateTime(vFecha);
        if VarIsNumeric(vPdte) then
          rPdte := vPdte
        else
          rPdte := StrToFloatDef(VarToStr(vPdte), 0);
        if (rPdte > 0) and (Trunc(dFecha) < Date) then
          AStyle := FEstiloRecepcionVencida;
      end;
    end;
  end;
end;

function TfrmMtoComprasSesiones.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (FPropiedadesFamilia <> nil) then
    FPropiedadesFamilia.GuardarBorrador;
end;

procedure TfrmMtoComprasSesiones.FormDestroy(Sender: TObject);
var
  GestorContexto: IGestorContextoSesion;
begin
  FreeAndNil(FPropiedadesFamilia);
  FreeAndNil(FTrazabilidadSesion);
  if Dmm <> nil then
  begin
    if Assigned(Dmm.dsSesionLin) then
      Dmm.dsSesionLin.OnDataChange := nil;
  end;
  // Desenganchar el log antes de soltar los colaboradores que lo usan.
  if Supports(ContextoSesion, IGestorContextoSesion, GestorContexto) then
    GestorContexto.AsignarLogSesion(nil);
  FAplicacionMaterializacion := nil;
  FDependencias.Liberar;
  // Orden inverso al de creacion: primero los que consultan el gestor de
  // tallas y el servicio, despues sus proveedores. Los colaboradores
  // cierran sus propios cursores antes de que TfrmMtoGen.FormDestroy
  // libere el data module y deje la conexion inactiva.
  FreeAndNil(FNavegacion);
  FreeAndNil(FFotos);
  FreeAndNil(FVisorPedidoOriginal);
  FreeAndNil(FImportadorOcr);
  FreeAndNil(FPestanasSesion);
  FreeAndNil(FCopiaLineas);
  FreeAndNil(FModeloPrv);
  FreeAndNil(FProveedor);
  FreeAndNil(FTallas);
  FreeAndNil(FServicioComprasSesiones);
  inherited;
end;

// ===========================================================================
//   Proveedor y kits — delegacion en TCoordinadorProveedorSesion
// ===========================================================================

procedure TfrmMtoComprasSesiones.cbbProveedorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if (AButtonIndex >= 0) and
     (AButtonIndex < cbbProveedor.Properties.Buttons.Count) and
     (cbbProveedor.Properties.Buttons[
        AButtonIndex].Kind = bkEllipsis) then
    BuscarProveedor;
end;

procedure TfrmMtoComprasSesiones.BuscarProveedor;
begin
  FProveedor.BuscarProveedor;
end;

function TfrmMtoComprasSesiones.IsShortCut(
  var Message: TWMKey): Boolean;
begin
  Result := (Message.CharCode = VK_RETURN) and
    (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) and
    Assigned(cbbProveedor) and cbbProveedor.Focused;
  if Result then
    BuscarProveedor
  else
    Result := inherited IsShortCut(Message);
end;

// ===========================================================================
//   Pestaña Proveedor — ficha, defectos y kits de cantidades por talla
// ===========================================================================

procedure TfrmMtoComprasSesiones.btnAplicarKitClick(Sender: TObject);
begin
  inherited;
  // Popup con los kits del proveedor de la sesion; el elegido se aplica
  // sobre la linea con foco del grid de articulos.
  FProveedor.MostrarMenuKits;
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitCabClick(Sender: TObject);
begin
  inherited;
  // El EditValue del desplegable de la cabecera es el CODIGO_PRVKIT.
//  if VarIsNull(cbbKitProv.EditValue) or VarIsClear(cbbKitProv.EditValue) then
//    sKit := ''
//  else
//    sKit := Trim(VarToStr(cbbKitProv.EditValue));
//  if sKit = '' then
//    MessageDlg_fza(SErrorKitProveedorDesplegableNoSeleccionado,
//               mtInformation, [mbOk], 0)
//  else
//    FProveedor.AplicarKitALineaActual(sKit);
end;

procedure TfrmMtoComprasSesiones.btnAplicarKitProvClick(Sender: TObject);
begin
  inherited;
  // Aplica el kit seleccionado en el grid de la pestana Proveedor sobre
  // la linea con foco del grid de articulos.
  if (not Dmm.unqryPrvKits.Active) or Dmm.unqryPrvKits.IsEmpty then
    MessageDlg_fza(SErrorProveedorSesionSinKits,
               mtInformation, [mbOk], 0)
  else
    FProveedor.AplicarKitALineaActual(
      Dmm.unqryPrvKits.FieldByName('CODIGO_PRVKIT').AsString);
end;

procedure TfrmMtoComprasSesiones.tvPrvKitsDblClick(Sender: TObject);
begin
  btnAplicarKitProvClick(Sender);
end;

// ===========================================================================
//   Lineas — alta, baja, navegacion
// ===========================================================================

procedure TfrmMtoComprasSesiones.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  // BeforeInsert se encarga de preparar el master (Post si pendiente,// Edit si
  // Browse,Abort si IsEmpty).
  LogSes('btnAddLineaClick: navegador de líneas.Append');
  // Mismo camino que el «+» del navegador: activar antes la rejilla para
  // que el cambio de foco del botón no descarte la inserción nueva.
  if cxgrdLineas.CanFocus then
    cxgrdLineas.SetFocus;
  tvLineas.DataController.Append;
  EditarModeloLineaNuevaDiferido;
  LogSes(Format('btnAddLineaClick FIN. LINEA_SESLIN=%d',
                [tvLineas.DataController.DataSet.FieldByName(
                  'LINEA_SESLIN').AsInteger]));
end;

// El ShowEdit del AfterInsert llega antes de que el grid tenga la fila
// nueva y con el foco aun en el boton: la celda quedaba seleccionada
// pero sin editor. Se repite en la cola, con el foco ya en el grid.
procedure TfrmMtoComprasSesiones.EditarModeloLineaNuevaDiferido;
begin
  TThread.ForceQueue(nil,
    TThreadProcedure(
    procedure
    begin
      if (not (csDestroying in ComponentState)) and
         Assigned(tvLineas.DataController.DataSet) and
         (tvLineas.DataController.DataSet.State = dsInsert) and
         cxgrdLineas.CanFocus then
      begin
        cxgrdLineas.SetFocus;
        tvLineas.Controller.FocusedColumn := dbcLinRefPrv;
        tvLineas.Controller.EditingController.ShowEdit;
      end;
    end));
end;

procedure TfrmMtoComprasSesiones.btnDelLineaClick(Sender: TObject);
begin
  inherited;
  if Dmm.unqrySesionLin.IsEmpty then
    LogSes('btnDelLineaClick: detail vacio, salida')
  else if MessageDlg_fza(SPreguntaBorrarLineaSesionCompra,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    LogSes('btnDelLineaClick: cancelado por el usuario')
  else
  begin
    LogSes(Format('btnDelLineaClick: linea=%d',
      [Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
    // BeforeDelete limpia SESCEL, AfterDelete recalcula columnas y totales
    Dmm.unqrySesionLin.Delete;
    LogSes('btnDelLineaClick FIN');
  end;
end;

procedure TfrmMtoComprasSesiones.btnReintentarFotosClick(
  Sender: TObject);
begin
  ReintentarFotosSesion;
end;

procedure TfrmMtoComprasSesiones.ReintentarFotosSesion;
var
  Aviso: string;
begin
  if (Dmm = nil) or Dmm.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorSesionCompraNoActiva)
  else if Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString <>
    'CERRADA' then
    ShowMessage_fza(SAvisoSesionCerradaParaFotos)
  else if Assigned(FServicioComprasSesiones) then
  begin
    Screen.Cursor := crHourGlass;
    try
      if FServicioComprasSesiones.ReintentarFotos(
        IdentidadSesion.Usuario, Aviso) then
        ShowMessage_fza(SInfoFotosSesionMigradas)
      else
        ShowMessage_fza(Aviso);
      if FFotos <> nil then
        FFotos.RefrescarLista;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.btnCrearClick(Sender: TObject);
begin
  inherited;
  if Assigned(FAplicacionMaterializacion) then
    FAplicacionMaterializacion.Ejecutar;
end;


procedure TfrmMtoComprasSesiones.btnRevertirClick(Sender: TObject);
var
  sErr: string;
  iLinea: Integer;
begin
  inherited;
  LogSes('btnRevertirClick INICIO');
  if Dmm.unqryTablaG.IsEmpty then
  begin
    LogSes('  cabecera vacia, salida');
    ShowMessage_fza(SErrorSesionCompraNoActiva);
  end
  else if Dmm.unqryTablaG.FieldByName(
    'ESTADO_SES').AsString <> 'CERRADA' then
  begin
    LogSes('  sesion no esta CERRADA, abortar');
    ShowMessage_fza(SErrorSesionNoCerradaParaReversion);
  end
  else if MessageDlg_fza(SPreguntaRevertirSesionCompra,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    LogSes('  cancelado por el usuario')
  else
  begin
    LogSes('  RevertirMaterializacion');
    Screen.Cursor := crHourGlass;
    try
      if FServicioComprasSesiones.RevertirMaterializacion(
        IdentidadSesion.Usuario, sErr) then
      begin
        LogSes('  reversion OK, recargar cabecera y lineas');
        iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
        Dmm.unqryTablaG.Refresh;
        Dmm.unqrySesionLin.DisableControls;
        try
          Dmm.unqrySesionLin.Close;
          Dmm.unqrySesionLin.Open;
          Dmm.unqrySesionLin.Locate('LINEA_SESLIN', iLinea, []);
        finally
          Dmm.unqrySesionLin.EnableControls;
        end;
        ShowMessage_fza(SInfoSesionRevertida);
      end
      else
      begin
        LogSes('  reversion KO: ' + sErr);
        ShowMessage_fza(Format(SErrorRevertirSesionCompra, [sErr]));
      end;
    finally
      Screen.Cursor := crDefault;
    end;
    LogSes('btnRevertirClick FIN');
  end;
end;

procedure TfrmMtoComprasSesiones.btnImprimirClick(Sender: TObject);
var
  form     : TfrmPrintSesion;
  sSerie   : string;
  sNumero  : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if Dmm.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorSesionActivaImprimirNoDisponible)
  else
  begin
    // Persistir cualquier edicion pendiente para que el informe la vea.
    if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
      Dmm.unqryTablaG.Post;
    if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
      Dmm.unqrySesionLin.Post;
    sSerie := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    form := TfrmPrintSesion.Create(Application);
    try
      form.dmSesion := Dmm;
      form.edtSerie.Text := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoComprasSesiones.btnNuevoColorClick(Sender: TObject);
begin
  inherited;
  FCopiaLineas.DuplicarLineaActiva;
end;

procedure TfrmMtoComprasSesiones.btnPreciosTallaClick(Sender: TObject);
begin
  inherited;
  EditarPreciosTallaLinea;
end;

// FZ-ISSUE-638: coste y PVP de cada talla de la línea activa.
procedure TfrmMtoComprasSesiones.EditarPreciosTallaLinea;
var
  oLineas: TDataSet;
  rCalculoPvp: TCalculoPvpSesion;
begin
  if (Dmm = nil) or Dmm.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorSesionCompraNoActiva)
  else if SameText(Dmm.unqryTablaG.FieldByName('ESTADO_SES').AsString,
            'CERRADA') then
    ShowMessage_fza(SErrorSesionYaMaterializada)
  else if not Dmm.unqrySesionLin.IsEmpty then
  begin
    oLineas := Dmm.unqrySesionLin;
    if oLineas.State in [dsEdit, dsInsert] then
      oLineas.Post;
    rCalculoPvp.Coeficiente :=
      Dmm.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat;
    rCalculoPvp.MultiploRedondeo :=
      Dmm.unqryTablaG.FieldByName('MULTIPLO_REDONDEO_SES').AsFloat;
    rCalculoPvp.AjusteFinal :=
      Dmm.unqryTablaG.FieldByName('AJUSTE_FINAL_SES').AsFloat;
    if TfrmModalPreciosTallaSesion.Editar(Self,
         Dmm.unqryTablaG.Connection,
         Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString,
         Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString,
         oLineas.FieldByName('LINEA_SESLIN').AsInteger,
         oLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat,
         oLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat,
         rCalculoPvp, IdentidadSesion.Usuario, oLineas.RecNo) then
    begin
      // Al grabar, el total de la línea suma el coste de cada talla.
      oLineas.Edit;
      oLineas.Post;
      Dmm.RefrescarTotalesSesion;
    end;
  end;
end;

// FZ-ISSUE-638: otro color de un artículo con coste y PVP por talla.
procedure TfrmMtoComprasSesiones.CopiarPreciosTallaCopia(ALineaOrigen,
  ALineaDestino: Integer);
var
  oLineas: TDataSet;
  sSerie: string;
  sNumero: string;
begin
  sSerie := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  if LineaTienePreciosCeldas(Dmm.unqryTablaG.Connection, sSerie, sNumero,
       ALineaOrigen) then
  begin
    CopiarPreciosCeldasLinea(Dmm.unqryTablaG.Connection, sSerie, sNumero,
      ALineaOrigen, ALineaDestino, IdentidadSesion.Usuario);
    // Al grabar, el total de la línea suma el coste de cada talla.
    oLineas := Dmm.unqrySesionLin;
    if oLineas.FieldByName('LINEA_SESLIN').AsInteger = ALineaDestino then
    begin
      if not (oLineas.State in [dsEdit, dsInsert]) then
        oLineas.Edit;
      oLineas.Post;
    end;
  end;
end;

// 1. Declaramos la clase cracker para acceder al popup interno

procedure TfrmMtoComprasSesiones.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  inherited;
  // El combo de tallaje y el Ctrl+Enter sobre columnas editbutton los
  // atiende el coordinador de tallas. F3 sobre Familia / Cod. articulo
  // abre el picker jerarquico de familias.
  if not FTallas.ProcesarTeclaEditor(AItem, AEdit, Key, Shift) then
  begin
    if (Key = VK_F3) and (Shift = []) and
       ((AItem = dbcLinFamilia) or (AItem = dbcLinCodArt)) then
    begin
      FModeloPrv.ElegirFamiliaConModal;
      Key := 0;
    end;
  end;
end;

function TfrmMtoComprasSesiones.CancelarEdicionConEscape: Boolean;
begin
  Result := Assigned(cxgrdLineas) and Assigned(tvLineas) and
    ((Screen.ActiveControl = cxgrdLineas) or
     cxgrdLineas.ContainsControl(Screen.ActiveControl)) and
    tvLineas.Controller.EditingController.IsEditing and
    not EsDesplegableAbierto(Screen.ActiveControl);
  if Result then
    tvLineas.Controller.EditingController.HideEdit(False);
end;

procedure TfrmMtoComprasSesiones.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // KeyPreview heredado = True: este KeyDown corre antes que la
  // navegacion Enter->Tab del grid y que el FormKeyDown base.
  if (Key = VK_ESCAPE) and (Shift = []) and
     Assigned(cxgrdLineas) and
     ((Screen.ActiveControl = cxgrdLineas) or
      cxgrdLineas.ContainsControl(Screen.ActiveControl)) then
  begin
    // El desplegable recibe su Esc. Fuera de él se cancela sólo la celda,
    // sin llegar al Escape global que devuelve la pantalla a la lista.
    if not EsDesplegableAbierto(Screen.ActiveControl) then
    begin
      if CancelarEdicionConEscape then
        Key := 0
      else
        inherited KeyDown(Key, Shift);
    end;
  end
  else if (Key = VK_F1) and (Shift = []) then
  begin
    //F1 -> coste y PVP por talla de la línea activa (FZ-ISSUE-638)
    Key := 0;
    EditarPreciosTallaLinea;
  end
  else if not FTallas.ProcesarTeclaFormulario(Key, Shift) then
    inherited KeyDown(Key, Shift);
end;

procedure TfrmMtoComprasSesiones.btnArbolFamiliasClick(Sender: TObject);
begin
  inherited;
  // Mismo modal jerarquico que F3 sobre la columna Familia. Operamos
  // sobre la linea con foco; si no hay ninguna, avisamos.
  if Dmm.unqrySesionLin.IsEmpty then
    MessageDlg_fza(SErrorLineaSesionAsignarFamiliaNoSeleccionada,
               mtInformation, [mbOk], 0)
  else
    FModeloPrv.ElegirFamiliaConModal;
end;

procedure TfrmMtoComprasSesiones.dbcLinFamiliaPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  FModeloPrv.ResolverFamiliaTecleada(Sender);
end;

procedure TfrmMtoComprasSesiones.dbcLinCodArtPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  inherited;
  Error := False;
  ErrorText := '';
  FModeloPrv.ConfirmarCodigoTecleado(DisplayValue);
end;

procedure TfrmMtoComprasSesiones.dbcLinRefPrvPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  inherited;
  Error := False;
  ErrorText := '';
  FModeloPrv.ConfirmarReferenciaTecleada(
    VarToStr(DisplayValue));
end;

procedure TfrmMtoComprasSesiones.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if GestorTallas <> nil then
    GestorTallas.ActualizarCaptionsLineaActiva;
  if FFotos <> nil then
    FFotos.Refrescar;
end;

// ===========================================================================
//   Color basico — selector con paleta
// ===========================================================================

procedure TfrmMtoComprasSesiones.tvLineasInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  inherited;
  // Estilo Excel: al entrar a una celda el contenido queda seleccionado.
  SeleccionarTodoEnEditor(AEdit);
  // Con raton el grid entrega el clic al editor despues de este evento y
  // el clic coloca el cursor: se repite la seleccion cuando ya se ha
  // procesado. Al destruir la ventana Windows descarta el mensaje.
  FEditorSeleccionPendiente := AEdit;
  PostMessage(Handle, WM_SELECCIONAR_CELDA_SESION, 0, 0);
  // 'Modelo prov.': si el editor es el desplegable de busqueda
  // incremental, el buscador engancha su debounce.
  if FModeloPrv <> nil then
    FModeloPrv.EngancharEditor(AItem, AEdit);
end;

procedure TfrmMtoComprasSesiones.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  // El sombreado de tallas fuera del conjunto y el nombre del sistema
  // los pinta el coordinador de tallas; el swatch, el de proveedor.
  if (FTallas <> nil) and FTallas.DibujarCelda(ACanvas, AViewInfo) then
    ADone := True
  else if (FProveedor <> nil) and
          FProveedor.DibujarCeldaColor(ACanvas, AViewInfo) then
    ADone := True;
end;

procedure TfrmMtoComprasSesiones.tvLineasEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  FTallas.AjustarPermisoEdicion(AItem, AAllow);
  if (AItem = dbcLinPestana) and
     (not FRotulosVariacion.TienePestanas) then
    AAllow := False;
end;

procedure TfrmMtoComprasSesiones.dbcLinColorBasicoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
  sLiteral: string;
begin
  inherited;
  if (not Error) and (FProveedor <> nil) then
  begin
    sLiteral := Trim(VarToStr(DisplayValue));
    if FProveedor.ResolverColorBasicoLiteral(sLiteral, sCodigo) then
      DisplayValue := sCodigo
    else
    begin
      Error := True;
      ErrorText := Format(
        SErrorColorBasicoCompraNoExiste, [sLiteral]);
    end;
  end;
end;

// ===========================================================================
//   Auto-PVP
// ===========================================================================

procedure TfrmMtoComprasSesiones.dbcLinPrecioCompraPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  FModeloPrv.ProponerPrecioVenta;
end;

procedure TfrmMtoComprasSesiones.dbcFotoUnidadGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var ATexto: string);
begin
  ATexto := TextoAsignacionFotoSesion(ATexto);
end;

initialization
  RegistrarPantalla(TfrmMtoComprasSesiones);
  ForceReferenceToClass(TfrmMtoComprasSesiones);
end.

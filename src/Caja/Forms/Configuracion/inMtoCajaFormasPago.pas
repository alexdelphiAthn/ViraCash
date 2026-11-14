{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaFormasPago                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de formas de pago de caja.                                  }
{    CRUD sobre fza_caja_formas_pago: botones disponibles en la fase de cobro }
{    (F12). Cada fila define un medio de cobro (efectivo, tarjeta, divisa,    }
{    cripto, bono) con sus flags de comportamiento (cajón, cambio,            }
{    referencia obligatoria, etc).                                             }
{******************************************************************************}
unit inMtoCajaFormasPago;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaFormasPago,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxSplitter, cxMaskEdit, cxDBEdit;

type
  TfrmMtoCajaFormasPago = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_FP_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinORDEN_VISUAL_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESREQ_REFERENCIA_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESCRIPTO_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESDIVISA_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESDEVUELVE_CAMBIO_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESABRE_CAJON_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENTAJE_COMISION_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinESCOMISION_INCL_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinNUM_COD_DIGIT_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinRED_BLOCKCHAIN_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_BLOCKCHAIN_FORMA_PAGO_CFP: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO_FP_CFP: TcxDBTextEdit;
    lblDescripcion: TcxLabel;
    txtDESCRIPCION_FORMA_PAGO_CFP: TcxDBTextEdit;
    lblOrdenVisual: TcxLabel;
    spnORDEN_VISUAL_FORMA_PAGO_CFP: TcxDBSpinEdit;
    chkESACTIVO_FORMA_PAGO_CFP: TcxDBCheckBox;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsComportamiento: TcxTabSheet;
    chkESREQ_REFERENCIA_FORMA_PAGO_CFP: TcxDBCheckBox;
    chkESCRIPTO_FORMA_PAGO_CFP: TcxDBCheckBox;
    chkESDIVISA_FORMA_PAGO_CFP: TcxDBCheckBox;
    chkESDEVUELVE_CAMBIO_FORMA_PAGO_CFP: TcxDBCheckBox;
    chkESABRE_CAJON_FORMA_PAGO_CFP: TcxDBCheckBox;
    lblPorcentajeComision: TcxLabel;
    spnPORCENTAJE_COMISION_FORMA_PAGO_CFP: TcxDBSpinEdit;
    chkESCOMISION_INCL_FORMA_PAGO_CFP: TcxDBCheckBox;
    lblNumCodDigit: TcxLabel;
    txtNUM_COD_DIGIT_FORMA_PAGO_CFP: TcxDBTextEdit;
    tsBlockchain: TcxTabSheet;
    lblRedBlockchain: TcxLabel;
    txtRED_BLOCKCHAIN_FORMA_PAGO_CFP: TcxDBTextEdit;
    lblHashBlockchain: TcxLabel;
    txtHASH_BLOCKCHAIN_FORMA_PAGO_CFP: TcxDBTextEdit;
    tsAuditoria: TcxTabSheet;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    dmmCajaFormasPago: TdmCajaFormasPago;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoCajaFormasPago.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaFormasPago := tdmDataModule as TdmCajaFormasPago;
  pkFieldName := 'CODIGO_FP_CFP';
end;

procedure TfrmMtoCajaFormasPago.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoCajaFormasPago.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // El código es PK y no debe modificarse una vez creada la fila.
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_FP_CFP.Enabled := True
  else
    txtCODIGO_FP_CFP.Enabled := False;
end;

initialization
  RegistrarPantalla(TfrmMtoCajaFormasPago);
  ForceReferenceToClass(TfrmMtoCajaFormasPago);
end.

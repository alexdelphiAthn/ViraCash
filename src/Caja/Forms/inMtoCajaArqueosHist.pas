{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaArqueosHist                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico de arqueos de caja.                                             }
{    Consulta de los arqueos grabados (cierres Z) con detalle de recuento,     }
{    posibilidad de imprimir informe (y exportarlo a Excel desde el modal).   }
{******************************************************************************}
unit inMtoCajaArqueosHist;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaArqueosHist,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxCurrencyEdit, cxGridExportLink,
  inLibPermisosIntf, inLibCajaPantallaInyeccion;

type
  TfrmMtoCajaArqueosHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMP_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALM_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_DESDE_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_HASTA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFASE_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_VENTAS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_NETO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_VENTAS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_EFECTIVO_CAJA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_OTROS_INGRESOS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_SALDO_RECONTAR_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_RECUENTO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinDIFERENCIA_TOTAL_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    cxgrdRecuento: TcxGrid;
    tvRecuento: TcxGridDBTableView;
    tvRecuentoCodigo: TcxGridDBColumn;
    tvRecuentoDescripcion: TcxGridDBColumn;
    tvRecuentoEsCajon: TcxGridDBColumn;
    tvRecuentoSistema: TcxGridDBColumn;
    tvRecuentoImporte: TcxGridDBColumn;
    tvRecuentoDiferencia: TcxGridDBColumn;
    lvRecuento: TcxGridLevel;
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure FaseGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
  private
    dmmCajaArqueosHist: TdmCajaArqueosHist;
    FDependenciasInforme: TDependenciasInformeCaja;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasInformeCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén/caja del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inMtoModalImpArqueos, inLibFiltroUsuario, inLibMsgCaja;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaArqueosHist }

constructor TfrmMtoCajaArqueosHist.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasInformeCaja);
begin
  ADependencias.Validar;
  FDependenciasInforme := ADependencias;
  inherited Create(AOwner, AContexto);
end;

function TfrmMtoCajaArqueosHist.SqlRestriccionUsuario: string;
begin
  // La empresa es obligatoria; el parametro solo amplia la restriccion
  // a almacen y caja, tambien cuando el usuario es administrador.
  Result := ' AND CODIGO_EMP_ARQ = ' +
    QuotedStr(UbicacionSesion.Empresa) + SqlFiltroEmpAlmCaja(
      ContextoSesion, ParametrosApp, '',
      'CODIGO_ALM_ARQ', 'CODIGO_CAJA_ARQ');
end;

procedure TfrmMtoCajaArqueosHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaArqueosHist := tdmDataModule as TdmCajaArqueosHist;
  pkFieldName := 'CODIGO_ARQ';
  cxGrdDBTabPrinFASE_ARQ.OnGetDisplayText := FaseGetDisplayText;
end;

procedure TfrmMtoCajaArqueosHist.FaseGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if SameText(Trim(AText), 'CERRADO') then
    AText := SEstadoArqueoCerrado;
end;

procedure TfrmMtoCajaArqueosHist.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoCajaArqueosHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintArqueos;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport). El usuario puede retocar el formato
  // con el botón Editar del propio modal y guardarlo como formato propio.
  frm := TfrmPrintArqueos.Create(
    Application,
    FDependenciasInforme);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoCajaArqueosHist);
  ForceReferenceToClass(TfrmMtoCajaArqueosHist);
end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEfectosCompra                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cartera de efectos de pago a proveedor (consulta).                       }
{******************************************************************************}
unit inMtoEfectosCompra;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEfectosCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, cxCurrencyEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, inLibFusionEfectosIntf;

type
  TfrmMtoEfectosCompra = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_FACC_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_FACC_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_PRV_VIEW_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_PAGO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_REMC_EFEC: TcxGridDBColumn;
    btnRegistrarPago: TcxButton;
    btnFusionarEfectos: TcxButton;
    procedure btnRegistrarPagoClick(Sender: TObject);
    procedure btnFusionarEfectosClick(Sender: TObject);
  private
    FCasoUsoFusionEfectos: ICasoUsoFusionEfectos;
  public
    dmmEfectosCompra: TdmEfectosCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inMtoModalRegistrarPago, inLibFiltroUsuario,
  inLibMsgCompras, inLibMsgComun, inLibFusionEfectos,
  UniDataFusionEfectos, inMtoFusionEfectosVcl;

function CrearContextoFusionEfectosCompraVcl(
  AFormulario: TfrmMtoEfectosCompra): TContextoFusionEfectosVcl;
begin
  Result := Default(TContextoFusionEfectosVcl);
  Result.Vista := AFormulario.cxGrdDBTabPrin;
  Result.CasoUso := AFormulario.FCasoUsoFusionEfectos;
  Result.IndiceSerie :=
    AFormulario.dbcGrdDBTabPrinSERIE_FACC_EFEC.Index;
  Result.IndiceNumero :=
    AFormulario.dbcGrdDBTabPrinNUMERO_FACC_EFEC.Index;
  Result.IndiceEfecto :=
    AFormulario.dbcGrdDBTabPrinNUMERO_EFEC.Index;
  Result.MensajeSeleccionInsuficiente :=
    SErrorEfectosCompraFusionInsuficientes;
end;

{$R *.dfm}

resourcestring
  STituloRegistrarPagoEfectoCompra = 'Efecto %d - pendiente %.2f';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoEfectosCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmEfectosCompra := tdmDataModule as TdmEfectosCompra;
  FCasoUsoFusionEfectos := CrearCasoUsoFusionEfectos(
    CrearRepositorioFusionEfectosCompraUniDAC(dmmEfectosCompra));
  pkFieldName := 'SERIE_FACC_EFEC;NUMERO_FACC_EFEC;NUMERO_EFEC';
end;

procedure TfrmMtoEfectosCompra.ResetForm;
begin
  inherited;
end;

function TfrmMtoEfectosCompra.SqlRestriccionUsuario: string;
begin
  // Los efectos de compra llevan la empresa de la factura origen en
  // cabecera; sin almacén ni caja.
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_EFEC',
    '',
    '');
end;

procedure TfrmMtoEfectosCompra.btnRegistrarPagoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmEfectosCompra) and dmmEfectosCompra.unqryTablaG.Active and
     (not dmmEfectosCompra.unqryTablaG.IsEmpty) then
  begin
    q     := dmmEfectosCompra.unqryTablaG;
    iEfe  := q.FieldByName('NUMERO_EFEC').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(
        Format(STituloRegistrarPagoEfectoCompra, [iEfe, fPend]),
        fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmEfectosCompra.RegistrarPago(
          q.FieldByName('SERIE_FACC_EFEC').AsString,
          q.FieldByName('NUMERO_FACC_EFEC').AsString,
          iEfe, frm.Fecha, frm.Importe, frm.Tipo, frm.Referencia);
        if iRes > 0 then
          ShowMessage_fza(SInfoEfectoConciliado)
        else
          ShowMessage_fza(SErrorConciliarEfecto);
      end;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage_fza(SErrorEfectoNoSeleccionado);
end;

procedure TfrmMtoEfectosCompra.btnFusionarEfectosClick(Sender: TObject);
begin
  inherited;
  if not Assigned(dmmEfectosCompra) then
    ShowMessage_fza(SErrorCarteraEfectosNoAbierta)
  else
    TCoordinadorFusionEfectosVcl.Ejecutar(
      CrearContextoFusionEfectosCompraVcl(Self));
end;

initialization
  RegistrarPantalla(TfrmMtoEfectosCompra);
  ForceReferenceToClass(TfrmMtoEfectosCompra);
end.

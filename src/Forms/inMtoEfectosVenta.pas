{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEfectosVenta                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cartera de efectos de cobro a cliente (consulta).                       }
{******************************************************************************}
unit inMtoEfectosVenta;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEfectosVenta,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, cxCurrencyEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, inLibFusionEfectosIntf;

type
  TfrmMtoEfectosVenta = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_FAC_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_FAC_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_CLI_VIEW_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_COBRO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_REMV_EFV: TcxGridDBColumn;
    btnRegistrarCobro: TcxButton;
    btnFusionarEfectos: TcxButton;
    procedure btnRegistrarCobroClick(Sender: TObject);
    procedure btnFusionarEfectosClick(Sender: TObject);
  private
    FCasoUsoFusionEfectos: ICasoUsoFusionEfectos;
  public
    dmmEfectosVenta: TdmEfectosVenta;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inMtoModalRegistrarPago, inLibFiltroUsuario,
  inLibMsgComun, inLibMsgVentas, inLibFusionEfectos,
  UniDataFusionEfectos, inMtoFusionEfectosVcl;

function CrearContextoFusionEfectosVentaVcl(
  AFormulario: TfrmMtoEfectosVenta): TContextoFusionEfectosVcl;
begin
  Result := Default(TContextoFusionEfectosVcl);
  Result.Vista := AFormulario.cxGrdDBTabPrin;
  Result.CasoUso := AFormulario.FCasoUsoFusionEfectos;
  Result.IndiceSerie :=
    AFormulario.dbcGrdDBTabPrinSERIE_FAC_EFV.Index;
  Result.IndiceNumero :=
    AFormulario.dbcGrdDBTabPrinNUMERO_FAC_EFV.Index;
  Result.IndiceEfecto :=
    AFormulario.dbcGrdDBTabPrinNUMERO_EFV.Index;
  Result.MensajeSeleccionInsuficiente :=
    SErrorEfectosVentaFusionInsuficientes;
end;

{$R *.dfm}

resourcestring
  STituloRegistrarCobroEfectoVenta = 'Efecto %d - pendiente %.2f';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoEfectosVenta.CrearTablaPrincipal;
begin
  inherited;
  dmmEfectosVenta := tdmDataModule as TdmEfectosVenta;
  FCasoUsoFusionEfectos := CrearCasoUsoFusionEfectos(
    CrearRepositorioFusionEfectosVentaUniDAC(dmmEfectosVenta));
  pkFieldName := 'SERIE_FAC_EFV;NUMERO_FAC_EFV;NUMERO_EFV';
end;

procedure TfrmMtoEfectosVenta.ResetForm;
begin
  inherited;
end;

function TfrmMtoEfectosVenta.SqlRestriccionUsuario: string;
begin
  // Los efectos de venta llevan la empresa de la factura origen en
  // cabecera; sin almacén ni caja.
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_EFV',
    '',
    '');
end;

procedure TfrmMtoEfectosVenta.btnRegistrarCobroClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmEfectosVenta) and dmmEfectosVenta.unqryTablaG.Active and
     (not dmmEfectosVenta.unqryTablaG.IsEmpty) then
  begin
    q     := dmmEfectosVenta.unqryTablaG;
    iEfe  := q.FieldByName('NUMERO_EFV').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFV').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(
        Format(STituloRegistrarCobroEfectoVenta, [iEfe, fPend]),
        fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmEfectosVenta.RegistrarCobro(
          q.FieldByName('SERIE_FAC_EFV').AsString,
          q.FieldByName('NUMERO_FAC_EFV').AsString,
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

procedure TfrmMtoEfectosVenta.btnFusionarEfectosClick(Sender: TObject);
begin
  inherited;
  if not Assigned(dmmEfectosVenta) then
    ShowMessage_fza(SErrorCarteraEfectosNoAbierta)
  else
    TCoordinadorFusionEfectosVcl.Ejecutar(
      CrearContextoFusionEfectosVentaVcl(Self));
end;

initialization
  RegistrarPantalla(TfrmMtoEfectosVenta);
  ForceReferenceToClass(TfrmMtoEfectosVenta);
end.



{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDepositosCliente                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de depositos de cliente.                                    }
{    Gestion de saldos depositados a cuenta por cada cliente.                  }
{******************************************************************************}
unit inMtoDepositosCliente;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataDepositosCliente,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxSplitter, inLibFotos,
  inLibPermisosIntf, inLibCajaPantallaInyeccion,
  inLibReimpresionOperacionCaja, System.Actions, Vcl.ActnList;

type
  TfrmMtoDepositosCliente = class(TfrmMtoGen)
    cxGrdDBTabPrinID_DEPOSITO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARTICULO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_UNIDAD_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_VENTA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_ANTICIPO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CREACION_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_IVA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinPORCEN_IVA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinESIMP_INCL_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_PENDIENTE_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_ENTREGA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    splFotoDep: TcxSplitter;
    pnlFotoDep: TPanel;
    imgFotoDep: TImage;
    btnImprimirInforme: TcxButton;
    btnDeudores: TcxButton;
    btnExtracto: TcxButton;
    btnReimprimirResguardo: TcxButton;
    alDepositos: TActionList;
    actReimprimirResguardo: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure btnDeudoresClick(Sender: TObject);
    procedure btnExtractoClick(Sender: TObject);
    procedure actReimprimirResguardoExecute(Sender: TObject);
    procedure actReimprimirResguardoUpdate(Sender: TObject);
  private
    dmmDepositosCliente: TdmDepositosCliente;
    FFotoEmb: TFotoEmbebida;
    FDependenciasInforme: TDependenciasInformeCaja;
    FDependenciasReimpresion: TDependenciasReimpresionCaja;
    function PuedeReimprimirResguardo: Boolean;
    procedure AbrirCuenta(const ACliente: string; AResumen: Boolean);
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasInformeCaja;
      const AReimpresion: TDependenciasReimpresionCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inMtoModalImpDepositos, inLibMensajesVcl, inLibMsgFacturas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoDepositosCliente }

constructor TfrmMtoDepositosCliente.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasInformeCaja;
  const AReimpresion: TDependenciasReimpresionCaja);
begin
  ADependencias.Validar;
  ValidarDependenciasReimpresionCaja(AReimpresion);
  FDependenciasInforme := ADependencias;
  FDependenciasReimpresion := AReimpresion;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoDepositosCliente.FormCreate(Sender: TObject);
begin
  inherited;
  // Foto embebida del articulo / SKU de la fila activa de dsTablaG.
  FFotoEmb := TFotoEmbebida.Create(
    FotosArticulos, imgFotoDep, dsTablaG);
end;

procedure TfrmMtoDepositosCliente.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FFotoEmb);
  inherited;
end;

procedure TfrmMtoDepositosCliente.CrearTablaPrincipal;
begin
  inherited;
  dmmDepositosCliente := tdmDataModule as TdmDepositosCliente;
  pkFieldName := 'ID_DEPOSITO_DEP';
  actReimprimirResguardo.Visible := PuedeImprimir;
  btnDeudores.Visible := PuedeImprimir;
  btnExtracto.Visible := PuedeImprimir;
end;

procedure TfrmMtoDepositosCliente.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDepositosCliente.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintDepositos;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport) de los depositos de clientes. El
  // usuario filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintDepositos.Create(
    Application,
    FDependenciasInforme);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoDepositosCliente.AbrirCuenta(
  const ACliente: string; AResumen: Boolean);
var
  Formulario: TfrmPrintDepositos;
begin
  if not PuedeImprimir then
    Abort;
  Formulario := TfrmPrintDepositos.Create(Self, FDependenciasInforme);
  try
    Formulario.ConfigurarCuenta(ACliente, AResumen);
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure TfrmMtoDepositosCliente.btnDeudoresClick(Sender: TObject);
begin
  AbrirCuenta('', True);
end;

procedure TfrmMtoDepositosCliente.btnExtractoClick(Sender: TObject);
var
  Codigo: string;
begin
  Codigo := '';
  if dsTablaG.DataSet.Active and not dsTablaG.DataSet.IsEmpty then
    Codigo := dsTablaG.DataSet.FieldByName('CODIGO_CLI_DEP').AsString;
  if InputQuery('Extracto de cuenta', 'Código de cliente:', Codigo) then
    if Trim(Codigo) <> '' then
      AbrirCuenta(Codigo, False);
end;

// Resguardo de la operacion de caja que creo el deposito, en vista
// previa (impresora 'DEBUG'): desde el visor se puede mandar a imprimir.
function TfrmMtoDepositosCliente.PuedeReimprimirResguardo: Boolean;
var
  oDeposito: TDataSet;
begin
  oDeposito := dsTablaG.DataSet;
  Result := PuedeImprimir and Assigned(oDeposito) and oDeposito.Active and
    (not oDeposito.IsEmpty) and
    (Trim(oDeposito.FieldByName('NUMERO_OPERACION_DEP').AsString) <> '');
end;

procedure TfrmMtoDepositosCliente.actReimprimirResguardoUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled := PuedeReimprimirResguardo;
end;

procedure TfrmMtoDepositosCliente.actReimprimirResguardoExecute(
  Sender: TObject);
var
  oDeposito: TDataSet;
  Entorno: TEntornoReimpresionCaja;
  Operacion: TOperacionReimpresionCaja;
begin
  if PuedeReimprimirResguardo then
  begin
    oDeposito := dsTablaG.DataSet;
    Operacion := Default(TOperacionReimpresionCaja);
    Operacion.Empresa := oDeposito.FieldByName('CODIGO_EMP_DEP').AsString;
    Operacion.Almacen := oDeposito.FieldByName('CODIGO_ALM_DEP').AsString;
    Operacion.Caja := oDeposito.FieldByName('CODIGO_CAJA_DEP').AsString;
    Operacion.NumeroOperacion :=
      oDeposito.FieldByName('NUMERO_OPERACION_DEP').AsString;
    Operacion.TieneDepositos := True;
    Entorno := Default(TEntornoReimpresionCaja);
    Entorno.ParametrosApp := ParametrosApp;
    Entorno.ParametrosCaja := ParametrosCaja;
    Entorno.Preview := PreviewTicket;
    Entorno.Unidades := UnidadesMedida;
    Entorno.EmpresaSesion := UbicacionSesion.Empresa;
    Screen.Cursor := crHourGlass;
    try
      if not ReimprimirOperacionCaja(
        Entorno,
        FDependenciasReimpresion,
        Operacion,
        'DEBUG') then
        ShowMessage_fza(SErrorOperacionSinTicket);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoDepositosCliente);
  ForceReferenceToClass(TfrmMtoDepositosCliente);
end.

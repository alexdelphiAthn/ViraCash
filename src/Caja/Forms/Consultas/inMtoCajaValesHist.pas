{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaValesHist                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de vales emitidos y redimidos.                                  }
{    Consulta de vales generados desde caja.                                   }
{******************************************************************************}
unit inMtoCajaValesHist;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Actions, Vcl.Graphics, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaValesHist,
  cxCheckBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab,
  dxShellDialogs, inLibPermisosIntf, inLibReimpresionOperacionCaja;

type
  TfrmMtoCajaValesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PADRE_VL: TcxGridDBColumn;
    cxGrdDBTabPrinPIN_SEGURIDAD_VL: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_NOMINAL_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_EMISION_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CADUCIDAD_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_REDENCION_VL: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_REDIMIDO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_VL: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_VL: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    btnIrOperacionOrigen: TcxButton;
    alValesHist: TActionList;
    actIrOperacionOrigen: TAction;
    btnIrOperacionRedencion: TcxButton;
    actIrOperacionRedencion: TAction;
    btnReimprimirVale: TcxButton;
    actReimprimirVale: TAction;
    procedure actIrOperacionOrigenExecute(Sender: TObject);
    procedure actIrOperacionOrigenUpdate(Sender: TObject);
    procedure actIrOperacionRedencionExecute(Sender: TObject);
    procedure actIrOperacionRedencionUpdate(Sender: TObject);
    procedure actReimprimirValeExecute(Sender: TObject);
    procedure actReimprimirValeUpdate(Sender: TObject);
  private
    dmmCajaValesHist: TdmCajaValesHist;
    FDependenciasReimpresion: TDependenciasReimpresionCaja;
    function ClaveOperacionVale(const ATerminal: string): string;
    procedure IrOperacionVale(const ATerminal: string);
    function PuedeReimprimirVale: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasReimpresionCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén/caja del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inLibFiltroUsuario, inLibShowMto, inLibMensajesVcl,
  inLibCajaPantallaInyeccion, inLibMsgFacturas,
  inMtoCajaFormatosTicket;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaValesHist }

constructor TfrmMtoCajaValesHist.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasReimpresionCaja);
begin
  ValidarDependenciasReimpresionCaja(ADependencias);
  FDependenciasReimpresion := ADependencias;
  inherited Create(AOwner, AContexto);
end;

function TfrmMtoCajaValesHist.SqlRestriccionUsuario: string;
var
  sEmision: string;
  sRedencion: string;
begin
  // Siempre limitar por empresa emisora o redentora. Las restricciones
  // opcionales de terminal se aplican dentro de su rama correspondiente.
  sEmision := ' AND CODIGO_EMP_EMI_VL = ' +
    QuotedStr(UbicacionSesion.Empresa) + SqlFiltroEmpAlmCaja(
      ContextoSesion, ParametrosApp, '',
      'CODIGO_ALM_EMI_VL', 'CODIGO_CAJA_EMI_VL');
  sRedencion := ' AND CODIGO_EMP_RED_VL = ' +
    QuotedStr(UbicacionSesion.Empresa) + SqlFiltroEmpAlmCaja(
      ContextoSesion, ParametrosApp, '',
      'CODIGO_ALM_RED_VL', 'CODIGO_CAJA_RED_VL');
  Result := ' AND ((1 = 1' + sEmision + ')' +
    ' OR (CODIGO_EMP_RED_VL IS NOT NULL' + sRedencion + '))';
end;

procedure TfrmMtoCajaValesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaValesHist := tdmDataModule as TdmCajaValesHist;
  dmmCajaValesHist.AplicarRestriccionUsuario(SqlRestriccionUsuario);
  pkFieldName := 'CODIGO_VL';
  actReimprimirVale.Visible := PuedeImprimir;
end;

procedure TfrmMtoCajaValesHist.ResetForm;
begin
  inherited;
end;

// Operacion de caja que emitio (ATerminal = 'EMI') o redimio ('RED') el
// vale, con la clave que espera el historico de operaciones: empresa,
// almacen, caja y numero separados por comas. Vacia si no hay vale activo
// o no consta la operacion.
function TfrmMtoCajaValesHist.ClaveOperacionVale(
  const ATerminal: string): string;
var
  oVale: TDataSet;
  sOperacion: string;
begin
  Result := '';
  oVale := dsTablaG.DataSet;
  if (oVale <> nil) and oVale.Active and (not oVale.IsEmpty) then
  begin
    sOperacion :=
      Trim(oVale.FieldByName(
        'NUMERO_OPERACION_' + ATerminal + '_VL').AsString);
    if sOperacion <> '' then
      Result :=
        Trim(oVale.FieldByName(
          'CODIGO_EMP_' + ATerminal + '_VL').AsString) + ',' +
        Trim(oVale.FieldByName(
          'CODIGO_ALM_' + ATerminal + '_VL').AsString) + ',' +
        Trim(oVale.FieldByName(
          'CODIGO_CAJA_' + ATerminal + '_VL').AsString) + ',' +
        sOperacion;
  end;
end;

procedure TfrmMtoCajaValesHist.IrOperacionVale(const ATerminal: string);
var
  sClave: string;
begin
  sClave := ClaveOperacionVale(ATerminal);
  if sClave <> '' then
    ShowMto(Self.Owner, 'CajaOperacionesHist', sClave);
end;

procedure TfrmMtoCajaValesHist.actIrOperacionOrigenExecute(
  Sender: TObject);
begin
  IrOperacionVale('EMI');
end;

procedure TfrmMtoCajaValesHist.actIrOperacionOrigenUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled := ClaveOperacionVale('EMI') <> '';
end;

procedure TfrmMtoCajaValesHist.actIrOperacionRedencionExecute(
  Sender: TObject);
begin
  IrOperacionVale('RED');
end;

procedure TfrmMtoCajaValesHist.actIrOperacionRedencionUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled := ClaveOperacionVale('RED') <> '';
end;

// El vale no tiene ticket propio: sale en el de la venta que lo emitio
// (codigo e importe a favor), asi que se reimprime ese ticket.
function TfrmMtoCajaValesHist.PuedeReimprimirVale: Boolean;
begin
  Result := PuedeImprimir and (ClaveOperacionVale('EMI') <> '');
end;

procedure TfrmMtoCajaValesHist.actReimprimirValeUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := PuedeReimprimirVale;
end;

procedure TfrmMtoCajaValesHist.actReimprimirValeExecute(Sender: TObject);
var
  oVale: TDataSet;
  Entorno: TEntornoReimpresionCaja;
  Operacion: TOperacionReimpresionCaja;
begin
  if PuedeReimprimirVale then
  begin
    oVale := dsTablaG.DataSet;
    Operacion := Default(TOperacionReimpresionCaja);
    Operacion.Empresa := oVale.FieldByName('CODIGO_EMP_EMI_VL').AsString;
    Operacion.Almacen := oVale.FieldByName('CODIGO_ALM_EMI_VL').AsString;
    Operacion.Caja := oVale.FieldByName('CODIGO_CAJA_EMI_VL').AsString;
    Operacion.NumeroOperacion :=
      oVale.FieldByName('NUMERO_OPERACION_EMI_VL').AsString;
    Operacion.TieneFactura :=
      Trim(oVale.FieldByName('NUMERO_FAC_EMI_VL').AsString) <> '';
    Entorno := Default(TEntornoReimpresionCaja);
    Entorno.ParametrosApp := ParametrosApp;
    Entorno.ParametrosCaja := ParametrosCaja;
    Entorno.Preview := PreviewTicket;
    Entorno.Unidades := UnidadesMedida;
    Entorno.EmpresaSesion := UbicacionSesion.Empresa;
    Entorno.TicketFormato := CrearTicketFormatoCaja(
      ConexionPrincipal, ParametrosCaja, PreviewTicket);
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
  RegistrarPantalla(TfrmMtoCajaValesHist);
  ForceReferenceToClass(TfrmMtoCajaValesHist);
end.

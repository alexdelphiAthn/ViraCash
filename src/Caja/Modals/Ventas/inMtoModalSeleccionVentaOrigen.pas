{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeleccionVentaOrigen                                }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Devolución sin código de barras: propone las ventas (12 meses,            }
{    cualquier tienda de la empresa) que contienen el SKU devuelto para        }
{    elegir el ticket de origen. Cancelable: la devolución queda sin           }
{    origen (modo DV).                                                         }
{******************************************************************************}
unit inMtoModalSeleccionVentaOrigen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  MemDS, VirtualTable,
  inMtoFrmBase, inLibCajaVentaIntf, dxCoreGraphics, Vcl.Menus,
  cxStyles, dxDateRanges, dxScrollbarAnnotations, cxLocalization,
  JvComponentBase, JvEnterTab;

type
  TVentaOrigenSeleccionada = record
    Encontrada: Boolean;
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
  end;
  TfrmModalSeleccionVentaOrigen = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    cxgrdVentas: TcxGrid;
    dbtvVentas: TcxGridDBTableView;
    cxgrdlvlVentas: TcxGridLevel;
    colFecha: TcxGridDBColumn;
    colSerie: TcxGridDBColumn;
    colNumero: TcxGridDBColumn;
    colAlmacen: TcxGridDBColumn;
    colCaja: TcxGridDBColumn;
    colUds: TcxGridDBColumn;
    colTotalLinea: TcxGridDBColumn;
    colTotalTicket: TcxGridDBColumn;
    dsVentas: TDataSource;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dbtvVentasDblClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    FRepositorio: IRepositorioConsultasCaja;
    FMemVentas: TVirtualTable;
    FSku: string;
    FEmpresa: string;
    FSeleccion: TVentaOrigenSeleccionada;
    procedure CargarVentas;
    function SeleccionarVentaActual: Boolean;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioConsultasCaja;
      const ASku, AEmpresa: string;
      out ASeleccion: TVentaOrigenSeleccionada): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalSeleccionVentaOrigen.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const ASku, AEmpresa: string;
  out ASeleccion: TVentaOrigenSeleccionada): Boolean;
var
  frm: TfrmModalSeleccionVentaOrigen;
begin
  Result := False;
  ASeleccion := Default(TVentaOrigenSeleccionada);
  frm := TfrmModalSeleccionVentaOrigen.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.FSku := ASku;
    frm.FEmpresa := AEmpresa;
    frm.lblTitulo.Caption := Format(
      SInfoVentasOrigenSkuCaja, [ASku]);
    if frm.ShowModal = mrOk then
    begin
      ASeleccion := frm.FSeleccion;
      Result := ASeleccion.Encontrada;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeleccionVentaOrigen.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
  FSeleccion := Default(TVentaOrigenSeleccionada);
  FMemVentas := TVirtualTable.Create(Self);
  FMemVentas.FieldDefs.Add('FECHA', ftDateTime);
  FMemVentas.FieldDefs.Add('SERIE_FAC', ftString, 20);
  FMemVentas.FieldDefs.Add('NUMERO_FAC', ftString, 20);
  FMemVentas.FieldDefs.Add('CODIGO_EMP_FAC', ftString, 10);
  FMemVentas.FieldDefs.Add('CODIGO_ALM_FAC', ftString, 10);
  FMemVentas.FieldDefs.Add('CODIGO_CAJA_FAC', ftString, 10);
  FMemVentas.FieldDefs.Add('NUMERO_OPERACION_FAC', ftString, 20);
  FMemVentas.FieldDefs.Add('CANTIDAD', ftFloat);
  FMemVentas.FieldDefs.Add('TOTAL_LINEA', ftCurrency);
  FMemVentas.FieldDefs.Add('TOTAL_TICKET', ftCurrency);
  FMemVentas.Open;
  dsVentas.DataSet := FMemVentas;
end;

procedure TfrmModalSeleccionVentaOrigen.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FMemVentas);
  inherited;
end;

procedure TfrmModalSeleccionVentaOrigen.FormShow(Sender: TObject);
begin
  CargarVentas;
  if cxgrdVentas.CanFocus then
    cxgrdVentas.SetFocus;
end;

procedure TfrmModalSeleccionVentaOrigen.CargarVentas;
var
  oConsulta: IResultadoConsultaCaja;
  oDatos: TDataSet;
begin
  oConsulta := FRepositorio.ConsultarVentasOrigenSku(
    FSku, FEmpresa);
  oDatos := oConsulta.DataSet;
  FMemVentas.DisableControls;
  try
    FMemVentas.Clear;
    while not oDatos.Eof do
    begin
      FMemVentas.Append;
      FMemVentas.FieldByName('FECHA').AsDateTime :=
        oDatos.FieldByName('INSTANTE_ALTA').AsDateTime;
      FMemVentas.FieldByName('SERIE_FAC').AsString :=
        oDatos.FieldByName('SERIE_FAC').AsString;
      FMemVentas.FieldByName('NUMERO_FAC').AsString :=
        oDatos.FieldByName('NUMERO_FAC').AsString;
      FMemVentas.FieldByName('CODIGO_EMP_FAC').AsString :=
        oDatos.FieldByName('CODIGO_EMP_FAC').AsString;
      FMemVentas.FieldByName('CODIGO_ALM_FAC').AsString :=
        oDatos.FieldByName('CODIGO_ALM_FAC').AsString;
      FMemVentas.FieldByName('CODIGO_CAJA_FAC').AsString :=
        oDatos.FieldByName('CODIGO_CAJA_FAC').AsString;
      FMemVentas.FieldByName('NUMERO_OPERACION_FAC').AsString :=
        oDatos.FieldByName('NUMERO_OPERACION_FAC').AsString;
      FMemVentas.FieldByName('CANTIDAD').AsFloat :=
        oDatos.FieldByName('CANTIDAD_FACLIN').AsFloat;
      FMemVentas.FieldByName('TOTAL_LINEA').AsCurrency :=
        oDatos.FieldByName('TOTAL_FACLIN').AsCurrency;
      FMemVentas.FieldByName('TOTAL_TICKET').AsCurrency :=
        oDatos.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
      FMemVentas.Post;
      oDatos.Next;
    end;
  finally
    FMemVentas.EnableControls;
  end;
  FMemVentas.First;
end;

function TfrmModalSeleccionVentaOrigen.SeleccionarVentaActual:
  Boolean;
begin
  Result := False;
  if not FMemVentas.IsEmpty then
  begin
    FSeleccion.Encontrada := True;
    FSeleccion.Serie :=
      FMemVentas.FieldByName('SERIE_FAC').AsString;
    FSeleccion.Numero :=
      FMemVentas.FieldByName('NUMERO_FAC').AsString;
    FSeleccion.Empresa :=
      FMemVentas.FieldByName('CODIGO_EMP_FAC').AsString;
    FSeleccion.Almacen :=
      FMemVentas.FieldByName('CODIGO_ALM_FAC').AsString;
    FSeleccion.Caja :=
      FMemVentas.FieldByName('CODIGO_CAJA_FAC').AsString;
    FSeleccion.NumeroOperacion :=
      FMemVentas.FieldByName('NUMERO_OPERACION_FAC').AsString;
    Result := True;
  end;
end;

procedure TfrmModalSeleccionVentaOrigen.dbtvVentasDblClick(
  Sender: TObject);
begin
  if SeleccionarVentaActual then
    ModalResult := mrOk;
end;

procedure TfrmModalSeleccionVentaOrigen.actAceptarExecute(
  Sender: TObject);
begin
  if SeleccionarVentaActual then
    ModalResult := mrOk
  else
    MessageBox_fza(
      PChar(SErrorVentaOrigenCajaSinSeleccion),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalSeleccionVentaOrigen.actCancelarExecute(
  Sender: TObject);
begin
  // Cancelar es válido: la devolución queda sin origen (modo DV)
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalSeleccionVentaOrigen);
end.

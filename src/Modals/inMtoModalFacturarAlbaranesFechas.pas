{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacturarAlbaranesFechas                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para facturar albaranes filtrando por serie y rango de fechas.      }
{    Permite agrupar por cliente al generar las facturas.                      }
{******************************************************************************}
unit inMtoModalFacturarAlbaranesFechas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCheckBox,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, dxSkinsCore, dxSkinBlue, cxContainer, cxMaskEdit,
  cxDropDownEdit, cxNavigator, cxPropertiesStore, dxSkinsForm,
  cxCalendar, cxDBData,
  inMtoFrmBase, UniDataAlbaranes, dxCore, cxDateUtils, Vcl.Menus,
  inLibFacturacionAlbaranesFechasPersistenciaIntf,
  inLibOpcionesDocumentoIntf;

type
  TfrmModalFacturarAlbaranesFechas = class(TfrmBase)
    pnlTop: TPanel;
    lblSerie: TcxLabel;
    edtSerie: TcxTextEdit;
    lblFechaDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblFechaHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    chkAgruparPorCliente: TcxCheckBox;
    btnBuscar: TcxButton;
    pnlMid: TPanel;
    cxgrdAlbaranes: TcxGrid;
    tvAlbaranes: TcxGridTableView;
    cxgrdlvlAlbaranes: TcxGridLevel;
    colSel: TcxGridColumn;
    colNumero: TcxGridColumn;
    colSerie: TcxGridColumn;
    colFecha: TcxGridColumn;
    colCliente: TcxGridColumn;
    colRazonSocial: TcxGridColumn;
    colTotal: TcxGridColumn;
    pnlBottom: TPanel;
    lblEstado: TcxLabel;
    btnSeleccionarTodos: TcxButton;
    btnFacturar: TcxButton;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnSeleccionarTodosClick(Sender: TObject);
    procedure btnFacturarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FRepositorio: IRepositorioFacturacionAlbaranesFechas;
    FAlbaranes: TAlbaranesFacturacionFechas;
    procedure CargarGrid;
    function SolicitarOpcionesFacturas(
      out AOpciones: TOpcionesDocumento): Boolean;
  public
    dmmAlbaranes: TdmAlbaranes;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgFacturas, inLibMsgVentas,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion,
  inMtoModalOpcionesDocumento, inLibMsgOpcionesDocumento,
  UniDataOpcionesDocumentoRepositorio;

procedure TfrmModalFacturarAlbaranesFechas.FormCreate(Sender: TObject);
var
  oContexto: TContextoFacturacionAlbaranesFechasVentasPantalla;
begin
  inherited;
  edtSerie.Text   := '';
  dteDesde.Date   := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  dteHasta.Date   := Date;
  chkAgruparPorCliente.Checked := True;
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FRepositorio := oContexto.Repositorio;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnBuscarClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    lblEstado.Caption := SCaptionBuscandoAlbaranes;
    Application.ProcessMessages;
    FAlbaranes := FRepositorio.Buscar(
      edtSerie.Text,
      dteDesde.Date,
      dteHasta.Date);
    CargarGrid;
    lblEstado.Caption := Format(SCaptionAlbaranesEncontrados,
                                [tvAlbaranes.DataController.RecordCount]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalFacturarAlbaranesFechas.CargarGrid;
var
  i: Integer;
begin
  tvAlbaranes.DataController.RecordCount := 0;
  tvAlbaranes.DataController.RecordCount := Length(FAlbaranes);
  for i := 0 to High(FAlbaranes) do
  begin
    tvAlbaranes.DataController.Values[i, colSel.Index]         := True;
    tvAlbaranes.DataController.Values[i, colNumero.Index]      :=
      FAlbaranes[i].Numero;
    tvAlbaranes.DataController.Values[i, colSerie.Index]       :=
      FAlbaranes[i].Serie;
    tvAlbaranes.DataController.Values[i, colFecha.Index]       :=
      FAlbaranes[i].Fecha;
    tvAlbaranes.DataController.Values[i, colCliente.Index]     :=
      FAlbaranes[i].CodigoCliente;
    tvAlbaranes.DataController.Values[i, colRazonSocial.Index] :=
      FAlbaranes[i].RazonSocial;
    tvAlbaranes.DataController.Values[i, colTotal.Index]       :=
      FAlbaranes[i].Total;
  end;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnSeleccionarTodosClick(
  Sender: TObject);
var
  i: Integer;
  bAlguno: Boolean;
begin
  bAlguno := False;
  for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
    if not Boolean(tvAlbaranes.DataController.Values[i, colSel.Index]) then
    begin
      bAlguno := True;
      Break;
    end;
  for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
    tvAlbaranes.DataController.Values[i, colSel.Index] := bAlguno;
end;

// Una factura por albaran (o por cliente): la serie vacia deja la de
// cada albaran, la forma de pago vacia la de cada albaran y el numero
// sale siempre del contador.
function TfrmModalFacturarAlbaranesFechas.SolicitarOpcionesFacturas(
  out AOpciones: TOpcionesDocumento): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'FC';
  oTipo.Nombre := SNombreFacturaVentaOpcionesDocumento;
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := STituloFacturasAlbaranesOpcionesDocumento;
  oConfig.Tipos := [oTipo];
  oConfig.Propuesta.Empresa := UbicacionSesion.Empresa;
  oConfig.Propuesta.Tipo := 'FC';
  oConfig.Propuesta.Fecha := Date;
  oConfig.Visibles := [codSerie, codNumero, codFecha, codFormaPago];
  oConfig.SerieOpcional := True;
  Result := TfrmModalOpcionesDocumento.Solicitar(Self,
    CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal), oConfig,
    AOpciones);
end;

procedure TfrmModalFacturarAlbaranesFechas.btnFacturarClick(Sender: TObject);
var
  i, generadas: Integer;
  lst: TStringList;
  sNumAlb, sSerAlb: string;
  oOpciones: TOpcionesDocumento;
begin
  if dmmAlbaranes = nil then
  begin
    ShowMessage_fza(SErrorDataModuleAlbaranesNoAsignado);
  end
  else
  begin
    lst := TStringList.Create;
    try
      for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
      begin
        if Boolean(
          tvAlbaranes.DataController.Values[i, colSel.Index]) then
        begin
          sNumAlb := VarToStr(
            tvAlbaranes.DataController.Values[i, colNumero.Index]);
          sSerAlb := VarToStr(
            tvAlbaranes.DataController.Values[i, colSerie.Index]);
          lst.Add(sSerAlb + '|' + sNumAlb);
        end;
      end;
      if lst.Count = 0 then
        ShowMessage_fza(SErrorAlbaranesNoSeleccionados)
      else if SolicitarOpcionesFacturas(oOpciones) then
      begin
        Screen.Cursor := crHourGlass;
        try
          lblEstado.Caption := Format(
            SCaptionCreandoBorradoresAlbaranes, [lst.Count]);
          Application.ProcessMessages;
          generadas := dmmAlbaranes.FacturarAlbaranesLista(lst,
            chkAgruparPorCliente.Checked, oOpciones);
          lblEstado.Caption := Format(SCaptionGeneradosBorradores,
            [generadas]);
          ShowMessageFmt_fza(SInfoBorradoresGenerados, [generadas]);
          btnBuscarClick(nil);
        finally
          Screen.Cursor := crDefault;
        end;
      end;
    finally
      FreeAndNil(lst);
    end;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCargarDocumentoTrabajo                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selecciona un documento de origen y carga sus líneas en un Documento de   }
{    Trabajo.                                                                  }
{******************************************************************************}
unit inMtoModalCargarDocumentoTrabajo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB, inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxContainer, cxLabel,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxButtons, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxCurrencyEdit, cxCalendar,
  inLibDocumentosTrabajo;

type
  TfrmModalCargarDocumentoTrabajo = class(TfrmBase)
    pnlFiltros: TPanel;
    lblEmpresa: TcxLabel;
    txtEmpresa: TcxTextEdit;
    lblCantidad: TcxLabel;
    cbbCantidad: TcxComboBox;
    lblTipo: TcxLabel;
    cbbTipo: TcxComboBox;
    lblSerie: TcxLabel;
    txtSerie: TcxTextEdit;
    lblNumero: TcxLabel;
    txtNumero: TcxTextEdit;
    btnActualizar: TcxButton;
    pnlDocumentos: TPanel;
    lblDocumentos: TcxLabel;
    cxgrdDocumentos: TcxGrid;
    tvDocumentos: TcxGridDBTableView;
    colTipoDocumento: TcxGridDBColumn;
    colFechaDocumento: TcxGridDBColumn;
    colSerieDocumento: TcxGridDBColumn;
    colNumeroDocumento: TcxGridDBColumn;
    colEstadoDocumento: TcxGridDBColumn;
    colTerceroDocumento: TcxGridDBColumn;
    colLineasDocumento: TcxGridDBColumn;
    colUnidadesDocumento: TcxGridDBColumn;
    colInstanteDocumento: TcxGridDBColumn;
    glDocumentos: TcxGridLevel;
    splVistaPrevia: TSplitter;
    pnlLineas: TPanel;
    lblLineas: TcxLabel;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    colLinea: TcxGridDBColumn;
    colArticulo: TcxGridDBColumn;
    colSku: TcxGridDBColumn;
    colAlmacen: TcxGridDBColumn;
    colLote: TcxGridDBColumn;
    colCaducidad: TcxGridDBColumn;
    colDescripcionArticulo: TcxGridDBColumn;
    colDescripcionSku: TcxGridDBColumn;
    colCantidad: TcxGridDBColumn;
    glLineas: TcxGridLevel;
    pnlBotones: TPanel;
    btnCancelar: TcxButton;
    btnCargar: TcxButton;
    dsDocumentos: TDataSource;
    dsLineas: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnActualizarClick(Sender: TObject);
    procedure btnCargarClick(Sender: TObject);
    procedure dsDocumentosDataChange(Sender: TObject; Field: TField);
  private
    FIdDtr: Int64;
    FEmpresa: string;
    FUsuario: string;
    FCargaOrigen: ICargaOrigenDocumentosTrabajo;
    FConsultaDocumentos: IConsultaDocumentoTrabajo;
    FConsultaLineas: IConsultaDocumentoTrabajo;
    FActualizando: Boolean;
    function CantidadSeleccionada: Integer;
    function CrearOrigenSeleccionado(
      out AOrigen: TDocumentoTrabajoOrigen): Boolean;
    function CoincideFiltro(const AValor, AFiltro: string): Boolean;
    procedure ActualizarBotonCargar;
    procedure ActualizarDocumentos;
    procedure CargarVistaPrevia;
    procedure Configurar(AIdDtr: Int64;
      const AEmpresa, AUsuario: string;
      const ACargaOrigen: ICargaOrigenDocumentosTrabajo);
    procedure FiltrarDocumento(DataSet: TDataSet; var Accept: Boolean);
    procedure LiberarDocumentos;
    procedure LiberarLineas;
    function TipoDocumentoSeleccionado: string;
  public
    class function Ejecutar(AOwner: TComponent; AIdDtr: Int64;
      const AEmpresa, AUsuario: string;
      const ACargaOrigen: ICargaOrigenDocumentosTrabajo): Boolean; static;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgVentas;

{$R *.dfm}

class function TfrmModalCargarDocumentoTrabajo.Ejecutar(
  AOwner: TComponent; AIdDtr: Int64;
  const AEmpresa, AUsuario: string;
  const ACargaOrigen: ICargaOrigenDocumentosTrabajo): Boolean;
var
  frm: TfrmModalCargarDocumentoTrabajo;
begin
  Result := False;
  if not Assigned(ACargaOrigen) then
    ShowMessage_fza(SErrorServicioCargaOrigenDocumentoTrabajo)
  else
  begin
    frm := TfrmModalCargarDocumentoTrabajo.Create(AOwner);
    try
      frm.Configurar(AIdDtr, AEmpresa, AUsuario, ACargaOrigen);
      Result := frm.ShowModal = mrOk;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

procedure TfrmModalCargarDocumentoTrabajo.FormCreate(Sender: TObject);
var
  Tipos: TTiposDocumentoTrabajoOrigen;
  I: Integer;
begin
  inherited;
  Caption := STituloCargarOrigenDocumentoTrabajo;
  cbbCantidad.Properties.Items.Clear;
  cbbCantidad.Properties.Items.Add('100');
  cbbCantidad.Properties.Items.Add('250');
  cbbCantidad.Properties.Items.Add('500');
  cbbCantidad.Properties.Items.Add('1000');
  cbbCantidad.ItemIndex := 0;
  cbbTipo.Properties.Items.Clear;
  cbbTipo.Properties.Items.Add(
    SCaptionTodosTiposOrigenDocumentoTrabajo);
  Tipos := TiposDocumentoTrabajoOrigen;
  for I := Low(Tipos) to High(Tipos) do
    cbbTipo.Properties.Items.Add(Tipos[I].Descripcion);
  cbbTipo.ItemIndex := 0;
  btnCargar.Enabled := False;
end;

procedure TfrmModalCargarDocumentoTrabajo.FormDestroy(Sender: TObject);
begin
  LiberarLineas;
  LiberarDocumentos;
  FCargaOrigen := nil;
  inherited;
end;

procedure TfrmModalCargarDocumentoTrabajo.Configurar(AIdDtr: Int64;
  const AEmpresa, AUsuario: string;
  const ACargaOrigen: ICargaOrigenDocumentosTrabajo);
begin
  FIdDtr := AIdDtr;
  FEmpresa := AEmpresa;
  FUsuario := AUsuario;
  FCargaOrigen := ACargaOrigen;
  txtEmpresa.Text := FEmpresa;
  ActualizarDocumentos;
end;

function TfrmModalCargarDocumentoTrabajo.CantidadSeleccionada: Integer;
begin
  Result := StrToIntDef(cbbCantidad.Text,
    LIMITE_DOCUMENTOS_ORIGEN_DEFECTO);
  if Result < 1 then
    Result := LIMITE_DOCUMENTOS_ORIGEN_DEFECTO;
  if Result > LIMITE_DOCUMENTOS_ORIGEN_MAXIMO then
    Result := LIMITE_DOCUMENTOS_ORIGEN_MAXIMO;
end;

procedure TfrmModalCargarDocumentoTrabajo.LiberarDocumentos;
begin
  dsDocumentos.DataSet := nil;
  if FConsultaDocumentos <> nil then
  begin
    FConsultaDocumentos.DataSet.Filtered := False;
    FConsultaDocumentos.DataSet.OnFilterRecord := nil;
  end;
  FConsultaDocumentos := nil;
end;

procedure TfrmModalCargarDocumentoTrabajo.LiberarLineas;
begin
  dsLineas.DataSet := nil;
  FConsultaLineas := nil;
end;

procedure TfrmModalCargarDocumentoTrabajo.ActualizarDocumentos;
begin
  FActualizando := True;
  try
    LiberarLineas;
    LiberarDocumentos;
    FConsultaDocumentos := FCargaOrigen.ConsultarUltimos(
      FEmpresa,
      TipoDocumentoSeleccionado,
      CantidadSeleccionada);
    FConsultaDocumentos.DataSet.OnFilterRecord := FiltrarDocumento;
    dsDocumentos.DataSet := FConsultaDocumentos.DataSet;
    FConsultaDocumentos.DataSet.Filtered := True;
  finally
    FActualizando := False;
  end;
  if FConsultaDocumentos.DataSet.IsEmpty then
    ShowMessage_fza(SInfoDocumentosOrigenDocumentoTrabajoNoEncontrados)
  else
    CargarVistaPrevia;
  ActualizarBotonCargar;
end;

function TfrmModalCargarDocumentoTrabajo.CoincideFiltro(
  const AValor, AFiltro: string): Boolean;
var
  sFiltro: string;
begin
  sFiltro := Trim(AFiltro);
  Result := (sFiltro = '') or
    (Pos(UpperCase(sFiltro), UpperCase(AValor)) > 0);
end;

procedure TfrmModalCargarDocumentoTrabajo.FiltrarDocumento(
  DataSet: TDataSet; var Accept: Boolean);
begin
  Accept :=
    CoincideFiltro(DataSet.FieldByName('SERIE').AsString, txtSerie.Text) and
    CoincideFiltro(DataSet.FieldByName('NUMERO').AsString, txtNumero.Text);
end;

function TfrmModalCargarDocumentoTrabajo.TipoDocumentoSeleccionado: string;
var
  Tipos: TTiposDocumentoTrabajoOrigen;
  Indice: Integer;
begin
  Result := '';
  Tipos := TiposDocumentoTrabajoOrigen;
  Indice := cbbTipo.ItemIndex - 1;
  if (Indice >= Low(Tipos)) and (Indice <= High(Tipos)) then
    Result := Tipos[Indice].Codigo;
end;

function TfrmModalCargarDocumentoTrabajo.CrearOrigenSeleccionado(
  out AOrigen: TDocumentoTrabajoOrigen): Boolean;
var
  Datos: TDataSet;
begin
  AOrigen.Clear;
  Datos := dsDocumentos.DataSet;
  Result := Assigned(Datos) and Datos.Active and not Datos.IsEmpty;
  if Result then
  begin
    AOrigen.Empresa := FEmpresa;
    AOrigen.TipoDocumento :=
      Datos.FieldByName('TIPO_DOCUMENTO').AsString;
    AOrigen.Serie := Datos.FieldByName('SERIE_ORIGEN').AsString;
    AOrigen.Numero := Datos.FieldByName('NUMERO_ORIGEN').AsString;
    AOrigen.SerieVisible := Datos.FieldByName('SERIE').AsString;
    AOrigen.NumeroVisible := Datos.FieldByName('NUMERO').AsString;
  end;
end;

procedure TfrmModalCargarDocumentoTrabajo.CargarVistaPrevia;
var
  Origen: TDocumentoTrabajoOrigen;
begin
  LiberarLineas;
  if CrearOrigenSeleccionado(Origen) then
  begin
    FConsultaLineas := FCargaOrigen.PrevisualizarLineas(Origen);
    dsLineas.DataSet := FConsultaLineas.DataSet;
  end;
  ActualizarBotonCargar;
end;

procedure TfrmModalCargarDocumentoTrabajo.ActualizarBotonCargar;
var
  Datos: TDataSet;
begin
  Datos := dsLineas.DataSet;
  btnCargar.Enabled := Assigned(Datos) and Datos.Active and
    not Datos.IsEmpty;
end;

procedure TfrmModalCargarDocumentoTrabajo.dsDocumentosDataChange(
  Sender: TObject; Field: TField);
begin
  inherited;
  if not FActualizando then
    CargarVistaPrevia;
end;

procedure TfrmModalCargarDocumentoTrabajo.btnActualizarClick(
  Sender: TObject);
begin
  inherited;
  ActualizarDocumentos;
end;

procedure TfrmModalCargarDocumentoTrabajo.btnCargarClick(Sender: TObject);
var
  Origen: TDocumentoTrabajoOrigen;
  Resultado: TResultadoCargaOrigenDocumentoTrabajo;
begin
  inherited;
  if not CrearOrigenSeleccionado(Origen) then
    ShowMessage_fza(SErrorOrigenDocumentoTrabajoNoSeleccionado)
  else
  begin
    Resultado := FCargaOrigen.CargarLineas(
      FIdDtr,
      Origen,
      FUsuario);
    ShowMessage_fza(Format(SInfoCargaOrigenDocumentoTrabajo,
      [Resultado.LineasEncontradas, Resultado.LineasInsertadas,
       Resultado.LineasOmitidas, Resultado.TotalUnidades]));
    ModalResult := mrOk;
  end;
end;

end.

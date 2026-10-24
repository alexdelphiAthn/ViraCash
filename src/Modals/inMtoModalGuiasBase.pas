{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalGuiasBase                                           }
{    Tipo:       Formulario base (Modal)                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Base compartida del constructor visual de guias (fza_informes_guias).     }
{    Provee la UI comun (listboxes, combo tablas, botones anadir/eliminar)     }
{    y define hooks virtuales que los hijos implementan:                       }
{      - TfrmModalGridGuias:     guias para grids (LEFT JOIN runtime)          }
{      - TfrmModalInformesGuias: guias para informes FastReport                }
{******************************************************************************}
unit inMtoModalGuiasBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions,
  Vcl.ActnList, Data.DB,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid, cxMemo,
  cxDropDownEdit, cxListBox,
  JvComponentBase, JvEnterTab, inLibGuiasPersistenciaIntf;

type
  TfrmModalGuiasBase = class(TfrmBase)
    pnlCabecera: TPanel;
    lblTitulo: TcxLabel;
    lblInfo: TcxLabel;
    pnlConstructor: TPanel;
    pnlCamposGrid: TPanel;
    lblCamposMaster: TcxLabel;
    lbCamposMaster: TcxListBox;
    pnlTabla: TPanel;
    lblTabla: TcxLabel;
    cbbTabla: TcxComboBox;
    lblCamposTabla: TcxLabel;
    lbCamposTabla: TcxListBox;
    pnlAcciones: TPanel;
    lblCodigo: TcxLabel;
    edtCodigo: TcxTextEdit;
    lblResumen: TcxLabel;
    mmoResumen: TcxMemo;
    btnAnadir: TcxButton;
    btnEliminar: TcxButton;
    pnlBotones: TPanel;
    btnCerrar: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    dsGuias: TDataSource;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    ActionList1: TActionList;
    actSalir: TAction;
    cxStyleRepo: TcxStyleRepository;
    cxsHeader: TcxStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure cbbTablaPropertiesChange(Sender: TObject);
    procedure btnAnadirClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure lbCamposMasterClick(Sender: TObject);
    procedure lbCamposTablaClick(Sender: TObject);
  protected
    // Hooks que los hijos implementan
    procedure CargarCamposMaster; virtual; abstract;
    function ObtenerClaveInforme: string; virtual; abstract;
    function ObtenerTitulo: string; virtual; abstract;
    function ObtenerInfoCaption: string; virtual; abstract;
    function ObtenerDatasetMaster: string; virtual;
    function ObtenerFormatoSugerido: string; virtual;
    function ObtenerCampoMasterSeleccionado: string; virtual;
    procedure ConfigurarGuiaNueva; virtual;
  private
    FRepositorio: IRepositorioGuias;
    FNavegador: INavegadorGuias;
    FGuias: TDataSet;
    procedure CargarTablas;
    procedure CargarCamposTabla(const sTabla: string);
    procedure ActualizarResumen;
    procedure AutoGenerarCodigo;
  public
    sFormulario: string;
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioGuias); reintroduce; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibUser, inLibMsgComun,
  UniDataConfiguracionPantalla;

resourcestring
  SInfoSeleccionarTablaGuia = 'Selecciona una tabla.';
  SInfoSeleccionarCamposRelacionGuia =
    '  (selecciona campo master y detail)';

constructor TfrmModalGuiasBase.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioGuias);
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'persistencia de guías');
  FRepositorio := ARepositorio;
  inherited Create(AOwner);
end;

procedure TfrmModalGuiasBase.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  ValidarDependenciaConfiguracion(
    FRepositorio,
    'persistencia de guías');
end;

procedure TfrmModalGuiasBase.FormShow(Sender: TObject);
begin
  inherited;
  FNavegador := FRepositorio.ConsultarGuias(ObtenerClaveInforme);
  FGuias := FNavegador.DataSet;
  dsGuias.DataSet := FGuias;
  lblTitulo.Caption := ObtenerTitulo;
  lblInfo.Caption := ObtenerInfoCaption;
  CargarCamposMaster;
  CargarTablas;
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.CargarTablas;
var
  aTablas: TNombresEsquemaGuias;
  sTabla: string;
begin
  cbbTabla.Properties.Items.Clear;
  aTablas := FRepositorio.ListarTablas;
  for sTabla in aTablas do
  begin
    cbbTabla.Properties.Items.Add(sTabla);
  end;
end;

procedure TfrmModalGuiasBase.cbbTablaPropertiesChange(Sender: TObject);
begin
  CargarCamposTabla(cbbTabla.Text);
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.CargarCamposTabla(const sTabla: string);
var
  aCampos: TNombresEsquemaGuias;
  sCampo: string;
begin
  lbCamposTabla.Items.Clear;
  if sTabla <> '' then
  begin
    aCampos := FRepositorio.ListarCamposTabla(sTabla);
    for sCampo in aCampos do
      lbCamposTabla.Items.Add(sCampo);
  end;
end;

procedure TfrmModalGuiasBase.ActualizarResumen;
var
  sMaster, sDetail, sTabla: string;
begin
  mmoResumen.Lines.Clear;
  sTabla := cbbTabla.Text;
  if sTabla = '' then
  begin
    mmoResumen.Lines.Add(SInfoSeleccionarTablaGuia);
  end
  else
  begin
    sMaster := '';
    sDetail := '';
    if lbCamposMaster.ItemIndex >= 0 then
      sMaster := ObtenerCampoMasterSeleccionado;
    if lbCamposTabla.ItemIndex >= 0 then
      sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
    mmoResumen.Lines.Add('LEFT JOIN ' + sTabla);
    if (sMaster <> '') and (sDetail <> '') then
      mmoResumen.Lines.Add('  ON ' + sDetail + ' = ' + sMaster)
    else
      mmoResumen.Lines.Add(SInfoSeleccionarCamposRelacionGuia);
    AutoGenerarCodigo;
  end;
end;

procedure TfrmModalGuiasBase.AutoGenerarCodigo;
var
  sMaster, sTabla, sDetail, sBase, sCodigo: string;
  i: Integer;
begin
  sTabla := UpperCase(cbbTabla.Text);
  if (sTabla <> '') and (lbCamposMaster.ItemIndex >= 0) and
     (lbCamposTabla.ItemIndex >= 0) then
  begin
    sMaster := UpperCase(ObtenerCampoMasterSeleccionado);
    sDetail := UpperCase(
      lbCamposTabla.Items[lbCamposTabla.ItemIndex]);
    sBase := sMaster + '.' + sTabla + '.' + sDetail;
    sCodigo := sBase;
    // Si ya existe una guía con ese código, añadir sufijo numérico
    if FGuias.Active then
    begin
      i := 1;
      FGuias.DisableControls;
      try
        while FGuias.Locate(
          'CODIGO_INFGUI',
          sCodigo,
          [loCaseInsensitive]) do
        begin
          sCodigo := sBase + IntToStr(i);
          Inc(i);
        end;
      finally
        FGuias.EnableControls;
      end;
    end;
    edtCodigo.Text := sCodigo;
  end;
end;

procedure TfrmModalGuiasBase.lbCamposMasterClick(Sender: TObject);
begin
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.lbCamposTablaClick(Sender: TObject);
begin
  ActualizarResumen;
end;

// Hooks con implementacion por defecto

function TfrmModalGuiasBase.ObtenerDatasetMaster: string;
begin
  Result := '';
end;

function TfrmModalGuiasBase.ObtenerFormatoSugerido: string;
begin
  Result := '';
end;

function TfrmModalGuiasBase.ObtenerCampoMasterSeleccionado: string;
begin
  if lbCamposMaster.ItemIndex >= 0 then
    Result := lbCamposMaster.Items[lbCamposMaster.ItemIndex]
  else
    Result := '';
end;

procedure TfrmModalGuiasBase.ConfigurarGuiaNueva;
begin
  // Los hijos pueden añadir campos extra
end;

procedure TfrmModalGuiasBase.btnAnadirClick(Sender: TObject);
var
  sCodigo, sTabla, sMaster, sDetail: string;
begin
  sCodigo := Trim(edtCodigo.Text);
  sTabla  := cbbTabla.Text;
  if sCodigo = '' then
  begin
    ShowMessage_fza(SErrorCodigoGuiaNoIndicado);
    edtCodigo.SetFocus;
  end
  else if sTabla = '' then
  begin
    ShowMessage_fza(SErrorTablaExternaGuiaNoSeleccionada);
  end
  else if lbCamposMaster.ItemIndex < 0 then
  begin
    ShowMessage_fza(SErrorCampoMasterGuiaNoSeleccionado);
  end
  else if lbCamposTabla.ItemIndex < 0 then
  begin
    ShowMessage_fza(SErrorCampoDetailGuiaNoSeleccionado);
  end
  else
  begin
    sMaster := ObtenerCampoMasterSeleccionado;
    sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
    FGuias.Append;
    FGuias.FieldByName('CODIGO_INFGUI').AsString := sCodigo;
    FGuias.FieldByName('INFORME_INFGUI').AsString := ObtenerClaveInforme;
    FGuias.FieldByName('FORMATO_INFGUI').AsString := ObtenerFormatoSugerido;
    FGuias.FieldByName('DATASET_MASTER_INFGUI').AsString :=
      ObtenerDatasetMaster;
    FGuias.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
    FGuias.FieldByName('TABLA_INFGUI').AsString := sTabla;
    FGuias.FieldByName('MASTER_FIELDS_INFGUI').AsString := sMaster;
    FGuias.FieldByName('DETAIL_FIELDS_INFGUI').AsString := sDetail;
    FGuias.FieldByName('ORDEN_INFGUI').AsInteger := FGuias.RecordCount;
    FGuias.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
    FGuias.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FGuias.FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    FGuias.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
    FGuias.FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
    ConfigurarGuiaNueva;
    FGuias.Post;
    ShowMessage_fza(Format(SInfoGuiaAnadida,
      [sCodigo, sTabla, sDetail, sMaster]));
    edtCodigo.Text := '';
  end;
end;

procedure TfrmModalGuiasBase.btnEliminarClick(Sender: TObject);
begin
  if FGuias.IsEmpty then
  begin
    ShowMessage_fza(SInfoGuiasEliminarNoEncontradas);
  end
  else if MessageDlg_fza(
    Format(SPreguntaEliminarGuia,
      [FGuias.FieldByName('CODIGO_INFGUI').AsString]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    FGuias.Delete;
end;

procedure TfrmModalGuiasBase.FormClose(Sender: TObject;
                                       var Action: TCloseAction);
begin
  inherited;
  if Assigned(FGuias) then
  begin
    if FGuias.State in [dsEdit, dsInsert] then
    begin
      FGuias.Post;
    end;
    FGuias.Close;
  end;
  dsGuias.DataSet := nil;
  FGuias := nil;
  FNavegador := nil;
end;

procedure TfrmModalGuiasBase.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmModalGuiasBase.actSalirExecute(Sender: TObject);
begin
  btnCerrarClick(Sender);
end;

end.

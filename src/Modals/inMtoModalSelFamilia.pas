{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelFamilia                                          }
{    Tipo:       Formulario (Modal)                                            }
{                                                                              }
{  Descripcion:                                                                }
{    Selector jerarquico y reutilizable de familias. Devuelve el codigo y el  }
{    nombre de la familia elegida.                                             }
{******************************************************************************}
unit inMtoModalSelFamilia;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Actions, Vcl.ActnList,
  Data.DB, inMtoFrmBase, inLibSeleccionFamiliaPersistenciaIntf,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxLabel, cxButtons, cxTextEdit, cxLocalization,
  cxStyles, cxData, cxDataStorage, cxCustomData, cxFilter, cxNavigator,
  cxTL, cxTLData, cxDBTL, cxInplaceContainer,
  dxSkinsCore, dxSkinsForm, dxSkinsDefaultPainters, dxSkinBlue,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab;

type
  TfrmModalSelFamilia = class(TfrmBase)
    pnlBody           : TPanel;
    pnlButton         : TPanel;
    pnlFiltro         : TPanel;
    btnAceptar        : TcxButton;
    btnCancelar       : TcxButton;
    lblFiltro         : TcxLabel;
    txtFiltro         : TcxTextEdit;
    tlFamilias        : TcxDBTreeList;
    tlcNombre         : TcxDBTreeListColumn;
    tlcCodigo         : TcxDBTreeListColumn;
    dsFamilias        : TDataSource;
    ActionList1       : TActionList;
    actAceptar        : TAction;
    actCancelar       : TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure txtFiltroPropertiesChange(Sender: TObject);
    procedure tlFamiliasDblClick(Sender: TObject);
  private
    FCodigoFamilia : string;
    FNombreFamilia : string;
    FCodigoFamiliaInicial: string;
    FRepositorio: IRepositorioSeleccionFamilia;
    FConsulta: IConsultaSeleccionFamilia;
    FFamilias: TDataSet;
    procedure AplicarFiltro;
  public
    property CodigoFamilia : string read FCodigoFamilia;
    property NombreFamilia : string read FNombreFamilia;
    property CodigoFamiliaInicial: string read FCodigoFamiliaInicial
      write FCodigoFamiliaInicial;
  end;

implementation

uses
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

{$R *.dfm}

procedure TfrmModalSelFamilia.FormCreate(Sender: TObject);
var
  oContexto: TContextoSeleccionFamiliaVentasPantalla;
begin
  inherited;
  Self.Position := poScreenCenter;
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FRepositorio := oContexto.Repositorio;
  FConsulta := FRepositorio.CrearConsulta;
  FFamilias := FConsulta.DataSet;
  dsFamilias.DataSet := FFamilias;
end;

procedure TfrmModalSelFamilia.FormShow(Sender: TObject);
var
  oNodo: TcxTreeListNode;
begin
  inherited;
  AplicarFiltro;
  if FCodigoFamiliaInicial <> '' then
  begin
    oNodo := tlFamilias.FindNodeByKeyValue(FCodigoFamiliaInicial);
    if oNodo <> nil then
      tlFamilias.FocusedNode := oNodo;
  end;
  if txtFiltro.CanFocus then
    txtFiltro.SetFocus;
end;

procedure TfrmModalSelFamilia.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  dsFamilias.DataSet := nil;
  FFamilias := nil;
  FConsulta := nil;
  FRepositorio := nil;
  Action := caHide;
end;

procedure TfrmModalSelFamilia.AplicarFiltro;
var
  sTxt : string;
begin
  sTxt := Trim(txtFiltro.Text);
  FConsulta.AplicarFiltro(sTxt);
  tlFamilias.FullExpand;
end;

procedure TfrmModalSelFamilia.txtFiltroPropertiesChange(Sender: TObject);
begin
  inherited;
  AplicarFiltro;
end;

procedure TfrmModalSelFamilia.tlFamiliasDblClick(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelFamilia.btnAceptarClick(Sender: TObject);
begin
  inherited;
  if (FFamilias.IsEmpty) or
     (tlFamilias.FocusedNode = nil) then
  begin
    FCodigoFamilia := '';
    ModalResult := mrCancel;
  end
  else
  begin
    FCodigoFamilia := FFamilias.FieldByName('CODIGO_FAM_FAM').AsString;
    FNombreFamilia := FFamilias.FieldByName('NOMBRE_FAM_FAM').AsString;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalSelFamilia.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FCodigoFamilia := '';
  ModalResult := mrCancel;
end;

procedure TfrmModalSelFamilia.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelFamilia.actCancelarExecute(Sender: TObject);
begin
  inherited;
  btnCancelarClick(Sender);
end;

end.

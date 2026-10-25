{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCajDef                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de seleccion de almacen/caja por defecto del usuario.               }
{    Devuelve la combinacion Empresa/Almacen/Caja elegida.                     }
{******************************************************************************}
unit inMtoModalCajDef;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxCore, dxSkinsForm,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics,
  cxControls, cxLookAndFeelPainters, cxCustomListBox, cxCheckListBox,
  cxDBCheckListBox, UniDataArticulos, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  Vcl.ExtCtrls, Vcl.ComCtrls, cxListView, cxStyles, Data.DB, JvComponentBase,
  JvEnterTab, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxDBData, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridCustomView,
  cxGrid, System.Actions, Vcl.ActnList,
  inLibCajasDefectoPersistenciaIntf, inLibCajaPantallaInyeccion;
type
  TfrmMtoModalCajDef = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    cxgrdAlmacenCajas: TcxGrid;
    tvAlmacenesCajas: TcxGridDBTableView;
    lvAlmacenCajas: TcxGridLevel;
    DataSource1: TDataSource;
    tvAlmacenesCajasEmpresa: TcxGridDBColumn;
    tvAlmacenesCajasNombreEmpresa: TcxGridDBColumn;
    tvAlmacenesCajasAlmacn: TcxGridDBColumn;
    tvAlmacenesCajasNombreAlmacn: TcxGridDBColumn;
    tvAlmacenesCajasCaja: TcxGridDBColumn;
    tvAlmacenesCajasNombreCaja: TcxGridDBColumn;
    ActionList1: TActionList;
    Action1: TAction;
    Action2: TAction;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelar1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
    procedure NavegarCajas(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FRepositorioPersistencia: IRepositorioCajasDefecto;
    FResultado: IResultadoCajasDefecto;
    FDatos: TDataSet;
    procedure ActualizarRotulos;
  public
    sFicha:string;
    sEmpresa: string;
    sAlmacen: string;
    sCaja:    string;
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioCajasDefecto); reintroduce;
      overload;
    procedure Cargar(const AEmpresaFiltro: string = '');
    function EmpresaSeleccionada: string;
    function AlmacenSeleccionado: string;
    function CajaSeleccionada: string;
    procedure AplicarTraduccionActual; override;
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses
  inLibFiltroUsuario, inLibMsgCaja;

constructor TfrmMtoModalCajDef.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioCajasDefecto);
begin
  ValidarDependenciaCaja(ARepositorio, 'selección de cajas');
  FRepositorioPersistencia := ARepositorio;
  inherited Create(AOwner);
end;

procedure TfrmMtoModalCajDef.Action1Execute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmMtoModalCajDef.Action2Execute(Sender: TObject);
begin
  inherited;
  btnCancelar1Click(Sender);
end;

procedure TfrmMtoModalCajDef.btnAceptarClick(Sender: TObject);
begin
  inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalCajDef.btnCancelar1Click(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalCajDef.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoModalCajDef.FormCreate(Sender: TObject);
begin
  inherited;
  ValidarDependenciaCaja(
    FRepositorioPersistencia,
    'selección de cajas');
  Self.Position := poScreenCenter;
  ActualizarRotulos;
  KeyPreview := True;
  OnKeyDown := NavegarCajas;
  tvAlmacenesCajas.OptionsBehavior.IncSearch := True;
  tvAlmacenesCajas.OptionsBehavior.IncSearchItem := tvAlmacenesCajasAlmacn;
  Cargar;
end;

procedure TfrmMtoModalCajDef.NavegarCajas(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and (Key in [VK_HOME, VK_END]) then
  begin
    if Key = VK_HOME then
      tvAlmacenesCajas.Controller.GoToFirst(True)
    else
      tvAlmacenesCajas.Controller.GoToLast(True);
    Key := 0;
  end;
end;

procedure TfrmMtoModalCajDef.AplicarTraduccionActual;
begin
  inherited;
  ActualizarRotulos;
end;

// Sin Caption, la rejilla rotula con el nombre del campo de la consulta.
procedure TfrmMtoModalCajDef.ActualizarRotulos;
begin
  tvAlmacenesCajasEmpresa.Caption := SCaptionColEmpresaSeleccionCaja;
  tvAlmacenesCajasNombreEmpresa.Caption :=
    SCaptionColNombreEmpresaSeleccionCaja;
  tvAlmacenesCajasAlmacn.Caption := SCaptionColAlmacenSeleccionCaja;
  tvAlmacenesCajasNombreAlmacn.Caption :=
    SCaptionColNombreAlmacenSeleccionCaja;
  tvAlmacenesCajasCaja.Caption := SCaptionColCajaSeleccionCaja;
  tvAlmacenesCajasNombreCaja.Caption := SCaptionColNombreCajaSeleccionCaja;
end;

procedure TfrmMtoModalCajDef.Cargar(const AEmpresaFiltro: string);
var
  Solicitud: TSolicitudCajasDefecto;
begin
  Solicitud.EmpresaFiltro := AEmpresaFiltro;
  Solicitud.EmpresaRestringida :=
    EmpresaRestringida(ContextoSesion, ParametrosApp);
  Solicitud.AlmacenRestringido :=
    AlmacenRestringido(ContextoSesion, ParametrosApp);
  Solicitud.CajaRestringida :=
    CajaRestringida(ContextoSesion, ParametrosApp);
  DataSource1.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorioPersistencia.Consultar(Solicitud);
  FDatos := FResultado.DataSet;
  DataSource1.DataSet := FDatos;
end;

function TfrmMtoModalCajDef.EmpresaSeleccionada: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Empresa').AsString;
  end;
end;

function TfrmMtoModalCajDef.AlmacenSeleccionado: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Almacen').AsString;
  end;
end;

function TfrmMtoModalCajDef.CajaSeleccionada: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Caja').AsString;
  end;
end;

procedure TfrmMtoModalCajDef.FormShow(Sender: TObject);
begin
  inherited;
  if Assigned(FDatos) then
  begin
    FDatos.Locate(
      'Empresa;Almacen;Caja',
      VarArrayOf([sEmpresa, sAlmacen, sCaja]),
      []);
  end;
  if cxgrdAlmacenCajas.CanFocus then
    cxgrdAlmacenCajas.SetFocus;
  tvAlmacenesCajas.ApplyBestFit(nil, True, False);
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoUsuarios                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de usuarios de la aplicacion.                               }
{    Credenciales, grupo y configuracion personal de cada usuario.             }
{******************************************************************************}
unit inMtoUsuarios;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataUsuarios, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxDBExtLookupComboBox, cxDBLookupComboBox, cxCalendar, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, dxShellDialogs, dxSkinBlue, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue,
  inLibPermisosIntf,
  inLibCajasDefectoPersistenciaIntf;

type
  TfrmMtoUsuarios = class(TfrmMtoGen)
    cxGrdDBTabPrinUSUARIO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinPASSWORD_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinGRUPO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinEMPRESADEF_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinULTIMOLOGIN_USUARIO: TcxGridDBColumn;
    btnSetPass: TcxButton;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESGRUPOADMINISTRADOR_GRUPO: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinALMACENDEF_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinCAJADEF_USUARIO: TcxGridDBColumn;
    btnSetCaja: TcxButton;
    procedure btnSetPassClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnSetCajaClick(Sender: TObject);
  private
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
  public
    dmmUsuarios: TdmUsuarios;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ARepositorio: IRepositorioCajasDefecto); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inMtoModalGenPass, inMtoModalCajDef;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoUsuarios }

constructor TfrmMtoUsuarios.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ARepositorio: IRepositorioCajasDefecto);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorioCajasDefecto := ARepositorio;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoUsuarios.btnSetPassClick(Sender: TObject);
var
  sContrasenaNueva: string;
  sUsuario: string;
begin
  inherited;
  sUsuario :=
    dmmUsuarios.unqryTablaG.FieldByName('USUARIO_USU').AsString;
  if TfrmModalGenPass.SolicitarNueva(
       Application,
       sUsuario,
       sContrasenaNueva) then
  begin
    try
      if ((dsTablaG.DataSet.State <> dsInsert) and
          (dsTablaG.DataSet.State <> dsEdit)) then
        dsTablaG.DataSet.Edit;
      dmmUsuarios.unqryTablaG.FieldByName('PASSWORD_USU').AsString :=
        sMd5(sContrasenaNueva);
      dmmUsuarios.unqryTablaG.Post;
    finally
      sContrasenaNueva := '';
    end;
  end;
end;

procedure TfrmMtoUsuarios.btnSetCajaClick(Sender: TObject);
var
  bAceptado: Boolean;
  frm: TfrmMtoModalCajDef;
  sAlmacen, sCaja, sEmpresa: string;
begin
  inherited;
  // Selector Empresa/Almacen/Caja por defecto del usuario (el mismo dialogo
  // que F5 en el menu de caja). Rellena los tres campos de forma coherente.
  frm := TfrmMtoModalCajDef.Create(
    Application,
    FRepositorioCajasDefecto);
  try
    frm.sEmpresa :=
      dmmUsuarios.unqryTablaG.FieldByName('EMPRESA_DEFECTO_USU').AsString;
    frm.sAlmacen :=
      dmmUsuarios.unqryTablaG.FieldByName('ALMACEN_DEFECTO_USU').AsString;
    frm.sCaja    :=
      dmmUsuarios.unqryTablaG.FieldByName('CAJA_DEFECTO_USU').AsString;
    frm.ShowModal;
    bAceptado := frm.sFicha = 'S';
    if bAceptado then
    begin
      sEmpresa := frm.EmpresaSeleccionada;
      sAlmacen := frm.AlmacenSeleccionado;
      sCaja := frm.CajaSeleccionada;
    end;
  finally
    FreeAndNil(frm);
  end;
  // FZ-ISSUE-397: el diálogo se libera antes de tocar el dataset. Al
  // cerrarse pide su propia liberación (caFree) y, si grabar enseñaba un
  // aviso, se liberaba dos veces: «Invalid pointer operation».
  if bAceptado then
  begin
    if ((dsTablaG.DataSet.State <> dsInsert) and
        (dsTablaG.DataSet.State <> dsEdit)) then
      dsTablaG.DataSet.Edit;
    dmmUsuarios.unqryTablaG.FieldByName('EMPRESA_DEFECTO_USU').AsString :=
      sEmpresa;
    dmmUsuarios.unqryTablaG.FieldByName('ALMACEN_DEFECTO_USU').AsString :=
      sAlmacen;
    dmmUsuarios.unqryTablaG.FieldByName('CAJA_DEFECTO_USU').AsString :=
      sCaja;
    // El usuario nuevo se graba al ponerle la contraseña: hasta entonces
    // la elección queda en la fila, sin el aviso de que falta.
    if dsTablaG.DataSet.State <> dsInsert then
      dmmUsuarios.unqryTablaG.Post;
  end;
end;

procedure TfrmMtoUsuarios.CrearTablaPrincipal;
begin
  inherited;
  dmmUsuarios := tdmDataModule as TdmUsuarios;
  TcxLookupComboBoxProperties(
    cxGrdDBTabPrinGRUPO_USUARIO.Properties).ListSource := dmmUsuarios.dsGrupos;
  dmmUsuarios.unqryGrupos.Open;
  TcxLookupComboBoxProperties(
    cxGrdDBTabPrinEMPRESADEF_USUARIO.Properties).ListSource :=
                                                         dmmUsuarios.dsEmpresas;
  dmmUsuarios.unqryEmpresas.Open;
  pkFieldName := 'USUARIO_USU';
  // FZ-ISSUE-397: el usuario se da de alta en la rejilla. Con Tab se pasa
  // a la celda siguiente (grupo) en vez de salir al buscador.
  cxGrdDBTabPrin.OptionsBehavior.FocusCellOnTab := True;
end;

procedure TfrmMtoUsuarios.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoUsuarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    cxGrdDBTabPrinUSUARIO_USUARIO.Options.Editing := True
  else
    cxGrdDBTabPrinUSUARIO_USUARIO.Options.Editing := False;
end;

initialization
  RegistrarPantalla(TfrmMtoUsuarios);
  ForceReferenceToClass(TfrmMtoUsuarios);
end.

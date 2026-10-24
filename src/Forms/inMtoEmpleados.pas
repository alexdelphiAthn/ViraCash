{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEmpleados                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de empleados (operarios de caja, traspasos y arqueos).      }
{    Datos de identificación/contacto + número de empleado en caja y           }
{    diminutivo de ticket. Independiente de los usuarios de login.             }
{******************************************************************************}
unit inMtoEmpleados;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEmpleados, cxCheckBox,
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
  dxSkinXmas2008Blue;

type
  TfrmMtoEmpleados = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinRAZON_SOCIAL_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinNIF_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinDIRECCION_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinDIRECCION2_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_POSTAL_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinPOBLACION_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinPROVINCIA_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinTELEFONO_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinTELEFONO2_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinFAX_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinEMAIL_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinWEB_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinIBAN_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinBIC_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinDIMINUTIVO_TICKET_EMPL: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_EMPL: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    dmmEmpleados: TdmEmpleados;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoEmpleados }

procedure TfrmMtoEmpleados.CrearTablaPrincipal;
begin
  inherited;
  dmmEmpleados := tdmDataModule as TdmEmpleados;
  pkFieldName := 'CODIGO_EMPL';
end;

procedure TfrmMtoEmpleados.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoEmpleados.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // El código de empleado (PK) solo es editable al dar de alta.
  if (dsTablaG.State = dsInsert) then
    cxGrdDBTabPrinCODIGO_EMPL.Options.Editing := True
  else
    cxGrdDBTabPrinCODIGO_EMPL.Options.Editing := False;
end;

initialization
  RegistrarPantalla(TfrmMtoEmpleados);
  ForceReferenceToClass(TfrmMtoEmpleados);
end.

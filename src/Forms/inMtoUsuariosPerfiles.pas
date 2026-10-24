{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoUsuariosPerfiles                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de perfiles de usuario.                                     }
{    Asociacion clave-valor de preferencias por usuario y grupo.               }
{******************************************************************************}
unit inMtoUsuariosPerfiles;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inmtoprincipal,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataUsuariosPerfiles,
  cxCheckBox,
  cxSpinEdit, cxDBEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoUsuariosPerfiles = class(TfrmMtoGen)
    cxGrdDBTabPrinUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinKEY_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinSUBKEY_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_TEXT_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinTYPE_BLOB_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_BLOB_PERFILES: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmUsuariosPerfiles: TdmUsuariosPerfiles;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoUsuariosPerfiles }

procedure TfrmMtoUsuariosPerfiles.CrearTablaPrincipal;
begin
  inherited;
  dmmUsuariosPerfiles := tdmDataModule as TdmUsuariosPerfiles;
  dsTablaG.DataSet := dmmUsuariosPerfiles.unqryTablaG;
  pkFieldName := 'USUARIO_GRUPO_USUPER;KEY_USUPER;SUBKEY_USUPER';
end;

procedure TfrmMtoUsuariosPerfiles.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoUsuariosPerfiles);
  ForceReferenceToClass(TfrmMtoUsuariosPerfiles);
end.

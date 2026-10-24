{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPermisos                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de permisos.                                                }
{    Asociacion codigo-valor de permisos por usuario, grupo y Todos.           }
{    Resolucion en runtime (inLibPermisos): admin, usuario, grupo, Todos.      }
{******************************************************************************}
unit inMtoPermisos;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPermisosGrupo,
  cxCheckBox,
  cxSpinEdit, cxDBEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoPermisos = class(TfrmMtoGen)
    cxGrdDBTabPrinUSUARIO_GRUPO_PERM: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PERM: TcxGridDBColumn;
    cxGrdDBTabPrinVALOR_PERM: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_PERM: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmPermisos: TdmPermisosGrupo;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPermisos }

procedure TfrmMtoPermisos.CrearTablaPrincipal;
begin
  inherited;
  dmmPermisos := tdmDataModule as TdmPermisosGrupo;
  dsTablaG.DataSet := dmmPermisos.unqryTablaG;
  pkFieldName := 'USUARIO_GRUPO_PERM;CODIGO_PERM';
end;

procedure TfrmMtoPermisos.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoPermisos);
  ForceReferenceToClass(TfrmMtoPermisos);
end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoIvasGrupos                                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de grupos de zona de IVA.                                   }
{    Agrupa zonas para aplicar regimenes fiscales por cliente.                 }
{******************************************************************************}
unit inMtoIvasGrupos;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataIvasGrupos, cxSpinEdit,
  cxCalendar, cxCheckBox, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoIvasGrupos = class(TfrmMtoGen)
    cxGrdDBTabPrinGRUPO_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESAPLICA_RE_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESDEFAULT_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  public
    dmmIvasGrupos: TdmIvasGrupos;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoIvasGrupos.CrearTablaPrincipal;
begin
  inherited;
  dmmIvasGrupos := tdmDataModule as TdmIvasGrupos;
  pkFieldName := 'IVA_IVAGRP';
end;

procedure TfrmMtoIvasGrupos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoIvasGrupos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    cxGrdDBTabPrinGRUPO_ZONA_IVA.Options.Editing := True
  else
    cxGrdDBTabPrinGRUPO_ZONA_IVA.Options.Editing := False;
end;

initialization
  RegistrarPantalla(TfrmMtoIvasGrupos);
  ForceReferenceToClass(TfrmMtoIvasGrupos);
end.

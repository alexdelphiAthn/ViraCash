{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGrupos                                                   }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de grupos de usuario.                                       }
{    Define grupos y permiso de administrador asociado.                        }
{******************************************************************************}
unit inMtoGrupos;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataGrupos, cxCheckBox,
  cxSpinEdit, cxDBEdit, cxCalendar, dxScrollbarAnnotations, cxBlobEdit, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoGrupos = class(TfrmMtoGen)
    cxGrdDBTabPrinGRUPO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinESGRUPOADMINISTRADOR: TcxGridDBColumn;
    pnlBodyFicha: TPanel;
    lblNombreGrupo: TcxLabel;
    lblEsGrupoAdmin: TcxLabel;
    txtNOMBRE_GRUPO: TcxDBTextEdit;
    chkESGRUPOADMINISTRADOR_USUGRP: TcxDBCheckBox;
    cxgrdUsuarios: TcxGrid;
    tvUsuarios: TcxGridDBTableView;
    cxgrdlvlUsuarios: TcxGridLevel;
    tvUsuariosUSUARIO_USUARIO: TcxGridDBColumn;
    tvUsuariosGRUPO_USUARIO: TcxGridDBColumn;
    tvUsuariosEMPRESADEF_USUARIO: TcxGridDBColumn;
    tvUsuariosULTIMOLOGIN_USUARIO: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    dmmGrupos: TdmGrupos;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibBotonesDetalle,
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoGrupos }

procedure TfrmMtoGrupos.CrearTablaPrincipal;
begin
  inherited;
  dmmGrupos :=  tdmDataModule as TdmGrupos;
  dsTablaG.DataSet := dmmGrupos.unqryTablaG;
  tvUsuarios.DataController.DataSource := dmmGrupos.dsUsuariosGrupo;
  pkFieldName := 'GRUPO_USUGRP';
  // Botones «Añadir» y «Borrar» sobre las rejillas de detalle, además
  // de los «+» y «-» del navegador.
  AnadirBotonesDetalle(tvUsuarios);
end;

procedure TfrmMtoGrupos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoGrupos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtNOMBRE_GRUPO.Enabled := True
  else
    txtNOMBRE_GRUPO.Enabled := False;
end;

initialization
  RegistrarPantalla(TfrmMtoGrupos);
  ForceReferenceToClass(TfrmMtoGrupos);
end.

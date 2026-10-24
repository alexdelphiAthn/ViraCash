{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPaises                                                   }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de paises.                                                  }
{    CRUD sobre fza_paises con codigos y nombres oficiales.                    }
{******************************************************************************}
unit inMtoPaises;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPaises, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoPaises = class(TfrmMtoGen)
    dbcGrdDBTabPrinCOD_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_SPA_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_ENG_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinCOD_PAIS_ALPHA3: TcxGridDBColumn;
    dbcGrdDBTabPrinCOD_PAIS_ALPHA2: TcxGridDBColumn;
    dbcGrdDBTabPrinESMIEMBRO_UE_PAIS: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmPaises: TdmPaises;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoContadores }

procedure TfrmMtoPaises.CrearTablaPrincipal;
begin
  inherited;
  dmmPaises := tdmDataModule as TdmPaises;
  pkFieldName := 'CODIGO_PAI_PAI';
end;

procedure TfrmMtoPaises.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoPaises);
  ForceReferenceToClass(TfrmMtoPaises);
end.

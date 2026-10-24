{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoUnidadesMedida                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de unidades de medida.                                      }
{    CRUD sobre fza_unidades_medida: decimales por unidad y conversión a la    }
{    unidad estándar de cada magnitud.                                         }
{******************************************************************************}
unit inMtoUnidadesMedida;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataUnidadesMedida,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoUnidadesMedida = class(TfrmMtoGen)
    dbcGrdDBTabPrinCODIGO_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinDECIMALES_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinMAGNITUD_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinESBASE_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinFACTOR_BASE_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_UNIMED: TcxGridDBColumn;
    dbcGrdDBTabPrinESACTIVO_UNIMED: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmUnidadesMedida: TdmUnidadesMedida;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoUnidadesMedida.CrearTablaPrincipal;
begin
  inherited;
  dmmUnidadesMedida := tdmDataModule as TdmUnidadesMedida;
  pkFieldName := 'CODIGO_UNIMED';
end;

procedure TfrmMtoUnidadesMedida.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoUnidadesMedida);
  ForceReferenceToClass(TfrmMtoUnidadesMedida);
end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPropiedadesValores                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de valores de propiedades de articulo.                      }
{    Lista de valores admitidos por cada propiedad definida.                   }
{******************************************************************************}
unit inMtoPropiedadesValores;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPropiedadesValores,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoPropiedadesValores = class(TfrmMtoGen)
    cxGrdDBTabPrinID_PV_ARTPROP: TcxGridDBColumn;
    cxGrdDBTabPrinID_PROP_PV: TcxGridDBColumn;
    cxGrdDBTabPrinPV: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_PV: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_PV: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn;
  private
    dmmPropiedadesValores: TdmPropiedadesValores;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPropiedadesValores }

procedure TfrmMtoPropiedadesValores.CrearTablaPrincipal;
begin
  inherited;
  dmmPropiedadesValores := tdmDataModule as TdmPropiedadesValores;
  pkFieldName := 'ID_PV_ARTPROP';
end;

procedure TfrmMtoPropiedadesValores.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoPropiedadesValores);
  ForceReferenceToClass(TfrmMtoPropiedadesValores);
end.

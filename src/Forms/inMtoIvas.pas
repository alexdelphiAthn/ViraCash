{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoIvas                                                     }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de tipos de IVA.                                            }
{    Tipos impositivos, recargo de equivalencia y vigencia.                    }
{******************************************************************************}
unit inMtoIvas;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataIvas, cxSpinEdit,
  cxCalendar, cxDBExtLookupComboBox, cxDBLookupComboBox, dxScrollbarAnnotations,
  cxBlobEdit, dxCore, cxRadioGroup, cxCheckBox,
  JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoIvas = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinGRUPO_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENEXENTO_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENEXENTO_RE_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENNORMAL_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENNORMAL_RE_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENREDUCIDO_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENREDUCIDO_RE_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENSUPERREDUCIDO_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPORCENSUPERREDUCIDO_RE_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_DESDE_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_HASTA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinESAPLICA_RE_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESDEFAULT_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA: TcxGridDBColumn;
    cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA: TcxGridDBColumn;
    procedure cxgrdbclmnGrdDBTabPrinGRUPO_ZONA_IVAPropertiesChange(
      Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  public
    dmmIvas: TdmIvas;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoIvas.CrearTablaPrincipal;
begin
  inherited;
  dmmIvas := tdmDataModule as TdmIvas;
  (cxGrdDBTabPrinGRUPO_ZONA_IVA.Properties as
                     TcxLookupComboBoxProperties).ListSource := dmmIvas.dsZonas;
  pkFieldName := 'CODIGO_IVA';
end;

procedure TfrmMtoIvas.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoIvas.cxgrdbclmnGrdDBTabPrinGRUPO_ZONA_IVAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  //copio la descripcion de Zona a la sig columna
  //dsTablaG.DataSet.FieldByName('DESCRIPCION_IVA_IVAGRP').AsString :=
  // dmmIVAS.unqryZonasIVA.FieldByName('DESCRIPCION_IVA_IVAGRP').AsString;
end;

procedure TfrmMtoIvas.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
    if (dsTablaG.State = dsInsert) then
      cxGrdDBTabPrinCODIGO_IVA.Options.Editing := True
    else
      cxGrdDBTabPrinCODIGO_IVA.Options.Editing := False;
end;

initialization
  RegistrarPantalla(TfrmMtoIvas);
  ForceReferenceToClass(TfrmMtoIvas);

end.

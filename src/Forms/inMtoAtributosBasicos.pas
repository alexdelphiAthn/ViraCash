{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAtributosBasicos                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento del catálogo de atributos básicos (fza_atributos_basicos).  }
{    Cada fila representa un "estándar" reusable (AZUL CIELO con HEX, talla    }
{    XL = 47 cm, calzado EU42 = 26.5 cm…). Los valores concretos               }
{    (fza_atributos_valores) y los conjuntos del artículo apuntan a estas      }
{    filas para dar contexto físico al valor.                                  }
{******************************************************************************}
unit inMtoAtributosBasicos;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoGen, dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAtributosBasicos,
  cxCheckBox, cxSpinEdit, dxScrollbarAnnotations, dxCore,
  cxMaskEdit, cxDBEdit, cxDBLookupComboBox, cxDBLookupEdit,
  cxLookupEdit, cxDropDownEdit, cxButtonEdit, cxCurrencyEdit;

type
  TfrmMtoAtributosBasicos = class(TfrmMtoGen)
    cxGrdDBTabPrinID_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinID_VA_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinHEX_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinVALOR_NUM_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinUNIDAD_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinORDEN_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_ATB: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblIdAtb: TcxLabel;
    txtID_ATB: TcxDBTextEdit;
    lblIdVaAtb: TcxLabel;
    cbbID_VA_ATB: TcxDBLookupComboBox;
    lblCodigo: TcxLabel;
    txtCODIGO_ATB: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE_ATB: TcxDBTextEdit;
    lblDescripcion: TcxLabel;
    txtDESCRIPCION_ATB: TcxDBTextEdit;
    lblHex: TcxLabel;
    btnHEX_ATB: TcxDBButtonEdit;
    lblValor: TcxLabel;
    txtVALOR_NUM_ATB: TcxDBTextEdit;
    lblUnidad: TcxLabel;
    txtUNIDAD_ATB: TcxDBTextEdit;
    lblOrden: TcxLabel;
    spnORDEN_ATB: TcxDBSpinEdit;
    chkESACTIVO_ATB: TcxDBCheckBox;
    procedure btnHEX_ATBPropertiesButtonClick(Sender: TObject;
                                              AButtonIndex: Integer);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure cxGrdDBTabPrinHEX_ATBCustomDrawCell(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    dmmAtributosBasicos: TdmAtributosBasicos;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoAtributosBasicos.CrearTablaPrincipal;
begin
  inherited;
  dmmAtributosBasicos := tdmDataModule as TdmAtributosBasicos;
  cbbID_VA_ATB.Properties.ListSource :=
                                       dmmAtributosBasicos.dsAtributosLookup;
  (cxGrdDBTabPrinID_VA_ATB.Properties as TcxLookupComboBoxProperties).ListSource
                                    := dmmAtributosBasicos.dsAtributosLookup;
  pkFieldName := 'ID_ATB';
end;

procedure TfrmMtoAtributosBasicos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoAtributosBasicos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // ID_ATB es AUTO_INCREMENT: no se edita.
  cxGrdDBTabPrinID_ATB.Options.Editing := False;
  txtID_ATB.Properties.ReadOnly := True;
end;

procedure TfrmMtoAtributosBasicos.btnHEX_ATBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Dlg: TColorDialog;
  LHex: string;
  fld : TField;
begin
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active then
  begin
    fld := dsTablaG.DataSet.FindField('HEX_ATB');
    if fld <> nil then
    begin
      Dlg := TColorDialog.Create(Self);
      try
        Dlg.Options := [cdFullOpen, cdAnyColor];
        LHex := Trim(fld.AsString);
        if (Length(LHex) = 7) and (LHex[1] = '#') then
        try
          Dlg.Color := RGB(
            StrToInt('$' + Copy(LHex, 2, 2)),
            StrToInt('$' + Copy(LHex, 4, 2)),
            StrToInt('$' + Copy(LHex, 6, 2)));
        except
          Dlg.Color := clWhite;
        end
        else
          Dlg.Color := clWhite;
        if Dlg.Execute then
        begin
          if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
            dsTablaG.DataSet.Edit;
          fld.AsString := Format(
            '#%.2X%.2X%.2X',
            [GetRValue(Dlg.Color), GetGValue(Dlg.Color),
             GetBValue(Dlg.Color)]);
        end;
      finally
        FreeAndNil(Dlg);
      end;
    end;
  end;
end;

procedure TfrmMtoAtributosBasicos.cxGrdDBTabPrinHEX_ATBCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  LHex: string;
  LR, LG, LB: Integer;
  LRect: TRect;
  LBrillo: Double;
  bColorValido: Boolean;
begin
  ADone := False;
  LR := 0;
  LG := 0;
  LB := 0;
  bColorValido := AViewInfo <> nil;
  if bColorValido then
  begin
    LHex := Trim(
      AViewInfo.GridRecord.DisplayTexts[AViewInfo.Item.Index]);
    bColorValido := (Length(LHex) = 7) and (LHex[1] = '#');
  end;
  if bColorValido then
    try
      LR := StrToInt('$' + Copy(LHex, 2, 2));
      LG := StrToInt('$' + Copy(LHex, 4, 2));
      LB := StrToInt('$' + Copy(LHex, 6, 2));
    except
      bColorValido := False;
    end;
  if bColorValido then
  begin
    ACanvas.FillRect(AViewInfo.Bounds, AViewInfo.Params.Color);
    LRect := AViewInfo.Bounds;
    InflateRect(LRect, -3, -3);
    ACanvas.Brush.Color := RGB(LR, LG, LB);
    ACanvas.Pen.Color := clBlack;
    ACanvas.Rectangle(LRect);
    LBrillo := LR * 0.299 + LG * 0.587 + LB * 0.114;
    ACanvas.Brush.Style := bsClear;
    if LBrillo < 128 then
      ACanvas.Font.Color := clWhite
    else
      ACanvas.Font.Color := clBlack;
    ACanvas.DrawText(LHex, LRect, cxAlignCenter or cxAlignVCenter);
    ADone := True;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoAtributosBasicos);
  ForceReferenceToClass(TfrmMtoAtributosBasicos);
end.

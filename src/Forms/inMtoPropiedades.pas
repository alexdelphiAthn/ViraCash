{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPropiedades                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de propiedades de articulo.                                 }
{    Define las propiedades configurables aplicables a articulos.              }
{******************************************************************************}
unit inMtoPropiedades;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Actions, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPropiedades,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxDBEdit, cxDropDownEdit, cxSplitter, cxMaskEdit;

type
  TfrmMtoPropiedades = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTIPO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIVEL: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNUMARTUSOS: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;

    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE: TcxDBTextEdit;
    lblTipo: TcxLabel;
    cbbTIPO: TcxDBComboBox;
    chkACTIVO: TcxDBCheckBox;
    lblNivel: TcxLabel;
    cbbNIVEL: TcxDBComboBox;
    splFicha: TcxSplitter;
    pnlBottomFicha: TPanel;
    pcPestana: TcxPageControl;

    tsValores: TcxTabSheet;
    cxgrdValores: TcxGrid;
    tvValores: TcxGridDBTableView;
    lvValores: TcxGridLevel;
    tvValoresPV: TcxGridDBColumn;
    tvValoresDESCRIPCION_PV: TcxGridDBColumn;
    tvValoresESACTIVO_PV: TcxGridDBColumn;
    tvValoresINSTANTEALTA: TcxGridDBColumn;
    tvValoresUSUARIOALTA: TcxGridDBColumn;

    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    lvArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    tvArticulosVALOR_LISTA: TcxGridDBColumn;
    tvArticulosVALOR_LIBRE_ARTPROP: TcxGridDBColumn;
    tvArticulosINSTANTEALTA: TcxGridDBColumn;
    tvArticulosUSUARIOALTA: TcxGridDBColumn;

    alPropiedades: TActionList;
    actGoArticulo: TAction;

    procedure dsTablaGStateChange(Sender: TObject);
    procedure actGoArticuloExecute(Sender: TObject);
    procedure actGoArticuloUpdate(Sender: TObject);
    procedure unqryValoresBeforePost(DataSet: TDataSet);
  private
    dmmPropiedades: TdmPropiedades;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibWin, inLibShowMto, inLibFotos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPropiedades }

// El articulo activo es el de la rejilla de articulos de la propiedad
// (tvArticulos, CODIGO_ART_ART).
procedure TfrmMtoPropiedades.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvArticulos.DataController.DataSource) then
  begin
    ds := tvArticulos.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoPropiedades.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmPropiedades) then
    Result := [dsTablaG, dmmPropiedades.dsArticulos]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoPropiedades.CrearTablaPrincipal;
begin
  inherited;
  dmmPropiedades := tdmDataModule as TdmPropiedades;
  pkFieldName := 'CODIGO_PROP_ARTPROP';

  dmmPropiedades.unqryArticulos.Connection := ConexionPrincipal;
  dmmPropiedades.unqryValores.Connection   := ConexionPrincipal;
  if not dmmPropiedades.unqryArticulos.Active then
    dmmPropiedades.unqryArticulos.Open;
  if not dmmPropiedades.unqryValores.Active then
    dmmPropiedades.unqryValores.Open;

  tvArticulos.DataController.DataSource := dmmPropiedades.dsArticulos;
  tvValores.DataController.DataSource   := dmmPropiedades.dsValores;
  dmmPropiedades.unqryValores.BeforePost := unqryValoresBeforePost;
end;

procedure TfrmMtoPropiedades.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoPropiedades.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
  begin
    txtCODIGO.Properties.ReadOnly := False;
    // Nivel por defecto = ARTICULO (codigo de articulo) en altas nuevas.
    if Assigned(dsTablaG.DataSet) and
       (dsTablaG.DataSet.FindField('NIVEL_PROP') <> nil) and
       dsTablaG.DataSet.FieldByName('NIVEL_PROP').IsNull then
      dsTablaG.DataSet.FieldByName('NIVEL_PROP').AsString := 'ARTICULO';
  end
  else
    txtCODIGO.Properties.ReadOnly := True;
end;

procedure TfrmMtoPropiedades.unqryValoresBeforePost(DataSet: TDataSet);
begin
  if (DataSet.State = dsInsert) and
     Assigned(dmmPropiedades) and
     dmmPropiedades.unqryTablaG.Active and
     not dmmPropiedades.unqryTablaG.IsEmpty then
  begin
    if DataSet.FieldByName('ID_PROP_PV').IsNull then
      DataSet.FieldByName('ID_PROP_PV').AsString :=
        dmmPropiedades.unqryTablaG.FieldByName('CODIGO_PROP_ARTPROP').AsString;
    if (DataSet.FindField('ESACTIVO_PV') <> nil) and
       DataSet.FieldByName('ESACTIVO_PV').IsNull then
      DataSet.FieldByName('ESACTIVO_PV').AsString := 'S';
  end;
  ActualizarAuditoria(DataSet);
end;

procedure TfrmMtoPropiedades.actGoArticuloUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    (pcPantalla.ActivePage = tsFicha) and
    (pcPestana.ActivePage = tsArticulos) and
    Assigned(dmmPropiedades) and
    Assigned(dmmPropiedades.unqryArticulos) and
    dmmPropiedades.unqryArticulos.Active and
    not dmmPropiedades.unqryArticulos.IsEmpty;
end;

procedure TfrmMtoPropiedades.actGoArticuloExecute(Sender: TObject);
var
  sCodArt: string;
begin
  if (dmmPropiedades <> nil) and
     (dmmPropiedades.unqryArticulos <> nil) and
     dmmPropiedades.unqryArticulos.Active and
     not dmmPropiedades.unqryArticulos.IsEmpty then
  begin
    sCodArt :=
      dmmPropiedades.unqryArticulos.FieldByName('CODIGO_ART_ART').AsString;
    if sCodArt <> '' then
      ShowMto(Self.Owner, 'Articulos', sCodArt);
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoPropiedades);
  ForceReferenceToClass(TfrmMtoPropiedades);
end.

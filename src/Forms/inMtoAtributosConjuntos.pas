{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAtributosConjuntos                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de conjuntos de atributos.                                  }
{    Agrupa variaciones y sus valores para usarlos en articulos.               }
{******************************************************************************}
unit inMtoAtributosConjuntos;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAtributosConjuntos,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxSplitter, cxMaskEdit, cxDBEdit, cxDBLookupComboBox,
  cxDBLookupEdit, cxLookupEdit, cxDropDownEdit,
  System.Actions, Vcl.ActnList;

type
  TfrmMtoAtributosConjuntos = class(TfrmMtoGen)
    cxGrdDBTabPrinID_AC: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn;
    cxGrdDBTabPrinID_VA_AC: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblNombre: TcxLabel;
    txtNOMBRE_AC: TcxDBTextEdit;
    chkESACTIVO_AC: TcxDBCheckBox;
    lblIdVa: TcxLabel;
    cbbID_VA_AC: TcxDBLookupComboBox;
    lblIdAc: TcxLabel;
    txtID_AC: TcxDBTextEdit;
    lblIdVaDesc: TcxLabel;
    splSplitterFicha: TcxSplitter;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsValores: TcxTabSheet;
    cxgrdValores: TcxGrid;
    tvValores: TcxGridDBTableView;
    cxgrdlvlValores: TcxGridLevel;
    tvValoresID_AC_ACD: TcxGridDBColumn;
    tvValoresAV: TcxGridDBColumn;
    tvValoresORDEN_ACD: TcxGridDBColumn;
    tvValoresID_ATB_ACD: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ART: TcxGridDBColumn;
    tvArticulosESACTIVO_ART: TcxGridDBColumn;
    tvArticulosCODIGO_FAM_ART: TcxGridDBColumn;
    tvArticulosNOMBRE_FAM_FAM: TcxGridDBColumn;
    alConjuntos: TActionList;
    actArticulo: TAction;
    tsAuditoria: TcxTabSheet;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    procedure dsTablaGStateChange(Sender: TObject);
    procedure actArticuloExecute(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
  private
    dmmAtributosConjuntos: TdmAtributosConjuntos;
    procedure ActualizarDescripciones;
    procedure dsConjuntoDetalleStateChange(Sender: TObject);
    procedure EditarValorNuevo;
    procedure tvValoresNavigatorButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibBotonesDetalle,
  cxDataUtils, inLibWin, inLibShowMto, inLibFotos, inLibMsgArticulos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAtributosConjuntos }

// El articulo activo es el de la rejilla de articulos del conjunto
// (tvArticulos, CODIGO_ART_ART).
procedure TfrmMtoAtributosConjuntos.ResolverArtSkuActivo(out ACodArt,
                                                             ACodSku: string);
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

function TfrmMtoAtributosConjuntos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmAtributosConjuntos) then
    Result := [dsTablaG, dmmAtributosConjuntos.dsArticulosConjunto]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoAtributosConjuntos.CrearTablaPrincipal;
begin
  inherited;
  dmmAtributosConjuntos := tdmDataModule as TdmAtributosConjuntos;
  tvValores.DataController.DataSource   :=
                                        dmmAtributosConjuntos.dsConjuntoDetalle;
  tvArticulos.DataController.DataSource :=
                                      dmmAtributosConjuntos.dsArticulosConjunto;
  (tvValoresID_ATB_ACD.Properties as TcxLookupComboBoxProperties).ListSource :=
                                   dmmAtributosConjuntos
                                   .dsAtributosBasicosLookup;
  // FZ-ISSUE-449: la colección depende solo de su atributo; el tipo de
  // variación ya no se elige ni se muestra.
  cbbID_VA_AC.Properties.ListSource :=
                                       dmmAtributosConjuntos.dsAtributosLookup;
  (cxGrdDBTabPrinID_VA_AC.Properties as TcxLookupComboBoxProperties).ListSource
                                    := dmmAtributosConjuntos.dsAtributosLookup;
  pkFieldName := 'ID_AC';
  dmmAtributosConjuntos.dsConjuntoDetalle.OnStateChange :=
                                                   dsConjuntoDetalleStateChange;
  // La consulta aplica el orden numérico solo a colecciones numéricas.
  tvValoresORDEN_ACD.SortOrder := soNone;
  tvValores.Navigator.Buttons.OnButtonClick := tvValoresNavigatorButtonClick;
  ActualizarDescripciones;
  // Botones «Añadir» y «Borrar» sobre las rejillas de detalle, además
  // de los «+» y «-» del navegador.
  AnadirBotonesDetalle(tvValores);
end;

procedure TfrmMtoAtributosConjuntos.tvValoresNavigatorButtonClick(
  Sender: TObject; AButtonIndex: Integer; var ADone: Boolean);
begin
  if AButtonIndex = NBDI_INSERT then
  begin
    ADone := True;
    tvValores.DataController.Append;
    // La fila nueva queda ya en edición en Valor, sin esperar a la cola
    // (FZ-ISSUE-625).
    EditarValorNuevo;
  end
  // Un valor que usan SKU no se puede quitar: se avisa antes de pedir
  // confirmación, no después.
  else if AButtonIndex = NBDI_DELETE then
    dmmAtributosConjuntos.ComprobarValorSinUso;
end;

// Al insertar un valor el cursor va a la columna Valor, ya en edición.
procedure TfrmMtoAtributosConjuntos.dsConjuntoDetalleStateChange(
  Sender: TObject);
begin
  if dmmAtributosConjuntos.dsConjuntoDetalle.State = dsInsert then
    TThread.ForceQueue(nil, EditarValorNuevo);
end;

// El data module puede sobrevivir al form (tareas de fondo vivas): se le
// quita el evento y se descarta el foco pendiente antes de liberar nada.
destructor TfrmMtoAtributosConjuntos.Destroy;
begin
  TThread.RemoveQueuedEvents(nil, EditarValorNuevo);
  if Assigned(dmmAtributosConjuntos) then
    dmmAtributosConjuntos.dsConjuntoDetalle.OnStateChange := nil;
  dmmAtributosConjuntos := nil;
  inherited;
end;

procedure TfrmMtoAtributosConjuntos.EditarValorNuevo;
begin
  if (csDestroying in ComponentState) or
     not Assigned(dmmAtributosConjuntos) or
     (dmmAtributosConjuntos.dsConjuntoDetalle.State <> dsInsert) then
    Exit;
  if cxgrdValores.CanFocus then
    cxgrdValores.SetFocus;
  tvValores.Controller.FocusedColumn := tvValoresAV;
  if tvValores.Controller.EditingController <> nil then
    tvValores.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoAtributosConjuntos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGDataChange(Sender: TObject;
                                                                 Field: TField);
begin
  if (Field = nil) or
     (Field.FieldName = 'ID_VA_AC') then
    ActualizarDescripciones;
end;

procedure TfrmMtoAtributosConjuntos.ActualizarDescripciones;
var
  LIdVa: string;
  LValor: Variant;
begin
  if (dmmAtributosConjuntos <> nil) and (dsTablaG <> nil) and
     (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     dmmAtributosConjuntos.unqryAtributosLookup.Active then
  begin
    // Nombre del atributo en los tipos de variación que lo usan
    // («Talla / Medida»).
    lblIdVaDesc.Caption := '';
    LIdVa := dsTablaG.DataSet.FieldByName('ID_VA_AC').AsString;
    dmmAtributosConjuntos.FiltrarAtributosBasicos(LIdVa);
    if LIdVa <> '' then
    begin
      LValor := dmmAtributosConjuntos.unqryAtributosLookup.Lookup(
        'ID_ATB_VA', LIdVa, 'NOMBRE_VA');
      if not VarIsNull(LValor) then
        lblIdVaDesc.Caption := VarToStr(LValor);
    end;
  end;
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // ID_AC es AUTO_INCREMENT, no editable.
  cxGrdDBTabPrinID_AC.Options.Editing := False;
end;

procedure TfrmMtoAtributosConjuntos.actArticuloExecute(Sender: TObject);
begin
  inherited;
  if ((pcDetail.ActivePage = tsArticulos) and
      (not dmmAtributosConjuntos.dsArticulosConjunto.DataSet.FieldByName(
        'CODIGO_ART_ART').IsNull)) then
    ShowMto(Self.Owner, 'Articulos',
      dmmAtributosConjuntos.dsArticulosConjunto.DataSet.FieldByName(
        'CODIGO_ART_ART').AsString)
  else
    ShowMto(Self.Owner, 'Articulos');
end;

initialization
  RegistrarPantalla(TfrmMtoAtributosConjuntos);
  ForceReferenceToClass(TfrmMtoAtributosConjuntos);
end.

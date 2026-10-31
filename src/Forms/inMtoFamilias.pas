{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFamilias                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de familias de articulos.                                   }
{    Jerarquia de familias y subfamilias para clasificar articulos.            }
{******************************************************************************}
unit inMtoFamilias;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
   cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataFamilias,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, JvComponentBase, JvEnterTab, cxDBLabel, dxShellDialogs,
  cxGroupBox, cxImageComboBox;

type
  TfrmMtoFamilias = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlDetailFich: TPanel;
    pcDetail: TcxPageControl;
    tsMasDatos: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlCabFich: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsOtros: TcxTabSheet;
    pnlOtros: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    lblDescripcion: TcxLabel;
    chkActivo: TcxDBCheckBox;
    cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn;
    txtCODIGO_FAMILIA: TcxDBTextEdit;
    txtNOMBRE_FAMILIA: TcxDBTextEdit;
    mDESCRIPCION_FAMILIA: TcxDBMemo;
    gbContadorArt: TcxGroupBox;
    lblTrazabilidadFamilia: TcxLabel;
    cbbTrazabilidadFamilia: TcxDBImageComboBox;
    chkEsContadorArtFam: TcxDBCheckBox;
    lblContadorArt: TcxLabel;
    spnContadorArt: TcxDBSpinEdit;
    lblPadArt: TcxLabel;
    spnPadArt: TcxDBSpinEdit;
    lblEjemploContador: TcxLabel;
    cxgrdbclmnGrdDBTabPrinACTIVO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinORDEN_FAMILIA: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    splFicha: TcxSplitter;
    cxgrdArticulosFamilias: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    tvLineasFacturacion: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlArticulosFamilias: TcxGridLevel;
    cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR_PRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosRAZON_SOCIAL_PROVEEDOR_PRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosESIMP_INCL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn;
    lblOrden: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevaFamilia: TcxButton;
    dbcGrdDBTabPrinESDEFAULT_FAMILIA: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_SUBFAMILIA: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_SUBFAMILIA: TcxGridDBColumn;
    cbbFamilia: TcxDBLookupComboBox;
    lblFamiliaPadre: TcxLabel;
    chkDEFAULT_FAMILIA: TcxDBCheckBox;
    alFamilias: TActionList;
    actArticulo: TAction;
    actProveedores: TAction;
    actTarifas: TAction;
    cxTabSheet1: TcxTabSheet;
    cxGrid1: TcxGrid;
    tvAtributos: TcxGridDBTableView;
    cxGridDBTableView2: TcxGridDBTableView;
    cxGridDBColumn11: TcxGridDBColumn;
    cxGridDBColumn12: TcxGridDBColumn;
    cxGridDBColumn13: TcxGridDBColumn;
    cxGridDBColumn14: TcxGridDBColumn;
    cxGridDBColumn15: TcxGridDBColumn;
    cxGridDBColumn16: TcxGridDBColumn;
    cxGridDBColumn17: TcxGridDBColumn;
    cxGridDBColumn18: TcxGridDBColumn;
    cxGridDBColumn19: TcxGridDBColumn;
    cxGridDBColumn20: TcxGridDBColumn;
    cxGridDBColumn21: TcxGridDBColumn;
    cxGridLevel1: TcxGridLevel;
    tvAtributosCODIGO_FAMILIA: TcxGridDBColumn;
    tvAtributosCODIGO_PROPIEDAD: TcxGridDBColumn;
    tvAtributosNOMBRE_PROPIEDAD: TcxGridDBColumn;
    tvAtributosES_REQUERIDO: TcxGridDBColumn;
    tvAtributosORDEN_MOSTRAR: TcxGridDBColumn;
    procedure btnGrabarClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure actTarifasExecute(Sender: TObject);
    procedure btnNuevaFamiliaClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    procedure CambiarEjemploContador(Sender: TObject);
  public
    procedure AplicarTraduccionActual; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  private
    dmmFamilias : TdmFamilias;
    // Propiedades heredadas de las familias superiores, solo lectura.
    FMemoHeredadas: TcxMemo;
    procedure ConfigurarTrazabilidadFamilia;
    procedure ActualizarEjemploContador;
    procedure CrearPropiedadesHeredadas;
    procedure MostrarPropiedadesHeredadas;
  end;

const
  pkFieldName = 'CODIGO_FAM_FAM';

implementation

uses
  inLibBotonesDetalle,
  inLibWin,
  inLibFotos,
  inLibUser,
  inLibDevExp,
  inLibShowMto, inLibTrazabilidad, inLibTrazabilidadAlta,
  inLibMsgTrazabilidad, inLibMsgCompras, System.Math,
  inLibMsgArticulos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// El articulo activo es el de la rejilla de articulos de la familia
// (tvArticulos, CODIGO_ART_ART).
procedure TfrmMtoFamilias.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
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

function TfrmMtoFamilias.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmFamilias) then
    Result := [dsTablaG, dmmFamilias.dsArticulosFamilias]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoFamilias.actArticulosExecute(Sender: TObject);
begin
  inherited;
  //Control + A --Artículos
  if ((pcDetail.ActivePage = tsArticulos) and
      (not(dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
        'CODIGO_ART_ART').isNull))) then
    ShowMto(Self.Owner,
            'Articulos',
            dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
              'CODIGO_ART_ART').AsString)
  else
    ShowMto(Self.Owner,
            'Articulos' );
end;

procedure TfrmMtoFamilias.actProveedoresExecute(Sender: TObject);
begin
  inherited;
  // Control + P-> Proveedores
  if (
      (pcDetail.ActivePage = tsArticulos) and
      (not(dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
        'CODIGO_PROVEEDOR_PRINCIPAL').isNull))) then
    ShowMto (Self.Owner,
             'Proveedores',
             dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
               'CODIGO_PROVEEDOR_PRINCIPAL').AsString)
  else
    ShowMto(Self.Owner,
            'Proveedores');
end;

procedure TfrmMtoFamilias.actTarifasExecute(Sender: TObject);
begin
  inherited;
  //Control + T -> Tarifas
  if (
      (pcDetail.ActivePage = tsArticulos) and
      (not(dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
        'CODIGO_TAR_ARTTAR').isNull))) then
    ShowMto(Self.Owner,
            'Tarifas',
            dmmFamilias.dsArticulosFamilias.DataSet.FieldByName(
              'CODIGO_TAR_ARTTAR').AsString)
  else
    ShowMto(Self.Owner,
            'Tarifas');
end;

procedure TfrmMtoFamilias.btnGrabarClick(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoFamilias.btnNuevaFamiliaClick(Sender: TObject);
begin
  inherited;
  if ( (dmmFamilias.unqryTablaG.State = dsInsert) or
       (dmmFamilias.unqryTablaG.State = dsEdit)) then
  begin
    dmmFamilias.unqryTablaG.Post;
  end;
  dmmFamilias.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
//  tsFicha.SetFocus;
  ResetForm;
//  txtNOMBRE_FAMILIA.SetFocus;
end;

procedure TfrmMtoFamilias.ConfigurarTrazabilidadFamilia;
var
  oItem: TcxImageComboBoxItem;
  rActivacion: TActivacionTrazabilidad;
  sTipo: string;
begin
  rActivacion := TActivacionTrazabilidad.Apagada;
  if Assigned(ParametrosApp) then
    rActivacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  lblTrazabilidadFamilia.Caption := SCaptionTrazabilidadFamilia;
  cbbTrazabilidadFamilia.Visible :=
    rActivacion.Lotes or rActivacion.Series;
  lblTrazabilidadFamilia.Visible := cbbTrazabilidadFamilia.Visible;
  cbbTrazabilidadFamilia.Properties.Items.Clear;
  for sTipo in TiposTrazabilidadFamiliaDisponibles(rActivacion) do
  begin
    oItem := cbbTrazabilidadFamilia.Properties.Items.Add;
    oItem.Value := sTipo;
    if sTipo = TRAZABILIDAD_FAMILIA_LOTE then
      oItem.Description := SCaptionFamiliaLote
    else if sTipo = TRAZABILIDAD_FAMILIA_LOTE_CADUCIDAD then
      oItem.Description := SCaptionFamiliaLoteCaducidad
    else if sTipo = TRAZABILIDAD_FAMILIA_SERIE then
      oItem.Description := SCaptionFamiliaSerie
    else
      oItem.Description := SCaptionModoNinguna;
  end;
end;

procedure TfrmMtoFamilias.CrearTablaPrincipal;
begin
  inherited;
  dmmFamilias := tdmDataModule as tdmFamilias;
  ConfigurarTrazabilidadFamilia;
  tvArticulos.DataController.DataSource := dmmFamilias.dsArticulosFamilias;
  cbbFamilia.Properties.ListSource := dmmFamilias.dsSubfamilias;
  TcxLookupComboBoxProperties(tvAtributosCODIGO_PROPIEDAD.Properties).ListSource
                                                   := dmmFamilias.dsPropiedades;
  tvAtributos.DataController.DataSource := dmmFamilias.dsFamiliasAtributos;
  ResetForm;
  ActualizarEjemploContador;
  pkFieldName := 'CODIGO_FAM_FAM';
  // Botones «Añadir» y «Borrar» sobre las rejillas de detalle, además
  // de los «+» y «-» del navegador.
  AnadirBotonesDetalle(tvAtributos);
  CrearPropiedadesHeredadas;
end;

procedure TfrmMtoFamilias.CrearPropiedadesHeredadas;
begin
  FMemoHeredadas := TcxMemo.Create(Self);
  FMemoHeredadas.Parent := cxTabSheet1;
  FMemoHeredadas.Align := alBottom;
  FMemoHeredadas.Height := ScaleValue(96);
  FMemoHeredadas.Properties.ReadOnly := True;
  FMemoHeredadas.Properties.ScrollBars := ssVertical;
  FMemoHeredadas.TabStop := False;
  MostrarPropiedadesHeredadas;
end;

// Las propiedades de la familia padre y superiores valen también aquí:
// se enseñan debajo de las propias, sin poder editarlas desde esta familia.
procedure TfrmMtoFamilias.MostrarPropiedadesHeredadas;
var
  Propiedad: TPropiedadHeredadaFamilia;
  oLineas: TStringList;
  sObligatoria: string;
begin
  if Assigned(FMemoHeredadas) and Assigned(dmmFamilias) and
     dsTablaG.DataSet.Active then
  begin
    oLineas := TStringList.Create;
    try
      for Propiedad in dmmFamilias.PropiedadesHeredadas(
        dsTablaG.DataSet.FieldByName('CODIGO_FAM_FAM').AsString) do
      begin
        sObligatoria := '';
        if Propiedad.Obligatoria then
          sObligatoria := SSufijoPropiedadHeredadaObligatoria;
        oLineas.Add(Format(SLineaPropiedadHeredadaFamilia,
          [Propiedad.Codigo, Propiedad.Nombre, Propiedad.Familia,
           sObligatoria]));
      end;
      if oLineas.Count = 0 then
        oLineas.Add(SSinPropiedadesHeredadasFamilia);
      oLineas.Insert(0, STituloPropiedadesHeredadasFamilia);
      FMemoHeredadas.Lines.Text := oLineas.Text;
    finally
      oLineas.Free;
    end;
  end;
end;

procedure TfrmMtoFamilias.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    txtCODIGO_FAMILIA.Enabled := True
  else
  begin
    txtCODIGO_FAMILIA.Enabled := False;
  end;
end;

procedure TfrmMtoFamilias.ActualizarEjemploContador;
var
  Codigo, Numero: string;
  Contador: Int64;
  Digitos: Integer;
begin
  if Assigned(txtCODIGO_FAMILIA) and Assigned(spnContadorArt) and
     Assigned(spnPadArt) and Assigned(lblEjemploContador) then
  begin
    Codigo := Trim(VarToStr(txtCODIGO_FAMILIA.EditValue));
    Contador := StrToInt64Def(VarToStr(spnContadorArt.EditValue), 0);
    Digitos := StrToIntDef(VarToStr(spnPadArt.EditValue), 5);
    if Digitos < 1 then
      Digitos := 5;
    Digitos := Min(Digitos, 12);
    Numero := IntToStr(Contador + 1);
    if Length(Numero) < Digitos then
      Numero := StringOfChar('0', Digitos - Length(Numero)) + Numero;
    if Codigo = '' then
      lblEjemploContador.Caption := ''
    else
      lblEjemploContador.Caption := Format(SCaptionProximoCodigoFamilia,
        [Codigo + Numero]);
  end;
end;

procedure TfrmMtoFamilias.AplicarTraduccionActual;
begin
  inherited;
  ActualizarEjemploContador;
end;

procedure TfrmMtoFamilias.dsTablaGDataChange(Sender: TObject;
  Field: TField);
begin
  ActualizarEjemploContador;
  // Al cambiar de familia o de familia padre.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PADRE_FAM') then
    MostrarPropiedadesHeredadas;
end;

procedure TfrmMtoFamilias.CambiarEjemploContador(Sender: TObject);
begin
  ActualizarEjemploContador;
end;

procedure TfrmMtoFamilias.ResetForm;
begin
  inherited;
  //pcDetail.ActivePage := tsMasDatos;
end;

initialization
  RegistrarPantalla(TfrmMtoFamilias);
  ForceReferenceToClass(TfrmMtoFamilias);
end.

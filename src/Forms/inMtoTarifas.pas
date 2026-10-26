{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifas                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de tarifas de precios.                                      }
{    Define tarifas aplicables a articulos por cliente o zona.                 }
{******************************************************************************}
unit inMtoTarifas;

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
  dxBevel, cxDBNavigator, UniDataTarifas,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan,
  cxSplitter, JvComponentBase, JvEnterTab, dxShellDialogs, System.UITypes,
  Vcl.CheckLst, inLibCargaMasivaArticulosPersistenciaIntf,
  inLibTarifasDescuentoCondicionesPersistenciaIntf, inLibPermisosIntf;

type
  TfrmMtoTarifas = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
    pcPestana: TcxPageControl;
    tsArticulos: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlInnerHeader: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsOtros: TcxTabSheet;
    pnlOtrosDatos: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    chkActivo: TcxDBCheckBox;
    txtNOMBRE_TARIFA: TcxDBTextEdit;
    txtCODIGO_TARIFA: TcxDBTextEdit;
    cxgrdbclmnGrdDBTabPrinCODIGO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxdbchckbxACTIVO_TARIFA: TcxDBCheckBox;
    pnlBotonera: TPanel;
    btnIraArticulo: TcxButton;
    btnAddBlock: TcxButton;
    splHorizontal: TcxSplitter;
    pnlArticulos: TPanel;
    cxgrdArticulosTarifas: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdbclmnArticulosACTIVO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_ARTICULO_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPOIVA_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_DESDE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_HASTA_TARIFA: TcxGridDBColumn;
    cxgrdbclmnArticulosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIOFINAL: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn;
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
    cxgrdlvlArticulosTarifas: TcxGridLevel;
    splVertical: TcxSplitter;
    splGeneral: TcxSplitter;
    alTarifas: TActionList;
    actArticulos: TAction;
    actFamilias: TAction;
    actProveedores: TAction;
    tvArticulosCODIGO_UNIDAD_TARIFA: TcxGridDBColumn;
    tvArticulosCODIGO_TARIFA: TcxGridDBColumn;
    tvArticulosNOMBRE_TARIFA: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA_SKU: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA_PADRE: TcxGridDBColumn;
    tvArticulosCODIGO_UNICO_TARIFA: TcxGridDBColumn;
    tvArticulosORIGEN_PRECIO: TcxGridDBColumn;
    tvArticulosPRECIOSALIDA_TARIFA: TcxGridDBColumn;
    tvArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn;
    tvArticulosPRECIO_DTO_TARIFA: TcxGridDBColumn;
    tvArticulosPORCEN_DTO_TARIFA: TcxGridDBColumn;
    tvArticulosESIMP_INCL_TARIFA: TcxGridDBColumn;
    tvArticulosESVARIACION_ARTICULO: TcxGridDBColumn;
    tvArticulosTIPO_IVA_ARTICULO: TcxGridDBColumn;
    tvArticulosTIENE_SKU: TcxGridDBColumn;
    tvArticulosESACTIVO_SKU: TcxGridDBColumn;
    tvArticulosDESCRIPCION_SKU: TcxGridDBColumn;
    tvArticulosNUM_ATRIBUTOS_REQ: TcxGridDBColumn;
    dteFechaDtoDesde: TcxDBDateEdit;
    dteFechaDtoHasta: TcxDBDateEdit;
    lblDtoDesde: TcxLabel;
    lblDtoHasta: TcxLabel;
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actFamiliasExecute(Sender: TObject);
    procedure actProveedoresExecute(Sender: TObject);
    procedure btnAddBlockClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  private
    FBtnSesionesCambios: TcxButton;
    FBtnEditarDescuento: TcxButton;
    FCargaMasiva: TServiciosCargaMasivaArticulos;
    FRepositorioCondicionesDto:
      IRepositorioCondicionesDescuentoTarifa;
    FTabCondicionDto: TcxTabSheet;
    FCmbModoCondicionDto: TcxComboBox;
    FCmbPropiedadCondicionDto: TcxComboBox;
    FLstValoresCondicionDto: TCheckListBox;
    FLblPropiedadCondicionDto: TcxLabel;
    FLblValoresCondicionDto: TcxLabel;
    FLblAyudaCondicionDto: TcxLabel;
    FBtnGuardarCondicionDto: TcxButton;
    FPropiedadesCondicionDto: TPropiedadesListaDescuentoTarifa;
    FValoresCondicionDto: TValoresListaDescuentoTarifa;
    FCargandoCondicionDto: Boolean;
    FUltimaTarifaCondicionDto: string;
    FOnDataChangeTablaGAnterior: TDataChangeEvent;
    procedure CrearBotonSesionesCambios;
    procedure EditarDescuentoArticulo(Sender: TObject);
    procedure DobleClickArticulo(Sender: TObject);
    procedure btnSesionesCambiosClick(Sender: TObject);
    procedure CrearControlesCondicionDto;
    procedure InicializarControlesCondicionDto;
    procedure CargarPropiedadesCondicionDto;
    procedure CargarCondicionDto;
    procedure CargarValoresCondicionDto(
      const AIdsSeleccionados: TArray<Integer>);
    procedure ActualizarEstadoCondicionDto;
    function CodigoTarifaActual: string;
    function CodigoPropiedadCondicionDto: string;
    function RecogerCondicionDto: TCondicionDescuentoTarifa;
    procedure cmbModoCondicionDtoChange(Sender: TObject);
    procedure cmbPropiedadCondicionDtoChange(Sender: TObject);
    procedure btnGuardarCondicionDtoClick(Sender: TObject);
    procedure dsTablaGDataChangeCondicionDto(
      Sender: TObject; Field: TField);
  public
    dmmTarifas: TdmTarifas;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ACargaMasiva: TServiciosCargaMasivaArticulos); reintroduce;
      overload;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin,
  inLibShowMto,
  inLibUser,
  inLibDevExp,
  inLibFotos,
  inMtoModalAddBlockTarifa, inLibMsgArticulos,
  UniDataTarifasDescuentoCondicionesRepositorio;

{$R *.dfm}


procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoTarifas.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ACargaMasiva: TServiciosCargaMasivaArticulos);
begin
  if not Assigned(ACargaMasiva.Consultas) or
     not Assigned(ACargaMasiva.Inserciones) then
  begin
    raise EArgumentNilException.Create('ACargaMasiva');
  end;
  FCargaMasiva := ACargaMasiva;
  inherited Create(AOwner, AContexto);
end;

destructor TfrmMtoTarifas.Destroy;
begin
  FRepositorioCondicionesDto := nil;
  FCargaMasiva.Consultas := nil;
  FCargaMasiva.Inserciones := nil;
  inherited;
end;

procedure TfrmMtoTarifas.actFamiliasExecute(Sender: TObject);
begin
  inherited;  //Control + N Familias
    if (
        (pcPestana.ActivePage = tsArticulos) and
         (not(dmmTarifas.unqryArticulosTarifas.FieldByName(
           'CODIGO_FAM_ART').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Familias',
              dmmTarifas.unqryArticulosTarifas.FieldByName(
                'CODIGO_FAM_ART').AsString)
      else
        ShowMto(Self.Owner,
                'Familias');
end;

procedure TfrmMtoTarifas.actProveedoresExecute(Sender: TObject);
begin
  inherited; // Control + P Proveedores
    if (
        (pcPestana.ActivePage = tsArticulos) and
        (not(dmmTarifas.unqryArticulosTarifas.FieldByName(
          'CODIGO_PRV_PRV').IsNull))
       ) then
      ShowMto(Self.Owner,
              'Proveedores',
              dmmTarifas.unqryArticulosTarifas.FieldByName(
                'CODIGO_PRV_PRV').AsString)
      else
        ShowMto(Self.Owner,
                'Proveedores');
end;

procedure TfrmMtoTarifas.btnAddBlockClick(Sender: TObject);
var
  res        : TAddBlockTarifaResult;
  codigoTar  : string;
  bContinuar : Boolean;
begin
  inherited;
  bContinuar := (dsTablaG.DataSet <> nil) and
    not dsTablaG.DataSet.IsEmpty;
  if not bContinuar then
    ShowMessage_fza(SErrorTarifaNoSeleccionada);
  if bContinuar and (dsTablaG.State in [dsInsert, dsEdit]) then
  begin
    bContinuar := MessageDlg_fza(SPreguntaGuardarTarifaAntesContinuar,
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes;
    if bContinuar then
      dsTablaG.DataSet.Post;
  end;
  if bContinuar then
  begin
    codigoTar := dsTablaG.DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString;
    res := TfrmModalAddBlockTarifa.Ejecutar(
      Self, codigoTar, FCargaMasiva);
    if res.Aceptado then
    begin
      dmmTarifas.unqryArticulosTarifas.Close;
      dmmTarifas.unqryArticulosTarifas.Open;
    end;
  end;
end;


procedure TfrmMtoTarifas.btnIraArticuloClick(Sender: TObject);
begin
  inherited;  //CONTROL + A Articulos
    if (
        (pcPestana.ActivePage = tsArticulos) and
        (not(dmmTarifas.unqryArticulosTarifas.FieldByName(
          'CODIGO_ART_ARTTAR').Isnull))
       ) then
      ShowMto(Self.Owner,
              'Articulos',
              dmmTarifas.unqryArticulosTarifas.FieldByName(
                'CODIGO_ART_ARTTAR').AsString)
      else
        ShowMto(Self.Owner,
                'Articulos');
end;

procedure TfrmMtoTarifas.CrearTablaPrincipal;
begin
  inherited;
  dmmTarifas := tdmDataModule as TdmTarifas;
  tvArticulos.DataController.DataSource := dmmTarifas.dsArticulosTarifas;
  tvArticulos.OptionsData.Deleting := PuedeAccionMto(apmBorrar);
  tvArticulos.Navigator.Buttons.Delete.Enabled := True;
  lblInstanteAlta.Caption := SCaptionInstanteAltaServidor;
  lblInstanteModif.Caption := SCaptionInstanteModificacionServidor;
  cxdbtxtdtUSUARIOALTA.Hint := SAyudaInstantesServidor;
  cxdbtxtdtUSUARIOALTA.ShowHint := True;
  cxdbtxtdtINSTANTEALTA.Hint := SAyudaInstantesServidor;
  cxdbtxtdtINSTANTEALTA.ShowHint := True;
  tvArticulos.OnDblClick := DobleClickArticulo;
  pkFieldName := 'CODIGO_TAR_ARTTAR';
  CrearBotonSesionesCambios;
  FBtnEditarDescuento := TcxButton.Create(Self);
  FBtnEditarDescuento.Parent := pnlBotonera;
  FBtnEditarDescuento.SetBounds(btnAddBlock.Left,
    FBtnSesionesCambios.Top + FBtnSesionesCambios.Height + 8,
    FBtnSesionesCambios.Width, 30);
  FBtnEditarDescuento.Caption := SCaptionEditarDescuentoArticuloTarifa;
  FBtnEditarDescuento.OnClick := EditarDescuentoArticulo;
  FRepositorioCondicionesDto :=
    CrearRepositorioCondicionesDescuentoTarifaUniDAC(
      dmmTarifas.unqryTablaG.Connection);
  CrearControlesCondicionDto;
  CargarPropiedadesCondicionDto;
  FOnDataChangeTablaGAnterior := dsTablaG.OnDataChange;
  dsTablaG.OnDataChange := dsTablaGDataChangeCondicionDto;
  CargarCondicionDto;
end;

procedure TfrmMtoTarifas.DobleClickArticulo(Sender: TObject);
begin
  if tvArticulos.Controller.FocusedColumn = tvArticulosPORCEN_DTO_TARIFA
  then
    EditarDescuentoArticulo(Sender);
end;

procedure TfrmMtoTarifas.EditarDescuentoArticulo(Sender: TObject);
var
  Porcentaje: Double;
  Texto: string;
begin
  if PuedeAccionMto(apmModificar) and
     not dmmTarifas.unqryArticulosTarifas.IsEmpty then
  begin
    Texto := dmmTarifas.unqryArticulosTarifas.FieldByName(
      'PORCENTAJE_DTO_ARTTAR').AsString;
    if InputQuery_fza(SCaptionEditarDescuentoArticuloTarifa,
         SPreguntaPorcentajeDescuentoLoteSesionTarifa, Texto) then
    begin
      if TryStrToFloat(Trim(Texto), Porcentaje) and
         (Porcentaje >= 0) and (Porcentaje <= 100) then
        dmmTarifas.ActualizarDescuentoArticulo(Porcentaje)
      else
        ShowMessage_fza(SErrorPorcentajeDescuentoLoteSesionTarifa);
    end;
  end;
end;

procedure TfrmMtoTarifas.CrearControlesCondicionDto;
begin
  if not Assigned(FTabCondicionDto) then
    InicializarControlesCondicionDto;
end;

procedure TfrmMtoTarifas.InicializarControlesCondicionDto;
var
  oEtiqueta: TcxLabel;
begin
  FTabCondicionDto := TcxTabSheet.Create(Self);
  FTabCondicionDto.PageControl := pcPestana;
  FTabCondicionDto.Caption := SCaptionAplicacionDescuento;

  oEtiqueta := TcxLabel.Create(Self);
  oEtiqueta.Parent := FTabCondicionDto;
  oEtiqueta.SetBounds(24, 24, 145, 24);
  oEtiqueta.Caption := SCaptionAplicarDescuento;
  oEtiqueta.Transparent := True;

  FCmbModoCondicionDto := TcxComboBox.Create(Self);
  FCmbModoCondicionDto.Parent := FTabCondicionDto;
  FCmbModoCondicionDto.SetBounds(180, 20, 310, 26);
  FCmbModoCondicionDto.Properties.DropDownListStyle := lsFixedList;
  FCmbModoCondicionDto.Properties.Items.Add(SCaptionCondicionDtoTodos);
  FCmbModoCondicionDto.Properties.Items.Add(SCaptionCondicionDtoSoloSi);
  FCmbModoCondicionDto.Properties.Items.Add(SCaptionCondicionDtoExcepto);
  FCmbModoCondicionDto.ItemIndex := Ord(mcdTodos);
  FCmbModoCondicionDto.Properties.OnEditValueChanged :=
    cmbModoCondicionDtoChange;

  FLblPropiedadCondicionDto := TcxLabel.Create(Self);
  FLblPropiedadCondicionDto.Parent := FTabCondicionDto;
  FLblPropiedadCondicionDto.SetBounds(24, 68, 145, 24);
  FLblPropiedadCondicionDto.Caption := SCaptionCondicionDtoPropiedad;
  FLblPropiedadCondicionDto.Transparent := True;

  FCmbPropiedadCondicionDto := TcxComboBox.Create(Self);
  FCmbPropiedadCondicionDto.Parent := FTabCondicionDto;
  FCmbPropiedadCondicionDto.SetBounds(180, 64, 430, 26);
  FCmbPropiedadCondicionDto.Anchors := [akLeft, akTop, akRight];
  FCmbPropiedadCondicionDto.Properties.DropDownListStyle := lsFixedList;
  FCmbPropiedadCondicionDto.Properties.OnEditValueChanged :=
    cmbPropiedadCondicionDtoChange;

  FLblValoresCondicionDto := TcxLabel.Create(Self);
  FLblValoresCondicionDto.Parent := FTabCondicionDto;
  FLblValoresCondicionDto.SetBounds(24, 108, 145, 24);
  FLblValoresCondicionDto.Caption := SCaptionCondicionDtoValores;
  FLblValoresCondicionDto.Transparent := True;

  FLstValoresCondicionDto := TCheckListBox.Create(Self);
  FLstValoresCondicionDto.Parent := FTabCondicionDto;
  FLstValoresCondicionDto.SetBounds(180, 104, 430, 190);
  FLstValoresCondicionDto.Anchors :=
    [akLeft, akTop, akRight, akBottom];
  FLstValoresCondicionDto.IntegralHeight := True;

  FLblAyudaCondicionDto := TcxLabel.Create(Self);
  FLblAyudaCondicionDto.Parent := FTabCondicionDto;
  FLblAyudaCondicionDto.SetBounds(180, 306, 600, 52);
  FLblAyudaCondicionDto.Anchors := [akLeft, akRight, akBottom];
  FLblAyudaCondicionDto.AutoSize := False;
  FLblAyudaCondicionDto.Properties.WordWrap := True;
  FLblAyudaCondicionDto.Caption :=
    SAyudaCondicionDescuento;
  FLblAyudaCondicionDto.Transparent := True;

  FBtnGuardarCondicionDto := TcxButton.Create(Self);
  FBtnGuardarCondicionDto.Parent := FTabCondicionDto;
  FBtnGuardarCondicionDto.SetBounds(180, 370, 210, 34);
  FBtnGuardarCondicionDto.Anchors := [akLeft, akBottom];
  FBtnGuardarCondicionDto.Caption := SCaptionGuardarAplicacionDto;
  FBtnGuardarCondicionDto.OnClick := btnGuardarCondicionDtoClick;
end;

procedure TfrmMtoTarifas.CargarPropiedadesCondicionDto;
var
  i: Integer;
begin
  FPropiedadesCondicionDto :=
    FRepositorioCondicionesDto.ListarPropiedades;
  FCargandoCondicionDto := True;
  try
    FCmbPropiedadCondicionDto.Properties.Items.Clear;
    for i := 0 to High(FPropiedadesCondicionDto) do
      FCmbPropiedadCondicionDto.Properties.Items.Add(
        FPropiedadesCondicionDto[i].Nombre + ' (' +
        FPropiedadesCondicionDto[i].Codigo + ')');
    FCmbPropiedadCondicionDto.ItemIndex := -1;
  finally
    FCargandoCondicionDto := False;
  end;
end;

function TfrmMtoTarifas.CodigoTarifaActual: string;
begin
  Result := '';
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
    Result := Trim(dsTablaG.DataSet.FieldByName(
      'CODIGO_TAR_ARTTAR').AsString);
end;

function TfrmMtoTarifas.CodigoPropiedadCondicionDto: string;
var
  i: Integer;
begin
  Result := '';
  i := FCmbPropiedadCondicionDto.ItemIndex;
  if (i >= 0) and (i < Length(FPropiedadesCondicionDto)) then
    Result := FPropiedadesCondicionDto[i].Codigo;
end;

procedure TfrmMtoTarifas.CargarValoresCondicionDto(
  const AIdsSeleccionados: TArray<Integer>);

  function EstaSeleccionado(AId: Integer): Boolean;
  var
    j: Integer;
  begin
    Result := False;
    j := 0;
    while (j <= High(AIdsSeleccionados)) and not Result do
    begin
      Result := AIdsSeleccionados[j] = AId;
      Inc(j);
    end;
  end;

var
  i: Integer;
  sCodigoPropiedad: string;
begin
  SetLength(FValoresCondicionDto, 0);
  FLstValoresCondicionDto.Items.Clear;
  sCodigoPropiedad := CodigoPropiedadCondicionDto;
  if sCodigoPropiedad <> '' then
  begin
    FValoresCondicionDto := FRepositorioCondicionesDto.ListarValores(
      sCodigoPropiedad);
    for i := 0 to High(FValoresCondicionDto) do
    begin
      FLstValoresCondicionDto.Items.Add(FValoresCondicionDto[i].Nombre);
      FLstValoresCondicionDto.Checked[i] :=
        EstaSeleccionado(FValoresCondicionDto[i].Id);
    end;
  end;
end;

procedure TfrmMtoTarifas.CargarCondicionDto;
var
  i: Integer;
  oCondicion: TCondicionDescuentoTarifa;
  sTarifa: string;
begin
  if Assigned(FRepositorioCondicionesDto) and
     Assigned(FCmbModoCondicionDto) then
  begin
    sTarifa := CodigoTarifaActual;
    if not SameText(FUltimaTarifaCondicionDto, sTarifa) then
    begin
      FUltimaTarifaCondicionDto := sTarifa;
      oCondicion := CondicionDescuentoTodos;
      if sTarifa <> '' then
        oCondicion := FRepositorioCondicionesDto.Cargar(sTarifa);
      FCargandoCondicionDto := True;
      try
        FCmbModoCondicionDto.ItemIndex := Ord(oCondicion.Modo);
        FCmbPropiedadCondicionDto.ItemIndex := -1;
        if oCondicion.Modo <> mcdTodos then
          for i := 0 to High(FPropiedadesCondicionDto) do
            if SameText(
              FPropiedadesCondicionDto[i].Codigo,
              oCondicion.CodigoPropiedad) then
            begin
              FCmbPropiedadCondicionDto.ItemIndex := i;
              Break;
            end;
        CargarValoresCondicionDto(oCondicion.IdsValores);
      finally
        FCargandoCondicionDto := False;
      end;
    end;
    ActualizarEstadoCondicionDto;
  end;
end;

procedure TfrmMtoTarifas.ActualizarEstadoCondicionDto;
var
  bCondicional: Boolean;
  bHayTarifa: Boolean;
  bPuedeEditar: Boolean;
begin
  if Assigned(FCmbModoCondicionDto) then
  begin
    bHayTarifa := CodigoTarifaActual <> '';
    bPuedeEditar := bHayTarifa and
      Assigned(dsTablaG.DataSet) and
      (dsTablaG.State = dsBrowse) and
      PuedeAccionMto(apmModificar);
    bCondicional := FCmbModoCondicionDto.ItemIndex in
      [Ord(mcdSoloSi), Ord(mcdTodosExcepto)];
    FCmbModoCondicionDto.Enabled := bPuedeEditar;
    FCmbPropiedadCondicionDto.Enabled := bPuedeEditar and bCondicional;
    FLstValoresCondicionDto.Enabled := bPuedeEditar and bCondicional and
      (FCmbPropiedadCondicionDto.ItemIndex >= 0);
    FLblPropiedadCondicionDto.Enabled := bCondicional;
    FLblValoresCondicionDto.Enabled := bCondicional;
    FBtnGuardarCondicionDto.Enabled := bPuedeEditar;
  end;
end;

function TfrmMtoTarifas.RecogerCondicionDto:
  TCondicionDescuentoTarifa;
var
  i: Integer;
  iSeleccionados: Integer;
begin
  Result := CondicionDescuentoTodos;
  if FCmbModoCondicionDto.ItemIndex >= 0 then
  begin
    Result.Modo := TModoCondicionDescuentoTarifa(
      FCmbModoCondicionDto.ItemIndex);
    if Result.Modo <> mcdTodos then
    begin
      Result.CodigoPropiedad := CodigoPropiedadCondicionDto;
      iSeleccionados := 0;
      for i := 0 to FLstValoresCondicionDto.Items.Count - 1 do
        if FLstValoresCondicionDto.Checked[i] then
        begin
          SetLength(Result.IdsValores, iSeleccionados + 1);
          Result.IdsValores[iSeleccionados] := FValoresCondicionDto[i].Id;
          Inc(iSeleccionados);
        end;
    end;
  end;
end;

procedure TfrmMtoTarifas.cmbModoCondicionDtoChange(Sender: TObject);
begin
  if not FCargandoCondicionDto then
    ActualizarEstadoCondicionDto;
end;

procedure TfrmMtoTarifas.cmbPropiedadCondicionDtoChange(Sender: TObject);
var
  aSinSeleccion: TArray<Integer>;
begin
  if not FCargandoCondicionDto then
  begin
    SetLength(aSinSeleccion, 0);
    CargarValoresCondicionDto(aSinSeleccion);
    ActualizarEstadoCondicionDto;
  end;
end;

procedure TfrmMtoTarifas.btnGuardarCondicionDtoClick(Sender: TObject);
var
  oCondicion: TCondicionDescuentoTarifa;
begin
  oCondicion := RecogerCondicionDto;
  FRepositorioCondicionesDto.Guardar(
    CodigoTarifaActual,
    oCondicion,
    IdentidadSesion.Usuario);
  FUltimaTarifaCondicionDto := '';
  CargarCondicionDto;
  ShowMessage_fza(SInfoAplicacionDescuentoGuardada);
end;

procedure TfrmMtoTarifas.dsTablaGDataChangeCondicionDto(
  Sender: TObject; Field: TField);
begin
  if Assigned(FOnDataChangeTablaGAnterior) then
    FOnDataChangeTablaGAnterior(Sender, Field);
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_TAR_ARTTAR') then
    CargarCondicionDto;
end;

procedure TfrmMtoTarifas.CrearBotonSesionesCambios;
const
  cAnchoBotonSesiones = 220;
  cMargenBotonera = 8;
begin
  if not Assigned(FBtnSesionesCambios) then
  begin
    FBtnSesionesCambios := TcxButton.Create(Self);
    FBtnSesionesCambios.Parent := pnlBotonera;
    FBtnSesionesCambios.Top := btnAddBlock.Top + btnAddBlock.Height +
                               cMargenBotonera;
    FBtnSesionesCambios.Left := btnAddBlock.Left;
    FBtnSesionesCambios.Width := cAnchoBotonSesiones;
    FBtnSesionesCambios.Height := btnAddBlock.Height + cMargenBotonera;
    FBtnSesionesCambios.Caption := SCaptionSesionesCambiosTarifa;
    FBtnSesionesCambios.OnClick := btnSesionesCambiosClick;
  end;
  if pnlBotonera.Width < FBtnSesionesCambios.Left +
                         FBtnSesionesCambios.Width + cMargenBotonera then
    pnlBotonera.Width := FBtnSesionesCambios.Left +
                         FBtnSesionesCambios.Width + cMargenBotonera;
end;

procedure TfrmMtoTarifas.btnSesionesCambiosClick(Sender: TObject);
begin
  ShowMto(Self.Owner, 'TarifasCambios');
end;

// dsTablaG apunta a la cabecera de tarifa. El articulo activo vive en
// la fila del sub-grid tvArticulos (CODIGO_ART_ARTTAR /
// CODIGO_UNIDAD_ARTTAR).
procedure TfrmMtoTarifas.ResolverArtSkuActivo(out ACodArt,
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

// dsTablaG es la cabecera (no tiene articulo). El articulo activo viene
// del sub-grid tvArticulos, cuyo DataSource es
// dmmTarifas.dsArticulosTarifas. Lo anadimos al hook para que la
// pantalla flotante refresque al moverse el cursor entre lineas.
function TfrmMtoTarifas.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmTarifas) then
    Result := [dsTablaG, dmmTarifas.dsArticulosTarifas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoTarifas.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoTarifas.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_TARIFA.Enabled := True
  else
  begin
    txtCODIGO_TARIFA.Enabled := False;
  end;
  ActualizarEstadoCondicionDto;
end;

initialization
  RegistrarPantalla(TfrmMtoTarifas);
  ForceReferenceToClass(TfrmMtoTarifas);
end.

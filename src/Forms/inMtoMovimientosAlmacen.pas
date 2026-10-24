{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoMovimientosAlmacen                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de movimientos de almacen.                                  }
{    Entradas, salidas y traspasos entre almacenes.                            }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista.        }
{******************************************************************************}
unit inMtoMovimientosAlmacen;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, Vcl.ComCtrls,
  UniDataMovimientosAlmacen, inLibPerfilesUsuarioIntf,
  inLibMovimientosAlmacenAplicacion, inLibFotoMiniaturaMtoVcl,
  cxCheckBox, cxCheckComboBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs, System.Actions, Vcl.ActnList;

type
  TfrmMtoMovimientosAlmacen = class(TfrmMtoGen)
    cxGrdDBTabPrinNUMERO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_MOVIMIENTO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_COSTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_MEDIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PROVEEDOR_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLOTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CADUCIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    colMovTipoCantidad: TcxGridDBColumn;
    Action1: TAction;
    btnIraArticulo: TcxButton;
    btnIrDocumento: TcxButton;
    pnlFiltros: TPanel;
    btnToggleFiltros: TcxButton;
    pnlContFiltros: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    procedure Action1Execute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnIrDocumentoClick(Sender: TObject);
    procedure btnToggleFiltrosClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Guarda contra reentrada mientras inicializamos los combos desde el
    // perfil (si no, cada marca dispara una reapertura del SQL).
    FFiltrosCargando: Boolean;
    // La carga inicial con barra de progreso se hace una sola vez.
    FCargaInicialHecha: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    dmmMovimientosAlmacen: TdmMovimientosAlmacen;
    FLectorMovimientos: ILectorMovimientosAlmacen;
    FServicioCarga: TServicioCargaMovimientosAlmacen;
    FMiniaturaFoto: TMiniaturaFotoMto;
    function ValorCampoMovimiento(const ACampo: string): string;
    function EsTipoOperacionCaja(const ATipoDocumento: string): Boolean;
    procedure AbrirOperacionCajaMovimiento;
    procedure AbrirDocumentoSerieNumero(const ACall: string;
      const AInvertirClave: Boolean = False);
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function ConstruirFiltroMovimientos: TFiltroMovimientosAlmacen;
    procedure AplicarFiltrosMovimientos;
    procedure AbrirConProgreso;
    function NotificarProgresoCarga(
      ALeidos, ATotal: Integer): Boolean;
    procedure MostrarProgresoCarga(const AMax: Integer);
    procedure ActualizarProgresoCarga(const APos, AMax: Integer);
    procedure OcultarProgresoCarga;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inLibUser, inLibShowMto, inLibGridCantidad,
  inLibMsgArticulos, inLibMsgComun, inLibTrazabilidad,
  UniDataMovimientosAlmacenRepositorio,
  UniDataDestinoFacturaRepositorio;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoMovimientosAlmacen }

procedure TfrmMtoMovimientosAlmacen.Action1Execute(Sender: TObject);
begin
  inherited;
  btnIraArticuloClick(Sender);
end;

procedure TfrmMtoMovimientosAlmacen.btnIraArticuloClick(Sender: TObject);
var
  sCodArt: string;
  vw: TcxCustomGridView;
  dbView: TcxGridDBTableView;
  colArticulo: TcxGridDBColumn;
begin
  inherited;
  sCodArt := '';
  vw := cxGrdPrincipal.FocusedView;
  if (vw <> nil) and (vw is TcxGridDBTableView) then
  begin
    dbView := TcxGridDBTableView(vw);
    colArticulo := dbView.GetColumnByFieldName('CODIGO_ART_MOV');
    if Assigned(colArticulo) and
       Assigned(dbView.Controller.FocusedRecord) then
      sCodArt := VarToStr(
        dbView.Controller.FocusedRecord.Values[colArticulo.Index]);
  end;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

resourcestring
  SAvisoMovimientoSinDocumento =
    'El movimiento seleccionado no tiene un documento asociado.';
  SAvisoMovimientoCajaSinClave =
    'No se puede abrir la operación de caja porque el movimiento no ' +
    'conserva la clave completa de empresa, almacén, caja y operación.';
  SAvisoTipoDocumentoMovimientoNoSoportado =
    'No hay una pantalla asociada al tipo de documento "%s".';

function TfrmMtoMovimientosAlmacen.ValorCampoMovimiento(
  const ACampo: string): string;
var
  Campo: TField;
begin
  Result := '';
  if Assigned(dmmMovimientosAlmacen) and
     Assigned(dmmMovimientosAlmacen.unqryTablaG) and
     dmmMovimientosAlmacen.unqryTablaG.Active and
     (not dmmMovimientosAlmacen.unqryTablaG.IsEmpty) then
  begin
    Campo := dmmMovimientosAlmacen.unqryTablaG.FindField(ACampo);
    if Assigned(Campo) then
      Result := Trim(Campo.AsString);
  end;
end;

function TfrmMtoMovimientosAlmacen.EsTipoOperacionCaja(
  const ATipoDocumento: string): Boolean;
begin
  Result := (ATipoDocumento = 'VE') or
            (ATipoDocumento = 'DV') or
            (ATipoDocumento = 'DE') or
            (ATipoDocumento = 'TR') or
            (ATipoDocumento = 'TA') or
            (ATipoDocumento = 'AT') or
            (ATipoDocumento = 'AL') or
            // Perdida en transito (FZ-ISSUE-256).
            (ATipoDocumento = 'TP');
end;

procedure TfrmMtoMovimientosAlmacen.AbrirOperacionCajaMovimiento;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sOperacion: string;
begin
  sEmpresa := ValorCampoMovimiento('CODIGO_EMP_MOV');
  sAlmacen := ValorCampoMovimiento('CODIGO_ALM_DOC_MOV');
  if sAlmacen = '' then
    sAlmacen := ValorCampoMovimiento('CODIGO_ALM_MOV');
  sCaja := ValorCampoMovimiento('CODIGO_CAJA_DOC_MOV');
  sOperacion := ValorCampoMovimiento('NUMERO_OPERACION_DOC_MOV');
  if (sEmpresa <> '') and (sAlmacen <> '') and
     (sCaja <> '') and (sOperacion <> '') then
    ShowMto(Self.Owner, 'CajaOperacionesHist',
      sEmpresa + ',' + sAlmacen + ',' + sCaja + ',' + sOperacion)
  else
    ShowMessage_fza(SAvisoMovimientoCajaSinClave);
end;

procedure TfrmMtoMovimientosAlmacen.AbrirDocumentoSerieNumero(
  const ACall: string; const AInvertirClave: Boolean);
var
  sNumero: string;
  sSerie: string;
begin
  sSerie := ValorCampoMovimiento('SERIE_DOC_MOV');
  sNumero := ValorCampoMovimiento('NUMERO_DOC_MOV');
  if (sSerie = '') or (sNumero = '') then
    ShowMessage_fza(SAvisoMovimientoSinDocumento)
  else
  begin
    if AInvertirClave then
      ShowMto(Self.Owner, ACall, sNumero + ',' + sSerie)
    else
      ShowMto(Self.Owner, ACall, sSerie + ',' + sNumero);
  end;
end;

procedure TfrmMtoMovimientosAlmacen.btnIrDocumentoClick(Sender: TObject);
var
  sCallFactura: string;
  sNumero: string;
  sSerie: string;
  sTipo: string;
begin
  inherited;
  sTipo := UpperCase(ValorCampoMovimiento('TIPO_DOC_MOV'));
  if sTipo = '' then
    ShowMessage_fza(SAvisoMovimientoSinDocumento)
  else
  begin
    if EsTipoOperacionCaja(sTipo) then
      AbrirOperacionCajaMovimiento
    else if sTipo = 'PE' then
      AbrirDocumentoSerieNumero('Pedidos')
    else if sTipo = 'AV' then
      AbrirDocumentoSerieNumero('Albaranes')
    else if sTipo = 'FC' then
    begin
      sSerie := ValorCampoMovimiento('SERIE_DOC_MOV');
      sNumero := ValorCampoMovimiento('NUMERO_DOC_MOV');
      if (sSerie = '') or (sNumero = '') then
        ShowMessage_fza(SAvisoMovimientoSinDocumento)
      else
      begin
        sCallFactura := ResolverCallFactura(
          CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
          sNumero, sSerie);
        ShowMto(Self.Owner, sCallFactura, sNumero + ',' + sSerie);
      end;
    end
    else if sTipo = 'PC' then
      AbrirDocumentoSerieNumero('PedidosCompra')
    else if (sTipo = 'AC') or (sTipo = 'AB') or (sTipo = 'AE') then
      AbrirDocumentoSerieNumero('AlbaranesCompra')
    else if sTipo = 'FP' then
      AbrirDocumentoSerieNumero('FacturasCompra')
    else if sTipo = 'DC' then
      AbrirDocumentoSerieNumero('DevolucionesCompra')
    else if sTipo = 'IN' then
      AbrirDocumentoSerieNumero('Inventarios')
    else if sTipo = 'SE' then
      AbrirDocumentoSerieNumero('ComprasSesiones')
    else
      ShowMessageFmt_fza(SAvisoTipoDocumentoMovimientoNoSoportado, [sTipo]);
  end;
end;

procedure TfrmMtoMovimientosAlmacen.CrearTablaPrincipal;
begin
  inherited;
  dmmMovimientosAlmacen := tdmDataModule as TdmMovimientosAlmacen;
  FLectorMovimientos := CrearLectorMovimientosAlmacenUniDAC(
    dmmMovimientosAlmacen.unqryTablaG,
    ContextoSesion,
    ParametrosApp);
  FServicioCarga := TServicioCargaMovimientosAlmacen.Create(
    FLectorMovimientos);
  // Cantidad del movimiento con decimales segun la unidad del articulo.
  VincularCantidadGrid(
    cxGrdDBTabPrin.GetColumnByFieldName('CANTIDAD_MOV'),
    cxGrdDBTabPrin.GetColumnByFieldName('TIPO_CANTIDAD_ART'),
    UnidadesMedida);
  pkFieldName := 'NUMERO_MOV';
  // F-LOTEC-018: con trazabilidad, lote y caducidad visibles por defecto.
  if TActivacionTrazabilidad.Leer(ParametrosApp).AlgunModoActivo then
  begin
    cxGrdDBTabPrinLOTE_MOV.Visible := True;
    cxGrdDBTabPrinFECHA_CADUCIDAD_MOV.Visible := True;
  end;
  // Persiana de filtros de carga: arranca colapsada (igual que el Mto de
  // articulos); se despliega al pulsar la cabecera.
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. NO
  // abrimos aqui: la query esta Active=False en su .dfm y la apertura con
  // barra de progreso se hace en ResetForm, ya con el form visible.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  FLectorMovimientos.Preparar(ConstruirFiltroMovimientos);
  // Foto del articulo del movimiento activo bajo el icono de la barra
  // derecha; sigue al registro y abre el visor igual que Ctrl+F.
  if not Assigned(FMiniaturaFoto) and Assigned(FotosArticulos) then
    FMiniaturaFoto := TMiniaturaFotoMto.Create(Self, pButtonRightBar,
      pButtonBDStat, FotosArticulos, ResolverArtSkuActivo,
      DataSourcesParaFoto, actFotoArticulo);
end;

procedure TfrmMtoMovimientosAlmacen.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales (la de busqueda Ctrl+R la maneja PrepararBusquedaExterna).
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.CargarAnyosFiltro;
var
  Anyos: TArray<Integer>;
  I: Integer;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  Anyos := FLectorMovimientos.ObtenerAnyos;
  for I := 0 to Length(Anyos) - 1 do
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := IntToStr(Anyos[I]);
    if item.Description = sAnyoActual then
      bExisteActual := True;
  end;
  // El año en curso es el valor por defecto: lo añadimos aunque no tenga
  // movimientos todavia para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.CargarAlmacenesFiltro;
var
  Almacenes: TArray<TAlmacenFiltroMovimiento>;
  I: Integer;
  item: TcxCheckComboBoxItem;
begin
  ccbFiltroAlmacen.Properties.Items.Clear;
  if FCodigosAlmacen = nil then
    FCodigosAlmacen := TStringList.Create
  else
    FCodigosAlmacen.Clear;
  Almacenes := FLectorMovimientos.ObtenerAlmacenes;
  for I := 0 to Length(Almacenes) - 1 do
  begin
    item := ccbFiltroAlmacen.Properties.Items.Add;
    item.Description := Almacenes[I].Codigo + ' - ' + Almacenes[I].Nombre;
    FCodigosAlmacen.Add(Almacenes[I].Codigo);
  end;
end;

procedure TfrmMtoMovimientosAlmacen.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  FFiltrosCargando := True;
  try
    // Por defecto: año en curso marcado; ningun almacen marcado (= todos).
    sAnyosCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAnyos',
                                   IntToStr(YearOf(Date)));
    sAlmCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacenes', '');
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sAnyosCsv;
      for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      begin
        if lst.IndexOf(ccbFiltroAnyo.Properties.Items[i].Description) >= 0 then
          ccbFiltroAnyo.States[i] := cbsChecked
        else
          ccbFiltroAnyo.States[i] := cbsUnchecked;
      end;
      lst.DelimitedText := sAlmCsv;
      for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      begin
        if (i < FCodigosAlmacen.Count) and
           (lst.IndexOf(FCodigosAlmacen[i]) >= 0) then
          ccbFiltroAlmacen.States[i] := cbsChecked
        else
          ccbFiltroAlmacen.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosCargando := False;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  if Assigned(ccbFiltroAnyo) then
  begin
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    sAnyos := '';
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
    begin
      if ccbFiltroAnyo.States[i] = cbsChecked then
      begin
        if sAnyos <> '' then
          sAnyos := sAnyos + ';';
        sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
      end;
    end;
    item.SubKey := 'oFiltroAnyos';
    item.Value := sAnyos;
    oList.Add(item);
    sAlmacenes := '';
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
    begin
      if (ccbFiltroAlmacen.States[i] = cbsChecked) and
         (i < FCodigosAlmacen.Count) then
      begin
        if sAlmacenes <> '' then
          sAlmacenes := sAlmacenes + ';';
        sAlmacenes := sAlmacenes + FCodigosAlmacen[i];
      end;
    end;
    item.SubKey := 'oFiltroAlmacenes';
    item.Value := sAlmacenes;
    oList.Add(item);
  end;
end;

function TfrmMtoMovimientosAlmacen.ConstruirFiltroMovimientos:
  TFiltroMovimientosAlmacen;
var
  i: Integer;
begin
  Result := Default(TFiltroMovimientosAlmacen);
  for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
  begin
    if ccbFiltroAnyo.States[i] = cbsChecked then
    begin
      SetLength(Result.Anyos, Length(Result.Anyos) + 1);
      Result.Anyos[High(Result.Anyos)] := StrToIntDef(
        ccbFiltroAnyo.Properties.Items[i].Description,
        0);
    end;
  end;
  for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
  begin
    if (ccbFiltroAlmacen.States[i] = cbsChecked) and
       (i < FCodigosAlmacen.Count) then
    begin
      SetLength(Result.Almacenes, Length(Result.Almacenes) + 1);
      Result.Almacenes[High(Result.Almacenes)] := FCodigosAlmacen[i];
    end;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.AplicarFiltrosMovimientos;
begin
  FLectorMovimientos.Preparar(ConstruirFiltroMovimientos);
  AbrirConProgreso;
end;

procedure TfrmMtoMovimientosAlmacen.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
  MAX_FILAS_CARGA = 200000;
var
  Resultado: TResultadoCargaMovimientos;
  cursorPrev: TCursor;
begin
  cursorPrev := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  MostrarProgresoCarga(0);
  try
    Resultado := FServicioCarga.Cargar(
      MAX_FILAS_CARGA,
      TAM_BLOQUE,
      200,
      NotificarProgresoCarga);
    if Resultado.Estado = ecmLimiteSuperado then
      MessageDlg_fza(Format(SAvisoLimiteRegistrosMovimientosAlmacen,
        [FormatFloat('#,##0', Resultado.Total)]), mtWarning, [mbOK], 0);
  finally
    OcultarProgresoCarga;
    Screen.Cursor := cursorPrev;
  end;
end;

function TfrmMtoMovimientosAlmacen.NotificarProgresoCarga(
  ALeidos, ATotal: Integer): Boolean;
begin
  ActualizarProgresoCarga(ALeidos, ATotal);
  Result := False;
end;

procedure TfrmMtoMovimientosAlmacen.MostrarProgresoCarga(const AMax: Integer);
begin
  if FPnlProgreso = nil then
  begin
    FPnlProgreso := TPanel.Create(Self);
    FPnlProgreso.Parent := Self;
    FPnlProgreso.BevelOuter := bvLowered;
    FPnlProgreso.ParentBackground := False;
    FPnlProgreso.Color := clWindow;
    FPnlProgreso.Width := 340;
    FPnlProgreso.Height := 96;
    FlblProgreso := TcxLabel.Create(Self);
    FlblProgreso.Parent := FPnlProgreso;
    FlblProgreso.Left := 16;
    FlblProgreso.Top := 18;
    FlblProgreso.Style.Font.Style := [fsBold];
    FbarProgreso := TProgressBar.Create(Self);
    FbarProgreso.Parent := FPnlProgreso;
    FbarProgreso.Left := 16;
    FbarProgreso.Top := 52;
    FbarProgreso.Width := 308;
    FbarProgreso.Height := 22;
  end;
  FbarProgreso.Min := 0;
  if AMax > 0 then
    FbarProgreso.Max := AMax
  else
    FbarProgreso.Max := 1;
  FbarProgreso.Position := 0;
  FlblProgreso.Caption := SCaptionCargandoMovimientos;
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmMtoMovimientosAlmacen.ActualizarProgresoCarga(const APos,
                                                            AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := Format(SCaptionCargandoMovimientosProgreso,
                                   [FormatFloat('#,##0', APos),
                                    FormatFloat('#,##0', AMax)]);
    Application.ProcessMessages;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

procedure TfrmMtoMovimientosAlmacen.btnToggleFiltrosClick(Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  pnlContFiltros.Visible := not pnlContFiltros.Visible;
  if pnlContFiltros.Visible then
  begin
    pnlFiltros.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltros.Caption := SCaptionFiltrosCargaExpandido;
  end
  else
  begin
    pnlFiltros.Height := ALTO_CABECERA;
    btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosMovimientos;
end;

procedure TfrmMtoMovimientosAlmacen.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosMovimientos;
end;

procedure TfrmMtoMovimientosAlmacen.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+R): sin filtros de carga para localizar el
  // movimiento sea del año/almacen que sea.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  FLectorMovimientos.Preparar(ConstruirFiltroMovimientos);
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  inherited;
end;

procedure TfrmMtoMovimientosAlmacen.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  pnlFiltros.Visible := False;
  // Movimientos es una lista SIN ficha (tsFicha oculta). La instancia de
  // busqueda externa oculta la lista para ir a la ficha; como aqui no hay
  // ficha, volvemos a mostrar la lista: el grid queda filtrado a la PK
  // (un solo movimiento) por PrepararBusquedaExterna.
  tsLista.TabVisible := True;
  pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoMovimientosAlmacen.FormDestroy(Sender: TObject);
begin
  inherited;
  FreeAndNil(FServicioCarga);
  FLectorMovimientos := nil;
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  RegistrarPantalla(TfrmMtoMovimientosAlmacen);
  ForceReferenceToClass(TfrmMtoMovimientosAlmacen);
end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGarantiasReparacionesVcl                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Paneles de la parte de reparaciones de «Reparaciones y garantías»:        }
{    líneas y presupuesto del expediente, liquidaciones (pago a externos y     }
{    cargo al fabricante) y configuración (tipos de servicio y modo de         }
{    liquidación de los proveedores). Reciben los datos y unos enlaces; no     }
{    conocen el formulario que los coloca.                                     }
{******************************************************************************}
unit inMtoGarantiasReparacionesVcl;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Data.DB,
  cxGroupBox, cxGrid, cxGridCustomTableView, cxGridDBTableView, cxButtons,
  UniDataReparacionesPantalla, inLibReparacionesDocumentos;

type
  // Lo que el panel necesita de quien lo coloca.
  TEnlacesReparaciones = record
    ReparacionActual: TFunc<Int64>;
    AlmacenActual: TFunc<string>;
    EmpresaActual: TFunc<string>;
    Usuario: string;
    // Releer la lista y volver a AReparacion (0 = la actual).
    Refrescar: TProc<Int64>;
    Imprimir: TProc<THojaReparaciones>;
  end;

  TPanelReparaciones = class(TcxGroupBox)
  private
    FSiguienteBoton: Integer;
  protected
    FBotonera: TcxGroupBox;
    FDatos: TDatosPantallaReparaciones;
    FEnlaces: TEnlacesReparaciones;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearBoton(const ATexto: string; AAncho: Integer;
      AAlPulsar: TNotifyEvent);
    function CrearVista(AAlineacion: TAlign; AAlto: Integer;
      ADatos: TDataSource): TcxGridDBTableView;
    function CrearColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    // Ejecuta AAccion; un error de situación o de validación se avisa.
    procedure Accion(AAccion: TProc);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); virtual;
  end;

  TPanelLineasReparacion = class(TPanelReparaciones)
  private
    FVista: TcxGridDBTableView;
    function LineaActual: Int64;
    function HayReparacion: Boolean;
    function HayLinea: Boolean;
    procedure CrearColumnas;
    procedure TipoLineaGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure EjecutorGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure AnadirClick(Sender: TObject);
    procedure CambiarClick(Sender: TObject);
    procedure BorrarClick(Sender: TObject);
    procedure EmpezarClick(Sender: TObject);
    procedure TerminarClick(Sender: TObject);
    procedure DevolverClick(Sender: TObject);
    procedure HojaEntregaClick(Sender: TObject);
    procedure PresupuestarClick(Sender: TObject);
    procedure AceptarPresupuestoClick(Sender: TObject);
    procedure RechazarPresupuestoClick(Sender: TObject);
    procedure Responder(AAceptado: Boolean);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
  end;

  TPanelLiquidacionesReparacion = class(TPanelReparaciones)
  private
    FVista: TcxGridDBTableView;
    FUltimoProveedor: string;
    function LiquidacionActual: Int64;
    procedure CrearColumnas;
    procedure Liquidar(const ASentido: string);
    procedure PagarClick(Sender: TObject);
    procedure CargarClick(Sender: TObject);
    procedure DocumentoClick(Sender: TObject);
    procedure AbonoClick(Sender: TObject);
    procedure ImprimirClick(Sender: TObject);
    procedure RefrescarClick(Sender: TObject);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
  end;

  TPanelConfiguracionReparaciones = class(TPanelReparaciones)
  private
    procedure CrearRejillaTipos;
    procedure CrearRejillaExternos;
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
  end;

implementation

uses
  Winapi.Windows, System.UITypes, System.Variants, Vcl.Dialogs,
  cxContainer, cxGridLevel, cxEdit, cxCheckBox, cxImageComboBox, cxCalendar,
  inLibMensajesVcl, inLibErroresBBDD, inLibReparaciones,
  inLibReparacionesIntf, inLibMsgReparaciones, inMtoModalLineaReparacion;

{ TPanelReparaciones }

constructor TPanelReparaciones.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited Create(AOwner);
  Parent := AParent;
  Align := alClient;
  PanelStyle.Active := True;
  Style.BorderStyle := ebsNone;
  Transparent := True;
  FDatos := ADatos;
  FEnlaces := AEnlaces;
  FBotonera := TcxGroupBox.Create(Self);
  FBotonera.Parent := Self;
  FBotonera.Align := alTop;
  FBotonera.Height := EscalarDpi(44);
  FBotonera.PanelStyle.Active := True;
  FBotonera.Style.BorderStyle := ebsNone;
  FBotonera.Transparent := True;
  FSiguienteBoton := 8;
end;

function TPanelReparaciones.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

// Los botones se colocan uno tras otro en la botonera.
procedure TPanelReparaciones.CrearBoton(const ATexto: string;
  AAncho: Integer; AAlPulsar: TNotifyEvent);
var
  oBoton: TcxButton;
begin
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := FBotonera;
  oBoton.SetBounds(EscalarDpi(FSiguienteBoton), EscalarDpi(6),
    EscalarDpi(AAncho), EscalarDpi(32));
  oBoton.Caption := ATexto;
  oBoton.OnClick := AAlPulsar;
  FSiguienteBoton := FSiguienteBoton + AAncho + 6;
end;

function TPanelReparaciones.CrearVista(AAlineacion: TAlign; AAlto: Integer;
  ADatos: TDataSource): TcxGridDBTableView;
var
  oRejilla: TcxGrid;
begin
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Parent := Self;
  oRejilla.Align := AAlineacion;
  oRejilla.Height := AAlto;
  Result := oRejilla.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  oRejilla.Levels.Add.GridView := Result;
  Result.DataController.DataSource := ADatos;
  Result.OptionsView.GroupByBox := False;
  Result.OptionsData.Editing := False;
  Result.OptionsData.Inserting := False;
  Result.OptionsData.Deleting := False;
end;

function TPanelReparaciones.CrearColumna(AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TPanelReparaciones.Accion(AAccion: TProc);
begin
  try
    AAccion();
  except
    on E: EFaseReparacion do
      ShowMessage_fza(E.Message);
    on E: EArgumentException do
      ShowMessage_fza(E.Message);
    on E: EValidacionBBDD do
      ShowMessage_fza(E.Message);
  end;
end;

{ TPanelLineasReparacion }

constructor TPanelLineasReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited;
  CrearBoton(SCaptionAnadirLinea, 100, AnadirClick);
  CrearBoton(SCaptionCambiarLinea, 80, CambiarClick);
  CrearBoton(SCaptionBorrarLinea, 70, BorrarClick);
  CrearBoton(SCaptionEmpezarLinea, 80, EmpezarClick);
  CrearBoton(SCaptionTerminarLinea, 80, TerminarClick);
  CrearBoton(SCaptionDevolverLinea, 120, DevolverClick);
  CrearBoton(SCaptionHojaEntrega, 110, HojaEntregaClick);
  CrearBoton(SCaptionPresupuestar, 100, PresupuestarClick);
  CrearBoton(SCaptionAceptarPresupuesto, 90, AceptarPresupuestoClick);
  CrearBoton(SCaptionRechazarPresupuesto, 90, RechazarPresupuestoClick);
  FVista := CrearVista(alClient, 0, FDatos.Lineas);
  FVista.OptionsSelection.MultiSelect := True;
  CrearColumnas;
end;

// ID_GARLIN va oculta: la hoja de entrega la lee de las filas
// seleccionadas.
procedure TPanelLineasReparacion.CrearColumnas;
begin
  CrearColumna(FVista, 'ID_GARLIN', 'ID_GARLIN', 40).Visible := False;
  CrearColumna(FVista, 'LINEA_GARLIN', SColLinea, 45);
  CrearColumna(FVista, 'TIPO_LINEA_GARLIN', SColTipoLinea, 100)
    .OnGetDisplayText := TipoLineaGetDisplayText;
  CrearColumna(FVista, 'DESCRIPCION_GARLIN', SColDescripcionLinea, 220);
  CrearColumna(FVista, 'TIPO_EJECUTOR_GARLIN', SColEjecutorTipo, 110)
    .OnGetDisplayText := EjecutorGetDisplayText;
  CrearColumna(FVista, 'EJECUTOR', SColEjecutor, 170);
  CrearColumna(FVista, 'CODIGO_UNIDAD_GARLIN', SColSkuLinea, 130);
  CrearColumna(FVista, 'CANTIDAD_GARLIN', SColCantidadLinea, 70);
  CrearColumna(FVista, 'IMPORTE_CLIENTE', SColImporteCliente, 90);
  CrearColumna(FVista, 'IMPORTE_COSTE', SColImporteCoste, 90);
  CrearColumna(FVista, 'FECHA_INICIO_GARLIN', SColInicioLinea, 90);
  CrearColumna(FVista, 'FECHA_FIN_GARLIN', SColFinLinea, 90);
  CrearColumna(FVista, 'INCIDENCIA_GARLIN', SColIncidenciaLinea, 180);
  CrearColumna(FVista, 'ID_GARLIQ_GARLIN', SColPagoLinea, 70);
  CrearColumna(FVista, 'ID_GARLIQ_CARGO_GARLIN', SColCargoLinea, 70);
end;

procedure TPanelLineasReparacion.TipoLineaGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if AText = LINEA_REPARACION_MATERIAL then
    AText := SLineaMaterial
  else if AText = LINEA_REPARACION_MANO_OBRA then
    AText := SLineaManoObra;
end;

procedure TPanelLineasReparacion.EjecutorGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoEjecutorReparacion(AText);
end;

function TPanelLineasReparacion.HayReparacion: Boolean;
begin
  Result := FEnlaces.ReparacionActual() > 0;
  if not Result then
    ShowMessage_fza(SInfoSinReparacion);
end;

function TPanelLineasReparacion.HayLinea: Boolean;
begin
  Result := HayReparacion and Assigned(FDatos.Lineas.DataSet) and
    FDatos.Lineas.DataSet.Active and not FDatos.Lineas.DataSet.IsEmpty;
  if HayReparacion and not Result then
    ShowMessage_fza(SInfoSinLinea);
end;

function TPanelLineasReparacion.LineaActual: Int64;
begin
  Result := FDatos.Lineas.DataSet.FieldByName('ID_GARLIN').AsLargeInt;
end;

function LineaDeDatos(ADatos: TDataSet): TLineaReparacion;
begin
  Result := Default(TLineaReparacion);
  Result.Id := ADatos.FieldByName('ID_GARLIN').AsLargeInt;
  Result.Reparacion := ADatos.FieldByName('ID_GAR_GARLIN').AsLargeInt;
  Result.TipoLinea := ADatos.FieldByName('TIPO_LINEA_GARLIN').AsString;
  Result.Tipo := ADatos.FieldByName('CODIGO_GARTIP_GARLIN').AsString;
  Result.Descripcion := ADatos.FieldByName('DESCRIPCION_GARLIN').AsString;
  Result.TipoEjecutor := ADatos.FieldByName('TIPO_EJECUTOR_GARLIN').AsString;
  Result.Empleado := ADatos.FieldByName('CODIGO_EMPL_GARLIN').AsString;
  Result.Proveedor := ADatos.FieldByName('CODIGO_PRV_GARLIN').AsString;
  Result.Sku := ADatos.FieldByName('CODIGO_UNIDAD_GARLIN').AsString;
  Result.Cantidad := ADatos.FieldByName('CANTIDAD_GARLIN').AsFloat;
  Result.PrecioCliente :=
    ADatos.FieldByName('PRECIO_CLIENTE_GARLIN').AsCurrency;
  Result.PrecioCoste := ADatos.FieldByName('PRECIO_COSTE_GARLIN').AsCurrency;
end;

procedure TPanelLineasReparacion.AnadirClick(Sender: TObject);
var
  Linea: TLineaReparacion;
begin
  if HayReparacion then
  begin
    Linea := Default(TLineaReparacion);
    Linea.Reparacion := FEnlaces.ReparacionActual();
    Linea.Usuario := FEnlaces.Usuario;
    if TfrmModalLineaReparacion.Ejecutar(Owner, FDatos.Catalogo,
      FDatos.Reparaciones, Linea) > 0 then
      FEnlaces.Refrescar(0);
  end;
end;

procedure TPanelLineasReparacion.CambiarClick(Sender: TObject);
var
  Linea: TLineaReparacion;
begin
  if HayLinea then
  begin
    Linea := LineaDeDatos(FDatos.Lineas.DataSet);
    Linea.Usuario := FEnlaces.Usuario;
    if TfrmModalLineaReparacion.Ejecutar(Owner, FDatos.Catalogo,
      FDatos.Reparaciones, Linea) > 0 then
      FEnlaces.Refrescar(0);
  end;
end;

procedure TPanelLineasReparacion.BorrarClick(Sender: TObject);
begin
  if HayLinea and (MessageDlg_fza(SPreguntaBorrarLinea, mtConfirmation,
    [mbYes, mbNo], 0, mbNo) = mrYes) then
    Accion(
      procedure
      begin
        FDatos.Reparaciones.BorrarLinea(LineaActual, FEnlaces.Usuario);
        FEnlaces.Refrescar(0);
      end);
end;

procedure TPanelLineasReparacion.EmpezarClick(Sender: TObject);
begin
  if HayLinea then
    Accion(
      procedure
      begin
        FDatos.Reparaciones.EmpezarLinea(LineaActual, Date,
          FEnlaces.Usuario);
        FEnlaces.Refrescar(0);
      end);
end;

procedure TPanelLineasReparacion.TerminarClick(Sender: TObject);
begin
  if HayLinea then
    Accion(
      procedure
      var
        iLiquidacion: Int64;
      begin
        iLiquidacion := FDatos.Reparaciones.TerminarLinea(LineaActual, Date,
          FEnlaces.Usuario);
        FEnlaces.Refrescar(0);
        if iLiquidacion > 0 then
          FEnlaces.Imprimir(FDatos.HojaLiquidacion(iLiquidacion));
      end);
end;

procedure TPanelLineasReparacion.DevolverClick(Sender: TObject);
var
  sIncidencia: string;
begin
  sIncidencia := '';
  if HayLinea and InputQuery_fza(STituloDevolverLinea,
    SPreguntaIncidenciaLinea, sIncidencia) and (Trim(sIncidencia) <> '') then
    Accion(
      procedure
      begin
        FDatos.Reparaciones.DevolverLinea(LineaActual, Date, sIncidencia,
          FEnlaces.Usuario);
        FEnlaces.Refrescar(0);
      end);
end;

function ValorFila(AVista: TcxGridDBTableView; AFila: TcxCustomGridRecord;
  const ACampo: string): Variant;
begin
  Result := AFila.Values[AVista.GetColumnByFieldName(ACampo).Index];
end;

// Las líneas seleccionadas de empresas externas: las aún sin empezar se
// marcan enviadas hoy y se imprime lo que se lleva el externo.
procedure TPanelLineasReparacion.HojaEntregaClick(Sender: TObject);
var
  Ids, Nuevas: TArray<Int64>;
  iFila: Integer;
  oFila: TcxCustomGridRecord;
begin
  if HayLinea then
  begin
    Ids := nil;
    Nuevas := nil;
    for iFila := 0 to FVista.Controller.SelectedRecordCount - 1 do
    begin
      oFila := FVista.Controller.SelectedRecords[iFila];
      if VarToStr(ValorFila(FVista, oFila, 'TIPO_EJECUTOR_GARLIN')) =
        EJECUTOR_REPARACION_EXTERNO then
      begin
        Ids := Ids + [Int64(ValorFila(FVista, oFila, 'ID_GARLIN'))];
        if VarIsNull(ValorFila(FVista, oFila, 'FECHA_INICIO_GARLIN')) then
          Nuevas := Nuevas + [Int64(ValorFila(FVista, oFila, 'ID_GARLIN'))];
      end;
    end;
    if Length(Ids) = 0 then
      ShowMessage_fza(SInfoSinLineasExternas)
    else
      Accion(
        procedure
        var
          iId: Int64;
        begin
          for iId in Nuevas do
            FDatos.Reparaciones.EmpezarLinea(iId, Date, FEnlaces.Usuario);
          FEnlaces.Refrescar(0);
          FEnlaces.Imprimir(FDatos.HojaEntrega(Ids,
            FEnlaces.AlmacenActual()));
        end);
  end;
end;

procedure TPanelLineasReparacion.PresupuestarClick(Sender: TObject);
var
  sImporte: string;
  dImporte: Double;
begin
  sImporte := '';
  if HayReparacion and InputQuery_fza(STituloPresupuesto,
    SPreguntaImportePresupuesto, sImporte) then
  begin
    if not TryStrToFloat(Trim(sImporte), dImporte) then
      ShowMessage_fza(SErrorImporteReparacion)
    else
      Accion(
        procedure
        begin
          FDatos.Reparaciones.Presupuestar(FEnlaces.ReparacionActual(),
            dImporte, Date, FEnlaces.Usuario);
          FEnlaces.Refrescar(0);
        end);
  end;
end;

procedure TPanelLineasReparacion.Responder(AAceptado: Boolean);
begin
  if HayReparacion then
    Accion(
      procedure
      begin
        FDatos.Reparaciones.ResponderPresupuesto(
          FEnlaces.ReparacionActual(), AAceptado, Date, FEnlaces.Usuario);
        FEnlaces.Refrescar(0);
      end);
end;

procedure TPanelLineasReparacion.AceptarPresupuestoClick(Sender: TObject);
begin
  Responder(True);
end;

procedure TPanelLineasReparacion.RechazarPresupuestoClick(Sender: TObject);
begin
  Responder(False);
end;

{ TPanelLiquidacionesReparacion }

constructor TPanelLiquidacionesReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited;
  CrearBoton(SCaptionPagarExterno, 130, PagarClick);
  CrearBoton(SCaptionCargarFabricante, 150, CargarClick);
  CrearBoton(SCaptionEnlazarDocumento, 140, DocumentoClick);
  CrearBoton(SCaptionAnotarAbono, 110, AbonoClick);
  CrearBoton(SCaptionImprimirLiquidacion, 90, ImprimirClick);
  CrearBoton(SCaptionRefrescarLiquidaciones, 90, RefrescarClick);
  FVista := CrearVista(alClient, 0, FDatos.Liquidaciones);
  CrearColumnas;
end;

procedure TPanelLiquidacionesReparacion.CrearColumnas;
begin
  CrearColumna(FVista, 'ID_GARLIQ', SColLiquidacion, 60);
  CrearColumna(FVista, 'SENTIDO_GARLIQ', SColSentido, 70);
  CrearColumna(FVista, 'CODIGO_PRV_GARLIQ', SColProveedor, 80);
  CrearColumna(FVista, 'RAZON_SOCIAL_PRV', SColRazonSocial, 200);
  CrearColumna(FVista, 'FECHA_GARLIQ', SColFechaLiquidacion, 90);
  CrearColumna(FVista, 'FECHA_HASTA_GARLIQ', SColHastaLiquidacion, 90);
  CrearColumna(FVista, 'CANTIDAD_LINEAS_GARLIQ', SColLineasLiquidacion, 60);
  CrearColumna(FVista, 'TOTAL_GARLIQ', SColTotalLiquidacion, 90);
  CrearColumna(FVista, 'TIPO_DOC_GARLIQ', SColTipoDocumento, 50);
  CrearColumna(FVista, 'SERIE_DOC_GARLIQ', SColSerieDocumento, 110);
  CrearColumna(FVista, 'NUMERO_DOC_GARLIQ', SColNumeroDocumento, 90);
  CrearColumna(FVista, 'FECHA_ABONO_GARLIQ', SColAbono, 90);
end;

function TPanelLiquidacionesReparacion.LiquidacionActual: Int64;
var
  oDatos: TDataSet;
begin
  Result := 0;
  oDatos := FDatos.Liquidaciones.DataSet;
  if oDatos.Active and not oDatos.IsEmpty then
    Result := oDatos.FieldByName('ID_GARLIQ').AsLargeInt
  else
    ShowMessage_fza(SInfoSinLiquidacion);
end;

// Lo terminado hasta hoy del proveedor tecleado.
procedure TPanelLiquidacionesReparacion.Liquidar(const ASentido: string);
var
  sProveedor: string;
begin
  sProveedor := FUltimoProveedor;
  if InputQuery_fza(STituloLiquidar, SPreguntaProveedorLiquidar,
    sProveedor) and (Trim(sProveedor) <> '') then
    Accion(
      procedure
      var
        Liquidacion: TLiquidacionReparaciones;
      begin
        FUltimoProveedor := Trim(sProveedor);
        Liquidacion := FDatos.LiquidacionesRepositorio.Liquidar(ASentido,
          FEnlaces.EmpresaActual(), FUltimoProveedor, Date,
          FEnlaces.Usuario);
        FDatos.RefrescarLiquidaciones;
        if Liquidacion.Id = 0 then
          ShowMessage_fza(SInfoNadaQueLiquidar)
        else
          FEnlaces.Imprimir(FDatos.HojaLiquidacion(Liquidacion.Id));
      end);
end;

procedure TPanelLiquidacionesReparacion.PagarClick(Sender: TObject);
begin
  Liquidar(LIQUIDACION_REPARACION_PAGO);
end;

procedure TPanelLiquidacionesReparacion.CargarClick(Sender: TObject);
begin
  Liquidar(LIQUIDACION_REPARACION_CARGO);
end;

// FP: factura o autofactura de compra; FA: factura de venta.
procedure TPanelLiquidacionesReparacion.DocumentoClick(Sender: TObject);
var
  iLiquidacion: Int64;
  sTexto, sTipo, sSerie, sNumero: string;
  iBarra: Integer;
begin
  iLiquidacion := LiquidacionActual;
  sTexto := '';
  if (iLiquidacion > 0) and InputQuery_fza(STituloDocumentoLiquidacion,
    SPreguntaDocumentoLiquidacion, sTexto) then
  begin
    sTexto := UpperCase(Trim(sTexto));
    sTipo := Copy(sTexto, 1, 2);
    sTexto := Trim(Copy(sTexto, 3, MaxInt));
    iBarra := LastDelimiter('/', sTexto);
    sSerie := Trim(Copy(sTexto, 1, iBarra - 1));
    sNumero := Trim(Copy(sTexto, iBarra + 1, MaxInt));
    Accion(
      procedure
      begin
        FDatos.LiquidacionesRepositorio.EnlazarDocumento(iLiquidacion,
          sTipo, sSerie, sNumero, FEnlaces.Usuario);
        FDatos.RefrescarLiquidaciones;
      end);
  end;
end;

procedure TPanelLiquidacionesReparacion.AbonoClick(Sender: TObject);
var
  iLiquidacion: Int64;
begin
  iLiquidacion := LiquidacionActual;
  if iLiquidacion > 0 then
    Accion(
      procedure
      begin
        FDatos.LiquidacionesRepositorio.AnotarAbono(iLiquidacion, Date,
          FEnlaces.Usuario);
        FDatos.RefrescarLiquidaciones;
      end);
end;

procedure TPanelLiquidacionesReparacion.ImprimirClick(Sender: TObject);
var
  iLiquidacion: Int64;
begin
  iLiquidacion := LiquidacionActual;
  if iLiquidacion > 0 then
    Accion(
      procedure
      begin
        FEnlaces.Imprimir(FDatos.HojaLiquidacion(iLiquidacion));
      end);
end;

procedure TPanelLiquidacionesReparacion.RefrescarClick(Sender: TObject);
begin
  FDatos.RefrescarLiquidaciones;
end;

{ TPanelConfiguracionReparaciones }

constructor TPanelConfiguracionReparaciones.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited;
  // Sin acciones: las rejillas se editan directamente.
  FBotonera.Visible := False;
  CrearRejillaTipos;
  CrearRejillaExternos;
end;

type
  TTextoValor = function(const AValor: string): string;

procedure AgregarOpciones(AColumna: TcxGridDBColumn;
  const AValores: array of string; ATexto: TTextoValor);
var
  sValor: string;
  oOpcion: TcxImageComboBoxItem;
begin
  AColumna.PropertiesClass := TcxImageComboBoxProperties;
  for sValor in AValores do
  begin
    oOpcion := TcxImageComboBoxProperties(AColumna.Properties).Items.Add;
    oOpcion.Value := sValor;
    oOpcion.Description := ATexto(sValor);
  end;
end;

// '' = el proveedor no trabaja como externo de reparaciones.
function TextoModoLiquidacionExterno(const AValor: string): string;
begin
  if AValor = '' then
    Result := SNoEsExterno
  else
    Result := TextoModoLiquidacion(AValor);
end;

procedure HacerCasilla(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxCheckBoxProperties;
  TcxCheckBoxProperties(AColumna.Properties).ValueChecked := 'S';
  TcxCheckBoxProperties(AColumna.Properties).ValueUnchecked := 'N';
end;

procedure TPanelConfiguracionReparaciones.CrearRejillaTipos;
var
  oVista: TcxGridDBTableView;
  iColumna: Integer;
begin
  oVista := CrearVista(alTop, EscalarDpi(300), FDatos.TiposEditables);
  oVista.OptionsData.Editing := True;
  oVista.OptionsData.Inserting := True;
  oVista.OptionsData.Deleting := True;
  oVista.OptionsView.NewItemRow := True;
  CrearColumna(oVista, 'CODIGO_GARTIP', SColTipoCodigo, 100);
  CrearColumna(oVista, 'CATEGORIA_GARTIP', SColTipoCategoria, 100);
  CrearColumna(oVista, 'DESCRIPCION_GARTIP', SColTipoDescripcion, 200);
  AgregarOpciones(CrearColumna(oVista, 'MODALIDAD_GARTIP', SColModalidad,
    120), [MODALIDAD_REPARACION_PAGO, MODALIDAD_REPARACION_GARANTIA,
    MODALIDAD_REPARACION_CORTESIA], TextoModalidadReparacion);
  HacerCasilla(CrearColumna(oVista, 'ESPRESUPUESTO_GARTIP',
    SColTipoPresupuesto, 80));
  CrearColumna(oVista, 'CANTIDAD_GARTIP', SColCantidadLinea, 70);
  CrearColumna(oVista, 'PRECIO_CLIENTE_GARTIP', SColImporteCliente, 90);
  CrearColumna(oVista, 'PRECIO_COSTE_GARTIP', SColImporteCoste, 90);
  AgregarOpciones(CrearColumna(oVista, 'MODO_COBRO_GARTIP', SColModoCobro,
    110), [COBRO_REPARACION_RECOGIDA, COBRO_REPARACION_COMPRA,
    COBRO_REPARACION_GRATIS], TextoModoCobroReparacion);
  CrearColumna(oVista, 'DIAS_PLAZO_GARTIP', SColTipoPlazo, 60);
  AgregarOpciones(CrearColumna(oVista, 'TIPO_EJECUTOR_GARTIP',
    SColEjecutorTipo, 110), [EJECUTOR_REPARACION_OPERARIO,
    EJECUTOR_REPARACION_EXTERNO], TextoEjecutorReparacion);
  CrearColumna(oVista, 'CODIGO_EMPL_GARTIP', SColTipoOperario, 80);
  CrearColumna(oVista, 'CODIGO_PRV_GARTIP', SColProveedor, 80);
  CrearColumna(oVista, 'CODIGO_ART_GARTIP', SColTipoArticulo, 100);
  CrearColumna(oVista, 'ORDEN_GARTIP', SColTipoOrden, 50);
  HacerCasilla(CrearColumna(oVista, 'ESACTIVO_GARTIP', SColTipoActivo, 60));
  for iColumna := 0 to oVista.ColumnCount - 1 do
    oVista.Columns[iColumna].Options.Editing := True;
end;

procedure TPanelConfiguracionReparaciones.CrearRejillaExternos;
var
  oVista: TcxGridDBTableView;
  oColumna: TcxGridDBColumn;
begin
  oVista := CrearVista(alClient, 0, FDatos.ExternosEditables);
  oVista.OptionsData.Editing := True;
  oVista.OptionsBehavior.IncSearch := True;
  CrearColumna(oVista, 'CODIGO_PRV_PRV', SColProveedor, 90);
  CrearColumna(oVista, 'RAZON_SOCIAL_PRV', SColRazonSocial, 260);
  HacerCasilla(CrearColumna(oVista, 'ESFACTURACION_DIRECTA_PRV',
    SColFacturacionDirecta, 110));
  oColumna := CrearColumna(oVista, 'MODO_LIQUIDACION_SERVICIOS_PRV',
    SColModoLiquidacion, 200);
  oColumna.Options.Editing := True;
  AgregarOpciones(oColumna, ['', MODO_LIQUIDACION_PERIODICA,
    MODO_LIQUIDACION_LINEA], TextoModoLiquidacionExterno);
end;

end.

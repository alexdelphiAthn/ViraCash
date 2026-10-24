{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraspasoSolicitudesExcel                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construcción nativa DevExpress del libro de solicitudes de traspaso.      }
{    Conserva la estructura cabecera/detalle y una miniatura por artículo.     }
{******************************************************************************}
unit inLibTraspasoSolicitudesExcel;

interface

uses
  Data.DB, dxSpreadSheet, inLibFotos;

procedure ExportarSolicitudesTraspasoExcel(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  AFotos: TFotosArticulos;
  AFechaDesde, AFechaHasta: TDateTime;
  const AResumen: TArray<string> = nil);

implementation

uses
  System.SysUtils, System.Types, System.Generics.Collections,
  Vcl.Graphics,
  cxGraphics,
  dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetContainers,
  dxSpreadSheetGraphics, dxSpreadSheetStyles, dxCoreGraphics,
  dxHashUtils, dxGDIPlusClasses, dxSmartImage,
  inLibDevExcel, inLibFotosTipos,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx,
  inLibResumenSeleccionesHoja;

const
  COL_FOTO = 0;
  COL_LINEA = 1;
  COL_ARTICULO = 2;
  COL_SKU = 3;
  COL_DESCRIPCION = 4;
  COL_PEDIDA = 5;
  COL_SERVIDA = 6;
  COL_PENDIENTE = 7;
  COL_ATENDIDA = 8;
  COL_MOTIVO = 9;
  COL_MAXIMA = COL_MOTIVO;
  TAMANO_FOTO = 64;
  COLOR_TITULO = $00664B32;
  COLOR_SOLICITUD = $00E8D8C9;
  COLOR_CABECERA = $00EEE9E4;
  COLOR_TOTALES = $00F4F1EE;
  FORMATO_CANTIDAD = '#,##0.###;-#,##0.###;0';

type
  TExportadorSolicitudesTraspasoExcel = class
  private
    FControl: TdxSpreadSheet;
    FDatos: TDataSet;
    FFotos: TFotosArticulos;
    FHoja: TdxSpreadSheetTableView;
    FFila: Integer;
    FClaveSolicitud: string;
    FTotalPedida: Double;
    FTotalServida: Double;
    FTotalPendiente: Double;
    FFotosLinea: TDictionary<string, TFotoInfo>;
    FFechaDesde: TDateTime;
    FFechaHasta: TDateTime;
    FResumen: TArray<string>;
    function CalcularAltoTexto(const ATexto: string;
      ACaracteresPorLinea, AAltoLinea, AAltoMinimo: Integer): Integer;
    function CampoNumero(const ANombre: string): Double;
    function CampoTexto(const ANombre: string): string;
    procedure ConfigurarColumnas;
    procedure EscribirCabeceraDetalle;
    procedure EscribirCabeceraSolicitud;
    procedure EscribirDetalle;
    procedure EscribirFecha(AFila, AColumna: Integer;
      AFecha: TDateTime; const AFormato: string);
    procedure EscribirNumero(AFila, AColumna: Integer;
      AValor: Double);
    procedure EscribirSinLineas;
    procedure EscribirTitulo;
    procedure EscribirTotalesSolicitud;
    procedure FormatearFila(AFila: Integer; AColor: TColor;
      ANegrita, ABordeSuperior, ABordeInferior: Boolean);
    procedure IncrustarFoto(AFila: Integer;
      const ACodigoArticulo: string);
    procedure ProcesarDatos;
    function TextoCodigoNombre(
      const ACodigo, ANombre: string): string;
  public
    constructor Create(
      AControl: TdxSpreadSheet;
      const ADatos: TDataSet;
      AFotos: TFotosArticulos;
      AFechaDesde, AFechaHasta: TDateTime);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

constructor TExportadorSolicitudesTraspasoExcel.Create(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  AFotos: TFotosArticulos;
  AFechaDesde, AFechaHasta: TDateTime);
begin
  inherited Create;
  FControl := AControl;
  FDatos := ADatos;
  FFotos := AFotos;
  FFechaDesde := AFechaDesde;
  FFechaHasta := AFechaHasta;
  FFotosLinea := TDictionary<string, TFotoInfo>.Create;
end;

destructor TExportadorSolicitudesTraspasoExcel.Destroy;
begin
  FreeAndNil(FFotosLinea);
  inherited;
end;

function TExportadorSolicitudesTraspasoExcel.CalcularAltoTexto(
  const ATexto: string;
  ACaracteresPorLinea, AAltoLinea, AAltoMinimo: Integer): Integer;
var
  cCaracter: Char;
  iColumna: Integer;
  iLineas: Integer;
begin
  iColumna := 0;
  iLineas := 1;
  for cCaracter in ATexto do
  begin
    if cCaracter = #10 then
    begin
      Inc(iLineas);
      iColumna := 0;
    end
    else if cCaracter <> #13 then
    begin
      Inc(iColumna);
      if iColumna > ACaracteresPorLinea then
      begin
        Inc(iLineas);
        iColumna := 1;
      end;
    end;
  end;
  Result := iLineas * AAltoLinea;
  if Result < AAltoMinimo then
    Result := AAltoMinimo;
end;

function TExportadorSolicitudesTraspasoExcel.CampoNumero(
  const ANombre: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := FDatos.FindField(ANombre);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := oCampo.AsFloat;
end;

function TExportadorSolicitudesTraspasoExcel.CampoTexto(
  const ANombre: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := FDatos.FindField(ANombre);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := oCampo.AsString;
end;

procedure TExportadorSolicitudesTraspasoExcel.ConfigurarColumnas;
begin
  FHoja.Columns[COL_FOTO].Size := 70;
  FHoja.Columns[COL_LINEA].Size := 55;
  FHoja.Columns[COL_ARTICULO].Size := 105;
  FHoja.Columns[COL_SKU].Size := 150;
  FHoja.Columns[COL_DESCRIPCION].Size := 280;
  FHoja.Columns[COL_PEDIDA].Size := 78;
  FHoja.Columns[COL_SERVIDA].Size := 78;
  FHoja.Columns[COL_PENDIENTE].Size := 88;
  FHoja.Columns[COL_ATENDIDA].Size := 78;
  FHoja.Columns[COL_MOTIVO].Size := 240;
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirCabeceraDetalle;
begin
  W(FHoja, FFila, COL_FOTO, 'Foto', True, ssahCenter);
  W(FHoja, FFila, COL_LINEA, 'Línea', True, ssahCenter);
  W(FHoja, FFila, COL_ARTICULO, 'Artículo', True);
  W(FHoja, FFila, COL_SKU, 'SKU / unidad', True);
  W(FHoja, FFila, COL_DESCRIPCION, 'Descripción', True);
  W(FHoja, FFila, COL_PEDIDA, 'Pedida', True, ssahRight);
  W(FHoja, FFila, COL_SERVIDA, 'Servida', True, ssahRight);
  W(FHoja, FFila, COL_PENDIENTE, 'Pendiente', True, ssahRight);
  W(FHoja, FFila, COL_ATENDIDA, 'Atendida', True, ssahCenter);
  W(FHoja, FFila, COL_MOTIVO, 'Motivo de rechazo', True);
  FormatearFila(FFila, COLOR_CABECERA, True, False, True);
  Inc(FFila);
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirCabeceraSolicitud;
var
  sCaja: string;
  sEmpleado: string;
  sObservaciones: string;
  sSolicitada: string;
  sSolicitante: string;
begin
  W(FHoja, FFila, 0,
    'SOLICITUD  ' + CampoTexto('SERIE_TRSOL') + '/' +
    CampoTexto('NUMERO_TRSOL'), True);
  Merge(FHoja, FFila, 0, 5, 1);
  EscribirFecha(
    FFila,
    5,
    FDatos.FieldByName('INSTANTE_ALTA').AsDateTime,
    'dd/mm/yyyy hh:mm');
  Merge(FHoja, FFila, 5, 2, 1);
  W(FHoja, FFila, 7,
    'Estado: ' + CampoTexto('ESTADO_TRSOL'), True, ssahRight);
  Merge(FHoja, FFila, 7, 3, 1);
  FormatearFila(FFila, COLOR_SOLICITUD, True, True, True);
  Inc(FFila);

  sSolicitante := TextoCodigoNombre(
    CampoTexto('CODIGO_EMP_TRSOL'),
    CampoTexto('NOMBRE_EMPRESA_TRSOL')) + ' / ' +
    TextoCodigoNombre(
      CampoTexto('CODIGO_ALM_DESTINO_TRSOL'),
      CampoTexto('NOMBRE_ALMACEN_DESTINO_TRSOL'));
  sSolicitada := TextoCodigoNombre(
    CampoTexto('CODIGO_EMP_CONTRA_TRSOL'),
    CampoTexto('NOMBRE_EMPRESA_CONTRA_TRSOL')) + ' / ' +
    TextoCodigoNombre(
      CampoTexto('CODIGO_ALM_ORIGEN_TRSOL'),
      CampoTexto('NOMBRE_ALMACEN_ORIGEN_TRSOL'));
  W(FHoja, FFila, 0, 'Solicitante:', True);
  W(FHoja, FFila, 1, sSolicitante);
  Merge(FHoja, FFila, 1, 4, 1);
  W(FHoja, FFila, 5, 'Solicitada:', True);
  W(FHoja, FFila, 6, sSolicitada);
  Merge(FHoja, FFila, 6, 4, 1);
  Inc(FFila);

  sCaja := TextoCodigoNombre(
    CampoTexto('CODIGO_CAJA_TRSOL'),
    CampoTexto('NOMBRE_CAJA_TRSOL'));
  sEmpleado := TextoCodigoNombre(
    CampoTexto('CODIGO_EMPLEADO_TRSOL'),
    CampoTexto('NOMBRE_EMPLEADO_TRSOL'));
  W(FHoja, FFila, 0, 'Caja:', True);
  W(FHoja, FFila, 1, sCaja);
  Merge(FHoja, FFila, 1, 4, 1);
  W(FHoja, FFila, 5, 'Empleado:', True);
  W(FHoja, FFila, 6, sEmpleado);
  Merge(FHoja, FFila, 6, 4, 1);
  Inc(FFila);

  sObservaciones := CampoTexto('OBSERVACIONES_TRSOL');
  W(FHoja, FFila, 0, 'Observaciones:', True);
  W(FHoja, FFila, 1, sObservaciones);
  Merge(FHoja, FFila, 1, COL_MAXIMA, 1);
  FHoja.Cells[FFila, 1].Style.WordWrap := True;
  FHoja.Rows[FFila].Size := CalcularAltoTexto(
    sObservaciones, 140, 16, 20);
  Inc(FFila);
  EscribirCabeceraDetalle;
  FTotalPedida := 0;
  FTotalServida := 0;
  FTotalPendiente := 0;
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirDetalle;
var
  dPedida: Double;
  dPendiente: Double;
  dServida: Double;
  iAltoFila: Integer;
  iAltoMotivo: Integer;
  sArticulo: string;
  sDescripcion: string;
  sMotivo: string;
  sSku: string;
begin
  sArticulo := CampoTexto('CODIGO_ART');
  sSku := CampoTexto('SKU_UNIDAD');
  sDescripcion := CampoTexto('DESCRIPCION_ART');
  sMotivo := CampoTexto('MOTIVO_RECHAZO_TRSOLLIN');
  iAltoFila := CalcularAltoTexto(
    sDescripcion, 45, 16, TAMANO_FOTO + 4);
  iAltoMotivo := CalcularAltoTexto(
    sMotivo, 38, 16, TAMANO_FOTO + 4);
  if iAltoMotivo > iAltoFila then
    iAltoFila := iAltoMotivo;
  if sArticulo <> '' then
    IncrustarFoto(FFila, sArticulo)
  else
    W(FHoja, FFila, COL_FOTO, 'Sin artículo', False, ssahCenter);
  W(FHoja, FFila, COL_LINEA,
    CampoTexto('LINEA_TRSOLLIN'), False, ssahCenter);
  W(FHoja, FFila, COL_ARTICULO, sArticulo);
  W(FHoja, FFila, COL_SKU, sSku);
  W(FHoja, FFila, COL_DESCRIPCION, sDescripcion);
  dPedida := CampoNumero('CANTIDAD_PEDIDA_TRSOLLIN');
  dServida := CampoNumero('CANTIDAD_SERVIDA_TRSOLLIN');
  dPendiente := CampoNumero('CANTIDAD_PENDIENTE_TRSOLLIN');
  EscribirNumero(FFila, COL_PEDIDA, dPedida);
  EscribirNumero(FFila, COL_SERVIDA, dServida);
  EscribirNumero(FFila, COL_PENDIENTE, dPendiente);
  W(FHoja, FFila, COL_ATENDIDA,
    CampoTexto('ATENDIDA_TRSOLLIN'), False, ssahCenter);
  W(FHoja, FFila, COL_MOTIVO, sMotivo);
  FHoja.Cells[FFila, COL_DESCRIPCION].Style.WordWrap := True;
  FHoja.Cells[FFila, COL_MOTIVO].Style.WordWrap := True;
  FHoja.Rows[FFila].Size := iAltoFila;
  PintarCuadro(
    FHoja,
    FFila,
    COL_FOTO,
    FFila,
    COL_MAXIMA,
    sscbsThin);
  FTotalPedida := FTotalPedida + dPedida;
  FTotalServida := FTotalServida + dServida;
  FTotalPendiente := FTotalPendiente + dPendiente;
  Inc(FFila);
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirFecha(
  AFila, AColumna: Integer; AFecha: TDateTime;
  const AFormato: string);
begin
  W(FHoja, AFila, AColumna, AFecha, False, ssahCenter);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode := AFormato;
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirNumero(
  AFila, AColumna: Integer; AValor: Double);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
    FORMATO_CANTIDAD;
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirSinLineas;
begin
  W(FHoja, FFila, COL_FOTO, 'Sin líneas solicitadas', False, ssahCenter);
  Merge(FHoja, FFila, COL_FOTO, COL_MAXIMA + 1, 1);
  FHoja.Cells[FFila, COL_FOTO].Style.Font.Style := [fsItalic];
  PintarCuadro(
    FHoja,
    FFila,
    COL_FOTO,
    FFila,
    COL_MAXIMA,
    sscbsThin);
  Inc(FFila);
end;

procedure TExportadorSolicitudesTraspasoExcel.EscribirTitulo;
var
  oServicios: TServiciosHojaCalculo;
begin
  FFila := 1;
  W(FHoja, FFila, 0, 'SOLICITUDES DE TRASPASO', True);
  Merge(FHoja, FFila, 0, COL_MAXIMA + 1, 1);
  FHoja.Cells[FFila, 0].Style.Font.Size := 16;
  FHoja.Cells[FFila, 0].Style.Font.Color := clWhite;
  FormatearFila(FFila, COLOR_TITULO, True, False, False);
  Inc(FFila);
  W(FHoja, FFila, 0, 'Periodo:', True);
  EscribirFecha(FFila, 1, FFechaDesde, 'dd/mm/yyyy');
  W(FHoja, FFila, 2, 'a', False, ssahCenter);
  EscribirFecha(FFila, 3, FFechaHasta, 'dd/mm/yyyy');
  Inc(FFila, 2);
  oServicios := CrearServiciosHojaCalculoDevExTabla(FHoja);
  FFila := EscribirResumenSeleccionesHoja(
    oServicios.Escritor, oServicios.Formateador, FFila, 0,
    FResumen);
end;

procedure TExportadorSolicitudesTraspasoExcel.
  EscribirTotalesSolicitud;
begin
  W(FHoja, FFila, 0, 'TOTAL SOLICITUD', True, ssahRight);
  Merge(FHoja, FFila, 0, COL_PEDIDA, 1);
  EscribirNumero(FFila, COL_PEDIDA, FTotalPedida);
  EscribirNumero(FFila, COL_SERVIDA, FTotalServida);
  EscribirNumero(FFila, COL_PENDIENTE, FTotalPendiente);
  W(FHoja, FFila, COL_ATENDIDA, '');
  W(FHoja, FFila, COL_MOTIVO, '');
  FormatearFila(FFila, COLOR_TOTALES, True, True, True);
  Inc(FFila, 2);
end;

procedure TExportadorSolicitudesTraspasoExcel.FormatearFila(
  AFila: Integer; AColor: TColor;
  ANegrita, ABordeSuperior, ABordeInferior: Boolean);
var
  iColumna: Integer;
begin
  for iColumna := 0 to COL_MAXIMA do
  begin
    FHoja.CreateCell(AFila, iColumna);
    FHoja.Cells[AFila, iColumna].Style.Brush.BackgroundColor := AColor;
    if ANegrita then
      FHoja.Cells[AFila, iColumna].Style.Font.Style := [fsBold];
    if ABordeSuperior then
      FHoja.Cells[AFila, iColumna].Style.Borders[bTop].Style :=
        sscbsThin;
    if ABordeInferior then
      FHoja.Cells[AFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
  end;
end;

procedure TExportadorSolicitudesTraspasoExcel.IncrustarFoto(
  AFila: Integer; const ACodigoArticulo: string);
var
  iAlto: Integer;
  iArriba: Integer;
  iAncho: Integer;
  iIzquierda: Integer;
  oCelda: TdxSpreadSheetCell;
  oFoto: TdxSpreadSheetPictureContainer;
  oImagen: TdxSmartImage;
  oInfo: TFotoInfo;
  sClave: string;
  sRuta: string;
begin
  oInfo := Default(TFotoInfo);
  sClave := ACodigoArticulo;
  if Assigned(FFotos) and
     not FFotosLinea.TryGetValue(sClave, oInfo) then
  begin
    oInfo := FFotos.Resolver(ACodigoArticulo, '');
    FFotosLinea.Add(sClave, oInfo);
  end;
  sRuta := '';
  if Assigned(FFotos) then
    sRuta := FFotos.RutaFoto(oInfo, frPx300);
  if (sRuta <> '') and FileExists(sRuta) then
  begin
    oImagen := TdxSmartImage.Create;
    try
      oImagen.LoadFromFile(sRuta);
      iAncho := oImagen.Width;
      iAlto := oImagen.Height;
      if (iAncho > TAMANO_FOTO) or (iAlto > TAMANO_FOTO) then
      begin
        if iAncho >= iAlto then
        begin
          iAlto := Round(iAlto * TAMANO_FOTO / iAncho);
          iAncho := TAMANO_FOTO;
        end
        else
        begin
          iAncho := Round(iAncho * TAMANO_FOTO / iAlto);
          iAlto := TAMANO_FOTO;
        end;
      end;
      iIzquierda := (TAMANO_FOTO - iAncho) div 2;
      iArriba := (TAMANO_FOTO - iAlto) div 2;
      oCelda := FHoja.CreateCell(AFila, COL_FOTO);
      oFoto := FHoja.Containers.Add(TdxSpreadSheetPictureContainer)
        as TdxSpreadSheetPictureContainer;
      oFoto.Picture.Image := oImagen;
      oFoto.RelativeResize := True;
      oFoto.AnchorType := catOneCell;
      oFoto.AnchorPoint1.Cell := oCelda;
      oFoto.AnchorPoint1.Offset := Point(iIzquierda, iArriba);
      oFoto.AnchorPoint2.Cell := oCelda;
      oFoto.AnchorPoint2.Offset :=
        Point(iIzquierda + iAncho, iArriba + iAlto);
    finally
      FreeAndNil(oImagen);
    end;
  end
  else
    W(FHoja, AFila, COL_FOTO, 'Sin foto', False, ssahCenter);
end;

procedure TExportadorSolicitudesTraspasoExcel.ProcesarDatos;
var
  sClave: string;
begin
  FClaveSolicitud := '';
  if Assigned(FDatos) and FDatos.Active and not FDatos.IsEmpty then
  begin
    FDatos.DisableControls;
    try
      FDatos.First;
      while not FDatos.Eof do
      begin
        sClave := CampoTexto('CLAVE_SOLICITUD');
        if sClave <> FClaveSolicitud then
        begin
          if FClaveSolicitud <> '' then
            EscribirTotalesSolicitud;
          FClaveSolicitud := sClave;
          EscribirCabeceraSolicitud;
        end;
        if FDatos.FieldByName('LINEA_TRSOLLIN').IsNull then
          EscribirSinLineas
        else
          EscribirDetalle;
        FDatos.Next;
      end;
      if FClaveSolicitud <> '' then
        EscribirTotalesSolicitud;
      FDatos.First;
    finally
      FDatos.EnableControls;
    end;
  end;
end;

function TExportadorSolicitudesTraspasoExcel.TextoCodigoNombre(
  const ACodigo, ANombre: string): string;
begin
  Result := Trim(ACodigo);
  if Trim(ANombre) <> '' then
  begin
    if Result <> '' then
      Result := Result + ' - ';
    Result := Result + Trim(ANombre);
  end;
end;

procedure TExportadorSolicitudesTraspasoExcel.Ejecutar;
begin
  FControl.ClearAll;
  FHoja := FControl.AddSheet(
    'Solicitudes de traspaso',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirTitulo;
    ProcesarDatos;
    ConfigurarColumnas;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure ExportarSolicitudesTraspasoExcel(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  AFotos: TFotosArticulos;
  AFechaDesde, AFechaHasta: TDateTime;
  const AResumen: TArray<string>);
var
  oExportador: TExportadorSolicitudesTraspasoExcel;
begin
  oExportador := TExportadorSolicitudesTraspasoExcel.Create(
    AControl,
    ADatos,
    AFotos,
    AFechaDesde,
    AFechaHasta);
  try
    oExportador.FResumen := AResumen;
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.

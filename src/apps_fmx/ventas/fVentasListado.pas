{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasListado                                                }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla principal: ventas de un día, con foto, y el total del día en     }
{    cabecera. Al tocar una línea se abre la ficha con todos los campos.       }
{    La UI se construye por código (sin .fmx).                                 }
{******************************************************************************}
unit fVentasListado;

interface

uses
  FMX.DialogService,  System.Classes, System.SysUtils, System.Threading,
  System.Generics.Collections,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.Layouts,
  FMX.Types, FMX.Graphics, FMX.ListBox,
  VentasApi, VentasModelo;

type
  TElementoListado = record
    EsCierre: Boolean;
    Indice: Integer;
  end;

  TfrmListado = class(TForm)
  private
    FApi: TVentasApi;
    FBotonFiltros: TButton;
    FBuscar: TEdit;
    FCargando: Boolean;
    FColCoste: TLayout;
    FColMargen: TLayout;
    FCierres: TArrCierreVenta;
    FFecha: TDate;
    FFiltro: TFiltroLineas;
    FFotos: TObjectDictionary<string, TBitmap>;
    FGeneracion: Integer;
    FLblEstado: TLabel;
    FLblFecha: TLabel;
    FLineas: TArrLineaVenta;
    FLista: TListBox;
    FOpciones: TOpcionesVentas;
    FTareaDatos: ITask;
    FTareaFotos: ITask;
    FTotalesDia: TTotalesVenta;
    FTruncado: Boolean;
    FValorCoste: TLabel;
    FValorDescuento: TLabel;
    FValorMargen: TLabel;
    FValorVenta: TLabel;
    FVisibles: TArray<Integer>;
    function CasaFiltro(const ALinea: TLineaVenta;
      const ATexto: string): Boolean;
    function CasaFiltroCierre(const ACierre: TCierreVenta;
      const ATexto: string): Boolean;
    function CompararElementos(const AIzquierda,
      ADerecha: TElementoListado): Integer;
    function CrearCabeceraGrupo(const ATitulo: string;
      ANivel: Integer): TListBoxItem;
    function CrearFila(const ALinea: TLineaVenta;
      AIndice: Integer): TListBoxItem;
    function CrearFilaCierre(const ACierre: TCierreVenta;
      AIndice: Integer): TListBoxItem;
    function FotoDeCache(const AClave: string): TBitmap;
    function GeneracionActual: Integer;
    function NuevaFicha(AParent: TFmxObject; const ATitulo: string;
      out AValor: TLabel): TLayout;
    function RutaCacheFoto(const AClave: string): string;
    function TotalesDeVisibles: TTotalesVenta;
    procedure ActualizarBotonFiltros;
    procedure CargarDia;
    procedure ConstruirCabecera;
    procedure ConstruirTotales;
    procedure DescargarFotosEnSegundoPlano(AGeneracion: Integer);
    procedure EsperarTareas;
    procedure MostrarTotales(const ATotales: TTotalesVenta;
      AFiltrado: Boolean);
    procedure OnAyerClick(Sender: TObject);
    procedure OnBuscarCambia(Sender: TObject);
    procedure OnConfigClick(Sender: TObject);
    procedure OnFechaClick(Sender: TObject);
    procedure OnFiltrosClick(Sender: TObject);
    procedure OnLineaClick(const Sender: TCustomListBox;
      const AItem: TListBoxItem);
    procedure OnMananaClick(Sender: TObject);
    procedure PintarLista;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmListado: TfrmListado;

implementation

uses
  System.Types, System.UITypes, System.DateUtils, System.IOUtils,
  System.Hash, System.SyncObjs,
  FMX.Objects, FMX.Dialogs,
  VentasConfig, fVentasConfig, fVentasFicha, fVentasCierre,
  fVentasFiltros, TraduccionMovil, TextosVentas;

const
  // Alto de fila y lado mayor de la miniatura. La foto se guarda en caché ya
  // reducida: una de 300 px descomprimida ocupa unos 360 KB, y repetirla en
  // cada fila se comería la memoria del móvil.
  cAltoFila = 92;
  cLadoMini = 152;
  cTagCabecera = -MaxInt;
  // Nombres en español (claves de TextosVentas) para el rótulo de la fecha.
  cDiasSemana: array[1..7] of string = ('lunes', 'martes', 'miércoles',
    'jueves', 'viernes', 'sábado', 'domingo');
  cMeses: array[1..12] of string = ('enero', 'febrero', 'marzo', 'abril',
    'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre',
    'noviembre', 'diciembre');

function Moneda(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.00', AValor, FormatoIdioma) + ' €';
end;

{ Rótulo largo de la fecha («lunes, 20 de octubre») en el idioma del
  dispositivo. El patrón recibe nombre del día, día, nombre del mes y número
  de mes para que cada idioma ordene las piezas a su manera. }
function FechaLarga(AFecha: TDate): string;
var
  iAnno: Word;
  iDia: Word;
  iMes: Word;
begin
  DecodeDate(AFecha, iAnno, iMes, iDia);
  Result := TrF('%0:s, %1:d de %2:s',
    [Tr(cDiasSemana[DayOfTheWeek(AFecha)]), iDia, Tr(cMeses[iMes]), iMes]);
end;

function TextoGrupo(const ATexto, ATextoVacio: string): string;
begin
  Result := Trim(ATexto);
  if Result = '' then
    Result := ATextoVacio;
end;

function TextoCodigoNombre(const ACodigo, ANombre,
  ATextoVacio: string): string;
var
  sCodigo: string;
  sNombre: string;
begin
  sCodigo := Trim(ACodigo);
  sNombre := Trim(ANombre);
  if sNombre = '' then
    sNombre := sCodigo;
  if sNombre = '' then
    sNombre := ATextoVacio;
  Result := sNombre;
  if (sCodigo <> '') and not SameText(sCodigo, sNombre) then
    Result := sNombre + ' (' + sCodigo + ')';
end;

constructor TfrmListado.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FApi := TVentasApi.Create;
  FFotos := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  FFecha := Date;
  FFiltro := Default(TFiltroLineas);
  FGeneracion := 0;
  FCargando := False;
  FTruncado := False;
  Self.Caption := Tr('Ventas del día');
  ConstruirCabecera;
  ConstruirTotales;
  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := Self;
  FLblEstado.Align := TAlignLayout.Bottom;
  FLblEstado.Height := 30;
  FLblEstado.Margins.Rect := RectF(14, 0, 14, 4);
  FLblEstado.Text := '';
  FBuscar := TEdit.Create(Self);
  FBuscar.Parent := Self;
  FBuscar.Align := TAlignLayout.Top;
  FBuscar.Height := 44;
  FBuscar.Margins.Rect := RectF(12, 4, 12, 6);
  FBuscar.TextPrompt := Tr('Buscar por descripción, SKU, familia…');
  FBuscar.OnChangeTracking := OnBuscarCambia;
  FBotonFiltros := TButton.Create(Self);
  FBotonFiltros.Parent := Self;
  FBotonFiltros.Align := TAlignLayout.Top;
  FBotonFiltros.Height := 42;
  FBotonFiltros.Margins.Rect := RectF(12, 0, 12, 6);
  FBotonFiltros.OnClick := OnFiltrosClick;
  ActualizarBotonFiltros;
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
  FLista.ItemHeight := cAltoFila;
  FLista.ShowScrollBars := True;
  FLista.OnItemClick := OnLineaClick;
  if oConfig.EstaConfigurado then
    CargarDia
  else
    // La configuración no puede abrirse desde el constructor: el formulario
    // principal todavía no está mostrado. Se deja encolada para cuando el
    // bucle de mensajes esté en marcha.
    TThread.ForceQueue(nil,
      procedure
      begin
        OnConfigClick(nil);
      end);
end;

{ Antes de soltar nada hay que asegurarse de que no queda ningún hilo usando
  FApi ni métodos de este formulario, y de drenar lo que ya se hubiera
  encolado hacia el hilo principal. }
destructor TfrmListado.Destroy;
begin
  TInterlocked.Increment(FGeneracion);
  EsperarTareas;
  CheckSynchronize(0);
  FreeAndNil(FApi);
  inherited;
  // Después de inherited: la lista ya no existe y nadie referencia los
  // bitmaps de la caché.
  FreeAndNil(FFotos);
end;

procedure TfrmListado.EsperarTareas;
var
  aTareas: TArray<ITask>;
begin
  SetLength(aTareas, 0);
  if Assigned(FTareaDatos) then
    aTareas := aTareas + [FTareaDatos];
  if Assigned(FTareaFotos) then
    aTareas := aTareas + [FTareaFotos];
  if Length(aTareas) > 0 then
  begin
    try
      TTask.WaitForAll(aTareas, 8000);
    except
      // Una tarea que ya falló no debe impedir cerrar la aplicación.
    end;
  end;
  FTareaDatos := nil;
  FTareaFotos := nil;
end;

{ Lectura del contador con barrera: lo escribe el hilo principal y lo leen
  los hilos de fondo en cada vuelta. }
function TfrmListado.GeneracionActual: Integer;
begin
  Result := TInterlocked.CompareExchange(FGeneracion, 0, 0);
end;

procedure TfrmListado.ConstruirCabecera;
var
  btnAyer: TButton;
  btnConfig: TButton;
  btnManana: TButton;
  layFecha: TLayout;
begin
  layFecha := TLayout.Create(Self);
  layFecha.Parent := Self;
  layFecha.Align := TAlignLayout.Top;
  layFecha.Height := 56;
  btnAyer := TButton.Create(Self);
  btnAyer.Parent := layFecha;
  btnAyer.Align := TAlignLayout.Left;
  btnAyer.Width := 56;
  btnAyer.Margins.Rect := RectF(12, 8, 0, 8);
  btnAyer.Text := '◀';
  btnAyer.OnClick := OnAyerClick;
  btnConfig := TButton.Create(Self);
  btnConfig.Parent := layFecha;
  btnConfig.Align := TAlignLayout.Right;
  btnConfig.Width := 56;
  btnConfig.Margins.Rect := RectF(0, 8, 12, 8);
  btnConfig.Text := '⚙';
  btnConfig.OnClick := OnConfigClick;
  btnManana := TButton.Create(Self);
  btnManana.Parent := layFecha;
  btnManana.Align := TAlignLayout.Right;
  btnManana.Width := 56;
  btnManana.Margins.Rect := RectF(0, 8, 4, 8);
  btnManana.Text := '▶';
  btnManana.OnClick := OnMananaClick;
  FLblFecha := TLabel.Create(Self);
  FLblFecha.Parent := layFecha;
  FLblFecha.Align := TAlignLayout.Client;
  FLblFecha.TextSettings.HorzAlign := TTextAlign.Center;
  FLblFecha.TextSettings.Font.Size := 17;
  FLblFecha.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFecha.StyledSettings := [];
  FLblFecha.OnClick := OnFechaClick;
  FLblFecha.HitTest := True;
end;

{ Cada dato del panel superior es una columna con rótulo pequeño arriba y
  cifra grande debajo. }
function TfrmListado.NuevaFicha(AParent: TFmxObject; const ATitulo: string;
  out AValor: TLabel): TLayout;
var
  lblTitulo: TLabel;
begin
  Result := TLayout.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Width := 96;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Result;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 20;
  lblTitulo.Text := ATitulo;
  lblTitulo.TextSettings.Font.Size := 12;
  lblTitulo.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblTitulo.TextSettings.HorzAlign := TTextAlign.Center;
  lblTitulo.StyledSettings := [];
  AValor := TLabel.Create(Self);
  AValor.Parent := Result;
  AValor.Align := TAlignLayout.Client;
  AValor.Text := '—';
  AValor.TextSettings.Font.Size := 16;
  AValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  AValor.TextSettings.HorzAlign := TTextAlign.Center;
  AValor.StyledSettings := [];
end;

procedure TfrmListado.ConstruirTotales;
var
  layTotales: TLayout;
  scbTotales: THorzScrollBox;
begin
  layTotales := TLayout.Create(Self);
  layTotales.Parent := Self;
  layTotales.Align := TAlignLayout.Top;
  layTotales.Height := 66;
  layTotales.Margins.Rect := RectF(8, 2, 8, 2);
  // En pantallas estrechas las cuatro cifras no caben: se dejan en un
  // scroll horizontal en vez de encogerlas hasta hacerlas ilegibles.
  scbTotales := THorzScrollBox.Create(Self);
  scbTotales.Parent := layTotales;
  scbTotales.Align := TAlignLayout.Client;
  scbTotales.ShowScrollBars := False;
  NuevaFicha(scbTotales, Tr('VENTA'), FValorVenta);
  FColCoste := NuevaFicha(scbTotales, Tr('COSTE'), FValorCoste);
  FColMargen := NuevaFicha(scbTotales, Tr('MARGEN'), FValorMargen);
  NuevaFicha(scbTotales, Tr('DESCUENTO'), FValorDescuento);
end;

procedure TfrmListado.MostrarTotales(const ATotales: TTotalesVenta;
  AFiltrado: Boolean);
var
  sEstado: string;
begin
  FValorVenta.Text := Moneda(ATotales.TotalVenta);
  FValorCoste.Text := Moneda(ATotales.TotalCoste);
  FValorMargen.Text := Moneda(ATotales.TotalMargen) + sLineBreak +
    FormatFloat('#,##0.0', ATotales.PorcentajeMargen, FormatoIdioma) + ' %';
  FValorDescuento.Text := Moneda(ATotales.TotalDescuento);
  FColCoste.Visible := oConfig.MostrarMargen;
  FColMargen.Visible := oConfig.MostrarMargen;
  sEstado := TrF('%d líneas · %s uds', [ATotales.Lineas,
    FormatFloat('#,##0.###', ATotales.Unidades, FormatoIdioma)]);
  if AFiltrado then
    sEstado := sEstado + '  ' + Tr('(filtrado)');
  if FTruncado and not AFiltrado then
    sEstado := sEstado + '  ·  ' +
      TrF('se muestran solo las %d primeras', [Length(FLineas)]);
  FLblEstado.Text := sEstado;
end;

procedure TfrmListado.ActualizarBotonFiltros;
var
  iActivos: Integer;
begin
  iActivos := 0;
  if Trim(FFiltro.Empresa) <> '' then
    Inc(iActivos);
  if Trim(FFiltro.Almacen) <> '' then
    Inc(iActivos);
  if Trim(FFiltro.Temporada) <> '' then
    Inc(iActivos);
  if Trim(FFiltro.Familia) <> '' then
    Inc(iActivos);
  if Trim(FFiltro.Proveedor) <> '' then
    Inc(iActivos);
  if iActivos = 0 then
    FBotonFiltros.Text := Tr('Filtros')
  else
    FBotonFiltros.Text := TrF('Filtros  (%d)', [iActivos]);
end;

procedure TfrmListado.CargarDia;
var
  iGeneracion: Integer;
  oFiltro: TFiltroLineas;
begin
  if not FCargando then
  begin
    FCargando := True;
    TInterlocked.Increment(FGeneracion);
    iGeneracion := GeneracionActual;
    FLblFecha.Text := FechaLarga(FFecha);
    FLblEstado.Text := Tr('Consultando…');
    FLista.Clear;
    oFiltro := FFiltro;
    oFiltro.Fecha := FormatDateTime('yyyy-mm-dd', FFecha);
    oFiltro.Limite := 1000;
    FTareaDatos := TTask.Run(
      procedure
      var
        bOk: Boolean;
        oRespuesta: TRespuestaLineas;
        sError: string;
      begin
        // Cualquier fallo tiene que llegar a la UI: si la tarea muriese sin
        // encolar nada, FCargando se quedaría en True para siempre y la app
        // no volvería a consultar.
        bOk := False;
        oRespuesta := Default(TRespuestaLineas);
        sError := '';
        try
          bOk := FApi.ConsultarLineas(oFiltro, oRespuesta);
          sError := FApi.UltimoError;
        except
          on E: Exception do
          begin
            bOk := False;
            sError := E.Message;
          end;
        end;
        TThread.Queue(nil,
          procedure
          begin
            if iGeneracion = GeneracionActual then
            begin
              FCargando := False;
              if bOk then
              begin
                FCierres := oRespuesta.Cierres;
                FLineas := oRespuesta.Lineas;
                FOpciones := oRespuesta.Opciones;
                FTotalesDia := oRespuesta.Totales;
                FTruncado := oRespuesta.Devueltas < oRespuesta.TotalLineas;
                PintarLista;
                DescargarFotosEnSegundoPlano(iGeneracion);
              end
              else
              begin
                SetLength(FCierres, 0);
                SetLength(FLineas, 0);
                FOpciones := Default(TOpcionesVentas);
                FTotalesDia := Default(TTotalesVenta);
                FTruncado := False;
                PintarLista;
                FLblEstado.Text := sError;
              end;
            end;
          end);
      end);
  end;
end;

function TfrmListado.CasaFiltro(const ALinea: TLineaVenta;
  const ATexto: string): Boolean;
var
  sBolsa: string;
begin
  Result := ATexto = '';
  if not Result then
  begin
    sBolsa := ALinea.Descripcion + ' ' + ALinea.Sku + ' ' +
      ALinea.CodigoFamilia + ' ' + ALinea.Familia + ' ' +
      ALinea.CodigoTemporada + ' ' + ALinea.Temporada + ' ' +
      ALinea.CodigoProveedor + ' ' + ALinea.Proveedor + ' ' +
      ALinea.CodigoAlmacen + ' ' + ALinea.Almacen + ' ' +
      ALinea.Color + ' ' + ALinea.Documento;
    // Con la configuración regional, para que "camison" case con "CAMISÓN".
    Result := Pos(ATexto,
      UpperCase(sBolsa, TLocaleOptions.loUserLocale)) > 0;
  end;
end;

function TfrmListado.CasaFiltroCierre(const ACierre: TCierreVenta;
  const ATexto: string): Boolean;
var
  sBolsa: string;
begin
  Result := ATexto = '';
  if not Result then
  begin
    sBolsa := ACierre.Codigo + ' ' + ACierre.Empresa + ' ' +
      ACierre.Almacen + ' ' + ACierre.Caja + ' ' + ACierre.Fecha;
    Result := Pos(ATexto,
      UpperCase(sBolsa, TLocaleOptions.loUserLocale)) > 0;
  end;
end;

function TfrmListado.CompararElementos(const AIzquierda,
  ADerecha: TElementoListado): Integer;
var
  oCierreDerecha: TCierreVenta;
  oCierreIzquierda: TCierreVenta;
  oLineaDerecha: TLineaVenta;
  oLineaIzquierda: TLineaVenta;
  sAlmacenDerecha: string;
  sAlmacenIzquierda: string;
  sFechaDerecha: string;
  sFechaIzquierda: string;
begin
  oCierreDerecha := Default(TCierreVenta);
  oCierreIzquierda := Default(TCierreVenta);
  oLineaDerecha := Default(TLineaVenta);
  oLineaIzquierda := Default(TLineaVenta);
  if AIzquierda.EsCierre then
  begin
    oCierreIzquierda := FCierres[AIzquierda.Indice];
    sFechaIzquierda := oCierreIzquierda.Fecha;
    sAlmacenIzquierda := oCierreIzquierda.CodigoAlmacen + #1 +
      oCierreIzquierda.Almacen;
  end
  else
  begin
    oLineaIzquierda := FLineas[AIzquierda.Indice];
    sFechaIzquierda := oLineaIzquierda.Fecha;
    sAlmacenIzquierda := oLineaIzquierda.CodigoAlmacen + #1 +
      oLineaIzquierda.Almacen;
  end;
  if ADerecha.EsCierre then
  begin
    oCierreDerecha := FCierres[ADerecha.Indice];
    sFechaDerecha := oCierreDerecha.Fecha;
    sAlmacenDerecha := oCierreDerecha.CodigoAlmacen + #1 +
      oCierreDerecha.Almacen;
  end
  else
  begin
    oLineaDerecha := FLineas[ADerecha.Indice];
    sFechaDerecha := oLineaDerecha.Fecha;
    sAlmacenDerecha := oLineaDerecha.CodigoAlmacen + #1 +
      oLineaDerecha.Almacen;
  end;
  Result := -CompareText(sFechaIzquierda, sFechaDerecha);
  if (Result = 0) and FOpciones.EsMultialmacen then
    Result := CompareText(sAlmacenIzquierda, sAlmacenDerecha);
  if Result = 0 then
  begin
    if AIzquierda.EsCierre <> ADerecha.EsCierre then
    begin
      if AIzquierda.EsCierre then
        Result := -1
      else
        Result := 1;
    end
    else if AIzquierda.EsCierre then
    begin
      Result := -CompareText(
        oCierreIzquierda.InstanteCierre,
        oCierreDerecha.InstanteCierre);
      if Result = 0 then
        Result := CompareText(
          oCierreIzquierda.Codigo,
          oCierreDerecha.Codigo);
    end
    else
    begin
      Result := CompareText(
        oLineaIzquierda.CodigoTemporada + #1 +
          oLineaIzquierda.Temporada,
        oLineaDerecha.CodigoTemporada + #1 +
          oLineaDerecha.Temporada);
      if Result = 0 then
        Result := CompareText(
          oLineaIzquierda.CodigoFamilia + #1 +
            oLineaIzquierda.Familia,
          oLineaDerecha.CodigoFamilia + #1 +
            oLineaDerecha.Familia);
      if Result = 0 then
        Result := CompareText(
          oLineaIzquierda.CodigoProveedor + #1 +
            oLineaIzquierda.Proveedor,
          oLineaDerecha.CodigoProveedor + #1 +
            oLineaDerecha.Proveedor);
      if Result = 0 then
        Result := -CompareText(
          oLineaIzquierda.Hora,
          oLineaDerecha.Hora);
      if Result = 0 then
        Result := CompareText(
          oLineaIzquierda.Documento,
          oLineaDerecha.Documento);
      if Result = 0 then
        Result := CompareText(
          oLineaIzquierda.Linea,
          oLineaDerecha.Linea);
    end;
  end;
end;

function TfrmListado.TotalesDeVisibles: TTotalesVenta;
var
  iIndice: Integer;
  oLinea: TLineaVenta;
begin
  Result := Default(TTotalesVenta);
  for iIndice in FVisibles do
  begin
    oLinea := FLineas[iIndice];
    Inc(Result.Lineas);
    Result.Unidades := Result.Unidades + oLinea.Cantidad;
    Result.TotalVenta := Result.TotalVenta + oLinea.TotalLinea;
    Result.TotalVentaSiva := Result.TotalVentaSiva + oLinea.TotalLineaSiva;
    Result.TotalCoste := Result.TotalCoste + oLinea.TotalCoste;
    Result.TotalDescuento :=
      Result.TotalDescuento + oLinea.ImporteDescuento;
  end;
  Result.TotalMargen := Result.TotalVentaSiva - Result.TotalCoste;
  if Result.TotalVentaSiva <> 0 then
    Result.PorcentajeMargen :=
      Result.TotalMargen / Result.TotalVentaSiva * 100;
end;

{ Los bitmaps los guarda el formulario, no los items: varias líneas del
  mismo artículo comparten uno y así se carga del disco una sola vez. }
function TfrmListado.FotoDeCache(const AClave: string): TBitmap;
var
  iAlto: Integer;
  iAncho: Integer;
  oBitmap: TBitmap;
  oMini: TBitmap;
  sRuta: string;
begin
  Result := nil;
  if not FFotos.TryGetValue(AClave, Result) then
  begin
    sRuta := RutaCacheFoto(AClave);
    if TFile.Exists(sRuta) then
    begin
      oBitmap := TBitmap.Create;
      try
        try
          oBitmap.LoadFromFile(sRuta);
          // Se reduce guardando la proporción: CreateThumbnail estira si se
          // le dan las dos medidas a lo bruto.
          if oBitmap.Width >= oBitmap.Height then
          begin
            iAncho := cLadoMini;
            iAlto := Round(oBitmap.Height * cLadoMini / oBitmap.Width);
          end
          else
          begin
            iAlto := cLadoMini;
            iAncho := Round(oBitmap.Width * cLadoMini / oBitmap.Height);
          end;
          if iAncho < 1 then
            iAncho := 1;
          if iAlto < 1 then
            iAlto := 1;
          oMini := oBitmap.CreateThumbnail(iAncho, iAlto);
          FFotos.Add(AClave, oMini);
          Result := oMini;
        except
          // PNG corrupto o a medio escribir: se descarta sin romper la lista.
          Result := nil;
        end;
      finally
        FreeAndNil(oBitmap);
      end;
    end;
  end;
end;

function TfrmListado.CrearCabeceraGrupo(const ATitulo: string;
  ANivel: Integer): TListBoxItem;
begin
  Result := TListBoxItem.Create(FLista);
  Result.Parent := FLista;
  Result.Height := 34;
  Result.Padding.Left := 8 + (ANivel * 14);
  Result.Text := ATitulo;
  Result.Tag := cTagCabecera;
  Result.Selectable := False;
  Result.HitTest := False;
  Result.TextSettings.Font.Size := 13;
  Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  Result.TextSettings.FontColor := TAlphaColorRec.Darkslategray;
  Result.StyledSettings := [];
end;

function TfrmListado.CrearFilaCierre(const ACierre: TCierreVenta;
  AIndice: Integer): TListBoxItem;
var
  layTexto: TLayout;
  lblImporte: TLabel;
  lblPie: TLabel;
  lblTitulo: TLabel;
  sPie: string;
begin
  Result := TListBoxItem.Create(FLista);
  Result.Parent := FLista;
  Result.Height := 76;
  Result.Text := '';
  Result.Tag := -(AIndice + 1);
  layTexto := TLayout.Create(Result);
  layTexto.Parent := Result;
  layTexto.Align := TAlignLayout.Client;
  layTexto.Margins.Rect := RectF(18, 8, 10, 8);
  layTexto.HitTest := False;
  lblTitulo := TLabel.Create(Result);
  lblTitulo.Parent := layTexto;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 28;
  lblTitulo.Text := TrF('CIERRE DE CAJA  ·  %s', [ACierre.Codigo]);
  lblTitulo.TextSettings.Font.Size := 15;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.TextSettings.FontColor := TAlphaColorRec.Darkgreen;
  lblTitulo.StyledSettings := [];
  lblTitulo.HitTest := False;
  lblImporte := TLabel.Create(Result);
  lblImporte.Parent := layTexto;
  lblImporte.Align := TAlignLayout.Right;
  lblImporte.Width := 130;
  lblImporte.Text := Moneda(ACierre.Resumen.TotalVentas);
  lblImporte.TextSettings.Font.Size := 14;
  lblImporte.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblImporte.TextSettings.HorzAlign := TTextAlign.Trailing;
  lblImporte.StyledSettings := [];
  lblImporte.HitTest := False;
  sPie := TextoGrupo(ACierre.Hora, Tr('sin hora'));
  if Trim(ACierre.Caja) <> '' then
    sPie := sPie + '  ·  ' + TrF('Caja %s', [ACierre.Caja]);
  sPie := sPie + '  ·  ' +
    TrF('Diferencia %s', [Moneda(ACierre.Resumen.DiferenciaTotal)]);
  lblPie := TLabel.Create(Result);
  lblPie.Parent := layTexto;
  lblPie.Align := TAlignLayout.Client;
  lblPie.Text := sPie;
  lblPie.TextSettings.Font.Size := 12;
  lblPie.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblPie.StyledSettings := [];
  lblPie.HitTest := False;
end;

{ Cada fila lleva miniatura y tres líneas: descripción, la terna
  familia / temporada / proveedor, y abajo hora y SKU con el importe a la
  derecha. Se compone a mano porque las apariencias de serie de FMX solo
  dan dos líneas de texto. }
function TfrmListado.CrearFila(const ALinea: TLineaVenta;
  AIndice: Integer): TListBoxItem;
var
  imgFoto: TImage;
  layPie: TLayout;
  layTexto: TLayout;
  lblClasif: TLabel;
  lblImporte: TLabel;
  lblPie: TLabel;
  lblTitulo: TLabel;
  oFoto: TBitmap;
  sClasif: string;
  sImporte: string;
  sPie: string;

  procedure Agregar(const ATrozo: string; var ADestino: string);
  begin
    if Trim(ATrozo) <> '' then
    begin
      if ADestino <> '' then
        ADestino := ADestino + '  ·  ';
      ADestino := ADestino + Trim(ATrozo);
    end;
  end;

begin
  Result := TListBoxItem.Create(FLista);
  Result.Parent := FLista;
  Result.Height := cAltoFila;
  Result.Text := '';
  Result.Tag := AIndice;
  imgFoto := TImage.Create(Result);
  imgFoto.Parent := Result;
  imgFoto.Align := TAlignLayout.Left;
  imgFoto.Width := 84;
  imgFoto.Margins.Rect := RectF(4, 6, 0, 6);
  imgFoto.WrapMode := TImageWrapMode.Fit;
  imgFoto.HitTest := False;
  oFoto := FotoDeCache(ALinea.ClaveFoto);
  if Assigned(oFoto) then
    imgFoto.Bitmap.Assign(oFoto);
  layTexto := TLayout.Create(Result);
  layTexto.Parent := Result;
  layTexto.Align := TAlignLayout.Client;
  layTexto.Margins.Rect := RectF(8, 8, 10, 8);
  layTexto.HitTest := False;
  lblTitulo := TLabel.Create(Result);
  lblTitulo.Parent := layTexto;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 24;
  lblTitulo.Text := ALinea.TituloLinea;
  lblTitulo.TextSettings.Font.Size := 15;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  lblTitulo.HitTest := False;
  sClasif := '';
  Agregar(ALinea.Familia, sClasif);
  Agregar(ALinea.Temporada, sClasif);
  Agregar(ALinea.Proveedor, sClasif);
  lblClasif := TLabel.Create(Result);
  lblClasif.Parent := layTexto;
  lblClasif.Align := TAlignLayout.Top;
  lblClasif.Height := 22;
  lblClasif.Text := sClasif;
  lblClasif.TextSettings.Font.Size := 13;
  lblClasif.StyledSettings := [TStyledSetting.FontColor];
  lblClasif.HitTest := False;
  layPie := TLayout.Create(Result);
  layPie.Parent := layTexto;
  layPie.Align := TAlignLayout.Top;
  layPie.Height := 22;
  layPie.HitTest := False;
  sImporte := Moneda(ALinea.TotalLinea);
  if ALinea.ImporteDescuento > 0 then
    sImporte := sImporte + '  −' +
      FormatFloat('#,##0.##', ALinea.PorcentajeDescuento, FormatoIdioma) +
      '%';
  lblImporte := TLabel.Create(Result);
  lblImporte.Parent := layPie;
  lblImporte.Align := TAlignLayout.Right;
  lblImporte.Width := 150;
  lblImporte.Text := sImporte;
  lblImporte.TextSettings.Font.Size := 14;
  lblImporte.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblImporte.TextSettings.HorzAlign := TTextAlign.Trailing;
  lblImporte.StyledSettings := [];
  lblImporte.HitTest := False;
  sPie := '';
  Agregar(ALinea.Hora, sPie);
  Agregar(ALinea.Sku, sPie);
  lblPie := TLabel.Create(Result);
  lblPie.Parent := layPie;
  lblPie.Align := TAlignLayout.Client;
  lblPie.Text := sPie;
  lblPie.TextSettings.Font.Size := 12;
  lblPie.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblPie.StyledSettings := [];
  lblPie.HitTest := False;
end;

procedure TfrmListado.PintarLista;
var
  aElementos: TArray<TElementoListado>;
  bFiltrado: Boolean;
  iCierre: Integer;
  iElemento: Integer;
  iLinea: Integer;
  iNivelClasificacion: Integer;
  iOrden: Integer;
  iPosicion: Integer;
  oCierre: TCierreVenta;
  oElemento: TElementoListado;
  oLinea: TLineaVenta;
  oTemporal: TElementoListado;
  sAlmacen: string;
  sClaveAlmacen: string;
  sClaveFamilia: string;
  sClaveProveedor: string;
  sClaveTemporada: string;
  sFamilia: string;
  sFecha: string;
  sProveedor: string;
  sTexto: string;
  sTemporada: string;
  sUltimoAlmacen: string;
  sUltimaFamilia: string;
  sUltimaFecha: string;
  sUltimoProveedor: string;
  sUltimaTemporada: string;
begin
  sTexto := UpperCase(Trim(FBuscar.Text), TLocaleOptions.loUserLocale);
  bFiltrado := sTexto <> '';
  SetLength(aElementos, 0);
  SetLength(FVisibles, 0);
  for iLinea := 0 to High(FLineas) do
  begin
    oLinea := FLineas[iLinea];
    if CasaFiltro(oLinea, sTexto) then
    begin
      FVisibles := FVisibles + [iLinea];
      oElemento.EsCierre := False;
      oElemento.Indice := iLinea;
      aElementos := aElementos + [oElemento];
    end;
  end;
  for iCierre := 0 to High(FCierres) do
  begin
    oCierre := FCierres[iCierre];
    if CasaFiltroCierre(oCierre, sTexto) then
    begin
      oElemento.EsCierre := True;
      oElemento.Indice := iCierre;
      aElementos := aElementos + [oElemento];
    end;
  end;
  for iOrden := 1 to High(aElementos) do
  begin
    oTemporal := aElementos[iOrden];
    iPosicion := iOrden - 1;
    while (iPosicion >= 0) and
          (CompararElementos(oTemporal, aElementos[iPosicion]) < 0) do
    begin
      aElementos[iPosicion + 1] := aElementos[iPosicion];
      Dec(iPosicion);
    end;
    aElementos[iPosicion + 1] := oTemporal;
  end;
  sUltimaFecha := #0;
  sUltimoAlmacen := #0;
  sUltimaTemporada := #0;
  sUltimaFamilia := #0;
  sUltimoProveedor := #0;
  FLista.BeginUpdate;
  try
    FLista.Clear;
    for iElemento := 0 to High(aElementos) do
    begin
      oElemento := aElementos[iElemento];
      if oElemento.EsCierre then
      begin
        oCierre := FCierres[oElemento.Indice];
        sFecha := oCierre.Fecha;
        sAlmacen := TextoCodigoNombre(
          oCierre.CodigoAlmacen,
          oCierre.Almacen,
          Tr('sin almacén'));
        sClaveAlmacen := oCierre.CodigoAlmacen + #1 +
          oCierre.Almacen;
      end
      else
      begin
        oLinea := FLineas[oElemento.Indice];
        sFecha := oLinea.Fecha;
        sAlmacen := TextoCodigoNombre(
          oLinea.CodigoAlmacen,
          oLinea.Almacen,
          Tr('sin almacén'));
        sClaveAlmacen := oLinea.CodigoAlmacen + #1 +
          oLinea.Almacen;
      end;
      if not SameText(sFecha, sUltimaFecha) then
      begin
        CrearCabeceraGrupo(
          Tr('Fecha') + '  ·  ' +
            TextoGrupo(FechaVisible(sFecha), Tr('sin fecha')), 0);
        sUltimaFecha := sFecha;
        sUltimoAlmacen := #0;
        sUltimaTemporada := #0;
        sUltimaFamilia := #0;
        sUltimoProveedor := #0;
      end;
      if FOpciones.EsMultialmacen and
         not SameText(sClaveAlmacen, sUltimoAlmacen) then
      begin
        CrearCabeceraGrupo(
          Tr('Almacén') + '  ·  ' +
            TextoGrupo(sAlmacen, Tr('sin almacén')), 1);
        sUltimoAlmacen := sClaveAlmacen;
        sUltimaTemporada := #0;
        sUltimaFamilia := #0;
        sUltimoProveedor := #0;
      end;
      if oElemento.EsCierre then
      begin
        CrearFilaCierre(oCierre, oElemento.Indice);
        sUltimaTemporada := #0;
        sUltimaFamilia := #0;
        sUltimoProveedor := #0;
      end
      else
      begin
        if FOpciones.EsMultialmacen then
          iNivelClasificacion := 2
        else
          iNivelClasificacion := 1;
        sTemporada := TextoCodigoNombre(
          oLinea.CodigoTemporada,
          oLinea.Temporada,
          Tr('sin temporada'));
        sFamilia := TextoCodigoNombre(
          oLinea.CodigoFamilia,
          oLinea.Familia,
          Tr('sin familia'));
        sProveedor := TextoCodigoNombre(
          oLinea.CodigoProveedor,
          oLinea.Proveedor,
          Tr('sin proveedor'));
        sClaveTemporada := oLinea.CodigoTemporada + #1 +
          oLinea.Temporada;
        sClaveFamilia := oLinea.CodigoFamilia + #1 + oLinea.Familia;
        sClaveProveedor := oLinea.CodigoProveedor + #1 +
          oLinea.Proveedor;
        if not SameText(sClaveTemporada, sUltimaTemporada) then
        begin
          CrearCabeceraGrupo(
            Tr('Temporada') + '  ·  ' + sTemporada,
            iNivelClasificacion);
          sUltimaTemporada := sClaveTemporada;
          sUltimaFamilia := #0;
          sUltimoProveedor := #0;
        end;
        if not SameText(sClaveFamilia, sUltimaFamilia) then
        begin
          CrearCabeceraGrupo(
            Tr('Familia') + '  ·  ' + sFamilia,
            iNivelClasificacion + 1);
          sUltimaFamilia := sClaveFamilia;
          sUltimoProveedor := #0;
        end;
        if not SameText(sClaveProveedor, sUltimoProveedor) then
        begin
          CrearCabeceraGrupo(
            Tr('Proveedor') + '  ·  ' + sProveedor,
            iNivelClasificacion + 2);
          sUltimoProveedor := sClaveProveedor;
        end;
        CrearFila(oLinea, oElemento.Indice);
      end;
    end;
  finally
    FLista.EndUpdate;
  end;
  if bFiltrado then
    MostrarTotales(TotalesDeVisibles, True)
  else
    MostrarTotales(FTotalesDia, False);
end;

function TfrmListado.RutaCacheFoto(const AClave: string): string;
begin
  // TPath cualificado: FMX.Objects declara otro TPath (la figura vectorial)
  // que tapa al de System.IOUtils.
  Result := System.IOUtils.TPath.Combine(oConfig.RutaCacheFotos,
    THashMD5.GetHashString(AClave) + '.png');
end;

{ Las fotos se piden una sola vez por artículo y color, después de pintar la
  lista, para que el listado salga de inmediato aunque la red vaya lenta. }
procedure TfrmListado.DescargarFotosEnSegundoPlano(AGeneracion: Integer);
var
  aClaves: TArray<string>;
  aDestinos: TArray<string>;
  aRutas: TArray<string>;
  iGeneracion: Integer;
  iLinea: Integer;
  oLinea: TLineaVenta;
  sClaves: TStringList;
begin
  // La generación se copia a una local: las closures anidadas capturan
  // variables del método, no sus parámetros.
  iGeneracion := AGeneracion;
  SetLength(aClaves, 0);
  SetLength(aRutas, 0);
  SetLength(aDestinos, 0);
  sClaves := TStringList.Create;
  try
    sClaves.Sorted := True;
    sClaves.Duplicates := dupIgnore;
    for iLinea := 0 to High(FLineas) do
    begin
      oLinea := FLineas[iLinea];
      if (oLinea.FotoRuta <> '') and
         (sClaves.IndexOf(oLinea.ClaveFoto) < 0) and
         not TFile.Exists(RutaCacheFoto(oLinea.ClaveFoto)) then
      begin
        sClaves.Add(oLinea.ClaveFoto);
        aClaves := aClaves + [oLinea.ClaveFoto];
        aRutas := aRutas + [oLinea.FotoRuta];
        // La ruta de destino se resuelve aquí, en el hilo principal: el de
        // fondo no debe tocar métodos del formulario.
        aDestinos := aDestinos + [RutaCacheFoto(oLinea.ClaveFoto)];
      end;
    end;
  finally
    FreeAndNil(sClaves);
  end;
  if Length(aRutas) > 0 then
  begin
    FTareaFotos := TTask.Run(
      procedure
      var
        iDescargadas: Integer;
        iPendiente: Integer;
        oApi: TVentasApi;
        sErrorFoto: string;
      begin
        iDescargadas := 0;
        iPendiente := 0;
        sErrorFoto := '';
        try
          // API propia del hilo: THTTPClient no se comparte entre hilos.
          oApi := TVentasApi.Create;
          try
            // Se corta en cuanto cambia la generación: el usuario ya está
            // mirando otro día y estas fotos ya no interesan.
            while (iPendiente <= High(aRutas)) and
                  (iGeneracion = GeneracionActual) do
            begin
              if oApi.DescargarFoto(aRutas[iPendiente],
                                    aDestinos[iPendiente]) then
                Inc(iDescargadas)
              else if sErrorFoto = '' then
                sErrorFoto := oApi.UltimoError;
              Inc(iPendiente);
            end;
          finally
            FreeAndNil(oApi);
          end;
        except
          on E: Exception do
            if sErrorFoto = '' then
              sErrorFoto := E.Message;
        end;
        // Si no ha entrado ninguna foto se dice por qué: casi siempre es
        // que la credencial no lleva el ámbito fotos:leer (403) o que ese
        // artículo no tiene foto subida al servidor (404).
        TThread.Queue(nil,
          procedure
          begin
            if iGeneracion = GeneracionActual then
            begin
              if iDescargadas > 0 then
                PintarLista;
              if (iDescargadas = 0) and (sErrorFoto <> '') then
                FLblEstado.Text := FLblEstado.Text + '  ·  ' +
                  TrF('fotos: %s', [sErrorFoto]);
            end;
          end);
      end);
  end;
end;

procedure TfrmListado.OnAyerClick(Sender: TObject);
begin
  // Mientras hay una consulta en marcha no se mueve la fecha: si no, el
  // rótulo y FFecha se desincronizarían.
  if not FCargando then
  begin
    FFecha := IncDay(FFecha, -1);
    CargarDia;
  end;
end;

procedure TfrmListado.OnMananaClick(Sender: TObject);
begin
  if not FCargando then
  begin
    FFecha := IncDay(FFecha, 1);
    CargarDia;
  end;
end;

procedure TfrmListado.OnFechaClick(Sender: TObject);
begin
  if (not FCargando) and (FFecha <> Date) then
  begin
    FFecha := Date;
    CargarDia;
  end;
end;

procedure TfrmListado.OnFiltrosClick(Sender: TObject);
begin
  if not FCargando then
    TfrmFiltrosVentas.Mostrar(
      Self,
      FOpciones,
      FFiltro,
      procedure(const AFiltro: TFiltroLineas)
      begin
        FFiltro := AFiltro;
        ActualizarBotonFiltros;
        CargarDia;
      end);
end;

procedure TfrmListado.OnBuscarCambia(Sender: TObject);
begin
  PintarLista;
end;

procedure TfrmListado.OnConfigClick(Sender: TObject);
begin
  if oConfig.ConfiguracionCentral then
    TDialogService.ShowMessage(
      Tr('Configuración en el menú de ViraCash móvil.'))
  else
    TfrmConfig.EditarAsync(Self,
    procedure(AGuardado: Boolean)
    begin
      if AGuardado and oConfig.EstaConfigurado then
        CargarDia;
    end);
end;

procedure TfrmListado.OnLineaClick(const Sender: TCustomListBox;
  const AItem: TListBoxItem);
var
  iCierre: Integer;
  iLinea: Integer;
begin
  if Assigned(AItem) then
  begin
    iLinea := Integer(AItem.Tag);
    if (iLinea >= 0) and (iLinea <= High(FLineas)) then
      TfrmFicha.Mostrar(Self, FLineas[iLinea],
        RutaCacheFoto(FLineas[iLinea].ClaveFoto))
    else if iLinea <> cTagCabecera then
    begin
      iCierre := -iLinea - 1;
      if (iCierre >= 0) and (iCierre <= High(FCierres)) then
        TfrmCierreVenta.Mostrar(Self, FCierres[iCierre]);
    end;
  end;
end;

end.

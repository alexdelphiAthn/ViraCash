{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotoMiniaturaMtoVcl                                      }
{    Tipo:       Presentador VCL                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Miniatura fija (foto a 600 px) del artículo / SKU activo en la barra      }
{    lateral derecha de un mantenimiento. Sigue el registro con los mismos     }
{    resolutor y DataSources que la foto flotante de Ctrl+F, y al pulsarla     }
{    ejecuta esa misma acción. Recibe las piezas, nunca el formulario.         }
{******************************************************************************}
unit inLibFotoMiniaturaMtoVcl;

interface

uses
  System.Classes, System.Generics.Collections,
  Data.DB,
  Vcl.Controls, Vcl.ExtCtrls,
  cxImage,
  inLibFotos, inLibGestorArticulosMto;

type
  // Avisa de cualquier cambio de registro activo de un DataSource sin
  // tocar su OnDataChange (que ya encadena la foto flotante de Ctrl+F).
  TEnlaceMiniaturaFoto = class(TDataLink)
  private
    FAlCambiar: TNotifyEvent;
    procedure Avisar;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(ADataSource: TDataSource; AAlCambiar: TNotifyEvent);
  end;

  // Se coloca bajo ADebajoDe dentro de AContenedor y baja los controles
  // sueltos (botones) que hubiera por debajo para hacerle hueco. La carga
  // se difiere con un temporizador: los DataSources de las líneas los
  // asignan los descendientes después de crearla, y así tampoco se lee
  // disco en cada fila mientras se recorre la rejilla con las flechas.
  TMiniaturaFotoMto = class(TComponent)
  private
    FImagen             : TcxImage;
    FTemporizador       : TTimer;
    FFotos              : TFotosArticulos;
    FResolver           : TResolverArtSkuMto;
    FObtenerDataSources : TObtenerDataSourcesFotoMto;
    FAccionAbrir        : TBasicAction;
    FAlPulsar           : TNotifyEvent;
    FEnlaces            : TObjectList<TEnlaceMiniaturaFoto>;
    FArticulo           : string;
    FSku                : string;
    FRuta               : string;
    procedure Colocar(AContenedor: TWinControl; ADebajoDe: TControl);
    procedure CrearImagen(AContenedor: TWinControl);
    procedure CrearTemporizador;
    procedure Vincular;
    procedure Programar(Sender: TObject);
    procedure AlVencer(Sender: TObject);
    procedure Refrescar;
    procedure MostrarRuta(const ARuta: string);
    procedure AlPulsar(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; AContenedor: TWinControl;
      ADebajoDe: TControl; AFotos: TFotosArticulos;
      AResolver: TResolverArtSkuMto;
      AObtenerDataSources: TObtenerDataSourcesFotoMto;
      AAccionAbrir: TBasicAction); reintroduce;
    // Variante para rejillas sin DataSource (modales): la miniatura ocupa
    // APanel entero y quien la usa llama a Actualizar al cambiar de fila.
    constructor CreateEnPanel(AOwner: TComponent; APanel: TWinControl;
      AFotos: TFotosArticulos; AResolver: TResolverArtSkuMto;
      AAlPulsar: TNotifyEvent);
    destructor Destroy; override;
    // Vuelve a preguntar el artículo / SKU (con la misma espera).
    procedure Actualizar;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.UITypes,
  Vcl.Graphics,
  cxEdit, cxGraphics,
  inLibFotosMiniaturasGridVcl, inLibMsgFotos;

const
  // Medidas a 96 ppp; se escalan al PPI del contenedor.
  cLadoMiniaturaMto   = 140;
  cMargenMiniaturaMto = 8;
  // Espera tras el último cambio de registro antes de leer la foto.
  cEsperaMiniaturaMs  = 120;

{ TEnlaceMiniaturaFoto }

constructor TEnlaceMiniaturaFoto.Create(ADataSource: TDataSource;
  AAlCambiar: TNotifyEvent);
begin
  inherited Create;
  FAlCambiar := AAlCambiar;
  DataSource := ADataSource;
end;

procedure TEnlaceMiniaturaFoto.Avisar;
begin
  if Assigned(FAlCambiar) then
    FAlCambiar(Self);
end;

procedure TEnlaceMiniaturaFoto.ActiveChanged;
begin
  inherited;
  Avisar;
end;

procedure TEnlaceMiniaturaFoto.DataSetChanged;
begin
  inherited;
  Avisar;
end;

procedure TEnlaceMiniaturaFoto.DataSetScrolled(Distance: Integer);
begin
  inherited;
  Avisar;
end;

procedure TEnlaceMiniaturaFoto.RecordChanged(Field: TField);
begin
  inherited;
  // Como la foto flotante: solo el cambio de registro, no cada campo.
  if Field = nil then
    Avisar;
end;

{ TMiniaturaFotoMto }

constructor TMiniaturaFotoMto.Create(AOwner: TComponent;
  AContenedor: TWinControl; ADebajoDe: TControl; AFotos: TFotosArticulos;
  AResolver: TResolverArtSkuMto;
  AObtenerDataSources: TObtenerDataSourcesFotoMto;
  AAccionAbrir: TBasicAction);
begin
  inherited Create(AOwner);
  FFotos := AFotos;
  FResolver := AResolver;
  FObtenerDataSources := AObtenerDataSources;
  FAccionAbrir := AAccionAbrir;
  FEnlaces := TObjectList<TEnlaceMiniaturaFoto>.Create(True);
  Colocar(AContenedor, ADebajoDe);
  CrearTemporizador;
end;

constructor TMiniaturaFotoMto.CreateEnPanel(AOwner: TComponent;
  APanel: TWinControl; AFotos: TFotosArticulos;
  AResolver: TResolverArtSkuMto; AAlPulsar: TNotifyEvent);
begin
  inherited Create(AOwner);
  FFotos := AFotos;
  FResolver := AResolver;
  FAlPulsar := AAlPulsar;
  FEnlaces := TObjectList<TEnlaceMiniaturaFoto>.Create(True);
  CrearImagen(APanel);
  FImagen.Align := alClient;
  CrearTemporizador;
end;

procedure TMiniaturaFotoMto.CrearTemporizador;
begin
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Interval := cEsperaMiniaturaMs;
  FTemporizador.OnTimer := AlVencer;
  // Primera pasada: vincula y pinta en cuanto el Mto termine de montarse.
  FTemporizador.Enabled := True;
end;

procedure TMiniaturaFotoMto.Actualizar;
begin
  Programar(Self);
end;

destructor TMiniaturaFotoMto.Destroy;
begin
  if Assigned(FTemporizador) then
    FTemporizador.Enabled := False;
  FreeAndNil(FEnlaces);
  inherited;
end;

procedure TMiniaturaFotoMto.Colocar(AContenedor: TWinControl;
  ADebajoDe: TControl);
var
  iControl : Integer;
  iDesplaza: Integer;
  iLado    : Integer;
  iMargen  : Integer;
  iTop     : Integer;
  oControl : TControl;
begin
  iLado := MulDiv(cLadoMiniaturaMto, AContenedor.CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iMargen := MulDiv(cMargenMiniaturaMto, AContenedor.CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iTop := 0;
  if Assigned(ADebajoDe) then
    iTop := ADebajoDe.Top + ADebajoDe.Height;
  iDesplaza := iLado + (2 * iMargen);
  // Los botones de la barra van colocados a mano: se bajan los que estén
  // por debajo del punto de inserción para no taparlos.
  for iControl := 0 to AContenedor.ControlCount - 1 do
  begin
    oControl := AContenedor.Controls[iControl];
    if (oControl.Align = alNone) and (oControl.Top >= iTop) then
      oControl.Top := oControl.Top + iDesplaza;
  end;
  CrearImagen(AContenedor);
  FImagen.SetBounds(iMargen, iTop + iMargen,
    AContenedor.ClientWidth - (2 * iMargen), iLado);
  FImagen.Anchors := [akLeft, akTop, akRight];
end;

procedure TMiniaturaFotoMto.CrearImagen(AContenedor: TWinControl);
begin
  FImagen := TcxImage.Create(Self);
  FImagen.Parent := AContenedor;
  FImagen.Properties.FitMode := ifmProportionalStretch;
  FImagen.Properties.PopupMenuLayout.MenuItems := [];
  FImagen.Properties.ReadOnly := True;
  FImagen.Properties.ShowFocusRect := False;
  FImagen.Style.BorderStyle := ebsNone;
  FImagen.StyleFocused.BorderStyle := ebsNone;
  FImagen.StyleHot.BorderStyle := ebsNone;
  FImagen.Transparent := True;
  FImagen.TabStop := False;
  FImagen.Cursor := crHandPoint;
  FImagen.ShowHint := True;
  FImagen.Hint := SHintMiniaturaFotoMto;
  FImagen.OnClick := AlPulsar;
end;

procedure TMiniaturaFotoMto.Vincular;
var
  aActuales  : TArray<TDataSource>;
  bIguales   : Boolean;
  iIndice    : Integer;
  oDataSource: TDataSource;
begin
  // Se vuelve a preguntar en cada pasada: la rejilla puede cambiar de
  // DataSource (el pivote de tallas en horizontal monta una copia en
  // memoria) y Ctrl+F escucha ya el nuevo; sin esto la miniatura seguiría
  // el DataSource del montaje y se quedaría en otra línea.
  aActuales := nil;
  if Assigned(FObtenerDataSources) then
    for oDataSource in FObtenerDataSources() do
      if Assigned(oDataSource) then
        aActuales := aActuales + [oDataSource];
  bIguales := Length(aActuales) = FEnlaces.Count;
  iIndice := 0;
  while bIguales and (iIndice < FEnlaces.Count) do
  begin
    bIguales := FEnlaces[iIndice].DataSource = aActuales[iIndice];
    Inc(iIndice);
  end;
  if not bIguales then
  begin
    FEnlaces.Clear;
    for oDataSource in aActuales do
      FEnlaces.Add(TEnlaceMiniaturaFoto.Create(oDataSource, Programar));
  end;
end;

procedure TMiniaturaFotoMto.Programar(Sender: TObject);
begin
  // Los DataSources se sueltan solos al liberarse (TDataLink); el
  // temporizador muere con el Mto, que es su dueño.
  if not (csDestroying in ComponentState) then
  begin
    // Reinicia la espera: al recorrer filas solo se carga la última.
    FTemporizador.Enabled := False;
    FTemporizador.Enabled := True;
  end;
end;

procedure TMiniaturaFotoMto.AlVencer(Sender: TObject);
begin
  FTemporizador.Enabled := False;
  // Un Mto cerrado aun recibe mensajes hasta que se libera (caFree).
  if Assigned(Owner) and (csDestroying in Owner.ComponentState) then
    Exit;
  Vincular;
  Refrescar;
end;

procedure TMiniaturaFotoMto.Refrescar;
var
  aFotos: TArray<TFotoInfo>;
  sArt  : string;
  sRuta : string;
  sSku  : string;
begin
  sArt := '';
  sSku := '';
  if Assigned(FResolver) then
    FResolver(sArt, sSku);
  if (sArt <> FArticulo) or (sSku <> FSku) then
  begin
    FArticulo := sArt;
    FSku := sSku;
    sRuta := '';
    if (sArt <> '') and Assigned(FFotos) then
    begin
      try
        // La misma foto con la que abre Ctrl+F (la primera de la colección
        // del artículo / SKU), a 600 px o, si falta, la que haya.
        aFotos := FFotos.ResolverColeccion(sArt, sSku);
        if Length(aFotos) > 0 then
        begin
          sRuta := FFotos.RutaFoto(aFotos[0], frPx600);
          if sRuta = '' then
            sRuta := FFotos.RutaFoto(aFotos[0], frReal);
          if sRuta = '' then
            sRuta := FFotos.RutaFoto(aFotos[0], frPx300);
        end;
      except
        // Sin conexión o sin acceso a la carpeta de fotos: sin miniatura,
        // y sin un diálogo de error en cada cambio de fila.
        sRuta := '';
      end;
    end;
    MostrarRuta(sRuta);
  end;
end;

procedure TMiniaturaFotoMto.MostrarRuta(const ARuta: string);
var
  oBitmap: Vcl.Graphics.TBitmap;
  iLado  : Integer;
begin
  if not SameText(ARuta, FRuta) then
  begin
    FRuta := ARuta;
    oBitmap := nil;
    if ARuta <> '' then
    begin
      iLado := FImagen.Width;
      if FImagen.Height < iLado then
        iLado := FImagen.Height;
      // Conservar detalle al ampliar la barra tras una ventana pequena.
      if iLado < MulDiv(cLadoMiniaturaMto, FImagen.CurrentPPI,
        USER_DEFAULT_SCREEN_DPI) then
        iLado := MulDiv(cLadoMiniaturaMto, FImagen.CurrentPPI,
          USER_DEFAULT_SCREEN_DPI);
      try
        oBitmap := CrearMiniaturaFotoPng(ARuta, iLado);
      except
        // Una foto ilegible deja la miniatura vacía, como sin foto.
        oBitmap := nil;
      end;
    end;
    try
      FImagen.Picture.Assign(oBitmap);
    finally
      FreeAndNil(oBitmap);
    end;
  end;
end;

procedure TMiniaturaFotoMto.AlPulsar(Sender: TObject);
begin
  if Assigned(FAccionAbrir) then
    FAccionAbrir.Execute
  else if Assigned(FAlPulsar) then
    FAlPulsar(Self);
end;

end.

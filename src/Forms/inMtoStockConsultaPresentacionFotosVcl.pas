{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionFotosVcl                        }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pestanas de fotos de articulos relacionados (familia, proveedor y         }
{    temporada) de la consulta de stock: filtros cruzados, tarjetas y cache.   }
{    Recibe el lector de catalogos y el proveedor de fotos por constructor;    }
{    nunca el formulario.                                                      }
{******************************************************************************}
unit inMtoStockConsultaPresentacionFotosVcl;

interface

uses
  System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics, Vcl.Forms,
  Vcl.Imaging.pngimage,
  Data.DB,
  cxControls, cxContainer, cxEdit, cxGraphics,
  cxButtons, cxLabel, cxPC,
  inLibFotos,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaPresentacionFotos;

type
  TNavegarArticuloRelacionado = reference to procedure(
    const ACodigoArticulo: string);

  TPresentadorFotosRelacionadasStock = class
  private
    FEstado: TEstadoFotosRelacionadas;
    FPestanas: array[TDimensionFotos] of TcxTabSheet;
    FPaginas: TcxPageControl;
    FContenedor: TScrollBox;
    FRejilla: TWinControl;
    FBotonFiltro1: TcxButton;
    FBotonFiltro2: TcxButton;
    FLector: ILectorCatalogosStockConsulta;
    FFotos: TFotosArticulos;
    FNavegar: TNavegarArticuloRelacionado;
    FCodigoArticulo: string;
    procedure BotonFiltroClick(Sender: TObject);
    procedure TarjetaDblClick(Sender: TObject);
    procedure ConfigurarFiltros(ADimension: TDimensionFotos);
    procedure PintarTarjeta(AIndice, AColumnas: Integer;
      ADataSet: TDataSet;
      AFotos: TDictionary<string, TFotoInfo>);
    procedure PintarFotoTarjeta(APanel: TPanel;
      const ARuta, ADescripcion, AArticulo: string);
    procedure PrepararDobleClick(AControl: TControl;
      const AArticulo: string);
  public
    constructor Create(
      AOwner: TComponent;
      APaginas: TcxPageControl;
      AContenedorTarjetas: TWinControl;
      ARejilla: TWinControl;
      const ACaptionFamilia, ACaptionProveedor,
            ACaptionTemporada: string;
      const ALector: ILectorCatalogosStockConsulta;
      AFotos: TFotosArticulos;
      const ANavegar: TNavegarArticuloRelacionado);
    destructor Destroy; override;
    function DimensionActiva(out ADimension: TDimensionFotos): Boolean;
    procedure FijarArticulo(const ACodigoArticulo: string);
    procedure ReiniciarDimensionActiva;
    procedure MostrarVista(AVisible: Boolean);
    procedure MostrarMensaje(const AMensaje: string);
    procedure LimpiarTarjetas;
    procedure Cargar(ADimension: TDimensionFotos);
    procedure CargarSiProcede;
  end;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

const
  ALTO_BOTON_FILTRO_FOTOS = 26;
  ANCHO_BOTON_FILTRO_FOTOS = 128;
  ALTO_IMAGEN_TARJETA = 118;
  MARGEN_INTERIOR_TARJETA = 8;
  TOP_TITULO_TARJETA = 130;
  ALTO_TITULO_TARJETA = 38;
  TOP_DETALLE_TARJETA = 168;
  ALTO_DETALLE_TARJETA = 62;
  CAMPO_ARTICULO_RELACIONADO = 'CODIGO_ART_ART';
  CAMPO_DESCRIPCION_RELACIONADA = 'DESCRIPCION_ART';
  CAMPO_COLORES_RELACIONADOS = 'COLORES';
  CAMPO_TALLAS_RELACIONADAS = 'TALLAS';

constructor TPresentadorFotosRelacionadasStock.Create(
  AOwner: TComponent;
  APaginas: TcxPageControl;
  AContenedorTarjetas: TWinControl;
  ARejilla: TWinControl;
  const ACaptionFamilia, ACaptionProveedor,
        ACaptionTemporada: string;
  const ALector: ILectorCatalogosStockConsulta;
  AFotos: TFotosArticulos;
  const ANavegar: TNavegarArticuloRelacionado);
var
  Dimension: TDimensionFotos;
  Pestana: TcxTabSheet;
begin
  inherited Create;
  FEstado := TEstadoFotosRelacionadas.Create;
  FPaginas := APaginas;
  FRejilla := ARejilla;
  FLector := ALector;
  FFotos := AFotos;
  FNavegar := ANavegar;
  for Dimension := Low(TDimensionFotos) to High(TDimensionFotos) do
  begin
    Pestana := TcxTabSheet.Create(AOwner);
    Pestana.PageControl := APaginas;
    case Dimension of
      dfFamilia:
        Pestana.Caption := ACaptionFamilia;
      dfProveedor:
        Pestana.Caption := ACaptionProveedor;
      dfTemporada:
        Pestana.Caption := ACaptionTemporada;
    end;
    FPestanas[Dimension] := Pestana;
  end;
  FContenedor := TScrollBox.Create(AOwner);
  FContenedor.Parent := AContenedorTarjetas;
  FContenedor.Align := alClient;
  FContenedor.BorderStyle := bsNone;
  FContenedor.Visible := False;
  FBotonFiltro1 := TcxButton.Create(AOwner);
  FBotonFiltro1.Parent := FContenedor;
  FBotonFiltro1.SetBounds(12, 10, ANCHO_BOTON_FILTRO_FOTOS,
    ALTO_BOTON_FILTRO_FOTOS);
  FBotonFiltro1.OnClick := BotonFiltroClick;
  FBotonFiltro2 := TcxButton.Create(AOwner);
  FBotonFiltro2.Parent := FContenedor;
  FBotonFiltro2.SetBounds(148, 10, ANCHO_BOTON_FILTRO_FOTOS,
    ALTO_BOTON_FILTRO_FOTOS);
  FBotonFiltro2.OnClick := BotonFiltroClick;
end;

destructor TPresentadorFotosRelacionadasStock.Destroy;
begin
  LimpiarTarjetas;
  FNavegar := nil;
  FLector := nil;
  FFotos := nil;
  FreeAndNil(FEstado);
  inherited Destroy;
end;

function TPresentadorFotosRelacionadasStock.DimensionActiva(
  out ADimension: TDimensionFotos): Boolean;
var
  Dimension: TDimensionFotos;
begin
  Result := False;
  for Dimension := Low(TDimensionFotos) to High(TDimensionFotos) do
    if FPaginas.ActivePage = FPestanas[Dimension] then
    begin
      ADimension := Dimension;
      Result := True;
    end;
end;

// Al cambiar de articulo se invalida la cache de las tres dimensiones y
// la siguiente visita a una pestana vuelve a consultar.
procedure TPresentadorFotosRelacionadasStock.FijarArticulo(
  const ACodigoArticulo: string);
begin
  FCodigoArticulo := ACodigoArticulo;
  FEstado.Invalidar;
end;

procedure TPresentadorFotosRelacionadasStock.ReiniciarDimensionActiva;
var
  Dimension: TDimensionFotos;
begin
  if DimensionActiva(Dimension) then
    FEstado.Reiniciar(Dimension);
end;

// Las tarjetas y la rejilla comparten hueco: solo una de las dos esta
// visible en cada momento.
procedure TPresentadorFotosRelacionadasStock.MostrarVista(
  AVisible: Boolean);
begin
  if FContenedor <> nil then
  begin
    FRejilla.Visible := not AVisible;
    FContenedor.Visible := AVisible;
    if AVisible then
      FContenedor.BringToFront
    else
      FRejilla.BringToFront;
  end
  else
    FRejilla.Visible := True;
end;

procedure TPresentadorFotosRelacionadasStock.LimpiarTarjetas;
var
  i: Integer;
  Control: TControl;
begin
  if FContenedor <> nil then
    for i := FContenedor.ControlCount - 1 downto 0 do
    begin
      Control := FContenedor.Controls[i];
      if (Control <> FBotonFiltro1) and (Control <> FBotonFiltro2) then
        Control.Free;
    end;
end;

procedure TPresentadorFotosRelacionadasStock.MostrarMensaje(
  const AMensaje: string);
var
  Etiqueta: TcxLabel;
begin
  if FContenedor <> nil then
  begin
    LimpiarTarjetas;
    Etiqueta := TcxLabel.Create(FContenedor);
    Etiqueta.Parent := FContenedor;
    Etiqueta.SetBounds(16, 50, FContenedor.ClientWidth - 32, 40);
    Etiqueta.AutoSize := False;
    Etiqueta.Caption := AMensaje;
    Etiqueta.Properties.WordWrap := True;
    Etiqueta.Transparent := True;
  end;
end;

procedure TPresentadorFotosRelacionadasStock.ConfigurarFiltros(
  ADimension: TDimensionFotos);
var
  Filtros: TArray<TDimensionFotos>;
  procedure ConfigurarBoton(ABoton: TcxButton;
    AFiltro: TDimensionFotos);
  begin
    ABoton.Tag := Ord(AFiltro);
    ABoton.Caption := EtiquetaFiltroFotos(AFiltro,
      FEstado.FiltroActivo(ADimension, AFiltro));
    ABoton.Visible := True;
  end;
begin
  Filtros := FEstado.FiltrosSecundarios(ADimension);
  if (FBotonFiltro1 <> nil) and (FBotonFiltro2 <> nil) then
  begin
    ConfigurarBoton(FBotonFiltro1, Filtros[0]);
    ConfigurarBoton(FBotonFiltro2, Filtros[1]);
    FBotonFiltro1.BringToFront;
    FBotonFiltro2.BringToFront;
  end;
end;

procedure TPresentadorFotosRelacionadasStock.BotonFiltroClick(
  Sender: TObject);
var
  Dimension: TDimensionFotos;
  Filtro: TDimensionFotos;
begin
  if DimensionActiva(Dimension) and (Sender is TcxButton) then
  begin
    Filtro := TDimensionFotos(TcxButton(Sender).Tag);
    FEstado.AlternarFiltro(Dimension, Filtro);
    ConfigurarFiltros(Dimension);
    Cargar(Dimension);
  end;
end;

procedure TPresentadorFotosRelacionadasStock.CargarSiProcede;
var
  Dimension: TDimensionFotos;
begin
  if DimensionActiva(Dimension) then
  begin
    ConfigurarFiltros(Dimension);
    if FEstado.DebeRecargar(Dimension, FCodigoArticulo) then
      Cargar(Dimension);
  end;
end;

procedure TPresentadorFotosRelacionadasStock.Cargar(
  ADimension: TDimensionFotos);
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
  Solicitud: TSolicitudFotosRelacionadasStock;
  Codigos: TList<string>;
  Fotos: TDictionary<string, TFotoInfo>;
  Articulos: TArray<string>;
  i: Integer;
  iColumnas: Integer;
begin
  LimpiarTarjetas;
  ConfigurarFiltros(ADimension);
  FEstado.IniciarCarga(ADimension, FCodigoArticulo);
  if Trim(FCodigoArticulo) = '' then
  begin
    MostrarMensaje(SErrorArticuloStockNoSeleccionadoFotos);
    FEstado.MarcarCargada(ADimension);
  end
  else
  begin
    Screen.Cursor := crHourGlass;
    Codigos := TList<string>.Create;
    Fotos := nil;
    try
      Solicitud.CodigoArticulo := FCodigoArticulo;
      Solicitud.Dimension := ADimension;
      Solicitud.Filtros := FEstado.Filtros[ADimension];
      Resultado := FLector.ConsultarFotosRelacionadas(Solicitud);
      Datos := Resultado.DataSet;
      if Datos.IsEmpty then
        MostrarMensaje(SInfoArticulosRelacionadosStockNoDisponibles)
      else
      begin
        while not Datos.Eof do
        begin
          Codigos.Add(
            Datos.FieldByName(CAMPO_ARTICULO_RELACIONADO).AsString);
          Datos.Next;
        end;
        SetLength(Articulos, Codigos.Count);
        for i := 0 to Codigos.Count - 1 do
          Articulos[i] := Codigos[i];
        Fotos := FFotos.ResolverArticulosLote(Articulos);
        Datos.First;
        iColumnas := ColumnasTarjetasFotos(FContenedor.ClientWidth);
        i := 0;
        while not Datos.Eof do
        begin
          PintarTarjeta(i, iColumnas, Datos, Fotos);
          Inc(i);
          Datos.Next;
        end;
      end;
      FEstado.MarcarCargada(ADimension);
    finally
      FreeAndNil(Fotos);
      FreeAndNil(Codigos);
      Resultado := nil;
      Screen.Cursor := crDefault;
    end;
  end;
end;

// El articulo viaja en el Hint del control para que el doble clic sepa
// a donde navegar. OnDblClick se asigna en cada control concreto porque
// TControl no lo publica.
procedure TPresentadorFotosRelacionadasStock.PrepararDobleClick(
  AControl: TControl; const AArticulo: string);
begin
  AControl.Hint := AArticulo;
  AControl.ShowHint := True;
  AControl.Cursor := crHandPoint;
end;

// Si el articulo tiene foto se muestra a 300 px; si no, un rotulo con su
// descripcion ocupando el mismo hueco.
procedure TPresentadorFotosRelacionadasStock.PintarFotoTarjeta(
  APanel: TPanel; const ARuta, ADescripcion, AArticulo: string);
var
  Imagen: TImage;
  Etiqueta: TLabel;
  Png: TPngImage;
begin
  if ARuta <> '' then
  begin
    Imagen := TImage.Create(APanel);
    Imagen.Parent := APanel;
    Imagen.SetBounds(MARGEN_INTERIOR_TARJETA, MARGEN_INTERIOR_TARJETA,
      ANCHO_TARJETA_FOTO_STOCK - 16, ALTO_IMAGEN_TARJETA);
    Imagen.Center := True;
    Imagen.Proportional := True;
    Imagen.Stretch := True;
    PrepararDobleClick(Imagen, AArticulo);
    Imagen.OnDblClick := TarjetaDblClick;
    Png := TPngImage.Create;
    try
      Png.LoadFromFile(ARuta);
      Imagen.Picture.Assign(Png);
    finally
      FreeAndNil(Png);
    end;
  end
  else
  begin
    Etiqueta := TLabel.Create(APanel);
    Etiqueta.Parent := APanel;
    Etiqueta.SetBounds(MARGEN_INTERIOR_TARJETA,
      MARGEN_INTERIOR_TARJETA,
      ANCHO_TARJETA_FOTO_STOCK - 16, ALTO_IMAGEN_TARJETA);
    Etiqueta.AutoSize := False;
    Etiqueta.Caption := ADescripcion;
    Etiqueta.Alignment := taCenter;
    Etiqueta.Layout := tlCenter;
    Etiqueta.WordWrap := True;
    Etiqueta.Transparent := False;
    Etiqueta.Color := clWindow;
    Etiqueta.Font.Color := clWindowText;
    PrepararDobleClick(Etiqueta, AArticulo);
    Etiqueta.OnDblClick := TarjetaDblClick;
  end;
end;

procedure TPresentadorFotosRelacionadasStock.PintarTarjeta(
  AIndice, AColumnas: Integer; ADataSet: TDataSet;
  AFotos: TDictionary<string, TFotoInfo>);
var
  Panel: TPanel;
  Etiqueta: TLabel;
  Info: TFotoInfo;
  sArticulo: string;
  sDescripcion: string;
  sRuta: string;
  sColores: string;
  sTallas: string;
  iX: Integer;
  iY: Integer;
begin
  sArticulo :=
    ADataSet.FieldByName(CAMPO_ARTICULO_RELACIONADO).AsString;
  sDescripcion :=
    ADataSet.FieldByName(CAMPO_DESCRIPCION_RELACIONADA).AsString;
  sColores :=
    Trim(ADataSet.FieldByName(CAMPO_COLORES_RELACIONADOS).AsString);
  sTallas :=
    Trim(ADataSet.FieldByName(CAMPO_TALLAS_RELACIONADAS).AsString);
  if sColores = '' then
    sColores := 'sin color';
  if sTallas = '' then
    sTallas := 'sin talla';
  PosicionTarjetaFotos(AIndice, AColumnas, iX, iY);
  Panel := TPanel.Create(FContenedor);
  Panel.Parent := FContenedor;
  Panel.SetBounds(iX, iY, ANCHO_TARJETA_FOTO_STOCK,
    ALTO_TARJETA_FOTO_STOCK);
  Panel.BevelOuter := bvLowered;
  Panel.Color := clWindow;
  Panel.ParentBackground := False;
  PrepararDobleClick(Panel, sArticulo);
  Panel.OnDblClick := TarjetaDblClick;
  sRuta := '';
  if (AFotos <> nil) and AFotos.TryGetValue(sArticulo, Info) then
    sRuta := FFotos.RutaFoto(Info, frPx300);
  PintarFotoTarjeta(Panel, sRuta, sDescripcion, sArticulo);
  Etiqueta := TLabel.Create(Panel);
  Etiqueta.Parent := Panel;
  Etiqueta.SetBounds(MARGEN_INTERIOR_TARJETA, TOP_TITULO_TARJETA,
    ANCHO_TARJETA_FOTO_STOCK - 16, ALTO_TITULO_TARJETA);
  Etiqueta.AutoSize := False;
  Etiqueta.Caption := sArticulo;
  Etiqueta.Font.Style := [fsBold];
  Etiqueta.Font.Color := clWindowText;
  Etiqueta.WordWrap := True;
  Etiqueta.Transparent := False;
  Etiqueta.Color := clWindow;
  PrepararDobleClick(Etiqueta, sArticulo);
  Etiqueta.OnDblClick := TarjetaDblClick;
  Etiqueta := TLabel.Create(Panel);
  Etiqueta.Parent := Panel;
  Etiqueta.SetBounds(MARGEN_INTERIOR_TARJETA, TOP_DETALLE_TARJETA,
    ANCHO_TARJETA_FOTO_STOCK - 16, ALTO_DETALLE_TARJETA);
  Etiqueta.AutoSize := False;
  Etiqueta.Caption := Format(SCaptionColoresTallas,
    [sColores, sTallas]);
  Etiqueta.Font.Height := -11;
  Etiqueta.Font.Color := clWindowText;
  Etiqueta.WordWrap := True;
  Etiqueta.Transparent := False;
  Etiqueta.Color := clWindow;
  PrepararDobleClick(Etiqueta, sArticulo);
  Etiqueta.OnDblClick := TarjetaDblClick;
end;

procedure TPresentadorFotosRelacionadasStock.TarjetaDblClick(
  Sender: TObject);
begin
  if (Sender is TControl) and Assigned(FNavegar) then
    FNavegar(TControl(Sender).Hint);
end;

end.

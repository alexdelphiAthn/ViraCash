unit inLibMenuIconos;

{
  Iconos del menu principal de ViraCash.

  Cada PNG se llama igual que el TMenuItem al que pertenece, y en el .res
  cada uno da lugar a cuatro recursos RCDATA:

      MNUEMPRESAS_16  MNUEMPRESAS_24  MNUEMPRESAS_32  MNUEMPRESAS_48

  De ahi que no haga falta ninguna tabla de indices: se recorre el menu,
  se busca el recurso que se llama como el componente y se carga.

  Requiere Delphi 10.3 Rio o superior (TImageCollection).
}

interface

uses
  System.Classes, System.SysUtils, Vcl.Menus, Vcl.ImageCollection,
  Vcl.Graphics;

const
  /// Tamanos disponibles de cada icono, de menor a mayor.
  TAMANOS_ICONO: array[0..3] of Integer = (16, 24, 32, 48);

/// Recorre el menu y carga en ACollection, desde los recursos enlazados
/// con IconosMenu.res, el icono de cada item que tenga uno. Devuelve el
/// numero de iconos cargados.
function CargarIconosDesdeRecursos(ACollection: TImageCollection;
  AItems: TMenuItem): Integer;

// Carga el PNG de mayor resolucion del item directamente del ejecutable.
// Si no existe, deja la imagen vacia y devuelve False.
function CargarIconoMenuMaximaResolucion(const ANombreItem: string;
  AImagen: TPicture): Boolean;

/// Variante que lee los PNG de disco: <ADir>\16x16\*.png, 24x24, etc.
//function CargarIconosDesdeCarpeta(ACollection: TImageCollection;
//  const ADir: string): Integer;

/// Asigna a cada item el icono cuyo nombre coincide con el del componente.
/// Los items sin icono se dejan con ImageIndex = -1.
function AsignarIconosMenu(AItems: TMenuItem;
  ACollection: TImageCollection): Integer;

implementation

uses
  Winapi.Windows, System.IOUtils, System.Types,
  dxGDIPlusClasses, dxGDIPlusApi;

type
  // Conserva el PNG original y suaviza cada dibujo al tamano del control.
  // TPngImage amplifica los escalones al estirarse en pantallas con DPI alto.
  TIconoMenuPNG = class(TdxPNGImage)
  protected
    procedure Draw(ACanvas: TCanvas; const ARect: TRect); override;
  end;

procedure TIconoMenuPNG.Draw(ACanvas: TCanvas; const ARect: TRect);
var
  oLienzo: TdxGPCustomPaintCanvas;
begin
  if not Empty and (ARect.Width > 0) and (ARect.Height > 0) then
  begin
    oLienzo := TdxGPCustomPaintCanvas.Create;
    try
      oLienzo.BeginPaint(ACanvas.Handle, ARect);
      try
        oLienzo.InterpolationMode := imHighQualityBicubic;
        oLienzo.PixelOffsetMode := PixelOffsetModeHalf;
        StretchDraw(oLienzo, ARect, ClientRect, nil);
      finally
        oLienzo.EndPaint;
      end;
    finally
      oLienzo.Free;
    end;
  end;
end;

function ExisteRecurso(const ANombre: string): Boolean;
begin
  Result := FindResource(HInstance, PChar(ANombre), RT_RCDATA) <> 0;
end;

function CargarIconoMenuMaximaResolucion(const ANombreItem: string;
  AImagen: TPicture): Boolean;
var
  iTamano: Integer;
  sRecurso: string;
  oFlujo: TResourceStream;
  oPng: TIconoMenuPNG;
begin
  Result := False;
  AImagen.Assign(nil);
  iTamano := High(TAMANOS_ICONO);
  while (iTamano >= Low(TAMANOS_ICONO)) and not Result do
  begin
    sRecurso := UpperCase(ANombreItem) + '_' +
      IntToStr(TAMANOS_ICONO[iTamano]);
    if ExisteRecurso(sRecurso) then
    begin
      oFlujo := TResourceStream.Create(HInstance, sRecurso, RT_RCDATA);
      try
        oPng := TIconoMenuPNG.Create;
        try
          oPng.LoadFromStream(oFlujo);
          AImagen.Assign(oPng);
          Result := True;
        finally
          oPng.Free;
        end;
      finally
        oFlujo.Free;
      end;
    end;
    Dec(iTamano);
  end;
end;

function CargarIconosDesdeRecursos(ACollection: TImageCollection;
  AItems: TMenuItem): Integer;
var
  Total: Integer;

  procedure Recorrer(AMenu: TMenuItem);
  var
    I, T: Integer;
    Nombre, Recurso: string;
    Cargado: Boolean;
  begin
    for I := 0 to AMenu.Count - 1 do
    begin
      Nombre := AMenu[I].Name;

      if (Nombre <> '') and (ACollection.GetIndexByName(Nombre) < 0) then
      begin
        Cargado := False;

        // Cada llamada a Add con el mismo nombre agrega una resolucion mas
        // al mismo item de la coleccion; el TVirtualImageList elegira
        // despues la que corresponda al DPI activo.
        for T in TAMANOS_ICONO do
        begin
          Recurso := UpperCase(Nombre) + '_' + IntToStr(T);
          if ExisteRecurso(Recurso) then
          begin
            ACollection.Add(Nombre, HInstance, Recurso);
            Cargado := True;
          end;
        end;

        if Cargado then
          Inc(Total);
      end;

      if AMenu[I].Count > 0 then
        Recorrer(AMenu[I]);
    end;
  end;

begin
  Total := 0;
  Recorrer(AItems);
  Result := Total;
end;
(*
function CargarIconosDesdeCarpeta(ACollection: TImageCollection;
  const ADir: string): Integer;
var
  DirBase, Ruta, RutaT, Nombre: string;
  T: Integer;
begin
  Result := 0;
  DirBase := IncludeTrailingPathDelimiter(ADir);
  if not TDirectory.Exists(DirBase + '16x16') then
    raise Exception.CreateFmt('No se encuentran los iconos en %s', [DirBase]);

  // El listado de 16x16 marca el juego completo de iconos disponibles.
  for Ruta in TDirectory.GetFiles(DirBase + '16x16', '*.png') do
  begin
    Nombre := TPath.GetFileNameWithoutExtension(Ruta);
    if ACollection.GetIndexByName(Nombre) >= 0 then
      Continue;

    for T in TAMANOS_ICONO do
    begin
      RutaT := Format('%s%dx%d\%s.png', [DirBase, T, T, Nombre]);
      if TFile.Exists(RutaT) then
        ACollection.Add(Nombre, RutaT);
    end;

    Inc(Result);
  end;
end;*)

function AsignarIconosMenu(AItems: TMenuItem;
  ACollection: TImageCollection): Integer;
var
  I, Idx: Integer;
begin
  Result := 0;
  for I := 0 to AItems.Count - 1 do
  begin
    if AItems[I].Caption <> '-' then
    begin
      Idx := ACollection.GetIndexByName(AItems[I].Name);
      if Idx >= 0 then
      begin
        AItems[I].ImageIndex := Idx;
        Inc(Result);
      end;
    end;

    if AItems[I].Count > 0 then
      Inc(Result, AsignarIconosMenu(AItems[I], ACollection));
  end;
end;

{
  ------------------------------------------------------------------------
  USO EN EL OnCreate DEL FORMULARIO PRINCIPAL
  ------------------------------------------------------------------------

    icoMenu.Images.Clear;
    CargarIconosDesdeRecursos(icoMenu, jvMnMenuPrin.Items);

    vilMenu.ImageCollection := icoMenu;
    vilMenu.AutoFill := True;    // imprescindible: replica la coleccion
    vilMenu.SetSize(16, 16);     // 16 a 96 ppp; escala solo en High-DPI

    jvMnMenuPrin.Images := vilMenu;
    AsignarIconosMenu(jvMnMenuPrin.Items, icoMenu);

  icoMenu es un TImageCollection y vilMenu un TVirtualImageList, ambos
  soltados sobre el formulario desde la paleta.

  AutoFill = True es lo que garantiza que el indice dentro del
  TVirtualImageList coincida con el de la coleccion. Si prefieres no
  usarlo, sustituye en AsignarIconosMenu la coleccion por el propio
  TVirtualImageList y llama a su GetIndexByName.
}

end.

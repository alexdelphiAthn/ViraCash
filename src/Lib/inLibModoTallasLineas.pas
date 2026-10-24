{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasLineas                                         }
{    Tipo:       Librería (adaptador de dataset)                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador de los puertos de lineas de tallas sobre el cds. Aísla          }
{    los casos de uso del dataset: recorrido, borrado programático y los       }
{    hooks AfterPost / AfterScroll que recargan las celdas. La escritura       }
{    campo a campo vive en TEscrituraLineasTallas.                            }
{******************************************************************************}
unit inLibModoTallasLineas;

interface

uses
  System.SysUtils, System.Classes, System.Variants, Data.DB,
  inLibModoTallasIntf;

type
  // Lectura y escritura campo a campo de una linea del documento.
  TEscrituraLineasTallas = class
  private
    FCds: TDataSet;
    FCampos: TCamposLineasTallas;
    FRegistro: TRegistroTallas;
    function LocalizarLinea(ALinea: Integer): Boolean;
    procedure PonerLineaNueva(ALinea: Integer);
    function ContarAtributos(const ANombres: TValoresAttrTallas;
      AOrdenTalla: Integer): Integer;
    procedure EscribirTallaYCantidad(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion);
    function LineaCoincide(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; APrecio: Double): Boolean;
    function LocalizarSinPrecio(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas): Boolean;
    function TotalLineaPivotada(
      const ATotales: TArray<TTotalLineaTallas>;
      out ATotal: Double): Boolean;
  public
    constructor Create(ACds: TDataSet;
      const ACampos: TCamposLineasTallas);
    function LeerCampo(const ANombre: string): string;
    procedure PonerCampo(const ANombre, AValor: string);
    function MaximaLinea: Integer;
    function LeerDatosLinea(ALinea: Integer): TDatosLineaExpansion;
    procedure ActualizarLineaExpandida(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLineaExpandida(ANuevaLinea: Integer;
      const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
      const ASku, AAlmacen: string);
    function LocalizarLineaConsolidable(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): Boolean;
    procedure AltaLineaResuelta(const ADatos: TAltaLineaTallas);
    procedure RefrescarTotales(
      const ATotales: TArray<TTotalLineaTallas>);
    property Registro: TRegistroTallas read FRegistro write FRegistro;
  end;
  TLineasDocumentoTallasCds = class(TInterfacedObject,
                                    ILineasRederivacionTallas,
                                    ILineasDesmontajeTallas,
                                    ILineasEntradaTallas,
                                    ILineasPresentacionTallas)
  private
    FCds: TDataSet;
    FCampos: TCamposLineasTallas;
    FEscritura: TEscrituraLineasTallas;
    FAfterPostOrig: TDataSetNotifyEvent;
    FAfterScrollOrig: TDataSetNotifyEvent;
    FOnRecargarCeldas: TNotifyEvent;
    FRegistro: TRegistroTallas;
    FProfundidadProceso: Integer;
    FPostsSilenciados: Integer;
    FEnganchado: Boolean;
    procedure SetRegistro(const AValor: TRegistroTallas);
    procedure ArmarRecarga;
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
  public
    constructor Create(ACds: TDataSet;
      const ACampos: TCamposLineasTallas);
    destructor Destroy; override;
    // Hooks del cds: el Post implicito al cambiar de fila re-renderiza
    // el grid y limpia los Values[] no-bound; el hook los recarga.
    procedure EngancharHooks;
    procedure SoltarHooks;
    function HayLineas: Boolean;
    function MaximaLinea: Integer;
    function LeerDatosLinea(ALinea: Integer): TDatosLineaExpansion;
    function CantidadesPorLinea: TArray<TCantidadLineaTallas>;
    procedure ActualizarLineaExpandida(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLineaExpandida(ANuevaLinea: Integer;
      const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
      const ASku, AAlmacen: string);
    function ContarLineas: Integer;
    procedure PosicionarEn(APosicion: Integer);
    function LeerLineaActual: TLineaDocumentoTallas;
    procedure EscribirLineaActual(const ADatos: TEscrituraLineaTallas);
    procedure BorrarLineaActual;
    procedure IrAlPrimero;
    procedure SuspenderRefrescoVisual;
    procedure ReanudarRefrescoVisual;
    procedure CancelarEdicionPendiente;
    procedure ConfirmarEdicionPendiente;
    function LocalizarLineaConsolidable(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): Boolean;
    procedure AltaLineaResuelta(const ADatos: TAltaLineaTallas);
    function NumeroLineaActual: Integer;
    function AlmacenLineaActual(const ADefecto: string): string;
    function ConjuntoPivotActual: Integer;
    procedure IrALineaEnBlanco;
    procedure RefrescarTotales(
      const ATotales: TArray<TTotalLineaTallas>);
    procedure IniciarProceso;
    procedure TerminarProceso;
    procedure NotificarPostsSilenciados;
    function EnProceso: Boolean;
    property Cds: TDataSet read FCds;
    property OnRecargarCeldas: TNotifyEvent read FOnRecargarCeldas
                                            write FOnRecargarCeldas;
    property Registro: TRegistroTallas read FRegistro
                                       write SetRegistro;
  end;

implementation

constructor TEscrituraLineasTallas.Create(ACds: TDataSet;
  const ACampos: TCamposLineasTallas);
begin
  inherited Create;
  FCds := ACds;
  FCampos := ACampos;
end;

function TEscrituraLineasTallas.LeerCampo(
  const ANombre: string): string;
var
  Campo: TField;
begin
  Result := '';
  if ANombre <> '' then
  begin
    Campo := FCds.FindField(ANombre);
    if Campo <> nil then
      Result := Campo.AsString;
  end;
end;

procedure TEscrituraLineasTallas.PonerCampo(
  const ANombre, AValor: string);
var
  Campo: TField;
begin
  if ANombre <> '' then
  begin
    Campo := FCds.FindField(ANombre);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;
end;

function TEscrituraLineasTallas.LocalizarLinea(
  ALinea: Integer): Boolean;
begin
  Result := FCds.Locate(FCampos.Linea, ALinea, []);
  if not Result then
  begin
    FCds.First;
    while (not FCds.Eof) and (not Result) do
    begin
      if FCds.FieldByName(FCampos.Linea).AsInteger = ALinea then
        Result := True
      else
        FCds.Next;
    end;
  end;
end;

procedure TEscrituraLineasTallas.PonerLineaNueva(ALinea: Integer);
var
  Campo: TField;
begin
  Campo := FCds.FieldByName(FCampos.Linea);
  if Campo is TStringField then
    Campo.AsString := Format('%.*d', [Campo.Size, ALinea])
  else
    Campo.AsInteger := ALinea;
end;

function TEscrituraLineasTallas.MaximaLinea: Integer;
begin
  Result := 0;
  FCds.First;
  while not FCds.Eof do
  begin
    if FCds.FieldByName(FCampos.Linea).AsInteger > Result then
      Result := FCds.FieldByName(FCampos.Linea).AsInteger;
    FCds.Next;
  end;
end;

function TEscrituraLineasTallas.LeerDatosLinea(
  ALinea: Integer): TDatosLineaExpansion;
var
  i: Integer;
begin
  Result := Default(TDatosLineaExpansion);
  Result.Numero := ALinea;
  Result.Primera := True;
  Result.OrdenTalla := -1;
  Result.Encontrada := LocalizarLinea(ALinea);
  if Result.Encontrada then
  begin
    Result.Articulo := Trim(LeerCampo(FCampos.CodigoArt));
    Result.Descripcion := LeerCampo(FCampos.Descripcion);
    Result.Almacen := LeerCampo(FCampos.Almacen);
    if (FCampos.PrecioBase <> '') and
       (FCds.FindField(FCampos.PrecioBase) <> nil) then
      Result.Precio := FCds.FieldByName(FCampos.PrecioBase).AsFloat;
    for i := 1 to 5 do
    begin
      Result.Valores[i] := LeerCampo(FCampos.AttrValor[i]);
      Result.Nombres[i] := LeerCampo(FCampos.AttrNombre[i]);
    end;
  end;
end;

function TEscrituraLineasTallas.ContarAtributos(
  const ANombres: TValoresAttrTallas; AOrdenTalla: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 5 do
  begin
    if ANombres[i] <> '' then
      Inc(Result);
  end;
  if AOrdenTalla >= 0 then
    Inc(Result);
end;

procedure TEscrituraLineasTallas.EscribirTallaYCantidad(
  const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion);
begin
  if (ADatos.OrdenTalla >= 0) and (ADatos.OrdenTalla < 5) then
  begin
    PonerCampo(FCampos.AttrValor[ADatos.OrdenTalla + 1],
               ACelda.ValorTalla);
    PonerCampo(FCampos.AttrNombre[ADatos.OrdenTalla + 1],
               ADatos.NombreTalla);
  end;
  PonerCampo(FCampos.NumAtributos,
    IntToStr(ContarAtributos(ADatos.Nombres, ADatos.OrdenTalla)));
  if FCds.FindField(FCampos.Cantidad) <> nil then
    FCds.FieldByName(FCampos.Cantidad).AsFloat := ACelda.Cantidad;
  // La linea deja de estar pivotada: su cantidad vuelve a la linea.
  if FCds.FindField(FCampos.ConjuntoPivot) <> nil then
    FCds.FieldByName(FCampos.ConjuntoPivot).AsInteger := 0;
  FCds.Post;
end;

procedure TEscrituraLineasTallas.ActualizarLineaExpandida(
  const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
  const ASku, AAlmacen: string);
begin
  if not (FCds.State in [dsEdit, dsInsert]) then
    FCds.Edit;
  PonerCampo(FCampos.CodigoUnidad, ASku);
  PonerCampo(FCampos.Almacen, AAlmacen);
  EscribirTallaYCantidad(ACelda, ADatos);
end;

procedure TEscrituraLineasTallas.CrearLineaExpandida(
  ANuevaLinea: Integer; const ACelda: TCeldaTallas;
  const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
var
  i: Integer;
begin
  FCds.Append;
  PonerLineaNueva(ANuevaLinea);
  PonerCampo(FCampos.CodigoArt, ADatos.Articulo);
  PonerCampo(FCampos.Descripcion, ADatos.Descripcion);
  PonerCampo(FCampos.Almacen, AAlmacen);
  PonerCampo(FCampos.CodigoUnidad, ASku);
  if (FCampos.PrecioBase <> '') and
     (FCds.FindField(FCampos.PrecioBase) <> nil) then
    FCds.FieldByName(FCampos.PrecioBase).AsFloat := ADatos.Precio;
  for i := 1 to 5 do
  begin
    PonerCampo(FCampos.AttrValor[i], ADatos.Valores[i]);
    PonerCampo(FCampos.AttrNombre[i], ADatos.Nombres[i]);
  end;
  EscribirTallaYCantidad(ACelda, ADatos);
end;

function TEscrituraLineasTallas.LineaCoincide(ADistribuido: Boolean;
  const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas; APrecio: Double): Boolean;
var
  j: Integer;
begin
  // Coincidencia manual de la fila actual con la clave completa,
  // PRECIO incluido (Locate no compara floats con tolerancia y debe
  // encontrarse la linea del MISMO precio aunque exista otra igual con
  // precio distinto).
  Result := SameText(Trim(LeerCampo(FCampos.CodigoArt)),
                     Trim(AArticulo));
  if Result and (FCampos.Almacen <> '') and (not ADistribuido) then
    Result := SameText(Trim(LeerCampo(FCampos.Almacen)),
                       Trim(AAlmacen));
  for j := 1 to 5 do
    if Result and (FCampos.AttrValor[j] <> '') then
      Result := SameText(Trim(LeerCampo(FCampos.AttrValor[j])),
                         Trim(AValores[j]));
  if Result then
    Result := Abs(FCds.FieldByName(
      FCampos.PrecioBase).AsFloat - APrecio) < 0.005;
end;

function TEscrituraLineasTallas.LocalizarSinPrecio(
  ADistribuido: Boolean; const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas): Boolean;
var
  sCampos: string;
  vValores: Variant;
  i, n: Integer;
begin
  // Clave de consolidacion: articulo + almacen de la linea + valores de
  // atributos no talla. En DISTRIBUIDO el almacen NO forma parte de la
  // clave: la linea es unica por articulo+color y el reparto por
  // almacen vive en las celdas (modelo sesiones).
  sCampos := FCampos.CodigoArt;
  n := 1;
  if (FCampos.Almacen <> '') and (not ADistribuido) then
    Inc(n);
  for i := 1 to 5 do
    if FCampos.AttrValor[i] <> '' then
      Inc(n);
  vValores := VarArrayCreate([0, n - 1], varVariant);
  vValores[0] := AArticulo;
  n := 1;
  if (FCampos.Almacen <> '') and (not ADistribuido) then
  begin
    sCampos := sCampos + ';' + FCampos.Almacen;
    vValores[n] := AAlmacen;
    Inc(n);
  end;
  for i := 1 to 5 do
    if FCampos.AttrValor[i] <> '' then
    begin
      sCampos := sCampos + ';' + FCampos.AttrValor[i];
      vValores[n] := AValores[i];
      Inc(n);
    end;
  Result := FCds.Locate(sCampos, vValores, []);
end;

function TEscrituraLineasTallas.LocalizarLineaConsolidable(
  ADistribuido: Boolean; const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
  APrecio: Double): Boolean;
begin
  if ATienePrecio and (FCampos.PrecioBase <> '') and
     (FCds.FindField(FCampos.PrecioBase) <> nil) then
  begin
    Result := False;
    FCds.First;
    while (not FCds.Eof) and (not Result) do
    begin
      if LineaCoincide(ADistribuido, AArticulo, AAlmacen, AValores,
                       APrecio) then
        Result := True
      else
        FCds.Next;
    end;
  end
  else
    Result := LocalizarSinPrecio(ADistribuido, AArticulo, AAlmacen,
                                 AValores);
end;

procedure TEscrituraLineasTallas.AltaLineaResuelta(
  const ADatos: TAltaLineaTallas);
var
  i: Integer;
begin
  // ResolverEntrada cancela primero la fila vacia del navegador. Esta
  // rama es un alta real: Edit en EOF modificaba la ultima linea.
  FCds.Append;
  PonerCampo(FCampos.CodigoArt, ADatos.Articulo);
  PonerCampo(FCampos.CodigoUnidad, ADatos.CodigoSku);
  PonerCampo(FCampos.Descripcion, ADatos.Descripcion);
  PonerCampo(FCampos.Almacen, ADatos.Almacen);
  for i := 1 to 5 do
  begin
    PonerCampo(FCampos.AttrValor[i], ADatos.Valores[i]);
    PonerCampo(FCampos.AttrNombre[i], ADatos.Nombres[i]);
  end;
  PonerCampo(FCampos.NumAtributos,
    IntToStr(ContarAtributos(ADatos.Nombres, ADatos.OrdenTalla)));
  if FCds.FindField(FCampos.ConjuntoPivot) <> nil then
    FCds.FieldByName(FCampos.ConjuntoPivot).AsInteger :=
      ADatos.ConjuntoTalla;
  // El precio se fija YA en la linea nueva: su clave de consolidacion
  // vale desde el primer momento (el host lo re-aplicara igual via
  // OnResuelto).
  if ADatos.TienePrecio and (FCampos.PrecioBase <> '') and
     (FCds.FindField(FCampos.PrecioBase) <> nil) then
    FCds.FieldByName(FCampos.PrecioBase).AsFloat := ADatos.Precio;
end;

function TEscrituraLineasTallas.TotalLineaPivotada(
  const ATotales: TArray<TTotalLineaTallas>;
  out ATotal: Double): Boolean;
var
  i, iLinea: Integer;
  bPivotada: Boolean;
begin
  // Solo lineas PIVOTADAS: una linea sin conjunto pivote no deberia
  // tener celdas; si las hay a su numero son residuo de una conversion
  // rota y volcar su suma aqui machacaba la cantidad real con basura
  // (cantidades desorbitadas, 10/07/26).
  Result := False;
  ATotal := 0;
  iLinea := FCds.FieldByName(FCampos.Linea).AsInteger;
  bPivotada := (FCampos.ConjuntoPivot = '') or
    (FCds.FindField(FCampos.ConjuntoPivot) = nil) or
    (FCds.FieldByName(FCampos.ConjuntoPivot).AsInteger > 0);
  for i := 0 to High(ATotales) do
  begin
    if ATotales[i].Linea = iLinea then
    begin
      ATotal := ATotales[i].Total;
      Result := bPivotada;
      if (not bPivotada) and Assigned(FRegistro) then
        FRegistro(Format('ModoTallas.RefrescarTotales: linea %d sin ' +
          'pivote con celdas a su numero; se IGNORAN (residuo de ' +
          'conversion rota)', [iLinea]));
    end;
  end;
end;

procedure TEscrituraLineasTallas.RefrescarTotales(
  const ATotales: TArray<TTotalLineaTallas>);
var
  Marca: TBookmark;
  rTotal, rPrecio: Double;
begin
  if (FCds <> nil) and FCds.Active and (not FCds.IsEmpty) and
     (FCds.FindField(FCampos.TotalUds) <> nil) then
  begin
    Marca := FCds.GetBookmark;
    FCds.DisableControls;
    try
      FCds.First;
      while not FCds.Eof do
      begin
        // Solo lineas CON celdas: las escalares (sin tallaje) llevan su
        // cantidad en la propia linea y este refresco las dejaba a 0.
        if TotalLineaPivotada(ATotales, rTotal) then
        begin
          rPrecio := 0;
          if FCds.FindField(FCampos.PrecioBase) <> nil then
            rPrecio := FCds.FieldByName(FCampos.PrecioBase).AsFloat;
          if FCds.FieldByName(FCampos.TotalUds).AsFloat <> rTotal then
          begin
            if not (FCds.State in [dsEdit, dsInsert]) then
              FCds.Edit;
            FCds.FieldByName(FCampos.TotalUds).AsFloat := rTotal;
            if FCds.FindField(FCampos.TotalLinea) <> nil then
              FCds.FieldByName(FCampos.TotalLinea).AsFloat :=
                rTotal * rPrecio;
            FCds.Post;
          end;
        end;
        FCds.Next;
      end;
      if FCds.BookmarkValid(Marca) then
        FCds.GotoBookmark(Marca);
    finally
      FCds.FreeBookmark(Marca);
      FCds.EnableControls;
    end;
  end;
end;

constructor TLineasDocumentoTallasCds.Create(ACds: TDataSet;
  const ACampos: TCamposLineasTallas);
begin
  inherited Create;
  FCds := ACds;
  FCampos := ACampos;
  FEscritura := TEscrituraLineasTallas.Create(ACds, ACampos);
end;

destructor TLineasDocumentoTallasCds.Destroy;
begin
  SoltarHooks;
  FreeAndNil(FEscritura);
  inherited;
end;

procedure TLineasDocumentoTallasCds.SetRegistro(
  const AValor: TRegistroTallas);
begin
  FRegistro := AValor;
  FEscritura.Registro := AValor;
end;

procedure TLineasDocumentoTallasCds.EngancharHooks;
begin
  if (FCds <> nil) and (not FEnganchado) then
  begin
    FAfterPostOrig := FCds.AfterPost;
    FCds.AfterPost := CdsAfterPost;
    FAfterScrollOrig := FCds.AfterScroll;
    FCds.AfterScroll := CdsAfterScroll;
    FEnganchado := True;
  end;
end;

procedure TLineasDocumentoTallasCds.SoltarHooks;
begin
  // Devolver los hooks a su duenyo, solo si los enganchamos.
  if FEnganchado and (FCds <> nil) then
  begin
    FCds.AfterPost := FAfterPostOrig;
    FCds.AfterScroll := FAfterScrollOrig;
    FEnganchado := False;
  end;
end;

function TLineasDocumentoTallasCds.HayLineas: Boolean;
begin
  Result := (FCds <> nil) and FCds.Active and (not FCds.IsEmpty);
end;

function TLineasDocumentoTallasCds.MaximaLinea: Integer;
begin
  Result := FEscritura.MaximaLinea;
end;

function TLineasDocumentoTallasCds.LeerDatosLinea(
  ALinea: Integer): TDatosLineaExpansion;
begin
  Result := FEscritura.LeerDatosLinea(ALinea);
end;

procedure TLineasDocumentoTallasCds.ActualizarLineaExpandida(
  const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
  const ASku, AAlmacen: string);
begin
  FEscritura.ActualizarLineaExpandida(ACelda, ADatos, ASku, AAlmacen);
end;

procedure TLineasDocumentoTallasCds.CrearLineaExpandida(
  ANuevaLinea: Integer; const ACelda: TCeldaTallas;
  const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
begin
  FEscritura.CrearLineaExpandida(ANuevaLinea, ACelda, ADatos, ASku,
                                 AAlmacen);
end;

function TLineasDocumentoTallasCds.CantidadesPorLinea
  : TArray<TCantidadLineaTallas>;
var
  Marca: TBookmark;
  iTotal: Integer;
begin
  Result := nil;
  iTotal := 0;
  if HayLineas and (FCds.FindField(FCampos.Cantidad) <> nil) then
  begin
    Marca := FCds.GetBookmark;
    FCds.DisableControls;
    try
      FCds.First;
      while not FCds.Eof do
      begin
        SetLength(Result, iTotal + 1);
        Result[iTotal].Linea :=
          FCds.FieldByName(FCampos.Linea).AsInteger;
        Result[iTotal].Cantidad :=
          FCds.FieldByName(FCampos.Cantidad).AsFloat;
        Inc(iTotal);
        FCds.Next;
      end;
      if FCds.BookmarkValid(Marca) then
        FCds.GotoBookmark(Marca);
    finally
      FCds.FreeBookmark(Marca);
      FCds.EnableControls;
    end;
  end;
end;

function TLineasDocumentoTallasCds.ContarLineas: Integer;
begin
  Result := FCds.RecordCount;
end;

procedure TLineasDocumentoTallasCds.PosicionarEn(APosicion: Integer);
begin
  FCds.RecNo := APosicion;
end;

function TLineasDocumentoTallasCds.LeerLineaActual
  : TLineaDocumentoTallas;
begin
  Result := Default(TLineaDocumentoTallas);
  Result.Numero := FCds.FieldByName(FCampos.Linea).AsInteger;
  Result.Articulo := Trim(FEscritura.LeerCampo(FCampos.CodigoArt));
  Result.Sku := Trim(FEscritura.LeerCampo(FCampos.CodigoUnidad));
  Result.TieneCantidad := FCds.FindField(FCampos.Cantidad) <> nil;
  if Result.TieneCantidad then
    Result.Cantidad := FCds.FieldByName(FCampos.Cantidad).AsFloat;
  Result.TieneAlmacen := (FCampos.Almacen <> '') and
    (FCds.FindField(FCampos.Almacen) <> nil);
  if Result.TieneAlmacen then
    Result.Almacen := Trim(FCds.FieldByName(FCampos.Almacen).AsString);
  Result.TienePrecio := (FCampos.PrecioBase <> '') and
    (FCds.FindField(FCampos.PrecioBase) <> nil);
  if Result.TienePrecio then
    Result.Precio := FCds.FieldByName(FCampos.PrecioBase).AsFloat;
end;

procedure TLineasDocumentoTallasCds.EscribirLineaActual(
  const ADatos: TEscrituraLineaTallas);
var
  i: Integer;
  Campo: TField;
begin
  if not (FCds.State in [dsEdit, dsInsert]) then
    FCds.Edit;
  FEscritura.PonerCampo(FCampos.Almacen, ADatos.Almacen);
  for i := 1 to 5 do
  begin
    FEscritura.PonerCampo(FCampos.AttrValor[i], ADatos.Valores[i]);
    FEscritura.PonerCampo(FCampos.AttrNombre[i], ADatos.Nombres[i]);
  end;
  FEscritura.PonerCampo(FCampos.NumAtributos,
    IntToStr(FEscritura.ContarAtributos(ADatos.Nombres,
      ADatos.OrdenTalla)));
  if FCds.FindField(FCampos.ConjuntoPivot) <> nil then
    FCds.FieldByName(FCampos.ConjuntoPivot).AsInteger :=
      ADatos.ConjuntoTalla;
  // La cantidad del SKU con talla pasa a su celda; la columna Cantidad
  // queda para lineas sin tallas.
  if ADatos.PonerCantidadCero then
  begin
    Campo := FCds.FindField(FCampos.Cantidad);
    if Campo <> nil then
      Campo.AsFloat := 0;
  end;
  FCds.Post;
end;

procedure TLineasDocumentoTallasCds.BorrarLineaActual;
var
  EventoBorrado: TDataSetNotifyEvent;
begin
  // Borrado PROGRAMATICO de la fusion: sin el guardian de confirmacion
  // que TfrmMtoGen engancha en BeforeDelete (preguntaria al usuario por
  // cada duplicada durante Construir).
  EventoBorrado := FCds.BeforeDelete;
  FCds.BeforeDelete := nil;
  try
    FCds.Delete;
  finally
    FCds.BeforeDelete := EventoBorrado;
  end;
end;

procedure TLineasDocumentoTallasCds.IrAlPrimero;
begin
  FCds.First;
end;

procedure TLineasDocumentoTallasCds.SuspenderRefrescoVisual;
begin
  FCds.DisableControls;
end;

procedure TLineasDocumentoTallasCds.ReanudarRefrescoVisual;
begin
  FCds.EnableControls;
end;

procedure TLineasDocumentoTallasCds.CancelarEdicionPendiente;
begin
  if FCds.State in [dsEdit, dsInsert] then
    FCds.Cancel;
end;

procedure TLineasDocumentoTallasCds.ConfirmarEdicionPendiente;
begin
  if FCds.State in [dsEdit, dsInsert] then
    FCds.Post;
end;

function TLineasDocumentoTallasCds.LocalizarLineaConsolidable(
  ADistribuido: Boolean; const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
  APrecio: Double): Boolean;
begin
  Result := FEscritura.LocalizarLineaConsolidable(ADistribuido,
    AArticulo, AAlmacen, AValores, ATienePrecio, APrecio);
end;

procedure TLineasDocumentoTallasCds.AltaLineaResuelta(
  const ADatos: TAltaLineaTallas);
begin
  FEscritura.AltaLineaResuelta(ADatos);
end;

function TLineasDocumentoTallasCds.NumeroLineaActual: Integer;
begin
  Result := FCds.FieldByName(FCampos.Linea).AsInteger;
end;

function TLineasDocumentoTallasCds.AlmacenLineaActual(
  const ADefecto: string): string;
begin
  // Fallback de cabecera (como albaranes de compra): la linea sin
  // almacen asume el almacen por defecto del documento.
  Result := '';
  if (FCampos.Almacen <> '') and
     (FCds.FindField(FCampos.Almacen) <> nil) then
  begin
    Result := Trim(FCds.FieldByName(FCampos.Almacen).AsString);
    if Result = '' then
      Result := Trim(ADefecto);
  end;
end;

function TLineasDocumentoTallasCds.ConjuntoPivotActual: Integer;
begin
  Result := 0;
  if FCds.FindField(FCampos.ConjuntoPivot) <> nil then
    Result := FCds.FieldByName(FCampos.ConjuntoPivot).AsInteger;
end;

procedure TLineasDocumentoTallasCds.IrALineaEnBlanco;
begin
  FCds.Locate(FCampos.CodigoArt, '', []);
end;

procedure TLineasDocumentoTallasCds.RefrescarTotales(
  const ATotales: TArray<TTotalLineaTallas>);
begin
  FEscritura.RefrescarTotales(ATotales);
end;

procedure TLineasDocumentoTallasCds.IniciarProceso;
begin
  Inc(FProfundidadProceso);
end;

procedure TLineasDocumentoTallasCds.TerminarProceso;
begin
  if FProfundidadProceso > 0 then
    Dec(FProfundidadProceso);
end;

function TLineasDocumentoTallasCds.EnProceso: Boolean;
begin
  Result := FProfundidadProceso > 0;
end;

procedure TLineasDocumentoTallasCds.ArmarRecarga;
begin
  if Assigned(FOnRecargarCeldas) and (FProfundidadProceso = 0) then
    FOnRecargarCeldas(Self);
end;

procedure TLineasDocumentoTallasCds.CdsAfterPost(DataSet: TDataSet);
begin
  // Conversion interna en curso (rederivar, totales, expansion): los
  // posts son masivos y encadenar el AfterPost del host en cada uno
  // dispara totales/movimientos en cascada; ademas sus repintados
  // borran los Values[] no-bound recien cargados. Se cuenta y se
  // notifica UNA sola vez al cerrar.
  if FProfundidadProceso > 0 then
    Inc(FPostsSilenciados)
  else
  begin
    if Assigned(FAfterPostOrig) then
      FAfterPostOrig(DataSet);
    ArmarRecarga;
  end;
end;

procedure TLineasDocumentoTallasCds.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FAfterScrollOrig) then
    FAfterScrollOrig(DataSet);
  // La navegacion tambien puede repintar y limpiar los Values[].
  ArmarRecarga;
end;

procedure TLineasDocumentoTallasCds.NotificarPostsSilenciados;
begin
  // Cierre de una conversion interna: si se silenciaron posts, encadena
  // UNA sola vez el AfterPost del host (totales, movimientos,
  // pendientes de recibir) y rearma la recarga de celdas.
  if (FPostsSilenciados > 0) and (FProfundidadProceso = 0) then
  begin
    FPostsSilenciados := 0;
    if Assigned(FAfterPostOrig) and (FCds <> nil) and FCds.Active then
      FAfterPostOrig(FCds);
    ArmarRecarga;
  end;
end;

end.

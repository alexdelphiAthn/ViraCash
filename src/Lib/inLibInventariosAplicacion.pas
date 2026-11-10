{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosAplicacion                                    }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquesta la entrada y la importacion de recuentos de inventario           }
{    sin conocer formularios, datasets concretos ni SQL.                       }
{******************************************************************************}
unit inLibInventariosAplicacion;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  inLibArticulosValidadorIntf,
  inLibInventariosAplicacionIntf;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;
// Lector CSV del recuento: cada linea es "UNIDAD;CANTIDAD" o
// "UNIDAD=CANTIDAD", y admite detras ";LOTE;CADUCIDAD" (F-LOTEC-014). Sin
// cantidad legible se asume una unidad, que es el comportamiento historico
// del lector de la pantalla.
function LeerLineasImportacionCsvInventario(
  const ATextos: TArray<string>): TLineasImportacionInventario;
// Reparte las lineas leidas entre actualizacion de recuento y alta
// pendiente. No conoce datasets: escribe a traves del puerto.
function AplicarImportacionInventario(
  const ALineas: TLineasImportacionInventario;
  const AOperaciones: IOperacionesImportacionInventario):
  TResumenImportacionInventario;

function CompletarFechasRecuentoInventario(
  var ALineas: TLineasImportacionInventario;
  const ASolicitar: TSolicitarFechaRecuentoInventario): Boolean;

function FechaHoraRecuentoInventarioValida(
  AFechaHora, AFechaReferencia: TDateTime): Boolean;

function ValidarIdentidadImportacionInventario(
  const AIdentidad: TIdentidadImportacionInventario;
  const AInventario: TClaveInventario):
  TEstadoIdentidadImportacionInventario;

function ConsolidarLineasSinIdentidadInventario(
  const ALineas: TLineasImportacionInventario):
  TLineasImportacionInventario;

// El Excel exportado lleva siempre "PMP nuevo" relleno con el PMP de la
// linea. Solo es un PMP manual si difiere del "PMP actual" de la misma
// fila (a cuatro decimales, la precision del PMP nuevo); si coincide, el
// recuento debe entrar al PMP del instante del recuento (FZ-ISSUE-081).
function PmpNuevoInventarioEsManual(
  APmpNuevo, APmpActual: Double): Boolean;

// Sustituye los codigos de linea numericos leidos del fichero por el codigo
// real de la linea del inventario con el mismo valor sin ceros a la
// izquierda (Excel guarda 0001 como 1). Los que no coinciden se dejan como
// estan para que la validacion los rechace.
procedure ResolverCodigosLineaInventario(
  var ALineas: TLineasImportacionInventario;
  ALineasInventario: TDataSet);

function ConsolidarLineasNuevasInventario(
  const ALineas: TLineasImportacionInventario;
  const ANuevas: TStrings): TLineasImportacionInventario;
// Adaptador del puerto de importacion sobre el dataset de lineas. No
// conoce VCL ni UniDAC: recibe el dataset, la lista de altas pendientes
// y las dos acciones propias del data module.
function CrearOperacionesImportacionInventario(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc): IOperacionesImportacionInventario;

implementation

uses
  inLibRedondeo,
  System.Generics.Collections,
  System.Math,
  inLibInventariosEntrada,
  inLibInventariosPresentacion,
  inLibInventarioRecuentoLote,
  inLibTrazabilidad;

const
  CAMPO_LINEA_IMPORTACION = 'LINEA_INVLIN';
  CAMPO_UNIDAD_IMPORTACION = 'CODIGO_UNIDAD_INVLIN';
  CAMPO_LOTE_IMPORTACION = 'LOTE_INVLIN';
  CAMPO_CANTIDAD_IMPORTACION = 'CANTIDAD_FISICA_INVLIN';
  CAMPO_PRECIO_IMPORTACION = 'PRECIO_MEDIO_NUEVO_INVLIN';
  CAMPO_PRECIO_CORREGIDO = 'ESPRECIO_MEDIO_CORREGIDO_INVLIN';
  CAMPO_FECHA_RECUENTO = 'FECHA_RECUENTO_INVLIN';
  CAMPO_CANTIDAD_TEORICA = 'CANTIDAD_TEORICA_INVLIN';
  CAMPO_PRECIO_ACTUAL = 'PRECIO_MEDIO_INVLIN';
  CAMPO_DIFERENCIA_UNIDADES = 'CANTIDAD_DIFERENCIA_INVLIN';
  CAMPO_DIFERENCIA_COSTE = 'TOTAL_COSTE_DIFERENCIA_INVLIN';

type
  TOperacionesImportacionInventarioDataSet = class(
    TInterfacedObject,
    IOperacionesImportacionInventario)
  private
    FLineas: TDataSet;
    FNuevas: TStrings;
    FAlConfirmarLinea: TProc;
    FConsolidar: TProc;
    procedure RecalcularDiferenciasLinea;
  public
    constructor Create(
      ALineas: TDataSet; ANuevas: TStrings;
      const AAlConfirmarLinea: TProc;
      const AConsolidar: TProc);
    function LocalizarLinea(
      const ACodigoLinea, ACodigoUnidad, ALote: string): Boolean;
    procedure IniciarEdicionLinea;
    procedure EscribirCantidadFisica(ACantidad: Double);
    procedure EscribirPrecioMedioNuevo(APrecio: Double);
    procedure EscribirFechaRecuento(AFecha: TDateTime);
    procedure UsarPrecioMedioHistorico;
    procedure ConfirmarLinea;
    procedure ConsolidarCambios;
    procedure AnadirUnidadPendiente(const ATextoOriginal: string);
  end;

  TAplicacionEntradaInventario = class(
    TInterfacedObject,
    IAplicacionEntradaInventario)
  private
    FValidador: IArticulosValidador;
    FOperaciones: IOperacionesEntradaInventario;
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AOperaciones: IOperacionesEntradaInventario);
    function Procesar(
      const AEntrada: string): TResultadoEntradaInventario;
  end;

constructor TAplicacionEntradaInventario.Create(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario);
begin
  inherited Create;
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  FValidador := AValidador;
  FOperaciones := AOperaciones;
end;

function TAplicacionEntradaInventario.Procesar(
  const AEntrada: string): TResultadoEntradaInventario;
var
  bMuestraAtributos: Boolean;
  iNumeroAtributos: Integer;
  Resolucion: TArtResolucionEntrada;
  Decision: TDecisionEntradaInventario;
  Modo: TModoTrazabilidad;
begin
  Result := Default(TResultadoEntradaInventario);
  Resolucion := FValidador.Resolver(Trim(AEntrada));
  if not Resolucion.Encontrado then
    Result.Error := eeiArticuloNoEncontrado;
  if Result.Error = eeiNinguno then
  begin
    Result.CodigoArticulo := Resolucion.CodigoArticulo;
    Result.CodigoSku := Resolucion.CodigoSku;
    Result.Descripcion := Resolucion.DescripcionArticulo;
    Result.TipoArticulo := Resolucion.TipoArticulo;
  end;
  if (Result.Error = eeiNinguno) and
     (not SameText(Resolucion.TipoArticulo, 'ESTANDAR')) then
    Result.Error := eeiTipoArticuloSinStock;
  bMuestraAtributos := FOperaciones.MuestraAtributos;
  iNumeroAtributos := 0;
  if (Result.Error = eeiNinguno) and
     (not bMuestraAtributos) and
     (Resolucion.CodigoSku = '') then
  begin
    iNumeroAtributos := FOperaciones.ObtenerNumeroAtributos(
      Resolucion.CodigoArticulo);
    if iNumeroAtributos > 0 then
      Result.Error := eeiAtributosRequierenSku;
  end;
  if Result.Error = eeiNinguno then
    Result.Error := FOperaciones.AsegurarEdicion;
  if Result.Error = eeiNinguno then
  begin
    FOperaciones.EscribirArticulo(
      Result.CodigoArticulo,
      Result.Descripcion);
    FOperaciones.ActualizarColumnas(Result.CodigoArticulo);
    if bMuestraAtributos then
      iNumeroAtributos := FOperaciones.NumeroAtributosActual;
    Result.Error := FOperaciones.AsegurarEdicion;
  end;
  if Result.Error = eeiNinguno then
  begin
    Decision := ResolverEntradaInventario(
      Result.CodigoArticulo,
      Result.CodigoSku,
      iNumeroAtributos);
    Result.CodigoUnidad := Decision.CodigoUnidad;
    FOperaciones.EscribirUnidad(Result.CodigoUnidad);
    if Decision.CargarStock then
      FOperaciones.CargarStock(Result.CodigoUnidad);
    if Decision.RellenarAtributos then
      FOperaciones.RellenarAtributos(Result.CodigoUnidad);
    // FZ-ISSUE-341: el IMEI o el lote leído va a la línea, como en ventas,
    // compras y traspasos; antes solo quedaba el artículo.
    if Decision.CargarStock and
       ((Resolucion.Lote <> '') or (Resolucion.Serie <> '')) then
    begin
      Modo := FOperaciones.ModoTrazabilidadEfectivo(Result.CodigoArticulo);
      Result.Lote := LoteLecturaInventario(
        Modo, Resolucion.Lote, Resolucion.Serie);
      if Result.Lote <> '' then
        FOperaciones.EscribirLoteLeido(
          Result.CodigoUnidad, Result.Lote, Resolucion.FechaCaducidad,
          Modo = mtSerie);
    end;
  end;
end;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;
begin
  Result := TAplicacionEntradaInventario.Create(
    AValidador,
    AOperaciones);
end;

function LeerLineasImportacionCsvInventario(
  const ATextos: TArray<string>): TLineasImportacionInventario;
var
  iResultado: Integer;
  iLinea: Integer;
  iSeparador: Integer;
  sTexto: string;
  sUnidad: string;
  Valor: TValorRecuentoLote;
begin
  SetLength(Result, 0);
  for iLinea := 0 to High(ATextos) do
  begin
    // El separador ';' del CSV se normaliza a '=' antes de partir, igual
    // que hacia la pantalla al cargar el fichero.
    sTexto := StringReplace(ATextos[iLinea], ';', '=', [rfReplaceAll]);
    iSeparador := Pos('=', sTexto);
    iResultado := Length(Result);
    SetLength(Result, iResultado + 1);
    Result[iResultado] := Default(TLineaImportacionInventario);
    Result[iResultado].Cantidad := 1;
    Result[iResultado].TextoOriginal := sTexto;
    if iSeparador > 0 then
    begin
      sUnidad := Copy(sTexto, 1, iSeparador - 1);
      Result[iResultado].CodigoUnidad := sUnidad;
      // CANTIDAD[;LOTE[;CADUCIDAD]] (F-LOTEC-014)
      Valor := LeerValorRecuentoLote(StringReplace(
        Copy(sTexto, iSeparador + 1, Length(sTexto)), '=',
        SEPARADOR_VALOR_RECUENTO, [rfReplaceAll]));
      if Valor.TieneCantidad then
        Result[iResultado].Cantidad := Valor.Cantidad;
      Result[iResultado].Lote := Valor.Lote;
      Result[iResultado].FechaCaducidad := Valor.FechaCaducidad;
      if Valor.Lote <> '' then
        Result[iResultado].TextoOriginal := sUnidad + '=' +
          ValorRecuentoLote(Result[iResultado].Cantidad, Valor.Lote,
            Valor.FechaCaducidad);
    end;
  end;
end;

function AplicarImportacionInventario(
  const ALineas: TLineasImportacionInventario;
  const AOperaciones: IOperacionesImportacionInventario):
  TResumenImportacionInventario;
var
  iLinea: Integer;
begin
  Result := Default(TResumenImportacionInventario);
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  for iLinea := 0 to High(ALineas) do
  begin
    if ALineas[iLinea].CodigoUnidad <> '' then
    begin
      if AOperaciones.LocalizarLinea(
           ALineas[iLinea].CodigoLinea,
           ALineas[iLinea].CodigoUnidad,
           ALineas[iLinea].Lote) then
      begin
        AOperaciones.IniciarEdicionLinea;
        AOperaciones.EscribirCantidadFisica(ALineas[iLinea].Cantidad);
        if ALineas[iLinea].TienePrecioMedio then
          AOperaciones.EscribirPrecioMedioNuevo(
            ALineas[iLinea].PrecioMedioNuevo)
        else
          AOperaciones.UsarPrecioMedioHistorico;
        if ALineas[iLinea].TieneFechaRecuento then
          AOperaciones.EscribirFechaRecuento(
            ALineas[iLinea].FechaRecuento);
        AOperaciones.ConfirmarLinea;
        Inc(Result.Actualizadas);
      end
      else
      begin
        AOperaciones.AnadirUnidadPendiente(ALineas[iLinea].TextoOriginal);
        Inc(Result.Nuevas);
      end;
    end;
  end;
  if Result.Actualizadas > 0 then
    AOperaciones.ConsolidarCambios;
end;

function CompletarFechasRecuentoInventario(
  var ALineas: TLineasImportacionInventario;
  const ASolicitar: TSolicitarFechaRecuentoInventario): Boolean;
var
  FechaRecuento: TDateTime;
  FaltanFechas: Boolean;
  iLinea: Integer;
begin
  if not Assigned(ASolicitar) then
    raise EArgumentNilException.Create('ASolicitar');
  FaltanFechas := False;
  for iLinea := 0 to High(ALineas) do
    if not ALineas[iLinea].TieneFechaRecuento then
      FaltanFechas := True;
  Result := True;
  if FaltanFechas then
  begin
    Result := ASolicitar(FechaRecuento);
    if Result then
      Result := FechaHoraRecuentoInventarioValida(
        FechaRecuento,
        Now);
    if Result then
      for iLinea := 0 to High(ALineas) do
        if not ALineas[iLinea].TieneFechaRecuento then
        begin
          ALineas[iLinea].FechaRecuento := FechaRecuento;
          ALineas[iLinea].TieneFechaRecuento := True;
        end;
  end;
end;

function FechaHoraRecuentoInventarioValida(
  AFechaHora, AFechaReferencia: TDateTime): Boolean;
begin
  Result := (AFechaHora >= EncodeDate(2000, 1, 1)) and
    (AFechaHora <= AFechaReferencia + EncodeTime(0, 5, 0, 0));
end;

function SonSoloDigitos(const ATexto: string): Boolean;
var
  i: Integer;
begin
  Result := ATexto <> '';
  i := 1;
  while Result and (i <= Length(ATexto)) do
  begin
    Result := CharInSet(ATexto[i], ['0'..'9']);
    Inc(i);
  end;
end;

function SinCerosIzquierda(const ATexto: string): string;
var
  i: Integer;
begin
  i := 1;
  while (i < Length(ATexto)) and (ATexto[i] = '0') do
    Inc(i);
  Result := Copy(ATexto, i, MaxInt);
end;

// Excel convierte en número los códigos con solo dígitos y pierde los
// ceros a la izquierda (empresa 012 -> 12, número 000036 -> 36).
function ValorClaveInventarioCoincide(const AExcel, AInventario: string):
  Boolean;
var
  Excel: string;
  Inventario: string;
begin
  Excel := Trim(AExcel);
  Inventario := Trim(AInventario);
  Result := SameText(Excel, Inventario);
  if (not Result) and SonSoloDigitos(Excel) and
    SonSoloDigitos(Inventario) then
    Result := SinCerosIzquierda(Excel) = SinCerosIzquierda(Inventario);
end;

function ValidarIdentidadImportacionInventario(
  const AIdentidad: TIdentidadImportacionInventario;
  const AInventario: TClaveInventario):
  TEstadoIdentidadImportacionInventario;
begin
  Result := eiiiCorrecta;
  if AIdentidad.TieneConflictos then
    Result := eiiiContradictoria
  else if (not AIdentidad.TieneEmpresa) or
          (not AIdentidad.TieneAlmacen) or
          (not AIdentidad.TieneSerie) or
          (not AIdentidad.TieneNumero) or
          (Trim(AIdentidad.Clave.Empresa) = '') or
          (Trim(AIdentidad.Clave.Almacen) = '') or
          (Trim(AIdentidad.Clave.Serie) = '') or
          (Trim(AIdentidad.Clave.Numero) = '') then
    Result := eiiiIncompleta
  else if (not ValorClaveInventarioCoincide(
             AIdentidad.Clave.Empresa,
             AInventario.Empresa)) or
          (not ValorClaveInventarioCoincide(
             AIdentidad.Clave.Almacen,
             AInventario.Almacen)) or
          (not ValorClaveInventarioCoincide(
             AIdentidad.Clave.Serie,
             AInventario.Serie)) or
          (not ValorClaveInventarioCoincide(
             AIdentidad.Clave.Numero,
             AInventario.Numero)) then
    Result := eiiiInventarioDistinto;
end;

function PmpNuevoInventarioEsManual(
  APmpNuevo, APmpActual: Double): Boolean;
var
  Nuevo: Currency;
  Actual: Currency;
begin
  // Se asigna a Currency antes de comparar para no depender del ultimo bit
  // del Double. Se admite una diezmilesima: la BBDD puede redondear el
  // PMP nuevo del medio hacia el otro lado (17,28575 -> 17,2858).
  Nuevo := RedondearDecimales(APmpNuevo, 4);
  Actual := RedondearDecimales(APmpActual, 4);
  Result := Abs(Nuevo - Actual) > 0.0001;
end;

function ClaveCodigoLineaInventario(const ACodigo: string): string;
begin
  Result := Trim(ACodigo);
  if SonSoloDigitos(Result) then
    Result := SinCerosIzquierda(Result);
end;

procedure CargarCodigosLineaInventario(
  ALineasInventario: TDataSet;
  ACodigos: TDictionary<string, string>);
var
  Campo: TField;
  Marcador: TBookmark;
begin
  Campo := ALineasInventario.FieldByName(CAMPO_LINEA_IMPORTACION);
  Marcador := ALineasInventario.GetBookmark;
  ALineasInventario.DisableControls;
  try
    ALineasInventario.First;
    while not ALineasInventario.Eof do
    begin
      if SonSoloDigitos(Trim(Campo.AsString)) then
        ACodigos.AddOrSetValue(
          ClaveCodigoLineaInventario(Campo.AsString),
          Campo.AsString);
      ALineasInventario.Next;
    end;
  finally
    if ALineasInventario.BookmarkValid(Marcador) then
      ALineasInventario.GotoBookmark(Marcador);
    ALineasInventario.FreeBookmark(Marcador);
    ALineasInventario.EnableControls;
  end;
end;

procedure ResolverCodigosLineaInventario(
  var ALineas: TLineasImportacionInventario;
  ALineasInventario: TDataSet);
var
  Codigos: TDictionary<string, string>;
  CodigoReal: string;
  iLinea: Integer;
begin
  if (ALineasInventario <> nil) and ALineasInventario.Active and
     (not ALineasInventario.IsEmpty) then
  begin
    Codigos := TDictionary<string, string>.Create;
    try
      CargarCodigosLineaInventario(ALineasInventario, Codigos);
      for iLinea := 0 to High(ALineas) do
        if SonSoloDigitos(Trim(ALineas[iLinea].CodigoLinea)) and
           Codigos.TryGetValue(
             ClaveCodigoLineaInventario(ALineas[iLinea].CodigoLinea),
             CodigoReal) then
          ALineas[iLinea].CodigoLinea := CodigoReal;
    finally
      Codigos.Free;
    end;
  end;
end;

procedure AcumularLineaImportacionInventario(
  var ADestino: TLineaImportacionInventario;
  const AOrigen: TLineaImportacionInventario);
begin
  ADestino.Cantidad := ADestino.Cantidad + AOrigen.Cantidad;
  if AOrigen.TienePrecioMedio then
  begin
    ADestino.PrecioMedioNuevo := AOrigen.PrecioMedioNuevo;
    ADestino.TienePrecioMedio := True;
  end;
  if AOrigen.TieneFechaRecuento and
     ((not ADestino.TieneFechaRecuento) or
      (AOrigen.FechaRecuento > ADestino.FechaRecuento)) then
  begin
    ADestino.FechaRecuento := AOrigen.FechaRecuento;
    ADestino.TieneFechaRecuento := True;
  end;
end;

function ConsolidarLineasSinIdentidadInventario(
  const ALineas: TLineasImportacionInventario):
  TLineasImportacionInventario;
var
  iExistente: Integer;
  iLinea: Integer;
  iResultado: Integer;
begin
  SetLength(Result, 0);
  for iLinea := 0 to High(ALineas) do
  begin
    iExistente := -1;
    if Trim(ALineas[iLinea].CodigoLinea) = '' then
      for iResultado := 0 to High(Result) do
        if (Trim(Result[iResultado].CodigoLinea) = '') and
           SameText(
             Result[iResultado].CodigoUnidad,
             ALineas[iLinea].CodigoUnidad) and
           MismoLoteRecuento(Result[iResultado].Lote,
             ALineas[iLinea].Lote) then
          iExistente := iResultado;
    if iExistente < 0 then
    begin
      iResultado := Length(Result);
      SetLength(Result, iResultado + 1);
      Result[iResultado] := ALineas[iLinea];
      iExistente := iResultado;
    end
    else
      AcumularLineaImportacionInventario(
        Result[iExistente],
        ALineas[iLinea]);
    if Trim(Result[iExistente].CodigoLinea) = '' then
      Result[iExistente].TextoOriginal :=
        Result[iExistente].CodigoUnidad + '=' +
        ValorRecuentoLote(Result[iExistente].Cantidad,
          Result[iExistente].Lote, Result[iExistente].FechaCaducidad);
  end;
end;

function ConsolidarLineasNuevasInventario(
  const ALineas: TLineasImportacionInventario;
  const ANuevas: TStrings): TLineasImportacionInventario;
var
  iExistente: Integer;
  iLinea: Integer;
  iResultado: Integer;
begin
  SetLength(Result, 0);
  if ANuevas = nil then
    raise EArgumentNilException.Create('ANuevas');
  for iLinea := 0 to High(ALineas) do
    if ANuevas.IndexOfName(ALineas[iLinea].CodigoUnidad) >= 0 then
    begin
      iExistente := -1;
      for iResultado := 0 to High(Result) do
        if SameText(
             Result[iResultado].CodigoUnidad,
             ALineas[iLinea].CodigoUnidad) and
           MismoLoteRecuento(Result[iResultado].Lote,
             ALineas[iLinea].Lote) then
          iExistente := iResultado;
      if iExistente < 0 then
      begin
        iResultado := Length(Result);
        SetLength(Result, iResultado + 1);
        Result[iResultado] := ALineas[iLinea];
        Result[iResultado].CodigoLinea := '';
      end
      else
        AcumularLineaImportacionInventario(
          Result[iExistente],
          ALineas[iLinea]);
    end;
end;

constructor TOperacionesImportacionInventarioDataSet.Create(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc);
begin
  inherited Create;
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  if ANuevas = nil then
    raise EArgumentNilException.Create('ANuevas');
  FLineas := ALineas;
  FNuevas := ANuevas;
  FAlConfirmarLinea := AAlConfirmarLinea;
  FConsolidar := AConsolidar;
end;

function TOperacionesImportacionInventarioDataSet.LocalizarLinea(
  const ACodigoLinea, ACodigoUnidad, ALote: string): Boolean;
var
  oCampoLote: TField;
begin
  oCampoLote := FLineas.FindField(CAMPO_LOTE_IMPORTACION);
  if (Trim(ACodigoLinea) = '') and (oCampoLote = nil) then
    Result := FLineas.Locate(
      CAMPO_UNIDAD_IMPORTACION,
      ACodigoUnidad,
      [loCaseInsensitive])
  else if Trim(ACodigoLinea) = '' then
  begin
    // F-LOTEC-014: SKU y lote; sin lote, la linea del SKU sin lote.
    Result := False;
    FLineas.First;
    while (not Result) and (not FLineas.Eof) do
    begin
      Result := SameText(
          FLineas.FieldByName(CAMPO_UNIDAD_IMPORTACION).AsString,
          ACodigoUnidad) and
        MismoLoteRecuento(oCampoLote.AsString, ALote);
      if not Result then
        FLineas.Next;
    end;
  end
  else
  begin
    Result := FLineas.Locate(
      CAMPO_LINEA_IMPORTACION,
      ACodigoLinea,
      [loCaseInsensitive]);
    if Result then
      Result := SameText(
        FLineas.FieldByName(CAMPO_UNIDAD_IMPORTACION).AsString,
        ACodigoUnidad);
  end;
end;

procedure TOperacionesImportacionInventarioDataSet.IniciarEdicionLinea;
begin
  FLineas.Edit;
end;

procedure TOperacionesImportacionInventarioDataSet.EscribirCantidadFisica(
  ACantidad: Double);
begin
  FLineas.FieldByName(CAMPO_CANTIDAD_IMPORTACION).AsFloat := ACantidad;
end;

procedure TOperacionesImportacionInventarioDataSet.
  EscribirPrecioMedioNuevo(APrecio: Double);
begin
  FLineas.FieldByName(CAMPO_PRECIO_IMPORTACION).AsFloat := APrecio;
  FLineas.FieldByName(CAMPO_PRECIO_CORREGIDO).AsString := 'S';
end;

procedure TOperacionesImportacionInventarioDataSet.EscribirFechaRecuento(
  AFecha: TDateTime);
begin
  FLineas.FieldByName(CAMPO_FECHA_RECUENTO).AsDateTime := AFecha;
end;

procedure TOperacionesImportacionInventarioDataSet.UsarPrecioMedioHistorico;
begin
  FLineas.FieldByName(CAMPO_PRECIO_CORREGIDO).AsString := 'N';
end;

// FZ-ISSUE-895: el recuento importado cambia la cantidad fisica (y, a
// veces, el PMP nuevo) sin pasar por la rejilla, que es quien recalculaba
// las diferencias. Se recalculan aqui, con las mismas formulas, antes de
// grabar la linea; la cabecera suma despues las lineas grabadas.
procedure TOperacionesImportacionInventarioDataSet.
  RecalcularDiferenciasLinea;
var
  oFisica: TField;
  oTeorica: TField;
  oPrecioNuevo: TField;
  oPrecioActual: TField;
  oDiferenciaUnidades: TField;
  oDiferenciaCoste: TField;
begin
  oFisica := FLineas.FindField(CAMPO_CANTIDAD_IMPORTACION);
  oTeorica := FLineas.FindField(CAMPO_CANTIDAD_TEORICA);
  oPrecioNuevo := FLineas.FindField(CAMPO_PRECIO_IMPORTACION);
  oPrecioActual := FLineas.FindField(CAMPO_PRECIO_ACTUAL);
  oDiferenciaUnidades := FLineas.FindField(CAMPO_DIFERENCIA_UNIDADES);
  oDiferenciaCoste := FLineas.FindField(CAMPO_DIFERENCIA_COSTE);
  if (oFisica <> nil) and (oTeorica <> nil) then
  begin
    if oDiferenciaUnidades <> nil then
      oDiferenciaUnidades.AsCurrency := DiferenciaUnidadesInventario(
        oFisica.AsCurrency, oTeorica.AsCurrency);
    if (oDiferenciaCoste <> nil) and (oPrecioNuevo <> nil) and
       (oPrecioActual <> nil) then
      oDiferenciaCoste.AsCurrency := DiferenciaCosteInventario(
        oFisica.AsCurrency, oTeorica.AsCurrency,
        oPrecioNuevo.AsCurrency, oPrecioActual.AsCurrency);
  end;
end;

procedure TOperacionesImportacionInventarioDataSet.ConfirmarLinea;
begin
  RecalcularDiferenciasLinea;
  if Assigned(FAlConfirmarLinea) then
    FAlConfirmarLinea();
  FLineas.Post;
end;

procedure TOperacionesImportacionInventarioDataSet.ConsolidarCambios;
begin
  if Assigned(FConsolidar) then
    FConsolidar();
end;

procedure TOperacionesImportacionInventarioDataSet.AnadirUnidadPendiente(
  const ATextoOriginal: string);
begin
  FNuevas.Add(ATextoOriginal);
end;

function CrearOperacionesImportacionInventario(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc): IOperacionesImportacionInventario;
begin
  Result := TOperacionesImportacionInventarioDataSet.Create(
    ALineas, ANuevas, AAlConfirmarLinea, AConsolidar);
end;

end.

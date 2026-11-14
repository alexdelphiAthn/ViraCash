{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLotesLineaDocumento                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lote o serie de las líneas de un documento (F-LOTEC-013 y      }
{    siguientes). El módulo de datos lo llama al grabar cada línea: decide     }
{    el lote con la regla común (DecidirLoteLectura: series    }
{    capturadas, lote elegido en el modal), lo valida y deja pendientes las    }
{    líneas de más (una por serie o lote). Con los interruptores apagados no   }
{    toca nada.                                                                }
{******************************************************************************}
unit inLibLotesLineaDocumento;

interface

uses
  Data.DB, inLibTrazabilidad, inLibLotesPersistenciaIntf,
  inLibLotesVisualIntf, inLibAsignacionLoteLectura;

type
  TCamposLoteLinea = record
    Articulo: string;
    Sku: string;
    Descripcion: string;
    Cantidad: string;
    Lote: string;
    Caducidad: string;
    Linea: string;
  end;

  // Lo que el módulo de datos sabe del documento al grabar la línea.
  TDocumentoLineaLote = record
    TipoDocumento: string;
    Serie: string;
    Numero: string;
    CodigoAlmacen: string;
    CodigoProveedor: string;
  end;

  TAnadirLineasLoteEvent = reference to procedure(const ACodigo: string;
    const AAsignaciones: TArray<TAsignacionLote>);
  TAvisoLineaLoteEvent = reference to procedure(const AMensaje: string);
  // FZ-ISSUE-327: True si el usuario acepta la pregunta
  TConfirmarLineaLoteEvent = reference to function(
    const AMensaje: string): Boolean;

  TConfiguracionLotesLineas = record
    Activacion: TActivacionTrazabilidad;
    Lectura: ILecturaTrazabilidadArticulo;
    Repositorio: IRepositorioLotes;
    Selector: ISelectorLotesVisual;
    // Sentido de una línea en positivo (en negativo se invierte).
    Sentido: TSentidoLoteLectura;
    Campos: TCamposLoteLinea;
    // Tabla de líneas y campos de su clave (series repetidas).
    Tabla: string;
    CampoSerie: string;
    CampoNumero: string;
    // vgerLoteAsignarFefo / vgerSerieExigirEnVenta en salidas.
    AsignarFefo: Boolean;
    ExigirSerieEnVenta: Boolean;
    DiasAvisoGeneral: Integer;
    AnadirLineas: TAnadirLineasLoteEvent;
    Avisar: TAvisoLineaLoteEvent;
    // FZ-ISSUE-327: si está asignado y se eligen menos unidades de las que
    // pide la línea, se pregunta antes de rebajarla; «No» deja la línea sin
    // grabar con su cantidad. Sin asignar, se rebaja como hasta ahora.
    ConfirmarMenosUnidades: TConfirmarLineaLoteEvent;
    // F-LOTEC-013: las series o lotes de más se dan de alta copiando la
    // línea recién grabada, en su AfterPost, en vez de por el lector
    // (documentos cuya rejilla descarta las líneas en blanco en diferido).
    CopiarLineasPendientes: Boolean;
  end;

  TLotesLineasDocumento = class
  private
    FConfig: TConfiguracionLotesLineas;
    FPendienteCodigo: string;
    FPendientes: TArray<TAsignacionLote>;
    FUltimaLinea: TDataSet;
    FCopiando: Boolean;
    // Lote que acaba de elegir ElegirLote: su Post no lo vuelve a validar.
    FLoteElegido: string;
    procedure CopiarLineaConAsignaciones(ALinea: TDataSet;
      const AAsignaciones: TArray<TAsignacionLote>);
    // Las series o lotes de más: copiando la línea (CopiarLineasPendientes)
    // o por el lector (EncolarAlta).
    procedure DarDeAltaPendientes(ALinea: TDataSet; const ACodigo: string;
      const AAsignaciones: TArray<TAsignacionLote>);
    procedure EncolarAlta(const ACodigo: string;
      const AAsignaciones: TArray<TAsignacionLote>);
    function Contexto(ALinea: TDataSet; const ADocumento: TDocumentoLineaLote;
      const ATrazabilidad: TTrazabilidadArticulo): TContextoLoteLectura;
    function DecidirSinLote(ALinea: TDataSet;
      const ADocumento: TDocumentoLineaLote;
      const ATrazabilidad: TTrazabilidadArticulo): Boolean;
    procedure ComprobarLoteTecleado(ALinea: TDataSet;
      const ADocumento: TDocumentoLineaLote;
      const ATrazabilidad: TTrazabilidadArticulo; const ALote: string);
    procedure ComprobarCatalogoEntrada(ALinea: TDataSet;
      const ADocumento: TDocumentoLineaLote; const ALote: string);
    function SentidoLinea(ALinea: TDataSet): TSentidoLoteLectura;
    procedure Rechazar(const AMensaje: string);
  public
    constructor Create(const AConfig: TConfiguracionLotesLineas);
    // BeforePost de la línea. Si la línea no vale, avisa y lanza EAbort.
    procedure AntesDePostLinea(ALinea: TDataSet;
      const ADocumento: TDocumentoLineaLote);
    // AfterPost: encola el alta de las líneas de más.
    procedure DespuesDePostLinea;
    // Botón de la columna Lote: vuelve a decidir el lote de la línea actual
    // (modal en LOTE y SERIE) y la graba. Cancelado, la línea no cambia.
    procedure ElegirLote(ALinea: TDataSet;
      const ADocumento: TDocumentoLineaLote);
    property Configuracion: TConfiguracionLotesLineas read FConfig;
  end;

type
  // Línea ya grabada (documento de trabajo que se envía a otro documento).
  TLineaLoteGrabada = record
    Linea: string;
    Articulo: string;
    Lote: string;
    FechaCaducidad: TDate;
    Cantidad: Double;
  end;

function CamposLoteLinea(const ASufijo: string): TCamposLoteLinea;
// FZ-ISSUE-327: unidades que cubren las asignaciones elegidas
function TotalAsignaciones(
  const AAsignaciones: TArray<TAsignacionLote>): Double;
// FZ-ISSUE-327: True si las asignaciones no cubren APedida (en positivo)
function FaltanUnidadesAsignadas(APedida: Double;
  const AAsignaciones: TArray<TAsignacionLote>): Boolean;
// Problemas de lote de unas líneas grabadas ('' si todas valen): falta el
// lote o la serie, la serie lleva más de una unidad o, si
// AExigirCaducidad (entradas), falta la caducidad obligatoria. Con todo
// apagado no consulta nada.
function ValidarLotesLineasGrabadas(const ALineas: TArray<TLineaLoteGrabada>;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo;
  AExigirCaducidad: Boolean): string;
// Limpia el lote donde no aplica y valida el de la línea. Con todo apagado
// devuelve vllCorrecta sin tocar la línea.
function PrepararLoteLinea(ALinea: TDataSet; const ACampos: TCamposLoteLinea;
  const AActivacion: TActivacionTrazabilidad;
  const ATrazabilidad: TTrazabilidadArticulo): TValidacionLineaLote;
function TextoValidacionLineaLote(AValidacion: TValidacionLineaLote;
  const AArticulo, ALote: string): string;

implementation

uses
  System.SysUtils, System.Classes, System.Math, System.Variants,
  System.Generics.Collections, inLibArticulosValidadorIntf,
  inLibMsgTrazabilidad, inLibLecturaGs1Pendiente, inLibErroresBBDD;

const
  // Problemas que se enumeran al enviar; del resto solo se da la cuenta.
  MAXIMO_LINEAS_LISTADAS = 10;

function ValidarLotesLineasGrabadas(const ALineas: TArray<TLineaLoteGrabada>;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo;
  AExigirCaducidad: Boolean): string;
var
  dicTrazabilidad: TDictionary<string, TTrazabilidadArticulo>;
  iProblemas: Integer;
  oModo: TModoTrazabilidad;
  oValidacion: TValidacionLineaLote;
  rLinea: TLineaLoteGrabada;
  rTrazabilidad: TTrazabilidadArticulo;
  sLote: string;
begin
  Result := '';
  iProblemas := 0;
  if AActivacion.AlgunModoActivo then
  begin
    if not Assigned(ALectura) then
      raise EArgumentNilException.Create('ALectura');
    dicTrazabilidad := TDictionary<string, TTrazabilidadArticulo>.Create;
    try
      for rLinea in ALineas do
      begin
        if Trim(rLinea.Articulo) <> '' then
        begin
          if not dicTrazabilidad.TryGetValue(UpperCase(rLinea.Articulo),
                                             rTrazabilidad) then
          begin
            rTrazabilidad := ALectura.Leer(rLinea.Articulo);
            dicTrazabilidad.Add(UpperCase(rLinea.Articulo), rTrazabilidad);
          end;
          oModo := AActivacion.ModoEfectivo(rTrazabilidad.Modo);
          sLote := NormalizarLote(rLinea.Lote);
          oValidacion := vllCorrecta;
          if RequiereLote(oModo) then
            oValidacion := ValidarLineaLote(oModo,
              rTrazabilidad.EsCaducidadObligatoria and AExigirCaducidad,
              sLote, rLinea.FechaCaducidad, Abs(rLinea.Cantidad));
          if oValidacion <> vllCorrecta then
          begin
            Inc(iProblemas);
            if iProblemas <= MAXIMO_LINEAS_LISTADAS then
              Result := Result + sLineBreak + Format(SErrorLineaNumeroLote,
                [rLinea.Linea, TextoValidacionLineaLote(oValidacion,
                  rLinea.Articulo, sLote)]);
          end;
        end;
      end;
    finally
      FreeAndNil(dicTrazabilidad);
    end;
  end;
  if iProblemas > MAXIMO_LINEAS_LISTADAS then
    Result := Result + sLineBreak + Format(SErrorMasLineasSinLote,
      [iProblemas - MAXIMO_LINEAS_LISTADAS]);
  if Result <> '' then
    Result := SErrorEnvioLineasSinLote + sLineBreak + Result;
end;

function CamposLoteLinea(const ASufijo: string): TCamposLoteLinea;
begin
  Result.Articulo := 'CODIGO_ART_' + ASufijo;
  Result.Sku := 'CODIGO_UNIDAD_' + ASufijo;
  Result.Descripcion := 'DESCRIPCION_ARTICULO_' + ASufijo;
  Result.Cantidad := 'CANTIDAD_' + ASufijo;
  Result.Lote := 'LOTE_' + ASufijo;
  Result.Caducidad := 'FECHA_CADUCIDAD_' + ASufijo;
  Result.Linea := 'LINEA_' + ASufijo;
end;

function ContieneLote(const ALotes: TArray<string>;
  const ALote: string): Boolean;
var
  sLote: string;
begin
  // Sin distinguir mayúsculas, como compara MariaDB.
  Result := False;
  for sLote in ALotes do
  begin
    if SameText(NormalizarLote(sLote), ALote) then
      Result := True;
  end;
end;

procedure EscribirLoteEnCampos(ALinea: TDataSet;
  const ACampos: TCamposLoteLinea; const AAsignacion: TAsignacionLote);
begin
  ALinea.FieldByName(ACampos.Lote).AsString := AAsignacion.Lote;
  if ALinea.FindField(ACampos.Caducidad) <> nil then
  begin
    if AAsignacion.FechaCaducidad = SIN_FECHA then
      ALinea.FieldByName(ACampos.Caducidad).Clear
    else
      ALinea.FieldByName(ACampos.Caducidad).AsDateTime :=
        AAsignacion.FechaCaducidad;
  end;
end;

function TextoCampo(ALinea: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ALinea.FindField(ACampo);
  if Assigned(oCampo) then
    Result := Trim(oCampo.AsString);
end;

function FechaCampo(ALinea: TDataSet; const ACampo: string): TDate;
var
  oCampo: TField;
begin
  Result := SIN_FECHA;
  oCampo := ALinea.FindField(ACampo);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := Trunc(oCampo.AsDateTime);
end;

// La línea es nueva o le han cambiado el lote o el SKU (lo ya grabado no
// se vuelve a validar: su propio movimiento ya ha descontado el stock).
function LoteCambiado(ALinea: TDataSet;
  const ACampos: TCamposLoteLinea): Boolean;

  function Cambiado(const ACampo: string): Boolean;
  var
    oCampo: TField;
  begin
    oCampo := ALinea.FindField(ACampo);
    Result := Assigned(oCampo) and
      not SameText(Trim(VarToStr(oCampo.OldValue)), Trim(oCampo.AsString));
  end;

begin
  Result := (ALinea.State = dsInsert) or Cambiado(ACampos.Lote) or
            Cambiado(ACampos.Sku);
end;

procedure LimpiarCampo(ALinea: TDataSet; const ACampo: string);
var
  oCampo: TField;
begin
  oCampo := ALinea.FindField(ACampo);
  if Assigned(oCampo) and not oCampo.IsNull and (oCampo.AsString <> '') then
    oCampo.Clear;
end;

function PrepararLoteLinea(ALinea: TDataSet; const ACampos: TCamposLoteLinea;
  const AActivacion: TActivacionTrazabilidad;
  const ATrazabilidad: TTrazabilidadArticulo): TValidacionLineaLote;
var
  oModo: TModoTrazabilidad;
  sLote: string;
begin
  Result := vllCorrecta;
  if AActivacion.AlgunModoActivo then
  begin
    oModo := AActivacion.ModoEfectivo(ATrazabilidad.Modo);
    if not RequiereLote(oModo) then
    begin
      LimpiarCampo(ALinea, ACampos.Lote);
      LimpiarCampo(ALinea, ACampos.Caducidad);
    end
    else
    begin
      sLote := NormalizarLote(TextoCampo(ALinea, ACampos.Lote));
      if (ALinea.FindField(ACampos.Lote) <> nil) and
         (ALinea.FieldByName(ACampos.Lote).AsString <> sLote) then
        ALinea.FieldByName(ACampos.Lote).AsString := sLote;
      Result := ValidarLineaLote(oModo, ATrazabilidad.EsCaducidadObligatoria,
        sLote, FechaCampo(ALinea, ACampos.Caducidad),
        ALinea.FieldByName(ACampos.Cantidad).AsFloat);
    end;
  end;
end;

function TextoValidacionLineaLote(AValidacion: TValidacionLineaLote;
  const AArticulo, ALote: string): string;
begin
  case AValidacion of
    vllFaltaLote:
      Result := Format(SErrorLineaFaltaLote, [AArticulo]);
    vllLoteSobrante:
      Result := Format(SErrorLineaLoteSobrante, [AArticulo, ALote]);
    vllLoteDemasiadoLargo:
      Result := Format(SErrorLoteLeidoDemasiadoLargo,
                       [ALote, LONGITUD_MAXIMA_LOTE]);
    vllFaltaCaducidad:
      Result := Format(SErrorLineaFaltaCaducidad, [ALote, AArticulo]);
    vllCantidadSerie:
      Result := Format(SErrorLineaCantidadSerie, [AArticulo]);
    vllCaducidadFueraDeRango:
      Result := Format(SErrorLineaCaducidadFueraDeRango,
                       [ALote, AArticulo]);
  else
    Result := '';
  end;
end;

{ TLotesLineasDocumento }

constructor TLotesLineasDocumento.Create(
  const AConfig: TConfiguracionLotesLineas);
begin
  inherited Create;
  if not Assigned(AConfig.Avisar) then
    raise EArgumentNilException.Create('Avisar');
  FConfig := AConfig;
end;

function TotalAsignaciones(
  const AAsignaciones: TArray<TAsignacionLote>): Double;
var
  rAsignacion: TAsignacionLote;
begin
  Result := 0;
  for rAsignacion in AAsignaciones do
    Result := Result + rAsignacion.Cantidad;
end;

function FaltanUnidadesAsignadas(APedida: Double;
  const AAsignaciones: TArray<TAsignacionLote>): Boolean;
const
  CTolerancia = 0.0005;
begin
  Result := (Length(AAsignaciones) > 0) and
    (TotalAsignaciones(AAsignaciones) < Abs(APedida) - CTolerancia);
end;

procedure TLotesLineasDocumento.Rechazar(const AMensaje: string);
begin
  // El aviso se presenta fuera del Post: un modal dentro de la validacion
  // de un editor puede volver a guardar la misma linea al cambiar el foco.
  if AMensaje <> '' then
    raise EValidacionBBDD.Create(AMensaje);
  Abort;
end;

function TLotesLineasDocumento.Contexto(ALinea: TDataSet;
  const ADocumento: TDocumentoLineaLote;
  const ATrazabilidad: TTrazabilidadArticulo): TContextoLoteLectura;
var
  dCantidad: Double;
begin
  dCantidad := ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat;
  Result := Default(TContextoLoteLectura);
  Result.Activacion := FConfig.Activacion;
  Result.Modo := ATrazabilidad.Modo;
  Result.EsCaducidadObligatoria := ATrazabilidad.EsCaducidadObligatoria;
  Result.Sentido := SentidoLinea(ALinea);
  Result.CodigoAlmacen := ADocumento.CodigoAlmacen;
  Result.DescripcionArticulo := TextoCampo(ALinea,
                                           FConfig.Campos.Descripcion);
  Result.Cantidad := Abs(dCantidad);
  Result.AsignarFefo := FConfig.AsignarFefo;
  Result.ExigirSerieEnVenta := FConfig.ExigirSerieEnVenta;
  Result.DiasAviso := DiasAvisoEfectivos(ATrazabilidad.DiasAviso,
                                         FConfig.DiasAvisoGeneral);
  Result.Hoy := Date;
  Result.SeriesDocumento := FConfig.Lectura.LotesOtrasLineas(FConfig.Tabla,
    FConfig.CampoSerie, FConfig.CampoNumero, FConfig.Campos.Linea,
    FConfig.Campos.Lote, ADocumento.Serie, ADocumento.Numero,
    TextoCampo(ALinea, FConfig.Campos.Linea));
end;

function TLotesLineasDocumento.DecidirSinLote(ALinea: TDataSet;
  const ADocumento: TDocumentoLineaLote;
  const ATrazabilidad: TTrazabilidadArticulo): Boolean;
var
  dSigno: Double;
  rDecision: TDecisionLoteLectura;
  rResolucion: TArtResolucionEntrada;
begin
  // La línea no trae lote: la regla común lo decide (y puede abrir el
  // modal). La primera asignación va en esta línea; el resto, pendiente.
  rResolucion.Clear;
  rResolucion.Encontrado := True;
  rResolucion.CodigoArticulo := TextoCampo(ALinea, FConfig.Campos.Articulo);
  rResolucion.CodigoSku := TextoCampo(ALinea, FConfig.Campos.Sku);
  rDecision := DecidirLoteLectura(rResolucion,
    Contexto(ALinea, ADocumento, ATrazabilidad), FConfig.Repositorio,
    FConfig.Selector);
  Result := rDecision.Resultado in [rllSinLote, rllAsignado];
  if rDecision.Error <> '' then
    FConfig.Avisar(rDecision.Error)
  else if rDecision.Aviso <> '' then
    FConfig.Avisar(rDecision.Aviso);
  // FZ-ISSUE-327: la línea se rebajaría a lo elegido sin que el usuario lo
  // sepa (en traspasos, justo antes de grabar el documento)
  if Result and Assigned(FConfig.ConfirmarMenosUnidades) and
     FaltanUnidadesAsignadas(
       ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat,
       rDecision.Asignaciones) then
    Result := FConfig.ConfirmarMenosUnidades(Format(
      SConfirmarMenosUnidadesLoteLinea,
      [FormatFloat('0.###', TotalAsignaciones(rDecision.Asignaciones)),
       FormatFloat('0.###',
         Abs(ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat)),
       TextoCampo(ALinea, FConfig.Campos.Articulo)]));
  if Result and (Length(rDecision.Asignaciones) > 0) then
  begin
    dSigno := Sign(ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat);
    if dSigno = 0 then
      dSigno := 1;
    ALinea.FieldByName(FConfig.Campos.Lote).AsString :=
      rDecision.Asignaciones[0].Lote;
    if ALinea.FindField(FConfig.Campos.Caducidad) <> nil then
    begin
      if rDecision.Asignaciones[0].FechaCaducidad = SIN_FECHA then
        ALinea.FieldByName(FConfig.Campos.Caducidad).Clear
      else
        ALinea.FieldByName(FConfig.Campos.Caducidad).AsDateTime :=
          rDecision.Asignaciones[0].FechaCaducidad;
    end;
    if rDecision.Asignaciones[0].Cantidad > 0 then
      ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat :=
        dSigno * rDecision.Asignaciones[0].Cantidad;
    FPendienteCodigo := rResolucion.CodigoSku;
    FPendientes := Copy(rDecision.Asignaciones, 1, MaxInt);
  end;
end;

function TLotesLineasDocumento.SentidoLinea(
  ALinea: TDataSet): TSentidoLoteLectura;
begin
  // Una línea en negativo va al revés (devolución al proveedor...).
  Result := FConfig.Sentido;
  if ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat < 0 then
  begin
    if FConfig.Sentido = sllEntrada then
      Result := sllSalida
    else
      Result := sllEntrada;
  end;
end;

procedure TLotesLineasDocumento.ComprobarLoteTecleado(ALinea: TDataSet;
  const ADocumento: TDocumentoLineaLote;
  const ATrazabilidad: TTrazabilidadArticulo; const ALote: string);
var
  oCaducidad: TField;
  rContexto: TContextoLoteLectura;
  rDecision: TDecisionLoteLectura;
  rResolucion: TArtResolucionEntrada;
begin
  // F-LOTEC-016: un lote o serie tecleado se valida como si se hubiera
  // leído: en salidas debe estar en el almacén (la serie, con stock) y una
  // serie de entrada no puede estar ya en stock.
  rResolucion.Clear;
  rResolucion.Encontrado := True;
  rResolucion.CodigoArticulo := TextoCampo(ALinea, FConfig.Campos.Articulo);
  rResolucion.CodigoSku := TextoCampo(ALinea, FConfig.Campos.Sku);
  rResolucion.Lote := ALote;
  rResolucion.FechaCaducidad := FechaCampo(ALinea, FConfig.Campos.Caducidad);
  rContexto := Contexto(ALinea, ADocumento, ATrazabilidad);
  // La serie repetida en el documento la comprueba AntesDePostLinea.
  rContexto.SeriesDocumento := [];
  rDecision := DecidirLoteLectura(rResolucion, rContexto,
    FConfig.Repositorio, FConfig.Selector);
  if rDecision.Resultado = rllRechazado then
    Rechazar(rDecision.Error);
  if rDecision.Aviso <> '' then
    FConfig.Avisar(rDecision.Aviso);
  // La caducidad del lote que sale la pone el catálogo.
  oCaducidad := ALinea.FindField(FConfig.Campos.Caducidad);
  if Assigned(oCaducidad) and oCaducidad.IsNull and
     (Length(rDecision.Asignaciones) > 0) and
     (rDecision.Asignaciones[0].FechaCaducidad <> SIN_FECHA) then
    oCaducidad.AsDateTime := rDecision.Asignaciones[0].FechaCaducidad;
end;

procedure TLotesLineasDocumento.ComprobarCatalogoEntrada(
  ALinea: TDataSet; const ADocumento: TDocumentoLineaLote;
  const ALote: string);
var
  rCatalogo: TLoteCatalogo;
  oCaducidad: TField;
  sProveedor: string;
begin
  if (ALote <> '') and Assigned(FConfig.Repositorio) and
     (SentidoLinea(ALinea) = sllEntrada) and
     FConfig.Repositorio.BuscarLote(
       TextoCampo(ALinea, FConfig.Campos.Sku), ALote, rCatalogo) then
  begin
    sProveedor := Trim(rCatalogo.CodigoProveedor);
    if (sProveedor <> '') and (sProveedor <> '0') and
       (Trim(ADocumento.CodigoProveedor) <> '') and
       (Trim(ADocumento.CodigoProveedor) <> '0') and
       not SameText(sProveedor, Trim(ADocumento.CodigoProveedor)) then
      Rechazar(Format(SErrorLoteProveedorDistinto,
        [ALote, sProveedor]));
    oCaducidad := ALinea.FindField(FConfig.Campos.Caducidad);
    if Assigned(oCaducidad) and
       (rCatalogo.FechaCaducidad <> SIN_FECHA) then
    begin
      if oCaducidad.IsNull then
        oCaducidad.AsDateTime := rCatalogo.FechaCaducidad
      else if Trunc(oCaducidad.AsDateTime) <>
              Trunc(rCatalogo.FechaCaducidad) then
        Rechazar(Format(SErrorLoteCaducidadContradictoria,
          [ALote, DateToStr(rCatalogo.FechaCaducidad)]));
    end;
  end;
end;

procedure TLotesLineasDocumento.AntesDePostLinea(ALinea: TDataSet;
  const ADocumento: TDocumentoLineaLote);
var
  bConRegla: Boolean;
  oModo: TModoTrazabilidad;
  oValidacion: TValidacionLineaLote;
  rGs1: TLecturaGs1Pendiente;
  rTrazabilidad: TTrazabilidadArticulo;
  sArticulo: string;
  sLote: string;
begin
  FPendientes := [];
  FUltimaLinea := ALinea;
  sArticulo := TextoCampo(ALinea, FConfig.Campos.Articulo);
  if FConfig.Activacion.AlgunModoActivo and Assigned(FConfig.Lectura) and
     (sArticulo <> '') then
  begin
    rTrazabilidad := FConfig.Lectura.Leer(sArticulo);
    oModo := FConfig.Activacion.ModoEfectivo(rTrazabilidad.Modo);
    bConRegla := RequiereLote(oModo) and
      (TextoCampo(ALinea, FConfig.Campos.Sku) <> '') and
      Assigned(FConfig.Repositorio) and Assigned(FConfig.Selector);
    sLote := NormalizarLote(TextoCampo(ALinea, FConfig.Campos.Lote));
    // Un GS1 que entró por la rejilla trae su lote, serie y caducidad: se
    // toman como leídos (y se validan) en vez de decidir el lote.
    if bConRegla and (sLote = '') and
       TomarLecturaGs1(TextoCampo(ALinea, FConfig.Campos.Sku), rGs1) then
    begin
      sLote := NormalizarLote(rGs1.Lote);
      if (oModo = mtSerie) and (Trim(rGs1.Serie) <> '') then
        sLote := NormalizarLote(rGs1.Serie);
      if sLote <> '' then
      begin
        ALinea.FieldByName(FConfig.Campos.Lote).AsString := sLote;
        if (rGs1.FechaCaducidad <> SIN_FECHA) and
           (ALinea.FindField(FConfig.Campos.Caducidad) <> nil) and
           ALinea.FieldByName(FConfig.Campos.Caducidad).IsNull then
          ALinea.FieldByName(FConfig.Campos.Caducidad).AsDateTime :=
            rGs1.FechaCaducidad;
      end;
    end;
    if bConRegla and (sLote = '') then
    begin
      if not DecidirSinLote(ALinea, ADocumento, rTrazabilidad) then
        Rechazar('');
    end
    else if bConRegla and LoteCambiado(ALinea, FConfig.Campos) and
            not SameText(sLote, FLoteElegido) and
            ((oModo = mtSerie) or
             (SentidoLinea(ALinea) = sllSalida)) then
      ComprobarLoteTecleado(ALinea, ADocumento, rTrazabilidad, sLote);
    // Recuperar la fecha antes de exigir la caducidad obligatoria.
    if RequiereLote(oModo) then
      ComprobarCatalogoEntrada(ALinea, ADocumento,
        NormalizarLote(TextoCampo(ALinea, FConfig.Campos.Lote)));
    oValidacion := PrepararLoteLinea(ALinea, FConfig.Campos,
      FConfig.Activacion, rTrazabilidad);
    sLote := NormalizarLote(TextoCampo(ALinea, FConfig.Campos.Lote));
    if oValidacion <> vllCorrecta then
      Rechazar(TextoValidacionLineaLote(oValidacion, sArticulo, sLote));
    if (oModo = mtSerie) and (sLote <> '') and
       ContieneLote(FConfig.Lectura.LotesOtrasLineas(FConfig.Tabla,
         FConfig.CampoSerie, FConfig.CampoNumero, FConfig.Campos.Linea,
         FConfig.Campos.Lote, ADocumento.Serie, ADocumento.Numero,
         TextoCampo(ALinea, FConfig.Campos.Linea)), sLote) then
      Rechazar(Format(SErrorSerieRepetidaDocumento, [sLote]));
  end;
end;

procedure TLotesLineasDocumento.EncolarAlta(const ACodigo: string;
  const AAsignaciones: TArray<TAsignacionLote>);
var
  aPendientes: TArray<TAsignacionLote>;
  oAnadir: TAnadirLineasLoteEvent;
  sCodigo: string;
begin
  if (Length(AAsignaciones) > 0) and Assigned(FConfig.AnadirLineas) then
  begin
    // Fuera del Post: el alta de líneas nuevas no cabe dentro de él.
    aPendientes := AAsignaciones;
    sCodigo := ACodigo;
    oAnadir := FConfig.AnadirLineas;
    TThread.ForceQueue(nil,
      procedure
      begin
        oAnadir(sCodigo, aPendientes);
      end);
  end;
end;

procedure TLotesLineasDocumento.DarDeAltaPendientes(ALinea: TDataSet;
  const ACodigo: string; const AAsignaciones: TArray<TAsignacionLote>);
begin
  if FConfig.CopiarLineasPendientes then
  begin
    if (Length(AAsignaciones) > 0) and Assigned(ALinea) and
       not FCopiando then
      CopiarLineaConAsignaciones(ALinea, AAsignaciones);
  end
  else
    EncolarAlta(ACodigo, AAsignaciones);
end;

procedure TLotesLineasDocumento.DespuesDePostLinea;
var
  aPendientes: TArray<TAsignacionLote>;
begin
  aPendientes := FPendientes;
  FPendientes := [];
  DarDeAltaPendientes(FUltimaLinea, FPendienteCodigo, aPendientes);
end;

procedure TLotesLineasDocumento.CopiarLineaConAsignaciones(ALinea: TDataSet;
  const AAsignaciones: TArray<TAsignacionLote>);
var
  aCampos: TArray<string>;
  aValores: TArray<Variant>;
  dSigno: Double;
  iCampo: Integer;
  oCampo: TField;
  rAsignacion: TAsignacionLote;
begin
  // Los datos de la línea recién grabada (precio, IVA, artículo...) salvo
  // su número, lote, caducidad y cantidad, que pone cada asignación.
  aCampos := [];
  aValores := [];
  for oCampo in ALinea.Fields do
  begin
    if (oCampo.FieldKind = fkData) and not oCampo.ReadOnly and
       not SameText(oCampo.FieldName, FConfig.Campos.Linea) and
       not SameText(oCampo.FieldName, FConfig.Campos.Lote) and
       not SameText(oCampo.FieldName, FConfig.Campos.Caducidad) and
       not SameText(oCampo.FieldName, FConfig.Campos.Cantidad) then
    begin
      aCampos := aCampos + [oCampo.FieldName];
      aValores := aValores + [oCampo.Value];
    end;
  end;
  dSigno := Sign(ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat);
  if dSigno = 0 then
    dSigno := 1;
  FCopiando := True;
  try
    for rAsignacion in AAsignaciones do
    begin
      ALinea.Append;
      for iCampo := 0 to High(aCampos) do
        ALinea.FieldByName(aCampos[iCampo]).Value := aValores[iCampo];
      ALinea.FieldByName(FConfig.Campos.Cantidad).AsFloat :=
        dSigno * rAsignacion.Cantidad;
      EscribirLoteEnCampos(ALinea, FConfig.Campos, rAsignacion);
      ALinea.Post;
    end;
  finally
    FCopiando := False;
  end;
end;

procedure TLotesLineasDocumento.ElegirLote(ALinea: TDataSet;
  const ADocumento: TDocumentoLineaLote);
var
  aPendientes: TArray<TAsignacionLote>;
  oModo: TModoTrazabilidad;
  rTrazabilidad: TTrazabilidadArticulo;
  sArticulo: string;
  sCodigo: string;
  sLoteAnterior: string;
  vCaducidadAnterior: Variant;
begin
  sArticulo := TextoCampo(ALinea, FConfig.Campos.Articulo);
  if FConfig.Activacion.AlgunModoActivo and Assigned(FConfig.Lectura) and
     Assigned(FConfig.Repositorio) and Assigned(FConfig.Selector) and
     (sArticulo <> '') and (TextoCampo(ALinea, FConfig.Campos.Sku) <> '')
  then
  begin
    rTrazabilidad := FConfig.Lectura.Leer(sArticulo);
    oModo := FConfig.Activacion.ModoEfectivo(rTrazabilidad.Modo);
    if RequiereLote(oModo) then
    begin
      if not (ALinea.State in dsEditModes) then
        ALinea.Edit;
      sLoteAnterior := ALinea.FieldByName(FConfig.Campos.Lote).AsString;
      vCaducidadAnterior := Null;
      if ALinea.FindField(FConfig.Campos.Caducidad) <> nil then
        vCaducidadAnterior :=
          ALinea.FieldByName(FConfig.Campos.Caducidad).Value;
      LimpiarCampo(ALinea, FConfig.Campos.Lote);
      LimpiarCampo(ALinea, FConfig.Campos.Caducidad);
      FPendientes := [];
      if DecidirSinLote(ALinea, ADocumento, rTrazabilidad) then
      begin
        aPendientes := FPendientes;
        sCodigo := FPendienteCodigo;
        FLoteElegido := NormalizarLote(TextoCampo(ALinea,
                                                  FConfig.Campos.Lote));
        try
          ALinea.Post;
        finally
          FLoteElegido := '';
        end;
        // F-LOTEC-013: en la factura de compra, copiando la línea (la
        // rejilla descarta las líneas en blanco que daría el lector).
        DarDeAltaPendientes(ALinea, sCodigo, aPendientes);
      end
      else
      begin
        ALinea.FieldByName(FConfig.Campos.Lote).AsString := sLoteAnterior;
        if ALinea.FindField(FConfig.Campos.Caducidad) <> nil then
          ALinea.FieldByName(FConfig.Campos.Caducidad).Value :=
            vCaducidadAnterior;
      end;
    end;
  end;
end;

end.

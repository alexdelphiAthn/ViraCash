{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCambioArticuloColorHistorico                           }
{    Tipo:       Repositorio UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Diario reversible de cambios de artículo y color mediante instantáneas.   }
{******************************************************************************}
unit UniDataCambioArticuloColorHistorico;

interface

uses
  System.SysUtils,
  System.Classes,
  Uni,
  inLibCambioArticuloColorIntf;

const
  TIPO_CAMBIO_ARTICULO = 'CAMBIO_ARTICULO';
  TIPO_FUSION_ARTICULO = 'FUSION_ARTICULO';
  TIPO_CAMBIO_COLOR = 'CAMBIO_COLOR';
  TIPO_FUSION_COLOR = 'FUSION_COLOR';
  TIPO_REVERSION = 'REVERSION';

  OBJETO_ARTICULO = 'ARTICULO';
  OBJETO_COLOR = 'COLOR';

type
  EHistoricoCambioArticuloColor = class(Exception)
  private
    FCausa: TCausaReversionHistorico;
  public
    constructor Create(
      ACausa: TCausaReversionHistorico;
      const AMensaje: string);
    property Causa: TCausaReversionHistorico read FCausa;
  end;

  THistoricoCambioArticuloColor = class
  private
    FImplementacion: TObject;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    { La ida usa la transacción SERIALIZABLE que ya abrió el repositorio. }
    procedure IniciarOperacion(
      const ATipoOperacion, ATipoObjeto, ACodigoOrigen,
      ACodigoDestino, AUsuario: string);
    { Se admite un solo ámbito por tabla. El criterio debe incluir las filas
      origen y destino, y seguir siendo válido hasta CompletarOperacion. Los
      ámbitos se añaden en orden maestro-hijo para invertirlos con seguridad.
      La condición debe ser literal y no depender de parámetros ni temporales. }
    procedure CapturarAntes(
      const ATabla, ACondicion: string;
      const ANombres, AValores: array of string);
    procedure CompletarOperacion(
      ACantidadUnidades: Integer;
      const ADetalle: string = '');
    { Revertir abre SERIALIZABLE si es necesario. La variante EnTransaccion
      crea un punto de restauración y nunca confirma la transacción ajena. }
    function Revertir(
      const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
    function RevertirEnTransaccion(
      const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
    function IdOperacion: string;
  end;

implementation

uses
  System.Hash,
  System.JSON,
  System.Generics.Collections,
  Data.DB,
  inLibCambioArticuloColorHistoricoAmbito;

resourcestring
  SErrorIdentificadorSqlHistoricoNoPermitido =
    'Identificador SQL no permitido: %s.';
  SErrorTipoOperacionHistoricoNoPermitido =
    'Tipo de operación histórico no permitido: %s.';
  SErrorTipoObjetoHistoricoNoPermitido =
    'Tipo de objeto histórico no permitido: %s.';
  SErrorAmbitoHistoricoAlterado =
    'El histórico contiene un ámbito no persistible o alterado.';
  SErrorIdentificadorHistoricoNoGenerado =
    'No se pudo generar el identificador del histórico.';
  SErrorTablaHistoricoNoExiste =
    'La tabla %s no existe en la base de datos actual.';
  SErrorTablaHistoricoSinClavePrimaria =
    'La tabla %s no tiene una clave primaria reversible.';
  SErrorCabeceraHistoricoNoAplicada =
    'No se pudo aplicar la cabecera del histórico.';
  SErrorHistoricoFueraTransaccion =
    'El histórico debe iniciarse dentro de la transacción del cambio.';
  SErrorOperacionHistoricoEnCurso =
    'Ya hay una operación de histórico en curso.';
  SErrorUsuarioHistoricoObligatorio =
    'El usuario del histórico es obligatorio.';
  SErrorOperacionHistoricoNoPreparadaCaptura =
    'No hay una operación preparada para capturar instantáneas.';
  SErrorLineasFacturaProtegidasHistorico =
    'Las líneas de factura están protegidas y no se historizan.';
  SErrorTablaHistoricoAutocontenida =
    'La tabla del histórico no puede contenerse a sí misma.';
  SErrorTablaAmbitoHistoricoDuplicada =
    'La tabla %s ya tiene un ámbito en esta operación.';
  SErrorParametrosAmbitoHistoricoNoCoinciden =
    'Los nombres y valores de parámetros no coinciden.';
  SErrorAmbitoHistoricoConParametros =
    'El ámbito histórico debe usar literales y no parámetros.';
  SErrorAmbitoHistoricoNoPersistible =
    'El ámbito histórico no admite parámetros, variables, referencias ' +
    'temporales ni sentencias no persistibles.';
  SErrorOperacionHistoricoNoPreparadaCompletar =
    'No hay una operación preparada para completar.';
  SErrorEsquemaCambioDuranteOperacion =
    'El esquema cambió durante la operación: %s.';
  SErrorOperacionHistoricaNoExisteAplicada =
    'La operación histórica no existe o no está aplicada.';
  SErrorVersionHistoricoNoCompatible =
    'La versión del histórico no es compatible.';
  SErrorDetalleHistoricoAlterado =
    'El detalle del histórico está incompleto o alterado.';
  SErrorAmbitosFilasHistoricoIncompletos =
    'El histórico no conserva todos sus ámbitos de filas.';
  SErrorCantidadFilasHistoricoNoCoincide =
    'El número de filas del histórico no coincide con su cabecera.';
  SErrorTablaProtegidaHistorico =
    'El histórico contiene una tabla protegida.';
  SErrorEsquemaTablaHistoricoModificado =
    'El esquema de %s cambió desde la operación original.';
  SErrorClaveJsonHistoricoInvalida =
    'El histórico contiene una clave JSON no válida.';
  SErrorClavePrimariaHistoricoIncompleta =
    'El histórico no contiene toda la clave primaria.';
  SErrorAmbitoHistoricoDivergente =
    'El ámbito histórico contiene filas nuevas, retiradas o modificadas en ' +
    '%s.';
  SErrorEstadoFilaHistoricoInesperado =
    'La fila histórica ya no tiene el estado esperado en %s.';
  SErrorFilaHistoricoModificada =
    'La fila histórica fue modificada después en %s.';
  SErrorDatosJsonHistoricoInvalidos =
    'El histórico contiene datos JSON no válidos.';
  SErrorCamposHistoricoIncompletos =
    'El histórico no contiene todos los campos de %s.';
  SErrorRetiradaFilaHistoricoFallida =
    'No se pudo retirar exactamente una fila de %s.';
  SErrorRestauracionFilaHistoricoFallida =
    'No se pudo restaurar exactamente una fila de %s.';
  SErrorAccionHistoricoNoReconocida =
    'El histórico contiene una acción no reconocida.';
  SErrorReversionDeReversion =
    'Una reversión no se puede volver a revertir.';
  SErrorOperacionHistoricaYaRevertida =
    'La operación histórica ya tiene una reversión aplicada.';
  SErrorDependenciaPosteriorHistorico =
    'Hay una operación posterior que depende de las mismas filas.';
  SErrorFacturasRelacionadasHistorico =
    'Hay líneas de factura asociadas; no se puede revertir.';
  SErrorReversionSinTransaccion =
    'La reversión requiere una transacción activa.';
  SErrorOperacionReversionNoIndicada =
    'Debe indicarse la operación que se quiere revertir.';
  SErrorUsuarioReversionObligatorio =
    'El usuario de la reversión es obligatorio.';

const
  TABLA_HISTORICO = 'fza_articulos_cambios_historico';
  TABLA_FACTURAS = 'fza_facturas_lineas';
  VERSION_FORMATO = 1;

  ESTADO_PREPARADA = 'PREPARADA';
  ESTADO_APLICADA = 'APLICADA';

  REGISTRO_OPERACION = 'OPERACION';
  REGISTRO_FILA = 'FILA';
  REGISTRO_GUARDA = 'GUARDA';
  REGISTRO_AMBITO = 'AMBITO';

  ACCION_INSERTAR = 'INSERTAR';
  ACCION_ACTUALIZAR = 'ACTUALIZAR';
  ACCION_ELIMINAR = 'ELIMINAR';
  ACCION_COMPROBAR = 'COMPROBAR';

type
  TColumnaHistorico = class
  public
    Nombre: string;
    Tipo: string;
    TipoDatos: string;
    EsNulable: string;
    ValorDefecto: string;
    JuegoCaracteres: string;
    Intercalacion: string;
    Extra: string;
    ExpresionGenerada: string;
    EsClave: Boolean;
    function EsGenerada: Boolean;
  end;

  TMetadatosHistorico = class
  private
    FColumnas: TObjectList<TColumnaHistorico>;
    FFirma: string;
  public
    constructor Create;
    destructor Destroy; override;
    property Columnas: TObjectList<TColumnaHistorico> read FColumnas;
    property Firma: string read FFirma write FFirma;
  end;

  TAmbitoHistorico = class
  private
    FAntes: TObjectList<TFilaHistorico>;
    FMetadatos: TMetadatosHistorico;
  public
    Tabla: string;
    Condicion: string;
    constructor Create;
    destructor Destroy; override;
    property Antes: TObjectList<TFilaHistorico> read FAntes;
    property Metadatos: TMetadatosHistorico read FMetadatos
      write FMetadatos;
  end;

  TDetalleHistorico = class
  public
    Orden: Integer;
    TipoRegistro: string;
    TipoOperacion: string;
    TipoObjeto: string;
    Tabla: string;
    Accion: string;
    ClaveAntes: string;
    ClaveDespues: string;
    HashClaveAntes: string;
    HashClaveDespues: string;
    DatosAntes: string;
    DatosDespues: string;
    HashAntes: string;
    HashDespues: string;
    FirmaEsquema: string;
    TieneClaveAntes: Boolean;
    TieneClaveDespues: Boolean;
    TieneDatosAntes: Boolean;
    TieneDatosDespues: Boolean;
  end;

  TOperacionHistorico = class
  public
    Id: string;
    IdFila: Int64;
    TipoOperacion: string;
    TipoObjeto: string;
    CodigoOrigen: string;
    CodigoDestino: string;
    CantidadFilas: Integer;
    CantidadUnidades: Integer;
  end;

  THistoricoCambioArticuloColorImpl = class
  private
    FConexion: TUniConnection;
    FAmbitos: TObjectList<TAmbitoHistorico>;
    FIdOperacion: string;
    FTipoOperacion: string;
    FTipoObjeto: string;
    FCodigoOrigen: string;
    FCodigoDestino: string;
    FUsuario: string;
    FOrden: Integer;
    FIniciada: Boolean;
    FCompletada: Boolean;
    function NuevaConsulta: TUniQuery;
    procedure Ejecutar(const ASql: string);
    procedure ValidarIdentificador(const AIdentificador: string);
    procedure ValidarTipoOperacion(const ATipoOperacion: string);
    procedure ValidarTipoObjeto(const ATipoObjeto: string);
    function GenerarUuid: string;
    function CalcularHash(const ATexto: string): string;
    function BuscarAmbito(const ATabla: string): TAmbitoHistorico;
    function CargarMetadatos(const ATabla: string): TMetadatosHistorico;
    function ConstruirSeleccion(
      const ATabla, ACondicion: string;
      AMetadatos: TMetadatosHistorico;
      ABloquear: Boolean): string;
    function ExpresionHex(AColumna: TColumnaHistorico): string;
    function CrearJsonFila(
      AConsulta: TUniQuery;
      AMetadatos: TMetadatosHistorico;
      ASoloClave: Boolean): string;
    procedure CapturarFilas(
      const ATabla, ACondicion: string;
      AMetadatos: TMetadatosHistorico;
      ADestino: TObjectList<TFilaHistorico>;
      ABloquear: Boolean);
    procedure InsertarCabecera(
      const AId, ATipoOperacion, AIdOrigen, ATipoObjeto,
      ACodigoOrigen, ACodigoDestino, AUsuario: string);
    procedure MarcarCabeceraAplicada(
      const AId, AUsuario, ADetalle: string;
      ACantidadFilas, ACantidadUnidades: Integer);
    procedure InsertarDetalle(
      const AIdOperacion, ATipoOperacion, ATipoObjeto,
      AUsuario: string;
      ADetalle: TDetalleHistorico);
    procedure RegistrarDiferencias(
      AAmbito: TAmbitoHistorico;
      ADespues: TObjectList<TFilaHistorico>;
      var ACantidadFilas: Integer);
    procedure RegistrarAmbito(
      AAmbito: TAmbitoHistorico;
      ADespues: TObjectList<TFilaHistorico>);
    function CrearDetalle(
      const ATipoRegistro, AAccion: string;
      AAntes, ADespues: TFilaHistorico;
      const AFirma: string): TDetalleHistorico;
    function CargarOperacion(
      const AIdOperacion: string): TOperacionHistorico;
    function CargarDetalles(
      const AIdOperacion: string): TObjectList<TDetalleHistorico>;
    procedure ValidarDetalles(
      AOperacion: TOperacionHistorico;
      ADetalles: TObjectList<TDetalleHistorico>);
    function TieneReversionAplicada(
      const AIdOperacion: string): Boolean;
    function TieneDependenciaPosterior(
      AOperacion: TOperacionHistorico): Boolean;
    function HayFacturasRelacionadas(
      AOperacion: TOperacionHistorico): Boolean;
    procedure ComprobarEsquemas(
      ADetalles: TObjectList<TDetalleHistorico>;
      AMetadatos: TObjectDictionary<string, TMetadatosHistorico>);
    function ObtenerDatosActuales(
      const ATabla, AClave: string;
      AMetadatos: TMetadatosHistorico;
      out ADatos, AHash: string): Boolean;
    procedure ComprobarEstadoAmbito(
      ADetalle: TDetalleHistorico;
      AMetadatos: TMetadatosHistorico;
      AComprobarDespues: Boolean);
    procedure ComprobarEstadoActual(
      ADetalles: TObjectList<TDetalleHistorico>;
      AMetadatos: TObjectDictionary<string, TMetadatosHistorico>;
      AComprobarDespues: Boolean);
    procedure BorrarFila(
      const ATabla, AClave: string;
      AMetadatos: TMetadatosHistorico);
    procedure InsertarFila(
      const ATabla, ADatos: string;
      AMetadatos: TMetadatosHistorico);
    procedure RestaurarFilas(
      ADetalles: TObjectList<TDetalleHistorico>;
      AMetadatos: TObjectDictionary<string, TMetadatosHistorico>);
    function InvertirAccion(const AAccion: string): string;
    procedure RegistrarReversion(
      const AIdReversion, AUsuario: string;
      AOperacion: TOperacionHistorico;
      ADetalles: TObjectList<TDetalleHistorico>);
    function EjecutarReversion(
      const AIdOperacion, AUsuario: string): string;
    function RevertirInterno(
      const AIdOperacion, AUsuario: string;
      AExigirTransaccion: Boolean): TResultadoReversionHistorico;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    procedure IniciarOperacion(
      const ATipoOperacion, ATipoObjeto, ACodigoOrigen,
      ACodigoDestino, AUsuario: string);
    procedure CapturarAntes(
      const ATabla, ACondicion: string;
      const ANombres, AValores: array of string);
    procedure CompletarOperacion(
      ACantidadUnidades: Integer;
      const ADetalle: string);
    function Revertir(
      const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
    function RevertirEnTransaccion(
      const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
    property IdOperacion: string read FIdOperacion;
  end;

{ EHistoricoCambioArticuloColor }

constructor EHistoricoCambioArticuloColor.Create(
  ACausa: TCausaReversionHistorico;
  const AMensaje: string);
begin
  inherited Create(AMensaje);
  FCausa := ACausa;
end;

{ TColumnaHistorico }

function TColumnaHistorico.EsGenerada: Boolean;
begin
  Result := (ExpresionGenerada <> '') or
    (Pos('GENERATED', UpperCase(Extra)) > 0);
end;

{ TMetadatosHistorico }

constructor TMetadatosHistorico.Create;
begin
  inherited Create;
  FColumnas := TObjectList<TColumnaHistorico>.Create(True);
end;

destructor TMetadatosHistorico.Destroy;
begin
  FColumnas.Free;
  inherited Destroy;
end;

{ TAmbitoHistorico }

constructor TAmbitoHistorico.Create;
begin
  inherited Create;
  FAntes := TObjectList<TFilaHistorico>.Create(True);
end;

destructor TAmbitoHistorico.Destroy;
begin
  FMetadatos.Free;
  FAntes.Free;
  inherited Destroy;
end;

function ExtraerCondicionAmbitoVerificada(const AClave: string): string;
begin
  if not TCodificadorAmbitoHistorico.IntentarExtraerCondicion(
    AClave,
    Result) then
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorAmbitoHistoricoAlterado);
end;

{ THistoricoCambioArticuloColorImpl }

constructor THistoricoCambioArticuloColorImpl.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FAmbitos := TObjectList<TAmbitoHistorico>.Create(True);
end;

destructor THistoricoCambioArticuloColorImpl.Destroy;
begin
  FAmbitos.Free;
  inherited Destroy;
end;

function THistoricoCambioArticuloColorImpl.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure THistoricoCambioArticuloColorImpl.Ejecutar(
  const ASql: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := ASql;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.ValidarIdentificador(
  const AIdentificador: string);
var
  i: Integer;
  EsValido: Boolean;
begin
  EsValido := AIdentificador <> '';
  i := 1;
  while EsValido and (i <= Length(AIdentificador)) do
  begin
    EsValido := CharInSet(
      AIdentificador[i],
      ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    Inc(i);
  end;
  if not EsValido then
    raise EArgumentException.CreateFmt(
      SErrorIdentificadorSqlHistoricoNoPermitido,
      [AIdentificador]);
end;

procedure THistoricoCambioArticuloColorImpl.ValidarTipoOperacion(
  const ATipoOperacion: string);
var
  EsValido: Boolean;
begin
  EsValido := SameText(ATipoOperacion, TIPO_CAMBIO_ARTICULO) or
    SameText(ATipoOperacion, TIPO_FUSION_ARTICULO) or
    SameText(ATipoOperacion, TIPO_CAMBIO_COLOR) or
    SameText(ATipoOperacion, TIPO_FUSION_COLOR);
  if not EsValido then
    raise EArgumentException.CreateFmt(
      SErrorTipoOperacionHistoricoNoPermitido,
      [ATipoOperacion]);
end;

procedure THistoricoCambioArticuloColorImpl.ValidarTipoObjeto(
  const ATipoObjeto: string);
begin
  if not SameText(ATipoObjeto, OBJETO_ARTICULO) and
     not SameText(ATipoObjeto, OBJETO_COLOR) then
    raise EArgumentException.CreateFmt(
      SErrorTipoObjetoHistoricoNoPermitido,
      [ATipoObjeto]);
end;

function THistoricoCambioArticuloColorImpl.GenerarUuid: string;
var
  oGuid: TGUID;
begin
  if CreateGUID(oGuid) <> 0 then
    raise EHistoricoCambioArticuloColor.Create(
      crhErrorTecnico,
      SErrorIdentificadorHistoricoNoGenerado);
  Result := GUIDToString(oGuid);
  Result := Copy(Result, 2, Length(Result) - 2);
end;

function THistoricoCambioArticuloColorImpl.CalcularHash(
  const ATexto: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashString(ATexto));
end;

function THistoricoCambioArticuloColorImpl.BuscarAmbito(
  const ATabla: string): TAmbitoHistorico;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (not Assigned(Result)) and (i < FAmbitos.Count) do
  begin
    if SameText(FAmbitos[i].Tabla, ATabla) then
      Result := FAmbitos[i];
    Inc(i);
  end;
end;

function THistoricoCambioArticuloColorImpl.CargarMetadatos(
  const ATabla: string): TMetadatosHistorico;
var
  oColumna: TColumnaHistorico;
  oConsulta: TUniQuery;
  sBaseFirma: string;
  stClaves: TStringList;
begin
  ValidarIdentificador(ATabla);
  Result := TMetadatosHistorico.Create;
  stClaves := TStringList.Create;
  oConsulta := NuevaConsulta;
  try
    try
      stClaves.CaseSensitive := False;
      oConsulta.SQL.Text :=
        'SELECT `COLUMN_NAME` FROM `information_schema`.' +
        '`KEY_COLUMN_USAGE` WHERE `TABLE_SCHEMA` = DATABASE() AND ' +
        '`TABLE_NAME` = :TABLA AND `CONSTRAINT_NAME` = ''PRIMARY'' ' +
        'ORDER BY `ORDINAL_POSITION`';
      oConsulta.ParamByName('TABLA').AsString := ATabla;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        stClaves.Add(oConsulta.Fields[0].AsString);
        oConsulta.Next;
      end;
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT `COLUMN_NAME`, `COLUMN_TYPE`, `DATA_TYPE`, ' +
        '`IS_NULLABLE`, `COLUMN_DEFAULT`, `CHARACTER_SET_NAME`, ' +
        '`COLLATION_NAME`, `EXTRA`, `GENERATION_EXPRESSION` FROM ' +
        '`information_schema`.`COLUMNS` WHERE ' +
        '`TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = :TABLA ' +
        'ORDER BY `ORDINAL_POSITION`';
      oConsulta.ParamByName('TABLA').AsString := ATabla;
      oConsulta.Open;
      sBaseFirma := '';
      while not oConsulta.Eof do
      begin
        oColumna := TColumnaHistorico.Create;
        try
          oColumna.Nombre := oConsulta.FieldByName(
            'COLUMN_NAME').AsString;
          oColumna.Tipo := oConsulta.FieldByName('COLUMN_TYPE').AsString;
          oColumna.TipoDatos := oConsulta.FieldByName(
            'DATA_TYPE').AsString;
          oColumna.EsNulable := oConsulta.FieldByName(
            'IS_NULLABLE').AsString;
          if oConsulta.FieldByName('COLUMN_DEFAULT').IsNull then
            oColumna.ValorDefecto := '<NULL>'
          else
            oColumna.ValorDefecto := oConsulta.FieldByName(
              'COLUMN_DEFAULT').AsString;
          oColumna.JuegoCaracteres := oConsulta.FieldByName(
            'CHARACTER_SET_NAME').AsString;
          oColumna.Intercalacion := oConsulta.FieldByName(
            'COLLATION_NAME').AsString;
          oColumna.Extra := oConsulta.FieldByName('EXTRA').AsString;
          oColumna.ExpresionGenerada := oConsulta.FieldByName(
            'GENERATION_EXPRESSION').AsString;
          oColumna.EsClave := stClaves.IndexOf(oColumna.Nombre) >= 0;
          Result.Columnas.Add(oColumna);
        except
          oColumna.Free;
          raise;
        end;
        sBaseFirma := sBaseFirma + IntToStr(Result.Columnas.Count) +
          '|' + oColumna.Nombre + '|' + oColumna.Tipo + '|' +
          oColumna.TipoDatos + '|' + oColumna.EsNulable + '|' +
          oColumna.ValorDefecto + '|' +
          oColumna.JuegoCaracteres + '|' + oColumna.Intercalacion +
          '|' + oColumna.Extra + '|' + oColumna.ExpresionGenerada +
          '|' + BoolToStr(oColumna.EsClave, True) + ';';
        oConsulta.Next;
      end;
      if Result.Columnas.Count = 0 then
        raise EArgumentException.CreateFmt(
          SErrorTablaHistoricoNoExiste,
          [ATabla]);
      if stClaves.Count = 0 then
        raise EArgumentException.CreateFmt(
          SErrorTablaHistoricoSinClavePrimaria,
          [ATabla]);
      Result.Firma := CalcularHash(sBaseFirma);
    except
      Result.Free;
      raise;
    end;
  finally
    oConsulta.Free;
    stClaves.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.ExpresionHex(
  AColumna: TColumnaHistorico): string;
var
  sTipo: string;
  EsDatoCrudo: Boolean;
begin
  sTipo := LowerCase(AColumna.TipoDatos);
  EsDatoCrudo := (sTipo = 'char') or
    (sTipo = 'varchar') or
    (sTipo = 'tinytext') or
    (sTipo = 'text') or
    (sTipo = 'mediumtext') or
    (sTipo = 'longtext') or
    (sTipo = 'enum') or
    (sTipo = 'set') or
    (sTipo = 'json') or
    (sTipo = 'binary') or
    (sTipo = 'varbinary') or
    (sTipo = 'tinyblob') or
    (sTipo = 'blob') or
    (sTipo = 'mediumblob') or
    (sTipo = 'longblob') or
    (sTipo = 'bit') or
    (sTipo = 'geometry') or
    (sTipo = 'point') or
    (sTipo = 'linestring') or
    (sTipo = 'polygon') or
    (sTipo = 'multipoint') or
    (sTipo = 'multilinestring') or
    (sTipo = 'multipolygon') or
    (sTipo = 'geometrycollection');
  if EsDatoCrudo then
    Result := 'HEX(`' + AColumna.Nombre + '`)'
  else
    Result := 'HEX(CAST(`' + AColumna.Nombre +
      '` AS CHAR CHARACTER SET utf8mb4))';
end;

function THistoricoCambioArticuloColorImpl.ConstruirSeleccion(
  const ATabla, ACondicion: string;
  AMetadatos: TMetadatosHistorico;
  ABloquear: Boolean): string;
var
  i: Integer;
  oColumna: TColumnaHistorico;
  sOrden: string;
  sSeleccion: string;
begin
  sSeleccion := '';
  sOrden := '';
  for i := 0 to AMetadatos.Columnas.Count - 1 do
  begin
    oColumna := AMetadatos.Columnas[i];
    if sSeleccion <> '' then
      sSeleccion := sSeleccion + ', ';
    sSeleccion := sSeleccion + 'CASE WHEN `' + oColumna.Nombre +
      '` IS NULL THEN NULL ELSE ' + ExpresionHex(oColumna) +
      ' END AS `' + oColumna.Nombre + '`';
    if oColumna.EsClave then
    begin
      if sOrden <> '' then
        sOrden := sOrden + ', ';
      sOrden := sOrden + '`' + oColumna.Nombre + '`';
    end;
  end;
  Result := 'SELECT ' + sSeleccion + ' FROM `' + ATabla + '` WHERE ';
  if Trim(ACondicion) = '' then
    Result := Result + '1 = 1'
  else
    Result := Result + '(' + ACondicion + ')';
  Result := Result + ' ORDER BY ' + sOrden;
  if ABloquear then
    Result := Result + ' FOR UPDATE';
end;

function THistoricoCambioArticuloColorImpl.CrearJsonFila(
  AConsulta: TUniQuery;
  AMetadatos: TMetadatosHistorico;
  ASoloClave: Boolean): string;
var
  i: Integer;
  oColumna: TColumnaHistorico;
  oJson: TJSONObject;
  oValor: TField;
begin
  oJson := TJSONObject.Create;
  try
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if (not ASoloClave) or oColumna.EsClave then
      begin
        oValor := AConsulta.FieldByName(oColumna.Nombre);
        if oValor.IsNull then
          oJson.AddPair(
            oColumna.Nombre,
            TJSONNull.Create)
        else
          oJson.AddPair(
            oColumna.Nombre,
            TJSONString.Create(oValor.AsString));
      end;
    end;
    Result := oJson.ToJSON;
  finally
    oJson.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.CapturarFilas(
  const ATabla, ACondicion: string;
  AMetadatos: TMetadatosHistorico;
  ADestino: TObjectList<TFilaHistorico>;
  ABloquear: Boolean);
var
  oConsulta: TUniQuery;
  oFila: TFilaHistorico;
begin
  ADestino.Clear;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := ConstruirSeleccion(
      ATabla,
      ACondicion,
      AMetadatos,
      ABloquear);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oFila := TFilaHistorico.Create;
      try
        oFila.Clave := CrearJsonFila(
          oConsulta,
          AMetadatos,
          True);
        oFila.HashClave := CalcularHash(oFila.Clave);
        oFila.Datos := CrearJsonFila(
          oConsulta,
          AMetadatos,
          False);
        oFila.HashDatos := CalcularHash(oFila.Datos);
        ADestino.Add(oFila);
      except
        oFila.Free;
        raise;
      end;
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.InsertarCabecera(
  const AId, ATipoOperacion, AIdOrigen, ATipoObjeto,
  ACodigoOrigen, ACodigoDestino, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO `' + TABLA_HISTORICO + '` (' +
      '`ID_OPERACION_ACH`, `ORDEN_ACH`, `TIPO_REGISTRO_ACH`, ' +
      '`TIPO_OPERACION_ACH`, `ID_OPERACION_ORIGEN_ACH`, ' +
      '`ESTADO_ACH`, `TIPO_OBJETO_ACH`, `CODIGO_ORIGEN_ACH`, ' +
      '`CODIGO_DESTINO_ACH`, `VERSION_FORMATO_ACH`, ' +
      '`INSTANTE_ALTA`, `USUARIO_ALTA`) VALUES (' +
      ':ID, 0, ''' + REGISTRO_OPERACION + ''', :TIPO_OPERACION, ' +
      ':ID_ORIGEN, ''' + ESTADO_PREPARADA + ''', :TIPO_OBJETO, ' +
      ':CODIGO_ORIGEN, :CODIGO_DESTINO, ' +
      IntToStr(VERSION_FORMATO) + ', CURRENT_TIMESTAMP, :USUARIO)';
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.ParamByName('TIPO_OPERACION').AsString := ATipoOperacion;
    if AIdOrigen = '' then
      oConsulta.ParamByName('ID_ORIGEN').Clear
    else
      oConsulta.ParamByName('ID_ORIGEN').AsString := AIdOrigen;
    oConsulta.ParamByName('TIPO_OBJETO').AsString := ATipoObjeto;
    oConsulta.ParamByName('CODIGO_ORIGEN').AsString := ACodigoOrigen;
    oConsulta.ParamByName('CODIGO_DESTINO').AsString := ACodigoDestino;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.MarcarCabeceraAplicada(
  const AId, AUsuario, ADetalle: string;
  ACantidadFilas, ACantidadUnidades: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE `' + TABLA_HISTORICO + '` SET ' +
      '`ESTADO_ACH` = ''' + ESTADO_APLICADA + ''', ' +
      '`CANTIDAD_FILAS_ACH` = :FILAS, ' +
      '`CANTIDAD_UNIDADES_ACH` = :UNIDADES, ' +
      '`DETALLE_ACH` = :DETALLE, ' +
      '`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
      '`USUARIO_MODIF` = :USUARIO WHERE ' +
      '`ID_OPERACION_ACH` = :ID AND `ORDEN_ACH` = 0 AND ' +
      '`ESTADO_ACH` = ''' + ESTADO_PREPARADA + '''';
    oConsulta.ParamByName('FILAS').AsInteger := ACantidadFilas;
    oConsulta.ParamByName('UNIDADES').AsInteger := ACantidadUnidades;
    oConsulta.ParamByName('DETALLE').AsString := Copy(ADetalle, 1, 500);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EHistoricoCambioArticuloColor.Create(
        crhErrorTecnico,
        SErrorCabeceraHistoricoNoAplicada);
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.InsertarDetalle(
  const AIdOperacion, ATipoOperacion, ATipoObjeto,
  AUsuario: string;
  ADetalle: TDetalleHistorico);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO `' + TABLA_HISTORICO + '` (' +
      '`ID_OPERACION_ACH`, `ORDEN_ACH`, `TIPO_REGISTRO_ACH`, ' +
      '`TIPO_OPERACION_ACH`, `ESTADO_ACH`, `TIPO_OBJETO_ACH`, ' +
      '`TABLA_ACH`, `ACCION_ACH`, `CLAVE_ANTES_ACH`, ' +
      '`CLAVE_DESPUES_ACH`, `HASH_CLAVE_ANTES_ACH`, ' +
      '`HASH_CLAVE_DESPUES_ACH`, `DATOS_ANTES_ACH`, ' +
      '`DATOS_DESPUES_ACH`, `HASH_ANTES_ACH`, `HASH_DESPUES_ACH`, ' +
      '`FIRMA_ESQUEMA_ACH`, `VERSION_FORMATO_ACH`, ' +
      '`INSTANTE_ALTA`, `USUARIO_ALTA`) VALUES (' +
      ':ID, :ORDEN, :TIPO_REGISTRO, :TIPO_OPERACION, ''' +
      ESTADO_APLICADA + ''', :TIPO_OBJETO, :TABLA, :ACCION, ' +
      ':CLAVE_ANTES, :CLAVE_DESPUES, :HASH_CLAVE_ANTES, ' +
      ':HASH_CLAVE_DESPUES, :DATOS_ANTES, :DATOS_DESPUES, ' +
      ':HASH_ANTES, :HASH_DESPUES, :FIRMA_ESQUEMA, ' +
      IntToStr(VERSION_FORMATO) + ', CURRENT_TIMESTAMP, :USUARIO)';
    oConsulta.ParamByName('ID').AsString := AIdOperacion;
    oConsulta.ParamByName('ORDEN').AsInteger := ADetalle.Orden;
    oConsulta.ParamByName('TIPO_REGISTRO').AsString :=
      ADetalle.TipoRegistro;
    oConsulta.ParamByName('TIPO_OPERACION').AsString := ATipoOperacion;
    oConsulta.ParamByName('TIPO_OBJETO').AsString := ATipoObjeto;
    oConsulta.ParamByName('TABLA').AsString := ADetalle.Tabla;
    oConsulta.ParamByName('ACCION').AsString := ADetalle.Accion;
    oConsulta.ParamByName('CLAVE_ANTES').DataType := ftWideMemo;
    oConsulta.ParamByName('CLAVE_DESPUES').DataType := ftWideMemo;
    oConsulta.ParamByName('DATOS_ANTES').DataType := ftWideMemo;
    oConsulta.ParamByName('DATOS_DESPUES').DataType := ftWideMemo;
    if ADetalle.TieneClaveAntes then
      oConsulta.ParamByName('CLAVE_ANTES').AsWideString :=
        ADetalle.ClaveAntes
    else
      oConsulta.ParamByName('CLAVE_ANTES').Clear;
    if ADetalle.TieneClaveDespues then
      oConsulta.ParamByName('CLAVE_DESPUES').AsWideString :=
        ADetalle.ClaveDespues
    else
      oConsulta.ParamByName('CLAVE_DESPUES').Clear;
    if ADetalle.TieneClaveAntes then
      oConsulta.ParamByName('HASH_CLAVE_ANTES').AsString :=
        ADetalle.HashClaveAntes
    else
      oConsulta.ParamByName('HASH_CLAVE_ANTES').Clear;
    if ADetalle.TieneClaveDespues then
      oConsulta.ParamByName('HASH_CLAVE_DESPUES').AsString :=
        ADetalle.HashClaveDespues
    else
      oConsulta.ParamByName('HASH_CLAVE_DESPUES').Clear;
    if ADetalle.TieneDatosAntes then
      oConsulta.ParamByName('DATOS_ANTES').AsWideString :=
        ADetalle.DatosAntes
    else
      oConsulta.ParamByName('DATOS_ANTES').Clear;
    if ADetalle.TieneDatosDespues then
      oConsulta.ParamByName('DATOS_DESPUES').AsWideString :=
        ADetalle.DatosDespues
    else
      oConsulta.ParamByName('DATOS_DESPUES').Clear;
    if ADetalle.TieneDatosAntes then
      oConsulta.ParamByName('HASH_ANTES').AsString :=
        ADetalle.HashAntes
    else
      oConsulta.ParamByName('HASH_ANTES').Clear;
    if ADetalle.TieneDatosDespues then
      oConsulta.ParamByName('HASH_DESPUES').AsString :=
        ADetalle.HashDespues
    else
      oConsulta.ParamByName('HASH_DESPUES').Clear;
    oConsulta.ParamByName('FIRMA_ESQUEMA').AsString :=
      ADetalle.FirmaEsquema;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.CrearDetalle(
  const ATipoRegistro, AAccion: string;
  AAntes, ADespues: TFilaHistorico;
  const AFirma: string): TDetalleHistorico;
begin
  Result := TDetalleHistorico.Create;
  Result.TipoRegistro := ATipoRegistro;
  Result.TipoOperacion := FTipoOperacion;
  Result.TipoObjeto := FTipoObjeto;
  Result.Accion := AAccion;
  Result.FirmaEsquema := AFirma;
  Result.TieneClaveAntes := Assigned(AAntes);
  Result.TieneDatosAntes := Assigned(AAntes);
  Result.TieneClaveDespues := Assigned(ADespues);
  Result.TieneDatosDespues := Assigned(ADespues);
  if Assigned(AAntes) then
  begin
    Result.ClaveAntes := AAntes.Clave;
    Result.HashClaveAntes := AAntes.HashClave;
    Result.DatosAntes := AAntes.Datos;
    Result.HashAntes := AAntes.HashDatos;
  end;
  if Assigned(ADespues) then
  begin
    Result.ClaveDespues := ADespues.Clave;
    Result.HashClaveDespues := ADespues.HashClave;
    Result.DatosDespues := ADespues.Datos;
    Result.HashDespues := ADespues.HashDatos;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.RegistrarDiferencias(
  AAmbito: TAmbitoHistorico;
  ADespues: TObjectList<TFilaHistorico>;
  var ACantidadFilas: Integer);
var
  i: Integer;
  oAntes: TFilaHistorico;
  oDespues: TFilaHistorico;
  oDetalle: TDetalleHistorico;
  sAccion: string;
  sClave: string;
  stDespues: TDictionary<string, TFilaHistorico>;
begin
  stDespues := TDictionary<string, TFilaHistorico>.Create;
  try
    for oDespues in ADespues do
    begin
      sClave := oDespues.HashClave + #0 + oDespues.Clave;
      stDespues.Add(sClave, oDespues);
    end;
    for oAntes in AAmbito.Antes do
    begin
      sClave := oAntes.HashClave + #0 + oAntes.Clave;
      if stDespues.TryGetValue(sClave, oDespues) then
      begin
        if (oAntes.HashDatos = oDespues.HashDatos) and
           (oAntes.Datos = oDespues.Datos) then
          sAccion := ACCION_COMPROBAR
        else
          sAccion := ACCION_ACTUALIZAR;
        if sAccion = ACCION_COMPROBAR then
          oDetalle := CrearDetalle(
            REGISTRO_GUARDA,
            sAccion,
            oAntes,
            oDespues,
            AAmbito.Metadatos.Firma)
        else
          oDetalle := CrearDetalle(
            REGISTRO_FILA,
            sAccion,
            oAntes,
            oDespues,
            AAmbito.Metadatos.Firma);
        stDespues.Remove(sClave);
      end
      else
        oDetalle := CrearDetalle(
          REGISTRO_FILA,
          ACCION_ELIMINAR,
          oAntes,
          nil,
          AAmbito.Metadatos.Firma);
      try
        Inc(FOrden);
        oDetalle.Orden := FOrden;
        oDetalle.Tabla := AAmbito.Tabla;
        InsertarDetalle(
          FIdOperacion,
          FTipoOperacion,
          FTipoObjeto,
          FUsuario,
          oDetalle);
        if oDetalle.TipoRegistro = REGISTRO_FILA then
          Inc(ACantidadFilas);
      finally
        oDetalle.Free;
      end;
    end;
    for i := 0 to ADespues.Count - 1 do
    begin
      oDespues := ADespues[i];
      sClave := oDespues.HashClave + #0 + oDespues.Clave;
      if stDespues.ContainsKey(sClave) then
      begin
        oDetalle := CrearDetalle(
          REGISTRO_FILA,
          ACCION_INSERTAR,
          nil,
          oDespues,
          AAmbito.Metadatos.Firma);
        try
          Inc(FOrden);
          oDetalle.Orden := FOrden;
          oDetalle.Tabla := AAmbito.Tabla;
          InsertarDetalle(
            FIdOperacion,
            FTipoOperacion,
            FTipoObjeto,
            FUsuario,
            oDetalle);
          Inc(ACantidadFilas);
        finally
          oDetalle.Free;
        end;
      end;
    end;
  finally
    stDespues.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.RegistrarAmbito(
  AAmbito: TAmbitoHistorico;
  ADespues: TObjectList<TFilaHistorico>);
var
  oAntes: TFilaHistorico;
  oDespues: TFilaHistorico;
  oDetalle: TDetalleHistorico;
begin
  oAntes := TCodificadorAmbitoHistorico.CrearEstado(
    AAmbito.Condicion,
    AAmbito.Antes);
  try
    oDespues := TCodificadorAmbitoHistorico.CrearEstado(
      AAmbito.Condicion,
      ADespues);
    try
      oDetalle := CrearDetalle(
        REGISTRO_AMBITO,
        ACCION_COMPROBAR,
        oAntes,
        oDespues,
        AAmbito.Metadatos.Firma);
      try
        Inc(FOrden);
        oDetalle.Orden := FOrden;
        oDetalle.Tabla := AAmbito.Tabla;
        InsertarDetalle(
          FIdOperacion,
          FTipoOperacion,
          FTipoObjeto,
          FUsuario,
          oDetalle);
      finally
        oDetalle.Free;
      end;
    finally
      oDespues.Free;
    end;
  finally
    oAntes.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.IniciarOperacion(
  const ATipoOperacion, ATipoObjeto, ACodigoOrigen,
  ACodigoDestino, AUsuario: string);
begin
  if not FConexion.InTransaction then
    raise EHistoricoCambioArticuloColor.Create(
      crhErrorTecnico,
      SErrorHistoricoFueraTransaccion);
  if FIniciada and not FCompletada then
    raise EHistoricoCambioArticuloColor.Create(
      crhErrorTecnico,
      SErrorOperacionHistoricoEnCurso);
  ValidarTipoOperacion(ATipoOperacion);
  ValidarTipoObjeto(ATipoObjeto);
  if Trim(AUsuario) = '' then
    raise EArgumentException.Create(SErrorUsuarioHistoricoObligatorio);
  FAmbitos.Clear;
  FIdOperacion := GenerarUuid;
  FTipoOperacion := UpperCase(ATipoOperacion);
  FTipoObjeto := UpperCase(ATipoObjeto);
  FCodigoOrigen := ACodigoOrigen;
  FCodigoDestino := ACodigoDestino;
  FUsuario := Copy(AUsuario, 1, 50);
  FOrden := 0;
  FIniciada := True;
  FCompletada := False;
  InsertarCabecera(
    FIdOperacion,
    FTipoOperacion,
    '',
    FTipoObjeto,
    FCodigoOrigen,
    FCodigoDestino,
    FUsuario);
end;

procedure THistoricoCambioArticuloColorImpl.CapturarAntes(
  const ATabla, ACondicion: string;
  const ANombres, AValores: array of string);
var
  oAmbito: TAmbitoHistorico;
begin
  if not FIniciada or FCompletada then
    raise EHistoricoCambioArticuloColor.Create(
      crhErrorTecnico,
      SErrorOperacionHistoricoNoPreparadaCaptura);
  ValidarIdentificador(ATabla);
  if SameText(ATabla, TABLA_FACTURAS) then
    raise EArgumentException.Create(SErrorLineasFacturaProtegidasHistorico);
  if SameText(ATabla, TABLA_HISTORICO) then
    raise EArgumentException.Create(SErrorTablaHistoricoAutocontenida);
  if Assigned(BuscarAmbito(ATabla)) then
    raise EArgumentException.CreateFmt(
      SErrorTablaAmbitoHistoricoDuplicada,
      [ATabla]);
  if Length(ANombres) <> Length(AValores) then
    raise EArgumentException.Create(SErrorParametrosAmbitoHistoricoNoCoinciden);
  if (Length(ANombres) <> 0) or (Length(AValores) <> 0) then
    raise EArgumentException.Create(SErrorAmbitoHistoricoConParametros);
  if not TCodificadorAmbitoHistorico.CondicionEsPersistible(
    ACondicion) then
    raise EArgumentException.Create(SErrorAmbitoHistoricoNoPersistible);
  oAmbito := TAmbitoHistorico.Create;
  try
    oAmbito.Tabla := ATabla;
    oAmbito.Condicion := Trim(ACondicion);
    oAmbito.Metadatos := CargarMetadatos(ATabla);
    CapturarFilas(
      oAmbito.Tabla,
      oAmbito.Condicion,
      oAmbito.Metadatos,
      oAmbito.Antes,
      True);
    FAmbitos.Add(oAmbito);
  except
    oAmbito.Free;
    raise;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.CompletarOperacion(
  ACantidadUnidades: Integer;
  const ADetalle: string);
var
  iCantidadFilas: Integer;
  oAmbito: TAmbitoHistorico;
  oDespues: TObjectList<TFilaHistorico>;
  oMetadatos: TMetadatosHistorico;
begin
  if not FIniciada or FCompletada then
    raise EHistoricoCambioArticuloColor.Create(
      crhErrorTecnico,
      SErrorOperacionHistoricoNoPreparadaCompletar);
  iCantidadFilas := 0;
  oDespues := TObjectList<TFilaHistorico>.Create(True);
  try
    for oAmbito in FAmbitos do
    begin
      oMetadatos := CargarMetadatos(oAmbito.Tabla);
      try
        if oMetadatos.Firma <> oAmbito.Metadatos.Firma then
          raise EHistoricoCambioArticuloColor.Create(
            crhEsquemaModificado,
            Format(SErrorEsquemaCambioDuranteOperacion, [oAmbito.Tabla]));
      finally
        oMetadatos.Free;
      end;
      CapturarFilas(
        oAmbito.Tabla,
        oAmbito.Condicion,
        oAmbito.Metadatos,
        oDespues,
        False);
      RegistrarDiferencias(
        oAmbito,
        oDespues,
        iCantidadFilas);
      RegistrarAmbito(
        oAmbito,
        oDespues);
    end;
    MarcarCabeceraAplicada(
      FIdOperacion,
      FUsuario,
      ADetalle,
      iCantidadFilas,
      ACantidadUnidades);
    FCompletada := True;
  finally
    oDespues.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.CargarOperacion(
  const AIdOperacion: string): TOperacionHistorico;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT `ID_ACH`, `ID_OPERACION_ACH`, `TIPO_OPERACION_ACH`, ' +
      '`TIPO_OBJETO_ACH`, `CODIGO_ORIGEN_ACH`, ' +
      '`CODIGO_DESTINO_ACH`, `CANTIDAD_FILAS_ACH`, ' +
      '`CANTIDAD_UNIDADES_ACH`, `VERSION_FORMATO_ACH` FROM `' +
      TABLA_HISTORICO + '` WHERE `ID_OPERACION_ACH` = :ID AND ' +
      '`ORDEN_ACH` = 0 AND `TIPO_REGISTRO_ACH` = ''' +
      REGISTRO_OPERACION + ''' AND `ESTADO_ACH` = ''' +
      ESTADO_APLICADA + ''' FOR UPDATE';
    oConsulta.ParamByName('ID').AsString := AIdOperacion;
    oConsulta.Open;
    if oConsulta.Eof then
      raise EHistoricoCambioArticuloColor.Create(
        crhNoEncontrada,
        SErrorOperacionHistoricaNoExisteAplicada);
    if oConsulta.FieldByName('VERSION_FORMATO_ACH').AsInteger <>
       VERSION_FORMATO then
      raise EHistoricoCambioArticuloColor.Create(
        crhNoReversible,
        SErrorVersionHistoricoNoCompatible);
    Result := TOperacionHistorico.Create;
    try
      Result.IdFila := oConsulta.FieldByName('ID_ACH').AsLargeInt;
      Result.Id := oConsulta.FieldByName('ID_OPERACION_ACH').AsString;
      Result.TipoOperacion := oConsulta.FieldByName(
        'TIPO_OPERACION_ACH').AsString;
      Result.TipoObjeto := oConsulta.FieldByName(
        'TIPO_OBJETO_ACH').AsString;
      Result.CodigoOrigen := oConsulta.FieldByName(
        'CODIGO_ORIGEN_ACH').AsString;
      Result.CodigoDestino := oConsulta.FieldByName(
        'CODIGO_DESTINO_ACH').AsString;
      Result.CantidadFilas := oConsulta.FieldByName(
        'CANTIDAD_FILAS_ACH').AsInteger;
      Result.CantidadUnidades := oConsulta.FieldByName(
        'CANTIDAD_UNIDADES_ACH').AsInteger;
    except
      Result.Free;
      raise;
    end;
  finally
    oConsulta.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.CargarDetalles(
  const AIdOperacion: string): TObjectList<TDetalleHistorico>;
var
  oConsulta: TUniQuery;
  oDetalle: TDetalleHistorico;
begin
  Result := TObjectList<TDetalleHistorico>.Create(True);
  oConsulta := NuevaConsulta;
  try
    try
      oConsulta.SQL.Text :=
        'SELECT `ORDEN_ACH`, `TIPO_REGISTRO_ACH`, ' +
        '`TIPO_OPERACION_ACH`, `TIPO_OBJETO_ACH`, `TABLA_ACH`, ' +
        '`ACCION_ACH`, `CLAVE_ANTES_ACH`, `CLAVE_DESPUES_ACH`, ' +
        '`HASH_CLAVE_ANTES_ACH`, `HASH_CLAVE_DESPUES_ACH`, ' +
        '`DATOS_ANTES_ACH`, `DATOS_DESPUES_ACH`, ' +
        '`HASH_ANTES_ACH`, `HASH_DESPUES_ACH`, ' +
        '`FIRMA_ESQUEMA_ACH` FROM `' + TABLA_HISTORICO + '` ' +
        'WHERE `ID_OPERACION_ACH` = :ID AND `ORDEN_ACH` > 0 ' +
        'AND `ESTADO_ACH` = ''' + ESTADO_APLICADA + ''' ' +
        'ORDER BY `ORDEN_ACH` FOR UPDATE';
      oConsulta.ParamByName('ID').AsString := AIdOperacion;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oDetalle := TDetalleHistorico.Create;
        try
          oDetalle.Orden := oConsulta.FieldByName('ORDEN_ACH').AsInteger;
          oDetalle.TipoRegistro := oConsulta.FieldByName(
            'TIPO_REGISTRO_ACH').AsString;
          oDetalle.TipoOperacion := oConsulta.FieldByName(
            'TIPO_OPERACION_ACH').AsString;
          oDetalle.TipoObjeto := oConsulta.FieldByName(
            'TIPO_OBJETO_ACH').AsString;
          oDetalle.Tabla := oConsulta.FieldByName('TABLA_ACH').AsString;
          oDetalle.Accion := oConsulta.FieldByName('ACCION_ACH').AsString;
          oDetalle.TieneClaveAntes := not oConsulta.FieldByName(
            'CLAVE_ANTES_ACH').IsNull;
          oDetalle.TieneClaveDespues := not oConsulta.FieldByName(
            'CLAVE_DESPUES_ACH').IsNull;
          oDetalle.TieneDatosAntes := not oConsulta.FieldByName(
            'DATOS_ANTES_ACH').IsNull;
          oDetalle.TieneDatosDespues := not oConsulta.FieldByName(
            'DATOS_DESPUES_ACH').IsNull;
          oDetalle.ClaveAntes := oConsulta.FieldByName(
            'CLAVE_ANTES_ACH').AsString;
          oDetalle.ClaveDespues := oConsulta.FieldByName(
            'CLAVE_DESPUES_ACH').AsString;
          oDetalle.HashClaveAntes := oConsulta.FieldByName(
            'HASH_CLAVE_ANTES_ACH').AsString;
          oDetalle.HashClaveDespues := oConsulta.FieldByName(
            'HASH_CLAVE_DESPUES_ACH').AsString;
          oDetalle.DatosAntes := oConsulta.FieldByName(
            'DATOS_ANTES_ACH').AsString;
          oDetalle.DatosDespues := oConsulta.FieldByName(
            'DATOS_DESPUES_ACH').AsString;
          oDetalle.HashAntes := oConsulta.FieldByName(
            'HASH_ANTES_ACH').AsString;
          oDetalle.HashDespues := oConsulta.FieldByName(
            'HASH_DESPUES_ACH').AsString;
          oDetalle.FirmaEsquema := oConsulta.FieldByName(
            'FIRMA_ESQUEMA_ACH').AsString;
          Result.Add(oDetalle);
        except
          oDetalle.Free;
          raise;
        end;
        oConsulta.Next;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.ValidarDetalles(
  AOperacion: TOperacionHistorico;
  ADetalles: TObjectList<TDetalleHistorico>);
var
  EsFormaValida: Boolean;
  iCantidadFilas: Integer;
  iOrdenEsperado: Integer;
  oDetalle: TDetalleHistorico;
  sCondicionAntes: string;
  sCondicionDespues: string;
  stAmbitos: TStringList;
  stTablas: TStringList;
begin
  iCantidadFilas := 0;
  iOrdenEsperado := 1;
  stAmbitos := TStringList.Create;
  stTablas := TStringList.Create;
  try
    stAmbitos.CaseSensitive := False;
    stAmbitos.Duplicates := dupIgnore;
    stAmbitos.Sorted := True;
    stTablas.CaseSensitive := False;
    stTablas.Duplicates := dupIgnore;
    stTablas.Sorted := True;
    for oDetalle in ADetalles do
    begin
      stTablas.Add(oDetalle.Tabla);
      EsFormaValida := oDetalle.Orden = iOrdenEsperado;
      EsFormaValida := EsFormaValida and
        SameText(oDetalle.TipoOperacion, AOperacion.TipoOperacion);
      EsFormaValida := EsFormaValida and
        SameText(oDetalle.TipoObjeto, AOperacion.TipoObjeto);
      EsFormaValida := EsFormaValida and
        (oDetalle.FirmaEsquema <> '');
      if oDetalle.TipoRegistro = REGISTRO_FILA then
      begin
        Inc(iCantidadFilas);
        if oDetalle.Accion = ACCION_INSERTAR then
          EsFormaValida := EsFormaValida and
            not oDetalle.TieneDatosAntes and
            oDetalle.TieneDatosDespues
        else if oDetalle.Accion = ACCION_ACTUALIZAR then
          EsFormaValida := EsFormaValida and
            oDetalle.TieneDatosAntes and
            oDetalle.TieneDatosDespues
        else if oDetalle.Accion = ACCION_ELIMINAR then
          EsFormaValida := EsFormaValida and
            oDetalle.TieneDatosAntes and
            not oDetalle.TieneDatosDespues
        else
          EsFormaValida := False;
      end
      else if oDetalle.TipoRegistro = REGISTRO_GUARDA then
        EsFormaValida := EsFormaValida and
          (oDetalle.Accion = ACCION_COMPROBAR) and
          oDetalle.TieneDatosAntes and
          oDetalle.TieneDatosDespues
      else if oDetalle.TipoRegistro = REGISTRO_AMBITO then
      begin
        EsFormaValida := EsFormaValida and
          (oDetalle.Accion = ACCION_COMPROBAR) and
          oDetalle.TieneClaveAntes and
          oDetalle.TieneClaveDespues and
          oDetalle.TieneDatosAntes and
          oDetalle.TieneDatosDespues;
        if EsFormaValida then
        begin
          sCondicionAntes := ExtraerCondicionAmbitoVerificada(
            oDetalle.ClaveAntes);
          sCondicionDespues := ExtraerCondicionAmbitoVerificada(
            oDetalle.ClaveDespues);
          EsFormaValida := sCondicionAntes = sCondicionDespues;
          EsFormaValida := EsFormaValida and
            TCodificadorAmbitoHistorico.ResumenEsValido(
              oDetalle.DatosAntes) and
            TCodificadorAmbitoHistorico.ResumenEsValido(
              oDetalle.DatosDespues) and
            (stAmbitos.IndexOf(oDetalle.Tabla) < 0);
          if EsFormaValida then
            stAmbitos.Add(oDetalle.Tabla);
        end;
      end
      else
        EsFormaValida := False;
      EsFormaValida := EsFormaValida and
        (oDetalle.TieneClaveAntes = oDetalle.TieneDatosAntes) and
        (oDetalle.TieneClaveDespues = oDetalle.TieneDatosDespues);
      if oDetalle.TieneClaveAntes then
        EsFormaValida := EsFormaValida and
          (CalcularHash(oDetalle.ClaveAntes) =
           oDetalle.HashClaveAntes) and
          (CalcularHash(oDetalle.DatosAntes) = oDetalle.HashAntes);
      if oDetalle.TieneClaveDespues then
        EsFormaValida := EsFormaValida and
          (CalcularHash(oDetalle.ClaveDespues) =
           oDetalle.HashClaveDespues) and
          (CalcularHash(oDetalle.DatosDespues) = oDetalle.HashDespues);
      if not EsFormaValida then
        raise EHistoricoCambioArticuloColor.Create(
          crhNoReversible,
          SErrorDetalleHistoricoAlterado);
      Inc(iOrdenEsperado);
    end;
    if stAmbitos.Count <> stTablas.Count then
      raise EHistoricoCambioArticuloColor.Create(
        crhNoReversible,
        SErrorAmbitosFilasHistoricoIncompletos);
  finally
    stTablas.Free;
    stAmbitos.Free;
  end;
  if iCantidadFilas <> AOperacion.CantidadFilas then
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorCantidadFilasHistoricoNoCoincide);
end;

function THistoricoCambioArticuloColorImpl.TieneReversionAplicada(
  const AIdOperacion: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT `ID_ACH` FROM `' + TABLA_HISTORICO + '` WHERE ' +
      '`TIPO_REGISTRO_ACH` = ''' + REGISTRO_OPERACION + ''' AND ' +
      '`TIPO_OPERACION_ACH` = ''' + TIPO_REVERSION + ''' AND ' +
      '`ID_OPERACION_ORIGEN_ACH` = :ID AND `ESTADO_ACH` = ''' +
      ESTADO_APLICADA + ''' LIMIT 1 FOR UPDATE';
    oConsulta.ParamByName('ID').AsString := AIdOperacion;
    oConsulta.Open;
    Result := not oConsulta.Eof;
  finally
    oConsulta.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.TieneDependenciaPosterior(
  AOperacion: TOperacionHistorico): Boolean;
var
  oConsulta: TUniQuery;
  sCoincidencia: string;
begin
  sCoincidencia :=
    '((origen.`HASH_CLAVE_ANTES_ACH` IS NOT NULL AND (' +
    '(origen.`HASH_CLAVE_ANTES_ACH` = ' +
    'posterior.`HASH_CLAVE_ANTES_ACH` AND ' +
    'origen.`CLAVE_ANTES_ACH` = posterior.`CLAVE_ANTES_ACH`) OR ' +
    '(origen.`HASH_CLAVE_ANTES_ACH` = ' +
    'posterior.`HASH_CLAVE_DESPUES_ACH` AND ' +
    'origen.`CLAVE_ANTES_ACH` = posterior.`CLAVE_DESPUES_ACH`))) OR ' +
    '(origen.`HASH_CLAVE_DESPUES_ACH` IS NOT NULL AND (' +
    '(origen.`HASH_CLAVE_DESPUES_ACH` = ' +
    'posterior.`HASH_CLAVE_ANTES_ACH` AND ' +
    'origen.`CLAVE_DESPUES_ACH` = posterior.`CLAVE_ANTES_ACH`) OR ' +
    '(origen.`HASH_CLAVE_DESPUES_ACH` = ' +
    'posterior.`HASH_CLAVE_DESPUES_ACH` AND ' +
    'origen.`CLAVE_DESPUES_ACH` = posterior.`CLAVE_DESPUES_ACH`))))';
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT posterior.`ID_ACH` FROM `' + TABLA_HISTORICO +
      '` origen JOIN `' + TABLA_HISTORICO + '` posterior ON ' +
      'posterior.`TIPO_REGISTRO_ACH` IN (''' + REGISTRO_FILA +
      ''', ''' + REGISTRO_GUARDA + ''', ''' + REGISTRO_AMBITO +
      ''') AND ' +
      'posterior.`TABLA_ACH` = origen.`TABLA_ACH` AND ' +
      sCoincidencia + ' JOIN `' + TABLA_HISTORICO + '` cabecera ON ' +
      'cabecera.`ID_OPERACION_ACH` = ' +
      'posterior.`ID_OPERACION_ACH` AND cabecera.`ORDEN_ACH` = 0 ' +
      'WHERE origen.`ID_OPERACION_ACH` = :ID AND ' +
      'origen.`ORDEN_ACH` > 0 AND cabecera.`ID_ACH` > :ID_FILA ' +
      'AND cabecera.`TIPO_REGISTRO_ACH` = ''' +
      REGISTRO_OPERACION + ''' AND cabecera.`ESTADO_ACH` = ''' +
      ESTADO_APLICADA + ''' AND cabecera.`TIPO_OPERACION_ACH` <> ''' +
      TIPO_REVERSION + ''' AND NOT EXISTS (SELECT 1 FROM `' +
      TABLA_HISTORICO + '` rev WHERE ' +
      'rev.`TIPO_REGISTRO_ACH` = ''' + REGISTRO_OPERACION + ''' AND ' +
      'rev.`TIPO_OPERACION_ACH` = ''' + TIPO_REVERSION + ''' AND ' +
      'rev.`ID_OPERACION_ORIGEN_ACH` = ' +
      'cabecera.`ID_OPERACION_ACH` AND rev.`ESTADO_ACH` = ''' +
      ESTADO_APLICADA + ''') LIMIT 1 FOR UPDATE';
    oConsulta.ParamByName('ID').AsString := AOperacion.Id;
    oConsulta.ParamByName('ID_FILA').AsLargeInt := AOperacion.IdFila;
    oConsulta.Open;
    Result := not oConsulta.Eof;
  finally
    oConsulta.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.HayFacturasRelacionadas(
  AOperacion: TOperacionHistorico): Boolean;
var
  i: Integer;
  oConsulta: TUniQuery;
  sCondicion: string;
  sCampo: string;
begin
  sCondicion :=
    'EXISTS (SELECT 1 FROM `' + TABLA_HISTORICO + '` detalle ' +
    'WHERE detalle.`ID_OPERACION_ACH` = :ID AND ' +
    'detalle.`TABLA_ACH` = ''fza_articulos_skus'' AND (' +
    'fac.`CODIGO_UNIDAD_FACLIN` = CONVERT(UNHEX(JSON_UNQUOTE(' +
    'JSON_EXTRACT(detalle.`DATOS_ANTES_ACH`, ' +
    '''$.CODIGO_UNIDAD_SKU''))) USING utf8mb4) OR ' +
    'fac.`CODIGO_UNIDAD_FACLIN` = CONVERT(UNHEX(JSON_UNQUOTE(' +
    'JSON_EXTRACT(detalle.`DATOS_DESPUES_ACH`, ' +
    '''$.CODIGO_UNIDAD_SKU''))) USING utf8mb4)))';
  if SameText(AOperacion.TipoObjeto, OBJETO_ARTICULO) then
  begin
    sCondicion := sCondicion +
      ' OR fac.`CODIGO_ART_FACLIN` IN (:ORIGEN, :DESTINO) OR ' +
      'fac.`CODIGO_UNIDAD_FACLIN` IN (:ORIGEN, :DESTINO) OR ' +
      'LEFT(fac.`CODIGO_UNIDAD_FACLIN`, ' +
      'CHAR_LENGTH(:ORIGEN) + 1) = CONCAT(:ORIGEN, ''/'') OR ' +
      'LEFT(fac.`CODIGO_UNIDAD_FACLIN`, ' +
      'CHAR_LENGTH(:DESTINO) + 1) = CONCAT(:DESTINO, ''/'')';
  end
  else
  begin
    sCondicion := sCondicion +
      ' OR LOCATE(CONCAT(''/'', TRIM(:ORIGEN), ''/''), ' +
      'CONCAT(''/'', fac.`CODIGO_UNIDAD_FACLIN`, ''/'')) > 0 OR ' +
      'LOCATE(CONCAT(''/'', TRIM(:DESTINO), ''/''), ' +
      'CONCAT(''/'', fac.`CODIGO_UNIDAD_FACLIN`, ''/'')) > 0';
    for i := 1 to 5 do
    begin
      sCampo := 'ATTR' + IntToStr(i) + '_VALOR_FACLIN';
      sCondicion := sCondicion + ' OR TRIM(fac.`' + sCampo +
        '`) IN (TRIM(:ORIGEN), TRIM(:DESTINO))';
    end;
  end;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT fac.`CODIGO_UNIDAD_FACLIN` FROM `' + TABLA_FACTURAS +
      '` fac WHERE ' + sCondicion + ' LIMIT 1 FOR UPDATE';
    oConsulta.ParamByName('ID').AsString := AOperacion.Id;
    oConsulta.ParamByName('ORIGEN').AsString := AOperacion.CodigoOrigen;
    oConsulta.ParamByName('DESTINO').AsString :=
      AOperacion.CodigoDestino;
    oConsulta.Open;
    Result := not oConsulta.Eof;
  finally
    oConsulta.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.ComprobarEsquemas(
  ADetalles: TObjectList<TDetalleHistorico>;
  AMetadatos: TObjectDictionary<string, TMetadatosHistorico>);
var
  oDetalle: TDetalleHistorico;
  oMetadatos: TMetadatosHistorico;
begin
  for oDetalle in ADetalles do
  begin
    ValidarIdentificador(oDetalle.Tabla);
    if SameText(oDetalle.Tabla, TABLA_FACTURAS) or
       SameText(oDetalle.Tabla, TABLA_HISTORICO) then
      raise EHistoricoCambioArticuloColor.Create(
        crhNoReversible,
        SErrorTablaProtegidaHistorico);
    if not AMetadatos.TryGetValue(oDetalle.Tabla, oMetadatos) then
    begin
      oMetadatos := CargarMetadatos(oDetalle.Tabla);
      AMetadatos.Add(oDetalle.Tabla, oMetadatos);
    end;
    if oMetadatos.Firma <> oDetalle.FirmaEsquema then
      raise EHistoricoCambioArticuloColor.Create(
        crhEsquemaModificado,
        Format(SErrorEsquemaTablaHistoricoModificado, [oDetalle.Tabla]));
  end;
end;

function THistoricoCambioArticuloColorImpl.ObtenerDatosActuales(
  const ATabla, AClave: string;
  AMetadatos: TMetadatosHistorico;
  out ADatos, AHash: string): Boolean;
var
  i: Integer;
  iParametro: Integer;
  oColumna: TColumnaHistorico;
  oConsulta: TUniQuery;
  oJson: TJSONObject;
  oRaiz: TJSONValue;
  oValor: TJSONValue;
  sCondicion: string;
  sParametro: string;
begin
  ADatos := '';
  AHash := '';
  oRaiz := TJSONObject.ParseJSONValue(AClave);
  if not (oRaiz is TJSONObject) then
  begin
    oRaiz.Free;
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorClaveJsonHistoricoInvalida);
  end;
  oJson := TJSONObject(oRaiz);
  oConsulta := NuevaConsulta;
  try
    sCondicion := '';
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if oColumna.EsClave then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not Assigned(oValor) then
          raise EHistoricoCambioArticuloColor.Create(
            crhNoReversible,
            SErrorClavePrimariaHistoricoIncompleta);
        if sCondicion <> '' then
          sCondicion := sCondicion + ' AND ';
        if oValor is TJSONNull then
          sCondicion := sCondicion + '`' + oColumna.Nombre + '` IS NULL'
        else
        begin
          sParametro := 'K' + IntToStr(iParametro);
          sCondicion := sCondicion + '`' + oColumna.Nombre +
            '` = UNHEX(:' + sParametro + ')';
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.SQL.Text := ConstruirSeleccion(
      ATabla,
      sCondicion,
      AMetadatos,
      True);
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if oColumna.EsClave then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not (oValor is TJSONNull) then
        begin
          sParametro := 'K' + IntToStr(iParametro);
          oConsulta.ParamByName(sParametro).AsString := oValor.Value;
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
    begin
      ADatos := CrearJsonFila(oConsulta, AMetadatos, False);
      AHash := CalcularHash(ADatos);
    end;
  finally
    oConsulta.Free;
    oJson.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.ComprobarEstadoAmbito(
  ADetalle: TDetalleHistorico;
  AMetadatos: TMetadatosHistorico;
  AComprobarDespues: Boolean);
var
  oFilas: TObjectList<TFilaHistorico>;
  sClave: string;
  sCondicion: string;
  sDatosActuales: string;
  sDatosEsperados: string;
  sHashActual: string;
  sHashEsperado: string;
begin
  if AComprobarDespues then
  begin
    sClave := ADetalle.ClaveDespues;
    sDatosEsperados := ADetalle.DatosDespues;
    sHashEsperado := ADetalle.HashDespues;
  end
  else
  begin
    sClave := ADetalle.ClaveAntes;
    sDatosEsperados := ADetalle.DatosAntes;
    sHashEsperado := ADetalle.HashAntes;
  end;
  sCondicion := ExtraerCondicionAmbitoVerificada(sClave);
  oFilas := TObjectList<TFilaHistorico>.Create(True);
  try
    CapturarFilas(
      ADetalle.Tabla,
      sCondicion,
      AMetadatos,
      oFilas,
      True);
    sDatosActuales := TCodificadorAmbitoHistorico.CrearResumen(oFilas);
    sHashActual := CalcularHash(sDatosActuales);
    if (sHashActual <> sHashEsperado) or
       (sDatosActuales <> sDatosEsperados) then
      raise EHistoricoCambioArticuloColor.Create(
        crhDatosDivergentes,
        Format(SErrorAmbitoHistoricoDivergente, [ADetalle.Tabla]));
  finally
    oFilas.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.ComprobarEstadoActual(
  ADetalles: TObjectList<TDetalleHistorico>;
  AMetadatos: TObjectDictionary<string, TMetadatosHistorico>;
  AComprobarDespues: Boolean);
var
  EsEsperada: Boolean;
  EsPresente: Boolean;
  oDetalle: TDetalleHistorico;
  oMetadatos: TMetadatosHistorico;
  sClave: string;
  sDatosActuales: string;
  sDatosEsperados: string;
  sHashActual: string;
  sHashEsperado: string;
begin
  for oDetalle in ADetalles do
  begin
    oMetadatos := AMetadatos.Items[oDetalle.Tabla];
    if oDetalle.TipoRegistro = REGISTRO_AMBITO then
      ComprobarEstadoAmbito(
        oDetalle,
        oMetadatos,
        AComprobarDespues)
    else
    begin
      if AComprobarDespues then
      begin
        EsEsperada := oDetalle.TieneDatosDespues;
        if oDetalle.TieneClaveDespues then
          sClave := oDetalle.ClaveDespues
        else
          sClave := oDetalle.ClaveAntes;
        sDatosEsperados := oDetalle.DatosDespues;
        sHashEsperado := oDetalle.HashDespues;
      end
      else
      begin
        EsEsperada := oDetalle.TieneDatosAntes;
        if oDetalle.TieneClaveAntes then
          sClave := oDetalle.ClaveAntes
        else
          sClave := oDetalle.ClaveDespues;
        sDatosEsperados := oDetalle.DatosAntes;
        sHashEsperado := oDetalle.HashAntes;
      end;
      EsPresente := ObtenerDatosActuales(
        oDetalle.Tabla,
        sClave,
        oMetadatos,
        sDatosActuales,
        sHashActual);
      if EsPresente <> EsEsperada then
        raise EHistoricoCambioArticuloColor.Create(
          crhDatosDivergentes,
          Format(SErrorEstadoFilaHistoricoInesperado, [oDetalle.Tabla]));
      if EsEsperada and
         ((sHashActual <> sHashEsperado) or
          (sDatosActuales <> sDatosEsperados)) then
        raise EHistoricoCambioArticuloColor.Create(
          crhDatosDivergentes,
          Format(SErrorFilaHistoricoModificada, [oDetalle.Tabla]));
    end;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.BorrarFila(
  const ATabla, AClave: string;
  AMetadatos: TMetadatosHistorico);
var
  i: Integer;
  iParametro: Integer;
  oColumna: TColumnaHistorico;
  oConsulta: TUniQuery;
  oJson: TJSONObject;
  oRaiz: TJSONValue;
  oValor: TJSONValue;
  sCondicion: string;
  sParametro: string;
begin
  oRaiz := TJSONObject.ParseJSONValue(AClave);
  if not (oRaiz is TJSONObject) then
  begin
    oRaiz.Free;
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorClaveJsonHistoricoInvalida);
  end;
  oJson := TJSONObject(oRaiz);
  oConsulta := NuevaConsulta;
  try
    sCondicion := '';
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if oColumna.EsClave then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not Assigned(oValor) then
          raise EHistoricoCambioArticuloColor.Create(
            crhNoReversible,
            SErrorClavePrimariaHistoricoIncompleta);
        if sCondicion <> '' then
          sCondicion := sCondicion + ' AND ';
        if oValor is TJSONNull then
          sCondicion := sCondicion + '`' + oColumna.Nombre + '` IS NULL'
        else
        begin
          sParametro := 'K' + IntToStr(iParametro);
          sCondicion := sCondicion + '`' + oColumna.Nombre +
            '` = UNHEX(:' + sParametro + ')';
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.SQL.Text :=
      'DELETE FROM `' + ATabla + '` WHERE ' + sCondicion;
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if oColumna.EsClave then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not (oValor is TJSONNull) then
        begin
          sParametro := 'K' + IntToStr(iParametro);
          oConsulta.ParamByName(sParametro).AsString := oValor.Value;
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EHistoricoCambioArticuloColor.Create(
        crhDatosDivergentes,
        Format(SErrorRetiradaFilaHistoricoFallida, [ATabla]));
  finally
    oConsulta.Free;
    oJson.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.InsertarFila(
  const ATabla, ADatos: string;
  AMetadatos: TMetadatosHistorico);
var
  i: Integer;
  iParametro: Integer;
  oColumna: TColumnaHistorico;
  oConsulta: TUniQuery;
  oJson: TJSONObject;
  oRaiz: TJSONValue;
  oValor: TJSONValue;
  sCampos: string;
  sParametro: string;
  sValores: string;
begin
  oRaiz := TJSONObject.ParseJSONValue(ADatos);
  if not (oRaiz is TJSONObject) then
  begin
    oRaiz.Free;
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorDatosJsonHistoricoInvalidos);
  end;
  oJson := TJSONObject(oRaiz);
  oConsulta := NuevaConsulta;
  try
    sCampos := '';
    sValores := '';
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if not oColumna.EsGenerada then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not Assigned(oValor) then
          raise EHistoricoCambioArticuloColor.Create(
            crhNoReversible,
            Format(SErrorCamposHistoricoIncompletos, [ATabla]));
        if sCampos <> '' then
        begin
          sCampos := sCampos + ', ';
          sValores := sValores + ', ';
        end;
        sCampos := sCampos + '`' + oColumna.Nombre + '`';
        if oValor is TJSONNull then
          sValores := sValores + 'NULL'
        else
        begin
          sParametro := 'V' + IntToStr(iParametro);
          sValores := sValores + 'UNHEX(:' + sParametro + ')';
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.SQL.Text :=
      'INSERT INTO `' + ATabla + '` (' + sCampos + ') VALUES (' +
      sValores + ')';
    iParametro := 0;
    for i := 0 to AMetadatos.Columnas.Count - 1 do
    begin
      oColumna := AMetadatos.Columnas[i];
      if not oColumna.EsGenerada then
      begin
        oValor := oJson.GetValue(oColumna.Nombre);
        if not (oValor is TJSONNull) then
        begin
          sParametro := 'V' + IntToStr(iParametro);
          oConsulta.ParamByName(sParametro).DataType := ftMemo;
          oConsulta.ParamByName(sParametro).AsString := oValor.Value;
          Inc(iParametro);
        end;
      end;
    end;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EHistoricoCambioArticuloColor.Create(
        crhDatosDivergentes,
        Format(SErrorRestauracionFilaHistoricoFallida, [ATabla]));
  finally
    oConsulta.Free;
    oJson.Free;
  end;
end;

procedure THistoricoCambioArticuloColorImpl.RestaurarFilas(
  ADetalles: TObjectList<TDetalleHistorico>;
  AMetadatos: TObjectDictionary<string, TMetadatosHistorico>);
var
  i: Integer;
  oDetalle: TDetalleHistorico;
  oMetadatos: TMetadatosHistorico;
begin
  { Las guardas y ámbitos se comprueban, pero nunca generan DML. }
  for i := ADetalles.Count - 1 downto 0 do
  begin
    oDetalle := ADetalles[i];
    if (oDetalle.TipoRegistro = REGISTRO_FILA) and
       oDetalle.TieneDatosDespues then
    begin
      oMetadatos := AMetadatos.Items[oDetalle.Tabla];
      BorrarFila(
        oDetalle.Tabla,
        oDetalle.ClaveDespues,
        oMetadatos);
    end;
  end;
  for i := 0 to ADetalles.Count - 1 do
  begin
    oDetalle := ADetalles[i];
    if (oDetalle.TipoRegistro = REGISTRO_FILA) and
       oDetalle.TieneDatosAntes then
    begin
      oMetadatos := AMetadatos.Items[oDetalle.Tabla];
      InsertarFila(
        oDetalle.Tabla,
        oDetalle.DatosAntes,
        oMetadatos);
    end;
  end;
end;

function THistoricoCambioArticuloColorImpl.InvertirAccion(
  const AAccion: string): string;
begin
  if AAccion = ACCION_INSERTAR then
    Result := ACCION_ELIMINAR
  else if AAccion = ACCION_ELIMINAR then
    Result := ACCION_INSERTAR
  else if AAccion = ACCION_ACTUALIZAR then
    Result := ACCION_ACTUALIZAR
  else if AAccion = ACCION_COMPROBAR then
    Result := ACCION_COMPROBAR
  else
    raise EHistoricoCambioArticuloColor.Create(
      crhNoReversible,
      SErrorAccionHistoricoNoReconocida);
end;

procedure THistoricoCambioArticuloColorImpl.RegistrarReversion(
  const AIdReversion, AUsuario: string;
  AOperacion: TOperacionHistorico;
  ADetalles: TObjectList<TDetalleHistorico>);
var
  oDetalle: TDetalleHistorico;
  oInverso: TDetalleHistorico;
begin
  InsertarCabecera(
    AIdReversion,
    TIPO_REVERSION,
    AOperacion.Id,
    AOperacion.TipoObjeto,
    AOperacion.CodigoDestino,
    AOperacion.CodigoOrigen,
    AUsuario);
  for oDetalle in ADetalles do
  begin
    oInverso := TDetalleHistorico.Create;
    try
      oInverso.Orden := oDetalle.Orden;
      oInverso.TipoRegistro := oDetalle.TipoRegistro;
      oInverso.TipoOperacion := TIPO_REVERSION;
      oInverso.TipoObjeto := AOperacion.TipoObjeto;
      oInverso.Tabla := oDetalle.Tabla;
      oInverso.Accion := InvertirAccion(oDetalle.Accion);
      oInverso.ClaveAntes := oDetalle.ClaveDespues;
      oInverso.ClaveDespues := oDetalle.ClaveAntes;
      oInverso.HashClaveAntes := oDetalle.HashClaveDespues;
      oInverso.HashClaveDespues := oDetalle.HashClaveAntes;
      oInverso.DatosAntes := oDetalle.DatosDespues;
      oInverso.DatosDespues := oDetalle.DatosAntes;
      oInverso.HashAntes := oDetalle.HashDespues;
      oInverso.HashDespues := oDetalle.HashAntes;
      oInverso.FirmaEsquema := oDetalle.FirmaEsquema;
      oInverso.TieneClaveAntes := oDetalle.TieneClaveDespues;
      oInverso.TieneClaveDespues := oDetalle.TieneClaveAntes;
      oInverso.TieneDatosAntes := oDetalle.TieneDatosDespues;
      oInverso.TieneDatosDespues := oDetalle.TieneDatosAntes;
      InsertarDetalle(
        AIdReversion,
        TIPO_REVERSION,
        AOperacion.TipoObjeto,
        AUsuario,
        oInverso);
    finally
      oInverso.Free;
    end;
  end;
end;

function THistoricoCambioArticuloColorImpl.EjecutarReversion(
  const AIdOperacion, AUsuario: string): string;
var
  oDetalles: TObjectList<TDetalleHistorico>;
  oMetadatos: TObjectDictionary<string, TMetadatosHistorico>;
  oOperacion: TOperacionHistorico;
begin
  oOperacion := CargarOperacion(AIdOperacion);
  try
    if SameText(oOperacion.TipoOperacion, TIPO_REVERSION) then
      raise EHistoricoCambioArticuloColor.Create(
        crhNoReversible,
        SErrorReversionDeReversion);
    if TieneReversionAplicada(oOperacion.Id) then
      raise EHistoricoCambioArticuloColor.Create(
        crhYaRevertida,
        SErrorOperacionHistoricaYaRevertida);
    if TieneDependenciaPosterior(oOperacion) then
      raise EHistoricoCambioArticuloColor.Create(
        crhDependenciaPosterior,
        SErrorDependenciaPosteriorHistorico);
    if HayFacturasRelacionadas(oOperacion) then
      raise EHistoricoCambioArticuloColor.Create(
        crhVentaFacturada,
        SErrorFacturasRelacionadasHistorico);
    oDetalles := CargarDetalles(oOperacion.Id);
    try
      ValidarDetalles(oOperacion, oDetalles);
      oMetadatos := TObjectDictionary<string,
        TMetadatosHistorico>.Create([doOwnsValues]);
      try
        ComprobarEsquemas(oDetalles, oMetadatos);
        ComprobarEstadoActual(oDetalles, oMetadatos, True);
        Result := GenerarUuid;
        RegistrarReversion(
          Result,
          AUsuario,
          oOperacion,
          oDetalles);
        RestaurarFilas(oDetalles, oMetadatos);
        ComprobarEstadoActual(oDetalles, oMetadatos, False);
        MarcarCabeceraAplicada(
          Result,
          AUsuario,
          'Reversión limpia de ' + oOperacion.Id,
          oOperacion.CantidadFilas,
          oOperacion.CantidadUnidades);
      finally
        oMetadatos.Free;
      end;
    finally
      oDetalles.Free;
    end;
  finally
    oOperacion.Free;
  end;
end;

function THistoricoCambioArticuloColorImpl.RevertirInterno(
  const AIdOperacion, AUsuario: string;
  AExigirTransaccion: Boolean): TResultadoReversionHistorico;
var
  EsPuntoGuardado: Boolean;
  EsTransaccionPropia: Boolean;
  sIdReversion: string;
  sPuntoGuardado: string;
begin
  EsTransaccionPropia := not FConexion.InTransaction;
  if AExigirTransaccion and EsTransaccionPropia then
    Result := TResultadoReversionHistorico.Error(
      crhErrorTecnico,
      SErrorReversionSinTransaccion)
  else if Trim(AIdOperacion) = '' then
    Result := TResultadoReversionHistorico.Error(
      crhNoEncontrada,
      SErrorOperacionReversionNoIndicada)
  else if Trim(AUsuario) = '' then
    Result := TResultadoReversionHistorico.Error(
      crhErrorTecnico,
      SErrorUsuarioReversionObligatorio)
  else
  begin
    EsPuntoGuardado := False;
    sPuntoGuardado := '';
    try
      if EsTransaccionPropia then
      begin
        Ejecutar('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE');
        FConexion.StartTransaction;
      end
      else
      begin
        sPuntoGuardado := 'SP_ACH_' + StringReplace(
          Copy(GenerarUuid, 1, 18),
          '-',
          '',
          [rfReplaceAll]);
        ValidarIdentificador(sPuntoGuardado);
        Ejecutar('SAVEPOINT `' + sPuntoGuardado + '`');
        EsPuntoGuardado := True;
      end;
      sIdReversion := EjecutarReversion(
        AIdOperacion,
        Copy(AUsuario, 1, 50));
      if EsTransaccionPropia then
        FConexion.Commit
      else
      begin
        Ejecutar('RELEASE SAVEPOINT `' + sPuntoGuardado + '`');
        EsPuntoGuardado := False;
      end;
      Result := TResultadoReversionHistorico.Correcto(sIdReversion);
    except
      on E: EHistoricoCambioArticuloColor do
      begin
        if EsTransaccionPropia and FConexion.InTransaction then
          FConexion.Rollback
        else if EsPuntoGuardado then
        begin
          Ejecutar('ROLLBACK TO SAVEPOINT `' + sPuntoGuardado + '`');
          Ejecutar('RELEASE SAVEPOINT `' + sPuntoGuardado + '`');
        end;
        Result := TResultadoReversionHistorico.Error(
          E.Causa,
          E.Message);
      end;
      on E: Exception do
      begin
        if EsTransaccionPropia and FConexion.InTransaction then
          FConexion.Rollback
        else if EsPuntoGuardado then
        begin
          Ejecutar('ROLLBACK TO SAVEPOINT `' + sPuntoGuardado + '`');
          Ejecutar('RELEASE SAVEPOINT `' + sPuntoGuardado + '`');
        end;
        Result := TResultadoReversionHistorico.Error(
          crhErrorTecnico,
          E.Message);
      end;
    end;
  end;
end;

function THistoricoCambioArticuloColorImpl.Revertir(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
begin
  Result := RevertirInterno(AIdOperacion, AUsuario, False);
end;

function THistoricoCambioArticuloColorImpl.RevertirEnTransaccion(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
begin
  Result := RevertirInterno(AIdOperacion, AUsuario, True);
end;

{ THistoricoCambioArticuloColor }

constructor THistoricoCambioArticuloColor.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FImplementacion := THistoricoCambioArticuloColorImpl.Create(AConexion);
end;

destructor THistoricoCambioArticuloColor.Destroy;
begin
  FImplementacion.Free;
  inherited Destroy;
end;

procedure THistoricoCambioArticuloColor.IniciarOperacion(
  const ATipoOperacion, ATipoObjeto, ACodigoOrigen,
  ACodigoDestino, AUsuario: string);
begin
  THistoricoCambioArticuloColorImpl(FImplementacion).IniciarOperacion(
    ATipoOperacion,
    ATipoObjeto,
    ACodigoOrigen,
    ACodigoDestino,
    AUsuario);
end;

procedure THistoricoCambioArticuloColor.CapturarAntes(
  const ATabla, ACondicion: string;
  const ANombres, AValores: array of string);
begin
  THistoricoCambioArticuloColorImpl(FImplementacion).CapturarAntes(
    ATabla,
    ACondicion,
    ANombres,
    AValores);
end;

procedure THistoricoCambioArticuloColor.CompletarOperacion(
  ACantidadUnidades: Integer;
  const ADetalle: string);
begin
  THistoricoCambioArticuloColorImpl(FImplementacion).CompletarOperacion(
    ACantidadUnidades,
    ADetalle);
end;

function THistoricoCambioArticuloColor.Revertir(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
begin
  Result := THistoricoCambioArticuloColorImpl(FImplementacion).Revertir(
    AIdOperacion,
    AUsuario);
end;

function THistoricoCambioArticuloColor.RevertirEnTransaccion(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
begin
  Result := THistoricoCambioArticuloColorImpl(FImplementacion).
    RevertirEnTransaccion(AIdOperacion, AUsuario);
end;

function THistoricoCambioArticuloColor.IdOperacion: string;
begin
  Result := THistoricoCambioArticuloColorImpl(FImplementacion).IdOperacion;
end;

end.

{******************************************************************************}
{                                                                             }
{  Módulo: UniDataCambioCodigoCliente                                         }
{  Tipo: Repositorio UniDAC                                                   }
{  Versión: 1.0.0                                                             }
{  Fecha: 14/11/2026                                                          }
{  Autor: Alejandro Laorden Hidalgo                                           }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  Descripción:                                                               }
{  Recodificación atómica y detección manual de coincidencias.                }
{                                                                             }
{******************************************************************************}
unit UniDataCambioCodigoCliente;

interface

uses
  Uni, inLibCambioCodigoCliente;

function CrearCambioCodigoCliente(AConexion: TUniConnection):
  ICambioCodigoCliente;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB;

const
  TABLA_CLIENTES = 'fza_clientes';
  fCodigo = 'CODIGO_CLI_CLI';
  REFERENCIAS_CLIENTE: array[0..17] of string = (
    'fza_albaranes|CODIGO_CLI_ALB',
    'fza_almacenes|CODIGO_CLI_ALM',
    'fza_caja_operaciones|CODIGO_CLI_OPCAJA',
    'fza_caja_vales|CODIGO_CLI_VL',
    'fza_clientes|CODIGO_CLI_CLI',
    'fza_clientes_medidas|CODIGO_CLI_CLMED',
    'fza_depositos_cliente|CODIGO_CLI_DEP',
    'fza_efectos_venta|CODIGO_CLI_EFV',
    'fza_empresas|CODIGO_CLI_TRASPASOS_EMP',
    'fza_facturas|CODIGO_CLI_FAC',
    'fza_facturas_compra|CODIGO_CLI_FACC',
    'fza_garantias_reclamaciones|CODIGO_CLI_GAR',
    'fza_garantias_reclamaciones|CODIGO_CLI_PAGADOR_GAR',
    'fza_movimientos_almacen|CODIGO_CLI_MOV',
    'fza_pedidos|CODIGO_CLI_PED',
    'fza_presupuestos|CODIGO_CLI_PRE',
    'fza_proformas_caja|CODIGO_CLI_PROCAJ',
    'fza_recibos|CODIGO_CLI_REC');

type
  TReferenciaCliente = record
    Tabla: string;
    Campo: string;
    TieneInstante: Boolean;
  end;
  TReferenciasCliente = TArray<TReferenciaCliente>;

  TCambioCodigoClienteUniDAC = class(TInterfacedObject, ICambioCodigoCliente)
  private
    FConexion: TUniConnection;
    function ReferenciasCompatibles(out AReferencias:
      TReferenciasCliente): Boolean;
    procedure BloquearReferencias(const AReferencias: TReferenciasCliente);
    function ExisteCodigo(const ATabla, ACampo, ACodigo: string): Boolean;
    function DestinoOcupado(const AReferencias: TReferenciasCliente;
      const ACodigo: string): Boolean;
    function ActualizarReferencia(const AReferencia: TReferenciaCliente;
      const AAnterior, ANuevo: string): Int64;
    function AplicarCambio(const AReferencias: TReferenciasCliente;
      const AAnterior, ANuevo, AUsuario: string): TResultadoCambioCliente;
  public
    constructor Create(AConexion: TUniConnection);
    function Cambiar(const AAnterior, ANuevo, AUsuario: string):
      TResultadoCambioCliente;
    function DetectarDuplicados(const ACodigo: string): TDuplicadosClientes;
  end;

constructor TCambioCodigoClienteUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function ReferenciaConocida(const ATabla, ACampo: string): Boolean;
var
  sReferencia: string;
begin
  Result := False;
  for sReferencia in REFERENCIAS_CLIENTE do
    Result := Result or SameText(sReferencia, ATabla + '|' + ACampo);
end;

function TCambioCodigoClienteUniDAC.ReferenciasCompatibles(
  out AReferencias: TReferenciasCliente): Boolean;
var
  oConsulta: TUniQuery;
  oReferencias: TList<TReferenciaCliente>;
  rReferencia: TReferenciaCliente;
  bMaestro: Boolean;
begin
  Result := True;
  bMaestro := False;
  oReferencias := TList<TReferenciaCliente>.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT C.TABLE_NAME, C.COLUMN_NAME, C.DATA_TYPE,' +
      ' C.CHARACTER_MAXIMUM_LENGTH, T.ENGINE,' +
      ' (M.COLUMN_NAME IS NOT NULL) TIENE_INSTANTE' +
      ' FROM INFORMATION_SCHEMA.COLUMNS C' +
      ' JOIN INFORMATION_SCHEMA.TABLES T' +
      ' ON T.TABLE_SCHEMA=C.TABLE_SCHEMA AND T.TABLE_NAME=C.TABLE_NAME' +
      ' LEFT JOIN INFORMATION_SCHEMA.COLUMNS M' +
      ' ON M.TABLE_SCHEMA=DATABASE() AND M.TABLE_NAME=C.TABLE_NAME' +
      ' AND M.COLUMN_NAME=''INSTANTE_MODIF''' +
      ' WHERE C.TABLE_SCHEMA=DATABASE() AND T.TABLE_TYPE=''BASE TABLE''' +
      ' AND LEFT(C.TABLE_NAME,4)=''fza_''' +
      ' AND C.COLUMN_NAME REGEXP ''^CODIGO_(CLI_|CLIENTE($|_))''' +
      ' ORDER BY C.TABLE_NAME,C.COLUMN_NAME';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rReferencia.Tabla := oConsulta.Fields[0].AsString;
      rReferencia.Campo := oConsulta.Fields[1].AsString;
      rReferencia.TieneInstante := oConsulta.Fields[5].AsInteger <> 0;
      Result := Result and ReferenciaConocida(rReferencia.Tabla,
        rReferencia.Campo) and SameText(oConsulta.Fields[2].AsString,
        'varchar') and (oConsulta.Fields[3].AsInteger >= 20)
        and SameText(oConsulta.Fields[4].AsString, 'InnoDB');
      bMaestro := bMaestro or SameText(rReferencia.Tabla, TABLA_CLIENTES);
      oReferencias.Add(rReferencia);
      oConsulta.Next;
    end;
    Result := Result and bMaestro;
    AReferencias := oReferencias.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oReferencias);
  end;
end;

procedure TCambioCodigoClienteUniDAC.BloquearReferencias(
  const AReferencias: TReferenciasCliente);
var
  rReferencia: TReferenciaCliente;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Lecturas de bloqueo bajo SERIALIZABLE: también protegen los huecos.
    // Los identificadores solo proceden de REFERENCIAS_CLIENTE.
    for rReferencia in AReferencias do
    begin
      oConsulta.Close;
      oConsulta.SQL.Text := 'SELECT `' + rReferencia.Campo + '` FROM `' +
        rReferencia.Tabla + '` FOR UPDATE';
      oConsulta.Open;
      oConsulta.Last;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCambioCodigoClienteUniDAC.ExisteCodigo(
  const ATabla, ACampo, ACodigo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM `' + ATabla + '` WHERE `' +
      ACampo + '`=:CODIGO LIMIT 1';
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCambioCodigoClienteUniDAC.DestinoOcupado(
  const AReferencias: TReferenciasCliente; const ACodigo: string): Boolean;
var
  rReferencia: TReferenciaCliente;
begin
  Result := False;
  for rReferencia in AReferencias do
    if not Result then
      Result := ExisteCodigo(rReferencia.Tabla, rReferencia.Campo, ACodigo);
end;

function TCambioCodigoClienteUniDAC.ActualizarReferencia(
  const AReferencia: TReferenciaCliente;
  const AAnterior, ANuevo: string): Int64;
var
  oConsulta: TUniQuery;
  sAuditoria: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Recodificar el vínculo no modifica el contenido del documento.
    // Evitar el ON UPDATE automático de sus columnas de auditoría.
    sAuditoria := '';
    if AReferencia.TieneInstante then
      sAuditoria := ', INSTANTE_MODIF=INSTANTE_MODIF';
    oConsulta.SQL.Text := 'UPDATE `' + AReferencia.Tabla + '` SET `' +
      AReferencia.Campo + '`=:NUEVO' + sAuditoria + ' WHERE `' +
      AReferencia.Campo +
      '`=:ANTERIOR';
    oConsulta.ParamByName('NUEVO').AsString := ANuevo;
    oConsulta.ParamByName('ANTERIOR').AsString := AAnterior;
    oConsulta.ExecSQL;
    Result := oConsulta.RowsAffected;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCambioCodigoClienteUniDAC.AplicarCambio(
  const AReferencias: TReferenciasCliente;
  const AAnterior, ANuevo, AUsuario: string): TResultadoCambioCliente;
var
  rReferencia: TReferenciaCliente;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoCambioCliente);
  BloquearReferencias(AReferencias);
  if not ExisteCodigo(TABLA_CLIENTES, fCodigo, AAnterior) then
    Result.Estado := eccOrigenNoExiste
  else if DestinoOcupado(AReferencias, ANuevo) then
    Result.Estado := eccDestinoOcupado
  else
  begin
    for rReferencia in AReferencias do
      if rReferencia.Tabla <> TABLA_CLIENTES then
        Inc(Result.Referencias,
          ActualizarReferencia(rReferencia, AAnterior, ANuevo));
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := 'UPDATE fza_clientes SET CODIGO_CLI_CLI=:NUEVO,' +
        ' INSTANTE_MODIF=NOW(), USUARIO_MODIF=:USUARIO' +
        ' WHERE CODIGO_CLI_CLI=:ANTERIOR';
      oConsulta.ParamByName('NUEVO').AsString := ANuevo;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ParamByName('ANTERIOR').AsString := AAnterior;
      oConsulta.ExecSQL;
      if oConsulta.RowsAffected <> 1 then
        raise EDatabaseError.Create('Cambio de cliente: fila no actualizada');
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TCambioCodigoClienteUniDAC.Cambiar(
  const AAnterior, ANuevo, AUsuario: string): TResultadoCambioCliente;
var
  aReferencias: TReferenciasCliente;
begin
  Result := Default(TResultadoCambioCliente);
  if not DatosCambioClienteValidos(AAnterior, ANuevo, AUsuario) then
    Result.Estado := eccDatosInvalidos
  else if FConexion.InTransaction then
    Result.Estado := eccTransaccionActiva
  else if not ReferenciasCompatibles(aReferencias) then
    Result.Estado := eccEsquemaNoCompatible
  else
  begin
    FConexion.ExecSQL('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE', []);
    FConexion.StartTransaction;
    try
      Result := AplicarCambio(aReferencias, Trim(AAnterior), Trim(ANuevo),
        Trim(AUsuario));
      if Result.Estado = eccCorrecto then
        FConexion.Commit
      else
        FConexion.Rollback;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  end;
end;

function TCambioCodigoClienteUniDAC.DetectarDuplicados(
  const ACodigo: string): TDuplicadosClientes;
var
  oConsulta: TUniQuery;
  oDuplicados: TList<TDuplicadoCliente>;
  rDuplicado: TDuplicadoCliente;
begin
  oConsulta := TUniQuery.Create(nil);
  oDuplicados := TList<TDuplicadoCliente>.Create;
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'WITH C AS (SELECT CODIGO_CLI_CLI CODIGO, RAZON_SOCIAL_CLI NOMBRE,' +
      ' REGEXP_REPLACE(UPPER(COALESCE(NIF_CLI,'''')),' +
      ' ''[^A-Z0-9]'','''') NIF,' +
      ' REGEXP_REPLACE(COALESCE(TELEFONO_CLI,''''),''[^0-9]'','''') TEL,' +
      ' REGEXP_REPLACE(COALESCE(MOVIL_CLI,''''),''[^0-9]'','''') MOVIL,' +
      ' LOWER(TRIM(COALESCE(EMAIL_CLI,''''))) CORREO FROM fza_clientes),' +
      ' P AS (SELECT A.CODIGO,A.NOMBRE,B.CODIGO OTRO,B.NOMBRE OTRO_NOMBRE,' +
      ' (A.NIF<>'''' AND A.NIF=B.NIF) MISMO_NIF,' +
      ' ((A.CORREO<>'''' AND A.CORREO=B.CORREO) OR' +
      ' (A.TEL<>'''' AND A.TEL IN (B.TEL,B.MOVIL)) OR' +
      ' (A.MOVIL<>'''' AND A.MOVIL IN (B.TEL,B.MOVIL))) MISMO_CONTACTO' +
      ' FROM C A JOIN C B ON A.CODIGO<B.CODIGO' +
      ' WHERE (:CODIGO='''' OR A.CODIGO=:CODIGO OR B.CODIGO=:CODIGO))' +
      ' SELECT CODIGO,NOMBRE,OTRO,OTRO_NOMBRE,MISMO_NIF,MISMO_CONTACTO' +
      ' FROM P WHERE MISMO_NIF OR MISMO_CONTACTO ORDER BY CODIGO,OTRO' +
      ' LIMIT ' + IntToStr(LIMITE_DUPLICADOS_CLIENTES + 1);
    oConsulta.ParamByName('CODIGO').AsString := Trim(ACodigo);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rDuplicado.Codigo := oConsulta.Fields[0].AsString;
      rDuplicado.Nombre := oConsulta.Fields[1].AsString;
      rDuplicado.OtroCodigo := oConsulta.Fields[2].AsString;
      rDuplicado.OtroNombre := oConsulta.Fields[3].AsString;
      rDuplicado.MismoNif := (oConsulta.Fields[4].AsInteger <> 0);
      rDuplicado.MismoContacto := (oConsulta.Fields[5].AsInteger <> 0);
      oDuplicados.Add(rDuplicado);
      oConsulta.Next;
    end;
    Result := oDuplicados.ToArray;
  finally
    FreeAndNil(oDuplicados);
    FreeAndNil(oConsulta);
  end;
end;

function CrearCambioCodigoCliente(AConexion: TUniConnection):
  ICambioCodigoCliente;
begin
  Result := TCambioCodigoClienteUniDAC.Create(AConexion);
end;

end.

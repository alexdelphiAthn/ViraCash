{******************************************************************************}
{  Módulo: UniDataCorreccionPago                                               }
{  Tipo: Persistencia de Caja                                                  }
{  Versión: 1.0.0                                                              }
{  Fecha: 15/09/2026                                                           }
{  Descripción: Añade la compensación y el nuevo cobro en una transacción.     }
{******************************************************************************}
unit UniDataCorreccionPago;

interface

uses
  Uni, inLibCorreccionPagoIntf, inLibPermisosIntf;

type
  TCorreccionPagoUniDAC = class(TInterfacedObject, ICorreccionPago)
  private
    FConexion: TUniConnection;
    FPermisos: IPermisosAplicacion;
    FUsuario: string;
    function Consulta(const ASql: string): TUniQuery;
    procedure ParametrosOperacion(AConsulta: TUniQuery;
      const AOperacion: TOperacionCorreccionPago);
    procedure ExigirPermiso;
    procedure ComprobarEsquema;
    procedure ValidarSolicitud(const ASolicitud: TSolicitudCorreccionPago);
    procedure BloquearOperacion(const AOperacion: TOperacionCorreccionPago);
    procedure ComprobarArqueo(const AOperacion: TOperacionCorreccionPago;
      AFecha: TDateTime);
    procedure ValidarMedio(const ASolicitud: TSolicitudCorreccionPago;
      const AOrigen: string);
    function BloquearCobro(const ASolicitud: TSolicitudCorreccionPago;
      out AFormaOrigen: string): Integer;
    procedure InsertarApunte(const ASolicitud: TSolicitudCorreccionPago;
      ALinea: Integer; ACompensacion: Boolean);
  public
    constructor Create(AConexion: TUniConnection;
      const APermisos: IPermisosAplicacion; const AUsuario: string);
    function Permitida: Boolean;
    function Cobros(const AOperacion: TOperacionCorreccionPago):
      TArray<TCobroCorregible>;
    function Medios: TArray<TMedioCorreccionPago>;
    procedure Corregir(const ASolicitud: TSolicitudCorreccionPago);
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB, inLibMsgCaja;

const
  SQL_OPERACION_PAGO =
    'CODIGO_EMP_PAGO = :EMP AND CODIGO_ALM_PAGO = :ALM ' +
    'AND CODIGO_CAJA_PAGO = :CAJA AND NUMERO_OPERACION_PAGO = :OPE ';
  SQL_MEDIO_SIMPLE =
    'COALESCE(ESCRIPTO_FORMA_PAGO_CFP, ''N'') <> ''S'' ' +
    'AND COALESCE(ESDIVISA_FORMA_PAGO_CFP, ''N'') <> ''S'' ' +
    'AND CODIGO_FP_CFP NOT IN (''VALE'', ''BONO'', ''DEUDA'') ' +
    'AND CHAR_LENGTH(CODIGO_FP_CFP) <= 10 ';

constructor TCorreccionPagoUniDAC.Create(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario: string);
begin
  inherited Create;
  FConexion := AConexion;
  FPermisos := APermisos;
  FUsuario := Trim(AUsuario);
end;

function TCorreccionPagoUniDAC.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TCorreccionPagoUniDAC.ParametrosOperacion(AConsulta: TUniQuery;
  const AOperacion: TOperacionCorreccionPago);
begin
  AConsulta.ParamByName('EMP').AsString := AOperacion.Empresa;
  AConsulta.ParamByName('ALM').AsString := AOperacion.Almacen;
  AConsulta.ParamByName('CAJA').AsString := AOperacion.Caja;
  AConsulta.ParamByName('OPE').AsString := AOperacion.Numero;
end;

function TCorreccionPagoUniDAC.Permitida: Boolean;
begin
  Result := Assigned(FPermisos) and FPermisos.Disponible and
    FPermisos.TienePermiso(
      CodigoPermisoMto('CajaPagosHist', apmModificar), paPermitir);
end;

procedure TCorreccionPagoUniDAC.ExigirPermiso;
begin
  if not Permitida or (FUsuario = '') then
    raise EInvalidOpException.Create(SErrorCorreccionPagoPermiso);
end;

procedure TCorreccionPagoUniDAC.ComprobarEsquema;
var
  ConsultaEsquema: TUniQuery;
begin
  ConsultaEsquema := Consulta(
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ''fza_caja_pagos'' '+
    'AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS s ' +
    'WHERE s.TABLE_SCHEMA = DATABASE() ' +
    'AND s.TABLE_NAME = ''fza_caja_pagos'' ' +
    'AND s.INDEX_NAME = ''UQ_PAGO_CORRECCION_ORIGEN'') ' +
    'AND COLUMN_NAME IN (''NUMERO_LINEA_ORIGEN_PAGO'', ' +
    '''TIPO_CORRECCION_PAGO'')');
  try
    ConsultaEsquema.Open;
    if ConsultaEsquema.FieldByName('N').AsInteger <> 2 then
      raise EInvalidOpException.Create(SErrorCorreccionPagoEsquema);
  finally
    FreeAndNil(ConsultaEsquema);
  end;
end;

function TCorreccionPagoUniDAC.Cobros(
  const AOperacion: TOperacionCorreccionPago): TArray<TCobroCorregible>;
var
  Datos: TUniQuery;
  Lista: TList<TCobroCorregible>;
  Cobro: TCobroCorregible;
begin
  ExigirPermiso;
  ComprobarEsquema;
  Datos := Consulta(
    'SELECT p.SERIE_OPERACION_PAGO, p.NUMERO_LINEA_PAGO, ' +
    'p.CODIGO_FP_CFP, fp.DESCRIPCION_FORMA_PAGO_CFP, ' +
    'p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO AS NETO ' +
    'FROM fza_caja_pagos p JOIN fza_caja_formas_pago fp ' +
    'ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP WHERE ' +
    StringReplace(SQL_OPERACION_PAGO, 'CODIGO_', 'p.CODIGO_',
      [rfReplaceAll]) +
    'AND ' + StringReplace(SQL_MEDIO_SIMPLE, 'CODIGO_FP_CFP',
      'fp.CODIGO_FP_CFP', [rfReplaceAll]) +
    'AND p.IMPORTE_ENTREGADO_PAGO > p.IMPORTE_CAMBIO_PAGO ' +
    'AND COALESCE(p.CODIGO_DIVISA_PAGO, ''EUR'') IN ('''', ''EUR'') '+
    'AND COALESCE(p.RED_BLOCKCHAIN_PAGO, '''') = '''' ' +
    'AND p.FACTOR_CAMBIO_PAGO = 1 AND p.IMPORTE_DIVISA_PAGO = 0 '+
    'AND NOT EXISTS (SELECT 1 FROM fza_caja_pagos c ' +
    'WHERE c.CODIGO_EMP_PAGO = p.CODIGO_EMP_PAGO ' +
    'AND c.CODIGO_ALM_PAGO = p.CODIGO_ALM_PAGO ' +
    'AND c.CODIGO_CAJA_PAGO = p.CODIGO_CAJA_PAGO ' +
    'AND c.SERIE_OPERACION_PAGO = p.SERIE_OPERACION_PAGO ' +
    'AND c.NUMERO_OPERACION_PAGO = p.NUMERO_OPERACION_PAGO ' +
    'AND c.NUMERO_LINEA_ORIGEN_PAGO = p.NUMERO_LINEA_PAGO) ' +
    'ORDER BY p.SERIE_OPERACION_PAGO, p.NUMERO_LINEA_PAGO');
  Lista := TList<TCobroCorregible>.Create;
  try
    ParametrosOperacion(Datos, AOperacion);
    Datos.Open;
    while not Datos.Eof do
    begin
      Cobro.Serie := Datos.FieldByName('SERIE_OPERACION_PAGO').AsString;
      Cobro.Linea := Datos.FieldByName('NUMERO_LINEA_PAGO').AsInteger;
      Cobro.FormaPago := Datos.FieldByName('CODIGO_FP_CFP').AsString;
      Cobro.Descripcion :=
        Datos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString;
      Cobro.ImporteNeto := Datos.FieldByName('NETO').AsCurrency;
      Lista.Add(Cobro);
      Datos.Next;
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
    FreeAndNil(Datos);
  end;
end;

function TCorreccionPagoUniDAC.Medios: TArray<TMedioCorreccionPago>;
var
  Datos: TUniQuery;
  Lista: TList<TMedioCorreccionPago>;
  Medio: TMedioCorreccionPago;
begin
  ExigirPermiso;
  Datos := Consulta(
    'SELECT CODIGO_FP_CFP, DESCRIPCION_FORMA_PAGO_CFP, ' +
    'ESREQ_REFERENCIA_FORMA_PAGO_CFP FROM fza_caja_formas_pago ' +
    'WHERE ESACTIVO_FORMA_PAGO_CFP = ''S'' AND ' + SQL_MEDIO_SIMPLE +
    'ORDER BY ORDEN_VISUAL_FORMA_PAGO_CFP, CODIGO_FP_CFP');
  Lista := TList<TMedioCorreccionPago>.Create;
  try
    Datos.Open;
    while not Datos.Eof do
    begin
      Medio.Codigo := Datos.FieldByName('CODIGO_FP_CFP').AsString;
      Medio.Descripcion :=
        Datos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString;
      Medio.RequiereReferencia :=
        Datos.FieldByName('ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString = 'S';
      Lista.Add(Medio);
      Datos.Next;
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
    FreeAndNil(Datos);
  end;
end;

procedure TCorreccionPagoUniDAC.ValidarSolicitud(
  const ASolicitud: TSolicitudCorreccionPago);
begin
  ExigirPermiso;
  if (ASolicitud.Linea < 1) or (Trim(ASolicitud.FormaPago) = '') then
    raise EArgumentException.Create(SErrorCorreccionPagoSeleccion);
  if (Trim(ASolicitud.Motivo) = '') or
     (Length(ASolicitud.Motivo) > 180) then
    raise EArgumentException.Create(SErrorCorreccionPagoMotivo);
  if Length(ASolicitud.Referencia) > 255 then
    raise EArgumentException.Create(SErrorCorreccionPagoReferencia);
end;

procedure TCorreccionPagoUniDAC.ComprobarArqueo(
  const AOperacion: TOperacionCorreccionPago; AFecha: TDateTime);
var
  Datos: TUniQuery;
begin
  Datos := Consulta(
    'SELECT CODIGO_ARQ FROM fza_caja_arqueos ' +
    'WHERE CODIGO_EMP_ARQ = :EMP AND CODIGO_ALM_ARQ = :ALM ' +
    'AND CODIGO_CAJA_ARQ = :CAJA AND FASE_ARQ = ''CERRADO'' ' +
    'AND FECHA_DESDE_ARQ <= :FECHA AND FECHA_HASTA_ARQ >= :FECHA ' +
    'FOR UPDATE');
  try
    Datos.ParamByName('EMP').AsString := AOperacion.Empresa;
    Datos.ParamByName('ALM').AsString := AOperacion.Almacen;
    Datos.ParamByName('CAJA').AsString := AOperacion.Caja;
    Datos.ParamByName('FECHA').AsDateTime := AFecha;
    Datos.Open;
    if not Datos.IsEmpty then
      raise EInvalidOpException.Create(SErrorCorreccionPagoArqueo);
  finally
    FreeAndNil(Datos);
  end;
end;

procedure TCorreccionPagoUniDAC.BloquearOperacion(
  const AOperacion: TOperacionCorreccionPago);
var
  Datos: TUniQuery;
begin
  Datos := Consulta(
    'SELECT ID_OPCAJA, FECHA_OPERACION_OPCAJA ' +
    'FROM fza_caja_operaciones WHERE CODIGO_EMP_OPCAJA = :EMP ' +
    'AND CODIGO_ALM_OPCAJA = :ALM AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND NUMERO_OPERACION_OPCAJA = :OPE ORDER BY ID_OPCAJA FOR UPDATE');
  try
    ParametrosOperacion(Datos, AOperacion);
    Datos.Open;
    if Datos.IsEmpty then
      raise EInvalidOpException.Create(SErrorCorreccionPagoSeleccion);
    while not Datos.Eof do
    begin
      ComprobarArqueo(AOperacion,
        Datos.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
      Datos.Next;
    end;
  finally
    FreeAndNil(Datos);
  end;
end;

function TCorreccionPagoUniDAC.BloquearCobro(
  const ASolicitud: TSolicitudCorreccionPago;
  out AFormaOrigen: string): Integer;
var
  Datos: TUniQuery;
  Encontrado: Boolean;
begin
  Result := 0;
  Encontrado := False;
  Datos := Consulta(
    'SELECT NUMERO_LINEA_PAGO, NUMERO_LINEA_ORIGEN_PAGO, CODIGO_FP_CFP, '+
    'IMPORTE_ENTREGADO_PAGO > IMPORTE_CAMBIO_PAGO AS POSITIVO, ' +
    'COALESCE(CODIGO_DIVISA_PAGO, ''EUR'') IN ('''', ''EUR'') ' +
    'AND COALESCE(RED_BLOCKCHAIN_PAGO, '''') = '''' ' +
    'AND FACTOR_CAMBIO_PAGO = 1 AND IMPORTE_DIVISA_PAGO = 0 AS EURO ' +
    'FROM fza_caja_pagos WHERE ' + SQL_OPERACION_PAGO +
    'AND SERIE_OPERACION_PAGO = :SERIE ' +
    'ORDER BY NUMERO_LINEA_PAGO FOR UPDATE');
  try
    ParametrosOperacion(Datos, ASolicitud.Operacion);
    Datos.ParamByName('SERIE').AsString := ASolicitud.Serie;
    Datos.Open;
    while not Datos.Eof do
    begin
      if Datos.FieldByName('NUMERO_LINEA_ORIGEN_PAGO').AsInteger =
         ASolicitud.Linea then
        raise EInvalidOpException.Create(SErrorCorreccionPagoYaCorregido);
      Result := Datos.FieldByName('NUMERO_LINEA_PAGO').AsInteger;
      if Result = ASolicitud.Linea then
      begin
        Encontrado := (Datos.FieldByName('POSITIVO').AsInteger = 1) and
          (Datos.FieldByName('EURO').AsInteger = 1);
        AFormaOrigen := Datos.FieldByName('CODIGO_FP_CFP').AsString;
      end;
      Datos.Next;
    end;
    if not Encontrado then
      raise EInvalidOpException.Create(SErrorCorreccionPagoSeleccion);
  finally
    FreeAndNil(Datos);
  end;
end;

procedure TCorreccionPagoUniDAC.ValidarMedio(
  const ASolicitud: TSolicitudCorreccionPago; const AOrigen: string);
var
  Datos: TUniQuery;
begin
  if SameText(AOrigen, ASolicitud.FormaPago) then
    raise EArgumentException.Create(SErrorCorreccionPagoMismoMedio);
  Datos := Consulta(
    'SELECT CODIGO_FP_CFP, ESACTIVO_FORMA_PAGO_CFP, ' +
    'ESREQ_REFERENCIA_FORMA_PAGO_CFP FROM fza_caja_formas_pago WHERE ' +
    SQL_MEDIO_SIMPLE +
    'AND CODIGO_FP_CFP IN (:ORIGEN, :DESTINO) ' +
    'ORDER BY CODIGO_FP_CFP FOR UPDATE');
  try
    Datos.ParamByName('ORIGEN').AsString := AOrigen;
    Datos.ParamByName('DESTINO').AsString := ASolicitud.FormaPago;
    Datos.Open;
    Datos.Last;
    if Datos.RecordCount <> 2 then
      raise EArgumentException.Create(SErrorCorreccionPagoMedio);
    Datos.Locate('CODIGO_FP_CFP', ASolicitud.FormaPago, []);
    if Datos.FieldByName('ESACTIVO_FORMA_PAGO_CFP').AsString <> 'S' then
      raise EArgumentException.Create(SErrorCorreccionPagoMedio);
    if (Datos.FieldByName('ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString =
        'S') and (Trim(ASolicitud.Referencia) = '') then
      raise EArgumentException.Create(SErrorCorreccionPagoReferencia);
  finally
    FreeAndNil(Datos);
  end;
end;

procedure TCorreccionPagoUniDAC.InsertarApunte(
  const ASolicitud: TSolicitudCorreccionPago;
  ALinea: Integer; ACompensacion: Boolean);
var
  Datos: TUniQuery;
  Tipo: string;
begin
  Tipo := 'P';
  if ACompensacion then
    Tipo := 'N';
  Datos := Consulta(
    'INSERT INTO fza_caja_pagos (CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, ' +
    'CODIGO_CAJA_PAGO, SERIE_OPERACION_PAGO, NUMERO_OPERACION_PAGO, ' +
    'NUMERO_LINEA_PAGO, CODIGO_FP_CFP, CODIGO_DIVISA_PAGO, ' +
    'RED_BLOCKCHAIN_PAGO, FACTOR_CAMBIO_PAGO, IMPORTE_DIVISA_PAGO, ' +
    'IMPORTE_ENTREGADO_PAGO, IMPORTE_CAMBIO_PAGO, REFERENCIA_FACPAG, ' +
    'OBSERVACIONES_PAGO, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, ' +
    'NUMERO_LINEA_ORIGEN_PAGO, TIPO_CORRECCION_PAGO) ' +
    'SELECT CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, CODIGO_CAJA_PAGO, ' +
    'SERIE_OPERACION_PAGO, NUMERO_OPERACION_PAGO, :LINEA, ' +
    'IF(:TIPO = ''N'', CODIGO_FP_CFP, :FP), CODIGO_DIVISA_PAGO, ' +
    'RED_BLOCKCHAIN_PAGO, FACTOR_CAMBIO_PAGO, -IMPORTE_DIVISA_PAGO, ' +
    'IF(:TIPO = ''N'', -IMPORTE_ENTREGADO_PAGO, ' +
    'IMPORTE_ENTREGADO_PAGO - IMPORTE_CAMBIO_PAGO), ' +
    'IF(:TIPO = ''N'', -IMPORTE_CAMBIO_PAGO, 0), ' +
    'IF(:TIPO = ''N'', REFERENCIA_FACPAG, :REF), ' +
    ':OBS, NOW(), NOW(), :USUARIO, NUMERO_LINEA_PAGO, :TIPO ' +
    'FROM fza_caja_pagos WHERE ' + SQL_OPERACION_PAGO +
    'AND SERIE_OPERACION_PAGO = :SERIE AND NUMERO_LINEA_PAGO = :ORIGEN');
  try
    ParametrosOperacion(Datos, ASolicitud.Operacion);
    Datos.ParamByName('SERIE').AsString := ASolicitud.Serie;
    Datos.ParamByName('ORIGEN').AsInteger := ASolicitud.Linea;
    Datos.ParamByName('LINEA').AsInteger := ALinea;
    Datos.ParamByName('TIPO').AsString := Tipo;
    Datos.ParamByName('FP').AsString := ASolicitud.FormaPago;
    Datos.ParamByName('REF').AsString := Trim(ASolicitud.Referencia);
    Datos.ParamByName('OBS').AsString := Format(SDetalleCorreccionPago,
      [Tipo, ASolicitud.Linea, Trim(ASolicitud.Motivo)]);
    Datos.ParamByName('USUARIO').AsString := FUsuario;
    Datos.Execute;
    if Datos.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SErrorCorreccionPagoSeleccion);
  finally
    FreeAndNil(Datos);
  end;
end;

procedure TCorreccionPagoUniDAC.Corregir(
  const ASolicitud: TSolicitudCorreccionPago);
var
  UltimaLinea: Integer;
  FormaOrigen: string;
begin
  ValidarSolicitud(ASolicitud);
  ComprobarEsquema;
  if FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorCorreccionPagoTransaccion);
  FConexion.StartTransaction;
  try
    BloquearOperacion(ASolicitud.Operacion);
    UltimaLinea := BloquearCobro(ASolicitud, FormaOrigen);
    ValidarMedio(ASolicitud, FormaOrigen);
    InsertarApunte(ASolicitud, UltimaLinea + 1, True);
    InsertarApunte(ASolicitud, UltimaLinea + 2, False);
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
end;

end.

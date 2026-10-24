{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuSubsanacionRepositorio                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Encola subsanaciones limitadas a registros aceptados con errores.         }
{******************************************************************************}
unit UniDataVerifactuSubsanacionRepositorio;

interface

uses
  Uni, inLibVerifactuSubsanacionIntf;

function CrearServicioVerifactuSubsanacionUniDAC(
  AConexion: TUniConnection): IServicioVerifactuSubsanacion;
function CrearServicioVerifactuCorreccionRegistroUniDAC(
  AConexion: TUniConnection): IServicioVerifactuCorreccionRegistro;

implementation

uses
  System.SysUtils, inLibMsgVerifactu, inLibParametrosIntf,
  inLibVentasWsCola, inLibVerifactu, UniDataVentasWsCola,
  UniDataVerifactuSubsanacionResultados, UniDataVerifactuColaOperaciones,
  UniDataVerifactuColaRepositorio;

type
  TSolicitudEncoladoSubsanacion = record
    Usuario: string;
    Serie: string;
    Numero: string;
    Motivo: string;
    EsCorreccionRegistro: Boolean;
    EsNoVerifactu: Boolean;
  end;
  TServicioVerifactuSubsanacionUniDAC = class(TInterfacedObject,
    IServicioVerifactuSubsanacion, IServicioVerifactuCorreccionRegistro)
  private
    FConexion: TUniConnection;
    function CrearConsulta: TUniQuery;
    procedure BloquearFactura(const AEntrada: TSolicitudEncoladoSubsanacion);
    procedure ValidarRegistro(const AEntrada: TSolicitudEncoladoSubsanacion);
    function BloquearColas(
      const AEntrada: TSolicitudEncoladoSubsanacion): Int64;
    procedure InsertarCola(const AEntrada: TSolicitudEncoladoSubsanacion);
    procedure ReintentarCola(AId: Int64;
      const AEntrada: TSolicitudEncoladoSubsanacion);
    procedure EncolarSolicitud(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AEntrada: TSolicitudEncoladoSubsanacion);
    procedure RegistrarCorreccionNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AEntrada: TSolicitudEncoladoSubsanacion);
  public
    constructor Create(AConexion: TUniConnection);
    procedure Encolar(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
    procedure EncolarCorreccionRegistro(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
  end;

function CrearServicioVerifactuSubsanacionUniDAC(
  AConexion: TUniConnection): IServicioVerifactuSubsanacion;
begin
  Result := TServicioVerifactuSubsanacionUniDAC.Create(AConexion);
end;

function CrearServicioVerifactuCorreccionRegistroUniDAC(
  AConexion: TUniConnection): IServicioVerifactuCorreccionRegistro;
begin
  Result := TServicioVerifactuSubsanacionUniDAC.Create(AConexion);
end;

constructor TServicioVerifactuSubsanacionUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TServicioVerifactuSubsanacionUniDAC.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TServicioVerifactuSubsanacionUniDAC.BloquearFactura(
  const AEntrada: TSolicitudEncoladoSubsanacion);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT SERIE_FAC FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oConsulta.Open;
    if oConsulta.Eof then
      raise EArgumentException.Create(SErrorSubsanacionRegistroNoVigente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioVerifactuSubsanacionUniDAC.ValidarRegistro(
  const AEntrada: TSolicitudEncoladoSubsanacion);
var
  oConsulta: TUniQuery;
  sEstado: string;
  bAceptado: Boolean;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT ESTADO_FACCON, CHAIN_HASH_FACCON ' +
      ' FROM fza_facturas_consolidaciones ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO ' +
      ' ORDER BY ID_FACCON DESC LIMIT 1 FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oConsulta.Open;
    bAceptado := not oConsulta.Eof;
    if bAceptado then
    begin
      sEstado := oConsulta.FieldByName('ESTADO_FACCON').AsString;
      bAceptado := sEstado = 'VERIFACTU_ACEPT_ERR';
      if AEntrada.EsNoVerifactu then
        bAceptado := (sEstado = 'NOVERIF_REGISTRADO') or
          (sEstado = 'NOVERIF_SUBSANADO')
      else if AEntrada.EsCorreccionRegistro then
        bAceptado := bAceptado or (sEstado = 'VERIFACTU_PROCESADO') or
          (sEstado = 'VERIFACTU_DUPLICADO') or
          (sEstado = 'VERIFACTU_SUBSANADO') or (sEstado = 'VERIFACTU_OK');
      // El SII no encadena: no hay huella que exigir (FZ-ISSUE-292)
      if Copy(sEstado, 1, 4) = 'SII_' then
        bAceptado := (sEstado = 'SII_ACEPT_ERR') or
          (AEntrada.EsCorreccionRegistro and EsEstadoSiiAceptado(sEstado))
      else
        bAceptado := bAceptado and
          (Trim(oConsulta.FieldByName('CHAIN_HASH_FACCON').AsString) <> '');
    end;
    if not bAceptado then
      raise EArgumentException.Create(SErrorSubsanacionRegistroNoVigente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioVerifactuSubsanacionUniDAC.BloquearColas(
  const AEntrada: TSolicitudEncoladoSubsanacion): Int64;
var
  oConsulta: TUniQuery;
  bReintento: Boolean;
begin
  Result := 0;
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT ID_VFCOLA, TIPO_OPERACION_VFCOLA, ESTADO_VFCOLA ' +
      ' FROM fza_verifactu_cola ' +
      ' WHERE SERIE_FAC_VFCOLA = :SERIE ' +
      '   AND NUMERO_FAC_VFCOLA = :NUMERO ' +
      ' ORDER BY ID_VFCOLA FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if oConsulta.FieldByName('TIPO_OPERACION_VFCOLA').AsString =
         'ANULACION' then
        raise EArgumentException.Create(SErrorSubsanacionRegistroNoVigente);
      bReintento := not AEntrada.EsCorreccionRegistro and
        (oConsulta.FieldByName('TIPO_OPERACION_VFCOLA').AsString =
         'SUBSANACION') and
        (oConsulta.FieldByName('ESTADO_VFCOLA').AsString = 'ERROR') and
        (Result = 0);
      if bReintento then
        Result := oConsulta.FieldByName('ID_VFCOLA').AsLargeInt
      else if oConsulta.FieldByName('ESTADO_VFCOLA').AsString <> 'ENVIADA' then
        raise EArgumentException.Create(SErrorSubsanacionColaActiva);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioVerifactuSubsanacionUniDAC.InsertarCola(
  const AEntrada: TSolicitudEncoladoSubsanacion);
var
  oConsulta: TUniQuery;
  bSistema: Boolean;
  sColumna: string;
  sValor: string;
begin
  // La subsanación va por el sistema del alta: en el SII es una
  // modificación (A1); sin la columna todo es VERI*FACTU (FZ-ISSUE-292)
  bSistema := ColaVerifactuTieneSistema(FConexion);
  sColumna := '';
  sValor := '';
  if bSistema then
  begin
    sColumna := ', SISTEMA_VFCOLA';
    sValor := ', :SISTEMA';
  end;
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      ' INSERT INTO fza_verifactu_cola ' +
      ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA, ' +
      '  ORDEN_SUBSANACION_VFCOLA, ESTADO_VFCOLA, ' +
      '  CONTADOR_INTENTOS_VFCOLA, MOTIVO_VFCOLA, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA' + sColumna + ') ' +
      ' SELECT :SERIE, :NUMERO, ''SUBSANACION'', ' +
      '        IFNULL(MAX(ORDEN_SUBSANACION_VFCOLA), 0) + 1, ' +
      '        ''PENDIENTE'', 0, :MOTIVO, NOW(), :USUARIO' + sValor + ' ' +
      ' FROM fza_verifactu_cola ' +
      ' WHERE SERIE_FAC_VFCOLA = :SERIE ' +
      '   AND NUMERO_FAC_VFCOLA = :NUMERO ' +
      '   AND TIPO_OPERACION_VFCOLA = ''SUBSANACION''';
    oConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oConsulta.ParamByName('MOTIVO').AsString := AEntrada.Motivo;
    oConsulta.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    if bSistema then
      oConsulta.ParamByName('SISTEMA').AsString := SistemaColaAltaFactura(
        FConexion, AEntrada.Serie, AEntrada.Numero, cSistemaColaVerifactu);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioVerifactuSubsanacionUniDAC.ReintentarCola(
  AId: Int64; const AEntrada: TSolicitudEncoladoSubsanacion);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      ' UPDATE fza_verifactu_cola SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
      ' CONTADOR_INTENTOS_VFCOLA = 0, MOTIVO_VFCOLA = :MOTIVO, ' +
      ' INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
      ' MENSAJE_ERROR_VFCOLA = NULL, INSTANTE_MODIF = NOW(), ' +
      ' USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID AND ESTADO_VFCOLA = ''ERROR''';
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ParamByName('MOTIVO').AsString := AEntrada.Motivo;
    oConsulta.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SErrorSubsanacionColaActiva);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioVerifactuSubsanacionUniDAC.EncolarSolicitud(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AEntrada: TSolicitudEncoladoSubsanacion);
var
  bTransaccionPropia: Boolean;
  iReintento: Int64;
  oContexto: TContextoSubsanacionFiscal;
begin
  if AEntrada.Motivo = '' then
    raise EArgumentException.Create(SErrorIncidenciaMotivoObligatorio);
  if AEntrada.EsCorreccionRegistro and not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorSubsanacionTransaccion);
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    BloquearFactura(AEntrada);
    ValidarRegistro(AEntrada);
    iReintento := BloquearColas(AEntrada);
    ValidarRequisitosFiscalesEmision(AParametrosApp, FConexion,
      AEntrada.Serie, AEntrada.Numero);
    oContexto := Default(TContextoSubsanacionFiscal);
    oContexto.Serie := AEntrada.Serie;
    oContexto.Numero := AEntrada.Numero;
    oContexto.Usuario := AEntrada.Usuario;
    ConservarHistorialSubsanacion(FConexion, oContexto);
    if iReintento = 0 then
      InsertarCola(AEntrada)
    else
      ReintentarCola(iReintento, AEntrada);
    TVentasWsCola.RegistrarFactura(AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(FConexion), AEntrada.Usuario,
      AEntrada.Serie, AEntrada.Numero, 'SUBSANACION');
    if bTransaccionPropia then
      FConexion.Commit;
  except
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TServicioVerifactuSubsanacionUniDAC.Encolar(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, AMotivo: string);
var
  oEntrada: TSolicitudEncoladoSubsanacion;
begin
  oEntrada := Default(TSolicitudEncoladoSubsanacion);
  oEntrada.Usuario := AUsuario;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.Motivo := Trim(AMotivo);
  EncolarSolicitud(AParametrosApp, AParametrosCaja, oEntrada);
end;

procedure TServicioVerifactuSubsanacionUniDAC.EncolarCorreccionRegistro(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, AMotivo: string);
var
  oEntrada: TSolicitudEncoladoSubsanacion;
begin
  oEntrada := Default(TSolicitudEncoladoSubsanacion);
  oEntrada.Usuario := AUsuario;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.Motivo := Trim(AMotivo);
  oEntrada.EsCorreccionRegistro := True;
  oEntrada.EsNoVerifactu := NoVerifactuActivo(AParametrosApp);
  if oEntrada.EsNoVerifactu then
    RegistrarCorreccionNoVerifactu(AParametrosApp, AParametrosCaja, oEntrada)
  else
    EncolarSolicitud(AParametrosApp, AParametrosCaja, oEntrada);
end;

procedure TServicioVerifactuSubsanacionUniDAC.RegistrarCorreccionNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AEntrada: TSolicitudEncoladoSubsanacion);
var
  oConsulta: TUniQuery;
begin
  // NO VERI*FACTU no envía a la AEAT: firma y encadena un nuevo registro de
  // subsanación y lo anota en el registro de eventos, en la misma transacción.
  if AEntrada.Motivo = '' then
    raise EArgumentException.Create(SErrorIncidenciaMotivoObligatorio);
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorSubsanacionTransaccion);
  BloquearFactura(AEntrada);
  ValidarRegistro(AEntrada);
  BloquearColas(AEntrada);
  oConsulta := CrearConsulta;
  try
    TOperacionesVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
      AParametrosApp, AParametrosCaja, oConsulta, AEntrada.Usuario,
      AEntrada.Serie, AEntrada.Numero, 'SUBSANACION', False, nil);
  finally
    FreeAndNil(oConsulta);
  end;
  RegistrarEventoVerifactu(AParametrosApp, FConexion, AEntrada.Usuario,
    cEventoVerifactuInfo, SInfoSubsanacionNoVerifactuRegistrada,
    Format(SInfoSubsanacionNoVerifactuMotivo, [AEntrada.Motivo]),
    AEntrada.Serie, AEntrada.Numero);
end;

end.

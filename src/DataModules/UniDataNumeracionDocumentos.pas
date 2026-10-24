{******************************************************************************}
{  Módulo: UniDataNumeracionDocumentos                                         }
{  Fecha: 03/10/2026                                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Recuperación confirmada de contadores atrasados, sin consumir números.      }
{******************************************************************************}
unit UniDataNumeracionDocumentos;

interface

uses
  System.SysUtils, System.Classes, Uni, inLibLogIntf;

type
  ERecuperacionNumeracion = class(Exception);
  TDocumentoNumeracion = (dnFactura, dnAlbaranVenta, dnAlbaranCompra);
  ERecuperacionNumeracionPendiente = class(ERecuperacionNumeracion)
  private
    FRecuperar: TProc;
  public
    constructor Create(const AMensaje: string;
      const ARecuperar: TProc); reintroduce;
    procedure Recuperar;
  end;

// Se invoca antes de empezar la escritura. Cancelar conserva el documento.
procedure PrepararNumeracionDocumento(AConexion: TUniConnection;
  ADocumento: TDocumentoNumeracion; const AEmpresa, ASerie, AUsuario: string;
  var ANumeroManual: string; const ARegistroLog: IRegistroLog;
  const AConfirmar: TFunc<string, Boolean>);

// El llamador revierte la escritura y restaura la entrada antes de reparar.
function EjecutarConRecuperacionNumeracion(AConexion: TUniConnection;
  const ATrabajo, ARestaurar: TProc): Boolean;
procedure GuardarConRecuperacionNumeracion(AConexion: TUniConnection;
  AModulo: TDataModule; const ATrabajo: TProc);
procedure EjecutarConEsperaBloqueoCorta(AConexion: TUniConnection;
  const ATrabajo: TProc; const ARegistroLog: IRegistroLog);

implementation

uses
  Data.DB, inLibMsgVentas, inLibDatasets;

type
  TEsquemaNumeracion = record
    Tabla, Serie, Numero, TipoContador: string;
  end;

constructor ERecuperacionNumeracionPendiente.Create(
  const AMensaje: string; const ARecuperar: TProc);
begin
  inherited Create(AMensaje);
  FRecuperar := ARecuperar;
end;

procedure ERecuperacionNumeracionPendiente.Recuperar;
begin
  FRecuperar();
end;

function EjecutarConRecuperacionNumeracion(AConexion: TUniConnection;
  const ATrabajo, ARestaurar: TProc): Boolean;
var
  Repetir, Exterior: Boolean;
begin
  Exterior := AConexion.InTransaction;
  Result := False;
  repeat
    Repetir := False;
    try
      ATrabajo();
      Result := True;
    except
      on E: ERecuperacionNumeracionPendiente do
      begin
        if Exterior or AConexion.InTransaction then
          raise;
        ARestaurar();
        try
          E.Recuperar;
          Repetir := True;
        except
          on EAbort do
            Result := False;
        end;
      end;
    end;
  until not Repetir;
end;

procedure GuardarConRecuperacionNumeracion(AConexion: TUniConnection;
  AModulo: TDataModule; const ATrabajo: TProc);
var
  Ediciones: TEdicionesDataSetsPendientes;
begin
  Ediciones := CapturarEdicionesDataSets(AModulo);
  if not EjecutarConRecuperacionNumeracion(AConexion, ATrabajo,
    procedure
    begin
      RestaurarEdicionesDataSets(Ediciones);
    end) then
    Abort;
end;

procedure EjecutarConEsperaBloqueoCorta(AConexion: TUniConnection;
  const ATrabajo: TProc; const ARegistroLog: IRegistroLog);
var
  Consulta: TUniQuery;
  Espera: Integer;
begin
  if ARegistroLog = nil then
    raise EArgumentNilException.Create('ARegistroLog');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT @@SESSION.innodb_lock_wait_timeout AS ESPERA';
    Consulta.Open;
    Espera := Consulta.FieldByName('ESPERA').AsInteger;
    Consulta.Close;
    if Espera > 5 then
      AConexion.ExecSQL('SET SESSION innodb_lock_wait_timeout = 5');
    try
      ATrabajo();
    finally
      if (Espera > 5) and AConexion.Connected then
      begin
        try
          AConexion.ExecSQL(
            'SET SESSION innodb_lock_wait_timeout = :ESPERA', [Espera]);
        except
          on E: Exception do
            ARegistroLog.RegistrarAviso(
              'No se restauró la espera de bloqueo: ' + E.Message);
        end;
      end;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function EsquemaNumeracion(ADocumento: TDocumentoNumeracion):
  TEsquemaNumeracion;
begin
  case ADocumento of
    dnFactura:
      begin
        Result.Tabla := 'fza_facturas';
        Result.Serie := 'SERIE_FAC';
        Result.Numero := 'NUMERO_FAC';
        Result.TipoContador := 'FC';
      end;
    dnAlbaranVenta:
      begin
        Result.Tabla := 'fza_albaranes';
        Result.Serie := 'SERIE_ALB';
        Result.Numero := 'NUMERO_ALB';
        Result.TipoContador := 'AV';
      end;
    dnAlbaranCompra:
      begin
        Result.Tabla := 'fza_albaranes_compra';
        Result.Serie := 'SERIE_ALBC';
        Result.Numero := 'NUMERO_ALBC';
        Result.TipoContador := 'AB';
      end;
  end;
end;

function FormatearNumero(ANumero: Int64; ADigitos: Integer): string;
begin
  Result := IntToStr(ANumero);
  if (ADigitos > Length(Result)) and (ADigitos <= 20) then
    Result := StringOfChar('0', ADigitos - Length(Result)) + Result;
end;

procedure ParametrosContador(AConsulta: TUniQuery;
  const AEsquema: TEsquemaNumeracion; const AEmpresa, ASerie: string);
begin
  AConsulta.ParamByName('TIPO').AsString := AEsquema.TipoContador;
  if Trim(AEmpresa) = '' then
    AConsulta.ParamByName('EMPRESA').AsString := '-'
  else
    AConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
end;

procedure LeerContador(AConsulta: TUniQuery;
  const AEsquema: TEsquemaNumeracion; const AEmpresa, ASerie: string;
  ABloquear: Boolean; out AValor: Int64; out ADigitos: Integer);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT CON, NUM_DIGITOS_CON, ESACTIVO_CON FROM fza_contadores ' +
    'WHERE TIPO_DOC_CON = :TIPO AND EMPRESA_CON = :EMPRESA ' +
    'AND SERIE_CON = :SERIE';
  if ABloquear then
    AConsulta.SQL.Add('FOR UPDATE');
  ParametrosContador(AConsulta, AEsquema, AEmpresa, ASerie);
  AConsulta.Open;
  AValor := 1;
  ADigitos := 6;
  if not AConsulta.IsEmpty then
  begin
    AValor := AConsulta.FieldByName('CON').AsLargeInt;
    ADigitos := AConsulta.FieldByName('NUM_DIGITOS_CON').AsInteger;
  end;
  if AValor < 1 then
    AValor := 1;
end;

function NumeroExiste(AConsulta: TUniQuery;
  const AEsquema: TEsquemaNumeracion; const ASerie, ANumero: string): Boolean;
begin
  AConsulta.Close;
  AConsulta.SQL.Text := 'SELECT 1 FROM ' + AEsquema.Tabla +
    ' WHERE ' + AEsquema.Serie + ' = :SERIE AND ' +
    AEsquema.Numero + ' = :NUMERO LIMIT 1';
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  Result := not AConsulta.IsEmpty;
end;

function UltimoNumero(AConsulta: TUniQuery;
  const AEsquema: TEsquemaNumeracion; const ASerie: string): Int64;
begin
  AConsulta.Close;
  // La PK es serie/número, incluso si hay documentos de varias empresas.
  // Solo los números enteros participan en MAX; no se truncan prefijos.
  AConsulta.SQL.Text := 'SELECT COALESCE(MAX(CAST(' + AEsquema.Numero +
    ' AS UNSIGNED)), 0) AS ULTIMO FROM ' + AEsquema.Tabla +
    ' WHERE ' + AEsquema.Serie + ' = :SERIE AND ' + AEsquema.Numero +
    ' REGEXP ''^[0-9]{1,18}$''';
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.Open;
  Result := AConsulta.FieldByName('ULTIMO').AsLargeInt;
end;

procedure AvanzarContador(AConsulta: TUniQuery;
  const AEsquema: TEsquemaNumeracion; const AEmpresa, ASerie,
  AUsuario: string; const ARegistroLog: IRegistroLog;
  AMinimo: Int64 = 0);
var
  Anterior, Nuevo: Int64;
  Digitos: Integer;
  Propia: Boolean;
begin
  Propia := not AConsulta.Connection.InTransaction;
  if Propia then
    AConsulta.Connection.StartTransaction;
  try
    LeerContador(AConsulta, AEsquema, AEmpresa, ASerie, True,
      Anterior, Digitos);
    if AConsulta.IsEmpty or
       (not SameText(AConsulta.FieldByName('ESACTIVO_CON').AsString, 'S')) then
      raise ERecuperacionNumeracion.Create(SErrorContadorNumeracionNoActivo);
    Nuevo := UltimoNumero(AConsulta, AEsquema, ASerie) + 1;
    if Nuevo < AMinimo then
      Nuevo := AMinimo;
    // Otro puesto puede haber reparado o reservado mientras se confirmaba.
    if Nuevo < Anterior then
      Nuevo := Anterior;
    AConsulta.Close;
    AConsulta.SQL.Text :=
      'UPDATE fza_contadores SET CON = :NUEVO, ' +
      'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
      'WHERE TIPO_DOC_CON = :TIPO AND EMPRESA_CON = :EMPRESA ' +
      'AND SERIE_CON = :SERIE';
    ParametrosContador(AConsulta, AEsquema, AEmpresa, ASerie);
    AConsulta.ParamByName('NUEVO').AsLargeInt := Nuevo;
    AConsulta.ParamByName('USUARIO').AsString := AUsuario;
    AConsulta.Execute;
    if Propia then
      AConsulta.Connection.Commit;
  except
    if Propia and AConsulta.Connection.InTransaction then
      AConsulta.Connection.Rollback;
    raise;
  end;
  if Propia then
    ARegistroLog.RegistrarInformacion(Format(
    'Contador corregido: tipo=%s empresa=%s serie=%s anterior=%d ' +
    'nuevo=%d usuario=%s',
    [AEsquema.TipoContador, AEmpresa, ASerie, Anterior, Nuevo, AUsuario]));
end;

procedure PrepararNumeracionDocumento(AConexion: TUniConnection;
  ADocumento: TDocumentoNumeracion; const AEmpresa, ASerie, AUsuario: string;
  var ANumeroManual: string; const ARegistroLog: IRegistroLog;
  const AConfirmar: TFunc<string, Boolean>);
var
  Consulta: TUniQuery;
  Esquema: TEsquemaNumeracion;
  Valor, Ultimo, Manual: Int64;
  Digitos: Integer;
  Numero, Mensaje: string;
  ContadorActivo: Boolean;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if ARegistroLog = nil then
    raise EArgumentNilException.Create('ARegistroLog');
  Esquema := EsquemaNumeracion(ADocumento);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    LeerContador(Consulta, Esquema, AEmpresa, ASerie, False,
      Valor, Digitos);
    // FZ-170: el contador ausente/inactivo se trata al reservar, con
    // permiso de administrador. El avance no debe crearlo por su cuenta.
    ContadorActivo := not Consulta.IsEmpty and
      SameText(Consulta.FieldByName('ESACTIVO_CON').AsString, 'S');
    Numero := Trim(ANumeroManual);
    if Numero = '' then
      Numero := FormatearNumero(Valor, Digitos)
    else if TryStrToInt64(Numero, Manual) and (Manual >= 0) then
      Numero := FormatearNumero(Manual, Digitos);
    if ((Trim(ANumeroManual) <> '') or ContadorActivo) and
       NumeroExiste(Consulta, Esquema, ASerie, Numero) then
    begin
      Ultimo := UltimoNumero(Consulta, Esquema, ASerie);
      if Trim(ANumeroManual) = '' then
        Mensaje := Format(SConfirmarAvanceContadorDocumento,
          [ASerie, Numero, FormatearNumero(Ultimo, Digitos)])
      else
        Mensaje := Format(SConfirmarNumeroManualDocumento,
          [ASerie, Numero, FormatearNumero(Ultimo + 1, Digitos)]);
      if not Assigned(AConfirmar) then
        raise ERecuperacionNumeracion.Create(Mensaje);
      if (Trim(ANumeroManual) = '') and AConexion.InTransaction then
        raise ERecuperacionNumeracionPendiente.Create(Mensaje,
          procedure
          var
            Automatico: string;
          begin
            Automatico := '';
            PrepararNumeracionDocumento(AConexion, ADocumento,
              AEmpresa, ASerie, AUsuario, Automatico,
              ARegistroLog, AConfirmar);
          end);
      if not AConfirmar(Mensaje) then
        Abort;
      if Trim(ANumeroManual) = '' then
        AvanzarContador(Consulta, Esquema, AEmpresa, ASerie,
          AUsuario, ARegistroLog)
      else
      begin
        // La revalidación pide evitar que el siguiente automático choque
        // con el número propuesto. El ajuste acompaña a la transacción
        // de escritura si ya existe y nunca retrocede el contador.
        if ContadorActivo then
          AvanzarContador(Consulta, Esquema, AEmpresa, ASerie,
            AUsuario, ARegistroLog, Ultimo + 2);
        ANumeroManual := FormatearNumero(Ultimo + 1, Digitos);
      end;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

end.

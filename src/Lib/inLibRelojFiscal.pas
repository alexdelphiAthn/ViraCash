{******************************************************************************}
{                                                                              }
{  Modulo:       inLibRelojFiscal                                             }
{    Tipo:       Libreria                                                      }
{   Fecha:       15/06/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Control de exactitud del reloj para registros fiscales NO VERI*FACTU.     }
{******************************************************************************}
unit inLibRelojFiscal;

interface

uses
  System.SysUtils, inLibParametrosIntf;

type
  TResultadoRelojFiscal = record
    Ok:                 Boolean;
    Servidor:           string;
    HoraSistema:        TDateTime;
    HoraNtp:            TDateTime;
    DiferenciaSegundos: Integer;
    MargenSegundos:     Integer;
    Mensaje:            string;
  end;

function ComprobarRelojFiscal(
  const AParametrosApp: IParametrosAplicacion;
  out AResultado: TResultadoRelojFiscal):
  Boolean;
procedure ExigirRelojFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AContexto: string = '');

implementation

uses
  System.Classes, System.DateUtils, System.StrUtils,
  IdSNTP, inLibMsgVerifactu;

const
  cServidoresNtpDefecto = 'time.google.com,time.windows.com,pool.ntp.org';
  cMargenLegalSegundos = 60;
  cTimeoutDefectoMs = 1500;

procedure InicializarResultado(var AResultado: TResultadoRelojFiscal);
begin
  AResultado.Ok := False;
  AResultado.Servidor := '';
  AResultado.HoraSistema := Now;
  AResultado.HoraNtp := 0;
  AResultado.DiferenciaSegundos := 0;
  AResultado.MargenSegundos := cMargenLegalSegundos;
  AResultado.Mensaje := '';
end;

function ListaServidoresNtp(
  const AParametrosApp: IParametrosAplicacion): TStringList;
var
  sServidores: string;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  Result.Delimiter := ',';
  sServidores := AParametrosApp.GetString(
    'appVerifactuNtpServidores',
    cServidoresNtpDefecto);
  sServidores := StringReplace(sServidores, ';', ',', [rfReplaceAll]);
  Result.DelimitedText := sServidores;
end;

function MargenSegundos(
  const AParametrosApp: IParametrosAplicacion): Integer;
begin
  Result := AParametrosApp.GetInt(
    'appVerifactuNtpMargenSegundos',
    cMargenLegalSegundos);
  if Result <= 0 then
    Result := cMargenLegalSegundos;
  if Result > cMargenLegalSegundos then
    Result := cMargenLegalSegundos;
end;

function TimeoutNtpMs(
  const AParametrosApp: IParametrosAplicacion): Integer;
begin
  Result := AParametrosApp.GetInt(
    'appVerifactuNtpTimeoutMs',
    cTimeoutDefectoMs);
  if Result < 250 then
    Result := 250;
  if Result > 10000 then
    Result := 10000;
end;

function ComprobarServidorNtp(const AServidor: string; ATimeoutMs: Integer;
                              out AHoraNtp: TDateTime;
                              out ADiferencia: Integer;
                              out AMensajeError: string): Boolean;
var
  Ntp: TIdSNTP;
  dHoraSistema: TDateTime;
begin
  Result := False;
  AHoraNtp := 0;
  ADiferencia := 0;
  AMensajeError := '';
  Ntp := TIdSNTP.Create(nil);
  try
    Ntp.Host := Trim(AServidor);
    Ntp.ReceiveTimeout := ATimeoutMs;
    Ntp.CheckStratum := True;
    try
      dHoraSistema := Now;
      AHoraNtp := Ntp.DateTime;
      if AHoraNtp = 0 then
        AMensajeError := SErrorRespuestaNtpNoValida
      else
      begin
        ADiferencia := Round((AHoraNtp - dHoraSistema) * SecsPerDay);
        Result := True;
      end;
    except
      on E: Exception do
      begin
        AMensajeError := E.Message;
      end;
    end;
  finally
    FreeAndNil(Ntp);
  end;
end;

function ComprobarRelojFiscal(
  const AParametrosApp: IParametrosAplicacion;
  out AResultado: TResultadoRelojFiscal):
  Boolean;
var
  Servidores: TStringList;
  i: Integer;
  bComprobado: Boolean;
  iMargen: Integer;
  iTimeout: Integer;
  iDiferencia: Integer;
  sServidor: string;
  sErrores: string;
  sError: string;
  dHoraNtp: TDateTime;
begin
  InicializarResultado(AResultado);
  iMargen := MargenSegundos(AParametrosApp);
  iTimeout := TimeoutNtpMs(AParametrosApp);
  AResultado.MargenSegundos := iMargen;
  Servidores := ListaServidoresNtp(AParametrosApp);
  try
    Result := False;
    bComprobado := False;
    sErrores := '';
    i := 0;
    while (i < Servidores.Count) and (not bComprobado) do
    begin
      sServidor := Trim(Servidores[i]);
      if sServidor <> '' then
      begin
        if ComprobarServidorNtp(sServidor, iTimeout, dHoraNtp,
                                iDiferencia, sError) then
        begin
          AResultado.Servidor := sServidor;
          AResultado.HoraSistema := Now;
          AResultado.HoraNtp := dHoraNtp;
          AResultado.DiferenciaSegundos := iDiferencia;
          AResultado.Ok := Abs(iDiferencia) <= iMargen;
          if AResultado.Ok then
            AResultado.Mensaje := Format(
              SInfoRelojFiscalCorrecto,
              [sServidor, iDiferencia])
          else
            AResultado.Mensaje := Format(
              SErrorRelojSistemaFueraMargenLegal,
              [sServidor, iDiferencia, iMargen]);
          Result := AResultado.Ok;
          bComprobado := True;
        end
        else
        begin
          if sErrores <> '' then
            sErrores := sErrores + ' | ';
          sErrores := sErrores + sServidor + ': ' + sError;
        end;
      end;
      Inc(i);
    end;
    if not bComprobado then
    begin
      AResultado.Mensaje := SErrorComprobarRelojFiscalNtp;
      if sErrores <> '' then
        AResultado.Mensaje := AResultado.Mensaje + ' ' + sErrores;
      Result := False;
    end;
  finally
    FreeAndNil(Servidores);
  end;
end;

procedure ExigirRelojFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AContexto: string);
var
  oResultado: TResultadoRelojFiscal;
  sMensaje: string;
begin
  if not ComprobarRelojFiscal(AParametrosApp, oResultado) then
  begin
    sMensaje := oResultado.Mensaje;
    if Trim(AContexto) <> '' then
      sMensaje := AContexto + ': ' + sMensaje;
    raise Exception.Create(sMensaje);
  end;
end;

end.

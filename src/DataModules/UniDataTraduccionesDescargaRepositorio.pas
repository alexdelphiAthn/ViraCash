{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraduccionesDescargaRepositorio                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para instalar paquetes de traducción.                    }
{******************************************************************************}
unit UniDataTraduccionesDescargaRepositorio;

interface

uses
  Uni,
  inLibTraduccionesDescargaPersistenciaIntf;

type
  TInstaladorTraduccionesUniDAC = class(
    TInterfacedObject,
    IInstaladorTraduccionesPersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure ComprobarDisponible;
    function DisponibleLocalmente(const AIdioma: string): Boolean;
    procedure Instalar(
      const AIdioma: string;
      const AScripts: TArray<TScriptInstalacionTraduccion>;
      AProgreso: TProgresoDescargaTraduccion);
  end;

implementation

uses
  System.SysUtils,
  UniScript,
  inLibMsgIntegraciones;

procedure NotificarProgreso(
  const AProgreso: TProgresoDescargaTraduccion;
  const ATexto: string;
  APosicion: Integer);
begin
  if Assigned(AProgreso) then
    AProgreso(ATexto, APosicion);
end;

constructor TInstaladorTraduccionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TInstaladorTraduccionesUniDAC.ComprobarDisponible;
begin
  if not Assigned(FConexion) or not FConexion.Connected then
    raise Exception.Create(SErrorConexionTraduccionNoDisponible);
  if FConexion.InTransaction then
    raise Exception.Create(SErrorTraduccionTransaccionActiva);
end;

function TInstaladorTraduccionesUniDAC.DisponibleLocalmente(
  const AIdioma: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS TOTAL ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_traducciones'' ' +
        '   AND COLUMN_NAME = ''ESDESCARGADA_TRAD''';
      oConsulta.Open;
      if oConsulta.FieldByName('TOTAL').AsInteger > 0 then
      begin
        oConsulta.Close;
        oConsulta.SQL.Text :=
          'SELECT COUNT(*) AS TOTAL ' +
          '  FROM fza_traducciones ' +
          ' WHERE IDIOMA_TRAD = :IDIOMA ' +
          '   AND ESDESCARGADA_TRAD = ''S''';
        oConsulta.ParamByName('IDIOMA').AsString := AIdioma;
        oConsulta.Open;
        Result := oConsulta.FieldByName('TOTAL').AsInteger > 0;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TInstaladorTraduccionesUniDAC.Instalar(
  const AIdioma: string;
  const AScripts: TArray<TScriptInstalacionTraduccion>;
  AProgreso: TProgresoDescargaTraduccion);
var
  bTransaccionIniciada: Boolean;
  iProgreso: Integer;
  iScript: Integer;
  oConsulta: TUniQuery;
  oScript: TUniScript;
begin
  ComprobarDisponible;
  bTransaccionIniciada := False;
  try
    for iScript := 0 to High(AScripts) do
    begin
      if iScript = 1 then
      begin
        FConexion.StartTransaction;
        bTransaccionIniciada := True;
      end;
      iProgreso := 45 +
        ((iScript * 40) div Length(AScripts));
      NotificarProgreso(
        AProgreso,
        Format(
          SProgresoTraduccionEjecutando,
          [AScripts[iScript].Nombre,
           iScript + 1,
           Length(AScripts)]),
        iProgreso);
      oScript := TUniScript.Create(nil);
      try
        oScript.Connection := FConexion;
        oScript.NoPreconnect := True;
        oScript.SQL.Text := AScripts[iScript].Contenido;
        oScript.Execute;
      finally
        FreeAndNil(oScript);
      end;
    end;
    NotificarProgreso(
      AProgreso,
      SProgresoTraduccionComprobando,
      90);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS TOTAL ' +
        '  FROM fza_traducciones ' +
        ' WHERE IDIOMA_TRAD = :IDIOMA ' +
        '   AND ESDESCARGADA_TRAD = ''S''';
      oConsulta.ParamByName('IDIOMA').AsString := AIdioma;
      oConsulta.Open;
      if oConsulta.FieldByName('TOTAL').AsInteger = 0 then
        raise Exception.CreateFmt(
          SErrorTraduccionSinFilas,
          [AIdioma]);
    finally
      FreeAndNil(oConsulta);
    end;
    if bTransaccionIniciada and FConexion.InTransaction then
      FConexion.Commit;
  except
    if bTransaccionIniciada and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

end.

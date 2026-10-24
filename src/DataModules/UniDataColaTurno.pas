{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColaTurno                                              }
{    Tipo:       Composición de persistencia                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Turno de cola apoyado en los bloqueos de consejo del motor.               }
{******************************************************************************}
unit UniDataColaTurno;

interface

uses
  Uni, inLibColaTurnoIntf, inLibLogIntf;

{ Turno apoyado en los bloqueos de consejo del motor (GET_LOCK).
  El bloqueo pertenece a la conexión: si el puesto se cae o pierde la red, el
  motor lo suelta solo y no hay nada que rescatar. Por eso la conexión que se
  pasa debe ser la propia del hilo de la cola, nunca una compartida.
  El turno alcanza a todas las máquinas contra la misma base de datos, que es
  justo lo que hace falta con varias sesiones en un servidor de terminales.
  Si el motor no sabe repartir el turno, el turno se concede y queda anotado:
  una cola no puede pararse por no poder repartirlo. }
function CrearTurnoColaUniDAC(
  AConexion: TUniConnection;
  const ANombre: string;
  const ARegistroLog: IRegistroLog = nil): ITurnoCola;

implementation

uses
  System.SysUtils, inLibMsgColaTurno;

type
  TTurnoColaUniDAC = class(TInterfacedObject, ITurnoCola)
  private
    FConexion: TUniConnection;
    FNombre: string;
    FRegistroLog: IRegistroLog;
    FEnPosesion: Boolean;
    FAvisoFallo: Boolean;
    function ExpresionNombre: string;
    procedure Anotar(const AMensaje: string);
  public
    constructor Create(AConexion: TUniConnection;
                       const ANombre: string;
                       const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    function Intentar: Boolean;
    procedure Liberar;
  end;

function NombreValido(const ANombre: string): Boolean;
var
  iCar: Integer;
begin
  Result := (ANombre <> '') and (Length(ANombre) <= 16);
  iCar := 1;
  while Result and (iCar <= Length(ANombre)) do
  begin
    Result := CharInSet(ANombre[iCar],
                        ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    Inc(iCar);
  end;
end;

function CrearTurnoColaUniDAC(
  AConexion: TUniConnection;
  const ANombre: string;
  const ARegistroLog: IRegistroLog): ITurnoCola;
begin
  Result := TTurnoColaUniDAC.Create(AConexion, ANombre, ARegistroLog);
end;

constructor TTurnoColaUniDAC.Create(AConexion: TUniConnection;
                                    const ANombre: string;
                                    const ARegistroLog: IRegistroLog);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  // El nombre viaja dentro del SQL: solo se admite lo que no puede salirse
  // de una literal
  if not NombreValido(ANombre) then
    raise EArgumentException.CreateFmt(
      SErrorNombreTurnoColaNoValido, [ANombre]);
  inherited Create;
  FConexion := AConexion;
  FNombre := ANombre;
  FRegistroLog := ARegistroLog;
  FEnPosesion := False;
  FAvisoFallo := False;
end;

destructor TTurnoColaUniDAC.Destroy;
begin
  Liberar;
  FRegistroLog := nil;
  FConexion := nil;
  inherited;
end;

procedure TTurnoColaUniDAC.Anotar(const AMensaje: string);
begin
  // Un solo aviso por turno: si el motor no reparte turnos, el ciclo se
  // repite cada minuto y el log no debe llenarse con lo mismo
  if Assigned(FRegistroLog) and (not FAvisoFallo) then
  begin
    FRegistroLog.RegistrarAviso(AMensaje);
    FAvisoFallo := True;
  end;
end;

function TTurnoColaUniDAC.ExpresionNombre: string;
begin
  // GET_LOCK es del servidor, no del esquema: sin acotarlo a la base en uso,
  // dos instalaciones del mismo servidor se quitarían el turno. El nombre no
  // puede pasar de 64 caracteres, de ahí el recorte; el resumen final
  // distingue dos bases cuyo nombre empiece igual.
  Result :=
    'CONCAT(''fzam_' + FNombre + '_'', LEFT(DATABASE(), 24), ''_'', ' +
    'LEFT(MD5(DATABASE()), 8))';
end;

function TTurnoColaUniDAC.Intentar: Boolean;
var
  Qry: TUniQuery;
begin
  Result := FEnPosesion;
  if not Result then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'SELECT GET_LOCK(' + ExpresionNombre + ', 0) AS TURNO';
      try
        Qry.Open;
        // 1 concede el turno y 0 lo tiene otro puesto. NULL es que el motor
        // no pudo resolverlo: entonces se trabaja como hasta ahora
        Result := Qry.Fields[0].IsNull or (Qry.Fields[0].AsInteger = 1);
        if Qry.Fields[0].IsNull then
          Anotar(SAvisoTurnoColaSinRespuesta);
      except
        on E: Exception do
        begin
          Anotar(Format(SAvisoTurnoColaNoDisponible, [E.Message]));
          Result := True;
        end;
      end;
      FEnPosesion := Result;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TTurnoColaUniDAC.Liberar;
var
  Qry: TUniQuery;
begin
  if FEnPosesion and Assigned(FConexion) then
  begin
    FEnPosesion := False;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'SELECT RELEASE_LOCK(' + ExpresionNombre + ') AS TURNO';
      try
        Qry.Open;
      except
        // Se anota y no se propaga: Liberar se llama desde un finally y
        // taparía el error de verdad. El motor suelta el bloqueo al cerrar
        // la conexión, así que el turno no se queda retenido.
        on E: Exception do
          Anotar(Format(SAvisoTurnoColaNoLiberado, [E.Message]));
      end;
    finally
      FreeAndNil(Qry);
    end;
  end
  else
    FEnPosesion := False;
end;

end.

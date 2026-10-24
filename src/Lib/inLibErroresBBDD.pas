{******************************************************************************}
{                                                                              }
{  Módulo:       inLibErroresBBDD                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Excepciones de base de datos que distinguen el fallo pasajero del         }
{    fallo del dato, para que quien reintenta sepa a qué atenerse.             }
{******************************************************************************}
unit inLibErroresBBDD;

interface

uses
  System.SysUtils;

type
  EErrorBBDD = class(Exception);
  ELimiteConexionesBBDD = class(EErrorBBDD);
  EConexionMantenimientoBBDD = class(EErrorBBDD)
  private
    FLimiteConexiones: Boolean;
  public
    constructor Create(const AMensaje: string;
      ALimiteConexiones: Boolean); reintroduce;
    property LimiteConexiones: Boolean read FLimiteConexiones;
  end;
  EConexionPerdidaBBDD = class(EErrorBBDD)
  private
    FConfirmacionIncierta: Boolean;
  public
    property ConfirmacionIncierta: Boolean
      read FConfirmacionIncierta write FConfirmacionIncierta;
  end;

  { Rechazo de negocio comunicado por SIGNAL SQLSTATE '45000'. }
  EValidacionBBDD = class(Exception);

  { Campo obligatorio sin rellenar. Se muestra como aviso de validación y
    NombreCampo permite a la pantalla darle el foco (FZ-ISSUE-623). }
  ECampoObligatorioBBDD = class(EValidacionBBDD)
  private
    FNombreCampo: string;
  public
    constructor Create(const ANombreCampo, AMensaje: string); reintroduce;
    property NombreCampo: string read FNombreCampo;
  end;

  { Bloqueo pasajero del motor: espera de bloqueo agotada o interbloqueo
    deshecho por el propio motor. No es un fallo del dato ni de la petición:
    el mismo trabajo sale adelante al repetirlo, así que quien reintenta no
    debe gastar intentos ni dar la operación por perdida. }
  EBloqueoBBDDTemporal = class(Exception)
  private
    FCodigo: Integer;
  public
    constructor Create(ACodigo: Integer;
                       const AMensaje: string); reintroduce;
    property Codigo: Integer read FCodigo;
  end;

// Sesión perdida o consulta interrumpida por una desconexión.
function EsConexionPerdidaBBDD(ACodigo: Integer): Boolean;

// FZ-ISSUE-337: el pool de UniDAC del puesto se ha quedado sin conexiones
// (cada pantalla abierta retiene la suya). UniDAC lo dice siempre en inglés.
function EsAgotamientoPoolConexiones(const AMensaje: string): Boolean;

{ Códigos de MariaDB/MySQL que solo indican contención entre sesiones.
  1205: se agotó la espera por un bloqueo. 1213: interbloqueo; el motor
  eligió víctima y deshizo su transacción. 1020: conflicto de lectura
  con aislamiento de instantánea; requiere repetir toda la transacción. }
function EsBloqueoTemporalBBDD(ACodigo: Integer): Boolean;

// ATrabajo debe revertir su transacción y restaurar la entrada antes de
// propagar el bloqueo. Solo se repite un interbloqueo automáticamente.
function EjecutarConReintentoBloqueoBBDD(const ATrabajo: TProc;
  const AReintentar: TFunc<Boolean>): Boolean;

{ UniDAC antepone #45000 al mensaje de las validaciones del servidor. }
function ObtenerMensajeValidacionBBDD(ACodigo: Integer;
  const AMensaje: string; out AMensajeValidacion: string): Boolean;

implementation

const
  CEsperaBloqueoAgotada = 1205;
  CInterbloqueo         = 1213;
  CFilaModificada      = 1020;

constructor EConexionMantenimientoBBDD.Create(const AMensaje: string;
  ALimiteConexiones: Boolean);
begin
  inherited Create(AMensaje);
  FLimiteConexiones := ALimiteConexiones;
end;

constructor ECampoObligatorioBBDD.Create(const ANombreCampo,
  AMensaje: string);
begin
  inherited Create(AMensaje);
  FNombreCampo := ANombreCampo;
end;

constructor EBloqueoBBDDTemporal.Create(ACodigo: Integer;
                                        const AMensaje: string);
begin
  inherited Create(AMensaje);
  FCodigo := ACodigo;
end;

function EsConexionPerdidaBBDD(ACodigo: Integer): Boolean;
begin
  Result := (ACodigo = 2006) or (ACodigo = 2013) or (ACodigo = 2055);
end;

function EsAgotamientoPoolConexiones(const AMensaje: string): Boolean;
begin
  Result := Pos('MAXIMUM CONNECTIONS REACHED IN POOL',
    UpperCase(AMensaje)) > 0;
end;

function EsBloqueoTemporalBBDD(ACodigo: Integer): Boolean;
begin
  Result := (ACodigo = CEsperaBloqueoAgotada) or
            (ACodigo = CInterbloqueo) or
            (ACodigo = CFilaModificada);
end;

function EjecutarConReintentoBloqueoBBDD(const ATrabajo: TProc;
  const AReintentar: TFunc<Boolean>): Boolean;
var
  bRepetir: Boolean;
  bAutomaticoUsado: Boolean;
begin
  if not Assigned(ATrabajo) then
    raise EArgumentNilException.Create('ATrabajo');
  Result := False;
  bAutomaticoUsado := False;
  repeat
    bRepetir := False;
    try
      ATrabajo();
      Result := True;
    except
      on E: EBloqueoBBDDTemporal do
      begin
        if ((E.Codigo = CInterbloqueo) or
            (E.Codigo = CFilaModificada)) and not bAutomaticoUsado then
        begin
          bAutomaticoUsado := True;
          bRepetir := True;
        end
        else if Assigned(AReintentar) then
          bRepetir := AReintentar()
        else
          raise;
      end;
    end;
  until not bRepetir;
end;

function ObtenerMensajeValidacionBBDD(ACodigo: Integer;
  const AMensaje: string; out AMensajeValidacion: string): Boolean;
const
  CSignalExcepcion = 1644;
  CEstadoValidacion = '#45000';
var
  sMensaje: string;
begin
  AMensajeValidacion := '';
  sMensaje := Trim(AMensaje);
  Result := (ACodigo = CSignalExcepcion) and
    (Copy(sMensaje, 1, Length(CEstadoValidacion)) = CEstadoValidacion);
  if Result then
  begin
    sMensaje := Trim(Copy(sMensaje, Length(CEstadoValidacion) + 1,
      MaxInt));
    Result := (sMensaje <> '') and not SameText(sMensaje,
      'Unhandled user-defined exception condition');
    if Result then
      AMensajeValidacion := sMensaje;
  end;
end;

end.

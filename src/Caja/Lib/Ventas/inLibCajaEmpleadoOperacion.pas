{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaEmpleadoOperacion                                    }
{    Tipo:       Libreria de dominio                                           }
{ Version:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Empleado de las operaciones de caja sin venta (gastos, entrada de         }
{    cambio, traspasos). FZ-ISSUE-396: se propone un empleado que exista       }
{    (o ninguno) y no se admite uno inexistente.                               }
{******************************************************************************}
unit inLibCajaEmpleadoOperacion;

interface

uses
  inLibCajaVentaIntf;

// Resuelve lo tecleado a un empleado activo de fza_empleados.
function ResolverEmpleadoOperacionCaja(
  const AConsultas: IRepositorioConsultasCaja;
  const AEntrada: string;
  out AEmpleado: TEmpleadoCaja): Boolean;

// Código que se propone al abrir la operación: el empleado por defecto de
// los parámetros de caja si está activado y existe; si no, vacío. Nunca el
// nombre del usuario, que no es un código de empleado.
function ProponerEmpleadoOperacionCaja(
  const AConsultas: IRepositorioConsultasCaja;
  ARellenarEmpleadoDefecto: Boolean;
  const AEmpleadoDefecto: string): string;

implementation

uses
  System.SysUtils;

function ResolverEmpleadoOperacionCaja(
  const AConsultas: IRepositorioConsultasCaja;
  const AEntrada: string;
  out AEmpleado: TEmpleadoCaja): Boolean;
begin
  AEmpleado := Default(TEmpleadoCaja);
  Result := Assigned(AConsultas) and (Trim(AEntrada) <> '') and
    AConsultas.BuscarEmpleado(Trim(AEntrada), AEmpleado) and
    (Trim(AEmpleado.Codigo) <> '');
  if not Result then
    AEmpleado := Default(TEmpleadoCaja);
end;

function ProponerEmpleadoOperacionCaja(
  const AConsultas: IRepositorioConsultasCaja;
  ARellenarEmpleadoDefecto: Boolean;
  const AEmpleadoDefecto: string): string;
var
  oEmpleado: TEmpleadoCaja;
begin
  Result := '';
  if ARellenarEmpleadoDefecto and
     ResolverEmpleadoOperacionCaja(
       AConsultas, AEmpleadoDefecto, oEmpleado) and
     SameText(Trim(oEmpleado.Codigo), Trim(AEmpleadoDefecto)) then
    Result := oEmpleado.Codigo;
end;

end.

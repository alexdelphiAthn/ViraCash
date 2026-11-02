{******************************************************************************}
{  Módulo: inLibClientesCoincidencias                                          }
{  Tipo: Librería. Fecha: 02/11/2026                                            }
{  Descripción: Identidad y contacto para avisos de coincidencias de clientes. }
{******************************************************************************}
unit inLibClientesCoincidencias;

interface

type
  TIdentidadClienteCoincidencias = record
    Codigo: string;
    Nif: string;
    Telefono: string;
    Movil: string;
    Correo: string;
  end;

  TCandidatoCliente = record
    Codigo: string;
    Nombre: string;
    MismoNif: Boolean;
    MismoContacto: Boolean;
  end;
  TCandidatosCliente = TArray<TCandidatoCliente>;

  TConfirmarCoincidenciasCliente = function(
    const ACandidatos: TCandidatosCliente;
    out AMotivo: string): Boolean of object;

function NormalizarNifCoincidencias(const ATexto: string): string;
function NormalizarTelefonoCoincidencias(const ATexto: string): string;
function NormalizarCorreoCoincidencias(const ATexto: string): string;

implementation

uses
  System.SysUtils;

function NormalizarNifCoincidencias(const ATexto: string): string;
var
  cCaracter: Char;
begin
  Result := '';
  for cCaracter in UpperCase(ATexto) do
    if CharInSet(cCaracter, ['A'..'Z', '0'..'9']) then
      Result := Result + cCaracter;
end;

function NormalizarTelefonoCoincidencias(const ATexto: string): string;
var
  cCaracter: Char;
begin
  Result := '';
  for cCaracter in ATexto do
    if CharInSet(cCaracter, ['0'..'9']) then
      Result := Result + cCaracter;
end;

function NormalizarCorreoCoincidencias(const ATexto: string): string;
begin
  Result := LowerCase(Trim(ATexto));
end;

end.

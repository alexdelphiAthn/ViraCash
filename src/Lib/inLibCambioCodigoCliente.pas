{******************************************************************************}
{                                                                             }
{  Módulo: inLibCambioCodigoCliente                                           }
{  Tipo: Contrato y validación                                                }
{  Versión: 1.0.0                                                             }
{  Fecha: 14/11/2026                                                          }
{  Autor: Alejandro Laorden Hidalgo                                           }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  Descripción:                                                               }
{  Tipos de cambio de código y coincidencias de clientes.                     }
{                                                                             }
{******************************************************************************}
unit inLibCambioCodigoCliente;

interface

type
  TEstadoCambioCliente = (eccCorrecto, eccDatosInvalidos,
    eccOrigenNoExiste, eccDestinoOcupado, eccEsquemaNoCompatible,
    eccTransaccionActiva);

  TResultadoCambioCliente = record
    Estado: TEstadoCambioCliente;
    Referencias: Int64;
  end;

  TDuplicadoCliente = record
    Codigo: string;
    Nombre: string;
    OtroCodigo: string;
    OtroNombre: string;
    MismoNif: Boolean;
    MismoContacto: Boolean;
  end;
  TDuplicadosClientes = TArray<TDuplicadoCliente>;

  ICambioCodigoCliente = interface
    ['{91B8206B-A99C-4E36-AF87-782B03D0DDDA}']
    function Cambiar(const AAnterior, ANuevo, AUsuario: string):
      TResultadoCambioCliente;
    // Código vacío: todos. La consulta no modifica ni fusiona fichas.
    function DetectarDuplicados(const ACodigo: string): TDuplicadosClientes;
  end;

const
  LIMITE_DUPLICADOS_CLIENTES = 200;

function DatosCambioClienteValidos(
  const AAnterior, ANuevo, AUsuario: string): Boolean;

implementation

uses
  System.SysUtils;

function CodigoValido(const ACodigo: string): Boolean;
var
  cCaracter: Char;
begin
  // Cero representa la venta sin cliente identificado en caja.
  Result := (Trim(ACodigo) <> '') and (Trim(ACodigo) <> '0')
    and (Length(ACodigo) <= 20);
  for cCaracter in ACodigo do
    Result := Result and (Ord(cCaracter) >= 32);
end;

function DatosCambioClienteValidos(
  const AAnterior, ANuevo, AUsuario: string): Boolean;
begin
  Result := CodigoValido(Trim(AAnterior)) and CodigoValido(Trim(ANuevo))
    and not SameText(Trim(AAnterior), Trim(ANuevo))
    and (Trim(AUsuario) <> '') and (Length(Trim(AUsuario)) <= 50);
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEnvioErroresIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y validaciones del envío de errores al servicio de soporte.     }
{******************************************************************************}
unit inLibEnvioErroresIntf;

interface

uses
  inLibLogIntf;

type
  TDatosEmpresaError = record
    RazonSocial: string;
    Nif: string;
    NumeroInstalacionSif: string;
    CodigoSif: string;
    VersionSif: string;
    Direccion1: string;
    Direccion2: string;
    CodigoPostal: string;
    Poblacion: string;
    Provincia: string;
    Telefono: string;
  end;

  IRepositorioDatosEmpresaError = interface
    ['{792A1E88-CE07-4C4F-8F12-8CD59392B84F}']
    function Obtener(
      const ACodigoEmpresa: string): TDatosEmpresaError;
  end;

  TRegistroEnvioErrorLocal = record
    InstanteError: TDateTime;
    InstanteEnvio: TDateTime;
    UrlServicio: string;
    UrlSeguimiento: string;
    UrlEstado: string;
    Referencia: string;
    TokenSeguimiento: string;
    Estado: string;
    CodigoHttp: Integer;
    ClaseError: string;
    MensajeError: string;
    DetalleError: string;
    MensajeEnvio: string;
    EmailContacto: string;
    TelefonoContacto: string;
    Descripcion: string;
    Usuario: string;
  end;

  IRepositorioErroresEnvios = interface
    ['{B67A9A55-A7DD-48F8-B9F6-C982692AF2BB}']
    procedure Registrar(
      const ARegistro: TRegistroEnvioErrorLocal);
  end;

  TContactoError = record
    Email: string;
    Telefono: string;
    Descripcion: string;
  end;

  TEvidenciaError = record
    InstanteError: TDateTime;
    ClaseError: string;
    MensajeError: string;
    DetalleError: string;
    RutaPantallazo: string;
    RutaLog: string;
    RutaCopiaSeguridad: string;
    Log: TEvidenciasLog;
  end;

  TResultadoEnvioError = record
    Ok: Boolean;
    EstadoHttp: Integer;
    Referencia: string;
    TokenSeguimiento: string;
    UrlSeguimiento: string;
    UrlEstado: string;
    Estado: string;
    Mensaje: string;
  end;

  IServicioEnvioErrores = interface
    ['{F6A6111C-C28E-493B-A90E-DC48FEA5447D}']
    function Preparar(
      const AClaseError, AMensajeError,
      ADetalleError: string): TEvidenciaError;
    function Enviar(
      const AEvidencia: TEvidenciaError;
      const AContacto: TContactoError): TResultadoEnvioError;
    function PrepararCopiaSeguridad(
      var AEvidencia: TEvidenciaError;
      const AContrasena: string;
      out AError: string): Boolean;
    procedure DescartarCopiaSeguridad(
      var AEvidencia: TEvidenciaError);
    procedure ActivarDiagnosticoCompleto;
    procedure Limpiar(var AEvidencia: TEvidenciaError);
  end;

function EmailSoporteValido(const AEmail: string): Boolean;
function TelefonoSoporteValido(const ATelefono: string): Boolean;

implementation

uses
  System.SysUtils;

function EmailSoporteValido(const AEmail: string): Boolean;
var
  iArroba: Integer;
  iPunto: Integer;
  sEmail: string;
begin
  sEmail := Trim(AEmail);
  iArroba := Pos('@', sEmail);
  iPunto := LastDelimiter('.', sEmail);
  Result := (sEmail <> '') and
            (Pos(' ', sEmail) = 0) and
            (iArroba > 1) and
            (iPunto > iArroba + 1) and
            (iPunto < Length(sEmail));
end;

function TelefonoSoporteValido(const ATelefono: string): Boolean;
var
  cCaracter: Char;
  iDigitos: Integer;
  iIndice: Integer;
  sTelefono: string;
begin
  sTelefono := Trim(ATelefono);
  iDigitos := 0;
  Result := sTelefono <> '';
  iIndice := 1;
  while (iIndice <= Length(sTelefono)) and Result do
  begin
    cCaracter := sTelefono[iIndice];
    if CharInSet(cCaracter, ['0'..'9']) then
      Inc(iDigitos)
    else
      Result := CharInSet(cCaracter, ['+', ' ', '-', '(', ')', '.']);
    Inc(iIndice);
  end;
  Result := Result and
            (iDigitos >= 7) and
            (iDigitos <= 15);
end;

end.

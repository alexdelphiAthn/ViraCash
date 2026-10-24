{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerificacionNifIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de la verificación de NIF en el censo de la AEAT (servicio       }
{    VNifV2, calidad de datos identificativos). FZ-ISSUE-131.                  }
{******************************************************************************}
unit inLibVerificacionNifIntf;

interface

uses
  System.SysUtils;

type
  // Resultado del censo. evnOtro agrupa respuestas no previstas.
  TEstadoVerificacionNif = (
    evnIdentificado,
    evnNoIdentificado,
    evnRevocado,
    evnBaja,
    evnOtro);

  // Correcta: identificado y coincide. Aviso: identificado con otro NIF
  // o con otra razón social. Error: no identificado, revocado o de baja.
  TGravedadVerificacionNif = (
    gvnCorrecta,
    gvnAviso,
    gvnError);

  TSolicitudVerificacionNif = record
    Nif: string;
    Nombre: string;
    // Empresa cuyo certificado autentica la petición.
    CodigoEmpresa: string;
    // Cliente en el que se guarda el resultado ('' = no se guarda).
    CodigoCliente: string;
  end;

  TResultadoVerificacionNif = record
    NifEnviado: string;
    NombreEnviado: string;
    NifAeat: string;
    NombreAeat: string;
    // Texto literal de la AEAT (IDENTIFICADO, NO IDENTIFICADO...).
    Resultado: string;
    Estado: TEstadoVerificacionNif;
    Gravedad: TGravedadVerificacionNif;
    // La AEAT casó el número con otro NIF (p. ej. B... → J...).
    NifDistinto: Boolean;
    // Persona jurídica cuya razón social oficial no coincide.
    NombreDistinto: Boolean;
    // En personas físicas la AEAT devuelve un eco del nombre enviado.
    EsPersonaJuridica: Boolean;
  end;

  TCertificadoVerificacionNif = record
    Serie: string;
    Titular: string;
  end;

  IRepositorioVerificacionNif = interface
    ['{6A0D8C1E-3B52-4E7F-9C21-5F3A7B9D0E41}']
    function LeerCertificadoEmpresa(
      const ACodigoEmpresa: string): TCertificadoVerificacionNif;
    // Sin las columnas de verificación (script no aplicado) no guarda.
    procedure GuardarResultadoCliente(
      const ACodigoCliente, AResultado: string);
  end;

  ITransporteVerificacionNif = interface
    ['{0F7B2D94-61C8-4A3E-B5D0-8E2C4F6A1B73}']
    function Enviar(
      const APeticion: string;
      const ACertificado: TCertificadoVerificacionNif;
      out AStatus: Integer): string;
  end;

  IServicioVerificacionNif = interface
    ['{C3E19A57-2D4B-4F86-A0B7-9D5E1C3F7A28}']
    function Verificar(
      const ASolicitud: TSolicitudVerificacionNif): TResultadoVerificacionNif;
  end;

  // Error controlado: sin certificado, NIF vacío o rechazo de la AEAT.
  EVerificacionNif = class(Exception);

implementation

end.

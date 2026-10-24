{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuSubsanacionIntf                                 }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de encolado para subsanar altas aceptadas con errores.           }
{******************************************************************************}
unit inLibVerifactuSubsanacionIntf;
interface
uses
  inLibParametrosIntf;
type
  IServicioVerifactuSubsanacion = interface
    ['{9FF0CC27-BE4B-4B5B-992A-92190D82887F}']
    procedure Encolar(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
  end;
  IServicioVerifactuCorreccionRegistro = interface
    ['{8792C4EC-EA22-4BAC-964D-1609F986581A}']
    // Comparte la transacción activa del llamador y no la confirma.
    procedure EncolarCorreccionRegistro(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
  end;
implementation
end.

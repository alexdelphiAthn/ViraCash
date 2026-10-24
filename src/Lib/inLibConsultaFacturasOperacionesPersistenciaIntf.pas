{******************************************************************************}
{                                                                              }
{  Modulo:       inLibConsultaFacturasOperacionesPersistenciaIntf             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura de facturas asociado a la consulta de operaciones.     }
{******************************************************************************}
unit inLibConsultaFacturasOperacionesPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TFacturaConsultaOperacion = record
    Existe: Boolean;
    Consolidada: Boolean;
    // Registro VeriFactu enviado y aceptado por la AEAT.
    PuedeSubsanar: Boolean;
    // Registro NO VERI*FACTU firmado y encadenado.
    PuedeSubsanarNoVerifactu: Boolean;
    // Subsanable en modo SIN VeriFactu, sin exigir consolidación.
    PuedeSubsanarSinVerifactu: Boolean;
    Tipo: string;
    Fase: string;
    Fecha: TDateTime;
  end;

  IRepositorioConsultaFacturasOperaciones = interface
    ['{5EAFF815-CB97-4B1B-AEBD-32CEFF997995}']
    function ConsultarFactura(
      const ASerie, ANumero: string): TFacturaConsultaOperacion;
  end;

implementation

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuColaIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de persistencia y procesamiento de la cola fiscal Verifactu.      }
{******************************************************************************}
unit inLibVerifactuColaIntf;

interface

uses
  inLibParametrosIntf, inLibEmisionFiscalIntf;

type
  // Enlace de una rectificativa recién creada con su factura original.
  // EmitirAhora encola el alta fiscal en el acto (abono completo, R4 de
  // una incidencia, caja). Sin él la rectificativa queda en BORRADOR para
  // revisarla y la original conserva su fase hasta que se consolide.
  TSolicitudVinculoRectificativa = record
    Usuario: string;
    SerieOriginal: string;
    NumeroOriginal: string;
    SerieRectificativa: string;
    NumeroRectificativa: string;
    // I = por diferencias; S = por sustitución.
    TipoRectificativa: string;
    // R1..R5; vacío conserva el de la factura o lo deduce el envío.
    TipoFacturaVerifactu: string;
    Motivo: string;
    // Sólo en sustitución: retira los movimientos de la original y la
    // rectificativa genera los suyos.
    ReemplazarMovimientosOriginales: Boolean;
    EmitirAhora: Boolean;
    DescripcionEvento: string;
  end;
  IServicioVerifactuCola = interface
    ['{8584C936-77C9-4CB8-AF27-E85A623FA3D4}']
    procedure EncolarFactura(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure MarcarFacturaSinVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure BorrarMovimientosFactura(
      const ASerie, ANumero: string);
    procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect, ATipoRectificativa: string;
      ABorrarMovimientosOriginales: Boolean);
    procedure RegistrarRelacionFactura(
      const AUsuario, ASerie, ANumero, ASerieOrigen,
      ANumeroOrigen, ATipoRelacion: string);
    // Marca la rectificativa, la enlaza con la original y, si la
    // solicitud lo pide, emite su alta fiscal. EncolarRectificativa
    // equivale a vincular con EmitirAhora.
    procedure VincularRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioEmision: IServicioEmisionFiscal;
      const ASolicitud: TSolicitudVinculoRectificativa);
    // Al consolidar una rectificativa vinculada sin emitir: la original
    // pasa a RECTIFICADA y, en sustitución con reemplazo, pierde sus
    // movimientos. Comparte la transacción del llamador.
    procedure CompletarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerieRect, ANumeroRect: string);
    // Al borrar un borrador rectificativo: retira la relación y devuelve
    // la original a su fase. Comparte la transacción del llamador.
    procedure DesvincularRectificativa(
      const AUsuario, ASerieRect, ANumeroRect: string);
  end;
  IProcesadorVerifactuCola = interface
    ['{EE2E4B72-27E1-4C27-9682-F14F50035941}']
    procedure Iniciar;
    procedure Detener;
  end;

implementation

end.

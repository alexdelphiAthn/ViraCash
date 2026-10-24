{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasSubsanacionIntf                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para subsanar el registro fiscal de una factura de venta        }
{    mayor ya aceptada: la factura se abre a corrección (fase SUBSANACION),    }
{    se edita con su misma identidad y se registra un alta con               }
{    Subsanacion = S.                                                          }
{******************************************************************************}
unit inLibFacturasSubsanacionIntf;

interface

uses
  System.SysUtils,
  inLibFacturasServiciosIntf;

type
  TDatosSubsanacionFactura = record
    Encontrada: Boolean;
    FormatoDocumento: string;
    Serie: string;
    Numero: string;
    TipoFactura: string;
    Fase: string;
    Consolidada: Boolean;
    // Estado del último registro fiscal (ESTADO_FACCON) y si está
    // encadenado (tiene huella).
    EstadoRegistro: string;
    TieneHuella: Boolean;
    // Estado de la fila de la cola Verifactu que no esté ENVIADA; vacío
    // si no hay ningún envío en curso.
    EstadoColaActiva: string;
    // Rectificativa vigente enlazada desde esta factura (columnas ABONO).
    SerieRectificativa: string;
    NumeroRectificativa: string;
    InstanteModificacion: TDateTime;
  end;
  TResultadoSubsanacionFactura = record
    Serie: string;
    Numero: string;
    EncoladaVerifactu: Boolean;
    RegistradaNoVerifactu: Boolean;
    Mensaje: string;
  end;
  // Factura grabada frente a su último registro aceptado (FZ-ISSUE-133).
  TDatosComparacionSubsanacion = record
    // XML del registro firmado; vacío si no se conserva.
    RegistroXml: string;
    // Los mismos importes que comunica el envío: cuota = TOTAL_IMPUESTOS
    // e importe = bases + impuestos (antes de la retención).
    CuotaTotal: Currency;
    ImporteTotal: Currency;
    NifCliente: string;
    NombreCliente: string;
  end;
  ESubsanacionFactura = class(Exception);
  IRepositorioSubsanacionFactura = interface
    ['{5E7A2C91-0D4B-4F3E-B6A8-1C9F7D2E4B30}']
    function Cargar(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosSubsanacionFactura;
    // Cambia la fase y devuelve el instante de modificación resultante.
    function CambiarFase(
      const ASerie, ANumero, AFase, AUsuario: string): TDateTime;
    // Importes y destinatario grabados y XML del último registro.
    function CargarComparacionRegistro(
      const ASerie, ANumero: string): TDatosComparacionSubsanacion;
  end;
  IServicioSubsanacionFactura = interface
    ['{A1B7E3D5-8C2F-4E6A-9D0B-3F5C7A1E8D42}']
    function Cargar(
      const ASerie, ANumero: string): TDatosSubsanacionFactura;
    function ValidarInicio(
      const ASerie, ANumero: string): TResultadoOperacionFactura;
    // Abre la factura a corrección: fase SUBSANACION, editable.
    procedure Iniciar(const ASerie, ANumero: string);
    // True si la factura se ha grabado desde que esta sesión inició la
    // subsanación; False sin cambios o sin constancia del inicio.
    function HayCambiosDesdeInicio(
      const ASerie, ANumero: string): Boolean;
    // Diferencias de la factura grabada con su último registro aceptado
    // (FZ-ISSUE-133); vacío si coinciden o no hay registro comparable.
    function DiferenciasConRegistro(
      const ASerie, ANumero: string): string;
    // Devuelve la factura a su fase de registro y encola (o firma en NO
    // VERI*FACTU) el registro de subsanación con los datos actuales.
    function Registrar(
      const ASerie, ANumero, AMotivo: string
    ): TResultadoSubsanacionFactura;
    // Devuelve la factura a su fase de registro sin subsanar. Lanza
    // ESubsanacionFactura si ya no coincide con el registro aceptado.
    procedure Cancelar(const ASerie, ANumero: string);
  end;

implementation

end.

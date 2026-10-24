{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasRectificativaIntf                                }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para rectificar (por diferencias o por sustitución) o          }
{    duplicar una factura de venta mayor desde el mantenimiento.               }
{******************************************************************************}
unit inLibFacturasRectificativaIntf;

interface

uses
  System.SysUtils,
  inLibFacturasServiciosIntf;

type
  TOperacionRectificativaFactura = (
    // Abono: copia con cantidades en negativo, TipoRectificativa I.
    orfDiferencias,
    // Copia positiva que el usuario corrige, TipoRectificativa S.
    orfSustitucion,
    // Copia sin vínculo fiscal con la original.
    orfDuplicado);
  TMovimientosRectificativaFactura = (
    mrfMantenerOriginales,
    mrfReemplazarOriginales);
  TDatosOrigenRectificativa = record
    Encontrada: Boolean;
    Serie: string;
    Numero: string;
    TipoFactura: string;
    Fase: string;
    Consolidada: Boolean;
    CodigoEmpresa: string;
    FormatoDocumento: string;
    CodigoAlmacen: string;
    FormaPago: string;
    // Rectificativa vigente enlazada desde la original (columnas ABONO).
    SerieRectificativa: string;
    NumeroRectificativa: string;
    // Alguna rectificativa de esta factura sigue en BORRADOR.
    TieneRectificativaPendiente: Boolean;
  end;
  TSolicitudRectificativaFactura = record
    SerieOriginal: string;
    NumeroOriginal: string;
    Operacion: TOperacionRectificativaFactura;
    // R1..R4 para originales completas; R5 para simplificadas.
    TipoFacturaVerifactu: string;
    Serie: string;
    Fecha: TDateTime;
    FormaPago: string;
    Motivo: string;
    Movimientos: TMovimientosRectificativaFactura;
    // True emite el alta fiscal al crear el documento; False lo deja en
    // BORRADOR para revisarlo y consolidarlo después.
    EmitirAlCrear: Boolean;
  end;
  TResultadoRectificativaFactura = record
    Serie: string;
    Numero: string;
    Emitida: Boolean;
    Mensaje: string;
  end;
  ERectificativaFactura = class(Exception);
  IRepositorioRectificativaFactura = interface
    ['{3C1F9E2A-7B6D-4F58-9A0C-2E5D8B7F1A64}']
    function CargarOrigen(
      const ASerie, ANumero: string): TDatosOrigenRectificativa;
    // Copia la original en la serie pedida (abono o duplicado) y
    // devuelve el número que asigna el contador.
    function CrearBorrador(
      const ASolicitud: TSolicitudRectificativaFactura;
      const AUsuario, ACodigoEmpresa: string): string;
  end;
  IServicioRectificativaFactura = interface
    ['{B8D4A7C3-5E19-4C2B-8F6A-9D3E1C7B2A55}']
    function CargarOrigen(
      const ASerie, ANumero: string): TDatosOrigenRectificativa;
    function Validar(
      const ASolicitud: TSolicitudRectificativaFactura
    ): TResultadoOperacionFactura;
    function Crear(
      const ASolicitud: TSolicitudRectificativaFactura
    ): TResultadoRectificativaFactura;
    // Cierra el vínculo de una rectificativa creada sin emitir cuando se
    // consolida: la original pasa a RECTIFICADA.
    procedure CompletarEmision(
      const ASerie, ANumero, AUsuario: string);
  end;

implementation

end.

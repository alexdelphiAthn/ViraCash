{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosCodigosBarrasPersistenciaIntf                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia para generar códigos de barras de artículos.       }
{******************************************************************************}
unit inLibArticulosCodigosBarrasPersistenciaIntf;

interface

type
  TEstadoCodigoBarrasSku = record
    CodigoSku: string;
    TienePrincipal: Boolean;
    TieneFilaFabricante: Boolean;
  end;

  IArticulosCodigosBarrasPersistencia = interface
    ['{9830E7E3-8FAF-4367-BC63-69E59B44F484}']
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
    function EliminarMarcadoresAntiguos(
      const ACodigoArticulo: string): Integer;
    function ConsultarSkusActivos(
      const ACodigoArticulo: string): TArray<TEstadoCodigoBarrasSku>;
    function ObtenerSiguienteContador(
      const ATipo, AUsuario: string): string;
    function ExisteCodigoBarras(const ACodigoBarras: string): Boolean;
    // Deja el contador por encima de la mayor secuencia que ya usan
    // los codigos internos con ese prefijo, los haya creado quien sea
    // (FZ-ISSUE-448: las sesiones de compra no consumen el contador).
    procedure AdelantarContador(const ATipo, APrefijo: string;
      ADigitosSecuencia: Integer; const AUsuario: string);
    procedure InsertarCodigoPrincipal(const ACodigoSku,
      ACodigoBarras, ATipo, AUsuario: string);
    procedure InsertarFilaFabricante(
      const ACodigoSku, ATipo, AUsuario: string);
  end;

implementation

end.

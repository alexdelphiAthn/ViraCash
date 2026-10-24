{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEmisionFiscalIntf                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para emitir facturas mediante una estrategia fiscal.            }
{******************************************************************************}
unit inLibEmisionFiscalIntf;

interface

uses
  inLibVerifactuTipos;

type
  TFlujoEmisionFiscal = (
    fefOperacion,
    fefConsolidacion,
    fefAlta);
  TSolicitudEmisionFiscal = record
    FormatoDocumento: string;
    Serie: string;
    Numero: string;
    Usuario: string;
    TipoOperacion: string;
    Accion: string;
    DescripcionEvento: string;
    BorrarMovimientos: Boolean;
    RegistrarEvento: Boolean;
    Flujo: TFlujoEmisionFiscal;
    class function ParaOperacion(
      const ASerie, ANumero, AUsuario,
      ATipoOperacion, AAccion: string;
      ABorrarMovimientos: Boolean;
      const ADescripcionEvento: string = ''
    ): TSolicitudEmisionFiscal; static;
    class function ParaAlta(
      const ASerie, ANumero, AUsuario,
      ADescripcionEvento: string;
      ARegistrarEvento: Boolean = True
    ): TSolicitudEmisionFiscal; static;
    class function ParaConsolidacion(
      const ASerie, ANumero, AUsuario: string
    ): TSolicitudEmisionFiscal; static;
  end;
  TResultadoEmisionFiscal = record
    Modo: TModoVerifactu;
    Mensaje: string;
  end;
  IServicioEmisionFiscal = interface
    ['{513E78E8-7755-413F-A033-7D5BC02C29C9}']
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;

implementation

class function TSolicitudEmisionFiscal.ParaOperacion(
  const ASerie, ANumero, AUsuario,
  ATipoOperacion, AAccion: string;
  ABorrarMovimientos: Boolean;
  const ADescripcionEvento: string
): TSolicitudEmisionFiscal;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
  Result.TipoOperacion := ATipoOperacion;
  Result.Accion := AAccion;
  if ADescripcionEvento <> '' then
    Result.DescripcionEvento := ADescripcionEvento
  else
    Result.DescripcionEvento :=
      AAccion + ' encolada desde Borradores';
  Result.BorrarMovimientos := ABorrarMovimientos;
  Result.RegistrarEvento := True;
  Result.Flujo := fefOperacion;
end;

class function TSolicitudEmisionFiscal.ParaAlta(
  const ASerie, ANumero, AUsuario,
  ADescripcionEvento: string;
  ARegistrarEvento: Boolean
): TSolicitudEmisionFiscal;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
  Result.TipoOperacion := 'ALTA';
  Result.Accion := '';
  Result.DescripcionEvento := ADescripcionEvento;
  Result.BorrarMovimientos := True;
  Result.RegistrarEvento := ARegistrarEvento;
  Result.Flujo := fefAlta;
end;

class function TSolicitudEmisionFiscal.ParaConsolidacion(
  const ASerie, ANumero, AUsuario: string
): TSolicitudEmisionFiscal;
begin
  Result := ParaAlta(
    ASerie,
    ANumero,
    AUsuario,
    'Lanzamiento manual (Consolidar) desde Borradores');
  Result.Flujo := fefConsolidacion;
end;

end.

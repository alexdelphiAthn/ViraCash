{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCambioArticuloColorHistoricoConsultaIntf                 }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de consulta del histórico de cambios de artículo y color.        }
{******************************************************************************}
unit inLibCambioArticuloColorHistoricoConsultaIntf;

interface

type
  TTipoHistoricoCambioArticuloColor = (
    thcacCambioArticulo,
    thcacFusionArticulo,
    thcacCambioColor,
    thcacFusionColor,
    thcacReversion
  );

  TEstadoHistoricoCambioArticuloColor = (
    ehcacAplicado,
    ehcacRevertido
  );

  TCambioArticuloColorHistorico = record
    Instante: TDateTime;
    Tipo: TTipoHistoricoCambioArticuloColor;
    Origen: string;
    Destino: string;
    Unidades: Integer;
    Usuario: string;
    Estado: TEstadoHistoricoCambioArticuloColor;
  end;

  TCambiosArticuloColorHistorico =
    TArray<TCambioArticuloColorHistorico>;

  IConsultaCambioArticuloColorHistorico = interface
    ['{8E72A178-E2D4-45A0-A8B5-FD6297861790}']
    function ConsultarUltimos(
      ALimite: Integer): TCambiosArticuloColorHistorico;
  end;

implementation

end.

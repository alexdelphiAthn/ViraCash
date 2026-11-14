{******************************************************************************}
{  Módulo: inLibCorreccionPagoIntf                                             }
{  Tipo: Contratos de Caja                                                     }
{  Versión: 1.0.0                                                              }
{  Fecha: 15/09/2026                                                           }
{  Descripción: Corrección de cobros mediante apuntes compensatorios.          }
{******************************************************************************}
unit inLibCorreccionPagoIntf;

interface

type
  TOperacionCorreccionPago = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Numero: string;
  end;

  TCobroCorregible = record
    Serie: string;
    Linea: Integer;
    FormaPago: string;
    Descripcion: string;
    ImporteNeto: Currency;
  end;

  TMedioCorreccionPago = record
    Codigo: string;
    Descripcion: string;
    RequiereReferencia: Boolean;
  end;

  TSolicitudCorreccionPago = record
    Operacion: TOperacionCorreccionPago;
    Serie: string;
    Linea: Integer;
    FormaPago: string;
    Referencia: string;
    Motivo: string;
  end;

  ICorreccionPago = interface
    ['{29201317-6A2B-43F0-98F7-E3D72D95B32C}']
    function Permitida: Boolean;
    function Cobros(const AOperacion: TOperacionCorreccionPago):
      TArray<TCobroCorregible>;
    function Medios: TArray<TMedioCorreccionPago>;
    procedure Corregir(const ASolicitud: TSolicitudCorreccionPago);
  end;

implementation

end.

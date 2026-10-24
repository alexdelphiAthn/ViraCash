{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArqueoPersistencia                                       }
{    Tipo:       Libreria                                                      }
{ Version:       1.1.0                                                         }
{   Fecha:       01/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto y caso de uso para grabar un arqueo de caja completo.              }
{******************************************************************************}
unit inLibArqueoPersistencia;

interface

uses
  inLibArqueo;

type
  TArqueoRecuentoLinea = record
    CodigoFP: string;
    Descripcion: string;
    EsCajon: string;
    Sistema: Currency;
    Recuento: Currency;
    Diferencia: Currency;
  end;
  IArqueoPersistencia = interface
    ['{4952397E-BE51-44AB-A25F-0C773488941B}']
    procedure GrabarArqueo(
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
      AImporteRetirada: Currency;
      const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
      ACodigoEmpleado, AUsuario: string);
  end;
  TArqueoPersistencia = class
  public
    class procedure GrabarArqueo(
      const APersistencia: IArqueoPersistencia;
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
      AImporteRetirada: Currency;
      const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
      ACodigoEmpleado, AUsuario: string);
  end;

implementation

class procedure TArqueoPersistencia.GrabarArqueo(
  const APersistencia: IArqueoPersistencia;
  const AArqueo: TArqueoCaja;
  const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
  ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
  AImporteRetirada: Currency;
  const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
  ACodigoEmpleado, AUsuario: string);
begin
  if APersistencia <> nil then
    APersistencia.GrabarArqueo(
      AArqueo,
      ALineasRecuento,
      ATotalRecuento,
      ADiferenciaTotal,
      AEfectivoDejado,
      AImporteRetirada,
      AConceptoRetirada,
      ADesgloseBilletes,
      AObservaciones,
      ACodigoEmpleado,
      AUsuario);
end;

end.

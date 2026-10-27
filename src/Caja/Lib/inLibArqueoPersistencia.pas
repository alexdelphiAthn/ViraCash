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
  inLibArqueo, inLibPermisosIntf;

type
  TModoCambioArqueoVenta = (mcavSubsanacion, mcavDiferencias,
    mcavSustitutiva);
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

function CambiaDineroArqueoVenta(AOriginal, ANuevo: Currency;
  AModo: TModoCambioArqueoVenta): Boolean;
function EsRootParaCambiarArqueo(
  const APermisos: IPermisosAplicacion): Boolean;

resourcestring
  SArqueoVentaRequiereRoot =
    'Para cambiar el importe de una venta con arqueo cerrado se necesita ' +
    'permiso root (administrador).';
  SArqueoVentaConfirmar =
    'El importe económico de la venta cambia y pertenece a un arqueo ' +
    'cerrado. Se borrará el cierre actual (%s) al guardar. Tendrá que ' +
    'realizar de nuevo el cierre de caja. ¿Desea continuar?';
  SArqueoVentaSinConfirmar =
    'El arqueo cerrado ha cambiado o falta confirmar su eliminación. ' +
    'Vuelva a guardar y confirme que tendrá que repetir el cierre.';

implementation

function CambiaDineroArqueoVenta(AOriginal, ANuevo: Currency;
  AModo: TModoCambioArqueoVenta): Boolean;
begin
  if AModo = mcavDiferencias then
    Result := ANuevo <> 0
  else
    Result := ANuevo <> AOriginal;
end;

function EsRootParaCambiarArqueo(
  const APermisos: IPermisosAplicacion): Boolean;
var
  rPermiso: TResultadoPermiso;
begin
  Result := False;
  if Assigned(APermisos) and APermisos.Disponible then
  begin
    rPermiso := APermisos.Evaluar(PERMISO_CAJA_BUSCAR_SUBSANAR, paDenegar);
    Result := rPermiso.Permitido and (rPermiso.Origen = opAdministrador);
  end;
end;

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

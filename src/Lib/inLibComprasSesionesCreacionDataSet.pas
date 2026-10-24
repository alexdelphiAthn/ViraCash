{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesCreacionDataSet                           }
{    Tipo:       Adaptador                                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Traduce la cabecera de una sesion de compra entre TDataSet y los records  }
{    puros usados por la aplicacion de materializacion.                        }
{******************************************************************************}
unit inLibComprasSesionesCreacionDataSet;

interface

uses
  Data.DB,
  inLibComprasSesionesCreacion;

function LeerEstadoSesionCreacion(
  ADataSet: TDataSet): TEstadoSesionCreacion;
procedure EscribirCabeceraSesionCreacion(
  ADataSet: TDataSet;
  const ACabecera: TCabeceraSesionActualizada);

implementation

uses
  System.SysUtils, System.StrUtils;

function LeerEstadoSesionCreacion(
  ADataSet: TDataSet): TEstadoSesionCreacion;
var
  bHayCabecera: Boolean;
begin
  Result := Default(TEstadoSesionCreacion);
  bHayCabecera := Assigned(ADataSet) and ADataSet.Active and
    (not ADataSet.IsEmpty);
  Result.HayCabecera := bHayCabecera;
  if bHayCabecera then
  begin
    Result.Estado := ADataSet.FieldByName('ESTADO_SES').AsString;
    Result.Serie := ADataSet.FieldByName('SERIE_SES').AsString;
    Result.Numero := ADataSet.FieldByName('NUMERO_SES').AsString;
    Result.Empresa := ADataSet.FieldByName('CODIGO_EMP_SES').AsString;
    Result.Almacen := ADataSet.FieldByName('CODIGO_ALM_SES').AsString;
    Result.Tarifa := ADataSet.FieldByName('CODIGO_TAR_SES').AsString;
    Result.TieneTemporada :=
      not ADataSet.FieldByName('ID_PV_TEMPORADA_SES').IsNull;
    if Result.TieneTemporada then
      Result.Temporada :=
        ADataSet.FieldByName('ID_PV_TEMPORADA_SES').AsInteger;
    Result.GeneraPedido :=
      ADataSet.FieldByName('ESGENERA_PEDIDO_SES').AsString = 'S';
    Result.GeneraAlbaran :=
      ADataSet.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S';
    Result.FormatoDistribuido :=
      ADataSet.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString = 'S';
    Result.RefProveedor := ADataSet.FieldByName('REF_PRV_SES').AsString;
    if Assigned(ADataSet.FindField('FECHA_SES')) then
      Result.FechaSesion := ADataSet.FieldByName('FECHA_SES').AsDateTime;
    if Assigned(ADataSet.FindField('FORMA_PAGO_SES')) then
      Result.FormaPago := ADataSet.FieldByName('FORMA_PAGO_SES').AsString;
  end;
end;

procedure EscribirCabeceraSesionCreacion(
  ADataSet: TDataSet;
  const ACabecera: TCabeceraSesionActualizada);
begin
  ADataSet.Edit;
  ADataSet.FieldByName('CODIGO_ALM_SES').AsString := ACabecera.Almacen;
  ADataSet.FieldByName('CODIGO_TAR_SES').AsString := ACabecera.Tarifa;
  if ACabecera.LimpiarTemporada then
    ADataSet.FieldByName('ID_PV_TEMPORADA_SES').Clear
  else
    ADataSet.FieldByName('ID_PV_TEMPORADA_SES').AsInteger :=
      ACabecera.Temporada;
  ADataSet.FieldByName('ESGENERA_PEDIDO_SES').AsString :=
    IfThen(ACabecera.GeneraPedido, 'S', 'N');
  ADataSet.FieldByName('ESGENERA_ALBARAN_SES').AsString :=
    IfThen(ACabecera.GeneraAlbaran, 'S', 'N');
  ADataSet.FieldByName('REF_PRV_SES').AsString :=
    ACabecera.RefProveedor;
  if (ACabecera.Fecha > 0) and Assigned(ADataSet.FindField('FECHA_SES')) then
    ADataSet.FieldByName('FECHA_SES').AsDateTime := Trunc(ACabecera.Fecha);
  if (Trim(ACabecera.FormaPago) <> '') and
     Assigned(ADataSet.FindField('FORMA_PAGO_SES')) then
    ADataSet.FieldByName('FORMA_PAGO_SES').AsString :=
      Trim(ACabecera.FormaPago);
  ADataSet.Post;
end;

end.

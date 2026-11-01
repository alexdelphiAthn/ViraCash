{******************************************************************************}
{  Módulo: UniDataReparacionesEntregas. Tipo: Persistencia                     }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Custodia y retornos parciales de objetos en proveedores.       }
{******************************************************************************}
unit UniDataReparacionesEntregas;

interface

uses
  Uni, UniDataReparacionesCircuitoBase;

type
  TEntregaExternoOrden = record
    Orden, Linea, Id: Int64;
    Proveedor, Objeto, Incidencia: string;
    Enviado, Recibido: Double;
    Revision: Integer;
  end;

  TRepositorioEntregasOrden = class(TRepositorioCircuitoOrden)
  public
    procedure Registrar(const AEntrega: TEntregaExternoOrden);
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgReparacionesCircuito;

procedure TRepositorioEntregasOrden.Registrar(
  const AEntrega: TEntregaExternoOrden);
begin
  if (Trim(AEntrega.Proveedor) = '') or (Trim(AEntrega.Objeto) = '') or
     (AEntrega.Enviado <= 0) or (AEntrega.Recibido < 0) or
     (AEntrega.Recibido > AEntrega.Enviado) then
    raise EArgumentException.Create(SCircuitoEntregaInvalida);
  Transaccion(
    procedure
    var
      oLinea, oConsulta: TUniQuery;
    begin
      oLinea := BloquearLinea(AEntrega.Orden, AEntrega.Linea);
      try
        if oLinea.FieldByName('CODIGO_PRV_GARLIN').AsString <>
           AEntrega.Proveedor then
          raise EArgumentException.Create(SCircuitoProveedorLinea);
        if AEntrega.Id = 0 then
          oConsulta := Consulta('INSERT INTO fza_reparaciones_entregas ' +
            '(ID_GAR_RCE,ID_GARLIN_RCE,CODIGO_PRV_RCE,OBJETO_RCE,' +
            'CANTIDAD_ENVIADA_RCE,CANTIDAD_RECIBIDA_RCE,INSTANTE_ENVIO_RCE,' +
            'INCIDENCIA_RCE,USUARIO_ALTA) ' +
            'VALUES (:ORDEN,:LINEA,:PROVEEDOR,:OBJETO,:ENVIADO,' +
            ':RECIBIDO,NOW(),:INCIDENCIA,:USUARIO)')
        else
          oConsulta := Consulta('UPDATE fza_reparaciones_entregas ' +
            'SET CANTIDAD_RECIBIDA_RCE=:RECIBIDO,INCIDENCIA_RCE=:INCIDENCIA,' +
            'INSTANTE_RECEPCION_RCE=NOW(),REVISION_RCE=REVISION_RCE+1,' +
            'INSTANTE_MODIF=NOW(),USUARIO_MODIF=:USUARIO ' +
            'WHERE ID_RCE=:ID AND ID_GAR_RCE=:ORDEN ' +
            'AND ID_GARLIN_RCE=:LINEA AND REVISION_RCE=:REVISION ' +
            'AND CODIGO_PRV_RCE=:PROVEEDOR AND OBJETO_RCE=:OBJETO ' +
            'AND CANTIDAD_ENVIADA_RCE=:ENVIADO ' +
            'AND CANTIDAD_RECIBIDA_RCE<=:RECIBIDO');
        try
          oConsulta.ParamByName('ORDEN').AsLargeInt := AEntrega.Orden;
          oConsulta.ParamByName('LINEA').AsLargeInt := AEntrega.Linea;
          oConsulta.ParamByName('PROVEEDOR').AsString := AEntrega.Proveedor;
          oConsulta.ParamByName('OBJETO').AsString := AEntrega.Objeto;
          oConsulta.ParamByName('ENVIADO').AsFloat := AEntrega.Enviado;
          oConsulta.ParamByName('RECIBIDO').AsFloat := AEntrega.Recibido;
          oConsulta.ParamByName('INCIDENCIA').AsString := AEntrega.Incidencia;
          oConsulta.ParamByName('USUARIO').AsString := FUsuario;
          if AEntrega.Id > 0 then
          begin
            oConsulta.ParamByName('ID').AsLargeInt := AEntrega.Id;
            oConsulta.ParamByName('REVISION').AsInteger := AEntrega.Revision;
          end;
          oConsulta.Execute;
          if oConsulta.RowsAffected <> 1 then
            raise EArgumentException.Create(SCircuitoConflicto);
          Historial(AEntrega.Orden, AEntrega.Linea, 'EXTERNO',
            Format('%s. %s. Enviado %g. Recibido %g. %s',
            [AEntrega.Proveedor, AEntrega.Objeto, AEntrega.Enviado,
             AEntrega.Recibido, AEntrega.Incidencia]));
        finally
          FreeAndNil(oConsulta);
        end;
      finally
        FreeAndNil(oLinea);
      end;
    end);
end;

end.

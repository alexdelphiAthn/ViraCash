{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoDevolucionesCompraSeleccionVcl                           }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Seleccion visual de empresa y proveedor para devoluciones de compra.      }
{    Trabaja con un contexto estrecho y no conserva el formulario ni el        }
{    modulo de datos.                                                          }
{******************************************************************************}
unit inMtoDevolucionesCompraSeleccionVcl;

interface

uses
  Data.DB,
  Vcl.Controls,
  Uni,
  inLibComprasPantallaIntf,
  inLibGenBusq;

type
  TAccionSeleccionDevolucionCompra = procedure of object;

  TContextoSeleccionDevolucionCompra = record
    Cabecera: TDataSet;
    BusquedaVisual: IBusquedaVisual;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    Conexion: TUniConnection;
    ControlOrigen: TControl;
    RecalcularTotales: TAccionSeleccionDevolucionCompra;
    ActualizarProveedor: TAccionSeleccionDevolucionCompra;
  end;

procedure SeleccionarEmpresaDevolucionCompra(
  const AContexto: TContextoSeleccionDevolucionCompra);
procedure SeleccionarProveedorDevolucionCompra(
  const AContexto: TContextoSeleccionDevolucionCompra);

implementation

uses
  inLibMensajesVcl,
  System.UITypes,
  Vcl.Dialogs,
  Vcl.Forms,
  inLibComprasImpuestos,
  inLibMsgCompras,
  UniDataImpuestosRepositorio;

resourcestring
  STituloBuscarEmpresasDevolucionCompra = 'Búsqueda de empresas';
  STituloBuscarProveedoresDevolucionCompra = 'Búsqueda de proveedores';

function FormularioPadreSeleccion(
  AControl: TControl): TCustomForm;
begin
  Result := nil;
  if Assigned(AControl) then
    Result := GetParentForm(AControl);
end;

procedure SeleccionarEmpresaDevolucionCompra(
  const AContexto: TContextoSeleccionDevolucionCompra);
var
  oConsulta: IConsultaComprasPantalla;
begin
  if Assigned(AContexto.Cabecera) and
     Assigned(AContexto.BusquedaEmpresas) and
     Assigned(AContexto.BusquedaVisual) then
  begin
    if AContexto.Cabecera.IsEmpty then
      MessageDlg_fza(SErrorDevolucionCompraElegirEmpresaNoSeleccionada,
        mtInformation, [mbOk], 0)
    else
    begin
      oConsulta := AContexto.BusquedaEmpresas.ConsultarEmpresas;
      if Assigned(oConsulta) and
         AContexto.BusquedaVisual.EjecutarBusquedaDataSet(
           STituloBuscarEmpresasDevolucionCompra,
           oConsulta.DataSet,
           'frmMtoEmpFacSearch',
           FormularioPadreSeleccion(AContexto.ControlOrigen)) then
      begin
        if not (AContexto.Cabecera.State in dsEditModes) then
          AContexto.Cabecera.Edit;
        AContexto.Cabecera.FieldByName('CODIGO_EMP_DEVC').AsString :=
          oConsulta.DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
      end;
    end;
  end;
end;

procedure SeleccionarProveedorDevolucionCompra(
  const AContexto: TContextoSeleccionDevolucionCompra);
var
  oConsulta: IConsultaComprasPantalla;
begin
  if Assigned(AContexto.Cabecera) and
     Assigned(AContexto.BusquedaProveedores) and
     Assigned(AContexto.BusquedaVisual) then
  begin
    if AContexto.Cabecera.IsEmpty then
      MessageDlg_fza(SErrorDevolucionCompraElegirProveedorNoSeleccionada,
        mtInformation, [mbOk], 0)
    else
    begin
      oConsulta := AContexto.BusquedaProveedores.ConsultarProveedores;
      if Assigned(oConsulta) and
         AContexto.BusquedaVisual.EjecutarBusquedaDataSet(
           STituloBuscarProveedoresDevolucionCompra,
           oConsulta.DataSet,
           'frmMtoDevcProvSearch',
           FormularioPadreSeleccion(AContexto.ControlOrigen)) then
      begin
        if not (AContexto.Cabecera.State in dsEditModes) then
          AContexto.Cabecera.Edit;
        AContexto.Cabecera.FieldByName('CODIGO_PRV_DEVC').AsString :=
          oConsulta.DataSet.FieldByName('CODIGO_PRV_PRV').AsString;
        AplicarIvaExentoIntracomunitarioProveedor(
          CrearLecturasImpuestos(AContexto.Conexion),
          AContexto.Cabecera,
          'CODIGO_PRV_DEVC',
          'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC');
        if Assigned(AContexto.RecalcularTotales) then
          AContexto.RecalcularTotales;
        if Assigned(AContexto.ActualizarProveedor) then
          AContexto.ActualizarProveedor;
      end;
    end;
  end;
end;

end.

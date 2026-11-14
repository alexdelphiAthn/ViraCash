{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataGastoCajaRepositorio                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia transaccional de gastos y retiradas de caja.                 }
{******************************************************************************}
unit UniDataGastoCajaRepositorio;

interface

uses
  Uni, inLibGastoCajaPersistenciaIntf, inLibParametrosIntf,
  inLibPreviewTicket, inLibContextoSesionIntf;

function CrearRepositorioGastoCajaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioGastoCaja;

implementation

uses
  System.SysUtils, UniDataCajaCierreVenta;

type
  TRepositorioGastoCajaUniDAC = class(
    TInterfacedObject,
    IRepositorioGastoCaja)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FPreviewTicket: IPreviewTicket;
    FContextoSesion: IContextoSesionAplicacion;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const APreviewTicket: IPreviewTicket;
      const AContextoSesion: IContextoSesionAplicacion);
    function Registrar(
      const ASolicitud: TSolicitudGastoCaja): string;
  end;

function CrearRepositorioGastoCajaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion
): IRepositorioGastoCaja;
begin
  Result := TRepositorioGastoCajaUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    APreviewTicket,
    AContextoSesion);
end;

constructor TRepositorioGastoCajaUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket;
  const AContextoSesion: IContextoSesionAplicacion);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FPreviewTicket := APreviewTicket;
  FContextoSesion := AContextoSesion;
end;

function TRepositorioGastoCajaUniDAC.Registrar(
  const ASolicitud: TSolicitudGastoCaja): string;
var
  oConsulta: TUniQuery;
  oPersistencia: TPersistenciaCierreVentaCajaUniDAC;
begin
  oPersistencia := TPersistenciaCierreVentaCajaUniDAC.Create(
    FConexion,
    FContextoSesion.Identidad.Usuario);
  try
    Result := oPersistencia.SiguienteOperacion(
      ASolicitud.Empresa,
      ASolicitud.Almacen,
      ASolicitud.Caja,
      ASolicitud.Empleado);
    oPersistencia.IniciarUnidadTrabajo;
    try
      oConsulta := oPersistencia.CrearConsulta;
      try
        oPersistencia.GuardarOperacion(
          oConsulta,
          ASolicitud.Empresa,
          ASolicitud.Almacen,
          ASolicitud.Caja,
          Result,
          'GC',
          ASolicitud.Importe,
          ASolicitud.Empleado,
          ASolicitud.FechaOperacion,
          '',
          '',
          '',
          ASolicitud.Concepto);
        oPersistencia.GuardarPago(
          oConsulta,
          ASolicitud.Empresa,
          ASolicitud.Almacen,
          ASolicitud.Caja,
          '',
          Result,
          1,
          'EFE',
          ASolicitud.Importe,
          0);
      finally
        FreeAndNil(oConsulta);
      end;
      oPersistencia.ConfirmarUnidadTrabajo;
    except
      oPersistencia.RevertirUnidadTrabajo;
      raise;
    end;
  finally
    FreeAndNil(oPersistencia);
  end;
end;

end.

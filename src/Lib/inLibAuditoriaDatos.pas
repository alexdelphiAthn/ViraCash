{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAuditoriaDatos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio que completa los campos estándar de auditoría de un dataset.     }
{******************************************************************************}
unit inLibAuditoriaDatos;

interface

uses
  Data.DB,
  inLibAuditoriaDatosIntf,
  inLibContextoSesionIntf;

type
  TServicioAuditoriaDatos = class(
    TInterfacedObject,
    IServicioAuditoriaDatos
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    procedure AsignarFechaAuditoria(
      ACampo: TField;
      AValor: TDateTime);
    procedure AsignarTextoAuditoria(
      ACampo: TField;
      const AValor: string);
    function GetUsuario: string;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion
    ); overload;
    constructor Create(const AUsuario: string); overload;
    procedure Actualizar(DataSet: TDataSet);
  end;

implementation

uses
  System.SysUtils,
  inLibContextoSesion;

procedure TServicioAuditoriaDatos.AsignarFechaAuditoria(
  ACampo: TField;
  AValor: TDateTime);
var
  EraSoloLectura: Boolean;
begin
  if Assigned(ACampo) then
  begin
    EraSoloLectura := ACampo.ReadOnly;
    ACampo.ReadOnly := False;
    try
      ACampo.AsDateTime := AValor;
    finally
      ACampo.ReadOnly := EraSoloLectura;
    end;
  end;
end;

procedure TServicioAuditoriaDatos.AsignarTextoAuditoria(
  ACampo: TField;
  const AValor: string);
var
  EraSoloLectura: Boolean;
begin
  if Assigned(ACampo) then
  begin
    EraSoloLectura := ACampo.ReadOnly;
    ACampo.ReadOnly := False;
    try
      ACampo.AsString := AValor;
    finally
      ACampo.ReadOnly := EraSoloLectura;
    end;
  end;
end;

constructor TServicioAuditoriaDatos.Create(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  inherited Create;
  FContextoSesion := AContextoSesion;
end;

constructor TServicioAuditoriaDatos.Create(const AUsuario: string);
begin
  Create(
    TContextoSesionAplicacion.Create(
      TIdentidadSesion.Crear(AUsuario, '', ''),
      TUbicacionSesion.Crear('', '', '')));
end;

function TServicioAuditoriaDatos.GetUsuario: string;
begin
  Result := '';
  if Assigned(FContextoSesion) then
    Result := FContextoSesion.Identidad.Usuario;
end;

procedure TServicioAuditoriaDatos.Actualizar(DataSet: TDataSet);
var
  Campo: TField;
  Usuario: string;
begin
  Usuario := GetUsuario;
  if Assigned(DataSet) and
     (DataSet.State in dsEditModes) then
  begin
    Campo := DataSet.FindField('USUARIO_MODIF');
    AsignarTextoAuditoria(Campo, Usuario);
    Campo := DataSet.FindField('INSTANTE_MODIF');
    AsignarFechaAuditoria(Campo, Now);
    if DataSet.State = dsInsert then
    begin
      Campo := DataSet.FindField('INSTANTE_ALTA');
      AsignarFechaAuditoria(Campo, Now);
      Campo := DataSet.FindField('USUARIO_ALTA');
      AsignarTextoAuditoria(Campo, Usuario);
    end;
  end;
end;

end.

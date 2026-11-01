{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosGuardado                                        }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina las capacidades que deben persistirse al grabar un articulo.     }
{******************************************************************************}
unit inLibArticulosGuardado;

interface

uses
  inLibArticulosGuardadoIntf, inLibPerfilesUsuarioIntf;

function CrearAplicacionGuardadoArticulo(
  const AOperaciones: IOperacionesGuardadoArticulo):
  IAplicacionGuardadoArticulo;

procedure ValidarDatosBasicosArticulo(const ANombre, AFamilia: string;
  const APerfiles: ILectorPerfilesUsuario;
  AExigirFamilia: Boolean = True);

implementation

uses
  System.SysUtils, inLibCadenas, inLibMsgArticulos;

type
  TAplicacionGuardadoArticulo = class(
    TInterfacedObject,
    IAplicacionGuardadoArticulo)
  private
    FOperaciones: IOperacionesGuardadoArticulo;
  public
    constructor Create(
      const AOperaciones: IOperacionesGuardadoArticulo);
    function Ejecutar: TResultadoGuardadoArticulo;
  end;

procedure ValidarDatosBasicosArticulo(const ANombre, AFamilia: string;
  const APerfiles: ILectorPerfilesUsuario;
  AExigirFamilia: Boolean);
var
  Simbolo: string;
begin
  if Trim(ANombre) = '' then
    raise EValidacionDatosArticulo.Create(cvaNombre,
      SErrorNombreArticuloVacio);
  Simbolo := PrimerSimboloProhibido(ANombre, APerfiles, ',/()');
  if Simbolo <> '' then
    raise EValidacionDatosArticulo.Create(cvaNombre,
      Format(SErrorSimboloNombreArticulo, [Simbolo]));
  if AExigirFamilia and (Trim(AFamilia) = '') then
    raise EValidacionDatosArticulo.Create(cvaFamilia,
      SErrorFamiliaArticuloObligatoria);
end;

constructor TAplicacionGuardadoArticulo.Create(
  const AOperaciones: IOperacionesGuardadoArticulo);
begin
  inherited Create;
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  FOperaciones := AOperaciones;
end;

function TAplicacionGuardadoArticulo.Ejecutar:
  TResultadoGuardadoArticulo;
var
  sMensaje: string;
begin
  Result := Default(TResultadoGuardadoArticulo);
  sMensaje := FOperaciones.ValidarPropiedades;
  if sMensaje <> '' then
  begin
    Result.Error := egaRevisionPropiedades;
    Result.Mensaje := sMensaje;
  end;
  if Result.Error = egaNinguno then
  begin
    if not FOperaciones.GuardarPropiedades(sMensaje) then
    begin
      Result.Error := egaGuardadoPropiedades;
      Result.Mensaje := sMensaje;
    end;
  end;
  if Result.Error = egaNinguno then
    FOperaciones.GuardarEdicionesPendientes;
  if Result.Error = egaNinguno then
  begin
    if not FOperaciones.GuardarVariaciones(sMensaje) then
    begin
      Result.Error := egaGuardadoVariaciones;
      Result.Mensaje := sMensaje;
    end;
  end;
end;

function CrearAplicacionGuardadoArticulo(
  const AOperaciones: IOperacionesGuardadoArticulo):
  IAplicacionGuardadoArticulo;
begin
  Result := TAplicacionGuardadoArticulo.Create(AOperaciones);
end;

end.

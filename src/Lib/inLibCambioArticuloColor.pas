{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCambioArticuloColor                                      }
{    Tipo:       Servicio de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida las solicitudes de recodificación antes de persistirlas.           }
{******************************************************************************}
unit inLibCambioArticuloColor;

interface

uses
  inLibCambioArticuloColorIntf;

function CrearServicioCambioArticuloColor(
  const ARepositorio: IRepositorioCambioArticuloColor):
  IServicioCambioArticuloColor;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorOperacionHistoricaInvalida =
    'Debe indicar una operación histórica válida.';

const
  LONGITUD_MAXIMA_ARTICULO = 20;
  LONGITUD_MAXIMA_COLOR = 100;
  LONGITUD_MAXIMA_USUARIO_AUDITORIA = 50;
  SEPARADOR_SKU = '/';

type
  TServicioCambioArticuloColor = class(
    TInterfacedObject,
    IServicioCambioArticuloColor)
  private
    FRepositorio: IRepositorioCambioArticuloColor;
    function DatosValidos(
      const AAnterior, ANuevo, AUsuario: string;
      ALongitudMaxima: Integer): Boolean;
  public
    constructor Create(
      const ARepositorio: IRepositorioCambioArticuloColor);
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function RevertirOperacion(
      const AIdOperacion, AUsuario: string):
      TResultadoReversionHistorico;
  end;

constructor TServicioCambioArticuloColor.Create(
  const ARepositorio: IRepositorioCambioArticuloColor);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TServicioCambioArticuloColor.DatosValidos(
  const AAnterior, ANuevo, AUsuario: string;
  ALongitudMaxima: Integer): Boolean;
begin
  Result := (AAnterior <> '') and
            (ANuevo <> '') and
            (AUsuario <> '') and
            (Length(AAnterior) <= ALongitudMaxima) and
            (Length(ANuevo) <= ALongitudMaxima) and
            (not SameText(AAnterior, ANuevo)) and
            (Pos(SEPARADOR_SKU, AAnterior) = 0) and
            (Pos(SEPARADOR_SKU, ANuevo) = 0);
end;

function TServicioCambioArticuloColor.CambiarArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
var
  sAnterior: string;
  sNuevo: string;
  sUsuario: string;
begin
  sAnterior := Trim(AArticuloAntiguo);
  sNuevo := Trim(AArticuloNuevo);
  sUsuario := Copy(
    Trim(AUsuario),
    1,
    LONGITUD_MAXIMA_USUARIO_AUDITORIA);
  if DatosValidos(
       sAnterior,
       sNuevo,
       sUsuario,
       LONGITUD_MAXIMA_ARTICULO) then
  begin
    Result := FRepositorio.CambiarArticulo(
      sAnterior,
      sNuevo,
      sUsuario);
  end
  else
  begin
    Result := TResultadoCambioArticuloColor.Error(mcacDatosInvalidos);
  end;
end;

function TServicioCambioArticuloColor.CambiarColor(
  const AColorAntiguo, AColorNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
var
  sAnterior: string;
  sNuevo: string;
  sUsuario: string;
begin
  sAnterior := Trim(AColorAntiguo);
  sNuevo := Trim(AColorNuevo);
  sUsuario := Copy(
    Trim(AUsuario),
    1,
    LONGITUD_MAXIMA_USUARIO_AUDITORIA);
  if DatosValidos(
       sAnterior,
       sNuevo,
       sUsuario,
       LONGITUD_MAXIMA_COLOR) then
  begin
    Result := FRepositorio.CambiarColor(
      sAnterior,
      sNuevo,
      sUsuario);
  end
  else
  begin
    Result := TResultadoCambioArticuloColor.Error(mcacDatosInvalidos);
  end;
end;

function TServicioCambioArticuloColor.FusionarArticulo(
  const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
var
  sAnterior: string;
  sDestino: string;
  sUsuario: string;
begin
  sAnterior := Trim(AArticuloAntiguo);
  sDestino := Trim(AArticuloDestino);
  sUsuario := Copy(
    Trim(AUsuario),
    1,
    LONGITUD_MAXIMA_USUARIO_AUDITORIA);
  if DatosValidos(
       sAnterior,
       sDestino,
       sUsuario,
       LONGITUD_MAXIMA_ARTICULO) then
  begin
    Result := FRepositorio.FusionarArticulo(
      sAnterior,
      sDestino,
      sUsuario);
  end
  else
  begin
    Result := TResultadoCambioArticuloColor.Error(mcacDatosInvalidos);
  end;
end;

function TServicioCambioArticuloColor.FusionarColor(
  const AColorAntiguo, AColorDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
var
  sAnterior: string;
  sDestino: string;
  sUsuario: string;
begin
  sAnterior := Trim(AColorAntiguo);
  sDestino := Trim(AColorDestino);
  sUsuario := Copy(
    Trim(AUsuario),
    1,
    LONGITUD_MAXIMA_USUARIO_AUDITORIA);
  if DatosValidos(
       sAnterior,
       sDestino,
       sUsuario,
       LONGITUD_MAXIMA_COLOR) then
  begin
    Result := FRepositorio.FusionarColor(
      sAnterior,
      sDestino,
      sUsuario);
  end
  else
  begin
    Result := TResultadoCambioArticuloColor.Error(mcacDatosInvalidos);
  end;
end;

function TServicioCambioArticuloColor.RevertirOperacion(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
var
  sIdOperacion: string;
  sUsuario: string;
begin
  sIdOperacion := Trim(AIdOperacion);
  sUsuario := Copy(
    Trim(AUsuario),
    1,
    LONGITUD_MAXIMA_USUARIO_AUDITORIA);
  if (Length(sIdOperacion) = 36) and (sUsuario <> '') then
    Result := FRepositorio.RevertirOperacion(sIdOperacion, sUsuario)
  else
  begin
    Result := TResultadoReversionHistorico.Error(
      crhNoEncontrada,
      SErrorOperacionHistoricaInvalida);
  end;
end;

function CrearServicioCambioArticuloColor(
  const ARepositorio: IRepositorioCambioArticuloColor):
  IServicioCambioArticuloColor;
begin
  Result := TServicioCambioArticuloColor.Create(ARepositorio);
end;

end.

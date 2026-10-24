{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataAppParamGrupoUsuarioConsulta                           }
{    Tipo:       Consulta UniDAC                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta el grupo asignado a un usuario sin exponer detalles UniDAC       }
{    al formulario de parametros de aplicacion.                                }
{******************************************************************************}
unit UniDataAppParamGrupoUsuarioConsulta;

interface

uses
  Uni;

function ConsultarGrupoUsuarioUniDAC(
  AConexion: TUniConnection;
  const AUsuario: string): string;

implementation

uses
  System.SysUtils;

function ConsultarGrupoUsuarioUniDAC(
  AConexion: TUniConnection;
  const AUsuario: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT GRUPO_USU FROM fza_usuarios ' +
      'WHERE USUARIO_USU = :USUARIO';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Open;
    if not oConsulta.Eof then
      Result := Trim(oConsulta.FieldByName('GRUPO_USU').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

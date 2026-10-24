{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesUsuarioIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos segregados para los perfiles de usuario.                        }
{******************************************************************************}
unit inLibPerfilesUsuarioIntf;

interface

uses
  System.Generics.Collections;

const
  PERFIL_TODOS = 'Todos';

type
  TDictValue = record
    sValue: string;
    sValueText: WideString;
  end;

  TProfileDicc = TDictionary<string, TDictValue>;

  TPerfilItem = record
    UserGroup: string;
    KeyPerfil: string;
    SubKey: string;
    Value: string;
  end;

  TPerfilList = TList<TPerfilItem>;

  ILectorPerfilesUsuario = interface
    ['{76B2E17F-A962-4F37-8C33-72F44C8B63D7}']
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
  end;

  IEscritorPerfilesUsuario = interface
    ['{1EC5C995-D03E-43CA-AC71-DE5E45F7D399}']
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
  end;

  ICachePerfilesUsuario = interface
    ['{E3DA791F-90CF-4BFA-81FD-4B0BFF4FABCC}']
    procedure PrecargarPerfilesUsuario;
    procedure ResincronizarPerfilFormulario(const AFormulario: string);
    procedure ActualizarPerfilFormulario(const AFormulario: string;
      APerfil: TProfileDicc);
    procedure InvalidarCachePerfiles;
  end;

  TServiciosPerfilesUsuario = record
    Lectura: ILectorPerfilesUsuario;
    Escritura: IEscritorPerfilesUsuario;
    Cache: ICachePerfilesUsuario;
  end;

  IProveedorPerfilesUsuario = interface
    ['{5D4A522A-54B3-40E5-A388-790D59C8E12E}']
    function GetServiciosPerfilesUsuario: TServiciosPerfilesUsuario;
    property ServiciosPerfilesUsuario: TServiciosPerfilesUsuario
      read GetServiciosPerfilesUsuario;
  end;

function CrearServiciosPerfilesUsuario(
  const ALectura: ILectorPerfilesUsuario;
  const AEscritura: IEscritorPerfilesUsuario;
  const ACache: ICachePerfilesUsuario
): TServiciosPerfilesUsuario;

implementation

function CrearServiciosPerfilesUsuario(
  const ALectura: ILectorPerfilesUsuario;
  const AEscritura: IEscritorPerfilesUsuario;
  const ACache: ICachePerfilesUsuario
): TServiciosPerfilesUsuario;
begin
  Result.Lectura := ALectura;
  Result.Escritura := AEscritura;
  Result.Cache := ACache;
end;

end.

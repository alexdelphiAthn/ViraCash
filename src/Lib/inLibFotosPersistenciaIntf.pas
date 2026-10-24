{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosPersistenciaIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del subsistema de fotos.                           }
{******************************************************************************}
unit inLibFotosPersistenciaIntf;

interface

uses
  System.SysUtils,
  inLibFotosSesionPersistenciaIntf;

type
  TMetadatosFotoPersistida = record
    CodigoArticulo: string;
    CodigoUnidad: string;
    Orden: Integer;
    Nombre: string;
    Extension: string;
  end;
  IRepositorioConsultaFotos = interface
    ['{B7EF7B91-B01C-4B36-8D89-121B2E2628AF}']
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>):
      TArray<TMetadatosFotoPersistida>;
    function BuscarFotosColeccion(
      const ACodigoArticulo, ACodigoUnidad: string):
      TArray<TMetadatosFotoPersistida>;
    function BuscarFotosVariaciones(
      const ACodigoArticulo: string):
      TArray<TMetadatosFotoPersistida>;
  end;
  IRepositorioEdicionFotos = interface
    ['{CE045E9E-16D8-4F75-A72D-08F142690E9A}']
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotosEditables(
      const ACodigoArticulo, ACodigoUnidad: string):
      TArray<TMetadatosFotoPersistida>;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const ANombreAnterior, AUsuario: string);
    procedure AnadirFoto(
      var AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreAnterior, ANombre, AUsuario: string);
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreEsperado: string);
    procedure MarcarFotoPredeterminada(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrdenEsperado: Integer;
      const ANombreEsperado, AUsuario: string);
  end;
  TRepositoriosFotos = record
    Consulta: IRepositorioConsultaFotos;
    Edicion: IRepositorioEdicionFotos;
    Sesion: IRepositorioSesionFotos;
  end;
implementation
end.

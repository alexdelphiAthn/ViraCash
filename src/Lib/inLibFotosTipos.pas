{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosTipos                                               }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos y contrato de lectura compartidos por el servicio de fotografías.  }
{******************************************************************************}
unit inLibFotosTipos;

interface

uses
  Data.DB;

const
  fcodartfot = 'CODIGO_ART_FOT';
  fcodunidadfot = 'CODIGO_UNIDAD_FOT';
  fordenfot = 'ORDEN_FOT';
  fnomfot = 'NOMBRE_FOT_FOT';
  fextfot = 'EXTENSION_ORIGEN_FOT';
  finstalta = 'INSTANTE_ALTA';
  finstmodif = 'INSTANTE_MODIF';
  fusralta = 'USUARIO_ALTA';
  fusrmodif = 'USUARIO_MODIF';
  cSubdir300 = '300';
  cSubdir600 = '600';
  cSubdirReal = 'real';
  cLado300 = 300;
  cLado600 = 600;

type
  TFotoResolucion = (frPx300, frPx600, frReal);
  TFotoOrigen = (foSinFoto, foArticulo, foSkuPrefijo, foSku);

  TFotoInfo = record
    Encontrada      : Boolean;
    Origen          : TFotoOrigen;
    CodigoArt       : string;
    CodigoSku       : string;
    ClaveResuelta   : string;
    Orden           : Integer;
    NombreBase      : string;
    ExtensionOrigen : string;
    procedure Clear;
  end;

  TProveedorFotosPresentacion = class abstract
  public
    function Resolver(const ACodigoArticulo,
      ACodigoSku: string): TFotoInfo; virtual; abstract;
    function RutaFoto(const AInfo: TFotoInfo;
      AResolucion: TFotoResolucion): string; virtual; abstract;
    procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
      out ACodigoArticulo, ACodigoSku: string); virtual; abstract;
  end;

implementation

procedure TFotoInfo.Clear;
begin
  Encontrada := False;
  Origen := foSinFoto;
  CodigoArt := '';
  CodigoSku := '';
  ClaveResuelta := '';
  Orden := 0;
  NombreBase := '';
  ExtensionOrigen := '';
end;

end.

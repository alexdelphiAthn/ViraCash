{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesColores                                }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve y persiste colores al materializar sesiones de compra.           }
{******************************************************************************}
unit UniDataComprasSesionesColores;

interface

uses
  Uni,
  inLibComprasSesionesLecturasIntf;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, AColorTexto, ACodigoAtbColor,
    AUsuario: string;
  out AValor: string): Integer; overload;
function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, AColorTexto, ACodigoAtbColor,
    AUsuario: string;
  out AValor: string;
  out AIdColorBasico: Integer): Integer; overload;
// Valor de pestañas (la copa) de una línea: el ID_AV del atributo de
// pestañas del tipo de variación del artículo, que se crea si no existe.
// 0 sin texto. Con texto y un tipo sin pestañas lanza EValidacionBBDD.
// AValor es el valor tal como entra en el código del SKU.
function ResolverIdAvPestanaLinea(
  AConn: TUniConnection;
  const ACodigoArticulo, ATexto, AUsuario: string;
  out AValor: string): Integer;

implementation

uses
  System.SysUtils,
  inLibCodigosSinBarra,
  inLibComprasSesionesReglas,
  inLibMsgCompras,
  inLibErroresBBDD,
  UniDataAtributosSkuEnlace,
  UniDataEjesVariacion;

function ResolverIdColorBasico(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoAtbColor: string): Integer;
begin
  Result := 0;
  if Trim(ACodigoAtbColor) <> '' then
  begin
    Result := ALecturas.ObtenerIdColorBasico(ACodigoAtbColor);
    if Result = 0 then
      raise Exception.CreateFmt(
        SErrorColorBasicoMaterializacionNoExiste,
        [ACodigoAtbColor]);
  end;
end;

function BuscarValorColor(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, AValor: string;
  out ATieneColorBasico: Boolean;
  out AIdColorBasico: Integer): Integer;
var
  oValor: TValorColorMaterializacion;
begin
  oValor := ALecturas.BuscarValorColor(
    ACodigoArticulo,
    AValor);
  Result := oValor.IdValor;
  ATieneColorBasico := oValor.TieneColorBasico;
  AIdColorBasico := oValor.IdColorBasico;
end;

procedure AsignarColorBasicoAValor(
  AQuery: TUniQuery;
  AIdValor, AIdColorBasico: Integer);
begin
  AQuery.SQL.Text :=
    'UPDATE fza_atributos_valores ' +
    '   SET ID_ATB_AV = :ia ' +
    ' WHERE ID_AV = :idav';
  AQuery.ParamByName('ia').AsInteger := AIdColorBasico;
  AQuery.ParamByName('idav').AsInteger := AIdValor;
  AQuery.ExecSQL;
end;

function CrearValorColor(
  AQuery: TUniQuery;
  const AArticulo, AValor, ADescripcion, AUsuario: string;
  AIdColorBasico: Integer): Integer;
begin
  Result := AsegurarValorAtributoNormalizado(AQuery,
    ObtenerAtributoEjeArticulo(AQuery.Connection, AArticulo,
      EJE_VARIACION_FILA), AValor, ADescripcion, AUsuario,
    0, AIdColorBasico);
end;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, AColorTexto, ACodigoAtbColor,
    AUsuario: string;
  out AValor: string): Integer;
var
  iIdColorBasico: Integer;
begin
  Result := ResolverIdAvColorLinea(
    AConn,
    ALecturas,
    ACodigoArticulo,
    AColorTexto,
    ACodigoAtbColor,
    AUsuario,
    AValor,
    iIdColorBasico);
end;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, AColorTexto, ACodigoAtbColor,
    AUsuario: string;
  out AValor: string;
  out AIdColorBasico: Integer): Integer;
var
  q                 : TUniQuery;
  sValor            : string;
  iIdColorGlobal    : Integer;
  bTieneColorBasico : Boolean;
begin
  Result := 0;
  AValor := '';
  AIdColorBasico := 0;
  // El texto del maestro conserva espacios; solo el código SKU se sanea.
  sValor := SinBarraSku(AColorTexto);
  if SanearColorSku(sValor) = '' then
    sValor := SinBarraSku(ACodigoAtbColor);
  if (sValor <> '') and
     (ObtenerAtributoEjeArticulo(AConn, ACodigoArticulo,
       EJE_VARIACION_FILA) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      AIdColorBasico :=
        ResolverIdColorBasico(ALecturas, ACodigoAtbColor);
      Result := BuscarValorColor(
        ALecturas, ACodigoArticulo, sValor, bTieneColorBasico,
        iIdColorGlobal);
      // Las lecturas comparan con SanearColorSku: el texto del maestro
      // y el token de una línea ya grabada resuelven el mismo ID_AV.
      if AIdColorBasico = 0 then
        AIdColorBasico := iIdColorGlobal;
      if Result = 0 then
        Result := CrearValorColor(
          q, ACodigoArticulo, sValor, AColorTexto, AUsuario,
          AIdColorBasico)
      else if (not bTieneColorBasico) and
              (AIdColorBasico > 0) then
        AsignarColorBasicoAValor(
          q, Result, AIdColorBasico);
      if Result > 0 then
        AValor := SanearColorSku(sValor);
    finally
      FreeAndNil(q);
    end;
  end;
end;

function ResolverIdAvPestanaLinea(
  AConn: TUniConnection;
  const ACodigoArticulo, ATexto, AUsuario: string;
  out AValor: string): Integer;
var
  q: TUniQuery;
  sAtributo: string;
  sValor: string;
begin
  Result := 0;
  AValor := '';
  sValor := SinBarraSku(Trim(ATexto));
  if sValor <> '' then
  begin
    sAtributo := ObtenerAtributoEjeArticulo(AConn, ACodigoArticulo,
      EJE_VARIACION_PESTANA);
    if sAtributo = '' then
      raise EValidacionBBDD.CreateFmt(SErrorPestanaLineaSinEjeVariacion,
        [sValor, ACodigoArticulo]);
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      Result := AsegurarValorAtributoNormalizado(q, sAtributo, sValor,
        Trim(ATexto), AUsuario, 0, 0);
      AValor := sValor;
    finally
      FreeAndNil(q);
    end;
  end;
end;

end.

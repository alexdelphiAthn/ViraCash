{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosAtributosBasicos                               }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta los atributos básicos de SKU sin conocer VCL, UniDAC ni SQL.     }
{******************************************************************************}
unit inLibArticulosAtributosBasicos;

interface

uses
  inLibArticulosAtributosBasicosIntf;

type
  TGestorAtributosBasicosSku = class(
    TInterfacedObject,
    IGestorAtributosBasicosSku)
  private
    FRepositorio: IRepositorioAtributosBasicosSku;
  public
    constructor Create(
      const ARepositorio: IRepositorioAtributosBasicosSku);
    function BuscarCodigoActivo(
      const AIdVariacion, ATexto: string;
      out ACodigo: string): Boolean;
    function CrearAtributoBasico(
      const AContexto: TContextoAtributoBasicoSku;
      const ANombre: string;
      AAmbito: TAmbitoAtributoBasico): string;
    function AsegurarValorSku(
      const AContexto: TContextoAtributoBasicoSku): Integer;
    function AsegurarBasico(
      const AContexto: TContextoAtributoBasicoSku;
      AAmbito: TAmbitoAtributoBasico): Integer;
    procedure GuardarOverride(
      const AContexto: TContextoAtributoBasicoSku;
      const AIdBasico: TEnteroOpcional);
    procedure ActualizarNombre(
      AIdBasico: Integer;
      const ANombre, AUsuario: string);
    procedure ActualizarValorNumerico(
      AIdBasico: Integer;
      const AValor: TRealOpcional;
      const AUsuario: string);
    procedure ActualizarUnidad(
      AIdBasico: Integer;
      const AUnidad, AUsuario: string);
    procedure GuardarDescripcion(
      const AContexto: TContextoAtributoBasicoSku;
      const AIdBasico: TEnteroOpcional;
      const ADescripcion: TCadenaOpcional);
    procedure ActualizarHex(
      AIdBasico: Integer;
      const AHex, AUsuario: string);
  end;

function ComponerCodigoAtributoBasico(
  AAmbito: TAmbitoAtributoBasico;
  const ACodigoArticulo, ANombre: string): string;

implementation

uses
  System.SysUtils;

function ComponerCodigoAtributoBasico(
  AAmbito: TAmbitoAtributoBasico;
  const ACodigoArticulo, ANombre: string): string;
const
  MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO = 100;
var
  sNombreNormalizado: string;
begin
  sNombreNormalizado := StringReplace(
    ANombre, ' ', '_', [rfReplaceAll]);
  if AAmbito = aabAdHoc then
    Result := Format(
      'AD_%s_%s', [ACodigoArticulo, sNombreNormalizado])
  else
    Result := sNombreNormalizado;
  if Length(Result) > MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO then
    Result := Copy(Result, 1, MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO);
end;

constructor TGestorAtributosBasicosSku.Create(
  const ARepositorio: IRepositorioAtributosBasicosSku);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TGestorAtributosBasicosSku.BuscarCodigoActivo(
  const AIdVariacion, ATexto: string;
  out ACodigo: string): Boolean;
begin
  Result := FRepositorio.BuscarCodigoActivo(
    AIdVariacion,
    ATexto,
    ACodigo);
end;

function TGestorAtributosBasicosSku.CrearAtributoBasico(
  const AContexto: TContextoAtributoBasicoSku;
  const ANombre: string;
  AAmbito: TAmbitoAtributoBasico): string;
begin
  Result := ComponerCodigoAtributoBasico(
    AAmbito,
    AContexto.CodigoArticulo,
    ANombre);
  if FRepositorio.AsegurarAtributoBasico(
       AContexto.IdVariacion,
       Result,
       ANombre,
       AContexto.Usuario) = 0 then
    Result := '';
end;

function TGestorAtributosBasicosSku.AsegurarValorSku(
  const AContexto: TContextoAtributoBasicoSku): Integer;
begin
  Result := AContexto.IdValor;
  if Result = 0 then
    Result := FRepositorio.AsegurarValorSku(
      AContexto.CodigoSku,
      AContexto.IdVariacion,
      AContexto.ValorAtributo,
      AContexto.Usuario);
end;

function TGestorAtributosBasicosSku.AsegurarBasico(
  const AContexto: TContextoAtributoBasicoSku;
  AAmbito: TAmbitoAtributoBasico): Integer;
var
  iIdValor: Integer;
  sCodigo: string;
begin
  Result := 0;
  iIdValor := AsegurarValorSku(AContexto);
  if (iIdValor > 0) and
     (AContexto.CodigoArticulo <> '') and
     (AContexto.IdVariacion <> '') then
  begin
    if Trim(AContexto.ValorAtributo) = '' then
      sCodigo := Format(
        'AD_%s_%d',
        [AContexto.CodigoArticulo, iIdValor])
    else
      sCodigo := ComponerCodigoAtributoBasico(
        AAmbito,
        AContexto.CodigoArticulo,
        AContexto.ValorAtributo);
    Result := FRepositorio.AsegurarAtributoBasico(
      AContexto.IdVariacion,
      sCodigo,
      AContexto.ValorAtributo,
      AContexto.Usuario);
    if Result > 0 then
      FRepositorio.GuardarOverride(
        AContexto.CodigoArticulo,
        iIdValor,
        EnteroConValor(Result),
        AContexto.Usuario);
  end;
end;

procedure TGestorAtributosBasicosSku.GuardarOverride(
  const AContexto: TContextoAtributoBasicoSku;
  const AIdBasico: TEnteroOpcional);
var
  iIdValor: Integer;
begin
  iIdValor := AsegurarValorSku(AContexto);
  if (AContexto.CodigoArticulo <> '') and
     (iIdValor > 0) then
    FRepositorio.GuardarOverride(
      AContexto.CodigoArticulo,
      iIdValor,
      AIdBasico,
      AContexto.Usuario);
end;

procedure TGestorAtributosBasicosSku.ActualizarNombre(
  AIdBasico: Integer;
  const ANombre, AUsuario: string);
begin
  if AIdBasico > 0 then
    FRepositorio.ActualizarNombre(
      AIdBasico,
      ANombre,
      AUsuario);
end;

procedure TGestorAtributosBasicosSku.ActualizarValorNumerico(
  AIdBasico: Integer;
  const AValor: TRealOpcional;
  const AUsuario: string);
begin
  if AIdBasico > 0 then
    FRepositorio.ActualizarValorNumerico(
      AIdBasico,
      AValor,
      AUsuario);
end;

procedure TGestorAtributosBasicosSku.ActualizarUnidad(
  AIdBasico: Integer;
  const AUnidad, AUsuario: string);
begin
  if AIdBasico > 0 then
    FRepositorio.ActualizarUnidad(
      AIdBasico,
      AUnidad,
      AUsuario);
end;

procedure TGestorAtributosBasicosSku.GuardarDescripcion(
  const AContexto: TContextoAtributoBasicoSku;
  const AIdBasico: TEnteroOpcional;
  const ADescripcion: TCadenaOpcional);
var
  iIdValor: Integer;
begin
  iIdValor := AsegurarValorSku(AContexto);
  if (AContexto.CodigoArticulo <> '') and
     (iIdValor > 0) then
    FRepositorio.GuardarDescripcion(
      AContexto.CodigoArticulo,
      iIdValor,
      AIdBasico,
      ADescripcion,
      AContexto.Usuario);
end;

procedure TGestorAtributosBasicosSku.ActualizarHex(
  AIdBasico: Integer;
  const AHex, AUsuario: string);
begin
  if AIdBasico > 0 then
    FRepositorio.ActualizarHex(
      AIdBasico,
      AHex,
      AUsuario);
end;

end.

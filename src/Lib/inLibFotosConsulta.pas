{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosConsulta                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y resolución jerárquica de fotografías de artículos y SKU.      }
{******************************************************************************}
unit inLibFotosConsulta;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni,
  inLibArticulosValidadorIntf, inLibFotosPersistenciaIntf,
  inLibFotosTipos;

type
  TConsultaFotos = class
  private
    FConexion   : TUniConnection;
    FValidador  : IArticulosValidador;
    FRepositorio: IRepositorioConsultaFotos;
    FCache      : TDictionary<string, TFotoInfo>;
    procedure CompletarSkuDesdeCodigoBarras(ADataSet: TDataSet;
      var ACodigoArticulo, ACodigoSku: string);
  public
    destructor Destroy; override;
    procedure AsignarServicios(AConexion: TUniConnection;
      const AValidador: IArticulosValidador;
      const ARepositorio: IRepositorioConsultaFotos);
    procedure LiberarServicios;
    function Resolver(const ACodigoArticulo,
      ACodigoSku: string): TFotoInfo;
    function ResolverColeccion(const ACodigoArticulo,
      ACodigoSku: string): TArray<TFotoInfo>;
    function ResolverFotosVariaciones(
      const ACodigoArticulo: string): TArray<TFotoInfo>;
    function ResolverArticulosLote(
      const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;
    procedure PrecargarFotosLote(const ACodigos: TArray<string>);
    procedure LimpiarPrecargaFotos;
    procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
      out ACodigoArticulo, ACodigoSku: string);
    property Validador: IArticulosValidador read FValidador;
  end;

function GenerarPrefijosSku(const ACodigoSku: string): TArray<string>;
procedure LeerArtSkuBasicoDeDataSet(ADataSet: TDataSet;
  out ACodigoArticulo, ACodigoSku: string);

implementation

const
  cAliasArt: array[0..20] of string = (
    'CODIGO_ART_ART', 'CODIGO_ART_FAC', 'CODIGO_ART_FACLIN',
    'CODIGO_ART_LIN', 'CODIGO_ART_SKU', 'CODIGO_ART_PEDLIN',
    'CODIGO_ART_ALBLIN', 'CODIGO_ART_PRELIN',
    'CODIGO_ART_ARTTAR', 'CODIGO_ART_AAB',
    'CODIGO_ART_ALBCLIN', 'CODIGO_ART_PEDCLIN',
    'CODIGO_ART_FACCLIN', 'CODIGO_ART_DEVCLIN',
    'CODIGO_ART_INVLIN', 'CODIGO_ART_MOV', 'CODIGO_ART_DEP',
    'CODIGO_ART_DTL', 'CODIGO_ART_TENTATIVO_SESLIN',
    'CODIGO_ART', 'CODIGO_ARTICULO');
  cAliasSku: array[0..16] of string = (
    'CODIGO_UNIDAD_SKU', 'CODIGO_UNIDAD_FAC',
    'CODIGO_UNIDAD_FACLIN', 'CODIGO_UNIDAD_LIN',
    'CODIGO_UNIDAD_PEDLIN', 'CODIGO_UNIDAD_ALBLIN',
    'CODIGO_UNIDAD_PRELIN',
    'CODIGO_UNIDAD_ALBCLIN', 'CODIGO_UNIDAD_PEDCLIN',
    'CODIGO_UNIDAD_FACCLIN', 'CODIGO_UNIDAD_DEVCLIN',
    'CODIGO_UNIDAD_ARTTAR', 'CODIGO_UNIDAD_INVLIN',
    'CODIGO_UNIDAD_MOV', 'CODIGO_UNIDAD_DEP', 'CODIGO_UNIDAD_DTL',
    'CODIGO_UNIDAD');
  cAliasCodBarras: array[0..0] of string = (
    'CODBAR_ART_PEDLIN');

function GenerarPrefijosSku(const ACodigoSku: string): TArray<string>;
var
  sActual   : string;
  sPrefijo  : string;
  iSeparador: Integer;
  bContinuar: Boolean;
begin
  SetLength(Result, 0);
  if ACodigoSku <> '' then
  begin
    Result := Result + [ACodigoSku];
    sActual := ACodigoSku;
    bContinuar := True;
    while bContinuar do
    begin
      iSeparador := LastDelimiter('/', sActual);
      bContinuar := iSeparador > 0;
      if bContinuar then
      begin
        sPrefijo := Copy(sActual, 1, iSeparador - 1);
        bContinuar := Pos('/', sPrefijo) > 0;
        if bContinuar then
        begin
          Result := Result + [sPrefijo];
          sActual := sPrefijo;
        end;
      end;
    end;
  end;
end;

procedure LeerArtSkuBasicoDeDataSet(ADataSet: TDataSet;
  out ACodigoArticulo, ACodigoSku: string);
var
  oCampo : TField;
  iAlias : Integer;
begin
  ACodigoArticulo := '';
  ACodigoSku := '';
  if (ADataSet <> nil) and ADataSet.Active and
     (not ADataSet.IsEmpty) then
  begin
    iAlias := Low(cAliasArt);
    while (iAlias <= High(cAliasArt)) and
          (ACodigoArticulo = '') do
    begin
      oCampo := ADataSet.FindField(cAliasArt[iAlias]);
      if Assigned(oCampo) and (not oCampo.IsNull) then
        ACodigoArticulo := oCampo.AsString;
      Inc(iAlias);
    end;
    iAlias := Low(cAliasSku);
    while (iAlias <= High(cAliasSku)) and (ACodigoSku = '') do
    begin
      oCampo := ADataSet.FindField(cAliasSku[iAlias]);
      if Assigned(oCampo) and (not oCampo.IsNull) then
        ACodigoSku := oCampo.AsString;
      Inc(iAlias);
    end;
  end;
end;

destructor TConsultaFotos.Destroy;
begin
  FreeAndNil(FCache);
  inherited;
end;

procedure TConsultaFotos.AsignarServicios(AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const ARepositorio: IRepositorioConsultaFotos);
begin
  FConexion := AConexion;
  FValidador := AValidador;
  FRepositorio := ARepositorio;
end;

procedure TConsultaFotos.LiberarServicios;
begin
  FreeAndNil(FCache);
  FConexion := nil;
  FValidador := nil;
  FRepositorio := nil;
end;

function TConsultaFotos.Resolver(const ACodigoArticulo,
  ACodigoSku: string): TFotoInfo;
var
  oMetadatos : TMetadatosFotoPersistida;
  aPrefijos  : TArray<string>;
  bUsarCache : Boolean;
  bEncontrada: Boolean;
begin
  Result.Clear;
  Result.CodigoArt := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
  if ACodigoArticulo <> '' then
  begin
    bUsarCache := (FCache <> nil) and (ACodigoSku = '') and
      FCache.TryGetValue(ACodigoArticulo, Result);
    if not bUsarCache then
    begin
      bEncontrada := False;
      aPrefijos := GenerarPrefijosSku(ACodigoSku);
      if Length(aPrefijos) > 0 then
      begin
        bEncontrada := FRepositorio.BuscarFotoPorUnidades(
          ACodigoArticulo, aPrefijos, oMetadatos);
        if bEncontrada then
        begin
          Result.Encontrada := True;
          if oMetadatos.CodigoUnidad = ACodigoSku then
            Result.Origen := foSku
          else
            Result.Origen := foSkuPrefijo;
          Result.ClaveResuelta := oMetadatos.CodigoUnidad;
          Result.Orden := oMetadatos.Orden;
          Result.NombreBase := oMetadatos.Nombre;
          Result.ExtensionOrigen := oMetadatos.Extension;
        end;
      end;
      if not bEncontrada then
      begin
        bEncontrada := FRepositorio.BuscarFotoArticulo(
          ACodigoArticulo, oMetadatos);
        if bEncontrada then
        begin
          Result.Encontrada := True;
          Result.Origen := foArticulo;
          Result.ClaveResuelta := '';
          Result.Orden := oMetadatos.Orden;
          Result.NombreBase := oMetadatos.Nombre;
          Result.ExtensionOrigen := oMetadatos.Extension;
        end;
      end;
      if (ACodigoSku = '') and (not bEncontrada) then
      begin
        bEncontrada := FRepositorio.BuscarPrimeraFotoUnidad(
          ACodigoArticulo, oMetadatos);
        if bEncontrada then
        begin
          Result.Encontrada := True;
          Result.Origen := foSkuPrefijo;
          Result.ClaveResuelta := oMetadatos.CodigoUnidad;
          Result.Orden := oMetadatos.Orden;
          Result.NombreBase := oMetadatos.Nombre;
          Result.ExtensionOrigen := oMetadatos.Extension;
        end;
      end;
    end;
  end;
end;

function TConsultaFotos.ResolverColeccion(const ACodigoArticulo,
  ACodigoSku: string): TArray<TFotoInfo>;
var
  oPrincipal: TFotoInfo;
  aMetadatos: TArray<TMetadatosFotoPersistida>;
  iFoto: Integer;
begin
  SetLength(Result, 0);
  oPrincipal := Resolver(ACodigoArticulo, ACodigoSku);
  if oPrincipal.Encontrada then
  begin
    aMetadatos := FRepositorio.BuscarFotosColeccion(
      ACodigoArticulo, oPrincipal.ClaveResuelta);
    SetLength(Result, Length(aMetadatos));
    for iFoto := 0 to High(aMetadatos) do
    begin
      Result[iFoto].Clear;
      Result[iFoto].Encontrada := True;
      Result[iFoto].Origen := oPrincipal.Origen;
      Result[iFoto].CodigoArt := ACodigoArticulo;
      Result[iFoto].CodigoSku := ACodigoSku;
      Result[iFoto].ClaveResuelta := aMetadatos[iFoto].CodigoUnidad;
      Result[iFoto].Orden := aMetadatos[iFoto].Orden;
      Result[iFoto].NombreBase := aMetadatos[iFoto].Nombre;
      Result[iFoto].ExtensionOrigen := aMetadatos[iFoto].Extension;
    end;
  end;
end;

function TConsultaFotos.ResolverFotosVariaciones(
  const ACodigoArticulo: string): TArray<TFotoInfo>;
var
  aMetadatos: TArray<TMetadatosFotoPersistida>;
  iFoto: Integer;
begin
  SetLength(Result, 0);
  if ACodigoArticulo <> '' then
  begin
    aMetadatos := FRepositorio.BuscarFotosVariaciones(
      ACodigoArticulo);
    SetLength(Result, Length(aMetadatos));
    for iFoto := 0 to High(aMetadatos) do
    begin
      Result[iFoto].Clear;
      Result[iFoto].Encontrada := True;
      Result[iFoto].Origen := foSku;
      Result[iFoto].CodigoArt := ACodigoArticulo;
      Result[iFoto].CodigoSku := aMetadatos[iFoto].CodigoUnidad;
      Result[iFoto].ClaveResuelta := aMetadatos[iFoto].CodigoUnidad;
      Result[iFoto].Orden := aMetadatos[iFoto].Orden;
      Result[iFoto].NombreBase := aMetadatos[iFoto].Nombre;
      Result[iFoto].ExtensionOrigen := aMetadatos[iFoto].Extension;
    end;
  end;
end;

function TConsultaFotos.ResolverArticulosLote(
  const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;
var
  aMetadatos     : TArray<TMetadatosFotoPersistida>;
  oResultado     : TDictionary<string, TFotoInfo>;
  sArticuloActual: string;
  sArticulo      : string;
  sUnidad        : string;
  sNombreArticulo: string;
  sExtArticulo   : string;
  iOrdenArticulo : Integer;
  sUnidadPrimera : string;
  sNombrePrimero : string;
  sExtPrimera    : string;
  iOrdenPrimero  : Integer;
  iFotosArticulo : Integer;
  iFoto          : Integer;
  bFotoArticulo  : Boolean;

  procedure FinalizarArticulo(const ACodigoArticulo: string);
  var
    oInfo: TFotoInfo;
  begin
    if ACodigoArticulo <> '' then
    begin
      oInfo.Clear;
      oInfo.CodigoArt := ACodigoArticulo;
      if bFotoArticulo then
      begin
        oInfo.Encontrada := True;
        oInfo.Origen := foArticulo;
        oInfo.Orden := iOrdenArticulo;
        oInfo.NombreBase := sNombreArticulo;
        oInfo.ExtensionOrigen := sExtArticulo;
      end
      else if iFotosArticulo > 0 then
      begin
        oInfo.Encontrada := True;
        if sUnidadPrimera = '' then
          oInfo.Origen := foArticulo
        else
          oInfo.Origen := foSkuPrefijo;
        oInfo.ClaveResuelta := sUnidadPrimera;
        oInfo.Orden := iOrdenPrimero;
        oInfo.NombreBase := sNombrePrimero;
        oInfo.ExtensionOrigen := sExtPrimera;
      end;
      if oInfo.Encontrada then
        oResultado.AddOrSetValue(ACodigoArticulo, oInfo);
    end;
  end;

begin
  oResultado := TDictionary<string, TFotoInfo>.Create;
  try
    if Length(ACodigos) > 0 then
    begin
      aMetadatos := FRepositorio.BuscarFotosArticulos(ACodigos);
      sArticuloActual := '';
      iFotosArticulo := 0;
      bFotoArticulo := False;
      sUnidadPrimera := '';
      sNombrePrimero := '';
      sExtPrimera := '';
      iOrdenPrimero := 0;
      sNombreArticulo := '';
      sExtArticulo := '';
      iOrdenArticulo := 0;
      for iFoto := 0 to High(aMetadatos) do
      begin
        sArticulo := aMetadatos[iFoto].CodigoArticulo;
        sUnidad := aMetadatos[iFoto].CodigoUnidad;
        if sArticulo <> sArticuloActual then
        begin
          FinalizarArticulo(sArticuloActual);
          sArticuloActual := sArticulo;
          iFotosArticulo := 0;
          bFotoArticulo := False;
          sUnidadPrimera := '';
          sNombrePrimero := '';
          sExtPrimera := '';
          iOrdenPrimero := 0;
          sNombreArticulo := '';
          sExtArticulo := '';
          iOrdenArticulo := 0;
        end;
        Inc(iFotosArticulo);
        if iFotosArticulo = 1 then
        begin
          sUnidadPrimera := sUnidad;
          sNombrePrimero := aMetadatos[iFoto].Nombre;
          sExtPrimera := aMetadatos[iFoto].Extension;
          iOrdenPrimero := aMetadatos[iFoto].Orden;
        end;
        if sUnidad = '' then
        begin
          bFotoArticulo := True;
          sNombreArticulo := aMetadatos[iFoto].Nombre;
          sExtArticulo := aMetadatos[iFoto].Extension;
          iOrdenArticulo := aMetadatos[iFoto].Orden;
        end;
      end;
      FinalizarArticulo(sArticuloActual);
    end;
    Result := oResultado;
    oResultado := nil;
  finally
    FreeAndNil(oResultado);
  end;
end;

procedure TConsultaFotos.PrecargarFotosLote(
  const ACodigos: TArray<string>);
var
  oInfo   : TFotoInfo;
  iCodigo : Integer;
begin
  FreeAndNil(FCache);
  FCache := ResolverArticulosLote(ACodigos);
  for iCodigo := 0 to High(ACodigos) do
  begin
    if (ACodigos[iCodigo] <> '') and
       (not FCache.ContainsKey(ACodigos[iCodigo])) then
    begin
      oInfo.Clear;
      oInfo.CodigoArt := ACodigos[iCodigo];
      FCache.AddOrSetValue(ACodigos[iCodigo], oInfo);
    end;
  end;
end;

procedure TConsultaFotos.LimpiarPrecargaFotos;
begin
  FreeAndNil(FCache);
end;

procedure TConsultaFotos.CompletarSkuDesdeCodigoBarras(
  ADataSet: TDataSet; var ACodigoArticulo, ACodigoSku: string);
var
  oCampo     : TField;
  oResolucion: TArtResolucionEntrada;
  sCodigo    : string;
  iAlias     : Integer;
begin
  if (ACodigoSku = '') and (ADataSet <> nil) and ADataSet.Active and
     (FConexion <> nil) and Assigned(FValidador) then
  begin
    sCodigo := '';
    iAlias := Low(cAliasCodBarras);
    while (iAlias <= High(cAliasCodBarras)) and (sCodigo = '') do
    begin
      oCampo := ADataSet.FindField(cAliasCodBarras[iAlias]);
      if Assigned(oCampo) and (not oCampo.IsNull) then
        sCodigo := Trim(oCampo.AsString);
      Inc(iAlias);
    end;
    if sCodigo <> '' then
    begin
      oResolucion := FValidador.ResolverCodigoBarras(sCodigo);
      if oResolucion.Encontrado and
         (oResolucion.CodigoSku <> '') and
         ((ACodigoArticulo = '') or
          SameText(oResolucion.CodigoArticulo,
            ACodigoArticulo)) then
      begin
        ACodigoArticulo := oResolucion.CodigoArticulo;
        ACodigoSku := oResolucion.CodigoSku;
      end;
    end;
  end;
end;

procedure TConsultaFotos.LeerArtSkuDeDataSet(ADataSet: TDataSet;
  out ACodigoArticulo, ACodigoSku: string);
begin
  LeerArtSkuBasicoDeDataSet(
    ADataSet, ACodigoArticulo, ACodigoSku);
  CompletarSkuDesdeCodigoBarras(
    ADataSet, ACodigoArticulo, ACodigoSku);
end;

end.

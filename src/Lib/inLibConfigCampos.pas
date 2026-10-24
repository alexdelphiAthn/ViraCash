{******************************************************************************}
{                                                                              }
{  Modulo:       inLibConfigCampos                                             }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cache en memoria de fza_config_campos. Provee titulo visual y ancho      }
{    por defecto para cualquier columna de cualquier tabla. Se precarga        }
{    al login y se usa como fallback cuando no hay perfil de usuario.          }
{******************************************************************************}
unit inLibConfigCampos;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  inLibConfigCamposIntf, inLibLogIntf,
  inLibConfigCamposPersistenciaIntf, inLibTraduccionesIntf;

type
  TConfigCampoItem = TConfigCampoPersistido;

  TConfigCamposCache = class(TInterfacedObject, IConfiguracionCampos)
  private
    // Diccionario indexado por CAMPO (sin tabla) para el fallback.
    // Solo contiene campos presentes en un unico ambito; los duplicados
    // se excluyen para no escoger una tabla arbitraria.
    FPorCampo: TDictionary<string, TConfigCampoItem>;
    FCamposAmbiguos: TDictionary<string, Boolean>;
    // Diccionario indexado por TABLA.CAMPO para resolucion exacta.
    FPorTablaCampo: TDictionary<string, TConfigCampoItem>;
    FRepositorio: IRepositorioConfigCampos;
    FCargada: Boolean;
    FRegistroLog: IRegistroLog;
    FTraducciones: IServicioTraducciones;
    function GetCargada: Boolean;
    function TraducirTitulo(
      const AItem: TConfigCampoItem): string;
  public
    constructor Create(
      const ARepositorio: IRepositorioConfigCampos;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure Precargar(
      const ARepositorio: IRepositorioConfigCampos = nil);
    procedure Invalidar;
    procedure AsignarTraducciones(
      const ATraducciones: IServicioTraducciones);
    // Busca tabla+campo, despues '*', y solo usa campo si es univoco.
    function ObtenerTitulo(const aCampo: string;
                           const aTabla: string = ''): string;
    function ObtenerAncho(const aCampo: string;
                          const aTabla: string = ''): Integer;
    function Existe(const aCampo: string;
                    const aTabla: string = ''): Boolean;
    property Cargada: Boolean read FCargada;
  end;

implementation

constructor TConfigCamposCache.Create(
  const ARepositorio: IRepositorioConfigCampos;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FRepositorio := ARepositorio;
  FRegistroLog := ARegistroLog;
  FTraducciones := nil;
  FPorCampo := TDictionary<string, TConfigCampoItem>.Create;
  FCamposAmbiguos := TDictionary<string, Boolean>.Create;
  FPorTablaCampo := TDictionary<string, TConfigCampoItem>.Create;
  FCargada := False;
end;

destructor TConfigCamposCache.Destroy;
begin
  FRepositorio := nil;
  FRegistroLog := nil;
  FTraducciones := nil;
  FreeAndNil(FCamposAmbiguos);
  FreeAndNil(FPorCampo);
  FreeAndNil(FPorTablaCampo);
  inherited;
end;

procedure TConfigCamposCache.AsignarTraducciones(
  const ATraducciones: IServicioTraducciones);
begin
  FTraducciones := ATraducciones;
end;

procedure TConfigCamposCache.Invalidar;
begin
  FPorCampo.Clear;
  FCamposAmbiguos.Clear;
  FPorTablaCampo.Clear;
  FCargada := False;
end;

procedure TConfigCamposCache.Precargar(
  const ARepositorio: IRepositorioConfigCampos);
var
  i: Integer;
  item: TConfigCampoItem;
  oRepositorio: IRepositorioConfigCampos;
  oResultado: TResultadoConfigCampos;
  sCampoKey: string;
  sKey: string;
begin
  FPorCampo.Clear;
  FCamposAmbiguos.Clear;
  FPorTablaCampo.Clear;
  FCargada := False;
  oRepositorio := ARepositorio;
  if not Assigned(oRepositorio) then
    oRepositorio := FRepositorio;
  if Assigned(oRepositorio) then
  begin
    try
      oResultado := oRepositorio.CargarCampos;
      if oResultado.Exito then
      begin
        for i := 0 to Length(oResultado.Elementos) - 1 do
        begin
          item := oResultado.Elementos[i];
          sKey := LowerCase(item.Tabla + '.' + item.Campo);
          FPorTablaCampo.AddOrSetValue(sKey, item);
          sCampoKey := LowerCase(item.Campo);
          if not FCamposAmbiguos.ContainsKey(sCampoKey) then
          begin
            if FPorCampo.ContainsKey(sCampoKey) then
            begin
              FPorCampo.Remove(sCampoKey);
              FCamposAmbiguos.Add(sCampoKey, True);
            end
            else
              FPorCampo.Add(sCampoKey, item);
          end;
        end;
        FCargada := True;
        FRegistroLog.RegistrarInformacion(
          Format(
            'ConfigCamposCache: precargados %d campos',
            [FPorTablaCampo.Count]));
      end
      else
      begin
        FRegistroLog.RegistrarError(
          'ConfigCamposCache.Precargar: ' +
          oResultado.Detalle);
      end;
    except
      on E: Exception do
      begin
        FPorCampo.Clear;
        FCamposAmbiguos.Clear;
        FPorTablaCampo.Clear;
        FRegistroLog.RegistrarError(
          'ConfigCamposCache.Precargar: ' + E.Message);
      end;
    end;
  end;
end;

function TConfigCamposCache.Existe(const aCampo: string;
                                   const aTabla: string): Boolean;
begin
  Result := False;
  if FCargada then
  begin
    if aTabla <> '' then
      Result := FPorTablaCampo.ContainsKey(
        LowerCase(aTabla + '.' + aCampo));
    if not Result then
      Result := FPorTablaCampo.ContainsKey(
        LowerCase('*.' + aCampo));
    if not Result then
      Result := FPorCampo.ContainsKey(LowerCase(aCampo));
  end;
end;

function TConfigCamposCache.ObtenerTitulo(const aCampo: string;
                                          const aTabla: string): string;
var
  item: TConfigCampoItem;
begin
  Result := '';
  if FCargada then
  begin
    // Busqueda exacta por tabla+campo
    if (aTabla <> '') and
       FPorTablaCampo.TryGetValue(
         LowerCase(aTabla + '.' + aCampo), item) then
      Result := TraducirTitulo(item)
    else if FPorTablaCampo.TryGetValue(
              LowerCase('*.' + aCampo), item) then
      Result := TraducirTitulo(item)
    // Fallback: solo por campo
    else if FPorCampo.TryGetValue(LowerCase(aCampo), item) then
      Result := TraducirTitulo(item);
  end;
end;

function TConfigCamposCache.TraducirTitulo(
  const AItem: TConfigCampoItem): string;
begin
  Result := AItem.TituloVisual;
  if Assigned(FTraducciones) and
     not SameText(FTraducciones.Idioma, IDIOMA_ESPANOL) then
    Result := FTraducciones.Traducir(
      ClaveTituloVisualConfigCampo(AItem.Tabla, AItem.Campo),
      Result);
end;

function TConfigCamposCache.ObtenerAncho(const aCampo: string;
                                         const aTabla: string): Integer;
var
  item: TConfigCampoItem;
begin
  Result := 0;
  if FCargada then
  begin
    if (aTabla <> '') and
       FPorTablaCampo.TryGetValue(
         LowerCase(aTabla + '.' + aCampo), item) then
      Result := item.AnchoColumna
    else if FPorTablaCampo.TryGetValue(
              LowerCase('*.' + aCampo), item) then
      Result := item.AnchoColumna
    else if FPorCampo.TryGetValue(LowerCase(aCampo), item) then
      Result := item.AnchoColumna;
  end;
end;

function TConfigCamposCache.GetCargada: Boolean;
begin
  Result := FCargada;
end;

end.

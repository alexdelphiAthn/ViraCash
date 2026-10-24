{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopCola                                          }
{    Tipo:       Librería                                                      }
{ Versión:       2.1.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Consume eventos de catálogo por artículo, sin recorrer el catálogo.       }
{******************************************************************************}
unit inLibPrestaShopCola;

interface

uses
  inLibEstadoColasIntf,
  System.Classes, inLibContextoSesionIntf, inLibParametrosIntf,
  inLibPrestaShopColaIntf, inLibPrestaShopCierre, inLibLogIntf;

type
  TPrestaShopCola = class
  private
    FControlTrabajo: TControlTrabajoPrestaShop;
    FHilo: TThread;
    FRegistroLog: IRegistroLog;
    FEstado: IEstadoCola;
    procedure FinalizarHilo;
  public
    constructor Create(const ARegistroLog: IRegistroLog;
      const AEstado: IEstadoCola = nil);
    destructor Destroy; override;
    function BloquearNuevasReclamaciones: Boolean;
    procedure CancelarCierre;
    procedure DetenerLiberandoTrabajoActual;
    procedure IniciarHilo(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionPrestaShopCola;
      const AUsuario: string);
    procedure DetenerHilo;
    procedure DetenerTrasTrabajoActual;
  end;

implementation

uses
  inLibEstadoColas, inLibMsgIntegraciones,
  Winapi.ActiveX, Winapi.Windows, System.Math, System.SyncObjs,
  System.SysUtils, System.Generics.Collections,
  inLibPrestaCatalogoIntf, inLibPrestaCatalogo,
  inLibPrestaCatalogoAltaIntf, inLibPrestaCatalogoAlta,
  inLibPrestaShopAltaArticuloIntf, inLibPrestaShopColaSenal,
  inLibPrestaShopTransporteHistorial, inLibErroresHttp;

const
  CToleranciaPrecio = 0.000001;
  CFilasPorCiclo = 10;
  CMinutosReclamacionCaducada = 10;
  CSegundosReintentoSinConexion = 300;
  CTipoRecursoProducto = 'product';

type
  EAltaArticuloPrestaWorker = class(Exception);
  ECierreForzadoPrestaShop = class(Exception);

  TMapeoLineaPrestaShop = record
    CantidadStock: Integer;
    IdCombinacion: Integer;
    IdStock: Integer;
    ImpactoPrecio: Double;
    Omitir: Boolean;
  end;

  TPlanArticuloPrestaShop = record
    IdProducto: Integer;
    Lineas: TArray<TMapeoLineaPrestaShop>;
  end;

  THiloPrestaShopCola = class(TThread)
  private
    FSesion: ISesionPrestaShopCola;
    FRepositorio: IRepositorioPrestaShopCola;
    FRepositorioAlta: IRepositorioAltaArticuloPresta;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FControlTrabajo: TControlTrabajoPrestaShop;
    FFabricaSesion: IFabricaSesionPrestaShopCola;
    FRegistroLog: IRegistroLog;
    FEstado: IEstadoCola;
    FUsuario: string;
    FClaveOculta: string;
    FSegundosCiclo: Integer;
    FAvisoConfiguracion: Boolean;
    function ColaActiva: Boolean;
    function ConfiguracionCompleta(
      const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
    function PrepararConfiguracion:
      TConfiguracionGlobalPrestaShop;
    function SigueVigente(
      const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
    procedure AsegurarLease(const ATrabajo: TTrabajoArticuloPrestaShop);
    procedure ComprobarCierreSeguro;
    procedure AsegurarAtributosAlta(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AArticulo: TArticuloCompletoAltaPresta;
      const ACliente: IClienteCatalogoAltaPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AGrupos, AValores: TDictionary<string, Integer>);
    procedure AsegurarCombinacionesAlta(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AArticulo: TArticuloCompletoAltaPresta;
      const ACliente: IClienteCatalogoAltaPresta;
      const AValores: TDictionary<string, Integer>;
      AIdProducto: Integer);
    function AsegurarFamiliasAlta(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AArticulo: TArticuloCompletoAltaPresta;
      const ACliente: IClienteCatalogoAltaPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop):
      TArray<Integer>;
    procedure AsegurarFotoAlta(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AArticulo: TArticuloCompletoAltaPresta;
      const ACliente: IClienteCatalogoAltaPresta;
      AIdProducto: Integer);
    function AsegurarProductoAlta(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AArticulo: TArticuloCompletoAltaPresta;
      const ACliente: IClienteCatalogoAltaPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AIdsCategorias: TArray<Integer>): Integer;
    procedure CrearOCompletarArticulo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ACliente: IClienteCatalogoAltaPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
    procedure GuardarError(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AMensaje: string);
    procedure GuardarSinConexion(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AMensaje: string);
    procedure GuardarIncidenciaTerminal(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AMensaje: string);
    procedure GuardarRecursoAmbiguo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AError: ERecursoPrestaAmbiguo);
    procedure GuardarRecursoNoEncontrado(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AError: ERecursoPrestaNoEncontrado);
    procedure LiberarTrabajoActual(AIdCola: Int64; const AToken: string);
    procedure LiberarSesion;
    procedure ProcesarArticulo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ACliente: IClienteCatalogoPrestaInstantanea;
      const AClienteAlta: IClienteCatalogoAltaPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
    procedure ProcesarDesactivacion(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ACliente: IClienteCatalogoPresta);
    function PrepararPlanArticulo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ACliente: IClienteCatalogoPrestaInstantanea;
      ASincronizarStockPrecios: Boolean): TPlanArticuloPrestaShop;
    procedure EjecutarBarridoSiProcede(
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
    procedure ProcesarCiclo(ARecuperacion: Boolean);
    procedure ProcesarCicloActivo(ARecuperacion: Boolean);
    function ProcesarFila(
      AIdCola: Int64;
      const ACliente: IClienteCatalogoPrestaInstantanea;
      const AClienteAlta: IClienteCatalogoAltaPresta;
      const ATransporteHistorial:
        ITransportePrestaShopConHistorial;
      const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
    procedure EnviarTrabajoReclamado(
      AIdCola: Int64;
      const AToken: string;
      const ACliente: IClienteCatalogoPrestaInstantanea;
      const AClienteAlta: IClienteCatalogoAltaPresta;
      const ATransporteHistorial:
        ITransportePrestaShopConHistorial;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      var ATrabajo: TTrabajoArticuloPrestaShop);
    function TratarErrorTrabajo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      AIdCola: Int64;
      const AToken: string;
      E: Exception): Boolean;
    procedure ProcesarLinea(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ALinea: TLineaArticuloPrestaShop;
      const AMapeo: TMapeoLineaPrestaShop;
      const ACliente: IClienteCatalogoPresta);
    procedure ProcesarPendientes(
      const ACliente: IClienteCatalogoPrestaInstantanea;
      const AClienteAlta: IClienteCatalogoAltaPresta;
      const ATransporteHistorial:
        ITransportePrestaShopConHistorial;
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionPrestaShopCola;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog;
      AControlTrabajo: TControlTrabajoPrestaShop;
      const AEstado: IEstadoCola); reintroduce;
    destructor Destroy; override;
  end;

resourcestring
  SConfiguracionPrestaShopIncompleta =
    'Cola PrestaShop pendiente: faltan URL, API key, empresa, tarifa o ' +
    'identificador de tienda en la configuración efectiva de la sesión.';
  SDestinoPrestaShopEnConflicto =
    'Cola PrestaShop detenida: otro perfil activo usa la misma URL y ' +
    'tienda con empresa, tarifa o permisos de sincronización distintos.';
  SSesionPrestaShopNoCreada =
    'La fábrica no creó la sesión de cola PrestaShop.';
  SRepositorioPrestaShopNoCreado =
    'La sesión de cola PrestaShop no tiene repositorio.';
  SRepositorioAltaPrestaShopNoCreado =
    'La sesión de cola PrestaShop no tiene repositorio para altas.';
  STrabajoPrestaShopNoReclamado =
    'No se pudo leer el artículo reclamado de la cola PrestaShop.';
  SLeasePrestaShopPerdido =
    'La reclamación del artículo PrestaShop dejó de estar vigente.';
  SPrecioProductoPrestaShopAusente =
    'El artículo %s no tiene precio base vigente.';
  SPrecioProductoNoVerificado =
    'PrestaShop no confirmó el precio del producto %d.';
  SPrecioCombinacionNoVerificado =
    'PrestaShop no confirmó el impacto de precio de la combinación %d.';
  SStockPrestaShopNoVerificado =
    'PrestaShop no confirmó el stock %d.';
  STrabajoPrestaShopReencolado =
    'Artículo PrestaShop %d reencolado sin consumir intento.';
  STrabajoPrestaShopNoLiberado =
    'No se liberó el artículo PrestaShop %d porque su reclamación ya no ' +
    'estaba vigente.';
  SBarridoPrestaShopOmitido =
    'Barrido de respaldo PrestaShop omitido: %s';
  SProductoPrestaShopNoEncontradoSinAlta =
    'No existe en PrestaShop un producto único con reference="%s". ' +
    'La creación de artículos está desactivada; no se envió ningún cambio.';
  SProductoPrestaShopNoEncontradoTrasAlta =
    'El alta no dejó un producto único con reference="%s". ' +
    'No se envió ningún cambio posterior.';
  SConfiguracionFiscalPrestaShopInvalida =
    'No existe una regla fiscal PrestaShop válida para el tipo de IVA %s.';
  SRecursoPrestaShopNoEncontrado =
    'No existe en PrestaShop la correspondencia %s del artículo con ' +
    'reference="%s". Se detuvo el envío; revise la correspondencia antes ' +
    'de reintentar.';
  SProductoPrestaShopAmbiguo =
    'PrestaShop devolvió %d productos para reference="%s". La referencia ' +
    'debe identificar un único producto; no se envió ningún cambio.';
  SRecursoPrestaShopAmbiguo =
    'PrestaShop devolvió %d correspondencias %s para el artículo con ' +
    'reference="%s". Se detuvo el envío; revise la correspondencia antes ' +
    'de reintentar.';

function PrecioDiferente(AActual, ADeseado: Double): Boolean;
begin
  Result := IsNan(AActual) or IsInfinite(AActual) or
            IsNan(ADeseado) or IsInfinite(ADeseado) or
            (Abs(AActual - ADeseado) > CToleranciaPrecio);
end;

function OcultarClave(const AMensaje, AClave: string): string;
begin
  Result := AMensaje;
  if AClave <> '' then
    Result := StringReplace(
      Result,
      AClave,
      '[oculta]',
      [rfReplaceAll, rfIgnoreCase]);
end;

function CalcularEspera(AIntentos: Integer): Integer;
begin
  if AIntentos < 0 then
    AIntentos := 0;
  if AIntentos > 6 then
    AIntentos := 6;
  Result := 60 * (1 shl AIntentos);
end;

function ClaveGrupoAtributo(
  const AGrupo: TAtributoAltaArticuloPresta): string;
begin
  Result := UpperCase(Trim(AGrupo.CodigoGrupo));
end;

function ClaveValorAtributo(
  const AValor: TAtributoAltaArticuloPresta): string;
begin
  Result := ClaveGrupoAtributo(AValor) + #1 +
    UpperCase(Trim(AValor.CodigoValor));
end;

function ResolverIdReglaIva(
  const ATipoIva: string;
  const AConfiguracion: TConfiguracionPrestaShopCola): Integer;
var
  sTipoIva: string;
begin
  sTipoIva := UpperCase(Trim(ATipoIva));
  Result := -1;
  if sTipoIva = 'N' then
    Result := AConfiguracion.IdReglaIvaNormal
  else if sTipoIva = 'R' then
    Result := AConfiguracion.IdReglaIvaReducido
  else if sTipoIva = 'S' then
    Result := AConfiguracion.IdReglaIvaSuperreducido
  else if sTipoIva = 'E' then
    Result := AConfiguracion.IdReglaIvaExento;
  if (Result < 0) or
     ((sTipoIva <> 'E') and (Result = 0)) then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SConfiguracionFiscalPrestaShopInvalida,
      [ATipoIva]);
end;

{ TPrestaShopCola }

constructor TPrestaShopCola.Create(
  const ARegistroLog: IRegistroLog; const AEstado: IEstadoCola);
begin
  inherited Create;
  FControlTrabajo := TControlTrabajoPrestaShop.Create;
  FRegistroLog := ARegistroLog;
  FEstado := AEstado;
  if not Assigned(FEstado) then
    FEstado := CrearEstadoCola;
end;

destructor TPrestaShopCola.Destroy;
begin
  try
    DetenerHilo;
    FRegistroLog := nil;
  finally
    FreeAndNil(FControlTrabajo);
    inherited;
  end;
end;

function TPrestaShopCola.BloquearNuevasReclamaciones: Boolean;
begin
  Result := False;
  if FHilo <> nil then
    Result := FControlTrabajo.BloquearNuevasReclamaciones;
end;

procedure TPrestaShopCola.CancelarCierre;
begin
  FControlTrabajo.CancelarCierre;
  SolicitarProcesadoPrestaShop;
end;

procedure TPrestaShopCola.DetenerLiberandoTrabajoActual;
begin
  FControlTrabajo.SolicitarCerrarDeTodosModos;
  FinalizarHilo;
end;

procedure TPrestaShopCola.IniciarHilo(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionPrestaShopCola;
  const AUsuario: string);
var
  oHilo: TThread;
begin
  if FHilo = nil then
  begin
    FControlTrabajo.CancelarCierre;
    oHilo := THiloPrestaShopCola.Create(
      AContextoSesion,
      AParametrosApp,
      AFabricaSesion,
      AUsuario,
      FRegistroLog,
      FControlTrabajo, FEstado);
    try
      oHilo.FreeOnTerminate := False;
      oHilo.Start;
      FHilo := oHilo;
      oHilo := nil;
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarInformacion(
          'Cola PrestaShop por artículo: hilo iniciado');
    finally
      FreeAndNil(oHilo);
    end;
  end;
end;

procedure TPrestaShopCola.DetenerHilo;
begin
  FControlTrabajo.SolicitarEsperar;
  FinalizarHilo;
end;

procedure TPrestaShopCola.DetenerTrasTrabajoActual;
begin
  FControlTrabajo.SolicitarEsperar;
  FinalizarHilo;
end;

procedure TPrestaShopCola.FinalizarHilo;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    SolicitarProcesadoPrestaShop;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarInformacion(
        'Cola PrestaShop por artículo: hilo detenido');
  end;
end;

{ THiloPrestaShopCola }

constructor THiloPrestaShopCola.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionPrestaShopCola;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog;
  AControlTrabajo: TControlTrabajoPrestaShop;
  const AEstado: IEstadoCola);
begin
  FEstado := AEstado;
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AFabricaSesion) then
    raise EArgumentNilException.Create('AFabricaSesion');
  if not Assigned(AControlTrabajo) then
    raise EArgumentNilException.Create('AControlTrabajo');
  inherited Create(True);
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FControlTrabajo := AControlTrabajo;
  FFabricaSesion := AFabricaSesion;
  FUsuario := Trim(AUsuario);
  if FUsuario = '' then
    FUsuario := 'SISTEMA';
  FRegistroLog := ARegistroLog;
  FSegundosCiclo := 60;
end;

destructor THiloPrestaShopCola.Destroy;
begin
  LiberarSesion;
  FFabricaSesion := nil;
  FControlTrabajo := nil;
  FParametrosApp := nil;
  FContextoSesion := nil;
  FRegistroLog := nil;
  inherited;
end;

function THiloPrestaShopCola.ColaActiva: Boolean;
var
  sValor: string;
begin
  sValor := Trim(FParametrosApp.GetString(
    'appPrestaShopSincronizarStockPrecios',
    'False'));
  Result := SameText(sValor, 'True') or
    (sValor = '1') or SameText(sValor, 'S');
end;

function THiloPrestaShopCola.ConfiguracionCompleta(
  const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
begin
  Result := (AConfiguracion.UrlApi <> '') and
            (AConfiguracion.ClaveApi <> '') and
            (AConfiguracion.Cola.ClaveInstalacion <> '') and
            (AConfiguracion.Cola.CodigoEmpresa <> '') and
            (AConfiguracion.Cola.CodigoTarifa <> '') and
            (AConfiguracion.Cola.IdTienda > 0) and
            (AConfiguracion.Cola.NivelesFamiliaAlta >= 0) and
            ((not AConfiguracion.CrearArticulos) or
             ((AConfiguracion.Cola.IdIdioma > 0) and
              (AConfiguracion.Cola.IdCategoriaRaiz > 0) and
              (AConfiguracion.Cola.IdReglaIvaNormal > 0) and
              (AConfiguracion.Cola.IdReglaIvaReducido > 0) and
              (AConfiguracion.Cola.IdReglaIvaSuperreducido > 0) and
              (AConfiguracion.Cola.IdReglaIvaExento >= 0)));
end;

function THiloPrestaShopCola.PrepararConfiguracion:
  TConfiguracionGlobalPrestaShop;
begin
  Result := FRepositorio.LeerConfiguracionPerfil(
    FContextoSesion.Identidad.Usuario,
    FContextoSesion.Identidad.Grupo);
  FSegundosCiclo := Result.SegundosCiclo;
  FClaveOculta := Result.ClaveApi;
  if Result.UrlApi <> '' then
    Result.Cola.ClaveInstalacion :=
      CalcularClaveInstalacionPresta(Result.UrlApi);
end;

function THiloPrestaShopCola.SigueVigente(
  const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
var
  oActual: TConfiguracionGlobalPrestaShop;
begin
  Result := ColaActiva;
  if Result then
  begin
    oActual := PrepararConfiguracion;
    Result := FRepositorio.DestinoSinConflictos(oActual, FUsuario) and
      SameText(oActual.UrlApi, AConfiguracion.UrlApi) and
      (oActual.ClaveApi = AConfiguracion.ClaveApi) and
      SameText(
        oActual.Cola.ClaveInstalacion,
        AConfiguracion.Cola.ClaveInstalacion) and
      (oActual.Cola.IdTienda = AConfiguracion.Cola.IdTienda) and
      (oActual.Cola.IdIdioma = AConfiguracion.Cola.IdIdioma) and
      (oActual.Cola.IdCategoriaRaiz =
        AConfiguracion.Cola.IdCategoriaRaiz) and
      (oActual.Cola.IdReglaIvaNormal =
        AConfiguracion.Cola.IdReglaIvaNormal) and
      (oActual.Cola.IdReglaIvaReducido =
        AConfiguracion.Cola.IdReglaIvaReducido) and
      (oActual.Cola.IdReglaIvaSuperreducido =
        AConfiguracion.Cola.IdReglaIvaSuperreducido) and
      (oActual.Cola.IdReglaIvaExento =
        AConfiguracion.Cola.IdReglaIvaExento) and
      (oActual.Cola.NivelesFamiliaAlta =
        AConfiguracion.Cola.NivelesFamiliaAlta) and
      (oActual.SincronizarStockPrecios =
        AConfiguracion.SincronizarStockPrecios) and
      (oActual.CrearArticulos = AConfiguracion.CrearArticulos) and
      (oActual.Cola.StockActivo = AConfiguracion.Cola.StockActivo) and
      (oActual.HorasBarrido = AConfiguracion.HorasBarrido) and
      SameText(
        oActual.Cola.CodigoEmpresa,
        AConfiguracion.Cola.CodigoEmpresa) and
      SameText(
        oActual.Cola.CodigoTarifa,
        AConfiguracion.Cola.CodigoTarifa);
  end;
end;

procedure THiloPrestaShopCola.AsegurarLease(
  const ATrabajo: TTrabajoArticuloPrestaShop);
begin
  ComprobarCierreSeguro;
  if not FRepositorio.RenovarReclamacion(
    ATrabajo.IdCola,
    ATrabajo.Token) then
    raise EInvalidOpException.Create(SLeasePrestaShopPerdido);
  ComprobarCierreSeguro;
end;

procedure THiloPrestaShopCola.ComprobarCierreSeguro;
begin
  if FControlTrabajo.DebeLiberarTrabajo then
    raise ECierreForzadoPrestaShop.Create(
      'Cierre solicitado tras la operación remota actual');
end;

function THiloPrestaShopCola.AsegurarFamiliasAlta(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AArticulo: TArticuloCompletoAltaPresta;
  const ACliente: IClienteCatalogoAltaPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop):
  TArray<Integer>;
var
  iFamilia: Integer;
  iIdPadre: Integer;
  iPrimeraFamilia: Integer;
  iResultado: Integer;
  oDatos: TAltaCategoriaPresta;
  oResultado: TResultadoAltaPresta;
begin
  iPrimeraFamilia := 0;
  if (AConfiguracion.Cola.NivelesFamiliaAlta > 0) and
     (Length(AArticulo.Familias) >
      AConfiguracion.Cola.NivelesFamiliaAlta) then
    iPrimeraFamilia := Length(AArticulo.Familias) -
      AConfiguracion.Cola.NivelesFamiliaAlta;
  SetLength(
    Result,
    Length(AArticulo.Familias) - iPrimeraFamilia + 1);
  iIdPadre := AConfiguracion.Cola.IdCategoriaRaiz;
  Result[0] := iIdPadre;
  iFamilia := iPrimeraFamilia;
  iResultado := 1;
  while iFamilia <= High(AArticulo.Familias) do
  begin
    oDatos := Default(TAltaCategoriaPresta);
    oDatos.IdPadre := iIdPadre;
    oDatos.IdTienda := ATrabajo.IdTienda;
    oDatos.IdIdioma := AConfiguracion.Cola.IdIdioma;
    oDatos.Nombre := AArticulo.Familias[iFamilia].Nombre;
    oDatos.Enlace := AArticulo.Familias[iFamilia].Enlace;
    oDatos.Activa := True;
    AsegurarLease(ATrabajo);
    oResultado := ACliente.AsegurarCategoria(oDatos);
    iIdPadre := oResultado.Id;
    Result[iResultado] := iIdPadre;
    Inc(iResultado);
    Inc(iFamilia);
  end;
end;

procedure THiloPrestaShopCola.AsegurarAtributosAlta(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AArticulo: TArticuloCompletoAltaPresta;
  const ACliente: IClienteCatalogoAltaPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AGrupos, AValores: TDictionary<string, Integer>);
var
  iAtributo: Integer;
  iGrupo: Integer;
  iSku: Integer;
  iValor: Integer;
  oAtributo: TAtributoAltaArticuloPresta;
  oDatosGrupo: TAltaGrupoAtributosPresta;
  oDatosValor: TAltaValorAtributoPresta;
  sClaveGrupo: string;
  sClaveValor: string;
begin
  iSku := 0;
  while iSku <= High(AArticulo.Skus) do
  begin
    iAtributo := 0;
    while iAtributo <= High(AArticulo.Skus[iSku].Atributos) do
    begin
      oAtributo := AArticulo.Skus[iSku].Atributos[iAtributo];
      sClaveGrupo := ClaveGrupoAtributo(oAtributo);
      if not AGrupos.TryGetValue(sClaveGrupo, iGrupo) then
      begin
        oDatosGrupo := Default(TAltaGrupoAtributosPresta);
        oDatosGrupo.IdTienda := ATrabajo.IdTienda;
        oDatosGrupo.IdIdioma := AConfiguracion.Cola.IdIdioma;
        oDatosGrupo.Nombre := oAtributo.NombreGrupo;
        oDatosGrupo.NombrePublico := oAtributo.NombrePublicoGrupo;
        oDatosGrupo.TipoGrupo := oAtributo.TipoGrupo;
        oDatosGrupo.EsColor := oAtributo.EsColor;
        AsegurarLease(ATrabajo);
        iGrupo := ACliente.AsegurarGrupoAtributos(oDatosGrupo).Id;
        AGrupos.Add(sClaveGrupo, iGrupo);
      end;
      sClaveValor := ClaveValorAtributo(oAtributo);
      if not AValores.TryGetValue(sClaveValor, iValor) then
      begin
        oDatosValor := Default(TAltaValorAtributoPresta);
        oDatosValor.IdGrupo := iGrupo;
        oDatosValor.IdTienda := ATrabajo.IdTienda;
        oDatosValor.IdIdioma := AConfiguracion.Cola.IdIdioma;
        oDatosValor.Nombre := oAtributo.NombreValor;
        oDatosValor.Color := oAtributo.ColorHtml;
        AsegurarLease(ATrabajo);
        iValor := ACliente.AsegurarValorAtributo(oDatosValor).Id;
        AValores.Add(sClaveValor, iValor);
      end;
      Inc(iAtributo);
    end;
    Inc(iSku);
  end;
end;

function THiloPrestaShopCola.AsegurarProductoAlta(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AArticulo: TArticuloCompletoAltaPresta;
  const ACliente: IClienteCatalogoAltaPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AIdsCategorias: TArray<Integer>): Integer;
var
  oDatos: TAltaProductoPresta;
begin
  oDatos := Default(TAltaProductoPresta);
  oDatos.IdCategoriaDefecto := AIdsCategorias[High(AIdsCategorias)];
  oDatos.IdGrupoReglasIva := ResolverIdReglaIva(
    AArticulo.TipoIva,
    AConfiguracion.Cola);
  oDatos.IdTienda := ATrabajo.IdTienda;
  oDatos.IdIdioma := AConfiguracion.Cola.IdIdioma;
  oDatos.Referencia := AArticulo.Codigo;
  oDatos.Nombre := AArticulo.Nombre;
  oDatos.Enlace := AArticulo.Enlace;
  oDatos.DescripcionCorta := AArticulo.DescripcionCorta;
  oDatos.Descripcion := AArticulo.Descripcion;
  oDatos.Precio := AArticulo.PrecioBaseSinIva;
  oDatos.IdsCategorias := AIdsCategorias;
  AsegurarLease(ATrabajo);
  Result := ACliente.AsegurarProductoInactivo(oDatos).Id;
end;

procedure THiloPrestaShopCola.AsegurarCombinacionesAlta(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AArticulo: TArticuloCompletoAltaPresta;
  const ACliente: IClienteCatalogoAltaPresta;
  const AValores: TDictionary<string, Integer>;
  AIdProducto: Integer);
var
  aIdsValores: TArray<Integer>;
  iAtributo: Integer;
  iSku: Integer;
  iValor: Integer;
  oDatos: TAltaCombinacionPresta;
  sClaveValor: string;
begin
  iSku := 0;
  while iSku <= High(AArticulo.Skus) do
  begin
    SetLength(
      aIdsValores,
      Length(AArticulo.Skus[iSku].Atributos));
    iAtributo := 0;
    while iAtributo <= High(AArticulo.Skus[iSku].Atributos) do
    begin
      sClaveValor := ClaveValorAtributo(
        AArticulo.Skus[iSku].Atributos[iAtributo]);
      if not AValores.TryGetValue(sClaveValor, iValor) then
        raise EInvalidOpException.Create(
          'No se resolvió un atributo de la combinación PrestaShop');
      aIdsValores[iAtributo] := iValor;
      Inc(iAtributo);
    end;
    oDatos := Default(TAltaCombinacionPresta);
    oDatos.IdProducto := AIdProducto;
    oDatos.IdTienda := ATrabajo.IdTienda;
    oDatos.Referencia := AArticulo.Skus[iSku].Codigo;
    oDatos.ImpactoPrecio := AArticulo.Skus[iSku].ImpactoPrecio;
    oDatos.Predeterminada := AArticulo.Skus[iSku].Predeterminado;
    oDatos.CantidadMinima := 1;
    oDatos.IdsValores := aIdsValores;
    AsegurarLease(ATrabajo);
    ACliente.AsegurarCombinacion(oDatos);
    Inc(iSku);
  end;
end;

procedure THiloPrestaShopCola.AsegurarFotoAlta(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AArticulo: TArticuloCompletoAltaPresta;
  const ACliente: IClienteCatalogoAltaPresta;
  AIdProducto: Integer);
var
  bSubida: Boolean;
  iFoto: Integer;
  iIndice: Integer;
begin
  if Length(AArticulo.Fotos) = 0 then
    raise EAltaArticuloPrestaLocal.Create(
      'El artículo no tiene una foto real válida para publicar');
  iFoto := 0;
  iIndice := 0;
  while iIndice <= High(AArticulo.Fotos) do
  begin
    if AArticulo.Fotos[iIndice].Principal then
      iFoto := iIndice;
    Inc(iIndice);
  end;
  AsegurarLease(ATrabajo);
  bSubida := ACliente.AsegurarImagenProductoSiVacia(
    AIdProducto,
    ATrabajo.IdTienda,
    AArticulo.Fotos[iFoto].RutaReal);
  if bSubida then
    AsegurarLease(ATrabajo);
end;

procedure THiloPrestaShopCola.CrearOCompletarArticulo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ACliente: IClienteCatalogoAltaPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  aIdsCategorias: TArray<Integer>;
  iIdProducto: Integer;
  oArticulo: TArticuloCompletoAltaPresta;
  oConfiguracionAlta: TConfiguracionAltaArticuloPresta;
  oGrupos: TDictionary<string, Integer>;
  oValores: TDictionary<string, Integer>;
begin
  if not Assigned(ACliente) then
    raise EInvalidOpException.Create(
      'El cliente de altas PrestaShop no está asignado');
  if not Assigned(FRepositorioAlta) then
    raise EInvalidOpException.Create(
      SRepositorioAltaPrestaShopNoCreado);
  oConfiguracionAlta := Default(TConfiguracionAltaArticuloPresta);
  oConfiguracionAlta.CodigoEmpresa :=
    AConfiguracion.Cola.CodigoEmpresa;
  oConfiguracionAlta.CodigoTarifa :=
    AConfiguracion.Cola.CodigoTarifa;
  oConfiguracionAlta.StockActivo :=
    AConfiguracion.Cola.StockActivo;
  try
    oArticulo := FRepositorioAlta.CargarValidado(
      ATrabajo.CodigoArticulo,
      FContextoSesion.Identidad.Usuario,
      FContextoSesion.Identidad.Grupo,
      oConfiguracionAlta);
    AsegurarLease(ATrabajo);
    if not SigueVigente(AConfiguracion) then
      raise EInvalidOpException.Create(
        'La configuración PrestaShop cambió antes del alta');
    if not FRepositorio.MarcarAltaEnCurso(
             ATrabajo.IdCola,
             ATrabajo.Token) then
      raise EInvalidOpException.Create(SLeasePrestaShopPerdido);
    oGrupos := TDictionary<string, Integer>.Create;
    oValores := TDictionary<string, Integer>.Create;
    try
      aIdsCategorias := AsegurarFamiliasAlta(
        ATrabajo,
        oArticulo,
        ACliente,
        AConfiguracion);
      AsegurarAtributosAlta(
        ATrabajo,
        oArticulo,
        ACliente,
        AConfiguracion,
        oGrupos,
        oValores);
      if not SigueVigente(AConfiguracion) then
        raise EInvalidOpException.Create(
          'La configuración PrestaShop cambió durante el alta');
      iIdProducto := AsegurarProductoAlta(
        ATrabajo,
        oArticulo,
        ACliente,
        AConfiguracion,
        aIdsCategorias);
      AsegurarCombinacionesAlta(
        ATrabajo,
        oArticulo,
        ACliente,
        oValores,
        iIdProducto);
      AsegurarFotoAlta(
        ATrabajo,
        oArticulo,
        ACliente,
        iIdProducto);
    finally
      FreeAndNil(oValores);
      FreeAndNil(oGrupos);
    end;
  except
    on E: ECierreForzadoPrestaShop do
      raise;
    on E: EConexionHttpTemporal do
      raise;
    on E: EAltaArticuloPrestaLocal do
      raise;
    on E: ERecursoPrestaAmbiguo do
      raise;
    on E: EAltaArticuloPrestaWorker do
      raise;
    on E: Exception do
      raise EAltaArticuloPrestaWorker.Create(
        CMarcaReanudacionAltaPrestaShop + E.Message);
  end;
end;

procedure THiloPrestaShopCola.Execute;
var
  bRecuperacion: Boolean;
  iInicializacionCom: HRESULT;
  iAhora: UInt64;
  iProximaRecuperacion: UInt64;
  iTiempoEspera: Cardinal;
  sMensaje: string;
begin
  iInicializacionCom := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  try
    NameThreadForDebugging('PrestaShopCola');
    FAvisoConfiguracion := False;
    bRecuperacion := True;
    iProximaRecuperacion := 0;
    while (not Terminated) and
          (not FContextoSesion.CerrandoAplicacion) do
    begin
      try
        FEstado.IniciarCiclo;
        ProcesarCiclo(bRecuperacion);
      except
        on E: Exception do
        begin
          sMensaje := OcultarClave(E.Message, FClaveOculta);
          FEstado.Publicar(acIncidencia, sMensaje);
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarError(
              'Cola PrestaShop: ' + sMensaje);
          LiberarSesion;
        end;
      end;
      if bRecuperacion then
      begin
        iProximaRecuperacion := GetTickCount64 +
          (UInt64(FSegundosCiclo) * 1000);
        bRecuperacion := False;
      end;
      if (not Terminated) and
         (not FContextoSesion.CerrandoAplicacion) then
      begin
        iAhora := GetTickCount64;
        if iAhora >= iProximaRecuperacion then
          bRecuperacion := True;
        if not bRecuperacion then
        begin
          iTiempoEspera := Cardinal(iProximaRecuperacion - iAhora);
          case EsperarProcesadoPrestaShop(iTiempoEspera) of
            wrSignaled:
              bRecuperacion := False;
            wrTimeout:
              bRecuperacion := True;
          else
            bRecuperacion := True;
          end;
        end;
      end;
    end;
  finally
    if Succeeded(iInicializacionCom) then
      CoUninitialize;
  end;
end;

procedure THiloPrestaShopCola.LiberarSesion;
begin
  FRepositorioAlta := nil;
  FRepositorio := nil;
  FSesion := nil;
end;

procedure THiloPrestaShopCola.EjecutarBarridoSiProcede(
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  sMensaje: string;
begin
  if AConfiguracion.HacerBarridoPeriodico then
  begin
    try
      FRepositorio.ReconciliarSiProcede(
        AConfiguracion.Cola,
        AConfiguracion.HorasBarrido,
        FUsuario);
    except
      on E: Exception do
      begin
        sMensaje := OcultarClave(E.Message, FClaveOculta);
        FEstado.Publicar(acIncidencia, sMensaje);
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarAviso(
            Format(SBarridoPrestaShopOmitido, [sMensaje]));
      end;
    end;
  end;
end;

procedure THiloPrestaShopCola.ProcesarCiclo(ARecuperacion: Boolean);
begin
  if ColaActiva then
    ProcesarCicloActivo(ARecuperacion)
  else
  begin
    LiberarSesion;
    FClaveOculta := '';
    FAvisoConfiguracion := False;
  end;
end;

procedure THiloPrestaShopCola.ProcesarCicloActivo(
  ARecuperacion: Boolean);
var
  bProcesar: Boolean;
  oCliente: IClienteCatalogoPrestaInstantanea;
  oClienteAlta: IClienteCatalogoAltaPresta;
  oConfiguracion: TConfiguracionGlobalPrestaShop;
  oTransporte: ITransporteAltaPresta;
  oTransporteHistorial: ITransportePrestaShopConHistorial;
  iHorasIncidencias: Integer;
begin
  if FSesion = nil then
  begin
    FSesion := FFabricaSesion.CrearSesion;
    if not Assigned(FSesion) then
      raise EInvalidOpException.Create(SSesionPrestaShopNoCreada);
    FRepositorio := FSesion.Repositorio;
    if not Assigned(FRepositorio) then
      raise EInvalidOpException.Create(SRepositorioPrestaShopNoCreado);
    FRepositorioAlta := FSesion.RepositorioAlta;
  end;
  oConfiguracion := PrepararConfiguracion;
  if oConfiguracion.Activo and ConfiguracionCompleta(oConfiguracion) and
     FRepositorio.DestinoSinConflictos(oConfiguracion, FUsuario) then
  begin
    FAvisoConfiguracion := False;
    if ARecuperacion and oConfiguracion.Activo then
      EjecutarBarridoSiProcede(oConfiguracion);
    bProcesar := not ARecuperacion;
    if ARecuperacion then
      bProcesar := FRepositorio.ReclamarRecuperacion(
        oConfiguracion.Cola.ClaveInstalacion,
        oConfiguracion.Cola.IdTienda,
        oConfiguracion.SegundosCiclo,
        FUsuario);
    if bProcesar then
    begin
      oTransporte := CrearTransportePresta(
        oConfiguracion.UrlApi,
        oConfiguracion.ClaveApi);
      oTransporteHistorial := CrearTransportePrestaShopConHistorial(
        oTransporte,
        FSesion.RegistradorEventos,
        oConfiguracion.UrlApi,
        oConfiguracion.ClaveApi);
      oCliente := TClienteCatalogoPresta.Create(
        oTransporteHistorial);
      if oConfiguracion.CrearArticulos then
      begin
        if not Assigned(FRepositorioAlta) then
          raise EInvalidOpException.Create(
            SRepositorioAltaPrestaShopNoCreado);
        oClienteAlta := TClienteCatalogoAltaPresta.Create(
          oTransporteHistorial);
      end;
      if ARecuperacion then
        FRepositorio.ReencolarProcesandoCaducadas(
          oConfiguracion.Cola.ClaveInstalacion,
          oConfiguracion.Cola.IdTienda,
          CMinutosReclamacionCaducada);
      { La exclusión es por fila mediante token y versión. Así un envío HTTP
        bloqueado no impide que otro proceso atienda el resto de la cola. }
      ProcesarPendientes(
        oCliente,
        oClienteAlta,
        oTransporteHistorial,
        oConfiguracion);
    end;
    if not Terminated and not FContextoSesion.CerrandoAplicacion then
    begin
      iHorasIncidencias := HorasIncidenciasColas(FParametrosApp);
      FEstado.FinalizarCiclo(OcultarClave(FSesion.LeerIncidencia(
        oConfiguracion.Cola.ClaveInstalacion,
        oConfiguracion.Cola.IdTienda, iHorasIncidencias), FClaveOculta),
        iHorasIncidencias);
    end;
  end
  else
  begin
    if oConfiguracion.Activo and (not FAvisoConfiguracion) then
    begin
      if ConfiguracionCompleta(oConfiguracion) then
        FEstado.Publicar(acIncidencia, SDestinoPrestaShopEnConflicto)
      else
        FEstado.Publicar(acIncidencia, SConfiguracionPrestaShopIncompleta);
      if Assigned(FRegistroLog) then
      begin
        if ConfiguracionCompleta(oConfiguracion) then
          FRegistroLog.RegistrarAviso(SDestinoPrestaShopEnConflicto)
        else
          FRegistroLog.RegistrarAviso(SConfiguracionPrestaShopIncompleta);
      end;
      FAvisoConfiguracion := True;
    end;
    if not oConfiguracion.Activo then
      FAvisoConfiguracion := False;
  end;
end;

procedure THiloPrestaShopCola.ProcesarPendientes(
  const ACliente: IClienteCatalogoPrestaInstantanea;
  const AClienteAlta: IClienteCatalogoAltaPresta;
  const ATransporteHistorial:
    ITransportePrestaShopConHistorial;
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  aPendientes: TArray<Int64>;
  bContinuar: Boolean;
  iIndice: Integer;
begin
  bContinuar := True;
  while ColaActiva and bContinuar and (not Terminated) and
        (not FContextoSesion.CerrandoAplicacion) and
        FControlTrabajo.PermiteNuevasReclamaciones do
  begin
    aPendientes := FRepositorio.BuscarPendientes(
      AConfiguracion.Cola.ClaveInstalacion,
      AConfiguracion.Cola.IdTienda,
      CFilasPorCiclo);
    bContinuar := Length(aPendientes) > 0;
    iIndice := 0;
    while ColaActiva and (iIndice <= High(aPendientes)) and bContinuar and
          (not Terminated) and
          (not FContextoSesion.CerrandoAplicacion) and
          FControlTrabajo.PermiteNuevasReclamaciones do
    begin
      bContinuar := SigueVigente(AConfiguracion);
      if bContinuar then
        bContinuar := ProcesarFila(
          aPendientes[iIndice],
          ACliente,
          AClienteAlta,
          ATransporteHistorial,
          AConfiguracion);
      Inc(iIndice);
    end;
  end;
end;

// Envio de un trabajo ya reclamado: lee, decide si toca tocar la web y
// cierra la fila como enviada.
procedure THiloPrestaShopCola.EnviarTrabajoReclamado(
  AIdCola: Int64;
  const AToken: string;
  const ACliente: IClienteCatalogoPrestaInstantanea;
  const AClienteAlta: IClienteCatalogoAltaPresta;
  const ATransporteHistorial:
    ITransportePrestaShopConHistorial;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  var ATrabajo: TTrabajoArticuloPrestaShop);
var
  oContextoHistorial: TContextoTransportePrestaShop;
begin
  FEstado.Publicar(acOcupada,
    Format(SColaEnviandoRegistro, [AIdCola]));
  ComprobarCierreSeguro;
  FRepositorio.LeerTrabajo(
    AIdCola,
    AToken,
    AConfiguracion.Cola,
    ATrabajo);
  if ATrabajo.IdCola = 0 then
    ATrabajo.IdCola := AIdCola;
  ATrabajo.Token := AToken;
  if ATrabajo.CodigoArticulo = '' then
    raise EInvalidOpException.Create(
      STrabajoPrestaShopNoReclamado);
  oContextoHistorial := Default(TContextoTransportePrestaShop);
  oContextoHistorial.IdCola := ATrabajo.IdCola;
  oContextoHistorial.IdReclamacion := ATrabajo.Token;
  oContextoHistorial.VersionReclamada :=
    ATrabajo.VersionReclamada;
  oContextoHistorial.NumeroIntento := ATrabajo.Intentos + 1;
  oContextoHistorial.Usuario := FUsuario;
  oContextoHistorial.OrdenOperacion := 0;
  ATransporteHistorial.EstablecerContexto(
    oContextoHistorial);
  if ((ATrabajo.AccionVisibilidad = avpDesactivar) and
      (not ATrabajo.EstaEnWeb)) or
     (ATrabajo.EstaEnWeb and
      ((ATrabajo.AccionVisibilidad = avpActivar) or
       AConfiguracion.CrearArticulos or
       (AConfiguracion.SincronizarStockPrecios and
        ((ATrabajo.TienePrecio and
          ATrabajo.TienePrecioProducto) or
         ATrabajo.TieneStock)))) then
  begin
    AsegurarLease(ATrabajo);
    if not SigueVigente(AConfiguracion) then
      raise EInvalidOpException.Create(
        'La configuración PrestaShop cambió durante el envío');
    if ATrabajo.AccionVisibilidad = avpDesactivar then
      ProcesarDesactivacion(ATrabajo, ACliente)
    else
      ProcesarArticulo(
        ATrabajo,
        ACliente,
        AClienteAlta,
        AConfiguracion);
  end;
  ComprobarCierreSeguro;
  FRepositorio.MarcarEnviada(
    ATrabajo.IdCola,
    ATrabajo.Token,
    FUsuario,
    ATrabajo.TieneProximoCambioPrecio,
    ATrabajo.ProximoCambioPrecio);
  FEstado.Publicar(acCorrecta,
    Format(SColaRegistroEnviado, [AIdCola]));
end;

// Reparto del fallo: liberar la reclamacion, anotarlo como incidencia
// terminal o dejarlo para otro intento. False detiene el ciclo.
function THiloPrestaShopCola.TratarErrorTrabajo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  AIdCola: Int64;
  const AToken: string;
  E: Exception): Boolean;
begin
  Result := True;
  FEstado.Publicar(acIncidencia, Format(SColaErrorRegistro,
    [AIdCola, OcultarClave(E.Message, FClaveOculta)]));
  if FControlTrabajo.DebeLiberarTrabajo or
     (E is ECierreForzadoPrestaShop) then
    LiberarTrabajoActual(AIdCola, AToken)
  else if not ColaActiva then
  begin
    LiberarTrabajoActual(AIdCola, AToken);
    Result := False;
  end
  else if E is EAltaArticuloPrestaLocal then
    GuardarIncidenciaTerminal(
      ATrabajo,
      AConfiguracion,
      E.Message)
  else if E is EConfiguracionPrestaInvalida then
    GuardarIncidenciaTerminal(
      ATrabajo,
      AConfiguracion,
      E.Message)
  else if E is ERecursoPrestaNoEncontrado then
    GuardarRecursoNoEncontrado(
      ATrabajo,
      AConfiguracion,
      ERecursoPrestaNoEncontrado(E))
  else if E is ERecursoPrestaAmbiguo then
    GuardarRecursoAmbiguo(
      ATrabajo,
      AConfiguracion,
      ERecursoPrestaAmbiguo(E))
  else if E is EConexionHttpTemporal then
  begin
    GuardarSinConexion(ATrabajo, AConfiguracion, E.Message);
    Result := False;
  end
  else
    GuardarError(ATrabajo, AConfiguracion, E.Message);
end;

function THiloPrestaShopCola.ProcesarFila(
  AIdCola: Int64;
  const ACliente: IClienteCatalogoPrestaInstantanea;
  const AClienteAlta: IClienteCatalogoAltaPresta;
  const ATransporteHistorial:
    ITransportePrestaShopConHistorial;
  const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
var
  oTrabajo: TTrabajoArticuloPrestaShop;
  sToken: string;
begin
  Result := True;
  if FControlTrabajo.IntentarIniciarTrabajo then
  begin
    try
      if FRepositorio.MarcarProcesando(
        AIdCola,
        AConfiguracion.Cola.ClaveInstalacion,
        AConfiguracion.Cola.IdTienda,
        FUsuario,
        sToken) then
      begin
        oTrabajo := Default(TTrabajoArticuloPrestaShop);
        oTrabajo.IdCola := AIdCola;
        oTrabajo.Token := sToken;
        try
          try
            EnviarTrabajoReclamado(
              AIdCola,
              sToken,
              ACliente,
              AClienteAlta,
              ATransporteHistorial,
              AConfiguracion,
              oTrabajo);
          except
            on E: Exception do
              Result := TratarErrorTrabajo(
                oTrabajo,
                AConfiguracion,
                AIdCola,
                sToken,
                E);
          end;
        finally
          ATransporteHistorial.LimpiarContexto;
        end;
      end;
    finally
      FControlTrabajo.FinalizarTrabajo;
    end;
  end;
end;

procedure THiloPrestaShopCola.LiberarTrabajoActual(
  AIdCola: Int64;
  const AToken: string);
begin
  if FRepositorio.LiberarReclamacionSinIntento(
    AIdCola,
    AToken,
    FUsuario) then
  begin
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarInformacion(
        Format(STrabajoPrestaShopReencolado, [AIdCola]));
  end
  else if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      Format(STrabajoPrestaShopNoLiberado, [AIdCola]));
end;

procedure THiloPrestaShopCola.ProcesarDesactivacion(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ACliente: IClienteCatalogoPresta);
var
  bEncontrado: Boolean;
  iIdProducto: Integer;
begin
  bEncontrado := True;
  iIdProducto := 0;
  AsegurarLease(ATrabajo);
  try
    iIdProducto := ACliente.BuscarProductoUnico(
      ATrabajo.CodigoArticulo,
      ATrabajo.IdTienda);
  except
    on E: ERecursoPrestaNoEncontrado do
    begin
      if SameText(E.TipoRecurso, CTipoRecursoProducto) then
        bEncontrado := False
      else
        raise;
    end;
  end;
  if bEncontrado then
  begin
    AsegurarLease(ATrabajo);
    ACliente.AsegurarEstadoActivoProducto(
      iIdProducto,
      ATrabajo.IdTienda,
      False);
    AsegurarLease(ATrabajo);
  end;
end;

procedure THiloPrestaShopCola.ProcesarArticulo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ACliente: IClienteCatalogoPrestaInstantanea;
  const AClienteAlta: IClienteCatalogoAltaPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  bAltaCompletada: Boolean;
  dActual: Double;
  iLinea: Integer;
  oPlan: TPlanArticuloPrestaShop;
begin
  bAltaCompletada := False;
  if AConfiguracion.CrearArticulos and ATrabajo.ReanudarAlta then
  begin
    CrearOCompletarArticulo(
      ATrabajo,
      AClienteAlta,
      AConfiguracion);
    bAltaCompletada := True;
  end;
  try
    oPlan := PrepararPlanArticulo(
      ATrabajo,
      ACliente,
      AConfiguracion.SincronizarStockPrecios);
  except
    on E: ERecursoPrestaNoEncontrado do
    begin
      if AConfiguracion.CrearArticulos and
         SameText(E.TipoRecurso, CTipoRecursoProducto) then
      begin
        if not bAltaCompletada then
          CrearOCompletarArticulo(
            ATrabajo,
            AClienteAlta,
            AConfiguracion);
        oPlan := PrepararPlanArticulo(
          ATrabajo,
          ACliente,
          AConfiguracion.SincronizarStockPrecios);
      end
      else
        raise;
    end;
  end;
  if AConfiguracion.SincronizarStockPrecios then
  begin
    if ATrabajo.TienePrecio then
    begin
      if not ATrabajo.TienePrecioProducto then
        raise EInvalidOpException.CreateFmt(
          SPrecioProductoPrestaShopAusente,
          [ATrabajo.CodigoArticulo]);
      AsegurarLease(ATrabajo);
      dActual := ACliente.LeerPrecioProducto(
        oPlan.IdProducto,
        ATrabajo.IdTienda);
      if PrecioDiferente(dActual, ATrabajo.PrecioProducto) then
      begin
        AsegurarLease(ATrabajo);
        ACliente.ActualizarPrecioProducto(
          oPlan.IdProducto,
          ATrabajo.IdTienda,
          ATrabajo.PrecioProducto);
        AsegurarLease(ATrabajo);
        dActual := ACliente.LeerPrecioProducto(
          oPlan.IdProducto,
          ATrabajo.IdTienda);
        if PrecioDiferente(dActual, ATrabajo.PrecioProducto) then
          raise EInvalidOpException.CreateFmt(
            SPrecioProductoNoVerificado,
            [oPlan.IdProducto]);
      end;
    end;
    iLinea := 0;
    while iLinea <= High(ATrabajo.Lineas) do
    begin
      if not oPlan.Lineas[iLinea].Omitir then
        ProcesarLinea(
          ATrabajo,
          ATrabajo.Lineas[iLinea],
          oPlan.Lineas[iLinea],
          ACliente);
      Inc(iLinea);
    end;
  end;
  if ATrabajo.AccionVisibilidad = avpActivar then
  begin
    AsegurarLease(ATrabajo);
    ACliente.AsegurarEstadoActivoProducto(
      oPlan.IdProducto,
      ATrabajo.IdTienda,
      True);
    AsegurarLease(ATrabajo);
  end;
end;

function THiloPrestaShopCola.PrepararPlanArticulo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ACliente: IClienteCatalogoPrestaInstantanea;
  ASincronizarStockPrecios: Boolean): TPlanArticuloPrestaShop;
var
  aCombinaciones: TArray<TCombinacionPresta>;
  aStocks: TArray<TStockDisponiblePresta>;
  bNecesitaCombinaciones: Boolean;
  bNecesitaStocks: Boolean;
  iAtributo: Integer;
  iLinea: Integer;
  oCombinacion: TCombinacionPresta;
  oStock: TStockDisponiblePresta;
begin
  Result := Default(TPlanArticuloPrestaShop);
  AsegurarLease(ATrabajo);
  Result.IdProducto := ACliente.BuscarProductoUnico(
    ATrabajo.CodigoArticulo,
    ATrabajo.IdTienda);
  AsegurarLease(ATrabajo);
  if ASincronizarStockPrecios then
  begin
    bNecesitaCombinaciones := False;
    bNecesitaStocks := False;
    iLinea := 0;
    while iLinea <= High(ATrabajo.Lineas) do
    begin
      if ATrabajo.Lineas[iLinea].EsCombinacion and
         (ATrabajo.Lineas[iLinea].TienePrecio or
          ATrabajo.Lineas[iLinea].TieneStock) then
        bNecesitaCombinaciones := True;
      if ATrabajo.Lineas[iLinea].TieneStock then
        bNecesitaStocks := True;
      Inc(iLinea);
    end;
    if bNecesitaCombinaciones then
    begin
      aCombinaciones := ACliente.CargarCombinacionesProducto(
        Result.IdProducto,
        ATrabajo.IdTienda);
      AsegurarLease(ATrabajo);
    end;
    if bNecesitaStocks then
    begin
      aStocks := ACliente.CargarStocksProducto(
        Result.IdProducto,
        ATrabajo.IdTienda);
      AsegurarLease(ATrabajo);
    end;
    SetLength(Result.Lineas, Length(ATrabajo.Lineas));
    iLinea := 0;
    while iLinea <= High(ATrabajo.Lineas) do
    begin
      iAtributo := 0;
      if ATrabajo.Lineas[iLinea].EsCombinacion and
         (ATrabajo.Lineas[iLinea].TienePrecio or
          ATrabajo.Lineas[iLinea].TieneStock) then
      begin
        try
          oCombinacion := ResolverCombinacionEnInstantanea(
            aCombinaciones,
            ATrabajo.Lineas[iLinea].CodigoSku,
            Result.IdProducto);
          iAtributo := oCombinacion.Id;
          Result.Lineas[iLinea].IdCombinacion := iAtributo;
          Result.Lineas[iLinea].ImpactoPrecio :=
            oCombinacion.ImpactoPrecio;
        except
          on E: ERecursoPrestaNoEncontrado do
          begin
            if ATrabajo.Lineas[iLinea].EstaActiva then
              raise
            else
              Result.Lineas[iLinea].Omitir := True;
          end;
        end;
      end;
      if ATrabajo.Lineas[iLinea].TieneStock and
         (not Result.Lineas[iLinea].Omitir) then
      begin
        oStock := ResolverStockEnInstantanea(
          aStocks,
          Result.IdProducto,
          iAtributo,
          ATrabajo.IdTienda);
        Result.Lineas[iLinea].IdStock := oStock.Id;
        Result.Lineas[iLinea].CantidadStock := oStock.Cantidad;
      end;
      Inc(iLinea);
    end;
  end;
end;

procedure THiloPrestaShopCola.ProcesarLinea(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ALinea: TLineaArticuloPrestaShop;
  const AMapeo: TMapeoLineaPrestaShop;
  const ACliente: IClienteCatalogoPresta);
var
  dActual: Double;
  dImpacto: Double;
  iActual: Integer;
begin
  if ALinea.TienePrecio and ALinea.EsCombinacion then
  begin
    dImpacto := ALinea.Precio - ATrabajo.PrecioProducto;
    dActual := AMapeo.ImpactoPrecio;
    if PrecioDiferente(dActual, dImpacto) then
    begin
      AsegurarLease(ATrabajo);
      ACliente.ActualizarImpactoPrecioCombinacion(
        AMapeo.IdCombinacion,
        ATrabajo.IdTienda,
        dImpacto);
      AsegurarLease(ATrabajo);
      dActual := ACliente.LeerImpactoPrecioCombinacion(
        AMapeo.IdCombinacion,
        ATrabajo.IdTienda);
      if PrecioDiferente(dActual, dImpacto) then
        raise EInvalidOpException.CreateFmt(
          SPrecioCombinacionNoVerificado,
          [AMapeo.IdCombinacion]);
    end;
  end;
  if ALinea.TieneStock then
  begin
    iActual := AMapeo.CantidadStock;
    if iActual <> ALinea.Cantidad then
    begin
      AsegurarLease(ATrabajo);
      ACliente.ActualizarCantidadStock(
        AMapeo.IdStock,
        ATrabajo.IdTienda,
        ALinea.Cantidad);
      AsegurarLease(ATrabajo);
      iActual := ACliente.LeerCantidadStock(
        AMapeo.IdStock,
        ATrabajo.IdTienda);
      if iActual <> ALinea.Cantidad then
        raise EInvalidOpException.CreateFmt(
          SStockPrestaShopNoVerificado,
          [AMapeo.IdStock]);
    end;
  end;
end;

procedure THiloPrestaShopCola.GuardarError(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AMensaje: string);
var
  iEspera: Integer;
  sEstado: string;
  sMensaje: string;
begin
  iEspera := CalcularEspera(ATrabajo.Intentos);
  if (ATrabajo.Intentos + 1) >= AConfiguracion.MaxIntentos then
    sEstado := 'ERROR'
  else
    sEstado := 'PENDIENTE';
  sMensaje := OcultarClave(AMensaje, AConfiguracion.ClaveApi);
  FRepositorio.GuardarErrorIntento(
    ATrabajo.IdCola,
    ATrabajo.Token,
    sEstado,
    iEspera,
    sMensaje,
    FUsuario);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      Format(
        'Cola PrestaShop, artículo %s: %s',
        [ATrabajo.CodigoArticulo, sMensaje]));
end;

procedure THiloPrestaShopCola.GuardarSinConexion(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AMensaje: string);
var
  sMensaje: string;
begin
  sMensaje := OcultarClave(AMensaje, AConfiguracion.ClaveApi);
  FRepositorio.GuardarErrorIntento(
    ATrabajo.IdCola,
    ATrabajo.Token,
    'PENDIENTE',
    CSegundosReintentoSinConexion,
    sMensaje,
    FUsuario,
    False);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      Format(
        'Cola PrestaShop aplazada por falta de conexión, artículo %s; ' +
        'el intento no se contabiliza: %s',
        [ATrabajo.CodigoArticulo, sMensaje]));
end;

procedure THiloPrestaShopCola.GuardarIncidenciaTerminal(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AMensaje: string);
var
  sMensaje: string;
begin
  sMensaje := OcultarClave(AMensaje, AConfiguracion.ClaveApi);
  FRepositorio.GuardarErrorIntento(
    ATrabajo.IdCola,
    ATrabajo.Token,
    'ERROR',
    0,
    sMensaje,
    FUsuario);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      Format(
        'Incidencia terminal PrestaShop, artículo %s: %s',
        [ATrabajo.CodigoArticulo, sMensaje]));
end;

procedure THiloPrestaShopCola.GuardarRecursoAmbiguo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AError: ERecursoPrestaAmbiguo);
var
  sMensaje: string;
begin
  if SameText(AError.TipoRecurso, CTipoRecursoProducto) then
    sMensaje := Format(
      SProductoPrestaShopAmbiguo,
      [AError.Cantidad, ATrabajo.CodigoArticulo])
  else
    sMensaje := Format(
      SRecursoPrestaShopAmbiguo,
      [AError.Cantidad,
       AError.TipoRecurso,
       ATrabajo.CodigoArticulo]);
  GuardarIncidenciaTerminal(
    ATrabajo,
    AConfiguracion,
    sMensaje);
end;

procedure THiloPrestaShopCola.GuardarRecursoNoEncontrado(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AError: ERecursoPrestaNoEncontrado);
var
  sMensaje: string;
begin
  if SameText(AError.TipoRecurso, CTipoRecursoProducto) then
  begin
    if AConfiguracion.CrearArticulos then
      sMensaje := Format(
        SProductoPrestaShopNoEncontradoTrasAlta,
        [ATrabajo.CodigoArticulo])
    else
      sMensaje := Format(
        SProductoPrestaShopNoEncontradoSinAlta,
        [ATrabajo.CodigoArticulo]);
  end
  else
    sMensaje := Format(
      SRecursoPrestaShopNoEncontrado,
      [AError.TipoRecurso, ATrabajo.CodigoArticulo]);
  GuardarIncidenciaTerminal(
    ATrabajo,
    AConfiguracion,
    sMensaje);
end;

end.

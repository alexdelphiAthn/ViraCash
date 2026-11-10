{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoTallas                                    }
{    Tipo:       Libreria (coordinador)                                        }
{ Version:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Implementacion de IModoEntradaGrid en modo TALLAS EN HORIZONTAL (una      }
{    fila por articulo+color y N columnas de cantidad por talla, pivotadas     }
{    por conjunto).                                                            }
{                                                                              }
{    CONSOLIDA: cada combinacion articulo+atributos no talla es UNA linea;     }
{    una lectura con talla (SKU/barras) suma +1 en la celda de su talla,       }
{    como la caja pero en horizontal. Las lineas heredadas de otros modos      }
{    se convierten al construir.                                              }
{                                                                              }
{    Coordinador: reparte el trabajo entre el modelo (inLibModoTallasModelo),  }
{    las conversiones (inLibModoTallasConversion), el adaptador de lineas      }
{    (inLibModoTallasLineas), la presentacion                                  }
{    (inLibModoTallasPresentacion) y el puerto de persistencia. No contiene    }
{    SQL ni toca controles.                                                    }
{                                                                              }
{    REQUISITOS DEL HOST:                                                      }
{      - Tabla de celdas y campos de pivote (TGridTallasConfig).               }
{      - Master y lineas ABIERTOS antes de Construir.                          }
{      - Campos ATTRn definidos si hay atributos no talla (color).             }
{******************************************************************************}
unit inLibColumnasSkuModoTallas;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Vcl.Dialogs,
  inLibColumnasSkuIntf, inLibGridTallasInline,
  inLibArticulosValidadorIntf, inLibArticulosAtributosIntf,
  inLibModoTallasIntf, inLibModoTallasModelo,
  inLibModoTallasConversion, inLibModoTallasLineas,
  inLibModoTallasPresentacion;

type
  TModoEntradaTallas = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig: TConfigColumnasSku;
    FCfgTallas: TGridTallasConfig;
    FLookup: IArticulosAtributosLookup;
    FPersistencias: TServiciosPersistenciaModoTallas;
    FLineas: TServiciosLineasDocumentoTallas;
    // Referencia NO propietaria: el ciclo de vida lo lleva FLineas.
    FLineasCds: TLineasDocumentoTallasCds;
    FModelo: TModeloTallas;
    FPresentacion: TPresentacionModoTallas;
    FOnResuelto: TSkuResueltoEvent;
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    // True si la ultima entrada traia talla (lectura de SKU/barras):
    // el foco vuelve al articulo para encadenar lecturas.
    FUltimaConTalla: Boolean;
    procedure LogSesion(const ATexto: string);
    function CamposLineas: TCamposLineasTallas;
    function ConfigPersistencia: TConfigPersistenciaTallas;
    procedure CrearColaboradores;
    procedure EntrarEdicion(Sender: TObject);
    procedure SalirEdicion(Sender: TObject);
    procedure AtributosEscritos(
      const AValores, ANombres: TValoresAttrTallas);
    procedure ResolverEntradaDiferida(const AEntrada: string);
    function UnidadesDocumento: Double;
    procedure RederivarLineasExistentes;
    procedure MigrarCeldasAlmacen;
    procedure ConvertirDocumento;
    function ResolverArticulo(
      const AEntrada: string): TArtResolucionEntrada;
    function DatosAlta(const AResolucion: TArtResolucionEntrada;
      const AAtributos: TAtributosLineaTallas;
      const AAlmacen: string): TAltaLineaTallas;
    procedure SumarTallaLeida(const AResolucion: TArtResolucionEntrada;
      const AAtributos: TAtributosLineaTallas; const ATalla: string);
    procedure NotificarResuelto(
      const AResolucion: TArtResolucionEntrada);
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgTallas: TGridTallasConfig);
    destructor Destroy; override;
    procedure Construir(
      AOnResuelto: TSkuResueltoEvent;
      AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
    // Des-pivote al abandonar el modo: cada celda con cantidad pasa a
    // una linea por SKU (cantidad plana) y se limpian las celdas.
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgArticulos;

constructor TModoEntradaTallas.Create(
  const AConfig: TConfigColumnasSku;
  const ACfgTallas: TGridTallasConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FCfgTallas := ACfgTallas;
  FCfgTallas.FieldArticulo := AConfig.Campos.CodigoArt;
  FLookup := AConfig.LookupAtributos;
  if not Assigned(FLookup) then
    raise Exception.Create(SErrorLookupAtributosNoInyectado);
  CrearColaboradores;
end;
destructor TModoEntradaTallas.Destroy;
begin
  // Soltar los hooks del cds ANTES de liberar la presentacion: su
  // callback de recarga apunta a los temporizadores del colaborador.
  if FLineasCds <> nil then
  begin
    FLineasCds.SoltarHooks;
    FLineasCds.OnRecargarCeldas := nil;
    FLineasCds := nil;
  end;
  FreeAndNil(FPresentacion);
  FreeAndNil(FModelo);
  FLineas := Default(TServiciosLineasDocumentoTallas);
  FPersistencias := Default(TServiciosPersistenciaModoTallas);
  FLookup := nil;
  inherited;
end;
procedure TModoEntradaTallas.LogSesion(const ATexto: string);
begin
  if Assigned(FConfig.ContextoSesion) then
    FConfig.ContextoSesion.LogSesion(ATexto);
end;
function TModoEntradaTallas.CamposLineas: TCamposLineasTallas;
var
  i: Integer;
begin
  Result := Default(TCamposLineasTallas);
  Result.CodigoArt := FConfig.Campos.CodigoArt;
  Result.CodigoUnidad := FConfig.Campos.CodigoUnidad;
  Result.Descripcion := FConfig.Campos.Descripcion;
  Result.Cantidad := FConfig.Campos.Cantidad;
  Result.Almacen := FConfig.Campos.Almacen;
  Result.NumAtributos := FConfig.Campos.NumAtributos;
  for i := 1 to 5 do
  begin
    Result.AttrValor[i] := FConfig.Campos.AttrValor[i];
    Result.AttrNombre[i] := FConfig.Campos.AttrNombre[i];
  end;
  Result.Linea := FCfgTallas.FieldLinea;
  Result.ConjuntoPivot := FCfgTallas.FieldConjuntoPivot;
  Result.PrecioBase := FCfgTallas.FieldPrecioBase;
  Result.CampoPorcentajeDto := FCfgTallas.CampoPorcentajeDto;
  Result.TotalUds := FCfgTallas.FieldTotalUds;
  Result.TotalLinea := FCfgTallas.FieldTotalLinea;
end;
function TModoEntradaTallas.ConfigPersistencia
  : TConfigPersistenciaTallas;
begin
  Result := Default(TConfigPersistenciaTallas);
  Result.Master := FCfgTallas.SourceMaster.DataSet;
  Result.Usuario := FCfgTallas.Usuario;
  Result.CampoSerieMaster := FCfgTallas.FieldSerieMaster;
  Result.CampoNumeroMaster := FCfgTallas.FieldNumeroMaster;
  Result.CamposDocExtraMaster := FCfgTallas.CamposDocExtraMaster;
  Result.TablaCeldas := FCfgTallas.TablaCeldas;
  Result.CampoSerieCel := FCfgTallas.FieldSerieCel;
  Result.CampoNumeroCel := FCfgTallas.FieldNumeroCel;
  Result.CampoLineaCel := FCfgTallas.FieldLineaCel;
  Result.CampoFilaCel := FCfgTallas.FieldFilaCel;
  Result.CampoAvPivotCel := FCfgTallas.FieldAvPivotCel;
  Result.CampoCantidadCel := FCfgTallas.FieldCantidadCel;
  Result.CampoAlmacenCel := FCfgTallas.FieldAlmacenCel;
  Result.CamposDocExtraCel := FCfgTallas.CamposDocExtraCel;
  Result.IdFilaFijo := FCfgTallas.IdFilaFijo;
end;
procedure TModoEntradaTallas.CrearColaboradores;
var
  Busqueda: IBusquedaSkusTallas;
begin
  if not Assigned(FConfig.Servicios.PersistenciaTallas) then
    raise EArgumentNilException.Create('Servicios.PersistenciaTallas');
  if not Assigned(FConfig.Servicios.Busqueda) then
    raise EArgumentNilException.Create('Servicios.Busqueda');
  if not Assigned(FConfig.Servicios.Paleta) then
    raise EArgumentNilException.Create('Servicios.Paleta');
  FPersistencias := FConfig.Servicios.PersistenciaTallas.
    CrearPersistencia(ConfigPersistencia);
  Busqueda := FConfig.Servicios.Busqueda.CrearBusqueda;
  FLineasCds := TLineasDocumentoTallasCds.Create(FConfig.Cds,
                                                 CamposLineas);
  FLineasCds.Registro := LogSesion;
  FLineas.Rederivacion := FLineasCds;
  FLineas.Desmontaje := FLineasCds;
  FLineas.Entrada := FLineasCds;
  FLineas.Presentacion := FLineasCds;
  FModelo := TModeloTallas.Create(FLookup, FPersistencias.Modelo,
    FConfig.Servicios.Paleta, LogSesion);
  FPresentacion := TPresentacionModoTallas.Create(FConfig, FCfgTallas,
    FLineas.Presentacion, FPersistencias.Presentacion,
    FPersistencias.GridInline, Busqueda, LogSesion);
  FPresentacion.OnResolverEntrada := ResolverEntradaDiferida;
  FPresentacion.OnEntrarEdicion := EntrarEdicion;
  FPresentacion.OnSalirEdicion := SalirEdicion;
  FLineasCds.OnRecargarCeldas := FPresentacion.ArmarRecarga;
end;
procedure TModoEntradaTallas.EntrarEdicion(Sender: TObject);
begin
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
end;
procedure TModoEntradaTallas.SalirEdicion(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;
function TModoEntradaTallas.UnidadesDocumento: Double;
begin
  Result := TModeloTallas.UnidadesDocumento(
    FPersistencias.Entrada.ConsultarTotalesPorLinea,
    FLineas.Entrada.CantidadesPorLinea);
end;
procedure TModoEntradaTallas.AtributosEscritos(
  const AValores, ANombres: TValoresAttrTallas);
begin
  FPresentacion.MostrarColumnasAtributo(AValores, ANombres);
end;

procedure TModoEntradaTallas.RederivarLineasExistentes;
var
  Rederivacion: TRederivacionTallas;
begin
  Rederivacion := TRederivacionTallas.Create(FLineas.Rederivacion,
    FPersistencias.Rederivacion, FModelo, FConfig.Distribuido,
    FPresentacion.AlmacenStock, LogSesion, AtributosEscritos);
  try
    Rederivacion.Ejecutar;
  finally
    FreeAndNil(Rederivacion);
  end;
end;

procedure TModoEntradaTallas.MigrarCeldasAlmacen;
var
  iMigradas: Integer;
begin
  if FConfig.Distribuido and
     (Trim(FPresentacion.AlmacenStock) = '') then
    // No deberia ocurrir (AsegurarAlmacenDefecto corre antes); se deja
    // tal cual y el grid seguira mostrando la suma correcta.
    LogSesion('ModoTallas.MigrarCeldas: sin almacen por defecto; las ' +
              'celdas sin almacen no se migran')
  else
  begin
    iMigradas := FPersistencias.Entrada.MigrarCeldasFormato(
      FConfig.Distribuido, Trim(FPresentacion.AlmacenStock));
    if iMigradas > 0 then
      LogSesion(Format('ModoTallas.MigrarCeldas: %d celdas ' +
        'unificadas (distribuido=%s)',
        [iMigradas, BoolToStr(FConfig.Distribuido, True)]));
  end;
end;

procedure TModoEntradaTallas.ConvertirDocumento;
var
  bTransaccionPropia: Boolean;
  rUnidadesAntes: Double;
begin
  // Conversion ATOMICA: la fusion mezcla posts de dataset y escrituras
  // de celdas; interrumpida a medias dejaba celdas ya sumadas con
  // lineas sin fusionar y cada reentrada volvia a sumar (cantidades
  // duplicadas y pedida disparada).
  bTransaccionPropia := not FPersistencias.Entrada.EnTransaccion;
  if bTransaccionPropia then
    FPersistencias.Entrada.IniciarTransaccion;
  try
    rUnidadesAntes := UnidadesDocumento;
    // Lineas heredadas de otros modos / documento reabierto: derivar
    // pivote y atributos, volcar cantidades y fusionar duplicadas.
    RederivarLineasExistentes;
    // Unificar celdas segun el formato (las heredadas se vuelcan a
    // almacen '', por eso la migracion va DESPUES del rederivar).
    MigrarCeldasAlmacen;
    // La fusion no puede perder ni duplicar unidades: si no cuadra,
    // excepcion y rollback (el host degrada a modo SKU con los datos
    // intactos).
    TModeloTallas.ComprobarInvarianteUnidades('Construir',
      rUnidadesAntes, UnidadesDocumento, LogSesion);
    if bTransaccionPropia then
      FPersistencias.Entrada.ConfirmarTransaccion;
  except
    if bTransaccionPropia then
      FPersistencias.Entrada.RevertirTransaccion;
    raise;
  end;
end;

procedure TModoEntradaTallas.Construir(
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
begin
  FOnResuelto := AOnResuelto;
  FOnEntrarEdicion := AOnEntrarEdicion;
  FOnSalirEdicion := AOnSalirEdicion;
  FPresentacion.Construir;
  // El gestor antes de la conversion: la conversion persiste celdas.
  FPresentacion.CrearGestor;
  // Hook AfterPost (como sesiones): recarga celdas tras el Post
  // implicito de cambiar de fila. Silenciado hasta acabar la carga
  // diferida para no recargar N veces en la conversion.
  FLineas.Entrada.IniciarProceso;
  FLineasCds.EngancharHooks;
  ConvertirDocumento;
  FPresentacion.ProgramarCargaInicial;
end;

procedure TModoEntradaTallas.Desmontar;
var
  Desmontaje: TDesmontajeTallas;
begin
  if (FConfig.Cds <> nil) and FConfig.Cds.Active then
  begin
    Desmontaje := TDesmontajeTallas.Create(FLineas.Desmontaje,
      FPersistencias.Desmontaje, FModelo, LogSesion);
    try
      Desmontaje.Ejecutar;
    finally
      FreeAndNil(Desmontaje);
    end;
  end;
end;

procedure TModoEntradaTallas.MostrarEditor;
begin
  FPresentacion.MostrarEditor;
end;

procedure TModoEntradaTallas.ResolverEntradaDiferida(
  const AEntrada: string);
begin
  if ResolverEntrada(AEntrada) then
  begin
    FPresentacion.CerrarEditorTrasResolver;
    FPresentacion.EnfocarTrasResolver(FUltimaConTalla);
  end;
end;

function TModoEntradaTallas.ResolverArticulo(
  const AEntrada: string): TArtResolucionEntrada;
var
  Validador: IArticulosValidador;
begin
  Validador := FConfig.ValidadorArticulos;
  if not Assigned(Validador) then
    raise Exception.Create(SErrorValidadorArticulosNoInyectado);
  try
    Result := Validador.Resolver(AEntrada);
  finally
    Validador := nil;
  end;
end;

function TModoEntradaTallas.DatosAlta(
  const AResolucion: TArtResolucionEntrada;
  const AAtributos: TAtributosLineaTallas;
  const AAlmacen: string): TAltaLineaTallas;
begin
  Result := Default(TAltaLineaTallas);
  Result.Articulo := AResolucion.CodigoArticulo;
  Result.CodigoSku := AResolucion.CodigoSku;
  Result.Descripcion := AResolucion.DescripcionArticulo;
  Result.Almacen := AAlmacen;
  Result.Valores := AAtributos.Valores;
  Result.Nombres := AAtributos.Nombres;
  Result.ConjuntoTalla := AAtributos.ConjuntoTalla;
  Result.OrdenTalla := AAtributos.OrdenTalla;
  // La linea maestra horizontal necesita una identidad no vacia antes
  // del Post. Si se eligio el articulo padre, se conserva el prefijo
  // articulo/atributos; la talla concreta se completara al des-pivotar.
  if Result.CodigoSku = '' then
    Result.CodigoSku := TModeloTallas.ComponerSkuLinea(
      Result.Articulo, Result.Valores, Result.OrdenTalla, '');
  // Precio del documento (su tarifa, su fecha): la consolidacion del
  // escaneo NO fusiona en una linea de precio distinto.
  if Assigned(FConfig.ObtenerPrecioSku) then
  begin
    Result.Precio := FConfig.ObtenerPrecioSku(
      AResolucion.CodigoArticulo, AResolucion.CodigoSku);
    Result.TienePrecio := True;
  end;
end;

procedure TModoEntradaTallas.SumarTallaLeida(
  const AResolucion: TArtResolucionEntrada;
  const AAtributos: TAtributosLineaTallas; const ATalla: string);
var
  idAv, iLinea: Integer;
begin
  // Lectura con talla: +1 en la celda de esa talla (como caja). En
  // formato distribuido NO se suma en linea: el reparto por almacen
  // entra por el distribuidor (como sesiones).
  if ATalla <> '' then
  begin
    if FConfig.Distribuido then
      LogSesion('ModoTallas.Resolver: distribuido, cantidades via ' +
                'distribuidor')
    else
    begin
      idAv := FModelo.IdAvDeTalla(AResolucion.CodigoArticulo,
                                  AAtributos.OrdenTalla, ATalla);
      iLinea := FLineas.Entrada.NumeroLineaActual;
      if idAv > 0 then
      begin
        FPersistencias.Entrada.SumarEnCelda(iLinea, idAv, 1, '');
        FPresentacion.RefrescarLineaActual(iLinea);
        FUltimaConTalla := True;
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.NotificarResuelto(
  const AResolucion: TArtResolucionEntrada);
begin
  if Assigned(FOnResuelto) then
  begin
    if AResolucion.CodigoSku <> '' then
      FOnResuelto(AResolucion.CodigoArticulo, AResolucion.CodigoSku,
                  AResolucion.DescripcionArticulo, True)
    else
      FOnResuelto(AResolucion.CodigoArticulo,
                  AResolucion.CodigoArticulo,
                  AResolucion.DescripcionArticulo, True);
  end;
end;

function TModoEntradaTallas.ResolverEntrada(
  const AEntrada: string): Boolean;
var
  Resolucion: TArtResolucionEntrada;
  Atributos: TAtributosLineaTallas;
  Partes: TArray<string>;
  Alta: TAltaLineaTallas;
  sEntrada, sTalla, sAlmacen: string;
begin
  Result := False;
  FUltimaConTalla := False;
  sEntrada := Trim(AEntrada);
  if sEntrada <> '' then
  begin
    Resolucion := ResolverArticulo(sEntrada);
    LogSesion(Format('ModoTallas.Resolver: "%s" encontrado=%s sku="%s"',
      [sEntrada, BoolToStr(Resolucion.Encontrado, True),
       Resolucion.CodigoSku]));
    if Resolucion.Encontrado then
    begin
      // Si la entrada trajo un SKU cerrado (barras / SKU completo), sus
      // valores mandan: color de la linea y talla de la celda.
      Partes := TModeloTallas.PartesDeSku(Resolucion.CodigoArticulo,
                                          Resolucion.CodigoSku);
      Atributos := FModelo.CalcularAtributosLinea(
        Resolucion.CodigoArticulo, Partes, False);
      sTalla := TModeloTallas.ValorTallaDePartes(Partes,
                                                 Atributos.OrdenTalla);
      LogSesion(Format(
        'ModoTallas.Resolver: pivote=%d ordTalla=%d talla="%s"',
        [Atributos.ConjuntoTalla, Atributos.OrdenTalla, sTalla]));
      // Almacen destino = el de la linea donde se tecleo. Se captura
      // ANTES del Cancel, que descartaria un cambio a medio editar.
      sAlmacen := FLineas.Entrada.AlmacenLineaActual(
        FPresentacion.AlmacenStock);
      Alta := DatosAlta(Resolucion, Atributos, sAlmacen);
      FLineas.Entrada.CancelarEdicionPendiente;
      // CONSOLIDACION: una linea por articulo+almacen+atributos no
      // talla Y PRECIO. La fila donde se tecleo (normalmente la vacia)
      // se descarta si ya existe linea para esa combinacion.
      if FLineas.Entrada.LocalizarLineaConsolidable(FConfig.Distribuido,
           Resolucion.CodigoArticulo, sAlmacen, Atributos.Valores,
           Alta.TienePrecio, Alta.Precio) then
        LogSesion(Format('ModoTallas.Resolver: consolidada en linea ' +
          '%d alm="%s" precio=%g',
          [FLineas.Entrada.NumeroLineaActual, sAlmacen, Alta.Precio]))
      else
      begin
        LogSesion(Format('ModoTallas.Resolver: linea nueva alm="%s" ' +
          'precio=%g', [sAlmacen, Alta.Precio]));
        FLineas.Entrada.AltaLineaResuelta(Alta);
        FPresentacion.MostrarColumnasAtributo(Atributos.Valores,
                                              Atributos.Nombres);
      end;
      FLineas.Entrada.ConfirmarEdicionPendiente;
      SumarTallaLeida(Resolucion, Atributos, sTalla);
      FPresentacion.ValidarSistemaSeleccionado;
      NotificarResuelto(Resolucion);
      Result := True;
    end
    else
      // Feedback como el desglose: sin aviso parecia que el Enter no
      // hacia nada cuando la entrada no existe (SKU no dado de alta).
      ShowMessage_fza(Format(SErrorArticuloSkuNoEncontrado, [sEntrada]));
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoConfiguracionInyeccionRaiz                              }
{    Tipo:       Composición raíz                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Compone las entradas compartidas de configuración, búsqueda y remesas.    }
{******************************************************************************}
unit inMtoConfiguracionInyeccionRaiz;

interface

uses
  System.Classes,
  Vcl.Forms,
  inLibCargaEfectosRemesaPersistenciaIntf,
  inLibDistribuidorPersistenciaIntf,
  UniDataComposicionAplicacion;

type
  TInyeccionConfiguracionRaiz = class
  private
    FOwnerRaiz: TComponent;
    FComposicion: TComposicionAplicacion;
  public
    constructor Create(
      AOwnerRaiz: TComponent;
      AComposicion: TComposicionAplicacion);
    procedure RegistrarFabricas;
    procedure RetirarFabricas;
    procedure MostrarParametrosAplicacion;
    procedure EjecutarBusquedaDatos(
      AOwner: TComponent;
      AFormularioPadre: TCustomForm);
    function CrearRepositorioCargaEfectos(
      const ANombrePantalla: string): IRepositorioCargaEfectosRemesa;
    function CrearRepositorioDistribuidor:
      IRepositorioDistribuidor;
  end;

implementation

uses
  System.SysUtils,
  inLibRegistroPantallas,
  inLibMensajesVcl,
  inLibMsgConfiguracion,
  inLibPermisosIntf,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosRemesasPantalla,
  inMtoAppParam,
  inMtoBusquedaDatos,
  inMtoEmpresas,
  inMtoRemesasCompra,
  inMtoRemesasVenta;

procedure NormalizarOwnerConfiguracion(
  AOwnerSolicitado: TComponent;
  AOwnerRaiz: TComponent;
  out AOwnerCreacion: TComponent;
  out AReparentarAplicacion: Boolean);
begin
  AReparentarAplicacion := AOwnerSolicitado = Application;
  AOwnerCreacion := AOwnerSolicitado;
  if not Assigned(AOwnerCreacion) or AReparentarAplicacion then
    AOwnerCreacion := AOwnerRaiz;
end;

procedure ReparentarConfiguracionSiProcede(
  AFormulario: TForm;
  AReparentarAplicacion: Boolean);
begin
  if AReparentarAplicacion then
  begin
    AFormulario.Owner.RemoveComponent(AFormulario);
    Application.InsertComponent(AFormulario);
  end;
end;

constructor TInyeccionConfiguracionRaiz.Create(
  AOwnerRaiz: TComponent;
  AComposicion: TComposicionAplicacion);
begin
  inherited Create;
  if not Assigned(AOwnerRaiz) then
    raise EArgumentNilException.Create('AOwnerRaiz');
  if not Assigned(AComposicion) then
    raise EArgumentNilException.Create('AComposicion');
  FOwnerRaiz := AOwnerRaiz;
  FComposicion := AComposicion;
end;

function TInyeccionConfiguracionRaiz.CrearRepositorioCargaEfectos(
  const ANombrePantalla: string): IRepositorioCargaEfectosRemesa;
var
  Repositorios: IRepositoriosRemesasPantalla;
begin
  Repositorios := FComposicion.CrearRepositoriosRemesasPantalla(
    ANombrePantalla);
  Result := Repositorios.CrearRepositorioCargaEfectosRemesa;
end;

function TInyeccionConfiguracionRaiz.CrearRepositorioDistribuidor:
  IRepositorioDistribuidor;
var
  Repositorios: IRepositoriosArticulosPantalla;
begin
  Repositorios := FComposicion.CrearRepositoriosArticulosPantalla(
    'ServiciosVisualesAplicacion');
  Result := Repositorios.CrearRepositorioDistribuidor;
end;

procedure TInyeccionConfiguracionRaiz.MostrarParametrosAplicacion;
var
  Formulario: TfrmMtoAppParam;
  Repositorios: IRepositoriosConfiguracionPantalla;
begin
  if not PuedeAbrirParametrosAplicacion(FComposicion.Permisos) then
    ShowMessage_fza(SErrorPermisoAbrirParametros)
  else
  begin
    Repositorios := FComposicion.CrearRepositoriosConfiguracionPantalla(
      'frmMtoAppParam');
    Formulario := TfrmMtoAppParam.Create(
      FOwnerRaiz,
      TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
      Repositorios.CrearRepositorioAppParam);
    try
      Formulario.ShowModal;
    finally
      Formulario.Free;
    end;
  end;
end;

procedure TInyeccionConfiguracionRaiz.EjecutarBusquedaDatos(
  AOwner: TComponent;
  AFormularioPadre: TCustomForm);
var
  Articulos: IRepositoriosArticulosPantalla;
  Configuracion: IRepositoriosConfiguracionPantalla;
  Dependencias: TDependenciasBusquedaDatos;
  Documentos: IRepositoriosDocumentosPantalla;
begin
  Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
    'frmMtoBusquedaDatos');
  Configuracion := FComposicion.CrearRepositoriosConfiguracionPantalla(
    'frmMtoBusquedaDatos');
  Documentos := FComposicion.CrearRepositoriosDocumentosPantalla(
    'frmMtoBusquedaDatos');
  Dependencias := Default(TDependenciasBusquedaDatos);
  Dependencias.Repositorio :=
    Configuracion.CrearRepositorioBusquedaDatos;
  Dependencias.Documentos :=
    Documentos.CrearRepositoriosDocumentosTrabajo;
  Dependencias.ResolverArticulos :=
    Articulos.CrearResolverArticulos;
  Dependencias.Validar;
  TfrmMtoBusquedaDatos.Ejecutar(
    AOwner,
    Dependencias,
    AFormularioPadre);
end;

procedure TInyeccionConfiguracionRaiz.RegistrarFabricas;
begin
  RegistrarFabricaPantalla(
    TfrmMtoEmpresas,
    function(AOwner: TComponent): TForm
    var
      Formulario: TfrmMtoEmpresas;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Repositorios: IRepositoriosConfiguracionPantalla;
    begin
      NormalizarOwnerConfiguracion(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Repositorios := FComposicion.CrearRepositoriosConfiguracionPantalla(
        'frmMtoEmpresas');
      Formulario := TfrmMtoEmpresas.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Repositorios.CrearRepositorioSeriesEmpresa);
      ReparentarConfiguracionSiProcede(
        Formulario,
        ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoRemesasCompra,
    function(AOwner: TComponent): TForm
    var
      Formulario: TfrmMtoRemesasCompra;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerConfiguracion(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Formulario := TfrmMtoRemesasCompra.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearRepositorioCargaEfectos('frmMtoRemesasCompra'));
      ReparentarConfiguracionSiProcede(
        Formulario,
        ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoRemesasVenta,
    function(AOwner: TComponent): TForm
    var
      Formulario: TfrmMtoRemesasVenta;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerConfiguracion(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Formulario := TfrmMtoRemesasVenta.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearRepositorioCargaEfectos('frmMtoRemesasVenta'));
      ReparentarConfiguracionSiProcede(
        Formulario,
        ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionConfiguracionRaiz.RetirarFabricas;
begin
  RetirarFabricaPantalla(TfrmMtoRemesasVenta);
  RetirarFabricaPantalla(TfrmMtoRemesasCompra);
  RetirarFabricaPantalla(TfrmMtoEmpresas);
end;

end.

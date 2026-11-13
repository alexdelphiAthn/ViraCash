{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoMantenimientosInyeccionRaiz                             }
{    Tipo:       Composición raíz                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Registra las fábricas de mantenimientos que requieren dependencias        }
{    explícitas y las compone exclusivamente en la raíz de la aplicación.      }
{******************************************************************************}
unit inMtoMantenimientosInyeccionRaiz;

interface

uses
  System.Classes,
  UniDataComposicionAplicacion;

type
  TInyeccionMantenimientosRaiz = class
  private
    FOwnerRaiz: TComponent;
    FComposicion: TComposicionAplicacion;
    procedure RegistrarFabricasStockYTarifas;
    procedure RegistrarFabricasCompras;
    procedure RegistrarFabricasCatalogos;
    procedure RegistrarFabricasFacturas;
  public
    constructor Create(
      AOwnerRaiz: TComponent;
      AComposicion: TComposicionAplicacion);
    procedure RegistrarFabricas;
    procedure RetirarFabricas;
  end;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  inLibRegistroPantallas,
  inMtoFrmBase,
  inMtoStockConsulta,
  inLibSimulacionPrecioCaja,
  inMtoTarifas,
  inMtoTarifasCambios,
  inMtoStockConsultaPresentacionComposicion,
  inMtoAlbaranesCompra,
  inMtoFacturasCompra, inMtoComprasDirectasTerceros,
  inMtoPedidosCompra,
  inMtoDevolucionesCompra,
  inMtoDocumentosTrabajo,
  inMtoArticulos,
  inMtoInventarios,
  inMtoComprasSesiones,
  inMtoFacturasNormal,
  inMtoFacturasSimplif,
  inLibPermisosIntf,
  inLibRepositoriosPantallaIntf,
  inLibArticulosInyeccion,
  inLibInventariosInyeccion,
  inLibFacturasInyeccion,
  inLibComprasSesionesInyeccion,
  UniDataArticulosPropiedadesRepositorio,
  UniDataArticulosVariaciones,
  UniDataComprasPantallaComposicion,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosCajaPantalla,
  UniDataTarifasPeriodicidadRepositorio,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosOperacionesPantalla,
  UniDataInventariosInyeccion,
  UniDataFacturasInyeccion;

type
  TfrmStockConsultaInyectadaRaiz = class(TfrmStockConsulta)
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasStockConsulta);
  end;

constructor TfrmStockConsultaInyectadaRaiz.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasStockConsulta);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure NormalizarOwnerPantalla(
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

procedure ReparentarAplicacionSiProcede(
  AFormulario: TForm;
  AReparentarAplicacion: Boolean);
begin
  if AReparentarAplicacion then
  begin
    AFormulario.Owner.RemoveComponent(AFormulario);
    Application.InsertComponent(AFormulario);
  end;
end;

constructor TInyeccionMantenimientosRaiz.Create(
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

procedure TInyeccionMantenimientosRaiz.RegistrarFabricasStockYTarifas;
begin
  RegistrarFabricaPantalla(
    TfrmStockConsulta,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TContextoDependenciasStockConsulta;
      Documentos: IRepositoriosDocumentosPantalla;
      Operaciones: IRepositoriosOperacionesPantalla;
      Formulario: TfrmStockConsultaInyectadaRaiz;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        NOMBRE_PANTALLA_STOCK_CONSULTA);
      Documentos := FComposicion.CrearRepositoriosDocumentosPantalla(
        NOMBRE_PANTALLA_STOCK_CONSULTA);
      Operaciones := FComposicion.CrearRepositoriosOperacionesPantalla(
        NOMBRE_PANTALLA_STOCK_CONSULTA);
      Dependencias := CrearContextoStockConsulta(
        Articulos,
        Documentos,
        Operaciones,
        FComposicion.DmConn.conUni);
      Formulario := TfrmStockConsultaInyectadaRaiz.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoTarifas,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Formulario: TfrmMtoTarifas;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoTarifas');
      Formulario := TfrmMtoTarifas.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Articulos.CrearServicioCargaMasivaArticulos);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoTarifasCambios,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Formulario: TfrmMtoTarifasCambios;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Simulacion: TServiciosSimulacionPrecioCaja;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoTarifasCambios');
      Simulacion := Default(TServiciosSimulacionPrecioCaja);
      Simulacion.Resolver := Articulos.CrearResolverArticulos;
      Simulacion.Validador := Articulos.CrearValidadorArticulos;
      // FZ-ISSUE-942: la periodicidad y las tarifas de caja tambien salen
      // de la raiz; la pantalla no crea repositorios.
      Simulacion.Periodicidad := CrearRepositorioPeriodicidadTarifa(
        FComposicion.DmConn.conUni);
      Simulacion.Consultas := FComposicion.CrearRepositoriosCajaPantalla(
        'frmMtoTarifasCambios').CrearRepositorioConsultasCaja;
      Formulario := TfrmMtoTarifasCambios.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Articulos.CrearServicioCargaMasivaArticulos,
        Simulacion);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionMantenimientosRaiz.RegistrarFabricasCompras;
begin
  RegistrarFabricaPantalla(
    TfrmMtoAlbaranesCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearAlbaranesCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorAlbaranCompraPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_ALBARANES_COMPRA)));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoFacturasCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearFacturasCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorFacturaCompraPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_FACTURAS_COMPRA),
          FComposicion.CrearRepositoriosConfiguracionPantalla(
            NOMBRE_PANTALLA_FACTURAS_COMPRA).
            CrearRepositorioSeleccionBancoEmpresa));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoComprasDirectasTerceros,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearComprasDirectasTercerosInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorFacturaCompraPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_FACTURAS_COMPRA),
          FComposicion.CrearRepositoriosConfiguracionPantalla(
            NOMBRE_PANTALLA_FACTURAS_COMPRA).
            CrearRepositorioSeleccionBancoEmpresa));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoPedidosCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearPedidosCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorPedidoCompraPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_PEDIDOS_COMPRA)));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoDevolucionesCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearDevolucionesCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorDevolucionCompraPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_DEVOLUCIONES_COMPRA)));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoDocumentosTrabajo,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearDocumentosTrabajoCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearCompositorDocumentosTrabajoPantalla(
          FComposicion.CrearRepositoriosArticulosPantalla(
            NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO)),
        FComposicion.CrearRepositoriosCajaPantalla(
          NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO).
          CrearRepositorioCajasDefecto);
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);
end;

procedure TInyeccionMantenimientosRaiz.RegistrarFabricasCatalogos;
begin
  RegistrarFabricaPantalla(
    TfrmMtoArticulos,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TContextoDependenciasArticulos;
      Formulario: TfrmMtoArticulos;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoArticulos');
      Dependencias := TContextoDependenciasArticulos.Crear(
        CrearCreadorGuardadoArticulo,
        CrearServiciosPropiedadesArticuloUniDAC(
          FComposicion.DmConn.conUni),
        CrearArticulosVariacionesUniDAC(FComposicion.DmConn.conUni),
        Articulos.CrearRepositorioMargen,
        Articulos.CrearRepositorioGeneracionSkus);
      Formulario := TfrmMtoArticulos.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoInventarios,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TDependenciasInventarios;
      Formulario: TfrmMtoInventarios;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoInventarios');
      Dependencias := CrearDependenciasInventariosUniDAC(
        Articulos,
        FComposicion.DmConn.conUni);
      Formulario := TfrmMtoInventarios.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoComprasSesiones,
    function(AOwner: TComponent): TForm
    var
      Dependencias: TContextoDependenciasComprasSesiones;
      Formulario: TfrmMtoComprasSesiones;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        NOMBRE_PANTALLA_COMPRAS_SESIONES);
      Dependencias := TContextoDependenciasComprasSesiones.Crear(
        Sql.Catalogo,
        Sql.Incidencias,
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_COMPRAS_SESIONES).
          CrearRepositorioDistribuidor);
      Formulario := TfrmMtoComprasSesiones.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionMantenimientosRaiz.RegistrarFabricasFacturas;
begin
  RegistrarFabricaPantalla(
    TfrmMtoFacturasNormal,
    function(AOwner: TComponent): TForm
    var
      ContextoUniDAC: TContextoFacturasUniDAC;
      Dependencias: TDependenciasFacturas;
      Formulario: TfrmMtoFacturasNormal;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        'frmMtoFacturasNormal');
      ContextoUniDAC := Default(TContextoFacturasUniDAC);
      ContextoUniDAC.Conexion := FComposicion.DmConn.conUni;
      ContextoUniDAC.ParametrosApp := FComposicion.ParametrosApp;
      ContextoUniDAC.ParametrosCaja := FComposicion.ParametrosCaja;
      ContextoUniDAC.CatalogoSql := Sql.Catalogo;
      ContextoUniDAC.IncidenciasSql := Sql.Incidencias;
      ContextoUniDAC.RegistroLog := FComposicion.RegistroLog;
      ContextoUniDAC.SeleccionBanco :=
        FComposicion.CrearRepositoriosConfiguracionPantalla(
          'frmMtoFacturasNormal').
          CrearRepositorioSeleccionBancoEmpresa;
      ContextoUniDAC.Usuario := FComposicion.ContextoSesion.Identidad.Usuario;
      Dependencias := CrearDependenciasFacturasUniDAC(ContextoUniDAC);
      Formulario := TfrmMtoFacturasNormal.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoFacturasSimplif,
    function(AOwner: TComponent): TForm
    var
      ContextoUniDAC: TContextoFacturasUniDAC;
      Dependencias: TDependenciasFacturas;
      Formulario: TfrmMtoFacturasSimplif;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        'frmMtoFacturasSimplif');
      ContextoUniDAC := Default(TContextoFacturasUniDAC);
      ContextoUniDAC.Conexion := FComposicion.DmConn.conUni;
      ContextoUniDAC.ParametrosApp := FComposicion.ParametrosApp;
      ContextoUniDAC.ParametrosCaja := FComposicion.ParametrosCaja;
      ContextoUniDAC.CatalogoSql := Sql.Catalogo;
      ContextoUniDAC.IncidenciasSql := Sql.Incidencias;
      ContextoUniDAC.RegistroLog := FComposicion.RegistroLog;
      ContextoUniDAC.SeleccionBanco :=
        FComposicion.CrearRepositoriosConfiguracionPantalla(
          'frmMtoFacturasSimplif').
          CrearRepositorioSeleccionBancoEmpresa;
      ContextoUniDAC.Usuario := FComposicion.ContextoSesion.Identidad.Usuario;
      Dependencias := CrearDependenciasFacturasUniDAC(ContextoUniDAC);
      Formulario := TfrmMtoFacturasSimplif.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionMantenimientosRaiz.RegistrarFabricas;
begin
  RegistrarFabricasStockYTarifas;
  RegistrarFabricasCompras;
  RegistrarFabricasCatalogos;
  RegistrarFabricasFacturas;
end;

procedure TInyeccionMantenimientosRaiz.RetirarFabricas;
begin
  RetirarFabricaPantalla(TfrmMtoFacturasSimplif);
  RetirarFabricaPantalla(TfrmMtoFacturasNormal);
  RetirarFabricaPantalla(TfrmMtoComprasSesiones);
  RetirarFabricaPantalla(TfrmMtoInventarios);
  RetirarFabricaPantalla(TfrmMtoArticulos);
  RetirarFabricaPantalla(TfrmMtoDocumentosTrabajo);
  RetirarFabricaPantalla(TfrmMtoDevolucionesCompra);
  RetirarFabricaPantalla(TfrmMtoPedidosCompra);
  RetirarFabricaPantalla(TfrmMtoFacturasCompra);
  RetirarFabricaPantalla(TfrmMtoComprasDirectasTerceros);
  RetirarFabricaPantalla(TfrmMtoAlbaranesCompra);
  RetirarFabricaPantalla(TfrmMtoTarifasCambios);
  RetirarFabricaPantalla(TfrmMtoTarifas);
  RetirarFabricaPantalla(TfrmStockConsulta);
end;

end.

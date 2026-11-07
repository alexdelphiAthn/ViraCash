{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPrincipalAccionesVcl                                    }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Apertura y ciclo de vida de acciones modales del menu principal.         }
{******************************************************************************}
unit inMtoPrincipalAccionesVcl;

interface

uses
  System.Classes, Vcl.Forms, cxPC, Uni,
  inLibAnfitrionMtoIntf, inLibLogIntf,
  inLibCargaEfectosRemesaPersistenciaIntf;

type
  TAccionPrincipalVcl = reference to procedure;

procedure MostrarListadoVentas(AOwner: TComponent);
procedure MostrarListadoDocumentosProveedor(AOwner: TComponent);
procedure MostrarListadoEfectosPago(AOwner: TComponent);
procedure MostrarListadoLibrosIva(AOwner: TComponent);
function FacturarAlbaranesCompra(out ASerie, ANumero: string): Boolean;
procedure MostrarProcesosAuxiliares(
  AOwner: TComponent;
  const AAnfitrionMantenimiento: IAnfitrionMantenimiento);
procedure MostrarCambioArticuloColor(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AUsuario: string);
procedure MostrarDeclaracionVerifactu(AOwner: TComponent);
procedure MostrarAyudaWeb(AOwner: TComponent;
  const ATitulo, AUrl: string);
procedure MostrarBalanceAlmacenHorizontal;
procedure MostrarBalanceAlmacenSinTallas;
procedure MostrarMovimientosVentasArticulos;
procedure MostrarComparativaVentas;
procedure MostrarAcercaDe(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
procedure MostrarConsultaStockPrincipal(
  AFormularioPrincipal: TForm;
  APaginas: TcxPageControl);
procedure DesvincularConsultaStockPrincipal;
function EsPantallaBusquedaDatos(AFormulario: TForm): Boolean;
procedure ActualizarFotoMantenimientoPrincipal(AMantenimiento: TObject);
procedure ActualizarFotoPaginaActivaPrincipal(APaginas: TcxPageControl);
procedure CargarEfectosRemesaPrincipal(
  AOwner: TComponent;
  const ARepositorio: IRepositorioCargaEfectosRemesa;
  AEsVenta: Boolean;
  const AAlCompletar: TAccionPrincipalVcl);

implementation

uses
  System.SysUtils,
  Vcl.Controls,
  inMtoModalListadoVentas,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalImpLibrosIva,
  inMtoModalFacturarAlbaranes,
  inMtoModalProcesosAuxiliaresBBDD,
  inMtoModalCambioArticuloColor,
  inLibCambioArticuloColor,
  UniDataCambioArticuloColorRepositorio,
  UniDataCambioArticuloColorHistoricoConsulta,
  inMtoModalVerifactuDecl,
  inMtoModalAyudaWeb,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt,
  inMtoModalImpComparativaVentas,
  inMtoSplash,
  inMtoFrmBase, inMtoStockConsulta,
  inMtoBusquedaDatos,
  inMtoFotoArticulo,
  inMtoGen,
  inMtoModalCargarEfectosRemesa;

procedure MostrarListadoVentas(AOwner: TComponent);
var
  Formulario: TfrmModalListadoVentas;
begin
  Formulario := TfrmModalListadoVentas.Create(AOwner);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarListadoDocumentosProveedor(AOwner: TComponent);
var
  Formulario: TfrmPrintDocsProveedor;
begin
  Formulario := TfrmPrintDocsProveedor.Create(AOwner);
  try
    Formulario.NombreIconoMenu := 'mnuListadoDocsProveedor';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarListadoEfectosPago(AOwner: TComponent);
var
  Formulario: TfrmPrintEfectosPago;
begin
  Formulario := TfrmPrintEfectosPago.Create(AOwner);
  try
    Formulario.NombreIconoMenu := 'mnuListadoEfectosPago';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarListadoLibrosIva(AOwner: TComponent);
var
  Formulario: TfrmPrintLibrosIva;
begin
  Formulario := TfrmPrintLibrosIva.Create(AOwner);
  try
    Formulario.NombreIconoMenu := 'mnuListadoLibrosIva';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

function FacturarAlbaranesCompra(out ASerie, ANumero: string): Boolean;
var
  Formulario: TfrmModalFacturarAlbaranes;
begin
  ASerie := '';
  ANumero := '';
  Formulario := TfrmModalFacturarAlbaranes.Create(nil);
  try
    Result := Formulario.ShowModal = mrOk;
    if Result then
    begin
      ASerie := Formulario.FacturaSerie;
      ANumero := Formulario.FacturaNumero;
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarProcesosAuxiliares(
  AOwner: TComponent;
  const AAnfitrionMantenimiento: IAnfitrionMantenimiento);
begin
  TfrmModalProcesosAuxiliaresBBDD.Ejecutar(
    AOwner,
    AAnfitrionMantenimiento);
end;

procedure MostrarCambioArticuloColor(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  TfrmModalCambioArticuloColor.Ejecutar(
    AOwner,
    CrearServicioCambioArticuloColor(
      CrearRepositorioCambioArticuloColorUniDAC(AConexion)),
    CrearConsultaCambioArticuloColorHistoricoUniDAC(AConexion),
    AUsuario);
end;

procedure MostrarDeclaracionVerifactu(AOwner: TComponent);
begin
  TfrmModalVerifactuDecl.Ejecutar(AOwner);
end;

procedure MostrarAyudaWeb(AOwner: TComponent;
  const ATitulo, AUrl: string);
begin
  TfrmModalAyudaWeb.Ejecutar(AOwner, ATitulo, AUrl);
end;

procedure MostrarBalanceAlmacenHorizontal;
var
  Formulario: TfrmPrintBalanceTallas;
begin
  Formulario := TfrmPrintBalanceTallas.Create(Application);
  try
    Formulario.NombreIconoMenu := 'mnuBalanceAlmacenHorizontal';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarBalanceAlmacenSinTallas;
var
  Formulario: TfrmPrintBalanceSinTallas;
begin
  Formulario := TfrmPrintBalanceSinTallas.Create(Application);
  try
    Formulario.NombreIconoMenu := 'mnuBalanceAlmacenSinTallas';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarComparativaVentas;
var
  Formulario: TfrmPrintComparativaVentas;
begin
  Formulario := TfrmPrintComparativaVentas.Create(Application);
  try
    Formulario.NombreIconoMenu := 'mnuComparativaVentas';
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure MostrarMovimientosVentasArticulos;
var
  Formulario: TfrmPrintMovVentasArt;
begin
  Formulario := TfrmPrintMovVentasArt.Create(Application);
  try
    Formulario.NombreIconoMenu := 'mnuMovVentasArt';
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarAcercaDe(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
var
  Formulario: TfrmSplash;
begin
  Formulario := TfrmSplash.Create(AOwner, ARegistroLog);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarConsultaStockPrincipal(
  AFormularioPrincipal: TForm;
  APaginas: TcxPageControl);
var
  FormularioActivo: TForm;
  Pestana: TcxTabSheet;
  Articulo: string;
  Sku: string;
begin
  FormularioActivo := Screen.ActiveForm;
  if (FormularioActivo = AFormularioPrincipal) and
     Assigned(APaginas) and
     (APaginas.PageCount > 0) and
     (APaginas.ActivePageIndex >= 0) then
  begin
    Pestana := APaginas.Pages[APaginas.ActivePageIndex] as TcxTabSheet;
    if (Pestana.ControlCount > 0) and
       (Pestana.Controls[0] is TForm) then
      FormularioActivo := TForm(Pestana.Controls[0]);
  end;
  Articulo := '';
  Sku := '';
  if FormularioActivo is TfrmBase then
    TfrmBase(FormularioActivo).ResolverArtSkuStock(Articulo, Sku);
  MostrarStockConsulta(Articulo, Sku);
end;

procedure DesvincularConsultaStockPrincipal;
begin
  DesvincularPerfilesStockConsulta;
end;

function EsPantallaBusquedaDatos(AFormulario: TForm): Boolean;
begin
  Result := AFormulario is TfrmMtoBusquedaDatos;
end;

procedure ActualizarFotoMantenimientoPrincipal(AMantenimiento: TObject);
var
  Articulo: string;
  FormularioFoto: TfrmFotoArticulo;
  Mantenimiento: TfrmMtoGen;
  Sku: string;
begin
  FormularioFoto := FotoFlotanteActual;
  if (FormularioFoto <> nil) and FormularioFoto.Visible and
     (AMantenimiento is TfrmMtoGen) then
  begin
    Mantenimiento := TfrmMtoGen(AMantenimiento);
    Mantenimiento.ResolverArtSkuActivo(Articulo, Sku);
    FormularioFoto.VincularDataSources(
      Mantenimiento.DataSourcesParaFoto,
      Mantenimiento.ResolverArtSkuActivo);
    FormularioFoto.SetArticuloSku(Articulo, Sku);
  end;
end;

procedure ActualizarFotoPaginaActivaPrincipal(APaginas: TcxPageControl);
var
  FormularioFoto: TfrmFotoArticulo;
  Pestana: TcxTabSheet;
begin
  FormularioFoto := FotoFlotanteActual;
  if APaginas.ActivePageIndex < 0 then
  begin
    if (FormularioFoto <> nil) and FormularioFoto.Visible then
    begin
      FormularioFoto.VincularDataSources([], nil);
      FormularioFoto.SetArticuloSku('', '');
    end;
  end
  else
  begin
    Pestana := APaginas.Pages[APaginas.ActivePageIndex] as TcxTabSheet;
    if (Pestana.ControlCount = 0) or
       not (Pestana.Controls[0] is TfrmMtoGen) then
    begin
      if (FormularioFoto <> nil) and FormularioFoto.Visible then
        FormularioFoto.VincularDataSources([], nil);
    end
    else
      ActualizarFotoMantenimientoPrincipal(Pestana.Controls[0]);
  end;
end;

procedure CargarEfectosRemesaPrincipal(
  AOwner: TComponent;
  const ARepositorio: IRepositorioCargaEfectosRemesa;
  AEsVenta: Boolean;
  const AAlCompletar: TAccionPrincipalVcl);
var
  Formulario: TfrmModalCargarEfectosRemesa;
begin
  if AEsVenta then
    Formulario := TfrmModalCargarEfectosRemesa.CrearParaVenta(
      AOwner,
      ARepositorio)
  else
    Formulario := TfrmModalCargarEfectosRemesa.CrearParaCompra(
      AOwner,
      ARepositorio);
  try
    if (Formulario.ShowModal = mrOk) and Assigned(AAlCompletar) then
      AAlCompletar();
  finally
    Formulario.Free;
  end;
end;

end.

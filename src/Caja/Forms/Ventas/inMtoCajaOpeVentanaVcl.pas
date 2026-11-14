{******************************************************************************}
{                                                                              }
{  Presentacion de la ventana de operacion de caja.                            }
{                                                                              }
{******************************************************************************}
unit inMtoCajaOpeVentanaVcl;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Vcl.Graphics, Vcl.Forms,
  Vcl.ExtCtrls, cxLabel,
  cxButtonEdit,
  cxGrid, cxGridDBTableView, inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf, inLibLayoutForm, inLibPermisosIntf;

type
  TConsultaFechaCajaVcl = reference to function: TDateTime;
  TAccionFechaCajaVcl = reference to procedure(AFecha: TDateTime);
  TFormatoFechaCajaVcl = reference to function(
    AFecha: TDateTime): string;
  TConsultaTextoVentanaCajaVcl = reference to function: string;
  TContextoVentanaOperacionCajaVcl = record
    Formulario: TForm;
    EtiquetasBotonera: TArray<TcxLabel>;
    EtiquetaFecha: TcxLabel;
    BotonEmpleado: TcxButtonEdit;
    RejillaLineas: TcxGrid;
    PanelBusqueda: TPanel;
    PanelFoto: TPanel;
    VistaLineas: TcxGridDBTableView;
    ContextoSesion: IContextoSesionAplicacion;
    PerfilesLectura: ILectorPerfilesUsuario;
    PerfilesEscritura: IEscritorPerfilesUsuario;
    SolicitudPermisoLayout: ISolicitudPermisoLayout;
    Permisos: IPermisosAplicacion;
    ObtenerEmpresa: TConsultaTextoVentanaCajaVcl;
    ObtenerAlmacen: TConsultaTextoVentanaCajaVcl;
    ObtenerCaja: TConsultaTextoVentanaCajaVcl;
    ObtenerFecha: TConsultaFechaCajaVcl;
    EstablecerFecha: TAccionFechaCajaVcl;
    FormatearFecha: TFormatoFechaCajaVcl;
    EscribirFechaCabecera: TAccionFechaCajaVcl;
    NotificarFecha: TAccionFechaCajaVcl;
  end;
  TVentanaOperacionCajaVcl = class
  private
    FContexto: TContextoVentanaOperacionCajaVcl;
    FUltimoTickReloj: TDateTime;
    procedure AjustarFuenteEtiqueta(AEtiqueta: TcxLabel);
  public
    constructor Create(
      const AContexto: TContextoVentanaOperacionCajaVcl);
    procedure AjustarFuentesBotonera;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure ResetearLayout;
    procedure ActualizarFoco;
    procedure ReiniciarReloj;
    procedure ActualizarReloj;
    procedure CambiarHora(Sender: TObject);
    procedure AbrirBuscarModificar;
  end;

procedure ResolverArtSkuStockCaja(
  ALineas: TDataSet;
  out ACodigoArticulo, ACodigoSku: string);
procedure MostrarConsultaStockCaja(ALineas: TDataSet);
function SolicitarCambioIvaCaja(
  AOwner: TComponent;
  const ATipoActual: string;
  out ATipoNuevo: string): Boolean;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows, System.Math, Vcl.Dialogs, inLibMsgCaja,
  inLibCajaVentanasIntf, inLibFotos, inMtoStockConsulta,
  inMtoModalCambioIva;

resourcestring
  SDescripcionPersonalizacionCaja =
    'Personalización Caja';

function SolicitarCambioIvaCaja(
  AOwner: TComponent;
  const ATipoActual: string;
  out ATipoNuevo: string): Boolean;
begin
  Result := TfrmModalCambioIva.Ejecutar(
    AOwner,
    ATipoActual,
    ATipoNuevo);
end;

procedure ResolverArtSkuStockCaja(
  ALineas: TDataSet;
  out ACodigoArticulo, ACodigoSku: string);
begin
  ACodigoArticulo := '';
  ACodigoSku := '';
  if Assigned(ALineas) then
    LeerArtSkuDeDataSet(ALineas, ACodigoArticulo, ACodigoSku);
end;

procedure MostrarConsultaStockCaja(ALineas: TDataSet);
var
  CodigoArticulo: string;
  CodigoSku: string;
begin
  ResolverArtSkuStockCaja(ALineas, CodigoArticulo, CodigoSku);
  MostrarStockConsulta(CodigoArticulo, CodigoSku);
end;

constructor TVentanaOperacionCajaVcl.Create(
  const AContexto: TContextoVentanaOperacionCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

procedure TVentanaOperacionCajaVcl.AjustarFuenteEtiqueta(
  AEtiqueta: TcxLabel);
const
  cMargenHorizontal = 8;
  cPorcentajeFuenteMinima = 65;
var
  AlturaMinima: Integer;
  MargenHorizontal: Integer;
begin
  AEtiqueta.Style.Font.Assign(FContexto.Formulario.Font);
  FContexto.Formulario.Canvas.Font.Assign(AEtiqueta.Style.Font);
  AlturaMinima := -Max(
    12,
    MulDiv(
      Abs(FContexto.Formulario.Font.Height),
      cPorcentajeFuenteMinima,
      100));
  MargenHorizontal := MulDiv(
    cMargenHorizontal,
    FContexto.Formulario.CurrentPPI,
    96);
  while (FContexto.Formulario.Canvas.TextWidth(AEtiqueta.Caption) >
         AEtiqueta.Width - MargenHorizontal) and
        (FContexto.Formulario.Canvas.Font.Height < AlturaMinima) do
    FContexto.Formulario.Canvas.Font.Height :=
      FContexto.Formulario.Canvas.Font.Height + 1;
  AEtiqueta.Style.Font.Assign(FContexto.Formulario.Canvas.Font);
end;

procedure TVentanaOperacionCajaVcl.AjustarFuentesBotonera;
var
  Etiqueta: TcxLabel;
begin
  for Etiqueta in FContexto.EtiquetasBotonera do
    AjustarFuenteEtiqueta(Etiqueta);
end;

procedure TVentanaOperacionCajaVcl.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    FContexto.Formulario.Name,
    FContexto.PerfilesEscritura,
    FContexto.SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(FContexto.Formulario);
    Layout.GuardarAlturaPanel(
      'StockPanelHeight',
      FContexto.PanelBusqueda);
    Layout.GuardarAnchoPanel(
      'FotoStockWidth',
      FContexto.PanelFoto);
    Layout.GuardarGrid('Lineas', FContexto.VistaLineas);
    if Layout.PreguntarYGrabar(SDescripcionPersonalizacionCaja) then
      ShowMessage_fza(SInfoLayoutCajaGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TVentanaOperacionCajaVcl.RestaurarLayout;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(
    FContexto.Formulario.Name,
    FContexto.ContextoSesion,
    FContexto.PerfilesLectura);
  try
    if Layout.Disponible then
    begin
      Layout.RestaurarGeometria(FContexto.Formulario);
      Layout.RestaurarAlturaPanel(
        'StockPanelHeight',
        FContexto.PanelBusqueda,
        30);
      Layout.RestaurarAnchoPanel(
        'FotoStockWidth',
        FContexto.PanelFoto,
        50);
      Layout.RestaurarGrid('Lineas', FContexto.VistaLineas);
    end;
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TVentanaOperacionCajaVcl.ResetearLayout;
begin
  inLibLayoutForm.ResetearLayout(
    FContexto.Formulario.Name,
    FContexto.PerfilesEscritura,
    FContexto.SolicitudPermisoLayout);
end;

procedure TVentanaOperacionCajaVcl.ActualizarFoco;
begin
  if FContexto.BotonEmpleado.Text = '' then
  begin
    if FContexto.BotonEmpleado.CanFocus then
      FContexto.BotonEmpleado.SetFocus;
  end
  else if FContexto.RejillaLineas.CanFocus then
    FContexto.RejillaLineas.SetFocus;
end;

procedure TVentanaOperacionCajaVcl.ReiniciarReloj;
begin
  FUltimoTickReloj := Now;
end;

procedure TVentanaOperacionCajaVcl.ActualizarReloj;
var
  Ahora: TDateTime;
  Fecha: TDateTime;
begin
  Ahora := Now;
  if FUltimoTickReloj = 0 then
    FUltimoTickReloj := Ahora;
  Fecha := FContexto.ObtenerFecha();
  if Fecha = 0 then
    Fecha := Ahora;
  Fecha := Fecha + (Ahora - FUltimoTickReloj);
  FUltimoTickReloj := Ahora;
  FContexto.EstablecerFecha(Fecha);
  FContexto.EtiquetaFecha.Caption :=
    FContexto.FormatearFecha(Fecha);
end;

procedure TVentanaOperacionCajaVcl.CambiarHora(Sender: TObject);
var
  HoraTexto: string;
  Hora: TDateTime;
  Fecha: TDateTime;
begin
  Fecha := FContexto.ObtenerFecha();
  if Fecha = 0 then
    Fecha := Now;
  HoraTexto := FormatDateTime('hh:nn', Fecha);
  if InputQuery_fza(STituloHoraCaja, SSolicitudHoraCaja, HoraTexto) then
  begin
    if TryStrToTime(HoraTexto, Hora) then
      Fecha := Trunc(Fecha) + Frac(Hora)
    else
    begin
      ShowMessage_fza(SErrorHoraCajaNoValida);
      HoraTexto := '';
    end;
  end
  else
    Fecha := Now;
  if HoraTexto <> '' then
  begin
    FContexto.EstablecerFecha(Fecha);
    ReiniciarReloj;
    ActualizarReloj;
    FContexto.EscribirFechaCabecera(FContexto.ObtenerFecha());
    FContexto.NotificarFecha(FContexto.ObtenerFecha());
  end;
end;

procedure TVentanaOperacionCajaVcl.AbrirBuscarModificar;
var
  Anfitrion: IAnfitrionCajaVentanas;
  Consulta: IConsultaOperacionesCaja;
  FormularioConsulta: TCustomForm;
begin
  if (FContexto.ObtenerEmpresa() = '') or
     (FContexto.ObtenerAlmacen() = '') or
     (FContexto.ObtenerCaja() = '') then
    ShowMessage_fza(SErrorUbicacionCajaBuscarOperacionesNoAsignada)
  else
  begin
    Anfitrion := ExigirAnfitrionCaja(Application.MainForm);
    Consulta := Anfitrion.CrearConsultaOperacionesCaja(
      Application,
      FContexto.Permisos);
    FormularioConsulta := Consulta.FormularioConsultaCaja;
    try
      FormularioConsulta.PopupParent := FContexto.Formulario;
      Consulta.PrepararValores(
        FContexto.ObtenerEmpresa(),
        FContexto.ObtenerAlmacen(),
        FContexto.ObtenerCaja(),
        FContexto.ObtenerFecha());
      FormularioConsulta.Show;
    except
      FreeAndNil(FormularioConsulta);
      raise;
    end;
  end;
end;

end.

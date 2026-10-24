{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasPresentadorCabeceraVcl                           }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presenta la cabecera de la factura: bloqueo, avisos y datos de apoyo.     }
{******************************************************************************}
unit inMtoFacturasPresentadorCabeceraVcl;

interface

uses
  System.Classes, Data.DB,
  cxButtons, cxCalendar, cxCheckBox, cxDBEdit, cxDBLookupComboBox,
  cxGridDBTableView, cxImage, cxMemo, cxPC, cxSpinEdit, cxTextEdit,
  UniDataFacturas,
  inLibFacturasAplicacionIntf,
  inLibFacturasLecturasIntf,
  inLibFacturasServiciosIntf,
  inLibParametrosIntf;

type
  TControlesRegistroFacturaVcl = record
    IdConsolidacion: TcxDBSpinEdit;
    Estado: TcxDBTextEdit;
    RespuestaCompleta: TcxDBMemo;
    ImagenQr: TcxDBImage;
    IdCola: TcxDBSpinEdit;
    FechaProcesamiento: TcxDBDateEdit;
    EmisorIrs: TcxDBTextEdit;
    InstanteEmision: TcxDBDateEdit;
    NumeroCadena: TcxDBTextEdit;
    HashCadena: TcxDBTextEdit;
    UrlVerifactu: TcxDBMemo;
    QrBase64: TcxDBMemo;
    PeticionCompleta: TcxDBMemo;
    IdPeticion: TcxDBTextEdit;
    VistaLog: TcxGridDBTableView;
  end;
  TContextoCabeceraFacturaVcl = record
    Cabecera: TDataSource;
    DataModule: TdmFacturas;
    ParametrosApp: IParametrosAplicacion;
    Estado: IPresentadorEstadoFactura;
    Lecturas: IRepositorioLecturasFactura;
    Numero: TcxDBTextEdit;
    Serie: TcxDBLookupComboBox;
    Tarifa: TcxDBLookupComboBox;
    CanalIva: TcxDBLookupComboBox;
    TipoOperacion: TcxDBLookupComboBox;
    BotonNuevaFactura: TcxButton;
    BotonRectificar: TcxButton;
    BotonConsolidar: TcxButton;
    BotonImprimir: TcxButton;
    PaginasCabecera: TcxPageControl;
    PestanaCabecera: TcxTabSheet;
    PestanaCliente: TcxTabSheet;
    PestanaEmpresa: TcxTabSheet;
    PaginasDetalle: TcxPageControl;
    PestanaLineas: TcxTabSheet;
    RazonSocialCliente: TcxDBTextEdit;
    RazonSocialEmpresa: TcxDBTextEdit;
    NifCliente: TcxDBTextEdit;
    NifEmpresa: TcxDBTextEdit;
    PaisCliente: TcxDBLookupComboBox;
  end;
  TPresentadorCabeceraFacturaVcl = class
  private
    FContexto: TContextoCabeceraFacturaVcl;
    function CabeceraViva: Boolean;
    function ObtenerSolicitudEstado(
      out ASolicitud: TSolicitudEstadoFactura): Boolean;
  public
    constructor Create(const AContexto: TContextoCabeceraFacturaVcl);
    procedure ActualizarBloqueoEdicion;
    procedure AplicarEstadoDatos;
    procedure RefrescarAlmacenes(AField: TField);
    procedure ActualizarComboSeries;
    procedure SeriesCambiadas(Sender: TObject);
    procedure CambiarIVA;
    procedure CopiarEmpresa(const ACodigoEmpresa: string);
    procedure AplicarTarifa(const ACodigoTarifa: string);
    procedure CambiarEstadoRecibo(const AEstado: string);
    // Avisos que el data module delega en la pantalla.
    procedure SenalarCampo(ACampo: TCampoValidacionFac);
    procedure MostrarResultadoOperacion(
      const AResultado: TResultadoOperacionFactura);
    procedure MostrarResultadoBorrado(
      const AResultado: TResultadoBorradoFactura);
    procedure MostrarAdvertencia(const AMensaje: string);
    procedure MostrarErrorValidacion(const AError: EValidacionFactura);
    function ConfirmarBorrado(const ASerie, ANumero: string): Boolean;
  end;

procedure RefrescarSelectorSerieFactura(
  ASelector: TcxDBLookupComboBox; AOrigen: TDataSource;
  ACampoSerie: TField; const ASerieAnterior: string);

procedure AsignarOrigenesRegistroFacturaVcl(
  const AControles: TControlesRegistroFacturaVcl;
  AConsolidacion, AErrores: TDataSource);

implementation

uses
  inLibMensajesVcl,
  System.SysUtils, System.UITypes, System.Variants, Vcl.Dialogs,
  inLibFacturas,
  inLibFacturasPresentadorCabecera,
  inLibMsgArticulos,
  inLibMsgFacturas,
  inLibVerifactu;

// La lista se recarga por fecha/empresa y al recuperar un borrador. No
// sustituir una selección válida por la primera serie del listado.
procedure RefrescarSelectorSerieFactura(
  ASelector: TcxDBLookupComboBox; AOrigen: TDataSource;
  ACampoSerie: TField; const ASerieAnterior: string);
var
  Serie: string;
begin
  Serie := ASerieAnterior;
  if not AOrigen.DataSet.Locate('SERIE_CON', Serie, []) then
  begin
    AOrigen.DataSet.First;
    Serie := AOrigen.DataSet.FieldByName('SERIE_CON').AsString;
  end;
  ASelector.Properties.ListFieldNames := 'SERIE_CON';
  ASelector.Properties.ListSource := AOrigen;
  ASelector.Refresh;
  if ACampoSerie.AsString <> Serie then
    ACampoSerie.AsString := Serie;
end;

procedure AsignarOrigenesRegistroFacturaVcl(
  const AControles: TControlesRegistroFacturaVcl;
  AConsolidacion, AErrores: TDataSource);
begin
  AControles.IdConsolidacion.DataBinding.DataSource := AConsolidacion;
  AControles.Estado.DataBinding.DataSource := AConsolidacion;
  AControles.RespuestaCompleta.DataBinding.DataSource := AConsolidacion;
  AControles.ImagenQr.DataBinding.DataSource := AConsolidacion;
  AControles.IdCola.DataBinding.DataSource := AConsolidacion;
  AControles.FechaProcesamiento.DataBinding.DataSource := AConsolidacion;
  AControles.EmisorIrs.DataBinding.DataSource := AConsolidacion;
  AControles.InstanteEmision.DataBinding.DataSource := AConsolidacion;
  AControles.NumeroCadena.DataBinding.DataSource := AConsolidacion;
  AControles.HashCadena.DataBinding.DataSource := AConsolidacion;
  AControles.UrlVerifactu.DataBinding.DataSource := AConsolidacion;
  AControles.QrBase64.DataBinding.DataSource := AConsolidacion;
  AControles.PeticionCompleta.DataBinding.DataSource := AConsolidacion;
  AControles.IdPeticion.DataBinding.DataSource := AConsolidacion;
  // El dfm ataba este grid al datamodule por NOMBRE GLOBAL: con dos
  // ventanas de facturas abiertas resolvia a la instancia equivocada.
  AControles.VistaLog.DataController.DataSource := AErrores;
end;

constructor TPresentadorCabeceraFacturaVcl.Create(
  const AContexto: TContextoCabeceraFacturaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

function TPresentadorCabeceraFacturaVcl.CabeceraViva: Boolean;
begin
  Result := Assigned(FContexto.Cabecera) and
    (FContexto.Cabecera.DataSet <> nil) and
    FContexto.Cabecera.DataSet.Active;
end;

function TPresentadorCabeceraFacturaVcl.ObtenerSolicitudEstado(
  out ASolicitud: TSolicitudEstadoFactura): Boolean;
var
  CampoFase: TField;
begin
  ASolicitud := Default(TSolicitudEstadoFactura);
  Result := Assigned(FContexto.DataModule) and CabeceraViva;
  if Result then
  begin
    CampoFase := FContexto.Cabecera.DataSet.FindField(ffasefac);
    Result := Assigned(CampoFase);
    if Result then
    begin
      ASolicitud.Fase := CampoFase.AsString;
      ASolicitud.Consolidada :=
        FContexto.Cabecera.DataSet.FieldByName(fescon).AsString = 'S';
      ASolicitud.SinVerifactu := SinVerifactuActivo(
        FContexto.ParametrosApp);
      if FContexto.Cabecera.DataSet.IsEmpty then
        ASolicitud.EstadoDatos := edfSinDatos
      else
      begin
        case FContexto.Cabecera.DataSet.State of
          dsInsert:
            ASolicitud.EstadoDatos := edfInsertando;
          dsEdit:
            ASolicitud.EstadoDatos := edfEditando;
        else
          ASolicitud.EstadoDatos := edfConsultando;
        end;
      end;
    end;
  end;
end;

procedure TPresentadorCabeceraFacturaVcl.ActualizarBloqueoEdicion;
var
  Solicitud: TSolicitudEstadoFactura;
begin
  if Assigned(FContexto.Estado) and ObtenerSolicitudEstado(Solicitud) then
    FContexto.Estado.Presentar(Solicitud);
end;

procedure TPresentadorCabeceraFacturaVcl.AplicarEstadoDatos;
var
  Situacion: TSituacionCabeceraFactura;
  Controles: TControlesCabeceraFactura;
begin
  if CabeceraViva then
  begin
    Situacion := CrearSituacionCabeceraFactura(
      ecfNavegando,
      SinVerifactuActivo(FContexto.ParametrosApp));
    if FContexto.Cabecera.DataSet.State = dsInsert then
      Situacion.Edicion := ecfInsertando
    else if FContexto.Cabecera.DataSet.State = dsEdit then
      Situacion.Edicion := ecfEditando;
    Controles := CalcularControlesCabeceraFactura(Situacion);
    FContexto.Numero.Properties.ReadOnly :=
      not Controles.NumeroSerieEditables;
    FContexto.Serie.Properties.ReadOnly :=
      not Controles.NumeroSerieEditables;
    if Controles.BloquearTarifaCanal then
    begin
      FContexto.Tarifa.Properties.ReadOnly := True;
      FContexto.CanalIva.Properties.ReadOnly := True;
    end;
    FContexto.BotonNuevaFactura.Enabled := Controles.PuedeNuevaFactura;
    FContexto.BotonRectificar.Enabled := Controles.PuedeRectificar;
    if Controles.EnEdicion then
    begin
      FContexto.BotonConsolidar.Enabled := Controles.PuedeConsolidar;
      FContexto.BotonImprimir.Enabled := Controles.PuedeImprimir;
    end
    else
      // Imprimir y Consolidar dependen de la fase Verifactu del registro
      // activo, no solo del estado del dataset.
      ActualizarBloqueoEdicion;
  end;
end;

procedure TPresentadorCabeceraFacturaVcl.RefrescarAlmacenes(
  AField: TField);
begin
  if ((AField = nil) or SameText(AField.FieldName, 'CODIGO_EMP_FAC')) and
     Assigned(FContexto.DataModule) and
     FContexto.DataModule.unqryTablaG.Active and
     (not FContexto.DataModule.unqryTablaG.IsEmpty) then
    FContexto.DataModule.RefrescarAlmacenes(
      FContexto.DataModule.unqryTablaG.FieldByName(
        'CODIGO_EMP_FAC').AsString);
end;

procedure TPresentadorCabeceraFacturaVcl.ActualizarComboSeries;
var
  SerieAnterior: string;
begin
  if FContexto.Cabecera.State = dsInsert then
  begin
    SerieAnterior := FContexto.Cabecera.DataSet.
      FieldByName(fseriefac).AsString;
    FContexto.DataModule.CrearTablaSeries(
      FContexto.Cabecera.DataSet.FindField(fcodemp).AsString,
      FContexto.Cabecera.DataSet.FindField(fcodcli).AsString,
      FContexto.Cabecera.DataSet.FindField(ffechfac).AsDateTime);
    RefrescarSelectorSerieFactura(FContexto.Serie,
      FContexto.DataModule.dsSeriesEditCombo,
      FContexto.Cabecera.DataSet.FieldByName(fseriefac), SerieAnterior);
  end
  else
    FContexto.Serie.Properties.ListSource :=
      FContexto.DataModule.dsSeries;
end;

procedure TPresentadorCabeceraFacturaVcl.SeriesCambiadas(Sender: TObject);
begin
  ActualizarComboSeries;
end;

procedure TPresentadorCabeceraFacturaVcl.CambiarIVA;
begin
  if CabeceraViva and (FContexto.Cabecera.DataSet.State = dsInsert) then
    FContexto.DataModule.AsignarIVA(
      FContexto.Cabecera.DataSet.FieldByName(
        'GRUPO_ZONA_IVA_EMPRESA_FAC').AsString,
      FContexto.DataModule.unqryTablaG);
end;

procedure TPresentadorCabeceraFacturaVcl.CopiarEmpresa(
  const ACodigoEmpresa: string);
var
  dsEmpresa: TDataSet;
begin
  // La lectura de la empresa es del repositorio: la pantalla no arma SQL.
  FContexto.Cabecera.DataSet.FindField('CODIGO_EMP_FAC').AsString :=
    ACodigoEmpresa;
  dsEmpresa := FContexto.Lecturas.BuscarEmpresa(ACodigoEmpresa);
  try
    if dsEmpresa.RecordCount > 0 then
      FContexto.DataModule.CopiarEmpresaaFactura(dsEmpresa);
    FContexto.DataModule.RefrescarAlmacenes(ACodigoEmpresa);
  finally
    dsEmpresa.Close;
    FreeAndNil(dsEmpresa);
  end;
end;

procedure TPresentadorCabeceraFacturaVcl.AplicarTarifa(
  const ACodigoTarifa: string);
begin
  if FContexto.DataModule.unqryTarifas.Locate(
       'CODIGO_TAR_ARTTAR', ACodigoTarifa, []) then
    FContexto.Cabecera.DataSet.FieldByName(
      'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
      FContexto.DataModule.unqryTarifas.FieldByName(
        'ESIMP_INCL_TAR').AsString
  else
    ShowMessage_fza(SErrorTarifaSeleccionadaNoEncontrada);
end;

procedure TPresentadorCabeceraFacturaVcl.CambiarEstadoRecibo(
  const AEstado: string);
var
  dsRecibos: TDataSet;
begin
  dsRecibos := FContexto.DataModule.unqryRecibos;
  if not (dsRecibos.State in [dsEdit, dsInsert]) then
    dsRecibos.Edit;
  dsRecibos.FieldByName('ESTADO_RECIBO_REC').AsString := AEstado;
  if AEstado = 'Pagado' then
    dsRecibos.FieldByName('FECHA_PAGO_RECIBO_REC').AsDateTime := Trunc(Now)
  else if (AEstado = 'Emitido') or (AEstado = 'Devuelto') then
    dsRecibos.FieldByName('FECHA_PAGO_RECIBO_REC').AsVariant := Null;
  dsRecibos.Post;
end;

procedure TPresentadorCabeceraFacturaVcl.SenalarCampo(
  ACampo: TCampoValidacionFac);
begin
  // La excepcion de dominio senala un campo logico; aqui se decide la
  // pestaña y el control donde debe caer el foco.
  case ACampo of
    cvfNinguno:
      ;
    cvfSerie:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCabecera;
      if FContexto.Serie.CanFocus then
        FContexto.Serie.SetFocus;
    end;
    cvfRazonSocialCliente:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCliente;
      if FContexto.RazonSocialCliente.CanFocus then
        FContexto.RazonSocialCliente.SetFocus;
    end;
    cvfRazonSocialEmpresa:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaEmpresa;
      if FContexto.RazonSocialEmpresa.CanFocus then
        FContexto.RazonSocialEmpresa.SetFocus;
    end;
    cvfFecha:
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCabecera;
    cvfNifCliente:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCliente;
      if FContexto.NifCliente.CanFocus then
        FContexto.NifCliente.SetFocus;
    end;
    cvfNifEmpresa:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaEmpresa;
      if FContexto.NifEmpresa.CanFocus then
        FContexto.NifEmpresa.SetFocus;
    end;
    cvfPais:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCliente;
      if FContexto.PaisCliente.CanFocus then
        FContexto.PaisCliente.SetFocus;
    end;
    cvfOperacionFiscal:
    begin
      FContexto.PaginasCabecera.ActivePage := FContexto.PestanaCabecera;
      if FContexto.TipoOperacion.CanFocus then
        FContexto.TipoOperacion.SetFocus;
    end;
    cvfTipoIva:
      FContexto.PaginasDetalle.ActivePage := FContexto.PestanaLineas;
  end;
end;

procedure TPresentadorCabeceraFacturaVcl.MostrarResultadoOperacion(
  const AResultado: TResultadoOperacionFactura);
begin
  if (not AResultado.Exito) and (AResultado.Mensaje <> '') then
    ShowMessage_fza(AResultado.Mensaje);
end;

procedure TPresentadorCabeceraFacturaVcl.MostrarResultadoBorrado(
  const AResultado: TResultadoBorradoFactura);
begin
  if (not AResultado.Permitido) and (AResultado.Mensaje <> '') then
    ShowMessage_fza(AResultado.Mensaje);
end;

procedure TPresentadorCabeceraFacturaVcl.MostrarAdvertencia(
  const AMensaje: string);
begin
  if AMensaje <> '' then
    ShowMessage_fza(AMensaje);
end;

procedure TPresentadorCabeceraFacturaVcl.MostrarErrorValidacion(
  const AError: EValidacionFactura);
begin
  ShowMessage_fza(AError.Message);
  SenalarCampo(AError.Campo);
end;

function TPresentadorCabeceraFacturaVcl.ConfirmarBorrado(
  const ASerie, ANumero: string): Boolean;
begin
  Result := MessageDlg_fza(
    Format(SPreguntaBorrarFactura, [ASerie, ANumero]),
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

end.

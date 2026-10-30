{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenImp                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal generico de impresion basado en FastReport.                         }
{    Base reutilizable para los modales de impresion especificos.              }
{******************************************************************************}
unit inMtoModalGenImp;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoFrmBase, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  dxSkinsCore, dxSkinBlue, frxClass, frxDBSet, StdCtrls, cxButtons, DB,
  DBClient, cxControls, cxContainer, cxEdit, cxTextEdit, cxLabel, frxExportPDF,
  ExtCtrls, ComCtrls, dxCore, cxDateUtils, cxMaskEdit, cxDropDownEdit,
  cxCalendar, frxDesgn, cxGroupBox, cxRadioGroup, frxExportBaseDialog,
  frxExportXLSX,
  inLibGlobalVar, inMtoModalGenImpEle, cxStyles, dxSkinsForm,
  cxClasses, cxLocalization, Vcl.Menus, System.UITypes, JvComponentBase,
  JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinsDefaultPainters, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, System.Actions, Vcl.ActnList,
  frxExportBaseImageSettingsDialog, frCoreClasses,
  frLocalization, frxBarcode,
  frLanguageSpanish, frxSmartMemo, inLibImpresionPersistenciaIntf,
  inLibVentanaEspera, cxCheckBox, inLibCorreoTickets,
  inLibCorreoDocumentoIntf, inLibResumenSeleccionesInforme,
  System.Diagnostics;

const
  WM_INICIAR_ENVIO_CORREO_DOCUMENTO = WM_APP + $462;

type
  TfrmPrint = class(TfrmBase, IEliminadorFormatoImpresion)
    pnl1: TPanel;
    btnPDF: TcxButton;
    btnImprimir: TcxButton;
    btnVistaPreliminar: TcxButton;
    btnSalir: TcxButton;
    frxrprt1: TfrxReport;
    frxpdfxprtPedWeb: TfrxPDFExport;
    btnEditar: TcxButton;
    frxlsxprtExcel: TfrxXLSXExport;
    btnExcel: TcxButton;
    frxdsgnr1: TfrxDesigner;
    frxReportOrigen: TfrxReport;
    ActionList1: TActionList;
    actSalir: TAction;
    frLocalizationController1: TfrLocalizationController;
    procedure btnImprimirClick(Sender: TObject); virtual;
    procedure btnSalirClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject); virtual;
    procedure btnVistaPreliminarClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function frxdsgnr1SaveReport(Report: TfrxReport; SaveAs: Boolean): Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actSalirExecute(Sender: TObject);
  private
    sElegido:String;
    // Cuando el usuario entra por Editar, fijamos el nombre del formato
    // al inicio del flujo (en btnEditarClick) en sElegido. Esta flag
    // indica al frxdsgnr1SaveReport que NO debe presentar el modal de
    // guardado: el nombre del formato ya esta decidido y el guardar va
    // directo a fza_usuarios_perfiles con sElegido y FScopePerfilFijado.
    FFormatoFijado: Boolean;
    FScopePerfilFijado: string;
    FServiciosPersistencia: TServiciosPersistenciaImpresion;
    FRestauracionesGuias: TInterfaceList;
    FUltimaRutaPdf: string;
    FUltimaImpresionCorrecta: Boolean;
    // D22: True si frxrprt1 contiene un formato personalizado
    // cargado del BLOB; False si contiene la plantilla base.
    FInformeEsPersonalizado: Boolean;
    // D22: evita traducir dos veces el informe ya cargado.
    FInformeTraducido: Boolean;
    // Ventana de espera de los flujos interactivos (consulta, carga del
    // formato y preparación de páginas). Vive solo durante cada flujo.
    FVentanaEspera: IVentanaEspera;
    // Página que FastReport está preparando; alimenta el detalle.
    FPaginaInforme: Integer;
    // Casilla "Enviar por email", creada al mostrar el modal solo si quien
    // lo abre ha llamado a ConfigurarDocumentoCorreo.
    FCasillaCorreoDocumento: TcxCheckBox;
    FCorreoDocumentoConfigurado: Boolean;
    FTipoCorreoDocumento: TTipoDocumentoCorreo;
    FSerieCorreoDocumento: string;
    FFormatoCorreoDocumento: string;
    FNumeroCorreoDocumento: string;
    FActualizandoCasillaCorreo: Boolean;
    FEnvioCorreoDocumentoPendiente: Boolean;
    FProcesandoCorreoDocumento: Boolean;
    // FZ-ISSUE-099: el aviso de impresora no encontrada sale una vez.
    FAvisoImpresoraRegistrado: Boolean;
    // Resumen de selecciones: cuándo se pidió el informe y cuánto tardó
    // en obtener los datos (consulta, carga y guías; sin el diálogo de
    // formato ni la preparación de páginas).
    FMomentoSolicitudInforme: TDateTime;
    FDuracionDatosInforme: Int64;
    FCronometroDatos: TStopwatch;
    // Si no está vacío, el selector solo ofrece los formatos con este
    // prefijo y los guardados lo conservan (tickets: 'Ticket').
    FPrefijoFormatos: string;
    function ContextoFormatos: TContextoFormatosImpresion;
    function LeerBlobFormato(const aDescripcion: string;
                             aStream: TStream): Boolean;
    procedure GuardarBlobFormato(const aUsuario, aSubKey,
                                  aDescripcion: string;
                                  aStream: TStream;
                                  aInsertar: Boolean);
    // D22: traduce los textos visibles del informe cargado antes
    // de PrepareReport. No se invoca en el flujo de edicion para
    // no guardar textos traducidos en el BLOB del formato.
    procedure TraducirInformeActual;
    // Fija como impresora del informe la de documentos resuelta por
    // parámetros (appImpresoraInformes). Solo al imprimir o
    // previsualizar: no se invoca antes de editar para no guardar el
    // nombre de la impresora en el BLOB del formato.
    procedure AplicarImpresoraDocumentos;
    function RectanguloReferenciaEspera: TRect;
    // Consulta, selección de formato y preparación de páginas con la
    // ventana de espera. True si hay formato y el informe quedó
    // preparado sin que el usuario cancelase.
    function PrepararInformeConEspera(
      AAplicarImpresora: Boolean): Boolean;
    // PrepareReport con el progreso redirigido a la ventana de espera.
    function PrepararPaginasInforme: Boolean;
    // Cabecera con las selecciones de DescribirSelecciones, el usuario,
    // el momento de la petición y la duración de la consulta.
    procedure InsertarResumenSelecciones;
    procedure InformeProgreso(
      Sender: TfrxReport;
      ProgressType: TfrxProgressType;
      Progress: Integer);
    procedure ExportarPdfInteractivo;
    // FZ-ISSUE-102.13: nombre que propone el diálogo Guardar al exportar
    // cuando el informe no fija uno propio: título de la ventana sin el
    // verbo inicial y la fecha (p. ej. "Histórico de Depósitos_20261001").
    function NombreExportacionPorDefecto(const AExtension: string): string;
    // Guardar del diseñador: el formato va al BLOB de fza_usuarios_perfiles.
    function GuardarFormatoEnBaseDatos(AReport: TfrxReport): Boolean;
    // Guardar como del diseñador: copia del .fr3 en un fichero elegido.
    procedure GuardarFormatoEnFichero(AReport: TfrxReport);
    // FZ-ISSUE-096: True si algún TfrxDBDataset del informe no tiene
    // todavía dataset (los que se enlazan en Preparar_consulta).
    function HayDatasetInformeSinConectar: Boolean;
    procedure ConectarDatasetsParaEdicion;
    procedure EliminarFormatoPredeterminado;
    procedure GuardarFormatoPredeterminado(const AFormato: string);
    procedure ActualizarFormatoPredeterminado(
      ASelector: TfrmMtoModalGenImpEle;
      const AFormatoAnterior: string);
    procedure SeleccionarFormato(
      const AFormatoPredeterminado: string;
      out AAccion: string);
    procedure CargarFormatoElegido(const AAccion: string);
    procedure PrepararCasillaCorreoDocumento;
    procedure CasillaCorreoDocumentoCambiada(Sender: TObject);
    procedure DesmarcarCasillaCorreoDocumento;
    procedure IniciarEnvioCorreoDocumento;
    procedure WMIniciarEnvioCorreoDocumento(
      var Message: TMessage); message WM_INICIAR_ENVIO_CORREO_DOCUMENTO;
  protected
    procedure EnviarCorreoDocumento(
      ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero: string); virtual;
    procedure EnviarCorreoDocumentoPreparado(
      ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero, ANombreDocumento, AEmail: string;
      const ADatos: TDatosCorreoDocumento);
    procedure PrepararSelectorFormato(
      ASelector: TfrmMtoModalGenImpEle;
      const AFormatoPredeterminado: string); virtual;
    function CargarFormatoGuardado(
      const AFormato: string): Boolean; virtual;
    // Los documentos cargan su referencia antes de editar; los listados
    // conservan las consultas de diseno sin exigir filtros de impresion.
    procedure PrepararDatosEdicion; virtual;
    // Los avisos modales se muestran antes de crear la ventana de progreso.
    procedure AvisarAntesDeConsulta; virtual;
    function TraducirContenidoInforme: Boolean; virtual;
    procedure PdfExportado(const ARuta: string); virtual;
    // Ventana de espera compartida por los flujos de impresión; los
    // descendientes la usan en sus propios flujos (p. ej. Excel).
    procedure IniciarEspera(const AFase: string);
    procedure ActualizarDetalleEspera(const ADetalle: string);
    procedure OcultarEspera;
    procedure TerminarEspera;
    function EsperaCancelada: Boolean;
    // Texto de detalle mientras se preparan las páginas; los
    // descendientes pueden añadir el registro en curso.
    function DetalleProgresoInforme: string; virtual;
    // Los listados con opciones describen aquí las que aplica la
    // consulta (se llama tras Preparar_consulta). Sin selecciones el
    // informe sale sin resumen: documentos y etiquetas no lo llevan.
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); virtual;
    // Tiempo de obtención de datos del resumen: se inicia al pedir el
    // informe y se pausa durante lo que no es consulta (diálogos).
    procedure IniciarMedicionDatos;
    procedure PausarMedicionDatos;
    procedure ReanudarMedicionDatos;
    // Para hojas de cálculo: "Selección:", una selección por línea y la
    // línea de emisión. Vacío si el listado no describe selecciones.
    function LineasResumenSelecciones: TArray<string>;
    procedure DoShow; override;
    property FormatoElegido: string read sElegido;
    property UltimaImpresionCorrecta: Boolean
      read FUltimaImpresionCorrecta;
  public
    destructor Destroy; override;
    procedure CargarFormatos(form:TfrmMtoModalGenImpEle);
    procedure DeleteForm(sElegido:String;form:TfrmMtoModalGenImpEle);
    procedure EliminarFormatoImpresion(
      const ANombre: string;
      ASelector: TObject);
    procedure preparar_consulta; virtual; abstract;
    procedure AfterReportLoaded; virtual;
    // OnBeforePrint del report: encadena la sustitución de fotos
    // (foto300/foto600/fotoReal) con la del QR tributario Verifactu
    // ('qrverifactu') en cada iteración del informe
    procedure ReportBeforePrintConQR(Component: TfrxReportComponent);
    procedure VistaPreviaCreada(Sender: TObject);
    procedure ReportInicioDocumento(Sender: TObject);
    procedure Consultar_Formularios(bForzarSeleccion: Boolean = False);
    // Selecciona un formato sin mostrar el modal. Se usa en procesos
    // automatizados que ya reciben el nombre como argumento.
    function SeleccionarFormatoSinDialogo(
      const AFormato: string): Boolean;
    // Exporta el informe usando los datos que el llamador ya ha preparado.
    // Evita ejecutar dos veces la consulta en los procesos por lotes.
    function ExportarPdfPreparado(
      const ARuta: string;
      ANotificarExportacion: Boolean = True): Boolean;
    // Imprime sin mostrar el dialogo del controlador usando los datos que
    // el llamador ya ha preparado. Un nombre vacio conserva la impresora
    // predeterminada del informe.
    function ImprimirPreparadoEn(
      const AImpresora: string): Boolean;
    // Prepara las páginas del formato elegido sin imprimir ni mostrar
    // diálogos, para quien las vuelca por su cuenta (ticket como imagen).
    function PrepararPaginasSinImprimir: Boolean;
    // Crea en runtime un dataset auxiliar por cada guia configurada en
    // fza_informes_guias para Self.Name, enlazandolo MasterSource-style
    // al frxDBDataset master y exponiendolo al frxrprt1.
    //   aSoloUsadasEnReport = True : solo se abren las guias cuyo
    //                                CODIGO_INFGUI aparece referenciado
    //                                en el .frx (modo impresion).
    //   aSoloUsadasEnReport = False: se abren todas las guias activas
    //                                (modo edicion del diseñador).
    procedure AbrirGuiasRuntime(aSoloUsadasEnReport: Boolean);
    procedure CerrarGuiasRuntime;
    // FZ-ISSUE-344: Preparar_consulta y reenlace de los TfrxDBDataset.
    procedure PrepararConsultaInforme;
    procedure ReenlazarDatasetsInforme;
    // Lanza el modal de mantenimiento de guias para Self.Name y un
    // formato concreto (vacio o 'Predeterminado' = global). Si se pasa
    // un report el modal muestra ademas la lista de datasets (cabecera y
    // detalle) con sus campos como ayuda visual al rellenar las guias.
    procedure EditarGuiasParaFormato(const aFormato: string;
                                     aReport: TfrxReport = nil);
    // Al guardar un formato personalizado del .frx, clona en
    // fza_informes_guias las guias globales referenciadas en el report
    // para que queden tambien atadas a ese formato. Idempotente.
    procedure ConsolidarGuiasParaFormato(const aFormato: string);
    // Exporta sin diálogo el formato que el usuario acaba de seleccionar.
    function ExportarPdfActual(const ARuta: string): Boolean;
    property UltimaRutaPdf: string read FUltimaRutaPdf;
    // Documento que la casilla "Enviar por email" manda como PDF por el
    // servicio web. Sin llamarlo el modal no muestra la casilla.
    procedure ConfigurarDocumentoCorreo(
      ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero: string);
    // NUEVOS HOOKS PARA SOPORTE DE CLIENTDATASETS:
    function RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet; virtual;
    procedure OnGuiasAplicadas; virtual;
    property PrefijoFormatos: string read FPrefijoFormatos
      write FPrefijoFormatos;
  end;

procedure RebindReportDataSetsByDataModule(Report: TfrxReport;
                                           DM: TDataModule);
procedure AjustarFormatoHorizontalTallas(AInforme: TfrxReport);

implementation

uses
  inLibFormatoDocumento, inLibPosicionFormulario,
  inLibMensajesVcl,
  inLibPivoteVentaCalculo,
  inMtoModalGenImpSave, inLibUser, inLibPathTokens,
  System.Generics.Collections, System.Rtti, System.TypInfo,
  System.StrUtils, frPrinter,
  inLibBuscarImpresora, inLibFotos, inLibVerifactu,
  inMtoModalInformesGuias, inMtoModalWizardEditar,
  inLibInformesGuiasCache, inLibMsgComun, inLibTraduccionesInforme,
  inLibFormatoCantidadesInforme,
  inLibVentasPantallaIntf, inLibCorreoDocumentoVcl,
  UniDataVentasPantallaComposicion, UniDataCorreoDocumento,
  inLibResumenSeleccionesFrx;

{$R *.dfm}

resourcestring
  SDescripcionFormatoPredeterminado = 'Predet: %s';
  SErrorDocumentoNoEnviadoCorreo =
    'No se pudo enviar el documento (%s) por correo electrónico.';
  SErrorPdfTemporalCorreoDocumento =
    'No se pudo generar el PDF del documento (%s) para enviarlo por ' +
    'correo electrónico.';
  SErrorDocumentoCorreoNoEncontrado =
    'No se encuentra el documento %s en la base de datos.';

destructor TfrmPrint.Destroy;
begin
  FVentanaEspera := nil;
  try
    try
      CerrarGuiasRuntime;
    finally
      FreeAndNil(FRestauracionesGuias);
    end;
  finally
    inherited Destroy;
  end;
end;

procedure TfrmPrint.ConfigurarDocumentoCorreo(
  ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero: string);
begin
  FTipoCorreoDocumento := ATipo;
  FSerieCorreoDocumento := Trim(ASerie);
  FNumeroCorreoDocumento := Trim(ANumero);
  FCorreoDocumentoConfigurado := FNumeroCorreoDocumento <> '';
  FFormatoCorreoDocumento := FORMATO_DOCUMENTO_DEFECTO;
end;

procedure TfrmPrint.DoShow;
begin
  PrepararCasillaCorreoDocumento;
  inherited;
end;

procedure TfrmPrint.PrepararCasillaCorreoDocumento;
begin
  if (FCasillaCorreoDocumento = nil) and FCorreoDocumentoConfigurado then
  begin
    FCasillaCorreoDocumento := TcxCheckBox.Create(Self);
    FCasillaCorreoDocumento.Parent := Self;
    FCasillaCorreoDocumento.Caption := SCasillaEnviarDocumentoEmail;
    FCasillaCorreoDocumento.Transparent := True;
    // Tras asignar Parent las medidas van en píxeles físicos (125 %).
    FCasillaCorreoDocumento.Left := ScaleValue(16);
    FCasillaCorreoDocumento.Width := pnl1.Left - ScaleValue(24);
    FCasillaCorreoDocumento.Top := ClientHeight -
      FCasillaCorreoDocumento.Height - ScaleValue(12);
    FCasillaCorreoDocumento.Anchors := [akLeft, akRight, akBottom];
    FCasillaCorreoDocumento.Properties.OnEditValueChanged :=
      CasillaCorreoDocumentoCambiada;
  end;
end;

procedure TfrmPrint.DesmarcarCasillaCorreoDocumento;
begin
  FActualizandoCasillaCorreo := True;
  try
    FCasillaCorreoDocumento.Checked := False;
  finally
    FActualizandoCasillaCorreo := False;
  end;
end;

procedure TfrmPrint.CasillaCorreoDocumentoCambiada(Sender: TObject);
begin
  // La casilla inicia el envío, como en facturas. Se difiere con un
  // mensaje para no abrir modales dentro del cambio de valor del editor.
  if not FActualizandoCasillaCorreo and
     FCasillaCorreoDocumento.Checked and
     not FEnvioCorreoDocumentoPendiente and
     not FProcesandoCorreoDocumento then
  begin
    FEnvioCorreoDocumentoPendiente := True;
    pnl1.Enabled := False;
    if not PostMessage(Handle, WM_INICIAR_ENVIO_CORREO_DOCUMENTO, 0, 0) then
    begin
      FEnvioCorreoDocumentoPendiente := False;
      pnl1.Enabled := True;
      DesmarcarCasillaCorreoDocumento;
    end;
  end;
end;

procedure TfrmPrint.WMIniciarEnvioCorreoDocumento(var Message: TMessage);
begin
  FEnvioCorreoDocumentoPendiente := False;
  if FCasillaCorreoDocumento.Checked then
    IniciarEnvioCorreoDocumento
  else
    pnl1.Enabled := True;
  Message.Result := 0;
end;

procedure TfrmPrint.IniciarEnvioCorreoDocumento;
var
  sMensaje: string;
begin
  FProcesandoCorreoDocumento := True;
  FCasillaCorreoDocumento.Enabled := False;
  pnl1.Enabled := False;
  try
    try
      if CorreoTicketsConfigurado(ParametrosApp, sMensaje) then
        EnviarCorreoDocumento(
          FTipoCorreoDocumento,
          FSerieCorreoDocumento,
          FNumeroCorreoDocumento)
      else
        ShowMessage_fza(sMensaje);
    except
      on E: Exception do
        MessageDlg_fza(
          Format(SErrorDocumentoNoEnviadoCorreo,
            [FormatearDocumento(FFormatoCorreoDocumento,
              FSerieCorreoDocumento, FNumeroCorreoDocumento)]) +
          sLineBreak + E.ClassName + ': ' + E.Message,
          mtError,
          [mbOK],
          0);
    end;
  finally
    // Tras enviar, cancelar o fallar se desmarca: reintentar es marcarla.
    DesmarcarCasillaCorreoDocumento;
    FCasillaCorreoDocumento.Enabled := True;
    pnl1.Enabled := True;
    FProcesandoCorreoDocumento := False;
  end;
end;

procedure TfrmPrint.EnviarCorreoDocumento(
  ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero: string);
var
  oDatos: TDatosCorreoDocumento;
  sEmail: string;
  sNombre: string;
begin
  oDatos := CrearLectorDatosCorreoDocumento(ConexionPrincipal).Leer(
    ATipo, ASerie, ANumero);
  FFormatoCorreoDocumento := oDatos.FormatoDocumento;
  if not oDatos.Encontrado then
    MessageDlg_fza(
      Format(SErrorDocumentoCorreoNoEncontrado, [FormatearDocumento(
        oDatos.FormatoDocumento, ASerie, ANumero)]),
      mtError,
      [mbOK],
      0)
  else
  begin
    sNombre := NombreDocumentoCorreoTraducido(
      ATipo, oDatos.NombreDocumento, Traducciones);
    // Mismo comienzo que el botón PDF: el usuario elige el formato y
    // después escribe el destinatario (no se toma del cliente).
    AvisarAntesDeConsulta;
    PrepararConsultaInforme;
    Consultar_Formularios;
    if (sElegido <> '') and
       SolicitarEmailDocumento(
         Self,
         TituloEnvioDocumentoCorreo(sNombre),
         '',
         sEmail) then
      EnviarCorreoDocumentoPreparado(
        ATipo, ASerie, ANumero, oDatos.NombreDocumento, sEmail, oDatos);
  end;
end;

procedure TfrmPrint.EnviarCorreoDocumentoPreparado(
  ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero, ANombreDocumento, AEmail: string;
  const ADatos: TDatosCorreoDocumento);
var
  bEnviado: Boolean;
  oRutas: TStringList;
  sMensaje: string;
  sReferencia: string;
  sRutaPdf: string;
begin
  sReferencia := FormatearDocumento(
    ADatos.FormatoDocumento, ASerie, ANumero);
  sRutaPdf := CrearRutaPdfTemporalCorreo(ATipo, ASerie, ANumero);
  oRutas := TStringList.Create;
  try
    if not ExportarPdfPreparado(sRutaPdf, False) then
      MessageDlg_fza(
        Format(SErrorPdfTemporalCorreoDocumento, [sReferencia]),
        mtError,
        [mbOK],
        0)
    else
    begin
      oRutas.Add(sRutaPdf);
      bEnviado := EnviarDocumentosPorCorreo(
        ParametrosApp,
        ATipo,
        sReferencia,
        ANombreDocumento,
        ADatos.NombreEmpresa,
        AEmail,
        ADatos.EmailEmpresa,
        oRutas,
        RegistroLog,
        sMensaje);
      if bEnviado then
        MessageDlg_fza(sMensaje, mtInformation, [mbOK], 0)
      else
        MessageDlg_fza(
          Format(SErrorDocumentoNoEnviadoCorreo, [sReferencia]) +
          sLineBreak + sMensaje,
          mtError,
          [mbOK],
          0);
    end;
  finally
    FreeAndNil(oRutas);
    EliminarPdfTemporalCorreo(sRutaPdf, RegistroLog);
  end;
end;

function TfrmPrint.RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet;
begin
  Result := aCDS; // Por defecto devuelve el mismo
end;

procedure TfrmPrint.OnGuiasAplicadas;
begin
  // Vacío por defecto en la clase base
end;

procedure TfrmPrint.PdfExportado(const ARuta: string);
begin
  FUltimaRutaPdf := ARuta;
end;

function RutaPdfExportado(AExportador: TfrxPDFExport): string;
begin
  Result := AExportador.FileName;
  if ExtractFilePath(Result) = '' then
    Result := IncludeTrailingPathDelimiter(AExportador.DefaultPath) + Result;
  if SameText(ExtractFileExt(Result), '') then
    Result := Result + '.pdf';
  if not FileExists(Result) then
    Result := '';
end;

procedure RebindReportDataSetsByDataModule(Report: TfrxReport;
                                           DM: TDataModule);
var
  Map: TDictionary<string, TfrxDBDataset>;
  i: Integer;
  comp: TComponent;
  ds: TfrxDBDataset;
  obj: TfrxComponent;
  ctx: TRttiContext;
  rType: TRttiType;
  prop: TRttiProperty;
  propDataSetName: TRttiProperty;
  curVal: TValue;
  curObj: TObject;
  newDs: TfrxDBDataset;
  sDataSetName: string;
begin
  if (Report <> nil) and (DM <> nil) then
  begin
    Map := TDictionary<string, TfrxDBDataset>.Create;
    ctx := TRttiContext.Create;
    try
      for i := 0 to DM.ComponentCount - 1 do
      begin
        comp := DM.Components[i];
        if (comp is TfrxDBDataset) and
           (TfrxDBDataset(comp).UserName <> '') then
          Map.AddOrSetValue(TfrxDBDataset(comp).UserName,
            TfrxDBDataset(comp));
      end;
      if Map.Count > 0 then
      begin
        // FastReport registra globalmente todos los TfrxDataSet. Cuando hay
        // dos instancias del mismo modulo (por ejemplo, la pantalla de
        // facturas y el impresor del lote), ambas publican los UserName
        // "Facturas" y "Lineas Facturas". El modo global puede resolver el
        // informe contra la primera instancia y mezclar FieldDefs con otro
        // TDataSet. EnabledDataSets es el mecanismo de FastReport para
        // acotar la resolucion al modulo de esta instancia.
        Report.EngineOptions.UseGlobalDataSetList := False;
        Report.EnabledDataSets.Clear;
        Report.DataSets.Clear;
        // Conservamos el orden de los componentes del data module y evitamos
        // duplicados si dos wrappers declaran accidentalmente el mismo
        // UserName.
        for i := 0 to DM.ComponentCount - 1 do
        begin
          comp := DM.Components[i];
          if comp is TfrxDBDataset then
          begin
            ds := TfrxDBDataset(comp);
            if (ds.UserName <> '') and
               Map.TryGetValue(ds.UserName, newDs) and
               (newDs = ds) then
            begin
              Report.EnabledDataSets.Add(ds);
              Report.DataSets.Add(ds);
            end;
          end;
        end;
        // El propio TfrxReport tambien puede actuar como banda de datos.
        // AllObjects no incluye la raiz, por lo que se trata expresamente.
        sDataSetName := Report.DataSetName;
        if (sDataSetName <> '') and
           Map.TryGetValue(sDataSetName, newDs) then
          Report.DataSet := newDs;
        for i := 0 to Report.AllObjects.Count - 1 do
        begin
          obj := TfrxComponent(Report.AllObjects[i]);
          rType := ctx.GetType(obj.ClassType);
          prop := rType.GetProperty('DataSet');
          if (prop <> nil) and prop.IsReadable and prop.IsWritable then
          begin
            sDataSetName := '';
            curVal := prop.GetValue(obj);
            if not curVal.IsEmpty and (curVal.Kind = tkClass) then
            begin
              curObj := curVal.AsObject;
              if curObj is TfrxDBDataset then
                sDataSetName := TfrxDBDataset(curObj).UserName;
            end;
            // Un formato guardado puede conservar DataSetName aunque el
            // puntero DataSet no se haya podido resolver al cargarlo.
            if sDataSetName = '' then
            begin
              propDataSetName := rType.GetProperty('DataSetName');
              if (propDataSetName <> nil) and
                 propDataSetName.IsReadable and
                 (propDataSetName.PropertyType.TypeKind in
                    [tkString, tkLString, tkWString, tkUString]) then
                sDataSetName := propDataSetName.GetValue(obj).AsString;
            end;
            if (sDataSetName <> '') and
               Map.TryGetValue(sDataSetName, newDs) then
              prop.SetValue(obj, newDs);
          end;
        end;
      end;
    finally
      ctx.Free;
      FreeAndNil(Map);
    end;
  end;
end;

procedure AjustarFormatoHorizontalTallas(AInforme: TfrxReport);
const
  ALTO_FILA_TOTALES = 26.45671;
  TOP_FILA_TOTALES = 3.77953;
var
  iTalla: Integer;
  mCampo: TfrxMemoView;
  mImporte: TfrxMemoView;
  oTalla: TfrxComponent;
  mTalla: TfrxMemoView;
  mTotalesFiscales: TfrxMemoView;
  mUnidades: TfrxMemoView;
  oImporte: TfrxComponent;
  oResumen: TfrxComponent;
  oTotalesFiscales: TfrxComponent;
  oUnidades: TfrxComponent;

  procedure AjustarCampoLinea(const ANombre: string;
    AAlturaFuente: Integer);
  var
    oCampo: TfrxComponent;
  begin
    oCampo := AInforme.FindObject(ANombre);
    if oCampo is TfrxMemoView then
    begin
      mCampo := TfrxMemoView(oCampo);
      mCampo.Font.Height := AAlturaFuente;
      mCampo.WordWrap := False;
      mCampo.Clipped := True;
    end;
  end;

  procedure AmpliarColumnaModelo(const ANombreModelo,
    ANombreDescripcion: string);
  const
    ANCHO_MODELO_PRIORITARIO = 80;
    ANCHO_MINIMO_DESCRIPCION = 100;
  var
    mDescripcion: TfrxMemoView;
    mModelo: TfrxMemoView;
    oDescripcion: TfrxComponent;
    oModelo: TfrxComponent;
    rAumento: Extended;
  begin
    oModelo := AInforme.FindObject(ANombreModelo);
    oDescripcion := AInforme.FindObject(ANombreDescripcion);
    if (oModelo is TfrxMemoView) and
       (oDescripcion is TfrxMemoView) then
    begin
      mModelo := TfrxMemoView(oModelo);
      mDescripcion := TfrxMemoView(oDescripcion);
      if (mModelo.Width < ANCHO_MODELO_PRIORITARIO) and
         (mDescripcion.Width > ANCHO_MINIMO_DESCRIPCION) and
         (Abs(mDescripcion.Left -
          (mModelo.Left + mModelo.Width)) < 1) then
      begin
        rAumento := ANCHO_MODELO_PRIORITARIO - mModelo.Width;
        if rAumento >
           (mDescripcion.Width - ANCHO_MINIMO_DESCRIPCION) then
          rAumento := mDescripcion.Width - ANCHO_MINIMO_DESCRIPCION;
        mModelo.Width := mModelo.Width + rAumento;
        mDescripcion.Left := mDescripcion.Left + rAumento;
        mDescripcion.Width := mDescripcion.Width - rAumento;
      end;
    end;
  end;
begin
  // Las guias horizontales reservan solo 25,5 puntos por talla. Incluso con
  // la correccion anterior a -12, valores como XXL/XXXL podian recortarse.
  // Se fuerza una sola linea tambien en formatos personalizados de la BBDD.
  if Assigned(AInforme) then
  begin
    for iTalla := 1 to MAX_TALLAS_HORIZONTAL do
    begin
      oTalla := AInforme.FindObject(Format('GuiaT%.2d', [iTalla]));
      if oTalla is TfrxMemoView then
      begin
        mTalla := TfrxMemoView(oTalla);
        if mTalla.Width <= 30 then
        begin
          mTalla.Font.Height := -9;
          mTalla.WordWrap := False;
          mTalla.Clipped := True;
        end;
      end;
    end;

    // Se prioriza el modelo: gana espacio a la descripcion y conserva una
    // fuente mayor. Ningun campo puede invadir la fila siguiente.
    AmpliarColumnaModelo('HdrModelo', 'HdrDescr');
    AmpliarColumnaModelo('LinModelo', 'LinDescr');
    AjustarCampoLinea('LinModelo', -11);
    AjustarCampoLinea('LinDescr', -10);
    AjustarCampoLinea('LinColor', -10);

    // El total definitivo no es un pie de pagina: debe aparecer una sola vez,
    // despues de la ultima linea. Se mueve al resumen final incluso cuando el
    // formato procede de la BBDD; la numeracion permanece en PageFooter1.
    oResumen := AInforme.FindObject('ReportSummaryTotalesFiscales');
    oUnidades := AInforme.FindObject('MemoTotalUds');
    oImporte := AInforme.FindObject('MemoTotalImporte');
    oTotalesFiscales := AInforme.FindObject('MemoTotalesFiscales');
    if (oResumen is TfrxReportSummary) and
       (oUnidades is TfrxMemoView) and
       (oImporte is TfrxMemoView) then
    begin
      mUnidades := TfrxMemoView(oUnidades);
      mImporte := TfrxMemoView(oImporte);
      if (mUnidades.Parent <> oResumen) or
         (mImporte.Parent <> oResumen) then
      begin
        if (oTotalesFiscales is TfrxMemoView) and
           (oTotalesFiscales.Parent = oResumen) then
        begin
          mTotalesFiscales := TfrxMemoView(oTotalesFiscales);
          mTotalesFiscales.Top :=
            mTotalesFiscales.Top + ALTO_FILA_TOTALES;
        end;
        TfrxReportSummary(oResumen).Height :=
          TfrxReportSummary(oResumen).Height + ALTO_FILA_TOTALES;
        mUnidades.Parent := TfrxReportSummary(oResumen);
        mImporte.Parent := TfrxReportSummary(oResumen);
        mUnidades.Top := TOP_FILA_TOTALES;
        mImporte.Top := TOP_FILA_TOTALES;
      end;
    end;
  end;
end;

procedure TfrmPrint.AfterReportLoaded;
begin
  // Hook para descendientes: re-enlazar DataSets del informe.
  // Aqui ademas enganchamos el OnBeforePrint del Report para que en
  // cada iteracion FastReport refresque los TfrxPictureView llamados
  // foto300 / foto600 / fotoReal con la foto del registro activo de la
  // banda padre (necesario en etiquetas y otros informes iterativos) y
  // el llamado 'qrverifactu' con el QR tributario de la factura.
  frxrprt1.OnBeforePrint := ReportBeforePrintConQR;
  // FZ-ISSUE-235: las cantidades se formatean al preparar, cuando los
  // descendientes ya han enlazado sus datasets (lo hacen tras inherited).
  frxrprt1.OnBeginDoc := ReportInicioDocumento;
  AjustarFormatoHorizontalTallas(frxrprt1);
end;

procedure TfrmPrint.VistaPreviaCreada(Sender: TObject);
begin
  if frxrprt1.PreviewForm <> nil then
  begin
    AsociarVentanaPropietaria(frxrprt1.PreviewForm, Self);
    frxrprt1.PreviewForm.ScaleForPPI(CurrentPPI);
    AjustarFormularioAreaTrabajo(frxrprt1.PreviewForm, Self);
  end;
end;

procedure TfrmPrint.ReportInicioDocumento(Sender: TObject);
begin
  AjustarFormatoCantidadesInforme(frxrprt1, UnidadesMedida);
end;

procedure TfrmPrint.ReportBeforePrintConQR(Component: TfrxReportComponent);
begin
  FotosArticulos.HandlerReportBeforePrint(Component);
  // Objetos que SÍ reciben el evento (QR/título en una banda de datos)
  SustituirQRVerifactuEnReport(ParametrosApp, Component);
  SustituirTituloFacturaEnReport(Component);
  // Vía fiable: al disparar la banda (la cabecera de página recibe el
  // evento aunque sus objetos sueltos no), rellenamos QR y título de
  // sus hijos con la factura activa
  AplicarVerifactuEnBanda(ParametrosApp, Component);
end;

procedure TfrmPrint.AbrirGuiasRuntime(
  aSoloUsadasEnReport: Boolean);
var
  arrGuias: TArray<TInformeGuiaItem>;
  sFormatoBuscado: string;
  sError: string;
  iGuia: Integer;
  iDataSet: Integer;
  oDataSetInforme: TfrxDBDataset;
  oDataSet: TDataSet;
  oRestauracion: IRestauracionDatasetInforme;
begin
  if not Assigned(FRestauracionesGuias) then
  begin
    FRestauracionesGuias := TInterfaceList.Create;
  frxrprt1.OnPreview := VistaPreviaCreada;
  end;
  CerrarGuiasRuntime;
  if Assigned(InformesGuiasCache) and
     InformesGuiasCache.Cargada then
  begin
    if (sElegido = '') or
       SameText(sElegido, 'Predeterminado') then
    begin
      sFormatoBuscado := '';
    end
    else
    begin
      sFormatoBuscado := sElegido;
    end;
    arrGuias := InformesGuiasCache.Obtener(
      Self.Name,
      sFormatoBuscado);
    for iGuia := 0 to High(arrGuias) do
    begin
      oDataSetInforme := nil;
      for iDataSet := 0 to frxrprt1.Datasets.Count - 1 do
      begin
        if (frxrprt1.Datasets[iDataSet].DataSet is TfrxDBDataset) and
           SameText(
             frxrprt1.Datasets[iDataSet].DataSet.UserName,
             arrGuias[iGuia].DatasetMaster) then
        begin
          oDataSetInforme := TfrxDBDataset(
            frxrprt1.Datasets[iDataSet].DataSet);
        end;
      end;
      if not Assigned(oDataSetInforme) then
      begin
        RegistroLog.RegistrarAviso(
          Format(
            'Guia ignorada: master "%s" no esta en el report de %s',
            [arrGuias[iGuia].DatasetMaster, Self.Name]));
      end
      else
      begin
        oDataSet := oDataSetInforme.DataSet;
        if not Assigned(oDataSet) and
           Assigned(oDataSetInforme.DataSource) then
        begin
          oDataSet := oDataSetInforme.DataSource.DataSet;
        end;
        if oDataSet is TClientDataSet then
        begin
          oDataSet := RelacionarClientDataSetConQuery(oDataSet);
        end;
        oRestauracion := FServiciosPersistencia.Enriquecedor.Enriquecer(
          oDataSet,
          arrGuias[iGuia],
          sError);
        if Assigned(oRestauracion) then
        begin
          FRestauracionesGuias.Add(oRestauracion);
          oDataSetInforme.FieldAliases.Clear;
          if Assigned(oDataSetInforme.DataSource) then
          begin
            var oOrigen := oDataSetInforme.DataSource;
            oDataSetInforme.DataSource := nil;
            oDataSetInforme.DataSource := oOrigen;
          end
          else if Assigned(oDataSetInforme.DataSet) then
          begin
            var oOrigenDatos := oDataSetInforme.DataSet;
            oDataSetInforme.DataSet := nil;
            oDataSetInforme.DataSet := oOrigenDatos;
          end;
        end
        else
        begin
          RegistroLog.RegistrarAviso(
            Format(
              'Guia ignorada (%s -> %s): %s',
              [
                arrGuias[iGuia].DatasetMaster,
                arrGuias[iGuia].Tabla,
                sError
              ]));
        end;
      end;
    end;
  end;
end;

procedure TfrmPrint.CerrarGuiasRuntime;
var
  iRestauracion: Integer;
  oRestauracion: IRestauracionDatasetInforme;
begin
  if Assigned(FRestauracionesGuias) then
  begin
    for iRestauracion := FRestauracionesGuias.Count - 1 downto 0 do
    begin
      oRestauracion := IRestauracionDatasetInforme(
        FRestauracionesGuias[iRestauracion]);
      try
        oRestauracion.Restaurar;
      except
        on E: Exception do
        begin
          RegistroLog.RegistrarError(
            'Restaurar dataset del informe fallo: ' + E.Message);
        end;
      end;
    end;
    FRestauracionesGuias.Clear;
  end;
end;
procedure TfrmPrint.ConsolidarGuiasParaFormato(
  const aFormato: string);
var
  oMemoria: TMemoryStream;
  oTexto: TStringList;
begin
  if (aFormato <> '') and
     not SameText(aFormato, 'Predeterminado') then
  begin
    oMemoria := TMemoryStream.Create;
    oTexto := TStringList.Create;
    try
      frxrprt1.SaveToStream(oMemoria);
      oMemoria.Position := 0;
      oTexto.LoadFromStream(oMemoria);
      FServiciosPersistencia.Guias.Consolidar(
        Self.Name,
        aFormato,
        IdentidadSesion.Usuario,
        oTexto.Text);
    finally
      FreeAndNil(oTexto);
      FreeAndNil(oMemoria);
    end;
    if Assigned(InformesGuiasCache) then
    begin
      InformesGuiasCache.Precargar;
    end;
  end;
end;
procedure TfrmPrint.EditarGuiasParaFormato(const aFormato: string;
                                            aReport: TfrxReport = nil);
var
  oForm: TfrmModalInformesGuias;
begin
  oForm := TfrmModalInformesGuias.Create(
    Self,
    FiltrosGuias);
  try
    oForm.sInforme := Self.Name;
    // Si el formato es 'Predeterminado' tratamos al usuario como si
    // estuviera trabajando sobre el .frx base: las guias nuevas son
    // globales por defecto. Para cualquier otro formato se atan a el.
    if SameText(aFormato, 'Predeterminado') then
      oForm.sFormatoSugerido := ''
    else
      oForm.sFormatoSugerido := aFormato;
    oForm.FReport := aReport;
    oForm.ShowModal;
    // El usuario pudo dar de alta / modificar / borrar guias en el modal:
    // refrescamos el cache para que el proximo Imprimir / PDF lo vea.
    if Assigned(InformesGuiasCache) then
      InformesGuiasCache.Precargar;
  finally
    FreeAndNil(oForm);
  end;
end;

procedure TfrmPrint.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnSalirClick(Sender);
end;

procedure TfrmPrint.AvisarAntesDeConsulta;
begin
  // Los listados sin referencias de documentos no necesitan avisos.
end;

procedure TfrmPrint.PrepararDatosEdicion;
begin
  // Los descendientes con documentos seleccionados preparan sus datos.
end;

function TfrmPrint.HayDatasetInformeSinConectar: Boolean;
var
  i: Integer;
  oDatos: TfrxDataSet;
begin
  Result := False;
  i := 0;
  while (not Result) and (i < frxrprt1.DataSets.Count) do
  begin
    oDatos := frxrprt1.DataSets[i].DataSet;
    // Con DataSource, .DataSet es nil: hay que mirar GetDataSet.
    Result := (oDatos is TfrxDBDataset) and
      (TfrxDBDataset(oDatos).GetDataSet = nil);
    Inc(i);
  end;
end;

procedure TfrmPrint.ConectarDatasetsParaEdicion;
begin
  // FZ-ISSUE-096: algunos informes (p. ej. Depositos) solo enlazan su
  // TfrxDBDataset en Preparar_consulta. Sin imprimir antes, el
  // asistente no veia campos y PrepareReport fallaba con "DataSet no
  // conectado". Solo se consulta si de verdad falta algun enlace: los
  // listados con consultas de diseno no cambian de comportamiento.
  if HayDatasetInformeSinConectar then
  begin
    AvisarAntesDeConsulta;
    IniciarEspera(SCaptionEsperaConsultandoDatosInforme);
    try
      PrepararConsultaInforme;
    finally
      OcultarEspera;
    end;
  end;
end;

procedure TfrmPrint.btnEditarClick(Sender: TObject);
var
  oWiz: TfrmModalWizardEditar;
  memStream: TMemoryStream;
  bAceptado: Boolean;
  iRespuesta: Integer;
begin
  inherited;
  PrepararDatosEdicion;
  ConectarDatasetsParaEdicion;
  Self.Hide;

  // AfterReportLoaded re-enlaza los datasets del informe via
  // RebindReportDataSetsByDataModule. Lo necesitamos en ambas ramas
  // (wizard y clasico) para que los TfrxDBDataset esten visibles.
  AfterReportLoaded;

  // Preguntamos al usuario si quiere entrar al wizard para añadir o
  // editar campos extra (guias) de tablas / vistas externas. Si dice
  // que no, vamos directos al flujo clasico de edicion (Consultar_
  // Formularios + DesignReport). Cancelar sale sin abrir el diseñador.
  iRespuesta := MessageDlg_fza(
    SPreguntaEditarCamposExtraInforme,
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if iRespuesta <> mrCancel then
  begin
  bAceptado := False;

  if iRespuesta = mrYes then
  begin
    // Flujo wizard: 1) elegir/crear formato + permiso, 2) configurar
    // guias. Al finalizar, sFormato y sScope quedan fijados y el
    // guardado posterior del .frx no vuelve a preguntar el nombre.
    oWiz := TfrmModalWizardEditar.Create(Self);
    try
      oWiz.sInforme := Self.Name;
      oWiz.FReport  := frxrprt1;
      oWiz.ShowModal;
      // El wizard puede haber dado de alta / editado guias: refresco cache.
      if Assigned(InformesGuiasCache) then
        InformesGuiasCache.Precargar;
      if oWiz.sFicha = 'S' then
      begin
        sElegido           := oWiz.sFormato;
        FScopePerfilFijado := oWiz.sScope;
        FFormatoFijado     := True;
        bAceptado          := True;

        // Cargar el .frx del formato elegido. Si existe lo cargamos
        // del BLOB (query lazy en LeerBlobFormato); si no existe o el
        // BLOB esta vacio partimos del .frx base.
        if oWiz.bExiste then
        begin
          memStream := TMemoryStream.Create;
          try
            if LeerBlobFormato(sElegido, memStream) then
            begin
              frxrprt1.LoadFromStream(memStream);
              FInformeEsPersonalizado := True;
            end
            else
            begin
              frxrprt1.AssignAll(frxReportOrigen);
              FInformeEsPersonalizado := False;
            end;
            FInformeTraducido := False;
          finally
            FreeAndNil(memStream);
          end;
        end
        else
        begin
          frxrprt1.AssignAll(frxReportOrigen);
          FInformeEsPersonalizado := False;
          FInformeTraducido := False;
        end;

        // Re-enlazar datasets despues de cargar/asignar el report.
        AfterReportLoaded;
      end;
    finally
      FreeAndNil(oWiz);
    end;
  end
  else  // iRespuesta = mrNo
  begin
    // Flujo clasico: elegir un formato existente (o usar el original)
    // y abrir el diseñador. Las guias ya configuradas se aplican
    // igualmente; lo unico que NO se hace es entrar al wizard de
    // creacion/edicion de guias. Al guardar el .frx el modal de
    // "Guardar Objeto Editado" sale como siempre.
    Consultar_Formularios(True);
    bAceptado := sElegido <> '';
    // LoadFromStream sustituye los datasets del informe por los que trae
    // el formato; un formato sin lista <Datasets> (p. ej. generado por
    // código) se quedaría sin 'Facturas' y fallaría al preparar.
    if bAceptado then
      AfterReportLoaded;
  end;

  if bAceptado then
  begin
    // Abrimos las guias activas del informe / formato (asi el usuario
    // las ve en el arbol de datasets del diseñador y los campos extra
    // estan disponibles para arrastrar al .frx).
    AbrirGuiasRuntime(False);
    // Los informes basados en TClientDataSet deben copiar de nuevo los
    // campos añadidos a la consulta física antes de abrir el diseñador.
    OnGuiasAplicadas;
    try
      ReenlazarDatasetsInforme;
      frxrprt1.PrepareReport(True);
      frxrprt1.DesignReport();
    finally
      CerrarGuiasRuntime;
      FFormatoFijado := False;
    end;
  end;
  end;
  Self.Show;
end;

procedure TfrmPrint.btnExcelClick(Sender: TObject);
begin
  inherited;
  try
    if PrepararInformeConEspera(False) then
    begin
      frxlsxprtExcel.DefaultPath := ParametrosApp.GetPath('appDirExcel');
      if Trim(frxlsxprtExcel.FileName) = '' then
        frxlsxprtExcel.FileName := NombreExportacionPorDefecto('.xlsx');
      frxrprt1.Export(frxlsxprtExcel);
    end;
  finally
    QuitarResumenSeleccionesInforme(frxrprt1);
    CerrarGuiasRuntime;
    TerminarEspera;
    Self.Show;
  end;
end;

procedure TfrmPrint.AplicarImpresoraDocumentos;
var
  sImpresora: string;
  sResuelta: string;
begin
  sImpresora := ImpresoraDocumentosConfigurada(ParametrosApp);
  if (sImpresora <> '') and (not SameText(sImpresora, 'DEBUG')) then
  begin
    // FZ-ISSUE-099: mientras la detección diferida no ha resuelto el
    // patrón, se resuelve aquí contra la lista de FastReport.
    sResuelta := BuscarImpresoraEnLista(sImpresora, frxPrinters.Printers);
    if sResuelta <> '' then
      frxrprt1.PrintOptions.Printer := sResuelta
    else if not FAvisoImpresoraRegistrado then
    begin
      FAvisoImpresoraRegistrado := True;
      RegistroLog.RegistrarAviso(
        Format('Impresora de informes "%s" (%s) no encontrada en %s; ' +
               'se propone la predeterminada.',
               [sImpresora, cParametroImpresoraDocumentos, Self.Name]));
    end;
  end;
end;

function TfrmPrint.RectanguloReferenciaEspera: TRect;
begin
  if Self.Visible then
    Result := Self.BoundsRect
  else if Assigned(Application.MainForm) then
    Result := Application.MainForm.BoundsRect
  else
    Result := Screen.WorkAreaRect;
end;

procedure TfrmPrint.IniciarEspera(const AFase: string);
begin
  if not Assigned(FVentanaEspera) then
    // Se vigila la ventana principal, no este modal: el modal se
    // oculta a proposito mientras se prepara el informe.
    FVentanaEspera := CrearVentanaEspera(
      RectanguloReferenciaEspera, Self.CurrentPPI,
      Application.MainFormHandle);
  FVentanaEspera.Mostrar(AFase);
end;

procedure TfrmPrint.ActualizarDetalleEspera(const ADetalle: string);
begin
  if Assigned(FVentanaEspera) then
    FVentanaEspera.ActualizarDetalle(ADetalle);
end;

procedure TfrmPrint.OcultarEspera;
begin
  if Assigned(FVentanaEspera) then
    FVentanaEspera.Ocultar;
end;

procedure TfrmPrint.TerminarEspera;
begin
  OcultarEspera;
  FVentanaEspera := nil;
end;

function TfrmPrint.EsperaCancelada: Boolean;
begin
  Result := Assigned(FVentanaEspera) and FVentanaEspera.Cancelado;
end;

function TfrmPrint.DetalleProgresoInforme: string;
begin
  Result := Format(SCaptionEsperaPaginaInforme, [FPaginaInforme]);
end;

procedure TfrmPrint.InformeProgreso(
  Sender: TfrxReport;
  ProgressType: TfrxProgressType;
  Progress: Integer);
begin
  if ProgressType = ptRunning then
  begin
    if Progress > 0 then
      FPaginaInforme := Progress;
    ActualizarDetalleEspera(DetalleProgresoInforme);
    if EsperaCancelada then
      Sender.Terminated := True;
  end;
end;

function TfrmPrint.PrepararPaginasInforme: Boolean;
begin
  FPaginaInforme := 1;
  frxrprt1.OnProgress := InformeProgreso;
  if Assigned(FVentanaEspera) then
    FVentanaEspera.PermitirCancelar(True);
  try
    ReenlazarDatasetsInforme;
    Result := frxrprt1.PrepareReport(True) and (not EsperaCancelada);
  finally
    frxrprt1.OnProgress := nil;
    if Assigned(FVentanaEspera) then
      FVentanaEspera.PermitirCancelar(False);
  end;
end;

function TfrmPrint.PrepararInformeConEspera(
  AAplicarImpresora: Boolean): Boolean;
begin
  Result := False;
  AvisarAntesDeConsulta;
  IniciarMedicionDatos;
  IniciarEspera(SCaptionEsperaConsultandoDatosInforme);
  try
    PrepararConsultaInforme;
  finally
    OcultarEspera;
  end;
  // El diálogo de formato no cuenta como tiempo de obtención de datos.
  PausarMedicionDatos;
  Self.Hide;
  Consultar_Formularios;
  if sElegido <> '' then
  begin
    IniciarEspera(SCaptionEsperaPreparandoInforme);
    try
      ReanudarMedicionDatos;
      AfterReportLoaded;
      AbrirGuiasRuntime(True);
      OnGuiasAplicadas;
      PausarMedicionDatos;
      TraducirInformeActual;
      InsertarResumenSelecciones;
      if AAplicarImpresora then
        AplicarImpresoraDocumentos;
      Result := PrepararPaginasInforme;
    finally
      OcultarEspera;
    end;
  end;
end;

procedure TfrmPrint.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  // Sin selecciones por defecto.
end;

procedure TfrmPrint.IniciarMedicionDatos;
begin
  FMomentoSolicitudInforme := Now;
  FDuracionDatosInforme := 0;
  FCronometroDatos := TStopwatch.StartNew;
end;

procedure TfrmPrint.PausarMedicionDatos;
begin
  FCronometroDatos.Stop;
  FDuracionDatosInforme := FCronometroDatos.ElapsedMilliseconds;
end;

procedure TfrmPrint.ReanudarMedicionDatos;
begin
  FCronometroDatos.Start;
end;

function TfrmPrint.LineasResumenSelecciones: TArray<string>;
var
  oResumen: TResumenSeleccionesInforme;
begin
  oResumen := TResumenSeleccionesInforme.Create;
  try
    DescribirSelecciones(oResumen);
    if oResumen.EstaVacio then
      SetLength(Result, 0)
    else
      Result := [Trim(SResumenSeleccionesPrefijo)] + oResumen.Elementos +
        [TextoEmisionInforme(
          FMomentoSolicitudInforme,
          IdentidadSesion.Usuario,
          FDuracionDatosInforme)];
  finally
    FreeAndNil(oResumen);
  end;
end;

procedure TfrmPrint.InsertarResumenSelecciones;
var
  oResumen: TResumenSeleccionesInforme;
begin
  oResumen := TResumenSeleccionesInforme.Create;
  try
    DescribirSelecciones(oResumen);
    if oResumen.EstaVacio then
      QuitarResumenSeleccionesInforme(frxrprt1)
    else
      InsertarResumenSeleccionesInforme(
        frxrprt1,
        oResumen.Texto + sLineBreak +
        TextoEmisionInforme(
          FMomentoSolicitudInforme,
          IdentidadSesion.Usuario,
          FDuracionDatosInforme));
  finally
    FreeAndNil(oResumen);
  end;
end;

function TfrmPrint.NombreExportacionPorDefecto(
  const AExtension: string): string;
const
  cVerbosTitulo: array[0..2] of string = ('Imprimir ', 'Imprimeix ',
    'Print ');
  cCaracteresNoValidos = '\/:*?"<>|';
var
  i: Integer;
  sBase: string;
begin
  sBase := Trim(Caption);
  for i := Low(cVerbosTitulo) to High(cVerbosTitulo) do
    if StartsText(cVerbosTitulo[i], sBase) then
      sBase := Trim(Copy(sBase, Length(cVerbosTitulo[i]) + 1, MaxInt));
  for i := 1 to Length(sBase) do
    if (Pos(sBase[i], cCaracteresNoValidos) > 0) or (sBase[i] < ' ') then
      sBase[i] := '-';
  if sBase = '' then
    sBase := Self.Name;
  Result := sBase + '_' + FormatDateTime('yyyymmdd', Date) + AExtension;
end;

procedure TfrmPrint.ExportarPdfInteractivo;
var
  sRutaPdf: string;
begin
  frxpdfxprtPedWeb.DefaultPath := ParametrosApp.GetPath('appDirPDF');
  if Trim(frxpdfxprtPedWeb.FileName) = '' then
    frxpdfxprtPedWeb.FileName := NombreExportacionPorDefecto('.pdf');
  if frxrprt1.Export(frxpdfxprtPedWeb) then
  begin
    sRutaPdf := RutaPdfExportado(frxpdfxprtPedWeb);
    if sRutaPdf <> '' then
      PdfExportado(sRutaPdf);
  end;
end;

procedure TfrmPrint.btnImprimirClick(Sender: TObject);
begin
  FUltimaImpresionCorrecta := False;
  try
    if PrepararInformeConEspera(True) then
      FUltimaImpresionCorrecta := frxrprt1.Print;
  finally
    QuitarResumenSeleccionesInforme(frxrprt1);
    CerrarGuiasRuntime;
    TerminarEspera;
    Self.Show;
  end;
end;

procedure TfrmPrint.btnSalirClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPrint.btnPDFClick(Sender: TObject);
begin
  FUltimaRutaPdf := '';
  try
    if PrepararInformeConEspera(False) then
      ExportarPdfInteractivo;
  finally
    QuitarResumenSeleccionesInforme(frxrprt1);
    CerrarGuiasRuntime;
    TerminarEspera;
    Self.Show;
  end;
end;

function TfrmPrint.ExportarPdfActual(const ARuta: string): Boolean;
begin
  Result := False;
  if (sElegido <> '') and (Trim(ARuta) <> '') then
  begin
    AvisarAntesDeConsulta;
    PrepararConsultaInforme;
    Result := ExportarPdfPreparado(ARuta);
  end;
end;

function TfrmPrint.ExportarPdfPreparado(
  const ARuta: string;
  ANotificarExportacion: Boolean): Boolean;
var
  bMostrarDialogo: Boolean;
  sDirectorioPrevio: string;
  sFicheroPrevio: string;
begin
  Result := False;
  if (sElegido <> '') and (Trim(ARuta) <> '') then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    OnGuiasAplicadas;
    TraducirInformeActual;
    bMostrarDialogo := frxpdfxprtPedWeb.ShowDialog;
    sDirectorioPrevio := frxpdfxprtPedWeb.DefaultPath;
    sFicheroPrevio := frxpdfxprtPedWeb.FileName;
    try
      ReenlazarDatasetsInforme;
      Result := frxrprt1.PrepareReport(True) and
                (frxrprt1.PreviewPages.Count > 0);
      if Result then
      begin
        frxpdfxprtPedWeb.ShowDialog := False;
        frxpdfxprtPedWeb.DefaultPath := ExtractFilePath(ARuta);
        frxpdfxprtPedWeb.FileName := ARuta;
        Result := frxrprt1.Export(frxpdfxprtPedWeb) and
                  FileExists(ARuta);
      end;
      if Result and ANotificarExportacion then
        PdfExportado(ARuta);
    finally
      frxpdfxprtPedWeb.ShowDialog := bMostrarDialogo;
      frxpdfxprtPedWeb.DefaultPath := sDirectorioPrevio;
      frxpdfxprtPedWeb.FileName := sFicheroPrevio;
      CerrarGuiasRuntime;
    end;
  end;
end;

function TfrmPrint.ImprimirPreparadoEn(
  const AImpresora: string): Boolean;
var
  bMostrarDialogo: Boolean;
  sImpresoraPrevia: string;
begin
  Result := False;
  if sElegido <> '' then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    OnGuiasAplicadas;
    TraducirInformeActual;
    bMostrarDialogo := frxrprt1.PrintOptions.ShowDialog;
    sImpresoraPrevia := frxrprt1.PrintOptions.Printer;
    try
      frxrprt1.PrintOptions.ShowDialog := False;
      if Trim(AImpresora) <> '' then
        frxrprt1.PrintOptions.Printer := Trim(AImpresora);
      ReenlazarDatasetsInforme;
      Result := frxrprt1.PrepareReport(True) and
                (frxrprt1.PreviewPages.Count > 0);
      if Result then
        Result := frxrprt1.Print;
    finally
      frxrprt1.PrintOptions.ShowDialog := bMostrarDialogo;
      frxrprt1.PrintOptions.Printer := sImpresoraPrevia;
      CerrarGuiasRuntime;
    end;
  end;
end;

function TfrmPrint.PrepararPaginasSinImprimir: Boolean;
begin
  Result := False;
  if sElegido <> '' then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    OnGuiasAplicadas;
    TraducirInformeActual;
    try
      ReenlazarDatasetsInforme;
      Result := frxrprt1.PrepareReport(True) and
                (frxrprt1.PreviewPages.Count > 0);
    finally
      CerrarGuiasRuntime;
    end;
  end;
end;

procedure TfrmPrint.PrepararConsultaInforme;
begin
  Preparar_consulta;
  ReenlazarDatasetsInforme;
end;

// FZ-ISSUE-344: TfrxDBDataset guarda el dataset de su DataSource al
// asignarselo y no se entera si despues cambia DataSource.DataSet. Las
// pantallas que en Preparar_consulta sustituyen el resultado (y liberan el
// anterior) dejaban a FastReport leyendo un dataset liberado en el
// OnBeginDoc: Access violation en TfrxDBDataset.IsAutoFieldDef /
// GetSourceFieldList, intermitente. Reasignar el DataSource lo refresca.
procedure TfrmPrint.ReenlazarDatasetsInforme;
var
  i: Integer;
  oDataSet: TfrxDBDataset;
  oOrigen: TDataSource;
begin
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TfrxDBDataset then
    begin
      oDataSet := TfrxDBDataset(Components[i]);
      oOrigen := oDataSet.DataSource;
      if oOrigen <> nil then
        oDataSet.DataSource := oOrigen;
    end;
end;

procedure TfrmPrint.btnVistaPreliminarClick(Sender: TObject);
begin
  try
    // Las páginas ya están preparadas con el progreso a la vista;
    // ShowReport las descartaría y volvería a construir el informe
    // dentro de la vista preliminar.
    if PrepararInformeConEspera(True) then
      frxrprt1.ShowPreparedReport;
  finally
    QuitarResumenSeleccionesInforme(frxrprt1);
    CerrarGuiasRuntime;
    TerminarEspera;
    Self.Show;
  end;
end;

procedure TfrmPrint.CargarFormatos(form:TfrmMtoModalGenImpEle);
var
  perfilDic: TProfileDicc;
  kvp: TPair<string, TDictValue>;
  arrFormatos: TFormatosImpresion;
  iFormato: Integer;
begin
  // Servimos la lista de formatos desde el cache precargado al login
  // (PrecargarPerfilesUsuario). Asi no se va a BBDD a refrescar; el BLOB
  // del .frx se carga lazy cuando el usuario elige un formato concreto.
  form.lstFormatos.Clear;
  if Assigned(PerfilesLectura) and
     PerfilesLectura.CargarPerfilFormulario(Self.Name, perfilDic) then
  try
    for kvp in perfilDic do
      if (FPrefijoFormatos = '') or
         StartsText(FPrefijoFormatos, kvp.Value.sValue) then
        form.lstFormatos.AddItem(kvp.Value.sValue, nil);
    if form.lstFormatos.Count > 0 then
      form.lstFormatos.ItemIndex := 0;
  finally
    FreeAndNil(perfilDic);
  end
  else
  begin
    arrFormatos := FServiciosPersistencia.Formatos.Listar(
      ContextoFormatos);
    for iFormato := 0 to High(arrFormatos) do
    begin
      if (FPrefijoFormatos = '') or
         StartsText(FPrefijoFormatos, arrFormatos[iFormato].Descripcion) then
        form.lstFormatos.AddItem(
          arrFormatos[iFormato].Descripcion,
          nil);
    end;
    if form.lstFormatos.Count > 0 then
    begin
      form.lstFormatos.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmPrint.PrepararSelectorFormato(
  ASelector: TfrmMtoModalGenImpEle;
  const AFormatoPredeterminado: string);
var
  Indice: Integer;
begin
  CargarFormatos(ASelector);
  // Al volver a elegir se confirma de nuevo si debe recordarse.
  ASelector.chkPredeterminado.Checked := False;
  if AFormatoPredeterminado <> '' then
  begin
    if AFormatoPredeterminado <> 'Predeterminado' then
    begin
      for Indice := 0 to ASelector.lstFormatos.Count - 1 do
      begin
        if ASelector.lstFormatos.Items[Indice] =
           AFormatoPredeterminado then
        begin
          ASelector.lstFormatos.ItemIndex := Indice;
          Break;
        end;
      end;
    end;
  end;
  if ASelector.lstFormatos.Count > 0 then
  begin
    if ASelector.ShowModal <> mrOk then
    begin
      // Cerrar el selector sin usar Original ni un formato guardado es una
      // cancelación. No debe conservar los valores iniciales del formulario.
      ASelector.sElegido := '';
      ASelector.sFicha := '';
      ASelector.bPredeterminado := False;
    end;
  end
  else
    ASelector.sFicha := 'O';
end;

procedure TfrmPrint.EliminarFormatoPredeterminado;
begin
  // La selección pertenece al usuario, no al propietario del formato.
  PerfilesEscritura.EliminarPerfil(
    IdentidadSesion.Usuario, Self.Name + '_formato_seleccionado');
end;

procedure TfrmPrint.GuardarFormatoPredeterminado(
  const AFormato: string);
begin
  // Subclave estable: cambiar de formato actualiza la misma preferencia.
  // El usuario en la subclave evita heredar elecciones de otros ámbitos.
  PerfilesEscritura.GrabarPerfil(
    IdentidadSesion.Usuario,
    Self.Name + '_formato_seleccionado',
    IdentidadSesion.Usuario,
    AFormato,
    AFormato);
end;

procedure TfrmPrint.ActualizarFormatoPredeterminado(
  ASelector: TfrmMtoModalGenImpEle;
  const AFormatoAnterior: string);
begin
  if (ASelector.sFicha = 'S') or (ASelector.sFicha = 'O') then
  begin
    if ASelector.bPredeterminado then
    begin
      if sElegido <> AFormatoAnterior then
        GuardarFormatoPredeterminado(sElegido);
    end
    else if AFormatoAnterior <> '' then
      EliminarFormatoPredeterminado;
  end;
end;

procedure TfrmPrint.SeleccionarFormato(
  const AFormatoPredeterminado: string;
  out AAccion: string);
var
  Selector: TfrmMtoModalGenImpEle;
begin
  Selector := TfrmMtoModalGenImpEle.Create(Self, Self);
  try
    PrepararSelectorFormato(Selector, AFormatoPredeterminado);
    sElegido := Selector.sElegido;
    AAccion := Selector.sFicha;
    ActualizarFormatoPredeterminado(
      Selector, AFormatoPredeterminado);
  finally
    FreeAndNil(Selector);
  end;
end;

function TfrmPrint.CargarFormatoGuardado(
  const AFormato: string): Boolean;
var
  Flujo: TMemoryStream;
begin
  Result := False;
  Flujo := TMemoryStream.Create;
  try
    if LeerBlobFormato(AFormato, Flujo) then
    begin
      frxrprt1.LoadFromStream(Flujo);
      FInformeEsPersonalizado := True;
      FInformeTraducido := False;
      Result := True;
    end;
  finally
    FreeAndNil(Flujo);
  end;
end;

procedure TfrmPrint.CargarFormatoElegido(const AAccion: string);
begin
  if AAccion = 'S' then
  begin
    if not CargarFormatoGuardado(sElegido) then
    begin
      frxrprt1.AssignAll(frxReportOrigen);
      FInformeEsPersonalizado := False;
      FInformeTraducido := False;
    end;
  end
  else if AAccion = 'O' then
  begin
    frxrprt1.AssignAll(frxReportOrigen);
    FInformeEsPersonalizado := False;
    FInformeTraducido := False;
  end;
end;

function TfrmPrint.SeleccionarFormatoSinDialogo(
  const AFormato: string): Boolean;
var
  sFormato: string;
begin
  Result := False;
  sElegido := '';
  sFormato := Trim(AFormato);
  if SameText(sFormato, 'Predeterminado') then
  begin
    sElegido := 'Predeterminado';
    CargarFormatoElegido('O');
    Result := True;
  end
  else if sFormato <> '' then
  begin
    sElegido := sFormato;
    Result := CargarFormatoGuardado(sFormato);
    if not Result then
      sElegido := '';
  end;
end;

procedure TfrmPrint.Consultar_Formularios(bForzarSeleccion: Boolean = False);
var
  sFichaAccion: string;
  sFormatoGuardado: string;
  bSeleccionAutomatica: Boolean;
begin
  sElegido := '';
  sFichaAccion := '';
  sFormatoGuardado := PerfilesLectura.ObtenerValorPerfil(
    Self.Name + '_formato_seleccionado', IdentidadSesion.Usuario, '');
  bSeleccionAutomatica := False;
  if (not bForzarSeleccion) and (sFormatoGuardado <> '') then
    bSeleccionAutomatica := SeleccionarFormatoSinDialogo(sFormatoGuardado);
  if not bSeleccionAutomatica then
  begin
    // Editar fuerza el selector; un formato retirado también permite elegir.
    SeleccionarFormato(sFormatoGuardado, sFichaAccion);
    CargarFormatoElegido(sFichaAccion);
  end;
end;

procedure TfrmPrint.DeleteForm(
  sElegido: String;
  form: TfrmMtoModalGenImpEle);
var
  sPropietario: string;
  iBotonSeleccionado: Integer;
begin
  sPropietario := FServiciosPersistencia.Formatos.ObtenerPropietario(
    Self.Name,
    sElegido);
  if not (
    (IdentidadSesion.GrupoRaiz = 'S') or
    (IdentidadSesion.Usuario = sPropietario) or
    (IdentidadSesion.Grupo = sPropietario)
  ) then
  begin
    ShowMessageFmt_fza(
      SErrorPrivilegiosBorrarFormato,
      [sPropietario]);
  end
  else
  begin
    iBotonSeleccionado := MessageDlg_fza(
      SPreguntaBorrarFormato,
      mtCustom,
      [mbYes, mbNo],
      0);
    if iBotonSeleccionado = mrYes then
    begin
      FServiciosPersistencia.Formatos.Eliminar(
        Self.Name,
        sElegido);
      if Assigned(CachePerfiles) then
      begin
        CachePerfiles.ResincronizarPerfilFormulario(Self.Name);
      end;
    end;
    CargarFormatos(form);
  end;
end;
procedure TfrmPrint.EliminarFormatoImpresion(
  const ANombre: string;
  ASelector: TObject);
begin
  if ASelector is TfrmMtoModalGenImpEle then
    DeleteForm(ANombre, TfrmMtoModalGenImpEle(ASelector));
end;

procedure TfrmPrint.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
  CerrarGuiasRuntime;
  FreeAndNil(FRestauracionesGuias);
end;

function TfrmPrint.ContextoFormatos: TContextoFormatosImpresion;
begin
  Result.Informe := Self.Name;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.Grupo := IdentidadSesion.Grupo;
  Result.Todos := oAll;
end;

function TfrmPrint.LeerBlobFormato(
  const aDescripcion: string;
  aStream: TStream
): Boolean;
begin
  Result := FServiciosPersistencia.Formatos.Leer(
    ContextoFormatos,
    aDescripcion,
    aStream);
end;

procedure TfrmPrint.GuardarBlobFormato(
  const aUsuario, aSubKey, aDescripcion: string;
  aStream: TStream;
  aInsertar: Boolean);
var
  Solicitud: TSolicitudGuardarFormato;
begin
  Solicitud.Contexto := ContextoFormatos;
  Solicitud.UsuarioGrupo := aUsuario;
  Solicitud.Subclave := aSubKey;
  Solicitud.Descripcion := aDescripcion;
  Solicitud.Insertar := aInsertar;
  FServiciosPersistencia.Formatos.Guardar(
    Solicitud,
    aStream);
end;
procedure TfrmPrint.TraducirInformeActual;
begin
  if not FInformeTraducido then
  begin
    if TraducirContenidoInforme then
    begin
      TraducirInformeFastReport(
        frxrprt1,
        Self,
        Traducciones,
        FInformeEsPersonalizado);
    end;
    FInformeTraducido := True;
  end;
end;

function TfrmPrint.TraducirContenidoInforme: Boolean;
begin
  Result := True;
end;

procedure TfrmPrint.FormCreate(Sender: TObject);
var
  oContexto: TContextoImpresionVentasPantalla;
begin
  inherited;
  if Width > Screen.WorkAreaWidth then
    Width := Screen.WorkAreaWidth;
  if Height > Screen.WorkAreaHeight then
    Height := Screen.WorkAreaHeight;
  pnl1.Visible := True;
  pnl1.Align := alRight;
  pnl1.BringToFront;
  Self.Position := poScreenCenter;
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FServiciosPersistencia := oContexto.Persistencia;
  FRestauracionesGuias := TInterfaceList.Create;
  frxrprt1.OnPreview := VistaPreviaCreada;
end;

function TfrmPrint.frxdsgnr1SaveReport(Report: TfrxReport;
  SaveAs: Boolean): Boolean;
begin
  // El fichero es una copia: el formato de la base de datos sigue sin
  // guardar, así que el diseñador no lo da por grabado.
  if SaveAs then
  begin
    GuardarFormatoEnFichero(Report);
    Result := False;
  end
  else
    Result := GuardarFormatoEnBaseDatos(Report);
end;

procedure TfrmPrint.GuardarFormatoEnFichero(AReport: TfrxReport);
var
  oDialogo: TSaveDialog;
begin
  oDialogo := TSaveDialog.Create(nil);
  try
    oDialogo.Title := STituloGuardarInformeFichero;
    oDialogo.Filter := SFiltroArchivoInformeFr3;
    oDialogo.DefaultExt := 'fr3';
    oDialogo.Options := oDialogo.Options + [ofOverwritePrompt,
      ofPathMustExist];
    oDialogo.FileName := NombreExportacionPorDefecto('.fr3');
    if oDialogo.Execute then
      AReport.SaveToFile(oDialogo.FileName);
  finally
    FreeAndNil(oDialogo);
  end;
end;

function TfrmPrint.GuardarFormatoEnBaseDatos(AReport: TfrxReport): Boolean;
var
  memStream:TMemoryStream;
  formulario: TfrmModalGenImpSave;
  bGuardar, bExiste : Boolean;
  sDescripcion, sPermisos : string;
begin
  Result := False;
  bGuardar := False;
  if FFormatoFijado then
  begin
    // El nombre y permiso del formato ya estan decididos por el wizard
    // de btnEditarClick — no volvemos a preguntar al usuario.
    bGuardar     := True;
    sDescripcion := sElegido;
    sPermisos    := FScopePerfilFijado;
    if sPermisos = '' then sPermisos := IdentidadSesion.Usuario;
  end
  else
  begin
    formulario := TfrmModalGenImpSave.Create(Application);
    try
      formulario.edtNombreOrigen.Text := Self.Name;
      formulario.edtDescripcion.Text := sElegido;
      formulario.ShowModal;
      if (formulario.sFicha = 'S') then
      begin
        bGuardar := True;
        sDescripcion := formulario.edtDescripcion.Text;
        sPermisos := formulario.cbbPermisos.Text;
      end;
    finally
      FreeAndNil(formulario);
    end;
  end;
  // Editando una familia de formatos (p. ej. tickets): el nombre guardado
  // conserva el prefijo para que siga apareciendo en su selector.
  if bGuardar and (FPrefijoFormatos <> '') and
     not StartsText(FPrefijoFormatos, Trim(sDescripcion)) then
    sDescripcion := FPrefijoFormatos + ' ' + Trim(sDescripcion);
  if bGuardar then
  begin
    memStream:=TMemoryStream.Create;
    try
      AReport.SaveToStream(memStream);
      memStream.Position:=0;
      bExiste := FServiciosPersistencia.Formatos.Existe(
        ContextoFormatos,
        sDescripcion);
      // Si FFormatoFijado=True el wizard ya advirtio al usuario y vamos
      // directos al UPDATE. En modo normal preguntamos confirmacion antes
      // de sobreescribir un formato existente.
      if bExiste and (not FFormatoFijado) then
      begin
        if MessageBox_fza(PChar(SPreguntaReemplazarInforme),
                                  PChar(STituloAdvertenciaInforme),
                                  MB_YESNO) <> ID_YES then
          bGuardar := False;
      end;
      if (bGuardar) then
      begin
        // El repositorio decide entre alta y actualización.
        GuardarBlobFormato(sPermisos,
                           frxrprt1.Name + '_' + sDescripcion,
                           sDescripcion,
                           memStream,
                           not bExiste);
        // Refrescamos el cache de perfiles del form (lo usa CargarFormatos)
        // para que la lista de formatos refleje el alta inmediatamente.
        if Assigned(CachePerfiles) then
          CachePerfiles.ResincronizarPerfilFormulario(Self.Name);
        // Atar las guias referenciadas por este .frx al formato recien
        // guardado: clona en fza_informes_guias las que existian como
        // globales para que el formato quede autocontenido.
        try
          ConsolidarGuiasParaFormato(sDescripcion);
        except
          on E: Exception do
            RegistroLog.RegistrarError(
              Format('Consolidacion de guias fallo para %s/%s: %s',
                     [Self.Name, sDescripcion, E.Message]));
        end;
        Result := True;
      end
      else
        Result := False;
    finally
      FreeAndNil(memStream);
    end;
  end;
end;
end.

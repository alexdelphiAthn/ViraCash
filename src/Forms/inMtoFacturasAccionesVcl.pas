{******************************************************************************}
{                                                                              }
{  Acciones modales de impresion, rectificacion y sustitucion de facturas.     }
{                                                                              }
{******************************************************************************}
unit inMtoFacturasAccionesVcl;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibComandoImprimirFacturas, inLibConexionesIntf,
  inLibContextoSesionIntf, inLibParametrosIntf, inLibPermisosIntf,
  inLibLogIntf, inLibFacturasRectificativaIntf, UniDataFacturas;

type
  TGuardarPendienteFacturaVcl = reference to procedure;
//  TObtenerFacturasFiltradasVcl = reference to function:
//    TReferenciasComandoFactura;
  TObtenerFacturasFiltradasVcl = TObtenerReferenciasComandoFactura;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
procedure ImprimirFacturaVcl(
  AOwnerSesion: TComponent;
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl;
  const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas;
  const AServicio: IServicioRectificativaFactura);
procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMensajesVcl,
  System.IOUtils, System.SysUtils, System.UITypes,
  Vcl.Forms, Vcl.Dialogs,
  inLibBuscarImpresora, inLibCorreoTickets,
  inLibFacturas, inLibVerifactu, inLibVerifactuTipos,
  inLibMsgFacturas, inMtoComandoImprimirFacturas,
  inMtoModalFacRec, inMtoModalImpFac, inMtoModalFacturarTicket;

resourcestring
  STituloSeleccionarCarpetaFacturas = 'Seleccione una carpeta';
  SResumenCorreosLoteFacturas =
    'Emails enviados: %d. Sin email: %d. Errores de envío: %d.';
  SInfoEmailNoSolicitadoLoteFacturas = 'Email solicitado: No';
  SInfoEmailSolicitadoLoteFacturas = 'Email solicitado: Sí';
  SInfoEmailsEnviadosLoteFacturas = 'Emails enviados: %d';
  SInfoSinEmailClienteLoteFacturas = 'Sin EMAIL_CLIENTE_FAC: %d';
  SInfoErroresEnvioLoteFacturas = 'Errores de envío: %d';
  SInfoDetalleEnviosLoteFacturas = 'Detalle de envíos:';
  SErrorPrepararCarpetaTrabajoLoteFacturas =
    'No se puede preparar la carpeta "%s".';

type
  TCoordinadorImpresionFacturaVcl = class
  private
    FOwnerFormulario: TComponent;
    FOwnerLote: TComponent;
    FFacturas: TdmFacturas;
    FCabecera: TDataSet;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FParametros: IParametrosAplicacion;
    FPermisos: IPermisosAplicacion;
    FRegistroLog: IRegistroLog;
    FObtenerFiltradas: TObtenerFacturasFiltradasVcl;
    FFormulario: TfrmPrintFac;
    FEmailFactura: string;
    FEmailRespuesta: string;
    FNombreEmpresa: string;
    FReferencia: string;
    function EnviarPdf(
      const ARutaPdf, AEmail: string;
      out AMensaje: string): Boolean;
    function SeleccionarDirectorioPdf(var ADirectorio: string): Boolean;
    function ExportarLotePdf(
      const AReferencias: TReferenciasComandoFactura;
      const AFormato: string;
      AEnviarEmail: Boolean): Boolean;
    function ImprimirLote(
      const AReferencias: TReferenciasComandoFactura;
      const AFormato: string;
      AEnviarEmail: Boolean): Boolean;
  public
    constructor Create(
      AOwnerSesion: TComponent;
      AFacturas: TdmFacturas;
      ACabecera: TDataSet;
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametros: IParametrosAplicacion;
      const APermisos: IPermisosAplicacion;
      const ARegistroLog: IRegistroLog;
      const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
    procedure ConfigurarFormulario(
      AFormulario: TfrmPrintFac;
      APuedeUsarActual: Boolean);
  end;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
var
  sReferencia: string;
begin
  sReferencia := FormatearDocumento(
    FORMATO_DOCUMENTO_DEFECTO, ASerie, ANumero);
  try
    sReferencia := FormatearReferenciaFactura(
      AFacturas.unqryTablaG.Connection, ASerie, ANumero);
    TfrmPrintFac.ArchivarFacturaConsolidada(AFacturas, ASerie, ANumero);
  except
    on E: Exception do
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(
          'No se pudo archivar el PDF al consolidar ' +
          sReferencia + ': ' + E.Message);
  end;
end;

function TextoResumenCorreoLote(
  ACorreoSolicitado: Boolean;
  AEnviados, ASinDestinatario, AConError: Integer;
  const ADetalle: string): string;
begin
  if not ACorreoSolicitado then
    Result := SInfoEmailNoSolicitadoLoteFacturas + sLineBreak
  else
  begin
    Result :=
      SInfoEmailSolicitadoLoteFacturas + sLineBreak +
      Format(SInfoEmailsEnviadosLoteFacturas, [AEnviados]) + sLineBreak +
      Format(SInfoSinEmailClienteLoteFacturas, [ASinDestinatario]) +
      sLineBreak +
      Format(SInfoErroresEnvioLoteFacturas, [AConError]) + sLineBreak;
    if Trim(ADetalle) <> '' then
      Result := Result + sLineBreak +
        SInfoDetalleEnviosLoteFacturas + sLineBreak + ADetalle + sLineBreak;
  end;
end;

function TieneIncidenciasCorreoLote(
  ACorreoSolicitado: Boolean;
  ASinDestinatario, AConError: Integer): Boolean;
begin
  Result := ACorreoSolicitado and
    ((ASinDestinatario > 0) or (AConError > 0));
end;

function EnviarPdfFacturaVcl(
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AReferencia, ANombreEmpresa, AEmailRespuesta, AEmail,
    ARutaPdf: string;
  out AMensaje: string): Boolean;
var
  oRutas: TStringList;
begin
  oRutas := TStringList.Create;
  try
    oRutas.Add(ARutaPdf);
    Result := EnviarDocumentosPorCorreo(
      AParametros,
      tdcFactura,
      AReferencia,
      ANombreEmpresa,
      AEmail,
      AEmailRespuesta,
      oRutas,
      ARegistroLog,
      AMensaje);
  finally
    oRutas.Free;
  end;
end;

function GuardarTrabajoLotePdf(
  const ADirectorio, AFormato: string;
  const AResultado: TResultadoComandoImprimirFacturas;
  out ARuta, AError: string): Boolean;
var
  sContenido: string;
  sEstado: string;
begin
  Result := False;
  ARuta := '';
  AError := '';
  try
    if not System.SysUtils.DirectoryExists(ADirectorio) and
       not System.SysUtils.ForceDirectories(ADirectorio) then
      raise Exception.CreateFmt(
        SErrorPrepararCarpetaTrabajoLoteFacturas,
        [ADirectorio]);
    ARuta := TPath.Combine(ADirectorio, 'trabajo_lote.txt');
    if AResultado.EsError or TieneIncidenciasCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError) then
      sEstado := 'CON INCIDENCIAS'
    else
      sEstado := 'CORRECTO';
    sContenido :=
      'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
      'Proceso: generación de PDF de facturas filtradas' + sLineBreak +
      'Formato: ' + AFormato + sLineBreak +
      'Carpeta destino: ' + ADirectorio + sLineBreak +
      'Estado: ' + sEstado + sLineBreak +
      'Resultado: ' + AResultado.Mensaje + sLineBreak +
      TextoResumenCorreoLote(
        AResultado.CorreoSolicitado,
        AResultado.CorreosEnviados,
        AResultado.CorreosSinDestinatario,
        AResultado.CorreosConError,
        AResultado.DetalleCorreo);
    TFile.WriteAllText(ARuta, sContenido, TEncoding.UTF8);
    Result := True;
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
end;

function GuardarTrabajoLoteImpresion(
  const ADirectorio, AFormato, AImpresora: string;
  const AResultado: TResultadoLoteImpresionFacturas;
  out ARuta, AError: string): Boolean;
var
  sContenido: string;
  sEstado: string;
begin
  Result := False;
  ARuta := '';
  AError := '';
  try
    if not System.SysUtils.DirectoryExists(ADirectorio) and
       not System.SysUtils.ForceDirectories(ADirectorio) then
      raise Exception.CreateFmt(
        SErrorPrepararCarpetaTrabajoLoteFacturas,
        [ADirectorio]);
    ARuta := TPath.Combine(ADirectorio, 'trabajo_lote.txt');
    if (AResultado.Error <> '') or TieneIncidenciasCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError) then
      sEstado := 'CON INCIDENCIAS'
    else
      sEstado := 'CORRECTO';
    sContenido :=
      'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
      'Proceso: impresión de facturas filtradas' + sLineBreak +
      'Formato: ' + AFormato + sLineBreak +
      'Impresora: ' + AImpresora + sLineBreak +
      'Estado: ' + sEstado + sLineBreak +
      Format('Solicitadas: %d', [AResultado.Solicitadas]) + sLineBreak +
      Format('Impresas: %d', [AResultado.Impresas]) + sLineBreak +
      Format('Omitidas no consolidadas: %d',
        [AResultado.OmitidasNoConsolidadas]) + sLineBreak;
    if AResultado.Error <> '' then
      sContenido := sContenido +
        'Incidencia de impresión: ' + AResultado.Error + sLineBreak;
    sContenido := sContenido + TextoResumenCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosEnviados,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError,
      AResultado.DetalleCorreo);
    TFile.WriteAllText(ARuta, sContenido, TEncoding.UTF8);
    Result := True;
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure MostrarResultadoImpresionLote(
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AFormato, AImpresora: string;
  const AResultado: TResultadoLoteImpresionFacturas);
var
  sDirectorioTrabajo: string;
  sErrorTrabajo: string;
  sMensaje: string;
  sRutaTrabajo: string;
begin
  if AResultado.Error <> '' then
    sMensaje := Format(
      SErrorLoteImpresionFacturas,
      [AResultado.Impresas, AResultado.Solicitadas, AResultado.Error])
  else
    sMensaje := Format(
      SInfoLoteImpresionFacturas,
      [AResultado.Impresas, AResultado.OmitidasNoConsolidadas]);

  if AResultado.CorreoSolicitado then
  begin
    sMensaje := sMensaje + sLineBreak + sLineBreak +
      Format(
        SResumenCorreosLoteFacturas,
        [AResultado.CorreosEnviados,
         AResultado.CorreosSinDestinatario,
         AResultado.CorreosConError]);
    sDirectorioTrabajo := AParametros.GetPath('appDirPDF');
    if Trim(sDirectorioTrabajo) = '' then
      sDirectorioTrabajo := TPath.Combine(
        TPath.GetDocumentsPath,
        'ViraCash');
    if GuardarTrabajoLoteImpresion(
      sDirectorioTrabajo,
      AFormato,
      AImpresora,
      AResultado,
      sRutaTrabajo,
      sErrorTrabajo) then
      sMensaje := sMensaje + sLineBreak + sLineBreak +
        Format(SInfoTrabajoLoteGuardado, [sRutaTrabajo])
    else
    begin
      sMensaje := sMensaje + sLineBreak + sLineBreak +
        Format(SErrorGuardarTrabajoLote, [sErrorTrabajo]);
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(sMensaje);
    end;
  end;

  if (AResultado.Error <> '') or
     (AResultado.CorreosConError > 0) or
     (AResultado.CorreosSinDestinatario > 0) then
    MessageDlg_fza(sMensaje, mtError, [mbOK], 0)
  else
    MessageDlg_fza(sMensaje, mtInformation, [mbOK], 0);
end;

{ TCoordinadorImpresionFacturaVcl }

constructor TCoordinadorImpresionFacturaVcl.Create(
  AOwnerSesion: TComponent;
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
begin
  inherited Create;
  FOwnerFormulario := AOwnerSesion;
  if FOwnerFormulario = nil then
    FOwnerFormulario := Application;
  FOwnerLote := Application.MainForm;
  if FOwnerLote = nil then
    FOwnerLote := FOwnerFormulario;
  FFacturas := AFacturas;
  FCabecera := ACabecera;
  FConexiones := AConexiones;
  FContextoSesion := AContextoSesion;
  FParametros := AParametros;
  FPermisos := APermisos;
  FRegistroLog := ARegistroLog;
  FObtenerFiltradas := AObtenerFiltradas;
  FEmailFactura := Trim(
    FCabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString);
  FNombreEmpresa := Trim(
    FCabecera.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString);
  FEmailRespuesta := Trim(
    FCabecera.FieldByName('EMAIL_EMPRESA_FAC').AsString);
  FReferencia :=
    FormatearReferenciaFactura(FConexiones.ConexionPrincipal,
    FCabecera.FieldByName(fseriefac).AsString,
    FCabecera.FieldByName(fnrofac).AsString);
end;

procedure TCoordinadorImpresionFacturaVcl.ConfigurarFormulario(
  AFormulario: TfrmPrintFac;
  APuedeUsarActual: Boolean);
begin
  FFormulario := AFormulario;
  FFormulario.edtNroFac.Text := FCabecera.FindField(fnrofac).AsString;
  FFormulario.edtSerie.Text := FCabecera.FindField(fseriefac).AsString;
  FFormulario.ConfigurarDataModule(FFacturas);
  FFormulario.ConfigurarCorreo(
    FEmailFactura,
    function(
      const ARutaPdf, AEmail: string;
      out AMensaje: string): Boolean
    begin
      Result := EnviarPdf(ARutaPdf, AEmail, AMensaje);
    end);
  FFormulario.ConfigurarLote(
    APuedeUsarActual,
    FObtenerFiltradas,
    function(
      const AReferencias: TReferenciasComandoFactura;
      const AFormato: string;
      AEnviarEmail: Boolean): Boolean
    begin
      Result := ExportarLotePdf(AReferencias, AFormato, AEnviarEmail);
    end,
    function(
      const AReferencias: TReferenciasComandoFactura;
      const AFormato: string;
      AEnviarEmail: Boolean): Boolean
    begin
      Result := ImprimirLote(AReferencias, AFormato, AEnviarEmail);
    end);
end;

function TCoordinadorImpresionFacturaVcl.EnviarPdf(
  const ARutaPdf, AEmail: string;
  out AMensaje: string): Boolean;
begin
  Result := EnviarPdfFacturaVcl(
    FParametros,
    FRegistroLog,
    FReferencia,
    FNombreEmpresa,
    FEmailRespuesta,
    AEmail,
    ARutaPdf,
    AMensaje);
end;

function TCoordinadorImpresionFacturaVcl.SeleccionarDirectorioPdf(
  var ADirectorio: string): Boolean;
var
  oDialogo: TFileOpenDialog;
begin
  oDialogo := TFileOpenDialog.Create(nil);
  try
    oDialogo.Title := STituloSeleccionarCarpetaFacturas;
    oDialogo.Options :=
      [fdoPickFolders, fdoForceFileSystem, fdoPathMustExist];
    if DirectoryExists(ADirectorio) then
      oDialogo.DefaultFolder := ADirectorio;
    // El dialogo pertenece al modal de impresion: se ordena con el y
    // se minimiza con la aplicacion.
    Result := oDialogo.Execute(FFormulario.Handle);
    if Result then
      ADirectorio := oDialogo.FileName;
  finally
    oDialogo.Free;
  end;
end;

function TCoordinadorImpresionFacturaVcl.ExportarLotePdf(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato: string;
  AEnviarEmail: Boolean): Boolean;
var
  oResultado: TResultadoComandoImprimirFacturas;
  oTipoMensaje: TMsgDlgType;
  sDirectorio: string;
  sErrorTrabajo: string;
  sMensaje: string;
  sRutaTrabajo: string;
begin
  Result := False;
  sDirectorio := FParametros.GetPath('appDirPDF');
  if SeleccionarDirectorioPdf(sDirectorio) then
  begin
    Screen.Cursor := crHourGlass;
    try
      try
        oResultado := EjecutarComandoImprimirFacturas(
          TArray<string>.Create(
            '/imprimirfacturas',
            SerializarReferenciasComandoFacturas(AReferencias),
            AFormato,
            sDirectorio),
          FOwnerFormulario,
          FConexiones.ConexionPrincipal,
          FContextoSesion,
          FParametros,
          FPermisos,
          FRegistroLog,
          AEnviarEmail);
      except
        on E: Exception do
        begin
          oResultado := Default(TResultadoComandoImprimirFacturas);
          oResultado.CodigoSalida := 1;
          oResultado.EsError := True;
          oResultado.Mensaje := E.ClassName + ': ' + E.Message;
          oResultado.CorreoSolicitado := AEnviarEmail;
        end;
      end;
      sMensaje := oResultado.Mensaje;
      if oResultado.CorreoSolicitado then
        sMensaje := sMensaje + sLineBreak + sLineBreak +
          Format(
            SResumenCorreosLoteFacturas,
            [oResultado.CorreosEnviados,
             oResultado.CorreosSinDestinatario,
             oResultado.CorreosConError]);
      if GuardarTrabajoLotePdf(
        sDirectorio,
        AFormato,
        oResultado,
        sRutaTrabajo,
        sErrorTrabajo) then
        sMensaje := sMensaje + sLineBreak + sLineBreak +
          Format(SInfoTrabajoLoteGuardado, [sRutaTrabajo])
      else
      begin
        sMensaje := sMensaje + sLineBreak + sLineBreak +
          Format(SErrorGuardarTrabajoLote, [sErrorTrabajo]);
        oResultado.EsError := True;
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarError(sMensaje);
      end;
    finally
      Screen.Cursor := crDefault;
    end;

    if oResultado.EsError or
       (oResultado.CorreosConError > 0) or
       (oResultado.CorreosSinDestinatario > 0) then
      oTipoMensaje := mtError
    else
      oTipoMensaje := mtInformation;
    MessageDlg_fza(sMensaje, oTipoMensaje, [mbOK], 0);
    Result := True;
  end;
end;

function TCoordinadorImpresionFacturaVcl.ImprimirLote(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato: string;
  AEnviarEmail: Boolean): Boolean;
var
  oParametros: IParametrosAplicacion;
  oRegistroLog: IRegistroLog;
  sFormato: string;
  sImpresora: string;
begin
  oParametros := FParametros;
  oRegistroLog := FRegistroLog;
  sFormato := AFormato;
  sImpresora := ImpresoraDocumentosConfigurada(FParametros);
  IniciarLoteImpresionFacturas(
    AReferencias,
    AFormato,
    sImpresora,
    FOwnerLote,
    FConexiones.ConexionPrincipal,
    FConexiones,
    FContextoSesion,
    FParametros,
    FPermisos,
    FRegistroLog,
    AEnviarEmail,
    procedure(const AResultado: TResultadoLoteImpresionFacturas)
    begin
      MostrarResultadoImpresionLote(
        oParametros,
        oRegistroLog,
        sFormato,
        sImpresora,
        AResultado);
    end);
  Result := True;
end;

procedure ImprimirFacturaVcl(
  AOwnerSesion: TComponent;
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl;
  const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
var
  oCoordinador: TCoordinadorImpresionFacturaVcl;
  oFormulario: TfrmPrintFac;
begin
  if not APuedeImprimir then
    Abort;
  if SinVerifactuActivo(AParametros) and
     Assigned(AGuardarPendiente) then
    AGuardarPendiente();
  // El borrador sin consolidar ya se puede ver e imprimir: mientras
  // no este emitido el informe se titula FACTURA PROFORMA, asi que el
  // papel no se puede confundir con una factura entregable.

  oCoordinador := TCoordinadorImpresionFacturaVcl.Create(
    AOwnerSesion,
    AFacturas,
    ACabecera,
    AConexiones,
    AContextoSesion,
    AParametros,
    APermisos,
    ARegistroLog,
    AObtenerFiltradas);
  try
    oFormulario := TfrmPrintFac.Create(oCoordinador.FOwnerFormulario);
    try
      oCoordinador.ConfigurarFormulario(oFormulario, True);
      oFormulario.ShowModal;
    finally
      oFormulario.Free;
    end;
  finally
    oCoordinador.Free;
  end;
end;

procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas;
  const AServicio: IServicioRectificativaFactura);
begin
  TfrmGenFacRec.Ejecutar(AOwner, AFacturas, AServicio);
end;

procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);
var
  Resultado: TFacturarTicketResult;
  Serie: string;
  Numero: string;
begin
  Serie := ACabecera.FieldByName('SERIE_FAC').AsString;
  Numero := ACabecera.FieldByName('NUMERO_FAC').AsString;
  if Trim(Numero) = '' then
    ShowMessage_fza(SErrorBorradorListaNoSeleccionado)
  else if not SameText(
    ACabecera.FieldByName('TIPO_FAC').AsString,
    'SIMPLIFICADA') then
    ShowMessage_fza(SErrorFacturarTicketRequiereSimplificado)
  else
  begin
    Resultado := TfrmModalFacturarTicket.Ejecutar(
      AOwner,
      Serie,
      Numero,
      ACabecera.FieldByName('CODIGO_EMP_FAC').AsString,
      ACabecera.FieldByName('CODIGO_ALM_FAC').AsString);
    if Resultado.Aceptado then
    begin
      ShowMessage_fza(FormatearMensajeDocumentos(
        Resultado.FormatoDocumento,
        SInfoBorradorSustitucionTicketCreado,
        [Resultado.SerieNueva, Resultado.NumeroNueva,
        Serie, Numero, ModoVerifactuTexto(AParametros)]));
      ACabecera.Refresh;
    end;
  end;
end;

end.

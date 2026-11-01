{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGarantiasResguardo                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resguardo de depósito de garantías en ticket o A4, con FastReport.       }
{******************************************************************************}
unit inLibGarantiasResguardo;

interface

uses
  frxClass, inLibPreviewTicket;

type
  TFormatoResguardoGarantia = (frgTicket, frgA4, frgEtiqueta);
  TDocumentoReparacion = (drRecepcion, drFabricante, drCliente, drAlbaran);
  TTrabajoResguardo = record
    Descripcion: string;
    Cantidad: Double;
    Importe: Currency;
    Terminado: Boolean;
  end;
  TResguardoGarantia = record
    Numero: Int64;
    Referencia: string;
    Fecha: TDateTime;
    Recepcion: TDateTime;
    Empresa: string;
    Nif: string;
    Tienda: string;
    DireccionTienda: string;
    PoblacionTienda: string;
    TelefonoTienda: string;
    Cliente: string;
    TelefonoCliente: string;
    Articulo: string;
    Descripcion: string;
    Modelo: string;
    Serie: string;
    Motivo: string;
    Observaciones: string;
    Medio: string;
    DocumentoVenta: string;
    FechaVenta: TDateTime;
    FinGarantia: TDateTime;
    EnGarantia: Boolean;
    // Reparaciones (30/10/2026); Modalidad '' = reclamación de garantía.
    Modalidad: string;
    Objeto: string;
    Detalles: string;
    ClaseServicio: string;
    DetallesServicio: string;
    FechaPrevista: TDateTime;
    ModoCobro: string;
    Importe: Currency;
    EsCobrado: Boolean;
    Presupuesto: Currency;
    DireccionCliente: string;
    PoblacionCliente: string;
    EmailCliente: string;
    EmailEmpresa: string;
    Fabricante: string;
    DireccionFabricante: string;
    TelefonoFabricante: string;
    EmailFabricante: string;
    Rma: string;
    Entrega: TDateTime;
    Resolucion: string;
    Intervencion: string;
    SerieSustituta: string;
    DocumentoCobro: string;
    EstadoPresupuesto: string;
    Agencia: string;
    Seguimiento: string;
    Movimiento: Int64;
    Trabajos: TArray<TTrabajoResguardo>;
  end;

function ReferenciaResguardoGarantia(
  const ADatos: TResguardoGarantia): string;
function RotuloReferenciaGarantia(const ADatos: TResguardoGarantia;
  const APlantilla: string): string;
function TextoResguardoGarantia(const ADatos: TResguardoGarantia): string;
// «Resguardo de depósito» en reparaciones de pago o cortesía; el de
// garantía si no.
function TituloResguardoGarantia(const ADatos: TResguardoGarantia): string;
function FormatoResguardoGarantia(const ATipoImpresion: string):
  TFormatoResguardoGarantia;
procedure CrearInformeResguardoGarantia(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; AFormato: TFormatoResguardoGarantia);
function TituloDocumentoReparacion(ATipo: TDocumentoReparacion): string;
function CopiasRecepcionReparacion(const ADatos: TResguardoGarantia):
  TArray<string>;
procedure CrearInformeDocumentoReparacion(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion;
  AFormato: TFormatoResguardoGarantia; const ACopia: string = '');

procedure ImprimirResguardoGarantiaTicket(AInforme: TfrxReport;
  const APreview: IPreviewTicket; const AImpresora, ARutaPdf: string);

implementation

uses
  System.SysUtils, System.Classes,
  inLibGarantias, inLibMsgGarantias, inLibMsgComun, inLibReparaciones,
  inLibMsgReparaciones, inLibReparacionesDiseno,
  inLibFTicket, inLibTicketTextoFR, inLibTrabajosCortinas;

function FechaResguardo(AFecha: TDateTime): string;
begin
  Result := '';
  if AFecha > 0 then
    Result := FormatDateTime('dd/mm/yyyy', AFecha);
end;

function FechaHoraResguardo(AFecha: TDateTime): string;
begin
  Result := '';
  if AFecha > 0 then
    Result := FormatDateTime('dd/mm/yyyy hh:nn', AFecha);
end;

procedure AgregarDato(ALineas: TStrings;
  const ARotulo, AValor: string);
begin
  if Trim(AValor) <> '' then
    ALineas.Add(ARotulo + ' ' + Trim(AValor));
end;

procedure AgregarTienda(ALineas: TStrings;
  const ADatos: TResguardoGarantia);
begin
  ALineas.Add(ADatos.Empresa);
  ALineas.Add(ADatos.Nif);
  ALineas.Add(ADatos.Tienda);
  ALineas.Add(ADatos.DireccionTienda);
  ALineas.Add(ADatos.PoblacionTienda);
  AgregarDato(ALineas, SCaptionGarantiaTelefonoFicha,
    ADatos.TelefonoTienda);
  ALineas.Add('');
end;

procedure AgregarGarantia(ALineas: TStrings;
  const ADatos: TResguardoGarantia);
var
  sCobertura: string;
begin
  sCobertura := SResguardoFueraGarantia;
  if ADatos.EnGarantia then
    sCobertura := SCaptionColGarantiaEnGarantia;
  ALineas.Add(sCobertura);
  AgregarDato(ALineas, SCaptionGarantiaVentaFicha, ADatos.DocumentoVenta);
  AgregarDato(ALineas, SCaptionGarantiaFechaVentaFicha,
    FechaResguardo(ADatos.FechaVenta));
  AgregarDato(ALineas, SCaptionGarantiaFinGarantiaFicha,
    FechaResguardo(ADatos.FinGarantia));
end;

function EsReparacion(const ADatos: TResguardoGarantia): Boolean;
begin
  Result := (ADatos.Modalidad <> '') and
    (ADatos.Modalidad <> MODALIDAD_REPARACION_GARANTIA);
end;

function TituloResguardoGarantia(const ADatos: TResguardoGarantia): string;
begin
  Result := SCaptionResguardoGarantia;
  if EsReparacion(ADatos) then
    Result := STituloResguardoDeposito;
end;

// Pago del cliente: importe pagado, a pagar al recoger o presupuesto;
// cortesía: sin cargo.
procedure AgregarCobro(ALineas: TStrings; const ADatos: TResguardoGarantia);
begin
  if ADatos.Modalidad = MODALIDAD_REPARACION_CORTESIA then
    ALineas.Add(SResguardoSinCargo)
  else if ADatos.Presupuesto > 0 then
    ALineas.Add(Format(SResguardoPresupuesto,
      [FormatFloat('#,##0.00', ADatos.Presupuesto)]))
  else if ADatos.EsCobrado then
    ALineas.Add(Format(SResguardoPagado,
      [FormatFloat('#,##0.00', ADatos.Importe)]))
  else if ADatos.Importe > 0 then
    ALineas.Add(Format(SResguardoAPagar,
      [FormatFloat('#,##0.00', ADatos.Importe)]));
end;

function ReferenciaResguardoGarantia(
  const ADatos: TResguardoGarantia): string;
begin
  Result := Trim(ADatos.Referencia);
  if Result = '' then
    Result := IntToStr(ADatos.Numero);
end;

function RotuloReferenciaGarantia(const ADatos: TResguardoGarantia;
  const APlantilla: string): string;
begin
  // Conserva los rótulos traducidos que antes recibían el ID numérico.
  Result := Format(StringReplace(APlantilla, '%d', '%s', [rfReplaceAll]),
    [ReferenciaResguardoGarantia(ADatos)]);
end;

function TextoResguardoGarantia(const ADatos: TResguardoGarantia): string;
var
  stLineas: TStringList;
begin
  stLineas := TStringList.Create;
  try
    AgregarTienda(stLineas, ADatos);
    if EsReparacion(ADatos) then
      AgregarDato(stLineas, SRotuloNumeroDeposito,
        ReferenciaResguardoGarantia(ADatos))
    else
      AgregarDato(stLineas, SCaptionGrupoReclamacion + ':',
        ReferenciaResguardoGarantia(ADatos));
    AgregarDato(stLineas, SCaptionGarantiaFechaReclamacion,
      FechaHoraResguardo(ADatos.Fecha));
    AgregarDato(stLineas, SCaptionGarantiaFechaRecepcion,
      FechaHoraResguardo(ADatos.Recepcion));
    AgregarDato(stLineas, SRotuloEntregaAproximada,
      FechaResguardo(ADatos.FechaPrevista));
    AgregarDato(stLineas, SCaptionGarantiaClienteFicha, ADatos.Cliente);
    AgregarDato(stLineas, SCaptionGarantiaTelefonoFicha,
      ADatos.TelefonoCliente);
    stLineas.Add('');
    AgregarDato(stLineas, SCaptionGarantiaArticuloFicha, ADatos.Articulo);
    stLineas.Add(ADatos.Descripcion);
    AgregarDato(stLineas, SCaptionGarantiaModeloFicha, ADatos.Modelo);
    AgregarDato(stLineas, SCaptionGarantiaSerieFicha, ADatos.Serie);
    if EsReparacion(ADatos) then
      AgregarDato(stLineas, SRotuloObjetoResguardo, ADatos.Objeto);
    AgregarDato(stLineas, SRotuloDetallesResguardo, ADatos.Detalles);
    AgregarDato(stLineas, SCaptionGarantiaMotivoFicha, ADatos.Motivo);
    AgregarDato(stLineas, SCaptionGarantiaObservacionesFicha,
      ADatos.Observaciones);
    AgregarDato(stLineas, SCaptionGarantiaMedio,
      TextoMedioGarantia(ADatos.Medio));
    stLineas.Add('');
    if EsReparacion(ADatos) then
      AgregarCobro(stLineas, ADatos)
    else
      AgregarGarantia(stLineas, ADatos);
    stLineas.Add('');
    stLineas.Add(SResguardoConservar);
    stLineas.Add('');
    stLineas.Add('');
    stLineas.Add(SResguardoFirmaCliente);
    stLineas.Add('');
    stLineas.Add('____________________________');
    Result := stLineas.Text;
  finally
    FreeAndNil(stLineas);
  end;
end;

function FormatoResguardoGarantia(const ATipoImpresion: string):
  TFormatoResguardoGarantia;
begin
  Result := frgTicket;
  if SameText(Trim(ATipoImpresion), 'EDITOR') or
     SameText(Trim(ATipoImpresion), 'A4') then
    Result := frgA4;
end;

function TituloDocumentoReparacion(ATipo: TDocumentoReparacion): string;
begin
  case ATipo of
    drRecepcion: Result := SImpresoRecepcion;
    drFabricante: Result := SImpresoFabricante;
    drCliente: Result := SImpresoEnvioCliente;
    drAlbaran: Result := SImpresoAlbaran;
  end;
end;

function BloqueEmisor(const ADatos: TResguardoGarantia): string;
var
  stTexto: TStringList;
begin
  stTexto := TStringList.Create;
  try
    AgregarTienda(stTexto, ADatos);
    Result := Trim(stTexto.Text);
  finally
    stTexto.Free;
  end;
end;

function BloqueCliente(const ADatos: TResguardoGarantia): string;
begin
  Result := Trim(ADatos.Cliente + sLineBreak + ADatos.DireccionCliente +
    sLineBreak + ADatos.PoblacionCliente + sLineBreak +
    ADatos.TelefonoCliente);
end;

function BloqueAparato(const ADatos: TResguardoGarantia): string;
var
  stTexto: TStringList;
begin
  stTexto := TStringList.Create;
  try
    AgregarDato(stTexto, SCaptionGarantiaArticuloFicha, ADatos.Articulo);
    if ADatos.Objeto <> '' then
      stTexto.Add(ADatos.Objeto)
    else
      AgregarDato(stTexto, '', ADatos.Descripcion);
    AgregarDato(stTexto, SCaptionGarantiaModeloFicha, ADatos.Modelo);
    AgregarDato(stTexto, SCaptionGarantiaSerieFicha, ADatos.Serie);
    Result := Trim(stTexto.Text);
  finally
    stTexto.Free;
  end;
end;

procedure ComponerRecepcion(ADiseno: TDisenoReparacion;
  const ADatos: TResguardoGarantia);
var
  stTexto: TStringList;
begin
  ADiseno.Sujetos(BloqueEmisor(ADatos), BloqueCliente(ADatos));
  ADiseno.Seccion(SImpresoAparato, BloqueAparato(ADatos));
  if (ADatos.ClaseServicio=CLASE_SERVICIO_ALTURA) or
     (ADatos.ClaseServicio=CLASE_SERVICIO_INSTALACION) then
    ADiseno.Seccion(STrabajoSolicitado,ADatos.Motivo)
  else
    ADiseno.Seccion(SImpresoMotivo, ADatos.Motivo);
  if ADatos.ClaseServicio=CLASE_SERVICIO_INSTALACION then
    ADiseno.Seccion(SInstalacionSeccion,ADatos.DetallesServicio)
  else
    ADiseno.Seccion(SMedidasSeccion,ADatos.DetallesServicio);
  ADiseno.Seccion(SImpresoEstadoRecepcion,
    Trim(ADatos.Detalles + sLineBreak + ADatos.Observaciones));
  stTexto := TStringList.Create;
  try
    if ADatos.ClaseServicio<>CLASE_SERVICIO_INSTALACION then
    begin
      AgregarDato(stTexto, SCaptionGarantiaFechaRecepcion,
        FechaHoraResguardo(ADatos.Recepcion));
      AgregarDato(stTexto, SRotuloEntregaAproximada,
        FechaResguardo(ADatos.FechaPrevista));
      AgregarDato(stTexto, SCaptionGarantiaMedio,
        TextoMedioGarantia(ADatos.Medio));
    end;
    if EsReparacion(ADatos) then
    begin
      stTexto.Add(TextoModalidadReparacion(ADatos.Modalidad));
      AgregarCobro(stTexto, ADatos);
      AgregarDato(stTexto, '', ADatos.EstadoPresupuesto);
    end
    else
      AgregarGarantia(stTexto, ADatos);
    ADiseno.Seccion(SImpresoCondiciones, Trim(stTexto.Text));
  finally
    stTexto.Free;
  end;
  if ADatos.ClaseServicio=CLASE_SERVICIO_INSTALACION then
    ADiseno.Firmas(SInstalacionAviso)
  else
    ADiseno.Firmas(SImpresoAcuseRecepcion);
end;

procedure ComponerAlbaran(ADiseno: TDisenoReparacion;
  const ADatos: TResguardoGarantia);
var
  rTrabajo: TTrabajoResguardo;
  sDescripcion, sResultado: string;
  stTexto: TStringList;
begin
  sDescripcion := '';
  if ADatos.Entrega <= 0 then
    sDescripcion := SImpresoBorrador;
  ADiseno.Seccion(SImpresoAlbaran, sDescripcion);
  ADiseno.Sujetos(BloqueEmisor(ADatos), BloqueCliente(ADatos));
  ADiseno.Seccion(SImpresoAparato, BloqueAparato(ADatos));
  sResultado := Trim(ADatos.Resolucion + sLineBreak + ADatos.Intervencion);
  if sResultado = '' then
    sResultado := SImpresoSinResolucion;
  if ADatos.SerieSustituta <> '' then
    sResultado := sResultado + sLineBreak +
      SCaptionGarantiaSerieFicha + ' ' + ADatos.SerieSustituta;
  ADiseno.Seccion(SImpresoResultado, sResultado);
  sDescripcion := SImpresoPrecios;
  if Length(ADatos.Trabajos) = 0 then
    sDescripcion := SImpresoSinTrabajos;
  ADiseno.Seccion(SImpresoTrabajos, sDescripcion, 8);
  if Length(ADatos.Trabajos) = 0 then
    ADiseno.Trabajo('', '', '')
  else
  begin
    ADiseno.CabeceraTrabajos;
    for rTrabajo in ADatos.Trabajos do
    begin
      sDescripcion := rTrabajo.Descripcion;
      if not rTrabajo.Terminado then
        sDescripcion := sDescripcion + ' (' + SImpresoPendiente + ')';
      ADiseno.Trabajo(sDescripcion,
        FormatFloat('0.###', rTrabajo.Cantidad),
        FormatFloat('#,##0.00', rTrabajo.Importe));
    end;
  end;
  ADiseno.Total(SImpresoTotal, FormatFloat('#,##0.00', ADatos.Importe));
  stTexto := TStringList.Create;
  try
    // El presupuesto nunca oculta el cobro real en el albarán final.
    if ADatos.Modalidad = MODALIDAD_REPARACION_CORTESIA then
      stTexto.Add(SResguardoSinCargo)
    else if ADatos.EsCobrado then
      stTexto.Add(Format(SResguardoPagado,
        [FormatFloat('#,##0.00', ADatos.Importe)]))
    else if ADatos.Importe > 0 then
      stTexto.Add(Format(SResguardoAPagar,
        [FormatFloat('#,##0.00', ADatos.Importe)]));
    if ADatos.DocumentoCobro <> '' then
      stTexto.Add(Format(SImpresoCobro, [ADatos.DocumentoCobro]));
    stTexto.Add(SImpresoNoFactura);
    ADiseno.Seccion(SImpresoCondiciones, Trim(stTexto.Text), 9);
  finally
    stTexto.Free;
  end;
  ADiseno.Firmas(SImpresoAcuseEntrega);
end;

procedure ComponerEtiqueta(ADiseno: TDisenoReparacion;
  const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion);
var
  sNombre, sDireccion, sDestino: string;
  stTexto: TStringList;
begin
  sNombre := ADatos.Cliente;
  sDireccion := ADatos.DireccionCliente;
  sDestino := BloqueCliente(ADatos);
  if ATipo = drFabricante then
  begin
    sNombre := ADatos.Fabricante;
    sDireccion := ADatos.DireccionFabricante;
    sDestino := sNombre + sLineBreak + sDireccion + sLineBreak +
      ADatos.TelefonoFabricante;
  end;
  if (Trim(sNombre) = '') or (Trim(sDireccion) = '') then
    raise EArgumentException.Create(SImpresoDireccionFalta);
  ADiseno.Seccion(SImpresoDestinatario, sDestino, 12);
  ADiseno.Seccion(SImpresoRemitente, BloqueEmisor(ADatos), 8);
  stTexto := TStringList.Create;
  try
    if ATipo = drFabricante then
      AgregarDato(stTexto, 'RMA:', ADatos.Rma);
    if ADatos.Movimiento > 0 then
      stTexto.Add(Format(SImpresoMovimiento, [ADatos.Movimiento]));
    AgregarDato(stTexto, SMovimientoAgencia + ':', ADatos.Agencia);
    AgregarDato(stTexto, SMovimientoTracking + ':', ADatos.Seguimiento);
    AgregarDato(stTexto, '', ADatos.Objeto);
    AgregarDato(stTexto, SCaptionGarantiaModeloFicha, ADatos.Modelo);
    AgregarDato(stTexto, SCaptionGarantiaSerieFicha, ADatos.Serie);
    ADiseno.Seccion(SImpresoTransporte, Trim(stTexto.Text), 9);
  finally
    stTexto.Free;
  end;
end;

function CopiasRecepcionReparacion(const ADatos: TResguardoGarantia):
  TArray<string>;
begin
  Result := TArray<string>.Create('');
  if ADatos.Recepcion > 0 then
    Result := TArray<string>.Create(SRecepcionCopiaCliente,
      SRecepcionCopiaPrenda);
end;

procedure CrearInformeDocumentoReparacion(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion;
  AFormato: TFormatoResguardoGarantia; const ACopia: string);
var
  oDiseno: TDisenoReparacion;
  dAncho, dAlto: Extended;
  sReferencia, sFecha, sTitulo: string;
begin
  dAncho := 210;
  dAlto := 297;
  if AFormato = frgTicket then
    dAncho := 80
  else if AFormato = frgEtiqueta then
  begin
    dAncho := 100;
    dAlto := 150;
  end;
  sReferencia := RotuloReferenciaGarantia(ADatos, SImpresoReferencia);
  if (ADatos.ClaseServicio=CLASE_SERVICIO_ALTURA) or
     (ADatos.ClaseServicio=CLASE_SERVICIO_INSTALACION) then
    sReferencia := RotuloReferenciaGarantia(ADatos, SOrdenTrabajoReferencia);
  sFecha := FechaHoraResguardo(ADatos.Fecha);
  if (ATipo = drAlbaran) and (ADatos.Entrega > 0) then
    sFecha := FechaResguardo(ADatos.Entrega);
  oDiseno := TDisenoReparacion.Create(AInforme, dAncho, dAlto,
    AFormato = frgTicket);
  try
    AInforme.ReportOptions.Name := TituloDocumentoReparacion(ATipo);
    if ATipo=drRecepcion then
    begin
      if ADatos.ClaseServicio=CLASE_SERVICIO_INSTALACION then
        AInforme.ReportOptions.Name := SOrdenInstalacion
      else if ADatos.ClaseServicio=CLASE_SERVICIO_ALTURA then
        AInforme.ReportOptions.Name := SOrdenAltura;
    end;
    sTitulo := AInforme.ReportOptions.Name;
    if (ATipo = drRecepcion) and (ACopia <> '') then
      sTitulo := sTitulo + sLineBreak + ACopia;
    oDiseno.Cabecera(sTitulo, sReferencia,
      Format(SImpresoFecha, [sFecha]));
    case ATipo of
      drRecepcion: ComponerRecepcion(oDiseno, ADatos);
      drAlbaran: ComponerAlbaran(oDiseno, ADatos);
      drFabricante, drCliente: ComponerEtiqueta(oDiseno, ADatos, ATipo);
    end;
    oDiseno.Pie(sReferencia + ' · ' + AInforme.ReportOptions.Name);
    if AFormato = frgEtiqueta then
      oDiseno.ValidarEtiqueta;
  finally
    oDiseno.Free;
  end;
end;

procedure CrearInformeResguardoGarantia(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; AFormato: TFormatoResguardoGarantia);
begin
  CrearInformeDocumentoReparacion(AInforme, ADatos, drRecepcion, AFormato);
end;

procedure ImprimirResguardoGarantiaTicket(AInforme: TfrxReport;
  const APreview: IPreviewTicket; const AImpresora, ARutaPdf: string);
var
  oTicket: TTicketTermico;
begin
  if not AInforme.PrepareReport then
    raise Exception.CreateFmt(SErrorImprimir, [SCaptionResguardoGarantia]);
  oTicket := TTicketTermico.Create(AImpresora);
  try
    ComponerTicketTextoDesdeInforme(AInforme, oTicket);
    ImprimirOPrevisualizarTicket(APreview, oTicket,
      oTicket.ObtenerComandos, ARutaPdf, AImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

end.

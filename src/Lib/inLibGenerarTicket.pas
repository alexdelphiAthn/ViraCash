{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicket                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación e impresión de tickets de venta en caja.                       }
{    Compone el ticket a partir de los datos de la operación y lo imprime.     }
{******************************************************************************}
unit inLibGenerarTicket;

interface
uses
  System.SysUtils, System.Classes, Data.DB, Uni, inLibCajaDatosFactura,
  inLibFTicket,        // Donde está tu TTicketTermico
  inLibFaseCobro,      // Para TDatosFaseCobro
  inLibParametrosIntf, inLibUnidadesMedida, inLibPreviewTicket,
  inLibGenerarTicketIntf;

  procedure ImprimirT(const AParametrosApp: IParametrosAplicacion;
                      const APreview: IPreviewTicket;
                      AUnidades: TUnidadesMedida;
                      AConexion: TUniConnection;
                      const ALecturasTicket: ILecturasImpresionTicket;
                      const ACodigoEmpresa,
                            ACodigoAlmacen,
                            ACodigoCaja,
                            ANumeroGenerado: string;
                            DatosCobro: TDatosFaseCobro;
                            NombreImpresora:string = 'DEBUG';
                            ASinPrecios: Boolean = False;
                            AFechaOperacion: TDateTime = 0;
                            ARutasPDF: TStrings = nil;
                            AImprimirCodigoBarras: Boolean = False;
                            AImprimirLotes: Boolean = True);

  // Diminutivo de ticket del empleado (fza_empleados) a partir de su
  // codigo. Si no se resuelve, devuelve el propio codigo recibido.
  function ObtenerDiminutivoVendedor(
    const ALecturasTicket: ILecturasImpresionTicket;
    const ACodigo: string): string;
  // Escribe las cuatro lineas configurables del pie de caja de la empresa.
  // Cada linea se limita al ancho real del ticket termico (42 caracteres).
  procedure EscribirPieTicketCaja(
                                  const ALecturasTicket:
                                  ILecturasImpresionTicket;
                                  ATicket: TTicketTermico;
                                  const ACodigoEmpresa: string);

implementation

uses
  inLibDir, inLibVerifactu, inLibFormatoDocumento,
  inLibMsgTickets, inLibTraducciones, inLibTipoCantidad, inLibTrazabilidad,
  inLibTicketDesgloseIva, inLibTicketLotes, Datasnap.DBClient;

type
  TImpresorTicketVenta = class
  private
    FParametrosApp       : IParametrosAplicacion;
    FPreview             : IPreviewTicket;
    FUnidades            : TUnidadesMedida;
    FConexion            : TUniConnection;
    FLecturasTicket      : ILecturasImpresionTicket;
    FCodigoEmpresa       : string;
    FCodigoAlmacen       : string;
    FCodigoCaja          : string;
    FNumeroGenerado      : string;
    FDatosCobro          : TDatosFaseCobro;
    FNombreImpresora     : string;
    FSinPrecios          : Boolean;
    FFechaOperacion      : TDateTime;
    FRutasPDF            : TStrings;
    FImprimirCodigoBarras: Boolean;
    FTicket              : TTicketTermico;
    FCabecera            : TDatosCabeceraFactura;
    FLineas              : TDataSet;
    FImprimirLotes       : Boolean;
    FDocumento           : string;
    FQRTexto             : string;
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const APreview: IPreviewTicket;
      AUnidades: TUnidadesMedida;
      AConexion: TUniConnection;
      const ALecturasTicket: ILecturasImpresionTicket;
      const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
        ANumeroGenerado: string;
      const ADatosCobro: TDatosFaseCobro;
      const ANombreImpresora: string;
      ASinPrecios: Boolean;
      AFechaOperacion: TDateTime;
      ARutasPDF: TStrings;
      AImprimirCodigoBarras: Boolean);
    function LPad(const AValor: string; ALongitud: Integer;
      const ACaracter: Char = '0'): string;
    function ConstruirQRTributario: string;
    procedure PrepararDatos;
    procedure EscribirQRTributario;
    procedure EscribirReferenciaRectificacion;
    procedure EscribirCabecera;
    procedure EscribirArticulos;
    procedure EscribirLoteArticulo;
    procedure EscribirResumenImportes;
    procedure EscribirPagosYCambio;
    procedure EscribirValeEmitido;
    procedure EscribirDesgloseIva;
    procedure EscribirTotales;
    procedure EscribirCodigoBarras;
    procedure EscribirPie;
    procedure Emitir;
  public
    procedure Ejecutar;
  end;

procedure EscribirPieTicketCaja(
                                const ALecturasTicket:
                                ILecturasImpresionTicket;
                                ATicket: TTicketTermico;
                                const ACodigoEmpresa: string);
var
  i: Integer;
  Lineas: TArray<string>;
  sLinea: string;
  EsHaEscrito: Boolean;
begin
  EsHaEscrito := False;
  if (ATicket <> nil) and (Trim(ACodigoEmpresa) <> '') and
     (ALecturasTicket <> nil) then
  begin
    Lineas := ALecturasTicket.ListarPieCaja(ACodigoEmpresa);
    for i := 0 to High(Lineas) do
    begin
      sLinea := Copy(Trim(Lineas[i]), 1, N_CHAR_LIN);
      if sLinea <> '' then
      begin
        if not EsHaEscrito then
        begin
          ATicket.SaltarLineas(1);
          ATicket.Alinear(alCentro);
          EsHaEscrito := True;
        end;
        ATicket.EscribirLinea(sLinea);
      end;
    end;
  end;
end;

// Cruza el codigo de empleado (CODIGO_CAJERO_FAC) con su diminutivo de
// ticket en fza_empleados. Si no hay conexion o no se encuentra, devuelve
// el codigo recibido para no dejar el dato en blanco.
function ObtenerDiminutivoVendedor(
  const ALecturasTicket: ILecturasImpresionTicket;
  const ACodigo: string): string;
begin
  Result := ACodigo;
  if (Trim(ACodigo) <> '') and (ALecturasTicket <> nil) then
    Result := ALecturasTicket.ObtenerDiminutivoVendedor(ACodigo);
end;

// EAN-13 del ticket desde fza_facturas ('' si la factura no lo tiene o
// si la columna aún no existe: script codigo_barras_ticket.sql sin
// aplicar).
function ObtenerCodigoBarrasTicketBD(
  const ALecturasTicket: ILecturasImpresionTicket;
  const ASerie, ANumero: string): string;
begin
  Result := '';
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') and
     (ALecturasTicket <> nil) then
    Result := ALecturasTicket.ObtenerCodigoBarras(ASerie, ANumero);
end;

constructor TImpresorTicketVenta.Create(
  const AParametrosApp: IParametrosAplicacion;
  const APreview: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  AConexion: TUniConnection;
  const ALecturasTicket: ILecturasImpresionTicket;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
    ANumeroGenerado: string;
  const ADatosCobro: TDatosFaseCobro;
  const ANombreImpresora: string;
  ASinPrecios: Boolean;
  AFechaOperacion: TDateTime;
  ARutasPDF: TStrings;
  AImprimirCodigoBarras: Boolean);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FPreview := APreview;
  FUnidades := AUnidades;
  FConexion := AConexion;
  FLecturasTicket := ALecturasTicket;
  FCodigoEmpresa := ACodigoEmpresa;
  FCodigoAlmacen := ACodigoAlmacen;
  FCodigoCaja := ACodigoCaja;
  FNumeroGenerado := ANumeroGenerado;
  FDatosCobro := ADatosCobro;
  FNombreImpresora := ANombreImpresora;
  FSinPrecios := ASinPrecios;
  FFechaOperacion := AFechaOperacion;
  FRutasPDF := ARutasPDF;
  FImprimirCodigoBarras := AImprimirCodigoBarras;
end;

function TImpresorTicketVenta.LPad(const AValor: string;
  ALongitud: Integer; const ACaracter: Char): string;
begin
  if Length(AValor) >= ALongitud then
    Result := AValor
  else
    Result := StringOfChar(
      ACaracter, ALongitud - Length(AValor)) + AValor;
end;

function TImpresorTicketVenta.ConstruirQRTributario: string;
var
  oCampoFormato: TField;
  sFormato: string;
begin
  Result := '';
  sFormato := '';
  oCampoFormato := FDatosCobro.TotalesFactura.Cabecera.FindField(
    'FORMATO_DOCUMENTO_EMP');
  if oCampoFormato <> nil then
    sFormato := oCampoFormato.AsString;
  // El SII no lleva QR tributario (FZ-ISSUE-293)
  if QrTributarioActivo(FParametrosApp) and
     (not FSinPrecios) then
    Result := ConstruirUrlQR(
      FParametrosApp,
      FCabecera.NifEmp,
      sFormato,
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'SERIE_FAC').AsString,
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'NUMERO_FAC').AsString,
      FCabecera.Fecha,
      FCabecera.TotalBases + FCabecera.TotalImpuestos);
end;

procedure TImpresorTicketVenta.PrepararDatos;
begin
  FCabecera := LeerCabeceraFactura(
    FDatosCobro.TotalesFactura.Cabecera);
  if FFechaOperacion = 0 then
    FFechaOperacion := Now;
  FLineas := FDatosCobro.TotalesFactura.Lineas;
  FDocumento := FormatearDocumentoDataSet(
    FDatosCobro.TotalesFactura.Cabecera,
    'SERIE_FAC',
    'NUMERO_FAC');
  FQRTexto := ConstruirQRTributario;
end;

procedure TImpresorTicketVenta.EscribirQRTributario;
begin
  if FQRTexto <> '' then
  begin
    FTicket.Alinear(alCentro);
    FTicket.SaltarLineas(1);
    FTicket.EscribirLinea('QR tributario:');
    FTicket.ImprimirQRNativo(FQRTexto, 6, 49);
    if VerifactuActivo(FParametrosApp) then
    begin
      FTicket.Alinear(alCentro);
      FTicket.EscribirLinea('VERI*FACTU - Factura verificable');
      FTicket.EscribirLinea('en la sede electrónica de la AEAT');
    end;
    FTicket.Alinear(alIzquierda);
  end;
end;

// FZ-ISSUE-200: una rectificativa o sustitutiva identifica la factura a
// la que se refiere, su fecha y el motivo de la devolucion.
procedure TImpresorTicketVenta.EscribirReferenciaRectificacion;
var
  oCampoFormato: TField;
  oReferencia: TReferenciaRectificacionTicket;
  sFormato: string;
  sLinea: string;
begin
  if (not FSinPrecios) and (FLecturasTicket <> nil) then
  begin
    oReferencia := FLecturasTicket.ObtenerReferenciaRectificacion(
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'SERIE_FAC').AsString,
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'NUMERO_FAC').AsString);
    sFormato := '';
    oCampoFormato := FDatosCobro.TotalesFactura.Cabecera.FindField(
      'FORMATO_DOCUMENTO_EMP');
    if oCampoFormato <> nil then
      sFormato := oCampoFormato.AsString;
    for sLinea in LineasReferenciaRectificacion(
      oReferencia, sFormato, N_CHAR_LIN) do
      FTicket.EscribirLinea(sLinea);
  end;
end;

procedure TImpresorTicketVenta.EscribirCabecera;
begin
  EscribirQRTributario;
  FTicket.SaltarLineas(1);
  FTicket.Negrita(True);
  if FSinPrecios then
    FTicket.EscribirLinea(
      Format(STicketRegaloNumero, [FDocumento]))
  else
    FTicket.EscribirLinea(
      FormatearTituloFacturaCaja(FCabecera.TipoFactura, FDocumento));
  FTicket.Negrita(False);
  EscribirReferenciaRectificacion;
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea(FCabecera.RazonSocialEmp);
  FTicket.EscribirLinea(FCabecera.Direccion1Emp);
  FTicket.EscribirLinea(
    FCabecera.CPostalEmp + ' ' + FCabecera.PoblacionEmp);
  FTicket.EscribirLinea(
    Format(STicketCifNif, [FCabecera.NifEmp]));
  if Trim(FCabecera.MovilEmp) <> '' then
    FTicket.EscribirLinea(
      Format(STicketTelefono, [FCabecera.MovilEmp]));
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alIzquierda);
  FTicket.TextoColumnas(
    STicketEtiquetaOperacionNumero, FNumeroGenerado);
  FTicket.SaltarLineas(1);
  FTicket.TextoColumnas(
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaOperacion),
    Format(STicketFormatoTienda,
      [LPad(FCodigoEmpresa, 3), LPad(FCodigoAlmacen, 3),
       LPad(FCodigoCaja, 2)]));
end;

// F-LOTEC-015: el lote o la serie bajo la línea, solo con interruptores.
procedure TImpresorTicketVenta.EscribirLoteArticulo;
var
  dtCaducidad: TDate;
  sTexto: string;
begin
  if ActivacionVigente.AlgunModoActivo and
     (FLineas.FindField('LOTE_FACLIN') <> nil) then
  begin
    dtCaducidad := SIN_FECHA;
    if (FLineas.FindField('FECHA_CADUCIDAD_FACLIN') <> nil) and
       not FLineas.FieldByName('FECHA_CADUCIDAD_FACLIN').IsNull then
      dtCaducidad :=
        Trunc(FLineas.FieldByName('FECHA_CADUCIDAD_FACLIN').AsDateTime);
    sTexto := TextoLoteTicket(FLineas.FieldByName('LOTE_FACLIN').AsString,
      dtCaducidad, (FLineas.FindField('ESSERIE_LOTE') <> nil) and
      (FLineas.FieldByName('ESSERIE_LOTE').AsString = 'S'));
    if sTexto <> '' then
      FTicket.EscribirLinea(Copy(sTexto, 1, 42));
  end;
end;

procedure TImpresorTicketVenta.EscribirArticulos;
var
  sArticulo, sUnidad, sUnidades, sPrecio, sDescuento: string;
  Original: TDataSet;
  Presentacion: TClientDataSet;
begin
  Original := FLineas;
  Presentacion := PrepararLineasTicket(FLineas, FImprimirLotes);
  FLineas := Presentacion;
  try
    FTicket.LineaSeparadora('-');
    FTicket.EscribirLinea(STicketCabeceraArticulos);
    FTicket.LineaSeparadora('-');
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        sArticulo := FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
        sUnidad := '';
        if FLineas.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN') <> nil then
          sUnidad := FLineas.FieldByName(
            'TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
        if Assigned(FUnidades) then
          sUnidades := FUnidades.Formatear(
            FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat, sUnidad)
        else
          sUnidades := FormatFloat(
            '0', FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat);
        sUnidades := CantidadConTipo(Format('%4s', [sUnidades]), sUnidad);
        if FSinPrecios then
          FTicket.EscribirLinea(
            ColumnaArticuloTicket(sArticulo, sUnidades, ''))
        else
        begin
          sPrecio := FormatFloat('#,##0.00',
            FLineas.FieldByName('TOTAL_FACLIN').AsCurrency) + ' €';
          FTicket.TextoColumnas(
            ColumnaArticuloTicket(sArticulo, sUnidades, sPrecio), sPrecio);
        end;
        FTicket.EscribirLinea(Copy(FLineas.FieldByName(
          'DESCRIPCION_ARTICULO_FACLIN').AsString, 1, 42));
        if not FSinPrecios and
           (FLineas.FindField('PRECIO_SALIDA_FACLIN') <> nil) and
           (FLineas.FindField('PORCENTAJE_DTO_FACLIN') <> nil) and
           (FLineas.FindField('PRECIO_DTO_FACLIN') <> nil) then
        begin
          sDescuento := TextoDescuentoTicket(
            FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat,
            FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat,
            FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat);
          if sDescuento <> '' then
            FTicket.EscribirLinea(sDescuento);
        end;
        EscribirLoteArticulo;
        FLineas.Next;
      end;
    finally
      FLineas.EnableControls;
    end;
  finally
    FLineas := Original;
    Presentacion.Free;
  end;
  FTicket.LineaSeparadora('-');
  FTicket.SaltarLineas(1);
end;

procedure TImpresorTicketVenta.EscribirResumenImportes;
begin
  FTicket.Alinear(alIzquierda);
  FTicket.Negrita(True);
  if FDatosCobro.ImporteDescuentoGlobal > 0 then
  begin
    FTicket.TextoColumnas(STicketSuma,
      Format('%.2f', [FCabecera.TotalLiquido +
        FDatosCobro.ImporteDescuentoGlobal]) + ' €');
    FTicket.TextoColumnas(STicketDescuento,
      Format('-%.2f', [FDatosCobro.ImporteDescuentoGlobal]) + ' €');
  end;
  if FDatosCobro.ImporteValeRecogido > 0 then
    FTicket.TextoColumnas(STicketValeRecogido,
      Format('-%.2f', [FDatosCobro.ImporteValeRecogido]) + ' €');
  FTicket.TextoColumnas(
    STicketAPagar,
    Format('%.2f', [FCabecera.TotalLiquido]) + ' €');
  FTicket.Negrita(False);
end;

procedure TImpresorTicketVenta.EscribirPagosYCambio;
var
  dImporte: Double;
  sFormaPago: string;
begin
  FTicket.Alinear(alIzquierda);
  FTicket.Negrita(True);
  FDatosCobro.MemTablePagos.First;
  while not FDatosCobro.MemTablePagos.Eof do
  begin
    sFormaPago := FDatosCobro.MemTablePagos.FieldByName(
      'DESCRIPCION_FORMA_PAGO_CFP').AsString;
    dImporte := FDatosCobro.MemTablePagos.FieldByName(
      'IMPORTE_ENTREGADO').AsFloat;
    // FZ-ISSUE-200: en una devolucion el importe entregado es negativo.
    if Abs(dImporte) > 0.001 then
      FTicket.TextoColumnas(
        UpperCase(sFormaPago), Format('%.2f', [dImporte]) + ' €');
    FDatosCobro.MemTablePagos.Next;
  end;
  if FDatosCobro.ImporteCambio > 0 then
    FTicket.TextoColumnas(STicketCambioEfectivo,
      Format('%.2f', [FDatosCobro.ImporteCambio]) + ' €');
  FTicket.Negrita(False);
end;

procedure TImpresorTicketVenta.EscribirValeEmitido;
begin
  if FDatosCobro.ImporteValeEmitido > 0 then
  begin
    FTicket.SaltarLineas(1);
    FTicket.Negrita(True);
    FTicket.TextoColumnas(STicketValeEmitidoFavor,
      Format('%.2f', [FDatosCobro.ImporteValeEmitido]) + ' €');
    if Length(STicketCodigoValeEmitidoEspacio +
       FDatosCobro.CodigoValeEmitido) <= 42 then
      FTicket.TextoColumnas(
        STicketCodigoValeEmitidoEspacio, FDatosCobro.CodigoValeEmitido)
    else
    begin
      FTicket.EscribirLinea(STicketCodigoValeEmitido);
      FTicket.EscribirLinea(FDatosCobro.CodigoValeEmitido);
    end;
    if FDatosCobro.PinValeEmitido <> '' then
      FTicket.TextoColumnas(
        STicketPinValeEmitidoEspacio, FDatosCobro.PinValeEmitido);
    FTicket.Negrita(False);
  end;
end;

// FZ-ISSUE-335: los cuatro tipos, no solo el normal y el reducido.
procedure TImpresorTicketVenta.EscribirDesgloseIva;
begin
  EscribirDesgloseIvaTicket(FTicket, TramosIvaTicket(
    ImportesIvaTicket(FCabecera.BaseIN, FCabecera.TotalIvaN,
      FCabecera.PorcIvaN, FCabecera.TotalReN, FCabecera.PorcReN),
    ImportesIvaTicket(FCabecera.BaseIR, FCabecera.TotalIvaR,
      FCabecera.PorcIvaR, FCabecera.TotalReR, FCabecera.PorcReR),
    ImportesIvaTicket(FCabecera.BaseIS, FCabecera.TotalIvaS,
      FCabecera.PorcIvaS, FCabecera.TotalReS, FCabecera.PorcReS),
    ImportesIvaTicket(FCabecera.BaseIE, FCabecera.TotalIvaE,
      FCabecera.PorcIvaE, FCabecera.TotalReE, FCabecera.PorcReE)));
end;

procedure TImpresorTicketVenta.EscribirTotales;
begin
  if not FSinPrecios then
  begin
    EscribirResumenImportes;
    EscribirPagosYCambio;
    EscribirValeEmitido;
    FTicket.SaltarLineas(1);
    EscribirDesgloseIva;
  end;
end;

procedure TImpresorTicketVenta.EscribirCodigoBarras;
var
  sCodigo: string;
begin
  if FImprimirCodigoBarras then
  begin
    sCodigo := ObtenerCodigoBarrasTicketBD(
      FLecturasTicket,
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'SERIE_FAC').AsString,
      FDatosCobro.TotalesFactura.Cabecera.FieldByName(
        'NUMERO_FAC').AsString);
    if sCodigo <> '' then
    begin
      FTicket.SaltarLineas(1);
      FTicket.ImprimirEAN13Nativo(sCodigo);
    end;
  end;
end;

procedure TImpresorTicketVenta.EscribirPie;
var
  sVendedor: string;
begin
  FTicket.SaltarLineas(2);
  FTicket.Alinear(alCentro);
  sVendedor := ObtenerDiminutivoVendedor(
    FLecturasTicket,
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'CODIGO_CAJERO_FAC').AsString);
  FTicket.EscribirLinea(Format(STicketLeAtendio, [sVendedor]));
  if not FSinPrecios then
    FTicket.EscribirLinea(STicketIvaIncluido);
  FTicket.EscribirLinea(STicketGraciasVisita);
  EscribirPieTicketCaja(FLecturasTicket, FTicket, FCodigoEmpresa);
  EscribirCodigoBarras;
  FTicket.AvanzarYCortarPapel;
  FTicket.AbrirCajon;
end;

procedure TImpresorTicketVenta.Emitir;
var
  sComandos, sRutaPDF, sSufijoPDF: string;
begin
  sComandos := FTicket.ObtenerComandos;
  sSufijoPDF := '';
  if FSinPrecios then
    sSufijoPDF := '_regalo';
  sRutaPDF := GetUserFolderTickets + 'Ticket_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + sSufijoPDF + '.pdf';
  ImprimirOPrevisualizarTicket(
    FPreview, FTicket, sComandos, sRutaPDF, FNombreImpresora);
  if (FRutasPDF <> nil) and FileExists(sRutaPDF) then
    FRutasPDF.Add(sRutaPDF);
end;

procedure TImpresorTicketVenta.Ejecutar;
var
  ProteccionIdioma: IInterface;
begin
  PrepararDatos;
  ProteccionIdioma := ProtegerDocumentoVentaEspanol;
  FTicket := TTicketTermico.Create(FNombreImpresora);
  try
    FTicket.Inicializar;
    EscribirCabecera;
    EscribirArticulos;
    EscribirTotales;
    EscribirPie;
    Emitir;
  finally
    FreeAndNil(FTicket);
  end;
end;

procedure ImprimirT(const AParametrosApp: IParametrosAplicacion;
                    const APreview: IPreviewTicket;
                    AUnidades: TUnidadesMedida;
                    AConexion: TUniConnection;
                    const ALecturasTicket: ILecturasImpresionTicket;
                    const ACodigoEmpresa,
                          ACodigoAlmacen,
                          ACodigoCaja,
                          ANumeroGenerado: string;
                          DatosCobro: TDatosFaseCobro;
                          NombreImpresora:string;
                          ASinPrecios: Boolean;
                          AFechaOperacion: TDateTime;
                          ARutasPDF: TStrings;
                          AImprimirCodigoBarras: Boolean;
                          AImprimirLotes: Boolean);
var
  Impresor: TImpresorTicketVenta;
begin
  if DatosCobro.FRequiereFactura then
  begin
    Impresor := TImpresorTicketVenta.Create(
      AParametrosApp, APreview, AUnidades, AConexion, ALecturasTicket,
      ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja, ANumeroGenerado,
      DatosCobro, NombreImpresora, ASinPrecios, AFechaOperacion,
      ARutasPDF, AImprimirCodigoBarras);
    try
      Impresor.FImprimirLotes := AImprimirLotes;
      Impresor.Ejecutar;
    finally
      FreeAndNil(Impresor);
    end;
  end;
end;

end.

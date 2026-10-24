{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketBD                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera tickets desde read models sin conocer UniDAC ni el esquema SQL.    }
{******************************************************************************}
unit inLibGenerarTicketBD;

interface

uses
  System.SysUtils, System.Classes, inLibFTicket,
  inLibUnidadesMedida, inLibDir, inLibParametrosIntf,
  inLibTicketsCajaIntf, inLibPreviewTicket;

// Con un apartado del cliente de Varios saca dos copias: una para el
// cliente y otra para pegar en la prenda.
procedure ImprimirResguardoDeposito(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioResguardosCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False;
  AImprimirCodigoBarras: Boolean = False);
procedure ImprimirTicketDesdeBD(
  const AParametrosApp: IParametrosAplicacion;
  const APreview: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorio: IRepositorioTicketsVentaCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  ANumeroOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False;
  AImprimirCodigoBarras: Boolean = False;
  AImprimirLotes: Boolean = True);
procedure ImprimirRecordatorio(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioRecordatoriosCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False);

implementation

uses
  inLibTicketDesgloseIva,
  inLibVerifactu, inLibFormatoDocumento,
  inLibCajaDatosFactura, inLibMsgCaja, inLibMsgTickets, inLibTraducciones,
  inLibTicketRecordatorio, inLibTipoCantidad, inLibTrazabilidad,
  inLibTicketLotes, inLibPrecioUnidad;

function LPAD(
  const AValue: string;
  ALength: Integer;
  const APadChar: Char = '0'): string;
var
  iLongitudActual: Integer;
begin
  iLongitudActual := Length(AValue);
  if iLongitudActual >= ALength then
    Result := AValue
  else
    Result := StringOfChar(APadChar, ALength - iLongitudActual) + AValue;
end;

procedure EscribirPieTicket(
  ATicket: TTicketTermico;
  const ALineas: TArray<string>);
var
  bHaEscrito: Boolean;
  i: Integer;
  sLinea: string;
begin
  bHaEscrito := False;
  if ATicket <> nil then
  begin
    for i := 0 to High(ALineas) do
    begin
      sLinea := Copy(Trim(ALineas[i]), 1, 42);
      if sLinea <> '' then
      begin
        if not bHaEscrito then
        begin
          ATicket.SaltarLineas(1);
          ATicket.Alinear(alCentro);
          bHaEscrito := True;
        end;
        ATicket.EscribirLinea(sLinea);
      end;
    end;
  end;
end;

type
  TGeneradorResguardoDeposito = class
  private
    FRepositorio: IRepositorioResguardosCaja;
    FPreview: IPreviewTicket;
    FContexto: TContextoOperacionTicketCaja;
    FNombreImpresora: string;
    FRutasPDF: TStrings;
    FSoloPDF: Boolean;
    FTicket: TTicketTermico;
    FNombreEmpresa: string;
    FFormatoDocumento: string;
    FFechaOperacion: TDateTime;
    FNuevosDepositos: TArray<TDepositoResguardoTicketCaja>;
    FTotalNuevos: Currency;
    FTotalEntregas: Currency;
    FTotalDevoluciones: Currency;
    FTotalDevueltos: Currency;
    FApartado: TApartadoResguardoTicketCaja;
    FImprimirCodigoBarras: Boolean;
    FSufijoFichero: string;
    procedure CargarCabecera;
    procedure ReiniciarTicket(const ASufijoFichero: string);
    procedure GenerarCopia(const AEtiquetaCopia, ASufijoFichero: string);
    procedure EscribirApartado(const AEtiquetaCopia: string);
    procedure EscribirTituloSeccion(const ATitulo: string);
    procedure EscribirCabecera;
    procedure EscribirDepositos(
      const ATitulo: string;
      ASaltarAntes: Boolean;
      const ADepositos: TArray<TDepositoResguardoTicketCaja>;
      var ATotal: Currency);
    procedure EscribirEntregas;
    procedure EscribirDevolucionEconomica;
    procedure EscribirResumen;
    procedure GenerarSalida;
    function HayMovimientos: Boolean;
    function TotalPagadoCaja: Currency;
  public
    constructor Create(
      const APreview: IPreviewTicket;
      const ARepositorio: IRepositorioResguardosCaja;
      const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
      AOperacion, ANombreImpresora: string;
      ARutasPDF: TStrings;
      ASoloPDF: Boolean);
    destructor Destroy; override;
    procedure Ejecutar;
    property ImprimirCodigoBarras: Boolean
      read FImprimirCodigoBarras write FImprimirCodigoBarras;
  end;
  TConfiguracionTicketVenta = record
    ImprimirLotes: Boolean;
    ParametrosApp: IParametrosAplicacion;
    Preview: IPreviewTicket;
    Unidades: TUnidadesMedida;
    Repositorio: IRepositorioTicketsVentaCaja;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    NumeroOperacion: string;
    NombreImpresora: string;
    RutasPDF: TStrings;
    SoloPDF: Boolean;
    ImprimirCodigoBarras: Boolean;
  end;
  TGeneradorTicketVenta = class
  private
    FConfiguracion: TConfiguracionTicketVenta;
    FContexto: TContextoOperacionTicketCaja;
    FCabecera: TCabeceraTicketCaja;
    FTicket: TTicketTermico;
    FProteccionIdioma: IInterface;
    FFechaOperacion: TDateTime;
    FDocumentoFactura: string;
    FTextoQr: string;
    FTieneFactura: Boolean;
    procedure CargarDatos;
    procedure EscribirQr;
    procedure EscribirIdentificacion;
    procedure EscribirEmpresa;
    procedure EscribirLineas;
    procedure EscribirPagos;
    procedure EscribirVales;
    procedure EscribirImpuestos;
    procedure EscribirPie;
    procedure EscribirCodigoBarras;
    procedure GenerarSalida;
  public
    constructor Create(const AConfiguracion: TConfiguracionTicketVenta);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

constructor TGeneradorResguardoDeposito.Create(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioResguardosCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion, ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
begin
  inherited Create;
  FPreview := APreview;
  FRepositorio := ARepositorio;
  FContexto.Empresa := ACodigoEmpresa;
  FContexto.Almacen := ACodigoAlmacen;
  FContexto.Caja := ACodigoCaja;
  FContexto.Operacion := AOperacion;
  FNombreImpresora := ANombreImpresora;
  FRutasPDF := ARutasPDF;
  FSoloPDF := ASoloPDF;
  FTicket := TTicketTermico.Create(FNombreImpresora);
end;

destructor TGeneradorResguardoDeposito.Destroy;
begin
  FreeAndNil(FTicket);
  FRepositorio := nil;
  inherited;
end;

procedure TGeneradorResguardoDeposito.CargarCabecera;
var
  oEmpresa: TEmpresaResguardoTicketCaja;
  oFecha: TFechaResguardoTicketCaja;
begin
  FFechaOperacion := 0;
  oEmpresa := FRepositorio.ObtenerEmpresaResguardo(
    FContexto.Empresa);
  if oEmpresa.Encontrada then
  begin
    FNombreEmpresa := oEmpresa.RazonSocial;
    FFormatoDocumento := oEmpresa.FormatoDocumento;
  end;
  oFecha := FRepositorio.ObtenerFechaResguardo(FContexto);
  if oFecha.Encontrada then
    FFechaOperacion := oFecha.FechaOperacion;
end;

procedure TGeneradorResguardoDeposito.EscribirTituloSeccion(
  const ATitulo: string);
begin
  FTicket.LineaSeparadora('=');
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(ATitulo);
  FTicket.Negrita(False);
  FTicket.LineaSeparadora('-');
  FTicket.Alinear(alIzquierda);
end;

procedure TGeneradorResguardoDeposito.EscribirCabecera;
var
  sCodigoCliente: string;
begin
  sCodigoCliente := '';
  if Length(FNuevosDepositos) > 0 then
    sCodigoCliente := FNuevosDepositos[0].CodigoCliente;
  FTicket.Inicializar;
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  if FNombreEmpresa <> '' then
    FTicket.EscribirLinea(FNombreEmpresa);
  FTicket.SaltarLineas(1);
  FTicket.EscribirLinea(STicketResumenOperacion);
  FTicket.EscribirLinea(STicketDepositosEntregas);
  FTicket.Negrita(False);
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alIzquierda);
  FTicket.TextoColumnas(
    STicketEtiquetaCodigoCliente,
    sCodigoCliente);
  FTicket.TextoColumnas(
    STicketEtiquetaFecha,
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaOperacion));
  FTicket.TextoColumnas(
    STicketEtiquetaNumeroOperacion,
    FContexto.Operacion);
  FTicket.SaltarLineas(1);
end;

procedure TGeneradorResguardoDeposito.EscribirDepositos(
  const ATitulo: string;
  ASaltarAntes: Boolean;
  const ADepositos: TArray<TDepositoResguardoTicketCaja>;
  var ATotal: Currency);
var
  i: Integer;
begin
  if Length(ADepositos) > 0 then
  begin
    if ASaltarAntes then
      FTicket.SaltarLineas(1);
    EscribirTituloSeccion(ATitulo);
    for i := 0 to High(ADepositos) do
    begin
      ATotal := ATotal + ADepositos[i].TotalPvp;
      if ADepositos[i].Descripcion <> '' then
        FTicket.EscribirLinea(
          Copy(ADepositos[i].Descripcion, 1, 40));
      FTicket.EscribirLinea(ADepositos[i].CodigoUnidad);
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        Format(
          STicketValorArticulo,
          [FormatFloat('#,##0.00', ADepositos[i].TotalPvp)]));
      FTicket.Alinear(alIzquierda);
    end;
    FTicket.SaltarLineas(1);
  end;
end;

procedure TGeneradorResguardoDeposito.EscribirEntregas;
var
  i: Integer;
  sConcepto: string;
  oEntregas: TArray<TEntregaResguardoTicketCaja>;
begin
  oEntregas := FRepositorio.ListarEntregasResguardo(FContexto);
  if Length(oEntregas) > 0 then
  begin
    EscribirTituloSeccion(STicketEntregasCuenta);
    for i := 0 to High(oEntregas) do
    begin
      FTotalEntregas := FTotalEntregas + oEntregas[i].Importe;
      sConcepto := '';
      if Trim(oEntregas[i].DescripcionArticulo) <> '' then
      begin
        if oEntregas[i].TipoOperacion = 'CB' then
          sConcepto := Format(
            STicketCuentaArticulo,
            [oEntregas[i].DescripcionArticulo])
        else if oEntregas[i].TipoOperacion = 'DE' then
          sConcepto := Format(
            STicketCuentaInicialArticulo,
            [oEntregas[i].DescripcionArticulo]);
      end
      else
      begin
        if oEntregas[i].TipoOperacion = 'CB' then
          sConcepto := STicketCuentaArticuloPendiente
        else if oEntregas[i].TipoOperacion = 'DE' then
          sConcepto := STicketCuentaInicial;
      end;
      FTicket.EscribirLinea(Copy(sConcepto, 1, 40));
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        FormatFloat('#,##0.00', oEntregas[i].Importe) + ' €');
      FTicket.Alinear(alIzquierda);
    end;
    FTicket.SaltarLineas(1);
  end;
end;

procedure TGeneradorResguardoDeposito.EscribirDevolucionEconomica;
var
  i: Integer;
  oDevoluciones: TArray<TDevolucionEconomicaTicketCaja>;
begin
  oDevoluciones :=
    FRepositorio.ListarDevolucionesEconomicasResguardo(FContexto);
  if Length(oDevoluciones) > 0 then
  begin
    EscribirTituloSeccion(STicketDevolucionEconomica);
    for i := 0 to High(oDevoluciones) do
    begin
      FTotalDevoluciones :=
        FTotalDevoluciones + oDevoluciones[i].Importe;
      FTicket.EscribirLinea(
        Copy(oDevoluciones[i].TipoOperacion, 1, 40));
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        FormatFloat('#,##0.00', oDevoluciones[i].Importe) + ' €');
      FTicket.Alinear(alIzquierda);
    end;
  end;
end;

function TGeneradorResguardoDeposito.HayMovimientos: Boolean;
begin
  Result :=
    (FTotalNuevos <> 0) or
    (FTotalEntregas <> 0) or
    (FTotalDevoluciones <> 0) or
    (FTotalDevueltos <> 0);
end;

function TGeneradorResguardoDeposito.TotalPagadoCaja: Currency;
begin
  Result := FRepositorio.ObtenerTotalPagadoResguardo(FContexto);
end;

procedure TGeneradorResguardoDeposito.EscribirResumen;
var
  dTotalPagado: Currency;
begin
  dTotalPagado := TotalPagadoCaja;
  FTicket.LineaSeparadora('=');
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alDerecha);
  if FTotalNuevos > 0 then
    FTicket.EscribirLinea(
      Format(
        STicketTotalNuevosDepositos,
        [FormatFloat('#,##0.00', FTotalNuevos)]));
  if FTotalDevueltos <> 0 then
    FTicket.EscribirLinea(
      Format(
        STicketTotalDepositosDevueltos,
        [FormatFloat('#,##0.00', FTotalDevueltos)]));
  FTicket.EscribirLinea(
    Format(
      STicketAnticiposEntregadosAhora,
      [FormatFloat('#,##0.00', FTotalEntregas)]));
  if FTotalDevoluciones < 0 then
    FTicket.EscribirLinea(
      Format(
        STicketDevueltoOperacion,
        [FormatFloat('#,##0.00', FTotalDevoluciones)]));
  FTicket.SaltarLineas(1);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(
    Format(
      STicketTotalPagadoDepositos,
      [FormatFloat('#,##0.00', dTotalPagado)]));
  FTicket.Negrita(False);
  FTicket.SaltarLineas(2);
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea(STicketConformeCliente);
  FTicket.SaltarLineas(4);
  FTicket.LineaSeparadora('_');
  EscribirPieTicket(
    FTicket,
    FRepositorio.ListarPieTicket(FContexto.Empresa));
  FTicket.CortarPapel;
end;

procedure TGeneradorResguardoDeposito.GenerarSalida;
var
  sComandosEsc: string;
  sRutaFicheroPdf: string;
begin
  sComandosEsc := FTicket.ObtenerComandos;
  sRutaFicheroPdf :=
    GetUserFolderTickets + 'ResguardoDep_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + FSufijoFichero + '.pdf';
  ImprimirOPrevisualizarTicket(
    FPreview,
    FTicket,
    sComandosEsc,
    sRutaFicheroPdf,
    FNombreImpresora,
    FSoloPDF);
  if (FRutasPDF <> nil) and FileExists(sRutaFicheroPdf) then
    FRutasPDF.Add(sRutaFicheroPdf);
end;

procedure TGeneradorResguardoDeposito.Ejecutar;
begin
  CargarCabecera;
  FApartado := FRepositorio.ObtenerApartadoResguardo(FContexto);
  if FApartado.Encontrado then
  begin
    GenerarCopia(STicketCopiaClienteApartado, '_cliente');
    GenerarCopia(STicketCopiaPrendaApartado, '_prenda');
  end
  else
    GenerarCopia('', '');
end;

procedure TGeneradorResguardoDeposito.ReiniciarTicket(
  const ASufijoFichero: string);
begin
  FreeAndNil(FTicket);
  FTicket := TTicketTermico.Create(FNombreImpresora);
  FSufijoFichero := ASufijoFichero;
  FTotalNuevos := 0;
  FTotalEntregas := 0;
  FTotalDevoluciones := 0;
  FTotalDevueltos := 0;
end;

procedure TGeneradorResguardoDeposito.EscribirApartado(
  const AEtiquetaCopia: string);
begin
  if FApartado.Encontrado then
  begin
    FTicket.Alinear(alCentro);
    FTicket.Negrita(True);
    FTicket.EscribirLinea(AEtiquetaCopia);
    FTicket.Negrita(False);
    FTicket.Alinear(alIzquierda);
    FTicket.TextoColumnas(
      STicketEtiquetaApartadoPor,
      Copy(FApartado.NombreContacto, 1, 28));
    if FApartado.TelefonoContacto <> '' then
      FTicket.TextoColumnas(
        STicketEtiquetaTelefonoApartado,
        FApartado.TelefonoContacto);
    if FApartado.NumeroFactura <> '' then
      FTicket.TextoColumnas(
        STicketEtiquetaTicketApartado,
        FormatearDocumento(FFormatoDocumento,
          FApartado.SerieFactura, FApartado.NumeroFactura));
    if FImprimirCodigoBarras and (FApartado.CodigoBarras <> '') then
    begin
      FTicket.Alinear(alCentro);
      FTicket.ImprimirEAN13Nativo(FApartado.CodigoBarras);
      FTicket.Alinear(alIzquierda);
    end;
    FTicket.SaltarLineas(1);
  end;
end;

procedure TGeneradorResguardoDeposito.GenerarCopia(
  const AEtiquetaCopia, ASufijoFichero: string);
var
  oDepositosDevueltos: TArray<TDepositoResguardoTicketCaja>;
begin
  ReiniciarTicket(ASufijoFichero);
  FNuevosDepositos :=
    FRepositorio.ListarNuevosDepositosResguardo(FContexto);
  EscribirCabecera;
  EscribirApartado(AEtiquetaCopia);
  EscribirDepositos(
    STicketMovimientoDepositosPrestamos,
    False,
    FNuevosDepositos,
    FTotalNuevos);
  EscribirEntregas;
  EscribirDevolucionEconomica;
  oDepositosDevueltos :=
    FRepositorio.ListarDepositosDevueltosResguardo(FContexto);
  EscribirDepositos(
    STicketDevolucionArticulos,
    True,
    oDepositosDevueltos,
    FTotalDevueltos);
  if HayMovimientos then
  begin
    EscribirResumen;
    GenerarSalida;
  end;
end;

constructor TGeneradorTicketVenta.Create(
  const AConfiguracion: TConfiguracionTicketVenta);
begin
  inherited Create;
  FConfiguracion := AConfiguracion;
  FTicket := TTicketTermico.Create(FConfiguracion.NombreImpresora);
end;

destructor TGeneradorTicketVenta.Destroy;
begin
  FreeAndNil(FTicket);
  FProteccionIdioma := nil;
  FConfiguracion.Repositorio := nil;
  FConfiguracion.Preview := nil;
  FConfiguracion.ParametrosApp := nil;
  inherited;
end;

procedure TGeneradorTicketVenta.CargarDatos;
begin
  if not Assigned(FConfiguracion.Repositorio) then
    raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  FContexto.Empresa := FConfiguracion.CodigoEmpresa;
  FContexto.Almacen := FConfiguracion.CodigoAlmacen;
  FContexto.Caja := FConfiguracion.CodigoCaja;
  FContexto.Operacion := FConfiguracion.NumeroOperacion;
  FCabecera := FConfiguracion.Repositorio.ObtenerCabeceraTicket(FContexto);
  if not FCabecera.Encontrada then
    raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  FFechaOperacion := FCabecera.FechaOperacion;
  if (Frac(FFechaOperacion) = 0) and
     (FCabecera.InstanteAlta <> 0) then
    FFechaOperacion := Trunc(FFechaOperacion) +
      Frac(FCabecera.InstanteAlta);
  FTieneFactura := (FCabecera.SerieFactura <> '') and
    (FCabecera.NumeroFactura <> '');
  FDocumentoFactura := FormatearDocumento(
    FCabecera.FormatoDocumento,
    FCabecera.SerieFactura,
    FCabecera.NumeroFactura);
  FTextoQr := '';
  // El SII no lleva QR tributario (FZ-ISSUE-293)
  if QrTributarioActivo(FConfiguracion.ParametrosApp) and
     FTieneFactura then
    FTextoQr := ConstruirUrlQR(
      FConfiguracion.ParametrosApp,
      FCabecera.NifEmpresaFactura,
      FCabecera.FormatoDocumento,
      FCabecera.SerieFactura,
      FCabecera.NumeroFactura,
      FCabecera.FechaFactura,
      FCabecera.ImporteVerifactu);
end;

procedure TGeneradorTicketVenta.EscribirQr;
begin
  if FTextoQr <> '' then
  begin
    FTicket.Alinear(alCentro);
    FTicket.SaltarLineas(1);
    FTicket.EscribirLinea('QR tributario:');
    FTicket.ImprimirQRNativo(FTextoQr, 6, 49);
    if VerifactuActivo(FConfiguracion.ParametrosApp) then
    begin
      FTicket.EscribirLinea('VERI*FACTU - Factura verificable');
      FTicket.EscribirLinea('en la sede electrónica de la AEAT');
    end;
    FTicket.Alinear(alIzquierda);
  end;
end;

procedure TGeneradorTicketVenta.EscribirIdentificacion;
var
  oReferencia: TReferenciaRectificacionTicket;
  sLinea: string;
begin
  FTicket.SaltarLineas(1);
  FTicket.Negrita(True);
  if FTieneFactura then
    FTicket.EscribirLinea(
      FormatearTituloFacturaCaja(
        FCabecera.TipoFactura, FDocumentoFactura))
  else
    FTicket.EscribirLinea(
      Format(
        STicketOperacionNumero,
        [FConfiguracion.NumeroOperacion]));
  FTicket.Negrita(False);
  // FZ-ISSUE-200: misma referencia que en la impresion inmediata.
  if FTieneFactura then
  begin
    oReferencia :=
      FConfiguracion.Repositorio.ObtenerReferenciaRectificacionTicket(
        FCabecera.SerieFactura,
        FCabecera.NumeroFactura);
    for sLinea in LineasReferenciaRectificacion(
      oReferencia, FCabecera.FormatoDocumento, N_CHAR_LIN) do
      FTicket.EscribirLinea(sLinea);
  end;
  FTicket.SaltarLineas(1);
end;

procedure TGeneradorTicketVenta.EscribirEmpresa;
begin
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea(FCabecera.RazonSocialEmpresa);
  FTicket.EscribirLinea(FCabecera.DireccionEmpresa);
  FTicket.EscribirLinea(
    FCabecera.CodigoPostalEmpresa + ' ' + FCabecera.PoblacionEmpresa);
  FTicket.EscribirLinea(
    Format(STicketCifNif, [FCabecera.NifEmpresaFactura]));
  if Trim(FCabecera.MovilEmpresa) <> '' then
    FTicket.EscribirLinea(
      Format(STicketTelefono, [FCabecera.MovilEmpresa]));
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alIzquierda);
  FTicket.TextoColumnas(
    STicketEtiquetaOperacionNumero,
    FConfiguracion.NumeroOperacion);
  FTicket.SaltarLineas(1);
  FTicket.TextoColumnas(
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaOperacion),
    Format(
      STicketFormatoTienda,
      [LPAD(FConfiguracion.CodigoEmpresa, 3),
       LPAD(FConfiguracion.CodigoAlmacen, 3),
       LPAD(FConfiguracion.CodigoCaja, 2)]));
end;

procedure TGeneradorTicketVenta.EscribirLineas;
var
  i: Integer;
  sCantidad: string;
  sTotal: string;
  sDescuento: string;
  oLineas: TArray<TLineaTicketCaja>;
begin
  if FTieneFactura then
  begin
    FTicket.LineaSeparadora('-');
    FTicket.EscribirLinea(STicketCabeceraArticulos);
    FTicket.LineaSeparadora('-');
    oLineas := FConfiguracion.Repositorio.ListarLineasTicket(
      FCabecera.SerieFactura,
      FCabecera.NumeroFactura);
    oLineas := AgruparLotesTicket(oLineas, FConfiguracion.ImprimirLotes);
    for i := 0 to High(oLineas) do
    begin
      if Assigned(FConfiguracion.Unidades) then
        sCantidad := FConfiguracion.Unidades.Formatear(
          oLineas[i].Cantidad,
          oLineas[i].TipoCantidad)
      else
        sCantidad := FormatFloat('0', oLineas[i].Cantidad);
      sCantidad := CantidadConTipo(
        Format('%4s', [sCantidad]),
        oLineas[i].TipoCantidad);
      sTotal := FormatFloat('#,##0.00', oLineas[i].Total) + ' €';
      FTicket.TextoColumnas(
        ColumnaArticuloTicket(
          oLineas[i].CodigoUnidad,
          sCantidad,
          sTotal),
        sTotal);
      FTicket.EscribirLinea(Copy(oLineas[i].Descripcion, 1, 42));
      sDescuento := TextoPrecioUnidadTicket(oLineas[i].ContenidoPrecio,
        oLineas[i].Total, oLineas[i].Cantidad);
      if sDescuento <> '' then
        FTicket.EscribirLinea(sDescuento);
      sDescuento := TextoDescuentoTicket(oLineas[i].PrecioSalida,
        oLineas[i].PorcentajeDescuento, oLineas[i].ImporteDescuento);
      if sDescuento <> '' then
        FTicket.EscribirLinea(sDescuento);
      // F-LOTEC-015: lote o serie bajo la línea (solo con interruptores).
      if ActivacionVigente.AlgunModoActivo and (oLineas[i].Lote <> '') then
        FTicket.EscribirLinea(Copy(TextoLoteTicket(oLineas[i].Lote,
          oLineas[i].FechaCaducidad, oLineas[i].EsSerie), 1, 42));
    end;
    FTicket.LineaSeparadora('-');
    FTicket.SaltarLineas(1);
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketAPagar,
      FormatFloat('#,##0.00', FCabecera.TotalLiquido) + ' €');
    FTicket.Negrita(False);
  end;
end;

procedure TGeneradorTicketVenta.EscribirPagos;
var
  dTotalCambio: Currency;
  i: Integer;
  oPagos: TArray<TPagoTicketCaja>;
begin
  FTicket.Alinear(alIzquierda);
  FTicket.Negrita(True);
  dTotalCambio := 0;
  oPagos := FConfiguracion.Repositorio.ListarPagosTicket(FContexto);
  for i := 0 to High(oPagos) do
  begin
    dTotalCambio := dTotalCambio + oPagos[i].ImporteCambio;
    // FZ-ISSUE-200: mismo formato que la impresion inmediata.
    if oPagos[i].ImporteEntregado <> 0 then
      FTicket.TextoColumnas(
        UpperCase(oPagos[i].DescripcionFormaPago),
        FormatFloat('#,##0.00', oPagos[i].ImporteEntregado) + ' €');
  end;
  if dTotalCambio > 0 then
    FTicket.TextoColumnas(
      STicketCambioEfectivo,
      FormatFloat('#,##0.00', dTotalCambio) + ' €');
  FTicket.Negrita(False);
end;

procedure TGeneradorTicketVenta.EscribirVales;
var
  i: Integer;
  oVales: TArray<TValeTicketCaja>;
begin
  oVales := FConfiguracion.Repositorio.ListarValesTicket(FContexto);
  for i := 0 to High(oVales) do
  begin
    FTicket.SaltarLineas(1);
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketValeEmitidoFavor,
      FormatFloat('#,##0.00', oVales[i].ImporteNominal) + ' €');
    if Length(STicketCodigoValeEmitidoEspacio + oVales[i].Codigo) <= 42 then
      FTicket.TextoColumnas(
        STicketCodigoValeEmitidoEspacio,
        oVales[i].Codigo)
    else
    begin
      FTicket.EscribirLinea(STicketCodigoValeEmitido);
      FTicket.EscribirLinea(oVales[i].Codigo);
    end;
    if oVales[i].Pin <> '' then
      FTicket.TextoColumnas(STicketPinValeEmitidoEspacio, oVales[i].Pin);
    FTicket.Negrita(False);
  end;
end;

procedure TGeneradorTicketVenta.EscribirImpuestos;
begin
  FTicket.SaltarLineas(1);
  // FZ-ISSUE-200: una rectificativa tiene bases e IVA negativos.
  // FZ-ISSUE-335: los cuatro tipos, no solo el normal y el reducido.
  if FTieneFactura then
    EscribirDesgloseIvaTicket(FTicket, TramosIvaTicket(
      ImportesIvaTicket(FCabecera.BaseIvaNormal, FCabecera.TotalIvaNormal,
        FCabecera.PorcentajeIvaNormal, FCabecera.TotalReNormal,
        FCabecera.PorcentajeReNormal),
      ImportesIvaTicket(FCabecera.BaseIvaReducido,
        FCabecera.TotalIvaReducido, FCabecera.PorcentajeIvaReducido,
        FCabecera.TotalReReducido, FCabecera.PorcentajeReReducido),
      ImportesIvaTicket(FCabecera.BaseIvaSuperreducido,
        FCabecera.TotalIvaSuperreducido,
        FCabecera.PorcentajeIvaSuperreducido,
        FCabecera.TotalReSuperreducido,
        FCabecera.PorcentajeReSuperreducido),
      ImportesIvaTicket(FCabecera.BaseIvaExento, FCabecera.TotalIvaExento,
        FCabecera.PorcentajeIvaExento, FCabecera.TotalReExento,
        FCabecera.PorcentajeReExento)));
end;

procedure TGeneradorTicketVenta.EscribirPie;
begin
  FTicket.SaltarLineas(2);
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea(
    Format(STicketLeAtendio, [FCabecera.DiminutivoVendedor]));
  FTicket.EscribirLinea(STicketIvaIncluido);
  FTicket.EscribirLinea(STicketGraciasVisita);
  if Trim(FCabecera.TextoLegalEmpresa) <> '' then
  begin
    FTicket.SaltarLineas(1);
    FTicket.EscribirLinea(FCabecera.TextoLegalEmpresa);
  end;
  EscribirPieTicket(
    FTicket,
    FConfiguracion.Repositorio.ListarPieTicket(
      FConfiguracion.CodigoEmpresa));
end;

procedure TGeneradorTicketVenta.EscribirCodigoBarras;
var
  sCodigoBarras: string;
begin
  if FConfiguracion.ImprimirCodigoBarras and FTieneFactura then
  begin
    sCodigoBarras :=
      FConfiguracion.Repositorio.ObtenerCodigoBarrasTicket(
        FCabecera.SerieFactura,
        FCabecera.NumeroFactura);
    if sCodigoBarras <> '' then
    begin
      FTicket.SaltarLineas(1);
      FTicket.ImprimirEAN13Nativo(sCodigoBarras);
    end;
  end;
end;

procedure TGeneradorTicketVenta.GenerarSalida;
var
  sComandosEsc: string;
  sRutaFicheroPdf: string;
begin
  FTicket.AvanzarYCortarPapel;
  FTicket.AbrirCajon;
  sComandosEsc := FTicket.ObtenerComandos;
  sRutaFicheroPdf := GetUserFolderTickets + 'TicketBD_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
  ImprimirOPrevisualizarTicket(
    FConfiguracion.Preview,
    FTicket,
    sComandosEsc,
    sRutaFicheroPdf,
    FConfiguracion.NombreImpresora,
    FConfiguracion.SoloPDF);
  if (FConfiguracion.RutasPDF <> nil) and
     FileExists(sRutaFicheroPdf) then
    FConfiguracion.RutasPDF.Add(sRutaFicheroPdf);
end;

procedure TGeneradorTicketVenta.Ejecutar;
begin
  CargarDatos;
  FProteccionIdioma := ProtegerDocumentoVentaEspanol;
  FTicket.Inicializar;
  EscribirQr;
  EscribirIdentificacion;
  EscribirEmpresa;
  EscribirLineas;
  EscribirPagos;
  EscribirVales;
  EscribirImpuestos;
  EscribirPie;
  EscribirCodigoBarras;
  GenerarSalida;
end;

procedure ImprimirResguardoDeposito(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioResguardosCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean;
  AImprimirCodigoBarras: Boolean);
var
  oGenerador: TGeneradorResguardoDeposito;
begin
  if (Trim(AOperacion) <> '') and Assigned(ARepositorio) then
  begin
    oGenerador := TGeneradorResguardoDeposito.Create(
      APreview,
      ARepositorio,
      ACodigoEmpresa,
      ACodigoAlmacen,
      ACodigoCaja,
      AOperacion,
      ANombreImpresora,
      ARutasPDF,
      ASoloPDF);
    try
      oGenerador.ImprimirCodigoBarras := AImprimirCodigoBarras;
      oGenerador.Ejecutar;
    finally
      FreeAndNil(oGenerador);
    end;
  end;
end;

procedure ImprimirTicketDesdeBD(
  const AParametrosApp: IParametrosAplicacion;
  const APreview: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorio: IRepositorioTicketsVentaCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  ANumeroOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean;
  AImprimirCodigoBarras: Boolean;
  AImprimirLotes: Boolean);
var
  oConfiguracion: TConfiguracionTicketVenta;
  oGenerador: TGeneradorTicketVenta;
begin
  oConfiguracion := Default(TConfiguracionTicketVenta);
  oConfiguracion.ParametrosApp := AParametrosApp;
  oConfiguracion.Preview := APreview;
  oConfiguracion.Unidades := AUnidades;
  oConfiguracion.Repositorio := ARepositorio;
  oConfiguracion.CodigoEmpresa := ACodigoEmpresa;
  oConfiguracion.CodigoAlmacen := ACodigoAlmacen;
  oConfiguracion.CodigoCaja := ACodigoCaja;
  oConfiguracion.NumeroOperacion := ANumeroOperacion;
  oConfiguracion.NombreImpresora := ANombreImpresora;
  oConfiguracion.RutasPDF := ARutasPDF;
  oConfiguracion.SoloPDF := ASoloPDF;
  oConfiguracion.ImprimirCodigoBarras := AImprimirCodigoBarras;
  oConfiguracion.ImprimirLotes := AImprimirLotes;
  oGenerador := TGeneradorTicketVenta.Create(oConfiguracion);
  try
    oGenerador.Ejecutar;
  finally
    FreeAndNil(oGenerador);
  end;
end;

procedure ImprimirRecordatorio(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioRecordatoriosCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
begin
  ImprimirRecordatorioTicket(
    APreview,
    ARepositorio,
    ACodigoEmpresa,
    ACodigoCliente,
    ANombreImpresora,
    ARutasPDF,
    ASoloPDF);
end;

end.

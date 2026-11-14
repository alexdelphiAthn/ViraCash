{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTiraCajaTicket                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera e imprime la "tira de caja": una tira térmica con el desglose de   }
{    las operaciones entre dos fechas para una empresa / almacén / caja. Las   }
{    ventas facturadas llevan nº de factura, nº de operación, fecha, líneas y  }
{    formas de pago. De forma opcional adjunta los traspasos salientes, los    }
{    ingresos por caja, los gastos por caja y las ventas a crédito (depósitos).}
{                                                                              }
{    Las ventas pueden acotarse a varias series de factura simplificada        }
{    (ASeries; vacío = todas). El agrupamiento (ACronologico) decide el orden: }
{    por tipo de documento (secciones con doble línea al romper el tipo) o por }
{    orden cronológico (operaciones intercaladas, cada una rotulada con su     }
{    tipo). En ambos modos hay una línea simple tras cada operación.           }
{                                                                              }
{    Si AImprimirQR es True y Verifactu está activo (envío PRE o PRO), añade   }
{    el QR tributario de cada venta. Si la impresora es 'DEBUG' abre el        }
{    preview (TFormVisualizador) en vez de mandar a la impresora física.       }
{******************************************************************************}
unit inLibTiraCajaTicket;

interface

uses
  System.SysUtils, System.Classes,
  inLibFTicket, inLibParametrosIntf,
  inLibTiraCajaTicketIntf, inLibPreviewExcel,
  inLibPreviewTicket;

type
  TTiraCajaTicket = class
  private
    class function FmtImp(AValor: Currency): string;
    class function LPad(const AValor: string; ALongitud: Integer): string;
    class function CentrarRelleno(const ATexto: string;
                                  ARelleno: Char): string;
    class procedure EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioTiraCajaTicket;
                                            const AEmpresa: string);
    class procedure EscribirLineasArticulos(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioTiraCajaTicket;
                                            const AEmpresa, AAlmacen,
                                                  ACaja, AOperacion: string);
    class procedure EscribirFormasPago(ATicket: TTicketTermico;
                                       const ARepositorio:
                                       IRepositorioTiraCajaTicket;
                                       const AEmpresa, AAlmacen,
                                             ACaja, AOperacion: string);
    class procedure EscribirOperacion(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      ATicket: TTicketTermico;
                                      const ARepositorio:
                                      IRepositorioTiraCajaTicket;
                                      const AOperacion:
                                      TOperacionTiraCaja;
                                      AImprimirQR: Boolean);
    // Render de una operación de traspaso saliente (cursor maestro
    // posicionado):
    // cabecera (referencia + fecha) + almacén destino + detalle de artículos
    // (SKU, descripción, cantidad) de fza_movimientos_almacen. Con AValorar
    // (permiso caja.verCoste) añade el coste por línea y el total a coste, que
    // además devuelve.
    class function EscribirTraspasoOpe(ATicket: TTicketTermico;
                                       const ARepositorio:
                                       IRepositorioTiraCajaTicket;
                                       const AOperacion:
                                       TOperacionTiraCaja;
                                       AValorar: Boolean): Currency;
    // Render de una operación de ingreso (EC) o gasto (GC): referencia + fecha
    // + importe y el concepto. Devuelve el importe de la operación.
    class function EscribirIngresoGastoOpe(ATicket: TTicketTermico;
                                           const AOperacion:
                                           TOperacionTiraCaja): Currency;
    // Render de una operación de depósito (DE = venta a crédito): por cada
    // depósito ligado a la operación, el cliente, el artículo (SKU +
    // descripción), la valoración (precio x cantidad), lo entregado a cuenta
    // (cobro del cliente) y el pendiente. Devuelve el total vendido y, en
    // ACobrado, lo entregado a cuenta.
    class function EscribirDepositoOpe(ATicket: TTicketTermico;
                                       const ARepositorio:
                                       IRepositorioTiraCajaTicket;
                                       const AOperacion:
                                       TOperacionTiraCaja;
                                       out ACobrado: Currency): Currency;
  public
    // Series facturadas distintas en el rango para la caja (para preguntar
    // la serie cuando hay más de una). Devuelve [] si no hay operaciones.
    class function ObtenerSeries(
                                 const ARepositorio:
                                 IRepositorioTiraCajaTicket;
                                 const AEmpresa, AAlmacen, ACaja: string;
                                 AFechaDesde, AFechaHasta: TDate)
                                 : TArray<string>;
    class procedure Imprimir(
                             const AParametrosApp: IParametrosAplicacion;
                             const APreview: IPreviewTicket;
                             const ARepositorio:
                             IRepositorioTiraCajaTicket;
                             const AEmpresa, AAlmacen, ACaja: string;
                             AFechaDesde, AFechaHasta: TDate;
                             const ASeries: TArray<string>;
                             AImprimirQR: Boolean = False;
                             const ANombreImpresora: string = 'DEBUG';
                             ACronologico: Boolean = False;
                             AIncluirTraspasos: Boolean = False;
                             AIncluirIngresos: Boolean = False;
                             AIncluirGastos: Boolean = False;
                             AIncluirCredito: Boolean = False;
                             AValorarTraspasos: Boolean = False);
    // Vuelca las mismas operaciones de la tira a una hoja de cálculo y la abre
    // en el visor de Excel (TfrmMtoPreviewExcel), con detalle por línea y el
    // mismo orden / agrupamiento que la impresión.
    class procedure ExportarExcel(
                                  AOwner: TComponent;
                                  const AProveedorPreview:
                                  IProveedorPreviewExcel;
                                  const ARepositorio:
                                  IRepositorioTiraCajaTicket;
                                  const AEmpresa, AAlmacen, ACaja: string;
                                  AFechaDesde, AFechaHasta: TDate;
                                  const ASeries: TArray<string>;
                                  ACronologico: Boolean = False;
                                  AIncluirTraspasos: Boolean = False;
                                  AIncluirIngresos: Boolean = False;
                                  AIncluirGastos: Boolean = False;
                                  AIncluirCredito: Boolean = False;
                                  AValorarTraspasos: Boolean = False);
  end;

implementation

uses
  Vcl.Forms,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetGraphics,
  dxSpreadSheetTypes, dxSpreadSheetStyles, dxHashUtils,
  inLibDir, inLibFormatoDocumento, inLibVerifactu,
  inLibDevExcel,
  inLibMsgTickets, inLibMsgCaja;

type
  TImpresorTiraCajaTicket = class
  private
    FParametrosApp    : IParametrosAplicacion;
    FPreview          : IPreviewTicket;
    FRepositorio      : IRepositorioTiraCajaTicket;
    FEmpresa          : string;
    FAlmacen          : string;
    FCaja             : string;
    FFechaDesde       : TDate;
    FFechaHasta       : TDate;
    FSeries           : TArray<string>;
    FImprimirQR       : Boolean;
    FNombreImpresora  : string;
    FCronologico      : Boolean;
    FIncluirTraspasos : Boolean;
    FIncluirIngresos  : Boolean;
    FIncluirGastos    : Boolean;
    FIncluirCredito   : Boolean;
    FVerCoste         : Boolean;
    FTicket           : TTicketTermico;
    FGrupoAnterior    : string;
    FNumeroVentas     : Integer;
    FNumeroTraspasos  : Integer;
    FNumeroPerdidas: Integer;
    FNumeroIngresos   : Integer;
    FNumeroGastos     : Integer;
    FNumeroDepositos  : Integer;
    FTotalVentas      : Currency;
    FTotalTraspasos   : Currency;
    FTotalPerdidas: Currency;
    FTotalIngresos    : Currency;
    FTotalGastos      : Currency;
    FTotalDepositos   : Currency;
    FTotalCobrado     : Currency;
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const APreview: IPreviewTicket;
      const ARepositorio: IRepositorioTiraCajaTicket;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate;
      const ASeries: TArray<string>;
      AImprimirQR: Boolean;
      const ANombreImpresora: string;
      ACronologico, AIncluirTraspasos, AIncluirIngresos,
        AIncluirGastos, AIncluirCredito, AValorarTraspasos: Boolean);
    function RotuloGrupo(const AGrupo: string): string;
    function NumeroOperaciones: Integer;
    procedure InicializarAcumuladores;
    procedure EscribirCabecera;
    procedure EscribirCabeceraGrupo(const AGrupo: string);
    procedure EscribirSubtotalGrupo(const AGrupo: string);
    procedure RenderizarOperacion(
      const AOperacion: TOperacionTiraCaja);
    procedure EscribirOperaciones;
    procedure EscribirCierre;
    procedure Emitir;
  public
    procedure Ejecutar;
  end;

// =============================================================================
//   Helpers de formato
// =============================================================================

class function TTiraCajaTicket.FmtImp(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

class function TTiraCajaTicket.LPad(const AValor: string;
                                    ALongitud: Integer): string;
begin
  if Length(AValor) >= ALongitud then
    Result := AValor
  else
    Result := StringOfChar('0', ALongitud - Length(AValor)) + AValor;
end;

// Centra ATexto en N_CHAR_LIN columnas rellenando ambos lados con ARelleno,
// como en el ejemplo del nº de factura: _____Nº Fac.: 2026.CE.004227_____
class function TTiraCajaTicket.CentrarRelleno(const ATexto: string;
                                              ARelleno: Char): string;
var
  iLibre, iIzq: Integer;
begin
  if Length(ATexto) >= N_CHAR_LIN then
    Result := ATexto
  else
  begin
    iLibre := N_CHAR_LIN - Length(ATexto);
    iIzq   := iLibre div 2;
    Result := StringOfChar(ARelleno, iIzq) + ATexto +
              StringOfChar(ARelleno, iLibre - iIzq);
  end;
end;

// =============================================================================
//   Cabecera de empresa
// =============================================================================

class procedure TTiraCajaTicket.EscribirCabeceraEmpresa(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa: string);
var
  oEmpresa: TEmpresaTiraCajaTicket;
begin
  oEmpresa := ARepositorio.ObtenerEmpresa(
    AEmpresa);
  if oEmpresa.Encontrada then
  begin
    ATicket.Alinear(alCentro);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(oEmpresa.RazonSocial);
    ATicket.Negrita(False);
    ATicket.EscribirLinea(oEmpresa.Direccion);
    ATicket.EscribirLinea(
      Trim(oEmpresa.CodigoPostal + ' ' + oEmpresa.Poblacion));
    ATicket.EscribirLinea(oEmpresa.Provincia);
    ATicket.EscribirLinea(
      Format(STicketCif, [oEmpresa.Nif]));
  end;
end;

// =============================================================================
//   Líneas de artículos y formas de pago de una operación
// =============================================================================

class procedure TTiraCajaTicket.EscribirLineasArticulos(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string);
var
  aLineas: TArray<TLineaVentaTiraCaja>;
  oLinea: TLineaVentaTiraCaja;
  sSku, sDesc, sIzq, sTot: string;
  dCant: Double;
  iMax: Integer;
begin
  aLineas := ARepositorio.ListarLineasVenta(
    AEmpresa,
    AAlmacen,
    ACaja,
    AOperacion);
  for oLinea in aLineas do
  begin
    sSku := Trim(oLinea.CodigoUnidad);
    sDesc := Trim(oLinea.Descripcion);
    dCant := oLinea.Cantidad;
    sTot := FmtImp(oLinea.Total);
    // Línea 1: SKU, cantidad opcional e importe.
    if dCant <> 1 then
      sIzq := FormatFloat('0.##', dCant) + 'x ' + sSku
    else
      sIzq := sSku;
    iMax := N_CHAR_LIN - Length(sTot) - 1;
    if Length(sIzq) > iMax then
      sIzq := Copy(sIzq, 1, iMax);
    ATicket.TextoColumnas(sIzq, sTot);
    if sDesc <> '' then
      ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
  end;
end;

class procedure TTiraCajaTicket.EscribirFormasPago(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string);
var
  aFormasPago: TArray<TFormaPagoTiraCaja>;
  oFormaPago: TFormaPagoTiraCaja;
  dCambio: Currency;
begin
  dCambio := 0;
  aFormasPago := ARepositorio.ListarFormasPago(
    AEmpresa,
    AAlmacen,
    ACaja,
    AOperacion);
  for oFormaPago in aFormasPago do
  begin
    dCambio := dCambio + oFormaPago.ImporteCambio;
    if oFormaPago.ImporteEntregado <> 0 then
      ATicket.TextoColumnas(
        UpperCase(Trim(oFormaPago.Descripcion)),
        FmtImp(oFormaPago.ImporteEntregado));
  end;
  if dCambio > 0 then
    ATicket.TextoColumnas(STicketCambio, FmtImp(dCambio));
end;

// =============================================================================
//   Bloque de una operación (cursor AOpe posicionado en la fila)
// =============================================================================

class procedure TTiraCajaTicket.EscribirOperacion(
  const AParametrosApp: IParametrosAplicacion;
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AOperacion: TOperacionTiraCaja;
  AImprimirQR: Boolean);
var
  sEmp, sAlm, sCaja, sOpe, sSerie, sNumFac, sNif, sQR: string;
  dFechaOpe, dFechaFac: TDateTime;
  dLiquido: Currency;
begin
  sEmp := AOperacion.Empresa;
  sAlm := AOperacion.Almacen;
  sCaja := AOperacion.Caja;
  sOpe := AOperacion.NumeroOperacion;
  dFechaOpe := AOperacion.FechaOperacion;
  sSerie := AOperacion.SerieFactura;
  sNumFac := AOperacion.NumeroFactura;
  dLiquido := AOperacion.TotalLiquido;
  dFechaFac := AOperacion.FechaFactura;
  sNif := AOperacion.NifEmpresaFactura;
  // Separador con el nº de factura formateado según la empresa.
  ATicket.Alinear(alIzquierda);
  ATicket.EscribirLinea(
    CentrarRelleno(
      Format(
        STicketNumeroFactura,
        [FormatearDocumento(
           AOperacion.FormatoDocumento,
           sSerie,
           sNumFac)]),
      '_'));
  // Operación, fecha/hora, empresa y Tda.almacén-caja.
  ATicket.EscribirLinea(
    Format(
      '%s %s %s',
      [sOpe,
       FormatDateTime('dd/mm/yy hh:nn:ss', dFechaOpe),
       Format(
         STicketFormatoTienda,
         [LPad(sEmp, 3),
          LPad(sAlm, 3),
          LPad(sCaja, 2)])]));
  // Líneas del ticket con su precio.
  EscribirLineasArticulos(
    ATicket,
    ARepositorio,
    sEmp,
    sAlm,
    sCaja,
    sOpe);
  // Total de la operación y formas de pago.
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketAPagar, FmtImp(dLiquido));
  ATicket.Negrita(False);
  EscribirFormasPago(
    ATicket,
    ARepositorio,
    sEmp,
    sAlm,
    sCaja,
    sOpe);
  // QR tributario por operación si Verifactu está activo y se ha pedido.
  // El SII no lleva QR (FZ-ISSUE-293).
  if AImprimirQR and QrTributarioActivo(AParametrosApp)
     and (Trim(sSerie) <> '') and (Trim(sNumFac) <> '') then
  begin
    sQR := ConstruirUrlQR(AParametrosApp, sNif,
      AOperacion.FormatoDocumento, sSerie, sNumFac,
      dFechaFac, AOperacion.ImporteVerifactu);
    if sQR <> '' then
    begin
      ATicket.Alinear(alCentro);
      // Nivel de corrección M (49) exigido por la AEAT para el QR.
      ATicket.ImprimirQRNativo(sQR, 6, 49);
      ATicket.Alinear(alIzquierda);
    end;
  end;
end;

// =============================================================================
//   Render por operación (traspaso / ingreso-gasto / depósito)
// =============================================================================

class function TTiraCajaTicket.EscribirIngresoGastoOpe(
  ATicket: TTicketTermico;
  const AOperacion: TOperacionTiraCaja): Currency;
var
  sRef, sConcepto: string;
  iMax: Integer;
begin
  Result := AOperacion.ImporteTotal;
  sConcepto := Trim(AOperacion.ConceptoGastoIngreso);
  // Fila 1: referencia (nº op + fecha) e importe a la derecha.
  sRef := Format(
    STicketOperacionCorta,
    [AOperacion.NumeroOperacion]) + ' ' +
    FormatDateTime(
      'dd/mm/yy hh:nn',
      AOperacion.FechaOperacion);
  iMax := N_CHAR_LIN - Length(FmtImp(Result)) - 1;
  if Length(sRef) > iMax then
    sRef := Copy(sRef, 1, iMax);
  ATicket.TextoColumnas(sRef, FmtImp(Result));
  // Fila 2: concepto descriptivo (gasto / ingreso), recortado.
  if sConcepto <> '' then
    ATicket.EscribirLinea(Copy(sConcepto, 1, N_CHAR_LIN));
end;

class function TTiraCajaTicket.EscribirTraspasoOpe(ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AOperacion: TOperacionTiraCaja;
  AValorar: Boolean): Currency;
var
  aLineas: TArray<TLineaTraspasoTiraCaja>;
  oLinea: TLineaTraspasoTiraCaja;
  iMax: Integer;
  sEmp, sAlm, sCaja, sOpe, sRef, sDestino, sSku, sDesc, sIzq: string;
  dCantidad, dCosteUnit: Double;
begin
  Result := 0;
  sEmp := AOperacion.Empresa;
  sAlm := AOperacion.Almacen;
  sCaja := AOperacion.Caja;
  sOpe := AOperacion.NumeroOperacion;
  sDestino := Trim(AOperacion.AlmacenContrapartida);
  // Referencia: documento formateado si lo tiene; si no, nº de operación.
  sRef := Trim(AOperacion.SerieFactura);
  if (sRef <> '') and
     (Trim(AOperacion.NumeroFactura) <> '') then
    sRef := FormatearDocumento(
      AOperacion.FormatoDocumento,
      sRef,
      AOperacion.NumeroFactura)
  else
    sRef := Format(STicketOperacionCorta, [sOpe]);
  if AOperacion.Grupo = 'PER' then
    ATicket.EscribirLinea(STicketPerdidaTransito + ' (TP)');
  ATicket.Negrita(True);
  ATicket.EscribirLinea(sRef + ' ' +
    FormatDateTime('dd/mm/yy hh:nn',
      AOperacion.FechaOperacion));
  ATicket.Negrita(False);
  if sDestino <> '' then
    if AOperacion.Grupo = 'PER' then
      ATicket.TextoColumnas(STicketOrigen, sDestino)
    else
      ATicket.EscribirLinea('  -> ' + sDestino);
  aLineas := ARepositorio.ListarLineasTraspaso(
    sEmp,
    sAlm,
    sCaja,
    sOpe);
  for oLinea in aLineas do
  begin
    sSku := Trim(oLinea.CodigoUnidad);
    sDesc := Trim(oLinea.Descripcion);
    dCantidad := oLinea.Cantidad;
    dCosteUnit := oLinea.PrecioCosteUnitario;
    sIzq := FormatFloat('0.##', dCantidad) + 'x ' + sSku;
    if AValorar then
    begin
      iMax := N_CHAR_LIN - Length(FmtImp(dCantidad * dCosteUnit)) - 1;
      if Length(sIzq) > iMax then
        sIzq := Copy(sIzq, 1, iMax);
      ATicket.TextoColumnas(sIzq, FmtImp(dCantidad * dCosteUnit));
    end
    else
      ATicket.EscribirLinea(Copy(sIzq, 1, N_CHAR_LIN));
    if sDesc <> '' then
      ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
    Result := Result + dCantidad * dCosteUnit;
  end;
  if AValorar then
  begin
    ATicket.Negrita(True);
    if AOperacion.Grupo = 'PER' then
      ATicket.TextoColumnas(STicketTotalPerdidaCoste, FmtImp(Result))
    else
      ATicket.TextoColumnas(STicketTotalTraspasoCoste, FmtImp(Result));
    ATicket.Negrita(False);
  end;
end;

class function TTiraCajaTicket.EscribirDepositoOpe(ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AOperacion: TOperacionTiraCaja;
  out ACobrado: Currency): Currency;
var
  aDepositos: TArray<TDepositoTiraCaja>;
  oDeposito: TDepositoTiraCaja;
  iMax: Integer;
  sEmp, sAlm, sCaja, sOpe, sCli, sCliNom, sSku, sDesc, sIzq: string;
  dCantidad: Double;
  dPrecio, dTotal, dAnticipo, dPendiente: Currency;
begin
  Result := 0;
  ACobrado := 0;
  sEmp := AOperacion.Empresa;
  sAlm := AOperacion.Almacen;
  sCaja := AOperacion.Caja;
  sOpe := AOperacion.NumeroOperacion;
  // Cabecera del depósito: referencia de operación + fecha.
  ATicket.Negrita(True);
  ATicket.EscribirLinea(Format(STicketOperacionCorta, [sOpe]) + ' ' +
    FormatDateTime('dd/mm/yy hh:nn',
      AOperacion.FechaOperacion));
  ATicket.Negrita(False);
  aDepositos := ARepositorio.ListarDepositos(
    sEmp,
    sAlm,
    sCaja,
    sOpe);
  for oDeposito in aDepositos do
  begin
    sCli := Trim(oDeposito.CodigoCliente);
    sCliNom := Trim(oDeposito.Cliente);
    sSku := Trim(oDeposito.CodigoUnidad);
    sDesc := Trim(oDeposito.Descripcion);
    dPrecio := oDeposito.PrecioVenta;
    dCantidad := oDeposito.Cantidad;
    dAnticipo := oDeposito.ImporteAnticipo;
    dTotal := dPrecio * dCantidad;
    dPendiente := dTotal - dAnticipo;
    ATicket.EscribirLinea(
      Copy(
        Format(
          STicketClienteCorto,
          [Trim(sCli + ' ' + sCliNom)]),
        1,
        N_CHAR_LIN));
    sIzq := FormatFloat('0.##', dCantidad) + 'x ' + sSku;
    iMax := N_CHAR_LIN - Length(FmtImp(dTotal)) - 1;
    if Length(sIzq) > iMax then
      sIzq := Copy(sIzq, 1, iMax);
    ATicket.TextoColumnas(sIzq, FmtImp(dTotal));
    if sDesc <> '' then
      ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
    if dAnticipo <> 0 then
      ATicket.TextoColumnas(STicketEntregadoCuenta, FmtImp(dAnticipo));
    ATicket.TextoColumnas(STicketPendienteSangrado, FmtImp(dPendiente));
    Result := Result + dTotal;
    ACobrado := ACobrado + dAnticipo;
  end;
end;

// =============================================================================
//   API pública
// =============================================================================

class function TTiraCajaTicket.ObtenerSeries(
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate): TArray<string>;
begin
  Result := ARepositorio.ListarSeries(
    AEmpresa,
    AAlmacen,
    ACaja,
    AFechaDesde,
    AFechaHasta);
end;

constructor TImpresorTiraCajaTicket.Create(
  const AParametrosApp: IParametrosAplicacion;
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate;
  const ASeries: TArray<string>;
  AImprimirQR: Boolean;
  const ANombreImpresora: string;
  ACronologico, AIncluirTraspasos, AIncluirIngresos,
    AIncluirGastos, AIncluirCredito, AValorarTraspasos: Boolean);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FPreview := APreview;
  FRepositorio := ARepositorio;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFechaDesde := AFechaDesde;
  FFechaHasta := AFechaHasta;
  FSeries := Copy(ASeries, 0, Length(ASeries));
  FImprimirQR := AImprimirQR;
  FNombreImpresora := ANombreImpresora;
  FCronologico := ACronologico;
  FIncluirTraspasos := AIncluirTraspasos;
  FIncluirIngresos := AIncluirIngresos;
  FIncluirGastos := AIncluirGastos;
  FIncluirCredito := AIncluirCredito;
  FVerCoste := AValorarTraspasos;
end;

function TImpresorTiraCajaTicket.RotuloGrupo(
  const AGrupo: string): string;
begin
  if AGrupo = 'TRA' then
    Result := STicketRotuloTraspaso
  else if AGrupo = 'PER' then
    Result := STicketPerdidas
  else if AGrupo = 'ING' then
    Result := STicketRotuloIngreso
  else if AGrupo = 'GAS' then
    Result := STicketRotuloGasto
  else if AGrupo = 'DEP' then
    Result := STicketRotuloDeposito
  else
    Result := STicketRotuloVenta;
end;

function TImpresorTiraCajaTicket.NumeroOperaciones: Integer;
begin
  Result := FNumeroVentas + FNumeroTraspasos + FNumeroPerdidas +
    FNumeroIngresos +
    FNumeroGastos + FNumeroDepositos;
end;

procedure TImpresorTiraCajaTicket.InicializarAcumuladores;
begin
  FGrupoAnterior := '';
  FNumeroVentas := 0;
  FNumeroTraspasos := 0;
  FNumeroPerdidas := 0;
  FNumeroIngresos := 0;
  FNumeroGastos := 0;
  FNumeroDepositos := 0;
  FTotalVentas := 0;
  FTotalTraspasos := 0;
  FTotalPerdidas := 0;
  FTotalIngresos := 0;
  FTotalGastos := 0;
  FTotalDepositos := 0;
  FTotalCobrado := 0;
end;

procedure TImpresorTiraCajaTicket.EscribirCabecera;
var
  i: Integer;
  sSeries: string;
begin
  TTiraCajaTicket.EscribirCabeceraEmpresa(
    FTicket, FRepositorio, FEmpresa);
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(Format(STicketArqueoCajaHora,
    [FCaja, FormatDateTime('hh:nn', Now)]));
  FTicket.EscribirLinea(Format(STicketDel,
    [FormatDateTime('dd/mm/yy hh:nn', FFechaDesde)]));
  FTicket.EscribirLinea(Format(STicketAl,
    [FormatDateTime('dd/mm/yy hh:nn', FFechaHasta)]));
  if Length(FSeries) = 0 then
    FTicket.EscribirLinea(STicketTodasSeries)
  else
  begin
    sSeries := '';
    for i := 0 to High(FSeries) do
    begin
      if sSeries <> '' then
        sSeries := sSeries + ', ';
      sSeries := sSeries + FSeries[i];
    end;
    FTicket.EscribirLinea(Format(STicketSeries, [sSeries]));
  end;
  if FCronologico then
    FTicket.EscribirLinea(STicketOrdenCronologico)
  else
    FTicket.EscribirLinea(STicketOrdenTipoDocumento);
  FTicket.Negrita(False);
  FTicket.Alinear(alIzquierda);
  FTicket.SaltarLineas(1);
end;

procedure TImpresorTiraCajaTicket.EscribirCabeceraGrupo(
  const AGrupo: string);
begin
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  if AGrupo = 'TRA' then
    FTicket.EscribirLinea(STicketTraspasosSalientes)
  else if AGrupo = 'PER' then
    FTicket.EscribirLinea(STicketPerdidasTransito)
  else if AGrupo = 'ING' then
    FTicket.EscribirLinea(STicketIngresosPorCaja)
  else if AGrupo = 'GAS' then
    FTicket.EscribirLinea(STicketGastosPorCaja)
  else if AGrupo = 'DEP' then
    FTicket.EscribirLinea(STicketVentasCreditoDepositos)
  else
    FTicket.EscribirLinea(STicketVentasFacturadas);
  FTicket.Negrita(False);
  FTicket.Alinear(alIzquierda);
end;

procedure TImpresorTiraCajaTicket.EscribirSubtotalGrupo(
  const AGrupo: string);
begin
  if AGrupo = 'TRA' then
  begin
    FTicket.TextoColumnas(
      STicketTraspasos, IntToStr(FNumeroTraspasos));
    if FVerCoste then
    begin
      FTicket.Negrita(True);
      FTicket.TextoColumnas(
        STicketSubtotalCoste, TTiraCajaTicket.FmtImp(FTotalTraspasos));
      FTicket.Negrita(False);
    end;
  end
  else if AGrupo = 'PER' then
  begin
    FTicket.TextoColumnas(STicketPerdidas, IntToStr(FNumeroPerdidas));
    if FVerCoste then
      FTicket.TextoColumnas(STicketSubtotalCoste,
        TTiraCajaTicket.FmtImp(FTotalPerdidas));
  end
  else if AGrupo = 'ING' then
  begin
    FTicket.TextoColumnas(STicketIngresos, IntToStr(FNumeroIngresos));
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketSubtotal, TTiraCajaTicket.FmtImp(FTotalIngresos));
    FTicket.Negrita(False);
  end
  else if AGrupo = 'GAS' then
  begin
    FTicket.TextoColumnas(STicketGastos, IntToStr(FNumeroGastos));
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketSubtotal, TTiraCajaTicket.FmtImp(FTotalGastos));
    FTicket.Negrita(False);
  end
  else if AGrupo = 'DEP' then
  begin
    FTicket.TextoColumnas(STicketDepositos, IntToStr(FNumeroDepositos));
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketSubtotalVenta, TTiraCajaTicket.FmtImp(FTotalDepositos));
    FTicket.Negrita(False);
    if FTotalCobrado <> 0 then
      FTicket.TextoColumnas(
        STicketSubtotalCobrado, TTiraCajaTicket.FmtImp(FTotalCobrado));
  end
  else
  begin
    FTicket.TextoColumnas(STicketOperaciones, IntToStr(FNumeroVentas));
    FTicket.Negrita(True);
    FTicket.TextoColumnas(
      STicketTotalVentasSinSigno, TTiraCajaTicket.FmtImp(FTotalVentas));
    FTicket.Negrita(False);
  end;
end;

procedure TImpresorTiraCajaTicket.RenderizarOperacion(
  const AOperacion: TOperacionTiraCaja);
var
  dCobrado: Currency;
begin
  if AOperacion.Grupo = 'TRA' then
  begin
    FTotalTraspasos := FTotalTraspasos +
      TTiraCajaTicket.EscribirTraspasoOpe(
        FTicket, FRepositorio, AOperacion, FVerCoste);
    Inc(FNumeroTraspasos);
  end
  else if AOperacion.Grupo = 'PER' then
  begin
    FTotalPerdidas := FTotalPerdidas +
      TTiraCajaTicket.EscribirTraspasoOpe(
        FTicket, FRepositorio, AOperacion, FVerCoste);
    Inc(FNumeroPerdidas);
  end
  else if AOperacion.Grupo = 'ING' then
  begin
    FTotalIngresos := FTotalIngresos +
      TTiraCajaTicket.EscribirIngresoGastoOpe(FTicket, AOperacion);
    Inc(FNumeroIngresos);
  end
  else if AOperacion.Grupo = 'GAS' then
  begin
    FTotalGastos := FTotalGastos +
      TTiraCajaTicket.EscribirIngresoGastoOpe(FTicket, AOperacion);
    Inc(FNumeroGastos);
  end
  else if AOperacion.Grupo = 'DEP' then
  begin
    FTotalDepositos := FTotalDepositos +
      TTiraCajaTicket.EscribirDepositoOpe(
        FTicket, FRepositorio, AOperacion, dCobrado);
    FTotalCobrado := FTotalCobrado + dCobrado;
    Inc(FNumeroDepositos);
  end
  else
  begin
    TTiraCajaTicket.EscribirOperacion(
      FParametrosApp, FTicket, FRepositorio, AOperacion, FImprimirQR);
    FTotalVentas := FTotalVentas + AOperacion.TotalLiquido;
    Inc(FNumeroVentas);
  end;
end;

procedure TImpresorTiraCajaTicket.EscribirOperaciones;
var
  aOperaciones: TArray<TOperacionTiraCaja>;
  Operacion: TOperacionTiraCaja;
  sGrupo: string;
begin
  aOperaciones := FRepositorio.ListarOperaciones(
    FEmpresa, FAlmacen, FCaja, FFechaDesde, FFechaHasta, FSeries,
    FCronologico, FIncluirTraspasos, FIncluirIngresos,
    FIncluirGastos, FIncluirCredito);
  for Operacion in aOperaciones do
  begin
    sGrupo := Operacion.Grupo;
    if FCronologico then
    begin
      FTicket.Negrita(True);
      FTicket.EscribirLinea('[' + RotuloGrupo(sGrupo) + ']');
      FTicket.Negrita(False);
    end
    else if sGrupo <> FGrupoAnterior then
    begin
      if FGrupoAnterior <> '' then
      begin
        EscribirSubtotalGrupo(FGrupoAnterior);
        FTicket.LineaSeparadora('=');
        FTicket.LineaSeparadora('=');
      end
      else
        FTicket.LineaSeparadora('=');
      EscribirCabeceraGrupo(sGrupo);
    end;
    RenderizarOperacion(Operacion);
    FTicket.LineaSeparadora('-');
    FGrupoAnterior := sGrupo;
  end;
end;

procedure TImpresorTiraCajaTicket.EscribirCierre;
begin
  if NumeroOperaciones = 0 then
    FTicket.EscribirLinea(STicketSinOperaciones)
  else if not FCronologico then
    EscribirSubtotalGrupo(FGrupoAnterior)
  else
  begin
    FTicket.LineaSeparadora('=');
    FTicket.Alinear(alCentro);
    FTicket.Negrita(True);
    FTicket.EscribirLinea(STicketResumen);
    FTicket.Negrita(False);
    FTicket.Alinear(alIzquierda);
    if FNumeroVentas > 0 then
      EscribirSubtotalGrupo('VEN');
    if FNumeroTraspasos > 0 then
      EscribirSubtotalGrupo('TRA');
    if FNumeroPerdidas > 0 then
      EscribirSubtotalGrupo('PER');
    if FNumeroIngresos > 0 then
      EscribirSubtotalGrupo('ING');
    if FNumeroGastos > 0 then
      EscribirSubtotalGrupo('GAS');
    if FNumeroDepositos > 0 then
      EscribirSubtotalGrupo('DEP');
  end;
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  FTicket.SaltarLineas(2);
  FTicket.CortarPapel;
end;

procedure TImpresorTiraCajaTicket.Emitir;
var
  sComandos, sRutaPDF: string;
begin
  sComandos := FTicket.ObtenerComandos;
  sRutaPDF := GetUserFolderTickets + 'TiraCaja_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
  ImprimirOPrevisualizarTicket(
    FPreview, FTicket, sComandos, sRutaPDF, FNombreImpresora);
end;

procedure TImpresorTiraCajaTicket.Ejecutar;
begin
  InicializarAcumuladores;
  FTicket := TTicketTermico.Create(FNombreImpresora);
  try
    FTicket.Inicializar;
    EscribirCabecera;
    EscribirOperaciones;
    EscribirCierre;
    Emitir;
  finally
    FreeAndNil(FTicket);
  end;
end;

class procedure TTiraCajaTicket.Imprimir(
  const AParametrosApp: IParametrosAplicacion;
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate;
  const ASeries: TArray<string>;
  AImprimirQR: Boolean;
  const ANombreImpresora: string;
  ACronologico: Boolean;
  AIncluirTraspasos: Boolean;
  AIncluirIngresos: Boolean;
  AIncluirGastos: Boolean;
  AIncluirCredito: Boolean;
  AValorarTraspasos: Boolean);
var
  Impresor: TImpresorTiraCajaTicket;
begin
  Impresor := TImpresorTiraCajaTicket.Create(
    AParametrosApp, APreview, ARepositorio,
    AEmpresa, AAlmacen, ACaja, AFechaDesde, AFechaHasta, ASeries,
    AImprimirQR, ANombreImpresora, ACronologico,
    AIncluirTraspasos, AIncluirIngresos, AIncluirGastos,
    AIncluirCredito, AValorarTraspasos);
  try
    Impresor.Ejecutar;
  finally
    FreeAndNil(Impresor);
  end;
end;

const
  COL_EXCEL_TIPO = 0;
  COL_EXCEL_FECHA = 1;
  COL_EXCEL_DOCUMENTO = 2;
  COL_EXCEL_REFERENCIA = 3;
  COL_EXCEL_SKU = 4;
  COL_EXCEL_DESCRIPCION = 5;
  COL_EXCEL_CANTIDAD = 6;
  COL_EXCEL_IMPORTE = 7;
  COL_EXCEL_COBRADO = 8;
  COL_EXCEL_PENDIENTE = 9;

type
  TExportadorTiraCajaExcel = class
  private
    FPropietario: TComponent;
    FProveedorPreview: IProveedorPreviewExcel;
    FRepositorio: IRepositorioTiraCajaTicket;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaDesde: TDate;
    FFechaHasta: TDate;
    FSeries: TArray<string>;
    FCronologico: Boolean;
    FIncluirTraspasos: Boolean;
    FIncluirIngresos: Boolean;
    FIncluirGastos: Boolean;
    FIncluirCredito: Boolean;
    FVerCoste: Boolean;
    FPreview: TSesionPreviewExcel;
    FHoja: TdxSpreadSheetTableView;
    FOperacion: TOperacionTiraCaja;
    FFila: Integer;
    FImporteVentas: Currency;
    FImporteTraspasos: Currency;
    FImportePerdidas: Currency;
    FImporteIngresos: Currency;
    FImporteGastos: Currency;
    FVentaDepositos: Currency;
    FCobroDepositos: Currency;
    FNumeroVentas: Integer;
    FNumeroTraspasos: Integer;
    FNumeroPerdidas: Integer;
    FNumeroIngresos: Integer;
    FNumeroGastos: Integer;
    FNumeroDepositos: Integer;
    function ReferenciaDocumento: string;
    function FechaOperacion: string;
    function TextoSeries: string;
    procedure EscribirMoneda(AFila, AColumna: Integer; AValor: Currency);
    procedure EscribirCabecera;
    procedure VolcarVenta;
    procedure VolcarTraspaso;
    procedure VolcarIngresoGasto(const ATipo: string);
    procedure VolcarDeposito;
    procedure EscribirTituloGrupo(const AGrupo: string);
    procedure EscribirSubtotalGrupo(const AGrupo: string);
    procedure VolcarFila(const AGrupo: string);
    procedure ProcesarOperaciones;
    procedure EscribirCierre(const AUltimoGrupo: string);
  public
    constructor Create(
      APropietario: TComponent;
      const AProveedorPreview: IProveedorPreviewExcel;
      const ARepositorio: IRepositorioTiraCajaTicket;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
      ACronologico, AIncluirTraspasos, AIncluirIngresos,
      AIncluirGastos, AIncluirCredito, AVerCoste: Boolean);
    procedure Ejecutar;
  end;

constructor TExportadorTiraCajaExcel.Create(APropietario: TComponent;
  const AProveedorPreview: IProveedorPreviewExcel;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
  ACronologico, AIncluirTraspasos, AIncluirIngresos,
  AIncluirGastos, AIncluirCredito, AVerCoste: Boolean);
begin
  inherited Create;
  FPropietario := APropietario;
  FProveedorPreview := AProveedorPreview;
  FRepositorio := ARepositorio;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFechaDesde := AFechaDesde;
  FFechaHasta := AFechaHasta;
  FSeries := ASeries;
  FCronologico := ACronologico;
  FIncluirTraspasos := AIncluirTraspasos;
  FIncluirIngresos := AIncluirIngresos;
  FIncluirGastos := AIncluirGastos;
  FIncluirCredito := AIncluirCredito;
  FVerCoste := AVerCoste;
end;

function TExportadorTiraCajaExcel.ReferenciaDocumento: string;
begin
  if Trim(FOperacion.SerieFactura) <> '' then
    Result := FormatearDocumento(
      FOperacion.FormatoDocumento,
      FOperacion.SerieFactura,
      FOperacion.NumeroFactura)
  else
    Result := Format(SFormatoReferenciaOperacionTiraCajaExcel,
      [FOperacion.NumeroOperacion]);
end;

function TExportadorTiraCajaExcel.FechaOperacion: string;
begin
  Result := FormatDateTime('dd/mm/yyyy hh:nn',
    FOperacion.FechaOperacion);
end;

function TExportadorTiraCajaExcel.TextoSeries: string;
var
  iSerie: Integer;
begin
  if Length(FSeries) = 0 then
    Result := STodasSeriesTiraCajaExcel
  else
  begin
    Result := SPrefijoSeriesTiraCajaExcel;
    for iSerie := 0 to High(FSeries) do
    begin
      if iSerie > 0 then
        Result := Result + ', ';
      Result := Result + FSeries[iSerie];
    end;
  end;
end;

procedure TExportadorTiraCajaExcel.EscribirMoneda(
  AFila, AColumna: Integer; AValor: Currency);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode := '#,##0.00';
end;

procedure TExportadorTiraCajaExcel.EscribirCabecera;
begin
  W(FHoja, 0, COL_EXCEL_TIPO,
    Format(SFormatoTituloTiraCajaExcel, [FCaja]), True);
  W(FHoja, 1, COL_EXCEL_TIPO,
    Format(SFormatoPeriodoTiraCajaExcel,
      [FormatDateTime('dd/mm/yyyy hh:nn', FFechaDesde),
       FormatDateTime('dd/mm/yyyy hh:nn', FFechaHasta)]));
  W(FHoja, 2, COL_EXCEL_TIPO, TextoSeries);
  if FCronologico then
    W(FHoja, 3, COL_EXCEL_TIPO, SOrdenCronologicoTiraCajaExcel)
  else
    W(FHoja, 3, COL_EXCEL_TIPO, SOrdenTipoDocumentoTiraCajaExcel);
  W(FHoja, 5, COL_EXCEL_TIPO, SColumnaTipoTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_FECHA, SColumnaFechaTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_DOCUMENTO,
    SColumnaDocumentoTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_REFERENCIA,
    SColumnaClienteDestinoTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_SKU, SColumnaSkuTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_DESCRIPCION,
    SColumnaDescripcionTiraCajaExcel, True);
  W(FHoja, 5, COL_EXCEL_CANTIDAD,
    SColumnaCantidadTiraCajaExcel, True, ssahRight);
  W(FHoja, 5, COL_EXCEL_IMPORTE,
    SColumnaImporteTiraCajaExcel, True, ssahRight);
  W(FHoja, 5, COL_EXCEL_COBRADO,
    SColumnaCobradoTiraCajaExcel, True, ssahRight);
  W(FHoja, 5, COL_EXCEL_PENDIENTE,
    SColumnaPendienteTiraCajaExcel, True, ssahRight);
  FFila := 6;
end;

procedure TExportadorTiraCajaExcel.VolcarVenta;
var
  aLineas: TArray<TLineaVentaTiraCaja>;
  oLinea: TLineaVentaTiraCaja;
  sDocumento: string;
begin
  sDocumento := ReferenciaDocumento;
  aLineas := FRepositorio.ListarLineasVenta(
    FOperacion.Empresa,
    FOperacion.Almacen,
    FOperacion.Caja,
    FOperacion.NumeroOperacion);
  for oLinea in aLineas do
  begin
    W(FHoja, FFila, COL_EXCEL_TIPO, STipoVentaTiraCajaExcel);
    W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
    W(FHoja, FFila, COL_EXCEL_DOCUMENTO, sDocumento);
    W(FHoja, FFila, COL_EXCEL_SKU, oLinea.CodigoUnidad);
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION, oLinea.Descripcion);
    W(FHoja, FFila, COL_EXCEL_CANTIDAD,
      oLinea.Cantidad,
      False,
      ssahRight);
    EscribirMoneda(
      FFila,
      COL_EXCEL_IMPORTE,
      oLinea.Total);
    FImporteVentas := FImporteVentas + oLinea.Total;
    Inc(FFila);
  end;
  Inc(FNumeroVentas);
end;

procedure TExportadorTiraCajaExcel.VolcarTraspaso;
var
  aLineas: TArray<TLineaTraspasoTiraCaja>;
  dCantidad, dCoste: Double;
  oLinea: TLineaTraspasoTiraCaja;
  sDestino, sDocumento: string;
begin
  sDocumento := ReferenciaDocumento;
  sDestino := Trim(FOperacion.AlmacenContrapartida);
  aLineas := FRepositorio.ListarLineasTraspaso(
    FOperacion.Empresa,
    FOperacion.Almacen,
    FOperacion.Caja,
    FOperacion.NumeroOperacion);
  for oLinea in aLineas do
  begin
    dCantidad := oLinea.Cantidad;
    dCoste := oLinea.PrecioCosteUnitario;
    if FOperacion.Grupo = 'PER' then
      W(FHoja, FFila, COL_EXCEL_TIPO, STicketPerdidaTransito)
    else
      W(FHoja, FFila, COL_EXCEL_TIPO, STipoTraspasoTiraCajaExcel);
    W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
    W(FHoja, FFila, COL_EXCEL_DOCUMENTO, sDocumento);
    W(FHoja, FFila, COL_EXCEL_REFERENCIA, sDestino);
    W(FHoja, FFila, COL_EXCEL_SKU, oLinea.CodigoUnidad);
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION, oLinea.Descripcion);
    W(FHoja, FFila, COL_EXCEL_CANTIDAD, dCantidad, False, ssahRight);
    if FVerCoste then
    begin
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dCantidad * dCoste);
      if FOperacion.Grupo = 'PER' then
        FImportePerdidas := FImportePerdidas + dCantidad * dCoste
      else
        FImporteTraspasos := FImporteTraspasos + dCantidad * dCoste;
    end;
    Inc(FFila);
  end;
  if FOperacion.Grupo = 'PER' then
    Inc(FNumeroPerdidas)
  else
    Inc(FNumeroTraspasos);
end;

procedure TExportadorTiraCajaExcel.VolcarIngresoGasto(
  const ATipo: string);
var
  dImporte: Currency;
begin
  dImporte := FOperacion.ImporteTotal;
  W(FHoja, FFila, COL_EXCEL_TIPO, ATipo);
  W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
  W(FHoja, FFila, COL_EXCEL_DOCUMENTO,
    Format(SFormatoReferenciaOperacionTiraCajaExcel,
      [FOperacion.NumeroOperacion]));
  W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
    Trim(FOperacion.ConceptoGastoIngreso));
  EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dImporte);
  if ATipo = STipoIngresoTiraCajaExcel then
  begin
    FImporteIngresos := FImporteIngresos + dImporte;
    Inc(FNumeroIngresos);
  end
  else
  begin
    FImporteGastos := FImporteGastos + dImporte;
    Inc(FNumeroGastos);
  end;
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.VolcarDeposito;
var
  aDepositos: TArray<TDepositoTiraCaja>;
  dAnticipo, dPrecio, dTotal: Currency;
  dCantidad: Double;
  oDeposito: TDepositoTiraCaja;
begin
  aDepositos := FRepositorio.ListarDepositos(
    FOperacion.Empresa,
    FOperacion.Almacen,
    FOperacion.Caja,
    FOperacion.NumeroOperacion);
  for oDeposito in aDepositos do
  begin
    dPrecio := oDeposito.PrecioVenta;
    dCantidad := oDeposito.Cantidad;
    dAnticipo := oDeposito.ImporteAnticipo;
    dTotal := dPrecio * dCantidad;
    W(FHoja, FFila, COL_EXCEL_TIPO, STipoCreditoDepositoTiraCajaExcel);
    W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
    W(FHoja, FFila, COL_EXCEL_DOCUMENTO,
      Format(SFormatoReferenciaOperacionTiraCajaExcel,
        [FOperacion.NumeroOperacion]));
    W(FHoja, FFila, COL_EXCEL_REFERENCIA,
      Trim(oDeposito.CodigoCliente + ' ' + oDeposito.Cliente));
    W(FHoja, FFila, COL_EXCEL_SKU, oDeposito.CodigoUnidad);
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION, oDeposito.Descripcion);
    W(FHoja, FFila, COL_EXCEL_CANTIDAD, dCantidad, False, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dTotal);
    EscribirMoneda(FFila, COL_EXCEL_COBRADO, dAnticipo);
    EscribirMoneda(FFila, COL_EXCEL_PENDIENTE, dTotal - dAnticipo);
    FVentaDepositos := FVentaDepositos + dTotal;
    FCobroDepositos := FCobroDepositos + dAnticipo;
    Inc(FFila);
  end;
  Inc(FNumeroDepositos);
end;

procedure TExportadorTiraCajaExcel.EscribirTituloGrupo(
  const AGrupo: string);
begin
  if AGrupo = 'TRA' then
    W(FHoja, FFila, COL_EXCEL_TIPO,
      STituloTraspasosTiraCajaExcel, True)
  else if AGrupo = 'PER' then
    W(FHoja, FFila, COL_EXCEL_TIPO, STicketPerdidasTransito, True)
  else if AGrupo = 'ING' then
    W(FHoja, FFila, COL_EXCEL_TIPO, STituloIngresosTiraCajaExcel, True)
  else if AGrupo = 'GAS' then
    W(FHoja, FFila, COL_EXCEL_TIPO, STituloGastosTiraCajaExcel, True)
  else if AGrupo = 'DEP' then
    W(FHoja, FFila, COL_EXCEL_TIPO,
      STituloDepositosTiraCajaExcel, True)
  else
    W(FHoja, FFila, COL_EXCEL_TIPO, STituloVentasTiraCajaExcel, True);
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.EscribirSubtotalGrupo(
  const AGrupo: string);
begin
  if AGrupo = 'TRA' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      SSubtotalTraspasosTiraCajaExcel, True, ssahRight);
    if FVerCoste then
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteTraspasos);
  end
  else if AGrupo = 'PER' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      STicketPerdidas, True, ssahRight);
    if FVerCoste then
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImportePerdidas);
  end
  else if AGrupo = 'ING' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      SSubtotalIngresosTiraCajaExcel, True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteIngresos);
  end
  else if AGrupo = 'GAS' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      SSubtotalGastosTiraCajaExcel, True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteGastos);
  end
  else if AGrupo = 'DEP' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      SSubtotalDepositosTiraCajaExcel, True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FVentaDepositos);
    EscribirMoneda(FFila, COL_EXCEL_COBRADO, FCobroDepositos);
  end
  else
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      SSubtotalVentasTiraCajaExcel, True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteVentas);
  end;
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.VolcarFila(const AGrupo: string);
begin
  if (AGrupo = 'TRA') or (AGrupo = 'PER') then
    VolcarTraspaso
  else if AGrupo = 'ING' then
    VolcarIngresoGasto(STipoIngresoTiraCajaExcel)
  else if AGrupo = 'GAS' then
    VolcarIngresoGasto(STipoGastoTiraCajaExcel)
  else if AGrupo = 'DEP' then
    VolcarDeposito
  else
    VolcarVenta;
end;

procedure TExportadorTiraCajaExcel.ProcesarOperaciones;
var
  aOperaciones: TArray<TOperacionTiraCaja>;
  oOperacion: TOperacionTiraCaja;
  sGrupo, sGrupoAnterior: string;
begin
  sGrupoAnterior := '';
  aOperaciones := FRepositorio.ListarOperaciones(
    FEmpresa,
    FAlmacen,
    FCaja,
    FFechaDesde,
    FFechaHasta,
    FSeries,
    FCronologico,
    FIncluirTraspasos,
    FIncluirIngresos,
    FIncluirGastos,
    FIncluirCredito);
  for oOperacion in aOperaciones do
  begin
    FOperacion := oOperacion;
    sGrupo := FOperacion.Grupo;
    if (not FCronologico) and (sGrupo <> sGrupoAnterior) then
    begin
      if sGrupoAnterior <> '' then
      begin
        EscribirSubtotalGrupo(sGrupoAnterior);
        Inc(FFila);
      end;
      EscribirTituloGrupo(sGrupo);
    end;
    VolcarFila(sGrupo);
    sGrupoAnterior := sGrupo;
  end;
  EscribirCierre(sGrupoAnterior);
end;

procedure TExportadorTiraCajaExcel.EscribirCierre(
  const AUltimoGrupo: string);
begin
  if (FNumeroVentas + FNumeroTraspasos + FNumeroPerdidas + FNumeroIngresos +
      FNumeroGastos + FNumeroDepositos) = 0 then
    W(FHoja, FFila, COL_EXCEL_TIPO, SSinOperacionesTiraCajaExcel)
  else if not FCronologico then
    EscribirSubtotalGrupo(AUltimoGrupo)
  else
  begin
    Inc(FFila);
    W(FHoja, FFila, COL_EXCEL_TIPO, STituloResumenTiraCajaExcel, True);
    Inc(FFila);
    if FNumeroVentas > 0 then
      EscribirSubtotalGrupo('VEN');
    if FNumeroTraspasos > 0 then
      EscribirSubtotalGrupo('TRA');
    if FNumeroPerdidas > 0 then
      EscribirSubtotalGrupo('PER');
    if FNumeroIngresos > 0 then
      EscribirSubtotalGrupo('ING');
    if FNumeroGastos > 0 then
      EscribirSubtotalGrupo('GAS');
    if FNumeroDepositos > 0 then
      EscribirSubtotalGrupo('DEP');
  end;
end;

procedure TExportadorTiraCajaExcel.Ejecutar;
begin
  FPreview := FProveedorPreview.Crear(FPropietario);
  try
    if FPreview.HojaCalculo.SheetCount = 0 then
      FPreview.HojaCalculo.AddSheet(
        SNombreHojaTiraCajaExcel, TdxSpreadSheetTableView);
    FHoja := FPreview.HojaCalculo.ActiveSheetAsTable;
    if FHoja <> nil then
    begin
      FHoja.BeginUpdate;
      try
        EscribirCabecera;
        ProcesarOperaciones;
      finally
        FHoja.EndUpdate;
      end;
      if FPropietario is TForm then
        FPreview.AsignarPopupParent(TForm(FPropietario));
      FPreview.AsignarNombreArchivo(
        Format(SFormatoNombreArchivoTiraCajaExcel,
          [FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now)]));
      FPreview.Mostrar;
    end;
  finally
    FreeAndNil(FPreview);
  end;
end;

class procedure TTiraCajaTicket.ExportarExcel(AOwner: TComponent;
  const AProveedorPreview: IProveedorPreviewExcel;
  const ARepositorio: IRepositorioTiraCajaTicket;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
  ACronologico: Boolean; AIncluirTraspasos: Boolean;
  AIncluirIngresos: Boolean; AIncluirGastos: Boolean;
  AIncluirCredito: Boolean; AValorarTraspasos: Boolean);
var
  oExportador: TExportadorTiraCajaExcel;
begin
  oExportador := TExportadorTiraCajaExcel.Create(
    AOwner,
    AProveedorPreview,
    ARepositorio,
    AEmpresa,
    AAlmacen,
    ACaja,
    AFechaDesde,
    AFechaHasta,
    ASeries,
    ACronologico,
    AIncluirTraspasos,
    AIncluirIngresos,
    AIncluirGastos,
    AIncluirCredito,
    AValorarTraspasos);
  try
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoTicket                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera e imprime el ticket de resumen del arqueo de caja (cierre Z).      }
{    Sigue el formato del ejemplo `src/otras pruebas/arqueos/recuento.txt`:    }
{    cabecera con empresa, contadores, líneas, operaciones, cobros, efectivo,  }
{    devoluciones y resúmenes por sección, empleado y forma de pago.           }
{                                                                              }
{    Recibe contratos de cálculo y lectura; no accede directamente a BBDD.    }
{                                                                              }
{    Si la impresora es 'DEBUG' abre el preview (TFormVisualizador) en vez de  }
{    mandar a la impresora física.                                             }
{******************************************************************************}
unit inLibArqueoTicket;

interface

uses
  System.SysUtils, System.Classes,
  inLibArqueoIntf,
  inLibArqueoTicketIntf,
  inLibArqueoPersistencia,
  inLibFTicket,
  inLibPreviewTicket,
  inLibDir,
  inLibContextoSesionIntf,
  inLibParametrosIntf,
  inLibMsgTickets;

type
  TArqueoTicket = class
  private
    class function FmtImp(AValor: Currency): string;
    class function FmtPorc(APorc: Currency): string;
    class procedure EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioArqueoTicket;
                                            const AEmpresa: string);
    class procedure EscribirContadores(ATicket: TTicketTermico;
                                       const ARepositorio:
                                       IRepositorioArqueoTicket;
                                       const AArqueo: TArqueoCaja);
    class procedure EscribirTotales(ATicket: TTicketTermico;
                                    const AArqueo: TArqueoCaja);
    class procedure EscribirDevolucionesPorFP(ATicket: TTicketTermico;
                                              const ARepositorio:
                                              IRepositorioArqueoTicket;
                                              const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSeccion(ATicket: TTicketTermico;
                                           const ARepositorio:
                                           IRepositorioArqueoTicket;
                                           const AParametrosCaja:
                                           IParametrosCaja;
                                           const AArqueo: TArqueoCaja);
    class procedure EscribirResumenTemporada(ATicket: TTicketTermico;
                                             const ARepositorio:
                                             IRepositorioArqueoTicket;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenEmpleado(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioArqueoTicket;
                                            const AArqueo: TArqueoCaja);
    class procedure EscribirResumenFormaPago(ATicket: TTicketTermico;
                                             const ARepositorio:
                                             IRepositorioArqueoTicket;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSerie(ATicket: TTicketTermico;
                                         const ARepositorio:
                                         IRepositorioArqueoTicket;
                                         const AArqueo: TArqueoCaja);
  public
    class procedure Imprimir(const APreview: IPreviewTicket;
                             const ARepositorioArqueo:
                             IRepositorioArqueoCaja;
                             const ARepositorioTicket:
                             IRepositorioArqueoTicket;
                             const AParametrosCaja: IParametrosCaja;
                             const AEmpresa: string;
                             const AAlmacen: string;
                             const ACaja: string;
                             AFechaDesde: TDate;
                             AFechaHasta: TDate;
                             const ANombreImpresora: string = 'DEBUG';
                             ADuplicado: Boolean = False);
    class procedure ImprimirCierre(
      const APreview: IPreviewTicket;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AContextoSesion: IContextoSesionAplicacion;
      const AArqueo: TArqueoCaja;
      const ALineas: TArray<TArqueoRecuentoLinea>;
      ATotalSistema: Currency;
      ATotalRecuento: Currency;
      ADiferencia: Currency;
      ARetirada: Currency;
      const AConceptoRetirada: string;
      AEfectivoDejado: Currency;
      const ADesgloseBilletes: string;
      const AObservaciones: string;
      const AVendedor: string;
      const ANombreImpresora: string = 'DEBUG';
      ADuplicado: Boolean = False);
    // Reimpresión (duplicado) del ticket de arqueo a partir de un arqueo ya
    // grabado en fza_caja_arqueos. Recalcula la tira en vivo (las operaciones
    // del rango son inmutables tras el cierre) y la marca como DUPLICADO.
    class procedure ImprimirDesdeHistorico(
      const APreview: IPreviewTicket;
      const ARepositorioArqueo: IRepositorioArqueoCaja;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AParametrosCaja: IParametrosCaja;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
      const ANombreImpresora: string = 'DEBUG');
    // Reimpresión (duplicado) del justificante de cierre reconstruido desde
    // fza_caja_arqueos + fza_caja_arqueos_recuento (sin recalcular nada).
    class procedure ImprimirCierreDesdeHistorico(
      const APreview: IPreviewTicket;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AContextoSesion: IContextoSesionAplicacion;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
      const ANombreImpresora: string = 'DEBUG');
  end;

implementation

uses
  inLibArqueoBitacora,
  inLibArqueoTicketPresentacion,
  inLibArqueoTicketPresentacionTermica;

// =============================================================================
//   Helpers de formato
// =============================================================================

class function TArqueoTicket.FmtImp(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

class function TArqueoTicket.FmtPorc(APorc: Currency): string;
begin
  // Un decimal: el arqueo queda más legible que con porcentajes enteros.
  Result := FormatFloat('0.0', APorc) + '%';
end;

// =============================================================================
//   Cabecera de empresa y título
// =============================================================================

class procedure TArqueoTicket.EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                                     const ARepositorio:
                                                     IRepositorioArqueoTicket;
                                                     const AEmpresa: string);
var
  oEmpresa: TEmpresaArqueoTicket;
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
//   Contadores: operaciones, unidades, primera/última operación
// =============================================================================

class procedure TArqueoTicket.EscribirContadores(ATicket: TTicketTermico;
                                                const ARepositorio:
                                                IRepositorioArqueoTicket;
                                                const AArqueo: TArqueoCaja);
var
  oContadores: TContadoresArqueoTicket;
begin
  oContadores := ARepositorio.ObtenerContadores(
    AArqueo);
  ATicket.Alinear(alIzquierda);
  if oContadores.Encontrado then
  begin
    ATicket.TextoColumnas(
      STicketPrimeraOperacion,
      oContadores.PrimeraOperacion);
    ATicket.TextoColumnas(
      STicketUltimaOperacion,
      oContadores.UltimaOperacion);
  end;
  ATicket.LineaSeparadora('-');
  ATicket.TextoColumnas(
    STicketOperaciones,
    IntToStr(AArqueo.CantidadVentas));
  if oContadores.Encontrado then
    ATicket.TextoColumnas(
      STicketUnidadesVenta,
      FmtImp(oContadores.Unidades));
end;

// =============================================================================
//   Bloques principales: líneas, operaciones, cobros, devoluciones
// =============================================================================

class procedure TArqueoTicket.EscribirTotales(ATicket: TTicketTermico;
                                              const AArqueo: TArqueoCaja);
begin
  ATicket.Alinear(alIzquierda);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketLineasArticulos);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(STicketBruto, FmtImp(AArqueo.BrutoLineas));

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketOperaciones);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketVentasNormales,
    FmtImp(AArqueo.VentasNormales));
  ATicket.TextoColumnas(
    STicketVentasPrestamos,
    FmtImp(AArqueo.VentasPrestamos));
  ATicket.TextoColumnas(
    STicketDevoluciones,
    FmtImp(AArqueo.Devoluciones));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketTotalVentas, FmtImp(AArqueo.TotalVentas));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketCobros);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketValesRecogidos,
    FmtImp(AArqueo.ValesRecogidos));
  ATicket.TextoColumnas(
    STicketValesEmitidos,
    FmtImp(AArqueo.ValesEmitidos));
  ATicket.TextoColumnas(
    STicketCobrosClientes,
    FmtImp(AArqueo.CobrosClientes));
  ATicket.TextoColumnas(
    STicketPendienteCobro,
    FmtImp(AArqueo.PendienteCobro));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketIngresosCaja, FmtImp(AArqueo.IngresosCaja));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketEfectivo);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketEfectivoIngresos,
    FmtImp(AArqueo.EfectivoIngresos));
  ATicket.TextoColumnas(
    STicketEfectivoEntradas,
    FmtImp(AArqueo.EfectivoEntradas));
  ATicket.TextoColumnas(
    STicketEfectivoSalidas,
    FmtImp(AArqueo.EfectivoSalidas));
  ATicket.TextoColumnas(
    STicketEfectivoAnterior,
    FmtImp(AArqueo.EfectivoAnterior));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketEfectivoCaja, FmtImp(AArqueo.EfectivoCaja));
  ATicket.Negrita(False);
  ATicket.TextoColumnas(STicketOtrosIngresos, FmtImp(AArqueo.OtrosIngresos));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketSaldoRecontar, FmtImp(AArqueo.SaldoRecontar));
  ATicket.Negrita(False);
end;

class procedure TArqueoTicket.EscribirDevolucionesPorFP(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TDevolucionFormaPagoArqueo>;
  iLinea: Integer;
begin
  if AArqueo.Devoluciones <> 0 then
  begin
    aLineas := ARepositorio.ListarDevolucionesPorFormaPago(
      AArqueo);
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketDevolucionesClientes);
    ATicket.Negrita(False);
    ATicket.TextoColumnas(
      STicketNetoArticulos,
      FmtImp(AArqueo.Devoluciones));
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        '    ' + aLineas[iLinea].FormaPago,
        FmtImp(aLineas[iLinea].Importe));
      Inc(iLinea);
    end;
  end;
end;

// =============================================================================
//   Resúmenes
// =============================================================================

class procedure TArqueoTicket.EscribirResumenSeccion(ATicket: TTicketTermico;
                                                    const ARepositorio:
                                                    IRepositorioArqueoTicket;
                                                    const AParametrosCaja:
                                                    IParametrosCaja;
                                                    const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenSeccionArqueo>;
  dTotal: Currency;
  dPorc: Currency;
  sFamilia: string;
  sImporte: string;
  sPorc: string;
  iAnchoFamilia: Integer;
  iLinea: Integer;
begin
  if AArqueo.Neto <> 0 then
  begin
    // FZ-ISSUE-433: con las devoluciones, como la pestaña Resúmenes; el
    // porcentaje va sobre la suma de las familias de primer nivel.
    aLineas := ARepositorio.ListarResumenSeccion(
      AArqueo,
      AParametrosCaja.NivelesFamiliaArqueo,
      True);
    dTotal := 0;
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      if not aLineas[iLinea].Familia.StartsWith(' ') then
        dTotal := dTotal + aLineas[iLinea].Neto;
      Inc(iLinea);
    end;
    if Length(aLineas) > 0 then
    begin
      ATicket.SaltarLineas(1);
      ATicket.Negrita(True);
      ATicket.EscribirLinea(STicketResumenNetoSeccion);
      ATicket.Negrita(False);
      iLinea := 0;
      while iLinea < Length(aLineas) do
      begin
        dPorc := 0;
        if dTotal <> 0 then
          dPorc := (aLineas[iLinea].Neto / dTotal) * 100;
        sFamilia := aLineas[iLinea].Familia;
        sPorc := FmtPorc(dPorc);
        sImporte := FmtImp(aLineas[iLinea].Neto);
        iAnchoFamilia :=
          N_CHAR_LIN - Length(sPorc) - Length(sImporte) - 3;
        if Length(sFamilia) > iAnchoFamilia then
        begin
          if iAnchoFamilia > 3 then
            sFamilia := Copy(
              sFamilia,
              1,
              iAnchoFamilia - 3) + '...'
          else
            sFamilia := Copy(sFamilia, 1, iAnchoFamilia);
        end;
        ATicket.TextoColumnas(
          sFamilia + ' ' + sPorc,
          sImporte);
        Inc(iLinea);
      end;
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenTemporada(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenTemporadaArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenTemporada(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasTemporada);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenTemporada,
          [Copy(aLineas[iLinea].Temporada, 1, 20),
           FormatFloat('0.##', aLineas[iLinea].Unidades)]),
        FmtImp(aLineas[iLinea].Neto));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenEmpleado(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenEmpleadoArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenEmpleado(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasEmpleado);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenEmpleado,
          [aLineas[iLinea].Empleado,
           aLineas[iLinea].Operaciones]),
        FmtImp(aLineas[iLinea].Neto));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenFormaPago(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenFormaPagoArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenFormaPago(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenFormaPago);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenFormaPago,
          [aLineas[iLinea].Descripcion,
           aLineas[iLinea].Unidades]),
        FmtImp(aLineas[iLinea].Importe));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenSerie(ATicket: TTicketTermico;
                                                  const ARepositorio:
                                                  IRepositorioArqueoTicket;
                                                  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenSerieArqueo>;
  dBase, dCuota, dTotal, dPorc: Currency;
  iLinea: Integer;
begin
  // Una fila por serie. % IVA se calcula como tipo efectivo
  // (cuota / base * 100). Si la serie mezcla varios tipos de IVA la cifra
  // del % es la media ponderada, no un tipo concreto.
  aLineas := ARepositorio.ListarResumenSerie(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasSerie);
    ATicket.Negrita(False);
    // El formato debe sumar exactamente N_CHAR_LIN (42) para que la columna
    // TOTAL acabe en el margen derecho, igual que el resto del ticket. Sin
    // espacio entre SERIE y BASE: la serie va a la izquierda y el importe a
    // la derecha, así no se pegan. 7+9+1+5+1+9+1+9 = 42.
    ATicket.EscribirLinea(
      Format(
        '%-7s%9s %5s %9s %9s',
        [STicketCabeceraSerie,
         STicketCabeceraBaseImponible,
         STicketCabeceraPorcentajeIva,
         STicketCabeceraCuota,
         STicketTotal]));
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      dBase := aLineas[iLinea].Base;
      dCuota := aLineas[iLinea].Cuota;
      dTotal := aLineas[iLinea].Total;
      if dBase <> 0 then
        dPorc := (dCuota / dBase) * 100
      else
        dPorc := 0;
      ATicket.EscribirLinea(
        Format('%-7s%9s %5s %9s %9s',
               [Copy(aLineas[iLinea].Serie, 1, 7),
                 FmtImp(dBase),
                FormatFloat('0.00', dPorc),
                FmtImp(dCuota),
                FmtImp(dTotal)]));
      Inc(iLinea);
    end;
  end;
end;

// =============================================================================
//   API pública
// =============================================================================

class procedure TArqueoTicket.Imprimir(
                                      const APreview: IPreviewTicket;
                                      const ARepositorioArqueo:
                                      IRepositorioArqueoCaja;
                                      const ARepositorioTicket:
                                      IRepositorioArqueoTicket;
                                      const AParametrosCaja:
                                      IParametrosCaja;
                                      const AEmpresa: string;
                                      const AAlmacen: string;
                                      const ACaja: string;
                                      AFechaDesde: TDate;
                                      AFechaHasta: TDate;
                                      const ANombreImpresora: string = 'DEBUG';
                                      ADuplicado: Boolean = False);
var
  Arqueo: TArqueoCaja;
  Ticket: TTicketTermico;
  ComandosESC, RutaPDF: string;
begin
  Arqueo := ARepositorioArqueo.Calcular(
    AEmpresa,
    AAlmacen,
    ACaja,
    AFechaDesde,
    AFechaHasta);

  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;

    // Cabecera de empresa
    EscribirCabeceraEmpresa(
      Ticket,
      ARepositorioTicket,
      AEmpresa);

    // Título del arqueo
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(Format(STicketArqueoCaja, [ACaja]));
    Ticket.EscribirLinea(STicketPeriodoSeleccionado);
    Ticket.EscribirLinea(Format(STicketDesde,
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaDesde)]));
    Ticket.EscribirLinea(Format(STicketHasta,
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaHasta)]));
    Ticket.EscribirLinea(STicketPendientesAnteriores);
    Ticket.Negrita(False);
    // Marca de reimpresión: el arqueo original ya se emitió en su día
    if ADuplicado then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketDuplicado);
      Ticket.Negrita(False);
    end;
    Ticket.SaltarLineas(1);

    // Contadores
    EscribirContadores(
      Ticket,
      ARepositorioTicket,
      Arqueo);

    // Totales
    EscribirTotales(Ticket, Arqueo);

    // Devoluciones desglosadas por forma de pago
    EscribirDevolucionesPorFP(
      Ticket,
      ARepositorioTicket,
      Arqueo);

    // Resúmenes
    EscribirResumenSeccion(
      Ticket,
      ARepositorioTicket,
      AParametrosCaja,
      Arqueo);
    EscribirResumenTemporada(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenEmpleado(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenFormaPago(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenSerie(
      Ticket,
      ARepositorioTicket,
      Arqueo);

    // Pie
    Ticket.SaltarLineas(1);
    Ticket.LineaSeparadora('-');
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ticket.SaltarLineas(2);
    Ticket.CortarPapel;

    // Vista previa o impresión real
    ComandosESC := Ticket.ObtenerComandos;
    RutaPDF := GetUserFolderTickets + 'Arqueo_' +
               FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

// =============================================================================
//   Ticket de recuento (cierre Z grabado)
// =============================================================================

function CrearDatosPresentacionCierre(
  const AArqueo: TArqueoCaja;
  const ALineas: TArray<TArqueoRecuentoLinea>;
  ATotalSistema: Currency;
  ATotalRecuento: Currency;
  ADiferencia: Currency;
  ARetirada: Currency;
  const AConceptoRetirada: string;
  AEfectivoDejado: Currency;
  const ADesgloseBilletes: string;
  const AObservaciones: string;
  const AVendedor: string;
  const AUsuario: string;
  AInstanteEmision: TDateTime;
  ADuplicado: Boolean): TDatosPresentacionCierreArqueo;
begin
  Result := Default(TDatosPresentacionCierreArqueo);
  Result.Arqueo := AArqueo;
  Result.Lineas := ALineas;
  Result.TotalSistema := ATotalSistema;
  Result.TotalRecuento := ATotalRecuento;
  Result.Diferencia := ADiferencia;
  Result.Retirada := ARetirada;
  Result.ConceptoRetirada := AConceptoRetirada;
  Result.EfectivoDejado := AEfectivoDejado;
  Result.DesgloseBilletes := ADesgloseBilletes;
  Result.Observaciones := AObservaciones;
  Result.Vendedor := AVendedor;
  Result.Usuario := AUsuario;
  Result.InstanteEmision := AInstanteEmision;
  Result.Duplicado := ADuplicado;
end;

class procedure TArqueoTicket.ImprimirCierre(
  const APreview: IPreviewTicket;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AContextoSesion: IContextoSesionAplicacion;
  const AArqueo: TArqueoCaja;
  const ALineas: TArray<TArqueoRecuentoLinea>;
  ATotalSistema: Currency;
  ATotalRecuento: Currency;
  ADiferencia: Currency;
  ARetirada: Currency;
  const AConceptoRetirada: string;
  AEfectivoDejado: Currency;
  const ADesgloseBilletes: string;
  const AObservaciones: string;
  const AVendedor: string;
  const ANombreImpresora: string = 'DEBUG';
  ADuplicado: Boolean = False);
var
  dInstanteEmision: TDateTime;
  aPresentacion: TPresentacionTicketArqueo;
  oBitacora: IRepositorioBitacoraArqueo;
  oDatos: TDatosPresentacionCierreArqueo;
  oTicket: TTicketTermico;
  sComandosESC: string;
  sRutaPDF: string;
begin
  dInstanteEmision := Now;
  oDatos := CrearDatosPresentacionCierre(
    AArqueo, ALineas, ATotalSistema, ATotalRecuento, ADiferencia,
    ARetirada, AConceptoRetirada, AEfectivoDejado,
    ADesgloseBilletes, AObservaciones, AVendedor,
    AContextoSesion.Identidad.Usuario, dInstanteEmision, ADuplicado);
  // Meteorología y cuaderno de bitácora de los días del arqueo, en el
  // almacén de la caja que cierra.
  if Supports(ARepositorioTicket, IRepositorioBitacoraArqueo, oBitacora) then
    oDatos.Bitacora := oBitacora.ListarDiasBitacora(
      AArqueo.Empresa, AArqueo.Almacen,
      AArqueo.FechaDesde, AArqueo.FechaHasta);
  aPresentacion := ConstruirPresentacionCierreArqueo(oDatos);
  oTicket := TTicketTermico.Create(ANombreImpresora);
  try
    oTicket.Inicializar;
    EscribirCabeceraEmpresa(
      oTicket,
      ARepositorioTicket,
      AArqueo.Empresa);
    RenderizarPresentacionTicketArqueo(oTicket, aPresentacion);
    sComandosESC := oTicket.ObtenerComandos;
    sRutaPDF := GetUserFolderTickets + 'Recuento_' +
      FormatDateTime('yyyy_mm_dd_hh_nn_ss', dInstanteEmision) + '.pdf';
    ImprimirOPrevisualizarTicket(
      APreview,
      oTicket,
      sComandosESC,
      sRutaPDF,
      ANombreImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

// =============================================================================
//   Reimpresión de duplicados desde el histórico (fza_caja_arqueos)
// =============================================================================

class procedure TArqueoTicket.ImprimirDesdeHistorico(
  const APreview: IPreviewTicket;
  const ARepositorioArqueo: IRepositorioArqueoCaja;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AParametrosCaja: IParametrosCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  dFechaHasta: TDate;
  oRango: TRangoHistoricoArqueo;
begin
  oRango := ARepositorioTicket.ObtenerRangoHistorico(
    AEmpresa,
    AAlmacen,
    ACaja,
    ACodigoArqueo);
  // Los cierres antiguos guardaban fechas sin hora. Se mantienen como dia
  // completo; los nuevos cierres por horas conservan su datetime exacto.
  if oRango.Encontrado then
  begin
    dFechaHasta := oRango.FechaHasta;
    if (Frac(oRango.FechaDesde) = 0) and
       (Frac(dFechaHasta) = 0) then
      dFechaHasta := dFechaHasta + EncodeTime(23, 59, 59, 0);
    Imprimir(
      APreview,
      ARepositorioArqueo,
      ARepositorioTicket,
      AParametrosCaja,
      oRango.Empresa,
      oRango.Almacen,
      oRango.Caja,
      oRango.FechaDesde,
      dFechaHasta,
      ANombreImpresora,
      True);
  end;
end;

class procedure TArqueoTicket.ImprimirCierreDesdeHistorico(
  const APreview: IPreviewTicket;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AContextoSesion: IContextoSesionAplicacion;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  aLineas: TArray<TArqueoRecuentoLinea>;
  iLinea: Integer;
  oCierre: TCierreHistoricoArqueo;
begin
  oCierre := ARepositorioTicket.ObtenerCierreHistorico(
    AEmpresa,
    AAlmacen,
    ACaja,
    ACodigoArqueo);
  if oCierre.Encontrado then
  begin
    if (Frac(oCierre.Arqueo.FechaDesde) = 0) and
       (Frac(oCierre.Arqueo.FechaHasta) = 0) then
      oCierre.Arqueo.FechaHasta :=
        oCierre.Arqueo.FechaHasta + EncodeTime(23, 59, 59, 0);
    SetLength(aLineas, Length(oCierre.Lineas));
    iLinea := 0;
    while iLinea < Length(oCierre.Lineas) do
    begin
      aLineas[iLinea].CodigoFP :=
        oCierre.Lineas[iLinea].CodigoFormaPago;
      aLineas[iLinea].Descripcion :=
        oCierre.Lineas[iLinea].Descripcion;
      aLineas[iLinea].EsCajon :=
        oCierre.Lineas[iLinea].EsCajon;
      aLineas[iLinea].Sistema :=
        oCierre.Lineas[iLinea].Sistema;
      aLineas[iLinea].Recuento :=
        oCierre.Lineas[iLinea].Recuento;
      aLineas[iLinea].Diferencia :=
        oCierre.Lineas[iLinea].Diferencia;
      Inc(iLinea);
    end;
    ImprimirCierre(
      APreview,
      ARepositorioTicket,
      AContextoSesion,
      oCierre.Arqueo,
      aLineas,
      oCierre.TotalSistema,
      oCierre.TotalRecuento,
      oCierre.Diferencia,
      oCierre.Retirada,
      oCierre.ConceptoRetirada,
      oCierre.EfectivoDejado,
      oCierre.DesgloseBilletes,
      oCierre.Observaciones,
      oCierre.Vendedor,
      ANombreImpresora,
      True);
  end;
end;

end.

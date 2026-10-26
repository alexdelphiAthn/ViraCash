{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasoTicket                                           }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Imprime (o previsualiza si la impresora es 'DEBUG') el ticket de una      }
{    solicitud de traspaso, listando por cada SKU la cantidad pedida y el      }
{    stock en el almacen origen y en el almacen destino. Patron clonado de     }
{    inLibArqueoTicket (TTicketTermico + preview TFormVisualizador).           }
{    Texto en ASCII a proposito para no depender del encoding del .pas.        }
{******************************************************************************}
unit inLibTraspasoTicket;

interface

uses
  System.SysUtils, System.Classes, Data.DB,
  inLibFTicket, inLibPreviewTicket, inLibDir,
  inLibTraspasoTicketIntf;

type
  // FZ-ISSUE-324: unidad de medida de una línea del ticket
  TUnidadLineaTicketTraspaso = record
    Codigo: string;
    // Decimales de la unidad; negativo si no se conoce ('0.###')
    Decimales: Integer;
    // Magnitud UNIDAD (Uds): se rotula «Unidades» y no se pone sufijo
    EsUnidades: Boolean;
  end;

  TTraspasoTicket = class
  private
    type
      TFormatoReposicion = record
        AnchoArticulo: Integer;
        AnchoPedido: Integer;
        AnchoStockOrigen: Integer;
        Fuente: TFuenteTermica;
      end;
    class function CrearFormatoReposicion(
      const ALineas: TArray<TLineaSolicitudTraspasoTicket>):
      TFormatoReposicion;
    class function FormatearArticuloReposicion(
      const ASku, ADescripcion: string;
      const AFormato: TFormatoReposicion): string;
    class function FormatearLineaReposicion(
      const ALinea: TLineaSolicitudTraspasoTicket;
      const AFormato: TFormatoReposicion): string;
    class function RequiereFormatoExtendidoReposicion(
      const ALineas: TArray<TLineaSolicitudTraspasoTicket>): Boolean;
    class function RellenarDerecha(
      const ATexto: string; AAncho: Integer): string;
    class function RellenarIzquierda(
      const ATexto: string; AAncho: Integer): string;
    class procedure ImprimirCabeceraReposicion(
      ATicket: TTicketTermico;
      const AFormato: TFormatoReposicion);
    class procedure ImprimirLineaReposicion(
      ATicket: TTicketTermico;
      const ALinea: TLineaSolicitudTraspasoTicket;
      const AFormato: TFormatoReposicion);
    // Imprime el bloque de una linea: SKU (en negrita), descripcion del
    // articulo y las tres magnitudes (unidades + stock origen/destino) con
    // etiquetas claras. El ticket no lleva precios a proposito.
    class procedure ImprimirLineaSku(ATicket: TTicketTermico;
                                     const ASku, ADescripcion,
                                     AEtiqUds: string; AUds: Double;
                                     const AEtiqOrigen: string; AOrigen: Double;
                                     const AEtiqDestino: string;
                                     ADestino: Double;
                                     const AUnidad:
                                       TUnidadLineaTicketTraspaso);
    // Los tres pasos de la solicitud: encabezado, cuerpo de lineas y
    // cierre con la salida a impresora o vista previa.
    // FZ-ISSUE-717: en una carga a un almacen de transito, el destino final
    // y las empresas que entregan y reciben la mercancia.
    class procedure ImprimirCargaTransito(ATicket: TTicketTermico;
                                          const ARepositorio:
                                          IRepositorioTraspasoTicket;
                                          const AEmpresa, AAlmacen, ACaja,
                                          ANumOperacion: string);
    class procedure ImprimirCabeceraSolicitud(
      ATicket: TTicketTermico;
      const ACabecera: TSolicitudTraspasoTicket;
      const ASerie, ANumero: string;
      AEsReposicion, ADuplicado: Boolean);
    class procedure ImprimirLineasSolicitud(
      ATicket: TTicketTermico;
      const ALineas: TArray<TLineaSolicitudTraspasoTicket>;
      AEsReposicion: Boolean);
    class procedure CerrarSolicitud(
      const APreview: IPreviewTicket;
      ATicket: TTicketTermico;
      const ASerie, ANumero, AImpresora: string;
      AEsReposicion, ADuplicado: Boolean);
  public
    // Imprime/previsualiza el ticket de una solicitud de traspaso ya grabada.
    class procedure ImprimirSolicitud(
                                      const APreview: IPreviewTicket;
                                      const ARepositorio:
                                      IRepositorioTraspasoTicket;
                                      const ANumero, ASerie: string;
                                      const ANombreImpresora:
                                      string = 'DEBUG';
                                      ADuplicado: Boolean = False);
    // Imprime/previsualiza el ticket de un traspaso ya ejecutado (F12 con
    // ticket). Recorre las lineas en memoria (ALineas: campos CODIGO_UNIDAD y
    // CANTIDAD) y por cada SKU calcula el stock en origen y en destino.
    class procedure ImprimirTraspaso(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const ADocRef, AOrigen, ADestino,
                                     AEmpleado, AEmpresa, ACaja: string;
                                     ALineas: TDataSet;
                                     const ANombreImpresora: string = 'DEBUG');
    // Reimprime el ticket de un traspaso ya grabado leyendo la cabecera de la
    // operacion de caja y sus lineas (movimientos de salida) de la BBDD. Lo usa
    // el boton Reimprimir de la consulta de operaciones (TR/TA).
    class procedure ImprimirTraspasoDesdeBD(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const AEmpresa, AAlmacen, ACaja,
                                     ANumOperacion: string;
                                     const ANombreImpresora: string = 'DEBUG';
                                     ARutasPDF: TStrings = nil;
                                     ASoloPDF: Boolean = False);
  end;

// FZ-ISSUE-324: unidad sin datos (formato '0.###', rótulo «Unidades»)
function UnidadLineaTicketDesconocida: TUnidadLineaTicketTraspaso;
// Cantidad con los decimales de la unidad y, si no es «unidades», su código
// detrás: «30,250 kg». Sin datos de la unidad, '0.###' como antes.
function TextoCantidadTicketTraspaso(AValor: Double;
  const AUnidad: TUnidadLineaTicketTraspaso): string;
// Rótulo de la cantidad: AEtiquetaUnidades («Unidades:», «A pedir:»...) en
// las unidades; «Cantidad:» en kg, litros, metros...
function EtiquetaCantidadTicketTraspaso(const AEtiquetaUnidades: string;
  const AUnidad: TUnidadLineaTicketTraspaso): string;

implementation

uses
  inLibMsgCaja,
  System.Math,
  inLibFormatoDocumento, inLibMsgTickets;

function UnidadLineaTicketDesconocida: TUnidadLineaTicketTraspaso;
begin
  Result := Default(TUnidadLineaTicketTraspaso);
  Result.Decimales := -1;
  Result.EsUnidades := True;
end;

function TextoCantidadTicketTraspaso(AValor: Double;
  const AUnidad: TUnidadLineaTicketTraspaso): string;
begin
  if AUnidad.Decimales < 0 then
    Result := FormatFloat('0.###', AValor)
  else if AUnidad.Decimales = 0 then
    Result := FormatFloat('0', AValor)
  else
    Result := FormatFloat('0.' + StringOfChar('0', AUnidad.Decimales),
      AValor);
  if (not AUnidad.EsUnidades) and (Trim(AUnidad.Codigo) <> '') then
    Result := Result + ' ' + Trim(AUnidad.Codigo);
end;

// Unidad de la línea actual de las líneas en memoria del traspaso
// (UNIDAD, DECIMALES_UNIDAD, ESUNIDADES); sin esos campos, desconocida.
function UnidadLineaDataSet(ALineas: TDataSet): TUnidadLineaTicketTraspaso;
var
  oDecimales: TField;
begin
  Result := UnidadLineaTicketDesconocida;
  oDecimales := ALineas.FindField('DECIMALES_UNIDAD');
  if (oDecimales <> nil) and not oDecimales.IsNull and
     (ALineas.FindField('UNIDAD') <> nil) and
     (ALineas.FindField('ESUNIDADES') <> nil) then
  begin
    Result.Codigo := ALineas.FieldByName('UNIDAD').AsString;
    Result.Decimales := oDecimales.AsInteger;
    Result.EsUnidades :=
      not SameText(ALineas.FieldByName('ESUNIDADES').AsString, 'N');
  end;
end;

function EtiquetaCantidadTicketTraspaso(const AEtiquetaUnidades: string;
  const AUnidad: TUnidadLineaTicketTraspaso): string;
begin
  if AUnidad.EsUnidades or (AUnidad.Decimales < 0) then
    Result := AEtiquetaUnidades
  else
    Result := STicketCantidad;
end;

const
  // La fuente B permite 56 caracteres y la C, 72. La fuente C conserva
  // completo el maximo de 50 caracteres admitido por CODIGO_UNIDAD_SKU.
  ANCHO_ARTICULO_REPOSICION_B = 41;
  ANCHO_PEDIDO_REPOSICION_B = 7;
  ANCHO_STOCK_ORIGEN_REPOSICION_B = 6;
  ANCHO_ARTICULO_REPOSICION_C = 55;
  ANCHO_PEDIDO_REPOSICION_C = 8;
  ANCHO_STOCK_ORIGEN_REPOSICION_C = 7;
  MIN_DESCRIPCION_REPOSICION = 7;
  SEPARACION_SKU_DESCRIPCION_REPOSICION = '  ';

class function TTraspasoTicket.CrearFormatoReposicion(
  const ALineas: TArray<TLineaSolicitudTraspasoTicket>):
  TFormatoReposicion;
var
  iAnchoPedido: Integer;
  iAnchoStockOrigen: Integer;
  iLinea: Integer;
begin
  Result := Default(TFormatoReposicion);
  if RequiereFormatoExtendidoReposicion(ALineas) then
  begin
    iAnchoPedido := ANCHO_PEDIDO_REPOSICION_C;
    iAnchoStockOrigen := ANCHO_STOCK_ORIGEN_REPOSICION_C;
    for iLinea := 0 to High(ALineas) do
    begin
      iAnchoPedido := Max(
        iAnchoPedido,
        Length(FormatFloat('0.###', ALineas[iLinea].CantidadPedida)));
      iAnchoStockOrigen := Max(
        iAnchoStockOrigen,
        Length(FormatFloat('0.###', ALineas[iLinea].StockOrigen)));
    end;
    Result.AnchoPedido := iAnchoPedido;
    Result.AnchoStockOrigen := iAnchoStockOrigen;
    Result.AnchoArticulo := ANCHO_ARTICULO_REPOSICION_C -
      (Result.AnchoPedido - ANCHO_PEDIDO_REPOSICION_C) -
      (Result.AnchoStockOrigen - ANCHO_STOCK_ORIGEN_REPOSICION_C);
    Result.Fuente := ftRasterC;
  end
  else
  begin
    Result.AnchoArticulo := ANCHO_ARTICULO_REPOSICION_B;
    Result.AnchoPedido := ANCHO_PEDIDO_REPOSICION_B;
    Result.AnchoStockOrigen := ANCHO_STOCK_ORIGEN_REPOSICION_B;
    Result.Fuente := ftRasterB;
  end;
end;

class function TTraspasoTicket.FormatearArticuloReposicion(
  const ASku, ADescripcion: string;
  const AFormato: TFormatoReposicion): string;
var
  iAnchoDescripcion: Integer;
  sDescripcion: string;
begin
  Result := Trim(ASku);
  sDescripcion := Trim(ADescripcion);
  iAnchoDescripcion := AFormato.AnchoArticulo - Length(Result) -
    Length(SEPARACION_SKU_DESCRIPCION_REPOSICION);
  if (sDescripcion <> '') and (iAnchoDescripcion > 0) then
    Result := Result + SEPARACION_SKU_DESCRIPCION_REPOSICION + Copy(
      sDescripcion,
      1,
      iAnchoDescripcion);
end;

class function TTraspasoTicket.FormatearLineaReposicion(
  const ALinea: TLineaSolicitudTraspasoTicket;
  const AFormato: TFormatoReposicion): string;
begin
  Result := RellenarDerecha(
    FormatearArticuloReposicion(
      ALinea.Sku,
      ALinea.Descripcion,
      AFormato),
    AFormato.AnchoArticulo) + ' ' +
    RellenarIzquierda(
      FormatFloat('0.###', ALinea.CantidadPedida),
      AFormato.AnchoPedido) + ' ' +
    RellenarIzquierda(
      FormatFloat('0.###', ALinea.StockOrigen),
      AFormato.AnchoStockOrigen);
end;

class function TTraspasoTicket.RequiereFormatoExtendidoReposicion(
  const ALineas: TArray<TLineaSolicitudTraspasoTicket>): Boolean;
var
  iLinea: Integer;
begin
  Result := False;
  iLinea := 0;
  while iLinea < Length(ALineas) do
  begin
    if (Length(Trim(ALineas[iLinea].Sku)) >
        ANCHO_ARTICULO_REPOSICION_B -
        MIN_DESCRIPCION_REPOSICION -
        Length(SEPARACION_SKU_DESCRIPCION_REPOSICION)) or
       (Length(FormatFloat(
          '0.###',
          ALineas[iLinea].CantidadPedida)) >
        ANCHO_PEDIDO_REPOSICION_B) or
       (Length(FormatFloat(
          '0.###',
          ALineas[iLinea].StockOrigen)) >
        ANCHO_STOCK_ORIGEN_REPOSICION_B) then
      Result := True;
    Inc(iLinea);
  end;
end;

class function TTraspasoTicket.RellenarDerecha(
  const ATexto: string; AAncho: Integer): string;
var
  iEspacios: Integer;
begin
  Result := Copy(ATexto, 1, AAncho);
  iEspacios := AAncho - Length(Result);
  if iEspacios > 0 then
    Result := Result + StringOfChar(' ', iEspacios);
end;

class function TTraspasoTicket.RellenarIzquierda(
  const ATexto: string; AAncho: Integer): string;
var
  iEspacios: Integer;
begin
  Result := ATexto;
  iEspacios := AAncho - Length(Result);
  if iEspacios > 0 then
    Result := StringOfChar(' ', iEspacios) + Result;
end;

class procedure TTraspasoTicket.ImprimirCabeceraReposicion(
  ATicket: TTicketTermico;
  const AFormato: TFormatoReposicion);
var
  iAnchoLinea: Integer;
begin
  iAnchoLinea := AFormato.AnchoArticulo + AFormato.AnchoPedido +
    AFormato.AnchoStockOrigen + 2;
  ATicket.SeleccionarFuente(AFormato.Fuente);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(
    RellenarDerecha(
      STicketArticulos,
      AFormato.AnchoArticulo) + ' ' +
    RellenarIzquierda(
      SCabeceraPedidoReposicionTicket,
      AFormato.AnchoPedido) + ' ' +
    RellenarIzquierda(
      SCabeceraStockReposicionTicket,
      AFormato.AnchoStockOrigen));
  ATicket.Negrita(False);
  ATicket.EscribirLinea(StringOfChar('-', iAnchoLinea));
  ATicket.SeleccionarFuente(ftRasterA);
end;

class procedure TTraspasoTicket.ImprimirLineaReposicion(
  ATicket: TTicketTermico;
  const ALinea: TLineaSolicitudTraspasoTicket;
  const AFormato: TFormatoReposicion);
begin
  ATicket.SeleccionarFuente(AFormato.Fuente);
  ATicket.EscribirLinea(
    FormatearLineaReposicion(
      ALinea,
      AFormato));
  ATicket.SeleccionarFuente(ftRasterA);
end;

class procedure TTraspasoTicket.ImprimirLineaSku(ATicket: TTicketTermico;
                                   const ASku, ADescripcion,
                                   AEtiqUds: string; AUds: Double;
                                   const AEtiqOrigen: string; AOrigen: Double;
                                   const AEtiqDestino: string;
                                   ADestino: Double;
                                   const AUnidad:
                                     TUnidadLineaTicketTraspaso);
var
  sDesc: string;
begin
  // SKU destacado para identificar la unidad.
  ATicket.Negrita(True);
  ATicket.EscribirLinea(ASku);
  ATicket.Negrita(False);
  // Descripcion del articulo, recortada al ancho del ticket para no desbordar.
  sDesc := Trim(ADescripcion);
  if Length(sDesc) > N_CHAR_LIN then
    sDesc := Copy(sDesc, 1, N_CHAR_LIN);
  if sDesc <> '' then
    ATicket.EscribirLinea(sDesc);
  // Unidades movidas/pedidas y stock resultante en origen y destino. Sin
  // precios: el coste no aparece en el ticket.
  ATicket.TextoColumnas(EtiquetaCantidadTicketTraspaso(AEtiqUds, AUnidad),
    TextoCantidadTicketTraspaso(AUds, AUnidad));
  ATicket.TextoColumnas(AEtiqOrigen,
    TextoCantidadTicketTraspaso(AOrigen, AUnidad));
  ATicket.TextoColumnas(AEtiqDestino,
    TextoCantidadTicketTraspaso(ADestino, AUnidad));
end;

function TextoCodigoNombre(const ACodigo, ANombre: string): string;
begin
  if Trim(ANombre) = '' then
    Result := ACodigo
  else
    Result := ACodigo + ' - ' + ANombre;
end;

class procedure TTraspasoTicket.ImprimirCargaTransito(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioTraspasoTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string);
var
  Carga: TCargaTransitoTicket;
begin
  Carga := ARepositorio.ObtenerCargaTransito(AEmpresa, AAlmacen, ACaja,
    ANumOperacion);
  if Carga.Existe then
  begin
    ATicket.TextoColumnas(STicketDestinoFinal,
      TextoCodigoNombre(Carga.DestinoFinal, Carga.NombreDestinoFinal));
    ATicket.TextoColumnas(STicketEmpresaOrigen,
      TextoCodigoNombre(Carga.EmpresaOrigen, Carga.NombreEmpresaOrigen));
    if Trim(Carga.EmpresaDestino) <> '' then
      ATicket.TextoColumnas(STicketEmpresaDestino,
        TextoCodigoNombre(Carga.EmpresaDestino,
          Carga.NombreEmpresaDestino));
  end;
end;

class procedure TTraspasoTicket.ImprimirCabeceraSolicitud(
  ATicket: TTicketTermico;
  const ACabecera: TSolicitudTraspasoTicket;
  const ASerie, ANumero: string;
  AEsReposicion, ADuplicado: Boolean);
var
  sVentasDesde, sVentasHasta: string;
begin
  ATicket.Inicializar;
  ATicket.ConfigurarEspanol;
  ATicket.Alinear(alCentro);
  ATicket.Negrita(True);
  if AEsReposicion then
    ATicket.EscribirLinea(STicketReposicionAutomatica)
  else
    ATicket.EscribirLinea(STicketSolicitudTraspaso);
  ATicket.EscribirLinea(ASerie + '/' + ANumero);
  ATicket.Negrita(False);
  if ADuplicado then
  begin
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketDuplicado);
    ATicket.Negrita(False);
  end;
  ATicket.SaltarLineas(1);
  ATicket.Alinear(alIzquierda);
  ATicket.TextoColumnas(STicketOrigen, ACabecera.Origen);
  ATicket.TextoColumnas(STicketDestino, ACabecera.Destino);
  ATicket.TextoColumnas(STicketEmpleado, ACabecera.Empleado);
  if AEsReposicion then
  begin
    sVentasDesde := '';
    if ACabecera.InstanteVentasDesde > 0 then
      sVentasDesde := FormatDateTime(
        'dd/mm/yyyy hh:nn',
        ACabecera.InstanteVentasDesde);
    sVentasHasta := '';
    if ACabecera.InstanteVentasHasta > 0 then
      sVentasHasta := FormatDateTime(
        'dd/mm/yyyy hh:nn',
        ACabecera.InstanteVentasHasta);
    ATicket.TextoColumnas(
      STicketVentasDesde,
      sVentasDesde);
    ATicket.TextoColumnas(
      STicketVentasHasta,
      sVentasHasta);
  end
  else
    ATicket.TextoColumnas(STicketEstado, ACabecera.Estado);
  ATicket.TextoColumnas(
    STicketFecha,
    FormatDateTime('dd/mm/yyyy', ACabecera.Fecha));
  ATicket.LineaSeparadora('-');
end;

class procedure TTraspasoTicket.ImprimirLineasSolicitud(
  ATicket: TTicketTermico;
  const ALineas: TArray<TLineaSolicitudTraspasoTicket>;
  AEsReposicion: Boolean);
var
  FormatoReposicion: TFormatoReposicion;
  sClaveProveedor, sClaveProveedorAnterior: string;
  sEtiquetaUnidades, sProveedor, sRotuloProveedor: string;
  iLinea: Integer;
begin
  if AEsReposicion then
  begin
    FormatoReposicion := CrearFormatoReposicion(ALineas);
    ImprimirCabeceraReposicion(
      ATicket,
      FormatoReposicion);
  end
  else
  begin
    ATicket.EscribirLinea(STicketArticulos);
    ATicket.LineaSeparadora('-');
  end;
  if AEsReposicion then
    sEtiquetaUnidades := STicketAPedir
  else
    sEtiquetaUnidades := STicketUnidadesPedidas;
  sClaveProveedorAnterior := '';
  iLinea := 0;
  while iLinea < Length(ALineas) do
  begin
    if AEsReposicion then
    begin
      sProveedor := Trim(ALineas[iLinea].Proveedor);
      sClaveProveedor :=
        UpperCase(Trim(ALineas[iLinea].CodigoProveedor));
      if sClaveProveedor = '' then
      begin
        if sProveedor = '' then
          sClaveProveedor := #1
        else
          sClaveProveedor := #2 + UpperCase(sProveedor);
      end
      else
        sClaveProveedor := #3 + sClaveProveedor;
      if sClaveProveedor <> sClaveProveedorAnterior then
      begin
        if iLinea > 0 then
          ATicket.LineaSeparadora('-');
        if sProveedor = '' then
          sProveedor := STicketSinProveedor;
        sRotuloProveedor := STicketProveedor + ' ' + sProveedor;
        if Length(sRotuloProveedor) > N_CHAR_LIN then
          sRotuloProveedor := Copy(
            sRotuloProveedor,
            1,
            N_CHAR_LIN);
        ATicket.Negrita(True);
        ATicket.EscribirLinea(sRotuloProveedor);
        ATicket.Negrita(False);
        sClaveProveedorAnterior := sClaveProveedor;
      end;
    end;
    if AEsReposicion then
      ImprimirLineaReposicion(
        ATicket,
        ALineas[iLinea],
        FormatoReposicion)
    else
      // Solicitud: nada se ha movido aun, el stock es la disponibilidad
      // actual en cada almacen (no lleva "tras traspaso").
      ImprimirLineaSku(ATicket,
        ALineas[iLinea].Sku,
        ALineas[iLinea].Descripcion,
        sEtiquetaUnidades,
        ALineas[iLinea].CantidadPedida,
        STicketStockOrigen,
        ALineas[iLinea].StockOrigen,
        STicketStockDestino,
        ALineas[iLinea].StockDestino,
        UnidadLineaTicketDesconocida);
    Inc(iLinea);
  end;
end;

class procedure TTraspasoTicket.CerrarSolicitud(
  const APreview: IPreviewTicket;
  ATicket: TTicketTermico;
  const ASerie, ANumero, AImpresora: string;
  AEsReposicion, ADuplicado: Boolean);
var
  ComandosESC, RutaPDF, sPrefijoPDF: string;
begin
  ATicket.LineaSeparadora('-');
  ATicket.Alinear(alCentro);
  ATicket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  ATicket.SaltarLineas(2);
  ATicket.CortarPapel;
  // Vista previa (DEBUG) o impresion real
  ComandosESC := ATicket.ObtenerComandos;
  if AEsReposicion then
    sPrefijoPDF := 'Reposicion'
  else
    sPrefijoPDF := 'SolTraspaso';
  if ADuplicado then
    sPrefijoPDF := sPrefijoPDF + '_Duplicado';
  // La serie puede llevar '/', que no cabe en un nombre de archivo
  RutaPDF := GetUserFolderTickets + sPrefijoPDF + '_' +
    StringReplace(ASerie, '/', '_', [rfReplaceAll]) + '_' + ANumero +
    '.pdf';
  ImprimirOPrevisualizarTicket(APreview, ATicket, ComandosESC, RutaPDF,
                               AImpresora);
end;

class procedure TTraspasoTicket.ImprimirSolicitud(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const ANumero, ASerie: string;
                                     const ANombreImpresora: string;
                                     ADuplicado: Boolean);
var
  Ticket: TTicketTermico;
  Cabecera: TSolicitudTraspasoTicket;
  Lineas: TArray<TLineaSolicitudTraspasoTicket>;
  bEsReposicion: Boolean;
  sImpresora: string;
begin
  if Assigned(ARepositorio) then
  begin
    // Impresora parametrizada
    // (vgerDefPrinter -> ParametrosCaja.ImpresoraCaja); si viene
    // vacia, preview.
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Cabecera := ARepositorio.ObtenerSolicitud(
      ANumero,
      ASerie);
    if Cabecera.Existe then
    begin
      bEsReposicion := SameText(
        Trim(Cabecera.Tipo),
        'AUTO');
      Ticket := TTicketTermico.Create(sImpresora);
      try
        ImprimirCabeceraSolicitud(
          Ticket,
          Cabecera,
          ASerie,
          ANumero,
          bEsReposicion,
          ADuplicado);
        // Lineas: por SKU, descripcion del articulo (denormalizada en la
        // propia linea, igual que en los movimientos), cantidad pedida y
        // stock disponible en origen y destino.
        Lineas := ARepositorio.ListarLineasSolicitud(
          ANumero,
          ASerie,
          Cabecera.Origen,
          Cabecera.Destino);
        ImprimirLineasSolicitud(Ticket, Lineas, bEsReposicion);
        CerrarSolicitud(
          APreview,
          Ticket,
          ASerie,
          ANumero,
          sImpresora,
          bEsReposicion,
          ADuplicado);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspaso(
                                   const APreview: IPreviewTicket;
                                   const ARepositorio:
                                   IRepositorioTraspasoTicket;
                                   const ADocRef, AOrigen, ADestino,
                                   AEmpleado, AEmpresa, ACaja: string;
                                   ALineas: TDataSet;
                                   const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  ComandosESC, RutaPDF, sImpresora, sRefArch, sSku: string;
  dPed, dOrg, dDes: Double;
  bm: TBookmark;
begin
  if Assigned(ARepositorio) and Assigned(ALineas) then
  begin
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Ticket := TTicketTermico.Create(sImpresora);
    try
      Ticket.Inicializar;
      Ticket.ConfigurarEspanol;
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketTraspaso);
      Ticket.EscribirLinea(ADocRef);
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas(STicketOrigen, AOrigen);
      Ticket.TextoColumnas(STicketDestino, ADestino);
      // ADocRef es el numero de la operacion recien grabada.
      ImprimirCargaTransito(Ticket, ARepositorio, AEmpresa, AOrigen, ACaja,
        ADocRef);
      Ticket.TextoColumnas(STicketEmpleado, AEmpleado);
      Ticket.TextoColumnas(
        STicketFecha,
        FormatDateTime('dd/mm/yyyy', Now));
      Ticket.LineaSeparadora('-');
      Ticket.EscribirLinea(STicketArticulos);
      Ticket.LineaSeparadora('-');
      // Recorre las lineas en memoria sin perder el registro actual. El ticket
      // se imprime DESPUES de grabar, asi que el stock leido ya es el estado
      // resultante del traspaso (por eso "tras traspaso").
      bm := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          sSku := ALineas.FieldByName('CODIGO_UNIDAD').AsString;
          if Trim(sSku) <> '' then
          begin
            dPed := ALineas.FieldByName('CANTIDAD').AsFloat;
            dOrg := ARepositorio.ObtenerStock(
              AOrigen,
              sSku);
            dDes := ARepositorio.ObtenerStock(
              ADestino,
              sSku);
            ImprimirLineaSku(Ticket, sSku,
              ALineas.FieldByName('DESCRIPCION').AsString,
              STicketUnidades, dPed,
              STicketStockOrigenTrasTraspaso, dOrg,
              STicketStockDestinoTrasTraspaso, dDes,
              UnidadLineaDataSet(ALineas));
          end;
          ALineas.Next;
        end;
      finally
        ALineas.GotoBookmark(bm);
        ALineas.FreeBookmark(bm);
        ALineas.EnableControls;
      end;
      Ticket.LineaSeparadora('-');
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
      Ticket.SaltarLineas(2);
      Ticket.CortarPapel;
      // Vista previa (DEBUG) o impresion real. El nombre de archivo no puede
      // llevar separadores: se sustituyen por '_'.
      ComandosESC := Ticket.ObtenerComandos;
      sRefArch := StringReplace(ADocRef, '/', '_', [rfReplaceAll]);
      sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
      RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
      ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                   sImpresora);
    finally
      FreeAndNil(Ticket);
    end;
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspasoDesdeBD(
                                   const APreview: IPreviewTicket;
                                   const ARepositorio:
                                   IRepositorioTraspasoTicket;
                                   const AEmpresa, AAlmacen, ACaja,
                                   ANumOperacion: string;
                                   const ANombreImpresora: string;
                                   ARutasPDF: TStrings;
                                   ASoloPDF: Boolean);
var
  Ticket: TTicketTermico;
  Cabecera: TTraspasoTicketHistorico;
  Lineas: TArray<TLineaTraspasoTicket>;
  ComandosESC, RutaPDF, sImpresora, sRefArch: string;
  sDocRef: string;
  dPed, dOrg, dDes: Double;
  iLinea: Integer;
begin
  if Assigned(ARepositorio) then
  begin
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Cabecera := ARepositorio.ObtenerTraspasoHistorico(
      AEmpresa,
      AAlmacen,
      ACaja,
      ANumOperacion);
    if Cabecera.Existe then
    begin
      if Trim(Cabecera.Serie + Cabecera.NumeroDocumento) <> '' then
        sDocRef := FormatearDocumento(
          Cabecera.FormatoDocumento,
          Cabecera.Serie,
          Cabecera.NumeroDocumento)
      else
        sDocRef := ANumOperacion;
      Ticket := TTicketTermico.Create(sImpresora);
      try
        Ticket.Inicializar;
        Ticket.ConfigurarEspanol;
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        if SameText(Cabecera.TipoOperacion, 'TP') then
          Ticket.EscribirLinea(STicketPerdidaTransito)
        else
          Ticket.EscribirLinea(STicketTraspaso);
        Ticket.EscribirLinea(sDocRef);
        Ticket.Negrita(False);
        Ticket.SaltarLineas(1);
        Ticket.Alinear(alIzquierda);
        if SameText(Cabecera.TipoOperacion, 'TP') then
          Ticket.TextoColumnas(STicketOrigen, Cabecera.Destino)
        else
        begin
          Ticket.TextoColumnas(STicketOrigen, Cabecera.Origen);
          Ticket.TextoColumnas(STicketDestino, Cabecera.Destino);
        end;
        ImprimirCargaTransito(Ticket, ARepositorio, AEmpresa, AAlmacen,
          ACaja, ANumOperacion);
        Ticket.TextoColumnas(STicketEmpleado, Cabecera.Empleado);
        Ticket.TextoColumnas(STicketOperacion, ANumOperacion);
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea(STicketArticulos);
        Ticket.LineaSeparadora('-');
        // Lineas: movimientos de salida (la salida del origen). La descripcion
        // viene denormalizada en el propio movimiento
        // (DESCRIPCION_ARTICULO_MOV).
        Lineas := ARepositorio.ListarLineasTraspaso(
          AEmpresa,
          AAlmacen,
          ACaja,
          ANumOperacion);
        iLinea := 0;
        while iLinea < Length(Lineas) do
        begin
          dPed := Lineas[iLinea].Cantidad;
          if SameText(Cabecera.TipoOperacion, 'TP') then
          begin
            Ticket.Negrita(True);
            Ticket.EscribirLinea(Lineas[iLinea].Sku);
            Ticket.Negrita(False);
            Ticket.EscribirLinea(Copy(Lineas[iLinea].Descripcion,
              1, N_CHAR_LIN));
            Ticket.TextoColumnas(STicketUnidades,
              FormatFloat('0.###', dPed));
          end
          else
          begin
            dOrg := ARepositorio.ObtenerStock(
              Cabecera.Origen,
              Lineas[iLinea].Sku);
            dDes := ARepositorio.ObtenerStock(
              Cabecera.Destino,
              Lineas[iLinea].Sku);
            // Reimpresion: el stock es el actual de cada almacen (puede haber
            // variado por movimientos posteriores), por eso "actual".
            ImprimirLineaSku(Ticket,
              Lineas[iLinea].Sku,
              Lineas[iLinea].Descripcion,
              STicketUnidades, dPed,
              STicketStockOrigenActual, dOrg,
              STicketStockDestinoActual, dDes,
              UnidadLineaTicketDesconocida);
          end;
          Inc(iLinea);
        end;
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
        Ticket.SaltarLineas(2);
        Ticket.CortarPapel;
        ComandosESC := Ticket.ObtenerComandos;
        sRefArch := StringReplace(sDocRef, '/', '_', [rfReplaceAll]);
        sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
        RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
        ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                     sImpresora, ASoloPDF);
        if Assigned(ARutasPDF) and FileExists(RutaPDF) then
          ARutasPDF.Add(RutaPDF);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  end;
end;

end.

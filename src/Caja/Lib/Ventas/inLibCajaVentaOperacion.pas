{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaVentaOperacion                                       }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Operación de venta de caja sobre sus datasets: cierre de la línea         }
{    pendiente, detección de devoluciones y depósitos, fecha de la             }
{    cabecera, preparación del artículo y documento del cierre.                }
{                                                                              }
{    Reune helpers que vivian enteros en TfrmMtoOpeCaja y no tocaban           }
{    ningun control. No conoce formularios, DevExpress ni UniDAC: el           }
{    lookup de atributos entra por contrato                                    }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.1 y 14.4).            }
{******************************************************************************}
unit inLibCajaVentaOperacion;

interface

uses
  Data.DB, Datasnap.DBClient,
  inLibArticulosAtributosIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf;

type
  // Serie, tipo y fecha del documento que nace al cerrar la venta.
  TDocumentoCierreVenta = record
    Serie: string;
    TipoFactura: string;
    FechaFactura: TDateTime;
  end;

  TResultadoPreparacionArticuloVenta = record
    Preparado: Boolean;
    MotivoRechazo: string;
    ConservoImportesExistentes: Boolean;
    IdentificadoPorCodigoBarras: Boolean;
  end;

  TAccionCodigoCaja = procedure(const ACodigo: string) of object;

// Devuelve el orden del primer atributo obligatorio sin valor (0 si no hay).
function PrimerAtributoPendienteLineaCaja(ALineas: TDataSet): Integer;

// Revisa la edición actual y todas las filas antes del cobro. Si falta un
// atributo deja situada su línea; si están completas conserva la posición.
function LocalizarLineaConAtributosPendientesCaja(
  ALineas: TDataSet): Integer;

// Cierra la linea pendiente: la insercion sin articulo se cancela; la
// que tiene articulo, y cualquier edicion, se graban.
procedure CerrarLineaPendiente(ALineas: TDataSet);

// Descarta el delta y los registros de la venta anterior. Las lineas
// quedan vacias y la cabecera preparada en insercion para la venta nueva.
procedure ReiniciarDatosOperacionVenta(
  ALineas, ACabecera: TCustomClientDataSet);

// Escribe los valores de negocio que identifican una nueva venta de caja.
// Los valores automaticos se aplican antes desde la composicion VCL.
procedure EscribirCabeceraBaseOperacionVenta(
  ACabecera: TDataSet;
  const AEmpresa, ATarifa: string;
  const AFecha: TDateTime);

// Para una nueva operacion se conserva el ultimo empleado validado. Si aun
// no lo hay, el configurado solo se usa cuando el parametro lo permite.
function ResolverEmpleadoNuevaOperacionVenta(
  const AUltimoEmpleado: string;
  ARellenarEmpleadoDefecto: Boolean;
  const AEmpleadoDefecto: string): string;

// Sin empleado por linea el vendedor no se puede tocar linea a linea: el
// de la cabecera manda sobre toda la venta, asi que al cambiarlo hay que
// estamparlo en las lineas ya metidas. Cierra antes la linea pendiente
// (la que no tiene articulo se cancela, la demas se graba), deja el
// cursor donde quedase tras cerrarla y devuelve cuantas lineas cambia.
function PropagarVendedorATodasLasLineas(
  ALineas: TDataSet;
  const AVendedor: string): Integer;

// Conserva los datos rechazados para corregir articulo, talla o cantidad.
// Si el recalculo ya publico la linea, la vuelve a dejar en edicion.
procedure ConservarLineaVentaPorValidacion(ALineas: TDataSet);

// Devolucion de venta: hay lineas en negativo que no sean operaciones
// de deposito (esas llevan su propio circuito). El flag llega de un
// CHAR de BBDD y puede traer relleno: se compara con Trim.
function HayLineasNegativasVenta(ALineas: TDataSet): Boolean;

// La venta arrastra alguna linea de deposito (prenda apartada o abono).
function HayLineasDepositoVenta(ALineas: TDataSet): Boolean;

// Cuenta del cliente (F2): alguna prenda de deposito esta marcada en la
// columna de seleccion (ESMARCADA_DEP = 'S') para cobrarla ahora.
function HayDepositosMarcadosVenta(ALineas: TDataSet): Boolean;

// Prepara la venta para el cobro y copia lo retirado en AApartadas para
// poder devolverlo. Siempre retira el historico (depositos cerrados,
// VIENE_DE_DEPOSITO = 'H'). Si hay prendas marcadas, retira ademas las
// prendas de deposito sin marcar y su abono a cuenta; las cancelaciones
// (ACCION_DEPOSITO = 'CANCELAR') se quedan. Devuelve las lineas apartadas.
function ApartarDepositosNoMarcadosVenta(
  ALineas: TDataSet;
  AApartadas: TClientDataSet): Integer;

// Quita de la venta las lineas del historico (depositos cerrados), que
// solo se muestran mientras la cuenta del cliente esta abierta.
procedure QuitarLineasHistoricoVenta(ALineas: TDataSet);

// Devuelve a la venta las lineas que aparto
// ApartarDepositosNoMarcadosVenta y vacia AApartadas.
procedure RestaurarDepositosApartadosVenta(
  ALineas: TDataSet;
  AApartadas: TClientDataSet);

// Cantidad cero en las líneas confirmadas que pasan al cobro.
function HayLineasConCantidadCero(ALineas: TDataSet): Boolean;

// La operacion esta vacia; una insercion o edicion pendiente se
// cancela antes de mirar.
// Consulta sin cancelar una línea válida que todavía se está escribiendo.
function VentaCajaSinContenido(ALineas: TClientDataSet): Boolean;

function OperacionVentaVacia(ALineas: TDataSet): Boolean;

// Estampa la fecha de caja en la cabecera; si estaba en reposo, graba.
procedure EscribirFechaCabeceraVenta(
  ACabecera: TDataSet;
  const AFecha: TDateTime);

// Escribe en la linea los valores ATTR1..ATTR5 de los atributos del
// SKU, segun el orden que devuelva el lookup.
procedure RellenarAtributosLineaDesdeSku(
  ALineas: TDataSet;
  const ASku: string;
  const ALookup: IArticulosAtributosLookup);

// AVs (BLANCO, 42, ...) referenciados por los SKUs del articulo para
// la columna AOrden, en el orden del tallaje.
procedure CargarAvsValidosArticulo(
  const ACodArt: string;
  AOrden: Integer;
  const ALookup: IArticulosAtributosLookup;
  out AAvs: TArray<string>);

// Documento del cierre: factura completa -> serie de factura, tipo
// NORMAL y su fecha; si no, la serie simplificada; y una devolucion
// con ticket rectificado que no acaba en factura es RECTIFICATIVA.
function ResolverDocumentoCierreVenta(
  AEsFactura: Boolean;
  const ASerieSimplificada, ASerieFactura: string;
  const AFechaFactura: TDateTime;
  AHayRectificacion: Boolean): TDocumentoCierreVenta;

// Resuelve una entrada manual o de escáner y prepara los datos de artículo
// de la línea. Las reacciones de stock y precio se reciben como callbacks
// para mantener esta operación separada de la presentación.
function PrepararArticuloLineaVenta(
  ALineas, ACabecera: TDataSet;
  const ACodigo: string;
  AEsLecturaScanner, AActualizandoDepositos: Boolean;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  AConsultarStock, ARecalcularPrecio: TAccionCodigoCaja):
  TResultadoPreparacionArticuloVenta;

implementation

uses
  System.SysUtils, System.Classes,
  inLibCajaVentaCliente;

procedure EscribirDatosBaseArticulo(
  ALineas: TDataSet;
  const AResolucion: TArtResolucionEntrada);
begin
  if ALineas.State = dsBrowse then
    ALineas.Edit;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    AResolucion.DescripcionArticulo;
  ALineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString :=
    AResolucion.TipoArticulo;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
    AResolucion.CodigoArticulo;
  ALineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger :=
    AResolucion.NumAtributosReq;
end;

// FZ-ISSUE-227: sin la unidad en la linea la columna Uds. se formatea
// con 0 decimales (2,35 m se veia «2»). Los depositos ya la traen.
// FZ-ISSUE-328: tambien el tipo de IVA del articulo. Con el SKU resuelto
// la linea se quedaba sin el y GetTipoIVA lo convertia en 'N': todo se
// vendia al 21 % aunque el articulo fuera reducido o superreducido.
procedure EscribirDatosArticuloResuelto(
  ALineas, ACabecera: TDataSet;
  const ACodigoArticulo: string;
  const AResolver: IArticulosResolver);
var
  Datos: TArticuloDatos;
  Campo: TField;
begin
  if Assigned(AResolver) and (Trim(ACodigoArticulo) <> '') then
  begin
    Datos := AResolver.ResolverDatos(
      ACodigoArticulo, '',
      ACabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString,
      ACabecera.FieldByName('FECHA_FAC').AsDateTime);
    Campo := ALineas.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN');
    if (Campo <> nil) and (Datos.TipoCantidad <> '') then
      Campo.AsString := Datos.TipoCantidad;
    Campo := ALineas.FindField('TIPO_IVA_ARTICULO_FACLIN');
    if (Campo <> nil) and (Trim(Datos.TipoIVA) <> '') then
      Campo.AsString := Trim(Datos.TipoIVA);
  end;
end;

procedure PrepararSkuResuelto(
  ALineas: TDataSet;
  const ACodigoSku: string;
  AActualizandoDepositos, AConservarImportesExistentes: Boolean;
  AConsultarStock, ARecalcularPrecio: TAccionCodigoCaja);
begin
  if (not AActualizandoDepositos) and Assigned(AConsultarStock) then
    AConsultarStock(ACodigoSku);
  ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
    ACodigoSku;
  if (not AConservarImportesExistentes) and
     Assigned(ARecalcularPrecio) then
    ARecalcularPrecio(ACodigoSku);
end;

procedure PrepararSkuPendiente(
  ALineas, ACabecera: TDataSet;
  const ACodigoArticulo: string;
  AActualizandoDepositos, AConservarImportesExistentes: Boolean;
  const AResolver: IArticulosResolver;
  AConsultarStock: TAccionCodigoCaja);
var
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
  sCodTarifa: string;
  dtFechaTicket: TDateTime;
begin
  if (not AActualizandoDepositos) and Assigned(AConsultarStock) then
    AConsultarStock(ACodigoArticulo);
  ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
    ACodigoArticulo;
  if (not AActualizandoDepositos) and
     (not AConservarImportesExistentes) and
     Assigned(AResolver) then
  begin
    sCodTarifa := ACabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    dtFechaTicket := ACabecera.FieldByName('FECHA_FAC').AsDateTime;
    Datos := AResolver.ResolverDatos(
      ACodigoArticulo, '', sCodTarifa, dtFechaTicket);
    Precio := AResolver.ResolverPrecio(
      ACodigoArticulo, '', sCodTarifa, dtFechaTicket);
    ALineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
      Datos.TipoIVA;
    if (Datos.TipoCantidad <> '') and
       (ALineas.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN') <> nil) then
      ALineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
        Datos.TipoCantidad;
    if Precio.EsImpIncl then
      ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString := 'S'
    else
      ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString := 'N';
    ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
      Precio.PorcentajeDto;
    ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
    ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
    ALineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    ALineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
    ALineas.FieldByName('CANTIDAD_FACLIN').AsCurrency := 1;
  end;
end;

function PrimerAtributoPendienteLineaCaja(ALineas: TDataSet): Integer;
var
  Campo: TField;
  Requeridos, I: Integer;
begin
  Result := 0;
  if Assigned(ALineas) and ALineas.Active and not ALineas.IsEmpty then
  begin
    Campo := ALineas.FindField('CODIGO_ART_FACLIN');
    if Assigned(Campo) and (Trim(Campo.AsString) <> '') then
    begin
      Requeridos := 0;
      Campo := ALineas.FindField('NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
      if Assigned(Campo) then
        Requeridos := Campo.AsInteger;
      for I := 1 to 5 do
      begin
        if (Result = 0) and (I <= Requeridos) then
        begin
          Campo := ALineas.FindField('ATTR' + IntToStr(I) + '_VALOR');
          if not Assigned(Campo) or (Trim(Campo.AsString) = '') then
            Result := I;
        end;
      end;
    end;
  end;
end;

function LocalizarLineaConAtributosPendientesCaja(
  ALineas: TDataSet): Integer;
var
  Marcador: TBookmark;
begin
  Result := PrimerAtributoPendienteLineaCaja(ALineas);
  if (Result = 0) and Assigned(ALineas) and ALineas.Active then
  begin
    CerrarLineaPendiente(ALineas);
    if not ALineas.IsEmpty then
    begin
      Marcador := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof and (Result = 0) do
        begin
          Result := PrimerAtributoPendienteLineaCaja(ALineas);
          if Result = 0 then
            ALineas.Next;
        end;
        if (Result = 0) and ALineas.BookmarkValid(Marcador) then
          ALineas.GotoBookmark(Marcador);
      finally
        ALineas.FreeBookmark(Marcador);
        ALineas.EnableControls;
      end;
    end;
  end;
end;

procedure CerrarLineaPendiente(ALineas: TDataSet);
begin
  if ALineas.State in [dsInsert, dsEdit] then
  begin
    if (ALineas.State = dsInsert) and
       (Trim(ALineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString) = '') then
      ALineas.Cancel
    else
      ALineas.Post;
  end;
end;

procedure ReiniciarDatosOperacionVenta(
  ALineas, ACabecera: TCustomClientDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    ALineas.DisableControls;
    try
      ALineas.CancelUpdates;
      if ALineas.RecordCount > 0 then
        ALineas.EmptyDataSet;
    finally
      ALineas.EnableControls;
    end;
  end;
  if Assigned(ACabecera) and ACabecera.Active then
  begin
    ACabecera.CancelUpdates;
    ACabecera.EmptyDataSet;
    ACabecera.Append;
  end;
end;

procedure EscribirCabeceraBaseOperacionVenta(
  ACabecera: TDataSet;
  const AEmpresa, ATarifa: string;
  const AFecha: TDateTime);
begin
  ACabecera.FieldByName('CODIGO_EMP_FAC').AsString := AEmpresa;
  ACabecera.FieldByName('FECHA_FAC').AsDateTime := AFecha;
  ACabecera.FieldByName('TIPO_FAC').AsString := 'SIMPLIFICADA';
  ACabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
    ATarifa;
end;

function ResolverEmpleadoNuevaOperacionVenta(
  const AUltimoEmpleado: string;
  ARellenarEmpleadoDefecto: Boolean;
  const AEmpleadoDefecto: string): string;
begin
  Result := Trim(AUltimoEmpleado);
  if (Result = '') and ARellenarEmpleadoDefecto then
    Result := Trim(AEmpleadoDefecto);
end;

function PropagarVendedorATodasLasLineas(
  ALineas: TDataSet;
  const AVendedor: string): Integer;
var
  Campo: TField;
  Marcador: TBookmark;
begin
  Result := 0;
  if Assigned(ALineas) and ALineas.Active then
  begin
    Campo := ALineas.FindField('CODIGO_VENDEDOR_FACLIN');
    if Assigned(Campo) then
    begin
      // Linea a medio meter: la que no tiene articulo se cancela para
      // evitar el Abort de BeforePost; la que ya lo tiene se graba.
      if ALineas.State in [dsInsert, dsEdit] then
      begin
        if Trim(ALineas.FieldByName(
             'CODIGO_ART_FACLIN').AsString) = '' then
          ALineas.Cancel
        else
          ALineas.Post;
      end;
      // Con los controles desconectados el Post de cada linea no dispara
      // el recalculo de la rejilla: aqui solo cambia el vendedor.
      ALineas.DisableControls;
      try
        Marcador := ALineas.GetBookmark;
        try
          ALineas.First;
          while not ALineas.Eof do
          begin
            if Campo.AsString <> AVendedor then
            begin
              ALineas.Edit;
              Campo.AsString := AVendedor;
              ALineas.Post;
              Inc(Result);
            end;
            ALineas.Next;
          end;
          if ALineas.BookmarkValid(Marcador) then
            ALineas.GotoBookmark(Marcador);
        finally
          ALineas.FreeBookmark(Marcador);
        end;
      finally
        ALineas.EnableControls;
      end;
    end;
  end;
end;

procedure ConservarLineaVentaPorValidacion(ALineas: TDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    if ALineas.State = dsBrowse then
    begin
      if ALineas.IsEmpty then
        ALineas.Append
      else
        ALineas.Edit;
    end;
  end;
end;

function HayLineasNegativasVenta(ALineas: TDataSet): Boolean;
var
  Marcador: TBookmark;
  sVieneDeDep: string;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active then
  begin
    ALineas.DisableControls;
    try
      Marcador := ALineas.GetBookmark;
      try
        ALineas.First;
        while (not ALineas.Eof) and (not Result) do
        begin
          sVieneDeDep := Trim(
            ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString);
          if (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat < 0) and
             (not EsLineaDeposito(sVieneDeDep)) then
            Result := True
          else
            ALineas.Next;
        end;
        if ALineas.BookmarkValid(Marcador) then
          ALineas.GotoBookmark(Marcador);
      finally
        ALineas.FreeBookmark(Marcador);
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

function HayLineasDepositoVenta(ALineas: TDataSet): Boolean;
var
  Bkm: TBookmark;
begin
  Result := False;
  ALineas.DisableControls;
  Bkm := ALineas.GetBookmark;
  try
    ALineas.First;
    while (not ALineas.Eof) and (not Result) do
    begin
      if EsLineaDeposito(
           ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) then
        Result := True
      else
        ALineas.Next;
    end;
  finally
    if ALineas.BookmarkValid(Bkm) then
      ALineas.GotoBookmark(Bkm);
    ALineas.FreeBookmark(Bkm);
    ALineas.EnableControls;
  end;
end;

function EsDepositoMarcado(ALineas: TDataSet): Boolean;
begin
  Result :=
    (Trim(ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) = 'S') and
    (ALineas.FieldByName('ESMARCADA_DEP').AsString = 'S');
end;

// Prenda de deposito que se queda pendiente: sin marcar y sin cancelar.
function EsDepositoQueSeAparta(ALineas: TDataSet): Boolean;
begin
  Result :=
    (Trim(ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) = 'S') and
    (ALineas.FieldByName('ESMARCADA_DEP').AsString <> 'S') and
    (Trim(ALineas.FieldByName('ACCION_DEPOSITO').AsString) <>
      'CANCELAR');
end;

function HayDepositosMarcadosVenta(ALineas: TDataSet): Boolean;
var
  Bkm: TBookmark;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active and
     Assigned(ALineas.FindField('ESMARCADA_DEP')) then
  begin
    ALineas.DisableControls;
    Bkm := ALineas.GetBookmark;
    try
      ALineas.First;
      while (not ALineas.Eof) and (not Result) do
      begin
        if EsDepositoMarcado(ALineas) then
          Result := True
        else
          ALineas.Next;
      end;
    finally
      if ALineas.BookmarkValid(Bkm) then
        ALineas.GotoBookmark(Bkm);
      ALineas.FreeBookmark(Bkm);
      ALineas.EnableControls;
    end;
  end;
end;

procedure CopiarRegistroVenta(AOrigen, ADestino: TDataSet);
var
  i: Integer;
  Destino: TField;
begin
  ADestino.Append;
  for i := 0 to AOrigen.FieldCount - 1 do
  begin
    Destino := ADestino.FindField(AOrigen.Fields[i].FieldName);
    if Assigned(Destino) and
       (AOrigen.Fields[i].FieldKind = fkData) then
      Destino.Value := AOrigen.Fields[i].Value;
  end;
  ADestino.Post;
end;

procedure RecogerDepositosQueSeApartan(
  ALineas: TDataSet;
  AIdsDeposito: TStringList);
begin
  ALineas.First;
  while not ALineas.Eof do
  begin
    if EsDepositoQueSeAparta(ALineas) then
      AIdsDeposito.Add(
        ALineas.FieldByName('ID_DEPOSITO_DEP').AsString);
    ALineas.Next;
  end;
end;

function HayLineasHistoricoVenta(ALineas: TDataSet): Boolean;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active then
  begin
    ALineas.DisableControls;
    try
      ALineas.First;
      while (not ALineas.Eof) and (not Result) do
      begin
        if EsLineaHistoricoDeposito(
             ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) then
          Result := True
        else
          ALineas.Next;
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

// El historico (depositos cerrados) nunca pasa al cobro. Las prendas sin
// marcar y su abono, solo cuando hay alguna marcada.
function DebeApartarseLineaVenta(
  ALineas: TDataSet;
  AIdsDeposito: TStringList;
  AHayMarcadas: Boolean): Boolean;
var
  sVieneDeDep: string;
begin
  sVieneDeDep := Trim(ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString);
  Result :=
    EsLineaHistoricoDeposito(sVieneDeDep) or
    (AHayMarcadas and
     (EsDepositoQueSeAparta(ALineas) or
      ((sVieneDeDep = 'A') and
       (AIdsDeposito.IndexOf(
          ALineas.FieldByName('ID_DEPOSITO_DEP').AsString) >= 0))));
end;

function ApartarDepositosNoMarcadosVenta(
  ALineas: TDataSet;
  AApartadas: TClientDataSet): Integer;
var
  IdsDeposito: TStringList;
  bHayMarcadas: Boolean;
begin
  Result := 0;
  CerrarLineaPendiente(ALineas);
  bHayMarcadas := HayDepositosMarcadosVenta(ALineas);
  if bHayMarcadas or HayLineasHistoricoVenta(ALineas) then
  begin
    if not AApartadas.Active then
    begin
      AApartadas.FieldDefs.Assign(ALineas.FieldDefs);
      AApartadas.CreateDataSet;
    end;
    IdsDeposito := TStringList.Create;
    ALineas.DisableControls;
    try
      IdsDeposito.Sorted := True;
      IdsDeposito.Duplicates := dupIgnore;
      if bHayMarcadas then
        RecogerDepositosQueSeApartan(ALineas, IdsDeposito);
      ALineas.First;
      while not ALineas.Eof do
      begin
        if DebeApartarseLineaVenta(
             ALineas, IdsDeposito, bHayMarcadas) then
        begin
          CopiarRegistroVenta(ALineas, AApartadas);
          // Delete deja el cursor en la linea siguiente.
          ALineas.Delete;
          Inc(Result);
        end
        else
          ALineas.Next;
      end;
      ALineas.First;
    finally
      ALineas.EnableControls;
      FreeAndNil(IdsDeposito);
    end;
  end;
end;

procedure QuitarLineasHistoricoVenta(ALineas: TDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    CerrarLineaPendiente(ALineas);
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        if EsLineaHistoricoDeposito(
             ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) then
          ALineas.Delete
        else
          ALineas.Next;
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

procedure RestaurarDepositosApartadosVenta(
  ALineas: TDataSet;
  AApartadas: TClientDataSet);
begin
  if AApartadas.Active and (not AApartadas.IsEmpty) then
  begin
    CerrarLineaPendiente(ALineas);
    ALineas.DisableControls;
    try
      AApartadas.First;
      while not AApartadas.Eof do
      begin
        CopiarRegistroVenta(AApartadas, ALineas);
        AApartadas.Next;
      end;
      AApartadas.EmptyDataSet;
      ALineas.First;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

function HayLineasConCantidadCero(ALineas: TDataSet): Boolean;
var
  Marcador: TBookmark;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active and not ALineas.IsEmpty then
  begin
    Marcador := ALineas.GetBookmark;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof and not Result do
      begin
        Result := ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat = 0;
        if not Result then
          ALineas.Next;
      end;
    finally
      if ALineas.BookmarkValid(Marcador) then
        ALineas.GotoBookmark(Marcador);
      ALineas.FreeBookmark(Marcador);
      ALineas.EnableControls;
    end;
  end;
end;

function VentaCajaSinContenido(ALineas: TClientDataSet): Boolean;
var
  Copia: TClientDataSet;

  function TieneContenido(ADatos: TDataSet): Boolean;
  const
    CAMPOS: array[0..3] of string = (
      'CODIGO_ART_FACLIN', 'CODIGO_UNIDAD_FACLIN',
      'DESCRIPCION_ARTICULO_FACLIN', 'DESCRIPCION_VARIACION_FACLIN');
    PRECIOS: array[0..1] of string = (
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN',
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN');
  var
    Nombre: string;
    Campo: TField;
  begin
    Result := False;
    for Nombre in CAMPOS do
    begin
      Campo := ADatos.FindField(Nombre);
      if Assigned(Campo) and (Trim(Campo.AsString) <> '') then
        Result := True;
    end;
    for Nombre in PRECIOS do
    begin
      Campo := ADatos.FindField(Nombre);
      if Assigned(Campo) and (Campo.AsFloat <> 0) then
        Result := True;
    end;
  end;

begin
  Result := True;
  if Assigned(ALineas) and ALineas.Active then
  begin
    Result := not TieneContenido(ALineas);
    if Result then
    begin
      Copia := TClientDataSet.Create(nil);
      try
        Copia.CloneCursor(ALineas, True);
        Copia.First;
        while Result and not Copia.Eof do
        begin
          Result := not TieneContenido(Copia);
          Copia.Next;
        end;
      finally
        Copia.Free;
      end;
    end;
  end;
end;

function OperacionVentaVacia(ALineas: TDataSet): Boolean;
begin
  Result := True;
  if Assigned(ALineas) and ALineas.Active then
  begin
    if ALineas.State in [dsEdit, dsInsert] then
      ALineas.Cancel;
    Result := ALineas.IsEmpty;
  end;
end;

procedure EscribirFechaCabeceraVenta(
  ACabecera: TDataSet;
  const AFecha: TDateTime);
var
  bPost: Boolean;
begin
  bPost := False;
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) then
  begin
    if ACabecera.State = dsBrowse then
    begin
      ACabecera.Edit;
      bPost := True;
    end;
    ACabecera.FieldByName('FECHA_FAC').AsDateTime := AFecha;
    if bPost then
      ACabecera.Post;
  end;
end;

procedure RellenarAtributosLineaDesdeSku(
  ALineas: TDataSet;
  const ASku: string;
  const ALookup: IArticulosAtributosLookup);
var
  Valores: TArray<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  i: Integer;
begin
  if (Trim(ASku) <> '') and Assigned(ALookup) then
  begin
    Valores := ALookup.ObtenerAtributosDeSku(ASku);
    if Length(Valores) > 0 then
    begin
      if not (ALineas.State in [dsEdit, dsInsert]) then
        ALineas.Edit;
      for V in Valores do
      begin
        i := V.Orden;
        if (i >= 1) and (i <= 5) then
          ALineas.FieldByName(
            'ATTR' + IntToStr(i) + '_VALOR').AsString := V.Valor;
      end;
    end;
  end;
end;

procedure CargarAvsValidosArticulo(
  const ACodArt: string;
  AOrden: Integer;
  const ALookup: IArticulosAtributosLookup;
  out AAvs: TArray<string>);
var
  Vals: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  SetLength(AAvs, 0);
  if (Trim(ACodArt) <> '') and (AOrden >= 1) and (AOrden <= 5) and
     Assigned(ALookup) then
  begin
    Vals := ALookup.ObtenerAvsEnSkus(ACodArt, AOrden);
    SetLength(AAvs, Length(Vals));
    for i := 0 to High(Vals) do
      AAvs[i] := Vals[i].Valor;
  end;
end;

function PrepararArticuloLineaVenta(
  ALineas, ACabecera: TDataSet;
  const ACodigo: string;
  AEsLecturaScanner, AActualizandoDepositos: Boolean;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  AConsultarStock, ARecalcularPrecio: TAccionCodigoCaja):
  TResultadoPreparacionArticuloVenta;
var
  Resolucion: TArtResolucionEntrada;
  sCodigoLimpio: string;
  sSkuPreferido: string;
  sSkuResuelto: string;
begin
  Result := Default(TResultadoPreparacionArticuloVenta);
  Result.ConservoImportesExistentes := ALineas.State = dsEdit;
  sSkuPreferido := ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
  sCodigoLimpio := UpperCase(Trim(ACodigo));
  if (sCodigoLimpio <> '') and Assigned(AValidador) then
  begin
    if AEsLecturaScanner then
    begin
      // FZ-ISSUE-231: como TAplicacionEntradaCaja.ResolverEntrada, si no es
      // un codigo de barras se resuelve como codigo de articulo o SKU (lo
      // que la aplicacion de entrada ya habia resuelto llega aqui como SKU).
      Resolucion := AValidador.ResolverCodigoBarras(sCodigoLimpio);
      if not Resolucion.Encontrado then
        Resolucion := AValidador.Resolver(sCodigoLimpio);
    end
    else if Result.ConservoImportesExistentes then
    begin
      Resolucion := AValidador.ResolverConSku(
        sCodigoLimpio,
        sSkuPreferido);
    end
    else
      Resolucion := AValidador.Resolver(sCodigoLimpio);
    if Resolucion.Encontrado then
    begin
      Result.IdentificadoPorCodigoBarras :=
        Resolucion.Tipo = atcCodigoBarras;
      sSkuResuelto := Resolucion.CodigoSku;
      if sSkuResuelto = '' then
        sSkuResuelto := Resolucion.CodigoArticulo;
      // Revalidar el mismo SKU conserva el precio pactado; sustituirlo
      // requiere resolver los importes del artículo nuevo.
      Result.ConservoImportesExistentes :=
        Result.ConservoImportesExistentes and
        (Trim(sSkuPreferido) <> '') and
        SameText(sSkuPreferido, sSkuResuelto);
      ALineas.DisableControls;
      try
        EscribirDatosBaseArticulo(ALineas, Resolucion);
        if Resolucion.CodigoSku <> '' then
        begin
          // El SKU pendiente ya resuelve los datos y escribe la unidad.
          if not AActualizandoDepositos then
            EscribirDatosArticuloResuelto(ALineas, ACabecera,
              Resolucion.CodigoArticulo, AResolver);
          PrepararSkuResuelto(
            ALineas,
            Resolucion.CodigoSku,
            AActualizandoDepositos,
            Result.ConservoImportesExistentes,
            AConsultarStock,
            ARecalcularPrecio);
          Result.Preparado := True;
        end
        else if Resolucion.RequiereSku then
        begin
          PrepararSkuPendiente(
            ALineas,
            ACabecera,
            Resolucion.CodigoArticulo,
            AActualizandoDepositos,
            Result.ConservoImportesExistentes,
            AResolver,
            AConsultarStock);
          Result.Preparado := True;
        end
        else
          Result.MotivoRechazo := Resolucion.Mensaje;
      finally
        ALineas.EnableControls;
      end;
    end;
  end;
end;

function ResolverDocumentoCierreVenta(
  AEsFactura: Boolean;
  const ASerieSimplificada, ASerieFactura: string;
  const AFechaFactura: TDateTime;
  AHayRectificacion: Boolean): TDocumentoCierreVenta;
begin
  Result.Serie := ASerieSimplificada;
  Result.TipoFactura := 'SIMPLIFICADA';
  Result.FechaFactura := 0;
  if AEsFactura then
  begin
    Result.Serie := ASerieFactura;
    Result.TipoFactura := 'NORMAL';
    Result.FechaFactura := AFechaFactura;
  end
  else if AHayRectificacion then
    Result.TipoFactura := 'RECTIFICATIVA';
end;

end.

{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaVentaCliente                                         }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas del cambio de cliente en la venta de caja: limpieza de las         }
{    lineas de deposito del cliente anterior, cabecera de venta al             }
{    contado, volcado del cliente a la cabecera y decision de autocarga        }
{    de depositos.                                                             }
{                                                                              }
{    Sale de TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate, donde          }
{    vivia mezclado con el grid y las etiquetas. No conoce formularios,        }
{    DevExpress ni UniDAC: trabaja sobre TDataSet y records de                 }
{    inLibCajaVentaIntf, y se prueba con un TClientDataSet en memoria          }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibCajaVentaCliente;

interface

uses
  Data.DB,
  inLibArticulosResolverIntf,
  inLibCajaVentaIntf;

// Una tarifa de cliente sin IVA se ignora y conserva la tarifa actual.
function ResolverTarifaVentaCaja(ATarifas: TDataSet;
  const ASolicitada, AActual, ADefecto: string;
  out AAviso: string): string;

// Precio de una línea en ATarifa. Lo que no tiene precio en ella se cobra
// con ARespaldo, la tarifa por defecto de caja (vacío: sin respaldo).
// ATarifaAplicada dice de cuál salió (FZ-ISSUE-727).
function ResolverPrecioVentaCaja(const AResolver: IArticulosResolver;
  const AArticulo, ASku, ATarifa, ARespaldo: string; AFecha: TDateTime;
  out ATarifaAplicada: string): TArticuloPrecio;

// Comprueba todos los precios antes de cambiar ninguna línea. ARespaldadas
// son los SKU que se cobran con ARespaldo por no tener precio en ATarifa.
function CambiarTarifaVentaCaja(ALineas, ACabecera: TDataSet;
  const ATarifa, ARespaldo: string; const AResolver: IArticulosResolver;
  out AError: string; out ARespaldadas: TArray<string>): Boolean;

// Una linea vino de deposito cuando VIENE_DE_DEPOSITO es 'S', 'A' o 'H'
// (historico). La misma regla protege el borrado por atajo en la ventana
// de caja.
function EsLineaDeposito(const AVieneDeDeposito: string): Boolean;

// Deposito ya cerrado cargado solo para consulta (Ver historico en F2):
// no se edita, no suma y no pasa al cobro.
function EsLineaHistoricoDeposito(const AVieneDeDeposito: string): Boolean;

// Cierra la linea pendiente (cancela la vacia, graba la que tiene
// articulo) y borra las lineas de deposito del cliente anterior.
procedure LimpiarLineasDeposito(ALineas: TDataSet);

// Deja la cabecera como venta al contado: datos del cliente vacios,
// tarifa por defecto e impuestos incluidos.
procedure EscribirCabeceraVentaContado(
  ACabecera: TDataSet;
  const ATarifaDefault: string);

// Vuelca el cliente a la cabecera de la venta. La forma de pago del
// cliente solo pisa la de la cabecera cuando viene informada.
procedure EscribirCabeceraClienteVenta(
  ACabecera: TDataSet;
  const ACliente: TClienteCaja);

// Los depositos solo se cargan solos si el cliente permite deuda y el
// parametro de autocarga esta activo.
function DebeCargarDepositosCliente(
  const AEsPermiteDeuda: string;
  AAutoCargar: Boolean): Boolean;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibMsgCaja;

function TarifaCajaDisponible(ATarifas: TDataSet;
  const ACodigo: string): Boolean;
begin
  Result := (Trim(ACodigo) <> '') and
    ATarifas.Locate('CODIGO_TAR', Trim(ACodigo), [loCaseInsensitive]);
  if Result then
    Result := (ATarifas.FieldByName('ESACTIVO_TAR').AsString = 'S') and
      (ATarifas.FieldByName('ESIMP_INCL_TAR').AsString = 'S');
end;

function ResolverTarifaVentaCaja(ATarifas: TDataSet;
  const ASolicitada, AActual, ADefecto: string;
  out AAviso: string): string;
var
  Inexistente: Boolean;
begin
  AAviso := '';
  Result := Trim(ASolicitada);
  if not TarifaCajaDisponible(ATarifas, Result) then
  begin
    Inexistente := (Result <> '') and
      (not ATarifas.Locate('CODIGO_TAR', Result, [loCaseInsensitive]) or
       (ATarifas.FieldByName('ESACTIVO_TAR').AsString <> 'S'));
    if (not Inexistente) and TarifaCajaDisponible(ATarifas, AActual) then
      Result := Trim(AActual)
    else
      Result := Trim(ADefecto);
    if not TarifaCajaDisponible(ATarifas, Result) then
      raise EInvalidOp.Create(SErrorTarifaCajaNoDisponible);
    if Inexistente then
      AAviso := Format(SAvisoTarifaCajaInexistente,
        [ASolicitada, Result]);
  end;
end;

function PrecioVentaCajaValido(const APrecio: TArticuloPrecio): Boolean;
begin
  Result := APrecio.TieneRegistro and APrecio.EsImpIncl;
end;

function ResolverPrecioVentaCaja(const AResolver: IArticulosResolver;
  const AArticulo, ASku, ATarifa, ARespaldo: string; AFecha: TDateTime;
  out ATarifaAplicada: string): TArticuloPrecio;
begin
  ATarifaAplicada := ATarifa;
  Result := AResolver.ResolverPrecio(AArticulo, ASku, ATarifa, AFecha);
  if not PrecioVentaCajaValido(Result) and (Trim(ARespaldo) <> '') and
     not SameText(Trim(ARespaldo), Trim(ATarifa)) then
  begin
    ATarifaAplicada := Trim(ARespaldo);
    Result := AResolver.ResolverPrecio(AArticulo, ASku, ATarifaAplicada,
      AFecha);
  end;
end;

function CambiarTarifaVentaCaja(ALineas, ACabecera: TDataSet;
  const ATarifa, ARespaldo: string; const AResolver: IArticulosResolver;
  out AError: string; out ARespaldadas: TArray<string>): Boolean;
type
  TCambioPrecio = record
    Posicion: TBookmark;
    Precio: TArticuloPrecio;
    Tarifa: string;
  end;
var
  Cambios: TList<TCambioPrecio>;
  Cambio: TCambioPrecio;
  Posicion: TBookmark;
  Articulo, Sku: string;
begin
  AError := '';
  ARespaldadas := nil;
  Result := True;
  Cambios := TList<TCambioPrecio>.Create;
  ALineas.DisableControls;
  Posicion := ALineas.Bookmark;
  try
    ALineas.First;
    while not ALineas.Eof and Result do
    begin
      Articulo := Trim(ALineas.FieldByName('CODIGO_ART_FACLIN').AsString);
      Sku := Trim(ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
      // Depósitos, abonos y devoluciones conservan el precio pactado.
      if (Articulo <> '') and (Sku <> '') and
         (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat > 0) and
         not EsLineaDeposito(ALineas.FieldByName(
           'VIENE_DE_DEPOSITO').AsString) and
         not SameText(ALineas.FieldByName(
           'TIPO_ARTICULO_FACLIN').AsString, 'ABONO') then
      begin
        Cambio.Posicion := ALineas.Bookmark;
        Cambio.Precio := ResolverPrecioVentaCaja(AResolver, Articulo, Sku,
          ATarifa, ARespaldo, ACabecera.FieldByName('FECHA_FAC').AsDateTime,
          Cambio.Tarifa);
        Result := PrecioVentaCajaValido(Cambio.Precio);
        if Result then
        begin
          Cambios.Add(Cambio);
          if not SameText(Cambio.Tarifa, Trim(ATarifa)) then
            ARespaldadas := ARespaldadas + [Sku];
        end
        else
          AError := Format(SErrorPrecioTarifaCajaNoDisponible,
            [Sku, ATarifa]);
      end;
      ALineas.Next;
    end;
    if Result then
    begin
      for Cambio in Cambios do
      begin
        ALineas.Bookmark := Cambio.Posicion;
        ALineas.Edit;
        ALineas.FieldByName('CODIGO_TAR_FACLIN').AsString := Cambio.Tarifa;
        ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString := 'S';
        ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat :=
          Cambio.Precio.PrecioSalida;
        ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
          Cambio.Precio.PorcentajeDto;
        ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
        ALineas.FieldByName(
          'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
        ALineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
        ALineas.Post;
      end;
      ACabecera.Edit;
      ACabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
        ATarifa;
      ACabecera.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString := 'S';
    end;
  finally
    if ALineas.BookmarkValid(Posicion) then
      ALineas.Bookmark := Posicion;
    ALineas.EnableControls;
    Cambios.Free;
  end;
end;

function EsLineaDeposito(const AVieneDeDeposito: string): Boolean;
begin
  Result := (AVieneDeDeposito = 'S') or (AVieneDeDeposito = 'A') or
    EsLineaHistoricoDeposito(AVieneDeDeposito);
end;

function EsLineaHistoricoDeposito(const AVieneDeDeposito: string): Boolean;
begin
  Result := Trim(AVieneDeDeposito) = 'H';
end;

procedure LimpiarLineasDeposito(ALineas: TDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    // Linea a medio meter: la vacia se cancela para evitar el Abort de
    // BeforePost; la que ya tiene articulo se graba.
    if ALineas.State in [dsInsert, dsEdit] then
    begin
      if Trim(ALineas.FieldByName('CODIGO_ART_FACLIN').AsString) = '' then
        ALineas.Cancel
      else
        ALineas.Post;
    end;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        if EsLineaDeposito(
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

procedure EscribirCabeceraVentaContado(
  ACabecera: TDataSet;
  const ATarifaDefault: string);
begin
  ACabecera.Edit;
  ACabecera.FieldByName('CODIGO_CLI_FAC').AsString := '';
  ACabecera.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('NIF_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('MOVIL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('DIRECCION1_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('DIRECCION2_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('POBLACION_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('PROVINCIA_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString := '';
  ACabecera.FieldByName(
    'CODIGO_UNIDAD_TRAMITADORA_FAC').AsString := '';
  // FZ-ISSUE-370: las marcas fiscales del cliente anterior no pueden
  // sobrevivir en la venta al contado (exento dejaria el ticket sin IVA).
  ACabecera.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_FAC').AsString := ATarifaDefault;
  ACabecera.FieldByName(
    'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString := 'S';
end;

procedure EscribirCabeceraClienteVenta(
  ACabecera: TDataSet;
  const ACliente: TClienteCaja);
begin
  ACabecera.Edit;
  ACabecera.FieldByName('CODIGO_CLI_FAC').AsString :=
    ACliente.Codigo;
  ACabecera.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString :=
    ACliente.RazonSocial;
  ACabecera.FieldByName('NIF_CLIENTE_FAC').AsString :=
    ACliente.Nif;
  ACabecera.FieldByName('MOVIL_CLIENTE_FAC').AsString :=
    ACliente.Movil;
  ACabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString :=
    ACliente.Email;
  ACabecera.FieldByName('DIRECCION1_CLIENTE_FAC').AsString :=
    ACliente.Direccion1;
  ACabecera.FieldByName('DIRECCION2_CLIENTE_FAC').AsString :=
    ACliente.Direccion2;
  ACabecera.FieldByName('POBLACION_CLIENTE_FAC').AsString :=
    ACliente.Poblacion;
  ACabecera.FieldByName('PROVINCIA_CLIENTE_FAC').AsString :=
    ACliente.Provincia;
  ACabecera.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString :=
    ACliente.CodigoPostal;
  ACabecera.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString :=
    ACliente.CodigoPais;
  ACabecera.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString :=
    ACliente.NombrePais;
  ACabecera.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString :=
    ACliente.CodigoOficinaContable;
  ACabecera.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString :=
    ACliente.CodigoOrganoGestor;
  ACabecera.FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString :=
    ACliente.CodigoUnidadTramitadora;
  ACabecera.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString :=
    ACliente.EsIvaRecargo;
  ACabecera.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString :=
    ACliente.EsIvaExento;
  ACabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString :=
    ACliente.EsRegimenEspecialAgricola;
  ACabecera.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
    ACliente.EsRetenciones;
  ACabecera.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString :=
    ACliente.EsIntracomunitario;
  if Trim(ACliente.CodigoFormaPago) <> '' then
    ACabecera.FieldByName('FORMA_PAGO_FAC').AsString :=
      ACliente.CodigoFormaPago;
  ACabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
    ACliente.TarifaArticulo;
end;

function DebeCargarDepositosCliente(
  const AEsPermiteDeuda: string;
  AAutoCargar: Boolean): Boolean;
begin
  Result := SameText(AEsPermiteDeuda, 'S') and AAutoCargar;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaRectificacion                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Carga una factura origen como rectificativa o devolución de caja.         }
{******************************************************************************}
unit inLibCajaRectificacion;

interface

uses
  System.Generics.Collections,
  Data.DB, inLibCajaTipos, inLibCajaVentaIntf;

type
  TServicioRectificacionCaja = class(
    TInterfacedObject,
    IServicioRectificacionCaja)
  private
    FRepositorio: IRepositorioConsultasCaja;
    procedure ResolverDocumentoOrigen(var ASerie, ANumero: string);
    procedure CopiarTipoFacturaCompleta(AOrigen, ADestino: TDataSet);
    procedure CopiarRetencionOrigen(AOrigen, ADestino: TDataSet);
    procedure CopiarCliente(
      AOrigen, ADestino: TDataSet);
    function CantidadPendienteLinea(
      AOrigen: TDataSet;
      ADevuelto: TDictionary<string, Double>): Double;
    function ImportePendienteLinea(AOrigen: TDataSet;
      ADevuelto: TDictionary<string, Currency>): Currency;
    function QuedaAlgoPorDevolver(AOrigen: TDataSet): Boolean;
    procedure CopiarLinea(
      AOrigen, ADestino: TDataSet;
      ASigno, ACantidad: Double; AImportePendiente: Currency);
    procedure CopiarLineas(
      AOrigen, ADestino: TDataSet;
      ASigno: Double);
    procedure CopiarAtributos(AOrigen, ADestino: TDataSet);
    procedure CopiarCampoAtributo(AOrigen, ADestino: TDataSet;
      const ANombre: string);
    // Devuelve el líquido de la factura de origen.
    function CargarOrigen(
      const ASerie, ANumero: string;
      ASigno: Double;
      ACabecera, ALineas: TDataSet): Currency;
  public
    constructor Create(
      const ARepositorio: IRepositorioConsultasCaja);
    procedure CargarDevolucion(
      const ASerie, ANumero: string;
      ACabecera, ALineas: TDataSet);
    function Cargar(
      const ASerie, ANumero: string;
      ATipo: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa;
      ACabecera, ALineas: TDataSet
    ): TResultadoRectificacionCaja;
  end;

procedure ConservarLineasDevolucionCaja(ALineas: TDataSet;
  const ASeleccion: TArray<string>);

implementation

uses
  inLibFormatoDocumento, inLibFormatoDocumentoLecturasIntf,
  System.SysUtils, System.StrUtils, inLibMsgCaja, inLibErroresBBDD,
  inLibMsgReparaciones;

const
  TIPO_FACTURA_COMPLETA_RECTIFICACION = 'NORMAL';

procedure ConservarLineasDevolucionCaja(ALineas: TDataSet;
  const ASeleccion: TArray<string>);
var
  iConservadas: Integer;
begin
  iConservadas := 0;
  ALineas.DisableControls;
  try
    ALineas.First;
    while not ALineas.Eof do
      if (IndexText(ALineas.FieldByName('LINEA_FACLIN').AsString,
          ASeleccion) >= 0) and
        (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat < 0) then
      begin
        Inc(iConservadas);
        ALineas.Next;
      end
      else
        ALineas.Delete;
  finally
    ALineas.EnableControls;
  end;
  if iConservadas = 0 then
    raise EValidacionBBDD.Create(SErrorDevolucionArregloSinLineas);
end;

constructor TServicioRectificacionCaja.Create(
  const ARepositorio: IRepositorioConsultasCaja);
begin
  inherited Create;
  FRepositorio := ARepositorio;
end;

procedure TServicioRectificacionCaja.CopiarCliente(
  AOrigen, ADestino: TDataSet);
var
  Indice: Integer;
  CampoOrigen: TField;
  CampoDestino: TField;
begin
  if not (ADestino.State in [dsEdit, dsInsert]) then
  begin
    ADestino.Edit;
  end;
  for Indice := 0 to AOrigen.FieldCount - 1 do
  begin
    CampoOrigen := AOrigen.Fields[Indice];
    CampoDestino := ADestino.FindField(
      CampoOrigen.FieldName);
    if Assigned(CampoDestino) and
       (Pos('CLIENTE', CampoOrigen.FieldName) > 0) then
    begin
      CampoDestino.Value := CampoOrigen.Value;
    end;
  end;
  ADestino.FieldByName('CODIGO_CLI_FAC').AsString :=
    AOrigen.FieldByName('CODIGO_CLI_FAC').AsString;
  ADestino.Post;
end;

procedure TServicioRectificacionCaja.CopiarCampoAtributo(
  AOrigen, ADestino: TDataSet; const ANombre: string);
var
  CampoOrigen, CampoDestino: TField;
begin
  CampoOrigen := AOrigen.FindField(ANombre + '_FACLIN');
  CampoDestino := ADestino.FindField(ANombre);
  if Assigned(CampoOrigen) and Assigned(CampoDestino) and
     not CampoOrigen.IsNull then
    CampoDestino.Value := CampoOrigen.Value;
end;

procedure TServicioRectificacionCaja.CopiarAtributos(
  AOrigen, ADestino: TDataSet);
var
  Partes: TArray<string>;
  Campo: TField;
  Indice, NumeroAtributos: Integer;
  Nombre: string;
begin
  // La factura guarda ATTR*_FACLIN; Caja usa ATTR* sin ese sufijo.
  // El SKU permite recuperar el desglose de tickets antiguos.
  Partes := nil;
  Campo := AOrigen.FindField('CODIGO_UNIDAD_FACLIN');
  if Assigned(Campo) then
    Partes := Campo.AsString.Split(['/']);
  NumeroAtributos := 0;
  Campo := AOrigen.FindField('NUM_ATRIBUTOS_FACLIN');
  if Assigned(Campo) then
    NumeroAtributos := Campo.AsInteger;
  for Indice := 1 to 5 do
  begin
    Nombre := 'ATTR' + IntToStr(Indice);
    CopiarCampoAtributo(AOrigen, ADestino, Nombre + '_NOMBRE');
    CopiarCampoAtributo(AOrigen, ADestino, Nombre + '_VALOR');
    Campo := ADestino.FindField(Nombre + '_VALOR');
    if Assigned(Campo) then
    begin
      if (Trim(Campo.AsString) = '') and (Indice < Length(Partes)) then
        Campo.AsString := Partes[Indice];
      if (Trim(Campo.AsString) <> '') and (Indice > NumeroAtributos) then
        NumeroAtributos := Indice;
    end;
  end;
  Campo := ADestino.FindField('NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
  if Assigned(Campo) then
    Campo.AsInteger := NumeroAtributos;
end;

// Clave con la que se reparte lo ya devuelto entre las líneas de la venta:
// el SKU o, en una línea sin SKU ni artículo, su descripción (FZ-998).
// Es el mismo criterio que SQL_MISMA_LINEA_DEVUELTA. Vacía si la línea no
// se puede reconocer (anticipos y artículos sin SKU).
function ClaveLineaDevuelta(AOrigen: TDataSet): string;
var
  oDescripcion: TField;
begin
  Result := UpperCase(Trim(AOrigen.FieldByName(
    'CODIGO_UNIDAD_FACLIN').AsString));
  oDescripcion := AOrigen.FindField('DESCRIPCION_ARTICULO_FACLIN');
  if (Result = '') and Assigned(oDescripcion) and
    (Trim(AOrigen.FieldByName('CODIGO_ART_FACLIN').AsString) = '') and
    (Trim(oDescripcion.AsString) <> '') then
  begin
    Result := #1 + UpperCase(Trim(oDescripcion.AsString));
  end;
end;

// FZ-ISSUE-392: unidades de la línea que quedan por devolver. Lo ya
// devuelto del SKU (CANTIDAD_DEVUELTA_VENTA, igual en todas sus líneas) se
// descuenta de las líneas de ese SKU por orden; ADevuelto lleva lo que
// falta por descontar. Sin esa columna o sin SKU no se descuenta nada.
function TServicioRectificacionCaja.CantidadPendienteLinea(
  AOrigen: TDataSet;
  ADevuelto: TDictionary<string, Double>): Double;
var
  oDevuelta, oSku: TField;
  rPorDescontar, rDescuento: Double;
  sSku: string;
begin
  Result := Abs(AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat);
  oDevuelta := AOrigen.FindField('CANTIDAD_DEVUELTA_VENTA');
  oSku := AOrigen.FindField('CODIGO_UNIDAD_FACLIN');
  sSku := ClaveLineaDevuelta(AOrigen);
  if Assigned(oDevuelta) and Assigned(oSku) and (sSku <> '') then
  begin
    if not ADevuelto.TryGetValue(sSku, rPorDescontar) then
      rPorDescontar := oDevuelta.AsFloat;
    rDescuento := rPorDescontar;
    if rDescuento > Result then
      rDescuento := Result;
    if rDescuento < 0 then
      rDescuento := 0;
    ADevuelto.AddOrSetValue(sSku, rPorDescontar - rDescuento);
    Result := Result - rDescuento;
  end;
end;

function TServicioRectificacionCaja.ImportePendienteLinea(
  AOrigen: TDataSet;
  ADevuelto: TDictionary<string, Currency>): Currency;
var
  sSku: string;
  dDevuelto, dAplicado: Currency;
begin
  Result := Abs(AOrigen.FieldByName('TOTAL_FACLIN').AsCurrency);
  sSku := ClaveLineaDevuelta(AOrigen);
  if not ADevuelto.TryGetValue(sSku, dDevuelto) then
  begin
    dDevuelto := AOrigen.FieldByName('IMPORTE_DEVUELTO_VENTA').AsCurrency;
  end;
  dAplicado := dDevuelto;
  if dAplicado > Result then
  begin
    dAplicado := Result;
  end;
  if dAplicado < 0 then
  begin
    dAplicado := 0;
  end;
  ADevuelto.AddOrSetValue(sSku, dDevuelto - dAplicado);
  Result := Result - dAplicado;
end;

procedure TServicioRectificacionCaja.CopiarLinea(
  AOrigen, ADestino: TDataSet;
  ASigno, ACantidad: Double; AImportePendiente: Currency);
var
  Indice: Integer;
  CampoOrigen: TField;
  CampoDestino: TField;
  rProporcion: Double;
  sImporte: string;
  dPrecioConIva: Currency;
begin
  rProporcion := 1;
  if AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat <> 0 then
    rProporcion := ACantidad /
      Abs(AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat);
  ADestino.Append;
  for Indice := 0 to AOrigen.FieldCount - 1 do
  begin
    CampoOrigen := AOrigen.Fields[Indice];
    CampoDestino := ADestino.FindField(
      CampoOrigen.FieldName);
    if Assigned(CampoDestino) and
       (not CampoOrigen.IsNull) then
    begin
      CampoDestino.Value := CampoOrigen.Value;
    end;
  end;
  // Anticipos antiguos: se guardaba el precio base con IVA incluido.
  // Corregir su indicador al cargar evita convertir el IVA en descuento.
  if SameText(AOrigen.FieldByName('CODIGO_ART_FACLIN').AsString,
       'ANTICIPO') and
     (AOrigen.FindField('ESIMP_INCL_TARIFA_FACLIN') <> nil) and
     (ADestino.FindField('ESIMP_INCL_TARIFA_FACLIN') <> nil) and
     (AOrigen.FindField('PRECIO_SALIDA_FACLIN') <> nil) and
     (AOrigen.FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN') <> nil) and
     (AOrigen.FindField('PORCENTAJE_DTO_FACLIN') <> nil) and
     (AOrigen.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat = 0) and
     (Abs(AOrigen.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency -
       AOrigen.FieldByName(
         'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency) < 0.0001) then
    ADestino.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString := 'N';
  CopiarAtributos(AOrigen, ADestino);
  // La sustitutiva conserva ventas, devoluciones y líneas gratuitas.
  // Sólo diferencias y devoluciones fuerzan el signo negativo.
  if (ASigno < 0) and
     (ADestino.FindField('CANTIDAD_FACLIN') <> nil) then
    ADestino.FieldByName('CANTIDAD_FACLIN').AsFloat := ASigno * ACantidad;
  for sImporte in TArray<string>.Create(
    'TOTAL_FACLIN', 'TOTAL_FAC_SIVA_FACLIN') do
  begin
    if (ASigno < 0) and Assigned(ADestino.FindField(sImporte)) and
       Assigned(AOrigen.FindField(sImporte)) then
      ADestino.FieldByName(sImporte).AsCurrency :=
        ASigno * rProporcion *
        Abs(AOrigen.FieldByName(sImporte).AsCurrency);
  end;
  if (ASigno < 0) and (ACantidad > 0) and
    (AOrigen.FindField('IMPORTE_DEVUELTO_VENTA') <> nil) and
    not SameText(AOrigen.FieldByName('CODIGO_ART_FACLIN').AsString,
      'ANTICIPO') and
    (AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat > 0) then
  begin
    // El ultimo resto absorbe los centimos redondeados en abonos previos.
    dPrecioConIva := AImportePendiente / ACantidad;
    ADestino.FieldByName('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency :=
      dPrecioConIva;
    ADestino.FieldByName('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
      dPrecioConIva / (1 +
        AOrigen.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency / 100);
    ADestino.FieldByName('TOTAL_FACLIN').AsCurrency := -AImportePendiente;
  end;
  ADestino.Post;
end;

procedure TServicioRectificacionCaja.CopiarLineas(
  AOrigen, ADestino: TDataSet;
  ASigno: Double);
var
  oDevuelto: TDictionary<string, Double>;
  oImportes: TDictionary<string, Currency>;
  dImporte: Currency;
  rCantidad: Double;
  bDescuenta: Boolean;
begin
  oDevuelto := TDictionary<string, Double>.Create;
  oImportes := TDictionary<string, Currency>.Create;
  ADestino.DisableControls;
  try
    while not AOrigen.Eof do
    begin
      rCantidad := Abs(AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat);
      // Solo la devolución de unidades vendidas descuenta lo ya devuelto;
      // las líneas a cero o en negativo del origen se copian como antes.
      bDescuenta := (ASigno < 0) and
        (AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat > 0);
      if bDescuenta then
        rCantidad := CantidadPendienteLinea(AOrigen, oDevuelto);
      dImporte := 0;
      if bDescuenta and
        (AOrigen.FindField('IMPORTE_DEVUELTO_VENTA') <> nil) then
      begin
        dImporte := ImportePendienteLinea(AOrigen, oImportes);
      end;
      if (not bDescuenta) or (rCantidad > 0) then
      begin
        CopiarLinea(AOrigen, ADestino, ASigno, rCantidad, dImporte);
      end;
      AOrigen.Next;
    end;
  finally
    ADestino.EnableControls;
    FreeAndNil(oImportes);
    FreeAndNil(oDevuelto);
  end;
end;

// True si la venta no tiene líneas o alguna conserva unidades por devolver.
function TServicioRectificacionCaja.QuedaAlgoPorDevolver(
  AOrigen: TDataSet): Boolean;
var
  oDevuelto: TDictionary<string, Double>;
begin
  Result := AOrigen.IsEmpty;
  oDevuelto := TDictionary<string, Double>.Create;
  try
    AOrigen.First;
    while not AOrigen.Eof do
    begin
      if (AOrigen.FieldByName('CANTIDAD_FACLIN').AsFloat <= 0) or
         (CantidadPendienteLinea(AOrigen, oDevuelto) > 0) then
        Result := True;
      AOrigen.Next;
    end;
    AOrigen.First;
  finally
    FreeAndNil(oDevuelto);
  end;
end;

// FZ-ISSUE-369: la devolución o rectificación de una factura completa se
// calcula como ella (con el recargo y la retención del cliente); la caja
// deja la cabecera como SIMPLIFICADA, que no los lleva, y lo devuelto
// no cuadraba con lo cobrado.
procedure TServicioRectificacionCaja.CopiarTipoFacturaCompleta(
  AOrigen, ADestino: TDataSet);
var
  oTipoOrigen: TField;
begin
  oTipoOrigen := AOrigen.FindField('TIPO_FAC');
  if Assigned(oTipoOrigen) and
     Assigned(ADestino.FindField('TIPO_FAC')) and
     SameText(oTipoOrigen.AsString,
       TIPO_FACTURA_COMPLETA_RECTIFICACION) then
  begin
    if not (ADestino.State in [dsEdit, dsInsert]) then
      ADestino.Edit;
    ADestino.FieldByName('TIPO_FAC').AsString :=
      TIPO_FACTURA_COMPLETA_RECTIFICACION;
    ADestino.Post;
    CopiarRetencionOrigen(AOrigen, ADestino);
  end;
end;

// FZ-ISSUE-934: el abono de una factura completa lleva la retención de la
// factura que rectifica, no la vigente en la empresa. Una factura sin
// retención (por ejemplo, la creada desde un ticket con «Convertir en
// normal») se abona sin ella: con el indicador del cliente a 'N', porque
// con porcentaje 0 el cálculo tomaría el porcentaje de la empresa.
procedure TServicioRectificacionCaja.CopiarRetencionOrigen(
  AOrigen, ADestino: TDataSet);
var
  oPorcentaje: TField;
  oTotal: TField;
  bSinRetencion: Boolean;
begin
  oPorcentaje := AOrigen.FindField('PORCENTAJE_RETENCION_FAC');
  oTotal := AOrigen.FindField('TOTAL_RETENCION_FAC');
  if Assigned(oPorcentaje) and
     Assigned(ADestino.FindField('PORCENTAJE_RETENCION_FAC')) and
     Assigned(ADestino.FindField('ESRETENCIONES_CLIENTE_FAC')) then
  begin
    bSinRetencion := (oPorcentaje.AsCurrency = 0) or
      (Assigned(oTotal) and (oTotal.AsCurrency = 0));
    if not (ADestino.State in [dsEdit, dsInsert]) then
      ADestino.Edit;
    if bSinRetencion then
    begin
      ADestino.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString := 'N';
      ADestino.FieldByName('PORCENTAJE_RETENCION_FAC').AsCurrency := 0;
    end
    else
      ADestino.FieldByName('PORCENTAJE_RETENCION_FAC').AsCurrency :=
        oPorcentaje.AsCurrency;
    ADestino.Post;
  end;
end;

function TServicioRectificacionCaja.CargarOrigen(
  const ASerie, ANumero: string;
  ASigno: Double;
  ACabecera, ALineas: TDataSet): Currency;
var
  ConsultaCabecera: IResultadoConsultaCaja;
  ConsultaLineas: IResultadoConsultaCaja;
begin
  if (not Assigned(ACabecera)) or
     (not Assigned(ALineas)) then
  begin
    raise Exception.Create(
      STextoLosDatosDeLaOperacionDeCajaCaja);
  end;
  ConsultaCabecera :=
    FRepositorio.ConsultarCabeceraFactura(
      ASerie,
      ANumero);
  if ConsultaCabecera.DataSet.IsEmpty then
  begin
    raise Exception.Create(
      FormatearMensajeDocumentos(
        FormatoDocumentoFacturaDelProveedor(FRepositorio, ASerie, ANumero),
        SErrorBorradorRectificarCajaNoEncontrado,
        [ASerie, ANumero]));
  end;
  ConsultaLineas :=
    FRepositorio.ConsultarLineasFactura(
      ASerie,
      ANumero);
  // FZ-ISSUE-392: antes de tocar la operación en curso. Aviso, no error.
  if (ASigno < 0) and
     (not QuedaAlgoPorDevolver(ConsultaLineas.DataSet)) then
    raise EValidacionBBDD.Create(
      FormatearMensajeDocumentos(
        FormatoDocumentoFacturaDelProveedor(FRepositorio, ASerie, ANumero),
        SErrorDevolucionCajaSinPendiente,
        [ASerie, ANumero]));
  CopiarCliente(
    ConsultaCabecera.DataSet,
    ACabecera);
  CopiarTipoFacturaCompleta(
    ConsultaCabecera.DataSet,
    ACabecera);
  Result := 0;
  if Assigned(ConsultaCabecera.DataSet.FindField('TOTAL_LIQUIDO_FAC')) then
    Result := ConsultaCabecera.DataSet.FieldByName(
      'TOTAL_LIQUIDO_FAC').AsCurrency;
  CopiarLineas(
    ConsultaLineas.DataSet,
    ALineas,
    ASigno);
end;

procedure TServicioRectificacionCaja.ResolverDocumentoOrigen(
  var ASerie, ANumero: string);
var
  Resolver: IResolverDocumentoDevolucionCaja;
  Documento: TDocumentoOrigenDevolucionCaja;
begin
  if Supports(FRepositorio, IResolverDocumentoDevolucionCaja, Resolver) then
  begin
    Documento := Resolver.ResolverDocumentoDevolucion(ASerie, ANumero);
    ASerie := Documento.Serie;
    ANumero := Documento.Numero;
  end;
end;

procedure TServicioRectificacionCaja.CargarDevolucion(
  const ASerie, ANumero: string;
  ACabecera, ALineas: TDataSet);
var
  sSerie, sNumero: string;
begin
  sSerie := ASerie;
  sNumero := ANumero;
  ResolverDocumentoOrigen(sSerie, sNumero);
  CargarOrigen(
    sSerie,
    sNumero,
    -1,
    ACabecera,
    ALineas);
end;

function TServicioRectificacionCaja.Cargar(
  const ASerie, ANumero: string;
  ATipo: TTipoRectificativaCaja;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa;
  ACabecera, ALineas: TDataSet
): TResultadoRectificacionCaja;
var
  Signo: Double;
  DescripcionTipo: string;
begin
  case ATipo of
    trcDiferencias:
      begin
        Signo := -1;
        DescripcionTipo := 'POR DIFERENCIAS';
      end;
    trcSustitutiva:
      begin
        Signo := 1;
        DescripcionTipo := 'SUSTITUTIVA';
      end;
  else
    begin
      raise Exception.Create(
        SErrorTipoRectificativaCajaNoIndicado);
    end;
  end;
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  ResolverDocumentoOrigen(Result.Serie, Result.Numero);
  Result.LiquidoOrigen := CargarOrigen(
    Result.Serie,
    Result.Numero,
    Signo,
    ACabecera,
    ALineas);
  Result.Tipo := ATipo;
  Result.TratamientoMovimientos := ATratamientoMovimientos;
  if ATipo = trcSustitutiva then
    Result.TratamientoMovimientos := tmrReemplazarOriginales;
  Result.DescripcionTipo := DescripcionTipo;
end;

end.

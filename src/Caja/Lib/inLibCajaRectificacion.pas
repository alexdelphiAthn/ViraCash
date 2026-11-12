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
    function QuedaAlgoPorDevolver(AOrigen: TDataSet): Boolean;
    procedure CopiarLinea(
      AOrigen, ADestino: TDataSet;
      ASigno, ACantidad: Double);
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
  if Assigned(oDevuelta) and Assigned(oSku) and
     (Trim(oSku.AsString) <> '') then
  begin
    sSku := UpperCase(Trim(oSku.AsString));
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

procedure TServicioRectificacionCaja.CopiarLinea(
  AOrigen, ADestino: TDataSet;
  ASigno, ACantidad: Double);
var
  Indice: Integer;
  CampoOrigen: TField;
  CampoDestino: TField;
  rProporcion: Double;
  sImporte: string;
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
  ADestino.Post;
end;

procedure TServicioRectificacionCaja.CopiarLineas(
  AOrigen, ADestino: TDataSet;
  ASigno: Double);
var
  oDevuelto: TDictionary<string, Double>;
  rCantidad: Double;
  bDescuenta: Boolean;
begin
  oDevuelto := TDictionary<string, Double>.Create;
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
      if (not bDescuenta) or (rCantidad > 0) then
        CopiarLinea(AOrigen, ADestino, ASigno, rCantidad);
      AOrigen.Next;
    end;
  finally
    ADestino.EnableControls;
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
      'Los datos de la operación de caja no están configurados');
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

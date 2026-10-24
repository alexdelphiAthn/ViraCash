{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaLotes                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lote y serie en la caja (F-LOTEC-015): al leer un artículo trazable se    }
{    decide con la regla común (FEFO o modal en LOTE,   }
{    serie leída o elegida, que esté en el almacén y no repetida en el         }
{    ticket); un lote ya en el ticket suma en su línea y una serie nunca.      }
{    «Elegir lote» reparte la línea conservando sus condiciones de venta.      }
{    La propuesta descuenta los lotes ya consumidos en el ticket.              }
{******************************************************************************}
unit inLibCajaLotes;

interface

uses
  System.SysUtils, Data.DB, Datasnap.DBClient, inLibTrazabilidad,
  inLibArticulosValidadorIntf, inLibLotesPersistenciaIntf,
  inLibLotesVisualIntf, inLibAsignacionLoteLectura, inLibCajaEntradaIntf,
  inLibLecturaGs1Pendiente;

const
  CAMPO_LOTE_CAJA = 'LOTE_FACLIN';
  CAMPO_CADUCIDAD_CAJA = 'FECHA_CADUCIDAD_FACLIN';
  CAMPO_CANTIDAD_CAJA = 'CANTIDAD_FACLIN';
  CAMPO_ARTICULO_CAJA = 'CODIGO_ART_FACLIN';
  CAMPO_SKU_CAJA = 'CODIGO_UNIDAD_FACLIN';
  CAMPO_DESCRIPCION_CAJA = 'DESCRIPCION_ARTICULO_FACLIN';
  CAMPO_ES_SERIE_CAJA = 'ESSERIE_LOTE';

type
  TConsolidarLoteCaja = reference to function(
    const ACodigoSku, ALote: string): Boolean;
  TAnadirLecturasCaja = reference to procedure(const ACodigoSku: string;
    ALecturas: Integer);
  TAvisoLoteCaja = reference to procedure(const AMensaje: string);

  TConfiguracionLotesCaja = record
    Activacion: TActivacionTrazabilidad;
    Lectura: ILecturaTrazabilidadArticulo;
    Repositorio: IRepositorioLotes;
    Selector: ISelectorLotesVisual;
    Lineas: TClientDataSet;
    Almacen: TFunc<string>;
    SiguienteNumeroLinea: TFunc<string>;
    // vgerLoteAsignarFefo / vgerSerieExigirEnVenta.
    AsignarFefo: Boolean;
    ExigirSerieEnVenta: Boolean;
    DiasAvisoGeneral: Integer;
    // Suma una unidad a otra línea del mismo SKU y lote (la de la caja).
    Consolidar: TConsolidarLoteCaja;
    // Tras escribir el lote en la línea: totales de la rejilla.
    Recalcular: TProc;
    Avisar: TAvisoLoteCaja;
    // Política general antes de repartir, también al elegir con F9.
    ValidarStock: TProc<TDataSet>;
    // Unidades que no caben en la línea grabada (series, varios lotes):
    // se dan de alta como lecturas del SKU, fuera del Post.
    AnadirLecturas: TAnadirLecturasCaja;
    // FZ-ISSUE-524: el reparto ha añadido líneas por un cursor clonado. Se
    // avisa desde dentro del Post (a menudo con DisableControls y con el
    // editor de la rejilla abierto): quien lo recibe debe recargar la
    // rejilla más tarde, no en el momento.
    LineasAnadidas: TProc;
    // FZ-ISSUE-525: el reparto se canceló y la línea ya grabada volvió a
    // lo grabado. Igual que el anterior, se avisa desde dentro del Post:
    // quien lo recibe debe soltar más tarde la edición de la rejilla, que
    // sigue mostrando lo tecleado.
    LineaDevuelta: TProc;
    procedure Validar;
  end;

  TTrazabilidadEntradaCaja = class(TInterfacedObject,
    ITrazabilidadEntradaCaja)
  private
    FConfig: TConfiguracionLotesCaja;
    FModoUltimo: TModoTrazabilidad;
    FPendientes: TArray<TAsignacionLote>;
    // Una lectura ya decidió el lote de la línea que se está dando de alta:
    // su Post no vuelve a decidir.
    FDecisionEnCurso: Boolean;
    procedure DecidirAlGrabar(ALinea: TDataSet;
      const AGs1: TLecturaGs1Pendiente);
    function SeriesTicket: TArray<string>;
    function Contexto(const AArticulo, ADescripcion: string;
      const ACantidad: Double; AFefo: Boolean): TContextoLoteLectura;
    function ModoArticulo(const AArticulo: string): TModoTrazabilidad;
    function UnidadesTicket(const ASku, ALote: string;
      AExcluir: TDataSet): Double;
    function DecidirCaja(const AResolucion: TArtResolucionEntrada;
      const ACantidad: Double; AFefo: Boolean;
      AExcluir: TDataSet; APermitirSinStock: Boolean = True):
      TDecisionLoteLectura;
    procedure AplicarReparto(ALinea: TDataSet;
      const AAsignaciones: TArray<TAsignacionLote>);
    procedure RestaurarLineaEditada(ALinea: TDataSet);
  public
    constructor Create(const AConfig: TConfiguracionLotesCaja);
    function Decidir(const AResolucion: TArtResolucionEntrada;
      out AAsignaciones: TArray<TAsignacionLote>): Boolean;
    function Consolidar(const ACodigoSku: string;
      const AAsignacion: TAsignacionLote): Boolean;
    procedure EscribirLote(const AAsignacion: TAsignacionLote);
    // Reparte la línea con sus precios y descuentos en una copia por lote.
    // Devuelve cero: no hay lecturas pendientes ni búsquedas por EAN.
    function ElegirLoteLineaActual(out ACodigoSku: string): Integer;
    // BeforePost: una venta sin lote de un artículo con lote lo decide
    // (FEFO, modal o serie: el código tecleado en la rejilla no
    // pasa por la lectura); una serie es una sola unidad; sin modo, sin
    // lote.
    procedure ValidarLinea(ALinea: TDataSet);
    // Devolución de ticket: las líneas copiadas traen el lote; se marca
    // cuáles son series para el ticket.
    procedure MarcarSeries;
    procedure ValidarExistencias(ALinea: TDataSet);
    procedure ValidarTicket;
  end;

implementation

uses
  System.Math, System.Classes, System.Variants, inLibMsgTrazabilidad;

procedure EscribirLoteLineaCaja(ALineas: TDataSet;
  const AAsignacion: TAsignacionLote; AEsSerie: Boolean);
begin
  if not (ALineas.State in dsEditModes) then
    ALineas.Edit;
  ALineas.FieldByName(CAMPO_LOTE_CAJA).AsString := AAsignacion.Lote;
  if ALineas.FindField(CAMPO_ES_SERIE_CAJA) <> nil then
  begin
    if AEsSerie then
      ALineas.FieldByName(CAMPO_ES_SERIE_CAJA).AsString := 'S'
    else
      ALineas.FieldByName(CAMPO_ES_SERIE_CAJA).AsString := 'N';
  end;
  if AAsignacion.FechaCaducidad = SIN_FECHA then
    ALineas.FieldByName(CAMPO_CADUCIDAD_CAJA).Clear
  else
    ALineas.FieldByName(CAMPO_CADUCIDAD_CAJA).AsDateTime :=
      AAsignacion.FechaCaducidad;
  if AAsignacion.Cantidad <> 0 then
    ALineas.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat := AAsignacion.Cantidad;
end;

procedure TConfiguracionLotesCaja.Validar;
begin
  if not Assigned(Lectura) then
    raise EArgumentNilException.Create('Lectura');
  if not Assigned(Repositorio) then
    raise EArgumentNilException.Create('Repositorio');
  if not Assigned(Selector) then
    raise EArgumentNilException.Create('Selector');
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(Almacen) then
    raise EArgumentNilException.Create('Almacen');
  if not Assigned(Avisar) then
    raise EArgumentNilException.Create('Avisar');
end;

constructor TTrazabilidadEntradaCaja.Create(
  const AConfig: TConfiguracionLotesCaja);
begin
  inherited Create;
  AConfig.Validar;
  FConfig := AConfig;
  FModoUltimo := mtNinguna;
end;

function TTrazabilidadEntradaCaja.SeriesTicket: TArray<string>;
var
  oClon: TClientDataSet;
  sLote: string;
begin
  // Las ya grabadas en el ticket (la línea en inserción aún no está).
  Result := [];
  oClon := TClientDataSet.Create(nil);
  try
    oClon.CloneCursor(FConfig.Lineas, True);
    oClon.First;
    while not oClon.Eof do
    begin
      sLote := Trim(oClon.FieldByName(CAMPO_LOTE_CAJA).AsString);
      if (sLote <> '') and
         (oClon.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat > 0) then
        Result := Result + [sLote];
      oClon.Next;
    end;
  finally
    FreeAndNil(oClon);
  end;
end;

function TTrazabilidadEntradaCaja.ModoArticulo(
  const AArticulo: string): TModoTrazabilidad;
begin
  Result := mtNinguna;
  if Trim(AArticulo) <> '' then
    Result := FConfig.Activacion.ModoEfectivo(
      FConfig.Lectura.Leer(AArticulo).Modo);
end;

function TTrazabilidadEntradaCaja.Contexto(const AArticulo,
  ADescripcion: string; const ACantidad: Double;
  AFefo: Boolean): TContextoLoteLectura;
var
  rTrazabilidad: TTrazabilidadArticulo;
begin
  rTrazabilidad := FConfig.Lectura.Leer(AArticulo);
  Result := Default(TContextoLoteLectura);
  Result.Activacion := FConfig.Activacion;
  Result.Modo := rTrazabilidad.Modo;
  Result.EsCaducidadObligatoria := rTrazabilidad.EsCaducidadObligatoria;
  Result.Sentido := sllSalida;
  Result.CodigoAlmacen := FConfig.Almacen();
  Result.DescripcionArticulo := ADescripcion;
  Result.Cantidad := ACantidad;
  Result.AsignarFefo := AFefo;
  Result.ExigirSerieEnVenta := FConfig.ExigirSerieEnVenta;
  Result.DiasAviso := DiasAvisoEfectivos(rTrazabilidad.DiasAviso,
                                         FConfig.DiasAvisoGeneral);
  Result.Hoy := Date;
  Result.SeriesDocumento := SeriesTicket;
end;

function TTrazabilidadEntradaCaja.UnidadesTicket(
  const ASku, ALote: string; AExcluir: TDataSet): Double;
var
  Clon: TClientDataSet;
  Excluida: string;
  Deposito: TField;
begin
  Result := 0;
  Excluida := '';
  if Assigned(AExcluir) then
    Excluida := AExcluir.FieldByName('LINEA_FACLIN').AsString;
  Clon := TClientDataSet.Create(nil);
  try
    Clon.CloneCursor(FConfig.Lineas, True);
    Clon.First;
    while not Clon.Eof do
    begin
      Deposito := Clon.FindField('VIENE_DE_DEPOSITO');
      if ((Excluida = '') or
          (Clon.FieldByName('LINEA_FACLIN').AsString <> Excluida)) and
         SameText(Trim(Clon.FieldByName(CAMPO_SKU_CAJA).AsString), ASku) and
         SameText(Trim(Clon.FieldByName(CAMPO_LOTE_CAJA).AsString), ALote) and
         ((Deposito = nil) or (Trim(Deposito.AsString) = '')) then
        Result := Result + Max(0,
          Clon.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat);
      Clon.Next;
    end;
  finally
    Clon.Free;
  end;
end;

function TTrazabilidadEntradaCaja.DecidirCaja(
  const AResolucion: TArtResolucionEntrada;
  const ACantidad: Double; AFefo: Boolean;
  AExcluir: TDataSet; APermitirSinStock: Boolean): TDecisionLoteLectura;
var
  Datos: TContextoLoteLectura;
  Resolucion: TArtResolucionEntrada;
  Lotes, Vigentes: TLotesDisponibles;
  Lote, Neto: TLoteDisponible;
  Propuesta: TSeleccionLotes;
  Pendiente: TAsignacionLote;
  Total, DisponibleLeido: Double;
begin
  Datos := Contexto(AResolucion.CodigoArticulo,
    AResolucion.DescripcionArticulo, ACantidad, AFefo);
  Resolucion := AResolucion;
  if FConfig.Activacion.ModoEfectivo(Datos.Modo) = mtLote then
  begin
    Lotes := FConfig.Repositorio.Disponibles(AResolucion.CodigoSku,
      Datos.CodigoAlmacen);
    Datos.UsarDisponibles := True;
    Datos.Disponibles := [];
    Vigentes := [];
    Total := 0;
    DisponibleLeido := 0;
    for Lote in Lotes do
    begin
      Neto := Lote;
      Neto.Cantidad := Max(0, Lote.Cantidad - UnidadesTicket(
        AResolucion.CodigoSku, Lote.Lote, AExcluir));
      Datos.Disponibles := Datos.Disponibles + [Neto];
      Total := Total + Neto.Cantidad;
      if SameText(Lote.Lote, AResolucion.Lote) then
        DisponibleLeido := Neto.Cantidad;
      if not EstaCaducado(Lote.FechaCaducidad, Datos.Hoy) then
        Vigentes := Vigentes + [Neto];
    end;
    Propuesta := SeleccionarFefo(mtLote, Vigentes, ACantidad, Datos.Hoy);
    if APermitirSinStock and (ACantidad > Total + 0.000001) then
    begin
      // La política general decide si permite vender el exceso sin lote.
      // Nunca se carga ese exceso a un lote físico ni se deja en negativo.
      Result := Default(TDecisionLoteLectura);
      Result.Resultado := rllAsignado;
      Result.Asignaciones := Propuesta.Asignaciones;
      if Propuesta.CantidadPendiente > 0 then
      begin
        Pendiente := Default(TAsignacionLote);
        Pendiente.Cantidad := Propuesta.CantidadPendiente;
        Result.Asignaciones := Result.Asignaciones + [Pendiente];
      end;
    end
    else
    begin
      if (Trim(Resolucion.Lote) <> '') and
         (DisponibleLeido + 0.000001 < ACantidad) then
      begin
        Resolucion.Lote := '';
        Resolucion.FechaCaducidad := SIN_FECHA;
        Datos.AsignarFefo := False;
      end;
      if Length(Propuesta.Asignaciones) > 1 then
        Datos.AsignarFefo := False;
      Result := DecidirLoteLectura(Resolucion, Datos,
        FConfig.Repositorio, FConfig.Selector);
    end;
  end
  else
    Result := DecidirLoteLectura(Resolucion, Datos,
      FConfig.Repositorio, FConfig.Selector);
end;

// FZ-ISSUE-525: lo que el cajero cambió en la línea ya grabada (p. ej.
// las unidades) vuelve a lo grabado cuando se cancela el reparto. La línea
// sigue en edición, pero lo que se ve cuadra con el total. Lo grabado se
// lee con un cursor clonado: OldValue de un TClientDataSet da el valor de
// antes del registro de cambios, que la caja no aplica.
procedure TTrazabilidadEntradaCaja.RestaurarLineaEditada(ALinea: TDataSet);
var
  Clon: TClientDataSet;
  Campo: TField;
  Grabado: TField;
  Indice: Integer;
begin
  if ALinea.State = dsEdit then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(FConfig.Lineas, True);
      if Clon.Locate('LINEA_FACLIN',
           ALinea.FieldByName('LINEA_FACLIN').AsString, []) then
        for Indice := 0 to ALinea.FieldCount - 1 do
        begin
          Campo := ALinea.Fields[Indice];
          Grabado := Clon.FindField(Campo.FieldName);
          if (Campo.FieldKind = fkData) and not Campo.ReadOnly and
             (Grabado <> nil) and
             not VarSameValue(Campo.Value, Grabado.Value) then
            Campo.Value := Grabado.Value;
        end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TTrazabilidadEntradaCaja.AplicarReparto(ALinea: TDataSet;
  const AAsignaciones: TArray<TAsignacionLote>);
var
  Clon: TClientDataSet;
  Valores: TArray<Variant>;
  Indice, Otro, Campo, NumeroLinea: Integer;
  PuntoGuardado: Int64;
  Cantidad, Total: Double;
  Sku, Lote: string;
  Validacion: TValidacionSalidaLote;
begin
  if Assigned(FConfig.ValidarStock) then
    FConfig.ValidarStock(ALinea);
  // Prevalidar todo antes de escribir: incluye otras líneas y lotes
  // repetidos en el reparto, excluyendo la línea que se sustituye.
  Sku := Trim(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString);
  Total := 0;
  for Indice := 0 to High(AAsignaciones) do
  begin
    Cantidad := AAsignaciones[Indice].Cantidad;
    if Cantidad <= 0 then
      Abort;
    Total := Total + Cantidad;
    Lote := AAsignaciones[Indice].Lote;
    if Trim(Lote) <> '' then
    begin
      Cantidad := UnidadesTicket(Sku, Lote, ALinea);
      for Otro := 0 to High(AAsignaciones) do
        if SameText(Lote, AAsignaciones[Otro].Lote) then
          Cantidad := Cantidad + AAsignaciones[Otro].Cantidad;
      Validacion := FConfig.Repositorio.ValidarSalida(Sku,
        FConfig.Almacen(), Lote, Cantidad);
      if (Validacion.Resultado = rslLoteInexistente) or
         (Cantidad > Validacion.StockDisponible + 0.000001) then
      begin
        FConfig.Avisar(Format(SErrorCantidadLoteSuperaStock,
          [Lote, FormatFloat('0.###', Cantidad),
           FormatFloat('0.###', Validacion.StockDisponible)]));
        Abort;
      end;
    end;
  end;
  if not SameValue(Total,
    ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat, 0.000001) then
  begin
    FConfig.Avisar(SErrorRepartoLotesCaja);
    Abort;
  end;
  SetLength(Valores, ALinea.FieldCount);
  for Campo := 0 to ALinea.FieldCount - 1 do
    Valores[Campo] := ALinea.Fields[Campo].Value;
  Clon := TClientDataSet.Create(nil);
  try
    Clon.CloneCursor(FConfig.Lineas, True);
    PuntoGuardado := Clon.SavePoint;
    NumeroLinea := 0;
    Clon.First;
    while not Clon.Eof do
    begin
      NumeroLinea := Max(NumeroLinea,
        StrToIntDef(Clon.FieldByName('LINEA_FACLIN').AsString, 0));
      Clon.Next;
    end;
    try
      // El original permanece en su buffer de edición hasta su Post.
      for Indice := 1 to High(AAsignaciones) do
      begin
        Clon.Append;
        for Campo := 0 to Clon.FieldCount - 1 do
          if (Clon.Fields[Campo].FieldKind = fkData) and
             not Clon.Fields[Campo].ReadOnly then
            Clon.Fields[Campo].Value := Valores[Campo];
        Inc(NumeroLinea, 10);
        if Assigned(FConfig.SiguienteNumeroLinea) then
          Clon.FieldByName('LINEA_FACLIN').AsString :=
            FConfig.SiguienteNumeroLinea()
        else
          Clon.FieldByName('LINEA_FACLIN').AsString :=
            Format('%.4d', [NumeroLinea]);
        EscribirLoteLineaCaja(Clon, AAsignaciones[Indice],
          FModoUltimo = mtSerie);
        Clon.Post;
      end;
      EscribirLoteLineaCaja(ALinea, AAsignaciones[0],
        FModoUltimo = mtSerie);
    except
      Clon.Cancel;
      Clon.SavePoint := PuntoGuardado;
      for Campo := 0 to ALinea.FieldCount - 1 do
        if (ALinea.Fields[Campo].FieldKind = fkData) and
           not ALinea.Fields[Campo].ReadOnly then
          ALinea.Fields[Campo].Value := Valores[Campo];
      raise;
    end;
  finally
    Clon.Free;
  end;
end;

function TTrazabilidadEntradaCaja.Decidir(
  const AResolucion: TArtResolucionEntrada;
  out AAsignaciones: TArray<TAsignacionLote>): Boolean;
var
  rDecision: TDecisionLoteLectura;
begin
  FModoUltimo := ModoArticulo(AResolucion.CodigoArticulo);
  FDecisionEnCurso := False;
  // La lectura ya trae lo suyo: no queda nada para el Post de la línea.
  DescartarLecturaGs1;
  if Length(FPendientes) > 0 then
  begin
    // Lo que el cajero ya eligió en el modal de «Elegir lote».
    AAsignaciones := [FPendientes[0]];
    FPendientes := Copy(FPendientes, 1, MaxInt);
    Result := True;
    FDecisionEnCurso := True;
  end
  else
  begin
    rDecision := DecidirCaja(AResolucion, 1,
      FConfig.AsignarFefo, nil);
    AAsignaciones := rDecision.Asignaciones;
    Result := rDecision.Resultado in [rllSinLote, rllAsignado];
    FDecisionEnCurso := Result and (Length(AAsignaciones) > 0);
    // Un caducado o un lote sin bastante stock avisan y dejan seguir.
    if rDecision.Error <> '' then
      FConfig.Avisar(rDecision.Error)
    else if rDecision.Aviso <> '' then
      FConfig.Avisar(rDecision.Aviso);
  end;
end;

function TTrazabilidadEntradaCaja.Consolidar(const ACodigoSku: string;
  const AAsignacion: TAsignacionLote): Boolean;
begin
  Result := (FModoUltimo <> mtSerie) and (Trim(AAsignacion.Lote) <> '') and
    Assigned(FConfig.Consolidar) and
    FConfig.Consolidar(ACodigoSku, AAsignacion.Lote);
  if Result then
    FDecisionEnCurso := False;
end;

procedure TTrazabilidadEntradaCaja.EscribirLote(
  const AAsignacion: TAsignacionLote);
var
  rAsignacion: TAsignacionLote;
begin
  // Cada lectura es una unidad: la cantidad de la línea no cambia aquí.
  rAsignacion := AAsignacion;
  rAsignacion.Cantidad := 0;
  FDecisionEnCurso := False;
  EscribirLoteLineaCaja(FConfig.Lineas, rAsignacion,
                        FModoUltimo = mtSerie);
  if FConfig.Lineas.State in dsEditModes then
    FConfig.Lineas.Post;
  if Assigned(FConfig.Recalcular) then
    FConfig.Recalcular();
end;

function TTrazabilidadEntradaCaja.ElegirLoteLineaActual(
  out ACodigoSku: string): Integer;
var
  Decision: TDecisionLoteLectura;
  Resolucion: TArtResolucionEntrada;
  Lineas: TClientDataSet;
begin
  Result := 0;
  Lineas := FConfig.Lineas;
  ACodigoSku := Trim(Lineas.FieldByName(CAMPO_SKU_CAJA).AsString);
  Resolucion.Clear;
  Resolucion.Encontrado := True;
  Resolucion.CodigoArticulo :=
    Trim(Lineas.FieldByName(CAMPO_ARTICULO_CAJA).AsString);
  Resolucion.CodigoSku := ACodigoSku;
  Resolucion.DescripcionArticulo :=
    Lineas.FieldByName(CAMPO_DESCRIPCION_CAJA).AsString;
  FModoUltimo := ModoArticulo(Resolucion.CodigoArticulo);
  if (ACodigoSku <> '') and
     (Lineas.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat > 0) and
     RequiereLote(FModoUltimo) then
  begin
    Decision := DecidirCaja(Resolucion,
      Lineas.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat, False, Lineas, False);
    if Decision.Error <> '' then
      FConfig.Avisar(Decision.Error)
    else if Decision.Aviso <> '' then
      FConfig.Avisar(Decision.Aviso);
    if (Decision.Resultado = rllAsignado) and
       (Length(Decision.Asignaciones) > 0) then
    begin
      AplicarReparto(Lineas, Decision.Asignaciones);
      Lineas.Post;
      if Assigned(FConfig.Recalcular) then
        FConfig.Recalcular();
      if (Length(Decision.Asignaciones) > 1) and
         Assigned(FConfig.LineasAnadidas) then
        FConfig.LineasAnadidas();
    end;
  end;
end;

procedure TTrazabilidadEntradaCaja.ValidarExistencias(ALinea: TDataSet);
var
  Cantidad: Double;
  Sku, Lote: string;
  Validacion: TValidacionSalidaLote;
  Deposito: TField;
begin
  Cantidad := ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat;
  Sku := Trim(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString);
  Lote := Trim(ALinea.FieldByName(CAMPO_LOTE_CAJA).AsString);
  Deposito := ALinea.FindField('VIENE_DE_DEPOSITO');
  if (Cantidad > 0) and (Sku <> '') and (Lote <> '') and
     ((Deposito = nil) or (Trim(Deposito.AsString) = '')) and
     RequiereLote(ModoArticulo(
       ALinea.FieldByName(CAMPO_ARTICULO_CAJA).AsString)) then
  begin
    Cantidad := Cantidad + UnidadesTicket(Sku, Lote, ALinea);
    Validacion := FConfig.Repositorio.ValidarSalida(Sku,
      FConfig.Almacen(), Lote, Cantidad);
    if (Validacion.Resultado <> rslCorrecta) or
       (Cantidad > Validacion.StockDisponible + 0.000001) then
    begin
      FConfig.Avisar(Format(SErrorCantidadLoteSuperaStock,
        [Lote, FormatFloat('0.###', Cantidad),
         FormatFloat('0.###', Validacion.StockDisponible)]));
      Abort;
    end;
  end;
end;

procedure TTrazabilidadEntradaCaja.ValidarTicket;
var
  Clon: TClientDataSet;
begin
  Clon := TClientDataSet.Create(nil);
  try
    Clon.CloneCursor(FConfig.Lineas, True);
    Clon.First;
    while not Clon.Eof do
    begin
      ValidarExistencias(Clon);
      Clon.Next;
    end;
  finally
    FreeAndNil(Clon);
  end;
end;

procedure TTrazabilidadEntradaCaja.MarcarSeries;
var
  oClon: TClientDataSet;
begin
  // En un clon: marcar no debe pasar por el BeforePost de la caja.
  oClon := TClientDataSet.Create(nil);
  try
    oClon.CloneCursor(FConfig.Lineas, True);
    oClon.First;
    while not oClon.Eof do
    begin
      if Trim(oClon.FieldByName(CAMPO_LOTE_CAJA).AsString) <> '' then
      begin
        oClon.Edit;
        if ModoArticulo(oClon.FieldByName(
             CAMPO_ARTICULO_CAJA).AsString) = mtSerie then
          oClon.FieldByName(CAMPO_ES_SERIE_CAJA).AsString := 'S'
        else
          oClon.FieldByName(CAMPO_ES_SERIE_CAJA).AsString := 'N';
        oClon.Post;
      end;
      oClon.Next;
    end;
  finally
    FreeAndNil(oClon);
  end;
end;

procedure TTrazabilidadEntradaCaja.DecidirAlGrabar(ALinea: TDataSet;
  const AGs1: TLecturaGs1Pendiente);
var
  aPendientes: TArray<TAsignacionLote>;
  dCantidad: Double;
  iAsignacion: Integer;
  iUnidad: Integer;
  oAnadir: TAnadirLecturasCaja;
  rDecision: TDecisionLoteLectura;
  rResolucion: TArtResolucionEntrada;
  rUnidad: TAsignacionLote;
  sSku: string;
begin
  rResolucion.Clear;
  rResolucion.Encontrado := True;
  rResolucion.CodigoArticulo :=
    Trim(ALinea.FieldByName(CAMPO_ARTICULO_CAJA).AsString);
  sSku := Trim(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString);
  rResolucion.CodigoSku := sSku;
  rResolucion.DescripcionArticulo :=
    ALinea.FieldByName(CAMPO_DESCRIPCION_CAJA).AsString;
  dCantidad := ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat;
  // GS1 tecleado en la rejilla: su lote o serie cuenta como leído (se
  // valida contra el almacén y avisa si no hay bastante).
  rResolucion.Lote := AGs1.Lote;
  rResolucion.Serie := AGs1.Serie;
  rResolucion.FechaCaducidad := AGs1.FechaCaducidad;
  FModoUltimo := ModoArticulo(rResolucion.CodigoArticulo);
  rDecision := DecidirCaja(rResolucion, dCantidad,
    FConfig.AsignarFefo, ALinea);
  if rDecision.Error <> '' then
    FConfig.Avisar(rDecision.Error)
  else if rDecision.Aviso <> '' then
    FConfig.Avisar(rDecision.Aviso);
  // Cancelado o rechazado: la línea no se graba y vuelve a lo grabado.
  if not (rDecision.Resultado in [rllSinLote, rllAsignado]) then
  begin
    if ALinea.State = dsEdit then
    begin
      RestaurarLineaEditada(ALinea);
      if Assigned(FConfig.LineaDevuelta) then
        FConfig.LineaDevuelta();
    end;
    Abort;
  end;
  if (Length(rDecision.Asignaciones) > 0) and
     (FModoUltimo <> mtSerie) then
  begin
    AplicarReparto(ALinea, rDecision.Asignaciones);
    if (Length(rDecision.Asignaciones) > 1) and
       Assigned(FConfig.LineasAnadidas) then
      FConfig.LineasAnadidas();
  end
  else if Length(rDecision.Asignaciones) > 0 then
  begin
    rUnidad := rDecision.Asignaciones[0];
    if rUnidad.Cantidad <= 0 then
      rUnidad.Cantidad := dCantidad;
    EscribirLoteLineaCaja(ALinea, rUnidad, FModoUltimo = mtSerie);
    // El resto, una lectura por unidad (como «Elegir lote»).
    aPendientes := [];
    for iAsignacion := 1 to High(rDecision.Asignaciones) do
    begin
      rUnidad := rDecision.Asignaciones[iAsignacion];
      rUnidad.Cantidad := 1;
      for iUnidad := 1 to Ceil(rDecision.Asignaciones[iAsignacion].Cantidad)
      do
        aPendientes := aPendientes + [rUnidad];
    end;
    if (Length(aPendientes) > 0) and Assigned(FConfig.AnadirLecturas) then
    begin
      FPendientes := FPendientes + aPendientes;
      oAnadir := FConfig.AnadirLecturas;
      iUnidad := Length(aPendientes);
      TThread.ForceQueue(nil,
        procedure
        begin
          oAnadir(sSku, iUnidad);
        end);
    end;
  end;
end;

procedure TTrazabilidadEntradaCaja.ValidarLinea(ALinea: TDataSet);
var
  oCampo: TField;
  rGs1: TLecturaGs1Pendiente;
  oModo: TModoTrazabilidad;
  sLote: string;
  Validacion: TValidacionSalidaLote;
begin
  sLote := Trim(ALinea.FieldByName(CAMPO_LOTE_CAJA).AsString);
  // Venta sin lote de un artículo con lote (no las líneas de depósito ni
  // las devoluciones, que llevan el de su ticket).
  oCampo := ALinea.FindField('VIENE_DE_DEPOSITO');
  if (sLote = '') and not FDecisionEnCurso and
     (ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat > 0) and
     (Trim(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString) <> '') and
     ((oCampo = nil) or (Trim(oCampo.AsString) = '')) and
     RequiereLote(ModoArticulo(
       ALinea.FieldByName(CAMPO_ARTICULO_CAJA).AsString)) then
  begin
    if not TomarLecturaGs1(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString,
                           rGs1) then
      rGs1 := Default(TLecturaGs1Pendiente);
    DecidirAlGrabar(ALinea, rGs1);
    sLote := Trim(ALinea.FieldByName(CAMPO_LOTE_CAJA).AsString);
  end;
  if sLote <> '' then
  begin
    oModo := ModoArticulo(ALinea.FieldByName(CAMPO_ARTICULO_CAJA).AsString);
    if not RequiereLote(oModo) then
    begin
      ALinea.FieldByName(CAMPO_LOTE_CAJA).Clear;
      ALinea.FieldByName(CAMPO_CADUCIDAD_CAJA).Clear;
    end
    else if (oModo = mtSerie) and
            not SameValue(Abs(ALinea.FieldByName(
              CAMPO_CANTIDAD_CAJA).AsFloat), 1) then
    begin
      FConfig.Avisar(Format(SErrorLineaCantidadSerie,
        [ALinea.FieldByName(CAMPO_ARTICULO_CAJA).AsString]));
      Abort;
    end;
    if (oModo = mtLote) and
       (ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat > 0) and
       ((oCampo = nil) or (Trim(oCampo.AsString) = '')) then
    begin
      Validacion := FConfig.Repositorio.ValidarSalida(
        ALinea.FieldByName(CAMPO_SKU_CAJA).AsString,
        FConfig.Almacen(), sLote,
        ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat);
      if ALinea.FieldByName(CAMPO_CANTIDAD_CAJA).AsFloat +
         UnidadesTicket(ALinea.FieldByName(CAMPO_SKU_CAJA).AsString,
           sLote, ALinea) > Validacion.StockDisponible + 0.000001 then
      begin
        rGs1 := Default(TLecturaGs1Pendiente);
        rGs1.Lote := sLote;
        DecidirAlGrabar(ALinea, rGs1);
      end;
    end;
    ValidarExistencias(ALinea);
  end;
end;

end.

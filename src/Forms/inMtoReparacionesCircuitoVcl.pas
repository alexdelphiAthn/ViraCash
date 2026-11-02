{******************************************************************************}
{  Módulo: inMtoReparacionesCircuitoVcl. Tipo: Formulario (Mto)                }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Ejecución de órdenes, tiempos, materiales y reparto visible.   }
{******************************************************************************}
unit inMtoReparacionesCircuitoVcl;

interface

uses
  System.Classes, Vcl.Controls, Data.DB, cxGridDBTableView, cxPC,
  UniDataReparacionesPantalla, inMtoGarantiasReparacionesVcl;

type
  TPanelDetalleCircuito = class(TPanelReparaciones)
  public
    procedure Configurar(AOrigen: TDataSource;
      const ACampos, ATitulos: array of string);
  end;

  TAccionCircuitoOrden = (acoAcuerdo, acoConcepto, acoTiempo,
    acoCorregirTiempo, acoPausar, acoMaterial, acoCerrar, acoRefrescar,
    acoCrearAlbaran, acoImputar, acoLiberar, acoEntrega, acoRetorno,
    acoHoja, acoEconomico, acoTodos);

  TPanelCircuitoOrden = class(TPanelReparaciones)
  private
    FResumen: TcxGridDBTableView;
    FPestanas: TcxPageControl;
    FEnlaceRotulo: TDataLink;
    procedure CrearAcciones;
    procedure CrearDetalles;
    procedure CrearDetalle(const ATitulo: string; AOrigen: TDataSource;
      const ACampos, ATitulos: array of string);
    procedure PulsarAccion(Sender: TObject);
    procedure Ejecutar(AAccion: TAccionCircuitoOrden);
    function Linea: Int64;
    procedure EditarAcuerdo;
    procedure EditarConcepto;
    procedure EditarTiempo(ACorregir: Boolean);
    procedure PausarTiempo;
    procedure EditarMaterial;
    procedure CerrarTecnico;
    procedure CrearAlbaran;
    procedure CrearTodos;
    procedure Imputar;
    procedure Liberar;
    procedure EntregaExterno(ARetorno: Boolean);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
    procedure AnadirPestana(APestana: TcxTabSheet);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, Vcl.Forms, Vcl.Graphics, cxGroupBox,
  cxButtons, cxCurrencyEdit,
  cxLabel, cxGrid, cxLookAndFeels, cxSplitter,
  inLibReparacionesCircuito, inLibMsgReparacionesCircuito,
  UniDataReparacionesDocumentoMemoria, UniDataReparacionesImputaciones,
  UniDataReparacionesEntregas,
  inMtoModalDatosOrden;

type
  TEnlaceRotuloOrden = class(TDataLink)
  private
    FRotulo: TcxLabel;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(ARotulo: TcxLabel; AOrigen: TDataSource);
  end;

constructor TEnlaceRotuloOrden.Create(ARotulo: TcxLabel;
  AOrigen: TDataSource);
begin
  inherited Create;
  FRotulo := ARotulo;
  DataSource := AOrigen;
  ActiveChanged;
end;

procedure TEnlaceRotuloOrden.ActiveChanged;
begin
  RecordChanged(nil);
end;

procedure TEnlaceRotuloOrden.RecordChanged(Field: TField);
begin
  FRotulo.Caption := SCircuitoSinOrden;
  if Active and not DataSet.IsEmpty then
    FRotulo.Caption := DataSet.FieldByName('ID_GAR').AsString;
end;

destructor TPanelCircuitoOrden.Destroy;
begin
  FreeAndNil(FEnlaceRotulo);
  inherited;
end;

procedure AjustarRejilla(AVista: TcxGridDBTableView);
begin
  // Barra horizontal siempre visible (sin ella las columnas que no caben no
  // se descubren con el ratón) y cabeceras en varias líneas en vez de
  // truncadas.
  TcxGrid(AVista.Control).LookAndFeel.ScrollbarMode := sbmClassic;
  AVista.OptionsView.HeaderAutoHeight := True;
end;

procedure FormatearHoras(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(AColumna.Properties).DecimalPlaces := 2;
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat := '#,##0.00';
end;

procedure TPanelDetalleCircuito.Configurar(AOrigen: TDataSource;
  const ACampos, ATitulos: array of string);
var
  oVista: TcxGridDBTableView;
  i: Integer;
begin
  FBotonera.Visible := False;
  oVista := CrearVista(alClient, 0, AOrigen);
  AjustarRejilla(oVista);
  for i := 0 to High(ACampos) do
    if SameText(ACampos[i], 'HORAS') then
      FormatearHoras(CrearColumna(oVista, ACampos[i], ATitulos[i], 150))
    else
      CrearColumna(oVista, ACampos[i], ATitulos[i], 150);
end;

function SiNo(AValor: Boolean): string;
begin
  Result := IfThen(AValor, 'S', 'N');
end;

function LeerSiNo(const AValor: string): Boolean;
begin
  if not SameText(AValor, 'S') and not SameText(AValor, 'N') then
    raise EArgumentException.Create(SCircuitoBooleano);
  Result := SameText(AValor, 'S');
end;

function Opcional(AValor: Currency; AExiste: Boolean): string;
begin
  Result := '';
  if AExiste then
    Result := CurrToStr(AValor);
end;

function LeerImporte(const ATexto, ACampo: string): Currency;
begin
  try
    Result := StrToCurr(ATexto);
  except
    on E: EConvertError do
      raise EArgumentException.CreateFmt(SCircuitoCampoFormato, [ACampo]);
  end;
end;

function LeerCantidad(const ATexto, ACampo: string): Double;
begin
  try
    Result := StrToFloat(ATexto);
  except
    on E: EConvertError do
      raise EArgumentException.CreateFmt(SCircuitoCampoFormato, [ACampo]);
  end;
end;

function LeerFecha(const ATexto, ACampo: string): TDateTime;
begin
  try
    Result := StrToDate(ATexto);
  except
    on E: EConvertError do
      raise EArgumentException.CreateFmt(SCircuitoCampoFormato, [ACampo]);
  end;
end;

function LeerInstante(const ATexto, ACampo: string): TDateTime;
begin
  try
    Result := StrToDateTime(ATexto);
  except
    on E: EConvertError do
      raise EArgumentException.CreateFmt(SCircuitoCampoFormato, [ACampo]);
  end;
end;

function FechaOpcional(const AValor, ACampo: string): TDateTime;
begin
  Result := 0;
  if Trim(AValor) <> '' then
    Result := LeerInstante(AValor, ACampo);
end;

function MonedaOpcional(const ATexto, ACampo: string): Currency;
begin
  Result := 0;
  if ATexto <> '' then
    Result := LeerImporte(ATexto, ACampo);
end;

function NumeroOpcional(const ATexto, ACampo: string): Double;
begin
  Result := 0;
  if ATexto <> '' then
    Result := LeerCantidad(ATexto, ACampo);
end;

constructor TPanelCircuitoOrden.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
var
  oSeparador: TcxSplitter;
begin
  inherited;
  CrearAcciones;
  FResumen := CrearVista(alTop, EscalarDpi(120), FDatos.Circuito.Resumen);
  AjustarRejilla(FResumen);
  CrearColumna(FResumen, 'LINEA', SCircuitoColNumero, 65);
  CrearColumna(FResumen, 'DESCRIPCION', SCircuitoTarea, 220);
  FormatearHoras(CrearColumna(FResumen, 'TOTAL',
    SCircuitoColTotal, 95));
  FormatearHoras(CrearColumna(FResumen, 'CLIENTE',
    SCircuitoColCliente, 95));
  FormatearHoras(CrearColumna(FResumen, 'ASEGURADORA',
    SCircuitoColAseguradora, 95));
  FormatearHoras(CrearColumna(FResumen, 'TALLER',
    SCircuitoTaller, 95));
  FormatearHoras(CrearColumna(FResumen, 'PENDIENTE',
    SCircuitoColPendiente, 110));
  FormatearHoras(CrearColumna(FResumen, 'HORAS_PREVISTAS',
    SCircuitoHorasPrevistas, 95));
  FormatearHoras(CrearColumna(FResumen, 'HORAS_REALES',
    SCircuitoColHorasReales, 95));
  FormatearHoras(CrearColumna(FResumen, 'HORAS_FACTURABLES',
    SCircuitoColHorasFacturables, 95));
  CrearColumna(FResumen, 'UTILIZADO', SCircuitoUtilizado, 95);
  CrearColumna(FResumen, 'DEVUELTO', SCircuitoDevuelto, 95);
  oSeparador := TcxSplitter.Create(Self);
  oSeparador.Parent := Self;
  oSeparador.AlignSplitter := salTop;
  oSeparador.Height := EscalarDpi(8);
  oSeparador.MinSize := EscalarDpi(80);
  oSeparador.HotZoneClassName := 'TcxMediaPlayer9Style';
  oSeparador.Control := FResumen.Control;
  oSeparador.Top := FResumen.Control.Top + FResumen.Control.Height;
  CrearDetalles;
end;

procedure TPanelCircuitoOrden.AnadirPestana(APestana: TcxTabSheet);
begin
  APestana.PageControl := FPestanas;
end;

procedure TPanelCircuitoOrden.CrearAcciones;
var
  oGrupos: TScrollBox;
  oCabecera: TcxGroupBox;
  oOrden: TcxLabel;
  oRotulo: TcxLabel;
  iGrupo: Integer;

  function Boton(AParent: TWinControl; const ATitulo: string;
    AAccion: TAccionCircuitoOrden; AFila: Integer): TcxButton;
  var
    oBoton: TcxButton;
  begin
    oBoton := TcxButton.Create(Self);
    oBoton.Parent := AParent;
    oBoton.SetBounds(EscalarDpi(8), EscalarDpi(28 + AFila * 36),
      EscalarDpi(179), EscalarDpi(32));
    oBoton.Caption := ATitulo;
    oBoton.Tag := Ord(AAccion);
    oBoton.OnClick := PulsarAccion;
    Result := oBoton;
  end;

  procedure Grupo(const ATitulo: string;
    const ATextos: array of string;
    const AAcciones: array of TAccionCircuitoOrden);
  var
    oGrupo: TcxGroupBox;
    oTitulo: TcxLabel;
    i: Integer;
  begin
    oGrupo := TcxGroupBox.Create(Self);
    oGrupo.Parent := oGrupos;
    oGrupo.Caption := '';
    oGrupo.Alignment := alCenterCenter;
    oGrupo.PanelStyle.Active := True;
    oGrupo.SetBounds(EscalarDpi(4 + iGrupo * 203), EscalarDpi(4),
      EscalarDpi(197), EscalarDpi(176));
    oTitulo := TcxLabel.Create(Self);
    oTitulo.Parent := oGrupo;
    oTitulo.Transparent := True;
    oTitulo.Caption := ATitulo;
    oTitulo.Style.TextStyle := [fsBold];
    oTitulo.SetBounds(EscalarDpi(8), EscalarDpi(4),
      EscalarDpi(181), EscalarDpi(22));
    for i := 0 to High(AAcciones) do
      Boton(oGrupo, ATextos[i], AAcciones[i], i);
    Inc(iGrupo);
  end;

begin
  FBotonera.Height := EscalarDpi(240);
  oCabecera := TcxGroupBox.Create(Self);
  oCabecera.Parent := FBotonera;
  oCabecera.Align := alTop;
  oCabecera.Height := EscalarDpi(36);
  oCabecera.PanelStyle.Active := True;
  Boton(oCabecera, SCircuitoRefrescar, acoRefrescar, 0).Top :=
    EscalarDpi(2);
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := oCabecera;
  oRotulo.Transparent := True;
  oRotulo.Caption := SCircuitoOrden;
  oRotulo.SetBounds(EscalarDpi(199), EscalarDpi(6),
    EscalarDpi(55), EscalarDpi(24));
  oOrden := TcxLabel.Create(Self);
  oOrden.Transparent := True;
  oOrden.Parent := oCabecera;
  oOrden.SetBounds(EscalarDpi(254), EscalarDpi(6),
    EscalarDpi(260), EscalarDpi(24));
  FEnlaceRotulo := TEnlaceRotuloOrden.Create(oOrden,
    FDatos.Circuito.Maestro);
  oGrupos := TScrollBox.Create(Self);
  oGrupos.Parent := FBotonera;
  oGrupos.Align := alClient;
  oGrupos.BorderStyle := bsNone;
  oGrupos.VertScrollBar.Visible := False;
  oGrupos.HorzScrollBar.Tracking := True;
  iGrupo := 0;
  Grupo(SCircuitoGrupoCondiciones,
    [SCircuitoAcuerdo, SCircuitoConcepto, SCircuitoCerrarEconomico],
    [acoAcuerdo, acoConcepto, acoEconomico]);
  Grupo(SCircuitoTiempos,
    [SCircuitoTiempo, SCircuitoPausar, SCircuitoCorregirTiempo],
    [acoTiempo, acoPausar, acoCorregirTiempo]);
  Grupo(SCircuitoGrupoTrabajo,
    [SCircuitoMaterial, SCircuitoImprimir, SCircuitoCerrar],
    [acoMaterial, acoHoja, acoCerrar]);
  Grupo(SCircuitoGrupoAlbaranes,
    [SCircuitoAlbaran, SCircuitoTodos, SCircuitoImputar, SCircuitoLiberar],
    [acoCrearAlbaran, acoTodos, acoImputar, acoLiberar]);
  Grupo(SCircuitoGrupoExternos,
    [SCircuitoEntrega, SCircuitoRetorno], [acoEntrega, acoRetorno]);
end;

procedure TPanelCircuitoOrden.CrearDetalle(const ATitulo: string;
  AOrigen: TDataSource; const ACampos, ATitulos: array of string);
var
  oPestana: TcxTabSheet;
  oPanel: TPanelDetalleCircuito;
begin
  oPestana := TcxTabSheet.Create(Self);
  oPestana.PageControl := FPestanas;
  oPestana.Caption := ATitulo;
  oPanel := TPanelDetalleCircuito.CreatePanel(Self, oPestana,
    FDatos, FEnlaces);
  oPanel.Configurar(AOrigen, ACampos, ATitulos);
end;

procedure TPanelCircuitoOrden.CrearDetalles;
begin
  FPestanas := TcxPageControl.Create(Self);
  FPestanas.Parent := Self;
  FPestanas.Align := alClient;
  CrearDetalle(SCircuitoTiempos, FDatos.Circuito.Tiempos,
    ['ID_RCT','ID_GARLIN_RCT','CODIGO_EMPL_RCT','TAREA_RCT',
     'INSTANTE_INICIO_RCT','INSTANTE_FIN_RCT','HORAS','ESANULADO_RCT',
     'MOTIVO_RCT'],
    [SCircuitoColNumero,SCircuitoColConcepto,SCircuitoOperario,
     SCircuitoTarea,SCircuitoInicio,
     SCircuitoFin,SCircuitoColHoras,SCircuitoColAnulada,SCircuitoMotivo]);
  CrearDetalle(SCircuitoMateriales, FDatos.Circuito.Materiales,
    ['ID_GARLIN_RCM','PROCEDENCIA_RCM','UNIDAD_RCM',
     'CANTIDAD_PREVISTA_RCM',
     'CANTIDAD_UTILIZADA_RCM','CANTIDAD_DEVUELTA_RCM','REFERENCIA_RCM'],
    [SCircuitoColConcepto,SCircuitoProcedencia,SCircuitoUnidad,
     SCircuitoPrevisto,SCircuitoUtilizado,
     SCircuitoDevuelto,SCircuitoOrigen]);
  CrearDetalle(SCircuitoHistorial, FDatos.Circuito.Historial,
    ['INSTANTE_ALTA','USUARIO_ALTA','ID_GARLIN_RCH','ACCION_RCH',
     'DETALLE_RCH'],[SCircuitoColFecha,SCircuitoColUsuario,
     SCircuitoColConcepto,SCircuitoColAccion,SCircuitoColDetalle]);
  CrearDetalle(SCircuitoDocumentos, FDatos.Circuito.Documentos,
    ['ID_RCI','ID_GARLIN_RCI','TIPO_RCI','SERIE_RCI','NUMERO_RCI',
     'LINEA_RCI','CODIGO_PROVEEDOR','NOMBRE_PROVEEDOR',
     'TOTAL_RCI','CANTIDAD_RCI'],
    [SCircuitoColNumero,SCircuitoColConcepto,SCircuitoTipoDoc,
     SCircuitoSerieDoc,SCircuitoNumeroDoc,
     SCircuitoLineaDoc,SCircuitoColCodigoProveedor,SCircuitoColProveedor,
     SCircuitoColImporteDoc,SCircuitoCantidadDoc]);
  CrearDetalle(SCircuitoExternos, FDatos.Circuito.Externos,
    ['ID_RCE','ID_GARLIN_RCE','CODIGO_PRV_RCE','OBJETO_RCE',
     'CANTIDAD_ENVIADA_RCE','CANTIDAD_RECIBIDA_RCE','INCIDENCIA_RCE'],
    [SCircuitoColNumero,SCircuitoColConcepto,SCircuitoEmpresaExterna,
     SCircuitoObjeto,
     SCircuitoEnviado,SCircuitoRecibido,SCircuitoIncidencia]);
  FPestanas.ActivePageIndex := 0;
end;

procedure TPanelCircuitoOrden.PulsarAccion(Sender: TObject);
begin
  Accion(
    procedure
    begin
      try
        Ejecutar(TAccionCircuitoOrden(TcxButton(Sender).Tag));
      except
        on E: EConvertError do
          raise EArgumentException.Create(SCircuitoFormato);
      end;
    end);
end;

procedure TPanelCircuitoOrden.Ejecutar(AAccion: TAccionCircuitoOrden);
begin
  if not FDatos.Circuito.Disponible then
    raise EArgumentException.Create(SCircuitoFaltaEsquema);
  if not (AAccion in [acoRefrescar, acoHoja]) and
     (not Assigned(FEnlaces.PuedeModificar) or
      not FEnlaces.PuedeModificar()) then
    raise EArgumentException.Create(SCircuitoConflicto);
  FEnlaces.GuardarOrden();
  FDatos.Circuito.Refrescar;
  if FEnlaces.ReparacionActual() <= 0 then
    raise EArgumentException.Create(SCircuitoSeleccionar);
  case AAccion of
    acoAcuerdo: EditarAcuerdo;
    acoConcepto: EditarConcepto;
    acoTiempo: EditarTiempo(False);
    acoCorregirTiempo: EditarTiempo(True);
    acoPausar: PausarTiempo;
    acoMaterial: EditarMaterial;
    acoCerrar: CerrarTecnico;
    acoCrearAlbaran: CrearAlbaran;
    acoTodos: CrearTodos;
    acoImputar: Imputar;
    acoLiberar: Liberar;
    acoEntrega: EntregaExterno(False);
    acoRetorno: EntregaExterno(True);
    acoEconomico: FDatos.Circuito.Cierre.Cerrar(FDatos.Circuito.Orden);
    acoHoja: FEnlaces.Imprimir(FDatos.HojaInterna(FDatos.Circuito.Orden,
      FEnlaces.AlmacenActual()));
  end;
  FDatos.Circuito.Refrescar;
  FEnlaces.Refrescar(0);
end;

function TPanelCircuitoOrden.Linea: Int64;
begin
  if FDatos.Circuito.Resumen.DataSet.IsEmpty then
    raise EArgumentException.Create(SCircuitoSeleccionar);
  Result := FDatos.Circuito.Resumen.DataSet.FieldByName('LINEA').AsLargeInt;
end;

procedure TPanelCircuitoOrden.EditarAcuerdo;
var
  rAcuerdo: TAcuerdoOrden;
  aValores: TArray<string>;
begin
  rAcuerdo := FDatos.Circuito.Cobertura.Acuerdo(FDatos.Circuito.Orden);
  aValores := [rAcuerdo.Referencia, rAcuerdo.Autorizacion,
    CurrToStr(rAcuerdo.PorcentajeManoObra),
    CurrToStr(rAcuerdo.PorcentajeMaterial),
    Opcional(rAcuerdo.Limite, rAcuerdo.TieneLimite),
    CurrToStr(rAcuerdo.Franquicia), SiNo(rAcuerdo.Autorizado),
    SiNo(rAcuerdo.ClienteAcepta)];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoAcuerdo,
    [SCircuitoReferencia, SCircuitoAutorizacion, SCircuitoPorcentajeMO,
     SCircuitoPorcentajeMAT, SCircuitoLimite, SCircuitoFranquicia,
     SCircuitoAutorizado, SCircuitoAceptado], aValores,
    [100, 200, 10, 10, 15, 15, 1, 1]) then
  begin
    rAcuerdo.Referencia := aValores[0];
    rAcuerdo.Autorizacion := aValores[1];
    rAcuerdo.PorcentajeManoObra := LeerImporte(aValores[2],
      SCircuitoPorcentajeMO);
    rAcuerdo.PorcentajeMaterial := LeerImporte(aValores[3],
      SCircuitoPorcentajeMAT);
    rAcuerdo.TieneLimite := aValores[4] <> '';
    rAcuerdo.Limite := MonedaOpcional(aValores[4],
      SCircuitoLimite);
    rAcuerdo.Franquicia := LeerImporte(aValores[5],
      SCircuitoFranquicia);
    rAcuerdo.Autorizado := LeerSiNo(aValores[6]);
    rAcuerdo.ClienteAcepta := LeerSiNo(aValores[7]);
    FDatos.Circuito.Cobertura.GuardarAcuerdo(FDatos.Circuito.Orden, rAcuerdo);
  end;
end;

procedure TPanelCircuitoOrden.EditarConcepto;
var
  rDetalle: TDetalleConceptoOrden;
  aValores: TArray<string>;
begin
  rDetalle := FDatos.Circuito.Cobertura.Concepto(FDatos.Circuito.Orden, Linea);
  aValores := [FloatToStr(rDetalle.HorasPrevistas),
    Opcional(rDetalle.HorasFacturables, rDetalle.PorHoras),
    SiNo(rDetalle.Concepto.CoberturaPropia),
    CurrToStr(rDetalle.Concepto.Porcentaje),
    Opcional(rDetalle.Concepto.Limite, rDetalle.Concepto.TieneLimite),
    CurrToStr(rDetalle.Concepto.Taller), SiNo(rDetalle.Concepto.ClienteAcepta)];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoConcepto,
    [SCircuitoHorasPrevistas, SCircuitoHorasFacturables, SCircuitoPropia,
     SCircuitoPorcentaje, SCircuitoLimite, SCircuitoTaller,
     SCircuitoAceptado], aValores, [10, 10, 1, 10, 15, 15, 1]) then
  begin
    rDetalle.HorasPrevistas := LeerCantidad(aValores[0],
      SCircuitoHorasPrevistas);
    rDetalle.PorHoras := aValores[1] <> '';
    rDetalle.HorasFacturables := NumeroOpcional(aValores[1],
      SCircuitoHorasFacturables);
    rDetalle.Concepto.CoberturaPropia := LeerSiNo(aValores[2]);
    rDetalle.Concepto.Porcentaje := LeerImporte(aValores[3],
      SCircuitoPorcentaje);
    rDetalle.Concepto.TieneLimite := aValores[4] <> '';
    rDetalle.Concepto.Limite := MonedaOpcional(aValores[4],
      SCircuitoLimite);
    rDetalle.Concepto.Taller := LeerImporte(aValores[5],
      SCircuitoTaller);
    rDetalle.Concepto.ClienteAcepta := LeerSiNo(aValores[6]);
    FDatos.Circuito.Cobertura.GuardarConcepto(FDatos.Circuito.Orden, rDetalle);
  end;
end;

procedure TPanelCircuitoOrden.EditarTiempo(ACorregir: Boolean);
var
  rParte: TParteTiempoOrden;
  aValores: TArray<string>;
  oDatos: TDataSet;
begin
  rParte := Default(TParteTiempoOrden);
  rParte.Linea := Linea;
  aValores := ['', '', DateTimeToStr(Now), '', ''];
  oDatos := FDatos.Circuito.Tiempos.DataSet;
  if ACorregir then
  begin
    if oDatos.IsEmpty or
       (oDatos.FieldByName('ESANULADO_RCT').AsString = 'S') then
      raise EArgumentException.Create(SCircuitoSeleccionarTiempo);
    rParte.Id := oDatos.FieldByName('ID_RCT').AsLargeInt;
    rParte.Linea := oDatos.FieldByName('ID_GARLIN_RCT').AsLargeInt;
    aValores[0] := oDatos.FieldByName('CODIGO_EMPL_RCT').AsString;
    aValores[1] := oDatos.FieldByName('TAREA_RCT').AsString;
    aValores[2] := oDatos.FieldByName('INSTANTE_INICIO_RCT').AsString;
    aValores[3] := oDatos.FieldByName('INSTANTE_FIN_RCT').AsString;
  end;
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoTiempo,
    [SCircuitoOperario, SCircuitoTarea, SCircuitoInicio, SCircuitoFin,
     SCircuitoMotivo], aValores, [20, 200, 19, 19, 500]) then
  begin
    rParte.Operario := aValores[0];
    rParte.Tarea := aValores[1];
    rParte.Inicio := LeerInstante(aValores[2],
      SCircuitoInicio);
    rParte.Fin := FechaOpcional(aValores[3],
      SCircuitoFin);
    rParte.Motivo := aValores[4];
    FDatos.Circuito.RegistroTiempos.Registrar(FDatos.Circuito.Orden, rParte);
  end;
end;

procedure TPanelCircuitoOrden.PausarTiempo;
var
  oDatos: TDataSet;
begin
  oDatos := FDatos.Circuito.Tiempos.DataSet;
  if oDatos.IsEmpty then
    raise EArgumentException.Create(SCircuitoSeleccionarTiempo);
  FDatos.Circuito.RegistroTiempos.Pausar(FDatos.Circuito.Orden,
    oDatos.FieldByName('ID_RCT').AsLargeInt);
end;

procedure TPanelCircuitoOrden.EditarMaterial;
var
  rMaterial: TMaterialOrden;
  aValores: TArray<string>;
begin
  rMaterial := FDatos.Circuito.RegistroMateriales.Material(
    FDatos.Circuito.Orden, Linea);
  aValores := [rMaterial.Procedencia, rMaterial.Unidad, rMaterial.Referencia,
    FloatToStr(rMaterial.Previsto), FloatToStr(rMaterial.Utilizado),
    FloatToStr(rMaterial.Devuelto)];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoMaterial,
    [SCircuitoProcedencia, SCircuitoUnidad, SCircuitoOrigen,
     SCircuitoPrevisto, SCircuitoUtilizado, SCircuitoDevuelto],
     aValores, [10, 20, 200, 15, 15, 15]) then
  begin
    rMaterial.Procedencia := UpperCase(aValores[0]);
    rMaterial.Unidad := aValores[1];
    rMaterial.Referencia := aValores[2];
    rMaterial.Previsto := LeerCantidad(aValores[3],
      SCircuitoPrevisto);
    rMaterial.Utilizado := LeerCantidad(aValores[4],
      SCircuitoUtilizado);
    rMaterial.Devuelto := LeerCantidad(aValores[5],
      SCircuitoDevuelto);
    FDatos.Circuito.RegistroMateriales.Guardar(FDatos.Circuito.Orden,
      rMaterial);
  end;
end;

procedure TPanelCircuitoOrden.CerrarTecnico;
var
  aValores: TArray<string>;
begin
  aValores := [''];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoCerrar,
    [SCircuitoMotivo], aValores, [500]) then
    FDatos.Circuito.Cobertura.CerrarTecnico(FDatos.Circuito.Orden,
      aValores[0]);
end;

procedure TPanelCircuitoOrden.CrearAlbaran;
var
  rSolicitud: TDocumentoOrdenNuevo;
  rCreado: TDocumentoOrdenCreado;
  aValores: TArray<string>;
begin
  rSolicitud := Default(TDocumentoOrdenNuevo);
  rSolicitud.Orden := FDatos.Circuito.Orden;
  rSolicitud.Linea := Linea;
  aValores := ['CL','','','',CurrToStr(
    FDatos.Circuito.Imputaciones.Pendiente(rSolicitud.Orden,
      rSolicitud.Linea, 'CL')), '1', '', DateToStr(Date), 'N'];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoAlbaran,
    [SCircuitoTipoDoc, SCircuitoSerieDoc, SCircuitoProveedor, SCircuitoAlmacen,
     SCircuitoImporteDoc, SCircuitoCantidadDoc, SCircuitoOrigen,
     SCircuitoFechaDoc, SCircuitoTipoIva], aValores,
    [2, 20, 20, 10, 15, 15, 50, 10, 1]) then
  begin
    rSolicitud.Tipo := UpperCase(aValores[0]);
    rSolicitud.Serie := aValores[1];
    rSolicitud.Proveedor := aValores[2];
    rSolicitud.Almacen := aValores[3];
    rSolicitud.Importe := LeerImporte(aValores[4],
      SCircuitoImporteDoc);
    rSolicitud.Cantidad := LeerCantidad(aValores[5],
      SCircuitoCantidadDoc);
    rSolicitud.Referencia := aValores[6];
    rSolicitud.Fecha := LeerFecha(aValores[7],
      SCircuitoFechaDoc);
    rSolicitud.TipoIva := aValores[8];
    rCreado := FDatos.Circuito.Generador.Crear(rSolicitud);
    FDatos.Albaranes.Refrescar;
    FEnlaces.AbrirAlbaran(rSolicitud.Tipo = 'PR', rCreado.Serie,
      rCreado.Numero);
  end;
end;

procedure TPanelCircuitoOrden.CrearTodos;
var
  rSolicitud: TDocumentoOrdenNuevo;
  rCreado: TDocumentoOrdenCreado;
  aValores: TArray<string>;
begin
  rSolicitud := Default(TDocumentoOrdenNuevo);
  rSolicitud.Orden := FDatos.Circuito.Orden;
  aValores := ['CL','','','',DateToStr(Date),'N'];
  if TfrmModalDatosOrden.Ejecutar(Self,SCircuitoTodos,
    [SCircuitoTipoVenta,SCircuitoSerieDoc,SCircuitoAlmacen,
     SCircuitoReferencia,SCircuitoFechaDoc,SCircuitoTipoIva],aValores,
    [2,20,10,50,10,1]) then
  begin
    rSolicitud.Tipo := UpperCase(aValores[0]);
    rSolicitud.Serie := aValores[1];
    rSolicitud.Almacen := aValores[2];
    rSolicitud.Referencia := aValores[3];
    rSolicitud.Fecha := LeerFecha(aValores[4],
      SCircuitoFechaDoc);
    rSolicitud.TipoIva := aValores[5];
    rCreado := FDatos.Circuito.Generador.CrearPendientes(rSolicitud);
    FDatos.Albaranes.Refrescar;
    FEnlaces.AbrirAlbaran(False,rCreado.Serie,rCreado.Numero);
  end;
end;

procedure TPanelCircuitoOrden.Imputar;
var
  rImputacion: TImputacionOrden;
  aValores: TArray<string>;
begin
  rImputacion := Default(TImputacionOrden);
  rImputacion.Orden := FDatos.Circuito.Orden;
  rImputacion.Linea := Linea;
  aValores := ['CL','','','','0','1'];
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoImputar,
    [SCircuitoTipoImputacion, SCircuitoSerieDoc, SCircuitoNumeroDoc,
     SCircuitoLineaDoc, SCircuitoImporteDoc, SCircuitoCantidadDoc],
     aValores, [2, 20, 20, 20, 15, 15]) then
  begin
    rImputacion.Tipo := UpperCase(aValores[0]);
    rImputacion.Serie := aValores[1];
    rImputacion.Numero := aValores[2];
    rImputacion.LineaDocumento := aValores[3];
    rImputacion.Importe := LeerImporte(aValores[4],
      SCircuitoImporteDoc);
    rImputacion.Cantidad := LeerCantidad(aValores[5],
      SCircuitoCantidadDoc);
    FDatos.Circuito.Imputaciones.Imputar(rImputacion);
    FDatos.Albaranes.Refrescar;
  end;
end;

procedure TPanelCircuitoOrden.Liberar;
var
  oDatos: TDataSet;
begin
  oDatos := FDatos.Circuito.Documentos.DataSet;
  if oDatos.IsEmpty then
    raise EArgumentException.Create(SCircuitoSeleccionar);
  FDatos.Circuito.Imputaciones.Liberar(FDatos.Circuito.Orden,
    oDatos.FieldByName('ID_RCI').AsLargeInt);
end;

procedure TPanelCircuitoOrden.EntregaExterno(ARetorno: Boolean);
var
  rEntrega: TEntregaExternoOrden;
  aValores: TArray<string>;
  oDatos: TDataSet;
begin
  rEntrega := Default(TEntregaExternoOrden);
  rEntrega.Orden := FDatos.Circuito.Orden;
  rEntrega.Linea := Linea;
  aValores := ['','','1','0',''];
  if ARetorno then
  begin
    oDatos := FDatos.Circuito.Externos.DataSet;
    if oDatos.IsEmpty then
      raise EArgumentException.Create(SCircuitoSeleccionar);
    rEntrega.Id := oDatos.FieldByName('ID_RCE').AsLargeInt;
    rEntrega.Linea := oDatos.FieldByName('ID_GARLIN_RCE').AsLargeInt;
    rEntrega.Revision := oDatos.FieldByName('REVISION_RCE').AsInteger;
    aValores[0] := oDatos.FieldByName('CODIGO_PRV_RCE').AsString;
    aValores[1] := oDatos.FieldByName('OBJETO_RCE').AsString;
    aValores[2] := oDatos.FieldByName('CANTIDAD_ENVIADA_RCE').AsString;
    aValores[3] := oDatos.FieldByName('CANTIDAD_RECIBIDA_RCE').AsString;
    aValores[4] := oDatos.FieldByName('INCIDENCIA_RCE').AsString;
  end;
  if TfrmModalDatosOrden.Ejecutar(Self, SCircuitoExternos,
    [SCircuitoEmpresaExterna, SCircuitoObjeto, SCircuitoEnviado,
     SCircuitoRecibido, SCircuitoIncidencia], aValores,
    [20, 200, 15, 15, 500]) then
  begin
    rEntrega.Proveedor := aValores[0];
    rEntrega.Objeto := aValores[1];
    rEntrega.Enviado := LeerCantidad(aValores[2],
      SCircuitoEnviado);
    rEntrega.Recibido := LeerCantidad(aValores[3],
      SCircuitoRecibido);
    rEntrega.Incidencia := aValores[4];
    FDatos.Circuito.Entregas.Registrar(rEntrega);
    if not ARetorno then
      FEnlaces.Imprimir(FDatos.HojaEntrega([rEntrega.Linea],
        FEnlaces.AlmacenActual()));
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Seleccion y avance de atributos del editor de lineas de caja.               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorAtributosVcl;

interface

uses
  System.Classes, System.Diagnostics, System.Types, Vcl.Controls,
  Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, cxControls, cxEdit, cxDropDownEdit,
  cxGraphics, cxGridDBTableView, Uni,
  UniDataCaja, inLibParametrosIntf, inLibArticulosAtributosIntf,
  inLibLogIntf, inLibAtributosPaletaIntf, inLibAtributosPaleta,
  inMtoCajaOpePresentacionVcl;

type
  TAccionSkuEditorCajaVcl = reference to procedure(const ASku: string);
  TConsultaSkuEditorCajaVcl = reference to function(
    const ASku: string): Boolean;
  TConsultaEnteroEditorCajaVcl = reference to function: Integer;
  TContextoAtributosEditorLineasCajaVcl = record
    Formulario: TCustomForm;
    DatosCaja: TdmCajaOpe;
    Conexion: TUniConnection;
    ParametrosCaja: IParametrosCaja;
    AtributosArticulos: IArticulosAtributosLookup;
    RegistroLog: IRegistroLog;
    VistaLineas: TcxGridDBTableView;
    ColumnaArticulo: TcxGridDBColumn;
    ColumnaDescripcion: TcxGridDBColumn;
    ObtenerNumeroAtributos: TConsultaEnteroEditorCajaVcl;
    RecalcularPrecio: TAccionSkuEditorCajaVcl;
    Consolidar: TConsultaSkuEditorCajaVcl;
    ValidarSku: TConsultaSkuEditorCajaVcl;
    ConsultarStock: TAccionSkuEditorCajaVcl;
    MensajeFinalizar: Cardinal;
    MensajeAvanzar: Cardinal;
    MensajeAbrirPopup: Cardinal;
    MensajeConfirmar: Cardinal;
  end;
  TSelectorAtributosEditorLineasCajaVcl = class
  private
    FContexto: TContextoAtributosEditorLineasCajaVcl;
    FCronometroPopup: TStopwatch;
    FProcesandoAtributo: Boolean;
    FConfirmacionPendiente: Boolean;
    FOrdenPendiente: Integer;
    FValorPendiente: string;
    FOpciones: array[1..5] of TArray<string>;
    // Cuadradito de color del editor en linea (boton-glifo).
    FGlifoSwatch: TGlifoSwatchCombo;
    function BuscarValorValido(AOrden: Integer;
      const AValor: string; out AValorCanonico: string): Boolean;
    function ObtenerOrdenEditor(AControl: TcxControl): Integer;
    function ObtenerIdVaEditor(AControl: TcxControl): string;
    function EsEditorEnLinea(AControl: TcxControl): Boolean;
    function ObtenerInfoColorOpcion(AControl: TcxControl;
      const ATexto: string; out AInfo: TInfoBasico): Boolean;
    function ObtenerColorEditor(AEditor: TcxComboBox;
      const ATexto: string; out AInfo: TInfoBasico): Boolean;
    procedure ProgramarConfirmacion(AOrden: Integer;
      const AValor: string);
    procedure RegistrarValor(AOrden: Integer;
      const AValorNuevo: string);
    procedure FinalizarUltimoAtributo;
    function MedirTextoMasAncho(AColumna: TcxGridDBColumn;
      AFuente: TFont): Integer;
  public
    constructor Create(
      const AContexto: TContextoAtributosEditorLineasCajaVcl);
    destructor Destroy; override;
    procedure IniciarMedicionPopup;
    procedure CargarOpciones(AOrden: Integer;
      const AArticulo: string;
      APropiedades: TcxComboBoxProperties);
    procedure DibujarOpcion(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
    procedure ConfigurarBotonSwatch(APropiedades: TcxComboBoxProperties);
    procedure AjustarBotonSwatch(APropiedades: TcxComboBoxProperties;
      const ANombreAtributo: string);
    procedure AjustarAnchoColumna(AColumna: TcxGridDBColumn);
    procedure PrepararSwatchEditor(AEditor: TcxCustomEdit;
      const AValor: string);
    procedure ActualizarSwatchEditor(Sender: TObject);
    procedure CerrarPopup(AControl: TcxControl;
      AReason: TcxEditCloseUpReason);
    procedure AbrirPopupEnEntrada(Sender: TObject);
    procedure AbrirPopupAtributo;
    procedure SeleccionarAtributo(Sender: TObject;
      AButtonIndex: Integer);
    procedure ConfirmarAtributoPendiente;
    procedure FinalizarAtributos;
    procedure AvanzarAtributo(ANumeroColumna: Integer);
  end;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows, System.SysUtils, System.Math, System.Variants,
  System.Generics.Collections, Data.DB, Vcl.Dialogs,
  cxGridTableView, cxGrid, cxCustomData, cxGeometry, dxCoreGraphics,
  dxDPIAwareUtils,
  inLibCajaVentaOperacion, inLibCajaOpePresentacion,
  inLibCajaOpePresentacionIntf, inLibSelectorAtributoLinea;

constructor TSelectorAtributosEditorLineasCajaVcl.Create(
  const AContexto: TContextoAtributosEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
  // Al pulsar el cuadradito se abre la lista como con la flecha.
  FGlifoSwatch := TGlifoSwatchCombo.Create(
    ObtenerColorEditor, SeleccionarAtributo);
end;

destructor TSelectorAtributosEditorLineasCajaVcl.Destroy;
begin
  FreeAndNil(FGlifoSwatch);
  inherited;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.IniciarMedicionPopup;
begin
  FCronometroPopup := TStopwatch.StartNew;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.CargarOpciones(
  AOrden: Integer; const AArticulo: string;
  APropiedades: TcxComboBoxProperties);
var
  I: Integer;
begin
  if (AOrden >= Low(FOpciones)) and
     (AOrden <= High(FOpciones)) and
     (APropiedades <> nil) then
  begin
    CargarAvsValidosArticulo(
      AArticulo,
      AOrden,
      FContexto.AtributosArticulos,
      FOpciones[AOrden]);
    APropiedades.Items.BeginUpdate;
    try
      APropiedades.Items.Clear;
      for I := 0 to High(FOpciones[AOrden]) do
        APropiedades.Items.Add(FOpciones[AOrden][I]);
    finally
      APropiedades.Items.EndUpdate;
    end;
  end;
end;

function TSelectorAtributosEditorLineasCajaVcl.BuscarValorValido(
  AOrden: Integer; const AValor: string;
  out AValorCanonico: string): Boolean;
var
  I: Integer;
  ValorBuscado: string;
begin
  Result := False;
  AValorCanonico := '';
  ValorBuscado := Trim(AValor);
  I := 0;
  if (AOrden >= Low(FOpciones)) and
     (AOrden <= High(FOpciones)) then
  begin
    while (I <= High(FOpciones[AOrden])) and not Result do
    begin
      Result := SameText(
        Trim(FOpciones[AOrden][I]),
        ValorBuscado);
      if Result then
        AValorCanonico := FOpciones[AOrden][I]
      else
        Inc(I);
    end;
  end;
end;

function TSelectorAtributosEditorLineasCajaVcl.ObtenerOrdenEditor(
  AControl: TcxControl): Integer;
var
  Columna: TcxGridColumn;
begin
  Result := 0;
  if AControl <> nil then
    Result := AControl.Tag;
  if (Result < Low(FOpciones)) or
     (Result > High(FOpciones)) then
  begin
    Columna := FContexto.VistaLineas.Controller.FocusedColumn;
    if Columna <> nil then
      Result := Columna.Tag;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.ProgramarConfirmacion(
  AOrden: Integer; const AValor: string);
begin
  if not FConfirmacionPendiente then
  begin
    FOrdenPendiente := AOrden;
    FValorPendiente := AValor;
    FConfirmacionPendiente := True;
    PostMessage(
      FContexto.Formulario.Handle,
      FContexto.MensajeConfirmar,
      0,
      0);
  end;
end;

function TSelectorAtributosEditorLineasCajaVcl.EsEditorEnLinea(
  AControl: TcxControl): Boolean;
begin
  Result := (AControl <> nil) and
    (FContexto.VistaLineas.Controller.EditingController.Edit =
     AControl);
end;

// ID_VA (CO, TAL...) del atributo que edita AControl: por el nombre del
// atributo de la linea en curso o, si aun no esta, por el caption de la
// columna enfocada.
function TSelectorAtributosEditorLineasCajaVcl.ObtenerIdVaEditor(
  AControl: TcxControl): string;
var
  Columna: TcxGridColumn;
  NombreAtributo: string;
  Orden: Integer;
begin
  Orden := ObtenerOrdenEditor(AControl);
  NombreAtributo := '';
  if (Orden >= Low(FOpciones)) and
     (Orden <= High(FOpciones)) and
     FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
    NombreAtributo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;
  if Trim(NombreAtributo) = '' then
  begin
    Columna := FContexto.VistaLineas.Controller.FocusedColumn;
    if (Columna <> nil) and (Columna.Tag = Orden) then
      NombreAtributo := Columna.Caption;
  end;
  Result := IdVaDeNombreAtributo(FContexto.Conexion, NombreAtributo);
end;

function TSelectorAtributosEditorLineasCajaVcl.ObtenerInfoColorOpcion(
  AControl: TcxControl; const ATexto: string;
  out AInfo: TInfoBasico): Boolean;
var
  Articulo: string;
  IdValorAtributo: string;
begin
  AInfo := Default(TInfoBasico);
  Articulo := '';
  if FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
    Articulo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
  IdValorAtributo := ObtenerIdVaEditor(AControl);
  // Igual que la celda (PintarCeldaSwatchAtributoSiAplica): primero la
  // asignacion del articulo y, si no la hay, la paleta global del
  // atributo. Sin este segundo paso los basicos usados tal cual (CAMEL,
  // NEGRO...) salian sin cuadradito en la lista.
  Result := (Trim(IdValorAtributo) <> '') and (Trim(ATexto) <> '') and
    (ObtenerInfoBasicoArticulo(
       FContexto.Conexion,
       Articulo,
       IdValorAtributo,
       ATexto,
       AInfo) or
     ObtenerInfoBasico(
       FContexto.Conexion,
       IdValorAtributo,
       ATexto,
       AInfo));
end;

procedure TSelectorAtributosEditorLineasCajaVcl.DibujarOpcion(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas;
  AIndex: Integer; const ARect: TRect; AState: TOwnerDrawState);
var
  HayColor: Boolean;
  Info: TInfoBasico;
  Texto: string;
begin
  // Con lsEditFixedList este evento solo pinta la lista desplegable; el
  // cuadradito del editor lo pone su boton-glifo (TGlifoSwatchCombo).
  // Si algun dia se pasa a lsFixedList, DevExpress lo usaria tambien
  // para la caja de texto y, via TcxInplaceComboBoxCustomDrawHelper,
  // para las celdas sin editar: por eso solo se busca color para el
  // editor en linea (las celdas las resuelve OnCustomDrawCell con su
  // fila).
  if (AControl <> nil) and (ACanvas <> nil) and
     (AIndex >= 0) and
     (AIndex < AControl.ActiveProperties.Items.Count) then
  begin
    Texto := AControl.ActiveProperties.Items[AIndex];
    Info := Default(TInfoBasico);
    HayColor := EsEditorEnLinea(AControl) and
      ObtenerInfoColorOpcion(AControl, Texto, Info);
    PintarOpcionComboConSwatch(
      ACanvas, ARect, AState, Texto, HayColor, Info);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.ConfigurarBotonSwatch(
  APropiedades: TcxComboBoxProperties);
begin
  // Boton-glifo con el cuadradito a la izquierda del texto; el editor
  // sigue siendo de texto con autocompletado. Nace oculto y
  // AjustarBotonSwatch lo muestra solo en el atributo con paleta.
  FGlifoSwatch.ConfigurarBoton(APropiedades);
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AjustarBotonSwatch(
  APropiedades: TcxComboBoxProperties; const ANombreAtributo: string);
begin
  // Se decide sobre las propiedades de la columna al montar los
  // atributos del articulo, nunca sobre el editor activo.
  FGlifoSwatch.MostrarBoton(
    APropiedades,
    EsAtributoConPaleta(FContexto.Conexion, ANombreAtributo));
end;

function TSelectorAtributosEditorLineasCajaVcl.MedirTextoMasAncho(
  AColumna: TcxGridDBColumn; AFuente: TFont): Integer;
var
  I: Integer;
  Propiedades: TcxComboBoxProperties;
  Datos: TcxCustomDataController;
begin
  // Opciones del articulo en curso y valores ya puestos en las lineas
  // (pueden ser de otro articulo del mismo ticket).
  Result := 0;
  if AColumna.Properties is TcxComboBoxProperties then
  begin
    Propiedades := TcxComboBoxProperties(AColumna.Properties);
    for I := 0 to Propiedades.Items.Count - 1 do
      Result := Max(Result,
        cxTextWidth(AFuente, Propiedades.Items[I]));
  end;
  Datos := AColumna.GridView.DataController;
  for I := 0 to Datos.RecordCount - 1 do
    Result := Max(Result, cxTextWidth(AFuente,
      VarToStr(Datos.Values[I, AColumna.Index])));
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AjustarAnchoColumna(
  AColumna: TcxGridDBColumn);
const
  // A 96 ppp. Con paleta, el editor lleva el boton-glifo (22) a la
  // izquierda y la flecha del desplegable a la derecha: pide mas que la
  // celda (margen 4 + cuadradito 16 + hueco 4). Sin paleta, solo flecha.
  RESERVA_CON_PALETA = 50;
  RESERVA_SIN_PALETA = 28;
  RESERVA_CABECERA = 16;
  ANCHO_MINIMO = 80;
  // Un nombre muy largo no debe comerse la Descripcion: sale con "...".
  ANCHO_MAXIMO = 220;
var
  Fuente: TFont;
  Escala: TdxScaleFactor;
  iReserva: Integer;
  iAncho: Integer;
begin
  // La rejilla reparte el ancho en proporcion (ColumnAutoWidth): con los
  // 80 px fijos de la columna "NEGRO" y su cuadradito no cabian. MinWidth
  // lo respeta el reparto y, si hace falta, sube Width (nunca la baja:
  // no deshace lo que el cajero haya ensanchado a mano).
  if (AColumna <> nil) and AColumna.Visible and
     (FContexto.VistaLineas.Control is TcxGrid) then
  begin
    Fuente := TcxGrid(FContexto.VistaLineas.Control).Font;
    Escala := dxGetScaleFactor(FContexto.VistaLineas);
    if EsAtributoConPaleta(FContexto.Conexion, AColumna.Caption) then
      iReserva := RESERVA_CON_PALETA
    else
      iReserva := RESERVA_SIN_PALETA;
    iAncho := Max(
      MedirTextoMasAncho(AColumna, Fuente) + Escala.Apply(iReserva),
      cxTextWidth(Fuente, AColumna.Caption) +
        Escala.Apply(RESERVA_CABECERA));
    iAncho := EnsureRange(iAncho,
      Escala.Apply(ANCHO_MINIMO), Escala.Apply(ANCHO_MAXIMO));
    AColumna.MinWidth := iAncho;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.PrepararSwatchEditor(
  AEditor: TcxCustomEdit; const AValor: string);
begin
  // OnInitEdit: color del valor actual de la celda.
  FGlifoSwatch.PrepararEditor(AEditor, AValor);
end;

procedure TSelectorAtributosEditorLineasCajaVcl.ActualizarSwatchEditor(
  Sender: TObject);
begin
  FGlifoSwatch.ActualizarEditor(Sender);
end;

function TSelectorAtributosEditorLineasCajaVcl.ObtenerColorEditor(
  AEditor: TcxComboBox; const ATexto: string;
  out AInfo: TInfoBasico): Boolean;
begin
  Result := ObtenerInfoColorOpcion(AEditor, ATexto, AInfo);
end;

procedure TSelectorAtributosEditorLineasCajaVcl.CerrarPopup(
  AControl: TcxControl; AReason: TcxEditCloseUpReason);
var
  Confirmar: Boolean;
  Orden: Integer;
  ValorActual: string;
  ValorCanonico: string;
begin
  if (AControl is TcxCustomComboBox) and
     (AReason in [crClose, crEnter]) then
  begin
    Orden := ObtenerOrdenEditor(AControl);
    if BuscarValorValido(
         Orden,
         TcxCustomComboBox(AControl).Text,
         ValorCanonico) then
    begin
      Confirmar := AReason = crEnter;
      if (AReason = crClose) and
         FContexto.DatosCaja.cdsLineas.Active and
         not FContexto.DatosCaja.cdsLineas.IsEmpty then
      begin
        ValorActual := FContexto.DatosCaja.cdsLineas.FieldByName(
          'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
        Confirmar := not SameText(
          Trim(ValorActual),
          Trim(ValorCanonico));
      end;
      if Confirmar then
        ProgramarConfirmacion(Orden, ValorCanonico);
    end;
  end;
  // El texto ya refleja la opcion elegida en la lista.
  ActualizarSwatchEditor(AControl);
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AbrirPopupEnEntrada(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  if Sender is TcxCustomEdit then
  begin
    Editor := TcxCustomEdit(Sender);
    Editor.OnEnter := nil;
    PostMessage(
      FContexto.Formulario.Handle,
      FContexto.MensajeAbrirPopup,
      0,
      0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AbrirPopupAtributo;
var
  Editor: TcxCustomEdit;
begin
  if FCronometroPopup.IsRunning then
    FCronometroPopup.Stop;
  if FContexto.VistaLineas.Controller.EditingController.IsEditing then
  begin
    Editor := FContexto.VistaLineas.Controller.EditingController.Edit;
    if (Editor is TcxComboBox) and
       (Editor.Tag >= 1) and (Editor.Tag <= 5) then
      SeleccionarAtributo(Editor, 0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.RegistrarValor(
  AOrden: Integer; const AValorNuevo: string);
var
  SkuNuevo: string;
  NumAtributosRequeridos: Integer;
begin
  if (AOrden >= 1) and (AOrden <= 5) and
     FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
  begin
    if FContexto.DatosCaja.cdsLineas.State = dsBrowse then
      FContexto.DatosCaja.cdsLineas.Edit;
    if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'ATTR' + IntToStr(AOrden) + '_VALOR').AsString := AValorNuevo;
      SkuNuevo := FContexto.DatosCaja.GenerarSkuFinal(
        FContexto.DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString);
      if Trim(SkuNuevo) = '' then
        SkuNuevo := FContexto.DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString;
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString := SkuNuevo;
      NumAtributosRequeridos :=
        FContexto.DatosCaja.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
      if SkuLineaCajaAdmitePrecio(
           SkuNuevo,
           NumAtributosRequeridos) then
        FContexto.RecalcularPrecio(SkuNuevo);
    end;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.FinalizarUltimoAtributo;
var
  SkuNuevo: string;
  EstabaInsertando: Boolean;
  Continuar: Boolean;
begin
  if not FProcesandoAtributo and
     FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
  begin
    if FContexto.VistaLineas.Controller.
       EditingController.IsEditing then
      FContexto.VistaLineas.Controller.
        EditingController.HideEdit(False);
    Continuar := True;
    FProcesandoAtributo := True;
    FContexto.DatosCaja.cdsLineas.DisableControls;
    try
      EstabaInsertando :=
        FContexto.DatosCaja.cdsLineas.State = dsInsert;
      SkuNuevo := FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString;
      if EstabaInsertando and FContexto.Consolidar(SkuNuevo) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          FContexto.DatosCaja.cdsLineas.Cancel;
        if not FContexto.DatosCaja.cdsLineas.IsEmpty and
           (FContexto.DatosCaja.cdsLineas.FieldByName(
             'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
          FContexto.DatosCaja.cdsLineas.Delete;
        FContexto.DatosCaja.cdsLineas.EnableControls;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
        FContexto.VistaLineas.Controller.
          EditingController.ShowEdit;
        Continuar := False;
      end;
      if Continuar and not FContexto.ValidarSku(SkuNuevo) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          FContexto.DatosCaja.cdsLineas.Cancel;
        if not FContexto.DatosCaja.cdsLineas.IsEmpty and
           (FContexto.DatosCaja.cdsLineas.FieldByName(
             'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
          FContexto.DatosCaja.cdsLineas.Delete;
        FContexto.DatosCaja.cdsLineas.EnableControls;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
        FContexto.VistaLineas.Controller.
          EditingController.ShowEdit;
        Continuar := False;
      end;
      if Continuar then
        FContexto.ConsultarStock(SkuNuevo);
    finally
      FProcesandoAtributo := False;
      FContexto.DatosCaja.cdsLineas.EnableControls;
    end;
    if Continuar then
    begin
      if FContexto.ParametrosCaja.GetBool(
           'vgerMoverLineaIdentif', True) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
          FContexto.DatosCaja.cdsLineas.Post;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
      end
      else
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaDescripcion;
      FContexto.VistaLineas.Controller.EditingController.ShowEdit;
    end;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.SeleccionarAtributo(
  Sender: TObject; AButtonIndex: Integer);
var
  Columna: TcxGridColumn;
  Combo: TcxComboBox;
  Orden: Integer;
  Articulo: string;
  Propiedades: TcxComboBoxProperties;
  Continuar: Boolean;
  Acceso: TAccesoSelectorAtributo;
begin
  Columna := FContexto.VistaLineas.Controller.FocusedColumn;
  Combo := nil;
  Continuar := (Columna <> nil) and (Sender is TcxComboBox);
  Orden := 0;
  if Continuar then
  begin
    Orden := Columna.Tag;
    Combo := TcxComboBox(Sender);
  end;
  Continuar := Continuar and (Orden >= 1) and (Orden <= 5) and
    FContexto.DatosCaja.cdsLineas.Active and
    not FContexto.DatosCaja.cdsLineas.IsEmpty;
  if Continuar then
  begin
    Articulo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    Propiedades := nil;
    if Columna.Properties is TcxComboBoxProperties then
      Propiedades := TcxComboBoxProperties(Columna.Properties);
    if Length(FOpciones[Orden]) = 0 then
      CargarOpciones(Orden, Articulo, Propiedades);
    // FZ-ISSUE-260: sin valores solo se avisa si el articulo lleva ese
    // atributo; en una linea sin atributos el desplegable no se abre.
    Acceso := AccesoSelectorAtributo(
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger,
      Orden, Length(FOpciones[Orden]));
    Continuar := Acceso = asaAbrir;
    if AvisarAtributoSinValores(Acceso) then
      ShowMessage_fza(MensajeAtributoSinValores(Articulo,
        FContexto.DatosCaja.cdsLineas.FieldByName(
          'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString));
  end;
  if Continuar then
    Combo.DroppedDown := True;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.
  ConfirmarAtributoPendiente;
var
  Orden: Integer;
  Valor: string;
begin
  if FConfirmacionPendiente then
  begin
    Orden := FOrdenPendiente;
    Valor := FValorPendiente;
    FConfirmacionPendiente := False;
    FOrdenPendiente := 0;
    FValorPendiente := '';
    RegistrarValor(Orden, Valor);
    if FContexto.VistaLineas.Controller.
       EditingController.IsEditing then
      FContexto.VistaLineas.Controller.
        EditingController.HideEdit(False);
    if PasoTrasAtributoLineaCaja(
         Orden,
         FContexto.ObtenerNumeroAtributos()) = palFinalizar then
      PostMessage(
        FContexto.Formulario.Handle,
        FContexto.MensajeFinalizar,
        0,
        0)
    else
      PostMessage(
        FContexto.Formulario.Handle,
        FContexto.MensajeAvanzar,
        Orden + 1,
        0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.FinalizarAtributos;
var
  SkuCompleto: Boolean;
  Pendiente: Integer;
begin
  Pendiente := PrimerAtributoPendienteLineaCaja(
    FContexto.DatosCaja.cdsLineas);
  SkuCompleto := False;
  if FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
    SkuCompleto := SkuLineaCajaCompleto(
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString,
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString,
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger);
  if Pendiente > 0 then
    AvanzarAtributo(Pendiente)
  else if SkuCompleto then
    FinalizarUltimoAtributo;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AvanzarAtributo(
  ANumeroColumna: Integer);
var
  Columna: TcxGridColumn;
  I: Integer;
begin
  Columna := nil;
  for I := 0 to FContexto.VistaLineas.ColumnCount - 1 do
  begin
    if (Columna = nil) and
       (FContexto.VistaLineas.Columns[I].Tag = ANumeroColumna) then
      Columna := FContexto.VistaLineas.Columns[I];
  end;
  if (Columna <> nil) and Columna.Visible then
  begin
    FContexto.VistaLineas.Controller.FocusedColumn := Columna;
    FContexto.VistaLineas.Controller.EditingController.ShowEdit;
  end;
end;

end.

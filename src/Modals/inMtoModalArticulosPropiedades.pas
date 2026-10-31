{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArticulosPropiedades                                }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión dinámica de propiedades de artículo.                              }
{    Inyecta controles en la pestaña de propiedades y persiste sus valores.    }
{******************************************************************************}
unit inMtoModalArticulosPropiedades;

{
  Unidad: inLibArticuloPropiedades
  Descripción: Gestión dinámica de propiedades en la pestaña tsPropiedades
               del formulario TfrmMtoArticulos de ViraCash.

  Flujo de uso:
    1. Crear TGestorPropiedades en FormShow / CrearTablaPrincipal
    2. Llamar a CargarPropiedades cuando cambia el artículo activo
       (AfterScroll del dataset principal)
    3. Llamar a GuardarPropiedades dentro de btnGrabarClick
    4. Llamar a AbrirSelectorPropiedades desde el botón "+ Añadir propiedad"

  El gestor inyecta controles en un TcxScrollBox que debe existir en
  tsPropiedades.
  El botón de añadir y el scroll se crean dinámicamente si no existen.
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs, inMtoModalAceptCancel, Messages,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxSpinEdit, cxMaskEdit,
  cxCheckBox, cxCheckListBox, cxLabel, cxDropDownEdit, cxButtons,
  cxPC, cxLookAndFeels, cxLookAndFeelPainters, cxScrollBox,
  System.UITypes, inLibArticulosPropiedadesPersistenciaIntf;

type
  TTipoValorProp = (tvpLista, tvpTextoLibre, tvpNumero, tvpBooleano);

  TSlotProp = record
    CodigoPropiedad : string;
    NombrePropiedad : string;
    TipoValor       : TTipoValorProp;
    Nivel           : string;
    EsRequerido     : Boolean;
    IdValorPV       : Integer;
    ValorLibre      : string;
    Ctrl            : TControl;
    Opciones        : TDictionary<Integer, string>;
    Eliminar        : Boolean;
    OriginalIdValorPV : Integer;
    OriginalValorLibre: string;
  end;

  TfrmSelPropiedades = class(TFrmModalAceptCancel)
  private
    FLectura        : ILectorPropiedadesArticulo;
    FExcluirCodigos : TStringList;
    FLista          : TcxCheckListBox;
    procedure AjustarColumnaTipo(AAnchoNombres, AAnchoTipos: Integer;
      AMedidor: TCanvas);
    procedure BtnAceptarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    CodigosSeleccionados : TStringList;
    constructor Create(
      AOwner: TComponent;
      const ALectura: ILectorPropiedadesArticulo;
      AExcluir: TStringList); reintroduce;
    destructor Destroy; override;
    procedure CargarLista;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

  TGestorPropiedades = class
  private
    FServicios      : TServiciosPropiedadesArticulo;
    FScrollBox      : TcxScrollBox;
    FCodigoArticulo : string;
    FUsuario        : string;
    FSlots          : TList<TSlotProp>;
    FModificado     : Boolean;
    FCargando       : Boolean;
    FAnchoLabel     : Integer;

    function  TipoDesdeCadena(const ATipo: string): TTipoValorProp;
    function  AnchoColumnaRotulos: Integer;
    procedure LimpiarControles;
    procedure ReconstruirVista;
    procedure CrearFilaLista      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaTexto      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaNumero     (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaBooleano   (var S: TSlotProp; ATop: Integer);
    procedure CrearBtnEliminar    (ASlotIdx: Integer; ATop: Integer);
    procedure BtnEliminarClick(Sender: TObject);
    procedure UpsertSlot(const S: TSlotProp);
    procedure DeleteSlot(const CodigoPropiedad: string);
    function IndexOfCodigo(const ACod: string): Integer;
    procedure CrearBtnPorUnidad(ASlotIdx, ATop: Integer);
    procedure BtnPorUnidadClick(Sender: TObject);
    procedure AbrirEditorPorUnidad(const S: TSlotProp);
  public
    constructor Create(
      AScrollBox: TcxScrollBox;
      const AServicios: TServiciosPropiedadesArticulo;
      const AUsuario: string);
    destructor Destroy; override;
    procedure CargarPropiedades(const ACodigoArticulo: string);
    procedure CargarPropiedadesPorFamilia(const ACodigoFamilia: string);
    // En un alta el gestor se carga sin código; al grabar la ficha recibe
    // el definitivo sin recargar, para no perder lo que hay en pantalla.
    procedure AsignarCodigoArticulo(const ACodigoArticulo: string);
    procedure AbrirSelectorPropiedades;
    function GuardarPropiedades(AValidar: Boolean = True): Boolean;
    function Validar: string;
    property Modificado: Boolean read FModificado;
  end;

  TFilaUnidadProp = record
    Unidad : string;
    Nombre : string;
    Ctrl   : TControl;
  end;

  TValUnidadProp = record
    IdValor    : Integer;
    ValorLibre : string;
  end;

  // Modal "propiedad por color/SKU": lista las unidades (colores o SKUs) del
  // articulo y fija el valor de UNA propiedad a ese nivel. Persiste directo en
  // fza_articulos_propiedades con CODIGO_UNIDAD_ARTPROP (mismo mecanismo que
  // tarifas/fotos). Construido en codigo, sin .dfm propio.
  TfrmPropPorUnidad = class(TFrmModalAceptCancel)
  private
    FServicios  : TServiciosPropiedadesArticulo;
    FUsuario    : string;
    FArticulo   : string;
    FCodigoProp : string;
    FNombreProp : string;
    FTipoValor  : TTipoValorProp;
    FNivel      : string;
    FScroll     : TcxScrollBox;
    FFilas      : TList<TFilaUnidadProp>;
    FOpciones   : TList<TPair<Integer, string>>;
    FActuales   : TDictionary<string, TValUnidadProp>;
    procedure CargarOpciones;
    procedure CargarUnidades;
    procedure CargarValoresActuales;
    procedure ConstruirFilas;
    procedure CrearControlFila(var F: TFilaUnidadProp; ATop, AIdValor: Integer;
                               const AValorLibre: string);
    procedure UpsertUnidad(const AUnidad: string; AIdValor: Integer;
                           const AValorLibre: string);
    procedure DeleteUnidad(const AUnidad: string);
    procedure BtnAceptarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    constructor Create(
      AOwner: TComponent;
      const AServicios: TServiciosPropiedadesArticulo;
      const AUsuario, AArticulo, ACodigoProp, ANombreProp: string;
      ATipoValor: TTipoValorProp;
      const ANivel: string); reintroduce;
    destructor Destroy; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

implementation

uses
  System.Math, System.Variants, inLibMensajesVcl,
  uGenericIfThen, inLibMsgArticulos;

type
  TControlFuentePropiedades = class(TControl);

// Número tecleado en una propiedad NUMERO, con coma o punto decimal.
// False si está vacío o no es un número: en una obligatoria no vale.
function LeerNumeroPropiedad(const ATexto: string;
  out AValor: string): Boolean;
var
  sTexto: string;
  dValor: Double;
  oFormato: TFormatSettings;
begin
  AValor := '';
  sTexto := StringReplace(Trim(ATexto), ',', '.', [rfReplaceAll]);
  oFormato := TFormatSettings.Invariant;
  Result := (sTexto <> '') and TryStrToFloat(sTexto, dValor, oFormato);
  if Result then
    AValor := FloatToStr(dValor);
end;

resourcestring
  STituloPropiedadPorSku = '%s por SKU';
  STituloPropiedadPorColor = '%s por color';

const
  ALTO_FILA      = 26;
  MARGEN_V       = 6;
  MARGEN_H       = 8;
  ANCHO_LABEL    = 180;
  // La columna de rótulos crece con la propiedad más larga hasta aquí.
  ANCHO_LABEL_MAX = 360;
  ANCHO_CTRL     = 260;
  ANCHO_BTN_DEL  = 24;
  COLOR_REQUERIDO = clMaroon;
  // Medidas de los modales a 96 ppp: su DFM heredado ya viene escalado al
  // PPI del monitor, así que se aplican con ScaleValue.
  ANCHO_BOTON_MODAL       = 140;
  ALTO_BOTONERA_MODAL     = 50;
  MARGEN_BOTONERA         = 9;
  MARGEN_DERECHO_BOTONERA = 12;
  SEPARACION_BOTONES      = 8;
  MARGEN_LISTA            = 10;
  ALTO_SELECTOR           = 360;
  ANCHO_MIN_SELECTOR      = 380;
  ANCHO_MAX_SELECTOR      = 640;
  ANCHO_MAX_NOMBRES       = 400;
  // Casilla, bordes y barra de desplazamiento de la lista.
  RESERVA_ANCHO_LISTA     = 90;
  // Hueco mínimo entre nombre y tipo, en anchos medios de carácter.
  SEPARACION_TIPO         = 3;

// La botonera del DFM base (botones de 177x40) está pensada para modales
// anchos: aquí se agrupa a la derecha con botones más compactos.
procedure CompactarBotonera(AForm: TfrmModalAceptCancel);

  procedure Colocar(ABoton: TcxButton; AMargenDerecho: Integer);
  begin
    ABoton.Width := AForm.ScaleValue(ANCHO_BOTON_MODAL);
    ABoton.AlignWithMargins := True;
    ABoton.Margins.SetBounds(
      0,
      AForm.ScaleValue(MARGEN_BOTONERA),
      AForm.ScaleValue(AMargenDerecho),
      AForm.ScaleValue(MARGEN_BOTONERA));
    ABoton.Align := alRight;
  end;

begin
  AForm.pnlButton.Height := AForm.ScaleValue(ALTO_BOTONERA_MODAL);
  Colocar(AForm.btnAceptar, MARGEN_DERECHO_BOTONERA);
  Colocar(AForm.btnCancelar, SEPARACION_BOTONES);
end;

function TextoTipoValor(const ATipo: string): string;
begin
  if ATipo = 'LISTA' then
    Result := SCaptionTipoValorLista
  else if ATipo = 'TEXTO_LIBRE' then
    Result := SCaptionTipoValorTextoLibre
  else if ATipo = 'NUMERO' then
    Result := SCaptionTipoValorNumero
  else if ATipo = 'BOOLEANO' then
    Result := SCaptionTipoValorBooleano
  else
    Result := ATipo;
end;

constructor TfrmSelPropiedades.Create(
  AOwner: TComponent;
  const ALectura: ILectorPropiedadesArticulo;
  AExcluir: TStringList);
begin
  inherited Create(AOwner);
  FLectura        := ALectura;
  FExcluirCodigos := AExcluir;
  CodigosSeleccionados := TStringList.Create;
  Position   := poOwnerFormCenter;
  BorderStyle:= bsDialog;
  Font.name := 'Source Sans 3';
  FLista := TcxCheckListBox.Create(Self);
  FLista.Parent := pnlBody;
  FLista.Align := alClient;
  FLista.AlignWithMargins := True;
  FLista.Margins.SetBounds(
    ScaleValue(MARGEN_LISTA),
    ScaleValue(MARGEN_LISTA),
    ScaleValue(MARGEN_LISTA),
    ScaleValue(MARGEN_LISTA));
  // cvfStatesString: con cvfInteger el checklist limita a 64 ítems.
  FLista.EditValueFormat := cvfStatesString;
  if Assigned(btnAceptar) then
    btnAceptar.OnClick := BtnAceptarClick;
  if Assigned(btnCancelar) then
    btnCancelar.OnClick := BtnCancelarClick;
  ClientHeight := ScaleValue(ALTO_SELECTOR);
  CompactarBotonera(Self);
  CargarLista;
end;

destructor TfrmSelPropiedades.Destroy;
begin
  FreeAndNil(CodigosSeleccionados);
  inherited;
end;

procedure TfrmSelPropiedades.DoCreate;
begin
  inherited;
  // FormCreate de TfrmBase traduce el Caption buscando su clave por la
  // jerarquía de clases: sin clave propia aplica la de TfrmBase ('frmBase').
  Caption := STituloAnadirPropiedades;
end;

function TfrmSelPropiedades.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    // Ejecutamos el botón cancelar y cerramos la modal
    BtnCancelarClick(Self);

    // Al devolver True, le decimos a Delphi: "Ya me he encargado de esta tecla,
    // córtala aquí y NO la pases al formulario principal".
    Result := True;
  end
  else if Message.CharCode = VK_F12 then
  begin
    // La acción F12 heredada llama al btnAceptarClick de la base (cierra
    // como Cancelar), no al OnClick asignado en el constructor.
    BtnAceptarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmSelPropiedades.CargarLista;
var
  iAnchoNombres: Integer;
  iAnchoTipos: Integer;
  oMedidor: TBitmap;
  oPropiedad: TDefinicionPropiedadArticulo;
  oPropiedades: TArray<TDefinicionPropiedadArticulo>;
  sTipo: string;
begin
  iAnchoNombres := 0;
  iAnchoTipos := 0;
  oMedidor := TBitmap.Create;
  FLista.Items.BeginUpdate;
  try
    oMedidor.Canvas.Font.Assign(FLista.Style.GetVisibleFont);
    FLista.Items.Clear;
    CodigosSeleccionados.Clear;
    oPropiedades := FLectura.ListarDisponibles;
    for oPropiedad in oPropiedades do
    begin
      // Excluir las ya asignadas
      if FExcluirCodigos.IndexOf(oPropiedad.Codigo) < 0 then
      begin
        sTipo := TextoTipoValor(oPropiedad.TipoValor);
        FLista.Items.Add.Text := oPropiedad.Nombre + #9 + sTipo;
        // La lista conserva el código asociado al mismo índice visual.
        CodigosSeleccionados.Add(oPropiedad.Codigo);
        iAnchoNombres := Max(
          iAnchoNombres,
          oMedidor.Canvas.TextWidth(oPropiedad.Nombre));
        iAnchoTipos := Max(iAnchoTipos, oMedidor.Canvas.TextWidth(sTipo));
      end;
    end;
    AjustarColumnaTipo(iAnchoNombres, iAnchoTipos, oMedidor.Canvas);
  finally
    FLista.Items.EndUpdate;
    FreeAndNil(oMedidor);
  end;
  // CodigosSeleccionados servirá como mapa índice→código
  // lo reutilizamos; los seleccionados reales se calculan en BtnAceptarClick
end;

// El tipo va tras un tabulador. El checklist pinta con DrawTextEx, que salta
// a múltiplos de TabWidth por el ancho medio de carácter: se toma el primer
// salto que deja atrás el nombre más largo y se ensancha el diálogo lo justo.
procedure TfrmSelPropiedades.AjustarColumnaTipo(AAnchoNombres,
  AAnchoTipos: Integer; AMedidor: TCanvas);
var
  iAnchoCaracter: Integer;
  oMetricas: TTextMetric;
begin
  GetTextMetrics(AMedidor.Handle, oMetricas);
  iAnchoCaracter := Max(oMetricas.tmAveCharWidth, 1);
  FLista.TabWidth :=
    Min(AAnchoNombres, ScaleValue(ANCHO_MAX_NOMBRES)) div iAnchoCaracter +
    SEPARACION_TIPO;
  ClientWidth := EnsureRange(
    FLista.TabWidth * iAnchoCaracter + AAnchoTipos +
      ScaleValue(RESERVA_ANCHO_LISTA),
    ScaleValue(ANCHO_MIN_SELECTOR),
    ScaleValue(ANCHO_MAX_SELECTOR));
end;

procedure TfrmSelPropiedades.BtnAceptarClick(Sender: TObject);
var
  i: Integer;
  seleccionados: TStringList;
begin
  seleccionados := TStringList.Create;
  try
    for i := 0 to FLista.Items.Count - 1 do
      if FLista.Items[i].Checked then
        seleccionados.Add(CodigosSeleccionados[i]);
    // Sin marcas vale la fila resaltada: clic en el nombre y Aceptar.
    if (seleccionados.Count = 0) and (FLista.ItemIndex >= 0) then
      seleccionados.Add(CodigosSeleccionados[FLista.ItemIndex]);
    CodigosSeleccionados.Clear;
    CodigosSeleccionados.AddStrings(seleccionados);
  finally
    FreeAndNil(seleccionados);
  end;
  ModalResult := mrOk;
end;

procedure TfrmSelPropiedades.BtnCancelarClick(Sender: TObject);
begin
  CodigosSeleccionados.Clear;
  ModalResult := mrCancel;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ TGestorPropiedades — constructor / destructor                               }
{ ═══════════════════════════════════════════════════════════════════════════ }

constructor TGestorPropiedades.Create(
  AScrollBox: TcxScrollBox;
  const AServicios: TServiciosPropiedadesArticulo;
  const AUsuario: string);
begin
  inherited Create;
  FScrollBox  := AScrollBox;
  FServicios  := AServicios;
  FUsuario    := AUsuario;
  FSlots      := TList<TSlotProp>.Create;
  FModificado := False;

  FScrollBox.AutoScroll := True;
end;

destructor TGestorPropiedades.Destroy;
begin
  LimpiarControles;
  FreeAndNil(FSlots);
  inherited;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Helpers internos                                                            }
{ ═══════════════════════════════════════════════════════════════════════════ }

function TGestorPropiedades.TipoDesdeCadena(
  const ATipo: string): TTipoValorProp;
begin
  if      ATipo = 'LISTA'    then Result := tvpLista
  else if ATipo = 'NUMERO'   then Result := tvpNumero
  else if ATipo = 'BOOLEANO' then Result := tvpBooleano
  else                            Result := tvpTextoLibre;
end;

function TGestorPropiedades.IndexOfCodigo(const ACod: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FSlots.Count - 1 do
    if FSlots[i].CodigoPropiedad = ACod then
    begin
      Result := i;
      Break;
    end;
end;

procedure TGestorPropiedades.LimpiarControles;
var
  i: Integer;
begin
  // Liberar diccionarios de opciones
  for i := 0 to FSlots.Count - 1 do
    if Assigned(FSlots[i].Opciones) then
      FreeAndNil(FSlots[i].Opciones);
  FSlots.Clear;

  // Destruir controles del scroll
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FreeAndNil(FScrollBox.Controls[0]);
  finally
    FScrollBox.EnableAlign;
  end;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Carga desde BD                                                              }
{ ═══════════════════════════════════════════════════════════════════════════ }

procedure TGestorPropiedades.CargarPropiedades(const ACodigoArticulo: string);
var
  i: Integer;
  oDefinicion: TDefinicionPropiedadArticulo;
  oDefiniciones: TArray<TDefinicionPropiedadArticulo>;
  oOpcion: TOpcionPropiedadArticulo;
  oOpciones: TArray<TOpcionPropiedadArticulo>;
  S: TSlotProp;
begin
  // Guard de reentrada: dos cargas solapadas (p.ej. dos AfterScroll casi
  // simultaneos) comparten FSlots y el LimpiarControles de una vacia la
  // lista mientras la otra la recorre -> EArgumentOutOfRangeException.
  if not FCargando then
  begin
    FCargando := True;
    try
      FCodigoArticulo := ACodigoArticulo;
      LimpiarControles;
      FModificado := False;
      if ACodigoArticulo <> '' then
      begin
        oDefiniciones := FServicios.Lectura.ListarAsignadas(ACodigoArticulo);
        for oDefinicion in oDefiniciones do
        begin
          S := Default(TSlotProp);
          S.CodigoPropiedad := oDefinicion.Codigo;
          S.NombrePropiedad := oDefinicion.Nombre;
          S.TipoValor := TipoDesdeCadena(oDefinicion.TipoValor);
          S.Nivel := oDefinicion.Nivel;
          S.EsRequerido := oDefinicion.EsRequerido;
          S.IdValorPV := oDefinicion.IdValor;
          S.ValorLibre := oDefinicion.ValorLibre;
          S.OriginalIdValorPV := S.IdValorPV;
          S.OriginalValorLibre := S.ValorLibre;
          S.Ctrl := nil;
          S.Opciones := nil;
          S.Eliminar := False;
          FSlots.Add(S);
        end;
        for i := 0 to FSlots.Count - 1 do
        begin
          if FSlots[i].TipoValor = tvpLista then
          begin
            S := FSlots[i];
            S.Opciones := TDictionary<Integer, string>.Create;
            oOpciones := FServicios.Lectura.ListarOpciones(
              S.CodigoPropiedad);
            for oOpcion in oOpciones do
              S.Opciones.Add(oOpcion.IdValor, oOpcion.Valor);
            FSlots[i] := S;
          end;
        end;
        ReconstruirVista;
      end;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TGestorPropiedades.AsignarCodigoArticulo(
  const ACodigoArticulo: string);
begin
  FCodigoArticulo := ACodigoArticulo;
end;

procedure TGestorPropiedades.CargarPropiedadesPorFamilia(
                                                   const ACodigoFamilia:
                                                   string);
var
  EstaVacia: Boolean;
  i: Integer;
  idx: Integer;
  oDefinicion: TDefinicionPropiedadArticulo;
  oDefiniciones: TArray<TDefinicionPropiedadArticulo>;
  oOpcion: TOpcionPropiedadArticulo;
  oOpciones: TArray<TOpcionPropiedadArticulo>;
  S: TSlotProp;
begin
  if ACodigoFamilia <> '' then
  begin
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if (not S.Eliminar) and Assigned(S.Ctrl) then
    begin
      case S.TipoValor of
        tvpLista:
          if (S.Ctrl as TcxComboBox).ItemIndex > 0 then
            S.IdValorPV := Integer((S.Ctrl as TcxComboBox).Properties.Items.
                                     Objects[(S.Ctrl as TcxComboBox).ItemIndex])
          else
            S.IdValorPV := 0;
        tvpTextoLibre:
          S.ValorLibre := Trim((S.Ctrl as TcxTextEdit).Text);
        tvpNumero:
          if not LeerNumeroPropiedad((S.Ctrl as TcxMaskEdit).Text,
            S.ValorLibre) then
            S.ValorLibre := '';
        tvpBooleano:
          if (S.Ctrl as TcxCheckBox).Checked then
            S.ValorLibre := 'S'
          else
            S.ValorLibre := 'N';
      end;
      S.OriginalIdValorPV  := S.IdValorPV;
      S.OriginalValorLibre := S.ValorLibre;
    end;
    FSlots[i] := S;
  end;
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    EstaVacia := False;
    case S.TipoValor of
      tvpLista:      EstaVacia := (S.IdValorPV <= 0);
      tvpTextoLibre: EstaVacia := (S.ValorLibre = '');
      tvpNumero:     EstaVacia := (S.ValorLibre = '') or (S.ValorLibre = '0');
      tvpBooleano:   EstaVacia := (S.ValorLibre <> 'S') and
                                                          (S.ValorLibre <> '1');
    end;
    if EstaVacia then
      S.Eliminar := True;
    FSlots[i] := S;
  end;
  FModificado := True;
  oDefiniciones := FServicios.Lectura.ListarFamilia(ACodigoFamilia);
  for oDefinicion in oDefiniciones do
  begin
    idx := IndexOfCodigo(oDefinicion.Codigo);
    if idx < 0 then
    begin
      S := Default(TSlotProp);
      S.CodigoPropiedad := oDefinicion.Codigo;
      S.NombrePropiedad := oDefinicion.Nombre;
      S.TipoValor := TipoDesdeCadena(oDefinicion.TipoValor);
      S.Nivel := oDefinicion.Nivel;
      S.EsRequerido := oDefinicion.EsRequerido;
      S.IdValorPV := 0;
      S.ValorLibre := '';
      S.OriginalIdValorPV := S.IdValorPV;
      S.OriginalValorLibre := S.ValorLibre;
      S.Ctrl := nil;
      S.Opciones := nil;
      S.Eliminar := False;
      if S.TipoValor = tvpLista then
      begin
        S.Opciones := TDictionary<Integer, string>.Create;
        oOpciones := FServicios.Lectura.ListarOpciones(
          S.CodigoPropiedad);
        for oOpcion in oOpciones do
        begin
          S.Opciones.Add(oOpcion.IdValor, oOpcion.Valor);
        end;
      end;
      FSlots.Add(S);
    end
    else
    begin
      S := FSlots[idx];
      S.EsRequerido := oDefinicion.EsRequerido;
      S.Eliminar := False;
      FSlots[idx] := S;
    end;
  end;
  ReconstruirVista;
  end;
end;

// Ancho del rótulo más largo, medido con un TcxLabel en el propio panel
// (misma fuente y escala que las filas; negrita si es obligatoria). Antes
// «Edad máxima aconsejada (años)» salía cortado por el control.
function TGestorPropiedades.AnchoColumnaRotulos: Integer;
var
  oMedidor: Vcl.Graphics.TBitmap;
  S: TSlotProp;
begin
  // FZ-ISSUE-789: un TcxLabel no calcula su AutoSize mientras el panel
  // no tiene ventana; se mide el texto con la fuente que heredan los
  // rótulos (la del panel, ya escalada).
  Result := ANCHO_LABEL;
  oMedidor := Vcl.Graphics.TBitmap.Create;
  try
    oMedidor.Canvas.Font.Assign(TControlFuentePropiedades(FScrollBox).Font);
    for S in FSlots do
      if not S.Eliminar then
      begin
        if S.EsRequerido then
          oMedidor.Canvas.Font.Style := [fsBold]
        else
          oMedidor.Canvas.Font.Style := [];
        Result := Max(Result,
          oMedidor.Canvas.TextWidth(S.NombrePropiedad) + 8);
      end;
  finally
    FreeAndNil(oMedidor);
  end;
  Result := Min(Result, ANCHO_LABEL_MAX);
end;

procedure TGestorPropiedades.ReconstruirVista;
var
  i   : Integer;
  Top : Integer;
  S   : TSlotProp;
begin
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FreeAndNil(FScrollBox.Controls[0]);
    for i := 0 to FSlots.Count - 1 do
    begin
      S := FSlots[i];
      S.Ctrl := nil;
      FSlots[i] := S;
    end;
  finally
    FScrollBox.EnableAlign;
  end;
  FAnchoLabel := AnchoColumnaRotulos;
  Top := MARGEN_V;
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if not S.Eliminar then
    begin
      case S.TipoValor of
        tvpLista      : CrearFilaLista   (S, Top);
        tvpTextoLibre : CrearFilaTexto   (S, Top);
        tvpNumero     : CrearFilaNumero  (S, Top);
        tvpBooleano   : CrearFilaBooleano(S, Top);
      end;
      CrearBtnEliminar(i, Top);
      if (S.Nivel = 'COLOR') or (S.Nivel = 'SKU') then
        CrearBtnPorUnidad(i, Top);
      FSlots[i] := S;
      Inc(Top, ALTO_FILA + MARGEN_V);
    end;
  end;
end;

procedure TGestorPropiedades.CrearFilaLista(var S: TSlotProp; ATop: Integer);
var
  lbl : TcxLabel;
  cb  : TcxComboBox;
  IdV : Integer;
  Txt : string;
  Idx : Integer;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent  := FScrollBox;
  lbl.Left    := MARGEN_H;
  lbl.Top     := ATop + 4;
  lbl.Width   := FAnchoLabel;
  lbl.AutoSize:= True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption := S.NombrePropiedad;
  lbl.Transparent := True;
  cb := TcxComboBox.Create(FScrollBox);
  cb.Parent  := FScrollBox;
  cb.Left    := MARGEN_H + FAnchoLabel + 6;
  cb.Top     := ATop;
  cb.Width   := ANCHO_CTRL;
  cb.Height  := ALTO_FILA;
  cb.Properties.DropDownListStyle := lsFixedList;
  cb.Properties.Items.Add('');   // opción vacía
  if Assigned(S.Opciones) then
    for IdV in S.Opciones.Keys do
    begin
      Txt := S.Opciones[IdV];
      cb.Properties.Items.AddObject(Txt, TObject(IdV));
    end;
  if S.IdValorPV > 0 then
    for Idx := 1 to cb.Properties.Items.Count - 1 do
      if Integer(cb.Properties.Items.Objects[Idx]) = S.IdValorPV then
      begin
        cb.ItemIndex := Idx;
        Break;
      end;
  S.Ctrl := cb;
end;

procedure TGestorPropiedades.CrearFilaTexto(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  ed : TcxTextEdit;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := FAnchoLabel;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;
  lbl.Transparent := True;
  ed := TcxTextEdit.Create(FScrollBox);
  ed.Parent := FScrollBox;
  ed.Left   := MARGEN_H + FAnchoLabel + 6;
  ed.Top    := ATop;
  ed.Width  := ANCHO_CTRL;
  ed.Height := ALTO_FILA;
  ed.Text   := S.ValorLibre;
  S.Ctrl := ed;
end;

procedure TGestorPropiedades.CrearFilaNumero(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  sp : TcxMaskEdit;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := FAnchoLabel;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;
  lbl.Transparent := True;
  // FZ-ISSUE-789: un TcxSpinEdit convierte el vacío en 0 al validar la
  // entrada, y una obligatoria vaciada se grababa con 0. El editor de
  // texto con máscara numérica admite quedarse vacío.
  sp := TcxMaskEdit.Create(FScrollBox);
  sp.Parent  := FScrollBox;
  sp.Left    := MARGEN_H + FAnchoLabel + 6;
  sp.Top     := ATop;
  sp.Width   := 120;
  sp.Height  := ALTO_FILA;
  sp.Properties.MaskKind := emkRegExpr;
  sp.Properties.EditMask := '-?\d{1,12}([.,]\d{1,6})?';
  sp.Properties.IgnoreMaskBlank := True;
  sp.Properties.Alignment.Horz := taRightJustify;
  sp.Text := S.ValorLibre;
  S.Ctrl := sp;
end;

procedure TGestorPropiedades.CrearFilaBooleano(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  chk: TcxCheckBox;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := FAnchoLabel;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;
  lbl.Transparent := True;
  chk := TcxCheckBox.Create(FScrollBox);
  chk.Parent   := FScrollBox;
  chk.Left     := MARGEN_H + FAnchoLabel + 6;
  chk.Top      := ATop + 4;
  chk.Width    := ALTO_FILA;
  chk.Height   := ALTO_FILA;
  chk.Caption  := '';
  chk.Properties.DisplayChecked   := '';
  chk.Properties.DisplayUnchecked := '';
  chk.Properties.DisplayGrayed    := '';
  chk.Checked  := (S.ValorLibre = 'S') or (S.ValorLibre = '1');
  S.Ctrl := chk;
end;

procedure TGestorPropiedades.CrearBtnEliminar(ASlotIdx: Integer; ATop: Integer);
var
  btn: TcxButton;
begin
  btn := TcxButton.Create(FScrollBox);
  btn.Parent  := FScrollBox;
  btn.Left    := MARGEN_H + FAnchoLabel + 6 + ANCHO_CTRL + 6;
  btn.Top     := ATop;
  btn.Width   := ANCHO_BTN_DEL;
  btn.Height  := ALTO_FILA;
  btn.Caption := '×';
  btn.Tag     := ASlotIdx;
  btn.Enabled := not FSlots[ASlotIdx].EsRequerido;
  btn.Hint    := Format(SHintQuitarPropiedad,
                        [FSlots[ASlotIdx].NombrePropiedad]);
  btn.ShowHint:= True;
  btn.OnClick := BtnEliminarClick;
end;

procedure TGestorPropiedades.BtnEliminarClick(Sender: TObject);
var
  idx: Integer;
  S  : TSlotProp;
begin
  idx := (Sender as TcxButton).Tag;
  if (idx >= 0) and (idx < FSlots.Count) and
     (MessageDlg_fza(Format(SPreguntaQuitarPropiedadArticulo,
       [FSlots[idx].NombrePropiedad]),
       mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    S := FSlots[idx];
    S.Eliminar := True;
    FSlots[idx] := S;
    FModificado := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        ReconstruirVista;
      end
    );
  end;
end;

procedure TGestorPropiedades.CrearBtnPorUnidad(ASlotIdx, ATop: Integer);
var
  btn: TcxButton;
  S  : TSlotProp;
begin
  S := FSlots[ASlotIdx];
  btn := TcxButton.Create(FScrollBox);
  btn.Parent := FScrollBox;
  btn.Left   := MARGEN_H + FAnchoLabel + 6 + ANCHO_CTRL + 6 + ANCHO_BTN_DEL + 6;
  btn.Top    := ATop;
  btn.Width  := 110;
  btn.Height := ALTO_FILA;
  if S.Nivel = 'SKU' then
    btn.Caption := SCaptionPorColorSku
  else
    btn.Caption := SCaptionPorColor;
  btn.Tag      := ASlotIdx;
  btn.Hint     := Format(SHintFijarPropiedadPorColorSku,
                         [S.NombrePropiedad]);
  btn.ShowHint := True;
  btn.OnClick  := BtnPorUnidadClick;
end;

procedure TGestorPropiedades.BtnPorUnidadClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := (Sender as TcxButton).Tag;
  if (idx >= 0) and (idx < FSlots.Count) then
  begin
    if FCodigoArticulo = '' then
      ShowMessage_fza(SErrorArticuloNoGuardadoValoresColor)
    else
      AbrirEditorPorUnidad(FSlots[idx]);
  end;
end;

procedure TGestorPropiedades.AbrirEditorPorUnidad(const S: TSlotProp);
var
  dlg: TfrmPropPorUnidad;
begin
  dlg := TfrmPropPorUnidad.Create(
    nil,
    FServicios,
    FUsuario,
    FCodigoArticulo,
    S.CodigoPropiedad,
    S.NombrePropiedad,
    S.TipoValor,
    S.Nivel);
  try
    dlg.ShowModal;
  finally
    FreeAndNil(dlg);
  end;
end;

procedure TGestorPropiedades.AbrirSelectorPropiedades;
var
  cod: string;
  dlg: TfrmSelPropiedades;
  Excluidos: TStringList;
  i: Integer;
  oDefinicion: TDefinicionPropiedadArticulo;
  oOpcion: TOpcionPropiedadArticulo;
  oOpciones: TArray<TOpcionPropiedadArticulo>;
  S: TSlotProp;
begin
  if FCodigoArticulo = '' then
  begin
    ShowMessage_fza(SErrorArticuloNoGuardadoAnadirPropiedades);
  end
  else
  begin
    Excluidos := TStringList.Create;
    try
      for i := 0 to FSlots.Count - 1 do
        if not FSlots[i].Eliminar then
          Excluidos.Add(FSlots[i].CodigoPropiedad);
      dlg := TfrmSelPropiedades.Create(
        nil,
        FServicios.Lectura,
        Excluidos);
      try
        if (dlg.ShowModal = mrOk) and
           (dlg.CodigosSeleccionados.Count > 0) then
        begin
          for cod in dlg.CodigosSeleccionados do
          begin
            if FServicios.Lectura.Buscar(cod, oDefinicion) then
            begin
              S := Default(TSlotProp);
              S.CodigoPropiedad := oDefinicion.Codigo;
              S.NombrePropiedad := oDefinicion.Nombre;
              S.TipoValor := TipoDesdeCadena(oDefinicion.TipoValor);
              S.Nivel := oDefinicion.Nivel;
              S.EsRequerido := False;
              S.IdValorPV := 0;
              S.ValorLibre := '';
              S.OriginalIdValorPV := S.IdValorPV;
              S.OriginalValorLibre := S.ValorLibre;
              S.Ctrl := nil;
              S.Opciones := nil;
              S.Eliminar := False;
              if S.TipoValor = tvpLista then
              begin
                S.Opciones := TDictionary<Integer, string>.Create;
                oOpciones := FServicios.Lectura.ListarOpciones(
                  S.CodigoPropiedad);
                for oOpcion in oOpciones do
                  S.Opciones.Add(oOpcion.IdValor, oOpcion.Valor);
              end;
              FSlots.Add(S);
              FModificado := True;
            end;
          end;
          ReconstruirVista;
        end;
      finally
        FreeAndNil(dlg);
      end;
    finally
      FreeAndNil(Excluidos);
    end;
  end;
end;

function TGestorPropiedades.Validar: string;
var
  i: Integer;
  S: TSlotProp;
  TieneValor: Boolean;
  sNumero: string;
begin
  Result := '';
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if (Result = '') and S.EsRequerido then
    begin
      TieneValor := False;
      if (not S.Eliminar) and Assigned(S.Ctrl) then
      case S.TipoValor of
        tvpLista:
          TieneValor := (S.Ctrl as TcxComboBox).ItemIndex > 0;
        tvpTextoLibre:
          TieneValor := Trim((S.Ctrl as TcxTextEdit).Text) <> '';
        tvpNumero:
          TieneValor := LeerNumeroPropiedad(
            (S.Ctrl as TcxMaskEdit).Text, sNumero);
        tvpBooleano:
          TieneValor := True;
      end;
      if not TieneValor then
        Result := Format(SErrorPropiedadObligatoriaFamilia,
          [S.NombrePropiedad]);
    end;
  end;
end;

function TGestorPropiedades.GuardarPropiedades(
  AValidar: Boolean): Boolean;
var
  i  : Integer;
  S  : TSlotProp;
  sE : string;
begin
  sE := '';
  if AValidar then
    sE := Validar;
  if sE <> '' then
    raise Exception.Create(sE);
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if S.Eliminar then
      DeleteSlot(S.CodigoPropiedad)
    else if Assigned(S.Ctrl) then
    begin
      case S.TipoValor of
        tvpLista:
        begin
          if (S.Ctrl as TcxComboBox).ItemIndex > 0 then
            S.IdValorPV := Integer(
              (S.Ctrl as TcxComboBox).Properties.Items.Objects[
                (S.Ctrl as TcxComboBox).ItemIndex])
          else
            S.IdValorPV := 0;
          S.ValorLibre := '';
        end;
        tvpTextoLibre:
        begin
          S.IdValorPV  := 0;
          S.ValorLibre := Trim((S.Ctrl as TcxTextEdit).Text);
        end;
        tvpNumero:
        begin
          S.IdValorPV  := 0;
          if not LeerNumeroPropiedad((S.Ctrl as TcxMaskEdit).Text,
            S.ValorLibre) then
            S.ValorLibre := '';
        end;
        tvpBooleano:
        begin
          S.IdValorPV  := 0;
          S.ValorLibre := TGenUtils.IfThen<String>(
            (S.Ctrl as TcxCheckBox).Checked, 'S', 'N');
        end;
      end;
      if (S.IdValorPV <> S.OriginalIdValorPV) or
         (S.ValorLibre <> S.OriginalValorLibre) then
      begin
        UpsertSlot(S);
        S.OriginalIdValorPV  := S.IdValorPV;
        S.OriginalValorLibre := S.ValorLibre;
      end;
      FSlots[i] := S;
    end;
  end;
  FModificado := False;
  Result := True;
end;

procedure TGestorPropiedades.UpsertSlot(const S: TSlotProp);
begin
  FServicios.Escritura.GuardarValor(
    FCodigoArticulo,
    S.CodigoPropiedad,
    '',
    S.IdValorPV,
    S.ValorLibre,
    FUsuario);
end;

procedure TGestorPropiedades.DeleteSlot(const CodigoPropiedad: string);
begin
  if FCodigoArticulo <> '' then
    FServicios.Escritura.EliminarPropiedad(
      FCodigoArticulo,
      CodigoPropiedad,
      FUsuario);
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ TfrmPropPorUnidad — editor de una propiedad por color/SKU                    }
{ ═══════════════════════════════════════════════════════════════════════════ }

constructor TfrmPropPorUnidad.Create(
  AOwner: TComponent;
  const AServicios: TServiciosPropiedadesArticulo;
  const AUsuario, AArticulo, ACodigoProp, ANombreProp: string;
  ATipoValor: TTipoValorProp;
  const ANivel: string);
begin
  inherited Create(AOwner);
  FServicios  := AServicios;
  FUsuario    := AUsuario;
  FArticulo   := AArticulo;
  FCodigoProp := ACodigoProp;
  FNombreProp := ANombreProp;
  FTipoValor  := ATipoValor;
  FNivel      := ANivel;
  FFilas      := TList<TFilaUnidadProp>.Create;
  FOpciones   := TList<TPair<Integer, string>>.Create;
  FActuales   := TDictionary<string, TValUnidadProp>.Create;
  Width       := 560;
  Height      := 460;
  Position    := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Font.Name   := 'Source Sans 3';
  CompactarBotonera(Self);
  FScroll := TcxScrollBox.Create(Self);
  FScroll.Parent      := pnlBody;
  FScroll.Align       := alClient;
  FScroll.BorderStyle := cxcbsNone;
  FScroll.AutoScroll  := True;
  if FTipoValor = tvpLista then
    CargarOpciones;
  CargarUnidades;
  CargarValoresActuales;
  ConstruirFilas;
  if Assigned(btnAceptar) then
    btnAceptar.OnClick := BtnAceptarClick;
  if Assigned(btnCancelar) then
    btnCancelar.OnClick := BtnCancelarClick;
end;

destructor TfrmPropPorUnidad.Destroy;
begin
  FreeAndNil(FFilas);
  FreeAndNil(FOpciones);
  FreeAndNil(FActuales);
  inherited;
end;

procedure TfrmPropPorUnidad.DoCreate;
begin
  inherited;
  // Como en TfrmSelPropiedades.DoCreate: FormCreate deja 'frmBase'.
  if FNivel = 'SKU' then
    Caption := Format(STituloPropiedadPorSku, [FNombreProp])
  else
    Caption := Format(STituloPropiedadPorColor, [FNombreProp]);
end;

function TfrmPropPorUnidad.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    BtnCancelarClick(Self);
    Result := True;
  end
  else if Message.CharCode = VK_F12 then
  begin
    BtnAceptarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmPropPorUnidad.CargarOpciones;
var
  oOpcion: TOpcionPropiedadArticulo;
  oOpciones: TArray<TOpcionPropiedadArticulo>;
begin
  oOpciones := FServicios.Lectura.ListarOpciones(FCodigoProp);
  for oOpcion in oOpciones do
  begin
    FOpciones.Add(TPair<Integer, string>.Create(
      oOpcion.IdValor,
      oOpcion.Valor));
  end;
end;

procedure TfrmPropPorUnidad.CargarUnidades;
var
  F: TFilaUnidadProp;
  oUnidad: TUnidadPropiedadArticulo;
  oUnidades: TArray<TUnidadPropiedadArticulo>;
begin
  oUnidades := FServicios.Lectura.ListarUnidades(FArticulo, FNivel);
  for oUnidad in oUnidades do
  begin
    F := Default(TFilaUnidadProp);
    F.Unidad := oUnidad.Codigo;
    F.Nombre := oUnidad.Nombre;
    F.Ctrl := nil;
    FFilas.Add(F);
  end;
end;

procedure TfrmPropPorUnidad.CargarValoresActuales;
var
  oValor: TValorUnidadPropiedadArticulo;
  oValores: TArray<TValorUnidadPropiedadArticulo>;
  V: TValUnidadProp;
begin
  oValores := FServicios.Lectura.ListarValoresUnidades(
    FArticulo,
    FCodigoProp);
  for oValor in oValores do
  begin
    V.IdValor := oValor.IdValor;
    V.ValorLibre := oValor.ValorLibre;
    FActuales.AddOrSetValue(oValor.CodigoUnidad, V);
  end;
end;

procedure TfrmPropPorUnidad.ConstruirFilas;
var
  i        : Integer;
  Top      : Integer;
  F        : TFilaUnidadProp;
  V        : TValUnidadProp;
  lblVacio : TcxLabel;
begin
  if FFilas.Count = 0 then
  begin
    lblVacio := TcxLabel.Create(FScroll);
    lblVacio.Parent      := FScroll;
    lblVacio.Left        := MARGEN_H;
    lblVacio.Top         := MARGEN_V;
    lblVacio.Caption     := SCaptionSinColoresSkuDefinidos;
    lblVacio.Transparent := True;
  end;
  Top := MARGEN_V;
  for i := 0 to FFilas.Count - 1 do
  begin
    F := FFilas[i];
    if FActuales.TryGetValue(F.Unidad, V) then
      CrearControlFila(F, Top, V.IdValor, V.ValorLibre)
    else
      CrearControlFila(F, Top, 0, '');
    FFilas[i] := F;
    Inc(Top, ALTO_FILA + MARGEN_V);
  end;
end;

procedure TfrmPropPorUnidad.CrearControlFila(var F: TFilaUnidadProp;
  ATop, AIdValor: Integer; const AValorLibre: string);
var
  lbl : TcxLabel;
  cb  : TcxComboBox;
  ed  : TcxTextEdit;
  sp  : TcxSpinEdit;
  chk : TcxCheckBox;
  par : TPair<Integer, string>;
  Idx : Integer;
begin
  lbl := TcxLabel.Create(FScroll);
  lbl.Parent      := FScroll;
  lbl.Left        := MARGEN_H;
  lbl.Top         := ATop + 4;
  lbl.Width       := ANCHO_LABEL;
  lbl.AutoSize    := True;
  lbl.Caption     := F.Nombre;
  lbl.Transparent := True;
  case FTipoValor of
    tvpLista:
    begin
      cb := TcxComboBox.Create(FScroll);
      cb.Parent := FScroll;
      cb.Left   := MARGEN_H + ANCHO_LABEL + 6;
      cb.Top    := ATop;
      cb.Width  := ANCHO_CTRL;
      cb.Height := ALTO_FILA;
      cb.Properties.DropDownListStyle := lsFixedList;
      cb.Properties.Items.Add('');
      for par in FOpciones do
        cb.Properties.Items.AddObject(par.Value, TObject(par.Key));
      if AIdValor > 0 then
        for Idx := 1 to cb.Properties.Items.Count - 1 do
          if Integer(cb.Properties.Items.Objects[Idx]) = AIdValor then
            cb.ItemIndex := Idx;
      F.Ctrl := cb;
    end;
    tvpTextoLibre:
    begin
      ed := TcxTextEdit.Create(FScroll);
      ed.Parent := FScroll;
      ed.Left   := MARGEN_H + ANCHO_LABEL + 6;
      ed.Top    := ATop;
      ed.Width  := ANCHO_CTRL;
      ed.Height := ALTO_FILA;
      ed.Text   := AValorLibre;
      F.Ctrl := ed;
    end;
    tvpNumero:
    begin
      sp := TcxSpinEdit.Create(FScroll);
      sp.Parent := FScroll;
      sp.Left   := MARGEN_H + ANCHO_LABEL + 6;
      sp.Top    := ATop;
      sp.Width  := 120;
      sp.Height := ALTO_FILA;
      sp.Properties.EditFormat := '0.00';
      if AValorLibre <> '' then
        sp.Value := StrToFloatDef(
          StringReplace(AValorLibre, ',', '.', []), 0);
      F.Ctrl := sp;
    end;
    tvpBooleano:
    begin
      chk := TcxCheckBox.Create(FScroll);
      chk.Parent := FScroll;
      chk.Left   := MARGEN_H + ANCHO_LABEL + 6;
      chk.Top    := ATop + 4;
      chk.Width  := ALTO_FILA;
      chk.Height := ALTO_FILA;
      chk.Caption := '';
      chk.Properties.DisplayChecked   := '';
      chk.Properties.DisplayUnchecked := '';
      chk.Properties.DisplayGrayed    := '';
      chk.Checked := (AValorLibre = 'S') or (AValorLibre = '1');
      F.Ctrl := chk;
    end;
  end;
end;

procedure TfrmPropPorUnidad.UpsertUnidad(const AUnidad: string;
  AIdValor: Integer; const AValorLibre: string);
begin
  FServicios.Escritura.GuardarValor(
    FArticulo,
    FCodigoProp,
    AUnidad,
    AIdValor,
    AValorLibre,
    FUsuario);
end;

procedure TfrmPropPorUnidad.DeleteUnidad(const AUnidad: string);
begin
  FServicios.Escritura.EliminarValorUnidad(
    FArticulo,
    FCodigoProp,
    AUnidad,
    FUsuario);
end;

procedure TfrmPropPorUnidad.BtnAceptarClick(Sender: TObject);
var
  i     : Integer;
  F     : TFilaUnidadProp;
  idVal : Integer;
  libre : string;
  vacio : Boolean;
begin
  for i := 0 to FFilas.Count - 1 do
  begin
    F := FFilas[i];
    if Assigned(F.Ctrl) then
    begin
      idVal := 0;
      libre := '';
      vacio := True;
      case FTipoValor of
        tvpLista:
          if (F.Ctrl as TcxComboBox).ItemIndex > 0 then
          begin
            idVal := Integer((F.Ctrl as TcxComboBox).Properties.Items.Objects[
                       (F.Ctrl as TcxComboBox).ItemIndex]);
            vacio := False;
          end;
        tvpTextoLibre:
        begin
          libre := Trim((F.Ctrl as TcxTextEdit).Text);
          vacio := libre = '';
        end;
        tvpNumero:
          if Trim((F.Ctrl as TcxSpinEdit).Text) <> '' then
          begin
            libre := FloatToStr((F.Ctrl as TcxSpinEdit).Value);
            vacio := False;
          end;
        tvpBooleano:
          if (F.Ctrl as TcxCheckBox).Checked then
          begin
            libre := 'S';
            vacio := False;
          end;
      end;
      if vacio then
        DeleteUnidad(F.Unidad)
      else
        UpsertUnidad(F.Unidad, idVal, libre);
    end;
  end;
  ModalResult := mrOk;
end;

procedure TfrmPropPorUnidad.BtnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.


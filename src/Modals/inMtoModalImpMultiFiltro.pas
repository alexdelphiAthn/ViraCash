{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMultiFiltro                                      }
{    Tipo:       Formulario base (Modal de impresión)                          }
{ Versión:       1.3.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario BASE para informes (FastReport) con filtros múltiples en       }
{    pestañas. Hereda de TfrmPrint y, al mostrarse, crea por código un         }
{    TcxPageControl con una pestaña por filtro: Fechas (rango) y, como         }
{    checklists multi-selección CON BUSCADOR, Almacenes / Proveedores /        }
{    Temporadas / Artículos.                                                   }
{                                                                              }
{    Familias se muestra como ÁRBOL jerárquico (no como lista plana): se       }
{    pinta la jerarquía padre→subfamilias (CODIGO_PADRE_FAM) y marcar     }
{    una familia incluye en cascada todas sus subfamilias, de modo que el      }
{    usuario elige el padre o el hijo según convenga. Ver CrearTabFamiliasArbol}
{                                                                              }
{    Cada checklist de filtro guarda su lista completa (Fuente) y el conjunto  }
{    de códigos marcados (Marcados); el buscador re-filtra las filas visibles  }
{    sin perder lo marcado. Convención: sin nada marcado = todos. El CSV       }
{    devuelto sale de Marcados (no de las filas visibles), así un filtro de    }
{    búsqueda no descarta selecciones ocultas.                                 }
{                                                                              }
{    Los descendientes indican con FiltrosUsados qué pestañas quieren y leen   }
{    CSVAlmacenes / CSVFamilias / CSVProveedores / CSVTemporadas /             }
{    CSVArticulos y FechaDesde / FechaHasta. Para checklists propios sin       }
{    buscador (p. ej. bandas) disponen de CrearTabChecklist +                  }
{    SeleccionadosCSV.                                                         }
{******************************************************************************}
unit inMtoModalImpMultiFiltro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, System.Generics.Collections, Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoModalGenImp, inLibInformeMultiFiltroPersistenciaIntf,
  inLibFamiliasArbolVcl, inLibResumenSeleccionesInforme,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxPC, cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses,
  cxTL, cxTLData, cxInplaceContainer,
  cxButtons, cxSpinEdit, cxImage, dxSkinsCore, dxSkinsForm;

type
  TFiltroReport = (frFechas, frAlmacenes, frFamilias, frProveedores,
                   frTemporadas, frArticulos);
  TFiltrosReport = set of TFiltroReport;

  // Checklist de filtro con buscador. Fuente = todos los ítems ("COD - NOM");
  // Marcados = códigos marcados (se conservan aunque el buscador oculte filas).
  TFiltroChecklist = class
  public
    Clb     : TcxCheckListBox;
    Edt     : TcxTextEdit;
    Fuente  : TStringList;
    Marcados: TStringList;
    // Título de la pestaña; etiqueta del filtro en el resumen.
    Titulo  : string;
    constructor Create;
    destructor Destroy; override;
  end;

  // Dimensión de agrupación (proveedor / familia / temporada...). El orden en
  // la lista marca la prioridad (la primera = grupo más externo); Marcado
  // indica si entra en la jerarquía.
  TItemAgrup = class
  public
    Codigo  : string;
    Etiqueta: string;
    Marcado : Boolean;
  end;

  TfrmPrintMultiFiltro = class(TfrmPrint)
  private
    FFiltrosCreados : Boolean;
    FpcFiltros      : TcxPageControl;
    FtsFechas       : TcxTabSheet;
    FdteDesde       : TcxDateEdit;
    FdteHasta       : TcxDateEdit;
    FFiltros        : TObjectList<TFiltroChecklist>;
    FfcAlmacenes    : TFiltroChecklist;
    FfcProveedores  : TFiltroChecklist;
    FfcTemporadas   : TFiltroChecklist;
    FfcArticulos    : TFiltroChecklist;
    // Familias va como árbol jerárquico (no checklist plano): marcar una
    // familia incluye sus subfamilias. Lo gobierna TArbolFamiliasVcl, el
    // mismo árbol que usa el selector de familias de otras pantallas.
    FtlFamilias     : TcxTreeList;
    FGestorFamilias : TArbolFamiliasVcl;
    FedtFamilias    : TcxTextEdit;
    // Pestaña de agrupaciones (reordenable). FAgrupItems es el orden actual de
    // las dimensiones; FclbAgrup el checklist; FseNivelFam el nivel de familia.
    FAgrupItems     : TObjectList<TItemAgrup>;
    FclbAgrup       : TcxCheckListBox;
    FseNivelFam     : TcxSpinEdit;
    FTituloAgrup    : string;
    FRepositorioFiltros: IRepositorioInformeMultiFiltro;
    FNombreIconoMenu: string;
    procedure CrearTabFechas;
    procedure ConfigurarFecha(AEditor: TcxDateEdit);
    procedure SeleccionarFecha(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ValidarTextoFecha(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure ValidarEditorFecha(AEditor: TcxDateEdit;
      const AMensajeVacio: string);
    procedure CrearIconoInforme;
    function  CrearTabFiltro(const ACaption: string): TFiltroChecklist;
    procedure CargarFiltro(AFc: TFiltroChecklist;
      const AOpciones: TOpcionesInformeMultiFiltro);
    procedure RefiltrarChecklist(AFc: TFiltroChecklist);
    procedure CargarFiltros;
    function  CodigoDeItem(const AText: string): string;
    function  FiltroPorClb(AClb: TObject): TFiltroChecklist;
    function  FiltroPorEdt(AEdt: TObject): TFiltroChecklist;
    function  CSVDe(AFc: TFiltroChecklist): string;
    procedure ClbFiltroClickCheck(Sender: TObject; AIndex: Integer;
                                   APrevState, ANewState: TcxCheckBoxState);
    procedure SearchChange(Sender: TObject);
    // Soporte de la pestaña de agrupaciones reordenable.
    procedure AgrupRefrescar;
    procedure AgrupClickCheck(Sender: TObject; AIndex: Integer;
                              APrevState, ANewState: TcxCheckBoxState);
    procedure AgrupSubirClick(Sender: TObject);
    procedure AgrupBajarClick(Sender: TObject);
    // Soporte de la pestaña de familias en árbol (jerárquico, con cascada).
    procedure CrearTabFamiliasArbol;
    procedure CargarFamiliasArbol;
    procedure FamiliasSearchChange(Sender: TObject);
    // Resumen de selecciones: marcados de un filtro (con su nombre) y
    // niveles de agrupación en orden.
    procedure DescribirFiltro(
      AResumen: TResumenSeleccionesInforme;
      AFc: TFiltroChecklist);
    procedure DescribirFamilias(AResumen: TResumenSeleccionesInforme);
    procedure DescribirAgrupacion(AResumen: TResumenSeleccionesInforme);
  protected
    procedure CrearUIFiltros;
    procedure ValidarFechas;
    procedure AvisarAntesDeConsulta; override;
    // Los descendientes redefinen esto para elegir qué pestañas mostrar.
    function FiltrosUsados: TFiltrosReport; virtual;
    // SQL de proveedores. Los informes de documentos pueden usar otra fuente
    // sin alterar el filtro de proveedor de balances y movimientos.
    function OrigenProveedores:
      TOrigenProveedoresInformeMultiFiltro; virtual;
    procedure DoShow; override;
    // Fechas (si están habilitadas), filtros comunes y agrupación. Los
    // descendientes añaden después sus opciones propias.
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    // Helpers para checklists "planos" SIN buscador (p. ej. la pestaña de
    // bandas del balance, pequeña): se crea uno y se lee su selección.
    function CrearTabChecklist(const ACaption: string;
      const AAyuda: string = ''): TcxCheckListBox;
    function  SeleccionadosCSV(AClb: TcxCheckListBox): string;
    // Pestaña de agrupaciones: dimensiones (código + etiqueta) que se pueden
    // marcar y reordenar. AConNivelFamilia añade un spin de nivel de familia.
    // NivelesAgrupacion devuelve los códigos marcados en el orden elegido (el
    // primero = grupo más externo). NivelFamilia da el valor del spin (0 si
    // no).
    function  CrearTabAgrupacion(const ACaption: string;
                                 const ACods, AEtiqs: array of string;
                                 AConNivelFamilia: Boolean = False):
                                 TcxCheckListBox;
    function  NivelesAgrupacion: TArray<string>;
    function  NivelFamilia: Integer;
    // Para que el descendiente añada controles propios (modo/detalle) sobre
    // la pestaña de fechas o gestione su habilitado.
    property TabFechas: TcxTabSheet read FtsFechas;
    property DteDesde : TcxDateEdit read FdteDesde;
    property DteHasta : TcxDateEdit read FdteHasta;
  public
    destructor Destroy; override;
    function CSVAlmacenes  : string;
    function CSVFamilias   : string;
    function CSVProveedores: string;
    function CSVTemporadas : string;
    function CSVArticulos  : string;
    function FechaDesde    : TDateTime;
    function FechaHasta    : TDateTime;
    // La apertura del informe indica su opcion de menu antes de ShowModal.
    property NombreIconoMenu: string
      read FNombreIconoMenu write FNombreIconoMenu;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, inLibMsgComun, UniDataInformeMultiFiltroRepositorio,
  inLibMenuIconos;

const
  MAX_NIVELES_AGRUPACION = 3;

{ TFiltroChecklist }

constructor TFiltroChecklist.Create;
begin
  inherited Create;
  Fuente := TStringList.Create;
  Marcados := TStringList.Create;
  Marcados.Sorted := True;
  Marcados.Duplicates := dupIgnore;
end;

destructor TFiltroChecklist.Destroy;
begin
  Fuente.Free;
  Marcados.Free;
  inherited Destroy;
end;

{ TfrmPrintMultiFiltro }

destructor TfrmPrintMultiFiltro.Destroy;
begin
  // Libera los TFiltroChecklist (y sus TStringList). Los controles (clb/edt)
  // son propiedad del form y los libera el inherited.
  FreeAndNil(FFiltros);
  FreeAndNil(FAgrupItems);
  FreeAndNil(FGestorFamilias);
  inherited Destroy;
end;

function TfrmPrintMultiFiltro.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas];
end;

function TfrmPrintMultiFiltro.OrigenProveedores:
  TOrigenProveedoresInformeMultiFiltro;
begin
  Result := opmfArticulos;
end;

procedure TfrmPrintMultiFiltro.DoShow;
begin
  inherited;
  if not FFiltrosCreados then
  begin
    CrearUIFiltros;
    CargarFiltros;
    FFiltrosCreados := True;
  end;
end;

procedure TfrmPrintMultiFiltro.CrearUIFiltros;
var
  fs: TFiltrosReport;
begin
  FFiltros := TObjectList<TFiltroChecklist>.Create(True);
  fs := FiltrosUsados;
  FpcFiltros := TcxPageControl.Create(Self);
  FpcFiltros.Parent := Self;
  FpcFiltros.Align := alClient;
  if frFechas in fs then
    CrearTabFechas;
  if frAlmacenes in fs then
    FfcAlmacenes := CrearTabFiltro(SCaptionAlmacenesFiltroInforme);
  if frFamilias in fs then
    CrearTabFamiliasArbol;
  if frProveedores in fs then
    FfcProveedores := CrearTabFiltro(SCaptionProveedoresFiltroInforme);
  if frTemporadas in fs then
    FfcTemporadas := CrearTabFiltro(SCaptionTemporadasFiltroInforme);
  if frArticulos in fs then
    FfcArticulos := CrearTabFiltro(SCaptionArticulosFiltroInforme);
  CrearIconoInforme;
  if FpcFiltros.PageCount > 0 then
    FpcFiltros.ActivePageIndex := 0;
end;

procedure TfrmPrintMultiFiltro.CrearIconoInforme;
const
  TAMANO_ICONO_96_DPI = 48;
  POSICION_VERTICAL_96_DPI = 224;
var
  oIcono: TcxImage;
  iTamano: Integer;
  iIzquierda: Integer;
  iArriba: Integer;
begin
  if Assigned(FtsFechas) and (FNombreIconoMenu <> '') then
  begin
    iTamano := MulDiv(TAMANO_ICONO_96_DPI, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    iIzquierda := FdteHasta.Left + (FdteHasta.Width - iTamano) div 2;
    // Debajo de los filtros, dejando sitio a las opciones de cada informe.
    iArriba := MulDiv(POSICION_VERTICAL_96_DPI, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    oIcono := TcxImage.Create(Self);
    oIcono.Name := 'imgIconoInforme';
    oIcono.Visible := False;
    oIcono.Parent := FtsFechas;
    oIcono.SetBounds(iIzquierda, iArriba, iTamano, iTamano);
    oIcono.Properties.FitMode := ifmProportionalStretch;
    oIcono.Properties.PopupMenuLayout.MenuItems := [];
    oIcono.Properties.ReadOnly := True;
    oIcono.Properties.ShowFocusRect := False;
    oIcono.Style.BorderStyle := ebsNone;
    oIcono.StyleFocused.BorderStyle := ebsNone;
    oIcono.StyleHot.BorderStyle := ebsNone;
    oIcono.TabStop := False;
    oIcono.Transparent := True;
    oIcono.Visible := CargarIconoMenuMaximaResolucion(
      FNombreIconoMenu, oIcono.Picture);
  end;
end;

procedure TfrmPrintMultiFiltro.CrearTabFechas;
var
  lblD, lblH: TcxLabel;
begin
  FtsFechas := TcxTabSheet.Create(FpcFiltros);
  FtsFechas.PageControl := FpcFiltros;
  FtsFechas.Caption := SCaptionTabFechas;
  lblD := TcxLabel.Create(Self);
  lblD.Parent      := FtsFechas;
  lblD.Transparent := True;
  lblD.Caption     := SCaptionFechaInicio;
  lblD.Left := 16;
  lblD.Top  := 16;
  FdteDesde := TcxDateEdit.Create(Self);
  FdteDesde.Parent := FtsFechas;
  FdteDesde.Left  := 16;
  FdteDesde.Top   := 38;
  FdteDesde.Width := 160;
  lblH := TcxLabel.Create(Self);
  lblH.Parent      := FtsFechas;
  lblH.Transparent := True;
  lblH.Caption     := SCaptionFechaFin;
  lblH.Left := 16;
  lblH.Top  := 70;
  FdteHasta := TcxDateEdit.Create(Self);
  FdteHasta.Parent := FtsFechas;
  FdteHasta.Left  := 16;
  FdteHasta.Top   := 92;
  FdteHasta.Width := 160;
  ConfigurarFecha(FdteDesde);
  ConfigurarFecha(FdteHasta);
  FdteDesde.Date := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  FdteHasta.Date := Date;
end;

procedure TfrmPrintMultiFiltro.ConfigurarFecha(AEditor: TcxDateEdit);
begin
  // La máscara por secciones puede descartar o desplazar lo tecleado.
  // La fecha completa se sustituye como texto, conservando el calendario.
  AEditor.Properties.InputKind := ikStandard;
  AEditor.Properties.AutoSelect := True;
  AEditor.Properties.DateOnError := deNoChange;
  AEditor.Properties.SaveTime := False;
  AEditor.Properties.MinDate := EncodeDate(1900, 1, 1);
  AEditor.Properties.MaxDate := EncodeDate(9999, 12, 31);
  AEditor.Properties.OnValidate := ValidarTextoFecha;
  AEditor.OnMouseUp := SeleccionarFecha;
end;

procedure TfrmPrintMultiFiltro.ValidarTextoFecha(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sTexto: string;
  dFecha: TDateTime;
  iNumero: Integer;
  bValida: Boolean;
begin
  // Se comprueba el texto original: el editor puede normalizar días que
  // no existen antes de entregar DisplayValue a este evento.
  sTexto := Trim(TcxDateEdit(Sender).Text);
  if (Length(sTexto) = 8) and TryStrToInt(sTexto, iNumero) then
    bValida := TryEncodeDate(iNumero mod 10000,
      (iNumero div 10000) mod 100, iNumero div 1000000, dFecha)
  else
    bValida := TryStrToDate(sTexto, dFecha);
  Error := not bValida;
  if bValida then
    Error := (dFecha < EncodeDate(1900, 1, 1)) or
      (dFecha > EncodeDate(9999, 12, 31));
  ErrorText := SErrorFechaFiltroInformeNoValida;
  if not Error then
    DisplayValue := DateToStr(dFecha);
end;

procedure TfrmPrintMultiFiltro.SeleccionarFecha(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Se aplica también al segundo y tercer clic sobre un campo ya activo.
  if (Button = mbLeft) and (Shift = []) then
    TcxDateEdit(Sender).SelectAll;
end;

procedure TfrmPrintMultiFiltro.ValidarEditorFecha(AEditor: TcxDateEdit;
  const AMensajeVacio: string);
begin
  AEditor.ValidateEdit(True);
  AEditor.PostEditValue;
  if VarIsNull(AEditor.EditValue) or VarIsEmpty(AEditor.EditValue) then
  begin
    FpcFiltros.ActivePage := FtsFechas;
    AEditor.SetFocus;
    raise EcxEditValidationError.Create(AMensajeVacio);
  end;
end;

procedure TfrmPrintMultiFiltro.ValidarFechas;
begin
  // El balance por acumulados no aplica las fechas deshabilitadas.
  if Assigned(FdteDesde) and FdteDesde.Enabled and
     Assigned(FdteHasta) and FdteHasta.Enabled then
  begin
    ValidarEditorFecha(FdteDesde, SErrorFechaInicioDocumentoNoIndicada);
    ValidarEditorFecha(FdteHasta, SErrorFechaFinDocumentoNoIndicada);
    if FdteDesde.Date > FdteHasta.Date then
    begin
      FpcFiltros.ActivePage := FtsFechas;
      FdteDesde.SetFocus;
      raise EcxEditValidationError.Create(SErrorRangoFechasDocumentoNoValido);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.AvisarAntesDeConsulta;
begin
  ValidarFechas;
  inherited;
end;

// Pestaña de filtro con buscador (TcxTextEdit alTop) + checklist (alClient).
function TfrmPrintMultiFiltro.CrearTabFiltro(
  const ACaption: string): TFiltroChecklist;
var
  ts : TcxTabSheet;
  edt: TcxTextEdit;
  clb: TcxCheckListBox;
begin
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  edt := TcxTextEdit.Create(Self);
  edt.Parent := ts;
  edt.Align  := alTop;
  edt.Hint     := SHintEscribaIntroFiltrar;
  edt.ShowHint := True;
  // OnEditValueChanged (evento confirmado en cx): filtra al postear el texto
  // (Intro / salir del cuadro). Para filtrar en cada tecla habría que usar
  // Properties.OnChange si la versión lo expone.
  edt.Properties.OnEditValueChanged := SearchChange;
  clb := TcxCheckListBox.Create(Self);
  clb.Parent := ts;
  clb.Align  := alClient;
  // cvfStatesString: sin esto (cvfInteger) el checklist limita a 64 ítems.
  clb.EditValueFormat := cvfStatesString;
  clb.OnClickCheck := ClbFiltroClickCheck;
  Result := TFiltroChecklist.Create;
  Result.Clb := clb;
  Result.Edt := edt;
  Result.Titulo := ACaption;
  FFiltros.Add(Result);
end;

// Checklist "plano" sin buscador (para descendientes). Mantiene la etiqueta
// de ayuda y el cvfStatesString, pero no lleva fuente/marcados ni OnClickCheck:
// SeleccionadosCSV lee directamente el State de cada ítem.
function TfrmPrintMultiFiltro.CrearTabChecklist(const ACaption: string;
  const AAyuda: string): TcxCheckListBox;
var
  ts : TcxTabSheet;
  lbl: TcxLabel;
begin
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  lbl := TcxLabel.Create(Self);
  lbl.Parent      := ts;
  lbl.Align       := alTop;
  lbl.Transparent := True;
  if AAyuda <> '' then
    lbl.Caption := AAyuda
  else
    lbl.Caption := SCaptionMarqueValoresIncluir;
  Result := TcxCheckListBox.Create(Self);
  Result.Parent := ts;
  Result.Align  := alClient;
  Result.EditValueFormat := cvfStatesString;
end;

function TfrmPrintMultiFiltro.CodigoDeItem(const AText: string): string;
var
  p: Integer;
begin
  p := Pos(' - ', AText);
  if p > 0 then
    Result := Copy(AText, 1, p - 1)
  else
    Result := AText;
end;

procedure TfrmPrintMultiFiltro.CargarFiltro(AFc: TFiltroChecklist;
  const AOpciones: TOpcionesInformeMultiFiltro);
var
  i: Integer;
  sCod, sNom, sLinea: string;
begin
  if AFc <> nil then
  begin
    AFc.Fuente.Clear;
    AFc.Marcados.Clear;
    for i := 0 to Length(AOpciones) - 1 do
    begin
        sCod := AOpciones[i].Codigo;
        sNom := AOpciones[i].Nombre;
        if (sNom <> '') and (sNom <> sCod) then
          sLinea := sCod + ' - ' + sNom
        else
          sLinea := sCod;
        AFc.Fuente.Add(sLinea);
    end;
    RefiltrarChecklist(AFc);
  end;
end;

// Repuebla las filas visibles del checklist según el texto del buscador,
// remarcando las que estén en Marcados (las selecciones se conservan).
procedure TfrmPrintMultiFiltro.RefiltrarChecklist(AFc: TFiltroChecklist);
var
  i: Integer;
  sFil, sLinea: string;
  item: TcxCheckListBoxItem;
begin
  if AFc <> nil then
  begin
    sFil := LowerCase(Trim(AFc.Edt.Text));
    AFc.Clb.Items.BeginUpdate;
    try
      AFc.Clb.Items.Clear;
      for i := 0 to AFc.Fuente.Count - 1 do
      begin
        sLinea := AFc.Fuente[i];
        if (sFil = '') or (Pos(sFil, LowerCase(sLinea)) > 0) then
        begin
          item := AFc.Clb.Items.Add;
          item.Text := sLinea;
          if AFc.Marcados.IndexOf(CodigoDeItem(sLinea)) >= 0 then
            item.State := cbsChecked
          else
            item.State := cbsUnchecked;
        end;
      end;
    finally
      AFc.Clb.Items.EndUpdate;
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.CargarFiltros;
begin
  if FRepositorioFiltros = nil then
    FRepositorioFiltros := CrearRepositorioInformeMultiFiltroUniDAC(
      ConexionPrincipal);
  CargarFiltro(FfcAlmacenes, FRepositorioFiltros.ListarAlmacenes);
  // Familias va como árbol (jerarquía padre→subfamilias), no como checklist.
  CargarFamiliasArbol;
  CargarFiltro(FfcProveedores,
    FRepositorioFiltros.ListarProveedores(OrigenProveedores));
  // Temporada = valor de la propiedad de artículo 'TEMPORADA' (código=nombre).
  CargarFiltro(FfcTemporadas, FRepositorioFiltros.ListarTemporadas);
  // Artículos activos (código + descripción). La lista puede ser larga: el
  // buscador de la pestaña acota las filas visibles. Sin marcar nada = todos.
  CargarFiltro(FfcArticulos, FRepositorioFiltros.ListarArticulos);
end;

function TfrmPrintMultiFiltro.FiltroPorClb(AClb: TObject): TFiltroChecklist;
var
  i: Integer;
begin
  Result := nil;
  if FFiltros <> nil then
    for i := 0 to FFiltros.Count - 1 do
      if (Result = nil) and (FFiltros[i].Clb = AClb) then
        Result := FFiltros[i];
end;

function TfrmPrintMultiFiltro.FiltroPorEdt(AEdt: TObject): TFiltroChecklist;
var
  i: Integer;
begin
  Result := nil;
  if FFiltros <> nil then
    for i := 0 to FFiltros.Count - 1 do
      if (Result = nil) and (FFiltros[i].Edt = AEdt) then
        Result := FFiltros[i];
end;

// Al marcar/desmarcar un ítem, se actualiza el conjunto de códigos marcados
// (fuente de verdad para el CSV, independiente del filtro de búsqueda).
procedure TfrmPrintMultiFiltro.ClbFiltroClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
var
  fc : TFiltroChecklist;
  cod: string;
  idx: Integer;
begin
  fc := FiltroPorClb(Sender);
  if (fc <> nil) and (AIndex >= 0) and (AIndex < fc.Clb.Items.Count) then
  begin
    cod := CodigoDeItem(fc.Clb.Items[AIndex].Text);
    if ANewState = cbsChecked then
    begin
      if fc.Marcados.IndexOf(cod) < 0 then
        fc.Marcados.Add(cod);
    end
    else
    begin
      idx := fc.Marcados.IndexOf(cod);
      if idx >= 0 then
        fc.Marcados.Delete(idx);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.SearchChange(Sender: TObject);
var
  fc: TFiltroChecklist;
begin
  fc := FiltroPorEdt(Sender);
  if fc <> nil then
    RefiltrarChecklist(fc);
end;

function TfrmPrintMultiFiltro.CSVDe(AFc: TFiltroChecklist): string;
var
  i: Integer;
begin
  Result := '';
  if AFc <> nil then
    for i := 0 to AFc.Marcados.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + AFc.Marcados[i];
    end;
end;

// CSV de un checklist "plano" (sin Marcados): se lee el State de cada ítem.
function TfrmPrintMultiFiltro.SeleccionadosCSV(AClb: TcxCheckListBox): string;
var
  i: Integer;
begin
  Result := '';
  if AClb <> nil then
    for i := 0 to AClb.Items.Count - 1 do
      if AClb.Items[i].State = cbsChecked then
      begin
        if Result <> '' then
          Result := Result + ',';
        Result := Result + CodigoDeItem(AClb.Items[i].Text);
      end;
end;

// Crea la pestaña de agrupaciones: un checklist con las dimensiones (en el
// orden recibido) más botones Subir/Bajar para reordenarlas y, opcionalmente,
// un spin con el nivel de familia.
function TfrmPrintMultiFiltro.CrearTabAgrupacion(const ACaption: string;
  const ACods, AEtiqs: array of string;
  AConNivelFamilia: Boolean): TcxCheckListBox;
var
  ts      : TcxTabSheet;
  lbl     : TcxLabel;
  lblNivel: TcxLabel;
  pnl     : TPanel;
  btnSubir: TcxButton;
  btnBajar: TcxButton;
  i       : Integer;
  it      : TItemAgrup;
begin
  if FAgrupItems = nil then
    FAgrupItems := TObjectList<TItemAgrup>.Create(True);
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  FTituloAgrup := ACaption;
  lbl := TcxLabel.Create(Self);
  lbl.Parent      := ts;
  lbl.Align       := alTop;
  lbl.Transparent := True;
  lbl.AutoSize := False;
  lbl.Properties.WordWrap := True;
  lbl.Height := MulDiv(60, CurrentPPI, 96);
  lbl.Caption := SCaptionMarqueAgrupacion;
  lbl.Hint := lbl.Caption;
  lbl.ShowHint := True;
  pnl := TPanel.Create(Self);
  pnl.Parent     := ts;
  pnl.Align      := alRight;
  pnl.Width      := 100;
  pnl.BevelOuter := bvNone;
  btnSubir := TcxButton.Create(Self);
  btnSubir.Parent  := pnl;
  btnSubir.Left    := 10;
  btnSubir.Top     := 10;
  btnSubir.Width   := 80;
  btnSubir.Caption := SCaptionSubir;
  btnSubir.OnClick := AgrupSubirClick;
  btnBajar := TcxButton.Create(Self);
  btnBajar.Parent  := pnl;
  btnBajar.Left    := 10;
  btnBajar.Top     := 42;
  btnBajar.Width   := 80;
  btnBajar.Caption := SCaptionBajar;
  btnBajar.OnClick := AgrupBajarClick;
  if AConNivelFamilia then
  begin
    lblNivel := TcxLabel.Create(Self);
    lblNivel.Parent      := pnl;
    lblNivel.Transparent := True;
    lblNivel.Left        := 10;
    lblNivel.Top         := 86;
    lblNivel.Caption     := SCaptionNivelFamilia;
    FseNivelFam := TcxSpinEdit.Create(Self);
    FseNivelFam.Parent             := pnl;
    FseNivelFam.Left               := 10;
    FseNivelFam.Top                := 106;
    FseNivelFam.Width              := 80;
    FseNivelFam.Properties.MinValue := 0;
    FseNivelFam.Properties.MaxValue := 20;
    FseNivelFam.Value              := 1;
    FseNivelFam.Hint := SHintNivelFamilia;
    FseNivelFam.ShowHint := True;
  end;
  FclbAgrup := TcxCheckListBox.Create(Self);
  FclbAgrup.Parent         := ts;
  FclbAgrup.Align          := alClient;
  FclbAgrup.EditValueFormat := cvfStatesString;
  FclbAgrup.OnClickCheck   := AgrupClickCheck;
  for i := Low(ACods) to High(ACods) do
  begin
    it := TItemAgrup.Create;
    it.Codigo := ACods[i];
    if i <= High(AEtiqs) then
      it.Etiqueta := AEtiqs[i]
    else
      it.Etiqueta := ACods[i];
    it.Marcado := False;
    FAgrupItems.Add(it);
  end;
  AgrupRefrescar;
  Result := FclbAgrup;
end;

// Repinta el checklist desde FAgrupItems (orden + marcas), conservando la fila
// seleccionada para que Subir/Bajar sean cómodos.
procedure TfrmPrintMultiFiltro.AgrupRefrescar;
var
  i, sel: Integer;
  item  : TcxCheckListBoxItem;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    sel := FclbAgrup.ItemIndex;
    FclbAgrup.Items.BeginUpdate;
    try
      FclbAgrup.Items.Clear;
      for i := 0 to FAgrupItems.Count - 1 do
      begin
        item := FclbAgrup.Items.Add;
        item.Text := FAgrupItems[i].Etiqueta;
        if FAgrupItems[i].Marcado then
          item.State := cbsChecked
        else
          item.State := cbsUnchecked;
      end;
    finally
      FclbAgrup.Items.EndUpdate;
    end;
    if (sel >= 0) and (sel < FclbAgrup.Items.Count) then
      FclbAgrup.ItemIndex := sel;
  end;
end;

procedure TfrmPrintMultiFiltro.AgrupClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
var
  i: Integer;
  iMarcados: Integer;
begin
  if (FAgrupItems <> nil) and (AIndex >= 0)
     and (AIndex < FAgrupItems.Count) then
  begin
    if ANewState = cbsChecked then
    begin
      iMarcados := 0;
      for i := 0 to FAgrupItems.Count - 1 do
        if (i <> AIndex) and FAgrupItems[i].Marcado then
          Inc(iMarcados);
      if iMarcados >= MAX_NIVELES_AGRUPACION then
      begin
        FAgrupItems[AIndex].Marcado := False;
        if (FclbAgrup <> nil) and (AIndex < FclbAgrup.Items.Count) then
          FclbAgrup.Items[AIndex].State := cbsUnchecked;
      end
      else
        FAgrupItems[AIndex].Marcado := True;
    end;
    if ANewState <> cbsChecked then
      FAgrupItems[AIndex].Marcado := False;
  end;
end;

procedure TfrmPrintMultiFiltro.AgrupSubirClick(Sender: TObject);
var
  i: Integer;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    i := FclbAgrup.ItemIndex;
    if i > 0 then
    begin
      FAgrupItems.Exchange(i, i - 1);
      AgrupRefrescar;
      FclbAgrup.ItemIndex := i - 1;
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.AgrupBajarClick(Sender: TObject);
var
  i: Integer;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    i := FclbAgrup.ItemIndex;
    if (i >= 0) and (i < FAgrupItems.Count - 1) then
    begin
      FAgrupItems.Exchange(i, i + 1);
      AgrupRefrescar;
      FclbAgrup.ItemIndex := i + 1;
    end;
  end;
end;

// Códigos marcados en el orden elegido (el primero = grupo más externo).
function TfrmPrintMultiFiltro.NivelesAgrupacion: TArray<string>;
var
  i  : Integer;
  lst: TList<string>;
begin
  lst := TList<string>.Create;
  try
    if FAgrupItems <> nil then
      for i := 0 to FAgrupItems.Count - 1 do
        if FAgrupItems[i].Marcado then
          lst.Add(FAgrupItems[i].Codigo);
    Result := lst.ToArray;
  finally
    lst.Free;
  end;
end;

function TfrmPrintMultiFiltro.NivelFamilia: Integer;
begin
  if (FseNivelFam <> nil) and (not VarIsNull(FseNivelFam.Value)) then
    Result := FseNivelFam.Value
  else
    Result := 0;
end;

// ===========================================================================
//   Pestaña de familias como árbol jerárquico (no como lista plana)
// ===========================================================================

// Crea la pestaña "Familias" con un TcxTreeList no ligado (nombre +
// checkbox "Incluir" + código) y un buscador. El comportamiento (marca en
// cascada, filtro y CSV) lo lleva TArbolFamiliasVcl, compartido con el
// selector de familias de otras pantallas.
procedure TfrmPrintMultiFiltro.CrearTabFamiliasArbol;
var
  ts    : TcxTabSheet;
  pnlTop: TPanel;
  lbl   : TcxLabel;
begin
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := SCaptionTabFamilias;
  // Cabecera fija con la ayuda y el buscador (panel para fijar el orden).
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent     := ts;
  pnlTop.Align      := alTop;
  pnlTop.Height     := 58;
  pnlTop.BevelOuter := bvNone;
  lbl := TcxLabel.Create(Self);
  lbl.Parent      := pnlTop;
  lbl.Transparent := True;
  lbl.Left        := 4;
  lbl.Top         := 4;
  lbl.Caption     := SCaptionDobleClicMarcaFamilia;
  FedtFamilias := TcxTextEdit.Create(Self);
  FedtFamilias.Parent   := pnlTop;
  FedtFamilias.Left     := 4;
  FedtFamilias.Top      := 28;
  FedtFamilias.Width    := 420;
  FedtFamilias.Hint     := SHintBuscarFamilia;
  FedtFamilias.ShowHint := True;
  FedtFamilias.Properties.OnEditValueChanged := FamiliasSearchChange;
  FtlFamilias := TcxTreeList.Create(Self);
  FtlFamilias.Parent := ts;
  FtlFamilias.Align  := alClient;
  FGestorFamilias := TArbolFamiliasVcl.Create(
    FtlFamilias,
    SCaptionFamiliaFiltroInforme,
    SCaptionIncluirFiltroInforme,
    SCaptionCodigoFiltroInforme);
end;

// Carga las familias activas; el árbol respeta la jerarquía padre→hijo
// (CODIGO_PADRE_FAM).
procedure TfrmPrintMultiFiltro.CargarFamiliasArbol;
begin
  if FGestorFamilias <> nil then
  begin
    if FRepositorioFiltros = nil then
      FRepositorioFiltros := CrearRepositorioInformeMultiFiltroUniDAC(
        ConexionPrincipal);
    FGestorFamilias.Cargar(FRepositorioFiltros.ListarFamilias);
  end;
end;

procedure TfrmPrintMultiFiltro.FamiliasSearchChange(Sender: TObject);
begin
  if FGestorFamilias <> nil then
    FGestorFamilias.Filtrar(FedtFamilias.Text);
end;

procedure TfrmPrintMultiFiltro.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  // Deshabilitadas (p. ej. balance por acumulados) no se aplican.
  if (FdteDesde <> nil) and FdteDesde.Enabled then
    AResumen.AnadirRangoFechas(SCaptionTabFechas, FechaDesde, FechaHasta);
  DescribirFiltro(AResumen, FfcAlmacenes);
  DescribirFamilias(AResumen);
  DescribirFiltro(AResumen, FfcProveedores);
  DescribirFiltro(AResumen, FfcTemporadas);
  DescribirFiltro(AResumen, FfcArticulos);
  DescribirAgrupacion(AResumen);
end;

// Se listan los marcados aunque lo estén todos: la consulta filtra por
// esos códigos y deja fuera lo que no aparece en la lista.
procedure TfrmPrintMultiFiltro.DescribirFiltro(
  AResumen: TResumenSeleccionesInforme;
  AFc: TFiltroChecklist);
var
  i: Integer;
  oTextos: TStringList;
begin
  if AFc <> nil then
  begin
    oTextos := TStringList.Create;
    try
      for i := 0 to AFc.Fuente.Count - 1 do
        if AFc.Marcados.IndexOf(CodigoDeItem(AFc.Fuente[i])) >= 0 then
          oTextos.Add(AFc.Fuente[i]);
      AResumen.AnadirLista(AFc.Titulo, oTextos);
    finally
      FreeAndNil(oTextos);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.DescribirFamilias(
  AResumen: TResumenSeleccionesInforme);
var
  oCodigos: TStringList;
begin
  if FGestorFamilias <> nil then
  begin
    oCodigos := TStringList.Create;
    try
      oCodigos.StrictDelimiter := True;
      oCodigos.Delimiter := ',';
      oCodigos.DelimitedText := CSVFamilias;
      AResumen.AnadirLista(SCaptionTabFamilias, oCodigos);
    finally
      FreeAndNil(oCodigos);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.DescribirAgrupacion(
  AResumen: TResumenSeleccionesInforme);
var
  i: Integer;
  bFamilia: Boolean;
  sNiveles: string;
begin
  if FAgrupItems <> nil then
  begin
    sNiveles := '';
    bFamilia := False;
    for i := 0 to FAgrupItems.Count - 1 do
      if FAgrupItems[i].Marcado then
      begin
        if sNiveles <> '' then
          sNiveles := sNiveles + ' > ';
        sNiveles := sNiveles + FAgrupItems[i].Etiqueta;
        bFamilia := bFamilia or (FAgrupItems[i].Codigo = 'FAM');
      end;
    if sNiveles = '' then
      sNiveles := SResumenSeleccionesNinguna;
    AResumen.Anadir(FTituloAgrup, sNiveles);
    if bFamilia and (FseNivelFam <> nil) then
      AResumen.Anadir(SCaptionNivelFamilia, IntToStr(NivelFamilia));
  end;
end;

function TfrmPrintMultiFiltro.CSVAlmacenes: string;
begin
  Result := CSVDe(FfcAlmacenes);
end;

// CSV de las familias marcadas en el árbol (incluye las marcadas en
// cascada al marcar un padre). Recorre todos los nodos, no solo los
// visibles, para no perder selecciones ocultas por el buscador.
function TfrmPrintMultiFiltro.CSVFamilias: string;
begin
  if FGestorFamilias = nil then
    Result := ''
  else
    Result := FGestorFamilias.CsvMarcadas;
end;

function TfrmPrintMultiFiltro.CSVProveedores: string;
begin
  Result := CSVDe(FfcProveedores);
end;

function TfrmPrintMultiFiltro.CSVTemporadas: string;
begin
  Result := CSVDe(FfcTemporadas);
end;

function TfrmPrintMultiFiltro.CSVArticulos: string;
begin
  Result := CSVDe(FfcArticulos);
end;

function TfrmPrintMultiFiltro.FechaDesde: TDateTime;
begin
  ValidarFechas;
  if FdteDesde <> nil then
    Result := FdteDesde.Date
  else
    Result := Date;
end;

function TfrmPrintMultiFiltro.FechaHasta: TDateTime;
begin
  ValidarFechas;
  if FdteHasta <> nil then
    Result := FdteHasta.Date
  else
    Result := Date;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpOperacionesVenta                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.2.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Listado de operaciones de venta del TPV, agrupado por fecha y caja.       }
{    Detalla artículos, variantes, importes, vendedor y formas de pago.        }
{******************************************************************************}
unit inMtoModalImpOperacionesVenta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtonEdit,
  cxCalendar, cxLabel, cxButtons, cxClasses, cxLocalization, cxPC,
  cxCheckListBox, cxCheckBox, dxSkinsForm, dxCore, frxClass, frxDBSet,
  frxDesgn, frxExportXLSX,
  frxExportBaseDialog, frxExportPDF, frxSmartMemo, frLocalization,
  frLanguageSpanish, frxExportBaseImageSettingsDialog, frCoreClasses,
  JvComponentBase, JvEnterTab, Vcl.Menus, System.Actions, Vcl.ActnList,
  inLibInformesCajaPersistenciaIntf, inLibCajaPantallaInyeccion,
  inLibResumenSeleccionesInforme, inLibInformeTabular,
  inLibBalanceCantidades;

type
  TfrmPrintOperacionesVenta = class(TfrmPrint)
    pcOpciones: TcxPageControl;
    tsUbicaciones: TcxTabSheet;
    tsFiltros: TcxTabSheet;
    lblFiltroTalla: TcxLabel;
    lblFiltroColor: TcxLabel;
    lblFiltroCopa: TcxLabel;
    lblNombreAtributo: TcxLabel;
    lblValorAtributo: TcxLabel;
    lblCodigoArqueo: TcxLabel;
    lblFiltrosOpcionales: TcxLabel;
    edtFiltroTalla: TcxButtonEdit;
    edtFiltroColor: TcxButtonEdit;
    edtFiltroCopa: TcxButtonEdit;
    edtNombreAtributo: TcxButtonEdit;
    edtValorAtributo: TcxButtonEdit;
    edtCodigoArqueo: TcxButtonEdit;
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblContexto: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    edtAlmacen: TcxTextEdit;
    lblCaja: TcxLabel;
    edtCaja: TcxTextEdit;
    lblUbicaciones: TcxLabel;
    clbUbicaciones: TcxCheckListBox;
    btnMarcarTodas: TcxButton;
    btnDesmarcarTodas: TcxButton;
    dsVentasPrint: TDataSource;
    fxdsVentas: TfrxDBDataset;
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure BuscarFiltroButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure btnDesmarcarTodasClick(Sender: TObject);
    procedure EjecutarAccionInforme(Sender: TObject);
    procedure clbUbicacionesMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FAlmacenesUbicacion: TStringList;
    FCajasUbicacion: TStringList;
    FEmpresasUbicacion: TStringList;
    FInicializado: Boolean;
    FInformeEnCurso: Boolean;
    FRestringido: Boolean;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    FDatos: TDataSet;
    FIndiceCantidades: TIndiceCantidadesBalance;
    FFechaGrupoCantidad: string;
    FCajaGrupoCantidad: string;
    FVendedorGrupoCantidad: string;
    // Títulos de las columnas de los dos ejes cuando hay variaciones que
    // los llaman de otra forma («Color / Aroma»); vacío = el del formato.
    FRotuloEjeColor: string;
    FRotuloEjeTalla: string;
    FRotuloEjeCopa: string;
    procedure AlternarUbicacion(AIndice: Integer);
    procedure AmpliarCabeceraParaDosLineas;
    procedure RecortarTextosDetalle;
    procedure AjustarDescuentoSubtotales;
    procedure AnadirColumnaHora;
    function FocoEnUbicaciones: Boolean;
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure ExportarExcelDatos;
    procedure ComponerDependencias;
    function ElegirOpcionFiltro(AFiltro: TFiltroOperacionesVentaCaja;
      const ATitulo: string; out AValor: string): Boolean;
    procedure IniciarDocumentoOperacionesVenta(Sender: TObject);
    procedure AsegurarUbicacionSeleccionada;
    procedure CargarUbicaciones;
    function ConstruirSolicitud:
      TSolicitudOperacionesVentaCaja;
    function HexAColor(const AHex: string; out AColor: TColor): Boolean;
    function NumeroUbicacionesMarcadas: Integer;
  protected
    procedure DoShow; override;
    procedure EjecutarInforme(Sender: TObject); virtual;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    procedure ReportBeforePrintConColor(
      Component: TfrxReportComponent);
  public
    procedure PrepararCantidadesInforme(ADatos: TDataSet);
    class function ColumnasExcel: TColumnasInformeTabular; static;
    class procedure AjustarTextosDetalle(AInforme: TfrxReport;
      const ANombreDatos: string); static;
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioInformesCaja); reintroduce;
      overload;
    function CloseQuery: Boolean; override;
    procedure AfterReportLoaded; override;
    procedure preparar_consulta; override;
    destructor Destroy; override;
  end;

implementation

uses
  inLibFiltroUsuario, inLibMsgCaja, inLibResumenSeleccionesCaja,
  frBaseGraphicsTypes, UniDataColumnasDocumentoRepositorio,
  inMtoPreviewExcel, inLibInformeTabularExcel, inLibMsgComun,
  inLibMensajesVcl;

{$R *.dfm}

resourcestring
  STituloHoraOperacion = 'Hora';
  STituloBuscarFiltroVentas = 'Buscar %s';
  SColumnaDescripcionFiltroVentas = 'Descripción';
  SColumnaCodigoArqueoFiltroVentas = 'Código de arqueo';
  SAvisoSinOpcionesFiltroVentas = 'No hay valores disponibles para este filtro.';
  SAvisoAtributoInformeIncompleto =
    'Indique el nombre y el valor del atributo para aplicar ese filtro.';

const
  // Títulos de los dos ejes en el formato del informe.
  TITULO_EJE_COLOR = 'Color';
  TITULO_EJE_TALLA = 'Talla';

{ TfrmPrintOperacionesVenta }

procedure TfrmPrintOperacionesVenta.EjecutarAccionInforme(Sender: TObject);
begin
  // FastReport atiende mensajes durante PrepareReport. Una segunda
  // ejecución no debe reemplazar su dataset ni limpiar sus guías.
  if not FInformeEnCurso then
  begin
    FInformeEnCurso := True;
    pnl1.Enabled := False;
    pcOpciones.Enabled := False;
    try
      EjecutarInforme(Sender);
    finally
      pcOpciones.Enabled := True;
      pnl1.Enabled := True;
      FInformeEnCurso := False;
    end;
  end;
end;

procedure TfrmPrintOperacionesVenta.EjecutarInforme(Sender: TObject);
begin
  if Sender = btnVistaPreliminar then
    inherited btnVistaPreliminarClick(Sender)
  else if Sender = btnPDF then
    inherited btnPDFClick(Sender)
  else if Sender = btnImprimir then
    inherited btnImprimirClick(Sender)
  else if Sender = btnExcel then
    ExportarExcelDatos
  else if Sender = btnEditar then
    inherited btnEditarClick(Sender);
end;

class function TfrmPrintOperacionesVenta.ColumnasExcel:
  TColumnasInformeTabular;
begin
  Result := [
    ColumnaInforme('FECHA_DIA', STextoFechaCaja, 1),
    ColumnaInforme('HORA_OPERACION', STituloHoraOperacion, 0.65),
    ColumnaInforme('CODIGO_EMP_OPCAJA', STextoEmpresaCaja, 0.6),
    ColumnaInforme('CODIGO_ALM_OPCAJA', STextoAlmacenCaja, 0.6),
    ColumnaInforme('CODIGO_CAJA_OPCAJA', STextoCajaCaja, 0.5),
    ColumnaInforme('NUMERO_OPERACION_OPCAJA', STextoOperacionCaja, 0.9),
    ColumnaInforme('DOCUMENTO', STextoDocumentoCaja, 1.6),
    ColumnaInforme('LINEA_FACLIN', STextoLineaCaja, 0.5),
    ColumnaInforme('ARTICULO', STextoArticuloCaja, 1),
    ColumnaInforme('COLOR', STextoColorAromaCaja, 1),
    ColumnaInforme('COPA', STextoCopaCaja, 0.5),
    ColumnaInforme('TALLA', STextoTallaMedidaCaja, 0.8),
    ColumnaInforme('PROVEEDOR', STextoProveedorCaja, 0.8),
    ColumnaInforme('MODELO', STextoModeloCaja, 1),
    ColumnaInforme('DESCRIPCION', STextoDescripcionCaja, 2),
    ColumnaInforme('CANTIDAD', STextoCantidadCaja, 0.7, '%g'),
    ColumnaInforme('BRUTO', STextoBrutoCaja, 0.8, '%2.2n'),
    ColumnaInforme('PORCENTAJE_DTO', STextoDescuentoCaja, 0.7, '%g'),
    ColumnaInforme('NETO_ARTICULO', STextoNetoArticuloCaja, 0.8, '%2.2n'),
    ColumnaInforme('INGRESOS', STextoIngresosCaja, 0.8, '%2.2n'),
    ColumnaInforme('VENDEDOR', STextoVendedorCaja, 0.8),
    ColumnaInforme('FORMA_PAGO', STextoFormaDePagoCaja, 1)];
end;

procedure TfrmPrintOperacionesVenta.ExportarExcelDatos;
var
  Preview: TfrmMtoPreviewExcel;
  CursorAnterior: TCursor;
begin
  // FZ-ISSUE-872: exportar lineas, nunca bandas ni subtotales de impresion.
  Preview := nil;
  CursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    IniciarEspera(SCaptionEsperaConsultandoDatosInforme);
    IniciarMedicionDatos;
    preparar_consulta;
    PausarMedicionDatos;
    Preview := TfrmMtoPreviewExcel.Create(Self);
    Preview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    Preview.DialogoGuardar.FileName := 'Operaciones_venta.xlsx';
    ExportarInformeTabularExcel(Preview.dxSpreadSheet1, FDatos,
      Caption, ColumnasExcel, LineasResumenSelecciones);
    TerminarEspera;
    Preview.ShowModal;
  finally
    TerminarEspera;
    Preview.Free;
    Screen.Cursor := CursorAnterior;
  end;
end;

function TfrmPrintOperacionesVenta.CloseQuery: Boolean;
begin
  Result := not FInformeEnCurso;
  if Result then
    Result := inherited CloseQuery;
end;

function TfrmPrintOperacionesVenta.FocoEnUbicaciones: Boolean;
var
  Control: TWinControl;
begin
  Control := ActiveControl;
  Result := Assigned(clbUbicaciones) and Assigned(Control) and
    ((Control = clbUbicaciones) or
     clbUbicaciones.ContainsControl(Control));
end;

procedure TfrmPrintOperacionesVenta.AlternarUbicacion(AIndice: Integer);
begin
  if not FInformeEnCurso and clbUbicaciones.Enabled and
     not clbUbicaciones.ReadOnly and
     (AIndice >= 0) and (AIndice < clbUbicaciones.Items.Count) and
     clbUbicaciones.Items[AIndice].Enabled then
  begin
    if clbUbicaciones.Items[AIndice].State = cbsChecked then
      clbUbicaciones.Items[AIndice].State := cbsUnchecked
    else
      clbUbicaciones.Items[AIndice].State := cbsChecked;
  end;
end;

procedure TfrmPrintOperacionesVenta.CMDialogKey(var Msg: TCMDialogKey);
begin
  // La lista conserva Espacio/Intro; no llegan al botón por defecto.
  if FocoEnUbicaciones and
     (Msg.CharCode in [VK_SPACE, VK_RETURN]) then
  begin
    AlternarUbicacion(clbUbicaciones.ItemIndex);
    Msg.Result := 1;
  end
  else
    inherited;
end;

procedure TfrmPrintOperacionesVenta.clbUbicacionesMouseUp(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  // La casilla conserva el manejo nativo; el texto también selecciona.
  if (Button = mbLeft) and
     (clbUbicaciones.CheckAtPos(Point(X, Y)) < 0) then
    AlternarUbicacion(clbUbicaciones.ItemAtPos(Point(X, Y), True));
end;

constructor TfrmPrintOperacionesVenta.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioInformesCaja);
begin
  ValidarDependenciaCaja(ARepositorio, 'informes de Caja');
  FRepositorioPersistencia := ARepositorio;
  inherited Create(AOwner);
end;

procedure TfrmPrintOperacionesVenta.AsegurarUbicacionSeleccionada;
var
  i: Integer;
begin
  if not FRestringido then
  begin
    if NumeroUbicacionesMarcadas = 0 then
    begin
      for i := 0 to clbUbicaciones.Items.Count - 1 do
      begin
        if SameText(
             FEmpresasUbicacion[i],
             UbicacionSesion.Empresa) and
           SameText(
             FAlmacenesUbicacion[i],
             UbicacionSesion.Almacen) and
           SameText(
             FCajasUbicacion[i],
             UbicacionSesion.Caja) then
          clbUbicaciones.Items[i].State := cbsChecked;
      end;
    end;
    if (NumeroUbicacionesMarcadas = 0) and
       (clbUbicaciones.Items.Count > 0) then
      clbUbicaciones.Items[0].State := cbsChecked;
  end;
end;

procedure TfrmPrintOperacionesVenta.AfterReportLoaded;
begin
  inherited;
  // FZ-ISSUE-439: solo se cambia el título si alguna variación activa
  // nombra el eje de otra manera; si no, vale el del formato (traducido).
  FRotuloEjeColor := RotuloGlobalEje(ConexionPrincipal, 'F', '');
  if SameText(FRotuloEjeColor, TITULO_EJE_COLOR) then
    FRotuloEjeColor := '';
  FRotuloEjeCopa := RotuloGlobalEje(ConexionPrincipal, 'S', 'Copa');
  FRotuloEjeTalla := RotuloGlobalEje(ConexionPrincipal, 'P', '');
  if SameText(FRotuloEjeTalla, TITULO_EJE_TALLA) then
    FRotuloEjeTalla := '';
  if (FRotuloEjeColor <> '') or (FRotuloEjeTalla <> '') then
    AmpliarCabeceraParaDosLineas;
  if FRotuloEjeColor <> '' then
    lblFiltroColor.Caption := FRotuloEjeColor;
  if FRotuloEjeTalla <> '' then
    lblFiltroTalla.Caption := FRotuloEjeTalla;
  lblFiltroCopa.Caption := FRotuloEjeCopa;
  AnadirColumnaHora;
  RecortarTextosDetalle;
  AjustarDescuentoSubtotales;
  frxrprt1.OnBeginDoc := IniciarDocumentoOperacionesVenta;
  frxrprt1.OnBeforePrint := ReportBeforePrintConColor;
end;

procedure TfrmPrintOperacionesVenta.AnadirColumnaHora;
const
  ANCHO_HORA = 40;
  ANCHO_MIN_DOCUMENTO = 82;

  procedure AgregarMemo(const ANombreDocumento, ANombreHora,
    ATexto: string);
  var
    Objeto: TfrxComponent;
    Documento, Hora: TfrxMemoView;
  begin
    Objeto := frxrprt1.FindObject(ANombreDocumento);
    if not (Objeto is TfrxMemoView) or
       Assigned(frxrprt1.FindObject(ANombreHora)) then
      Exit;
    Documento := TfrxMemoView(Objeto);
    if Documento.Width < ANCHO_MIN_DOCUMENTO + ANCHO_HORA then
      Exit;
    Documento.Width := Documento.Width - ANCHO_HORA;
    Hora := TfrxMemoView.Create(Documento.Parent);
    Hora.Name := ANombreHora;
    Hora.Left := Documento.Left + Documento.Width;
    Hora.Top := Documento.Top;
    Hora.Width := ANCHO_HORA;
    Hora.Height := Documento.Height;
    Hora.ParentFont := False;
    Hora.Font.Assign(Documento.Font);
    Hora.Frame.Typ := Documento.Frame.Typ;
    Hora.HAlign := haCenter;
    Hora.VAlign := Documento.VAlign;
    Hora.WordWrap := False;
    Hora.Text := ATexto;
  end;

begin
  AgregarMemo('MemoHDocumento', 'MemoHHoraOperacion', STituloHoraOperacion);
  AgregarMemo('MemoDocumento', 'MemoHoraOperacion',
    '[' + fxdsVentas.UserName + '."HORA_OPERACION"]');
end;

procedure TfrmPrintOperacionesVenta.AjustarDescuentoSubtotales;
const
  MEMOS_DESCUENTO: array[0..2] of string = (
    'MemoTotalVendedorDto', 'MemoTotalCajaDto', 'MemoTotalFechaDto');
  BRUTO = 'SUM(IIF(<Ventas."ES_PRESTAMO"> = 1, 0, ' +
    '<Ventas."BRUTO">),MasterData1)';
  NETO = 'SUM(IIF(<Ventas."ES_PRESTAMO"> = 1, 0, ' +
    '<Ventas."NETO_ARTICULO">),MasterData1)';
  FORMULA_ANTERIOR = '[IIF(' + BRUTO + ' = 0, 0, (' + BRUTO +
    ' - ' + NETO + ') * 100 / ' + BRUTO + ')]';
  LINEAS_VENTA = 'SUM(IIF(<Ventas."ES_PRESTAMO"> = 1, 0, 1),MasterData1)';
  DESCUENTO_LINEA = 'SUM(IIF(<Ventas."ES_PRESTAMO"> = 1, 0, ' +
    '<Ventas."PORCENTAJE_DTO">),MasterData1)';
  FORMULA_NUEVA = '[IIF(' + LINEAS_VENTA + ' = 1, ' + DESCUENTO_LINEA +
    ', (' + BRUTO + ' - ' + NETO + ') * 100 * IIF(' + BRUTO +
    ' = 0, 0, 1) / IIF(' + BRUTO + ' = 0, 1, ' + BRUTO + '))]';
var
  Nombre: string;
  Objeto: TfrxComponent;
  Memo: TfrxMemoView;
  Expresion: string;
begin
  // FZ-ISSUE-1141: conservar el descuento de la línea cuando es la única.
  // Actualizar también los formatos guardados que usan la fórmula estándar.
  for Nombre in MEMOS_DESCUENTO do
  begin
    Objeto := frxrprt1.FindObject(Nombre);
    if Objeto is TfrxMemoView then
    begin
      Memo := TfrxMemoView(Objeto);
      Expresion := StringReplace(Memo.Text, #13, '', [rfReplaceAll]);
      Expresion := StringReplace(Expresion, #10, '', [rfReplaceAll]);
      if SameText(Trim(Expresion), FORMULA_ANTERIOR) then
        Memo.Text := FORMULA_NUEVA;
    end;
  end;
end;

procedure TfrmPrintOperacionesVenta.IniciarDocumentoOperacionesVenta(
  Sender: TObject);

  procedure AplicarFecha(const ANombreMemo, ACampo, AVariable: string;
    const AFecha: TDateTime);
  var
    Objeto: TfrxComponent;
    Memo: TfrxMemoView;
  begin
    Objeto := frxrprt1.FindObject(ANombreMemo);
    if Objeto is TfrxMemoView then
    begin
      Memo := TfrxMemoView(Objeto);
      frxrprt1.Variables[AVariable] := AFecha;
      Memo.Text := StringReplace(Memo.Text,
        '<' + fxdsVentas.UserName + '."' + ACampo + '">', '<' + AVariable + '>',
        [rfReplaceAll, rfIgnoreCase]);
    end;
  end;

begin
  ReportInicioDocumento(Sender);
  // Adaptar la cabecera después de traducirla, también en formatos guardados.
  AplicarFecha('MemoDesde', 'FECHA_DESDE', 'FechaDesdeSeleccionada',
    DateOf(dteDesde.Date));
  AplicarFecha('MemoHasta', 'FECHA_HASTA', 'FechaHastaSeleccionada',
    DateOf(dteHasta.Date));
end;

// FZ-ISSUE-641: un texto que no cabe en su columna («AMARILLO») saltaba a
// un segundo renglón que se montaba sobre la línea siguiente. Las columnas
// de texto del detalle van en un solo renglón y recortan lo que sobra.
// Se aplica también a los formatos guardados con el salto activado.
procedure TfrmPrintOperacionesVenta.RecortarTextosDetalle;
begin
  AjustarTextosDetalle(frxrprt1, fxdsVentas.UserName);
end;

class procedure TfrmPrintOperacionesVenta.AjustarTextosDetalle(
  AInforme: TfrxReport; const ANombreDatos: string);
const
  MEMOS_TEXTO: array[0..9] of string = (
    'MemoArticulo', 'MemoColor', 'MemoTalla', 'MemoCopa', 'MemoProveedor',
    'MemoModelo', 'MemoDescripcion', 'MemoVendedor', 'MemoFormaPago',
    'MemoDocumento');
var
  sNombre: string;
  oObjeto: TfrxComponent;
  iObjeto: Integer;
  oMemo: TfrxMemoView;

  procedure AmpliarColor(const ANombreColor, ANombreDescripcion: string);
  var
    Color, Descripcion, Celda: TfrxMemoView;
    Objeto: TfrxComponent;
    Delta, InicioDescripcion, FinColor: Extended;
    I: Integer;
  begin
    Objeto := AInforme.FindObject(ANombreColor);
    if Objeto is TfrxMemoView then
    begin
      Color := TfrxMemoView(Objeto);
      Objeto := AInforme.FindObject(ANombreDescripcion);
      if Objeto is TfrxMemoView then
      begin
        Descripcion := TfrxMemoView(Objeto);
        Delta := 52 - Color.Width;
        if (Delta > 0) and (Descripcion.Width - Delta >= 80) and
          (Color.Parent = Descripcion.Parent) then
        begin
          InicioDescripcion := Descripcion.Left;
          FinColor := Color.Left + Color.Width;
          for I := 0 to Color.Parent.Objects.Count - 1 do
            if TObject(Color.Parent.Objects[I]) is TfrxMemoView then
            begin
              Celda := TfrxMemoView(Color.Parent.Objects[I]);
              if (Celda.Left >= FinColor - 0.01) and
                (Celda.Left <= InicioDescripcion + 0.01) then
                Celda.Left := Celda.Left + Delta;
            end;
          Descripcion.Width := Descripcion.Width - Delta;
          Color.Width := 52;
        end;
      end;
    end;
  end;

begin
  AmpliarColor('MemoColor', 'MemoDescripcion');
  AmpliarColor('MemoHColor', 'MemoHDescripcion');
  for sNombre in MEMOS_TEXTO do
  begin
    oObjeto := AInforme.FindObject(sNombre);
    if oObjeto is TfrxMemoView then
    begin
      TfrxMemoView(oObjeto).WordWrap := False;
      TfrxMemoView(oObjeto).Clipped := True;
    end;
  end;
  // FZ-ISSUE-641: las celdas de detalle ocupan una sola línea,
  // también cuando el formato se carga desde la BBDD.
  for iObjeto := 0 to AInforme.AllObjects.Count - 1 do
    if TObject(AInforme.AllObjects[iObjeto]) is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(AInforme.AllObjects[iObjeto]);
      if (oMemo.Parent is TfrxMasterData) and
         SameText(oMemo.DataSetName, ANombreDatos) then
      begin
        oMemo.WordWrap := False;
        oMemo.Clipped := True;
      end;
    end;
  // El color se muestra completo; la banda crece con sus renglones.
  // Mantener WordWrap sin estirar la banda provocaba la regresión 641.
  oObjeto := AInforme.FindObject('MemoColor');
  if oObjeto is TfrxMemoView then
  begin
    oMemo := TfrxMemoView(oObjeto);
    oMemo.WordWrap := True;
    oMemo.StretchMode := smActualHeight;
    if oMemo.Parent is TfrxBand then
      TfrxBand(oMemo.Parent).Stretched := True;
  end;
end;

// FZ-ISSUE-450: «Color / Aroma» y «Talla / Medida» no caben en una línea
// y la segunda quedaba cortada por la raya. La cabecera de columnas gana
// la altura de una línea más; los títulos de una sola línea se apoyan
// abajo, junto a la raya, como estaban. La marca en Tag evita crecer dos
// veces si el formato no se vuelve a cargar.
procedure TfrmPrintOperacionesVenta.AmpliarCabeceraParaDosLineas;
const
  ALTURA_LINEA_TITULO = 10;
  CABECERA_AMPLIADA = 450;
var
  iObjeto: Integer;
  oBanda: TfrxBand;
  oMemo: TfrxMemoView;
  oTitulo: TfrxComponent;
begin
  oTitulo := frxrprt1.FindObject('MemoHColor');
  if (oTitulo <> nil) and (oTitulo.Parent is TfrxBand) then
  begin
    oBanda := TfrxBand(oTitulo.Parent);
    if oBanda.Tag <> CABECERA_AMPLIADA then
    begin
      oBanda.Tag := CABECERA_AMPLIADA;
      oBanda.Height := oBanda.Height + ALTURA_LINEA_TITULO;
      for iObjeto := 0 to oBanda.Objects.Count - 1 do
      begin
        if TObject(oBanda.Objects[iObjeto]) is TfrxMemoView then
        begin
          oMemo := TfrxMemoView(oBanda.Objects[iObjeto]);
          oMemo.Height := oMemo.Height + ALTURA_LINEA_TITULO;
          oMemo.VAlign := frBaseGraphicsTypes.vaBottom;
          oMemo.WordWrap := True;
        end;
      end;
    end;
  end;
end;

function TfrmPrintOperacionesVenta.ElegirOpcionFiltro(
  AFiltro: TFiltroOperacionesVentaCaja; const ATitulo: string;
  out AValor: string): Boolean;
const
  NOMBRES_BUSQUEDA: array[TFiltroOperacionesVentaCaja] of string = (
    'OperacionesVentaBuscarTalla', 'OperacionesVentaBuscarColor',
    'OperacionesVentaBuscarCopa', 'OperacionesVentaBuscarAtributo',
    'OperacionesVentaBuscarValor', 'OperacionesVentaBuscarTurno'
  );
var
  Opciones: IResultadoInformeCaja;
  Datos: TDataSet;
  Campo: TField;
begin
  Opciones := FRepositorioPersistencia.ConsultarOpcionesFiltroOperacionesVenta(
    AFiltro, ConstruirSolicitud);
  Datos := Opciones.DataSet;
  Result := False;
  if Datos.IsEmpty then
    ShowMessage_fza(SAvisoSinOpcionesFiltroVentas)
  else
  begin
    Campo := Datos.FieldByName('VALOR');
    Campo.DisplayLabel := ATitulo;
    Campo.DisplayWidth := 22;
    if AFiltro = fovTurno then
    begin
      Campo.DisplayLabel := SColumnaCodigoArqueoFiltroVentas;
      Datos.FieldByName('EMPRESA').DisplayLabel := STextoEmpresaCaja;
      Datos.FieldByName('ALMACEN').DisplayLabel := STextoAlmacenCaja;
      Datos.FieldByName('CAJA').DisplayLabel := STextoCajaCaja;
      Datos.FieldByName('DESDE').DisplayLabel := lblDesde.Caption;
      Datos.FieldByName('HASTA').DisplayLabel := lblHasta.Caption;
    end;
    Campo := Datos.FindField('DESCRIPCION');
    if Assigned(Campo) then
    begin
      Campo.DisplayLabel := SColumnaDescripcionFiltroVentas;
      Campo.DisplayWidth := 32;
    end;
    Result := BusquedaVisual.EjecutarBusquedaDataSet(
      Format(STituloBuscarFiltroVentas, [ATitulo]), Datos,
      NOMBRES_BUSQUEDA[AFiltro], Self);
    if Result then
      AValor := Datos.FieldByName('VALOR').AsString;
  end;
end;

procedure TfrmPrintOperacionesVenta.BuscarFiltroButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Etiquetas: array[TFiltroOperacionesVentaCaja] of TcxLabel;
  Editor: TcxButtonEdit;
  Filtro: TFiltroOperacionesVentaCaja;
  Valor: string;
begin
  Editor := TcxButtonEdit(Sender);
  Filtro := TFiltroOperacionesVentaCaja(Editor.Tag);
  Etiquetas[fovTalla] := lblFiltroTalla;
  Etiquetas[fovColor] := lblFiltroColor;
  Etiquetas[fovCopa] := lblFiltroCopa;
  Etiquetas[fovAtributo] := lblNombreAtributo;
  Etiquetas[fovValorAtributo] := lblValorAtributo;
  Etiquetas[fovTurno] := lblCodigoArqueo;
  if (Filtro = fovValorAtributo) and (Trim(edtNombreAtributo.Text) = '') then
    BuscarFiltroButtonClick(edtNombreAtributo, 0);
  if (Filtro <> fovValorAtributo) or (Trim(edtNombreAtributo.Text) <> '') then
    if ElegirOpcionFiltro(Filtro, Etiquetas[Filtro].Caption, Valor) then
    begin
      if (Filtro = fovAtributo) and
         not SameText(Trim(Editor.Text), Valor) then
        edtValorAtributo.Text := '';
      Editor.Text := Valor;
    end;
end;

procedure TfrmPrintOperacionesVenta.btnDesmarcarTodasClick(
  Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsUnchecked;
end;

procedure TfrmPrintOperacionesVenta.btnMarcarTodasClick(Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsChecked;
end;

procedure TfrmPrintOperacionesVenta.CargarUbicaciones;
var
  Ubicaciones: TUbicacionesInformeCaja;
  Ubicacion: TUbicacionInformeCaja;
  item: TcxCheckListBoxItem;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
begin
  if FEmpresasUbicacion = nil then
    FEmpresasUbicacion := TStringList.Create;
  if FAlmacenesUbicacion = nil then
    FAlmacenesUbicacion := TStringList.Create;
  if FCajasUbicacion = nil then
    FCajasUbicacion := TStringList.Create;
  clbUbicaciones.Items.BeginUpdate;
  try
    clbUbicaciones.Items.Clear;
    FEmpresasUbicacion.Clear;
    FAlmacenesUbicacion.Clear;
    FCajasUbicacion.Clear;
    Ubicaciones := FRepositorioPersistencia.ListarUbicaciones;
    for Ubicacion in Ubicaciones do
    begin
      sEmpresa := Ubicacion.Empresa;
      sAlmacen := Ubicacion.Almacen;
      sCaja := Ubicacion.Caja;
      item := clbUbicaciones.Items.Add;
      item.Text := Format(
        '%s - %s  |  %s - %s  |  %s - %s',
        [sEmpresa, Ubicacion.NombreEmpresa,
         sAlmacen, Ubicacion.NombreAlmacen,
         sCaja, Ubicacion.NombreCaja]);
      item.State := cbsUnchecked;
      if SameText(sEmpresa, UbicacionSesion.Empresa) and
         SameText(sAlmacen, UbicacionSesion.Almacen) and
         SameText(sCaja, UbicacionSesion.Caja) then
      begin
        item.State := cbsChecked;
      end;
      FEmpresasUbicacion.Add(sEmpresa);
      FAlmacenesUbicacion.Add(sAlmacen);
      FCajasUbicacion.Add(sCaja);
    end;
  finally
    clbUbicaciones.Items.EndUpdate;
  end;
  AsegurarUbicacionSeleccionada;
end;

destructor TfrmPrintOperacionesVenta.Destroy;
begin
  FreeAndNil(FIndiceCantidades);
  FreeAndNil(FEmpresasUbicacion);
  FreeAndNil(FAlmacenesUbicacion);
  FreeAndNil(FCajasUbicacion);
  inherited;
end;

procedure TfrmPrintOperacionesVenta.DoShow;
begin
  inherited;
  ComponerDependencias;
  if not FInicializado then
  begin
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    dteHasta.Date := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    edtAlmacen.Text := UbicacionSesion.Almacen;
    edtCaja.Text := UbicacionSesion.Caja;
    FRestringido := RestriccionEmpAlmCajaActiva(
      ContextoSesion,
      ParametrosApp);
    ClientWidth := 900;
    tsUbicaciones.TabVisible := not FRestringido;
    if FRestringido then
    begin
      pcOpciones.ActivePage := tsFiltros;
      lblContexto.Caption := SCaptionTpvRestringido;
    end
    else
    begin
      pcOpciones.ActivePage := tsUbicaciones;
      CargarUbicaciones;
    end;
    FInicializado := True;
  end;
end;

procedure TfrmPrintOperacionesVenta.ComponerDependencias;
begin
  ValidarDependenciaCaja(FRepositorioPersistencia, 'informes de Caja');
end;

function TfrmPrintOperacionesVenta.HexAColor(
  const AHex: string;
  out AColor: TColor): Boolean;
var
  nAzul: Integer;
  nRojo: Integer;
  nVerde: Integer;
  sHex: string;
begin
  Result := False;
  sHex := Trim(AHex);
  if Copy(sHex, 1, 1) = '#' then
    Delete(sHex, 1, 1);
  if Length(sHex) = 6 then
  begin
    Result :=
      TryStrToInt('$' + Copy(sHex, 1, 2), nRojo) and
      TryStrToInt('$' + Copy(sHex, 3, 2), nVerde) and
      TryStrToInt('$' + Copy(sHex, 5, 2), nAzul);
    if Result then
      AColor := RGB(nRojo, nVerde, nAzul);
  end;
end;

function TfrmPrintOperacionesVenta.NumeroUbicacionesMarcadas: Integer;
var
  i: Integer;
begin
  Result := 0;
  if clbUbicaciones <> nil then
    for i := 0 to clbUbicaciones.Items.Count - 1 do
      if clbUbicaciones.Items[i].State = cbsChecked then
        Inc(Result);
end;

procedure TfrmPrintOperacionesVenta.preparar_consulta;
var
  NuevoResultado: IResultadoInformeCaja;
  Solicitud: TSolicitudOperacionesVentaCaja;
begin
  if frxrprt1.Engine.Running then
    raise EInvalidOperation.Create(
      STextoElInformeDeOperacionesDeVentaSigueCaja);
  inherited;
  if dteDesde.Date <= 0 then
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
  if dteHasta.Date <= 0 then
    dteHasta.Date := Date;
  if dteHasta.Date < dteDesde.Date then
    dteHasta.Date := dteDesde.Date;
  AsegurarUbicacionSeleccionada;
  // Mantener el resultado anterior hasta enlazar el nuevo por completo.
  Solicitud := ConstruirSolicitud;
  if (Solicitud.NombreAtributo = '') <> (Solicitud.ValorAtributo = '') then
    raise EArgumentException.Create(SAvisoAtributoInformeIncompleto);
  NuevoResultado := FRepositorioPersistencia.ConsultarOperacionesVenta(
    Solicitud);
  try
    dsVentasPrint.DataSet := NuevoResultado.DataSet;
    fxdsVentas.UpdateBounds;
  except
    dsVentasPrint.DataSet := FDatos;
    fxdsVentas.UpdateBounds;
    raise;
  end;
  FDatos := NuevoResultado.DataSet;
  FResultado := NuevoResultado;
  PrepararCantidadesInforme(FDatos);
end;

procedure TfrmPrintOperacionesVenta.PrepararCantidadesInforme(
  ADatos: TDataSet);
var
  Marca: TBookmark;
  Unidad: string;
begin
  FreeAndNil(FIndiceCantidades);
  FIndiceCantidades := TIndiceCantidadesBalance.Create;
  FFechaGrupoCantidad := '';
  FCajaGrupoCantidad := '';
  FVendedorGrupoCantidad := '';
  Marca := ADatos.Bookmark;
  ADatos.DisableControls;
  try
    ADatos.First;
    while not ADatos.Eof do
    begin
      // FZ-ISSUE-1126: los préstamos no entran en los totales.
      if (ADatos.FieldByName('CANTIDAD').AsFloat <> 0) and
         (ADatos.FieldByName('ES_PRESTAMO').AsInteger = 0) then
      begin
        Unidad := UpperCase(Trim(
          ADatos.FieldByName('UNIDAD_CANTIDAD').AsString));
        if (Unidad = 'UDS.') or (Unidad = 'UD') or
           (Unidad = 'UNIDADES') then Unidad := 'UDS';
        FIndiceCantidades.Agregar(Unidad,
          [FormatDateTime('yyyymmdd',
            ADatos.FieldByName('FECHA_DIA').AsDateTime),
           ADatos.FieldByName('CLAVE_CAJA').AsString,
           ADatos.FieldByName('VENDEDOR').AsString]);
      end;
      ADatos.Next;
    end;
  finally
    if ADatos.BookmarkValid(Marca) then ADatos.Bookmark := Marca;
    ADatos.EnableControls;
  end;
end;

procedure TfrmPrintOperacionesVenta.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
var
  oSolicitud: TSolicitudOperacionesVentaCaja;
begin
  inherited;
  // La misma solicitud que la consulta: sin ubicaciones marcadas (o con
  // la restricción activa) se consulta la de la sesión.
  oSolicitud := ConstruirSolicitud;
  AResumen.AnadirRangoFechas(
    lblFechas.Caption, oSolicitud.FechaDesde, oSolicitud.FechaHasta);
  AnadirUbicacionesInformeCaja(
    AResumen, tsUbicaciones.Caption, oSolicitud.Ubicaciones);
  if oSolicitud.Talla <> '' then
    AResumen.Anadir(lblFiltroTalla.Caption, oSolicitud.Talla);
  if oSolicitud.Color <> '' then
    AResumen.Anadir(lblFiltroColor.Caption, oSolicitud.Color);
  if oSolicitud.Copa <> '' then
    AResumen.Anadir(lblFiltroCopa.Caption, oSolicitud.Copa);
  if oSolicitud.NombreAtributo <> '' then
    AResumen.Anadir(oSolicitud.NombreAtributo, oSolicitud.ValorAtributo);
  if oSolicitud.CodigoArqueo <> '' then
    AResumen.Anadir(lblCodigoArqueo.Caption, oSolicitud.CodigoArqueo);
end;

function TfrmPrintOperacionesVenta.ConstruirSolicitud:
  TSolicitudOperacionesVentaCaja;
var
  i: Integer;
begin
  Result.FechaDesde := Trunc(dteDesde.Date);
  if Result.FechaDesde <= 0 then
    Result.FechaDesde := EncodeDate(YearOf(Date), 1, 1);
  Result.FechaHasta := Trunc(dteHasta.Date);
  if Result.FechaHasta <= 0 then
    Result.FechaHasta := Date;
  if Result.FechaHasta < Result.FechaDesde then
    Result.FechaHasta := Result.FechaDesde;
  Result.Talla := Trim(edtFiltroTalla.Text);
  Result.Color := Trim(edtFiltroColor.Text);
  Result.Copa := Trim(edtFiltroCopa.Text);
  Result.NombreAtributo := Trim(edtNombreAtributo.Text);
  Result.ValorAtributo := Trim(edtValorAtributo.Text);
  Result.CodigoArqueo := Trim(edtCodigoArqueo.Text);
  SetLength(Result.Ubicaciones, 0);
  if FRestringido or (NumeroUbicacionesMarcadas = 0) then
  begin
    SetLength(Result.Ubicaciones, 1);
    Result.Ubicaciones[0].Empresa := UbicacionSesion.Empresa;
    Result.Ubicaciones[0].Almacen := UbicacionSesion.Almacen;
    Result.Ubicaciones[0].Caja := UbicacionSesion.Caja;
  end
  else
  begin
    for i := 0 to clbUbicaciones.Items.Count - 1 do
    begin
      if clbUbicaciones.Items[i].State = cbsChecked then
      begin
        SetLength(
          Result.Ubicaciones,
          Length(Result.Ubicaciones) + 1);
        Result.Ubicaciones[High(Result.Ubicaciones)].Empresa :=
          FEmpresasUbicacion[i];
        Result.Ubicaciones[High(Result.Ubicaciones)].Almacen :=
          FAlmacenesUbicacion[i];
        Result.Ubicaciones[High(Result.Ubicaciones)].Caja :=
          FCajasUbicacion[i];
      end;
    end;
  end;
end;

procedure TfrmPrintOperacionesVenta.ReportBeforePrintConColor(
  Component: TfrxReportComponent);
var
  ColorBasico: TColor;
  MemoColorBasico: TfrxMemoView;
  ObjetoCantidad: TfrxComponent;
begin
  ReportBeforePrintConQR(Component);
  if Assigned(FIndiceCantidades) and Assigned(Component) then
  begin
    if SameText(Component.Name, 'GroupHeaderFecha') then
      FFechaGrupoCantidad := FormatDateTime('yyyymmdd',
        dsVentasPrint.DataSet.FieldByName('FECHA_DIA').AsDateTime);
    if SameText(Component.Name, 'GroupHeaderCaja') then
      FCajaGrupoCantidad :=
        dsVentasPrint.DataSet.FieldByName('CLAVE_CAJA').AsString;
    if SameText(Component.Name, 'GroupHeaderVendedor') then
      FVendedorGrupoCantidad :=
        dsVentasPrint.DataSet.FieldByName('VENDEDOR').AsString;
    if SameText(Component.Name, 'GroupFooterVendedor') then
    begin
      ObjetoCantidad := frxrprt1.FindObject('MemoTotalVendedorCantidad');
      if ObjetoCantidad is TfrxMemoView then
        TfrxMemoView(ObjetoCantidad).Visible :=
          FIndiceCantidades.GrupoSumable([FFechaGrupoCantidad,
            FCajaGrupoCantidad, FVendedorGrupoCantidad], 3);
    end;
    if SameText(Component.Name, 'GroupFooterCaja') then
    begin
      ObjetoCantidad := frxrprt1.FindObject('MemoTotalCajaCantidad');
      if ObjetoCantidad is TfrxMemoView then
        TfrxMemoView(ObjetoCantidad).Visible :=
          FIndiceCantidades.GrupoSumable(
            [FFechaGrupoCantidad, FCajaGrupoCantidad], 2);
    end;
    if SameText(Component.Name, 'GroupFooterFecha') then
    begin
      ObjetoCantidad := frxrprt1.FindObject('MemoTotalFechaCantidad');
      if ObjetoCantidad is TfrxMemoView then
        TfrxMemoView(ObjetoCantidad).Visible :=
          FIndiceCantidades.GrupoSumable([FFechaGrupoCantidad], 1);
    end;
  end;

  if (Component <> nil) and
     SameText(Component.Name, 'MemoColorBasico') and
     (Component is TfrxMemoView) then
  begin
    MemoColorBasico := TfrxMemoView(Component);
    if Assigned(FDatos) and
       HexAColor(
         FDatos.FieldByName('HEX_COLOR_BASICO').AsString,
         ColorBasico) then
      MemoColorBasico.Color := ColorBasico
    else
      MemoColorBasico.Color := clWhite;
  end
  else if (Component is TfrxMemoView) and (FRotuloEjeColor <> '') and
          SameText(Component.Name, 'MemoHColor') then
    TfrxMemoView(Component).Text := FRotuloEjeColor
  else if (Component is TfrxMemoView) and
          SameText(Component.Name, 'MemoHCopa') then
    TfrxMemoView(Component).Text := FRotuloEjeCopa
  else if (Component is TfrxMemoView) and (FRotuloEjeTalla <> '') and
          SameText(Component.Name, 'MemoHTalla') then
    TfrxMemoView(Component).Text := FRotuloEjeTalla;
end;

end.

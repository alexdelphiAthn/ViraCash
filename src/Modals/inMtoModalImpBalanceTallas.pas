{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpBalanceTallas                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.2.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Balance de almacén por tallas" (FastReport).      }
{    Informe A4 horizontal con la foto del artículo, agrupado por familia y    }
{    artículo, con las tallas como columnas y los colores/estados como         }
{    bandas. Se apoya en el SP PRC_GET_BALANCE_ALMACEN_TALLAS (ver             }
{    DESARROLLOS EN CURSO/balance_almacen_tallas.sql).                         }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro, que aporta las pestañas de filtros        }
{    múltiples (almacenes, familias, proveedores, temporadas y fechas). Este   }
{    modal solo añade el modo (entre fechas / acumulados) y el nivel de        }
{    detalle (simplificado / desglosado) sobre la pestaña de fechas, y la      }
{    plantilla del informe + la consulta.                                      }
{******************************************************************************}
unit inMtoModalImpBalanceTallas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxRadioGroup,
  cxCheckListBox, cxCheckBox, cxCustomListBox,
  cxClasses, dxSkinsForm, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frCoreClasses,
  inLibInformeBalanceTallasPersistenciaIntf, inMtoPreviewExcel,
  inLibResumenSeleccionesInforme, inLibBalanceCantidades;

type
  TfrmPrintBalanceTallas = class(TfrmPrintMultiFiltro)
    fxdsBalance: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FIndiceCantidades: TIndiceCantidadesBalance;
    FUnidadArticuloBalance: TUnidadArticuloBalance;
    FRepositorioBalance: IRepositorioInformeBalanceTallas;
    FResultadoBalance: IResultadoInformeBalanceTallas;
    FrgModo: TcxRadioGroup;       // 0 = Entre fechas, 1 = Por acumulados
    FrgDetalle: TcxRadioGroup;    // 0 = Simplificado, 1 = Desglosado
    FclbBandas: TcxCheckListBox;  // qué bandas mostrar (sin marcar = todas)
    // Crea los radios de modo/detalle y la pestaña de bandas.
    procedure CrearControlesModo;
    procedure CargarBandas;
    procedure ActualizarHabilitacion;
    procedure rgConfigChange(Sender: TObject);
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelBalance(Sender: TObject);
    // Handler de OnBeforePrint del report: mantiene el refresco de fotos del
    // base y oculta las bandas de grupo de los niveles no usados.
    procedure ReportBeforePrint(Component: TfrxReportComponent);
    // Precarga en bloque las fotos de los artículos del resultado (1 consulta).
    procedure PrecargarFotosArticulos;
    // Muestra el visor de Excel sobre el modal.
    procedure MostrarPreviewExcel(APreview: TfrmMtoPreviewExcel);
    // Detalle "Exportando fila X de Y" de la ventana de espera.
    procedure AvisarProgresoExcel(AFila, ATotal: Integer);
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    procedure DoShow; override;
    // Añade al detalle de la espera el artículo que se está volcando.
    function DetalleProgresoInforme: string; override;
  public
    destructor Destroy; override;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

uses
  System.StrUtils, inLibMsgArticulos, inLibMsgComun,
  inLibBalanceTallasExcel, inLibBalanceAvisos,
  UniDataDecimalesArticulo, inLibBalanceCantidadesInforme,
  dxSpreadSheet, inLibFotos, UniDataInformeBalanceTallasRepositorio,
  inLibResumenSeleccionesVcl, UniDataColumnasDocumentoRepositorio;

{ TfrmPrintBalanceTallas }

function TfrmPrintBalanceTallas.FiltrosUsados: TFiltrosReport;
begin
  // El balance usa todas las pestañas de filtro.
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintBalanceTallas.DoShow;
begin
  inherited;
  // El base ya ha creado las pestañas de filtro (incluida Fechas). Añadimos
  // una sola vez los radios de modo/detalle sobre la pestaña de fechas.
  if not FInicializado then
  begin
    CrearControlesModo;
    // El botón Excel del base exporta el FastReport a XLSX (queda farragoso
    // con un informe agrupado). Lo redirigimos a una exportación limpia con
    // el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelBalance;
    FInicializado := True;
    ActualizarHabilitacion;
  end;
end;

procedure TfrmPrintBalanceTallas.CrearControlesModo;
begin
  if TabFechas <> nil then
  begin
    FrgModo := TcxRadioGroup.Create(Self);
    FrgModo.Parent  := TabFechas;
    FrgModo.Left    := 220;
    FrgModo.Top     := 12;
    FrgModo.Width   := 210;
    FrgModo.Height  := 80;
    FrgModo.Caption := SCaptionGrupoModo;
    FrgModo.Properties.Items.Add.Caption := SCaptionModoEntreFechas;
    FrgModo.Properties.Items.Add.Caption := SCaptionModoPorAcumulados;
    FrgModo.ItemIndex := 0;
    FrgModo.Properties.OnEditValueChanged := rgConfigChange;
    FrgDetalle := TcxRadioGroup.Create(Self);
    FrgDetalle.Parent  := TabFechas;
    FrgDetalle.Left    := 220;
    FrgDetalle.Top     := 100;
    FrgDetalle.Width   := 210;
    FrgDetalle.Height  := 80;
    FrgDetalle.Caption := SCaptionGrupoDetalle;
    FrgDetalle.Properties.Items.Add.Caption := SCaptionModoSimplificado;
    FrgDetalle.Properties.Items.Add.Caption := SCaptionModoDesglosado;
    FrgDetalle.ItemIndex := 0;
    FrgDetalle.Properties.OnEditValueChanged := rgConfigChange;
  end;
  // Pestaña "Bandas": qué bandas mostrar. Se rellena según modo/detalle y se
  // refresca al cambiarlos (las bandas disponibles cambian).
  FclbBandas := CrearTabChecklist(SCaptionBandasBalanceTallas);
  CargarBandas;
  // Pestaña "Agrupaciones": agrupa (con resumen por grupo) por almacén,
  // proveedor, familia y/o temporada, en el orden elegido. El spin de nivel de
  // familia permite agrupar por la familia raíz o por un nivel intermedio.
  CrearTabAgrupacion(SCaptionAgrupacionesBalanceTallas,
    ['ALM', 'PRV', 'FAM', 'TMP'],
    [SCaptionAlmacenBalanceTallas,
     SCaptionProveedorBalanceTallas,
     SCaptionFamiliaBalanceTallas,
     SCaptionTemporadaBalanceTallas], True);
end;

procedure TfrmPrintBalanceTallas.ActualizarHabilitacion;
var
  bFechas: Boolean;
begin
  bFechas := (FrgModo = nil) or (FrgModo.ItemIndex = 0);
  if DteDesde <> nil then
    DteDesde.Enabled := bFechas;
  if DteHasta <> nil then
    DteHasta.Enabled := bFechas;
  if FrgDetalle <> nil then
    FrgDetalle.Enabled := bFechas;
end;

procedure TfrmPrintBalanceTallas.rgConfigChange(Sender: TObject);
begin
  ActualizarHabilitacion;
  CargarBandas;
end;

procedure TfrmPrintBalanceTallas.CargarBandas;

  procedure Agregar(const ACod, AEtiq: string);
  var
    item: TcxCheckListBoxItem;
  begin
    item := FclbBandas.Items.Add;
    item.Text  := ACod + ' - ' + AEtiq;
    item.State := cbsUnchecked;
  end;

begin
  if FclbBandas <> nil then
  begin
    FclbBandas.Items.Clear;
    // Los avisos (AVIFAC, SINMOV) no se listan: el SP los devuelve siempre
    // que haya algo que avisar.
    if (FrgModo <> nil) and (FrgModo.ItemIndex = 1) then
    begin
      // Por acumulados (todo el histórico de movimientos, todo neto).
      Agregar('ENT',    SCaptionEntradasBalanceTallas);
      Agregar('VEN',    SCaptionVentasBalanceTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceTallas);
    end
    else if (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    begin
      // Entre fechas, desglosado: entradas por tipo de movimiento (netas) y
      // ventas en alb. venta y ventas.
      Agregar('EXIINI', SCaptionExistenciasInicialesBalanceTallas);
      Agregar('ENTCMP', SCaptionEntradaCompraBalanceTallas);
      Agregar('ENTALB', SCaptionAlbaranEntradaBalanceTallas);
      Agregar('ENTTRA', SCaptionTraspasosBalanceTallas);
      Agregar('ENTDEP', SCaptionDepositosBalanceTallas);
      Agregar('ENTREG', SCaptionRegularizacionesBalanceTallas);
      Agregar('ENTDEV', SCaptionDevolucionProveedorBalanceTallas);
      Agregar('ENTOTR', SCaptionOtrosMovimientosBalanceTallas);
      Agregar('SALALB', SCaptionAlbaranVentaBalanceTallas);
      Agregar('VEN',    SCaptionVentasBalanceTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceTallas);
    end
    else
    begin
      // Entre fechas, simplificado (sin Salidas).
      Agregar('EXIINI', SCaptionExistenciasInicialesBalanceTallas);
      Agregar('ENT',    SCaptionEntradasBalanceTallas);
      Agregar('VEN',    SCaptionVentasBalanceTallas);
      Agregar('EXIFIN', SCaptionExistenciasFinalesBalanceTallas);
    end;
  end;
end;

procedure TfrmPrintBalanceTallas.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AnadirOpcionRadio(AResumen, FrgModo);
  // Por acumulados el detalle está deshabilitado y no se describe.
  AnadirOpcionRadio(AResumen, FrgDetalle);
  // Sin marcar, el procedimiento devuelve todas las bandas.
  AnadirMarcados(
    AResumen,
    SCaptionBandasBalanceTallas,
    FclbBandas,
    SResumenSeleccionesTodas);
  AResumen.Anadir(
    SResumenSeleccionesTarifa,
    ParametrosCaja.TarifaDefecto);
  AResumen.Anadir(
    SResumenBalanceValoracion,
    SResumenBalanceValoracionCriterio);
end;

procedure TfrmPrintBalanceTallas.preparar_consulta;
var
  criterios: TCriteriosInformeBalanceTallas;
  niveles: TArray<string>;
  function NivelN(idx: Integer): string;
  begin
    if (idx >= 0) and (idx < Length(niveles)) then
      Result := niveles[idx]
    else
      Result := '';
  end;
begin
  inherited;
  niveles := NivelesAgrupacion;
  if (FrgModo <> nil) and (FrgModo.ItemIndex = 1) then
    criterios.Modo := 'A'
  else
    criterios.Modo := 'F';
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Familias := CSVFamilias;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Articulos := CSVArticulos;
  criterios.Tarifa := ParametrosCaja.TarifaDefecto;
  if (FrgModo <> nil) and (FrgModo.ItemIndex = 0) and
     (FrgDetalle <> nil) and (FrgDetalle.ItemIndex = 1) then
    criterios.Desglosado := 'S'
  else
    criterios.Desglosado := 'N';
  criterios.Bandas := SeleccionadosCSV(FclbBandas);
  criterios.Nivel1 := NivelN(0);
  criterios.Nivel2 := NivelN(1);
  criterios.Nivel3 := NivelN(2);
  criterios.NivelFamilia := NivelFamilia;
  if FRepositorioBalance = nil then
    FRepositorioBalance := CrearRepositorioInformeBalanceTallasUniDAC(
      ConexionPrincipal);
  FreeAndNil(FIndiceCantidades);
  FResultadoBalance := FRepositorioBalance.Preparar(criterios);
  FUnidadArticuloBalance :=
    function(const ACodigoArticulo: string): string
    begin
      Result := FResultadoBalance.UnidadArticulo(ACodigoArticulo);
    end;
  FIndiceCantidades := PrepararIndiceCantidadesBalance(
    FResultadoBalance.DataSet, FUnidadArticuloBalance);
  fxdsBalance.UpdateBounds;
end;

procedure TfrmPrintBalanceTallas.AfterReportLoaded;
var
  CabeceraArticulo: TfrxComponent;
begin
  inherited;
  // El TfrxDBDataset debe enlazar la query por DataSet directo (no por
  // DataSource): la resolución de la foto lee TfrxDBDataset.DataSet en
  // inLibFotos.ObtenerDataSetDeBandaPadre, que es nil si solo se fija el
  // DataSource. Reafirmamos el enlace y el registro en el report.
  fxdsBalance.DataSet := FResultadoBalance.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsBalance);
  // Cada bloque necesita su propia cabecera de tallas, tambien en plantillas
  // guardadas antes del 835. La identidad del articulo se conserva para fotos.
  if fxdsBalance.DataSet.FindField('CLAVE_BLOQUE') <> nil then
  begin
    CabeceraArticulo := frxrprt1.FindObject('GroupHeaderArt');
    if CabeceraArticulo is TfrxGroupHeader then
      TfrxGroupHeader(CabeceraArticulo).Condition := 'Balance."CLAVE_BLOQUE"';
  end;
  // Las filas de aviso del SP (facturado distinto de vendido, stock sin
  // movimientos) salen en rojo.
  ResaltarAvisosBalance(frxrprt1, fxdsBalance);
  ExplicarAvisosBalance(frxrprt1);
  // El base ha enganchado el OnBeforePrint a las fotos. Lo sustituimos por el
  // nuestro, que encadena las fotos y además oculta las bandas de grupo de los
  // niveles inactivos (sin esto, FastReport pinta una banda vacía por nivel).
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta: el handler de fotos
  // El servicio de fotos las toma de la caché y no hace un SELECT por artículo
  // (antes era un N+1 con muchas fotos).
  PrecargarFotosArticulos;
end;

destructor TfrmPrintBalanceTallas.Destroy;
begin
  // Vaciar la caché de precarga de fotos (vive durante el modal).
  FreeAndNil(FIndiceCantidades);
  FotosArticulos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintBalanceTallas.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active and
     (not FResultadoBalance.DataSet.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      FResultadoBalance.DataSet.DisableControls;
      try
        FResultadoBalance.DataSet.First;
        while not FResultadoBalance.DataSet.Eof do
        begin
          slCod.Add(FResultadoBalance.DataSet.FieldByName(
            'CODIGO_ART_ART').AsString);
          FResultadoBalance.DataSet.Next;
        end;
      finally
        FResultadoBalance.DataSet.EnableControls;
      end;
      FotosArticulos.PrecargarFotosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
end;

procedure TfrmPrintBalanceTallas.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  sNom : string;
  nivel: Integer;
begin
  // 1) Mantener el refresco de la foto del artículo (foto300/600/real) que
  //    hace el formulario base a través del servicio de fotos inyectado.
  FotosArticulos.HandlerReportBeforePrint(Component);
  if FResultadoBalance <> nil then
    AplicarCantidadBalance(Component, FResultadoBalance.DataSet,
      FIndiceCantidades);
  // Las etiquetas del SP se traducen por código, sin cambiar sus datos.
  if (Component is TfrxMemoView) and
     SameText(Component.Name, 'MemoBanda') and
     (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active and
     not FResultadoBalance.DataSet.IsEmpty then
    TfrxMemoView(Component).Text := EtiquetaBandaBalance(
      FResultadoBalance.DataSet.FieldByName('BANDA').AsString,
      FResultadoBalance.DataSet.FieldByName('ETIQUETA_BANDA').AsString);
  // FZ-ISSUE-533: esta cabecera pertenece al artículo actual. El nombre
  // del memo permanece estable aunque FastReport cambie su texto.
  if (Component is TfrxMemoView) and
     SameText(Component.Name, 'MemoColHdr') and
     (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active and
     not FResultadoBalance.DataSet.IsEmpty then
    TfrxMemoView(Component).Text := RotuloEjeBalanceTraducido(
      RotuloEjeArticulo(ConexionPrincipal,
        FResultadoBalance.DataSet.FieldByName('CODIGO_ART_ART').AsString,
        'F', ''));
  // 2) Ocultar las bandas de grupo (cabecera y pie) cuyo nivel no está activo:
  //    el SP devuelve GRUPOn_ETIQ vacío para los niveles no usados. Como los
  //    niveles inactivos van siempre al final (el modal los manda compactados),
  //    su condición es constante y FastReport pintaría una banda vacía.
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if Component is TfrxMasterData then
      ActualizarDetalleEspera(DetalleProgresoInforme);
    if (Pos('GroupHeaderG', sNom) = 1) or (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active then
      TfrxBand(Component).Visible :=
        FResultadoBalance.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // 3) La familia NO agrupa por sí sola: solo se agrupa por familia si se
      //    elige FAM en la pestaña Agrupaciones (sale como "Familia: ..."). La
      //    cabecera fija de familia queda siempre oculta.
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintBalanceTallas.MostrarPreviewExcel(
  APreview: TfrmMtoPreviewExcel);
begin
  APreview.ShowModal;
end;

procedure TfrmPrintBalanceTallas.AvisarProgresoExcel(AFila, ATotal: Integer);
begin
  ActualizarDetalleEspera(Format(SCaptionEsperaExportandoFilas,
    [FormatFloat('#,##0', AFila), FormatFloat('#,##0', ATotal)]));
end;

function TfrmPrintBalanceTallas.DetalleProgresoInforme: string;
var
  oDatos: TDataSet;
begin
  Result := inherited DetalleProgresoInforme;
  if (FResultadoBalance <> nil) and FResultadoBalance.DataSet.Active and
     (not FResultadoBalance.DataSet.IsEmpty) then
  begin
    oDatos := FResultadoBalance.DataSet;
    Result := Format(SCaptionEsperaSeleccionandoArticulo,
      [Result, Trim(
        oDatos.FieldByName('CODIGO_ART_ART').AsString + ' ' +
        oDatos.FieldByName('DESCRIPCION_ART').AsString)]);
  end;
end;

procedure TfrmPrintBalanceTallas.ExportarExcelBalance(Sender: TObject);
var
  crCursorAnterior: TCursor;
  fPreview: TfrmMtoPreviewExcel;
begin
  // Ejecuta el SP con los filtros actuales y vuelca el resultado en una hoja
  // con el mismo layout que el informe. La ventana de espera acompaña la
  // consulta y el volcado fila a fila; el visor permite guardar a .xlsx.
  crCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  fPreview := nil;
  try
    IniciarEspera(SCaptionEsperaConsultandoDatosInforme);
    IniciarMedicionDatos;
    preparar_consulta;
    PausarMedicionDatos;
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName :=
      SNombreArchivoBalanceAlmacenTallas;
    IniciarEspera(SCaptionEsperaGenerandoHojaCalculo);
    ExportarBalanceTallasExcel(
      fPreview.dxSpreadSheet1, FResultadoBalance.DataSet, FotosArticulos,
      AvisarProgresoExcel, LineasResumenSelecciones,
      CrearDecimalesArticuloUniDAC(ConexionPrincipal, UnidadesMedida),
      FUnidadArticuloBalance);
    TerminarEspera;
    MostrarPreviewExcel(fPreview);
  finally
    TerminarEspera;
    FreeAndNil(fPreview);
    Screen.Cursor := crCursorAnterior;
  end;
end;

end.

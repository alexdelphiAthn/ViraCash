unit UNormalizer;

{
  Form principal del normalizador. Funciones:
    - Cargar SQL original o CSV de plan ya editado
    - Generar plan de renombrado de columnas e índices (BBDD)
    - Buscar usos de nombres viejos en el resto del SQL (vistas, INSERTs,
      procedures embebidos, …) y generar un SQL de reemplazo
    - Buscar usos en código Delphi (.pas, .dfm) y aplicar los reemplazos
      con backup .bak
    - Editar configuración (sufijos, abreviaturas, excepciones)
    - Exportar todos los entregables a una carpeta
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, System.Generics.Defaults,
  System.IOUtils, System.Math, System.Zip,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus,
  UNormalizerEngine, UProjectScanner, UDBObjectScanner;

type
  TFormNormalizer = class(TForm)
    PanelTop: TPanel;
    btnLoadSQL: TButton;
    btnLoadCSV: TButton;
    btnGenerate: TButton;
    btnExport: TButton;
    btnEditConfig: TButton;
    lblSourceFile: TLabel;

    PageControl: TPageControl;
    tabPlan: TTabSheet;
    tabColumnSQL: TTabSheet;
    tabIndexSQL: TTabSheet;
    tabSQLSearch: TTabSheet;
    tabFullSQL: TTabSheet;
    tabCodeSearch: TTabSheet;
    tabAudit: TTabSheet;
    tabReport: TTabSheet;
    tabLog: TTabSheet;

    GridPlan: TStringGrid;
    MemoColumnSQL: TMemo;
    MemoIndexSQL: TMemo;
    MemoFullSQL: TMemo;

    PanelSQLSearchTop: TPanel;
    btnScanSQL: TButton;
    btnGenerateReplaceSQL: TButton;
    lblSQLSearchInfo: TLabel;
    GridSQLMatches: TStringGrid;

    PanelCodeTop: TPanel;
    lblFolders: TLabel;
    ListBoxFolders: TListBox;
    btnAddFolder: TButton;
    btnRemoveFolder: TButton;
    btnScanCode: TButton;
    btnApplyCodeReplacements: TButton;
    btnGenerateApplyScript: TButton;
    btnFixOldParams: TButton;
    btnPatchFR3Dump: TButton;
    GridCodeMatches: TStringGrid;
    lblCodeInfo: TLabel;

    PanelAuditTop: TPanel;
    btnAuditCode: TButton;
    btnExportAudit: TButton;
    lblAuditInfo: TLabel;
    GridAuditMatches: TStringGrid;
    SaveDialogAudit: TSaveDialog;

    MemoReport: TMemo;

    MemoLog: TMemo;
    OpenDialog: TOpenDialog;
    StatusBar: TStatusBar;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadSQLClick(Sender: TObject);
    procedure btnLoadCSVClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnEditConfigClick(Sender: TObject);
    procedure btnAddFolderClick(Sender: TObject);
    procedure btnRemoveFolderClick(Sender: TObject);
    procedure btnScanCodeClick(Sender: TObject);
    procedure btnApplyCodeReplacementsClick(Sender: TObject);
    procedure btnScanSQLClick(Sender: TObject);
    procedure btnGenerateReplaceSQLClick(Sender: TObject);
    procedure btnAuditCodeClick(Sender: TObject);
    procedure btnExportAuditClick(Sender: TObject);
    procedure btnGenerateApplyScriptClick(Sender: TObject);
    procedure btnFixOldParamsClick(Sender: TObject);
    procedure btnPatchFR3DumpClick(Sender: TObject);
  private
    FNormalizer:    TViraCashNormalizer;
    FSourceSQL:     string;
    FColumnPlan:    TColumnList;
    FIndexPlan:     TIndexList;
    FProjectScanner: TProjectScanner;
    FDBScanner:     TDBObjectScanner;
    FCodeMatches:   TFileMatchList;
    FSQLMatches:    TSQLMatchList;
    FAuditMatches:  TLooseMatchList;
    FReplaceSQL:    string;
    procedure Log(const S: string);
    procedure RefreshGridPlan;
    procedure RefreshGridSQLMatches;
    procedure RefreshGridCodeMatches;
    procedure RefreshGridAuditMatches;
    procedure RefreshReport;
    procedure UpdateButtons;
    procedure SetupGrids;
    function  BuildPlanPairList: TPlanPairList;
    procedure LoadPlanFromCSV(const Path: string);
    function  BuildApplyScriptPS1: string;
    function  BuildApplyScriptCSV: string;
    procedure WriteApplyScriptZip(const ZipPath: string);
  end;

var
  FormNormalizer: TFormNormalizer;

implementation

{$R *.dfm}

uses
  System.UITypes, System.StrUtils,
  UConfigEditor, UFR3SQLDumpPatcher;

const
  cMascaraSql = '*.sql';
  cMascaraCsv = '*.csv';
  cMascaraTexto = '*.txt';
  cMascaraZip = '*.zip';
  cMascaraTodosArchivos = '*.*';
  cExtensionPas = '.pas';
  cExtensionDfm = '.dfm';
  cExtensionBackup = '.bak';
  cPatronParametrosOld = 'Old_*';
  cCampoKeyUsuper = 'KEY_USUPER';
  cFormularioPrintFac = 'frmPrintFac';
  cFormularioPrintRecFac = 'frmPrintRecFac';
  cArchivoSqlReemplazo = '03_reemplazar_en_resto_sql.sql';
  cArchivoScriptCambios = 'aplicar_cambios.ps1';
  cArchivoPlanCambios = 'aplicar_cambios.csv';
  cArchivoLeemeCambios = 'LEEME.txt';
  cOpcionDryRun = '-DryRun';

resourcestring
  SFiltroArchivosSql =
    'Archivos SQL (%s)|%s|Todos los archivos (%s)|%s';
  SFiltroArchivosCsv =
    'Archivos CSV (%s)|%s|Todos los archivos (%s)|%s';
  SFiltroArchivosTexto =
    'Texto (%s)|%s|Todos los archivos (%s)|%s';
  SFiltroArchivosZip =
    'Archivos ZIP (%s)|%s|Todos los archivos (%s)|%s';
  STituloSeleccionarVolcadoSql = 'Selecciona el volcado SQL original';
  STituloSeleccionarPlanCsv = 'Selecciona el CSV de plan ya editado';
  STituloSeleccionarCarpetaEntregables =
    'Selecciona la carpeta donde guardar los entregables';
  STituloSeleccionarCarpetaProyecto =
    'Selecciona una carpeta del proyecto Delphi';
  STituloSeleccionarDumpOriginal =
    'Selecciona el dump SQL ORIGINAL (no se modificará)';
  STituloArchivoSalidaDump =
    'Archivo de salida (NO debe coincidir con la entrada)';
  STituloExportarInformeAuditoria = 'Exportar informe de auditoría';
  STituloGuardarScriptCambios =
    'Guardar script de aplicación de cambios';
  SNombreArchivoCasosRevisar = 'casos_a_revisar.txt';
  SNombreArchivoAplicarCambios = 'aplicar_cambios.zip';
  SErrorCargarArchivo = 'No se pudo cargar el archivo: %s';
  SErrorCargarCsv = 'No se pudo cargar el CSV: %s';
  SAvisoCargarSqlPrimero = 'Carga un fichero SQL primero.';
  SInfoExportacionCompletada =
    'Exportación completada (%d ficheros) en:'#13#10'%s';
  SErrorExportar = 'Error al exportar: %s';
  SPreguntaAplicarReemplazosCodigo =
    'Se modificarán los archivos %s/%s de las carpetas indicadas.'#13#10 +
    'Se creará una copia de seguridad %s de cada uno ' +
    '(si no existe ya).'#13#10#13#10 +
    '¿Continuar?';
  SInfoReemplazosCodigoAplicados =
    'Reemplazos aplicados a %d ficheros.'#13#10 +
    'Se han creado backups %s junto a cada original.';
  SAvisoSinCarpetasEscaneo =
    'No hay carpetas que escanear. Añade al menos una.';
  SInfoSinParametrosDesincronizados =
    'No se han encontrado parámetros %s desincronizados.';
  SPreguntaCorregirParametrosDesincronizados =
    'Se han detectado parámetros %s desincronizados en los %s.'#13#10 +
    'Se reescribirán para que coincidan con el nombre actual de la columna.' +
    #13#10 +
    'Se creará un backup %s de cada archivo modificado ' +
    '(si no existe).'#13#10#13#10 +
    '¿Aplicar los cambios?';
  SInfoSaneadoParametrosCompletado =
    'Saneado completado.'#13#10 +
    '  Ficheros modificados: %d'#13#10 +
    '  Parámetros corregidos: %d'#13#10#13#10 +
    'Se han creado backups %s junto a cada original.';
  SErrorArchivoSalidaCoincide =
    'El archivo de salida no puede coincidir con el de entrada.';
  SAvisoSinPlanRenombrado =
    'No hay plan de renombrado cargado.'#13#10 +
    'Genera el plan primero desde la pestaña SQL.';
  SPreguntaParchearDump =
    'Entrada (intacta):'#13#10'  %s'#13#10#13#10 +
    'Salida (se creará/sobreescribirá):'#13#10'  %s'#13#10#13#10 +
    'Solo se procesarán filas con %s en (%s, %s).'#13#10#13#10 +
    '¿Continuar?';
  SInfoDumpSinCambios =
    'Procesado correctamente, sin cambios necesarios.'#13#10 +
    'El archivo de salida es una copia 1:1 de la entrada:'#13#10 +
    '  %s';
  SInfoDumpParcheado =
    'Dump parcheado correctamente.'#13#10 +
    '  Filas con cambios:  %d'#13#10 +
    '  Salida:             %s';
  SInfoSqlReemplazoGenerado =
    'SQL de reemplazo generado.'#13#10 +
    'Se incluirá en la exportación como %s.';
  SAvisoSinDatosAuditoria =
    'No hay datos de auditoría que exportar. ' +
    'Pulsa "Auditar código" primero.';
  SInfoInformeAuditoriaExportado = 'Informe exportado a:'#13#10'%s';
  SAvisoSinCambiosPlan =
    'No hay cambios en el plan. Carga el SQL o un CSV de plan primero.';
  SInfoZipCambiosGenerado =
    'ZIP generado en:'#13#10'%s'#13#10#13#10 +
    'Contiene:'#13#10 +
    '  - %s (script PowerShell)'#13#10 +
    '  - %s (%d pares de renombrado)'#13#10 +
    '  - %s (instrucciones)'#13#10#13#10 +
    'Antes de aplicar de verdad, ejecuta primero con %s.';
  SErrorGenerarScriptCambios = 'Error al generar el script: %s';

procedure TFormNormalizer.FormCreate(Sender: TObject);
begin
  Caption  := 'ViraCash Normalizer';
  Position := poScreenCenter;

  FNormalizer     := TViraCashNormalizer.Create;
  FColumnPlan     := TColumnList.Create;
  FIndexPlan      := TIndexList.Create;
  FProjectScanner := TProjectScanner.Create;
//  FProjectScanner.OnLog := Log;
  FDBScanner      := TDBObjectScanner.Create;
//  FDBScanner.OnLog := Log;
  FCodeMatches    := TFileMatchList.Create;
  FSQLMatches     := TSQLMatchList.Create;
  FAuditMatches   := TLooseMatchList.Create;
  FProjectScanner.OnLog :=  procedure(S: string)
                            begin
                              Log(S);
                            end;
  FDBScanner.OnLog :=  procedure(S: string)
                       begin
                         Log(S);
                       end;
  SetupGrids;
  Log('Normalizer iniciado.');
  Log('Carga el SQL original (Cargar SQL...) o un CSV de plan ya editado (Cargar CSV...).');
  UpdateButtons;
end;

procedure TFormNormalizer.FormDestroy(Sender: TObject);
begin
  FCodeMatches.Free;
  FSQLMatches.Free;
  FAuditMatches.Free;
  FProjectScanner.Free;
  FDBScanner.Free;
  FColumnPlan.Free;
  FIndexPlan.Free;
  FNormalizer.Free;
end;

procedure TFormNormalizer.SetupGrids;
begin
  GridPlan.ColCount    := 5;
  GridPlan.RowCount    := 2;
  GridPlan.FixedRows   := 1;
  GridPlan.FixedCols   := 0;
  GridPlan.Cells[0, 0] := 'Tabla';
  GridPlan.Cells[1, 0] := 'Columna actual';
  GridPlan.Cells[2, 0] := 'Columna nueva';
  GridPlan.Cells[3, 0] := 'Cambia';
  GridPlan.Cells[4, 0] := 'Definición';
  GridPlan.ColWidths[0] := 220;
  GridPlan.ColWidths[1] := 240;
  GridPlan.ColWidths[2] := 240;
  GridPlan.ColWidths[3] := 60;
  GridPlan.ColWidths[4] := 280;
  GridPlan.Options := GridPlan.Options + [goRowSelect, goColSizing,
                                            goThumbTracking] - [goEditing];

  GridSQLMatches.ColCount  := 5;
  GridSQLMatches.RowCount  := 2;
  GridSQLMatches.FixedRows := 1;
  GridSQLMatches.FixedCols := 0;
  GridSQLMatches.Cells[0, 0] := 'Línea';
  GridSQLMatches.Cells[1, 0] := 'Contexto';
  GridSQLMatches.Cells[2, 0] := 'Antes';
  GridSQLMatches.Cells[3, 0] := 'Después';
  GridSQLMatches.Cells[4, 0] := 'Texto';
  GridSQLMatches.ColWidths[0] := 60;
  GridSQLMatches.ColWidths[1] := 80;
  GridSQLMatches.ColWidths[2] := 200;
  GridSQLMatches.ColWidths[3] := 200;
  GridSQLMatches.ColWidths[4] := 600;
  GridSQLMatches.Options := GridSQLMatches.Options + [goRowSelect, goColSizing,
                            goThumbTracking] - [goEditing];

  GridCodeMatches.ColCount  := 5;
  GridCodeMatches.RowCount  := 2;
  GridCodeMatches.FixedRows := 1;
  GridCodeMatches.FixedCols := 0;
  GridCodeMatches.Cells[0, 0] := 'Archivo';
  GridCodeMatches.Cells[1, 0] := 'Línea';
  GridCodeMatches.Cells[2, 0] := 'Antes';
  GridCodeMatches.Cells[3, 0] := 'Después';
  GridCodeMatches.Cells[4, 0] := 'Texto';
  GridCodeMatches.ColWidths[0] := 350;
  GridCodeMatches.ColWidths[1] := 60;
  GridCodeMatches.ColWidths[2] := 200;
  GridCodeMatches.ColWidths[3] := 200;
  GridCodeMatches.ColWidths[4] := 500;
  GridCodeMatches.Options := GridCodeMatches.Options + [goRowSelect, goColSizing,
                             goThumbTracking] - [goEditing];

  // Rejilla de auditoría (pasada B)
  GridAuditMatches.ColCount  := 7;
  GridAuditMatches.RowCount  := 2;
  GridAuditMatches.FixedRows := 1;
  GridAuditMatches.FixedCols := 0;
  GridAuditMatches.Cells[0, 0] := 'Archivo';
  GridAuditMatches.Cells[1, 0] := 'Línea';
  GridAuditMatches.Cells[2, 0] := 'Nombre antiguo';
  GridAuditMatches.Cells[3, 0] := 'Nombre nuevo';
  GridAuditMatches.Cells[4, 0] := 'Contexto';
  GridAuditMatches.Cells[5, 0] := 'Motivo';
  GridAuditMatches.Cells[6, 0] := 'Texto';
  GridAuditMatches.ColWidths[0] := 350;
  GridAuditMatches.ColWidths[1] := 60;
  GridAuditMatches.ColWidths[2] := 180;
  GridAuditMatches.ColWidths[3] := 180;
  GridAuditMatches.ColWidths[4] := 220;
  GridAuditMatches.ColWidths[5] := 90;
  GridAuditMatches.ColWidths[6] := 500;
  GridAuditMatches.Options := GridAuditMatches.Options + [goRowSelect, goColSizing,
                              goThumbTracking] - [goEditing];
end;

procedure TFormNormalizer.Log(const S: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TFormNormalizer.UpdateButtons;
begin
  btnGenerate.Enabled              := FSourceSQL <> '';
  btnExport.Enabled                := FColumnPlan.Count > 0;
  btnScanSQL.Enabled               := (FColumnPlan.Count > 0) and (FSourceSQL <> '');
  btnGenerateReplaceSQL.Enabled    := (FColumnPlan.Count > 0) and (FSourceSQL <> '');
  btnScanCode.Enabled              := (FColumnPlan.Count > 0) and
                                      (ListBoxFolders.Items.Count > 0);
  btnApplyCodeReplacements.Enabled := btnScanCode.Enabled;
  btnAuditCode.Enabled             := btnScanCode.Enabled;
  btnExportAudit.Enabled           := Assigned(FAuditMatches) and (FAuditMatches.Count > 0);
  btnGenerateApplyScript.Enabled   := FColumnPlan.Count > 0;
end;

function TFormNormalizer.BuildPlanPairList: TPlanPairList;
var
  Rec:         TColumnRename;
  SeenOld:     TDictionary<string, string>;  // OldName -> NewName ya añadido
  ExistingNew: string;
begin
  Result  := TPlanPairList.Create;
  SeenOld := TDictionary<string, string>.Create;
  try
    for Rec in FColumnPlan do
    begin
      if not Rec.Changed then Continue;

      if SeenOld.TryGetValue(Rec.OldName, ExistingNew) then
      begin
        // Ya teníamos este OldName.
        // Si el NewName coincide -> duplicado normal (mismo nombre de columna
        // en varias tablas), lo ignoramos silenciosamente.
        // Si NO coincide -> es un conflicto: misma columna, distintos nuevos
        // nombres en tablas distintas. Avisamos y NO lo añadimos al plan
        // textual (un reemplazo ciego sería peor que no hacer nada).
        if ExistingNew <> Rec.NewName then
          Log(Format(
            '[WARN] Conflicto en plan: %s aparece como %s y como %s en tablas ' +
            'distintas. Se omite del plan textual; renombra manualmente.',
            [Rec.OldName, ExistingNew, Rec.NewName]));
        Continue;
      end;

      SeenOld.Add(Rec.OldName, Rec.NewName);
      Result.Add(TPlanPair.Create(Rec.OldName, Rec.NewName));
    end;
  finally
    SeenOld.Free;
  end;
end;

procedure TFormNormalizer.btnLoadSQLClick(Sender: TObject);
var
  Plan:         TPlanPairList;
  ChangedCount, i, Changed: Integer;
begin
  OpenDialog.Filter     := Format(SFiltroArchivosSql,
    [cMascaraSql, cMascaraSql,
     cMascaraTodosArchivos, cMascaraTodosArchivos]);
  OpenDialog.DefaultExt := 'sql';
  OpenDialog.Title      := STituloSeleccionarVolcadoSql;
  if not OpenDialog.Execute then Exit;

  Screen.Cursor := crHourGlass;
  try
    // 1) Cargar
    try
      FSourceSQL := TFile.ReadAllText(OpenDialog.FileName, TEncoding.UTF8);
      lblSourceFile.Caption := 'Origen: ' + ExtractFileName(OpenDialog.FileName);
      Log(Format('SQL cargado: %s (%d bytes)',
        [OpenDialog.FileName, Length(FSourceSQL)]));
    except
      on E: Exception do
      begin
        Log('[ERROR] Cargando SQL: ' + E.Message);
        MessageDlg(Format(SErrorCargarArchivo, [E.Message]),
                   mtError, [mbOK], 0);
        Exit;
      end;
    end;

    // 2) Generar plan automáticamente
    Log('Generando plan…');
    FNormalizer.GeneratePlan(FSourceSQL, FColumnPlan, FIndexPlan,
      procedure(S: string)
      begin
        Log(S);
      end);

    ChangedCount := 0;
    for i := 0 to FColumnPlan.Count - 1 do
      if FColumnPlan[i].Changed then Inc(ChangedCount);

    Log(Format('Plan generado: %d columnas (%d cambian, %d sin cambios), %d índices.',
      [FColumnPlan.Count, ChangedCount, FColumnPlan.Count - ChangedCount,
       FIndexPlan.Count]));

    RefreshGridPlan;
    MemoColumnSQL.Lines.Text := FNormalizer.BuildColumnRenameSQL(FColumnPlan);
    MemoIndexSQL.Lines.Text  := FNormalizer.BuildIndexRenameSQL(FIndexPlan);

    // 3) Escanear el propio SQL en busca de usos de los nombres viejos
    //    fuera de los CREATE TABLE (vistas, procedures, INSERTs, triggers...)
    if ChangedCount > 0 then
    begin
      Plan := BuildPlanPairList;
      try
        FDBScanner.SetRenamePlan(Plan);
        FDBScanner.Scan(FSourceSQL, FSQLMatches);
        RefreshGridSQLMatches;

        // 4) Generar SQL completo modificado: el dump original entero,
        //    con los nombres viejos sustituidos por los nuevos en
        //    vistas, procedures, INSERTs, etc. (los CREATE TABLE quedan
        //    intactos porque ya van por separado en 01_renombrar_columnas.sql).
        FReplaceSQL := FDBScanner.BuildReplacementSQL(FSourceSQL, Changed);
        MemoFullSQL.Lines.Text := FReplaceSQL;
        Log(Format('SQL completo modificado generado (%d reemplazos aplicados).',
          [Changed]));
      finally
        Plan.Free;
      end;
    end
    else
    begin
      FSQLMatches.Clear;
      RefreshGridSQLMatches;
      FReplaceSQL := '';
      MemoFullSQL.Lines.Clear;
      Log('No hay columnas que cambien: no se ha escaneado SQL ni generado reemplazo.');
    end;

    RefreshReport;

    StatusBar.SimpleText := Format('%d columnas, %d cambian, %d índices, %d coincidencias en SQL.',
      [FColumnPlan.Count, ChangedCount, FIndexPlan.Count, FSQLMatches.Count]);

    PageControl.ActivePage := tabPlan;
    UpdateButtons;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.btnLoadCSVClick(Sender: TObject);
var
  i, ChangedCount: Integer;
begin
  OpenDialog.Filter     := Format(SFiltroArchivosCsv,
    [cMascaraCsv, cMascaraCsv,
     cMascaraTodosArchivos, cMascaraTodosArchivos]);
  OpenDialog.DefaultExt := 'csv';
  OpenDialog.Title      := STituloSeleccionarPlanCsv;
  if not OpenDialog.Execute then Exit;

  try
    LoadPlanFromCSV(OpenDialog.FileName);
    lblSourceFile.Caption := 'Plan: ' + ExtractFileName(OpenDialog.FileName);
    RefreshGridPlan;
    MemoColumnSQL.Lines.Text := FNormalizer.BuildColumnRenameSQL(FColumnPlan);
    ChangedCount := 0;
    for i := 0 to FColumnPlan.Count - 1 do
      if FColumnPlan[i].Changed then Inc(ChangedCount);
    StatusBar.SimpleText := Format('CSV cargado: %d filas, %d cambian.',
      [FColumnPlan.Count, ChangedCount]);
    UpdateButtons;
  except
    on E: Exception do
    begin
      Log('[ERROR] Cargando CSV: ' + E.Message);
      MessageDlg(Format(SErrorCargarCsv, [E.Message]), mtError, [mbOK], 0);
    end;
  end;
end;

procedure TFormNormalizer.LoadPlanFromCSV(const Path: string);
var
  Lines: TStringList;
  i:     Integer;
  Parts: TArray<string>;
  Rec:   TColumnRename;
  Line:  string;

  function SplitCSVLine(const S: string): TArray<string>;
  var
    j:        Integer;
    InQuotes: Boolean;
    Cur:      string;
    Out_:     TList<string>;
    NextChar: Char;
  begin
    Out_ := TList<string>.Create;
    try
      Cur := '';
      InQuotes := False;
      j := 1;
      while j <= Length(S) do
      begin
        if S[j] = '"' then
        begin
          if j < Length(S) then NextChar := S[j + 1] else NextChar := #0;
          if InQuotes and (NextChar = '"') then
          begin
            Cur := Cur + '"';
            Inc(j, 2);
            Continue;
          end
          else
            InQuotes := not InQuotes;
        end
        else if (S[j] = ',') and not InQuotes then
        begin
          Out_.Add(Cur);
          Cur := '';
        end
        else
          Cur := Cur + S[j];
        Inc(j);
      end;
      Out_.Add(Cur);
      Result := Out_.ToArray;
    finally
      Out_.Free;
    end;
  end;

begin
  FColumnPlan.Clear;
  FIndexPlan.Clear;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Path, TEncoding.UTF8);
    if Lines.Count < 2 then
    begin
      Log('[WARN] CSV vacío o sin filas de datos.');
      Exit;
    end;
    for i := 1 to Lines.Count - 1 do
    begin
      Line := Lines[i].Trim;
      if Line = '' then Continue;
      Parts := SplitCSVLine(Line);
      if Length(Parts) < 5 then
      begin
        Log(Format('[WARN] Línea %d con menos de 5 columnas, ignorada.', [i + 1]));
        Continue;
      end;
      Rec.TableName  := Parts[0].Trim(['"']);
      Rec.OldName    := Parts[1].Trim(['"']);
      Rec.NewName    := Parts[2].Trim(['"']);
      Rec.Definition := Parts[4].Trim(['"']);
      Rec.Definition := StringReplace(Rec.Definition, '""', '"', [rfReplaceAll]);
      Rec.Changed    := SameText(Parts[3].Trim(['"']), 'SI') or
                        (Rec.OldName <> Rec.NewName);
      FColumnPlan.Add(Rec);
    end;
    Log(Format('CSV cargado: %d filas.', [FColumnPlan.Count]));
  finally
    Lines.Free;
  end;
end;

procedure TFormNormalizer.btnGenerateClick(Sender: TObject);
var
  ChangedCount, i: Integer;
begin
  if FSourceSQL = '' then
  begin
    MessageDlg(SAvisoCargarSqlPrimero, mtWarning, [mbOK], 0);
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    Log('Generando plan…');
    FNormalizer.GeneratePlan(FSourceSQL, FColumnPlan, FIndexPlan,
      procedure(S: string)
      begin
        Log(S);
      end);

    ChangedCount := 0;
    for i := 0 to FColumnPlan.Count - 1 do
      if FColumnPlan[i].Changed then Inc(ChangedCount);

    Log(Format('Plan generado: %d columnas (%d cambian, %d sin cambios), %d índices.',
      [FColumnPlan.Count, ChangedCount, FColumnPlan.Count - ChangedCount,
       FIndexPlan.Count]));

    RefreshGridPlan;
    MemoColumnSQL.Lines.Text := FNormalizer.BuildColumnRenameSQL(FColumnPlan);
    MemoIndexSQL.Lines.Text  := FNormalizer.BuildIndexRenameSQL(FIndexPlan);

    StatusBar.SimpleText := Format('%d columnas, %d cambian, %d índices.',
      [FColumnPlan.Count, ChangedCount, FIndexPlan.Count]);
    UpdateButtons;
    PageControl.ActivePage := tabPlan;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.RefreshGridPlan;
var
  i:   Integer;
  Rec: TColumnRename;
begin
  if FColumnPlan.Count = 0 then
  begin
    GridPlan.RowCount := 2;
    GridPlan.Cells[0, 1] := '';
    GridPlan.Cells[1, 1] := '';
    GridPlan.Cells[2, 1] := '';
    GridPlan.Cells[3, 1] := '';
    GridPlan.Cells[4, 1] := '';
    Exit;
  end;
  GridPlan.RowCount := FColumnPlan.Count + 1;
  for i := 0 to FColumnPlan.Count - 1 do
  begin
    Rec := FColumnPlan[i];
    GridPlan.Cells[0, i + 1] := Rec.TableName;
    GridPlan.Cells[1, i + 1] := Rec.OldName;
    GridPlan.Cells[2, i + 1] := Rec.NewName;
    if Rec.Changed then
      GridPlan.Cells[3, i + 1] := 'SI'
    else
      GridPlan.Cells[3, i + 1] := 'NO';
    GridPlan.Cells[4, i + 1] := Rec.Definition;
  end;
end;

procedure TFormNormalizer.btnExportClick(Sender: TObject);
var
  Folder: string;
  ColSQL, IdxSQL, CSV: string;
  SL:     TStringList;
  M:      TFileMatch;
  L:      TLooseMatch;
  ExportedFiles: Integer;
begin
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders, fdoForceFileSystem, fdoPathMustExist];
    Title   := STituloSeleccionarCarpetaEntregables;
    if not Execute then Exit;
    Folder := FileName;
  finally
    Free;
  end;

  ExportedFiles := 0;
  try
    // ---- 1) Plan de BBDD ----
    ColSQL := FNormalizer.BuildColumnRenameSQL(FColumnPlan);
    IdxSQL := FNormalizer.BuildIndexRenameSQL(FIndexPlan);
    CSV    := FNormalizer.BuildPlanCSV(FColumnPlan);

    TFile.WriteAllText(TPath.Combine(Folder, '01_renombrar_columnas.sql'),
      ColSQL, TEncoding.UTF8);
    Log('  + 01_renombrar_columnas.sql');
    Inc(ExportedFiles);

    TFile.WriteAllText(TPath.Combine(Folder, '02_renombrar_indices.sql'),
      IdxSQL, TEncoding.UTF8);
    Log('  + 02_renombrar_indices.sql');
    Inc(ExportedFiles);

    TFile.WriteAllText(TPath.Combine(Folder, 'plan_renombrado.csv'),
      CSV, TEncoding.UTF8);
    Log('  + plan_renombrado.csv');
    Inc(ExportedFiles);

    // ---- 2) SQL completo modificado (vistas, procedures, INSERTs...) ----
    if FReplaceSQL <> '' then
    begin
      TFile.WriteAllText(TPath.Combine(Folder, '03_dump_completo_modificado.sql'),
        FReplaceSQL, TEncoding.UTF8);
      Log('  + 03_dump_completo_modificado.sql');
      Inc(ExportedFiles);
    end;

    // ---- 3) Coincidencias en código Delphi (pasada estricta) ----
    if FCodeMatches.Count > 0 then
    begin
      // 3a) CSV con todas las coincidencias estrictas
      SL := TStringList.Create;
      try
        SL.Add('Archivo;Linea;NombreAntiguo;NombreNuevo;Texto');
        for M in FCodeMatches do
          SL.Add(Format('"%s";%d;"%s";"%s";"%s"',
            [M.FilePath, M.LineNumber, M.ColumnOld, M.ColumnNew,
             StringReplace(M.LineText.Trim, '"', '""', [rfReplaceAll])]));
        SL.SaveToFile(TPath.Combine(Folder, '04_codigo_coincidencias.csv'),
          TEncoding.UTF8);
        Log('  + 04_codigo_coincidencias.csv');
        Inc(ExportedFiles);
      finally
        SL.Free;
      end;

      // 3b) TXT con resumen legible (para abrir y leer directamente)
      SL := TStringList.Create;
      try
        SL.Add('# Coincidencias en código fuente (pasada estricta)');
        SL.Add('# Generado: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
        SL.Add(Format('# Total coincidencias: %d', [FCodeMatches.Count]));
        SL.Add('# Estos cambios SE APLICAN cuando pulsas "Aplicar reemplazos (con .bak)".');
        SL.Add('# Formato: ARCHIVO | LINEA | OLD -> NEW | TEXTO');
        SL.Add('');
        for M in FCodeMatches do
          SL.Add(Format('%s | %d | %s -> %s | %s',
            [M.FilePath, M.LineNumber, M.ColumnOld, M.ColumnNew,
             M.LineText.Trim]));
        SL.SaveToFile(TPath.Combine(Folder, '04_codigo_coincidencias.txt'),
          TEncoding.UTF8);
        Log('  + 04_codigo_coincidencias.txt');
        Inc(ExportedFiles);
      finally
        SL.Free;
      end;
    end
    else
      Log('  (sin coincidencias en código: omito 04_codigo_coincidencias.*)');

    // ---- 4) Auditoría laxa (casos dudosos a revisar manualmente) ----
    if FAuditMatches.Count > 0 then
    begin
      // 4a) CSV
      SL := TStringList.Create;
      try
        SL.Add('Archivo;Linea;NombreAntiguo;NombreNuevo;Contexto;Motivo;Texto');
        for L in FAuditMatches do
          SL.Add(Format('"%s";%d;"%s";"%s";"%s";"%s";"%s"',
            [L.FilePath, L.LineNumber, L.ColumnOld, L.ColumnNew,
             L.Context, L.Reason,
             StringReplace(L.LineText.Trim, '"', '""', [rfReplaceAll])]));
        SL.SaveToFile(TPath.Combine(Folder, '05_codigo_auditoria.csv'),
          TEncoding.UTF8);
        Log('  + 05_codigo_auditoria.csv');
        Inc(ExportedFiles);
      finally
        SL.Free;
      end;

      // 4b) TXT legible
      SL := TStringList.Create;
      try
        SL.Add('# Auditoría de código (pasada B - revisar manualmente)');
        SL.Add('# Generado: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
        SL.Add(Format('# Total ocurrencias dudosas: %d', [FAuditMatches.Count]));
        SL.Add('# Estos casos NO se aplican automáticamente. Hay que decidir');
        SL.Add('# uno a uno si conviene renombrarlos a mano.');
        SL.Add('# Formato: ARCHIVO | LINEA | OLD -> NEW | CONTEXTO | MOTIVO | TEXTO');
        SL.Add('');
        for L in FAuditMatches do
          SL.Add(Format('%s | %d | %s -> %s | %s | %s | %s',
            [L.FilePath, L.LineNumber, L.ColumnOld, L.ColumnNew,
             L.Context, L.Reason, L.LineText.Trim]));
        SL.SaveToFile(TPath.Combine(Folder, '05_codigo_auditoria.txt'),
          TEncoding.UTF8);
        Log('  + 05_codigo_auditoria.txt');
        Inc(ExportedFiles);
      finally
        SL.Free;
      end;
    end
    else
      Log('  (sin ocurrencias dudosas en auditoría: omito 05_codigo_auditoria.*)');

    // ---- 5) Informe global ----
    if MemoReport.Lines.Count > 0 then
    begin
      TFile.WriteAllText(TPath.Combine(Folder, 'informe_impacto.txt'),
        MemoReport.Lines.Text, TEncoding.UTF8);
      Log('  + informe_impacto.txt');
      Inc(ExportedFiles);
    end;

    // ---- 6) Script PowerShell para aplicar cambios al codigo fuente ----
    try
      WriteApplyScriptZip(TPath.Combine(Folder, '06_aplicar_cambios.zip'));
      Log('  + 06_aplicar_cambios.zip (script + CSV + LEEME)');
      Inc(ExportedFiles);
    except
      on E: Exception do
        Log('[WARN] No se pudo generar el ZIP de script: ' + E.Message);
    end;

    Log(Format('Exportados %d ficheros a %s', [ExportedFiles, Folder]));
    MessageDlg(Format(SInfoExportacionCompletada,
      [ExportedFiles, Folder]),
      mtInformation, [mbOK], 0);
  except
    on E: Exception do
    begin
      Log('[ERROR] Exportando: ' + E.Message);
      MessageDlg(Format(SErrorExportar, [E.Message]), mtError, [mbOK], 0);
    end;
  end;
end;

procedure TFormNormalizer.btnEditConfigClick(Sender: TObject);
begin
  with TFormConfigEditor.Create(Self) do
  try
    Normalizer := FNormalizer;
    LoadFromNormalizer;
    if ShowModal = mrOK then
    begin
      ApplyToNormalizer;
      Log('Configuración actualizada. Pulsa "Generar plan" para regenerar.');
    end;
  finally
    Free;
  end;
end;

procedure TFormNormalizer.btnAddFolderClick(Sender: TObject);
var
  Folder: string;
begin
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders, fdoForceFileSystem, fdoPathMustExist];
    Title   := STituloSeleccionarCarpetaProyecto;
    if not Execute then Exit;
    Folder := FileName;
  finally
    Free;
  end;

  if ListBoxFolders.Items.IndexOf(Folder) < 0 then
  begin
    ListBoxFolders.Items.Add(Folder);
    FProjectScanner.AddFolder(Folder);
    Log('Carpeta añadida: ' + Folder);
  end;
  UpdateButtons;
end;

procedure TFormNormalizer.btnRemoveFolderClick(Sender: TObject);
var
  i: Integer;
begin
  if ListBoxFolders.ItemIndex < 0 then Exit;
  ListBoxFolders.Items.Delete(ListBoxFolders.ItemIndex);
  FProjectScanner.ClearFolders;
  for i := 0 to ListBoxFolders.Items.Count - 1 do
    FProjectScanner.AddFolder(ListBoxFolders.Items[i]);
  UpdateButtons;
end;

procedure TFormNormalizer.btnScanCodeClick(Sender: TObject);
var
  Plan: TPlanPairList;
begin
  Screen.Cursor := crHourGlass;
  Plan := BuildPlanPairList;
  try
    FProjectScanner.SetRenamePlan(Plan);
    FProjectScanner.Scan(FCodeMatches);
    RefreshGridCodeMatches;
    RefreshReport;
    PageControl.ActivePage := tabCodeSearch;
  finally
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.btnApplyCodeReplacementsClick(Sender: TObject);
var
  Plan:  TPlanPairList;
  Stats: TFileChangeList;
begin
  if MessageDlg(
       Format(SPreguntaAplicarReemplazosCodigo,
         [cExtensionPas, cExtensionDfm, cExtensionBackup]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Stats := TFileChangeList.Create;
  Plan  := BuildPlanPairList;
  Screen.Cursor := crHourGlass;
  try
    FProjectScanner.SetRenamePlan(Plan);
    FProjectScanner.ApplyReplacements(Stats);
    Log(Format('Reemplazos aplicados a %d ficheros.', [Stats.Count]));
    MessageDlg(Format(SInfoReemplazosCodigoAplicados,
      [Stats.Count, cExtensionBackup]),
      mtInformation, [mbOK], 0);
    FProjectScanner.Scan(FCodeMatches);
    RefreshGridCodeMatches;
    RefreshReport;
  finally
    Stats.Free;
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.btnFixOldParamsClick(Sender: TObject);
var
  Stats: TFileChangeList;
  Fixes: TOldParamFixList;
  i:     Integer;
  Fix:   TOldParamFix;
begin
  if ListBoxFolders.Items.Count = 0 then
  begin
    MessageDlg(SAvisoSinCarpetasEscaneo,
      mtWarning, [mbOK], 0);
    Exit;
  end;

  // Aseguramos que las carpetas configuradas en la UI están en el scanner.
  FProjectScanner.ClearFolders;
  for i := 0 to ListBoxFolders.Items.Count - 1 do
    FProjectScanner.AddFolder(ListBoxFolders.Items[i]);

  // Pasada 1: PREVIEW (no toca disco). Sirve para que el usuario sepa
  // exactamente cuántos cambios se aplicarían y en qué archivos.
  Fixes := TOldParamFixList.Create;
  Screen.Cursor := crHourGlass;
  try
    FProjectScanner.PreviewOldParameterFixes(Fixes);

    if Fixes.Count = 0 then
    begin
      Log('No hay parámetros Old_* desincronizados. Nada que sanear.');
      MessageDlg(Format(SInfoSinParametrosDesincronizados,
        [cPatronParametrosOld]),
        mtInformation, [mbOK], 0);
      Exit;
    end;

    Log(Format('Detectados %d parámetro(s) Old_* desincronizados.',
      [Fixes.Count]));
    // Volcamos los primeros casos al log para inspección rápida.
    for i := 0 to Min(Fixes.Count - 1, 19) do
    begin
      Fix := Fixes[i];
      Log(Format('  [%s]  col=%s  %s -> %s',
        [ExtractFileName(Fix.FilePath), Fix.ColumnName,
         Fix.OldParam, Fix.NewParam]));
    end;
    if Fixes.Count > 20 then
      Log(Format('  ...y %d más (ver fichero corregido)', [Fixes.Count - 20]));
  finally
    Fixes.Free;
    Screen.Cursor := crDefault;
  end;

  // Confirmación antes de tocar disco
  if MessageDlg(
       Format(SPreguntaCorregirParametrosDesincronizados,
         [cPatronParametrosOld, cExtensionDfm, cExtensionBackup]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    Log('Cancelado por el usuario. No se ha modificado nada.');
    Exit;
  end;

  // Pasada 2: APLICAR
  Stats := TFileChangeList.Create;
  Fixes := TOldParamFixList.Create;
  Screen.Cursor := crHourGlass;
  try
    FProjectScanner.FixOldParameters(Stats, Fixes);
    Log(Format('Saneado completado: %d fichero(s) modificado(s), %d parámetro(s) corregido(s).',
      [Stats.Count, Fixes.Count]));
    MessageDlg(Format(SInfoSaneadoParametrosCompletado,
      [Stats.Count, Fixes.Count, cExtensionBackup]),
      mtInformation, [mbOK], 0);
  finally
    Stats.Free;
    Fixes.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.btnPatchFR3DumpClick(Sender: TObject);
var
  Patcher:    TFR3DumpPatcher;
  Plan:       TPlanPairList;
  Fixes:      TFR3DumpRowFixList;
  OpenDlg:    TOpenDialog;
  SaveDlg:    TSaveDialog;
  InputFile:  string;
  OutputFile: string;
  DefaultOut: string;
  BaseDir, BaseName, BaseExt: string;
  Changed:    Boolean;
  i:          Integer;
  Fix:        TFR3DumpRowFix;
begin
  // 1) Pedir archivo de ENTRADA (dump original)
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title  := STituloSeleccionarDumpOriginal;
    OpenDlg.Filter := Format(SFiltroArchivosSql,
      [cMascaraSql, cMascaraSql,
       cMascaraTodosArchivos, cMascaraTodosArchivos]);
    if not OpenDlg.Execute then Exit;
    InputFile := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;

  // 2) Construir nombre por defecto del archivo de salida:
  //    <basename>_dfmfr3patched.sql en la misma carpeta
  BaseDir  := ExtractFilePath(InputFile);
  BaseName := ChangeFileExt(ExtractFileName(InputFile), '');
  BaseExt  := ExtractFileExt(InputFile);
  if BaseExt = '' then BaseExt := '.sql';
  DefaultOut := IncludeTrailingPathDelimiter(BaseDir) +
                BaseName + '_dfmfr3patched' + BaseExt;

  // 3) Pedir archivo de SALIDA
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Title       := STituloArchivoSalidaDump;
    SaveDlg.Filter      := Format(SFiltroArchivosSql,
      [cMascaraSql, cMascaraSql,
       cMascaraTodosArchivos, cMascaraTodosArchivos]);
    SaveDlg.DefaultExt  := 'sql';
    SaveDlg.FileName    := DefaultOut;
    SaveDlg.Options     := SaveDlg.Options + [ofOverwritePrompt];
    if not SaveDlg.Execute then Exit;
    OutputFile := SaveDlg.FileName;
  finally
    SaveDlg.Free;
  end;

  if SameFileName(InputFile, OutputFile) then
  begin
    MessageDlg(SErrorArchivoSalidaCoincide,
      mtError, [mbOK], 0);
    Exit;
  end;

  if FColumnPlan.Count = 0 then
  begin
    MessageDlg(SAvisoSinPlanRenombrado,
      mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg(
       Format(SPreguntaParchearDump,
         [InputFile, OutputFile, cCampoKeyUsuper,
          cFormularioPrintFac, cFormularioPrintRecFac]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Plan    := BuildPlanPairList;
  Fixes   := TFR3DumpRowFixList.Create;
  Patcher := TFR3DumpPatcher.Create;
  Screen.Cursor := crHourGlass;
  try
    Patcher.OnLog :=
      procedure(S: string)
      begin
        Log(S);
      end;
    Patcher.SetRenamePlan(Plan);
    Patcher.SetKeyFilter('frmPrintFac,frmPrintRecFac');

    Changed := Patcher.ProcessDumpFile(InputFile, OutputFile, Fixes);

    if not Changed then
    begin
      MessageDlg(Format(SInfoDumpSinCambios, [OutputFile]),
        mtInformation, [mbOK], 0);
      Exit;
    end;

    // Resumen detallado al log
    Log(Format('--- Cambios por fila (%d) ---', [Fixes.Count]));
    for i := 0 to Min(Fixes.Count - 1, 49) do
    begin
      Fix := Fixes[i];
      if Fix.ErrorMsg <> '' then
        Log(Format('  [ERR ] [%s/%s/%s] %s',
          [Fix.UsuarioGrupo, Fix.KeyName, Fix.SubKey, Fix.ErrorMsg]))
      else
        Log(Format('  [%4d] [%s/%s/%s] %d->%d bytes',
          [Fix.Replacements,
           Fix.UsuarioGrupo, Fix.KeyName, Fix.SubKey,
           Fix.BytesBefore, Fix.BytesAfter]));
    end;
    if Fixes.Count > 50 then
      Log(Format('  ...y %d más', [Fixes.Count - 50]));

    MessageDlg(Format(SInfoDumpParcheado,
      [Fixes.Count, OutputFile]),
      mtInformation, [mbOK], 0);
  finally
    Patcher.Free;
    Fixes.Free;
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.RefreshGridCodeMatches;
var
  i: Integer;
  M: TFileMatch;
begin
  if FCodeMatches.Count = 0 then
  begin
    GridCodeMatches.RowCount := 2;
    GridCodeMatches.Cells[0, 1] := '';
    GridCodeMatches.Cells[1, 1] := '';
    GridCodeMatches.Cells[2, 1] := '';
    GridCodeMatches.Cells[3, 1] := '';
    GridCodeMatches.Cells[4, 1] := '';
    lblCodeInfo.Caption := 'Sin coincidencias.';
    Exit;
  end;
  GridCodeMatches.RowCount := FCodeMatches.Count + 1;
  for i := 0 to FCodeMatches.Count - 1 do
  begin
    M := FCodeMatches[i];
    GridCodeMatches.Cells[0, i + 1] := M.FilePath;
    GridCodeMatches.Cells[1, i + 1] := IntToStr(M.LineNumber);
    GridCodeMatches.Cells[2, i + 1] := M.ColumnOld;
    GridCodeMatches.Cells[3, i + 1] := M.ColumnNew;
    GridCodeMatches.Cells[4, i + 1] := M.LineText.Trim;
  end;
  lblCodeInfo.Caption := Format('%d coincidencias.', [FCodeMatches.Count]);
end;

procedure TFormNormalizer.btnScanSQLClick(Sender: TObject);
var
  Plan: TPlanPairList;
begin
  Screen.Cursor := crHourGlass;
  Plan := BuildPlanPairList;
  try
    FDBScanner.SetRenamePlan(Plan);
    FDBScanner.Scan(FSourceSQL, FSQLMatches);
    RefreshGridSQLMatches;
    RefreshReport;
    PageControl.ActivePage := tabSQLSearch;
  finally
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.btnGenerateReplaceSQLClick(Sender: TObject);
var
  Plan:    TPlanPairList;
  Changed: Integer;
begin
  Screen.Cursor := crHourGlass;
  Plan := BuildPlanPairList;
  try
    FDBScanner.SetRenamePlan(Plan);
    FReplaceSQL := FDBScanner.BuildReplacementSQL(FSourceSQL, Changed);
    MemoFullSQL.Lines.Text := FReplaceSQL;
    Log(Format('SQL de reemplazo generado (%d reemplazos aplicados).',
      [Changed]));
    PageControl.ActivePage := tabFullSQL;
    MessageDlg(Format(SInfoSqlReemplazoGenerado,
      [cArchivoSqlReemplazo]),
      mtInformation, [mbOK], 0);
  finally
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.RefreshGridSQLMatches;
var
  i: Integer;
  M: TSQLMatch;
begin
  if FSQLMatches.Count = 0 then
  begin
    GridSQLMatches.RowCount := 2;
    GridSQLMatches.Cells[0, 1] := '';
    GridSQLMatches.Cells[1, 1] := '';
    GridSQLMatches.Cells[2, 1] := '';
    GridSQLMatches.Cells[3, 1] := '';
    GridSQLMatches.Cells[4, 1] := '';
    lblSQLSearchInfo.Caption := 'Sin coincidencias.';
    Exit;
  end;
  GridSQLMatches.RowCount := FSQLMatches.Count + 1;
  for i := 0 to FSQLMatches.Count - 1 do
  begin
    M := FSQLMatches[i];
    GridSQLMatches.Cells[0, i + 1] := IntToStr(M.LineNumber);
    GridSQLMatches.Cells[1, i + 1] := M.Context;
    GridSQLMatches.Cells[2, i + 1] := M.ColumnOld;
    GridSQLMatches.Cells[3, i + 1] := M.ColumnNew;
    GridSQLMatches.Cells[4, i + 1] := M.LineText.Trim;
  end;
  lblSQLSearchInfo.Caption := Format('%d coincidencias.', [FSQLMatches.Count]);
end;

procedure TFormNormalizer.RefreshReport;
var
  ColCounts:  TDictionary<string, Integer>;
  CtxCounts:  TDictionary<string, Integer>;
  FileCounts: TDictionary<string, Integer>;
  M:          TFileMatch;
  S:          TSQLMatch;
  Pair:       TPair<string, Integer>;
  SB:         TStringBuilder;
  i, ChangedCols, V: Integer;

  function SortDictDesc(D: TDictionary<string, Integer>): TArray<TPair<string,Integer>>;
  var
    Arr: TArray<TPair<string,Integer>>;
    Idx: Integer;
    Pair: TPair<string, Integer>;
  begin
    SetLength(Arr, D.Count);
    Idx := 0;
    for Pair in D do
    begin
      Arr[Idx] := Pair;
      Inc(Idx);
    end;
    TArray.Sort<TPair<string,Integer>>(Arr,
      TComparer<TPair<string,Integer>>.Construct(
        function(const L, R: TPair<string,Integer>): Integer
        begin
          Result := R.Value - L.Value;
          if Result = 0 then Result := CompareStr(L.Key, R.Key);
        end));
    Result := Arr;
  end;

  procedure Dump(const Title: string; Arr: TArray<TPair<string,Integer>>;
                 Limit: Integer);
  var
    Idx: Integer;
  begin
    SB.AppendLine(Title);
    SB.AppendLine(StringOfChar('-', Length(Title)));
    for Idx := 0 to Min(High(Arr), Limit - 1) do
      SB.AppendLine(Format('  %-50s %5d',
        [Arr[Idx].Key, Arr[Idx].Value]));
    if Length(Arr) > Limit then
      SB.AppendLine(Format('  … y %d más', [Length(Arr) - Limit]));
    SB.AppendLine;
  end;

begin
  ColCounts  := TDictionary<string, Integer>.Create;
  CtxCounts  := TDictionary<string, Integer>.Create;
  FileCounts := TDictionary<string, Integer>.Create;
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('======================================');
    SB.AppendLine(' INFORME DE IMPACTO');
    SB.AppendLine('======================================');
    SB.AppendLine;

    ChangedCols := 0;
    for i := 0 to FColumnPlan.Count - 1 do
      if FColumnPlan[i].Changed then Inc(ChangedCols);
    SB.AppendLine(Format('Columnas en plan:           %d', [FColumnPlan.Count]));
    SB.AppendLine(Format('  - Que cambian:            %d', [ChangedCols]));
    SB.AppendLine(Format('  - Sin cambio:             %d',
      [FColumnPlan.Count - ChangedCols]));
    SB.AppendLine(Format('Índices a renombrar:        %d', [FIndexPlan.Count]));
    SB.AppendLine;

    for S in FSQLMatches do
    begin
      if ColCounts.TryGetValue(S.ColumnOld, V) then
        ColCounts[S.ColumnOld] := V + 1
      else
        ColCounts.Add(S.ColumnOld, 1);
      if CtxCounts.TryGetValue(S.Context, V) then
        CtxCounts[S.Context] := V + 1
      else
        CtxCounts.Add(S.Context, 1);
    end;
    SB.AppendLine(Format('Coincidencias en SQL fuera de CREATE TABLE: %d',
      [FSQLMatches.Count]));
    if FSQLMatches.Count > 0 then
    begin
      SB.AppendLine;
      Dump('Columnas con más matches en SQL:', SortDictDesc(ColCounts), 20);
      Dump('Distribución por contexto:', SortDictDesc(CtxCounts), 10);
    end;

    ColCounts.Clear;
    for M in FCodeMatches do
    begin
      if ColCounts.TryGetValue(M.ColumnOld, V) then
        ColCounts[M.ColumnOld] := V + 1
      else
        ColCounts.Add(M.ColumnOld, 1);
      if FileCounts.TryGetValue(M.FilePath, V) then
        FileCounts[M.FilePath] := V + 1
      else
        FileCounts.Add(M.FilePath, 1);
    end;
    SB.AppendLine(Format('Coincidencias en código Delphi: %d (en %d ficheros)',
      [FCodeMatches.Count, FileCounts.Count]));
    if FCodeMatches.Count > 0 then
    begin
      SB.AppendLine;
      Dump('Columnas con más matches en código:', SortDictDesc(ColCounts), 20);
      Dump('Ficheros más afectados:', SortDictDesc(FileCounts), 20);
    end;

    MemoReport.Lines.Text := SB.ToString;
  finally
    SB.Free;
    ColCounts.Free;
    CtxCounts.Free;
    FileCounts.Free;
  end;
end;

procedure TFormNormalizer.btnAuditCodeClick(Sender: TObject);
var
  Plan: TPlanPairList;
begin
  Screen.Cursor := crHourGlass;
  Plan := BuildPlanPairList;
  try
    FProjectScanner.SetRenamePlan(Plan);
    FProjectScanner.ScanLooseAudit(FAuditMatches);
    RefreshGridAuditMatches;
    PageControl.ActivePage := tabAudit;
    UpdateButtons;
  finally
    Plan.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormNormalizer.RefreshGridAuditMatches;
var
  i: Integer;
  M: TLooseMatch;
begin
  if FAuditMatches.Count = 0 then
  begin
    GridAuditMatches.RowCount := 2;
    for i := 0 to GridAuditMatches.ColCount - 1 do
      GridAuditMatches.Cells[i, 1] := '';
    lblAuditInfo.Caption := 'Sin ocurrencias sospechosas.';
    Exit;
  end;
  GridAuditMatches.RowCount := FAuditMatches.Count + 1;
  for i := 0 to FAuditMatches.Count - 1 do
  begin
    M := FAuditMatches[i];
    GridAuditMatches.Cells[0, i + 1] := M.FilePath;
    GridAuditMatches.Cells[1, i + 1] := IntToStr(M.LineNumber);
    GridAuditMatches.Cells[2, i + 1] := M.ColumnOld;
    GridAuditMatches.Cells[3, i + 1] := M.ColumnNew;
    GridAuditMatches.Cells[4, i + 1] := M.Context;
    GridAuditMatches.Cells[5, i + 1] := M.Reason;
    GridAuditMatches.Cells[6, i + 1] := M.LineText.Trim;
  end;
  lblAuditInfo.Caption := Format('%d ocurrencias sospechosas (revisar manualmente).',
    [FAuditMatches.Count]);
end;

procedure TFormNormalizer.btnExportAuditClick(Sender: TObject);
var
  SL:   TStringList;
  M:    TLooseMatch;
  Path: string;
begin
  if FAuditMatches.Count = 0 then
  begin
    MessageDlg(SAvisoSinDatosAuditoria,
      mtInformation, [mbOK], 0);
    Exit;
  end;

  SaveDialogAudit.Filter     := Format(SFiltroArchivosTexto,
    [cMascaraTexto, cMascaraTexto,
     cMascaraTodosArchivos, cMascaraTodosArchivos]);
  SaveDialogAudit.DefaultExt := 'txt';
  SaveDialogAudit.FileName   := SNombreArchivoCasosRevisar;
  SaveDialogAudit.Title      := STituloExportarInformeAuditoria;
  if not SaveDialogAudit.Execute then Exit;
  Path := SaveDialogAudit.FileName;

  SL := TStringList.Create;
  try
    SL.Add('# Informe de auditoría (pasada B - revisar manualmente)');
    SL.Add('# Generado: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    SL.Add(Format('# Total ocurrencias: %d', [FAuditMatches.Count]));
    SL.Add('# Formato: ARCHIVO | LINEA | OLD -> NEW | CONTEXTO | MOTIVO | TEXTO');
    SL.Add('');
    for M in FAuditMatches do
      SL.Add(Format('%s | %d | %s -> %s | %s | %s | %s',
        [M.FilePath, M.LineNumber, M.ColumnOld, M.ColumnNew,
         M.Context, M.Reason, M.LineText.Trim]));
    SL.SaveToFile(Path, TEncoding.UTF8);
    Log(Format('Informe de auditoría exportado: %s (%d filas)',
      [Path, FAuditMatches.Count]));
    MessageDlg(Format(SInfoInformeAuditoriaExportado, [Path]),
      mtInformation, [mbOK], 0);
  finally
    SL.Free;
  end;
end;

function TFormNormalizer.BuildApplyScriptCSV: string;
{
  Genera el CSV de pares (OldName;NewName) deduplicado, que el script .ps1
  consumirá. Una columna por par. Separador ; para que abra bien en Excel
  ES sin volverse loco.
}
var
  SB:      TStringBuilder;
  Rec:     TColumnRename;
  SeenOld: TDictionary<string, string>;
  ExNew:   string;
begin
  SB      := TStringBuilder.Create;
  SeenOld := TDictionary<string, string>.Create;
  try
    SB.AppendLine('OldName;NewName');
    for Rec in FColumnPlan do
    begin
      if not Rec.Changed then Continue;
      if SeenOld.TryGetValue(Rec.OldName, ExNew) then Continue;
      SeenOld.Add(Rec.OldName, Rec.NewName);
      SB.AppendLine(Rec.OldName + ';' + Rec.NewName);
    end;
    Result := SB.ToString;
  finally
    SeenOld.Free;
    SB.Free;
  end;
end;

function TFormNormalizer.BuildApplyScriptPS1: string;
{
  Devuelve el contenido del script PowerShell genérico que aplica
  los reemplazos. Lee el CSV vecino "aplicar_cambios.csv" y procesa
  todos los .pas y .dfm de la carpeta indicada (recursivamente).
  Crea backup .bak antes de modificar.

  Uso típico (desde la carpeta del ZIP descomprimido):
    .\aplicar_cambios.ps1 -Carpeta 'C:\proyectos\MiProyecto\src'
    .\aplicar_cambios.ps1 -Carpeta '...' -DryRun
    .\aplicar_cambios.ps1 -Carpeta '...' -Extensiones '.pas','.dfm','.inc'
}
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<#');
    SB.AppendLine('  aplicar_cambios.ps1');
    SB.AppendLine('  Aplica los renombrados de columnas definidos en aplicar_cambios.csv');
    SB.AppendLine('  a los ficheros .pas y .dfm de una carpeta (recursivo).');
    SB.AppendLine('  Generado por ViraCash Normalizer.');
    SB.AppendLine('  Reglas:');
    SB.AppendLine('   - Reemplazo CASE-SENSITIVE.');
    SB.AppendLine('   - Solo "palabra completa" (boundary regex \b en clase [A-Za-z0-9_]).');
    SB.AppendLine('   - Procesa nombres mas largos primero.');
    SB.AppendLine('   - Crea .bak antes de modificar (si no existe).');
    SB.AppendLine('  Uso:');
    SB.AppendLine('    .\aplicar_cambios.ps1 -Carpeta ''C:\ruta\proyecto''');
    SB.AppendLine('    .\aplicar_cambios.ps1 -Carpeta ''...'' -DryRun');
    SB.AppendLine('#>');
    SB.AppendLine('param(');
    SB.AppendLine('    [Parameter(Mandatory=$true)] [string] $Carpeta,');
    SB.AppendLine('    [string] $Csv = (Join-Path $PSScriptRoot ''aplicar_cambios.csv''),');
    SB.AppendLine('    [string[]] $Extensiones = @(''.pas'', ''.dfm''),');
    SB.AppendLine('    [switch] $DryRun');
    SB.AppendLine(')');
    SB.AppendLine('');
    SB.AppendLine('$ErrorActionPreference = ''Stop''');
    SB.AppendLine('');
    SB.AppendLine('# --- Validaciones ----------------------------------------------------------');
    SB.AppendLine('if (-not (Test-Path -LiteralPath $Carpeta -PathType Container)) {');
    SB.AppendLine('    Write-Error "La carpeta indicada no existe: $Carpeta"');
    SB.AppendLine('    exit 1');
    SB.AppendLine('}');
    SB.AppendLine('if (-not (Test-Path -LiteralPath $Csv -PathType Leaf)) {');
    SB.AppendLine('    Write-Error "No encuentro el CSV de pares: $Csv"');
    SB.AppendLine('    exit 1');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# --- Cargar CSV de pares ---------------------------------------------------');
    SB.AppendLine('$pares = Import-Csv -LiteralPath $Csv -Delimiter '';'' -Encoding UTF8');
    SB.AppendLine('if (-not $pares -or $pares.Count -eq 0) {');
    SB.AppendLine('    Write-Error "El CSV no contiene pares de renombrado: $Csv"');
    SB.AppendLine('    exit 1');
    SB.AppendLine('}');
    SB.AppendLine('# Filtrar pares vacios o no cambiantes, y deduplicar por OldName');
    SB.AppendLine('$seen = @{}');
    SB.AppendLine('$pairs = @()');
    SB.AppendLine('foreach ($p in $pares) {');
    SB.AppendLine('    if (-not $p.OldName -or -not $p.NewName) { continue }');
    SB.AppendLine('    if ($p.OldName -eq $p.NewName)            { continue }');
    SB.AppendLine('    if ($seen.ContainsKey($p.OldName))         { continue }');
    SB.AppendLine('    $seen[$p.OldName] = $true');
    SB.AppendLine('    $pairs += [pscustomobject]@{ Old = $p.OldName; New = $p.NewName }');
    SB.AppendLine('}');
    SB.AppendLine('# Orden: nombres mas largos primero (para no romper compuestos)');
    SB.AppendLine('$pairs = $pairs | Sort-Object @{Expression={$_.Old.Length}; Descending=$true}, Old');
    SB.AppendLine('Write-Host ("Pares de renombrado a aplicar: {0}" -f $pairs.Count)');
    SB.AppendLine('');
    SB.AppendLine('# --- Recolectar ficheros ---------------------------------------------------');
    SB.AppendLine('$archivos = @()');
    SB.AppendLine('foreach ($ext in $Extensiones) {');
    SB.AppendLine('    $archivos += Get-ChildItem -LiteralPath $Carpeta -Recurse -File `');
    SB.AppendLine('                 -Filter ("*" + $ext) -ErrorAction SilentlyContinue');
    SB.AppendLine('}');
    SB.AppendLine('# Deduplicar por ruta');
    SB.AppendLine('$archivos = $archivos | Sort-Object FullName -Unique');
    SB.AppendLine('Write-Host ("Ficheros a revisar: {0}" -f $archivos.Count)');
    SB.AppendLine('');
    SB.AppendLine('# --- Helper: detectar codificacion sin BOM (heuristica) --------------------');
    SB.AppendLine('function Get-FileEncoding {');
    SB.AppendLine('    param([string] $Path)');
    SB.AppendLine('    $bytes = [byte[]](Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 4 -TotalCount 4)');
    SB.AppendLine('    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {');
    SB.AppendLine('        return ''utf-8-bom''');
    SB.AppendLine('    }');
    SB.AppendLine('    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { return ''utf-16le'' }');
    SB.AppendLine('    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { return ''utf-16be'' }');
    SB.AppendLine('    # Sin BOM: tratar como ANSI Windows-1252 (por defecto en .pas/.dfm antiguos).');
    SB.AppendLine('    return ''ansi''');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# --- Helper: leer contenido respetando codificacion -----------------------');
    SB.AppendLine('function Read-Text {');
    SB.AppendLine('    param([string] $Path, [string] $Enc)');
    SB.AppendLine('    switch ($Enc) {');
    SB.AppendLine('        ''utf-8-bom'' { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }');
    SB.AppendLine('        ''utf-16le''  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::Unicode) }');
    SB.AppendLine('        ''utf-16be''  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::BigEndianUnicode) }');
    SB.AppendLine('        default      { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding(1252)) }');
    SB.AppendLine('    }');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# --- Helper: escribir contenido respetando codificacion -------------------');
    SB.AppendLine('function Write-Text {');
    SB.AppendLine('    param([string] $Path, [string] $Content, [string] $Enc)');
    SB.AppendLine('    switch ($Enc) {');
    SB.AppendLine('        ''utf-8-bom'' { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($true)) }');
    SB.AppendLine('        ''utf-16le''  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::Unicode) }');
    SB.AppendLine('        ''utf-16be''  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::BigEndianUnicode) }');
    SB.AppendLine('        default      { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::GetEncoding(1252)) }');
    SB.AppendLine('    }');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# --- Bucle principal -------------------------------------------------------');
    SB.AppendLine('$totalFicherosTocados = 0');
    SB.AppendLine('$totalReemplazos      = 0');
    SB.AppendLine('$detalle              = @()');
    SB.AppendLine('');
    SB.AppendLine('foreach ($f in $archivos) {');
    SB.AppendLine('    try {');
    SB.AppendLine('        $enc = Get-FileEncoding -Path $f.FullName');
    SB.AppendLine('        $original = Read-Text -Path $f.FullName -Enc $enc');
    SB.AppendLine('        $modificado = $original');
    SB.AppendLine('        $reempEnFichero = 0');
    SB.AppendLine('');
    SB.AppendLine('        foreach ($par in $pairs) {');
    SB.AppendLine('            $patron = ''(?<![A-Za-z0-9_])'' + [regex]::Escape($par.Old) + ''(?![A-Za-z0-9_])''');
    SB.AppendLine('            $matches = [regex]::Matches($modificado, $patron)');
    SB.AppendLine('            if ($matches.Count -gt 0) {');
    SB.AppendLine('                $reempEnFichero += $matches.Count');
    SB.AppendLine('                $modificado = [regex]::Replace($modificado, $patron, $par.New)');
    SB.AppendLine('            }');
    SB.AppendLine('        }');
    SB.AppendLine('');
    SB.AppendLine('        if ($modificado -ne $original) {');
    SB.AppendLine('            if ($DryRun) {');
    SB.AppendLine('                Write-Host ("[DRY] {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)');
    SB.AppendLine('            } else {');
    SB.AppendLine('                $bak = "$($f.FullName).bak"');
    SB.AppendLine('                if (-not (Test-Path -LiteralPath $bak)) {');
    SB.AppendLine('                    Copy-Item -LiteralPath $f.FullName -Destination $bak -ErrorAction Stop');
    SB.AppendLine('                }');
    SB.AppendLine('                Write-Text -Path $f.FullName -Content $modificado -Enc $enc');
    SB.AppendLine('                Write-Host ("OK   {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)');
    SB.AppendLine('            }');
    SB.AppendLine('            $totalFicherosTocados++');
    SB.AppendLine('            $totalReemplazos += $reempEnFichero');
    SB.AppendLine('            $detalle += [pscustomobject]@{');
    SB.AppendLine('                Archivo     = $f.FullName');
    SB.AppendLine('                Reemplazos  = $reempEnFichero');
    SB.AppendLine('                Codificacion= $enc');
    SB.AppendLine('            }');
    SB.AppendLine('        }');
    SB.AppendLine('    } catch {');
    SB.AppendLine('        Write-Warning ("Error procesando {0}: {1}" -f $f.FullName, $_.Exception.Message)');
    SB.AppendLine('    }');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# --- Resumen ----------------------------------------------------------------');
    SB.AppendLine('Write-Host ""');
    SB.AppendLine('if ($DryRun) {');
    SB.AppendLine('    Write-Host ("=== DRY RUN: {0} ficheros cambiarian, {1} reemplazos en total ===" -f $totalFicherosTocados, $totalReemplazos)');
    SB.AppendLine('} else {');
    SB.AppendLine('    Write-Host ("=== Listo: {0} ficheros modificados, {1} reemplazos aplicados ===" -f $totalFicherosTocados, $totalReemplazos)');
    SB.AppendLine('}');
    SB.AppendLine('');
    SB.AppendLine('# Volcar log csv junto al script');
    SB.AppendLine('if ($detalle.Count -gt 0) {');
    SB.AppendLine('    $logCsv = Join-Path $PSScriptRoot ("aplicar_cambios_log_" + (Get-Date -Format ''yyyyMMdd_HHmmss'') + ".csv")');
    SB.AppendLine('    $detalle | Export-Csv -LiteralPath $logCsv -Delimiter '';'' -Encoding UTF8 -NoTypeInformation');
    SB.AppendLine('    Write-Host ("Detalle: {0}" -f $logCsv)');
    SB.AppendLine('}');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TFormNormalizer.WriteApplyScriptZip(const ZipPath: string);
var
  Zip:    TZipFile;
  TmpPS1, TmpCSV, TmpReadme: string;
  Readme: TStringList;
begin
  TmpPS1    := TPath.Combine(TPath.GetTempPath, 'aplicar_cambios.ps1');
  TmpCSV    := TPath.Combine(TPath.GetTempPath, 'aplicar_cambios.csv');
  TmpReadme := TPath.Combine(TPath.GetTempPath, 'LEEME.txt');

  // Escribir contenidos a temporal con UTF-8 + BOM (PowerShell ISE/old PS lo agradecen)
  TFile.WriteAllText(TmpPS1, BuildApplyScriptPS1, TEncoding.UTF8);
  TFile.WriteAllText(TmpCSV, BuildApplyScriptCSV, TEncoding.UTF8);

  Readme := TStringList.Create;
  try
    Readme.Add('Aplicar cambios al codigo fuente');
    Readme.Add('================================');
    Readme.Add('');
    Readme.Add('Generado por ViraCash Normalizer.');
    Readme.Add('');
    Readme.Add('CONTENIDO');
    Readme.Add('---------');
    Readme.Add('  aplicar_cambios.ps1   Script PowerShell que recorre la carpeta y');
    Readme.Add('                        aplica los reemplazos sobre .pas y .dfm.');
    Readme.Add('  aplicar_cambios.csv   Lista de pares (OldName;NewName) a aplicar.');
    Readme.Add('');
    Readme.Add('USO');
    Readme.Add('---');
    Readme.Add('  1) Descomprime el ZIP en cualquier carpeta.');
    Readme.Add('  2) Abre PowerShell ahi (Shift+click derecho > Abrir aqui).');
    Readme.Add('  3) Prueba primero en modo simulacion:');
    Readme.Add('       .\aplicar_cambios.ps1 -Carpeta ''C:\ruta\proyecto\src'' -DryRun');
    Readme.Add('  4) Si el resultado te convence, aplica de verdad:');
    Readme.Add('       .\aplicar_cambios.ps1 -Carpeta ''C:\ruta\proyecto\src''');
    Readme.Add('');
    Readme.Add('  Si Windows te bloquea por ExecutionPolicy:');
    Readme.Add('       powershell -ExecutionPolicy Bypass -File .\aplicar_cambios.ps1 -Carpeta ''...''');
    Readme.Add('');
    Readme.Add('GARANTIAS');
    Readme.Add('---------');
    Readme.Add('  - Cada fichero modificado tiene una copia .bak junto al original.');
    Readme.Add('  - Los reemplazos son CASE-SENSITIVE y solo "palabra completa".');
    Readme.Add('  - El script genera un log CSV con cada ejecucion en su carpeta.');
    Readme.Add('');
    Readme.Add('AVISO');
    Readme.Add('-----');
    Readme.Add('  Antes de ejecutar en produccion, asegurate de tener tu codigo en');
    Readme.Add('  control de versiones (git, svn) o haz una copia de la carpeta.');
    Readme.Add('  Los .bak son una segunda red, no la primera.');
    Readme.SaveToFile(TmpReadme, TEncoding.UTF8);
  finally
    Readme.Free;
  end;

  // Empaquetar en ZIP
  Zip := TZipFile.Create;
  try
    if FileExists(ZipPath) then DeleteFile(PChar(ZipPath));
    Zip.Open(ZipPath, zmWrite);
    Zip.Add(TmpPS1,    'aplicar_cambios.ps1');
    Zip.Add(TmpCSV,    'aplicar_cambios.csv');
    Zip.Add(TmpReadme, 'LEEME.txt');
    Zip.Close;
  finally
    Zip.Free;
  end;

  // Limpiar temporales
  if FileExists(TmpPS1)    then DeleteFile(PChar(TmpPS1));
  if FileExists(TmpCSV)    then DeleteFile(PChar(TmpCSV));
  if FileExists(TmpReadme) then DeleteFile(PChar(TmpReadme));
end;

procedure TFormNormalizer.btnGenerateApplyScriptClick(Sender: TObject);
var
  ZipPath:    string;
  ChangedCount, i: Integer;
begin
  // Verificar que tenemos plan utilizable
  ChangedCount := 0;
  for i := 0 to FColumnPlan.Count - 1 do
    if FColumnPlan[i].Changed then Inc(ChangedCount);
  if ChangedCount = 0 then
  begin
    MessageDlg(SAvisoSinCambiosPlan,
      mtWarning, [mbOK], 0);
    Exit;
  end;

  with TSaveDialog.Create(nil) do
  try
    Filter     := Format(SFiltroArchivosZip,
      [cMascaraZip, cMascaraZip,
       cMascaraTodosArchivos, cMascaraTodosArchivos]);
    DefaultExt := 'zip';
    FileName   := SNombreArchivoAplicarCambios;
    Title      := STituloGuardarScriptCambios;
    if not Execute then Exit;
    ZipPath := FileName;
  finally
    Free;
  end;

  Screen.Cursor := crHourGlass;
  try
    WriteApplyScriptZip(ZipPath);
    Log(Format('Script de aplicación generado: %s (%d pares)',
      [ZipPath, ChangedCount]));
    MessageDlg(Format(SInfoZipCambiosGenerado,
      [ZipPath, cArchivoScriptCambios, cArchivoPlanCambios, ChangedCount,
       cArchivoLeemeCambios, cOpcionDryRun]),
      mtInformation, [mbOK], 0);
  except
    on E: Exception do
    begin
      Log('[ERROR] Generando script: ' + E.Message);
      MessageDlg(Format(SErrorGenerarScriptCambios, [E.Message]),
        mtError, [mbOK], 0);
    end;
  end;
  Screen.Cursor := crDefault;
end;

end.

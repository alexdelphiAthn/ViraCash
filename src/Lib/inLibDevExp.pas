{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevExp                                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades para componentes DevExpress (cxGrid y derivados).              }
{    Búsqueda en grids, persistencia de perfiles y manejo de columnas.         }
{******************************************************************************}
unit inLibDevExp;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, DB, ADODB, DBCtrls, StdCtrls, cxGridExportLink, dxCore,
    ExtCtrls, Grids, DBGrids, ComCtrls, Buttons, Mask,
    cxControls, cxContainer, cxEdit, System.strUtils, cxGridDBDataDefinitions,
    cxTextEdit, cxMaskEdit, cxDBEdit, cxNavigator, cxLookAndFeelPainters,
    cxButtons, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
    cxDBLookupComboBox, cxImage, jpeg, cxCalendar, cxStyles, cxCustomData,
    cxGraphics, cxFilter, cxData, cxDataStorage, cxDBData,
    cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridLevel,
    cxClasses, cxGridCustomView, cxGrid, cxGridCardView, cxSpinEdit,
    cxGridDBCardView, cxGridBandedTableView, cxGridDBBandedTableView,
    cxRadioGroup, cxPc, dxShellDialogs, inLibUser,
    cxGroupBox, cxLabel, cxListBox, System.NetEncoding,
    inLibPerfilesUsuarioIntf,
    cxCheckBox, cxMemo, cxCurrencyEdit, ExtDlgs, OleServer, AxCtrls,
    OleCtrls, DBOleCtl, cxLookAndFeels, System.Generics.Collections, TypInfo,
    inLibLogIntf, inLibConfigCamposIntf,
    inLibParametrosIntf, Uni, inLibFormatoExcel,
    inLibFacturas, inLibFacturasLecturasIntf;
  procedure BusqAllGrid(var AdbTvGen: TcxGridDBTableView;
                        AsDatoBusq: String);
  procedure GrabarGrids(frmMto: TComponent);
  function CheckOpenGrids(frmMto: TComponent):Boolean;
  procedure CancelarGrids(ApcPrincipal:TcxPageControl);
  procedure CancelarGridsFormulario(AFormulario: TComponent);
  procedure SetCaseTcxTextProperty(oControl: TComponent;
                                   AsCase: TEditCharCase);
//  procedure SaveColumnsStateActiveWindow;
//  procedure RecoverColumnsStateActiveWindow;
//  procedure ResetColumnsStateActiveWindow;
  procedure RestaurarFocoGrid(AcxgrdtvVista: TcxCustomGridTableView;
                              var oPerfilDic: TProfileDicc;
                              const ARegistroLog: IRegistroLog);
  procedure CollectSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                        const sName: string;
                                        const AsProfile: string;
                                        const APerfilesUsuario:
                                          IEscritorPerfilesUsuario;
                                        AList: TPerfilList;
                                        const ARegistroLog: IRegistroLog);

  procedure GetSettingsColumn(AcxgrdtvVista: TcxCustomGridTableView;
                              sName: String;
                              Sender: TComponent;
                              const APerfilesUsuario:
                                IEscritorPerfilesUsuario;
                              sUserGroup:String = 'Todos');
  procedure GetSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                      sName: String;
                                      Sender: TComponent;
                                      const APerfilesUsuario:
                                        IEscritorPerfilesUsuario;
                                      AsProfile: String);
  procedure PonerAnchosTitulos( AcxgrdtvVista: TcxCustomGridTableView;
                                AsDes: string;
                                var oPerfilDic: TProfileDicc;
                                const AConfiguracionCampos:
                                  IConfiguracionCampos;
                                const ARegistroLog: IRegistroLog);
  // Asigna PropertiesClass a las columnas del view en funcion del prefijo
  // del campo, siguiendo la convencion del LIBRO_DE_ESTILO_BBDD.md §3.2.
  // Mapeo:
  //   PRECIO_  / TOTAL_ / IMPORTE_  -> TcxCurrencyEditProperties (€)
  //   PORCENTAJE_                   -> TcxCurrencyEditProperties (%)
  //   VALOR_   / CANTIDAD_          -> TcxCurrencyEditProperties (decimal)
  //   ESxxx (con TField varchar(1)) -> TcxCheckBoxProperties (S/N)
  // No toca columnas que ya traigan un PropertiesClassName distinto de
  // vacio o TcxTextEditProperties (respeta lo del .dfm). NUMERO_/LINEA_/
  // CONTADOR_ son varchar en BBDD (salen como texto, no necesitan
  // properties); ORDEN_ es int (cxGrid usa TcxSpinEditProperties por
  // defecto); FECHA_/INSTANTE_ son date/datetime (cxGrid usa
  // TcxDateEditProperties por defecto). Por eso quedan fuera.
  procedure AplicarPropertiesPorPrefijo(AView: TcxCustomGridTableView);
  // Autoajuste con margen DPI para texto, tambien en vistas no visibles.
  // Conserva los limites explicitos, los editores compactos y AutoWidth.
  procedure AplicarBestFitConMargen(AVista: TcxCustomGridTableView);
  procedure ExportarExcel(
                          const AParametrosApp: IParametrosAplicacion;
                          AcxGrd: TcxGrid;
                          AsNomFile: string;
                          AFormatoNativo: Boolean = True);
  procedure BusqEnTodoElGrid(AGrid: TcxGrid; AsDatoBusq: String);
  procedure GridRecalc(AConexion: TUniConnection;
                       const ARepositorioLecturas:
                         IRepositorioLecturasFactura;
                       Sender: TObject;
                       View: TcxGridDBTableView;
                       AcdsLineas, AcdsCabecera: TDataSet;
                       AOnUpdateTotal:
                         TActualizarTotalFacturaEvent = nil;
                       AAlcance:
                         TAlcanceRecalculoFactura =
                           arfLineaYDocumento);
  function GetDBDataController(
    AView: TcxCustomGridTableView): TcxGridDBDataController;
  function GetItemFieldName(AItem: TcxCustomGridTableItem): string;
  // Crea sólo las columnas para los Fields del dataset que aún no tengan
  // columna en la vista (comparación por FieldName, case-insensitive).
  // Devuelve el número de columnas nuevas creadas. Sustituye a la antigua
  // llamada directa a DataController.CreateAllItems, que duplicaba todas
  // las columnas en cada apertura del form con oCreateItems='True'.
  function CrearItemsFaltantes(
    AView: TcxCustomGridTableView;
    const ARegistroLog: IRegistroLog): Integer;
  // Numera las pestañas visibles según su orden real (&1_, &2_...) para
  // Alt+número. Quita antes el prefijo que traiga el DFM o la traducción.
  procedure NumerarPestanasAtajo(APestanas: TcxPageControl);

implementation

uses
  inLibMensajesVcl,
  inLibWin,
       inLibMsgComun,
       inLibDatasets,
       inLibCodigosSinBarra,
       inLibDir, uGenericIfThen, cxImageComboBox;

resourcestring
  SCaptionFiltroArchivoExportacion =
    'Archivo %s';

function EsColumnaBestFitCompacta(AColumna: TcxGridColumn): Boolean;
var
  oPropiedades: TcxCustomEditProperties;
begin
  oPropiedades := AColumna.GetProperties;
  Result := (oPropiedades is TcxCustomCheckBoxProperties) or
            (oPropiedades is TcxCustomImageProperties);
  if oPropiedades is TcxCustomImageComboBoxProperties then
    Result := not TcxCustomImageComboBoxProperties(
      oPropiedades).ShowDescriptions;
end;

function AnchoCabeceraBestFit(AColumna: TcxGridColumn;
  ALienzo: TCanvas): Integer;
var
  rParametros: TcxViewParams;
  sLinea: string;
  iAncho: Integer;
begin
  Result := 0;
  if TcxGridTableView(AColumna.GridView).OptionsView.Header then
  begin
    AColumna.Styles.GetHeaderParams(rParametros);
    ALienzo.Font.Assign(rParametros.Font);
    for sLinea in AColumna.Caption.Split([#13, #10]) do
    begin
      iAncho := ALienzo.TextWidth(sLinea);
      if iAncho > Result then
        Result := iAncho;
    end;
  end;
end;

procedure AjustarColumnaBestFit(AColumna: TcxGridColumn;
  ALienzo: TCanvas; AMargen: Integer);
var
  iAncho, iCabecera: Integer;
begin
  if not EsColumnaBestFitCompacta(AColumna) then
  begin
    iAncho := AColumna.Width;
    // DevExpress omite la cabecera cuando la vista aun esta oculta.
    iCabecera := AnchoCabeceraBestFit(AColumna, ALienzo);
    if iCabecera > iAncho then
      iAncho := iCabecera;
    Inc(iAncho, AMargen);
    if (AColumna.BestFitMaxWidth > 0) and
       (iAncho > AColumna.BestFitMaxWidth) then
      iAncho := AColumna.BestFitMaxWidth;
    // Width aplica tambien MinWidth, incluso si supera BestFitMaxWidth.
    AColumna.Width := iAncho;
  end;
end;

procedure AplicarBestFitTablaConMargen(AVista: TcxGridTableView);
const
  MARGEN_BESTFIT_96_DPI = 24;
var
  oMedicion: TBitmap;
  iColumna, iPpi, iMargen: Integer;
begin
  if AVista.OptionsView.ColumnAutoWidth then
    AVista.ApplyBestFit(nil, True, False)
  else if not AVista.IsPattern then
  begin
    iPpi := USER_DEFAULT_SCREEN_DPI;
    if Assigned(AVista.Control) then
      iPpi := AVista.Control.CurrentPPI;
    iMargen := MulDiv(MARGEN_BESTFIT_96_DPI, iPpi,
      USER_DEFAULT_SCREEN_DPI);
    oMedicion := TBitmap.Create;
    try
      // VisibleItems puede estar vacio en niveles ocultos. ActuallyVisible
      // respeta la visibilidad de cada columna sin exigir una vista activa.
      for iColumna := 0 to AVista.ColumnCount - 1 do
        if AVista.Columns[iColumna].ActuallyVisible and
           TcxCustomGridTableItemAccess.CanHorzSize(
             AVista.Columns[iColumna]) then
        begin
          AVista.Columns[iColumna].ApplyBestFit(True, False);
          AjustarColumnaBestFit(AVista.Columns[iColumna],
            oMedicion.Canvas, iMargen);
        end;
    finally
      FreeAndNil(oMedicion);
    end;
  end;
end;

procedure AplicarBestFitConMargen(AVista: TcxCustomGridTableView);
begin
  if Assigned(AVista) then
  begin
    AVista.BeginUpdate;
    try
      // Volver a medir impide acumular el margen en ajustes sucesivos.
      if AVista is TcxGridTableView then
        AplicarBestFitTablaConMargen(TcxGridTableView(AVista))
      else
        AVista.ApplyBestFit(nil, True, False);
    finally
      AVista.EndUpdate;
    end;
  end;
end;

procedure GridRecalc(AConexion: TUniConnection;
                     const ARepositorioLecturas:
                       IRepositorioLecturasFactura;
                     Sender: TObject;
                     View: TcxGridDBTableView;
                     AcdsLineas, AcdsCabecera: TDataSet;
                     AOnUpdateTotal:
                       TActualizarTotalFacturaEvent = nil;
                     AAlcance:
                       TAlcanceRecalculoFactura =
                         arfLineaYDocumento);
var
  Edit: TcxCustomEdit;
  Column: TcxGridDBColumn;
  FieldName: string;
  ValoEditado: Variant;
begin
  ValoEditado := null;
  if (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    // El editor in-place del grid puede llegar aqui sin Parent asignado
    // (transicion de celda, cierre de edicion...). PostEditValue invoca
    // HandleNeeded internamente y lanza EInvalidOperation 'no tiene
    // ventana principal' cuando Parent = nil. Si no esta parentado, dejamos
    // ValoEditado en null y el fallback de mas abajo lee del dataset.
    if Assigned(Edit.Parent) then
    begin
      Edit.PostEditValue;
      ValoEditado := Edit.EditValue;
    end;
  end;
  if (View.Controller.FocusedColumn <> nil) and
     (View.Controller.FocusedColumn is TcxGridDBColumn) then
  begin
    Column := TcxGridDBColumn(View.Controller.FocusedColumn);
    FieldName := Column.DataBinding.FieldName;
    if VarIsNull(ValoEditado) or (not VarIsNumeric(ValoEditado)) then
    begin
      FieldName := 'PRECIO_SALIDA_FACLIN';
      if AcdsLineas.FindField(FieldName) <> nil then
        ValoEditado := AcdsLineas.FieldByName(FieldName).Value
      else
        ValoEditado := 0;
    end;
    if AAlcance = arfSoloLinea then
    begin
      RecalcularLineaFactura(
        AcdsLineas,
        AcdsCabecera,
        FieldName,
        ValoEditado);
    end
    else
    begin
      ActualizarLineaFactura(
        AConexion,
        ARepositorioLecturas,
        AcdsLineas,
        AcdsCabecera,
        FieldName,
        ValoEditado,
        AOnUpdateTotal);
    end;
  end;
end;

procedure ExportarExcel(
  const AParametrosApp: IParametrosAplicacion;
  AcxGrd: TcxGrid;
  AsNomFile: string;
  AFormatoNativo: Boolean);
var
  saveDialog: TFileSaveDialog;
  oFormato: TFormatoExcel;
  oTipoFichero: TFileTypeItem;
  sExt: string;
begin
  oFormato := FormatoExcelDesde(
    AParametrosApp.GetString(CLAVE_FORMATO_EXCEL, VALOR_FORMATO_DEFECTO));
  sExt := ExtensionFormato(oFormato);
  saveDialog := TFileSaveDialog.Create(nil);
  try
    saveDialog.Title := STituloGuardarListadoExcel;
    saveDialog.DefaultFolder := AParametrosApp.GetPath('appDirExcel');
    saveDialog.DefaultExtension := sExt;
    oTipoFichero := saveDialog.FileTypes.Add;
    oTipoFichero.DisplayName :=
      Format(SCaptionFiltroArchivoExportacion, [sExt]);
    oTipoFichero.FileMask := '*.' + sExt;
    saveDialog.FileName := AsNomFile;
    if saveDialog.Execute then
    begin
      if oFormato = feXls then
        ExportGridToExcel(saveDialog.FileName, AcxGrd,
          True, True, AFormatoNativo)
      else
        ExportGridToXLSX(saveDialog.FileName, AcxGrd,
          True, True, AFormatoNativo);
    end;
  finally
    FreeAndNil(saveDialog);
  end;
end;

// Helpers para soportar tanto TcxGridDBTableView como TcxGridDBBandedTableView
// (sus columnas son TcxGridDBColumn / TcxGridDBBandedColumn, ambas con
// DataBinding tipo TcxGridItemDBDataBinding).
function GetItemFieldName(AItem: TcxCustomGridTableItem): string;
begin
  Result := '';
  if (AItem <> nil) and (AItem.DataBinding <> nil) and
     (AItem.DataBinding is TcxGridItemDBDataBinding) then
    Result := TcxGridItemDBDataBinding(AItem.DataBinding).FieldName;
end;

function GetDBDataController(
  AView: TcxCustomGridTableView): TcxGridDBDataController;
begin
  if (AView <> nil) and (AView.DataController is TcxGridDBDataController) then
    Result := TcxGridDBDataController(AView.DataController)
  else
    Result := nil;
end;

function CamposClaveDisponibles(ADataSet: TDataSet;
                                const ACamposClave: string): Boolean;
var
  Campos :TStringList;
  i      :Integer;
  sCampo :string;
begin
  Result := Assigned(ADataSet) and (Trim(ACamposClave) <> '');
  if Result then
  begin
    Campos := TStringList.Create;
    try
      Campos.StrictDelimiter := True;
      Campos.Delimiter := ';';
      Campos.DelimitedText := ACamposClave;
      i := 0;
      while Result and (i < Campos.Count) do
      begin
        sCampo := Trim(Campos[i]);
        Result := (sCampo <> '') and Assigned(ADataSet.FindField(sCampo));
        Inc(i);
      end;
    finally
      FreeAndNil(Campos);
    end;
  end;
end;

function CrearItemsFaltantes(
  AView: TcxCustomGridTableView;
  const ARegistroLog: IRegistroLog): Integer;
var
  oCtrl       : TcxGridDBDataController;
  oDataSet    : TDataSet;
  oExistentes : TDictionary<string, Boolean>;
  i           : Integer;
  sField      : string;
  oCol        : TcxCustomGridTableItem;
begin
  Result := 0;
  oCtrl := GetDBDataController(AView);
  if (oCtrl <> nil) and Assigned(oCtrl.DataSource) then
  begin
    oDataSet := oCtrl.DataSource.DataSet;
    if Assigned(oDataSet) then
    begin
      oExistentes := TDictionary<string, Boolean>.Create;
      try
        // Recolectar FieldName ya presentes en la vista (case-insensitive)
        for i := 0 to AView.ItemCount - 1 do
        begin
          sField := GetItemFieldName(AView.Items[i]);
          if sField <> '' then
            oExistentes.AddOrSetValue(UpperCase(sField), True);
        end;
        // Crear sólo las columnas para los Fields que no estén ya
        for i := 0 to oDataSet.FieldCount - 1 do
        begin
          sField := oDataSet.Fields[i].FieldName;
          if not oExistentes.ContainsKey(UpperCase(sField)) then
          begin
            oCol := nil;
            if AView is TcxGridDBBandedTableView then
              oCol := TcxGridDBBandedTableView(AView).CreateColumn
            else if AView is TcxGridDBTableView then
              oCol := TcxGridDBTableView(AView).CreateColumn;
            if (oCol <> nil) and (oCol.DataBinding <> nil) and
               (oCol.DataBinding is TcxGridItemDBDataBinding) then
            begin
              TcxGridItemDBDataBinding(oCol.DataBinding).FieldName := sField;
              oExistentes.AddOrSetValue(UpperCase(sField), True);
              Inc(Result);
            end;
          end;
        end;
      finally
        FreeAndNil(oExistentes);
      end;
    end;
  end;
  ARegistroLog.RegistrarInformacion(
    Format(
      'CrearItemsFaltantes: vista=%s creadas=%d items_total=%d',
      [AView.Name, Result, AView.ItemCount]));
end;

// Helpers locales para AplicarPropertiesPorPrefijo
function EsCampoBooleanoSN(AField: TField): Boolean;
begin
  // Booleano S/N de ViraCash: varchar(1). En UniDAC puede mapear a
  // ftString o ftFixedChar. En ambos casos Size=1.
  Result := Assigned(AField) and
            (AField.DataType in [ftString, ftFixedChar, ftWideString,
                                 ftFixedWideChar]) and
            (AField.Size = 1);
end;

procedure SetCurrencyProps(ACol: TcxGridDBColumn;
                           const AFormato: string);
var
  cp: TcxCurrencyEditProperties;
begin
  ACol.PropertiesClass := TcxCurrencyEditProperties;
  cp := TcxCurrencyEditProperties(ACol.Properties);
  cp.DisplayFormat               := AFormato;
  cp.UseDisplayFormatWhenEditing := True;
end;

procedure SetCheckBoxProps(ACol: TcxGridDBColumn);
var
  cb: TcxCheckBoxProperties;
begin
  ACol.PropertiesClass := TcxCheckBoxProperties;
  cb := TcxCheckBoxProperties(ACol.Properties);
  cb.ValueChecked   := 'S';
  cb.ValueUnchecked := 'N';
  cb.ValueGrayed    := '';
  cb.NullStyle      := nssUnchecked;
end;

procedure AplicarPropertiesPorPrefijo(AView: TcxCustomGridTableView);
const
  // Prefijos monetarios (€)
  PRE_DINERO: array[0..2] of string = ('PRECIO_', 'TOTAL_', 'IMPORTE_');
  // Prefijo porcentaje (%)
  PRE_PORC: array[0..0] of string = ('PORCENTAJE_');
  // Prefijos numericos sin moneda
  PRE_NUM: array[0..1] of string = ('VALOR_', 'CANTIDAD_');
  // Formatos con sufijo de moneda/porcentaje fijo
  FMT_EURO  = '#,##0.00 "€";-#,##0.00 "€";0.00 "€"';
  FMT_PORC  = '#,##0.00 "%";-#,##0.00 "%";0.00 "%"';
  FMT_NUM   = '#,##0.##;-#,##0.##;0';

  function CampoEmpiezaPor(const AField: string;
                           const APrefijos: array of string): Boolean;
  var
    p: string;
  begin
    Result := False;
    for p in APrefijos do
      if (not Result) and StartsText(p, AField) then
        Result := True;
  end;

  function EsPrefijoES(const AField: string): Boolean;
  begin
    // Booleano: 'ES' seguido de mayuscula (ESACTIVO, ESDEFECTO, ESVIP...).
    // No queremos confundir con campos que casualmente empiecen por 'es'
    // pero no sean booleanos. Adicionalmente se valida con
    // EsCampoBooleanoSN que el tipo subyacente sea varchar(1).
    Result := (Length(AField) >= 3) and
              (UpCase(AField[1]) = 'E') and
              (UpCase(AField[2]) = 'S') and
              CharInSet(AField[3], ['A'..'Z']);
  end;

var
  i: Integer;
  oItem: TcxCustomGridTableItem;
  oCol: TcxGridDBColumn;
  sField, sProp: string;
  oField: TField;
  oDBCtrl: TcxGridDBDataController;
  bAplicable: Boolean;
begin
  if AView <> nil then
  begin
    oDBCtrl := GetDBDataController(AView);
    AView.BeginUpdate;
    try
      for i := 0 to AView.ItemCount - 1 do
      begin
        oItem := AView.Items[i];
        if (oItem is TcxGridDBColumn) then
        begin
          oCol := TcxGridDBColumn(oItem);
          sField := GetItemFieldName(oCol);
          sProp := oCol.PropertiesClassName;
          // Solo aplicamos si la columna no tiene properties especificas
          // ya asignadas (no pisamos lo que venga del .dfm o de otra
          // rutina externa).
          bAplicable := (sField <> '') and
                        ((sProp = '') or (sProp = 'TcxTextEditProperties'));
          if bAplicable then
          begin
            if EsPrefijoES(sField) then
            begin
              // ESxxx -> CheckBox S/N (solo si el TField es varchar(1))
              oField := nil;
              if (oDBCtrl <> nil) and Assigned(oDBCtrl.DataSet) then
                oField := oDBCtrl.DataSet.FindField(sField);
              if EsCampoBooleanoSN(oField) then
                SetCheckBoxProps(oCol);
            end
            else if CampoEmpiezaPor(sField, PRE_DINERO) then
              SetCurrencyProps(oCol, FMT_EURO)
            else if CampoEmpiezaPor(sField, PRE_PORC) then
              SetCurrencyProps(oCol, FMT_PORC)
            else if CampoEmpiezaPor(sField, PRE_NUM) then
              SetCurrencyProps(oCol, FMT_NUM);
          end;
        end;
      end;
    finally
      AView.EndUpdate;
    end;
  end;
end;

procedure GetSettingsColumn(AcxgrdtvVista: TcxCustomGridTableView;
                            sName: String;
                            Sender: TComponent;
                            const APerfilesUsuario:
                              IEscritorPerfilesUsuario;
                            sUserGroup:String = 'Todos');
var
  i: Integer;
  oItem: TcxGridColumn ;
  sVistaName, sColumnName, sValue: string;
begin
  sVistaName := AcxgrdtvVista.Name;
  for i := 0 to AcxgrdtvVista.ItemCount - 1 do
  begin
    oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
    sColumnName := GetItemFieldName(oItem);
    if sColumnName <> '' then
    begin
    if (oItem.Visible) then
      sValue := 'True'
    else
      sValue := 'False';
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Visible',
                             sValue);
    sValue := IntToStr(oItem.Index);
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Index',
                             sValue);
    sValue := IntToStr(oItem.Width);
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Width',
                             sValue);
    sValue := oItem.Caption;
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Caption',
                             sValue);
    if oItem is TcxGridDBBandedColumn then
    begin
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_BandIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_ColIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_RowIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
    end;
    end;
  end;
end;

procedure RestaurarFocoGrid(AcxgrdtvVista: TcxCustomGridTableView;
                            var oPerfilDic: TProfileDicc;
                            const ARegistroLog: IRegistroLog);
var
  sFocusedIDString: string;
  sCamposClave: string;
  vLocateValues: Variant;
  oDBDataCtrl: TcxGridDBDataController;
  bFound: Boolean;
begin
  oDBDataCtrl := GetDBDataController(AcxgrdtvVista);
  if (oDBDataCtrl = nil) or
     not Assigned(oDBDataCtrl.DataSet) or
     not oDBDataCtrl.DataSet.Active then
  begin
    ARegistroLog.RegistrarInformacion(
      Format('RestaurarFocoGrid: vista=%s SKIP (dataset no activo)',
      [AcxgrdtvVista.Name]));
  end
  else
  begin
    sCamposClave := oDBDataCtrl.KeyFieldNames;
    if (sCamposClave <> '') and
       (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
    begin
      ARegistroLog.RegistrarAviso(
        Format('RestaurarFocoGrid: vista=%s clave="%s" ' +
        'no disponible en la consulta activa',
        [AcxgrdtvVista.Name, sCamposClave]));
      oDBDataCtrl.KeyFieldNames := '';
      sCamposClave := '';
    end;
    if sCamposClave = '' then
    begin
      sCamposClave :=
        inLibDatasets.ObtenerClavePrimaria(
          oDBDataCtrl.DataSet);
      if (sCamposClave <> '') and
         CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave) then
        oDBDataCtrl.KeyFieldNames := sCamposClave;
      if (sCamposClave <> '') and
         (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
      begin
        ARegistroLog.RegistrarAviso(
          Format('RestaurarFocoGrid: vista=%s clave="%s" ' +
          'descartada porque faltan campos',
          [AcxgrdtvVista.Name, sCamposClave]));
        sCamposClave := '';
      end;
    end;
    if sCamposClave = '' then
    begin
      ARegistroLog.RegistrarAviso(
        Format('RestaurarFocoGrid: vista=%s SKIP (sin clave primaria)',
        [AcxgrdtvVista.Name]));
    end
    else
    begin
      sFocusedIDString := GetPerfilValueDef(oPerfilDic,
        AcxgrdtvVista.Name + '_FocusedID', '');
      ARegistroLog.RegistrarInformacion(
        Format('RestaurarFocoGrid: vista=%s clave="%s" ' +
        'valorGuardado="%s"',
        [AcxgrdtvVista.Name, sCamposClave, sFocusedIDString]));
      if sFocusedIDString <> '' then
      begin
        vLocateValues := inLibDatasets.StrToKeyValues(
          sFocusedIDString, sCamposClave);
        bFound := oDBDataCtrl.DataSet.Locate(
          sCamposClave, vLocateValues, []);
        ARegistroLog.RegistrarInformacion(
          Format('RestaurarFocoGrid: Locate(%s, %s) = %s',
          [sCamposClave, sFocusedIDString, BoolToStr(bFound, True)]));
      end;
    end;
  end;
end;

procedure AnadirValorPerfilVista(AList: TPerfilList;
  const AsProfile, sName, ASubclave, AValor: string);
var
  oItem: TPerfilItem;
begin
  oItem.UserGroup := AsProfile;
  oItem.KeyPerfil := sName;
  oItem.SubKey := ASubclave;
  oItem.Value := AValor;
  // El ValueText del record lo dejamos vacío para el batch normal
  AList.Add(oItem);
end;

procedure RecogerFocoVistaPerfil(AVista: TcxCustomGridTableView;
  AList: TPerfilList; const AsProfile, sName: string;
  const ARegistroLog: IRegistroLog);
var
  oDatos: TcxGridDBDataController;
  sCamposClave: string;
  vValoresClave: Variant;
begin
  oDatos := GetDBDataController(AVista);
  // Obtenemos la clave primaria disponible en la consulta.
  sCamposClave := oDatos.KeyFieldNames;
  if (sCamposClave <> '') and
     (not CamposClaveDisponibles(oDatos.DataSet, sCamposClave)) then
  begin
    ARegistroLog.RegistrarAviso(
      Format('CollectSettingsColumnProfile: vista=%s ' +
      'clave="%s" no disponible en la consulta activa',
      [AVista.Name, sCamposClave]));
    oDatos.KeyFieldNames := '';
    sCamposClave := '';
  end;
  if sCamposClave = '' then
  begin
    sCamposClave := inLibDatasets.ObtenerClavePrimaria(oDatos.DataSet);
    if (sCamposClave <> '') and
       CamposClaveDisponibles(oDatos.DataSet, sCamposClave) then
      oDatos.KeyFieldNames := sCamposClave;
    if (sCamposClave <> '') and
       (not CamposClaveDisponibles(oDatos.DataSet, sCamposClave)) then
    begin
      ARegistroLog.RegistrarAviso(
        Format('CollectSettingsColumnProfile: vista=%s ' +
        'clave="%s" descartada porque faltan campos',
        [AVista.Name, sCamposClave]));
      sCamposClave := '';
    end;
  end;
  if sCamposClave <> '' then
  begin
    vValoresClave := oDatos.GetKeyFieldsValues;
    if not VarIsNull(vValoresClave) and not VarIsEmpty(vValoresClave) then
      AnadirValorPerfilVista(AList, AsProfile, sName,
        AVista.Name + '_FocusedID',
        inLibDatasets.KeyValuesToStr(vValoresClave));
  end;
end;

procedure GrabarFiltroVistaPerfil(AVista: TcxCustomGridTableView;
  const AsProfile, sName: string;
  const APerfilesUsuario: IEscritorPerfilesUsuario);
var
  oFlujo: TMemoryStream;
  oTexto: TStringStream;
begin
  if AVista.DataController.Filter.IsEmpty then
    APerfilesUsuario.GrabarPerfil(
      AsProfile, sName, AVista.Name + '_Filtro', '', '')
  else
  begin
    oFlujo := TMemoryStream.Create;
    oTexto := TStringStream.Create('');
    try
      AVista.DataController.Filter.SaveToStream(oFlujo);
      oFlujo.Position := 0;
      TNetEncoding.Base64.Encode(oFlujo, oTexto);
      APerfilesUsuario.GrabarPerfil(
        AsProfile, sName, AVista.Name + '_Filtro', '',
        oTexto.DataString);
    finally
      FreeAndNil(oFlujo);
      FreeAndNil(oTexto);
    end;
  end;
end;

procedure CollectSettingsColumnProfile(AcxgrdtvVista: TcxCustomGridTableView;
                                        const sName: string;
                                        const AsProfile: string;
                                        const APerfilesUsuario:
                                          IEscritorPerfilesUsuario;
                                        AList: TPerfilList;
                                        const ARegistroLog: IRegistroLog);
var
  i: Integer;
  oItem: TcxGridColumn;
  sColumnName, sPrefix: string;
  oDBDataCtrl: TcxGridDBDataController;

  procedure Add(const aSub, aVal: string);
  begin
    AnadirValorPerfilVista(AList, AsProfile, sName, aSub, aVal);
  end;

begin
  oDBDataCtrl := GetDBDataController(AcxgrdtvVista);
  if (oDBDataCtrl <> nil) and Assigned(oDBDataCtrl.DataSet) then
  begin
    // Solo el foco necesita la consulta abierta. Las pestañas de carga
    // perezosa (Tarifas de Artículos) la cierran al salir: si las columnas
    // dependieran de ella, el perfil quedaba marcado para aplicarse y sin
    // columnas, y al restaurarlo salían visibles todas las del diseño.
    if oDBDataCtrl.DataSet.Active then
      RecogerFocoVistaPerfil(AcxgrdtvVista, AList, AsProfile, sName,
        ARegistroLog);
    // Recolección de propiedades de columnas para el lote.
    for i := 0 to AcxgrdtvVista.ItemCount - 1 do
    begin
      oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
      sColumnName := GetItemFieldName(oItem);
      if sColumnName <> '' then
      begin
        sPrefix := AcxgrdtvVista.Name + '_' + sColumnName + '_';
        Add(sPrefix + 'Visible',
          TGenUtils.IfThen<String>(oItem.Visible, 'True', 'False'));
        Add(sPrefix + 'Index', IntToStr(oItem.Index));
        Add(sPrefix + 'Width', IntToStr(oItem.Width));
        Add(sPrefix + 'Caption', oItem.Caption);
        Add(sPrefix + 'SortOrder', IntToStr(Ord(oItem.SortOrder)));
        Add(sPrefix + 'SortIndex', IntToStr(oItem.SortIndex));
        if oItem is TcxGridDBBandedColumn then
        begin
          Add(sPrefix + 'BandIndex',
            IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
          Add(sPrefix + 'ColIndex',
            IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
          Add(sPrefix + 'RowIndex',
            IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
        end;
      end;
    end;
    GrabarFiltroVistaPerfil(AcxgrdtvVista, AsProfile, sName,
      APerfilesUsuario);
  end;
end;

procedure GetSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                    sName: String;
                                    Sender: TComponent;
                                    const APerfilesUsuario:
                                      IEscritorPerfilesUsuario;
                                    AsProfile: String);
var
  i: Integer;
  oItem: TcxGridColumn;
  sVistaName, sColumnName, sValue: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
begin
  sVistaName := AcxgrdtvVista.Name;
  for i := 0 to AcxgrdtvVista.ItemCount - 1 do
  begin
    oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
    sColumnName := GetItemFieldName(oItem);
    if sColumnName <> '' then
    begin

    // 1. Guardar Visibilidad
    if (oItem.Visible) then sValue := 'True' else sValue := 'False';
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Visible',
                             sValue);

    // 2. Guardar Orden (Mantenemos Index como lo tenías)
    sValue := IntToStr(oItem.Index);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Index',
                             sValue);

    // 3. Guardar Ancho
    sValue := IntToStr(oItem.Width);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Width',
                             sValue);

    // 4. Guardar Caption
    sValue := oItem.Caption;
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Caption',
                             sValue);

    // 5. Guardar Ordenación de datos (Sorting)
    sValue := IntToStr(Ord(oItem.SortOrder));
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_SortOrder',
                             sValue);

    sValue := IntToStr(oItem.SortIndex);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_SortIndex',
                             sValue);

    // 6. Si es columna banded, guardar tambien la posicion en band
    if oItem is TcxGridDBBandedColumn then
    begin
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_BandIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_ColIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_RowIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
    end;
    end;
  end;
  // 6. GUARDAR EL FILTRO DE LA VISTA COMPLETA (Binario -> Base64)
  LStream := TMemoryStream.Create;
  BStream := TStringStream.Create('');
  try
    // Extraemos el filtro del grid al stream de memoria
    AcxgrdtvVista.DataController.Filter.SaveToStream(LStream);
    LStream.Position := 0;

    // Lo codificamos a Base64 para que sea un texto seguro (sin caracteres
    // raros)
    TNetEncoding.Base64.Encode(LStream, BStream);
    sValue := BStream.DataString;

    // Lo guardamos en tu perfil con la clave terminada en "_Filtro"
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             AcxgrdtvVista.Name + '_Filtro',
                             sValue);

    // Guardar el ancho general del componente TcxGrid contenedor
    if Assigned(AcxgrdtvVista.Control) then
    begin
      sValue := IntToStr(AcxgrdtvVista.Control.Width);
      APerfilesUsuario.GrabarPerfil(AsProfile,
                               sName,
                               AcxgrdtvVista.Name + '_GridTotalWidth',
                               sValue);
    end;
  finally
    FreeAndNil(LStream);
    FreeAndNil(BStream);
  end;
end;

procedure RestaurarAparienciaColumnas(
  AView: TcxCustomGridTableView;
  const ANombreVista: string;
  var APerfil: TProfileDicc;
  const AConfiguracionCampos: IConfiguracionCampos);
var
  oItem: TcxGridColumn;
  iItem: Integer;
  sCampo: string;
  sSubClave: string;
  sValor: string;
begin
  for iItem := 0 to AView.ItemCount - 1 do
  begin
    oItem := AView.Items[iItem] as TcxGridColumn;
    sCampo := GetItemFieldName(oItem);
    if sCampo <> '' then
    begin
      sSubClave := ANombreVista + '_' + sCampo;
      // La visibilidad de una columna que el usuario no puede personalizar
      // la decide el formulario: un perfil antiguo, sin ella, la mostraria.
      if oItem.VisibleForCustomization then
        oItem.Visible := SameText(
          GetPerfilSubKeyValueDef(
            APerfil, sSubClave, 'Visible', 'True'), 'True');
      sValor := GetPerfilSubKeyValueDef(
        APerfil, sSubClave, 'Caption', '');
      if sValor <> '' then
        oItem.Caption := sValor
      else if Assigned(AConfiguracionCampos) and
              AConfiguracionCampos.Cargada and
              (AConfiguracionCampos.ObtenerTitulo(sCampo) <> '') then
        oItem.Caption := AConfiguracionCampos.ObtenerTitulo(sCampo);
      sValor := GetPerfilSubKeyValueDef(
        APerfil, sSubClave, 'Width', '');
      if sValor <> '' then
        oItem.Width := StrToIntDef(sValor, oItem.Width)
      else if Assigned(AConfiguracionCampos) and
              AConfiguracionCampos.Cargada and
              (AConfiguracionCampos.ObtenerAncho(sCampo) > 0) then
        oItem.Width := AConfiguracionCampos.ObtenerAncho(sCampo);
      oItem.SortOrder := TcxDataSortOrder(StrToIntDef(
        GetPerfilSubKeyValueDef(
          APerfil, sSubClave, 'SortOrder', '0'), 0));
      if Ord(oItem.SortOrder) <> 0 then
        oItem.SortIndex := StrToIntDef(
          GetPerfilSubKeyValueDef(
            APerfil, sSubClave, 'SortIndex', '-1'), -1);
    end;
  end;
end;

procedure RestaurarIndicesColumnas(
  AView: TcxCustomGridTableView;
  const ANombreVista: string;
  var APerfil: TProfileDicc;
  const ARegistroLog: IRegistroLog);
var
  oItem: TcxGridColumn;
  iItem: Integer;
  iIndice: Integer;
  iMaximo: Integer;
  sCampo: string;
  sValor: string;
begin
  iMaximo := AView.ItemCount - 1;
  if not (AView is TcxGridDBBandedTableView) then
  begin
    for iItem := 0 to AView.ItemCount - 1 do
    begin
      oItem := AView.Items[iItem] as TcxGridColumn;
      sCampo := GetItemFieldName(oItem);
      if sCampo <> '' then
      begin
        sValor := GetPerfilSubKeyValueDef(
          APerfil, ANombreVista + '_' + sCampo, 'Index', '');
        if sValor <> '' then
        begin
          iIndice := StrToIntDef(sValor, oItem.Index);
          if iIndice > iMaximo then
          begin
            ARegistroLog.RegistrarAviso(Format(
              '  columna %s: Index guardado=%d > max=%d, ajustado',
              [sCampo, iIndice, iMaximo]));
            iIndice := iMaximo;
          end;
          if iIndice < 0 then
            iIndice := 0;
          oItem.Index := iIndice;
        end;
      end;
    end;
  end;
end;

procedure RestaurarPosicionColumnaBanded(
  AColumna: TcxGridDBBandedColumn;
  const ACampo, ASubClave: string;
  var APerfil: TProfileDicc;
  AMaximoBandas: Integer;
  const ARegistroLog: IRegistroLog);
var
  iBanda: Integer;
  iColumna: Integer;
  iFila: Integer;
begin
  iBanda := StrToIntDef(
    GetPerfilSubKeyValueDef(APerfil, ASubClave, 'BandIndex', ''),
    AColumna.Position.BandIndex);
  iColumna := StrToIntDef(
    GetPerfilSubKeyValueDef(APerfil, ASubClave, 'ColIndex', ''),
    AColumna.Position.ColIndex);
  iFila := StrToIntDef(
    GetPerfilSubKeyValueDef(APerfil, ASubClave, 'RowIndex', ''),
    AColumna.Position.RowIndex);
  if (AMaximoBandas > 0) and (iBanda >= AMaximoBandas) then
  begin
    ARegistroLog.RegistrarAviso(Format(
      '  columna banded %s: BandIndex=%d >= bands=%d, ajustado a %d',
      [ACampo, iBanda, AMaximoBandas, AMaximoBandas - 1]));
    iBanda := AMaximoBandas - 1;
  end;
  if iBanda < 0 then
    iBanda := 0;
  if iColumna < 0 then
    iColumna := 0;
  if iFila < 0 then
    iFila := 0;
  ARegistroLog.RegistrarInformacion(Format(
    '  banded %s: band=%d col=%d row=%d',
    [ACampo, iBanda, iColumna, iFila]));
  AColumna.Position.BandIndex := iBanda;
  AColumna.Position.ColIndex := iColumna;
  AColumna.Position.RowIndex := iFila;
end;

procedure RestaurarPosicionesBanded(
  AView: TcxCustomGridTableView;
  const ANombreVista: string;
  var APerfil: TProfileDicc;
  const ARegistroLog: IRegistroLog);
var
  oItem: TcxGridColumn;
  iItem: Integer;
  iMaximoBandas: Integer;
  sCampo: string;
begin
  iMaximoBandas := 0;
  if AView is TcxGridDBBandedTableView then
    iMaximoBandas := TcxGridDBBandedTableView(AView).Bands.Count;
  for iItem := 0 to AView.ItemCount - 1 do
  begin
    oItem := AView.Items[iItem] as TcxGridColumn;
    sCampo := GetItemFieldName(oItem);
    if (sCampo <> '') and (oItem is TcxGridDBBandedColumn) then
      RestaurarPosicionColumnaBanded(
        TcxGridDBBandedColumn(oItem), sCampo,
        ANombreVista + '_' + sCampo, APerfil, iMaximoBandas,
        ARegistroLog);
  end;
end;

procedure RestaurarFiltroColumnas(
  AView: TcxCustomGridTableView;
  const ANombreVista: string;
  var APerfil: TProfileDicc);
var
  oFlujo: TMemoryStream;
  oTexto: TStringStream;
  sFiltroBase64: string;
begin
  sFiltroBase64 := GetPerfilValueTextDef(
    APerfil, ANombreVista + '_Filtro', '');
  if sFiltroBase64 <> '' then
  begin
    oTexto := TStringStream.Create(sFiltroBase64);
    oFlujo := TMemoryStream.Create;
    try
      oTexto.Position := 0;
      System.NetEncoding.TNetEncoding.Base64.Decode(oTexto, oFlujo);
      oFlujo.Position := 0;
      AView.DataController.Filter.LoadFromStream(oFlujo);
    finally
      FreeAndNil(oTexto);
      FreeAndNil(oFlujo);
    end;
  end;
end;

procedure RestaurarAnchoGrid(
  AView: TcxCustomGridTableView;
  var APerfil: TProfileDicc);
var
  sSubClave: string;
begin
  if Assigned(AView.Control) then
  begin
    sSubClave := AView.Name + '_GridTotalWidth';
    AView.Control.Width := StrToIntDef(
      GetPerfilValueDef(APerfil, sSubClave, ''), AView.Control.Width);
  end;
end;

procedure PonerAnchosTitulos(AcxgrdtvVista: TcxCustomGridTableView;
                             AsDes: string;
                             var oPerfilDic: TProfileDicc;
                             const AConfiguracionCampos:
                               IConfiguracionCampos;
                             const ARegistroLog: IRegistroLog);
var
  sNombreVista: string;
begin
  AcxgrdtvVista.BeginUpdate;
  try
    sNombreVista := AcxgrdtvVista.Name;
    ARegistroLog.RegistrarInformacion(
      Format('PonerAnchosTitulos: vista=%s items=%d form=%s',
        [sNombreVista, AcxgrdtvVista.ItemCount, AsDes]));
    RestaurarAparienciaColumnas(
      AcxgrdtvVista, sNombreVista, oPerfilDic, AConfiguracionCampos);

    RestaurarIndicesColumnas(
      AcxgrdtvVista, sNombreVista, oPerfilDic, ARegistroLog);

    RestaurarPosicionesBanded(
      AcxgrdtvVista, sNombreVista, oPerfilDic, ARegistroLog);

    RestaurarFiltroColumnas(
      AcxgrdtvVista, sNombreVista, oPerfilDic);
    RestaurarAnchoGrid(AcxgrdtvVista, oPerfilDic);
  finally
    AcxgrdtvVista.EndUpdate;
  end;
end;

procedure BusqAllGrid(var AdbTvGen: TcxGridDBTableView; AsDatoBusq: String);
const
  CMaxLongitudBusquedaGlobal = 128;
var
  i: Integer;
  oListaBusqueda: TcxFilterCriteriaItemList;
  oFiltro: TcxDataFilterCriteria;
  sBusqueda: string;
  sVariante: string;
begin
  // Aplicar un filtro hace CheckBrowseMode y puede confirmar la ficha.
  // Una búsqueda automática nunca guarda ni descarta una edición.
  if (AdbTvGen <> nil) and
     (AdbTvGen.DataController.DataSet <> nil) and
     AdbTvGen.DataController.DataSet.Active and
     not (AdbTvGen.DataController.DataSet.State in dsEditModes) then
  begin
    // Los filtros de DevExpress normalizan cada valor de cada columna.
    // Acotar tambien las llamadas que no proceden del editor del formulario.
    sBusqueda := Copy(AsDatoBusq, 1, CMaxLongitudBusquedaGlobal);
    sBusqueda := StringReplace(sBusqueda, #13, ' ', [rfReplaceAll]);
    sBusqueda := StringReplace(sBusqueda, #10, ' ', [rfReplaceAll]);
    if sBusqueda <> ''
    then
    begin
      oFiltro := AdbTvGen.DataController.Filter;
      oFiltro.BeginUpdate;
      oFiltro.Options := oFiltro.Options + [fcoCaseInsensitive];
      try
        oFiltro.Root.Clear;
        oFiltro.Root.BoolOperatorKind := fboAnd;
        oListaBusqueda := oFiltro.Root.AddItemList(fboOr);
          for i := 0 to AdbTvGen.ColumnCount - 1 do
          begin
            if AdbTvGen.Columns[i].DataBinding.Field <> nil then
              if AdbTvGen.Columns[i].DataBinding.Field.DataType in [ftSmallint,
                                                                   ftInteger,
                                                                   ftWord,
                                                                   ftCurrency,
                                                                   ftBCD,
                                                                   ftLargeint,
                                                                   ftFMTBcd,
                                                                   ftLongWord,
                                                                   ftShortint,
                                                                   ftString,
                                                                   ftWideString,
                                                                   ftMemo,
                                                                   ftFmtMemo,
                                                                   ftWideMemo]
            then
            begin
              // Con barra se busca tambien la variante con guion: un codigo
              // legacy '2354/A-158' encuentra '2354-A-158' y un SKU sigue
              // buscandose con su separador.
              for sVariante in VariantesBusquedaSinBarra(sBusqueda) do
                oListaBusqueda.AddItem((AdbTvGen.Columns[i] as TObject),
                  foLike,
                  '%' + sVariante + '%',
                  '%' + sVariante + '%');
            end;
          end;
      finally
        oFiltro.EndUpdate;
      end;
      oFiltro.Active := True;
    end
    else
    begin
      AdbTvGen.DataController.Filter.Root.Clear;
      AdbTvGen.DataController.Filter.Root.BoolOperatorKind := fboAnd;
    end;
  end;
end;

procedure BusqEnTodoElGrid(AGrid: TcxGrid; AsDatoBusq: String);
  procedure AplicarFiltroAVista(AView: TcxGridDBTableView);
  var
    i: Integer;
    bModoTemporal: Boolean; // Unifica Fecha y Hora
    sTextoBuscar: String;
    FieldType: TFieldType;
    oListaBusqueda: TcxFilterCriteriaItemList;
    oFiltro: TcxDataFilterCriteria;
  begin
    if AsDatoBusq = '' then
    begin
      AView.DataController.Filter.Root.Clear;
      AView.DataController.Filter.Root.BoolOperatorKind := fboAnd;
      AView.DataController.Filter.Active := False;
    end
    else
    begin
      bModoTemporal := False;
      sTextoBuscar := AsDatoBusq;
      if Pos('//', AsDatoBusq) > 0 then
      begin
        bModoTemporal := True;
        sTextoBuscar := StringReplace(
          AsDatoBusq, '//', '', [rfReplaceAll]);
      end
      else if Pos('::', AsDatoBusq) > 0 then
      begin
        bModoTemporal := True;
        sTextoBuscar := StringReplace(
          AsDatoBusq, '::', '', [rfReplaceAll]);
      end
      else if (Pos('/', AsDatoBusq) > 0) or
              (Pos(':', AsDatoBusq) > 0) then
        bModoTemporal := True;
      if not (bModoTemporal and (Trim(sTextoBuscar) = '')) then
      begin
        oFiltro := AView.DataController.Filter;
        oFiltro.BeginUpdate;
        try
          oFiltro.Options := oFiltro.Options + [fcoCaseInsensitive];
          oFiltro.Root.Clear;
          oFiltro.Root.BoolOperatorKind := fboAnd;
          oListaBusqueda := oFiltro.Root.AddItemList(fboOr);
        for i := 0 to AView.ColumnCount - 1 do
        begin
          if (AView.Columns[i].DataBinding.Field <> nil) then
          begin
            FieldType := AView.Columns[i].DataBinding.Field.DataType;
            if bModoTemporal then
            begin
              // MODO TEMPORAL: Busca en Fechas, Horas y FechaHoras
              if FieldType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
              begin
                 oListaBusqueda.AddItem((AView.Columns[i] as TObject),
                    foLike,
                    '%' + sTextoBuscar + '%',
                    '%' + sTextoBuscar + '%');
              end;
            end
            else
            begin
              // MODO TEXTO/NUMÉRICO: Lo habitual
              if FieldType in [
                 ftSmallint, ftInteger, ftWord, ftCurrency, ftBCD, ftLargeint,
                 ftFMTBcd, ftLongWord, ftShortint, ftString, ftWideString,
                 ftMemo, ftFmtMemo, ftWideMemo] then
              begin
                oListaBusqueda.AddItem((AView.Columns[i] as TObject),
                  foLike,
                  '%' + sTextoBuscar + '%',
                  '%' + sTextoBuscar + '%');
              end;
            end;
          end;
        end;
        finally
          oFiltro.EndUpdate;
        end;
        oFiltro.Active := True;
      end;
    end;
  end;
  procedure ProcesarNivel(ALevel: TcxGridLevel);
  var
    i: Integer;
  begin
    if (ALevel.GridView <> nil) and (ALevel.GridView is TcxGridDBTableView) then
      AplicarFiltroAVista(TcxGridDBTableView(ALevel.GridView));
    for i := 0 to ALevel.Count - 1 do
      ProcesarNivel(ALevel.Items[i]);
  end;
var
  i: Integer;
begin
  if AGrid <> nil then
  begin
    AGrid.BeginUpdate;
    try
      for i := 0 to AGrid.Levels.Count - 1 do
        ProcesarNivel(AGrid.Levels[i]);
    finally
      AGrid.EndUpdate;
    end;
  end;
end;

procedure CancelarGrids(ApcPrincipal:TcxPageControl);
var
  oPestana: TcxTabSheet;
begin
  if Assigned(ApcPrincipal) and Assigned(ApcPrincipal.ActivePage) then
  begin
    oPestana := ApcPrincipal.ActivePage;
    if oPestana.ControlCount > 0 then
      CancelarGridsFormulario(oPestana.Controls[0]);
  end;
end;

procedure CancelarGridsFormulario(AFormulario: TComponent);
var
  i: Integer;
  iPasada: Integer;
  oVista: TcxGridDBTableView;
  oControlador: TcxGridDBDataController;
  bDetalle: Boolean;
begin
  // Primero los detalles y después sus cabeceras: TDataSet.Cancel de una
  // cabecera avisa a sus detalles (deCheckBrowseMode) antes de su
  // BeforeCancel, y la fila de detalle pendiente se grababa con su
  // validación en vez de descartarse (FZ-ISSUE-624, cajas del almacén).
  for iPasada := 0 to 1 do
  begin
    i := 0;
    while Assigned(AFormulario) and (i < AFormulario.ComponentCount) do
    begin
      if AFormulario.Components[i] is TcxGridDBTableView then
      begin
        oVista := TcxGridDBTableView(AFormulario.Components[i]);
        oControlador := oVista.DataController;
        bDetalle := (oControlador.DataSet <> nil) and
          (oControlador.DataSet.DataSource <> nil);
        if bDetalle = (iPasada = 0) then
        begin
          // FZ-ISSUE-430: cancelar tambien descarta lo tecleado en la
          // celda. Con el editor abierto, la rejilla aceptaba su texto al
          // cancelar el registro y la linea volvia a crearse e intentaba
          // grabarse.
          if oVista.Controller.EditingController.IsEditing then
            oVista.Controller.EditingController.HideEdit(False);
          if (oControlador.DataSource <> nil) and
             (oControlador.DataSet <> nil) and
             (oControlador.DataSet.State in [dsInsert, dsEdit]) then
          begin
            // Por el controlador: la rejilla sale de su modo de insercion
            // y la fila sin grabar deja de verse. El dataset, por si
            // quedara.
            oControlador.Cancel;
            if oControlador.DataSet.State in [dsInsert, dsEdit] then
              oControlador.DataSet.Cancel;
          end;
        end;
      end;
      Inc(i);
    end;
  end;
end;

procedure GrabarGrids(frmMto: TComponent);
var
  i: Integer;
  dsData:TDataSource;
begin
  for i := 0 to frmMto.Componentcount - 1 do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      dsData := (frmMto.Components[i] as
            TcxGridDBTableView).DataController.DataSource;
      // ShowMessage_fza((frmMto.Components[i] as TcxGridDBTableView).Name);
      if (dsData <> nil)
      then
        if ((dsData.DataSet.State = dsInsert) or
            (dsData.DataSet.State = dsEdit)
          )
        then
        begin
          dsData.DataSet.Post;
        end;
    end;
  end;
end;

function CheckOpenGrids(frmMto: TComponent):Boolean;
var
  i: Integer;
  dsData:TDataSource;
  bResul:Boolean;
begin
  bResul:= False;
  i:= 0;
  while ((i<frmMto.Componentcount) and (bResul = False)) do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      dsData := (frmMto.Components[i] as
            TcxGridDBTableView).DataController.DataSource;
      // ShowMessage_fza((frmMto.Components[i] as TcxGridDBTableView).Name);
      if dsData <> nil then
        if (dsData.DataSet <> nil)
        then
          if ((dsData.DataSet.State = dsInsert) or
              (dsData.DataSet.State = dsEdit)) then
          begin
            bResul:= true;
            //Exit;
          end;
    end;
    Inc(i);
  end;
  Result:=bResul;
end;

procedure SetCaseTcxTextProperty(oControl: TComponent; AsCase: TEditCharCase);
var
  i: Integer;
begin
  for i := 0 to oControl.Componentcount - 1 do
  begin
    if oControl.Components[i].ClassNameis('TcxDBTextEdit')
    then
      (oControl.Components[i] as TcxDBTextEdit).Properties.CharCase
        := AsCase;
    if oControl.Components[i].ClassNameis('TcxTextEdit')
    then
      (oControl.Components[i] as TcxTextEdit).Properties.CharCase := AsCase;

    if oControl.Components[i].ClassNameis('TcxDBMaskEdit')
    then
      (oControl.Components[i] as TcxDBMaskEdit).Properties.CharCase
        := AsCase;
    if oControl.Components[i].ClassNameis('TcxDBMemo')
    then
      (oControl.Components[i] as TcxDBMemo).Properties.CharCase := AsCase;
    if oControl.Components[i].ClassNameis('TcxGridDBColumn')
    then
      if (oControl.Components[i] as TcxGridDBColumn).PropertiesClassName =
        ('TcxTextEditProperties')
      then
      begin
        ((oControl.Components[i] as TcxGridDBColumn).Properties as
            TcxTextEditProperties).CharCase := AsCase;
      end
      else
      begin
        // ShowMessage_fza( ((oControl.Components[i] as
        // TcxGridDBColumn).PropertiesClassName));
      end;
  end;
end;

procedure NumerarPestanasAtajo(APestanas: TcxPageControl);
var
  iPestana: Integer;
  iNumero: Integer;
  sTitulo: string;
begin
  iNumero := 0;
  for iPestana := 0 to APestanas.PageCount - 1 do
    if APestanas.Pages[iPestana].TabVisible then
    begin
      Inc(iNumero);
      sTitulo := APestanas.Pages[iPestana].Caption;
      if (Length(sTitulo) >= 3) and (sTitulo[1] = '&') and
         CharInSet(sTitulo[2], ['0'..'9']) and (sTitulo[3] = '_') then
        Delete(sTitulo, 1, 3);
      APestanas.Pages[iPestana].Caption :=
        '&' + IntToStr(iNumero) + '_' + sTitulo;
    end;
end;

end.

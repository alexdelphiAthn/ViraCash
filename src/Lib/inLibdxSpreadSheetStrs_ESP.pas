{******************************************************************************}
{                                                                              }
{  Módulo:       inLibdxSpreadSheetStrs_ESP                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traducción al castellano de los recursos de dxSpreadSheet.                }
{    Sobrescribe los textos de menús, diálogos y mensajes del componente.      }
{******************************************************************************}
unit inLibdxSpreadSheetStrs_ESP;

interface

type
  TProcesarTraduccionDxSpreadSheet = reference to procedure(
    const ANombre: string;
    ARecurso: PResStringRec;
    const ATexto: string);

procedure EnumerarTraduccionesEspanolasDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);
procedure ApplySpanishTranslation;

implementation

uses
  dxCore, cxClasses, dxSpreadSheetStrs;

procedure RegistrarMenuEdicionDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);

  procedure Registrar(
    const ANombre: string;
    ARecurso: PResStringRec;
    const ATexto: string);
  begin
    AProcesar(
      ANombre,
      ARecurso,
      ATexto);
  end;

begin
  if Assigned(AProcesar) then
  begin
    // Menú contextual
    Registrar(
      'sdxBuiltInPopupMenuBringToFront',
      @sdxBuiltInPopupMenuBringToFront,
      'Traer al &frente');
    Registrar(
      'sdxBuiltInPopupMenuClearContents',
      @sdxBuiltInPopupMenuClearContents,
      'Borrar co&ntenido');
    Registrar(
      'sdxBuiltInPopupMenuCopy',
      @sdxBuiltInPopupMenuCopy,
      '&Copiar');
    Registrar(
      'sdxBuiltInPopupMenuCustomizeObject',
      @sdxBuiltInPopupMenuCustomizeObject,
      'Perso&nalizar objeto...');
    Registrar(
      'sdxBuiltInPopupMenuCut',
      @sdxBuiltInPopupMenuCut,
      'Cor&tar');
    Registrar(
      'sdxBuiltInPopupMenuDelete',
      @sdxBuiltInPopupMenuDelete,
      '&Eliminar');
    Registrar(
      'sdxBuiltInPopupMenuDeleteDialog',
      @sdxBuiltInPopupMenuDeleteDialog,
      '&Eliminar...');
    Registrar(
      'sdxBuiltInPopupMenuFormatCells',
      @sdxBuiltInPopupMenuFormatCells,
      '&Formato de celdas...');
    Registrar(
      'sdxBuiltInPopupMenuHide',
      @sdxBuiltInPopupMenuHide,
      '&Ocultar');
    Registrar(
      'sdxBuiltInPopupMenuInsert',
      @sdxBuiltInPopupMenuInsert,
      '&Insertar');
    Registrar(
      'sdxBuiltInPopupMenuInsertDialog',
      @sdxBuiltInPopupMenuInsertDialog,
      '&Insertar...');
    Registrar(
      'sdxBuiltInPopupMenuMergeCells',
      @sdxBuiltInPopupMenuMergeCells,
      '&Combinar celdas');
    Registrar(
      'sdxBuiltInPopupMenuPaste',
      @sdxBuiltInPopupMenuPaste,
      '&Pegar');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecial',
      @sdxBuiltInPopupMenuPasteSpecial,
      'Pegado especial');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialAll',
      @sdxBuiltInPopupMenuPasteSpecialAll,
      '&Pegar todo');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialFormulas',
      @sdxBuiltInPopupMenuPasteSpecialFormulas,
      '&Fórmulas');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialFormulasAndColumnWidths',
      @sdxBuiltInPopupMenuPasteSpecialFormulasAndColumnWidths,
      'Mantener anchos de columna de &origen');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialFormulasAndFormatting',
      @sdxBuiltInPopupMenuPasteSpecialFormulasAndFormatting,
      'Fór&mulas y formato de números');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialFormulasAndStyles',
      @sdxBuiltInPopupMenuPasteSpecialFormulasAndStyles,
      '&Mantener formato de origen');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialShowDialog',
      @sdxBuiltInPopupMenuPasteSpecialShowDialog,
      'Pegado especial...');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialValues',
      @sdxBuiltInPopupMenuPasteSpecialValues,
      '&Valores');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialValuesAndFormatting',
      @sdxBuiltInPopupMenuPasteSpecialValuesAndFormatting,
      'V&alores y formato de números');
    Registrar(
      'sdxBuiltInPopupMenuPasteSpecialValuesAndStyles',
      @sdxBuiltInPopupMenuPasteSpecialValuesAndStyles,
      'Valor&es y formato de origen');
  end;
end;

procedure RegistrarMenuHojaDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);

  procedure Registrar(
    const ANombre: string;
    ARecurso: PResStringRec;
    const ATexto: string);
  begin
    AProcesar(
      ANombre,
      ARecurso,
      ATexto);
  end;

begin
  if Assigned(AProcesar) then
  begin
    Registrar(
      'sdxBuiltInPopupMenuRename',
      @sdxBuiltInPopupMenuRename,
      '&Cambiar nombre...');
    Registrar(
      'sdxBuiltInPopupMenuSendToBack',
      @sdxBuiltInPopupMenuSendToBack,
      'Enviar al &fondo');
    Registrar(
      'sdxBuiltInPopupMenuSplitCells',
      @sdxBuiltInPopupMenuSplitCells,
      'Se&parar celdas');
    Registrar(
      'sdxBuiltInPopupMenuUnhide',
      @sdxBuiltInPopupMenuUnhide,
      '&Mostrar');
    Registrar(
      'sdxBuiltInPopupMenuUnhideDialog',
      @sdxBuiltInPopupMenuUnhideDialog,
      '&Mostrar...');
    Registrar(
      'sdxBuiltInPopupMenuCreateHyperlink',
      @sdxBuiltInPopupMenuCreateHyperlink,
      '&Hipervínculo...');
    Registrar(
      'sdxBuiltInPopupMenuEditHyperlink',
      @sdxBuiltInPopupMenuEditHyperlink,
      'Editar &hipervínculo...');
    Registrar(
      'sdxBuiltInPopupMenuOpenHyperlink',
      @sdxBuiltInPopupMenuOpenHyperlink,
      '&Abrir hipervínculo');
    Registrar(
      'sdxBuiltInPopupMenuRemoveHyperlink',
      @sdxBuiltInPopupMenuRemoveHyperlink,
      '&Quitar hipervínculo');
    Registrar(
      'sdxBuiltInPopupMenuDeleteComment',
      @sdxBuiltInPopupMenuDeleteComment,
      'Eliminar co&mentario');
    Registrar(
      'sdxBuiltInPopupMenuEditComment',
      @sdxBuiltInPopupMenuEditComment,
      '&Editar comentario...');
    Registrar(
      'sdxBuiltInPopupMenuHideComment',
      @sdxBuiltInPopupMenuHideComment,
      '&Ocultar comentario');
    Registrar(
      'sdxBuiltInPopupMenuInsertComment',
      @sdxBuiltInPopupMenuInsertComment,
      'Insertar co&mentario...');
    Registrar(
      'sdxBuiltInPopupMenuShowComment',
      @sdxBuiltInPopupMenuShowComment,
      'M&ostrar comentario');
    Registrar(
      'sdxBuiltInPopupMenuProtectSheet',
      @sdxBuiltInPopupMenuProtectSheet,
      '&Proteger hoja...');
    Registrar(
      'sdxBuiltInPopupMenuUnprotectSheet',
      @sdxBuiltInPopupMenuUnprotectSheet,
      'Des&proteger hoja...');
  end;
end;

procedure RegistrarDialogosYAccionesDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);

  procedure Registrar(
    const ANombre: string;
    ARecurso: PResStringRec;
    const ATexto: string);
  begin
    AProcesar(
      ANombre,
      ARecurso,
      ATexto);
  end;

begin
  if Assigned(AProcesar) then
  begin
    // Diálogo para cambiar el nombre de la hoja
    Registrar(
      'sdxRenameDialogCaption',
      @sdxRenameDialogCaption,
      'Cambiar nombre de la hoja');
    Registrar(
      'sdxRenameDialogSheetName',
      @sdxRenameDialogSheetName,
      'Nombre de la hoja:');
    // Diálogo de archivos
    Registrar(
      'sdxFileDialogAllSupported',
      @sdxFileDialogAllSupported,
      'Todos los soportados');
    // Acciones
    Registrar(
      'sdxActionAddGroup',
      @sdxActionAddGroup,
      'Agrupar');
    Registrar(
      'sdxActionAutoFill',
      @sdxActionAutoFill,
      'Autorrelleno');
    Registrar(
      'sdxActionCellEditing',
      @sdxActionCellEditing,
      'Edición de celdas');
    Registrar(
      'sdxActionCellsMerge',
      @sdxActionCellsMerge,
      'Combinar celdas');
    Registrar(
      'sdxActionChangeConditionalFormatting',
      @sdxActionChangeConditionalFormatting,
      'Cambiar formato condicional');
    Registrar(
      'sdxActionChangePrintingOptions',
      @sdxActionChangePrintingOptions,
      'Cambiar opciones de impresión');
    Registrar(
      'sdxActionCreateDefinedName',
      @sdxActionCreateDefinedName,
      'Crear nombre definido');
    Registrar(
      'sdxActionChangeDefinedName',
      @sdxActionChangeDefinedName,
      'Cambiar nombre definido');
    Registrar(
      'sdxActionChangeContainer',
      @sdxActionChangeContainer,
      'Cambiar contenedor');
    Registrar(
      'sdxActionChangeGroup',
      @sdxActionChangeGroup,
      'Cambiar grupo');
    Registrar(
      'sdxActionChangeHyperlink',
      @sdxActionChangeHyperlink,
      'Cambiar hipervínculo');
    Registrar(
      'sdxActionChangeRowColumn',
      @sdxActionChangeRowColumn,
      'Cambiar Fila/Columna');
    Registrar(
      'sdxActionClearCells',
      @sdxActionClearCells,
      'Borrar celda(s)');
    Registrar(
      'sdxActionCutCells',
      @sdxActionCutCells,
      'Cortar celdas');
    Registrar(
      'sdxActionDeleteDefinedName',
      @sdxActionDeleteDefinedName,
      'Eliminar nombre(s) definido(s)');
    Registrar(
      'sdxActionDeleteCells',
      @sdxActionDeleteCells,
      'Eliminar celdas');
    Registrar(
      'sdxActionDeleteComment',
      @sdxActionDeleteComment,
      'Eliminar comentario');
    Registrar(
      'sdxActionDeleteGroup',
      @sdxActionDeleteGroup,
      'Desagrupar');
    Registrar(
      'sdxActionDragAndDrop',
      @sdxActionDragAndDrop,
      'Arrastrar y soltar');
    Registrar(
      'sdxActionEditComment',
      @sdxActionEditComment,
      'Editar comentario');
    Registrar(
      'sdxActionExpandCollapseGroup',
      @sdxActionExpandCollapseGroup,
      'Mostrar/Ocultar detalles');
    Registrar(
      'sdxActionFillCells',
      @sdxActionFillCells,
      'Rellenar celdas');
    Registrar(
      'sdxActionFormatCells',
      @sdxActionFormatCells,
      'Formato de celdas');
    Registrar(
      'sdxActionInsertCells',
      @sdxActionInsertCells,
      'Insertar celdas');
    Registrar(
      'sdxActionMoveCells',
      @sdxActionMoveCells,
      'Mover celdas');
    Registrar(
      'sdxActionPasteCells',
      @sdxActionPasteCells,
      'Pegar celdas');
    Registrar(
      'sdxActionReplace',
      @sdxActionReplace,
      'Reemplazar');
    Registrar(
      'sdxActionSortCells',
      @sdxActionSortCells,
      'Ordenar celdas');
  end;
end;

procedure RegistrarTextosAuxiliaresDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);

  procedure Registrar(
    const ANombre: string;
    ARecurso: PResStringRec;
    const ATexto: string);
  begin
    AProcesar(
      ANombre,
      ARecurso,
      ATexto);
  end;

begin
  if Assigned(AProcesar) then
  begin
    // Hipervínculos
    Registrar(
      'sdxDefaultHyperlinkScreenTip',
      @sdxDefaultHyperlinkScreenTip,
      '%s - Clic una vez para seguir.'#13#10'Clic y mantener para ' +
      'seleccionar esta celda.');
    Registrar(
      'sdxDefaultHyperlinkShortScreenTip',
      @sdxDefaultHyperlinkShortScreenTip,
      '%s - Clic una vez para seguir.');
    Registrar(
      'scxSelectionInDocument',
      @scxSelectionInDocument,
      '<< Selección en Documento >>');
    Registrar(
      'sdxHyperlinkExecuteError',
      @sdxHyperlinkExecuteError,
      '"%s" no se puede abrir.');
    // Portapapeles
    Registrar(
      'sdxClipboardFormatHTML',
      @sdxClipboardFormatHTML,
      'Formato HTML');
    Registrar(
      'sdxClipboardFormatImage',
      @sdxClipboardFormatImage,
      'Imagen');
    Registrar(
      'sdxClipboardFormatText',
      @sdxClipboardFormatText,
      'Texto');
    // Impresión
    Registrar(
      'sdxSetSingleCellAsPrintAreaConfirmation',
      @sdxSetSingleCellAsPrintAreaConfirmation,
      'Ha seleccionado una sola celda para el área de impresión.' +
      #13#10#13#10 +
      'Si esto es correcto, haga clic en Aceptar.' + #13#10 +
      'Si seleccionó una celda por error, haga clic en Cancelar, ' +
      'seleccione las celdas deseadas y vuelva a hacer clic en ' +
      '"Establecer área de impresión"');
    Registrar(
      'sdxCell',
      @sdxCell,
      'Celda: ');
    Registrar(
      'sdxComment',
      @sdxComment,
      'Comentario: ');
    // Barra de fórmulas
    Registrar(
      'sdxFormulaBarCancelHint',
      @sdxFormulaBarCancelHint,
      'Cancelar');
    Registrar(
      'sdxFormulaBarEnterHint',
      @sdxFormulaBarEnterHint,
      'Introducir');
    Registrar(
      'sdxFormulaBarFormulaBarHint',
      @sdxFormulaBarFormulaBarHint,
      'Barra de fórmulas');
    Registrar(
      'sdxFormulaBarInsertFunctionHint',
      @sdxFormulaBarInsertFunctionHint,
      'Insertar función');
    Registrar(
      'sdxFormulaBarNameBoxHint',
      @sdxFormulaBarNameBoxHint,
      'Cuadro de nombres');
    Registrar(
      'sdxFormulaBarSelectionInfo',
      @sdxFormulaBarSelectionInfo,
      '%dF x %dC');
  end;
end;

procedure EnumerarTraduccionesEspanolasDxSpreadSheet(
  const AProcesar: TProcesarTraduccionDxSpreadSheet);
begin
  if Assigned(AProcesar) then
  begin
    RegistrarMenuEdicionDxSpreadSheet(AProcesar);
    RegistrarMenuHojaDxSpreadSheet(AProcesar);
    RegistrarDialogosYAccionesDxSpreadSheet(AProcesar);
    RegistrarTextosAuxiliaresDxSpreadSheet(AProcesar);
  end;
end;

procedure ApplySpanishTranslation;
begin
  EnumerarTraduccionesEspanolasDxSpreadSheet(
    procedure(
      const ANombre: string;
      ARecurso: PResStringRec;
      const ATexto: string)
    begin
      if ANombre <> '' then
        cxSetResourceString(
          ARecurso,
          ATexto);
    end);
end;

initialization
//  ApplySpanishTranslation;

end.

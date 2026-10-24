inherited frmModalGestionFiltros: TfrmModalGestionFiltros
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Filtros guardados'
  ClientHeight = 585
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Pitch = fpFixed
  Font.Style = []
  Font.Quality = fqClearTypeNatural
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object lblCompartidoCon: TcxLabel
    Left = 8
    Top = 406
    Caption = 'Compartido con'
    TabOrder = 3
    Transparent = True
  end
  object cxgrdFiltros: TcxGrid
    Left = 8
    Top = 8
    Width = 984
    Height = 170
    TabOrder = 0
    object tvFiltros: TcxGridDBTableView
      OnDblClick = tvFiltrosDblClick
      OnFocusedRecordChanged = tvFiltrosFocusedRecordChanged
      DataController.KeyFieldNames = 'ID_FILT'
      OptionsBehavior.FocusCellOnTab = True
      OptionsBehavior.GoToNextCellOnEnter = True
      OptionsSelection.CellSelect = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsData.Deleting = False
      OptionsView.GroupByBox = False
      object tvFiltrosNOMBRE_FILT: TcxGridDBColumn
        Caption = 'Nombre'
        DataBinding.FieldName = 'NOMBRE_FILT'
        Options.Editing = False
        Width = 250
      end
      object tvFiltrosDESCRIPCION_FILT: TcxGridDBColumn
        Caption = 'Descripción'
        DataBinding.FieldName = 'DESCRIPCION_FILT'
        Options.Editing = False
        Width = 500
      end
      object tvFiltrosUSUARIO_PROPIETARIO_FILT: TcxGridDBColumn
        Caption = 'Propietario'
        DataBinding.FieldName = 'USUARIO_PROPIETARIO_FILT'
        Options.Editing = False
        Width = 210
      end
    end
    object lvlFiltros: TcxGridLevel
      GridView = tvFiltros
    end
  end
  object lblCondiciones: TcxLabel
    Left = 8
    Top = 186
    Caption = 'Condiciones del filtro seleccionado (puede editarlas):'
    TabOrder = 1
    Transparent = True
  end
  object pnlEditorFiltro: TPanel
    Left = 8
    Top = 208
    Width = 984
    Height = 190
    BevelOuter = bvNone
    TabOrder = 2
  end
  object lbCompartidoCon: TcxListBox
    Left = 8
    Top = 426
    Width = 984
    Height = 70
    TabOrder = 4
  end
  object btnCompartirUsuario: TcxButton
    Left = 8
    Top = 504
    Width = 220
    Height = 25
    Caption = 'Compartir con &usuario...'
    TabOrder = 5
    OnClick = btnCompartirUsuarioClick
  end
  object btnCompartirGrupo: TcxButton
    Left = 236
    Top = 504
    Width = 220
    Height = 25
    Caption = 'Compartir con &grupo...'
    TabOrder = 6
    OnClick = btnCompartirGrupoClick
  end
  object btnCompartirTodos: TcxButton
    Left = 464
    Top = 504
    Width = 220
    Height = 25
    Caption = 'Compartir con &todos'
    TabOrder = 7
    OnClick = btnCompartirTodosClick
  end
  object btnQuitarCompartido: TcxButton
    Left = 692
    Top = 504
    Width = 300
    Height = 25
    Caption = '&Quitar destino seleccionado'
    TabOrder = 8
    OnClick = btnQuitarCompartidoClick
  end
  object btnAplicar: TcxButton
    Left = 8
    Top = 545
    Width = 110
    Height = 30
    Caption = '&Aplicar'
    Default = True
    TabOrder = 9
    OnClick = btnAplicarClick
  end
  object btnGuardarCambios: TcxButton
    Left = 126
    Top = 545
    Width = 155
    Height = 30
    Caption = '&Guardar cambios'
    TabOrder = 10
    OnClick = btnGuardarCambiosClick
  end
  object btnReemplazarActual: TcxButton
    Left = 284
    Top = 545
    Width = 200
    Height = 30
    Caption = 'Reemplazar por el &actual'
    TabOrder = 11
    OnClick = btnReemplazarActualClick
  end
  object btnGuardarCopia: TcxButton
    Left = 492
    Top = 545
    Width = 150
    Height = 30
    Caption = 'Guardar &copia...'
    TabOrder = 12
    OnClick = btnGuardarCopiaClick
  end
  object btnRenombrar: TcxButton
    Left = 650
    Top = 545
    Width = 130
    Height = 30
    Caption = 'Editar &datos...'
    TabOrder = 13
    OnClick = btnRenombrarClick
  end
  object btnBorrar: TcxButton
    Left = 788
    Top = 545
    Width = 96
    Height = 30
    Caption = 'Bo&rrar'
    TabOrder = 14
    OnClick = btnBorrarClick
  end
  object btnCerrar: TcxButton
    Left = 892
    Top = 545
    Width = 100
    Height = 30
    Cancel = True
    Caption = '&Cerrar'
    TabOrder = 15
    OnClick = btnCerrarClick
  end
end

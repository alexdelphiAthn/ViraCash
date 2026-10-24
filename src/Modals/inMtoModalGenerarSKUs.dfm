inherited frmMtoModalGenerarSKUS: TfrmMtoModalGenerarSKUS
  Caption = 'Generar SKUS'
  ClientHeight = 485
  ClientWidth = 732
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 748
  ExplicitHeight = 524
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 426
    Width = 732
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 418
    ExplicitWidth = 730
    inherited btnCancelar: TcxButton
      Left = 50
      Top = 6
      ExplicitLeft = 50
      ExplicitTop = 6
    end
    inherited btnAceptar: TcxButton
      Left = 533
      Top = 6
      ExplicitLeft = 533
      ExplicitTop = 6
    end
    object btnAddValue: TcxButton
      Left = 290
      Top = 6
      Width = 177
      Height = 40
      Caption = 'Añadir &Valor (F3)'
      TabOrder = 2
      OnClick = btnAddValueClick
    end
  end
  inherited pnlBody: TPanel
    Width = 732
    Height = 426
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 730
    ExplicitHeight = 418
    object pnlBodyCab: TPanel
      Left = 1
      Top = 1
      Width = 730
      Height = 120
      Align = alTop
      TabOrder = 0
      ExplicitWidth = 728
      object cxGrid1: TcxGrid
        Left = 1
        Top = 1
        Width = 728
        Height = 118
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 726
        object tvMaestro: TcxGridDBTableView
          DataController.DataSource = dsMaestro
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          object tvMaestroID_ATRIBUTO_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_ATB_VA'
            Visible = False
          end
          object tvMaestroID_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_VAR_VA'
            Visible = False
          end
          object tvMaestroNOMBRE_ATRIBUTO: TcxGridDBColumn
            Caption = 'Variaci'#243'n'
            DataBinding.FieldName = 'NOMBRE_ATRIBUTO'
            Width = 183
          end
          object tvMaestroORDEN_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ORDEN_VA'
            Visible = False
          end
          object tvMaestroORDEN_ACA: TcxGridDBColumn
            Caption = 'Orden'
            DataBinding.FieldName = 'ORDEN_ACA'
            HeaderAlignmentHorz = taRightJustify
            Options.Editing = False
            Width = 130
          end
        end
        object cxGrid1Level1: TcxGridLevel
          GridView = tvMaestro
        end
      end
    end
    object pnlBodyDetalle: TPanel
      Left = 1
      Top = 121
      Width = 730
      Height = 304
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 728
      ExplicitHeight = 296
      object cxSplitter1: TcxSplitter
        Left = 1
        Top = 1
        Width = 728
        Height = 10
        HotZoneClassName = 'TcxMediaPlayer9Style'
        AlignSplitter = salTop
        Control = pnlBodyCab
        ExplicitWidth = 726
      end
      object pnlConjunto: TPanel
        Left = 1
        Top = 11
        Width = 728
        Height = 44
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        object lblConjunto: TcxLabel
          Left = 8
          Top = 11
          Caption = 'Conjunto:'
          Transparent = True
        end
        object cbConjunto: TcxComboBox
          Left = 96
          Top = 8
          Properties.DropDownListStyle = lsFixedList
          Properties.DropDownRows = 12
          Properties.OnChange = cbConjuntoPropertiesChange
          TabOrder = 0
          Width = 320
        end
        object btnMarcarTodas: TcxButton
          Left = 432
          Top = 6
          Width = 200
          Height = 32
          Caption = 'Marcar/desmarcar todas'
          TabOrder = 1
          OnClick = btnMarcarTodasClick
        end
      end
      object cxGrid2: TcxGrid
        Left = 1
        Top = 55
        Width = 728
        Height = 248
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 726
        ExplicitHeight = 284
        object tvDetalle: TcxGridDBTableView
          OnCellDblClick = tvDetalleCellDblClick
          Navigator.Buttons.CustomButtons = <>
          Navigator.Visible = True
          DataController.DataSource = dsDetalle
          OptionsData.DeletingConfirmation = False
          OptionsView.GroupByBox = False
          object tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_VA_AC'
            Visible = False
          end
          object tvDetalleID_CONJUNTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_AC'
            Visible = False
            Width = 167
          end
          object tvDetalleNOMBRE_AC: TcxGridDBColumn
            Caption = 'Valor'
            DataBinding.FieldName = 'NOMBRE_AC'
            Options.Editing = False
            SortIndex = 1
            SortOrder = soAscending
            Width = 168
          end
          object tvDetalleASIGNADO: TcxGridDBColumn
            Caption = 'Asignar'
            DataBinding.FieldName = 'ASIGNADO'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Properties.Alignment = taRightJustify
            Properties.ImmediatePost = True
            Properties.ValueChecked = '1'
            Properties.ValueUnchecked = '0'
          end
          object tvDetalleID_ATRIBUTO_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_ATB_VA'
            Visible = False
          end
          object tvDetalleORDEN_AV: TcxGridDBColumn
            Caption = 'Orden (doble click cambiar orden)'
            DataBinding.FieldName = 'ORDEN_AV'
            HeaderAlignmentHorz = taRightJustify
            Options.Editing = False
            SortIndex = 0
            SortOrder = soAscending
            Width = 299
          end
        end
        object cxGridLevel1: TcxGridLevel
          GridView = tvDetalle
        end
      end
    end
  end
  inherited ActionList1: TActionList
    object actAnadirValor: TAction
      ShortCut = 114
      OnExecute = btnAddValueClick
    end
  end
  object dsMaestro: TDataSource
    OnDataChange = dsMaestroDataChange
    Left = 592
    Top = 144
  end
  object dsDetalle: TDataSource
    Left = 688
    Top = 144
  end
end

inherited frmModalAddBlockInventario: TfrmModalAddBlockInventario
  Caption = 'A'#241'adir Bloque - Carga masiva en Inventario'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    Height = 64
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1178
    ExplicitHeight = 64
    object lblInventarioInfo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Inventario destino'
      TabOrder = 0
      Transparent = True
    end
    object lblNotaCarga: TcxLabel
      Left = 12
      Top = 38
      Caption = 
        'Se a'#241'adir'#225' una l'#237'nea por cada SKU con stock>0 en el almac'#233'n del ' +
        'inventario. Las cantidades te'#243'ricas se calcular'#225'n despu'#233's pulsan' +
        'do "Recalcular te'#243'rico/PMP".'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
    end
  end
  inherited pnlCabeceraComun: TPanel
    Top = 64
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 64
    inherited chkExcluirYaCargados: TcxCheckBox
      Left = 221
      Top = 6
      ExplicitLeft = 221
      ExplicitTop = 6
    end
    inherited chkSoloConStock: TcxCheckBox
      Left = 494
      Top = 6
      ExplicitLeft = 494
      ExplicitTop = 6
    end
    inherited lblStockAviso: TcxLabel
      Left = 18
      Top = 30
      ExplicitLeft = 18
      ExplicitTop = 30
    end
    object chkSoloNegativos: TcxCheckBox
      Left = 710
      Top = 6
      Caption = 'Cargar s'#243'lo negativos'
      Hint = 'Cargar stock negativo del almac'#233'n para regularizarlo a cero'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = chkSoloNegativosClick
      Width = 210
    end
    inherited btnPrevisualizar: TcxButton
      Left = 928
      Width = 122
      ExplicitLeft = 928
      ExplicitWidth = 122
    end
  end
  inherited pcFiltros: TcxPageControl
    Top = 114
    Height = 374
    ExplicitTop = 114
    ExplicitHeight = 366
    ClientRectBottom = 372
    inherited tsFamilias: TcxTabSheet
      ExplicitHeight = 335
      inherited pnlFamiliasTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited btnExpandirFamilias: TcxButton
          Left = 313
          ExplicitLeft = 313
        end
        inherited btnContraerFamilias: TcxButton
          Left = 409
          ExplicitLeft = 409
        end
        inherited btnQuitarSelFamilias: TcxButton
          Left = 505
          Width = 163
          ExplicitLeft = 505
          ExplicitWidth = 163
        end
        inherited lblSelFamilias: TcxLabel
          Left = 674
          Top = 6
          ExplicitLeft = 674
          ExplicitTop = 6
        end
      end
      inherited tlFamilias: TcxDBTreeList
        Height = 308
        ExplicitHeight = 300
      end
    end
    inherited tsProveedores: TcxTabSheet
      ExplicitHeight = 343
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited edtFiltroProveedor: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited chkSoloPrincipal: TcxCheckBox
          ExplicitWidth = 268
          ExplicitHeight = 23
        end
        inherited btnQuitarSelProveedores: TcxButton
          Left = 544
          Width = 166
          ExplicitLeft = 544
          ExplicitWidth = 166
        end
        inherited lblSelProveedores: TcxLabel
          Left = 716
          Top = 6
          ExplicitLeft = 716
          ExplicitTop = 6
        end
      end
      inherited grdProveedores: TcxGrid
        Height = 308
        ExplicitWidth = 1176
        ExplicitHeight = 302
      end
    end
    inherited tsPropiedades: TcxTabSheet
      ExplicitHeight = 343
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited cbxPropiedad: TcxComboBox
          Left = 165
          Top = 2
          ExplicitLeft = 165
          ExplicitTop = 2
          ExplicitHeight = 27
        end
        inherited btnQuitarSelPropiedades: TcxButton
          Left = 492
          Width = 155
          ExplicitLeft = 492
          ExplicitWidth = 155
        end
        inherited lblSelPropiedades: TcxLabel
          Left = 657
          Top = 6
          ExplicitLeft = 657
          ExplicitTop = 6
        end
      end
      inherited grdPropValores: TcxGrid
        Height = 308
        ExplicitWidth = 1176
        ExplicitHeight = 302
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      ExplicitHeight = 343
      inherited pnlAlmacenesTop: TPanel
        Height = 113
        StyleElements = [seFont, seClient, seBorder]
        ExplicitHeight = 113
        inherited rgStockCombinacion: TcxRadioGroup
          ExplicitWidth = 786
          ExplicitHeight = 65
          Height = 65
          Width = 786
        end
        inherited btnMarcarTodosAlm: TcxButton
          Left = 470
          Top = 37
          ExplicitLeft = 470
          ExplicitTop = 37
        end
        inherited btnDesmarcarTodosAlm: TcxButton
          Left = 618
          Top = 37
          Width = 144
          ExplicitLeft = 618
          ExplicitTop = 37
          ExplicitWidth = 144
        end
        inherited lblSelAlmacenes: TcxLabel
          Top = 37
          ExplicitTop = 37
        end
      end
      inherited chkLstAlmacenes: TcxCheckListBox
        Top = 113
        Height = 230
        ExplicitTop = 113
        ExplicitHeight = 230
      end
    end
    inherited tsFechaAlta: TcxTabSheet
      ExplicitHeight = 343
      inherited chkAplicarFechaAlta: TcxCheckBox
        ExplicitWidth = 322
        ExplicitHeight = 23
      end
      inherited dtAltaDesde: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited dtAltaHasta: TcxDateEdit
        ExplicitHeight = 27
      end
    end
    inherited tsVentas: TcxTabSheet
      ExplicitHeight = 343
      inherited chkConVenta: TcxCheckBox
        ExplicitWidth = 297
        ExplicitHeight = 23
      end
      inherited dtVtaDesde: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited dtVtaHasta: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited rgConSinVenta: TcxRadioGroup
        ExplicitHeight = 80
        Height = 80
      end
      inherited spnNumMinVtas: TcxSpinEdit
        Left = 252
        ExplicitLeft = 252
        ExplicitHeight = 27
      end
    end
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited grdPreview: TcxGrid
      inherited tvPreview: TcxGridDBTableView
        inherited colPrevFamilia: TcxGridDBColumn
          Width = 203
        end
        inherited colPrevYaCargado: TcxGridDBColumn
          Width = 110
        end
        object colPrevSkusConStock: TcxGridDBColumn
          Caption = 'SKUs c/ stock'
          DataBinding.FieldName = 'NUM_SKUS_CON_STOCK'
          HeaderAlignmentHorz = taRightJustify
          Width = 90
        end
        object colPrevPMPActual: TcxGridDBColumn
          Caption = 'PMP medio'
          DataBinding.FieldName = 'PMP_ACTUAL'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
          Width = 90
        end
      end
    end
  end
  inherited pnlBotonera: TPanel
    StyleElements = [seFont, seClient, seBorder]
  end
end

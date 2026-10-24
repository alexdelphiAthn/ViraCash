inherited frmModalAddBlockTarifa: TfrmModalAddBlockTarifa
  Caption = 'A'#241'adir Bloque - Carga masiva en Tarifa'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    StyleElements = [seFont, seClient, seBorder]
    object lblTarifa: TcxLabel
      Left = 12
      Top = 6
      Caption = 'Tarifa destino:'
      TabOrder = 11
      Transparent = True
    end
    object cbxTarifa: TcxComboBox
      Left = 12
      Top = 28
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 0
      Width = 200
    end
    object lblFechaDesde: TcxLabel
      Left = 227
      Top = 6
      Caption = 'Fecha desde:'
      TabOrder = 12
      Transparent = True
    end
    object dtFechaDesde: TcxDateEdit
      Left = 227
      Top = 28
      TabOrder = 1
      Width = 146
    end
    object chkConFechaHasta: TcxCheckBox
      Left = 388
      Top = 6
      Caption = 'Fecha hasta:'
      Properties.OnChange = chkConFechaHastaPropertiesChange
      TabOrder = 2
    end
    object dtFechaHasta: TcxDateEdit
      Left = 388
      Top = 28
      Enabled = False
      TabOrder = 3
      Width = 165
    end
    object lblPorcenDto: TcxLabel
      Left = 580
      Top = 6
      Caption = '% Dto:'
      TabOrder = 13
      Transparent = True
    end
    object spnPorcenDto: TcxCurrencyEdit
      Left = 580
      Top = 28
      Properties.DisplayFormat = '0.00 %'
      TabOrder = 4
      Width = 65
    end
    object chkAjustarPrecio: TcxCheckBox
      Left = 660
      Top = 4
      Caption = 'Ajustar precio'
      Properties.OnChange = chkAjustarPrecioPropertiesChange
      TabOrder = 5
    end
    object lblMultiplo: TcxLabel
      Left = 660
      Top = 32
      Caption = 'M'#250'ltiplo:'
      TabOrder = 14
      Transparent = True
    end
    object spnMultiplo: TcxCurrencyEdit
      Left = 660
      Top = 56
      Enabled = False
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      TabOrder = 6
      Width = 82
    end
    object lblRestar: TcxLabel
      Left = 790
      Top = 32
      Caption = 'Menos:'
      TabOrder = 15
      Transparent = True
    end
    object spnRestar: TcxCurrencyEdit
      Left = 790
      Top = 56
      Enabled = False
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      TabOrder = 7
      Width = 79
    end
    object rgAjusteAlcance: TcxRadioGroup
      Left = 888
      Top = 2
      Caption = ' Aplicar ajuste a '
      Enabled = False
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Final'
        end
        item
          Caption = 'Salida'
        end
        item
          Caption = 'Ambos'
        end>
      ItemIndex = 0
      TabOrder = 8
      Height = 81
      Width = 265
    end
    object chkCopiarDeTarifa: TcxCheckBox
      Left = 12
      Top = 71
      Caption = 'Copiar precios de tarifa'
      Properties.OnChange = chkCopiarDeTarifaPropertiesChange
      TabOrder = 9
    end
    object cbxTarifaOrigen: TcxComboBox
      Left = 240
      Top = 67
      Enabled = False
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 10
      Width = 220
    end
  end
  inherited pnlCabeceraComun: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited chkSoloActivos: TcxCheckBox
      Top = 6
      ExplicitTop = 6
    end
    inherited chkExcluirYaCargados: TcxCheckBox
      Left = 223
      Top = 6
      ExplicitLeft = 223
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
      Top = 28
      ExplicitLeft = 18
      ExplicitTop = 28
    end
    inherited btnPrevisualizar: TcxButton
      Left = 888
      Width = 162
      ExplicitLeft = 888
      ExplicitWidth = 162
    end
    inherited btnLimpiarFiltros: TcxButton
      Width = 93
      ExplicitWidth = 93
    end
  end
  inherited pcFiltros: TcxPageControl
    inherited tsFamilias: TcxTabSheet
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
          Width = 152
          ExplicitLeft = 505
          ExplicitWidth = 152
        end
        inherited lblSelFamilias: TcxLabel
          Left = 663
          Top = 6
          ExplicitLeft = 663
          ExplicitTop = 6
        end
      end
    end
    inherited tsProveedores: TcxTabSheet
      Caption = '&2_Proveedores '
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
          Left = 558
          Width = 154
          ExplicitLeft = 558
          ExplicitWidth = 154
        end
        inherited lblSelProveedores: TcxLabel
          Left = 726
          Top = 6
          ExplicitLeft = 726
          ExplicitTop = 6
        end
      end
      inherited grdProveedores: TcxGrid
        ExplicitWidth = 1176
        ExplicitHeight = 272
      end
    end
    inherited tsPropiedades: TcxTabSheet
      Caption = '&3_Propiedades '
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited cbxPropiedad: TcxComboBox
          Left = 176
          ExplicitLeft = 176
          ExplicitWidth = 254
          ExplicitHeight = 27
          Width = 254
        end
        inherited btnQuitarSelPropiedades: TcxButton
          Width = 151
          ExplicitWidth = 151
        end
        inherited lblSelPropiedades: TcxLabel
          Left = 627
          Top = 6
          ExplicitLeft = 627
          ExplicitTop = 6
        end
      end
      inherited grdPropValores: TcxGrid
        ExplicitWidth = 1176
        ExplicitHeight = 272
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      inherited pnlAlmacenesTop: TPanel
        Height = 113
        StyleElements = [seFont, seClient, seBorder]
        ExplicitHeight = 113
        inherited rgStockCombinacion: TcxRadioGroup
          ExplicitWidth = 873
          ExplicitHeight = 65
          Height = 65
          Width = 873
        end
        inherited btnMarcarTodosAlm: TcxButton
          Left = 887
          Top = 37
          ExplicitLeft = 887
          ExplicitTop = 37
        end
        inherited btnDesmarcarTodosAlm: TcxButton
          Left = 887
          Top = 68
          Width = 154
          ExplicitLeft = 887
          ExplicitTop = 68
          ExplicitWidth = 154
        end
        inherited lblSelAlmacenes: TcxLabel
          Left = 1047
          Top = 39
          ExplicitLeft = 1047
          ExplicitTop = 39
        end
      end
      inherited chkLstAlmacenes: TcxCheckListBox
        Top = 113
        Height = 194
        ExplicitTop = 113
        ExplicitHeight = 194
      end
    end
    inherited tsFechaAlta: TcxTabSheet
      Caption = '&5_Fecha alta '
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
      Caption = '&6_Ventas '
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
        inherited colPrevCodigo: TcxGridDBColumn
          Width = 193
        end
        inherited colPrevFamilia: TcxGridDBColumn
          Width = 209
        end
        object colPrevPrecioSalidaOrig: TcxGridDBColumn
          Caption = 'P. Salida orig.'
          DataBinding.FieldName = 'PRECIO_SALIDA_ORIG'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
          Width = 90
        end
        object colPrevPrecioFinalOrig: TcxGridDBColumn
          Caption = 'P. Final orig.'
          DataBinding.FieldName = 'PRECIO_FINAL_ORIG'
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
  inherited jvntrstb1: TJvEnterAsTab
    Left = 704
    Top = 680
  end
end

inherited frmModalAddBlockDocumentoTrabajo: TfrmModalAddBlockDocumentoTrabajo
  Caption = 'A'#241'adir Bloque - Documento de Trabajo'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    Height = 64
    StyleElements = [seFont, seClient, seBorder]
    ExplicitHeight = 64
    object lblDocumentoInfo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Documento destino'
      TabOrder = 0
      Transparent = True
    end
    object lblNotaCarga: TcxLabel
      Left = 12
      Top = 38
      Caption = 
        'Se cargar'#225'n los SKU vendidos que cumplan los filtros de stock. La ' +
        'reserva de origen y la cantidad m'#225'xima a servir son configurables.'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
    end
  end
  inherited pnlCabeceraComun: TPanel
    Top = 64
    Height = 76
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
      Top = 44
      ExplicitLeft = 18
      ExplicitTop = 30
    end
    inherited btnPrevisualizar: TcxButton
      Left = 916
      Width = 134
      ExplicitLeft = 916
      ExplicitWidth = 134
    end
  end
  inherited pcFiltros: TcxPageControl
    Top = 114
    Height = 374
    ExplicitTop = 114
    ExplicitHeight = 374
    ClientRectBottom = 372
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
        ExplicitHeight = 308
      end
    end
    inherited tsProveedores: TcxTabSheet
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
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
        ExplicitHeight = 308
      end
    end
    inherited tsPropiedades: TcxTabSheet
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited cbxPropiedad: TcxComboBox
          Left = 165
          Top = 2
          ExplicitLeft = 165
          ExplicitTop = 2
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
        ExplicitHeight = 308
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      inherited pnlAlmacenesTop: TPanel
        Height = 140
        StyleElements = [seFont, seClient, seBorder]
        ExplicitHeight = 140
        inherited rgStockCombinacion: TcxRadioGroup
          ExplicitWidth = 640
          ExplicitHeight = 65
          Height = 65
          Width = 640
        end
        inherited btnMarcarTodosAlm: TcxButton
          Left = 660
          Top = 37
          Width = 140
          ExplicitLeft = 660
          ExplicitTop = 37
          ExplicitWidth = 140
        end
        inherited btnDesmarcarTodosAlm: TcxButton
          Left = 812
          Top = 37
          Width = 160
          ExplicitLeft = 812
          ExplicitTop = 37
          ExplicitWidth = 160
        end
        inherited lblSelAlmacenes: TcxLabel
          Left = 984
          Top = 37
          ExplicitLeft = 984
          ExplicitTop = 37
        end
        inherited lblReservaStockOrigen: TcxLabel
          Top = 109
          Visible = True
          ExplicitTop = 109
        end
        inherited spnReservaStockOrigen: TcxSpinEdit
          Left = 340
          Top = 105
          Visible = True
          ExplicitLeft = 340
          ExplicitTop = 105
        end
        inherited lblMaximoServirPorSku: TcxLabel
          Left = 460
          Top = 109
          Visible = True
          ExplicitLeft = 460
          ExplicitTop = 109
        end
        inherited spnMaximoServirPorSku: TcxSpinEdit
          Left = 740
          Top = 105
          Visible = True
          ExplicitLeft = 740
          ExplicitTop = 105
        end
      end
      inherited chkLstAlmacenes: TcxCheckListBox
        Top = 140
        Height = 203
        ExplicitTop = 140
        ExplicitHeight = 203
      end
    end
    inherited tsVentas: TcxTabSheet
      inherited lblAlmacenesVentas: TcxLabel
        Visible = True
      end
      inherited chkLstAlmacenesVentas: TcxCheckListBox
        Visible = True
      end
      inherited chkFiltrarStockAlmacenVenta: TcxCheckBox
        Visible = True
      end
      inherited lblStockMaximoAlmacenVenta: TcxLabel
        Visible = True
      end
      inherited spnStockMaximoAlmacenVenta: TcxSpinEdit
        Visible = True
      end
    end
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
  end
  inherited pnlBotonera: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited btnAceptar: TcxButton
      Left = 892
      Width = 132
      ExplicitLeft = 892
      ExplicitWidth = 132
    end
    inherited btnCancelar: TcxButton
      Left = 1036
      Width = 132
      ExplicitLeft = 1036
      ExplicitWidth = 132
    end
  end
end

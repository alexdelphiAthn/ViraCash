inherited frmMtoEfectosVenta: TfrmMtoEfectosVenta
  Caption = 'Efectos de Cobro a Cliente'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsSelection.MultiSelect = True
            object dbcGrdDBTabPrinNUMERO_FAC_EFV: TcxGridDBColumn
              Caption = 'Borrador'
              DataBinding.FieldName = 'NUMERO_FAC_EFV'
              Width = 80
            end
            object dbcGrdDBTabPrinSERIE_FAC_EFV: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC_EFV'
              Width = 70
            end
            object dbcGrdDBTabPrinNUMERO_EFV: TcxGridDBColumn
              Caption = 'Efecto'
              DataBinding.FieldName = 'NUMERO_EFV'
              Width = 60
            end
            object dbcGrdDBTabPrinNOMBRE_CLI_VIEW_EFV: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'NOMBRE_CLI_VIEW_EFV'
              Width = 200
            end
            object dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFV: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'DESCRIPCION_TEFE_VIEW_EFV'
              Width = 120
            end
            object dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFV: TcxGridDBColumn
              Caption = 'Vencimiento'
              DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFV'
              Width = 110
            end
            object dbcGrdDBTabPrinIMPORTE_EFV: TcxGridDBColumn
              Caption = 'Importe'
              DataBinding.FieldName = 'IMPORTE_EFV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFV: TcxGridDBColumn
              Caption = 'Pendiente'
              DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object dbcGrdDBTabPrinESTADO_EFV: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_EFV'
              Width = 100
            end
            object dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFV: TcxGridDBColumn
              Caption = 'Ref. doc.'
              DataBinding.FieldName = 'REFERENCIA_DOCUMENTO_EFV'
              Width = 130
            end
            object dbcGrdDBTabPrinFECHA_COBRO_EFV: TcxGridDBColumn
              Caption = 'F. cobro'
              DataBinding.FieldName = 'FECHA_COBRO_EFV'
              Width = 100
            end
            object dbcGrdDBTabPrinNUMERO_REMV_EFV: TcxGridDBColumn
              Caption = 'Remesa'
              DataBinding.FieldName = 'NUMERO_REMV_EFV'
              Width = 80
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited nvNavegador: TcxDBNavigator
          Width = 252
          ExplicitWidth = 252
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnRegistrarCobro: TcxButton
      Left = 0
      Top = 200
      Width = 137
      Height = 44
      Caption = 'Conciliar efecto'
      TabOrder = 2
      OnClick = btnRegistrarCobroClick
    end
    object btnFusionarEfectos: TcxButton
      Left = 0
      Top = 250
      Width = 137
      Height = 44
      Caption = 'Fusionar efectos'
      TabOrder = 3
      OnClick = btnFusionarEfectosClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmEfectosVenta.unqryTablaG
  end
end



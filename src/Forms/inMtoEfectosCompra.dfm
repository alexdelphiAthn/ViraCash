inherited frmMtoEfectosCompra: TfrmMtoEfectosCompra
  Caption = 'Efectos de Pago a Proveedor'
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
            object dbcGrdDBTabPrinNUMERO_FACC_EFEC: TcxGridDBColumn
              Caption = 'Borrador'
              DataBinding.FieldName = 'NUMERO_FACC_EFEC'
              Width = 80
            end
            object dbcGrdDBTabPrinSERIE_FACC_EFEC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FACC_EFEC'
              Width = 70
            end
            object dbcGrdDBTabPrinNUMERO_EFEC: TcxGridDBColumn
              Caption = 'Efecto'
              DataBinding.FieldName = 'NUMERO_EFEC'
              Width = 60
            end
            object dbcGrdDBTabPrinNOMBRE_PRV_VIEW_EFEC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'NOMBRE_PRV_VIEW_EFEC'
              Width = 200
            end
            object dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'DESCRIPCION_TEFE_VIEW_EFEC'
              Width = 120
            end
            object dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn
              Caption = 'Vencimiento'
              DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFEC'
              Width = 110
            end
            object dbcGrdDBTabPrinIMPORTE_EFEC: TcxGridDBColumn
              Caption = 'Importe'
              DataBinding.FieldName = 'IMPORTE_EFEC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn
              Caption = 'Pendiente'
              DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFEC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object dbcGrdDBTabPrinESTADO_EFEC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_EFEC'
              Width = 100
            end
            object dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn
              Caption = 'Ref. doc.'
              DataBinding.FieldName = 'REFERENCIA_DOCUMENTO_EFEC'
              Width = 130
            end
            object dbcGrdDBTabPrinFECHA_PAGO_EFEC: TcxGridDBColumn
              Caption = 'F. pago'
              DataBinding.FieldName = 'FECHA_PAGO_EFEC'
              Width = 100
            end
            object dbcGrdDBTabPrinNUMERO_REMC_EFEC: TcxGridDBColumn
              Caption = 'Remesa'
              DataBinding.FieldName = 'NUMERO_REMC_EFEC'
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
    object btnRegistrarPago: TcxButton
      Left = 0
      Top = 200
      Width = 137
      Height = 44
      Caption = 'Conciliar efecto'
      TabOrder = 2
      OnClick = btnRegistrarPagoClick
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
    DataSet = dmEfectosCompra.unqryTablaG
  end
end

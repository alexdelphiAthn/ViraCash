inherited frmMtoFacturasSimplif: TfrmMtoFacturasSimplif
  Caption = 'Borradores Simplificados (Caja)'
  OnDestroy = FormDestroy
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        object pnlFiltros: TPanel
          Left = 0
          Top = 0
          Width = 1000
          Height = 60
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object btnToggleFiltros: TcxButton
            Left = 0
            Top = 0
            Width = 1000
            Height = 22
            Align = alTop
            Caption = #9654'  Filtros de carga'
            LookAndFeel.Kind = lfUltraFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnToggleFiltrosClick
          end
          object pnlContFiltros: TPanel
            Left = 0
            Top = 22
            Width = 1000
            Height = 38
            Align = alClient
            BevelOuter = bvNone
            ParentBackground = False
            TabOrder = 1
            object lblFiltroAnyo: TcxLabel
              Left = 16
              Top = 8
              Caption = 'A'#241'os:'
              TabOrder = 2
              Transparent = True
            end
            object ccbFiltroAnyo: TcxCheckComboBox
              Left = 80
              Top = 5
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAnyoPropertiesCloseUp
              TabOrder = 0
              Width = 210
            end
            object lblFiltroAlmacen: TcxLabel
              Left = 320
              Top = 8
              Caption = 'Almacenes:'
              TabOrder = 3
              Transparent = True
            end
            object ccbFiltroAlmacen: TcxCheckComboBox
              Left = 416
              Top = 5
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAlmacenPropertiesCloseUp
              TabOrder = 1
              Width = 340
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        inherited pnlVerifactu: TPanel
          inherited pcDetail: TcxPageControl
            inherited tsRecibos: TcxTabSheet
              TabVisible = False
            end
            object tsPagosCaja: TcxTabSheet
              Caption = '&3_Pagos de Caja'
              PageIndex = 2
              object pnlRightPagosCaja: TPanel
                Left = 918
                Top = 0
                Width = 153
                Height = 395
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnIrAPagosCaja: TcxButton
                  Left = 3
                  Top = 17
                  Width = 146
                  Height = 25
                  Caption = 'Ir a Pagos de Caja'
                  TabOrder = 0
                  OnClick = btnIrAPagosCajaClick
                end
              end
              object pnlBodyPagosCaja: TPanel
                Left = 0
                Top = 0
                Width = 918
                Height = 395
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdPagosCaja: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 918
                  Height = 395
                  Align = alClient
                  TabOrder = 0
                  object tvPagosCaja: TcxGridDBTableView
                    Navigator.Buttons.CustomButtons = <>
                    DataController.Summary.DefaultGroupSummaryItems = <>
                    DataController.Summary.FooterSummaryItems = <>
                    DataController.Summary.SummaryGroups = <>
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object colPagoLinea: TcxGridDBColumn
                      Caption = 'L'#237'nea'
                      DataBinding.FieldName = 'NUMERO_LINEA_PAGO'
                      Options.Editing = False
                      Width = 60
                    end
                    object colPagoFormaPago: TcxGridDBColumn
                      Caption = 'Forma de Pago'
                      DataBinding.FieldName = 'CODIGO_FP_CFP'
                      Options.Editing = False
                      Width = 110
                    end
                    object colPagoDescripcion: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_CFP'
                      Options.Editing = False
                      Width = 200
                    end
                    object colPagoEntregado: TcxGridDBColumn
                      Caption = 'Entregado'
                      DataBinding.FieldName = 'IMPORTE_ENTREGADO_PAGO'
                      Options.Editing = False
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.00 '#8364
                      Width = 110
                    end
                    object colPagoCambio: TcxGridDBColumn
                      Caption = 'Cambio'
                      DataBinding.FieldName = 'IMPORTE_CAMBIO_PAGO'
                      Options.Editing = False
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.00 '#8364
                      Width = 100
                    end
                    object colPagoDivisa: TcxGridDBColumn
                      Caption = 'Divisa'
                      DataBinding.FieldName = 'CODIGO_DIVISA_PAGO'
                      Options.Editing = False
                      Width = 80
                    end
                    object colPagoImporteDivisa: TcxGridDBColumn
                      Caption = 'Importe Divisa'
                      DataBinding.FieldName = 'IMPORTE_DIVISA_PAGO'
                      Options.Editing = False
                      Width = 120
                    end
                    object colPagoReferencia: TcxGridDBColumn
                      Caption = 'Referencia'
                      DataBinding.FieldName = 'REFERENCIA_FACPAG'
                      Options.Editing = False
                      Width = 200
                    end
                    object colPagoObservaciones: TcxGridDBColumn
                      Caption = 'Observaciones'
                      DataBinding.FieldName = 'OBSERVACIONES_PAGO'
                      Options.Editing = False
                      Width = 220
                    end
                  end
                  object cxgrdlvlPagosCaja: TcxGridLevel
                    GridView = tvPagosCaja
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

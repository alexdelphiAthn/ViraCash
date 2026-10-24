inherited frmModalArqueo: TfrmModalArqueo
  Caption = 'Arqueo de caja'
  ClientHeight = 639
  ClientWidth = 1006
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 1022
  ExplicitHeight = 678
  TextHeight = 17
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 1006
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 1004
    object lblTituloDesde: TcxLabel
      Left = 16
      Top = 6
      Caption = 'Fecha desde (F10)'
      Style.TextColor = clNavy
      TabOrder = 4
      Transparent = True
    end
    object dteFechaDesde: TcxDateEdit
      Left = 16
      Top = 28
      Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.Kind = ckDateTime
      Properties.OnChange = dteFechaDesdePropertiesChange
      TabOrder = 0
      Width = 190
    end
    object lblTituloHasta: TcxLabel
      Left = 210
      Top = 6
      Caption = 'Fecha hasta (F6)'
      Style.TextColor = clNavy
      TabOrder = 6
      Transparent = True
    end
    object dteFechaHasta: TcxDateEdit
      Left = 210
      Top = 28
      Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.Kind = ckDateTime
      Properties.OnChange = dteFechaHastaPropertiesChange
      TabOrder = 1
      Width = 190
    end
    object lblTituloVentas: TcxLabel
      Left = 500
      Top = 6
      Caption = 'Ventas'
      Style.TextColor = clNavy
      TabOrder = 5
      Transparent = True
    end
    object lblVentas: TcxLabel
      Left = 500
      Top = 28
      AutoSize = False
      Caption = '0'
      Properties.Alignment.Horz = taRightJustify
      TabOrder = 7
      Transparent = True
      Height = 28
      Width = 70
      AnchorX = 570
    end
    object btnRecalcular: TcxButton
      Left = 410
      Top = 18
      Width = 82
      Height = 35
      Caption = 'Calc (F5)'
      TabOrder = 2
      OnClick = btnRecalcularClick
    end
    object btnImprimir: TcxButton
      Left = 728
      Top = 22
      Width = 144
      Height = 35
      Caption = 'Resumen (F11)'
      TabOrder = 3
      OnClick = btnImprimirClick
    end
    object btnHistorico: TcxButton
      Left = 876
      Top = 22
      Width = 124
      Height = 35
      Caption = 'Hist'#243'rico (F8)'
      TabOrder = 8
      OnClick = btnHistoricoClick
    end
    object btnTiraCaja: TcxButton
      Left = 576
      Top = 22
      Width = 146
      Height = 35
      Caption = 'Tira de Caja (F7)'
      TabOrder = 9
      OnClick = btnTiraCajaClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 70
    Width = 1006
    Height = 519
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    ExplicitWidth = 1004
    ExplicitHeight = 511
    object pcArqueo: TcxPageControl
      Left = 0
      Top = 0
      Width = 1006
      Height = 519
      Align = alClient
      TabOrder = 0
      Properties.ActivePage = tsArqueo
      Properties.CustomButtons.Buttons = <>
      ExplicitWidth = 1004
      ExplicitHeight = 511
      ClientRectBottom = 515
      ClientRectLeft = 4
      ClientRectRight = 1002
      ClientRectTop = 28
      object tsArqueo: TcxTabSheet
        Caption = '&1_Arqueo'
        ExplicitWidth = 996
        ExplicitHeight = 479
        object pnlLineas: TPanel
          Left = 8
          Top = 8
          Width = 360
          Height = 130
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          object lblLineasTitulo: TcxLabel
            Left = 10
            Top = 6
            Caption = 'L'#237'neas art'#237'culos'
            Style.TextColor = clNavy
            TabOrder = 0
            Transparent = True
          end
          object lblLinBrutoLbl: TcxLabel
            Left = 16
            Top = 34
            Caption = '+ Bruto'
            TabOrder = 1
            Transparent = True
          end
          object lblLinBruto: TcxLabel
            Left = 190
            Top = 34
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 2
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblLinDescuentoLbl: TcxLabel
            Left = 16
            Top = 60
            Caption = '- Descuento'
            TabOrder = 3
            Transparent = True
          end
          object lblLinDescuento: TcxLabel
            Left = 190
            Top = 60
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 4
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblLinNetoLbl: TcxLabel
            Left = 16
            Top = 92
            Caption = '= Bruto'
            TabOrder = 5
            Transparent = True
          end
          object lblLinNeto: TcxLabel
            Left = 190
            Top = 92
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 6
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
        end
        object pnlOperaciones: TPanel
          Left = 376
          Top = 8
          Width = 496
          Height = 130
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object lblOpeTitulo: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Operaciones'
            Style.TextColor = clNavy
            TabOrder = 0
            Transparent = True
          end
          object lblOpeVentasNormLbl: TcxLabel
            Left = 16
            Top = 30
            Caption = 'Ventas Normales'
            TabOrder = 1
            Transparent = True
          end
          object lblOpeVentasNorm: TcxLabel
            Left = 175
            Top = 30
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 2
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 325
          end
          object lblOpeVentasPrestLbl: TcxLabel
            Left = 16
            Top = 54
            Caption = '+ Ventas Pr'#233'stamos'
            TabOrder = 3
            Transparent = True
          end
          object lblOpeVentasPrest: TcxLabel
            Left = 175
            Top = 54
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 4
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 325
          end
          object lblOpeDevolLbl: TcxLabel
            Left = 16
            Top = 78
            Caption = '- Devoluciones'
            TabOrder = 5
            Transparent = True
          end
          object lblOpeDevol: TcxLabel
            Left = 175
            Top = 78
            AutoSize = False
            Style.TextColor = clRed
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 6
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 325
          end
          object lblOpeTotalVentasLbl: TcxLabel
            Left = 16
            Top = 102
            Caption = '= Total Ventas'
            TabOrder = 7
            Transparent = True
          end
          object lblOpeTotalVentas: TcxLabel
            Left = 175
            Top = 102
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 8
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 325
          end
        end
        object pnlCobros: TPanel
          Left = 8
          Top = 146
          Width = 864
          Height = 230
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 2
          object lblCobrosTitulo: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Cobros'
            Style.TextColor = clNavy
            TabOrder = 0
            Transparent = True
          end
          object lblCobValesRecLbl: TcxLabel
            Left = 16
            Top = 34
            Caption = '- Vales recogidos'
            TabOrder = 1
            Transparent = True
          end
          object lblCobValesRec: TcxLabel
            Left = 190
            Top = 34
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 2
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblCobValesEmiLbl: TcxLabel
            Left = 16
            Top = 60
            Caption = '+ Vales emitidos'
            TabOrder = 3
            Transparent = True
          end
          object lblCobValesEmi: TcxLabel
            Left = 190
            Top = 60
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 4
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblCobClientesLbl: TcxLabel
            Left = 16
            Top = 86
            Caption = '+ Cobros clientes'
            TabOrder = 5
            Transparent = True
          end
          object lblCobClientes: TcxLabel
            Left = 190
            Top = 86
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 6
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblCobPendienteLbl: TcxLabel
            Left = 16
            Top = 112
            Caption = '- Pendiente cobro'
            TabOrder = 7
            Transparent = True
          end
          object lblCobPendiente: TcxLabel
            Left = 190
            Top = 112
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 8
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblCobIngresosLbl: TcxLabel
            Left = 16
            Top = 144
            Caption = '= Ingresos caja'
            TabOrder = 9
            Transparent = True
          end
          object lblCobIngresos: TcxLabel
            Left = 190
            Top = 144
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 10
            Transparent = True
            Height = 21
            Width = 150
            AnchorX = 340
          end
          object lblEftIngresosLbl: TcxLabel
            Left = 400
            Top = 34
            Caption = 'Eftvo. ingresos'
            TabOrder = 11
            Transparent = True
          end
          object lblEftIngresos: TcxLabel
            Left = 690
            Top = 34
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 12
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblEftEntradasLbl: TcxLabel
            Left = 400
            Top = 60
            Caption = '+ Efectivo entradas'
            TabOrder = 13
            Transparent = True
          end
          object lblEftEntradas: TcxLabel
            Left = 690
            Top = 60
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 14
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblEftSalidasLbl: TcxLabel
            Left = 400
            Top = 86
            Caption = '- Efectivo salidas'
            TabOrder = 15
            Transparent = True
          end
          object lblEftSalidas: TcxLabel
            Left = 690
            Top = 86
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 16
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblEftAnteriorLbl: TcxLabel
            Left = 400
            Top = 112
            Caption = '+ Efectivo anterior'
            TabOrder = 17
            Transparent = True
          end
          object lblEftAnterior: TcxLabel
            Left = 690
            Top = 112
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 18
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblEftCajaLbl: TcxLabel
            Left = 400
            Top = 138
            Caption = '= Efectivo en caja'
            TabOrder = 19
            Transparent = True
          end
          object lblEftCaja: TcxLabel
            Left = 690
            Top = 138
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 20
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblTarjetasLbl: TcxLabel
            Left = 400
            Top = 164
            Caption = '+ Otros (tarj, bonos, divisa, cripto)'
            TabOrder = 21
            Transparent = True
          end
          object lblTarjetas: TcxLabel
            Left = 690
            Top = 164
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 22
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
          object lblSaldoLbl: TcxLabel
            Left = 400
            Top = 196
            Caption = '= Saldo efectivo + otros (a recontar)'
            TabOrder = 23
            Transparent = True
          end
          object lblSaldo: TcxLabel
            Left = 690
            Top = 196
            AutoSize = False
            Properties.Alignment.Horz = taRightJustify
            TabOrder = 24
            Transparent = True
            Height = 21
            Width = 160
            AnchorX = 850
          end
        end
      end
      object tsResumenes: TcxTabSheet
        Caption = '&2_Res'#250'menes'
        object pnlResEmpleado: TPanel
          Left = 8
          Top = 8
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          object lblResEmpleadoTit: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Neto ventas por empleado'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object cxgrdResEmpleado: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResEmpleado: TcxGridDBTableView
              DataController.DataSource = dsResEmpleado
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResEmpleadoEMP: TcxGridDBColumn
                Caption = 'Empleado'
                DataBinding.FieldName = 'EMPLEADO'
                Width = 150
              end
              object tvResEmpleadoUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 70
              end
              object tvResEmpleadoNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResEmpleado: TcxGridLevel
              GridView = tvResEmpleado
            end
          end
        end
        object pnlResFP: TPanel
          Left = 444
          Top = 8
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object lblResFPTit: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Neto ventas por forma de pago'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object cxgrdResFP: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResFP: TcxGridDBTableView
              DataController.DataSource = dsResFP
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResFPFP: TcxGridDBColumn
                Caption = 'Forma de pago'
                DataBinding.FieldName = 'FP'
                Width = 150
              end
              object tvResFPUDS: TcxGridDBColumn
                Caption = 'Cobros'
                DataBinding.FieldName = 'UDS'
                Width = 70
              end
              object tvResFPNETO: TcxGridDBColumn
                Caption = 'Importe'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResFP: TcxGridLevel
              GridView = tvResFP
            end
          end
        end
        object pnlResFam: TPanel
          Left = 8
          Top = 186
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 2
          object lblResFamTit: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Neto ventas por familia'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object cxgrdResFam: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResFam: TcxGridDBTableView
              DataController.DataSource = dsResFam
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResFamFAM: TcxGridDBColumn
                Caption = 'Familia'
                DataBinding.FieldName = 'FAMILIA'
                Width = 200
              end
              object tvResFamUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 60
              end
              object tvResFamNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResFam: TcxGridLevel
              GridView = tvResFam
            end
          end
        end
        object pnlResProp: TPanel
          Left = 444
          Top = 186
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 3
          object lblResPropTit: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Neto ventas por propiedad'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object cxgrdResProp: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResProp: TcxGridDBTableView
              DataController.DataSource = dsResProp
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResPropPROP: TcxGridDBColumn
                Caption = 'Propiedad'
                DataBinding.FieldName = 'PROP'
                Width = 120
              end
              object tvResPropVAL: TcxGridDBColumn
                Caption = 'Valor'
                DataBinding.FieldName = 'VALOR'
                Width = 130
              end
              object tvResPropUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 50
              end
              object tvResPropNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 100
              end
            end
            object lvResProp: TcxGridLevel
              GridView = tvResProp
            end
          end
        end
      end
      object tsMasDatos: TcxTabSheet
        Caption = '&3_M'#225's datos'
        object pnlResIVA: TPanel
          Left = 8
          Top = 8
          Width = 864
          Height = 250
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          object lblResIVATit: TcxLabel
            Left = 10
            Top = 6
            Caption = 'Resumen por IVA'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object cxgrdResIVA: TcxGrid
            Left = 8
            Top = 30
            Width = 848
            Height = 210
            TabOrder = 0
            object tvResIVA: TcxGridDBTableView
              DataController.DataSource = dsResIVA
              OptionsView.GroupByBox = False
              object tvResIVABASE: TcxGridDBColumn
                Caption = 'Bases'
                DataBinding.FieldName = 'BASE'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVAPORC_IVA: TcxGridDBColumn
                Caption = '% IVA'
                DataBinding.FieldName = 'PORC_IVA'
                Width = 80
              end
              object tvResIVACUOTA_IVA: TcxGridDBColumn
                Caption = 'Cuota IVA'
                DataBinding.FieldName = 'CUOTA_IVA'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVAPORC_RE: TcxGridDBColumn
                Caption = '% RE'
                DataBinding.FieldName = 'PORC_RE'
                Width = 80
              end
              object tvResIVACUOTA_RE: TcxGridDBColumn
                Caption = 'Cuota RE'
                DataBinding.FieldName = 'CUOTA_RE'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVABASE_IVAS: TcxGridDBColumn
                Caption = 'Base + IVAS'
                DataBinding.FieldName = 'BASE_IVAS'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResIVA: TcxGridLevel
              GridView = tvResIVA
            end
          end
        end
      end
      object tsRecuento: TcxTabSheet
        Caption = '&4_Recuento'
        object pnlAnterior: TPanel
          Left = 8
          Top = 4
          Width = 956
          Height = 26
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          object lblAnteriorTit: TcxLabel
            Left = 4
            Top = 2
            Caption = 'Resto d'#237'a anterior:'
            Style.TextColor = clNavy
            TabOrder = 0
            Transparent = True
          end
          object lblAnteriorImporte: TcxLabel
            Left = 180
            Top = 2
            Caption = '0,00 EUR'
            TabOrder = 1
            Transparent = True
          end
        end
        object pnlOtrasFP: TPanel
          Left = 8
          Top = 32
          Width = 956
          Height = 186
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object lblOtrasFPTit: TcxLabel
            Left = 8
            Top = 4
            Caption = 'Recuento por forma de pago'
            Style.TextColor = clNavy
            TabOrder = 1
            Transparent = True
          end
          object btnDesgloseEfectivo: TcxButton
            Left = 700
            Top = 2
            Width = 250
            Height = 22
            Action = actDesglose
            TabOrder = 2
            Visible = False
          end
          object cxgrdRecuento: TcxGrid
            Left = 4
            Top = 26
            Width = 946
            Height = 154
            TabOrder = 0
            object tvRecuento: TcxGridTableView
              OnCellClick = tvRecuentoCellClick
              OnEditing = tvRecuentoEditing
              OnKeyDown = tvRecuentoKeyDown
              OnEditValueChanged = tvRecuentoImportePropertiesEditValueChanged
              OptionsBehavior.FocusCellOnTab = True
              OptionsData.Deleting = False
              OptionsData.Inserting = False
              OptionsView.ColumnAutoWidth = True
              OptionsView.GroupByBox = False
              object tvRecuentoFP: TcxGridColumn
                Caption = 'C'#243'digo'
                Options.Editing = False
                Width = 70
              end
              object tvRecuentoDesc: TcxGridColumn
                Caption = 'Forma de pago'
                Options.Editing = False
                Width = 160
              end
              object tvRecuentoSistema: TcxGridColumn
                Caption = 'Sistema'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Options.Editing = False
                Width = 110
              end
              object tvRecuentoImporte: TcxGridColumn
                Caption = 'Recontado'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 110
              end
              object tvRecuentoDiferencia: TcxGridColumn
                Caption = 'Diferencia'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Options.Editing = False
                Width = 100
              end
            end
            object lvRecuento: TcxGridLevel
              GridView = tvRecuento
            end
          end
        end
        object pnlRecuentoTotales: TPanel
          Left = 8
          Top = 224
          Width = 956
          Height = 195
          BevelInner = bvLowered
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 2
          object lblDesgloseEfectivo: TcxLabel
            Left = 8
            Top = 4
            AutoSize = False
            Style.TextColor = clGray
            TabOrder = 0
            Transparent = True
            Height = 35
            Width = 633
          end
          object lblRecTotalSistemaLbl: TcxLabel
            Left = 9
            Top = 41
            Caption = 'Total sistema:'
            TabOrder = 1
            Transparent = True
          end
          object lblRecTotalSistema: TcxLabel
            Left = 121
            Top = 41
            AutoSize = False
            Properties.Alignment.Horz = taLeftJustify
            TabOrder = 2
            Transparent = True
            Height = 19
            Width = 100
          end
          object lblRecTotalRecuentoLbl: TcxLabel
            Left = 241
            Top = 41
            Caption = 'Total recontado:'
            TabOrder = 3
            Transparent = True
          end
          object lblRecTotalRecuento: TcxLabel
            Left = 370
            Top = 41
            AutoSize = False
            Properties.Alignment.Horz = taLeftJustify
            TabOrder = 4
            Transparent = True
            Height = 19
            Width = 100
          end
          object lblRecDiferenciaLbl: TcxLabel
            Left = 491
            Top = 41
            Caption = 'Diferencia:'
            TabOrder = 5
            Transparent = True
          end
          object lblRecDiferencia: TcxLabel
            Left = 578
            Top = 41
            AutoSize = False
            Properties.Alignment.Horz = taLeftJustify
            TabOrder = 6
            Transparent = True
            Height = 19
            Width = 130
          end
          object lblRetiradaLbl: TcxLabel
            Left = 9
            Top = 160
            Caption = 'Retirada:'
            TabOrder = 7
            Transparent = True
          end
          object txtRetiradaImporte: TcxCurrencyEdit
            Left = 180
            Top = 158
            EditValue = 0.000000000000000000
            Properties.OnChange = txtRetiradaImportePropertiesChange
            TabOrder = 8
            Width = 110
          end
          object rgRetiradaTipo: TcxRadioGroup
            Left = 9
            Top = 63
            Properties.Columns = 5
            Properties.Items = <
              item
                Caption = 'Banco'
              end
              item
                Caption = 'Encargado'
              end
              item
                Caption = 'C. fuerte'
              end>
            ItemIndex = 0
            TabOrder = 9
            Height = 48
            Width = 601
          end
          object lblDejoLbl: TcxLabel
            Left = 8
            Top = 123
            Caption = 'Dejo para sig. turno:'
            TabOrder = 10
            Transparent = True
          end
          object txtDejoImporte: TcxCurrencyEdit
            Left = 180
            Top = 119
            EditValue = 0.000000000000000000
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Properties.OnChange = txtDejoImportePropertiesChange
            TabStop = False
            TabOrder = 11
            Width = 110
          end
          object lblObservacionesLbl: TcxLabel
            Left = 300
            Top = 123
            Caption = 'Obs:'
            TabOrder = 12
            Transparent = True
          end
          object txtObservaciones: TcxTextEdit
            Left = 340
            Top = 119
            Properties.MaxLength = 500
            TabOrder = 13
            Width = 280
          end
          object lblVendedorLbl: TcxLabel
            Left = 300
            Top = 160
            Caption = 'Vendedor:'
            TabOrder = 14
            Transparent = True
          end
          object txtVendedorCodigo: TcxButtonEdit
            Left = 450
            Top = 158
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.MaxLength = 20
            Properties.OnButtonClick = txtVendedorCodigoPropertiesButtonClick
            TabOrder = 15
            OnExit = txtVendedorCodigoExit
            Width = 130
          end
          object lblVendedorNombre: TcxLabel
            Left = 586
            Top = 160
            AutoSize = False
            Style.TextColor = clGray
            Properties.Alignment.Horz = taLeftJustify
            TabOrder = 16
            Transparent = True
            Height = 19
            Width = 150
          end
        end
        object btnGrabarArqueo: TcxButton
          Left = 340
          Top = 425
          Width = 320
          Height = 34
          Caption = 'Grabar Arqueo y emitir justificante (F2)'
          TabOrder = 3
          OnClick = btnGrabarArqueoClick
        end
      end
    end
  end
  object pnlBottom: TPanel [2]
    Left = 0
    Top = 589
    Width = 1006
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 2
    ExplicitTop = 581
    ExplicitWidth = 1004
    object lblESC: TcxLabel
      Left = 600
      Top = 14
      Caption = 'ESC'
      Style.TextColor = clBlue
      TabOrder = 1
      Transparent = True
    end
    object btnAtras: TcxButton
      Left = 650
      Top = 8
      Width = 200
      Height = 35
      Cancel = True
      Caption = 'Atr'#225's (ESC)'
      TabOrder = 0
      OnClick = btnAtrasClick
    end
  end
  object alArqueo: TActionList
    Left = 16
    Top = 540
    object actEscape: TAction
      Caption = 'Escape'
      ShortCut = 27
      OnExecute = actEscapeExecute
    end
    object actTiraCaja: TAction
      Caption = 'Tira de Caja'
      ShortCut = 118
      OnExecute = actTiraCajaExecute
    end
    object actRecalcular: TAction
      Caption = 'Recalcular'
      ShortCut = 116
      OnExecute = actRecalcularExecute
    end
    object actImprimir: TAction
      Caption = 'Imprimir'
      ShortCut = 122
      OnExecute = actImprimirExecute
    end
    object actGrabar: TAction
      Caption = 'Grabar'
      ShortCut = 113
      OnExecute = actGrabarExecute
    end
    object actDesplegarDesde: TAction
      Caption = 'Desplegar Desde'
      ShortCut = 121
      OnExecute = actDesplegarDesdeExecute
    end
    object actDesplegarHasta: TAction
      Caption = 'Desplegar Hasta'
      ShortCut = 117
      OnExecute = actDesplegarHastaExecute
    end
    object actHistorico: TAction
      Caption = 'Hist'#243'rico'
      ShortCut = 119
      OnExecute = actHistoricoExecute
    end
    object actDesglose: TAction
      Caption = 'Desglosar efectivo (F3)'
      ShortCut = 114
      OnExecute = actDesgloseExecute
    end
  end
  object dsResEmpleado: TDataSource
    Left = 760
    Top = 80
  end
  object dsResFP: TDataSource
    Left = 760
    Top = 160
  end
  object dsResFam: TDataSource
    Left = 760
    Top = 240
  end
  object dsResProp: TDataSource
    Left = 760
    Top = 320
  end
  object dsResIVA: TDataSource
    Left = 760
    Top = 400
  end
end

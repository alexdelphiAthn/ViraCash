inherited frmMtoCajaFormasPago: TfrmMtoCajaFormasPago
  Caption = 'Formas de Pago Caja'
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
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_FP_CFP: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_FP_CFP'
              Width = 100
            end
            object cxGrdDBTabPrinDESCRIPCION_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_CFP'
              Width = 220
            end
            object cxGrdDBTabPrinESACTIVO_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinORDEN_VISUAL_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Orden F12'
              DataBinding.FieldName = 'ORDEN_VISUAL_FORMA_PAGO_CFP'
              HeaderAlignmentHorz = taRightJustify
              Width = 90
            end
            object cxGrdDBTabPrinESREQ_REFERENCIA_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Pide Referencia'
              DataBinding.FieldName = 'ESREQ_REFERENCIA_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 120
            end
            object cxGrdDBTabPrinESCRIPTO_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Cripto'
              DataBinding.FieldName = 'ESCRIPTO_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinESDIVISA_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Divisa'
              DataBinding.FieldName = 'ESDIVISA_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinESDEVUELVE_CAMBIO_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Devuelve Cambio'
              DataBinding.FieldName = 'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 130
            end
            object cxGrdDBTabPrinESABRE_CAJON_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Abre Caj'#243'n'
              DataBinding.FieldName = 'ESABRE_CAJON_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 100
            end
            object cxGrdDBTabPrinPORCENTAJE_COMISION_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = '% Comisi'#243'n'
              DataBinding.FieldName = 'PORCENTAJE_COMISION_FORMA_PAGO_CFP'
              HeaderAlignmentHorz = taRightJustify
              Width = 100
            end
            object cxGrdDBTabPrinESCOMISION_INCL_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Comisi'#243'n Incl.'
              DataBinding.FieldName = 'ESCOMISION_INCL_FORMA_PAGO_CFP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 110
            end
            object cxGrdDBTabPrinNUM_COD_DIGIT_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Cod. D'#237'git.'
              DataBinding.FieldName = 'NUM_COD_DIGIT_FORMA_PAGO_CFP'
              Width = 90
            end
            object cxGrdDBTabPrinRED_BLOCKCHAIN_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Red Blockchain'
              DataBinding.FieldName = 'RED_BLOCKCHAIN_FORMA_PAGO_CFP'
              Visible = False
            end
            object cxGrdDBTabPrinHASH_BLOCKCHAIN_FORMA_PAGO_CFP: TcxGridDBColumn
              Caption = 'Hash Blockchain'
              DataBinding.FieldName = 'HASH_BLOCKCHAIN_FORMA_PAGO_CFP'
              Visible = False
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 121
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 121
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblCodigo: TcxLabel
              Left = 16
              Top = 16
              Caption = 'C'#243'digo'
              TabOrder = 0
              Transparent = True
            end
            object txtCODIGO_FP_CFP: TcxDBTextEdit
              Left = 130
              Top = 13
              DataBinding.DataField = 'CODIGO_FP_CFP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 1
              Width = 110
            end
            object lblDescripcion: TcxLabel
              Left = 16
              Top = 48
              Caption = 'Descripci'#243'n'
              TabOrder = 2
              Transparent = True
            end
            object txtDESCRIPCION_FORMA_PAGO_CFP: TcxDBTextEdit
              Left = 130
              Top = 45
              DataBinding.DataField = 'DESCRIPCION_FORMA_PAGO_CFP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 380
            end
            object chkESACTIVO_FORMA_PAGO_CFP: TcxDBCheckBox
              Left = 260
              Top = 14
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_FORMA_PAGO_CFP'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
            object lblOrdenVisual: TcxLabel
              Left = 16
              Top = 80
              Caption = 'Orden F12'
              TabOrder = 5
              Transparent = True
            end
            object spnORDEN_VISUAL_FORMA_PAGO_CFP: TcxDBSpinEdit
              Left = 130
              Top = 77
              DataBinding.DataField = 'ORDEN_VISUAL_FORMA_PAGO_CFP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 6
              Width = 110
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 121
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 129
          Width = 943
          Height = 355
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 355
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsComportamiento
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 351
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 30
            object tsComportamiento: TcxTabSheet
              Caption = '&0_Comportamiento'
              ImageIndex = 0
              object chkESREQ_REFERENCIA_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 24
                Top = 20
                Caption = 'Pide referencia (bono, autorizaci'#243'n tarjeta...)'
                DataBinding.DataField = 'ESREQ_REFERENCIA_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 0
                Transparent = True
                Width = 320
              end
              object chkESDIVISA_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 24
                Top = 48
                Caption = 'Es divisa (USD, GBP...)'
                DataBinding.DataField = 'ESDIVISA_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 1
                Transparent = True
                Width = 320
              end
              object chkESCRIPTO_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 24
                Top = 76
                Caption = 'Es criptomoneda'
                DataBinding.DataField = 'ESCRIPTO_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 2
                Transparent = True
                Width = 320
              end
              object chkESDEVUELVE_CAMBIO_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 24
                Top = 104
                Caption = 'Permite dar cambio'
                DataBinding.DataField = 'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 3
                Transparent = True
                Width = 320
              end
              object chkESABRE_CAJON_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 24
                Top = 132
                Caption = 'Abre caj'#243'n al cobrar'
                DataBinding.DataField = 'ESABRE_CAJON_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 4
                Transparent = True
                Width = 320
              end
              object lblPorcentajeComision: TcxLabel
                Left = 380
                Top = 24
                Caption = '% Comisi'#243'n'
                TabOrder = 5
                Transparent = True
              end
              object spnPORCENTAJE_COMISION_FORMA_PAGO_CFP: TcxDBSpinEdit
                Left = 504
                Top = 21
                DataBinding.DataField = 'PORCENTAJE_COMISION_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                TabOrder = 6
                Width = 100
              end
              object chkESCOMISION_INCL_FORMA_PAGO_CFP: TcxDBCheckBox
                Left = 380
                Top = 52
                Caption = 'Comisi'#243'n incluida en importe'
                DataBinding.DataField = 'ESCOMISION_INCL_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 7
                Transparent = True
                Width = 250
              end
              object lblNumCodDigit: TcxLabel
                Left = 380
                Top = 84
                Caption = 'Cod. dig. teclado'
                TabOrder = 8
                Transparent = True
              end
              object txtNUM_COD_DIGIT_FORMA_PAGO_CFP: TcxDBTextEdit
                Left = 504
                Top = 81
                DataBinding.DataField = 'NUM_COD_DIGIT_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 1
                TabOrder = 9
                Width = 40
              end
            end
            object tsBlockchain: TcxTabSheet
              Caption = '&1_Blockchain'
              ImageIndex = 1
              object lblRedBlockchain: TcxLabel
                Left = 24
                Top = 24
                Caption = 'Red blockchain'
                TabOrder = 0
                Transparent = True
              end
              object txtRED_BLOCKCHAIN_FORMA_PAGO_CFP: TcxDBTextEdit
                Left = 166
                Top = 21
                DataBinding.DataField = 'RED_BLOCKCHAIN_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 250
              end
              object lblHashBlockchain: TcxLabel
                Left = 24
                Top = 56
                Caption = 'Hash blockchain'
                TabOrder = 2
                Transparent = True
              end
              object txtHASH_BLOCKCHAIN_FORMA_PAGO_CFP: TcxDBTextEdit
                Left = 166
                Top = 53
                DataBinding.DataField = 'HASH_BLOCKCHAIN_FORMA_PAGO_CFP'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 500
              end
            end
            object tsAuditoria: TcxTabSheet
              Caption = '&2_Auditor'#237'a'
              ImageIndex = 2
              object pnlAuditoria: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 321
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object lblUsuarioAlta: TcxLabel
                  Left = 16
                  Top = 16
                  Caption = 'Usuario Alta'
                  TabOrder = 0
                  Transparent = True
                end
                object txtUSUARIOALTA: TcxDBTextEdit
                  Left = 160
                  Top = 13
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 150
                end
                object lblInstanteAlta: TcxLabel
                  Left = 16
                  Top = 48
                  Caption = 'Instante Alta'
                  TabOrder = 2
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 160
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 200
                end
                object lblUsuarioModif: TcxLabel
                  Left = 400
                  Top = 16
                  Caption = 'Usuario Modificaci'#243'n'
                  TabOrder = 4
                  Transparent = True
                end
                object txtUSUARIOMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 13
                  DataBinding.DataField = 'USUARIO_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 5
                  Width = 150
                end
                object lblInstanteModif: TcxLabel
                  Left = 400
                  Top = 48
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object txtINSTANTEMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 200
                end
              end
            end
          end
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmCajaFormasPago.unqryTablaG
  end
end

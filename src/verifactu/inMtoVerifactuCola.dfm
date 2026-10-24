inherited frmMtoVerifactuCola: TfrmMtoVerifactuCola
  Caption = 'Verifactu - Cola de Env'#237'os'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Appending = False
            OptionsData.Deleting = False
            OptionsData.Editing = True
            OptionsData.Inserting = False
            object cxGrdDBTabPrinID_VFCOLA: TcxGridDBColumn
              Caption = 'Id'
              DataBinding.FieldName = 'ID_VFCOLA'
              Options.Editing = False
              Width = 70
            end
            object cxGrdDBTabPrinSERIE_FAC_VFCOLA: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC_VFCOLA'
              Options.Editing = False
              Width = 110
            end
            object cxGrdDBTabPrinNUMERO_FAC_VFCOLA: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_FAC_VFCOLA'
              Options.Editing = False
              Width = 100
            end
            object cxGrdDBTabPrinTIPO_OPERACION_VFCOLA: TcxGridDBColumn
              Caption = 'Operaci'#243'n'
              DataBinding.FieldName = 'TIPO_OPERACION_VFCOLA'
              Options.Editing = False
              Width = 100
            end
            object cxGrdDBTabPrinESTADO_VFCOLA: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_VFCOLA'
              PropertiesClassName = 'TcxComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'PENDIENTE'
                'PROCESANDO'
                'ENVIADA'
                'ERROR')
              Width = 110
            end
            object cxGrdDBTabPrinCONTADOR_INTENTOS_VFCOLA: TcxGridDBColumn
              Caption = 'Intentos'
              DataBinding.FieldName = 'CONTADOR_INTENTOS_VFCOLA'
              Width = 80
            end
            object cxGrdDBTabPrinMENSAJE_ERROR_VFCOLA: TcxGridDBColumn
              Caption = 'Mensaje de error'
              DataBinding.FieldName = 'MENSAJE_ERROR_VFCOLA'
              PropertiesClassName = 'TcxTextEditProperties'
              Options.Editing = False
              Width = 400
            end
            object cxGrdDBTabPrinINSTANTE_PROXIMO_INTENTO_VFCOLA: TcxGridDBColumn
              Caption = 'Pr'#243'ximo intento'
              DataBinding.FieldName = 'INSTANTE_PROXIMO_INTENTO_VFCOLA'
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_ENVIO_VFCOLA: TcxGridDBColumn
              Caption = 'Enviada'
              DataBinding.FieldName = 'INSTANTE_ENVIO_VFCOLA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Encolada'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 110
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Modificada'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario modif.'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Width = 110
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnIrADocumento: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 34
      Caption = 'Ir a &Documento'
      TabOrder = 2
      OnClick = btnIrADocumentoClick
    end
    object btnEnviarYa: TcxButton
      Left = 1
      Top = 158
      Width = 138
      Height = 34
      Caption = 'Enviar &ya'
      TabOrder = 3
      OnClick = btnEnviarYaClick
    end
  end
end

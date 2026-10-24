inherited frmMtoVerifactuLog: TfrmMtoVerifactuLog
  Caption = 'Verifactu - Log'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Appending = False
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            object cxGrdDBTabPrinID_LOG: TcxGridDBColumn
              Caption = 'Id'
              DataBinding.FieldName = 'ID_LOG'
              Width = 70
            end
            object cxGrdDBTabPrinTIMESTAMP_LOG: TcxGridDBColumn
              Caption = 'Fecha Hora'
              DataBinding.FieldName = 'TIMESTAMP_LOG'
              Width = 160
            end
            object cxGrdDBTabPrinTIPO_EVENTO_LOG: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_EVENTO_LOG'
              Width = 60
            end
            object cxGrdDBTabPrinDESCRIPCION_LOG: TcxGridDBColumn
              Caption = 'Evento'
              DataBinding.FieldName = 'DESCRIPCION_LOG'
              Width = 360
            end
            object cxGrdDBTabPrinDATOS_ADICIONALES_LOG: TcxGridDBColumn
              Caption = 'Datos adicionales'
              DataBinding.FieldName = 'DATOS_ADICIONALES_LOG'
              Width = 240
            end
            object cxGrdDBTabPrinSERIE_FAC_LOG: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC_LOG'
              Width = 100
            end
            object cxGrdDBTabPrinNUMERO_FAC_LOG: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_FAC_LOG'
              Width = 90
            end
            object cxGrdDBTabPrinUSUARIO_LOG: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_LOG'
              Width = 110
            end
            object cxGrdDBTabPrinVERSION_LOG: TcxGridDBColumn
              Caption = 'Versi'#243'n'
              DataBinding.FieldName = 'VERSION_LOG'
              Width = 170
            end
            object cxGrdDBTabPrinHASH_ANTERIOR_LOG: TcxGridDBColumn
              Caption = 'Hash anterior'
              DataBinding.FieldName = 'HASH_ANTERIOR_LOG'
              Width = 180
            end
            object cxGrdDBTabPrinHASH_PROPIO_LOG: TcxGridDBColumn
              Caption = 'Hash propio'
              DataBinding.FieldName = 'HASH_PROPIO_LOG'
              Width = 180
            end
            object cxGrdDBTabPrinFIRMA_DIGITAL_LOG: TcxGridDBColumn
              Caption = 'Firma'
              DataBinding.FieldName = 'FIRMA_DIGITAL_LOG'
              Width = 180
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
    object btnExportarNoVerifactu: TcxButton
      Left = 1
      Top = 160
      Width = 138
      Height = 34
      Caption = 'Exportar NO*VF'
      TabOrder = 3
      OnClick = btnExportarNoVerifactuClick
    end
    object btnVerificarNoVerifactu: TcxButton
      Left = 1
      Top = 200
      Width = 138
      Height = 34
      Caption = 'Verificar NO*VF'
      TabOrder = 4
      OnClick = btnVerificarNoVerifactuClick
    end
  end
end

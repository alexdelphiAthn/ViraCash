inherited frmMtoUsuariosPerfiles: TfrmMtoUsuariosPerfiles
  Caption = 'UsuariosPerfiles'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 3
        ExplicitTop = 32
        ExplicitWidth = 942
        ExplicitHeight = 480
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinUSUARIO_GRUPO_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_GRUPO_USUPER'
              Width = 210
            end
            object cxGrdDBTabPrinKEY_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'KEY_USUPER'
              Width = 132
            end
            object cxGrdDBTabPrinSUBKEY_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'SUBKEY_USUPER'
              Width = 382
            end
            object cxGrdDBTabPrinVALUE_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'VALUE_USUPER'
              Width = 234
            end
            object cxGrdDBTabPrinVALUE_TEXT_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'VALUE_TEXT_USUPER'
              PropertiesClassName = 'TcxBlobEditProperties'
              Properties.BlobEditKind = bekMemo
            end
            object cxGrdDBTabPrinTYPE_BLOB_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'TYPE_BLOB_USUPER'
            end
            object cxGrdDBTabPrinVALUE_BLOB_PERFILES: TcxGridDBColumn
              DataBinding.FieldName = 'VALUE_BLOB_USUPER'
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
end

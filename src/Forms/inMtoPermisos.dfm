inherited frmMtoPermisos: TfrmMtoPermisos
  Caption = 'Permisos'
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
            object cxGrdDBTabPrinUSUARIO_GRUPO_PERM: TcxGridDBColumn
              Caption = 'Usuario / Grupo'
              DataBinding.FieldName = 'USUARIO_GRUPO_PERM'
              Width = 200
            end
            object cxGrdDBTabPrinCODIGO_PERM: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_PERM'
              Width = 230
            end
            object cxGrdDBTabPrinVALOR_PERM: TcxGridDBColumn
              Caption = 'Valor'
              DataBinding.FieldName = 'VALOR_PERM'
              Width = 70
            end
            object cxGrdDBTabPrinDESCRIPCION_PERM: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_PERM'
              Width = 320
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

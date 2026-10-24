inherited frmMtoUnidadesMedida: TfrmMtoUnidadesMedida
  Caption = 'Unidades de Medida'
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
            object dbcGrdDBTabPrinCODIGO_UNIMED: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_UNIMED'
              Width = 100
            end
            object dbcGrdDBTabPrinDESCRIPCION_UNIMED: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_UNIMED'
              Width = 200
            end
            object dbcGrdDBTabPrinDECIMALES_UNIMED: TcxGridDBColumn
              Caption = 'Decimales'
              DataBinding.FieldName = 'DECIMALES_UNIMED'
              HeaderAlignmentHorz = taRightJustify
              Width = 90
            end
            object dbcGrdDBTabPrinMAGNITUD_UNIMED: TcxGridDBColumn
              Caption = 'Magnitud'
              DataBinding.FieldName = 'MAGNITUD_UNIMED'
              Width = 120
            end
            object dbcGrdDBTabPrinESBASE_UNIMED: TcxGridDBColumn
              Caption = 'Es Base'
              DataBinding.FieldName = 'ESBASE_UNIMED'
              Width = 70
            end
            object dbcGrdDBTabPrinFACTOR_BASE_UNIMED: TcxGridDBColumn
              Caption = 'Factor a Base'
              DataBinding.FieldName = 'FACTOR_BASE_UNIMED'
              HeaderAlignmentHorz = taRightJustify
              Width = 120
            end
            object dbcGrdDBTabPrinORDEN_UNIMED: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_UNIMED'
              HeaderAlignmentHorz = taRightJustify
              Width = 70
            end
            object dbcGrdDBTabPrinESACTIVO_UNIMED: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_UNIMED'
              Width = 70
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
  inherited dsTablaG: TDataSource
    DataSet = dmUnidadesMedida.unqryTablaG
  end
end

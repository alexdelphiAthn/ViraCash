inherited frmMtoPropiedadesValores: TfrmMtoPropiedadesValores
  Caption = 'Valores de Propiedades'
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
            object cxGrdDBTabPrinID_PV_ARTPROP: TcxGridDBColumn
              Caption = 'ID'
              DataBinding.FieldName = 'ID_PV_ARTPROP'
              Options.Editing = False
              Width = 70
            end
            object cxGrdDBTabPrinID_PROP_PV: TcxGridDBColumn
              Caption = 'Propiedad'
              DataBinding.FieldName = 'ID_PROP_PV'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'CODIGO_PROP_ARTPROP'
              Properties.ListColumns = <
                item
                  FieldName = 'CODIGO_PROP_ARTPROP'
                  Caption.Text = 'C'#243'digo'
                  Width = 100
                end
                item
                  FieldName = 'NOMBRE_PROP_PROP'
                  Caption.Text = 'Nombre'
                  Width = 200
                end>
              Properties.ListSource = dmPropiedadesValores.dsPropiedades
              Width = 180
            end
            object cxGrdDBTabPrinPV: TcxGridDBColumn
              Caption = 'Valor'
              DataBinding.FieldName = 'PV'
              Width = 220
            end
            object cxGrdDBTabPrinDESCRIPCION_PV: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_PV'
              Width = 280
            end
            object cxGrdDBTabPrinESACTIVO_PV: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_PV'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
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
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmPropiedadesValores.unqryTablaG
  end
end

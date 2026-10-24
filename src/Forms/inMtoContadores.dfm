inherited frmMtoContadores: TfrmMtoContadores
  Caption = 'Contadores'
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
            object cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR: TcxGridDBColumn
              Caption = 'Tipo de Documento'
              DataBinding.FieldName = 'TIPO_DOC_CON'
              Options.Editing = False
              Width = 71
            end
            object cxGrdDBTabPrinDESCRIPCION_TIPODOCUMENTO: TcxGridDBColumn
              Caption = 'Documento'
              DataBinding.FieldName = 'DESCRIPCION_TIPO_DOCUMENTO_TD'
              Width = 197
            end
            object cxGrdDBTabPrinTABLAORIGEN_TIPODOCUMENTO: TcxGridDBColumn
              Caption = 'Tabla de origen'
              DataBinding.FieldName = 'TABLA_ORIGEN_TIPO_DOCUMENTO_TD'
              Width = 188
            end
            object cxGrdDBTabPrinEMPRESA_CONTADOR: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'EMPRESA_CON'
              Width = 88
            end
            object cxgrdbclmnGrdDBTabPrinSERIE_CONTADOR: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_CON'
              Width = 114
            end
            object cxgrdbclmnGrdDBTabPrinCONTADOR_CONTADOR: TcxGridDBColumn
              Caption = 'Contador'
              DataBinding.FieldName = 'CON'
              Width = 88
            end
            object cxGrdDBTabPrinNUMDIGIT_CONTADOR: TcxGridDBColumn
              Caption = 'D'#237'gitos del contador'
              DataBinding.FieldName = 'NUM_DIGITOS_CON'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.MaxValue = 30.000000000000000000
              Width = 161
            end
            object cxGrdDBTabPrinACTIVO_CONTADOR: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_CON'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxgrdbclmnGrdDBTabPrinDEFAULT_CONTADOR: TcxGridDBColumn
              Caption = 'Es contador por defecto'
              DataBinding.FieldName = 'DEFAULT_CON'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 177
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
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
    DataSet = dmContadores.unqryTablaG
    Left = 96
    Top = 360
  end
end

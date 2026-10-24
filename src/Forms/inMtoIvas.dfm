inherited frmMtoIvas: TfrmMtoIvas
  Caption = 'IVA'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsCustomize.ColumnExpressionEditing = True
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_IVA: TcxGridDBColumn
              Caption = 'C'#243'digo IVA'
              DataBinding.FieldName = 'CODIGO_IVA'
              Width = 111
            end
            object cxGrdDBTabPrinGRUPO_ZONA_IVA: TcxGridDBColumn
              Caption = 'Zona IVA'
              DataBinding.FieldName = 'IVA_IVAGRP'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.KeyFieldNames = 'IVA_IVAGRP'
              Properties.ListColumns = <
                item
                  MinWidth = 50
                  FieldName = 'IVA_IVAGRP'
                end
                item
                  FieldName = 'DESCRIPCION_IVA_IVAGRP'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ListSource = dmIvas.dsZonas
              Width = 217
            end
            object cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
              Width = 277
            end
            object cxGrdDBTabPrinPORCENNORMAL_IVA: TcxGridDBColumn
              Caption = '%Normal'
              DataBinding.FieldName = 'PORCENTAJE_NORMAL_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 102
            end
            object cxGrdDBTabPrinPORCENNORMAL_RE_IVA: TcxGridDBColumn
              Caption = '%RE Normal'
              DataBinding.FieldName = 'PORCENTAJE_NORMAL_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 121
            end
            object cxGrdDBTabPrinPORCENREDUCIDO_IVA: TcxGridDBColumn
              Caption = '% Reducido'
              DataBinding.FieldName = 'PORCENTAJE_REDUCIDO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 123
            end
            object cxGrdDBTabPrinPORCENREDUCIDO_RE_IVA: TcxGridDBColumn
              Caption = '%RE Reducido'
              DataBinding.FieldName = 'PORCENTAJE_REDUCIDO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 158
            end
            object cxGrdDBTabPrinPORCENSUPERREDUCIDO_IVA: TcxGridDBColumn
              Caption = '%S'#250'perReducido'
              DataBinding.FieldName = 'PORCENTAJE_SUPERREDUCIDO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 170
            end
            object cxGrdDBTabPrinPORCENSUPERREDUCIDO_RE_IVA: TcxGridDBColumn
              Caption = '%RE SuperReducido'
              DataBinding.FieldName = 'PORCENTAJE_SUPERREDUCIDO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 213
            end
            object cxGrdDBTabPrinPORCENEXENTO_IVA: TcxGridDBColumn
              Caption = '%Exento'
              DataBinding.FieldName = 'PORCENTAJE_EXENTO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 88
            end
            object cxGrdDBTabPrinPORCENEXENTO_RE_IVA: TcxGridDBColumn
              Caption = '%RE Exento'
              DataBinding.FieldName = 'PORCENTAJE_EXENTO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 129
            end
            object cxGrdDBTabPrinFECHA_DESDE_IVA: TcxGridDBColumn
              Caption = 'Validez Desde'
              DataBinding.FieldName = 'FECHA_DESDE_IVA'
              Width = 138
            end
            object cxGrdDBTabPrinFECHA_HASTA_IVA: TcxGridDBColumn
              Caption = 'Validez Hasta'
              DataBinding.FieldName = 'FECHA_HASTA_IVA'
              Width = 121
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
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
            object cxGrdDBTabPrinESAPLICA_RE_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESAPLICA_RE_IVA_IVAGRP'
              Visible = False
            end
            object cxGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESIVAAGRICOLA_IVA_IVAGRP'
              Visible = False
            end
            object cxGrdDBTabPrinESDEFAULT_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESDEFAULT_IVA_IVAGRP'
              Visible = False
            end
            object cxGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESIRPF_IMP_INCL_IVA_IVAGRP'
              Visible = False
            end
            object cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA: TcxGridDBColumn
              Caption = 'Palabra IVA'
              DataBinding.FieldName = 'PALABRA_REPORTS_IVA_IVAGRP'
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Enabled = False
        TabVisible = False
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmIvas.unqryTablaG
  end
end

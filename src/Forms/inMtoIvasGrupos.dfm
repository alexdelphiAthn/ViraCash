inherited frmMtoIvasGrupos: TfrmMtoIvasGrupos
  Caption = 'IVA'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinGRUPO_ZONA_IVA: TcxGridDBColumn
              Caption = 'C'#243'digo Zona'
              DataBinding.FieldName = 'IVA_IVAGRP'
              Width = 143
            end
            object cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn
              Caption = 'Descripci'#243'n Zona'
              DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
              Width = 324
            end
            object cxGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA: TcxGridDBColumn
              Caption = 'REAGP'
              DataBinding.FieldName = 'ESIVAAGRICOLA_IVA_IVAGRP'
              Width = 85
            end
            object cxGrdDBTabPrinESAPLICA_RE_ZONA_IVA: TcxGridDBColumn
              Caption = 'Aplica RE'
              DataBinding.FieldName = 'ESAPLICA_RE_IVA_IVAGRP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 106
            end
            object cxGrdDBTabPrinESDEFAULT_ZONA_IVA: TcxGridDBColumn
              Caption = 'Zona por Defecto'
              DataBinding.FieldName = 'ESDEFAULT_IVA_IVAGRP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 190
            end
            object cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA: TcxGridDBColumn
              Caption = 'Palabra IVA'
              DataBinding.FieldName = 'PALABRA_REPORTS_IVA_IVAGRP'
            end
            object cxGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA: TcxGridDBColumn
              Caption = 'IRPF Imp Incl'
              DataBinding.FieldName = 'ESIRPF_IMP_INCL_IVA_IVAGRP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 115
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Enabled = False
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmIvasGrupos.unqryTablaG
  end
end

inherited frmMtoEmpleados: TfrmMtoEmpleados
  Caption = 'Empleados'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_EMPL: TcxGridDBColumn
              Caption = 'C'#243'digo Empleado'
              DataBinding.FieldName = 'CODIGO_EMPL'
              Width = 130
            end
            object cxGrdDBTabPrinNOMBRE_EMPL: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_EMPL'
              Width = 230
            end
            object cxGrdDBTabPrinRAZON_SOCIAL_EMPL: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPL'
              Width = 230
            end
            object cxGrdDBTabPrinNIF_EMPL: TcxGridDBColumn
              Caption = 'NIF'
              DataBinding.FieldName = 'NIF_EMPL'
              Width = 110
            end
            object cxGrdDBTabPrinDIRECCION_EMPL: TcxGridDBColumn
              Caption = 'Direcci'#243'n 1'
              DataBinding.FieldName = 'DIRECCION_EMPL'
              Width = 260
            end
            object cxGrdDBTabPrinDIRECCION2_EMPL: TcxGridDBColumn
              Caption = 'Direcci'#243'n 2'
              DataBinding.FieldName = 'DIRECCION2_EMPL'
              Width = 220
            end
            object cxGrdDBTabPrinCODIGO_POSTAL_EMPL: TcxGridDBColumn
              Caption = 'C.P.'
              DataBinding.FieldName = 'CODIGO_POSTAL_EMPL'
              Width = 80
            end
            object cxGrdDBTabPrinPOBLACION_EMPL: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_EMPL'
              Width = 150
            end
            object cxGrdDBTabPrinPROVINCIA_EMPL: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_EMPL'
              Width = 130
            end
            object cxGrdDBTabPrinTELEFONO_EMPL: TcxGridDBColumn
              Caption = 'Tel'#233'fono 1'
              DataBinding.FieldName = 'TELEFONO_EMPL'
              Width = 120
            end
            object cxGrdDBTabPrinTELEFONO2_EMPL: TcxGridDBColumn
              Caption = 'Tel'#233'fono 2'
              DataBinding.FieldName = 'TELEFONO2_EMPL'
              Width = 120
            end
            object cxGrdDBTabPrinFAX_EMPL: TcxGridDBColumn
              Caption = 'Fax'
              DataBinding.FieldName = 'FAX_EMPL'
              Width = 120
            end
            object cxGrdDBTabPrinEMAIL_EMPL: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_EMPL'
              Width = 180
            end
            object cxGrdDBTabPrinWEB_EMPL: TcxGridDBColumn
              Caption = 'Web'
              DataBinding.FieldName = 'WEB_EMPL'
              Width = 180
            end
            object cxGrdDBTabPrinIBAN_EMPL: TcxGridDBColumn
              Caption = 'IBAN'
              DataBinding.FieldName = 'IBAN_EMPL'
              Width = 200
            end
            object cxGrdDBTabPrinBIC_EMPL: TcxGridDBColumn
              Caption = 'BIC'
              DataBinding.FieldName = 'BIC_EMPL'
              Width = 90
            end
            object cxGrdDBTabPrinDIMINUTIVO_TICKET_EMPL: TcxGridDBColumn
              Caption = 'Diminutivo Caja'
              DataBinding.FieldName = 'DIMINUTIVO_TICKET_EMPL'
              Width = 130
            end
            object cxGrdDBTabPrinESACTIVO_EMPL: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_EMPL'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmEmpleados.unqryTablaG
  end
end

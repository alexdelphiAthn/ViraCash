inherited frmMtoComprasPlantillas: TfrmMtoComprasPlantillas
  Caption = 'Plantillas de Sesiones de Compra'
  ClientHeight = 700
  ClientWidth = 1100
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1100
  ExplicitHeight = 700
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 960
    Height = 700
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 960
    ExplicitHeight = 700
    inherited pcPantalla: TcxPageControl
      Width = 960
      Height = 660
      ExplicitWidth = 960
      ExplicitHeight = 660
      ClientRectBottom = 658
      ClientRectRight = 958
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcCodigoSespl: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_SESPL'
              Width = 100
            end
            object dbcNombreSespl: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_SESPL'
              Width = 250
            end
            object dbcCodigoPrvSespl: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SESPL'
              Width = 100
            end
            object dbcCodigoFamSespl: TcxGridDBColumn
              Caption = 'Familia'
              DataBinding.FieldName = 'CODIGO_FAM_SESPL'
              Width = 100
            end
            object dbcEsactivaSespl: TcxGridDBColumn
              Caption = 'Activa'
              DataBinding.FieldName = 'ESACTIVA_SESPL'
              Width = 70
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        object pcPlantilla: TcxPageControl
          Left = 0
          Top = 0
          Width = 956
          Height = 629
          Align = alClient
          TabOrder = 0
          Properties.ActivePage = tsDatos
          Properties.CustomButtons.Buttons = <>
          ClientRectBottom = 627
          ClientRectLeft = 2
          ClientRectRight = 954
          ClientRectTop = 29
          object tsDatos: TcxTabSheet
            Caption = 'Datos'
            object gbDatos: TcxGroupBox
              Left = 8
              Top = 8
              Caption = ' Cabecera de plantilla '
              TabOrder = 0
              Height = 580
              Width = 928
              object lblCodigo: TcxLabel
                Left = 16
                Top = 24
                Caption = 'C'#243'digo'
                TabOrder = 10
                Transparent = True
              end
              object txtCodigo: TcxDBTextEdit
                Left = 100
                Top = 22
                DataBinding.DataField = 'CODIGO_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 120
              end
              object lblNombre: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Nombre'
                TabOrder = 11
                Transparent = True
              end
              object txtNombre: TcxDBTextEdit
                Left = 100
                Top = 58
                DataBinding.DataField = 'NOMBRE_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 400
              end
              object lblDescripcion: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Descripci'#243'n'
                TabOrder = 12
                Transparent = True
              end
              object txtDescripcion: TcxDBTextEdit
                Left = 100
                Top = 94
                DataBinding.DataField = 'DESCRIPCION_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 700
              end
              object lblProveedor: TcxLabel
                Left = 16
                Top = 132
                Caption = 'Proveedor'
                TabOrder = 13
                Transparent = True
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 100
                Top = 130
                DataBinding.DataField = 'CODIGO_PRV_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 3
                Width = 280
              end
              object lblFamilia: TcxLabel
                Left = 400
                Top = 132
                Caption = 'Familia'
                TabOrder = 14
                Transparent = True
              end
              object cbbFamilia: TcxDBLookupComboBox
                Left = 460
                Top = 130
                DataBinding.DataField = 'CODIGO_FAM_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 4
                Width = 200
              end
              object lblVariacion: TcxLabel
                Left = 16
                Top = 168
                Caption = 'Variaci'#243'n'
                TabOrder = 15
                Transparent = True
              end
              object cbbVariacion: TcxDBLookupComboBox
                Left = 100
                Top = 166
                DataBinding.DataField = 'CODIGO_VAR_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 5
                Width = 200
              end
              object chkVarFija: TcxDBCheckBox
                Left = 320
                Top = 166
                Caption = 'Variaci'#243'n fija por l'#237'nea'
                DataBinding.DataField = 'ESVAR_FIJA_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 6
              end
              object lblConjPivot: TcxLabel
                Left = 16
                Top = 204
                Caption = 'Conj. pivot'
                TabOrder = 16
                Transparent = True
              end
              object cbbConjuntoPivot: TcxDBLookupComboBox
                Left = 100
                Top = 202
                DataBinding.DataField = 'ID_AC_PIVOT_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 7
                Width = 280
              end
              object lblConjFila: TcxLabel
                Left = 16
                Top = 240
                Caption = 'Conj. fila'
                TabOrder = 17
                Transparent = True
              end
              object cbbConjuntoFila: TcxDBLookupComboBox
                Left = 100
                Top = 238
                DataBinding.DataField = 'ID_AC_FILA_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 8
                Width = 280
              end
              object chkActiva: TcxDBCheckBox
                Left = 16
                Top = 280
                Caption = 'Plantilla activa'
                DataBinding.DataField = 'ESACTIVA_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 9
              end
            end
          end
          object tsPropsPlantilla: TcxTabSheet
            Caption = 'Propiedades'
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object cxgrdProps: TcxGrid
              Left = 0
              Top = 36
              Width = 944
              Height = 552
              Align = alClient
              TabOrder = 0
              object tvProps: TcxGridDBTableView
                object dbcPropsCodigo: TcxGridDBColumn
                  Caption = 'C'#243'digo'
                  DataBinding.FieldName = 'CODIGO_PROP_SESPLPROP'
                end
                object dbcPropsFijo: TcxGridDBColumn
                  Caption = 'Fijo'
                  DataBinding.FieldName = 'ESFIJO_SESPLPROP'
                end
                object dbcPropsValor: TcxGridDBColumn
                  Caption = 'Valor por defecto'
                  DataBinding.FieldName = 'VALOR_DEFECTO_SESPLPROP'
                end
              end
              object glProps: TcxGridLevel
                GridView = tvProps
              end
            end
            object btnAddProp: TcxButton
              Left = 8
              Top = 4
              Width = 100
              Height = 28
              Caption = '+ A'#241'adir'
              TabOrder = 1
              OnClick = btnAddPropClick
            end
            object btnDelProp: TcxButton
              Left = 116
              Top = 4
              Width = 100
              Height = 28
              Caption = '- Borrar'
              TabOrder = 2
              OnClick = btnDelPropClick
            end
          end
          object tsKitsPlantilla: TcxTabSheet
            Caption = 'Kits'
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object cxgrdKits: TcxGrid
              Left = 0
              Top = 36
              Width = 400
              Height = 552
              Align = alLeft
              TabOrder = 0
              object tvKits: TcxGridDBTableView
                object dbcKitsCodigo: TcxGridDBColumn
                  Caption = 'C'#243'digo'
                  DataBinding.FieldName = 'CODIGO_SESPLKIT'
                end
                object dbcKitsNombre: TcxGridDBColumn
                  Caption = 'Nombre'
                  DataBinding.FieldName = 'NOMBRE_SESPLKIT'
                end
              end
              object glKits: TcxGridLevel
                GridView = tvKits
              end
            end
            object cxgrdKitsDet: TcxGrid
              Left = 400
              Top = 36
              Width = 544
              Height = 552
              Align = alClient
              TabOrder = 1
              object tvKitsDet: TcxGridDBTableView
                object dbcKitsDetValor: TcxGridDBColumn
                  Caption = 'Valor (talla)'
                  DataBinding.FieldName = 'VALOR_DESTINO_SESPLKITD'
                end
                object dbcKitsDetCantidad: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD_SESPLKITD'
                end
              end
              object glKitsDet: TcxGridLevel
                GridView = tvKitsDet
              end
            end
            object btnAddKit: TcxButton
              Left = 8
              Top = 4
              Width = 100
              Height = 28
              Caption = '+ Kit'
              TabOrder = 2
              OnClick = btnAddKitClick
            end
            object btnDelKit: TcxButton
              Left = 116
              Top = 4
              Width = 100
              Height = 28
              Caption = '- Kit'
              TabOrder = 3
              OnClick = btnDelKitClick
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 954
        ExplicitHeight = 627
        inherited pnlPerfilTop: TPanel
          Width = 956
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 954
        end
        inherited pnlPerfilDetail: TPanel
          Width = 956
          Height = 572
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 960
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 960
      inherited pnlTopGrid: TPanel
        Width = 960
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 960
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 960
    Height = 700
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 960
    ExplicitHeight = 700
    inherited pButtonGen: TPanel
      Top = 502
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
end

inherited frmModalServiciosOffLine: TfrmModalServiciosOffLine
  ActiveControl = edtUsuarioCuenta
  BorderStyle = bsDialog
  Caption = 'Establecer servicios off line'
  ClientHeight = 440
  ClientWidth = 720
  Position = poMainFormCenter
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 380
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblIntroduccion: TcxLabel
      Left = 20
      Top = 10
      AutoSize = False
      Caption =
        'Deje programados en el servidor los procesos que conviene ' +
        'ejecutar fuera de hora. ViraCash los instala como tareas del ' +
        'Programador de tareas de Windows.'
      Style.TextColor = clNavy
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      TabOrder = 0
      Transparent = True
      Height = 46
      Width = 680
    end
    object pcServicios: TcxPageControl
      Left = 20
      Top = 60
      Width = 680
      Height = 312
      TabOrder = 1
      Properties.ActivePage = tsCuenta
      Properties.CustomButtons.Buttons = <>
      ClientRectBottom = 308
      ClientRectLeft = 4
      ClientRectRight = 676
      ClientRectTop = 28
      object tsCuenta: TcxTabSheet
        Caption = 'Cuenta de Windows'
        ImageIndex = 0
        object gbCuenta: TcxGroupBox
          Left = 12
          Top = 12
          Caption = ' Cuenta de Windows que ejecutará las tareas '
          TabOrder = 0
          Height = 96
          Width = 648
          object lblUsuarioCuenta: TcxLabel
            Left = 16
            Top = 26
            Caption = 'Usuario de Windows:'
            TabOrder = 2
            Transparent = True
          end
          object edtUsuarioCuenta: TcxTextEdit
            Left = 200
            Top = 24
            Properties.MaxLength = 120
            TabOrder = 0
            Width = 300
          end
          object lblContrasena: TcxLabel
            Left = 16
            Top = 58
            Caption = 'Contraseña:'
            TabOrder = 3
            Transparent = True
          end
          object edtContrasena: TcxTextEdit
            Left = 200
            Top = 56
            Properties.EchoMode = eemPassword
            Properties.PasswordChar = #9679
            TabOrder = 1
            Width = 300
          end
        end
        object lblUsuario: TcxLabel
          Left = 16
          Top = 124
          AutoSize = False
          Caption = ' '
          Style.TextColor = clMaroon
          Properties.WordWrap = True
          TabOrder = 1
          Transparent = True
          Height = 108
          Width = 640
        end
      end
      object tsCopia: TcxTabSheet
        Caption = 'Copia de seguridad'
        ImageIndex = 1
        object chkCopia: TcxCheckBox
          Left = 16
          Top = 24
          Caption = 'Dejar programada la copia de seguridad'
          Properties.OnEditValueChanged = chkCopiaPropertiesEditValueChanged
          TabOrder = 0
          Transparent = True
          Width = 420
        end
        object lblCarpetaCopia: TcxLabel
          Left = 16
          Top = 62
          Caption = 'Carpeta de destino:'
          TabOrder = 5
          Transparent = True
        end
        object edtCarpetaCopia: TcxButtonEdit
          Left = 200
          Top = 60
          Properties.Buttons = <
            item
              Default = True
              Kind = bkEllipsis
            end>
          Properties.OnButtonClick = edtCarpetaCopiaPropertiesButtonClick
          TabOrder = 1
          Width = 450
        end
        object lblNombreCopia: TcxLabel
          Left = 16
          Top = 100
          Caption = 'Nombre del fichero:'
          TabOrder = 6
          Transparent = True
        end
        object edtNombreCopia: TcxTextEdit
          Left = 200
          Top = 98
          Properties.MaxLength = 120
          TabOrder = 2
          Width = 450
        end
        object lblTokensCopia: TcxLabel
          Left = 200
          Top = 128
          AutoSize = False
          Caption =
            'El nombre admite DIASEMANA, DIAMES, MES y AÑO. La extensión ' +
            'debe ser .crypt.'
          Properties.WordWrap = True
          TabOrder = 7
          Transparent = True
          Height = 46
          Width = 450
        end
        object lblHoraCopia: TcxLabel
          Left = 16
          Top = 186
          Caption = 'Hora de arranque:'
          TabOrder = 8
          Transparent = True
        end
        object edtHoraCopia: TcxTimeEdit
          Left = 200
          Top = 184
          Properties.TimeFormat = tfHourMin
          TabOrder = 3
          Width = 110
        end
        object lblEstadoCopia: TcxLabel
          Left = 16
          Top = 214
          AutoSize = False
          Caption = 'No instalado.'
          Style.TextColor = clNavy
          Properties.WordWrap = True
          TabOrder = 9
          Transparent = True
          Height = 46
          Width = 648
        end
      end
      object tsPrecios: TcxTabSheet
        Caption = 'Precios medios'
        ImageIndex = 2
        object chkPrecios: TcxCheckBox
          Left = 16
          Top = 24
          Caption = 'Dejar programado el cálculo de precios medios'
          Properties.OnEditValueChanged = chkPreciosPropertiesEditValueChanged
          TabOrder = 0
          Transparent = True
          Width = 460
        end
        object lblExplicacionPrecios: TcxLabel
          Left = 16
          Top = 56
          AutoSize = False
          Caption =
            'Procesa la cola de recálculos de stock y precio medio ' +
            'pendientes hasta dejarla vacía.'
          Properties.WordWrap = True
          TabOrder = 3
          Transparent = True
          Height = 26
          Width = 648
        end
        object lblHoraPrecios: TcxLabel
          Left = 16
          Top = 92
          Caption = 'Hora de arranque:'
          TabOrder = 4
          Transparent = True
        end
        object edtHoraPrecios: TcxTimeEdit
          Left = 200
          Top = 90
          Properties.TimeFormat = tfHourMin
          TabOrder = 1
          Width = 110
        end
        object lblEstadoPrecios: TcxLabel
          Left = 16
          Top = 118
          AutoSize = False
          Caption = 'No instalado.'
          Style.TextColor = clNavy
          Properties.WordWrap = True
          TabOrder = 5
          Transparent = True
          Height = 46
          Width = 648
        end
      end
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 380
    Width = 720
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnInstalar: TcxButton
      Left = 400
      Top = 12
      Width = 140
      Height = 36
      Caption = '&Instalar'
      Default = True
      TabOrder = 0
      OnClick = btnInstalarClick
    end
    object btnCerrar: TcxButton
      Left = 560
      Top = 12
      Width = 140
      Height = 36
      Cancel = True
      Caption = '&Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end

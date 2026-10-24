inherited frmMtoModalScriptLog: TfrmMtoModalScriptLog
  Left = 0
  Top = 0
  Caption = 'Progreso de Ejecuci'#243'n del Script'
  ClientHeight = 500
  ClientWidth = 750
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 17
  object pnlBotonera: TPanel
    Left = 0
    Top = 462
    Width = 750
    Height = 38
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnGuardarComo: TButton
      Left = 607
      Top = 5
      Width = 135
      Height = 28
      Caption = 'Guardar como...'
      TabOrder = 0
      OnClick = btnGuardarComoClick
    end
  end
  object LogMemo: TSynEdit
    Left = 0
    Top = 0
    Width = 750
    Height = 462
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    TabOrder = 0
    Gutter.AutoSize = True
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.ShowLineNumbers = True
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object LogHigSQL: TSynSQLSyn
    SQLDialect = sqlMySQL
    Left = 32
    Top = 24
  end
end

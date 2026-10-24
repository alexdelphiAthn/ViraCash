inherited frmMtoModalAddPreciosTar: TfrmMtoModalAddPreciosTar
  Caption = 'A'#241'adir precios a Tarifas'
  ClientHeight = 600
  ClientWidth = 550
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 566
  ExplicitHeight = 639
  OnDestroy = FormDestroy
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 541
    Width = 550
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 533
    ExplicitWidth = 548
    inherited btnCancelar: TcxButton
      Left = 40
      ExplicitLeft = 40
    end
    inherited btnAceptar: TcxButton
      Left = 320
      ExplicitLeft = 320
    end
  end
  inherited pnlBody: TPanel
    Width = 550
    Height = 541
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 548
    ExplicitHeight = 533
    object lblSkus: TLabel
      AlignWithMargins = True
      Left = 11
      Top = 72
      Width = 528
      Height = 19
      Margins.Left = 10
      Margins.Top = 6
      Margins.Right = 10
      Margins.Bottom = 2
      Align = alTop
      Caption = ' 1. Seleccione el art'#237'culo, un color o una talla:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Source Sans 3'
      Font.Pitch = fpFixed
      Font.Style = [fsBold]
      Font.Quality = fqClearTypeNatural
      ParentFont = False
      ExplicitWidth = 414
      Transparent = True
    end
    object lblTarifas: TLabel
      AlignWithMargins = True
      Left = 11
      Top = 285
      Width = 528
      Height = 19
      Margins.Left = 10
      Margins.Top = 6
      Margins.Right = 10
      Margins.Bottom = 2
      Align = alTop
      Caption = ' 2. Seleccione las Tarifas:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Source Sans 3'
      Font.Pitch = fpFixed
      Font.Style = [fsBold]
      Font.Quality = fqClearTypeNatural
      ParentFont = False
      ExplicitWidth = 206
      Transparent = True
    end
    object pnlFechas: TPanel
      Left = 1
      Top = 1
      Width = 548
      Height = 65
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 546
      object lblDesde: TLabel
        Left = 12
        Top = 22
        Width = 122
        Height = 19
        Caption = 'Vigente desde:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Source Sans 3'
        Font.Pitch = fpFixed
        Font.Style = [fsBold]
        Font.Quality = fqClearTypeNatural
        ParentFont = False
        Transparent = True
      end
      object lblHasta: TLabel
        Left = 280
        Top = 22
        Width = 142
        Height = 19
        Caption = 'Hasta (opcional):'
        Transparent = True
      end
      object dtpDesde: TcxDateEdit
        Left = 141
        Top = 19
        TabOrder = 0
        Width = 120
      end
      object dtpHasta: TcxDateEdit
        Left = 424
        Top = 19
        TabOrder = 1
        Width = 120
      end
    end
    object chkSkus: TcxCheckListBox
      AlignWithMargins = True
      Left = 11
      Top = 95
      Width = 528
      Height = 180
      Margins.Left = 10
      Margins.Top = 2
      Margins.Right = 10
      Margins.Bottom = 4
      Align = alTop
      Items = <>
      TabOrder = 1
      ExplicitWidth = 526
    end
    object chkTarifas: TcxCheckListBox
      AlignWithMargins = True
      Left = 11
      Top = 308
      Width = 528
      Height = 228
      Margins.Left = 10
      Margins.Top = 2
      Margins.Right = 10
      Margins.Bottom = 4
      Align = alClient
      Items = <>
      TabOrder = 2
      ExplicitWidth = 526
      ExplicitHeight = 220
    end
  end
end

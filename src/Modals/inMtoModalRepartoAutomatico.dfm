inherited frmModalRepartoAutomatico: TfrmModalRepartoAutomatico
  Caption = 'Reparto autom'#225'tico'
  ClientHeight = 590
  ClientWidth = 620
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 636
  ExplicitHeight = 629
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 531
    Width = 620
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 531
    ExplicitWidth = 620
    inherited btnCancelar: TcxButton
      Left = 214
      ExplicitLeft = 214
    end
    inherited btnAceptar: TcxButton
      Left = 418
      ExplicitLeft = 418
    end
  end
  inherited pnlBody: TPanel
    Width = 620
    Height = 531
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 620
    ExplicitHeight = 531
    object lblDestinos: TcxLabel
      Left = 20
      Top = 14
      Caption = 'Tiendas que participan'
      TabOrder = 7
      Transparent = True
    end
    object clbDestinos: TcxCheckListBox
      Left = 20
      Top = 42
      Width = 400
      Height = 250
      Items = <>
      TabOrder = 0
    end
    object btnMarcarTodos: TcxButton
      Left = 436
      Top = 42
      Width = 164
      Height = 34
      Caption = 'Marcar todas'
      TabOrder = 1
      OnClick = btnMarcarTodosClick
    end
    object btnDesmarcarTodos: TcxButton
      Left = 436
      Top = 84
      Width = 164
      Height = 34
      Caption = 'Desmarcar todas'
      TabOrder = 2
      OnClick = btnDesmarcarTodosClick
    end
    object lblMaximo: TcxLabel
      Left = 20
      Top = 308
      Caption = 'M'#225'ximo por tienda y talla (0 = sin tope)'
      TabOrder = 8
      Transparent = True
    end
    object edtMaximo: TcxSpinEdit
      Left = 436
      Top = 304
      Properties.AssignedValues.MinValue = True
      Properties.ValueType = vtFloat
      TabOrder = 3
      Width = 164
    end
    object lblObjetivo: TcxLabel
      Left = 20
      Top = 346
      Caption = 'Stock objetivo por tienda y talla (0 = no mirar)'
      TabOrder = 9
      Transparent = True
    end
    object edtObjetivo: TcxSpinEdit
      Left = 436
      Top = 342
      Properties.AssignedValues.MinValue = True
      Properties.ValueType = vtFloat
      TabOrder = 4
      Width = 164
    end
    object rgCriterio: TcxRadioGroup
      Left = 20
      Top = 382
      Caption = ' Prioridad '
      Properties.Items = <
        item
          Caption = 'En ronda, por orden de almac'#233'n'
        end
        item
          Caption = 'Primero la tienda con menos existencias'
        end>
      ItemIndex = 0
      TabOrder = 5
      Height = 78
      Width = 580
    end
    object lblAyuda: TcxLabel
      Left = 20
      Top = 466
      AutoSize = False
      Caption =
        'Reparte lo recibido que queda por repartir. Se a'#241'ade a lo ya re' +
        'partido y respeta el origen fijado y el m'#237'nimo en origen.'
      Properties.WordWrap = True
      TabOrder = 6
      Transparent = True
      Height = 56
      Width = 580
    end
  end
end

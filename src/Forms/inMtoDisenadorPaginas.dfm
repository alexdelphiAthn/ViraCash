inherited frmDisenadorPaginas: TfrmDisenadorPaginas
  Caption = 'Datos y publicación'
  BorderStyle = bsDialog
  Position = poOwnerFormCenter
  ClientWidth = 780
  ClientHeight = 534
  object lblNombre: TcxLabel
    Left = 16
    Top = 12
    Width = 690
    Height = 21
    Caption = 'Nombre de la página'
  end
  object edtNombre: TcxTextEdit
    Left = 16
    Top = 38
    Width = 380
    Height = 26
    Properties.MaxLength = 53
    Properties.OnChange = CambiarNombrePagina
  end
  object lblGrupo: TcxLabel
    Left = 420
    Top = 12
    Caption = 'Nombre del proyecto'
  end
  object edtGrupo: TcxTextEdit
    Left = 420
    Top = 38
    Width = 340
    Height = 26
    Properties.MaxLength = 53
    Properties.OnChange = CambiarNombreProyecto
  end
  object pcEditor: TcxPageControl
    Left = 16
    Top = 85
    Width = 748
    Height = 381
    Properties.ActivePage = tsDatos
    object tsDatos: TcxTabSheet
      Caption = 'Lista y ficha'
      object lblTipo: TcxLabel
        Left = 12
        Top = 12
        Width = 690
        Height = 21
        Caption = 'Tipo de origen'
      end
      object cmbTipo: TcxComboBox
        Left = 12
        Top = 39
        Width = 180
        Height = 27
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = ElegirTipo
      end
      object lblOrigen: TcxLabel
        Left = 208
        Top = 12
        Width = 690
        Height = 21
        Caption = 'Origen de la base actual'
      end
      object cmbOrigen: TcxComboBox
        Left = 208
        Top = 39
        Width = 500
        Height = 27
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = ElegirOrigen
      end
      object lblCampos: TcxLabel
        Left = 12
        Top = 85
        Width = 390
        Height = 21
        Caption = 'Campos de la lista y de la ficha'
      end
      object btnMarcarTodo: TcxButton
        Left = 408
        Top = 78
        Width = 142
        Height = 30
        Caption = 'Marcar todo'
        OnClick = MarcarCampos
      end
      object btnRotulos: TcxButton
        Left = 250
        Top = 78
        Width = 150
        Height = 30
        Caption = 'Editar rótulo...'
        OnClick = EditarRotulos
      end
      object btnDesmarcarTodo: TcxButton
        Left = 558
        Top = 78
        Width = 150
        Height = 30
        Caption = 'Desmarcar todo'
        OnClick = MarcarCampos
      end
      object lstCampos: TcxCheckListBox
        EditValueFormat = cvfStatesString
        Left = 12
        Top = 113
        Width = 538
        Height = 210
      end
      object btnSubir: TcxButton
        Left = 558
        Top = 113
        Width = 150
        Height = 30
        Caption = 'Subir'
        OnClick = MoverCampo
      end
      object btnBajar: TcxButton
        Left = 558
        Top = 151
        Width = 150
        Height = 30
        Caption = 'Bajar'
        OnClick = MoverCampo
      end
      object btnAncho: TcxButton
        Left = 558
        Top = 189
        Width = 150
        Height = 30
        Caption = 'Ancho...'
        OnClick = EditarAncho
      end
    end
    object tsUnidades: TcxTabSheet
      Caption = 'Elemento y unidades TMS'
      object lblClaseTMS: TcxLabel
        Left = 16
        Top = 15
        Caption = 'Tipo de elemento'
      end
      object cmbClase: TcxComboBox
        Left = 16
        Top = 40
        Width = 308
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = CambiarClase
      end
      object lblMotor: TcxLabel
        Left = 342
        Top = 15
        Caption = 'Motor de impresión'
      end
      object cmbMotor: TcxComboBox
        Left = 342
        Top = 40
        Width = 234
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          'FastReport'
          'DevExpress')
      end
      object lblEntradaTMS: TcxLabel
        Left = 16
        Top = 85
        Caption = 'Unidad de entrada'
      end
      object cmbEntrada: TcxComboBox
        Left = 16
        Top = 110
        Width = 560
        Properties.DropDownListStyle = lsFixedList
      end
      object lblEventoTMS: TcxLabel
        Left = 16
        Top = 155
        Caption = 'Unidad antes de guardar (opcional)'
      end
      object cmbEvento: TcxComboBox
        Left = 16
        Top = 180
        Width = 560
        Properties.DropDownListStyle = lsFixedList
      end
      object lblSelectorTMS: TcxLabel
        Left = 16
        Top = 225
        Caption = 'Unidad de selectores (opcional)'
      end
      object cmbSelector: TcxComboBox
        Left = 16
        Top = 250
        Width = 560
        Properties.DropDownListStyle = lsFixedList
      end
    end
    object tsPublicar: TcxTabSheet
      Caption = 'Publicación'
      object chkMenu: TcxCheckBox
        Left = 14
        Top = 20
        Width = 490
        Height = 27
        Caption = 'Crear una opción en el menú Consultoría'
      end
      object lblDestino: TcxLabel
        Left = 16
        Top = 78
        Width = 690
        Height = 21
        Caption = 'Añadir como pestaña del mantenimiento'
      end
      object cmbDestino: TcxComboBox
        Left = 16
        Top = 108
        Width = 440
        Height = 27
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = ElegirDestino
      end
      object lblMaestro: TcxLabel
        Left = 16
        Top = 154
        Width = 690
        Height = 21
        Caption = 'Clave principal'
      end
      object lblEnlace: TcxLabel
        Left = 16
        Top = 202
        Width = 690
        Height = 21
        Caption = 'Campo del origen que coincide con la clave principal'
      end
      object cmbEnlace: TcxComboBox
        Left = 16
        Top = 232
        Width = 440
        Height = 27
        Properties.DropDownListStyle = lsFixedList
      end
    end
  end
  object btnPublicar: TcxButton
    Left = 485
    Top = 483
    Width = 150
    Height = 34
    Caption = 'Aceptar'
    OnClick = Publicar
  end
  object btnCerrar: TcxButton
    Left = 645
    Top = 483
    Width = 117
    Height = 34
    Caption = 'Cancelar'
    Cancel = True
    ModalResult = 2
  end
end

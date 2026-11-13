inherited frmModalCargarSesionTarifa: TfrmModalCargarSesionTarifa
  Caption = 'Cargar articulos en sesion de tarifas'
  TextHeight = 19
  inherited pnlCabeceraComun: TPanel
    inherited chkSoloActivos: TcxCheckBox
      AutoSize = False
      Width = 180
    end
    inherited chkExcluirYaCargados: TcxCheckBox
      AutoSize = False
      Width = 340
    end
    inherited chkSoloConStock: TcxCheckBox
      Left = 550
      AutoSize = False
      Width = 210
    end
    inherited lblStockAviso: TcxLabel
      Left = 770
    end
  end
end

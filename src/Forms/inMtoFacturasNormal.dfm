inherited frmMtoFacturasNormal: TfrmMtoFacturasNormal
  Caption = 'Borradores (Venta Mayor)'
  TextHeight = 18
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsFicha: TcxTabSheet
        inherited pnlVerifactu: TPanel
          inherited pcDetail: TcxPageControl
            inherited tsTotales: TcxTabSheet
              inherited scrTotales: TcxScrollBox
                inherited lblVentaDtoComercial: TcxLabel
                  AnchorX = 222
                  AnchorY = 206
                end
                inherited lblVentaDtoFinanciero: TcxLabel
                  AnchorX = 222
                  AnchorY = 238
                end
                inherited lblTotalaPagar: TcxLabel
                  AnchorX = 222
                  AnchorY = 158
                end
                inherited lblTotalRetencionFactura: TcxLabel
                  AnchorX = 222
                  AnchorY = 126
                end
                inherited lblPorcRetencionFactura: TcxLabel
                  AnchorX = 222
                  AnchorY = 94
                end
                inherited lblTotalBaseImponible: TcxLabel
                  AnchorX = 222
                  AnchorY = 30
                end
                inherited lbl1TotalImpuestos: TcxLabel
                  AnchorX = 222
                  AnchorY = 62
                end
                inherited lblFormadePago: TcxLabel
                  AnchorX = 222
                  AnchorY = 282
                end
                inherited lblTotalesTotalPrendas: TcxLabel
                  AnchorX = 222
                  AnchorY = 364
                end
                inherited grpDesgloseImpuestos: TcxGroupBox
                  inherited lblTotRE: TcxLabel
                    AnchorX = 480
                    AnchorY = 52
                  end
                  inherited PorRE: TcxLabel
                    AnchorX = 415
                    AnchorY = 52
                  end
                  inherited lblTotIVA: TcxLabel
                    AnchorX = 339
                    AnchorY = 52
                  end
                  inherited lblPorIVA: TcxLabel
                    AnchorX = 266
                    AnchorY = 52
                  end
                  inherited lblBaseNeta: TcxLabel
                    AnchorX = 191
                    AnchorY = 52
                  end
                  inherited lblNormal: TcxLabel
                    AnchorY = 92
                  end
                  inherited lblReducido: TcxLabel
                    AnchorY = 140
                  end
                  inherited lblSReducido: TcxLabel
                    AnchorY = 188
                  end
                  inherited lblExento: TcxLabel
                    AnchorY = 236
                  end
                end
              end
            end
            inherited tsVerifactu: TcxTabSheet
              inherited scrlbxVerifactu: TcxScrollBox
                VertScrollBar.Position = 0
                inherited lblPETICION_COMPLETA: TcxLabel
                  Top = 612
                end
                inherited lblRESPUESTA_COMPLETA: TcxLabel
                  Top = 60
                end
                inherited lblQRCODE_BASE64: TcxLabel
                  Top = 543
                end
                inherited lblVERIFACTU_URL: TcxLabel
                  Top = 476
                end
                inherited lblCHAIN_HASH: TcxLabel
                  Top = 410
                end
                inherited lblCHAIN_NUMBER: TcxLabel
                  Top = 361
                end
                inherited lblISSUED_TIME: TcxLabel
                  Top = 313
                end
                inherited lblISSUER_IRS_ID: TcxLabel
                  Top = 264
                end
                inherited lblQUEUE_ID: TcxLabel
                  Top = 216
                end
                inherited lblREQUEST_ID: TcxLabel
                  Top = 167
                end
                inherited lbl: TcxLabel
                  Top = 20
                end
                inherited lblFECHA_PROCESAMIENTO: TcxLabel
                  Top = 224
                end
                inherited lblESTADO: TcxLabel
                  Top = 20
                end
                inherited spQUEUE_ID: TcxDBSpinEdit
                  Top = 208
                end
                inherited cxdbmRESPUESTA_COMPLETA: TcxDBMemo
                  Top = 56
                end
                inherited cxdbmQRCODE_BASE64: TcxDBMemo
                  Top = 517
                end
                inherited cxdbmVERIFACTU_URL: TcxDBMemo
                  Top = 450
                end
                inherited txtCHAIN_HASH: TcxDBTextEdit
                  Top = 402
                end
                inherited txtCHAIN_NUMBER: TcxDBTextEdit
                  Top = 353
                end
                inherited dteISSUED_TIME: TcxDBDateEdit
                  Top = 305
                end
                inherited txtISSUER_IRS_ID: TcxDBTextEdit
                  Top = 256
                end
                inherited imgQRCODE_PNG: TcxDBImage
                  Top = 17
                end
                inherited txtREQUEST_ID: TcxDBTextEdit
                  Top = 159
                end
                inherited spID_CONSOLIDACION: TcxDBSpinEdit
                  Top = 14
                end
                inherited cxdbmPETICION_COMPLETA_FACCON: TcxDBMemo
                  Top = 587
                end
                inherited dteFECHA_PROCESAMIENTO: TcxDBDateEdit
                  Top = 216
                end
                inherited txtESTADO: TcxDBTextEdit
                  Top = 14
                end
                inherited btnVerifactuAnular: TcxButton
                  Top = 79
                end
                inherited btnVerifactuFacturar: TcxButton
                  Top = 119
                end
                inherited btnVolverBorrador: TcxButton
                  Top = 38
                end
              end
            end
          end
        end
        inherited pnlTopFicha: TPanel
          inherited pnlBodyFicha: TPanel
            inherited pcCab: TcxPageControl
              inherited tsCabecera: TcxTabSheet
                inherited lblNroFactura: TcxLabel
                  AnchorX = 147
                  AnchorY = 24
                end
                inherited lblFechaFactura: TcxLabel
                  AnchorX = 147
                  AnchorY = 208
                end
                inherited lblSerieFactura: TcxLabel
                  AnchorX = 147
                  AnchorY = 162
                end
                inherited lblCodigoCliente: TcxLabel
                  AnchorX = 147
                  AnchorY = 117
                end
                inherited lblCodigoEmpresa: TcxLabel
                  AnchorX = 147
                  AnchorY = 70
                end
                inherited lblTipoFactura: TcxLabel
                  AnchorX = 487
                  AnchorY = 162
                end
                inherited lblVendedorFactura: TcxLabel
                  AnchorX = 487
                  AnchorY = 24
                end
                inherited txtCODIGO_CAJERO_FAC: TcxDBTextEdit
                  Visible = False
                end
                inherited lblFaseFactura: TcxLabel
                  AnchorX = 487
                  AnchorY = 208
                end
                inherited lblAlmacenFactura: TcxLabel
                  AnchorX = 782
                  AnchorY = 70
                end
                object cbbVendedorFactura: TcxDBLookupComboBox
                  Left = 495
                  Top = 12
                  DataBinding.DataField = 'CODIGO_CAJERO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ClearKey = 46
                  Properties.DropDownListStyle = lsFixedList
                  Properties.KeyFieldNames = 'CODIGO_EMPL'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      Width = 80
                      FieldName = 'CODIGO_EMPL'
                    end
                    item
                      Caption = 'Vendedor'
                      Width = 220
                      FieldName = 'NOMBRE_VENDEDOR'
                    end>
                  Properties.ListFieldIndex = 1
                  TabOrder = 23
                  Width = 80
                end
              end
              object tsParametrosEDoc: TcxTabSheet
                Caption = 'Par'#225'metros eDoc -'
                ImageIndex = 3
                object cxgrpbxParametrosEDoc: TcxGroupBox
                  AlignWithMargins = True
                  Left = 21
                  Top = 0
                  TabStop = True
                  Caption = 'Par'#225'metros eDoc'
                  TabOrder = 0
                  Height = 174
                  Width = 890
                  object lblCodigoOficinaContable: TcxLabel
                    Left = 36
                    Top = 32
                    Caption = 'Oficina contable'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 0
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_OFICINA_CONTABLE_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 28
                    DataBinding.DataField = 'CODIGO_OFICINA_CONTABLE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 160
                  end
                  object lblCodigoOrganoGestor: TcxLabel
                    Left = 51
                    Top = 72
                    Caption = 'Organo gestor'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 2
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_ORGANO_GESTOR_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 68
                    DataBinding.DataField = 'CODIGO_ORGANO_GESTOR_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 160
                  end
                  object lblCodigoUnidadTramitadora: TcxLabel
                    Left = 10
                    Top = 112
                    Caption = 'Unidad tramitadora'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 4
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_UNIDAD_TRAMITADORA_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 108
                    DataBinding.DataField = 'CODIGO_UNIDAD_TRAMITADORA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 160
                  end
                  object lblNombrePersonaCliente: TcxLabel
                    Left = 369
                    Top = 32
                    Caption = 'Nombre persona f'#237'sica'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 6
                    Transparent = True
                    AnchorX = 543
                  end
                  object txtNOMBRE_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 550
                    Top = 28
                    DataBinding.DataField = 'NOMBRE_PERSONA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Width = 250
                  end
                  object lblApellidosPersonaCliente: TcxLabel
                    Left = 360
                    Top = 72
                    Caption = 'Apellidos persona f'#237'sica'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 8
                    Transparent = True
                    AnchorX = 543
                  end
                  object txtAPELLIDOS_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 550
                    Top = 68
                    DataBinding.DataField = 'APELLIDOS_PERSONA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 9
                    Width = 250
                  end
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel


        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel


      end
    end
  end
  inherited pButtonRightBar: TPanel
    inherited pButtonBDStat: TPanel
      inherited imgIconoPantalla: TcxImage
        Style.Font.Height = -7
        Style.IsFontAssigned = True
      end
      inherited pnStateDataSet: TPanel

      end
      inherited pnlDataSetName: TPanel

      end
    end
    object btnEmitirEDoc: TcxButton
      Left = 1
      Top = 397
      Width = 140
      Height = 34
      Caption = 'Emitir eDoc'
      TabOrder = 6
      OnClick = btnEmitirEDocClick
    end
  end
end

{ Vistas guardadas del historial de llamadas. }
unit inMtoVistaLlamadas;

interface

uses
  System.Classes, Vcl.Controls, Vcl.ExtCtrls, inMtoFrmBase,
  cxGrid, cxGridDBTableView, cxDropDownEdit, cxCheckListBox,
  cxLabel, cxTextEdit, cxButtons, UniDataLlamadasCliente;

type
  TCargarListadoLlamadas = procedure(ASoloSeguimiento: Boolean) of object;

  TfrmVistaLlamadas = class(TfrmBase)
    lblCampos: TcxLabel;
    lstCampos: TcxCheckListBox;
    lblFiltro: TcxLabel;
    cmbFiltro: TcxComboBox;
    lblNombre: TcxLabel;
    edtNombre: TcxTextEdit;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
  end;

  TPanelVistasLlamadas = class(TPanel)
  private
    FVista: TcxGridDBTableView;
    FRepositorio: TRepositorioLlamadas;
    FCargar: TCargarListadoLlamadas;
    FSelector: TcxComboBox;
    FCamposBase: TStringList;
    FIndice: Integer;
    FSeguimiento: Boolean;
    procedure Personalizar(Sender: TObject);
    procedure CambiarVista(Sender: TObject);
    procedure AplicarCampos(ACampos: TStrings);
  public
    class procedure Instalar(ARejilla: TcxGrid;
      ARepositorio: TRepositorioLlamadas; ACargar: TCargarListadoLlamadas);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.UITypes, Vcl.Forms, Vcl.Dialogs,
  cxEdit, inLibMsgScripter, inLibMensajesVcl;

{$R *.dfm}

class procedure TPanelVistasLlamadas.Instalar(ARejilla: TcxGrid;
  ARepositorio: TRepositorioLlamadas; ACargar: TCargarListadoLlamadas);
var
  oPanel: TPanelVistasLlamadas;
  oBoton: TcxButton;
  oEtiqueta: TcxLabel;
  i: Integer;
begin
  oPanel := TPanelVistasLlamadas.Create(ARejilla);
  try
    oPanel.Name := 'VistasHistorial';
    oPanel.FVista := ARejilla.Levels[0].GridView as TcxGridDBTableView;
    oPanel.FRepositorio := ARepositorio;
    oPanel.FCargar := ACargar;
    oPanel.FCamposBase := TStringList.Create;
    for i := 0 to oPanel.FVista.ColumnCount - 1 do
      if oPanel.FVista.Columns[i].Visible then
        oPanel.FCamposBase.Add(oPanel.FVista.Columns[i].DataBinding.FieldName);
    oPanel.Parent := ARejilla.Parent;
    oPanel.BevelOuter := bvNone;
    oPanel.ShowCaption := False;
    oPanel.Top := ARejilla.Top;
    oPanel.Align := alTop;
    oPanel.Height := oPanel.ScaleValue(38);

    oEtiqueta := TcxLabel.Create(oPanel);
    oEtiqueta.Parent := oPanel;
    oEtiqueta.Caption := SVistaHistorial;
    oEtiqueta.Left := oPanel.ScaleValue(8);
    oEtiqueta.Top := oPanel.ScaleValue(9);
    oPanel.FSelector := TcxComboBox.Create(oPanel);
    oPanel.FSelector.Parent := oPanel;
    oPanel.FSelector.SetBounds(oEtiqueta.Left + oEtiqueta.Width +
      oPanel.ScaleValue(8), oPanel.ScaleValue(6), oPanel.ScaleValue(225),
      oPanel.ScaleValue(26));
    oPanel.FSelector.Properties.DropDownListStyle := lsFixedList;
    oPanel.FSelector.Properties.Items.Add(SHistorialOriginal);
    ARepositorio.ListarVistas(oPanel.FSelector.Properties.Items);
    oPanel.FSelector.ItemIndex := 0;
    oPanel.FSelector.Properties.OnChange := oPanel.CambiarVista;

    if ARepositorio.Permitido(PermisoEditarProyecto) then
    begin
      oBoton := TcxButton.Create(oPanel);
      oBoton.Parent := oPanel;
      oBoton.Caption := SPersonalizarVista;
      oBoton.SetBounds(oPanel.FSelector.Left + oPanel.FSelector.Width +
        oPanel.ScaleValue(8), oPanel.ScaleValue(4), oPanel.ScaleValue(125),
        oPanel.ScaleValue(30));
      oBoton.OnClick := oPanel.Personalizar;
    end;
  except
    oPanel.Free;
    raise;
  end;
end;

destructor TPanelVistasLlamadas.Destroy;
begin
  FCamposBase.Free;
  inherited;
end;

procedure TPanelVistasLlamadas.AplicarCampos(ACampos: TStrings);
var
  i: Integer;
begin
  FVista.BeginUpdate;
  try
    for i := 0 to FVista.ColumnCount - 1 do
      FVista.Columns[i].Visible :=
        ACampos.IndexOf(FVista.Columns[i].DataBinding.FieldName) >= 0;
  finally
    FVista.EndUpdate;
  end;
end;

procedure TPanelVistasLlamadas.CambiarVista(Sender: TObject);
var
  iVersion, iNuevo, i: Integer;
  sTexto: string;
  oValor: TJSONValue;
  oCampos: TStringList;
  bSeguimiento: Boolean;
begin
  iNuevo := FSelector.ItemIndex;
  if (iNuevo >= 0) and (iNuevo <> FIndice) then
  begin
    oCampos := TStringList.Create;
    try
      try
        bSeguimiento := False;
        if iNuevo = 0 then
          oCampos.Assign(FCamposBase)
        else
        begin
          sTexto := FRepositorio.LeerProyecto(iVersion, PrefijoVista +
            FSelector.Properties.Items[iNuevo]);
          oValor := TJSONObject.ParseJSONValue(sTexto);
          try
            if not (oValor is TJSONObject) then
              raise EConvertError.Create(SVistaIlegible);
            oCampos.CommaText := oValor.GetValue<string>('campos');
            bSeguimiento := oValor.GetValue<Boolean>('seguimiento');
            for i := oCampos.Count - 1 downto 0 do
              if FVista.GetColumnByFieldName(oCampos[i]) = nil then
                oCampos.Delete(i);
            if oCampos.Count = 0 then
              raise EConvertError.Create(SVistaIlegible);
          finally
            oValor.Free;
          end;
        end;
        FCargar(bSeguimiento);
        AplicarCampos(oCampos);
        FSeguimiento := bSeguimiento;
        FIndice := iNuevo;
      except
        FSelector.ItemIndex := FIndice;
        raise;
      end;
    finally
      oCampos.Free;
    end;
  end;
end;

procedure TPanelVistasLlamadas.Personalizar(Sender: TObject);
var
  oDialogo: TfrmVistaLlamadas;
  oCampos: TStringList;
  oContenido: TJSONObject;
  sNombre: string;
  i: Integer;
  bListo: Boolean;
begin
  FRepositorio.ExigirEditor;
  oDialogo := TfrmVistaLlamadas.Create(GetParentForm(Self));
  try
    oDialogo.Caption := SPersonalizarVista;
    oDialogo.lblCampos.Caption := SCamposVisibles;
    oDialogo.lblFiltro.Caption := SFiltroVista;
    oDialogo.cmbFiltro.Properties.Items.Add(STodasLlamadas);
    oDialogo.cmbFiltro.Properties.Items.Add(SConSeguimiento);
    oDialogo.cmbFiltro.ItemIndex := Ord(FSeguimiento);
    oDialogo.lblNombre.Caption := SNombreVista;
    oDialogo.edtNombre.Text := SProximasLlamadas;
    oDialogo.edtNombre.Properties.MaxLength := LongitudNombreVista;
    oDialogo.btnGuardar.Caption := SGuardarComo;
    oDialogo.btnCancelar.Caption := SCancelarOpciones;
    for i := 0 to FVista.ColumnCount - 1 do
    begin
      oDialogo.lstCampos.Items.Add.Text := FVista.Columns[i].Caption;
      oDialogo.lstCampos.Items[i].Checked := FVista.Columns[i].Visible;
    end;
    oCampos := TStringList.Create;
    try
      bListo := False;
      while not bListo and (oDialogo.ShowModal = mrOk) do
      begin
        oCampos.Clear;
        for i := 0 to FVista.ColumnCount - 1 do
          if oDialogo.lstCampos.Items[i].Checked then
            oCampos.Add(FVista.Columns[i].DataBinding.FieldName);
        sNombre := Trim(oDialogo.edtNombre.Text);
        if oCampos.Count = 0 then
          ShowMessage_fza(SMarqueCampo)
        else if sNombre = '' then
          ShowMessage_fza(SNombreVistaInvalido)
        else if FSelector.Properties.Items.IndexOf(sNombre) >= 0 then
          ShowMessage_fza(SVistaYaExiste)
        else
        begin
          oContenido := TJSONObject.Create;
          try
            oContenido.AddPair('campos', oCampos.CommaText);
            oContenido.AddPair('seguimiento', oDialogo.cmbFiltro.ItemIndex = 1);
            bListo := FRepositorio.CrearVista(sNombre, oContenido.ToJSON);
          finally
            oContenido.Free;
          end;
          if bListo then
            FSelector.ItemIndex := FSelector.Properties.Items.Add(sNombre)
          else
            ShowMessage_fza(SVistaYaExiste);
        end;
      end;
    finally
      oCampos.Free;
    end;
  finally
    oDialogo.Free;
  end;
end;

end.

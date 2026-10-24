{******************************************************************************}
{  fMovilVenta: borrador de venta para capturar desde Ventas del TPV.          }
{  FZ-ISSUE-353. Copyright (c) Alejandro Laorden Hidalgo.                      }
{******************************************************************************}
unit fMovilVenta;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  FMX.Forms, FMX.StdCtrls, FMX.Types, FMX.Edit, FMX.ListBox,
  SesionClienteMovil, TraduccionMovil;

type
  TfrmMovilVenta = class(TForm)
  private
    FSesion: TSesionClienteMovil;
    FVida: ISesionClienteMovil;
    FRuta: string;
    FOperario: string;
    FDispositivo: string;
    FEnvio: string;
    FLineas: TJSONArray;
    FCodigo: TEdit;
    FCantidad: TEdit;
    FDestino: TEdit;
    FLista: TListBox;
    FEstado: TLabel;
    procedure Anadir(Sender: TObject);
    procedure Quitar(Sender: TObject);
    procedure Enviar(Sender: TObject);
    procedure Volver(Sender: TObject);
    procedure Actualizar;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Configurar(ASesion: TSesionClienteMovil;
      const ARuta, AOperario, ADispositivo: string);
    procedure ProponerCodigo(const ACodigo: string);
  end;

implementation

uses
  System.IOUtils, System.Net.HttpClient, FMX.Controls,
  FMX.Controls.Presentation, FMX.DialogService;

constructor TfrmMovilVenta.Create(AOwner: TComponent);
  function Boton(const ATexto: string; AAccion: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := Self;
    Result.Align := TAlignLayout.Bottom;
    Result.Height := 44;
    Result.Text := ATexto;
    Result.OnClick := AAccion;
  end;
begin
  inherited CreateNew(AOwner);
  Caption := Tr('Venta para TPV');
  FLineas := TJSONArray.Create;
  FEstado := TLabel.Create(Self);
  FEstado.Parent := Self;
  FEstado.Align := TAlignLayout.Top;
  FEstado.Height := 60;
  FEstado.WordWrap := True;
  FEstado.Text :=
    Tr('Añade códigos de unidad o códigos de barras y cantidades.');
  FCodigo := TEdit.Create(Self);
  FCodigo.Parent := Self;
  FCodigo.Align := TAlignLayout.Top;
  FCodigo.TextPrompt := Tr('Código de barras o SKU');
  FCantidad := TEdit.Create(Self);
  FCantidad.Parent := Self;
  FCantidad.Align := TAlignLayout.Top;
  FCantidad.Text := '1';
  FDestino := TEdit.Create(Self);
  FDestino.Parent := Self;
  FDestino.Align := TAlignLayout.Top;
  FDestino.TextPrompt :=
    Tr('Referencia para el cajero (cliente, mesa...)');
  Boton(Tr('Volver'), Volver);
  Boton(Tr('Enviar venta a TPV / reintentar'), Enviar);
  Boton(Tr('Quitar línea seleccionada'), Quitar);
  Boton(Tr('Añadir artículo'), Anadir);
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
end;

destructor TfrmMovilVenta.Destroy;
begin
  FLineas.Free;
  inherited;
end;

procedure TfrmMovilVenta.Configurar(ASesion: TSesionClienteMovil;
  const ARuta, AOperario, ADispositivo: string);
begin
  FSesion := ASesion;
  FVida := ASesion;
  FRuta := ARuta;
  FOperario := AOperario;
  FDispositivo := ADispositivo;
  if TFile.Exists(FRuta) then
  begin
    FEnvio := TFile.ReadAllText(FRuta, TEncoding.UTF8);
    FEstado.Text := Tr('Venta pendiente de envío. Pulsa reintentar.');
  end;
end;

procedure TfrmMovilVenta.ProponerCodigo(const ACodigo: string);
begin
  FCodigo.Text := ACodigo;
end;

procedure TfrmMovilVenta.Anadir(Sender: TObject);
var
  nCantidad: Double;
  sCantidad: string;
  oLinea: TJSONObject;
begin
  sCantidad := StringReplace(Trim(FCantidad.Text), ',', '.', []);
  if FEnvio <> '' then
    TDialogService.ShowMessage(Tr('Reintenta primero la venta pendiente.'))
  else if (Trim(FCodigo.Text) <> '') and
    TryStrToFloat(sCantidad, nCantidad, TFormatSettings.Invariant) and
    (nCantidad > 0) and (nCantidad < 100000) and (FLineas.Count < 200) then
  begin
    oLinea := TJSONObject.Create;
    oLinea.AddPair('codigo', Trim(FCodigo.Text));
    oLinea.AddPair('cantidad',
      FormatFloat('0.###', nCantidad, TFormatSettings.Invariant));
    FLineas.AddElement(oLinea);
    Actualizar;
  end
  else
    TDialogService.ShowMessage(Tr('Revisa el código y la cantidad.'));
end;

procedure TfrmMovilVenta.Quitar(Sender: TObject);
begin
  if (FEnvio = '') and (FLista.ItemIndex >= 0) then
  begin
    FLineas.Remove(FLista.ItemIndex).Free;
    Actualizar;
  end;
end;

procedure TfrmMovilVenta.Actualizar;
var
  oLinea: TJSONValue;
begin
  FLista.Clear;
  for oLinea in FLineas do
    FLista.Items.Add(oLinea.GetValue<string>('codigo') + ' x ' +
      oLinea.GetValue<string>('cantidad'));
end;

procedure TfrmMovilVenta.Enviar(Sender: TObject);
var
  oVenta: TJSONObject;
  oHttp: THTTPClient;
  oCuerpo: TStringStream;
  oRespuesta: IHTTPResponse;
  oId: TGUID;
begin
  if not FSesion.Permite('tpv:enviar') then
    raise Exception.Create(
      Tr('Esta clave no permite enviar ventas al TPV.'));
  try
    if (FEnvio = '') and (FLineas.Count > 0) then
    begin
      CreateGUID(oId);
      oVenta := TJSONObject.Create;
      try
        oVenta.AddPair('id', LowerCase(Copy(GUIDToString(oId), 2, 36)));
        oVenta.AddPair('operario', FOperario);
        oVenta.AddPair('dispositivo', FDispositivo);
        oVenta.AddPair('destino', FDestino.Text);
        oVenta.AddPair('lineas', FLineas.Clone as TJSONArray);
        FEnvio := oVenta.ToJSON;
        TFile.WriteAllText(FRuta, FEnvio, TEncoding.UTF8);
      finally
        oVenta.Free;
      end;
    end;
    if FEnvio <> '' then
    begin
      oHttp := FSesion.CrearHttp;
      oCuerpo := TStringStream.Create(FEnvio, TEncoding.UTF8);
      try
        oHttp.ContentType := 'application/json';
        oRespuesta := oHttp.Post(FSesion.Url + 'ventas_app.php', oCuerpo);
        FSesion.RecibirEstado(oRespuesta.StatusCode);
        if oRespuesta.StatusCode <> 200 then
          raise Exception.Create(TrF('Envío pendiente (HTTP %d).',
            [oRespuesta.StatusCode]));
        TFile.Delete(FRuta);
        FEnvio := '';
        FreeAndNil(FLineas);
        FLineas := TJSONArray.Create;
        Actualizar;
        FEstado.Text := Tr('Enviada. Captúrala en Ventas del TPV.');
      finally
        oCuerpo.Free;
        oHttp.Free;
      end;
    end;
  except
    on E: Exception do
      FEstado.Text := TrF('Pendiente de envío: %s', [E.Message]);
  end;
end;

procedure TfrmMovilVenta.Volver(Sender: TObject);
begin
  Close;
end;

end.

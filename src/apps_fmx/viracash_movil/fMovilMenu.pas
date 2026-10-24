{******************************************************************************}
{  fMovilMenu: entrada única a Fotos, Ventas, Stock, Recuento y venta TPV.    }
{  FZ-ISSUE-353 y FZ-ISSUE-352. Copyright (c) Alejandro Laorden Hidalgo.      }
{******************************************************************************}
unit fMovilMenu;

interface

uses
  System.Classes, System.SysUtils, System.UITypes,
  FMX.Forms, FMX.Types, FMX.StdCtrls,
  FMX.Edit, FMX.Layouts, FMX.Controls, FMX.ScrollBox,
  SesionClienteMovil, MovilConfig, fMovilVenta, TraduccionMovil;

type
  TfrmMovilMenu = class(TForm)
  private
    FFormularios: array[1..4] of TForm;
    FVenta: TfrmMovilVenta;
    FStockPreparado: Boolean;
    FNumeroCampos: Integer;
    FConfig: TMovilConfig;
    FSesion: TSesionClienteMovil;
    FVidaSesion: ISesionClienteMovil;
    FEstado: TLabel;
    FUrl: TEdit;
    FToken: TEdit;
    FOperario: TEdit;
    FDispositivo: TEdit;
    FStock: TEdit;
    FConfiguracion: TVertScrollBox;
    FMenu: TLayout;
    FTimer: TTimer;
    FRevocacionMostrada: Boolean;
    function Campo(const ATexto, AValor: string): TEdit;
    function PermiteModulo(AIndice: Integer): Boolean;
    procedure BotonModulo(const ATexto, AAmbito: string; AIndice: Integer);
    procedure Conectar(Sender: TObject);
    procedure Configurar(Sender: TObject);
    procedure AbrirModulo(Sender: TObject);
    procedure Volver(Sender: TObject);
    procedure VigilarSesion(Sender: TObject);
    procedure CerrarModulo(Sender: TObject; var Action: TCloseAction);
    procedure MostrarMenu;
    procedure PrepararStock(Sender: TObject);
    procedure PrepararVenta;
    procedure VentaDesdeStock(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils, FMX.DialogService,
  RecuentoConfig, RecuentoLocal, fRecuentoMenu,
  VentasConfig, fVentasListado, UPrincipal,
  frmLogin, frmStock, uSettings, TextosMovil;

constructor TfrmMovilMenu.Create(AOwner: TComponent);
var
  oBoton: TButton;
begin
  inherited CreateNew(AOwner);
  Caption := Tr('ViraCash móvil');
  Width := 420;
  Height := 720;
  FConfig := TMovilConfig.Create;
  FEstado := TLabel.Create(Self);
  FEstado.Parent := Self;
  FEstado.Align := TAlignLayout.Top;
  FEstado.Height := 70;
  FEstado.WordWrap := True;
  FEstado.Margins.Left := 16;
  FEstado.Margins.Right := 16;
  FEstado.Text := Tr('Configura tu clave de persona o dispositivo.');
  FMenu := TLayout.Create(Self);
  FMenu.Parent := Self;
  FMenu.Align := TAlignLayout.Client;
  FMenu.Visible := False;
  FConfiguracion := TVertScrollBox.Create(Self);
  FConfiguracion.Parent := Self;
  FConfiguracion.Align := TAlignLayout.Client;
  FUrl := Campo(Tr('URL API'), FConfig.Url);
  FToken := Campo(Tr('Clave API'), FConfig.Token);
  FToken.Password := True;
  FOperario := Campo(Tr('Operario'), FConfig.Operario);
  FDispositivo := Campo(Tr('Dispositivo'), FConfig.Dispositivo);
  FDispositivo.TextPrompt := Tr('Ejemplo: MOVIL-ANA o TIENDA-01');
  FStock := Campo(Tr('URL interna de Stock (opcional)'), FConfig.UrlStock);
  oBoton := TButton.Create(Self);
  oBoton.Parent := FConfiguracion;
  oBoton.Position.Y := 100000;
  oBoton.Align := TAlignLayout.Top;
  oBoton.Height := 48;
  oBoton.Margins.Left := 16;
  oBoton.Margins.Right := 16;
  oBoton.Margins.Top := 12;
  oBoton.Margins.Bottom := 16;
  oBoton.Text := Tr('Guardar y probar conexión');
  oBoton.OnClick := Conectar;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 500;
  FTimer.OnTimer := VigilarSesion;
end;

destructor TfrmMovilMenu.Destroy;
begin
  FTimer.Enabled := False;
  FConfig.Free;
  inherited;
end;

function TfrmMovilMenu.Campo(const ATexto, AValor: string): TEdit;
var
  oGrupo: TLayout;
  oEtiqueta: TLabel;
begin
  oGrupo := TLayout.Create(Self);
  oGrupo.Parent := FConfiguracion;
  oGrupo.Position.Y := FNumeroCampos * 84;
  oGrupo.Height := 84;
  oGrupo.Margins.Left := 16;
  oGrupo.Margins.Right := 16;
  oGrupo.Align := TAlignLayout.Top;
  Inc(FNumeroCampos);
  oEtiqueta := TLabel.Create(Self);
  oEtiqueta.Parent := oGrupo;
  oEtiqueta.Align := TAlignLayout.Top;
  oEtiqueta.Height := 28;
  oEtiqueta.Text := ATexto;
  Result := TEdit.Create(Self);
  Result.Parent := oGrupo;
  Result.Align := TAlignLayout.Client;
  Result.Margins.Bottom := 12;
  Result.Text := AValor;
end;

procedure TfrmMovilMenu.Conectar(Sender: TObject);
var
  sMensaje: string;
  sRuta: string;
  oNueva: TMovilConfig;
begin
  try
    if Assigned(FSesion) then
    begin
      oNueva := TMovilConfig.Create;
      try
        oNueva.Url := FUrl.Text;
        oNueva.Token := FToken.Text;
        oNueva.Operario := FOperario.Text;
        oNueva.Dispositivo := FDispositivo.Text;
        oNueva.UrlStock := FStock.Text;
        oNueva.Guardar;
      finally
        oNueva.Free;
      end;
      TDialogService.ShowMessage(
        Tr('Configuración guardada. Cierra y abre la app para aplicarla.'));
    end
    else
    begin
      FConfig.Url := FUrl.Text;
      FConfig.Token := FToken.Text;
      FConfig.Operario := FOperario.Text;
      FConfig.Dispositivo := FDispositivo.Text;
      FConfig.UrlStock := FStock.Text;
      FConfig.Guardar;
      sRuta := FConfig.CarpetaIdentidad;
      FSesion := TSesionClienteMovil.Create(FConfig.Url, FConfig.Token,
        TPath.Combine(sRuta, 'sesion.json'));
      FVidaSesion := FSesion;
      if FSesion.Actualizar(sMensaje) then
      begin
        RecuentoConfig.oConfig.UrlBase := FConfig.Url;
        RecuentoConfig.oConfig.Token := FConfig.Token;
        RecuentoConfig.oConfig.Carpeta := FSesion.Referencia;
        RecuentoConfig.oConfig.Operario := FConfig.Operario;
        RecuentoConfig.oConfig.Dispositivo := FConfig.Dispositivo;
        RecuentoConfig.oConfig.CarpetaSesiones := sRuta;
        RecuentoConfig.oConfig.Sesion := FVidaSesion;
        RecuentoConfig.oConfig.ConfiguracionCentral := True;
        FreeAndNil(RecuentoLocal.oLocal);
        if PermiteModulo(4) then
          RecuentoLocal.oLocal := TRecuentoLocal.Create(
            TPath.Combine(sRuta, 'recuento.db'));
        VentasConfig.oConfig.UrlBase := FConfig.Url;
        VentasConfig.oConfig.Token := FConfig.Token;
        VentasConfig.oConfig.Referencia := FSesion.Referencia;
        VentasConfig.oConfig.Sesion := FVidaSesion;
        VentasConfig.oConfig.ConfiguracionCentral := True;
        VentasConfig.oConfig.CarpetaCache :=
          TPath.Combine(sRuta, 'cachefotos');
        MostrarMenu;
      end
      else
      begin
        FSesion := nil;
        FVidaSesion := nil;
      end;
      if Assigned(FSesion) and (FMenu.ChildrenCount = 1) then
        FEstado.Text :=
          Tr('Esta clave no tiene permisos para ninguna función')
      else
        FEstado.Text := sMensaje;
    end;
  except
    on E: Exception do
    begin
      if not FMenu.Visible then
      begin
        FSesion := nil;
        FVidaSesion := nil;
      end;
      FEstado.Text := E.Message;
    end;
  end;
end;

// El recuento escribe lecturas pero empieza leyendo almacenes, plantillas y
// catálogo: sin recuentos:leer el módulo no puede funcionar.
function TfrmMovilMenu.PermiteModulo(AIndice: Integer): Boolean;
const
  cAmbitos: array[1..5] of string = ('fotos:escribir',
    'ventas:leer', 'stock:leer', 'recuentos:escribir', 'tpv:enviar');
begin
  Result := FSesion.Permite(cAmbitos[AIndice]);
  if AIndice = 4 then
    Result := Result and FSesion.Permite('recuentos:leer');
end;

procedure TfrmMovilMenu.BotonModulo(const ATexto, AAmbito: string;
  AIndice: Integer);
var
  oBoton: TButton;
begin
  if (AAmbito = '') or PermiteModulo(AIndice) then
  begin
    oBoton := TButton.Create(FMenu);
    oBoton.Parent := FMenu;
    oBoton.Position.Y := AIndice * 70;
    oBoton.Align := TAlignLayout.Top;
    oBoton.Height := 64;
    oBoton.Text := ATexto;
    oBoton.Tag := AIndice;
    oBoton.OnClick := AbrirModulo;
    if AIndice = 0 then
      oBoton.OnClick := Configurar;
  end;
end;

procedure TfrmMovilMenu.MostrarMenu;
begin
  FConfiguracion.Visible := False;
  FMenu.Visible := True;
  BotonModulo(Tr('Fotos'), 'fotos:escribir', 1);
  BotonModulo(Tr('Ventas del día'), 'ventas:leer', 2);
  BotonModulo(Tr('Stock'), 'stock:leer', 3);
  BotonModulo(Tr('Recuento y traspasos'), 'recuentos:escribir', 4);
  BotonModulo(Tr('Venta para TPV'), 'tpv:enviar', 5);
  if FMenu.ChildrenCount = 0 then
    FEstado.Text :=
      Tr('Esta clave no tiene permisos para ninguna función');
  BotonModulo(Tr('Configuración'), '', 0);
end;

procedure TfrmMovilMenu.Configurar(Sender: TObject);
begin
  FConfiguracion.Visible := True;
  FMenu.Visible := False;
end;

procedure TfrmMovilMenu.CerrarModulo(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := TCloseAction.caHide;
  Show;
end;

procedure TfrmMovilMenu.Volver(Sender: TObject);
begin
  TForm(TButton(Sender).Owner).Close;
end;

procedure TfrmMovilMenu.AbrirModulo(Sender: TObject);
var
  iModulo: Integer;
  oFormulario: TForm;
  oFotos: TfrmPrincipal;
  oBoton: TButton;
begin
  iModulo := TButton(Sender).Tag;
  // FZ-ISSUE-352: la venta para el TPV no depende de Stock; trae su propio
  // botón de volver y se reutiliza cuando se abre desde Stock.
  if (iModulo = 5) and PermiteModulo(iModulo) then
  begin
    PrepararVenta;
    FVenta.Show;
  end
  else if PermiteModulo(iModulo) then
  begin
    oFormulario := FFormularios[iModulo];
    if not Assigned(oFormulario) then
    begin
    case iModulo of
      1:
        begin
          oFotos := TfrmPrincipal.Create(Self);
          oFotos.ConfigurarModulo(FConfig.Url, FConfig.Token,
            FSesion.Referencia,
            TPath.Combine(FConfig.CarpetaIdentidad, 'fotos.json'),
            FVidaSesion);
          oFormulario := oFotos;
        end;
      2: oFormulario := TfrmListado.Create(Self);
      3:
        if Trim(FConfig.UrlStock) = '' then
          TDialogService.ShowMessage(
            Tr('Configura la URL interna de Stock.'))
        else
        begin
          TSettings.GuardarBaseUrl(FConfig.UrlStock);
          if not Assigned(FormLogin) then
            FormLogin := TFormLogin.Create(Self);
          FormLogin.edtUrl.Enabled := False;
          FormLogin.AlAbrirStock := PrepararStock;
          oFormulario := FormLogin;
        end;
      4: oFormulario := TfrmMenu.Create(Self);
    end;
    if Assigned(oFormulario) then
    begin
      oBoton := TButton.Create(oFormulario);
      oBoton.Parent := oFormulario;
      oBoton.Align := TAlignLayout.Bottom;
      oBoton.Height := 44;
      oBoton.Text := Tr('Menú principal');
      oBoton.OnClick := Volver;
      oFormulario.OnClose := CerrarModulo;
      FFormularios[iModulo] := oFormulario;
    end;
    end;
    if Assigned(oFormulario) then
      oFormulario.Show;
  end;
end;

procedure TfrmMovilMenu.PrepararStock(Sender: TObject);
var
  oBoton: TButton;
begin
  if not FStockPreparado then
  begin
    FStockPreparado := True;
    if FSesion.Permite('tpv:enviar') then
    begin
      oBoton := TButton.Create(FormStock);
      oBoton.Parent := FormStock;
      oBoton.Align := TAlignLayout.Bottom;
      oBoton.Height := 44;
      oBoton.Text := Tr('Enviar venta a TPV');
      oBoton.OnClick := VentaDesdeStock;
    end;
  end;
end;

procedure TfrmMovilMenu.PrepararVenta;
begin
  if not Assigned(FVenta) then
  begin
    FVenta := TfrmMovilVenta.Create(Self);
    FVenta.Configurar(FSesion,
      TPath.Combine(FConfig.CarpetaIdentidad, 'venta_tpv.json'),
      FConfig.Operario, FConfig.Dispositivo);
  end;
end;

procedure TfrmMovilMenu.VentaDesdeStock(Sender: TObject);
begin
  if FSesion.Permite('tpv:enviar') then
  begin
    PrepararVenta;
    FVenta.ProponerCodigo(FormStock.edtArticulo.Text);
    FVenta.Show;
  end;
end;

procedure TfrmMovilMenu.VigilarSesion(Sender: TObject);
var
  i, j: Integer;
begin
  if Assigned(FSesion) and FSesion.Revocada and
     not FRevocacionMostrada then
  begin
    FRevocacionMostrada := True;
    for i := 0 to Screen.FormCount - 1 do
      if Screen.Forms[i] <> Self then
      begin
        for j := 0 to Screen.Forms[i].ChildrenCount - 1 do
          if Screen.Forms[i].Children[j] is TControl then
            TControl(Screen.Forms[i].Children[j]).Enabled := False;
        Screen.Forms[i].Hide;
      end;
    FEstado.Text := Tr('Clave revocada. Configura una clave válida.');
    Configurar(nil);
    Show;
  end;
end;

end.

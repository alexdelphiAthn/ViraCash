{******************************************************************************}
{ Pestaña de propiedades de familia de la linea seleccionada en Sesiones.     }
{ Reutiliza los controles de Articulos y guarda borradores sin materializar. }
{******************************************************************************}
unit inMtoComprasSesionesPropiedadesVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Vcl.ExtCtrls,
  cxPC, cxLabel, cxButtons, cxScrollBox,
  inMtoModalArticulosPropiedades,
  inLibArticulosPropiedadesPersistenciaIntf;

type
  TCrearPropiedadesLineaSesion = reference to function(
    const ASerie, ANumero: string; ALinea: Integer):
    TServiciosPropiedadesArticulo;

  TPropiedadesFamiliaSesion = class
  private
    FCabecera, FLineas: TDataSet;
    FCrearServicios: TCrearPropiedadesLineaSesion;
    FUsuario, FClave: string;
    FPagina: TcxTabSheet;
    FAyuda: TcxLabel;
    FScroll: TcxScrollBox;
    FBoton: TcxButton;
    FTemporizador: TTimer;
    FGestor: TGestorPropiedades;
    FActualizando: Boolean;
    procedure AlTemporizador(Sender: TObject);
    procedure AnadirPropiedad(Sender: TObject);
    function Contexto(out ASerie, ANumero: string;
      out ALinea: Integer): string;
  public
    constructor Create(AOwner: TComponent; APaginas: TcxPageControl;
      ACabecera, ALineas: TDataSet; const AUsuario: string;
      const ACrearServicios: TCrearPropiedadesLineaSesion);
    destructor Destroy; override;
    procedure Actualizar;
    procedure GuardarBorrador;
    procedure Abrir;
    property Pagina: TcxTabSheet read FPagina;
  end;

implementation

uses
  Vcl.Controls, inLibMensajesVcl, inLibMsgCompras, inLibMsgArticulos;

constructor TPropiedadesFamiliaSesion.Create(AOwner: TComponent;
  APaginas: TcxPageControl; ACabecera, ALineas: TDataSet;
  const AUsuario: string;
  const ACrearServicios: TCrearPropiedadesLineaSesion);
begin
  inherited Create;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FUsuario := AUsuario;
  FClave := '#';
  FCrearServicios := ACrearServicios;
  FPagina := TcxTabSheet.Create(AOwner);
  FPagina.Name := 'tsPropiedadesFamiliaSesion';
  FPagina.PageControl := APaginas;
  FPagina.Caption := SCaptionPropiedadesFamiliaSesion;
  FAyuda := TcxLabel.Create(FPagina);
  FAyuda.Parent := FPagina;
  FAyuda.Align := alTop;
  FAyuda.Properties.WordWrap := True;
  FAyuda.AutoSize := True;
  FBoton := TcxButton.Create(FPagina);
  FBoton.Parent := FPagina;
  FBoton.Align := alTop;
  FBoton.Height := 32;
  FBoton.Caption := SCaptionAnadirPropiedad;
  FBoton.OnClick := AnadirPropiedad;
  FScroll := TcxScrollBox.Create(FPagina);
  FScroll.Parent := FPagina;
  FScroll.Align := alClient;
  FTemporizador := TTimer.Create(nil);
  FTemporizador.Interval := 400;
  FTemporizador.OnTimer := AlTemporizador;
  Actualizar;
end;

destructor TPropiedadesFamiliaSesion.Destroy;
begin
  FTemporizador.Free;
  FGestor.Free;
  FPagina.Free;
  inherited;
end;

function TPropiedadesFamiliaSesion.Contexto(
  out ASerie, ANumero: string; out ALinea: Integer): string;
begin
  ASerie := '';
  ANumero := '';
  ALinea := 0;
  Result := '';
  if FCabecera.Active and FLineas.Active and
    (not FCabecera.IsEmpty) and (not FLineas.IsEmpty) and
    (FLineas.State = dsBrowse) then
  begin
    ASerie := FCabecera.FieldByName('SERIE_SES').AsString;
    ANumero := FCabecera.FieldByName('NUMERO_SES').AsString;
    ALinea := FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    Result := ASerie + '|' + ANumero + '|' + IntToStr(ALinea) + '|' +
      FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString + '|' +
      FCabecera.FieldByName('CODIGO_FAM_SES').AsString + '|' +
      FLineas.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString + '|' +
      FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString + '|' +
      FCabecera.FieldByName('ESTADO_SES').AsString + '|' +
      FCabecera.FieldByName('ID_PV_TEMPORADA_SES').AsString + '|' +
      FLineas.FieldByName('ACCION_DUPLICADO_SESLIN').AsString;
  end;
end;

procedure TPropiedadesFamiliaSesion.Actualizar;
var
  Serie, Numero, Clave: string;
  Linea: Integer;
  Servicios: TServiciosPropiedadesArticulo;
begin
  if not FActualizando then
  begin
    FActualizando := True;
    try
      Clave := Contexto(Serie, Numero, Linea);
      if Clave <> FClave then
      begin
        GuardarBorrador;
        FreeAndNil(FGestor);
        FClave := Clave;
        FScroll.Enabled := (Clave <> '') and
          (FCabecera.FieldByName('ESTADO_SES').AsString <> 'CERRADA');
        FBoton.Enabled := FScroll.Enabled;
        if Clave = '' then
          FAyuda.Caption := SAyudaPropiedadesSesionSinLinea
        else
        begin
          Servicios := FCrearServicios(Serie, Numero, Linea);
          FGestor := TGestorPropiedades.Create(FScroll, Servicios, FUsuario);
          FGestor.CargarPropiedades(IntToStr(Linea));
          FAyuda.Caption := Format(SAyudaPropiedadesFamiliaSesion,
            [Linea, FLineas.FieldByName('DESCRIPCION_SESLIN').AsString]);
        end;
      end;
    finally
      FActualizando := False;
    end;
  end;
end;

procedure TPropiedadesFamiliaSesion.GuardarBorrador;
begin
  if (FGestor <> nil) and FScroll.Enabled then
    FGestor.GuardarPropiedades(False);
end;

procedure TPropiedadesFamiliaSesion.AlTemporizador(Sender: TObject);
begin
  try
    Actualizar;
    // No se reconstruyen controles mientras se escribe: solo valores cambiados.
    GuardarBorrador;
  except
    on E: Exception do
    begin
      FTemporizador.Enabled := False;
      ShowMessage_fza(Format(SErrorGuardarPropiedadesSesion, [E.Message]));
    end;
  end;
end;

procedure TPropiedadesFamiliaSesion.AnadirPropiedad(Sender: TObject);
begin
  if FGestor <> nil then
    FGestor.AbrirSelectorPropiedades;
end;

procedure TPropiedadesFamiliaSesion.Abrir;
begin
  FPagina.PageControl.ActivePage := FPagina;
  Actualizar;
end;

end.

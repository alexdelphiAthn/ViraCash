{ Operaciones de ViraCash disponibles en los scripts de Llamadas. }
unit inMtoLlamadasAccionesVcl;

interface

uses
  System.Classes, Data.DB, Uni, UniDataLlamadasCliente;

type
  {$M+}
  TAccionesLlamadas = class
  private
    FRepositorio: TRepositorioLlamadas;
    FDatos: TUniQuery;
    FOrigen: TDataSource;
    FId: Int64;
    FVersion: Integer;
    FClienteEdicion: string;
  public
    constructor Create(ARepositorio: TRepositorioLlamadas);
    destructor Destroy; override;
  published
    procedure EnlazarRejilla(ARejilla: TObject);
    procedure EnlazarInforme(ARejilla: TObject; ASoloSeguimiento: Boolean);
    procedure Actualizar;
    function Puede(const AAccion: string): Boolean;
    function Seleccionar: Boolean;
    procedure Nueva;
    function Campo(const ANombre: string): string;
    function ClienteInicial: string;
    function ClienteEditable: Boolean;
    function AyudaSeguimiento: string;
    function IntentarGuardar(const ACliente, AFecha, ATelefono,
      AMotivo, AResultado, ASeguimiento: string): Boolean;
    procedure Guardar(const ACliente, AFecha, ATelefono, AMotivo,
      AResultado, ASeguimiento: string);
    procedure Borrar;
    procedure Imprimir(ARejilla: TObject);
  end;
  {$M-}

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, cxGrid, cxGridLevel,
  cxGridDBTableView, dxPrintUtils, dxPSCore, dxPScxGridLnk, dxPrnDlg, dxPreVw,
  inLibMensajesVcl, inLibMsgScripter;

resourcestring
  SConfirmarBorrar = '¿Borrar la llamada seleccionada?';
  SCliente = 'El cliente de una llamada existente no se puede cambiar.';
  SImpresion = 'Falta el permiso de impresión de llamadas.';

constructor TAccionesLlamadas.Create(ARepositorio: TRepositorioLlamadas);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FOrigen := TDataSource.Create(nil);
end;

destructor TAccionesLlamadas.Destroy;
begin
  FOrigen.Free;
  FDatos.Free;
  inherited;
end;

procedure TAccionesLlamadas.Actualizar;
var
  oAnterior: TUniQuery;
begin
  oAnterior := FDatos;
  FDatos := FRepositorio.AbrirListado;
  try
    FOrigen.DataSet := FDatos;
  finally
    oAnterior.Free;
  end;
end;

procedure MostrarListado(oRejilla: TcxGrid; oOrigen: TDataSource);
var
  oVista: TcxGridDBTableView;
  oNivel: TcxGridLevel;

  procedure Columna(const ACampo, ATitulo: string; AAncho: Integer);
  var
    oColumna: TcxGridDBColumn;
  begin
    oColumna := oVista.CreateColumn;
    oColumna.DataBinding.FieldName := ACampo;
    oColumna.Caption := ATitulo;
    oColumna.Width := AAncho;
  end;

begin
  if oRejilla.Levels.Count = 0 then
    oNivel := oRejilla.Levels.Add
  else
    oNivel := oRejilla.Levels[0];
  if oNivel.GridView = nil then
    oNivel.GridView := oRejilla.CreateView(TcxGridDBTableView);
  oVista := oNivel.GridView as TcxGridDBTableView;
  oVista.DataController.DataSource := oOrigen;
  oVista.OptionsData.Editing := False;
  oVista.OptionsView.GroupByBox := False;
  oVista.OptionsView.CellAutoHeight := True;
  if oVista.ColumnCount = 0 then
  begin
    Columna('FECHA_CLLAM', 'Fecha y hora', 160);
    Columna('RAZON_SOCIAL_CLI', 'Cliente', 145);
    Columna('TELEFONO_CLLAM', 'Teléfono', 100);
    Columna('MOTIVO_CLLAM', 'Motivo', 160);
    Columna('RESULTADO_CLLAM', 'Resultado', 145);
    Columna('SEGUIMIENTO_CLLAM', 'Volver a llamar', 110);
  end;
end;

procedure TAccionesLlamadas.EnlazarRejilla(ARejilla: TObject);
begin
  Actualizar;
  MostrarListado(ARejilla as TcxGrid, FOrigen);
end;

procedure TAccionesLlamadas.EnlazarInforme(ARejilla: TObject;
  ASoloSeguimiento: Boolean);
var
  oRejilla: TcxGrid;
  oOrigen: TDataSource;
  oDatos, oAnterior: TDataSet;
begin
  oRejilla := ARejilla as TcxGrid;
  oOrigen := oRejilla.FindComponent('OrigenInformeLlamadas') as TDataSource;
  if oOrigen = nil then
  begin
    oOrigen := TDataSource.Create(oRejilla);
    oOrigen.Name := 'OrigenInformeLlamadas';
  end;
  oDatos := FRepositorio.AbrirListado(ASoloSeguimiento);
  oOrigen.InsertComponent(oDatos);
  oAnterior := oOrigen.DataSet;
  oOrigen.DataSet := oDatos;
  oAnterior.Free;
  MostrarListado(oRejilla, oOrigen);
end;

function TAccionesLlamadas.Puede(const AAccion: string): Boolean;
begin
  Result := FRepositorio.Permitido('Llamadas.' + AAccion);
end;

function TAccionesLlamadas.Seleccionar: Boolean;
begin
  Result := Assigned(FDatos) and not FDatos.IsEmpty;
  if Result then
  begin
    FId := FDatos.FieldByName('ID_CLLAM').AsLargeInt;
    FVersion := FDatos.FieldByName('VERSION_CLLAM').AsInteger;
    FClienteEdicion := FDatos.FieldByName('CODIGO_CLI_CLLAM').AsString;
  end;
end;

procedure TAccionesLlamadas.Nueva;
begin
  FId := 0;
  FVersion := 0;
  FClienteEdicion := FRepositorio.Cliente;
end;

function TAccionesLlamadas.Campo(const ANombre: string): string;
begin
  Result := '';
  if (FId <> 0) and Assigned(FDatos) then
    Result := FDatos.FieldByName(ANombre).DisplayText;
end;

function TAccionesLlamadas.ClienteInicial: string;
begin
  Result := FClienteEdicion;
end;

function TAccionesLlamadas.ClienteEditable: Boolean;
begin
  Result := (FId = 0) and (FRepositorio.Cliente = '');
end;

function TAccionesLlamadas.AyudaSeguimiento: string;
begin
  Result := Format(SAyudaSeguimiento, [DateToStr(Date)]);
end;

procedure TAccionesLlamadas.Guardar(const ACliente, AFecha, ATelefono,
  AMotivo, AResultado, ASeguimiento: string);
begin
  // Los scripts anteriores cierran la ficha al regresar de Guardar.
  if not IntentarGuardar(ACliente, AFecha, ATelefono, AMotivo, AResultado,
    ASeguimiento) then
    Abort;
end;

function TAccionesLlamadas.IntentarGuardar(const ACliente, AFecha, ATelefono,
  AMotivo, AResultado, ASeguimiento: string): Boolean;
var
  rDatos: TDatosLlamada;
begin
  rDatos := Default(TDatosLlamada);
  rDatos.Cliente := Trim(ACliente);
  Result := False;
  if not TryStrToDateTime(Trim(AFecha), rDatos.Fecha) then
    MessageDlg_fza(Format(SRevisarFechaLlamada, [DateTimeToStr(Now)]),
      mtWarning, [mbOK], 0)
  else if (Trim(ASeguimiento) <> '') and
    not TryStrToDate(Trim(ASeguimiento), rDatos.Seguimiento) then
    MessageDlg_fza(Format(SRevisarSeguimiento, [DateToStr(Date)]),
      mtWarning, [mbOK], 0)
  else
  begin
    if not ClienteEditable and not SameText(rDatos.Cliente, FClienteEdicion) then
      raise EArgumentException.Create(SCliente);
    rDatos.Telefono := ATelefono;
    rDatos.Motivo := AMotivo;
    rDatos.Resultado := AResultado;
    FRepositorio.Guardar(FId, FVersion, rDatos);
    Result := True;
  end;
end;

procedure TAccionesLlamadas.Borrar;
begin
  if Seleccionar and
    (MessageDlg_fza(SConfirmarBorrar, mtConfirmation, [mbYes, mbNo], 0)
      = mrYes) then
  begin
    FRepositorio.Borrar(FId, FVersion);
    Actualizar;
  end;
end;

procedure TAccionesLlamadas.Imprimir(ARejilla: TObject);
var
  oImpresora: TdxComponentPrinter;
  oInforme: TdxGridReportLink;
  oRejilla: TcxGrid;
  oVista: TcxGridDBTableView;
begin
  if not Puede('imprimir') then
    raise EInvalidOpException.Create(SImpresion);
  oImpresora := TdxComponentPrinter.Create(nil);
  try
    oRejilla := ARejilla as TcxGrid;
    oInforme := oImpresora.AddLink(oRejilla) as TdxGridReportLink;
    oInforme.PrinterPage.Orientation := poLandscape;
    oInforme.OptionsSize.AutoWidth := True;
    oInforme.OptionsOnEveryPage.Headers := True;
    oInforme.OptionsView.Caption := False;
    oInforme.OptionsView.FilterBar := False;
    if oRejilla.ActiveView is TcxGridDBTableView then
    begin
      oVista := TcxGridDBTableView(oRejilla.ActiveView);
      oInforme.OptionsView.FilterBar := oVista.DataController.Filter.Active
        and not oVista.DataController.Filter.IsEmpty;
    end;
    oImpresora.Preview(True, oInforme);
  finally
    oImpresora.Free;
  end;
end;

end.

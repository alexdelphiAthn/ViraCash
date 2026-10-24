{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraducciones                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Acceso UniDAC al catálogo de traducciones de ViraCash.                    }
{******************************************************************************}
unit UniDataTraducciones;

interface

uses
  System.Classes, Datasnap.DBClient,
  Uni, MySQLUniProvider;

type
  TdmTraducciones = class(TDataModule)
  private
    FComando: TUniQuery;
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    function GetConectado: Boolean;
    procedure PrepararDatos(ADatos: TClientDataSet);
    procedure PrepararComandoGuardar;
    procedure VerificarCatalogo;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Conectar(
      const AServidor: string;
      APuerto: Integer;
      const ABaseDatos, AUsuario, AClave: string);
    procedure Desconectar;
    procedure CargarTraducciones(
      ADatos: TClientDataSet;
      const AIdiomaDestino: string;
      ASoloPendientes: Boolean);
    procedure CargarIdiomasDestino(AIdiomas: TStrings);
    function GuardarTraducciones(
      ADatos: TClientDataSet;
      const AIdiomaDestino, AUsuario: string): Integer;
    function ImportarCatalogoEspanol(
      const AUsuario: string): Integer;
    property Conectado: Boolean read GetConectado;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  cxLocalization,
  inLibRegistroResourcestringTraducciones,
  inLibRegistroParametrosTraducciones,
  inLibConfigCamposIntf,
  inLibdxSpreadSheetStrs_ESP, inLibMsgTraduc;

{$R *.dfm}

const
  CIdiomaChinoSimplificado = 'zh-CN';

type
  TEntradaImportacionTraduccion = record
    Texto: string;
    Contexto: string;
  end;

  TCatalogoImportacionTraduccion =
    TDictionary<string, TEntradaImportacionTraduccion>;

procedure AgregarEntradaImportacion(
  ACatalogo: TCatalogoImportacionTraduccion;
  const AClave, ATexto, AContexto: string);
var
  Entrada: TEntradaImportacionTraduccion;
begin
  if (AClave <> '') and
     (ATexto <> '') then
  begin
    Entrada.Texto := ATexto;
    Entrada.Contexto := AContexto;
    ACatalogo.AddOrSetValue(
      AClave,
      Entrada);
  end;
end;

procedure RecopilarResourcestrings(
  ACatalogo: TCatalogoImportacionTraduccion);
begin
  EnumerarResourcestringsTraduccion(
    procedure(
      const AClave, AContexto: string;
      ARecurso: PResStringRec)
    begin
      AgregarEntradaImportacion(
        ACatalogo,
        AClave,
        LoadResString(ARecurso),
        AContexto);
    end);
end;

procedure RecopilarParametrosDinamicos(
  ACatalogo: TCatalogoImportacionTraduccion);
begin
  EnumerarParametrosTraduccion(
    procedure(
      const AClave, ATexto, AContexto: string)
    begin
      AgregarEntradaImportacion(
        ACatalogo,
        AClave,
        ATexto,
        AContexto);
    end);
end;

procedure RecopilarDevExpress(
  ACatalogo: TCatalogoImportacionTraduccion);
var
  IdiomaEspanol: TcxLanguage;
  Localizador: TcxLocalizer;
  Nombre: string;
  Texto: string;
  i: Integer;
begin
  Localizador := TcxLocalizer.Create(nil);
  try
    Localizador.StorageType := lstResource;
    Localizador.Active := True;
    IdiomaEspanol := nil;
    for i := 0 to Localizador.Languages.Count - 1 do
      if Localizador.Languages[i].LocaleID = 1034 then
        IdiomaEspanol := Localizador.Languages[i];
    if Assigned(IdiomaEspanol) then
      for i := 0 to IdiomaEspanol.Dictionary.Count - 1 do
      begin
        Nombre := IdiomaEspanol.Dictionary.Names[i];
        Texto := IdiomaEspanol.Dictionary.ValueFromIndex[i];
        AgregarEntradaImportacion(
          ACatalogo,
          'DevExpress.' + Nombre,
          Texto,
          'CXLOCALIZATION.res');
      end;
    EnumerarTraduccionesEspanolasDxSpreadSheet(
      procedure(
        const ANombre: string;
        ARecurso: PResStringRec;
        const ATexto: string)
      begin
        if Assigned(ARecurso) then
          AgregarEntradaImportacion(
            ACatalogo,
            'DevExpress.' + ANombre,
            ATexto,
            'src/Lib/inLibdxSpreadSheetStrs_ESP.pas');
      end);
  finally
    Localizador.Free;
  end;
end;

procedure RecopilarTitulosConfigCampos(
  AConexion: TUniConnection;
  ACatalogo: TCatalogoImportacionTraduccion);
var
  Consulta: TUniQuery;
  Campo: string;
  Tabla: string;
  Titulo: string;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC ' +
      '  FROM fza_config_campos ' +
      ' ORDER BY TABLA_OBJETIVO_CC, OBJETIVO_CC';
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Tabla := Consulta.FieldByName(
        'TABLA_OBJETIVO_CC').AsString;
      Campo := Consulta.FieldByName('OBJETIVO_CC').AsString;
      Titulo := Consulta.FieldByName('TITULO_VISUAL_CC').AsString;
      AgregarEntradaImportacion(
        ACatalogo,
        ClaveTituloVisualConfigCampo(Tabla, Campo),
        Titulo,
        'fza_config_campos.' + Tabla + '.' + Campo);
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

constructor TdmTraducciones.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TMySQLUniProvider.Create(Self);
  FConexion := TUniConnection.Create(Self);
  FConexion.ProviderName := 'MySQL';
  FConexion.LoginPrompt := False;
  FConsulta := TUniQuery.Create(Self);
  FConsulta.Connection := FConexion;
  FComando := TUniQuery.Create(Self);
  FComando.Connection := FConexion;
end;

function TdmTraducciones.GetConectado: Boolean;
begin
  Result := FConexion.Connected;
end;

procedure TdmTraducciones.Conectar(
  const AServidor: string;
  APuerto: Integer;
  const ABaseDatos, AUsuario, AClave: string);
begin
  FConexion.Close;
  FConexion.Server := AServidor;
  FConexion.Port := APuerto;
  FConexion.Database := ABaseDatos;
  FConexion.Username := AUsuario;
  FConexion.Password := AClave;
  FConexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
  FConexion.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
  try
    FConexion.Open;
    VerificarCatalogo;
  except
    FConexion.Close;
    raise;
  end;
end;

procedure TdmTraducciones.Desconectar;
begin
  FConexion.Close;
end;

procedure TdmTraducciones.VerificarCatalogo;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT COUNT(*) AS TOTAL ' +
    'FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = ''fza_traducciones''';
  FConsulta.Open;
  if FConsulta.FieldByName('TOTAL').AsInteger = 0 then
    raise Exception.Create(SErrorTablaTraduccionesNoExiste);
  FConsulta.Close;
end;

procedure TdmTraducciones.PrepararDatos(ADatos: TClientDataSet);
begin
  ADatos.Close;
  ADatos.FieldDefs.Clear;
  ADatos.FieldDefs.Add('CLAVE_TRAD', ftString, 255, True);
  ADatos.FieldDefs.Add('TEXTO_ORIGEN', ftWideMemo);
  ADatos.FieldDefs.Add('TEXTO_DESTINO', ftWideMemo);
  ADatos.FieldDefs.Add('CONTEXTO_TRAD', ftString, 500);
  ADatos.CreateDataSet;
end;

procedure TdmTraducciones.CargarTraducciones(
  ADatos: TClientDataSet;
  const AIdiomaDestino: string;
  ASoloPendientes: Boolean);
begin
  PrepararDatos(ADatos);
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT Origen.CLAVE_TRAD, ' +
    '       Origen.TEXTO_TRAD AS TEXTO_ORIGEN, ' +
    '       Origen.CONTEXTO_TRAD, ' +
    '       Destino.TEXTO_TRAD AS TEXTO_DESTINO ' +
    'FROM fza_traducciones Origen ' +
    'LEFT JOIN fza_traducciones Destino ' +
    '  ON Destino.CLAVE_TRAD = Origen.CLAVE_TRAD ' +
    ' AND Destino.IDIOMA_TRAD = :idioma_destino ' +
    ' AND Destino.ESACTIVO_TRAD = ''S'' ' +
    'WHERE Origen.IDIOMA_TRAD = ''es-ES'' ' +
    '  AND Origen.ESACTIVO_TRAD = ''S'' ' +
    '  AND (:solo_pendientes = ''N'' ' +
    '       OR Destino.ID_TRAD IS NULL ' +
    '       OR OCTET_LENGTH(Destino.TEXTO_TRAD) = 0) ' +
    'ORDER BY Origen.CLAVE_TRAD';
  FConsulta.ParamByName('idioma_destino').AsString := AIdiomaDestino;
  if ASoloPendientes then
    FConsulta.ParamByName('solo_pendientes').AsString := 'S'
  else
    FConsulta.ParamByName('solo_pendientes').AsString := 'N';
  FConsulta.Open;
  ADatos.DisableControls;
  try
    while not FConsulta.Eof do
    begin
      ADatos.Append;
      ADatos.FieldByName('CLAVE_TRAD').AsString :=
        FConsulta.FieldByName('CLAVE_TRAD').AsString;
      ADatos.FieldByName('TEXTO_ORIGEN').AsWideString :=
        FConsulta.FieldByName('TEXTO_ORIGEN').AsWideString;
      ADatos.FieldByName('TEXTO_DESTINO').AsWideString :=
        FConsulta.FieldByName('TEXTO_DESTINO').AsWideString;
      ADatos.FieldByName('CONTEXTO_TRAD').AsString :=
        FConsulta.FieldByName('CONTEXTO_TRAD').AsString;
      ADatos.Post;
      FConsulta.Next;
    end;
    ADatos.MergeChangeLog;
    ADatos.First;
  finally
    ADatos.EnableControls;
    FConsulta.Close;
  end;
end;

procedure TdmTraducciones.CargarIdiomasDestino(
  AIdiomas: TStrings);
var
  Idioma: string;
begin
  AIdiomas.BeginUpdate;
  try
    AIdiomas.Clear;
    FConsulta.Close;
    FConsulta.SQL.Text :=
      'SELECT DISTINCT IDIOMA_TRAD ' +
      '  FROM fza_traducciones ' +
      ' WHERE ESACTIVO_TRAD = ''S'' ' +
      '   AND IDIOMA_TRAD <> ''es-ES'' ' +
      ' ORDER BY IDIOMA_TRAD';
    FConsulta.Open;
    while not FConsulta.Eof do
    begin
      Idioma := Trim(
        FConsulta.FieldByName('IDIOMA_TRAD').AsString);
      if Idioma <> '' then
        AIdiomas.Add(Idioma);
      FConsulta.Next;
    end;
    if AIdiomas.IndexOf(CIdiomaChinoSimplificado) < 0 then
      AIdiomas.Add(CIdiomaChinoSimplificado);
  finally
    FConsulta.Close;
    AIdiomas.EndUpdate;
  end;
end;

procedure TdmTraducciones.PrepararComandoGuardar;
begin
  FComando.SQL.Text :=
    'INSERT INTO fza_traducciones (' +
    '  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD, ' +
    '  ESACTIVO_TRAD, INSTANTE_ALTA, USUARIO_ALTA' +
    ') VALUES (' +
    '  :clave, :idioma, :texto, :contexto, ''S'', ' +
    '  CURRENT_TIMESTAMP, :usuario' +
    ') ON DUPLICATE KEY UPDATE ' +
    '  TEXTO_TRAD = VALUES(TEXTO_TRAD), ' +
    '  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD), ' +
    '  ESACTIVO_TRAD = ''S'', ' +
    '  INSTANTE_MODIF = CURRENT_TIMESTAMP, ' +
    '  USUARIO_MODIF = VALUES(USUARIO_ALTA)';
end;

function TdmTraducciones.GuardarTraducciones(
  ADatos: TClientDataSet;
  const AIdiomaDestino, AUsuario: string): Integer;
var
  ClaveActual: string;
begin
  Result := 0;
  ADatos.CheckBrowseMode;
  ClaveActual := ADatos.FieldByName('CLAVE_TRAD').AsString;
  PrepararComandoGuardar;
  FConexion.StartTransaction;
  ADatos.DisableControls;
  try
    try
      ADatos.First;
      while not ADatos.Eof do
      begin
        if (ADatos.UpdateStatus = usModified) and
           (Trim(
              ADatos.FieldByName('TEXTO_DESTINO').AsWideString) <> '') then
        begin
          FComando.ParamByName('clave').AsString :=
            ADatos.FieldByName('CLAVE_TRAD').AsString;
          FComando.ParamByName('idioma').AsString := AIdiomaDestino;
          FComando.ParamByName('texto').AsWideString :=
            ADatos.FieldByName('TEXTO_DESTINO').AsWideString;
          FComando.ParamByName('contexto').AsString :=
            ADatos.FieldByName('CONTEXTO_TRAD').AsString;
          FComando.ParamByName('usuario').AsString := AUsuario;
          FComando.ExecSQL;
          Inc(Result);
        end;
        ADatos.Next;
      end;
      FConexion.Commit;
      ADatos.MergeChangeLog;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if ClaveActual <> '' then
      ADatos.Locate('CLAVE_TRAD', ClaveActual, []);
    ADatos.EnableControls;
  end;
end;

function TdmTraducciones.ImportarCatalogoEspanol(
  const AUsuario: string): Integer;
var
  Catalogo: TCatalogoImportacionTraduccion;
  Par: TPair<string, TEntradaImportacionTraduccion>;
begin
  Catalogo := TCatalogoImportacionTraduccion.Create;
  try
    RecopilarResourcestrings(Catalogo);
    RecopilarParametrosDinamicos(Catalogo);
    RecopilarTitulosConfigCampos(FConexion, Catalogo);
    RecopilarDevExpress(Catalogo);
    PrepararComandoGuardar;
    FConexion.StartTransaction;
    try
      for Par in Catalogo do
      begin
        FComando.ParamByName('clave').AsString := Par.Key;
        FComando.ParamByName('idioma').AsString := 'es-ES';
        FComando.ParamByName('texto').AsWideString :=
          Par.Value.Texto;
        FComando.ParamByName('contexto').AsString :=
          Par.Value.Contexto;
        FComando.ParamByName('usuario').AsString := AUsuario;
        FComando.ExecSQL;
      end;
      FConexion.Commit;
      Result := Catalogo.Count;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    Catalogo.Free;
  end;
end;

end.

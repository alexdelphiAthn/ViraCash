unit UniDataDBStructureRepositorio;

interface

uses
  Data.DB, Uni,
  inLibDBStructure, inLibDBStructurePersistenciaIntf;

type
  TRepositorioEstructuraBBDDUniDAC = class(
    TInterfacedObject, IRepositorioEstructuraBBDD)
  private
    FConexion: TUniConnection;
    function ExisteObjeto(const AEsquema, ANombre,
      ATipo: string): Boolean;
    procedure ComprobarConexion;
  public
    constructor Create(AConexion: TUniConnection);
    function ExisteEsquema(const AEsquema: string): Boolean;
    function ExisteTabla(const AEsquema, ATabla: string): Boolean;
    function ExisteVista(const AEsquema, AVista: string): Boolean;
  end;

  TDBStructureChecker = class
  public
    class function Check(AConexion: TUniConnection;
      const ADatabaseName: string): TDBStructureCheckResult;
  end;

implementation

uses
  System.SysUtils;

constructor TRepositorioEstructuraBBDDUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioEstructuraBBDDUniDAC.ComprobarConexion;
begin
  if not Assigned(FConexion) or
     not FConexion.Connected then
  begin
    raise ELecturaEstructuraBBDD.Create(
      eleConexionNoDisponible,
      'La conexión de estructura no está activa.');
  end;
end;

function TRepositorioEstructuraBBDDUniDAC.ExisteEsquema(
  const AEsquema: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ' +
      ' WHERE SCHEMA_NAME = :BBDD';
    oConsulta.ParamByName('BBDD').AsString := AEsquema;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEstructuraBBDDUniDAC.ExisteObjeto(
  const AEsquema, ANombre, ATipo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if SameText(ATipo, 'TABLE') then
    begin
      oConsulta.SQL.Text :=
        'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
        ' WHERE TABLE_SCHEMA = :SCH ' +
        '   AND TABLE_NAME = :NAM ' +
        '   AND TABLE_TYPE = ''BASE TABLE''';
    end
    else if SameText(ATipo, 'VIEW') then
    begin
      oConsulta.SQL.Text :=
        'SELECT 1 FROM INFORMATION_SCHEMA.VIEWS ' +
        ' WHERE TABLE_SCHEMA = :SCH ' +
        '   AND TABLE_NAME = :NAM';
    end;
    if oConsulta.SQL.Text <> '' then
    begin
      oConsulta.ParamByName('SCH').AsString := AEsquema;
      oConsulta.ParamByName('NAM').AsString := ANombre;
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEstructuraBBDDUniDAC.ExisteTabla(
  const AEsquema, ATabla: string): Boolean;
begin
  Result := ExisteObjeto(AEsquema, ATabla, 'TABLE');
end;

function TRepositorioEstructuraBBDDUniDAC.ExisteVista(
  const AEsquema, AVista: string): Boolean;
begin
  Result := ExisteObjeto(AEsquema, AVista, 'VIEW');
end;

class function TDBStructureChecker.Check(
  AConexion: TUniConnection;
  const ADatabaseName: string): TDBStructureCheckResult;
var
  oRepositorio: IRepositorioEstructuraBBDD;
begin
  oRepositorio := TRepositorioEstructuraBBDDUniDAC.Create(AConexion);
  Result := inLibDBStructure.TDBStructureChecker.Check(
    oRepositorio, ADatabaseName);
end;

end.

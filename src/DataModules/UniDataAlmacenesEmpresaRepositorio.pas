unit UniDataAlmacenesEmpresaRepositorio;

interface

uses
  Data.DB, Uni,
  inLibAlmacenesEmpresaPersistenciaIntf;

type
  TRepositorioAlmacenesEmpresaUniDAC = class(
    TInterfacedObject, IRepositorioAlmacenesEmpresa)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function AlmacenPerteneceEmpresa(const AEmpresa,
      AAlmacen: string): Boolean;
    function PrimerAlmacenEmpresa(const AEmpresa: string): string;
    function ObtenerAlmacenDepositoEmpresa(
      const AEmpresa: string): string;
  end;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;

implementation

uses
  System.SysUtils,
  inLibData;

constructor TRepositorioAlmacenesEmpresaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioAlmacenesEmpresaUniDAC.AlmacenPerteneceEmpresa(
  const AEmpresa, AAlmacen: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND CODIGO_ALM_ALM = :ALMACEN ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      oConsulta.ParamByName('ALMACEN').AsString := Trim(AAlmacen);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioAlmacenesEmpresaUniDAC.PrimerAlmacenEmpresa(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S'' ' +
        ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), ' +
        '          CODIGO_ALM_ALM ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioAlmacenesEmpresaUniDAC.ObtenerAlmacenDepositoEmpresa(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMP ' +
        '   AND ESACTIVO_ALM = ''S'' ' +
        '   AND TIPO_USO_ALM IN (''DEPÓSITO'', ''DEPOSITO'') ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMP').AsString := AEmpresa;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearRepositorio(AConexion: TUniConnection):
  IRepositorioAlmacenesEmpresa;
begin
  Result := TRepositorioAlmacenesEmpresaUniDAC.Create(AConexion);
end;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
begin
  Result := inLibData.AlmacenPerteneceEmpresa(
    CrearRepositorio(AConexion), AEmpresa, AAlmacen);
end;

function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
begin
  Result := inLibData.PrimerAlmacenEmpresa(
    CrearRepositorio(AConexion), AEmpresa);
end;

function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
begin
  Result := inLibData.ResolverAlmacenEmpresa(
    CrearRepositorio(AConexion), AEmpresa, AAlmacen);
end;

procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
begin
  inLibData.AjustarEmpresaAlmacenDataSet(
    CrearRepositorio(AConexion), ADataSet,
    ACampoEmpresa, ACampoAlmacen);
end;

procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
begin
  inLibData.AjustarEmpresasAlmacenesDocumento(
    CrearRepositorio(AConexion), ADataSet);
end;

function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
begin
  Result := inLibData.ObtenerAlmacenDepositoEmpresa(
    CrearRepositorio(AConexion), AEmpresa);
end;

end.

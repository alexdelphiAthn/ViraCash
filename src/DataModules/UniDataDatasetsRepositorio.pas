unit UniDataDatasetsRepositorio;

interface

uses
  Data.DB, Uni,
  inLibDatasetsPersistenciaIntf;

type
  TRepositorioMetadatosDatasetsUniDAC = class(
    TInterfacedObject, IRepositorioMetadatosDatasets)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerColumnasClavePrimaria(
      const ATabla: string): TArray<string>;
  end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibDatasets;

constructor TRepositorioMetadatosDatasetsUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioMetadatosDatasetsUniDAC.ObtenerColumnasClavePrimaria(
  const ATabla: string): TArray<string>;
var
  oColumnas: TList<string>;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oColumnas := TList<string>.Create;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT COLUMN_NAME ' +
          '  FROM information_schema.KEY_COLUMN_USAGE ' +
          ' WHERE TABLE_SCHEMA = database() ' +
          '   AND TABLE_NAME = :TAB ' +
          '   AND CONSTRAINT_NAME = ''PRIMARY'' ' +
          ' ORDER BY ORDINAL_POSITION';
        oConsulta.ParamByName('TAB').AsString := ATabla;
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          oColumnas.Add(
            oConsulta.FieldByName('COLUMN_NAME').AsString);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
      Result := oColumnas.ToArray;
    finally
      FreeAndNil(oColumnas);
    end;
  end;
end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;
var
  oRepositorio: IRepositorioMetadatosDatasets;
begin
  oRepositorio := nil;
  if ADataSet is TUniQuery then
  begin
    oRepositorio := TRepositorioMetadatosDatasetsUniDAC.Create(
      TUniQuery(ADataSet).Connection);
  end;
  Result := inLibDatasets.ObtenerClavePrimaria(
    ADataSet, oRepositorio);
end;

end.

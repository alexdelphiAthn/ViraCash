unit UniDataUnidadesMedidaRepositorio;

interface

uses
  Uni,
  inLibUnidadesMedidaPersistenciaIntf;

type
  TRepositorioUnidadesMedidaUniDAC = class(
    TInterfacedObject, IRepositorioUnidadesMedida)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarUnidades:
      TArray<TUnidadMedidaPersistida>;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections;

constructor TRepositorioUnidadesMedidaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioUnidadesMedidaUniDAC.CargarUnidades:
  TArray<TUnidadMedidaPersistida>;
var
  oConsulta: TUniQuery;
  oDato: TUnidadMedidaPersistida;
  oDatos: TList<TUnidadMedidaPersistida>;
begin
  SetLength(Result, 0);
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oDatos := TList<TUnidadMedidaPersistida>.Create;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT CODIGO_UNIMED, DESCRIPCION_UNIMED, ' +
          '       DECIMALES_UNIMED, MAGNITUD_UNIMED, ' +
          '       ESBASE_UNIMED, FACTOR_BASE_UNIMED ' +
          '  FROM fza_unidades_medida';
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          oDato.Codigo := oConsulta.FieldByName(
            'CODIGO_UNIMED').AsString;
          oDato.Descripcion := oConsulta.FieldByName(
            'DESCRIPCION_UNIMED').AsString;
          oDato.Decimales := oConsulta.FieldByName(
            'DECIMALES_UNIMED').AsInteger;
          oDato.Magnitud := oConsulta.FieldByName(
            'MAGNITUD_UNIMED').AsString;
          oDato.EsBase := SameText(
            oConsulta.FieldByName('ESBASE_UNIMED').AsString, 'S');
          oDato.FactorBase := oConsulta.FieldByName(
            'FACTOR_BASE_UNIMED').AsFloat;
          oDatos.Add(oDato);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
      Result := oDatos.ToArray;
    finally
      FreeAndNil(oDatos);
    end;
  end;
end;

end.

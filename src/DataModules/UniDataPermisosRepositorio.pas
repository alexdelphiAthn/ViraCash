unit UniDataPermisosRepositorio;

interface

uses
  Uni,
  inLibPermisosIntf, inLibPermisosPersistenciaIntf;

type
  TRepositorioPermisosUniDAC = class(
    TInterfacedObject, IRepositorioPermisos)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarReglas(const AIdentidad: TIdentidadPermisos):
      TResultadoLecturaPermisos;
  end;

  TCargadorPermisosUniDAC = class
  public
    class function Cargar(AConexion: TUniConnection;
      const AIdentidad: TIdentidadPermisos): IPermisosAplicacion;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibPermisosUniDAC;

constructor TRepositorioPermisosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioPermisosUniDAC.CargarReglas(
  const AIdentidad: TIdentidadPermisos): TResultadoLecturaPermisos;
var
  oConsulta: TUniQuery;
  oRegla: TReglaPermisoPersistida;
  oReglas: TList<TReglaPermisoPersistida>;
begin
  if not Assigned(FConexion) or
     not FConexion.Connected then
  begin
    Result := TResultadoLecturaPermisos.Fallido(
      elpConexionNoDisponible,
      'La conexión de permisos no está activa.');
  end
  else
  begin
    oReglas := TList<TReglaPermisoPersistida>.Create;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        try
          oConsulta.Connection := FConexion;
          oConsulta.SQL.Text :=
            'SELECT USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM ' +
            '  FROM fza_permisos ' +
            ' WHERE USUARIO_GRUPO_PERM IN (:U, :G, :A)';
          oConsulta.ParamByName('U').AsString := AIdentidad.Usuario;
          oConsulta.ParamByName('G').AsString := AIdentidad.Grupo;
          oConsulta.ParamByName('A').AsString := 'Todos';
          oConsulta.Open;
          while not oConsulta.Eof do
          begin
            oRegla.Sujeto := oConsulta.FieldByName(
              'USUARIO_GRUPO_PERM').AsString;
            oRegla.Codigo := oConsulta.FieldByName(
              'CODIGO_PERM').AsString;
            oRegla.Permitido := SameText(
              oConsulta.FieldByName('VALOR_PERM').AsString, 'S');
            oReglas.Add(oRegla);
            oConsulta.Next;
          end;
          Result := TResultadoLecturaPermisos.Correcto(
            oReglas.ToArray);
        except
          on E: Exception do
          begin
            Result := TResultadoLecturaPermisos.Fallido(
              elpConsultaFallida, E.Message);
          end;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    finally
      FreeAndNil(oReglas);
    end;
  end;
end;

class function TCargadorPermisosUniDAC.Cargar(
  AConexion: TUniConnection;
  const AIdentidad: TIdentidadPermisos): IPermisosAplicacion;
var
  oRepositorio: IRepositorioPermisos;
begin
  oRepositorio := TRepositorioPermisosUniDAC.Create(AConexion);
  Result := inLibPermisosUniDAC.TCargadorPermisosUniDAC.Cargar(
    oRepositorio, AIdentidad);
end;

end.

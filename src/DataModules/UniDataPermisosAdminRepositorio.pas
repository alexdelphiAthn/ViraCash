unit UniDataPermisosAdminRepositorio;

interface

uses
  Uni,
  inLibPermisosAdmin;

function CrearRepositoriosPermisosAdmin(
  AConexion: TUniConnection): TRepositoriosPermisosAdmin;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, DBAccess;

type
  TRepositorioPermisosAdmin = class(
    TInterfacedObject,
    IConsultaPermisosAdmin,
    IEdicionPermisosAdmin)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarSujetos: TArray<TPermisoSujeto>;
    function CatalogoCodigos: TArray<TPermisoCodigo>;
    function CargarExplicitos(
      const ASujeto: string): TDictionary<string, string>;
    procedure Establecer(const ASujeto, ACodigo, AValor,
      ADescripcion, AUsuario: string);
    procedure Heredar(const ASujeto, ACodigo: string);
    function Copiar(const AOrigen, ADestino, AUsuario: string;
      AReemplazar, ASoloMenu: Boolean): Integer;
  end;

function CrearRepositoriosPermisosAdmin(
  AConexion: TUniConnection): TRepositoriosPermisosAdmin;
var
  Repositorio: TRepositorioPermisosAdmin;
begin
  Repositorio := TRepositorioPermisosAdmin.Create(AConexion);
  Result.Consulta := Repositorio;
  Result.Edicion := Repositorio;
end;

constructor TRepositorioPermisosAdmin.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioPermisosAdmin.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioPermisosAdmin.ListarSujetos:
  TArray<TPermisoSujeto>;
var
  Lista: TList<TPermisoSujeto>;
  Consulta: TUniQuery;
  Sujeto: TPermisoSujeto;
begin
  Lista := TList<TPermisoSujeto>.Create;
  try
    Sujeto.Tipo := tsTodos;
    Sujeto.Nombre := 'Todos';
    Sujeto.Grupo := '';
    Sujeto.EsAdmin := False;
    Lista.Add(Sujeto);
    if (FConexion <> nil) and FConexion.Connected then
    begin
      Consulta := NuevaConsulta;
      try
        Consulta.SQL.Text :=
          'SELECT GRUPO_USUGRP, ' +
          '       COALESCE(ESGRUPOADMINISTRADOR_USUGRP, ''N'') AS ADM ' +
          '  FROM fza_usuarios_grupos ' +
          ' ORDER BY GRUPO_USUGRP';
        Consulta.Open;
        while not Consulta.Eof do
        begin
          Sujeto.Tipo := tsGrupo;
          Sujeto.Nombre := Consulta.FieldByName('GRUPO_USUGRP').AsString;
          Sujeto.Grupo := '';
          Sujeto.EsAdmin := Consulta.FieldByName('ADM').AsString = 'S';
          Lista.Add(Sujeto);
          Consulta.Next;
        end;
        Consulta.Close;
        Consulta.SQL.Text :=
          'SELECT u.USUARIO_USU, ' +
          '       COALESCE(u.GRUPO_USU, '''') AS G, ' +
          '       COALESCE(g.ESGRUPOADMINISTRADOR_USUGRP, ''N'') AS ADM ' +
          '  FROM fza_usuarios u ' +
          '  LEFT JOIN fza_usuarios_grupos g ' +
          '    ON g.GRUPO_USUGRP = u.GRUPO_USU ' +
          ' ORDER BY u.USUARIO_USU';
        Consulta.Open;
        while not Consulta.Eof do
        begin
          Sujeto.Tipo := tsUsuario;
          Sujeto.Nombre := Consulta.FieldByName('USUARIO_USU').AsString;
          Sujeto.Grupo := Consulta.FieldByName('G').AsString;
          Sujeto.EsAdmin := Consulta.FieldByName('ADM').AsString = 'S';
          Lista.Add(Sujeto);
          Consulta.Next;
        end;
      finally
        FreeAndNil(Consulta);
      end;
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioPermisosAdmin.CatalogoCodigos:
  TArray<TPermisoCodigo>;
var
  Lista: TList<TPermisoCodigo>;
  Consulta: TUniQuery;
  Permiso: TPermisoCodigo;
begin
  Lista := TList<TPermisoCodigo>.Create;
  try
    if (FConexion <> nil) and FConexion.Connected then
    begin
      Consulta := NuevaConsulta;
      try
        Consulta.SQL.Text :=
          'SELECT CODIGO_PERM, ' +
          '       MAX(COALESCE(DESCRIPCION_PERM, '''')) AS DESCR ' +
          '  FROM fza_permisos ' +
          ' GROUP BY CODIGO_PERM ' +
          ' ORDER BY CODIGO_PERM';
        Consulta.Open;
        while not Consulta.Eof do
        begin
          Permiso.Codigo := Consulta.FieldByName('CODIGO_PERM').AsString;
          Permiso.Descripcion := Consulta.FieldByName('DESCR').AsString;
          Lista.Add(Permiso);
          Consulta.Next;
        end;
      finally
        FreeAndNil(Consulta);
      end;
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioPermisosAdmin.CargarExplicitos(
  const ASujeto: string): TDictionary<string, string>;
var
  Consulta: TUniQuery;
begin
  Result := TDictionary<string, string>.Create;
  if (FConexion <> nil) and FConexion.Connected and (ASujeto <> '') then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT CODIGO_PERM, VALOR_PERM ' +
        '  FROM fza_permisos ' +
        ' WHERE USUARIO_GRUPO_PERM = :S';
      Consulta.ParamByName('S').AsString := ASujeto;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Result.AddOrSetValue(
          Consulta.FieldByName('CODIGO_PERM').AsString,
          Consulta.FieldByName('VALOR_PERM').AsString);
        Consulta.Next;
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TRepositorioPermisosAdmin.Establecer(
  const ASujeto, ACodigo, AValor, ADescripcion, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  if (FConexion <> nil) and FConexion.Connected and
     (ASujeto <> '') and (ACodigo <> '') then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'INSERT INTO fza_permisos ' +
        '  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, ' +
        '   DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:S, :C, :V, :D, NOW(), :UA) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  VALOR_PERM = :V2, ' +
        '  DESCRIPCION_PERM = COALESCE(:D2, DESCRIPCION_PERM), ' +
        '  INSTANTE_MODIF = NOW(), ' +
        '  USUARIO_MODIF = :UM';
      Consulta.ParamByName('S').AsString := ASujeto;
      Consulta.ParamByName('C').AsString := ACodigo;
      Consulta.ParamByName('V').AsString := AValor;
      Consulta.ParamByName('D').AsString := ADescripcion;
      Consulta.ParamByName('UA').AsString := AUsuario;
      Consulta.ParamByName('V2').AsString := AValor;
      Consulta.ParamByName('D2').AsString := ADescripcion;
      Consulta.ParamByName('UM').AsString := AUsuario;
      Consulta.ExecSQL;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TRepositorioPermisosAdmin.Heredar(
  const ASujeto, ACodigo: string);
var
  Consulta: TUniQuery;
begin
  if (FConexion <> nil) and FConexion.Connected and
     (ASujeto <> '') and (ACodigo <> '') then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'DELETE FROM fza_permisos ' +
        ' WHERE USUARIO_GRUPO_PERM = :S ' +
        '   AND CODIGO_PERM = :C';
      Consulta.ParamByName('S').AsString := ASujeto;
      Consulta.ParamByName('C').AsString := ACodigo;
      Consulta.ExecSQL;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TRepositorioPermisosAdmin.Copiar(
  const AOrigen, ADestino, AUsuario: string;
  AReemplazar, ASoloMenu: Boolean): Integer;
var
  Consulta: TUniQuery;
  Filtro: string;
  TransaccionPropia: Boolean;
begin
  Result := 0;
  if (FConexion <> nil) and FConexion.Connected and
     (AOrigen <> '') and (ADestino <> '') and
     (not SameText(AOrigen, ADestino)) then
  begin
    if ASoloMenu then
      Filtro := ' AND CODIGO_PERM LIKE ''menu.%'' '
    else
      Filtro := ' ';
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    Consulta := NuevaConsulta;
    try
      try
        Consulta.SQL.Text :=
          'SELECT COUNT(*) AS N FROM fza_permisos ' +
          ' WHERE USUARIO_GRUPO_PERM = :O' + Filtro;
        Consulta.ParamByName('O').AsString := AOrigen;
        Consulta.Open;
        Result := Consulta.FieldByName('N').AsInteger;
        Consulta.Close;
        if AReemplazar then
        begin
          Consulta.SQL.Text :=
            'DELETE FROM fza_permisos ' +
            ' WHERE USUARIO_GRUPO_PERM = :D' + Filtro;
          Consulta.ParamByName('D').AsString := ADestino;
          Consulta.ExecSQL;
        end;
        Consulta.SQL.Text :=
          'INSERT INTO fza_permisos ' +
          '  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, ' +
          '   DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA) ' +
          'SELECT :D2, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, ' +
          '       NOW(), :UA ' +
          '  FROM fza_permisos ' +
          ' WHERE USUARIO_GRUPO_PERM = :O2' + Filtro +
          'ON DUPLICATE KEY UPDATE ' +
          '  VALOR_PERM = VALUES(VALOR_PERM), ' +
          '  DESCRIPCION_PERM = VALUES(DESCRIPCION_PERM), ' +
          '  INSTANTE_MODIF = NOW(), ' +
          '  USUARIO_MODIF = :UM';
        Consulta.ParamByName('D2').AsString := ADestino;
        Consulta.ParamByName('UA').AsString := AUsuario;
        Consulta.ParamByName('O2').AsString := AOrigen;
        Consulta.ParamByName('UM').AsString := AUsuario;
        Consulta.ExecSQL;
        if TransaccionPropia and FConexion.InTransaction then
          FConexion.Commit;
      except
        if TransaccionPropia and FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

end.

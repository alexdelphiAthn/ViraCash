{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataImpresionRepositorio                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de formatos y guias de impresion.                     }
{******************************************************************************}
unit UniDataImpresionRepositorio;

interface

uses
  System.Classes, Uni, inLibImpresionPersistenciaIntf;

function CrearServiciosPersistenciaImpresionUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaImpresion;

implementation

uses
  System.SysUtils, Data.DB, DBAccess, UniDataImpresionGuiasEnriquecedor;

type
  TRepositorioImpresionUniDAC = class(
    TInterfacedObject,
    IRepositorioFormatosImpresion,
    IRepositorioGuiasFormatoImpresion)
  private
    FConexion: TUniConnection;
    procedure AsignarContexto(
      AConsulta: TUniQuery;
      const AContexto: TContextoFormatosImpresion);
    function Referenciado(
      const ACodigo, AContenidoInforme: string
    ): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function Listar(
      const AContexto: TContextoFormatosImpresion
    ): TFormatosImpresion;
    function Existe(
      const AContexto: TContextoFormatosImpresion;
      const ADescripcion: string
    ): Boolean;
    function Leer(
      const AContexto: TContextoFormatosImpresion;
      const ADescripcion: string;
      AStream: TStream
    ): Boolean;
    procedure Guardar(
      const ASolicitud: TSolicitudGuardarFormato;
      AStream: TStream);
    function ObtenerPropietario(
      const AInforme, ADescripcion: string
    ): string;
    procedure Eliminar(
      const AInforme, ADescripcion: string);
    procedure Consolidar(
      const AInforme, AFormato, AUsuario, AContenidoInforme: string);
  end;

constructor TRepositorioImpresionUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioImpresionUniDAC.AsignarContexto(
  AConsulta: TUniQuery;
  const AContexto: TContextoFormatosImpresion);
begin
  AConsulta.ParamByName('INFORME').AsString := AContexto.Informe;
  AConsulta.ParamByName('USUARIO').AsString := AContexto.Usuario;
  AConsulta.ParamByName('GRUPO').AsString := AContexto.Grupo;
  AConsulta.ParamByName('TODOS').AsString := AContexto.Todos;
end;

function TRepositorioImpresionUniDAC.Listar(
  const AContexto: TContextoFormatosImpresion
): TFormatosImpresion;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT VALUE_USUPER, USUARIO_GRUPO_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND (USUARIO_GRUPO_USUPER = :USUARIO OR ' +
      '        USUARIO_GRUPO_USUPER = :GRUPO OR ' +
      '        USUARIO_GRUPO_USUPER = :TODOS)';
    AsignarContexto(oConsulta, AContexto);
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].Descripcion :=
        oConsulta.FieldByName('VALUE_USUPER').AsString;
      Result[iIndice].Propietario :=
        oConsulta.FieldByName('USUARIO_GRUPO_USUPER').AsString;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioImpresionUniDAC.Existe(
  const AContexto: TContextoFormatosImpresion;
  const ADescripcion: string
): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND VALUE_USUPER = :DESCRIPCION ' +
      '   AND (USUARIO_GRUPO_USUPER = :USUARIO OR ' +
      '        USUARIO_GRUPO_USUPER = :GRUPO OR ' +
      '        USUARIO_GRUPO_USUPER = :TODOS) ' +
      ' LIMIT 1';
    AsignarContexto(oConsulta, AContexto);
    oConsulta.ParamByName('DESCRIPCION').AsString := ADescripcion;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioImpresionUniDAC.Leer(
  const AContexto: TContextoFormatosImpresion;
  const ADescripcion: string;
  AStream: TStream
): Boolean;
var
  oConsulta: TUniQuery;
  oCampo: TBlobField;
begin
  Result := False;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT VALUE_BLOB_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND VALUE_USUPER = :DESCRIPCION ' +
      '   AND (USUARIO_GRUPO_USUPER = :USUARIO OR ' +
      '        USUARIO_GRUPO_USUPER = :GRUPO OR ' +
      '        USUARIO_GRUPO_USUPER = :TODOS) ' +
      ' ORDER BY CASE USUARIO_GRUPO_USUPER ' +
      '   WHEN :USUARIO THEN 0 WHEN :GRUPO THEN 1 ELSE 2 END ' +
      ' LIMIT 1';
    AsignarContexto(oConsulta, AContexto);
    oConsulta.ParamByName('DESCRIPCION').AsString := ADescripcion;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      oCampo := TBlobField(
        oConsulta.FieldByName('VALUE_BLOB_USUPER'));
      if not oCampo.IsNull then
      begin
        oCampo.SaveToStream(AStream);
        AStream.Position := 0;
        Result := True;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioImpresionUniDAC.Guardar(
  const ASolicitud: TSolicitudGuardarFormato;
  AStream: TStream);
var
  oConsulta: TUniQuery;
  sSubclave: string;
  bInsertar: Boolean;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Los formatos importados pueden tener otra subclave. Resolverla por
    // nombre y ámbito evita UPDATE sin filas y conserva el formato común
    // cuando el usuario guarda una copia en su propio ámbito.
    oConsulta.SQL.Text :=
      'SELECT SUBKEY_USUPER FROM fza_usuarios_perfiles ' +
      'WHERE KEY_USUPER = :INFORME ' +
      'AND USUARIO_GRUPO_USUPER = :USUARIO_GRUPO ' +
      'AND VALUE_USUPER = :DESCRIPCION LIMIT 1';
    oConsulta.ParamByName('INFORME').AsString :=
      ASolicitud.Contexto.Informe;
    oConsulta.ParamByName('USUARIO_GRUPO').AsString :=
      ASolicitud.UsuarioGrupo;
    oConsulta.ParamByName('DESCRIPCION').AsString :=
      ASolicitud.Descripcion;
    oConsulta.Open;
    bInsertar := oConsulta.IsEmpty;
    sSubclave := ASolicitud.Subclave;
    if not bInsertar then
      sSubclave := oConsulta.FieldByName('SUBKEY_USUPER').AsString;
    oConsulta.Close;
    if bInsertar then
    begin
      oConsulta.SQL.Text :=
        'INSERT INTO fza_usuarios_perfiles (' +
        '  USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, ' +
        '  VALUE_USUPER, VALUE_BLOB_USUPER, ' +
        '  INSTANTE_ALTA, INSTANTE_MODIF, ' +
        '  USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (' +
        '  :USUARIO_GRUPO, :INFORME, :SUBCLAVE, ' +
        '  :DESCRIPCION, :BLOB, NOW(), NOW(), ' +
        '  :USUARIO_ACTUAL, :USUARIO_ACTUAL)';
    end
    else
    begin
      oConsulta.SQL.Text :=
        'UPDATE fza_usuarios_perfiles SET ' +
        '  VALUE_USUPER = :DESCRIPCION, ' +
        '  VALUE_BLOB_USUPER = :BLOB, ' +
        '  INSTANTE_MODIF = NOW(), ' +
        '  USUARIO_MODIF = :USUARIO_ACTUAL ' +
        ' WHERE USUARIO_GRUPO_USUPER = :USUARIO_GRUPO ' +
        '   AND KEY_USUPER = :INFORME ' +
        '   AND SUBKEY_USUPER = :SUBCLAVE';
    end;
    oConsulta.ParamByName('USUARIO_GRUPO').AsString :=
      ASolicitud.UsuarioGrupo;
    oConsulta.ParamByName('INFORME').AsString :=
      ASolicitud.Contexto.Informe;
    oConsulta.ParamByName('SUBCLAVE').AsString := sSubclave;
    oConsulta.ParamByName('DESCRIPCION').AsString :=
      ASolicitud.Descripcion;
    oConsulta.ParamByName('USUARIO_ACTUAL').AsString :=
      ASolicitud.Contexto.Usuario;
    AStream.Position := 0;
    oConsulta.ParamByName('BLOB').LoadFromStream(AStream, ftBlob);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioImpresionUniDAC.ObtenerPropietario(
  const AInforme, ADescripcion: string
): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT USUARIO_GRUPO_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND VALUE_USUPER = :DESCRIPCION ' +
      ' LIMIT 1';
    oConsulta.ParamByName('INFORME').AsString := AInforme;
    oConsulta.ParamByName('DESCRIPCION').AsString := ADescripcion;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName(
        'USUARIO_GRUPO_USUPER').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioImpresionUniDAC.Eliminar(
  const AInforme, ADescripcion: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'DELETE FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND VALUE_USUPER = :DESCRIPCION';
    oConsulta.ParamByName('INFORME').AsString := AInforme;
    oConsulta.ParamByName('DESCRIPCION').AsString := ADescripcion;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioImpresionUniDAC.Referenciado(
  const ACodigo, AContenidoInforme: string
): Boolean;
begin
  Result :=
    (Pos('"' + ACodigo + '"', AContenidoInforme) > 0) or
    (Pos('<' + ACodigo + '."', AContenidoInforme) > 0) or
    (Pos('[' + ACodigo + '."', AContenidoInforme) > 0);
end;

procedure TRepositorioImpresionUniDAC.Consolidar(
  const AInforme, AFormato, AUsuario, AContenidoInforme: string);
var
  oOrigen: TUniQuery;
  oInsercion: TUniQuery;
  sCodigo: string;
begin
  oOrigen := TUniQuery.Create(nil);
  oInsercion := TUniQuery.Create(nil);
  try
    oOrigen.Connection := FConexion;
    oOrigen.SQL.Text :=
      'SELECT CODIGO_INFGUI ' +
      '  FROM fza_informes_guias ' +
      ' WHERE INFORME_INFGUI = :INFORME ' +
      '   AND FORMATO_INFGUI = ''''';
    oOrigen.ParamByName('INFORME').AsString := AInforme;
    oOrigen.Open;
    oInsercion.Connection := FConexion;
    oInsercion.SQL.Text :=
      'INSERT INTO fza_informes_guias (' +
      '  CODIGO_INFGUI, INFORME_INFGUI, FORMATO_INFGUI, ' +
      '  DATASET_MASTER_INFGUI, TIPO_INFGUI, TABLA_INFGUI, ' +
      '  SQL_INFGUI, MASTER_FIELDS_INFGUI, DETAIL_FIELDS_INFGUI, ' +
      '  ORDEN_INFGUI, ESACTIVO_INFGUI, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT G.CODIGO_INFGUI, G.INFORME_INFGUI, :FORMATO, ' +
      '       G.DATASET_MASTER_INFGUI, G.TIPO_INFGUI, ' +
      '       G.TABLA_INFGUI, G.SQL_INFGUI, ' +
      '       G.MASTER_FIELDS_INFGUI, G.DETAIL_FIELDS_INFGUI, ' +
      '       G.ORDEN_INFGUI, G.ESACTIVO_INFGUI, NOW(), :USUARIO ' +
      '  FROM fza_informes_guias G ' +
      ' WHERE G.INFORME_INFGUI = :INFORME ' +
      '   AND G.FORMATO_INFGUI = '''' ' +
      '   AND G.CODIGO_INFGUI = :CODIGO ' +
      '   AND NOT EXISTS (' +
      '     SELECT 1 FROM fza_informes_guias E ' +
      '      WHERE E.INFORME_INFGUI = G.INFORME_INFGUI ' +
      '        AND E.FORMATO_INFGUI = :FORMATO ' +
      '        AND E.CODIGO_INFGUI = G.CODIGO_INFGUI)';
    while not oOrigen.Eof do
    begin
      sCodigo := oOrigen.FieldByName('CODIGO_INFGUI').AsString;
      if Referenciado(sCodigo, AContenidoInforme) then
      begin
        oInsercion.ParamByName('FORMATO').AsString := AFormato;
        oInsercion.ParamByName('USUARIO').AsString := AUsuario;
        oInsercion.ParamByName('INFORME').AsString := AInforme;
        oInsercion.ParamByName('CODIGO').AsString := sCodigo;
        oInsercion.Execute;
      end;
      oOrigen.Next;
    end;
  finally
    FreeAndNil(oInsercion);
    FreeAndNil(oOrigen);
  end;
end;

function CrearServiciosPersistenciaImpresionUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaImpresion;
var
  oRepositorio: TRepositorioImpresionUniDAC;
begin
  oRepositorio := TRepositorioImpresionUniDAC.Create(AConexion);
  Result.Formatos := oRepositorio;
  Result.Guias := oRepositorio;
  Result.Enriquecedor := TEnriquecedorGuiasImpresionUniDAC.Create(
    AConexion);
end;

end.

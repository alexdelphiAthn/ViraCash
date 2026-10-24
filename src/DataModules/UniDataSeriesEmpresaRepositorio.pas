{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSeriesEmpresaRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de las series documentales de una empresa.           }
{******************************************************************************}
unit UniDataSeriesEmpresaRepositorio;

interface

uses
  Uni, inLibSeriesEmpresaPersistenciaIntf;

function CrearRepositorioSeriesEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;

// FZ-ISSUE-371: fza_facturas (y los demás documentos) tienen la clave
// NUMERO + SERIE sin empresa, mientras los contadores van por empresa: el
// texto de una serie (o su plantilla) no puede repetirse en otra empresa.
// Devuelve la otra empresa que lo usa, sin contar la fila
// ACodigoSerieExcluida (la que se edita). Las series OV de operaciones de
// caja quedan fuera: su tabla no se indexa por serie y número.
function EmpresaQueUsaSerie(
  AConexion: TUniConnection;
  const AEmpresa, ASerie, ASerieTokenizada, ATipo,
    ACodigoSerieExcluida: string): string;

implementation

uses
  System.SysUtils, Data.DB, UniDataValoresAutomaticosRepositorio,
  inLibMsgComun;

const
  SQL_TIPOS_DOCUMENTO =
    'SELECT DOC.TIPO_DOC, ' +
    '       CASE ' +
    '         WHEN DOC.TIPO_DOC IN (''AB'', ''AE'', ''AV'', ''PC'', ''PE'') ' +
    '           OR LOWER(COALESCE(TD.TABLA_ORIGEN_TIPO_DOCUMENTO_TD, ' +
    '                    '''')) LIKE ''%albaran%'' ' +
    '           OR LOWER(COALESCE(TD.TABLA_ORIGEN_TIPO_DOCUMENTO_TD, ' +
    '                    '''')) LIKE ''%pedido%'' ' +
    '         THEN ''N'' ' +
    '         WHEN DOC.TIPO_DOC IN ' +
    '              (''VE'', ''DE'', ''DV'', ''TR'', ''TA'') ' +
    '         THEN ''S'' ELSE ''N'' ' +
    '       END AS ESCAJA ' +
    '  FROM (SELECT CODIGO_TIPO_DOCUMENTO_TD AS TIPO_DOC ' +
    '          FROM fza_tipos_documentos ' +
    '         WHERE TRIM(COALESCE(CODIGO_TIPO_DOCUMENTO_TD, '''')) <> '''' ' +
    '         UNION SELECT TIPO_DOC_CON FROM fza_contadores ' +
    '         WHERE TRIM(COALESCE(TIPO_DOC_CON, '''')) <> '''' ' +
    '         UNION SELECT TIPO_DOC_EMPSER FROM fza_empresas_series ' +
    '         WHERE TRIM(COALESCE(TIPO_DOC_EMPSER, '''')) <> '''' ' +
    '         UNION SELECT ''VE'' ' +
    '         UNION SELECT ''DE'' ' +
    '         UNION SELECT ''DV'' ' +
    '         UNION SELECT ''TR'' ' +
    '         UNION SELECT ''TA'') DOC ' +
    '  LEFT JOIN fza_tipos_documentos TD ' +
    '    ON TD.CODIGO_TIPO_DOCUMENTO_TD = DOC.TIPO_DOC ' +
    ' ORDER BY DOC.TIPO_DOC';
  SQL_EXISTE_SERIE_SOLAPADA =
    'SELECT 1 FROM fza_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIPO ' +
    'AND IFNULL(CODIGO_ALM_EMPSER, '''') = :ALMACEN ' +
    'AND IFNULL(CODIGO_CAJA_EMPSER, '''') = :CAJA ' +
    'AND IFNULL(SERIE_TOKENIZADA_EMPSER, '''') = :SERIE_TOKENIZADA ' +
    'AND IFNULL(SUBTIPO_EMPSER, '''') = :SUBTIPO ' +
    'LIMIT 1';
  TIPO_SERIE_OPERACIONES_CAJA = 'OV';
  SQL_EMPRESA_QUE_USA_SERIE =
    'SELECT CODIGO_EMP_EMPSER FROM fza_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER <> :EMP ' +
    'AND CODIGO_SERIE_EMPSER <> :CODIGO ' +
    'AND (EMPSER = :SERIE ' +
    '     OR (:TOKENIZADA <> '''' ' +
    '         AND IFNULL(SERIE_TOKENIZADA_EMPSER, '''') = :TOKENIZADA)) ' +
    'AND NOT (:TIPO = :OV AND IFNULL(TIPO_DOC_EMPSER, '''') = :OV) ' +
    'ORDER BY CODIGO_EMP_EMPSER LIMIT 1';
  SQL_INSERTAR_SERIE =
    'INSERT INTO fza_empresas_series (CODIGO_SERIE_EMPSER, ' +
    'CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER, CODIGO_CAJA_EMPSER, EMPSER, ' +
    'SERIE_TOKENIZADA_EMPSER, TIPO_DOC_EMPSER, SUBTIPO_EMPSER, ' +
    'FECHA_DESDE_EMPSER, FECHA_HASTA_EMPSER, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) VALUES ' +
    '(:CODIGO, :EMP, :ALMACEN, NULLIF(:CAJA, ''''), ' +
    'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(:SERIE_TOKENIZADA), ' +
    '''yyyy'', CAST(YEAR(CURDATE()) AS CHAR)), ' +
    '''yy'', DATE_FORMAT(CURDATE(), ''%y'')), ' +
    '''mm'', DATE_FORMAT(CURDATE(), ''%m'')), ' +
    '''dd'', DATE_FORMAT(CURDATE(), ''%d'')), ' +
    '''q'', CAST(QUARTER(CURDATE()) AS CHAR)), ' +
    ':SERIE_TOKENIZADA, :TIPO, NULLIF(:SUBTIPO, ''''), NULL, NULL, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO)';

type
  TRepositorioSeriesEmpresaUniDAC = class(
    TInterfacedObject,
    IRepositorioSeriesEmpresa)
  private
    FConexion: TUniConnection;
    function ExisteSerieSolapada(
      const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
      const ATipo, ASubtipo: string): Boolean;
    procedure InsertarSerie(
      const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
      const ATipo, ASubtipo: string;
      const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    function ListarTiposDocumento: TTiposDocumentoEmpresa;
    function CrearSerieSiFalta(
      const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
      const ATipo, ASubtipo: string;
      const AUsuario: string): Boolean;
    function EmpresaQueUsaSerie(
      const AEmpresa, ASerie, ASerieTokenizada: string): string;
  end;

constructor TRepositorioSeriesEmpresaUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioSeriesEmpresaUniDAC.ListarTiposDocumento:
  TTiposDocumentoEmpresa;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_TIPOS_DOCUMENTO;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion].Codigo :=
        Consulta.FieldByName('TIPO_DOC').AsString;
      Result[Posicion].UsaCaja :=
        Consulta.FieldByName('ESCAJA').AsString = 'S';
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioSeriesEmpresaUniDAC.ExisteSerieSolapada(
  const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
  const ATipo, ASubtipo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_EXISTE_SERIE_SOLAPADA;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SERIE_TOKENIZADA').AsString :=
      ASerieTokenizada;
    Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioSeriesEmpresaUniDAC.InsertarSerie(
  const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
  const ATipo, ASubtipo: string;
  const AUsuario: string);
var
  Codigo: string;
  Consulta: TUniQuery;
begin
  Codigo := ObtenerSiguienteContador(FConexion, 'ES', AUsuario);
  if Trim(Codigo) = '' then
    raise Exception.Create(SErrorContadorSerieEmpresa);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_INSERTAR_SERIE;
    Consulta.ParamByName('CODIGO').AsString := Codigo;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.ParamByName('SERIE_TOKENIZADA').AsString :=
      ASerieTokenizada;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioSeriesEmpresaUniDAC.CrearSerieSiFalta(
  const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
  const ATipo, ASubtipo: string;
  const AUsuario: string): Boolean;
begin
  Result := not ExisteSerieSolapada(
    AEmpresa,
    AAlmacen,
    ACaja,
    ASerieTokenizada,
    ATipo,
    ASubtipo);
  if Result then
    InsertarSerie(
      AEmpresa,
      AAlmacen,
      ACaja,
      ASerieTokenizada,
      ATipo,
      ASubtipo,
      AUsuario);
end;

function TRepositorioSeriesEmpresaUniDAC.EmpresaQueUsaSerie(
  const AEmpresa, ASerie, ASerieTokenizada: string): string;
begin
  Result := UniDataSeriesEmpresaRepositorio.EmpresaQueUsaSerie(
    FConexion, AEmpresa, ASerie, ASerieTokenizada, '', '');
end;

function CrearRepositorioSeriesEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;
begin
  Result := TRepositorioSeriesEmpresaUniDAC.Create(AConexion);
end;

function EmpresaQueUsaSerie(
  AConexion: TUniConnection;
  const AEmpresa, ASerie, ASerieTokenizada, ATipo,
    ACodigoSerieExcluida: string): string;
var
  Consulta: TUniQuery;
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text := SQL_EMPRESA_QUE_USA_SERIE;
    Consulta.ParamByName('EMP').AsString := Trim(AEmpresa);
    Consulta.ParamByName('CODIGO').AsString := Trim(ACodigoSerieExcluida);
    Consulta.ParamByName('SERIE').AsString := Trim(ASerie);
    Consulta.ParamByName('TOKENIZADA').AsString := Trim(ASerieTokenizada);
    Consulta.ParamByName('TIPO').AsString := Trim(ATipo);
    Consulta.ParamByName('OV').AsString := TIPO_SERIE_OPERACIONES_CAJA;
    Consulta.Open;
    Result := '';
    if not Consulta.IsEmpty then
      Result := Consulta.Fields[0].AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

end.

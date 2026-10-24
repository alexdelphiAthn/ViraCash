{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataAppParamRepositorio                                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del editor de parametros de aplicacion.               }
{******************************************************************************}
unit UniDataAppParamRepositorio;

interface

uses
  Uni, inLibAppParamPersistenciaIntf;

function CrearRepositorioAppParamUniDAC(
  AConexion: TUniConnection
): IRepositorioAppParam;

implementation

uses
  System.SysUtils;

type
  TRepositorioAppParamUniDAC = class(
    TInterfacedObject,
    IRepositorioAppParam)
  private
    FConexion: TUniConnection;
    function ListarConsulta(
      const ASql, ACampo: string
    ): TCadenasAppParam;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarIdiomas: TCadenasAppParam;
    function ListarTemporadas: TCadenasAppParam;
    function ListarNifsEmpresas: TCadenasAppParam;
    function ListarTarifas: TCadenasAppParam;
    function ListarAmbitos: TCadenasAppParam;
    function ListarFormatosInforme(
      const AInforme, APrefijo: string
    ): TCadenasAppParam;
    function CargarValores(
      const AUsuario, AGrupo, AFormulario: string
    ): TValoresPerfilAppParam;
    procedure GuardarValores(
      const AUsuarioGrupo, AFormulario: string;
      const AValores: TValoresPerfilAppParam);
  end;

constructor TRepositorioAppParamUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioAppParamUniDAC.ListarConsulta(
  const ASql, ACampo: string
): TCadenasAppParam;
var
  oConsulta: TUniQuery;
  iValor: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iValor := 0;
    while not oConsulta.Eof do
    begin
      Result[iValor] := oConsulta.FieldByName(ACampo).AsString;
      Inc(iValor);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioAppParamUniDAC.ListarIdiomas: TCadenasAppParam;
begin
  Result := ListarConsulta(
    'SELECT DISTINCT IDIOMA_TRAD ' +
    '  FROM fza_traducciones ' +
    ' WHERE ESACTIVO_TRAD = ''S'' ' +
    ' ORDER BY IDIOMA_TRAD',
    'IDIOMA_TRAD');
end;

function TRepositorioAppParamUniDAC.ListarTemporadas: TCadenasAppParam;
begin
  Result := ListarConsulta(
    'SELECT PV ' +
    '  FROM fza_propiedades_valores ' +
    ' WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    '   AND ESACTIVO_PV = ''S'' ' +
    ' ORDER BY PV',
    'PV');
end;

function TRepositorioAppParamUniDAC.ListarNifsEmpresas: TCadenasAppParam;
begin
  Result := ListarConsulta(
    'SELECT DISTINCT NIF_EMP ' +
    '  FROM fza_empresas ' +
    ' WHERE IFNULL(NIF_EMP, '''') <> '''' ' +
    ' ORDER BY NIF_EMP',
    'NIF_EMP');
end;

function TRepositorioAppParamUniDAC.ListarTarifas: TCadenasAppParam;
begin
  Result := ListarConsulta(
    'SELECT CODIGO_TAR_ARTTAR ' +
    '  FROM fza_tarifas ' +
    ' WHERE ESACTIVO_ARTTAR = ''S'' ' +
    ' ORDER BY ORDEN_TAR',
    'CODIGO_TAR_ARTTAR');
end;

function TRepositorioAppParamUniDAC.ListarAmbitos: TCadenasAppParam;
begin
  Result := ListarConsulta(
    'SELECT ''Todos'' AS AMBITO ' +
    ' UNION SELECT GRUPO_USUGRP FROM fza_usuarios_grupos ' +
    ' UNION SELECT USUARIO_USU FROM fza_usuarios ' +
    ' ORDER BY AMBITO',
    'AMBITO');
end;

function TRepositorioAppParamUniDAC.ListarFormatosInforme(
  const AInforme, APrefijo: string
): TCadenasAppParam;
var
  oConsulta: TUniQuery;
  iValor: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Los formatos son filas con BLOB; '<informe>_default' guarda solo la
    // elección del predeterminado y no es un formato.
    oConsulta.SQL.Text :=
      'SELECT DISTINCT VALUE_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :INFORME ' +
      '   AND VALUE_USUPER LIKE :PREFIJO ' +
      '   AND VALUE_BLOB_USUPER IS NOT NULL ' +
      ' ORDER BY VALUE_USUPER';
    oConsulta.ParamByName('INFORME').AsString := AInforme;
    oConsulta.ParamByName('PREFIJO').AsString := APrefijo + '%';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iValor := 0;
    while not oConsulta.Eof do
    begin
      Result[iValor] := oConsulta.FieldByName('VALUE_USUPER').AsString;
      Inc(iValor);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioAppParamUniDAC.CargarValores(
  const AUsuario, AGrupo, AFormulario: string
): TValoresPerfilAppParam;
var
  oConsulta: TUniQuery;
  iValor: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_GETPERFILFORMULARIO(' +
      ':USUARIO, :GRUPO, :FORMULARIO)';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('GRUPO').AsString := AGrupo;
    oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iValor := 0;
    while not oConsulta.Eof do
    begin
      Result[iValor].Subclave :=
        oConsulta.FieldByName('SUBKEY_USUPER').AsString;
      Result[iValor].Valor :=
        oConsulta.FieldByName('VALUE_USUPER').AsString;
      Inc(iValor);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAppParamUniDAC.GuardarValores(
  const AUsuarioGrupo, AFormulario: string;
  const AValores: TValoresPerfilAppParam);
var
  oConsulta: TUniQuery;
  Valor: TValorPerfilAppParam;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_SETPERFILFORMULARIO(' +
      ':USUARIO_GRUPO, :FORMULARIO, :SUBCLAVE, :VALOR)';
    for Valor in AValores do
    begin
      oConsulta.ParamByName('USUARIO_GRUPO').AsString :=
        AUsuarioGrupo;
      oConsulta.ParamByName('FORMULARIO').AsString := AFormulario;
      oConsulta.ParamByName('SUBCLAVE').AsString := Valor.Subclave;
      oConsulta.ParamByName('VALOR').AsString := Valor.Valor;
      oConsulta.Execute;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioAppParamUniDAC(
  AConexion: TUniConnection
): IRepositorioAppParam;
begin
  Result := TRepositorioAppParamUniDAC.Create(AConexion);
end;

end.

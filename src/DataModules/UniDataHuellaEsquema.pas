{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataHuellaEsquema                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lector UniDAC del catálogo para la huella del esquema. Hace en el         }
{    programa las mismas consultas que PRC_FZA_HUELLA_ESQUEMA (mismas firmas   }
{    y exclusiones) y llama al procedimiento solo para contrastarlo. No        }
{    provoca errores de permiso: antes de leer mysql.user o llamar al          }
{    procedimiento mira en information_schema si puede.                        }
{******************************************************************************}
unit UniDataHuellaEsquema;

interface

uses
  System.Generics.Collections,
  Uni,
  inLibHuellaEsquemaIntf;

type
  TLectorCatalogoEsquemaUniDAC = class(
    TInterfacedObject,
    ILectorCatalogoEsquema)
  private
    FConexion: TUniConnection;
    function AbrirConsulta(const ASql: string): TUniQuery;
    procedure LeerTablasYVistas(AElementos: TList<TElementoHuella>);
    procedure LeerIndices(AElementos: TList<TElementoHuella>);
    procedure LeerFirmasParametros(AFirmas: TDictionary<string, string>);
    procedure LeerRutinas(AElementos: TList<TElementoHuella>);
    procedure LeerDefinidores(AElementos: TList<TElementoHuella>);
  public
    constructor Create(AConexion: TUniConnection);
    class function SqlContexto: string; static;
    class function SqlVistas: string; static;
    class function SqlColumnas: string; static;
    class function SqlIndices: string; static;
    class function SqlRutinas: string; static;
    class function SqlParametros: string; static;
    class function SqlDefinidores: string; static;
    class function SqlPuedeLeerUsuarios: string; static;
    class function SqlUsuarios: string; static;
    class function SqlExisteProcedimiento: string; static;
    class function SqlProcedimiento: string; static;
    function LeerContexto: TContextoCatalogo;
    function LeerElementos: TElementosHuella;
    function LeerHuellasProcedimiento: THuellasProcedimiento;
  end;

function CrearLectorCatalogoEsquemaUniDAC(
  AConexion: TUniConnection): ILectorCatalogoEsquema;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibHuellaEsquema;

const
  // Lo mismo que excluye PRC_FZA_HUELLA_ESQUEMA: temporales, copias,
  // objetos de usuario (fzu_, vu_, PRU_), vistas *_print (se amplían a
  // petición), los propios procedimientos y la sonda de MySQL 8.
  cSinTablasAjenas =
    '    AND %0:s NOT LIKE ''tmp\_%%'' ' +
    '    AND %0:s NOT LIKE ''bak\_%%'' ' +
    '    AND %0:s NOT LIKE ''fzu\_%%'' ';
  cSinVistasAjenas =
    '    AND %0:s NOT LIKE ''tmp\_%%'' ' +
    '    AND %0:s NOT LIKE ''vu\_%%'' ';
  cSinRutinasAjenas =
    '    AND %0:s NOT LIKE ''PRC\_FZA\_HUELLA\_ESQUEMA%%'' ' +
    '    AND %0:s NOT LIKE ''PRU\_%%'' ' +
    '    AND %0:s <> ''PRC_FZA_EN_TRANSACCION'' ';
  cProcedimientoHuella = 'PRC_FZA_HUELLA_ESQUEMA';

function CrearLectorCatalogoEsquemaUniDAC(
  AConexion: TUniConnection): ILectorCatalogoEsquema;
begin
  Result := TLectorCatalogoEsquemaUniDAC.Create(AConexion);
end;

function NuevoElemento(
  AApartado: TApartadoHuella;
  const AObjeto, AFirma: string): TElementoHuella;
begin
  Result.Apartado := AApartado;
  Result.Objeto := AObjeto;
  Result.Firma := AFirma;
end;

{ TLectorCatalogoEsquemaUniDAC }

constructor TLectorCatalogoEsquemaUniDAC.Create(AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

class function TLectorCatalogoEsquemaUniDAC.SqlContexto: string;
begin
  Result :=
    ' SELECT DATABASE() AS BASE_DATOS, ' +
    '        VERSION() AS VERSION_SERVIDOR, ' +
    '        CURRENT_USER() AS USUARIO ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlVistas: string;
begin
  Result :=
    ' SELECT LOWER(T.TABLE_NAME) AS TABLA ' +
    '   FROM information_schema.TABLES T ' +
    '  WHERE T.TABLE_SCHEMA = DATABASE() ' +
    '    AND T.TABLE_TYPE = ''VIEW'' ' +
    Format(cSinVistasAjenas, ['T.TABLE_NAME']);
end;

class function TLectorCatalogoEsquemaUniDAC.SqlColumnas: string;
begin
  Result :=
    ' SELECT LOWER(C.TABLE_NAME) AS TABLA, ' +
    '        LOWER(CONCAT(C.TABLE_NAME, ''.'', C.COLUMN_NAME)) AS OBJETO, ' +
    '        CONCAT(LOWER(C.DATA_TYPE), ''|'', ' +
    '               IFNULL(C.CHARACTER_MAXIMUM_LENGTH, ''''), ''|'', ' +
    '               IFNULL(C.NUMERIC_PRECISION, ''''), ''|'', ' +
    '               IFNULL(C.NUMERIC_SCALE, ''''), ''|'', ' +
    '               C.IS_NULLABLE) AS FIRMA ' +
    '   FROM information_schema.COLUMNS C ' +
    '  WHERE C.TABLE_SCHEMA = DATABASE() ' +
    Format(cSinTablasAjenas, ['C.TABLE_NAME']) +
    '    AND C.TABLE_NAME NOT LIKE ''vu\_%'' ' +
    '    AND C.TABLE_NAME NOT LIKE ''%\_print'' ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlIndices: string;
begin
  Result :=
    ' SELECT IF(S.NON_UNIQUE = 0, ''S'', ''N'') AS ESUNICO, ' +
    '        LOWER(CONCAT(S.TABLE_NAME, '':'', S.INDEX_NAME)) AS OBJETO, ' +
    '        LOWER(CONCAT(IF(S.NON_UNIQUE = 0, ''unique|'', ''index|''), ' +
    '                     GROUP_CONCAT(S.COLUMN_NAME ' +
    '                                  ORDER BY S.SEQ_IN_INDEX ' +
    '                                  SEPARATOR '',''))) AS FIRMA ' +
    '   FROM information_schema.STATISTICS S ' +
    '  WHERE S.TABLE_SCHEMA = DATABASE() ' +
    Format(cSinTablasAjenas, ['S.TABLE_NAME']) +
    '  GROUP BY S.TABLE_NAME, S.INDEX_NAME, S.NON_UNIQUE ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlRutinas: string;
begin
  Result :=
    ' SELECT LOWER(CONCAT(R.ROUTINE_TYPE, '' '', R.ROUTINE_NAME)) ' +
    '          AS OBJETO, ' +
    // El cuerpo entero: su huella se calcula en el programa, sin
    // comentarios (HuellaCuerpoRutina).
    '        R.ROUTINE_DEFINITION AS CUERPO ' +
    '   FROM information_schema.ROUTINES R ' +
    '  WHERE R.ROUTINE_SCHEMA = DATABASE() ' +
    Format(cSinRutinasAjenas, ['R.ROUTINE_NAME']);
end;

class function TLectorCatalogoEsquemaUniDAC.SqlParametros: string;
begin
  // Un parámetro por fila: el procedimiento los junta con GROUP_CONCAT,
  // que aquí cortaría en group_concat_max_len (1024 por defecto).
  Result :=
    ' SELECT LOWER(CONCAT(P.ROUTINE_TYPE, '' '', P.SPECIFIC_NAME)) ' +
    '          AS OBJETO, ' +
    '        LOWER(CONCAT(IFNULL(P.PARAMETER_MODE, ''RETURNS''), '' '', ' +
    '                     IFNULL(P.PARAMETER_NAME, ''''), '' '', ' +
    '                     P.DATA_TYPE, '' '', ' +
    '                     IFNULL(P.CHARACTER_MAXIMUM_LENGTH, ''''), '','', ' +
    '                     IFNULL(P.NUMERIC_PRECISION, ''''), '','', ' +
    '                     IFNULL(P.NUMERIC_SCALE, ''''))) AS FIRMA ' +
    '   FROM information_schema.PARAMETERS P ' +
    '  WHERE P.SPECIFIC_SCHEMA = DATABASE() ' +
    '    AND P.DATA_TYPE IS NOT NULL ' +
    '  ORDER BY P.ROUTINE_TYPE, P.SPECIFIC_NAME, P.ORDINAL_POSITION ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlDefinidores: string;
begin
  Result :=
    ' SELECT LOWER(CONCAT(''view '', V.TABLE_NAME)) AS OBJETO, ' +
    '        V.SECURITY_TYPE AS SEGURIDAD, ' +
    '        CONVERT(V.DEFINER USING utf8mb4) AS DEFINIDOR ' +
    '   FROM information_schema.VIEWS V ' +
    '  WHERE V.TABLE_SCHEMA = DATABASE() ' +
    Format(cSinVistasAjenas, ['V.TABLE_NAME']) +
    ' UNION ALL ' +
    ' SELECT LOWER(CONCAT(R.ROUTINE_TYPE, '' '', R.ROUTINE_NAME)), ' +
    '        R.SECURITY_TYPE, ' +
    '        CONVERT(R.DEFINER USING utf8mb4) ' +
    '   FROM information_schema.ROUTINES R ' +
    '  WHERE R.ROUTINE_SCHEMA = DATABASE() ' +
    Format(cSinRutinasAjenas, ['R.ROUTINE_NAME']);
end;

class function TLectorCatalogoEsquemaUniDAC.SqlPuedeLeerUsuarios: string;
begin
  // information_schema solo enseña las tablas sobre las que hay permiso.
  Result :=
    ' SELECT COUNT(*) AS N ' +
    '   FROM information_schema.TABLES T ' +
    '  WHERE T.TABLE_SCHEMA = ''mysql'' ' +
    '    AND T.TABLE_NAME = ''user'' ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlUsuarios: string;
begin
  Result :=
    ' SELECT CONVERT(CONCAT(U.User, ''@'', U.Host) USING utf8mb4) ' +
    '          AS CUENTA ' +
    '   FROM mysql.user U ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlExisteProcedimiento: string;
begin
  Result :=
    ' SELECT COUNT(*) AS N ' +
    '   FROM information_schema.ROUTINES R ' +
    '  WHERE R.ROUTINE_SCHEMA = DATABASE() ' +
    '    AND R.ROUTINE_TYPE = ''PROCEDURE'' ' +
    '    AND R.ROUTINE_NAME = ''' + cProcedimientoHuella + ''' ';
end;

class function TLectorCatalogoEsquemaUniDAC.SqlProcedimiento: string;
begin
  Result := 'CALL ' + cProcedimientoHuella + '(''N'')';
end;

function TLectorCatalogoEsquemaUniDAC.AbrirConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := ASql;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

function TLectorCatalogoEsquemaUniDAC.LeerContexto: TContextoCatalogo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := AbrirConsulta(SqlContexto);
  try
    Result.BaseDatos := oConsulta.FieldByName('BASE_DATOS').AsString;
    Result.VersionServidor := oConsulta.FieldByName(
      'VERSION_SERVIDOR').AsString;
    Result.Usuario := oConsulta.FieldByName('USUARIO').AsString;
  finally
    oConsulta.Free;
  end;
end;

procedure TLectorCatalogoEsquemaUniDAC.LeerTablasYVistas(
  AElementos: TList<TElementoHuella>);
var
  oConsulta: TUniQuery;
  // Solo importa la clave; Delphi 11 no tiene THashSet.
  oVistas: TDictionary<string, Boolean>;
  sTabla: string;
begin
  oVistas := TDictionary<string, Boolean>.Create;
  try
    oConsulta := AbrirConsulta(SqlVistas);
    try
      while not oConsulta.Eof do
      begin
        sTabla := oConsulta.FieldByName('TABLA').AsString;
        oVistas.AddOrSetValue(sTabla, True);
        AElementos.Add(NuevoElemento(ahVistas, sTabla, 'VIEW'));
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
    // Las columnas de una vista solo cuentan por su nombre: el tipo lo
    // deduce cada motor a su manera y ya lo fijan las tablas.
    oConsulta := AbrirConsulta(SqlColumnas);
    try
      while not oConsulta.Eof do
      begin
        if oVistas.ContainsKey(oConsulta.FieldByName('TABLA').AsString) then
          AElementos.Add(NuevoElemento(ahVistas,
            oConsulta.FieldByName('OBJETO').AsString, 'COLUMN'))
        else
          AElementos.Add(NuevoElemento(ahEstructura,
            oConsulta.FieldByName('OBJETO').AsString,
            oConsulta.FieldByName('FIRMA').AsString));
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
  finally
    oVistas.Free;
  end;
end;

procedure TLectorCatalogoEsquemaUniDAC.LeerIndices(
  AElementos: TList<TElementoHuella>);
var
  oConsulta: TUniQuery;
  eApartado: TApartadoHuella;
begin
  oConsulta := AbrirConsulta(SqlIndices);
  try
    while not oConsulta.Eof do
    begin
      if oConsulta.FieldByName('ESUNICO').AsString = 'S' then
        eApartado := ahEstructura
      else
        eApartado := ahIndices;
      AElementos.Add(NuevoElemento(eApartado,
        oConsulta.FieldByName('OBJETO').AsString,
        oConsulta.FieldByName('FIRMA').AsString));
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure TLectorCatalogoEsquemaUniDAC.LeerFirmasParametros(
  AFirmas: TDictionary<string, string>);
var
  oConsulta: TUniQuery;
  sObjeto, sFirma: string;
begin
  // Parámetros en su orden, separados por ';' como el GROUP_CONCAT del
  // procedimiento.
  oConsulta := AbrirConsulta(SqlParametros);
  try
    while not oConsulta.Eof do
    begin
      sObjeto := oConsulta.FieldByName('OBJETO').AsString;
      if AFirmas.TryGetValue(sObjeto, sFirma) then
        AFirmas[sObjeto] := sFirma + ';' +
          oConsulta.FieldByName('FIRMA').AsString
      else
        AFirmas.Add(sObjeto, oConsulta.FieldByName('FIRMA').AsString);
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure TLectorCatalogoEsquemaUniDAC.LeerRutinas(
  AElementos: TList<TElementoHuella>);
var
  oFirmas: TDictionary<string, string>;
  oConsulta: TUniQuery;
  sObjeto, sFirma: string;
begin
  oFirmas := TDictionary<string, string>.Create;
  try
    LeerFirmasParametros(oFirmas);
    oConsulta := AbrirConsulta(SqlRutinas);
    try
      while not oConsulta.Eof do
      begin
        sObjeto := oConsulta.FieldByName('OBJETO').AsString;
        if not oFirmas.TryGetValue(sObjeto, sFirma) then
          sFirma := '';
        AElementos.Add(NuevoElemento(ahRutinas, sObjeto, sFirma));
        // Sin permiso sobre una rutina el servidor no da su cuerpo
        // (NULL): no se puede comprobar, que no es lo mismo que sea
        // distinto.
        if oConsulta.FieldByName('CUERPO').IsNull then
          AElementos.Add(NuevoElemento(ahCodigo, sObjeto, cFirmaSinPermiso))
        else
          AElementos.Add(NuevoElemento(ahCodigo, sObjeto,
            HuellaCuerpoRutina(oConsulta.FieldByName('CUERPO').AsString)));
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
  finally
    oFirmas.Free;
  end;
end;

procedure TLectorCatalogoEsquemaUniDAC.LeerDefinidores(
  AElementos: TList<TElementoHuella>);
var
  oCuentas: TDictionary<string, Boolean>;
  oConsulta: TUniQuery;
  bPuedeLeer: Boolean;
  sFirma: string;
begin
  oCuentas := TDictionary<string, Boolean>.Create;
  try
    oConsulta := AbrirConsulta(SqlPuedeLeerUsuarios);
    try
      bPuedeLeer := oConsulta.FieldByName('N').AsInteger > 0;
    finally
      oConsulta.Free;
    end;
    if bPuedeLeer then
    begin
      oConsulta := AbrirConsulta(SqlUsuarios);
      try
        while not oConsulta.Eof do
        begin
          oCuentas.AddOrSetValue(
            oConsulta.FieldByName('CUENTA').AsString, True);
          oConsulta.Next;
        end;
      finally
        oConsulta.Free;
      end;
    end;
    oConsulta := AbrirConsulta(SqlDefinidores);
    try
      while not oConsulta.Eof do
      begin
        if oConsulta.FieldByName('SEGURIDAD').AsString = 'INVOKER' then
          sFirma := 'OK'
        else if not bPuedeLeer then
          sFirma := cFirmaSinPermiso
        else if oCuentas.ContainsKey(
                  oConsulta.FieldByName('DEFINIDOR').AsString) then
          sFirma := 'OK'
        else
          sFirma := 'NO_EXISTE';
        AElementos.Add(NuevoElemento(ahDefinidores,
          oConsulta.FieldByName('OBJETO').AsString, sFirma));
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
  finally
    oCuentas.Free;
  end;
end;

function TLectorCatalogoEsquemaUniDAC.LeerElementos: TElementosHuella;
var
  oElementos: TList<TElementoHuella>;
begin
  oElementos := TList<TElementoHuella>.Create;
  try
    LeerTablasYVistas(oElementos);
    LeerIndices(oElementos);
    LeerRutinas(oElementos);
    LeerDefinidores(oElementos);
    Result := oElementos.ToArray;
  finally
    oElementos.Free;
  end;
end;

function TLectorCatalogoEsquemaUniDAC.LeerHuellasProcedimiento:
  THuellasProcedimiento;
var
  oConsulta: TUniQuery;
  eApartado: TApartadoHuella;
  oCampo: TField;
begin
  Result := Default(THuellasProcedimiento);
  oConsulta := AbrirConsulta(SqlExisteProcedimiento);
  try
    Result.Existe := oConsulta.FieldByName('N').AsInteger > 0;
  finally
    oConsulta.Free;
  end;
  if Result.Existe then
  begin
    try
      oConsulta := AbrirConsulta(SqlProcedimiento);
      try
        Result.Version := oConsulta.FieldByName(
          'VERSION_HUELLA').AsInteger;
        Result.Huellas.Global := oConsulta.FieldByName(
          'HUELLA_GLOBAL').AsString;
        for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
        begin
          oCampo := oConsulta.FindField(
            'HUELLA_' + TextoApartadoHuella(eApartado));
          if Assigned(oCampo) then
            Result.Huellas.Apartados[eApartado] := oCampo.AsString;
        end;
      finally
        oConsulta.Free;
      end;
    except
      // Un procedimiento que falla es justo lo que se quiere detectar:
      // se informa en el resultado en vez de cortar la comprobación.
      on E: Exception do
        Result.Error := E.Message;
    end;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraduccionesRepositorio                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores UniDAC de lectura para las traducciones.                      }
{******************************************************************************}
unit UniDataTraduccionesRepositorio;

interface

uses
  Uni,
  inLibConexionesIntf,
  inLibTraduccionesPersistenciaIntf;

type
  TLectorCatalogoTraduccionesUniDAC = class(
    TInterfacedObject,
    ILectorCatalogoTraducciones)
  private
    FConexion: TUniConnection;
    FConexiones: IServicioConexiones;
    function ObtenerConexion(out AEsPropia: Boolean): TUniConnection;
  public
    constructor Create(AConexion: TUniConnection); overload;
    constructor Create(
      const AConexiones: IServicioConexiones); overload;
    function Cargar(
      const AIdioma, AIdiomaBase: string): TCatalogoTraducciones;
  end;

  TLectorIdiomaConfiguradoUniDAC = class(
    TInterfacedObject,
    ILectorIdiomaConfigurado)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Leer(const AUsuario: string): string;
  end;

implementation

uses
  System.SysUtils;

procedure AgregarTexto(
  var ACatalogo: TCatalogoTraducciones;
  const AClave, ATexto: string);
var
  iPosicion: Integer;
begin
  iPosicion := Length(ACatalogo.Textos);
  SetLength(ACatalogo.Textos, iPosicion + 1);
  ACatalogo.Textos[iPosicion].Clave := AClave;
  ACatalogo.Textos[iPosicion].Texto := ATexto;
end;

procedure AgregarTextoInforme(
  var ACatalogo: TCatalogoTraducciones;
  const ATextoBase, ATextoIdioma: string);
var
  iPosicion: Integer;
begin
  iPosicion := Length(ACatalogo.TextosInforme);
  SetLength(ACatalogo.TextosInforme, iPosicion + 1);
  ACatalogo.TextosInforme[iPosicion].TextoBase := ATextoBase;
  ACatalogo.TextosInforme[iPosicion].TextoIdioma := ATextoIdioma;
end;

constructor TLectorCatalogoTraduccionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FConexiones := nil;
end;

constructor TLectorCatalogoTraduccionesUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  inherited Create;
  FConexion := nil;
  FConexiones := AConexiones;
end;

function TLectorCatalogoTraduccionesUniDAC.ObtenerConexion(
  out AEsPropia: Boolean): TUniConnection;
begin
  AEsPropia := False;
  Result := FConexion;
  if not Assigned(Result) and
     Assigned(FConexiones) and
     FConexiones.Disponible then
  begin
    Result := FConexiones.CrearConexion(nil, uctPrecarga);
    AEsPropia := True;
  end;
end;

function TLectorCatalogoTraduccionesUniDAC.Cargar(
  const AIdioma, AIdiomaBase: string): TCatalogoTraducciones;
var
  bConexionPropia: Boolean;
  oConexion: TUniConnection;
  oConsulta: TUniQuery;
begin
  Result := Default(TCatalogoTraducciones);
  oConexion := ObtenerConexion(bConexionPropia);
  oConsulta := nil;
  try
    if Assigned(oConexion) then
    begin
      oConsulta := TUniQuery.Create(nil);
      oConsulta.Connection := oConexion;
      oConsulta.SQL.Text :=
        'SELECT CLAVE_TRAD, TEXTO_TRAD ' +
        '  FROM fza_traducciones ' +
        ' WHERE ESACTIVO_TRAD = ''S'' ' +
        '   AND (IDIOMA_TRAD = :IDIOMA ' +
        '        OR IDIOMA_TRAD = :IDIOMA_BASE) ' +
        ' ORDER BY CASE WHEN IDIOMA_TRAD = :IDIOMA_BASE ' +
        '               THEN 1 ELSE 2 END';
      oConsulta.ParamByName('IDIOMA').AsString := AIdioma;
      oConsulta.ParamByName('IDIOMA_BASE').AsString := AIdiomaBase;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        AgregarTexto(
          Result,
          oConsulta.FieldByName('CLAVE_TRAD').AsString,
          oConsulta.FieldByName('TEXTO_TRAD').AsString);
        oConsulta.Next;
      end;
      if not SameText(AIdioma, AIdiomaBase) then
      begin
        oConsulta.Close;
        oConsulta.SQL.Text :=
          'SELECT B.TEXTO_TRAD AS TEXTO_BASE, ' +
          '       T.TEXTO_TRAD AS TEXTO_IDIOMA ' +
          '  FROM fza_traducciones B ' +
          '  JOIN fza_traducciones T ' +
          '    ON T.CLAVE_TRAD = B.CLAVE_TRAD ' +
          '   AND T.IDIOMA_TRAD = :IDIOMA ' +
          '   AND T.ESACTIVO_TRAD = ''S'' ' +
          ' WHERE B.IDIOMA_TRAD = :IDIOMA_BASE ' +
          '   AND B.ESACTIVO_TRAD = ''S'' ' +
          '   AND B.CLAVE_TRAD LIKE ''FastReport.%'' ' +
          ' ORDER BY B.CLAVE_TRAD';
        oConsulta.ParamByName('IDIOMA').AsString := AIdioma;
        oConsulta.ParamByName('IDIOMA_BASE').AsString := AIdiomaBase;
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          AgregarTextoInforme(
            Result,
            oConsulta.FieldByName('TEXTO_BASE').AsString,
            oConsulta.FieldByName('TEXTO_IDIOMA').AsString);
          oConsulta.Next;
        end;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
    if bConexionPropia then
      FreeAndNil(oConexion);
  end;
end;

constructor TLectorIdiomaConfiguradoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorIdiomaConfiguradoUniDAC.Leer(
  const AUsuario: string): string;
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
        'SELECT P.VALUE_USUPER ' +
        '  FROM fza_usuarios_perfiles P ' +
        '  LEFT JOIN fza_usuarios U ' +
        '    ON U.USUARIO_USU = :USUARIO ' +
        ' WHERE P.KEY_USUPER = ''frmMtoAppParam'' ' +
        '   AND P.SUBKEY_USUPER = ''appIdioma'' ' +
        '   AND P.USUARIO_GRUPO_USUPER IN ' +
        '       (:USUARIO, U.GRUPO_USU, :TODOS) ' +
        ' ORDER BY CASE P.USUARIO_GRUPO_USUPER ' +
        '            WHEN :USUARIO THEN 1 ' +
        '            WHEN U.GRUPO_USU THEN 2 ' +
        '            ELSE 3 ' +
        '          END ' +
        ' LIMIT 1';
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ParamByName('TODOS').AsString := 'Todos';
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('VALUE_USUPER').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.

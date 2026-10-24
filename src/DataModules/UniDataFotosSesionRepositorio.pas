{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosSesionRepositorio                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de fotografías temporales de sesiones de compra.      }
{******************************************************************************}
unit UniDataFotosSesionRepositorio;

interface

uses
  Uni, inLibFotosSesionPersistenciaIntf;

function CrearRepositorioSesionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioSesionFotos;

implementation

uses
  System.SysUtils;

const
  fcodunidadses = 'CODIGO_UNIDAD_CSF';
  fcodarttentativo = 'CODIGO_ART_TENTATIVO_CSF';
  fnomfotses = 'NOMBRE_FOT_CSF';
  fextfotses = 'EXTENSION_ORIGEN_CSF';

type
  TRepositorioSesionFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioSesionFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoSesion): Boolean;
    procedure GuardarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
        AExtension, AUsuario: string);
    procedure GuardarFotosSesionLote(
      const ASerieSesion, ANumeroSesion: string;
      const AMetadatos: TMetadatosFotosSesionLote;
      const AUsuario: string);
    procedure EliminarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string);
    function BuscarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer): TArray<TMetadatosFotoSesion>;
    procedure GuardarFotoMigrada(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
        AUsuario: string);
    procedure EliminarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer);
  end;

function LeerMetadatosSesion(
  AConsulta: TUniQuery): TMetadatosFotoSesion;
begin
  Result := Default(TMetadatosFotoSesion);
  Result.CodigoArticuloTentativo :=
    AConsulta.FieldByName(fcodarttentativo).AsString;
  Result.CodigoUnidad :=
    AConsulta.FieldByName(fcodunidadses).AsString;
  Result.Nombre := AConsulta.FieldByName(fnomfotses).AsString;
  Result.Extension := AConsulta.FieldByName(fextfotses).AsString;
end;

constructor TRepositorioSesionFotosUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioSesionFotosUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioSesionFotosUniDAC.BuscarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad: string;
  out AMetadatos: TMetadatosFotoSesion): Boolean;
var
  oConsulta: TUniQuery;
begin
  AMetadatos := Default(TMetadatosFotoSesion);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    oConsulta.ParamByName('s').AsString := ASerieSesion;
    oConsulta.ParamByName('n').AsString := ANumeroSesion;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.ParamByName('u').AsString := ACodigoUnidad;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      AMetadatos := LeerMetadatosSesion(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioSesionFotosUniDAC.GuardarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
    AExtension, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_fotos ' +
      '  (SERIE_SES_CSF, NUMERO_SES_CSF, LINEA_CSF, ' +
      '   CODIGO_UNIDAD_CSF, CODIGO_ART_TENTATIVO_CSF, ' +
      '   NOMBRE_FOT_CSF, EXTENSION_ORIGEN_CSF, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:s, :n, :l, :u, :a, :nom, :ext, NOW(), :usr, ' +
      '        NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  CODIGO_ART_TENTATIVO_CSF = :a, ' +
      '  NOMBRE_FOT_CSF           = :nom, ' +
      '  EXTENSION_ORIGEN_CSF     = :ext, ' +
      '  INSTANTE_MODIF           = NOW(), ' +
      '  USUARIO_MODIF            = :usr';
    oConsulta.ParamByName('s').AsString := ASerieSesion;
    oConsulta.ParamByName('n').AsString := ANumeroSesion;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.ParamByName('u').AsString := ACodigoUnidad;
    oConsulta.ParamByName('a').AsString :=
      ACodigoArticuloTentativo;
    oConsulta.ParamByName('nom').AsString := ANombre;
    oConsulta.ParamByName('ext').AsString := AExtension;
    oConsulta.ParamByName('usr').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioSesionFotosUniDAC.GuardarFotosSesionLote(
  const ASerieSesion, ANumeroSesion: string;
  const AMetadatos: TMetadatosFotosSesionLote;
  const AUsuario: string);
var
  iFoto: Integer;
  oConsulta: TUniQuery;
  sValores: string;
begin
  if Length(AMetadatos) > 0 then
  begin
    oConsulta := NuevaConsulta;
    try
      sValores := '';
      for iFoto := 0 to High(AMetadatos) do
      begin
        if sValores <> '' then
          sValores := sValores + ', ';
        sValores := sValores +
          '(:serie, :numero, :linea' + IntToStr(iFoto) +
          ', :unidad' + IntToStr(iFoto) +
          ', :articulo' + IntToStr(iFoto) +
          ', :nombre' + IntToStr(iFoto) +
          ', :extension' + IntToStr(iFoto) +
          ', NOW(), :usuario, NOW(), :usuario)';
      end;
      oConsulta.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_fotos ' +
        '  (SERIE_SES_CSF, NUMERO_SES_CSF, LINEA_CSF, ' +
        '   CODIGO_UNIDAD_CSF, CODIGO_ART_TENTATIVO_CSF, ' +
        '   NOMBRE_FOT_CSF, EXTENSION_ORIGEN_CSF, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) VALUES ' +
        sValores +
        ' ON DUPLICATE KEY UPDATE ' +
        '   CODIGO_ART_TENTATIVO_CSF = ' +
        '     VALUES(CODIGO_ART_TENTATIVO_CSF), ' +
        '   NOMBRE_FOT_CSF = VALUES(NOMBRE_FOT_CSF), ' +
        '   EXTENSION_ORIGEN_CSF = VALUES(EXTENSION_ORIGEN_CSF), ' +
        '   INSTANTE_MODIF = NOW(), ' +
        '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
      oConsulta.ParamByName('serie').AsString := ASerieSesion;
      oConsulta.ParamByName('numero').AsString := ANumeroSesion;
      oConsulta.ParamByName('usuario').AsString := AUsuario;
      for iFoto := 0 to High(AMetadatos) do
      begin
        oConsulta.ParamByName(
          'linea' + IntToStr(iFoto)).AsInteger :=
          AMetadatos[iFoto].Linea;
        oConsulta.ParamByName(
          'unidad' + IntToStr(iFoto)).AsString :=
          AMetadatos[iFoto].CodigoUnidad;
        oConsulta.ParamByName(
          'articulo' + IntToStr(iFoto)).AsString :=
          AMetadatos[iFoto].CodigoArticuloTentativo;
        oConsulta.ParamByName(
          'nombre' + IntToStr(iFoto)).AsString :=
          AMetadatos[iFoto].Nombre;
        oConsulta.ParamByName(
          'extension' + IntToStr(iFoto)).AsString :=
          AMetadatos[iFoto].Extension;
      end;
      oConsulta.ExecSQL;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioSesionFotosUniDAC.EliminarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    oConsulta.ParamByName('s').AsString := ASerieSesion;
    oConsulta.ParamByName('n').AsString := ANumeroSesion;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.ParamByName('u').AsString := ACodigoUnidad;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioSesionFotosUniDAC.BuscarFotosSesionLinea(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer): TArray<TMetadatosFotoSesion>;
var
  oConsulta: TUniQuery;
  iFoto: Integer;
begin
  SetLength(Result, 0);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    oConsulta.ParamByName('s').AsString := ASerieSesion;
    oConsulta.ParamByName('n').AsString := ANumeroSesion;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFoto := Length(Result);
      SetLength(Result, iFoto + 1);
      Result[iFoto] := LeerMetadatosSesion(oConsulta);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioSesionFotosUniDAC.GuardarFotoMigrada(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
    AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO fza_articulos_fotos ' +
      '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, NOMBRE_FOT_FOT, ' +
      '   EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:a, :u, 1, :nom, :ext, NOW(), :usr, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  NOMBRE_FOT_FOT       = :nom, ' +
      '  EXTENSION_ORIGEN_FOT = :ext, ' +
      '  INSTANTE_MODIF       = NOW(), ' +
      '  USUARIO_MODIF        = :usr';
    oConsulta.ParamByName('a').AsString := ACodigoArticulo;
    oConsulta.ParamByName('u').AsString := ACodigoUnidad;
    oConsulta.ParamByName('nom').AsString := ANombre;
    oConsulta.ParamByName('ext').AsString := AExtension;
    oConsulta.ParamByName('usr').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioSesionFotosUniDAC.EliminarFotosSesionLinea(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    oConsulta.ParamByName('s').AsString := ASerieSesion;
    oConsulta.ParamByName('n').AsString := ANumeroSesion;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioSesionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioSesionFotos;
begin
  Result := TRepositorioSesionFotosUniDAC.Create(AConexion);
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosAtributosBasicosRepositorio                   }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de los atributos básicos editados desde los SKU.      }
{******************************************************************************}
unit UniDataArticulosAtributosBasicosRepositorio;

interface

uses
  Uni,
  inLibArticulosAtributosBasicosIntf;

type
  TRepositorioAtributosBasicosSku = class(
    TInterfacedObject,
    IRepositorioAtributosBasicosSku)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarCodigoActivo(
      const AIdVariacion, ATexto: string;
      out ACodigo: string): Boolean;
    function AsegurarValorSku(
      const ACodigoSku, AIdVariacion, AValor,
      AUsuario: string): Integer;
    function AsegurarAtributoBasico(
      const AIdVariacion, ACodigo, ANombre,
      AUsuario: string): Integer;
    procedure GuardarOverride(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const AUsuario: string);
    procedure ActualizarNombre(
      AIdBasico: Integer;
      const ANombre, AUsuario: string);
    procedure ActualizarValorNumerico(
      AIdBasico: Integer;
      const AValor: TRealOpcional;
      const AUsuario: string);
    procedure ActualizarUnidad(
      AIdBasico: Integer;
      const AUnidad, AUsuario: string);
    procedure GuardarDescripcion(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const ADescripcion: TCadenaOpcional;
      const AUsuario: string);
    procedure ActualizarHex(
      AIdBasico: Integer;
      const AHex, AUsuario: string);
  end;

implementation

uses
  System.SysUtils, Data.DB,
  UniDataAtributosSkuEnlace;

const
  SQL_BUSCAR_CODIGO_ACTIVO =
    'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
    ' WHERE ID_VA_ATB = :IDVA ' +
    '   AND ESACTIVO_ATB = ''S'' ' +
    '   AND (CODIGO_ATB = :T OR NOMBRE_ATB = :T) ' +
    ' ORDER BY (CODIGO_ATB = :T) DESC LIMIT 1';
  SQL_ENLAZAR_VALOR_SKU =
    'INSERT IGNORE INTO fza_atributos_sku ' +
    '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
    '   USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:SKU, :AV, NOW(), :USR, :USR)';
  SQL_ASEGURAR_BASICO =
    'INSERT INTO fza_atributos_basicos ' +
    '  (ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, ESACTIVO_ATB, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:IDVA, :COD, :NOM, ''S'', NOW(), :USR, :USR) ' +
    'ON DUPLICATE KEY UPDATE ' +
    '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_BUSCAR_BASICO =
    'SELECT ID_ATB FROM fza_atributos_basicos ' +
    ' WHERE ID_VA_ATB = :IDVA AND CODIGO_ATB = :COD';
  SQL_GUARDAR_OVERRIDE =
    'INSERT INTO fza_articulos_atributos_basicos ' +
    '  (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:ART, :AV, :ATB, NOW(), :USR, :USR) ' +
    'ON DUPLICATE KEY UPDATE ' +
    '  ID_ATB_AAB = VALUES(ID_ATB_AAB), ' +
    '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_ACTUALIZAR_NOMBRE =
    'UPDATE fza_atributos_basicos ' +
    '   SET NOMBRE_ATB = :VAL, USUARIO_MODIF = :USR ' +
    ' WHERE ID_ATB = :ID';
  SQL_ACTUALIZAR_VALOR_NUMERICO =
    'UPDATE fza_atributos_basicos ' +
    '   SET VALOR_NUM_ATB = :VAL, USUARIO_MODIF = :USR ' +
    ' WHERE ID_ATB = :ID';
  SQL_ACTUALIZAR_UNIDAD =
    'UPDATE fza_atributos_basicos ' +
    '   SET UNIDAD_ATB = :VAL, USUARIO_MODIF = :USR ' +
    ' WHERE ID_ATB = :ID';
  SQL_GUARDAR_DESCRIPCION =
    'INSERT INTO fza_articulos_atributos_basicos ' +
    '  (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, DESCRIPCION_AAB, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:ART, :AV, :ATB, :DES, NOW(), :USR, :USR) ' +
    'ON DUPLICATE KEY UPDATE ' +
    '  DESCRIPCION_AAB = VALUES(DESCRIPCION_AAB), ' +
    '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_ACTUALIZAR_HEX =
    'UPDATE fza_atributos_basicos ' +
    '   SET HEX_ATB = :HEX, USUARIO_MODIF = :USR ' +
    ' WHERE ID_ATB = :ID';

constructor TRepositorioAtributosBasicosSku.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioAtributosBasicosSku.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioAtributosBasicosSku.BuscarCodigoActivo(
  const AIdVariacion, ATexto: string;
  out ACodigo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  ACodigo := '';
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_BUSCAR_CODIGO_ACTIVO;
    oConsulta.ParamByName('IDVA').AsString := AIdVariacion;
    oConsulta.ParamByName('T').AsString := ATexto;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
      ACodigo := oConsulta.FieldByName('CODIGO_ATB').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioAtributosBasicosSku.AsegurarValorSku(
  const ACodigoSku, AIdVariacion, AValor,
  AUsuario: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if (ACodigoSku <> '') and
     (AIdVariacion <> '') then
  begin
    oConsulta := NuevaConsulta;
    try
      Result := AsegurarValorAtributoNormalizado(oConsulta,
        AIdVariacion, AValor, '', AUsuario, 0, 0);
      if Result > 0 then
      begin
        oConsulta.SQL.Text := SQL_ENLAZAR_VALOR_SKU;
        oConsulta.ParamByName('SKU').AsString := ACodigoSku;
        oConsulta.ParamByName('AV').AsInteger := Result;
        oConsulta.ParamByName('USR').AsString := AUsuario;
        oConsulta.Execute;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioAtributosBasicosSku.AsegurarAtributoBasico(
  const AIdVariacion, ACodigo, ANombre,
  AUsuario: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if (AIdVariacion <> '') and
     (ACodigo <> '') then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text := SQL_ASEGURAR_BASICO;
      oConsulta.ParamByName('IDVA').AsString := AIdVariacion;
      oConsulta.ParamByName('COD').AsString := ACodigo;
      oConsulta.ParamByName('NOM').AsString := ANombre;
      oConsulta.ParamByName('USR').AsString := AUsuario;
      oConsulta.Execute;
      oConsulta.SQL.Text := SQL_BUSCAR_BASICO;
      oConsulta.ParamByName('IDVA').AsString := AIdVariacion;
      oConsulta.ParamByName('COD').AsString := ACodigo;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('ID_ATB').AsInteger;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioAtributosBasicosSku.GuardarOverride(
  const ACodigoArticulo: string;
  AIdValor: Integer;
  const AIdBasico: TEnteroOpcional;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_GUARDAR_OVERRIDE;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('AV').AsInteger := AIdValor;
    if AIdBasico.TieneValor then
      oConsulta.ParamByName('ATB').AsInteger := AIdBasico.Valor
    else
      oConsulta.ParamByName('ATB').Clear;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAtributosBasicosSku.ActualizarNombre(
  AIdBasico: Integer;
  const ANombre, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ACTUALIZAR_NOMBRE;
    oConsulta.ParamByName('VAL').AsString := ANombre;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsInteger := AIdBasico;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAtributosBasicosSku.ActualizarValorNumerico(
  AIdBasico: Integer;
  const AValor: TRealOpcional;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ACTUALIZAR_VALOR_NUMERICO;
    if AValor.TieneValor then
      oConsulta.ParamByName('VAL').AsFloat := AValor.Valor
    else
      oConsulta.ParamByName('VAL').Clear;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsInteger := AIdBasico;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAtributosBasicosSku.ActualizarUnidad(
  AIdBasico: Integer;
  const AUnidad, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ACTUALIZAR_UNIDAD;
    oConsulta.ParamByName('VAL').AsString := AUnidad;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsInteger := AIdBasico;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAtributosBasicosSku.GuardarDescripcion(
  const ACodigoArticulo: string;
  AIdValor: Integer;
  const AIdBasico: TEnteroOpcional;
  const ADescripcion: TCadenaOpcional;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_GUARDAR_DESCRIPCION;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('AV').AsInteger := AIdValor;
    if AIdBasico.TieneValor then
      oConsulta.ParamByName('ATB').AsInteger := AIdBasico.Valor
    else
      oConsulta.ParamByName('ATB').Clear;
    if ADescripcion.TieneValor then
      oConsulta.ParamByName('DES').AsString := ADescripcion.Valor
    else
      oConsulta.ParamByName('DES').Clear;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAtributosBasicosSku.ActualizarHex(
  AIdBasico: Integer;
  const AHex, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ACTUALIZAR_HEX;
    oConsulta.ParamByName('HEX').AsString := AHex;
    oConsulta.ParamByName('USR').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsInteger := AIdBasico;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesArticuloServicio                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Creación de artículos y precios desde servicios de reparación.            }
{******************************************************************************}
unit UniDataReparacionesArticuloServicio;

interface

uses
  Uni, inLibReparaciones;

type
  TArticulosServicioReparacion = class
  private
    FConexion: TUniConnection;
    function Consulta(const ASql: string;
      const AEntrada: TArticuloServicioReparacion): TUniQuery;
    function GuardarArticulo(const AEntrada: TArticuloServicioReparacion):
      string;
    function PrecioTarifa(const AEntrada: TArticuloServicioReparacion;
      const ATipoIva: string): Double;
    procedure GuardarSku(const AEntrada: TArticuloServicioReparacion);
    procedure GuardarProveedor(const AEntrada: TArticuloServicioReparacion);
    procedure GuardarTarifa(const AEntrada: TArticuloServicioReparacion;
      APrecio: Double);
    procedure GuardarCoste(const AEntrada: TArticuloServicioReparacion);
    procedure Validar(const AEntrada: TArticuloServicioReparacion);
  public
    constructor Create(AConexion: TUniConnection);
    // La transacción pertenece al llamador e incluye el tipo de servicio.
    procedure Guardar(const AEntrada: TArticuloServicioReparacion);
  end;

function SqlArticulosConMarcaReparacion(AConexion: TUniConnection;
  const ASql: string): string;

implementation

uses
  System.SysUtils, System.RegularExpressions, Data.DB,
  inLibMsgReparaciones, inLibImpuestosComun;

constructor TArticulosServicioReparacion.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TArticulosServicioReparacion.Consulta(const ASql: string;
  const AEntrada: TArticuloServicioReparacion): TUniQuery;
  procedure Texto(const ANombre, AValor: string);
  begin
    if Assigned(Result.Params.FindParam(ANombre)) then
      Result.ParamByName(ANombre).AsString := AValor;
  end;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
  Texto('CODIGO', Trim(AEntrada.Tipo.Codigo));
  Texto('DESCRIPCION', AEntrada.Tipo.Descripcion);
  Texto('PROVEEDOR', AEntrada.Tipo.Proveedor);
  Texto('TARIFA', AEntrada.Tarifa);
  Texto('EMPRESA', AEntrada.Empresa);
  Texto('USUARIO', Copy(AEntrada.Usuario, 1, 50));
  if Assigned(Result.Params.FindParam('COSTE')) then
    Result.ParamByName('COSTE').AsCurrency := AEntrada.Tipo.PrecioCoste;
end;

procedure TArticulosServicioReparacion.Validar(
  const AEntrada: TArticuloServicioReparacion);
var
  oConsulta: TUniQuery;
begin
  if not FConexion.InTransaction then
    raise EArgumentException.Create(SErrorArticuloServicioTransaccion);
  if (Trim(AEntrada.Tipo.Codigo) = '') or
     (Length(Trim(AEntrada.Tipo.Codigo)) > 20) or
     (Pos('/', AEntrada.Tipo.Codigo) > 0) or
     (Pos('\', AEntrada.Tipo.Codigo) > 0) then
    raise EArgumentException.Create(SErrorArticuloServicioCodigo);
  if (Trim(AEntrada.Tipo.Descripcion) = '') or
     (AEntrada.Tipo.PrecioCliente < 0) or (AEntrada.Tipo.PrecioCoste < 0) then
    raise EArgumentException.Create(SErrorArticuloServicioDatos);
  if Trim(AEntrada.Usuario) = '' then
    raise EArgumentException.Create(SFaseUsuarioObligatorio);
  if Trim(AEntrada.Tipo.Proveedor) <> '' then
  begin
    oConsulta := Consulta('SELECT CODIGO_PRV_PRV FROM fza_proveedores ' +
      'WHERE CODIGO_PRV_PRV = :PROVEEDOR AND ESACTIVO_PRV = ''S''', AEntrada);
    try
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EArgumentException.Create(SErrorArticuloServicioProveedor);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TArticulosServicioReparacion.GuardarArticulo(
  const AEntrada: TArticuloServicioReparacion): string;
var
  oConsulta: TUniQuery;
  bExiste: Boolean;
begin
  Result := 'N';
  oConsulta := Consulta('SELECT TIPO_ART, TIPO_IVA_ART, ESVARIACION_ART, ' +
    'ESTRAZABLE_ART FROM fza_articulos WHERE CODIGO_ART_ART = :CODIGO ' +
    'FOR UPDATE', AEntrada);
  try
    oConsulta.Open;
    bExiste := not oConsulta.IsEmpty;
    if bExiste then
    begin
      if (oConsulta.FieldByName('TIPO_ART').AsString <> 'SERVICIO') or
         (oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S') or
         (oConsulta.FieldByName('ESTRAZABLE_ART').AsString = 'S') then
        raise EArgumentException.CreateFmt(SErrorArticuloServicioTipo,
          [AEntrada.Tipo.Codigo]);
      Result := oConsulta.FieldByName('TIPO_IVA_ART').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if bExiste then
    oConsulta := Consulta('UPDATE fza_articulos SET ' +
      'DESCRIPCION_ART = :DESCRIPCION, ESSERVICIO_REPARACION_ART = ''S'', ' +
      'ESACTIVO_ART = ''S'', INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO '+
      'WHERE CODIGO_ART_ART = :CODIGO', AEntrada)
  else
    oConsulta := Consulta('INSERT INTO fza_articulos ' +
      '(CODIGO_ART_ART, ORDEN_ART, ESACTIVO_ART, ESWEB_ART, TIPO_ART, ' +
      'DESCRIPCION_ART, TIPO_IVA_ART, ESACTIVO_FIJO_ART, TIPO_CANTIDAD_ART, ' +
      'ESVARIACION_ART, ESTRAZABLE_ART, ESSERVICIO_REPARACION_ART, ' +
      'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :CODIGO, COALESCE(MAX(ORDEN_ART), 0) + 1, ''S'', ''N'', ' +
      '''SERVICIO'', :DESCRIPCION, ''N'', ''N'', ''Uds'', ''N'', ''N'', ' +
      '''S'', NOW(), :USUARIO, :USUARIO FROM fza_articulos', AEntrada);
  try
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TArticulosServicioReparacion.PrecioTarifa(
  const AEntrada: TArticuloServicioReparacion; const ATipoIva: string): Double;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT T.ESIMP_INCL_TAR, ' +
    '(SELECT CASE :TIPO_IVA ' +
    'WHEN ''N'' THEN V.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN V.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN V.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN V.PORCENTAJE_EXENTO_IVA END ' +
    'FROM fza_ivas V WHERE V.IVA_IVAGRP = E.GRUPO_ZONA_IVA_EMP ' +
    'AND V.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (V.FECHA_HASTA_IVA IS NULL OR V.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY V.FECHA_DESDE_IVA DESC, V.CODIGO_IVA DESC LIMIT 1) AS IVA ' +
    'FROM fza_tarifas T JOIN fza_empresas E ON E.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND E.ESACTIVO_EMP = ''S'' WHERE T.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND T.ESACTIVO_ARTTAR = ''S''', AEntrada);
  try
    oConsulta.ParamByName('TIPO_IVA').AsString := ATipoIva;
    oConsulta.Open;
    if oConsulta.IsEmpty or oConsulta.FieldByName('IVA').IsNull then
      raise EArgumentException.Create(SErrorArticuloServicioTarifa);
    Result := AEntrada.Tipo.PrecioCliente;
    if oConsulta.FieldByName('ESIMP_INCL_TAR').AsString <> 'S' then
      Result := PrecioSinIvaDesdeConIva(Result,
        oConsulta.FieldByName('IVA').AsFloat);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TArticulosServicioReparacion.GuardarSku(
  const AEntrada: TArticuloServicioReparacion);
var
  oConsulta: TUniQuery;
  bExiste: Boolean;
begin
  oConsulta := Consulta('SELECT CODIGO_ART_SKU, CODIGO_VAR_SKU ' +
    'FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = :CODIGO FOR UPDATE',
    AEntrada);
  try
    oConsulta.Open;
    bExiste := not oConsulta.IsEmpty;
    if bExiste and
       ((oConsulta.FieldByName('CODIGO_ART_SKU').AsString <>
         AEntrada.Tipo.Codigo) or
        (oConsulta.FieldByName('CODIGO_VAR_SKU').AsString <> '-')) then
      raise EArgumentException.CreateFmt(SErrorArticuloServicioSku,
        [AEntrada.Tipo.Codigo]);
  finally
    FreeAndNil(oConsulta);
  end;
  if bExiste then
    oConsulta := Consulta('UPDATE fza_articulos_skus ' +
      'SET ESACTIVO_SKU = ''S'', USUARIO_MODIF = :USUARIO, ' +
      'INSTANTE_MODIF = NOW() WHERE CODIGO_UNIDAD_SKU = :CODIGO', AEntrada)
  else
    oConsulta := Consulta('INSERT INTO fza_articulos_skus ' +
      '(CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
      'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:CODIGO, :CODIGO, ''-'', ''S'', NOW(), :USUARIO, :USUARIO)',
      AEntrada);
  try
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TArticulosServicioReparacion.GuardarProveedor(
  const AEntrada: TArticuloServicioReparacion);
var
  oConsulta: TUniQuery;
begin
  if Trim(AEntrada.Tipo.Proveedor) <> '' then
  begin
    oConsulta := Consulta('UPDATE fza_articulos_proveedores ' +
      'SET ESPROVEEDORPRINCIPAL_AP = ''N'', INSTANTE_MODIF = NOW(), ' +
      'USUARIO_MODIF = :USUARIO WHERE CODIGO_ART_AP = :CODIGO ' +
      'AND CODIGO_PRV_AP <> :PROVEEDOR AND ESPROVEEDORPRINCIPAL_AP = ''S''',
      AEntrada);
    try
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
    oConsulta := Consulta('INSERT INTO fza_articulos_proveedores ' +
      '(CODIGO_ART_AP, CODIGO_PRV_AP, REF_PROVEEDOR_AP, ' +
      'ESPROVEEDORPRINCIPAL_AP, PRECIO_ULT_COMPRA_AP, INSTANTE_ALTA, ' +
      'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) VALUES ' +
      '(:CODIGO, :PROVEEDOR, :CODIGO, ''S'', NULLIF(:COSTE, 0), NOW(), ' +
      'NOW(), :USUARIO, :USUARIO) ON DUPLICATE KEY UPDATE ' +
      'ESPROVEEDORPRINCIPAL_AP = ''S'', ' +
      'PRECIO_ULT_COMPRA_AP = IF(:COSTE > 0, :COSTE, PRECIO_ULT_COMPRA_AP), ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO', AEntrada);
    try
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TArticulosServicioReparacion.GuardarTarifa(
  const AEntrada: TArticuloServicioReparacion; APrecio: Double);
const
  FILTRO = 'WHERE CODIGO_ART_ARTTAR = :CODIGO ' +
    'AND CODIGO_TAR_ARTTAR = :TARIFA AND ESACTIVO_ARTTAR = ''S'' ' +
    'AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') IN ('''', :CODIGO) ' +
    'AND (FECHA_DESDE_ARTTAR IS NULL OR FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (FECHA_HASTA_ARTTAR IS NULL OR FECHA_HASTA_ARTTAR >= CURDATE())';
var
  oConsulta: TUniQuery;
  bExiste: Boolean;
begin
  oConsulta := Consulta('SELECT CODIGO_UNICO_ARTTAR ' +
    'FROM fza_articulos_tarifas ' + FILTRO + ' FOR UPDATE', AEntrada);
  try
    oConsulta.Open;
    bExiste := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
  if bExiste then
    oConsulta := Consulta('UPDATE fza_articulos_tarifas ' +
      'SET PRECIO_SALIDA_ARTTAR = :PRECIO, PRECIO_FINAL_ARTTAR = :PRECIO, ' +
      'PRECIO_DTO_ARTTAR = 0, PORCENTAJE_DTO_ARTTAR = 0, ' +
      'PRECIO_COSTE_ARTTAR = IF(:COSTE > 0, :COSTE, PRECIO_COSTE_ARTTAR), ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' + FILTRO, AEntrada)
  else
    oConsulta := Consulta('INSERT INTO fza_articulos_tarifas ' +
      '(CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
      'ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
      'PRECIO_COSTE_ARTTAR, PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, ' +
      'FECHA_DESDE_ARTTAR, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:CODIGO, '''', :TARIFA, ''S'', :PRECIO, :PRECIO, ' +
      'NULLIF(:COSTE, 0), 0, 0, CURDATE(), NOW(), :USUARIO, :USUARIO)',
      AEntrada);
  try
    oConsulta.ParamByName('PRECIO').AsFloat := APrecio;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TArticulosServicioReparacion.GuardarCoste(
  const AEntrada: TArticuloServicioReparacion);
var
  oConsulta: TUniQuery;
begin
  if AEntrada.Tipo.PrecioCoste > 0 then
  begin
    oConsulta := Consulta('INSERT INTO fza_articulos_skus_costes ' +
      '(CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
      'FECHA_ULT_COMPRA_SKUC, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:CODIGO, :COSTE, CURDATE(), NOW(), :USUARIO, :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE PRECIO_ULT_COMPRA_SKUC = :COSTE, ' +
      'FECHA_ULT_COMPRA_SKUC = CURDATE(), INSTANTE_MODIF = NOW(), ' +
      'USUARIO_MODIF = :USUARIO', AEntrada);
    try
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TArticulosServicioReparacion.Guardar(
  const AEntrada: TArticuloServicioReparacion);
var
  sTipoIva: string;
  dPrecio: Double;
begin
  Validar(AEntrada);
  sTipoIva := GuardarArticulo(AEntrada);
  dPrecio := PrecioTarifa(AEntrada, sTipoIva);
  GuardarSku(AEntrada);
  GuardarProveedor(AEntrada);
  GuardarTarifa(AEntrada, dPrecio);
  GuardarCoste(AEntrada);
end;

function SqlArticulosConMarcaReparacion(AConexion: TUniConnection;
  const ASql: string): string;
var
  oConsulta: TUniQuery;
  sCampos: string;
  iAsterisco: Integer;
begin
  Result := ASql;
  if TRegEx.IsMatch(ASql, '^\s*SELECT\s+\*', [roIgnoreCase]) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.' +
        'COLUMNS WHERE TABLE_SCHEMA = DATABASE() ' +
        'AND TABLE_NAME = ''vi_articulos'' ' +
        'AND COLUMN_NAME <> ''ESSERVICIO_REPARACION_ART'' ' +
        'ORDER BY ORDINAL_POSITION';
      oConsulta.Open;
      sCampos := '';
      while not oConsulta.Eof do
      begin
        sCampos := sCampos + 'vi_articulos.`' + StringReplace(
          oConsulta.Fields[0].AsString, '`', '``', [rfReplaceAll]) + '`, ';
        oConsulta.Next;
      end;
      sCampos := sCampos + '(SELECT R.ESSERVICIO_REPARACION_ART ' +
        'FROM fza_articulos R WHERE R.CODIGO_ART_ART = ' +
        'vi_articulos.CODIGO_ART_ART) AS ESSERVICIO_REPARACION_ART';
      iAsterisco := Pos('*', ASql);
      Result := Copy(ASql, 1, iAsterisco - 1) + sCampos +
        Copy(ASql, iAsterisco + 1, MaxInt);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.

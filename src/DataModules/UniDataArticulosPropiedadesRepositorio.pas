{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosPropiedadesRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de las propiedades de artículos.                     }
{******************************************************************************}
unit UniDataArticulosPropiedadesRepositorio;

interface

uses
  Uni, inLibArticulosPropiedadesPersistenciaIntf;

function CrearServiciosPropiedadesArticuloUniDAC(
  AConexion: TUniConnection): TServiciosPropiedadesArticulo;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  UniDataPrestaShopEncolado;

type
  TRepositorioPropiedadesArticuloUniDAC = class(
    TInterfacedObject,
    ILectorPropiedadesArticulo,
    IEscritorPropiedadesArticulo)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    class function LeerDefinicion(
      AConsulta: TUniQuery): TDefinicionPropiedadArticulo; static;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarDisponibles: TArray<TDefinicionPropiedadArticulo>;
    function ListarAsignadas(
      const ACodigoArticulo: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function ListarFamilia(
      const ACodigoFamilia: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function Buscar(
      const ACodigoPropiedad: string;
      out APropiedad: TDefinicionPropiedadArticulo): Boolean;
    function ListarOpciones(
      const ACodigoPropiedad: string
    ): TArray<TOpcionPropiedadArticulo>;
    function ListarUnidades(
      const ACodigoArticulo, ANivel: string
    ): TArray<TUnidadPropiedadArticulo>;
    function ListarValoresUnidades(
      const ACodigoArticulo, ACodigoPropiedad: string
    ): TArray<TValorUnidadPropiedadArticulo>;
    procedure GuardarValor(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
      AIdValor: Integer;
      const AValorLibre, AUsuario: string);
    procedure EliminarPropiedad(
      const ACodigoArticulo, ACodigoPropiedad,
      AUsuario: string);
    procedure EliminarValorUnidad(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad,
      AUsuario: string);
  end;

constructor TRepositorioPropiedadesArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioPropiedadesArticuloUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

class function TRepositorioPropiedadesArticuloUniDAC.LeerDefinicion(
  AConsulta: TUniQuery): TDefinicionPropiedadArticulo;
begin
  Result := Default(TDefinicionPropiedadArticulo);
  Result.Codigo := AConsulta.FieldByName(
    'CODIGO_PROP_ARTPROP').AsString;
  Result.Nombre := AConsulta.FieldByName(
    'NOMBRE_PROP_PROP').AsString;
  Result.TipoValor := AConsulta.FieldByName(
    'TIPO_VALOR_PROP').AsString;
  Result.Nivel := AConsulta.FieldByName(
    'NIVEL_PROP').AsString;
  if Assigned(AConsulta.FindField('ESREQUERIDO_FA')) then
    Result.EsRequerido := AConsulta.FieldByName(
      'ESREQUERIDO_FA').AsString = 'S';
  if Assigned(AConsulta.FindField('ID_PV_ARTPROP')) then
    Result.IdValor := AConsulta.FieldByName(
      'ID_PV_ARTPROP').AsInteger;
  if Assigned(AConsulta.FindField('VALOR_LIBRE_ARTPROP')) then
    Result.ValorLibre := AConsulta.FieldByName(
      'VALOR_LIBRE_ARTPROP').AsString;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarDisponibles:
  TArray<TDefinicionPropiedadArticulo>;
var
  oConsulta: TUniQuery;
  oLista: TList<TDefinicionPropiedadArticulo>;
begin
  oLista := TList<TDefinicionPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP, ' +
      '       NIVEL_PROP ' +
      '  FROM fza_propiedades ' +
      ' WHERE ESACTIVO_PROP = ''S'' ' +
      ' ORDER BY NOMBRE_PROP_PROP';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLista.Add(LeerDefinicion(oConsulta));
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarAsignadas(
  const ACodigoArticulo: string): TArray<TDefinicionPropiedadArticulo>;
var
  oConsulta: TUniQuery;
  oLista: TList<TDefinicionPropiedadArticulo>;
begin
  oLista := TList<TDefinicionPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, ' +
      '       p.TIPO_VALOR_PROP, p.NIVEL_PROP, ' +
      '       apz.ID_PV_ARTPROP, apz.VALOR_LIBRE_ARTPROP, ' +
      '       COALESCE(fa.ESREQUERIDO_FA, ''N'') AS ESREQUERIDO_FA, ' +
      '       COALESCE(fa.ORDEN_MOSTRAR_FA, 999) AS ORDEN_MOSTRAR_FA ' +
      '  FROM (SELECT DISTINCT CODIGO_ART_ART, CODIGO_PROP_ARTPROP ' +
      '          FROM fza_articulos_propiedades ' +
      '         WHERE CODIGO_ART_ART = :ARTICULO) d ' +
      '  JOIN fza_propiedades p ' +
      '    ON p.CODIGO_PROP_ARTPROP = d.CODIGO_PROP_ARTPROP ' +
      '  LEFT JOIN fza_articulos_propiedades apz ' +
      '    ON apz.CODIGO_ART_ART = d.CODIGO_ART_ART ' +
      '   AND apz.CODIGO_PROP_ARTPROP = d.CODIGO_PROP_ARTPROP ' +
      '   AND apz.CODIGO_UNIDAD_ARTPROP = '''' ' +
      '  LEFT JOIN fza_articulos art ' +
      '    ON art.CODIGO_ART_ART = d.CODIGO_ART_ART ' +
      '  LEFT JOIN fza_familias_atributos fa ' +
      '    ON fa.CODIGO_PROP_ARTPROP = d.CODIGO_PROP_ARTPROP ' +
      '   AND fa.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
      ' WHERE p.ESACTIVO_PROP = ''S'' ' +
      ' ORDER BY COALESCE(fa.ORDEN_MOSTRAR_FA, 999), ' +
      '          p.NOMBRE_PROP_PROP';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLista.Add(LeerDefinicion(oConsulta));
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarFamilia(
  const ACodigoFamilia: string): TArray<TDefinicionPropiedadArticulo>;
var
  oConsulta: TUniQuery;
  oLista: TList<TDefinicionPropiedadArticulo>;
begin
  oLista := TList<TDefinicionPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, ' +
      '       p.TIPO_VALOR_PROP, p.NIVEL_PROP, fa.ESREQUERIDO_FA ' +
      '  FROM fza_familias_atributos fa ' +
      '  JOIN fza_propiedades p ' +
      '    ON p.CODIGO_PROP_ARTPROP = fa.CODIGO_PROP_ARTPROP ' +
      ' WHERE fa.CODIGO_FAM_FAM = :FAMILIA ' +
      '   AND p.ESACTIVO_PROP = ''S'' ' +
      ' ORDER BY fa.ORDEN_MOSTRAR_FA, p.NOMBRE_PROP_PROP';
    oConsulta.ParamByName('FAMILIA').AsString := ACodigoFamilia;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLista.Add(LeerDefinicion(oConsulta));
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.Buscar(
  const ACodigoPropiedad: string;
  out APropiedad: TDefinicionPropiedadArticulo): Boolean;
var
  oConsulta: TUniQuery;
begin
  APropiedad := Default(TDefinicionPropiedadArticulo);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP, ' +
      '       NIVEL_PROP ' +
      '  FROM fza_propiedades ' +
      ' WHERE CODIGO_PROP_ARTPROP = :PROPIEDAD';
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      APropiedad := LeerDefinicion(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarOpciones(
  const ACodigoPropiedad: string): TArray<TOpcionPropiedadArticulo>;
var
  oConsulta: TUniQuery;
  oLista: TList<TOpcionPropiedadArticulo>;
  oOpcion: TOpcionPropiedadArticulo;
begin
  oLista := TList<TOpcionPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT ID_PV_ARTPROP, PV ' +
      '  FROM fza_propiedades_valores ' +
      ' WHERE ID_PROP_PV = :PROPIEDAD ' +
      '   AND ESACTIVO_PV = ''S'' ' +
      ' ORDER BY PV';
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oOpcion.IdValor := oConsulta.FieldByName(
        'ID_PV_ARTPROP').AsInteger;
      oOpcion.Valor := oConsulta.FieldByName('PV').AsString;
      oLista.Add(oOpcion);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarUnidades(
  const ACodigoArticulo, ANivel: string
  ): TArray<TUnidadPropiedadArticulo>;
var
  iBarra: Integer;
  oConsulta: TUniQuery;
  oLista: TList<TUnidadPropiedadArticulo>;
  oUnidad: TUnidadPropiedadArticulo;
begin
  oLista := TList<TUnidadPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    if SameText(ANivel, 'SKU') then
      oConsulta.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU AS UNIDAD, ' +
        '       COALESCE((SELECT GROUP_CONCAT(av.AV ' +
        '                          ORDER BY av.ORDEN_AV SEPARATOR '' / '') ' +
        '                   FROM fza_atributos_sku sa ' +
        '                   JOIN fza_atributos_valores av ' +
        '                     ON av.ID_AV = sa.ID_AV_SA ' +
        '                  WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                        sk.CODIGO_UNIDAD_SKU), ' +
        '                sk.CODIGO_UNIDAD_SKU) AS NOMBRE ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :ARTICULO ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        ' ORDER BY sk.CODIGO_UNIDAD_SKU'
    else
      oConsulta.SQL.Text :=
        'SELECT DISTINCT ' +
        '       SUBSTRING_INDEX(CODIGO_UNIDAD_SKU, ''/'', 2) AS UNIDAD ' +
        '  FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :ARTICULO ' +
        '   AND ESACTIVO_SKU = ''S'' ' +
        '   AND CHAR_LENGTH(CODIGO_UNIDAD_SKU) ' +
        '     - CHAR_LENGTH(REPLACE(CODIGO_UNIDAD_SKU, ''/'', '''')) >= 2 ' +
        ' ORDER BY UNIDAD';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oUnidad := Default(TUnidadPropiedadArticulo);
      oUnidad.Codigo := oConsulta.FieldByName('UNIDAD').AsString;
      if SameText(ANivel, 'SKU') then
        oUnidad.Nombre := oConsulta.FieldByName('NOMBRE').AsString
      else
      begin
        iBarra := LastDelimiter('/', oUnidad.Codigo);
        if iBarra > 0 then
          oUnidad.Nombre := Copy(
            oUnidad.Codigo,
            iBarra + 1,
            MaxInt)
        else
          oUnidad.Nombre := oUnidad.Codigo;
      end;
      oLista.Add(oUnidad);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioPropiedadesArticuloUniDAC.ListarValoresUnidades(
  const ACodigoArticulo, ACodigoPropiedad: string
  ): TArray<TValorUnidadPropiedadArticulo>;
var
  oConsulta: TUniQuery;
  oLista: TList<TValorUnidadPropiedadArticulo>;
  oValor: TValorUnidadPropiedadArticulo;
begin
  oLista := TList<TValorUnidadPropiedadArticulo>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT CODIGO_UNIDAD_ARTPROP, ID_PV_ARTPROP, ' +
      '       VALOR_LIBRE_ARTPROP ' +
      '  FROM fza_articulos_propiedades ' +
      ' WHERE CODIGO_ART_ART = :ARTICULO ' +
      '   AND CODIGO_PROP_ARTPROP = :PROPIEDAD ' +
      '   AND CODIGO_UNIDAD_ARTPROP <> ''''';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oValor.CodigoUnidad := oConsulta.FieldByName(
        'CODIGO_UNIDAD_ARTPROP').AsString;
      oValor.IdValor := oConsulta.FieldByName(
        'ID_PV_ARTPROP').AsInteger;
      oValor.ValorLibre := oConsulta.FieldByName(
        'VALOR_LIBRE_ARTPROP').AsString;
      oLista.Add(oValor);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

procedure TRepositorioPropiedadesArticuloUniDAC.GuardarValor(
  const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
  AIdValor: Integer;
  const AValorLibre, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP, ' +
      '   ID_PV_ARTPROP, VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, ' +
      '   USUARIO_ALTA) ' +
      'VALUES ' +
      '  (:ARTICULO, :PROPIEDAD, :UNIDAD, :ID_VALOR, :VALOR_LIBRE, ' +
      '   NOW(), :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ID_PV_ARTPROP = VALUES(ID_PV_ARTPROP), ' +
      '  VALOR_LIBRE_ARTPROP = VALUES(VALOR_LIBRE_ARTPROP)';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.ParamByName('UNIDAD').AsString := ACodigoUnidad;
    if AIdValor > 0 then
      oConsulta.ParamByName('ID_VALOR').AsInteger := AIdValor
    else
      oConsulta.ParamByName('ID_VALOR').Clear;
    if AValorLibre <> '' then
      oConsulta.ParamByName('VALOR_LIBRE').AsString := AValorLibre
    else
      oConsulta.ParamByName('VALOR_LIBRE').Clear;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
    EncolarCambioPropiedadArticuloPrestaShop(
      FConexion,
      ACodigoArticulo,
      ACodigoPropiedad,
      AUsuario);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPropiedadesArticuloUniDAC.EliminarPropiedad(
  const ACodigoArticulo, ACodigoPropiedad, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'DELETE FROM fza_articulos_propiedades ' +
      ' WHERE CODIGO_ART_ART = :ARTICULO ' +
      '   AND CODIGO_PROP_ARTPROP = :PROPIEDAD';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.Execute;
    if oConsulta.RowsAffected > 0 then
      EncolarCambioPropiedadArticuloPrestaShop(
        FConexion,
        ACodigoArticulo,
        ACodigoPropiedad,
        AUsuario);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPropiedadesArticuloUniDAC.EliminarValorUnidad(
  const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad,
  AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'DELETE FROM fza_articulos_propiedades ' +
      ' WHERE CODIGO_ART_ART = :ARTICULO ' +
      '   AND CODIGO_PROP_ARTPROP = :PROPIEDAD ' +
      '   AND CODIGO_UNIDAD_ARTPROP = :UNIDAD';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROPIEDAD').AsString := ACodigoPropiedad;
    oConsulta.ParamByName('UNIDAD').AsString := ACodigoUnidad;
    oConsulta.Execute;
    if oConsulta.RowsAffected > 0 then
      EncolarCambioPropiedadArticuloPrestaShop(
        FConexion,
        ACodigoArticulo,
        ACodigoPropiedad,
        AUsuario);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearServiciosPropiedadesArticuloUniDAC(
  AConexion: TUniConnection): TServiciosPropiedadesArticulo;
var
  oRepositorio: TRepositorioPropiedadesArticuloUniDAC;
begin
  oRepositorio := TRepositorioPropiedadesArticuloUniDAC.Create(AConexion);
  Result.Lectura := oRepositorio;
  Result.Escritura := oRepositorio;
end;

end.

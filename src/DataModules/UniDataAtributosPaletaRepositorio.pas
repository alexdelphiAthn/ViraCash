unit UniDataAtributosPaletaRepositorio;

interface

uses
  inLibAtributosPaletaIntf;

function LecturasAtributosPaleta: ILecturasAtributosPaleta;
function SqlBasicosArticuloAtributosPaleta: string;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB, DBAccess, Uni,
  Vcl.Graphics, inLibAtributosPaleta;

type
  TLecturasAtributosPaleta = class(
    TInterfacedObject,
    ILecturasAtributosPaleta)
  public
    function ListarEntradasCache(
      AConexion: TUniConnection): TArray<TEntradaCacheBasico>;
    function ObtenerBasicosArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<string>;
    procedure CargarMapaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo: string;
      ADestino: TDictionary<string, string>);
    procedure CargarMapaGlobal(AConexion: TUniConnection;
      ADestino: TDictionary<string, string>);
    function ListarPaletaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<TValorPaletaArticulo>;
    function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
      const ACodigoArticulo, AIdVariacion, AValor: string;
      out AInfo: TInfoBasico): Boolean;
  end;

var
  GLecturas: ILecturasAtributosPaleta;

function LecturasAtributosPaleta: ILecturasAtributosPaleta;
begin
  Result := GLecturas;
end;

function SqlBasicosArticuloAtributosPaleta: string;
begin
  Result :=
    'SELECT ATB.CODIGO_ATB, MIN(ATB.ORDEN_ATB) AS ORDEN_ATB, ' +
    '       MIN(ATB.NOMBRE_ATB) AS NOMBRE_ATB ' +
    '  FROM fza_articulos_skus SK ' +
    '  JOIN fza_atributos_sku SA ' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '  JOIN fza_atributos_valores AV ' +
    '    ON AV.ID_AV = SA.ID_AV_SA ' +
    '   AND AV.ID_VA_AV = :va ' +
    '  JOIN fza_atributos_basicos ATB ' +
    '    ON ATB.ID_VA_ATB = :va ' +
    '   AND (ATB.ID_ATB = AV.ID_ATB_AV ' +
    '        OR (AV.ID_ATB_AV IS NULL AND ATB.CODIGO_ATB = AV.AV)) ' +
    ' WHERE SK.CODIGO_ART_SKU = :art ' +
    '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
    '   AND COALESCE(AV.ESACTIVO_AV, ''S'') = ''S'' ' +
    '   AND COALESCE(ATB.ESACTIVO_ATB, ''S'') = ''S'' ' +
    ' GROUP BY ATB.CODIGO_ATB ' +
    ' ORDER BY ORDEN_ATB, NOMBRE_ATB, ATB.CODIGO_ATB';
end;

function TLecturasAtributosPaleta.ListarEntradasCache(
  AConexion: TUniConnection): TArray<TEntradaCacheBasico>;
var
  Consulta: TUniQuery;
  Entrada: TEntradaCacheBasico;
  Lista: TList<TEntradaCacheBasico>;
begin
  Result := nil;
  if AConexion <> nil then
  begin
    Lista := TList<TEntradaCacheBasico>.Create;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT B.ID_VA_ATB, B.CODIGO_ATB, B.NOMBRE_ATB, ' +
        '       B.HEX_ATB, V.AV, V.DESCRIPCION_AV ' +
        '  FROM fza_atributos_basicos B ' +
        '  LEFT JOIN fza_atributos_valores V ON V.ID_ATB_AV = B.ID_ATB ' +
        ' WHERE B.ESACTIVO_ATB = ''S'' ' +
        '   AND B.HEX_ATB IS NOT NULL ' +
        '   AND B.HEX_ATB <> ''''';
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Entrada := Default(TEntradaCacheBasico);
        Entrada.IdVariacion :=
          Consulta.FieldByName('ID_VA_ATB').AsString;
        Entrada.Codigo := Consulta.FieldByName('CODIGO_ATB').AsString;
        Entrada.Nombre := Consulta.FieldByName('NOMBRE_ATB').AsString;
        Entrada.Valor := Consulta.FieldByName('AV').AsString;
        Entrada.Descripcion :=
          Consulta.FieldByName('DESCRIPCION_AV').AsString;
        Entrada.Info.HexColor := Consulta.FieldByName('HEX_ATB').AsString;
        Entrada.Info.Color := HexToColor(Entrada.Info.HexColor);
        Entrada.Info.Nombre := Entrada.Nombre;
        Entrada.Info.EsValido := Entrada.Info.Color <> clNone;
        Lista.Add(Entrada);
        Consulta.Next;
      end;
      Result := Lista.ToArray;
    finally
      FreeAndNil(Consulta);
      FreeAndNil(Lista);
    end;
  end;
end;

function TLecturasAtributosPaleta.ObtenerBasicosArticulo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AIdVariacion: string): TArray<string>;
var
  Consulta: TUniQuery;
  Lista: TList<string>;
begin
  Result := nil;
  if (AConexion <> nil) and (Trim(ACodigoArticulo) <> '') then
  begin
    Lista := TList<string>.Create;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text := SqlBasicosArticuloAtributosPaleta;
      Consulta.ParamByName('va').AsString := AIdVariacion;
      Consulta.ParamByName('art').AsString := Trim(ACodigoArticulo);
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Lista.Add(Consulta.FieldByName('CODIGO_ATB').AsString);
        Consulta.Next;
      end;
      Result := Lista.ToArray;
    finally
      FreeAndNil(Consulta);
      FreeAndNil(Lista);
    end;
  end;
end;

procedure TLecturasAtributosPaleta.CargarMapaArticulo(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  ADestino: TDictionary<string, string>);
var
  Consulta: TUniQuery;
begin
  if ADestino <> nil then
  begin
    ADestino.Clear;
    if (AConexion <> nil) and (Trim(ACodigoArticulo) <> '') then
    begin
      Consulta := TUniQuery.Create(nil);
      try
        Consulta.Connection := AConexion;
        Consulta.SQL.Text :=
          'SELECT DISTINCT ID_ATRIBUTO, NOMBRE_ATRIBUTO ' +
          '  FROM vi_atributos_nombres ' +
          ' WHERE CODIGO_ART_PADRE_ARTVIN = :ART';
        Consulta.ParamByName('ART').AsString := ACodigoArticulo;
        Consulta.Open;
        while not Consulta.Eof do
        begin
          ADestino.AddOrSetValue(
            UpperCase(Trim(Consulta.FieldByName(
              'NOMBRE_ATRIBUTO').AsString)),
            Consulta.FieldByName('ID_ATRIBUTO').AsString);
          Consulta.Next;
        end;
      finally
        FreeAndNil(Consulta);
      end;
    end;
  end;
end;

procedure TLecturasAtributosPaleta.CargarMapaGlobal(
  AConexion: TUniConnection;
  ADestino: TDictionary<string, string>);
var
  Consulta: TUniQuery;
  Nombre: string;
begin
  if ADestino <> nil then
  begin
    ADestino.Clear;
    if AConexion <> nil then
    begin
      Consulta := TUniQuery.Create(nil);
      try
        Consulta.Connection := AConexion;
        Consulta.SQL.Text :=
          'SELECT ID_ATB_VA, COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE_VA ' +
          '  FROM fza_variaciones_atributos';
        Consulta.Open;
        while not Consulta.Eof do
        begin
          Nombre := UpperCase(Trim(
            Consulta.FieldByName('NOMBRE_VA').AsString));
          if Nombre <> '' then
            ADestino.AddOrSetValue(
              Nombre,
              Consulta.FieldByName('ID_ATB_VA').AsString);
          Consulta.Next;
        end;
      finally
        FreeAndNil(Consulta);
      end;
    end;
  end;
end;

function TLecturasAtributosPaleta.ListarPaletaArticulo(
  AConexion: TUniConnection;
  const ACodigoArticulo,
  AIdVariacion: string): TArray<TValorPaletaArticulo>;
var
  Consulta: TUniQuery;
  Lista: TList<TValorPaletaArticulo>;
  Valor: TValorPaletaArticulo;
begin
  Result := nil;
  if (AConexion <> nil) and (Trim(ACodigoArticulo) <> '') then
  begin
    Lista := TList<TValorPaletaArticulo>.Create;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT av.AV, b.NOMBRE_ATB, b.HEX_ATB ' +
        '  FROM fza_articulos_atributos_basicos aab ' +
        '  JOIN fza_atributos_valores av ON av.ID_AV = aab.ID_AV_AAB ' +
        '  JOIN fza_atributos_basicos b ON b.ID_ATB = aab.ID_ATB_AAB ' +
        ' WHERE aab.CODIGO_ART_AAB = :art ' +
        '   AND (:idva = '''' OR av.ID_VA_AV = :idva) ' +
        '   AND b.ESACTIVO_ATB = ''S'' ' +
        '   AND b.HEX_ATB IS NOT NULL ' +
        '   AND b.HEX_ATB <> ''''';
      Consulta.ParamByName('art').AsString := ACodigoArticulo;
      Consulta.ParamByName('idva').AsString := AIdVariacion;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Valor := Default(TValorPaletaArticulo);
        Valor.Valor := Consulta.FieldByName('AV').AsString;
        Valor.Info.HexColor := Consulta.FieldByName('HEX_ATB').AsString;
        Valor.Info.Color := HexToColor(Valor.Info.HexColor);
        Valor.Info.Nombre := Consulta.FieldByName('NOMBRE_ATB').AsString;
        Valor.Info.EsValido := Valor.Info.Color <> clNone;
        Lista.Add(Valor);
        Consulta.Next;
      end;
      Result := Lista.ToArray;
    finally
      FreeAndNil(Consulta);
      FreeAndNil(Lista);
    end;
  end;
end;

function TLecturasAtributosPaleta.ObtenerInfoBasicoArticulo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AIdVariacion, AValor: string;
  out AInfo: TInfoBasico): Boolean;
var
  Consulta: TUniQuery;
begin
  AInfo := Default(TInfoBasico);
  if (AConexion <> nil) and (Trim(ACodigoArticulo) <> '') and
     (Trim(AValor) <> '') then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT b.NOMBRE_ATB, b.HEX_ATB ' +
        '  FROM fza_articulos_atributos_basicos aab ' +
        '  JOIN fza_atributos_valores av ON av.ID_AV = aab.ID_AV_AAB ' +
        '  JOIN fza_atributos_basicos b ON b.ID_ATB = aab.ID_ATB_AAB ' +
        ' WHERE aab.CODIGO_ART_AAB = :art ' +
        '   AND av.AV = :av ' +
        '   AND (:idva = '''' OR av.ID_VA_AV = :idva) ' +
        '   AND b.ESACTIVO_ATB = ''S'' ' +
        '   AND b.HEX_ATB IS NOT NULL ' +
        '   AND b.HEX_ATB <> '''' ' +
        ' LIMIT 1';
      Consulta.ParamByName('art').AsString := ACodigoArticulo;
      Consulta.ParamByName('av').AsString := AValor;
      Consulta.ParamByName('idva').AsString := AIdVariacion;
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        AInfo.HexColor := Consulta.FieldByName('HEX_ATB').AsString;
        AInfo.Color := HexToColor(AInfo.HexColor);
        AInfo.Nombre := Consulta.FieldByName('NOMBRE_ATB').AsString;
        AInfo.EsValido := AInfo.Color <> clNone;
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
  Result := AInfo.EsValido;
end;

initialization
  GLecturas := TLecturasAtributosPaleta.Create;

finalization
  GLecturas := nil;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGuiasGridRepositorio                                  }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de persistencia para las guías de grid.                  }
{******************************************************************************}
unit UniDataGuiasGridRepositorio;

interface

uses
  Uni, inLibGuiasGridPersistenciaIntf;

function CrearPersistenciaGuiasGridUniDAC(
  AConexion: TUniConnection): IPersistenciaGuiasGrid;

implementation

uses
  System.SysUtils, System.Classes, System.Variants,
  Data.DB,
  inLibInformesGuiasCache;

const
  SQL_CAMPOS_TABLA =
    'SELECT COLUMN_NAME FROM information_schema.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :TAB ' +
    'ORDER BY ORDINAL_POSITION';
  SQL_BORRAR_GUIAS =
    'DELETE FROM fza_informes_guias ' +
    'WHERE INFORME_INFGUI = :INF';
  SQL_GUARDAR_VISIBLES =
    'UPDATE fza_informes_guias ' +
    'SET COLUMNAS_VISIBLES_INFGUI = :VIS ' +
    'WHERE INFORME_INFGUI = :INF';

type
  TPersistenciaGuiasGridUniDAC = class(
    TInterfacedObject,
    IPersistenciaGuiasGrid)
  private
    FConexion: TUniConnection;
    procedure Agregar(
      var AValores: TArray<string>;
      const AValor: string);
    procedure ValidarIdentificador(const AValor: string);
    function SepararCampos(const AValor: string): TArray<string>;
    function NormalizarSql(const ASql: string): string;
    function BuscarParametro(
      const AParametros: TArray<TParametroConsultaGuia>;
      const ANombre: string;
      out AValor: Variant): Boolean;
    function LeerCamposConsulta(
      const ASql: string;
      const AParametros: TArray<TParametroConsultaGuia>): TArray<string>;
    function LeerCamposTabla(const ATabla: string): TArray<string>;
    function ConstruirCondicion(
      const AMaestros, ADetalles: string): string;
    function ConstruirSeleccion(
      const ATabla: string;
      const ACamposMaestro: TArray<string>;
      var AResultado: TResultadoEnriquecimientoGuias): string;
    procedure AplicarGuia(
      const AGuia: TInformeGuiaItem;
      const AParametros: TArray<TParametroConsultaGuia>;
      var ASql: string;
      var AResultado: TResultadoEnriquecimientoGuias);
  public
    constructor Create(AConexion: TUniConnection);
    function Enriquecer(
      const ASqlOriginal: string;
      const AParametros: TArray<TParametroConsultaGuia>;
      const AGuias: TArray<TInformeGuiaItem>
    ): TResultadoEnriquecimientoGuias;
    procedure Borrar(const AInforme: string);
    procedure GuardarColumnasVisibles(
      const AInforme, AColumnas: string);
  end;

constructor TPersistenciaGuiasGridUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TPersistenciaGuiasGridUniDAC.Agregar(
  var AValores: TArray<string>;
  const AValor: string);
var
  iIndice: Integer;
begin
  iIndice := Length(AValores);
  SetLength(AValores, iIndice + 1);
  AValores[iIndice] := AValor;
end;

procedure TPersistenciaGuiasGridUniDAC.ValidarIdentificador(
  const AValor: string);
var
  iCaracter: Integer;
  EsValido: Boolean;
begin
  EsValido := AValor <> '';
  iCaracter := 1;
  while EsValido and (iCaracter <= Length(AValor)) do
  begin
    EsValido := CharInSet(
      AValor[iCaracter], ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    Inc(iCaracter);
  end;
  if not EsValido then
    raise EArgumentException.CreateFmt(
      'Identificador de guía no válido: %s', [AValor]);
end;

function TPersistenciaGuiasGridUniDAC.SepararCampos(
  const AValor: string): TArray<string>;
var
  iCampo: Integer;
  oCampos: TStringList;
begin
  SetLength(Result, 0);
  oCampos := TStringList.Create;
  try
    oCampos.StrictDelimiter := True;
    oCampos.Delimiter := ';';
    oCampos.DelimitedText := AValor;
    SetLength(Result, oCampos.Count);
    for iCampo := 0 to oCampos.Count - 1 do
      Result[iCampo] := Trim(oCampos[iCampo]);
  finally
    FreeAndNil(oCampos);
  end;
end;

function TPersistenciaGuiasGridUniDAC.NormalizarSql(
  const ASql: string): string;
begin
  Result := TrimRight(ASql);
  while (Result <> '') and
        (Result[Length(Result)] = ';') do
  begin
    SetLength(Result, Length(Result) - 1);
    Result := TrimRight(Result);
  end;
end;

function TPersistenciaGuiasGridUniDAC.BuscarParametro(
  const AParametros: TArray<TParametroConsultaGuia>;
  const ANombre: string;
  out AValor: Variant): Boolean;
var
  iParametro: Integer;
begin
  Result := False;
  iParametro := 0;
  while not Result and (iParametro < Length(AParametros)) do
  begin
    Result := SameText(AParametros[iParametro].Nombre, ANombre);
    if Result then
      AValor := AParametros[iParametro].Valor;
    Inc(iParametro);
  end;
end;

function TPersistenciaGuiasGridUniDAC.LeerCamposConsulta(
  const ASql: string;
  const AParametros: TArray<TParametroConsultaGuia>): TArray<string>;
var
  iCampo: Integer;
  iParametro: Integer;
  oConsulta: TUniQuery;
  vValor: Variant;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * FROM (' + ASql + ') X_GUIAS WHERE 1 = 0';
    for iParametro := 0 to oConsulta.Params.Count - 1 do
    begin
      if BuscarParametro(
           AParametros,
           oConsulta.Params[iParametro].Name,
           vValor) then
        oConsulta.Params[iParametro].Value := vValor
      else
        oConsulta.Params[iParametro].Clear;
    end;
    oConsulta.Open;
    SetLength(Result, oConsulta.FieldCount);
    for iCampo := 0 to oConsulta.FieldCount - 1 do
      Result[iCampo] := oConsulta.Fields[iCampo].FieldName;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TPersistenciaGuiasGridUniDAC.LeerCamposTabla(
  const ATabla: string): TArray<string>;
var
  iCampo: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CAMPOS_TABLA;
    oConsulta.ParamByName('TAB').AsString := ATabla;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCampo := Length(Result);
      SetLength(Result, iCampo + 1);
      Result[iCampo] :=
        oConsulta.FieldByName('COLUMN_NAME').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TPersistenciaGuiasGridUniDAC.ConstruirCondicion(
  const AMaestros, ADetalles: string): string;
var
  iCampo: Integer;
  iPares: Integer;
  arrMaestros: TArray<string>;
  arrDetalles: TArray<string>;
begin
  Result := '';
  arrMaestros := SepararCampos(AMaestros);
  arrDetalles := SepararCampos(ADetalles);
  iPares := Length(arrMaestros);
  if Length(arrDetalles) < iPares then
    iPares := Length(arrDetalles);
  for iCampo := 0 to iPares - 1 do
  begin
    if (arrMaestros[iCampo] <> '') and
       (arrDetalles[iCampo] <> '') then
    begin
      ValidarIdentificador(arrMaestros[iCampo]);
      ValidarIdentificador(arrDetalles[iCampo]);
      if Result <> '' then
        Result := Result + ' AND ';
      Result := Result + 'EXT_GUIA.' + arrDetalles[iCampo] +
        ' = M_GUIA.' + arrMaestros[iCampo];
    end;
  end;
end;

function TPersistenciaGuiasGridUniDAC.ConstruirSeleccion(
  const ATabla: string;
  const ACamposMaestro: TArray<string>;
  var AResultado: TResultadoEnriquecimientoGuias): string;
var
  iCampo: Integer;
  iSufijo: Integer;
  sAlias: string;
  sCampo: string;
  arrCamposTabla: TArray<string>;
  oCampos: TStringList;
begin
  Result := '';
  oCampos := TStringList.Create;
  try
    oCampos.CaseSensitive := False;
    oCampos.Sorted := True;
    oCampos.Duplicates := dupIgnore;
    for sCampo in ACamposMaestro do
      oCampos.Add(sCampo);
    arrCamposTabla := LeerCamposTabla(ATabla);
    for iCampo := 0 to High(arrCamposTabla) do
    begin
      sCampo := arrCamposTabla[iCampo];
      ValidarIdentificador(sCampo);
      sAlias := sCampo;
      iSufijo := 1;
      while oCampos.IndexOf(sAlias) >= 0 do
      begin
        sAlias := sCampo + IntToStr(iSufijo);
        Inc(iSufijo);
      end;
      oCampos.Add(sAlias);
      Agregar(AResultado.CamposNuevos, sAlias);
      Agregar(AResultado.CamposTabla, sAlias + '=' + ATabla);
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + 'EXT_GUIA.' + sCampo + ' AS ' + sAlias;
    end;
  finally
    FreeAndNil(oCampos);
  end;
end;

procedure TPersistenciaGuiasGridUniDAC.AplicarGuia(
  const AGuia: TInformeGuiaItem;
  const AParametros: TArray<TParametroConsultaGuia>;
  var ASql: string;
  var AResultado: TResultadoEnriquecimientoGuias);
var
  sCondicion: string;
  sSeleccion: string;
  sVisible: string;
  arrCamposMaestro: TArray<string>;
  arrVisibles: TArray<string>;
begin
  if (AGuia.Tabla <> '') and
     (AGuia.MasterFields <> '') and
     (AGuia.DetailFields <> '') and
     (ASql <> '') then
  begin
    ValidarIdentificador(AGuia.Tabla);
    arrCamposMaestro := LeerCamposConsulta(ASql, AParametros);
    sSeleccion := ConstruirSeleccion(
      AGuia.Tabla, arrCamposMaestro, AResultado);
    sCondicion := ConstruirCondicion(
      AGuia.MasterFields, AGuia.DetailFields);
    if (sSeleccion <> '') and (sCondicion <> '') then
    begin
      ASql := 'SELECT M_GUIA.*, ' + sSeleccion + ' FROM (' + ASql +
        ') M_GUIA LEFT JOIN ' + AGuia.Tabla +
        ' EXT_GUIA ON ' + sCondicion;
      AResultado.Exito := True;
      arrVisibles := SepararCampos(AGuia.ColumnasVisibles);
      for sVisible in arrVisibles do
      begin
        if sVisible <> '' then
          Agregar(AResultado.ColumnasVisibles, sVisible);
      end;
    end;
  end;
end;

function TPersistenciaGuiasGridUniDAC.Enriquecer(
  const ASqlOriginal: string;
  const AParametros: TArray<TParametroConsultaGuia>;
  const AGuias: TArray<TInformeGuiaItem>
): TResultadoEnriquecimientoGuias;
var
  oGuia: TInformeGuiaItem;
  sSql: string;
begin
  Result := Default(TResultadoEnriquecimientoGuias);
  sSql := NormalizarSql(ASqlOriginal);
  for oGuia in AGuias do
    AplicarGuia(oGuia, AParametros, sSql, Result);
  if Result.Exito then
    Result.SqlEnriquecido := sSql;
end;

procedure TPersistenciaGuiasGridUniDAC.Borrar(
  const AInforme: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BORRAR_GUIAS;
    oConsulta.ParamByName('INF').AsString := AInforme;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TPersistenciaGuiasGridUniDAC.GuardarColumnasVisibles(
  const AInforme, AColumnas: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_GUARDAR_VISIBLES;
    oConsulta.ParamByName('VIS').AsString := AColumnas;
    oConsulta.ParamByName('INF').AsString := AInforme;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearPersistenciaGuiasGridUniDAC(
  AConexion: TUniConnection): IPersistenciaGuiasGrid;
begin
  Result := TPersistenciaGuiasGridUniDAC.Create(AConexion);
end;

end.

{******************************************************************************}
{  Módulo: UniDataBalanceComplementos                                          }
{  Complementos del resumen de balance: pendientes y coste histórico.          }
{  Autor: Alejandro Laorden Hidalgo. Fecha: 07/11/2026.                        }
{******************************************************************************}
unit UniDataBalanceComplementos;

interface

uses
  Data.DB, Datasnap.DBClient, Uni,
  inLibInformeBalanceSinTallasPersistenciaIntf;

// El llamador posee el dataset devuelto, independiente del original.
function CompletarDatosResumenBalance(AConexion: TUniConnection;
  AOrigen: TDataSet; const ACriterios: TCriteriosInformeBalanceSinTallas):
  TClientDataSet;

implementation

uses
  System.SysUtils, System.Classes, System.DateUtils,
  System.Generics.Collections,
  inLibFamiliasArbol, inLibInformeMultiFiltroPersistenciaIntf,
  UniDataInformeMultiFiltroRepositorio, UniDataBalanceComplementosSql;

function Incluido(const ACsv, ACodigo: string): Boolean;
begin
  Result := (ACsv = '') or
    (Pos(',' + ACodigo + ',', ',' + ACsv + ',') > 0);
end;

function RutaFamilia(const ACodigo: string; const AFamilias: TFamiliasArbol):
  TArray<TFamiliaArbol>;
var
  sCodigo: string;
  oFamilia: TFamiliaArbol;
  i: Integer;
begin
  Result := nil;
  sCodigo := ACodigo;
  // El límite también protege frente a una jerarquía dañada con ciclos.
  for i := 0 to Length(AFamilias) do
    if sCodigo <> '' then
    begin
      oFamilia := Default(TFamiliaArbol);
      for oFamilia in AFamilias do
        if oFamilia.Codigo = sCodigo then
          Break;
      if oFamilia.Codigo = sCodigo then
      begin
        Result := [oFamilia] + Result;
        sCodigo := oFamilia.CodigoPadre;
      end
      else
        sCodigo := '';
    end;
end;

function FamiliaIncluida(const ACsv, ACodigo: string;
  const AFamilias: TFamiliasArbol): Boolean;
var
  oFamilia: TFamiliaArbol;
begin
  Result := Incluido(ACsv, ACodigo);
  for oFamilia in RutaFamilia(ACodigo, AFamilias) do
    Result := Result or Incluido(ACsv, oFamilia.Codigo);
end;

function FamiliaGrupo(const ACodigo: string; ANivel: Integer;
  const AFamilias: TFamiliasArbol): TFamiliaArbol;
var
  oRuta: TArray<TFamiliaArbol>;
  i: Integer;
begin
  Result := Default(TFamiliaArbol);
  Result.Codigo := ACodigo;
  Result.Nombre := ACodigo;
  oRuta := RutaFamilia(ACodigo, AFamilias);
  if Length(oRuta) > 0 then
  begin
    i := High(oRuta);
    if (ANivel > 0) and (ANivel <= Length(oRuta)) then
      i := ANivel - 1;
    Result := oRuta[i];
  end;
end;

procedure CopiarBalance(AOrigen: TDataSet; ADestino: TClientDataSet);
var
  i: Integer;
  oMarca: TBookmark;
begin
  ADestino.FieldDefs.Assign(AOrigen.FieldDefs);
  ADestino.FieldDefs.Add('PTE_RECIBIR_RESUMEN', ftFloat);
  ADestino.FieldDefs.Add('COSTE_SALIDAS_RESUMEN', ftCurrency);
  // FZ-ISSUE-899: nulos salvo en los complementos de un balance entre
  // fechas; el resumen los usa solo cuando vienen informados.
  ADestino.FieldDefs.Add('ENT_UDS_RESUMEN', ftFloat);
  ADestino.FieldDefs.Add('ENT_COSTE_RESUMEN', ftCurrency);
  ADestino.FieldDefs.Add('REG_UDS_RESUMEN', ftFloat);
  ADestino.FieldDefs.Add('REG_COSTE_RESUMEN', ftCurrency);
  for i := 0 to ADestino.FieldDefs.Count - 1 do
    ADestino.FieldDefs[i].Attributes :=
      ADestino.FieldDefs[i].Attributes -
        [Data.DB.faRequired, Data.DB.faReadonly];
  ADestino.CreateDataSet;
  for i := 0 to ADestino.FieldCount - 1 do
  begin
    ADestino.Fields[i].Required := False;
    ADestino.Fields[i].ReadOnly := False;
  end;
  oMarca := AOrigen.Bookmark;
  AOrigen.DisableControls;
  try
    AOrigen.First;
    while not AOrigen.Eof do
    begin
      ADestino.Append;
      for i := 0 to AOrigen.FieldCount - 1 do
        ADestino.Fields[i].Value := AOrigen.Fields[i].Value;
      ADestino.FieldByName('PTE_RECIBIR_RESUMEN').AsFloat := 0;
      ADestino.FieldByName('COSTE_SALIDAS_RESUMEN').AsCurrency := 0;
      ADestino.Post;
      AOrigen.Next;
    end;
  finally
    if AOrigen.BookmarkValid(oMarca) then
      AOrigen.Bookmark := oMarca;
    AOrigen.EnableControls;
  end;
end;

procedure AsignarGrupos(ADatos, AMetrica: TDataSet;
  const ACriterios: TCriteriosInformeBalanceSinTallas;
  const AFamilias: TFamiliasArbol;
  AProveedores: TDictionary<string, string>);
var
  i: Integer;
  sNivel, sCodigo, sNombre: string;
  oFamilia: TFamiliaArbol;
begin
  for i := 1 to 3 do
  begin
    sNivel := '';
    case i of
      1: sNivel := ACriterios.Nivel1;
      2: sNivel := ACriterios.Nivel2;
      3: sNivel := ACriterios.Nivel3;
    end;
    sCodigo := '';
    sNombre := '';
    if sNivel = 'ALM' then
    begin
      sCodigo := AMetrica.FieldByName('CODIGO_ALM').AsString;
      sNombre := 'Almacén: ' + AMetrica.FieldByName('NOMBRE_ALM').AsString;
    end;
    if sNivel = 'PRV' then
    begin
      sCodigo := AMetrica.FieldByName('PROVEEDOR').AsString;
      if not AProveedores.TryGetValue(sCodigo, sNombre) then
        sNombre := sCodigo;
      if sNombre = '' then
        sNombre := '(sin proveedor)';
      sNombre := 'Proveedor: ' + sNombre;
    end;
    if sNivel = 'FAM' then
    begin
      oFamilia := FamiliaGrupo(AMetrica.FieldByName('CODIGO_FAM').AsString,
        ACriterios.NivelFamilia, AFamilias);
      sCodigo := oFamilia.Codigo;
      sNombre := 'Familia: ' + oFamilia.Nombre;
    end;
    if sNivel = 'TMP' then
    begin
      sCodigo := AMetrica.FieldByName('TEMPORADA').AsString;
      sNombre := 'Temporada: ' + sCodigo;
    end;
    ADatos.FieldByName(Format('GRUPO%d_COD', [i])).AsString := sCodigo;
    ADatos.FieldByName(Format('GRUPO%d_ETIQ', [i])).AsString := sNombre;
  end;
end;

procedure IncorporarComplementos(AConexion: TUniConnection;
  ADatos: TClientDataSet;
  const ACriterios: TCriteriosInformeBalanceSinTallas);
var
  oConsulta: TUniQuery;
  oFiltros: IRepositorioInformeMultiFiltro;
  oFamilias: TFamiliasInformeMultiFiltro;
  oProveedores: TDictionary<string, string>;
  oProveedor: TOpcionInformeMultiFiltro;
begin
  oConsulta := TUniQuery.Create(nil);
  oProveedores := TDictionary<string, string>.Create;
  try
    oFiltros := CrearRepositorioInformeMultiFiltroUniDAC(AConexion);
    oFamilias := oFiltros.ListarFamilias;
    for oProveedor in oFiltros.ListarProveedores(opmfArticulos) do
      oProveedores.AddOrSetValue(oProveedor.Codigo, oProveedor.Nombre);
    oConsulta.Connection := AConexion;
    // FZ-ISSUE-941: al agrupar por proveedor, el de cada identidad.
    oConsulta.SQL.Text := SqlComplementosBalance(
      (ACriterios.Nivel1 = 'PRV') or (ACriterios.Nivel2 = 'PRV') or
      (ACriterios.Nivel3 = 'PRV'));
    oConsulta.ParamByName('DESDE').AsDateTime := Trunc(ACriterios.FechaDesde);
    oConsulta.ParamByName('HASTA').AsDateTime :=
      IncDay(Trunc(ACriterios.FechaHasta));
    oConsulta.ParamByName('ALMACENES').AsString := ACriterios.Almacenes;
    oConsulta.ParamByName('PROVEEDORES').AsString := ACriterios.Proveedores;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if Incluido(ACriterios.Articulos,
        oConsulta.FieldByName('CODIGO_ART_ART').AsString) and
        Incluido(ACriterios.Temporadas,
        oConsulta.FieldByName('TEMPORADA').AsString) and
        FamiliaIncluida(ACriterios.Familias,
        oConsulta.FieldByName('CODIGO_FAM').AsString, oFamilias) then
      begin
        ADatos.Append;
        ADatos.FieldByName('BANDA').AsString := 'COMPLEMENTO';
        ADatos.FieldByName('CODIGO_ART_ART').Value :=
          oConsulta.FieldByName('CODIGO_ART_ART').Value;
        ADatos.FieldByName('PTE_RECIBIR_RESUMEN').Value :=
          oConsulta.FieldByName('PENDIENTE').Value;
        ADatos.FieldByName('COSTE_SALIDAS_RESUMEN').Value :=
          oConsulta.FieldByName('COSTE').Value;
        // En acumulados las entradas del balance no tienen periodo: se
        // conservan las del procedimiento, valoradas como hasta ahora.
        if ACriterios.Modo <> 'A' then
        begin
          ADatos.FieldByName('ENT_UDS_RESUMEN').AsFloat :=
            oConsulta.FieldByName('ENT_UDS').AsFloat;
          ADatos.FieldByName('ENT_COSTE_RESUMEN').AsCurrency :=
            oConsulta.FieldByName('ENT_COSTE').AsCurrency;
          ADatos.FieldByName('REG_UDS_RESUMEN').AsFloat :=
            oConsulta.FieldByName('REG_UDS').AsFloat;
          ADatos.FieldByName('REG_COSTE_RESUMEN').AsCurrency :=
            oConsulta.FieldByName('REG_COSTE').AsCurrency;
        end;
        AsignarGrupos(ADatos, oConsulta, ACriterios, oFamilias, oProveedores);
        ADatos.Post;
      end;
      oConsulta.Next;
    end;
    ADatos.First;
  finally
    oProveedores.Free;
    oConsulta.Free;
  end;
end;

function CompletarDatosResumenBalance(AConexion: TUniConnection;
  AOrigen: TDataSet; const ACriterios: TCriteriosInformeBalanceSinTallas):
  TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  try
    CopiarBalance(AOrigen, Result);
    IncorporarComplementos(AConexion, Result, ACriterios);
  except
    Result.Free;
    raise;
  end;
end;

end.

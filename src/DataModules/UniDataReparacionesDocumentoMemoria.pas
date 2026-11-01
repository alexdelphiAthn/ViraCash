{******************************************************************************}
{  Módulo: UniDataReparacionesDocumentoMemoria. Tipo: Persistencia             }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Prepara documentos con el motor fiscal común antes de escribir.}
{******************************************************************************}
unit UniDataReparacionesDocumentoMemoria;

interface

uses
  Uni, Data.DB, Datasnap.DBClient, UniDataReparacionesCircuitoBase;

type
  TDocumentoOrdenNuevo = record
    Orden, Linea: Int64;
    NumeroLinea: Integer;
    Tipo, Serie, Proveedor, Almacen, Referencia, TipoIva: string;
    Importe: Currency;
    Cantidad: Double;
    Fecha: TDateTime;
  end;

  TDocumentoOrdenCreado = record
    Serie, Numero: string;
  end;

  TDocumentoMemoriaOrden = class(TRepositorioCircuitoOrden)
  private
    function CamposTabla(const ATabla: string): string;
  protected
    procedure Inicializar(ADatos: TDataSet);
    function TablaMemoria(const ATabla: string): TClientDataSet;
    procedure InsertarRegistro(const ATabla: string; ADatos: TDataSet);
    procedure CopiarFicha(ADestino: TDataSet;
      const ATabla, ACodigo, ASufijoOrigen, ASufijoDestino: string);
    function Numerar(const AEmpresa, ASerie, ATipo: string): string;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.Classes,
  UniDataValoresAutomaticosRepositorio;

function TDocumentoMemoriaOrden.CamposTabla(const ATabla: string): string;
var
  oConsulta: TUniQuery;
begin
  if (ATabla <> 'fza_albaranes') and
     (ATabla <> 'fza_albaranes_lineas') and
     (ATabla <> 'fza_albaranes_compra') and
     (ATabla <> 'fza_albaranes_compra_lineas') and
     (ATabla <> 'fza_clientes') and (ATabla <> 'fza_proveedores') and
     (ATabla <> 'fza_empresas') then
    raise EArgumentException.Create('ATabla');
  Result := '';
  oConsulta := Consulta('SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=:TABLA ' +
    'AND EXTRA NOT LIKE ''%GENERATED%'' ORDER BY ORDINAL_POSITION');
  try
    oConsulta.ParamByName('TABLA').AsString := ATabla;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + '`' +
        StringReplace(oConsulta.Fields[0].AsString, '`', '``', [rfReplaceAll]) +
        '`';
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDocumentoMemoriaOrden.Inicializar(ADatos: TDataSet);
var
  oCampo: TField;
begin
  ADatos.Append;
  for oCampo in ADatos.Fields do
  begin
    oCampo.Required := False;
    if StartsText('ES', oCampo.FieldName) then
      oCampo.AsString := 'N';
    if StartsText('TOTAL_', oCampo.FieldName) or
       StartsText('PORCENTAJE_', oCampo.FieldName) or
       StartsText('PRECIO_', oCampo.FieldName) or
       StartsText('NUM_ATRIBUTOS_', oCampo.FieldName) or
       StartsText('ID_AC_PIVOT_', oCampo.FieldName) then
      oCampo.AsFloat := 0;
    if StartsText('ATTR', oCampo.FieldName) then
      oCampo.AsString := '';
  end;
  ADatos.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  ADatos.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  ADatos.FieldByName('USUARIO_ALTA').AsString := FUsuario;
  ADatos.FieldByName('USUARIO_MODIF').AsString := FUsuario;
end;

function TDocumentoMemoriaOrden.TablaMemoria(
  const ATabla: string): TClientDataSet;
var
  oConsulta: TUniQuery;
  iCampo: Integer;
begin
  oConsulta := Consulta('SELECT ' + CamposTabla(ATabla) +
    ' FROM ' + ATabla + ' WHERE 1=0');
  Result := TClientDataSet.Create(nil);
  try
    try
      oConsulta.Open;
      Result.FieldDefs.Assign(oConsulta.FieldDefs);
      for iCampo := 0 to Result.FieldDefs.Count - 1 do
        Result.FieldDefs[iCampo].Required := False;
      Result.CreateDataSet;
      Inicializar(Result);
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDocumentoMemoriaOrden.InsertarRegistro(const ATabla: string;
  ADatos: TDataSet);
var
  sCampos, sValores: string;
  oCampo: TField;
  oConsulta: TUniQuery;
begin
  CamposTabla(ATabla);
  sCampos := '';
  sValores := '';
  for oCampo in ADatos.Fields do
    if not oCampo.IsNull then
    begin
      if sCampos <> '' then
      begin
        sCampos := sCampos + ',';
        sValores := sValores + ',';
      end;
      sCampos := sCampos + '`' + oCampo.FieldName + '`';
      sValores := sValores + ':' + oCampo.FieldName;
    end;
  oConsulta := Consulta('INSERT INTO ' + ATabla + ' (' + sCampos +
    ') VALUES (' + sValores + ')');
  try
    for oCampo in ADatos.Fields do
      if not oCampo.IsNull then
        oConsulta.ParamByName(oCampo.FieldName).Value := oCampo.Value;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDocumentoMemoriaOrden.CopiarFicha(ADestino: TDataSet;
  const ATabla, ACodigo, ASufijoOrigen, ASufijoDestino: string);
var
  oConsulta: TUniQuery;
  oCampo, oDestino: TField;
  sNombre, sClave: string;
begin
  sClave := 'CODIGO_' + ASufijoOrigen;
  if ATabla = 'fza_clientes' then
    sClave := 'CODIGO_CLI_CLI';
  if ATabla = 'fza_proveedores' then
    sClave := 'CODIGO_PRV_PRV';
  if ATabla = 'fza_empresas' then
    sClave := 'CODIGO_EMP_EMP';
  oConsulta := Consulta('SELECT ' + CamposTabla(ATabla) + ' FROM ' +
    ATabla + ' WHERE ' + sClave + '=:CODIGO');
  try
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(ATabla + ': ' + ACodigo);
    for oCampo in oConsulta.Fields do
    begin
      sNombre := oCampo.FieldName;
      if EndsText('_' + ASufijoOrigen, sNombre) then
      begin
        Delete(sNombre, Length(sNombre) - Length(ASufijoOrigen),
          Length(ASufijoOrigen) + 1);
        oDestino := ADestino.FindField(sNombre + '_' + ASufijoDestino);
        if oDestino <> nil then
          oDestino.Value := oCampo.Value;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDocumentoMemoriaOrden.Numerar(const AEmpresa,
  ASerie, ATipo: string): string;
var
  oContador: TUniStoredProc;
begin
  oContador := TUniStoredProc.Create(nil);
  try
    oContador.Connection := FConexion;
    oContador.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oContador.Params.CreateParam(ftString, 'pserie', ptInput).
      AsString := ASerie;
    oContador.Params.CreateParam(ftString, 'ptipodoc', ptInput).
      AsString := ATipo;
    oContador.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR',
      ptInput).AsString := AEmpresa;
    oContador.Params.CreateParam(ftString, 'pUSUARIOMODIF',
      ptInput).AsString := FUsuario;
    oContador.Params.CreateParam(ftString, 'pcont', ptOutput);
    EjecutarContadorDocumentoUniDAC(oContador, False, nil);
    Result := oContador.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oContador);
  end;
end;

end.

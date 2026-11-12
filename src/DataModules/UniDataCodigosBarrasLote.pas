{******************************************************************************}
{ Módulo: UniDataCodigosBarrasLote · Persistencia · 12/10/2026 · 1.0.0           }
{ Autor: Alejandro Laorden Hidalgo · SPDX-License-Identifier: MPL-2.0          }
{ EAN interno reutilizable por SKU y lote. FZ-ISSUE-456.                       }
{******************************************************************************}
unit UniDataCodigosBarrasLote;

interface

uses
  Data.DB, Uni, inLibParametrosIntf, inLibEtiquetasLotes;

function AsegurarCodigoBarrasLote(AConexion: TUniConnection;
  const ASku, ALote, AUsuario: string;
  const AParametros: IParametros = nil): string;
procedure GenerarCodigoLoteLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
procedure CompletarCodigosEtiquetasLotes(AConexion: TUniConnection;
  const AUsuario: string; const AParametros: IParametros;
  var ALotes: TLotesEtiquetas);

implementation

uses
  System.SysUtils, inLibTrazabilidad, inLibEAN13,
  inLibArticulosCodigosBarras, UniDataArticulosCodigosBarrasRepositorio;

resourcestring
  SErrorIdentidadCodigoLote = 'El código requiere un SKU y un lote válido.';

function BloquearSkuTrazable(AConsulta: TUniQuery;
  const ASku: string; const AParametros: IParametros): Boolean;
var
  Modo: TModoTrazabilidad;
  Activacion: TActivacionTrazabilidad;
begin
  // La fila del SKU existe antes del primer código. Serializa dos altas
  // simultáneas del mismo lote, sin añadir unicidad a los códigos externos.
  AConsulta.SQL.Text :=
    'SELECT A.TIPO_TRAZABILIDAD_ART FROM fza_articulos_skus S ' +
    'JOIN fza_articulos A ON A.CODIGO_ART_ART = S.CODIGO_ART_SKU ' +
    'WHERE S.CODIGO_UNIDAD_SKU = :SKU FOR UPDATE';
  AConsulta.ParamByName('SKU').AsString := ASku;
  AConsulta.Open;
  Result := False;
  if not AConsulta.Eof then
  begin
    Modo := ModoDesdeCadena(
      AConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString);
    Result := Modo in [mtLote, mtSerie];
    if Result and Assigned(AParametros) then
    begin
      Activacion := TActivacionTrazabilidad.Leer(AParametros);
      Result := Activacion.ModoActivo(Modo);
    end;
  end;
  AConsulta.Close;
end;

function BuscarCodigoLote(AConsulta: TUniQuery;
  const ASku, ALote: string): string;
begin
  Result := '';
  // Lectura actual también con REPEATABLE READ después de esperar el SKU.
  AConsulta.SQL.Text :=
    'SELECT CODIGO_BARRAS_CB FROM fza_codigos_barras ' +
    'WHERE CODIGO_UNIDAD_CB = :SKU AND LOTE_CB = :LOTE ' +
    'AND TIPO_CODIGO_CB = ''EAN13'' ' +
    'ORDER BY CODIGO_BARRAS_CB FOR UPDATE';
  AConsulta.ParamByName('SKU').AsString := ASku;
  AConsulta.ParamByName('LOTE').AsString := ALote;
  AConsulta.Open;
  while not AConsulta.Eof and (Result = '') do
  begin
    if EsEAN13Valido(AConsulta.Fields[0].AsString) then
      Result := AConsulta.Fields[0].AsString;
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

procedure InsertarCodigoLote(AConsulta: TUniQuery;
  const ASku, ALote, ACodigo, AUsuario: string);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_codigos_barras (CODIGO_UNIDAD_CB, LOTE_CB, ' +
    'CODIGO_BARRAS_CB, TIPO_CODIGO_CB, ESPRINCIPAL_CB, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:SKU, :LOTE, :CODIGO, ''EAN13'', ''N'', NOW(), :USR, :USR)';
  AConsulta.ParamByName('SKU').AsString := ASku;
  AConsulta.ParamByName('LOTE').AsString := ALote;
  AConsulta.ParamByName('CODIGO').AsString := ACodigo;
  AConsulta.ParamByName('USR').AsString := AUsuario;
  AConsulta.ExecSQL;
end;

function AsegurarCodigoBarrasLote(AConexion: TUniConnection;
  const ASku, ALote, AUsuario: string;
  const AParametros: IParametros): string;
var
  oConsulta: TUniQuery;
  bPropia: Boolean;
  sLote: string;
begin
  Result := '';
  sLote := NormalizarLote(ALote);
  if (Trim(ASku) = '') or (sLote = '') or
     (Length(sLote) > LONGITUD_MAXIMA_LOTE) then
    raise EArgumentException.Create(SErrorIdentidadCodigoLote);
  bPropia := not AConexion.InTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    if bPropia then
      AConexion.StartTransaction;
    try
      if BloquearSkuTrazable(oConsulta, ASku, AParametros) then
      begin
        Result := BuscarCodigoLote(oConsulta, ASku, sLote);
        if Result = '' then
        begin
          Result := CrearCodigoBarrasInterno(
            CrearArticulosCodigosBarrasPersistenciaUniDAC(AConexion),
            AUsuario);
          InsertarCodigoLote(oConsulta, ASku, sLote, Result, AUsuario);
        end;
      end;
      if bPropia then
        AConexion.Commit;
    except
      if bPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure GenerarCodigoLoteLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
var
  oSku, oLote: TField;
begin
  if GeneracionCodigosLoteActiva(AParametros) and Assigned(ALinea) then
  begin
    oSku := ALinea.FindField('CODIGO_UNIDAD_' + ASufijo);
    oLote := ALinea.FindField('LOTE_' + ASufijo);
    if Assigned(oSku) and Assigned(oLote) and
       (Trim(oSku.AsString) <> '') and (Trim(oLote.AsString) <> '') then
      AsegurarCodigoBarrasLote(AConexion, oSku.AsString,
        oLote.AsString, AUsuario, AParametros);
  end;
end;

procedure CompletarCodigosEtiquetasLotes(AConexion: TUniConnection;
  const AUsuario: string; const AParametros: IParametros;
  var ALotes: TLotesEtiquetas);
var
  iLote: Integer;
begin
  if GeneracionCodigosLoteActiva(AParametros) then
    for iLote := 0 to High(ALotes) do
      if (ALotes[iLote].TipoLote = TIPO_CATALOGO_LOTE) or
         (ALotes[iLote].TipoLote = TIPO_CATALOGO_SERIE) then
        ALotes[iLote].CodigoBarras := AsegurarCodigoBarrasLote(AConexion,
          ALotes[iLote].Sku, ALotes[iLote].Lote, AUsuario, AParametros);
end;

end.

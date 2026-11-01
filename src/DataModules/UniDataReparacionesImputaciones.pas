{******************************************************************************}
{  Módulo: UniDataReparacionesImputaciones. Tipo: Persistencia                 }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Imputación parcial por concepto, destinatario y línea real.    }
{******************************************************************************}
unit UniDataReparacionesImputaciones;

interface

uses
  Uni, UniDataReparacionesCircuitoBase;

type
  TImputacionOrden = record
    Orden, Linea: Int64;
    Tipo, Serie, Numero, LineaDocumento: string;
    Importe: Currency;
    Cantidad: Double;
  end;

  TRepositorioImputacionesOrden = class(TRepositorioCircuitoOrden)
  private
    procedure ExigirDocumento(const AImputacion: TImputacionOrden);
    procedure Insertar(const AImputacion: TImputacionOrden);
  public
    function Pendiente(AOrden, ALinea: Int64; const ATipo: string): Currency;
    procedure Imputar(const AImputacion: TImputacionOrden);
    procedure Liberar(AOrden, AImputacion: Int64);
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.Math, Data.DB,
  UniDataReparacionesCobertura,
  UniDataReparacionesAlbaranes, inLibReparacionesCircuito,
  inLibMsgReparacionesCircuito;

function TRepositorioImputacionesOrden.Pendiente(AOrden,
  ALinea: Int64; const ATipo: string): Currency;
var
  oCobertura: TRepositorioCoberturaOrden;
  oConsulta: TUniQuery;
  rReparto: TRepartoConceptoOrden;
begin
  Result := 0;
  oCobertura := TRepositorioCoberturaOrden.Create(FConexion, FUsuario);
  try
    for rReparto in oCobertura.Reparto(AOrden) do
      if rReparto.Linea = ALinea then
      begin
        if ATipo = 'CL' then
          Result := rReparto.Cliente;
        if ATipo = 'AS' then
          Result := rReparto.Aseguradora;
      end;
  finally
    FreeAndNil(oCobertura);
  end;
  oConsulta := Consulta('SELECT COALESCE(SUM(TOTAL_RCI),0) ' +
    'FROM fza_reparaciones_imputaciones WHERE ID_GAR_RCI=:ORDEN ' +
    'AND ID_GARLIN_RCI=:LINEA AND (TIPO_RCI=:TIPO OR ' +
    '(:TIPO=''CL'' AND TIPO_RCI=''TC''))');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
    oConsulta.ParamByName('TIPO').AsString := ATipo;
    oConsulta.Open;
    Result := Result - oConsulta.Fields[0].AsCurrency;
  finally
    FreeAndNil(oConsulta);
  end;
end;

type
  TConfiguracionImputacionOrden = record
    Sufijo, Tabla, Total, Filtro, Cabecera, TablaCabecera,
      Destinatario: string;
  end;

function ConfiguracionImputacion(const ATipo: string):
  TConfiguracionImputacionOrden;
begin
  Result.Sufijo := 'ALBLIN';
  Result.Tabla := 'fza_albaranes_lineas';
  Result.Total := 'ROUND(L.TOTAL_ALBLIN*(1+L.PORCENTAJE_IVA_ALBLIN/100),2)';
  Result.Filtro := '(I.TIPO_RCI IN (''CL'',''AS''))';
  Result.Cabecera := 'ALB';
  Result.TablaCabecera := 'fza_albaranes';
  Result.Destinatario := ' AND D.CODIGO_CLI_ALB=G.CODIGO_CLI_GAR';
  if ATipo = 'AS' then
    Result.Destinatario := ' AND D.CODIGO_CLI_ALB=G.CODIGO_CLI_PAGADOR_GAR';
  if ATipo = 'PR' then
  begin
    Result.Sufijo := 'ALBCLIN';
    Result.Tabla := 'fza_albaranes_compra_lineas';
    Result.Total := 'L.TOTAL_ALBCLIN';
    Result.Filtro := 'I.TIPO_RCI=''PR''';
    Result.Cabecera := 'ALBC';
    Result.TablaCabecera := 'fza_albaranes_compra';
    Result.Destinatario := '';
  end;
  if ATipo = 'TC' then
  begin
    Result.Sufijo := 'FACLIN';
    Result.Tabla := 'fza_facturas_lineas';
    Result.Total := 'ROUND(L.TOTAL_FACLIN*(1+L.PORCENTAJE_IVA_FACLIN/100),2)';
    Result.Filtro := 'I.TIPO_RCI=''TC''';
    Result.Cabecera := 'FAC';
    Result.TablaCabecera := 'fza_facturas';
    Result.Destinatario := ' AND D.CODIGO_CLI_FAC=G.CODIGO_CLI_GAR';
  end;
end;

procedure TRepositorioImputacionesOrden.ExigirDocumento(
  const AImputacion: TImputacionOrden);
var
  oConsulta: TUniQuery;
  sSufijo, sTabla, sTotal, sFiltro, sCabecera, sTablaCabecera,
    sDestinatario: string;
  rConfig: TConfiguracionImputacionOrden;
begin
  rConfig := ConfiguracionImputacion(AImputacion.Tipo);
  sSufijo := rConfig.Sufijo;
  sTabla := rConfig.Tabla;
  sTotal := rConfig.Total;
  sFiltro := rConfig.Filtro;
  sCabecera := rConfig.Cabecera;
  sTablaCabecera := rConfig.TablaCabecera;
  sDestinatario := rConfig.Destinatario;
  oConsulta := Consulta('SELECT ' + sTotal + ' AS TOTAL, ' +
    '(SELECT COALESCE(SUM(I.TOTAL_RCI),0) ' +
    'FROM fza_reparaciones_imputaciones I WHERE I.SERIE_RCI=:SERIE ' +
    'AND I.NUMERO_RCI=:NUMERO AND I.LINEA_RCI=:LINEA AND ' + sFiltro +
    ') AS IMPUTADO FROM ' + sTabla + ' L JOIN ' + sTablaCabecera +
    ' D ON D.SERIE_' + sCabecera + '=L.SERIE_' + sCabecera + '_' +
    sSufijo + ' AND D.NUMERO_' + sCabecera + '=L.NUMERO_' + sCabecera +
    '_' + sSufijo + ' JOIN fza_garantias_reclamaciones G ' +
    'ON G.ID_GAR=:ORDEN JOIN fza_almacenes O ' +
    'ON O.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR WHERE D.CODIGO_EMP_' +
    sCabecera + '=O.CODIGO_EMP_ALM AND L.SERIE_' +
    sCabecera + '_' + sSufijo +
    '=:SERIE AND L.NUMERO_' +
    sCabecera + '_' + sSufijo +
    '=:NUMERO AND L.LINEA_' + sSufijo + '=:LINEA ' + sDestinatario +
    ' FOR UPDATE');
  try
    oConsulta.ParamByName('SERIE').AsString := AImputacion.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AImputacion.Numero;
    oConsulta.ParamByName('LINEA').AsString := AImputacion.LineaDocumento;
    oConsulta.ParamByName('ORDEN').AsLargeInt := AImputacion.Orden;
    oConsulta.Open;
    if oConsulta.IsEmpty or (AImputacion.Importe >
       oConsulta.FieldByName('TOTAL').AsCurrency -
       oConsulta.FieldByName('IMPUTADO').AsCurrency + 0.001) then
      raise EArgumentException.Create(SCircuitoRepartoInvalido);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioImputacionesOrden.Insertar(
  const AImputacion: TImputacionOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_imputaciones ' +
    '(ID_GAR_RCI,ID_GARLIN_RCI,TIPO_RCI,SERIE_RCI,NUMERO_RCI,LINEA_RCI,' +
    'TOTAL_RCI,CANTIDAD_RCI,USUARIO_ALTA) VALUES ' +
    '(:ORDEN,:LINEA,:TIPO,:SERIE,:NUMERO,:LINEA_DOC,' +
    ':TOTAL,:CANTIDAD,:USUARIO)');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AImputacion.Orden;
    oConsulta.ParamByName('LINEA').AsLargeInt := AImputacion.Linea;
    oConsulta.ParamByName('TIPO').AsString := AImputacion.Tipo;
    oConsulta.ParamByName('SERIE').AsString := AImputacion.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AImputacion.Numero;
    oConsulta.ParamByName('LINEA_DOC').AsString := AImputacion.LineaDocumento;
    oConsulta.ParamByName('TOTAL').AsCurrency := AImputacion.Importe;
    oConsulta.ParamByName('CANTIDAD').AsFloat := AImputacion.Cantidad;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioImputacionesOrden.Imputar(
  const AImputacion: TImputacionOrden);
begin
  if (AImputacion.Importe <= 0) or (AImputacion.Cantidad < 0) or
     ((AImputacion.Tipo <> 'CL') and (AImputacion.Tipo <> 'AS') and
      (AImputacion.Tipo <> 'PR') and (AImputacion.Tipo <> 'TC')) then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  Transaccion(
    procedure
    var
      oLinea: TUniQuery;
      oVinculos: TDatosAlbaranesOrden;
    begin
      oLinea := BloquearLinea(AImputacion.Orden, AImputacion.Linea, '', False);
      oVinculos := TDatosAlbaranesOrden.CreateDatos(nil, FConexion, FUsuario);
      try
        if (AImputacion.Tipo <> 'PR') and
           (AImputacion.Importe > Pendiente(AImputacion.Orden,
            AImputacion.Linea, IfThen(AImputacion.Tipo='TC',
              'CL',AImputacion.Tipo)) + 0.001) then
          raise EArgumentException.Create(SCircuitoRepartoInvalido);
        ExigirDocumento(AImputacion);
        if AImputacion.Tipo <> 'TC' then
          oVinculos.Vincular(AImputacion.Orden, AImputacion.Tipo = 'PR',
            AImputacion.Serie, AImputacion.Numero);
        Insertar(AImputacion);
        Historial(AImputacion.Orden, AImputacion.Linea, 'IMPUTACION',
          Format('%s %s/%s/%s: %g', [AImputacion.Tipo, AImputacion.Serie,
           AImputacion.Numero, AImputacion.LineaDocumento,
           AImputacion.Importe]));
      finally
        FreeAndNil(oVinculos);
        FreeAndNil(oLinea);
      end;
    end);
end;

procedure TRepositorioImputacionesOrden.Liberar(AOrden,
  AImputacion: Int64);
begin
  Transaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      BloquearOrden(AOrden, False);
      oConsulta := Consulta('DELETE I FROM fza_reparaciones_imputaciones I ' +
        'LEFT JOIN fza_albaranes_lineas V ON I.TIPO_RCI IN (''CL'',''AS'') ' +
        'AND V.SERIE_ALB_ALBLIN=I.SERIE_RCI ' +
        'AND V.NUMERO_ALB_ALBLIN=I.NUMERO_RCI AND V.LINEA_ALBLIN=I.LINEA_RCI ' +
        'LEFT JOIN fza_albaranes_compra_lineas C ON I.TIPO_RCI=''PR'' ' +
        'AND C.SERIE_ALBC_ALBCLIN=I.SERIE_RCI ' +
        'AND C.NUMERO_ALBC_ALBCLIN=I.NUMERO_RCI ' +
        'AND C.LINEA_ALBCLIN=I.LINEA_RCI WHERE I.ID_RCI=:ID ' +
        'AND I.ID_GAR_RCI=:ORDEN AND I.TIPO_RCI<>''TC'' ' +
        'AND COALESCE(V.ESFACTURADA_ALBLIN,''N'')<>''S'' ' +
        'AND COALESCE(V.NUMERO_FAC_ALBLIN,'''')='''' ' +
        'AND COALESCE(C.ESFACTURADA_ALBCLIN,''N'')<>''S'' ' +
        'AND COALESCE(C.NUMERO_FAC_ALBCLIN,'''')=''''');
      try
        oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
        oConsulta.ParamByName('ID').AsLargeInt := AImputacion;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> 1 then
          raise EArgumentException.Create(SCircuitoDocumentado);
        Historial(AOrden, 0, 'LIBERAR_IMPUTACION', IntToStr(AImputacion));
      finally
        FreeAndNil(oConsulta);
      end;
    end);
end;

end.

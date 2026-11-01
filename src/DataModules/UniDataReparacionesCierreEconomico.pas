{******************************************************************************}
{  Módulo: UniDataReparacionesCierreEconomico. Tipo: Persistencia              }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Verifica documentación, facturación y cobros antes del cierre. }
{******************************************************************************}
unit UniDataReparacionesCierreEconomico;

interface

uses
  Uni, UniDataReparacionesCircuitoBase;

type
  TRepositorioCierreEconomicoOrden = class(TRepositorioCircuitoOrden)
  private
    procedure ExigirRepartoDocumentado(AOrden: Int64);
    procedure ExigirFacturasSaldadas(AOrden: Int64);
  public
    procedure Cerrar(AOrden: Int64);
    function ImporteCliente(AOrden: Int64): Currency;
    function SaldoCliente(AOrden: Int64): Currency;
    function TieneDocumentosCliente(AOrden: Int64): Boolean;
  end;

implementation

uses
  System.SysUtils, Data.DB, UniDataReparacionesCobertura,
  UniDataReparacionesImputaciones, inLibReparacionesCircuito,
  inLibMsgReparacionesCircuito;

function TRepositorioCierreEconomicoOrden.ImporteCliente(
  AOrden: Int64): Currency;
var
  oCobertura: TRepositorioCoberturaOrden;
  rReparto: TRepartoConceptoOrden;
begin
  Result := 0;
  oCobertura := TRepositorioCoberturaOrden.Create(FConexion, FUsuario);
  try
    for rReparto in oCobertura.Reparto(AOrden) do
      Result := Result + rReparto.Cliente;
  finally
    FreeAndNil(oCobertura);
  end;
end;

function TRepositorioCierreEconomicoOrden.TieneDocumentosCliente(
  AOrden: Int64): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM fza_reparaciones_imputaciones ' +
    'WHERE ID_GAR_RCI=:ORDEN AND TIPO_RCI IN (''CL'',''TC'') ' +
    'UNION ALL SELECT 1 FROM fza_reparaciones_albaranes V ' +
    'JOIN fza_albaranes D ON D.SERIE_ALB=V.SERIE_GARALB ' +
    'AND D.NUMERO_ALB=V.NUMERO_GARALB ' +
    'JOIN fza_garantias_reclamaciones G ON G.ID_GAR=V.ID_GAR_GARALB ' +
    'WHERE G.ID_GAR=:ORDEN AND V.TIPO_GARALB=''CL'' ' +
    'AND D.CODIGO_CLI_ALB=G.CODIGO_CLI_GAR LIMIT 1');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCierreEconomicoOrden.SaldoCliente(
  AOrden: Int64): Currency;
var
  oConsulta: TUniQuery;
begin
  Result := ImporteCliente(AOrden);
  oConsulta := Consulta('SELECT COALESCE(SUM(LEAST(I.TOTAL_RCI,' +
    'I.TOTAL_RCI*LEAST(1,GREATEST(' +
    'COALESCE((SELECT SUM(P.IMPORTE_FACPAG) FROM fza_facturas_pagos P ' +
    'WHERE P.SERIE_FAC_FACPAG=F.SERIE_FAC ' +
    'AND P.NUMERO_FAC_FACPAG=F.NUMERO_FAC),0),' +
    'COALESCE((SELECT SUM(IF(E.ESTADO_EFV=''CONCILIADO'',E.IMPORTE_EFV,' +
    'E.IMPORTE_COBRADO_EFV)) FROM fza_efectos_venta E ' +
    'WHERE E.SERIE_FAC_EFV=F.SERIE_FAC ' +
    'AND E.NUMERO_FAC_EFV=F.NUMERO_FAC),0))/' +
    'NULLIF(F.TOTAL_LIQUIDO_FAC,0)))),0) AS COBRADO ' +
    'FROM fza_reparaciones_imputaciones I ' +
    'LEFT JOIN fza_albaranes_lineas L ON I.TIPO_RCI=''CL'' ' +
    'AND L.SERIE_ALB_ALBLIN=I.SERIE_RCI ' +
    'AND L.NUMERO_ALB_ALBLIN=I.NUMERO_RCI AND L.LINEA_ALBLIN=I.LINEA_RCI ' +
    'LEFT JOIN fza_facturas F ' +
    'ON F.SERIE_FAC=IF(I.TIPO_RCI=''TC'',I.SERIE_RCI,L.SERIE_FAC_ALBLIN) ' +
    'AND F.NUMERO_FAC=IF(I.TIPO_RCI=''TC'',I.NUMERO_RCI,L.NUMERO_FAC_ALBLIN) ' +
    'WHERE I.ID_GAR_RCI=:ORDEN AND I.TIPO_RCI IN (''CL'',''TC'')');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    Result := Result - oConsulta.Fields[0].AsCurrency;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCierreEconomicoOrden.ExigirRepartoDocumentado(
  AOrden: Int64);
var
  oCobertura: TRepositorioCoberturaOrden;
  oImputaciones: TRepositorioImputacionesOrden;
  rReparto: TRepartoConceptoOrden;
begin
  oCobertura := TRepositorioCoberturaOrden.Create(FConexion, FUsuario);
  oImputaciones := TRepositorioImputacionesOrden.Create(FConexion, FUsuario);
  try
    for rReparto in oCobertura.Reparto(AOrden) do
      if (rReparto.Pendiente > 0) or
         (oImputaciones.Pendiente(AOrden,rReparto.Linea,'CL') > 0) or
         (oImputaciones.Pendiente(AOrden,rReparto.Linea,'AS') > 0) then
        raise EArgumentException.Create(SCircuitoEconomicoPendiente);
  finally
    FreeAndNil(oImputaciones);
    FreeAndNil(oCobertura);
  end;
end;

procedure TRepositorioCierreEconomicoOrden.ExigirFacturasSaldadas(
  AOrden: Int64);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM fza_reparaciones_imputaciones I ' +
    'LEFT JOIN fza_albaranes_lineas L ON L.SERIE_ALB_ALBLIN=I.SERIE_RCI ' +
    'AND L.NUMERO_ALB_ALBLIN=I.NUMERO_RCI AND L.LINEA_ALBLIN=I.LINEA_RCI ' +
    'LEFT JOIN fza_facturas F ON F.SERIE_FAC=L.SERIE_FAC_ALBLIN ' +
    'AND F.NUMERO_FAC=L.NUMERO_FAC_ALBLIN ' +
    'WHERE I.ID_GAR_RCI=:ORDEN AND I.TIPO_RCI IN (''CL'',''AS'') AND ' +
    '(COALESCE(L.ESFACTURADA_ALBLIN,''N'')<>''S'' OR F.NUMERO_FAC IS NULL ' +
    'OR (F.TOTAL_LIQUIDO_FAC>0 AND NOT EXISTS (' +
    'SELECT 1 FROM fza_efectos_venta E WHERE E.SERIE_FAC_EFV=F.SERIE_FAC ' +
    'AND E.NUMERO_FAC_EFV=F.NUMERO_FAC) AND COALESCE((' +
    'SELECT SUM(P.IMPORTE_FACPAG) FROM fza_facturas_pagos P ' +
    'WHERE P.SERIE_FAC_FACPAG=F.SERIE_FAC ' +
    'AND P.NUMERO_FAC_FACPAG=F.NUMERO_FAC),0) ' +
    '<F.TOTAL_LIQUIDO_FAC-0.001) OR EXISTS (' +
    'SELECT 1 FROM fza_efectos_venta E WHERE E.SERIE_FAC_EFV=F.SERIE_FAC ' +
    'AND E.NUMERO_FAC_EFV=F.NUMERO_FAC ' +
    'AND (COALESCE(E.IMPORTE_PENDIENTE_EFV,E.IMPORTE_EFV)>0.001 ' +
    'OR E.ESTADO_EFV NOT IN (''COBRADO'',''CONCILIADO'')))) UNION ALL ' +
    'SELECT 1 FROM fza_reparaciones_imputaciones I ' +
    'LEFT JOIN fza_albaranes_compra_lineas L ' +
    'ON L.SERIE_ALBC_ALBCLIN=I.SERIE_RCI ' +
    'AND L.NUMERO_ALBC_ALBCLIN=I.NUMERO_RCI ' +
    'AND L.LINEA_ALBCLIN=I.LINEA_RCI LEFT JOIN fza_facturas_compra F ' +
    'ON F.SERIE_FACC=L.SERIE_FAC_ALBCLIN ' +
    'AND F.NUMERO_FACC=L.NUMERO_FAC_ALBCLIN ' +
    'WHERE I.ID_GAR_RCI=:ORDEN AND I.TIPO_RCI=''PR'' AND ' +
    '(COALESCE(L.ESFACTURADA_ALBCLIN,''N'')<>''S'' ' +
    'OR F.NUMERO_FACC IS NULL OR (F.ESTADO_FACC<>''PAGADA'' AND ' +
    '(NOT EXISTS (SELECT 1 FROM fza_efectos_compra E ' +
    'WHERE E.SERIE_FACC_EFEC=F.SERIE_FACC ' +
    'AND E.NUMERO_FACC_EFEC=F.NUMERO_FACC) OR EXISTS (' +
    'SELECT 1 FROM fza_efectos_compra E ' +
    'WHERE E.SERIE_FACC_EFEC=F.SERIE_FACC ' +
    'AND E.NUMERO_FACC_EFEC=F.NUMERO_FACC ' +
    'AND (E.IMPORTE_PENDIENTE_EFEC>0.001 OR ' +
    'E.ESTADO_EFEC NOT IN (''PAGADO'',''CONCILIADO'')))))) LIMIT 1');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoEconomicoPendiente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCierreEconomicoOrden.Cerrar(AOrden: Int64);
begin
  Transaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      BloquearOrden(AOrden, False);
      ExigirRepartoDocumentado(AOrden);
      ExigirFacturasSaldadas(AOrden);
      if SaldoCliente(AOrden) > 0.001 then
        raise EArgumentException.Create(SCircuitoEconomicoPendiente);
      oConsulta := Consulta('UPDATE fza_reparaciones_acuerdos ' +
        'SET ESCIERRE_ECONOMICO_RAC=''S'',INSTANTE_MODIF=NOW(),' +
        'USUARIO_MODIF=:USUARIO WHERE ID_GAR_RAC=:ORDEN');
      try
        oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> 1 then
          raise EArgumentException.Create(SCircuitoConflicto);
        Historial(AOrden,0,'COMPROBAR_CIERRE_ECONOMICO', '');
      finally
        FreeAndNil(oConsulta);
      end;
    end);
end;

end.

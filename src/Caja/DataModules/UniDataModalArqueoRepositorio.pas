{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataModalArqueoRepositorio                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de los resumenes y validaciones del modal de arqueo. }
{******************************************************************************}
unit UniDataModalArqueoRepositorio;

interface

uses
  Uni, inLibModalArqueoPersistenciaIntf;

function CrearRepositorioModalArqueoUniDAC(
  AConexion: TUniConnection): IRepositorioModalArqueo;

implementation

uses
  System.SysUtils, Data.DB, UniDataRectificativasSql,
  UniDataArqueoRepositorio;

type
  TResultadoModalArqueoUniDAC = class(
    TInterfacedObject,
    IResultadoModalArqueo)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioModalArqueoUniDAC = class(
    TInterfacedObject,
    IRepositorioModalArqueo)
  private
    FConexion: TUniConnection;
    function EjecutarResumen(
      const ASql: string;
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarResumenEmpleados(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenFormasPago(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenPropiedades(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenIva(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function BuscarNombreVendedor(
      const ACodigo: string): string;
    function ExisteArqueoCerrado(
      const ASolicitud: TSolicitudResumenModalArqueo): Boolean;
    function UltimoCierreEnRango(
      const ASolicitud: TSolicitudResumenModalArqueo;
      out AFechaHasta: TDateTime): Boolean;
    function OperacionesSinCerrarAntes(
      const ASolicitud: TSolicitudResumenModalArqueo;
      out AUltimoCierre: TDateTime;
      out AOperaciones: Integer): Boolean;
  end;

constructor TResultadoModalArqueoUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoModalArqueoUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoModalArqueoUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioModalArqueoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioModalArqueoUniDAC.EjecutarResumen(
  const ASql: string;
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('pEMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('pALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('pCAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('pFDESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('pFHASTA').AsDateTime := ASolicitud.FechaHasta;
    oConsulta.Open;
    Result := TResultadoModalArqueoUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioModalArqueoUniDAC.ConsultarResumenEmpleados(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  // FZ-ISSUE-407: neto con las devoluciones (DV) restadas y unidades
  // reales de las líneas, para que cuadre con la pestaña Arqueo.
  Result := EjecutarResumen(
    ' SELECT ' +
    '   COALESCE(e.DIMINUTIVO_TICKET_EMPL, ' +
    '            o.CODIGO_EMPLEADO_OPCAJA, ''?'') AS EMPLEADO, ' +
    '   COALESCE(SUM((SELECT SUM(l.CANTIDAD_FACLIN) ' +
    '     FROM fza_facturas_lineas l ' +
    '    WHERE l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    '      AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    '      AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    '      AND l.NUMERO_OPERACION_FACLIN = ' +
    '          o.NUMERO_OPERACION_OPCAJA)), 0) AS UDS, ' +
    '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0) AS NETO ' +
    '   FROM fza_caja_operaciones o ' +
    '   LEFT JOIN fza_empleados e ' +
    '     ON e.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'') ' +
    '    AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    '    AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    '    AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    '    AND (o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'OR COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''') ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''' ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    '  GROUP BY o.CODIGO_EMPLEADO_OPCAJA, ' +
    '           e.DIMINUTIVO_TICKET_EMPL ' +
    '  ORDER BY o.CODIGO_EMPLEADO_OPCAJA',
    ASolicitud);
end;

function TRepositorioModalArqueoUniDAC.ConsultarResumenFormasPago(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := EjecutarResumen(
    ' SELECT p.CODIGO_FP_CFP AS FP, ' +
    '        COUNT(*) AS UDS, ' +
    '        COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO - ' +
    '          p.IMPORTE_CAMBIO_PAGO), 0) AS NETO ' +
    '   FROM fza_caja_pagos p ' +
    '  WHERE p.CODIGO_EMP_PAGO = :pEMPRESA ' +
    '    AND p.CODIGO_ALM_PAGO = :pALMACEN ' +
    '    AND p.CODIGO_CAJA_PAGO = :pCAJA ' +
    '    AND EXISTS (SELECT 1 FROM fza_caja_operaciones o ' +
    '  WHERE o.CODIGO_EMP_OPCAJA = p.CODIGO_EMP_PAGO ' +
    '    AND o.CODIGO_ALM_OPCAJA = p.CODIGO_ALM_PAGO ' +
    '    AND o.CODIGO_CAJA_OPCAJA = p.CODIGO_CAJA_PAGO ' +
    '    AND o.NUMERO_OPERACION_OPCAJA = ' +
    '        p.NUMERO_OPERACION_PAGO ' +
    '    AND (o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'OR COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''') ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''' ' +
    // FZ-ISSUE-407: la entrada de cambio y los gastos de caja no son
    // cobros de ventas (mismo criterio que la pestaña Arqueo, 346).
    '    AND o.TIPO_OPERACION_OPCAJA NOT IN (''EC'', ''GC'') ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    ') GROUP BY p.CODIGO_FP_CFP ' +
    '  ORDER BY p.CODIGO_FP_CFP',
    ASolicitud);
end;

function TRepositorioModalArqueoUniDAC.ConsultarResumenPropiedades(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := EjecutarResumen(
    ' SELECT ap.CODIGO_PROP_ARTPROP AS PROP, ' +
    '        COALESCE(pv.PV, ap.VALOR_LIBRE_ARTPROP, ''?'') AS VALOR, ' +
    '        COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS UDS, ' +
    '        COALESCE(SUM(l.TOTAL_FACLIN), 0) AS NETO ' +
    '   FROM fza_caja_operaciones o ' +
    '   JOIN fza_facturas_lineas l ' +
    '     ON l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    '    AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    '    AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    '    AND l.NUMERO_OPERACION_FACLIN = ' +
    '        o.NUMERO_OPERACION_OPCAJA ' +
    '   JOIN fza_articulos_propiedades ap ' +
    '     ON ap.CODIGO_ART_ART = l.CODIGO_ART_FACLIN ' +
    '   LEFT JOIN fza_propiedades_valores pv ' +
    '     ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'') ' +
    '    AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    '    AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    '    AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    '    AND (o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'OR COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''') ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''' ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    '  GROUP BY ap.CODIGO_PROP_ARTPROP, VALOR ' +
    '  ORDER BY ap.CODIGO_PROP_ARTPROP, VALOR',
    ASolicitud);
end;

function TRepositorioModalArqueoUniDAC.ConsultarResumenIva(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := EjecutarResumen(
    ' SELECT t.ORD, t.TIPO, ' +
    '        MAX(CASE t.ORD ' +
    '              WHEN 1 THEN f.PORCENTAJE_IVAN_FAC ' +
    '              WHEN 2 THEN f.PORCENTAJE_IVAR_FAC ' +
    '              WHEN 3 THEN f.PORCENTAJE_IVAS_FAC ' +
    '              ELSE f.PORCENTAJE_IVAE_FAC END) AS PORC_IVA, ' +
    '        COALESCE(SUM(CASE t.ORD ' +
    '              WHEN 1 THEN f.TOTAL_BASEI_IVAN_FAC ' +
    '              WHEN 2 THEN f.TOTAL_BASEI_IVAR_FAC ' +
    '              WHEN 3 THEN f.TOTAL_BASEI_IVAS_FAC ' +
    '              ELSE f.TOTAL_BASEI_IVAE_FAC END), 0) AS BASE, ' +
    '        COALESCE(SUM(CASE t.ORD ' +
    '              WHEN 1 THEN f.TOTAL_IVAN_FAC ' +
    '              WHEN 2 THEN f.TOTAL_IVAR_FAC ' +
    '              WHEN 3 THEN f.TOTAL_IVAS_FAC ' +
    '              ELSE f.TOTAL_IVAE_FAC END), 0) AS CUOTA_IVA, ' +
    '        MAX(CASE t.ORD ' +
    '              WHEN 1 THEN f.PORCENTAJE_REN_FAC ' +
    '              WHEN 2 THEN f.PORCENTAJE_RER_FAC ' +
    '              WHEN 3 THEN f.PORCENTAJE_RES_FAC ' +
    '              ELSE f.PORCENTAJE_REE_FAC END) AS PORC_RE, ' +
    '        COALESCE(SUM(CASE t.ORD ' +
    '              WHEN 1 THEN f.TOTAL_REN_FAC ' +
    '              WHEN 2 THEN f.TOTAL_RER_FAC ' +
    '              WHEN 3 THEN f.TOTAL_RES_FAC ' +
    '              ELSE f.TOTAL_REE_FAC END), 0) AS CUOTA_RE, ' +
    '        COALESCE(SUM(CASE t.ORD ' +
    '              WHEN 1 THEN COALESCE(f.TOTAL_BASEI_IVAN_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_IVAN_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_REN_FAC, 0) ' +
    '              WHEN 2 THEN COALESCE(f.TOTAL_BASEI_IVAR_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_IVAR_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_RER_FAC, 0) ' +
    '              WHEN 3 THEN COALESCE(f.TOTAL_BASEI_IVAS_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_IVAS_FAC, 0) + ' +
    '                          COALESCE(f.TOTAL_RES_FAC, 0) ' +
    '              ELSE COALESCE(f.TOTAL_BASEI_IVAE_FAC, 0) + ' +
    '                   COALESCE(f.TOTAL_IVAE_FAC, 0) + ' +
    '                   COALESCE(f.TOTAL_REE_FAC, 0) END), 0) ' +
    '          AS BASE_IVAS ' +
    '   FROM ( ' +
    '     SELECT DISTINCT f.SERIE_FAC, f.NUMERO_FAC, ' +
    '            f.PORCENTAJE_IVAN_FAC, f.TOTAL_BASEI_IVAN_FAC, ' +
    '            f.TOTAL_IVAN_FAC, f.PORCENTAJE_REN_FAC, ' +
    '            f.TOTAL_REN_FAC, f.PORCENTAJE_IVAR_FAC, ' +
    '            f.TOTAL_BASEI_IVAR_FAC, f.TOTAL_IVAR_FAC, ' +
    '            f.PORCENTAJE_RER_FAC, f.TOTAL_RER_FAC, ' +
    '            f.PORCENTAJE_IVAS_FAC, f.TOTAL_BASEI_IVAS_FAC, ' +
    '            f.TOTAL_IVAS_FAC, f.PORCENTAJE_RES_FAC, ' +
    '            f.TOTAL_RES_FAC, f.PORCENTAJE_IVAE_FAC, ' +
    '            f.TOTAL_BASEI_IVAE_FAC, f.TOTAL_IVAE_FAC, ' +
    '            f.PORCENTAJE_REE_FAC, f.TOTAL_REE_FAC ' +
    '       FROM fza_caja_operaciones o ' +
    '       JOIN fza_facturas f ' +
    '         ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA ' +
    '        AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA ' +
    '        AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA ' +
    '        AND f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
    '        AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA ' +
    '      WHERE o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    '        AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    '        AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    '        AND (o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'OR COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''') ' +
    '        AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND COALESCE(o.CODIGO_ARQUEO_OPCAJA, '''') = '''' ' +
    '        AND f.TIPO_FAC IN ' +
    '            (''SIMPLIFICADA'', ''RECTIFICATIVA'') ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    '   ) f ' +
    '   CROSS JOIN ( ' +
    '     SELECT 1 AS ORD, ''N'' AS TIPO ' +
    '      UNION ALL SELECT 2, ''R'' ' +
    '      UNION ALL SELECT 3, ''S'' ' +
    '      UNION ALL SELECT 4, ''E'' ' +
    '   ) t ' +
    '  GROUP BY t.ORD, t.TIPO ' +
    '  HAVING BASE <> 0 OR CUOTA_IVA <> 0 OR CUOTA_RE <> 0 ' +
    '  ORDER BY t.ORD',
    ASolicitud);
end;

function TRepositorioModalArqueoUniDAC.BuscarNombreVendedor(
  const ACodigo: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Trim(ACodigo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(NOMBRE_EMPL, DIMINUTIVO_TICKET_EMPL, ' +
        '                CODIGO_EMPL) AS NOMBRE ' +
        '  FROM fza_empleados ' +
        ' WHERE CODIGO_EMPL = :CODIGO ' +
        '   AND ESACTIVO_EMPL = ''S''';
      oConsulta.ParamByName('CODIGO').AsString := Trim(ACodigo);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result := oConsulta.FieldByName('NOMBRE').AsString;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioModalArqueoUniDAC.ExisteArqueoCerrado(
  const ASolicitud: TSolicitudResumenModalArqueo): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
      '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
      '   AND CODIGO_CAJA_ARQ = :CAJA ' +
      '   AND FASE_ARQ = ''CERRADO'' ' +
      '   AND FECHA_DESDE_ARQ <= :FECHA_HASTA ' +
      '   AND FECHA_HASTA_ARQ >= :FECHA_DESDE';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('FECHA_DESDE').AsDateTime :=
      ASolicitud.FechaDesde;
    oConsulta.ParamByName('FECHA_HASTA').AsDateTime :=
      ASolicitud.FechaHasta;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioModalArqueoUniDAC.UltimoCierreEnRango(
  const ASolicitud: TSolicitudResumenModalArqueo;
  out AFechaHasta: TDateTime): Boolean;
var
  oConsulta: TUniQuery;
begin
  AFechaHasta := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT MAX(FECHA_HASTA_ARQ) AS ULTIMO ' +
      '  FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
      '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
      '   AND CODIGO_CAJA_ARQ = :CAJA ' +
      '   AND FASE_ARQ = ''CERRADO'' ' +
      '   AND FECHA_HASTA_ARQ >= :FECHA_DESDE ' +
      '   AND FECHA_HASTA_ARQ <= :FECHA_HASTA';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('FECHA_DESDE').AsDateTime :=
      ASolicitud.FechaDesde;
    oConsulta.ParamByName('FECHA_HASTA').AsDateTime :=
      ASolicitud.FechaHasta;
    oConsulta.Open;
    Result := not oConsulta.FieldByName('ULTIMO').IsNull;
    if Result then
      AFechaHasta := oConsulta.FieldByName('ULTIMO').AsDateTime;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioModalArqueoUniDAC.OperacionesSinCerrarAntes(
  const ASolicitud: TSolicitudResumenModalArqueo;
  out AUltimoCierre: TDateTime;
  out AOperaciones: Integer): Boolean;
var
  bHayCierre: Boolean;
  oConsulta: TUniQuery;
begin
  AUltimoCierre := 0;
  AOperaciones := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT MAX(FECHA_HASTA_ARQ) AS ULTIMO ' +
      '  FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
      '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
      '   AND CODIGO_CAJA_ARQ = :CAJA ' +
      '   AND FASE_ARQ = ''CERRADO'' ' +
      '   AND FECHA_HASTA_ARQ < :FECHA_DESDE';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('FECHA_DESDE').AsDateTime :=
      ASolicitud.FechaDesde;
    oConsulta.Open;
    bHayCierre := not oConsulta.FieldByName('ULTIMO').IsNull;
    if bHayCierre then
    begin
      AUltimoCierre := oConsulta.FieldByName('ULTIMO').AsDateTime;
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA) AS N ' +
        '  FROM fza_caja_operaciones o ' +
        ' WHERE o.CODIGO_EMP_OPCAJA = :EMPRESA ' +
        '   AND o.CODIGO_ALM_OPCAJA = :ALMACEN ' +
        '   AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
        '   AND o.FECHA_OPERACION_OPCAJA > :ULTIMO ' +
        '   AND o.FECHA_OPERACION_OPCAJA < :FECHA_DESDE ' +
        '   AND (o.CODIGO_ARQUEO_OPCAJA IS NULL ' +
        '        OR o.CODIGO_ARQUEO_OPCAJA = '''') ' +
        SQLExcluirVentaRetirada(
          'o.CODIGO_EMP_OPCAJA',
          'o.SERIE_FAC_OPCAJA',
          'o.NUMERO_FAC_OPCAJA');
      oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
      oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
      oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
      oConsulta.ParamByName('ULTIMO').AsDateTime := AUltimoCierre;
      oConsulta.ParamByName('FECHA_DESDE').AsDateTime :=
        ASolicitud.FechaDesde;
      oConsulta.Open;
      AOperaciones := oConsulta.FieldByName('N').AsInteger;
    end;
    Result := bHayCierre and (AOperaciones > 0);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioModalArqueoUniDAC(
  AConexion: TUniConnection): IRepositorioModalArqueo;
begin
  Result := TRepositorioModalArqueoUniDAC.Create(AConexion);
end;

end.

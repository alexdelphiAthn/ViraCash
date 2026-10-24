{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsJson                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC del serializador de una factura y todos sus datos        }
{    asociados para el webservice.                                             }
{******************************************************************************}
unit UniDataVentasWsJson;

interface

uses
  Uni, inLibVentasWsJsonIntf;

function CrearVentasWsJsonUniDAC(
  AConexion: TUniConnection): IVentasWsJson;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.SysUtils, System.JSON, System.Classes,
  System.DateUtils, System.NetEncoding,
  System.Hash, System.IOUtils,
  Data.DB,
  inLibParametrosIntf, inLibViraCashApi, inLibMsgFacturas;

type
  TVentasWsJson = class
  private
    class function ConstruirArray(AConn: TUniConnection;
      const ASql, ASerie, ANumero: string): TJSONArray; static;
    class function ConstruirArrayCierre(AConn: TUniConnection;
      const ASql, AEmpresa, ACodigo: string): TJSONArray; static;
    class function ConstruirCabecera(AConn: TUniConnection;
      const ASerie, ANumero: string): TJSONObject; static;
    class function ConstruirCierre(AConn: TUniConnection;
      const AEmpresa, ACodigo: string): TJSONObject; static;
    class function ConstruirCierreCabecera(AConn: TUniConnection;
      const AEmpresa, ACodigo: string): TJSONObject; static;
    class function ConstruirDocumentos(AConn: TUniConnection;
      AIdCola: Int64): TJSONObject; static;
    class function ConstruirFotos(
      const AParametrosApp: IParametrosAplicacion;
      AConn: TUniConnection;
      const ASerie, ANumero: string): TJSONArray; static;
    class function SqlCierreRecuento: string; static;
    class function SqlCierreResumenTemporadas: string; static;
    class function SqlCierreResumenFamilias: string; static;
    class function SqlCierreResumenProveedores: string; static;
    class function SqlCierreResumenFormasPago: string; static;
    class function SqlCierreResumenEmpleados: string; static;
    class function SqlCierreResumenSeries: string; static;
    class function SqlVentaLineas: string; static;
    class function ConstruirVenta(
      const AParametrosApp: IParametrosAplicacion;
      AConn: TUniConnection;
      AIdCola: Int64;
      const ASerie, ANumero: string): TJSONObject; static;
  public
    class function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AConn: TUniConnection;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string; static;
  end;
  TVentasWsJsonUniDAC = class(TInterfacedObject, IVentasWsJson)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string;
  end;

function LeerCampoBinario(ACampo: TField): TBytes;
var
  oFlujo: TStream;
begin
  SetLength(Result, 0);
  oFlujo := ACampo.DataSet.CreateBlobStream(ACampo, bmRead);
  try
    SetLength(Result, oFlujo.Size);
    if oFlujo.Size > 0 then
      oFlujo.ReadBuffer(Result[0], oFlujo.Size);
  finally
    FreeAndNil(oFlujo);
  end;
end;

function RegistroAJson(ADataSet: TDataSet): TJSONObject; forward;

class function TVentasWsJson.ConstruirArrayCierre(
  AConn: TUniConnection;
  const ASql, AEmpresa, ACodigo: string): TJSONArray;
var
  oArray: TJSONArray;
  Qry: TUniQuery;
begin
  oArray := TJSONArray.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text := ASql;
      if Assigned(Qry.Params.FindParam('EMPRESA')) then
        Qry.ParamByName('EMPRESA').AsString := AEmpresa;
      if Assigned(Qry.Params.FindParam('CODIGO')) then
        Qry.ParamByName('CODIGO').AsString := ACodigo;
      Qry.Open;
      while not Qry.Eof do
      begin
        oArray.AddElement(RegistroAJson(Qry));
        Qry.Next;
      end;
      Result := oArray;
    except
      FreeAndNil(oArray);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function CampoAJson(ACampo: TField): TJSONValue;
var
  aDatos: TBytes;
  dtUtc: TDateTime;
  sNumero: string;
begin
  if ACampo.IsNull then
    Result := TJSONNull.Create
  else
  begin
    case ACampo.DataType of
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftLongWord,
      ftShortint, ftByte:
        Result := TJSONNumber.Create(ACampo.AsLargeInt);
      ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
        begin
          sNumero := FloatToStr(ACampo.AsFloat,
                                TFormatSettings.Invariant);
          Result := TJSONNumber.Create(sNumero);
        end;
      ftBoolean:
        Result := TJSONBool.Create(ACampo.AsBoolean);
      ftDate:
        Result := TJSONString.Create(
          FormatDateTime('yyyy-mm-dd', ACampo.AsDateTime));
      ftTime:
        Result := TJSONString.Create(
          FormatDateTime('hh:nn:ss.zzz', ACampo.AsDateTime));
      ftDateTime, ftTimeStamp, ftTimeStampOffset:
        begin
          dtUtc := TTimeZone.Local.ToUniversalTime(ACampo.AsDateTime);
          Result := TJSONString.Create(DateToISO8601(dtUtc, True));
        end;
      ftBlob, ftGraphic, ftOraBlob:
        begin
          aDatos := LeerCampoBinario(ACampo);
          Result := TJSONString.Create(
            TNetEncoding.Base64.EncodeBytesToString(aDatos));
        end;
      ftBytes, ftVarBytes:
        begin
          aDatos := ACampo.AsBytes;
          Result := TJSONString.Create(
            TNetEncoding.Base64.EncodeBytesToString(aDatos));
        end;
    else
      Result := TJSONString.Create(ACampo.AsString);
    end;
  end;
end;

function RegistroAJson(ADataSet: TDataSet): TJSONObject;
var
  iCampo: Integer;
begin
  Result := TJSONObject.Create;
  try
    for iCampo := 0 to ADataSet.FieldCount - 1 do
      Result.AddPair(ADataSet.Fields[iCampo].FieldName,
                     CampoAJson(ADataSet.Fields[iCampo]));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

class function TVentasWsJson.ConstruirArray(AConn: TUniConnection;
  const ASql, ASerie, ANumero: string): TJSONArray;
var
  oArray: TJSONArray;
  Qry: TUniQuery;
begin
  oArray := TJSONArray.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text := ASql;
      if Assigned(Qry.Params.FindParam('SERIE')) then
        Qry.ParamByName('SERIE').AsString := ASerie;
      if Assigned(Qry.Params.FindParam('NUMERO')) then
        Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      while not Qry.Eof do
      begin
        oArray.AddElement(RegistroAJson(Qry));
        Qry.Next;
      end;
      Result := oArray;
    except
      FreeAndNil(oArray);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

class function TVentasWsJson.ConstruirCabecera(AConn: TUniConnection;
  const ASerie, ANumero: string): TJSONObject;
var
  oCabecera: TJSONObject;
  Qry: TUniQuery;
begin
  oCabecera := nil;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT * FROM fza_facturas ' +
        ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      if Qry.IsEmpty then
        raise Exception.Create(FormatearMensajeDocumentos(
          CrearFormatoDocumentoLecturas(AConn)
          .LeerFormatoFactura(ASerie, ANumero),
          SErrorFacturaWebserviceNoExiste, [ASerie, ANumero]));
      oCabecera := RegistroAJson(Qry);
      Result := oCabecera;
    except
      FreeAndNil(oCabecera);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

class function TVentasWsJson.ConstruirCierreCabecera(
  AConn: TUniConnection;
  const AEmpresa, ACodigo: string): TJSONObject;
var
  oCabecera: TJSONObject;
  Qry: TUniQuery;
begin
  oCabecera := nil;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT A.*, ' +
        '   COALESCE(NULLIF(ALM.NOMBRE_ALM_ALM, ''''), ' +
        '     A.CODIGO_ALM_ARQ) AS NOMBRE_ALMACEN_CALC ' +
        ' FROM fza_caja_arqueos A ' +
        ' LEFT JOIN fza_almacenes ALM ' +
        '   ON ALM.CODIGO_ALM_ALM = A.CODIGO_ALM_ARQ ' +
        ' WHERE A.CODIGO_EMP_ARQ = :EMPRESA ' +
        '   AND A.CODIGO_ARQ = :CODIGO';
      Qry.ParamByName('EMPRESA').AsString := AEmpresa;
      Qry.ParamByName('CODIGO').AsString := ACodigo;
      Qry.Open;
      if Qry.IsEmpty then
        raise Exception.CreateFmt(
          'No existe el cierre de caja %s de la empresa %s.',
          [ACodigo, AEmpresa]);
      oCabecera := RegistroAJson(Qry);
      Result := oCabecera;
    except
      FreeAndNil(oCabecera);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

// Recuento de efectivo y formas de pago del arqueo.
class function TVentasWsJson.SqlCierreRecuento: string;
begin
  Result :=
    ' SELECT R.* ' +
    ' FROM fza_caja_arqueos_recuento R ' +
    ' INNER JOIN fza_caja_arqueos A ' +
    '   ON A.CODIGO_ARQ = R.CODIGO_ARQ_ARQR ' +
    ' WHERE A.CODIGO_EMP_ARQ = :EMPRESA ' +
    '   AND R.CODIGO_ARQ_ARQR = :CODIGO ' +
    ' ORDER BY R.ESCAJON_ARQR DESC, R.CODIGO_FP_CFP_ARQR';
end;

// Unidades y neto por temporada del articulo.
class function TVentasWsJson.SqlCierreResumenTemporadas: string;
begin
  Result :=
    ' SELECT COALESCE(NULLIF((SELECT COALESCE(PV.PV, ' +
    '     P.VALOR_LIBRE_ARTPROP) ' +
    '   FROM fza_articulos_propiedades P ' +
    '   LEFT JOIN fza_propiedades_valores PV ' +
    '     ON PV.ID_PV_ARTPROP = P.ID_PV_ARTPROP ' +
    '   WHERE P.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    '     AND P.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    '     AND P.CODIGO_UNIDAD_ARTPROP IN ( ' +
    '       IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ' +
    '       SUBSTRING_INDEX(' +
    '         IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ''/'', 2), ' +
    '       '''') ' +
    '   ORDER BY LENGTH(P.CODIGO_UNIDAD_ARTPROP) DESC, ' +
    '     P.CODIGO_UNIDAD_ARTPROP DESC ' +
    '   LIMIT 1), ''''), ''(sin temporada)'') AS TEMPORADA, ' +
    '   COALESCE(SUM(L.CANTIDAD_FACLIN), 0) AS UNIDADES, ' +
    '   COALESCE(SUM(L.TOTAL_FACLIN), 0) AS NETO ' +
    ' FROM (SELECT DISTINCT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.SERIE_FAC_OPCAJA AS SERIE, ' +
    '     O.NUMERO_FAC_OPCAJA AS NUMERO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO ' +
    '     AND COALESCE(O.SERIE_FAC_OPCAJA, '''') <> '''' ' +
    '     AND COALESCE(O.NUMERO_FAC_OPCAJA, '''') <> '''') D ' +
    ' INNER JOIN fza_facturas_lineas L ' +
    '   ON L.CODIGO_EMP_FACLIN = D.EMPRESA ' +
    '  AND L.SERIE_FAC_FACLIN = D.SERIE ' +
    '  AND L.NUMERO_FAC_FACLIN = D.NUMERO ' +
    ' GROUP BY TEMPORADA ORDER BY TEMPORADA';
end;

// Unidades y neto por familia de articulo.
class function TVentasWsJson.SqlCierreResumenFamilias: string;
begin
  Result :=
    ' SELECT COALESCE(NULLIF(L.CODIGO_FAM_FACLIN, ''''), ' +
    '   A.CODIGO_FAM_ART, '''') AS CODIGO_FAMILIA, ' +
    '   COALESCE(NULLIF(L.NOMBRE_FAM_FACLIN, ''''), ' +
    '   NULLIF(F.DESCRIPCION_FAM, ''''), ' +
    '   NULLIF(F.NOMBRE_FAM_FAM, ''''), ' +
    '   ''(sin familia)'') AS FAMILIA, ' +
    '   COALESCE(SUM(L.CANTIDAD_FACLIN), 0) AS UNIDADES, ' +
    '   COALESCE(SUM(L.TOTAL_FACLIN), 0) AS NETO ' +
    ' FROM (SELECT DISTINCT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.SERIE_FAC_OPCAJA AS SERIE, ' +
    '     O.NUMERO_FAC_OPCAJA AS NUMERO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO ' +
    '     AND COALESCE(O.SERIE_FAC_OPCAJA, '''') <> '''' ' +
    '     AND COALESCE(O.NUMERO_FAC_OPCAJA, '''') <> '''') D ' +
    ' INNER JOIN fza_facturas_lineas L ' +
    '   ON L.CODIGO_EMP_FACLIN = D.EMPRESA ' +
    '  AND L.SERIE_FAC_FACLIN = D.SERIE ' +
    '  AND L.NUMERO_FAC_FACLIN = D.NUMERO ' +
    ' LEFT JOIN fza_articulos A ' +
    '   ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    ' LEFT JOIN fza_articulos_familias F ' +
    '   ON F.CODIGO_FAM_FAM = COALESCE(' +
    '     NULLIF(L.CODIGO_FAM_FACLIN, ''''), A.CODIGO_FAM_ART) ' +
    ' GROUP BY CODIGO_FAMILIA, FAMILIA ' +
    ' ORDER BY FAMILIA';
end;

// Unidades y neto por proveedor del articulo.
class function TVentasWsJson.SqlCierreResumenProveedores: string;
begin
  Result :=
    ' SELECT COALESCE(NULLIF(L.CODIGO_PRV_FACLIN, ''''), ' +
    '   AP.CODIGO_PRV_AP, ''(sin proveedor)'') ' +
    '   AS CODIGO_PROVEEDOR, ' +
    '   COALESCE(NULLIF(L.RAZON_SOCIAL_PROVEEDOR_FACLIN, ''''), ' +
    '   NULLIF(PRV.RAZON_SOCIAL_PRV, ''''), ' +
    '   NULLIF(L.CODIGO_PRV_FACLIN, ''''), AP.CODIGO_PRV_AP, ' +
    '   ''(sin proveedor)'') AS PROVEEDOR, ' +
    '   COALESCE(SUM(L.CANTIDAD_FACLIN), 0) AS UNIDADES, ' +
    '   COALESCE(SUM(L.TOTAL_FACLIN), 0) AS NETO ' +
    ' FROM (SELECT DISTINCT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.SERIE_FAC_OPCAJA AS SERIE, ' +
    '     O.NUMERO_FAC_OPCAJA AS NUMERO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO ' +
    '     AND COALESCE(O.SERIE_FAC_OPCAJA, '''') <> '''' ' +
    '     AND COALESCE(O.NUMERO_FAC_OPCAJA, '''') <> '''') D ' +
    ' INNER JOIN fza_facturas_lineas L ' +
    '   ON L.CODIGO_EMP_FACLIN = D.EMPRESA ' +
    '  AND L.SERIE_FAC_FACLIN = D.SERIE ' +
    '  AND L.NUMERO_FAC_FACLIN = D.NUMERO ' +
    ' LEFT JOIN fza_articulos A ' +
    '   ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    ' LEFT JOIN fza_articulos_proveedores AP ' +
    '   ON AP.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '  AND AP.CODIGO_PRV_AP = COALESCE(' +
    '    NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '    (SELECT APX.CODIGO_PRV_AP ' +
    '       FROM fza_articulos_proveedores APX ' +
    '      WHERE APX.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '      ORDER BY CASE ' +
    '        WHEN APX.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '        THEN 0 ELSE 1 END, ' +
    '        APX.FECHA_VALIDEZ_AP DESC, APX.CODIGO_PRV_AP ' +
    '      LIMIT 1)) ' +
    ' LEFT JOIN fza_proveedores PRV ' +
    '   ON PRV.CODIGO_PRV_PRV = COALESCE(' +
    '     NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '     AP.CODIGO_PRV_AP) ' +
    ' GROUP BY CODIGO_PROVEEDOR, PROVEEDOR ' +
    ' ORDER BY PROVEEDOR';
end;

// Operaciones e importe por forma de pago.
class function TVentasWsJson.SqlCierreResumenFormasPago: string;
begin
  Result :=
    ' SELECT P.CODIGO_FP_CFP AS CODIGO_FORMA_PAGO, ' +
    '   COALESCE(NULLIF(FP.DESCRIPCION_FORMA_PAGO_CFP, ''''), ' +
    '   P.CODIGO_FP_CFP) AS FORMA_PAGO, ' +
    '   COUNT(DISTINCT O.EMPRESA, O.ALMACEN, O.CAJA, ' +
    '     O.SERIE, O.NUMERO) AS OPERACIONES, ' +
    '   COALESCE(SUM(COALESCE(P.IMPORTE_ENTREGADO_PAGO, 0) - ' +
    '     COALESCE(P.IMPORTE_CAMBIO_PAGO, 0)), 0) AS IMPORTE ' +
    ' FROM (SELECT DISTINCT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.CODIGO_ALM_OPCAJA AS ALMACEN, ' +
    '     O.CODIGO_CAJA_OPCAJA AS CAJA, ' +
    '     COALESCE(O.SERIE_FAC_OPCAJA, '''') AS SERIE, ' +
    '     O.NUMERO_OPERACION_OPCAJA AS NUMERO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO) O ' +
    ' INNER JOIN fza_caja_pagos P ' +
    '   ON P.CODIGO_EMP_PAGO = O.EMPRESA ' +
    '  AND P.CODIGO_ALM_PAGO = O.ALMACEN ' +
    '  AND P.CODIGO_CAJA_PAGO = O.CAJA ' +
    '  AND P.SERIE_OPERACION_PAGO = O.SERIE ' +
    '  AND P.NUMERO_OPERACION_PAGO = O.NUMERO ' +
    ' LEFT JOIN fza_caja_formas_pago FP ' +
    '   ON FP.CODIGO_FP_CFP = P.CODIGO_FP_CFP ' +
    ' GROUP BY P.CODIGO_FP_CFP, FORMA_PAGO ' +
    ' ORDER BY IMPORTE DESC';
end;

// Operaciones y neto por empleado.
class function TVentasWsJson.SqlCierreResumenEmpleados: string;
begin
  Result :=
    ' SELECT D.CODIGO_EMPLEADO AS CODIGO_EMPLEADO, ' +
    '   COALESCE(NULLIF(E.DIMINUTIVO_TICKET_EMPL, ''''), ' +
    '   NULLIF(E.NOMBRE_EMPL, ''''), ' +
    '   D.CODIGO_EMPLEADO, ''?'') AS EMPLEADO, ' +
    '   COUNT(*) AS OPERACIONES, ' +
    '   COALESCE(SUM(F.TOTAL_LIQUIDO_FAC), 0) AS NETO ' +
    ' FROM (SELECT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.SERIE_FAC_OPCAJA AS SERIE, ' +
    '     O.NUMERO_FAC_OPCAJA AS NUMERO, ' +
    '     MAX(O.CODIGO_EMPLEADO_OPCAJA) AS CODIGO_EMPLEADO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO ' +
    '     AND COALESCE(O.SERIE_FAC_OPCAJA, '''') <> '''' ' +
    '     AND COALESCE(O.NUMERO_FAC_OPCAJA, '''') <> '''' ' +
    '   GROUP BY O.CODIGO_EMP_OPCAJA, O.SERIE_FAC_OPCAJA, ' +
    '     O.NUMERO_FAC_OPCAJA) D ' +
    ' INNER JOIN fza_facturas F ' +
    '   ON F.CODIGO_EMP_FAC = D.EMPRESA ' +
    '  AND F.SERIE_FAC = D.SERIE ' +
    '  AND F.NUMERO_FAC = D.NUMERO ' +
    ' LEFT JOIN fza_empleados E ' +
    '   ON E.CODIGO_EMPL = D.CODIGO_EMPLEADO ' +
    ' GROUP BY D.CODIGO_EMPLEADO, EMPLEADO ' +
    ' ORDER BY NETO DESC';
end;

// Bases, cuotas y total por serie de factura.
class function TVentasWsJson.SqlCierreResumenSeries: string;
begin
  Result :=
    ' SELECT F.SERIE_FAC AS SERIE, ' +
    '   COALESCE(SUM(F.TOTAL_BASES_FAC), 0) AS BASE, ' +
    '   COALESCE(SUM(F.TOTAL_IMPUESTOS_FAC), 0) AS CUOTA, ' +
    '   COALESCE(SUM(F.TOTAL_LIQUIDO_FAC), 0) AS TOTAL ' +
    ' FROM (SELECT DISTINCT ' +
    '     O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    '     O.SERIE_FAC_OPCAJA AS SERIE, ' +
    '     O.NUMERO_FAC_OPCAJA AS NUMERO ' +
    '   FROM fza_caja_operaciones O ' +
    '   WHERE O.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '     AND O.CODIGO_ARQUEO_OPCAJA = :CODIGO ' +
    '     AND COALESCE(O.SERIE_FAC_OPCAJA, '''') <> '''' ' +
    '     AND COALESCE(O.NUMERO_FAC_OPCAJA, '''') <> '''') D ' +
    ' INNER JOIN fza_facturas F ' +
    '   ON F.CODIGO_EMP_FAC = D.EMPRESA ' +
    '  AND F.SERIE_FAC = D.SERIE ' +
    '  AND F.NUMERO_FAC = D.NUMERO ' +
    ' GROUP BY F.SERIE_FAC ORDER BY F.SERIE_FAC';
end;

class function TVentasWsJson.ConstruirCierre(
  AConn: TUniConnection;
  const AEmpresa, ACodigo: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair(
      'cabecera',
      ConstruirCierreCabecera(AConn, AEmpresa, ACodigo));
    Result.AddPair('recuento', ConstruirArrayCierre(
      AConn, SqlCierreRecuento, AEmpresa, ACodigo));
    Result.AddPair('resumen_temporadas', ConstruirArrayCierre(
      AConn, SqlCierreResumenTemporadas, AEmpresa, ACodigo));
    Result.AddPair('resumen_familias', ConstruirArrayCierre(
      AConn, SqlCierreResumenFamilias, AEmpresa, ACodigo));
    Result.AddPair('resumen_proveedores', ConstruirArrayCierre(
      AConn, SqlCierreResumenProveedores, AEmpresa, ACodigo));
    Result.AddPair('resumen_formas_pago', ConstruirArrayCierre(
      AConn, SqlCierreResumenFormasPago, AEmpresa, ACodigo));
    Result.AddPair('resumen_empleados', ConstruirArrayCierre(
      AConn, SqlCierreResumenEmpleados, AEmpresa, ACodigo));
    Result.AddPair('resumen_series', ConstruirArrayCierre(
      AConn, SqlCierreResumenSeries, AEmpresa, ACodigo));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

class function TVentasWsJson.ConstruirDocumentos(AConn: TUniConnection;
  AIdCola: Int64): TJSONObject;
var
  Qry: TUniQuery;

  procedure AgregarPdf(const AClave, ACampoNombre, ACampoContenido,
    ACampoTamano, ACampoHuella: string);
  var
    aPdf: TBytes;
    oPdf: TJSONObject;
  begin
    if not Qry.FieldByName(ACampoContenido).IsNull then
    begin
      aPdf := LeerCampoBinario(Qry.FieldByName(ACampoContenido));
      oPdf := TJSONObject.Create;
      try
        oPdf.AddPair('nombre', Qry.FieldByName(ACampoNombre).AsString);
        oPdf.AddPair('mime', 'application/pdf');
        oPdf.AddPair('tamano', TJSONNumber.Create(
          Qry.FieldByName(ACampoTamano).AsLargeInt));
        oPdf.AddPair('sha256', Qry.FieldByName(ACampoHuella).AsString);
        oPdf.AddPair('contenido_base64',
          TNetEncoding.Base64.EncodeBytesToString(aPdf));
        Result.AddPair(AClave, oPdf);
        oPdf := nil;
      finally
        FreeAndNil(oPdf);
      end;
    end;
  end;

begin
  Result := TJSONObject.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT NOMBRE_PDF_VWSC, TICKET_PDF_VWSC, ' +
        '        TAMANO_PDF_VWSC, HUELLA_PDF_VWSC, ' +
        '        NOMBRE_FACTURA_PDF_VWSC, FACTURA_PDF_VWSC, ' +
        '        TAMANO_FACTURA_PDF_VWSC, HUELLA_FACTURA_PDF_VWSC ' +
        ' FROM fza_ventas_ws_cola WHERE ID_VWSC = :ID';
      Qry.ParamByName('ID').AsLargeInt := AIdCola;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        AgregarPdf('ticket_pdf', 'NOMBRE_PDF_VWSC', 'TICKET_PDF_VWSC',
          'TAMANO_PDF_VWSC', 'HUELLA_PDF_VWSC');
        AgregarPdf('factura_pdf', 'NOMBRE_FACTURA_PDF_VWSC',
          'FACTURA_PDF_VWSC', 'TAMANO_FACTURA_PDF_VWSC',
          'HUELLA_FACTURA_PDF_VWSC');
      end;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

{ Fotos de los articulos de la venta, en la version de 300 px que ViraCash
  ya tiene generada en disco. Van a nivel de venta y no de linea: si el mismo
  articulo aparece cinco veces, la foto viaja una sola vez.

  La resolucion replica la de inLibFotos (foto del SKU, si no la del prefijo
  mas largo, si no la del articulo) pero por SQL, para no arrastrar hasta
  aqui las dependencias graficas y de FastReport de aquella unidad. }
class function TVentasWsJson.ConstruirFotos(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string): TJSONArray;
const
  cMaxBytesFoto = 4 * 1024 * 1024;
var
  aDatos: TBytes;
  iTamano: Int64;
  oArray: TJSONArray;
  oEnviadas: TStringList;
  oFoto: TJSONObject;
  QryFoto: TUniQuery;
  QryLin: TUniQuery;
  sArticulo: string;
  sClave: string;
  sDir300: string;
  sDirFotos: string;
  sRuta: string;
  sUnidad: string;
begin
  oArray := TJSONArray.Create;
  oEnviadas := TStringList.Create;
  QryLin := TUniQuery.Create(nil);
  QryFoto := TUniQuery.Create(nil);
  try
    try
      oEnviadas.Sorted := True;
      oEnviadas.Duplicates := dupIgnore;
      sDirFotos := '';
      if Assigned(AParametrosApp) then
        sDirFotos := Trim(AParametrosApp.GetPath('appDirFotos'));
      if sDirFotos <> '' then
      begin
        sDir300 := TPath.Combine(sDirFotos, '300');
        QryLin.Connection := AConn;
        QryLin.SQL.Text :=
          ' SELECT DISTINCT CODIGO_ART_FACLIN AS ARTICULO, ' +
          '   IFNULL(CODIGO_UNIDAD_FACLIN, '''') AS UNIDAD ' +
          ' FROM fza_facturas_lineas ' +
          ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
          '   AND NUMERO_FAC_FACLIN = :NUMERO ' +
          '   AND CODIGO_ART_FACLIN IS NOT NULL';
        QryLin.ParamByName('SERIE').AsString := ASerie;
        QryLin.ParamByName('NUMERO').AsString := ANumero;
        QryLin.Open;
        QryFoto.Connection := AConn;
        QryFoto.SQL.Text :=
          ' SELECT CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT ' +
          ' FROM fza_articulos_fotos ' +
          ' WHERE CODIGO_ART_FOT = :ART ' +
          '   AND ORDEN_FOT = 1 ' +
          '   AND (CODIGO_UNIDAD_FOT = :SKU ' +
          '        OR :SKU LIKE CONCAT(CODIGO_UNIDAD_FOT, ''/%'') ' +
          '        OR CODIGO_UNIDAD_FOT = '''') ' +
          ' ORDER BY LENGTH(CODIGO_UNIDAD_FOT) DESC, ' +
          '          CODIGO_UNIDAD_FOT DESC ' +
          ' LIMIT 1';
        while not QryLin.Eof do
        begin
          sArticulo := QryLin.FieldByName('ARTICULO').AsString;
          sUnidad := QryLin.FieldByName('UNIDAD').AsString;
          QryFoto.Close;
          QryFoto.ParamByName('ART').AsString := sArticulo;
          QryFoto.ParamByName('SKU').AsString := sUnidad;
          QryFoto.Open;
          if not QryFoto.IsEmpty then
          begin
            sClave := sArticulo + '|' +
                      QryFoto.FieldByName('CODIGO_UNIDAD_FOT').AsString;
            sRuta := TPath.Combine(sDir300,
              QryFoto.FieldByName('NOMBRE_FOT_FOT').AsString + '.png');
            if (oEnviadas.IndexOf(sClave) < 0) and TFile.Exists(sRuta) then
            begin
              iTamano := TFile.GetSize(sRuta);
              if (iTamano > 0) and (iTamano <= cMaxBytesFoto) then
              begin
                oEnviadas.Add(sClave);
                aDatos := TFile.ReadAllBytes(sRuta);
                oFoto := TJSONObject.Create;
                oArray.AddElement(oFoto);
                oFoto.AddPair('articulo', sArticulo);
                oFoto.AddPair('clave_unidad',
                  QryFoto.FieldByName('CODIGO_UNIDAD_FOT').AsString);
                oFoto.AddPair('nombre', ExtractFileName(sRuta));
                oFoto.AddPair('mime', 'image/png');
                oFoto.AddPair('tamano', TJSONNumber.Create(iTamano));
                oFoto.AddPair('sha256',
                  UpperCase(THashSHA2.GetHashStringFromFile(sRuta)));
                oFoto.AddPair('contenido_base64',
                  TNetEncoding.Base64.EncodeBytesToString(aDatos));
              end;
            end;
          end;
          QryFoto.Close;
          QryLin.Next;
        end;
        QryLin.Close;
      end;
      Result := oArray;
    except
      // Que falle una foto no puede impedir que la venta se envie.
      FreeAndNil(oArray);
      Result := TJSONArray.Create;
    end;
  finally
    FreeAndNil(QryFoto);
    FreeAndNil(QryLin);
    FreeAndNil(oEnviadas);
  end;
end;

// Lineas de la venta con temporada, familia, proveedor y almacen ya
// resueltos: el webservice los proyecta tal cual.
class function TVentasWsJson.SqlVentaLineas: string;
begin
  Result :=
      ' SELECT L.*, ' +
    '   (SELECT COALESCE(V.PV, P.VALOR_LIBRE_ARTPROP) ' +
    '      FROM fza_articulos_propiedades P ' +
    '      LEFT JOIN fza_propiedades_valores V ' +
    '             ON V.ID_PV_ARTPROP = P.ID_PV_ARTPROP ' +
    '     WHERE P.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    '       AND P.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    '       AND P.CODIGO_UNIDAD_ARTPROP IN ( ' +
    '             IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ' +
    '             SUBSTRING_INDEX( ' +
    '               IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ''/'', 2), ' +
    '             '''') ' +
    '     ORDER BY LENGTH(P.CODIGO_UNIDAD_ARTPROP) DESC, ' +
    '              P.CODIGO_UNIDAD_ARTPROP DESC ' +
    '     LIMIT 1) AS TEMPORADA_CALC, ' +
    '   COALESCE(NULLIF(TRIM(L.CODIGO_FAM_FACLIN), ''''), ' +
    '     A.CODIGO_FAM_ART, '''') AS CODIGO_FAM_CALC, ' +
    '   COALESCE(NULLIF(L.NOMBRE_FAM_FACLIN, ''''), ' +
    '     NULLIF(FAM.NOMBRE_FAM_FAM, ''''), ' +
    '     NULLIF(FAM.DESCRIPCION_FAM, ''''), ' +
    '     NULLIF(TRIM(L.CODIGO_FAM_FACLIN), ''''), ' +
    '     A.CODIGO_FAM_ART, '''') AS NOMBRE_FAM_CALC, ' +
    '   COALESCE(NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '     AP.CODIGO_PRV_AP, '''') AS CODIGO_PRV_CALC, ' +
    '   COALESCE(' +
    '     NULLIF(L.RAZON_SOCIAL_PROVEEDOR_FACLIN, ''''), ' +
    '     NULLIF(PRV.RAZON_SOCIAL_PRV, ''''), ' +
    '     NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '     AP.CODIGO_PRV_AP, '''') AS NOMBRE_PRV_CALC, ' +
    '   COALESCE(NULLIF(L.CODIGO_ALM_FACLIN, ''''), ' +
    '     F.CODIGO_ALM_FAC, '''') AS CODIGO_ALM_CALC, ' +
    '   COALESCE(NULLIF(ALM.NOMBRE_ALM_ALM, ''''), ' +
    '     NULLIF(L.CODIGO_ALM_FACLIN, ''''), ' +
    '     F.CODIGO_ALM_FAC, '''') AS NOMBRE_ALM_CALC ' +
    ' FROM fza_facturas_lineas L ' +
    ' LEFT JOIN fza_facturas F ' +
    '   ON F.SERIE_FAC = L.SERIE_FAC_FACLIN ' +
    '  AND F.NUMERO_FAC = L.NUMERO_FAC_FACLIN ' +
    ' LEFT JOIN fza_articulos A ' +
    '   ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    ' LEFT JOIN fza_articulos_familias FAM ' +
    '   ON FAM.CODIGO_FAM_FAM = COALESCE(' +
    '     NULLIF(TRIM(L.CODIGO_FAM_FACLIN), ''''), ' +
    '     A.CODIGO_FAM_ART) ' +
    ' LEFT JOIN fza_articulos_proveedores AP ' +
    '   ON AP.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '  AND AP.CODIGO_PRV_AP = COALESCE(' +
    '    NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '    (SELECT APX.CODIGO_PRV_AP ' +
    '       FROM fza_articulos_proveedores APX ' +
    '      WHERE APX.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '      ORDER BY CASE ' +
    '        WHEN APX.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '        THEN 0 ELSE 1 END, ' +
    '        APX.FECHA_VALIDEZ_AP DESC, APX.CODIGO_PRV_AP ' +
    '      LIMIT 1)) ' +
    ' LEFT JOIN fza_proveedores PRV ' +
    '   ON PRV.CODIGO_PRV_PRV = COALESCE(' +
    '     NULLIF(TRIM(L.CODIGO_PRV_FACLIN), ''''), ' +
    '     AP.CODIGO_PRV_AP) ' +
    ' LEFT JOIN fza_almacenes ALM ' +
    '   ON ALM.CODIGO_ALM_ALM = COALESCE(' +
    '     NULLIF(L.CODIGO_ALM_FACLIN, ''''), ' +
    '     F.CODIGO_ALM_FAC) ' +
    ' WHERE L.SERIE_FAC_FACLIN = :SERIE ' +
    '   AND L.NUMERO_FAC_FACLIN = :NUMERO ' +
    ' ORDER BY L.LINEA_FACLIN';
end;

// Cuerpo de la venta: cabecera, lineas, cobros, movimientos, bloque
// fiscal y adjuntos.
class function TVentasWsJson.ConstruirVenta(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  AIdCola: Int64;
  const ASerie, ANumero: string): TJSONObject;
var
  oFiscal: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
      Result.AddPair('cabecera',
        ConstruirCabecera(AConn, ASerie, ANumero));
      // La temporada no vive en la linea: es una propiedad del articulo. Se
      // resuelve del nivel mas concreto al mas general (sku, color, articulo)
      // y viaja como TEMPORADA_CALC, que es lo que proyecta el webservice.
      Result.AddPair('lineas', ConstruirArray(
        AConn, SqlVentaLineas, ASerie, ANumero));
    Result.AddPair('pagos_factura', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_pagos ' +
      ' WHERE SERIE_FAC_FACPAG = :SERIE ' +
      '   AND NUMERO_FAC_FACPAG = :NUMERO ' +
      ' ORDER BY LINEA_FACPAG', ASerie, ANumero));
    Result.AddPair('recibos', ConstruirArray(AConn,
      ' SELECT * FROM fza_recibos ' +
      ' WHERE SERIE_FAC_REC = :SERIE ' +
      '   AND NUMERO_FAC_REC = :NUMERO ' +
      ' ORDER BY NUMERO_PLAZO_REC', ASerie, ANumero));
    Result.AddPair('efectos_venta', ConstruirArray(AConn,
      ' SELECT * FROM fza_efectos_venta ' +
      ' WHERE SERIE_FAC_EFV = :SERIE ' +
      '   AND NUMERO_FAC_EFV = :NUMERO ' +
      ' ORDER BY NUMERO_EFV', ASerie, ANumero));
    Result.AddPair('pagos_caja', ConstruirArray(AConn,
      ' SELECT P.* FROM fza_caja_pagos P ' +
      ' INNER JOIN fza_facturas F ' +
      '   ON F.CODIGO_EMP_FAC = P.CODIGO_EMP_PAGO ' +
      '  AND F.CODIGO_ALM_FAC = P.CODIGO_ALM_PAGO ' +
      '  AND F.CODIGO_CAJA_FAC = P.CODIGO_CAJA_PAGO ' +
      '  AND F.SERIE_FAC = P.SERIE_OPERACION_PAGO ' +
      '  AND F.NUMERO_OPERACION_FAC = P.NUMERO_OPERACION_PAGO ' +
      ' WHERE F.SERIE_FAC = :SERIE AND F.NUMERO_FAC = :NUMERO ' +
      ' ORDER BY P.NUMERO_LINEA_PAGO', ASerie, ANumero));
    Result.AddPair('operaciones_caja', ConstruirArray(AConn,
      ' SELECT O.* FROM fza_caja_operaciones O ' +
      ' WHERE O.SERIE_FAC_OPCAJA = :SERIE ' +
      '   AND O.NUMERO_FAC_OPCAJA = :NUMERO ' +
      ' ORDER BY O.ID_OPCAJA', ASerie, ANumero));
    Result.AddPair('movimientos_almacen', ConstruirArray(AConn,
      ' SELECT * FROM fza_movimientos_almacen ' +
      ' WHERE SERIE_DOC_MOV = :SERIE AND NUMERO_DOC_MOV = :NUMERO ' +
      ' ORDER BY NUMERO_MOV', ASerie, ANumero));
    Result.AddPair('vales', ConstruirArray(AConn,
      ' SELECT * FROM fza_caja_vales ' +
      ' WHERE (SERIE_FAC_EMI_VL = :SERIE ' +
      '        AND NUMERO_FAC_EMI_VL = :NUMERO) ' +
      '    OR (SERIE_FAC_RED_VL = :SERIE ' +
      '        AND NUMERO_FAC_RED_VL = :NUMERO) ' +
      ' ORDER BY CODIGO_VL', ASerie, ANumero));
    Result.AddPair('depositos', ConstruirArray(AConn,
      ' SELECT DISTINCT D.* FROM fza_depositos_cliente D ' +
      ' INNER JOIN fza_caja_operaciones O ' +
      '   ON O.ID_DEPOSITO_OPCAJA = D.ID_DEPOSITO_DEP ' +
      ' WHERE O.SERIE_FAC_OPCAJA = :SERIE ' +
      '   AND O.NUMERO_FAC_OPCAJA = :NUMERO ' +
      ' ORDER BY D.ID_DEPOSITO_DEP', ASerie, ANumero));
    Result.AddPair('relaciones', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_relaciones ' +
      ' WHERE (SERIE_FAC_FACREL = :SERIE ' +
      '        AND NUMERO_FAC_FACREL = :NUMERO) ' +
      '    OR (SERIE_FAC_ORIGEN_FACREL = :SERIE ' +
      '        AND NUMERO_FAC_ORIGEN_FACREL = :NUMERO) ' +
      ' ORDER BY ID_FACREL', ASerie, ANumero));
    oFiscal := TJSONObject.Create;
    Result.AddPair('fiscal', oFiscal);
    oFiscal.AddPair('cola', ConstruirArray(AConn,
      ' SELECT * FROM fza_verifactu_cola ' +
      ' WHERE SERIE_FAC_VFCOLA = :SERIE ' +
      '   AND NUMERO_FAC_VFCOLA = :NUMERO ' +
      ' ORDER BY ID_VFCOLA', ASerie, ANumero));
    oFiscal.AddPair('consolidaciones', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_consolidaciones ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO ' +
      ' ORDER BY ID_FACCON', ASerie, ANumero));
    oFiscal.AddPair('eventos', ConstruirArray(AConn,
      ' SELECT * FROM fza_verifactu_eventos ' +
      ' WHERE SERIE_FAC_LOG = :SERIE AND NUMERO_FAC_LOG = :NUMERO ' +
      ' ORDER BY ID_LOG', ASerie, ANumero));
    Result.AddPair('documentos', ConstruirDocumentos(AConn, AIdCola));
    Result.AddPair('fotos',
      ConstruirFotos(AParametrosApp, AConn, ASerie, ANumero));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

class function TVentasWsJson.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  AConn: TUniConnection;
  AIdCola: Int64; const AIdEvento, ATipoEvento, AEmpresa,
  ASerie, ANumero: string): string;
var
  oDocumento: TJSONObject;
  oOrigen: TJSONObject;
  oRaiz: TJSONObject;
  sReferencia: string;
begin
  oRaiz := TJSONObject.Create;
  try
    oRaiz.AddPair('version_contrato', TJSONNumber.Create(1));
    oRaiz.AddPair('id_evento', AIdEvento);
    oRaiz.AddPair('secuencia_evento', TJSONNumber.Create(AIdCola));
    oRaiz.AddPair('tipo_evento', ATipoEvento);
    oRaiz.AddPair('generado_utc',
      DateToISO8601(TTimeZone.Local.ToUniversalTime(Now), True));
    oOrigen := TJSONObject.Create;
    oRaiz.AddPair('origen', oOrigen);
    oOrigen.AddPair('aplicacion', 'ViraCash');
    oOrigen.AddPair('version', AVersionApp);
    sReferencia := TClienteViraCashApi.Referencia(AParametrosApp);
    oOrigen.AddPair('referencia', sReferencia);
    oDocumento := TJSONObject.Create;
    oDocumento.AddPair('empresa', AEmpresa);
    oDocumento.AddPair('serie', ASerie);
    oDocumento.AddPair('numero', ANumero);
    oRaiz.AddPair('documento', oDocumento);
    if SameText(ATipoEvento, 'CIERRE_CAJA') then
      oRaiz.AddPair('cierre',
        ConstruirCierre(AConn, AEmpresa, ANumero))
    else
      oRaiz.AddPair('venta', ConstruirVenta(
        AParametrosApp, AConn, AIdCola, ASerie, ANumero));
    Result := oRaiz.ToJSON;
  finally
    FreeAndNil(oRaiz);
  end;
end;

constructor TVentasWsJsonUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TVentasWsJsonUniDAC.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  AIdCola: Int64;
  const AIdEvento, ATipoEvento, AEmpresa,
    ASerie, ANumero: string): string;
begin
  Result := TVentasWsJson.ConstruirEvento(
    AParametrosApp, AVersionApp, FConexion, AIdCola,
    AIdEvento, ATipoEvento, AEmpresa, ASerie, ANumero);
end;

function CrearVentasWsJsonUniDAC(
  AConexion: TUniConnection): IVentasWsJson;
begin
  Result := TVentasWsJsonUniDAC.Create(AConexion);
end;

end.

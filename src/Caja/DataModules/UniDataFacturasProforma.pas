{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasProforma                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de documentos generados y empresas disponibles.                 }
{******************************************************************************}
unit UniDataFacturasProforma;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibParametrosIntf,
  inLibFacturasProformaIntf;

type
  TdmFacturasProforma = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    function ConstruirSqlProformasCaja: string;
    function ConstruirSqlFacturasTraspaso: string;
    function ConstruirSqlFacturasTraspasoVendido: string;
    function ConstruirSqlPeriodosPendientes: string;
    procedure ConfigurarConsultas;
  public
    unqryEmpresas: TUniQuery;
    dsEmpresas   : TDataSource;
    unqryEmpresasDestino: TUniQuery;
    dsEmpresasDestino: TDataSource;
    procedure AbrirEmpresas;
    procedure AbrirEmpresasDestino(const AOrigen: string);
    procedure AbrirDetalles; override;
    function CrearRepositorio(
      const AParametrosApp: IParametrosAplicacion
    ): IRepositorioFacturasProforma;
    procedure RefrescarDocumentos;
    function ScriptsEsquemaPendientes: string;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  UniDataFacturasProformaRepositorio;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmFacturasProforma.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas := TUniQuery.Create(Self);
  // Hereda la conexión que TdmBase.DoCreate ya dejó en unqryTablaG antes de
  // tocar SpecificOptions: UniDAC valida cada opción contra el proveedor de
  // la conexión y sin ella lanza "Connection is not defined". Más tarde
  // ReasignarConexion la sustituye por la conexión propia del Mto.
  unqryEmpresas.Connection := unqryTablaG.Connection;
  dsEmpresas := TDataSource.Create(Self);
  dsEmpresas.DataSet := unqryEmpresas;
  unqryEmpresasDestino := TUniQuery.Create(Self);
  unqryEmpresasDestino.Connection := unqryTablaG.Connection;
  dsEmpresasDestino := TDataSource.Create(Self);
  dsEmpresasDestino.DataSet := unqryEmpresasDestino;
  ConfigurarConsultas;
end;

procedure TdmFacturasProforma.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsEmpresas) then
    dsEmpresas.DataSet := nil;
  if Assigned(unqryEmpresas) and unqryEmpresas.Active then
    unqryEmpresas.Close;
  inherited;
end;

procedure TdmFacturasProforma.ConfigurarConsultas;
begin
  unqryTablaG.SQL.Text :=
    ConstruirSqlProformasCaja +
    ConstruirSqlFacturasTraspaso +
    ConstruirSqlFacturasTraspasoVendido +
    ConstruirSqlPeriodosPendientes +
    ' ORDER BY FECHA_DOCUMENTO DESC, TIPO_DOCUMENTO, ' +
    '          SERIE_DOCUMENTO, NUMERO_DOCUMENTO DESC';
  unqryTablaG.KeyFields := 'CLAVE_DOCUMENTO';
  unqryTablaG.ReadOnly := True;
  unqryEmpresas.SQL.Text :=
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP ' +
    '  FROM fza_empresas ' +
    ' WHERE ESACTIVO_EMP = ''S'' ' +
    ' ORDER BY ORDEN_EMP, RAZON_SOCIAL_EMP';
  // Catálogo pequeño: se materializa antes de que el historial abra en
  // segundo plano, evitando un fetch pendiente sobre la misma conexión.
  if Assigned(unqryEmpresas.Connection) then
    unqryEmpresas.SpecificOptions.Values['FetchAll'] := 'True';
  unqryEmpresas.ReadOnly := True;
end;

function TdmFacturasProforma.ConstruirSqlProformasCaja: string;
begin
  Result :=
    'SELECT CONCAT(P.TIPO_PROCAJ, ''-'', P.ID_PROCAJ) ' +
    '         AS CLAVE_DOCUMENTO, ' +
    '       P.TIPO_PROCAJ AS TIPO_DOCUMENTO, ' +
    '       P.SERIE_PROCAJ AS SERIE_DOCUMENTO, ' +
    '       P.ID_FACPER_PROCAJ AS ID_PERIODO, ' +
    '       FP.ESTADO_FACPER AS ESTADO_PERIODO, ' +
    '       P.NUMERO_PROCAJ AS NUMERO_DOCUMENTO, ' +
    '       P.FECHA_PROCAJ AS FECHA_DOCUMENTO, ' +
    '       COALESCE(FP.FECHA_DESDE_FACPER, ' +
    '                P.FECHA_DESDE_PROCAJ) AS FECHA_DESDE, ' +
    '       COALESCE(FP.FECHA_HASTA_FACPER, ' +
    '                P.FECHA_HASTA_PROCAJ) AS FECHA_HASTA, ' +
    '       P.CODIGO_EMP_PROCAJ AS CODIGO_EMPRESA_ORIGEN, ' +
    '       P.RAZON_SOCIAL_EMPRESA_PROCAJ AS EMPRESA_ORIGEN, ' +
    '       CASE WHEN P.TIPO_PROCAJ = ''VR'' ' +
    '            THEN FP.CODIGO_EMP_DESTINO_FACPER ' +
    '            ELSE '''' END AS CODIGO_EMPRESA_DESTINO, ' +
    '       CASE WHEN P.TIPO_PROCAJ = ''VR'' ' +
    '            THEN ED.RAZON_SOCIAL_EMP ' +
    '            ELSE '''' END AS EMPRESA_DESTINO, ' +
    '       P.ESTADO_PROCAJ AS ESTADO_DOCUMENTO, ' +
    '       P.TOTAL_BASE_PROCAJ AS TOTAL_BASE, ' +
    '       P.TOTAL_IMPUESTOS_PROCAJ AS TOTAL_IMPUESTOS, ' +
    '       P.TOTAL_PROCAJ AS TOTAL_DOCUMENTO, ' +
    '       CASE WHEN P.TIPO_PROCAJ = ''VR'' THEN ' +
    '         (SELECT COUNT(*) FROM fza_proformas_caja_vales V ' +
    '          WHERE V.ID_PROCAJ_PROCVL = P.ID_PROCAJ) ELSE ' +
    '         (SELECT COUNT(DISTINCT L.ID_OPCAJA_PROCLIN) ' +
    '          FROM fza_proformas_caja_lineas L ' +
    '          WHERE L.ID_PROCAJ_PROCLIN = P.ID_PROCAJ) ' +
    '       END ' +
    '         AS CANTIDAD_OPERACIONES, ' +
    '       CASE WHEN P.TIPO_PROCAJ = ''VR'' THEN ' +
    '         (SELECT COUNT(*) FROM fza_proformas_caja_vales V ' +
    '          WHERE V.ID_PROCAJ_PROCVL = P.ID_PROCAJ ' +
    '          AND V.IMPORTE_COMPENSACION_PROCVL < 0) ELSE ' +
    '         (SELECT COUNT(DISTINCT L.ID_OPCAJA_PROCLIN) ' +
    '          FROM fza_proformas_caja_lineas L ' +
    '          WHERE L.ID_PROCAJ_PROCLIN = P.ID_PROCAJ ' +
    '          AND L.TIPO_VINCULO_PROCLIN = ''AJUSTE'') ' +
    '       END ' +
    '         AS CANTIDAD_AJUSTES ' +
    '  FROM fza_proformas_caja P ' +
    '  LEFT JOIN fza_facturacion_caja_periodos FP ' +
    '    ON FP.ID_FACPER = P.ID_FACPER_PROCAJ ' +
    '  LEFT JOIN fza_empresas ED ' +
    '    ON ED.CODIGO_EMP_EMP = FP.CODIGO_EMP_DESTINO_FACPER ';
end;

function TdmFacturasProforma.ConstruirSqlFacturasTraspaso: string;
begin
  Result :=
    'UNION ALL ' +
    'SELECT CONCAT(''TA-'', MIN(M.ID_FACOP)) AS CLAVE_DOCUMENTO, ' +
    '       ''TA'' AS TIPO_DOCUMENTO, ' +
    '       M.SERIE_FAC_FACOP AS SERIE_DOCUMENTO, ' +
    '       MIN(M.ID_FACPER_FACOP) AS ID_PERIODO, ' +
    '       MIN(FP.ESTADO_FACPER) AS ESTADO_PERIODO, ' +
    '       M.NUMERO_FAC_FACOP AS NUMERO_DOCUMENTO, ' +
    '       F.FECHA_FAC AS FECHA_DOCUMENTO, ' +
    '       COALESCE(MIN(FP.FECHA_DESDE_FACPER), ' +
    '                MIN(DATE(O.FECHA_OPERACION_OPCAJA))) AS FECHA_DESDE, ' +
    '       COALESCE(MAX(FP.FECHA_HASTA_FACPER), ' +
    '                MAX(DATE(O.FECHA_OPERACION_OPCAJA))) AS FECHA_HASTA, ' +
    '       M.CODIGO_EMP_ORIGEN_FACOP AS CODIGO_EMPRESA_ORIGEN, ' +
    '       COALESCE(NULLIF(F.RAZON_SOCIAL_EMPRESA_FAC, ''''), ' +
    '                EO.RAZON_SOCIAL_EMP) AS EMPRESA_ORIGEN, ' +
    '       M.CODIGO_EMP_DESTINO_FACOP AS CODIGO_EMPRESA_DESTINO, ' +
    '       COALESCE(NULLIF(F.RAZON_SOCIAL_CLIENTE_FAC, ''''), ' +
    '                ED.RAZON_SOCIAL_EMP) AS EMPRESA_DESTINO, ' +
    '       M.ESTADO_FACOP AS ESTADO_DOCUMENTO, ' +
    '       F.TOTAL_BASES_FAC AS TOTAL_BASE, ' +
    '       F.TOTAL_IMPUESTOS_FAC AS TOTAL_IMPUESTOS, ' +
    '       F.TOTAL_LIQUIDO_FAC AS TOTAL_DOCUMENTO, ' +
    '       COUNT(DISTINCT M.ID_OPCAJA_FACOP) AS CANTIDAD_OPERACIONES, ' +
    '       0 AS CANTIDAD_AJUSTES ' +
    '  FROM fza_facturas_operaciones_caja M ' +
    '  JOIN fza_facturas F ' +
    '    ON F.SERIE_FAC = M.SERIE_FAC_FACOP ' +
    '   AND F.NUMERO_FAC = M.NUMERO_FAC_FACOP ' +
    '  JOIN fza_caja_operaciones O ' +
    '    ON O.ID_OPCAJA = M.ID_OPCAJA_FACOP ' +
    '  LEFT JOIN fza_empresas EO ' +
    '    ON EO.CODIGO_EMP_EMP = M.CODIGO_EMP_ORIGEN_FACOP ' +
    '  LEFT JOIN fza_empresas ED ' +
    '    ON ED.CODIGO_EMP_EMP = M.CODIGO_EMP_DESTINO_FACOP ' +
    '  LEFT JOIN fza_facturacion_caja_periodos FP ' +
    '    ON FP.ID_FACPER = M.ID_FACPER_FACOP ' +
    ' GROUP BY M.SERIE_FAC_FACOP, M.NUMERO_FAC_FACOP, F.FECHA_FAC, ' +
    '          M.CODIGO_EMP_ORIGEN_FACOP, ' +
    '          F.RAZON_SOCIAL_EMPRESA_FAC, EO.RAZON_SOCIAL_EMP, ' +
    '          M.CODIGO_EMP_DESTINO_FACOP, ' +
    '          F.RAZON_SOCIAL_CLIENTE_FAC, ED.RAZON_SOCIAL_EMP, ' +
    '          M.ESTADO_FACOP, F.TOTAL_BASES_FAC, ' +
    '          F.TOTAL_IMPUESTOS_FAC, F.TOTAL_LIQUIDO_FAC ';
end;

// Facturas TV: no tienen fila en fza_facturas_operaciones_caja (una misma
// operación de traspaso se factura en varias), sino en el libro mayor.
function TdmFacturasProforma.ConstruirSqlFacturasTraspasoVendido: string;
begin
  Result :=
    'UNION ALL ' +
    'SELECT CONCAT(''TV-'', MIN(V.ID_FACTV)) AS CLAVE_DOCUMENTO, ' +
    '       ''TV'' AS TIPO_DOCUMENTO, ' +
    '       V.SERIE_FAC_FACTV AS SERIE_DOCUMENTO, ' +
    '       MIN(V.ID_FACPER_FACTV) AS ID_PERIODO, ' +
    '       MIN(FP.ESTADO_FACPER) AS ESTADO_PERIODO, ' +
    '       V.NUMERO_FAC_FACTV AS NUMERO_DOCUMENTO, ' +
    '       F.FECHA_FAC AS FECHA_DOCUMENTO, ' +
    '       COALESCE(MIN(FP.FECHA_DESDE_FACPER), ' +
    '                MIN(V.FECHA_VENTA_FACTV)) AS FECHA_DESDE, ' +
    '       COALESCE(MAX(FP.FECHA_HASTA_FACPER), ' +
    '                MAX(V.FECHA_VENTA_FACTV)) AS FECHA_HASTA, ' +
    '       V.CODIGO_EMP_ORIGEN_FACTV AS CODIGO_EMPRESA_ORIGEN, ' +
    '       COALESCE(NULLIF(F.RAZON_SOCIAL_EMPRESA_FAC, ''''), ' +
    '                EO.RAZON_SOCIAL_EMP) AS EMPRESA_ORIGEN, ' +
    '       V.CODIGO_EMP_DESTINO_FACTV AS CODIGO_EMPRESA_DESTINO, ' +
    '       COALESCE(NULLIF(F.RAZON_SOCIAL_CLIENTE_FAC, ''''), ' +
    '                ED.RAZON_SOCIAL_EMP) AS EMPRESA_DESTINO, ' +
    '       F.FASE_FAC AS ESTADO_DOCUMENTO, ' +
    '       F.TOTAL_BASES_FAC AS TOTAL_BASE, ' +
    '       F.TOTAL_IMPUESTOS_FAC AS TOTAL_IMPUESTOS, ' +
    '       F.TOTAL_LIQUIDO_FAC AS TOTAL_DOCUMENTO, ' +
    '       COUNT(DISTINCT V.ID_OPCAJA_TA_FACTV) ' +
    '         AS CANTIDAD_OPERACIONES, ' +
    '       COUNT(DISTINCT CASE WHEN V.TIPO_FACTV = ''DEVOLUCION'' ' +
    '                           THEN V.ID_FACTV END) AS CANTIDAD_AJUSTES ' +
    '  FROM fza_facturas_traspasos_vendidos V ' +
    '  JOIN fza_facturas F ' +
    '    ON F.SERIE_FAC = V.SERIE_FAC_FACTV ' +
    '   AND F.NUMERO_FAC = V.NUMERO_FAC_FACTV ' +
    '  LEFT JOIN fza_empresas EO ' +
    '    ON EO.CODIGO_EMP_EMP = V.CODIGO_EMP_ORIGEN_FACTV ' +
    '  LEFT JOIN fza_empresas ED ' +
    '    ON ED.CODIGO_EMP_EMP = V.CODIGO_EMP_DESTINO_FACTV ' +
    '  LEFT JOIN fza_facturacion_caja_periodos FP ' +
    '    ON FP.ID_FACPER = V.ID_FACPER_FACTV ' +
    ' GROUP BY V.SERIE_FAC_FACTV, V.NUMERO_FAC_FACTV, F.FECHA_FAC, ' +
    '          V.CODIGO_EMP_ORIGEN_FACTV, ' +
    '          F.RAZON_SOCIAL_EMPRESA_FAC, EO.RAZON_SOCIAL_EMP, ' +
    '          V.CODIGO_EMP_DESTINO_FACTV, ' +
    '          F.RAZON_SOCIAL_CLIENTE_FAC, ED.RAZON_SOCIAL_EMP, ' +
    '          F.FASE_FAC, F.TOTAL_BASES_FAC, ' +
    '          F.TOTAL_IMPUESTOS_FAC, F.TOTAL_LIQUIDO_FAC ';
end;

function TdmFacturasProforma.ConstruirSqlPeriodosPendientes: string;
begin
  Result :=
    'UNION ALL ' +
    'SELECT CONCAT(''PER-'', FP.ID_FACPER) AS CLAVE_DOCUMENTO, ' +
    '       FP.MODALIDAD_FACPER AS TIPO_DOCUMENTO, ' +
    '       '''' AS SERIE_DOCUMENTO, FP.ID_FACPER AS ID_PERIODO, ' +
    '       FP.ESTADO_FACPER AS ESTADO_PERIODO, ' +
    '       '''' AS NUMERO_DOCUMENTO, ' +
    '       FP.FECHA_HASTA_FACPER AS FECHA_DOCUMENTO, ' +
    '       FP.FECHA_DESDE_FACPER AS FECHA_DESDE, ' +
    '       FP.FECHA_HASTA_FACPER AS FECHA_HASTA, ' +
    '       FP.CODIGO_EMP_ORIGEN_FACPER AS CODIGO_EMPRESA_ORIGEN, ' +
    '       CASE WHEN FP.CODIGO_EMP_ORIGEN_FACPER IS NULL ' +
    '            THEN ''VARIAS/TODAS (legado)'' ' +
    '            ELSE EO.RAZON_SOCIAL_EMP END AS EMPRESA_ORIGEN, ' +
    '       CASE WHEN FP.MODALIDAD_FACPER = ''VE'' THEN '''' ' +
    '            ELSE FP.CODIGO_EMP_DESTINO_FACPER ' +
    '       END AS CODIGO_EMPRESA_DESTINO, ' +
    '       CASE WHEN FP.MODALIDAD_FACPER = ''VE'' THEN '''' ' +
    '            ELSE ED.RAZON_SOCIAL_EMP END AS EMPRESA_DESTINO, ' +
    '       FP.ESTADO_FACPER AS ESTADO_DOCUMENTO, ' +
    '       0 AS TOTAL_BASE, 0 AS TOTAL_IMPUESTOS, ' +
    '       0 AS TOTAL_DOCUMENTO, ' +
    '       FP.CANTIDAD_OPERACIONES_FACPER AS CANTIDAD_OPERACIONES, ' +
    '       FP.CANTIDAD_AJUSTES_FACPER AS CANTIDAD_AJUSTES ' +
    '  FROM fza_facturacion_caja_periodos FP ' +
    '  LEFT JOIN fza_empresas EO ' +
    '    ON EO.CODIGO_EMP_EMP = FP.CODIGO_EMP_ORIGEN_FACPER ' +
    '  LEFT JOIN fza_empresas ED ' +
    '    ON ED.CODIGO_EMP_EMP = FP.CODIGO_EMP_DESTINO_FACPER ' +
    ' WHERE NOT EXISTS (SELECT 1 FROM fza_proformas_caja P ' +
    '                    WHERE P.ID_FACPER_PROCAJ = FP.ID_FACPER) ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja M ' +
    '                    WHERE M.ID_FACPER_FACOP = FP.ID_FACPER) ' +
    '   AND NOT EXISTS (SELECT 1 ' +
    '                     FROM fza_facturas_traspasos_vendidos V ' +
    '                    WHERE V.ID_FACPER_FACTV = FP.ID_FACPER) ';
end;

procedure TdmFacturasProforma.AbrirDetalles;
begin
  inherited;
  AbrirEmpresas;
end;

procedure TdmFacturasProforma.AbrirEmpresasDestino(const AOrigen: string);
begin
  unqryEmpresasDestino.Close;
  unqryEmpresasDestino.SQL.Text :=
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP FROM fza_empresas ' +
    'WHERE ESACTIVO_EMP = ''S'' AND CODIGO_EMP_EMP <> :ORIGEN ' +
    'ORDER BY ORDEN_EMP, RAZON_SOCIAL_EMP';
  unqryEmpresasDestino.ParamByName('ORIGEN').AsString := AOrigen;
  unqryEmpresasDestino.Open;
end;

procedure TdmFacturasProforma.AbrirEmpresas;
begin
  if not unqryEmpresas.Active then
    unqryEmpresas.Open;
end;

function TdmFacturasProforma.CrearRepositorio(
  const AParametrosApp: IParametrosAplicacion
):
  IRepositorioFacturasProforma;
begin
  Result := TRepositorioFacturasProformaUniDAC.Create(
    unqryTablaG.Connection,
    AParametrosApp);
end;

procedure TdmFacturasProforma.RefrescarDocumentos;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh;
end;

// Migraciones de DESARROLLOS EN CURSO de las que depende la pantalla y que
// faltan en la BBDD, separadas por saltos de línea. Sin la tabla de vales
// la consulta del historial falla con el error 1146 (FZ-ISSUE-027).
function TdmFacturasProforma.ScriptsEsquemaPendientes: string;
var
  unqryEsquema: TUniQuery;
begin
  Result := '';
  unqryEsquema := TUniQuery.Create(nil);
  try
    unqryEsquema.Connection := unqryTablaG.Connection;
    unqryEsquema.SQL.Text :=
      'SELECT (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS ' +
      '         WHERE TABLE_SCHEMA = DATABASE() ' +
      '           AND TABLE_NAME = ''fza_empresas'' ' +
      '           AND COLUMN_NAME = ''CODIGO_CLI_TRASPASOS_EMP'') ' +
      '         AS EXISTE_CLIENTE_TRASPASOS, ' +
      '       (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES ' +
      '         WHERE TABLE_SCHEMA = DATABASE() ' +
      '           AND TABLE_NAME = ''fza_proformas_caja_vales'') ' +
      '         AS EXISTE_VALES';
    unqryEsquema.Open;
    if unqryEsquema.FieldByName(
      'EXISTE_CLIENTE_TRASPASOS').AsInteger = 0 then
      Result := Result + '20260927_empresas_cliente_traspasos.sql' +
        sLineBreak;
    if unqryEsquema.FieldByName('EXISTE_VALES').AsInteger = 0 then
      Result := Result + '20260927_facturacion_vales_entre_empresas.sql' +
        sLineBreak;
    Result := Trim(Result);
  finally
    FreeAndNil(unqryEsquema);
  end;
end;

initialization
  RegistrarDataModule(TdmFacturasProforma);
  ForceReferenceToClass(TdmFacturasProforma);
end.

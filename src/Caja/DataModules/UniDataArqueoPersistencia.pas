{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoPersistencia                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia del arqueo de caja: graba un TArqueoCaja completo en         }
{    fza_caja_arqueos + fza_caja_arqueos_recuento, marca las operaciones       }
{    del rango con CODIGO_ARQUEO_OPCAJA, y lee arqueos previos.                }
{******************************************************************************}
unit UniDataArqueoPersistencia;

interface

uses
  Uni,
  inLibArqueoPersistencia,
  inLibVentasWsColaIntf;

function ConsultarArqueosCambioVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta): TArray<string>;
// Participa en la transacción del guardado; no confirma por su cuenta.
procedure InvalidarArqueosCambioVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta; AEsRoot: Boolean;
  const AConfirmados: TArray<string>);

function CrearPersistenciaArqueo(
  AConexion: TUniConnection;
  const ARepositorioVentasWs: IAltaVentasWsCola = nil;
  AEnviarVentasWs: Boolean = False): IArqueoPersistencia;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.DateUtils, Data.DB, DBAccess,
  inLibArqueo, inLibMsgCaja;

function ConsultarArqueosCambioVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta): TArray<string>;
var
  oConsulta: TUniQuery;
  oCodigos: TList<string>;
  sBloqueo: string;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  oCodigos := TList<string>.Create;
  try
    oConsulta.Connection := AConexion;
    sBloqueo := '';
    if AConexion.InTransaction then
      sBloqueo := ' FOR UPDATE';
    oConsulta.SQL.Text :=
      'SELECT TOTAL_LIQUIDO_FAC FROM fza_facturas ' +
      'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO' + sBloqueo;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty and CambiaDineroArqueoVenta(
      oConsulta.Fields[0].AsCurrency, ANuevoTotal, AModo) then
    begin
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT A.CODIGO_ARQ FROM fza_caja_arqueos A ' +
        'WHERE A.FASE_ARQ = ''CERRADO'' AND EXISTS (' +
        'SELECT 1 FROM fza_caja_operaciones O ' +
        'WHERE O.SERIE_FAC_OPCAJA = :SERIE ' +
        'AND O.NUMERO_FAC_OPCAJA = :NUMERO ' +
        'AND O.CODIGO_EMP_OPCAJA = A.CODIGO_EMP_ARQ ' +
        'AND O.CODIGO_ALM_OPCAJA = A.CODIGO_ALM_ARQ ' +
        'AND O.CODIGO_CAJA_OPCAJA = A.CODIGO_CAJA_ARQ ' +
        'AND (O.CODIGO_ARQUEO_OPCAJA = A.CODIGO_ARQ OR (' +
        'O.FECHA_OPERACION_OPCAJA >= A.FECHA_DESDE_ARQ ' +
        'AND O.FECHA_OPERACION_OPCAJA <= A.FECHA_HASTA_ARQ))) ' +
        'ORDER BY A.CODIGO_ARQ' + sBloqueo;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oCodigos.Add(oConsulta.Fields[0].AsString);
        oConsulta.Next;
      end;
      Result := oCodigos.ToArray;
    end;
  finally
    oCodigos.Free;
    oConsulta.Free;
  end;
end;

procedure InvalidarArqueosCambioVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta; AEsRoot: Boolean;
  const AConfirmados: TArray<string>);
var
  aCodigos: TArray<string>;
  sCodigo, sConfirmado: string;
  bConfirmado: Boolean;
  oConsulta: TUniQuery;
begin
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create('Falta la transacción de la venta.');
  aCodigos := ConsultarArqueosCambioVenta(AConexion,
    ASerie, ANumero, ANuevoTotal, AModo);
  if (Length(aCodigos) > 0) and not AEsRoot then
    raise EInvalidOpException.Create(SArqueoVentaRequiereRoot);
  for sCodigo in aCodigos do
  begin
    bConfirmado := False;
    for sConfirmado in AConfirmados do
      bConfirmado := bConfirmado or SameText(sCodigo, sConfirmado);
    if not bConfirmado then
      raise EInvalidOpException.Create(SArqueoVentaSinConfirmar);
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    for sCodigo in aCodigos do
    begin
      oConsulta.SQL.Text :=
        'UPDATE fza_caja_operaciones SET CODIGO_ARQUEO_OPCAJA = NULL ' +
        'WHERE CODIGO_ARQUEO_OPCAJA = :ARQUEO';
      oConsulta.ParamByName('ARQUEO').AsString := sCodigo;
      oConsulta.Execute;
      oConsulta.SQL.Text :=
        'DELETE FROM fza_caja_arqueos_recuento ' +
        'WHERE CODIGO_ARQ_ARQR = :ARQUEO';
      oConsulta.ParamByName('ARQUEO').AsString := sCodigo;
      oConsulta.Execute;
      oConsulta.SQL.Text :=
        'DELETE FROM fza_caja_arqueos WHERE CODIGO_ARQ = :ARQUEO';
      oConsulta.ParamByName('ARQUEO').AsString := sCodigo;
      oConsulta.Execute;
    end;
  finally
    oConsulta.Free;
  end;
end;

const
  SQL_INSERTAR_ARQUEO =
    'INSERT INTO fza_caja_arqueos (' +
    '  CODIGO_ARQ,' +
    '  CODIGO_EMP_ARQ,' +
    '  CODIGO_ALM_ARQ,' +
    '  CODIGO_CAJA_ARQ,' +
    '  FECHA_DESDE_ARQ,' +
    '  FECHA_HASTA_ARQ,' +
    '  FASE_ARQ,' +
    '  CODIGO_EMPLEADO_ARQ,' +
    '  CANTIDAD_VENTAS_ARQ,' +
    '  CANTIDAD_OPERACIONES_ARQ,' +
    '  TOTAL_BRUTO_LINEAS_ARQ,' +
    '  TOTAL_DESCUENTOS_LINEAS_ARQ,' +
    '  TOTAL_BRUTO_OPERACIONES_ARQ,' +
    '  TOTAL_DESCUENTOS_OPERACIONES_ARQ,' +
    '  TOTAL_NETO_ARQ,' +
    '  TOTAL_VALES_RECOGIDOS_ARQ,' +
    '  TOTAL_VALES_EMITIDOS_ARQ,' +
    '  TOTAL_COBROS_CLIENTES_ARQ,' +
    '  TOTAL_PENDIENTE_COBRO_ARQ,' +
    '  TOTAL_INGRESOS_CAJA_ARQ,' +
    '  TOTAL_EFECTIVO_INGRESOS_ARQ,' +
    '  TOTAL_EFECTIVO_ENTRADAS_ARQ,' +
    '  TOTAL_EFECTIVO_SALIDAS_ARQ,' +
    '  TOTAL_EFECTIVO_ANTERIOR_ARQ,' +
    '  TOTAL_EFECTIVO_CAJA_ARQ,' +
    '  TOTAL_OTROS_INGRESOS_ARQ,' +
    '  TOTAL_SALDO_RECONTAR_ARQ,' +
    '  OBSERVACIONES_ARQ,' +
    '  INSTANTE_ALTA,' +
    '  USUARIO_ALTA,' +
    '  USUARIO_MODIF' +
    ') VALUES (' +
    '  :pCODIGO,' +
    '  :pEMP,' +
    '  :pALM,' +
    '  :pCAJA,' +
    '  :pFDESDE,' +
    '  :pFHASTA,' +
    '  ''CERRADO'',' +
    '  :pEMPLEADO,' +
    '  :pCNT_VENTAS,' +
    '  :pCNT_OPE,' +
    '  :pBRUTO_LIN,' +
    '  :pDESC_LIN,' +
    '  :pBRUTO_OPE,' +
    '  :pDESC_OPE,' +
    '  :pNETO,' +
    '  :pVALES_REC,' +
    '  :pVALES_EMI,' +
    '  :pCOBROS_CLI,' +
    '  :pPEND_COB,' +
    '  :pING_CAJA,' +
    '  :pEFT_ING,' +
    '  :pEFT_ENT,' +
    '  :pEFT_SAL,' +
    '  :pEFT_ANT,' +
    '  :pEFT_CAJA,' +
    '  :pOTROS_ING,' +
    '  :pSALDO_REC,' +
    '  :pOBS,' +
    '  NOW(),' +
    '  :pUSUARIO,' +
    '  :pUSUARIO2' +
    ')';
  SQL_COLUMNAS_OPCIONALES =
    'SELECT COLUMN_NAME' +
    '  FROM INFORMATION_SCHEMA.COLUMNS' +
    ' WHERE TABLE_SCHEMA = DATABASE()' +
    '   AND TABLE_NAME   = ''fza_caja_arqueos''' +
    '   AND COLUMN_NAME IN (' +
    '     ''TOTAL_PRESTAMOS_ARQ'',' +
    '     ''TOTAL_VENTAS_NORMALES_ARQ'',' +
    '     ''TOTAL_VENTAS_PRESTAMOS_ARQ'',' +
    '     ''TOTAL_DEVOLUCIONES_ARQ'',' +
    '     ''TOTAL_VENTAS_ARQ'',' +
    '     ''TOTAL_RECUENTO_ARQ'',' +
    '     ''DIFERENCIA_TOTAL_ARQ'',' +
    '     ''EFECTIVO_DEJADO_CAJA_ARQ'',' +
    '     ''DESGLOSE_BILLETES_ARQ'',' +
    '     ''IMPORTE_RETIRADA_ARQ'',' +
    '     ''CONCEPTO_RETIRADA_ARQ'')';
  SQL_INSERTAR_RECUENTO =
    'INSERT INTO fza_caja_arqueos_recuento (' +
    '  CODIGO_ARQ_ARQR,' +
    '  CODIGO_FP_CFP_ARQR,' +
    '  DESCRIPCION_FP_ARQR,' +
    '  ESCAJON_ARQR,' +
    '  IMPORTE_SISTEMA_ARQR,' +
    '  IMPORTE_RECUENTO_ARQR,' +
    '  DIFERENCIA_ARQR,' +
    '  INSTANTE_ALTA,' +
    '  USUARIO_ALTA,' +
    '  USUARIO_MODIF' +
    ') VALUES (' +
    '  :pARQ,' +
    '  :pFP,' +
    '  :pDESC,' +
    '  :pCAJON,' +
    '  :pSIST,' +
    '  :pREC,' +
    '  :pDIF,' +
    '  NOW(),' +
    '  :pUSUARIO,' +
    '  :pUSUARIO2' +
    ')';
  SQL_MARCAR_OPERACIONES =
    'UPDATE fza_caja_operaciones' +
    '   SET CODIGO_ARQUEO_OPCAJA = :pARQ' +
    ' WHERE CODIGO_EMP_OPCAJA    = :pEMP' +
    '   AND CODIGO_ALM_OPCAJA    = :pALM' +
    '   AND CODIGO_CAJA_OPCAJA   = :pCAJA' +
    '   AND FECHA_OPERACION_OPCAJA >= :pFDESDE' +
    '   AND FECHA_OPERACION_OPCAJA <= :pFHASTA' +
    '   AND (CODIGO_ARQUEO_OPCAJA IS NULL' +
    '        OR CODIGO_ARQUEO_OPCAJA = '''')';
  SQL_INSERTAR_RETIRADA =
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA,' +
    '  CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA,' +
    '  TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA,' +
    '  CODIGO_EMPLEADO_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA,' +
    '  ESTADO_DEVOLUCION_OPCAJA,' +
    '  CODIGO_ARQUEO_OPCAJA,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA' +
    ') VALUES (' +
    '  :EMP, :ALM, :CAJA, :NUMOP,' +
    '  ''GC'', :IMP, NOW(), CURRENT_DATE,' +
    '  :EMPL, :CONCEPTO, ''N'', :ARQ,' +
    '  :USR2, :USR3, NOW())';

type
  TPersistenciaArqueoUniDAC = class(
    TInterfacedObject,
    IArqueoPersistencia)
  private
    FConexion: TUniConnection;
    FEnviarVentasWs: Boolean;
    FRepositorioVentasWs: IAltaVentasWsCola;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ARepositorioVentasWs: IAltaVentasWsCola;
      AEnviarVentasWs: Boolean);
    procedure GrabarArqueo(
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
      AImporteRetirada: Currency;
      const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
      ACodigoEmpleado, AUsuario: string);
  end;
  TGrabacionArqueo = class
  private
    FConexion: TUniConnection;
    FEnviarVentasWs: Boolean;
    FRepositorioVentasWs: IAltaVentasWsCola;
    FArqueo: TArqueoCaja;
    FLineasRecuento: TArray<TArqueoRecuentoLinea>;
    FTotalRecuento: Currency;
    FDiferenciaTotal: Currency;
    FEfectivoDejado: Currency;
    FImporteRetirada: Currency;
    FConceptoRetirada: string;
    FDesgloseBilletes: string;
    FObservaciones: string;
    FCodigoEmpleado: string;
    FUsuario: string;
    FCodigoArqueo: string;
    FNumeroRetirada: string;
    function CrearConsulta(const ASql: string): TUniQuery;
    function ConstruirSetOpcional: string;
    procedure ReservarNumeroRetirada;
    procedure InsertarCabecera;
    procedure AsignarParametrosOpcionales(AQuery: TUniQuery);
    procedure ActualizarColumnasOpcionales;
    procedure InsertarLineasRecuento;
    procedure MarcarOperaciones;
    procedure InsertarRetirada;
    procedure EncolarCierre;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ARepositorioVentasWs: IAltaVentasWsCola;
      AEnviarVentasWs: Boolean;
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
      AImporteRetirada: Currency;
      const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
      ACodigoEmpleado, AUsuario: string);
    procedure Ejecutar;
  end;

function NuevoUuid: string;
var
  Guid: TGUID;
  sGuid: string;
begin
  CreateGUID(Guid);
  sGuid := GUIDToString(Guid);
  Result := Copy(sGuid, 2, 36);
end;

{ --------------------------------------------------------------------------- }
{   Genera CODIGO_ARQ: YYYYMMDD-NN global del día                             }
{ --------------------------------------------------------------------------- }
function GenerarCodigoArqueo(
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDate): string;
var
  Query: TUniQuery;
  sBase: string;
  iSeq: Integer;
begin
  { Formato compacto para caber en CODIGO_ARQUEO_OPCAJA (varchar(20)):
    YYYYMMDD-NN. La secuencia es global del día porque CODIGO_ARQ enlaza la
    tabla hija de recuento y no puede repetirse entre cajas. }
  sBase := FormatDateTime('yyyymmdd', AFecha);
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(SUBSTRING(CODIGO_ARQ, 10)' +
      '       AS UNSIGNED)), 0) AS ULTIMO' +
      '  FROM fza_caja_arqueos' +
      ' WHERE CODIGO_ARQ LIKE :pBASE';
    Query.ParamByName('pBASE').AsString := sBase + '%';
    Query.Open;
    iSeq := Query.FieldByName('ULTIMO').AsInteger + 1;
  finally
    FreeAndNil(Query);
  end;
  Result := sBase + '-' + Format('%.2d', [iSeq]);
end;

{ --------------------------------------------------------------------------- }
{   Graba cabecera + detalle del recuento en una transacción                  }
{ --------------------------------------------------------------------------- }
constructor TGrabacionArqueo.Create(
  AConexion: TUniConnection;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  AEnviarVentasWs: Boolean;
  const AArqueo: TArqueoCaja;
  const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
  ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
  AImporteRetirada: Currency;
  const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
  ACodigoEmpleado, AUsuario: string);
begin
  inherited Create;
  FConexion := AConexion;
  FRepositorioVentasWs := ARepositorioVentasWs;
  FEnviarVentasWs := AEnviarVentasWs;
  FArqueo := AArqueo;
  FLineasRecuento := ALineasRecuento;
  FTotalRecuento := ATotalRecuento;
  FDiferenciaTotal := ADiferenciaTotal;
  FEfectivoDejado := AEfectivoDejado;
  FImporteRetirada := AImporteRetirada;
  FConceptoRetirada := AConceptoRetirada;
  FDesgloseBilletes := ADesgloseBilletes;
  FObservaciones := AObservaciones;
  FCodigoEmpleado := ACodigoEmpleado;
  FUsuario := AUsuario;
end;

procedure TGrabacionArqueo.EncolarCierre;
var
  iIdCola: Int64;
begin
  if FEnviarVentasWs and Assigned(FRepositorioVentasWs) then
  begin
    iIdCola := FRepositorioVentasWs.EncolarEvento(
      NuevoUuid,
      'CIERRE_CAJA',
      FArqueo.Empresa,
      'CIERRE',
      FCodigoArqueo,
      FUsuario);
    if iIdCola = 0 then
      raise Exception.CreateFmt(
        SErrorEncolarCierreVentasWs,
        [FCodigoArqueo]);
  end;
end;

function TGrabacionArqueo.CrearConsulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := ASql;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TGrabacionArqueo.ReservarNumeroRetirada;
var
  oNumerador: TUniStoredProc;
begin
  FNumeroRetirada := '';
  if FImporteRetirada > 0 then
  begin
    oNumerador := TUniStoredProc.Create(nil);
    try
      oNumerador.Connection := FConexion;
      oNumerador.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
      oNumerador.Params.CreateParam(
        ftString, 'pEmpresa', ptInput).AsString := FArqueo.Empresa;
      oNumerador.Params.CreateParam(
        ftString, 'pAlmacen', ptInput).AsString := FArqueo.Almacen;
      oNumerador.Params.CreateParam(
        ftString, 'pCaja', ptInput).AsString := FArqueo.Caja;
      oNumerador.Params.CreateParam(
        ftString, 'pUsuario', ptInput).AsString := FUsuario;
      oNumerador.Params.CreateParam(
        ftString, 'pSerie', ptOutput).Size := 12;
      oNumerador.Params.CreateParam(
        ftString, 'pcont', ptOutput).Size := 20;
      oNumerador.Prepare;
      oNumerador.Execute;
      FNumeroRetirada := oNumerador.ParamByName('pcont').AsString;
    finally
      FreeAndNil(oNumerador);
    end;
  end;
end;

procedure TGrabacionArqueo.InsertarCabecera;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_INSERTAR_ARQUEO);
  try
    oConsulta.ParamByName('pCODIGO').AsString := FCodigoArqueo;
    oConsulta.ParamByName('pEMP').AsString := FArqueo.Empresa;
    oConsulta.ParamByName('pALM').AsString := FArqueo.Almacen;
    oConsulta.ParamByName('pCAJA').AsString := FArqueo.Caja;
    oConsulta.ParamByName('pFDESDE').AsDateTime := FArqueo.FechaDesde;
    oConsulta.ParamByName('pFHASTA').AsDateTime := FArqueo.FechaHasta;
    oConsulta.ParamByName('pEMPLEADO').AsString := FCodigoEmpleado;
    oConsulta.ParamByName('pCNT_VENTAS').AsInteger :=
      FArqueo.CantidadVentas;
    oConsulta.ParamByName('pCNT_OPE').AsInteger :=
      FArqueo.CantidadOperaciones;
    oConsulta.ParamByName('pBRUTO_LIN').AsCurrency := FArqueo.BrutoLineas;
    oConsulta.ParamByName('pDESC_LIN').AsCurrency :=
      FArqueo.DescuentosLineas;
    oConsulta.ParamByName('pBRUTO_OPE').AsCurrency :=
      FArqueo.BrutoOperaciones;
    oConsulta.ParamByName('pDESC_OPE').AsCurrency :=
      FArqueo.DescuentosOperaciones;
    oConsulta.ParamByName('pNETO').AsCurrency := FArqueo.Neto;
    oConsulta.ParamByName('pVALES_REC').AsCurrency :=
      FArqueo.ValesRecogidos;
    oConsulta.ParamByName('pVALES_EMI').AsCurrency :=
      FArqueo.ValesEmitidos;
    oConsulta.ParamByName('pCOBROS_CLI').AsCurrency :=
      FArqueo.CobrosClientes;
    oConsulta.ParamByName('pPEND_COB').AsCurrency :=
      FArqueo.PendienteCobro;
    oConsulta.ParamByName('pING_CAJA').AsCurrency := FArqueo.IngresosCaja;
    oConsulta.ParamByName('pEFT_ING').AsCurrency :=
      FArqueo.EfectivoIngresos;
    oConsulta.ParamByName('pEFT_ENT').AsCurrency :=
      FArqueo.EfectivoEntradas;
    oConsulta.ParamByName('pEFT_SAL').AsCurrency :=
      FArqueo.EfectivoSalidas;
    oConsulta.ParamByName('pEFT_ANT').AsCurrency :=
      FArqueo.EfectivoAnterior;
    oConsulta.ParamByName('pEFT_CAJA').AsCurrency := FArqueo.EfectivoCaja;
    oConsulta.ParamByName('pOTROS_ING').AsCurrency := FArqueo.OtrosIngresos;
    oConsulta.ParamByName('pSALDO_REC').AsCurrency := FArqueo.SaldoRecontar;
    oConsulta.ParamByName('pOBS').AsString := FObservaciones;
    oConsulta.ParamByName('pUSUARIO').AsString := FUsuario;
    oConsulta.ParamByName('pUSUARIO2').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TGrabacionArqueo.ConstruirSetOpcional: string;
var
  oConsulta: TUniQuery;
  sColumna: string;
begin
  Result := '';
  oConsulta := CrearConsulta(SQL_COLUMNAS_OPCIONALES);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if Result <> '' then
        Result := Result + ', ';
      sColumna := oConsulta.FieldByName('COLUMN_NAME').AsString;
      Result := Result + sColumna + ' = :p' + sColumna;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TGrabacionArqueo.AsignarParametrosOpcionales(
  AQuery: TUniQuery);
begin
  if AQuery.FindParam('pTOTAL_PRESTAMOS_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_PRESTAMOS_ARQ').AsCurrency :=
      FArqueo.Prestamos;
  if AQuery.FindParam('pTOTAL_VENTAS_NORMALES_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_VENTAS_NORMALES_ARQ').AsCurrency :=
      FArqueo.VentasNormales;
  if AQuery.FindParam('pTOTAL_VENTAS_PRESTAMOS_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_VENTAS_PRESTAMOS_ARQ').AsCurrency :=
      FArqueo.VentasPrestamos;
  if AQuery.FindParam('pTOTAL_DEVOLUCIONES_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_DEVOLUCIONES_ARQ').AsCurrency :=
      FArqueo.Devoluciones;
  if AQuery.FindParam('pTOTAL_VENTAS_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_VENTAS_ARQ').AsCurrency :=
      FArqueo.TotalVentas;
  if AQuery.FindParam('pTOTAL_RECUENTO_ARQ') <> nil then
    AQuery.ParamByName('pTOTAL_RECUENTO_ARQ').AsCurrency :=
      FTotalRecuento;
  if AQuery.FindParam('pDIFERENCIA_TOTAL_ARQ') <> nil then
    AQuery.ParamByName('pDIFERENCIA_TOTAL_ARQ').AsCurrency :=
      FDiferenciaTotal;
  if AQuery.FindParam('pEFECTIVO_DEJADO_CAJA_ARQ') <> nil then
    AQuery.ParamByName('pEFECTIVO_DEJADO_CAJA_ARQ').AsCurrency :=
      FEfectivoDejado;
  if AQuery.FindParam('pDESGLOSE_BILLETES_ARQ') <> nil then
    AQuery.ParamByName('pDESGLOSE_BILLETES_ARQ').AsString :=
      FDesgloseBilletes;
  if AQuery.FindParam('pIMPORTE_RETIRADA_ARQ') <> nil then
    AQuery.ParamByName('pIMPORTE_RETIRADA_ARQ').AsCurrency :=
      FImporteRetirada;
  if AQuery.FindParam('pCONCEPTO_RETIRADA_ARQ') <> nil then
    AQuery.ParamByName('pCONCEPTO_RETIRADA_ARQ').AsString :=
      FConceptoRetirada;
end;

procedure TGrabacionArqueo.ActualizarColumnasOpcionales;
var
  oConsulta: TUniQuery;
  sSet: string;
begin
  sSet := ConstruirSetOpcional;
  if sSet <> '' then
  begin
    oConsulta := CrearConsulta(
      'UPDATE fza_caja_arqueos SET ' + sSet +
      ' WHERE CODIGO_ARQ = :pCODIGO');
    try
      oConsulta.ParamByName('pCODIGO').AsString := FCodigoArqueo;
      AsignarParametrosOpcionales(oConsulta);
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TGrabacionArqueo.InsertarLineasRecuento;
var
  iLinea: Integer;
  oConsulta: TUniQuery;
begin
  for iLinea := 0 to High(FLineasRecuento) do
  begin
    oConsulta := CrearConsulta(SQL_INSERTAR_RECUENTO);
    try
      oConsulta.ParamByName('pARQ').AsString := FCodigoArqueo;
      oConsulta.ParamByName('pFP').AsString :=
        FLineasRecuento[iLinea].CodigoFP;
      oConsulta.ParamByName('pDESC').AsString :=
        FLineasRecuento[iLinea].Descripcion;
      oConsulta.ParamByName('pCAJON').AsString :=
        FLineasRecuento[iLinea].EsCajon;
      oConsulta.ParamByName('pSIST').AsCurrency :=
        FLineasRecuento[iLinea].Sistema;
      oConsulta.ParamByName('pREC').AsCurrency :=
        FLineasRecuento[iLinea].Recuento;
      oConsulta.ParamByName('pDIF').AsCurrency :=
        FLineasRecuento[iLinea].Diferencia;
      oConsulta.ParamByName('pUSUARIO').AsString := FUsuario;
      oConsulta.ParamByName('pUSUARIO2').AsString := FUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TGrabacionArqueo.MarcarOperaciones;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_MARCAR_OPERACIONES);
  try
    oConsulta.ParamByName('pARQ').AsString := FCodigoArqueo;
    oConsulta.ParamByName('pEMP').AsString := FArqueo.Empresa;
    oConsulta.ParamByName('pALM').AsString := FArqueo.Almacen;
    oConsulta.ParamByName('pCAJA').AsString := FArqueo.Caja;
    oConsulta.ParamByName('pFDESDE').AsDateTime := FArqueo.FechaDesde;
    oConsulta.ParamByName('pFHASTA').AsDateTime := FArqueo.FechaHasta;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TGrabacionArqueo.InsertarRetirada;
var
  oConsulta: TUniQuery;
begin
  if FImporteRetirada > 0 then
  begin
    oConsulta := CrearConsulta(SQL_INSERTAR_RETIRADA);
    try
      oConsulta.ParamByName('EMP').AsString := FArqueo.Empresa;
      oConsulta.ParamByName('ALM').AsString := FArqueo.Almacen;
      oConsulta.ParamByName('CAJA').AsString := FArqueo.Caja;
      oConsulta.ParamByName('NUMOP').AsString := FNumeroRetirada;
      oConsulta.ParamByName('IMP').AsCurrency := FImporteRetirada;
      // FZ-ISSUE-396: la columna de empleado lleva el vendedor del
      // cierre, no el usuario (que ya va en USUARIO_ALTA).
      oConsulta.ParamByName('EMPL').AsString := FCodigoEmpleado;
      oConsulta.ParamByName('CONCEPTO').AsString := FConceptoRetirada;
      oConsulta.ParamByName('ARQ').AsString := FCodigoArqueo;
      oConsulta.ParamByName('USR2').AsString := FUsuario;
      oConsulta.ParamByName('USR3').AsString := FUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TGrabacionArqueo.Ejecutar;
begin
  FCodigoArqueo := GenerarCodigoArqueo(
    FConexion, FArqueo.Empresa, FArqueo.Almacen, FArqueo.Caja,
    FArqueo.FechaDesde);
  ReservarNumeroRetirada;
  FConexion.StartTransaction;
  try
    InsertarCabecera;
    ActualizarColumnasOpcionales;
    InsertarLineasRecuento;
    MarcarOperaciones;
    InsertarRetirada;
    EncolarCierre;
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
end;

constructor TPersistenciaArqueoUniDAC.Create(
  AConexion: TUniConnection;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  AEnviarVentasWs: Boolean);
begin
  if AEnviarVentasWs and not Assigned(ARepositorioVentasWs) then
    raise EArgumentException.Create(
      SErrorRepositorioVentasWsNoAsignado);
  inherited Create;
  FConexion := AConexion;
  FRepositorioVentasWs := ARepositorioVentasWs;
  FEnviarVentasWs := AEnviarVentasWs;
end;

procedure TPersistenciaArqueoUniDAC.GrabarArqueo(
  const AArqueo: TArqueoCaja;
  const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
  ATotalRecuento, ADiferenciaTotal, AEfectivoDejado,
  AImporteRetirada: Currency;
  const AConceptoRetirada, ADesgloseBilletes, AObservaciones,
  ACodigoEmpleado, AUsuario: string);
var
  oGrabacion: TGrabacionArqueo;
begin
  oGrabacion := TGrabacionArqueo.Create(
    FConexion, FRepositorioVentasWs, FEnviarVentasWs,
    AArqueo, ALineasRecuento, ATotalRecuento,
    ADiferenciaTotal, AEfectivoDejado, AImporteRetirada,
    AConceptoRetirada, ADesgloseBilletes, AObservaciones,
    ACodigoEmpleado, AUsuario);
  try
    oGrabacion.Ejecutar;
  finally
    FreeAndNil(oGrabacion);
  end;
end;

function CrearPersistenciaArqueo(
  AConexion: TUniConnection;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  AEnviarVentasWs: Boolean): IArqueoPersistencia;
begin
  Result := TPersistenciaArqueoUniDAC.Create(
    AConexion,
    ARepositorioVentasWs,
    AEnviarVentasWs);
end;

end.

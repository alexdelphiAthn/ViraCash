{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasOperaciones                                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa la persistencia de las operaciones de facturas de venta:       }
{    borrado, reapertura, consolidación, efectos, movimientos y PDF.           }
{******************************************************************************}
unit UniDataFacturasOperaciones;

interface

uses
  inLibFormatoDocumentoLecturasIntf,
  Uni, inLibFacturasPersistenciaIntf;

function CrearPersistenciaFacturasUniDAC(
  AConexion: TUniConnection): TPersistenciaFacturas;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils, System.Hash, System.IOUtils, Data.DB,
  UniDataMovimientosAlmacenRecalculo, UniDataMovimientosLote;

type
  TPersistenciaFacturasUniDAC = class(
    TInterfacedObject,
    IRepositorioBorradoFactura,
    IRepositorioReaperturaFactura,
    IRepositorioConsolidacionFactura,
    IRepositorioEfectosFactura,
    IRepositorioMovimientosFactura,
    IRepositorioPdfFactura,
    IUnidadTrabajoFacturas,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function TablaEfectosExiste: Boolean;
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(AConexion: TUniConnection);
    { IUnidadTrabajoFacturas }
    procedure Ejecutar(const ATrabajo: TProc);
    { IRepositorioBorradoFactura }
    function TieneEfectosCobrados(
      const ASerie, ANumero: string): Boolean;
    procedure DesvincularAlbaranes(
      const ASerie, ANumero, AUsuario: string);
    procedure BorrarEfectos(
      const ASerie, ANumero: string);
    procedure BorrarLineas(
      const ASerie, ANumero: string);
    procedure BorrarRecibos(
      const ASerie, ANumero: string);
    { IRepositorioReaperturaFactura }
    function CargarDatosReapertura(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosFacturaReapertura;
    procedure AparcarAltaEnCola(
      const ASerie, ANumero, AUsuario: string);
    procedure MarcarComoBorrador(
      const ASerie, ANumero, AUsuario: string);
    { IRepositorioConsolidacionFactura }
    function CargarDatosConsolidacion(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosFacturaConsolidacion;
    { IRepositorioEfectosFactura }
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function GenerarDesdeFactura(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
    { IRepositorioMovimientosFactura }
    function CargarLineas(
      const ASerie, ANumero: string): TLineasFacturaMovimientos;
    function BuscarMovimientoExistente(
      const ATipoDocumento, ASerie, ANumero, ALinea: string): string;
    procedure InsertarMovimiento(
      const ADatos: TInsercionMovimientoFactura);
    procedure ActualizarLineaMovimiento(
      const ASerie, ANumero, ALinea, ANumeroMovimiento,
        AUsuario: string);
    procedure RecalcularDocumento(
      const ATipo, ASerie, ANumero: string);
    { IRepositorioPdfFactura }
    function GuardarPdf(
      const ASerie, ANumero, ARutaPdf, AFormato,
        AUsuario: string): Boolean;
  end;

function TPersistenciaFacturasUniDAC.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TPersistenciaFacturasUniDAC.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TPersistenciaFacturasUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

procedure TPersistenciaFacturasUniDAC.Ejecutar(
  const ATrabajo: TProc);
var
  bTransaccionPropia: Boolean;
begin
  if not Assigned(ATrabajo) then
    raise EArgumentNilException.Create('ATrabajo');
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    ATrabajo();
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Commit;
  except
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function TPersistenciaFacturasUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

{ IRepositorioBorradoFactura }

function TPersistenciaFacturasUniDAC.TablaEfectosExiste: Boolean;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM INFORMATION_SCHEMA.TABLES ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_efectos_venta''';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

function TPersistenciaFacturasUniDAC.TieneEfectosCobrados(
  const ASerie, ANumero: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if TablaEfectosExiste then
  begin
    Qry := NuevaConsulta;
    try
      Qry.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_efectos_venta ' +
        ' WHERE SERIE_FAC_EFV = :serie ' +
        '   AND NUMERO_FAC_EFV = :numero ' +
        '   AND (COALESCE(IMPORTE_COBRADO_EFV, 0) > 0.0001 ' +
        '    OR COALESCE(ESCONCILIADO_EFV, ''N'') = ''S'' ' +
        '    OR COALESCE(SERIE_REMV_EFV, '''') <> '''' ' +
        '    OR COALESCE(NUMERO_REMV_EFV, '''') <> '''' ' +
        '    OR COALESCE(ESTADO_EFV, '''') IN ' +
        '       (''COBRADO'', ''REMESADO'', ''CONCILIADO''))';
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.Open;
      Result := Qry.FieldByName('N').AsInteger > 0;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TPersistenciaFacturasUniDAC.DesvincularAlbaranes(
  const ASerie, ANumero, AUsuario: string);
var
  Afectados, Qry: TUniQuery;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create('Falta la transaccion de borrado.');
  Afectados := NuevaConsulta;
  Qry := NuevaConsulta;
  try
    Afectados.SQL.Text :=
      'SELECT A.SERIE_ALB, A.NUMERO_ALB FROM fza_albaranes A ' +
      'WHERE (A.SERIE_FAC_ALB=:SERIE AND A.NUMERO_FAC_ALB=:NUMERO) ' +
      'OR EXISTS (SELECT 1 FROM fza_albaranes_lineas L ' +
      'WHERE L.SERIE_ALB_ALBLIN=A.SERIE_ALB ' +
      'AND L.NUMERO_ALB_ALBLIN=A.NUMERO_ALB ' +
      'AND L.SERIE_FAC_ALBLIN=:SERIE AND L.NUMERO_FAC_ALBLIN=:NUMERO) ' +
      'ORDER BY A.SERIE_ALB, A.NUMERO_ALB FOR UPDATE';
    Afectados.ParamByName('SERIE').AsString := ASerie;
    Afectados.ParamByName('NUMERO').AsString := ANumero;
    Afectados.Open;
    Qry.SQL.Text :=
      'UPDATE fza_albaranes_lineas SET ESFACTURADA_ALBLIN=''N'', ' +
      'SERIE_FAC_ALBLIN=NULL, NUMERO_FAC_ALBLIN=NULL, ' +
      'LINEA_FAC_ALBLIN=NULL, ' +
      'INSTANTE_MODIF=NOW(), USUARIO_MODIF=:USUARIO ' +
      'WHERE SERIE_FAC_ALBLIN=:SERIE AND NUMERO_FAC_ALBLIN=:NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ExecSQL;
    Qry.SQL.Text :=
      'UPDATE fza_albaranes A SET ' +
      'A.SERIE_FAC_ALB=CASE WHEN A.SERIE_FAC_ALB=:SERIE ' +
      'AND A.NUMERO_FAC_ALB=:NUMERO THEN NULL ELSE A.SERIE_FAC_ALB END, ' +
      'A.NUMERO_FAC_ALB=CASE WHEN A.SERIE_FAC_ALB IS NULL ' +
      'THEN NULL ELSE A.NUMERO_FAC_ALB END, ' +
      'A.ESTADO_ALB=CASE WHEN A.ESTADO_ALB=''CANCELADO'' ' +
      'THEN A.ESTADO_ALB WHEN EXISTS (' +
      'SELECT 1 FROM fza_albaranes_lineas L ' +
      'WHERE L.SERIE_ALB_ALBLIN=A.SERIE_ALB ' +
      'AND L.NUMERO_ALB_ALBLIN=A.NUMERO_ALB ' +
      'AND L.ESFACTURADA_ALBLIN=''S'') THEN ''PARCIAL'' ' +
      'ELSE ''ABIERTO'' END, A.INSTANTE_MODIF=NOW(), ' +
      'A.USUARIO_MODIF=:USUARIO ' +
      'WHERE A.SERIE_ALB=:ALB_SERIE AND A.NUMERO_ALB=:ALB_NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    while not Afectados.Eof do
    begin
      Qry.ParamByName('ALB_SERIE').AsString :=
        Afectados.FieldByName('SERIE_ALB').AsString;
      Qry.ParamByName('ALB_NUMERO').AsString :=
        Afectados.FieldByName('NUMERO_ALB').AsString;
      Qry.ExecSQL;
      Afectados.Next;
    end;
  finally
    Qry.Free;
    Afectados.Free;
  end;
end;

procedure TPersistenciaFacturasUniDAC.BorrarEfectos(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  if TablaEfectosExiste then
  begin
    Qry := NuevaConsulta;
    try
      Qry.SQL.Text :=
        'DELETE FROM fza_efectos_venta ' +
        ' WHERE SERIE_FAC_EFV = :serie ' +
        '   AND NUMERO_FAC_EFV = :numero';
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TPersistenciaFacturasUniDAC.BorrarLineas(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'DELETE FROM fza_facturas_lineas ' +
      ' WHERE SERIE_FAC_FACLIN = :serie ' +
      '   AND NUMERO_FAC_FACLIN = :numero';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TPersistenciaFacturasUniDAC.BorrarRecibos(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'DELETE FROM fza_recibos ' +
      ' WHERE SERIE_FAC_REC = :serie ' +
      '   AND NUMERO_FAC_REC = :numero';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

{ IRepositorioReaperturaFactura }

function TPersistenciaFacturasUniDAC.CargarDatosReapertura(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosFacturaReapertura;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosFacturaReapertura);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'SELECT FASE_FAC, ESCONSOLIDADA_FAC ' +
      '  FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero';
    if ABloquear then
      Qry.SQL.Add(' FOR UPDATE');
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.Consolidada := SameText(
        Qry.FieldByName('ESCONSOLIDADA_FAC').AsString,
        'S');
    end;
    Qry.Close;
    if Result.Encontrada and
       (not Result.Consolidada) and
       (Trim(Result.Fase) <> '') and
       (not SameText(Result.Fase, 'BORRADOR')) then
    begin
      Qry.SQL.Text :=
        'SELECT ESTADO_VFCOLA ' +
        '  FROM fza_verifactu_cola ' +
        ' WHERE SERIE_FAC_VFCOLA = :serie ' +
        '   AND NUMERO_FAC_VFCOLA = :numero ' +
        '   AND TIPO_OPERACION_VFCOLA = ''ALTA''';
      if ABloquear then
        Qry.SQL.Add(' FOR UPDATE');
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        Result.EstadoCola :=
          Qry.FieldByName('ESTADO_VFCOLA').AsString;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TPersistenciaFacturasUniDAC.AparcarAltaEnCola(
  const ASerie, ANumero, AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'UPDATE fza_verifactu_cola ' +
      '   SET ESTADO_VFCOLA = ''ERROR'', ' +
      '       CONTADOR_INTENTOS_VFCOLA = 999999, ' +
      '       MENSAJE_ERROR_VFCOLA = ''Lanzamiento anulado ' +
      'por el usuario: borrador devuelto a BORRADOR'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC_VFCOLA = :serie ' +
      '   AND NUMERO_FAC_VFCOLA = :numero ' +
      '   AND TIPO_OPERACION_VFCOLA = ''ALTA''';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TPersistenciaFacturasUniDAC.MarcarComoBorrador(
  const ASerie, ANumero, AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET FASE_FAC = ''BORRADOR'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero ' +
      '   AND ESCONSOLIDADA_FAC <> ''S''';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

{ IRepositorioConsolidacionFactura }

function TPersistenciaFacturasUniDAC.CargarDatosConsolidacion(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosFacturaConsolidacion;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosFacturaConsolidacion);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'SELECT FASE_FAC, TIPO_FAC, NIF_CLIENTE_FAC, ' +
      '       CODIGO_EMP_FAC, CODIGO_CLI_FAC, CODIGO_CAJA_FAC, ' +
      '       NUMERO_OPERACION_FAC, FECHA_FAC, ESMUEVE_STOCK_FAC, ' +
      '       TIPO_OPER_VFACTU_FAC, CODIGO_PAI_CLIENTE_FAC, ' +
      '       TOTAL_IMPUESTOS_FAC, ' +
      '       (SELECT COUNT(*) ' +
      '          FROM fza_facturas_lineas l ' +
      '         WHERE l.SERIE_FAC_FACLIN = :serie_lineas ' +
      '           AND l.NUMERO_FAC_FACLIN = :numero_lineas) ' +
      '         AS NUMERO_LINEAS ' +
      '  FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero';
    if ABloquear then
      Qry.SQL.Add(' FOR UPDATE');
    Qry.ParamByName('serie_lineas').AsString := ASerie;
    Qry.ParamByName('numero_lineas').AsString := ANumero;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.TipoFactura := Qry.FieldByName('TIPO_FAC').AsString;
      Result.NifCliente :=
        Qry.FieldByName('NIF_CLIENTE_FAC').AsString;
      Result.Empresa := Qry.FieldByName('CODIGO_EMP_FAC').AsString;
      Result.Cliente := Qry.FieldByName('CODIGO_CLI_FAC').AsString;
      Result.Caja := Qry.FieldByName('CODIGO_CAJA_FAC').AsString;
      Result.NumeroOperacion :=
        Qry.FieldByName('NUMERO_OPERACION_FAC').AsString;
      Result.Fecha := Qry.FieldByName('FECHA_FAC').AsDateTime;
      Result.MueveStock := SameText(
        Qry.FieldByName('ESMUEVE_STOCK_FAC').AsString,
        'S');
      Result.NumeroLineas :=
        Qry.FieldByName('NUMERO_LINEAS').AsInteger;
      Result.TipoOperacion :=
        Qry.FieldByName('TIPO_OPER_VFACTU_FAC').AsString;
      Result.CodigoPaisCliente :=
        Qry.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString;
      Result.TotalImpuestos :=
        Qry.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

{ IRepositorioEfectosFactura }

procedure TPersistenciaFacturasUniDAC.EstamparBancoRecibos(
  const ASerie, ANumero, ACodigoBanco, AIban: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'UPDATE fza_recibos ' +
      '   SET CODIGO_EMPBAN_REC = :banco, ' +
      '       IBAN_EMP_REC = :iban ' +
      ' WHERE SERIE_FAC_REC = :serie ' +
      '   AND NUMERO_FAC_REC = :numero';
    Qry.ParamByName('banco').AsString := ACodigoBanco;
    Qry.ParamByName('iban').AsString := AIban;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

function TPersistenciaFacturasUniDAC.BancoDefectoCliente(
  const ACodigoCliente: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'SELECT CODIGO_EMPBAN_CLI ' +
      '  FROM fza_clientes ' +
      ' WHERE CODIGO_CLI_CLI = :cliente';
    Qry.ParamByName('cliente').AsString := ACodigoCliente;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('CODIGO_EMPBAN_CLI').AsString;
  finally
    FreeAndNil(Qry);
  end;
end;

function TPersistenciaFacturasUniDAC.GenerarDesdeFactura(
  const ASerie, ANumero, AUsuario,
  ACodigoBanco, AIban: string): Integer;
var
  Procedimiento: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_EFV_GENERAR_DESDE_FACTURA';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_EMPBAN',
      ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_IBAN_EMP', ptInput);
    Procedimiento.Params.CreateParam(
      ftInteger,
      'p_RESULTADO',
      ptOutput);
    Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
    Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
    Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    Procedimiento.ParamByName('p_CODIGO_EMPBAN').AsString :=
      ACodigoBanco;
    Procedimiento.ParamByName('p_IBAN_EMP').AsString := AIban;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TPersistenciaFacturasUniDAC.RegistrarCobro(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  AFecha: TDateTime;
  AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  Procedimiento: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_EFV_CONCILIAR_COBRO';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    Procedimiento.Params.CreateParam(ftInteger, 'p_NUM_EFV', ptInput);
    Procedimiento.Params.CreateParam(ftDate, 'p_FECHA', ptInput);
    Procedimiento.Params.CreateParam(ftFloat, 'p_IMPORTE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_TIPO', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_REFERENCIA', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_ENTIDAD', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(
      ftInteger,
      'p_RESULTADO',
      ptOutput);
    Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
    Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
    Procedimiento.ParamByName('p_NUM_EFV').AsInteger := ANumeroEfecto;
    Procedimiento.ParamByName('p_FECHA').AsDateTime := AFecha;
    Procedimiento.ParamByName('p_IMPORTE').AsFloat := AImporte;
    Procedimiento.ParamByName('p_TIPO').AsString := ATipo;
    Procedimiento.ParamByName('p_REFERENCIA').AsString := AReferencia;
    Procedimiento.ParamByName('p_ENTIDAD').AsString := '';
    Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TPersistenciaFacturasUniDAC.CambiarEstado(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  const AEstado: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'UPDATE fza_efectos_venta ' +
      '   SET ESTADO_EFV = :estado, ' +
      '       FECHA_COBRO_EFV = CASE ' +
      '         WHEN :estado = ''PENDIENTE'' THEN NULL ' +
      '         WHEN :estado = ''DEVUELTO'' THEN NULL ' +
      '         ELSE FECHA_COBRO_EFV END, ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC_EFV = :serie ' +
      '   AND NUMERO_FAC_EFV = :numero ' +
      '   AND NUMERO_EFV = :efecto ' +
      '   AND COALESCE(IMPORTE_COBRADO_EFV, 0) <= 0.0001 ' +
      '   AND COALESCE(ESCONCILIADO_EFV, ''N'') <> ''S''';
    Qry.ParamByName('estado').AsString := AEstado;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('efecto').AsInteger := ANumeroEfecto;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

{ IRepositorioMovimientosFactura }

function TPersistenciaFacturasUniDAC.CargarLineas(
  const ASerie, ANumero: string): TLineasFacturaMovimientos;
var
  iLinea: Integer;
  Qry: TUniQuery;
begin
  SetLength(Result, 0);
  Qry := NuevaConsulta;
  try
    // La línea sin almacén propio hereda el de la cabecera, como en
    // albaranes; sin él el movimiento de stock no se puede bloquear.
    Qry.SQL.Text :=
      'SELECT L.LINEA_FACLIN, L.CODIGO_UNIDAD_FACLIN, ' +
      '       L.CODIGO_ART_FACLIN, L.CANTIDAD_FACLIN, ' +
      '       COALESCE(NULLIF(TRIM(L.CODIGO_ALM_FACLIN), ''''), ' +
      '                TRIM(F.CODIGO_ALM_FAC), '''') ' +
      '         AS CODIGO_ALM_FACLIN, ' +
      '       L.NUMERO_MOV_FACLIN, L.LOTE_FACLIN, ' +
      '       L.FECHA_CADUCIDAD_FACLIN ' +
      '  FROM fza_facturas_lineas L ' +
      '  LEFT JOIN fza_facturas F ' +
      '    ON F.SERIE_FAC = L.SERIE_FAC_FACLIN ' +
      '   AND F.NUMERO_FAC = L.NUMERO_FAC_FACLIN ' +
      ' WHERE L.NUMERO_FAC_FACLIN = :numero ' +
      '   AND L.SERIE_FAC_FACLIN = :serie ' +
      ' ORDER BY L.LINEA_FACLIN';
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.Open;
    SetLength(Result, Qry.RecordCount);
    iLinea := 0;
    while not Qry.Eof do
    begin
      Result[iLinea].Linea :=
        Qry.FieldByName('LINEA_FACLIN').AsString;
      Result[iLinea].Sku :=
        Trim(Qry.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
      Result[iLinea].Articulo :=
        Qry.FieldByName('CODIGO_ART_FACLIN').AsString;
      Result[iLinea].Almacen :=
        Qry.FieldByName('CODIGO_ALM_FACLIN').AsString;
      Result[iLinea].Cantidad :=
        Qry.FieldByName('CANTIDAD_FACLIN').AsFloat;
      Result[iLinea].NumeroMovimiento :=
        Qry.FieldByName('NUMERO_MOV_FACLIN').AsString;
      Result[iLinea].Lote := Qry.FieldByName('LOTE_FACLIN').AsString;
      Result[iLinea].FechaCaducidad := 0;
      if not Qry.FieldByName('FECHA_CADUCIDAD_FACLIN').IsNull then
        Result[iLinea].FechaCaducidad :=
          Trunc(Qry.FieldByName('FECHA_CADUCIDAD_FACLIN').AsDateTime);
      Inc(iLinea);
      Qry.Next;
    end;
    SetLength(Result, iLinea);
  finally
    FreeAndNil(Qry);
  end;
end;

function TPersistenciaFacturasUniDAC.BuscarMovimientoExistente(
  const ATipoDocumento, ASerie, ANumero, ALinea: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'SELECT NUMERO_MOV ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV IN (:tipo_documento, ''VE'') ' +
      '   AND SERIE_DOC_MOV = :serie ' +
      '   AND NUMERO_DOC_MOV = :numero ' +
      '   AND LINEA_MOV = :linea ' +
      ' ORDER BY CASE TIPO_DOC_MOV ' +
      '          WHEN ''VE'' THEN 0 ELSE 1 END, NUMERO_MOV ' +
      ' LIMIT 1';
    Qry.ParamByName('tipo_documento').AsString := ATipoDocumento;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('linea').AsString := ALinea;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('NUMERO_MOV').AsString;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TPersistenciaFacturasUniDAC.InsertarMovimiento(
  const ADatos: TInsercionMovimientoFactura);
var
  QryFecha: TUniQuery;
  Procedimiento: TUniStoredProc;
  ProcedimientoLote: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  ProcedimientoLote := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName :=
      'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(
      ftString,
      'p_NUMERO_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_TIPO_DOC_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_SERIE_DOC_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_NRO_DOC_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_LINEA_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_EMPRESA_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_ALMACEN_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_ALMACEN_CONTRA_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_UNIDAD_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_TIPO_MOVIMIENTO_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftBCD,
      'p_CANTIDAD_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftBCD,
      'p_PRECIO_MEDIO_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftBCD,
      'p_TOTAL_COSTE_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_USUARIO',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_ALMACEN_DOC',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_NUMOP_DOC',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_CAJA_DOC_MOV',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODCLIENTE',
      ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODARTICULO',
      ptInput);
    Procedimiento.ParamByName('p_NUMERO_MOV').AsString :=
      ADatos.NumeroMovimiento;
    Procedimiento.ParamByName('p_TIPO_DOC_MOV').AsString :=
      ADatos.TipoDocumento;
    Procedimiento.ParamByName('p_SERIE_DOC_MOV').AsString :=
      ADatos.Serie;
    Procedimiento.ParamByName('p_NRO_DOC_MOV').AsString :=
      ADatos.Numero;
    Procedimiento.ParamByName('p_LINEA_MOV').AsString :=
      ADatos.Linea;
    Procedimiento.ParamByName('p_CODIGO_EMPRESA_MOV').AsString :=
      ADatos.Empresa;
    Procedimiento.ParamByName('p_CODIGO_ALMACEN_MOV').AsString :=
      ADatos.Almacen;
    Procedimiento.ParamByName(
      'p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
    Procedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString :=
      ADatos.Sku;
    Procedimiento.ParamByName(
      'p_TIPO_MOVIMIENTO_MOV').AsString :=
        ADatos.TipoMovimiento;
    Procedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat :=
      ADatos.Cantidad;
    Procedimiento.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat := 0;
    Procedimiento.ParamByName('p_TOTAL_COSTE_MOV').AsFloat := 0;
    Procedimiento.ParamByName('p_USUARIO').AsString :=
      ADatos.Usuario;
    Procedimiento.ParamByName('p_ALMACEN_DOC').AsString :=
      ADatos.Almacen;
    Procedimiento.ParamByName('p_NUMOP_DOC').AsString :=
      ADatos.NumeroOperacion;
    Procedimiento.ParamByName(
      'p_CODIGO_CAJA_DOC_MOV').AsString := ADatos.Caja;
    Procedimiento.ParamByName('p_CODCLIENTE').AsString :=
      ADatos.Cliente;
    Procedimiento.ParamByName('p_CODARTICULO').AsString :=
      ADatos.Articulo;
    // F-LOTEC-016: con lote o serie, ..._INSERT_LOTE.
    EjecutarMovimientoConLote(Procedimiento, ProcedimientoLote, ADatos.Lote,
      ADatos.FechaCaducidad);
    if ADatos.Fecha > 0 then
    begin
      QryFecha := NuevaConsulta;
      try
        QryFecha.SQL.Text :=
          'UPDATE fza_movimientos_almacen ' +
          '   SET FECHA_MOV = :fecha ' +
          ' WHERE NUMERO_MOV = :numero';
        QryFecha.ParamByName('fecha').AsDateTime := ADatos.Fecha;
        QryFecha.ParamByName('numero').AsString :=
          ADatos.NumeroMovimiento;
        QryFecha.ExecSQL;
      finally
        FreeAndNil(QryFecha);
      end;
    end;
  finally
    FreeAndNil(ProcedimientoLote);
    FreeAndNil(Procedimiento);
  end;
end;

procedure TPersistenciaFacturasUniDAC.RecalcularDocumento(
  const ATipo, ASerie, ANumero: string);
begin
  RecalcularMovimientosDocumento(FConexion, ATipo, ASerie, ANumero);
end;

procedure TPersistenciaFacturasUniDAC.ActualizarLineaMovimiento(
  const ASerie, ANumero, ALinea, ANumeroMovimiento,
    AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      'UPDATE fza_facturas_lineas ' +
      '   SET NUMERO_MOV_FACLIN = :movimiento, ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC_FACLIN = :serie ' +
      '   AND NUMERO_FAC_FACLIN = :numero ' +
      '   AND LINEA_FACLIN = :linea';
    Qry.ParamByName('movimiento').AsString := ANumeroMovimiento;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('linea').AsString := ALinea;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

{ IRepositorioPdfFactura }

function TPersistenciaFacturasUniDAC.GuardarPdf(
  const ASerie, ANumero, ARutaPdf, AFormato,
    AUsuario: string): Boolean;
var
  iTamano: Int64;
  Qry: TUniQuery;
  sHuella: string;
begin
  iTamano := TFile.GetSize(ARutaPdf);
  sHuella := UpperCase(THashSHA2.GetHashStringFromFile(ARutaPdf));
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET PDF_FAC = :PDF, ' +
      '     NOMBRE_PDF_FAC = :NOMBRE, ' +
      '     TAMANO_PDF_FAC = :TAMANO, ' +
      '     HUELLA_PDF_FAC = :HUELLA, ' +
      '     INSTANTE_PDF_FAC = NOW(), ' +
      '     FORMATO_PDF_FAC = :FORMATO, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE SERIE_FAC  = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('PDF').LoadFromFile(ARutaPdf, ftBlob);
    Qry.ParamByName('NOMBRE').AsString := ExtractFileName(ARutaPdf);
    Qry.ParamByName('TAMANO').AsLargeInt := iTamano;
    Qry.ParamByName('HUELLA').AsString := sHuella;
    Qry.ParamByName('FORMATO').AsString := AFormato;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

function CrearPersistenciaFacturasUniDAC(
  AConexion: TUniConnection): TPersistenciaFacturas;
var
  oAdaptador: TPersistenciaFacturasUniDAC;
begin
  oAdaptador := TPersistenciaFacturasUniDAC.Create(AConexion);
  Result.UnidadTrabajo := oAdaptador;
  Result.Borrado := oAdaptador;
  Result.Reapertura := oAdaptador;
  Result.Consolidacion := oAdaptador;
  Result.Efectos := oAdaptador;
  Result.Movimientos := oAdaptador;
  Result.Pdf := oAdaptador;
end;

end.

{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFacturacionAlbaranesCompraRepositorio                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para agrupar albaranes en facturas de compra.        }
{******************************************************************************}
unit UniDataFacturacionAlbaranesCompraRepositorio;

interface

uses
  Uni, inLibFacturacionAlbaranesCompraPersistenciaIntf,
  inLibOpcionesDocumentoIntf;

function CrearRepositorioFacturacionAlbaranesCompraUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;

implementation

uses
  System.SysUtils, Data.DB, DBAccess, UniDataProveedoresTexto;

const
  SQL_ALBARANES_PENDIENTES =
    'SELECT NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, REF_PROVEEDOR_ALBC, ' +
    'RAZON_SOCIAL_PRV_ALBC, TOTAL_LIQUIDO_ALBC, ESTADO_ALBC, ' +
    'CODIGO_ALM_ALBC, FORMA_PAGO_ALBC ' +
    'FROM fza_albaranes_compra WHERE CODIGO_EMP_ALBC = :EMP ' +
    'AND CODIGO_PRV_ALBC = :PRV AND COALESCE(ESTADO_ALBC, '''') ' +
    'NOT IN (''FACTURADO'', ''CANCELADO'') ' +
    'ORDER BY FECHA_ALBC, NUMERO_ALBC';
  SQL_EMPRESAS =
    'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP';
  SQL_PROVEEDORES =
    'SELECT * FROM fza_proveedores ORDER BY ' +
    SQL_NOMBRE_MOSTRADO_PRV + ', CODIGO_PRV_PRV';
  SQL_NOMBRE_PROVEEDOR =
    'SELECT ' + SQL_COLUMNA_NOMBRE_MOSTRADO_PRV +
    ' FROM fza_proveedores WHERE CODIGO_PRV_PRV = :PRV';
  SQL_FORMA_PAGO_PROVEEDOR =
    'SELECT CODIGO_FP_PRV FROM fza_proveedores ' +
    ' WHERE CODIGO_PRV_PRV = :PRV';
  SQL_FACTURAS_ABIERTAS =
    'SELECT SERIE_FACC, NUMERO_FACC, FECHA_FACC ' +
    'FROM fza_facturas_compra WHERE CODIGO_EMP_FACC = :EMP ' +
    'AND CODIGO_PRV_FACC = :PRV AND COALESCE(ESTADO_FACC, '''') ' +
    'IN (''ABIERTA'', ''CERRADA'') ' +
    'ORDER BY FECHA_FACC DESC, NUMERO_FACC DESC';

type
  TConsultaFacturacionAlbaranesCompraUniDAC = class(
    TInterfacedObject,
    IConsultaFacturacionAlbaranesCompra)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioFacturacionAlbaranesCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturacionAlbaranesCompra)
  private
    FConexion: TUniConnection;
    FProcedimiento: TUniStoredProc;
    FProcedimientoOpciones: TUniStoredProc;
    procedure DefinirParametrosProcedimiento;
    procedure DefinirParametrosProcedimientoOpciones;
    function NuevaConsulta: TUniQuery;
    function AbrirConsulta(
      const ASql: string): IConsultaFacturacionAlbaranesCompra;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function ConsultarAlbaranesPendientes(
      const AEmpresa, AProveedor: string
    ): IConsultaFacturacionAlbaranesCompra;
    function ConsultarEmpresas: IConsultaFacturacionAlbaranesCompra;
    function ConsultarProveedores: IConsultaFacturacionAlbaranesCompra;
    function BuscarNombreProveedor(const AProveedor: string): string;
    function ListarFacturasAbiertas(
      const AEmpresa, AProveedor: string): TFacturasCompraAbiertas;
    function FacturarAlbaran(
      const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
      ANumeroFactura, AUsuario: string
    ): TResultadoFacturacionAlbaranCompra;
    function FacturarAlbaranConOpciones(
      const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
      ANumeroFactura: string; const AOpciones: TOpcionesDocumento;
      const AUsuario: string
    ): TResultadoFacturacionAlbaranCompra;
    function BuscarFormaPagoProveedor(const AProveedor: string): string;
    procedure ProponerReferenciaProveedor(
      const ASerie, ANumero, AUsuario: string);
  end;

constructor TConsultaFacturacionAlbaranesCompraUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaFacturacionAlbaranesCompraUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaFacturacionAlbaranesCompraUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioFacturacionAlbaranesCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FProcedimiento := TUniStoredProc.Create(nil);
  FProcedimiento.Connection := FConexion;
  FProcedimiento.StoredProcName := 'PRC_FACC_FACTURAR_ALBARAN';
  DefinirParametrosProcedimiento;
  FProcedimientoOpciones := TUniStoredProc.Create(nil);
  FProcedimientoOpciones.Connection := FConexion;
  FProcedimientoOpciones.StoredProcName :=
    'PRC_FACC_FACTURAR_ALBARAN_OPCIONES';
  DefinirParametrosProcedimientoOpciones;
end;

destructor TRepositorioFacturacionAlbaranesCompraUniDAC.Destroy;
begin
  FreeAndNil(FProcedimientoOpciones);
  FreeAndNil(FProcedimiento);
  inherited;
end;

procedure TRepositorioFacturacionAlbaranesCompraUniDAC.
  DefinirParametrosProcedimiento;
begin
  FProcedimiento.Params.Clear;
  FProcedimiento.Params.CreateParam(
    ftString, 'p_SERIE_ALB', ptInput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_ALB', ptInput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_SERIE_FAC', ptInput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_FAC', ptInput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_USUARIO', ptInput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_SERIE_FAC_OUT', ptOutput);
  FProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_FAC_OUT', ptOutput);
  FProcedimiento.Params.CreateParam(
    ftInteger, 'p_RESULTADO', ptOutput);
end;

procedure TRepositorioFacturacionAlbaranesCompraUniDAC.
  DefinirParametrosProcedimientoOpciones;
var
  oParams: TParams;
begin
  oParams := FProcedimientoOpciones.Params;
  oParams.Clear;
  oParams.CreateParam(ftString, 'p_SERIE_ALB', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_FAC', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_NUEVA', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_MANUAL', ptInput);
  oParams.CreateParam(ftDate, 'p_FECHA', ptInput);
  oParams.CreateParam(ftString, 'p_FORMA_PAGO', ptInput);
  oParams.CreateParam(ftString, 'p_ALMACEN', ptInput);
  oParams.CreateParam(ftString, 'p_USUARIO', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_FAC_OUT', ptOutput);
  oParams.CreateParam(ftString, 'p_NUMERO_FAC_OUT', ptOutput);
  oParams.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.AbrirConsulta(
  const ASql: string): IConsultaFacturacionAlbaranesCompra;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := ASql;
    Consulta.Open;
    Result := TConsultaFacturacionAlbaranesCompraUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.
  ConsultarAlbaranesPendientes(
  const AEmpresa, AProveedor: string
): IConsultaFacturacionAlbaranesCompra;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_ALBARANES_PENDIENTES;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('PRV').AsString := AProveedor;
    Consulta.Open;
    Result := TConsultaFacturacionAlbaranesCompraUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.ConsultarEmpresas:
  IConsultaFacturacionAlbaranesCompra;
begin
  Result := AbrirConsulta(SQL_EMPRESAS);
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.ConsultarProveedores:
  IConsultaFacturacionAlbaranesCompra;
begin
  Result := AbrirConsulta(SQL_PROVEEDORES);
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.BuscarNombreProveedor(
  const AProveedor: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_NOMBRE_PROVEEDOR;
    Consulta.ParamByName('PRV').AsString := AProveedor;
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.FieldByName(
        CAMPO_NOMBRE_MOSTRADO_PRV).AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.ListarFacturasAbiertas(
  const AEmpresa, AProveedor: string): TFacturasCompraAbiertas;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_FACTURAS_ABIERTAS;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('PRV').AsString := AProveedor;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion].Serie :=
        Consulta.FieldByName('SERIE_FACC').AsString;
      Result[Posicion].Numero :=
        Consulta.FieldByName('NUMERO_FACC').AsString;
      Result[Posicion].Fecha :=
        Consulta.FieldByName('FECHA_FACC').AsDateTime;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.FacturarAlbaran(
  const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
  ANumeroFactura, AUsuario: string
): TResultadoFacturacionAlbaranCompra;
begin
  FProcedimiento.ParamByName('p_SERIE_ALB').AsString := ASerieAlbaran;
  FProcedimiento.ParamByName('p_NUMERO_ALB').AsString := ANumeroAlbaran;
  FProcedimiento.ParamByName('p_SERIE_FAC').AsString := ASerieFactura;
  FProcedimiento.ParamByName('p_NUMERO_FAC').AsString := ANumeroFactura;
  FProcedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
  FProcedimiento.ExecProc;
  Result.Procesado :=
    FProcedimiento.ParamByName('p_RESULTADO').AsInteger = 1;
  Result.SerieFactura :=
    FProcedimiento.ParamByName('p_SERIE_FAC_OUT').AsString;
  Result.NumeroFactura :=
    FProcedimiento.ParamByName('p_NUMERO_FAC_OUT').AsString;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.
  FacturarAlbaranConOpciones(
  const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
  ANumeroFactura: string; const AOpciones: TOpcionesDocumento;
  const AUsuario: string
): TResultadoFacturacionAlbaranCompra;
var
  oProc: TUniStoredProc;
begin
  oProc := FProcedimientoOpciones;
  oProc.ParamByName('p_SERIE_ALB').AsString := ASerieAlbaran;
  oProc.ParamByName('p_NUMERO_ALB').AsString := ANumeroAlbaran;
  oProc.ParamByName('p_SERIE_FAC').AsString := ASerieFactura;
  oProc.ParamByName('p_NUMERO_FAC').AsString := ANumeroFactura;
  oProc.ParamByName('p_SERIE_NUEVA').AsString := AOpciones.Serie;
  oProc.ParamByName('p_NUMERO_MANUAL').AsString := AOpciones.Numero;
  oProc.ParamByName('p_FECHA').AsDate := AOpciones.Fecha;
  oProc.ParamByName('p_FORMA_PAGO').AsString := AOpciones.FormaPago;
  oProc.ParamByName('p_ALMACEN').AsString := AOpciones.Almacen;
  oProc.ParamByName('p_USUARIO').AsString := AUsuario;
  oProc.ExecProc;
  Result.Procesado := oProc.ParamByName('p_RESULTADO').AsInteger = 1;
  Result.SerieFactura := oProc.ParamByName('p_SERIE_FAC_OUT').AsString;
  Result.NumeroFactura := oProc.ParamByName('p_NUMERO_FAC_OUT').AsString;
end;

function TRepositorioFacturacionAlbaranesCompraUniDAC.
  BuscarFormaPagoProveedor(const AProveedor: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_FORMA_PAGO_PROVEEDOR;
    Consulta.ParamByName('PRV').AsString := AProveedor;
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.FieldByName('CODIGO_FP_PRV').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFacturacionAlbaranesCompraUniDAC.
  ProponerReferenciaProveedor(const ASerie, ANumero, AUsuario: string);
var
  q: TUniQuery;
begin
  q := NuevaConsulta;
  try
    q.SQL.Text :=
      'UPDATE fza_facturas_compra F JOIN (' +
      'SELECT SERIE_FAC_ALBC, NUMERO_FAC_ALBC, ' +
      'CASE WHEN COUNT(DISTINCT TRIM(REF_PROVEEDOR_ALBC)) = 1 ' +
      'AND COUNT(NULLIF(TRIM(REF_PROVEEDOR_ALBC), '''')) = COUNT(*) ' +
      'THEN MIN(TRIM(REF_PROVEEDOR_ALBC)) ELSE NULL END REFERENCIA ' +
      'FROM fza_albaranes_compra ' +
      'WHERE SERIE_FAC_ALBC = :SERIE AND NUMERO_FAC_ALBC = :NUMERO ' +
      'GROUP BY SERIE_FAC_ALBC, NUMERO_FAC_ALBC) A ' +
      'ON A.SERIE_FAC_ALBC = F.SERIE_FACC ' +
      'AND A.NUMERO_FAC_ALBC = F.NUMERO_FACC ' +
      'SET F.REF_PROVEEDOR_FACC = A.REFERENCIA, ' +
      'F.INSTANTE_MODIF = NOW(), F.USUARIO_MODIF = :USUARIO ' +
      'WHERE F.SERIE_FACC = :SERIE AND F.NUMERO_FACC = :NUMERO ' +
      'AND NULLIF(TRIM(F.REF_PROVEEDOR_FACC), '''') IS NULL ' +
      'AND COALESCE(F.ESTADO_FACC, ''ABIERTA'') = ''ABIERTA''';
    q.ParamByName('SERIE').AsString := ASerie;
    q.ParamByName('NUMERO').AsString := ANumero;
    q.ParamByName('USUARIO').AsString := AUsuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

function CrearRepositorioFacturacionAlbaranesCompraUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;
begin
  Result := TRepositorioFacturacionAlbaranesCompraUniDAC.Create(AConexion);
end;

end.

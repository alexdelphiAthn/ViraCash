{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataAbonoDevolucionCompraRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       11/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-925: genera el abono de una devolucion a proveedor con          }
{    PRC_FACC_GENERAR_ABONO_DEVOLUCION y lista las facturas de origen.        }
{******************************************************************************}
unit UniDataAbonoDevolucionCompraRepositorio;

interface

uses
  Uni, inLibAbonoDevolucionCompraPersistenciaIntf;

function CrearRepositorioAbonoDevolucionCompraUniDAC(
  AConexion: TUniConnection): IRepositorioAbonoDevolucionCompra;

implementation

uses
  System.SysUtils, Data.DB, DBAccess;

const
  SQL_FACTURAS_ORIGEN =
    'SELECT SERIE_FACC, NUMERO_FACC, FECHA_FACC, ' +
    '       COALESCE(NULLIF(TRIM(DOC_EXTERNO_FACC), ''''), ' +
    '                REF_PROVEEDOR_FACC, '''') AS REFERENCIA, ' +
    '       COALESCE(TOTAL_LIQUIDO_FACC, 0) AS TOTAL ' +
    '  FROM fza_facturas_compra ' +
    ' WHERE CODIGO_EMP_FACC = :EMPRESA ' +
    '   AND CODIGO_PRV_FACC = :PROVEEDOR ' +
    '   AND COALESCE(TIPO_FACC, ''NORMAL'') <> ''RECTIFICATIVA'' ' +
    '   AND COALESCE(ESTADO_FACC, '''') <> ''CANCELADA'' ' +
    ' ORDER BY FECHA_FACC DESC, SERIE_FACC, NUMERO_FACC DESC';

type
  TRepositorioAbonoDevolucionCompraUniDAC = class(TInterfacedObject,
    IRepositorioAbonoDevolucionCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarFacturasOrigen(
      const AEmpresa, AProveedor: string): TFacturasOrigenAbonoCompra;
    procedure GenerarAbono(const ASolicitud: TSolicitudAbonoDevolucionCompra;
      out ASerie, ANumero: string);
  end;

constructor TRepositorioAbonoDevolucionCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioAbonoDevolucionCompraUniDAC.ListarFacturasOrigen(
  const AEmpresa, AProveedor: string): TFacturasOrigenAbonoCompra;
var
  oConsulta: TUniQuery;
  iFactura: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_FACTURAS_ORIGEN;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('PROVEEDOR').AsString := AProveedor;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iFactura := 0;
    while not oConsulta.Eof do
    begin
      Result[iFactura].Serie := oConsulta.FieldByName('SERIE_FACC').AsString;
      Result[iFactura].Numero :=
        oConsulta.FieldByName('NUMERO_FACC').AsString;
      Result[iFactura].Fecha :=
        oConsulta.FieldByName('FECHA_FACC').AsDateTime;
      Result[iFactura].ReferenciaProveedor :=
        oConsulta.FieldByName('REFERENCIA').AsString;
      Result[iFactura].Total := oConsulta.FieldByName('TOTAL').AsCurrency;
      Inc(iFactura);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAbonoDevolucionCompraUniDAC.GenerarAbono(
  const ASolicitud: TSolicitudAbonoDevolucionCompra;
  out ASerie, ANumero: string);
var
  oProc: TUniStoredProc;
  oParams: TParams;
begin
  ASerie := '';
  ANumero := '';
  oProc := TUniStoredProc.Create(nil);
  try
    oProc.Connection := FConexion;
    oProc.StoredProcName := 'PRC_FACC_GENERAR_ABONO_DEVOLUCION';
    oParams := oProc.Params;
    oParams.Clear;
    oParams.CreateParam(ftString, 'p_SERIE_DEV', ptInput);
    oParams.CreateParam(ftString, 'p_NUMERO_DEV', ptInput);
    oParams.CreateParam(ftString, 'p_SERIE_NUEVA', ptInput);
    oParams.CreateParam(ftString, 'p_NUMERO_MANUAL', ptInput);
    oParams.CreateParam(ftDate, 'p_FECHA', ptInput);
    oParams.CreateParam(ftString, 'p_FORMA_PAGO', ptInput);
    oParams.CreateParam(ftString, 'p_ALMACEN', ptInput);
    oParams.CreateParam(ftString, 'p_SERIE_ORIGEN', ptInput);
    oParams.CreateParam(ftString, 'p_NUMERO_ORIGEN', ptInput);
    oParams.CreateParam(ftString, 'p_USUARIO', ptInput);
    oParams.CreateParam(ftString, 'p_SERIE_FAC_OUT', ptOutput);
    oParams.CreateParam(ftString, 'p_NUMERO_FAC_OUT', ptOutput);
    oParams.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
    oProc.ParamByName('p_SERIE_DEV').AsString := ASolicitud.SerieDevolucion;
    oProc.ParamByName('p_NUMERO_DEV').AsString :=
      ASolicitud.NumeroDevolucion;
    oProc.ParamByName('p_SERIE_NUEVA').AsString := ASolicitud.Serie;
    oProc.ParamByName('p_NUMERO_MANUAL').AsString := ASolicitud.NumeroManual;
    oProc.ParamByName('p_FECHA').AsDate := ASolicitud.Fecha;
    oProc.ParamByName('p_FORMA_PAGO').AsString := ASolicitud.FormaPago;
    oProc.ParamByName('p_ALMACEN').AsString := ASolicitud.Almacen;
    oProc.ParamByName('p_SERIE_ORIGEN').AsString := ASolicitud.SerieOrigen;
    oProc.ParamByName('p_NUMERO_ORIGEN').AsString := ASolicitud.NumeroOrigen;
    oProc.ParamByName('p_USUARIO').AsString := ASolicitud.Usuario;
    oProc.ExecProc;
    if oProc.ParamByName('p_RESULTADO').AsInteger = 1 then
    begin
      ASerie := oProc.ParamByName('p_SERIE_FAC_OUT').AsString;
      ANumero := oProc.ParamByName('p_NUMERO_FAC_OUT').AsString;
    end;
  finally
    FreeAndNil(oProc);
  end;
end;

function CrearRepositorioAbonoDevolucionCompraUniDAC(
  AConexion: TUniConnection): IRepositorioAbonoDevolucionCompra;
begin
  Result := TRepositorioAbonoDevolucionCompraUniDAC.Create(AConexion);
end;

end.

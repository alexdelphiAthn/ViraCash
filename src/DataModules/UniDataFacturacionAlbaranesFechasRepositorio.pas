{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFacturacionAlbaranesFechasRepositorio                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de la facturacion de albaranes por fechas.            }
{******************************************************************************}
unit UniDataFacturacionAlbaranesFechasRepositorio;

interface

uses
  Uni, inLibFacturacionAlbaranesFechasPersistenciaIntf;

function CrearRepositorioFacturacionAlbaranesFechasUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;

procedure BloquearAlbaranPendienteFacturacion(AConexion: TUniConnection;
  const ASerie, ANumero: string);
procedure PrepararTipoFacturaAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ATipo, AUsuario: string);
procedure ValidarImporteFacturaAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ATipo: string);

implementation

uses
  System.SysUtils, Data.DB, inLibMsgFacturas;

procedure BloquearAlbaranPendienteFacturacion(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConexion;
    Q.SQL.Text :=
      'SELECT ESTADO_ALB FROM fza_albaranes ' +
      'WHERE SERIE_ALB=:SERIE AND NUMERO_ALB=:NUMERO FOR UPDATE';
    Q.ParamByName('SERIE').AsString := ASerie;
    Q.ParamByName('NUMERO').AsString := ANumero;
    Q.Open;
    if Q.IsEmpty or
       SameText(Q.FieldByName('ESTADO_ALB').AsString, 'FACTURADO') or
       SameText(Q.FieldByName('ESTADO_ALB').AsString, 'CANCELADO') then
      raise EInvalidOpException.Create(SErrorAlbaranSinPendientesFacturacion);
    Q.Close;
    Q.SQL.Text :=
      'SELECT LINEA_ALBLIN FROM fza_albaranes_lineas ' +
      'WHERE SERIE_ALB_ALBLIN=:SERIE AND NUMERO_ALB_ALBLIN=:NUMERO ' +
      'AND COALESCE(ESFACTURADA_ALBLIN,''N'')<>''S'' LIMIT 1 FOR UPDATE';
    Q.ParamByName('SERIE').AsString := ASerie;
    Q.ParamByName('NUMERO').AsString := ANumero;
    Q.Open;
    if Q.IsEmpty then
      raise EInvalidOpException.Create(SErrorAlbaranSinPendientesFacturacion);
  finally
    Q.Free;
  end;
end;

function EsSimplificadaAlbaran(const ATipo: string): Boolean;
begin
  Result := SameText(ATipo, 'SIMPLIFICADA');
end;

procedure PrepararTipoFacturaAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ATipo, AUsuario: string);
var
  Q: TUniQuery;
begin
  if EsSimplificadaAlbaran(ATipo) then
  begin
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConexion;
      Q.SQL.Text :=
        'SELECT F.NUMERO_FAC FROM fza_facturas F ' +
        'WHERE F.SERIE_FAC=:SERIE AND F.NUMERO_FAC=:NUMERO ' +
        'AND EXISTS (SELECT 1 FROM vi_empresas_series S ' +
        'WHERE S.CODIGO_EMP_EMPSER=F.CODIGO_EMP_FAC ' +
        'AND S.EMPSER=F.SERIE_FAC AND S.TIPO_DOC_EMPSER=''FC'' ' +
        'AND S.SUBTIPO_EMPSER=''SIMPLIFICADA'')';
      Q.ParamByName('SERIE').AsString := ASerie;
      Q.ParamByName('NUMERO').AsString := ANumero;
      Q.Open;
      if Q.IsEmpty then
        raise EInvalidOpException.Create(SErrorSerieSimplificadaAlbaran);
      Q.Close;
      Q.SQL.Text :=
        'UPDATE fza_facturas SET TIPO_FAC=''SIMPLIFICADA'', ' +
        'ESMUEVE_STOCK_FAC=''N'', INSTANTE_MODIF=NOW(), ' +
        'USUARIO_MODIF=:USUARIO ' +
        'WHERE SERIE_FAC=:SERIE AND NUMERO_FAC=:NUMERO ' +
        'AND COALESCE(FASE_FAC,''BORRADOR'')=''BORRADOR''';
      Q.ParamByName('SERIE').AsString := ASerie;
      Q.ParamByName('NUMERO').AsString := ANumero;
      Q.ParamByName('USUARIO').AsString := AUsuario;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
  end;
end;

procedure ValidarImporteFacturaAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ATipo: string);
var
  Q: TUniQuery;
  Limite, Importe: Currency;
begin
  if EsSimplificadaAlbaran(ATipo) then
  begin
    Limite := 3000;
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConexion;
      Q.SQL.Text :=
        'SELECT COALESCE(F.TOTAL_BASES_FAC,0)+' +
        'COALESCE(F.TOTAL_IMPUESTOS_FAC,0)+' +
        'COALESCE(F.TOTAL_REN_FAC,0)+COALESCE(F.TOTAL_RER_FAC,0)+' +
        'COALESCE(F.TOTAL_RES_FAC,0)+COALESCE(F.TOTAL_REE_FAC,0) ' +
        'AS IMPORTE, EXISTS (SELECT 1 FROM fza_formas_pago P ' +
        'WHERE P.CODIGO_FP_FP=F.FORMA_PAGO_FAC ' +
        'AND P.CODIGO_FACTURAE_FP=''01'') AS EFECTIVO ' +
        'FROM fza_facturas F ' +
        'WHERE F.SERIE_FAC=:SERIE AND F.NUMERO_FAC=:NUMERO';
      Q.ParamByName('SERIE').AsString := ASerie;
      Q.ParamByName('NUMERO').AsString := ANumero;
      Q.Open;
      if Q.IsEmpty then
        raise EInvalidOpException.Create(SErrorCrearBorradorFactura);
      Importe := Q.FieldByName('IMPORTE').AsCurrency;
      if (Importe < 0) or (Importe > Limite) then
        raise EInvalidOpException.CreateFmt(
          SErrorImporteSimplificadaAlbaran, [FormatFloat('0.00', Limite)]);
      if (Importe >= 1000) and (Q.FieldByName('EFECTIVO').AsInteger <> 0) then
        raise EInvalidOpException.Create(SErrorEfectivoFacturaAlbaran);
    finally
      Q.Free;
    end;
  end;
end;

const
  SQL_BUSCAR_ALBARANES =
    'SELECT NUMERO_ALB, SERIE_ALB, FECHA_ALB, CODIGO_CLI_ALB, ' +
    'RAZON_SOCIAL_CLIENTE_ALB, TOTAL_LIQUIDO_ALB FROM fza_albaranes ' +
    'WHERE SERIE_ALB = :SERIE AND FECHA_ALB BETWEEN :DESDE AND :HASTA ' +
    'AND IFNULL(ESTADO_ALB, '''') <> ''FACTURADO'' ' +
    'AND IFNULL(ESTADO_ALB, '''') <> ''CANCELADO'' ' +
    'ORDER BY CODIGO_CLI_ALB, FECHA_ALB, NUMERO_ALB';

type
  TRepositorioFacturacionAlbaranesFechasUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturacionAlbaranesFechas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Buscar(
      const ASerie: string;
      AFechaDesde: TDateTime;
      AFechaHasta: TDateTime): TAlbaranesFacturacionFechas;
  end;

constructor TRepositorioFacturacionAlbaranesFechasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFacturacionAlbaranesFechasUniDAC.Buscar(
  const ASerie: string;
  AFechaDesde: TDateTime;
  AFechaHasta: TDateTime): TAlbaranesFacturacionFechas;
var
  iAlbaran: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSCAR_ALBARANES;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('DESDE').AsDateTime := AFechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := AFechaHasta;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iAlbaran := Length(Result);
      SetLength(Result, iAlbaran + 1);
      Result[iAlbaran].Numero :=
        oConsulta.FieldByName('NUMERO_ALB').AsString;
      Result[iAlbaran].Serie :=
        oConsulta.FieldByName('SERIE_ALB').AsString;
      Result[iAlbaran].Fecha :=
        oConsulta.FieldByName('FECHA_ALB').AsDateTime;
      Result[iAlbaran].CodigoCliente :=
        oConsulta.FieldByName('CODIGO_CLI_ALB').AsString;
      Result[iAlbaran].RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLIENTE_ALB').AsString;
      Result[iAlbaran].Total :=
        oConsulta.FieldByName('TOTAL_LIQUIDO_ALB').AsCurrency;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFacturacionAlbaranesFechasUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
begin
  Result := TRepositorioFacturacionAlbaranesFechasUniDAC.Create(AConexion);
end;

end.

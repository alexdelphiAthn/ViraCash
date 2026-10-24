{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataConsultaFacturasOperacionesRepositorio                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para consultar una factura desde operaciones.        }
{******************************************************************************}
unit UniDataConsultaFacturasOperacionesRepositorio;

interface

uses
  Uni, inLibConsultaFacturasOperacionesPersistenciaIntf;

function CrearRepositorioConsultaFacturasOperacionesUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFacturasOperaciones;

implementation

uses
  System.SysUtils, Data.DB, UniDataRectificativasSql;

const
  SQL_CONSULTAR_FACTURA =
    'SELECT f.ESCONSOLIDADA_FAC, f.TIPO_FAC, f.FECHA_FAC, f.FASE_FAC, ';
  SQL_FASES_VERIFACTU = '''VERIFACTU_OK'', ''VERIFACTU_ACEPT_ERR''';
  // VERI*FACTU y SII (misma fase; el estado distingue el sistema)
  SQL_ESTADOS_VERIFACTU =
    '''VERIFACTU_OK'', ''VERIFACTU_PROCESADO'', ''VERIFACTU_DUPLICADO'', ' +
    '''VERIFACTU_SUBSANADO'', ''VERIFACTU_ACEPT_ERR'', ' +
    '''SII_PROCESADO'', ''SII_ACEPT_ERR'', ''SII_DUPLICADO'', ' +
    '''SII_MODIFICADO''';
  SQL_FASES_NO_VERIFACTU = '''NOVERIFACTU_OK''';
  SQL_ESTADOS_NO_VERIFACTU = '''NOVERIF_REGISTRADO'', ''NOVERIF_SUBSANADO''';
  SQL_SUBSANABLE_SIN_VERIFACTU =
    // Sin VeriFactu no se exige consolidación ni registro fiscal.
    'CASE WHEN f.TIPO_FAC = ''SIMPLIFICADA'' ' +
    'AND COALESCE(f.FASE_FAC, '''') NOT IN ' +
    '(''SIN_VERIF_ANULADA'', ''VERIFACTU_ANULADA'', ' +
    '''NOVERIFACTU_ANULADA'', ''RECTIFICADA'', ''CANCELADA'') ';

function SQLSubsanableRegistrado(const AFases, AEstados: string): string;
begin
  // Registro fiscal aceptado y sin envíos ni anulaciones pendientes.
  Result :=
    'CASE WHEN f.ESCONSOLIDADA_FAC = ''S'' ' +
    'AND f.TIPO_FAC = ''SIMPLIFICADA'' ' +
    'AND f.FASE_FAC IN (' + AFases + ') ' +
    'AND (SELECT c.ESTADO_FACCON FROM fza_facturas_consolidaciones c ' +
    'WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
    'AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
    'ORDER BY c.ID_FACCON DESC LIMIT 1) IN (' + AEstados + ') ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola q ' +
    'WHERE q.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
    'AND q.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
    'AND q.TIPO_OPERACION_VFCOLA IN ' +
    '(''ALTA'', ''ANULACION'', ''SUBSANACION'') ' +
    'AND (q.ESTADO_VFCOLA <> ''ENVIADA'' ' +
    'OR q.TIPO_OPERACION_VFCOLA = ''ANULACION'')) ';
end;

type
  TRepositorioConsultaFacturasOperacionesUniDAC = class(
    TInterfacedObject,
    IRepositorioConsultaFacturasOperaciones)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarFactura(
      const ASerie, ANumero: string): TFacturaConsultaOperacion;
  end;

constructor TRepositorioConsultaFacturasOperacionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioConsultaFacturasOperacionesUniDAC.ConsultarFactura(
  const ASerie, ANumero: string): TFacturaConsultaOperacion;
var
  Consulta: TUniQuery;
  sVigente: string;
begin
  Result := Default(TFacturaConsultaOperacion);
  sVigente := SQLExcluirVentaRetirada(
    'f.CODIGO_EMP_FAC', 'f.SERIE_FAC', 'f.NUMERO_FAC');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_CONSULTAR_FACTURA +
      SQLSubsanableRegistrado(SQL_FASES_VERIFACTU, SQL_ESTADOS_VERIFACTU) +
      sVigente + 'THEN ''S'' ELSE ''N'' END AS PUEDE_SUBSANAR, ' +
      SQLSubsanableRegistrado(SQL_FASES_NO_VERIFACTU,
        SQL_ESTADOS_NO_VERIFACTU) +
      sVigente + 'THEN ''S'' ELSE ''N'' END AS PUEDE_SUBSANAR_NO_VERIFACTU, ' +
      SQL_SUBSANABLE_SIN_VERIFACTU +
      sVigente + 'THEN ''S'' ELSE ''N'' END AS PUEDE_SUBSANAR_SIN_VERIFACTU ' +
      'FROM fza_facturas f WHERE f.SERIE_FAC = :SERIE ' +
      'AND f.NUMERO_FAC = :NUMERO';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result.Existe := not Consulta.IsEmpty;
    if Result.Existe then
    begin
      Result.Consolidada :=
        Consulta.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S';
      Result.PuedeSubsanar :=
        Consulta.FieldByName('PUEDE_SUBSANAR').AsString = 'S';
      Result.PuedeSubsanarNoVerifactu := Consulta.FieldByName(
        'PUEDE_SUBSANAR_NO_VERIFACTU').AsString = 'S';
      Result.PuedeSubsanarSinVerifactu := Consulta.FieldByName(
        'PUEDE_SUBSANAR_SIN_VERIFACTU').AsString = 'S';
      Result.Tipo := Consulta.FieldByName('TIPO_FAC').AsString;
      Result.Fase := Consulta.FieldByName('FASE_FAC').AsString;
      Result.Fecha := Consulta.FieldByName('FECHA_FAC').AsDateTime;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioConsultaFacturasOperacionesUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFacturasOperaciones;
begin
  Result := TRepositorioConsultaFacturasOperacionesUniDAC.Create(AConexion);
end;

end.

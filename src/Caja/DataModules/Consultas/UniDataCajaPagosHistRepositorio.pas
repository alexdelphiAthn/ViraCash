{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCajaPagosHistRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del historico de pagos de caja.                       }
{******************************************************************************}
unit UniDataCajaPagosHistRepositorio;

interface

uses
  Uni, inLibCajaPagosHistPersistenciaIntf;

function CrearRepositorioCajaPagosHistUniDAC(
  AConsulta: TUniQuery): IRepositorioCajaPagosHist;

implementation

uses
  System.Classes, System.SysUtils;

type
  TRepositorioCajaPagosHistUniDAC = class(
    TInterfacedObject,
    IRepositorioCajaPagosHist)
  private
    FConsulta: TUniQuery;
    FConexionLectura: TUniConnection;
    FCancelada: Integer;
    FEjecutando: Integer;
    FUltimoCorte: UInt64;
    function ConstruirSql(
      const AFiltros: TFiltrosCajaPagosHist): string;
  public
    constructor Create(AConsulta: TUniQuery);
    procedure PrepararConsulta(
      const AFiltros: TFiltrosCajaPagosHist);
    procedure AbrirConsulta;
    procedure CancelarConsulta;
  end;

constructor TRepositorioCajaPagosHistUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

function TRepositorioCajaPagosHistUniDAC.ConstruirSql(
  const AFiltros: TFiltrosCajaPagosHist): string;

  function FragmentoDimension(
    const AColumna, AValor: string): string;
  begin
    Result := '';
    if AValor <> '' then
    begin
      Result := ' AND (' + AColumna + ' = ' + QuotedStr(AValor) +
        ' OR ' + AColumna + ' IS NULL)';
    end;
  end;

begin
  // FZ-ISSUE-861: los gastos se guardan positivos, pero son salidas.
  Result := 'SELECT ' +
    'CODIGO_EMP_PAGO, ' +
    'CODIGO_ALM_PAGO, ' +
    'CODIGO_CAJA_PAGO, ' +
    'SERIE_OPERACION_PAGO, ' +
    'NUMERO_OPERACION_PAGO, ' +
    'NUMERO_LINEA_PAGO, ' +
    'CODIGO_FP_CFP, ' +
    'CODIGO_DIVISA_PAGO, ' +
    'RED_BLOCKCHAIN_PAGO, ' +
    'FACTOR_CAMBIO_PAGO, ' +
    'CASE WHEN TIPO_OPERACION_PAGO = ''GC'' THEN ' +
    '-ABS(IMPORTE_DIVISA_PAGO) ELSE IMPORTE_DIVISA_PAGO ' +
    'END AS IMPORTE_DIVISA_PAGO, ' +
    'CASE WHEN TIPO_OPERACION_PAGO = ''GC'' THEN ' +
    '-ABS(IMPORTE_ENTREGADO_PAGO) ELSE IMPORTE_ENTREGADO_PAGO ' +
    'END AS IMPORTE_ENTREGADO_PAGO, ' +
    'CASE WHEN TIPO_OPERACION_PAGO = ''GC'' THEN ' +
    '-ABS(IMPORTE_CAMBIO_PAGO) ELSE IMPORTE_CAMBIO_PAGO ' +
    'END AS IMPORTE_CAMBIO_PAGO, ' +
    'CASE WHEN TIPO_OPERACION_PAGO = ''GC'' THEN ' +
    '-ABS(IMPORTE_ENTREGADO_PAGO) + ABS(IMPORTE_CAMBIO_PAGO) ' +
    'ELSE IMPORTE_ENTREGADO_PAGO - IMPORTE_CAMBIO_PAGO ' +
    'END AS NETO_PAGO, ' +
    'REFERENCIA_FACPAG, ' +
    'OBSERVACIONES_PAGO, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'FECHA_PAGO, ' +
    'NUMERO_FAC_PAGO, ' +
    'SERIE_FAC_PAGO, ' +
    'DESCRIPCION_FP_PAGO, ' +
    'TIPO_OPERACION_PAGO, ' +
    'EMPLEADO_PAGO, ' +
    'CODIGO_CLI_PAGO, ' +
    'CASE WHEN TIPO_OPERACION_PAGO = ''GC'' THEN ' +
    '-ABS(IMPORTE_OPERACION_PAGO) ELSE IMPORTE_OPERACION_PAGO ' +
    'END AS IMPORTE_OPERACION_PAGO, ' +
    'ARQUEO_PAGO, ' +
    'SERIE_ORIGEN_PAGO, ' +
    'NUMERO_ORIGEN_PAGO, ' +
    'MOTIVO_DEVOLUCION_PAGO, ' +
    'TIPO_FAC_PAGO, ' +
    'FASE_FAC_PAGO, ' +
    'ESCONSOLIDADA_FAC_PAGO, ' +
    'TOTAL_FAC_PAGO, ' +
    'CODIGO_CLI_FAC_PAGO, ' +
    'CLIENTE_FAC_PAGO ' +
    'FROM vi_caja_pagos WHERE 1 = 1';
  if AFiltros.SinFilas then
    Result := Result + ' AND 1 = 0'
  else if AFiltros.HastaExclusiva > 0 then
    Result := Result + ' AND FECHA_PAGO >= :DESDE AND FECHA_PAGO < :HASTA';
  Result := Result + FragmentoDimension(
    'CODIGO_EMP_PAGO',
    AFiltros.Empresa);
  Result := Result + FragmentoDimension(
    'CODIGO_ALM_PAGO',
    AFiltros.Almacen);
  Result := Result + FragmentoDimension(
    'CODIGO_CAJA_PAGO',
    AFiltros.Caja);
  Result := Result + ' ORDER BY FECHA_PAGO DESC';
end;


procedure TRepositorioCajaPagosHistUniDAC.PrepararConsulta(
  const AFiltros: TFiltrosCajaPagosHist);
begin
  FConsulta.Close;
  if (AFiltros.HastaExclusiva > 0) and not Assigned(FConexionLectura) then
  begin
    // BreakExec solo debe afectar a la conexión de esta consulta.
    FConexionLectura := TUniConnection.Create(FConsulta);
    try
      FConexionLectura.Assign(FConsulta.Connection);
      FConexionLectura.LoginPrompt := False;
      FConsulta.Connection := FConexionLectura;
    except
      FreeAndNil(FConexionLectura);
      raise;
    end;
  end;
  AtomicExchange(FCancelada, 0);
  FUltimoCorte := 0;
  // Refrescar debe releer el importe firmado, no el SELECT crudo del DFM.
  FConsulta.SQLRefresh.Clear;
  FConsulta.ReadOnly := True;
  FConsulta.SQL.Text := ConstruirSql(AFiltros);
  if not AFiltros.SinFilas and (AFiltros.HastaExclusiva > 0) then
  begin
    FConsulta.ParamByName('DESDE').AsDateTime := AFiltros.Desde;
    FConsulta.ParamByName('HASTA').AsDateTime := AFiltros.HastaExclusiva;
  end;
end;

procedure TRepositorioCajaPagosHistUniDAC.AbrirConsulta;
begin
  if not FConsulta.Active and (AtomicCmpExchange(FCancelada, 0, 0) = 0) then
  begin
    if Assigned(FConexionLectura) then
      FConexionLectura.Connect;
    AtomicExchange(FEjecutando, 1);
    try
      if AtomicCmpExchange(FCancelada, 0, 0) = 0 then
      begin
        FConsulta.Open;
        FConsulta.Last;
        FConsulta.First;
      end;
    finally
      AtomicExchange(FEjecutando, 0);
    end;
  end;
end;

procedure TRepositorioCajaPagosHistUniDAC.CancelarConsulta;
var
  iAhora: UInt64;
begin
  AtomicExchange(FCancelada, 1);
  iAhora := TThread.GetTickCount64;
  if (AtomicCmpExchange(FEjecutando, 0, 0) <> 0) and
     ((FUltimoCorte = 0) or (iAhora - FUltimoCorte >= 1000)) then
  begin
    FUltimoCorte := iAhora;
    FConsulta.BreakExec;
  end;
end;

function CrearRepositorioCajaPagosHistUniDAC(
  AConsulta: TUniQuery): IRepositorioCajaPagosHist;
begin
  Result := TRepositorioCajaPagosHistUniDAC.Create(AConsulta);
end;

end.

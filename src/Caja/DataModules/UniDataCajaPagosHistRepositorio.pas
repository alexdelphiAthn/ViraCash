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
  System.SysUtils;

type
  TRepositorioCajaPagosHistUniDAC = class(
    TInterfacedObject,
    IRepositorioCajaPagosHist)
  private
    FConsulta: TUniQuery;
    function ConstruirSql(
      const AFiltros: TFiltrosCajaPagosHist): string;
  public
    constructor Create(AConsulta: TUniQuery);
    function ListarAnyos: TCadenasCajaPagosHist;
    procedure PrepararConsulta(
      const AFiltros: TFiltrosCajaPagosHist);
    procedure AbrirConsulta;
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

var
  iAnyo: Integer;
  nAnyo: Integer;
  sAnyos: string;
begin
  sAnyos := '';
  for iAnyo := Low(AFiltros.Anyos) to High(AFiltros.Anyos) do
  begin
    if TryStrToInt(AFiltros.Anyos[iAnyo], nAnyo) then
    begin
      if sAnyos <> '' then
      begin
        sAnyos := sAnyos + ', ';
      end;
      sAnyos := sAnyos + IntToStr(nAnyo);
    end;
  end;
  Result := 'SELECT * FROM vi_caja_pagos WHERE 1 = 1';
  if sAnyos <> '' then
  begin
    Result := Result + ' AND YEAR(FECHA_PAGO) IN (' + sAnyos + ')';
  end;
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

function TRepositorioCajaPagosHistUniDAC.ListarAnyos:
  TCadenasCajaPagosHist;
var
  oConsulta: TUniQuery;
  iAnyo: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConsulta.Connection;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_PAGO) AS ANYO ' +
      'FROM vi_caja_pagos ' +
      'WHERE FECHA_PAGO IS NOT NULL ' +
      'ORDER BY ANYO DESC';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iAnyo := Length(Result);
      SetLength(Result, iAnyo + 1);
      Result[iAnyo] := oConsulta.FieldByName('ANYO').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCajaPagosHistUniDAC.PrepararConsulta(
  const AFiltros: TFiltrosCajaPagosHist);
begin
  FConsulta.Close;
  FConsulta.SQL.Text := ConstruirSql(AFiltros);
end;

procedure TRepositorioCajaPagosHistUniDAC.AbrirConsulta;
begin
  if not FConsulta.Active then
  begin
    FConsulta.Open;
  end;
end;

function CrearRepositorioCajaPagosHistUniDAC(
  AConsulta: TUniQuery): IRepositorioCajaPagosHist;
begin
  Result := TRepositorioCajaPagosHistUniDAC.Create(AConsulta);
end;

end.

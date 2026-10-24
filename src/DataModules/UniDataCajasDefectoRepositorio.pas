{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCajasDefectoRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del selector de empresa, almacen y caja.              }
{******************************************************************************}
unit UniDataCajasDefectoRepositorio;

interface

uses
  Uni, inLibCajasDefectoPersistenciaIntf;

function CrearRepositorioCajasDefectoUniDAC(
  AConexion: TUniConnection): IRepositorioCajasDefecto;

implementation

uses
  System.SysUtils, Data.DB;

type
  TResultadoCajasDefectoUniDAC = class(
    TInterfacedObject,
    IResultadoCajasDefecto)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioCajasDefectoUniDAC = class(
    TInterfacedObject,
    IRepositorioCajasDefecto)
  private
    FConexion: TUniConnection;
    function FragmentoRestriccion(
      const AColumna, AValor: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function Consultar(
      const ASolicitud: TSolicitudCajasDefecto
    ): IResultadoCajasDefecto;
  end;

constructor TResultadoCajasDefectoUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoCajasDefectoUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoCajasDefectoUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioCajasDefectoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioCajasDefectoUniDAC.FragmentoRestriccion(
  const AColumna, AValor: string): string;
begin
  Result := '';
  if AValor <> '' then
  begin
    Result := ' AND (' + AColumna + ' = ' + QuotedStr(AValor) +
      ' OR ' + AColumna + ' IS NULL)';
  end;
end;

function TRepositorioCajasDefectoUniDAC.Consultar(
  const ASolicitud: TSolicitudCajasDefecto
): IResultadoCajasDefecto;
var
  oConsulta: TUniQuery;
  sFiltroEmpresa: string;
begin
  sFiltroEmpresa := '';
  if ASolicitud.EmpresaFiltro <> '' then
  begin
    sFiltroEmpresa := ' AND Empresa = :EMPRESA_FILTRO';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * ' +
      '  FROM vi_cajasdef ' +
      ' WHERE 1 = 1 ' +
      // FZ-ISSUE-240: un almacén de tránsito no abre caja.
      '   AND NOT EXISTS (SELECT 1 FROM fza_almacenes t ' +
      '                    WHERE t.CODIGO_ALM_ALM = Almacen ' +
      '                      AND t.TIPO_USO_ALM IN (''TR' + #$C1 +
      'NSITO'', ''TRANSITO'')) ' +
      sFiltroEmpresa +
      FragmentoRestriccion(
        'Empresa',
        ASolicitud.EmpresaRestringida) +
      FragmentoRestriccion(
        'Almacen',
        ASolicitud.AlmacenRestringido) +
      FragmentoRestriccion(
        'Caja',
        ASolicitud.CajaRestringida) +
      ' ORDER BY Empresa, Almacen, Caja';
    if ASolicitud.EmpresaFiltro <> '' then
    begin
      oConsulta.ParamByName('EMPRESA_FILTRO').AsString :=
        ASolicitud.EmpresaFiltro;
    end;
    oConsulta.Open;
    Result := TResultadoCajasDefectoUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioCajasDefectoUniDAC(
  AConexion: TUniConnection): IRepositorioCajasDefecto;
begin
  Result := TRepositorioCajasDefectoUniDAC.Create(AConexion);
end;

end.

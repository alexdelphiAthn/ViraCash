{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInformeLibrosIvaRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Repositorio UniDAC del listado «Libros de IVA» (FZ-ISSUE-262): abre el   }
{    detalle por factura y tramo y el resumen por porcentaje con los mismos   }
{    criterios. El resultado es dueño de ambos datasets.                       }
{******************************************************************************}
unit UniDataInformeLibrosIvaRepositorio;

interface

uses
  Uni, inLibInformeLibrosIvaPersistenciaIntf;

function CrearRepositorioInformeLibrosIvaUniDAC(
  AConexion: TUniConnection): IRepositorioInformeLibrosIva;

implementation

uses
  System.SysUtils, Data.DB, UniDataLibrosIvaSql;

type
  TResultadoInformeLibrosIvaUniDAC = class(
    TInterfacedObject,
    IResultadoInformeLibrosIva)
  private
    FDetalle: TDataSet;
    FResumen: TDataSet;
    FLiquidacion: TDataSet;
  public
    constructor Create(ADetalle, AResumen, ALiquidacion: TDataSet);
    destructor Destroy; override;
    function Detalle: TDataSet;
    function Resumen: TDataSet;
    function Liquidacion: TDataSet;
  end;

  TRepositorioInformeLibrosIvaUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeLibrosIva)
  private
    FConexion: TUniConnection;
    function Abrir(const ASql: string;
      const ACriterios: TCriteriosInformeLibrosIva): TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarEmpresas: TEmpresasInformeLibrosIva;
    function Preparar(
      const ACriterios: TCriteriosInformeLibrosIva
    ): IResultadoInformeLibrosIva;
    function ListarFacturasSinNumeroProveedor(
      const ACriterios: TCriteriosInformeLibrosIva
    ): TFacturasSinNumeroProveedorLibrosIva;
    function ListarFacturasAbiertas(
      const ACriterios: TCriteriosInformeLibrosIva
    ): TFacturasAbiertasLibrosIva;
    function ListarFacturas(const ASql: string;
      const ACriterios: TCriteriosInformeLibrosIva
    ): TFacturasSinNumeroProveedorLibrosIva;
  end;

constructor TResultadoInformeLibrosIvaUniDAC.Create(
  ADetalle, AResumen, ALiquidacion: TDataSet);
begin
  inherited Create;
  FDetalle := ADetalle;
  FResumen := AResumen;
  FLiquidacion := ALiquidacion;
end;

destructor TResultadoInformeLibrosIvaUniDAC.Destroy;
begin
  FreeAndNil(FLiquidacion);
  FreeAndNil(FResumen);
  FreeAndNil(FDetalle);
  inherited Destroy;
end;

function TResultadoInformeLibrosIvaUniDAC.Detalle: TDataSet;
begin
  Result := FDetalle;
end;

function TResultadoInformeLibrosIvaUniDAC.Resumen: TDataSet;
begin
  Result := FResumen;
end;

function TResultadoInformeLibrosIvaUniDAC.Liquidacion: TDataSet;
begin
  Result := FLiquidacion;
end;

constructor TRepositorioInformeLibrosIvaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeLibrosIvaUniDAC.ListarEmpresas:
  TEmpresasInformeLibrosIva;
var
  iEmpresa: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlEmpresasLibrosIva;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iEmpresa := Length(Result);
      SetLength(Result, iEmpresa + 1);
      Result[iEmpresa].Codigo :=
        oConsulta.FieldByName('CODIGO_EMP_EMP').AsString;
      Result[iEmpresa].RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeLibrosIvaUniDAC.Abrir(const ASql: string;
  const ACriterios: TCriteriosInformeLibrosIva): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := ASql;
    Result.ParamByName('pDESDE').AsDate := ACriterios.FechaDesde;
    Result.ParamByName('pHASTA').AsDate := ACriterios.FechaHasta;
    Result.ParamByName('pEMP').AsString := ACriterios.Empresas;
    Result.ParamByName('pLIB').AsString := ACriterios.Libros;
    if ACriterios.IncluirSinFase then
      Result.ParamByName('pSINFASE').AsString := 'S'
    else
      Result.ParamByName('pSINFASE').AsString := 'N';
    Result.Open;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TRepositorioInformeLibrosIvaUniDAC.Preparar(
  const ACriterios: TCriteriosInformeLibrosIva
): IResultadoInformeLibrosIva;
var
  oDetalle: TUniQuery;
  oResumen: TUniQuery;
  oLiquidacion: TUniQuery;
begin
  oResumen := nil;
  oDetalle := Abrir(SqlDetalleLibrosIva, ACriterios);
  try
    oResumen := Abrir(SqlResumenLibrosIva, ACriterios);
    oLiquidacion := Abrir(SqlLiquidacionLibrosIva, ACriterios);
  except
    FreeAndNil(oResumen);
    FreeAndNil(oDetalle);
    raise;
  end;
  Result := TResultadoInformeLibrosIvaUniDAC.Create(oDetalle, oResumen,
    oLiquidacion);
end;

function TRepositorioInformeLibrosIvaUniDAC.ListarFacturasSinNumeroProveedor(
  const ACriterios: TCriteriosInformeLibrosIva
): TFacturasSinNumeroProveedorLibrosIva;
begin
  Result := ListarFacturas(SqlSoportadoSinNumeroProveedorLibrosIva,
    ACriterios);
end;

function TRepositorioInformeLibrosIvaUniDAC.ListarFacturasAbiertas(
  const ACriterios: TCriteriosInformeLibrosIva
): TFacturasAbiertasLibrosIva;
begin
  Result := ListarFacturas(SqlSoportadoAbiertasLibrosIva, ACriterios);
end;

function TRepositorioInformeLibrosIvaUniDAC.ListarFacturas(
  const ASql: string; const ACriterios: TCriteriosInformeLibrosIva
): TFacturasSinNumeroProveedorLibrosIva;
var
  iFactura: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := Abrir(ASql, ACriterios);
  try
    while not oConsulta.Eof do
    begin
      iFactura := Length(Result);
      SetLength(Result, iFactura + 1);
      Result[iFactura].Empresa :=
        oConsulta.FieldByName('EMPRESA').AsString;
      Result[iFactura].Serie := oConsulta.FieldByName('SERIE').AsString;
      Result[iFactura].Numero := oConsulta.FieldByName('NUMERO').AsString;
      Result[iFactura].Fecha := oConsulta.FieldByName('FECHA').AsDateTime;
      Result[iFactura].Proveedor :=
        oConsulta.FieldByName('NOMBRE').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioInformeLibrosIvaUniDAC(
  AConexion: TUniConnection): IRepositorioInformeLibrosIva;
begin
  Result := TRepositorioInformeLibrosIvaUniDAC.Create(AConexion);
end;

end.

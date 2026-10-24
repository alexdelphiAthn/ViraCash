{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataVentasPantallaFacturasSimplificadas                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Encapsula las consultas y la configuracion del listado de facturas        }
{    simplificadas que antes pertenecian al formulario.                        }
{******************************************************************************}
unit UniDataVentasPantallaFacturasSimplificadas;

interface

uses
  Uni,
  inLibContextoSesionIntf,
  inLibParametrosIntf,
  inLibVentasPantallaIntf;

function CrearRepositorioFacturasSimplificadasPantallaUniDAC(
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion):
  IRepositorioFacturasSimplificadasPantalla;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibFiltroUsuario, UniDataFacturasListado;

const
  SQL_ANYOS =
    'SELECT DISTINCT YEAR(FECHA_FAC) AS ANYO ' +
    '  FROM vi_facturas v ';
  SQL_ALMACENES =
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
    '  FROM fza_almacenes ' +
    ' WHERE ESACTIVO_ALM = ''S'' ';
  SQL_LISTADO =
    'SELECT v.*, ' + SQL_CAMPOS_RECTIFICADA_LISTADO +
    ' FROM vi_facturas v ' + SQL_ENLACE_RECTIFICADA_LISTADO;
  SQL_CONTAR =
    'SELECT COUNT(*) AS N FROM vi_facturas v ';
  SQL_ORDEN_LISTADO =
    ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC';
  SQL_ORDEN_ALMACENES =
    ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';

type
  TRepositorioFacturasSimplificadasPantallaUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturasSimplificadasPantalla)
  private
    FConexion: TUniConnection;
    FListado: TUniQuery;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FFirmaFiltros: string;
    function ConstruirListaParametros(
      const APrefijo: string;
      ACantidad: Integer): string;
    function ConstruirWhere(
      const AFiltros: TFiltrosFacturasSimplificadas): string;
    function FirmaFiltros(
      const AFiltros: TFiltrosFacturasSimplificadas): string;
    procedure AsignarParametrosFiltro(
      AConsulta: TUniQuery;
      const AFiltros: TFiltrosFacturasSimplificadas);
    procedure AnadirRestriccion(
      var ASql: string;
      const AColumna, AParametro, AValor: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      AListado: TUniQuery;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion);
    function ListarAnyos: TArray<Integer>;
    function ListarAlmacenes: TAlmacenesFiltroFacturaSimplificada;
    function ConfigurarListado(
      const AFiltros: TFiltrosFacturasSimplificadas): Boolean;
    function Contar(
      const AFiltros: TFiltrosFacturasSimplificadas): Integer;
  end;

constructor TRepositorioFacturasSimplificadasPantallaUniDAC.Create(
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(AListado) then
    raise EArgumentNilException.Create('AListado');
  FConexion := AConexion;
  FListado := AListado;
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FFirmaFiltros := #0;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.
  ConstruirListaParametros(
  const APrefijo: string;
  ACantidad: Integer): string;
var
  iParametro: Integer;
begin
  Result := '';
  for iParametro := 0 to ACantidad - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ':' + APrefijo + IntToStr(iParametro);
  end;
end;

procedure TRepositorioFacturasSimplificadasPantallaUniDAC.
  AnadirRestriccion(
  var ASql: string;
  const AColumna, AParametro, AValor: string);
begin
  if AValor <> '' then
  begin
    ASql := ASql + ' AND (' + AColumna + ' = :' + AParametro +
      ' OR ' + AColumna + ' IS NULL)';
  end;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.ConstruirWhere(
  const AFiltros: TFiltrosFacturasSimplificadas): string;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
begin
  Result := ' WHERE ' +
    SQLFiltroVistaListadoFacturas('vi_facturas_simplificadas');
  if Length(AFiltros.Anyos) > 0 then
  begin
    Result := Result + ' AND YEAR(FECHA_FAC) IN (' +
      ConstruirListaParametros('ANYO', Length(AFiltros.Anyos)) + ')';
  end;
  if Length(AFiltros.Almacenes) > 0 then
  begin
    Result := Result + ' AND CODIGO_ALM_FAC IN (' +
      ConstruirListaParametros(
        'ALMACEN', Length(AFiltros.Almacenes)) + ')';
  end;
  sEmpresa := EmpresaRestringida(FContextoSesion, FParametrosApp);
  sAlmacen := AlmacenRestringido(FContextoSesion, FParametrosApp);
  sCaja := CajaRestringida(FContextoSesion, FParametrosApp);
  AnadirRestriccion(
    Result, 'CODIGO_EMP_FAC', 'EMPRESA_USUARIO', sEmpresa);
  AnadirRestriccion(
    Result, 'CODIGO_ALM_FAC', 'ALMACEN_USUARIO', sAlmacen);
  AnadirRestriccion(
    Result, 'CODIGO_CAJA_FAC', 'CAJA_USUARIO', sCaja);
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.FirmaFiltros(
  const AFiltros: TFiltrosFacturasSimplificadas): string;
var
  iValor: Integer;
begin
  Result := 'A:';
  for iValor := 0 to High(AFiltros.Anyos) do
    Result := Result + IntToStr(AFiltros.Anyos[iValor]) + ';';
  Result := Result + '|L:';
  for iValor := 0 to High(AFiltros.Almacenes) do
    Result := Result + AFiltros.Almacenes[iValor] + ';';
  Result := Result + '|U:' +
    EmpresaRestringida(FContextoSesion, FParametrosApp) + ';' +
    AlmacenRestringido(FContextoSesion, FParametrosApp) + ';' +
    CajaRestringida(FContextoSesion, FParametrosApp);
end;

procedure TRepositorioFacturasSimplificadasPantallaUniDAC.
  AsignarParametrosFiltro(
  AConsulta: TUniQuery;
  const AFiltros: TFiltrosFacturasSimplificadas);
var
  iValor: Integer;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
begin
  for iValor := 0 to High(AFiltros.Anyos) do
  begin
    AConsulta.ParamByName('ANYO' + IntToStr(iValor)).AsInteger :=
      AFiltros.Anyos[iValor];
  end;
  for iValor := 0 to High(AFiltros.Almacenes) do
  begin
    AConsulta.ParamByName('ALMACEN' + IntToStr(iValor)).AsString :=
      AFiltros.Almacenes[iValor];
  end;
  sEmpresa := EmpresaRestringida(FContextoSesion, FParametrosApp);
  sAlmacen := AlmacenRestringido(FContextoSesion, FParametrosApp);
  sCaja := CajaRestringida(FContextoSesion, FParametrosApp);
  if sEmpresa <> '' then
    AConsulta.ParamByName('EMPRESA_USUARIO').AsString := sEmpresa;
  if sAlmacen <> '' then
    AConsulta.ParamByName('ALMACEN_USUARIO').AsString := sAlmacen;
  if sCaja <> '' then
    AConsulta.ParamByName('CAJA_USUARIO').AsString := sCaja;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.ListarAnyos:
  TArray<Integer>;
var
  iAnyo: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ANYOS + ' WHERE ' +
      SQLFiltroVistaListadoFacturas('vi_facturas_simplificadas') +
      ' AND FECHA_FAC IS NOT NULL ORDER BY ANYO DESC';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iAnyo := Length(Result);
      SetLength(Result, iAnyo + 1);
      Result[iAnyo] := oConsulta.FieldByName('ANYO').AsInteger;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.ListarAlmacenes:
  TAlmacenesFiltroFacturaSimplificada;
var
  iAlmacen: Integer;
  oConsulta: TUniQuery;
  sAlmacen: string;
  sEmpresa: string;
  sSql: string;
begin
  SetLength(Result, 0);
  sEmpresa := EmpresaRestringida(FContextoSesion, FParametrosApp);
  sAlmacen := AlmacenRestringido(FContextoSesion, FParametrosApp);
  sSql := SQL_ALMACENES;
  AnadirRestriccion(
    sSql, 'CODIGO_EMP_ALM', 'EMPRESA_USUARIO', sEmpresa);
  AnadirRestriccion(
    sSql, 'CODIGO_ALM_ALM', 'ALMACEN_USUARIO', sAlmacen);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := sSql + SQL_ORDEN_ALMACENES;
    if sEmpresa <> '' then
      oConsulta.ParamByName('EMPRESA_USUARIO').AsString := sEmpresa;
    if sAlmacen <> '' then
      oConsulta.ParamByName('ALMACEN_USUARIO').AsString := sAlmacen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iAlmacen := Length(Result);
      SetLength(Result, iAlmacen + 1);
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.ConfigurarListado(
  const AFiltros: TFiltrosFacturasSimplificadas): Boolean;
var
  sFirma: string;
begin
  sFirma := FirmaFiltros(AFiltros);
  Result := sFirma <> FFirmaFiltros;
  if Result then
  begin
    FListado.Close;
    FListado.SQL.Text := SQL_LISTADO + ConstruirWhere(AFiltros) +
      SQL_ORDEN_LISTADO;
    AsignarParametrosFiltro(FListado, AFiltros);
    FFirmaFiltros := sFirma;
  end;
end;

function TRepositorioFacturasSimplificadasPantallaUniDAC.Contar(
  const AFiltros: TFiltrosFacturasSimplificadas): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR + ConstruirWhere(AFiltros);
    AsignarParametrosFiltro(oConsulta, AFiltros);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFacturasSimplificadasPantallaUniDAC(
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion):
  IRepositorioFacturasSimplificadasPantalla;
begin
  Result := TRepositorioFacturasSimplificadasPantallaUniDAC.Create(
    AConexion,
    AListado,
    AContextoSesion,
    AParametrosApp);
end;

end.

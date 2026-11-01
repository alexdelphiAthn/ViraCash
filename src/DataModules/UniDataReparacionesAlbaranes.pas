{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesAlbaranes                                  }
{    Tipo:       Persistencia                                                  }
{  Versión:       1.0.0                                                        }
{    Fecha:       31/10/2026                                                   }
{    Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Vistas y vínculos de albaranes TALLER de una orden.                       }
{******************************************************************************}
unit UniDataReparacionesAlbaranes;

interface

uses
  System.Classes, Data.DB, Uni;

type
  TDatosAlbaranesOrden = class(TComponent)
  private
    FConexion: TUniConnection;
    FUsuario: string;
    FCliente: TUniQuery;
    FProveedor: TUniQuery;
    FdsCliente: TDataSource;
    FdsProveedor: TDataSource;
    function Consulta(const ASql: string): TUniQuery;
    function CrearLista(AProveedor: Boolean): TUniQuery;
    procedure CambiarVinculo(AOrden: Int64; AProveedor, ABorrar: Boolean;
      const ASerie, ANumero: string);
    procedure ComprobarDocumento(AOrden: Int64; AProveedor, ABorrar: Boolean;
      const ASerie, ANumero: string);
    function LineasFacturadas(AProveedor: Boolean;
      const ASerie, ANumero: string): Boolean;
  public
    constructor CreateDatos(AOwner: TComponent; AConexion: TUniConnection;
      const AUsuario: string);
    procedure AsignarMaestro(AMaestro: TDataSource);
    procedure Refrescar;
    procedure Vincular(AOrden: Int64; AProveedor: Boolean;
      const ASerie, ANumero: string);
    procedure Desvincular(AOrden: Int64; AProveedor: Boolean;
      const ASerie, ANumero: string);
    property Cliente: TDataSource read FdsCliente;
    property Proveedor: TDataSource read FdsProveedor;
  end;

function SqlAlbaranesOrden(AProveedor: Boolean): string;

implementation

uses
  UniDataReparacionesProteccion,
  System.SysUtils, inLibMsgReparaciones;

function TablaDocumento(AProveedor: Boolean): string;
begin
  Result := 'fza_albaranes';
  if AProveedor then
    Result := 'fza_albaranes_compra';
end;

function SufijoDocumento(AProveedor: Boolean): string;
begin
  Result := 'ALB';
  if AProveedor then
    Result := 'ALBC';
end;

function TipoVinculo(AProveedor: Boolean): string;
begin
  Result := 'CL';
  if AProveedor then
    Result := 'PR';
end;

function SqlDocumento(AProveedor: Boolean): string;
var
  sSufijo, sTercero, sNombre: string;
begin
  sSufijo := SufijoDocumento(AProveedor);
  sTercero := 'CLI';
  sNombre := 'CLIENTE';
  if AProveedor then
  begin
    sTercero := 'PRV';
    sNombre := 'PRV';
  end;
  Result := 'SELECT D.SERIE_' + sSufijo + ' AS SERIE, D.NUMERO_' +
    sSufijo + ' AS NUMERO, D.FECHA_' + sSufijo + ' AS FECHA, ' +
    'D.CODIGO_' + sTercero + '_' + sSufijo + ' AS TERCERO, ' +
    'D.RAZON_SOCIAL_' + sNombre + '_' + sSufijo + ' AS NOMBRE, ' +
    'D.CODIGO_ALM_' + sSufijo + ' AS ALMACEN, D.ESTADO_' + sSufijo +
    ' AS ESTADO, D.TOTAL_LIQUIDO_' + sSufijo + ' AS TOTAL, ' +
    'D.SERIE_FAC_' + sSufijo + ' AS SERIE_FACTURA, D.NUMERO_FAC_' +
    sSufijo + ' AS NUMERO_FACTURA FROM ' + TablaDocumento(AProveedor) +
    ' D JOIN fza_almacenes A ON A.CODIGO_ALM_ALM=D.CODIGO_ALM_' + sSufijo;
end;

function SqlAlbaranesOrden(AProveedor: Boolean): string;
var
  sSufijo: string;
begin
  sSufijo := SufijoDocumento(AProveedor);
  Result := StringReplace(SqlDocumento(AProveedor), 'SELECT ',
    'SELECT V.ID_GAR_GARALB, ', []) +
    ' JOIN fza_reparaciones_albaranes V ON V.SERIE_GARALB=D.SERIE_' +
    sSufijo + ' AND V.NUMERO_GARALB=D.NUMERO_' + sSufijo +
    ' JOIN fza_garantias_reclamaciones G ON G.ID_GAR=V.ID_GAR_GARALB ' +
    ' JOIN fza_almacenes O ON O.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR ' +
    ' WHERE V.ID_GAR_GARALB=:ID_GAR AND V.TIPO_GARALB=''' +
    TipoVinculo(AProveedor) + ''' ' +
    ' AND D.CODIGO_EMP_' + sSufijo + '=O.CODIGO_EMP_ALM ' +
    // También los creados desde el almacén de la orden cuando la tienda
    // no tiene almacén TALLER.
    ' AND (A.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR OR ' +
    ' (A.TIPO_USO_ALM=''TALLER'' AND (A.CODIGO_PADRE_ALM=G.CODIGO_ALM_GAR ' +
    ' OR A.ESCOMPARTIDO_ALM=''S''))) ORDER BY D.FECHA_' + sSufijo +
    ' DESC, D.SERIE_' + sSufijo + ', D.NUMERO_' + sSufijo;
end;

constructor TDatosAlbaranesOrden.CreateDatos(AOwner: TComponent;
  AConexion: TUniConnection; const AUsuario: string);
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FUsuario := AUsuario;
  FCliente := CrearLista(False);
  FProveedor := CrearLista(True);
  FdsCliente := TDataSource.Create(Self);
  FdsCliente.DataSet := FCliente;
  FdsProveedor := TDataSource.Create(Self);
  FdsProveedor.DataSet := FProveedor;
end;

function TDatosAlbaranesOrden.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(Self);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TDatosAlbaranesOrden.CrearLista(AProveedor: Boolean): TUniQuery;
begin
  Result := Consulta(SqlAlbaranesOrden(AProveedor));
  Result.ReadOnly := True;
  Result.MasterFields := 'ID_GAR';
  Result.DetailFields := 'ID_GAR_GARALB';
end;

procedure TDatosAlbaranesOrden.AsignarMaestro(AMaestro: TDataSource);
begin
  FCliente.MasterSource := AMaestro;
  FProveedor.MasterSource := AMaestro;
  FCliente.Open;
  FProveedor.Open;
end;

procedure TDatosAlbaranesOrden.Refrescar;
begin
  if FCliente.Active then
    FCliente.Refresh;
  if FProveedor.Active then
    FProveedor.Refresh;
end;

procedure TDatosAlbaranesOrden.ComprobarDocumento(AOrden: Int64;
  AProveedor, ABorrar: Boolean; const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
  sSufijo, sFiltroTercero: string;
begin
  sSufijo := SufijoDocumento(AProveedor);
  sFiltroTercero := '';
  if not AProveedor then
    sFiltroTercero := ' AND (G.CODIGO_CLI_GAR=D.CODIGO_CLI_ALB ' +
      ' OR G.CODIGO_CLI_PAGADOR_GAR=D.CODIGO_CLI_ALB)';
  oConsulta := Consulta(SqlDocumento(AProveedor) +
    ' JOIN fza_garantias_reclamaciones G ON G.ID_GAR=:ID ' +
    ' JOIN fza_almacenes O ON O.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR ' +
    ' WHERE D.SERIE_' + sSufijo + '=:SERIE AND D.NUMERO_' +
    sSufijo + '=:NUMERO ' +
    ' AND D.CODIGO_EMP_' + sSufijo + '=O.CODIGO_EMP_ALM ' +
    // Almacén de la orden (tienda sin TALLER) o TALLER de esa tienda.
    ' AND (A.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR OR ' +
    ' (A.TIPO_USO_ALM=''TALLER'' AND (A.CODIGO_PADRE_ALM=G.CODIGO_ALM_GAR ' +
    ' OR A.ESCOMPARTIDO_ALM=''S''))) ' + sFiltroTercero + ' FOR UPDATE');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AOrden;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SAlbaranTallerNoValido);
    if not ABorrar and
       SameText(oConsulta.FieldByName('ESTADO').AsString, 'CANCELADO') then
      raise EArgumentException.Create(SAlbaranTallerNoValido);
    if ABorrar and
       ((Trim(oConsulta.FieldByName('NUMERO_FACTURA').AsString) <> '') or
        SameText(oConsulta.FieldByName('ESTADO').AsString, 'FACTURADO') or
        LineasFacturadas(AProveedor, ASerie, ANumero)) then
      raise EArgumentException.Create(SAlbaranFacturadoNoDesvincular);
  finally
    oConsulta.Free;
  end;
end;

function TDatosAlbaranesOrden.LineasFacturadas(AProveedor: Boolean;
  const ASerie, ANumero: string): Boolean;
var
  oConsulta: TUniQuery;
  sCabecera, sLinea: string;
begin
  sCabecera := SufijoDocumento(AProveedor);
  sLinea := sCabecera + 'LIN';
  oConsulta := Consulta('SELECT 1 FROM ' + TablaDocumento(AProveedor) +
    '_lineas L WHERE L.SERIE_' + sCabecera + '_' + sLinea + '=:SERIE ' +
    'AND L.NUMERO_' + sCabecera + '_' + sLinea + '=:NUMERO AND (' +
    'L.ESFACTURADA_' + sLinea + '=''S'' OR ' +
    'COALESCE(L.NUMERO_FAC_' + sLinea + ', '''')<>'''' OR ' +
    'COALESCE(L.SERIE_FAC_' + sLinea + ', '''')<>'''') LIMIT 1');
  try
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    oConsulta.Free;
  end;
end;

procedure TDatosAlbaranesOrden.CambiarVinculo(AOrden: Int64;
  AProveedor, ABorrar: Boolean; const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
  bPropia: Boolean;
begin
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    ComprobarDocumento(AOrden, AProveedor, ABorrar, ASerie, ANumero);
    if ABorrar then
      ExigirDocumentoOrdenEditable(FConexion, ASerie, ANumero, AProveedor);
    if ABorrar then
      oConsulta := Consulta('DELETE FROM fza_reparaciones_albaranes ' +
        'WHERE ID_GAR_GARALB=:ID AND TIPO_GARALB=:TIPO ' +
        'AND SERIE_GARALB=:SERIE AND NUMERO_GARALB=:NUMERO')
    else
      oConsulta := Consulta('INSERT INTO fza_reparaciones_albaranes ' +
        '(ID_GAR_GARALB,TIPO_GARALB,SERIE_GARALB,NUMERO_GARALB,' +
        'USUARIO_ALTA) VALUES (:ID,:TIPO,:SERIE,:NUMERO,:USUARIO) ' +
        'ON DUPLICATE KEY UPDATE ID_GAR_GARALB=VALUES(ID_GAR_GARALB)');
    try
      oConsulta.ParamByName('ID').AsLargeInt := AOrden;
      oConsulta.ParamByName('TIPO').AsString := TipoVinculo(AProveedor);
      oConsulta.ParamByName('SERIE').AsString := Trim(ASerie);
      oConsulta.ParamByName('NUMERO').AsString := Trim(ANumero);
      if not ABorrar then
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
      oConsulta.Execute;
    finally
      oConsulta.Free;
    end;
    if bPropia then
      FConexion.Commit;
  except
    if bPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
  Refrescar;
end;

procedure TDatosAlbaranesOrden.Vincular(AOrden: Int64;
  AProveedor: Boolean; const ASerie, ANumero: string);
begin
  CambiarVinculo(AOrden, AProveedor, False, ASerie, ANumero);
end;

procedure TDatosAlbaranesOrden.Desvincular(AOrden: Int64;
  AProveedor: Boolean; const ASerie, ANumero: string);
begin
  CambiarVinculo(AOrden, AProveedor, True, ASerie, ANumero);
end;

end.

{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDistribuidorRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del distribuidor por almacen y talla.                 }
{******************************************************************************}
unit UniDataDistribuidorRepositorio;

interface

uses
  Uni, inLibDistribuidorPersistenciaIntf;

function CrearRepositorioDistribuidorUniDAC(
  AConexion: TUniConnection): IRepositorioDistribuidor;

implementation

uses
  System.SysUtils;

const
  SQL_LISTAR_ALMACENES =
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
    'FROM fza_almacenes WHERE ESACTIVO_ALM = ''S'' ' +
    'AND TIPO_USO_ALM IN (''ESTANDAR'', ''ESTANDARD'') ' +
    'ORDER BY CODIGO_ALM_ALM';
  SQL_LISTAR_VALORES_KIT =
    'SELECT VALOR_DESTINO_PRVKITD, CANTIDAD_PRVKITD ' +
    'FROM fza_proveedores_kits_det ' +
    'WHERE CODIGO_PRV_PRVKITD = :prv ' +
    'AND CODIGO_PRVKIT_PRVKITD = :kit';

type
  TRepositorioDistribuidorUniDAC = class(
    TInterfacedObject,
    IRepositorioDistribuidor)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarAlmacenes: TAlmacenesDistribuidor;
    function ListarCeldas(
      const AConfiguracion: TConfiguracionCeldasDistribuidor;
      const ADocumento: TDocumentoDistribuidor
    ): TCeldasDistribuidor;
    function ListarValoresKit(
      const ACodigoProveedor: string;
      const ACodigoKit: string
    ): TValoresKitDistribuidor;
    procedure GuardarCambios(
      const AConfiguracion: TConfiguracionCeldasDistribuidor;
      const ADocumento: TDocumentoDistribuidor;
      const AUsuario: string;
      const ACambios: TCambiosCeldasDistribuidor);
  end;

constructor TRepositorioDistribuidorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDistribuidorUniDAC.ListarAlmacenes:
  TAlmacenesDistribuidor;
var
  iAlmacen: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_ALMACENES;
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

function TRepositorioDistribuidorUniDAC.ListarCeldas(
  const AConfiguracion: TConfiguracionCeldasDistribuidor;
  const ADocumento: TDocumentoDistribuidor): TCeldasDistribuidor;
var
  iCelda: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ' + AConfiguracion.CampoAlmacen +
      ' AS CODIGO_ALM_CEL, ' + AConfiguracion.CampoAtributoValor +
      ' AS ID_AV_CEL, ' + AConfiguracion.CampoCantidad +
      ' AS CANTIDAD_CEL FROM ' + AConfiguracion.Tabla +
      ' WHERE ' + AConfiguracion.CampoSerie + ' = :s AND ' +
      AConfiguracion.CampoNumero + ' = :n AND ' +
      AConfiguracion.CampoLinea + ' = :l';
    oConsulta.ParamByName('s').AsString := ADocumento.Serie;
    oConsulta.ParamByName('n').AsString := ADocumento.Numero;
    oConsulta.ParamByName('l').AsInteger := ADocumento.Linea;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCelda := Length(Result);
      SetLength(Result, iCelda + 1);
      Result[iCelda].CodigoAlmacen :=
        oConsulta.FieldByName('CODIGO_ALM_CEL').AsString;
      Result[iCelda].IdAtributoValor :=
        oConsulta.FieldByName('ID_AV_CEL').AsInteger;
      Result[iCelda].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_CEL').AsFloat;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribuidorUniDAC.ListarValoresKit(
  const ACodigoProveedor: string;
  const ACodigoKit: string): TValoresKitDistribuidor;
var
  iValor: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_VALORES_KIT;
    oConsulta.ParamByName('prv').AsString := ACodigoProveedor;
    oConsulta.ParamByName('kit').AsString := ACodigoKit;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iValor := Length(Result);
      SetLength(Result, iValor + 1);
      Result[iValor].ValorDestino :=
        oConsulta.FieldByName('VALOR_DESTINO_PRVKITD').AsString;
      Result[iValor].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_PRVKITD').AsFloat;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioDistribuidorUniDAC.GuardarCambios(
  const AConfiguracion: TConfiguracionCeldasDistribuidor;
  const ADocumento: TDocumentoDistribuidor;
  const AUsuario: string;
  const ACambios: TCambiosCeldasDistribuidor);
var
  oCambio: TCambioCeldaDistribuidor;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    for oCambio in ACambios do
    begin
      oConsulta.Close;
      if oCambio.Cantidad > 0 then
      begin
        oConsulta.SQL.Text :=
          'INSERT INTO ' + AConfiguracion.Tabla + ' (' +
          AConfiguracion.CampoSerie + ', ' +
          AConfiguracion.CampoNumero + ', ' +
          AConfiguracion.CampoLinea + ', ' +
          AConfiguracion.CampoFila + ', ' +
          AConfiguracion.CampoAlmacen + ', ' +
          AConfiguracion.CampoAtributoValor + ', ' +
          AConfiguracion.CampoCantidad + ', INSTANTE_ALTA, ' +
          'USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:s, :n, :l, 1, :a, :p, :c, NOW(), :u, NOW(), :u) ' +
          'ON DUPLICATE KEY UPDATE ' + AConfiguracion.CampoCantidad +
          ' = :c, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
        oConsulta.ParamByName('c').AsFloat := oCambio.Cantidad;
        oConsulta.ParamByName('u').AsString := AUsuario;
      end
      else
      begin
        oConsulta.SQL.Text :=
          'DELETE FROM ' + AConfiguracion.Tabla + ' WHERE ' +
          AConfiguracion.CampoSerie + ' = :s AND ' +
          AConfiguracion.CampoNumero + ' = :n AND ' +
          AConfiguracion.CampoLinea + ' = :l AND ' +
          AConfiguracion.CampoAlmacen + ' = :a AND ' +
          AConfiguracion.CampoAtributoValor + ' = :p';
      end;
      oConsulta.ParamByName('s').AsString := ADocumento.Serie;
      oConsulta.ParamByName('n').AsString := ADocumento.Numero;
      oConsulta.ParamByName('l').AsInteger := ADocumento.Linea;
      oConsulta.ParamByName('a').AsString := oCambio.CodigoAlmacen;
      oConsulta.ParamByName('p').AsInteger := oCambio.IdAtributoValor;
      oConsulta.ExecSQL;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioDistribuidorUniDAC(
  AConexion: TUniConnection): IRepositorioDistribuidor;
begin
  Result := TRepositorioDistribuidorUniDAC.Create(AConexion);
end;

end.

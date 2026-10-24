{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInventarioNubeRepositorio                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para enviar y materializar recuentos de inventario.      }
{******************************************************************************}
unit UniDataInventarioNubeRepositorio;

interface

uses
  Uni,
  inLibInventarioNubePersistenciaIntf;

function CrearInventarioNubeRepositorio(
  AConexion: TUniConnection): IInventarioNubePersistencia;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  inLibTrazabilidad;

type
  TInventarioNubeRepositorio = class(
    TInterfacedObject,
    IInventarioNubePersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarLineas(
      const AClave: TClaveInventarioNube): TLineasInventarioNube;
    function GuardarEventoSiNuevo(
      const AClave: TClaveInventarioNube;
      const AEvento: TEventoInventarioNube;
      const AUsuario: string): Boolean;
  end;

function CrearInventarioNubeRepositorio(
  AConexion: TUniConnection): IInventarioNubePersistencia;
begin
  Result := TInventarioNubeRepositorio.Create(AConexion);
end;

constructor TInventarioNubeRepositorio.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TInventarioNubeRepositorio.ListarLineas(
  const AClave: TClaveInventarioNube): TLineasInventarioNube;
var
  oConsulta: TUniQuery;
  oLineas: TList<TLineaInventarioNube>;
  oLinea: TLineaInventarioNube;
begin
  oConsulta := TUniQuery.Create(nil);
  oLineas := TList<TLineaInventarioNube>.Create;
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.CODIGO_ART_INVLIN, L.CODIGO_UNIDAD_INVLIN, ' +
      '       L.DESCRIPCION_ARTICULO_INVLIN, ' +
      '       L.CANTIDAD_TEORICA_INVLIN, A.TIPO_TRAZABILIDAD_ART, ' +
      '       CB.CODIGO_BARRAS_CB ' +
      '  FROM fza_inventarios_lineas L ' +
      '  LEFT JOIN fza_articulos A ' +
      '    ON A.CODIGO_ART_ART = L.CODIGO_ART_INVLIN ' +
      '  LEFT JOIN fza_codigos_barras CB ' +
      '    ON CB.CODIGO_UNIDAD_CB = L.CODIGO_UNIDAD_INVLIN ' +
      ' WHERE L.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND L.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND L.SERIE_INV_INVLIN = :SERIE ' +
      '   AND L.NUMERO_INV_INVLIN = :NUMERO';
    oConsulta.ParamByName('EMPRESA').AsString := AClave.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := AClave.Almacen;
    oConsulta.ParamByName('SERIE').AsString := AClave.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AClave.Numero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLinea := Default(TLineaInventarioNube);
      oLinea.CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART_INVLIN').AsString;
      oLinea.CodigoUnidad :=
        oConsulta.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
      oLinea.Descripcion :=
        oConsulta.FieldByName(
          'DESCRIPCION_ARTICULO_INVLIN').AsString;
      oLinea.CodigoBarras :=
        oConsulta.FieldByName('CODIGO_BARRAS_CB').AsString;
      oLinea.CantidadTeorica :=
        oConsulta.FieldByName('CANTIDAD_TEORICA_INVLIN').AsFloat;
      // F-LOTEC-014: la app pide lote si el modo efectivo del artículo lo
      // pide con los interruptores vigentes.
      oLinea.EsTrazable := ValorEsTrazable(ActivacionVigente.ModoEfectivo(
        ModoDesdeCadena(
          oConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString)));
      oLineas.Add(oLinea);
      oConsulta.Next;
    end;
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oLineas);
    FreeAndNil(oConsulta);
  end;
end;

function TInventarioNubeRepositorio.GuardarEventoSiNuevo(
  const AClave: TClaveInventarioNube;
  const AEvento: TEventoInventarioNube;
  const AUsuario: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO fza_inventarios_recuentos ' +
      '  (UUID_INVREC, CODIGO_EMP_INVREC, CODIGO_ALM_INVREC, ' +
      '   SERIE_INV_INVREC, NUMERO_INV_INVREC, CODIGO_ART_INVREC, ' +
      '   CODIGO_UNIDAD_INVREC, CODIGO_BARRAS_INVREC, ' +
      '   CANTIDAD_INVREC, LOTE_INVREC, FECHA_CADUCIDAD_INVREC, ' +
      '   INSTANTE_RECUENTO_INVREC, INSTANTE_RECUENTO_UTC_INVREC, ' +
      '   OPERARIO_INVREC, ' +
      '   DISPOSITIVO_INVREC, ZONA_INVREC, ESANULADO_INVREC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:UUID, :EMPRESA, :ALMACEN, :SERIE, :NUMERO, ' +
      '  :ARTICULO, :SKU, :BARRAS, :CANTIDAD, :LOTE, :CADUCIDAD, ' +
      '  :INSTANTE, :INSTANTE_UTC, :OPERARIO, :DISPOSITIVO, ' +
      '  :ZONA, ''N'', ' +
      '  NOW(), :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE ID_INVREC = ID_INVREC';
    oConsulta.ParamByName('UUID').AsString := AEvento.Uuid;
    oConsulta.ParamByName('EMPRESA').AsString := AClave.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := AClave.Almacen;
    oConsulta.ParamByName('SERIE').AsString := AClave.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AClave.Numero;
    oConsulta.ParamByName('ARTICULO').AsString :=
      AEvento.CodigoArticulo;
    oConsulta.ParamByName('SKU').AsString := AEvento.CodigoUnidad;
    oConsulta.ParamByName('BARRAS').AsString := AEvento.CodigoBarras;
    oConsulta.ParamByName('CANTIDAD').AsFloat := AEvento.Cantidad;
    oConsulta.ParamByName('LOTE').AsString := AEvento.Lote;
    if Trim(AEvento.FechaCaducidad) = '' then
      oConsulta.ParamByName('CADUCIDAD').Clear
    else
      oConsulta.ParamByName('CADUCIDAD').AsString :=
        AEvento.FechaCaducidad;
    oConsulta.ParamByName('INSTANTE').AsString :=
      AEvento.InstanteRecuento;
    if Trim(AEvento.InstanteRecuentoUtc) = '' then
      oConsulta.ParamByName('INSTANTE_UTC').Clear
    else
      oConsulta.ParamByName('INSTANTE_UTC').AsString :=
        AEvento.InstanteRecuentoUtc;
    oConsulta.ParamByName('OPERARIO').AsString := AEvento.Operario;
    oConsulta.ParamByName('DISPOSITIVO').AsString :=
      AEvento.Dispositivo;
    oConsulta.ParamByName('ZONA').AsString := AEvento.Zona;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ExecSQL;
    Result := oConsulta.RowsAffected = 1;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

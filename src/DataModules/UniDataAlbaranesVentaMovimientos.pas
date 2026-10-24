{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesVentaMovimientos                             }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persiste y protege los movimientos de salida de albaranes de venta.       }
{******************************************************************************}
unit UniDataAlbaranesVentaMovimientos;

interface

uses
  Uni,
  inLibLogIntf,
  inLibAlbaranesVentaPresentacionMovimientos;

function CrearPersistenciaMovimientosAlbaranVentaUniDAC(
  AConexion: TUniConnection;
  AProcedimientoMovimiento: TUniStoredProc;
  const ARegistroLog: IRegistroLog):
  IPersistenciaMovimientosAlbaranVenta;
function CrearUnidadTrabajoMovimientosAlbaranVentaUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoMovimientosAlbaranVenta;

implementation

uses
  System.SysUtils,
  Data.DB,
  UniDataMovimientosLote,
  inLibContadorLineas,
  inLibDocumento,
  inLibPrestaShopColaSenal,
  UniDataContadorLineasRepositorio,
  UniDataMovimientosAlmacenRecalculo,
  UniDataValoresAutomaticosRepositorio;

type
  TLineaMovimientoAlbaranVenta = record
    Linea: string;
    Sku: string;
    Almacen: string;
    Articulo: string;
    Cantidad: Double;
    // F-LOTEC-016: lote o serie ('' sin lote); 0 = sin caducidad.
    Lote: string;
    FechaCaducidad: TDate;
  end;
  TPersistenciaMovimientosAlbaranVentaUniDAC = class(
    TInterfacedObject, IPersistenciaMovimientosAlbaranVenta)
  private
    FConexion: TUniConnection;
    FProcedimientoMovimiento: TUniStoredProc;
    // Para las líneas con lote (lo crea y libera esta clase).
    FProcedimientoLote: TUniStoredProc;
    FRegistroLog: IRegistroLog;
    procedure ActualizarAlmacenLineas(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    function CrearConsultaLineasPreparacion(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
    procedure PrepararLinea(
      AConsultaLineas, AConsultaActualizacion: TUniQuery;
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    function AsignarNumeroLinea(
      AConsultaActualizacion: TUniQuery;
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALineaAnterior: string): string;
    procedure AsignarSkuLinea(
      AConsultaActualizacion: TUniQuery;
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALinea, AArticulo, ASku: string);
    function ResolverSku(const AArticulo, AUsuario: string): string;
    function BuscarSkuUnico(
      AConsulta: TUniQuery;
      const AArticulo: string;
      out ASkusActivos: Integer): string;
    procedure CrearSkuSimpleSiProcede(
      AConsulta: TUniQuery;
      const AArticulo, AUsuario: string);
    function BuscarSkuSimple(
      AConsulta: TUniQuery;
      const AArticulo: string): string;
    function CrearConsultaLineasMovimiento(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
    function CrearConsultaExistencia(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
    function LeerLinea(AConsulta: TUniQuery;
      const AAlmacenCabecera: string): TLineaMovimientoAlbaranVenta;
    function PuedeGenerar(
      const ALinea: TLineaMovimientoAlbaranVenta): Boolean;
    function ExisteMovimiento(AConsulta: TUniQuery;
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALinea: string): Boolean;
    procedure DefinirParametrosMovimiento;
    procedure AsignarParametrosMovimiento(
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALinea: TLineaMovimientoAlbaranVenta;
      const ANumeroMovimiento: string);
    procedure InsertarMovimiento(
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALinea: TLineaMovimientoAlbaranVenta);
    procedure AvisarLineaSinMovimiento(
      const ADocumento: TDocumentoMovimientosAlbaranVenta;
      const ALinea: TLineaMovimientoAlbaranVenta);
  public
    constructor Create(
      AConexion: TUniConnection;
      AProcedimientoMovimiento: TUniStoredProc;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure PrepararLineas(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    procedure Borrar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    function Generar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
  end;
  TUnidadTrabajoMovimientosAlbaranVentaUniDAC = class(
    TInterfacedObject, IUnidadTrabajoMovimientosAlbaranVenta)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

constructor TPersistenciaMovimientosAlbaranVentaUniDAC.Create(
  AConexion: TUniConnection;
  AProcedimientoMovimiento: TUniStoredProc;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  if AProcedimientoMovimiento = nil then
    raise EArgumentNilException.Create('AProcedimientoMovimiento');
  if ARegistroLog = nil then
    raise EArgumentNilException.Create('ARegistroLog');
  FConexion := AConexion;
  FProcedimientoMovimiento := AProcedimientoMovimiento;
  FProcedimientoLote := TUniStoredProc.Create(nil);
  FRegistroLog := ARegistroLog;
end;

destructor TPersistenciaMovimientosAlbaranVentaUniDAC.Destroy;
begin
  FreeAndNil(FProcedimientoLote);
  inherited;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.ActualizarAlmacenLineas(
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'UPDATE fza_albaranes_lineas ' +
      '   SET CODIGO_ALMACEN_ALBLIN = :ALMACEN, ' +
      '       USUARIO_MODIF = :USUARIO, ' +
      '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
      ' WHERE SERIE_ALB_ALBLIN = :SERIE ' +
      '   AND NUMERO_ALB_ALBLIN = :NUMERO ' +
      '   AND COALESCE(CODIGO_ALMACEN_ALBLIN, '''') <> :ALMACEN2';
    oConsulta.ParamByName('ALMACEN').AsString := ADocumento.Almacen;
    oConsulta.ParamByName('ALMACEN2').AsString := ADocumento.Almacen;
    oConsulta.ParamByName('USUARIO').AsString := ADocumento.Usuario;
    oConsulta.ParamByName('SERIE').AsString := ADocumento.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ADocumento.Numero;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.
  CrearConsultaLineasPreparacion(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text :=
    'SELECT LINEA_ALBLIN, CODIGO_ART_ALBLIN, CODIGO_UNIDAD_ALBLIN ' +
    '  FROM fza_albaranes_lineas ' +
    ' WHERE SERIE_ALB_ALBLIN = :SERIE ' +
    '   AND NUMERO_ALB_ALBLIN = :NUMERO ' +
    ' ORDER BY LINEA_ALBLIN, INSTANTE_ALTA, CODIGO_ART_ALBLIN';
  Result.ParamByName('SERIE').AsString := ADocumento.Serie;
  Result.ParamByName('NUMERO').AsString := ADocumento.Numero;
  Result.Open;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.AsignarNumeroLinea(
  AConsultaActualizacion: TUniQuery;
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALineaAnterior: string): string;
var
  iNuevaLinea: Integer;
begin
  Result := ALineaAnterior;
  if (ALineaAnterior = '') or
     (StrToIntDef(ALineaAnterior, 0) = 0) then
  begin
    iNuevaLinea := GetSiguienteLineaDocLibre(
      CrearContadorLineasDocumento(FConexion),
      CONT_ALBARANES,
      LIN_ALBARANES,
      ADocumento.Serie,
      ADocumento.Numero);
    if iNuevaLinea > 0 then
    begin
      Result := Format('%.4d', [iNuevaLinea]);
      AConsultaActualizacion.SQL.Text :=
        'UPDATE fza_albaranes_lineas ' +
        '   SET LINEA_ALBLIN = :LINEA, ' +
        '       USUARIO_MODIF = :USUARIO, ' +
        '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
        ' WHERE SERIE_ALB_ALBLIN = :SERIE ' +
        '   AND NUMERO_ALB_ALBLIN = :NUMERO ' +
        '   AND COALESCE(LINEA_ALBLIN, '''') = :LINEA_ANTERIOR ' +
        ' ORDER BY INSTANTE_ALTA, CODIGO_ART_ALBLIN LIMIT 1';
      AConsultaActualizacion.ParamByName('LINEA').AsString := Result;
      AConsultaActualizacion.ParamByName('USUARIO').AsString :=
        ADocumento.Usuario;
      AConsultaActualizacion.ParamByName('SERIE').AsString :=
        ADocumento.Serie;
      AConsultaActualizacion.ParamByName('NUMERO').AsString :=
        ADocumento.Numero;
      AConsultaActualizacion.ParamByName('LINEA_ANTERIOR').AsString :=
        ALineaAnterior;
      AConsultaActualizacion.ExecSQL;
      if AConsultaActualizacion.RowsAffected = 0 then
        Result := ALineaAnterior;
    end;
  end;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.AsignarSkuLinea(
  AConsultaActualizacion: TUniQuery;
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALinea, AArticulo, ASku: string);
begin
  AConsultaActualizacion.SQL.Text :=
    'UPDATE fza_albaranes_lineas ' +
    '   SET CODIGO_UNIDAD_ALBLIN = :SKU, ' +
    '       USUARIO_MODIF = :USUARIO, ' +
    '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
    ' WHERE SERIE_ALB_ALBLIN = :SERIE ' +
    '   AND NUMERO_ALB_ALBLIN = :NUMERO ' +
    '   AND COALESCE(LINEA_ALBLIN, '''') = :LINEA ' +
    '   AND CODIGO_ART_ALBLIN = :ARTICULO ' +
    '   AND COALESCE(CODIGO_UNIDAD_ALBLIN, '''') = ''''';
  AConsultaActualizacion.ParamByName('SKU').AsString := ASku;
  AConsultaActualizacion.ParamByName('USUARIO').AsString :=
    ADocumento.Usuario;
  AConsultaActualizacion.ParamByName('SERIE').AsString := ADocumento.Serie;
  AConsultaActualizacion.ParamByName('NUMERO').AsString := ADocumento.Numero;
  AConsultaActualizacion.ParamByName('LINEA').AsString := ALinea;
  AConsultaActualizacion.ParamByName('ARTICULO').AsString := AArticulo;
  AConsultaActualizacion.ExecSQL;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.PrepararLinea(
  AConsultaLineas, AConsultaActualizacion: TUniQuery;
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
var
  sArticulo: string;
  sLinea: string;
  sSku: string;
begin
  sLinea := Trim(AConsultaLineas.FieldByName('LINEA_ALBLIN').AsString);
  sLinea := AsignarNumeroLinea(
    AConsultaActualizacion, ADocumento, sLinea);
  sArticulo := Trim(
    AConsultaLineas.FieldByName('CODIGO_ART_ALBLIN').AsString);
  sSku := Trim(
    AConsultaLineas.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
  if (sSku = '') and (sArticulo <> '') then
  begin
    sSku := ResolverSku(sArticulo, ADocumento.Usuario);
    if sSku <> '' then
      AsignarSkuLinea(
        AConsultaActualizacion,
        ADocumento,
        sLinea,
        sArticulo,
        sSku);
  end;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.PrepararLineas(
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
var
  oConsultaActualizacion: TUniQuery;
  oConsultaLineas: TUniQuery;
begin
  ActualizarAlmacenLineas(ADocumento);
  oConsultaLineas := CrearConsultaLineasPreparacion(ADocumento);
  oConsultaActualizacion := TUniQuery.Create(nil);
  try
    oConsultaActualizacion.Connection := FConexion;
    while not oConsultaLineas.Eof do
    begin
      PrepararLinea(
        oConsultaLineas, oConsultaActualizacion, ADocumento);
      oConsultaLineas.Next;
    end;
  finally
    FreeAndNil(oConsultaLineas);
    FreeAndNil(oConsultaActualizacion);
  end;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.BuscarSkuUnico(
  AConsulta: TUniQuery;
  const AArticulo: string;
  out ASkusActivos: Integer): string;
var
  iSkus: Integer;
begin
  Result := '';
  AConsulta.SQL.Text :=
    'SELECT CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus ' +
    ' WHERE CODIGO_ART_SKU = :ARTICULO ' +
    '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S'' ' +
    ' ORDER BY CODIGO_UNIDAD_SKU';
  AConsulta.ParamByName('ARTICULO').AsString := AArticulo;
  AConsulta.Open;
  iSkus := 0;
  while not AConsulta.Eof do
  begin
    Inc(iSkus);
    if iSkus = 1 then
      Result := AConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    AConsulta.Next;
  end;
  AConsulta.Close;
  ASkusActivos := iSkus;
  if iSkus <> 1 then
    Result := '';
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.CrearSkuSimpleSiProcede(
  AConsulta: TUniQuery;
  const AArticulo, AUsuario: string);
begin
  AConsulta.SQL.Text :=
    'INSERT IGNORE INTO fza_articulos_skus ' +
    '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT a.CODIGO_ART_ART, a.CODIGO_ART_ART, ''-'', ''S'', ' +
    '       CURRENT_TIMESTAMP, :USUARIO, :USUARIO ' +
    '  FROM fza_articulos a ' +
    ' WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    '   AND COALESCE(a.ESVARIACION_ART, ''N'') = ''N'' ' +
    '   AND COALESCE(a.ESACTIVO_ART, ''S'') = ''S'' ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_articulos_skus sk ' +
    '                    WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART)';
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('ARTICULO').AsString := AArticulo;
  AConsulta.ExecSQL;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.BuscarSkuSimple(
  AConsulta: TUniQuery;
  const AArticulo: string): string;
begin
  Result := '';
  AConsulta.SQL.Text :=
    'SELECT CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus ' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU ' +
    '   AND CODIGO_ART_SKU = :ARTICULO ' +
    '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S''';
  AConsulta.ParamByName('SKU').AsString := AArticulo;
  AConsulta.ParamByName('ARTICULO').AsString := AArticulo;
  AConsulta.Open;
  if not AConsulta.Eof then
    Result := AConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  AConsulta.Close;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.ResolverSku(
  const AArticulo, AUsuario: string): string;
var
  oConsulta: TUniQuery;
  iSkusActivos: Integer;
begin
  Result := '';
  if Trim(AArticulo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      Result := BuscarSkuUnico(
        oConsulta, Trim(AArticulo), iSkusActivos);
      // FZ-ISSUE-430: con varios SKU activos (tallas, colores) no se
      // elige ninguno: la línea queda sin SKU y no mueve stock. Antes
      // se tomaba el SKU con el código del modelo, si existía, y el
      // albarán descontaba del modelo.
      if (Result = '') and (iSkusActivos = 0) then
      begin
        CrearSkuSimpleSiProcede(oConsulta, Trim(AArticulo), AUsuario);
        Result := BuscarSkuSimple(oConsulta, Trim(AArticulo));
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.Borrar(
  const ADocumento: TDocumentoMovimientosAlbaranVenta);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(' +
      ':TIPO, :SERIE, :NUMERO)';
    oConsulta.ParamByName('TIPO').AsString := ADocumento.TipoDocumento;
    oConsulta.ParamByName('SERIE').AsString := ADocumento.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ADocumento.Numero;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.
  CrearConsultaLineasMovimiento(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text :=
    'SELECT L.LINEA_ALBLIN, L.CODIGO_UNIDAD_ALBLIN, ' +
    '       L.CODIGO_ART_ALBLIN, L.CANTIDAD_ALBLIN, ' +
    '       L.CODIGO_ALMACEN_ALBLIN, L.LOTE_ALBLIN, ' +
    '       L.FECHA_CADUCIDAD_ALBLIN ' +
    '  FROM fza_albaranes_lineas L ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_ALBLIN ' +
    ' WHERE L.NUMERO_ALB_ALBLIN = :NUMERO ' +
    '   AND L.SERIE_ALB_ALBLIN = :SERIE ' +
    '   AND COALESCE(UPPER(TRIM(A.TIPO_ART)), ''ESTANDAR'') ' +
    '       <> ''SERVICIO'' ' +
    ' ORDER BY L.LINEA_ALBLIN';
  Result.ParamByName('NUMERO').AsString := ADocumento.Numero;
  Result.ParamByName('SERIE').AsString := ADocumento.Serie;
  Result.Open;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.CrearConsultaExistencia(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text :=
    'SELECT COUNT(*) AS N ' +
    '  FROM fza_movimientos_almacen ' +
    ' WHERE TIPO_DOC_MOV = :TIPO ' +
    '   AND SERIE_DOC_MOV = :SERIE ' +
    '   AND NUMERO_DOC_MOV = :NUMERO ' +
    '   AND LINEA_MOV = :LINEA';
  Result.ParamByName('TIPO').AsString := ADocumento.TipoDocumento;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.LeerLinea(
  AConsulta: TUniQuery;
  const AAlmacenCabecera: string): TLineaMovimientoAlbaranVenta;
begin
  Result := Default(TLineaMovimientoAlbaranVenta);
  Result.Linea := AConsulta.FieldByName('LINEA_ALBLIN').AsString;
  Result.Sku := Trim(
    AConsulta.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
  Result.Articulo :=
    AConsulta.FieldByName('CODIGO_ART_ALBLIN').AsString;
  Result.Cantidad := AConsulta.FieldByName('CANTIDAD_ALBLIN').AsFloat;
  Result.Almacen := Trim(
    AConsulta.FieldByName('CODIGO_ALMACEN_ALBLIN').AsString);
  if Result.Almacen = '' then
    Result.Almacen := AAlmacenCabecera;
  Result.Lote := AConsulta.FieldByName('LOTE_ALBLIN').AsString;
  if not AConsulta.FieldByName('FECHA_CADUCIDAD_ALBLIN').IsNull then
    Result.FechaCaducidad :=
      Trunc(AConsulta.FieldByName('FECHA_CADUCIDAD_ALBLIN').AsDateTime);
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.PuedeGenerar(
  const ALinea: TLineaMovimientoAlbaranVenta): Boolean;
begin
  Result := (Trim(ALinea.Linea) <> '') and
            (StrToIntDef(ALinea.Linea, 0) > 0) and
            (Trim(ALinea.Sku) <> '') and
            (Trim(ALinea.Almacen) <> '') and
            (ALinea.Cantidad <> 0);
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.ExisteMovimiento(
  AConsulta: TUniQuery;
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALinea: string): Boolean;
begin
  AConsulta.Close;
  AConsulta.ParamByName('SERIE').AsString := ADocumento.Serie;
  AConsulta.ParamByName('NUMERO').AsString := ADocumento.Numero;
  AConsulta.ParamByName('LINEA').AsString := ALinea;
  AConsulta.Open;
  Result := AConsulta.FieldByName('N').AsInteger <> 0;
  AConsulta.Close;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.
  DefinirParametrosMovimiento;
begin
  FProcedimientoMovimiento.Connection := FConexion;
  FProcedimientoMovimiento.StoredProcName :=
    'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
  FProcedimientoMovimiento.Params.Clear;
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_NUMERO_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_TIPO_DOC_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_SERIE_DOC_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_NRO_DOC_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_LINEA_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODIGO_EMPRESA_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODIGO_ALMACEN_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODIGO_ALMACEN_CONTRA_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODIGO_UNIDAD_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_TIPO_MOVIMIENTO_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftBCD, 'p_CANTIDAD_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftBCD, 'p_PRECIO_MEDIO_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftBCD, 'p_TOTAL_COSTE_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_USUARIO', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_ALMACEN_DOC', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_NUMOP_DOC', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODIGO_CAJA_DOC_MOV', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODCLIENTE', ptInput);
  FProcedimientoMovimiento.Params.CreateParam(
    ftString, 'p_CODARTICULO', ptInput);
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.
  AsignarParametrosMovimiento(
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALinea: TLineaMovimientoAlbaranVenta;
  const ANumeroMovimiento: string);
begin
  FProcedimientoMovimiento.ParamByName('p_NUMERO_MOV').AsString :=
    ANumeroMovimiento;
  FProcedimientoMovimiento.ParamByName('p_TIPO_DOC_MOV').AsString :=
    ADocumento.TipoDocumento;
  FProcedimientoMovimiento.ParamByName('p_SERIE_DOC_MOV').AsString :=
    ADocumento.Serie;
  FProcedimientoMovimiento.ParamByName('p_NRO_DOC_MOV').AsString :=
    ADocumento.Numero;
  FProcedimientoMovimiento.ParamByName('p_LINEA_MOV').AsString :=
    ALinea.Linea;
  FProcedimientoMovimiento.ParamByName('p_CODIGO_EMPRESA_MOV').AsString :=
    ADocumento.Empresa;
  FProcedimientoMovimiento.ParamByName('p_CODIGO_ALMACEN_MOV').AsString :=
    ALinea.Almacen;
  FProcedimientoMovimiento.ParamByName(
    'p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
  FProcedimientoMovimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString :=
    ALinea.Sku;
  // La línea negativa es una devolución del cliente: entra al PMP.
  FProcedimientoMovimiento.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString :=
    TipoMovimientoStockLinea(ADocumento.TipoMovimiento, ALinea.Cantidad);
  FProcedimientoMovimiento.ParamByName('p_CANTIDAD_MOV').AsFloat :=
    Abs(ALinea.Cantidad);
  FProcedimientoMovimiento.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat := 0;
  FProcedimientoMovimiento.ParamByName('p_TOTAL_COSTE_MOV').AsFloat := 0;
  FProcedimientoMovimiento.ParamByName('p_USUARIO').AsString :=
    ADocumento.Usuario;
  FProcedimientoMovimiento.ParamByName('p_ALMACEN_DOC').AsString :=
    ALinea.Almacen;
  FProcedimientoMovimiento.ParamByName('p_NUMOP_DOC').AsString := '';
  FProcedimientoMovimiento.ParamByName(
    'p_CODIGO_CAJA_DOC_MOV').AsString := '';
  FProcedimientoMovimiento.ParamByName('p_CODCLIENTE').AsString :=
    ADocumento.Cliente;
  FProcedimientoMovimiento.ParamByName('p_CODARTICULO').AsString :=
    ALinea.Articulo;
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.InsertarMovimiento(
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALinea: TLineaMovimientoAlbaranVenta);
var
  sNumeroMovimiento: string;
begin
  DefinirParametrosMovimiento;
  sNumeroMovimiento := ObtenerSiguienteContador(
    FConexion, 'MV', ADocumento.Usuario);
  AsignarParametrosMovimiento(
    ADocumento, ALinea, sNumeroMovimiento);
  // F-LOTEC-016: con lote o serie, ..._INSERT_LOTE.
  EjecutarMovimientoConLote(FProcedimientoMovimiento, FProcedimientoLote,
    ALinea.Lote, ALinea.FechaCaducidad);
end;

procedure TPersistenciaMovimientosAlbaranVentaUniDAC.
  AvisarLineaSinMovimiento(
  const ADocumento: TDocumentoMovimientosAlbaranVenta;
  const ALinea: TLineaMovimientoAlbaranVenta);
begin
  if ALinea.Cantidad <> 0 then
  begin
    FRegistroLog.RegistrarAviso(Format(
      'Albaran %s/%s linea %s sin movimiento AV. Articulo=%s, ' +
      'SKU=%s, almacen=%s.',
      [ADocumento.Serie, ADocumento.Numero, ALinea.Linea,
       ALinea.Articulo, ALinea.Sku, ALinea.Almacen]));
  end;
end;

function TPersistenciaMovimientosAlbaranVentaUniDAC.Generar(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
var
  Linea: TLineaMovimientoAlbaranVenta;
  oConsultaExistencia: TUniQuery;
  oConsultaLineas: TUniQuery;
begin
  Result := 0;
  oConsultaLineas := CrearConsultaLineasMovimiento(ADocumento);
  oConsultaExistencia := CrearConsultaExistencia(ADocumento);
  try
    while not oConsultaLineas.Eof do
    begin
      Linea := LeerLinea(oConsultaLineas, ADocumento.Almacen);
      if PuedeGenerar(Linea) then
      begin
        if not ExisteMovimiento(
            oConsultaExistencia, ADocumento, Linea.Linea) then
        begin
          InsertarMovimiento(ADocumento, Linea);
          Inc(Result);
        end;
      end
      else
        AvisarLineaSinMovimiento(ADocumento, Linea);
      oConsultaLineas.Next;
    end;
  finally
    FreeAndNil(oConsultaLineas);
    FreeAndNil(oConsultaExistencia);
  end;
  if Result > 0 then
  begin
    FecharYEncolarMovimientosDocumento(
      FConexion,
      ADocumento.TipoDocumento,
      ADocumento.Serie,
      ADocumento.Numero,
      ADocumento.InstanteMovimiento,
      'ALBARAN_VENTA',
      ADocumento.Usuario);
  end;
end;

constructor TUnidadTrabajoMovimientosAlbaranVentaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TUnidadTrabajoMovimientosAlbaranVentaUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaUniDAC.Confirmar;
begin
  FConexion.Commit;
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoMovimientosAlbaranVentaUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

function CrearPersistenciaMovimientosAlbaranVentaUniDAC(
  AConexion: TUniConnection;
  AProcedimientoMovimiento: TUniStoredProc;
  const ARegistroLog: IRegistroLog):
  IPersistenciaMovimientosAlbaranVenta;
begin
  Result := TPersistenciaMovimientosAlbaranVentaUniDAC.Create(
    AConexion, AProcedimientoMovimiento, ARegistroLog);
end;

function CrearUnidadTrabajoMovimientosAlbaranVentaUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoMovimientosAlbaranVenta;
begin
  Result := TUnidadTrabajoMovimientosAlbaranVentaUniDAC.Create(AConexion);
end;

end.

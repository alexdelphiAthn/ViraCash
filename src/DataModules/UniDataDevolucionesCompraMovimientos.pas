{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDevolucionesCompraMovimientos                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generacion y reversion de movimientos de almacen para devoluciones a      }
{    proveedor. Espejo de inLibAlbaranesCompraMovimientos pero generando       }
{    movimientos de SALIDA (TIPO_MOV='S') en vez de entrada: la cantidad       }
{    del documento va en positivo y el movimiento RESTA del stock, porque      }
{    la mercancia sale del almacen de vuelta al proveedor.                     }
{                                                                              }
{    Usa el procedimiento almacenado PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT,       }
{    que es el unico que toca stock real (fza_articulos_stockactual). El       }
{    signo lo pone el propio SP segun TIPO_MOV ('S' => resta CANTIDAD_STK      }
{    y VALOR_TOTAL_STK). El codigo de documento de los movimientos es 'DC'.    }
{    La reversion borra los movimientos por (TIPO_DOC='DC' + SERIE + NUMERO)   }
{    y recalcula PMP + stock de los SKUs afectados via                         }
{    SP_RECALCULAR_PMP_LOTE_ALMACEN.                                           }
{                                                                              }
{    Fuente de datos para los movimientos:                                     }
{      - fza_devoluciones_compra_celdas si la linea tiene celdas con           }
{        cantidad > 0 (caso edicion manual con tallas).                        }
{      - fza_devoluciones_compra_lineas en caso contrario, una salida por      }
{        linea con CANTIDAD_DEVCLIN.                                           }
{                                                                              }
{    Limitacion conocida: ambos caminos asumen que el SKU de la linea          }
{    (CODIGO_UNIDAD_DEVCLIN) es el correcto. No resolvemos un SKU              }
{    distinto por celda; cuando se permita en un hito futuro habra que         }
{    ampliar ResolverSkuCelda en el bucle de celdas.                           }
{******************************************************************************}
unit UniDataDevolucionesCompraMovimientos;
interface
uses
  Uni, inLibDevolucionesCompraMovimientosIntf;
function CrearMovimientosDevolucionCompraUniDAC(
  AConexion: TUniConnection): IMovimientosDevolucionCompra;
implementation
uses
  System.SysUtils, Data.DB, DBAccess, inLibDocumento,
  inLibDocumentoIntf, UniDataValoresAutomaticosRepositorio,
  inLibMsgCompras, UniDataMovimientosAlmacenRecalculo,
  UniDataDevolucionesCompraMovimientosSql,
  inLibPrestaShopColaSenal,
  inLibDevolucionesCompraMovimientos, UniDataMovimientosLote;
type
  TUnidadTrabajoMovimientosDevolucionCompraUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoMovimientosDevolucionCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

  TMovimientosDevolucionCompraUniDAC = class(
    TInterfacedObject,
    IMovimientosDevolucionCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure SincronizarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string;
      AGenerar: Boolean);
  end;
function EstrategiaDevolucionCompra: IEstrategiaDocumento;
begin
  Result := CrearEstrategiaDocumento(
    CrearConfiguracionDocumento(tdDevolucion, sdCompra));
end;
// Carga los datos minimos del devolucion necesarios para construir los
// movimientos: empresa (para el parametro p_CODIGO_EMPRESA_MOV) y
// almacen por defecto de la cabecera (fallback cuando linea/celda no
// llevan almacen propio).
procedure LeerCabeceraDevolucion(AConn: TUniConnection;
                              const ASerieDevc, ANumDevc: string;
                              out ACodigoEmp, ACodigoAlmCab: string;
                              out AInstanteMovimiento: TDateTime);
var
  q: TUniQuery;
begin
  ACodigoEmp    := '';
  ACodigoAlmCab := '';
  AInstanteMovimiento := Now;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT CODIGO_EMP_DEVC, CODIGO_ALM_DEVC, ' +
      '       COALESCE(INSTANTE_MOVIMIENTO_DEVC, ' +
      '                CAST(FECHA_DEVC AS datetime), NOW()) ' +
      '         AS INSTANTE_MOVIMIENTO ' +
      '  FROM fza_devoluciones_compra ' +
      ' WHERE SERIE_DEVC = :s AND NUMERO_DEVC = :n';
    q.ParamByName('s').AsString := ASerieDevc;
    q.ParamByName('n').AsString := ANumDevc;
    q.Open;
    if q.Eof then
      raise Exception.CreateFmt(
        SErrorDevolucionCompraMovimientosNoEncontrada,
        [ASerieDevc, ANumDevc]);
    ACodigoEmp    := q.FieldByName('CODIGO_EMP_DEVC').AsString;
    ACodigoAlmCab := q.FieldByName('CODIGO_ALM_DEVC').AsString;
    AInstanteMovimiento :=
      q.FieldByName('INSTANTE_MOVIMIENTO').AsDateTime;
  finally
    FreeAndNil(q);
  end;
end;
procedure PrepararInsercionMovimiento(AConn: TUniConnection;
                                      AProcedimiento: TUniStoredProc);
begin
  AProcedimiento.Connection := AConn;
  AProcedimiento.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMERO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_TIPO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NRO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_LINEA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString,
    'p_CODIGO_ALMACEN_CONTRA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_CANTIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_PRECIO_MEDIO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_TOTAL_COSTE_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_ALMACEN_DOC', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMOP_DOC', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODCLIENTE', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODARTICULO', ptInput);
end;
procedure GenerarMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                               const ASerieDevc, ANumDevc,
                                                     AUsuario: string);
var
  qSrc, qChk: TUniQuery;
  spIns: TUniStoredProc;
  spInsLote: TUniStoredProc;
  sCodigoEmp, sCodigoAlmCab, sCodigoAlm, sCodigoSku, sCodigoArt,
  sNumeroMov, sLinea: string;
  iCount: Integer;
  dtInstanteMovimiento: TDateTime;
  rCantidad, rPrecio, rTotal: Double;
begin
  LeerCabeceraDevolucion(AConn,
                         ASerieDevc,
                         ANumDevc,
                         sCodigoEmp,
                         sCodigoAlmCab,
                         dtInstanteMovimiento);
  // Sanidad: bloquear doble generacion. Si ya hay movs de la devolucion, no
  // generamos otra vez. La reversion debe llamarse explicita antes.
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConn;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = :t ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qChk.ParamByName('t').AsString :=
      EstrategiaDevolucionCompra.TipoDocumentoMovimientoStock;
    qChk.ParamByName('s').AsString := ASerieDevc;
    qChk.ParamByName('n').AsString := ANumDevc;
    qChk.Open;
    if qChk.FieldByName('N').AsInteger > 0 then
      raise Exception.CreateFmt(
        SErrorDevolucionCompraMovimientosYaGenerados,
        [ASerieDevc, ANumDevc]);
  finally
    FreeAndNil(qChk);
  end;
  qSrc := TUniQuery.Create(nil);
  spIns := TUniStoredProc.Create(nil);
  spInsLote := TUniStoredProc.Create(nil);
  try
    qSrc.Connection := AConn;
    // Union de dos selects:
    //   A) Lineas SIN celdas con cantidad > 0: una salida por linea.
    //   B) Celdas con cantidad > 0: una salida por celda.
    // Asi cubrimos el flujo de materializacion (que solo escribe
    // lineas) y el de edicion manual con tallas (que escribe celdas).
    qSrc.SQL.Text := SqlOrigenMovimientosDevolucionCompra;
    qSrc.ParamByName('s1').AsString      := ASerieDevc;
    qSrc.ParamByName('n1').AsString      := ANumDevc;
    qSrc.ParamByName('alm_cab1').AsString := sCodigoAlmCab;
    qSrc.ParamByName('s2').AsString      := ASerieDevc;
    qSrc.ParamByName('n2').AsString      := ANumDevc;
    qSrc.ParamByName('alm_cab2').AsString := sCodigoAlmCab;
    qSrc.Open;
    PrepararInsercionMovimiento(AConn, spIns);
    iCount := 0;
    while not qSrc.Eof do
    begin
      sCodigoSku := qSrc.FieldByName('SKU').AsString;
      sCodigoArt := qSrc.FieldByName('ARTICULO').AsString;
      sCodigoAlm := qSrc.FieldByName('ALMACEN').AsString;
      rCantidad  := qSrc.FieldByName('CANTIDAD').AsFloat;
      rPrecio    := qSrc.FieldByName('PRECIO').AsFloat;
      rTotal     := rCantidad * rPrecio;
      // Lineas sin SKU no pueden mover stock; las saltamos. No es
      // fatal porque pueden ser lineas de servicio o lineas en
      // construccion. Lo mismo para sin almacen efectivo.
      if (sCodigoSku <> '') and (sCodigoAlm <> '') then
      begin
        sNumeroMov := ObtenerSiguienteContador(
          AConn, 'MV', AUsuario);
      // LINEA_DEVCLIN ya viene en formato '0010', '0020', etc. Lo
      // reusamos tal cual como LINEA_MOV.
      sLinea := qSrc.FieldByName('LINEA').AsString;
      spIns.ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
      spIns.ParamByName('p_TIPO_DOC_MOV').AsString :=
        EstrategiaDevolucionCompra.TipoDocumentoMovimientoStock;
      spIns.ParamByName('p_SERIE_DOC_MOV').AsString       := ASerieDevc;
      spIns.ParamByName('p_NRO_DOC_MOV').AsString         := ANumDevc;
      spIns.ParamByName('p_LINEA_MOV').AsString           := sLinea;
      spIns.ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sCodigoEmp;
      spIns.ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sCodigoAlm;
      spIns.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
      spIns.ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sCodigoSku;
      spIns.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString :=
        EstrategiaDevolucionCompra.TipoMovimientoStock;
      spIns.ParamByName('p_CANTIDAD_MOV').AsFloat         := rCantidad;
      spIns.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := rPrecio;
      spIns.ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := rTotal;
      spIns.ParamByName('p_USUARIO').AsString             := AUsuario;
      spIns.ParamByName('p_ALMACEN_DOC').AsString         := sCodigoAlm;
      spIns.ParamByName('p_NUMOP_DOC').AsString           := '';
      spIns.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
      spIns.ParamByName('p_CODCLIENTE').AsString          := '';
      spIns.ParamByName('p_CODARTICULO').AsString         := sCodigoArt;
      // F-LOTEC-013: con lote o serie, ..._INSERT_LOTE.
      EjecutarMovimientoConLote(spIns, spInsLote,
        qSrc.FieldByName('LOTE').AsString,
        FechaCaducidadMovimiento(qSrc));
        Inc(iCount);
      end;
      qSrc.Next;
    end;
    if iCount = 0 then
      raise Exception.CreateFmt(
        SErrorDevolucionCompraSinCantidadParaMovimientos,
        [ASerieDevc, ANumDevc]);
    FecharYEncolarMovimientosDocumento(
      AConn,
      EstrategiaDevolucionCompra.TipoDocumentoMovimientoStock,
      ASerieDevc,
      ANumDevc,
      dtInstanteMovimiento,
      'DEVOLUCION_COMPRA',
      AUsuario);
  finally
    FreeAndNil(qSrc);
    FreeAndNil(spInsLote);
    FreeAndNil(spIns);
  end;
end;
procedure RevertirMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                                 const ASerieDevc, ANumDevc,
                                                       AUsuario: string);
var
  qExec: TUniQuery;
begin
  qExec  := TUniQuery.Create(nil);
  try
    qExec.Connection  := AConn;
    qExec.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qExec.ParamByName('t').AsString :=
      EstrategiaDevolucionCompra.TipoDocumentoMovimientoStock;
    qExec.ParamByName('s').AsString := ASerieDevc;
    qExec.ParamByName('n').AsString := ANumDevc;
    qExec.ExecSQL;
  finally
    FreeAndNil(qExec);
  end;
end;
constructor TMovimientosDevolucionCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;
procedure TMovimientosDevolucionCompraUniDAC.GenerarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  GenerarMovimientosDesdeDevolucionCompra(
    FConexion, ASerieDevc, ANumDevc, AUsuario);
end;
procedure TMovimientosDevolucionCompraUniDAC.RevertirDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  RevertirMovimientosDesdeDevolucionCompra(
    FConexion, ASerieDevc, ANumDevc, AUsuario);
end;
procedure TMovimientosDevolucionCompraUniDAC.SincronizarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string;
  AGenerar: Boolean);
begin
  RevertirMovimientosDesdeDevolucionCompra(
    FConexion, ASerieDevc, ANumDevc, AUsuario);
  if AGenerar then
    GenerarMovimientosDesdeDevolucionCompra(
      FConexion, ASerieDevc, ANumDevc, AUsuario);
end;
function CrearMovimientosDevolucionCompraUniDAC(
  AConexion: TUniConnection): IMovimientosDevolucionCompra;
begin
  Result := ProtegerMovimientosDevolucionCompra(
    TMovimientosDevolucionCompraUniDAC.Create(AConexion),
    TUnidadTrabajoMovimientosDevolucionCompraUniDAC.Create(AConexion));
end;

constructor TUnidadTrabajoMovimientosDevolucionCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TUnidadTrabajoMovimientosDevolucionCompraUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoMovimientosDevolucionCompraUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoMovimientosDevolucionCompraUniDAC.Confirmar;
begin
  FConexion.Commit;
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoMovimientosDevolucionCompraUniDAC.Revertir;
begin
  FConexion.Rollback;
end;
end.

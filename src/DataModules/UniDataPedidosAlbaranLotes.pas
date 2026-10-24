{******************************************************************************}
{  Módulo:       UniDataPedidosAlbaranLotes                                    }
{    Tipo:       Data Module (funciones)                                       }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Pedido de venta → albarán (FZ-ISSUE-336). Las líneas nuevas    }
{               de artículos con lote o serie toman el lote del almacén por    }
{               FEFO (una línea por lote o serie) y el albarán genera sus      }
{               movimientos de salida, como al convertir un presupuesto.      }
{               Antes salía sin lote y sin mover stock, con el pedido ya      }
{               ENTREGADO.                                                    }
{******************************************************************************}
unit UniDataPedidosAlbaranLotes;

interface

uses
  System.Classes, Uni;

// Última línea del albarán ('' si no tiene): lo que haya después es nuevo.
function UltimaLineaAlbaranPedido(AConexion: TUniConnection;
  const ASerie, ANumero: string): string;

// Reparte por lotes las líneas posteriores a ALineaDesde sin lote de
// artículos que lo requieren. Si no hay existencias identificadas
// suficientes o tocaría un lote caducado, lanza una excepción (el llamante
// deshace la creación).
procedure RepartirLotesAlbaranPedido(AConexion: TUniConnection;
  const ASerie, ANumero, ALineaDesde: string);

// Movimientos de salida de las líneas que aún no los tienen.
procedure GenerarMovimientosAlbaranPedido(AOwner: TComponent;
  AConexion: TUniConnection; const ASerie, ANumero: string);

implementation

uses
  System.SysUtils, Data.DB,
  inLibTrazabilidad, inLibLotesPersistenciaIntf, inLibPropuestaTraspasoLotes,
  inLibMsgVentas, UniDataLotesRepositorio, UniDataAlbaranes,
  inLibErroresBBDD;

type
  TLineaAlbaranLote = record
    Linea: string;
    Articulo: string;
    Sku: string;
    Almacen: string;
    Cantidad: Double;
  end;

function UltimaLineaAlbaranPedido(AConexion: TUniConnection;
  const ASerie, ANumero: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT COALESCE(MAX(LINEA_ALBLIN), '''') AS LINEA ' +
      '  FROM fza_albaranes_lineas ' +
      ' WHERE SERIE_ALB_ALBLIN = :SERIE AND NUMERO_ALB_ALBLIN = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('LINEA').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerLineasSinLote(AConexion: TUniConnection;
  const ASerie, ANumero, ALineaDesde: string): TArray<TLineaAlbaranLote>;
var
  oConsulta: TUniQuery;
  rLinea: TLineaAlbaranLote;
begin
  Result := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT L.LINEA_ALBLIN, L.CODIGO_ART_ALBLIN, L.CODIGO_UNIDAD_ALBLIN, ' +
      '       COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBLIN, ''''), ' +
      '                A.CODIGO_ALM_ALB) AS ALMACEN, L.CANTIDAD_ALBLIN ' +
      '  FROM fza_albaranes_lineas L ' +
      '  JOIN fza_albaranes A ' +
      '    ON A.SERIE_ALB = L.SERIE_ALB_ALBLIN ' +
      '   AND A.NUMERO_ALB = L.NUMERO_ALB_ALBLIN ' +
      ' WHERE L.SERIE_ALB_ALBLIN = :SERIE AND L.NUMERO_ALB_ALBLIN = :NUMERO ' +
      '   AND L.LINEA_ALBLIN > :DESDE ' +
      '   AND COALESCE(L.LOTE_ALBLIN, '''') = '''' ' +
      '   AND L.CANTIDAD_ALBLIN > 0 ' +
      ' ORDER BY L.LINEA_ALBLIN';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('DESDE').AsString := ALineaDesde;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rLinea.Linea := oConsulta.FieldByName('LINEA_ALBLIN').AsString;
      rLinea.Articulo := oConsulta.FieldByName('CODIGO_ART_ALBLIN').AsString;
      rLinea.Sku := oConsulta.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString;
      rLinea.Almacen := oConsulta.FieldByName('ALMACEN').AsString;
      rLinea.Cantidad := oConsulta.FieldByName('CANTIDAD_ALBLIN').AsFloat;
      Result := Result + [rLinea];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure AsignarParametrosLote(AConsulta: TUniQuery;
  const AAsignacion: TAsignacionLote);
begin
  AConsulta.ParamByName('CANTIDAD').AsFloat := AAsignacion.Cantidad;
  AConsulta.ParamByName('LOTE').AsString := AAsignacion.Lote;
  AConsulta.ParamByName('CADUCIDAD').DataType := ftDate;
  if AAsignacion.FechaCaducidad = SIN_FECHA then
    AConsulta.ParamByName('CADUCIDAD').Clear
  else
    AConsulta.ParamByName('CADUCIDAD').AsDate := AAsignacion.FechaCaducidad;
end;

// La línea creada desde el pedido se queda con la primera asignación.
procedure ActualizarLineaConLote(AConsulta: TUniQuery;
  const ASerie, ANumero, ALinea: string; const AAsignacion: TAsignacionLote);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_albaranes_lineas ' +
    '   SET CANTIDAD_ALBLIN = :CANTIDAD, LOTE_ALBLIN = :LOTE, ' +
    '       FECHA_CADUCIDAD_ALBLIN = :CADUCIDAD, ' +
    '       TOTAL_ALBLIN = :CANTIDAD * PRECIO_VENTA_SIVA_ARTICULO_ALBLIN ' +
    ' WHERE SERIE_ALB_ALBLIN = :SERIE AND NUMERO_ALB_ALBLIN = :NUMERO ' +
    '   AND LINEA_ALBLIN = :LINEA';
  AsignarParametrosLote(AConsulta, AAsignacion);
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.ParamByName('LINEA').AsString := ALinea;
  AConsulta.Execute;
end;

// Mismo contador que PRC_PED_CREAR_ALBARAN_LINEA.
function SiguienteLineaAlbaran(AConsulta: TUniQuery;
  const ASerie, ANumero: string): string;
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_albaranes ' +
    '   SET CONTADOR_LINEAS_ALB = LPAD(LAST_INSERT_ID(' +
    '         IFNULL(CAST(NULLIF(CONTADOR_LINEAS_ALB, '''') ' +
    '         AS UNSIGNED), 0) + 10), 8, ''0'') ' +
    ' WHERE SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO';
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  AConsulta.SQL.Text := 'SELECT LPAD(LAST_INSERT_ID(), 4, ''0'') AS LINEA';
  AConsulta.Open;
  Result := AConsulta.FieldByName('LINEA').AsString;
  AConsulta.Close;
end;

// Las demás asignaciones copian la línea entera (precio, IVA, pedido de
// origen...) con su cantidad, lote y caducidad.
procedure CopiarLineaConLote(AConsulta: TUniQuery;
  const ASerie, ANumero, ALinea: string; const AAsignacion: TAsignacionLote);
var
  sNueva: string;
begin
  sNueva := SiguienteLineaAlbaran(AConsulta, ASerie, ANumero);
  AConsulta.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_fza_alblin_lote';
  AConsulta.Execute;
  AConsulta.SQL.Text :=
    'CREATE TEMPORARY TABLE tmp_fza_alblin_lote AS ' +
    'SELECT * FROM fza_albaranes_lineas ' +
    ' WHERE SERIE_ALB_ALBLIN = :SERIE AND NUMERO_ALB_ALBLIN = :NUMERO ' +
    '   AND LINEA_ALBLIN = :LINEA';
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.ParamByName('LINEA').AsString := ALinea;
  AConsulta.Execute;
  AConsulta.SQL.Text :=
    'UPDATE tmp_fza_alblin_lote ' +
    '   SET LINEA_ALBLIN = :NUEVA, CANTIDAD_ALBLIN = :CANTIDAD, ' +
    '       LOTE_ALBLIN = :LOTE, FECHA_CADUCIDAD_ALBLIN = :CADUCIDAD, ' +
    '       TOTAL_ALBLIN = :CANTIDAD * PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
    '       INSTANTE_ALTA = NOW()';
  AConsulta.ParamByName('NUEVA').AsString := sNueva;
  AsignarParametrosLote(AConsulta, AAsignacion);
  AConsulta.Execute;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_albaranes_lineas SELECT * FROM tmp_fza_alblin_lote';
  AConsulta.Execute;
  AConsulta.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_fza_alblin_lote';
  AConsulta.Execute;
end;

procedure RepartirLotesAlbaranPedido(AConexion: TUniConnection;
  const ASerie, ANumero, ALineaDesde: string);
var
  oLectura: ILecturaTrazabilidadArticulo;
  oRepositorio: IRepositorioLotes;
  oConsulta: TUniQuery;
  oModo: TModoTrazabilidad;
  rLinea: TLineaAlbaranLote;
  rReparto: TRepartoLotesPropuesta;
  i: Integer;
begin
  if ActivacionVigente.AlgunModoActivo then
  begin
    oLectura := CrearLecturaTrazabilidadArticuloUniDAC(AConexion);
    oRepositorio := CrearRepositorioLotesUniDAC(AConexion);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      for rLinea in LeerLineasSinLote(AConexion, ASerie, ANumero,
                                      ALineaDesde) do
      begin
        oModo := ActivacionVigente.ModoEfectivo(
          oLectura.Leer(rLinea.Articulo).Modo);
        if RequiereLote(oModo) then
        begin
          rReparto := RepartirPropuestaPorLotes(oModo,
            oRepositorio.Disponibles(rLinea.Sku, rLinea.Almacen),
            rLinea.Cantidad, Date);
          // FZ-ISSUE-342: situaciones de negocio, no fallos: la pantalla
          // las muestra como aviso (EsValidacionAplicacionEsperada).
          if rReparto.LoteCaducado <> '' then
            raise EValidacionBBDD.CreateFmt(SErrorPedidoAlbaranLoteCaducado,
              [rLinea.Articulo, rLinea.Sku, rLinea.Almacen,
               rReparto.LoteCaducado]);
          if not rReparto.Correcto then
            raise EValidacionBBDD.CreateFmt(
              SErrorPedidoAlbaranLotesInsuficientes,
              [rLinea.Articulo, rLinea.Sku, rLinea.Almacen,
               FormatFloat('0.###', rReparto.CantidadPendiente)]);
          ActualizarLineaConLote(oConsulta, ASerie, ANumero, rLinea.Linea,
            rReparto.Asignaciones[0]);
          for i := 1 to High(rReparto.Asignaciones) do
            CopiarLineaConLote(oConsulta, ASerie, ANumero, rLinea.Linea,
              rReparto.Asignaciones[i]);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

// Como SincronizarAlbaran de la conversión de presupuestos: el albarán en
// la conexión de la transacción, para que vea sus propias líneas.
procedure GenerarMovimientosAlbaranPedido(AOwner: TComponent;
  AConexion: TUniConnection; const ASerie, ANumero: string);
var
  oAlbaran: TdmAlbaranes;
begin
  oAlbaran := TdmAlbaranes.Create(AOwner);
  try
    oAlbaran.ReasignarConexion(AConexion);
    oAlbaran.unqryTablaG.SQL.Text :=
      'SELECT NUMERO_ALB, SERIE_ALB, CODIGO_EMP_ALB, CODIGO_CLI_ALB, ' +
      'CODIGO_ALM_ALB, INSTANTE_MOVIMIENTO_ALB, FECHA_ALB ' +
      'FROM fza_albaranes WHERE SERIE_ALB = :SERIE ' +
      'AND NUMERO_ALB = :NUMERO';
    oAlbaran.unqryTablaG.ParamByName('SERIE').AsString := ASerie;
    oAlbaran.unqryTablaG.ParamByName('NUMERO').AsString := ANumero;
    oAlbaran.unqryTablaG.Open;
    oAlbaran.GenerarMovimientosSalida;
  finally
    FreeAndNil(oAlbaran);
  end;
end;

end.

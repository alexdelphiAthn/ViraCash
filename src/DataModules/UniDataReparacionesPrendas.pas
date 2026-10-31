{******************************************************************************}
{  Módulo: UniDataReparacionesPrendas                                          }
{  Descripción: Custodia de prendas vendidas hasta su entrega al cliente.      }
{******************************************************************************}
unit UniDataReparacionesPrendas;

interface

uses
  Uni, inLibReparaciones, inLibMovimientosAlmacenAplicacion;

type
  TDatosPrendasReparacion = class
  private
    FConexion: TUniConnection;
    FEscritor: IEscritorMovimientosAlmacen;
    function Consulta(const ASql: string): TUniQuery;
    function Disponible: Boolean;
    function AlmacenTaller(const AVenta: TVentaServiciosReparacion): string;
    function BloquearPrenda(const AVenta: TVentaServiciosReparacion;
      const APrenda: TPrendaVentaReparacion): TUniQuery;
    function CrearPrenda(ALinea: TUniQuery;
      const AVenta: TVentaServiciosReparacion;
      const APrenda: TPrendaVentaReparacion): Int64;
    procedure ValidarSelecciones(const ALineaServicio: string;
      const AVenta: TVentaServiciosReparacion);
    procedure Movimiento(AConsulta: TUniQuery; const ATipo, AUsuario: string;
      ACantidad: Double);
    procedure Vincular(AReparacion, APrenda: Int64; const AUsuario: string);
    function PrendaPorUnidades(const AVenta: TVentaServiciosReparacion;
      const ALinea: string): Boolean;
    function CantidadCustodia(const AUnidadMedida: string;
      ACantidadLinea: Double): Double;
  public
    constructor Create(AConexion: TUniConnection;
      const AEscritor: IEscritorMovimientosAlmacen = nil);
    procedure ComprobarPreparacion(const AEmpresa,AAlmacen: string);
    procedure Recibir(AReparacion: Int64; const ALineaServicio: string;
      const AVenta: TVentaServiciosReparacion);
    procedure Entregar(AReparacion: Int64; const AUsuario: string);
  end;

// FZ-ISSUE-786: True si la unidad de medida se cuenta por piezas
// (DECIMALES_UNIMED = 0); vacía o desconocida cuenta como Uds. Una línea
// en metros o kilos es una sola prenda, la línea entera.
function UnidadMedidaPorUnidades(AConexion: TUniConnection;
  const AUnidadMedida: string): Boolean;

implementation

uses
  System.SysUtils, Data.DB, System.Math, inLibMsgReparaciones,
  UniDataMovimientosAlmacenRepositorio, inLibTrabajosCortinas;

function UnidadMedidaPorUnidades(AConexion: TUniConnection;
  const AUnidadMedida: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := True;
  if Trim(AUnidadMedida) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT DECIMALES_UNIMED ' +
        'FROM fza_unidades_medida WHERE CODIGO_UNIMED=:UNIDAD';
      oConsulta.ParamByName('UNIDAD').AsString := AUnidadMedida;
      oConsulta.Open;
      Result := oConsulta.IsEmpty or (oConsulta.Fields[0].AsInteger = 0);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

constructor TDatosPrendasReparacion.Create(AConexion: TUniConnection;
  const AEscritor: IEscritorMovimientosAlmacen);
var
  oUnidad: IUnidadTrabajoMovimientosAlmacen;
begin
  inherited Create;
  FConexion := AConexion;
  FEscritor := AEscritor;
  if not Assigned(FEscritor) then
    CrearEscrituraMovimientosAlmacenUniDAC(FConexion, FEscritor, oUnidad);
end;

function TDatosPrendasReparacion.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TDatosPrendasReparacion.Disponible: Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA=DATABASE() ' +
    'AND TABLE_NAME=''fza_reparaciones_prendas_trabajos''');
  try
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPrendasReparacion.AlmacenTaller(
  const AVenta: TVentaServiciosReparacion): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT CODIGO_ALM_ALM FROM fza_almacenes ' +
    'WHERE TIPO_USO_ALM=''TALLER'' AND ESACTIVO_ALM=''S'' ' +
    'AND (CODIGO_EMP_ALM=:EMPRESA OR ESCOMPARTIDO_ALM=''S'') ' +
    'AND (CODIGO_PADRE_ALM=:TIENDA OR ESCOMPARTIDO_ALM=''S'') ' +
    'ORDER BY (CODIGO_PADRE_ALM=:TIENDA) DESC, ' +
    '(CODIGO_EMP_ALM=:EMPRESA) DESC,CODIGO_ALM_ALM LIMIT 1 FOR UPDATE');
  try
    oConsulta.ParamByName('EMPRESA').AsString := AVenta.Empresa;
    oConsulta.ParamByName('TIENDA').AsString := AVenta.Almacen;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SPrendaAlmacenFalta);
    Result := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPrendasReparacion.BloquearPrenda(
  const AVenta: TVentaServiciosReparacion;
  const APrenda: TPrendaVentaReparacion): TUniQuery;
begin
  Result := Consulta('SELECT ID_GARPRE, CODIGO_UNIDAD_SKU_GARPRE, ' +
    'CODIGO_ART_GARPRE, CODIGO_ALM_GARPRE, LOTE_GARPRE, ' +
    'FECHA_CADUCIDAD_GARPRE, ESENTREGADA_GARPRE, ' +
    'CODIGO_EMP_GARPRE AS EMPRESA ' +
    'FROM fza_reparaciones_prendas WHERE SERIE_FAC_GARPRE=:SERIE ' +
    'AND NUMERO_FAC_GARPRE=:NUMERO AND LINEA_FACLIN_GARPRE=:LINEA ' +
    'AND UNIDAD_GARPRE=:UNIDAD FOR UPDATE');
  try
    Result.ParamByName('SERIE').AsString := AVenta.Serie;
    Result.ParamByName('NUMERO').AsString := AVenta.Numero;
    Result.ParamByName('LINEA').AsString := APrenda.LineaPrenda;
    Result.ParamByName('UNIDAD').AsInteger := APrenda.UnidadPrenda;
    Result.Open;
    if not Result.IsEmpty and
       (Result.FieldByName('ESENTREGADA_GARPRE').AsString = 'S') then
      raise EArgumentException.Create(SPrendaEntregada);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

// La prenda en piezas entra y sale de una en una; la de metros o kilos,
// con la cantidad de su línea (FZ-ISSUE-786).
function TDatosPrendasReparacion.CantidadCustodia(
  const AUnidadMedida: string; ACantidadLinea: Double): Double;
begin
  Result := 1;
  if (ACantidadLinea > 0) and
     not UnidadMedidaPorUnidades(FConexion, AUnidadMedida) then
    Result := ACantidadLinea;
end;

// Sin lectura bloqueante: la línea ya la bloquea Recibir o es del ticket.
function TDatosPrendasReparacion.PrendaPorUnidades(
  const AVenta: TVentaServiciosReparacion; const ALinea: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT TIPO_CANTIDAD_ARTICULO_FACLIN ' +
    'FROM fza_facturas_lineas ' +
    'WHERE SERIE_FAC_FACLIN=:SERIE AND NUMERO_FAC_FACLIN=:NUMERO ' +
    'AND LINEA_FACLIN=:LINEA AND CODIGO_EMP_FACLIN=:EMPRESA');
  try
    oConsulta.ParamByName('SERIE').AsString := AVenta.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AVenta.Numero;
    oConsulta.ParamByName('LINEA').AsString := ALinea;
    oConsulta.ParamByName('EMPRESA').AsString := AVenta.Empresa;
    oConsulta.Open;
    Result := oConsulta.IsEmpty or
      UnidadMedidaPorUnidades(FConexion, oConsulta.Fields[0].AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosPrendasReparacion.Movimiento(AConsulta: TUniQuery;
  const ATipo, AUsuario: string; ACantidad: Double);
var
  Movimiento: TMovimientoAlmacenEscritura;
begin
  Movimiento := Default(TMovimientoAlmacenEscritura);
  Movimiento.Empresa := AConsulta.FieldByName('EMPRESA').AsString;
  Movimiento.TipoDocumento := 'RT';
  Movimiento.SerieDocumento := 'TALLER';
  Movimiento.NumeroDocumento := AConsulta.FieldByName('ID_GARPRE').AsString;
  Movimiento.Linea := ATipo;
  Movimiento.Unidad :=
    AConsulta.FieldByName('CODIGO_UNIDAD_SKU_GARPRE').AsString;
  Movimiento.Articulo := AConsulta.FieldByName('CODIGO_ART_GARPRE').AsString;
  Movimiento.Almacen := AConsulta.FieldByName('CODIGO_ALM_GARPRE').AsString;
  Movimiento.Lote := AConsulta.FieldByName('LOTE_GARPRE').AsString;
  Movimiento.FechaCaducidad :=
    AConsulta.FieldByName('FECHA_CADUCIDAD_GARPRE').AsDateTime;
  Movimiento.TipoMovimiento := ATipo;
  Movimiento.Cantidad := ACantidad;
  Movimiento.Usuario := AUsuario;
  Movimiento.Fecha := Now;
  // Ya vendida: entra en custodia a coste cero, sin otra salida de tienda.
  FEscritor.Guardar(Movimiento);
end;

function TDatosPrendasReparacion.CrearPrenda(ALinea: TUniQuery;
  const AVenta: TVentaServiciosReparacion;
  const APrenda: TPrendaVentaReparacion): Int64;
var
  oConsulta: TUniQuery;
  sAlmacen: string;
begin
  sAlmacen := AlmacenTaller(AVenta);
  oConsulta := Consulta('INSERT INTO fza_reparaciones_prendas ' +
    '(SERIE_FAC_GARPRE,NUMERO_FAC_GARPRE,LINEA_FACLIN_GARPRE, ' +
    'UNIDAD_GARPRE,CODIGO_UNIDAD_SKU_GARPRE,CODIGO_ART_GARPRE, ' +
    'DESCRIPCION_GARPRE,LOTE_GARPRE,FECHA_CADUCIDAD_GARPRE, ' +
    'CODIGO_EMP_GARPRE, ' +
    'CODIGO_ALM_GARPRE,INSTANTE_ALTA,USUARIO_ALTA) ' +
    'VALUES (:SERIE,:NUMERO,:LINEA,:UNIDAD,:SKU,:ARTICULO,:DESCRIPCION, ' +
    'NULLIF(:LOTE,''''),:CADUCIDAD,:EMPRESA,:ALMACEN,NOW(6),:USUARIO)');
  try
    oConsulta.ParamByName('SERIE').AsString := AVenta.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AVenta.Numero;
    oConsulta.ParamByName('LINEA').AsString := APrenda.LineaPrenda;
    oConsulta.ParamByName('UNIDAD').AsInteger := APrenda.UnidadPrenda;
    oConsulta.ParamByName('SKU').AsString :=
      ALinea.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ALinea.FieldByName('CODIGO_ART_FACLIN').AsString;
    oConsulta.ParamByName('DESCRIPCION').AsString :=
      Copy(ALinea.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString,1,250);
    oConsulta.ParamByName('LOTE').AsString :=
      ALinea.FieldByName('LOTE_FACLIN').AsString;
    oConsulta.ParamByName('CADUCIDAD').Value :=
      ALinea.FieldByName('FECHA_CADUCIDAD_FACLIN').Value;
    oConsulta.ParamByName('EMPRESA').AsString := AVenta.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := sAlmacen;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AVenta.Usuario,1,50);
    oConsulta.ExecSQL;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID()';
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosPrendasReparacion.Vincular(AReparacion, APrenda: Int64;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_prendas_trabajos ' +
    '(ID_GAR_GARPT,ID_GARPRE_GARPT,INSTANTE_ALTA,USUARIO_ALTA) ' +
    'VALUES (:ID,:PRENDA,NOW(6),:USUARIO) ON DUPLICATE KEY UPDATE ' +
    'ID_GAR_GARPT=VALUES(ID_GAR_GARPT)');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.ParamByName('PRENDA').AsLargeInt := APrenda;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario,1,50);
    oConsulta.Execute;
    oConsulta.SQL.Text := 'UPDATE fza_garantias_reclamaciones G ' +
      'SET G.DESCRIPCION_OBJETO_GAR=LEFT((SELECT GROUP_CONCAT(DISTINCT ' +
      'CONCAT(P.DESCRIPCION_GARPRE,'' ['',P.CODIGO_UNIDAD_SKU_GARPRE, ' +
      '''] unidad '',P.UNIDAD_GARPRE) ORDER BY P.ID_GARPRE SEPARATOR ''; '') '+
      'FROM fza_reparaciones_prendas P JOIN ' +
      'fza_reparaciones_prendas_trabajos T ON T.ID_GARPRE_GARPT=P.ID_GARPRE '+
      'WHERE T.ID_GAR_GARPT=G.ID_GAR),200),G.REFERENCIA_OBJETO_GAR=NULL ' +
      'WHERE G.ID_GAR=:ID';
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosPrendasReparacion.ComprobarPreparacion(
  const AEmpresa,AAlmacen: string);
var
  Venta: TVentaServiciosReparacion;
begin
  if not Disponible then
    raise EArgumentException.Create(SPrendaEsquemaFalta);
  Venta := Default(TVentaServiciosReparacion);
  Venta.Empresa := AEmpresa;
  Venta.Almacen := AAlmacen;
  AlmacenTaller(Venta);
end;

procedure TDatosPrendasReparacion.ValidarSelecciones(
  const ALineaServicio: string; const AVenta: TVentaServiciosReparacion);
var
  i,j: Integer;
  oServicio: TUniQuery;
begin
  oServicio := Consulta('SELECT CANTIDAD_FACLIN FROM fza_facturas_lineas ' +
    'WHERE SERIE_FAC_FACLIN=:SERIE AND NUMERO_FAC_FACLIN=:NUMERO ' +
    'AND LINEA_FACLIN=:LINEA AND CODIGO_EMP_FACLIN=:EMPRESA FOR UPDATE');
  try
    oServicio.ParamByName('SERIE').AsString := AVenta.Serie;
    oServicio.ParamByName('NUMERO').AsString := AVenta.Numero;
    oServicio.ParamByName('LINEA').AsString := ALineaServicio;
    oServicio.ParamByName('EMPRESA').AsString := AVenta.Empresa;
    oServicio.Open;
    for i := 0 to High(AVenta.Prendas) do
      if AVenta.Prendas[i].LineaServicio=ALineaServicio then
      begin
        if oServicio.IsEmpty or (AVenta.Prendas[i].UnidadServicio<1) or
           (AVenta.Prendas[i].UnidadServicio>Ceil(oServicio.Fields[0].
             AsFloat)) then
          raise EArgumentException.Create(SPrendaVentaInvalida);
        // FZ-ISSUE-786: varias unidades del servicio pueden ir a la misma
        // prenda en metros o kilos, que es una sola (la línea entera).
        for j := 0 to i-1 do
          if (AVenta.Prendas[j].LineaServicio=ALineaServicio) and
             ((AVenta.Prendas[j].UnidadServicio=
               AVenta.Prendas[i].UnidadServicio) or
              ((AVenta.Prendas[j].LineaPrenda=AVenta.Prendas[i].LineaPrenda)
               and (AVenta.Prendas[j].UnidadPrenda=
                 AVenta.Prendas[i].UnidadPrenda)
               and PrendaPorUnidades(AVenta,
                 AVenta.Prendas[i].LineaPrenda))) then
            raise EArgumentException.Create(SPrendaVentaInvalida);
      end;
  finally
    FreeAndNil(oServicio);
  end;
end;

procedure TDatosPrendasReparacion.Recibir(AReparacion: Int64;
  const ALineaServicio: string; const AVenta: TVentaServiciosReparacion);
var
  Prenda: TPrendaVentaReparacion;
  oPrenda, oLinea: TUniQuery;
  iId: Int64;
  iMaximo: Integer;
  dCantidad: Double;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  if Length(AVenta.Prendas)>0 then
  begin
    if not Disponible then
      raise EArgumentException.Create(SPrendaEsquemaFalta);
    ValidarSelecciones(ALineaServicio,AVenta);
  end;
  for Prenda in AVenta.Prendas do
    if (Prenda.LineaServicio=ALineaServicio) and (Prenda.LineaPrenda<>'') and
       (Prenda.Trabajo.Clase<>CLASE_SERVICIO_INSTALACION) then
    begin
      oLinea := Consulta('SELECT CODIGO_UNIDAD_FACLIN,CODIGO_ART_FACLIN, ' +
        'DESCRIPCION_ARTICULO_FACLIN,CANTIDAD_FACLIN,LOTE_FACLIN, ' +
        'FECHA_CADUCIDAD_FACLIN,TIPO_CANTIDAD_ARTICULO_FACLIN ' +
        'FROM fza_facturas_lineas ' +
        'WHERE SERIE_FAC_FACLIN=:SERIE AND NUMERO_FAC_FACLIN=:NUMERO ' +
        'AND LINEA_FACLIN=:LINEA AND CODIGO_EMP_FACLIN=:EMPRESA ' +
        'AND TIPO_ARTICULO_FACLIN=''ESTANDAR'' FOR UPDATE');
      oPrenda := nil;
      try
        oLinea.ParamByName('SERIE').AsString := AVenta.Serie;
        oLinea.ParamByName('NUMERO').AsString := AVenta.Numero;
        oLinea.ParamByName('LINEA').AsString := Prenda.LineaPrenda;
        oLinea.ParamByName('EMPRESA').AsString := AVenta.Empresa;
        oLinea.Open;
        // FZ-ISSUE-786: en piezas, una prenda por unidad entera de la
        // línea; en metros o kilos, una sola (la unidad 1) con toda la
        // cantidad de la línea.
        iMaximo := 0;
        dCantidad := 1;
        if not oLinea.IsEmpty then
        begin
          dCantidad := CantidadCustodia(oLinea.FieldByName(
            'TIPO_CANTIDAD_ARTICULO_FACLIN').AsString,
            oLinea.FieldByName('CANTIDAD_FACLIN').AsFloat);
          // Una línea de 1 m cae aquí y da el mismo máximo (1).
          if dCantidad = 1 then
            iMaximo := Floor(oLinea.FieldByName('CANTIDAD_FACLIN').AsFloat)
          else
            iMaximo := 1;
        end;
        if oLinea.IsEmpty or (Prenda.UnidadPrenda<1) or
           (Prenda.UnidadPrenda>iMaximo) then
          raise EArgumentException.Create(SPrendaVentaInvalida);
        oPrenda := BloquearPrenda(AVenta,Prenda);
        if oPrenda.IsEmpty then
        begin
          FreeAndNil(oPrenda);
          iId := CrearPrenda(oLinea,AVenta,Prenda);
          oPrenda := BloquearPrenda(AVenta,Prenda);
          Movimiento(oPrenda,'E',AVenta.Usuario,dCantidad);
        end
        else
          iId := oPrenda.FieldByName('ID_GARPRE').AsLargeInt;
        Vincular(AReparacion,iId,AVenta.Usuario);
      finally
        FreeAndNil(oPrenda);
        FreeAndNil(oLinea);
      end;
    end;
end;

procedure TDatosPrendasReparacion.Entregar(AReparacion: Int64;
  const AUsuario: string);
var
  oPrendas, oPendientes, oCambio: TUniQuery;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  if Disponible then
  begin
    oPrendas := Consulta('SELECT P.ID_GARPRE,P.CODIGO_UNIDAD_SKU_GARPRE, ' +
      'P.CODIGO_ART_GARPRE,P.CODIGO_ALM_GARPRE,P.LOTE_GARPRE, ' +
      'P.FECHA_CADUCIDAD_GARPRE,P.CODIGO_EMP_GARPRE AS EMPRESA, ' +
      // FZ-ISSUE-786: sale lo mismo que entró (CantidadCustodia). Las
      // subconsultas no bloquean las líneas del ticket.
      '(SELECT L.CANTIDAD_FACLIN FROM fza_facturas_lineas L ' +
      ' WHERE L.SERIE_FAC_FACLIN=P.SERIE_FAC_GARPRE ' +
      ' AND L.NUMERO_FAC_FACLIN=P.NUMERO_FAC_GARPRE ' +
      ' AND L.LINEA_FACLIN=P.LINEA_FACLIN_GARPRE ' +
      ' AND L.CODIGO_EMP_FACLIN=P.CODIGO_EMP_GARPRE) AS CANTIDAD_LINEA, ' +
      '(SELECT L.TIPO_CANTIDAD_ARTICULO_FACLIN FROM fza_facturas_lineas L ' +
      ' WHERE L.SERIE_FAC_FACLIN=P.SERIE_FAC_GARPRE ' +
      ' AND L.NUMERO_FAC_FACLIN=P.NUMERO_FAC_GARPRE ' +
      ' AND L.LINEA_FACLIN=P.LINEA_FACLIN_GARPRE ' +
      ' AND L.CODIGO_EMP_FACLIN=P.CODIGO_EMP_GARPRE) AS UNIDAD_MEDIDA ' +
      'FROM fza_reparaciones_prendas P ' +
      'JOIN fza_reparaciones_prendas_trabajos T ' +
      'ON T.ID_GARPRE_GARPT=P.ID_GARPRE WHERE T.ID_GAR_GARPT=:ID ' +
      'AND P.ESENTREGADA_GARPRE=''N'' ORDER BY P.ID_GARPRE FOR UPDATE');
    oPendientes := Consulta('SELECT G.ID_GAR FROM ' +
      'fza_reparaciones_prendas_trabajos T ' +
      'JOIN fza_garantias_reclamaciones G ON G.ID_GAR=T.ID_GAR_GARPT ' +
      'WHERE T.ID_GARPRE_GARPT=:PRENDA ' +
      'AND G.FECHA_ENTREGA_CLI_GAR IS NULL FOR UPDATE');
    oCambio := Consulta('UPDATE fza_reparaciones_prendas SET ' +
      'ESENTREGADA_GARPRE=''S'',INSTANTE_MODIF=NOW(6),USUARIO_MODIF=:USUARIO '+
      'WHERE ID_GARPRE=:ID AND ESENTREGADA_GARPRE=''N''');
    try
      oPrendas.ParamByName('ID').AsLargeInt := AReparacion;
      oPrendas.Open;
      while not oPrendas.Eof do
      begin
        oPendientes.Close;
        oPendientes.ParamByName('PRENDA').AsLargeInt :=
          oPrendas.FieldByName('ID_GARPRE').AsLargeInt;
        oPendientes.Open;
        if oPendientes.IsEmpty then
        begin
          Movimiento(oPrendas,'S',AUsuario,CantidadCustodia(
            oPrendas.FieldByName('UNIDAD_MEDIDA').AsString,
            oPrendas.FieldByName('CANTIDAD_LINEA').AsFloat));
          oCambio.ParamByName('ID').AsLargeInt :=
            oPrendas.FieldByName('ID_GARPRE').AsLargeInt;
          oCambio.ParamByName('USUARIO').AsString := Copy(AUsuario,1,50);
          oCambio.Execute;
        end;
        oPrendas.Next;
      end;
    finally
      FreeAndNil(oCambio);
      FreeAndNil(oPendientes);
      FreeAndNil(oPrendas);
    end;
  end;
end;

end.

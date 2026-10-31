{******************************************************************************}
{  Módulo: UniDataReparacionesVentaTpv                                         }
{  Descripción: Órdenes de reparación vinculadas a líneas de venta del TPV.    }
{******************************************************************************}
unit UniDataReparacionesVentaTpv;

interface

uses
  Uni, inLibReparaciones, UniDataReparacionesRepositorio;

type
  TReparacionesVentaTpv = class
  private
    FConexion: TUniConnection;
    FRepositorio: TRepositorioReparacionesUniDAC;
    FTipos: TArray<TTipoServicio>;
    function Consulta(const ASql: string;
      const AVenta: TVentaServiciosReparacion): TUniQuery;
    function PrepararOrden(ALinea: TUniQuery;
      const AVenta: TVentaServiciosReparacion): TReparacionNueva;
    procedure CompletarEjecutor(var AOrden: TReparacionNueva;
      const AArticulo: string);
    procedure VincularOrden(AId: Int64; ALinea: TUniQuery;
      const AVenta: TVentaServiciosReparacion);
    procedure CrearOrden(ALinea: TUniQuery;
      const AVenta: TVentaServiciosReparacion);
    procedure BloquearTicket(const AVenta: TVentaServiciosReparacion);
    function TieneMarca: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    // Participa en la transacción del ticket: no confirma por su cuenta.
    procedure CrearOrdenes(const AVenta: TVentaServiciosReparacion);
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgReparaciones;

constructor TReparacionesVentaTpv.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FRepositorio := TRepositorioReparacionesUniDAC.Create(AConexion);
end;

destructor TReparacionesVentaTpv.Destroy;
begin
  FreeAndNil(FRepositorio);
  inherited;
end;

function TReparacionesVentaTpv.Consulta(const ASql: string;
  const AVenta: TVentaServiciosReparacion): TUniQuery;
  procedure Texto(const ANombre, AValor: string);
  begin
    if Assigned(Result.Params.FindParam(ANombre)) then
      Result.ParamByName(ANombre).AsString := AValor;
  end;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
  Texto('SERIE', AVenta.Serie);
  Texto('NUMERO', AVenta.Numero);
  Texto('EMPRESA', AVenta.Empresa);
  Texto('USUARIO', Copy(AVenta.Usuario, 1, 50));
end;

function TReparacionesVentaTpv.TieneMarca: Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ''fza_articulos'' ' +
    'AND COLUMN_NAME = ''ESSERVICIO_REPARACION_ART''',
    Default(TVentaServiciosReparacion));
  try
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TReparacionesVentaTpv.BloquearTicket(
  const AVenta: TVentaServiciosReparacion);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT NUMERO_FAC FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO ' +
    'AND CODIGO_EMP_FAC = :EMPRESA FOR UPDATE', AVenta);
  try
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EInvalidOpException.Create(SErrorTicketOrdenReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TReparacionesVentaTpv.PrepararOrden(ALinea: TUniQuery;
  const AVenta: TVentaServiciosReparacion): TReparacionNueva;
var
  Tipo: TTipoServicio;
  sArticulo: string;
begin
  Result := Default(TReparacionNueva);
  Result.Fecha := AVenta.Fecha;
  sArticulo := ALinea.FieldByName('CODIGO_ART_FACLIN').AsString;
  for Tipo in FTipos do
    if (Tipo.Articulo = sArticulo) and
       ((Result.Tipo = '') or (Tipo.Codigo = sArticulo)) then
      Result := AplicarTipoServicio(Result, Tipo);
  Result.Almacen := AVenta.Almacen;
  Result.Usuario := AVenta.Usuario;
  Result.Modalidad := MODALIDAD_REPARACION_PAGO;
  Result.Origen := ORIGEN_REPARACION_CLIENTE;
  Result.Cliente := AVenta.Cliente;
  Result.NombreCliente := AVenta.NombreCliente;
  if Trim(Result.NombreCliente) = '' then
    Result.NombreCliente := SClienteMostradorReparacion;
  Result.TelefonoCliente := AVenta.Telefono;
  Result.Trabajo := ALinea.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
  if Trim(Result.Trabajo) = '' then
    Result.Trabajo := sArticulo;
  Result.DescripcionObjeto := Result.Trabajo;
  Result.ReferenciaObjeto := sArticulo;
  Result.SerieVenta := AVenta.Serie;
  Result.NumeroVenta := AVenta.Numero;
  Result.EsPresupuesto := False;
  Result.ModoCobro := COBRO_REPARACION_COMPRA;
  Result.EsCobrado := AVenta.Cobrada;
  if AVenta.Cobrada then
  begin
    Result.SerieCobro := AVenta.Serie;
    Result.NumeroCobro := AVenta.Numero;
  end;
  Result.Cantidad := ALinea.FieldByName('CANTIDAD_FACLIN').AsFloat;
  Result.PrecioCliente := ALinea.FieldByName('TOTAL_FACLIN').AsCurrency /
    Result.Cantidad;
  Result.PrecioCoste :=
    ALinea.FieldByName('PRECIO_ULT_COMPRA_FACLIN').AsCurrency;
  CompletarEjecutor(Result, sArticulo);
end;

procedure TReparacionesVentaTpv.CompletarEjecutor(
  var AOrden: TReparacionNueva; const AArticulo: string);
var
  oConsulta: TUniQuery;
begin
  if AOrden.TipoEjecutor = '' then
  begin
    oConsulta := Consulta('SELECT P.CODIGO_PRV_AP ' +
      'FROM fza_articulos_proveedores P JOIN fza_proveedores V ' +
      'ON V.CODIGO_PRV_PRV = P.CODIGO_PRV_AP ' +
      'WHERE P.CODIGO_ART_AP = :ARTICULO ' +
      'AND P.ESPROVEEDORPRINCIPAL_AP = ''S'' AND V.ESACTIVO_PRV = ''S'' ' +
      'ORDER BY P.CODIGO_PRV_AP LIMIT 1', Default(TVentaServiciosReparacion));
    try
      oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        AOrden.TipoEjecutor := EJECUTOR_REPARACION_EXTERNO;
        AOrden.Proveedor := oConsulta.Fields[0].AsString;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TReparacionesVentaTpv.VincularOrden(AId: Int64;
  ALinea: TUniQuery; const AVenta: TVentaServiciosReparacion);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_ventas ' +
    '(SERIE_FAC_GARVEN, NUMERO_FAC_GARVEN, LINEA_FACLIN_GARVEN, ' +
    'ID_GAR_GARVEN, CODIGO_ART_GARVEN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (:SERIE, :NUMERO, :LINEA, :ID, :ARTICULO, NOW(6), :USUARIO)',
    AVenta);
  try
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ParamByName('LINEA').AsString :=
      ALinea.FieldByName('LINEA_FACLIN').AsString;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ALinea.FieldByName('CODIGO_ART_FACLIN').AsString;
    oConsulta.ExecSQL;
    oConsulta.SQL.Text := 'UPDATE fza_garantias_reclamaciones ' +
      'SET EMAIL_CLIENTE_GAR = NULLIF(:EMAIL, ''''), ' +
      'FECHA_RECEPCION_GAR = NULL WHERE ID_GAR = :ID';
    oConsulta.ParamByName('EMAIL').AsString := Copy(AVenta.Email, 1, 200);
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TReparacionesVentaTpv.CrearOrden(ALinea: TUniQuery;
  const AVenta: TVentaServiciosReparacion);
var
  Orden: TReparacionNueva;
  Linea: TLineaReparacion;
  iId: Int64;
begin
  Orden := PrepararOrden(ALinea, AVenta);
  iId := FRepositorio.Alta(Orden);
  if (Orden.TipoEjecutor = '') and (Orden.PrecioCliente = 0) and
     (Orden.PrecioCoste = 0) then
  begin
    Linea := Default(TLineaReparacion);
    Linea.Reparacion := iId;
    Linea.TipoLinea := LINEA_REPARACION_MANO_OBRA;
    Linea.Tipo := Orden.Tipo;
    Linea.Descripcion := Orden.Trabajo;
    Linea.Cantidad := Orden.Cantidad;
    Linea.Usuario := Orden.Usuario;
    FRepositorio.GuardarLinea(Linea);
  end;
  VincularOrden(iId, ALinea, AVenta);
end;

procedure TReparacionesVentaTpv.CrearOrdenes(
  const AVenta: TVentaServiciosReparacion);
var
  oConsulta: TUniQuery;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  if TieneMarca then
  begin
    BloquearTicket(AVenta);
    FTipos := FRepositorio.Tipos('');
    oConsulta := Consulta('SELECT L.LINEA_FACLIN, L.CODIGO_ART_FACLIN, ' +
      'L.DESCRIPCION_ARTICULO_FACLIN, L.CANTIDAD_FACLIN, ' +
      'L.TOTAL_FACLIN, L.PRECIO_ULT_COMPRA_FACLIN ' +
      'FROM fza_facturas_lineas L JOIN fza_articulos A ' +
      'ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
      'LEFT JOIN fza_reparaciones_ventas V ' +
      'ON V.SERIE_FAC_GARVEN = L.SERIE_FAC_FACLIN ' +
      'AND V.NUMERO_FAC_GARVEN = L.NUMERO_FAC_FACLIN ' +
      'AND V.LINEA_FACLIN_GARVEN = L.LINEA_FACLIN ' +
      'WHERE L.SERIE_FAC_FACLIN = :SERIE ' +
      'AND L.NUMERO_FAC_FACLIN = :NUMERO ' +
      'AND L.CODIGO_EMP_FACLIN = :EMPRESA ' +
      'AND L.CANTIDAD_FACLIN > 0 AND L.TOTAL_FACLIN >= 0 ' +
      'AND A.ESSERVICIO_REPARACION_ART = ''S'' ' +
      'AND A.TIPO_ART = ''SERVICIO'' AND V.ID_GAR_GARVEN IS NULL ' +
      'ORDER BY L.LINEA_FACLIN', AVenta);
    try
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        CrearOrden(oConsulta, AVenta);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.


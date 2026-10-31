{******************************************************************************}
{  Módulo: UniDataReparacionesVentaTpv                                         }
{  Descripción: Órdenes de reparación vinculadas a líneas de venta del TPV.    }
{******************************************************************************}
unit UniDataReparacionesVentaTpv;

interface

uses
  Uni, Data.DB, inLibReparaciones, UniDataReparacionesRepositorio,
  inLibGarantiasResguardo;

type
  TReparacionesVentaTpv = class
  private
    FConexion: TUniConnection;
    FRepositorio: TRepositorioReparacionesUniDAC;
    FTipos: TArray<TTipoServicio>;
    // -1 sin consultar; 0/1 si existe ID_DEP_GARVEN (script 861).
    FEnlaceDeposito: Integer;
    function Consulta(const ASql: string;
      const AVenta: TVentaServiciosReparacion): TUniQuery;
    function LeerLinea(AConsulta: TUniQuery): TLineaServicioVenta;
    function PrepararOrden(const ALinea: TLineaServicioVenta;
      const AVenta: TVentaServiciosReparacion): TReparacionNueva;
    procedure CompletarEjecutor(var AOrden: TReparacionNueva;
      const AArticulo: string);
    procedure VincularOrden(AId: Int64; const ALinea: TLineaServicioVenta;
      const AVenta: TVentaServiciosReparacion);
    procedure CrearOrden(const ALinea: TLineaServicioVenta;
      const AVenta: TVentaServiciosReparacion);
    procedure BloquearTicket(const AVenta: TVentaServiciosReparacion);
    function TieneMarca: Boolean;
    function EsServicioReparacion(const AArticulo: string): Boolean;
    function OrdenesDeposito(const AIdDeposito: string): TArray<Int64>;
    function LeerResguardo(AConsulta: TUniQuery): TResguardoGarantia;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    // Participa en la transacción del ticket: no confirma por su cuenta.
    procedure CrearOrdenes(const AVenta: TVentaServiciosReparacion);
    function ClaseArticuloServicio(const AArticulo: string): string;
    function CodigosServicio: TArray<string>;
    function HayServicios(ALineas: TDataSet): Boolean;
    // FZ-ISSUE-787: completa nombre, teléfono y correo vacíos con la
    // ficha del cliente (venta de contado, '0' o '', no cambia nada).
    procedure CompletarContactoCliente(const ACliente: string;
      var ANombre, ATelefono, AEmail: string);
    // FZ-ISSUE-778: la orden de un servicio en préstamo se crea con el
    // anticipo, enlazada al depósito; al cobrar el resto se reutiliza.
    function TieneEnlaceDeposito: Boolean;
    function DepositoConOrden(const AIdDeposito: string): Boolean;
    // Participan en la transacción del ticket, como CrearOrdenes.
    procedure CrearOrdenesDepositos(const AVenta: TVentaServiciosReparacion;
      const ALineas: TLineasServicioVenta);
    // Antes de CrearOrdenes: enlaza al ticket las órdenes de los depósitos
    // que se cierran, que así no se crean de nuevo.
    procedure EnlazarOrdenesDepositos(
      const AVenta: TVentaServiciosReparacion;
      const ALineas: TLineasServicioVenta);
    function Resguardos(const AVenta: TVentaServiciosReparacion):
      TArray<TResguardoGarantia>;
  end;

implementation

uses
  System.SysUtils, inLibMsgReparaciones, UniDataReparacionesPrendas,
  UniDataTrabajosCortinas, inLibTrabajosCortinas;

constructor TReparacionesVentaTpv.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FRepositorio := TRepositorioReparacionesUniDAC.Create(AConexion);
  FEnlaceDeposito := -1;
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

function TReparacionesVentaTpv.LeerLinea(
  AConsulta: TUniQuery): TLineaServicioVenta;
begin
  Result := Default(TLineaServicioVenta);
  Result.Linea := AConsulta.FieldByName('LINEA_FACLIN').AsString;
  Result.Articulo := AConsulta.FieldByName('CODIGO_ART_FACLIN').AsString;
  Result.Descripcion :=
    AConsulta.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
  Result.Cantidad := AConsulta.FieldByName('CANTIDAD_FACLIN').AsFloat;
  Result.Total := AConsulta.FieldByName('TOTAL_FACLIN').AsCurrency;
  Result.CosteUltimaCompra :=
    AConsulta.FieldByName('PRECIO_ULT_COMPRA_FACLIN').AsCurrency;
end;

function TReparacionesVentaTpv.PrepararOrden(
  const ALinea: TLineaServicioVenta;
  const AVenta: TVentaServiciosReparacion): TReparacionNueva;
var
  Tipo: TTipoServicio;
  sArticulo: string;
  Prenda: TPrendaVentaReparacion;
  dCosteTipo: Currency;
begin
  Result := Default(TReparacionNueva);
  Result.Fecha := AVenta.Fecha;
  if Result.Fecha <= 0 then
    Result.Fecha := Now;
  sArticulo := ALinea.Articulo;
  for Tipo in FTipos do
    if (Tipo.Articulo = sArticulo) and
       ((Result.Tipo = '') or (Tipo.Codigo = sArticulo)) then
      Result := AplicarTipoServicio(Result, Tipo);
  dCosteTipo := Result.PrecioCoste;
  Result.Almacen := AVenta.Almacen;
  Result.Usuario := AVenta.Usuario;
  Result.Modalidad := MODALIDAD_REPARACION_PAGO;
  Result.Origen := ORIGEN_REPARACION_CLIENTE;
  Result.Cliente := AVenta.Cliente;
  Result.NombreCliente := AVenta.NombreCliente;
  if Trim(Result.NombreCliente) = '' then
    Result.NombreCliente := SClienteMostradorReparacion;
  Result.TelefonoCliente := AVenta.Telefono;
  Result.Trabajo := ALinea.Descripcion;
  if Trim(Result.Trabajo) = '' then
    Result.Trabajo := sArticulo;
  Result.DescripcionObjeto := Result.Trabajo;
  Result.ReferenciaObjeto := sArticulo;
  for Prenda in AVenta.Prendas do
    if (Prenda.LineaServicio=ALinea.Linea) and (Prenda.LineaPrenda<>'') then
    begin
      if Result.ReferenciaObjeto=sArticulo then
      begin
        Result.DescripcionObjeto := '';
        Result.ReferenciaObjeto := '';
      end;
      if Result.DescripcionObjeto<>'' then
        Result.DescripcionObjeto := Result.DescripcionObjeto+'; ';
      Result.DescripcionObjeto := Copy(Result.DescripcionObjeto+
        Prenda.Descripcion,1,200);
    end;
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
  Result.Cantidad := ALinea.Cantidad;
  Result.PrecioCliente := ALinea.Total / Result.Cantidad;
  // El coste unitario del tipo manda; un servicio no tiene última compra
  // y la liquidación al externo salía a 0 (FZ-ISSUE-780).
  Result.PrecioCoste := dCosteTipo;
  if Result.PrecioCoste = 0 then
    Result.PrecioCoste := ALinea.CosteUltimaCompra;
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
  const ALinea: TLineaServicioVenta;
  const AVenta: TVentaServiciosReparacion);
var
  oConsulta: TUniQuery;
begin
  if TieneEnlaceDeposito then
    oConsulta := Consulta('INSERT INTO fza_reparaciones_ventas ' +
      '(SERIE_FAC_GARVEN, NUMERO_FAC_GARVEN, LINEA_FACLIN_GARVEN, ' +
      'ID_GAR_GARVEN, CODIGO_ART_GARVEN, ID_DEP_GARVEN, INSTANTE_ALTA, ' +
      'USUARIO_ALTA) VALUES (:SERIE, :NUMERO, :LINEA, :ID, :ARTICULO, ' +
      'NULLIF(:DEPOSITO, ''''), NOW(6), :USUARIO)', AVenta)
  else
    oConsulta := Consulta('INSERT INTO fza_reparaciones_ventas ' +
      '(SERIE_FAC_GARVEN, NUMERO_FAC_GARVEN, LINEA_FACLIN_GARVEN, ' +
      'ID_GAR_GARVEN, CODIGO_ART_GARVEN, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:SERIE, :NUMERO, :LINEA, :ID, :ARTICULO, NOW(6), :USUARIO)',
      AVenta);
  try
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ParamByName('LINEA').AsString := ALinea.Linea;
    oConsulta.ParamByName('ARTICULO').AsString := ALinea.Articulo;
    if Assigned(oConsulta.Params.FindParam('DEPOSITO')) then
      oConsulta.ParamByName('DEPOSITO').AsString := ALinea.IdDeposito;
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

procedure TReparacionesVentaTpv.CrearOrden(
  const ALinea: TLineaServicioVenta;
  const AVenta: TVentaServiciosReparacion);
var
  Orden: TReparacionNueva;
  Linea: TLineaReparacion;
  iId: Int64;
  oPrendas: TDatosPrendasReparacion;
  oDetalles: TDatosTrabajosCortinas;
  sClase: string;
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
  sClase := ClaseArticuloServicio(ALinea.Articulo);
  oDetalles := TDatosTrabajosCortinas.Create(FConexion);
  try
    oDetalles.GuardarVenta(iId, ALinea.Linea, sClase, ALinea.Cantidad,
      AVenta);
  finally
    FreeAndNil(oDetalles);
  end;
  // En préstamo la prenda también queda en el depósito, no en una línea
  // vendida del ticket: no se recibe en el taller (FZ-ISSUE-778).
  if ALinea.IdDeposito = '' then
  begin
    oPrendas := TDatosPrendasReparacion.Create(FConexion);
    try
      if sClase<>CLASE_SERVICIO_INSTALACION then
        oPrendas.Recibir(iId, ALinea.Linea, AVenta);
    finally
      FreeAndNil(oPrendas);
    end;
  end;
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
        CrearOrden(LeerLinea(oConsulta), AVenta);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TReparacionesVentaTpv.ClaseArticuloServicio(
  const AArticulo: string): string;
var
  Tipo: TTipoServicio;
  sTipo: string;
begin
  Result := CLASE_SERVICIO_TALLER;
  sTipo := '';
  for Tipo in FTipos do
    if (Tipo.Articulo=AArticulo) and
       ((sTipo='') or (Tipo.Codigo=AArticulo)) then
    begin
      sTipo := Tipo.Codigo;
      if Tipo.ClaseServicio<>'' then
        Result := Tipo.ClaseServicio;
    end;
end;

function TReparacionesVentaTpv.CodigosServicio: TArray<string>;
var
  oConsulta: TUniQuery;
  i: Integer;
begin
  Result := nil;
  if TieneMarca then
  begin
    FTipos := FRepositorio.Tipos('');
    oConsulta := Consulta('SELECT CODIGO_ART_ART FROM fza_articulos ' +
      'WHERE ESSERVICIO_REPARACION_ART=''S'' AND TIPO_ART=''SERVICIO''',
      Default(TVentaServiciosReparacion));
    try
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        i := Length(Result);
        SetLength(Result,i+1);
        Result[i] := oConsulta.Fields[0].AsString;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TReparacionesVentaTpv.HayServicios(ALineas: TDataSet): Boolean;
var
  oConsulta: TUniQuery;
  Marcador: TBookmark;
  bVenta: Boolean;
  function Texto(const ACampo: string): string;
  begin
    Result := '';
    if Assigned(ALineas.FindField(ACampo)) then
      Result := ALineas.FieldByName(ACampo).AsString;
  end;
begin
  Result := False;
  if TieneMarca and not ALineas.IsEmpty then
  begin
    oConsulta := Consulta('SELECT 1 FROM fza_articulos ' +
      'WHERE CODIGO_ART_ART = :ARTICULO AND TIPO_ART = ''SERVICIO'' ' +
      'AND ESSERVICIO_REPARACION_ART = ''S''',
      Default(TVentaServiciosReparacion));
    Marcador := ALineas.GetBookmark;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof and not Result do
      begin
        bVenta := (Texto('VIENE_DE_DEPOSITO') <> 'A') and
          (Texto('ACCION_DEPOSITO') <> 'NUEVO_DEP') and
          (Texto('ACCION_DEPOSITO') <> 'AUMENTAR_DEP') and
          not ((Texto('VIENE_DE_DEPOSITO') = 'S') and
               DepositoConOrden(Texto('ID_DEPOSITO_DEP')));
        if bVenta and (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat > 0)
           and (Texto('CODIGO_ART_FACLIN') <> '') then
        begin
          oConsulta.Close;
          oConsulta.ParamByName('ARTICULO').AsString :=
            Texto('CODIGO_ART_FACLIN');
          oConsulta.Open;
          Result := not oConsulta.IsEmpty;
        end;
        if not Result then
          ALineas.Next;
      end;
    finally
      if ALineas.BookmarkValid(Marcador) then
        ALineas.GotoBookmark(Marcador);
      ALineas.FreeBookmark(Marcador);
      ALineas.EnableControls;
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TReparacionesVentaTpv.CompletarContactoCliente(
  const ACliente: string; var ANombre, ATelefono, AEmail: string);
var
  oConsulta: TUniQuery;
begin
  if (Trim(ACliente) <> '') and (Trim(ACliente) <> '0') and
     ((Trim(ANombre) = '') or (Trim(ATelefono) = '') or
      (Trim(AEmail) = '')) then
  begin
    oConsulta := Consulta('SELECT RAZON_SOCIAL_CLI, ' +
      'COALESCE(NULLIF(TRIM(MOVIL_CLI), ''''), ' +
      'NULLIF(TRIM(TELEFONO_CLI), ''''), ' +
      'TRIM(TELEFONO_CONTACTO_CLI)) AS TELEFONO, EMAIL_CLI ' +
      'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CLIENTE',
      Default(TVentaServiciosReparacion));
    try
      oConsulta.ParamByName('CLIENTE').AsString := Trim(ACliente);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        if Trim(ANombre) = '' then
          ANombre := oConsulta.Fields[0].AsString;
        if Trim(ATelefono) = '' then
          ATelefono := oConsulta.Fields[1].AsString;
        if Trim(AEmail) = '' then
          AEmail := oConsulta.Fields[2].AsString;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TReparacionesVentaTpv.TieneEnlaceDeposito: Boolean;
var
  oConsulta: TUniQuery;
begin
  if FEnlaceDeposito < 0 then
  begin
    oConsulta := Consulta('SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_reparaciones_ventas'' ' +
      'AND COLUMN_NAME = ''ID_DEP_GARVEN''',
      Default(TVentaServiciosReparacion));
    try
      oConsulta.Open;
      FEnlaceDeposito := Ord(not oConsulta.IsEmpty);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
  Result := FEnlaceDeposito = 1;
end;

function TReparacionesVentaTpv.EsServicioReparacion(
  const AArticulo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM fza_articulos ' +
    'WHERE CODIGO_ART_ART = :ARTICULO AND TIPO_ART = ''SERVICIO'' ' +
    'AND ESSERVICIO_REPARACION_ART = ''S''',
    Default(TVentaServiciosReparacion));
  try
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TReparacionesVentaTpv.OrdenesDeposito(
  const AIdDeposito: string): TArray<Int64>;
var
  oConsulta: TUniQuery;
  i: Integer;
begin
  Result := nil;
  if (Trim(AIdDeposito) <> '') and TieneMarca and TieneEnlaceDeposito then
  begin
    oConsulta := Consulta('SELECT DISTINCT ID_GAR_GARVEN ' +
      'FROM fza_reparaciones_ventas WHERE ID_DEP_GARVEN = :DEPOSITO ' +
      'ORDER BY ID_GAR_GARVEN', Default(TVentaServiciosReparacion));
    try
      oConsulta.ParamByName('DEPOSITO').AsString := Trim(AIdDeposito);
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        i := Length(Result);
        SetLength(Result, i + 1);
        Result[i] := oConsulta.Fields[0].AsLargeInt;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TReparacionesVentaTpv.DepositoConOrden(
  const AIdDeposito: string): Boolean;
begin
  Result := Length(OrdenesDeposito(AIdDeposito)) > 0;
end;

procedure TReparacionesVentaTpv.CrearOrdenesDepositos(
  const AVenta: TVentaServiciosReparacion;
  const ALineas: TLineasServicioVenta);
var
  Linea: TLineaServicioVenta;
  Venta: TVentaServiciosReparacion;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  if (Length(ALineas) > 0) and TieneMarca and TieneEnlaceDeposito then
  begin
    BloquearTicket(AVenta);
    FTipos := FRepositorio.Tipos('');
    // Solo hay anticipo: el resto se cobra al cerrar el depósito.
    Venta := AVenta;
    Venta.Cobrada := False;
    for Linea in ALineas do
      if (Linea.IdDeposito <> '') and (Linea.Cantidad > 0) and
         EsServicioReparacion(Linea.Articulo) and
         not DepositoConOrden(Linea.IdDeposito) then
        CrearOrden(Linea, Venta);
  end;
end;

procedure TReparacionesVentaTpv.EnlazarOrdenesDepositos(
  const AVenta: TVentaServiciosReparacion;
  const ALineas: TLineasServicioVenta);
var
  Linea: TLineaServicioVenta;
  iId: Int64;
  oConsulta: TUniQuery;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  for Linea in ALineas do
    for iId in OrdenesDeposito(Linea.IdDeposito) do
    begin
      VincularOrden(iId, Linea, AVenta);
      if AVenta.Cobrada then
      begin
        oConsulta := Consulta('UPDATE fza_garantias_reclamaciones ' +
          'SET ESCOBRADO_GAR = ''S'', SERIE_COBRO_GAR = :SERIE, ' +
          'NUMERO_COBRO_GAR = :NUMERO, INSTANTE_MODIF = NOW(), ' +
          'USUARIO_MODIF = :USUARIO WHERE ID_GAR = :ID', AVenta);
        try
          oConsulta.ParamByName('ID').AsLargeInt := iId;
          oConsulta.ExecSQL;
        finally
          FreeAndNil(oConsulta);
        end;
      end;
    end;
end;

function TReparacionesVentaTpv.LeerResguardo(AConsulta: TUniQuery):
  TResguardoGarantia;
begin
  Result := Default(TResguardoGarantia);
  Result.Numero := AConsulta.FieldByName('ID_GAR').AsLargeInt;
  Result.Fecha := AConsulta.FieldByName('INSTANTE_ALTA').AsDateTime;
  Result.FechaPrevista := AConsulta.FieldByName('FECHA_PREVISTA_GAR').AsDateTime;
  Result.Recepcion := AConsulta.FieldByName('FECHA_RECEPCION_GAR').AsDateTime;
  Result.Empresa := AConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
  Result.Nif := AConsulta.FieldByName('NIF_EMP').AsString;
  Result.Tienda := AConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
  Result.DireccionTienda := AConsulta.FieldByName('DIRECCION').AsString;
  Result.PoblacionTienda := AConsulta.FieldByName('POBLACION').AsString;
  Result.TelefonoTienda := AConsulta.FieldByName('TELEFONO_ALM').AsString;
  Result.Cliente := AConsulta.FieldByName('NOMBRE_CLIENTE_GAR').AsString;
  Result.TelefonoCliente :=
    AConsulta.FieldByName('TELEFONO_CLIENTE_GAR').AsString;
  Result.EmailCliente := AConsulta.FieldByName('EMAIL_CLIENTE_GAR').AsString;
  Result.EmailEmpresa := AConsulta.FieldByName('EMAIL_EMP').AsString;
  Result.Objeto := Trim(AConsulta.FieldByName('DESCRIPCION_OBJETO_GAR').
    AsString + ' ' + AConsulta.FieldByName('REFERENCIA_OBJETO_GAR').AsString);
  Result.Motivo := AConsulta.FieldByName('MOTIVO_GAR').AsString;
  Result.Modalidad := AConsulta.FieldByName('MODALIDAD_GAR').AsString;
  Result.ModoCobro := AConsulta.FieldByName('MODO_COBRO_GAR').AsString;
  Result.EsCobrado := AConsulta.FieldByName('ESCOBRADO_GAR').AsString = 'S';
  Result.Importe := AConsulta.FieldByName('TOTAL').AsCurrency;
  Result.DocumentoVenta := AConsulta.FieldByName('DOCUMENTO_VENTA').AsString;
  if Result.EsCobrado then
    Result.DocumentoCobro := Result.DocumentoVenta;
end;

function TReparacionesVentaTpv.Resguardos(
  const AVenta: TVentaServiciosReparacion): TArray<TResguardoGarantia>;
var
  oConsulta: TUniQuery;
  i: Integer;
  oDetalles: TDatosTrabajosCortinas;
begin
  Result := nil;
  if TieneMarca and (AVenta.Serie <> '') and (AVenta.Numero <> '') then
  begin
    oConsulta := Consulta('SELECT G.ID_GAR, V.INSTANTE_ALTA, ' +
      'G.FECHA_PREVISTA_GAR, G.FECHA_RECEPCION_GAR, ' +
      'G.NOMBRE_CLIENTE_GAR, G.TELEFONO_CLIENTE_GAR, G.EMAIL_CLIENTE_GAR, ' +
      'G.DESCRIPCION_OBJETO_GAR, G.REFERENCIA_OBJETO_GAR, G.MOTIVO_GAR, ' +
      'G.MODALIDAD_GAR, G.MODO_COBRO_GAR, G.ESCOBRADO_GAR, ' +
      'E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.EMAIL_EMP, A.NOMBRE_ALM_ALM, ' +
      'COALESCE(NULLIF(A.DIRECCION_ALM, ''''),E.DIRECCION1_EMP) AS DIRECCION, '+
      'CONCAT_WS('' '',A.CODIGO_POSTAL_ALM,A.POBLACION_ALM, ' +
      'A.PROVINCIA_ALM) AS POBLACION, A.TELEFONO_ALM, ' +
      'CONCAT(V.SERIE_FAC_GARVEN,''/'',V.NUMERO_FAC_GARVEN) ' +
      'AS DOCUMENTO_VENTA, (SELECT SUM(L.CANTIDAD_GARLIN * ' +
      'L.PRECIO_CLIENTE_GARLIN) FROM fza_garantias_lineas L ' +
      'WHERE L.ID_GAR_GARLIN=G.ID_GAR) AS TOTAL ' +
      'FROM fza_reparaciones_ventas V JOIN fza_garantias_reclamaciones G ' +
      'ON G.ID_GAR=V.ID_GAR_GARVEN ' +
      'JOIN fza_almacenes A ON A.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR ' +
      'JOIN fza_empresas E ON E.CODIGO_EMP_EMP=A.CODIGO_EMP_ALM ' +
      'WHERE V.SERIE_FAC_GARVEN=:SERIE AND V.NUMERO_FAC_GARVEN=:NUMERO ' +
      'AND E.CODIGO_EMP_EMP=:EMPRESA ORDER BY V.LINEA_FACLIN_GARVEN', AVenta);
    try
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        i := Length(Result);
        SetLength(Result, i + 1);
        Result[i] := LeerResguardo(oConsulta);
        oDetalles := TDatosTrabajosCortinas.Create(FConexion);
        try
          oDetalles.CompletarResguardo(Result[i].Numero,Result[i]);
        finally
          FreeAndNil(oDetalles);
        end;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.


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
    function LeerResguardo(AConsulta: TUniQuery): TResguardoGarantia;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    // Participa en la transacción del ticket: no confirma por su cuenta.
    procedure CrearOrdenes(const AVenta: TVentaServiciosReparacion);
    function ClaseArticuloServicio(const AArticulo: string): string;
    function CodigosServicio: TArray<string>;
    function HayServicios(ALineas: TDataSet): Boolean;
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
  Prenda: TPrendaVentaReparacion;
begin
  Result := Default(TReparacionNueva);
  Result.Fecha := AVenta.Fecha;
  if Result.Fecha <= 0 then
    Result.Fecha := Now;
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
  for Prenda in AVenta.Prendas do
    if (Prenda.LineaServicio=ALinea.FieldByName('LINEA_FACLIN').AsString)
       and (Prenda.LineaPrenda<>'') then
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
  sClase := ClaseArticuloServicio(ALinea.FieldByName(
    'CODIGO_ART_FACLIN').AsString);
  oDetalles := TDatosTrabajosCortinas.Create(FConexion);
  try
    oDetalles.GuardarVenta(iId,ALinea.FieldByName('LINEA_FACLIN').AsString,
      sClase,ALinea.FieldByName('CANTIDAD_FACLIN').AsFloat,AVenta);
  finally
    FreeAndNil(oDetalles);
  end;
  oPrendas := TDatosPrendasReparacion.Create(FConexion);
  try
    if sClase<>CLASE_SERVICIO_INSTALACION then
      oPrendas.Recibir(iId, ALinea.FieldByName('LINEA_FACLIN').AsString, AVenta);
  finally
    FreeAndNil(oPrendas);
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
        CrearOrden(oConsulta, AVenta);
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
          (Texto('ACCION_DEPOSITO') <> 'AUMENTAR_DEP');
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


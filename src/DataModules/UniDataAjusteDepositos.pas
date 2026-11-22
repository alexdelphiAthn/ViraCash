unit UniDataAjusteDepositos;

interface

uses
  Uni;

type
  TTipoMovimientoDeposito = (tmdTodos, tmdEntradaInicial, tmdCambioAlmacen);

  TFiltroAjusteDepositos = record
    Desde: TDateTime;
    Hasta: TDateTime;
    Origen: string;
    Tipo: TTipoMovimientoDeposito;
  end;

  TAlmacenAjusteDepositos = record
    Codigo: string;
    Nombre: string;
    Activo: Boolean;
  end;

  TDepositoAjustable = record
    Id: string;
    Movimiento: string;
    Fecha: TDateTime;
    Tienda: string;
    Articulo: string;
    Sku: string;
    Lote: string;
    Caducidad: TDateTime;
    Cantidad: Double;
    EsAjuste: Boolean;
  end;

  TRepositorioAjusteDepositos = class
  private
    FConexion: TUniConnection;
    FEmpresa: string;
    FTiendaRestringida: string;
    function LeerDepositos(const AFiltro: TFiltroAjusteDepositos;
      const AId: string): TArray<TDepositoAjustable>;
    procedure BloquearDeposito(const AId: string);
    procedure BloquearDestino(const ADestino: string);
    function CosteTraslado(const ADeposito: TDepositoAjustable;
      const AOrigen: string): Currency;
    procedure AuditarDeposito(const AId, AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection;
      const AEmpresa, ATiendaRestringida: string);
    function ListarAlmacenes: TArray<TAlmacenAjusteDepositos>;
    function ListarDepositos(const AFiltro: TFiltroAjusteDepositos):
      TArray<TDepositoAjustable>;
    procedure CambiarAlmacen(const AFiltro: TFiltroAjusteDepositos;
      const ADestino, AUsuario: string;
      const ASeleccion: TArray<TDepositoAjustable>);
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  System.Generics.Defaults,
  inLibMovimientosAlmacenAplicacion, UniDataMovimientosAlmacenRepositorio,
  UniDataAlmacenesEmpresaRepositorio;

const
  SQL_ALMACENES_DEPOSITO =
    'FROM fza_almacenes WHERE CODIGO_EMP_ALM = :EMPRESA ' +
    'AND TIPO_USO_ALM IN (''DEPÓSITO'', ''DEPOSITO'') ' +
    'AND (:TIENDA = '''' OR CODIGO_PADRE_ALM = :TIENDA ' +
    ' OR COALESCE(TRIM(CODIGO_PADRE_ALM), '''') = '''') ';

resourcestring
  SDepositoModificado = 'El depósito %s ya no coincide con la selección.';
  SStockInsuficiente = 'Stock insuficiente para el depósito %s en %s.';
  SDestinoInvalido = 'El almacén de destino debe ser un depósito activo.';
  STraspasoInvalido = 'Selecciona depósitos y un destino distinto del origen.';
  SEmpresaNecesaria = 'Selecciona una empresa para ajustar los depósitos.';
  SFiltroInvalido = 'Selecciona el almacén de origen y un rango válido.';

constructor TRepositorioAjusteDepositos.Create(AConexion: TUniConnection;
  const AEmpresa, ATiendaRestringida: string);
begin
  inherited Create;
  FConexion := AConexion;
  FEmpresa := Trim(AEmpresa);
  FTiendaRestringida := Trim(ATiendaRestringida);
  if FEmpresa = '' then
    raise EArgumentException.Create(SEmpresaNecesaria);
end;

function TRepositorioAjusteDepositos.ListarAlmacenes:
  TArray<TAlmacenAjusteDepositos>;
var
  Consulta: TUniQuery;
  Almacen: TAlmacenAjusteDepositos;
  Almacenes: TList<TAlmacenAjusteDepositos>;
begin
  Almacenes := TList<TAlmacenAjusteDepositos>.Create;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, ' +
      'ESACTIVO_ALM ' + SQL_ALMACENES_DEPOSITO +
      'ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    Consulta.ParamByName('EMPRESA').AsString := FEmpresa;
    Consulta.ParamByName('TIENDA').AsString := FTiendaRestringida;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Almacen.Codigo := Consulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Almacen.Nombre := Consulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Almacen.Activo := Consulta.FieldByName('ESACTIVO_ALM').AsString = 'S';
      Almacenes.Add(Almacen);
      Consulta.Next;
    end;
    Result := Almacenes.ToArray;
  finally
    Consulta.Free;
    Almacenes.Free;
  end;
end;

function TRepositorioAjusteDepositos.LeerDepositos(
  const AFiltro: TFiltroAjusteDepositos; const AId: string):
  TArray<TDepositoAjustable>;
var
  Consulta: TUniQuery;
  Deposito: TDepositoAjustable;
  Depositos: TList<TDepositoAjustable>;
begin
  if (AFiltro.Origen = '') or (AFiltro.Desde <= 0) or
     (AFiltro.Hasta < AFiltro.Desde) then
    raise EArgumentException.Create(SFiltroInvalido);
  Depositos := TList<TDepositoAjustable>.Create;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT D.ID_DEPOSITO_DEP, D.CODIGO_ALM_DEP, D.CODIGO_ART_DEP, ' +
      'D.CODIGO_UNIDAD_DEP, M.LOTE_MOV, M.FECHA_CADUCIDAD_MOV, ' +
      'COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD, ' +
      'M.NUMERO_MOV, M.FECHA_MOV, M.SERIE_DOC_MOV ' +
      'FROM fza_depositos_cliente D ' +
      'JOIN fza_movimientos_almacen M ON M.NUMERO_MOV = ' +
      SqlMovimientoCustodiaDeposito(AId <> '') +
      'WHERE D.CODIGO_EMP_DEP = :EMPRESA AND D.ESTADO_DEP = ''PENDIENTE'' ' +
      '  AND COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) > 0 ' +
      '  AND (:TIENDA = '''' OR D.CODIGO_ALM_DEP = :TIENDA) ' +
      '  AND M.CODIGO_ALM_MOV = :ORIGEN ' +
      '  AND M.FECHA_MOV >= :DESDE AND M.FECHA_MOV < :HASTA ';
    case AFiltro.Tipo of
      tmdEntradaInicial:
        Consulta.SQL.Add('AND M.SERIE_DOC_MOV <> :SERIE_AJUSTE');
      tmdCambioAlmacen:
        Consulta.SQL.Add('AND M.SERIE_DOC_MOV = :SERIE_AJUSTE');
    end;
    if AId <> '' then
      Consulta.SQL.Add('AND D.ID_DEPOSITO_DEP = :ID');
    Consulta.SQL.Add('ORDER BY M.FECHA_MOV, D.ID_DEPOSITO_DEP');
    if AId <> '' then
      Consulta.SQL.Add('FOR UPDATE');
    Consulta.ParamByName('EMPRESA').AsString := FEmpresa;
    Consulta.ParamByName('TIENDA').AsString := FTiendaRestringida;
    Consulta.ParamByName('ORIGEN').AsString := AFiltro.Origen;
    Consulta.ParamByName('DESDE').AsDate := Trunc(AFiltro.Desde);
    Consulta.ParamByName('HASTA').AsDate := Trunc(AFiltro.Hasta) + 1;
    if AFiltro.Tipo <> tmdTodos then
      Consulta.ParamByName('SERIE_AJUSTE').AsString := SERIE_CAMBIO_DEPOSITO;
    if AId <> '' then
      Consulta.ParamByName('ID').AsString := AId;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Deposito.Id := Consulta.FieldByName('ID_DEPOSITO_DEP').AsString;
      Deposito.Movimiento := Consulta.FieldByName('NUMERO_MOV').AsString;
      Deposito.Fecha := Consulta.FieldByName('FECHA_MOV').AsDateTime;
      Deposito.Tienda := Consulta.FieldByName('CODIGO_ALM_DEP').AsString;
      Deposito.Articulo := Consulta.FieldByName('CODIGO_ART_DEP').AsString;
      Deposito.Sku := Consulta.FieldByName('CODIGO_UNIDAD_DEP').AsString;
      Deposito.Lote := Consulta.FieldByName('LOTE_MOV').AsString;
      Deposito.Caducidad := Consulta.FieldByName('FECHA_CADUCIDAD_MOV')
        .AsDateTime;
      Deposito.Cantidad := Consulta.FieldByName('CANTIDAD').AsFloat;
      Deposito.EsAjuste := Consulta.FieldByName('SERIE_DOC_MOV').AsString =
        SERIE_CAMBIO_DEPOSITO;
      Depositos.Add(Deposito);
      Consulta.Next;
    end;
    Result := Depositos.ToArray;
  finally
    Consulta.Free;
    Depositos.Free;
  end;
end;

function TRepositorioAjusteDepositos.ListarDepositos(
  const AFiltro: TFiltroAjusteDepositos): TArray<TDepositoAjustable>;
begin
  Result := LeerDepositos(AFiltro, '');
end;

procedure TRepositorioAjusteDepositos.BloquearDeposito(const AId: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT ID_DEPOSITO_DEP FROM fza_depositos_cliente ' +
      'WHERE ID_DEPOSITO_DEP = :ID AND CODIGO_EMP_DEP = :EMPRESA ' +
      '  AND ESTADO_DEP = ''PENDIENTE'' ' +
      '  AND (:TIENDA = '''' OR CODIGO_ALM_DEP = :TIENDA) FOR UPDATE';
    Consulta.ParamByName('ID').AsString := AId;
    Consulta.ParamByName('EMPRESA').AsString := FEmpresa;
    Consulta.ParamByName('TIENDA').AsString := FTiendaRestringida;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise Exception.CreateFmt(SDepositoModificado, [AId]);
  finally
    Consulta.Free;
  end;
end;

procedure TRepositorioAjusteDepositos.BloquearDestino(
  const ADestino: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := 'SELECT CODIGO_ALM_ALM ' + SQL_ALMACENES_DEPOSITO +
      'AND CODIGO_ALM_ALM = :DESTINO AND ESACTIVO_ALM = ''S'' FOR UPDATE';
    Consulta.ParamByName('EMPRESA').AsString := FEmpresa;
    Consulta.ParamByName('TIENDA').AsString := FTiendaRestringida;
    Consulta.ParamByName('DESTINO').AsString := ADestino;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise Exception.Create(SDestinoInvalido);
  finally
    Consulta.Free;
  end;
end;

function TRepositorioAjusteDepositos.CosteTraslado(
  const ADeposito: TDepositoAjustable; const AOrigen: string): Currency;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT CANTIDAD_STK, COALESCE(FNC_FZA_COSTE_SALIDA(' +
      '  CODIGO_ALM_STK, CODIGO_UNIDAD_STK, LOTE_STK), ' +
      '  PRECIO_MEDIO_STK, 0) AS COSTE ' +
      'FROM fza_articulos_stockactual WHERE CODIGO_ALM_STK = :ALMACEN ' +
      '  AND CODIGO_UNIDAD_STK = :SKU AND LOTE_STK = :LOTE FOR UPDATE';
    Consulta.ParamByName('ALMACEN').AsString := AOrigen;
    Consulta.ParamByName('SKU').AsString := ADeposito.Sku;
    Consulta.ParamByName('LOTE').AsString := ADeposito.Lote;
    Consulta.Open;
    if Consulta.IsEmpty or
       (Consulta.FieldByName('CANTIDAD_STK').AsFloat + 0.000001 <
        ADeposito.Cantidad) then
      raise Exception.CreateFmt(SStockInsuficiente, [ADeposito.Id, AOrigen]);
    Result := Consulta.FieldByName('COSTE').AsCurrency;
  finally
    Consulta.Free;
  end;
end;

procedure TRepositorioAjusteDepositos.AuditarDeposito(
  const AId, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := 'UPDATE fza_depositos_cliente ' +
      'SET INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_DEPOSITO_DEP = :ID AND CODIGO_EMP_DEP = :EMPRESA';
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ParamByName('ID').AsString := AId;
    Consulta.ParamByName('EMPRESA').AsString := FEmpresa;
    Consulta.Execute;
  finally
    Consulta.Free;
  end;
end;

procedure TRepositorioAjusteDepositos.CambiarAlmacen(
  const AFiltro: TFiltroAjusteDepositos; const ADestino, AUsuario: string;
  const ASeleccion: TArray<TDepositoAjustable>);
var
  Escritor: IEscritorMovimientosAlmacen;
  Trabajo: IUnidadTrabajoMovimientosAlmacen;
  Seleccion, Vigentes: TArray<TDepositoAjustable>;
  Deposito, Vigente: TDepositoAjustable;
  Movimiento: TMovimientoAlmacenEscritura;
begin
  if (Length(ASeleccion) = 0) or (ADestino = '') or
     SameText(AFiltro.Origen, ADestino) then
    raise EArgumentException.Create(STraspasoInvalido);
  Seleccion := Copy(ASeleccion);
  TArray.Sort<TDepositoAjustable>(Seleccion,
    TComparer<TDepositoAjustable>.Construct(
      function(const Izquierda, Derecha: TDepositoAjustable): Integer
      begin
        Result := CompareStr(Izquierda.Id, Derecha.Id);
      end));
  CrearEscrituraMovimientosAlmacenUniDAC(FConexion, Escritor, Trabajo);
  Trabajo.Iniciar;
  try
    // Bloquear las fichas antes de leer la custodia para serializar el
    // ajuste con otros traslados y con el cierre en caja o facturación.
    for Deposito in Seleccion do
      BloquearDeposito(Deposito.Id);
    BloquearDestino(ADestino);
    for Deposito in Seleccion do
    begin
      Vigentes := LeerDepositos(AFiltro, Deposito.Id);
      if (Length(Vigentes) <> 1) or
         (Vigentes[0].Movimiento <> Deposito.Movimiento) or
         (Vigentes[0].Cantidad <> Deposito.Cantidad) then
        raise Exception.CreateFmt(SDepositoModificado, [Deposito.Id]);
      Vigente := Vigentes[0];
      Movimiento := Default(TMovimientoAlmacenEscritura);
      Movimiento.TipoDocumento := 'TR';
      Movimiento.SerieDocumento := SERIE_CAMBIO_DEPOSITO;
      Movimiento.NumeroDocumento := Vigente.Id;
      Movimiento.Linea := '0001';
      Movimiento.Empresa := FEmpresa;
      Movimiento.Almacen := AFiltro.Origen;
      Movimiento.AlmacenContrapartida := ADestino;
      Movimiento.Unidad := Vigente.Sku;
      Movimiento.Articulo := Vigente.Articulo;
      Movimiento.TipoMovimiento := 'S';
      Movimiento.Cantidad := Vigente.Cantidad;
      Movimiento.CosteUnitario := CosteTraslado(Vigente, AFiltro.Origen);
      Movimiento.Lote := Vigente.Lote;
      Movimiento.FechaCaducidad := Vigente.Caducidad;
      Movimiento.ConservarLote := True;
      Movimiento.Usuario := AUsuario;
      Escritor.Guardar(Movimiento);
      Movimiento.Linea := '0002';
      Movimiento.Almacen := ADestino;
      Movimiento.AlmacenContrapartida := AFiltro.Origen;
      Movimiento.TipoMovimiento := 'E';
      Escritor.Guardar(Movimiento);
      AuditarDeposito(Deposito.Id, AUsuario);
    end;
    Trabajo.Confirmar;
  except
    Trabajo.Revertir;
    raise;
  end;
end;

end.

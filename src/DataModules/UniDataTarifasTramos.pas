{******************************************************************************}
{  Módulo: UniDataTarifasTramos                                                 }
{  Tipo: Persistencia                                                          }
{  Fecha: 13/11/2026                                                           }
{  FZ-ISSUE-944. En una misma tarifa, artículo y SKU no puede haber dos        }
{  precios vigentes el mismo día:                                              }
{  - los precios cerrados fijos (periodos de rebajas y precios con fecha fin   }
{    puestos a mano, ESTRAMO_ARTTAR = 'N') no se pueden solapar entre sí y no }
{    se tocan nunca;                                                           }
{  - el precio base (la fila abierta y sus tramos, ESTRAMO_ARTTAR = 'S')       }
{    rellena solo los huecos que dejan los fijos.                              }
{  Al aplicar un periodo se aparta el precio base de sus fechas; al aplicar    }
{  un precio base desde una fecha se rehace a partir de ella.                  }
{******************************************************************************}
unit UniDataTarifasTramos;

interface

uses
  System.SysUtils, System.Generics.Collections, Data.DB, Uni;

type
  TPreciosTramoTarifa = record
    Salida: Double;
    Final: Double;
    Dto: Double;
    PorcentajeDto: Double;
  end;

  TTramosPrecioTarifa = class
  private type
    TTramoPendiente = record
      Origen: Integer;
      Desde: TDate;
      TieneHasta: Boolean;
      Hasta: TDate;
    end;
  private
    FConexion: TUniConnection;
    FUsuario: string;
    FArticulo: string;
    FSku: string;
    FTarifa: string;
    function NuevaConsulta(const ASql: string): TUniQuery;
    function SiguienteLibre(ADesde: TDate): TDate;
    function SiguienteFijo(ADesde: TDate; out AInicio: TDate): Boolean;
    function Insertar(ADesde: TDate; ATieneHasta: Boolean; AHasta: TDate;
      AOrigen: Integer; AConPrecios: Boolean;
      const APrecios: TPreciosTramoTarifa): Integer;
    function EscribirBase(ADesde: TDate; ATieneHasta: Boolean;
      AHasta: TDate; AOrigen: Integer; AConPrecios: Boolean;
      const APrecios: TPreciosTramoTarifa): Integer;
    procedure ApartarBase(ADesde: TDate; ATieneHasta: Boolean;
      AHasta: TDate; APendientes: TList<TTramoPendiente>;
      out AOrigenEnInicio: Integer);
    procedure EscribirPendientes(APendientes: TList<TTramoPendiente>);
    procedure ComprobarSolape(ADesde, AHasta: TDate);
  public
    constructor Create(AConexion: TUniConnection; const AUsuario,
      AArticulo, ASku, ATarifa: string);
    // Periodo [ADesde, AHasta]: crea o actualiza su fila y aparta el precio
    // base de esas fechas. Devuelve CODIGO_UNICO_ARTTAR del periodo.
    function AplicarPeriodo(ADesde, AHasta: TDate;
      const APrecios: TPreciosTramoTarifa): Integer;
    // Precio base desde ADesde (hasta AHasta si ATieneHasta). Devuelve el
    // CODIGO_UNICO_ARTTAR de su primer tramo.
    function AplicarBase(ADesde: TDate; ATieneHasta: Boolean; AHasta: TDate;
      const APrecios: TPreciosTramoTarifa): Integer;
  end;

implementation

uses
  inLibMsgArticulos;

const
  SQL_CLAVE =
    'T.CODIGO_ART_ARTTAR = :ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = :SKU ' +
    'AND T.CODIGO_TAR_ARTTAR = :TAR AND T.ESACTIVO_ARTTAR = ''S'' ';
  SQL_FIJO =
    'AND T.FECHA_HASTA_ARTTAR IS NOT NULL AND T.ESTRAMO_ARTTAR = ''N'' ';
  SQL_BASE =
    'AND (T.FECHA_HASTA_ARTTAR IS NULL OR T.ESTRAMO_ARTTAR = ''S'') ';
  SQL_DESDE = 'COALESCE(T.FECHA_DESDE_ARTTAR, ''1000-01-01'')';
  // Columnas que conserva un tramo copiado de otra fila del precio base.
  SQL_COLUMNAS_COPIA =
    'CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    'PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    'PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, PORCENTAJE_MARGEN_ARTTAR, ' +
    'VALOR_MULTIPLO_AJUSTE_ARTTAR, VALOR_MENOS_AJUSTE_ARTTAR, ' +
    'PRECIO_COSTE_ARTTAR, FECHA_ULT_COMPRA_ARTTAR, CODIGO_PRV_ARTTAR';

constructor TTramosPrecioTarifa.Create(AConexion: TUniConnection;
  const AUsuario, AArticulo, ASku, ATarifa: string);
begin
  inherited Create;
  FConexion := AConexion;
  FUsuario := AUsuario;
  FArticulo := AArticulo;
  FSku := ASku;
  FTarifa := ATarifa;
end;

function TTramosPrecioTarifa.NuevaConsulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
  if Assigned(Result.Params.FindParam('ART')) then
  begin
    Result.ParamByName('ART').AsString := FArticulo;
    Result.ParamByName('SKU').AsString := FSku;
    Result.ParamByName('TAR').AsString := FTarifa;
  end;
end;

// Primer día desde ADesde que no cubre ningún precio fijo.
function TTramosPrecioTarifa.SiguienteLibre(ADesde: TDate): TDate;
var
  qry: TUniQuery;
  Seguir: Boolean;
begin
  Result := ADesde;
  qry := NuevaConsulta(
    'SELECT MAX(T.FECHA_HASTA_ARTTAR) AS HASTA ' +
    'FROM fza_articulos_tarifas T WHERE ' + SQL_CLAVE + SQL_FIJO +
    'AND ' + SQL_DESDE + ' <= :DIA AND T.FECHA_HASTA_ARTTAR >= :DIA');
  try
    repeat
      qry.Close;
      qry.ParamByName('DIA').AsDate := Result;
      qry.Open;
      Seguir := not qry.FieldByName('HASTA').IsNull;
      if Seguir then
        Result := qry.FieldByName('HASTA').AsDateTime + 1;
    until not Seguir;
  finally
    qry.Free;
  end;
end;

// Inicio del siguiente precio fijo que empieza después de ADesde.
function TTramosPrecioTarifa.SiguienteFijo(ADesde: TDate;
  out AInicio: TDate): Boolean;
var
  qry: TUniQuery;
begin
  qry := NuevaConsulta(
    'SELECT MIN(T.FECHA_DESDE_ARTTAR) AS DESDE ' +
    'FROM fza_articulos_tarifas T WHERE ' + SQL_CLAVE + SQL_FIJO +
    'AND T.FECHA_DESDE_ARTTAR > :DIA');
  try
    qry.ParamByName('DIA').AsDate := ADesde;
    qry.Open;
    Result := not qry.FieldByName('DESDE').IsNull;
    AInicio := 0;
    if Result then
      AInicio := qry.FieldByName('DESDE').AsDateTime;
  finally
    qry.Free;
  end;
end;

// Inserta una fila del precio base. Con AOrigen copia sus columnas (coste,
// margen, ajustes...); con AConPrecios pone los precios de la sesión.
function TTramosPrecioTarifa.Insertar(ADesde: TDate; ATieneHasta: Boolean;
  AHasta: TDate; AOrigen: Integer; AConPrecios: Boolean;
  const APrecios: TPreciosTramoTarifa): Integer;
var
  qry: TUniQuery;
begin
  if AOrigen <> 0 then
  begin
    qry := NuevaConsulta(
      'INSERT INTO fza_articulos_tarifas (' + SQL_COLUMNAS_COPIA +
      ', ESACTIVO_ARTTAR, FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR, ' +
      'ESTRAMO_ARTTAR, USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) SELECT ' +
      SQL_COLUMNAS_COPIA + ', ''S'', :DESDE, :HASTA, :TRAMO, :USUARIO, ' +
      ':USUARIO, NOW() FROM fza_articulos_tarifas ' +
      'WHERE CODIGO_UNICO_ARTTAR = :ORIGEN');
    qry.ParamByName('ORIGEN').AsInteger := AOrigen;
  end
  else
  begin
    qry := NuevaConsulta(
      'INSERT INTO fza_articulos_tarifas (CODIGO_ART_ARTTAR, ' +
      'CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, ' +
      'FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR, ESTRAMO_ARTTAR, ' +
      'USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) VALUES (:A, :S, :T, ' +
      '''S'', :DESDE, :HASTA, :TRAMO, :USUARIO, :USUARIO, NOW())');
    qry.ParamByName('A').AsString := FArticulo;
    qry.ParamByName('S').AsString := FSku;
    qry.ParamByName('T').AsString := FTarifa;
  end;
  try
    qry.ParamByName('DESDE').AsDate := ADesde;
    qry.ParamByName('HASTA').DataType := ftDate;
    if ATieneHasta then
      qry.ParamByName('HASTA').AsDate := AHasta
    else
      qry.ParamByName('HASTA').Clear;
    // Un tramo cerrado del precio base se marca para poder rehacerlo.
    if ATieneHasta then
      qry.ParamByName('TRAMO').AsString := 'S'
    else
      qry.ParamByName('TRAMO').AsString := 'N';
    qry.ParamByName('USUARIO').AsString := FUsuario;
    qry.Execute;
    qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    qry.Open;
    Result := qry.FieldByName('ID').AsInteger;
  finally
    qry.Free;
  end;
  if AConPrecios then
  begin
    qry := NuevaConsulta(
      'UPDATE fza_articulos_tarifas SET PRECIO_SALIDA_ARTTAR = :SALIDA, ' +
      'PRECIO_FINAL_ARTTAR = :FINAL, PRECIO_DTO_ARTTAR = :DTO, ' +
      'PORCENTAJE_DTO_ARTTAR = :PORC WHERE CODIGO_UNICO_ARTTAR = :ID');
    try
      qry.ParamByName('SALIDA').AsFloat := APrecios.Salida;
      qry.ParamByName('FINAL').AsFloat := APrecios.Final;
      qry.ParamByName('DTO').AsFloat := APrecios.Dto;
      qry.ParamByName('PORC').AsFloat := APrecios.PorcentajeDto;
      qry.ParamByName('ID').AsInteger := Result;
      qry.Execute;
    finally
      qry.Free;
    end;
  end;
end;

// Escribe el precio base de [ADesde, AHasta] (o sin fin) solo en los huecos
// entre precios fijos. Devuelve el primer tramo escrito (0 si ninguno).
function TTramosPrecioTarifa.EscribirBase(ADesde: TDate;
  ATieneHasta: Boolean; AHasta: TDate; AOrigen: Integer;
  AConPrecios: Boolean; const APrecios: TPreciosTramoTarifa): Integer;
var
  Actual: TDate;
  InicioFijo: TDate;
  Id: Integer;
  Fin: Boolean;
begin
  Result := 0;
  Actual := SiguienteLibre(ADesde);
  Fin := False;
  while not Fin do
  begin
    if ATieneHasta and (Actual > AHasta) then
      Fin := True
    else if SiguienteFijo(Actual, InicioFijo) and
      ((not ATieneHasta) or (InicioFijo <= AHasta)) then
    begin
      Id := Insertar(Actual, True, InicioFijo - 1, AOrigen, AConPrecios,
        APrecios);
      if Result = 0 then
        Result := Id;
      Actual := SiguienteLibre(InicioFijo);
    end
    else
    begin
      Id := Insertar(Actual, ATieneHasta, AHasta, AOrigen, AConPrecios,
        APrecios);
      if Result = 0 then
        Result := Id;
      Fin := True;
    end;
  end;
end;

// Retira el precio base de [ADesde, AHasta] (o sin fin). Lo anterior se
// cierra el día antes; lo que pasa de AHasta se apunta en APendientes para
// volver a escribirlo después. AOrigenEnInicio es la fila base que estaba
// vigente en ADesde (para copiar sus columnas), o 0.
procedure TTramosPrecioTarifa.ApartarBase(ADesde: TDate;
  ATieneHasta: Boolean; AHasta: TDate;
  APendientes: TList<TTramoPendiente>; out AOrigenEnInicio: Integer);
var
  qry: TUniQuery;
  qryCambio: TUniQuery;
  Pendiente: TTramoPendiente;
  Id: Integer;
  EmpiezaAntes: Boolean;
  SigueDespues: Boolean;
  FinFila: TDate;
  TieneFin: Boolean;
begin
  AOrigenEnInicio := 0;
  qry := NuevaConsulta(
    'SELECT T.CODIGO_UNICO_ARTTAR, T.FECHA_DESDE_ARTTAR, ' +
    'T.FECHA_HASTA_ARTTAR FROM fza_articulos_tarifas T WHERE ' +
    SQL_CLAVE + SQL_BASE +
    'AND (T.FECHA_HASTA_ARTTAR IS NULL OR T.FECHA_HASTA_ARTTAR >= :DESDE) ' +
    'AND (:SIN_FIN = 1 OR ' + SQL_DESDE + ' <= :HASTA) ' +
    'ORDER BY ' + SQL_DESDE + ', T.CODIGO_UNICO_ARTTAR');
  qryCambio := NuevaConsulta('');
  try
    qry.ParamByName('DESDE').AsDate := ADesde;
    qry.ParamByName('SIN_FIN').AsInteger := Ord(not ATieneHasta);
    qry.ParamByName('HASTA').DataType := ftDate;
    if ATieneHasta then
      qry.ParamByName('HASTA').AsDate := AHasta
    else
      qry.ParamByName('HASTA').AsDate := ADesde;
    qry.Open;
    while not qry.Eof do
    begin
      Id := qry.FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
      EmpiezaAntes := qry.FieldByName('FECHA_DESDE_ARTTAR').IsNull or
        (qry.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime < ADesde);
      TieneFin := not qry.FieldByName('FECHA_HASTA_ARTTAR').IsNull;
      FinFila := 0;
      if TieneFin then
        FinFila := qry.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime;
      SigueDespues := ATieneHasta and ((not TieneFin) or (FinFila > AHasta));
      if EmpiezaAntes then
      begin
        AOrigenEnInicio := Id;
        if SigueDespues then
        begin
          Pendiente.Origen := Id;
          Pendiente.Desde := AHasta + 1;
          Pendiente.TieneHasta := TieneFin;
          Pendiente.Hasta := FinFila;
          APendientes.Add(Pendiente);
        end;
        qryCambio.SQL.Text :=
          'UPDATE fza_articulos_tarifas SET FECHA_HASTA_ARTTAR = :HASTA, ' +
          'ESTRAMO_ARTTAR = ''S'', USUARIO_MODIF = :USUARIO, ' +
          'INSTANTE_MODIF = NOW() WHERE CODIGO_UNICO_ARTTAR = :ID';
        qryCambio.ParamByName('HASTA').AsDate := ADesde - 1;
      end
      else if SigueDespues then
      begin
        if AOrigenEnInicio = 0 then
          AOrigenEnInicio := Id;
        qryCambio.SQL.Text :=
          'UPDATE fza_articulos_tarifas SET FECHA_DESDE_ARTTAR = :DESDE, ' +
          'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
          'WHERE CODIGO_UNICO_ARTTAR = :ID';
        qryCambio.ParamByName('DESDE').AsDate := AHasta + 1;
      end
      else
      begin
        // Queda entera dentro: el precio nuevo la sustituye. Se desactiva
        // en lugar de borrarla para conservar el histórico.
        if AOrigenEnInicio = 0 then
          AOrigenEnInicio := Id;
        qryCambio.SQL.Text :=
          'UPDATE fza_articulos_tarifas SET ESACTIVO_ARTTAR = ''N'', ' +
          'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
          'WHERE CODIGO_UNICO_ARTTAR = :ID';
      end;
      qryCambio.ParamByName('USUARIO').AsString := FUsuario;
      qryCambio.ParamByName('ID').AsInteger := Id;
      qryCambio.Execute;
      qry.Next;
    end;
  finally
    qryCambio.Free;
    qry.Free;
  end;
end;

procedure TTramosPrecioTarifa.EscribirPendientes(
  APendientes: TList<TTramoPendiente>);
var
  Pendiente: TTramoPendiente;
  SinPrecios: TPreciosTramoTarifa;
begin
  SinPrecios := Default(TPreciosTramoTarifa);
  for Pendiente in APendientes do
    EscribirBase(Pendiente.Desde, Pendiente.TieneHasta, Pendiente.Hasta,
      Pendiente.Origen, False, SinPrecios);
end;

procedure TTramosPrecioTarifa.ComprobarSolape(ADesde, AHasta: TDate);
var
  qry: TUniQuery;
  sArticulo: string;
begin
  qry := NuevaConsulta(
    'SELECT T.FECHA_DESDE_ARTTAR, T.FECHA_HASTA_ARTTAR ' +
    'FROM fza_articulos_tarifas T WHERE ' + SQL_CLAVE + SQL_FIJO +
    'AND NOT (T.FECHA_DESDE_ARTTAR <=> :DESDE ' +
    '  AND T.FECHA_HASTA_ARTTAR = :HASTA) ' +
    'AND ' + SQL_DESDE + ' <= :HASTA AND T.FECHA_HASTA_ARTTAR >= :DESDE ' +
    'ORDER BY ' + SQL_DESDE + ' LIMIT 1');
  try
    qry.ParamByName('DESDE').AsDate := ADesde;
    qry.ParamByName('HASTA').AsDate := AHasta;
    qry.Open;
    if not qry.IsEmpty then
    begin
      sArticulo := FArticulo;
      if FSku <> '' then
        sArticulo := FSku;
      raise EDatabaseError.CreateFmt(SErrorPeriodoTarifaSolapaPrecio,
        [DateToStr(ADesde), DateToStr(AHasta), sArticulo, FTarifa,
         DateToStr(qry.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime),
         DateToStr(qry.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime)]);
    end;
  finally
    qry.Free;
  end;
end;

function TTramosPrecioTarifa.AplicarPeriodo(ADesde, AHasta: TDate;
  const APrecios: TPreciosTramoTarifa): Integer;
var
  qry: TUniQuery;
  Pendientes: TList<TTramoPendiente>;
  OrigenBase: Integer;
begin
  ComprobarSolape(ADesde, AHasta);
  Pendientes := TList<TTramoPendiente>.Create;
  try
    // Primero se aparta el precio base: así el periodo no se solapa con él.
    ApartarBase(ADesde, True, AHasta, Pendientes, OrigenBase);
    qry := NuevaConsulta(
      'SELECT T.CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas T ' +
      'WHERE ' + SQL_CLAVE + SQL_FIJO +
      'AND T.FECHA_DESDE_ARTTAR = :DESDE AND T.FECHA_HASTA_ARTTAR = :HASTA ' +
      'ORDER BY T.CODIGO_UNICO_ARTTAR DESC LIMIT 1');
    try
      qry.ParamByName('DESDE').AsDate := ADesde;
      qry.ParamByName('HASTA').AsDate := AHasta;
      qry.Open;
      if qry.IsEmpty then
      begin
        Result := Insertar(ADesde, True, AHasta, 0, True, APrecios);
        // Insertar marca como tramo lo cerrado; un periodo es fijo.
        qry.Close;
        qry.SQL.Text :=
          'UPDATE fza_articulos_tarifas SET ESTRAMO_ARTTAR = ''N'' ' +
          'WHERE CODIGO_UNICO_ARTTAR = :ID';
        qry.ParamByName('ID').AsInteger := Result;
        qry.Execute;
      end
      else
      begin
        Result := qry.FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
        qry.Close;
        qry.SQL.Text :=
          'UPDATE fza_articulos_tarifas SET ' +
          'PRECIO_SALIDA_ARTTAR = :SALIDA, PRECIO_FINAL_ARTTAR = :FINAL, ' +
          'PRECIO_DTO_ARTTAR = :DTO, PORCENTAJE_DTO_ARTTAR = :PORC, ' +
          'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
          'WHERE CODIGO_UNICO_ARTTAR = :ID';
        qry.ParamByName('SALIDA').AsFloat := APrecios.Salida;
        qry.ParamByName('FINAL').AsFloat := APrecios.Final;
        qry.ParamByName('DTO').AsFloat := APrecios.Dto;
        qry.ParamByName('PORC').AsFloat := APrecios.PorcentajeDto;
        qry.ParamByName('USUARIO').AsString := FUsuario;
        qry.ParamByName('ID').AsInteger := Result;
        qry.Execute;
      end;
    finally
      qry.Free;
    end;
    // Lo que el precio base cubría después del periodo vuelve, saltando
    // otros periodos que haya a continuación.
    EscribirPendientes(Pendientes);
  finally
    Pendientes.Free;
  end;
end;

function TTramosPrecioTarifa.AplicarBase(ADesde: TDate; ATieneHasta: Boolean;
  AHasta: TDate; const APrecios: TPreciosTramoTarifa): Integer;
var
  Pendientes: TList<TTramoPendiente>;
  OrigenBase: Integer;
begin
  Pendientes := TList<TTramoPendiente>.Create;
  try
    ApartarBase(ADesde, ATieneHasta, AHasta, Pendientes, OrigenBase);
    Result := EscribirBase(ADesde, ATieneHasta, AHasta, OrigenBase, True,
      APrecios);
    EscribirPendientes(Pendientes);
  finally
    Pendientes.Free;
  end;
end;

end.

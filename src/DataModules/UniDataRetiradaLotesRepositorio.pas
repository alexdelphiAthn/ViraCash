{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRetiradaLotesRepositorio                               }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Traspaso a TARAS y archivo de órdenes de retirada.            }
{******************************************************************************}
unit UniDataRetiradaLotesRepositorio;

interface

uses
  Data.DB, Uni, inLibRetiradaLotesIntf, UniDataRetiradaLotesLecturas;

type
  TRepositorioRetiradaLotes = class(TInterfacedObject,
    IRepositorioRetiradaLotes)
  private
    FConexion: TUniConnection;
    FEmpresa: string;
    FAlmacenRestringido: string;
    FLecturas: TLecturasRetiradaLotes;
    procedure Bloquear(const AOrden: TOrdenRetiradaLotes);
    function Mover(const AOrden: TOrdenRetiradaLotes;
      const ALinea: TLineaRetiradaLote; AIndice: Integer;
      AEntrada: Boolean; ACoste: Double): string;
    procedure Insertar(const AOrden: TOrdenRetiradaLotes;
      const ALinea: TLineaRetiradaLote; AIndice: Integer;
      AAdicional: Boolean);
    function LeerLinea(ADatos: TUniQuery): TLineaRetiradaLote;
    procedure LeerCabecera(ADatos: TUniQuery;
      var AOrden: TOrdenRetiradaLotes);
    function Registrar(const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
  public
    constructor Create(AConexion: TUniConnection; const AEmpresa: string;
      const AAlmacenRestringido: string = '');
    destructor Destroy; override;
    function Guardar(const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
    function Leer(const AId: string): TOrdenRetiradaLotes;
    function LeerPorMovimiento(const ANumero: string): TOrdenRetiradaLotes;
    function AlmacenesTaras(const AEmpresa: string):
      TArray<TAlmacenRetiradaLotes>;
    function AlmacenesBaja: TArray<TAlmacenRetiradaLotes>;
    function StockSinLote(const AAlmacen, ASku: string): Double;
    function ConsultarBajas(const AAlmacen: string; ADesde, AHasta: TDateTime;
      AMotivo: Integer): TDataSet;
  end;

implementation

uses
  inLibMsgComun,
  System.SysUtils, System.Classes, System.Generics.Collections,
  inLibRetiradaLotes, inLibMsgRetiradaLotes,
  UniDataValoresAutomaticosRepositorio;

constructor TRepositorioRetiradaLotes.Create(AConexion: TUniConnection;
  const AEmpresa, AAlmacenRestringido: string);
begin
  inherited Create;
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FAlmacenRestringido := AAlmacenRestringido;
  FLecturas := TLecturasRetiradaLotes.Create(AConexion);
end;

function TRepositorioRetiradaLotes.AlmacenesBaja:
  TArray<TAlmacenRetiradaLotes>;
var
  Datos: TUniQuery;
  Almacenes: TList<TAlmacenRetiradaLotes>;
  Almacen: TAlmacenRetiradaLotes;
begin
  Almacenes := TList<TAlmacenRetiradaLotes>.Create;
  Datos := FLecturas.Consulta('SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
    'FROM fza_almacenes WHERE CODIGO_EMP_ALM = :EMP ' +
    'AND ESACTIVO_ALM = ''S'' ' +
    'AND (:RESTRICCION = '''' OR CODIGO_ALM_ALM = :RESTRICCION) ' +
    'ORDER BY ORDEN_ALM, CODIGO_ALM_ALM');
  try
    Datos.ParamByName('EMP').AsString := FEmpresa;
    Datos.ParamByName('RESTRICCION').AsString := FAlmacenRestringido;
    Datos.Open;
    while not Datos.Eof do
    begin
      Almacen.Codigo := Datos.Fields[0].AsString;
      Almacen.Nombre := Datos.Fields[1].AsString;
      Almacenes.Add(Almacen);
      Datos.Next;
    end;
    Result := Almacenes.ToArray;
  finally
    Datos.Free;
    Almacenes.Free;
  end;
end;

function TRepositorioRetiradaLotes.StockSinLote(
  const AAlmacen, ASku: string): Double;
var
  Datos: TUniQuery;
begin
  Datos := FLecturas.Consulta('SELECT S.CANTIDAD_STK ' +
    'FROM fza_articulos_stockactual S JOIN fza_almacenes M ' +
    'ON M.CODIGO_ALM_ALM = S.CODIGO_ALM_STK ' +
    'WHERE M.CODIGO_EMP_ALM = :EMP AND M.ESACTIVO_ALM = ''S'' ' +
    'AND (:RESTRICCION = '''' OR S.CODIGO_ALM_STK = :RESTRICCION) ' +
    'AND S.CODIGO_ALM_STK = :ALM AND S.CODIGO_UNIDAD_STK = :SKU ' +
    'AND S.LOTE_STK = ''''');
  try
    Datos.ParamByName('EMP').AsString := FEmpresa;
    Datos.ParamByName('RESTRICCION').AsString := FAlmacenRestringido;
    Datos.ParamByName('ALM').AsString := AAlmacen;
    Datos.ParamByName('SKU').AsString := ASku;
    Datos.Open;
    Result := Datos.Fields[0].AsFloat;
  finally
    Datos.Free;
  end;
end;

function TRepositorioRetiradaLotes.ConsultarBajas(
  const AAlmacen: string; ADesde, AHasta: TDateTime; AMotivo: Integer):
  TDataSet;
var
  Datos: TUniQuery;
begin
  Datos := FLecturas.Consulta('SELECT R.INSTANTE_LRET, R.CODIGO_ALM_LRET, ' +
    'R.CODIGO_UNIDAD_LRET, R.CANTIDAD_LRET, R.MOTIVO_LRET, ' +
    'R.USUARIO_ALTA, R.NUMERO_MOV_LRET, ' +
    'COALESCE(NULLIF(TRIM(A.TIPO_CANTIDAD_ART), ''''), ''Uds'') AS UNIDAD ' +
    'FROM fza_lotes_retiradas R ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = R.CODIGO_ART_LRET ' +
    'WHERE R.CODIGO_EMP_LRET = :EMP AND R.DESTINO_LRET = ''BAJA'' ' +
    'AND R.ESADICIONAL_LRET = ''N'' ' +
    'AND (:RESTRICCION = '''' OR R.CODIGO_ALM_LRET = :RESTRICCION) ' +
    'AND (:ALM = '''' OR R.CODIGO_ALM_LRET = :ALM) ' +
    'AND (:MOTIVO = '''' OR R.MOTIVO_LRET = :MOTIVO) ' +
    'AND R.INSTANTE_LRET >= :DESDE AND R.INSTANTE_LRET < :HASTA ' +
    'ORDER BY R.INSTANTE_LRET DESC, R.ID_LRET, R.LINEA_LRET');
  try
    Datos.ParamByName('EMP').AsString := FEmpresa;
    Datos.ParamByName('RESTRICCION').AsString := FAlmacenRestringido;
    Datos.ParamByName('ALM').AsString := AAlmacen;
    Datos.ParamByName('MOTIVO').AsString := '';
    if AMotivo >= 0 then
      Datos.ParamByName('MOTIVO').AsString := IntToStr(AMotivo);
    Datos.ParamByName('DESDE').AsDate := Trunc(ADesde);
    Datos.ParamByName('HASTA').AsDate := Trunc(AHasta) + 1;
    Datos.Open;
  except
    Datos.Free;
    raise;
  end;
  Result := Datos;
end;

destructor TRepositorioRetiradaLotes.Destroy;
begin
  FLecturas.Free;
  inherited;
end;

function TRepositorioRetiradaLotes.AlmacenesTaras(const AEmpresa: string):
  TArray<TAlmacenRetiradaLotes>;
begin
  if not SameText(AEmpresa, FEmpresa) then
    raise Exception.Create(SErrorRetiradaAlmacen);
  Result := FLecturas.AlmacenesTaras(AEmpresa);
end;

procedure TRepositorioRetiradaLotes.Bloquear(
  const AOrden: TOrdenRetiradaLotes);
var
  Claves: TStringList;
  Linea: TLineaRetiradaLote;
  Clave: string;
  Datos: TUniQuery;
  Separador: Integer;
begin
  Claves := TStringList.Create;
  try
    Claves.Sorted := True;
    Claves.Duplicates := dupIgnore;
    for Linea in AOrden.Lineas do
    begin
      Claves.Add(Linea.CodigoAlmacen + '|' + Linea.CodigoSku);
      if not AOrden.EsBajaSinLote then
        Claves.Add(AOrden.AlmacenDestino + '|' + Linea.CodigoSku);
    end;
    Datos := FLecturas.Consulta(
      'CALL PRC_FZA_STOCK_BLOQUEAR_CLAVE(:ALM, :SKU, :USUARIO)');
    try
      for Clave in Claves do
      begin
        Separador := Pos('|', Clave);
        Datos.ParamByName('ALM').AsString := Copy(Clave, 1, Separador - 1);
        Datos.ParamByName('SKU').AsString := Copy(Clave, Separador + 1);
        Datos.ParamByName('USUARIO').AsString := AOrden.Usuario;
        Datos.ExecSQL;
      end;
    finally
      Datos.Free;
    end;
  finally
    Claves.Free;
  end;
end;

function TRepositorioRetiradaLotes.Mover(const AOrden: TOrdenRetiradaLotes;
  const ALinea: TLineaRetiradaLote; AIndice: Integer;
  AEntrada: Boolean; ACoste: Double): string;
var
  Datos: TUniQuery;
  Almacen, Contra, Tipo: string;
begin
  Result := ObtenerSiguienteContador(FConexion, 'MV', AOrden.Usuario);
  Almacen := ALinea.CodigoAlmacen;
  Contra := AOrden.AlmacenDestino;
  Tipo := 'S';
  if AEntrada then
  begin
    Almacen := AOrden.AlmacenDestino;
    Contra := ALinea.CodigoAlmacen;
    Tipo := 'E';
  end;
  Datos := FLecturas.Consulta(
    'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT_LOTE(' +
    ':NUM, :TIPO_DOC, :SERIE, :DOC, :LIN, :EMP, :ALM, :CONTRA, :SKU, ' +
    ':TIPO, :CANT, :PMP, :COSTE, :USR, :ORIGEN, '''', '''', '''', ' +
    ':ART, :LOTE, :FECHA)');
  try
    Datos.ParamByName('NUM').AsString := Result;
    if AOrden.EsBajaSinLote then
    begin
      Datos.ParamByName('TIPO_DOC').AsString := 'ME';
      Datos.ParamByName('SERIE').AsString := 'BAJA';
    end
    else
    begin
      Datos.ParamByName('TIPO_DOC').AsString := 'TR';
      Datos.ParamByName('SERIE').AsString := 'RL';
    end;
    Datos.ParamByName('DOC').AsString := Copy(AOrden.Id, 1, 20);
    Datos.ParamByName('LIN').AsString := IntToStr(AIndice);
    Datos.ParamByName('EMP').AsString := AOrden.Empresa;
    Datos.ParamByName('ALM').AsString := Almacen;
    Datos.ParamByName('CONTRA').DataType := ftString;
    if Contra = '' then
      Datos.ParamByName('CONTRA').Clear
    else
      Datos.ParamByName('CONTRA').AsString := Contra;
    Datos.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Datos.ParamByName('TIPO').AsString := Tipo;
    Datos.ParamByName('CANT').AsFloat := ALinea.Cantidad;
    Datos.ParamByName('PMP').AsFloat := ACoste;
    Datos.ParamByName('COSTE').AsFloat := ALinea.Cantidad * ACoste;
    Datos.ParamByName('USR').AsString := AOrden.Usuario;
    Datos.ParamByName('ORIGEN').AsString := ALinea.CodigoAlmacen;
    Datos.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Datos.ParamByName('LOTE').AsString := ALinea.Lote;
    Datos.ParamByName('FECHA').DataType := ftDate;
    if ALinea.FechaCaducidad = 0 then
      Datos.ParamByName('FECHA').Clear
    else
      Datos.ParamByName('FECHA').AsDate := ALinea.FechaCaducidad;
    Datos.ExecSQL;
  finally
    Datos.Free;
  end;
end;

procedure TRepositorioRetiradaLotes.Insertar(
  const AOrden: TOrdenRetiradaLotes; const ALinea: TLineaRetiradaLote;
  AIndice: Integer; AAdicional: Boolean);
var
  Datos: TUniQuery;
begin
  Datos := FLecturas.Consulta('INSERT INTO fza_lotes_retiradas (' +
    'ID_LRET, LINEA_LRET, ESADICIONAL_LRET, INSTANTE_LRET, ' +
    'ESURGENTE_LRET, CODIGO_EMP_LRET, EMPLEADO_LRET, MOTIVO_LRET, ' +
    'DESTINO_LRET, CODIGO_ALM_DESTINO_LRET, CODIGO_ART_LRET, ' +
    'CODIGO_UNIDAD_LRET, DESCRIPCION_LRET, LOTE_LRET, ' +
    'FECHA_CADUCIDAD_LRET, CANTIDAD_LRET, CODIGO_ALM_LRET, UBICACION_LRET, ' +
    'NUMERO_MOV_LRET, NUMERO_MOV_DESTINO_LRET, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (:ID, :LIN, :ADIC, :INST, :URG, :EMP, :EMPL, :MOT, ' +
    ':DESTINO, NULLIF(:DEST, ''''), :ART, :SKU, :DESCR, :LOTE, :FECHA, ' +
    ':CANT, :ALM, ' +
    ':UBI, NULLIF(:MOV, ''''), NULLIF(:MOVDEST, ''''), :INST, :USR)');
  try
    Datos.ParamByName('ID').AsString := AOrden.Id;
    Datos.ParamByName('LIN').AsInteger := AIndice;
    Datos.ParamByName('ADIC').AsString := 'N';
    if AAdicional then
      Datos.ParamByName('ADIC').AsString := 'S';
    Datos.ParamByName('INST').AsDateTime := AOrden.Instante;
    Datos.ParamByName('URG').AsString := 'N';
    if AOrden.EsUrgente then
      Datos.ParamByName('URG').AsString := 'S';
    Datos.ParamByName('EMP').AsString := AOrden.Empresa;
    Datos.ParamByName('EMPL').AsString := AOrden.Empleado;
    Datos.ParamByName('MOT').AsString := IntToStr(Ord(AOrden.Motivo));
    if AOrden.EsBajaSinLote then
      Datos.ParamByName('DESTINO').AsString := 'BAJA'
    else
      Datos.ParamByName('DESTINO').AsString := 'TARAS';
    Datos.ParamByName('DEST').AsString := AOrden.AlmacenDestino;
    Datos.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Datos.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Datos.ParamByName('DESCR').AsString := ALinea.Descripcion;
    Datos.ParamByName('LOTE').AsString := ALinea.Lote;
    Datos.ParamByName('FECHA').DataType := ftDate;
    if ALinea.FechaCaducidad = 0 then
      Datos.ParamByName('FECHA').Clear
    else
      Datos.ParamByName('FECHA').AsDate := ALinea.FechaCaducidad;
    Datos.ParamByName('CANT').AsFloat := ALinea.Cantidad;
    Datos.ParamByName('ALM').AsString := ALinea.CodigoAlmacen;
    Datos.ParamByName('UBI').AsString := ALinea.Ubicacion;
    Datos.ParamByName('MOV').AsString := ALinea.NumeroMovimiento;
    Datos.ParamByName('MOVDEST').AsString := ALinea.NumeroMovimientoDestino;
    Datos.ParamByName('USR').AsString := AOrden.Usuario;
    Datos.ExecSQL;
  finally
    Datos.Free;
  end;
end;

function TRepositorioRetiradaLotes.Registrar(
  const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
var
  Indice: Integer;
  Coste: Double;
begin
  Result := AOrden;
  Result.Lineas := Copy(AOrden.Lineas);
  Result.Instante := Now;
  Bloquear(Result);
  if not Result.EsBajaSinLote then
    FLecturas.ValidarAlmacen(FEmpresa, Result.AlmacenDestino, True);
  for Indice := 0 to High(Result.Lineas) do
  begin
    FLecturas.ValidarAlmacen(FEmpresa,
      Result.Lineas[Indice].CodigoAlmacen, False);
    FLecturas.Completar(FEmpresa, Result.Lineas[Indice], Coste);
    Result.Lineas[Indice].NumeroMovimiento :=
      Mover(Result, Result.Lineas[Indice], Indice + 1, False, Coste);
    if not Result.EsBajaSinLote then
      Result.Lineas[Indice].NumeroMovimientoDestino :=
        Mover(Result, Result.Lineas[Indice], Indice + 1, True, Coste);
    Insertar(Result, Result.Lineas[Indice], Indice + 1, False);
  end;
  if not Result.EsBajaSinLote then
  begin
    Result.Urgentes := FLecturas.Urgentes(Result);
    for Indice := 0 to High(Result.Urgentes) do
      Insertar(Result, Result.Urgentes[Indice],
        Length(Result.Lineas) + Indice + 1, True);
  end;
end;

function TRepositorioRetiradaLotes.Guardar(
  const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
var
  Error: string;
  Linea: TLineaRetiradaLote;
begin
  Error := ValidarOrdenRetirada(AOrden);
  if Error <> '' then
    raise Exception.Create(Error);
  if not SameText(AOrden.Empresa, FEmpresa) then
    raise Exception.Create(SErrorRetiradaAlmacen);
  if FAlmacenRestringido <> '' then
    for Linea in AOrden.Lineas do
      if not SameText(Linea.CodigoAlmacen, FAlmacenRestringido) then
        raise Exception.Create(SErrorRetiradaAlmacen);
  if (Length(AOrden.Id) <> 36) or FConexion.InTransaction then
    raise Exception.Create(STextoFinaliceLaOperacionActualAntesDeRetirarComun);
  FConexion.StartTransaction;
  try
    // La clave primaria arbitra también dos peticiones simultáneas.
    Result := Leer(AOrden.Id);
    if Result.Id <> '' then
    begin
      if not MismaSolicitudRetirada(AOrden, Result) then
        raise Exception.Create(SErrorRetiradaConflicto);
    end
    else
      Result := Registrar(AOrden);
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
end;

function TRepositorioRetiradaLotes.LeerLinea(ADatos: TUniQuery):
  TLineaRetiradaLote;
begin
  Result := Default(TLineaRetiradaLote);
  Result.CodigoArticulo := ADatos.FieldByName('CODIGO_ART_LRET').AsString;
  Result.CodigoSku := ADatos.FieldByName('CODIGO_UNIDAD_LRET').AsString;
  Result.Descripcion := ADatos.FieldByName('DESCRIPCION_LRET').AsString;
  Result.Lote := ADatos.FieldByName('LOTE_LRET').AsString;
  Result.FechaCaducidad :=
    ADatos.FieldByName('FECHA_CADUCIDAD_LRET').AsDateTime;
  Result.Cantidad := ADatos.FieldByName('CANTIDAD_LRET').AsFloat;
  Result.CodigoAlmacen := ADatos.FieldByName('CODIGO_ALM_LRET').AsString;
  Result.Ubicacion := ADatos.FieldByName('UBICACION_LRET').AsString;
  Result.NumeroMovimiento := ADatos.FieldByName('NUMERO_MOV_LRET').AsString;
  Result.NumeroMovimientoDestino :=
    ADatos.FieldByName('NUMERO_MOV_DESTINO_LRET').AsString;
end;

procedure TRepositorioRetiradaLotes.LeerCabecera(ADatos: TUniQuery;
  var AOrden: TOrdenRetiradaLotes);
begin
  AOrden.Id := ADatos.FieldByName('ID_LRET').AsString;
  AOrden.Instante := ADatos.FieldByName('INSTANTE_LRET').AsDateTime;
  AOrden.EsUrgente := ADatos.FieldByName('ESURGENTE_LRET').AsString = 'S';
  AOrden.EsBajaSinLote := ADatos.FieldByName('DESTINO_LRET').AsString = 'BAJA';
  AOrden.Empresa := ADatos.FieldByName('CODIGO_EMP_LRET').AsString;
  AOrden.Empleado := ADatos.FieldByName('EMPLEADO_LRET').AsString;
  AOrden.Usuario := ADatos.FieldByName('USUARIO_ALTA').AsString;
  AOrden.Motivo := TMotivoRetiradaLote(
    ADatos.FieldByName('MOTIVO_LRET').AsInteger);
  AOrden.AlmacenDestino :=
    ADatos.FieldByName('CODIGO_ALM_DESTINO_LRET').AsString;
end;

function TRepositorioRetiradaLotes.Leer(const AId: string):
  TOrdenRetiradaLotes;
const
  CAMPOS = 'ID_LRET, INSTANTE_LRET, ESURGENTE_LRET, CODIGO_EMP_LRET, ' +
    'EMPLEADO_LRET, USUARIO_ALTA, MOTIVO_LRET, DESTINO_LRET, ' +
    'CODIGO_ALM_DESTINO_LRET, ' +
    'CODIGO_ART_LRET, CODIGO_UNIDAD_LRET, DESCRIPCION_LRET, LOTE_LRET, ' +
    'FECHA_CADUCIDAD_LRET, CANTIDAD_LRET, CODIGO_ALM_LRET, UBICACION_LRET, ' +
    'NUMERO_MOV_LRET, NUMERO_MOV_DESTINO_LRET, ESADICIONAL_LRET';
var
  Datos: TUniQuery;
  Linea: TLineaRetiradaLote;
begin
  Result := Default(TOrdenRetiradaLotes);
  Datos := FLecturas.Consulta('SELECT ' + CAMPOS +
    ' FROM fza_lotes_retiradas WHERE ID_LRET = :ID ' +
    'AND CODIGO_EMP_LRET = :EMP ORDER BY LINEA_LRET');
  try
    Datos.ParamByName('ID').AsString := AId;
    Datos.ParamByName('EMP').AsString := FEmpresa;
    Datos.Open;
    if not Datos.IsEmpty then
      LeerCabecera(Datos, Result);
    while not Datos.Eof do
    begin
      Linea := LeerLinea(Datos);
      if Datos.FieldByName('ESADICIONAL_LRET').AsString = 'S' then
        Result.Urgentes := Result.Urgentes + [Linea]
      else
        Result.Lineas := Result.Lineas + [Linea];
      Datos.Next;
    end;
  finally
    Datos.Free;
  end;
end;

function TRepositorioRetiradaLotes.LeerPorMovimiento(const ANumero: string):
  TOrdenRetiradaLotes;
var
  Datos: TUniQuery;
  Id: string;
begin
  Datos := FLecturas.Consulta('SELECT ID_LRET FROM fza_lotes_retiradas ' +
    'WHERE CODIGO_EMP_LRET = :EMP AND ' +
    '(NUMERO_MOV_LRET = :MOV OR NUMERO_MOV_DESTINO_LRET = :MOV) LIMIT 1');
  try
    Datos.ParamByName('EMP').AsString := FEmpresa;
    Datos.ParamByName('MOV').AsString := ANumero;
    Datos.Open;
    Id := Datos.FieldByName('ID_LRET').AsString;
  finally
    Datos.Free;
  end;
  Result := Leer(Id);
  if Result.Id = '' then
    raise Exception.Create(SErrorRetiradaSinRegistro);
end;

end.

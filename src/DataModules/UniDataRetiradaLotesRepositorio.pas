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
  Uni, inLibRetiradaLotesIntf, UniDataRetiradaLotesLecturas;

type
  TRepositorioRetiradaLotes = class(TInterfacedObject,
    IRepositorioRetiradaLotes)
  private
    FConexion: TUniConnection;
    FEmpresa: string;
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
    constructor Create(AConexion: TUniConnection; const AEmpresa: string);
    destructor Destroy; override;
    function Guardar(const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
    function Leer(const AId: string): TOrdenRetiradaLotes;
    function LeerPorMovimiento(const ANumero: string): TOrdenRetiradaLotes;
    function AlmacenesTaras(const AEmpresa: string):
      TArray<TAlmacenRetiradaLotes>;
  end;

implementation

uses
  System.SysUtils, System.Classes, Data.DB,
  inLibRetiradaLotes, inLibMsgRetiradaLotes,
  UniDataValoresAutomaticosRepositorio;

constructor TRepositorioRetiradaLotes.Create(AConexion: TUniConnection;
  const AEmpresa: string);
begin
  inherited Create;
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FLecturas := TLecturasRetiradaLotes.Create(AConexion);
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
    ':NUM, ''TR'', ''RL'', :DOC, :LIN, :EMP, :ALM, :CONTRA, :SKU, ' +
    ':TIPO, :CANT, :PMP, :COSTE, :USR, :ORIGEN, '''', '''', '''', ' +
    ':ART, :LOTE, :FECHA)');
  try
    Datos.ParamByName('NUM').AsString := Result;
    Datos.ParamByName('DOC').AsString := Copy(AOrden.Id, 1, 20);
    Datos.ParamByName('LIN').AsString := IntToStr(AIndice);
    Datos.ParamByName('EMP').AsString := AOrden.Empresa;
    Datos.ParamByName('ALM').AsString := Almacen;
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
    '''TARAS'', :DEST, :ART, :SKU, :DESCR, :LOTE, :FECHA, :CANT, :ALM, ' +
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
  FLecturas.ValidarAlmacen(FEmpresa, Result.AlmacenDestino, True);
  for Indice := 0 to High(Result.Lineas) do
  begin
    FLecturas.ValidarAlmacen(FEmpresa,
      Result.Lineas[Indice].CodigoAlmacen, False);
    FLecturas.Completar(FEmpresa, Result.Lineas[Indice], Coste);
    Result.Lineas[Indice].NumeroMovimiento :=
      Mover(Result, Result.Lineas[Indice], Indice + 1, False, Coste);
    Result.Lineas[Indice].NumeroMovimientoDestino :=
      Mover(Result, Result.Lineas[Indice], Indice + 1, True, Coste);
    Insertar(Result, Result.Lineas[Indice], Indice + 1, False);
  end;
  Result.Urgentes := FLecturas.Urgentes(Result);
  for Indice := 0 to High(Result.Urgentes) do
    Insertar(Result, Result.Urgentes[Indice],
      Length(Result.Lineas) + Indice + 1, True);
end;

function TRepositorioRetiradaLotes.Guardar(
  const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
var
  Error: string;
begin
  Error := ValidarOrdenRetirada(AOrden);
  if Error <> '' then
    raise Exception.Create(Error);
  if not SameText(AOrden.Empresa, FEmpresa) then
    raise Exception.Create(SErrorRetiradaAlmacen);
  if (Length(AOrden.Id) <> 36) or FConexion.InTransaction then
    raise Exception.Create('Finalice la operación actual antes de retirar.');
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
    'EMPLEADO_LRET, USUARIO_ALTA, MOTIVO_LRET, CODIGO_ALM_DESTINO_LRET, ' +
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

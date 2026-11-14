{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLotesRepositorio                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    IRepositorioLotes sobre los procedimientos PRC_FZA_LOTES_* de             }
{    F-LOTEC-006: catálogo de lotes y series, existencias por lote,            }
{    validación de salidas, histórico y búsqueda de series.                   }
{******************************************************************************}
unit UniDataLotesRepositorio;

interface

uses
  System.SysUtils, Uni, inLibLotesPersistenciaIntf;

type
  // Un procedimiento ha devuelto un código que este adaptador no conoce:
  // la BBDD y el programa no van a la par.
  ERepositorioLotes = class(Exception);

function CrearRepositorioLotesUniDAC(
  AConexion: TUniConnection): IRepositorioLotes;
function CrearConsultaLotesArticuloUniDAC(
  AConexion: TUniConnection): IConsultaLotesArticulo;
function CrearLecturaTrazabilidadArticuloUniDAC(
  AConexion: TUniConnection): ILecturaTrazabilidadArticulo;

implementation

uses
  Data.DB, inLibTrazabilidad, inLibMsgTrazabilidad;

const
  PROC_ASEGURAR = 'PRC_FZA_LOTES_ASEGURAR';
  PROC_VALIDAR_SALIDA = 'PRC_FZA_LOTES_VALIDAR_SALIDA';
  SQL_DISPONIBLES = 'CALL PRC_FZA_LOTES_DISPONIBLES(:SKU, :ALMACEN)';
  SQL_HISTORICO = 'CALL PRC_FZA_LOTES_HISTORICO(:SKU, :LOTE)';
  SQL_BUSCAR = 'CALL PRC_FZA_LOTES_BUSCAR(:LOTE)';
  SQL_LOTES_ARTICULO =
    'SELECT l.CODIGO_UNIDAD_LOT, l.LOTE_LOT, l.TIPO_LOT, ' +
    'l.FECHA_CADUCIDAD_LOT, l.FECHA_ENTRADA_LOT, l.ESACTIVO_LOT, ' +
    's.CODIGO_ALM_STK, s.CANTIDAD_STK ' +
    'FROM fza_articulos_lotes l ' +
    'JOIN fza_articulos_skus k ON k.CODIGO_UNIDAD_SKU = l.CODIGO_UNIDAD_LOT ' +
    'LEFT JOIN fza_articulos_stockactual s ' +
    'ON s.CODIGO_UNIDAD_STK = l.CODIGO_UNIDAD_LOT ' +
    'AND s.LOTE_STK = l.LOTE_LOT AND s.CANTIDAD_STK <> 0 ' +
    'WHERE k.CODIGO_ART_SKU = :ART ' +
    'ORDER BY l.FECHA_CADUCIDAD_LOT IS NULL, l.FECHA_CADUCIDAD_LOT, ' +
    'l.LOTE_LOT, l.CODIGO_UNIDAD_LOT, s.CODIGO_ALM_STK';
  SQL_TRAZABILIDAD_ARTICULO =
    'SELECT TIPO_TRAZABILIDAD_ART, ESCADUCIDAD_ART, ' +
    'DIAS_AVISO_CADUCIDAD_ART FROM fza_articulos ' +
    'WHERE CODIGO_ART_ART = :ART';
  SQL_SKUS_ARTICULO =
    'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :ART AND COALESCE(ESACTIVO_SKU, ''S'') = ''S'' ' +
    'ORDER BY CODIGO_UNIDAD_SKU';

  RESULTADO_CREADO = 'CREADO';
  RESULTADO_ACTUALIZADO = 'ACTUALIZADO';
  RESULTADO_SERIE_OTRO_ARTICULO = 'SERIE_OTRO_ARTICULO';
  RESULTADO_SERIE_EN_STOCK = 'SERIE_EN_STOCK';
  RESULTADO_OK = 'OK';
  RESULTADO_INEXISTENTE = 'INEXISTENTE';
  RESULTADO_SIN_STOCK = 'SIN_STOCK';
  RESULTADO_CANTIDAD_SERIE = 'CANTIDAD_SERIE';

  VALOR_SI = 'S';

type
  TRepositorioLotesUniDAC = class(TInterfacedObject, IRepositorioLotes)
  private
    FConexion: TUniConnection;
    function CrearProcedimiento(const ANombre: string): TUniStoredProc;
    function AbrirConsulta(const ASql: string): TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarLote(const ACodigoSku, ALote: string;
      out ACatalogo: TLoteCatalogo): Boolean;
    function Asegurar(
      const ALote: TLoteCatalogo;
      const AUsuario: string): TResultadoAsegurarLote;
    function Disponibles(
      const ACodigoSku, ACodigoAlmacen: string): TLotesDisponibles;
    function ValidarSalida(
      const ACodigoSku, ACodigoAlmacen, ALote: string;
      const ACantidad: Double): TValidacionSalidaLote;
    function Historico(
      const ACodigoSku, ALote: string): TArray<TMovimientoLote>;
    function BuscarSerie(
      const ASerie: string;
      out AUbicacion: TUbicacionSerie): Boolean;
  end;

  TConsultaLotesArticuloUniDAC = class(TInterfacedObject,
    IConsultaLotesArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Lotes(const ACodigoArticulo: string): TArray<TLoteArticulo>;
    function Skus(const ACodigoArticulo: string): TArray<string>;
  end;

  TLecturaTrazabilidadArticuloUniDAC = class(TInterfacedObject,
    ILecturaTrazabilidadArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Leer(const ACodigoArticulo: string): TTrazabilidadArticulo;
    function LotesOtrasLineas(const ATabla, ACampoSerie, ACampoNumero,
      ACampoLinea, ACampoLote, ASerie, ANumero, ALinea: string):
      TArray<string>;
  end;

function CrearRepositorioLotesUniDAC(
  AConexion: TUniConnection): IRepositorioLotes;
begin
  Result := TRepositorioLotesUniDAC.Create(AConexion);
end;

function CrearLecturaTrazabilidadArticuloUniDAC(
  AConexion: TUniConnection): ILecturaTrazabilidadArticulo;
begin
  Result := TLecturaTrazabilidadArticuloUniDAC.Create(AConexion);
end;

function CrearConsultaLotesArticuloUniDAC(
  AConexion: TUniConnection): IConsultaLotesArticulo;
begin
  Result := TConsultaLotesArticuloUniDAC.Create(AConexion);
end;

procedure ErrorResultado(const AProcedimiento, ACodigo: string);
begin
  raise ERepositorioLotes.CreateFmt(SErrorResultadoProcedimientoLotes,
                                    [AProcedimiento, ACodigo]);
end;

function ResultadoAsegurar(const ACodigo: string): TResultadoAsegurarLote;
begin
  Result := ralCreado;
  if ACodigo = RESULTADO_ACTUALIZADO then
    Result := ralActualizado
  else if ACodigo = RESULTADO_SERIE_OTRO_ARTICULO then
    Result := ralSerieEnOtroArticulo
  else if ACodigo = RESULTADO_SERIE_EN_STOCK then
    Result := ralSerieYaEnStock
  else if ACodigo <> RESULTADO_CREADO then
    ErrorResultado(PROC_ASEGURAR, ACodigo);
end;

function ResultadoSalida(const ACodigo: string): TResultadoSalidaLote;
begin
  Result := rslCorrecta;
  if ACodigo = RESULTADO_INEXISTENTE then
    Result := rslLoteInexistente
  else if ACodigo = RESULTADO_SIN_STOCK then
    Result := rslSinStockSuficiente
  else if ACodigo = RESULTADO_CANTIDAD_SERIE then
    Result := rslCantidadSerie
  else if ACodigo <> RESULTADO_OK then
    ErrorResultado(PROC_VALIDAR_SALIDA, ACodigo);
end;

function FechaCampo(AField: TField): TDate;
begin
  if AField.IsNull then
    Result := SIN_FECHA
  else
    Result := Trunc(AField.AsDateTime);
end;

procedure PonerFecha(AParam: TUniParam; AFecha: TDate);
begin
  if AFecha = SIN_FECHA then
    AParam.Clear
  else
    AParam.AsDate := AFecha;
end;

procedure PonerTexto(AParam: TUniParam; const ATexto: string);
begin
  // Vacío = NULL: los procedimientos lo entienden como «no viene».
  if ATexto = '' then
    AParam.Clear
  else
    AParam.AsString := ATexto;
end;

constructor TRepositorioLotesUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioLotesUniDAC.CrearProcedimiento(
  const ANombre: string): TUniStoredProc;
begin
  Result := TUniStoredProc.Create(nil);
  Result.Connection := FConexion;
  Result.StoredProcName := ANombre;
  Result.Params.Clear;
end;

function TRepositorioLotesUniDAC.AbrirConsulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TRepositorioLotesUniDAC.Asegurar(
  const ALote: TLoteCatalogo;
  const AUsuario: string): TResultadoAsegurarLote;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := CrearProcedimiento(PROC_ASEGURAR);
  try
    oProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_LOTE', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_TIPO_LOT', ptInput);
    oProcedimiento.Params.CreateParam(ftDate, 'p_FECHA_CADUCIDAD', ptInput);
    oProcedimiento.Params.CreateParam(ftDate, 'p_FECHA_ENTRADA', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_PRV', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_TIPO_DOC', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_SERIE_DOC', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_NUMERO_DOC', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_COMPROBAR_STOCK', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_RESULTADO', ptOutput);
    oProcedimiento.ParamByName('p_CODIGO_UNIDAD').AsString := ALote.CodigoSku;
    oProcedimiento.ParamByName('p_LOTE').AsString := NormalizarLote(
                                                       ALote.Lote);
    // NINGUNA → NULL: el procedimiento toma el modo del artículo.
    PonerTexto(oProcedimiento.ParamByName('p_TIPO_LOT'),
               TipoCatalogoDeModo(ALote.Modo));
    PonerFecha(oProcedimiento.ParamByName('p_FECHA_CADUCIDAD'),
               ALote.FechaCaducidad);
    PonerFecha(oProcedimiento.ParamByName('p_FECHA_ENTRADA'),
               ALote.FechaEntrada);
    PonerTexto(oProcedimiento.ParamByName('p_CODIGO_PRV'),
               ALote.CodigoProveedor);
    PonerTexto(oProcedimiento.ParamByName('p_TIPO_DOC'),
               ALote.TipoDocumentoOrigen);
    PonerTexto(oProcedimiento.ParamByName('p_SERIE_DOC'),
               ALote.SerieDocumentoOrigen);
    PonerTexto(oProcedimiento.ParamByName('p_NUMERO_DOC'),
               ALote.NumeroDocumentoOrigen);
    oProcedimiento.ParamByName('p_COMPROBAR_STOCK').AsString := VALOR_SI;
    oProcedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    oProcedimiento.ExecProc;
    Result := ResultadoAsegurar(
      oProcedimiento.ParamByName('p_RESULTADO').AsString);
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function TRepositorioLotesUniDAC.Disponibles(
  const ACodigoSku, ACodigoAlmacen: string): TLotesDisponibles;
var
  oConsulta: TUniQuery;
  rLote: TLoteDisponible;
begin
  Result := [];
  oConsulta := AbrirConsulta(SQL_DISPONIBLES);
  try
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.ParamByName('ALMACEN').AsString := ACodigoAlmacen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rLote.Lote := oConsulta.FieldByName('LOTE_STK').AsString;
      rLote.FechaCaducidad := FechaCampo(
        oConsulta.FieldByName('FECHA_CADUCIDAD'));
      rLote.FechaEntrada := FechaCampo(
        oConsulta.FieldByName('FECHA_ENTRADA_LOT'));
      rLote.Cantidad := oConsulta.FieldByName('CANTIDAD').AsFloat;
      Result := Result + [rLote];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioLotesUniDAC.ValidarSalida(
  const ACodigoSku, ACodigoAlmacen, ALote: string;
  const ACantidad: Double): TValidacionSalidaLote;
var
  oProcedimiento: TUniStoredProc;
begin
  Result := Default(TValidacionSalidaLote);
  oProcedimiento := CrearProcedimiento(PROC_VALIDAR_SALIDA);
  try
    oProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_LOTE', ptInput);
    oProcedimiento.Params.CreateParam(ftFloat, 'p_CANTIDAD', ptInput);
    oProcedimiento.Params.CreateParam(ftString, 'p_RESULTADO', ptOutput);
    oProcedimiento.Params.CreateParam(ftString, 'p_ESCADUCADO', ptOutput);
    oProcedimiento.Params.CreateParam(ftFloat, 'p_STOCK', ptOutput);
    oProcedimiento.Params.CreateParam(ftDate, 'p_FECHA_CADUCIDAD', ptOutput);
    oProcedimiento.ParamByName('p_CODIGO_UNIDAD').AsString := ACodigoSku;
    oProcedimiento.ParamByName('p_CODIGO_ALMACEN').AsString :=
      ACodigoAlmacen;
    oProcedimiento.ParamByName('p_LOTE').AsString := NormalizarLote(ALote);
    oProcedimiento.ParamByName('p_CANTIDAD').AsFloat := ACantidad;
    oProcedimiento.ExecProc;
    Result.Resultado := ResultadoSalida(
      oProcedimiento.ParamByName('p_RESULTADO').AsString);
    Result.EsCaducado :=
      oProcedimiento.ParamByName('p_ESCADUCADO').AsString = VALOR_SI;
    Result.StockDisponible := oProcedimiento.ParamByName('p_STOCK').AsFloat;
    if not oProcedimiento.ParamByName('p_FECHA_CADUCIDAD').IsNull then
      Result.FechaCaducidad := Trunc(
        oProcedimiento.ParamByName('p_FECHA_CADUCIDAD').AsDateTime);
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function TRepositorioLotesUniDAC.Historico(
  const ACodigoSku, ALote: string): TArray<TMovimientoLote>;
var
  oConsulta: TUniQuery;
  rMovimiento: TMovimientoLote;
begin
  Result := [];
  oConsulta := AbrirConsulta(SQL_HISTORICO);
  try
    PonerTexto(oConsulta.ParamByName('SKU'), ACodigoSku);
    oConsulta.ParamByName('LOTE').AsString := NormalizarLote(ALote);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rMovimiento.NumeroMovimiento :=
        oConsulta.FieldByName('NUMERO_MOV').AsString;
      rMovimiento.Fecha := oConsulta.FieldByName('FECHA_MOV').AsDateTime;
      rMovimiento.TipoDocumento :=
        oConsulta.FieldByName('TIPO_DOC_MOV').AsString;
      rMovimiento.SerieDocumento :=
        oConsulta.FieldByName('SERIE_DOC_MOV').AsString;
      rMovimiento.NumeroDocumento :=
        oConsulta.FieldByName('NUMERO_DOC_MOV').AsString;
      rMovimiento.Linea := oConsulta.FieldByName('LINEA_MOV').AsInteger;
      rMovimiento.CodigoSku :=
        oConsulta.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      rMovimiento.CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART_MOV').AsString;
      rMovimiento.CodigoAlmacen :=
        oConsulta.FieldByName('CODIGO_ALM_MOV').AsString;
      rMovimiento.CodigoAlmacenContra :=
        oConsulta.FieldByName('CODIGO_ALM_CONTRA_MOV').AsString;
      rMovimiento.TipoMovimiento := oConsulta.FieldByName('TIPO_MOV').AsString;
      rMovimiento.Cantidad := oConsulta.FieldByName('CANTIDAD_MOV').AsFloat;
      rMovimiento.FechaCaducidad := FechaCampo(
        oConsulta.FieldByName('FECHA_CADUCIDAD_MOV'));
      rMovimiento.CodigoCliente :=
        oConsulta.FieldByName('CODIGO_CLI_MOV').AsString;
      rMovimiento.RazonSocialCliente :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      rMovimiento.CodigoProveedor :=
        oConsulta.FieldByName('CODIGO_PRV').AsString;
      rMovimiento.NombreProveedor :=
        oConsulta.FieldByName('NOMBRE_PRV').AsString;
      Result := Result + [rMovimiento];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerCatalogo(AConsulta: TUniQuery): TLoteCatalogo;
begin
  Result := Default(TLoteCatalogo);
  Result.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString;
  Result.Modo := ModoDeTipoCatalogo(
    AConsulta.FieldByName('TIPO_LOT').AsString);
  Result.FechaCaducidad := FechaCampo(
    AConsulta.FieldByName('FECHA_CADUCIDAD_LOT'));
  Result.FechaEntrada := FechaCampo(
    AConsulta.FieldByName('FECHA_ENTRADA_LOT'));
  Result.CodigoProveedor := AConsulta.FieldByName('CODIGO_PRV_LOT').AsString;
  Result.TipoDocumentoOrigen :=
    AConsulta.FieldByName('TIPO_DOC_ORIGEN_LOT').AsString;
  Result.SerieDocumentoOrigen :=
    AConsulta.FieldByName('SERIE_DOC_ORIGEN_LOT').AsString;
  Result.NumeroDocumentoOrigen :=
    AConsulta.FieldByName('NUMERO_DOC_ORIGEN_LOT').AsString;
  Result.EsActivo :=
    AConsulta.FieldByName('ESACTIVO_LOT').AsString <> 'N';
end;

function TRepositorioLotesUniDAC.BuscarLote(
  const ACodigoSku, ALote: string; out ACatalogo: TLoteCatalogo): Boolean;
var
  oConsulta: TUniQuery;
begin
  ACatalogo := Default(TLoteCatalogo);
  oConsulta := AbrirConsulta(
    'SELECT CODIGO_UNIDAD_LOT, TIPO_LOT, FECHA_CADUCIDAD_LOT, ' +
    'FECHA_ENTRADA_LOT, CODIGO_PRV_LOT, TIPO_DOC_ORIGEN_LOT, ' +
    'SERIE_DOC_ORIGEN_LOT, NUMERO_DOC_ORIGEN_LOT, ESACTIVO_LOT ' +
    'FROM fza_articulos_lotes ' +
    'WHERE CODIGO_UNIDAD_LOT = :SKU AND LOTE_LOT = :LOTE');
  try
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.ParamByName('LOTE').AsString := NormalizarLote(ALote);
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      ACatalogo := LeerCatalogo(oConsulta);
      ACatalogo.Lote := NormalizarLote(ALote);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioLotesUniDAC.BuscarSerie(
  const ASerie: string;
  out AUbicacion: TUbicacionSerie): Boolean;
var
  oConsulta: TUniQuery;
begin
  // El procedimiento busca cualquier lote con ese código; aquí solo
  // cuentan las filas de serie (TIPO_LOT = 'S'). Una fila por almacén con
  // stock (o una sin almacén): manda la que tiene existencias.
  Result := False;
  AUbicacion := Default(TUbicacionSerie);
  oConsulta := AbrirConsulta(SQL_BUSCAR);
  try
    oConsulta.ParamByName('LOTE').AsString := NormalizarLote(ASerie);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if (oConsulta.FieldByName('TIPO_LOT').AsString = TIPO_CATALOGO_SERIE)
         and ((not Result) or
              (oConsulta.FieldByName('CANTIDAD_STK').AsFloat > 0)) then
      begin
        Result := True;
        AUbicacion.Catalogo := LeerCatalogo(oConsulta);
        AUbicacion.Catalogo.Lote := NormalizarLote(ASerie);
        AUbicacion.CodigoArticulo :=
          oConsulta.FieldByName('CODIGO_ART_SKU').AsString;
        AUbicacion.DescripcionArticulo :=
          oConsulta.FieldByName('DESCRIPCION_ART').AsString;
        AUbicacion.Stock := oConsulta.FieldByName('CANTIDAD_STK').AsFloat;
        if AUbicacion.Stock > 0 then
          AUbicacion.CodigoAlmacen :=
            oConsulta.FieldByName('CODIGO_ALM_STK').AsString
        else
          AUbicacion.CodigoAlmacen := '';
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

{ TLecturaTrazabilidadArticuloUniDAC }

constructor TLecturaTrazabilidadArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLecturaTrazabilidadArticuloUniDAC.Leer(
  const ACodigoArticulo: string): TTrazabilidadArticulo;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TTrazabilidadArticulo);
  Result.DiasAviso := DIAS_AVISO_SIN_VALOR;
  if Trim(ACodigoArticulo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_TRAZABILIDAD_ARTICULO;
      oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result.Modo := ModoDesdeCadena(
          oConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString);
        Result.EsCaducidadObligatoria :=
          oConsulta.FieldByName('ESCADUCIDAD_ART').AsString = VALOR_SI;
        if not oConsulta.FieldByName('DIAS_AVISO_CADUCIDAD_ART').IsNull then
          Result.DiasAviso :=
            oConsulta.FieldByName('DIAS_AVISO_CADUCIDAD_ART').AsInteger;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturaTrazabilidadArticuloUniDAC.LotesOtrasLineas(const ATabla,
  ACampoSerie, ACampoNumero, ACampoLinea, ACampoLote, ASerie, ANumero,
  ALinea: string): TArray<string>;
var
  oConsulta: TUniQuery;
begin
  Result := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ' + ACampoLote + ' AS LOTE FROM ' + ATabla +
      ' WHERE ' + ACampoSerie + ' = :SERIE AND ' + ACampoNumero +
      ' = :NUMERO AND ' + ACampoLinea + ' <> :LINEA AND ' +
      'COALESCE(' + ACampoLote + ', '''') <> ''''';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('LINEA').AsString := ALinea;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [oConsulta.FieldByName('LOTE').AsString];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

{ TConsultaLotesArticuloUniDAC }

constructor TConsultaLotesArticuloUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TConsultaLotesArticuloUniDAC.Lotes(
  const ACodigoArticulo: string): TArray<TLoteArticulo>;
var
  oConsulta: TUniQuery;
  rLote: TLoteArticulo;
begin
  Result := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LOTES_ARTICULO;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rLote.CodigoSku := oConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString;
      rLote.Lote := oConsulta.FieldByName('LOTE_LOT').AsString;
      rLote.Modo := ModoDeTipoCatalogo(
        oConsulta.FieldByName('TIPO_LOT').AsString);
      rLote.FechaCaducidad := FechaCampo(
        oConsulta.FieldByName('FECHA_CADUCIDAD_LOT'));
      rLote.FechaEntrada := FechaCampo(
        oConsulta.FieldByName('FECHA_ENTRADA_LOT'));
      rLote.EsActivo :=
        oConsulta.FieldByName('ESACTIVO_LOT').AsString <> 'N';
      rLote.CodigoAlmacen := oConsulta.FieldByName('CODIGO_ALM_STK').AsString;
      rLote.Stock := oConsulta.FieldByName('CANTIDAD_STK').AsFloat;
      Result := Result + [rLote];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TConsultaLotesArticuloUniDAC.Skus(
  const ACodigoArticulo: string): TArray<string>;
var
  oConsulta: TUniQuery;
begin
  Result := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_SKUS_ARTICULO;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

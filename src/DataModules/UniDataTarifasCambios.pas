{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifasCambios                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de sesiones de cambios de tarifa.                             }
{    Calcula lineas pendientes y aplica los precios a fza_articulos_tarifas.   }
{******************************************************************************}
unit UniDataTarifasCambios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibTarifasCambiosExcel;

type
  TdmTarifasCambios = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FAjustandoPrecios: Boolean;
    function  CampoCabecera(const ACampo: string): TField;
    function  LeerFloatLinea(const ACampo: string): Double;
    function  PrecioBaseLinea(const ACampoOrigen: string): Double;
    function  CalcularImporte(AImporteBase: Double;
                              const ATipoAplicacion: string;
                              AValorAplicacion: Double): Double;
    function  RedondearImporte(AImporte: Double;
                               AValorRedondeo: Double;
                               AValorMenos: Double;
                               EsRedondearArriba: Boolean): Double;
    procedure ConfigurarConsultasAplicacion(
      AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
    function AplicarLineaTarifa(
      AConsultaBusca, AConsultaExec, AConsultaMarca,
      AConsultaUnico: TUniQuery;
      out AEncoloPrestaShop: Boolean): Boolean;
    procedure MarcarSesionAplicada(AConsulta: TUniQuery);
    procedure ConfigurarQueries;
    procedure GrabarLineaPendiente;
    procedure AsignarParametrosLineaExcel(AConsulta: TUniQuery;
      const ALinea: TLineaSesionTarifaExcel);
    procedure CompletarDescuentoLineaExcel(AConsulta: TUniQuery;
      const ALinea: TLineaSesionTarifaExcel);
    procedure unqryLineasAfterOpen(DataSet: TDataSet);
    procedure CampoPrecioNuevoChange(Sender: TField);
    function  RedondearConCabecera(AImporte: Double): Double;
    function  SalidaParaDescuento: Double;
    procedure CalcularDescuento(ASalida, APorcentaje: Double;
      out AFinal, ADto, APorcentajeReal: Double);
    procedure GrabarDescuentos(const APorLinea: TDictionary<Integer, Double>);
    procedure AplicarPorcentajesExcel(const ALineas: TLineasSesionTarifaExcel);
  public
    unqryLineas  : TUniQuery;
    dsLineas     : TDataSource;
    unqryTarifas : TUniQuery;
    dsTarifas    : TDataSource;
    procedure RellenarPreciosPartida;
    procedure ImportarLineasExcel(const ALineas: TLineasSesionTarifaExcel;
      out ANuevas, AActualizadas: Integer);
    procedure AbrirDetalles; override;
    procedure AplicarDescuentoLote(const AIdsLinea: TArray<Integer>;
      APorcentaje: Double);
    function  LineasSinPrecioNuevo: Integer;
    function RecalcularSesionActual(const AIdsLinea: TArray<Integer>;
      out AMensaje: string): Integer;
    function  AplicarSesionActual(out AMensaje: string): Integer;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibUser, inLibMsgArticulos, UniDataPrestaShopEncolado,
  inLibPrestaShopColaSenal, inLibRedondeo;

{$R *.dfm}

resourcestring
  SErrorTarifasCambiosSinSesionActiva =
    'No hay ninguna sesion activa.';
  SErrorTarifasCambiosSesionSinLineas =
    'La sesion no tiene lineas.';
  SErrorTarifasCambiosSesionAplicada =
    'La sesion ya esta aplicada.';

const
  // Precio vigente de una tarifa para el articulo/SKU de la linea L.
  SQL_PRECIO_TARIFA_LINEA =
    '(SELECT T.%s FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = L.CODIGO_ART_TARCLIN ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = ' +
    'L.CODIGO_UNIDAD_SKU_TARCLIN ' +
    'AND T.CODIGO_TAR_ARTTAR = :%s AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1)';
  // Tarifa de la linea distinta de la de la cabecera.
  SQL_CAMBIO_TARIFA_ORIGEN =
    'NOT (L.CODIGO_TAR_ORIGEN_TARCLIN <=> :TAR_ORIG)';
  SQL_CAMBIO_TARIFA_DESTINO =
    'NOT (L.CODIGO_TAR_DESTINO_TARCLIN <=> :TAR_DEST)';
  // Ultimo precio de compra: proveedor principal o, si no hay, cualquiera.
  SQL_COSTE_LINEA =
    '(SELECT AP.PRECIO_ULT_COMPRA_AP FROM fza_articulos_proveedores AP ' +
    'WHERE AP.CODIGO_ART_AP = L.CODIGO_ART_TARCLIN ' +
    'ORDER BY AP.ESPROVEEDORPRINCIPAL_AP = ''S'' DESC LIMIT 1)';
  // Salida nueva de partida para un descuento: la calculada, si no la
  // actual de la tarifa destino y, si tampoco, la de origen.
  SQL_BASE_SALIDA_NUEVA =
    'COALESCE(NULLIF(PRECIO_NUEVO_TARCLIN, 0), ' +
    'NULLIF(PRECIO_SALIDA_ACTUAL_TARCLIN, 0), PRECIO_ORIGEN_TARCLIN)';
  // Descuento a partir del precio final ya grabado en la linea. En un
  // UPDATE de una tabla las asignaciones usan los valores ya asignados.
  SQL_DESCUENTO_FINAL =
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'PRECIO_NUEVO_TARCLIN = ' + SQL_BASE_SALIDA_NUEVA + ', ' +
    'PRECIO_DTO_NUEVO_TARCLIN = GREATEST(PRECIO_NUEVO_TARCLIN - ' +
    '  PRECIO_FINAL_NUEVO_TARCLIN, 0), ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN = CASE WHEN PRECIO_NUEVO_TARCLIN > 0 ' +
    '  THEN ROUND(PRECIO_DTO_NUEVO_TARCLIN / PRECIO_NUEVO_TARCLIN * 100, 2) ' +
    '  ELSE 0 END, ' +
    'ESTADO_TARCLIN = ''PENDIENTE'', MENSAJE_TARCLIN = NULL, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() WHERE %s';
  SQL_FILTRO_ARTICULO_LINEA =
    'CODIGO_TARC_TARCLIN = :TARC AND CODIGO_ART_TARCLIN = :ART ' +
    'AND CODIGO_UNIDAD_SKU_TARCLIN = :SKU';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifasCambios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryLineas := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  unqryTarifas := TUniQuery.Create(Self);
  dsTarifas := TDataSource.Create(Self);
  dsTarifas.DataSet := unqryTarifas;
  ConfigurarQueries;
end;

procedure TdmTarifasCambios.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsLineas) then
    dsLineas.DataSet := nil;
  if Assigned(dsTarifas) then
    dsTarifas.DataSet := nil;
  if Assigned(unqryLineas) then
  begin
    if unqryLineas.Active then
      unqryLineas.Close;
    unqryLineas.MasterSource := nil;
    unqryLineas.MasterFields := '';
    unqryLineas.DetailFields := '';
  end;
  if Assigned(unqryTarifas) then
  begin
    if unqryTarifas.Active then
      unqryTarifas.Close;
  end;
  inherited;
end;

procedure TdmTarifasCambios.ConfigurarQueries;
begin
  unqryTablaG.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_tarifas_cambios ' +
    ' ORDER BY CODIGO_TARC DESC';
  unqryTablaG.KeyFields := 'CODIGO_TARC';
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryLineas.SQL.Text :=
    'SELECT L.*, A.DESCRIPCION_ART, A.CODIGO_FAM_ART, ' +
    '       F.NOMBRE_FAM_FAM, P.RAZON_SOCIAL_PRV ' +
    '  FROM fza_tarifas_cambios_lineas L ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TARCLIN ' +
    '  LEFT JOIN fza_articulos_familias F ' +
    '    ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_proveedores AP ' +
    '    ON AP.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '   AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '  LEFT JOIN fza_proveedores P ' +
    '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
    ' ORDER BY L.ID_TARCLIN';
  unqryLineas.KeyFields := 'ID_TARCLIN';
  unqryLineas.AfterOpen := unqryLineasAfterOpen;
  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    '  CODIGO_ART_TARCLIN = :CODIGO_ART_TARCLIN, ' +
    '  CODIGO_UNIDAD_SKU_TARCLIN = :CODIGO_UNIDAD_SKU_TARCLIN, ' +
    '  CODIGO_TAR_ORIGEN_TARCLIN = :CODIGO_TAR_ORIGEN_TARCLIN, ' +
    '  CODIGO_TAR_DESTINO_TARCLIN = :CODIGO_TAR_DESTINO_TARCLIN, ' +
    '  ESAPLICAR_TARCLIN = :ESAPLICAR_TARCLIN, ' +
    '  PRECIO_ORIGEN_TARCLIN = :PRECIO_ORIGEN_TARCLIN, ' +
    '  PRECIO_COSTE_TARCLIN = :PRECIO_COSTE_TARCLIN, ' +
    '  PRECIO_SALIDA_ACTUAL_TARCLIN = :PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    '  PRECIO_FINAL_ACTUAL_TARCLIN = :PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    '  PRECIO_DTO_ACTUAL_TARCLIN = :PRECIO_DTO_ACTUAL_TARCLIN, ' +
    '  PORCENTAJE_DTO_ACTUAL_TARCLIN = :PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    '  PRECIO_NUEVO_TARCLIN = :PRECIO_NUEVO_TARCLIN, ' +
    '  PRECIO_FINAL_NUEVO_TARCLIN = :PRECIO_FINAL_NUEVO_TARCLIN, ' +
    '  PRECIO_DTO_NUEVO_TARCLIN = :PRECIO_DTO_NUEVO_TARCLIN, ' +
    '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    '  ESTADO_TARCLIN = :ESTADO_TARCLIN, ' +
    '  MENSAJE_TARCLIN = :MENSAJE_TARCLIN, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF, ' +
    '  INSTANTE_MODIF = NOW() ' +
    'WHERE ID_TARCLIN = :Old_ID_TARCLIN';
  unqryTarifas.SQL.Text :=
    'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR ' +
    '  FROM fza_tarifas ' +
    ' WHERE ESACTIVO_ARTTAR = ''S'' ' +
    ' ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
end;

procedure TdmTarifasCambios.AbrirDetalles;
begin
  inherited;
  if not unqryTarifas.Active then
    unqryTarifas.Open;
  if not unqryLineas.Active then
    unqryLineas.Open;
end;

// Los campos son dinamicos: se recrean en cada apertura del detalle.
procedure TdmTarifasCambios.unqryLineasAfterOpen(DataSet: TDataSet);
begin
  DataSet.FieldByName('PRECIO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PRECIO_FINAL_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PRECIO_DTO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PORCENTAJE_DTO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
end;

// Edicion a mano de una linea, con el criterio comun:
// - % escrito o salida cambiada: el final sale del % con el redondeo de la
//   cabecera (como la formula y el descuento en lote);
// - final o importe de descuento escritos: se respetan tal cual.
// El % que queda es siempre el real (descuento / salida).
procedure TdmTarifasCambios.CampoPrecioNuevoChange(Sender: TField);
var
  dDto: Double;
  dFinal: Double;
  dPorc: Double;
  dSalida: Double;
  Lineas: TDataSet;
begin
  if not FAjustandoPrecios then
  begin
    FAjustandoPrecios := True;
    try
      Lineas := Sender.DataSet;
      dSalida := SalidaParaDescuento;
      if (dSalida > 0) and
         (LeerFloatLinea('PRECIO_NUEVO_TARCLIN') <= 0) then
        Lineas.FieldByName('PRECIO_NUEVO_TARCLIN').AsFloat := dSalida;
      dFinal := LeerFloatLinea('PRECIO_FINAL_NUEVO_TARCLIN');
      dDto := LeerFloatLinea('PRECIO_DTO_NUEVO_TARCLIN');
      if Sender.FieldName = 'PRECIO_DTO_NUEVO_TARCLIN' then
        dFinal := Max(dSalida - dDto, 0)
      else if Sender.FieldName <> 'PRECIO_FINAL_NUEVO_TARCLIN' then
        CalcularDescuento(dSalida,
          LeerFloatLinea('PORCENTAJE_DTO_NUEVO_TARCLIN'),
          dFinal, dDto, dPorc);
      dDto := Max(dSalida - dFinal, 0);
      dPorc := 0;
      if dSalida > 0 then
        dPorc := Round(dDto / dSalida * 100 * 100) / 100;
      if Sender.FieldName <> 'PRECIO_FINAL_NUEVO_TARCLIN' then
        Lineas.FieldByName('PRECIO_FINAL_NUEVO_TARCLIN').AsFloat := dFinal;
      if Sender.FieldName <> 'PRECIO_DTO_NUEVO_TARCLIN' then
        Lineas.FieldByName('PRECIO_DTO_NUEVO_TARCLIN').AsFloat := dDto;
      Lineas.FieldByName('PORCENTAJE_DTO_NUEVO_TARCLIN').AsFloat := dPorc;
      Lineas.FieldByName('ESTADO_TARCLIN').AsString := 'PENDIENTE';
    finally
      FAjustandoPrecios := False;
    end;
  end;
end;

procedure TdmTarifasCambios.AplicarDescuentoLote(
  const AIdsLinea: TArray<Integer>; APorcentaje: Double);
var
  iLinea: Integer;
  PorLinea: TDictionary<Integer, Double>;
begin
  GrabarLineaPendiente;
  PorLinea := TDictionary<Integer, Double>.Create;
  try
    for iLinea := 0 to High(AIdsLinea) do
      PorLinea.AddOrSetValue(AIdsLinea[iLinea], APorcentaje);
    GrabarDescuentos(PorLinea);
  finally
    FreeAndNil(PorLinea);
  end;
end;

// Lineas a aplicar que aun no tienen salida o final nuevo: aplicarlas
// dejaria el articulo a precio 0 en la tarifa destino.
function TdmTarifasCambios.LineasSinPrecioNuevo: Integer;
var
  qry: TUniQuery;
begin
  Result := 0;
  GrabarLineaPendiente;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas_cambios_lineas ' +
        'WHERE CODIGO_TARC_TARCLIN = :CODIGO AND ESAPLICAR_TARCLIN = ''S'' ' +
        'AND (COALESCE(PRECIO_NUEVO_TARCLIN, 0) <= 0 ' +
        '  OR COALESCE(PRECIO_FINAL_NUEVO_TARCLIN, 0) <= 0)';
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.Open;
      Result := qry.FieldByName('CANTIDAD').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmTarifasCambios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('NOMBRE_TARC').AsString :=
    'Sesion tarifas ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  DataSet.FieldByName('FECHA_TARC').AsDateTime := Date;
  DataSet.FieldByName('ESTADO_TARC').AsString := 'BORRADOR';
  DataSet.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString := 'PVP';
  DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString := 'PVP';
  DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
  DataSet.FieldByName('VALOR_APLICACION_TARC').AsFloat := 0;
  DataSet.FieldByName('VALOR_REDONDEO_TARC').AsFloat := 0.01;
  DataSet.FieldByName('VALOR_MENOS_AJUSTE_TARC').AsFloat := 0;
  DataSet.FieldByName('ESREDONDEAR_ARRIBA_TARC').AsString := 'S';
  DataSet.FieldByName('FECHA_DESDE_TARC').AsDateTime := Date;
end;

procedure TdmTarifasCambios.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(DataSet.FieldByName('NOMBRE_TARC').AsString) = '' then
    raise Exception.Create(SErrorNombreSesionCambioTarifaObligatorio);
  if Trim(DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString) = '' then
    raise Exception.Create(SErrorTarifaDestinoObligatoria);
  if Trim(DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  if Trim(DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  if Trim(DataSet.FieldByName('TIPO_APLICACION_TARC').AsString) = '' then
    DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
end;

function TdmTarifasCambios.CampoCabecera(const ACampo: string): TField;
begin
  Result := nil;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    Result := unqryTablaG.FieldByName(ACampo);
end;

function TdmTarifasCambios.LeerFloatLinea(const ACampo: string): Double;
begin
  Result := 0;
  if not unqryLineas.FieldByName(ACampo).IsNull then
    Result := unqryLineas.FieldByName(ACampo).AsFloat;
end;

function TdmTarifasCambios.PrecioBaseLinea(
  const ACampoOrigen: string): Double;
begin
  if SameText(ACampoOrigen, 'PRECIO_COSTE') then
    Result := LeerFloatLinea('PRECIO_COSTE_TARCLIN')
  else if SameText(ACampoOrigen, 'PRECIO_DESTINO_ACTUAL') then
    Result := LeerFloatLinea('PRECIO_FINAL_ACTUAL_TARCLIN')
  else
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

function TdmTarifasCambios.CalcularImporte(AImporteBase: Double;
  const ATipoAplicacion: string; AValorAplicacion: Double): Double;
begin
  if SameText(ATipoAplicacion, 'INCREMENTO_LINEAL') then
    Result := AImporteBase + AValorAplicacion
  else if SameText(ATipoAplicacion, 'INCREMENTO_PORCENTUAL') then
    Result := AImporteBase + (AImporteBase * AValorAplicacion / 100)
  else if SameText(ATipoAplicacion, 'PRECIO_FIJO') then
    Result := AValorAplicacion
  else
    Result := AImporteBase;
end;

function TdmTarifasCambios.RedondearImporte(AImporte: Double;
  AValorRedondeo: Double; AValorMenos: Double;
  EsRedondearArriba: Boolean): Double;
begin
  Result := AImporte;
  if AValorRedondeo > 0 then
  begin
    if EsRedondearArriba then
      Result := Ceil(Result / AValorRedondeo) * AValorRedondeo
    else
      Result := RedondearAMultiplo(Result, AValorRedondeo);
  end;
  Result := Result - AValorMenos;
  if Result < 0 then
    Result := 0;
  Result := RedondearACentimos(Result);
end;

// Criterio unico: todo precio que sale de un porcentaje (formula, descuento
// en lote, % del Excel o % escrito en la rejilla) se redondea igual.
function TdmTarifasCambios.RedondearConCabecera(AImporte: Double): Double;
begin
  Result := RedondearImporte(AImporte,
    CampoCabecera('VALOR_REDONDEO_TARC').AsFloat,
    CampoCabecera('VALOR_MENOS_AJUSTE_TARC').AsFloat,
    SameText(CampoCabecera('ESREDONDEAR_ARRIBA_TARC').AsString, 'S'));
end;

// Salida de partida de la linea actual: la nueva ya calculada; si no hay,
// la actual de la tarifa destino y, si tampoco, la de la tarifa origen.
function TdmTarifasCambios.SalidaParaDescuento: Double;
begin
  Result := LeerFloatLinea('PRECIO_NUEVO_TARCLIN');
  if Result <= 0 then
    Result := LeerFloatLinea('PRECIO_SALIDA_ACTUAL_TARCLIN');
  if Result <= 0 then
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

procedure TdmTarifasCambios.CalcularDescuento(ASalida, APorcentaje: Double;
  out AFinal, ADto, APorcentajeReal: Double);
begin
  AFinal := ASalida;
  if APorcentaje > 0 then
    AFinal := RedondearConCabecera(ASalida * (1 - APorcentaje / 100));
  ADto := Max(ASalida - AFinal, 0);
  APorcentajeReal := 0;
  if ASalida > 0 then
    APorcentajeReal := Round(ADto / ASalida * 100 * 100) / 100;
end;

// Graba el descuento de las lineas indicadas (ID -> % pedido). La salida no
// cambia; el % grabado es el real tras redondear.
procedure TdmTarifasCambios.GrabarDescuentos(
  const APorLinea: TDictionary<Integer, Double>);
var
  dDto: Double;
  dFinal: Double;
  dPorcentaje: Double;
  dPorcentajeReal: Double;
  dSalida: Double;
  EsTransaccionPropia: Boolean;
  oConexion: TUniConnection;
  qry: TUniQuery;
begin
  if APorLinea.Count > 0 then
  begin
    oConexion := unqryTablaG.Connection as TUniConnection;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConexion;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas SET ' +
        'PRECIO_NUEVO_TARCLIN = :SALIDA, ' +
        'PRECIO_FINAL_NUEVO_TARCLIN = :FINAL, ' +
        'PRECIO_DTO_NUEVO_TARCLIN = :DTO, ' +
        'PORCENTAJE_DTO_NUEVO_TARCLIN = :PORC, ' +
        'ESTADO_TARCLIN = ''PENDIENTE'', MENSAJE_TARCLIN = NULL, ' +
        'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE ID_TARCLIN = :ID';
      EsTransaccionPropia := not oConexion.InTransaction;
      if EsTransaccionPropia then
        oConexion.StartTransaction;
      unqryLineas.DisableControls;
      try
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            if APorLinea.TryGetValue(
                 unqryLineas.FieldByName('ID_TARCLIN').AsInteger,
                 dPorcentaje) then
            begin
              dSalida := SalidaParaDescuento;
              CalcularDescuento(dSalida, dPorcentaje, dFinal, dDto,
                dPorcentajeReal);
              qry.ParamByName('SALIDA').AsFloat := dSalida;
              qry.ParamByName('FINAL').AsFloat := dFinal;
              qry.ParamByName('DTO').AsFloat := dDto;
              qry.ParamByName('PORC').AsFloat := dPorcentajeReal;
              qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
              qry.ParamByName('ID').AsInteger :=
                unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
              qry.Execute;
            end;
            unqryLineas.Next;
          end;
          if EsTransaccionPropia then
            oConexion.Commit;
        except
          if EsTransaccionPropia and oConexion.InTransaction then
            oConexion.Rollback;
          raise;
        end;
      finally
        unqryLineas.EnableControls;
      end;
    finally
      FreeAndNil(qry);
    end;
    unqryLineas.Refresh;
  end;
end;

procedure TdmTarifasCambios.GrabarLineaPendiente;
begin
  if unqryLineas.Active and (unqryLineas.State in dsEditModes) then
    unqryLineas.Post;
end;

// Completa los precios de partida de las lineas de la sesion activa, vengan
// de la carga de articulos, de un documento de trabajo o de un Excel:
// - lo que este vacio se lee de la tarifa o del proveedor;
// - si la cabecera cambio de tarifa origen/destino, se releen los precios
//   que dependen de ella y la linea pasa a esa tarifa;
// - el coste escrito a mano no se pisa.
// En un UPDATE de una sola tabla MySQL evalua las asignaciones en orden: los
// codigos de tarifa de la linea se actualizan al final, tras comparar. Por
// eso no hay JOIN con la cabecera: sus tarifas llegan como parametros.
procedure TdmTarifasCambios.RellenarPreciosPartida;
var
  qry: TUniQuery;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (not SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
                   'APLICADA')) then
  begin
    GrabarLineaPendiente;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas L SET ' +
        'L.PRECIO_ORIGEN_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_ORIGEN_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_ORIGEN + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_SALIDA_ARTTAR', 'TAR_ORIG']) +
        '  ELSE L.PRECIO_ORIGEN_TARCLIN END, ' +
        'L.PRECIO_SALIDA_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_SALIDA_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_SALIDA_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_SALIDA_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_FINAL_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_FINAL_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_FINAL_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_FINAL_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_DTO_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_DTO_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_DTO_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_DTO_ACTUAL_TARCLIN END, ' +
        'L.PORCENTAJE_DTO_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PORCENTAJE_DTO_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PORCENTAJE_DTO_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PORCENTAJE_DTO_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_COSTE_TARCLIN = COALESCE(L.PRECIO_COSTE_TARCLIN, ' +
        SQL_COSTE_LINEA + '), ' +
        'L.CODIGO_TAR_ORIGEN_TARCLIN = :TAR_ORIG, ' +
        'L.CODIGO_TAR_DESTINO_TARCLIN = :TAR_DEST ' +
        'WHERE L.CODIGO_TARC_TARCLIN = :CODIGO';
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.ParamByName('TAR_ORIG').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString;
      qry.ParamByName('TAR_DEST').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString;
      qry.Execute;
      if unqryLineas.Active then
        unqryLineas.Refresh;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

const
  // Una celda vacia del Excel llega como NULL y conserva el valor actual.
  SQL_ACTUALIZAR_LINEA_EXCEL =
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'ESAPLICAR_TARCLIN = COALESCE(:APLICAR, ESAPLICAR_TARCLIN), ' +
    'PRECIO_ORIGEN_TARCLIN = COALESCE(:P0, PRECIO_ORIGEN_TARCLIN), ' +
    'PRECIO_COSTE_TARCLIN = COALESCE(:P1, PRECIO_COSTE_TARCLIN), ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P2, PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P3, PRECIO_FINAL_ACTUAL_TARCLIN), ' +
    'PRECIO_DTO_ACTUAL_TARCLIN = COALESCE(:P4, PRECIO_DTO_ACTUAL_TARCLIN), ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P5, PORCENTAJE_DTO_ACTUAL_TARCLIN), ' +
    'PRECIO_NUEVO_TARCLIN = COALESCE(:P6, PRECIO_NUEVO_TARCLIN), ' +
    'PRECIO_FINAL_NUEVO_TARCLIN = ' +
    '  COALESCE(:P7, PRECIO_FINAL_NUEVO_TARCLIN), ' +
    'PRECIO_DTO_NUEVO_TARCLIN = COALESCE(:P8, PRECIO_DTO_NUEVO_TARCLIN), ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN = ' +
    '  COALESCE(:P9, PORCENTAJE_DTO_NUEVO_TARCLIN), ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC_TARCLIN = :TARC AND CODIGO_ART_TARCLIN = :ART ' +
    'AND CODIGO_UNIDAD_SKU_TARCLIN = :SKU';
  SQL_INSERTAR_LINEA_EXCEL =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, ESTADO_TARCLIN, PRECIO_ORIGEN_TARCLIN, ' +
    'PRECIO_COSTE_TARCLIN, PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN, PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN, PRECIO_NUEVO_TARCLIN, ' +
    'PRECIO_FINAL_NUEVO_TARCLIN, PRECIO_DTO_NUEVO_TARCLIN, ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT C.CODIGO_TARC, :ART, :SKU, C.CODIGO_TAR_ORIGEN_TARC, ' +
    'C.CODIGO_TAR_DESTINO_TARC, COALESCE(:APLICAR, ''S''), ''PENDIENTE'', ' +
    ':P0, :P1, :P2, :P3, :P4, :P5, :P6, :P7, :P8, :P9, NOW(), :USUARIO ' +
    'FROM fza_tarifas_cambios C WHERE C.CODIGO_TARC = :TARC';
  SQL_EXISTE_LINEA_EXCEL =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas_cambios_lineas ' +
    'WHERE CODIGO_TARC_TARCLIN = :TARC AND CODIGO_ART_TARCLIN = :ART ' +
    'AND CODIGO_UNIDAD_SKU_TARCLIN = :SKU';

procedure TdmTarifasCambios.AsignarParametrosLineaExcel(AConsulta: TUniQuery;
  const ALinea: TLineaSesionTarifaExcel);
var
  Importe: TImporteSesionTarifa;
  Parametro: TUniParam;
begin
  AConsulta.ParamByName('TARC').AsInteger :=
    unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
  AConsulta.ParamByName('ART').AsString := ALinea.Articulo;
  AConsulta.ParamByName('SKU').AsString := ALinea.Sku;
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  Parametro := AConsulta.ParamByName('APLICAR');
  Parametro.DataType := ftString;
  if ALinea.Aplicar = '' then
    Parametro.Clear
  else
    Parametro.AsString := ALinea.Aplicar;
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
  begin
    Parametro := AConsulta.ParamByName('P' + IntToStr(Ord(Importe)));
    Parametro.DataType := ftFloat;
    if ALinea.TieneImporte[Importe] then
      Parametro.AsFloat := ALinea.Importes[Importe]
    else
      Parametro.Clear;
  end;
end;

function EsDescuentoPorPorcentajeExcel(
  const ALinea: TLineaSesionTarifaExcel): Boolean;
begin
  Result := ALinea.TieneImporte[istPorcDtoNuevo] and
    (not ALinea.TieneImporte[istFinalNueva]);
end;

function ClaveArticuloSku(const AArticulo, ASku: string): string;
begin
  Result := AArticulo + #9 + ASku;
end;

// Si el Excel trae solo el final se calculan el importe y el % sin
// redondear: el final lo ha fijado el usuario. Si trae solo el %, se trata
// despues con el criterio comun (GrabarDescuentos) una vez cargadas las
// lineas y sus precios de partida.
procedure TdmTarifasCambios.CompletarDescuentoLineaExcel(AConsulta: TUniQuery;
  const ALinea: TLineaSesionTarifaExcel);
begin
  if ALinea.TieneImporte[istFinalNueva] and
     (not ALinea.TieneImporte[istPorcDtoNuevo]) and
     (not ALinea.TieneImporte[istDtoNuevo]) then
  begin
    AConsulta.SQL.Text :=
      Format(SQL_DESCUENTO_FINAL, [SQL_FILTRO_ARTICULO_LINEA]);
    AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    AConsulta.ParamByName('TARC').AsInteger :=
      unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
    AConsulta.ParamByName('ART').AsString := ALinea.Articulo;
    AConsulta.ParamByName('SKU').AsString := ALinea.Sku;
    AConsulta.Execute;
  end;
end;

procedure TdmTarifasCambios.ImportarLineasExcel(
  const ALineas: TLineasSesionTarifaExcel;
  out ANuevas, AActualizadas: Integer);
var
  EsTransaccionPropia: Boolean;
  iLinea: Integer;
  oConexion: TUniConnection;
  qryActualizar: TUniQuery;
  qryDescuento: TUniQuery;
  qryExiste: TUniQuery;
  qryInsertar: TUniQuery;
begin
  ANuevas := 0;
  AActualizadas := 0;
  GrabarLineaPendiente;
  oConexion := unqryTablaG.Connection as TUniConnection;
  qryActualizar := TUniQuery.Create(nil);
  qryDescuento := TUniQuery.Create(nil);
  qryExiste := TUniQuery.Create(nil);
  qryInsertar := TUniQuery.Create(nil);
  try
    qryDescuento.Connection := oConexion;
    qryExiste.Connection := oConexion;
    qryExiste.SQL.Text := SQL_EXISTE_LINEA_EXCEL;
    qryActualizar.Connection := oConexion;
    qryActualizar.SQL.Text := SQL_ACTUALIZAR_LINEA_EXCEL;
    qryInsertar.Connection := oConexion;
    qryInsertar.SQL.Text := SQL_INSERTAR_LINEA_EXCEL;
    EsTransaccionPropia := not oConexion.InTransaction;
    if EsTransaccionPropia then
      oConexion.StartTransaction;
    try
      for iLinea := 0 to High(ALineas) do
      begin
        qryExiste.Close;
        qryExiste.ParamByName('TARC').AsInteger :=
          unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
        qryExiste.ParamByName('ART').AsString := ALineas[iLinea].Articulo;
        qryExiste.ParamByName('SKU').AsString := ALineas[iLinea].Sku;
        qryExiste.Open;
        if qryExiste.FieldByName('CANTIDAD').AsInteger > 0 then
        begin
          AsignarParametrosLineaExcel(qryActualizar, ALineas[iLinea]);
          qryActualizar.Execute;
          Inc(AActualizadas);
        end
        else
        begin
          AsignarParametrosLineaExcel(qryInsertar, ALineas[iLinea]);
          qryInsertar.Execute;
          Inc(ANuevas);
        end;
        CompletarDescuentoLineaExcel(qryDescuento, ALineas[iLinea]);
      end;
      if EsTransaccionPropia then
        oConexion.Commit;
    except
      if EsTransaccionPropia and oConexion.InTransaction then
        oConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qryInsertar);
    FreeAndNil(qryExiste);
    FreeAndNil(qryDescuento);
    FreeAndNil(qryActualizar);
  end;
  RellenarPreciosPartida;
  AplicarPorcentajesExcel(ALineas);
end;

// Filas del Excel con solo "% dto nuevo": se calculan con el criterio comun
// de redondeo sobre la salida de cada linea ya cargada.
procedure TdmTarifasCambios.AplicarPorcentajesExcel(
  const ALineas: TLineasSesionTarifaExcel);
var
  dPorcentaje: Double;
  iLinea: Integer;
  PorClave: TDictionary<string, Double>;
  PorLinea: TDictionary<Integer, Double>;
begin
  PorClave := TDictionary<string, Double>.Create;
  PorLinea := TDictionary<Integer, Double>.Create;
  try
    for iLinea := 0 to High(ALineas) do
      if EsDescuentoPorPorcentajeExcel(ALineas[iLinea]) then
        PorClave.AddOrSetValue(
          ClaveArticuloSku(ALineas[iLinea].Articulo, ALineas[iLinea].Sku),
          ALineas[iLinea].Importes[istPorcDtoNuevo]);
    if PorClave.Count > 0 then
    begin
      unqryLineas.DisableControls;
      try
        unqryLineas.First;
        while not unqryLineas.Eof do
        begin
          if PorClave.TryGetValue(ClaveArticuloSku(
               unqryLineas.FieldByName('CODIGO_ART_TARCLIN').AsString,
               unqryLineas.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString),
               dPorcentaje) then
            PorLinea.AddOrSetValue(
              unqryLineas.FieldByName('ID_TARCLIN').AsInteger, dPorcentaje);
          unqryLineas.Next;
        end;
      finally
        unqryLineas.EnableControls;
      end;
      GrabarDescuentos(PorLinea);
    end;
  finally
    FreeAndNil(PorLinea);
    FreeAndNil(PorClave);
  end;
end;

function TdmTarifasCambios.RecalcularSesionActual(
  const AIdsLinea: TArray<Integer>; out AMensaje: string): Integer;
var
  qry               : TUniQuery;
  Seleccion: TDictionary<Integer, Boolean>;
  iId: Integer;
  sCampoOrigen      : string;
  sCampoDestino     : string;
  sTipoAplicacion   : string;
  dValorAplicacion  : Double;
  dValorRedondeo    : Double;
  dValorMenos       : Double;
  dBase             : Double;
  dNuevo            : Double;
  dSalida           : Double;
  dFinal            : Double;
  dDto              : Double;
  dPorcDto          : Double;
  EsRedondearArriba : Boolean;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else if Length(AIdsLinea) = 0 then
    AMensaje := SErrorSeleccionVaciaSesionTarifa
  else
  begin
    RellenarPreciosPartida;
    sCampoOrigen := CampoCabecera('CAMPO_ORIGEN_TARC').AsString;
    sCampoDestino := CampoCabecera('CAMPO_DESTINO_TARC').AsString;
    sTipoAplicacion := CampoCabecera('TIPO_APLICACION_TARC').AsString;
    dValorAplicacion := CampoCabecera('VALOR_APLICACION_TARC').AsFloat;
    dValorRedondeo := CampoCabecera('VALOR_REDONDEO_TARC').AsFloat;
    dValorMenos := CampoCabecera('VALOR_MENOS_AJUSTE_TARC').AsFloat;
    EsRedondearArriba :=
      SameText(CampoCabecera('ESREDONDEAR_ARRIBA_TARC').AsString, 'S');
    Seleccion := TDictionary<Integer, Boolean>.Create;
    try
      for iId in AIdsLinea do
        Seleccion.AddOrSetValue(iId, True);
      qry := TUniQuery.Create(nil);
      try
        qry.Connection := unqryTablaG.Connection;
        qry.SQL.Text :=
          'UPDATE fza_tarifas_cambios_lineas SET ' +
          '  PRECIO_NUEVO_TARCLIN = :SALIDA, ' +
          '  PRECIO_FINAL_NUEVO_TARCLIN = :FINAL, ' +
          '  PRECIO_DTO_NUEVO_TARCLIN = :DTO, ' +
          '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORC_DTO, ' +
          '  ESTADO_TARCLIN = ''PENDIENTE'', ' +
          '  MENSAJE_TARCLIN = NULL, ' +
          '  USUARIO_MODIF = :USUARIO, ' +
          '  INSTANTE_MODIF = NOW() ' +
          'WHERE ID_TARCLIN = :ID';
        unqryLineas.DisableControls;
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            if Seleccion.ContainsKey(
              unqryLineas.FieldByName('ID_TARCLIN').AsInteger) then
            begin
              dBase := PrecioBaseLinea(sCampoOrigen);
              dNuevo := CalcularImporte(dBase, sTipoAplicacion,
                                        dValorAplicacion);
              dNuevo := RedondearImporte(dNuevo, dValorRedondeo,
                                         dValorMenos, EsRedondearArriba);
              dSalida := dNuevo;
              dFinal := dNuevo;
              dDto := 0;
              dPorcDto := 0;
              if SameText(sCampoDestino, 'PRECIO_FINAL') then
              begin
                // Tarifa destino sin precio: la salida es la de origen.
                dSalida := LeerFloatLinea('PRECIO_SALIDA_ACTUAL_TARCLIN');
                if dSalida <= 0 then
                  dSalida := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
                if dSalida <= 0 then
                  dSalida := dNuevo;
                dFinal := dNuevo;
                dDto := dSalida - dFinal;
                if dDto < 0 then
                  dDto := 0;
              end
              else if SameText(sCampoDestino, 'PRECIO_SALIDA') then
              begin
                dSalida := dNuevo;
                dDto := LeerFloatLinea('PRECIO_DTO_ACTUAL_TARCLIN');
                dFinal := dSalida - dDto;
                if dFinal < 0 then
                  dFinal := dSalida;
              end;
              if (dSalida > 0) and (dDto > 0) then
                dPorcDto := dDto / dSalida * 100;
              qry.ParamByName('SALIDA').AsFloat := dSalida;
              qry.ParamByName('FINAL').AsFloat := dFinal;
              qry.ParamByName('DTO').AsFloat := dDto;
              qry.ParamByName('PORC_DTO').AsFloat := dPorcDto;
              qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
              qry.ParamByName('ID').AsInteger :=
                unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
              qry.Execute;
              Inc(Result);
            end;
            unqryLineas.Next;
          end;
        finally
          unqryLineas.EnableControls;
        end;
        qry.SQL.Text :=
          'UPDATE fza_tarifas_cambios SET ' +
          '  ESTADO_TARC = ''BORRADOR'', ' +
          '  INSTANTE_APLICACION_TARC = NULL, ' +
          '  USUARIO_APLICACION_TARC = NULL, ' +
          '  USUARIO_MODIF = :USUARIO, ' +
          '  INSTANTE_MODIF = NOW() ' +
          'WHERE CODIGO_TARC = :CODIGO';
        qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
        qry.ParamByName('CODIGO').AsInteger :=
          unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
        qry.Execute;
        unqryTablaG.Refresh;
        unqryLineas.Refresh;
      finally
        FreeAndNil(qry);
      end;
    finally
      FreeAndNil(Seleccion);
    end;
  end;
end;

procedure TdmTarifasCambios.ConfigurarConsultasAplicacion(
  AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
begin
  AConsultaBusca.SQL.Text :=
    'SELECT CODIGO_UNICO_ARTTAR ' +
    'FROM fza_articulos_tarifas ' +
    'WHERE CODIGO_ART_ARTTAR = :ART ' +
    'AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = :SKU ' +
    'AND CODIGO_TAR_ARTTAR = :TAR ' +
    'AND ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY FECHA_DESDE_ARTTAR DESC, CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1';
  AConsultaMarca.SQL.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'ESTADO_TARCLIN = ''APLICADA'', MENSAJE_TARCLIN = :MENSAJE, ' +
    'CODIGO_UNICO_ARTTAR_TARCLIN = :UNICO, ' +
    'INSTANTE_APLICACION_TARCLIN = NOW(), USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() WHERE ID_TARCLIN = :ID';
  AConsultaUnico.SQL.Text :=
    'SELECT LAST_INSERT_ID() AS CODIGO_UNICO_ARTTAR';
end;

function TdmTarifasCambios.AplicarLineaTarifa(
  AConsultaBusca, AConsultaExec, AConsultaMarca,
  AConsultaUnico: TUniQuery;
  out AEncoloPrestaShop: Boolean): Boolean;
var
  EsInsertar: Boolean;
  iUnico: Integer;
  sArticulo: string;
  sSku: string;
  sTarifa: string;
begin
  Result := False;
  AEncoloPrestaShop := False;
  if SameText(unqryLineas.FieldByName(
    'ESAPLICAR_TARCLIN').AsString, 'S') then
  begin
    sArticulo := unqryLineas.FieldByName('CODIGO_ART_TARCLIN').AsString;
    sSku := unqryLineas.FieldByName(
      'CODIGO_UNIDAD_SKU_TARCLIN').AsString;
    sTarifa := unqryLineas.FieldByName(
      'CODIGO_TAR_DESTINO_TARCLIN').AsString;
    AConsultaBusca.Close;
    AConsultaBusca.ParamByName('ART').AsString := sArticulo;
    AConsultaBusca.ParamByName('SKU').AsString := sSku;
    AConsultaBusca.ParamByName('TAR').AsString := sTarifa;
    AConsultaBusca.Open;
    EsInsertar := AConsultaBusca.IsEmpty;
    if EsInsertar then
    begin
      iUnico := 0;
      AConsultaExec.SQL.Text :=
        'INSERT INTO fza_articulos_tarifas ' +
        '(CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, ' +
        'CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, ' +
        'PRECIO_FINAL_ARTTAR, PRECIO_DTO_ARTTAR, ' +
        'PORCENTAJE_DTO_ARTTAR, FECHA_DESDE_ARTTAR, ' +
        'FECHA_HASTA_ARTTAR, USUARIO_ALTA, USUARIO_MODIF, ' +
        'INSTANTE_ALTA) VALUES (:ART, :SKU, :TAR, ''S'', :SALIDA, ' +
        ':FINAL, :DTO, :PORC_DTO, :DESDE, :HASTA, :USUARIO, ' +
        ':USUARIO, NOW())';
      AConsultaExec.ParamByName('ART').AsString := sArticulo;
      AConsultaExec.ParamByName('SKU').AsString := sSku;
      AConsultaExec.ParamByName('TAR').AsString := sTarifa;
    end
    else
    begin
      iUnico := AConsultaBusca.FieldByName(
        'CODIGO_UNICO_ARTTAR').AsInteger;
      AConsultaExec.SQL.Text :=
        'UPDATE fza_articulos_tarifas SET ' +
        'PRECIO_SALIDA_ARTTAR = :SALIDA, PRECIO_FINAL_ARTTAR = :FINAL, ' +
        'PRECIO_DTO_ARTTAR = :DTO, PORCENTAJE_DTO_ARTTAR = :PORC_DTO, ' +
        'FECHA_DESDE_ARTTAR = :DESDE, FECHA_HASTA_ARTTAR = :HASTA, ' +
        'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE CODIGO_UNICO_ARTTAR = :UNICO';
      AConsultaExec.ParamByName('UNICO').AsInteger := iUnico;
    end;
    AConsultaExec.ParamByName('SALIDA').AsFloat :=
      LeerFloatLinea('PRECIO_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('FINAL').AsFloat :=
      LeerFloatLinea('PRECIO_FINAL_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('DTO').AsFloat :=
      LeerFloatLinea('PRECIO_DTO_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('PORC_DTO').AsFloat :=
      LeerFloatLinea('PORCENTAJE_DTO_NUEVO_TARCLIN');
    if CampoCabecera('FECHA_DESDE_TARC').IsNull then
      AConsultaExec.ParamByName('DESDE').AsDateTime := Date
    else
      AConsultaExec.ParamByName('DESDE').AsDateTime :=
        CampoCabecera('FECHA_DESDE_TARC').AsDateTime;
    if CampoCabecera('FECHA_HASTA_TARC').IsNull then
      AConsultaExec.ParamByName('HASTA').Clear
    else
      AConsultaExec.ParamByName('HASTA').AsDateTime :=
        CampoCabecera('FECHA_HASTA_TARC').AsDateTime;
    AConsultaExec.ParamByName('USUARIO').AsString :=
      IdentidadSesion.Usuario;
    AConsultaExec.Execute;
    if EsInsertar then
    begin
      AConsultaUnico.Close;
      AConsultaUnico.Open;
      iUnico := AConsultaUnico.FieldByName(
        'CODIGO_UNICO_ARTTAR').AsInteger;
    end;
    AConsultaMarca.ParamByName('MENSAJE').AsString := 'Aplicada';
    AConsultaMarca.ParamByName('UNICO').AsInteger := iUnico;
    AConsultaMarca.ParamByName('USUARIO').AsString :=
      IdentidadSesion.Usuario;
    AConsultaMarca.ParamByName('ID').AsInteger :=
      unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
    AConsultaMarca.Execute;
    if SameText(
      Trim(sTarifa),
      LeerCodigoTarifaPrestaShop(
        AConsultaExec.Connection,
        IdentidadSesion.Usuario)) then
    begin
      EncolarPrecioPrestaShop(
        AConsultaExec.Connection,
        sArticulo,
        IdentidadSesion.Usuario);
      AEncoloPrestaShop := True;
    end;
    Result := True;
  end;
end;

procedure TdmTarifasCambios.MarcarSesionAplicada(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_tarifas_cambios SET ESTADO_TARC = ''APLICADA'', ' +
    'INSTANTE_APLICACION_TARC = NOW(), USUARIO_APLICACION_TARC = ' +
    ':USUARIO, USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC = :CODIGO';
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  AConsulta.ParamByName('CODIGO').AsInteger :=
    unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
  AConsulta.Execute;
end;

function TdmTarifasCambios.AplicarSesionActual(
  out AMensaje: string): Integer;
var
  EncoloLineaPrestaShop: Boolean;
  EsTransaccionPropia: Boolean;
  HayEncoladoPrestaShop: Boolean;
  TransaccionConfirmada: Boolean;
  oConexion: TUniConnection;
  qryBusca: TUniQuery;
  qryExec: TUniQuery;
  qryMarca: TUniQuery;
  qryUnico: TUniQuery;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
    'APLICADA') then
    AMensaje := SErrorTarifasCambiosSesionAplicada
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else
  begin
    qryBusca := nil;
    qryExec := nil;
    qryMarca := nil;
    qryUnico := nil;
    try
      qryBusca := TUniQuery.Create(nil);
      qryExec := TUniQuery.Create(nil);
      qryMarca := TUniQuery.Create(nil);
      qryUnico := TUniQuery.Create(nil);
      oConexion := unqryTablaG.Connection as TUniConnection;
      qryBusca.Connection := oConexion;
      qryExec.Connection := oConexion;
      qryMarca.Connection := oConexion;
      qryUnico.Connection := oConexion;
      ConfigurarConsultasAplicacion(qryBusca, qryMarca, qryUnico);
      EsTransaccionPropia := not oConexion.InTransaction;
      HayEncoladoPrestaShop := False;
      TransaccionConfirmada := False;
      if EsTransaccionPropia then
        oConexion.StartTransaction;
      try
        unqryLineas.DisableControls;
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            if AplicarLineaTarifa(
              qryBusca, qryExec, qryMarca, qryUnico,
              EncoloLineaPrestaShop) then
              Inc(Result);
            HayEncoladoPrestaShop :=
              HayEncoladoPrestaShop or EncoloLineaPrestaShop;
            unqryLineas.Next;
          end;
        finally
          unqryLineas.EnableControls;
        end;
        MarcarSesionAplicada(qryExec);
        if EsTransaccionPropia then
        begin
          oConexion.Commit;
          TransaccionConfirmada := True;
        end;
      except
        on E: Exception do
        begin
          if EsTransaccionPropia and oConexion.InTransaction then
            oConexion.Rollback;
          if EsTransaccionPropia then
          begin
            AMensaje := E.Message;
            Result := 0;
          end
          else
            raise;
        end;
      end;
      if TransaccionConfirmada and HayEncoladoPrestaShop then
        SolicitarProcesadoPrestaShop;
      unqryTablaG.Refresh;
      unqryLineas.Refresh;
    finally
      FreeAndNil(qryUnico);
      FreeAndNil(qryMarca);
      FreeAndNil(qryExec);
      FreeAndNil(qryBusca);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmTarifasCambios);
  ForceReferenceToClass(TdmTarifasCambios);
end.

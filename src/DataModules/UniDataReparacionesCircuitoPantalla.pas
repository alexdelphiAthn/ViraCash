{******************************************************************************}
{  Módulo: UniDataReparacionesCircuitoPantalla. Tipo: Persistencia             }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Consultas maestro/detalle y resumen calculado de la orden.     }
{******************************************************************************}
unit UniDataReparacionesCircuitoPantalla;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Datasnap.DBClient, Uni,
  UniDataReparacionesCobertura, UniDataReparacionesTiempos,
  UniDataReparacionesMateriales, UniDataReparacionesCrearAlbaran,
  UniDataReparacionesImputaciones, UniDataReparacionesEntregas,
  UniDataReparacionesCierreEconomico;

type
  TEnlaceMaestroCircuito = class(TDataLink)
  private
    FNotificar: TProc;
  protected
    procedure ActiveChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(const ANotificar: TProc);
  end;

  TDatosCircuitoOrden = class(TComponent)
  private
    FConexion: TUniConnection;
    FDisponible, FActualizando: Boolean;
    FOrden: Int64;
    FEnlace: TEnlaceMaestroCircuito;
    FResumen: TClientDataSet;
    FdsResumen, FdsTiempos, FdsMateriales, FdsHistorial: TDataSource;
    FTiempos, FMateriales, FHistorial, FDocumentos: TUniQuery;
    FdsDocumentos: TDataSource;
    FGenerador: TGeneradorAlbaranOrden;
    FImputaciones: TRepositorioImputacionesOrden;
    FEntregas: TRepositorioEntregasOrden;
    FCierre: TRepositorioCierreEconomicoOrden;
    FExternos: TUniQuery;
    FdsExternos: TDataSource;
    FCobertura: TRepositorioCoberturaOrden;
    FRegistroTiempos: TRepositorioTiemposOrden;
    FRegistroMateriales: TRepositorioMaterialesOrden;
    function CrearConsulta(const ASql: string): TUniQuery;
    function Origen(ADatos: TDataSet): TDataSource;
    procedure CrearResumen;
    procedure CrearListas;
    procedure CargarResumen;
    procedure MaestroCambiado;
    procedure AbrirDetalle(AConsulta: TUniQuery);
  public
    constructor CreateDatos(AOwner: TComponent; AConexion: TUniConnection;
      const AUsuario: string);
    destructor Destroy; override;
    procedure AsignarMaestro(AMaestro: TDataSource);
    procedure Refrescar;
    function Gestionada(AOrden: Int64): Boolean;
    function ResumenReparto(AOrden: Int64): string;
    function Maestro: TDataSource;
    property Disponible: Boolean read FDisponible;
    property Orden: Int64 read FOrden;
    property Resumen: TDataSource read FdsResumen;
    property Tiempos: TDataSource read FdsTiempos;
    property Materiales: TDataSource read FdsMateriales;
    property Cierre: TRepositorioCierreEconomicoOrden read FCierre;
    property Entregas: TRepositorioEntregasOrden read FEntregas;
    property Externos: TDataSource read FdsExternos;
    property Generador: TGeneradorAlbaranOrden read FGenerador;
    property Imputaciones: TRepositorioImputacionesOrden read FImputaciones;
    property Documentos: TDataSource read FdsDocumentos;
    property Historial: TDataSource read FdsHistorial;
    property Cobertura: TRepositorioCoberturaOrden read FCobertura;
    property RegistroTiempos: TRepositorioTiemposOrden read FRegistroTiempos;
    property RegistroMateriales: TRepositorioMaterialesOrden
      read FRegistroMateriales;
  end;

implementation

uses
  inLibReparacionesCircuito, inLibMsgReparacionesCircuito;

function TDatosCircuitoOrden.Gestionada(AOrden: Int64): Boolean;
begin
  Result := FDisponible and (FCobertura.Acuerdo(AOrden).Revision > 0);
end;

function TDatosCircuitoOrden.Maestro: TDataSource;
begin
  Result := FEnlace.DataSource;
end;

function TDatosCircuitoOrden.ResumenReparto(AOrden: Int64): string;
var
  rConcepto: TRepartoConceptoOrden;
  dCliente, dSeguro, dTaller, dPendiente: Currency;
begin
  Result := '';
  if Gestionada(AOrden) then
  begin
    dCliente := 0;
    dSeguro := 0;
    dTaller := 0;
    dPendiente := 0;
    for rConcepto in FCobertura.Reparto(AOrden) do
    begin
      dCliente := dCliente + rConcepto.Cliente;
      dSeguro := dSeguro + rConcepto.Aseguradora;
      dTaller := dTaller + rConcepto.Taller;
      dPendiente := dPendiente + rConcepto.Pendiente;
    end;
    Result := Format(SCircuitoResumenReparto,
      [CurrToStr(dCliente),CurrToStr(dSeguro),CurrToStr(dTaller),
       CurrToStr(dPendiente)]);
  end;
end;

constructor TEnlaceMaestroCircuito.Create(const ANotificar: TProc);
begin
  inherited Create;
  FNotificar := ANotificar;
end;

procedure TEnlaceMaestroCircuito.ActiveChanged;
begin
  FNotificar();
end;

procedure TEnlaceMaestroCircuito.DataSetScrolled(Distance: Integer);
begin
  FNotificar();
end;

procedure TEnlaceMaestroCircuito.RecordChanged(Field: TField);
begin
  if Field = nil then
    FNotificar();
end;

function TDatosCircuitoOrden.CrearConsulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(Self);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
  Result.ReadOnly := True;
end;

function TDatosCircuitoOrden.Origen(ADatos: TDataSet): TDataSource;
begin
  Result := TDataSource.Create(Self);
  Result.DataSet := ADatos;
end;

procedure TDatosCircuitoOrden.CrearListas;
begin
  FTiempos := CrearConsulta('SELECT ID_GAR_RCT,ID_RCT,ID_GARLIN_RCT,' +
    'CODIGO_EMPL_RCT,TAREA_RCT,INSTANTE_INICIO_RCT,INSTANTE_FIN_RCT,' +
    'ROUND(TIMESTAMPDIFF(SECOND,INSTANTE_INICIO_RCT,' +
    'COALESCE(INSTANTE_FIN_RCT,NOW()))/3600,4) AS HORAS,' +
    'ESANULADO_RCT,MOTIVO_RCT FROM fza_reparaciones_tiempos ' +
    'WHERE ID_GAR_RCT=:ORDEN ORDER BY ID_RCT DESC');
  FdsTiempos := Origen(FTiempos);
  FMateriales := CrearConsulta('SELECT ID_GAR_RCM,ID_GARLIN_RCM,' +
    'PROCEDENCIA_RCM,UNIDAD_RCM,REFERENCIA_RCM,' +
    'CANTIDAD_PREVISTA_RCM,CANTIDAD_UTILIZADA_RCM,' +
    'CANTIDAD_DEVUELTA_RCM FROM fza_reparaciones_materiales ' +
    'WHERE ID_GAR_RCM=:ORDEN ORDER BY ID_GARLIN_RCM');
  FdsMateriales := Origen(FMateriales);
  FHistorial := CrearConsulta('SELECT ID_GAR_RCH,ID_RCH,ID_GARLIN_RCH,' +
    'ACCION_RCH,DETALLE_RCH,INSTANTE_ALTA,USUARIO_ALTA ' +
    'FROM fza_reparaciones_historial WHERE ID_GAR_RCH=:ORDEN ' +
    'ORDER BY ID_RCH DESC');
  FdsHistorial := Origen(FHistorial);
  FDocumentos := CrearConsulta('SELECT I.ID_RCI,I.ID_GARLIN_RCI,I.TIPO_RCI,' +
    'I.SERIE_RCI,I.NUMERO_RCI,I.LINEA_RCI,I.TOTAL_RCI,I.CANTIDAD_RCI,' +
    'COALESCE(A.CODIGO_PRV_ALBC,'''') AS CODIGO_PROVEEDOR,' +
    'COALESCE(A.RAZON_SOCIAL_PRV_ALBC,'''') AS NOMBRE_PROVEEDOR ' +
    'FROM fza_reparaciones_imputaciones I ' +
    'LEFT JOIN fza_albaranes_compra A ON I.TIPO_RCI=''PR'' ' +
    'AND A.SERIE_ALBC=I.SERIE_RCI AND A.NUMERO_ALBC=I.NUMERO_RCI ' +
    'WHERE I.ID_GAR_RCI=:ORDEN ORDER BY I.ID_RCI');
  FdsDocumentos := Origen(FDocumentos);
  FExternos := CrearConsulta('SELECT ID_RCE,ID_GARLIN_RCE,CODIGO_PRV_RCE,' +
    'OBJETO_RCE,CANTIDAD_ENVIADA_RCE,CANTIDAD_RECIBIDA_RCE,' +
    'INSTANTE_ENVIO_RCE,INSTANTE_RECEPCION_RCE,INCIDENCIA_RCE,REVISION_RCE ' +
    'FROM fza_reparaciones_entregas WHERE ID_GAR_RCE=:ORDEN ' +
    'ORDER BY ID_RCE DESC');
  FdsExternos := Origen(FExternos);
end;

constructor TDatosCircuitoOrden.CreateDatos(AOwner: TComponent;
  AConexion: TUniConnection; const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FCierre := TRepositorioCierreEconomicoOrden.Create(AConexion, AUsuario);
  FEntregas := TRepositorioEntregasOrden.Create(AConexion, AUsuario);
  FGenerador := TGeneradorAlbaranOrden.Create(AConexion, AUsuario);
  FImputaciones := TRepositorioImputacionesOrden.Create(AConexion, AUsuario);
  FCobertura := TRepositorioCoberturaOrden.Create(AConexion, AUsuario);
  FRegistroTiempos := TRepositorioTiemposOrden.Create(AConexion, AUsuario);
  FRegistroMateriales := TRepositorioMaterialesOrden.Create(
    AConexion, AUsuario);
  FEnlace := TEnlaceMaestroCircuito.Create(MaestroCambiado);
  CrearResumen;
  CrearListas;
  oConsulta := CrearConsulta('SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA=DATABASE() ' +
    'AND TABLE_NAME=''fza_reparaciones_acuerdos''');
  try
    oConsulta.Open;
    FDisponible := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

destructor TDatosCircuitoOrden.Destroy;
begin
  FreeAndNil(FEnlace);
  FreeAndNil(FCierre);
  FreeAndNil(FEntregas);
  FreeAndNil(FGenerador);
  FreeAndNil(FImputaciones);
  FreeAndNil(FRegistroMateriales);
  FreeAndNil(FRegistroTiempos);
  FreeAndNil(FCobertura);
  inherited;
end;

procedure TDatosCircuitoOrden.CrearResumen;
begin
  FResumen := TClientDataSet.Create(Self);
  FResumen.FieldDefs.Add('LINEA', ftLargeint);
  FResumen.FieldDefs.Add('DESCRIPCION', ftString, 200);
  FResumen.FieldDefs.Add('TOTAL', ftCurrency);
  FResumen.FieldDefs.Add('CLIENTE', ftCurrency);
  FResumen.FieldDefs.Add('ASEGURADORA', ftCurrency);
  FResumen.FieldDefs.Add('TALLER', ftCurrency);
  FResumen.FieldDefs.Add('PENDIENTE', ftCurrency);
  FResumen.FieldDefs.Add('HORAS_PREVISTAS', ftFloat);
  FResumen.FieldDefs.Add('HORAS_REALES', ftFloat);
  FResumen.FieldDefs.Add('HORAS_FACTURABLES', ftFloat);
  FResumen.FieldDefs.Add('UTILIZADO', ftFloat);
  FResumen.FieldDefs.Add('DEVUELTO', ftFloat);
  FResumen.CreateDataSet;
  FdsResumen := Origen(FResumen);
end;

procedure TDatosCircuitoOrden.AsignarMaestro(AMaestro: TDataSource);
begin
  FEnlace.DataSource := AMaestro;
  MaestroCambiado;
end;

procedure TDatosCircuitoOrden.MaestroCambiado;
var
  iOrden: Int64;
begin
  iOrden := 0;
  if FEnlace.Active and not FEnlace.DataSet.IsEmpty then
    iOrden := FEnlace.DataSet.FieldByName('ID_GAR').AsLargeInt;
  if iOrden <> FOrden then
  begin
    FOrden := iOrden;
    Refrescar;
  end;
end;

procedure TDatosCircuitoOrden.AbrirDetalle(AConsulta: TUniQuery);
begin
  AConsulta.Close;
  AConsulta.ParamByName('ORDEN').AsLargeInt := FOrden;
  AConsulta.Open;
end;

procedure TDatosCircuitoOrden.CargarResumen;
var
  oConsulta: TUniQuery;
  rReparto: TRepartoConceptoOrden;
  iLinea: Int64;
begin
  FResumen.EmptyDataSet;
  oConsulta := CrearConsulta('SELECT L.ID_GARLIN,L.DESCRIPCION_GARLIN,' +
    'COALESCE(C.VALOR_HORAS_PREVISTAS_RCC,0) AS PREVISTAS,' +
    'C.VALOR_HORAS_FACTURABLES_RCC AS FACTURABLES,' +
    'COALESCE((SELECT SUM(TIMESTAMPDIFF(SECOND,T.INSTANTE_INICIO_RCT,' +
    'COALESCE(T.INSTANTE_FIN_RCT,NOW())))/3600 ' +
    'FROM fza_reparaciones_tiempos T WHERE T.ID_GARLIN_RCT=L.ID_GARLIN ' +
    'AND T.ESANULADO_RCT=''N''),0) AS REALES,' +
    'COALESCE(M.CANTIDAD_UTILIZADA_RCM,0) AS UTILIZADO,' +
    'COALESCE(M.CANTIDAD_DEVUELTA_RCM,0) AS DEVUELTO ' +
    'FROM fza_garantias_lineas L LEFT JOIN fza_reparaciones_conceptos C ' +
    'ON C.ID_GARLIN_RCC=L.ID_GARLIN LEFT JOIN fza_reparaciones_materiales M ' +
    'ON M.ID_GARLIN_RCM=L.ID_GARLIN WHERE L.ID_GAR_GARLIN=:ORDEN');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := FOrden;
    oConsulta.Open;
    for rReparto in FCobertura.Reparto(FOrden) do
    begin
      iLinea := rReparto.Linea;
      if oConsulta.Locate('ID_GARLIN', iLinea, []) then
        FResumen.AppendRecord([iLinea, oConsulta.Fields[1].AsString,
          rReparto.Cliente + rReparto.Aseguradora + rReparto.Taller +
          rReparto.Pendiente, rReparto.Cliente, rReparto.Aseguradora,
          rReparto.Taller, rReparto.Pendiente,
          oConsulta.Fields[2].Value, oConsulta.Fields[4].Value,
          oConsulta.Fields[3].Value, oConsulta.Fields[5].Value,
          oConsulta.Fields[6].Value]);
    end;
    FResumen.First;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosCircuitoOrden.Refrescar;
begin
  if FDisponible and not FActualizando then
  begin
    FActualizando := True;
    FResumen.DisableControls;
    try
      CargarResumen;
      AbrirDetalle(FTiempos);
      AbrirDetalle(FMateriales);
      AbrirDetalle(FHistorial);
      AbrirDetalle(FDocumentos);
      AbrirDetalle(FExternos);
    finally
      FResumen.EnableControls;
      FActualizando := False;
    end;
  end;
end;

end.

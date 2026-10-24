{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGeneradorProcesosRepositorio                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia y ejecución del generador de procesos.                       }
{    El ejecutor corre en el hilo de la tarea sobre la conexión que se le      }
{    entregue y admite que otro hilo corte la sentencia en marcha.             }
{******************************************************************************}
unit UniDataGeneradorProcesosRepositorio;

interface

uses
  Data.DB,
  Uni,
  inLibGeneradorProcesosAplicacion;

// Ejecutor de scripts sobre la conexión indicada. La pantalla le pasa una
// conexión propia de segundo plano: así el script no ocupa la principal y
// se puede cortar sin dejar atrapada la sesión del usuario.
function CrearEjecutorProcesosUniDAC(
  AConexion: TUniConnection): IRepositorioGeneradorProcesos;
// Catálogo de la base de datos (metadatos, estructura y contenido)
// sobre la conexión de la pantalla: esto sí va en el hilo principal.
function CrearCatalogoGeneradorProcesosUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoGeneradorProcesos;
function ExtraerDatosResultadoProceso(
  const AResultado: IResultadoSentenciaProceso): TDataSet;

implementation

uses
  System.Classes,
  System.Diagnostics,
  System.SyncObjs,
  System.SysUtils,
  DAScript,
  inLibProteccionDatosFacturacion,
  UniScript;

type
  IResultadoSentenciaProcesoUniDAC = interface
    ['{68667238-E002-4D91-8ADC-83FEB0DB9377}']
    function ExtraerDatos: TDataSet;
  end;
  TResultadoSentenciaProcesoUniDAC = class(
    TInterfacedObject,
    IResultadoSentenciaProceso,
    IResultadoSentenciaProcesoUniDAC)
  private
    FConsulta: TUniQuery;
    FCorrecto: Boolean;
    FFilas: Integer;
    FMensajeError: string;
    FMilisegundos: Int64;
    FTieneDatos: Boolean;
  public
    destructor Destroy; override;
    function Correcto: Boolean;
    function TieneDatos: Boolean;
    function Filas: Integer;
    function Milisegundos: Int64;
    function MensajeError: string;
    function ExtraerDatos: TDataSet;
  end;
  // Ejecuta el script y deja que otro hilo lo corte. El objeto que está
  // trabajando se guarda bajo sección crítica: el hilo que cancela llama a
  // BreakExec sin que el de ejecución lo libere a la vez.
  TEjecutorProcesosUniDAC = class(
    TInterfacedObject,
    IRepositorioGeneradorProcesos)
  private
    FCancelacion: Integer;
    FConexion: TUniConnection;
    FConsultaActiva: TUniQuery;
    FScriptActivo: TUniScript;
    FSeccion: TCriticalSection;
    procedure AnotarConsultaActiva(AConsulta: TUniQuery);
    procedure AnotarScriptActivo(AScript: TUniScript);
    procedure CortarEjecucionActiva;
    procedure DevolverErrorScript(
      Sender: TObject;
      E: Exception;
      SQL: string;
      var Action: TErrorAction);
    procedure EjecutarComando(
      const ASentencia: string;
      AResultado: TResultadoSentenciaProcesoUniDAC);
    procedure EjecutarConsulta(
      const ASentencia: string;
      AResultado: TResultadoSentenciaProcesoUniDAC);
    function EsConsultaIndividual(const ASentencia: string): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function SepararSentencias(
      const AScript: string): TArray<string>;
    function EjecutarSentencia(
      const ASentencia: string;
      ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
    procedure PedirCancelacion;
    procedure OlvidarCancelacion;
    function CancelacionPedida: Boolean;
  end;
  TCatalogoGeneradorProcesosUniDAC = class(
    TInterfacedObject,
    ICatalogoGeneradorProcesos)
  private
    FConexion: TUniConnection;
    FContenido: TUniQuery;
    FEstructura: TUniQuery;
    FMetadatos: TUniQuery;
    FRefresco: TUniStoredProc;
  public
    constructor Create(
      AConexion: TUniConnection;
      AMetadatos, AEstructura, AContenido: TUniQuery;
      ARefresco: TUniStoredProc);
    procedure Refrescar(const ABaseDatos: string);
    function CargarEstructura(
      const ATipo, ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
    function GenerarLlamadaProcedimiento(
      const ANombre: string): string;
  end;

function IdentificadorSeguro(const AValor: string): string;
var
  I: Integer;
begin
  Result := Trim(AValor);
  if Result = '' then
    raise EArgumentException.Create('El identificador no puede estar vacío');
  for I := 1 to Length(Result) do
  begin
    if not CharInSet(Result[I], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      raise EArgumentException.CreateFmt(
        'Identificador de base de datos no válido: %s',
        [Result]);
  end;
end;

destructor TResultadoSentenciaProcesoUniDAC.Destroy;
begin
  FConsulta.Free;
  inherited;
end;

function TResultadoSentenciaProcesoUniDAC.Correcto: Boolean;
begin
  Result := FCorrecto;
end;

function TResultadoSentenciaProcesoUniDAC.TieneDatos: Boolean;
begin
  Result := FTieneDatos;
end;

function TResultadoSentenciaProcesoUniDAC.Filas: Integer;
begin
  Result := FFilas;
end;

function TResultadoSentenciaProcesoUniDAC.Milisegundos: Int64;
begin
  Result := FMilisegundos;
end;

function TResultadoSentenciaProcesoUniDAC.MensajeError: string;
begin
  Result := FMensajeError;
end;

function TResultadoSentenciaProcesoUniDAC.ExtraerDatos: TDataSet;
begin
  Result := FConsulta;
  FConsulta := nil;
end;

constructor TEjecutorProcesosUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FSeccion := TCriticalSection.Create;
end;

destructor TEjecutorProcesosUniDAC.Destroy;
begin
  FreeAndNil(FSeccion);
  inherited;
end;

procedure TEjecutorProcesosUniDAC.AnotarConsultaActiva(
  AConsulta: TUniQuery);
begin
  FSeccion.Enter;
  try
    FConsultaActiva := AConsulta;
  finally
    FSeccion.Leave;
  end;
end;

procedure TEjecutorProcesosUniDAC.AnotarScriptActivo(AScript: TUniScript);
begin
  FSeccion.Enter;
  try
    FScriptActivo := AScript;
  finally
    FSeccion.Leave;
  end;
end;

// La llama el hilo que cancela. El de ejecución no puede liberar el objeto
// mientras tanto porque lo desanota dentro de la misma sección.
procedure TEjecutorProcesosUniDAC.CortarEjecucionActiva;
begin
  FSeccion.Enter;
  try
    if Assigned(FConsultaActiva) then
      FConsultaActiva.BreakExec;
    if Assigned(FScriptActivo) then
      FScriptActivo.BreakExec;
  finally
    FSeccion.Leave;
  end;
end;

procedure TEjecutorProcesosUniDAC.PedirCancelacion;
begin
  AtomicExchange(FCancelacion, 1);
  CortarEjecucionActiva;
end;

procedure TEjecutorProcesosUniDAC.OlvidarCancelacion;
begin
  AtomicExchange(FCancelacion, 0);
end;

function TEjecutorProcesosUniDAC.CancelacionPedida: Boolean;
begin
  Result := AtomicCmpExchange(FCancelacion, 0, 0) <> 0;
end;

function TEjecutorProcesosUniDAC.SepararSentencias(
  const AScript: string): TArray<string>;
var
  I: Integer;
  Sentencia: string;
  Script: TUniScript;
begin
  Result := nil;
  if Trim(AScript) = '' then
  begin
  end
  else if Pos('DELIMITER ', UpperCase(AScript)) > 0 then
  begin
    SetLength(Result, 1);
    Result[0] := AScript;
  end
  else
  begin
    Script := TUniScript.Create(nil);
    try
      Script.Connection := FConexion;
      Script.SQL.Text := AScript;
      for I := 0 to Script.Statements.Count - 1 do
      begin
        Sentencia := Trim(Script.Statements[I].SQL);
        if PrimeraLineaUtilProceso(Sentencia) <> '' then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := Sentencia;
        end;
      end;
    except
      SetLength(Result, 1);
      Result[0] := AScript;
    end;
    Script.Free;
  end;
end;

function TEjecutorProcesosUniDAC.EsConsultaIndividual(
  const ASentencia: string): Boolean;
var
  Script: TUniScript;
begin
  Script := TUniScript.Create(nil);
  try
    Script.Connection := FConexion;
    Script.SQL.Text := ASentencia;
    // Un script con SELECT inicial y DELIMITER debe pasar completo por
    // TUniScript, que interpreta las directivas antes de enviar SQL.
    Result := Script.Statements.Count = 1;
  finally
    Script.Free;
  end;
end;

procedure TEjecutorProcesosUniDAC.EjecutarConsulta(
  const ASentencia: string;
  AResultado: TResultadoSentenciaProcesoUniDAC);
begin
  AResultado.FConsulta := TUniQuery.Create(nil);
  AResultado.FConsulta.Connection := FConexion;
  AResultado.FConsulta.SQL.Text := ASentencia;
  AResultado.FConsulta.ReadOnly :=
    SqlReferenciaTablaFacturacionProtegida(ASentencia);
  AnotarConsultaActiva(AResultado.FConsulta);
  try
    AResultado.FConsulta.Open;
  finally
    AnotarConsultaActiva(nil);
  end;
  AResultado.FTieneDatos := AResultado.FConsulta.FieldCount > 0;
  if AResultado.FTieneDatos then
    AResultado.FFilas := AResultado.FConsulta.RecordCount
  else
    AResultado.FFilas := AResultado.FConsulta.RowsAffected;
end;

// Sin OnError, TUniScript entrega el error a Application.HandleException,
// que abre la ventana de error de la aplicación desde el hilo del proceso:
// la VCL se interbloquea con el hilo principal (fuentes compartidas) y
// el programa queda colgado. El error se devuelve al hilo que ejecuta y
// el servicio decide con su pregunta sincronizada.
procedure TEjecutorProcesosUniDAC.DevolverErrorScript(
  Sender: TObject;
  E: Exception;
  SQL: string;
  var Action: TErrorAction);
begin
  Action := eaFail;
end;

procedure TEjecutorProcesosUniDAC.EjecutarComando(
  const ASentencia: string;
  AResultado: TResultadoSentenciaProcesoUniDAC);
var
  Script: TUniScript;
begin
  Script := TUniScript.Create(nil);
  try
    Script.Connection := FConexion;
    Script.OnError := DevolverErrorScript;
    Script.SQL.Text := ASentencia;
    AnotarScriptActivo(Script);
    try
      Script.Execute;
    finally
      AnotarScriptActivo(nil);
    end;
    AResultado.FFilas := Script.RowsAffected;
  finally
    Script.Free;
  end;
end;

function TEjecutorProcesosUniDAC.EjecutarSentencia(
  const ASentencia: string;
  ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
var
  Cronometro: TStopwatch;
  ResultadoUniDAC: TResultadoSentenciaProcesoUniDAC;
begin
  ResultadoUniDAC := TResultadoSentenciaProcesoUniDAC.Create;
  Result := ResultadoUniDAC;
  Cronometro := TStopwatch.StartNew;
  try
    try
      if (ATipo = tspConsulta) and EsConsultaIndividual(ASentencia) then
      begin
        try
          EjecutarConsulta(ASentencia, ResultadoUniDAC);
        except
          ResultadoUniDAC.FConsulta.Free;
          ResultadoUniDAC.FConsulta := nil;
          // Una consulta cortada no se reintenta como comando: se deja
          // subir el error para que el servicio cierre la ejecución.
          if CancelacionPedida then
            raise;
          EjecutarComando(ASentencia, ResultadoUniDAC);
        end;
      end
      else
        EjecutarComando(ASentencia, ResultadoUniDAC);
      ResultadoUniDAC.FCorrecto := True;
    except
      on E: Exception do
        ResultadoUniDAC.FMensajeError := E.Message;
    end;
  finally
    Cronometro.Stop;
    ResultadoUniDAC.FMilisegundos := Cronometro.ElapsedMilliseconds;
  end;
end;

constructor TCatalogoGeneradorProcesosUniDAC.Create(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(AMetadatos) then
    raise EArgumentNilException.Create('AMetadatos');
  if not Assigned(AEstructura) then
    raise EArgumentNilException.Create('AEstructura');
  if not Assigned(AContenido) then
    raise EArgumentNilException.Create('AContenido');
  if not Assigned(ARefresco) then
    raise EArgumentNilException.Create('ARefresco');
  FConexion := AConexion;
  FMetadatos := AMetadatos;
  FEstructura := AEstructura;
  FContenido := AContenido;
  FRefresco := ARefresco;
end;

procedure TCatalogoGeneradorProcesosUniDAC.Refrescar(
  const ABaseDatos: string);
begin
  FRefresco.ParamByName('pDATABASENAME').AsString := ABaseDatos;
  FRefresco.ExecProc;
  if FMetadatos.Active then
    FMetadatos.Refresh
  else
    FMetadatos.Open;
end;

function TCatalogoGeneradorProcesosUniDAC.CargarEstructura(
  const ATipo, ANombre: string): string;
var
  CampoResultado: string;
begin
  Result := '';
  FEstructura.Close;
  if ATipo = '1' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create Table';
  end
  else if ATipo = '2' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create View';
  end
  else if ATipo = '3' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create Procedure';
  end
  else
    CampoResultado := '';
  if CampoResultado <> '' then
  begin
    FEstructura.Open;
    Result := FEstructura.FieldByName(CampoResultado).AsString;
  end;
end;

procedure TCatalogoGeneradorProcesosUniDAC.CargarContenido(
  const ANombre: string);
begin
  FContenido.Close;
  FContenido.ReadOnly := EsTablaFacturacionProtegida(ANombre);
  FContenido.SQL.Text := 'SELECT * FROM ' +
    IdentificadorSeguro(ANombre) + ' LIMIT 1000';
  FContenido.Open;
end;

function TCatalogoGeneradorProcesosUniDAC.
  GenerarLlamadaProcedimiento(const ANombre: string): string;
var
  Consulta: TUniQuery;
  NombreSeguro: string;
begin
  NombreSeguro := IdentificadorSeguro(ANombre);
  Result := 'CALL ' + NombreSeguro + '(';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT PARAMETER_NAME, DTD_IDENTIFIER ' +
      'FROM information_schema.parameters ' +
      'WHERE SPECIFIC_NAME = :ProcName ' +
      'AND ROUTINE_TYPE = ''PROCEDURE'' ' +
      'ORDER BY ORDINAL_POSITION';
    Consulta.ParamByName('ProcName').AsString := NombreSeguro;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Result := Result + '/* ' +
        Consulta.FieldByName('PARAMETER_NAME').AsString + ' ' +
        Consulta.FieldByName('DTD_IDENTIFIER').AsString + ' */';
      Consulta.Next;
      if not Consulta.Eof then
        Result := Result + ', ';
    end;
  finally
    Consulta.Free;
  end;
  Result := Result + ');';
end;

function CrearEjecutorProcesosUniDAC(
  AConexion: TUniConnection): IRepositorioGeneradorProcesos;
begin
  Result := TEjecutorProcesosUniDAC.Create(AConexion);
end;

function CrearCatalogoGeneradorProcesosUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoGeneradorProcesos;
begin
  Result := TCatalogoGeneradorProcesosUniDAC.Create(
    AConexion,
    AMetadatos,
    AEstructura,
    AContenido,
    ARefresco);
end;

function ExtraerDatosResultadoProceso(
  const AResultado: IResultadoSentenciaProceso): TDataSet;
var
  ResultadoUniDAC: IResultadoSentenciaProcesoUniDAC;
begin
  Result := nil;
  if AResultado <> nil then
  begin
    try
      ResultadoUniDAC :=
        AResultado as IResultadoSentenciaProcesoUniDAC;
      Result := ResultadoUniDAC.ExtraerDatos;
    except
      on EIntfCastError do
        Result := nil;
    end;
  end;
end;

end.

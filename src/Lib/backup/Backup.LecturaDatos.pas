{******************************************************************************}
{                                                                              }
{  Módulo:       Backup.LecturaDatos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lee y escribe datos de una tabla sin materializarla por completo.         }
{******************************************************************************}
unit Backup.LecturaDatos;

interface

uses
  System.Classes,
  Core_Interfaces,
  Backup.Types;

type
  TProgresoLecturaDatosBackupEvent = procedure(
    const AEtapa: string; APaso, ATotal: Integer) of object;
  TFilaLeidaDatosBackupEvent = procedure of object;

  TDependenciasLecturaDatosBackup = record
    Esquema: ILectorEsquemaBBDD;
    Datos: ILectorDatosBBDD;
    Escritor: IScriptWriter;
    Valores: IGeneradorSqlValores;
    class function Crear(
      const AEsquema: ILectorEsquemaBBDD;
      const ADatos: ILectorDatosBBDD;
      const AEscritor: IScriptWriter;
      const AValores: IGeneradorSqlValores):
      TDependenciasLecturaDatosBackup; static;
  end;

  TConfiguracionLecturaDatosBackup = record
    InsertExtendido: Boolean;
    FilasPorLote: Integer;
    class function Crear(
      AInsertExtendido: Boolean;
      AFilasPorLote: Integer): TConfiguracionLecturaDatosBackup; static;
  end;

  TLecturaDatosTablaBackup = class
  private
    FDependencias: TDependenciasLecturaDatosBackup;
    FConfiguracion: TConfiguracionLecturaDatosBackup;
    FOnProgreso: TProgresoLecturaDatosBackupEvent;
    FOnFilaLeida: TFilaLeidaDatosBackupEvent;
  public
    constructor Create(
      const ADependencias: TDependenciasLecturaDatosBackup;
      const AConfiguracion: TConfiguracionLecturaDatosBackup;
      AOnProgreso: TProgresoLecturaDatosBackupEvent;
      AOnFilaLeida: TFilaLeidaDatosBackupEvent);
    procedure Ejecutar(
      const ANombreTabla, AFiltro: string);
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Data.DB;

const
  MAX_BYTES_LOTE_EXTENDIDO = 1024 * 1024;

type
  TValidadorLecturaDatosBackup = class
  public
    class procedure ValidarDependencias(
      const ADependencias: TDependenciasLecturaDatosBackup); static;
    class procedure ValidarDataSet(ADataSet: TDataSet); static;
  end;

  TTransformadorFilaDatosBackup = class
  private
    FNombreTabla: string;
    FValoresSql: IGeneradorSqlValores;
    FCampos: TStringList;
    FValores: TStringList;
    function Unir(const APartes: TStrings): string;
  public
    constructor Create(
      const ANombreTabla: string;
      const AValoresSql: IGeneradorSqlValores);
    destructor Destroy; override;
    procedure LeerFila(ADataSet: TDataSet);
    function CrearCabeceraExtendida: string;
    function CrearValoresFila: string;
    function CrearInsertClasico(ATieneAutoincremento: Boolean): string;
  end;

  TEscritorLotesDatosBackup = class
  private
    FEscritor: IScriptWriter;
    FCabecera: string;
    FFilas: TStringList;
    FLimiteFilas: Integer;
    FBytesLote: Integer;
    function ConstruirSentencia: string;
    function SuperaLimite(ABytesFila: Integer): Boolean;
  public
    constructor Create(
      const AEscritor: IScriptWriter;
      const ACabecera: string;
      ALimiteFilas: Integer);
    destructor Destroy; override;
    procedure Agregar(const AValores: string);
    procedure EscribirClasico(const ASQL: string);
    procedure Volcar;
  end;

  TProcesoLecturaDatosBackup = class
  private
    FDependencias: TDependenciasLecturaDatosBackup;
    FConfiguracion: TConfiguracionLecturaDatosBackup;
    FOnProgreso: TProgresoLecturaDatosBackupEvent;
    FOnFilaLeida: TFilaLeidaDatosBackupEvent;
    FNombreTabla: string;
    FFiltro: string;
    FDataSet: TDataSet;
    FTransformador: TTransformadorFilaDatosBackup;
    FEscritorLotes: TEscritorLotesDatosBackup;
    FTieneAutoincremento: Boolean;
    FFilas: Integer;
    FTotal: Integer;
    FFrecuenciaProgreso: Integer;
    function TieneAutoincremento: Boolean;
    procedure AbrirLectura;
    procedure CrearColaboradores;
    procedure EscribirInicio;
    procedure ProcesarFilas;
    procedure ProcesarFila;
    procedure EscribirFin;
    procedure NotificarProgreso(
      const AEtapa: string; APaso, ATotal: Integer);
    procedure NotificarFilaLeida;
  public
    constructor Create(
      const ADependencias: TDependenciasLecturaDatosBackup;
      const AConfiguracion: TConfiguracionLecturaDatosBackup;
      AOnProgreso: TProgresoLecturaDatosBackupEvent;
      AOnFilaLeida: TFilaLeidaDatosBackupEvent;
      const ANombreTabla, AFiltro: string);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

class function TDependenciasLecturaDatosBackup.Crear(
  const AEsquema: ILectorEsquemaBBDD;
  const ADatos: ILectorDatosBBDD;
  const AEscritor: IScriptWriter;
  const AValores: IGeneradorSqlValores):
  TDependenciasLecturaDatosBackup;
begin
  Result.Esquema := AEsquema;
  Result.Datos := ADatos;
  Result.Escritor := AEscritor;
  Result.Valores := AValores;
end;

class function TConfiguracionLecturaDatosBackup.Crear(
  AInsertExtendido: Boolean;
  AFilasPorLote: Integer): TConfiguracionLecturaDatosBackup;
begin
  Result.InsertExtendido := AInsertExtendido;
  Result.FilasPorLote := AFilasPorLote;
end;

class procedure TValidadorLecturaDatosBackup.ValidarDependencias(
  const ADependencias: TDependenciasLecturaDatosBackup);
begin
  if not Assigned(ADependencias.Esquema) then
  begin
    raise EArgumentNilException.Create('ADependencias.Esquema');
  end;
  if not Assigned(ADependencias.Datos) then
  begin
    raise EArgumentNilException.Create('ADependencias.Datos');
  end;
  if not Assigned(ADependencias.Escritor) then
  begin
    raise EArgumentNilException.Create('ADependencias.Escritor');
  end;
  if not Assigned(ADependencias.Valores) then
  begin
    raise EArgumentNilException.Create('ADependencias.Valores');
  end;
end;

class procedure TValidadorLecturaDatosBackup.ValidarDataSet(
  ADataSet: TDataSet);
begin
  if not Assigned(ADataSet) then
  begin
    raise EArgumentNilException.Create('ADataSet');
  end;
end;

constructor TTransformadorFilaDatosBackup.Create(
  const ANombreTabla: string;
  const AValoresSql: IGeneradorSqlValores);
begin
  inherited Create;
  FNombreTabla := ANombreTabla;
  FValoresSql := AValoresSql;
  FCampos := TStringList.Create;
  FValores := TStringList.Create;
end;

destructor TTransformadorFilaDatosBackup.Destroy;
begin
  FreeAndNil(FValores);
  FreeAndNil(FCampos);
  inherited Destroy;
end;

procedure TTransformadorFilaDatosBackup.LeerFila(ADataSet: TDataSet);
var
  I: Integer;
begin
  FCampos.Clear;
  FValores.Clear;
  for I := 0 to ADataSet.FieldCount - 1 do
  begin
    FCampos.Add(
      FValoresSql.QuoteIdentifier(ADataSet.Fields[I].FieldName));
    FValores.Add(FValoresSql.ValueToSQL(ADataSet.Fields[I]));
  end;
end;

function TTransformadorFilaDatosBackup.Unir(
  const APartes: TStrings): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to APartes.Count - 1 do
  begin
    if I > 0 then
    begin
      Result := Result + ', ';
    end;
    Result := Result + APartes[I];
  end;
end;

function TTransformadorFilaDatosBackup.CrearCabeceraExtendida: string;
begin
  Result := 'INSERT INTO ' +
    FValoresSql.QuoteIdentifier(FNombreTabla) +
    ' (' + Unir(FCampos) + ') VALUES';
end;

function TTransformadorFilaDatosBackup.CrearValoresFila: string;
begin
  Result := Unir(FValores);
end;

function TTransformadorFilaDatosBackup.CrearInsertClasico(
  ATieneAutoincremento: Boolean): string;
begin
  Result := FValoresSql.GenerateInsertSQL(
    FNombreTabla,
    FCampos,
    FValores,
    ATieneAutoincremento);
end;

constructor TEscritorLotesDatosBackup.Create(
  const AEscritor: IScriptWriter;
  const ACabecera: string;
  ALimiteFilas: Integer);
begin
  inherited Create;
  FEscritor := AEscritor;
  FCabecera := ACabecera;
  FLimiteFilas := ALimiteFilas;
  FFilas := TStringList.Create;
end;

destructor TEscritorLotesDatosBackup.Destroy;
begin
  FreeAndNil(FFilas);
  inherited Destroy;
end;

function TEscritorLotesDatosBackup.SuperaLimite(
  ABytesFila: Integer): Boolean;
begin
  Result := (FBytesLote > 0) and
    ((FBytesLote + ABytesFila) > MAX_BYTES_LOTE_EXTENDIDO);
end;

procedure TEscritorLotesDatosBackup.Agregar(const AValores: string);
var
  iBytesFila: Integer;
begin
  iBytesFila := TEncoding.UTF8.GetByteCount(AValores);
  if SuperaLimite(iBytesFila) then
  begin
    Volcar;
  end;
  FFilas.Add(AValores);
  Inc(FBytesLote, iBytesFila);
  if (FLimiteFilas > 0) and (FFilas.Count >= FLimiteFilas) then
  begin
    Volcar;
  end;
end;

procedure TEscritorLotesDatosBackup.EscribirClasico(
  const ASQL: string);
begin
  FEscritor.AddCommand(ASQL);
end;

function TEscritorLotesDatosBackup.ConstruirSentencia: string;
var
  I: Integer;
  oSQL: TStringBuilder;
begin
  oSQL := TStringBuilder.Create(
    Length(FCabecera) + FBytesLote + (FFilas.Count * 8));
  try
    oSQL.Append(FCabecera);
    oSQL.Append(sLineBreak);
    for I := 0 to FFilas.Count - 1 do
    begin
      oSQL.Append('  (');
      oSQL.Append(FFilas[I]);
      if I < FFilas.Count - 1 then
      begin
        oSQL.Append('),');
        oSQL.Append(sLineBreak);
      end
      else
      begin
        oSQL.Append(');');
      end;
    end;
    Result := oSQL.ToString;
  finally
    FreeAndNil(oSQL);
  end;
end;

procedure TEscritorLotesDatosBackup.Volcar;
begin
  if FFilas.Count > 0 then
  begin
    FEscritor.AddCommand(ConstruirSentencia);
    FFilas.Clear;
    FBytesLote := 0;
  end;
end;

constructor TLecturaDatosTablaBackup.Create(
  const ADependencias: TDependenciasLecturaDatosBackup;
  const AConfiguracion: TConfiguracionLecturaDatosBackup;
  AOnProgreso: TProgresoLecturaDatosBackupEvent;
  AOnFilaLeida: TFilaLeidaDatosBackupEvent);
begin
  inherited Create;
  TValidadorLecturaDatosBackup.ValidarDependencias(ADependencias);
  FDependencias := ADependencias;
  FConfiguracion := AConfiguracion;
  FOnProgreso := AOnProgreso;
  FOnFilaLeida := AOnFilaLeida;
end;

constructor TProcesoLecturaDatosBackup.Create(
  const ADependencias: TDependenciasLecturaDatosBackup;
  const AConfiguracion: TConfiguracionLecturaDatosBackup;
  AOnProgreso: TProgresoLecturaDatosBackupEvent;
  AOnFilaLeida: TFilaLeidaDatosBackupEvent;
  const ANombreTabla, AFiltro: string);
begin
  inherited Create;
  FDependencias := ADependencias;
  FConfiguracion := AConfiguracion;
  FOnProgreso := AOnProgreso;
  FOnFilaLeida := AOnFilaLeida;
  FNombreTabla := ANombreTabla;
  FFiltro := AFiltro;
end;

destructor TProcesoLecturaDatosBackup.Destroy;
begin
  FreeAndNil(FEscritorLotes);
  FreeAndNil(FTransformador);
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TProcesoLecturaDatosBackup.TieneAutoincremento: Boolean;
var
  I: Integer;
  oTabla: TTableInfo;
begin
  Result := False;
  oTabla := FDependencias.Esquema.GetTableStructure(FNombreTabla);
  try
    for I := 0 to oTabla.Columns.Count - 1 do
    begin
      if ContainsText(oTabla.Columns[I].Extra, 'auto_increment') then
      begin
        Result := True;
      end;
    end;
  finally
    FreeAndNil(oTabla);
  end;
end;

procedure TProcesoLecturaDatosBackup.AbrirLectura;
begin
  FTieneAutoincremento := TieneAutoincremento;
  FTotal := FDependencias.Datos.GetRowCount(FNombreTabla, FFiltro);
  FDataSet := FDependencias.Datos.GetData(FNombreTabla, FFiltro);
  TValidadorLecturaDatosBackup.ValidarDataSet(FDataSet);
  FFrecuenciaProgreso := FTotal div 100;
  if FFrecuenciaProgreso < 1 then
  begin
    FFrecuenciaProgreso := 1;
  end;
end;

procedure TProcesoLecturaDatosBackup.CrearColaboradores;
begin
  FTransformador := TTransformadorFilaDatosBackup.Create(
    FNombreTabla,
    FDependencias.Valores);
end;

procedure TProcesoLecturaDatosBackup.EscribirInicio;
begin
  FDependencias.Escritor.AddComment(
    Format('Datos de %s', [FNombreTabla]));
  if FTieneAutoincremento then
  begin
    FDependencias.Escritor.AddCommand(Format(
      '/*!40000 ALTER TABLE %s DISABLE KEYS */;',
      [FDependencias.Valores.QuoteIdentifier(FNombreTabla)]));
  end;
end;

procedure TProcesoLecturaDatosBackup.ProcesarFila;
begin
  Inc(FFilas);
  NotificarFilaLeida;
  FTransformador.LeerFila(FDataSet);
  if not Assigned(FEscritorLotes) then
  begin
    FEscritorLotes := TEscritorLotesDatosBackup.Create(
      FDependencias.Escritor,
      FTransformador.CrearCabeceraExtendida,
      FConfiguracion.FilasPorLote);
  end;
  if FConfiguracion.InsertExtendido then
  begin
    FEscritorLotes.Agregar(FTransformador.CrearValoresFila);
  end
  else
  begin
    FEscritorLotes.EscribirClasico(
      FTransformador.CrearInsertClasico(FTieneAutoincremento));
  end;
  FDataSet.Next;
  if ((FFilas mod FFrecuenciaProgreso) = 0) or FDataSet.Eof then
  begin
    NotificarProgreso(FNombreTabla + ' (datos)', FFilas, FTotal);
  end;
end;

procedure TProcesoLecturaDatosBackup.ProcesarFilas;
begin
  while not FDataSet.Eof do
  begin
    ProcesarFila;
  end;
  if FConfiguracion.InsertExtendido then
  begin
    FEscritorLotes.Volcar;
  end;
end;

procedure TProcesoLecturaDatosBackup.EscribirFin;
begin
  NotificarProgreso(FNombreTabla + ' OK', FFilas, FFilas);
  if FTieneAutoincremento then
  begin
    FDependencias.Escritor.AddCommand(Format(
      '/*!40000 ALTER TABLE %s ENABLE KEYS */;',
      [FDependencias.Valores.QuoteIdentifier(FNombreTabla)]));
  end;
  FDependencias.Escritor.AddComment(
    Format('%d registros exportados', [FFilas]));
  FDependencias.Escritor.AddCommand('');
end;

procedure TProcesoLecturaDatosBackup.NotificarProgreso(
  const AEtapa: string; APaso, ATotal: Integer);
begin
  if Assigned(FOnProgreso) then
  begin
    FOnProgreso(AEtapa, APaso, ATotal);
  end;
end;

procedure TProcesoLecturaDatosBackup.NotificarFilaLeida;
begin
  if Assigned(FOnFilaLeida) then
  begin
    FOnFilaLeida;
  end;
end;

procedure TProcesoLecturaDatosBackup.Ejecutar;
begin
  AbrirLectura;
  NotificarProgreso(FNombreTabla + ' (datos)', 0, FTotal);
  if not FDataSet.IsEmpty then
  begin
    EscribirInicio;
    CrearColaboradores;
    ProcesarFilas;
    EscribirFin;
  end;
end;

procedure TLecturaDatosTablaBackup.Ejecutar(
  const ANombreTabla, AFiltro: string);
var
  oProceso: TProcesoLecturaDatosBackup;
begin
  oProceso := TProcesoLecturaDatosBackup.Create(
    FDependencias,
    FConfiguracion,
    FOnProgreso,
    FOnFilaLeida,
    ANombreTabla,
    AFiltro);
  try
    oProceso.Ejecutar;
  finally
    FreeAndNil(oProceso);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibValoresAutomaticos                                      }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve series, contadores y valores configurados por defecto.           }
{******************************************************************************}
unit inLibValoresAutomaticos;

interface

uses
  System.Classes, Data.DB,
  inLibValoresAutomaticosPersistenciaIntf;

function ObtenerSeriePropiaAlmacen(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
function ObtenerSerieDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento: string;
  const AAlmacen: string = ''): string;
procedure CargarSeriesEmpresa(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento: string;
  AElementos: TStrings);
function IntentarObtenerSiguienteContador(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATipoDocumento, AUsuario: string):
  TResultadoContadorAutomatico;
function ObtenerSiguienteContador(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATipoDocumento, AUsuario: string): string;
function ObtenerValorPorDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATabla, ACampo, ACampoCondicion: string): string;
procedure AsignarValorPorDefecto(ADataSet: TDataSet;
  const ACampo, AValor, ATipoDato: string);
procedure AplicarValoresPorDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);

implementation

uses
  System.SysUtils;

function HayDatosSerie(const AEmpresa, ATipoDocumento: string): Boolean;
begin
  Result :=
    (Trim(AEmpresa) <> '') and
    (Trim(ATipoDocumento) <> '');
end;

function ObtenerSeriePropiaAlmacen(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := '';
  if Assigned(ARepositorio) and
     HayDatosSerie(AEmpresa, ATipoDocumento) and
     (Trim(AAlmacen) <> '') then
  begin
    Result := ARepositorio.ObtenerSeriePropiaAlmacen(
      AEmpresa, ATipoDocumento, AAlmacen);
  end;
end;

function ObtenerSerieDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := '';
  if Assigned(ARepositorio) and
     HayDatosSerie(AEmpresa, ATipoDocumento) then
  begin
    Result := ARepositorio.ObtenerSerieDefecto(
      AEmpresa, ATipoDocumento, AAlmacen);
  end;
end;

procedure CargarSeriesEmpresa(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const AEmpresa, ATipoDocumento: string;
  AElementos: TStrings);
begin
  AElementos.Clear;
  if Assigned(ARepositorio) and
     HayDatosSerie(AEmpresa, ATipoDocumento) then
  begin
    ARepositorio.CargarSeriesEmpresa(
      AEmpresa, ATipoDocumento, AElementos);
  end;
end;

function IntentarObtenerSiguienteContador(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATipoDocumento, AUsuario: string):
  TResultadoContadorAutomatico;
begin
  if Assigned(ARepositorio) then
  begin
    Result := ARepositorio.ObtenerSiguienteContador(
      ATipoDocumento, AUsuario);
  end
  else
  begin
    Result := TResultadoContadorAutomatico.Fallido(
      evaConexionNoDisponible,
      'No se ha configurado el repositorio de valores automáticos.');
  end;
end;

function ObtenerSiguienteContador(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATipoDocumento, AUsuario: string): string;
var
  oResultado: TResultadoContadorAutomatico;
begin
  oResultado := IntentarObtenerSiguienteContador(
    ARepositorio, ATipoDocumento, AUsuario);
  if not oResultado.Exito then
  begin
    raise EValoresAutomaticosPersistencia.Create(
      oResultado.Error, oResultado.Detalle);
  end;
  Result := oResultado.Valor;
end;

function ObtenerValorPorDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  const ATabla, ACampo, ACampoCondicion: string): string;
begin
  Result := '';
  if Assigned(ARepositorio) then
  begin
    Result := ARepositorio.ObtenerValorPorDefecto(
      ATabla, ACampo, ACampoCondicion);
  end;
end;

procedure AsignarValorPorDefecto(ADataSet: TDataSet;
  const ACampo, AValor, ATipoDato: string);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
  begin
    if ATipoDato = 'INTEGER' then
      oCampo.AsInteger := StrToIntDef(AValor, 0)
    else if ATipoDato = 'FLOAT' then
      oCampo.AsFloat := StrToFloatDef(AValor, 0)
    else
      oCampo.AsString := AValor;
  end;
end;

procedure AplicarValoresPorDefecto(
  const ARepositorio: IRepositorioValoresAutomaticos;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);
var
  i: Integer;
  oValores: TArray<TValorPorDefectoPersistido>;
begin
  if not (ADataSetDestino.State in [dsInsert, dsEdit]) then
    ADataSetDestino.Edit;
  if Assigned(ARepositorio) then
  begin
    oValores := ARepositorio.CargarValoresPorDefecto(ANombreTabla);
    for i := 0 to Length(oValores) - 1 do
    begin
      AsignarValorPorDefecto(
        ADataSetDestino,
        oValores[i].Campo,
        oValores[i].Valor,
        oValores[i].TipoDato);
    end;
  end;
end;

end.

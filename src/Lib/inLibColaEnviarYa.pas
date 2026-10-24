{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColaEnviarYa                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    «Enviar ya» de las colas (FZ-ISSUE-310): qué filas se reactivan y la      }
{    sentencia que las pone a enviar sin esperar al próximo intento. Sin VCL   }
{    ni base de datos: lo prueba DUnitX.                                       }
{******************************************************************************}
unit inLibColaEnviarYa;

interface

type
  // Tabla de una cola y cómo se reactiva una fila con error
  TDefinicionColaEnviarYa = record
    Tabla: string;
    CampoId: string;
    CampoEstado: string;
    CampoIntentos: string;
    CampoProximoIntento: string;
    // Estados que esperan turno: solo se adelanta su próximo intento
    EstadosPendientes: TArray<string>;
    EstadoError: string;
    // Expresión SQL con el estado al que vuelve una fila con error
    ExpresionEstadoReactivado: string;
    ParametroMaxIntentos: string;
    MaxIntentosDefecto: Integer;
  end;

  TFilaColaEnviarYa = record
    Id: Int64;
    Estado: string;
  end;

function DefinicionColaVerifactu: TDefinicionColaEnviarYa;
function DefinicionColaPrestaShop: TDefinicionColaEnviarYa;
function DefinicionColaVentasWs: TDefinicionColaEnviarYa;

// True si «Enviar ya» actúa sobre una fila en AEstado: pendientes y con
// error. Las enviadas y las que se están procesando no se tocan.
function EsEstadoEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AEstado: string): Boolean;
// Identificadores de AFilas en estado de «Enviar ya», sin repetir
function IdsEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AFilas: TArray<TFilaColaEnviarYa>): TArray<Int64>;
// Intentos que quedan tras «Enviar ya»: una fila con error que agotó el
// máximo se deja con margen para un intento más; el resto no cambia.
function IntentosTrasEnviarYa(AEsError: Boolean;
  AIntentos, AMaxIntentos: Integer): Integer;
// UPDATE con los parámetros :MAXINTENTOS y :USUARIO. Repite el filtro de
// estado: lo que otro puesto haya enviado entretanto no se toca. Los
// intentos se asignan antes que el estado porque MariaDB evalúa el SET de
// izquierda a derecha con los valores ya asignados.
function SqlEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AIds: TArray<Int64>): string;

implementation

uses
  System.SysUtils, System.Generics.Collections;

function DefinicionColaVerifactu: TDefinicionColaEnviarYa;
begin
  Result := Default(TDefinicionColaEnviarYa);
  Result.Tabla := 'fza_verifactu_cola';
  Result.CampoId := 'ID_VFCOLA';
  Result.CampoEstado := 'ESTADO_VFCOLA';
  Result.CampoIntentos := 'CONTADOR_INTENTOS_VFCOLA';
  Result.CampoProximoIntento := 'INSTANTE_PROXIMO_INTENTO_VFCOLA';
  Result.EstadosPendientes := ['PENDIENTE'];
  Result.EstadoError := 'ERROR';
  Result.ExpresionEstadoReactivado := '''PENDIENTE''';
  Result.ParametroMaxIntentos := 'appVerifactuMaxIntentos';
  Result.MaxIntentosDefecto := 10;
end;

function DefinicionColaPrestaShop: TDefinicionColaEnviarYa;
begin
  Result := Default(TDefinicionColaEnviarYa);
  Result.Tabla := 'fza_prestashop_cola';
  Result.CampoId := 'ID_PSCOLA';
  Result.CampoEstado := 'ESTADO_PSCOLA';
  Result.CampoIntentos := 'CONTADOR_INTENTOS_PSCOLA';
  Result.CampoProximoIntento := 'INSTANTE_PROXIMO_INTENTO_PSCOLA';
  Result.EstadosPendientes := ['PENDIENTE', 'PENDIENTE_VISIBILIDAD'];
  Result.EstadoError := 'ERROR';
  // Mismo criterio que el reintento del procesador (GuardarErrorIntento)
  Result.ExpresionEstadoReactivado :=
    'CASE WHEN ACCION_VISIBILIDAD_PSCOLA IN (''A'', ''D'') ' +
    'THEN ''PENDIENTE_VISIBILIDAD'' ELSE ''PENDIENTE'' END';
  Result.ParametroMaxIntentos := 'appPrestaShopMaxIntentos';
  Result.MaxIntentosDefecto := 10;
end;

function DefinicionColaVentasWs: TDefinicionColaEnviarYa;
begin
  Result := Default(TDefinicionColaEnviarYa);
  Result.Tabla := 'fza_ventas_ws_cola';
  Result.CampoId := 'ID_VWSC';
  Result.CampoEstado := 'ESTADO_VWSC';
  Result.CampoIntentos := 'CONTADOR_INTENTOS_VWSC';
  Result.CampoProximoIntento := 'INSTANTE_PROXIMO_INTENTO_VWSC';
  Result.EstadosPendientes := ['PENDIENTE'];
  Result.EstadoError := 'ERROR';
  Result.ExpresionEstadoReactivado := '''PENDIENTE''';
  Result.ParametroMaxIntentos := 'appVentasWsMaxIntentos';
  Result.MaxIntentosDefecto := 20;
end;

function EsEstadoEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AEstado: string): Boolean;
var
  sEstado: string;
  sPendiente: string;
begin
  sEstado := UpperCase(Trim(AEstado));
  Result := sEstado = ADefinicion.EstadoError;
  if not Result then
    for sPendiente in ADefinicion.EstadosPendientes do
      if sEstado = sPendiente then
        Exit(True);
end;

function IdsEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AFilas: TArray<TFilaColaEnviarYa>): TArray<Int64>;
var
  oVistos: TDictionary<Int64, Boolean>;
  oFila: TFilaColaEnviarYa;
  iTotal: Integer;
begin
  SetLength(Result, Length(AFilas));
  iTotal := 0;
  oVistos := TDictionary<Int64, Boolean>.Create;
  try
    for oFila in AFilas do
      if (oFila.Id > 0) and EsEstadoEnviarYa(ADefinicion, oFila.Estado) and
         not oVistos.ContainsKey(oFila.Id) then
      begin
        oVistos.Add(oFila.Id, True);
        Result[iTotal] := oFila.Id;
        Inc(iTotal);
      end;
  finally
    FreeAndNil(oVistos);
  end;
  SetLength(Result, iTotal);
end;

function IntentosTrasEnviarYa(AEsError: Boolean;
  AIntentos, AMaxIntentos: Integer): Integer;
begin
  Result := AIntentos;
  if AEsError and (AIntentos >= AMaxIntentos) then
  begin
    Result := AMaxIntentos - 1;
    if Result < 0 then
      Result := 0;
  end;
end;

function ListaTextos(const AValores: TArray<string>): string;
var
  sValor: string;
begin
  Result := '';
  for sValor in AValores do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + QuotedStr(sValor);
  end;
end;

function ListaIds(const AIds: TArray<Int64>): string;
var
  iId: Int64;
begin
  Result := '';
  for iId in AIds do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + IntToStr(iId);
  end;
end;

function SqlEnviarYa(const ADefinicion: TDefinicionColaEnviarYa;
  const AIds: TArray<Int64>): string;
var
  sEsError: string;
begin
  if Length(AIds) = 0 then
    raise EArgumentException.Create('AIds');
  sEsError := ADefinicion.CampoEstado + ' = ' +
    QuotedStr(ADefinicion.EstadoError);
  Result :=
    'UPDATE ' + ADefinicion.Tabla + ' SET ' +
    ADefinicion.CampoIntentos + ' = CASE WHEN ' + sEsError + ' AND ' +
    ADefinicion.CampoIntentos + ' >= :MAXINTENTOS ' +
    'THEN GREATEST(:MAXINTENTOS - 1, 0) ' +
    'ELSE ' + ADefinicion.CampoIntentos + ' END, ' +
    ADefinicion.CampoProximoIntento + ' = NULL, ' +
    ADefinicion.CampoEstado + ' = CASE WHEN ' + sEsError + ' THEN ' +
    ADefinicion.ExpresionEstadoReactivado + ' ' +
    'ELSE ' + ADefinicion.CampoEstado + ' END, ' +
    'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    'WHERE ' + ADefinicion.CampoId + ' IN (' + ListaIds(AIds) + ') ' +
    'AND ' + ADefinicion.CampoEstado + ' IN (' +
    ListaTextos(ADefinicion.EstadosPendientes + [ADefinicion.EstadoError]) +
    ')';
end;

end.

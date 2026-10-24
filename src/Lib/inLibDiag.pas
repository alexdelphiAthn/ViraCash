{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDiag                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       24/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de diagnóstico para verificar el cableado de manejo            }
{    de excepciones (JCL stack trace + AppException + log + modal).            }
{                                                                              }
{    Uso: arrancar vcash.exe con el switch /teststack. Tras el                  }
{    arranque del form principal se encola una excepción de prueba             }
{    con varios niveles de llamada para que el stack tenga frames              }
{    visibles y se distinga si JCL está rellenando E.StackTrace.               }
{    También detecta campos booleanos ES* con metadata numérica incompatible.  }
{                                                                              }
{    Directivas locales: forzamos sin optimización, con stack frames           }
{    y sin inlining para que cada capa intermedia aparezca como                }
{    frame propio en el volcado de pila (de lo contrario el                    }
{    compilador colapsa las llamadas triviales).                               }
{******************************************************************************}
unit inLibDiag;

{$O-}
{$STACKFRAMES ON}
{$INLINE OFF}

interface

uses
  Data.DB, inLibLogIntf;

type
  TIncidenciaMetadataCampo = record
    NombreCampo: string;
    TipoCampo: TFieldType;
  end;

  TIncidenciasMetadataCampos =
    TArray<TIncidenciaMetadataCampo>;

procedure ProbarStackTrace;
function DetectarCamposBooleanosNumericos(
  ADataSet: TDataSet): TIncidenciasMetadataCampos;
function MensajeCampoBooleanoNumerico(
  const AContexto: string;
  const AIncidencia: TIncidenciaMetadataCampo): string;
procedure DiagnosticarCamposBooleanos(
  ADataSet: TDataSet;
  const AContexto: string;
  const ARegistroLog: IRegistroLog);

implementation

uses
  System.SysUtils, System.StrUtils, System.TypInfo,
  inLibMsgIntegraciones;

// Cada capa concatena su nombre a la traza para que el compilador
// no pueda colapsar la llamada (tail call) ni inlinearla. Así
// el stack trace muestra los 4 frames de la cadena.

procedure LanzarExcepcionProfunda(const ATraza: string);
begin
  raise Exception.CreateFmt(SErrorPruebaPilaJcl, [ATraza]);
end;

procedure CapaProfunda(const ATraza: string);
begin
  LanzarExcepcionProfunda(ATraza + ' -> profunda');
end;

procedure CapaMedia(const ATraza: string);
begin
  CapaProfunda(ATraza + ' -> media');
end;

procedure CapaSuperficial(const ATraza: string);
begin
  CapaMedia(ATraza + ' -> superficial');
end;

procedure ProbarStackTrace;
begin
  CapaSuperficial('arranque');
end;

function EsTipoNumericoBooleano(
  ATipoCampo: TFieldType): Boolean;
begin
  Result := ATipoCampo in [
    Data.DB.ftFloat,
    Data.DB.ftCurrency,
    Data.DB.ftBCD,
    Data.DB.ftFMTBcd,
    Data.DB.ftSingle,
    Data.DB.ftExtended,
    Data.DB.ftInteger,
    Data.DB.ftSmallint,
    Data.DB.ftLargeint,
    Data.DB.ftWord,
    Data.DB.ftByte];
end;

function DetectarCamposBooleanosNumericos(
  ADataSet: TDataSet): TIncidenciasMetadataCampos;
var
  i: Integer;
  iIncidencia: Integer;
  oCampo: TField;
begin
  Result := nil;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    for i := 0 to ADataSet.FieldCount - 1 do
    begin
      oCampo := ADataSet.Fields[i];
      if StartsText('ES', oCampo.FieldName) and
         EsTipoNumericoBooleano(oCampo.DataType) then
      begin
        iIncidencia := Length(Result);
        SetLength(Result, iIncidencia + 1);
        Result[iIncidencia].NombreCampo := oCampo.FieldName;
        Result[iIncidencia].TipoCampo := oCampo.DataType;
      end;
    end;
  end;
end;

function MensajeCampoBooleanoNumerico(
  const AContexto: string;
  const AIncidencia: TIncidenciaMetadataCampo): string;
var
  sTipo: string;
begin
  sTipo := GetEnumName(
    TypeInfo(TFieldType),
    Ord(AIncidencia.TipoCampo));
  Result := Format(
    '[DiagnosticarCamposBooleanos] %s: campo "%s" tipado como %s ' +
    'pero por convencion deberia ser varchar(1) S/N. Causa probable: ' +
    'metadata de vista desactualizada tras modificar la tabla. ' +
    'Solucion: regenerar (borrar y volver a definir) la vista usada ' +
    'por el grid.',
    [AContexto, AIncidencia.NombreCampo, sTipo]);
end;

procedure DiagnosticarCamposBooleanos(
  ADataSet: TDataSet;
  const AContexto: string;
  const ARegistroLog: IRegistroLog);
var
  aIncidencias: TIncidenciasMetadataCampos;
  i: Integer;
begin
  aIncidencias :=
    DetectarCamposBooleanosNumericos(ADataSet);
  for i := 0 to Length(aIncidencias) - 1 do
    if Assigned(ARegistroLog) then
      ARegistroLog.RegistrarError(
        MensajeCampoBooleanoNumerico(
          AContexto, aIncidencias[i]));
end;

end.

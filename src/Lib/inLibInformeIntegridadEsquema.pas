{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformeIntegridadEsquema                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Texto del resultado de Ayuda > Comprobar integridad: resumen, avisos y    }
{    detalle de las diferencias con el esquema ideal.                          }
{******************************************************************************}
unit inLibInformeIntegridadEsquema;

interface

uses
  inLibHuellaEsquema;

const
  // Líneas de detalle como máximo; el resto se resume en una.
  cMaximoLineasDetalleIntegridad = 300;

function TextoInformeIntegridad(
  const AComprobacion: TComprobacionIntegridad;
  AAlArrancar: Boolean = False): string;
// Una línea para el log: estado y huellas.
function ResumenLogIntegridad(
  const AComprobacion: TComprobacionIntegridad): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  inLibHuellaEsquemaIntf,
  inLibMsgIntegridadEsquema;

function NombreApartado(AApartado: TApartadoHuella): string;
begin
  case AApartado of
    ahEstructura:
      Result := SIntegridadApartadoEstructura;
    ahVistas:
      Result := SIntegridadApartadoVistas;
    ahRutinas:
      Result := SIntegridadApartadoRutinas;
    ahDefinidores:
      Result := SIntegridadApartadoDefinidores;
    ahCodigo:
      Result := SIntegridadApartadoCodigo;
  else
    Result := SIntegridadApartadoIndices;
  end;
end;

function ContarDiferencias(
  const AResultado: TResultadoIntegridad;
  ASobra: Boolean): Integer;
var
  oDiferencia: TDiferenciaHuella;
begin
  Result := 0;
  for oDiferencia in AResultado.Diferencias do
  begin
    if (oDiferencia.Apartado <> ahIndices) and
       ((oDiferencia.Tipo = tdhSobra) = ASobra) then
      Inc(Result);
  end;
end;

function SoloDifiereElCodigo(const AResultado: TResultadoIntegridad):
  Boolean;
var
  oDiferencia: TDiferenciaHuella;
begin
  Result := True;
  for oDiferencia in AResultado.Diferencias do
  begin
    if (oDiferencia.Apartado <> ahIndices) and
       (oDiferencia.Tipo <> tdhSobra) and
       (oDiferencia.Apartado <> ahCodigo) then
      Result := False;
  end;
end;

function TextoResultado(const AResultado: TResultadoIntegridad;
  AAlArrancar: Boolean): string;
begin
  case AResultado.Estado of
    eiIntegra:
      Result := SIntegridadResultadoIntegra;
    eiObjetosDeMas:
      Result := Format(SIntegridadResultadoObjetosDeMas,
                       [ContarDiferencias(AResultado, True)]);
  else
    // Con solo código distinto no sirve mandar a buscar scripts.
    if SoloDifiereElCodigo(AResultado) then
      Result := Format(SIntegridadResultadoSoloCodigo,
                       [ContarDiferencias(AResultado, False)])
    else if AAlArrancar then
      Result := Format(SIntegridadResultadoDiferenciasArranque,
                       [ContarDiferencias(AResultado, False)])
    else
      Result := Format(SIntegridadResultadoDiferencias,
                       [ContarDiferencias(AResultado, False)]);
  end;
end;

function NombresApartados(AApartados: TArray<TApartadoHuella>): string;
var
  eApartado: TApartadoHuella;
begin
  Result := '';
  for eApartado in AApartados do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + NombreApartado(eApartado);
  end;
end;

function TextoProcedimiento(const AResultado: TResultadoIntegridad): string;
var
  aApartados: TArray<TApartadoHuella>;
  eApartado: TApartadoHuella;
begin
  case AResultado.Procedimiento of
    ephNoInstalado:
      Result := SIntegridadProcedimientoNoInstalado;
    ephCoherente:
      Result := SIntegridadProcedimientoCoherente;
    ephVersionDistinta:
      Result := Format(SIntegridadProcedimientoOtraVersion,
                       [AResultado.VersionProcedimiento]);
    ephConError:
      Result := Format(SIntegridadProcedimientoError,
                       [AResultado.ErrorProcedimiento]);
    ephNoComparable:
      Result := SIntegridadProcedimientoNoComparable;
  else
    aApartados := nil;
    for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
    begin
      if eApartado in AResultado.ApartadosProcedimientoDistintos then
        aApartados := aApartados + [eApartado];
    end;
    Result := Format(SIntegridadProcedimientoDistinto,
                     [NombresApartados(aApartados)]);
  end;
end;

procedure AnadirAvisos(
  const AComprobacion: TComprobacionIntegridad;
  ALineas: TStrings);
var
  oResultado: TResultadoIntegridad;
begin
  oResultado := AComprobacion.Resultado;
  if (AComprobacion.TextoFirma <> '') and
     not AComprobacion.FirmaPreocupante then
    ALineas.Add(Format(SIntegridadFirma, [AComprobacion.TextoFirma]));
  if not AComprobacion.EsquemaIdealCoherente then
    ALineas.Add(SIntegridadEsquemaIdealDanado);
  if not oResultado.CodigoComprobado then
    ALineas.Add(SIntegridadCodigoNoComprobado);
  if oResultado.ElementosSinPermiso > 0 then
    ALineas.Add(Format(SIntegridadSinPermiso,
                       [oResultado.ElementosSinPermiso]));
  if oResultado.HayAjustesIndices then
    ALineas.Add(SIntegridadAjustesIndices);
  ALineas.Add(TextoProcedimiento(oResultado));
end;

function LineaDiferencia(const ADiferencia: TDiferenciaHuella): string;
begin
  case ADiferencia.Tipo of
    tdhFalta:
      Result := Format('[%s] %s: %s', [NombreApartado(ADiferencia.Apartado),
                                       SIntegridadFalta,
                                       ADiferencia.Objeto]);
    tdhSobra:
      Result := Format('[%s] %s: %s', [NombreApartado(ADiferencia.Apartado),
                                       SIntegridadSobra,
                                       ADiferencia.Objeto]);
  else
    Result := Format('[%s] %s: %s (%s %s; %s %s)',
                     [NombreApartado(ADiferencia.Apartado),
                      SIntegridadDistinto, ADiferencia.Objeto,
                      SIntegridadFirmaIdeal, ADiferencia.FirmaIdeal,
                      SIntegridadFirmaReal, ADiferencia.FirmaReal]);
  end;
end;

function DiferenciasOrdenadas(const AResultado: TResultadoIntegridad):
  TArray<TDiferenciaHuella>;
begin
  // Primero lo que hay que arreglar, después lo de más y los índices.
  Result := Copy(AResultado.Diferencias);
  TArray.Sort<TDiferenciaHuella>(Result,
    TComparer<TDiferenciaHuella>.Construct(
      function(const A, B: TDiferenciaHuella): Integer
      begin
        Result := Ord(A.Apartado = ahIndices) - Ord(B.Apartado = ahIndices);
        if Result = 0 then
          Result := Ord(A.Tipo = tdhSobra) - Ord(B.Tipo = tdhSobra);
        if Result = 0 then
          Result := Ord(A.Apartado) - Ord(B.Apartado);
        if Result = 0 then
          Result := CompareStr(A.Objeto, B.Objeto);
      end));
end;

procedure AnadirDetalle(
  const AResultado: TResultadoIntegridad;
  ALineas: TStrings);
var
  aDiferencias: TArray<TDiferenciaHuella>;
  iDiferencia: Integer;
begin
  aDiferencias := DiferenciasOrdenadas(AResultado);
  if Length(aDiferencias) > 0 then
  begin
    ALineas.Add('');
    ALineas.Add(SIntegridadDetalle);
    iDiferencia := 0;
    while (iDiferencia < Length(aDiferencias)) and
          (iDiferencia < cMaximoLineasDetalleIntegridad) do
    begin
      ALineas.Add(LineaDiferencia(aDiferencias[iDiferencia]));
      Inc(iDiferencia);
    end;
    if Length(aDiferencias) > cMaximoLineasDetalleIntegridad then
      ALineas.Add(Format(SIntegridadMasDiferencias,
                         [Length(aDiferencias) -
                          cMaximoLineasDetalleIntegridad]));
  end;
end;

function TextoInformeIntegridad(
  const AComprobacion: TComprobacionIntegridad;
  AAlArrancar: Boolean): string;
var
  oLineas: TStringList;
begin
  oLineas := TStringList.Create;
  try
    // Un programa sin la firma propia va antes que cualquier otra cosa.
    if AComprobacion.FirmaPreocupante then
    begin
      oLineas.Add(Format(SIntegridadFirmaAtencion,
                         [AComprobacion.TextoFirma]));
      oLineas.Add('');
    end;
    oLineas.Add(TextoResultado(AComprobacion.Resultado, AAlArrancar));
    oLineas.Add('');
    AnadirAvisos(AComprobacion, oLineas);
    oLineas.Add('');
    oLineas.Add(Format(SIntegridadCabeceraBase,
                       [AComprobacion.Contexto.BaseDatos]));
    oLineas.Add(Format(SIntegridadCabeceraServidor,
                       [AComprobacion.Contexto.VersionServidor]));
    oLineas.Add(Format(SIntegridadCabeceraUsuario,
                       [AComprobacion.Contexto.Usuario]));
    oLineas.Add(Format(SIntegridadCabeceraModelo,
                       [AComprobacion.Modelo, AComprobacion.Generado]));
    oLineas.Add(Format(SIntegridadHuellaBase,
                       [AComprobacion.Resultado.Huellas.Global]));
    oLineas.Add(Format(SIntegridadHuellaIdeal,
                       [AComprobacion.Resultado.HuellasIdeal.Global]));
    AnadirDetalle(AComprobacion.Resultado, oLineas);
    Result := TrimRight(oLineas.Text);
  finally
    oLineas.Free;
  end;
end;

function ResumenLogIntegridad(
  const AComprobacion: TComprobacionIntegridad): string;
const
  cEstados: array[TEstadoIntegridad] of string = (
    'INTEGRA',
    'OBJETOS_DE_MAS',
    'CON_DIFERENCIAS');
  cProcedimiento: array[TEstadoProcedimientoHuella] of string = (
    'NO_INSTALADO',
    'COHERENTE',
    'OTRA_VERSION',
    'DISTINTO',
    'CON_ERROR',
    'NO_COMPARABLE');
begin
  Result := Format(
    'Integridad del esquema: %s; base %s; huella %s; modelo %s; ' +
    'motor %s; diferencias %d; procedimiento %s; ideal coherente %s',
    [cEstados[AComprobacion.Resultado.Estado],
     AComprobacion.Contexto.BaseDatos,
     AComprobacion.Resultado.Huellas.Global,
     AComprobacion.Resultado.HuellasIdeal.Global,
     AComprobacion.Motor,
     Length(AComprobacion.Resultado.Diferencias),
     cProcedimiento[AComprobacion.Resultado.Procedimiento],
     BoolToStr(AComprobacion.EsquemaIdealCoherente, True)]);
end;

end.

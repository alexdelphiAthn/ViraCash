{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImpuestosComun                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades fiscales compartidas por compras y ventas: lectura y           }
{    escritura tolerante de campos, normalización de tipos de IVA y            }
{    lectura de porcentajes por código de IVA o por empresa.                   }
{    Extraída de inLibComprasImpuestos / inLibVentasImpuestos, donde           }
{    estas 14 funciones vivían duplicadas byte a byte.                         }
{******************************************************************************}
unit inLibImpuestosComun;

interface

uses
  System.SysUtils, Data.DB, inLibImpuestosLecturasIntf;

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
function CampoString(ADataSet: TDataSet; const ACampo: string): string;
function CampoFloatDifiere(ADataSet: TDataSet; const ACampo: string;
  AValor: Double): Boolean;
function CampoStringDifiere(ADataSet: TDataSet; const ACampo,
  AValor: string): Boolean;
procedure PonerFloat(ADataSet: TDataSet; const ACampo: string;
  AValor: Double);
procedure PonerString(ADataSet: TDataSet; const ACampo, AValor: string);
function TipoIvaValido(const ATipoIva: string): Boolean;
function NormalizarTipoIva(const ATipoIva: string): string;
function IndiceTipoIva(const ATipoIva: string): Integer;
function LeerPorcentajesIvaPorCodigo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoIva: string; out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double): Boolean;
function LeerPorcentajesIvaPorEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string; out ACodigoIva: string; out AIvaN, AIvaR,
  AIvaS, AIvaE, ARecN, ARecR, ARecS, ARecE: Double): Boolean;
function ObtenerTipoIvaArticulo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoArt: string): string;
function PorcentajeIvaCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
// Conversion IVA incluido <-> excluido con guarda de division por cero.
// APorcentajeIva viene en tanto por cien (21, 10.5...), NUNCA truncado
// a entero: los IVAs con decimales existen y truncarlos descuadra
// centimos entre linea y cabecera.
function PrecioSinIvaDesdeConIva(APrecioConIva,
                                 APorcentajeIva: Double): Double;
function PrecioConIvaDesdeSinIva(APrecioSinIva,
                                 APorcentajeIva: Double): Double;
function SufijoLineaFiscalDesdeCampo(const ACampoTipoIva: string): string;

implementation

const
  // Copia privada: el orden define el indice de tipo de IVA (N/R/S/E)
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsFloat;
  end;
end;

function CampoString(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsString;
  end;
end;

function CampoFloatDifiere(ADataSet: TDataSet; const ACampo: string;
  AValor: Double): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.IsNull or (Abs(oCampo.AsFloat - AValor) > 0.000001);
  end;
end;

function CampoStringDifiere(ADataSet: TDataSet; const ACampo,
  AValor: string): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.IsNull or (oCampo.AsString <> AValor);
  end;
end;

procedure PonerFloat(ADataSet: TDataSet; const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and CampoFloatDifiere(ADataSet, ACampo, AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      oCampo.AsFloat := AValor;
    end;
  end;
end;

procedure PonerString(ADataSet: TDataSet; const ACampo, AValor: string);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and CampoStringDifiere(ADataSet, ACampo, AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      oCampo.AsString := AValor;
    end;
  end;
end;

function TipoIvaValido(const ATipoIva: string): Boolean;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoIva));
  Result := (sTipo = 'N') or (sTipo = 'R') or (sTipo = 'S') or
            (sTipo = 'E');
end;

function NormalizarTipoIva(const ATipoIva: string): string;
begin
  Result := UpperCase(Trim(ATipoIva));
  if not TipoIvaValido(Result) then
    Result := 'N';
end;

function IndiceTipoIva(const ATipoIva: string): Integer;
var
  sTipo: string;
begin
  sTipo := NormalizarTipoIva(ATipoIva);
  Result := 0;
  if sTipo = 'R' then
    Result := 1
  else if sTipo = 'S' then
    Result := 2
  else if sTipo = 'E' then
    Result := 3;
end;

procedure CopiarPorcentajes(
  const APorcentajes: TPorcentajesImpuestos;
  out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double);
begin
  AIvaN := APorcentajes.IvaNormal;
  AIvaR := APorcentajes.IvaReducido;
  AIvaS := APorcentajes.IvaSuperReducido;
  AIvaE := APorcentajes.IvaExento;
  ARecN := APorcentajes.RecargoNormal;
  ARecR := APorcentajes.RecargoReducido;
  ARecS := APorcentajes.RecargoSuperReducido;
  ARecE := APorcentajes.RecargoExento;
end;

procedure LimpiarPorcentajes(
  out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double);
begin
  AIvaN := 0;
  AIvaR := 0;
  AIvaS := 0;
  AIvaE := 0;
  ARecN := 0;
  ARecR := 0;
  ARecS := 0;
  ARecE := 0;
end;

function LeerPorcentajesIvaPorCodigo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoIva: string; out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double): Boolean;
var
  oPorcentajes: TPorcentajesImpuestos;
begin
  Result := False;
  LimpiarPorcentajes(AIvaN, AIvaR, AIvaS, AIvaE,
    ARecN, ARecR, ARecS, ARecE);
  if Assigned(ALecturas) and (Trim(ACodigoIva) <> '') and
     (Trim(ACodigoIva) <> '0') then
  begin
    Result := ALecturas.LeerPorCodigo(ACodigoIva, oPorcentajes);
    if Result then
      CopiarPorcentajes(oPorcentajes, AIvaN, AIvaR, AIvaS, AIvaE,
        ARecN, ARecR, ARecS, ARecE);
  end;
end;

function LeerPorcentajesIvaPorEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string; out ACodigoIva: string; out AIvaN, AIvaR,
  AIvaS, AIvaE, ARecN, ARecR, ARecS, ARecE: Double): Boolean;
var
  oPorcentajes: TPorcentajesImpuestos;
begin
  Result := False;
  ACodigoIva := '';
  LimpiarPorcentajes(AIvaN, AIvaR, AIvaS, AIvaE,
    ARecN, ARecR, ARecS, ARecE);
  if Assigned(ALecturas) and (Trim(ACodigoEmp) <> '') and
     (Trim(ACodigoEmp) <> '0') then
  begin
    Result := ALecturas.LeerPorEmpresa(ACodigoEmp, oPorcentajes);
    if Result then
    begin
      ACodigoIva := oPorcentajes.CodigoIva;
      CopiarPorcentajes(oPorcentajes, AIvaN, AIvaR, AIvaS, AIvaE,
        ARecN, ARecR, ARecS, ARecE);
    end;
  end;
end;

function ObtenerTipoIvaArticulo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoArt: string): string;
begin
  Result := '';
  if Assigned(ALecturas) and (Trim(ACodigoArt) <> '') then
    Result := UpperCase(Trim(
      ALecturas.LeerTipoIvaArticulo(ACodigoArt)));
  if not TipoIvaValido(Result) then
    Result := '';
end;

function PorcentajeIvaCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
var
  iIndice: Integer;
begin
  iIndice := IndiceTipoIva(ATipoIva);
  Result := CampoFloat(ACabecera,
    'PORCENTAJE_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera);
end;

function PrecioSinIvaDesdeConIva(APrecioConIva,
                                 APorcentajeIva: Double): Double;
var
  rFactor: Double;
begin
  rFactor := 1 + (APorcentajeIva / 100);
  if rFactor = 0 then
    Result := APrecioConIva
  else
    Result := APrecioConIva / rFactor;
end;

function PrecioConIvaDesdeSinIva(APrecioSinIva,
                                 APorcentajeIva: Double): Double;
begin
  Result := APrecioSinIva * (1 + (APorcentajeIva / 100));
end;

function SufijoLineaFiscalDesdeCampo(const ACampoTipoIva: string): string;
const
  PREFIJO = 'TIPO_IVA_ARTICULO_';
begin
  Result := '';
  if Pos(PREFIJO, ACampoTipoIva) = 1 then
    Result := Copy(ACampoTipoIva, Length(PREFIJO) + 1, MaxInt);
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesCodigoArticulo                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Evalúa la fórmula configurable del código de artículo de una sesión.      }
{    Un parámetro admite ancho (CodProv:3 entre llaves): su valor se rellena   }
{    con ceros a la izquierda hasta ese número de caracteres (92 -> 092); no   }
{    recorta.                                                                  }
{******************************************************************************}
unit inLibComprasSesionesCodigoArticulo;

interface

uses
  System.SysUtils;

const
  CLAVE_FORMULA_CODIGO_ARTICULO_SESION =
    'appFormulaCodigoArticuloSesion';
  FORMULA_CODIGO_ARTICULO_SESION_DEFECTO =
    '{CodFamilia}{ContadorFamilia}';
  FORMULA_CODIGO_ARTICULO_MODELO_PROVEEDOR =
    '{ModeloProv}-{CodProv}';
  // MODELO-PROVEEDOR con el proveedor a tres dígitos (ZEROTAI-092).
  FORMULA_CODIGO_ARTICULO_MODELO_PROVEEDOR_3 =
    '{ModeloProv}-{CodProv:3}';
  LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION = 20;

type
  EFormulaCodigoArticuloSesion = class(Exception);

  TValoresFormulaCodigoArticuloSesion = record
    CodFamilia: string;
    ContadorFamilia: string;
    CodArt: string;
    ModeloProv: string;
    CodProv: string;
  end;

  TFormulaCodigoArticuloSesion = class sealed
  private
    // Parte 'Nombre:Ancho'. Sin ancho, AAncho = 0. False si el ancho
    // no es un entero de 1 a LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION.
    class function SepararAncho(
      const AParametro: string;
      out ANombre: string;
      out AAncho: Integer): Boolean; static;
    class function EsParametroValido(
      const AParametro: string): Boolean; static;
    class function Sustituir(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
    class function UsaParametro(
      const AFormula, AParametro: string): Boolean; static;
    class function ValorParametro(
      const AParametro: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
  public
    class function Normalizar(const AFormula: string): string; static;
    class procedure Validar(const AFormula: string); static;
    class function UsaContadorFamilia(
      const AFormula: string): Boolean; static;
    class function UsaDatosFamilia(
      const AFormula: string): Boolean; static;
    class function UsaContadorArticulo(
      const AFormula: string): Boolean; static;
    class function UsaModeloProveedor(
      const AFormula: string): Boolean; static;
    class function UsaCodigoProveedor(
      const AFormula: string): Boolean; static;
    class function PuedeEvaluar(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): Boolean; static;
    class function Evaluar(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
  end;

implementation

uses
  System.StrUtils,
  inLibMsgCompras;

class function TFormulaCodigoArticuloSesion.Normalizar(
  const AFormula: string): string;
begin
  Result := Trim(AFormula);
  if Result = '' then
    Result := FORMULA_CODIGO_ARTICULO_SESION_DEFECTO;
end;

class function TFormulaCodigoArticuloSesion.SepararAncho(
  const AParametro: string;
  out ANombre: string;
  out AAncho: Integer): Boolean;
var
  iSeparador: Integer;
begin
  Result := True;
  AAncho := 0;
  iSeparador := Pos(':', AParametro);
  if iSeparador = 0 then
    ANombre := AParametro
  else
  begin
    ANombre := Copy(AParametro, 1, iSeparador - 1);
    Result := TryStrToInt(
                Copy(AParametro, iSeparador + 1, MaxInt), AAncho) and
              (AAncho >= 1) and
              (AAncho <= LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION);
  end;
end;

class function TFormulaCodigoArticuloSesion.EsParametroValido(
  const AParametro: string): Boolean;
begin
  Result := SameText(AParametro, 'CodFamilia') or
            SameText(AParametro, 'ContadorFamilia') or
            SameText(AParametro, 'ModeloProv') or
            SameText(AParametro, 'CodProv') or
            SameText(AParametro, 'CodArt');
end;

class function TFormulaCodigoArticuloSesion.UsaParametro(
  const AFormula, AParametro: string): Boolean;
begin
  Validar(AFormula);
  Result := ContainsText(
              Normalizar(AFormula),
              '{' + AParametro + '}') or
            ContainsText(
              Normalizar(AFormula),
              '{' + AParametro + ':');
end;

class function TFormulaCodigoArticuloSesion.ValorParametro(
  const AParametro: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
var
  iAncho: Integer;
  sNombre: string;
begin
  Result := '';
  SepararAncho(AParametro, sNombre, iAncho);
  if SameText(sNombre, 'CodFamilia') then
    Result := AValores.CodFamilia
  else if SameText(sNombre, 'ContadorFamilia') then
    Result := AValores.ContadorFamilia
  else if SameText(sNombre, 'CodArt') then
    Result := AValores.CodArt
  else if SameText(sNombre, 'ModeloProv') then
    Result := AValores.ModeloProv
  else if SameText(sNombre, 'CodProv') then
    Result := AValores.CodProv;
  Result := Trim(Result);
  // Un dato sin informar sigue vacío: PuedeEvaluar lo detecta.
  if (Result <> '') and (Length(Result) < iAncho) then
    Result := StringOfChar('0', iAncho - Length(Result)) + Result;
end;

class procedure TFormulaCodigoArticuloSesion.Validar(
  const AFormula: string);
var
  iFin: Integer;
  iPosicion: Integer;
  iAncho: Integer;
  iParametros: Integer;
  sFormula: string;
  sNombre: string;
  sParametro: string;
begin
  sFormula := Normalizar(AFormula);
  iParametros := 0;
  iPosicion := 1;
  while iPosicion <= Length(sFormula) do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      if iFin = 0 then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      if (sParametro = '') or
         (Pos('{', sParametro) > 0) then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      if not SepararAncho(sParametro, sNombre, iAncho) then
        raise EFormulaCodigoArticuloSesion.CreateFmt(
          SErrorFormulaCodigoArticuloAncho,
          [sParametro, LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION]);
      if not EsParametroValido(sNombre) then
        raise EFormulaCodigoArticuloSesion.CreateFmt(
          SErrorFormulaCodigoArticuloParametro,
          [sNombre]);
      Inc(iParametros);
      iPosicion := iFin + 1;
    end
    else
    begin
      if sFormula[iPosicion] = '}' then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      Inc(iPosicion);
    end;
  end;
  if iParametros = 0 then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloSinParametros);
end;

class function TFormulaCodigoArticuloSesion.UsaContadorFamilia(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'ContadorFamilia');
end;

class function TFormulaCodigoArticuloSesion.UsaContadorArticulo(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'CodArt');
end;

class function TFormulaCodigoArticuloSesion.UsaDatosFamilia(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'CodFamilia') or
            UsaContadorFamilia(AFormula);
end;

class function TFormulaCodigoArticuloSesion.UsaModeloProveedor(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'ModeloProv');
end;

class function TFormulaCodigoArticuloSesion.UsaCodigoProveedor(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'CodProv');
end;

class function TFormulaCodigoArticuloSesion.PuedeEvaluar(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): Boolean;
var
  iFin: Integer;
  iPosicion: Integer;
  sFormula: string;
  sParametro: string;
begin
  Validar(AFormula);
  Result := True;
  sFormula := Normalizar(AFormula);
  iPosicion := 1;
  while (iPosicion <= Length(sFormula)) and Result do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      Result := ValorParametro(sParametro, AValores) <> '';
      iPosicion := iFin + 1;
    end
    else
      Inc(iPosicion);
  end;
end;

class function TFormulaCodigoArticuloSesion.Sustituir(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
var
  iFin: Integer;
  iPosicion: Integer;
  sFormula: string;
  sParametro: string;
begin
  Result := '';
  sFormula := Normalizar(AFormula);
  iPosicion := 1;
  while iPosicion <= Length(sFormula) do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      Result := Result + ValorParametro(sParametro, AValores);
      iPosicion := iFin + 1;
    end
    else
    begin
      Result := Result + sFormula[iPosicion];
      Inc(iPosicion);
    end;
  end;
  Result := Trim(Result);
end;

class function TFormulaCodigoArticuloSesion.Evaluar(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
begin
  Validar(AFormula);
  if not PuedeEvaluar(AFormula, AValores) then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloDatos);
  Result := Sustituir(AFormula, AValores);
  if Result = '' then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloResultadoVacio);
  if Length(Result) > LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION then
    raise EFormulaCodigoArticuloSesion.CreateFmt(
      SErrorFormulaCodigoArticuloLongitud,
      [Result, Length(Result), LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION]);
end;

end.

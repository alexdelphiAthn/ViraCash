{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCambioArticuloColorHistoricoAmbito                       }
{    Tipo:       Codec de dominio                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Codificacion canonica y validacion de los ambitos del historico de        }
{    cambios de articulo y color. No conoce VCL, UniDAC ni transacciones.      }
{******************************************************************************}
unit inLibCambioArticuloColorHistoricoAmbito;

interface

uses
  System.Generics.Collections;

type
  TFilaHistorico = class
  public
    Clave: string;
    HashClave: string;
    Datos: string;
    HashDatos: string;
  end;

  TCodificadorAmbitoHistorico = class sealed
  private
    class function CalcularHash(const ATexto: string): string; static;
  public
    class function CondicionEsPersistible(
      const ACondicion: string): Boolean; static;
    class function CrearClave(const ACondicion: string): string; static;
    class function IntentarExtraerCondicion(
      const AClave: string;
      out ACondicion: string): Boolean; static;
    class function CrearResumen(
      AFilas: TObjectList<TFilaHistorico>): string; static;
    class function ResumenEsValido(const ADatos: string): Boolean; static;
    class function CrearEstado(
      const ACondicion: string;
      AFilas: TObjectList<TFilaHistorico>): TFilaHistorico; static;
  end;

implementation

uses
  System.Hash,
  System.JSON,
  System.SysUtils;

class function TCodificadorAmbitoHistorico.CalcularHash(
  const ATexto: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashString(ATexto));
end;

class function TCodificadorAmbitoHistorico.CondicionEsPersistible(
  const ACondicion: string): Boolean;
var
  cCaracter: Char;
  EnIdentificador: Boolean;
  EnTexto: Boolean;
  i: Integer;
  sSinLiterales: string;
  sToken: string;
  sTokenMayusculas: string;

  function TokenNoPermitido(const AToken: string): Boolean;
  begin
    sTokenMayusculas := UpperCase(AToken);
    Result := (sTokenMayusculas = 'TEMP') or
      (sTokenMayusculas = 'TMP') or
      (sTokenMayusculas = 'TEMPORARY') or
      (Copy(sTokenMayusculas, 1, 4) = 'TMP_') or
      (Copy(sTokenMayusculas, 1, 5) = 'TEMP_') or
      (sTokenMayusculas = 'DROP') or
      (sTokenMayusculas = 'ALTER') or
      (sTokenMayusculas = 'CREATE') or
      (sTokenMayusculas = 'INSERT') or
      (sTokenMayusculas = 'UPDATE') or
      (sTokenMayusculas = 'DELETE') or
      (sTokenMayusculas = 'REPLACE') or
      (sTokenMayusculas = 'TRUNCATE') or
      (sTokenMayusculas = 'CALL') or
      (sTokenMayusculas = 'LOAD') or
      (sTokenMayusculas = 'OUTFILE') or
      (sTokenMayusculas = 'INFILE') or
      (sTokenMayusculas = 'INTO');
  end;

begin
  EnIdentificador := False;
  EnTexto := False;
  i := 1;
  sSinLiterales := '';
  while i <= Length(ACondicion) do
  begin
    cCaracter := ACondicion[i];
    if EnTexto then
    begin
      sSinLiterales := sSinLiterales + ' ';
      if cCaracter = '''' then
      begin
        if (i < Length(ACondicion)) and
           (ACondicion[i + 1] = '''') then
        begin
          sSinLiterales := sSinLiterales + ' ';
          Inc(i);
        end
        else
          EnTexto := False;
      end
      else if (cCaracter = '\') and
              (i < Length(ACondicion)) then
      begin
        sSinLiterales := sSinLiterales + ' ';
        Inc(i);
      end;
    end
    else if EnIdentificador then
    begin
      if cCaracter = '`' then
      begin
        EnIdentificador := False;
        sSinLiterales := sSinLiterales + ' ';
      end
      else
        sSinLiterales := sSinLiterales + cCaracter;
    end
    else if cCaracter = '''' then
    begin
      EnTexto := True;
      sSinLiterales := sSinLiterales + ' ';
    end
    else if cCaracter = '`' then
    begin
      EnIdentificador := True;
      sSinLiterales := sSinLiterales + ' ';
    end
    else
      sSinLiterales := sSinLiterales + cCaracter;
    Inc(i);
  end;
  Result := not EnTexto and not EnIdentificador;
  Result := Result and (Pos(':', sSinLiterales) = 0);
  Result := Result and (Pos('?', sSinLiterales) = 0);
  Result := Result and (Pos('@', sSinLiterales) = 0);
  Result := Result and (Pos('#', sSinLiterales) = 0);
  Result := Result and (Pos(';', sSinLiterales) = 0);
  Result := Result and (Pos('"', sSinLiterales) = 0);
  Result := Result and (Pos('--', sSinLiterales) = 0);
  Result := Result and (Pos('/*', sSinLiterales) = 0);
  Result := Result and (Pos('*/', sSinLiterales) = 0);
  sToken := '';
  i := 1;
  while Result and (i <= Length(sSinLiterales) + 1) do
  begin
    if (i <= Length(sSinLiterales)) and
       CharInSet(
         sSinLiterales[i],
         ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      sToken := sToken + sSinLiterales[i]
    else
    begin
      if sToken <> '' then
        Result := not TokenNoPermitido(sToken);
      sToken := '';
    end;
    Inc(i);
  end;
end;

class function TCodificadorAmbitoHistorico.CrearClave(
  const ACondicion: string): string;
var
  oJson: TJSONObject;
begin
  oJson := TJSONObject.Create;
  try
    oJson.AddPair(
      'CONDICION',
      TJSONString.Create(Trim(ACondicion)));
    Result := oJson.ToJSON;
  finally
    oJson.Free;
  end;
end;

class function TCodificadorAmbitoHistorico.IntentarExtraerCondicion(
  const AClave: string;
  out ACondicion: string): Boolean;
var
  oJson: TJSONObject;
  oRaiz: TJSONValue;
  oValor: TJSONValue;
begin
  ACondicion := '';
  Result := False;
  oRaiz := TJSONObject.ParseJSONValue(AClave);
  try
    if oRaiz is TJSONObject then
    begin
      oJson := TJSONObject(oRaiz);
      oValor := oJson.GetValue('CONDICION');
      Result := (oJson.Count = 1) and
        (oValor is TJSONString);
      if Result then
      begin
        ACondicion := oValor.Value;
        Result := CondicionEsPersistible(ACondicion) and
          (CrearClave(ACondicion) = AClave);
      end;
    end;
  finally
    oRaiz.Free;
  end;
end;

class function TCodificadorAmbitoHistorico.CrearResumen(
  AFilas: TObjectList<TFilaHistorico>): string;
var
  oBase: TStringBuilder;
  oFila: TFilaHistorico;
  oJson: TJSONObject;
  sHuella: string;
begin
  oBase := TStringBuilder.Create;
  oJson := TJSONObject.Create;
  try
    for oFila in AFilas do
    begin
      oBase.Append(oFila.HashClave);
      oBase.Append(':');
      oBase.Append(oFila.HashDatos);
      oBase.Append(';');
    end;
    sHuella := CalcularHash(oBase.ToString);
    oJson.AddPair(
      'CANTIDAD',
      TJSONNumber.Create(AFilas.Count));
    oJson.AddPair(
      'HUELLA',
      TJSONString.Create(sHuella));
    Result := oJson.ToJSON;
  finally
    oJson.Free;
    oBase.Free;
  end;
end;

class function TCodificadorAmbitoHistorico.ResumenEsValido(
  const ADatos: string): Boolean;
var
  cCaracter: Char;
  EsHuellaValida: Boolean;
  i: Integer;
  iCantidad: Integer;
  oCanonico: TJSONObject;
  oCantidad: TJSONValue;
  oHuella: TJSONValue;
  oJson: TJSONObject;
  oRaiz: TJSONValue;
begin
  Result := False;
  oRaiz := TJSONObject.ParseJSONValue(ADatos);
  try
    if oRaiz is TJSONObject then
    begin
      oJson := TJSONObject(oRaiz);
      oCantidad := oJson.GetValue('CANTIDAD');
      oHuella := oJson.GetValue('HUELLA');
      Result := (oJson.Count = 2) and
        (oCantidad is TJSONNumber) and
        (oHuella is TJSONString) and
        TryStrToInt(oCantidad.Value, iCantidad) and
        (iCantidad >= 0);
      if Result then
      begin
        EsHuellaValida := Length(oHuella.Value) = 64;
        i := 1;
        while EsHuellaValida and (i <= Length(oHuella.Value)) do
        begin
          cCaracter := oHuella.Value[i];
          EsHuellaValida := CharInSet(cCaracter, ['0'..'9', 'a'..'f']);
          Inc(i);
        end;
        Result := EsHuellaValida;
      end;
      if Result then
      begin
        oCanonico := TJSONObject.Create;
        try
          oCanonico.AddPair(
            'CANTIDAD',
            TJSONNumber.Create(iCantidad));
          oCanonico.AddPair(
            'HUELLA',
            TJSONString.Create(oHuella.Value));
          Result := oCanonico.ToJSON = ADatos;
        finally
          oCanonico.Free;
        end;
      end;
    end;
  finally
    oRaiz.Free;
  end;
end;

class function TCodificadorAmbitoHistorico.CrearEstado(
  const ACondicion: string;
  AFilas: TObjectList<TFilaHistorico>): TFilaHistorico;
begin
  Result := TFilaHistorico.Create;
  try
    Result.Clave := CrearClave(ACondicion);
    Result.HashClave := CalcularHash(Result.Clave);
    Result.Datos := CrearResumen(AFilas);
    Result.HashDatos := CalcularHash(Result.Datos);
  except
    Result.Free;
    raise;
  end;
end;

end.

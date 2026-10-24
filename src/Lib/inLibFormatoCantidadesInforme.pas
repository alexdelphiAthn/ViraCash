{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormatoCantidadesInforme                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cantidades de los informes con los decimales de la unidad de cada línea   }
{    (125,5 m se imprime 125,50; 3 Uds, 3). Reescribe los textos que son solo  }
{    [DataSet."CANTIDAD_xxx"] cuando el dataset trae TIPO_CANTIDAD_ARTICULO_xxx }
{    y los FormatFloat('mascara', <DataSet."CANTIDAD_xxx">) de textos          }
{    compuestos (CANTIDAD sin sufijo: unidad en UNIDAD). Las sumas no se tocan. }
{    (FZ-ISSUE-235). El formato guardado no se toca: se aplica al preparar.    }
{******************************************************************************}
unit inLibFormatoCantidadesInforme;

interface

uses
  frxClass, inLibUnidadesMedida;

// Expresion FastReport que formatea <ADataSet."ACampoCantidad"> con los
// decimales de la unidad <ADataSet."ACampoUnidad"> de la misma fila.
function ExpresionCantidadUnidad(const ADataSet, ACampoCantidad,
  ACampoUnidad: string; AUnidades: TUnidadesMedida): string;

// Aplica ExpresionCantidadUnidad a los textos del informe que muestran
// solo una cantidad de linea. Pensado para TfrxReport.OnBeginDoc, con los
// datasets ya enlazados (si el dataset no tiene el campo de unidad, el
// texto se deja como esta).
procedure AjustarFormatoCantidadesInforme(AInforme: TfrxReport;
  AUnidades: TUnidadesMedida);

implementation

uses
  System.SysUtils, System.RegularExpressions,
  System.Generics.Collections, System.Generics.Defaults;

const
  // Unidad desconocida: los decimales que tenga el valor, sin perderlos.
  MASCARA_SIN_UNIDAD = '#,##0.###';
  // El nombre del dataset puede llevar espacios («Lineas Facturas» del
  // informe de facturas, FZ-ISSUE-298).
  PATRON_CANTIDAD =
    '^\[\s*([A-Za-z0-9_ ]+)\."(CANTIDAD(_([A-Za-z0-9_]+))?)"\s*\]$';
  // FZ-ISSUE-235: FormatFloat con mascara fija dentro de un texto compuesto,
  // p. ej. '[FormatFloat('#,##0.##', <Lineas."CANTIDAD">)] [Lineas."UNIDAD"]'
  // del informe de documentos.
  PATRON_FORMATO_CANTIDAD =
    'FormatFloat\(\s*''[^'']*''\s*,\s*<([A-Za-z0-9_ ]+)\."' +
    '(CANTIDAD(_([A-Za-z0-9_]+))?)">\s*\)';
  // Unidad de CANTIDAD sin sufijo (dataset Lineas de inLibInformeDocumento).
  CAMPO_UNIDAD_SIN_SUFIJO = 'UNIDAD';

function MascaraDecimales(ADecimales: Integer): string;
begin
  if ADecimales > 0 then
    Result := '#,##0.' + StringOfChar('0', ADecimales)
  else
    Result := '#,##0';
end;

function LiteralScript(const ATexto: string): string;
begin
  Result := '''' + StringReplace(ATexto, '''', '''''', [rfReplaceAll]) +
    '''';
end;

function ExpresionCantidadUnidad(const ADataSet, ACampoCantidad,
  ACampoUnidad: string; AUnidades: TUnidadesMedida): string;
var
  Condiciones: TDictionary<Integer, string>;
  Decimales: TArray<Integer>;
  sUnidad, sCondicion, sMascara, sCodigo: string;
  iDecimales: Integer;
begin
  sUnidad := 'UpperCase(Trim(VarToStr(<' + ADataSet + '."' +
    ACampoUnidad + '">)))';
  sMascara := LiteralScript(MASCARA_SIN_UNIDAD);
  Condiciones := TDictionary<Integer, string>.Create;
  try
    if Assigned(AUnidades) then
      for sCodigo in AUnidades.Codigos do
      begin
        iDecimales := AUnidades.Decimales(sCodigo);
        sCondicion := '(' + sUnidad + ' = ' +
          LiteralScript(UpperCase(Trim(sCodigo))) + ')';
        if Condiciones.ContainsKey(iDecimales) then
          Condiciones[iDecimales] :=
            Condiciones[iDecimales] + ' or ' + sCondicion
        else
          Condiciones.Add(iDecimales, sCondicion);
      end;
    Decimales := Condiciones.Keys.ToArray;
    TArray.Sort<Integer>(Decimales);
    for iDecimales in Decimales do
      sMascara := 'IIF(' + Condiciones[iDecimales] + ', ' +
        LiteralScript(MascaraDecimales(iDecimales)) + ', ' + sMascara + ')';
  finally
    Condiciones.Free;
  end;
  Result := 'FormatFloat(' + sMascara + ', <' + ADataSet + '."' +
    ACampoCantidad + '">)';
end;

// Grupo opcional de la coincidencia: '' si no participo.
function GrupoOpcional(const AMatch: TMatch; AIndice: Integer): string;
begin
  Result := '';
  if (AIndice < AMatch.Groups.Count) and AMatch.Groups[AIndice].Success then
    Result := AMatch.Groups[AIndice].Value;
end;

// Campo de unidad de la cantidad ACampoCantidad (sufijo ASufijo, con el
// guion bajo) si el dataset lo trae; '' si no.
function CampoUnidadCantidad(AInforme: TfrxReport;
  const ADataSet, ASufijo: string): string;
var
  oDatos: TfrxDataSet;
begin
  if ASufijo <> '' then
    Result := 'TIPO_CANTIDAD_ARTICULO' + ASufijo
  else
    Result := CAMPO_UNIDAD_SIN_SUFIJO;
  oDatos := AInforme.GetDataset(ADataSet);
  if (oDatos = nil) or not oDatos.HasField(Result) then
    Result := '';
end;

function ReescribirFormatosCantidad(AInforme: TfrxReport;
  const ATexto: string; AUnidades: TUnidadesMedida): string;
var
  oCoincidencia: TMatch;
  iDesde: Integer;
  sUnidad: string;
begin
  Result := '';
  iDesde := 1;
  for oCoincidencia in TRegEx.Matches(ATexto, PATRON_FORMATO_CANTIDAD) do
  begin
    Result := Result + Copy(ATexto, iDesde, oCoincidencia.Index - iDesde);
    sUnidad := CampoUnidadCantidad(AInforme,
      oCoincidencia.Groups[1].Value, GrupoOpcional(oCoincidencia, 3));
    if sUnidad = '' then
      Result := Result + oCoincidencia.Value
    else
      Result := Result + ExpresionCantidadUnidad(
        oCoincidencia.Groups[1].Value, oCoincidencia.Groups[2].Value,
        sUnidad, AUnidades);
    iDesde := oCoincidencia.Index + oCoincidencia.Length;
  end;
  Result := Result + Copy(ATexto, iDesde, MaxInt);
end;

procedure AjustarFormatoCantidadesInforme(AInforme: TfrxReport;
  AUnidades: TUnidadesMedida);
var
  i: Integer;
  oMemo: TfrxCustomMemoView;
  oCoincidencia: TMatch;
  sDataSet, sCantidad, sUnidad, sTexto: string;
begin
  if Assigned(AInforme) and Assigned(AUnidades) then
    for i := 0 to AInforme.AllObjects.Count - 1 do
      if TObject(AInforme.AllObjects[i]) is TfrxCustomMemoView then
      begin
        oMemo := TfrxCustomMemoView(AInforme.AllObjects[i]);
        oCoincidencia := TRegEx.Match(Trim(oMemo.Text), PATRON_CANTIDAD);
        if not oMemo.AllowExpressions then
          Continue;
        if oCoincidencia.Success then
        begin
          sDataSet := oCoincidencia.Groups[1].Value;
          sCantidad := oCoincidencia.Groups[2].Value;
          sUnidad := CampoUnidadCantidad(AInforme, sDataSet,
            GrupoOpcional(oCoincidencia, 3));
          if sUnidad <> '' then
          begin
            oMemo.Text := '[' + ExpresionCantidadUnidad(sDataSet,
              sCantidad, sUnidad, AUnidades) + ']';
            // El resultado ya es texto: sin formato numerico encima.
            oMemo.DisplayFormat.Kind := fkText;
            oMemo.DisplayFormat.FormatStr := '';
          end;
        end
        else
        begin
          // Ya es texto (FormatFloat): no hace falta tocar DisplayFormat.
          sTexto := ReescribirFormatosCantidad(AInforme, oMemo.Text,
            AUnidades);
          if sTexto <> oMemo.Text then
            oMemo.Text := sTexto;
        end;
      end;
end;

end.

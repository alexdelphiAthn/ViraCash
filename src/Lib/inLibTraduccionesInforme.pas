{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesInforme                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traducción de los textos visibles de un informe FastReport ya             }
{    cargado. Las plantillas predeterminadas usan las claves                   }
{    FastReport.<unidad>.Predeterminado.<objeto>.Memo con recorrido de         }
{    clases heredadas; los formatos personalizados se traducen buscando        }
{    el texto español de cada memo en el catálogo (D22-B).                     }
{******************************************************************************}
unit inLibTraduccionesInforme;

interface

uses
  System.Classes, frxClass, inLibTraduccionesIntf;

function ExpresionesInformeConservadas(
  const AOriginal, ATraduccion: string): Boolean;

// Los memos añadidos en ejecución también necesitan una fuente con CJK.
procedure AjustarFuenteTextoInforme(AMemo: TfrxCustomMemoView);

procedure TraducirInformeFastReport(
  AInforme: TfrxReport;
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  AEsPersonalizado: Boolean);

implementation

uses
  System.SysUtils, System.RegularExpressions, Vcl.Graphics;

const
  SALTO_FINAL = #13#10;
  // Arial y el resto de fuentes latinas de las plantillas no tienen
  // glifos CJK: GDI los sustituye por una fuente de mapa de bits que en
  // cuerpos de 7-9 puntos se lee como cuadros (FZ-ISSUE-609).
  FUENTE_CJK = 'Microsoft YaHei';

function ContieneCaracteresCjk(const ATexto: string): Boolean;
var
  Caracter: Char;
begin
  Result := False;
  for Caracter in ATexto do
    if ((Caracter >= #$2E80) and (Caracter <= #$9FFF)) or
       ((Caracter >= #$F900) and (Caracter <= #$FAFF)) or
       ((Caracter >= #$FF00) and (Caracter <= #$FFEF)) then
      Exit(True);
end;

procedure AjustarFuenteTextoInforme(AMemo: TfrxCustomMemoView);
begin
  if (AMemo <> nil) and ContieneCaracteresCjk(AMemo.Text) then
    AMemo.Font.Name := FUENTE_CJK;
end;

function ExpresionSinCambiosDeCalculo(const AOriginal,
  ATraduccion: string): Boolean;
var
  Originales, Traducidas: TMatchCollection;
  Indice: Integer;
  Comparada, Rotulo, Prefijo: string;
begin
  Comparada := ATraduccion;
  Originales := TRegEx.Matches(AOriginal, '''(?:[^'']|'''')*''');
  Traducidas := TRegEx.Matches(ATraduccion, '''(?:[^'']|'''')*''');
  if Originales.Count = Traducidas.Count then
    for Indice := Originales.Count - 1 downto 0 do
    begin
      Rotulo := Originales[Indice].Value;
      Prefijo := TrimRight(Copy(AOriginal, 1,
        Originales[Indice].Index - 1));
      // Solo rótulos fiscales visibles conocidos. Los formatos numéricos,
      // códigos, condiciones, campos y funciones siguen siendo idénticos.
      if TRegEx.IsMatch(Rotulo,
        '^''\s*(Normal\s+Base|Reducido\s+Base|Super red\.\s+Base|' +
        'IVA|RE|Retencion IRPF|CIF:)\s*''$') and
        TRegEx.IsMatch(Traducidas[Indice].Value, '^''[\p{L}\s.:]+''$') and
        (not TRegEx.IsMatch(Rotulo, '^''\s*(IVA|RE)\s*''$') or
         Prefijo.EndsWith('+') or
         ((Rotulo = '''  RE ''') and Prefijo.EndsWith(','))) then
      begin
        Delete(Comparada, Traducidas[Indice].Index,
          Traducidas[Indice].Length);
        Insert(Rotulo, Comparada, Traducidas[Indice].Index);
      end;
    end;
  Result := AOriginal = Comparada;
end;

function ExpresionesInformeConservadas(
  const AOriginal, ATraduccion: string): Boolean;
var
  Originales, Traducidas: TMatchCollection;
  Indice: Integer;
begin
  Originales := TRegEx.Matches(AOriginal, '\[[^\]]+\]');
  Traducidas := TRegEx.Matches(ATraduccion, '\[[^\]]+\]');
  Result := Originales.Count = Traducidas.Count;
  Indice := 0;
  while Result and (Indice < Originales.Count) do
  begin
    Result := ExpresionSinCambiosDeCalculo(
      Originales[Indice].Value, Traducidas[Indice].Value);
    Inc(Indice);
  end;
end;

function TraducirMemoPredeterminado(
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  const ANombreObjeto, ATexto: string;
  out ATraducido: string): Boolean;
var
  Clase: TClass;
  Clave: string;
begin
  Result := False;
  ATraducido := ATexto;
  if Assigned(AInstancia) and
     (ANombreObjeto <> '') then
  begin
    // Igual que en los DFM: primero la clase concreta y después sus
    // ancestros, para reutilizar el catálogo del formulario base.
    Clase := AInstancia.ClassType;
    while Assigned(Clase) and
          Clase.InheritsFrom(TComponent) and
          not Result do
    begin
      Clave := 'FastReport.' + Clase.UnitName +
        '.Predeterminado.' + ANombreObjeto + '.Memo';
      if ATraducciones.ExisteTraduccion(Clave) then
      begin
        ATraducido := ATraducciones.Traducir(Clave, ATexto);
        Result := True;
      end
      else
        Clase := Clase.ClassParent;
    end;
  end;
end;

procedure TraducirInformeFastReport(
  AInforme: TfrxReport;
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  AEsPersonalizado: Boolean);
var
  i: Integer;
  EsPseudo: Boolean;
  TeniaSalto: Boolean;
  Memo: TfrxCustomMemoView;
  Texto: string;
  Traducido: string;
begin
  if Assigned(AInforme) and
     Assigned(ATraducciones) then
  begin
    EsPseudo := SameText(ATraducciones.Idioma, IDIOMA_PSEUDO);
    if EsPseudo or
       not SameText(ATraducciones.Idioma, IDIOMA_ESPANOL) then
    begin
      for i := 0 to AInforme.AllObjects.Count - 1 do
      begin
        if TObject(AInforme.AllObjects[i]) is TfrxCustomMemoView then
        begin
          Memo := TfrxCustomMemoView(AInforme.AllObjects[i]);
          Texto := Memo.Text;
          // El memo termina con un salto de línea que no forma
          // parte del texto catalogado en fza_traducciones.
          TeniaSalto := Texto.EndsWith(SALTO_FINAL);
          if TeniaSalto then
            SetLength(Texto, Length(Texto) - Length(SALTO_FINAL));
          if Texto <> '' then
          begin
            if EsPseudo or AEsPersonalizado then
              Traducido := ATraducciones.TraducirTextoInforme(Texto)
            else if not TraducirMemoPredeterminado(
                          AInstancia,
                          ATraducciones,
                          Memo.Name,
                          Texto,
                          Traducido) then
              Traducido := ATraducciones.TraducirTextoInforme(Texto);
            // Una traducción no puede renombrar variables de FastReport.
            if not ExpresionesInformeConservadas(Texto, Traducido) then
              Traducido := Texto;
            if Traducido <> Texto then
            begin
              if TeniaSalto then
                Memo.Text := Traducido + SALTO_FINAL
              else
                Memo.Text := Traducido;
              AjustarFuenteTextoInforme(Memo);
              // Las cabeceras predeterminadas conservan su ancho de columna.
              // Reducir solo su fuente evita invadir la celda contigua.
              if (not AEsPersonalizado) and
                 (Copy(Memo.Name, 1, 3) = 'Hdr') and
                 (Pos('[', Traducido) = 0) and (Memo.Width > 0) then
                while (Abs(Memo.Font.Height) > 9) and
                      (Memo.CalcWidth > Memo.Width) do
                  Memo.Font.Height := -(Abs(Memo.Font.Height) - 1);
            end;
          end;
        end;
      end;
    end;
  end;
end;

end.

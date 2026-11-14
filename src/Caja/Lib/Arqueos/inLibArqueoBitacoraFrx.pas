{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoBitacoraFrx                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Banda hija del listado de arqueos (FastReport) con la meteorología y      }
{    los apuntes del cuaderno de bitácora de cada arqueo. Se añade al          }
{    formato cargado si no la trae, así sirve también para los formatos        }
{    propios del usuario, y solo se imprime cuando hay algo que mostrar.       }
{******************************************************************************}
unit inLibArqueoBitacoraFrx;

interface

uses
  frxClass;

const
  BANDA_BITACORA_ARQUEOS = 'ChildBitacoraArqueos';
  MEMO_METEOROLOGIA_ARQUEOS = 'MemoMeteorologiaArqueo';
  MEMO_BITACORA_ARQUEOS = 'MemoBitacoraArqueo';

// Cuelga la banda de la banda de datos de ADatos (al final de sus bandas
// hijas). No hace nada si el formato ya la tiene o no hay banda de datos.
procedure AsegurarBandaBitacoraArqueos(AInforme: TfrxReport;
  ADatos: TfrxDataSet);
function EsBandaBitacoraArqueos(AComponente: TfrxComponent): Boolean;
// Para el OnBeforePrint de la banda: escribe los textos del arqueo en
// curso y la oculta si no se piden o están vacíos.
procedure AplicarBitacoraArqueosEnBanda(ABanda: TfrxComponent;
  AIncluir: Boolean; const AMeteorologia, ABitacora: string);

implementation

uses
  System.SysUtils, System.Classes;

const
  ALTO_LINEA_BITACORA = 14;
  SANGRIA_BITACORA = 20;

function EsBandaBitacoraArqueos(AComponente: TfrxComponent): Boolean;
begin
  Result := (AComponente is TfrxBand) and
    SameText(AComponente.Name, BANDA_BITACORA_ARQUEOS);
end;

function BuscarBandaDatos(AInforme: TfrxReport;
  ADatos: TfrxDataSet): TfrxDataBand;
var
  iObjeto: Integer;
  oObjeto: TObject;
begin
  Result := nil;
  for iObjeto := 0 to AInforme.AllObjects.Count - 1 do
  begin
    oObjeto := TObject(AInforme.AllObjects[iObjeto]);
    if (Result = nil) and (oObjeto is TfrxMasterData) and
       (TfrxMasterData(oObjeto).DataSet = ADatos) then
      Result := TfrxMasterData(oObjeto);
  end;
end;

function CrearMemoBitacora(ABanda: TfrxBand; const ANombre: string;
  ATop, AAncho: Extended): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(ABanda);
  Result.Name := ANombre;
  Result.SetBounds(SANGRIA_BITACORA, ATop, AAncho - SANGRIA_BITACORA,
    ALTO_LINEA_BITACORA);
  Result.Font.Name := 'Arial';
  Result.Font.Height := -10;
  Result.WordWrap := True;
  Result.StretchMode := smActualHeight;
  // El texto es del usuario: unos corchetes no son una expresión.
  Result.AllowExpressions := False;
end;

procedure AsegurarBandaBitacoraArqueos(AInforme: TfrxReport;
  ADatos: TfrxDataSet);
var
  oBanda: TfrxChild;
  oDatos: TfrxDataBand;
  oUltima: TfrxBand;
begin
  if Assigned(AInforme) and Assigned(ADatos) and
     (AInforme.FindObject(BANDA_BITACORA_ARQUEOS) = nil) then
  begin
    oDatos := BuscarBandaDatos(AInforme, ADatos);
    if Assigned(oDatos) and (oDatos.Parent is TfrxPage) then
    begin
      oUltima := oDatos;
      while Assigned(oUltima.Child) do
        oUltima := oUltima.Child;
      oBanda := TfrxChild.Create(oDatos.Parent);
      oBanda.Name := BANDA_BITACORA_ARQUEOS;
      oBanda.Top := oUltima.Top + oUltima.Height + 1;
      oBanda.Height := 2 * ALTO_LINEA_BITACORA + 4;
      oBanda.Stretched := True;
      CrearMemoBitacora(oBanda, MEMO_METEOROLOGIA_ARQUEOS, 0,
        oDatos.Width).Memo.Text := MEMO_METEOROLOGIA_ARQUEOS;
      CrearMemoBitacora(oBanda, MEMO_BITACORA_ARQUEOS,
        ALTO_LINEA_BITACORA, oDatos.Width).Memo.Text :=
        MEMO_BITACORA_ARQUEOS;
      oUltima.Child := oBanda;
    end;
  end;
end;

procedure AplicarBitacoraArqueosEnBanda(ABanda: TfrxComponent;
  AIncluir: Boolean; const AMeteorologia, ABitacora: string);
var
  oBanda: TfrxBand;
  oBitacora: TfrxComponent;
  oMeteorologia: TfrxComponent;
  rTop: Extended;
begin
  if EsBandaBitacoraArqueos(ABanda) then
  begin
    oBanda := TfrxBand(ABanda);
    oMeteorologia := oBanda.Report.FindObject(MEMO_METEOROLOGIA_ARQUEOS);
    oBitacora := oBanda.Report.FindObject(MEMO_BITACORA_ARQUEOS);
    oBanda.Visible := AIncluir and
      ((AMeteorologia <> '') or (ABitacora <> ''));
    rTop := 0;
    if oMeteorologia is TfrxMemoView then
    begin
      TfrxMemoView(oMeteorologia).Memo.Text := AMeteorologia;
      TfrxMemoView(oMeteorologia).Visible := AMeteorologia <> '';
      if AMeteorologia <> '' then
        rTop := oMeteorologia.Top + ALTO_LINEA_BITACORA;
    end;
    if oBitacora is TfrxMemoView then
    begin
      TfrxMemoView(oBitacora).Memo.Text := ABitacora;
      TfrxMemoView(oBitacora).Visible := ABitacora <> '';
      // Sin parte meteorológico los apuntes suben a la primera línea.
      oBitacora.Top := rTop;
    end;
  end;
end;

end.

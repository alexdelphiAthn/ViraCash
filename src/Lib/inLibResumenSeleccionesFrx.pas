{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResumenSeleccionesFrx                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pone en la cabecera de la primera página de un informe FastReport ya      }
{    cargado una banda con el resumen de selecciones, y la retira después.     }
{    Si la página tiene título, la banda va como hija suya (debajo, sin        }
{    mover nada del formato); si no, es el título. Se crea en tiempo de        }
{    ejecución y se quita tras imprimir para que nunca llegue a guardarse      }
{    en un formato personalizado.                                              }
{******************************************************************************}
unit inLibResumenSeleccionesFrx;

interface

uses
  frxClass;

procedure InsertarResumenSeleccionesInforme(
  AInforme: TfrxReport;
  const ATexto: string);
procedure QuitarResumenSeleccionesInforme(AInforme: TfrxReport);

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Graphics;

const
  NOMBRE_BANDA_RESUMEN = 'BandaResumenSeleccionesFza';
  NOMBRE_MEMO_RESUMEN = 'MemoResumenSeleccionesFza';
  FUENTE_RESUMEN = 'Arial';
  TAMANO_FUENTE_RESUMEN = 8;
  COLOR_TEXTO_RESUMEN = TColor($00333333);
  COLOR_LINEA_RESUMEN = TColor($00A0A0A0);
  // Dos líneas de 8 puntos; el memo se estira si el texto ocupa más.
  ALTO_RESUMEN_MM = 9;
  MARGEN_INFERIOR_MM = 1.5;

function PrimeraPaginaInforme(AInforme: TfrxReport): TfrxReportPage;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < AInforme.PagesCount) do
  begin
    if AInforme.Pages[i] is TfrxReportPage then
      Result := TfrxReportPage(AInforme.Pages[i]);
    Inc(i);
  end;
end;

function TituloPagina(APagina: TfrxReportPage): TfrxReportTitle;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < APagina.Objects.Count) do
  begin
    if TObject(APagina.Objects[i]) is TfrxReportTitle then
      Result := TfrxReportTitle(APagina.Objects[i]);
    Inc(i);
  end;
end;

function BandaQueEnlaza(
  AInforme: TfrxReport;
  AHija: TfrxBand): TfrxBand;
var
  i: Integer;
  oObjeto: TObject;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < AInforme.AllObjects.Count) do
  begin
    oObjeto := AInforme.AllObjects[i];
    if (oObjeto is TfrxBand) and (TfrxBand(oObjeto).Child = AHija) then
      Result := TfrxBand(oObjeto);
    Inc(i);
  end;
end;

function CrearBandaResumen(APagina: TfrxReportPage): TfrxBand;
var
  oHija: TfrxChild;
  oTitulo: TfrxReportTitle;
begin
  oTitulo := TituloPagina(APagina);
  if oTitulo = nil then
    Result := TfrxReportTitle.Create(APagina)
  else
  begin
    // Se intercala entre el título y su hija, si la tenía.
    oHija := TfrxChild.Create(APagina);
    oHija.Top := oTitulo.Top + oTitulo.Height;
    oHija.Child := oTitulo.Child;
    oTitulo.Child := oHija;
    Result := oHija;
  end;
  Result.Name := NOMBRE_BANDA_RESUMEN;
  Result.Height := (ALTO_RESUMEN_MM + MARGEN_INFERIOR_MM) * fr01cm;
  Result.Stretched := True;
end;

procedure CrearMemoResumen(ABanda: TfrxBand; const ATexto: string);
var
  oMemo: TfrxMemoView;
begin
  oMemo := TfrxMemoView.Create(ABanda);
  oMemo.Name := NOMBRE_MEMO_RESUMEN;
  oMemo.SetBounds(0, 0, ABanda.Width, ALTO_RESUMEN_MM * fr01cm);
  oMemo.Align := baWidth;
  oMemo.StretchMode := smActualHeight;
  // Los valores pueden llevar corchetes: no son expresiones.
  oMemo.AllowExpressions := False;
  oMemo.WordWrap := True;
  oMemo.ParentFont := False;
  oMemo.Font.Name := FUENTE_RESUMEN;
  oMemo.Font.Size := TAMANO_FUENTE_RESUMEN;
  oMemo.Font.Style := [];
  oMemo.Font.Color := COLOR_TEXTO_RESUMEN;
  oMemo.Frame.Typ := [ftBottom];
  oMemo.Frame.Color := COLOR_LINEA_RESUMEN;
  oMemo.Text := ATexto;
end;

procedure InsertarResumenSeleccionesInforme(
  AInforme: TfrxReport;
  const ATexto: string);
var
  oPagina: TfrxReportPage;
begin
  if AInforme <> nil then
  begin
    QuitarResumenSeleccionesInforme(AInforme);
    oPagina := PrimeraPaginaInforme(AInforme);
    if (oPagina <> nil) and (Trim(ATexto) <> '') then
      CrearMemoResumen(CrearBandaResumen(oPagina), ATexto);
  end;
end;

procedure QuitarResumenSeleccionesInforme(AInforme: TfrxReport);
var
  oBanda: TfrxBand;
  oComponente: TfrxComponent;
  oPadre: TfrxBand;
begin
  if AInforme <> nil then
  begin
    oComponente := AInforme.FindObject(NOMBRE_BANDA_RESUMEN);
    if oComponente is TfrxBand then
    begin
      oBanda := TfrxBand(oComponente);
      // FastReport no avisa al padre: se desenlaza antes de liberarla.
      oPadre := BandaQueEnlaza(AInforme, oBanda);
      if oPadre <> nil then
        oPadre.Child := oBanda.Child;
      oBanda.Child := nil;
      FreeAndNil(oBanda);
    end;
  end;
end;

end.

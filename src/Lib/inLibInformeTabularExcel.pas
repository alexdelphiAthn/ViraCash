{******************************************************************************}
{  Módulo:       inLibInformeTabularExcel                                       }
{    Tipo:       Librería                                                      }
{   Fecha:       07/11/2026                                                     }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  Exporta datos tabulares directamente a un libro Excel editable.             }
{******************************************************************************}
unit inLibInformeTabularExcel;

interface

uses
  Data.DB, dxSpreadSheet, inLibInformeTabular;

procedure ExportarInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ATitulo: string;
  const AColumnas: TColumnasInformeTabular;
  const AResumen: TArray<string>);

implementation

uses
  System.SysUtils, System.Variants, dxSpreadSheetCore,
  inLibHojaCalculoIntf,
  inLibHojaCalculoDevEx, inLibMsgInformesCliente;

procedure EscribirValor(const AServicios: TServiciosHojaCalculo;
  AFila, AColumna: Integer; ACampo: TField;
  const ADefinicion: TColumnaInformeTabular);
var
  oFecha: TDateTime;
  oFormato: TFormatSettings;
begin
  if not ACampo.IsNull then
  begin
    if ADefinicion.Numerica then
    begin
      AServicios.Escritor.Escribir(AFila, AColumna, ACampo.AsFloat);
      AServicios.Formateador.Alinear(AFila, AColumna, acDerecha);
      if ADefinicion.Formato = '%g' then
        AServicios.Formateador.AplicarFormato(AFila, AColumna, 'General')
      else
        AServicios.Formateador.AplicarFormato(AFila, AColumna, '#,##0.00');
    end
    else
    begin
      oFormato := TFormatSettings.Create;
      oFormato.ShortDateFormat := 'dd/mm/yyyy';
      oFormato.DateSeparator := '/';
      if ((ADefinicion.Campo = 'FECHA') or
          (ADefinicion.Campo = 'FECHA_ANT')) and
        TryStrToDate(Copy(ACampo.AsString, 1, 10), oFecha, oFormato) then
      begin
        AServicios.Escritor.Escribir(AFila, AColumna,
          VarFromDateTime(oFecha));
        AServicios.Formateador.AplicarFormato(AFila, AColumna,
          'dd/mm/yyyy ddd');
      end
      else
        AServicios.Escritor.Escribir(AFila, AColumna, ACampo.AsString);
    end;
  end;
end;

procedure EscribirDatos(const AServicios: TServiciosHojaCalculo;
  ADatos: TDataSet; const AColumnas: TColumnasInformeTabular);
var
  iColumna, iFila: Integer;
  sEtiqueta: string;
  bTotal: Boolean;
  oMarca: TBookmark;
begin
  for iColumna := 0 to High(AColumnas) do
  begin
    AServicios.Escritor.Escribir(0, iColumna, AColumnas[iColumna].Titulo);
    if AColumnas[iColumna].Numerica or
      (AColumnas[iColumna].Campo = 'FECHA') or
      (AColumnas[iColumna].Campo = 'FECHA_ANT') then
      AServicios.Formateador.Alinear(0, iColumna, acDerecha);
    AServicios.Formateador.Negrita(0, iColumna);
    AServicios.Formateador.FondoCelda(0, iColumna, $00EEEEEE);
    AServicios.Formateador.AnchoColumna(iColumna,
      Round(100 * AColumnas[iColumna].Peso + 40));
  end;
  oMarca := ADatos.Bookmark;
  ADatos.DisableControls;
  try
    ADatos.First;
    iFila := 1;
    while not ADatos.Eof do
    begin
      sEtiqueta := ADatos.FieldByName(AColumnas[0].Campo).AsString;
      bTotal := (sEtiqueta = SInformeTotal) or
        (sEtiqueta = SInformeTotalGeneral);
      for iColumna := 0 to High(AColumnas) do
      begin
        EscribirValor(AServicios, iFila, iColumna,
          ADatos.FieldByName(AColumnas[iColumna].Campo),
          AColumnas[iColumna]);
        if bTotal then
        begin
          AServicios.Formateador.Negrita(iFila, iColumna);
          AServicios.Formateador.FondoCelda(iFila, iColumna, $00F7EBDD);
        end;
      end;
      Inc(iFila);
      ADatos.Next;
    end;
  finally
    if ADatos.BookmarkValid(oMarca) then
      ADatos.Bookmark := oMarca;
    ADatos.EnableControls;
  end;
end;

procedure ExportarInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ATitulo: string;
  const AColumnas: TColumnasInformeTabular;
  const AResumen: TArray<string>);
var
  oHoja: TdxSpreadSheetTableView;
  oServicios: TServiciosHojaCalculo;
  i: Integer;
begin
  AControl.ClearAll;
  oHoja := AControl.AddSheet(SInformeHojaDatos,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oServicios := CrearServiciosHojaCalculoDevExTabla(oHoja);
  oServicios.Escritor.IniciarLote;
  try
    EscribirDatos(oServicios, ADatos, AColumnas);
  finally
    oServicios.Escritor.FinalizarLote;
  end;
  oHoja := AControl.AddSheet(SInformeHojaSeleccion,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oServicios := CrearServiciosHojaCalculoDevExTabla(oHoja);
  oServicios.Escritor.Escribir(0, 0, ATitulo);
  oServicios.Formateador.Negrita(0, 0);
  oServicios.Formateador.AnchoColumna(0, 1100);
  for i := 0 to High(AResumen) do
    oServicios.Escritor.Escribir(i + 2, 0, AResumen[i]);
  AControl.ActiveSheetIndex := 0;
end;

end.

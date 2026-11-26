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
  const AResumen: TArray<string>; ATotalGeneral: Boolean = False);

procedure AnadirHojaInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ANombre: string;
  const AColumnas: TColumnasInformeTabular;
  ATotalGeneral: Boolean = False;
  const ATituloCabecera: string = '';
  const AResumenCabecera: TArray<string> = nil);

// Las columnas de texto agrupan; solo se suman las columnas numéricas.
// ACampoIncluir permite excluir filas del resumen sin filtrar el detalle.
procedure AnadirResumenInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ANombre: string;
  const AColumnas: TColumnasInformeTabular;
  const ACampoIncluir: string = ''; ATotalGeneral: Boolean = True;
  const AResumenCabecera: TArray<string> = nil);

procedure AnadirSeleccionInformeExcel(AControl: TdxSpreadSheet;
  const ATitulo: string; const AResumen: TArray<string>);

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  Datasnap.DBClient, dxSpreadSheetCore,
  inLibHojaCalculoIntf,
  inLibHojaCalculoDevEx, inLibMsgInformesCliente, inLibResumenSeleccionesHoja;

procedure EscribirValor(const AServicios: TServiciosHojaCalculo;
  AFila, AColumna: Integer; ACampo: TField;
  const ADefinicion: TColumnaInformeTabular);
var
  oFecha: TDateTime;
  oFormato: TFormatSettings;
begin
  if not ACampo.IsNull then
  begin
    // Mantener las fechas nativas como numeros Excel con formato de fecha,
    // con independencia del nombre o del idioma del campo.
    if ADefinicion.FormatoExcel <> '' then
    begin
      case ACampo.DataType of
        ftDate, ftTime, ftDateTime, ftTimeStamp:
          AServicios.Escritor.Escribir(AFila, AColumna,
            VarFromDateTime(ACampo.AsDateTime));
        ftBoolean:
          AServicios.Escritor.Escribir(AFila, AColumna, ACampo.AsBoolean);
      else
        AServicios.Escritor.Escribir(AFila, AColumna, ACampo.AsString);
      end;
      AServicios.Formateador.AplicarFormato(AFila, AColumna,
        ADefinicion.FormatoExcel);
    end
    else if ACampo.DataType in [ftDate, ftDateTime, ftTimeStamp] then
    begin
      AServicios.Escritor.Escribir(AFila, AColumna,
        VarFromDateTime(ACampo.AsDateTime));
      AServicios.Formateador.AplicarFormato(AFila, AColumna,
        'dd/mm/yyyy');
    end
    else if ADefinicion.Numerica then
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
          (ADefinicion.Campo = 'FECHA_ANT') or
          (ADefinicion.Campo = 'CADUCIDAD_ETI')) and
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

function EscribirCabeceraDatos(const AServicios: TServiciosHojaCalculo;
  const ATitulo: string; const AResumen: TArray<string>;
  ANumColumnas: Integer): Integer;
begin
  Result := 0;
  if (ATitulo <> '') and (Length(AResumen) > 0) then
  begin
    if ANumColumnas > 1 then
      AServicios.Escritor.Combinar(0, 0, 1, ANumColumnas);
    AServicios.Escritor.Escribir(0, 0, ATitulo);
    AServicios.Formateador.Negrita(0, 0);
    Result := EscribirResumenSeleccionesHoja(AServicios.Escritor,
      AServicios.Formateador, 2, 0, AResumen, ANumColumnas);
  end;
end;

procedure EscribirDatos(const AServicios: TServiciosHojaCalculo;
  ADatos: TDataSet; const AColumnas: TColumnasInformeTabular;
  AFilaTitulos: Integer);
var
  iColumna, iFila: Integer;
  sEtiqueta: string;
  bTotal: Boolean;
  oMarca: TBookmark;
begin
  for iColumna := 0 to High(AColumnas) do
  begin
    AServicios.Escritor.Escribir(AFilaTitulos, iColumna,
      AColumnas[iColumna].Titulo);
    if AColumnas[iColumna].Numerica or
      (AColumnas[iColumna].Campo = 'FECHA') or
      (AColumnas[iColumna].Campo = 'FECHA_ANT') then
      AServicios.Formateador.Alinear(AFilaTitulos, iColumna, acDerecha);
    AServicios.Formateador.Negrita(AFilaTitulos, iColumna);
    AServicios.Formateador.FondoCelda(AFilaTitulos, iColumna, $00EEEEEE);
    AServicios.Formateador.AnchoColumna(iColumna,
      Round(100 * AColumnas[iColumna].Peso + 40));
  end;
  oMarca := ADatos.Bookmark;
  ADatos.DisableControls;
  try
    ADatos.First;
    iFila := AFilaTitulos + 1;
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

procedure AnadirHojaInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ANombre: string;
  const AColumnas: TColumnasInformeTabular;
  ATotalGeneral: Boolean;
  const ATituloCabecera: string;
  const AResumenCabecera: TArray<string>);
var
  oHoja: TdxSpreadSheetTableView;
  oServicios: TServiciosHojaCalculo;
  iFila, iFilaTitulos, iColumna, iIndice: Integer;
  sColumna: string;
begin
  oHoja := AControl.AddSheet(ANombre,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oServicios := CrearServiciosHojaCalculoDevExTabla(oHoja);
  oServicios.Escritor.IniciarLote;
  try
    iFilaTitulos := EscribirCabeceraDatos(oServicios, ATituloCabecera,
      AResumenCabecera, Length(AColumnas));
    EscribirDatos(oServicios, ADatos, AColumnas, iFilaTitulos);
    if ATotalGeneral then
    begin
      iFila := iFilaTitulos + ADatos.RecordCount + 1;
      oServicios.Escritor.Escribir(iFila, 0, SInformeTotalGeneral);
      for iColumna := 0 to High(AColumnas) do
      begin
        oServicios.Formateador.Negrita(iFila, iColumna);
        if AColumnas[iColumna].Numerica then
        begin
          sColumna := '';
          iIndice := iColumna + 1;
          while iIndice > 0 do
          begin
            Dec(iIndice);
            sColumna := Char(Ord('A') + iIndice mod 26) + sColumna;
            iIndice := iIndice div 26;
          end;
          if iFila > iFilaTitulos + 1 then
            oServicios.Escritor.EscribirFormula(iFila, iColumna,
              Format('=SUM(%s%d:%s%d)',
                [sColumna, iFilaTitulos + 2, sColumna, iFila]))
          else
            oServicios.Escritor.Escribir(iFila, iColumna, 0);
          if AColumnas[iColumna].Formato = '%g' then
            oServicios.Formateador.AplicarFormato(
              iFila, iColumna, 'General')
          else
            oServicios.Formateador.AplicarFormato(
              iFila, iColumna, '#,##0.00');
        end;
      end;
    end;
  finally
    oServicios.Escritor.FinalizarLote;
  end;
end;

procedure AnadirResumenInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ANombre: string;
  const AColumnas: TColumnasInformeTabular;
  const ACampoIncluir: string; ATotalGeneral: Boolean;
  const AResumenCabecera: TArray<string>);
var
  oIndice: TDictionary<string, Integer>;
  oFilas: TList<TArray<Variant>>;
  oResumen: TClientDataSet;
  oMarca: TBookmark;
  aValores: TArray<Variant>;
  sClave, sValor: string;
  i, iFila: Integer;
  bIncluir: Boolean;
begin
  oIndice := TDictionary<string, Integer>.Create;
  oFilas := TList<TArray<Variant>>.Create;
  oResumen := TClientDataSet.Create(nil);
  try
    for i := 0 to High(AColumnas) do
      if AColumnas[i].Numerica then
        oResumen.FieldDefs.Add(AColumnas[i].Campo, ftFloat)
      else
        oResumen.FieldDefs.Add(AColumnas[i].Campo, ftWideMemo);
    oResumen.CreateDataSet;
    oMarca := ADatos.Bookmark;
    ADatos.DisableControls;
    try
      ADatos.First;
      while not ADatos.Eof do
      begin
        bIncluir := True;
        if ACampoIncluir <> '' then
          bIncluir := ADatos.FieldByName(ACampoIncluir).AsInteger = 1;
        if bIncluir then
        begin
          sClave := '';
          for i := 0 to High(AColumnas) do
            if not AColumnas[i].Numerica then
            begin
              sValor := ADatos.FieldByName(AColumnas[i].Campo).AsString;
              sClave := sClave + IntToStr(Length(sValor)) + ':' + sValor;
            end;
          if oIndice.TryGetValue(sClave, iFila) then
            aValores := oFilas[iFila]
          else
          begin
            aValores := nil;
            SetLength(aValores, Length(AColumnas));
            for i := 0 to High(AColumnas) do
              if AColumnas[i].Numerica then
                aValores[i] := 0.0
              else
                aValores[i] :=
                  ADatos.FieldByName(AColumnas[i].Campo).AsString;
            oIndice.Add(sClave, oFilas.Add(aValores));
          end;
          for i := 0 to High(AColumnas) do
            if AColumnas[i].Numerica then
              aValores[i] := aValores[i] +
                ADatos.FieldByName(AColumnas[i].Campo).AsFloat;
        end;
        ADatos.Next;
      end;
    finally
      if ADatos.BookmarkValid(oMarca) then
        ADatos.Bookmark := oMarca;
      ADatos.EnableControls;
    end;
    for aValores in oFilas do
    begin
      oResumen.Append;
      for i := 0 to High(AColumnas) do
        oResumen.Fields[i].Value := aValores[i];
      oResumen.Post;
    end;
    AnadirHojaInformeTabularExcel(AControl, oResumen, ANombre,
      AColumnas, ATotalGeneral, ANombre, AResumenCabecera);
  finally
    oResumen.Free;
    oFilas.Free;
    oIndice.Free;
  end;
end;

procedure AnadirSeleccionInformeExcel(AControl: TdxSpreadSheet;
  const ATitulo: string; const AResumen: TArray<string>);
var
  oHoja: TdxSpreadSheetTableView;
  oServicios: TServiciosHojaCalculo;
  i: Integer;
begin
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

procedure ExportarInformeTabularExcel(AControl: TdxSpreadSheet;
  ADatos: TDataSet; const ATitulo: string;
  const AColumnas: TColumnasInformeTabular;
  const AResumen: TArray<string>; ATotalGeneral: Boolean);
begin
  AControl.ClearAll;
  AnadirHojaInformeTabularExcel(AControl, ADatos, SInformeHojaDatos,
    AColumnas, ATotalGeneral, ATitulo, AResumen);
  AnadirSeleccionInformeExcel(AControl, ATitulo, AResumen);
end;

end.

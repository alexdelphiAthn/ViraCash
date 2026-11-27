{ Impresión de una sesión de medidas desde su histórico. }
unit inMtoModalImpMedidasCliente;

interface

uses
  System.Classes, Datasnap.DBClient, frxClass, frxDBSet, inMtoModalGenImp,
  inLibMedidasCliente;

type
  TfrmPrintMedidasCliente = class(TfrmPrint)
  private
    FCabecera, FDetalle: TClientDataSet;
    procedure Preparar(const ASesion: TSesionMedidasCliente;
      const ANombre: string; AFicha: TFichaMedidas);
  public
    procedure preparar_consulta; override;
    class procedure Abrir(AOwner: TComponent;
      const ASesion: TSesionMedidasCliente; const ANombre: string;
      AFicha: TFichaMedidas);
  end;

implementation

uses
  System.SysUtils, Data.DB, Vcl.Graphics, frCoreClasses, frBaseGraphicsTypes,
  inLibTraducciones, inLibTraduccionesIntf,
  inLibIdiomaConsultoria, inLibInformeTabular, inLibMsgMedidasCliente, inLibDibujoMedidas;

function RotuloMagnitud(const Medida: TMedidaCliente): string;
const
  Codigos: array[0..11] of string = ('HOMBROS', 'PECHO', 'CINTURA',
    'MANGA', 'LARGO', 'ROPA_CADERA',
    'PIE_LARGO_I', 'PIE_LARGO_D', 'PIE_ANCHO_I',
    'PIE_ANCHO_D', 'PIE_EMPEINE_I', 'PIE_EMPEINE_D');
var
  I: Integer;
begin
  Result := Medida.Nombre;
  for I := Low(Codigos) to High(Codigos) do
    if SameText(Codigos[I], Medida.Codigo) then
    begin
      Result := TextoMedidaCatalogo(Medida.Nombre);
      Break;
    end;
end;

procedure TfrmPrintMedidasCliente.preparar_consulta;
begin
  FCabecera.First;
  FDetalle.First;
end;

procedure TfrmPrintMedidasCliente.Preparar(const ASesion: TSesionMedidasCliente;
  const ANombre: string; AFicha: TFichaMedidas);
const
  Tinta = $00443B1B;
  Verde = $00565A19;
  Papel = $00F2F5EE;
var
  Cabecera, Detalle: TfrxDBDataset;
  Banda: TfrxPageHeader;
  Resumen: TfrxReportSummary;
  Memo: TfrxMemoView;
  Dibujo: TfrxPictureView;
  Valor: TMedidaCliente;
  Notas, TextoValor, Magnitud, Leyenda: string;
  Ancho: Double;
  Traducciones: IServicioTraducciones;
  Objeto: TfrxComponent;
  i, Marca, AltoGuia: Integer;

  function Enlazar(Datos: TClientDataSet; const Alias: string): TfrxDBDataset;
  begin
    Result := TfrxDBDataset.Create(Self);
    Result.Name := 'ds' + Alias;
    Result.UserName := Alias;
    Result.DataSet := Datos;
  end;

  function Texto(Padre: TfrxBand; const Nombre, Contenido: string;
    X, Y, W, H: Double; Puntos: Integer): TfrxMemoView;
  begin
    Result := TfrxMemoView.Create(Padre);
    Result.Name := Nombre;
    Result.SetBounds(X, Y, W, H);
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := Puntos;
    Result.Font.Color := Tinta;
    Result.Text := Contenido;
    Result.AllowExpressions := False;
  end;

  procedure Campo(Padre: TfrxBand; const Nombre: string; X, Y, W, H: Double;
    Puntos: Integer);
  begin
    Memo := Texto(Padre, 'txt' + Nombre, '', X, Y, W, H, Puntos);
    Memo.DataSet := Cabecera;
    Memo.DataField := Nombre;
    Memo.StretchMode := smActualHeight;
  end;

begin
  Caption := TextoConsultoria(TituloFichaMedidas(AFicha));
  MostrarDisenosGuardados := True;
  FCabecera := TClientDataSet.Create(Self);
  FCabecera.FieldDefs.Add('Cliente', ftWideString, 300);
  FCabecera.FieldDefs.Add('Fecha', ftWideString, 50);
  FCabecera.FieldDefs.Add('Persona', ftWideString, 100);
  FCabecera.FieldDefs.Add('Notas', ftWideMemo);
  FCabecera.CreateDataSet;
  Notas := ASesion.Observaciones;
  if ASesion.Motivo <> '' then
    Notas := Trim(Notas + sLineBreak + TextoConsultoria(SMedidasMotivo) + ': ' + ASesion.Motivo);
  FCabecera.AppendRecord([Trim(ASesion.Cliente + '  ' + ANombre),
    DateToStr(ASesion.Fecha), ASesion.Persona, Notas]);
  FDetalle := TClientDataSet.Create(Self);
  FDetalle.FieldDefs.Add('Magnitud', ftWideString, 100);
  FDetalle.FieldDefs.Add('Valor', ftWideString, 40);
  FDetalle.FieldDefs.Add('Unidad', ftWideString, 10);
  FDetalle.FieldDefs.Add('Orden', ftInteger);
  FDetalle.CreateDataSet;
  for Valor in ASesion.Valores do
  begin
    if IncluyeMagnitud(AFicha, Valor.Codigo) then
    begin
      TextoValor := TextoConsultoria(SMedidasDesconocida);
      if Valor.Conocida then
        TextoValor := FormatCurr('0.##', Valor.Valor);
      Magnitud := RotuloMagnitud(Valor);
      Marca := MarcaMagnitud(AFicha, Valor.Codigo);
      if Marca > 0 then
        Magnitud := IntToStr(Marca) + '    ' + Magnitud
      else
        Marca := 99;
      FDetalle.AppendRecord([Magnitud, TextoValor, Valor.Unidad, Marca]);
    end;
  end;
  FDetalle.IndexFieldNames := 'Orden;Magnitud';
  preparar_consulta;
  Detalle := Enlazar(FDetalle, 'Medidas');
  Cabecera := Enlazar(FCabecera, 'Sesion');
  CrearInformeTabular(frxReportOrigen, Detalle, Caption,
    [ColumnaInforme('Magnitud', TextoConsultoria(SMedidasMagnitud), 62),
     ColumnaInforme('Valor', TextoConsultoria(SMedidasValor), 23),
     ColumnaInforme('Unidad', TextoConsultoria(SMedidasUnidad), 15)], True);
  frxReportOrigen.EnabledDataSets.Add(Cabecera);
  frxReportOrigen.DataSets.Add(Cabecera);
  Banda := frxReportOrigen.FindObject('CabeceraTabla') as TfrxPageHeader;
  AltoGuia := 0;
  if AFicha <> fmCompleta then AltoGuia := 195;
  Banda.Height := 154 + AltoGuia;
  Banda.Stretched := True;
  Memo := frxReportOrigen.FindObject('TituloTabla') as TfrxMemoView;
  Ancho := Memo.Width;
  Memo.SetBounds(0, 0, Ancho, 39);
  Memo.Font.Name := 'Segoe UI';
  Memo.Font.Size := 19;
  Memo.Font.Color := clWhite;
  Memo.Color := Verde;
  Memo.GapX := 10;
  Memo.VAlign := vaCenter;
  Texto(Banda, 'RotuloCliente', TextoConsultoria(SMedidasCliente), 0, 49, Ancho * 0.50, 16, 9);
  Texto(Banda, 'RotuloFecha', TextoConsultoria(SMedidasFecha), Ancho * 0.50, 49,
    Ancho * 0.20, 16, 9);
  Texto(Banda, 'RotuloPersona', TextoConsultoria(SMedidasPersona), Ancho * 0.71, 49,
    Ancho * 0.29, 16, 9);
  Campo(Banda, 'Cliente', 0, 68, Ancho * 0.48, 48, 12);
  Campo(Banda, 'Fecha', Ancho * 0.50, 68, Ancho * 0.20, 48, 12);
  Campo(Banda, 'Persona', Ancho * 0.71, 68, Ancho * 0.29, 48, 12);
  if AltoGuia > 0 then
  begin
    Dibujo := TfrxPictureView.Create(Banda);
    Dibujo.Name := 'GuiaTaller';
    Dibujo.SetBounds(26, 116, 245, 188);
    Dibujo.KeepAspectRatio := True;
    Dibujo.ShiftMode := smWhenOverlapped;
    DibujarGuiaMedidas(Dibujo.Picture, AFicha);
    Texto(Banda, 'TituloGuia', TextoConsultoria(SMedidasGuia), 315, 136, Ancho - 320,
      26, 13).Font.Style := [fsBold];
    if AFicha in [fmPieIzquierdo, fmPieDerecho] then
      Leyenda := TextoConsultoria(SMedidasGuiaPie)
    else
      Leyenda := TextoConsultoria(SMedidasGuiaRopa);
    if AFicha = fmRopa then
      Leyenda := Leyenda + '|' + TextoConsultoria(SMedidasGuiaCadera);
    Memo := Texto(Banda, 'LeyendaGuia', StringReplace(Leyenda, '|',
      sLineBreak, [rfReplaceAll]), 315, 172, Ancho - 320, 128, 11);
    Memo.LineSpacing := 4;
  end;
  for i := 0 to 2 do
  begin
    Memo := frxReportOrigen.FindObject('Cabecera' + IntToStr(i)) as TfrxMemoView;
    Memo.Top := 126 + AltoGuia;
    Memo.Height := 26;
    Memo.VAlign := vaCenter;
    Memo.Color := Papel;
    Memo.Font.Color := Verde;
    Memo.Font.Size := 10;
    Memo.GapX := 6;
    Memo.ShiftMode := smWhenOverlapped;
    Memo := frxReportOrigen.FindObject('Dato' + IntToStr(i)) as TfrxMemoView;
    Memo.Font.Name := 'Segoe UI';
    Memo.Font.Size := 10;
    Memo.Font.Color := Tinta;
    Memo.GapX := 6;
    Memo.Frame.Typ := [ftBottom];
    Memo.Frame.Color := Papel;
    Memo.AllowExpressions := False;
  end;
  frxReportOrigen.FindObject('DetalleTabla').Top := 165 + AltoGuia;
  Resumen := TfrxReportSummary.Create(Banda.Parent);
  Resumen.Name := 'NotasSesion';
  Resumen.Top := 220 + AltoGuia;
  Resumen.Height := 60;
  Resumen.Stretched := True;
  Resumen.AllowSplit := True;
  Texto(Resumen, 'RotuloNotas', TextoConsultoria(SMedidasObservaciones), 0, 12, Ancho, 19,
    11).Font.Style := [fsBold];
  Campo(Resumen, 'Notas', 0, 36, Ancho, 24, 10);
  if AFicha <> fmCompleta then
  begin
    Resumen.Height := 132;
    Memo := Texto(Resumen, 'RotuloAjustes', TextoConsultoria(SMedidasPrueba), 0, 68,
      Ancho, 22, 11);
    Memo.Font.Style := [fsBold];
    Memo.ShiftMode := smAlways;
    Memo := Texto(Resumen, 'EspacioAjustes', '', 0, 92, Ancho, 30, 10);
    Memo.Frame.Typ := [ftBottom];
    Memo.Frame.Color := Verde;
    Memo.ShiftMode := smAlways;
  end;
  frxReportOrigen.FindObject('PieTabla').Top := 400 + AltoGuia;
  Memo := frxReportOrigen.FindObject('PaginaTabla') as TfrxMemoView;
  Memo.Text := TextoConsultoria('Página [Page#] de [TotalPages#]');
  Memo.HAlign := haRight;
  Texto(Memo.Parent as TfrxBand, 'Marca', 'ViraCash', 0, 0, Ancho / 2, 18, 9);
  Traducciones := ResolverServicioTraducciones(Self);
  if Assigned(Traducciones) and
    SameText(Traducciones.Idioma, IDIOMA_CHINO_SIMPLIFICADO) then
  begin
    frxpdfxprtPedWeb.EmbeddedFonts := True;
    for i := 0 to frxReportOrigen.AllObjects.Count - 1 do
    begin
      Objeto := TfrxComponent(frxReportOrigen.AllObjects[i]);
      if Objeto is TfrxMemoView then
        TfrxMemoView(Objeto).Font.Name := 'Microsoft YaHei';
    end;
  end;
end;

class procedure TfrmPrintMedidasCliente.Abrir(AOwner: TComponent;
  const ASesion: TSesionMedidasCliente; const ANombre: string;
  AFicha: TFichaMedidas);
const
  Informes: array[TFichaMedidas] of string = ('frmPrintMedidasCliente',
    'frmMedidasPieIzquierdo', 'frmMedidasPieDerecho', 'frmMedidasTraje',
    'frmMedidasRopa');
var
  Dialogo: TfrmPrintMedidasCliente;
begin
  Dialogo := TfrmPrintMedidasCliente.Create(AOwner);
  try
    Dialogo.Name := Informes[AFicha];
    Dialogo.Preparar(ASesion, ANombre, AFicha);
    Dialogo.ShowModal;
  finally
    Dialogo.Free;
  end;
end;

end.

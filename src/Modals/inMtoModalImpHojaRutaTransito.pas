{ Módulo: inMtoModalImpHojaRutaTransito. Tipo: formulario de impresión.
  Versión: 1.0.0. Fecha: 26/10/2026. Autor: ViraCash.
  Hoja de ruta por viaje y albaranes origen-destino (FZ-ISSUE-718).
  Copyright (c) Alejandro Laorden Hidalgo. SPDX-License-Identifier: MPL-2.0. }
unit inMtoModalImpHojaRutaTransito;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni,
  frxClass, frxDBSet, cxTextEdit, cxCheckListBox, inMtoModalGenImp;

type
  TfrmPrintHojaRutaTransito = class(TfrmPrint)
  private
    FTransito: string;
    FConexion: TUniConnection;
    FDatos: TUniQuery;
    FDataset: TfrxDBDataset;
    FImprimir: Boolean;
    FExportar: Boolean;
    FInicializado: Boolean;
    FIdsCargas: TArray<Int64>;
    edtViaje: TcxTextEdit;
    clbCargas: TcxCheckListBox;
    procedure CrearSeleccionViaje;
    procedure CargarCargasViaje;
    function CargasSeleccionadas: TArray<Int64>;
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
    procedure AvisarAntesDeConsulta; override;
  public
    class procedure Ejecutar(AOwner: TComponent;
      AConexion: TUniConnection; const ATransito: string;
      APuedeImprimir, APuedeExportar: Boolean); static;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

procedure CrearFormatoHojaRuta(AInforme: TfrxReport;
  ADataset: TfrxDBDataset);
procedure AsignarTextosHojaRuta(AInforme: TfrxReport);

implementation

uses
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, cxCheckBox, cxLabel,
  cxLookAndFeelPainters, frBaseGraphicsTypes, inLibMsgCaja,
  inLibMensajesVcl,
  UniDataCargasTransito;

{$R *.dfm}

function AgregarMemo(ABanda: TfrxBand; const ANombre, ATexto: string;
  AIzq, ATop, AAncho, AAlto: Extended; ANegrita: Boolean = False): TfrxMemoView;
var
  Memo: TfrxMemoView;
begin
  Memo := TfrxMemoView.Create(ABanda);
  Memo.Name := ANombre;
  Memo.SetBounds(AIzq, ATop, AAncho, AAlto);
  Memo.Font.Name := 'Arial';
  Memo.Font.Size := 9;
  if ANegrita then
    Memo.Font.Style := [fsBold];
  Memo.Text := ATexto;
  Memo.WordWrap := True;
  Result := Memo;
end;

const
  // Misma paleta y tipografía que los presupuestos comerciales.
  COLOR_FONDO_RUTA = $00EAEAEA;
  COLOR_LINEA_RUTA = $00C8C8C8;
  COLOR_TENUE_RUTA = $00666666;

function CajaRuta(ABanda: TfrxBand; const ANombre: string;
  AIzq, ATop, AAncho, AAlto: Extended): TfrxMemoView;
begin
  Result := AgregarMemo(ABanda, ANombre, '', AIzq, ATop, AAncho, AAlto);
  Result.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  Result.Frame.Color := COLOR_LINEA_RUTA;
  Result.Color := clWhite;
end;

procedure CrearTituloRuta(ABanda: TfrxBand; const ATitulo: string);
var
  Texto: TfrxMemoView;
begin
  Texto := AgregarMemo(ABanda, 'Marca'+ABanda.Name,
    'VIRACASH', 0, 0, 350, 14, True);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto := AgregarMemo(ABanda, 'Titulo'+ABanda.Name,
    ATitulo, 0, 20, 410, 30, True);
  Texto.Font.Size := 18;
  Texto := AgregarMemo(ABanda, 'Viaje'+ABanda.Name,
    '[CAP_VIAJE]: [VIAJE]', 430, 0, 288, 38, True);
  Texto.HAlign := haRight;
  Texto := AgregarMemo(ABanda, 'Fecha'+ABanda.Name,
    '[Date]  [Time]', 430, 40, 288, 16);
  Texto.HAlign := haRight;
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto := AgregarMemo(ABanda, 'Linea'+ABanda.Name,
    '', 0, 62, 718, 1);
  Texto.Frame.Typ := [ftBottom];
  Texto.Frame.Color := COLOR_LINEA_RUTA;
end;

procedure CrearSujetoRuta(ABanda: TfrxBand;
  const APrefijo, ARotulo, AEmpresa, AAlmacen: string;
  AIzq, ATop: Extended);
var
  Texto: TfrxMemoView;
begin
  CajaRuta(ABanda, APrefijo+'Caja', AIzq, ATop, 350, 114);
  Texto := AgregarMemo(ABanda, APrefijo+'Rotulo', ARotulo,
    AIzq, ATop, 350, 24, True);
  Texto.Color := COLOR_FONDO_RUTA;
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto.GapX := 10;
  Texto.GapY := 6;
  Texto := AgregarMemo(ABanda, APrefijo+'Empresa', AEmpresa,
    AIzq+10, ATop+32, 330, 34, True);
  Texto.Font.Size := 10;
  AgregarMemo(ABanda, APrefijo+'Almacen', AAlmacen,
    AIzq+10, ATop+72, 330, 34);
end;

procedure CrearTitulosTablaRuta(ABanda: TfrxBand);
const
  IZQUIERDAS: array[0..5] of Integer = (0,160,462,528,594,654);
  ANCHOS: array[0..5] of Integer = (160,302,66,66,60,64);
var
  I: Integer;
  Texto: TfrxMemoView;
  Titulos: TArray<string>;
begin
  Titulos := ['SKU / [CAP_LOTE]', '[CAP_DESCRIPCION]',
    '[CAP_UNIDADES]', '[CAP_RECIBIDAS]', '[CAP_TARAS]', '[CAP_PERDIDAS]'];
  for I := 0 to High(Titulos) do
  begin
    Texto := AgregarMemo(ABanda, 'ColumnaRuta'+IntToStr(I), Titulos[I],
      IZQUIERDAS[I], 276, ANCHOS[I], 26, True);
    Texto.Color := COLOR_FONDO_RUTA;
    Texto.Font.Size := 8;
    Texto.GapX := 5;
    Texto.GapY := 6;
    Texto.Frame.Typ := [ftTop,ftBottom];
    Texto.Frame.Color := COLOR_LINEA_RUTA;
    if I = 2 then
      Texto.HAlign := haRight
    else if I > 2 then
      Texto.HAlign := haCenter;
  end;
end;

procedure CrearCabeceraRuta(APagina: TfrxReportPage);
var
  Banda: TfrxGroupHeader;
  Texto: TfrxMemoView;
begin
  Banda := TfrxGroupHeader.Create(APagina);
  Banda.Name := 'CabeceraDestino';
  Banda.Height := 302;
  Banda.Top := 20;
  Banda.Condition := 'Ruta."GRUPO"';
  Banda.StartNewPage := True;
  Banda.ReprintOnNewPage := True;
  CrearTituloRuta(Banda,'[TITULO_ALBARAN]');
  CrearSujetoRuta(Banda,'Emisor','[CAP_ENTREGA]',
    '[Ruta."ENTREGA"]','[CAP_ORIGEN]: [Ruta."ORIGEN"]',0,78);
  CrearSujetoRuta(Banda,'Receptor','[CAP_RECIBE]',
    '[Ruta."RECIBE"]','[CAP_DESTINO]: [Ruta."DESTINO"]',368,78);
  Texto := AgregarMemo(Banda,'TransitoRuta',
    '[CAP_TRANSITO] [Ruta."TRANSITO"]',0,204,718,26,True);
  Texto.Color := COLOR_FONDO_RUTA;
  Texto.GapX := 8;
  Texto.GapY := 6;
  Texto := AgregarMemo(Banda,'NotaCotejo','[NOTA_COTEJO]',0,240,718,28);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  CrearTitulosTablaRuta(Banda);
end;

procedure EstilarCeldasRuta(ADetalle: TfrxMasterData);
var
  I: Integer;
  Celda: TfrxMemoView;
begin
  for I := 0 to ADetalle.Objects.Count-1 do
    if TObject(ADetalle.Objects[I]) is TfrxMemoView then
    begin
      Celda := TfrxMemoView(ADetalle.Objects[I]);
      Celda.Frame.Typ := [ftBottom];
      Celda.Frame.Color := COLOR_LINEA_RUTA;
      Celda.GapX := 5;
      Celda.GapY := 5;
      Celda.VAlign := vaTop;
      Celda.StretchMode := smMaxHeight;
      if Celda.Left >= 462 then
      begin
        Celda.HAlign := haRight;
        Celda.StretchMode := smMaxHeight;
      end;
    end;
end;

procedure CrearDetalleRuta(APagina: TfrxReportPage;
  ADataset: TfrxDBDataset);
var
  Carga: TfrxGroupHeader;
  Detalle: TfrxMasterData;
  Unidades: TfrxMemoView;
begin
  Carga := TfrxGroupHeader.Create(APagina);
  Carga.Name := 'CabeceraCarga';
  Carga.Top := 340;
  Carga.Height := 42;
  Carga.Condition := 'Ruta."ID_CARGA"';
  Carga.ReprintOnNewPage := True;
  AgregarMemo(Carga,'CargaRuta',
    '[CAP_CARGA] [Ruta."ID_CARGA"] / [Ruta."DOCUMENTO"] / ' +
    '[CAP_OPERACION] [Ruta."OPERACION"]', 0, 3, 718, 18, True);
  AgregarMemo(Carga,'OrigenRuta',
    '[CAP_ORIGEN]: [Ruta."ORIGEN"] / [Ruta."FECHA_CARGA"]', 0, 23, 718, 18);
  Detalle := TfrxMasterData.Create(APagina);
  Detalle.Name := 'DetalleRuta';
  Detalle.Top := 400;
  Detalle.Height := 34;
  Detalle.Stretched := True;
  Detalle.AllowSplit := False;
  Detalle.DataSet := ADataset;
  AgregarMemo(Detalle,'SkuRuta',
    '[Ruta."SKU"]'+#13#10+'[Ruta."LOTE"]', 0, 0, 160, 32);
  AgregarMemo(Detalle,'DescripcionRuta','[Ruta."DESCRIPCION"]',
    160, 0, 302, 32);
  TfrxMemoView(Detalle.FindObject('SkuRuta')).StretchMode :=
    smActualHeight;
  TfrxMemoView(Detalle.FindObject('DescripcionRuta')).StretchMode :=
    smActualHeight;
  AgregarMemo(Detalle,'UnidadesRuta','[Ruta."UNIDADES"]', 462, 0, 66, 32);
  Unidades := TfrxMemoView(Detalle.FindObject('UnidadesRuta'));
  Unidades.Text :=
    '[FormatFloat(''#,##0.###'', <Ruta."UNIDADES">)]';
  AgregarMemo(Detalle,'RecibidasRuta','',528,0,66,32);
  AgregarMemo(Detalle,'TarasRuta','',594,0,60,32);
  AgregarMemo(Detalle,'PerdidasRuta','',654,0,64,32);
  EstilarCeldasRuta(Detalle);
end;

procedure CrearPiePaginaRuta(APagina: TfrxReportPage;
  const ANombre: string);
var
  Pie: TfrxPageFooter;
  Texto: TfrxMemoView;
begin
  Pie := TfrxPageFooter.Create(APagina);
  Pie.Name := ANombre;
  Pie.Top := 900;
  Pie.Height := 24;
  Texto := AgregarMemo(Pie,ANombre+'Referencia',
    'VIRACASH  /  [VIAJE]',0,0,570,24);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto.Frame.Typ := [ftTop];
  Texto.Frame.Color := COLOR_LINEA_RUTA;
  Texto.GapY := 6;
  Texto := AgregarMemo(Pie,ANombre+'Numero','[Page#]',570,0,148,24);
  Texto.HAlign := haRight;
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto.Frame.Typ := [ftTop];
  Texto.Frame.Color := COLOR_LINEA_RUTA;
  Texto.GapY := 6;
end;

procedure CrearPieRuta(APagina: TfrxReportPage);
var
  PieCarga, PieDestino: TfrxGroupFooter;
  Texto: TfrxMemoView;
begin
  PieCarga := TfrxGroupFooter.Create(APagina);
  PieCarga.Name := 'PieCarga';
  PieCarga.Top := 460;
  PieCarga.Height := 4;
  PieDestino := TfrxGroupFooter.Create(APagina);
  PieDestino.Name := 'PieDestino';
  PieDestino.Top := 480;
  PieDestino.Height := 208;
  Texto := AgregarMemo(PieDestino,'TotalRuta',
    '[CAP_TOTAL]: [SUM(<Ruta."UNIDADES">,DetalleRuta)]',400,12,318,34,True);
  Texto.Color := COLOR_FONDO_RUTA;
  Texto.Font.Size := 10;
  Texto.HAlign := haRight;
  Texto.GapX := 10;
  Texto.GapY := 8;
  Texto := AgregarMemo(PieDestino,'NotaFiscalRuta','[NOTA_FISCAL]',
    0,62,718,38);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  CajaRuta(PieDestino,'CajaFirma',0,122,350,70);
  CajaRuta(PieDestino,'CajaFecha',368,122,350,70);
  Texto := AgregarMemo(PieDestino,'FirmaRuta','[FIRMA]',10,132,330,22);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  Texto := AgregarMemo(PieDestino,'FechaRuta','[FECHA_ENTREGA]',
    378,132,330,22);
  Texto.Font.Size := 8;
  Texto.Font.Color := COLOR_TENUE_RUTA;
  CrearPiePaginaRuta(APagina,'PiePaginaRuta');
end;

procedure AsignarTextosHojaRuta(AInforme: TfrxReport);
var
  I: Integer;
  Ch: Char;
  EsCjk: Boolean;
  procedure Texto(const AClave, AValor: string);
  begin
    AInforme.Variables[AClave] := QuotedStr(AValor);
  end;
begin
  Texto('TITULO', SCaptionHojaRutaTransito);
  Texto('TITULO_ALBARAN', SCaptionAlbaranHojaRuta);
  Texto('CAP_VIAJE', SCaptionViajeHojaRuta);
  Texto('CAP_TRANSITO', SCaptionFiltroTransito);
  Texto('CAP_ENTREGA', SCaptionEntregaHojaRuta);
  Texto('CAP_RECIBE', SCaptionRecibeHojaRuta);
  Texto('CAP_DESTINO', SCaptionColDestinoCargaTransito);
  Texto('CAP_ORIGEN', SCaptionColOrigenCargaTransito);
  Texto('CAP_CARGA', SCaptionColNumeroCargaTransito);
  Texto('CAP_OPERACION', SCaptionColOperacionCargaTransito);
  Texto('CAP_LOTE', SCaptionLoteHojaRuta);
  Texto('CAP_DESCRIPCION', SCaptionColDescripcionRepartoTransito);
  Texto('CAP_UNIDADES', SCaptionColUnidadesCargaTransito);
  Texto('CAP_RECIBIDAS', SCaptionRecibidasHojaRuta);
  Texto('CAP_TARAS', SCaptionTarasHojaRuta);
  Texto('CAP_PERDIDAS', SCaptionPerdidasHojaRuta);
  Texto('CAP_TOTAL', SCaptionTotalHojaRuta);
  Texto('NOTA_COTEJO', SNotaCotejoHojaRuta);
  Texto('NOTA_FISCAL', SNotaHojaRutaTransito);
  Texto('FIRMA', STextoFirmaHojaRuta.Replace('_','').Trim);
  Texto('FECHA_ENTREGA', STextoFechaHojaRuta.Replace('_','').Trim);
  EsCjk := False;
  for Ch in SCaptionHojaRutaTransito do
    EsCjk := EsCjk or ((Ord(Ch)>=$2E80) and (Ord(Ch)<=$9FFF));
  if EsCjk then
    for I := 0 to AInforme.AllObjects.Count-1 do
      if TObject(AInforme.AllObjects[I]) is TfrxMemoView then
        TfrxMemoView(AInforme.AllObjects[I]).Font.Name := 'Microsoft YaHei';
end;

procedure CrearResumenViaje(APagina: TfrxReportPage;
  ADataset: TfrxDBDataset);
var
  Titulo: TfrxReportTitle;
  Carga: TfrxGroupHeader;
  Detalle: TfrxMasterData;
  Total: TfrxGroupFooter;
  Texto: TfrxMemoView;
begin
  Titulo := TfrxReportTitle.Create(APagina);
  Titulo.Name := 'TituloViaje';
  Titulo.Top := 0;
  Titulo.Height := 122;
  CrearTituloRuta(Titulo,'[TITULO]');
  Texto := AgregarMemo(Titulo,'TransitoResumen',
    '[CAP_TRANSITO] [Ruta."TRANSITO"]',0,78,718,28,True);
  Texto.Color := COLOR_FONDO_RUTA;
  Texto.GapX := 8;
  Texto.GapY := 7;
  Carga := TfrxGroupHeader.Create(APagina);
  Carga.Name := 'CargaViaje';
  Carga.Top := 140;
  Carga.Height := 158;
  Carga.Condition := 'Ruta."ID_CARGA"';
  Texto := AgregarMemo(Carga,'ReferenciaCargaViaje',
    '[CAP_CARGA] [Ruta."ID_CARGA"] / [Ruta."DOCUMENTO"] / ' +
    '[CAP_OPERACION] [Ruta."OPERACION"]',0,0,718,22,True);
  Texto.Font.Color := COLOR_TENUE_RUTA;
  CrearSujetoRuta(Carga,'EmisorViaje','[CAP_ENTREGA]',
    '[Ruta."ENTREGA"]','[CAP_ORIGEN]: [Ruta."ORIGEN"]',0,30);
  CrearSujetoRuta(Carga,'ReceptorViaje','[CAP_RECIBE]',
    '[Ruta."RECIBE"]','[CAP_DESTINO]: [Ruta."DESTINO"]',368,30);
  Detalle := TfrxMasterData.Create(APagina);
  Detalle.Name := 'DetalleViaje';
  Detalle.Top := 320;
  Detalle.Height := 0;
  Detalle.DataSet := ADataset;
  Total := TfrxGroupFooter.Create(APagina);
  Total.Name := 'TotalCargaViaje';
  Total.Top := 340;
  Total.Height := 40;
  Texto := AgregarMemo(Total,'UnidadesViaje',
    '[CAP_TOTAL]: [SUM(<Ruta."UNIDADES">,DetalleViaje)]',400,0,318,26,True);
  Texto.HAlign := haRight;
  Texto.Color := COLOR_FONDO_RUTA;
  Texto.GapX := 8;
  Texto.GapY := 6;
  CrearPiePaginaRuta(APagina,'PiePaginaViaje');
end;

procedure CrearFormatoHojaRuta(AInforme: TfrxReport;
  ADataset: TfrxDBDataset);
var
  Pagina: TfrxReportPage;
begin
  AInforme.Clear;
  ADataset.UserName := 'Ruta';
  AInforme.DataSets.Add(ADataset);
  Pagina := TfrxReportPage.Create(AInforme);
  Pagina.Name := 'PaginaRuta';
  Pagina.SetDefaults;
  Pagina.PaperWidth := 210;
  Pagina.PaperHeight := 297;
  Pagina.LeftMargin := 10;
  Pagina.RightMargin := 10;
  Pagina.TopMargin := 10;
  Pagina.BottomMargin := 10;
  Pagina.Name := 'PaginaViaje';
  CrearResumenViaje(Pagina, ADataset);
  Pagina := TfrxReportPage.Create(AInforme);
  Pagina.Name := 'PaginaAlbaranes';
  Pagina.SetDefaults;
  Pagina.PaperWidth := 210;
  Pagina.PaperHeight := 297;
  Pagina.LeftMargin := 10;
  Pagina.RightMargin := 10;
  Pagina.TopMargin := 10;
  Pagina.BottomMargin := 10;
  CrearCabeceraRuta(Pagina);
  CrearDetalleRuta(Pagina, ADataset);
  CrearPieRuta(Pagina);
  AsignarTextosHojaRuta(AInforme);
  AInforme.Variables['VIAJE'] := QuotedStr('');
end;

procedure TfrmPrintHojaRutaTransito.CrearSeleccionViaje;
var
  Etiqueta: TcxLabel;
begin
  ClientWidth := ScaleValue(900);
  ClientHeight := ScaleValue(440);
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Self;
  Etiqueta.SetBounds(ScaleValue(12), ScaleValue(12),
    ScaleValue(700), ScaleValue(38));
  Etiqueta.AutoSize := False;
  Etiqueta.Transparent := True;
  Etiqueta.Properties.WordWrap := True;
  Etiqueta.Caption := STextoAyudaHojaRuta;
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Self;
  Etiqueta.SetBounds(ScaleValue(12), ScaleValue(58),
    ScaleValue(70), ScaleValue(28));
  Etiqueta.Transparent := True;
  Etiqueta.Caption := SCaptionViajeHojaRuta;
  edtViaje := TcxTextEdit.Create(Self);
  edtViaje.Parent := Self;
  edtViaje.SetBounds(ScaleValue(90), ScaleValue(58),
    ScaleValue(622), ScaleValue(28));
  edtViaje.Properties.MaxLength := 100;
  clbCargas := TcxCheckListBox.Create(Self);
  clbCargas.Parent := Self;
  clbCargas.SetBounds(ScaleValue(12), ScaleValue(100),
    ScaleValue(700), ScaleValue(310));
end;

procedure TfrmPrintHojaRutaTransito.DoCreate;
begin
  inherited;
  Caption := SCaptionHojaRutaTransito;
  CrearSeleccionViaje;
  FDataset := TfrxDBDataset.Create(Self);
  FDataset.Name := 'fxdsRuta';
  FDataset.UserName := 'Ruta';
  CrearFormatoHojaRuta(frxReportOrigen, FDataset);
end;

procedure TfrmPrintHojaRutaTransito.CargarCargasViaje;
var
  Cargas: TUniQuery;
  Id: Int64;
  Item: TcxCheckListBoxItem;
begin
  Cargas := ConsultarHojaRutaTransito(nil, FConexion, FTransito);
  try
    while not Cargas.Eof do
    begin
      Id := Cargas.FieldByName('ID_CARGA').AsLargeInt;
      if (Length(FIdsCargas)=0) or
        (FIdsCargas[High(FIdsCargas)]<>Id) then
      begin
        FIdsCargas := FIdsCargas + [Id];
        Item := clbCargas.Items.Add;
        Item.Text := Cargas.FieldByName('DOCUMENTO').AsString + ' / ' +
          Cargas.FieldByName('ORIGEN').AsString + ' > ' +
          Cargas.FieldByName('DESTINO').AsString;
        Item.State := cbsChecked;
      end;
      Cargas.Next;
    end;
    edtViaje.Text := FTransito + ' / ' +
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  finally
    FreeAndNil(Cargas);
  end;
end;

function TfrmPrintHojaRutaTransito.CargasSeleccionadas: TArray<Int64>;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to clbCargas.Items.Count-1 do
    if clbCargas.Items[I].State = cbsChecked then
      Result := Result + [FIdsCargas[I]];
end;

procedure TfrmPrintHojaRutaTransito.AvisarAntesDeConsulta;
begin
  if (Trim(edtViaje.Text)='') or (Length(CargasSeleccionadas)=0) then
  begin
    ShowMessage_fza(SErrorSeleccionViajeHojaRuta);
    Abort;
  end;
  inherited;
end;

procedure TfrmPrintHojaRutaTransito.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CargarCargasViaje;
    FInicializado := True;
  end;
  btnImprimir.Enabled := FImprimir;
  btnVistaPreliminar.Enabled := FImprimir or FExportar;
  btnPDF.Enabled := FExportar;
  btnExcel.Enabled := FExportar;
end;

class procedure TfrmPrintHojaRutaTransito.Ejecutar(AOwner: TComponent;
  AConexion: TUniConnection; const ATransito: string;
  APuedeImprimir, APuedeExportar: Boolean);
var
  Formulario: TfrmPrintHojaRutaTransito;
begin
  if Trim(ATransito) = '' then
    ShowMessage_fza(SErrorHojaRutaSinTransito)
  else if APuedeImprimir or APuedeExportar then
  begin
    Formulario := TfrmPrintHojaRutaTransito.Create(AOwner);
    try
      Formulario.FConexion := AConexion;
      Formulario.FTransito := ATransito;
      Formulario.FImprimir := APuedeImprimir;
      Formulario.FExportar := APuedeExportar;
      Formulario.ShowModal;
    finally
      FreeAndNil(Formulario);
    end;
  end;
end;

procedure TfrmPrintHojaRutaTransito.preparar_consulta;
begin
  FreeAndNil(FDatos);
  FDatos := ConsultarHojaRutaTransito(Self, FConexion, FTransito,
    CargasSeleccionadas);
  FDataset.DataSet := FDatos;
  if FDatos.IsEmpty then
  begin
    ShowMessage_fza(SErrorHojaRutaSinCargas);
    Abort;
  end;
  FDataset.UpdateBounds;
  frxpdfxprtPedWeb.FileName := 'Hoja_ruta_' + FTransito;
end;

procedure TfrmPrintHojaRutaTransito.AfterReportLoaded;
begin
  inherited;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(FDataset);
  AsignarTextosHojaRuta(frxrprt1);
  frxrprt1.Variables['VIAJE'] := QuotedStr(Trim(edtViaje.Text));
end;

end.

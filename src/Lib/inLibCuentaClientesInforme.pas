{ Informe A4 de deudores y extracto de cuenta por depósito.
  FZ-ISSUE-726. Copyright (c) Alejandro Laorden Hidalgo. }
unit inLibCuentaClientesInforme;

interface

uses
  frxClass, frxDBSet;

procedure ConstruirInformeCuentaClientes(AInforme: TfrxReport;
  ADatos: TfrxDBDataset; AResumen: Boolean);

implementation

uses
  inLibMsgComun,
  System.SysUtils, Vcl.Graphics, Vcl.Printers, frBaseGraphicsTypes,
  inLibTraduccionesInforme;

procedure Texto(ABanda: TfrxBand; const ANombre, ATexto: string;
  AX, AAncho: Double; ANegrita: Boolean = False);
var
  Memo: TfrxMemoView;
begin
  Memo := TfrxMemoView.Create(ABanda);
  Memo.Name := ANombre;
  Memo.SetBounds(AX, 3, AAncho - 6, 24);
  Memo.Text := ATexto;
  Memo.Font.Name := 'Arial';
  Memo.Font.Size := 9;
  if ANegrita then
    Memo.Font.Style := [fsBold];
  Memo.WordWrap := True;
  Memo.StretchMode := smActualHeight;
  AjustarFuenteTextoInforme(Memo);
end;

procedure Columna(ACabecera: TfrxPageHeader; ADetalle: TfrxMasterData;
  const ACampo, ATitulo: string; AX, AAncho: Double;
  AImporte: Boolean = False);
var
  Memo: TfrxMemoView;
begin
  Texto(ACabecera, 'Titulo' + ACampo, ATitulo, AX, AAncho, True);
  Texto(ADetalle, 'Dato' + ACampo, '[Cuenta."' + ACampo + '"]',
    AX, AAncho);
  if AImporte then
  begin
    Memo := ADetalle.Report.FindObject('Dato' + ACampo) as TfrxMemoView;
    Memo.DisplayFormat.Kind := fkNumeric;
    Memo.DisplayFormat.FormatStr := '#,##0.00';
    Memo.HAlign := haRight;
  end;
end;

procedure ConstruirInformeCuentaClientes(AInforme: TfrxReport;
  ADatos: TfrxDBDataset; AResumen: Boolean);
var
  Pagina: TfrxReportPage;
  Titulo: TfrxReportTitle;
  Cabecera: TfrxPageHeader;
  Cliente: TfrxGroupHeader;
  Detalle: TfrxMasterData;
  TotalCliente: TfrxGroupFooter;
  Total: TfrxReportSummary;
  Pie: TfrxPageFooter;
  Nombre: string;
begin
  AInforme.Clear;
  AInforme.ScriptText.Text := 'begin end.';
  AInforme.DataSets.Add(ADatos);
  Pagina := TfrxReportPage.Create(AInforme);
  Pagina.Name := 'PaginaCuenta';
  Pagina.Orientation := poLandscape;
  Pagina.PaperWidth := 297;
  Pagina.PaperHeight := 210;
  Pagina.LeftMargin := 10;
  Pagina.RightMargin := 10;
  Pagina.TopMargin := 10;
  Pagina.BottomMargin := 10;
  Titulo := TfrxReportTitle.Create(Pagina);
  Titulo.Name := 'TituloCuenta';
  Titulo.Height := 50;
  if AResumen then
    Nombre := STextoDeudoresPorEmpresaYTiendaComun
  else
    Nombre := STextoExtractoDeCuentaDelClienteComun;
  Texto(Titulo, 'NombreInforme', Nombre, 0, 1047, True);
  Texto(Titulo, 'FechaInforme', Format(
    STextoSituacionActualADateImportesEnComun, ['[Date]']),
    0, 1047);
  (AInforme.FindObject('FechaInforme') as TfrxMemoView).Top := 28;
  Cabecera := TfrxPageHeader.Create(Pagina);
  Cabecera.Name := 'CabeceraCuenta';
  Cabecera.Top := 60;
  Cabecera.Height := 32;
  Cabecera.Stretched := True;
  Cliente := TfrxGroupHeader.Create(Pagina);
  Cliente.Name := 'ClienteCuenta';
  Cliente.Top := 100;
  Cliente.Height := 42;
  Cliente.Stretched := True;
  Cliente.Condition := 'Cuenta."CLIENTE"';
  Cliente.ReprintOnNewPage := True;
  Texto(Cliente, 'NombreCliente',
    '[Cuenta."CLIENTE"] · [Cuenta."NOMBRE"]', 0, 760, True);
  Texto(Cliente, 'LimiteCliente',
    Format(SLimiteGlobalCuenta,
      ['[IIF(<Cuenta."LIMITE"> = 0, ' +
       QuotedStr(SSinLimiteCuenta) + ', ' +
       'FormatFloat(''#,##0.00'', <Cuenta."LIMITE">))]']), 760, 287);
  Detalle := TfrxMasterData.Create(Pagina);
  Detalle.Name := 'DetalleCuenta';
  Detalle.Top := 150;
  Detalle.Height := 30;
  Detalle.Stretched := True;
  Detalle.DataSet := ADatos;
  if AResumen then
  begin
    Columna(Cabecera, Detalle, 'NOMBRE_EMPRESA', STextoEmpresaComun, 0, 270);
    Columna(Cabecera, Detalle, 'TIENDA', STextoTiendaComun, 270, 270);
    Columna(Cabecera, Detalle, 'FECHA', STextoPendienteDesdeComun, 540, 200);
    Columna(Cabecera, Detalle, 'DIAS', STextoAntiguedadDiasComun, 740, 150);
    Columna(Cabecera, Detalle, 'PENDIENTE', STextoPendienteComun, 890, 157,
      True);
  end
  else
  begin
    Columna(Cabecera, Detalle, 'FECHA', STextoFechaComun, 0, 80);
    Columna(Cabecera, Detalle, 'NOMBRE_EMPRESA', STextoEmpresaComun, 80, 155);
    Columna(Cabecera, Detalle, 'TIENDA', STextoTiendaComun, 235, 140);
    Columna(Cabecera, Detalle, 'DEPOSITO', STextoDepositoComun, 375, 210);
    Columna(Cabecera, Detalle, 'ESTADO', STextoEstadoComun, 585, 100);
    Columna(Cabecera, Detalle, 'IMPORTE', STextoImporteComun, 685, 120, True);
    Columna(Cabecera, Detalle, 'ENTREGADO', STextoEntregadoComun, 805, 120,
      True);
    Columna(Cabecera, Detalle, 'PENDIENTE', STextoPendienteComun, 925, 122,
      True);
  end;
  (AInforme.FindObject('DatoFECHA') as TfrxMemoView).DisplayFormat.Kind :=
    fkDateTime;
  (AInforme.FindObject('DatoFECHA') as TfrxMemoView).
    DisplayFormat.FormatStr := 'dd/mm/yyyy';
  TotalCliente := TfrxGroupFooter.Create(Pagina);
  TotalCliente.Name := 'TotalClienteCuenta';
  TotalCliente.Top := 190;
  TotalCliente.Height := 30;
  Texto(TotalCliente, 'TotalPorCliente',
    Format(STotalPendienteClienteCuenta,
      ['[FormatFloat(''#,##0.00'', SUM(<Cuenta."PENDIENTE">, ' +
       'DetalleCuenta))] €']), 600, 447, True);
  Total := TfrxReportSummary.Create(Pagina);
  Total.Name := 'TotalCuenta';
  Total.Top := 230;
  Total.Height := 36;
  Texto(Total, 'TotalGeneral',
    Format(STotalPendienteCuenta,
      ['[FormatFloat(''#,##0.00'', ' +
       'SUM(<Cuenta."PENDIENTE">, DetalleCuenta))] €']), 600, 447, True);
  Pie := TfrxPageFooter.Create(Pagina);
  Pie.Name := 'PieCuenta';
  Pie.Top := 280;
  Pie.Height := 24;
  Texto(Pie, 'Pagina', Format(STextoPaginaPageDeTotalpagesComun,
      ['[Page#]', '[TotalPages#]']), 800, 247);
end;

end.

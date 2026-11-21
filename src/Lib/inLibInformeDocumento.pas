{******************************************************************************}
{                                                                              }
{                        Módulo: inLibInformeDocumento                         }
{                                Versión: 1.1.0                                }
{                              Fecha: 22/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibInformeDocumento;

interface

uses
  frxClass, frxDBSet;

// Informe base de presupuestos, pedidos y albaranes, con la misma
// estructura que la factura: cajas de emisor y tercero, lineas, desglose
// de IVA junto a los totales, forma de pago y observaciones.
// AEtiquetaTercero rotula la caja del cliente o del proveedor.
procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas, AImpuestos: TfrxDBDataset;
  const ATitulo, AEtiquetaTercero: string;
  AMostrarDescuento: Boolean = False;
  APedidoCompra: Boolean = False; AHorizontal: Boolean = False);

// Aplica el formato español también a plantillas de factura guardadas.
procedure AjustarFormatoBasesFactura(AInforme: TfrxReport);
procedure AjustarRotulosReciboFactura(AInforme: TfrxReport);

implementation

uses
  inLibMsgPresupuestos, inLibMsgFacturas, inLibPivoteVentaCalculo,
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Printers,
  frBaseGraphicsTypes;

procedure AjustarFormatoBasesFactura(AInforme: TfrxReport);
const
  NOMBRES_BASES: array[0..3] of string = (
    'BaseImponibleN', 'BaseImponibleR', 'BaseImponibleS', 'BaseImponibleE');
  NOMBRES_SOBRANTES: array[0..3] of string = (
    'Memo19', 'Memo21', 'Memo23', 'Memo25');
var
  Nombre: string;
  Componente: TfrxComponent;
  Memo: TfrxMemoView;
begin
  if AInforme <> nil then
    for Nombre in NOMBRES_BASES do
    begin
      Componente := AInforme.FindObject(Nombre);
      if Componente is TfrxMemoView then
      begin
        Memo := TfrxMemoView(Componente);
        Memo.DisplayFormat.Kind := fkNumeric;
        Memo.DisplayFormat.FormatStr := '%2.2m';
        Memo.DisplayFormat.DecimalSeparator := ',';
        Memo.DisplayFormat.ThousandSeparator := '.';
      end;
    end;
  // FZ-182: las plantillas antiguas conservan importes duplicados fuera
  // del papel. Solo se omiten los memos sueltos de pagina, no los totales
  // de sus bandas ni los objetos que el usuario haya colocado dentro.
  if AInforme <> nil then
    for Nombre in NOMBRES_SOBRANTES do
    begin
      Componente := AInforme.FindObject(Nombre);
      if (Componente is TfrxMemoView) and
         (Componente.Parent is TfrxReportPage) then
      begin
        Memo := TfrxMemoView(Componente);
        if Memo.Left >=
           TfrxReportPage(Memo.Parent).PaperWidth * 3.77953 then
        begin
          Memo.OnBeforePrint := '';
          Memo.Visible := False;
        end;
      end;
    end;
end;

procedure AjustarRotulosReciboFactura(AInforme: TfrxReport);
const
  NOMBRES: array[0..2] of string = ('Memo6', 'Memo13', 'Memo19');
  ANCHOS: array[0..2] of Integer = (300, 330, 370);
var
  I: Integer;
  Componente: TfrxComponent;
begin
  if AInforme <> nil then
    for I := Low(NOMBRES) to High(NOMBRES) do
    begin
      Componente := AInforme.FindObject(NOMBRES[I]);
      if (Componente is TfrxMemoView) and
         (TfrxMemoView(Componente).Width < ANCHOS[I]) then
        TfrxMemoView(Componente).Width := ANCHOS[I];
    end;
  if AInforme <> nil then
    for I := 0 to AInforme.AllObjects.Count - 1 do
    begin
      Componente := AInforme.AllObjects[I];
      // FZ-ISSUE-856: normaliza tambien las plantillas guardadas.
      if (Componente is TfrxMemoView) and
         (Pos('DOCUMENTO_FACTURA_FORMATO',
           string(TfrxMemoView(Componente).Text)) > 0) and
         (Pos('NUMERO_PLAZO_REC',
           string(TfrxMemoView(Componente).Text)) > 0) then
      begin
        TfrxMemoView(Componente).Text := StringReplace(
          TfrxMemoView(Componente).Text, ']\[', ']/[', [rfReplaceAll]);
        TfrxMemoView(Componente).WordWrap := False;
        if Componente.Name = 'Memo2' then
        begin
          TfrxMemoView(Componente).Font.Height := -11;
          if AInforme.FindObject('Memo1') is TfrxView then
          begin
            TfrxMemoView(Componente).Left :=
              TfrxView(AInforme.FindObject('Memo1')).Left + 2;
            TfrxMemoView(Componente).Width :=
              TfrxView(AInforme.FindObject('Memo1')).Width - 4;
          end;
        end;
      end;
      if (Componente is TfrxMemoView) and
         (Pos('<IBAN>', string(TfrxMemoView(Componente).Text)) > 0) then
        TfrxMemoView(Componente).Text :=
          '[IIF(<Recibos."IBAN_CLI_REC"> <> '''', ' +
          '''PAGADERO EN:'', '''')]';
    end;
end;

const
  PIXELES_POR_MM = 3.77953;
  COLOR_FONDO = $00EAEAEA;
  COLOR_LINEA = $00C8C8C8;
  COLOR_TENUE = $00666666;
  ANCHO_CAJA = 350;
  ALTO_FILA = 18;
  ANCHO_CODIGO = 135;
  FORMATO_IMPORTE = '#,##0.00';
  SCRIPT_INFORME =
    'procedure NotasOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Cabecera."NOTAS"> <> '''';'#13#10 +
    'end;'#13#10 +
    'procedure FormaPagoOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible :='#13#10 +
    '    <Cabecera."FORMA_PAGO_DESCRIPCION"> <> '''';'#13#10 +
    'end;'#13#10 +
    'procedure RetencionOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Cabecera."RETENCION"> <> 0;'#13#10 +
    'end;'#13#10 +
    'procedure RecargoCabecera(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Cabecera."TIENE_RECARGO"> <> 0;'#13#10 +
    'end;'#13#10 +
    'procedure RecargoLinea(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Impuestos."CUOTA_RE"> <> 0;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.';

type
  TInformeDocumento = class
  private
    FInforme: TfrxReport;
    FCabecera: TfrxDBDataset;
    FLineas: TfrxDBDataset;
    FImpuestos: TfrxDBDataset;
    FTitulo: string;
    FEtiquetaTercero: string;
    FAncho: Extended;
    FMostrarDescuento: Boolean;
    FPedidoCompra: Boolean;
    FHorizontal: Boolean;
    function Memo(AParent: TfrxComponent; const ATexto: string;
      ALeft, ATop, AWidth, AHeight: Extended): TfrxMemoView;
    function Importe(const ACampo: string): string;
    procedure Caja(AParent: TfrxComponent; ALeft, ATop, AWidth,
      AHeight: Extended);
    function CeldaTitulo(AParent: TfrxComponent; const ATexto: string;
      ALeft, AWidth: Extended; AAlineacion: TfrxHAlign): TfrxMemoView;
    function CeldaLinea(AParent: TfrxComponent; const ATexto: string;
      ALeft, AWidth: Extended; AAlineacion: TfrxHAlign): TfrxMemoView;
    procedure CrearSujeto(ABanda: TfrxBand; const AEtiqueta, ANombre,
      ABloque: string; ALeft, ATop: Extended);
    procedure CrearCabecera(APagina: TfrxReportPage);
    procedure CrearDetalle(APagina: TfrxReportPage);
    procedure CrearDetallePedidoCompra(APagina: TfrxReportPage);
    procedure CrearDetallePedidoCompraHorizontal(APagina: TfrxReportPage);
    procedure CrearDesgloseIva(AResumen: TfrxBand);
    procedure CrearFilaTotal(AResumen: TfrxBand; const AEtiqueta,
      AValor: string; ATop: Extended; const AAlVisualizar: string);
    procedure CrearTotales(APagina: TfrxReportPage);
    procedure CrearPie(APagina: TfrxReportPage);
    procedure CrearInforme;
  end;

function TInformeDocumento.Memo(AParent: TfrxComponent;
  const ATexto: string; ALeft, ATop, AWidth,
  AHeight: Extended): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(AParent);
  Result.CreateUniqueName;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
  Result.Font.Name := 'Arial';
  Result.Font.Size := 9;
  Result.Font.Color := clBlack;
  Result.WordWrap := False;
  Result.VAlign := vaCenter;
  Result.Text := ATexto;
end;

function TInformeDocumento.Importe(const ACampo: string): string;
begin
  Result := '[FormatFloat(''' + FORMATO_IMPORTE + ''', <' + ACampo +
    '>)]';
end;

procedure TInformeDocumento.Caja(AParent: TfrxComponent; ALeft, ATop,
  AWidth, AHeight: Extended);
var
  oCaja: TfrxMemoView;
begin
  oCaja := Memo(AParent, '', ALeft, ATop, AWidth, AHeight);
  oCaja.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oCaja.Frame.Color := COLOR_LINEA;
end;

function TInformeDocumento.CeldaTitulo(AParent: TfrxComponent;
  const ATexto: string; ALeft, AWidth: Extended;
  AAlineacion: TfrxHAlign): TfrxMemoView;
var
  oCelda: TfrxMemoView;
begin
  oCelda := Memo(AParent, ATexto, ALeft, 0, AWidth, 22);
  oCelda.Font.Style := [fsBold];
  oCelda.Color := COLOR_FONDO;
  oCelda.Frame.Typ := [ftTop, ftBottom];
  oCelda.Frame.Color := COLOR_LINEA;
  oCelda.GapX := 5;
  oCelda.HAlign := AAlineacion;
  Result := oCelda;
end;

function TInformeDocumento.CeldaLinea(AParent: TfrxComponent;
  const ATexto: string; ALeft, AWidth: Extended;
  AAlineacion: TfrxHAlign): TfrxMemoView;
var
  oCelda: TfrxMemoView;
begin
  oCelda := Memo(AParent, ATexto, ALeft, 0, AWidth, ALTO_FILA + 4);
  oCelda.WordWrap := AAlineacion = haLeft;
  oCelda.StretchMode := smMaxHeight;
  oCelda.VAlign := vaTop;
  oCelda.GapX := 5;
  oCelda.GapY := 4;
  oCelda.Frame.Typ := [ftBottom];
  oCelda.Frame.Color := COLOR_LINEA;
  oCelda.HAlign := AAlineacion;
  Result := oCelda;
end;

procedure TInformeDocumento.CrearSujeto(ABanda: TfrxBand;
  const AEtiqueta, ANombre, ABloque: string; ALeft, ATop: Extended);
var
  oTexto: TfrxMemoView;
begin
  oTexto := Memo(ABanda, AEtiqueta, ALeft, ATop, ANCHO_CAJA, 18);
  oTexto.Font.Style := [fsBold];
  oTexto.Font.Color := COLOR_TENUE;
  Caja(ABanda, ALeft, ATop + 20, ANCHO_CAJA, 118);
  oTexto := Memo(ABanda, ANombre, ALeft + 10, ATop + 26, ANCHO_CAJA - 20,
    20);
  oTexto.Font.Size := 10;
  oTexto.Font.Style := [fsBold];
  oTexto := Memo(ABanda, ABloque, ALeft + 10, ATop + 48, ANCHO_CAJA - 20,
    86);
  oTexto.WordWrap := True;
  oTexto.VAlign := vaTop;
end;

procedure TInformeDocumento.CrearCabecera(APagina: TfrxReportPage);
var
  oBanda: TfrxReportTitle;
  oTexto: TfrxMemoView;
  nTopNumero, nTopSujeto: Extended;
begin
  oBanda := TfrxReportTitle.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.Height := 252;
  nTopNumero := 44;
  nTopSujeto := 100;
  if FHorizontal then
  begin
    oBanda.Height := 186;
    nTopNumero := 0;
    nTopSujeto := 40;
  end;
  oTexto := Memo(oBanda, FTitulo.ToUpper, 0, 0, FAncho, 30);
  oTexto.Font.Size := 16;
  oTexto.Font.Style := [fsBold, fsUnderline];
  oTexto.HAlign := haCenter;
  oTexto := Memo(oBanda, SInformeNumeroDocumento, 0, nTopNumero,
    ANCHO_CAJA, 18);
  oTexto.Font.Size := 10;
  oTexto.Font.Style := [fsBold];
  Memo(oBanda, SInformeFechaDocumento, 0, nTopNumero + 18,
    ANCHO_CAJA, 18).Font.Size :=
    10;
  if not FHorizontal then
    Memo(oBanda, '[Cabecera."VALIDEZ"]', 0, 80,
      ANCHO_CAJA, 18).Font.Size := 10;
  CrearSujeto(oBanda, SInformeEmisorDocumento, '[Cabecera."EMPRESA"]',
    '[Cabecera."BLOQUE_EMPRESA"]', 0, nTopSujeto);
  CrearSujeto(oBanda, FEtiquetaTercero, '[Cabecera."TERCERO"]',
    '[Cabecera."BLOQUE_TERCERO"]', FAncho - ANCHO_CAJA, nTopSujeto);
end;

procedure TInformeDocumento.CrearDetalle(APagina: TfrxReportPage);
var
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
  Columnas: array[0..7] of Extended;
  CampoPrecio: string;
begin
  // Bordes: codigo, descripcion, cantidad, precio, descuento, IVA,
  // importe y final de la tabla. El codigo admite 15 caracteres en
  // mayusculas (COMPLEMENTOS003) sin partirse (FZ-ISSUE-102.5).
  Columnas[0] := 0;
  Columnas[1] := ANCHO_CODIGO;
  Columnas[2] := FAncho - 322;
  Columnas[3] := FAncho - 247;
  Columnas[5] := FAncho - 167;
  Columnas[4] := Columnas[5];
  if FMostrarDescuento then
  begin
    Columnas[2] := Columnas[2] - 50;
    Columnas[3] := Columnas[3] - 50;
    Columnas[4] := Columnas[4] - 50;
  end;
  Columnas[6] := FAncho - 112;
  Columnas[7] := FAncho;
  oCabecera := TfrxHeader.Create(APagina);
  oCabecera.CreateUniqueName;
  oCabecera.Top := 270;
  oCabecera.Height := 26;
  oCabecera.ReprintOnNewPage := True;
  CeldaTitulo(oCabecera, SInformeCodigoDocumento, Columnas[0],
    Columnas[1] - Columnas[0], haLeft);
  CeldaTitulo(oCabecera, SInformeDescripcionDocumento, Columnas[1],
    Columnas[2] - Columnas[1], haLeft);
  CeldaTitulo(oCabecera, SInformeCantidadDocumento, Columnas[2],
    Columnas[3] - Columnas[2], haRight);
  CeldaTitulo(oCabecera, SInformePrecioDocumento, Columnas[3],
    Columnas[4] - Columnas[3], haRight);
  if FMostrarDescuento then
    CeldaTitulo(oCabecera, SCaptionDescuentoLineaPresupuesto,
      Columnas[4], Columnas[5] - Columnas[4], haRight);
  CeldaTitulo(oCabecera, SInformeIvaDocumento, Columnas[5],
    Columnas[6] - Columnas[5], haRight);
  CeldaTitulo(oCabecera, SInformeImporteDocumento, Columnas[6],
    Columnas[7] - Columnas[6], haRight);
  oDetalle := TfrxMasterData.Create(APagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 310;
  oDetalle.DataSet := FLineas;
  oDetalle.Height := ALTO_FILA + 4;
  oDetalle.Stretched := True;
  // Una linea no se parte entre paginas.
  oDetalle.AllowSplit := False;
  CeldaLinea(oDetalle, '[Lineas."ARTICULO"]', Columnas[0],
    Columnas[1] - Columnas[0], haLeft);
  CeldaLinea(oDetalle, '[Lineas."DETALLE"]', Columnas[1],
    Columnas[2] - Columnas[1], haLeft);
  CeldaLinea(oDetalle,
    '[FormatFloat(''#,##0.##'', <Lineas."CANTIDAD">)] [Lineas."UNIDAD"]',
    Columnas[2], Columnas[3] - Columnas[2], haRight);
  CampoPrecio := 'Lineas."PRECIO"';
  if FMostrarDescuento then
    CampoPrecio := 'Lineas."PRECIO_ANTES_DTO"';
  CeldaLinea(oDetalle, Importe(CampoPrecio), Columnas[3],
    Columnas[4] - Columnas[3], haRight);
  if FMostrarDescuento then
    CeldaLinea(oDetalle,
      '[FormatFloat(''0.##'', <Lineas."PORCENTAJE_DTO">)]',
      Columnas[4], Columnas[5] - Columnas[4], haRight);
  CeldaLinea(oDetalle, '[FormatFloat(''0.##'', <Lineas."IVA">)]',
    Columnas[5], Columnas[6] - Columnas[5], haRight);
  CeldaLinea(oDetalle, Importe('Lineas."TOTAL"'), Columnas[6],
    Columnas[7] - Columnas[6], haRight);
end;

// Una cabecera por modelo; las tallas y los SKU se imprimen debajo.
procedure TInformeDocumento.CrearDetallePedidoCompra(
  APagina: TfrxReportPage);
const
  ROTULOS: array[0..5] of string =
    ('Modelo', 'SKU', 'Descripción', 'Precio', 'Cantidad', 'Total');
var
  oGrupo: TfrxGroupHeader;
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
  oFoto: TfrxPictureView;
  oTexto: TfrxMemoView;
  Bordes: array[0..6] of Extended;
  Textos: array[0..5] of string;
  iColumna: Integer;
  eAlineacion: TfrxHAlign;
begin
  Bordes[0] := 0;
  Bordes[1] := 78;
  Bordes[2] := 308;
  Bordes[3] := FAncho - 222;
  Bordes[4] := FAncho - 148;
  Bordes[5] := FAncho - 74;
  Bordes[6] := FAncho;
  oGrupo := TfrxGroupHeader.Create(APagina);
  oGrupo.Name := 'CabeceraModeloCompra';
  oGrupo.Top := 270;
  oGrupo.Height := 88;
  oGrupo.Condition := 'Lineas."MODELO"';
  oGrupo.ReprintOnNewPage := False;
  oGrupo.KeepChild := True;
  oFoto := TfrxPictureView.Create(oGrupo);
  oFoto.Name := 'foto300';
  oFoto.SetBounds(0, 4, 96, 78);
  oFoto.DataSet := FLineas;
  oFoto.Stretched := True;
  oFoto.KeepAspectRatio := True;
  oTexto := Memo(oGrupo, 'Modelo [Lineas."MODELO"]',
    108, 8, FAncho - 108, 24);
  oTexto.Font.Size := 11;
  oTexto.Font.Style := [fsBold];
  Memo(oGrupo, '[Lineas."DESCRIPCION"]',
    108, 34, FAncho - 108, 44).WordWrap := True;
  oCabecera := TfrxHeader.Create(APagina);
  oCabecera.CreateUniqueName;
  oCabecera.Top := 370;
  oCabecera.Height := 24;
  oCabecera.ReprintOnNewPage := True;
  oDetalle := TfrxMasterData.Create(APagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 400;
  oDetalle.DataSet := FLineas;
  oDetalle.Height := ALTO_FILA + 4;
  oDetalle.Stretched := True;
  oDetalle.AllowSplit := False;
  Textos[0] := '[Lineas."MODELO"]';
  Textos[1] := '[Lineas."SKU"]';
  Textos[2] := '[Lineas."DETALLE"]';
  Textos[3] := Importe('Lineas."PRECIO"');
  Textos[4] :=
    '[FormatFloat(''#,##0.##'', <Lineas."CANTIDAD">)]';
  Textos[5] := Importe('Lineas."TOTAL"');
  for iColumna := 0 to High(ROTULOS) do
  begin
    eAlineacion := haLeft;
    if iColumna >= 3 then
      eAlineacion := haRight;
    CeldaTitulo(oCabecera, ROTULOS[iColumna],
      Bordes[iColumna], Bordes[iColumna + 1] - Bordes[iColumna],
      eAlineacion);
    oTexto := CeldaLinea(oDetalle, Textos[iColumna],
      Bordes[iColumna], Bordes[iColumna + 1] - Bordes[iColumna],
      eAlineacion);
    if iColumna = 1 then
      oTexto.Font.Size := 8;
  end;
end;

procedure TInformeDocumento.CrearDetallePedidoCompraHorizontal(
  APagina: TfrxReportPage);
const
  ANCHO_VARIANTE = 160;
  ANCHO_PRECIO = 80;
  ANCHO_UNIDADES = 72;
  ANCHO_TOTAL = 86;
  ALTO_TRAMO = 38;
  FORMATO_CANTIDAD = '#,##0.######';
var
  oGrupo: TfrxGroupHeader;
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
  oFoto: TfrxPictureView;
  oTexto: TfrxMemoView;
  nPrecio, nCantidad, nTotal, nAnchoTalla, X: Extended;
  I: Integer;
  sColumna: string;
begin
  nTotal := FAncho - ANCHO_TOTAL;
  nCantidad := nTotal - ANCHO_UNIDADES;
  nPrecio := nCantidad - ANCHO_PRECIO;
  nAnchoTalla := (nPrecio - ANCHO_VARIANTE) / MAX_TALLAS_HORIZONTAL;
  oGrupo := TfrxGroupHeader.Create(APagina);
  oGrupo.Name := 'CabeceraModeloCompra';
  oGrupo.Top := 270;
  oGrupo.Height := 72;
  oGrupo.Condition := 'LineasHorizontales."GRUPO_MODELO"';
  oGrupo.ReprintOnNewPage := True;
  oGrupo.KeepChild := True;
  oFoto := TfrxPictureView.Create(oGrupo);
  oFoto.Name := 'foto300';
  oFoto.SetBounds(0, 4, 92, 62);
  oFoto.DataSet := FLineas;
  oFoto.Stretched := True;
  oFoto.KeepAspectRatio := True;
  oTexto := Memo(oGrupo, 'Modelo [LineasHorizontales."MODELO"]',
    104, 4, FAncho - 104, 24);
  oTexto.Font.Size := 11;
  oTexto.Font.Style := [fsBold];
  Memo(oGrupo, '[LineasHorizontales."DESCRIPCION_BASE"]',
    104, 27, FAncho - 104, 36).WordWrap := True;
  oCabecera := TfrxHeader.Create(APagina);
  oCabecera.CreateUniqueName;
  oCabecera.Top := 370;
  oCabecera.Height := 24;
  oCabecera.ReprintOnNewPage := True;
  CeldaTitulo(oCabecera, STextoSkuFacturas, 0, ANCHO_VARIANTE, haLeft);
  CeldaTitulo(oCabecera, STextoTallasFacturas, ANCHO_VARIANTE,
    nPrecio - ANCHO_VARIANTE, haCenter);
  CeldaTitulo(oCabecera, SInformePrecioDocumento, nPrecio,
    ANCHO_PRECIO, haRight);
  CeldaTitulo(oCabecera, SInformeCantidadDocumento, nCantidad,
    ANCHO_UNIDADES, haRight);
  CeldaTitulo(oCabecera, SInformeImporteDocumento, nTotal,
    ANCHO_TOTAL, haRight);
  oDetalle := TfrxMasterData.Create(APagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 400;
  oDetalle.DataSet := FLineas;
  oDetalle.Height := ALTO_TRAMO;
  oDetalle.Stretched := True;
  oDetalle.AllowSplit := False;
  CeldaLinea(oDetalle, '', 0, FAncho, haLeft).Height := ALTO_TRAMO;
  oTexto := Memo(oDetalle, '[LineasHorizontales."VARIANTE"]', 4, 1,
    ANCHO_VARIANTE - 8, 17);
  oTexto.Font.Size := 8;
  Memo(oDetalle, '[LineasHorizontales."COLOR_TEXTO"]', 4, 18,
    ANCHO_VARIANTE - 8, 17).Font.Size := 8;
  oTexto := Memo(oDetalle, '[LineasHorizontales."DETALLE"]',
    ANCHO_VARIANTE, 0, nPrecio - ANCHO_VARIANTE, ALTO_TRAMO - 2);
  oTexto.WordWrap := True;
  oTexto.StretchMode := smActualHeight;
  for I := 1 to MAX_TALLAS_HORIZONTAL do
  begin
    X := ANCHO_VARIANTE + (I - 1) * nAnchoTalla;
    oTexto := Memo(oDetalle, Format('[LineasHorizontales."R%.2d"]', [I]),
      X, 1, nAnchoTalla, 17);
    oTexto.Font.Size := 8;
    oTexto.Font.Style := [fsBold];
    oTexto.Font.Color := COLOR_TENUE;
    oTexto.HAlign := haCenter;
    oTexto.GapX := 1;
    sColumna := Format('<LineasHorizontales."T%.2d">', [I]);
    oTexto := Memo(oDetalle, '[IIF(' + sColumna + ' = 0, '''', ' +
      'FormatFloat(''' + FORMATO_CANTIDAD + ''', ' + sColumna + '))]',
      X, 18, nAnchoTalla, 17);
    oTexto.Font.Size := 8;
    oTexto.HAlign := haCenter;
    oTexto.GapX := 1;
  end;
  Memo(oDetalle, '[FormatFloat(''#,##0.00####'', ' +
    '<LineasHorizontales."PRECIO_COMPRA">)]', nPrecio, 18,
    ANCHO_PRECIO, 17).HAlign := haRight;
  Memo(oDetalle, '[FormatFloat(''' + FORMATO_CANTIDAD +
    ''', <LineasHorizontales."TOTAL_UNIDADES">)]', nCantidad, 18,
    ANCHO_UNIDADES, 17).HAlign := haRight;
  Memo(oDetalle, Importe('LineasHorizontales."TOTAL_LINEA"'),
    nTotal, 18, ANCHO_TOTAL, 17).HAlign := haRight;
end;

// Desglose guardado por tipo; las dos columnas de R.E. son condicionales.
procedure TInformeDocumento.CrearDesgloseIva(AResumen: TfrxBand);
var
  oSubinforme: TfrxSubreport;
  oPagina: TfrxReportPage;
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
begin
  oPagina := TfrxReportPage.Create(FInforme);
  oPagina.CreateUniqueName;
  oSubinforme := TfrxSubreport.Create(AResumen);
  oSubinforme.CreateUniqueName;
  oSubinforme.SetBounds(0, 12, 426, 104);
  oSubinforme.Page := oPagina;
  oCabecera := TfrxHeader.Create(oPagina);
  oCabecera.CreateUniqueName;
  oCabecera.Height := 22;
  CeldaTitulo(oCabecera, SInformeTipoIvaDocumento, 0, 92, haLeft);
  CeldaTitulo(oCabecera, SInformeBaseDesgloseDocumento, 92, 82, haRight);
  CeldaTitulo(oCabecera, SInformePorcentajeIvaDocumento, 174, 45, haRight);
  CeldaTitulo(oCabecera, SInformeCuotaIvaDocumento, 219, 75, haRight);
  CeldaTitulo(oCabecera, SInformePorcentajeRecargoDocumento, 294, 50,
    haRight).OnBeforePrint := 'RecargoCabecera';
  CeldaTitulo(oCabecera, SInformeCuotaRecargoDocumento, 344, 82,
    haRight).OnBeforePrint := 'RecargoCabecera';
  oDetalle := TfrxMasterData.Create(oPagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 30;
  oDetalle.Height := ALTO_FILA + 4;
  oDetalle.DataSet := FImpuestos;
  CeldaLinea(oDetalle, '[Impuestos."NOMBRE"]', 0, 92, haLeft);
  CeldaLinea(oDetalle, Importe('Impuestos."BASE"'), 92, 82, haRight);
  CeldaLinea(oDetalle, '[FormatFloat(''0.##'', <Impuestos."PORCENTAJE">)]',
    174, 45, haRight);
  CeldaLinea(oDetalle, Importe('Impuestos."CUOTA"'), 219, 75, haRight);
  CeldaLinea(oDetalle,
    '[FormatFloat(''0.##'', <Impuestos."PORCENTAJE_RE">)]', 294, 50,
    haRight).OnBeforePrint := 'RecargoLinea';
  CeldaLinea(oDetalle, Importe('Impuestos."CUOTA_RE"'), 344, 82,
    haRight).OnBeforePrint := 'RecargoLinea';
end;

procedure TInformeDocumento.CrearFilaTotal(AResumen: TfrxBand;
  const AEtiqueta, AValor: string; ATop: Extended;
  const AAlVisualizar: string);
var
  oEtiqueta, oValor: TfrxMemoView;
begin
  oEtiqueta := Memo(AResumen, AEtiqueta, FAncho - 280, ATop, 160, 20);
  oEtiqueta.GapX := 5;
  oValor := Memo(AResumen, AValor + ' €', FAncho - 120, ATop, 120, 20);
  oValor.HAlign := haRight;
  oValor.GapX := 5;
  oEtiqueta.Frame.Typ := [ftBottom];
  oEtiqueta.Frame.Color := COLOR_LINEA;
  oValor.Frame.Typ := [ftBottom];
  oValor.Frame.Color := COLOR_LINEA;
  oEtiqueta.OnBeforePrint := AAlVisualizar;
  oValor.OnBeforePrint := AAlVisualizar;
end;

procedure TInformeDocumento.CrearTotales(APagina: TfrxReportPage);
var
  oResumen: TfrxReportSummary;
  oTotal: TfrxMemoView;
  oTexto: TfrxMemoView;
  EventoRetencion: string;
begin
  oResumen := TfrxReportSummary.Create(APagina);
  oResumen.CreateUniqueName;
  oResumen.Top := 350;
  oResumen.Height := 220;
  oResumen.Stretched := True;
  CrearDesgloseIva(oResumen);
  CrearFilaTotal(oResumen, SInformeBaseImponibleDocumento,
    Importe('Cabecera."BASES"'), 12, '');
  CrearFilaTotal(oResumen, SInformeTotalIvaDocumento,
    Importe('Cabecera."TOTAL_IVA"'), 32, '');
  CrearFilaTotal(oResumen, SInformeTotalRecargoDocumento,
    Importe('Cabecera."RECARGO"'), 52, 'RecargoCabecera');
  EventoRetencion := 'RetencionOnBeforePrint';
  if FMostrarDescuento then
    EventoRetencion := '';
  CrearFilaTotal(oResumen, SInformeRetencionIrpfDocumento,
    '-' + Importe('Cabecera."RETENCION"'), 72, EventoRetencion);
  oTotal := Memo(oResumen, SInformeTotalLiquidoDocumento, FAncho - 280, 100,
    280, 28);
  oTotal.Font.Size := 11;
  oTotal.Font.Style := [fsBold];
  oTotal.Color := COLOR_FONDO;
  oTotal.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oTotal.Frame.Width := 1.5;
  oTotal.GapX := 8;
  oTotal := Memo(oResumen, Importe('Cabecera."TOTAL"') + ' €',
    FAncho - 160, 100, 160, 28);
  oTotal.Font.Size := 11;
  oTotal.Font.Style := [fsBold];
  oTotal.HAlign := haRight;
  oTotal.GapX := 8;
  oTexto := Memo(oResumen, SInformeFormaPagoDescDocumento, 0, 146, FAncho,
    20);
  oTexto.OnBeforePrint := 'FormaPagoOnBeforePrint';
  oTexto := Memo(oResumen, SInformeObservacionesDocumento, 0, 172,
    FAncho, 20);
  oTexto.Font.Style := [fsBold];
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.OnBeforePrint := 'NotasOnBeforePrint';
  oTexto := Memo(oResumen, '[Cabecera."NOTAS"]', 0, 192, FAncho, 24);
  oTexto.WordWrap := True;
  oTexto.VAlign := vaTop;
  oTexto.GapX := 8;
  oTexto.GapY := 5;
  oTexto.StretchMode := smActualHeight;
  oTexto.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oTexto.Frame.Color := COLOR_LINEA;
  oTexto.OnBeforePrint := 'NotasOnBeforePrint';
end;

procedure TInformeDocumento.CrearPie(APagina: TfrxReportPage);
var
  oPie: TfrxPageFooter;
  oTexto: TfrxMemoView;
begin
  oPie := TfrxPageFooter.Create(APagina);
  oPie.CreateUniqueName;
  oPie.Top := 700;
  oPie.Height := 24;
  oTexto := Memo(oPie, '[Cabecera."EMPRESA"] · ' + SInformeNifDocumento +
    '[Cabecera."NIF_EMPRESA"]', 0, 4, FAncho - 150, 18);
  oTexto.Font.Size := 8;
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.Frame.Typ := [ftTop];
  oTexto.Frame.Color := COLOR_LINEA;
  oTexto := Memo(oPie, SInformePaginaDocumento, FAncho - 150, 4, 150, 18);
  oTexto.Font.Size := 8;
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.HAlign := haRight;
  oTexto.Frame.Typ := [ftTop];
  oTexto.Frame.Color := COLOR_LINEA;
end;

procedure TInformeDocumento.CrearInforme;
var
  oPagina: TfrxReportPage;
begin
  FInforme.Clear;
  FInforme.DataSets.Add(FCabecera);
  FInforme.DataSets.Add(FLineas);
  FInforme.DataSets.Add(FImpuestos);
  FInforme.EngineOptions.DoublePass := True;
  FInforme.ScriptLanguage := 'PascalScript';
  FInforme.ScriptText.Text := SCRIPT_INFORME;
  oPagina := TfrxReportPage.Create(FInforme);
  oPagina.CreateUniqueName;
  oPagina.SetDefaults;
  if FHorizontal then
  begin
    oPagina.Orientation := poLandscape;
    oPagina.PaperWidth := 297;
    oPagina.PaperHeight := 210;
  end;
  oPagina.LeftMargin := 10;
  oPagina.RightMargin := 10;
  oPagina.TopMargin := 10;
  oPagina.BottomMargin := 10;
  FAncho := (oPagina.PaperWidth - oPagina.LeftMargin -
    oPagina.RightMargin) * PIXELES_POR_MM;
  CrearCabecera(oPagina);
  if FHorizontal then
    CrearDetallePedidoCompraHorizontal(oPagina)
  else if FPedidoCompra then
    CrearDetallePedidoCompra(oPagina)
  else
    CrearDetalle(oPagina);
  CrearTotales(oPagina);
  CrearPie(oPagina);
end;

procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas, AImpuestos: TfrxDBDataset;
  const ATitulo, AEtiquetaTercero: string;
  AMostrarDescuento, APedidoCompra, AHorizontal: Boolean);
var
  oConstructor: TInformeDocumento;
begin
  oConstructor := TInformeDocumento.Create;
  try
    oConstructor.FInforme := AInforme;
    oConstructor.FCabecera := ACabecera;
    oConstructor.FLineas := ALineas;
    oConstructor.FImpuestos := AImpuestos;
    oConstructor.FMostrarDescuento := AMostrarDescuento;
    oConstructor.FPedidoCompra := APedidoCompra;
    oConstructor.FHorizontal := AHorizontal;
    oConstructor.FTitulo := ATitulo;
    oConstructor.FEtiquetaTercero := AEtiquetaTercero;
    oConstructor.CrearInforme;
  finally
    FreeAndNil(oConstructor);
  end;
end;

end.

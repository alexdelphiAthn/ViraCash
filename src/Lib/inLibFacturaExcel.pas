{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturaExcel                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exporta una factura a hoja dxSpreadSheet de DevExpress.                   }
{    Maqueta cabecera, líneas y desglose de impuestos sobre la plantilla.      }
{******************************************************************************}
unit inLibFacturaExcel;

interface

uses
  Uni, DB, dxSpreadSheet, inLibParametrosIntf, inLibLogIntf;

procedure ExportarFacturaADevExpress(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet; const QMaster, QLineas: TDataSet);


implementation

uses
  System.SysUtils, System.Classes, Vcl.Graphics, cxGraphics,
  inLibMsgFacturas,
  dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetGraphics,
  dxCoreGraphics, dxShellDialogs, dxSpreadSheetStyles,
  dxSpreadSheetContainers, dxHashUtils, dxGDIPlusClasses, dxSmartImage,
  inLibDevExcel, inLibVerifactu, inLibFormatoDocumento;

const
  COL_DESC = 0;
  COL_CANT = 1;
  COL_PRECIO = 2;
  COL_PIVA = 3;
  COL_TOTAL = 4;
  COL_BASEI = 5;
  COL_TIPO_L = 6;
  COL_QR = 7;

type
  TExportadorFacturaDevExpress = class
  private
    FParametrosApp: IParametrosAplicacion;
    FRegistroLog: IRegistroLog;
    FConexion: TUniConnection;
    FControl: TdxSpreadSheet;
    FMaster: TDataSet;
    FLineas: TDataSet;
    FHoja: TdxSpreadSheetTableView;
    FFila: Integer;
    FDocumento: string;
    FImpuestosIncluidos: Boolean;
    FTieneRecargo: Boolean;
    function CampoTexto(const ANombre: string): string;
    function CampoNumero(const ANombre: string): Double;
    function TituloFactura: string;
    function PuedeIncrustarQR: Boolean;
    function Rango(AFilaInicial, AFilaFinal, AColumna: Integer): string;
    procedure ConfigurarNombreHoja;
    procedure AgregarImagenQR(const APng: TBytes);
    procedure IncrustarQRVerifactu;
    procedure EscribirInterviniente(AColumna, AAncho: Integer;
      const ATitulo, ACampoRazonSocial, ACampoNif, ACampoDireccion,
      ACampoCodigoPostal, ACampoPoblacion: string);
    procedure EscribirCabecera;
    procedure EscribirCabeceraLineas;
    procedure EscribirLinea;
    procedure EscribirLineas(out AFilaInicial, AFilaFinal: Integer);
    procedure EscribirCabeceraImpuestos;
    procedure PintarImpuesto(const ATipoLetra: string;
      APctIVA, APctRE: Double; const ARangoTipos, ARangoBases: string);
    procedure PintarImpuestoSiProcede(const ACampoBase, ACampoPorcentaje,
      ATipoLetra, ARangoTipos, ARangoBases: string; APctRE: Double);
    procedure CargarRecargos(out APctN, APctR, APctS, APctE: Double);
    procedure EscribirTablaImpuestos(AFilaInicial, AFilaFinal: Integer;
      out AFilaInicioTabla, AFilaFinTabla: Integer);
    procedure EscribirResumen(AFilaInicioTabla, AFilaFinTabla: Integer);
    procedure EscribirFormaPago;
    procedure ConfigurarColumnas;
  public
    constructor Create(const AParametrosApp: IParametrosAplicacion;
      const ARegistroLog: IRegistroLog;
      AConexion: TUniConnection; AControl: TdxSpreadSheet;
      const AMaster, ALineas: TDataSet);
    procedure Ejecutar;
  end;

constructor TExportadorFacturaDevExpress.Create(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  AControl: TdxSpreadSheet; const AMaster, ALineas: TDataSet);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FRegistroLog := ARegistroLog;
  FConexion := AConexion;
  FControl := AControl;
  FMaster := AMaster;
  FLineas := ALineas;
end;

function TExportadorFacturaDevExpress.CampoTexto(
  const ANombre: string): string;
begin
  Result := FMaster.FieldByName(ANombre).AsString;
end;

function TExportadorFacturaDevExpress.CampoNumero(
  const ANombre: string): Double;
begin
  Result := FMaster.FieldByName(ANombre).AsFloat;
end;

function TExportadorFacturaDevExpress.TituloFactura: string;
begin
  Result := 'FACTURA';
  if FMaster.FindField('TIPO_FAC') <> nil then
  begin
    if SameText(CampoTexto('TIPO_FAC'), 'SIMPLIFICADA') then
      Result := 'FACTURA SIMPLIFICADA'
    else if SameText(CampoTexto('TIPO_FAC'), 'RECTIFICATIVA') then
      Result := 'FACTURA RECTIFICATIVA';
  end;
  // Mientras el borrador no este consolidado no es una factura
  // emitida: sale como proforma, igual que en el informe.
  if not SinVerifactuActivo(FParametrosApp) and
     EsFacturaPendienteConsolidar(FMaster) then
    Result := 'FACTURA PROFORMA';
end;

function TExportadorFacturaDevExpress.PuedeIncrustarQR: Boolean;
begin
  Result := ObtenerUrlQRFactura(FParametrosApp, FMaster) <> '';
end;

function TExportadorFacturaDevExpress.Rango(
  AFilaInicial, AFilaFinal, AColumna: Integer): string;
begin
  Result := GetRef(AFilaInicial, AColumna, True) + ':' +
    GetRef(AFilaFinal, AColumna, True);
end;

procedure TExportadorFacturaDevExpress.ConfigurarNombreHoja;
const
  CARACTERES_NO_VALIDOS = '\/:*?[]';
var
  cCaracter: Char;
  sNombreHoja: string;
begin
  FDocumento := FormatearDocumentoDataSet(FMaster,
    'SERIE_FAC', 'NUMERO_FAC');
  if FDocumento <> '' then
  begin
    sNombreHoja := FDocumento;
    for cCaracter in CARACTERES_NO_VALIDOS do
      sNombreHoja := StringReplace(sNombreHoja, string(cCaracter), '_',
        [rfReplaceAll]);
    FHoja.Caption := Copy(Format(SCaptionHojaFactura,
                                 [sNombreHoja]), 1, 31);
  end;
end;

procedure TExportadorFacturaDevExpress.AgregarImagenQR(const APng: TBytes);
var
  oImagen: TdxSmartImage;
  oContenedor: TdxSpreadSheetPictureContainer;
  oStream: TBytesStream;
begin
  oImagen := TdxSmartImage.Create;
  try
    oStream := TBytesStream.Create(APng);
    try
      oStream.Position := 0;
      oImagen.LoadFromStream(oStream);
      if (oImagen.Width > 0) and (oImagen.Height > 0) then
      begin
        oContenedor := FHoja.Containers.Add(
          TdxSpreadSheetPictureContainer) as TdxSpreadSheetPictureContainer;
        if oContenedor <> nil then
        begin
          oContenedor.Picture.Image := oImagen;
          oContenedor.AnchorType := catTwoCell;
          oContenedor.AnchorPoint1.Cell := FHoja.CreateCell(1, COL_QR);
          oContenedor.AnchorPoint2.Cell := FHoja.CreateCell(7, COL_QR + 1);
          FHoja.Columns[COL_QR].Size := 120;
        end;
      end;
    finally
      FreeAndNil(oStream);
    end;
  finally
    FreeAndNil(oImagen);
  end;
end;

procedure TExportadorFacturaDevExpress.IncrustarQRVerifactu;
var
  aPng: TBytes;
  sUrl: string;
begin
  if PuedeIncrustarQR then
  begin
    sUrl := ObtenerUrlQRFactura(FParametrosApp, FMaster);
    aPng := GenerarQRPngVerifactu(sUrl);
    if Length(aPng) > 0 then
    begin
      try
        AgregarImagenQR(aPng);
      except
        // El QR opcional no impide exportar la factura.
        on E: Exception do
          FRegistroLog.RegistrarAviso(
            'FacturaExcel: QR Verifactu omitido: ' + E.Message);
      end;
    end;
  end;
end;

procedure TExportadorFacturaDevExpress.EscribirInterviniente(
  AColumna, AAncho: Integer; const ATitulo, ACampoRazonSocial,
  ACampoNif, ACampoDireccion, ACampoCodigoPostal,
  ACampoPoblacion: string);
begin
  W(FHoja, 4, AColumna, ATitulo, True);
  W(FHoja, 5, AColumna, CampoTexto(ACampoRazonSocial));
  Merge(FHoja, 5, AColumna, AAncho, 1);
  W(FHoja, 6, AColumna, 'NIF: ' + CampoTexto(ACampoNif));
  Merge(FHoja, 6, AColumna, AAncho, 1);
  W(FHoja, 7, AColumna, CampoTexto(ACampoDireccion));
  Merge(FHoja, 7, AColumna, AAncho, 1);
  W(FHoja, 8, AColumna, CampoTexto(ACampoCodigoPostal) + ' ' +
    CampoTexto(ACampoPoblacion));
  Merge(FHoja, 8, AColumna, AAncho, 1);
end;

procedure TExportadorFacturaDevExpress.EscribirCabecera;
begin
  ConfigurarNombreHoja;
  W(FHoja, 1, COL_DESC, TituloFactura, True);
  FHoja.Cells[1, COL_DESC].Style.Font.Size := 18;
  IncrustarQRVerifactu;
  W(FHoja, 1, COL_TOTAL, 'Fecha: ' + CampoTexto('FECHA_FAC'),
    False, ssahRight);
  W(FHoja, 2, COL_TOTAL, 'Número: ' + FDocumento, True, ssahRight);
  EscribirInterviniente(COL_DESC, 3, 'EMISOR',
    'RAZON_SOCIAL_EMPRESA_FAC', 'NIF_EMPRESA_FAC',
    'DIRECCION1_EMPRESA_FAC', 'CODIGO_POSTAL_EMPRESA_FAC',
    'POBLACION_EMPRESA_FAC');
  EscribirInterviniente(COL_PIVA, 2, 'RECEPTOR',
    'RAZON_SOCIAL_CLIENTE_FAC', 'NIF_CLIENTE_FAC',
    'DIRECCION1_CLIENTE_FAC', 'CODIGO_POSTAL_CLIENTE_FAC',
    'POBLACION_CLIENTE_FAC');
end;

procedure TExportadorFacturaDevExpress.EscribirCabeceraLineas;
var
  iColumna: Integer;
begin
  FFila := 11;
  W(FHoja, FFila, COL_DESC, 'Descripción', True);
  W(FHoja, FFila, COL_CANT, 'Cantidad', True, ssahRight);
  W(FHoja, FFila, COL_PRECIO, 'Precio', True, ssahRight);
  W(FHoja, FFila, COL_PIVA, '% IVA', True, ssahRight);
  W(FHoja, FFila, COL_TOTAL, 'Total', True, ssahRight);
  for iColumna := COL_DESC to COL_TOTAL do
    if FHoja.Cells[FFila, iColumna] <> nil then
      FHoja.Cells[FFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
end;

procedure TExportadorFacturaDevExpress.EscribirLinea;
var
  Celda: TdxSpreadSheetCell;
begin
  Inc(FFila);
  Celda := FHoja.CreateCell(FFila, COL_DESC);
  Celda.AsString := FLineas.FieldByName(
    'DESCRIPCION_ARTICULO_FACLIN').AsString;
  Celda.Style.WordWrap := True;
  Celda.Style.AlignVert := ssavTop;
  W(FHoja, FFila, COL_CANT,
    FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat, False, ssahRight);
  FHoja.Cells[FFila, COL_CANT].Style.AlignVert := ssavTop;
  W(FHoja, FFila, COL_PRECIO,
    FLineas.FieldByName('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat,
    False, ssahRight);
  FHoja.Cells[FFila, COL_PRECIO].Style.AlignVert := ssavTop;
  W(FHoja, FFila, COL_PIVA,
    FLineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsFloat,
    False, ssahRight);
  FHoja.Cells[FFila, COL_PIVA].Style.AlignVert := ssavTop;
  if FHoja.Cells[FFila, COL_PIVA] <> nil then
    FHoja.Cells[FFila, COL_PIVA].Style.DataFormat.FormatCode := '0.##"%"';
  WFormula(FHoja, FFila, COL_TOTAL,
    '=' + GetRef(FFila, COL_CANT) + '*' + GetRef(FFila, COL_PRECIO),
    '#,##0.00" €"');
  FHoja.Cells[FFila, COL_TOTAL].Style.AlignVert := ssavTop;
  if FImpuestosIncluidos then
    WFormula(FHoja, FFila, COL_BASEI, '=' + GetRef(FFila, COL_TOTAL) +
      '/(1+' + GetRef(FFila, COL_PIVA) + '/100)')
  else
    WFormula(FHoja, FFila, COL_BASEI, '=' + GetRef(FFila, COL_TOTAL));
  W(FHoja, FFila, COL_TIPO_L,
    FLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString,
    False, ssahCenter);
end;

procedure TExportadorFacturaDevExpress.EscribirLineas(
  out AFilaInicial, AFilaFinal: Integer);
begin
  EscribirCabeceraLineas;
  AFilaInicial := FFila + 1;
  FLineas.DisableControls;
  try
    FLineas.First;
    while not FLineas.Eof do
    begin
      EscribirLinea;
      FLineas.Next;
    end;
  finally
    FLineas.EnableControls;
  end;
  AFilaFinal := FFila;
end;

procedure TExportadorFacturaDevExpress.EscribirCabeceraImpuestos;
var
  iColumna: Integer;
begin
  W(FHoja, FFila, COL_DESC, 'Base Imponible', True, ssahRight);
  W(FHoja, FFila, COL_CANT, 'Tipo IVA', True, ssahRight);
  W(FHoja, FFila, COL_PRECIO, 'Cuota IVA', True, ssahRight);
  if FTieneRecargo then
  begin
    W(FHoja, FFila, COL_PIVA, '% RE', True, ssahRight);
    W(FHoja, FFila, COL_TOTAL, 'Total RE', True, ssahRight);
  end
  else
  begin
    W(FHoja, FFila, COL_PIVA, '', False);
    W(FHoja, FFila, COL_TOTAL, '', False);
  end;
  for iColumna := COL_DESC to COL_TOTAL do
    if FHoja.Cells[FFila, iColumna] <> nil then
      FHoja.Cells[FFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
end;

procedure TExportadorFacturaDevExpress.PintarImpuesto(
  const ATipoLetra: string; APctIVA, APctRE: Double;
  const ARangoTipos, ARangoBases: string);
var
  sRefBase: string;
begin
  Inc(FFila);
  WFormula(FHoja, FFila, COL_DESC,
    '=SUMIF(' + ARangoTipos + ';"' + ATipoLetra + '";' +
    ARangoBases + ')', '#,##0.00" €"');
  sRefBase := GetRef(FFila, COL_DESC);
  W(FHoja, FFila, COL_CANT, APctIVA, False, ssahCenter);
  if Frac(APctIVA) = 0 then
    FHoja.Cells[FFila, COL_CANT].Style.DataFormat.FormatCode := '0"%"'
  else
    FHoja.Cells[FFila, COL_CANT].Style.DataFormat.FormatCode := '0.##"%"';
  WFormula(FHoja, FFila, COL_PRECIO,
    '=' + sRefBase + '*' + FloatToStr(APctIVA) + '/100',
    '#,##0.00" €"');
  if APctRE > 0 then
  begin
    W(FHoja, FFila, COL_PIVA, APctRE, False, ssahCenter);
    FHoja.Cells[FFila, COL_PIVA].Style.DataFormat.FormatCode := '0.##"%"';
    WFormula(FHoja, FFila, COL_TOTAL, '=' + sRefBase + '*' +
      GetRef(FFila, COL_PIVA) + '/100', '#,##0.00" €"');
  end
  else
  begin
    W(FHoja, FFila, COL_PIVA, '', False, ssahCenter);
    W(FHoja, FFila, COL_TOTAL, '', False, ssahCenter);
  end;
end;

procedure TExportadorFacturaDevExpress.PintarImpuestoSiProcede(
  const ACampoBase, ACampoPorcentaje, ATipoLetra, ARangoTipos,
  ARangoBases: string; APctRE: Double);
begin
  if CampoNumero(ACampoBase) > 0 then
    PintarImpuesto(ATipoLetra, CampoNumero(ACampoPorcentaje),
      APctRE, ARangoTipos, ARangoBases);
end;

procedure TExportadorFacturaDevExpress.CargarRecargos(
  out APctN, APctR, APctS, APctE: Double);
begin
  APctN := 0;
  APctR := 0;
  APctS := 0;
  APctE := 0;
  if FTieneRecargo then
  begin
    APctN := CampoNumero('PORCENTAJE_REN_FAC');
    APctR := CampoNumero('PORCENTAJE_RER_FAC');
    APctS := CampoNumero('PORCENTAJE_RES_FAC');
    APctE := CampoNumero('PORCENTAJE_REE_FAC');
  end;
end;

procedure TExportadorFacturaDevExpress.EscribirTablaImpuestos(
  AFilaInicial, AFilaFinal: Integer;
  out AFilaInicioTabla, AFilaFinTabla: Integer);
var
  dPctN, dPctR, dPctS, dPctE: Double;
  sRangoBases, sRangoTipos: string;
begin
  Inc(FFila, 3);
  AFilaInicioTabla := FFila;
  sRangoBases := Rango(AFilaInicial, AFilaFinal, COL_BASEI);
  sRangoTipos := Rango(AFilaInicial, AFilaFinal, COL_TIPO_L);
  EscribirCabeceraImpuestos;
  CargarRecargos(dPctN, dPctR, dPctS, dPctE);
  PintarImpuestoSiProcede('TOTAL_BASEI_IVAN_FAC',
    'PORCENTAJE_IVAN_FAC', 'N', sRangoTipos, sRangoBases, dPctN);
  PintarImpuestoSiProcede('TOTAL_BASEI_IVAR_FAC',
    'PORCENTAJE_IVAR_FAC', 'R', sRangoTipos, sRangoBases, dPctR);
  PintarImpuestoSiProcede('TOTAL_BASEI_IVAS_FAC',
    'PORCENTAJE_IVAS_FAC', 'S', sRangoTipos, sRangoBases, dPctS);
  PintarImpuestoSiProcede('TOTAL_BASEI_IVAE_FAC',
    'PORCENTAJE_IVAE_FAC', 'E', sRangoTipos, sRangoBases, dPctE);
  AFilaFinTabla := FFila;
end;

procedure TExportadorFacturaDevExpress.EscribirResumen(
  AFilaInicioTabla, AFilaFinTabla: Integer);
var
  sFormula: string;
  sRefImpuestos, sRefRetenciones, sRefTotalBase: string;
  Celda: TdxSpreadSheetCell;
begin
  Inc(FFila, 2);
  W(FHoja, FFila, COL_PIVA, 'Total Base Imponible:', True, ssahRight);
  Celda := FHoja.CreateCell(FFila, COL_TOTAL);
  Celda.SetText('=SUM(' + GetRef(AFilaInicioTabla + 1, COL_DESC) + ':' +
    GetRef(AFilaFinTabla, COL_DESC) + ')', True);
  Celda.Style.DataFormat.FormatCode := '#,##0.00" €"';
  Celda.Style.AlignHorz := ssahRight;
  sRefTotalBase := GetRef(FFila, COL_TOTAL);
  Inc(FFila);
  W(FHoja, FFila, COL_PIVA, 'Total Impuestos (IVA+RE):',
    True, ssahRight);
  Celda := FHoja.CreateCell(FFila, COL_TOTAL);
  Celda.SetText('=SUM(' + GetRef(AFilaInicioTabla + 1, COL_PRECIO) + ':' +
    GetRef(AFilaFinTabla, COL_PRECIO) + ')+' +
    'SUM(' + GetRef(AFilaInicioTabla + 1, COL_TOTAL) + ':' +
    GetRef(AFilaFinTabla, COL_TOTAL) + ')', True);
  Celda.Style.DataFormat.FormatCode := '#,##0.00" €"';
  Celda.Style.AlignHorz := ssahRight;
  sRefImpuestos := GetRef(FFila, COL_TOTAL);
  sRefRetenciones := '';
  if Abs(CampoNumero('TOTAL_RETENCION_FAC')) > 0.001 then
  begin
    Inc(FFila);
    W(FHoja, FFila, COL_BASEI, CampoNumero('PORCENTAJE_RETENCION_FAC'));
    WFormula(FHoja, FFila, COL_PIVA, '="Retención IRPF ("&' +
      GetRef(FFila, COL_BASEI) + '&"%):"');
    Celda := FHoja.CreateCell(FFila, COL_TOTAL);
    Celda.SetText('=-(' + sRefTotalBase + '*' +
      GetRef(FFila, COL_BASEI) + '/100)', True);
    Celda.Style.Font.Color := clRed;
    Celda.Style.AlignHorz := ssahRight;
    Celda.Style.DataFormat.FormatCode := '#,##0.00" €"';
    sRefRetenciones := GetRef(FFila, COL_TOTAL);
  end;
  Inc(FFila);
  W(FHoja, FFila, COL_PIVA, 'TOTAL A PAGAR:', True, ssahRight);
  Celda := FHoja.CreateCell(FFila, COL_TOTAL);
  sFormula := '=' + sRefTotalBase + '+' + sRefImpuestos;
  if sRefRetenciones <> '' then
    sFormula := sFormula + '+' + sRefRetenciones;
  Celda.SetText(sFormula, True);
  Celda.Style.Font.Style := [fsBold];
  Celda.Style.Font.Size := 14;
  Celda.Style.DataFormat.FormatCode := '#,##0.00" €"';
  Celda.Style.AlignHorz := ssahRight;
end;

procedure TExportadorFacturaDevExpress.EscribirFormaPago;
var
  Celda: TdxSpreadSheetCell;
begin
  Inc(FFila, 2);
  Celda := FHoja.CreateCell(FFila, COL_DESC);
  Celda.AsString := 'Forma de Pago:';
  Celda.Style.Font.Style := [fsBold];
  Celda.Style.AlignVert := ssavCenter;
  Celda := FHoja.CreateCell(FFila, COL_CANT);
  Celda.AsString := CampoTexto('FORMA_PAGO_FAC');
  Celda.Style.AlignVert := ssavCenter;
  Celda.Style.AlignHorz := ssahLeft;
  Celda.Style.WordWrap := False;
  Merge(FHoja, FFila, COL_CANT, 4, 1);
end;

procedure TExportadorFacturaDevExpress.ConfigurarColumnas;
begin
  FHoja.Columns[COL_DESC].Size := 280;
  FHoja.Columns[COL_CANT].Size := 60;
  FHoja.Columns[COL_PRECIO].Size := 80;
  FHoja.Columns[COL_PIVA].Size := 180;
  FHoja.Columns[COL_TOTAL].Size := 110;
  FHoja.Columns[COL_BASEI].Visible := False;
  FHoja.Columns[COL_TIPO_L].Visible := False;
end;

procedure TExportadorFacturaDevExpress.Ejecutar;
var
  iFilaFinLineas, iFilaFinTabla: Integer;
  iFilaInicioLineas, iFilaInicioTabla: Integer;
begin
  FControl.ClearAll;
  FTieneRecargo := CampoTexto('ESIVA_RECARGO_CLIENTE_FAC') = 'S';
  FImpuestosIncluidos :=
    CampoTexto('ESIMP_INCL_TARIFA_CLIENTE_FAC') = 'S';
  FHoja := FControl.AddSheet('Factura',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirCabecera;
    EscribirLineas(iFilaInicioLineas, iFilaFinLineas);
    EscribirTablaImpuestos(iFilaInicioLineas, iFilaFinLineas,
      iFilaInicioTabla, iFilaFinTabla);
    EscribirResumen(iFilaInicioTabla, iFilaFinTabla);
    EscribirFormaPago;
    ConfigurarColumnas;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure ExportarFacturaADevExpress(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet; const QMaster, QLineas: TDataSet);
var
  oExportador: TExportadorFacturaDevExpress;
begin
  oExportador := TExportadorFacturaDevExpress.Create(
    AParametrosApp,
    ARegistroLog,
    AConexion,
    ASheetControl,
    QMaster,
    QLineas);
  try
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.

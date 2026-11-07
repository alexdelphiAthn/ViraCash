{******************************************************************************}
{                                                                              }
{  Módulo: inLibInformeTabular                                                 }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibInformeTabular;

interface

uses
  frxClass, frxDBSet;

type
  TColumnaInformeTabular = record
    Campo: string;
    Titulo: string;
    Peso: Double;
    Numerica: Boolean;
    Formato: string;
  end;
  TColumnasInformeTabular = TArray<TColumnaInformeTabular>;

function ColumnaInforme(const ACampo, ATitulo: string; APeso: Double;
  const AFormato: string = ''): TColumnaInformeTabular;
procedure CrearInformeTabular(AInforme: TfrxReport; ADatos: TfrxDBDataset;
  const ATitulo: string; const AColumnas: TColumnasInformeTabular);

implementation

uses
  inLibMsgInformesCliente,
  System.SysUtils, Vcl.Graphics, System.Classes, frCoreClasses,
  frBaseGraphicsTypes;

function ColumnaInforme(const ACampo, ATitulo: string; APeso: Double;
  const AFormato: string): TColumnaInformeTabular;
begin
  Result.Campo := ACampo;
  Result.Titulo := ATitulo;
  Result.Peso := APeso;
  Result.Numerica := AFormato <> '';
  Result.Formato := AFormato;
end;

function CrearMemo(ABanda: TfrxBand; const ANombre, ATexto: string;
  AX, AY, AAncho, AAlto: Double): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(ABanda);
  Result.Name := ANombre;
  Result.SetBounds(AX, AY, AAncho, AAlto);
  Result.Text := ATexto;
  Result.Font.Name := 'Arial';
  Result.Font.Size := 8;
  Result.WordWrap := True;
end;

procedure CrearColumnasInforme(ACabecera: TfrxPageHeader;
  ADetalle: TfrxMasterData; ADatos: TfrxDBDataset; AAncho: Double;
  const AColumnas: TColumnasInformeTabular);
var
  i: Integer;
  dPesos, dX, dAncho: Double;
  oColumna: TColumnaInformeTabular;
  oMemo: TfrxMemoView;
begin
  dPesos := 0;
  for oColumna in AColumnas do
    dPesos := dPesos + oColumna.Peso;
  dX := 0;
  for i := 0 to High(AColumnas) do
  begin
    oColumna := AColumnas[i];
    dAncho := AAncho * oColumna.Peso / dPesos;
    oMemo := CrearMemo(ACabecera, 'Cabecera' + IntToStr(i),
      oColumna.Titulo, dX, 30, dAncho - 3, 40);
    oMemo.Font.Style := [fsBold];
    oMemo.VAlign := vaBottom;
    if oColumna.Numerica then
      oMemo.HAlign := haRight;
    oMemo := CrearMemo(ADetalle, 'Dato' + IntToStr(i), '',
      dX, 0, dAncho - 3, 22);
    oMemo.DataSet := ADatos;
    oMemo.DataField := oColumna.Campo;
    oMemo.StretchMode := smActualHeight;
    if oColumna.Numerica then
    begin
      oMemo.HAlign := haRight;
      oMemo.DisplayFormat.Kind := fkNumeric;
      oMemo.DisplayFormat.FormatStr := oColumna.Formato;
    end;
    dX := dX + dAncho;
  end;
end;

procedure CrearInformeTabular(AInforme: TfrxReport; ADatos: TfrxDBDataset;
  const ATitulo: string; const AColumnas: TColumnasInformeTabular);
var
  oPagina: TfrxReportPage;
  oCabecera: TfrxPageHeader;
  oDetalle: TfrxMasterData;
  oPie: TfrxPageFooter;
  oMemo: TfrxMemoView;
  dAncho: Double;
begin
  AInforme.Clear;
  AInforme.EngineOptions.UseGlobalDataSetList := False;
  AInforme.EnabledDataSets.Add(ADatos);
  AInforme.DataSets.Add(ADatos);
  TfrxDataPage.Create(AInforme).Name := 'Datos';
  oPagina := TfrxReportPage.Create(AInforme);
  oPagina.Name := 'Pagina';
  oPagina.SetDefaults;
  oPagina.PaperWidth := 297;
  oPagina.PaperHeight := 210;
  oPagina.LeftMargin := 10;
  oPagina.RightMargin := 10;
  oPagina.TopMargin := 10;
  oPagina.BottomMargin := 10;
  dAncho := 277 * fr01cm;
  oCabecera := TfrxPageHeader.Create(oPagina);
  oCabecera.Name := 'CabeceraTabla';
  oCabecera.Height := 78;
  oMemo := CrearMemo(oCabecera, 'TituloTabla', ATitulo, 0, 0, dAncho, 24);
  oMemo.Font.Size := 12;
  oMemo.Font.Style := [fsBold];
  oDetalle := TfrxMasterData.Create(oPagina);
  oDetalle.Name := 'DetalleTabla';
  oDetalle.Top := 80;
  oDetalle.Height := 24;
  oDetalle.Stretched := True;
  oDetalle.DataSet := ADatos;
  CrearColumnasInforme(oCabecera, oDetalle, ADatos, dAncho, AColumnas);
  oPie := TfrxPageFooter.Create(oPagina);
  oPie.Name := 'PieTabla';
  oPie.Top := 140;
  oPie.Height := 20;
  CrearMemo(oPie, 'PaginaTabla', SInformePaginas,
    0, 0, dAncho, 18);
end;

end.

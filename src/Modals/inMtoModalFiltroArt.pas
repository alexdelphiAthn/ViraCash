{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFiltroArt                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Diálogo de acotado de la precarga de artículos. Se muestra cuando con     }
{    los filtros por defecto (solo activos + solo stock) salen más artículos   }
{    que el umbral admitido. Permite filtrar por temporada y proveedor,        }
{    mostrando en vivo cuántos artículos se cargarían.                         }
{    Se construye en código (CreateNew), sin .dfm.                            }
{******************************************************************************}
unit inMtoModalFiltroArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls,
  Vcl.Dialogs, Uni, cxLookAndFeelPainters,
  cxGraphics, cxControls, cxContainer, cxEdit, cxLabel, cxButtons,
  cxCheckBox, cxCheckListBox, inMtoFrmBase,
  inLibFiltroArticulosPersistenciaIntf;

type
  // Callback que cuenta los artículos que saldrían con una combinación de
  // filtros (temporada/proveedor/familia en CSV ';'). Lo provee el Mto de
  // Artículos para que el diálogo muestre el conteo en vivo con el MISMO
  // WHERE que usará la carga real. (La familia ya no se filtra desde aquí,
  // pero se mantiene en la firma para no tocar el llamador: pasa de largo.)
  TContarArticulosFunc = reference to function(const aTempCsv, aPrvCsv,
    aFamCsv: string): Integer;

  TfrmModalFiltroArt = class(TfrmBase)
  private
    FUmbral: Integer;
    FContar: TContarArticulosFunc;
    // Familia heredada del llamador: no se filtra en este diálogo, solo se
    // arrastra para el conteo y se devuelve sin cambios.
    FFamCsv: string;
    FlblCabecera: TcxLabel;
    FlblResultado: TcxLabel;
    FclbTemporada: TcxCheckListBox;
    FclbProveedor: TcxCheckListBox;
    // Códigos alineados por índice con los Items de la lista de proveedor
    // (el Text muestra la descripción; el filtro usa el código).
    FCodProv: TStringList;
    FbtnCalcular: TcxButton;
    FbtnAceptar: TcxButton;
    FbtnCancelar: TcxButton;
    FRepositorio: IRepositorioFiltroArticulos;
    procedure ConstruirUI;
    function  CrearCheckList(ALeft, ATop, AWidth, AHeight: Integer;
                            const ATitulo: string): TcxCheckListBox;
    procedure CargarTemporadas(const aPreCsv: string);
    procedure CargarProveedores(const aPreCsv: string);
    function  CsvMarcados(AClb: TcxCheckListBox;
                          ACodigos: TStringList): string;
    procedure ActualizarResultado;
    procedure CalcularClick(Sender: TObject);
    procedure AceptarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Muestra el diálogo. Devuelve True si el usuario acepta (y deja en los
    // parámetros out el CSV de cada filtro); False si cancela (los out
    // conservan lo recibido, para que el llamador cargue el filtro base).
    class function Ejecutar(AOwner: TComponent; AConn: TUniConnection;
      AUmbral: Integer;
      const APreTempCsv, APrePrvCsv, APreFamCsv: string;
      AContar: TContarArticulosFunc;
      out aTempCsv, aPrvCsv, aFamCsv: string): Boolean; overload;
    class function Ejecutar(
      AOwner: TComponent;
      AUmbral: Integer;
      const APreTempCsv, APrePrvCsv, APreFamCsv: string;
      AContar: TContarArticulosFunc;
      out aTempCsv, aPrvCsv, aFamCsv: string;
      const ARepositorio: IRepositorioFiltroArticulos): Boolean; overload;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgArticulos, inLibMsgComun,
  UniDataConfiguracionPantalla;

resourcestring
  STituloFiltroDemasiadosArticulos =
    'Demasiados artículos - acotar la carga';
  SCaptionTemporadaFiltroArticulos = 'Temporada';
  SCaptionProveedorFiltroArticulos = 'Proveedor';

constructor TfrmModalFiltroArt.Create(AOwner: TComponent);
begin
  // CreateNew: sin .dfm, montamos la UI a mano en ConstruirUI.
  inherited CreateNew(AOwner);
  FCodProv := TStringList.Create;
  ConstruirUI;
end;

destructor TfrmModalFiltroArt.Destroy;
begin
  FreeAndNil(FCodProv);
  inherited;
end;

function TfrmModalFiltroArt.CrearCheckList(ALeft, ATop, AWidth,
  AHeight: Integer; const ATitulo: string): TcxCheckListBox;
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent  := Self;
  lbl.Left    := ALeft;
  lbl.Top     := ATop;
  lbl.Caption := ATitulo;
  Result := TcxCheckListBox.Create(Self);
  Result.Parent := Self;
  Result.Left   := ALeft;
  Result.Top    := ATop + 18;
  Result.Width  := AWidth;
  Result.Height := AHeight;
  // Por defecto EditValueFormat es cvfInteger: empaqueta los estados como
  // bits de un integer y revienta con >64 items ("The number of items cannot
  // be greater than 64"). Un catálogo real tiene cientos de proveedores, así
  // que usamos cvfIndices (serializa los índices marcados como string, sin
  // tope). Leemos por Items[i].State, no por EditValue.
  Result.EditValueFormat := cvfIndices;
end;

procedure TfrmModalFiltroArt.ConstruirUI;
const
  MARGEN = 12;
  GAP    = 10;
var
  anchoCol, topListas, altoLista, topBotones: Integer;
  pnlBot: TPanel;
begin
  Caption      := STituloFiltroDemasiadosArticulos;
  BorderStyle  := bsDialog;
  Position     := poScreenCenter;
  ClientWidth  := 680;
  ClientHeight := 488;
  // Cabecera explicativa (multilínea)
  FlblCabecera := TcxLabel.Create(Self);
  FlblCabecera.Parent := Self;
  FlblCabecera.Left   := MARGEN;
  FlblCabecera.Top    := MARGEN;
  FlblCabecera.AutoSize := False;
  FlblCabecera.Width  := ClientWidth - 2 * MARGEN;
  FlblCabecera.Height := 52;
  FlblCabecera.Properties.WordWrap := True;
  // Dos columnas de selección (temporada / proveedor)
  topListas := MARGEN + 60;
  altoLista := 300;
  anchoCol  := (ClientWidth - 2 * MARGEN - GAP) div 2;
  FclbTemporada := CrearCheckList(MARGEN, topListas, anchoCol, altoLista,
                                  SCaptionTemporadaFiltroArticulos);
  FclbProveedor := CrearCheckList(MARGEN + anchoCol + GAP, topListas,
                                  anchoCol, altoLista,
                                  SCaptionProveedorFiltroArticulos);
  // Línea de resultado + botón Calcular
  topBotones := topListas + 18 + altoLista + 10;
  FlblResultado := TcxLabel.Create(Self);
  FlblResultado.Parent  := Self;
  FlblResultado.Left    := MARGEN;
  FlblResultado.Top     := topBotones + 8;
  FlblResultado.Caption := '';
  FbtnCalcular := TcxButton.Create(Self);
  FbtnCalcular.Parent  := Self;
  FbtnCalcular.Left    := MARGEN + 220;
  FbtnCalcular.Top     := topBotones;
  FbtnCalcular.Width   := 150;
  FbtnCalcular.Caption := SCaptionCalcularNumero;
  FbtnCalcular.OnClick := CalcularClick;
  // Panel inferior con Aceptar / Cancelar
  pnlBot := TPanel.Create(Self);
  pnlBot.Parent     := Self;
  pnlBot.Align      := alBottom;
  pnlBot.Height     := 44;
  pnlBot.BevelOuter := bvNone;
  FbtnAceptar := TcxButton.Create(Self);
  FbtnAceptar.Parent  := pnlBot;
  FbtnAceptar.Caption := SCaptionAceptar;
  FbtnAceptar.Width   := 110;
  FbtnAceptar.Height  := 28;
  FbtnAceptar.Top     := 8;
  FbtnAceptar.Left    := ClientWidth - 2 * 110 - MARGEN - GAP;
  FbtnAceptar.Default := True;
  FbtnAceptar.OnClick := AceptarClick;
  FbtnCancelar := TcxButton.Create(Self);
  FbtnCancelar.Parent     := pnlBot;
  FbtnCancelar.Caption    := SCaptionCancelar;
  FbtnCancelar.Width      := 110;
  FbtnCancelar.Height     := 28;
  FbtnCancelar.Top        := 8;
  FbtnCancelar.Left       := ClientWidth - 110 - MARGEN;
  FbtnCancelar.Cancel     := True;
  FbtnCancelar.ModalResult := mrCancel;
end;

procedure TfrmModalFiltroArt.CargarTemporadas(const aPreCsv: string);
var
  aTemporadas: TTemporadasFiltroArticulos;
  pre: TStringList;
  it: TcxCheckListBoxItem;
  sTemporada: string;
begin
  pre := TStringList.Create;
  try
    pre.Delimiter       := ';';
    pre.StrictDelimiter := True;
    pre.DelimitedText   := aPreCsv;
    aTemporadas := FRepositorio.ListarTemporadas;
    for sTemporada in aTemporadas do
    begin
      it := FclbTemporada.Items.Add;
      it.Text := sTemporada;
      if pre.IndexOf(it.Text) >= 0 then
      begin
        it.State := cbsChecked
      end
      else
      begin
        it.State := cbsUnchecked;
      end;
    end;
  finally
    FreeAndNil(pre);
  end;
end;

procedure TfrmModalFiltroArt.CargarProveedores(const aPreCsv: string);
var
  aProveedores: TProveedoresFiltroArticulos;
  oProveedor: TProveedorFiltroArticulos;
  pre: TStringList;
  it: TcxCheckListBoxItem;
  cod: string;
begin
  FCodProv.Clear;
  pre := TStringList.Create;
  try
    pre.Delimiter       := ';';
    pre.StrictDelimiter := True;
    pre.DelimitedText   := aPreCsv;
    aProveedores := FRepositorio.ListarProveedores;
    for oProveedor in aProveedores do
    begin
      cod := oProveedor.Codigo;
      it := FclbProveedor.Items.Add;
      it.Text := oProveedor.Nombre + ' (' + cod + ')';
      if pre.IndexOf(cod) >= 0 then
      begin
        it.State := cbsChecked
      end
      else
      begin
        it.State := cbsUnchecked;
      end;
      FCodProv.Add(cod);
    end;
  finally
    FreeAndNil(pre);
  end;
end;

function TfrmModalFiltroArt.CsvMarcados(AClb: TcxCheckListBox;
  ACodigos: TStringList): string;
var
  i: Integer;
  val: string;
begin
  // Para temporada (ACodigos=nil) el valor es el propio texto del item;
  // para proveedor es el código alineado por índice.
  Result := '';
  for i := 0 to AClb.Items.Count - 1 do
    if AClb.Items[i].State = cbsChecked then
    begin
      if (ACodigos <> nil) and (i < ACodigos.Count) then
        val := ACodigos[i]
      else
        val := AClb.Items[i].Text;
      if Result <> '' then Result := Result + ';';
      Result := Result + val;
    end;
end;

procedure TfrmModalFiltroArt.ActualizarResultado;
var
  n: Integer;
begin
  if Assigned(FContar) then
  begin
    Screen.Cursor := crHourGlass;
    try
      n := FContar(CsvMarcados(FclbTemporada, nil),
                   CsvMarcados(FclbProveedor, FCodProv),
                   FFamCsv);
    finally
      Screen.Cursor := crDefault;
    end;
    FlblResultado.Caption := Format(SCaptionSeCargaranArticulos,
                                    [n, FUmbral]);
    if n > FUmbral then
      FlblResultado.Style.TextColor := clRed
    else
      FlblResultado.Style.TextColor := clGreen;
  end;
end;

procedure TfrmModalFiltroArt.CalcularClick(Sender: TObject);
begin
  ActualizarResultado;
end;

procedure TfrmModalFiltroArt.AceptarClick(Sender: TObject);
var
  n: Integer;
  bSeguir: Boolean;
begin
  bSeguir := True;
  if Assigned(FContar) then
  begin
    Screen.Cursor := crHourGlass;
    try
      n := FContar(CsvMarcados(FclbTemporada, nil),
                   CsvMarcados(FclbProveedor, FCodProv),
                   FFamCsv);
    finally
      Screen.Cursor := crDefault;
    end;
    if n > FUmbral then
      bSeguir := MessageDlg_fza(
        Format(SPreguntaSuperarLimiteCargaArticulos,
               [n, FUmbral]),
        mtWarning, [mbYes, mbNo], 0) = mrYes;
  end;
  if bSeguir then
    ModalResult := mrOk;
end;

class function TfrmModalFiltroArt.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection; AUmbral: Integer;
  const APreTempCsv, APrePrvCsv, APreFamCsv: string;
  AContar: TContarArticulosFunc;
  out aTempCsv, aPrvCsv, aFamCsv: string): Boolean;
begin
  Result := False;
  ValidarDependenciaConfiguracion(
    nil,
    'filtros de artículos');
end;

class function TfrmModalFiltroArt.Ejecutar(
  AOwner: TComponent;
  AUmbral: Integer;
  const APreTempCsv, APrePrvCsv, APreFamCsv: string;
  AContar: TContarArticulosFunc;
  out aTempCsv, aPrvCsv, aFamCsv: string;
  const ARepositorio: IRepositorioFiltroArticulos): Boolean;
var
  frm: TfrmModalFiltroArt;
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'filtros de artículos');
  // Si cancela, devolvemos lo recibido para que el Mto cargue el filtro base.
  aTempCsv := APreTempCsv;
  aPrvCsv  := APrePrvCsv;
  aFamCsv  := APreFamCsv;
  Result := False;
  frm := TfrmModalFiltroArt.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.FUmbral := AUmbral;
    frm.FContar := AContar;
    frm.FFamCsv := APreFamCsv;
    frm.FlblCabecera.Caption :=
      Format(SCaptionDemasiadosArticulosFiltro, [AUmbral]);
    frm.CargarTemporadas(APreTempCsv);
    frm.CargarProveedores(APrePrvCsv);
    frm.ActualizarResultado;
    if frm.ShowModal = mrOk then
    begin
      aTempCsv := frm.CsvMarcados(frm.FclbTemporada, nil);
      aPrvCsv  := frm.CsvMarcados(frm.FclbProveedor, frm.FCodProv);
      aFamCsv  := frm.FFamCsv;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

end.

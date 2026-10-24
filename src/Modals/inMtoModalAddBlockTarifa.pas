{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockTarifa                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de carga masiva de articulos en una tarifa.                         }
{    Hereda de AddBlockBase y permite ajustes de precio y descuento.           }
{******************************************************************************}
unit inMtoModalAddBlockTarifa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxClasses, cxContainer, cxEdit,
  cxLabel, cxButtons, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxCurrencyEdit, cxCheckBox, cxRadioGroup,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inMtoModalAddBlockBase, cxLookAndFeelPainters, Vcl.Menus, cxFilter,
  cxCustomData, cxStyles, dxScrollbarAnnotations, cxTL, cxDBData, Vcl.ComCtrls,
  dxCore, cxDateUtils, JvComponentBase, JvEnterTab, cxLocalization, cxSplitter,
  cxSpinEdit, cxCustomListBox, cxCheckListBox, cxGroupBox, cxInplaceContainer,
  cxDBTL, cxTLData, cxPC,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  TAjusteAlcance = TAjusteAlcanceCargaMasiva;

  TAddBlockTarifaResult = record
    Aceptado          : Boolean;
    NumInsertados     : Integer;
    ArticulosCodigos  : TArray<string>;
    CodigoTarifa      : string;
    FechaDesdeTarifa  : TDateTime;
    FechaHastaTarifa  : TDateTime;
    UsaFechaHasta     : Boolean;
    PorcenDtoDefecto  : Double;
    AjustarPrecio     : Boolean;
    MultiploAjuste    : Double;
    RestarAjuste      : Double;
    AlcanceAjuste     : TAjusteAlcance;
    CopiarDeTarifa    : string;
  end;

  TfrmModalAddBlockTarifa = class(TfrmModalAddBlockBase)
    // Controles que viven en pnlCabeceraExtra (heredado vacio)
    lblTarifa: TcxLabel;
    cbxTarifa: TcxComboBox;
    lblFechaDesde: TcxLabel;
    dtFechaDesde: TcxDateEdit;
    chkConFechaHasta: TcxCheckBox;
    dtFechaHasta: TcxDateEdit;
    lblPorcenDto: TcxLabel;
    spnPorcenDto: TcxCurrencyEdit;
    chkAjustarPrecio: TcxCheckBox;
    lblMultiplo: TcxLabel;
    spnMultiplo: TcxCurrencyEdit;
    lblRestar: TcxLabel;
    spnRestar: TcxCurrencyEdit;
    rgAjusteAlcance: TcxRadioGroup;
    chkCopiarDeTarifa: TcxCheckBox;
    cbxTarifaOrigen: TcxComboBox;

    // Columnas extra del preview (precios origen)
    colPrevPrecioSalidaOrig: TcxGridDBColumn;
    colPrevPrecioFinalOrig: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);
    procedure chkConFechaHastaPropertiesChange(Sender: TObject);
    procedure chkAjustarPrecioPropertiesChange(Sender: TObject);
    procedure chkCopiarDeTarifaPropertiesChange(Sender: TObject);

  protected
    FResultadoTarifa : TAddBlockTarifaResult;
    FCodigoTarifaIni : string;

    // === Overrides ==========================================================
    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    override;
    function ContextoCargaMasiva: TContextoCargaMasivaArticulos; override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;
    procedure ConfigurarPreviewExtra; override;

    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean;
                                override;

  private
    procedure CargarTarifas;
    function  ObtenerCodigoTarifaActual: string;
    function  ObtenerCodigoTarifaOrigen: string;
    function  AlcanceAjusteActual: TAjusteAlcance;

  public
    class function Ejecutar(
      AOwner: TComponent;
      const ACodigoTarifa: string): TAddBlockTarifaResult; overload;
    class function Ejecutar(
      AOwner: TComponent;
      const ACodigoTarifa: string;
      const AServicios: TServiciosCargaMasivaArticulos):
      TAddBlockTarifaResult; overload;
    property ResultadoTarifa: TAddBlockTarifaResult read FResultadoTarifa;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgArticulos;

resourcestring
  SCaptionExcluirArticulosYaEnTarifa =
    'Excluir articulos ya en la tarifa';

// ============================================================================
//   API publica
// ============================================================================

class function TfrmModalAddBlockTarifa.Ejecutar(
  AOwner: TComponent;
  const ACodigoTarifa: string): TAddBlockTarifaResult;
var
  Servicios: TServiciosCargaMasivaArticulos;
begin
  Servicios := Default(TServiciosCargaMasivaArticulos);
  Result := Ejecutar(AOwner, ACodigoTarifa, Servicios);
end;

class function TfrmModalAddBlockTarifa.Ejecutar(
  AOwner: TComponent;
  const ACodigoTarifa: string;
  const AServicios: TServiciosCargaMasivaArticulos):
  TAddBlockTarifaResult;
var
  frm: TfrmModalAddBlockTarifa;
  i  : Integer;
begin
  frm := TfrmModalAddBlockTarifa.Create(AOwner, AServicios);
  try
    frm.FCodigoTarifaIni := ACodigoTarifa;
    frm.Inicializar;
    frm.CargarTarifas;

    if ACodigoTarifa <> '' then
      for i := 0 to frm.cbxTarifa.Properties.Items.Count - 1 do
        if Pos(ACodigoTarifa, frm.cbxTarifa.Properties.Items[i]) = 1 then
        begin
          frm.cbxTarifa.ItemIndex := i;
          Break;
        end;

    frm.ShowModal;
    Result := frm.FResultadoTarifa;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockTarifa.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Caption := STituloAnadirBloqueTarifa;

  // Defaults especificos
  dtFechaDesde.Date           := Date;
  chkConFechaHasta.Checked    := False;
  dtFechaHasta.Enabled        := False;
  spnPorcenDto.Value          := 0;
  chkAjustarPrecio.Checked    := False;
  spnMultiplo.Value           := 0.01;
  spnRestar.Value             := 0.01;
  spnMultiplo.Enabled         := False;
  spnRestar.Enabled           := False;
  rgAjusteAlcance.Enabled     := False;
  rgAjusteAlcance.ItemIndex   := 0;
  chkCopiarDeTarifa.Checked   := False;
  cbxTarifaOrigen.Enabled     := False;

  FResultadoTarifa.Aceptado := False;
end;

procedure TfrmModalAddBlockTarifa.CargarTarifas;
var
  aTarifas: TTarifasCargaMasiva;
  oTarifa: TTarifaCargaMasiva;
begin
  aTarifas := ConsultasCargaMasiva.ListarTarifas;
  cbxTarifa.Properties.Items.Clear;
  cbxTarifaOrigen.Properties.Items.Clear;
  for oTarifa in aTarifas do
  begin
    cbxTarifa.Properties.Items.Add(
      oTarifa.Codigo + ' - ' + oTarifa.Nombre);
    cbxTarifaOrigen.Properties.Items.Add(
      oTarifa.Codigo + ' - ' + oTarifa.Nombre);
  end;
end;

// ============================================================================
//   Eventos
// ============================================================================

procedure TfrmModalAddBlockTarifa.chkConFechaHastaPropertiesChange(
  Sender: TObject);
begin
  dtFechaHasta.Enabled := chkConFechaHasta.Checked;
end;

procedure TfrmModalAddBlockTarifa.chkAjustarPrecioPropertiesChange(
  Sender: TObject);
begin
  spnMultiplo.Enabled     := chkAjustarPrecio.Checked;
  spnRestar.Enabled       := chkAjustarPrecio.Checked;
  rgAjusteAlcance.Enabled := chkAjustarPrecio.Checked;
end;

procedure TfrmModalAddBlockTarifa.chkCopiarDeTarifaPropertiesChange(
  Sender: TObject);
begin
  cbxTarifaOrigen.Enabled := chkCopiarDeTarifa.Checked;
  if not chkCopiarDeTarifa.Checked then
    cbxTarifaOrigen.ItemIndex := -1;
end;

// ============================================================================
//   Helpers
// ============================================================================

function TfrmModalAddBlockTarifa.ObtenerCodigoTarifaActual: string;
begin
  Result := Trim(cbxTarifa.Text);
  if Pos(' - ', Result) > 0 then
    Result := Copy(Result, 1, Pos(' - ', Result) - 1);
end;

function TfrmModalAddBlockTarifa.ObtenerCodigoTarifaOrigen: string;
begin
  if chkCopiarDeTarifa.Checked then
  begin
    Result := Trim(cbxTarifaOrigen.Text);
    if Pos(' - ', Result) > 0 then
      Result := Copy(Result, 1, Pos(' - ', Result) - 1);
  end
  else
    Result := '';
end;

function TfrmModalAddBlockTarifa.AlcanceAjusteActual: TAjusteAlcance;
begin
  case rgAjusteAlcance.ItemIndex of
    1: Result := aaSoloSalida;
    2: Result := aaAmbos;
  else
    Result := aaSoloFinal;
  end;
end;

// ============================================================================
//   Overrides de la base
// ============================================================================

function TfrmModalAddBlockTarifa.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := False;
  AMensaje := '';

  if ObtenerCodigoTarifaActual = '' then
    AMensaje := SErrorTarifaDestinoAddBlockNoSeleccionada
  else if chkCopiarDeTarifa.Checked and
          (ObtenerCodigoTarifaOrigen = '') then
    AMensaje := SErrorTarifaOrigenAddBlockNoSeleccionada
  else if chkCopiarDeTarifa.Checked and
          SameText(ObtenerCodigoTarifaOrigen,
            ObtenerCodigoTarifaActual) then
    AMensaje := SErrorTarifasAddBlockCoincidentes
  else if chkAjustarPrecio.Checked and (spnMultiplo.Value <= 0) then
    AMensaje := SErrorMultiploAjusteAddBlockNoValido
  else
  begin
    Result := True;
  end;
end;

function TfrmModalAddBlockTarifa.ContextoCargaMasiva:
  TContextoCargaMasivaArticulos;
begin
  Result.Modo := mcTarifa;
  Result.CodigoTarifa := ObtenerCodigoTarifaActual;
  Result.CodigoTarifaOrigen := ObtenerCodigoTarifaOrigen;
end;

function TfrmModalAddBlockTarifa.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarTarifaAddBlock,
                   [ANumPendientes, ObtenerCodigoTarifaActual]);
end;

function TfrmModalAddBlockTarifa.TextoExito(ANumInsertados: Integer): string;
begin
  Result := Format(SInfoArticulosTarifaAddBlockAnadidos,
                   [ANumInsertados]);
end;

function TfrmModalAddBlockTarifa.TextoExcluirYaCargados: string;
begin
  Result := SCaptionExcluirArticulosYaEnTarifa;
end;

procedure TfrmModalAddBlockTarifa.ConfigurarPreviewExtra;
begin
  // Las columnas extra (precios origen) ya estan en el DFM
  // y se enlazan automaticamente por DataBinding.FieldName.
  // Aqui podriamos forzar visibilidad si el usuario no copia de tarifa.
  colPrevPrecioSalidaOrig.Visible := chkCopiarDeTarifa.Checked;
  colPrevPrecioFinalOrig.Visible  := chkCopiarDeTarifa.Checked;
end;

// ============================================================================
//   Insercion real
// ============================================================================

function TfrmModalAddBlockTarifa.EjecutarInsercion(
  out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  oParametros: TParametrosInsercionTarifa;
  oResultado: TResultadoInsercionCargaMasiva;
begin
  Result := False;
  ANumInsertados := 0;
  SetLength(ACodigos, 0);
  if Assigned(DatosPreview) and DatosPreview.Active and
     (DatosPreview.RecordCount > 0) then
  begin
    oParametros.CodigoTarifa := ObtenerCodigoTarifaActual;
    oParametros.CodigoTarifaOrigen := ObtenerCodigoTarifaOrigen;
    oParametros.FechaDesde := dtFechaDesde.Date;
    oParametros.FechaHasta := dtFechaHasta.Date;
    oParametros.UsaFechaHasta := chkConFechaHasta.Checked;
    oParametros.PorcentajeDescuento := spnPorcenDto.Value;
    oParametros.AjustarPrecio := chkAjustarPrecio.Checked;
    oParametros.MultiploAjuste := spnMultiplo.Value;
    oParametros.RestarAjuste := spnRestar.Value;
    oParametros.AlcanceAjuste := AlcanceAjusteActual;
    oParametros.Usuario := IdentidadSesion.Usuario;
    try
      oResultado := InsercionesCargaMasiva.InsertarTarifa(
        ConsultaPreview,
        oParametros);
      ANumInsertados := oResultado.NumeroLineas;
      ACodigos := oResultado.CodigosArticulo;
      FResultadoTarifa.Aceptado := True;
      FResultadoTarifa.NumInsertados := ANumInsertados;
      FResultadoTarifa.ArticulosCodigos := ACodigos;
      FResultadoTarifa.CodigoTarifa := oParametros.CodigoTarifa;
      FResultadoTarifa.FechaDesdeTarifa := oParametros.FechaDesde;
      FResultadoTarifa.UsaFechaHasta := oParametros.UsaFechaHasta;
      if oParametros.UsaFechaHasta then
      begin
        FResultadoTarifa.FechaHastaTarifa := oParametros.FechaHasta;
      end;
      FResultadoTarifa.PorcenDtoDefecto :=
        oParametros.PorcentajeDescuento;
      FResultadoTarifa.AjustarPrecio := oParametros.AjustarPrecio;
      FResultadoTarifa.MultiploAjuste := oParametros.MultiploAjuste;
      FResultadoTarifa.RestarAjuste := oParametros.RestarAjuste;
      FResultadoTarifa.AlcanceAjuste := oParametros.AlcanceAjuste;
      FResultadoTarifa.CopiarDeTarifa := oParametros.CodigoTarifaOrigen;
      Result := True;
    except
      on E: Exception do
      begin
        ShowMessage_fza(SErrorInsertarTarifaAddBlock + E.Message);
      end;
    end;
  end;
end;

end.

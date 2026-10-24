{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalOperacionesCajaSku                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resumen de ventas, devoluciones y préstamos de un SKU desde la consulta   }
{    de stock. Muestra las operaciones VE, DV y DE vinculadas al artículo.     }
{******************************************************************************}
unit inMtoModalOperacionesCajaSku;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxButtons, cxCurrencyEdit, cxCalendar,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData,
  cxGridLevel, cxClasses, cxStyles, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  dxDateRanges, dxScrollbarAnnotations,
  Uni,
  inMtoFrmBase, inLibOperacionesCajaSkuPersistenciaIntf,
  inLibCajaPantallaInyeccion;

type
  TfrmModalOperacionesCajaSku = class(TfrmBase)
    pnlSuperior: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdOperaciones: TcxGrid;
    tvOperaciones: TcxGridDBTableView;
    cxgrdlvlOperaciones: TcxGridLevel;
    tvOperacionesTIPO_OPERACION: TcxGridDBColumn;
    tvOperacionesNUMERO_OPERACION: TcxGridDBColumn;
    tvOperacionesFECHA_OPERACION: TcxGridDBColumn;
    tvOperacionesFACTURA: TcxGridDBColumn;
    tvOperacionesDESCRIPCION_ARTICULO: TcxGridDBColumn;
    tvOperacionesPRECIO_VENTA: TcxGridDBColumn;
    tvOperacionesDESCUENTO: TcxGridDBColumn;
    dsOperaciones: TDataSource;
    pnlBotones: TPanel;
    lblResultado: TcxLabel;
    btnIrOperacion: TcxButton;
    btnIrFacturaSimplificada: TcxButton;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dsOperacionesDataChange(Sender: TObject; Field: TField);
    procedure btnIrOperacionClick(Sender: TObject);
    procedure btnIrFacturaSimplificadaClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConn: TUniConnection;
    FCodigoSku: string;
    FDescripcionArticulo: string;
    FConsulta: IConsultaOperacionesCajaSku;
    FRepositorioOperaciones: IRepositorioOperacionesCajaSku;
    FDatos: TDataSet;
    FCallNavegacion: string;
    FBusquedaNavegacion: string;
    procedure ComponerDependencias;
    procedure ActualizarAcciones;
    procedure ActualizarCabecera;
    procedure CargarOperaciones;
    function FacturaSeleccionada(
      out ASerie, ANumero: string): Boolean;
    function OperacionSeleccionada(
      out AEmpresa, AAlmacen, ACaja, ANumero: string): Boolean;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ACodigoSku, ADescripcionArticulo: string); overload;
    class procedure Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ARepositorio: IRepositorioOperacionesCajaSku;
      const ACodigoSku, ADescripcionArticulo: string); overload;
  end;

implementation

uses
  inLibShowMto, inLibMsgCaja;

{$R *.dfm}

class procedure TfrmModalOperacionesCajaSku.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ACodigoSku, ADescripcionArticulo: string);
begin
  ValidarDependenciaCaja(nil, 'operaciones del SKU en Caja');
end;

class procedure TfrmModalOperacionesCajaSku.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ARepositorio: IRepositorioOperacionesCajaSku;
  const ACodigoSku, ADescripcionArticulo: string);
var
  frm: TfrmModalOperacionesCajaSku;
begin
  ValidarDependenciaCaja(ARepositorio, 'operaciones del SKU en Caja');
  frm := TfrmModalOperacionesCajaSku.Create(AOwner);
  try
    frm.FConn := AConn;
    frm.FCodigoSku := ACodigoSku;
    frm.FDescripcionArticulo := ADescripcionArticulo;
    frm.FRepositorioOperaciones := ARepositorio;
    frm.ComponerDependencias;
    frm.ShowModal;
    if frm.FCallNavegacion <> '' then
    begin
      if AOwner is TCustomForm then
      begin
        TCustomForm(AOwner).Hide;
      end;
      if Application.MainForm <> nil then
      begin
        ShowMto(
          Application.MainForm,
          frm.FCallNavegacion,
          frm.FBusquedaNavegacion);
      end;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalOperacionesCajaSku.ComponerDependencias;
begin
  ValidarDependenciaCaja(
    FRepositorioOperaciones,
    'operaciones del SKU en Caja');
end;

procedure TfrmModalOperacionesCajaSku.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Self.KeyPreview := True;
  FCallNavegacion := '';
  FBusquedaNavegacion := '';
end;

procedure TfrmModalOperacionesCajaSku.FormShow(Sender: TObject);
begin
  ActualizarCabecera;
  CargarOperaciones;
  ActualizarAcciones;
  if (not FDatos.IsEmpty) and cxgrdOperaciones.CanFocus then
    cxgrdOperaciones.SetFocus;
end;

procedure TfrmModalOperacionesCajaSku.ActualizarAcciones;
var
  sEmpresa  : string;
  sAlmacen  : string;
  sCaja     : string;
  sOperacion: string;
  sSerie    : string;
  sFactura  : string;
begin
  btnIrOperacion.Enabled := OperacionSeleccionada(
    sEmpresa, sAlmacen, sCaja, sOperacion);
  btnIrFacturaSimplificada.Enabled := FacturaSeleccionada(
    sSerie, sFactura);
end;

procedure TfrmModalOperacionesCajaSku.ActualizarCabecera;
var
  sDescripcion: string;
begin
  sDescripcion := Trim(FDescripcionArticulo);
  if sDescripcion = '' then
    sDescripcion := FCodigoSku;
  lblTitulo.Caption := sDescripcion + ' · ' + FCodigoSku;
end;

procedure TfrmModalOperacionesCajaSku.CargarOperaciones;
var
  iOperaciones: Integer;
begin
  if (FConn = nil) or (not FConn.Connected) then
    raise Exception.Create(SErrorConexionOperacionesCajaSkuNoDisponible);
  FConsulta := FRepositorioOperaciones.ConsultarOperaciones(FCodigoSku);
  FDatos := FConsulta.DataSet;
  dsOperaciones.DataSet := FDatos;
  iOperaciones := 0;
  if not FDatos.IsEmpty then
  begin
    FDatos.Last;
    iOperaciones := FDatos.RecordCount;
    FDatos.First;
  end;
  if iOperaciones = 1 then
  begin
    lblResultado.Caption := SCaptionUnaOperacion;
  end
  else
  begin
    lblResultado.Caption := Format(SCaptionNumOperaciones,
                                   [iOperaciones]);
  end;
end;

function TfrmModalOperacionesCajaSku.FacturaSeleccionada(
  out ASerie, ANumero: string): Boolean;
begin
  Result := False;
  ASerie := '';
  ANumero := '';
  if Assigned(FDatos) and FDatos.Active and
     (not FDatos.IsEmpty) then
  begin
    ASerie := Trim(FDatos.FieldByName('SERIE_FACTURA').AsString);
    ANumero := Trim(FDatos.FieldByName('NUMERO_FACTURA').AsString);
    Result := (ASerie <> '') and
              (ANumero <> '') and
              (ANumero <> '0');
  end;
end;

function TfrmModalOperacionesCajaSku.OperacionSeleccionada(
  out AEmpresa, AAlmacen, ACaja, ANumero: string): Boolean;
begin
  Result := False;
  AEmpresa := '';
  AAlmacen := '';
  ACaja := '';
  ANumero := '';
  if Assigned(FDatos) and FDatos.Active and
     (not FDatos.IsEmpty) then
  begin
    AEmpresa := Trim(FDatos.FieldByName('CODIGO_EMP_OPCAJA').AsString);
    AAlmacen := Trim(FDatos.FieldByName('CODIGO_ALM_OPCAJA').AsString);
    ACaja := Trim(FDatos.FieldByName('CODIGO_CAJA_OPCAJA').AsString);
    ANumero := Trim(FDatos.FieldByName('NUMERO_OPERACION').AsString);
    Result := (AEmpresa <> '') and
              (AAlmacen <> '') and
              (ACaja <> '') and
              (ANumero <> '');
  end;
end;

procedure TfrmModalOperacionesCajaSku.dsOperacionesDataChange(
  Sender: TObject; Field: TField);
begin
  ActualizarAcciones;
end;

procedure TfrmModalOperacionesCajaSku.btnIrOperacionClick(
  Sender: TObject);
var
  sEmpresa  : string;
  sAlmacen  : string;
  sCaja     : string;
  sOperacion: string;
begin
  if OperacionSeleccionada(
       sEmpresa, sAlmacen, sCaja, sOperacion) then
  begin
    FCallNavegacion := 'CajaOperacionesHist';
    FBusquedaNavegacion :=
      sEmpresa + ',' + sAlmacen + ',' + sCaja + ',' + sOperacion;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalOperacionesCajaSku.btnIrFacturaSimplificadaClick(
  Sender: TObject);
var
  sSerie  : string;
  sFactura: string;
begin
  if FacturaSeleccionada(sSerie, sFactura) then
  begin
    FCallNavegacion := 'FacturasSimplif';
    FBusquedaNavegacion := sFactura + ',' + sSerie;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalOperacionesCajaSku.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.

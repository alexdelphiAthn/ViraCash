{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArqueosHistCaja                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico de arqueos dentro del TPV (caja). Lista los cierres grabados    }
{    de la caja actual y permite reemitir un DUPLICADO del ticket de arqueo    }
{    o del justificante de cierre en la impresora de tickets.                  }
{    Se abre desde el modal de arqueo (F11) y no recalcula nada: lee de        }
{    fza_caja_arqueos / fza_caja_arqueos_recuento.                             }
{******************************************************************************}
unit inMtoModalArqueosHistCaja;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxCurrencyEdit, cxLabel, cxButtons,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses, cxStyles, dxDateRanges,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, dxScrollbarAnnotations,
  // Acceso a datos
  Uni,
  inMtoFrmBase, inLibArqueoTicket,
  inLibInformesCajaPersistenciaIntf, inLibArqueoIntf,
  inLibArqueoTicketIntf, inLibCajaPantallaInyeccion;

type
  TfrmModalArqueosHistCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlSuperior: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdArqueos: TcxGrid;
    dbtvArqueos: TcxGridDBTableView;
    cxgrdlvlArqueos: TcxGridLevel;
    colCodigo: TcxGridDBColumn;
    colDesde: TcxGridDBColumn;
    colHasta: TcxGridDBColumn;
    colFase: TcxGridDBColumn;
    colVentas: TcxGridDBColumn;
    colTotalVentas: TcxGridDBColumn;
    colEfectivo: TcxGridDBColumn;
    colRecuento: TcxGridDBColumn;
    colDiferencia: TcxGridDBColumn;
    colUsuario: TcxGridDBColumn;
    dsArqueos: TDataSource;
    btnDupTicket: TcxButton;
    btnDupCierre: TcxButton;
    btnSalir: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure AplicarEstiloCaja;
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnDupTicketClick(Sender: TObject);
    procedure btnDupCierreClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure dbtvArqueosDblClick(Sender: TObject);
    procedure colFaseGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FDatos: TDataSet;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    FRepositorioArqueoCaja: IRepositorioArqueoCaja;
    FRepositorioArqueoTicket: IRepositorioArqueoTicket;
    procedure ComponerDependencias;
    procedure CargarArqueos;
    function ArqueoSeleccionado: string;
  public
    class procedure Ejecutar(AOwner: TComponent;
                             AConn: TUniConnection;
                             const AEmpresa: string;
                             const AAlmacen: string;
                             const ACaja: string); overload;
    class procedure Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ADependencias: TDependenciasArqueosHistoricosCaja;
      const AEmpresa: string;
      const AAlmacen: string;
      const ACaja: string); overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgCaja, inLibCajaEstiloVcl, inLibPosicionFormulario;

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmModalArqueosHistCaja }

class procedure TfrmModalArqueosHistCaja.Ejecutar(AOwner: TComponent;
                                                  AConn: TUniConnection;
                                                  const AEmpresa: string;
                                                  const AAlmacen: string;
                                                  const ACaja: string);
begin
  ValidarDependenciaCaja(nil, 'contexto del histórico de arqueos');
end;

class procedure TfrmModalArqueosHistCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ADependencias: TDependenciasArqueosHistoricosCaja;
  const AEmpresa: string;
  const AAlmacen: string;
  const ACaja: string);
var
  Frm: TfrmModalArqueosHistCaja;
begin
  ADependencias.Validar;
  Frm := TfrmModalArqueosHistCaja.Create(AOwner);
  try
    AsociarVentanaPropietaria(Frm, AOwner);
    Frm.FConn    := AConn;
    Frm.FRepositorioPersistencia := ADependencias.Informes;
    Frm.FRepositorioArqueoCaja := ADependencias.Arqueo;
    Frm.FRepositorioArqueoTicket := ADependencias.Ticket;
    Frm.ComponerDependencias;
    Frm.FEmpresa := AEmpresa;
    Frm.FAlmacen := AAlmacen;
    Frm.FCaja    := ACaja;
    Frm.ShowModal;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmModalArqueosHistCaja.ComponerDependencias;
var
  Dependencias: TDependenciasArqueosHistoricosCaja;
begin
  Dependencias.Informes := FRepositorioPersistencia;
  Dependencias.Arqueo := FRepositorioArqueoCaja;
  Dependencias.Ticket := FRepositorioArqueoTicket;
  Dependencias.Validar;
end;

procedure TfrmModalArqueosHistCaja.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  AplicarEstiloCaja;
  colFase.OnGetDisplayText := colFaseGetDisplayText;
end;

procedure TfrmModalArqueosHistCaja.colFaseGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if SameText(Trim(AText), 'CERRADO') then
    AText := SEstadoArqueoCerrado;
end;

// Mismo aspecto que el resto de pantallas de caja. Las teclas van en los
// botones, así que sobra la línea de ayuda; tampoco se agrupa por columnas.
procedure TfrmModalArqueosHistCaja.AplicarEstiloCaja;
var
  Estilo: TEstiloCaja;
  Boton: TcxButton;
begin
  Estilo := TEstiloCaja.Create(Self);
  EstilarEtiquetaCaja(lblTitulo, 18, True);
  lblAyuda.Visible := False;
  lblTitulo.Parent.Height := EscalarCaja(Self, 44);
  dbtvArqueos.OptionsView.GroupByBox := False;
  Estilo.EstilarRejilla(dbtvArqueos);
  for Boton in TArray<TcxButton>.Create(btnDupTicket, btnDupCierre,
    btnSalir) do
    Estilo.EstilarBoton(Boton, '', nil, 15);
  ColocarBotoneraDerechaCaja(btnSalir.Parent,
    [btnDupTicket, btnDupCierre, btnSalir]);
end;

procedure TfrmModalArqueosHistCaja.FormDestroy(Sender: TObject);
begin
  dsArqueos.DataSet := nil;
  FDatos := nil;
  FResultado := nil;
  FRepositorioArqueoTicket := nil;
  FRepositorioArqueoCaja := nil;
  FRepositorioPersistencia := nil;
  inherited;
end;

procedure TfrmModalArqueosHistCaja.FormShow(Sender: TObject);
begin
  inherited;
  lblTitulo.Caption := Format(STituloHistoricoArqueosCaja, [FCaja]);
  CargarArqueos;
  // Ajustar el ancho de las columnas al contenido al presentar la pantalla.
  dbtvArqueos.ApplyBestFit;
end;

procedure TfrmModalArqueosHistCaja.CargarArqueos;
begin
  if (FConn <> nil) and FConn.Connected then
  begin
    dsArqueos.DataSet := nil;
    FDatos := nil;
    FResultado := FRepositorioPersistencia.ConsultarArqueosHistorico(
      FEmpresa,
      FAlmacen,
      FCaja);
    FDatos := FResultado.DataSet;
    dsArqueos.DataSet := FDatos;
  end;
end;

function TfrmModalArqueosHistCaja.ArqueoSeleccionado: string;
begin
  Result := '';
  if Assigned(FDatos) and FDatos.Active and (not FDatos.IsEmpty) then
  begin
    Result := FDatos.FieldByName('CODIGO_ARQ').AsString;
  end;
end;

procedure TfrmModalArqueosHistCaja.btnDupTicketClick(Sender: TObject);
var
  sCod: string;
begin
  sCod := ArqueoSeleccionado;
  if sCod = '' then
  begin
    ShowMessage_fza(SErrorArqueoCajaNoSeleccionado);
  end
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      TArqueoTicket.ImprimirDesdeHistorico(
        PreviewTicket,
        FRepositorioArqueoCaja,
        FRepositorioArqueoTicket,
        ParametrosCaja,
        FEmpresa,
        FAlmacen,
        FCaja,
        sCod,
        ParametrosCaja.ImpresoraCaja);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalArqueosHistCaja.btnDupCierreClick(Sender: TObject);
var
  sCod: string;
begin
  sCod := ArqueoSeleccionado;
  if sCod = '' then
  begin
    ShowMessage_fza(SErrorArqueoCajaNoSeleccionado);
  end
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      TArqueoTicket.ImprimirCierreDesdeHistorico(
        PreviewTicket,
        FRepositorioArqueoTicket,
        ContextoSesion,
        FEmpresa,
        FAlmacen,
        FCaja,
        sCod,
        ParametrosCaja.ImpresoraCaja);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalArqueosHistCaja.dbtvArqueosDblClick(Sender: TObject);
begin
  // Doble clic = duplicado del cierre (el documento más completo).
  btnDupCierreClick(Sender);
end;

procedure TfrmModalArqueosHistCaja.btnSalirClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueosHistCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2:
      begin
        Key := 0;
        btnDupTicketClick(Self);
      end;
    VK_F3:
      begin
        Key := 0;
        btnDupCierreClick(Self);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        Close;
      end;
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalArqueosHistCaja);
end.

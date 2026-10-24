{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenAlbaran                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.1.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de "Crear albaran desde pedido" (ventas). Permite elegir el         }
{    almacen del que sale la mercancia y, opcionalmente, anadir las lineas     }
{    a un albaran que ya existe en lugar de crear uno nuevo.                   }
{                                                                              }
{    El llamador (inMtoPedidos) calcula el almacen comun de las lineas que     }
{    se van a entregar y lo pasa como defecto:                                 }
{      * Si todas las lineas comparten almacen, el combo aparece ya con        }
{        ese almacen seleccionado (basta con Aceptar).                         }
{      * Si las lineas son de almacenes distintos (o sin almacen), el          }
{        combo aparece vacio y obliga a elegir uno.                            }
{                                                                              }
{    Modo "anadir a albaran existente": si el pedido ya tiene albaranes no     }
{    facturados, el usuario puede marcar la casilla y elegir uno de ellos      }
{    como destino. En ese caso las lineas se agregan a ese albaran (mismo      }
{    cliente y empresa por construccion, ya que proceden del mismo pedido)     }
{    y el almacen elegido solo afecta a las lineas nuevas.                     }
{                                                                              }
{    Devuelve el almacen elegido y, si procede, el albaran destino; la         }
{    generacion la hace UniDataPedidos.CrearAlbaranDesdePedido.                }
{******************************************************************************}
unit inMtoModalSelAlmacenAlbaran;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoFrmBase,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxButtons, cxContainer, cxEdit, cxLabel, cxTextEdit,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxCheckBox,
  System.Actions, Vcl.ActnList,
  Data.DB, inLibSeleccionAlmacenPersistenciaIntf;

type
  TSelAlmacenAlbaranResult = record
    Aceptado      : Boolean;
    CodigoAlmacen : string;
    // Modo "anadir a albaran existente": cuando EsExistente es True, las
    // lineas se agregan al albaran (NumeroAlb / SerieAlb) en lugar de
    // crear uno nuevo.
    EsExistente   : Boolean;
    NumeroAlb     : string;
    SerieAlb      : string;
  end;

  TfrmModalSelAlmacenAlbaran = class(TfrmBase)
    pnlButton:          TPanel;
    btnCancelar:        TcxButton;
    btnAceptar:         TcxButton;
    pnlBody:            TPanel;
    lblPedido:          TLabel;
    lblAlmacen:         TcxLabel;
    cbbAlmacen:         TcxLookupComboBox;
    dsAlmacenes:        TDataSource;
    ActionList1:        TActionList;
    actAceptar:         TAction;
    chkAnadirExistente: TcxCheckBox;
    lblAlbaran:         TcxLabel;
    cbbAlbaran:         TcxLookupComboBox;
    dsAlbaranesPed:     TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure chkAnadirExistenteClick(Sender: TObject);
  private
    FCodigoEmpresa  : string;
    FSeriePed       : string;
    FNumPed         : string;
    FAlmacenDefecto : string;
    FCodigoAlmacen  : string;
    FAceptado       : Boolean;
    FEsExistente    : Boolean;
    FNumeroAlb      : string;
    FSerieAlb       : string;
    FRepositorio: IRepositorioSeleccionAlmacen;
    FConsultaAlmacenes: IConsultaSeleccionAlmacen;
    FConsultaAlbaranes: IConsultaSeleccionAlmacen;
    FAlmacenes: TDataSet;
    FAlbaranes: TDataSet;
    procedure CargarAlmacenes;
    procedure CargarAlbaranesPedido;
    procedure ActualizarEstadoControles;
  public
    class function Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoEmpresa,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMsgVentas,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

{$R *.dfm}

class function TfrmModalSelAlmacenAlbaran.Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoEmpresa,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
var
  frm: TfrmModalSelAlmacenAlbaran;
begin
  Result.Aceptado      := False;
  Result.CodigoAlmacen := '';
  Result.EsExistente   := False;
  Result.NumeroAlb     := '';
  Result.SerieAlb      := '';
  frm := TfrmModalSelAlmacenAlbaran.Create(AOwner);
  try
    frm.FCodigoEmpresa  := ACodigoEmpresa;
    frm.FSeriePed       := ASeriePed;
    frm.FNumPed         := ANumPed;
    frm.FAlmacenDefecto := ACodigoAlmacenDefecto;
    frm.ShowModal;
    Result.Aceptado      := frm.FAceptado;
    Result.CodigoAlmacen := frm.FCodigoAlmacen;
    Result.EsExistente   := frm.FEsExistente;
    Result.NumeroAlb     := frm.FNumeroAlb;
    Result.SerieAlb      := frm.FSerieAlb;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSelAlmacenAlbaran.FormCreate(Sender: TObject);
var
  oContexto: TContextoSeleccionAlmacenVentasPantalla;
begin
  inherited;
  Self.Position  := poScreenCenter;
  cbbAlmacen.OnEnter := DesactivarEnterAsTabTemporal;
  cbbAlmacen.OnExit  := RestaurarEnterAsTabTemporal;
  cbbAlmacen.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  cbbAlmacen.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  cbbAlmacen.Properties.PostPopupValueOnTab := True;
  FCodigoEmpresa := '';
  FAceptado      := False;
  FCodigoAlmacen := '';
  FEsExistente   := False;
  FNumeroAlb     := '';
  FSerieAlb      := '';
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FRepositorio := oContexto.Repositorio;
end;

procedure TfrmModalSelAlmacenAlbaran.FormShow(Sender: TObject);
begin
  inherited;
  dsAlmacenes.DataSet := nil;
  dsAlbaranesPed.DataSet := nil;
  FAlmacenes := nil;
  FAlbaranes := nil;
  FConsultaAlmacenes := nil;
  FConsultaAlbaranes := nil;
  lblPedido.Caption := Format(SCaptionCrearAlbaranDesdePedido,
    [FormatearDocumento(CrearFormatoDocumentoLecturas(
      ConexionPrincipal).LeerFormatoEmpresa(FCodigoEmpresa),
      FSeriePed, FNumPed)]);
  CargarAlmacenes;
  CargarAlbaranesPedido;
  // Defecto: almacen comun de las lineas a entregar. Si viene vacio
  // (lineas de almacenes distintos o sin almacen) el combo queda en
  // blanco y obliga a elegir.
  if Trim(FAlmacenDefecto) <> '' then
    cbbAlmacen.EditValue := FAlmacenDefecto
  else
    cbbAlmacen.EditValue := Null;
  // Por defecto se crea un albaran nuevo; el usuario decide si lo anade
  // a uno existente.
  chkAnadirExistente.Checked := False;
  ActualizarEstadoControles;
  if cbbAlmacen.CanFocus then
    cbbAlmacen.SetFocus;
end;

procedure TfrmModalSelAlmacenAlbaran.FormClose(Sender: TObject;
                                               var Action: TCloseAction);
begin
  inherited;
  // caHide: Ejecutar lee los campos tras ShowModal y libera con
  // FreeAndNil. caFree dejaria un puntero colgante (double-free).
  Action := caHide;
end;

procedure TfrmModalSelAlmacenAlbaran.CargarAlmacenes;
begin
  FConsultaAlmacenes := FRepositorio.ConsultarAlmacenes;
  FAlmacenes := FConsultaAlmacenes.DataSet;
  dsAlmacenes.DataSet := FAlmacenes;
  cbbAlmacen.Properties.ListSource := dsAlmacenes;
end;

procedure TfrmModalSelAlmacenAlbaran.CargarAlbaranesPedido;
begin
  FConsultaAlbaranes := FRepositorio.ConsultarAlbaranesVenta(
    FNumPed,
    FSeriePed);
  FAlbaranes := FConsultaAlbaranes.DataSet;
  dsAlbaranesPed.DataSet := FAlbaranes;
  cbbAlbaran.Properties.ListSource := dsAlbaranesPed;
end;

procedure TfrmModalSelAlmacenAlbaran.ActualizarEstadoControles;
var
  bHayAlbaranes: Boolean;
begin
  // Solo se puede anadir a un albaran existente si el pedido tiene
  // alguno no facturado.
  bHayAlbaranes := Assigned(FAlbaranes) and
                   FAlbaranes.Active and
                   (FAlbaranes.RecordCount > 0);
  chkAnadirExistente.Enabled := bHayAlbaranes;
  if not bHayAlbaranes then
    chkAnadirExistente.Checked := False;
  cbbAlbaran.Enabled := chkAnadirExistente.Checked;
  lblAlbaran.Enabled := chkAnadirExistente.Checked;
  if not chkAnadirExistente.Checked then
    cbbAlbaran.EditValue := Null;
end;

procedure TfrmModalSelAlmacenAlbaran.chkAnadirExistenteClick(Sender: TObject);
begin
  inherited;
  ActualizarEstadoControles;
  if chkAnadirExistente.Checked and cbbAlbaran.CanFocus then
    cbbAlbaran.SetFocus;
end;

procedure TfrmModalSelAlmacenAlbaran.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenAlbaran.btnAceptarClick(Sender: TObject);
var
  vAlm: Variant;
  vAlb: Variant;
  sNumAlb: string;
begin
  inherited;
  vAlm := cbbAlmacen.EditValue;
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) or (Trim(VarToStr(vAlm)) = '') then
  begin
    // El almacen es obligatorio: las lineas nuevas necesitan saber de
    // que almacen sale la mercancia (genera los movimientos de salida).
    MessageDlg_fza(SErrorAlmacenAlbaranNoSeleccionado,
               mtInformation, [mbOk], 0);
    if cbbAlmacen.CanFocus then
      cbbAlmacen.SetFocus;
  end
  else if chkAnadirExistente.Checked then
  begin
    // Modo anadir a un albaran existente: hay que elegir el destino.
    vAlb := cbbAlbaran.EditValue;
    if VarIsNull(vAlb) or VarIsEmpty(vAlb) or (Trim(VarToStr(vAlb)) = '') then
    begin
      MessageDlg_fza(SErrorAlbaranDestinoNoSeleccionado,
                 mtInformation, [mbOk], 0);
      if cbbAlbaran.CanFocus then
        cbbAlbaran.SetFocus;
    end
    else
    begin
      sNumAlb := VarToStr(vAlb);
      // La serie real se lee de la fila localizada; los albaranes de un
      // pedido comparten serie con el pedido, pero no lo damos por hecho.
      if FAlbaranes.Locate('NUMERO_ALB', sNumAlb, []) then
        FSerieAlb := FAlbaranes.FieldByName('SERIE_ALB').AsString
      else
        FSerieAlb := FSeriePed;
      FNumeroAlb     := sNumAlb;
      FEsExistente   := True;
      FCodigoAlmacen := VarToStr(vAlm);
      FAceptado      := True;
      ModalResult    := mrOk;
    end;
  end
  else
  begin
    // Modo clasico: crear un albaran nuevo.
    FEsExistente   := False;
    FNumeroAlb     := '';
    FSerieAlb      := '';
    FCodigoAlmacen := VarToStr(vAlm);
    FAceptado      := True;
    ModalResult    := mrOk;
  end;
end;

end.

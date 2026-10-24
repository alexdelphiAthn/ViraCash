{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSerieFechaFactura                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pide la serie de factura completa (por defecto la del almacén) y la       }
{    fecha del documento. Lo usa el botón Factura (F8) de la fase de           }
{    cobro de caja antes de grabar la venta como factura NORMAL.               }
{******************************************************************************}
unit inMtoModalSerieFechaFactura;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxCalendar, cxLabel,
  cxButtons, dxCore, cxDateUtils,
  inMtoFrmBase, inLibSerieFechaFacturaPersistenciaIntf;

type
  TSerieFechaFacturaResult = record
    Aceptado: Boolean;
    Serie:    string;
    Fecha:    TDateTime;
  end;

  TfrmModalSerieFechaFactura = class(TfrmBase)
    lblSerie:    TcxLabel;
    cbbSerie:    TcxLookupComboBox;
    lblFecha:    TcxLabel;
    dtFecha:     TcxDateEdit;
    pnlButton:   TPanel;
    btnAceptar:  TcxButton;
    btnCancelar: TcxButton;
    dsSeries:    TDataSource;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FResultado: TSerieFechaFacturaResult;
    FRepositorio: IRepositorioSerieFechaFactura;
    FConsultaSeries: IConsultaSeriesFactura;
    FSeries: TDataSet;
  public
    class function Ejecutar(AOwner: TComponent;
                            const AEmpresa, AAlmacen: string)
                            : TSerieFechaFacturaResult;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgComun,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

{$R *.dfm}

class function TfrmModalSerieFechaFactura.Ejecutar(AOwner: TComponent;
                                                   const AEmpresa,
                                                   AAlmacen: string)
                                                   : TSerieFechaFacturaResult;
var
  frm:    TfrmModalSerieFechaFactura;
  oContexto: TContextoSerieFechaFacturaVentasPantalla;
  sSerie: string;
begin
  frm := TfrmModalSerieFechaFactura.Create(AOwner);
  try
    CrearContextoVentasPantalla(
      frm.ConexionPrincipal,
      oContexto);
    frm.FRepositorio := oContexto.Repositorio;
    frm.FConsultaSeries := frm.FRepositorio.ConsultarSeries(AEmpresa);
    frm.FSeries := frm.FConsultaSeries.DataSet;
    frm.dsSeries.DataSet := frm.FSeries;
    // Serie por defecto: la ligada al almacén; si no tiene, la primera
    // serie FC activa (DEFAULT_CON primero)
    sSerie := frm.FRepositorio.ObtenerSerieAlmacen(AEmpresa, AAlmacen);
    if sSerie = '' then
    begin
      sSerie := frm.FSeries.FieldByName('SERIE_CON').AsString;
    end;
    frm.cbbSerie.EditValue := sSerie;
    frm.dtFecha.Date := Trunc(Now);
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    frm.dsSeries.DataSet := nil;
    frm.FSeries := nil;
    frm.FConsultaSeries := nil;
    frm.FRepositorio := nil;
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSerieFechaFactura.btnCancelarClick(Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalSerieFechaFactura.btnAceptarClick(Sender: TObject);
begin
  if Trim(VarToStr(cbbSerie.EditValue)) = '' then
    ShowMessage_fza(SErrorSerieBorradorNoSeleccionada)
  else if dtFecha.Date <= 0 then
    ShowMessage_fza(SErrorFechaBorradorNoIndicada)
  else
  begin
    FResultado.Aceptado := True;
    FResultado.Serie    := VarToStr(cbbSerie.EditValue);
    FResultado.Fecha    := dtFecha.Date;
    Close;
  end;
end;

end.

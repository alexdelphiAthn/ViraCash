{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoDevolucionesCompraAbonoVcl                               }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       11/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-925: pide serie, numero y fecha del abono de una devolucion a   }
{    proveedor y la factura de compra que rectifica, y crea el borrador.      }
{    Solo conoce la cabecera de la devolucion y el puerto de persistencia.    }
{******************************************************************************}
unit inMtoDevolucionesCompraAbonoVcl;

interface

uses
  System.Classes, Data.DB, Vcl.Forms, Uni,
  inLibAbonoDevolucionCompraPersistenciaIntf;

// True si se ha creado el borrador; ASerie y ANumero lo identifican.
function GenerarAbonoDevolucionCompra(
  AOwner: TCustomForm;
  ACabecera: TDataSet;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioAbonoDevolucionCompra;
  const AUsuario: string;
  out ASerie, ANumero: string): Boolean;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxDropDownEdit, cxButtons, cxLabel,
  inLibMensajesVcl, inLibMsgCompras, inLibMsgOpcionesDocumento,
  inLibOpcionesDocumentoIntf, inMtoModalOpcionesDocumento,
  UniDataOpcionesDocumentoRepositorio;

const
  // TIPO_DOC de las facturas de proveedor en contadores y series.
  TIPO_DOC_FACTURA_COMPRA = 'FP';

function Campo(ACabecera: TDataSet; const ANombre: string): string;
begin
  Result := Trim(ACabecera.FieldByName(ANombre).AsString);
end;

function ValidarDevolucion(ACabecera: TDataSet): Boolean;
var
  sSerie: string;
  sNumero: string;
begin
  Result := False;
  if (ACabecera = nil) or (not ACabecera.Active) or ACabecera.IsEmpty or
     (ACabecera.State <> dsBrowse) then
    ShowMessage_fza(SErrorAbonoDevolucionSinGrabar)
  else
  begin
    sSerie := Campo(ACabecera, 'SERIE_DEVC');
    sNumero := Campo(ACabecera, 'NUMERO_DEVC');
    if Campo(ACabecera, 'NUMERO_FAC_DEVC') <> '' then
      ShowMessage_fza(Format(SErrorAbonoDevolucionYaGenerado,
        [sSerie, sNumero, Campo(ACabecera, 'SERIE_FAC_DEVC'),
         Campo(ACabecera, 'NUMERO_FAC_DEVC')]))
    else if SameText(Campo(ACabecera, 'ESTADO_DEVC'), 'CANCELADO') then
      ShowMessage_fza(Format(SErrorAbonoDevolucionCancelada,
        [sSerie, sNumero]))
    else
      Result := True;
  end;
end;

function SolicitarOpciones(AOwner: TCustomForm; ACabecera: TDataSet;
  AConexion: TUniConnection; out AOpciones: TOpcionesDocumento): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := TIPO_DOC_FACTURA_COMPRA;
  oTipo.Nombre := SNombreAbonoDevolucionCompra;
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := STituloAbonoDevolucionCompra;
  oConfig.Tipos := [oTipo];
  oConfig.Propuesta := Default(TOpcionesDocumento);
  oConfig.Propuesta.Empresa := Campo(ACabecera, 'CODIGO_EMP_DEVC');
  oConfig.Propuesta.Almacen := Campo(ACabecera, 'CODIGO_ALM_DEVC');
  oConfig.Propuesta.Tipo := TIPO_DOC_FACTURA_COMPRA;
  oConfig.Propuesta.Fecha := Date;
  oConfig.Propuesta.FormaPago := Campo(ACabecera, 'FORMA_PAGO_DEVC');
  // La empresa es la de la devolucion: sus datos fiscales se copian.
  oConfig.Visibles := [codEmpresa, codAlmacen, codSerie, codNumero,
    codFecha, codFormaPago];
  oConfig.Fijos := [codEmpresa];
  oConfig.PermiteNumeroManual := True;
  Result := TfrmModalOpcionesDocumento.Solicitar(AOwner,
    CrearLectorOpcionesDocumentoUniDAC(AConexion), oConfig, AOpciones);
end;

function TextoFactura(const AFactura: TFacturaOrigenAbonoCompra): string;
begin
  Result := AFactura.Serie + '/' + AFactura.Numero + '  ' +
    FormatDateTime('dd/mm/yyyy', AFactura.Fecha) + '  ' +
    FormatFloat('#,##0.00', AFactura.Total);
  if AFactura.ReferenciaProveedor <> '' then
    Result := Result + '  (' + AFactura.ReferenciaProveedor + ')';
end;

// Desplegable con las facturas del proveedor; la primera opcion es no
// enlazar ninguna. False si se cancela.
function ElegirFacturaOrigen(AOwner: TCustomForm;
  const AFacturas: TFacturasOrigenAbonoCompra;
  out ASerie, ANumero: string): Boolean;
var
  oDialogo: TForm;
  oEtiqueta: TcxLabel;
  oCombo: TcxComboBox;
  oPanel: TPanel;
  oAceptar: TcxButton;
  oCancelar: TcxButton;
  oFactura: TFacturaOrigenAbonoCompra;
begin
  ASerie := '';
  ANumero := '';
  oDialogo := TForm.Create(AOwner);
  try
    oDialogo.Caption := STituloFacturaOrigenAbonoCompra;
    oDialogo.BorderStyle := bsDialog;
    oDialogo.Position := poOwnerFormCenter;
    oDialogo.ClientWidth := 560;
    oDialogo.ClientHeight := 150;
    oEtiqueta := TcxLabel.Create(oDialogo);
    oEtiqueta.Parent := oDialogo;
    oEtiqueta.SetBounds(16, 14, 528, 24);
    oEtiqueta.Caption := SEtiquetaFacturaOrigenAbonoCompra;
    oEtiqueta.Transparent := True;
    oCombo := TcxComboBox.Create(oDialogo);
    oCombo.Parent := oDialogo;
    oCombo.SetBounds(16, 44, 528, 24);
    oCombo.Properties.DropDownListStyle := lsFixedList;
    oCombo.Properties.Items.Add(SSinFacturaOrigenAbonoCompra);
    for oFactura in AFacturas do
      oCombo.Properties.Items.Add(TextoFactura(oFactura));
    oCombo.ItemIndex := 0;
    oPanel := TPanel.Create(oDialogo);
    oPanel.Parent := oDialogo;
    oPanel.Align := alBottom;
    oPanel.Height := 48;
    oPanel.BevelOuter := bvNone;
    oCancelar := TcxButton.Create(oDialogo);
    oCancelar.Parent := oPanel;
    oCancelar.SetBounds(444, 10, 100, 28);
    oCancelar.Caption := SCaptionCancelarOpcionesDocumento;
    oCancelar.ModalResult := mrCancel;
    oCancelar.Cancel := True;
    oAceptar := TcxButton.Create(oDialogo);
    oAceptar.Parent := oPanel;
    oAceptar.SetBounds(336, 10, 100, 28);
    oAceptar.Caption := SCaptionAceptarOpcionesDocumento;
    oAceptar.ModalResult := mrOk;
    oAceptar.Default := True;
    Result := oDialogo.ShowModal = mrOk;
    if Result and (oCombo.ItemIndex > 0) then
    begin
      ASerie := AFacturas[oCombo.ItemIndex - 1].Serie;
      ANumero := AFacturas[oCombo.ItemIndex - 1].Numero;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

function GenerarAbonoDevolucionCompra(
  AOwner: TCustomForm;
  ACabecera: TDataSet;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioAbonoDevolucionCompra;
  const AUsuario: string;
  out ASerie, ANumero: string): Boolean;
var
  oOpciones: TOpcionesDocumento;
  oSolicitud: TSolicitudAbonoDevolucionCompra;
begin
  ASerie := '';
  ANumero := '';
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  Result := ValidarDevolucion(ACabecera) and
    SolicitarOpciones(AOwner, ACabecera, AConexion, oOpciones);
  if Result then
  begin
    oSolicitud := Default(TSolicitudAbonoDevolucionCompra);
    Result := ElegirFacturaOrigen(AOwner,
      ARepositorio.ListarFacturasOrigen(
        Campo(ACabecera, 'CODIGO_EMP_DEVC'),
        Campo(ACabecera, 'CODIGO_PRV_DEVC')),
      oSolicitud.SerieOrigen, oSolicitud.NumeroOrigen);
  end;
  if Result then
  begin
    oSolicitud.SerieDevolucion := Campo(ACabecera, 'SERIE_DEVC');
    oSolicitud.NumeroDevolucion := Campo(ACabecera, 'NUMERO_DEVC');
    oSolicitud.Serie := oOpciones.Serie;
    oSolicitud.NumeroManual := oOpciones.Numero;
    oSolicitud.Fecha := oOpciones.Fecha;
    oSolicitud.FormaPago := oOpciones.FormaPago;
    oSolicitud.Almacen := oOpciones.Almacen;
    oSolicitud.Usuario := AUsuario;
    Screen.Cursor := crHourGlass;
    try
      ARepositorio.GenerarAbono(oSolicitud, ASerie, ANumero);
    finally
      Screen.Cursor := crDefault;
    end;
    Result := ANumero <> '';
    if Result then
      ShowMessage_fza(Format(SInfoAbonoDevolucionGenerado,
        [ASerie, ANumero]))
    else
      ShowMessage_fza(SErrorAbonoDevolucionNoGenerado);
  end;
end;

end.

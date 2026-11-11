{******************************************************************************}
{                                                                              }
{  Coordinacion VCL de efectos y pagos de facturas de compra.                  }
{                                                                              }
{******************************************************************************}
unit inMtoFacturasCompraPagosVcl;

interface

uses
  System.Classes, Data.DB,
  inLibSeleccionBancoEmpresaPersistenciaIntf, UniDataFacturasCompra;

type
  TObtenerBancoDefectoProveedor = reference to function(
    const ACodigoProveedor: string): string;
  TGenerarEfectosCompra = reference to function(
    const ACodigoBancoEmpresa, AIban: string): Integer;
  TRegistrarPagoEfectoCompra = reference to function(
    ANumeroEfecto: Integer;
    AFecha: TDateTime;
    AImporte: Double;
    const ATipo, AReferencia: string): Integer;

procedure GenerarEfectosFacturaCompraVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const ARepositorio: IRepositorioSeleccionBancoEmpresa;
  const AObtenerBancoDefecto: TObtenerBancoDefectoProveedor;
  const AGenerarEfectos: TGenerarEfectosCompra);
procedure RegistrarPagoFacturaCompraVcl(
  AEfectos: TDataSet;
  const ARegistrarPago: TRegistrarPagoEfectoCompra;
  const AMensajeConciliado, AMensajeError: string);

procedure ImprimirReciboPagoCompraVcl(AOwner: TComponent;
  ADataModule: TdmFacturasCompra);

implementation

uses
  inLibMensajesVcl, UniDataComprasAgricultores,
  System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inLibMsgCompras,
  inMtoModalRegistrarPago, inMtoModalSeleccionarBanco, inMtoModalImpRecFac;


procedure GenerarEfectosFacturaCompraVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const ARepositorio: IRepositorioSeleccionBancoEmpresa;
  const AObtenerBancoDefecto: TObtenerBancoDefectoProveedor;
  const AGenerarEfectos: TGenerarEfectosCompra);
var
  Resultado: Integer;
  Empresa: string;
  Proveedor: string;
  BancoPreferido: string;
  Banco: TSeleccionBancoResult;
begin
  if Assigned(ACabecera) and
     not SameText(ACabecera.FieldByName('ESTADO_FACC').AsString,
       'CERRADA') then
    ShowMessage_fza(SAvisoGenerarEfectosFacturaAbierta)
  else if Assigned(ACabecera) then
  begin
    Empresa := ACabecera.FieldByName('CODIGO_EMP_FACC').AsString;
    Proveedor := ACabecera.FieldByName(
      CampoEmisorCompra(ACabecera)).AsString;
    BancoPreferido := AObtenerBancoDefecto(Proveedor);
    Banco := TfrmModalSeleccionarBanco.Ejecutar(
      AOwner,
      Empresa,
      ubePago,
      ARepositorio,
      BancoPreferido);
    if not Banco.Aceptado then
      ShowMessage_fza(SInfoGeneracionEfectosPagoCancelada)
    else
    begin
      Resultado := AGenerarEfectos(Banco.CodigoEmpban, Banco.Iban);
      if Resultado > 0 then
        ShowMessage_fza(Format(SInfoEfectosPagoGenerados, [Resultado]))
      else if Resultado = -2 then
        ShowMessage_fza(SAvisoGenerarEfectosFacturaAbierta)
      else if Resultado = 0 then
        ShowMessage_fza(SAvisoEfectosPagoNoGenerados)
      else
        ShowMessage_fza(SErrorGenerarEfectosPagoSinBorrador);
    end;
  end;
end;

procedure RegistrarPagoFacturaCompraVcl(
  AEfectos: TDataSet;
  const ARegistrarPago: TRegistrarPagoEfectoCompra;
  const AMensajeConciliado, AMensajeError: string);
var
  Formulario: TfrmModalRegistrarPago;
  NumeroEfecto: Integer;
  Resultado: Integer;
  Pendiente: Double;
begin
  if Assigned(AEfectos) and AEfectos.Active and
     (not AEfectos.IsEmpty) then
  begin
    NumeroEfecto := AEfectos.FieldByName('NUMERO_EFEC').AsInteger;
    Pendiente := AEfectos.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    if Pendiente < 0 then
      ShowMessage_fza(SAvisoPagoEfectoNegativo)
    else
    begin
    Formulario := TfrmModalRegistrarPago.Create(nil);
    try
      Formulario.SetDatos(
        Format(
          STituloRegistrarPagoEfectoFacturaCompra,
          [NumeroEfecto,
           FormatDateTime(
             'dd/mm/yyyy',
             AEfectos.FieldByName('FECHA_VENCIMIENTO_EFEC').AsDateTime),
           Pendiente]),
        Pendiente);
      if Formulario.ShowModal = mrOk then
      begin
        Resultado := ARegistrarPago(
          NumeroEfecto,
          Formulario.Fecha,
          Formulario.Importe,
          Formulario.Tipo,
          Formulario.Referencia);
        if Resultado > 0 then
          ShowMessage_fza(AMensajeConciliado)
        else
          ShowMessage_fza(AMensajeError);
      end;
    finally
      Formulario.Free;
    end;
    end;
  end
  else
    ShowMessage_fza(SErrorEfectoCompraNoSeleccionado);
end;

procedure ImprimirReciboPagoCompraVcl(AOwner: TComponent;
  ADataModule: TdmFacturasCompra);
var
  oFormulario: TfrmPrintRecFac;
  oEfectos: TDataSet;
begin
  oEfectos := ADataModule.unqryEfectos;
  if (not oEfectos.Active) or oEfectos.IsEmpty then
    ShowMessage_fza(SErrorEfectoCompraNoSeleccionado)
  else if oEfectos.FieldByName('IMPORTE_PAGADO_EFEC').AsCurrency <= 0 then
    ShowMessage_fza(SRegistrarPagoAntesDeRecibo)
  else
  begin
    oFormulario := TfrmPrintRecFac.Create(AOwner);
    try
      oFormulario.edtSerie.Text :=
        ADataModule.unqryTablaG.FieldByName('SERIE_FACC').AsString;
      oFormulario.edtNroFac.Text :=
        ADataModule.unqryTablaG.FieldByName('NUMERO_FACC').AsString;
      oFormulario.PrepararEfectosCompra(
        ADataModule.unqryTablaG.Connection,
        oEfectos.FieldByName('NUMERO_EFEC').AsString);
      oFormulario.ShowModal;
    finally
      FreeAndNil(oFormulario);
    end;
  end;
end;

end.

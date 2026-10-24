{******************************************************************************}
{                                                                              }
{  Coordinacion VCL de efectos y pagos de facturas de compra.                  }
{                                                                              }
{******************************************************************************}
unit inMtoFacturasCompraPagosVcl;

interface

uses
  System.Classes, Data.DB,
  inLibSeleccionBancoEmpresaPersistenciaIntf;

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

implementation

uses
  inLibMensajesVcl,
  System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inLibMsgCompras,
  inMtoModalRegistrarPago, inMtoModalSeleccionarBanco;

resourcestring
  STituloRegistrarPagoEfectoFacturaCompra =
    'Efecto %d - vto %s - pendiente %.2f';

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
  if Assigned(ACabecera) then
  begin
    Empresa := ACabecera.FieldByName('CODIGO_EMP_FACC').AsString;
    Proveedor := ACabecera.FieldByName('CODIGO_PRV_FACC').AsString;
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
  end
  else
    ShowMessage_fza(SErrorEfectoCompraNoSeleccionado);
end;

end.

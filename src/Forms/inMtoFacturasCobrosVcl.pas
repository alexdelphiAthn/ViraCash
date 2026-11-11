{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasCobrosVcl                                       }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge interacción de cobros y delega sus operaciones en la aplicación.  }
{******************************************************************************}
unit inMtoFacturasCobrosVcl;

interface

uses
  System.Classes, Data.DB, Uni, UniDataFacturas,
  inLibFacturasAplicacionIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf;

type
  TAccionCobrosFacturaVcl = reference to procedure;
  TContextoCobrosFacturaVcl = record
    Aplicacion: IAplicacionCobrosFactura;
    Cabecera: TDataSet;
    Efectos: TDataSet;
    Recibos: TDataSet;
    DataModule: TdmFacturas;
    Conexion: TUniConnection;
    PropietarioVisual: TComponent;
    Usuario: string;
    SeleccionBanco: IRepositorioSeleccionBancoEmpresa;
    EsVentaMayor: Boolean;
    // CSV de NUMERO_EFV de los efectos seleccionados en la rejilla.
    EfectosSeleccionados: string;
    AsegurarEfectos: TAccionCobrosFacturaVcl;
    AsegurarRecibos: TAccionCobrosFacturaVcl;
    GenerarRecibos: TAccionCobrosFacturaVcl;
    RefrescarEfectos: TAccionCobrosFacturaVcl;
    MarcarReciboPagado: TAccionCobrosFacturaVcl;
    MarcarReciboPendiente: TAccionCobrosFacturaVcl;
    MarcarReciboDevuelto: TAccionCobrosFacturaVcl;
  end;
  TCoordinadorCobrosFacturaVcl = class
  private
    class function HayCabecera(
      const AContexto: TContextoCobrosFacturaVcl): Boolean; static;
    class procedure MostrarResultadoGeneracion(
      AResultado: Integer); static;
    class procedure ImprimirReciboEfectos(
      const AContexto: TContextoCobrosFacturaVcl); static;
  public
    class procedure Generar(
      const AContexto: TContextoCobrosFacturaVcl); static;
    class procedure MarcarCobrado(
      const AContexto: TContextoCobrosFacturaVcl); static;
    class procedure MarcarPendiente(
      const AContexto: TContextoCobrosFacturaVcl); static;
    class procedure MarcarDevuelto(
      const AContexto: TContextoCobrosFacturaVcl); static;
    class procedure ImprimirRecibo(
      const AContexto: TContextoCobrosFacturaVcl;
      APuedeImprimir: Boolean); static;
  end;

implementation

uses
  inLibMensajesVcl,
  Windows, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalRegistrarPago, inMtoModalSeleccionarBanco,
  inMtoModalImpRecFac,
  inLibFacturasCobrosPresentacion, inLibMsgFacturas, inLibMsgComun,
  inLibMsgVentas;

resourcestring
  STituloRegistrarCobroEfectoFactura =
    'Efecto %d - vto %s - pendiente %.2f';

class function TCoordinadorCobrosFacturaVcl.HayCabecera(
  const AContexto: TContextoCobrosFacturaVcl): Boolean;
begin
  Result := Assigned(AContexto.Cabecera) and
    AContexto.Cabecera.Active and
    (not AContexto.Cabecera.IsEmpty);
end;

class procedure TCoordinadorCobrosFacturaVcl.MostrarResultadoGeneracion(
  AResultado: Integer);
begin
  if AResultado = -2 then
    ShowMessage_fza(SAvisoAbonoVentaNoEmitido)
  else if AResultado > 0 then
    ShowMessage_fza(Format(SInfoEfectosCobroGenerados, [AResultado]))
  else if AResultado = 0 then
    ShowMessage_fza(SAvisoEfectosCobroNoGenerados)
  else
    ShowMessage_fza(SErrorGenerarEfectosCobroSinBorrador);
end;

class procedure TCoordinadorCobrosFacturaVcl.Generar(
  const AContexto: TContextoCobrosFacturaVcl);
var
  Configuracion: TConfiguracionCobrosFactura;
  Cobros: TDataSet;
  SeleccionBanco: TSeleccionBancoResult;
  Solicitud: TSolicitudGeneracionCobrosFactura;
  sCliente: string;
  sEmpresa: string;
  sMensaje: string;
  sPreferido: string;
begin
  if HayCabecera(AContexto) then
  begin
    if AContexto.Cabecera.State in [dsEdit, dsInsert] then
      AContexto.Cabecera.Post;
    if AContexto.EsVentaMayor then
    begin
      if Assigned(AContexto.AsegurarEfectos) then
        AContexto.AsegurarEfectos();
      Cobros := AContexto.Efectos;
    end
    else
    begin
      if Assigned(AContexto.AsegurarRecibos) then
        AContexto.AsegurarRecibos();
      Cobros := AContexto.Recibos;
    end;
    Configuracion := CrearConfiguracionCobrosFactura(
      AContexto.Cabecera.FieldByName('TIPO_FAC').AsString);
    sMensaje := Format(
      SPreguntaReemplazarCobros,
      [Configuracion.TextoPlural]);
    if (not Assigned(Cobros)) or
       (Cobros.RecordCount = 0) or
       (MessageBox_fza(
          PChar(sMensaje),
          PChar(STituloMensajeAdvertencia),
          MB_YESNO) = ID_YES) then
    begin
      sEmpresa := AContexto.Cabecera.FieldByName(
        'CODIGO_EMP_FAC').AsString;
      sCliente := AContexto.Cabecera.FieldByName(
        'CODIGO_CLI_FAC').AsString;
      sPreferido := AContexto.Aplicacion.BancoDefectoCliente(sCliente);
      SeleccionBanco := TfrmModalSeleccionarBanco.Ejecutar(
        AContexto.PropietarioVisual,
        sEmpresa,
        ubeCobro,
        AContexto.SeleccionBanco,
        sPreferido);
      if not SeleccionBanco.Aceptado then
      begin
        ShowMessage_fza(Format(
          SInfoGeneracionCobrosCancelada,
          [Configuracion.TextoPlural]));
      end
      else if AContexto.EsVentaMayor then
      begin
        Solicitud := Default(TSolicitudGeneracionCobrosFactura);
        Solicitud.Serie := AContexto.Cabecera.FieldByName(
          'SERIE_FAC').AsString;
        Solicitud.Numero := AContexto.Cabecera.FieldByName(
          'NUMERO_FAC').AsString;
        Solicitud.Usuario := AContexto.Usuario;
        Solicitud.CodigoBanco := SeleccionBanco.CodigoEmpban;
        Solicitud.Iban := SeleccionBanco.Iban;
        MostrarResultadoGeneracion(
          AContexto.Aplicacion.Generar(Solicitud));
        if Assigned(AContexto.RefrescarEfectos) then
          AContexto.RefrescarEfectos();
      end
      else
      begin
        if Assigned(AContexto.GenerarRecibos) then
          AContexto.GenerarRecibos();
        if SeleccionBanco.CodigoEmpban <> '' then
          AContexto.Aplicacion.EstamparBancoRecibos(
            AContexto.Cabecera.FieldByName('SERIE_FAC').AsString,
            AContexto.Cabecera.FieldByName('NUMERO_FAC').AsString,
            SeleccionBanco.CodigoEmpban,
            SeleccionBanco.Iban);
      end;
    end;
  end;
end;

class procedure TCoordinadorCobrosFacturaVcl.MarcarCobrado(
  const AContexto: TContextoCobrosFacturaVcl);
var
  Formulario: TfrmModalRegistrarPago;
  Solicitud: TSolicitudRegistroCobroFactura;
  fPendiente: Double;
  iEfecto: Integer;
begin
  if AContexto.EsVentaMayor then
  begin
    if Assigned(AContexto.AsegurarEfectos) then
      AContexto.AsegurarEfectos();
    if Assigned(AContexto.Efectos) and
       AContexto.Efectos.Active and
       (not AContexto.Efectos.IsEmpty) then
    begin
      iEfecto := AContexto.Efectos.FieldByName(
        'NUMERO_EFV').AsInteger;
      fPendiente := AContexto.Efectos.FieldByName(
        'IMPORTE_PENDIENTE_EFV').AsFloat;
      if Abs(fPendiente) <= 0.0001 then
      begin
        ShowMessage_fza(SErrorEfectoSinImportePendiente);
      end
      else
      begin
        Formulario := TfrmModalRegistrarPago.Create(nil);
        try
          Formulario.SetDatos(
            Format(
              STituloRegistrarCobroEfectoFactura,
              [iEfecto,
               FormatDateTime(
                 'dd/mm/yyyy',
                 AContexto.Efectos.FieldByName(
                   'FECHA_VENCIMIENTO_EFV').AsDateTime),
               fPendiente]),
            Abs(fPendiente));
          if fPendiente < 0 then
            Formulario.Caption := STituloDevolucionCliente;
          if Formulario.ShowModal = mrOk then
          begin
            Solicitud := Default(TSolicitudRegistroCobroFactura);
            Solicitud.Serie := AContexto.Cabecera.FieldByName(
              'SERIE_FAC').AsString;
            Solicitud.Numero := AContexto.Cabecera.FieldByName(
              'NUMERO_FAC').AsString;
            Solicitud.Usuario := AContexto.Usuario;
            Solicitud.NumeroEfecto := iEfecto;
            Solicitud.Fecha := Formulario.Fecha;
            Solicitud.Importe := Formulario.Importe;
            Solicitud.Tipo := Formulario.Tipo;
            Solicitud.Referencia := Formulario.Referencia;
            if AContexto.Aplicacion.Registrar(Solicitud) > 0 then
            begin
              if fPendiente < 0 then
                ShowMessage_fza(SInfoDevolucionClienteRegistrada)
              else
                ShowMessage_fza(SInfoEfectoConciliado);
            end
            else
              ShowMessage_fza(SErrorConciliarEfecto);
            if Assigned(AContexto.RefrescarEfectos) then
              AContexto.RefrescarEfectos();
          end;
        finally
          Formulario.Free;
        end;
      end;
    end
    else
      ShowMessage_fza(SErrorEfectoNoSeleccionado);
  end
  else if Assigned(AContexto.MarcarReciboPagado) then
    AContexto.MarcarReciboPagado();
end;

procedure CambiarEstadoEfecto(
  const AContexto: TContextoCobrosFacturaVcl;
  const AEstado, AMensajeCorrecto, AMensajeError: string);
var
  Solicitud: TSolicitudEstadoCobroFactura;
begin
  if Assigned(AContexto.AsegurarEfectos) then
    AContexto.AsegurarEfectos();
  if Assigned(AContexto.Efectos) and
     AContexto.Efectos.Active and
     (not AContexto.Efectos.IsEmpty) then
  begin
    Solicitud := Default(TSolicitudEstadoCobroFactura);
    Solicitud.Serie := AContexto.Efectos.FieldByName(
      'SERIE_FAC_EFV').AsString;
    Solicitud.Numero := AContexto.Efectos.FieldByName(
      'NUMERO_FAC_EFV').AsString;
    Solicitud.Usuario := AContexto.Usuario;
    Solicitud.NumeroEfecto := AContexto.Efectos.FieldByName(
      'NUMERO_EFV').AsInteger;
    Solicitud.Estado := AEstado;
    if AContexto.Aplicacion.CambiarEstado(Solicitud) then
      ShowMessage_fza(AMensajeCorrecto)
    else
      ShowMessage_fza(AMensajeError);
    if Assigned(AContexto.RefrescarEfectos) then
      AContexto.RefrescarEfectos();
  end
  else
    ShowMessage_fza(SErrorEfectoNoSeleccionado);
end;

class procedure TCoordinadorCobrosFacturaVcl.MarcarPendiente(
  const AContexto: TContextoCobrosFacturaVcl);
begin
  if AContexto.EsVentaMayor then
  begin
    CambiarEstadoEfecto(
      AContexto,
      'PENDIENTE',
      SInfoEfectoMarcadoPendiente,
      SErrorMarcarEfectoPendiente);
  end
  else if Assigned(AContexto.MarcarReciboPendiente) then
    AContexto.MarcarReciboPendiente();
end;

class procedure TCoordinadorCobrosFacturaVcl.MarcarDevuelto(
  const AContexto: TContextoCobrosFacturaVcl);
begin
  if AContexto.EsVentaMayor then
  begin
    CambiarEstadoEfecto(
      AContexto,
      'DEVUELTO',
      SInfoEfectoMarcadoDevuelto,
      SErrorMarcarEfectoDevuelto);
  end
  else if Assigned(AContexto.MarcarReciboDevuelto) then
    AContexto.MarcarReciboDevuelto();
end;

// FZ-ISSUE-102.14: recibo de los efectos de cobro de venta mayor con el
// informe de recibos; sin selección, el efecto actual.
class procedure TCoordinadorCobrosFacturaVcl.ImprimirReciboEfectos(
  const AContexto: TContextoCobrosFacturaVcl);
var
  Formulario: TfrmPrintRecFac;
  sEfectos: string;
begin
  if Assigned(AContexto.AsegurarEfectos) then
    AContexto.AsegurarEfectos();
  if (not HayCabecera(AContexto)) or
     (not Assigned(AContexto.Efectos)) or
     (not AContexto.Efectos.Active) or
     AContexto.Efectos.IsEmpty then
    ShowMessage_fza(SAvisoSinEfectosCobroImprimir)
  else
  begin
    sEfectos := AContexto.EfectosSeleccionados;
    if sEfectos = '' then
      sEfectos := AContexto.Efectos.FieldByName('NUMERO_EFV').AsString;
    Formulario := TfrmPrintRecFac.Create(Application);
    try
      Formulario.dmFac := AContexto.DataModule;
      Formulario.edtNroFac.Text := AContexto.Cabecera.FieldByName(
        'NUMERO_FAC').AsString;
      Formulario.edtSerie.Text := AContexto.Cabecera.FieldByName(
        'SERIE_FAC').AsString;
      Formulario.PrepararEfectosVenta(sEfectos);
      Formulario.ShowModal;
    finally
      Formulario.Free;
    end;
  end;
end;

class procedure TCoordinadorCobrosFacturaVcl.ImprimirRecibo(
  const AContexto: TContextoCobrosFacturaVcl;
  APuedeImprimir: Boolean);
var
  Formulario: TfrmPrintRecFac;
begin
  if not APuedeImprimir then
    Abort;
  if AContexto.EsVentaMayor then
    ImprimirReciboEfectos(AContexto)
  else
  begin
    Formulario := TfrmPrintRecFac.Create(Application);
    try
      Formulario.dmFac := AContexto.DataModule;
      Formulario.edtNroFac.Text := AContexto.Cabecera.FieldByName(
        'NUMERO_FAC').AsString;
      Formulario.edtSerie.Text := AContexto.Cabecera.FieldByName(
        'SERIE_FAC').AsString;
      Formulario.edtPlazoRecFac.Text := AContexto.Recibos.FieldByName(
        'NUMERO_PLAZO_REC').AsString;
      Formulario.ShowModal;
    finally
      Formulario.Free;
    end;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoImportacionPedidosVcl                                   }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge selección y presenta listado y progreso de pedidos externos.       }
{******************************************************************************}
unit inMtoImportacionPedidosVcl;

interface

uses
  cxGridTableView,
  cxLabel,
  inLibImportacionPedidosIntf;

type
  TContextoImportacionPedidosVcl = record
    Vista: TcxGridTableView;
    Estado: TcxLabel;
    Resumen: TResumenPedidosImportacion;
    CasoUso: ICasoUsoImportacionPedidos;
    BaseURL: string;
    ApiKey: string;
    IncluirImportados: Boolean;
    IndiceSeleccion: Integer;
    IndiceId: Integer;
    IndiceReferencia: Integer;
    IndiceFecha: Integer;
    IndiceCliente: Integer;
    IndiceTotal: Integer;
    IndiceEstado: Integer;
    IndiceImportado: Integer;
  end;
  TCoordinadorImportacionPedidosVcl = class
  private
    class procedure CargarGrid(
      const AContexto: TContextoImportacionPedidosVcl); static;
    class function RecogerIds(
      const AContexto: TContextoImportacionPedidosVcl
    ): TIdsPedidosImportacion; static;
    class procedure PresentarProgreso(
      const AContexto: TContextoImportacionPedidosVcl;
      const AIdPedido: string;
      AEstado: TEstadoImportacionPedido;
      const AError: string); static;
  public
    class procedure Conectar(
      const AContexto: TContextoImportacionPedidosVcl); static;
    class procedure Importar(
      const AContexto: TContextoImportacionPedidosVcl); static;
  end;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  System.Variants,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  inLibMsgIntegraciones,
  inLibMsgVentas;

class procedure TCoordinadorImportacionPedidosVcl.CargarGrid(
  const AContexto: TContextoImportacionPedidosVcl);
var
  i: Integer;
begin
  AContexto.Vista.DataController.RecordCount := 0;
  AContexto.Vista.DataController.RecordCount := AContexto.Resumen.Count;
  for i := 0 to AContexto.Resumen.Count - 1 do
  begin
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceSeleccion] := False;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceId] := AContexto.Resumen[i].IdPedido;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceReferencia] := AContexto.Resumen[i].Referencia;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceFecha] := AContexto.Resumen[i].Fecha;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceCliente] := AContexto.Resumen[i].Cliente;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceTotal] := AContexto.Resumen[i].Total;
    AContexto.Vista.DataController.Values[
      i, AContexto.IndiceEstado] := AContexto.Resumen[i].Estado;
    if AContexto.Resumen[i].Importado then
      AContexto.Vista.DataController.Values[
        i, AContexto.IndiceImportado] := 'S'
    else
      AContexto.Vista.DataController.Values[
        i, AContexto.IndiceImportado] := 'N';
  end;
end;

class function TCoordinadorImportacionPedidosVcl.RecogerIds(
  const AContexto: TContextoImportacionPedidosVcl
): TIdsPedidosImportacion;
var
  i: Integer;
  iCantidad: Integer;
begin
  SetLength(Result, AContexto.Resumen.Count);
  iCantidad := 0;
  for i := 0 to AContexto.Resumen.Count - 1 do
  begin
    if Boolean(AContexto.Vista.DataController.Values[
         i, AContexto.IndiceSeleccion]) then
    begin
      Result[iCantidad] := AContexto.Resumen[i].IdPedido;
      Inc(iCantidad);
    end;
  end;
  SetLength(Result, iCantidad);
end;

class procedure TCoordinadorImportacionPedidosVcl.PresentarProgreso(
  const AContexto: TContextoImportacionPedidosVcl;
  const AIdPedido: string;
  AEstado: TEstadoImportacionPedido;
  const AError: string);
var
  i: Integer;
begin
  if AEstado = eipImportando then
    AContexto.Estado.Caption := Format(
      SCaptionImportandoPedido,
      [AIdPedido])
  else if AEstado = eipError then
    AContexto.Estado.Caption := Format(
      SCaptionErrorImportandoPedido,
      [AIdPedido, AError]);
  if AEstado = eipImportado then
  begin
    for i := 0 to AContexto.Resumen.Count - 1 do
    begin
      if AContexto.Resumen[i].IdPedido = AIdPedido then
        AContexto.Vista.DataController.Values[
          i, AContexto.IndiceImportado] := 'S';
    end;
  end;
  Application.ProcessMessages;
end;

class procedure TCoordinadorImportacionPedidosVcl.Conectar(
  const AContexto: TContextoImportacionPedidosVcl);
begin
  Screen.Cursor := crHourGlass;
  try
    AContexto.Estado.Caption := SCaptionConectandoPrestaShop;
    Application.ProcessMessages;
    if AContexto.CasoUso.Listar(
         AContexto.BaseURL,
         AContexto.ApiKey,
         AContexto.IncluirImportados,
         AContexto.Resumen) then
    begin
      CargarGrid(AContexto);
      if (AContexto.Resumen.Count = 0) and
         not AContexto.IncluirImportados then
        AContexto.Estado.Caption := SCaptionSinPedidosNuevosPrestaShop
      else
        AContexto.Estado.Caption := Format(
          SCaptionRecuperadosPedidos,
          [AContexto.Resumen.Count]);
    end
    else
      AContexto.Estado.Caption := SCaptionNoRecuperadosPedidos;
  finally
    Screen.Cursor := crDefault;
  end;
end;

class procedure TCoordinadorImportacionPedidosVcl.Importar(
  const AContexto: TContextoImportacionPedidosVcl);
var
  oResultado: TResultadoImportacionPedidos;
  oSolicitud: TSolicitudImportacionPedidos;
begin
  if AContexto.CasoUso = nil then
    ShowMessage_fza(SErrorDataModulePedidosNoAsignado)
  else
  begin
    oSolicitud := Default(TSolicitudImportacionPedidos);
    oSolicitud.BaseURL := AContexto.BaseURL;
    oSolicitud.ApiKey := AContexto.ApiKey;
    oSolicitud.IdsPedidos := RecogerIds(AContexto);
    Screen.Cursor := crHourGlass;
    try
      oResultado := AContexto.CasoUso.Ejecutar(
        oSolicitud,
        procedure(
          const AIdPedido: string;
          AEstado: TEstadoImportacionPedido;
          const AError: string)
        begin
          PresentarProgreso(
            AContexto,
            AIdPedido,
            AEstado,
            AError);
        end);
    finally
      Screen.Cursor := crDefault;
    end;
    // La etiqueta se quedaba en el último «Importando ...».
    AContexto.Estado.Caption := Format(
      SInfoImportacionPedidosFinalizada,
      [oResultado.Importados, oResultado.Errores]);
    ShowMessage_fza(AContexto.Estado.Caption);
  end;
end;

end.

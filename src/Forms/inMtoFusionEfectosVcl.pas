{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFusionEfectosVcl                                        }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge la selección VCL y presenta el resultado de fusionar efectos.      }
{******************************************************************************}
unit inMtoFusionEfectosVcl;

interface

uses
  cxGridCustomTableView,
  cxGridDBTableView,
  inLibFusionEfectosIntf;

type
  TContextoFusionEfectosVcl = record
    Vista: TcxGridDBTableView;
    CasoUso: ICasoUsoFusionEfectos;
    IndiceSerie: Integer;
    IndiceNumero: Integer;
    IndiceEfecto: Integer;
    MensajeSeleccionInsuficiente: string;
  end;
  TCoordinadorFusionEfectosVcl = class
  private
    class function RecogerClaves(
      const AContexto: TContextoFusionEfectosVcl
    ): TClavesFusionEfectos; static;
  public
    class procedure Ejecutar(
      const AContexto: TContextoFusionEfectosVcl); static;
  end;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  System.UITypes,
  System.Variants,
  Vcl.Dialogs,
  inLibMsgComun;

class function TCoordinadorFusionEfectosVcl.RecogerClaves(
  const AContexto: TContextoFusionEfectosVcl
): TClavesFusionEfectos;
var
  i: Integer;
  iRegistro: Integer;
begin
  SetLength(
    Result,
    AContexto.Vista.Controller.SelectedRecordCount);
  for i := 0 to Length(Result) - 1 do
  begin
    iRegistro := AContexto.Vista.Controller.SelectedRecords[i].RecordIndex;
    Result[i].SerieFactura := VarToStr(
      AContexto.Vista.DataController.Values[
        iRegistro,
        AContexto.IndiceSerie]);
    Result[i].NumeroFactura := VarToStr(
      AContexto.Vista.DataController.Values[
        iRegistro,
        AContexto.IndiceNumero]);
    Result[i].NumeroEfecto := StrToIntDef(
      VarToStr(AContexto.Vista.DataController.Values[
        iRegistro,
        AContexto.IndiceEfecto]),
      0);
  end;
end;

class procedure TCoordinadorFusionEfectosVcl.Ejecutar(
  const AContexto: TContextoFusionEfectosVcl);
var
  aClaves: TClavesFusionEfectos;
  oResultado: TResultadoFusionEfectos;
begin
  if not Assigned(AContexto.Vista) or
     (AContexto.Vista.Controller.SelectedRecordCount < 2) then
    ShowMessage_fza(AContexto.MensajeSeleccionInsuficiente)
  else if MessageDlg_fza(
            SPreguntaFusionarEfectos,
            mtConfirmation,
            [mbYes, mbNo],
            0) = mrYes then
  begin
    aClaves := RecogerClaves(AContexto);
    oResultado := AContexto.CasoUso.Ejecutar(aClaves);
    if oResultado.Cantidad > 0 then
      ShowMessage_fza(Format(
        SInfoEfectosConciliados,
        [oResultado.Referencia]))
    else
      ShowMessage_fza(SErrorFusionarEfectos);
  end;
end;

end.

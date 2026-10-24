{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasEstadoFiscalPresentacion                         }
{    Tipo:       Colaborador de presentación                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calcula y aplica el bloqueo fiscal de una factura.                        }
{******************************************************************************}
unit inLibFacturasEstadoFiscalPresentacion;

interface

uses
  Data.DB, cxButtons, cxGridDBTableView;

type
  TConfiguracionEstadoFiscalFactura = record
    EsBorradorPendiente: Boolean;
    Editable: Boolean;
    ActualizarAcciones: Boolean;
    PuedeConsolidar: Boolean;
    PuedeImprimir: Boolean;
    // Subsanación: se corrigen importes y textos, pero no se insertan
    // ni borran líneas.
    EstructuraLineasBloqueada: Boolean;
  end;
  TControlesEstadoFiscalFactura = record
    DataSourceCabecera: TDataSource;
    VistaLineas: TcxGridDBTableView;
    BotonConsolidar: TcxButton;
    BotonImprimir: TcxButton;
  end;
  TPresentacionEstadoFiscalFactura = class
  public
    class procedure Aplicar(
      const AConfiguracion: TConfiguracionEstadoFiscalFactura;
      const AControles: TControlesEstadoFiscalFactura); static;
  end;

function CrearConfiguracionEstadoFiscalFactura(
  const AFase: string;
  AConsolidada: Boolean;
  ASinVerifactu: Boolean;
  ADataSetVacio: Boolean;
  AEstadoDataSet: TDataSetState
): TConfiguracionEstadoFiscalFactura;

implementation

uses
  System.SysUtils;

function CrearConfiguracionEstadoFiscalFactura(
  const AFase: string;
  AConsolidada: Boolean;
  ASinVerifactu: Boolean;
  ADataSetVacio: Boolean;
  AEstadoDataSet: TDataSetState
): TConfiguracionEstadoFiscalFactura;
begin
  Result := Default(TConfiguracionEstadoFiscalFactura);
  Result.EsBorradorPendiente :=
    ((AFase = '') or SameText(AFase, 'BORRADOR')) and
    (not AConsolidada);
  Result.EstructuraLineasBloqueada := SameText(AFase, 'SUBSANACION');
  Result.Editable := Result.EsBorradorPendiente or
    Result.EstructuraLineasBloqueada;
  if ASinVerifactu and
     ((AFase = '') or SameText(AFase, 'BORRADOR') or
      SameText(AFase, 'SIN_VERIFACTU')) then
  begin
    Result.Editable := True;
  end;
  if AEstadoDataSet = dsInsert then
    Result.Editable := True;
  Result.ActualizarAcciones := AEstadoDataSet = dsBrowse;
  Result.PuedeConsolidar :=
    Result.EsBorradorPendiente and
    (not ADataSetVacio);
  if ASinVerifactu then
    Result.PuedeImprimir := not ADataSetVacio
  else
    Result.PuedeImprimir := not Result.Editable;
end;

class procedure TPresentacionEstadoFiscalFactura.Aplicar(
  const AConfiguracion: TConfiguracionEstadoFiscalFactura;
  const AControles: TControlesEstadoFiscalFactura);
begin
  if Assigned(AControles.DataSourceCabecera) then
    AControles.DataSourceCabecera.AutoEdit := AConfiguracion.Editable;
  if Assigned(AControles.VistaLineas) then
  begin
    AControles.VistaLineas.OptionsData.Editing :=
      AConfiguracion.Editable;
    AControles.VistaLineas.OptionsData.Inserting :=
      AConfiguracion.Editable and
      (not AConfiguracion.EstructuraLineasBloqueada);
    AControles.VistaLineas.OptionsData.Deleting :=
      AConfiguracion.Editable and
      (not AConfiguracion.EstructuraLineasBloqueada);
    // FZ-ISSUE-129: sin Appending ni fila de alta, ni la flecha abajo en
    // la última línea ni «Click aquí para añadir fila» insertan.
    AControles.VistaLineas.OptionsData.Appending :=
      not AConfiguracion.EstructuraLineasBloqueada;
    AControles.VistaLineas.NewItemRow.Visible :=
      not AConfiguracion.EstructuraLineasBloqueada;
  end;
  if AConfiguracion.ActualizarAcciones then
  begin
    if Assigned(AControles.BotonConsolidar) then
      AControles.BotonConsolidar.Enabled :=
        AConfiguracion.PuedeConsolidar;
    if Assigned(AControles.BotonImprimir) then
      AControles.BotonImprimir.Enabled :=
        AConfiguracion.PuedeImprimir;
  end;
end;

end.

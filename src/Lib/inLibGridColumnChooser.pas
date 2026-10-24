{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridColumnChooser                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina el enriquecimiento y la selección de columnas de guías.         }
{******************************************************************************}
unit inLibGridColumnChooser;

interface

uses
  System.Classes, Vcl.Forms, Uni, inLibInformesGuiasCache,
  inLibGuiasGridPersistenciaIntf, inLibLogIntf;

type
  TGridGuiaResult = record
    Exito: Boolean;
    CamposNuevos: TStringList;
    CamposTabla: TStringList;
    ColumnasVisibles: TStringList;
    SqlOriginal: string;
  end;

function EnriquecerQueryConGuias(
  const APersistencia: IPersistenciaGuiasGrid;
  const ACache: IInformesGuiasCache;
  const AFormName: string;
  AQuery: TUniQuery;
  const ARegistroLog: IRegistroLog): TGridGuiaResult;

function ElegirColumnasNuevas(
  AOwner: TForm;
  ACamposNuevos: TStringList): TStringList;

implementation

uses
  System.SysUtils, Vcl.CheckLst, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Controls, Vcl.Dialogs, inLibMsgComun;

function CrearResultadoVacio(AQuery: TUniQuery): TGridGuiaResult;
begin
  Result.Exito := False;
  Result.CamposNuevos := TStringList.Create;
  Result.CamposTabla := TStringList.Create;
  Result.ColumnasVisibles := TStringList.Create;
  Result.ColumnasVisibles.CaseSensitive := False;
  Result.SqlOriginal := '';
  if Assigned(AQuery) then
    Result.SqlOriginal := AQuery.SQL.Text;
end;

function RecogerParametros(
  AQuery: TUniQuery): TArray<TParametroConsultaGuia>;
var
  iParametro: Integer;
begin
  SetLength(Result, AQuery.Params.Count);
  for iParametro := 0 to AQuery.Params.Count - 1 do
  begin
    Result[iParametro].Nombre := AQuery.Params[iParametro].Name;
    Result[iParametro].Valor := AQuery.Params[iParametro].Value;
  end;
end;

procedure CopiarValores(
  ADestino: TStrings;
  const AOrigen: TArray<string>);
var
  sValor: string;
begin
  for sValor in AOrigen do
  begin
    if ADestino.IndexOf(sValor) < 0 then
      ADestino.Add(sValor);
  end;
end;

procedure AplicarResultadoPersistencia(
  const AOrigen: TResultadoEnriquecimientoGuias;
  AQuery: TUniQuery;
  var ADestino: TGridGuiaResult);
begin
  ADestino.Exito := AOrigen.Exito;
  if AOrigen.Exito then
  begin
    AQuery.Close;
    AQuery.SQL.Text := AOrigen.SqlEnriquecido;
    CopiarValores(ADestino.CamposNuevos, AOrigen.CamposNuevos);
    CopiarValores(ADestino.CamposTabla, AOrigen.CamposTabla);
    CopiarValores(
      ADestino.ColumnasVisibles, AOrigen.ColumnasVisibles);
  end;
end;

function EnriquecerQueryConGuias(
  const APersistencia: IPersistenciaGuiasGrid;
  const ACache: IInformesGuiasCache;
  const AFormName: string;
  AQuery: TUniQuery;
  const ARegistroLog: IRegistroLog): TGridGuiaResult;
var
  arrGuias: TArray<TInformeGuiaItem>;
  arrParametros: TArray<TParametroConsultaGuia>;
  oResultado: TResultadoEnriquecimientoGuias;
begin
  Result := CrearResultadoVacio(AQuery);
  if Assigned(APersistencia) and Assigned(ACache) and
     ACache.Cargada and Assigned(AQuery) then
  begin
    arrGuias := ACache.Obtener('GRID:' + AFormName, '');
    if Length(arrGuias) > 0 then
    begin
      try
        arrParametros := RecogerParametros(AQuery);
        oResultado := APersistencia.Enriquecer(
          Result.SqlOriginal, arrParametros, arrGuias);
        AplicarResultadoPersistencia(oResultado, AQuery, Result);
      except
        on E: Exception do
        begin
          if Assigned(ARegistroLog) then
            ARegistroLog.RegistrarError(
              Format('Guía grid (%s) falló: %s',
                     [AFormName, E.Message]));
        end;
      end;
    end;
  end;
end;

function ElegirColumnasNuevas(
  AOwner: TForm;
  ACamposNuevos: TStringList): TStringList;
var
  iCampo: Integer;
  oBotonAceptar: TButton;
  oBotonCancelar: TButton;
  oFormulario: TForm;
  oLista: TCheckListBox;
  oPanel: TPanel;
begin
  Result := TStringList.Create;
  if Assigned(ACamposNuevos) and (ACamposNuevos.Count > 0) then
  begin
    oFormulario := TForm.Create(AOwner);
    try
      oFormulario.Caption := STituloSeleccionarColumnas;
      oFormulario.Width := 420;
      oFormulario.Height := 460;
      oFormulario.Position := poScreenCenter;
      oFormulario.BorderStyle := bsDialog;
      oPanel := TPanel.Create(oFormulario);
      oPanel.Parent := oFormulario;
      oPanel.Align := alBottom;
      oPanel.Height := 45;
      oPanel.BevelOuter := bvNone;
      oLista := TCheckListBox.Create(oFormulario);
      oLista.Parent := oFormulario;
      oLista.Align := alClient;
      oLista.Font.Name := 'Consolas';
      oLista.Font.Size := 10;
      for iCampo := 0 to ACamposNuevos.Count - 1 do
        oLista.Items.Add(ACamposNuevos[iCampo]);
      oBotonAceptar := TButton.Create(oPanel);
      oBotonAceptar.Parent := oPanel;
      oBotonAceptar.Caption := SCaptionAceptar;
      oBotonAceptar.ModalResult := mrOk;
      oBotonAceptar.Left := 160;
      oBotonAceptar.Top := 8;
      oBotonAceptar.Width := 120;
      oBotonAceptar.Height := 30;
      oBotonCancelar := TButton.Create(oPanel);
      oBotonCancelar.Parent := oPanel;
      oBotonCancelar.Caption := SCaptionCancelar;
      oBotonCancelar.ModalResult := mrCancel;
      oBotonCancelar.Left := 290;
      oBotonCancelar.Top := 8;
      oBotonCancelar.Width := 120;
      oBotonCancelar.Height := 30;
      if oFormulario.ShowModal = mrOk then
      begin
        for iCampo := 0 to oLista.Count - 1 do
        begin
          if oLista.Checked[iCampo] then
            Result.Add(oLista.Items[iCampo]);
        end;
      end;
    finally
      FreeAndNil(oFormulario);
    end;
  end;
end;

end.

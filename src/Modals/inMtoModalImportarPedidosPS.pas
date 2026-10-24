{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImportarPedidosPS                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de importacion de pedidos desde PrestaShop.                         }
{    Conecta via API y permite seleccionar los pedidos a importar.             }
{******************************************************************************}
unit inMtoModalImportarPedidosPS;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxLabel, cxButtons, cxCheckBox,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGrid, dxSkinsCore, dxSkinBlue, cxContainer, cxMaskEdit,
  cxDropDownEdit, cxListBox, cxCheckListBox, cxNavigator,
  cxPropertiesStore, dxSkinsForm,
  System.Generics.Collections,
  UniDataPedidos, Vcl.Menus, inMtoFrmBase,
  inLibImportacionPedidosIntf;

type
  TfrmModalImportarPedidosPS = class(TfrmBase)
    pnlTop: TPanel;
    pnlMid:  TPanel;
    pnlBottom: TPanel;
    lblConfiguracion: TcxLabel;
    btnConectar: TcxButton;
    chkMostrarImportados: TcxCheckBox;
    cxgrdPedidos: TcxGrid;
    tvPedidos: TcxGridTableView;
    cxgrdlvlPedidos: TcxGridLevel;
    colSel: TcxGridColumn;
    colId: TcxGridColumn;
    colRef: TcxGridColumn;
    colFecha: TcxGridColumn;
    colCliente: TcxGridColumn;
    colTotal: TcxGridColumn;
    colEstado: TcxGridColumn;
    colImportado: TcxGridColumn;
    btnImportar: TcxButton;
    btnCerrar: TcxButton;
    lblEstado: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnImportarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FBaseURL: string;
    FApiKey: string;
    FConfiguracionCargada: Boolean;
    FResumen: TResumenPedidosImportacion;
    FCasoUsoImportacion: ICasoUsoImportacionPedidos;
    function CargarConfiguracion: Boolean;
    function ConfiguracionSigueVigente: Boolean;
    function LeerConfiguracion(
      out ABaseURL, AApiKey: string): Boolean;
  public
    procedure Configurar(ADataModule: TdmPedidos);
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibImportacionPedidos,
  inLibPrestaShopPedidosAdaptador,
  UniDataImportacionPedidos,
  inMtoImportacionPedidosVcl;

resourcestring
  SConfiguracionPrestaShopIncompleta =
    'Configura la URL y la clave de PrestaShop en Parámetros de Entorno.';
  SConfiguracionPrestaShopCambiada =
    'La configuración de PrestaShop ha cambiado. Pulsa Conectar y listar ' +
    'antes de importar.';
  SPrestaShopNoConectado =
    'Pulsa Conectar y listar antes de importar pedidos.';

function CrearContextoImportacionPedidosVcl(
  AFormulario: TfrmModalImportarPedidosPS
): TContextoImportacionPedidosVcl;
begin
  Result := Default(TContextoImportacionPedidosVcl);
  Result.Vista := AFormulario.tvPedidos;
  Result.Estado := AFormulario.lblEstado;
  Result.Resumen := AFormulario.FResumen;
  Result.CasoUso := AFormulario.FCasoUsoImportacion;
  Result.BaseURL := AFormulario.FBaseURL;
  Result.ApiKey := AFormulario.FApiKey;
  Result.IncluirImportados := AFormulario.chkMostrarImportados.Checked;
  Result.IndiceSeleccion := AFormulario.colSel.Index;
  Result.IndiceId := AFormulario.colId.Index;
  Result.IndiceReferencia := AFormulario.colRef.Index;
  Result.IndiceFecha := AFormulario.colFecha.Index;
  Result.IndiceCliente := AFormulario.colCliente.Index;
  Result.IndiceTotal := AFormulario.colTotal.Index;
  Result.IndiceEstado := AFormulario.colEstado.Index;
  Result.IndiceImportado := AFormulario.colImportado.Index;
end;

procedure TfrmModalImportarPedidosPS.FormCreate(Sender: TObject);
begin
  inherited;
  FResumen := TResumenPedidosImportacion.Create;
  FConfiguracionCargada := False;
end;

function TfrmModalImportarPedidosPS.CargarConfiguracion: Boolean;
begin
  Result := LeerConfiguracion(FBaseURL, FApiKey);
  FConfiguracionCargada := Result;
  if not Result then
    ShowMessage_fza(SConfiguracionPrestaShopIncompleta);
end;

function TfrmModalImportarPedidosPS.ConfiguracionSigueVigente: Boolean;
var
  sApiKeyActual: string;
  sBaseURLActual: string;
begin
  Result := False;
  if not FConfiguracionCargada then
    ShowMessage_fza(SPrestaShopNoConectado)
  else if not LeerConfiguracion(sBaseURLActual, sApiKeyActual) then
    ShowMessage_fza(SConfiguracionPrestaShopIncompleta)
  else if (sBaseURLActual <> FBaseURL) or
          (sApiKeyActual <> FApiKey) then
  begin
    FConfiguracionCargada := False;
    ShowMessage_fza(SConfiguracionPrestaShopCambiada);
  end
  else
    Result := True;
end;

function TfrmModalImportarPedidosPS.LeerConfiguracion(
  out ABaseURL, AApiKey: string): Boolean;
begin
  ABaseURL := '';
  AApiKey := '';
  if Assigned(ParametrosApp) then
  begin
    ABaseURL := Trim(ParametrosApp.GetString('appPrestaShopUrl', ''));
    AApiKey := Trim(ParametrosApp.GetString('appPrestaShopApiKey', ''));
  end;
  Result := (ABaseURL <> '') and (AApiKey <> '');
end;

procedure TfrmModalImportarPedidosPS.btnCerrarClick(Sender: TObject);
begin
  FreeAndNil(FResumen);
  Close;
end;

procedure TfrmModalImportarPedidosPS.btnConectarClick(Sender: TObject);
begin
  if CargarConfiguracion then
  begin
    TCoordinadorImportacionPedidosVcl.Conectar(
      CrearContextoImportacionPedidosVcl(Self));
  end;
end;

procedure TfrmModalImportarPedidosPS.Configurar(
  ADataModule: TdmPedidos);
begin
  FCasoUsoImportacion := CrearCasoUsoImportacionPedidos(
    CrearFabricaFuentePedidosPrestaShop(RegistroLog),
    CrearRepositorioImportacionPedidosUniDAC(ADataModule));
end;

procedure TfrmModalImportarPedidosPS.btnImportarClick(Sender: TObject);
begin
  if ConfiguracionSigueVigente then
  begin
    TCoordinadorImportacionPedidosVcl.Importar(
      CrearContextoImportacionPedidosVcl(Self));
  end;
end;

end.

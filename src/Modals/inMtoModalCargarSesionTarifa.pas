{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCargarSesionTarifa                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Carga masiva de articulos sobre una sesion de cambios de tarifa.          }
{    Reutiliza los filtros de AddBlockBase y guarda una linea revisable.       }
{******************************************************************************}
unit inMtoModalCargarSesionTarifa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalAddBlockBase,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  TCargarSesionTarifaResult = record
    Aceptado      : Boolean;
    NumInsertados : Integer;
  end;

  TfrmModalCargarSesionTarifa = class(TfrmModalAddBlockBase)
  protected
    FCodigoTarc    : Integer;
    FCodigoTarOrig : string;
    FCodigoTarDest : string;
    FResultado     : TCargarSesionTarifaResult;
    function ContextoCargaMasiva: TContextoCargaMasivaArticulos; override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;
    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean;
      override;
  public
    class function Ejecutar(
      AOwner: TComponent;
      ACodigoTarc: Integer;
      const ACodigoTarOrig,
      ACodigoTarDest: string;
      const AServicios: TServiciosCargaMasivaArticulos):
      TCargarSesionTarifaResult;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibUser, inLibMsgArticulos;

resourcestring
  SCaptionExcluirArticulosYaEnSesionTarifa =
    'Excluir articulos ya cargados en la sesion';

class function TfrmModalCargarSesionTarifa.Ejecutar(
  AOwner: TComponent;
  ACodigoTarc: Integer;
  const ACodigoTarOrig, ACodigoTarDest: string;
  const AServicios: TServiciosCargaMasivaArticulos):
  TCargarSesionTarifaResult;
var
  frm: TfrmModalCargarSesionTarifa;
begin
  frm := TfrmModalCargarSesionTarifa.Create(AOwner, AServicios);
  try
    frm.FCodigoTarc := ACodigoTarc;
    frm.FCodigoTarOrig := ACodigoTarOrig;
    frm.FCodigoTarDest := ACodigoTarDest;
    frm.FResultado.Aceptado := False;
    frm.Caption := STituloCargarArticulosSesionTarifas;
    frm.Inicializar;
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

function TfrmModalCargarSesionTarifa.ContextoCargaMasiva:
  TContextoCargaMasivaArticulos;
begin
  Result.Modo := mcSesionTarifa;
  Result.CodigoSesionTarifa := FCodigoTarc;
  Result.TarifaOrigenSesion := FCodigoTarOrig;
  Result.TarifaDestinoSesion := FCodigoTarDest;
end;

function TfrmModalCargarSesionTarifa.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarCargaSesionTarifa,
                   [ANumPendientes]);
end;

function TfrmModalCargarSesionTarifa.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format(SInfoArticulosCargadosSesionTarifa, [ANumInsertados]);
end;

function TfrmModalCargarSesionTarifa.TextoExcluirYaCargados: string;
begin
  Result := SCaptionExcluirArticulosYaEnSesionTarifa;
end;

function TfrmModalCargarSesionTarifa.EjecutarInsercion(
  out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  oParametros: TParametrosInsercionSesionTarifa;
  oResultado: TResultadoInsercionCargaMasiva;
begin
  Result := False;
  ANumInsertados := 0;
  SetLength(ACodigos, 0);
  if Assigned(DatosPreview) and DatosPreview.Active and
     (DatosPreview.RecordCount > 0) then
  begin
    oParametros.CodigoSesion := FCodigoTarc;
    oParametros.TarifaOrigen := FCodigoTarOrig;
    oParametros.TarifaDestino := FCodigoTarDest;
    oParametros.Usuario := IdentidadSesion.Usuario;
    try
      oResultado := InsercionesCargaMasiva.InsertarSesionTarifa(
        ConsultaPreview,
        oParametros);
      ANumInsertados := oResultado.NumeroLineas;
      ACodigos := oResultado.CodigosArticulo;
      FResultado.Aceptado := True;
      FResultado.NumInsertados := ANumInsertados;
      Result := True;
    except
      on E: Exception do
      begin
        ShowMessage_fza(SErrorCargarSesionTarifa + E.Message);
      end;
    end;
  end;
end;

end.

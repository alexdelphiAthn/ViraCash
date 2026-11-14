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
  private
    function NumeroArticulosPreview(ASoloPendientes: Boolean): Integer;
  protected
    FCodigoTarc    : Integer;
    FCodigoTarOrig : string;
    FCodigoTarDest : string;
    FResultado     : TCargarSesionTarifaResult;
    procedure ConfigurarPreviewExtra; override;
    function TextoResumenPreview(ANumeroRegistros: Integer): string; override;
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
  Data.DB, cxGridDBTableView,
  inLibMensajesVcl,
  inLibUser, inLibMsgArticulos;

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

procedure TfrmModalCargarSesionTarifa.ConfigurarPreviewExtra;
var
  Columna: TcxGridDBColumn;
begin
  inherited;
  Columna := tvPreview.GetColumnByFieldName('CODIGO_UNIDAD_SKU');
  if Columna = nil then
  begin
    Columna := tvPreview.CreateColumn;
    Columna.DataBinding.FieldName := 'CODIGO_UNIDAD_SKU';
    Columna.Index := colPrevCodigo.Index + 1;
    Columna.Width := 160;
    Columna.Options.Editing := False;
  end;
  Columna.Caption := SCaptionColSku;
end;

function TfrmModalCargarSesionTarifa.NumeroArticulosPreview(
  ASoloPendientes: Boolean): Integer;
var
  Codigos: TStringList;
  Marca: TBookmark;
begin
  Result := 0;
  if Assigned(DatosPreview) and DatosPreview.Active then
  begin
    Codigos := TStringList.Create;
    try
      Codigos.Sorted := True;
      Codigos.Duplicates := dupIgnore;
      Marca := DatosPreview.Bookmark;
      DatosPreview.DisableControls;
      try
        DatosPreview.First;
        while not DatosPreview.Eof do
        begin
          if (not ASoloPendientes) or
            (DatosPreview.FieldByName('YA_CARGADO').AsString <> 'S') then
          begin
            Codigos.Add(DatosPreview.FieldByName('CODIGO_ART_ART').AsString);
          end;
          DatosPreview.Next;
        end;
      finally
        if DatosPreview.BookmarkValid(Marca) then
        begin
          DatosPreview.Bookmark := Marca;
        end;
        DatosPreview.EnableControls;
      end;
      Result := Codigos.Count;
    finally
      Codigos.Free;
    end;
  end;
end;

function TfrmModalCargarSesionTarifa.TextoResumenPreview(
  ANumeroRegistros: Integer): string;
begin
  Result := inherited TextoResumenPreview(NumeroArticulosPreview(False));
end;

function TfrmModalCargarSesionTarifa.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarCargaSesionTarifa,
                   [NumeroArticulosPreview(True)]);
end;

function TfrmModalCargarSesionTarifa.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format(SInfoArticulosCargadosSesionTarifa,
    [NumeroArticulosPreview(True)]);
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

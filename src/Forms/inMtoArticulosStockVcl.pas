{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosStockVcl                                        }
{    Tipo:       Coordinador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la presentacion, carga perezosa y reconstruccion del stock de    }
{    articulos mediante datasets y callbacks estrechos.                        }
{******************************************************************************}
unit inMtoArticulosStockVcl;

interface

uses
  System.SysUtils, System.Types, Data.DB, Uni,
  cxGraphics, cxGridCustomView, cxGridCustomTableView, cxGridDBTableView,
  inMtoArticulosPresentacionStock, inLibPestanasEjeVcl;

type
  TRecargarStockArticuloVcl = reference to procedure;
  TReconstruirStockArticuloVcl = reference to function: string;
  TContextoStockArticuloVcl = record
    Vista: TcxGridDBTableView;
    Conexion: TUniConnection;
    Articulos: TDataSet;
    ConsultaStock: TDataSet;
    Recargar: TRecargarStockArticuloVcl;
    Reconstruir: TReconstruirStockArticuloVcl;
    PreguntaReconstruir: string;
    TituloReconstruir: string;
    ErrorReconstruir: string;
    InfoReconstruido: string;
    procedure Validar;
  end;
  TCoordinadorStockArticuloVcl = class
  private
    FContexto: TContextoStockArticuloVcl;
    FPresentador: TPresentadorStockArticulo;
    FArticuloCargado: string;
    FPestanas: TControlPestanasGridStock;
  public
    constructor Create(const AContexto: TContextoStockArticuloVcl);
    destructor Destroy; override;
    procedure CargarMapaArticulo(const ACodigoArticulo: string);
    procedure AsegurarAlDia(const ACodigoArticulo: string);
    procedure Reconstruir(const ACodigoArticulo: string);
    procedure PintarCelda(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
    function ObtenerHint(AViewInfo: TcxGridTableDataCellViewInfo;
      out AHint: string): Boolean;
    procedure EnsancharColumnasParaSwatch;
  end;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

procedure TContextoStockArticuloVcl.Validar;
begin
  if Vista = nil then
    raise EArgumentNilException.Create('Vista');
  if Conexion = nil then
    raise EArgumentNilException.Create('Conexion');
  if Articulos = nil then
    raise EArgumentNilException.Create('Articulos');
  if ConsultaStock = nil then
    raise EArgumentNilException.Create('ConsultaStock');
  if not Assigned(Recargar) then
    raise EArgumentNilException.Create('Recargar');
  if not Assigned(Reconstruir) then
    raise EArgumentNilException.Create('Reconstruir');
end;

constructor TCoordinadorStockArticuloVcl.Create(
  const AContexto: TContextoStockArticuloVcl);
begin
  inherited Create;
  AContexto.Validar;
  FContexto := AContexto;
  FPestanas := TControlPestanasGridStock.Create(FContexto.Vista);
  FPresentador := TPresentadorStockArticulo.Create(
    FContexto.Vista, FContexto.Conexion);
end;

destructor TCoordinadorStockArticuloVcl.Destroy;
begin
  FreeAndNil(FPestanas);
  FreeAndNil(FPresentador);
  inherited Destroy;
end;

procedure TCoordinadorStockArticuloVcl.CargarMapaArticulo(
  const ACodigoArticulo: string);
begin
  FPresentador.CargarMapaArticulo(ACodigoArticulo);
end;

procedure TCoordinadorStockArticuloVcl.AsegurarAlDia(
  const ACodigoArticulo: string);
var
  AlDia: Boolean;
begin
  if ACodigoArticulo <> '' then
  begin
    AlDia := (FArticuloCargado = ACodigoArticulo) and
      FContexto.ConsultaStock.Active;
    if not AlDia then
    begin
      FContexto.Recargar();
      FPestanas.Actualizar(ACodigoArticulo);
      FArticuloCargado := ACodigoArticulo;
    end;
  end
  else
  begin
    // FZ-ISSUE-201: sin articulo (alta en curso) la consulta no puede
    // seguir mostrando el stock del ultimo articulo cargado.
    FPestanas.Ocultar;
    FContexto.ConsultaStock.Close;
    FArticuloCargado := '';
  end;
end;

procedure TCoordinadorStockArticuloVcl.Reconstruir(
  const ACodigoArticulo: string);
var
  Mensaje: string;
  Reconstruido: Boolean;
begin
  if MessageBox_fza(
       PChar(FContexto.PreguntaReconstruir),
       PChar(FContexto.TituloReconstruir),
       MB_YESNO + MB_ICONQUESTION) = ID_YES then
  begin
    Reconstruido := True;
    Screen.Cursor := crHourGlass;
    try
      try
        Mensaje := FContexto.Reconstruir();
        if FContexto.Articulos.Active and
           not FContexto.Articulos.IsEmpty then
        begin
          FContexto.Recargar();
          FPestanas.Actualizar(ACodigoArticulo);
          FArticuloCargado := ACodigoArticulo;
        end;
      except
        on E: Exception do
        begin
          Reconstruido := False;
          ShowMessage_fza(Format(FContexto.ErrorReconstruir, [E.Message]));
        end;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
    if Reconstruido then
    begin
      if Mensaje = '' then
        Mensaje := FContexto.InfoReconstruido;
      ShowMessage_fza(Mensaje);
    end;
  end;
end;

procedure TCoordinadorStockArticuloVcl.PintarCelda(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
begin
  FPresentador.PintarCelda(ACanvas, AViewInfo, AHecho);
end;

function TCoordinadorStockArticuloVcl.ObtenerHint(
  AViewInfo: TcxGridTableDataCellViewInfo; out AHint: string): Boolean;
begin
  Result := FPresentador.ObtenerHint(AViewInfo, AHint);
end;

procedure TCoordinadorStockArticuloVcl.EnsancharColumnasParaSwatch;
begin
  FPresentador.EnsancharColumnasParaSwatch;
end;

end.

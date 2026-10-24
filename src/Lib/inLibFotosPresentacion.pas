{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosPresentacion                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presentación de fotografías en VCL y sustitución en FastReport.           }
{******************************************************************************}
unit inLibFotosPresentacion;

interface

uses
  System.Classes,
  Data.DB,
  Vcl.ExtCtrls,
  frxClass,
  inLibFotosTipos;

type
  TPresentacionFotos = class
  private
    procedure SustituirFotoEnPicture(
      AFotos: TProveedorFotosPresentacion;
      APicture: TfrxPictureView;
      AResolucion: TFotoResolucion);
  public
    procedure AntesDeImprimir(
      AFotos: TProveedorFotosPresentacion;
      AComponente: TfrxReportComponent);
  end;

  TFotoEmbebida = class
  private
    FFotos          : TProveedorFotosPresentacion;
    FImagen         : TImage;
    FOrigenDatos    : TDataSource;
    FAnteriorCambio : TDataChangeEvent;
    procedure CambioDatos(Sender: TObject; Field: TField);
  public
    constructor Create(AFotos: TProveedorFotosPresentacion;
      AImagen: TImage; AOrigenDatos: TDataSource);
    destructor Destroy; override;
    procedure Refrescar;
  end;

function ObtenerDataSetDeBandaPadre(AObjeto: TfrxComponent): TDataSet;

implementation

uses
  System.SysUtils,
  Vcl.Imaging.PngImage,
  frxDBSet;

function ObtenerDataSetDeBandaPadre(
  AObjeto: TfrxComponent): TDataSet;
var
  oBanda      : TfrxDataBand;
  oPadre      : TfrxComponent;
  oReport     : TfrxReport;
  iDataSet    : Integer;
  bContinuar  : Boolean;
begin
  Result := nil;
  if AObjeto <> nil then
  begin
    oPadre := AObjeto.Parent;
    bContinuar := Assigned(oPadre);
    while bContinuar do
    begin
      if oPadre is TfrxDataBand then
      begin
        oBanda := TfrxDataBand(oPadre);
        // GetDataSet y no DataSet: enlazado por DataSource, FastReport
        // deja la propiedad DataSet a nil
        if Assigned(oBanda.DataSet) and
           (oBanda.DataSet is TfrxDBDataset) then
          Result := TfrxDBDataset(oBanda.DataSet).GetDataSet;
      end;
      if Result = nil then
        oPadre := oPadre.Parent;
      bContinuar := Assigned(oPadre) and (Result = nil);
    end;
    oReport := AObjeto.Report;
    if (Result = nil) and (oReport <> nil) then
    begin
      iDataSet := 0;
      while (iDataSet < oReport.Datasets.Count) and
            (Result = nil) do
      begin
        if oReport.Datasets[iDataSet].DataSet is TfrxDBDataset then
          Result := TfrxDBDataset(
            oReport.Datasets[iDataSet].DataSet).GetDataSet;
        Inc(iDataSet);
      end;
    end;
  end;
end;

procedure TPresentacionFotos.SustituirFotoEnPicture(
  AFotos: TProveedorFotosPresentacion;
  APicture: TfrxPictureView; AResolucion: TFotoResolucion);
var
  oDataSet: TDataSet;
  oInfo   : TFotoInfo;
  oPng    : TPngImage;
  sArt    : string;
  sSku    : string;
  sRuta   : string;
begin
  if Assigned(APicture) then
  begin
    APicture.Picture.Assign(nil);
    if Assigned(AFotos) then
    begin
      oDataSet := ObtenerDataSetDeBandaPadre(APicture);
      if oDataSet <> nil then
      begin
        AFotos.LeerArtSkuDeDataSet(oDataSet, sArt, sSku);
        if sArt <> '' then
        begin
          oInfo := AFotos.Resolver(sArt, sSku);
          sRuta := AFotos.RutaFoto(oInfo, AResolucion);
          if sRuta <> '' then
          begin
            oPng := TPngImage.Create;
            try
              oPng.LoadFromFile(sRuta);
              APicture.Picture.Assign(oPng);
            finally
              FreeAndNil(oPng);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TPresentacionFotos.AntesDeImprimir(
  AFotos: TProveedorFotosPresentacion;
  AComponente: TfrxReportComponent);
var
  oPicture  : TfrxPictureView;
  eResolucion: TFotoResolucion;
  sNombre   : string;
  bEsFoto   : Boolean;
begin
  if AComponente is TfrxPictureView then
  begin
    oPicture := TfrxPictureView(AComponente);
    sNombre := LowerCase(oPicture.Name);
    eResolucion := frPx300;
    bEsFoto := True;
    if sNombre = 'foto300' then
      eResolucion := frPx300
    else if sNombre = 'foto600' then
      eResolucion := frPx600
    else if sNombre = 'fotoreal' then
      eResolucion := frReal
    else
      bEsFoto := False;
    if bEsFoto then
      SustituirFotoEnPicture(AFotos, oPicture, eResolucion);
  end;
end;

constructor TFotoEmbebida.Create(
  AFotos: TProveedorFotosPresentacion; AImagen: TImage;
  AOrigenDatos: TDataSource);
begin
  inherited Create;
  FFotos := AFotos;
  FImagen := AImagen;
  FOrigenDatos := AOrigenDatos;
  if Assigned(FOrigenDatos) then
  begin
    FAnteriorCambio := FOrigenDatos.OnDataChange;
    FOrigenDatos.OnDataChange := CambioDatos;
  end;
  Refrescar;
end;

destructor TFotoEmbebida.Destroy;
begin
  if Assigned(FOrigenDatos) then
    FOrigenDatos.OnDataChange := FAnteriorCambio;
  inherited;
end;

procedure TFotoEmbebida.CambioDatos(Sender: TObject; Field: TField);
begin
  if Assigned(FAnteriorCambio) then
    FAnteriorCambio(Sender, Field);
  if Field = nil then
    Refrescar;
end;

procedure TFotoEmbebida.Refrescar;
var
  oInfo: TFotoInfo;
  oPng : TPngImage;
  sArt : string;
  sSku : string;
  sRuta: string;
begin
  if Assigned(FImagen) then
  begin
    FImagen.Picture.Assign(nil);
    if Assigned(FOrigenDatos) and Assigned(FFotos) then
    begin
      FFotos.LeerArtSkuDeDataSet(
        FOrigenDatos.DataSet, sArt, sSku);
      if sArt <> '' then
      begin
        oInfo := FFotos.Resolver(sArt, sSku);
        sRuta := FFotos.RutaFoto(oInfo, frPx300);
        if sRuta <> '' then
        begin
          oPng := TPngImage.Create;
          try
            oPng.LoadFromFile(sRuta);
            FImagen.Picture.Assign(oPng);
          finally
            FreeAndNil(oPng);
          end;
        end;
      end;
    end;
  end;
end;

end.

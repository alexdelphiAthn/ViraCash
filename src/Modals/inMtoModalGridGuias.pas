{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalGridGuias                                           }
{    Tipo:       Formulario (Modal) - hijo de inMtoModalGuiasBase              }
{ Version:       2.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Hijo de TfrmModalGuiasBase para guias de grid (LEFT JOIN runtime).        }
{    Los campos master se cargan del TDataSet del grid principal.              }
{******************************************************************************}
unit inMtoModalGridGuias;

interface

uses
  System.SysUtils, System.Classes, Data.DB,
  inMtoModalGuiasBase;

type
  TfrmModalGridGuias = class(TfrmModalGuiasBase)
  protected
    procedure CargarCamposMaster; override;
    function ObtenerClaveInforme: string; override;
    function ObtenerTitulo: string; override;
    function ObtenerInfoCaption: string; override;
    function ObtenerDatasetMaster: string; override;
  public
    FDataSet: TDataSet;
  end;

implementation

{$R *.dfm}

resourcestring
  STituloGuiasGrid = 'Guías del grid';
  SInfoFormularioGridGuias = 'Formulario: %s';

procedure TfrmModalGridGuias.CargarCamposMaster;
var
  i: Integer;
begin
  lbCamposMaster.Items.Clear;
  if (FDataSet <> nil) and FDataSet.Active then
    for i := 0 to FDataSet.FieldCount - 1 do
      lbCamposMaster.Items.Add(FDataSet.Fields[i].FieldName);
end;

function TfrmModalGridGuias.ObtenerClaveInforme: string;
begin
  Result := 'GRID:' + sFormulario;
end;

function TfrmModalGridGuias.ObtenerTitulo: string;
begin
  Result := STituloGuiasGrid;
end;

function TfrmModalGridGuias.ObtenerInfoCaption: string;
begin
  Result := Format(SInfoFormularioGridGuias, [sFormulario]);
end;

function TfrmModalGridGuias.ObtenerDatasetMaster: string;
begin
  Result := 'TablaG';
end;

end.

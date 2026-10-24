{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFuenteFastReport                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Aplica la fuente corporativa a las ventanas propias de FastReport: la     }
{    vista preliminar, el diálogo de impresión, los de exportación y el        }
{    diseñador. El código del proveedor no se toca.                            }
{                                                                              }
{    Esos formularios llevan 'Tahoma' escrita en su propio DFM, así que        }
{    Application.DefaultFont no les llega. Aquí se engancha                    }
{    Screen.OnActiveFormChange y, cuando el formulario que se activa           }
{    desciende de TfrxBaseForm, se renombra la fuente de sus controles.        }
{    El controlador que hubiera antes se sigue llamando.                       }
{                                                                              }
{    Solo se sustituyen fuentes de texto corriente. Las de símbolos y las      }
{    monoespaciadas se respetan, porque dibujan iconos y texto alineado.       }
{    No se tocan tamaño, estilo ni color, y los controles con ParentFont       }
{    se dejan heredar de su contenedor.                                        }
{******************************************************************************}
unit inLibFuenteFastReport;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms;

const
  NOMBRE_FUENTE_FASTREPORT = 'Source Sans 3';

type
  // Renombrado en caliente de la fuente de la interfaz de FastReport.
  // Activar se invoca una vez al arrancar la aplicación;
  // AplicarAFormulario permite forzarlo sobre una ventana concreta.
  TFuenteFastReport = class
  strict private
    class var FActiva: Boolean;
    class var FNombre: string;
    class var FControladorPrevio: TNotifyEvent;
    class procedure CambioDeFormularioActivo(ASender: TObject);
    class procedure AplicarAControl(AControl: TControl);
  public
    class procedure Activar(
      const ANombre: string = NOMBRE_FUENTE_FASTREPORT);
    class procedure Desactivar;
    class procedure AplicarAFormulario(AFormulario: TCustomForm);
    // Públicas para poder probarlas sin abrir ventanas.
    class function EsSustituible(const ANombre: string): Boolean;
    class function EstaActiva: Boolean;
    class function NombreActual: string;
  end;

implementation

uses
  System.SysUtils, frxBaseForm;

type
  // TControl declara Font y ParentFont en la sección protegida.
  TControlProtegido = class(TControl);

const
  // Fuentes de texto corriente que trae la interfaz de FastReport.
  // Cualquier otra (Wingdings, Symbol, Courier New...) se respeta.
  FUENTES_SUSTITUIBLES: array[0..4] of string = (
    'Tahoma',
    'Arial',
    'Segoe UI',
    'MS Sans Serif',
    'Microsoft Sans Serif');

class function TFuenteFastReport.EsSustituible(
  const ANombre: string): Boolean;
var
  Indice: Integer;
begin
  Result := False;
  for Indice := Low(FUENTES_SUSTITUIBLES) to High(FUENTES_SUSTITUIBLES) do
    if SameText(ANombre, FUENTES_SUSTITUIBLES[Indice]) then
      Result := True;
end;

class function TFuenteFastReport.EstaActiva: Boolean;
begin
  Result := FActiva;
end;

class function TFuenteFastReport.NombreActual: string;
begin
  Result := FNombre;
end;

class procedure TFuenteFastReport.AplicarAControl(AControl: TControl);
var
  Protegido: TControlProtegido;
  Contenedor: TWinControl;
  Indice: Integer;
begin
  if AControl <> nil then
  begin
    Protegido := TControlProtegido(AControl);
    if (not Protegido.ParentFont)
      and EsSustituible(Protegido.Font.Name) then
      Protegido.Font.Name := FNombre;
    if AControl is TWinControl then
    begin
      Contenedor := TWinControl(AControl);
      for Indice := 0 to Contenedor.ControlCount - 1 do
        AplicarAControl(Contenedor.Controls[Indice]);
    end;
  end;
end;

class procedure TFuenteFastReport.AplicarAFormulario(
  AFormulario: TCustomForm);
begin
  if (AFormulario <> nil) and (FNombre <> '') then
    AplicarAControl(AFormulario);
end;

class procedure TFuenteFastReport.CambioDeFormularioActivo(
  ASender: TObject);
begin
  if FActiva and (Screen.ActiveCustomForm is TfrxBaseForm) then
    AplicarAFormulario(Screen.ActiveCustomForm);
  if Assigned(FControladorPrevio) then
    FControladorPrevio(ASender);
end;

class procedure TFuenteFastReport.Activar(const ANombre: string);
begin
  FNombre := ANombre;
  if not FActiva then
  begin
    FControladorPrevio := Screen.OnActiveFormChange;
    Screen.OnActiveFormChange := CambioDeFormularioActivo;
    FActiva := True;
  end;
end;

class procedure TFuenteFastReport.Desactivar;
begin
  if FActiva then
  begin
    Screen.OnActiveFormChange := FControladorPrevio;
    FControladorPrevio := nil;
    FActiva := False;
  end;
end;

end.

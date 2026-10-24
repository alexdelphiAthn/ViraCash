{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFotoArticulo                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Wrapper modal de TfrmFotoArticulo para invocarlo dentro de otro modal.    }
{    Reutiliza el mismo formulario flotante, pero abierto con ShowModal.       }
{******************************************************************************}
unit inMtoModalFotoArticulo;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  inMtoFotoArticulo;

type
  TfrmModalFotoArticulo = class
  public
    /// Muestra la foto del par (articulo, sku) en modo modal. Devuelve
    /// `True` siempre (el modal solo informa). Util cuando el llamador
    /// es a su vez un formulario modal, donde un Show no-modal queda por
    /// detras.
    class function Ejecutar(AOwner: TComponent;
                            const ACodArt, ACodSku: string): Boolean;
  end;

implementation

class function TfrmModalFotoArticulo.Ejecutar(AOwner: TComponent;
                              const ACodArt, ACodSku: string): Boolean;
var
  frm: TfrmFotoArticulo;
begin
  frm := TfrmFotoArticulo.Create(AOwner);
  try
    frm.FormStyle := fsNormal;   // dentro de modal no usamos StayOnTop
    frm.SetArticuloSku(ACodArt, ACodSku);
    frm.ShowModal;
    Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

end.

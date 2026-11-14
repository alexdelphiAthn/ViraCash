{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoTicketPresentacionTermica                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta los comandos puros de presentación a un ticket térmico ESC/POS.   }
{******************************************************************************}
unit inLibArqueoTicketPresentacionTermica;

interface

uses
  inLibFTicket,
  inLibArqueoTicketPresentacion;

procedure RenderizarPresentacionTicketArqueo(
  ATicket: TTicketTermico;
  const APresentacion: TPresentacionTicketArqueo);

implementation

function ConvertirAlineacion(
  AAlineacion: TAlineacionPresentacionTicket): TAlineacion;
begin
  case AAlineacion of
    aptIzquierda:
      Result := alIzquierda;
    aptCentro:
      Result := alCentro;
    aptDerecha:
      Result := alDerecha;
  else
    Result := alIzquierda;
  end;
end;

procedure RenderizarComando(
  ATicket: TTicketTermico;
  const AComando: TComandoPresentacionTicket);
begin
  case AComando.Tipo of
    tcptAlinear:
      ATicket.Alinear(ConvertirAlineacion(AComando.Alineacion));
    tcptNegrita:
      ATicket.Negrita(AComando.Activar);
    tcptLinea:
      ATicket.EscribirLinea(AComando.Texto);
    tcptColumnas:
      ATicket.TextoColumnas(AComando.Texto, AComando.TextoDerecha);
    tcptSeparador:
      ATicket.LineaSeparadora(AComando.Caracter);
    tcptSalto:
      ATicket.SaltarLineas(AComando.Cantidad);
    tcptCorte:
      ATicket.CortarPapel;
  end;
end;

procedure RenderizarPresentacionTicketArqueo(
  ATicket: TTicketTermico;
  const APresentacion: TPresentacionTicketArqueo);
var
  iComando: Integer;
begin
  iComando := 0;
  while iComando < Length(APresentacion) do
  begin
    RenderizarComando(ATicket, APresentacion[iComando]);
    Inc(iComando);
  end;
end;

end.

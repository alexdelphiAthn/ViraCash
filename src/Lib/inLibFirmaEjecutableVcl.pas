{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFirmaEjecutableVcl                                       }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Al arrancar, comprueba en segundo plano que el propio ejecutable lleva    }
{    la firma EV de Alejandro Laorden Hidalgo (inLibFirmaEjecutable). Si no,   }
{    lo deja en el log y avisa, sin impedir el uso. Una compilación sin        }
{    firmar dentro del árbol de fuentes (desarrollo) solo va al log.           }
{******************************************************************************}
unit inLibFirmaEjecutableVcl;

interface

uses
  inLibLogIntf;

// Lanza la comprobación y vuelve enseguida: el resultado llega al hilo
// principal cuando esté (hashear el ejecutable lleva unas décimas).
procedure ComprobarFirmaEjecutableAlArrancar(
  const ARegistroLog: IRegistroLog);

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Threading,
  Vcl.Dialogs,
  Vcl.Forms,
  inLibFirmaEjecutable,
  inLibMensajesVcl,
  inLibMsgComun;

procedure AtenderResultadoFirma(
  const ARegistroLog: IRegistroLog;
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable);
var
  sTexto: string;
begin
  if AResultado.Correcta then
  begin
    if Assigned(ARegistroLog) then
      ARegistroLog.RegistrarInformacion(
        'Firma del ejecutable correcta: ' + AResultado.Titular + ' (EV).');
  end
  else
  begin
    sTexto := TextoFirmaEjecutable(ARuta, AResultado);
    if Assigned(ARegistroLog) then
      ARegistroLog.RegistrarAviso('Firma del ejecutable: ' + sTexto);
    if DebeAvisarFirma(ARuta, AResultado) and
       not Application.Terminated then
      MessageDlg_fza(
        Format(SAvisoFirmaEjecutable, [sTexto]),
        mtWarning,
        [mbOk],
        0);
  end;
end;

procedure ComprobarFirmaEjecutableAlArrancar(
  const ARegistroLog: IRegistroLog);
var
  RegistroLog: IRegistroLog;
  sRuta: string;
begin
  RegistroLog := ARegistroLog;
  sRuta := ParamStr(0);
  TTask.Run(
    procedure
    var
      Resultado: TResultadoFirmaEjecutable;
    begin
      // ComprobarFirmaEjecutable no lanza: lo que falla viene en Estado.
      Resultado := ComprobarFirmaEjecutable(sRuta);
      TThread.Queue(
        nil,
        procedure
        begin
          AtenderResultadoFirma(RegistroLog, sRuta, Resultado);
        end);
    end);
end;

end.

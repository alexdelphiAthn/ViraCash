{******************************************************************************}
{                                                                              }
{  Módulo:       VentasVisor                                                   }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Apertura del PDF privado mediante el visor instalado en el dispositivo.   }
{******************************************************************************}
unit VentasVisor;

interface

uses
  System.SysUtils;

function AbrirTicketVenta(const AContenido: TBytes;
  out AError: string): Boolean;

implementation

uses
  System.IOUtils, System.DateUtils, VentasTicket, TraduccionMovil
  {$IFDEF ANDROID}
  , Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.App,
  Androidapi.JNI.Net, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Support
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

// Textos en español; Tr los traduce al idioma del dispositivo (TextosVentas).
const
  STicketSinVisor = 'No se ha encontrado una aplicación para abrir PDF. ' +
    'Instala un visor de PDF y vuelve a intentarlo.';
  STicketAbrirError = 'No se pudo preparar o abrir el ticket PDF.';
  STicketPlataforma = 'Consulta este ticket desde la web de ventas.';

function PrepararDirectorioTickets: string;
var
  sArchivo: string;
begin
  Result := TPath.Combine(TPath.GetCachePath, 'ViraCashVentasTickets');
  TDirectory.CreateDirectory(Result);
  // Se conservan unas horas para que el visor externo termine de leerlos.
  // No se reutilizan: cada apertura vuelve a validar la clave en el servidor.
  for sArchivo in TDirectory.GetFiles(Result, 'ticket_*.pdf') do
    if TFile.GetLastWriteTimeUtc(sArchivo) <
       IncHour(TTimeZone.Local.ToUniversalTime(Now), -8) then
      TFile.Delete(sArchivo);
end;

{$IFDEF ANDROID}
function MostrarEnVisor(const ARuta: string): Boolean;
var
  oArchivo: JFile;
  oUri: Jnet_Uri;
  oIntento: JIntent;
  sAutoridad: string;
begin
  oArchivo := TJFile.JavaClass.init(StringToJString(ARuta));
  sAutoridad := JStringToString(TAndroidHelper.Context.getPackageName) +
    '.tickets.fileprovider';
  oUri := TJcontent_FileProvider.JavaClass.getUriForFile(
    TAndroidHelper.Context, StringToJString(sAutoridad), oArchivo);
  oIntento := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
  oIntento.setDataAndType(oUri, StringToJString('application/pdf'));
  oIntento.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  Result := oIntento.resolveActivity(
    TAndroidHelper.Context.getPackageManager) <> nil;
  if Result then
    TAndroidHelper.Activity.startActivity(oIntento);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function MostrarEnVisor(const ARuta: string): Boolean;
begin
  Result := NativeInt(ShellExecute(0, 'open', PChar(ARuta), nil,
    nil, SW_SHOWNORMAL)) > 32;
end;
{$ENDIF}

function AbrirTicketVenta(const AContenido: TBytes;
  out AError: string): Boolean;
{$IF Defined(ANDROID) or Defined(MSWINDOWS)}
var
  sDirectorio: string;
  sRuta: string;
{$ENDIF}
begin
  Result := False;
  AError := '';
  {$IF Defined(ANDROID) or Defined(MSWINDOWS)}
  try
    if (Length(AContenido) < 5) or
       (Length(AContenido) > cMaximoTicketVenta) then
      AError := Tr(STicketAbrirError)
    else
    begin
      sDirectorio := PrepararDirectorioTickets;
      sRuta := TPath.Combine(sDirectorio,
        'ticket_' + TGUID.NewGuid.ToString + '.pdf');
      TFile.WriteAllBytes(sRuta, AContenido);
      Result := MostrarEnVisor(sRuta);
      if not Result then
      begin
        AError := Tr(STicketSinVisor);
        TFile.Delete(sRuta);
      end;
    end;
  except
    on E: Exception do
      AError := Tr(STicketAbrirError);
  end;
  {$ELSE}
  AError := Tr(STicketPlataforma);
  {$ENDIF}
end;

end.

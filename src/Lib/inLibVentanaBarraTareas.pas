{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentanaBarraTareas                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Botón propio en la barra de tareas para una ventana del mismo exe.        }
{                                                                              }
{    Windows agrupa los botones por identificador de aplicación              }
{    (AppUserModelID), igual para todo vcash.exe. Dando a la ventana uno      }
{    distinto (propiedad PKEY_AppUserModel_ID del almacén de propiedades de   }
{    la ventana) se trata como otra aplicación: botón independiente, con el    }
{    icono de la ventana, aunque la barra combine botones. La ventana tiene    }
{    que tener botón (WS_EX_APPWINDOW) y la propiedad debe quitarse antes de   }
{    destruir la ventana (documentación de SHGetPropertyStoreForWindow).       }
{                                                                              }
{    El icono se toma de los PNG de IconosMenu.res (<RECURSO>_16/_32/_48).     }
{******************************************************************************}
unit inLibVentanaBarraTareas;

interface

uses
  Winapi.Windows;

/// Asigna a la ventana un identificador de aplicación propio (botón
/// separado en la barra de tareas). Llamar tras crear el manejador.
procedure AsignarGrupoBarraTareas(AVentana: HWND; const AIdentificador: string);
/// Quita el identificador. Llamar antes de destruir el manejador.
procedure QuitarGrupoBarraTareas(AVentana: HWND);
/// Pone como iconos grande y pequeño de la ventana los PNG del recurso
/// indicado (<ARecurso>_48 o _32 y <ARecurso>_16). Libera los anteriores
/// que puso esta misma función.
procedure AsignarIconoVentanaDesdePng(AVentana: HWND; const ARecurso: string);
/// Libera los iconos puestos con AsignarIconoVentanaDesdePng.
procedure LiberarIconoVentana(AVentana: HWND);
/// Crea un icono con el PNG del recurso indicado, con su sufijo de
/// tamano (<RECURSO>_32). El llamante se queda con el manejador; si se
/// asigna a TIcon.Handle, lo libera el propio TIcon.
function IconoDesdeRecursoPng(const ANombre: string): HICON;

implementation

uses
  System.SysUtils, System.Classes, Winapi.Messages, Winapi.ActiveX,
  Winapi.ShellAPI, Winapi.PropSys, Winapi.PropKey, Winapi.GDIPAPI,
  Winapi.GDIPOBJ, Vcl.AxCtrls;

function EscribirIdentificador(AVentana: HWND; const AIdentificador: string;
  AQuitar: Boolean): Boolean;
var
  pAlmacen: Pointer;
  Almacen: IPropertyStore;
  Valor: TPropVariant;
begin
  Result := False;
  pAlmacen := nil;
  if (AVentana = 0) or
     Failed(SHGetPropertyStoreForWindow(AVentana, IPropertyStore, pAlmacen)) then
    Exit;
  // SHGetPropertyStoreForWindow devuelve la referencia ya contada.
  Pointer(Almacen) := pAlmacen;
  if AQuitar then
    PropVariantInit(Valor)
  else if Failed(InitPropVariantFromString(PChar(AIdentificador), Valor)) then
    Exit;
  try
    Result := Succeeded(Almacen.SetValue(PKEY_AppUserModel_ID, Valor)) and
      Succeeded(Almacen.Commit);
  finally
    PropVariantClear(Valor);
  end;
end;

procedure AsignarGrupoBarraTareas(AVentana: HWND; const AIdentificador: string);
begin
  EscribirIdentificador(AVentana, AIdentificador, False);
end;

procedure QuitarGrupoBarraTareas(AVentana: HWND);
begin
  EscribirIdentificador(AVentana, '', True);
end;

function IconoDesdeRecursoPng(const ANombre: string): HICON;
var
  oRecurso: TResourceStream;
  oFlujo: IStream;
  oImagen: TGPBitmap;
begin
  Result := 0;
  if FindResource(HInstance, PChar(ANombre), RT_RCDATA) = 0 then
    Exit;
  oRecurso := TResourceStream.Create(HInstance, ANombre, RT_RCDATA);
  try
    oFlujo := TStreamAdapter.Create(oRecurso, soReference);
    oImagen := TGPBitmap.Create(oFlujo);
    try
      if oImagen.GetLastStatus = Ok then
        oImagen.GetHICON(Result);
    finally
      oImagen.Free;
    end;
  finally
    oFlujo := nil;
    oRecurso.Free;
  end;
end;

procedure CambiarIcono(AVentana: HWND; ATipo: WPARAM; AIcono: HICON);
var
  hAnterior: HICON;
begin
  hAnterior := HICON(SendMessage(AVentana, WM_SETICON, ATipo, LPARAM(AIcono)));
  // Solo se destruye el anterior si lo creó esta unidad (marcado con una
  // propiedad de ventana); el de la aplicación no es nuestro.
  if (hAnterior <> 0) and (hAnterior <> AIcono) and
     (GetProp(AVentana, PChar('fzaIcono' + IntToStr(ATipo))) <> 0) then
    DestroyIcon(hAnterior);
  if AIcono <> 0 then
    SetProp(AVentana, PChar('fzaIcono' + IntToStr(ATipo)), 1)
  else
    RemoveProp(AVentana, PChar('fzaIcono' + IntToStr(ATipo)));
end;

procedure AsignarIconoVentanaDesdePng(AVentana: HWND; const ARecurso: string);
var
  hGrande, hPequeno: HICON;
begin
  if AVentana = 0 then
    Exit;
  hGrande := IconoDesdeRecursoPng(UpperCase(ARecurso) + '_48');
  if hGrande = 0 then
    hGrande := IconoDesdeRecursoPng(UpperCase(ARecurso) + '_32');
  hPequeno := IconoDesdeRecursoPng(UpperCase(ARecurso) + '_16');
  if hGrande <> 0 then
    CambiarIcono(AVentana, ICON_BIG, hGrande);
  if hPequeno <> 0 then
    CambiarIcono(AVentana, ICON_SMALL, hPequeno);
end;

procedure LiberarIconoVentana(AVentana: HWND);
begin
  if AVentana = 0 then
    Exit;
  CambiarIcono(AVentana, ICON_BIG, 0);
  CambiarIcono(AVentana, ICON_SMALL, 0);
end;

end.

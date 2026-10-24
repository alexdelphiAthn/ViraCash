{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAvisoTallasHorizontalVcl                                 }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Aviso de los artículos con más tallas de las que caben en una rejilla     }
{    en horizontal (FZ-ISSUE-405). Las rejillas calculan sus columnas          }
{    mientras se cargan o se pintan, donde no se puede abrir un diálogo: el    }
{    aviso se anota y sale después, una sola vez por artículo y pantalla, con  }
{    todos los artículos anotados juntos.                                      }
{******************************************************************************}
unit inLibAvisoTallasHorizontalVcl;

interface

type
  IAvisoTallasHorizontal = interface
    ['{6C0B6E0F-6A3B-4C5B-9D0A-3D7B6A4B5E41}']
    procedure Anotar(const AArticulo: string; ATallas, AMaximo: Integer);
  end;

function CrearAvisoTallasHorizontal: IAvisoTallasHorizontal;

implementation

uses
  System.Classes, System.SysUtils, System.UITypes, Vcl.Dialogs,
  inLibMensajesVcl, inLibMsgArticulos;

const
  MAX_ARTICULOS_EN_AVISO = 8;

type
  TAvisoTallasHorizontal = class(TInterfacedObject, IAvisoTallasHorizontal)
  private
    FAvisados: TStringList;
    FPendientes: TStringList;
    FMaximo: Integer;
    FEnCola: Boolean;
    procedure Mostrar;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Anotar(const AArticulo: string; ATallas, AMaximo: Integer);
  end;

function CrearAvisoTallasHorizontal: IAvisoTallasHorizontal;
begin
  Result := TAvisoTallasHorizontal.Create;
end;

constructor TAvisoTallasHorizontal.Create;
begin
  inherited Create;
  FAvisados := TStringList.Create;
  FPendientes := TStringList.Create;
end;

destructor TAvisoTallasHorizontal.Destroy;
begin
  FreeAndNil(FPendientes);
  FreeAndNil(FAvisados);
  inherited;
end;

procedure TAvisoTallasHorizontal.Anotar(const AArticulo: string;
  ATallas, AMaximo: Integer);
var
  oMostrar: TThreadProcedure;
  oVida: IAvisoTallasHorizontal;
begin
  if FAvisados.IndexOf(AArticulo) < 0 then
  begin
    FAvisados.Add(AArticulo);
    FPendientes.Add(Format(SAvisoTallasHorizontalArticulo,
      [AArticulo, ATallas]));
    FMaximo := AMaximo;
    if not FEnCola then
    begin
      FEnCola := True;
      // La cola guarda una referencia: la pantalla puede cerrarse antes
      // de que salga el aviso.
      oVida := Self;
      oMostrar :=
        procedure
        begin
          if Assigned(oVida) then
            Mostrar;
        end;
      TThread.ForceQueue(nil, oMostrar);
    end;
  end;
end;

procedure TAvisoTallasHorizontal.Mostrar;
var
  i: Integer;
  sLista: string;
begin
  sLista := '';
  for i := 0 to FPendientes.Count - 1 do
    if i < MAX_ARTICULOS_EN_AVISO then
    begin
      if sLista <> '' then
        sLista := sLista + ', ';
      sLista := sLista + FPendientes[i];
    end;
  if FPendientes.Count > MAX_ARTICULOS_EN_AVISO then
    sLista := Format(SAvisoTallasHorizontalYMas,
      [sLista, FPendientes.Count - MAX_ARTICULOS_EN_AVISO]);
  FPendientes.Clear;
  FEnCola := False;
  MessageDlg_fza(Format(SAvisoTallasHorizontalRecortadas,
    [FMaximo, sLista]), mtWarning, [mbOK], 0);
end;

end.

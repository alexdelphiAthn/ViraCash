{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorTareasMto                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona tareas en segundo plano y el overlay de los mantenimientos.      }
{******************************************************************************}
unit inLibGestorTareasMto;

interface

uses
  System.SysUtils, System.Threading, System.Generics.Collections,
  Vcl.Forms, Vcl.ExtCtrls, inLibLogIntf;

type
  TConsultarCierreAplicacionMto = function: Boolean of object;

  TGestorTareasMto = class
  private
    FFormulario: TForm;
    FOverlay: TPanel;
    FBloqueos: Integer;
    FTareas: TList<ITask>;
    FConsultarCierre: TConsultarCierreAplicacionMto;
    FEstado: IInterface;
    FRegistroLog: IRegistroLog;
    function AplicacionCerrando: Boolean;
    function GetCantidadTareas: Integer;
    function GetEnDestruccion: Boolean;
    procedure CrearOverlay;
  public
    constructor Create(
      AFormulario: TForm;
      AConsultarCierre: TConsultarCierreAplicacionMto;
      const ARegistroLog: IRegistroLog = nil);
    destructor Destroy; override;
    procedure Bloquear(ABloquear: Boolean);
    procedure Ejecutar(
      AAccion: TProc;
      AAlTerminar: TProc<string>);
    function EsperarFinalizacion(
      ACancelar: TProc;
      ACierreAplicacion: Boolean): Boolean;
    property Overlay: TPanel read FOverlay;
    property Bloqueos: Integer read FBloqueos;
    property CantidadTareas: Integer read GetCantidadTareas;
    property EnDestruccion: Boolean read GetEnDestruccion;
  end;

implementation

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Graphics, inLibMsgComun, inLibRegistroLogNulo;

type
  IEstadoTareasMto = interface
    ['{E7B54B8D-972A-4782-9AF6-1EDE1BE1ED65}']
    function GetDestruyendo: Boolean;
    procedure MarcarDestruyendo;
    property Destruyendo: Boolean read GetDestruyendo;
  end;

  TEstadoTareasMto = class(
    TInterfacedObject, IEstadoTareasMto)
  private
    FDestruyendo: Boolean;
    function GetDestruyendo: Boolean;
  public
    procedure MarcarDestruyendo;
  end;

function TEstadoTareasMto.GetDestruyendo: Boolean;
begin
  Result := FDestruyendo;
end;

procedure TEstadoTareasMto.MarcarDestruyendo;
begin
  FDestruyendo := True;
end;

constructor TGestorTareasMto.Create(
  AFormulario: TForm;
  AConsultarCierre: TConsultarCierreAplicacionMto;
  const ARegistroLog: IRegistroLog);
var
  oEstado: IEstadoTareasMto;
begin
  inherited Create;
  FFormulario := AFormulario;
  FOverlay := nil;
  FBloqueos := 0;
  FTareas := nil;
  FConsultarCierre := AConsultarCierre;
  FRegistroLog := ARegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
  oEstado := TEstadoTareasMto.Create;
  FEstado := oEstado;
end;

destructor TGestorTareasMto.Destroy;
begin
  (FEstado as IEstadoTareasMto).MarcarDestruyendo;
  FreeAndNil(FTareas);
  FreeAndNil(FOverlay);
  FEstado := nil;
  FRegistroLog := nil;
  inherited;
end;

function TGestorTareasMto.AplicacionCerrando: Boolean;
begin
  Result := False;
  if Assigned(FConsultarCierre) then
    Result := FConsultarCierre;
end;

function TGestorTareasMto.GetCantidadTareas: Integer;
begin
  Result := 0;
  if Assigned(FTareas) then
    Result := FTareas.Count;
end;

function TGestorTareasMto.GetEnDestruccion: Boolean;
begin
  Result :=
    (FEstado as IEstadoTareasMto).Destruyendo;
end;

procedure TGestorTareasMto.CrearOverlay;
var
  oTexto: TLabel;
  oBarra: TProgressBar;
begin
  FOverlay := TPanel.Create(FFormulario);
  FOverlay.Parent := FFormulario;
  FOverlay.SetBounds(
    0, 0, FFormulario.ClientWidth,
    FFormulario.ClientHeight);
  FOverlay.Anchors :=
    [akLeft, akTop, akRight, akBottom];
  FOverlay.BevelOuter := bvNone;
  FOverlay.Color := $00F5E6CC;
  FOverlay.ParentBackground := False;
  FOverlay.Caption := '';
  oTexto := TLabel.Create(FOverlay);
  oTexto.Parent := FOverlay;
  oTexto.AutoSize := False;
  oTexto.SetBounds(
    0, (FOverlay.ClientHeight div 2) - 40,
    FOverlay.ClientWidth, 30);
  oTexto.Anchors := [akLeft, akTop, akRight];
  oTexto.Alignment := taCenter;
  oTexto.Layout := tlCenter;
  oTexto.Caption := SCaptionCargandoDatosEspere;
  oTexto.Font.Style := [fsBold];
  oTexto.Font.Size := 11;
  oTexto.Font.Color := clNavy;
  oTexto.Transparent := True;
  oBarra := TProgressBar.Create(FOverlay);
  oBarra.Parent := FOverlay;
  oBarra.SetBounds(
    (FOverlay.ClientWidth div 2) - 150,
    (FOverlay.ClientHeight div 2) + 5,
    300, 18);
  oBarra.Anchors := [];
  oBarra.Style := pbstMarquee;
  oBarra.MarqueeInterval := 30;
end;

procedure TGestorTareasMto.Bloquear(
  ABloquear: Boolean);
begin
  if ABloquear then
  begin
    Inc(FBloqueos);
    if not Assigned(FOverlay) then
      CrearOverlay;
    FOverlay.SetBounds(
      0, 0, FFormulario.ClientWidth,
      FFormulario.ClientHeight);
    FOverlay.BringToFront;
    FOverlay.Visible := True;
    FFormulario.Cursor := crHourGlass;
  end
  else
  begin
    if FBloqueos > 0 then
      Dec(FBloqueos);
    if (FBloqueos = 0) and
       Assigned(FOverlay) then
    begin
      FOverlay.Visible := False;
      FFormulario.Cursor := crDefault;
    end;
  end;
end;

procedure TGestorTareasMto.Ejecutar(
  AAccion: TProc;
  AAlTerminar: TProc<string>);
var
  oTarea: ITask;
  oEstado: IEstadoTareasMto;
begin
  if Assigned(AAccion) and
     not AplicacionCerrando and
     not GetEnDestruccion then
  begin
    if not Assigned(FTareas) then
      FTareas := TList<ITask>.Create;
    Bloquear(True);
    oEstado := FEstado as IEstadoTareasMto;
    try
      oTarea := TTask.Run(
        procedure
        var
          sError: string;
        begin
          sError := '';
          try
            AAccion();
          except
            on E: Exception do
            begin
              FRegistroLog.RegistrarError(
                '[EjecutarEnBackground] ' +
                E.ClassName + ': ' + E.Message);
              sError := E.Message;
              if sError = '' then
                sError := E.ClassName;
            end;
          end;
          TThread.Queue(nil,
            procedure
            begin
              try
                if not oEstado.Destruyendo then
                begin
                  if Assigned(FTareas) then
                    FTareas.Remove(oTarea);
                  if not (
                    csDestroying in
                    FFormulario.ComponentState) then
                  begin
                    try
                      if Assigned(AAlTerminar) then
                        AAlTerminar(sError);
                    finally
                      Bloquear(False);
                    end;
                  end;
                end;
              except
                on E: Exception do
                  FRegistroLog.RegistrarError(
                    '[EjecutarEnBackground.AlTerminar] ' +
                    E.ClassName + ': ' + E.Message);
              end;
            end);
        end);
      FTareas.Add(oTarea);
    except
      Bloquear(False);
      raise;
    end;
  end;
end;

function TGestorTareasMto.EsperarFinalizacion(
  ACancelar: TProc;
  ACierreAplicacion: Boolean): Boolean;
var
  iEsperaMs: Integer;
begin
  (FEstado as IEstadoTareasMto).MarcarDestruyendo;
  Result := False;
  if Assigned(FTareas) then
  begin
    try
      if FTareas.Count > 0 then
      begin
        if Assigned(ACancelar) then
          ACancelar();
        if ACierreAplicacion then
          iEsperaMs := 15000
        else
          iEsperaMs := 5000;
        Result := not TTask.WaitForAll(
          FTareas.ToArray, iEsperaMs);
      end;
    except
      Result := False;
    end;
    FreeAndNil(FTareas);
  end;
end;

end.

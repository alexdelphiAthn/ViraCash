{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteCompraValidacion                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación del documento y resolución de colores del pivote de compra.   }
{******************************************************************************}
unit inLibPivoteCompraValidacion;

interface

uses
  System.SysUtils,
  inLibGridPivoteCompraTipos,
  inLibGridPivoteCompraPersistenciaIntf,
  inLibPivoteCompraCorrespondencia;

type
  TValidadorPivoteCompra = class
  private
    FCfg            : TGridPivoteCompraConfig;
    FRepositorio    : TRepositoriosGridPivoteCompra;
    FCorrespondencia: TCorrespondenciaPivoteCompra;
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig;
      const ARepositorio: TRepositoriosGridPivoteCompra;
      ACorrespondencia: TCorrespondenciaPivoteCompra);
    function Validar(var AMensaje: string): Boolean;
    function ResolverColorBasico(const ACodigoAtbColor, AVariacion: string;
      out AIdAv: Integer; out AValorAv, ANombreColor,
      AMensaje: string): Boolean;
  end;

implementation

uses
  System.Classes,
  Data.DB,
  inLibMsgArticulos, inLibMsgCompras;

constructor TValidadorPivoteCompra.Create(
  const ACfg: TGridPivoteCompraConfig;
  const ARepositorio: TRepositoriosGridPivoteCompra;
  ACorrespondencia: TCorrespondenciaPivoteCompra);
begin
  inherited Create;
  FCfg := ACfg;
  FRepositorio := ARepositorio;
  FCorrespondencia := ACorrespondencia;
end;

function TValidadorPivoteCompra.Validar(var AMensaje: string): Boolean;
var
  oConsulta    : TDataSet;
  oIncidencias : TStringList;
  sSerie       : string;
  sNumero      : string;
begin
  Result := True;
  AMensaje := '';
  if FCorrespondencia.ObtenerSerieNumero(sSerie, sNumero) then
  begin
    oIncidencias := TStringList.Create;
    oConsulta := nil;
    try
      oConsulta := FRepositorio.Validacion.BuscarArticulosSinSistema(
        sSerie, sNumero);
      while not oConsulta.Eof do
      begin
        oIncidencias.Add(Format(SErrorArticuloSinSistemaTallasPivote,
          [oConsulta.FieldByName('ART').AsString]));
        oConsulta.Next;
      end;
      FreeAndNil(oConsulta);
      oConsulta := FRepositorio.Validacion.BuscarSistemasConExceso(
        sSerie, sNumero);
      while not oConsulta.Eof do
      begin
        oIncidencias.Add(Format(SErrorSistemaTallasSuperaMaximoPivote,
          [oConsulta.FieldByName('ART').AsString,
           oConsulta.FieldByName('SISTEMA').AsString,
           oConsulta.FieldByName('N').AsInteger,
           FCfg.MaxColumnasTallas]));
        oConsulta.Next;
      end;
      if oIncidencias.Count > 0 then
      begin
        AMensaje := Format(SErrorActivarPivoteTallas,
          [oIncidencias.Text]);
        Result := False;
      end;
    finally
      FreeAndNil(oConsulta);
      FreeAndNil(oIncidencias);
    end;
  end;
end;

function TValidadorPivoteCompra.ResolverColorBasico(
  const ACodigoAtbColor, AVariacion: string; out AIdAv: Integer;
  out AValorAv, ANombreColor, AMensaje: string): Boolean;
var
  iIdBasico    : Integer;
  sCodigo      : string;
  bTieneBasico : Boolean;
begin
  Result := False;
  AIdAv := 0;
  AValorAv := '';
  ANombreColor := '';
  AMensaje := '';
  sCodigo := Trim(ACodigoAtbColor);
  if sCodigo = '' then
    AMensaje := SErrorColorCompraNoSeleccionado
  else if FCfg.Conexion = nil then
    AMensaje := SErrorConexionResolverColorCompra
  else if not FRepositorio.Colores.BuscarColorBasico(
    sCodigo, iIdBasico, ANombreColor, AVariacion) then
    AMensaje := Format(SErrorColorBasicoCompraNoExiste, [sCodigo])
  else
  begin
    AValorAv := sCodigo;
    if FRepositorio.Colores.BuscarValorColor(
      AValorAv, AIdAv, bTieneBasico, AVariacion) then
    begin
      if (not bTieneBasico) and (iIdBasico > 0) then
        FRepositorio.Colores.VincularValorColor(
          AIdAv, iIdBasico,
          FCfg.ContextoSesion.Identidad.Usuario);
    end
    else
      AIdAv := FRepositorio.Colores.InsertarValorColor(
        AValorAv, ANombreColor,
        FCfg.ContextoSesion.Identidad.Usuario, iIdBasico, AVariacion);
    Result := AIdAv > 0;
    if not Result then
      AMensaje := Format(SErrorResolverColorCompra, [sCodigo]);
  end;
end;

end.

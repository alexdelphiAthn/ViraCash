{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArqueoBitacora                                         }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura de los partes meteorológicos (fza_almacenes_meteorologia) y de    }
{    los apuntes del cuaderno de bitácora (fza_almacenes_observaciones) de     }
{    los días de un arqueo. Solo lee: no crea ni modifica nada.                }
{******************************************************************************}
unit UniDataArqueoBitacora;

interface

uses
  Uni, inLibArqueoBitacora;

function CrearRepositorioBitacoraArqueo(
  AConexion: TUniConnection): IRepositorioBitacoraArqueo;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Data.DB, inLibMeteorologiaCajaIntf;

type
  TRepositorioBitacoraArqueo = class(TInterfacedObject,
    IRepositorioBitacoraArqueo)
  private
    FConexion: TUniConnection;
    function ExisteTabla(AConsulta: TUniQuery;
      const ATabla: string): Boolean;
    procedure AbrirRango(AConsulta: TUniQuery; const ASql: string;
      const AEmpresa, AAlmacen: string; ADesde, AHasta: TDateTime);
    procedure LeerMeteorologia(AConsulta: TUniQuery;
      ADias: TDictionary<string, TDiaBitacoraArqueo>);
    procedure LeerApuntes(AConsulta: TUniQuery;
      ADias: TDictionary<string, TDiaBitacoraArqueo>);
  public
    constructor Create(AConexion: TUniConnection);
    function ListarDiasBitacora(const AEmpresa, AAlmacen: string;
      ADesde, AHasta: TDateTime): TDiasBitacoraArqueo;
  end;

function SqlExisteTabla: string;
begin
  Result :=
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES' +
    ' WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :TABLA';
end;

function SqlMeteorologia: string;
begin
  Result :=
    'SELECT CODIGO_ALM_ALMET, FECHA_ALMET, CIUDAD_ALMET,' +
    ' VALOR_TEMPERATURA_ALMET, VALOR_MINIMA_ALMET, VALOR_MAXIMA_ALMET,' +
    ' PORCENTAJE_NUBES_ALMET, VALOR_LLUVIA_PREVISTA_ALMET' +
    ' FROM fza_almacenes_meteorologia' +
    ' WHERE CODIGO_EMP_ALMET = :EMPRESA' +
    ' AND (:ALMACEN = '''' OR CODIGO_ALM_ALMET = :ALMACEN)' +
    ' AND FECHA_ALMET >= :DESDE AND FECHA_ALMET <= :HASTA';
end;

function SqlApuntes: string;
begin
  Result :=
    'SELECT CODIGO_ALM_ALOB, FECHA_ALOB, OBSERVACIONES_ALOB' +
    ' FROM fza_almacenes_observaciones' +
    ' WHERE CODIGO_EMP_ALOB = :EMPRESA' +
    ' AND (:ALMACEN = '''' OR CODIGO_ALM_ALOB = :ALMACEN)' +
    ' AND FECHA_ALOB >= :DESDE AND FECHA_ALOB <= :HASTA';
end;

function ClaveDia(const AAlmacen: string; AFecha: TDateTime): string;
begin
  Result := UpperCase(Trim(AAlmacen)) + '|' +
    FormatDateTime('yyyymmdd', AFecha);
end;

function LeerValor(ACampo: TField): TValorMeteorologiaCaja;
begin
  Result.TieneValor := not ACampo.IsNull;
  Result.Valor := 0;
  if Result.TieneValor then
    Result.Valor := ACampo.AsFloat;
end;

function CrearRepositorioBitacoraArqueo(
  AConexion: TUniConnection): IRepositorioBitacoraArqueo;
begin
  Result := TRepositorioBitacoraArqueo.Create(AConexion);
end;

constructor TRepositorioBitacoraArqueo.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioBitacoraArqueo.ExisteTabla(AConsulta: TUniQuery;
  const ATabla: string): Boolean;
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlExisteTabla;
  AConsulta.ParamByName('TABLA').AsString := ATabla;
  AConsulta.Open;
  Result := AConsulta.FieldByName('N').AsInteger = 1;
  AConsulta.Close;
end;

procedure TRepositorioBitacoraArqueo.AbrirRango(AConsulta: TUniQuery;
  const ASql: string; const AEmpresa, AAlmacen: string;
  ADesde, AHasta: TDateTime);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := ASql;
  AConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
  AConsulta.ParamByName('ALMACEN').AsString := Trim(AAlmacen);
  AConsulta.ParamByName('DESDE').AsDate := Trunc(ADesde);
  AConsulta.ParamByName('HASTA').AsDate := Trunc(AHasta);
  AConsulta.Open;
end;

procedure TRepositorioBitacoraArqueo.LeerMeteorologia(AConsulta: TUniQuery;
  ADias: TDictionary<string, TDiaBitacoraArqueo>);
var
  oDia: TDiaBitacoraArqueo;
  sClave: string;
begin
  while not AConsulta.Eof do
  begin
    oDia := Default(TDiaBitacoraArqueo);
    oDia.Almacen := AConsulta.FieldByName('CODIGO_ALM_ALMET').AsString;
    oDia.Fecha := Trunc(AConsulta.FieldByName('FECHA_ALMET').AsDateTime);
    sClave := ClaveDia(oDia.Almacen, oDia.Fecha);
    oDia.TieneMeteorologia := True;
    oDia.Ciudad := AConsulta.FieldByName('CIUDAD_ALMET').AsString;
    oDia.Temperatura := LeerValor(
      AConsulta.FieldByName('VALOR_TEMPERATURA_ALMET'));
    oDia.Minima := LeerValor(AConsulta.FieldByName('VALOR_MINIMA_ALMET'));
    oDia.Maxima := LeerValor(AConsulta.FieldByName('VALOR_MAXIMA_ALMET'));
    oDia.Nubes := LeerValor(
      AConsulta.FieldByName('PORCENTAJE_NUBES_ALMET'));
    oDia.Lluvia := LeerValor(
      AConsulta.FieldByName('VALOR_LLUVIA_PREVISTA_ALMET'));
    ADias.AddOrSetValue(sClave, oDia);
    AConsulta.Next;
  end;
end;

procedure TRepositorioBitacoraArqueo.LeerApuntes(AConsulta: TUniQuery;
  ADias: TDictionary<string, TDiaBitacoraArqueo>);
var
  oDia: TDiaBitacoraArqueo;
  sAlmacen: string;
  sClave: string;
  dFecha: TDateTime;
begin
  while not AConsulta.Eof do
  begin
    sAlmacen := AConsulta.FieldByName('CODIGO_ALM_ALOB').AsString;
    dFecha := Trunc(AConsulta.FieldByName('FECHA_ALOB').AsDateTime);
    sClave := ClaveDia(sAlmacen, dFecha);
    if not ADias.TryGetValue(sClave, oDia) then
    begin
      oDia := Default(TDiaBitacoraArqueo);
      oDia.Almacen := sAlmacen;
      oDia.Fecha := dFecha;
    end;
    oDia.Apuntes := AConsulta.FieldByName('OBSERVACIONES_ALOB').AsString;
    ADias.AddOrSetValue(sClave, oDia);
    AConsulta.Next;
  end;
end;

function TRepositorioBitacoraArqueo.ListarDiasBitacora(
  const AEmpresa, AAlmacen: string;
  ADesde, AHasta: TDateTime): TDiasBitacoraArqueo;
var
  oConsulta: TUniQuery;
  oDias: TDictionary<string, TDiaBitacoraArqueo>;
begin
  Result := nil;
  if Assigned(FConexion) and FConexion.Connected and
     (Trim(AEmpresa) <> '') then
  begin
    oDias := TDictionary<string, TDiaBitacoraArqueo>.Create;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      // Sin las tablas (actualización de BBDD pendiente) no hay datos que
      // mostrar; el arqueo se presenta igual, sin este bloque.
      if ExisteTabla(oConsulta, 'fza_almacenes_meteorologia') then
      begin
        AbrirRango(oConsulta, SqlMeteorologia, AEmpresa, AAlmacen,
          ADesde, AHasta);
        LeerMeteorologia(oConsulta, oDias);
      end;
      if ExisteTabla(oConsulta, 'fza_almacenes_observaciones') then
      begin
        AbrirRango(oConsulta, SqlApuntes, AEmpresa, AAlmacen,
          ADesde, AHasta);
        LeerApuntes(oConsulta, oDias);
      end;
      Result := oDias.Values.ToArray;
      TArray.Sort<TDiaBitacoraArqueo>(Result,
        TComparer<TDiaBitacoraArqueo>.Construct(
          function(const AIzquierda,
            ADerecha: TDiaBitacoraArqueo): Integer
          begin
            Result := CompareText(AIzquierda.Almacen, ADerecha.Almacen);
            if Result = 0 then
              Result := Trunc(AIzquierda.Fecha) - Trunc(ADerecha.Fecha);
          end));
    finally
      FreeAndNil(oConsulta);
      FreeAndNil(oDias);
    end;
  end;
end;

end.

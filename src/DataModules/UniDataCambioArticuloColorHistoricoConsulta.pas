{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCambioArticuloColorHistoricoConsulta                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta UniDAC de los últimos cambios de artículo y color.               }
{******************************************************************************}
unit UniDataCambioArticuloColorHistoricoConsulta;

interface

uses
  Uni,
  inLibCambioArticuloColorHistoricoConsultaIntf;

function CrearConsultaCambioArticuloColorHistoricoUniDAC(
  AConexion: TUniConnection): IConsultaCambioArticuloColorHistorico;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibMsgCambioArticuloColor;

const
  fidach = 'ID_ACH';
  fidoperacionach = 'ID_OPERACION_ACH';
  fordenach = 'ORDEN_ACH';
  ftiporegistroach = 'TIPO_REGISTRO_ACH';
  ftipooperacionach = 'TIPO_OPERACION_ACH';
  fidoperacionorigenach = 'ID_OPERACION_ORIGEN_ACH';
  festadoach = 'ESTADO_ACH';
  fcodigoorigenach = 'CODIGO_ORIGEN_ACH';
  fcodigodestinoach = 'CODIGO_DESTINO_ACH';
  fcantidadunidadesach = 'CANTIDAD_UNIDADES_ACH';
  finstantealta = 'INSTANTE_ALTA';
  fusuarioalta = 'USUARIO_ALTA';
  fesrevertida = 'ESREVERTIDA';

  RegistroOperacion = 'OPERACION';
  EstadoAplicada = 'APLICADA';
  TipoCambioArticulo = 'CAMBIO_ARTICULO';
  TipoFusionArticulo = 'FUSION_ARTICULO';
  TipoCambioColor = 'CAMBIO_COLOR';
  TipoFusionColor = 'FUSION_COLOR';
  TipoReversion = 'REVERSION';
  MaximoCambiosConsulta = 1000;

type
  TConsultaCambioArticuloColorHistoricoUniDAC = class(
    TInterfacedObject,
    IConsultaCambioArticuloColorHistorico)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function TraducirTipo(
      const AValor: string): TTipoHistoricoCambioArticuloColor;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarUltimos(
      ALimite: Integer): TCambiosArticuloColorHistorico;
  end;

constructor TConsultaCambioArticuloColorHistoricoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TConsultaCambioArticuloColorHistoricoUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TConsultaCambioArticuloColorHistoricoUniDAC.TraducirTipo(
  const AValor: string): TTipoHistoricoCambioArticuloColor;
begin
  if SameText(AValor, TipoCambioArticulo) then
    Result := thcacCambioArticulo
  else if SameText(AValor, TipoFusionArticulo) then
    Result := thcacFusionArticulo
  else if SameText(AValor, TipoCambioColor) then
    Result := thcacCambioColor
  else if SameText(AValor, TipoFusionColor) then
    Result := thcacFusionColor
  else if SameText(AValor, TipoReversion) then
    Result := thcacReversion
  else
    raise EConvertError.CreateFmt(
      SErrorTipoOperacionHistoricoDesconocido,
      [AValor]);
end;

function TConsultaCambioArticuloColorHistoricoUniDAC.ConsultarUltimos(
  ALimite: Integer): TCambiosArticuloColorHistorico;
var
  iIndice: Integer;
  iLimite: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  if ALimite > 0 then
  begin
    iLimite := ALimite;
    if iLimite > MaximoCambiosConsulta then
      iLimite := MaximoCambiosConsulta;
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT H.' + finstantealta + ', ' +
        '       H.' + ftipooperacionach + ', ' +
        '       H.' + fcodigoorigenach + ', ' +
        '       H.' + fcodigodestinoach + ', ' +
        '       H.' + fcantidadunidadesach + ', ' +
        '       H.' + fusuarioalta + ', ' +
        '       CASE ' +
        '         WHEN H.' + ftipooperacionach +
          ' <> :TIPO_REVERSION_ORIGINAL ' +
        '          AND EXISTS (' +
        '           SELECT 1 ' +
        '             FROM fza_articulos_cambios_historico R ' +
        '            WHERE R.' + fidoperacionorigenach +
          ' = H.' + fidoperacionach +
        '              AND R.' + fordenach + ' = :ORDEN_REVERSION ' +
        '              AND R.' + ftiporegistroach +
          ' = :REGISTRO_REVERSION ' +
        '              AND R.' + ftipooperacionach +
          ' = :TIPO_REVERSION ' +
        '              AND R.' + festadoach +
          ' = :ESTADO_REVERSION) ' +
        '         THEN 1 ELSE 0 ' +
        '       END AS ' + fesrevertida + ' ' +
        '  FROM fza_articulos_cambios_historico H ' +
        ' WHERE H.' + fordenach + ' = :ORDEN_OPERACION ' +
        '   AND H.' + ftiporegistroach +
          ' = :REGISTRO_OPERACION ' +
        '   AND H.' + festadoach + ' = :ESTADO_OPERACION ' +
        '   AND H.' + ftipooperacionach + ' IN (' +
        '       :TIPO_CAMBIO_ARTICULO, :TIPO_FUSION_ARTICULO, ' +
        '       :TIPO_CAMBIO_COLOR, :TIPO_FUSION_COLOR, ' +
        '       :TIPO_REVERSION_OPERACION) ' +
        ' ORDER BY H.' + finstantealta + ' DESC, ' +
        '          H.' + fidach + ' DESC ' +
        ' LIMIT :LIMITE';
      oConsulta.ParamByName('TIPO_REVERSION_ORIGINAL').AsString :=
        TipoReversion;
      oConsulta.ParamByName('ORDEN_REVERSION').AsInteger := 0;
      oConsulta.ParamByName('REGISTRO_REVERSION').AsString :=
        RegistroOperacion;
      oConsulta.ParamByName('TIPO_REVERSION').AsString := TipoReversion;
      oConsulta.ParamByName('ESTADO_REVERSION').AsString :=
        EstadoAplicada;
      oConsulta.ParamByName('ORDEN_OPERACION').AsInteger := 0;
      oConsulta.ParamByName('REGISTRO_OPERACION').AsString :=
        RegistroOperacion;
      oConsulta.ParamByName('ESTADO_OPERACION').AsString :=
        EstadoAplicada;
      oConsulta.ParamByName('TIPO_CAMBIO_ARTICULO').AsString :=
        TipoCambioArticulo;
      oConsulta.ParamByName('TIPO_FUSION_ARTICULO').AsString :=
        TipoFusionArticulo;
      oConsulta.ParamByName('TIPO_CAMBIO_COLOR').AsString :=
        TipoCambioColor;
      oConsulta.ParamByName('TIPO_FUSION_COLOR').AsString :=
        TipoFusionColor;
      oConsulta.ParamByName('TIPO_REVERSION_OPERACION').AsString :=
        TipoReversion;
      oConsulta.ParamByName('LIMITE').AsInteger := iLimite;
      oConsulta.Open;
      iIndice := 0;
      while (not oConsulta.Eof) and (iIndice < iLimite) do
      begin
        SetLength(Result, iIndice + 1);
        Result[iIndice].Instante :=
          oConsulta.FieldByName(finstantealta).AsDateTime;
        Result[iIndice].Tipo := TraducirTipo(
          oConsulta.FieldByName(ftipooperacionach).AsString);
        Result[iIndice].Origen :=
          oConsulta.FieldByName(fcodigoorigenach).AsString;
        Result[iIndice].Destino :=
          oConsulta.FieldByName(fcodigodestinoach).AsString;
        Result[iIndice].Unidades :=
          oConsulta.FieldByName(fcantidadunidadesach).AsInteger;
        Result[iIndice].Usuario :=
          oConsulta.FieldByName(fusuarioalta).AsString;
        if oConsulta.FieldByName(fesrevertida).AsInteger = 1 then
          Result[iIndice].Estado := ehcacRevertido
        else
          Result[iIndice].Estado := ehcacAplicado;
        Inc(iIndice);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearConsultaCambioArticuloColorHistoricoUniDAC(
  AConexion: TUniConnection): IConsultaCambioArticuloColorHistorico;
begin
  Result := TConsultaCambioArticuloColorHistoricoUniDAC.Create(
    AConexion);
end;

end.

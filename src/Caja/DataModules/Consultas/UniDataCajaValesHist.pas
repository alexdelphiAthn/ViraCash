{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaValesHist                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del histórico de vales de caja.                               }
{    Contenedor de consultas sobre fza_caja_vales emitidos y redimidos.        }
{******************************************************************************}
unit UniDataCajaValesHist;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmCajaValesHist = class(TdmBase)
  public
    function ConsultarSaldoVales(const AEmpresa, AFiltroEmision: string;
      ACorte: TDateTime): TUniQuery;
  end;

function AbrirSaldoVales(AConexion: TUniConnection;
  const AEmpresa, AFiltroEmision: string; ACorte: TDateTime): TUniQuery;

implementation

uses
  System.DateUtils;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function AbrirSaldoVales(AConexion: TUniConnection;
  const AEmpresa, AFiltroEmision: string; ACorte: TDateTime): TUniQuery;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    // Las redenciones antiguas pueden llevar la fecha de grabación.
    // La operación VR identifica el instante de caja de ese canje.
    oConsulta.SQL.Text :=
      'WITH VALES AS (' +
      ' SELECT V.CODIGO_VL, V.CODIGO_ALM_EMI_VL, V.FECHA_EMISION_VL,' +
      '        V.IMPORTE_NOMINAL_VL, V.ESTADO_VL,' +
      '        COALESCE((SELECT MAX(O.FECHA_OPERACION_OPCAJA)' +
      '          FROM fza_caja_operaciones O' +
      '          WHERE O.CODIGO_EMP_OPCAJA = V.CODIGO_EMP_RED_VL' +
      '            AND O.CODIGO_ALM_OPCAJA = V.CODIGO_ALM_RED_VL' +
      '            AND O.CODIGO_CAJA_OPCAJA = V.CODIGO_CAJA_RED_VL' +
      '            AND O.NUMERO_OPERACION_OPCAJA = V.NUMERO_OPERACION_RED_VL' +
      '            AND O.TIPO_OPERACION_OPCAJA = ''VR''),' +
      '          V.FECHA_REDENCION_VL) AS FECHA_CANJE' +
      ' FROM fza_caja_vales V' +
      ' WHERE V.CODIGO_EMP_EMI_VL = :EMPRESA' +
      '   AND V.FECHA_EMISION_VL < :LIMITE' +
      '   AND V.ESTADO_VL IN (''PENDIENTE'', ''REDIMIDO'')' +
      AFiltroEmision + ')' +
      ' SELECT CODIGO_VL, CODIGO_ALM_EMI_VL, FECHA_EMISION_VL,' +
      '        IMPORTE_NOMINAL_VL' +
      ' FROM VALES WHERE FECHA_CANJE >= :LIMITE' +
      '    OR (FECHA_CANJE IS NULL AND ESTADO_VL = ''PENDIENTE'')' +
      ' ORDER BY CODIGO_ALM_EMI_VL, FECHA_EMISION_VL, CODIGO_VL';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('LIMITE').AsDateTime := IncDay(DateOf(ACorte));
    oConsulta.Open;
    Result := oConsulta;
  except
    oConsulta.Free;
    raise;
  end;
end;

function TdmCajaValesHist.ConsultarSaldoVales(
  const AEmpresa, AFiltroEmision: string; ACorte: TDateTime): TUniQuery;
begin
  Result := AbrirSaldoVales(ConexionPrincipal, AEmpresa, AFiltroEmision, ACorte);
end;

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  RegistrarDataModule(TdmCajaValesHist);
  ForceReferenceToClass(TdmCajaValesHist);
end.

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
  inLibUser, UniDataConn, inLibInformeMultiFiltroPersistenciaIntf;

type
  TFiltrosSaldoVales = record
    Corte: TDateTime;
    EmisionDesde: TDateTime;
    EmisionHasta: TDateTime;
    Almacenes: TArray<string>;
  end;

  TdmCajaValesHist = class(TdmBase)
  public
    function ListarAlmacenesEmisores(const AEmpresa, AFiltroEmision: string):
      TOpcionesInformeMultiFiltro;
    function ConsultarSaldoVales(const AEmpresa, AFiltroEmision: string;
      const AFiltros: TFiltrosSaldoVales): TUniQuery;
  end;

function AbrirSaldoVales(AConexion: TUniConnection;
  const AEmpresa, AFiltroEmision: string;
  const AFiltros: TFiltrosSaldoVales): TUniQuery;

implementation

uses
  System.DateUtils;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function AbrirSaldoVales(AConexion: TUniConnection;
  const AEmpresa, AFiltroEmision: string;
  const AFiltros: TFiltrosSaldoVales): TUniQuery;
var
  bHasta: Boolean;
  iAlmacen: Integer;
  oConsulta: TUniQuery;
  sFiltros: string;
begin
  bHasta := (AFiltros.EmisionHasta <> 0) and
    (DateOf(AFiltros.EmisionHasta) < DateOf(AFiltros.Corte));
  sFiltros := AFiltroEmision;
  if AFiltros.EmisionDesde <> 0 then
    sFiltros := sFiltros + ' AND V.FECHA_EMISION_VL >= :EMISION_DESDE';
  if bHasta then
    sFiltros := sFiltros + ' AND V.FECHA_EMISION_VL < :EMISION_HASTA';
  if Length(AFiltros.Almacenes) > 0 then
  begin
    sFiltros := sFiltros + ' AND V.CODIGO_ALM_EMI_VL IN (';
    for iAlmacen := 0 to High(AFiltros.Almacenes) do
    begin
      if iAlmacen > 0 then
        sFiltros := sFiltros + ', ';
      sFiltros := sFiltros + ':ALMACEN_' + IntToStr(iAlmacen);
    end;
    sFiltros := sFiltros + ')';
  end;

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
      sFiltros + ')' +
      ' SELECT CODIGO_VL, CODIGO_ALM_EMI_VL, FECHA_EMISION_VL,' +
      '        IMPORTE_NOMINAL_VL' +
      ' FROM VALES WHERE FECHA_CANJE >= :LIMITE' +
      '    OR (FECHA_CANJE IS NULL AND ESTADO_VL = ''PENDIENTE'')' +
      ' ORDER BY CODIGO_ALM_EMI_VL, FECHA_EMISION_VL, CODIGO_VL';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('LIMITE').AsDateTime :=
      IncDay(DateOf(AFiltros.Corte));
    if AFiltros.EmisionDesde <> 0 then
      oConsulta.ParamByName('EMISION_DESDE').AsDateTime :=
        DateOf(AFiltros.EmisionDesde);
    if bHasta then
      oConsulta.ParamByName('EMISION_HASTA').AsDateTime :=
        IncDay(DateOf(AFiltros.EmisionHasta));
    for iAlmacen := 0 to High(AFiltros.Almacenes) do
      oConsulta.ParamByName('ALMACEN_' + IntToStr(iAlmacen)).AsString :=
        AFiltros.Almacenes[iAlmacen];
    oConsulta.Open;
    Result := oConsulta;
  except
    oConsulta.Free;
    raise;
  end;
end;

function TdmCajaValesHist.ListarAlmacenesEmisores(
  const AEmpresa, AFiltroEmision: string): TOpcionesInformeMultiFiltro;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionPrincipal;
    // Partir del histórico permite seleccionar también almacenes dados de baja.
    oConsulta.SQL.Text :=
      'SELECT DISTINCT V.CODIGO_ALM_EMI_VL, A.NOMBRE_ALM_ALM' +
      ' FROM fza_caja_vales V LEFT JOIN fza_almacenes A' +
      ' ON A.CODIGO_ALM_ALM = V.CODIGO_ALM_EMI_VL' +
      ' WHERE V.CODIGO_EMP_EMI_VL = :EMPRESA' + AFiltroEmision +
      ' ORDER BY V.CODIGO_ALM_EMI_VL';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_EMI_VL').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TdmCajaValesHist.ConsultarSaldoVales(
  const AEmpresa, AFiltroEmision: string;
  const AFiltros: TFiltrosSaldoVales): TUniQuery;
begin
  Result := AbrirSaldoVales(ConexionPrincipal, AEmpresa, AFiltroEmision,
    AFiltros);
end;

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  RegistrarDataModule(TdmCajaValesHist);
  ForceReferenceToClass(TdmCajaValesHist);
end.

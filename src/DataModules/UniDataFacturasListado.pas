{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasListado                                        }
{    Tipo:       Adaptador de persistencia (UniDAC)                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sentencia del listado de facturas y disponibilidad de la cola AEAT.       }
{******************************************************************************}
unit UniDataFacturasListado;

interface

uses
  Data.DB, Uni,
  inLibFacturasPresentadorListado;

const
  // Solo presentación: la fase persistida sigue siendo la del motor fiscal.
  SQL_FASE_FISCAL_LISTADO =
    'CASE WHEN c.SISTEMA_VFCOLA = ''SII'' ' +
    ' AND v.FASE_FAC LIKE ''VERIFACTU_%'' THEN ' +
    ' CASE WHEN v.FASE_FAC = ''VERIFACTU_ANULADA'' ' +
    '        THEN ''SII_ANULADA'' ' +
    '      WHEN c.ESTADO_VFCOLA = ''ENVIADA'' THEN ''SII_OK'' ' +
    '      WHEN c.ESTADO_VFCOLA = ''ERROR'' THEN ''SII_ERROR'' ' +
    '      ELSE ''SII_PENDIENTE'' END ' +
    ' ELSE v.FASE_FAC END AS FASE_PRESENTACION_FAC, ';
  SQL_ENLACE_COLA_LISTADO =
    ' LEFT JOIN fza_verifactu_cola c ON c.ID_VFCOLA = (' +
    ' SELECT MAX(uc.ID_VFCOLA) FROM fza_verifactu_cola uc ' +
    ' WHERE uc.SERIE_FAC_VFCOLA = v.SERIE_FAC ' +
    '   AND uc.NUMERO_FAC_VFCOLA = v.NUMERO_FAC) ';
  // ABONO apunta desde la original a la rectificativa. El historial guarda
  // el sentido inverso y conserva el origen de rectificaciones anteriores.
  SQL_CAMPOS_RECTIFICADA_LISTADO =
    'fr.SERIE_FAC_ORIGEN_FACREL AS SERIE_RECTIFICADA_FAC, ' +
    'fr.NUMERO_FAC_ORIGEN_FACREL AS NUMERO_RECTIFICADA_FAC ';
  SQL_ENLACE_RECTIFICADA_LISTADO =
    ' LEFT JOIN fza_facturas_relaciones fr ' +
    '   ON fr.SERIE_FAC_FACREL = v.SERIE_FAC ' +
    '  AND fr.NUMERO_FAC_FACREL = v.NUMERO_FAC ' +
    '  AND fr.TIPO_RELACION_FACREL = ''RECTIFICA'' ';

function CrearPreparadorListadoFacturasUniDAC(
  AConexion: TUniConnection): IPreparadorListadoFacturas;

function SQLFiltroVistaListadoFacturas(const AVista: string): string;

implementation

uses
  System.SysUtils,
  inLibSqlSeguro,
  inLibVerifactuEsquemaIntf,
  UniDataVerifactuEsquema;

const
  // Las vistas por tipo permiten clasificar también el origen rectificado.
  cVistasListadoFacturas: array[0..2] of string = (
    'vi_facturas',
    'vi_facturas_normales',
    'vi_facturas_simplificadas');

type
  TPreparadorListadoFacturasUniDAC = class(TInterfacedObject,
    IPreparadorListadoFacturas)
  private
    FConexion: TUniConnection;
    function SentenciaConEstadoCola(const AVista: string): string;
    function SentenciaSinEstadoCola(const AVista: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function EstadoColaDisponible(out AMensaje: string): Boolean;
    procedure PrepararListado(
      AConsulta: TDataSet;
      const AVista: string;
      AIncluirEstadoCola: Boolean);
  end;

constructor TPreparadorListadoFacturasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function SQLFiltroVistaListadoFacturas(const AVista: string): string;
var
  sVista: string;
begin
  sVista := DelimitarIdentificadorSql(AVista, cVistasListadoFacturas);
  Result := '1 = 1';
  if not SameText(AVista, 'vi_facturas') then
    // Una rectificativa pertenece a la misma pantalla que su original.
    Result :=
      '(EXISTS (SELECT 1 FROM ' + sVista + ' vt ' +
      ' WHERE vt.SERIE_FAC = v.SERIE_FAC ' +
      '   AND vt.NUMERO_FAC = v.NUMERO_FAC) ' +
      ' OR (v.TIPO_FAC = ''RECTIFICATIVA'' AND EXISTS (' +
      ' SELECT 1 FROM fza_facturas_relaciones r ' +
      ' JOIN ' + sVista + ' vo ' +
      '   ON vo.SERIE_FAC = r.SERIE_FAC_ORIGEN_FACREL ' +
      '  AND vo.NUMERO_FAC = r.NUMERO_FAC_ORIGEN_FACREL ' +
      ' WHERE r.SERIE_FAC_FACREL = v.SERIE_FAC ' +
      '   AND r.NUMERO_FAC_FACREL = v.NUMERO_FAC ' +
      '   AND r.TIPO_RELACION_FACREL = ''RECTIFICA'')))';
end;

function TPreparadorListadoFacturasUniDAC.EstadoColaDisponible(
  out AMensaje: string): Boolean;
var
  oRepositorio: IRepositorioEsquemaVerifactu;
begin
  oRepositorio := CrearRepositorioEsquemaVerifactuUniDAC(FConexion);
  Result := oRepositorio.ColaDisponible(AMensaje);
end;

function TPreparadorListadoFacturasUniDAC.SentenciaConEstadoCola(
  const AVista: string): string;
begin
  // Columna Cola Verifactu: último estado en fza_verifactu_cola de cada
  // factura (PENDIENTE/PROCESANDO/ENVIADA/ERROR; NULL si nunca se encoló).
  Result :=
    'SELECT v.*, c.ESTADO_VFCOLA, ' +
    SQL_FASE_FISCAL_LISTADO +
    SQL_CAMPOS_RECTIFICADA_LISTADO +
    '  FROM vi_facturas v ' +
    SQL_ENLACE_RECTIFICADA_LISTADO +
    SQL_ENLACE_COLA_LISTADO +
    ' WHERE ' + SQLFiltroVistaListadoFacturas(AVista) +
    ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC';
end;

function TPreparadorListadoFacturasUniDAC.SentenciaSinEstadoCola(
  const AVista: string): string;
begin
  Result :=
    'SELECT v.*, '''' AS ESTADO_VFCOLA, ' +
    'v.FASE_FAC AS FASE_PRESENTACION_FAC, ' +
    SQL_CAMPOS_RECTIFICADA_LISTADO +
    '  FROM vi_facturas v ' +
    SQL_ENLACE_RECTIFICADA_LISTADO +
    ' WHERE ' + SQLFiltroVistaListadoFacturas(AVista) +
    ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC';
end;

procedure TPreparadorListadoFacturasUniDAC.PrepararListado(
  AConsulta: TDataSet;
  const AVista: string;
  AIncluirEstadoCola: Boolean);
var
  sListado, sRefresco: string;
begin
  if AConsulta is TUniQuery then
  begin
    // SQLFiltroVistaListadoFacturas valida la vista mediante lista blanca.
    if AIncluirEstadoCola then
    begin
      sListado := SentenciaConEstadoCola(AVista);
      sRefresco := SentenciaConEstadoCola('vi_facturas');
    end
    else
    begin
      sListado := SentenciaSinEstadoCola(AVista);
      sRefresco := SentenciaSinEstadoCola('vi_facturas');
    end;
    TUniQuery(AConsulta).SQL.Text := sListado;
    // Refresh tras consolidar debe recuperar también la fase de presentación.
    TUniQuery(AConsulta).SQLRefresh.Text := StringReplace(sRefresco,
      'WHERE 1 = 1',
      'WHERE v.SERIE_FAC = :Old_SERIE_FAC ' +
      'AND v.NUMERO_FAC = :Old_NUMERO_FAC', []);
  end;
end;

function CrearPreparadorListadoFacturasUniDAC(
  AConexion: TUniConnection): IPreparadorListadoFacturas;
begin
  Result := TPreparadorListadoFacturasUniDAC.Create(AConexion);
end;

end.

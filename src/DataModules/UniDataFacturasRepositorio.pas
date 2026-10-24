{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasRepositorio                                    }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC necesaria para editar facturas.                       }
{******************************************************************************}
unit UniDataFacturasRepositorio;

interface

uses
  System.SysUtils, Uni,
  inLibCatalogoSqlIntf,
  inLibFacturasServiciosIntf;

type
  TRepositorioFacturas = class(
    TInterfacedObject,
    IRepositorioFacturas)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function ResolverTextoSql(
      const ADefinicion: TDefinicionSql): string;
    function EjecutarExisteSerieOtraEmpresa(
      const ASql, ASerie, AEmpresa,
      ATipoDocumento: string): Boolean;
    function EjecutarEsPaisUE(
      const ASql, ACodigoPais: string): Boolean;
    function EjecutarObtenerOperacionFiscal(
      const ASql, ACodigo: string;
      out AOperacion: TOperacionFiscalFactura): Boolean;
    function EjecutarUltimaFechaSerie(
      const ASql, ASerie, AEmpresa,
      ANumero: string): TDateTime;
    function EjecutarHayHuecoNumeracion(
      const ASql, ASerie, AEmpresa,
      ANumero: string): Boolean;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    function ExisteSerieOtraEmpresa(
      const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
    function EsPaisUE(const ACodigoPais: string): Boolean;
    function ObtenerOperacionFiscal(
      const ACodigo: string;
      out AOperacion: TOperacionFiscalFactura): Boolean;
    function UltimaFechaSerie(
      const ASerie, AEmpresa, ANumero: string): TDateTime;
    function HayHuecoNumeracion(
      const ASerie, AEmpresa, ANumero: string): Boolean;
    procedure GuardarCliente(
      const ASolicitud: TSolicitudClienteFactura);
    procedure GuardarEmpresa(
      const ASolicitud: TSolicitudEmpresaFactura);
  end;

implementation

uses
  Data.DB,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_EXISTE_SERIE_OTRA_EMPRESA =
    'SELECT EMPRESA_CON FROM fza_contadores ' +
    'WHERE SERIE_CON = :SERIE ' +
    'AND TIPO_DOC_CON = :TIPODOC ' +
    'AND EMPRESA_CON <> :EMPRESA ' +
    'AND EMPRESA_CON <> :EMPRESASINASIGNAR';
  SQL_ES_PAIS_UE =
    'SELECT ESMIEMBRO_UE_PAI FROM fza_paises ' +
    'WHERE CODIGO_PAI_PAI = TRIM(:PAIS) ' +
    'OR COD_ALPHA2_PAI = UPPER(TRIM(:PAIS))';
  SQL_OBTENER_OPERACION_FISCAL =
    'SELECT AMBITO_VFO, ESREPERCUTE_IVA_VFO ' +
    'FROM fza_verifactu_operaciones ' +
    'WHERE CODIGO_VFO = :CODIGO';
  SQL_ULTIMA_FECHA_SERIE =
    'SELECT MAX(FECHA_FAC) AS ULTIMA FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE ' +
    'AND CODIGO_EMP_FAC = :EMPRESA ' +
    'AND NUMERO_FAC <> :NUMERO ' +
    'AND FECHA_FAC IS NOT NULL ' +
    'AND FASE_FAC <> ''BORRADOR''';
  SQL_HAY_HUECO_NUMERACION =
    'SELECT MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS MAXNUM ' +
    'FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE ' +
    'AND CODIGO_EMP_FAC = :EMPRESA ' +
    'AND CAST(NUMERO_FAC AS UNSIGNED) < :ASIGNADO';
  SQL_GUARDAR_CLIENTE =
    'CALL PRC_CREAR_ACTUALIZAR_CLIENTE(' +
    ':pCODIGO_CLIENTE, :pRAZONSOCIAL_CLIENTE, :pNIF_CLIENTE, ' +
    ':pMOVIL_CLIENTE, :pEMAIL_CLIENTE, :pDIRECCION1_CLIENTE, ' +
    ':pDIRECCION2_CLIENTE, :pPOBLACION_CLIENTE, ' +
    ':pPROVINCIA_CLIENTE, :pCPOSTAL_CLIENTE, ' +
    ':pCOD_PAIS_CLIENTE, :pPAIS_CLIENTE, ' +
    ':pESIVA_EXENTO_CLIENTE, :pESRETENCIONES_CLIENTE, ' +
    ':pESIVA_RECARGO_CLIENTE, :pESINTRACOMUNITARIO_CLIENTE, ' +
    ':pESREGIMENESPECIALAGRICOLA_CLIENTE, ' +
    ':pTARIFA_ARTICULO_CLIENTE, :pUSUARIO)';
  SQL_GUARDAR_EMPRESA =
    'CALL PRC_CREAR_ACTUALIZAR_EMPRESA(' +
    ':pCODIGO_EMPRESA, :pRAZONSOCIAL_EMPRESA, :pNIF_EMPRESA, ' +
    ':pMOVIL_EMPRESA, :pEMAIL_EMPRESA, :pDIRECCION1_EMPRESA, ' +
    ':pDIRECCION2_EMPRESA, :pPOBLACION_EMPRESA, ' +
    ':pPROVINCIA_EMPRESA, :pCPOSTAL_EMPRESA, :pPAIS_EMPRESA, ' +
    ':pCODPAIS_EMPRESA, :pRETENCIONES_EMPRESA, ' +
    ':pIVA_RECARGO_EMPRESA, :pREGIMENESPECIALAGRICOLA_EMPRESA, ' +
    ':pGRUPO_ZONA_IVA_EMPRESA, :pUSUARIO)';

function DefinicionExisteSerieOtraEmpresa: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'ExisteSerieOtraEmpresa',
    SQL_EXISTE_SERIE_OTRA_EMPRESA,
    'SERIE,TIPODOC,EMPRESA,EMPRESASINASIGNAR',
    'EMPRESA_CON',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionEsPaisUE: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'EsPaisUE',
    SQL_ES_PAIS_UE,
    'PAIS',
    'ESMIEMBRO_UE_PAI',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionObtenerOperacionFiscal: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'ObtenerOperacionFiscal',
    SQL_OBTENER_OPERACION_FISCAL,
    'CODIGO',
    'AMBITO_VFO,ESREPERCUTE_IVA_VFO',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionUltimaFechaSerie: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'UltimaFechaSerie',
    SQL_ULTIMA_FECHA_SERIE,
    'SERIE,EMPRESA,NUMERO',
    'ULTIMA',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionHayHuecoNumeracion: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'HayHuecoNumeracion',
    SQL_HAY_HUECO_NUMERACION,
    'SERIE,EMPRESA,ASIGNADO',
    'MAXNUM',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionGuardarCliente: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'GuardarCliente',
    SQL_GUARDAR_CLIENTE,
    'pCODIGO_CLIENTE,pRAZONSOCIAL_CLIENTE,pNIF_CLIENTE,' +
    'pMOVIL_CLIENTE,pEMAIL_CLIENTE,pDIRECCION1_CLIENTE,' +
    'pDIRECCION2_CLIENTE,pPOBLACION_CLIENTE,pPROVINCIA_CLIENTE,' +
    'pCPOSTAL_CLIENTE,pCOD_PAIS_CLIENTE,pPAIS_CLIENTE,' +
    'pESIVA_EXENTO_CLIENTE,pESRETENCIONES_CLIENTE,' +
    'pESIVA_RECARGO_CLIENTE,pESINTRACOMUNITARIO_CLIENTE,' +
    'pESREGIMENESPECIALAGRICOLA_CLIENTE,' +
    'pTARIFA_ARTICULO_CLIENTE,pUSUARIO',
    '',
    tssCall,
    pesSoloBase);
end;

function DefinicionGuardarEmpresa: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioFacturas',
    'GuardarEmpresa',
    SQL_GUARDAR_EMPRESA,
    'pCODIGO_EMPRESA,pRAZONSOCIAL_EMPRESA,pNIF_EMPRESA,' +
    'pMOVIL_EMPRESA,pEMAIL_EMPRESA,pDIRECCION1_EMPRESA,' +
    'pDIRECCION2_EMPRESA,pPOBLACION_EMPRESA,pPROVINCIA_EMPRESA,' +
    'pCPOSTAL_EMPRESA,pPAIS_EMPRESA,pCODPAIS_EMPRESA,' +
    'pRETENCIONES_EMPRESA,pIVA_RECARGO_EMPRESA,' +
    'pREGIMENESPECIALAGRICOLA_EMPRESA,' +
    'pGRUPO_ZONA_IVA_EMPRESA,pUSUARIO',
    '',
    tssCall,
    pesSoloBase);
end;

constructor TRepositorioFacturas.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioFacturas.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 7);
  Result[0] := DefinicionExisteSerieOtraEmpresa;
  Result[1] := DefinicionEsPaisUE;
  Result[2] := DefinicionObtenerOperacionFiscal;
  Result[3] := DefinicionUltimaFechaSerie;
  Result[4] := DefinicionHayHuecoNumeracion;
  Result[5] := DefinicionGuardarCliente;
  Result[6] := DefinicionGuardarEmpresa;
end;

function TRepositorioFacturas.ResolverTextoSql(
  const ADefinicion: TDefinicionSql): string;
var
  oSql: TSqlResuelto;
begin
  oSql := ResolverSqlBase(ADefinicion);
  if Assigned(FCatalogoSql) then
    oSql := FCatalogoSql.Resolver(
      ADefinicion);
  Result := oSql.Texto;
end;

function TRepositorioFacturas.EjecutarExisteSerieOtraEmpresa(
  const ASql, ASerie, AEmpresa,
  ATipoDocumento: string): Boolean;
var
  oConsulta: TUniQuery;
  sEmpresaEncontrada: string;
begin
  Result := False;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('TIPODOC').AsString :=
      ATipoDocumento;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('EMPRESASINASIGNAR').AsString := '-';
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionExisteSerieOtraEmpresa,
      oConsulta);
    if not oConsulta.IsEmpty then
    begin
      sEmpresaEncontrada :=
        oConsulta.FieldByName('EMPRESA_CON').AsString;
      Result := (sEmpresaEncontrada = '') or
        (not SameText(
          sEmpresaEncontrada,
          AEmpresa));
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturas.EjecutarEsPaisUE(
  const ASql, ACodigoPais: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('PAIS').AsString :=
      Trim(ACodigoPais);
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionEsPaisUE,
      oConsulta);
    Result := (not oConsulta.IsEmpty) and
      SameText(
        Trim(
          oConsulta.FieldByName(
            'ESMIEMBRO_UE_PAI').AsString),
        'S');
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturas.EjecutarObtenerOperacionFiscal(
  const ASql, ACodigo: string;
  out AOperacion: TOperacionFiscalFactura): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AOperacion.Ambito := '';
  AOperacion.RepercuteIva := True;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('CODIGO').AsString :=
      Trim(ACodigo);
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionObtenerOperacionFiscal,
      oConsulta);
    if not oConsulta.IsEmpty then
    begin
      AOperacion.Ambito :=
        Trim(
          oConsulta.FieldByName(
            'AMBITO_VFO').AsString);
      AOperacion.RepercuteIva :=
        not SameText(
          Trim(
            oConsulta.FieldByName(
              'ESREPERCUTE_IVA_VFO').AsString),
          'N');
      Result := True;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturas.EjecutarUltimaFechaSerie(
  const ASql, ASerie, AEmpresa,
  ANumero: string): TDateTime;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionUltimaFechaSerie,
      oConsulta);
    if (not oConsulta.IsEmpty) and
       (not oConsulta.FieldByName('ULTIMA').IsNull) then
      Result := oConsulta.FieldByName(
        'ULTIMA').AsDateTime;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturas.EjecutarHayHuecoNumeracion(
  const ASql, ASerie, AEmpresa,
  ANumero: string): Boolean;
var
  iNumeroAsignado: Int64;
  iNumeroMaximo: Int64;
  oConsulta: TUniQuery;
begin
  Result := False;
  iNumeroAsignado := StrToInt64Def(
    Trim(ANumero),
    0);
  if iNumeroAsignado > 1 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := ASql;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.ParamByName('ASIGNADO').AsLargeInt :=
        iNumeroAsignado;
      oConsulta.Open;
      ValidarCamposResultadoSql(
        DefinicionHayHuecoNumeracion,
        oConsulta);
      if (not oConsulta.IsEmpty) and
         (not oConsulta.FieldByName('MAXNUM').IsNull) then
      begin
        iNumeroMaximo :=
          oConsulta.FieldByName('MAXNUM').AsLargeInt;
        Result := (iNumeroAsignado - iNumeroMaximo) > 1;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioFacturas.ExisteSerieOtraEmpresa(
  const ASerie, AEmpresa,
  ATipoDocumento: string): Boolean;
var
  bExiste: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bExiste := False;
  oDefinicion := DefinicionExisteSerieOtraEmpresa;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      bExiste := EjecutarExisteSerieOtraEmpresa(
        ASql,
        ASerie,
        AEmpresa,
        ATipoDocumento);
    end,
    FIncidenciasSql);
  Result := bExiste;
end;

function TRepositorioFacturas.EsPaisUE(
  const ACodigoPais: string): Boolean;
var
  bEsPaisUE: Boolean;
  oDefinicion: TDefinicionSql;
begin
  Result := False;
  if Trim(ACodigoPais) <> '' then
  begin
    bEsPaisUE := False;
    oDefinicion := DefinicionEsPaisUE;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        bEsPaisUE := EjecutarEsPaisUE(
          ASql,
          ACodigoPais);
      end,
      FIncidenciasSql);
    Result := bEsPaisUE;
  end;
end;

function TRepositorioFacturas.ObtenerOperacionFiscal(
  const ACodigo: string;
  out AOperacion: TOperacionFiscalFactura): Boolean;
var
  bEncontrada: Boolean;
  oDefinicion: TDefinicionSql;
  oOperacion: TOperacionFiscalFactura;
begin
  bEncontrada := False;
  oOperacion.Ambito := '';
  oOperacion.RepercuteIva := True;
  if Trim(ACodigo) <> '' then
  begin
    oDefinicion := DefinicionObtenerOperacionFiscal;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        bEncontrada := EjecutarObtenerOperacionFiscal(
          ASql,
          ACodigo,
          oOperacion);
      end,
      FIncidenciasSql);
  end;
  AOperacion := oOperacion;
  Result := bEncontrada;
end;

function TRepositorioFacturas.UltimaFechaSerie(
  const ASerie, AEmpresa,
  ANumero: string): TDateTime;
var
  dUltimaFecha: TDateTime;
  oDefinicion: TDefinicionSql;
begin
  dUltimaFecha := 0;
  oDefinicion := DefinicionUltimaFechaSerie;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      dUltimaFecha := EjecutarUltimaFechaSerie(
        ASql,
        ASerie,
        AEmpresa,
        ANumero);
    end,
    FIncidenciasSql);
  Result := dUltimaFecha;
end;

function TRepositorioFacturas.HayHuecoNumeracion(
  const ASerie, AEmpresa,
  ANumero: string): Boolean;
var
  bHayHueco: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bHayHueco := False;
  oDefinicion := DefinicionHayHuecoNumeracion;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      bHayHueco := EjecutarHayHuecoNumeracion(
        ASql,
        ASerie,
        AEmpresa,
        ANumero);
    end,
    FIncidenciasSql);
  Result := bHayHueco;
end;

procedure TRepositorioFacturas.GuardarCliente(
  const ASolicitud: TSolicitudClienteFactura);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ResolverTextoSql(
      DefinicionGuardarCliente);
    oConsulta.ParamByName('pCODIGO_CLIENTE').AsString :=
      ASolicitud.Codigo;
    oConsulta.ParamByName('pRAZONSOCIAL_CLIENTE').AsString :=
      ASolicitud.RazonSocial;
    oConsulta.ParamByName('pNIF_CLIENTE').AsString :=
      ASolicitud.Nif;
    oConsulta.ParamByName('pMOVIL_CLIENTE').AsString :=
      ASolicitud.Movil;
    oConsulta.ParamByName('pEMAIL_CLIENTE').AsString :=
      ASolicitud.Email;
    oConsulta.ParamByName('pDIRECCION1_CLIENTE').AsString :=
      ASolicitud.Direccion1;
    oConsulta.ParamByName('pDIRECCION2_CLIENTE').AsString :=
      ASolicitud.Direccion2;
    oConsulta.ParamByName('pPOBLACION_CLIENTE').AsString :=
      ASolicitud.Poblacion;
    oConsulta.ParamByName('pPROVINCIA_CLIENTE').AsString :=
      ASolicitud.Provincia;
    oConsulta.ParamByName('pCPOSTAL_CLIENTE').AsString :=
      ASolicitud.CodigoPostal;
    oConsulta.ParamByName('pPAIS_CLIENTE').AsString :=
      ASolicitud.NombrePais;
    oConsulta.ParamByName('pCOD_PAIS_CLIENTE').AsString :=
      ASolicitud.CodigoPais;
    oConsulta.ParamByName(
      'pESINTRACOMUNITARIO_CLIENTE').AsString :=
      ASolicitud.EsIntracomunitario;
    oConsulta.ParamByName('pESIVA_EXENTO_CLIENTE').AsString :=
      ASolicitud.EsIvaExento;
    oConsulta.ParamByName('pESRETENCIONES_CLIENTE').AsString :=
      ASolicitud.EsRetenciones;
    oConsulta.ParamByName('pESIVA_RECARGO_CLIENTE').AsString :=
      ASolicitud.EsIvaRecargo;
    oConsulta.ParamByName(
      'pESREGIMENESPECIALAGRICOLA_CLIENTE').AsString :=
      ASolicitud.EsRegimenEspecialAgricola;
    oConsulta.ParamByName(
      'pTARIFA_ARTICULO_CLIENTE').AsString :=
      ASolicitud.TarifaArticulo;
    oConsulta.ParamByName('pUSUARIO').AsString :=
      ASolicitud.Usuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturas.GuardarEmpresa(
  const ASolicitud: TSolicitudEmpresaFactura);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ResolverTextoSql(
      DefinicionGuardarEmpresa);
    oConsulta.ParamByName('pCODIGO_EMPRESA').AsString :=
      ASolicitud.Codigo;
    oConsulta.ParamByName('pRAZONSOCIAL_EMPRESA').AsString :=
      ASolicitud.RazonSocial;
    oConsulta.ParamByName('pNIF_EMPRESA').AsString :=
      ASolicitud.Nif;
    oConsulta.ParamByName('pMOVIL_EMPRESA').AsString :=
      ASolicitud.Movil;
    oConsulta.ParamByName('pEMAIL_EMPRESA').AsString :=
      ASolicitud.Email;
    oConsulta.ParamByName('pDIRECCION1_EMPRESA').AsString :=
      ASolicitud.Direccion1;
    oConsulta.ParamByName('pDIRECCION2_EMPRESA').AsString :=
      ASolicitud.Direccion2;
    oConsulta.ParamByName('pPOBLACION_EMPRESA').AsString :=
      ASolicitud.Poblacion;
    oConsulta.ParamByName('pPROVINCIA_EMPRESA').AsString :=
      ASolicitud.Provincia;
    oConsulta.ParamByName('pCPOSTAL_EMPRESA').AsString :=
      ASolicitud.CodigoPostal;
    oConsulta.ParamByName('pPAIS_EMPRESA').AsString :=
      ASolicitud.NombrePais;
    oConsulta.ParamByName('pCODPAIS_EMPRESA').AsString :=
      ASolicitud.CodigoPais;
    oConsulta.ParamByName('pRETENCIONES_EMPRESA').AsString :=
      ASolicitud.EsRetenciones;
    oConsulta.ParamByName('pIVA_RECARGO_EMPRESA').AsString :=
      ASolicitud.EsIvaRecargo;
    oConsulta.ParamByName(
      'pREGIMENESPECIALAGRICOLA_EMPRESA').AsString :=
      ASolicitud.EsRegimenEspecialAgricola;
    oConsulta.ParamByName(
      'pGRUPO_ZONA_IVA_EMPRESA').AsString :=
      ASolicitud.GrupoZonaIva;
    oConsulta.ParamByName('pUSUARIO').AsString :=
      ASolicitud.Usuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

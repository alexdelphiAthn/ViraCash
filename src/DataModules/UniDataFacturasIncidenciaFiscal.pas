{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasIncidenciaFiscal                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de incidencias fiscales y creación de rectificativas R4.     }
{******************************************************************************}
unit UniDataFacturasIncidenciaFiscal;

interface

uses
  inLibFormatoDocumentoLecturasIntf,
  Uni,
  inLibFacturasIncidenciaFiscalIntf;

function CrearRepositorioIncidenciaFiscalFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioIncidenciaFiscalFactura;

implementation

uses
  inLibFormatoDocumento,
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  Data.DB,
  inLibMsgVerifactu;

const
  fseriefac = 'SERIE_FAC';
  fnumerofac = 'NUMERO_FAC';
  ftipofac = 'TIPO_FAC';
  fcodigoempfac = 'CODIGO_EMP_FAC';
  fcodigoclifac = 'CODIGO_CLI_FAC';
  frazonsocialclifac = 'RAZON_SOCIAL_CLIENTE_FAC';
  fnifclifac = 'NIF_CLIENTE_FAC';
  festadofaccon = 'ESTADO_FACCON';
  fcodigoerrorfaccon = 'CODIGO_ERROR_AEAT_FACCON';
  fdescripcionerrorfaccon = 'DESCRIPCION_ERROR_AEAT_FACCON';
  festadosubsanacion = 'ESTADO_SUBSANACION';
  fcodigocli = 'CODIGO_CLI_CLI';
  frazonsocialcli = 'RAZON_SOCIAL_CLI';
  fnifcli = 'NIF_CLI';

type
  TRepositorioIncidenciaFiscalFacturaUniDAC = class(
    TInterfacedObject,
    IRepositorioIncidenciaFiscalFactura,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    function LeerCliente(AQry: TUniQuery): TDatosClienteIncidenciaFiscal;
    procedure ComprobarRectificativaNoCreada(
      const ASerie, ANumero: string);
    function EjecutarDuplicacion(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const AUsuario, ACodigoEmpresa: string): string;
    procedure AplicarDatosRectificativa(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const AUsuario, ANumeroRectificativa: string);
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(AConexion: TUniConnection);
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function CrearRectificativaR4(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const AUsuario: string): string;
  end;

function CrearRepositorioIncidenciaFiscalFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioIncidenciaFiscalFactura;
begin
  Result := TRepositorioIncidenciaFiscalFacturaUniDAC.Create(AConexion);
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TRepositorioIncidenciaFiscalFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.LeerCliente(
  AQry: TUniQuery): TDatosClienteIncidenciaFiscal;
begin
  Result := Default(TDatosClienteIncidenciaFiscal);
  if not AQry.IsEmpty then
  begin
    Result.Codigo := AQry.FieldByName(fcodigocli).AsString;
    Result.RazonSocial := AQry.FieldByName(frazonsocialcli).AsString;
    Result.Nif := AQry.FieldByName(fnifcli).AsString;
  end;
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.CargarIncidencia(
  const ASerie, ANumero: string): TDatosIncidenciaFiscal;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosIncidenciaFiscal);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT f.SERIE_FAC, f.NUMERO_FAC, f.TIPO_FAC, ' +
      '        f.CODIGO_EMP_FAC, ' +
      '        f.CODIGO_CLI_FAC, f.RAZON_SOCIAL_CLIENTE_FAC, ' +
      '        f.NIF_CLIENTE_FAC, c.ESTADO_FACCON, ' +
      '        c.CODIGO_ERROR_AEAT_FACCON, ' +
      '        COALESCE(NULLIF(c.DESCRIPCION_ERROR_AEAT_FACCON, ''''), ' +
      '          (SELECT qa.MENSAJE_ERROR_VFCOLA ' +
      '             FROM fza_verifactu_cola qa ' +
      '            WHERE qa.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
      '              AND qa.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
      '              AND qa.TIPO_OPERACION_VFCOLA = ''ALTA'' ' +
      '            ORDER BY qa.ID_VFCOLA DESC LIMIT 1)) ' +
      '          AS DESCRIPCION_ERROR_AEAT_FACCON, ' +
      '        (SELECT q.ESTADO_VFCOLA ' +
      '           FROM fza_verifactu_cola q ' +
      '          WHERE q.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
      '            AND q.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
      '            AND q.TIPO_OPERACION_VFCOLA = ''SUBSANACION'' ' +
      '          ORDER BY q.ID_VFCOLA DESC LIMIT 1) ' +
      '          AS ESTADO_SUBSANACION ' +
      ' FROM fza_facturas f ' +
      ' LEFT JOIN fza_facturas_consolidaciones c ' +
      '   ON c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '  AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO ' +
      ' ORDER BY c.ID_FACCON DESC LIMIT 1';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.Serie := Qry.FieldByName(fseriefac).AsString;
      Result.Numero := Qry.FieldByName(fnumerofac).AsString;
      Result.TipoFactura := Qry.FieldByName(ftipofac).AsString;
      Result.CodigoEmpresa := Qry.FieldByName(fcodigoempfac).AsString;
      Result.FormatoDocumento := LeerFormatoEmpresa(Result.CodigoEmpresa);
      Result.EstadoRegistro := Qry.FieldByName(festadofaccon).AsString;
      Result.EstadoSubsanacion :=
        Qry.FieldByName(festadosubsanacion).AsString;
      Result.CodigoError := Qry.FieldByName(fcodigoerrorfaccon).AsString;
      Result.DescripcionError :=
        Qry.FieldByName(fdescripcionerrorfaccon).AsString;
      Result.Cliente.Codigo := Qry.FieldByName(fcodigoclifac).AsString;
      Result.Cliente.RazonSocial :=
        Qry.FieldByName(frazonsocialclifac).AsString;
      Result.Cliente.Nif := Qry.FieldByName(fnifclifac).AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.CargarCliente(
  const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT CODIGO_CLI_CLI, RAZON_SOCIAL_CLI, NIF_CLI ' +
      ' FROM fza_clientes ' +
      ' WHERE CODIGO_CLI_CLI = :CODIGO';
    Qry.ParamByName('CODIGO').AsString := Trim(ACodigoCliente);
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.CreateFmt(
        SErrorIncidenciaClienteNoEncontrado,
        [ACodigoCliente]);
    Result := LeerCliente(Qry);
    if Trim(Result.Nif) = '' then
      raise Exception.CreateFmt(
        SErrorIncidenciaClienteSinNif,
        [Result.Codigo]);
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioIncidenciaFiscalFacturaUniDAC.
  ComprobarRectificativaNoCreada(const ASerie, ANumero: string);
var
  Qry: TUniQuery;
  sNumeroRectificativa: string;
  sSerieRectificativa: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT SERIE_FAC_ABONO_FAC, NUMERO_FAC_ABONO_FAC ' +
      ' FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    sSerieRectificativa :=
      Qry.FieldByName('SERIE_FAC_ABONO_FAC').AsString;
    sNumeroRectificativa :=
      Qry.FieldByName('NUMERO_FAC_ABONO_FAC').AsString;
    if (Trim(sSerieRectificativa) <> '') or
       (Trim(sNumeroRectificativa) <> '') then
      raise Exception.Create(FormatearMensajeDocumentos(
        LeerFormatoFactura(ASerie, ANumero),
        SErrorIncidenciaRectificativaExistente,
        [ASerie, ANumero, sSerieRectificativa, sNumeroRectificativa]));
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.EjecutarDuplicacion(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const AUsuario, ACodigoEmpresa: string): string;
var
  Procedimiento: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_CREAR_FACTURA_DUPLICADA';
    Procedimiento.Prepare;
    Procedimiento.ParamByName('pidseriefactura').AsString :=
      ASolicitud.Serie;
    Procedimiento.ParamByName('pidnumfactura').AsString :=
      ASolicitud.Numero;
    Procedimiento.ParamByName('pidseriefacturaabono').AsString :=
      ASolicitud.SerieRectificativa;
    Procedimiento.ParamByName('pidcodigo_empresa').AsString :=
      ACodigoEmpresa;
    Procedimiento.ParamByName('pfechafacturaabono').AsDate :=
      ASolicitud.FechaRectificativa;
    Procedimiento.ParamByName('pUSUARIO').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result := Trim(Procedimiento.ParamByName(
      'pidnumfacturaabono').AsString);
  finally
    FreeAndNil(Procedimiento);
  end;
  if Result = '' then
    raise Exception.Create(SErrorIncidenciaCrearRectificativa);
end;

procedure TRepositorioIncidenciaFiscalFacturaUniDAC.AplicarDatosRectificativa(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const AUsuario, ANumeroRectificativa: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' UPDATE fza_facturas f ' +
      ' JOIN fza_clientes c ' +
      '   ON c.CODIGO_CLI_CLI = :CODIGOCLI ' +
      ' SET f.CODIGO_CLI_FAC = c.CODIGO_CLI_CLI, ' +
      '     f.RAZON_SOCIAL_CLIENTE_FAC = c.RAZON_SOCIAL_CLI, ' +
      '     f.NIF_CLIENTE_FAC = c.NIF_CLI, ' +
      '     f.MOVIL_CLIENTE_FAC = c.MOVIL_CLI, ' +
      '     f.EMAIL_CLIENTE_FAC = c.EMAIL_CLI, ' +
      '     f.DIRECCION1_CLIENTE_FAC = c.DIRECCION1_CLI, ' +
      '     f.DIRECCION2_CLIENTE_FAC = c.DIRECCION2_CLI, ' +
      '     f.POBLACION_CLIENTE_FAC = c.POBLACION_CLI, ' +
      '     f.PROVINCIA_CLIENTE_FAC = c.PROVINCIA_CLI, ' +
      '     f.CODIGO_POSTAL_CLIENTE_FAC = c.CODIGO_POSTAL_CLI, ' +
      '     f.CODIGO_PAI_CLIENTE_FAC = c.CODIGO_PAI_CLI, ' +
      '     f.NOMBRE_PAI_CLIENTE_FAC = c.NOMBRE_PAI_CLI, ' +
      '     f.TIPO_FAC = ''RECTIFICATIVA'', ' +
      '     f.TIPO_RECTIFICATIVA_FAC = ''S'', ' +
      '     f.TIPO_FACTURA_VERIFACTU_FAC = ''R4'', ' +
      '     f.ESCONSOLIDADA_FAC = ''N'', ' +
      '     f.INSTANTECONSO_FAC = NULL, ' +
      '     f.FASE_FAC = ''BORRADOR'', ' +
      '     f.COMENTARIOS_FAC = TRIM(CONCAT(' +
      '       IFNULL(f.COMENTARIOS_FAC, ''''), ' +
      '       '' MOTIVO R4: '', :MOTIVO)), ' +
      '     f.INSTANTE_MODIF = NOW(), ' +
      '     f.USUARIO_MODIF = :USUARIO ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO';
    Qry.ParamByName('CODIGOCLI').AsString :=
      ASolicitud.CodigoClienteCorrecto;
    Qry.ParamByName('MOTIVO').AsString := Trim(ASolicitud.Motivo);
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('SERIE').AsString := ASolicitud.SerieRectificativa;
    Qry.ParamByName('NUMERO').AsString := ANumeroRectificativa;
    Qry.Execute;
    if Qry.RowsAffected <> 1 then
      raise Exception.Create(SErrorIncidenciaCrearRectificativa);
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioIncidenciaFiscalFacturaUniDAC.CrearRectificativaR4(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const AUsuario: string): string;
var
  Datos: TDatosIncidenciaFiscal;
begin
  CargarCliente(ASolicitud.CodigoClienteCorrecto);
  ComprobarRectificativaNoCreada(
    ASolicitud.Serie,
    ASolicitud.Numero);
  Datos := CargarIncidencia(ASolicitud.Serie, ASolicitud.Numero);
  if Trim(Datos.Serie) = '' then
    raise Exception.Create(SErrorIncidenciaFacturaNoSeleccionada);
  Result := EjecutarDuplicacion(
    ASolicitud,
    AUsuario,
    Datos.CodigoEmpresa);
  AplicarDatosRectificativa(ASolicitud, AUsuario, Result);
end;

end.

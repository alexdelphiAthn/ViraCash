{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesEstado                                  }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Estado y metadatos de materialización de una sesión de compra.            }
{******************************************************************************}
unit UniDataComprasSesionesEstado;
interface
uses
  Uni,
  inLibComprasSesionesIntf,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

function ValidarMaterializacionSesion(
  ADM: TdmComprasSesiones;
  const ARepositorio: IRepositorioLecturasComprasSesiones;
  out AMensajeError: string): Boolean;
function CargarConfiguracionMaterializacion(
  ADM: TdmComprasSesiones):
  TConfiguracionMaterializacionSesion;
function ConsultarAlmacenesMaterializacion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasEstadoMaterializacion):
  TArray<string>;
function ResolverSerieMaterializacion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen,
  ASerieAlternativa: string): string;
procedure CerrarSesionMaterializada(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const APedido, AAlbaran: TDocumentoMaterializado;
  const AUsuario: string);
procedure PersistirErrorMaterializacion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const AUsuario, AMensaje: string);

implementation
uses
  System.SysUtils,
  Data.DB, DBAccess,
  inLibMsgCompras,
  UniDataValoresAutomaticosRepositorio,
  UniDataComprasSesionesOperaciones;

function ValidarMaterializacionSesion(
  ADM: TdmComprasSesiones;
  const ARepositorio: IRepositorioLecturasComprasSesiones;
  out AMensajeError: string): Boolean;
var
  oIncidencias: TIncidenciasSesionCompra;
begin
  oIncidencias := ARepositorio.ValidarSesionDetallado;
  Result := Length(oIncidencias) = 0;
  AMensajeError := '';
  if not Result then
  begin
    AMensajeError := oIncidencias[0];
    if AMensajeError = '' then
      AMensajeError := SErrorSesionIncidenciasSinDetalle;
  end;
end;

function CargarConfiguracionMaterializacion(
  ADM: TdmComprasSesiones):
  TConfiguracionMaterializacionSesion;
begin
  Result := Default(TConfiguracionMaterializacionSesion);
  Result.GeneraPedido :=
    ADM.unqryTablaG.FieldByName(
      'ESGENERA_PEDIDO_SES').AsString = 'S';
  Result.GeneraAlbaran :=
    ADM.unqryTablaG.FieldByName(
      'ESGENERA_ALBARAN_SES').AsString = 'S';
  Result.Empresa :=
    ADM.unqryTablaG.FieldByName(
      'CODIGO_EMP_SES').AsString;
  Result.AlmacenCabecera :=
    ADM.unqryTablaG.FieldByName(
      'CODIGO_ALM_SES').AsString;
end;

function ConsultarAlmacenesMaterializacion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasEstadoMaterializacion):
  TArray<string>;
begin
  Result := ALecturas.ConsultarAlmacenes(
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString,
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString,
    ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString);
end;

function ResolverSerieMaterializacion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen,
  ASerieAlternativa: string): string;
begin
  Result := ObtenerSeriePropiaAlmacen(
    AConexion,
    AEmpresa,
    ATipoDocumento,
    AAlmacen);
  if Result = '' then
    Result := ASerieAlternativa;
end;

procedure CerrarSesionMaterializada(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const APedido, AAlbaran: TDocumentoMaterializado;
  const AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones SET ' +
      '  ESTADO_SES = ''CERRADA'', ' +
      '  INSTANTE_MATERIALIZA_SES = NOW(), ' +
      '  USUARIO_MATERIALIZA_SES = :u, ' +
      '  SERIE_PEDC_SES = :sp, NUMERO_PEDC_SES = :np, ' +
      '  SERIE_ALBC_SES = :sa, NUMERO_ALBC_SES = :na, ' +
      '  MENSAJE_ERROR_SES = NULL, ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
      ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('sp').AsString := APedido.Serie;
    q.ParamByName('np').AsString := APedido.Numero;
    q.ParamByName('sa').AsString := AAlbaran.Serie;
    q.ParamByName('na').AsString := AAlbaran.Numero;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure AvisarErrorNoPersistido(
  ADM: TdmComprasSesiones;
  const AMensaje: string);
begin
  if Assigned(ADM) then
  begin
    ADM.RegistroLog.RegistrarAviso(
      'UniDataComprasSesionesEstado: ' +
      'no se pudo persistir MENSAJE_ERROR_SES: ' +
      AMensaje);
    if Assigned(ADM.ContextoSesion) then
      ADM.ContextoSesion.LogSesion(
        '  AVISO: no se pudo persistir el error: ' +
        AMensaje);
  end;
end;

procedure PersistirErrorMaterializacion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const AUsuario, AMensaje: string);
var
  q: TUniQuery;
begin
  try
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'UPDATE fza_compras_sesiones ' +
        '   SET MENSAJE_ERROR_SES = :e, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :u ' +
        ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
      q.ParamByName('e').AsString :=
        Copy(AMensaje, 1, 2000);
      q.ParamByName('u').AsString := AUsuario;
      q.ParamByName('s').AsString :=
        ADM.unqryTablaG.FieldByName(
          'SERIE_SES').AsString;
      q.ParamByName('n').AsString :=
        ADM.unqryTablaG.FieldByName(
          'NUMERO_SES').AsString;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  except
    on E: Exception do
      AvisarErrorNoPersistido(ADM, E.Message);
  end;
end;

end.

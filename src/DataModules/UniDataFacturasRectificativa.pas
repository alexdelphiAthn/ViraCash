{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasRectificativa                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de las rectificativas de venta mayor: datos de la factura    }
{    original y copia del borrador con los SP de abono y duplicado.            }
{******************************************************************************}
unit UniDataFacturasRectificativa;

interface

uses
  inLibFormatoDocumentoLecturasIntf,
  Uni,
  inLibFacturasRectificativaIntf;

function CrearRepositorioRectificativaFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioRectificativaFactura;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  Data.DB,
  inLibMsgFacturas;

type
  TRepositorioRectificativaFacturaUniDAC = class(
    TInterfacedObject,
    IRepositorioRectificativaFactura,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    function NombreProcedimiento(
      AOperacion: TOperacionRectificativaFactura): string;
    procedure AplicarFormaPago(
      const ASerie, ANumero, AFormaPago: string);
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(AConexion: TUniConnection);
    function CargarOrigen(
      const ASerie, ANumero: string): TDatosOrigenRectificativa;
    function CrearBorrador(
      const ASolicitud: TSolicitudRectificativaFactura;
      const AUsuario, ACodigoEmpresa: string): string;
  end;

function CrearRepositorioRectificativaFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioRectificativaFactura;
begin
  Result := TRepositorioRectificativaFacturaUniDAC.Create(AConexion);
end;

function TRepositorioRectificativaFacturaUniDAC.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TRepositorioRectificativaFacturaUniDAC.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TRepositorioRectificativaFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioRectificativaFacturaUniDAC.CargarOrigen(
  const ASerie, ANumero: string): TDatosOrigenRectificativa;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosOrigenRectificativa);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    // PENDIENTES cuenta las rectificativas de esta factura que siguen
    // en BORRADOR (vínculo creado sin emitir).
    Qry.SQL.Text :=
      ' SELECT f.SERIE_FAC, f.NUMERO_FAC, f.TIPO_FAC, f.FASE_FAC, ' +
      '        f.ESCONSOLIDADA_FAC, f.CODIGO_EMP_FAC, f.CODIGO_ALM_FAC, ' +
      '        f.FORMA_PAGO_FAC, ' +
      '        f.SERIE_FAC_ABONO_FAC, f.NUMERO_FAC_ABONO_FAC, ' +
      '        (SELECT COUNT(*) ' +
      '           FROM fza_facturas_relaciones r ' +
      '           JOIN fza_facturas h ' +
      '             ON h.SERIE_FAC = r.SERIE_FAC_FACREL ' +
      '            AND h.NUMERO_FAC = r.NUMERO_FAC_FACREL ' +
      '          WHERE r.SERIE_FAC_ORIGEN_FACREL = f.SERIE_FAC ' +
      '            AND r.NUMERO_FAC_ORIGEN_FACREL = f.NUMERO_FAC ' +
      '            AND r.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
      '            AND (h.FASE_FAC IS NULL OR ' +
      '                 h.FASE_FAC IN ('''', ''BORRADOR''))) ' +
      '          AS PENDIENTES ' +
      ' FROM fza_facturas f ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.Serie := Qry.FieldByName('SERIE_FAC').AsString;
      Result.Numero := Qry.FieldByName('NUMERO_FAC').AsString;
      Result.TipoFactura := Qry.FieldByName('TIPO_FAC').AsString;
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.Consolidada := SameText(
        Qry.FieldByName('ESCONSOLIDADA_FAC').AsString, 'S');
      Result.CodigoEmpresa := Qry.FieldByName('CODIGO_EMP_FAC').AsString;
      Result.FormatoDocumento := LeerFormatoEmpresa(Result.CodigoEmpresa);
      Result.CodigoAlmacen := Qry.FieldByName('CODIGO_ALM_FAC').AsString;
      Result.FormaPago := Qry.FieldByName('FORMA_PAGO_FAC').AsString;
      Result.SerieRectificativa :=
        Qry.FieldByName('SERIE_FAC_ABONO_FAC').AsString;
      Result.NumeroRectificativa :=
        Qry.FieldByName('NUMERO_FAC_ABONO_FAC').AsString;
      Result.TieneRectificativaPendiente :=
        Qry.FieldByName('PENDIENTES').AsInteger > 0;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioRectificativaFacturaUniDAC.NombreProcedimiento(
  AOperacion: TOperacionRectificativaFactura): string;
begin
  // El abono invierte cantidades y totales y recalcula netos; la
  // sustitución y el duplicado copian la factura tal cual.
  if AOperacion = orfDiferencias then
    Result := 'PRC_CREAR_FACTURA_ABONO'
  else
    Result := 'PRC_CREAR_FACTURA_DUPLICADA';
end;

procedure TRepositorioRectificativaFacturaUniDAC.AplicarFormaPago(
  const ASerie, ANumero, AFormaPago: string);
var
  Qry: TUniQuery;
begin
  if Trim(AFormaPago) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FORMA_PAGO_FAC = :FORMAPAGO ' +
        ' WHERE SERIE_FAC = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('FORMAPAGO').AsString := Trim(AFormaPago);
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Execute;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TRepositorioRectificativaFacturaUniDAC.CrearBorrador(
  const ASolicitud: TSolicitudRectificativaFactura;
  const AUsuario, ACodigoEmpresa: string): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName :=
      NombreProcedimiento(ASolicitud.Operacion);
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pidseriefactura').AsString :=
      ASolicitud.SerieOriginal;
    oProcedimiento.ParamByName('pidnumfactura').AsString :=
      ASolicitud.NumeroOriginal;
    oProcedimiento.ParamByName('pidseriefacturaabono').AsString :=
      ASolicitud.Serie;
    oProcedimiento.ParamByName('pidcodigo_empresa').AsString :=
      ACodigoEmpresa;
    oProcedimiento.ParamByName('pfechafacturaabono').AsDate :=
      ASolicitud.Fecha;
    oProcedimiento.ParamByName('pUSUARIO').AsString := AUsuario;
    oProcedimiento.ExecProc;
    Result := Trim(oProcedimiento.ParamByName(
      'pidnumfacturaabono').AsString);
  finally
    FreeAndNil(oProcedimiento);
  end;
  if Result = '' then
    raise Exception.Create(SErrorCrearBorradorFactura);
  AplicarFormaPago(ASolicitud.Serie, Result, ASolicitud.FormaPago);
end;

end.

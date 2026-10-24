{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasSubsanacion                                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de la subsanación de venta mayor: situación fiscal de la     }
{    factura y cambio de fase. La cola de subsanación la gestiona             }
{    UniDataVerifactuSubsanacionRepositorio.                                   }
{******************************************************************************}
unit UniDataFacturasSubsanacion;

interface

uses
  Uni,
  inLibFacturasSubsanacionIntf;

function CrearRepositorioSubsanacionFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioSubsanacionFactura;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  Data.DB;

type
  TRepositorioSubsanacionFacturaUniDAC = class(
    TInterfacedObject,
    IRepositorioSubsanacionFactura)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosSubsanacionFactura;
    function CambiarFase(
      const ASerie, ANumero, AFase, AUsuario: string): TDateTime;
    function CargarComparacionRegistro(
      const ASerie, ANumero: string): TDatosComparacionSubsanacion;
  end;

function CrearRepositorioSubsanacionFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioSubsanacionFactura;
begin
  Result := TRepositorioSubsanacionFacturaUniDAC.Create(AConexion);
end;

constructor TRepositorioSubsanacionFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioSubsanacionFacturaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioSubsanacionFacturaUniDAC.Cargar(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosSubsanacionFactura;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosSubsanacionFactura);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' SELECT f.SERIE_FAC, f.NUMERO_FAC, f.TIPO_FAC, f.FASE_FAC, ' +
      '        f.ESCONSOLIDADA_FAC, f.INSTANTE_MODIF, ' +
      '        f.SERIE_FAC_ABONO_FAC, f.NUMERO_FAC_ABONO_FAC, ' +
      '        (SELECT c.ESTADO_FACCON ' +
      '           FROM fza_facturas_consolidaciones c ' +
      '          WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '            AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      '          ORDER BY c.ID_FACCON DESC LIMIT 1) AS ESTADO_REGISTRO, ' +
      '        (SELECT c.CHAIN_HASH_FACCON ' +
      '           FROM fza_facturas_consolidaciones c ' +
      '          WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '            AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      '          ORDER BY c.ID_FACCON DESC LIMIT 1) AS HUELLA_REGISTRO, ' +
      '        (SELECT q.ESTADO_VFCOLA ' +
      '           FROM fza_verifactu_cola q ' +
      '          WHERE q.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
      '            AND q.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
      '            AND q.ESTADO_VFCOLA <> ''ENVIADA'' ' +
      '          ORDER BY q.ID_VFCOLA DESC LIMIT 1) AS ESTADO_COLA_ACTIVA ' +
      ' FROM fza_facturas f ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO';
    if ABloquear then
      Qry.SQL.Add(' FOR UPDATE');
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.FormatoDocumento := CrearFormatoDocumentoLecturas(
        FConexion).LeerFormatoFactura(ASerie, ANumero);
      Result.Serie := Qry.FieldByName('SERIE_FAC').AsString;
      Result.Numero := Qry.FieldByName('NUMERO_FAC').AsString;
      Result.TipoFactura := Qry.FieldByName('TIPO_FAC').AsString;
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.Consolidada := SameText(
        Qry.FieldByName('ESCONSOLIDADA_FAC').AsString, 'S');
      Result.EstadoRegistro :=
        Qry.FieldByName('ESTADO_REGISTRO').AsString;
      Result.TieneHuella :=
        Trim(Qry.FieldByName('HUELLA_REGISTRO').AsString) <> '';
      Result.EstadoColaActiva :=
        Qry.FieldByName('ESTADO_COLA_ACTIVA').AsString;
      Result.SerieRectificativa :=
        Qry.FieldByName('SERIE_FAC_ABONO_FAC').AsString;
      Result.NumeroRectificativa :=
        Qry.FieldByName('NUMERO_FAC_ABONO_FAC').AsString;
      Result.InstanteModificacion :=
        Qry.FieldByName('INSTANTE_MODIF').AsDateTime;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioSubsanacionFacturaUniDAC.CargarComparacionRegistro(
  const ASerie, ANumero: string): TDatosComparacionSubsanacion;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosComparacionSubsanacion);
  Qry := NuevaConsulta;
  try
    // Mismos importes que comunica el envío (CargarImportesYCertificado).
    Qry.SQL.Text :=
      ' SELECT f.TOTAL_BASES_FAC, f.TOTAL_IMPUESTOS_FAC, ' +
      '        f.NIF_CLIENTE_FAC, f.RAZON_SOCIAL_CLIENTE_FAC, ' +
      '        (SELECT c.REGISTRO_XML_FACCON ' +
      '           FROM fza_facturas_consolidaciones c ' +
      '          WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '            AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      '          ORDER BY c.ID_FACCON DESC LIMIT 1) AS REGISTRO_XML ' +
      ' FROM fza_facturas f ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.CuotaTotal := Qry.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
      Result.ImporteTotal :=
        Qry.FieldByName('TOTAL_BASES_FAC').AsCurrency +
        Qry.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
      Result.NifCliente := Qry.FieldByName('NIF_CLIENTE_FAC').AsString;
      Result.NombreCliente :=
        Qry.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString;
      Result.RegistroXml := Qry.FieldByName('REGISTRO_XML').AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioSubsanacionFacturaUniDAC.CambiarFase(
  const ASerie, ANumero, AFase, AUsuario: string): TDateTime;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET FASE_FAC = :FASE, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF = :USUARIO ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('FASE').AsString := AFase;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Execute;
    Qry.SQL.Text :=
      ' SELECT INSTANTE_MODIF ' +
      ' FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if Qry.IsEmpty then
      Result := 0
    else
      Result := Qry.FieldByName('INSTANTE_MODIF').AsDateTime;
  finally
    FreeAndNil(Qry);
  end;
end;

end.

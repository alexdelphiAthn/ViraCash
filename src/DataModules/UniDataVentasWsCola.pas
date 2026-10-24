{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsCola                                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa la persistencia de la cola de eventos de venta para el         }
{    webservice de respaldo (fza_ventas_ws_cola).                              }
{******************************************************************************}
unit UniDataVentasWsCola;

interface

uses
  inLibFormatoDocumentoLecturasIntf,
  Uni, inLibVentasWsColaIntf;

function CrearRepositorioVentasWsColaUniDAC(
  AConexion: TUniConnection): IDespachoVentasWsCola;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils, System.Hash, System.IOUtils, Data.DB;

type
  TRepositorioVentasWsColaUniDAC = class(
    TInterfacedObject,
    IAltaVentasWsCola,
    IDespachoVentasWsCola,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    procedure AsignarParametrosPdf(
      AQry: TUniQuery;
      const ARutaPdf, AUsuario: string);
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(AConexion: TUniConnection);
    function Encolar(
      const AIdEvento, ATipoEvento, ASerie, ANumero,
        AUsuario: string): Int64;
    function EncolarEvento(
      const AIdEvento, ATipoEvento, AEmpresa, ASerie,
        ANumero, AUsuario: string): Int64;
    function ActualizarPdfVentaPendiente(
      AEsFactura: Boolean;
      const ASerie, ANumero, ARutaPdf, AUsuario: string): Boolean;
    procedure ActualizarPdfPorId(
      AEsFactura: Boolean;
      AIdCola: Int64;
      const ARutaPdf, AUsuario: string);
    procedure ReencolarProcesandoCaducadas;
    function BuscarPendientes(
      AMaximo: Integer): TArray<Int64>;
    function MarcarProcesando(
      AIdCola: Int64;
      const AUsuario: string): Boolean;
    function LeerFila(
      AIdCola: Int64): TFilaVentasWsCola;
    procedure GuardarContenido(
      AIdCola: Int64;
      const AContenido, AHuella: string);
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AIdPeticion, AUsuario: string);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string;
      AConsumirIntento: Boolean = True);
  end;

procedure CamposPdf(
  AEsFactura: Boolean;
  out ACampoNombre, ACampoContenido, ACampoTamano,
    ACampoHuella: string);
begin
  if AEsFactura then
  begin
    ACampoNombre := 'NOMBRE_FACTURA_PDF_VWSC';
    ACampoContenido := 'FACTURA_PDF_VWSC';
    ACampoTamano := 'TAMANO_FACTURA_PDF_VWSC';
    ACampoHuella := 'HUELLA_FACTURA_PDF_VWSC';
  end
  else
  begin
    ACampoNombre := 'NOMBRE_PDF_VWSC';
    ACampoContenido := 'TICKET_PDF_VWSC';
    ACampoTamano := 'TAMANO_PDF_VWSC';
    ACampoHuella := 'HUELLA_PDF_VWSC';
  end;
end;

function TRepositorioVentasWsColaUniDAC.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TRepositorioVentasWsColaUniDAC.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TRepositorioVentasWsColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioVentasWsColaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TRepositorioVentasWsColaUniDAC.AsignarParametrosPdf(
  AQry: TUniQuery;
  const ARutaPdf, AUsuario: string);
begin
  AQry.ParamByName('NOMBRE').AsString := ExtractFileName(ARutaPdf);
  AQry.ParamByName('PDF').LoadFromFile(ARutaPdf, ftBlob);
  AQry.ParamByName('TAMANO').AsLargeInt := TFile.GetSize(ARutaPdf);
  AQry.ParamByName('HUELLA').AsString :=
    UpperCase(THashSHA2.GetHashStringFromFile(ARutaPdf));
  AQry.ParamByName('USUARIO').AsString := AUsuario;
end;

function TRepositorioVentasWsColaUniDAC.Encolar(
  const AIdEvento, ATipoEvento, ASerie, ANumero,
    AUsuario: string): Int64;
var
  Qry: TUniQuery;
  sEmpresa: string;
begin
  Result := 0;
  sEmpresa := '';
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' SELECT CODIGO_EMP_FAC FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if not Qry.IsEmpty then
      sEmpresa := Qry.FieldByName('CODIGO_EMP_FAC').AsString;
  finally
    FreeAndNil(Qry);
  end;
  if sEmpresa <> '' then
    Result := EncolarEvento(
      AIdEvento, ATipoEvento, sEmpresa, ASerie, ANumero, AUsuario);
end;

function TRepositorioVentasWsColaUniDAC.EncolarEvento(
  const AIdEvento, ATipoEvento, AEmpresa, ASerie,
    ANumero, AUsuario: string): Int64;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' INSERT INTO fza_ventas_ws_cola ' +
      ' (ID_EVENTO_VWSC, CODIGO_EMP_VWSC, SERIE_FAC_VWSC, ' +
      '  NUMERO_FAC_VWSC, TIPO_EVENTO_VWSC, ' +
      '  VERSION_CONTRATO_VWSC, ESTADO_VWSC, ' +
      '  CONTADOR_INTENTOS_VWSC, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:EVENTO, :EMPRESA, :SERIE, :NUMERO, :TIPO, 1, ' +
      '         ''PENDIENTE'', 0, NOW(), :USUARIO)';
    Qry.ParamByName('EVENTO').AsString := AIdEvento;
    Qry.ParamByName('EMPRESA').AsString := AEmpresa;
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.ParamByName('TIPO').AsString := ATipoEvento;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.Execute;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Qry.Open;
    Result := Qry.FieldByName('ID').AsLargeInt;
    Qry.Close;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioVentasWsColaUniDAC.ActualizarPdfVentaPendiente(
  AEsFactura: Boolean;
  const ASerie, ANumero, ARutaPdf, AUsuario: string): Boolean;
var
  Qry: TUniQuery;
  sCampoContenido: string;
  sCampoHuella: string;
  sCampoNombre: string;
  sCampoTamano: string;
begin
  CamposPdf(AEsFactura, sCampoNombre, sCampoContenido, sCampoTamano,
    sCampoHuella);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola ' +
      ' SET ' + sCampoNombre + ' = :NOMBRE, ' +
      '     ' + sCampoContenido + ' = :PDF, ' +
      '     ' + sCampoTamano + ' = :TAMANO, ' +
      '     ' + sCampoHuella + ' = :HUELLA, ' +
      '     CONTENIDO_JSON_VWSC = NULL, ' +
      '     HUELLA_CONTENIDO_VWSC = NULL, ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE SERIE_FAC_VWSC = :SERIE ' +
      '   AND NUMERO_FAC_VWSC = :NUMERO ' +
      '   AND TIPO_EVENTO_VWSC = ''VENTA_CONFIRMADA'' ' +
      '   AND ESTADO_VWSC = ''PENDIENTE'' ' +
      '   AND CONTENIDO_JSON_VWSC IS NULL ' +
      ' ORDER BY ID_VWSC DESC LIMIT 1';
    AsignarParametrosPdf(Qry, ARutaPdf, AUsuario);
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVentasWsColaUniDAC.ActualizarPdfPorId(
  AEsFactura: Boolean;
  AIdCola: Int64;
  const ARutaPdf, AUsuario: string);
var
  Qry: TUniQuery;
  sCampoContenido: string;
  sCampoHuella: string;
  sCampoNombre: string;
  sCampoTamano: string;
begin
  CamposPdf(AEsFactura, sCampoNombre, sCampoContenido, sCampoTamano,
    sCampoHuella);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola ' +
      ' SET ' + sCampoNombre + ' = :NOMBRE, ' +
      '     ' + sCampoContenido + ' = :PDF, ' +
      '     ' + sCampoTamano + ' = :TAMANO, ' +
      '     ' + sCampoHuella + ' = :HUELLA, ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VWSC = :ID';
    AsignarParametrosPdf(Qry, ARutaPdf, AUsuario);
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVentasWsColaUniDAC.ReencolarProcesandoCaducadas;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = ''PENDIENTE'', ' +
      ' INSTANTE_MODIF = NOW() WHERE ESTADO_VWSC = ''PROCESANDO'' ' +
      ' AND INSTANTE_MODIF < DATE_SUB(NOW(), INTERVAL 10 MINUTE)';
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioVentasWsColaUniDAC.BuscarPendientes(
  AMaximo: Integer): TArray<Int64>;
var
  iFila: Integer;
  Qry: TUniQuery;
begin
  SetLength(Result, 0);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' SELECT ID_VWSC FROM fza_ventas_ws_cola ' +
      ' WHERE ESTADO_VWSC = ''PENDIENTE'' ' +
      '   AND (INSTANTE_PROXIMO_INTENTO_VWSC IS NULL ' +
      '        OR INSTANTE_PROXIMO_INTENTO_VWSC <= NOW()) ' +
      ' ORDER BY ID_VWSC LIMIT ' + IntToStr(AMaximo);
    Qry.Open;
    SetLength(Result, Qry.RecordCount);
    iFila := 0;
    while not Qry.Eof do
    begin
      Result[iFila] := Qry.FieldByName('ID_VWSC').AsLargeInt;
      Inc(iFila);
      Qry.Next;
    end;
    SetLength(Result, iFila);
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioVentasWsColaUniDAC.MarcarProcesando(
  AIdCola: Int64;
  const AUsuario: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = ''PROCESANDO'', ' +
      ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VWSC = :ID AND ESTADO_VWSC = ''PENDIENTE''';
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
    Result := Qry.RowsAffected = 1;
  finally
    FreeAndNil(Qry);
  end;
end;

function TRepositorioVentasWsColaUniDAC.LeerFila(
  AIdCola: Int64): TFilaVentasWsCola;
var
  Qry: TUniQuery;
begin
  Result := Default(TFilaVentasWsCola);
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' SELECT ID_EVENTO_VWSC, CODIGO_EMP_VWSC, SERIE_FAC_VWSC, ' +
      ' NUMERO_FAC_VWSC, TIPO_EVENTO_VWSC, ' +
      ' CONTADOR_INTENTOS_VWSC, CONTENIDO_JSON_VWSC ' +
      ' FROM fza_ventas_ws_cola WHERE ID_VWSC = :ID';
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.IdEvento := Qry.FieldByName('ID_EVENTO_VWSC').AsString;
      Result.Empresa := Qry.FieldByName('CODIGO_EMP_VWSC').AsString;
      Result.Serie := Qry.FieldByName('SERIE_FAC_VWSC').AsString;
      Result.Numero := Qry.FieldByName('NUMERO_FAC_VWSC').AsString;
      Result.TipoEvento :=
        Qry.FieldByName('TIPO_EVENTO_VWSC').AsString;
      Result.Intentos :=
        Qry.FieldByName('CONTADOR_INTENTOS_VWSC').AsInteger;
      Result.Contenido :=
        Qry.FieldByName('CONTENIDO_JSON_VWSC').AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVentasWsColaUniDAC.GuardarContenido(
  AIdCola: Int64;
  const AContenido, AHuella: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola ' +
      ' SET CONTENIDO_JSON_VWSC = :CONTENIDO, ' +
      '     HUELLA_CONTENIDO_VWSC = :HUELLA, ' +
      '     INSTANTE_MODIF = NOW() WHERE ID_VWSC = :ID';
    Qry.ParamByName('CONTENIDO').AsMemo := AContenido;
    Qry.ParamByName('HUELLA').AsString := AHuella;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVentasWsColaUniDAC.MarcarEnviada(
  AIdCola: Int64;
  const AIdPeticion, AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola ' +
      ' SET ESTADO_VWSC = ''ENVIADA'', INSTANTE_ENVIO_VWSC = NOW(), ' +
      ' ID_PETICION_VWSC = :PETICION, MENSAJE_ERROR_VWSC = NULL, ' +
      ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VWSC = :ID';
    Qry.ParamByName('PETICION').AsString := AIdPeticion;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVentasWsColaUniDAC.GuardarErrorIntento(
  AIdCola: Int64;
  const AEstado: string;
  AEsperaSegundos: Integer;
  const AMensaje, AUsuario: string;
  AConsumirIntento: Boolean);
var
  Qry: TUniQuery;
begin
  Qry := NuevaConsulta;
  try
    Qry.SQL.Text :=
      ' UPDATE fza_ventas_ws_cola SET ESTADO_VWSC = :ESTADO, ' +
      ' CONTADOR_INTENTOS_VWSC = CONTADOR_INTENTOS_VWSC + ' +
      ' :INCREMENTO, ' +
      ' INSTANTE_PROXIMO_INTENTO_VWSC = ' +
      ' DATE_ADD(NOW(), INTERVAL :ESPERA SECOND), ' +
      ' MENSAJE_ERROR_VWSC = :MENSAJE, INSTANTE_MODIF = NOW(), ' +
      ' USUARIO_MODIF = :USUARIO WHERE ID_VWSC = :ID';
    Qry.ParamByName('ESTADO').AsString := AEstado;
    if AConsumirIntento then
      Qry.ParamByName('INCREMENTO').AsInteger := 1
    else
      Qry.ParamByName('INCREMENTO').AsInteger := 0;
    Qry.ParamByName('ESPERA').AsInteger := AEsperaSegundos;
    Qry.ParamByName('MENSAJE').AsString := AMensaje;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

function CrearRepositorioVentasWsColaUniDAC(
  AConexion: TUniConnection): IDespachoVentasWsCola;
begin
  Result := TRepositorioVentasWsColaUniDAC.Create(AConexion);
end;

end.

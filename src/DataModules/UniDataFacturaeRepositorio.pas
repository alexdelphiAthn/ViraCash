{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturaeRepositorio                                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa la persistencia necesaria para generar Facturae.               }
{******************************************************************************}
unit UniDataFacturaeRepositorio;

interface

uses
  Uni, inLibFacturaePersistenciaIntf;

function CrearRepositorioFacturaeUniDAC(
  AConexion: TUniConnection): IRepositorioFacturae;

implementation

uses
  System.SysUtils, Data.DB;

type
  TRepositorioFacturaeUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturae)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function ColumnaExiste(
      const ATabla, ACampo: string): Boolean;
    function ColumnasDir3Disponibles(
      const ATabla, ASufijo: string): Boolean;
    function ColumnasPersonaFisicaDisponibles(
      const ATabla, ASufijo: string): Boolean;
    function SqlCabecera: string;
  public
    constructor Create(AConexion: TUniConnection);
    procedure CargarCertificadoEmpresa(
      const ACodigoEmpresa: string;
      out ASerial, ATitular: string);
    function BuscarCabecera(
      const ASerie, ANumero: string): TDataSet;
    function BuscarLineas(
      const ASerie, ANumero: string): TDataSet;
    procedure GuardarXml(
      const ASerie, ANumero, AUsuario, AXml: string);
  end;

constructor TRepositorioFacturaeUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFacturaeUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TRepositorioFacturaeUniDAC.CargarCertificadoEmpresa(
  const ACodigoEmpresa: string;
  out ASerial, ATitular: string);
var
  Consulta: TUniQuery;
begin
  ASerial := '';
  ATitular := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT CODIGO_CERTIFICADO_EMP, TITULAR_CERTIFICADO_EMP ' +
      ' FROM fza_empresas ' +
      ' WHERE CODIGO_EMP_EMP = :EMP ' +
      ' LIMIT 1';
    Consulta.ParamByName('EMP').AsString := ACodigoEmpresa;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      ASerial :=
        Trim(Consulta.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      ATitular :=
        Trim(Consulta.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFacturaeUniDAC.GuardarXml(
  const ASerie, ANumero, AUsuario, AXml: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET XML_FAC = :XML_FAC, USUARIO_MODIF = :USUARIO_MODIF ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Consulta.ParamByName('XML_FAC').DataType := ftMemo;
    Consulta.ParamByName('XML_FAC').AsString := AXml;
    Consulta.ParamByName('USUARIO_MODIF').AsString := AUsuario;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFacturaeUniDAC.ColumnaExiste(
  const ATabla, ACampo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT COUNT(*) AS TOTAL ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      ' AND TABLE_NAME = :TABLA ' +
      ' AND COLUMN_NAME = :CAMPO ';
    Consulta.ParamByName('TABLA').AsString := ATabla;
    Consulta.ParamByName('CAMPO').AsString := ACampo;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('TOTAL').AsInteger > 0;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFacturaeUniDAC.ColumnasDir3Disponibles(
  const ATabla, ASufijo: string): Boolean;
begin
  Result := ColumnaExiste(
    ATabla,
    'CODIGO_OFICINA_CONTABLE_' + ASufijo);
  if Result then
    Result := ColumnaExiste(
      ATabla,
      'CODIGO_ORGANO_GESTOR_' + ASufijo);
  if Result then
    Result := ColumnaExiste(
      ATabla,
      'CODIGO_UNIDAD_TRAMITADORA_' + ASufijo);
end;

function TRepositorioFacturaeUniDAC.ColumnasPersonaFisicaDisponibles(
  const ATabla, ASufijo: string): Boolean;
begin
  Result := ColumnaExiste(
    ATabla,
    'NOMBRE_PERSONA_CLIENTE_' + ASufijo);
  if Result then
    Result := ColumnaExiste(
      ATabla,
      'APELLIDOS_PERSONA_CLIENTE_' + ASufijo);
end;

function TRepositorioFacturaeUniDAC.SqlCabecera: string;
var
  bDir3Factura: Boolean;
  bDir3Cliente: Boolean;
  bCodigoPagoFacturae: Boolean;
  bPersonaFacturae: Boolean;
  bPersonaCliente: Boolean;
begin
  bDir3Factura := ColumnasDir3Disponibles('fza_facturas', 'FAC');
  bDir3Cliente := ColumnasDir3Disponibles('fza_clientes', 'CLI');
  bCodigoPagoFacturae := ColumnaExiste(
    'fza_formas_pago',
    'CODIGO_FACTURAE_FP');
  bPersonaFacturae := ColumnasPersonaFisicaDisponibles(
    'fza_facturas',
    'FAC');
  bPersonaCliente := ColumnasPersonaFisicaDisponibles(
    'fza_clientes',
    'CLI');
  Result := ' SELECT f.* ';
  if bCodigoPagoFacturae then
    Result := Result +
      ', fp.CODIGO_FACTURAE_FP AS CODIGO_FACTURAE_FP '
  else
    Result := Result + ', ''01'' AS CODIGO_FACTURAE_FP ';
  if bDir3Cliente then
  begin
    Result := Result +
      ', cli.CODIGO_OFICINA_CONTABLE_CLI AS CODIGO_OFICINA_CONTABLE_CLI ' +
      ', cli.CODIGO_ORGANO_GESTOR_CLI AS CODIGO_ORGANO_GESTOR_CLI ' +
      ', cli.CODIGO_UNIDAD_TRAMITADORA_CLI ' +
      'AS CODIGO_UNIDAD_TRAMITADORA_CLI ';
  end;
  if bPersonaCliente then
  begin
    Result := Result +
      ', cli.NOMBRE_PERSONA_CLIENTE_CLI AS NOMBRE_PERSONA_CLIENTE_CLI ' +
      ', cli.APELLIDOS_PERSONA_CLIENTE_CLI ' +
      'AS APELLIDOS_PERSONA_CLIENTE_CLI ';
  end;
  if (not bDir3Factura) and bDir3Cliente then
  begin
    Result := Result +
      ', cli.CODIGO_OFICINA_CONTABLE_CLI AS CODIGO_OFICINA_CONTABLE_FAC ' +
      ', cli.CODIGO_ORGANO_GESTOR_CLI AS CODIGO_ORGANO_GESTOR_FAC ' +
      ', cli.CODIGO_UNIDAD_TRAMITADORA_CLI ' +
      'AS CODIGO_UNIDAD_TRAMITADORA_FAC ';
  end
  else if not bDir3Factura then
  begin
    Result := Result +
      ', '''' AS CODIGO_OFICINA_CONTABLE_FAC ' +
      ', '''' AS CODIGO_ORGANO_GESTOR_FAC ' +
      ', '''' AS CODIGO_UNIDAD_TRAMITADORA_FAC ';
  end;
  if (not bPersonaFacturae) and bPersonaCliente then
  begin
    Result := Result +
      ', cli.NOMBRE_PERSONA_CLIENTE_CLI AS NOMBRE_PERSONA_CLIENTE_FAC ' +
      ', cli.APELLIDOS_PERSONA_CLIENTE_CLI ' +
      'AS APELLIDOS_PERSONA_CLIENTE_FAC ';
  end
  else if not bPersonaFacturae then
  begin
    Result := Result +
      ', '''' AS NOMBRE_PERSONA_CLIENTE_FAC ' +
      ', '''' AS APELLIDOS_PERSONA_CLIENTE_FAC ';
  end;
  Result := Result + ' FROM fza_facturas f ';
  if bCodigoPagoFacturae then
  begin
    Result := Result +
      ' LEFT JOIN fza_formas_pago fp ' +
      ' ON fp.CODIGO_FP_FP = f.FORMA_PAGO_FAC ';
  end;
  if bDir3Cliente or bPersonaCliente then
  begin
    Result := Result +
      ' LEFT JOIN fza_clientes cli ' +
      ' ON cli.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC ';
  end;
  Result := Result +
    ' WHERE f.SERIE_FAC = :SERIE ' +
    ' AND f.NUMERO_FAC = :NUMERO ';
end;

function TRepositorioFacturaeUniDAC.BuscarCabecera(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SqlCabecera;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFacturaeUniDAC.BuscarLineas(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT * ' +
      ' FROM fza_facturas_lineas ' +
      ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
      '   AND NUMERO_FAC_FACLIN = :NUMERO ' +
      ' ORDER BY LINEA_FACLIN';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioFacturaeUniDAC(
  AConexion: TUniConnection): IRepositorioFacturae;
begin
  Result := TRepositorioFacturaeUniDAC.Create(AConexion);
end;

end.

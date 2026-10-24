{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataClienteTraspasosEmpresaRepositorio                     }
{    Tipo:       Repositorio UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Alta del cliente al que se emiten las facturas internas entre empresas    }
{    (E_<código de empresa>) con los datos de la empresa destino.              }
{******************************************************************************}
unit UniDataClienteTraspasosEmpresaRepositorio;

interface

uses
  Uni,
  inLibClienteTraspasosEmpresa;

const
  // Lista del desplegable de la ficha de Empresas.
  SQL_CLIENTES_TRASPASOS_EMPRESA =
    'SELECT C.CODIGO_CLI_CLI, C.RAZON_SOCIAL_CLI, C.NIF_CLI ' +
    '  FROM fza_clientes C ' +
    ' WHERE COALESCE(C.ESACTIVO_CLI, ''S'') <> ''N'' ' +
    ' ORDER BY C.RAZON_SOCIAL_CLI, C.CODIGO_CLI_CLI';

// Da de alta el cliente E_<empresa> si no existe y devuelve su código. Si ya
// existe (se creó antes o lo dio de alta alguien a mano) no se toca: sus
// datos y su casilla de retenciones son los que mandan.
function CrearClienteTraspasosEmpresa(
  AConexion: TUniConnection;
  const ADatos: TDatosClienteTraspasosEmpresa;
  const AUsuario: string): string;

// FZ-ISSUE-354: lleva la casilla de recargo de la empresa destino a su
// cliente de traspasos cuando se cambia en la ficha de Empresas.
procedure ActualizarRecargoClienteTraspasos(
  AConexion: TUniConnection;
  const ACodigoCliente: string;
  AEsRecargo: Boolean;
  const AUsuario: string);

implementation

uses
  System.SysUtils;

const
  // La empresa guarda el país como 'ES' o como '724'; el cliente, con el
  // código de fza_paises.
  SQL_INSERTAR_CLIENTE_TRASPASOS =
    'INSERT INTO fza_clientes (' +
    'CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, ' +
    'MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, ' +
    'CODIGO_POSTAL_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
    'CODIGO_PAI_CLI, NOMBRE_PAI_CLI, ESIVA_RECARGO_CLI, ' +
    'ESRETENCIONES_CLI, ESVARIOS_CLI, ESIVA_EXENTO_CLI, ' +
    'ESINTRACOMUNITARIO_CLI, ESREGIMENESPECIALAGRICOLA_CLI, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :CODIGO, ''S'', :RAZON_SOCIAL, :NIF, :MOVIL, :EMAIL, ' +
    ':DIRECCION1, :DIRECCION2, :CODIGO_POSTAL, :POBLACION, :PROVINCIA, ' +
    'COALESCE((SELECT P.CODIGO_PAI_PAI FROM fza_paises P ' +
    '  WHERE P.CODIGO_PAI_PAI = :PAIS OR P.COD_ALPHA2_PAI = :PAIS ' +
    '  LIMIT 1), NULLIF(:PAIS, '''')), :NOMBRE_PAIS, :RECARGO, ' +
    // FZ-ISSUE-355: la venta de mercancía entre empresas vinculadas no
    // lleva retención de IRPF, sea cual sea el NIF de la destino.
    '''N'', ''N'', ''N'', ''N'', :REGIMEN_AGRICOLA, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO FROM DUAL ' +
    'WHERE NOT EXISTS (SELECT 1 FROM fza_clientes X ' +
    '  WHERE X.CODIGO_CLI_CLI = :CODIGO)';

  SQL_ACTUALIZAR_RECARGO_CLIENTE_TRASPASOS =
    'UPDATE fza_clientes ' +
    '   SET ESIVA_RECARGO_CLI = :RECARGO, ' +
    '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    ' WHERE CODIGO_CLI_CLI = :CODIGO ' +
    '   AND COALESCE(ESIVA_RECARGO_CLI, ''N'') <> :RECARGO';

function SiNo(AValor: Boolean): string;
begin
  if AValor then
    Result := 'S'
  else
    Result := 'N';
end;

function CrearClienteTraspasosEmpresa(
  AConexion: TUniConnection;
  const ADatos: TDatosClienteTraspasosEmpresa;
  const AUsuario: string): string;
var
  oConsulta: TUniQuery;
begin
  if Trim(ADatos.CodigoEmpresa) = '' then
  begin
    raise EArgumentException.Create('ADatos.CodigoEmpresa');
  end;
  Result := CodigoClienteTraspasosEmpresa(ADatos.CodigoEmpresa);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_INSERTAR_CLIENTE_TRASPASOS;
    oConsulta.ParamByName('CODIGO').AsString := Result;
    oConsulta.ParamByName('RAZON_SOCIAL').AsString :=
      Trim(ADatos.RazonSocial);
    oConsulta.ParamByName('NIF').AsString := Trim(ADatos.Nif);
    oConsulta.ParamByName('MOVIL').AsString := Trim(ADatos.Movil);
    oConsulta.ParamByName('EMAIL').AsString := Trim(ADatos.Email);
    oConsulta.ParamByName('DIRECCION1').AsString := Trim(ADatos.Direccion1);
    oConsulta.ParamByName('DIRECCION2').AsString := Trim(ADatos.Direccion2);
    oConsulta.ParamByName('CODIGO_POSTAL').AsString :=
      Trim(ADatos.CodigoPostal);
    oConsulta.ParamByName('POBLACION').AsString := Trim(ADatos.Poblacion);
    oConsulta.ParamByName('PROVINCIA').AsString := Trim(ADatos.Provincia);
    oConsulta.ParamByName('PAIS').AsString := Trim(ADatos.CodigoPais);
    oConsulta.ParamByName('NOMBRE_PAIS').AsString :=
      Trim(ADatos.NombrePais);
    oConsulta.ParamByName('REGIMEN_AGRICOLA').AsString :=
      SiNo(ADatos.EsRegimenAgricola);
    oConsulta.ParamByName('RECARGO').AsString :=
      SiNo(ADatos.EsRecargoEquivalencia);
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ActualizarRecargoClienteTraspasos(
  AConexion: TUniConnection;
  const ACodigoCliente: string;
  AEsRecargo: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if Trim(ACodigoCliente) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SQL_ACTUALIZAR_RECARGO_CLIENTE_TRASPASOS;
      oConsulta.ParamByName('RECARGO').AsString := SiNo(AEsRecargo);
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ParamByName('CODIGO').AsString := Trim(ACodigoCliente);
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.

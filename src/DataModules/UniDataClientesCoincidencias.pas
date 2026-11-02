{******************************************************************************}
{  Módulo: UniDataClientesCoincidencias                                        }
{  Tipo: Persistencia. Fecha: 02/11/2026                                        }
{  Descripción: Candidatos por NIF o contacto, sin fusionar fichas.             }
{******************************************************************************}
unit UniDataClientesCoincidencias;

interface

uses
  Uni, inLibClientesCoincidencias;

function BuscarCoincidenciasCliente(AConexion: TUniConnection;
  const AIdentidad: TIdentidadClienteCoincidencias): TCandidatosCliente;

implementation

uses
  System.SysUtils;

procedure PrepararConsulta(AConsulta: TUniQuery;
  const AIdentidad: TIdentidadClienteCoincidencias);
begin
  AConsulta.SQL.Text :=
    'SELECT CODIGO, NOMBRE, MISMO_NIF, MISMO_CONTACTO FROM (' +
    ' SELECT CODIGO_CLI_CLI AS CODIGO, RAZON_SOCIAL_CLI AS NOMBRE,' +
    ' (:NIF<>'''' AND REGEXP_REPLACE(UPPER(COALESCE(NIF_CLI,'''')),' +
    ' ''[^A-Z0-9]'','''')=:NIF) AS MISMO_NIF,' +
    ' ((:CORREO<>'''' AND LOWER(TRIM(EMAIL_CLI))=:CORREO) OR' +
    ' (REGEXP_REPLACE(COALESCE(TELEFONO_CLI,''''),''[^0-9]'','''')' +
    ' IN (NULLIF(:TELEFONO,''''),NULLIF(:MOVIL,''''))) OR' +
    ' (REGEXP_REPLACE(COALESCE(MOVIL_CLI,''''),''[^0-9]'','''')' +
    ' IN (NULLIF(:TELEFONO,''''),NULLIF(:MOVIL,''''))))' +
    ' AS MISMO_CONTACTO FROM fza_clientes' +
    ' WHERE CODIGO_CLI_CLI<>:CODIGO) CANDIDATOS' +
    ' WHERE MISMO_NIF OR MISMO_CONTACTO' +
    ' ORDER BY MISMO_NIF DESC, CODIGO';
  AConsulta.ParamByName('CODIGO').AsString := AIdentidad.Codigo;
  AConsulta.ParamByName('NIF').AsString :=
    NormalizarNifCoincidencias(AIdentidad.Nif);
  AConsulta.ParamByName('TELEFONO').AsString :=
    NormalizarTelefonoCoincidencias(AIdentidad.Telefono);
  AConsulta.ParamByName('MOVIL').AsString :=
    NormalizarTelefonoCoincidencias(AIdentidad.Movil);
  AConsulta.ParamByName('CORREO').AsString :=
    NormalizarCorreoCoincidencias(AIdentidad.Correo);
end;

function BuscarCoincidenciasCliente(AConexion: TUniConnection;
  const AIdentidad: TIdentidadClienteCoincidencias): TCandidatosCliente;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    PrepararConsulta(oConsulta, AIdentidad);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice].Codigo := oConsulta.FieldByName('CODIGO').AsString;
      Result[iIndice].Nombre := oConsulta.FieldByName('NOMBRE').AsString;
      Result[iIndice].MismoNif :=
        oConsulta.FieldByName('MISMO_NIF').AsInteger <> 0;
      Result[iIndice].MismoContacto :=
        oConsulta.FieldByName('MISMO_CONTACTO').AsInteger <> 0;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

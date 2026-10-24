{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataErroresEnvios                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta local y sincronización de las incidencias enviadas a soporte.   }
{******************************************************************************}
unit UniDataErroresEnvios;

interface

uses
  inLibRegistroPantallas,
  System.Classes,
  System.SysUtils,
  Data.DB,
  DBAccess,
  MemDS,
  Uni,
  UniDataGen;

type
  TdmErroresEnvios = class(TdmBase)
  private
    procedure GuardarSeguimientoActual;
  public
    procedure ConfigurarVisibilidad(
      const AUsuario: string;
      AEsAdministrador: Boolean);
    function ActualizarActual(out AError: string): Boolean;
    function EnviarComentarioActual(
      const AMensaje: string;
      out AError: string): Boolean;
    function EjecutarScriptActual(out AError: string): Boolean;
  end;

implementation

uses
  System.Hash,
  UniScript,
  inLibSeguimientoErrores;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

resourcestring
  SErrorSeleccionarEnvioError = 'Seleccione un envío de error.';
  SErrorScriptRemotoNoPendiente = 'No hay un script pendiente.';
  SErrorScriptRemotoVacio = 'El script propuesto está vacío.';
  SErrorHuellaScriptRemotoNoCoincide =
    'La huella SHA-256 del script no coincide.';
  SErrorComunicarResultadoScriptRemoto =
    'El script se ejecutó, pero no se pudo comunicar el resultado: %s';

procedure TdmErroresEnvios.ConfigurarVisibilidad(
  const AUsuario: string;
  AEsAdministrador: Boolean);
begin
  unqryTablaG.Close;
  unqryTablaG.SQL.Clear;
  unqryTablaG.SQL.Add('SELECT *');
  unqryTablaG.SQL.Add('FROM fza_errores_envios');
  if not AEsAdministrador then
  begin
    unqryTablaG.SQL.Add('WHERE USUARIO_ALTA = :USUARIO');
    unqryTablaG.ParamByName('USUARIO').AsString := AUsuario;
  end;
  unqryTablaG.SQL.Add('ORDER BY ID_ERENV DESC');
end;

procedure AsignarParametroFecha(
  AParametro: TUniParam;
  AValor: TDateTime);
begin
  if AValor > 0 then
    AParametro.AsDateTime := AValor
  else
    AParametro.Clear;
end;

procedure TdmErroresEnvios.GuardarSeguimientoActual;
var
  iId: Int64;
  oConsulta: TUniQuery;
  Resultado: TResultadoSeguimientoError;
begin
  iId := unqryTablaG.FieldByName('ID_ERENV').AsLargeInt;
  Resultado := ConsultarSeguimientoError(
    unqryTablaG.FieldByName('URL_ESTADO_ERENV').AsString);
  if not Resultado.Ok then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := unqryTablaG.Connection;
      oConsulta.SQL.Text :=
        'UPDATE fza_errores_envios SET CODIGO_HTTP_ERENV = :HTTP, ' +
        'INSTANTE_CONSULTA_ERENV = CURRENT_TIMESTAMP, ' +
        'MENSAJE_CONSULTA_ERENV = :MENSAJE WHERE ID_ERENV = :ID';
      oConsulta.ParamByName('HTTP').AsInteger := Resultado.CodigoHttp;
      oConsulta.ParamByName('MENSAJE').AsString := Resultado.Mensaje;
      oConsulta.ParamByName('ID').AsLargeInt := iId;
      oConsulta.ExecSQL;
    finally
      oConsulta.Free;
    end;
    raise Exception.Create(Resultado.Mensaje);
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'UPDATE fza_errores_envios SET ' +
      'ESTADO_ERENV = :ESTADO, CODIGO_HTTP_ERENV = :HTTP, ' +
      'COMENTARIO_TECNICO_ERENV = :COMENTARIO, ' +
      'COMUNICACIONES_ERENV = :COMUNICACIONES, ' +
      'INSTANTE_COMENTARIO_ERENV = :INSTANTE_COMENTARIO, ' +
      'INSTANTE_CONSULTA_ERENV = CURRENT_TIMESTAMP, ' +
      'MENSAJE_CONSULTA_ERENV = :MENSAJE, ' +
      'ID_SCRIPT_REMOTO_ERENV = :ID_SCRIPT, ' +
      'DESCRIPCION_SCRIPT_ERENV = :DESCRIPCION_SCRIPT, ' +
      'SCRIPT_SQL_ERENV = :SCRIPT_SQL, ' +
      'SHA256_SCRIPT_ERENV = :SHA256_SCRIPT, ' +
      'ESTADO_SCRIPT_ERENV = :ESTADO_SCRIPT, ' +
      'ID_EJECUTABLE_REMOTO_ERENV = :ID_EJECUTABLE, ' +
      'DESCRIPCION_EJECUTABLE_ERENV = :DESCRIPCION_EJECUTABLE, ' +
      'VERSION_EJECUTABLE_ERENV = :VERSION_EJECUTABLE, ' +
      'URL_EJECUTABLE_ERENV = :URL_EJECUTABLE, ' +
      'NOMBRE_EJECUTABLE_ERENV = :NOMBRE_EJECUTABLE, ' +
      'CANTIDAD_BYTES_EJECUTABLE_ERENV = :BYTES_EJECUTABLE, ' +
      'SHA256_EJECUTABLE_ERENV = :SHA256_EJECUTABLE, ' +
      'ESTADO_EJECUTABLE_ERENV = :ESTADO_EJECUTABLE, ' +
      'USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_ERENV = :ID';
    oConsulta.ParamByName('ESTADO').AsString := Resultado.Estado;
    oConsulta.ParamByName('HTTP').AsInteger := Resultado.CodigoHttp;
    oConsulta.ParamByName('COMENTARIO').AsString :=
      Resultado.ComentarioTecnico;
    oConsulta.ParamByName('COMUNICACIONES').AsString :=
      Resultado.Comunicaciones;
    AsignarParametroFecha(
      oConsulta.ParamByName('INSTANTE_COMENTARIO'),
      Resultado.InstanteComentario);
    oConsulta.ParamByName('MENSAJE').AsString := Resultado.Mensaje;
    if Resultado.Script.Id > 0 then
      oConsulta.ParamByName('ID_SCRIPT').AsLargeInt := Resultado.Script.Id
    else
      oConsulta.ParamByName('ID_SCRIPT').Clear;
    oConsulta.ParamByName('DESCRIPCION_SCRIPT').AsString :=
      Resultado.Script.Descripcion;
    oConsulta.ParamByName('SCRIPT_SQL').AsString := Resultado.Script.SQL;
    oConsulta.ParamByName('SHA256_SCRIPT').AsString := Resultado.Script.Sha256;
    oConsulta.ParamByName('ESTADO_SCRIPT').AsString := Resultado.Script.Estado;
    if Resultado.Ejecutable.Id > 0 then
      oConsulta.ParamByName('ID_EJECUTABLE').AsLargeInt :=
        Resultado.Ejecutable.Id
    else
      oConsulta.ParamByName('ID_EJECUTABLE').Clear;
    oConsulta.ParamByName('DESCRIPCION_EJECUTABLE').AsString :=
      Resultado.Ejecutable.Descripcion;
    oConsulta.ParamByName('VERSION_EJECUTABLE').AsString :=
      Resultado.Ejecutable.Version;
    oConsulta.ParamByName('URL_EJECUTABLE').AsString :=
      Resultado.Ejecutable.UrlDescarga;
    oConsulta.ParamByName('NOMBRE_EJECUTABLE').AsString :=
      Resultado.Ejecutable.Nombre;
    oConsulta.ParamByName('BYTES_EJECUTABLE').AsLargeInt :=
      Resultado.Ejecutable.CantidadBytes;
    oConsulta.ParamByName('SHA256_EJECUTABLE').AsString :=
      Resultado.Ejecutable.Sha256;
    oConsulta.ParamByName('ESTADO_EJECUTABLE').AsString :=
      Resultado.Ejecutable.Estado;
    oConsulta.ParamByName('USUARIO').AsString :=
      unqryTablaG.FieldByName('USUARIO_ALTA').AsString;
    oConsulta.ParamByName('ID').AsLargeInt := iId;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
  unqryTablaG.Close;
  unqryTablaG.Open;
  unqryTablaG.Locate('ID_ERENV', iId, []);
end;

function TdmErroresEnvios.ActualizarActual(
  out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
  begin
    try
      GuardarSeguimientoActual;
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  end
  else
    AError := SErrorSeleccionarEnvioError;
end;

function TdmErroresEnvios.EnviarComentarioActual(
  const AMensaje: string;
  out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
  begin
    Result := EnviarComentarioError(
      unqryTablaG.FieldByName('URL_SERVICIO_ERENV').AsString,
      unqryTablaG.FieldByName('REFERENCIA_ERENV').AsString,
      unqryTablaG.FieldByName('TOKEN_SEGUIMIENTO_ERENV').AsString,
      AMensaje,
      AError);
    if Result then
      Result := ActualizarActual(AError);
  end
  else
    AError := SErrorSeleccionarEnvioError;
end;

function TdmErroresEnvios.EjecutarScriptActual(
  out AError: string): Boolean;
var
  iId: Int64;
  iRegistroLocal: Int64;
  oConsulta: TUniQuery;
  oScript: TUniScript;
  sEstado: string;
  sHash: string;
  sNotificacion: string;
  sResultado: string;
  sSql: string;
begin
  Result := False;
  AError := '';
  sEstado := 'ERROR';
  sResultado := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
  begin
    iId := unqryTablaG.FieldByName('ID_SCRIPT_REMOTO_ERENV').AsLargeInt;
    iRegistroLocal := unqryTablaG.FieldByName('ID_ERENV').AsLargeInt;
    sSql := unqryTablaG.FieldByName('SCRIPT_SQL_ERENV').AsString;
    sHash := UpperCase(THashSHA2.GetHashString(sSql));
    if iId <= 0 then
      AError := SErrorScriptRemotoNoPendiente
    else if Trim(sSql) = '' then
      AError := SErrorScriptRemotoVacio
    else if not SameText(
                  sHash,
                  unqryTablaG.FieldByName(
                    'SHA256_SCRIPT_ERENV').AsString) then
      AError := SErrorHuellaScriptRemotoNoCoincide
    else
    begin
      oScript := TUniScript.Create(nil);
      try
        try
          oScript.Connection := unqryTablaG.Connection;
          oScript.SQL.Text := sSql;
          oScript.Execute;
          sEstado := 'EJECUTADO';
          sResultado := 'Script ejecutado correctamente desde ViraCash.';
          Result := True;
        except
          on E: Exception do
          begin
            AError := E.ClassName + ': ' + E.Message;
            sResultado := AError;
          end;
        end;
      finally
        oScript.Free;
      end;
      if not NotificarResultadoScriptError(
               unqryTablaG.FieldByName('URL_SERVICIO_ERENV').AsString,
               unqryTablaG.FieldByName('REFERENCIA_ERENV').AsString,
               unqryTablaG.FieldByName(
                 'TOKEN_SEGUIMIENTO_ERENV').AsString,
               iId,
               sEstado,
               sResultado,
               sNotificacion) and
         (AError = '') then
        AError := Format(SErrorComunicarResultadoScriptRemoto,
          [sNotificacion]);
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := unqryTablaG.Connection;
        oConsulta.SQL.Text :=
          'UPDATE fza_errores_envios SET ESTADO_SCRIPT_ERENV = :ESTADO ' +
          'WHERE ID_ERENV = :ID';
        oConsulta.ParamByName('ESTADO').AsString := sEstado;
        oConsulta.ParamByName('ID').AsLargeInt := iRegistroLocal;
        oConsulta.ExecSQL;
      finally
        oConsulta.Free;
      end;
      unqryTablaG.Refresh;
    end;
  end
  else
    AError := SErrorSeleccionarEnvioError;
end;

initialization
  RegistrarDataModule(TdmErroresEnvios);

end.

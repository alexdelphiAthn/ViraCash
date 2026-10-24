{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocumentosTrabajoEstados                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Estados y clausulas SQL comunes de los Documentos de Trabajo.             }
{******************************************************************************}
unit inLibDocumentosTrabajoEstados;

interface

const
  ESTADO_DOCUMENTO_TRABAJO_CREADO = 'CREADO';
  ESTADO_DOCUMENTO_TRABAJO_ENVIADO = 'ENVIADO';
  ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO = 'ARCHIVADO';
  ESTADO_DOCUMENTO_TRABAJO_ABIERTO_LEGACY = 'ABIERTO';

function NormalizarEstadoDocumentoTrabajo(const AEstado: string): string;
function EsEstadoDocumentoTrabajoValido(const AEstado: string): Boolean;
function EsDocumentoTrabajoCreado(const AEstado: string): Boolean;
function EsDocumentoTrabajoEnviado(const AEstado: string): Boolean;
function EsDocumentoTrabajoArchivado(const AEstado: string): Boolean;
function CondicionSqlDocumentoTrabajoActivo(const ACampo: string): string;
function CondicionSqlDocumentoTrabajoCreado(const ACampo: string): string;
function CondicionSqlDocumentoTrabajoEnviado(const ACampo: string): string;
function CondicionSqlDocumentoTrabajoArchivado(const ACampo: string): string;
function ClausulaOrdenSqlDocumentosTrabajo(const AAlias: string): string;

implementation

uses
  System.SysUtils;

function NormalizarEstadoDocumentoTrabajo(const AEstado: string): string;
begin
  Result := UpperCase(Trim(AEstado));
  if (Result = '') or
     (Result = ESTADO_DOCUMENTO_TRABAJO_ABIERTO_LEGACY) then
  begin
    Result := ESTADO_DOCUMENTO_TRABAJO_CREADO;
  end;
end;

function EsEstadoDocumentoTrabajoValido(const AEstado: string): Boolean;
var
  sEstado: string;
begin
  sEstado := NormalizarEstadoDocumentoTrabajo(AEstado);
  Result :=
    (sEstado = ESTADO_DOCUMENTO_TRABAJO_CREADO) or
    (sEstado = ESTADO_DOCUMENTO_TRABAJO_ENVIADO) or
    (sEstado = ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO);
end;

function EsDocumentoTrabajoCreado(const AEstado: string): Boolean;
begin
  Result := NormalizarEstadoDocumentoTrabajo(AEstado) =
    ESTADO_DOCUMENTO_TRABAJO_CREADO;
end;

function EsDocumentoTrabajoEnviado(const AEstado: string): Boolean;
begin
  Result := NormalizarEstadoDocumentoTrabajo(AEstado) =
    ESTADO_DOCUMENTO_TRABAJO_ENVIADO;
end;

function EsDocumentoTrabajoArchivado(const AEstado: string): Boolean;
begin
  Result := NormalizarEstadoDocumentoTrabajo(AEstado) =
    ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO;
end;

function CampoSqlNormalizado(const ACampo: string): string;
begin
  if Trim(ACampo) = '' then
  begin
    raise EArgumentException.Create('ACampo');
  end;
  Result :=
    'COALESCE(NULLIF(UPPER(TRIM(' + ACampo + ')), ''''), ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_CREADO) + ')';
end;

function CondicionSqlDocumentoTrabajoActivo(const ACampo: string): string;
begin
  Result := '(' + CampoSqlNormalizado(ACampo) + ' <> ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO) + ')';
end;

function CondicionSqlDocumentoTrabajoCreado(const ACampo: string): string;
begin
  Result := '(' + CampoSqlNormalizado(ACampo) +
    ' IN (' + QuotedStr(ESTADO_DOCUMENTO_TRABAJO_CREADO) + ', ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_ABIERTO_LEGACY) + '))';
end;

function CondicionSqlDocumentoTrabajoEnviado(const ACampo: string): string;
begin
  Result := '(' + CampoSqlNormalizado(ACampo) + ' = ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_ENVIADO) + ')';
end;

function CondicionSqlDocumentoTrabajoArchivado(const ACampo: string): string;
begin
  Result := '(' + CampoSqlNormalizado(ACampo) + ' = ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO) + ')';
end;

function ClausulaOrdenSqlDocumentosTrabajo(const AAlias: string): string;
var
  sPrefijo: string;
begin
  sPrefijo := Trim(AAlias);
  if sPrefijo <> '' then
  begin
    sPrefijo := sPrefijo + '.';
  end;
  Result := ' ORDER BY ' + sPrefijo +
    'INSTANTE_DOCUMENTO_DTR DESC, ' + sPrefijo + 'ID_DTR DESC';
end;

end.

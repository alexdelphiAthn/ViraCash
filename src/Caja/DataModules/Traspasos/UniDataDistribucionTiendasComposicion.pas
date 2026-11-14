{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDistribucionTiendasComposicion                         }
{    Tipo:       Librería (composición)                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Monta los servicios de la distribución entre tiendas (repositorio y       }
{    confirmador de propuestas) sobre una misma conexión: el traspaso y la     }
{    propuesta se resuelven en una sola transacción. También prepara el        }
{    documento de trabajo con el que se distribuye un albarán de compra.       }
{******************************************************************************}
unit UniDataDistribucionTiendasComposicion;

interface

uses
  System.Classes, Uni,
  inLibContextoSesionIntf,
  inLibDistribucionTiendasIntf;

type
  TAlbaranCompraDistribucion = record
    Empresa: string;
    Almacen: string;
    Serie: string;
    Numero: string;
  end;

// APropietarioSesion es quien da el contexto de sesión al data module de
// traspasos: cualquier TdmBase o TfrmBase.
function CrearServiciosDistribucionTiendasUniDAC(
  APropietarioSesion: TComponent;
  AConexion: TUniConnection;
  const AUbicacion: TUbicacionSesion): TServiciosDistribucionTiendas;

// El último documento de trabajo no archivado cargado desde ese albarán que
// ya es una distribución: lleva el título de distribución o tiene
// propuestas. Cero si no hay ninguno.
function BuscarDocumentoDistribucionAlbaranCompra(
  AConexion: TUniConnection;
  const AAlbaran: TAlbaranCompraDistribucion;
  const ATitulo: string): Int64;

// Crea el documento de trabajo y le carga las líneas del albarán. Cero si
// el albarán no aporta ninguna línea (el documento vacío no se conserva).
function CrearDocumentoDistribucionAlbaranCompra(
  AConexion: TUniConnection;
  const AAlbaran: TAlbaranCompraDistribucion;
  const ATitulo, AUsuario: string): Int64;

function SqlBuscarDocumentoDistribucionAlbaranCompra: string;

implementation

uses
  System.SysUtils,
  inLibDocumentosTrabajo,
  inLibDocumentosTrabajoEstados,
  UniDataDocumentosTrabajoRepositorio,
  UniDataDistribucionTiendasRepositorio,
  UniDataPropuestasTraspasoConfirmador;

const
  TIPO_DOCUMENTO_ALBARAN_COMPRA = 'AB';

function CrearServiciosDistribucionTiendasUniDAC(
  APropietarioSesion: TComponent;
  AConexion: TUniConnection;
  const AUbicacion: TUbicacionSesion): TServiciosDistribucionTiendas;
begin
  Result := Default(TServiciosDistribucionTiendas);
  Result.Repositorio :=
    CrearRepositorioDistribucionTiendasUniDAC(AConexion);
  Result.Confirmador := CrearConfirmadorPropuestasTraspasoUniDAC(
    APropietarioSesion, AConexion, Result.Repositorio, AUbicacion);
end;

function SqlBuscarDocumentoDistribucionAlbaranCompra: string;
begin
  Result :=
    'SELECT COALESCE(MAX(DTR.ID_DTR), 0) AS ID_DTR ' +
    '  FROM fza_documentos_trabajo DTR ' +
    ' WHERE DTR.ESTADO_DTR <> ' +
    QuotedStr(ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO) +
    '   AND EXISTS (SELECT 1 ' +
    '                 FROM fza_documentos_trabajo_lineas DTL ' +
    '                WHERE DTL.ID_DTR_DTL = DTR.ID_DTR ' +
    '                  AND DTL.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '                  AND DTL.TIPO_DOCUMENTO_ORIGEN_DTL = ' +
    QuotedStr(TIPO_DOCUMENTO_ALBARAN_COMPRA) +
    '                  AND DTL.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '                  AND DTL.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO) ' +
    '   AND (DTR.TITULO_DTR = :TITULO ' +
    '        OR EXISTS (SELECT 1 ' +
    '                     FROM fza_traspasos_propuestas P ' +
    '                    WHERE P.ID_DTR_TRPRO = DTR.ID_DTR))';
end;

function BuscarDocumentoDistribucionAlbaranCompra(
  AConexion: TUniConnection;
  const AAlbaran: TAlbaranCompraDistribucion;
  const ATitulo: string): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SqlBuscarDocumentoDistribucionAlbaranCompra;
    oConsulta.ParamByName('EMPRESA').AsString := Trim(AAlbaran.Empresa);
    oConsulta.ParamByName('SERIE').AsString := Trim(AAlbaran.Serie);
    oConsulta.ParamByName('NUMERO').AsString := Trim(AAlbaran.Numero);
    oConsulta.ParamByName('TITULO').AsString := Trim(ATitulo);
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID_DTR').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearDocumentoDistribucionAlbaranCompra(
  AConexion: TUniConnection;
  const AAlbaran: TAlbaranCompraDistribucion;
  const ATitulo, AUsuario: string): Int64;
var
  Repositorios: TRepositoriosDocumentosTrabajo;
  Origen: TDocumentoTrabajoOrigen;
  Carga: TResultadoCargaOrigenDocumentoTrabajo;
  bTransaccionPropia: Boolean;
begin
  Repositorios := CrearRepositoriosDocumentosTrabajo(AConexion);
  Origen := Default(TDocumentoTrabajoOrigen);
  Origen.Empresa := Trim(AAlbaran.Empresa);
  Origen.TipoDocumento := TIPO_DOCUMENTO_ALBARAN_COMPRA;
  Origen.Serie := Trim(AAlbaran.Serie);
  Origen.Numero := Trim(AAlbaran.Numero);
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    Result := Repositorios.Escritura.CrearDocumento(
      ATitulo, Trim(AAlbaran.Empresa), Trim(AAlbaran.Almacen), AUsuario);
    Carga := Repositorios.CargaOrigen.CargarLineas(Result, Origen, AUsuario);
    if Carga.LineasInsertadas <= 0 then
    begin
      Result := 0;
      if bTransaccionPropia then
        AConexion.Rollback;
    end
    else if bTransaccionPropia then
      AConexion.Commit;
  except
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasSubsanacionReglas                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas puras de la subsanación de venta mayor: fases y estados de         }
{    registro que la admiten, campos editables de cabecera y líneas, y         }
{    validación del inicio y del registro. Sin dependencias de datos ni de     }
{    pantalla, para probarlas aisladas (tests/fpc).                            }
{******************************************************************************}
unit inLibFacturasSubsanacionReglas;

interface

uses
  inLibFacturasServiciosIntf,
  inLibFacturasSubsanacionIntf,
  inLibVerifactuTipos;

// Sólo se subsana una factura con registro aceptado y vigente.
function FaseAdmiteSubsanacion(const AFase: string): Boolean;
function EstadoRegistroAdmiteSubsanacion(
  const AEstado: string;
  AModo: TModoVerifactu): Boolean;
// Fase a la que vuelve la factura al registrar o cancelar.
function FaseTrasSubsanacionFactura(
  const AEstadoRegistro: string): string;
// En subsanación la factura conserva su identidad y sus importes.
function CampoCabeceraEditableEnSubsanacion(const ACampo: string): Boolean;
function EvaluarInicioSubsanacionFactura(
  const ADatos: TDatosSubsanacionFactura;
  AModo: TModoVerifactu): TResultadoOperacionFactura;
function EvaluarRegistroSubsanacionFactura(
  const ADatos: TDatosSubsanacionFactura;
  const AMotivo: string): TResultadoOperacionFactura;

implementation

uses
  inLibFormatoDocumento,
  System.SysUtils, System.StrUtils,
  inLibMsgFacturas, inLibVerifactu;

function FaseAdmiteSubsanacion(const AFase: string): Boolean;
begin
  Result := MatchText(Trim(AFase),
    [cFaseFacturaVerifactuOk, cFaseFacturaNoVerifactuOk]);
end;

function EstadoRegistroAdmiteSubsanacion(
  const AEstado: string;
  AModo: TModoVerifactu): Boolean;
begin
  // Mismos estados que admite la cola de corrección de registros.
  // En VERI*FACTU y en SII la subsanación va por el sistema del alta: un
  // alta del SII se modifica (A1) aunque el modo sea ahora VERI*FACTU
  case AModo of
    mvVerifactu, mvSii:
      Result := MatchText(Trim(AEstado),
        ['VERIFACTU_OK', 'VERIFACTU_PROCESADO', 'VERIFACTU_ACEPT_ERR',
         'VERIFACTU_SUBSANADO', 'VERIFACTU_DUPLICADO']) or
        EsEstadoSiiAceptado(AEstado);
    mvNoVerifactu:
      Result := MatchText(Trim(AEstado),
        ['NOVERIF_REGISTRADO', 'NOVERIF_SUBSANADO']);
  else
    Result := False;
  end;
end;

function FaseTrasSubsanacionFactura(
  const AEstadoRegistro: string): string;
begin
  if StartsText('NOVERIF', Trim(AEstadoRegistro)) then
    Result := cFaseFacturaNoVerifactuOk
  else
    Result := cFaseFacturaVerifactuOk;
end;

function CampoCabeceraEditableEnSubsanacion(const ACampo: string): Boolean;
var
  sCampo: string;
begin
  sCampo := UpperCase(Trim(ACampo));
  // Datos del cliente, su forma de pago y los campos de auditoría.
  Result := ContainsText(sCampo, 'CLIENTE') or
    MatchText(sCampo, ['CODIGO_CLI_FAC', 'FORMA_PAGO_FAC',
      'CONTADOR_LINEAS_FAC', 'INSTANTE_MODIF', 'USUARIO_MODIF']);
end;

function EvaluarInicioSubsanacionFactura(
  const ADatos: TDatosSubsanacionFactura;
  AModo: TModoVerifactu): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado)
  else if AModo = mvSinVerifactu then
    Result := TResultadoOperacionFactura.Error(
      SErrorSubsanacionSinVerifactu)
  else if not MatchText(Trim(ADatos.TipoFactura),
            ['NORMAL', 'RECTIFICATIVA']) then
    Result := TResultadoOperacionFactura.Error(
      SErrorSubsanacionSoloVentaMayor)
  else if SameText(Trim(ADatos.Fase), cFaseFacturaSubsanacion) then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionYaIniciada, [ADatos.Serie, ADatos.Numero]))
  else if not FaseAdmiteSubsanacion(ADatos.Fase) then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionFaseNoAdmitida,
      [ADatos.Serie, ADatos.Numero, ADatos.Fase]))
  // El SII no encadena: sus registros no tienen huella
  else if not (EstadoRegistroAdmiteSubsanacion(ADatos.EstadoRegistro,
                 AModo) and (ADatos.TieneHuella or
                 EsEstadoSiiAceptado(ADatos.EstadoRegistro))) then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionRegistroNoAceptado,
      [ADatos.Serie, ADatos.Numero, ADatos.EstadoRegistro]))
  else if Trim(ADatos.EstadoColaActiva) <> '' then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionFacturaColaActiva,
      [ADatos.Serie, ADatos.Numero, ADatos.EstadoColaActiva]))
  else if Trim(ADatos.SerieRectificativa) <> '' then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionConRectificativa,
      [ADatos.Serie, ADatos.Numero, ADatos.SerieRectificativa,
      ADatos.NumeroRectificativa]))
  else
    Result := TResultadoOperacionFactura.Correcto;
end;

function EvaluarRegistroSubsanacionFactura(
  const ADatos: TDatosSubsanacionFactura;
  const AMotivo: string): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado)
  else if not SameText(Trim(ADatos.Fase), cFaseFacturaSubsanacion) then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorSubsanacionNoIniciada, [ADatos.Serie, ADatos.Numero]))
  else if Trim(AMotivo) = '' then
    Result := TResultadoOperacionFactura.Error(
      SErrorSubsanacionMotivoObligatorio)
  else
    Result := TResultadoOperacionFactura.Correcto;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibOpcionesDocumento                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas del diálogo común de creación de documentos: qué serie se          }
{    propone al elegir almacén, cuándo es obligatorio el almacén y la          }
{    validación de las opciones antes de aceptar.                              }
{******************************************************************************}
unit inLibOpcionesDocumento;

interface

uses
  inLibOpcionesDocumentoIntf;

function BuscarTipoOpcionesDocumento(
  const ATipos: TTiposOpcionesDocumento; const ACodigo: string;
  out ATipo: TTipoOpcionesDocumento): Boolean;
function ProponerSerieOpcionesDocumento(const ASeries: TArray<string>;
  const ASerieAlmacen: string;
  const ASerieGeneralFactura: string = ''): string;
function AlmacenObligatorioOpcionesDocumento(
  const ATipo: TTipoOpcionesDocumento; AMueveStock: Boolean): Boolean;
function MueveStockOpcionesDocumento(const ATipo: TTipoOpcionesDocumento;
  AMueveStockElegido: Boolean): Boolean;
function CamposDeshabilitadosOpcionesDocumento(
  const AOpciones: TOpcionesDocumento): TCamposOpcionesDocumento;
function AdicionalesDelTipoOpcionesDocumento(
  const AAdicionales: TCamposAdicionalesOpcionesDocumento;
  const ATipo: string): TCamposAdicionalesOpcionesDocumento;
function ValidarOpcionesDocumento(
  const AConfiguracion: TConfiguracionOpcionesDocumento;
  const AOpciones: TOpcionesDocumento; ANumeroAutomatico: Boolean):
  TResultadoValidacionOpcionesDocumento;

implementation

uses
  System.SysUtils,
  inLibMsgOpcionesDocumento;

function BuscarTipoOpcionesDocumento(
  const ATipos: TTiposOpcionesDocumento; const ACodigo: string;
  out ATipo: TTipoOpcionesDocumento): Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  ATipo := Default(TTipoOpcionesDocumento);
  iIndice := 0;
  while (not Result) and (iIndice < Length(ATipos)) do
  begin
    if SameText(ATipos[iIndice].Codigo, ACodigo) then
    begin
      ATipo := ATipos[iIndice];
      Result := True;
    end;
    Inc(iIndice);
  end;
end;

// En factura normal prima su serie general si el llamador la aporta.
// Sin ella se mantiene la serie del almacén y después la lista.
function ProponerSerieOpcionesDocumento(const ASeries: TArray<string>;
  const ASerieAlmacen, ASerieGeneralFactura: string): string;
begin
  Result := Trim(ASerieGeneralFactura);
  if Result = '' then
    Result := Trim(ASerieAlmacen);
  if (Result = '') and (Length(ASeries) > 0) then
    Result := ASeries[0];
end;

// Una factura sin movimientos puede no llevar almacén (empresas de solo
// servicios); el resto de documentos que lo piden lo necesitan.
function AlmacenObligatorioOpcionesDocumento(
  const ATipo: TTipoOpcionesDocumento; AMueveStock: Boolean): Boolean;
begin
  Result := ATipo.AlmacenObligatorio and
    (AMueveStock or (not ATipo.MueveStockOpcional));
end;

function MueveStockOpcionesDocumento(const ATipo: TTipoOpcionesDocumento;
  AMueveStockElegido: Boolean): Boolean;
begin
  Result := AMueveStockElegido or (not ATipo.MueveStockOpcional);
end;

// Un campo propio con valor (o casilla marcada) puede dejar sin uso
// otros: p. ej. añadir a un documento existente no pide serie ni número.
function CamposDeshabilitadosOpcionesDocumento(
  const AOpciones: TOpcionesDocumento): TCamposOpcionesDocumento;
var
  oCampo: TCampoAdicionalOpcionesDocumento;
  bConValor: Boolean;
begin
  Result := [];
  for oCampo in AOpciones.Adicionales do
  begin
    if oCampo.VisibleConTipo(AOpciones.Tipo) then
    begin
      if oCampo.Clase = ccaCasilla then
        bConValor := oCampo.Valor = 'S'
      else
        bConValor := Trim(oCampo.Valor) <> '';
      if bConValor then
        Result := Result + oCampo.DeshabilitaConValor
      else
        Result := Result + oCampo.DeshabilitaSinValor;
    end;
  end;
end;

// Los campos propios que no se piden con el tipo elegido vuelven sin valor,
// para que el llamador no reciba lo que el usuario no ha visto.
function AdicionalesDelTipoOpcionesDocumento(
  const AAdicionales: TCamposAdicionalesOpcionesDocumento;
  const ATipo: string): TCamposAdicionalesOpcionesDocumento;
var
  iIndice: Integer;
begin
  Result := Copy(AAdicionales);
  for iIndice := 0 to High(Result) do
  begin
    if not Result[iIndice].VisibleConTipo(ATipo) then
    begin
      Result[iIndice].Valor := '';
      Result[iIndice].Descripcion := '';
    end;
  end;
end;

function Invalido(ACampo: TCampoOpcionesDocumento;
  const AMensaje: string): TResultadoValidacionOpcionesDocumento;
begin
  Result.EsValido := False;
  Result.Campo := ACampo;
  Result.IndiceAdicional := -1;
  Result.Mensaje := AMensaje;
end;

// Campos propios obligatorios vacíos, los del principio o los del final.
function ValidarAdicionales(const AOpciones: TOpcionesDocumento;
  AlPrincipio: Boolean): TResultadoValidacionOpcionesDocumento;
var
  iIndice: Integer;
  oCampo: TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TResultadoValidacionOpcionesDocumento);
  Result.EsValido := True;
  iIndice := 0;
  while Result.EsValido and (iIndice < Length(AOpciones.Adicionales)) do
  begin
    oCampo := AOpciones.Adicionales[iIndice];
    if (oCampo.AlPrincipio = AlPrincipio) and oCampo.Obligatorio and
       oCampo.VisibleConTipo(AOpciones.Tipo) and
       (oCampo.Clase <> ccaCasilla) and (Trim(oCampo.Valor) = '') then
    begin
      Result := Invalido(codAdicional, oCampo.MensajeObligatorio);
      Result.IndiceAdicional := iIndice;
      if Result.Mensaje = '' then
        Result.Mensaje := Format(SErrorCampoObligatorioOpcionesDocumento,
          [oCampo.Etiqueta.TrimRight([':', ' '])]);
    end;
    Inc(iIndice);
  end;
end;

function ValidarPrincipales(
  const AConfiguracion: TConfiguracionOpcionesDocumento;
  const AOpciones: TOpcionesDocumento; ANumeroAutomatico: Boolean;
  const APedidos: TCamposOpcionesDocumento):
  TResultadoValidacionOpcionesDocumento;
var
  oTipo: TTipoOpcionesDocumento;
  bTipoValido: Boolean;
  bAlmacenObligatorio: Boolean;
begin
  Result := Default(TResultadoValidacionOpcionesDocumento);
  Result.EsValido := True;
  bTipoValido := BuscarTipoOpcionesDocumento(AConfiguracion.Tipos,
    AOpciones.Tipo, oTipo);
  bAlmacenObligatorio := bTipoValido and (codAlmacen in APedidos) and
    AlmacenObligatorioOpcionesDocumento(oTipo, AOpciones.MueveStock);
  if not bTipoValido then
    Result := Invalido(codTipo, SErrorTipoOpcionesDocumento)
  else if bAlmacenObligatorio and (Trim(AOpciones.Almacen) = '') then
    Result := Invalido(codAlmacen, SErrorAlmacenOpcionesDocumento)
  else if (codSerie in APedidos) and
          (not AConfiguracion.SerieOpcional) and
          (Trim(AOpciones.Serie) = '') then
    Result := Invalido(codSerie, SErrorSerieOpcionesDocumento)
  else if (codNumero in APedidos) and
          AConfiguracion.PermiteNumeroManual and
          (not ANumeroAutomatico) and
          (Trim(AOpciones.Numero) = '') then
    Result := Invalido(codNumero, SErrorNumeroOpcionesDocumento)
  else if (codFecha in APedidos) and (AOpciones.Fecha <= 0) then
    Result := Invalido(codFecha, SErrorFechaOpcionesDocumento)
  else if (codFormaPago in APedidos) and
          AConfiguracion.FormaPagoObligatoria and
          (Trim(AOpciones.FormaPago) = '') then
    Result := Invalido(codFormaPago, SErrorFormaPagoOpcionesDocumento);
end;

// Mismo orden que en pantalla: empresa, campos propios del principio,
// campos principales y campos propios del final.
function ValidarOpcionesDocumento(
  const AConfiguracion: TConfiguracionOpcionesDocumento;
  const AOpciones: TOpcionesDocumento; ANumeroAutomatico: Boolean):
  TResultadoValidacionOpcionesDocumento;
var
  sPedidos: TCamposOpcionesDocumento;
begin
  sPedidos := AConfiguracion.Visibles -
    CamposDeshabilitadosOpcionesDocumento(AOpciones);
  if (codEmpresa in sPedidos) and (Trim(AOpciones.Empresa) = '') then
    Result := Invalido(codEmpresa, SErrorEmpresaOpcionesDocumento)
  else
  begin
    Result := ValidarAdicionales(AOpciones, True);
    if Result.EsValido then
      Result := ValidarPrincipales(AConfiguracion, AOpciones,
        ANumeroAutomatico, sPedidos);
    if Result.EsValido then
      Result := ValidarAdicionales(AOpciones, False);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibOpcionesDocumentoIntf                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato del diálogo común que se muestra antes de crear un documento     }
{    a partir de otro (conversiones, borradores, proformas, documentos de      }
{    trabajo): empresa, almacén, tipo, serie, número, fecha, forma de pago     }
{    y movimientos de stock, más los campos propios de cada llamador          }
{    (cliente, referencia del proveedor, documento al que añadir...). Cada     }
{    llamador dice qué campos se ven, cuáles quedan fijos y qué se propone.    }
{******************************************************************************}
unit inLibOpcionesDocumentoIntf;

interface

type
  TCampoOpcionesDocumento = (
    codEmpresa,
    codAlmacen,
    codTipo,
    codSerie,
    codNumero,
    codFecha,
    // Hora del movimiento, como campo aparte de la fecha (entradas de
    // stock: albaranes de compra, devoluciones, inventarios).
    codHora,
    codFormaPago,
    codMueveStock,
    // Un campo propio del llamador (ver TCampoAdicionalOpcionesDocumento).
    codAdicional,
    codConsolidar
  );
  TCamposOpcionesDocumento = set of TCampoOpcionesDocumento;

  // Un tipo de documento que se puede crear desde el diálogo. El código lo
  // identifica en el resultado; Contador es el TIPO_DOC de fza_contadores /
  // fza_empresas_series ('FC', 'FP'...) y vacío equivale al código. Dos
  // tipos pueden compartir contador (abono y duplicado de una factura).
  TTipoOpcionesDocumento = record
    Codigo: string;
    Nombre: string;
    Contador: string;
    // SUBTIPO_EMPSER de las series que valen; vacío = NORMAL o sin subtipo.
    Subtipo: string;
    // La casilla «Genera movimientos de stock» solo tiene sentido en
    // facturas; en albaranes e inventarios los movimientos son obligatorios.
    MueveStockOpcional: Boolean;
    AlmacenObligatorio: Boolean;
    function TipoContador: string;
  end;
  TTiposOpcionesDocumento = TArray<TTipoOpcionesDocumento>;

  TElementoOpcionesDocumento = record
    Codigo: string;
    Nombre: string;
  end;
  TElementosOpcionesDocumento = TArray<TElementoOpcionesDocumento>;

  TClaseCampoAdicional = (
    ccaTexto,
    // Lista de Elementos; ConVacio añade un primer elemento sin valor.
    ccaLista,
    // Valor 'S' / 'N'.
    ccaCasilla,
    // Código con botón de búsqueda (y, si hay Alta, otro de alta rápida);
    // Descripcion muestra el nombre del elegido.
    ccaBusqueda
  );

  // Búsqueda o alta desde el botón del campo: True si el usuario eligió o
  // creó un registro, que se devuelve en ACodigo / ADescripcion.
  TBuscarCampoAdicional = reference to function(
    var ACodigo, ADescripcion: string): Boolean;
  // Nombre del código tecleado a mano; False si no existe.
  TResolverCampoAdicional = reference to function(
    const ACodigo: string; out ADescripcion: string): Boolean;

  TCampoAdicionalOpcionesDocumento = record
    Clave: string;
    Etiqueta: string;
    Clase: TClaseCampoAdicional;
    Valor: string;
    Descripcion: string;
    Elementos: TElementosOpcionesDocumento;
    ConVacio: Boolean;
    Obligatorio: Boolean;
    MensajeObligatorio: string;
    LongitudMaxima: Integer;
    // Se muestra justo debajo de la empresa en vez de al final.
    AlPrincipio: Boolean;
    // Con valor (casilla marcada), estos campos del diálogo no se piden:
    // p. ej. añadir a un documento existente deja sin uso serie y número.
    DeshabilitaConValor: TCamposOpcionesDocumento;
    // Al revés: sin valor (casilla sin marcar) estos campos no se piden;
    // p. ej. la serie de una rectificativa que sólo se emite si se marca.
    DeshabilitaSinValor: TCamposOpcionesDocumento;
    // Códigos de tipo con los que se pide el campo; vacío = con todos. Con
    // otro tipo no se ve, no se valida y vuelve sin valor (p. ej. el motivo
    // de una rectificativa no aplica al duplicado de la factura).
    SoloTipos: TArray<string>;
    Buscar: TBuscarCampoAdicional;
    Alta: TBuscarCampoAdicional;
    Resolver: TResolverCampoAdicional;
    function VisibleConTipo(const ATipo: string): Boolean;
  end;
  TCamposAdicionalesOpcionesDocumento =
    TArray<TCampoAdicionalOpcionesDocumento>;

  // Valores propuestos al abrir y elegidos al aceptar. Numero vacío =
  // numeración automática del contador de la serie. Los campos propios
  // se definen en la propuesta y vuelven con su Valor.
  TOpcionesDocumento = record
    Empresa: string;
    Almacen: string;
    Tipo: string;
    Serie: string;
    Numero: string;
    Fecha: TDate;
    // Sólo cuenta si ConHora (el llamador mostró el campo Hora).
    Hora: TTime;
    ConHora: Boolean;
    FormaPago: string;
    MueveStock: Boolean;
    ConsolidarAlCrear: Boolean;
    Adicionales: TCamposAdicionalesOpcionesDocumento;
    function NumeroAutomatico: Boolean;
    // Fecha + hora elegidas; sin hora, la actual si la fecha es hoy y las
    // 00:00 si es otro día.
    function Instante: TDateTime;
    function Adicional(const AClave: string): string;
    function DescripcionAdicional(const AClave: string): string;
  end;

  // Comprobación propia del llamador al aceptar; con False el diálogo
  // muestra AMensaje y sigue abierto.
  TValidarOpcionesDocumento = reference to function(
    const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;

  TFormaPagoAdicionalDocumento = reference to function(
    const AOpciones: TOpcionesDocumento; out AFormaPago: string): Boolean;

  TConfiguracionOpcionesDocumento = record
    Titulo: string;
    // Texto explicativo opcional encima de los campos.
    Aviso: string;
    TextoConsolidar: string;
    Tipos: TTiposOpcionesDocumento;
    Propuesta: TOpcionesDocumento;
    // Campos que se muestran; el resto no se pide ni se valida.
    Visibles: TCamposOpcionesDocumento;
    // Campos visibles que no se pueden cambiar (p. ej. la empresa de un
    // documento de origen cuyos datos fiscales se copian).
    Fijos: TCamposOpcionesDocumento;
    // False cuando se crean varios documentos de una vez: el número tiene
    // que salir del contador.
    PermiteNumeroManual: Boolean;
    FormaPagoObligatoria: Boolean;
    // Serie vacía admitida: cada documento toma la de su almacén (varios
    // documentos de almacenes distintos creados de una vez).
    SerieOpcional: Boolean;
    Validar: TValidarOpcionesDocumento;
    // True propone una forma de pago al cambiar el tercero; False conserva
    // la elección manual del usuario al modificar otros campos.
    FormaPagoAlCambiarAdicional: TFormaPagoAdicionalDocumento;
  end;

  TResultadoValidacionOpcionesDocumento = record
    EsValido: Boolean;
    Campo: TCampoOpcionesDocumento;
    // Índice del campo propio cuando Campo = codAdicional.
    IndiceAdicional: Integer;
    Mensaje: string;
  end;

  // Datos maestros que necesita el diálogo. Las series de una empresa y
  // tipo reúnen las de Empresas > Series vigentes y los contadores activos
  // (primero el contador por defecto); la serie de almacén es la que
  // Empresas > Series asigna a ese almacén, vacía si no tiene.
  ILectorOpcionesDocumento = interface
    ['{5D0B6F1A-3C47-4E8B-9F21-7A6C2E94B1D3}']
    function ListarEmpresas: TElementosOpcionesDocumento;
    function ListarAlmacenes(
      const AEmpresa: string): TElementosOpcionesDocumento;
    function PrimerAlmacenEstandar(
      const AEmpresa: string): string;
    function ListarSeries(const AEmpresa, ATipo,
      ASubtipo: string): TArray<string>;
    // Serie general vigente de factura normal, sin asociar a almacén.
    function ObtenerSerieGeneralFactura(const AEmpresa: string): string;
    function ObtenerSerieAlmacen(const AEmpresa, ATipo, ASubtipo,
      AAlmacen: string): string;
    function ListarFormasPago: TElementosOpcionesDocumento;
  end;

function TiposFacturaDesdeAlbaran: TTiposOpcionesDocumento;

implementation

uses
  inLibMsgFacturas, inLibMsgOpcionesDocumento, System.SysUtils;

function TiposFacturaDesdeAlbaran: TTiposOpcionesDocumento;
begin
  SetLength(Result, 2);
  Result[0].Codigo := 'FC';
  Result[0].Nombre := SNombreFacturaVentaOpcionesDocumento;
  Result[1].Codigo := 'SIMPLIFICADA';
  Result[1].Nombre := STipoSimplificadaAlbaran;
  Result[1].Contador := 'FC';
  Result[1].Subtipo := 'SIMPLIFICADA';
end;

function TTipoOpcionesDocumento.TipoContador: string;
begin
  Result := Contador;
  if Result = '' then
    Result := Codigo;
end;

function TCampoAdicionalOpcionesDocumento.VisibleConTipo(
  const ATipo: string): Boolean;
var
  sTipo: string;
begin
  Result := Length(SoloTipos) = 0;
  for sTipo in SoloTipos do
  begin
    if SameText(sTipo, ATipo) then
      Result := True;
  end;
end;

function TOpcionesDocumento.NumeroAutomatico: Boolean;
begin
  Result := Numero = '';
end;

function TOpcionesDocumento.Instante: TDateTime;
begin
  if ConHora then
    Result := Trunc(Fecha) + Frac(Hora)
  else if Trunc(Fecha) = Date then
    Result := Now
  else
    Result := Trunc(Fecha);
end;

function TOpcionesDocumento.Adicional(const AClave: string): string;
var
  oCampo: TCampoAdicionalOpcionesDocumento;
begin
  Result := '';
  for oCampo in Adicionales do
  begin
    if SameText(oCampo.Clave, AClave) then
      Result := oCampo.Valor;
  end;
end;

function TOpcionesDocumento.DescripcionAdicional(
  const AClave: string): string;
var
  oCampo: TCampoAdicionalOpcionesDocumento;
begin
  Result := '';
  for oCampo in Adicionales do
  begin
    if SameText(oCampo.Clave, AClave) then
      Result := oCampo.Descripcion;
  end;
end;

end.

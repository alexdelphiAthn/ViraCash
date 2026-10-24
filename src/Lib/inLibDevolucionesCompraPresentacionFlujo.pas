{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevolucionesCompraPresentacionFlujo                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina la presentación del stock y el enlace de líneas de devolución.   }
{******************************************************************************}
unit inLibDevolucionesCompraPresentacionFlujo;

interface

uses
  System.SysUtils,
  Data.DB,
  cxGridDBTableView,
  inLibComprasPantallaIntf,
  inLibDevolucionesCompraStock,
  inLibGridPivoteCompra;

type
  TEstadoPreparacionStockDevolucion = (
    epsdCancelada,
    epsdCompletada,
    epsdRechazada);

  TResultadoPreparacionStockDevolucion = record
    Estado: TEstadoPreparacionStockDevolucion;
    Motivo: TEstadoStockDevolucionCompra;
    Lineas: Integer;
  end;

  TAccionPresentacionStock = procedure of object;
  TObtenerColorPresentacionStock = function(
    const ASerie, ANumero, ALinea: string;
    out AIdColor: Integer): Boolean of object;
  TRestaurarPivotePresentacionStock = procedure(
    ADebeEstarActivo: Boolean) of object;
  TBuscarSkuPresentacion = procedure(
    Sender: TObject;
    AButtonIndex: Integer) of object;

  TContextoPresentacionStockDevolucion = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Persistencia: IPersistenciaStockDevolucionCompra;
    Pivote: TGridPivoteCompra;
    Usuario: string;
    LineaSeleccionada: string;
    CodigoArticulo: string;
    AsegurarCabecera: TAccionPresentacionStock;
    ObtenerColor: TObtenerColorPresentacionStock;
    CalcularTotales: TAccionPresentacionStock;
    RestaurarPivote: TRestaurarPivotePresentacionStock;
  end;

function EjecutarPreparacionStockDevolucion(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra;
  AConfirmada: Boolean): TResultadoPreparacionStockDevolucion;
procedure EjecutarPresentacionStockDevolucion(
  const AContexto: TContextoPresentacionStockDevolucion);
procedure PrepararColorPendienteDevolucion(
  ALineas: TDataSet;
  const ACodigoArticulo: string;
  AIdConjuntoPivote: Integer);
procedure AplicarLineaArticuloDevolucion(
  ALineas: TDataSet;
  const ALinea: TLineaArticuloDevolucionCompra);
function RecogerEntradaArticuloDevolucion(
  const ACodigoIntroducido: string;
  ACabecera, ALineas: TDataSet): TEntradaArticuloDevolucionCompra;
procedure PrepararEdicionArticuloDevolucion(ALineas: TDataSet);
procedure EnfocarSkuDevolucion(
  AGrid: TcxGridDBTableView;
  AAbrirBusqueda: Boolean;
  ABuscarSku: TBuscarSkuPresentacion);

implementation

uses
  inLibMensajesVcl,
  System.Classes,
  System.UITypes,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  cxGridCustomView,
  inLibMsgArticulos,
  inLibMsgCompras;

type
  TValoresColorPendiente = record
    CodigoArticulo: string;
    Referencia: string;
    Familia: string;
    Descripcion: string;
    TipoCantidad: string;
    TipoIva: string;
    Almacen: string;
    IdConjuntoPivote: Integer;
    Iva: Double;
    PrecioSinIva: Double;
    PrecioConIva: Double;
  end;

function LeerTexto(
  ADataSet: TDataSet;
  const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) and not oCampo.IsNull then
      Result := Trim(oCampo.AsString);
  end;
end;

function LeerNumero(
  ADataSet: TDataSet;
  const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) and not oCampo.IsNull then
      Result := oCampo.AsFloat;
  end;
end;

procedure EscribirTexto(
  ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
    oCampo.AsString := AValor;
end;

procedure EscribirNumero(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
    oCampo.AsFloat := AValor;
end;

procedure EscribirEntero(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Integer);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
    oCampo.AsInteger := AValor;
end;

procedure MostrarEstadoStock(
  AEstado: TEstadoStockDevolucionCompra);
begin
  case AEstado of
    esdcProveedorNoIndicado:
      MessageDlg_fza(
        SErrorProveedorDevolucionFilaNoSeleccionado,
        mtWarning, [mbOk], 0);
    esdcAlmacenNoIndicado:
      MessageDlg_fza(
        SErrorAlmacenDevolucionFilaNoSeleccionado,
        mtWarning, [mbOk], 0);
    esdcArticuloNoIndicado:
      MessageDlg_fza(
        SErrorArticuloDevolucionFilaNoSeleccionado,
        mtInformation, [mbOk], 0);
    esdcRequiereColor:
      MessageDlg_fza(
        SErrorColorDevolucionFilaNoSeleccionado,
        mtInformation, [mbOk], 0);
    esdcSinStock:
      MessageDlg_fza(
        SErrorStockDevolucionFilaNoDisponible,
        mtInformation, [mbOk], 0);
  end;
end;

function EjecutarPreparacionStockDevolucion(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra;
  AConfirmada: Boolean): TResultadoPreparacionStockDevolucion;
begin
  Result := Default(TResultadoPreparacionStockDevolucion);
  Result.Estado := epsdCancelada;
  Result.Motivo := esdcDisponible;
  if AConfirmada then
  begin
    if DevolverTodoStockCompra(
      APersistencia,
      AParametros,
      Result.Lineas,
      Result.Motivo) then
      Result.Estado := epsdCompletada
    else
      Result.Estado := epsdRechazada;
  end;
end;

function ContextoStockValido(
  const AContexto: TContextoPresentacionStockDevolucion): Boolean;
begin
  Result := Assigned(AContexto.Cabecera) and
    Assigned(AContexto.Lineas) and
    AContexto.Cabecera.Active and
    not AContexto.Cabecera.IsEmpty and
    Assigned(AContexto.AsegurarCabecera) and
    Assigned(AContexto.ObtenerColor) and
    Assigned(AContexto.CalcularTotales) and
    Assigned(AContexto.RestaurarPivote);
end;

function CrearParametrosStock(
  const AContexto: TContextoPresentacionStockDevolucion):
  TParametrosStockDevolucionCompra;
begin
  Result := Default(TParametrosStockDevolucionCompra);
  Result.Serie := LeerTexto(AContexto.Cabecera, 'SERIE_DEVC');
  Result.Numero := LeerTexto(AContexto.Cabecera, 'NUMERO_DEVC');
  Result.CodigoProveedor := LeerTexto(
    AContexto.Cabecera, 'CODIGO_PRV_DEVC');
  Result.CodigoAlmacen := LeerTexto(
    AContexto.Cabecera, 'CODIGO_ALM_DEVC');
  Result.CodigoArticulo := AContexto.CodigoArticulo;
  Result.Usuario := AContexto.Usuario;
  AContexto.ObtenerColor(
    Result.Serie,
    Result.Numero,
    AContexto.LineaSeleccionada,
    Result.IdColor);
  Result.IvaNormal := LeerNumero(
    AContexto.Cabecera, 'PORCENTAJE_IVAN_DEVC');
  Result.IvaReducido := LeerNumero(
    AContexto.Cabecera, 'PORCENTAJE_IVAR_DEVC');
  Result.IvaSuperreducido := LeerNumero(
    AContexto.Cabecera, 'PORCENTAJE_IVAS_DEVC');
  Result.IvaExento := LeerNumero(
    AContexto.Cabecera, 'PORCENTAJE_IVAE_DEVC');
end;

function PrepararInterfazStock(
  const AContexto: TContextoPresentacionStockDevolucion): Boolean;
begin
  Result := Assigned(AContexto.Pivote) and AContexto.Pivote.Activo;
  Screen.Cursor := crHourGlass;
  if Result then
    AContexto.Pivote.Desactivar;
  if AContexto.Lineas.Active then
    AContexto.Lineas.Close;
end;

procedure RestaurarInterfazStock(
  const AContexto: TContextoPresentacionStockDevolucion;
  APivoteActivo: Boolean);
begin
  Screen.Cursor := crDefault;
  if not AContexto.Lineas.Active then
    AContexto.Lineas.Open;
  AContexto.RestaurarPivote(APivoteActivo);
end;

procedure PresentarPreparacionCompletada(
  const AContexto: TContextoPresentacionStockDevolucion;
  const AResultado: TResultadoPreparacionStockDevolucion);
begin
  if not AContexto.Lineas.Active then
    AContexto.Lineas.Open;
  AContexto.CalcularTotales;
  if AContexto.Cabecera.State in dsEditModes then
    AContexto.Cabecera.Post;
  MessageDlg_fza(
    Format(SInfoStockFilaDevolucionPreparado, [AResultado.Lineas]),
    mtInformation, [mbOk], 0);
end;

procedure EjecutarOperacionStockConfirmada(
  const AContexto: TContextoPresentacionStockDevolucion;
  const AParametros: TParametrosStockDevolucionCompra);
var
  EsPivoteActivo: Boolean;
  oResultado: TResultadoPreparacionStockDevolucion;
begin
  EsPivoteActivo := PrepararInterfazStock(AContexto);
  try
    oResultado := EjecutarPreparacionStockDevolucion(
      AContexto.Persistencia,
      AParametros,
      True);
    if oResultado.Estado = epsdCompletada then
      PresentarPreparacionCompletada(AContexto, oResultado)
    else
      MostrarEstadoStock(oResultado.Motivo);
  finally
    RestaurarInterfazStock(AContexto, EsPivoteActivo);
  end;
end;

procedure EjecutarPresentacionStockDevolucion(
  const AContexto: TContextoPresentacionStockDevolucion);
var
  oParametros: TParametrosStockDevolucionCompra;
  oEstado: TEstadoStockDevolucionCompra;
begin
  if ContextoStockValido(AContexto) then
  begin
    AContexto.AsegurarCabecera;
    if AContexto.Lineas.Active and
       (AContexto.Lineas.State in dsEditModes) then
      AContexto.Lineas.Post;
    if AContexto.LineaSeleccionada = '' then
      MessageDlg_fza(
        SErrorFilaDevolucionStockNoSeleccionada,
        mtInformation, [mbOk], 0)
    else
    begin
      oParametros := CrearParametrosStock(AContexto);
      oEstado := ConsultarEstadoStockDevolucionCompra(
        AContexto.Persistencia,
        oParametros);
      if oEstado <> esdcDisponible then
        MostrarEstadoStock(oEstado)
      else if MessageDlg_fza(
        SPreguntaPrepararStockFilaDevolucion,
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        EjecutarOperacionStockConfirmada(AContexto, oParametros);
    end;
  end;
end;

procedure AplicarValoresColorPendiente(
  ALineas: TDataSet;
  const AValores: TValoresColorPendiente);
begin
  EscribirTexto(
    ALineas, 'CODIGO_ART_DEVCLIN', AValores.CodigoArticulo);
  EscribirTexto(ALineas, 'CODIGO_UNIDAD_DEVCLIN', '');
  EscribirTexto(ALineas, 'REF_PRV_DEVCLIN', AValores.Referencia);
  EscribirTexto(ALineas, 'CODIGO_FAM_DEVCLIN', AValores.Familia);
  EscribirTexto(
    ALineas, 'DESCRIPCION_ARTICULO_DEVCLIN', AValores.Descripcion);
  EscribirTexto(
    ALineas, 'TIPO_CANTIDAD_ARTICULO_DEVCLIN', AValores.TipoCantidad);
  EscribirTexto(
    ALineas, 'TIPO_IVA_ARTICULO_DEVCLIN', AValores.TipoIva);
  EscribirTexto(ALineas, 'CODIGO_ALMACEN_DEVCLIN', AValores.Almacen);
  EscribirEntero(
    ALineas, 'ID_AC_PIVOT_DEVCLIN', AValores.IdConjuntoPivote);
  EscribirNumero(ALineas, 'PORCENTAJE_IVA_DEVCLIN', AValores.Iva);
  EscribirNumero(
    ALineas,
    'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
    AValores.PrecioSinIva);
  EscribirNumero(
    ALineas,
    'PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN',
    AValores.PrecioConIva);
  EscribirNumero(ALineas, 'CANTIDAD_DEVCLIN', 0);
  EscribirNumero(ALineas, 'TOTAL_UNIDADES_DEVCLIN', 0);
  EscribirNumero(ALineas, 'TOTAL_DEVCLIN', 0);
end;

procedure PrepararColorPendienteDevolucion(
  ALineas: TDataSet;
  const ACodigoArticulo: string;
  AIdConjuntoPivote: Integer);
var
  oValores: TValoresColorPendiente;
begin
  if (ACodigoArticulo <> '') and
     (AIdConjuntoPivote > 0) and
     Assigned(ALineas) and ALineas.Active then
  begin
    oValores := Default(TValoresColorPendiente);
    oValores.CodigoArticulo := ACodigoArticulo;
    oValores.Referencia := LeerTexto(ALineas, 'REF_PRV_DEVCLIN');
    oValores.Familia := LeerTexto(ALineas, 'CODIGO_FAM_DEVCLIN');
    oValores.Descripcion := LeerTexto(
      ALineas, 'DESCRIPCION_ARTICULO_DEVCLIN');
    oValores.TipoCantidad := LeerTexto(
      ALineas, 'TIPO_CANTIDAD_ARTICULO_DEVCLIN');
    oValores.TipoIva := LeerTexto(
      ALineas, 'TIPO_IVA_ARTICULO_DEVCLIN');
    oValores.Almacen := LeerTexto(
      ALineas, 'CODIGO_ALMACEN_DEVCLIN');
    oValores.IdConjuntoPivote := AIdConjuntoPivote;
    oValores.Iva := LeerNumero(ALineas, 'PORCENTAJE_IVA_DEVCLIN');
    oValores.PrecioSinIva := LeerNumero(
      ALineas, 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN');
    oValores.PrecioConIva := LeerNumero(
      ALineas, 'PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN');
    if not (ALineas.State in dsEditModes) then
      ALineas.Edit;
    AplicarValoresColorPendiente(ALineas, oValores);
    ALineas.Post;
  end;
end;

procedure AplicarLineaArticuloDevolucion(
  ALineas: TDataSet;
  const ALinea: TLineaArticuloDevolucionCompra);
var
  oCampo: TField;
begin
  ALineas.FieldByName('CODIGO_ART_DEVCLIN').AsString :=
    ALinea.CodigoArticulo;
  ALineas.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString :=
    ALinea.CodigoSku;
  ALineas.FieldByName('REF_PRV_DEVCLIN').AsString :=
    ALinea.ReferenciaProveedor;
  ALineas.FieldByName('CODIGO_FAM_DEVCLIN').AsString :=
    ALinea.CodigoFamilia;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_DEVCLIN').AsString :=
    ALinea.DescripcionArticulo;
  ALineas.FieldByName('TIPO_CANTIDAD_ARTICULO_DEVCLIN').AsString :=
    ALinea.TipoCantidad;
  ALineas.FieldByName('TIPO_IVA_ARTICULO_DEVCLIN').AsString :=
    ALinea.TipoIva;
  ALineas.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN').AsFloat :=
    ALinea.PrecioCompra;
  if ALinea.AsignarAlmacen then
    ALineas.FieldByName('CODIGO_ALMACEN_DEVCLIN').AsString :=
      ALinea.CodigoAlmacen;
  oCampo := ALineas.FindField('ID_AC_PIVOT_DEVCLIN');
  if Assigned(oCampo) then
  begin
    if ALinea.IdConjuntoPivote > 0 then
      oCampo.AsInteger := ALinea.IdConjuntoPivote
    else
      oCampo.Clear;
  end;
  if ALinea.AsignarCantidad then
    ALineas.FieldByName('CANTIDAD_DEVCLIN').AsFloat := ALinea.Cantidad;
  if ALinea.AsignarTotalUnidades then
    ALineas.FieldByName('TOTAL_UNIDADES_DEVCLIN').AsFloat :=
      ALinea.TotalUnidades;
  ALineas.FieldByName('TOTAL_DEVCLIN').AsFloat := ALinea.Total;
end;

function RecogerEntradaArticuloDevolucion(
  const ACodigoIntroducido: string;
  ACabecera, ALineas: TDataSet): TEntradaArticuloDevolucionCompra;
begin
  Result := Default(TEntradaArticuloDevolucionCompra);
  Result.CodigoIntroducido := ACodigoIntroducido;
  Result.CodigoProveedor := LeerTexto(ACabecera, 'CODIGO_PRV_DEVC');
  Result.CodigoAlmacen := LeerTexto(ACabecera, 'CODIGO_ALM_DEVC');
  Result.Fecha := Date;
  if not ACabecera.FieldByName('FECHA_DEVC').IsNull then
    Result.Fecha := ACabecera.FieldByName('FECHA_DEVC').AsDateTime;
  Result.CantidadActual := LeerNumero(ALineas, 'CANTIDAD_DEVCLIN');
end;

procedure PrepararEdicionArticuloDevolucion(ALineas: TDataSet);
begin
  if ALineas.IsEmpty then
    ALineas.Append;
  if not (ALineas.State in dsEditModes) then
    ALineas.Edit;
end;

procedure EnfocarSkuDevolucion(
  AGrid: TcxGridDBTableView;
  AAbrirBusqueda: Boolean;
  ABuscarSku: TBuscarSkuPresentacion);
var
  oAccion: TThreadProcedure;
  oColumnaSku: TcxGridDBColumn;
begin
  oColumnaSku := AGrid.GetColumnByFieldName('CODIGO_UNIDAD_DEVCLIN');
  if Assigned(oColumnaSku) then
  begin
    oColumnaSku.Visible := True;
    oAccion :=
      procedure
      begin
        AGrid.Controller.FocusedColumn := oColumnaSku;
        AGrid.Controller.EditingController.ShowEdit;
        if AAbrirBusqueda and Assigned(ABuscarSku) then
          ABuscarSku(nil, 0);
      end;
    TThread.ForceQueue(nil, oAccion);
  end;
end;

end.

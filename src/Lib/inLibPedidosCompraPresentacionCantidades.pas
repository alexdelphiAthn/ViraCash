{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraPresentacionCantidades                    }
{    Tipo:       Librería                                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Gestiona las cantidades visuales elegidas para recibir un pedido.        }
{******************************************************************************}
unit inLibPedidosCompraPresentacionCantidades;

interface

uses
  Data.DB,
  cxEdit,
  cxGridDBTableView,
  inLibGridPivoteCompra,
  inLibPedidosCompraPresentacionRecepcion;

type
  TConfigCantidadesRecepcionPedidoCompra = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Vista: TcxGridDBTableView;
    ColumnaVertical: TcxGridDBColumn;
    Pivote: TGridPivoteCompra;
  end;
  TCantidadesRecepcionPedidoCompra = class(
    TInterfacedObject, ISeleccionCantidadesRecepcionPedidoCompra)
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FVista: TcxGridDBTableView;
    FColumnaVertical: TcxGridDBColumn;
    FPivote: TGridPivoteCompra;
    function TieneLineas: Boolean;
    function AlmacenEfectivoActual: string;
    function ValorVertical(AIndiceRegistro: Integer): Double;
    function PendienteActual: Double;
    function TotalCampo: Double;
    function TotalVertical: Double;
    function PrimerAlmacenCampo: string;
    function PrimerAlmacenVertical: string;
    function RecogerCampo(
      const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
    function RecogerVertical(
      const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
    procedure LimpiarCampo(const ACodigoAlmacen: string);
    procedure LimpiarVertical;
    function RellenarCampo: Integer;
    function RellenarVertical: Integer;
  public
    constructor Create(
      const AConfig: TConfigCantidadesRecepcionPedidoCompra);
    function PrimerAlmacen(AUsarCampo: Boolean): string;
    function Recoger(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean): TArray<TCeldaARecibir>;
    procedure Limpiar(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean);
    function Total(AUsarCampo: Boolean): Double;
    function RellenarTodo(AUsarCampo: Boolean): Integer;
    function RellenarFila(AUsarCampo: Boolean): Integer;
    procedure LimitarCampo(Sender: TObject);
    procedure LimitarVertical(Sender: TObject);
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Variants,
  System.Generics.Collections,
  inLibGridPivoteCompraTipos;

function NumeroVariante(const AValor: Variant): Double;
begin
  Result := 0;
  if not (VarIsNull(AValor) or VarIsEmpty(AValor)) then
  begin
    if VarIsNumeric(AValor) then
      Result := AValor
    else
      Result := StrToFloatDef(VarToStr(AValor), 0);
  end;
end;

constructor TCantidadesRecepcionPedidoCompra.Create(
  const AConfig: TConfigCantidadesRecepcionPedidoCompra);
begin
  inherited Create;
  if AConfig.Cabecera = nil then
    raise EArgumentNilException.Create('AConfig.Cabecera');
  if AConfig.Lineas = nil then
    raise EArgumentNilException.Create('AConfig.Lineas');
  if AConfig.Vista = nil then
    raise EArgumentNilException.Create('AConfig.Vista');
  FCabecera := AConfig.Cabecera;
  FLineas := AConfig.Lineas;
  FVista := AConfig.Vista;
  FColumnaVertical := AConfig.ColumnaVertical;
  FPivote := AConfig.Pivote;
end;

function TCantidadesRecepcionPedidoCompra.TieneLineas: Boolean;
begin
  Result := FLineas.Active and not FLineas.IsEmpty;
end;

function TCantidadesRecepcionPedidoCompra.AlmacenEfectivoActual: string;
begin
  Result := Trim(
    FLineas.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString);
  if Result = '' then
    Result := FCabecera.FieldByName('CODIGO_ALM_PEDC').AsString;
end;

function TCantidadesRecepcionPedidoCompra.ValorVertical(
  AIndiceRegistro: Integer): Double;
begin
  Result := 0;
  if FColumnaVertical <> nil then
    Result := NumeroVariante(FVista.DataController.Values[
      AIndiceRegistro, FColumnaVertical.Index]);
end;

function TCantidadesRecepcionPedidoCompra.PendienteActual: Double;
begin
  Result := FLineas.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
    FLineas.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
  if Result < 0 then
    Result := 0;
end;

function TCantidadesRecepcionPedidoCompra.TotalCampo: Double;
var
  Marca: TBookmark;
begin
  Result := 0;
  if TieneLineas and not (FLineas.State in dsEditModes) and
     (FLineas.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
  begin
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        Result := Result + FLineas.FieldByName(
          'CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat;
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.TotalVertical: Double;
var
  Marca: TBookmark;
  Indice: Integer;
  Cantidad: Double;
begin
  Result := 0;
  if TieneLineas and (FColumnaVertical <> nil) then
  begin
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      Indice := 0;
      FLineas.First;
      while not FLineas.Eof do
      begin
        Cantidad := ValorVertical(Indice);
        if Cantidad > 0 then
          Result := Result + Cantidad;
        Inc(Indice);
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.Total(
  AUsarCampo: Boolean): Double;
begin
  if AUsarCampo then
    Result := TotalCampo
  else if Assigned(FPivote) and FPivote.Activo and
          FPivote.Expandido then
    Result := FPivote.TotalARecibir
  else
    Result := TotalVertical;
end;

function TCantidadesRecepcionPedidoCompra.PrimerAlmacenCampo: string;
var
  Marca: TBookmark;
begin
  Result := '';
  if TieneLineas and
     (FLineas.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
  begin
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while (Result = '') and not FLineas.Eof do
      begin
        if FLineas.FieldByName(
          'CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat > 0 then
          Result := AlmacenEfectivoActual;
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.PrimerAlmacenVertical: string;
var
  Marca: TBookmark;
  Indice: Integer;
begin
  Result := '';
  if TieneLineas and (FColumnaVertical <> nil) then
  begin
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      Indice := 0;
      FLineas.First;
      while (Result = '') and not FLineas.Eof do
      begin
        if ValorVertical(Indice) > 0 then
          Result := AlmacenEfectivoActual;
        Inc(Indice);
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.PrimerAlmacen(
  AUsarCampo: Boolean): string;
begin
  if AUsarCampo then
    Result := PrimerAlmacenCampo
  else if Assigned(FPivote) and FPivote.Activo and
          FPivote.Expandido then
    Result := FPivote.PrimerAlmacenARecibir
  else
    Result := PrimerAlmacenVertical;
end;

function CrearCeldaRecepcion(
  ALineas: TDataSet;
  const ACodigoAlmacen: string;
  ACantidad: Double): TCeldaARecibir;
begin
  Result := Default(TCeldaARecibir);
  Result.LineaPedido :=
    ALineas.FieldByName('LINEA_PEDCLIN').AsString;
  Result.CodigoSku :=
    ALineas.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
  Result.CodigoAlmacen := ACodigoAlmacen;
  Result.Cantidad := ACantidad;
end;

function TCantidadesRecepcionPedidoCompra.RecogerCampo(
  const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
var
  Celdas: TList<TCeldaARecibir>;
  Marca: TBookmark;
  Cantidad: Double;
  Almacen: string;
begin
  Result := nil;
  if TieneLineas and
     (FLineas.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
  begin
    Celdas := TList<TCeldaARecibir>.Create;
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        Cantidad := FLineas.FieldByName(
          'CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat;
        Almacen := AlmacenEfectivoActual;
        if (Cantidad > 0) and SameText(
          Almacen, ACodigoAlmacen) then
          Celdas.Add(CrearCeldaRecepcion(
            FLineas, Almacen, Cantidad));
        FLineas.Next;
      end;
      Result := Celdas.ToArray;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
      FreeAndNil(Celdas);
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.RecogerVertical(
  const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
var
  Celdas: TList<TCeldaARecibir>;
  Marca: TBookmark;
  Indice: Integer;
  Cantidad: Double;
  Almacen: string;
begin
  Result := nil;
  if TieneLineas and (FColumnaVertical <> nil) then
  begin
    Celdas := TList<TCeldaARecibir>.Create;
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      Indice := 0;
      FLineas.First;
      while not FLineas.Eof do
      begin
        Cantidad := ValorVertical(Indice);
        Almacen := AlmacenEfectivoActual;
        if (Cantidad > 0) and SameText(
          Almacen, ACodigoAlmacen) then
          Celdas.Add(CrearCeldaRecepcion(
            FLineas, Almacen, Cantidad));
        Inc(Indice);
        FLineas.Next;
      end;
      Result := Celdas.ToArray;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
      FreeAndNil(Celdas);
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.Recoger(
  const ACodigoAlmacen: string;
  AUsarCampo: Boolean): TArray<TCeldaARecibir>;
begin
  if AUsarCampo then
    Result := RecogerCampo(ACodigoAlmacen)
  else if Assigned(FPivote) and FPivote.Activo and
          FPivote.Expandido then
    Result := FPivote.IterarARecibirPorAlmacen(ACodigoAlmacen)
  else
    Result := RecogerVertical(ACodigoAlmacen);
end;

procedure TCantidadesRecepcionPedidoCompra.LimpiarCampo(
  const ACodigoAlmacen: string);
begin
  // La recepción ya limpió el almacén en su transacción. Solo releer;
  // Edit/Post volvería a escribir después de confirmar el documento.
  if FLineas.Active and (FLineas.State = dsBrowse) then
    FLineas.Refresh;
end;

procedure TCantidadesRecepcionPedidoCompra.LimpiarVertical;
var
  Indice: Integer;
begin
  if FColumnaVertical <> nil then
  begin
    FVista.DataController.BeginUpdate;
    try
      for Indice := 0 to FVista.DataController.RecordCount - 1 do
        FVista.DataController.Values[
          Indice, FColumnaVertical.Index] := Null;
    finally
      FVista.DataController.EndUpdate;
    end;
  end;
end;

procedure TCantidadesRecepcionPedidoCompra.Limpiar(
  const ACodigoAlmacen: string;
  AUsarCampo: Boolean);
begin
  if AUsarCampo then
    LimpiarCampo(ACodigoAlmacen)
  else if Assigned(FPivote) and FPivote.Activo and
          FPivote.Expandido then
    FPivote.LimpiarARecibirParaAlmacen(ACodigoAlmacen)
  else
    LimpiarVertical;
end;

function TCantidadesRecepcionPedidoCompra.RellenarCampo: Integer;
var
  Marca: TBookmark;
  Pendiente: Double;
begin
  Result := 0;
  if TieneLineas and
     (FLineas.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
  begin
    if FLineas.State in dsEditModes then
      FLineas.Post;
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        Pendiente := PendienteActual;
        if FLineas.FieldByName(
          'CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat <> Pendiente then
        begin
          FLineas.Edit;
          FLineas.FieldByName(
            'CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat := Pendiente;
          FLineas.Post;
        end;
        if Pendiente > 0 then
          Inc(Result);
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.RellenarVertical: Integer;
var
  Marca: TBookmark;
  Indice: Integer;
  Pendiente: Double;
begin
  Result := 0;
  if TieneLineas and (FColumnaVertical <> nil) then
  begin
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    FVista.DataController.BeginUpdate;
    try
      Indice := 0;
      FLineas.First;
      while not FLineas.Eof do
      begin
        Pendiente := PendienteActual;
        if Pendiente > 0 then
        begin
          FVista.DataController.Values[
            Indice, FColumnaVertical.Index] := Pendiente;
          Inc(Result);
        end
        else
          FVista.DataController.Values[
            Indice, FColumnaVertical.Index] := Null;
        Inc(Indice);
        FLineas.Next;
      end;
    finally
      FVista.DataController.EndUpdate;
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
      FLineas.FreeBookmark(Marca);
      FLineas.EnableControls;
    end;
  end;
end;

function TCantidadesRecepcionPedidoCompra.RellenarFila(
  AUsarCampo: Boolean): Integer;
var
  rPendiente: Double;
  iRegistro: Integer;
begin
  Result := 0;
  if TieneLineas then
  begin
    if FLineas.State in dsEditModes then
      FLineas.Post;
    rPendiente := PendienteActual;
    if AUsarCampo then
    begin
      FLineas.Edit;
      FLineas.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat :=
        rPendiente;
      FLineas.Post;
    end
    else if Assigned(FColumnaVertical) then
    begin
      iRegistro := FVista.DataController.FocusedRecordIndex;
      if iRegistro >= 0 then
        FVista.DataController.Values[iRegistro, FColumnaVertical.Index] :=
          rPendiente;
    end;
    if rPendiente > 0 then
      Result := 1;
  end;
end;

function TCantidadesRecepcionPedidoCompra.RellenarTodo(
  AUsarCampo: Boolean): Integer;
begin
  if AUsarCampo then
    Result := RellenarCampo
  else if Assigned(FPivote) and FPivote.Activo then
  begin
    if not FPivote.Expandido then
      FPivote.Expandir;
    Result := FPivote.RecibirTodo;
  end
  else
    Result := RellenarVertical;
end;

procedure TCantidadesRecepcionPedidoCompra.LimitarCampo(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
  Cantidad: Double;
  Pendiente: Double;
begin
  if (Sender is TcxCustomEdit) and TieneLineas then
  begin
    Editor := TcxCustomEdit(Sender);
    Cantidad := NumeroVariante(Editor.EditValue);
    Pendiente := PendienteActual;
    if Cantidad > Pendiente then
    begin
      MessageBeep(MB_ICONWARNING);
      Editor.EditValue := Pendiente;
    end;
  end;
end;

procedure TCantidadesRecepcionPedidoCompra.LimitarVertical(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
  Cantidad: Double;
  Pendiente: Double;
begin
  if (Sender is TcxCustomEdit) and TieneLineas and
     ((FPivote = nil) or not FPivote.Activo) then
  begin
    Editor := TcxCustomEdit(Sender);
    Cantidad := NumeroVariante(Editor.EditValue);
    Pendiente := PendienteActual;
    if Cantidad > Pendiente then
    begin
      MessageBeep(MB_ICONWARNING);
      if Pendiente > 0 then
        Editor.EditValue := Pendiente
      else
        Editor.EditValue := Null;
    end;
  end;
end;

end.

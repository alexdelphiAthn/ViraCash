{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompraEdicion                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Edición, persistencia de cantidades y recepción del pivote de compra.    }
{******************************************************************************}
unit inLibGridPivoteCompraEdicion;

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Data.DB,
  cxEdit, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibGridPivoteCompraTipos,
  inLibGridTallasInline,
  inLibGridPivoteCompraPersistenciaIntf,
  inLibPivoteCompraCorrespondencia,
  inLibPivoteCompraEstadoEdicion,
  inLibPivoteCompraValidacion,
  inLibGridPivoteCompraPresentacion;

type
  TEdicionPivoteCompra = class
  private
    FCfg            : TGridPivoteCompraConfig;
    FRepositorio    : TRepositoriosGridPivoteCompra;
    FCorrespondencia: TCorrespondenciaPivoteCompra;
    FCache          : TCachePivoteCompra;
    FEstado         : TEstadoEdicionPivoteCompra;
    // Cantidad de la línea real antes de GrabarCantidadLinea (FZ-ISSUE-255).
    FCantidadAntesDeGrabar: Double;
    FValidador      : TValidadorPivoteCompra;
    FPresentacion   : TPresentacionPivoteCompra;
    FActualizando   : Boolean;
    FGuardando      : Boolean;
    procedure RegistrarSesion(const ATexto: string);
    procedure CapturarEditorActivo;
    procedure CapturarValoresVisibles;
    function ObtenerValorEditor(AEditor: TcxCustomEdit;
      ARegistro: TcxCustomGridRecord; AColumna: TcxGridColumn;
      AValorPreferente: Variant): Double;
    procedure GrabarCantidadLinea(const ALineaReal, ALineaFoco: string;
      ACantidad: Double);
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig;
      const ARepositorio: TRepositoriosGridPivoteCompra;
      ACorrespondencia: TCorrespondenciaPivoteCompra;
      AEstado: TEstadoEdicionPivoteCompra;
      AValidador: TValidadorPivoteCompra;
      APresentacion: TPresentacionPivoteCompra);
    procedure Limpiar;
    function IterarARecibirPorAlmacen(const ACodigoAlmacen: string)
      : TArray<TCeldaARecibir>;
    procedure LimpiarARecibirParaAlmacen(const ACodigoAlmacen: string);
    function ProcesarTeclaCeldaTalla(AKey: Word): Boolean;
    function GetInfoCeldaTallaActiva(out ATallaCaption: string;
      out APedido, ARecibida: Double): Boolean;
    function RecibirFilaEntera: Integer;
    function RecibirTodo: Integer;
    procedure PersistirCantidadEditValueChanged(ASender: TObject;
      var AValorEditado: Variant);
    procedure CapturarCantidadEditValueChanged(ASender: TObject);
    function PersistirCantidadesPendientes: Integer;
    procedure CapturarARecibirEditValueChanged(ASender: TObject);
    function PrimerAlmacenARecibir: string;
    function TotalARecibir: Double;
    function ColorCodigoLineaActiva: string;
    function CambiarColorLineaActiva(const ACodigoAtbColor: string;
      out AMensaje: string): Boolean;
  end;
implementation
uses
  Winapi.Windows,
  inLibMsgCompras, inLibPivoteCompraCalculo;

constructor TEdicionPivoteCompra.Create(
  const ACfg: TGridPivoteCompraConfig;
  const ARepositorio: TRepositoriosGridPivoteCompra;
  ACorrespondencia: TCorrespondenciaPivoteCompra;
  AEstado: TEstadoEdicionPivoteCompra;
  AValidador: TValidadorPivoteCompra;
  APresentacion: TPresentacionPivoteCompra);
begin
  inherited Create;
  FCfg := ACfg;
  FRepositorio := ARepositorio;
  FCorrespondencia := ACorrespondencia;
  FCache := ACorrespondencia.Cache;
  FEstado := AEstado;
  FValidador := AValidador;
  FPresentacion := APresentacion;
  FActualizando := False;
  FGuardando := False;
end;

procedure TEdicionPivoteCompra.Limpiar;
begin
  FEstado.Limpiar;
  FActualizando := False;
  FGuardando := False;
end;

procedure TEdicionPivoteCompra.RegistrarSesion(const ATexto: string);
begin
  if FCfg.ContextoSesion <> nil then
    FCfg.ContextoSesion.LogSesion(ATexto);
end;

function TEdicionPivoteCompra.IterarARecibirPorAlmacen(
  const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
var
  oResultado : TList<TCeldaARecibir>;
  oPar       : TPair<Int64, Double>;
  oCelda     : TCeldaARecibir;
  sSku       : string;
  sAlmacen   : string;
  sLinea     : string;
begin
  Result := nil;
  oResultado := TList<TCeldaARecibir>.Create;
  try
    if FPresentacion.Activo and (FCfg.Gestor <> nil) then
    begin
      for oPar in FEstado.ARecibir do
      begin
        sSku := '';
        sAlmacen := '';
        sLinea := '';
        if (oPar.Value > 0) and
           FCache.CeldaSku.TryGetValue(oPar.Key, sSku) and
           FCache.CeldaAlmacen.TryGetValue(oPar.Key, sAlmacen) and
           FCache.CeldaLineaPedido.TryGetValue(oPar.Key, sLinea) and
           SameText(sAlmacen, ACodigoAlmacen) then
        begin
          oCelda := Default(TCeldaARecibir);
          oCelda.LineaPedido := sLinea;
          oCelda.CodigoSku := sSku;
          oCelda.CodigoAlmacen := sAlmacen;
          oCelda.Cantidad := oPar.Value;
          oResultado.Add(oCelda);
        end;
      end;
    end;
    Result := oResultado.ToArray;
  finally
    FreeAndNil(oResultado);
  end;
end;

procedure TEdicionPivoteCompra.LimpiarARecibirParaAlmacen(
  const ACodigoAlmacen: string);
var
  oPar     : TPair<Int64, Double>;
  oClaves  : TList<Int64>;
  iClave   : Int64;
  sAlmacen : string;
begin
  oClaves := TList<Int64>.Create;
  try
    for oPar in FEstado.ARecibir do
    begin
      sAlmacen := '';
      if FCache.CeldaAlmacen.TryGetValue(oPar.Key, sAlmacen) and
         SameText(sAlmacen, ACodigoAlmacen) then
        oClaves.Add(oPar.Key);
    end;
    for iClave in oClaves do
      FEstado.ARecibir.Remove(iClave);
  finally
    FreeAndNil(oClaves);
  end;
  if (FCfg.Grid <> nil) and (FCfg.Grid.Site <> nil) then
    FCfg.Grid.Site.Invalidate;
end;

function TEdicionPivoteCompra.ProcesarTeclaCeldaTalla(
  AKey: Word): Boolean;
var
  oRegistro    : TcxCustomGridRecord;
  oColumna     : TcxGridColumn;
  oColumnaLinea: TcxGridColumn;
  vLinea       : Variant;
  vValor       : Variant;
  aPosiciones  : TArrPosConjunto;
  iLinea       : Integer;
  iConjunto    : Integer;
  iRegistro    : Integer;
  iColumna     : Integer;
  iClave       : Int64;
  iTalla       : Integer;
  sValor       : string;
  cDigito      : Char;
  bCeldaValida : Boolean;
begin
  Result := False;
  bCeldaValida := FPresentacion.Activo and
    FPresentacion.Expandido and FPresentacion.PuedeExpandir and
    (FCfg.Grid <> nil);
  if bCeldaValida then
  begin
    oRegistro := FCfg.Grid.Controller.FocusedRecord;
    oColumna := FCfg.Grid.Controller.FocusedColumn;
    bCeldaValida := (oRegistro <> nil) and (oColumna <> nil) and
      (oColumna.Tag >= 1) and
      (oColumna.Tag <= FCfg.MaxColumnasTallas) and
      (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
      (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
    oColumnaLinea := nil;
    if bCeldaValida then
      oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if oColumnaLinea <> nil then
    begin
      vLinea := oRegistro.Values[oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    iConjunto := 0;
    if iLinea > 0 then
      FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
    bCeldaValida := bCeldaValida and (iConjunto > 0);
    if bCeldaValida then
    begin
      aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
        iConjunto, FCache.ArticuloLinea(iLinea));
      bCeldaValida := oColumna.Tag <= Length(aPosiciones);
    end;
    if bCeldaValida then
    begin
      iRegistro := oRegistro.RecordIndex;
      iColumna := oColumna.Index;
      vValor := FCfg.Grid.DataController.Values[iRegistro, iColumna];
      sValor := '';
      if not (VarIsNull(vValor) or VarIsEmpty(vValor)) then
      begin
        if VarIsNumeric(vValor) then
          sValor := IntToStr(Round(Double(vValor)))
        else
          sValor := VarToStr(vValor);
      end;
      case AKey of
        VK_BACK:
          begin
            if sValor <> '' then
              sValor := Copy(sValor, 1, Length(sValor) - 1);
            Result := True;
          end;
        VK_DELETE, VK_ESCAPE:
          begin
            sValor := '';
            Result := True;
          end;
        Ord('0')..Ord('9'):
          begin
            cDigito := Char(AKey);
            sValor := sValor + cDigito;
            Result := True;
          end;
        VK_NUMPAD0..VK_NUMPAD9:
          begin
            cDigito := Char(Ord('0') + AKey - VK_NUMPAD0);
            sValor := sValor + cDigito;
            Result := True;
          end;
      end;
      if Result then
      begin
        FCfg.Grid.DataController.BeginUpdate;
        try
          if sValor = '' then
            FCfg.Grid.DataController.Values[iRegistro, iColumna] := Null
          else
            FCfg.Grid.DataController.Values[iRegistro, iColumna] :=
              StrToIntDef(sValor, 0);
        finally
          FCfg.Grid.DataController.EndUpdate;
        end;
        iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
        iClave := ClaveCeldaPivoteCompra(iLinea, iTalla);
        if sValor = '' then
          FEstado.ARecibir.Remove(iClave)
        else
          FEstado.ARecibir.AddOrSetValue(iClave,
            StrToIntDef(sValor, 0));
      end;
    end;
  end;
end;

function TEdicionPivoteCompra.GetInfoCeldaTallaActiva(
  out ATallaCaption: string; out APedido, ARecibida: Double): Boolean;
var
  oRegistro    : TcxCustomGridRecord;
  oColumna     : TcxGridColumn;
  oColumnaLinea: TcxGridColumn;
  vLinea       : Variant;
  aPosiciones  : TArrPosConjunto;
  iLinea       : Integer;
  iConjunto    : Integer;
  iClave       : Int64;
  iTalla       : Integer;
  bValida      : Boolean;
begin
  ATallaCaption := '';
  APedido := 0;
  ARecibida := 0;
  bValida := FPresentacion.Activo and FPresentacion.Expandido and
    FPresentacion.PuedeExpandir and (FCfg.Grid <> nil);
  if bValida then
  begin
    oRegistro := FCfg.Grid.Controller.FocusedRecord;
    oColumna := FCfg.Grid.Controller.FocusedColumn;
    bValida := (oRegistro <> nil) and (oColumna <> nil) and
      (oColumna.Tag >= 1) and
      (oColumna.Tag <= FCfg.MaxColumnasTallas) and
      (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
      (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
    oColumnaLinea := nil;
    if bValida then
      oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if oColumnaLinea <> nil then
    begin
      vLinea := oRegistro.Values[oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    iConjunto := 0;
    if iLinea > 0 then
      FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
    bValida := bValida and (iConjunto > 0);
    if bValida then
    begin
      aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
        iConjunto, FCache.ArticuloLinea(iLinea));
      bValida := oColumna.Tag <= Length(aPosiciones);
    end;
    if bValida then
    begin
      iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
      ATallaCaption := aPosiciones[oColumna.Tag - 1].Valor;
      iClave := ClaveCeldaPivoteCompra(iLinea, iTalla);
      FCache.Cantidades.TryGetValue(iClave, APedido);
      FCache.CantidadesRecibidas.TryGetValue(iClave, ARecibida);
    end;
  end;
  Result := bValida;
end;

function TEdicionPivoteCompra.RecibirFilaEntera: Integer;
var
  oRegistro    : TcxCustomGridRecord;
  oColumnaLinea: TcxGridColumn;
  oColumnaTalla: TcxGridDBColumn;
  vLinea       : Variant;
  aPosiciones  : TArrPosConjunto;
  iLinea       : Integer;
  iConjunto    : Integer;
  iPosicion    : Integer;
  iRegistro    : Integer;
  iClave       : Int64;
  dPedida      : Double;
  dRecibida    : Double;
  dPendiente   : Double;
begin
  Result := 0;
  if FPresentacion.Activo and FPresentacion.Expandido and
     FPresentacion.PuedeExpandir and (FCfg.Grid <> nil) then
  begin
    oRegistro := FCfg.Grid.Controller.FocusedRecord;
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if (oRegistro <> nil) and (oColumnaLinea <> nil) then
    begin
      vLinea := oRegistro.Values[oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    iConjunto := 0;
    if iLinea > 0 then
      FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
    if (oRegistro <> nil) and (iConjunto > 0) then
    begin
      aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
        iConjunto, FCache.ArticuloLinea(iLinea));
      iRegistro := oRegistro.RecordIndex;
      FCfg.Grid.DataController.BeginUpdate;
      try
        for iPosicion := 0 to High(aPosiciones) do
        begin
          if (iPosicion < FCfg.MaxColumnasTallas) and
             (iPosicion < Length(FCfg.ColumnasTallas)) and
             (FCfg.ColumnasTallas[iPosicion] <> nil) then
          begin
            oColumnaTalla := FCfg.ColumnasTallas[iPosicion];
            iClave := ClaveCeldaPivoteCompra(iLinea,
              aPosiciones[iPosicion].IdAv);
            dPedida := 0;
            dRecibida := 0;
            FCache.Cantidades.TryGetValue(iClave, dPedida);
            FCache.CantidadesRecibidas.TryGetValue(iClave, dRecibida);
            dPendiente := PendientePivoteCompra(dPedida, dRecibida);
            if dPendiente > 0 then
            begin
              FCfg.Grid.DataController.Values[iRegistro,
                oColumnaTalla.Index] := dPendiente;
              FEstado.ARecibir.AddOrSetValue(iClave, dPendiente);
              Inc(Result);
            end;
          end;
        end;
      finally
        FCfg.Grid.DataController.EndUpdate;
      end;
    end;
  end;
end;

function TEdicionPivoteCompra.RecibirTodo: Integer;
var
  oColumnaLinea: TcxGridColumn;
  oColumnaTalla: TcxGridDBColumn;
  vLinea       : Variant;
  aPosiciones  : TArrPosConjunto;
  iRegistro    : Integer;
  iLinea       : Integer;
  iConjunto    : Integer;
  iPosicion    : Integer;
  iClave       : Int64;
  dPedida      : Double;
  dRecibida    : Double;
  dPendiente   : Double;
begin
  Result := 0;
  if FPresentacion.Activo and FPresentacion.Expandido and
     FPresentacion.PuedeExpandir and (FCfg.Grid <> nil) then
  begin
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    if oColumnaLinea <> nil then
    begin
      FCfg.Grid.DataController.BeginUpdate;
      try
        for iRegistro := 0 to
          FCfg.Grid.DataController.RecordCount - 1 do
        begin
          vLinea := FCfg.Grid.DataController.Values[iRegistro,
            oColumnaLinea.Index];
          iLinea := 0;
          if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
            iLinea := StrToIntDef(VarToStr(vLinea), 0);
          iConjunto := 0;
          if iLinea > 0 then
            FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
          if iConjunto > 0 then
          begin
            aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
              iConjunto, FCache.ArticuloLinea(iLinea));
            for iPosicion := 0 to High(aPosiciones) do
            begin
              if (iPosicion < FCfg.MaxColumnasTallas) and
                 (iPosicion < Length(FCfg.ColumnasTallas)) and
                 (FCfg.ColumnasTallas[iPosicion] <> nil) then
              begin
                oColumnaTalla := FCfg.ColumnasTallas[iPosicion];
                iClave := ClaveCeldaPivoteCompra(iLinea,
                  aPosiciones[iPosicion].IdAv);
                dPedida := 0;
                dRecibida := 0;
                FCache.Cantidades.TryGetValue(iClave, dPedida);
                FCache.CantidadesRecibidas.TryGetValue(
                  iClave, dRecibida);
                dPendiente := PendientePivoteCompra(
                  dPedida, dRecibida);
                if dPendiente > 0 then
                begin
                  FCfg.Grid.DataController.Values[iRegistro,
                    oColumnaTalla.Index] := dPendiente;
                  FEstado.ARecibir.AddOrSetValue(iClave, dPendiente);
                  Inc(Result);
                end;
              end;
            end;
          end;
        end;
      finally
        FCfg.Grid.DataController.EndUpdate;
      end;
    end;
  end;
end;

function TEdicionPivoteCompra.ObtenerValorEditor(
  AEditor: TcxCustomEdit; ARegistro: TcxCustomGridRecord;
  AColumna: TcxGridColumn; AValorPreferente: Variant): Double;
var
  vValor: Variant;
begin
  vValor := AValorPreferente;
  if VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor) then
    vValor := AEditor.EditingValue;
  if VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor) then
    vValor := AEditor.EditValue;
  if VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor) then
    vValor := FCfg.Grid.DataController.Values[
      ARegistro.RecordIndex, AColumna.Index];
  if VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor) then
    Result := 0
  else if VarIsNumeric(vValor) then
    Result := vValor
  else
    Result := StrToFloatDef(VarToStr(vValor), 0);
end;

procedure TEdicionPivoteCompra.GrabarCantidadLinea(
  const ALineaReal, ALineaFoco: string; ACantidad: Double);
var
  dPrecio  : Double;
  bFiltro  : Boolean;
  bCambiado: Boolean;
begin
  bFiltro := FCfg.SourceLineas.Filtered;
  FCfg.SourceLineas.DisableControls;
  try
    if bFiltro then
      FCfg.SourceLineas.Filtered := False;
    if FCfg.SourceLineas.Locate(FCfg.FieldLinea, ALineaReal, []) then
    begin
      FCantidadAntesDeGrabar := FCfg.SourceLineas.FieldByName(
        FCfg.FieldCantidad).AsFloat;
      bCambiado := Abs(FCantidadAntesDeGrabar - ACantidad) > 0.000001;
      if bCambiado then
      begin
        if not (FCfg.SourceLineas.State in dsEditModes) then
          FCfg.SourceLineas.Edit;
        FCfg.SourceLineas.FieldByName(
          FCfg.FieldCantidad).AsFloat := ACantidad;
        if FCfg.FieldTotalUds <> '' then
          FCfg.SourceLineas.FieldByName(
            FCfg.FieldTotalUds).AsFloat := ACantidad;
        if (FCfg.FieldPrecioBase <> '') and
           (FCfg.FieldTotalLinea <> '') then
        begin
          dPrecio := FCfg.SourceLineas.FieldByName(
            FCfg.FieldPrecioBase).AsFloat;
          FCfg.SourceLineas.FieldByName(
            FCfg.FieldTotalLinea).AsFloat := ACantidad * dPrecio;
        end;
        try
          FCfg.SourceLineas.Post;
        except
          // FZ-ISSUE-255: total no confirmado; la línea vuelve a como
          // estaba en vez de quedar en edición con la cantidad rechazada.
          on EAbort do
          begin
            FCfg.SourceLineas.Cancel;
            raise;
          end;
        end;
      end
      else if FCfg.SourceLineas.State in dsEditModes then
        FCfg.SourceLineas.Post;
    end;
  finally
    if bFiltro then
      FCfg.SourceLineas.Filtered := True;
    if ALineaFoco <> '' then
      FCfg.SourceLineas.Locate(FCfg.FieldLinea, ALineaFoco, []);
    FCfg.SourceLineas.EnableControls;
  end;
end;

procedure TEdicionPivoteCompra.PersistirCantidadEditValueChanged(
  ASender: TObject; var AValorEditado: Variant);
var
  oEditor       : TcxCustomEdit;
  oRegistro     : TcxCustomGridRecord;
  oColumna      : TcxGridColumn;
  oColumnaLinea : TcxGridColumn;
  vLinea        : Variant;
  aPosiciones   : TArrPosConjunto;
  iLineaRepr    : Integer;
  iConjunto     : Integer;
  iTalla        : Integer;
  iClave        : Int64;
  sLineaReal    : string;
  sLineaFoco    : string;
  dCantidad     : Double;
  dAnterior     : Double;
  bCeldaValida  : Boolean;
begin
  if FPresentacion.Expandido then
    CapturarARecibirEditValueChanged(ASender)
  else
  begin
    bCeldaValida := (not FPresentacion.ActualizandoGrid) and
      (not FActualizando) and (not FGuardando) and
      FPresentacion.Activo and (ASender is TcxCustomEdit) and
      (FCfg.Grid <> nil) and (FCfg.Gestor <> nil) and
      (FCfg.SourceLineas <> nil) and FCfg.SourceLineas.Active;
    if bCeldaValida then
    begin
      FGuardando := True;
      try
        oEditor := TcxCustomEdit(ASender);
        oRegistro := FCfg.Grid.Controller.FocusedRecord;
        oColumna := FCfg.Grid.Controller.FocusedColumn;
        bCeldaValida := (oRegistro <> nil) and (oColumna <> nil) and
          (oColumna.Tag >= 1) and
          (oColumna.Tag <= FCfg.MaxColumnasTallas) and
          (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
          (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
        oColumnaLinea := nil;
        iTalla := 0;
        iClave := 0;
        if bCeldaValida then
          oColumnaLinea := FCfg.Grid.GetColumnByFieldName(
            FCfg.FieldLinea);
        iLineaRepr := 0;
        sLineaFoco := '';
        if oColumnaLinea <> nil then
        begin
          vLinea := oRegistro.Values[oColumnaLinea.Index];
          if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
          begin
            sLineaFoco := VarToStr(vLinea);
            iLineaRepr := StrToIntDef(sLineaFoco, 0);
          end;
        end;
        iConjunto := 0;
        if iLineaRepr > 0 then
          FCache.IdConjunto.TryGetValue(iLineaRepr, iConjunto);
        bCeldaValida := bCeldaValida and (iConjunto > 0);
        if bCeldaValida then
        begin
          aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
            iConjunto, FCache.ArticuloLinea(iLineaRepr));
          bCeldaValida := oColumna.Tag <= Length(aPosiciones);
        end;
        if bCeldaValida then
        begin
          iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
          iClave := ClaveCeldaPivoteCompra(iLineaRepr, iTalla);
          sLineaReal := '';
          bCeldaValida := FCache.CeldaLineaPedido.TryGetValue(
            iClave, sLineaReal);
          if not bCeldaValida then
            RegistrarSesion(Format(
              'PivoteCompra.PersistirCantidad: sin linea real ' +
              'repr=%d tallaAv=%d', [iLineaRepr, iTalla]));
        end;
        if bCeldaValida then
        begin
          dCantidad := ObtenerValorEditor(oEditor, oRegistro,
            oColumna, AValorEditado);
          FCache.Cantidades.AddOrSetValue(iClave, dCantidad);
          RegistrarSesion(Format(
            'PivoteCompra.PersistirCantidad: repr=%s linea=%s ' +
            'tallaAv=%d cantidad=%g',
            [sLineaFoco, sLineaReal, iTalla, dCantidad]));
          // FZ-ISSUE-255: total de la línea rechazado. La celda valida con
          // la cantidad anterior y el editor la recupera.
          try
            GrabarCantidadLinea(sLineaReal, sLineaFoco, dCantidad);
          except
            on EAbort do
            begin
              // La captura de cada pulsación ya dejó la cantidad rechazada
              // en la caché y en pendientes: se deshace en los dos.
              dAnterior := FCantidadAntesDeGrabar;
              FCache.Cantidades.AddOrSetValue(iClave, dAnterior);
              FEstado.CantidadesPendientes.Remove(iClave);
              AValorEditado := dAnterior;
            end;
          end;
        end;
      finally
        FGuardando := False;
      end;
      FPresentacion.PublicarCantidades;
    end;
  end;
end;

procedure TEdicionPivoteCompra.CapturarCantidadEditValueChanged(
  ASender: TObject);
var
  oEditor       : TcxCustomEdit;
  oRegistro     : TcxCustomGridRecord;
  oColumna      : TcxGridColumn;
  oColumnaLinea : TcxGridColumn;
  vLinea        : Variant;
  aPosiciones   : TArrPosConjunto;
  iLineaRepr    : Integer;
  iConjunto     : Integer;
  iTalla        : Integer;
  iClave        : Int64;
  dCantidad     : Double;
  bCeldaValida  : Boolean;
begin
  if FPresentacion.Expandido then
    CapturarARecibirEditValueChanged(ASender)
  else
  begin
    bCeldaValida := (not FPresentacion.ActualizandoGrid) and
      (not FActualizando) and (not FGuardando) and
      FPresentacion.Activo and (ASender is TcxCustomEdit) and
      (FCfg.Grid <> nil) and (FCfg.Gestor <> nil);
    if bCeldaValida then
    begin
      oEditor := TcxCustomEdit(ASender);
      oRegistro := FCfg.Grid.Controller.FocusedRecord;
      oColumna := FCfg.Grid.Controller.FocusedColumn;
      bCeldaValida := (oRegistro <> nil) and (oColumna <> nil) and
        (oColumna.Tag >= 1) and
        (oColumna.Tag <= FCfg.MaxColumnasTallas) and
        (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
        (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
      oColumnaLinea := nil;
      if bCeldaValida then
        oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
      iLineaRepr := 0;
      if oColumnaLinea <> nil then
      begin
        vLinea := oRegistro.Values[oColumnaLinea.Index];
        if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
          iLineaRepr := StrToIntDef(VarToStr(vLinea), 0);
      end;
      iConjunto := 0;
      if iLineaRepr > 0 then
        FCache.IdConjunto.TryGetValue(iLineaRepr, iConjunto);
      bCeldaValida := bCeldaValida and (iConjunto > 0);
      if bCeldaValida then
      begin
        aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
          iConjunto, FCache.ArticuloLinea(iLineaRepr));
        bCeldaValida := oColumna.Tag <= Length(aPosiciones);
      end;
      if bCeldaValida then
      begin
        iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
        iClave := ClaveCeldaPivoteCompra(iLineaRepr, iTalla);
        dCantidad := ObtenerValorEditor(oEditor, oRegistro,
          oColumna, Null);
        FEstado.CantidadesPendientes.AddOrSetValue(iClave, dCantidad);
        FCache.Cantidades.AddOrSetValue(iClave, dCantidad);
        RegistrarSesion(Format(
          'PivoteCompra.CapturarCantidad: repr=%d tallaAv=%d ' +
          'cantidad=%g', [iLineaRepr, iTalla, dCantidad]));
        FActualizando := True;
        try
          FCfg.Grid.DataController.BeginUpdate;
          try
            if dCantidad <> 0 then
              FCfg.Grid.DataController.Values[oRegistro.RecordIndex,
                oColumna.Index] := dCantidad
            else
              FCfg.Grid.DataController.Values[oRegistro.RecordIndex,
                oColumna.Index] := Null;
          finally
            FCfg.Grid.DataController.EndUpdate;
          end;
        finally
          FActualizando := False;
        end;
        FPresentacion.PublicarCantidades;
      end;
    end;
  end;
end;

procedure TEdicionPivoteCompra.CapturarEditorActivo;
var
  oEditor: TcxCustomEdit;
begin
  oEditor := nil;
  if (FCfg.Grid <> nil) and
     (FCfg.Grid.Controller.EditingController <> nil) and
     FCfg.Grid.Controller.EditingController.IsEditing then
    oEditor := FCfg.Grid.Controller.EditingController.Edit;
  if oEditor <> nil then
  begin
    if FPresentacion.Expandido then
      CapturarARecibirEditValueChanged(oEditor)
    else
      CapturarCantidadEditValueChanged(oEditor);
    try
      FCfg.Grid.Controller.EditingController.HideEdit(True);
    except
      on E: EInvalidOperation do
      begin
        if Assigned(FCfg.RegistroLog) then
          FCfg.RegistroLog.RegistrarAviso(
            'GridPivoteCompra.CapturarEditorActivo: HideEdit ' +
            'ignorado: ' + E.Message);
      end;
    end;
  end;
end;

procedure TEdicionPivoteCompra.CapturarValoresVisibles;
var
  oColumnaLinea : TcxGridColumn;
  oColumnaTalla : TcxGridDBColumn;
  vLinea        : Variant;
  vValor        : Variant;
  aPosiciones   : TArrPosConjunto;
  iRegistro     : Integer;
  iPosicion     : Integer;
  iLineaRepr    : Integer;
  iConjunto     : Integer;
  iClave        : Int64;
  dCantidad     : Double;
begin
  if (FCfg.Grid <> nil) and (FCfg.Gestor <> nil) then
  begin
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    if oColumnaLinea <> nil then
    begin
      for iRegistro := 0 to
        FCfg.Grid.DataController.RecordCount - 1 do
      begin
        vLinea := FCfg.Grid.DataController.Values[iRegistro,
          oColumnaLinea.Index];
        iLineaRepr := 0;
        if not (VarIsNull(vLinea) or VarIsEmpty(vLinea) or
                VarIsClear(vLinea)) then
          iLineaRepr := StrToIntDef(VarToStr(vLinea), 0);
        iConjunto := 0;
        if iLineaRepr > 0 then
          FCache.IdConjunto.TryGetValue(iLineaRepr, iConjunto);
        if (iLineaRepr > 0) and
           FCache.SinTalla.ContainsKey(iLineaRepr) and
           (Length(FCfg.ColumnasTallas) > 0) and
           (FCfg.ColumnasTallas[0] <> nil) then
        begin
          iClave := ClaveCeldaPivoteCompra(iLineaRepr,
            ID_AV_SIN_TALLA);
          vValor := FCfg.Grid.DataController.Values[iRegistro,
            FCfg.ColumnasTallas[0].Index];
          if FCache.CeldaLineaPedido.ContainsKey(iClave) and
             not (VarIsNull(vValor) or VarIsEmpty(vValor) or
                  VarIsClear(vValor)) then
          begin
            if VarIsNumeric(vValor) then
              dCantidad := vValor
            else
              dCantidad := StrToFloatDef(VarToStr(vValor), 0);
            FEstado.CantidadesPendientes.AddOrSetValue(
              iClave, dCantidad);
          end;
        end
        else if (iLineaRepr > 0) and (iConjunto > 0) then
        begin
          aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
            iConjunto, FCache.ArticuloLinea(iLineaRepr));
          for iPosicion := 0 to High(aPosiciones) do
          begin
            if (iPosicion < FCfg.MaxColumnasTallas) and
               (iPosicion < Length(FCfg.ColumnasTallas)) and
               (FCfg.ColumnasTallas[iPosicion] <> nil) then
            begin
              oColumnaTalla := FCfg.ColumnasTallas[iPosicion];
              iClave := ClaveCeldaPivoteCompra(iLineaRepr,
                aPosiciones[iPosicion].IdAv);
              vValor := FCfg.Grid.DataController.Values[iRegistro,
                oColumnaTalla.Index];
              if not (VarIsNull(vValor) or VarIsEmpty(vValor) or
                      VarIsClear(vValor)) then
              begin
                if VarIsNumeric(vValor) then
                  dCantidad := vValor
                else
                  dCantidad := StrToFloatDef(VarToStr(vValor), 0);
                FEstado.CantidadesPendientes.AddOrSetValue(
                  iClave, dCantidad);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TEdicionPivoteCompra.PersistirCantidadesPendientes: Integer;
var
  oPar        : TPair<Int64, Double>;
  sLineaReal  : string;
  sLineaFoco  : string;
  dCantidad   : Double;
  dPrecio     : Double;
  bFiltro     : Boolean;
  bCambiado   : Boolean;
  bPuedeGrabar: Boolean;
begin
  Result := 0;
  if Assigned(FCfg.RegistroLog) then
    FCfg.RegistroLog.RegistrarInformacion('PivoteCompra.Persistir: INICIO');
  bPuedeGrabar := (not FGuardando) and FPresentacion.Activo and
    (not FPresentacion.Expandido);
  if bPuedeGrabar then
  begin
    CapturarEditorActivo;
    CapturarValoresVisibles;
    bPuedeGrabar := (FEstado.CantidadesPendientes.Count > 0) and
      (FCfg.SourceLineas <> nil) and FCfg.SourceLineas.Active;
  end;
  if bPuedeGrabar then
  begin
    sLineaFoco := '';
    if (not FCfg.SourceLineas.IsEmpty) and
       (FCfg.SourceLineas.FindField(FCfg.FieldLinea) <> nil) then
      sLineaFoco := FCfg.SourceLineas.FieldByName(
        FCfg.FieldLinea).AsString;
    bFiltro := FCfg.SourceLineas.Filtered;
    FGuardando := True;
    FCfg.SourceLineas.DisableControls;
    try
      if bFiltro then
        FCfg.SourceLineas.Filtered := False;
      for oPar in FEstado.CantidadesPendientes do
      begin
        dCantidad := oPar.Value;
        sLineaReal := '';
        if not FCache.CeldaLineaPedido.TryGetValue(
          oPar.Key, sLineaReal) then
        begin
          if FCorrespondencia.CrearLineaRealDesdeCelda(
            oPar.Key, dCantidad, sLineaReal) then
            Inc(Result)
          else if Assigned(FCfg.RegistroLog) then
            FCfg.RegistroLog.RegistrarInformacion(Format(
              'PivoteCompra.PersistirPendiente: sin linea real key=%d',
              [oPar.Key]));
        end
        else
        begin
          FCache.Cantidades.AddOrSetValue(oPar.Key, dCantidad);
          if FCfg.SourceLineas.Locate(
            FCfg.FieldLinea, sLineaReal, []) then
          begin
            bCambiado := Abs(FCfg.SourceLineas.FieldByName(
              FCfg.FieldCantidad).AsFloat - dCantidad) > 0.000001;
            if bCambiado then
            begin
              if not (FCfg.SourceLineas.State in dsEditModes) then
                FCfg.SourceLineas.Edit;
              FCfg.SourceLineas.FieldByName(
                FCfg.FieldCantidad).AsFloat := dCantidad;
              if FCfg.FieldTotalUds <> '' then
                FCfg.SourceLineas.FieldByName(
                  FCfg.FieldTotalUds).AsFloat := dCantidad;
              if (FCfg.FieldPrecioBase <> '') and
                 (FCfg.FieldTotalLinea <> '') then
              begin
                dPrecio := FCfg.SourceLineas.FieldByName(
                  FCfg.FieldPrecioBase).AsFloat;
                FCfg.SourceLineas.FieldByName(
                  FCfg.FieldTotalLinea).AsFloat :=
                    dCantidad * dPrecio;
              end;
              FCfg.SourceLineas.Post;
              Inc(Result);
            end
            else if FCfg.SourceLineas.State in dsEditModes then
            begin
              FCfg.SourceLineas.Post;
              Inc(Result);
            end;
          end;
        end;
      end;
      FEstado.CantidadesPendientes.Clear;
    finally
      if bFiltro then
        FCfg.SourceLineas.Filtered := True;
      if sLineaFoco <> '' then
        FCfg.SourceLineas.Locate(FCfg.FieldLinea, sLineaFoco, []);
      FCfg.SourceLineas.EnableControls;
      FGuardando := False;
      if Assigned(FCfg.RegistroLog) then
        FCfg.RegistroLog.RegistrarInformacion(Format(
          'PivoteCompra.PersistirPendiente: FIN guardadas=%d',
          [Result]));
    end;
  end;
end;

procedure TEdicionPivoteCompra.CapturarARecibirEditValueChanged(
  ASender: TObject);
var
  oEditor       : TcxCustomEdit;
  oRegistro     : TcxCustomGridRecord;
  oColumna      : TcxGridColumn;
  oColumnaLinea : TcxGridColumn;
  vLinea        : Variant;
  aPosiciones   : TArrPosConjunto;
  iLinea        : Integer;
  iConjunto     : Integer;
  iTalla        : Integer;
  iClave        : Int64;
  dValor        : Double;
  dPedida       : Double;
  dRecibida     : Double;
  dLimitada     : Double;
  bCeldaValida  : Boolean;
begin
  bCeldaValida := (not FPresentacion.ActualizandoGrid) and
    (not FActualizando) and FPresentacion.Activo and
    FPresentacion.Expandido and FPresentacion.PuedeExpandir and
    (ASender is TcxCustomEdit) and (FCfg.Grid <> nil);
  if bCeldaValida then
  begin
    oEditor := TcxCustomEdit(ASender);
    oEditor.PostEditValue;
    oRegistro := FCfg.Grid.Controller.FocusedRecord;
    oColumna := FCfg.Grid.Controller.FocusedColumn;
    bCeldaValida := (oRegistro <> nil) and (oColumna <> nil) and
      (oColumna.Tag >= 1) and
      (oColumna.Tag <= FCfg.MaxColumnasTallas) and
      (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
      (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
    oColumnaLinea := nil;
    if bCeldaValida then
      oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if oColumnaLinea <> nil then
    begin
      vLinea := oRegistro.Values[oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    iConjunto := 0;
    if iLinea > 0 then
      FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
    bCeldaValida := bCeldaValida and (iConjunto > 0);
    if bCeldaValida then
    begin
      aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
        iConjunto, FCache.ArticuloLinea(iLinea));
      bCeldaValida := oColumna.Tag <= Length(aPosiciones);
    end;
    if bCeldaValida then
    begin
      iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
      iClave := ClaveCeldaPivoteCompra(iLinea, iTalla);
      dValor := ObtenerValorEditor(oEditor, oRegistro, oColumna, Null);
      dPedida := 0;
      dRecibida := 0;
      FCache.Cantidades.TryGetValue(iClave, dPedida);
      FCache.CantidadesRecibidas.TryGetValue(iClave, dRecibida);
      dLimitada := LimitarARecibirPivoteCompra(
        dPedida, dRecibida, dValor);
      if Abs(dLimitada - dValor) > 0.000001 then
      begin
        MessageBeep(MB_ICONWARNING);
        FActualizando := True;
        try
          if dLimitada > 0 then
            oEditor.EditValue := dLimitada
          else
            oEditor.EditValue := Null;
          FCfg.Grid.DataController.BeginUpdate;
          try
            if dLimitada > 0 then
              FCfg.Grid.DataController.Values[oRegistro.RecordIndex,
                oColumna.Index] := dLimitada
            else
              FCfg.Grid.DataController.Values[oRegistro.RecordIndex,
                oColumna.Index] := Null;
          finally
            FCfg.Grid.DataController.EndUpdate;
          end;
        finally
          FActualizando := False;
        end;
      end;
      if dLimitada <= 0 then
        FEstado.ARecibir.Remove(iClave)
      else
        FEstado.ARecibir.AddOrSetValue(iClave, dLimitada);
    end;
  end;
end;

function TEdicionPivoteCompra.PrimerAlmacenARecibir: string;
var
  oPar     : TPair<Int64, Double>;
  sAlmacen : string;
begin
  Result := '';
  for oPar in FEstado.ARecibir do
  begin
    sAlmacen := '';
    if (Result = '') and (oPar.Value > 0) and
       FCache.CeldaAlmacen.TryGetValue(oPar.Key, sAlmacen) and
       (Trim(sAlmacen) <> '') then
      Result := sAlmacen;
  end;
end;

function TEdicionPivoteCompra.TotalARecibir: Double;
var
  oPar: TPair<Int64, Double>;
begin
  Result := 0;
  for oPar in FEstado.ARecibir do
  begin
    if oPar.Value > 0 then
      Result := Result + oPar.Value;
  end;
end;

function TEdicionPivoteCompra.ColorCodigoLineaActiva: string;
var
  iLinea: Integer;
  sLinea: string;
begin
  Result := '';
  if FPresentacion.ObtenerLineaActiva(iLinea, sLinea) then
    FCache.ColorCodigo.TryGetValue(iLinea, Result);
end;

function TEdicionPivoteCompra.CambiarColorLineaActiva(
  const ACodigoAtbColor: string; out AMensaje: string): Boolean;
var
  oDataSet     : TDataSet;
  oCampo       : TField;
  iLinea       : Integer;
  iIdAtributo  : Integer;
  sLinea       : string;
  sLineaBuscar : string;
  sLineaDataSet: string;
  sArticulo    : string;
  sSkuColor    : string;
  sVariacion   : string;
  sValor       : string;
  sNombreColor : string;
  dTotal       : Double;
  bLineaActual : Boolean;
  bPuedeCambiar: Boolean;
begin
  Result := False;
  AMensaje := '';
  oDataSet := nil;
  dTotal := 0;
  bPuedeCambiar := FPresentacion.Activo;
  if not bPuedeCambiar then
    AMensaje := SErrorActivarTallasHorizontalesParaColor;
  if bPuedeCambiar then
  begin
    bPuedeCambiar := FPresentacion.ObtenerLineaActiva(iLinea, sLinea);
    if not bPuedeCambiar then
      AMensaje := SErrorLineaActivaColorNoDisponible;
  end;
  if bPuedeCambiar and
     FCache.TotalPedido.TryGetValue(iLinea, dTotal) and
     (Abs(dTotal) > 0.000001) then
  begin
    bPuedeCambiar := False;
    AMensaje := SErrorColorCompraConCantidades;
  end;
  if bPuedeCambiar then
  begin
    bPuedeCambiar := (FCfg.SourceLineas <> nil) and
      FCfg.SourceLineas.Active;
    if not bPuedeCambiar then
      AMensaje := SErrorConsultaLineasCompraNoAbierta;
  end;
  if bPuedeCambiar then
  begin
    oDataSet := FCfg.SourceLineas;
    sLineaBuscar := sLinea;
    if StrToIntDef(sLineaBuscar, 0) > 0 then
      sLineaBuscar := Format('%.4d', [StrToIntDef(sLineaBuscar, 0)]);
    bLineaActual := False;
    if (not oDataSet.IsEmpty) and
       (oDataSet.FindField(FCfg.FieldLinea) <> nil) then
    begin
      sLineaDataSet := Trim(oDataSet.FieldByName(
        FCfg.FieldLinea).AsString);
      if StrToIntDef(sLineaDataSet, 0) > 0 then
        sLineaDataSet := Format('%.4d',
          [StrToIntDef(sLineaDataSet, 0)]);
      bLineaActual := SameText(sLineaDataSet, sLineaBuscar);
    end;
    bPuedeCambiar := bLineaActual or oDataSet.Locate(
      FCfg.FieldLinea, sLineaBuscar, []);
    if not bPuedeCambiar then
      AMensaje := SErrorLineaActivaColorNoEncontrada;
  end;
  if bPuedeCambiar then
  begin
    sArticulo := Trim(oDataSet.FieldByName(FCfg.FieldArt).AsString);
    bPuedeCambiar := sArticulo <> '';
    if not bPuedeCambiar then
      AMensaje := SErrorLineaActivaCompraSinArticulo;
  end;
  if bPuedeCambiar then
  begin
    sVariacion := '';
    FCache.VariacionSku.TryGetValue(iLinea, sVariacion);
    if sVariacion = '' then
      sVariacion := FRepositorio.Skus.BuscarTipoVariacion(sArticulo);
    if sVariacion = '' then
      sVariacion := 'TC';
    bPuedeCambiar := FValidador.ResolverColorBasico(
      ACodigoAtbColor, sVariacion, iIdAtributo, sValor,
      sNombreColor, AMensaje);
  end;
  if bPuedeCambiar then
  begin
    sSkuColor := sArticulo + '/' + sValor;
    FRepositorio.Skus.AsegurarSkuColor(
      sSkuColor, sArticulo, sVariacion,
      FCfg.ContextoSesion.Identidad.Usuario, iIdAtributo);
    if not (oDataSet.State in dsEditModes) then
      oDataSet.Edit;
    oDataSet.FieldByName(FCfg.FieldSku).AsString := sSkuColor;
    if FCfg.FieldColorTexto <> '' then
    begin
      oCampo := oDataSet.FindField(FCfg.FieldColorTexto);
      if oCampo <> nil then
        oCampo.AsString := sValor;
    end;
    oDataSet.Post;
    FCache.ColorCodigo.AddOrSetValue(iLinea, ACodigoAtbColor);
    FCache.ColorTexto.AddOrSetValue(iLinea, sValor);
    FCache.ColorAtributo.AddOrSetValue(iLinea, iIdAtributo);
    FCache.SkuBase.AddOrSetValue(iLinea, sSkuColor);
    FCache.SkuPrefijo.AddOrSetValue(iLinea, sSkuColor);
    FCache.VariacionSku.AddOrSetValue(iLinea, sVariacion);
    Result := True;
  end;
end;

end.

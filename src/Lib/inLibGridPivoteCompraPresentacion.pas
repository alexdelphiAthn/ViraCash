{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompraPresentacion                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presentación, distribución y ciclo visual del pivote de compra.          }
{******************************************************************************}
unit inLibGridPivoteCompraPresentacion;

interface

uses
  System.SysUtils, System.Variants, System.Types, System.UITypes,
  Data.DB,
  Vcl.Graphics,
  cxGraphics, cxEdit, cxTextEdit, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView,
  inLibGridPivoteCompraTipos,
  inLibGridTallasInline,
  inLibPestanasEjeVcl,
  inLibPivoteCompraCorrespondencia,
  inLibPivoteCompraEstadoEdicion;

type
  TPresentacionPivoteCompra = class
  private
    FCfg                    : TGridPivoteCompraConfig;
    FCorrespondencia        : TCorrespondenciaPivoteCompra;
    FCache                  : TCachePivoteCompra;
    FEstadoEdicion          : TEstadoEdicionPivoteCompra;
    FActivo                 : Boolean;
    FExpandido              : Boolean;
    FActualizandoGrid       : Boolean;
    FIndiceOriginalAlmacen  : Integer;
    FIndiceOriginalColor    : Integer;
    FIndiceOriginalProveedor: Integer;
    FAlturaFilaOriginal     : Integer;
    // Pestañas de copa sobre la rejilla (tercera dimensión, fase 4).
    FPestanas               : TControlPestanasEje;
    procedure FiltrarRegistro(DataSet: TDataSet; var Accept: Boolean);
    procedure CrearPestanas;
    procedure RefrescarPestanas;
    procedure CambiarPestana(const ACodigo: string);
    function PestanaDeLinea(ALinea: Integer): string;
    procedure AplicarColumnaCantidadSinTalla;
    procedure AplicarVisibilidad(AModoPivote: Boolean);
    procedure IntercambiarPosicionColorAlmacen(AModoPivote: Boolean);
    procedure PintarCeldaTallaTresSegmentos(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; AColorFondo: TColor;
      APedida, ARecibida, ARecibir: Double);
    procedure DibujarBordeFoco(ACanvas: TcxCanvas; const ARect: TRect);
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig;
      ACorrespondencia: TCorrespondenciaPivoteCompra;
      AEstadoEdicion: TEstadoEdicionPivoteCompra);
    destructor Destroy; override;
    procedure Activar;
    procedure Desactivar;
    procedure Recargar;
    procedure Expandir;
    procedure Contraer;
    procedure PublicarCantidades;
    function PuedeExpandir: Boolean;
    function ObtenerLineaActiva(out ALinea: Integer;
      out ALineaTexto: string): Boolean;
    procedure CustomDrawCellTalla(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure EditingCeldaTalla(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure InitEditCeldaTalla(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure CustomDrawColorCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    property Activo: Boolean read FActivo;
    property Expandido: Boolean read FExpandido;
    property ActualizandoGrid: Boolean read FActualizandoGrid;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Controls,
  cxGrid,
  inLibAtributosPaleta, inLibMsgArticulos,
  inLibPestanasEje,
  inLibPivoteCompraCalculo;

procedure MoverColumnaJustoAntes(ACol, AReferencia: TcxGridColumn);
begin
  if (ACol <> nil) and (AReferencia <> nil) and
     (ACol <> AReferencia) then
  begin
    if ACol.Index < AReferencia.Index then
      ACol.Index := AReferencia.Index - 1
    else
      ACol.Index := AReferencia.Index;
  end;
end;

procedure MoverColumnaJustoDespues(ACol, AReferencia: TcxGridColumn);
begin
  if (ACol <> nil) and (AReferencia <> nil) and
     (ACol <> AReferencia) then
  begin
    if ACol.Index < AReferencia.Index then
      ACol.Index := AReferencia.Index
    else
      ACol.Index := AReferencia.Index + 1;
  end;
end;

constructor TPresentacionPivoteCompra.Create(
  const ACfg: TGridPivoteCompraConfig;
  ACorrespondencia: TCorrespondenciaPivoteCompra;
  AEstadoEdicion: TEstadoEdicionPivoteCompra);
begin
  inherited Create;
  FCfg := ACfg;
  FCorrespondencia := ACorrespondencia;
  FCache := ACorrespondencia.Cache;
  FEstadoEdicion := AEstadoEdicion;
  FActivo := False;
  FExpandido := False;
  FActualizandoGrid := False;
  FIndiceOriginalAlmacen := -1;
  FIndiceOriginalColor := -1;
  FIndiceOriginalProveedor := -1;
  FAlturaFilaOriginal := 0;
end;

destructor TPresentacionPivoteCompra.Destroy;
begin
  FreeAndNil(FPestanas);
  inherited Destroy;
end;

// Las pestañas van encima de la rejilla, en su mismo contenedor.
procedure TPresentacionPivoteCompra.CrearPestanas;
var
  oRejilla: TControl;
begin
  if (FPestanas = nil) and (FCfg.Grid <> nil) and
     (FCfg.Grid.Control is TcxGrid) then
  begin
    oRejilla := TcxGrid(FCfg.Grid.Control);
    if oRejilla.Parent <> nil then
    begin
      FPestanas := TControlPestanasEje.Create(oRejilla.Owner,
        oRejilla.Parent, CambiarPestana);
      FPestanas.Control.Top := oRejilla.Top - 1;
    end;
  end;
end;

// Una pestaña por copa de las filas, con las unidades pedidas.
procedure TPresentacionPivoteCompra.RefrescarPestanas;
var
  aValores: TArray<string>;
  aUnidades: TArray<Double>;
  iLinea: Integer;
  sPestana: string;
  dTotal: Double;
begin
  CrearPestanas;
  if FPestanas <> nil then
  begin
    aValores := nil;
    aUnidades := nil;
    for iLinea in FCache.LineasRepresentantes do
    begin
      sPestana := '';
      FCache.PestanaTexto.TryGetValue(iLinea, sPestana);
      dTotal := 0;
      FCache.TotalPedido.TryGetValue(iLinea, dTotal);
      aValores := aValores + [sPestana];
      aUnidades := aUnidades + [dTotal];
    end;
    FPestanas.Mostrar(ModeloPestanasDeLineas('', nil, aValores, aUnidades));
  end;
end;

function TPresentacionPivoteCompra.PestanaDeLinea(ALinea: Integer): string;
begin
  Result := '';
  FCache.PestanaTexto.TryGetValue(ALinea, Result);
end;

procedure TPresentacionPivoteCompra.CambiarPestana(const ACodigo: string);
begin
  if FActivo and (FCfg.SourceLineas <> nil) then
  begin
    FCfg.SourceLineas.Filtered := False;
    FCfg.SourceLineas.Filtered := True;
    PublicarCantidades;
  end;
end;

procedure TPresentacionPivoteCompra.Activar;
begin
  if FCfg.SourceLineas <> nil then
  begin
    RefrescarPestanas;
    FCfg.SourceLineas.OnFilterRecord := FiltrarRegistro;
    FCfg.SourceLineas.Filtered := True;
    AplicarVisibilidad(True);
    if FCfg.Gestor <> nil then
    begin
      FCfg.Gestor.RecalcularMaxColumnas;
      FCfg.Gestor.ActualizarCaptionsLineaActiva;
    end;
    AplicarColumnaCantidadSinTalla;
    PublicarCantidades;
    FActivo := True;
  end;
end;

procedure TPresentacionPivoteCompra.Desactivar;
var
  iColumna: Integer;
begin
  if FExpandido then
    Contraer;
  if FCfg.SourceLineas <> nil then
  begin
    FCfg.SourceLineas.Filtered := False;
    FCfg.SourceLineas.OnFilterRecord := nil;
  end;
  if FPestanas <> nil then
    FPestanas.Ocultar;
  AplicarVisibilidad(False);
  for iColumna := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[iColumna] <> nil then
      FCfg.ColumnasTallas[iColumna].Visible := False;
  end;
  FActivo := False;
end;

procedure TPresentacionPivoteCompra.Recargar;
begin
  if FActivo and (FCfg.SourceLineas <> nil) then
  begin
    FCfg.SourceLineas.Filtered := False;
    FCorrespondencia.Cargar;
    RefrescarPestanas;
    FCfg.SourceLineas.Filtered := True;
    if FCfg.Gestor <> nil then
    begin
      FCfg.Gestor.InvalidarCache;
      FCfg.Gestor.RecalcularMaxColumnas;
      FCfg.Gestor.ActualizarCaptionsLineaActiva;
    end;
    AplicarColumnaCantidadSinTalla;
    PublicarCantidades;
  end;
end;

function TPresentacionPivoteCompra.PuedeExpandir: Boolean;
begin
  Result := FCfg.FieldCantidadRecibida <> '';
end;

procedure TPresentacionPivoteCompra.Expandir;
var
  iColumna: Integer;
  iRegistro: Integer;
begin
  if FActivo and PuedeExpandir and (not FExpandido) and
     (FCfg.Grid <> nil) then
  begin
    FCfg.Grid.DataController.BeginUpdate;
    try
      for iRegistro := 0 to FCfg.Grid.DataController.RecordCount - 1 do
      begin
        for iColumna := 0 to High(FCfg.ColumnasTallas) do
        begin
          if FCfg.ColumnasTallas[iColumna] <> nil then
            FCfg.Grid.DataController.Values[iRegistro,
              FCfg.ColumnasTallas[iColumna].Index] := Null;
        end;
      end;
      for iColumna := 0 to High(FCfg.ColumnasTallas) do
      begin
        if FCfg.ColumnasTallas[iColumna] <> nil then
          FCfg.ColumnasTallas[iColumna].Options.Editing := True;
      end;
    finally
      FCfg.Grid.DataController.EndUpdate;
    end;
    FAlturaFilaOriginal := FCfg.Grid.OptionsView.DataRowHeight;
    FCfg.Grid.OptionsView.DataRowHeight := ALTURA_FILA_EXPANDIDA;
    FExpandido := True;
  end;
end;

procedure TPresentacionPivoteCompra.Contraer;
var
  iColumna: Integer;
begin
  if FExpandido then
  begin
    if FCfg.Grid <> nil then
    begin
      FCfg.Grid.OptionsView.DataRowHeight := FAlturaFilaOriginal;
      for iColumna := 0 to High(FCfg.ColumnasTallas) do
      begin
        if FCfg.ColumnasTallas[iColumna] <> nil then
          FCfg.ColumnasTallas[iColumna].Options.Editing := False;
      end;
    end;
    FExpandido := False;
    PublicarCantidades;
  end;
end;

procedure TPresentacionPivoteCompra.FiltrarRegistro(DataSet: TDataSet;
  var Accept: Boolean);
var
  iLinea: Integer;
  sPestana: string;
begin
  Accept := True;
  if FCache.LineasRepresentantes <> nil then
  begin
    iLinea := DataSet.FieldByName(FCfg.FieldLinea).AsInteger;
    Accept := FCache.LineasRepresentantes.Contains(iLinea);
    if Accept and (FPestanas <> nil) and
       (FPestanas.CodigoSeleccionado <> '') then
    begin
      sPestana := '';
      FCache.PestanaTexto.TryGetValue(iLinea, sPestana);
      Accept := SameText(sPestana, FPestanas.CodigoSeleccionado);
    end;
  end;
end;

procedure TPresentacionPivoteCompra.AplicarColumnaCantidadSinTalla;
var
  iColumna: Integer;
  bVisible: Boolean;
begin
  bVisible := False;
  if (FCache.SinTalla.Count > 0) and
     (Length(FCfg.ColumnasTallas) > 0) and
     (FCfg.ColumnasTallas[0] <> nil) then
  begin
    for iColumna := 0 to High(FCfg.ColumnasTallas) do
    begin
      if (FCfg.ColumnasTallas[iColumna] <> nil) and
         FCfg.ColumnasTallas[iColumna].Visible then
        bVisible := True;
    end;
    if not bVisible then
    begin
      FCfg.ColumnasTallas[0].Visible := True;
      FCfg.ColumnasTallas[0].Caption := SCaptionColCantidad;
    end;
  end;
end;

procedure TPresentacionPivoteCompra.PublicarCantidades;
var
  oColumnaLinea: TcxGridDBColumn;
  vLinea        : Variant;
  aPosiciones   : TArrPosConjunto;
  iRegistro     : Integer;
  iLinea        : Integer;
  iConjunto     : Integer;
  iPosicion     : Integer;
  iClave        : Int64;
  dCantidad     : Double;
begin
  if (FCfg.Gestor <> nil) and (FCfg.Grid <> nil) then
  begin
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    if oColumnaLinea <> nil then
    begin
      FActualizandoGrid := True;
      try
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
            if (iLinea > 0) and (FCfg.ColColorPivot <> nil) and
               FCache.ColorTexto.ContainsKey(iLinea) then
              FCfg.Grid.DataController.Values[iRegistro,
                FCfg.ColColorPivot.Index] := TextoFilaConPestana(
                  FCache.ColorTexto[iLinea], PestanaDeLinea(iLinea));
            if (iLinea > 0) and
               (FCfg.ColColorProveedorPivot <> nil) and
               FCache.ColorProveedor.ContainsKey(iLinea) then
              FCfg.Grid.DataController.Values[iRegistro,
                FCfg.ColColorProveedorPivot.Index] :=
                  FCache.ColorProveedor[iLinea];
            if (iLinea > 0) and FCache.SinTalla.ContainsKey(iLinea) and
               (not FExpandido) and
               (Length(FCfg.ColumnasTallas) > 0) and
               (FCfg.ColumnasTallas[0] <> nil) then
            begin
              iClave := ClaveCeldaPivoteCompra(iLinea,
                ID_AV_SIN_TALLA);
              dCantidad := 0;
              FCache.Cantidades.TryGetValue(iClave, dCantidad);
              if dCantidad <> 0 then
                FCfg.Grid.DataController.Values[iRegistro,
                  FCfg.ColumnasTallas[0].Index] := dCantidad
              else
                FCfg.Grid.DataController.Values[iRegistro,
                  FCfg.ColumnasTallas[0].Index] := Null;
            end
            else if (iLinea > 0) and (iConjunto > 0) and
                    (not FExpandido) then
            begin
              aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
                iConjunto, FCache.ArticuloLinea(iLinea));
              for iPosicion := 0 to High(aPosiciones) do
              begin
                if (iPosicion < FCfg.MaxColumnasTallas) and
                   (iPosicion < Length(FCfg.ColumnasTallas)) and
                   (FCfg.ColumnasTallas[iPosicion] <> nil) then
                begin
                  iClave := ClaveCeldaPivoteCompra(iLinea,
                    aPosiciones[iPosicion].IdAv);
                  dCantidad := 0;
                  FCache.Cantidades.TryGetValue(iClave, dCantidad);
                  if dCantidad <> 0 then
                    FCfg.Grid.DataController.Values[iRegistro,
                      FCfg.ColumnasTallas[iPosicion].Index] := dCantidad
                  else
                    FCfg.Grid.DataController.Values[iRegistro,
                      FCfg.ColumnasTallas[iPosicion].Index] := Null;
                end;
              end;
            end;
          end;
        finally
          FCfg.Grid.DataController.EndUpdate;
        end;
      finally
        FActualizandoGrid := False;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteCompra.AplicarVisibilidad(
  AModoPivote: Boolean);
var
  iCampo: Integer;
  oColumna: TcxGridColumn;
begin
  for iCampo := 0 to High(FCfg.CamposOcultosEnPivote) do
  begin
    oColumna := FCfg.Grid.GetColumnByFieldName(
      FCfg.CamposOcultosEnPivote[iCampo]);
    if oColumna <> nil then
      oColumna.Visible := not AModoPivote;
  end;
  if FCfg.ColColorPivot <> nil then
    FCfg.ColColorPivot.Visible := AModoPivote;
  if FCfg.ColColorProveedorPivot <> nil then
    FCfg.ColColorProveedorPivot.Visible := AModoPivote;
  IntercambiarPosicionColorAlmacen(AModoPivote);
end;

procedure TPresentacionPivoteCompra.IntercambiarPosicionColorAlmacen(
  AModoPivote: Boolean);
var
  oColumnaAlmacen: TcxGridDBColumn;
  oPrimeraTalla  : TcxGridDBColumn;
  oUltimaTalla   : TcxGridDBColumn;
  bConfigValida  : Boolean;
begin
  bConfigValida := (FCfg.ColColorPivot <> nil) and
    (FCfg.FieldAlmacen <> '') and
    (Length(FCfg.ColumnasTallas) > 0);
  if bConfigValida then
  begin
    oColumnaAlmacen := FCfg.Grid.GetColumnByFieldName(FCfg.FieldAlmacen);
    oPrimeraTalla := FCfg.ColumnasTallas[0];
    oUltimaTalla := FCfg.ColumnasTallas[High(FCfg.ColumnasTallas)];
    bConfigValida := (oColumnaAlmacen <> nil) and
      (oPrimeraTalla <> nil) and (oUltimaTalla <> nil);
    if bConfigValida and AModoPivote then
    begin
      if FIndiceOriginalAlmacen < 0 then
        FIndiceOriginalAlmacen := oColumnaAlmacen.Index;
      if FIndiceOriginalColor < 0 then
        FIndiceOriginalColor := FCfg.ColColorPivot.Index;
      MoverColumnaJustoAntes(FCfg.ColColorPivot, oPrimeraTalla);
      if FCfg.ColColorProveedorPivot <> nil then
      begin
        if FIndiceOriginalProveedor < 0 then
          FIndiceOriginalProveedor :=
            FCfg.ColColorProveedorPivot.Index;
        MoverColumnaJustoAntes(FCfg.ColColorProveedorPivot,
          FCfg.ColColorPivot);
      end;
      MoverColumnaJustoDespues(oColumnaAlmacen, oUltimaTalla);
    end
    else if bConfigValida then
    begin
      if FIndiceOriginalColor >= 0 then
        FCfg.ColColorPivot.Index := FIndiceOriginalColor;
      if FIndiceOriginalAlmacen >= 0 then
        oColumnaAlmacen.Index := FIndiceOriginalAlmacen;
      if (FCfg.ColColorProveedorPivot <> nil) and
         (FIndiceOriginalProveedor >= 0) then
        FCfg.ColColorProveedorPivot.Index :=
          FIndiceOriginalProveedor;
    end;
  end;
end;

function TPresentacionPivoteCompra.ObtenerLineaActiva(
  out ALinea: Integer; out ALineaTexto: string): Boolean;
var
  oColumnaLinea: TcxGridDBColumn;
  oRegistro    : TcxCustomGridRecord;
  vLinea       : Variant;
begin
  ALinea := 0;
  ALineaTexto := '';
  if FCfg.Grid <> nil then
  begin
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    oRegistro := FCfg.Grid.Controller.FocusedRecord;
    if (oColumnaLinea <> nil) and (oRegistro <> nil) then
    begin
      vLinea := FCfg.Grid.DataController.Values[oRegistro.RecordIndex,
        oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
      begin
        ALineaTexto := VarToStr(vLinea);
        ALinea := StrToIntDef(ALineaTexto, 0);
      end;
    end;
  end;
  Result := ALinea > 0;
end;

procedure TPresentacionPivoteCompra.CustomDrawCellTalla(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oColumna      : TcxGridColumn;
  oColumnaLinea : TcxGridColumn;
  vLinea        : Variant;
  aPosiciones   : TArrPosConjunto;
  iConjunto     : Integer;
  iLinea        : Integer;
  iTalla        : Integer;
  iClave        : Int64;
  bEsTalla      : Boolean;
  bSinTalla     : Boolean;
  eEstado       : TEstadoFilaRecibida;
  oColorFila    : TColor;
  dPedido       : Double;
  dRecibida     : Double;
  dARecibir     : Double;
  dTotalPedido  : Double;
  dTotalRecibido: Double;
begin
  if FActivo and (FCfg.Gestor <> nil) and
     (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item is TcxGridColumn) then
  begin
    oColumna := TcxGridColumn(AViewInfo.Item);
    bEsTalla := (oColumna.Tag >= 1) and
      (oColumna.Tag <= FCfg.MaxColumnasTallas) and
      (oColumna.Tag - 1 < Length(FCfg.ColumnasTallas)) and
      (oColumna = FCfg.ColumnasTallas[oColumna.Tag - 1]);
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if oColumnaLinea <> nil then
    begin
      vLinea := AViewInfo.GridRecord.Values[oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    iConjunto := 0;
    if iLinea > 0 then
      FCache.IdConjunto.TryGetValue(iLinea, iConjunto);
    bSinTalla := FCache.SinTalla.ContainsKey(iLinea);
    if bEsTalla and bSinTalla and (oColumna.Tag > 1) then
    begin
      ACanvas.Brush.Color := $00E8E8E8;
      ACanvas.FillRect(AViewInfo.Bounds);
      ADone := True;
    end
    else if bEsTalla and (not bSinTalla) and (iConjunto > 0) and
            (oColumna.Tag > Length(
              FCfg.Gestor.GetPosicionesConjunto(
                iConjunto, FCache.ArticuloLinea(iLinea)))) then
    begin
      ACanvas.Brush.Color := $00E8E8E8;
      ACanvas.FillRect(AViewInfo.Bounds);
      ADone := True;
    end
    else if FExpandido and PuedeExpandir and (iLinea > 0) then
    begin
      dTotalPedido := 0;
      dTotalRecibido := 0;
      FCache.TotalPedido.TryGetValue(iLinea, dTotalPedido);
      FCache.TotalRecibido.TryGetValue(iLinea, dTotalRecibido);
      eEstado := EstadoRecepcionPivoteCompra(
        dTotalPedido, dTotalRecibido);
      if (eEstado <> efrIndefinido) and
         (bEsTalla or (not AViewInfo.GridRecord.Selected)) then
      begin
        case eEstado of
          efrParcial:
            oColorFila := COL_REC_PARCIAL;
          efrTotal:
            oColorFila := COL_REC_TOTAL;
        else
          oColorFila := COL_REC_NADA;
        end;
        if bEsTalla then
        begin
          iTalla := -1;
          if bSinTalla and (oColumna.Tag = 1) then
            iTalla := ID_AV_SIN_TALLA
          else if (not bSinTalla) and (iConjunto > 0) then
          begin
            aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
              iConjunto, FCache.ArticuloLinea(iLinea));
            if oColumna.Tag <= Length(aPosiciones) then
              iTalla := aPosiciones[oColumna.Tag - 1].IdAv;
          end;
          if iTalla >= 0 then
          begin
            iClave := ClaveCeldaPivoteCompra(iLinea, iTalla);
            dPedido := 0;
            dRecibida := 0;
            dARecibir := 0;
            FCache.Cantidades.TryGetValue(iClave, dPedido);
            FCache.CantidadesRecibidas.TryGetValue(iClave, dRecibida);
            FEstadoEdicion.ARecibir.TryGetValue(iClave, dARecibir);
            PintarCeldaTallaTresSegmentos(ACanvas, AViewInfo,
              oColorFila, dPedido, dRecibida, dARecibir);
            if (FCfg.Grid.Controller.FocusedRecord =
                AViewInfo.GridRecord) and
               (FCfg.Grid.Controller.FocusedItem = AViewInfo.Item) then
              DibujarBordeFoco(ACanvas, AViewInfo.Bounds);
            ADone := True;
          end;
        end
        else
        begin
          ACanvas.Brush.Color := oColorFila;
          ACanvas.FillRect(AViewInfo.Bounds);
        end;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteCompra.PintarCeldaTallaTresSegmentos(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  AColorFondo: TColor; APedida, ARecibida, ARecibir: Double);
var
  oLimites             : TRect;
  oRectPedido          : TRect;
  oRectRecibido        : TRect;
  oRectARecibir        : TRect;
  iAltoSegmento        : Integer;
  iInicioRecibido      : Integer;
  iInicioARecibir      : Integer;
  sPedido              : string;
  sRecibido            : string;
  sARecibir            : string;
begin
  // FZ-ISSUE-211: Round mostraba 125,5 m como 126.
  sPedido := '';
  if APedida > 0 then
    sPedido := FormatFloat('0.###', APedida);
  sRecibido := FormatFloat('0.###', ARecibida);
  sARecibir := '';
  if ARecibir > 0 then
    sARecibir := FormatFloat('0.###', ARecibir);
  ACanvas.Brush.Color := AColorFondo;
  ACanvas.FillRect(AViewInfo.Bounds);
  oLimites := AViewInfo.Bounds;
  iAltoSegmento := (oLimites.Bottom - oLimites.Top) div 3;
  iInicioRecibido := oLimites.Top + iAltoSegmento;
  iInicioARecibir := oLimites.Top + 2 * iAltoSegmento;
  oRectPedido := Rect(oLimites.Left, oLimites.Top,
    oLimites.Right, iInicioRecibido);
  oRectRecibido := Rect(oLimites.Left, iInicioRecibido,
    oLimites.Right, iInicioARecibir);
  oRectARecibir := Rect(oLimites.Left, iInicioARecibir,
    oLimites.Right, oLimites.Bottom);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := clGrayText;
  DrawText(ACanvas.Handle, PChar(sPedido), Length(sPedido),
    oRectPedido, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Font.Color := clGreen;
  ACanvas.Font.Style := [fsItalic];
  DrawText(ACanvas.Handle, PChar(sRecibido), Length(sRecibido),
    oRectRecibido, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Font.Color := clBlue;
  ACanvas.Font.Style := [fsBold];
  DrawText(ACanvas.Handle, PChar(sARecibir), Length(sARecibir),
    oRectARecibir, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Font.Style := [];
  ACanvas.Pen.Color := clSilver;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(oLimites.Left, iInicioRecibido);
  ACanvas.LineTo(oLimites.Right, iInicioRecibido);
  ACanvas.MoveTo(oLimites.Left, iInicioARecibir);
  ACanvas.LineTo(oLimites.Right, iInicioARecibir);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteCompra.DibujarBordeFoco(
  ACanvas: TcxCanvas; const ARect: TRect);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := clNavy;
  ACanvas.Pen.Width := 2;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Rectangle(ARect.Left + 1, ARect.Top + 1,
    ARect.Right - 1, ARect.Bottom - 1);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteCompra.EditingCeldaTalla(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  oRegistro    : TcxCustomGridRecord;
  oColumnaLinea: TcxGridColumn;
  oCampo       : TField;
  vLinea       : Variant;
  aPosiciones  : TArrPosConjunto;
  iLinea       : Integer;
  iConjunto    : Integer;
  bEsTalla     : Boolean;
begin
  bEsTalla := (AItem <> nil) and (AItem.Tag >= 1) and
    (AItem.Tag <= FCfg.MaxColumnasTallas) and
    (AItem.Tag - 1 < Length(FCfg.ColumnasTallas)) and
    (AItem = FCfg.ColumnasTallas[AItem.Tag - 1]);
  if bEsTalla then
  begin
    AAllow := False;
    if (not FExpandido) and (FCfg.Gestor <> nil) and
       (FCfg.SourceLineas <> nil) and
       (not FCfg.SourceLineas.IsEmpty) then
    begin
      oRegistro := nil;
      if Sender <> nil then
        oRegistro := Sender.Controller.FocusedRecord;
      oColumnaLinea := nil;
      if FCfg.Grid <> nil then
        oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
      iLinea := 0;
      if (oRegistro <> nil) and (oColumnaLinea <> nil) then
      begin
        vLinea := oRegistro.Values[oColumnaLinea.Index];
        if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
          iLinea := StrToIntDef(VarToStr(vLinea), 0);
      end;
      oCampo := FCfg.SourceLineas.FindField(FCfg.FieldLinea);
      if (iLinea <= 0) and (oCampo <> nil) then
        iLinea := oCampo.AsInteger;
      if iLinea > 0 then
      begin
        if FCache.SinTalla.ContainsKey(iLinea) then
          AAllow := AItem.Tag = 1
        else
        begin
          iConjunto := 0;
          if not FCache.IdConjunto.TryGetValue(iLinea, iConjunto) then
          begin
            oCampo := FCfg.SourceLineas.FindField(FCfg.FieldIdAcPivot);
            if oCampo <> nil then
              iConjunto := oCampo.AsInteger;
          end;
          if iConjunto > 0 then
          begin
            aPosiciones := FCfg.Gestor.GetPosicionesConjunto(
              iConjunto, FCache.ArticuloLinea(iLinea));
            AAllow := AItem.Tag <= Length(aPosiciones);
          end;
        end;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteCompra.InitEditCeldaTalla(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

procedure TPresentacionPivoteCompra.CustomDrawColorCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oColumnaLinea: TcxGridDBColumn;
  vLinea        : Variant;
  iRegistro     : Integer;
  iLinea        : Integer;
  sCodigo       : string;
  sTexto        : string;
  sArticulo     : string;
begin
  ADone := False;
  if AViewInfo.GridRecord <> nil then
  begin
    iRegistro := AViewInfo.GridRecord.RecordIndex;
    oColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    iLinea := 0;
    if oColumnaLinea <> nil then
    begin
      vLinea := FCfg.Grid.DataController.Values[iRegistro,
        oColumnaLinea.Index];
      if not (VarIsNull(vLinea) or VarIsEmpty(vLinea)) then
        iLinea := StrToIntDef(VarToStr(vLinea), 0);
    end;
    if iLinea > 0 then
    begin
      sCodigo := '';
      sTexto := '';
      sArticulo := '';
      FCache.ColorCodigo.TryGetValue(iLinea, sCodigo);
      FCache.ColorTexto.TryGetValue(iLinea, sTexto);
      FCache.Articulo.TryGetValue(iLinea, sArticulo);
      if sTexto = '' then
        sTexto := sCodigo;
      ADone := PintarCeldaSwatchArticuloSiAplica(
        FCfg.Conexion, ACanvas, AViewInfo, sArticulo, sTexto, nil);
    end;
  end;
end;

end.

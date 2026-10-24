{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorFiltrosMto                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona los filtros guardados de los mantenimientos genéricos.           }
{******************************************************************************}
unit inLibGestorFiltrosMto;

interface

uses
  System.Classes, Vcl.ExtCtrls, Vcl.Menus, Vcl.Buttons,
  cxGridDBTableView, cxTextEdit, inLibFiltrosGuardadosIntf;

type
  TDatosGuardadoFiltroMto = record
    Aceptado: Boolean;
    Nombre: string;
    Descripcion: string;
  end;

  TResultadoGestionFiltroMto = record
    Aplicado: Boolean;
    FiltroBase64: string;
  end;

  TSolicitarDatosFiltroMto = function: TDatosGuardadoFiltroMto of object;
  TEjecutarGestionFiltroMto = function(
    const AFiltroActualBase64: string
  ): TResultadoGestionFiltroMto of object;

  TGestorFiltrosMto = class
  private
    FPropietario: TComponent;
    FVista: TcxGridDBTableView;
    FEditorBusqueda: TcxTextEdit;
    FTemporizadorBusqueda: TTimer;
    FMenu: TPopupMenu;
    FServicioLectura: ILectorFiltrosGuardados;
    FServicioEscritura: IEscritorFiltrosGuardados;
    FSolicitarDatos: TSolicitarDatosFiltroMto;
    FEjecutarGestion: TEjecutarGestionFiltroMto;
    FFiltroCapturadoBase64: string;
    FBusquedaCapturada: string;
    procedure AplicarFiltroGuardadoClick(Sender: TObject);
    procedure GuardarFiltroActualClick(Sender: TObject);
    procedure GestionarFiltrosClick(Sender: TObject);
  public
    constructor Create(
      APropietario: TComponent;
      AVista: TcxGridDBTableView;
      AEditorBusqueda: TcxTextEdit;
      ATemporizadorBusqueda: TTimer;
      AMenu: TPopupMenu;
      const AServicioLectura: ILectorFiltrosGuardados;
      const AServicioEscritura: IEscritorFiltrosGuardados;
      ASolicitarDatos: TSolicitarDatosFiltroMto;
      AEjecutarGestion: TEjecutarGestionFiltroMto);
    procedure MostrarMenu(AButton: TSpeedButton);
    procedure CargarMenu;
    procedure CapturarActual;
    function SerializarActualBase64: string;
    function ExtraerBusquedaGlobal: string;
    procedure RestaurarCapturado;
    procedure AplicarDesdeBase64(const ABase64: string);
    property FiltroCapturadoBase64: string
      read FFiltroCapturadoBase64;
    property BusquedaCapturada: string read FBusquedaCapturada;
  end;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows, System.SysUtils, System.Variants, System.NetEncoding,
  System.Types, Vcl.Forms, Vcl.Dialogs, cxFilter, inLibDevExp,
  inLibMsgComun;

constructor TGestorFiltrosMto.Create(
  APropietario: TComponent;
  AVista: TcxGridDBTableView;
  AEditorBusqueda: TcxTextEdit;
  ATemporizadorBusqueda: TTimer;
  AMenu: TPopupMenu;
  const AServicioLectura: ILectorFiltrosGuardados;
  const AServicioEscritura: IEscritorFiltrosGuardados;
  ASolicitarDatos: TSolicitarDatosFiltroMto;
  AEjecutarGestion: TEjecutarGestionFiltroMto);
begin
  inherited Create;
  FPropietario := APropietario;
  FVista := AVista;
  FEditorBusqueda := AEditorBusqueda;
  FTemporizadorBusqueda := ATemporizadorBusqueda;
  FMenu := AMenu;
  FServicioLectura := AServicioLectura;
  FServicioEscritura := AServicioEscritura;
  FSolicitarDatos := ASolicitarDatos;
  FEjecutarGestion := AEjecutarGestion;
  FFiltroCapturadoBase64 := '';
  FBusquedaCapturada := '';
end;

procedure TGestorFiltrosMto.MostrarMenu(AButton: TSpeedButton);
var
  oPunto: TPoint;
begin
  CapturarActual;
  CargarMenu;
  oPunto := AButton.ClientToScreen(Point(0, AButton.Height));
  FMenu.Popup(oPunto.X, oPunto.Y);
end;

procedure TGestorFiltrosMto.CargarMenu;
var
  oLista: TFiltrosGuardadosList;
  oInfo: TFiltroGuardadoInfo;
  oItem: TMenuItem;
  oSeparador: TMenuItem;
begin
  FMenu.Items.Clear;
  if Assigned(FServicioLectura) then
  begin
    oLista := FServicioLectura.ListarFiltros(
      FPropietario.Name, FVista.Name);
    try
      if oLista.Count = 0 then
      begin
        oItem := TMenuItem.Create(FMenu);
        oItem.Caption := SCaptionSinFiltrosGuardados;
        oItem.Enabled := False;
        FMenu.Items.Add(oItem);
      end
      else
      begin
        for oInfo in oLista do
        begin
          oItem := TMenuItem.Create(FMenu);
          if oInfo.EsPropio then
            oItem.Caption := oInfo.Nombre
          else
            oItem.Caption := oInfo.Nombre + ' (' +
              oInfo.Propietario + ')';
          oItem.Tag := oInfo.Id;
          oItem.OnClick := AplicarFiltroGuardadoClick;
          FMenu.Items.Add(oItem);
        end;
      end;
    finally
      FreeAndNil(oLista);
    end;
  end;
  oSeparador := TMenuItem.Create(FMenu);
  oSeparador.Caption := '-';
  FMenu.Items.Add(oSeparador);
  oItem := TMenuItem.Create(FMenu);
  oItem.Caption := SCaptionGuardarFiltroActual;
  oItem.OnClick := GuardarFiltroActualClick;
  FMenu.Items.Add(oItem);
  oItem := TMenuItem.Create(FMenu);
  oItem.Caption := SCaptionGestionarCompartirFiltros;
  oItem.OnClick := GestionarFiltrosClick;
  FMenu.Items.Add(oItem);
end;

procedure TGestorFiltrosMto.CapturarActual;
begin
  FTemporizadorBusqueda.Enabled := False;
  if FEditorBusqueda.Text <> '' then
    BusqAllGrid(FVista, FEditorBusqueda.Text);
  FBusquedaCapturada := FEditorBusqueda.Text;
  if FVista.DataController.Filter.IsEmpty then
    FFiltroCapturadoBase64 := ''
  else
    FFiltroCapturadoBase64 := SerializarActualBase64;
end;

function TGestorFiltrosMto.SerializarActualBase64: string;
var
  oStreamBinario: TMemoryStream;
  oStreamBase64: TStringStream;
begin
  Result := '';
  oStreamBinario := TMemoryStream.Create;
  oStreamBase64 := TStringStream.Create('');
  try
    FVista.DataController.Filter.SaveToStream(oStreamBinario);
    oStreamBinario.Position := 0;
    TNetEncoding.Base64.Encode(oStreamBinario, oStreamBase64);
    Result := oStreamBase64.DataString;
  finally
    FreeAndNil(oStreamBase64);
    FreeAndNil(oStreamBinario);
  end;
end;

function TGestorFiltrosMto.ExtraerBusquedaGlobal: string;
  function TextoDesdeLike(const AValor: string): string;
  var
    sValor: string;
  begin
    Result := '';
    sValor := Trim(AValor);
    if (Length(sValor) >= 2) and
       (sValor[1] = '%') and
       (sValor[Length(sValor)] = '%') then
    begin
      Result := Copy(sValor, 2, Length(sValor) - 2);
    end;
  end;
  function TextoBusquedaLista(
    ALista: TcxFilterCriteriaItemList): string;
  var
    iIndice: Integer;
    bValido: Boolean;
    oItemBase: TcxCustomFilterCriteriaItem;
    oItem: TcxFilterCriteriaItem;
    sTexto: string;
    sTextoItem: string;
  begin
    Result := '';
    sTexto := '';
    bValido := Assigned(ALista) and
      (ALista.BoolOperatorKind = fboOr) and
      (ALista.Count > 0);
    iIndice := 0;
    oItem := nil;
    while bValido and (iIndice < ALista.Count) do
    begin
      oItemBase := ALista.Items[iIndice];
      bValido := (not oItemBase.IsItemList) and
        (oItemBase is TcxFilterCriteriaItem);
      if bValido then
      begin
        oItem := TcxFilterCriteriaItem(oItemBase);
        bValido := oItem.OperatorKind = foLike;
      end;
      if bValido then
      begin
        sTextoItem := TextoDesdeLike(VarToStr(oItem.Value));
        if sTextoItem = '' then
          sTextoItem := TextoDesdeLike(oItem.DisplayValue);
        bValido := sTextoItem <> '';
      end;
      if bValido then
      begin
        if sTexto = '' then
          sTexto := sTextoItem
        else
          bValido := SameText(sTexto, sTextoItem);
      end;
      Inc(iIndice);
    end;
    if bValido then
      Result := sTexto;
  end;
var
  iIndice: Integer;
  oItemBase: TcxCustomFilterCriteriaItem;
  oRaiz: TcxFilterCriteriaItemList;
begin
  Result := '';
  oRaiz := FVista.DataController.Filter.Root;
  if oRaiz.BoolOperatorKind = fboOr then
    Result := TextoBusquedaLista(oRaiz);
  if (Result = '') and
     (oRaiz.BoolOperatorKind = fboAnd) then
  begin
    iIndice := 0;
    while (Result = '') and (iIndice < oRaiz.Count) do
    begin
      oItemBase := oRaiz.Items[iIndice];
      if oItemBase.IsItemList then
        Result := TextoBusquedaLista(
          TcxFilterCriteriaItemList(oItemBase));
      Inc(iIndice);
    end;
  end;
end;

procedure TGestorFiltrosMto.RestaurarCapturado;
begin
  if not (csDestroying in FPropietario.ComponentState) then
  begin
    FTemporizadorBusqueda.Enabled := False;
    if FEditorBusqueda.Text <> FBusquedaCapturada then
      FEditorBusqueda.Text := FBusquedaCapturada;
    FTemporizadorBusqueda.Enabled := False;
    if FBusquedaCapturada <> '' then
      BusqAllGrid(FVista, FBusquedaCapturada)
    else if FFiltroCapturadoBase64 <> '' then
      AplicarDesdeBase64(FFiltroCapturadoBase64);
  end;
end;

procedure TGestorFiltrosMto.AplicarDesdeBase64(
  const ABase64: string);
var
  oStreamBinario: TMemoryStream;
  oStreamBase64: TStringStream;
  sBusquedaGlobal: string;
begin
  if ABase64 = '' then
  begin
    ShowMessage_fza(SErrorFiltroSinCondiciones);
  end
  else
  begin
    oStreamBase64 := TStringStream.Create(ABase64);
    oStreamBinario := TMemoryStream.Create;
    try
      oStreamBase64.Position := 0;
      TNetEncoding.Base64.Decode(oStreamBase64, oStreamBinario);
      oStreamBinario.Position := 0;
      FVista.DataController.Filter.LoadFromStream(oStreamBinario);
      FVista.DataController.Filter.Active :=
        not FVista.DataController.Filter.IsEmpty;
      sBusquedaGlobal := ExtraerBusquedaGlobal;
      FTemporizadorBusqueda.Enabled := False;
      if FEditorBusqueda.Text <> sBusquedaGlobal then
        FEditorBusqueda.Text := sBusquedaGlobal;
      FTemporizadorBusqueda.Enabled := False;
      FBusquedaCapturada := sBusquedaGlobal;
      FFiltroCapturadoBase64 := ABase64;
    finally
      FreeAndNil(oStreamBinario);
      FreeAndNil(oStreamBase64);
    end;
  end;
end;

procedure TGestorFiltrosMto.AplicarFiltroGuardadoClick(
  Sender: TObject);
var
  sFiltroBase64: string;
begin
  FTemporizadorBusqueda.Enabled := False;
  if Assigned(FServicioLectura) then
  begin
    sFiltroBase64 := FServicioLectura.CargarFiltroBase64(
      (Sender as TMenuItem).Tag);
    AplicarDesdeBase64(sFiltroBase64);
  end;
  FTemporizadorBusqueda.Enabled := False;
end;

procedure TGestorFiltrosMto.GuardarFiltroActualClick(
  Sender: TObject);
var
  oDatos: TDatosGuardadoFiltroMto;
  sFiltroBase64: string;
  sBusquedaGlobal: string;
  iIdFiltro: Int64;
begin
  if FTemporizadorBusqueda.Enabled then
  begin
    FTemporizadorBusqueda.Enabled := False;
    BusqAllGrid(FVista, FEditorBusqueda.Text);
  end;
  sFiltroBase64 := '';
  sBusquedaGlobal := FEditorBusqueda.Text;
  if (sBusquedaGlobal = '') and
     (FBusquedaCapturada <> '') then
    sBusquedaGlobal := FBusquedaCapturada;
  FTemporizadorBusqueda.Enabled := False;
  if FEditorBusqueda.Text <> sBusquedaGlobal then
    FEditorBusqueda.Text := sBusquedaGlobal;
  FTemporizadorBusqueda.Enabled := False;
  if sBusquedaGlobal <> '' then
  begin
    BusqAllGrid(FVista, sBusquedaGlobal);
    sFiltroBase64 := SerializarActualBase64;
    BusqAllGrid(FVista, sBusquedaGlobal);
  end
  else if not FVista.DataController.Filter.IsEmpty then
    sFiltroBase64 := SerializarActualBase64
  else if FFiltroCapturadoBase64 <> '' then
  begin
    sFiltroBase64 := FFiltroCapturadoBase64;
    AplicarDesdeBase64(sFiltroBase64);
  end;
  if sFiltroBase64 = '' then
  begin
    ShowMessage_fza(SErrorFiltroActualVacio);
  end
  else if Assigned(FSolicitarDatos) and
          Assigned(FServicioLectura) and
          Assigned(FServicioEscritura) then
  begin
    try
      FFiltroCapturadoBase64 := sFiltroBase64;
      FBusquedaCapturada := sBusquedaGlobal;
      RestaurarCapturado;
      TThread.ForceQueue(nil,
        procedure
        begin
          RestaurarCapturado;
        end);
      oDatos := FSolicitarDatos();
      if oDatos.Aceptado then
      begin
        iIdFiltro := FServicioLectura.BuscarFiltroPropio(
          FPropietario.Name, FVista.Name, oDatos.Nombre);
        if iIdFiltro > 0 then
        begin
          if MessageBox_fza(
              PChar(SPreguntaSobrescribirFiltro),
              PChar(STituloSobrescribirFiltro),
              MB_YESNO + MB_ICONQUESTION) = ID_YES then
          begin
            FServicioEscritura.SobrescribirFiltro(
              iIdFiltro, oDatos.Nombre, oDatos.Descripcion,
              sFiltroBase64);
            ShowMessage_fza(SInfoFiltroSobrescrito);
          end;
        end
        else
        begin
          FServicioEscritura.GuardarFiltroNuevo(
            FPropietario.Name, FVista.Name, oDatos.Nombre,
            oDatos.Descripcion, sFiltroBase64);
          ShowMessage_fza(SInfoFiltroGuardado);
        end;
      end;
    finally
      RestaurarCapturado;
    end;
  end;
end;

procedure TGestorFiltrosMto.GestionarFiltrosClick(
  Sender: TObject);
var
  oResultado: TResultadoGestionFiltroMto;
begin
  if Assigned(FEjecutarGestion) then
  begin
    oResultado := FEjecutarGestion(
      FFiltroCapturadoBase64);
    if oResultado.Aplicado then
      AplicarDesdeBase64(oResultado.FiltroBase64);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionAtributos                           }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Edicion de los atributos basicos del SKU y activacion por color. Recibe   }
{    datasets, el gestor de atributos y una accion de bloque; nunca el         }
{    formulario ni un contexto general de repositorios.                        }
{******************************************************************************}
unit inMtoArticulosPresentacionAtributos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Types, System.Variants,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Dialogs, Data.DB,
  Datasnap.DBClient, System.Generics.Collections,
  cxGraphics, cxEdit, cxDBLookupComboBox, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView,
  inLibArticulosAtributosBasicosIntf;

type
  // Activa o desactiva en bloque los SKU de un color. Devuelve las filas
  // afectadas. Lo aporta el data module; aqui solo se invoca.
  TCambiarActivoSkusColor = reference to function(
    const ACodigoArticulo, AColor, AActivo: string): Integer;

  TCambioBasicoPendiente = record
    Contexto: TContextoAtributoBasicoSku;
    IdBasico: TEnteroOpcional;
    Codigo: string;
  end;

  TPresentadorAtributosBasicosArticulo = class
  private
    FCambios: TDictionary<string, TCambioBasicoPendiente>;
    FListaBasicos: TClientDataSet;
    FOrigenLista: TDataSource;
    FOrigenAnterior: TDataSource;
    FEditorLista: TcxLookupComboBox;
    FDetalles: TDataSet;
    FLookupBasicos: TDataSet;
    FSkus: TDataSet;
    FGestor: IGestorAtributosBasicosSku;
    FUsuario: string;
    FIdAtributoFila: string;
    FCambiarActivoSkusColor: TCambiarActivoSkusColor;
    function HayDetalleActivo: Boolean;
    function ObtenerContextoActual(
      out AContexto: TContextoAtributoBasicoSku): Boolean;
    function PreguntarAmbito(const ACodigoArticulo, AValor: string;
      out AAmbito: TAmbitoAtributoBasico): Boolean;
    function AsegurarBasicoFilaActual: Integer;
    procedure RefrescarTrasEdicion;
  public
    constructor Create(
      ADetalles: TDataSet;
      ALookupBasicos: TDataSet;
      ASkus: TDataSet;
      const AGestor: IGestorAtributosBasicosSku;
      const AUsuario: string;
      const ACambiarActivoSkusColor: TCambiarActivoSkusColor);
    destructor Destroy; override;
    procedure GuardarCambios;
    procedure CancelarCambios;
    procedure MostrarBasicoPendiente(const AVariacion, AValor: string;
      var ATexto: string);
    procedure MostrarFuente(var ATexto: string);
    procedure CambiarNombre(ASender: TObject);
    procedure CambiarValorNumerico(ASender: TObject);
    procedure CambiarUnidad(ASender: TObject);
    procedure CambiarDescripcion(ASender: TObject);
    procedure PrepararListaBasicos(AProperties: TcxLookupComboBoxProperties);
    procedure AbrirDesplegableBasico(AEditor: TcxLookupComboBox = nil);
    procedure CerrarDesplegableBasico;
    procedure ValidarBasico(var ADisplayValue: Variant;
      var AErrorText: TCaption; var AError: Boolean);
    procedure ElegirColor;
    function ObtenerValorFilaActual(out ACodigoArticulo,
      AValor: string): Boolean;
    procedure CambiarActivoColorSkus(const AActivo: string);
    procedure PintarCeldaHex(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
    property IdAtributoFila: string read FIdAtributoFila
      write FIdAtributoFila;
  end;

implementation

uses
  inLibMensajesVcl,
  Vcl.Forms,
  inLibArticulosPresentacion,
  inLibAtributosPaleta,
  inLibMsgArticulos;

constructor TPresentadorAtributosBasicosArticulo.Create(
  ADetalles: TDataSet;
  ALookupBasicos: TDataSet;
  ASkus: TDataSet;
  const AGestor: IGestorAtributosBasicosSku;
  const AUsuario: string;
  const ACambiarActivoSkusColor: TCambiarActivoSkusColor);
begin
  inherited Create;
  if ADetalles = nil then
    raise EArgumentNilException.Create('ADetalles');
  if not Assigned(AGestor) then
    raise EArgumentNilException.Create('AGestor');
  FCambios := TDictionary<string, TCambioBasicoPendiente>.Create;
  FListaBasicos := TClientDataSet.Create(nil);
  FOrigenLista := TDataSource.Create(nil);
  FOrigenLista.DataSet := FListaBasicos;
  FDetalles := ADetalles;
  FLookupBasicos := ALookupBasicos;
  FSkus := ASkus;
  FGestor := AGestor;
  FUsuario := AUsuario;
  FCambiarActivoSkusColor := ACambiarActivoSkusColor;
end;

destructor TPresentadorAtributosBasicosArticulo.Destroy;
begin
  FOrigenLista.Free;
  FListaBasicos.Free;
  FCambios.Free;
  inherited;
end;

procedure TPresentadorAtributosBasicosArticulo.GuardarCambios;
var
  Cambio: TCambioBasicoPendiente;
begin
  if FCambios.Count > 0 then
  begin
    for Cambio in FCambios.Values do
      FGestor.GuardarOverride(Cambio.Contexto, Cambio.IdBasico);
    FCambios.Clear;
    if HayDetalleActivo then
      RefrescarTrasEdicion;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CancelarCambios;
begin
  if FCambios.Count > 0 then
  begin
    FCambios.Clear;
    if HayDetalleActivo then
      RefrescarTrasEdicion;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.MostrarBasicoPendiente(
  const AVariacion, AValor: string; var ATexto: string);
var
  Cambio: TCambioBasicoPendiente;
begin
  if FCambios.TryGetValue(AVariacion + #9 + AValor, Cambio) then
    ATexto := Cambio.Codigo;
end;

function TPresentadorAtributosBasicosArticulo.HayDetalleActivo: Boolean;
begin
  Result := (FDetalles <> nil) and FDetalles.Active and
            (not FDetalles.IsEmpty);
end;

function TPresentadorAtributosBasicosArticulo.ObtenerContextoActual(
  out AContexto: TContextoAtributoBasicoSku): Boolean;
begin
  AContexto := Default(TContextoAtributoBasicoSku);
  Result := HayDetalleActivo;
  if Result then
  begin
    AContexto.CodigoArticulo :=
      FDetalles.FieldByName('CODIGO_ART_SKU').AsString;
    AContexto.CodigoSku :=
      FDetalles.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    AContexto.IdVariacion := FDetalles.FieldByName('ID_VA_AV').AsString;
    AContexto.ValorAtributo := FDetalles.FieldByName('VALOR_AV').AsString;
    if not FDetalles.FieldByName('ID_AV').IsNull then
      AContexto.IdValor := FDetalles.FieldByName('ID_AV').AsInteger;
    AContexto.Usuario := FUsuario;
    Result := (AContexto.CodigoArticulo <> '') and
              (AContexto.CodigoSku <> '') and
              (AContexto.IdVariacion <> '');
  end;
end;

function TPresentadorAtributosBasicosArticulo.PreguntarAmbito(
  const ACodigoArticulo, AValor: string;
  out AAmbito: TAmbitoAtributoBasico): Boolean;
// Cuando hay que CREAR un atributo basico nuevo preguntamos que tipo
// quiere el usuario: global (compartido) o ad-hoc (exclusivo del
// articulo, prefijo AD_<articulo>_). Cancelar no crea nada.
var
  sCodigoGlobal, sCodigoAdHoc, sTexto: string;
begin
  Result := False;
  AAmbito := aabGlobal;
  sCodigoGlobal := StringReplace(Trim(AValor), ' ', '_', [rfReplaceAll]);
  if sCodigoGlobal = '' then
    sCodigoGlobal := STextoAtributoBasicoSinValor;
  sCodigoAdHoc := Format('AD_%s_%s', [ACodigoArticulo, sCodigoGlobal]);
  sTexto := Format(SPreguntaCrearAtributoBasicoSku,
    [sCodigoGlobal, sCodigoAdHoc]);
  // MB_YESNOCANCEL: Si = global, No = ad-hoc, Cancelar = no crear nada.
  case MessageBox_fza(
         PChar(sTexto),
         PChar(STituloCrearAtributoBasico),
         MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON1) of
    ID_YES:
      begin
        AAmbito := aabGlobal;
        Result := True;
      end;
    ID_NO:
      begin
        AAmbito := aabAdHoc;
        Result := True;
      end;
  end;
end;

function TPresentadorAtributosBasicosArticulo.AsegurarBasicoFilaActual:
  Integer;
var
  oContexto: TContextoAtributoBasicoSku;
  eAmbito: TAmbitoAtributoBasico;
  bContinuar: Boolean;
begin
  Result := 0;
  if ObtenerContextoActual(oContexto) then
  begin
    if not FDetalles.FieldByName('ID_ATB_AV').IsNull then
      Result := FDetalles.FieldByName('ID_ATB_AV').AsInteger
    else
    begin
      eAmbito := aabAdHoc;
      bContinuar := Trim(oContexto.ValorAtributo) = '';
      if not bContinuar then
        bContinuar := PreguntarAmbito(
          oContexto.CodigoArticulo, oContexto.ValorAtributo, eAmbito);
      if bContinuar then
        Result := FGestor.AsegurarBasico(oContexto, eAmbito);
    end;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.RefrescarTrasEdicion;
begin
  if FDetalles.State in [dsEdit, dsInsert] then
    FDetalles.Cancel;
  FDetalles.Refresh;
  if FLookupBasicos <> nil then
    FLookupBasicos.Refresh;
end;

procedure TPresentadorAtributosBasicosArticulo.MostrarFuente(
  var ATexto: string);
begin
  ATexto := EtiquetaFuenteAtributoBasico(ATexto);
end;

procedure TPresentadorAtributosBasicosArticulo.CambiarNombre(
  ASender: TObject);
var
  iIdBasico: Integer;
  vNuevo: Variant;
begin
  if HayDetalleActivo then
  begin
    iIdBasico := AsegurarBasicoFilaActual;
    if iIdBasico > 0 then
    begin
      vNuevo := (ASender as TcxCustomEdit).EditingValue;
      FGestor.ActualizarNombre(iIdBasico, VarToStr(vNuevo), FUsuario);
      RefrescarTrasEdicion;
    end
    else if FDetalles.State in [dsEdit, dsInsert] then
      FDetalles.Cancel;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CambiarValorNumerico(
  ASender: TObject);
var
  iIdBasico: Integer;
  vNuevo: Variant;
  oValor: TRealOpcional;
begin
  if HayDetalleActivo then
  begin
    iIdBasico := AsegurarBasicoFilaActual;
    if iIdBasico > 0 then
    begin
      vNuevo := (ASender as TcxCustomEdit).EditingValue;
      if VarIsNull(vNuevo) or (VarToStr(vNuevo) = '') then
        oValor := RealNulo
      else
        oValor := RealConValor(Double(vNuevo));
      FGestor.ActualizarValorNumerico(iIdBasico, oValor, FUsuario);
      RefrescarTrasEdicion;
    end
    else if FDetalles.State in [dsEdit, dsInsert] then
      FDetalles.Cancel;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CambiarUnidad(
  ASender: TObject);
var
  iIdBasico: Integer;
  vNuevo: Variant;
begin
  if HayDetalleActivo then
  begin
    iIdBasico := AsegurarBasicoFilaActual;
    if iIdBasico > 0 then
    begin
      vNuevo := (ASender as TcxCustomEdit).EditingValue;
      FGestor.ActualizarUnidad(iIdBasico, VarToStr(vNuevo), FUsuario);
      RefrescarTrasEdicion;
    end
    else if FDetalles.State in [dsEdit, dsInsert] then
      FDetalles.Cancel;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CambiarDescripcion(
  ASender: TObject);
var
  oContexto: TContextoAtributoBasicoSku;
  oDescripcion: TCadenaOpcional;
  oIdBasico: TEnteroOpcional;
  vNuevo: Variant;
begin
  if ObtenerContextoActual(oContexto) then
  begin
    if not FDetalles.FieldByName('ID_ATB_AV').IsNull then
      oIdBasico := EnteroConValor(
        FDetalles.FieldByName('ID_ATB_AV').AsInteger)
    else
      oIdBasico := EnteroNulo;
    vNuevo := (ASender as TcxCustomEdit).EditingValue;
    if VarIsNull(vNuevo) or (VarToStr(vNuevo) = '') then
      oDescripcion := CadenaNula
    else
      oDescripcion := CadenaConValor(VarToStr(vNuevo));
    FGestor.GuardarDescripcion(oContexto, oIdBasico, oDescripcion);
    if FDetalles.State in [dsEdit, dsInsert] then
      FDetalles.Cancel;
    FDetalles.Refresh;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.PrepararListaBasicos(
  AProperties: TcxLookupComboBoxProperties);
// La lista (columnas en el DFM) solo muestra el código y el cuadradito de
// paleta: la columna HEX_ATB se pinta como muestra, sin el texto '#RRGGBB'.
begin
  if AProperties <> nil then
    MostrarMuestraPaletaEnLista(AProperties.ListColumns, 'HEX_ATB');
end;

procedure TPresentadorAtributosBasicosArticulo.AbrirDesplegableBasico(
  AEditor: TcxLookupComboBox);
var
  Marca: TBookmark;
begin
  if Assigned(AEditor) and Assigned(FLookupBasicos) and
     FLookupBasicos.Active and HayDetalleActivo then
  begin
    FListaBasicos.Close;
    FListaBasicos.FieldDefs.Clear;
    FListaBasicos.FieldDefs.Add('ID_ATB', ftInteger);
    FListaBasicos.FieldDefs.Add('ID_VA_ATB', ftString, 30);
    FListaBasicos.FieldDefs.Add('CODIGO_ATB', ftString, 100);
    FListaBasicos.FieldDefs.Add('HEX_ATB', ftString, 20);
    FListaBasicos.CreateDataSet;
    Marca := FLookupBasicos.GetBookmark;
    FLookupBasicos.DisableControls;
    try
      FLookupBasicos.First;
      while not FLookupBasicos.Eof do
      begin
        if SameText(FLookupBasicos.FieldByName('ID_VA_ATB').AsString,
          FDetalles.FieldByName('ID_VA_AV').AsString) then
          FListaBasicos.AppendRecord([
            FLookupBasicos.FieldByName('ID_ATB').Value,
            FLookupBasicos.FieldByName('ID_VA_ATB').Value,
            FLookupBasicos.FieldByName('CODIGO_ATB').Value,
            FLookupBasicos.FieldByName('HEX_ATB').Value]);
        FLookupBasicos.Next;
      end;
    finally
      if FLookupBasicos.BookmarkValid(Marca) then
        FLookupBasicos.GotoBookmark(Marca);
      FLookupBasicos.FreeBookmark(Marca);
      FLookupBasicos.EnableControls;
    end;
    FListaBasicos.First;
    FEditorLista := AEditor;
    FOrigenAnterior := AEditor.Properties.ListSource;
    AEditor.Properties.ListSource := FOrigenLista;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CerrarDesplegableBasico;
begin
  if Assigned(FEditorLista) then
    FEditorLista.Properties.ListSource := FOrigenAnterior;
  FEditorLista := nil;
  FOrigenAnterior := nil;
end;

procedure TPresentadorAtributosBasicosArticulo.ValidarBasico(
  var ADisplayValue: Variant; var AErrorText: TCaption;
  var AError: Boolean);
// Texto tecleado sin elegir del desplegable: primero buscamos un basico
// activo de la misma variacion; si no existe, ofrecemos crearlo; si el
// usuario cancela, marcamos error para no dejar un ID huerfano.
var
  sTexto: string;
  sCodigoExistente: string;
  sCodigoNuevo: string;
  Cambio: TCambioBasicoPendiente;
  eAmbito: TAmbitoAtributoBasico;
  oContexto: TContextoAtributoBasicoSku;
begin
  AError := False;
  sTexto := Trim(VarToStr(ADisplayValue));
  if (sTexto <> '') and ObtenerContextoActual(oContexto) then
  begin
    if FGestor.BuscarCodigoActivo(
         oContexto.IdVariacion, sTexto, sCodigoExistente) then
      ADisplayValue := sCodigoExistente
    else if PreguntarAmbito(
              oContexto.CodigoArticulo, sTexto, eAmbito) then
    begin
      sCodigoNuevo := FGestor.CrearAtributoBasico(
        oContexto, sTexto, eAmbito);
      if FLookupBasicos <> nil then
        FLookupBasicos.Refresh;
      ADisplayValue := sCodigoNuevo;
    end
    else
    begin
      AError := True;
      AErrorText := 'Sin asignar.';
    end;
  end;
  if not AError and ObtenerContextoActual(oContexto) then
  begin
    Cambio.Contexto := oContexto;
    Cambio.Codigo := Trim(VarToStr(ADisplayValue));
    Cambio.IdBasico := EnteroNulo;
    if Cambio.Codigo <> '' then
    begin
      if Assigned(FLookupBasicos) and FLookupBasicos.Locate(
        'ID_VA_ATB;CODIGO_ATB',
        VarArrayOf([oContexto.IdVariacion, Cambio.Codigo]),
        [loCaseInsensitive]) then
        Cambio.IdBasico := EnteroConValor(
          FLookupBasicos.FieldByName('ID_ATB').AsInteger)
      else
      begin
        AError := True;
        AErrorText := 'Sin asignar.';
      end;
    end;
    if not AError then
    begin
      FCambios.AddOrSetValue(oContexto.IdVariacion + #9 +
        oContexto.ValorAtributo, Cambio);
      if FDetalles.State in [dsEdit, dsInsert] then
        FDetalles.Cancel;
      FDetalles.Refresh;
      if Cambio.IdBasico.TieneValor then
        ADisplayValue := Cambio.IdBasico.Valor
      else
        ADisplayValue := Null;
    end;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.ElegirColor;
// Selector de color sobre el basico de la fila activa. Si la fila aun no
// tiene basico se crea al vuelo para poder asignarle un HEX.
var
  iIdBasico: Integer;
  oDialogo: TColorDialog;
  sHex: string;
  iRojo, iVerde, iAzul: Integer;
begin
  if HayDetalleActivo then
  begin
    iIdBasico := AsegurarBasicoFilaActual;
    if iIdBasico > 0 then
    begin
      oDialogo := TColorDialog.Create(nil);
      try
        oDialogo.Options := [cdFullOpen, cdAnyColor];
        sHex := FDetalles.FieldByName('HEX_ATB').AsString;
        if DescomponerHexAtributo(sHex, iRojo, iVerde, iAzul) then
          oDialogo.Color := RGB(iRojo, iVerde, iAzul)
        else
          oDialogo.Color := clWhite;
        if oDialogo.Execute then
        begin
          sHex := ComponerHexAtributo(
            GetRValue(oDialogo.Color),
            GetGValue(oDialogo.Color),
            GetBValue(oDialogo.Color));
          FGestor.ActualizarHex(iIdBasico, sHex, FUsuario);
          RefrescarTrasEdicion;
        end;
      finally
        FreeAndNil(oDialogo);
      end;
    end;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CambiarActivoColorSkus(
  const AActivo: string);
// Activa o desactiva en bloque todos los SKU del articulo que comparten el
// valor del eje de fila del SKU seleccionado.
var
  sCodigoArticulo, sColor, sInfinitivo, sParticipio: string;
  iAfectados: Integer;
  bConfirmado: Boolean;
begin
  if not ObtenerValorFilaActual(sCodigoArticulo, sColor) then
    MessageDlg_fza(SErrorSkuColorNoSeleccionado, mtInformation, [mbOK], 0)
  else
  begin
    if AActivo = 'S' then
      sInfinitivo := STextoActivarSkusColor
    else
      sInfinitivo := STextoDesactivarSkusColor;
    bConfirmado := MessageDlg_fza(
      Format(SPreguntaCambiarActivoSkusColor, [sInfinitivo, sColor]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes;
    if bConfirmado and Assigned(FCambiarActivoSkusColor) then
    begin
      iAfectados := FCambiarActivoSkusColor(
        sCodigoArticulo, sColor, AActivo);
      // Refrescamos el grid de SKU para reflejar ESACTIVO_SKU.
      if (FSkus <> nil) and FSkus.Active then
        FSkus.Refresh;
      if AActivo = 'S' then
        sParticipio := STextoSkusColorActivados
      else
        sParticipio := STextoSkusColorDesactivados;
      MessageDlg_fza(
        Format(SInfoSkusColorActualizados,
          [iAfectados, sColor, sParticipio]),
        mtInformation, [mbOK], 0);
    end;
  end;
end;

function TPresentadorAtributosBasicosArticulo.ObtenerValorFilaActual(
  out ACodigoArticulo, AValor: string): Boolean;
// El detalle ya esta master-detalleado al SKU en foco, asi que recorrerlo
// da los atributos de ese SKU (una fila CO, una TAL, ...).
var
  oMarca: TBookmark;
begin
  Result := False;
  ACodigoArticulo := '';
  AValor := '';
  if HayDetalleActivo and (Trim(FIdAtributoFila) <> '') then
  begin
    FDetalles.DisableControls;
    oMarca := FDetalles.GetBookmark;
    try
      FDetalles.First;
      while (not FDetalles.Eof) and (not Result) do
      begin
        if SameText(FDetalles.FieldByName('ID_VA_AV').AsString,
                    FIdAtributoFila) and
           (FDetalles.FieldByName('VALOR_AV').AsString <> '') then
        begin
          ACodigoArticulo :=
            FDetalles.FieldByName('CODIGO_ART_SKU').AsString;
          AValor := FDetalles.FieldByName('VALOR_AV').AsString;
          Result := True;
        end;
        if not Result then
          FDetalles.Next;
      end;
    finally
      if FDetalles.BookmarkValid(oMarca) then
        FDetalles.GotoBookmark(oMarca);
      FDetalles.FreeBookmark(oMarca);
      FDetalles.EnableControls;
    end;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.PintarCeldaHex(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var AHecho: Boolean);
var
  sHex: string;
  iRojo, iVerde, iAzul: Integer;
  oColor: TColor;
  oRecuadro: TRect;
begin
  AHecho := False;
  if AViewInfo <> nil then
  begin
    sHex := AViewInfo.GridRecord.DisplayTexts[AViewInfo.Item.Index];
    if DescomponerHexAtributo(sHex, iRojo, iVerde, iAzul) then
    begin
      oColor := RGB(iRojo, iVerde, iAzul);
      // Fondo de celda: mantiene la seleccion y la zebra del grid.
      ACanvas.FillRect(AViewInfo.Bounds, AViewInfo.Params.Color);
      oRecuadro := AViewInfo.Bounds;
      InflateRect(oRecuadro, -3, -3);
      ACanvas.Brush.Color := oColor;
      ACanvas.Pen.Color := clBlack;
      ACanvas.Rectangle(oRecuadro);
      // Etiqueta del HEX encima, en blanco o negro segun luminancia.
      ACanvas.Brush.Style := bsClear;
      if EsColorOscuroAtributo(iRojo, iVerde, iAzul) then
        ACanvas.Font.Color := clWhite
      else
        ACanvas.Font.Color := clBlack;
      ACanvas.DrawText(Trim(sHex), oRecuadro,
        cxAlignCenter or cxAlignVCenter);
      AHecho := True;
    end;
  end;
end;

end.

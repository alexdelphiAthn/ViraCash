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
  cxGraphics, cxEdit, cxDBLookupComboBox, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView,
  inLibArticulosAtributosBasicosIntf;

type
  // Activa o desactiva en bloque los SKU de un color. Devuelve las filas
  // afectadas. Lo aporta el data module; aqui solo se invoca.
  TCambiarActivoSkusColor = reference to function(
    const ACodigoArticulo, AColor, AActivo: string): Integer;

  TPresentadorAtributosBasicosArticulo = class
  private
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
    procedure MostrarFuente(var ATexto: string);
    procedure CambiarNombre(ASender: TObject);
    procedure CambiarValorNumerico(ASender: TObject);
    procedure CambiarUnidad(ASender: TObject);
    procedure CambiarDescripcion(ASender: TObject);
    procedure CambiarBasico(ASender: TObject);
    procedure PrepararListaBasicos(AProperties: TcxLookupComboBoxProperties);
    procedure AbrirDesplegableBasico;
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
  FDetalles := ADetalles;
  FLookupBasicos := ALookupBasicos;
  FSkus := ASkus;
  FGestor := AGestor;
  FUsuario := AUsuario;
  FCambiarActivoSkusColor := ACambiarActivoSkusColor;
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

procedure TPresentadorAtributosBasicosArticulo.CambiarBasico(
  ASender: TObject);
// La eleccion en el SKU es un override por articulo. Si el usuario limpia
// el lookup se guarda un bloqueo explicito con ID_ATB_AAB nulo para que no
// reaparezca un valor heredado.
var
  oContexto: TContextoAtributoBasicoSku;
  oIdBasico: TEnteroOpcional;
  vNuevo: Variant;
begin
  if ObtenerContextoActual(oContexto) then
  begin
    vNuevo := (ASender as TcxCustomEdit).EditingValue;
    if VarIsNull(vNuevo) or (VarToStr(vNuevo) = '') then
      oIdBasico := EnteroNulo
    else
      oIdBasico := EnteroConValor(Integer(vNuevo));
    FGestor.GuardarOverride(oContexto, oIdBasico);
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

procedure TPresentadorAtributosBasicosArticulo.AbrirDesplegableBasico;
// Filtramos el lookup por ID_VA_ATB para que un atributo CO solo vea
// basicos de color, uno TAL solo tallas, etc.
var
  sIdVariacion: string;
begin
  if (FLookupBasicos <> nil) and HayDetalleActivo then
  begin
    sIdVariacion := FDetalles.FieldByName('ID_VA_AV').AsString;
    if sIdVariacion = '' then
    begin
      FLookupBasicos.Filter := '';
      FLookupBasicos.Filtered := False;
    end
    else
    begin
      FLookupBasicos.Filter := 'ID_VA_ATB = ' + QuotedStr(sIdVariacion);
      FLookupBasicos.Filtered := True;
    end;
  end;
end;

procedure TPresentadorAtributosBasicosArticulo.CerrarDesplegableBasico;
// Si el filtro se queda puesto, la grilla no resuelve el CODIGO_ATB de las
// filas de otro tipo y la columna "Basico" se ve vacia.
begin
  if (FLookupBasicos <> nil) and FLookupBasicos.Filtered then
  begin
    FLookupBasicos.Filter := '';
    FLookupBasicos.Filtered := False;
  end;
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

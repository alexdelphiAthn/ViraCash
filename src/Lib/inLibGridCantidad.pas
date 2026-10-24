{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridCantidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formato de columnas de CANTIDAD en grids cx con decimales POR FILA segun  }
{    la unidad de medida de la linea. Usa OnGetDisplayText (texto por fila,    }
{    respeta el editor) + permite teclear decimales en el spin. Apoyo de       }
{    inLibUnidadesMedida para las fases de documentos.                         }
{******************************************************************************}
unit inLibGridCantidad;

interface

uses
  cxGridDBTableView, inLibUnidadesMedida;

// Vincula una columna de cantidad a su columna de unidad de medida: la celda
// mostrara los decimales que correspondan a la unidad de esa fila y el editor
// admitira decimales. AColUnidad puede ser nil (entonces decimales por
// defecto). Con AMostrarUnidad = False la columna de unidad queda siempre
// oculta (solo aporta el dato; p. ej. el modo bandas de compras, cuyo
// Tipo ya dice «Pedido - m»). Llamarla otra vez sobre la misma columna
// reconfigura el formateador existente en lugar de encadenar otro.
procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn;
  AUnidades: TUnidadesMedida; AMostrarUnidad: Boolean = True);

// Expresion regular de una cantidad con como maximo ADecimales decimales
// (separador regional): '-?\d*(,\d{0,2})?'. Con 0, solo enteros.
function MascaraCantidadDecimales(ADecimales: Integer): string;

// VincularCantidadGrid sobre varias columnas con la misma unidad (tallas
// del pivote, totales de unidades...). Ignora las columnas nil.
procedure VincularCantidadesGrid(
  const AColumnas: array of TcxGridDBColumn;
  AColUnidad: TcxGridDBColumn; AUnidades: TUnidadesMedida;
  AMostrarUnidad: Boolean = True);

// Suma el contenido publicado por la rejilla y sustituye la fila en edición
// por su buffer actual, sin crear cursores ni mover el dataset.
function ImporteCantidadesGrid(AVista: TcxGridDBTableView;
  const ACampoCantidad, ACampoPrecio: string): Currency;

implementation

uses
  System.Classes, System.SysUtils, System.Variants, System.Math, Data.DB,
  Vcl.Controls, Vcl.ExtCtrls, cxEdit, cxGridCustomTableView,
  cxGridTableView, cxSpinEdit, cxMaskEdit,
  inLibMsgArticulos, inLibTipoCantidad, inLibRedondeo,
  inLibSeparadorDecimalTeclado;

const
  MASCARA_CANTIDAD_SIN_UNIDAD = '0.###';

type
  TVisibilidadTipoCantidad = class;

  TEnlaceTipoCantidad = class(TDataLink)
  private
    FGestor: TVisibilidadTipoCantidad;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure RecordChanged(Field: TField); override;
  end;

  TVisibilidadTipoCantidad = class(TComponent)
  private
    FColUnidad: TcxGridDBColumn;
    FEnlace: TEnlaceTipoCantidad;
    FTimer: TTimer;
    procedure Actualizar;
    procedure Programar;
    procedure TimerTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Configurar(AColUnidad: TcxGridDBColumn);
  end;

  TFormatoCantidadGrid = class(TComponent)
  private
    FColCantidad: TcxGridDBColumn;
    FColUnidad: TcxGridDBColumn;
    FUnidades: TUnidadesMedida;
    // Manejador que ya tenia la columna (p. ej. el del formulario): se
    // llama despues del formato para que pueda sustituir el texto.
    FAnterior: TcxGridGetDisplayTextEvent;
    FAnteriorEdicion: TcxGridGetPropertiesEvent;
    // Copia propia de las propiedades del editor con el OnValidate que
    // redondea; las de la columna pueden ser las compartidas por defecto.
    FPropiedadesEdicion: TcxCustomEditProperties;
    FValidarAnterior: TcxEditValidateEvent;
    function UnidadFilaEnFoco: string;
    procedure GetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure GetPropertiesForEdit(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure ValidarCantidad(Sender: TObject;
      var DisplayValue: TcxEditValue; var ErrorText: TCaption;
      var Error: Boolean);
    procedure LimitarDecimalesEditor(AProperties: TcxCustomEditProperties);
  public
    destructor Destroy; override;
  end;

function ExcedeDecimales(AValor: Double; ADecimales: Integer): Boolean;
begin
  Result := Abs(RedondearDecimales(AValor, ADecimales) - AValor) >
    Power(10, -ADecimales - 3);
end;

procedure TEnlaceTipoCantidad.ActiveChanged;
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

procedure TEnlaceTipoCantidad.DataSetChanged;
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

procedure TEnlaceTipoCantidad.RecordChanged(Field: TField);
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

constructor TVisibilidadTipoCantidad.Create(AOwner: TComponent);
begin
  inherited;
  FEnlace := TEnlaceTipoCantidad.Create;
  FEnlace.FGestor := Self;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 1;
  FTimer.OnTimer := TimerTimer;
end;

destructor TVisibilidadTipoCantidad.Destroy;
begin
  FTimer.Enabled := False;
  FEnlace.DataSource := nil;
  FEnlace.FGestor := nil;
  FreeAndNil(FEnlace);
  inherited;
end;

procedure TVisibilidadTipoCantidad.Configurar(
  AColUnidad: TcxGridDBColumn);
begin
  FColUnidad := AColUnidad;
  if (FColUnidad <> nil) and
     (FColUnidad.GridView is TcxGridDBTableView) then
    FEnlace.DataSource := TcxGridDBTableView(FColUnidad.GridView).
      DataController.DataSource
  else
    FEnlace.DataSource := nil;
  if FColUnidad <> nil then
  begin
    FColUnidad.Visible := False;
    FColUnidad.VisibleForCustomization := False;
  end;
  Programar;
end;

procedure TVisibilidadTipoCantidad.Programar;
begin
  if FTimer <> nil then
  begin
    FTimer.Enabled := False;
    FTimer.Enabled := True;
  end;
end;

procedure TVisibilidadTipoCantidad.TimerTimer(Sender: TObject);
begin
  FTimer.Enabled := False;
  Actualizar;
end;

procedure TVisibilidadTipoCantidad.Actualizar;
var
  Vista: TcxGridDBTableView;
  i: Integer;
  sUnidad: string;
  vUnidad: Variant;
  bEspecial: Boolean;
begin
  bEspecial := False;
  Vista := nil;
  if (FColUnidad <> nil) and
     (FColUnidad.GridView is TcxGridDBTableView) then
    Vista := TcxGridDBTableView(FColUnidad.GridView);
  if Vista <> nil then
  begin
    i := 0;
    while (not bEspecial) and
          (i < Vista.DataController.RecordCount) do
    begin
      vUnidad := Vista.DataController.Values[i, FColUnidad.Index];
      sUnidad := '';
      if not (VarIsNull(vUnidad) or VarIsEmpty(vUnidad)) then
        sUnidad := VarToStr(vUnidad);
      bEspecial := not EsTipoCantidadPredeterminado(sUnidad);
      Inc(i);
    end;
  end;
  if FColUnidad <> nil then
  begin
    FColUnidad.Visible := bEspecial;
    FColUnidad.VisibleForCustomization := bEspecial;
    if bEspecial then
    begin
      // FZ-ISSUE-203: sin titulo asignado, Caption devuelve el nombre
      // del campo (TIPO_CANTIDAD_ARTICULO_*), no una cadena vacia.
      if (Trim(FColUnidad.Caption) = '') or
         SameText(FColUnidad.Caption,
           FColUnidad.DataBinding.FieldName) or
         ((FColUnidad.DataBinding.Field <> nil) and
          SameText(FColUnidad.Caption,
            FColUnidad.DataBinding.Field.DisplayName)) then
        FColUnidad.Caption := SCaptionColTipoCantidad;
      if FColUnidad.Width < 80 then
        FColUnidad.Width := 90;
    end;
  end;
end;

// FZ-ISSUE-259: la copia del editor no es un componente y no se libera con
// el formateador. Viva, sigue registrada en cxFormatController con su
// propietario ya destruido y el siguiente cambio de idioma (FormCreate de
// cualquier pantalla) da un Access violation.
destructor TFormatoCantidadGrid.Destroy;
begin
  FreeAndNil(FPropiedadesEdicion);
  inherited;
end;

procedure TFormatoCantidadGrid.GetDisplayText(Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord; var AText: string);
var
  vVal: Variant;
  vUni: Variant;
  dVal: Double;
  sUni: string;
begin
  // DevExpress pide el texto con ARecord = nil cuando el editor no está
  // ligado a un registro: sin registro no hay valores que formatear.
  vVal := Null;
  if ARecord <> nil then
    vVal := ARecord.Values[FColCantidad.Index];
  // Celda vacia: dejamos el texto por defecto (no formateamos null).
  if not (VarIsNull(vVal) or VarIsEmpty(vVal)) then
  begin
    dVal := vVal;
    sUni := '';
    if FColUnidad <> nil then
    begin
      vUni := ARecord.Values[FColUnidad.Index];
      if not (VarIsNull(vUni) or VarIsEmpty(vUni)) then
        sUni := VarToStr(vUni);
    end;
    // Unidad desconocida (linea antigua sin unidad, tabla sin cargar):
    // se muestran los decimales que tenga en vez de ocultarlos.
    if Assigned(FUnidades) and (FUnidades.Info(sUni) <> nil) then
      AText := FUnidades.Formatear(dVal, sUni)
    else if Assigned(FUnidades) then
      AText := FormatFloat(MASCARA_CANTIDAD_SIN_UNIDAD, dVal);
  end;
  if Assigned(FAnterior) then
    FAnterior(Sender, ARecord, AText);
end;

function TFormatoCantidadGrid.UnidadFilaEnFoco: string;
var
  Registro: TcxCustomGridRecord;
  vUni: Variant;
begin
  Result := '';
  Registro := nil;
  if (FColUnidad <> nil) and
     (FColCantidad.GridView is TcxCustomGridTableView) then
    Registro := TcxCustomGridTableView(FColCantidad.GridView).
      Controller.FocusedRecord;
  if Registro <> nil then
  begin
    vUni := Registro.Values[FColUnidad.Index];
    if not (VarIsNull(vUni) or VarIsEmpty(vUni)) then
      Result := VarToStr(vUni);
  end;
end;

procedure TFormatoCantidadGrid.GetPropertiesForEdit(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
begin
  if Assigned(FAnteriorEdicion) then
    FAnteriorEdicion(Sender, ARecord, AProperties);
  if (AProperties <> nil) and (AProperties <> FPropiedadesEdicion) then
  begin
    if (FPropiedadesEdicion = nil) or
       (FPropiedadesEdicion.ClassType <> AProperties.ClassType) then
    begin
      FreeAndNil(FPropiedadesEdicion);
      FPropiedadesEdicion := TcxCustomEditPropertiesClass(
        AProperties.ClassType).Create(Self);
    end;
    // Se copia en cada edicion: ReadOnly, decimales... pueden cambiar.
    FPropiedadesEdicion.Assign(AProperties);
    FValidarAnterior := AProperties.OnValidate;
    FPropiedadesEdicion.OnValidate := ValidarCantidad;
    LimitarDecimalesEditor(FPropiedadesEdicion);
    AProperties := FPropiedadesEdicion;
  end;
end;

function MascaraCantidadDecimales(ADecimales: Integer): string;
begin
  Result := '-?\d*';
  if ADecimales > 0 then
    Result := Result + '(\' + FormatSettings.DecimalSeparator +
      '\d{0,' + IntToStr(ADecimales) + '})?';
end;

// FZ-ISSUE-205 (requisito del usuario): con unidad conocida, el editor de
// mascara no deja teclear mas decimales de los que admite la unidad de la
// fila. Solo si la columna no traia ya su propia mascara.
procedure TFormatoCantidadGrid.LimitarDecimalesEditor(
  AProperties: TcxCustomEditProperties);
var
  Info: TUnidadInfo;
  Mascara: TcxCustomMaskEditProperties;
begin
  Info := nil;
  if Assigned(FUnidades) then
    Info := FUnidades.Info(UnidadFilaEnFoco);
  if (Info <> nil) and (AProperties is TcxCustomMaskEditProperties) and
     (TcxCustomMaskEditProperties(AProperties).EditMask = '') then
  begin
    Mascara := TcxCustomMaskEditProperties(AProperties);
    Mascara.MaskKind := emkRegExpr;
    Mascara.EditMask := MascaraCantidadDecimales(Info.Decimales);
  end;
end;

// FZ-ISSUE-205: una cantidad con mas decimales de los que admite la unidad
// de la fila se rechaza al aceptar la celda (pegados, lectores, editores
// sin mascara), en vez de redondearla en silencio. Solo con unidades
// conocidas: sin la tabla de unidades no se valida.
procedure TFormatoCantidadGrid.ValidarCantidad(Sender: TObject;
  var DisplayValue: TcxEditValue; var ErrorText: TCaption;
  var Error: Boolean);
var
  Info: TUnidadInfo;
  rValor: Double;
  sNormalizado: string;
begin
  // FZ-ISSUE-223: lo pegado o leido llega como texto; «3.5» es 3,5 y un
  // texto con dos separadores se rechaza en vez de multiplicar la
  // cantidad. Antes que el validador previo, para que lo vea normalizado.
  if VarIsStr(DisplayValue) then
  begin
    if NormalizarTextoDecimal(VarToStr(DisplayValue), sNormalizado) then
      DisplayValue := sNormalizado
    else
    begin
      Error := True;
      ErrorText := Format(SErrorCantidadSeparadorAmbiguo,
        [VarToStr(DisplayValue)]);
    end;
  end;
  if (not Error) and Assigned(FValidarAnterior) then
    FValidarAnterior(Sender, DisplayValue, ErrorText, Error);
  Info := nil;
  if (not Error) and Assigned(FUnidades) then
    Info := FUnidades.Info(UnidadFilaEnFoco);
  if (Info <> nil) and
     not (VarIsNull(DisplayValue) or VarIsEmpty(DisplayValue)) and
     TryStrToFloat(Trim(VarToStr(DisplayValue)), rValor) and
     ExcedeDecimales(rValor, Info.Decimales) then
  begin
    Error := True;
    if Info.Decimales <= 0 then
      ErrorText := Format(SErrorCantidadSinDecimalesUnidad, [Info.Codigo])
    else
      ErrorText := Format(SErrorCantidadDecimalesUnidad,
        [Info.Codigo, Info.Decimales]);
  end;
end;

procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn;
  AUnidades: TUnidadesMedida; AMostrarUnidad: Boolean);
var
  i: Integer;
  oFmt: TFormatoCantidadGrid;
  oVisibilidad: TVisibilidadTipoCantidad;
begin
  if AColCantidad <> nil then
  begin
    // El spin que hoy solo admite enteros pasa a admitir decimales.
    if (AColCantidad.Properties <> nil) and
       (AColCantidad.Properties is TcxSpinEditProperties) then
      TcxSpinEditProperties(AColCantidad.Properties).ValueType := vtFloat;
    oFmt := nil;
    i := 0;
    while (oFmt = nil) and (i < AColCantidad.ComponentCount) do
    begin
      if AColCantidad.Components[i] is TFormatoCantidadGrid then
        oFmt := TFormatoCantidadGrid(AColCantidad.Components[i]);
      Inc(i);
    end;
    if oFmt = nil then
    begin
      // El formateador vive ligado a la columna (se libera con ella).
      oFmt := TFormatoCantidadGrid.Create(AColCantidad);
      oFmt.FColCantidad := AColCantidad;
      oFmt.FAnterior := AColCantidad.OnGetDisplayText;
      AColCantidad.OnGetDisplayText := oFmt.GetDisplayText;
      oFmt.FAnteriorEdicion := AColCantidad.OnGetPropertiesForEdit;
      AColCantidad.OnGetPropertiesForEdit := oFmt.GetPropertiesForEdit;
    end;
    oFmt.FColUnidad := AColUnidad;
    oFmt.FUnidades := AUnidades;
  end;
  if (AColUnidad <> nil) and not AMostrarUnidad then
  begin
    AColUnidad.Visible := False;
    AColUnidad.VisibleForCustomization := False;
  end
  else if AColUnidad <> nil then
  begin
    oVisibilidad := nil;
    i := 0;
    while (oVisibilidad = nil) and (i < AColUnidad.ComponentCount) do
    begin
      if AColUnidad.Components[i] is TVisibilidadTipoCantidad then
        oVisibilidad := TVisibilidadTipoCantidad(
          AColUnidad.Components[i]);
      Inc(i);
    end;
    if oVisibilidad = nil then
      oVisibilidad := TVisibilidadTipoCantidad.Create(AColUnidad);
    oVisibilidad.Configurar(AColUnidad);
  end;
end;

procedure VincularCantidadesGrid(
  const AColumnas: array of TcxGridDBColumn;
  AColUnidad: TcxGridDBColumn; AUnidades: TUnidadesMedida;
  AMostrarUnidad: Boolean);
var
  i: Integer;
begin
  // La columna de unidad se configura aunque no haya columnas de cantidad
  // (FZ-ISSUE-236: en bandas quedaba visible con el nombre del campo).
  VincularCantidadGrid(nil, AColUnidad, AUnidades, AMostrarUnidad);
  for i := Low(AColumnas) to High(AColumnas) do
  begin
    if AColumnas[i] <> nil then
      VincularCantidadGrid(AColumnas[i], AColUnidad, AUnidades,
        AMostrarUnidad);
  end;
end;

function ImporteCantidadesGrid(AVista: TcxGridDBTableView;
  const ACampoCantidad, ACampoPrecio: string): Currency;
var
  oDatos: TDataSet;
  oCantidad, oPrecio: TcxGridDBColumn;
  iRegistro, iEditado: Integer;
  vCantidad, vPrecio: Variant;
begin
  Result := 0;
  oDatos := AVista.DataController.DataSet;
  oCantidad := AVista.GetColumnByFieldName(ACampoCantidad);
  oPrecio := AVista.GetColumnByFieldName(ACampoPrecio);
  if Assigned(oDatos) and oDatos.Active and Assigned(oCantidad) and
     Assigned(oPrecio) then
  begin
    iEditado := -1;
    if oDatos.State in dsEditModes then
      iEditado := AVista.DataController.FocusedRecordIndex;
    for iRegistro := 0 to AVista.DataController.RecordCount - 1 do
    begin
      if iRegistro <> iEditado then
      begin
        vCantidad := AVista.DataController.Values[iRegistro, oCantidad.Index];
        vPrecio := AVista.DataController.Values[iRegistro, oPrecio.Index];
        if not VarIsNull(vCantidad) and not VarIsEmpty(vCantidad) and
           not VarIsNull(vPrecio) and not VarIsEmpty(vPrecio) then
          Result := Result + Double(vCantidad) * Currency(vPrecio);
      end;
    end;
    if oDatos.State in dsEditModes then
      Result := Result + oDatos.FieldByName(ACampoCantidad).AsFloat *
        oDatos.FieldByName(ACampoPrecio).AsCurrency;
  end;
end;

end.

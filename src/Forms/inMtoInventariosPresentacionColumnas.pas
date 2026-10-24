{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosPresentacionColumnas                          }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Aplica al grid de lineas el plan de columnas de atributo decidido en      }
{    inLibInventariosPresentacion. Recibe la vista y las columnas, nunca el    }
{    formulario, y consulta la definicion de atributos por su puerto.          }
{******************************************************************************}
unit inMtoInventariosPresentacionColumnas;

interface

uses
  inLibMsgArticulos,
  Vcl.Graphics,
  Vcl.Controls,
  Data.DB,
  cxEdit,
  cxGridTableView,
  cxGridDBTableView,
  inLibInventariosPresentacionIntf,
  inLibUnidadesMedida;

type
  TColumnasSkuInventario =
    array[1..MAX_ATRIBUTOS_INVENTARIO] of TcxGridDBColumn;

  TGestorColumnasAtributosInventario = class
  private
    FVista: TcxGridDBTableView;
    FColumnasSku: TColumnasSkuInventario;
    FColumnaArticulo: TcxGridDBColumn;
    FColumnaUnidad: TcxGridDBColumn;
    FLineas: TDataSet;
    FLookup: IAtributosInventarioLookup;
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FMostrarAtributos: Boolean;
    FContratoConstruido: Boolean;
    FVistaAplicada: Boolean;
    function SituacionActual(
      const ACodigoArticuloPadre: string): TSituacionColumnasInventario;
    procedure AplicarPlan(
      const APlan: TPlanColumnasAtributosInventario);
    procedure OcultarTodas;
    procedure AplicarColumnasDelArticulo(
      const ACodigoArticulo: string);
    procedure AplicarColumnasDeLaVista;
  public
    constructor Create(
      AVista: TcxGridDBTableView;
      const AColumnasSku: TColumnasSkuInventario;
      AColumnaArticulo, AColumnaUnidad: TcxGridDBColumn);
    procedure EstablecerOrigen(
      ALineas: TDataSet;
      const ALookup: IAtributosInventarioLookup);
    procedure Actualizar(const ACodigoArticuloPadre: string);
    procedure AplicarModoEntrada(AModoAtributos: Boolean);
    procedure AjustarAnchosAtributos(AFuente: TFont);
    procedure ActualizarCabecerasContrato;
    function ColumnaEntradaActiva: TcxGridDBColumn;
    function ColumnaSkuPorTag(ANumero: Integer): TcxGridDBColumn;
    function NumeroAtributosArticulo(
      const ACodigoArticulo: string): Integer;
    property NumAtributosActual: Integer read FNumAtributosActual;
    property MostrarAtributos: Boolean read FMostrarAtributos
      write FMostrarAtributos;
    property ContratoConstruido: Boolean read FContratoConstruido
      write FContratoConstruido;
    property VistaAplicada: Boolean read FVistaAplicada
      write FVistaAplicada;
    property UltimoArticuloPadre: string read FUltimoArticuloPadre
      write FUltimoArticuloPadre;
  end;

// Recrea en runtime las columnas propias del documento que mueren en el
// ClearItems del contrato de entrada. Con AConLotes (algún modo de
// trazabilidad activo, F-LOTEC-014) añade lote y caducidad, editables.
procedure CrearColumnasDocumentoInventario(
  AVista: TcxGridDBTableView;
  AValidarEdicion: TcxEditValidateEvent;
  AUnidades: TUnidadesMedida;
  AConLotes: Boolean = False);

implementation

uses
  System.SysUtils,
  System.Classes,
  cxGraphics,
  dxCoreGraphics,
  cxCalendar,
  cxCheckBox,
  cxCurrencyEdit,
  cxTextEdit,
  inLibInventariosPresentacion,
  inLibGridCantidad;

const
  CAMPO_ARTICULO_LINEA = 'CODIGO_ART_INVLIN';
  CAMPO_NUM_ATRIBUTOS_LINEA = 'NUM_ATRIBUTOS_REQ_INV_LINEA';

function CrearColumnaDocumentoInventario(
  AVista: TcxGridDBTableView;
  const ACaption, ACampo: string;
  AAncho: Integer; AEditable: Boolean): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn as TcxGridDBColumn;
  Result.Caption := ACaption;
  Result.DataBinding.FieldName := ACampo;
  Result.Width := AAncho;
  Result.Options.Editing := AEditable;
  Result.HeaderAlignmentHorz := taRightJustify;
end;

// Importes en euros con dos decimales, como en albaranes y facturas. El
// formato de edicion va sin simbolo ni separador de miles porque la
// validacion de la linea convierte el texto con StrToCurrDef.
procedure ConfigurarColumnaEuros(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat :=
    '#,##0.00 ' + #8364;
  TcxCurrencyEditProperties(AColumna.Properties).EditFormat := '0.00';
  TcxCurrencyEditProperties(AColumna.Properties).DecimalPlaces := 2;
end;

procedure CrearColumnasLoteInventario(AVista: TcxGridDBTableView);
var
  oCaducidad: TcxGridDBColumn;
  oLote: TcxGridDBColumn;
begin
  oLote := CrearColumnaDocumentoInventario(AVista,
    SCaptionLoteExcelInventario, 'LOTE_INVLIN', 90, True);
  oLote.HeaderAlignmentHorz := taLeftJustify;
  oCaducidad := CrearColumnaDocumentoInventario(AVista,
    SCaptionCaducidadExcelInventario, 'FECHA_CADUCIDAD_INVLIN', 90, True);
  oCaducidad.PropertiesClass := TcxDateEditProperties;
end;

procedure CrearColumnasDocumentoInventario(
  AVista: TcxGridDBTableView;
  AValidarEdicion: TcxEditValidateEvent;
  AUnidades: TUnidadesMedida;
  AConLotes: Boolean);
var
  oDescripcion: TcxGridDBColumn;
  oPmp: TcxGridDBColumn;
  oPmpCorregido: TcxGridDBColumn;
  oRecuento: TcxGridDBColumn;
  oTeorico: TcxGridDBColumn;
  oDiferencia: TcxGridDBColumn;
  oUnidad: TcxGridDBColumn;
  oHoraRecuento: TcxGridDBColumn;
begin
  oDescripcion := CrearColumnaDocumentoInventario(AVista,
    SCaptionDescripcionColumnaInventario, 'DESCRIPCION_ARTICULO_INVLIN',
      200, False);
  oDescripcion.HeaderAlignmentHorz := taLeftJustify;
  if AConLotes then
    CrearColumnasLoteInventario(AVista);
  oTeorico := CrearColumnaDocumentoInventario(AVista,
    SCaptionUnidadesTeoricasInventario, 'CANTIDAD_TEORICA_INVLIN', 90, False);
  oRecuento := CrearColumnaDocumentoInventario(AVista,
    SCaptionRecuentoInventario, 'CANTIDAD_FISICA_INVLIN', 90, True);
  oRecuento.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(oRecuento.Properties).OnValidate :=
    AValidarEdicion;
  ConfigurarColumnaEuros(CrearColumnaDocumentoInventario(AVista,
    SCaptionPmpActualInventario, 'PRECIO_MEDIO_INVLIN', 85, False));
  oPmp := CrearColumnaDocumentoInventario(AVista,
    SCaptionPmpNuevoInventario, 'PRECIO_MEDIO_NUEVO_INVLIN', 85, True);
  ConfigurarColumnaEuros(oPmp);
  TcxCurrencyEditProperties(oPmp.Properties).OnValidate := AValidarEdicion;
  oPmpCorregido := CrearColumnaDocumentoInventario(AVista,
    SCaptionPmpManualInventario, 'ESPRECIO_MEDIO_CORREGIDO_INVLIN', 75, True);
  oPmpCorregido.PropertiesClass := TcxCheckBoxProperties;
  TcxCheckBoxProperties(oPmpCorregido.Properties).ValueChecked := 'S';
  TcxCheckBoxProperties(oPmpCorregido.Properties).ValueUnchecked := 'N';
  oDiferencia := CrearColumnaDocumentoInventario(AVista,
    SCaptionDiferenciaUnidadesInventario, 'CANTIDAD_DIFERENCIA_INVLIN', 80,
      False);
  ConfigurarColumnaEuros(CrearColumnaDocumentoInventario(AVista,
    SCaptionDiferenciaCosteInventario, 'TOTAL_COSTE_DIFERENCIA_INVLIN', 90,
      False));
  CrearColumnaDocumentoInventario(AVista,
    SCaptionUnidadesRegularizadasInventario, 'UDS_REGULARIZADAS', 80, False);
  // FZ-ISSUE-423: nace con la fecha de la cabecera y se puede cambiar,
  // con fecha y hora, en cada línea.
  oHoraRecuento := CrearColumnaDocumentoInventario(AVista,
    SCaptionHoraRecuentoInventario, 'FECHA_RECUENTO_INVLIN', 140, True);
  oHoraRecuento.PropertiesClass := TcxDateEditProperties;
  TcxDateEditProperties(oHoraRecuento.Properties).Kind := ckDateTime;
  // FZ-ISSUE-244: recuento, teorico y diferencia con los decimales de la
  // unidad del articulo; el recuento rechaza decimales de mas (182,425 m).
  oUnidad := CrearColumnaDocumentoInventario(AVista, '',
    'TIPO_CANTIDAD_INV_LINEA', 60, False);
  VincularCantidadesGrid([oRecuento, oTeorico, oDiferencia], oUnidad,
    AUnidades, False);
end;

constructor TGestorColumnasAtributosInventario.Create(
  AVista: TcxGridDBTableView;
  const AColumnasSku: TColumnasSkuInventario;
  AColumnaArticulo, AColumnaUnidad: TcxGridDBColumn);
begin
  inherited Create;
  FVista := AVista;
  FColumnasSku := AColumnasSku;
  FColumnaArticulo := AColumnaArticulo;
  FColumnaUnidad := AColumnaUnidad;
  FNumAtributosActual := 0;
  FUltimoArticuloPadre := '';
  FMostrarAtributos := False;
  FContratoConstruido := False;
  FVistaAplicada := False;
end;

procedure TGestorColumnasAtributosInventario.EstablecerOrigen(
  ALineas: TDataSet;
  const ALookup: IAtributosInventarioLookup);
begin
  FLineas := ALineas;
  FLookup := ALookup;
end;

function TGestorColumnasAtributosInventario.ColumnaSkuPorTag(
  ANumero: Integer): TcxGridDBColumn;
var
  iColumna: Integer;
begin
  Result := nil;
  if (ANumero >= 1) and (ANumero <= MAX_ATRIBUTOS_INVENTARIO) then
  begin
    if FContratoConstruido then
    begin
      for iColumna := 0 to FVista.ColumnCount - 1 do
        if FVista.Columns[iColumna].Tag = ANumero then
          Result := FVista.Columns[iColumna];
    end
    else
      Result := FColumnasSku[ANumero];
  end;
end;

function TGestorColumnasAtributosInventario.ColumnaEntradaActiva:
  TcxGridDBColumn;
begin
  // Con el contrato construido estas columnas del dfm estan liberadas.
  Result := nil;
  if (not FContratoConstruido) and FMostrarAtributos then
    Result := FColumnaArticulo
  else if not FContratoConstruido then
    Result := FColumnaUnidad;
end;

function TGestorColumnasAtributosInventario.NumeroAtributosArticulo(
  const ACodigoArticulo: string): Integer;
begin
  Result := 0;
  if Assigned(FLookup) and (Trim(ACodigoArticulo) <> '') then
    Result := Length(FLookup.NombresAtributosArticulo(ACodigoArticulo));
end;

function TGestorColumnasAtributosInventario.SituacionActual(
  const ACodigoArticuloPadre: string): TSituacionColumnasInventario;
begin
  Result.ContratoConstruido := FContratoConstruido;
  Result.MostrarAtributos := FMostrarAtributos;
  Result.HayOrigenDeDatos := FLineas <> nil;
  Result.LineasEnEdicion := (FLineas <> nil) and FLineas.Active and
    (FLineas.State in [dsEdit, dsInsert]);
  Result.MismoArticuloPadre :=
    SameText(ACodigoArticuloPadre, FUltimoArticuloPadre);
  Result.VistaAplicada := FVistaAplicada;
end;

procedure TGestorColumnasAtributosInventario.AplicarPlan(
  const APlan: TPlanColumnasAtributosInventario);
var
  iColumna: Integer;
  oColumna: TcxGridDBColumn;
begin
  FVista.BeginUpdate;
  try
    for iColumna := 1 to MAX_ATRIBUTOS_INVENTARIO do
    begin
      oColumna := ColumnaSkuPorTag(iColumna);
      if oColumna <> nil then
      begin
        if FContratoConstruido then
        begin
          // El contrato conserva visibilidad y edicion de sus columnas.
          if APlan[iColumna].Visible then
            oColumna.Caption := APlan[iColumna].Caption;
        end
        else
        begin
          oColumna.Caption := APlan[iColumna].Caption;
          oColumna.Visible := APlan[iColumna].Visible;
          oColumna.Options.Editing := APlan[iColumna].Editable;
        end;
      end;
    end;
  finally
    FVista.EndUpdate;
  end;
end;

procedure TGestorColumnasAtributosInventario.OcultarTodas;
var
  SinNombres: TArray<string>;
begin
  if FVista <> nil then
  begin
    SetLength(SinNombres, 0);
    AplicarPlan(PlanColumnasAtributosInventario(SinNombres, 0));
    // En modo normal la entrada es la columna unificada SKU/Articulo.
    AplicarModoEntrada(False);
  end;
end;

procedure TGestorColumnasAtributosInventario.AplicarColumnasDelArticulo(
  const ACodigoArticulo: string);
var
  Nombres: TArray<string>;
begin
  SetLength(Nombres, 0);
  if Assigned(FLookup) and (Trim(ACodigoArticulo) <> '') then
    Nombres := FLookup.NombresAtributosArticulo(ACodigoArticulo);
  FNumAtributosActual := Length(Nombres);
  if (FLineas <> nil) and FLineas.Active and
     (FLineas.State in [dsEdit, dsInsert]) then
    FLineas.FieldByName(CAMPO_NUM_ATRIBUTOS_LINEA).AsInteger :=
      FNumAtributosActual;
  AplicarPlan(PlanColumnasAtributosInventario(
    Nombres, Length(Nombres)));
  AplicarModoEntrada(True);
end;

procedure TGestorColumnasAtributosInventario.AplicarColumnasDeLaVista;
var
  Marca: TBookmark;
  iMaximo: Integer;
  iNumero: Integer;
  sArticuloRepresentativo: string;
  Nombres: TArray<string>;
begin
  // Sin lineas abiertas no hay nada que recalcular: el plan anterior se
  // conserva tal cual, igual que hacia la pantalla.
  if (FLineas <> nil) and FLineas.Active then
  begin
    // 1. Numero maximo de atributos del inventario y articulo que lo
    //    alcanza: de el se toman los nombres en su ORDEN_VISUAL.
    iMaximo := 0;
    sArticuloRepresentativo := '';
    if not FLineas.IsEmpty then
    begin
      Marca := FLineas.GetBookmark;
      FLineas.DisableControls;
      try
        FLineas.First;
        while not FLineas.Eof do
        begin
          iNumero :=
            FLineas.FieldByName(CAMPO_NUM_ATRIBUTOS_LINEA).AsInteger;
          if iNumero > iMaximo then
          begin
            iMaximo := iNumero;
            sArticuloRepresentativo :=
              FLineas.FieldByName(CAMPO_ARTICULO_LINEA).AsString;
          end;
          FLineas.Next;
        end;
      finally
        if FLineas.BookmarkValid(Marca) then
          FLineas.GotoBookmark(Marca);
        FLineas.FreeBookmark(Marca);
        FLineas.EnableControls;
      end;
    end;
    if iMaximo > MAX_ATRIBUTOS_INVENTARIO then
      iMaximo := MAX_ATRIBUTOS_INVENTARIO;
    FNumAtributosActual := iMaximo;
    // 2. Nombres (Talla, Color...) del articulo representativo.
    SetLength(Nombres, 0);
    if Assigned(FLookup) and (iMaximo > 0) and
       (sArticuloRepresentativo <> '') then
      Nombres := FLookup.NombresAtributosArticulo(
        sArticuloRepresentativo);
    // 3. SKU1..iMaximo visibles con su nombre; el resto, ocultas.
    AplicarPlan(PlanColumnasAtributosInventario(Nombres, iMaximo));
  end;
end;

procedure TGestorColumnasAtributosInventario.ActualizarCabecerasContrato;
begin
  // ClearItems libera las columnas del DFM: buscar las nuevas por Tag.
  if FContratoConstruido and FMostrarAtributos and
     (FLineas <> nil) and FLineas.Active and
     (FLineas.State = dsBrowse) then
    AplicarColumnasDeLaVista;
end;

procedure TGestorColumnasAtributosInventario.Actualizar(
  const ACodigoArticuloPadre: string);
var
  Accion: TAccionColumnasInventario;
begin
  Accion := DecidirAccionColumnasInventario(
    SituacionActual(ACodigoArticuloPadre));
  case Accion of
    aciOcultarTodas:
      begin
        // Sin atributos visibles el ultimo padre se memoriza igual; sin
        // origen de datos no hay nada que memorizar.
        if FMostrarAtributos then
          OcultarTodas
        else
        begin
          FNumAtributosActual := 0;
          FUltimoArticuloPadre := ACodigoArticuloPadre;
          OcultarTodas;
        end;
      end;
    aciColumnasDelArticulo:
      begin
        FUltimoArticuloPadre := ACodigoArticuloPadre;
        AplicarColumnasDelArticulo(ACodigoArticuloPadre);
      end;
    aciColumnasDeLaVista:
      begin
        FUltimoArticuloPadre := ACodigoArticuloPadre;
        AplicarColumnasDeLaVista;
        FVistaAplicada := True;
        AplicarModoEntrada(True);
      end;
    aciSoloModoEntrada:
      begin
        FUltimoArticuloPadre := ACodigoArticuloPadre;
        AplicarModoEntrada(True);
      end;
  end;
end;

procedure TGestorColumnasAtributosInventario.AplicarModoEntrada(
  AModoAtributos: Boolean);
begin
  // Contrato activo: la entrada es del contrato; columnas dfm muertas.
  if (not FContratoConstruido) and
     Assigned(FColumnaArticulo) and Assigned(FColumnaUnidad) then
  begin
    FVista.BeginUpdate;
    try
      if AModoAtributos then
      begin
        // Atributos en columna: la entrada es la columna Articulo y la
        // unificada SKU/Articulo se oculta.
        FColumnaArticulo.Visible := True;
        FColumnaArticulo.Options.Editing := True;
        FColumnaUnidad.Visible := False;
      end
      else
      begin
        // Modo normal: una unica columna de entrada, la unificada.
        FColumnaUnidad.Visible := True;
        FColumnaArticulo.Visible := False;
      end;
    finally
      FVista.EndUpdate;
    end;
  end;
end;

procedure TGestorColumnasAtributosInventario.AjustarAnchosAtributos(
  AFuente: TFont);
var
  Marca: TBookmark;
  iAtributo: Integer;
  iColumna: Integer;
  iAncho: Integer;
  AnchoMaximo: array[1..MAX_ATRIBUTOS_INVENTARIO] of Integer;
  oColumna: TcxGridColumn;
begin
  // Ancho segun el VALOR mas largo cargado mas el margen del swatch:
  // AZUL_CIELO quedaba ilegible con el ancho por defecto. Solo crece,
  // para no pisar anchos tocados a mano.
  if (FLineas <> nil) and FLineas.Active and (not FLineas.IsEmpty) then
  begin
    for iAtributo := 1 to MAX_ATRIBUTOS_INVENTARIO do
      AnchoMaximo[iAtributo] := 0;
    Marca := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        for iAtributo := 1 to MAX_ATRIBUTOS_INVENTARIO do
        begin
          iAncho := cxTextWidth(AFuente, Trim(FLineas.FieldByName(
            'ATTR' + IntToStr(iAtributo) + '_VALOR').AsString));
          if iAncho > AnchoMaximo[iAtributo] then
            AnchoMaximo[iAtributo] := iAncho;
        end;
        FLineas.Next;
      end;
      if FLineas.BookmarkValid(Marca) then
        FLineas.GotoBookmark(Marca);
    finally
      FLineas.EnableControls;
      FLineas.FreeBookmark(Marca);
    end;
    for iColumna := 0 to FVista.ColumnCount - 1 do
    begin
      oColumna := FVista.Columns[iColumna];
      if (oColumna.Tag >= 1) and
         (oColumna.Tag <= MAX_ATRIBUTOS_INVENTARIO) and
         oColumna.Visible then
        oColumna.Width := AnchoColumnaAtributoInventario(
          AnchoMaximo[oColumna.Tag], oColumna.Width);
    end;
  end;
end;

end.

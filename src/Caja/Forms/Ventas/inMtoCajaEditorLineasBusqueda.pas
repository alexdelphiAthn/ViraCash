{******************************************************************************}
{                                                                              }
{  Busqueda, stock y fotografia del editor de lineas de caja.                  }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorLineasBusqueda;

interface

uses
  System.Classes, Vcl.Forms, Vcl.ExtCtrls, Data.DB, Uni,
  cxEdit, cxGridCustomTableView, cxGridDBTableView,
  UniDataCaja, inLibParametrosIntf, inLibCajaVentaIntf,
  inLibGenBusq, inLibFotos, inLibLogIntf, inLibPestanasEjeVcl;

type
  TContextoBusquedaEditorLineasCajaVcl = record
    Formulario: TCustomForm;
    DatosCaja: TdmCajaOpe;
    Conexion: TUniConnection;
    ParametrosCaja: IParametrosCaja;
    RepositorioConsultas: IRepositorioConsultasCaja;
    RepositorioArticulos: IRepositorioArticulosCaja;
    BusquedaVisual: IBusquedaVisual;
    FotosArticulos: TFotosArticulos;
    RegistroLog: IRegistroLog;
    VistaLineas: TcxGridDBTableView;
    FuenteLineas: TDataSource;
    FuenteStock: TDataSource;
    FuenteBusqueda: TDataSource;
    VistaStock: TcxGridDBTableView;
    VistaBusqueda: TcxGridDBTableView;
    TemporizadorBusqueda: TTimer;
    ImagenStock: TImage;
  end;
  TBusquedaEditorLineasCajaVcl = class
  private
    FContexto: TContextoBusquedaEditorLineasCajaVcl;
    FConsultaStock: IResultadoConsultaCaja;
    FPestanasStock: TControlPestanasGridStock;
    function CodigoConsultaStock(const ACodigo: string): string;
    procedure AsignarColumnasStock(ADataSet: TDataSet);
    procedure AjustarPresentacionStock(ADataSet: TDataSet);
    function ObtenerEditorActivo: TcxCustomEdit;
    function ObtenerTextoEditor(AEditor: TcxCustomEdit): string;
    procedure LimpiarVistaBusqueda;
    function CargarBusquedaIncremental(
      const ATexto: string): IResultadoConsultaCaja;
    procedure RegistrarDiagnosticoBusqueda(
      const ATarifa, ATexto: string;
      AFecha: TDateTime;
      ADataSet: TDataSet);
    procedure ConfigurarDesplegable(AEditor: TcxCustomEdit);
    procedure ConfigurarCampo(
      ACampo: TField;
      const AEtiqueta, AFormato: string);
  public
    constructor Create(
      const AContexto: TContextoBusquedaEditorLineasCajaVcl);
    destructor Destroy; override;
    procedure ConsultarStock(const ACodigo: string);
    procedure LimpiarStock;
    function EjecutarBusquedaIncremental(
      Sender: TObject): IResultadoConsultaCaja;
    function BuscarArticulo: string;
    procedure RefrescarFotoStock;
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  Data.FmtBcd, Data.SqlTimSt, Vcl.Imaging.PngImage, cxTextEdit,
  cxDBExtLookupComboBox, inLibAtributosPaleta,
  inMtoCajaEditorLineasDecisiones, inLibMsgArticulos, inLibMsgCaja,
  inLibErroresBBDD;

type
  // Acceso al ancho óptimo de la columna, que DevExpress deja protegido.
  TColumnaStockAcceso = class(TcxGridDBColumn);

constructor TBusquedaEditorLineasCajaVcl.Create(
  const AContexto: TContextoBusquedaEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
  FPestanasStock := TControlPestanasGridStock.Create(
    FContexto.VistaStock);
end;

destructor TBusquedaEditorLineasCajaVcl.Destroy;
begin
  FreeAndNil(FPestanasStock);
  FConsultaStock := nil;
  FContexto.RepositorioConsultas := nil;
  FContexto.RepositorioArticulos := nil;
  FContexto.BusquedaVisual := nil;
  FContexto.ParametrosCaja := nil;
  FContexto.RegistroLog := nil;
  inherited;
end;

function TBusquedaEditorLineasCajaVcl.CodigoConsultaStock(
  const ACodigo: string): string;
var
  ArticuloLinea: string;
  LineasActivas: Boolean;
  TodosColores: Boolean;
begin
  ArticuloLinea := '';
  LineasActivas := Assigned(FContexto.DatosCaja) and
    FContexto.DatosCaja.cdsLineas.Active;
  if LineasActivas then
    ArticuloLinea := Trim(
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString);
  TodosColores := FContexto.ParametrosCaja.GetBool(
    'vgerStockTodosColores',
    False);
  Result := ResolverCodigoConsultaStock(
    ACodigo,
    ArticuloLinea,
    TodosColores,
    LineasActivas);
end;

procedure TBusquedaEditorLineasCajaVcl.AsignarColumnasStock(
  ADataSet: TDataSet);
var
  I: Integer;
begin
  FContexto.VistaStock.BeginUpdate;
  try
    FContexto.VistaStock.ClearItems;
    if not ADataSet.IsEmpty then
    begin
      ConfigurarCampo(ADataSet.FindField('Codigo'),
        SCaptionStockCodigoCaja, '');
      ConfigurarCampo(ADataSet.FindField('Almacen'),
        SCaptionBusquedaAlmacen, '');
      ConfigurarCampo(ADataSet.FindField('Stock_Total'),
        SCaptionStockTotalCaja, '');
      ConfigurarCampo(ADataSet.FindField('Total'),
        SCaptionStockTotalCaja, '');
      FContexto.VistaStock.DataController.CreateAllItems;
      for I := 0 to FContexto.VistaStock.ColumnCount - 1 do
      begin
        if I <= 1 then
          FContexto.VistaStock.Columns[I].HeaderAlignmentHorz :=
            taLeftJustify
        else
          FContexto.VistaStock.Columns[I].HeaderAlignmentHorz :=
            taRightJustify;
      end;
    end;
  finally
    FContexto.VistaStock.EndUpdate;
  end;
end;

procedure TBusquedaEditorLineasCajaVcl.AjustarPresentacionStock(
  ADataSet: TDataSet);
var
  Mapa: TDictionary<string, string>;
  Columna: TcxGridDBColumn;
  I: Integer;
begin
  if ADataSet.Active and (not ADataSet.IsEmpty) then
  begin
    FContexto.VistaStock.BeginUpdate;
    try
      try
        FContexto.VistaStock.ApplyBestFit;
        // La vista reparte el ancho (ColumnAutoWidth) y, al ensanchar la
        // columna del código para el cuadradito, estrechaba las de tallas
        // y el total hasta cortar la cabecera ("Tot"). Con el mínimo en
        // su ancho óptimo sólo ceden las columnas de texto.
        for I := 2 to FContexto.VistaStock.ColumnCount - 1 do
        begin
          Columna := FContexto.VistaStock.Columns[I];
          Columna.MinWidth := TColumnaStockAcceso(Columna).GetBestFitWidth;
        end;
      except
        on E: Exception do
          FContexto.RegistroLog.RegistrarAviso(
            'CajaOpe: ApplyBestFit del stock ignorado: ' +
            E.Message);
      end;
      Mapa := ObtenerMapaAtributosGlobal(FContexto.Conexion);
      if Assigned(Mapa) and (Mapa.Count > 0) and
         (FContexto.VistaStock.ColumnCount > 0) then
        AjustarAnchoColumnaParaSwatch(
          FContexto.Conexion,
          FContexto.VistaStock.Columns[0],
          Mapa);
    finally
      FContexto.VistaStock.EndUpdate;
    end;
  end;
end;

procedure TBusquedaEditorLineasCajaVcl.ConsultarStock(
  const ACodigo: string);
var
  Codigo: string;
  Datos: TDataSet;
begin
  Codigo := CodigoConsultaStock(ACodigo);
  if Codigo <> '' then
  begin
    FContexto.FuenteStock.DataSet := nil;
    // FZ-ISSUE-393: la rejilla de stock es informativa. Si su consulta
    // falla, la línea de venta entra igual y el fallo queda en el log.
    try
      FConsultaStock :=
        FContexto.RepositorioConsultas.ConsultarStock(Codigo);
      Datos := FConsultaStock.DataSet;
      FContexto.FuenteStock.DataSet := Datos;
      AsignarColumnasStock(Datos);
      AjustarPresentacionStock(Datos);
      FPestanasStock.Actualizar(Codigo);
    except
      on E: Exception do
      begin
        FContexto.FuenteStock.DataSet := nil;
        FPestanasStock.Ocultar;
        FConsultaStock := nil;
        FContexto.RegistroLog.RegistrarAviso(
          'CajaOpe: consulta de stock de "' + Codigo +
          '" ignorada: ' + E.ClassName + ' ' + E.Message);
      end;
    end;
  end;
end;

procedure TBusquedaEditorLineasCajaVcl.LimpiarStock;
begin
  FContexto.FuenteStock.DataSet := nil;
  FPestanasStock.Ocultar;
  FConsultaStock := nil;
end;

function TBusquedaEditorLineasCajaVcl.ObtenerEditorActivo:
  TcxCustomEdit;
begin
  Result := nil;
  if FContexto.VistaLineas.Controller.
     EditingController.IsEditing then
    Result := FContexto.VistaLineas.Controller.
      EditingController.Edit;
end;

function TBusquedaEditorLineasCajaVcl.ObtenerTextoEditor(
  AEditor: TcxCustomEdit): string;
var
  EditorTexto: TcxCustomTextEdit;
begin
  if AEditor is TcxCustomTextEdit then
  begin
    EditorTexto := TcxCustomTextEdit(AEditor);
    Result := ResolverTextoBusqueda(
      EditorTexto.Text,
      EditorTexto.SelStart,
      EditorTexto.SelLength);
  end
  else
    Result := Trim(VarToStr(AEditor.EditingValue));
end;

procedure TBusquedaEditorLineasCajaVcl.LimpiarVistaBusqueda;
begin
  FContexto.VistaBusqueda.DataController.DataSource := nil;
  FContexto.VistaBusqueda.DataController.Filter.Clear;
  FContexto.VistaBusqueda.DataController.Filter.Active := False;
  FContexto.VistaBusqueda.Controller.IncSearchingText := '';
end;

procedure TBusquedaEditorLineasCajaVcl.RegistrarDiagnosticoBusqueda(
  const ATarifa, ATexto: string;
  AFecha: TDateTime;
  ADataSet: TDataSet);
begin
  try
    FContexto.RegistroLog.RegistrarInformacion(
      Format(
        'qryBusq.Open: TARIFA="%s" FECHA_TARIFA="%s" ' +
        'TOKEN="%s" IsEmpty=%s RecordCount=%d',
        [ATarifa,
         DateToStr(AFecha),
         ATexto,
         BoolToStr(ADataSet.IsEmpty, True),
         ADataSet.RecordCount]));
    if not ADataSet.IsEmpty then
    begin
      ADataSet.First;
      while (not ADataSet.Eof) and (ADataSet.RecNo <= 5) do
      begin
        FContexto.RegistroLog.RegistrarInformacion(
          Format(
            'qryBusq fila %d: cod="%s" desc="%s"',
            [ADataSet.RecNo,
             ADataSet.FieldByName('CODIGO_PADRE').AsString,
             ADataSet.FieldByName('DESCRIPCION_ART').AsString]));
        ADataSet.Next;
      end;
      ADataSet.First;
    end;
  except
    on E: Exception do
      FContexto.RegistroLog.RegistrarAviso(
        'qryBusq diagnostico: ' +
        E.ClassName + ' ' + E.Message);
  end;
end;

function TBusquedaEditorLineasCajaVcl.CargarBusquedaIncremental(
  const ATexto: string): IResultadoConsultaCaja;
var
  Datos: TDataSet;
  Fecha: TDateTime;
  Tarifa: string;
begin
  Tarifa := FContexto.DatosCaja.cdsCabecera.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  Fecha := FContexto.DatosCaja.cdsCabecera.FieldByName(
    'FECHA_FAC').AsDateTime;
  FContexto.FuenteBusqueda.DataSet := nil;
  Result := FContexto.RepositorioArticulos.
    ConsultarArticulosIncremental(Tarifa, ATexto, Fecha);
  Datos := Result.DataSet;
  FContexto.FuenteBusqueda.DataSet := Datos;
  RegistrarDiagnosticoBusqueda(Tarifa, ATexto, Fecha, Datos);
  FContexto.VistaBusqueda.DataController.DataSource :=
    FContexto.FuenteBusqueda;
  FContexto.VistaBusqueda.DataController.Refresh;
end;

procedure TBusquedaEditorLineasCajaVcl.ConfigurarDesplegable(
  AEditor: TcxCustomEdit);
var
  Combo: TcxExtLookupComboBox;
begin
  if AEditor is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(AEditor);
    if not Combo.DroppedDown then
    begin
      if Assigned(FContexto.FuenteBusqueda.DataSet) and
         (not FContexto.FuenteBusqueda.DataSet.IsEmpty) then
        Combo.DroppedDown := True;
    end
    else
      Combo.Properties.DropDownRows := 15;
  end;
end;

function TBusquedaEditorLineasCajaVcl.EjecutarBusquedaIncremental(
  Sender: TObject): IResultadoConsultaCaja;
var
  EditorActivo: TcxCustomEdit;
  Texto: string;
begin
  Result := nil;
  FContexto.TemporizadorBusqueda.Enabled := False;
  FContexto.VistaBusqueda.BeginUpdate;
  try
    LimpiarVistaBusqueda;
    EditorActivo := ObtenerEditorActivo;
    if Assigned(EditorActivo) then
    begin
      Texto := ObtenerTextoEditor(EditorActivo);
      if DebeBuscarIncremental(Texto) then
        Result := CargarBusquedaIncremental(Texto);
    end;
  finally
    FContexto.VistaBusqueda.EndUpdate;
  end;
  ConfigurarDesplegable(EditorActivo);
end;

procedure TBusquedaEditorLineasCajaVcl.ConfigurarCampo(
  ACampo: TField;
  const AEtiqueta, AFormato: string);
begin
  if Assigned(ACampo) then
  begin
    if AEtiqueta <> '' then
      ACampo.DisplayLabel := AEtiqueta;
    if AFormato <> '' then
    begin
      if ACampo is TFloatField then
        TFloatField(ACampo).DisplayFormat := AFormato
      else if ACampo is TBCDField then
        TBCDField(ACampo).DisplayFormat := AFormato
      else if ACampo is TFMTBCDField then
        TFMTBCDField(ACampo).DisplayFormat := AFormato
      else if ACampo is TDateField then
        TDateField(ACampo).DisplayFormat := AFormato
      else if ACampo is TDateTimeField then
        TDateTimeField(ACampo).DisplayFormat := AFormato
      else if ACampo is TSQLTimeStampField then
        TSQLTimeStampField(ACampo).DisplayFormat := AFormato;
    end;
  end;
end;

function TBusquedaEditorLineasCajaVcl.BuscarArticulo: string;
var
  Datos: TDataSet;
  Resultado: IResultadoConsultaCaja;
begin
  Resultado := FContexto.RepositorioArticulos.
    ConsultarArticulosBusqueda(
      FContexto.DatosCaja.cdsCabecera.FieldByName(
        'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
      FContexto.DatosCaja.cdsCabecera.FieldByName(
        'FECHA_FAC').AsDateTime);
  Datos := Resultado.DataSet;
  ConfigurarCampo(Datos.FindField('CODIGO_ART_ART'), 'Código', '');
  ConfigurarCampo(Datos.FindField('DESCRIPCION_ART'), 'Descripción', '');
  ConfigurarCampo(Datos.FindField('DESCRIPCION_FAM'), 'Familia', '');
  ConfigurarCampo(Datos.FindField('TEMPORADA'), 'Temporada', '');
  ConfigurarCampo(
    Datos.FindField('RAZON_SOCIAL_PROVEEDOR'),
    'Proveedor',
    '');
  ConfigurarCampo(Datos.FindField('REF_PROVEEDOR'), 'Ref. proveedor', '');
  ConfigurarCampo(Datos.FindField('CODIGO_TAR_ARTTAR'), 'Tarifa', '');
  ConfigurarCampo(Datos.FindField('NOMBRE_TAR_TAR'), 'Nombre tarifa', '');
  ConfigurarCampo(
    Datos.FindField('PRECIO_FINAL_ARTTAR'),
    'Precio',
    '#,##0.00 €');
  ConfigurarCampo(
    Datos.FindField('FECHA_DESDE_ARTTAR'),
    'Desde',
    'dd/mm/yyyy');
  ConfigurarCampo(
    Datos.FindField('FECHA_HASTA_ARTTAR'),
    'Hasta',
    'dd/mm/yyyy');
  if FContexto.BusquedaVisual.EjecutarBusquedaDataSet(
       STituloBusquedaArticulosCaja,
       Datos,
       'frmMtoArtFacSearch',
       FContexto.Formulario) then
    Result := Datos.FieldByName('CODIGO_ART_ART').AsString
  else
    Result := '';
end;

procedure TBusquedaEditorLineasCajaVcl.RefrescarFotoStock;
var
  Articulo: string;
  Foto: TFotoInfo;
  Png: TPngImage;
  Ruta: string;
  Sku: string;
begin
  if Assigned(FContexto.ImagenStock) and
     Assigned(FContexto.FuenteLineas) then
  begin
    LeerArtSkuDeDataSet(
      FContexto.FuenteLineas.DataSet,
      Articulo,
      Sku);
    if Articulo <> '' then
    begin
      FContexto.ImagenStock.Picture.Assign(nil);
      try
        Foto := FContexto.FotosArticulos.Resolver(Articulo, Sku);
        Ruta := FContexto.FotosArticulos.RutaFoto(Foto, frPx300);
        if Ruta <> '' then
        begin
          Png := TPngImage.Create;
          try
            Png.LoadFromFile(Ruta);
            FContexto.ImagenStock.Picture.Assign(Png);
          finally
            Png.Free;
          end;
        end;
      except
        on E: EErrorBBDD do
          // OnDataChange puede ejecutarse dentro del refresco de DevExpress.
          // Dejar salir el error de la foto interrumpe ese refresco y deja
          // la rejilla bloqueada aunque el cobro capture la excepción.
          FContexto.RegistroLog.RegistrarAviso(
            'CajaOpe: no se pudo refrescar la foto de "' + Articulo +
            '": ' + E.Message);
      end;
    end;
  end;
end;

end.

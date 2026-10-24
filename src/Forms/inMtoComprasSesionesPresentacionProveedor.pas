{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionProveedor                     }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Proveedor de la sesion de compra: busqueda, rotulo, ficha, defectos       }
{    de compras y kits de cantidades por talla. Incluye el selector de         }
{    color basico de la linea, que comparte paleta y swatch.                   }
{                                                                              }
{    Recibe el data module de sesiones porque las operaciones de kit           }
{    (UniDataComprasSesionesOperaciones) estan escritas contra el.             }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionProveedor;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Math,
  System.Variants,
  System.UITypes,
  Data.DB,
  Uni,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Menus,
  cxGraphics,
  cxLookAndFeels,
  cxControls,
  cxEdit,
  cxTextEdit,
  cxDropDownEdit,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibGenBusq,
  inLibGridTallasInline,
  UniDataComprasSesiones;

type
  TEntornoProveedorSesion = record
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Datos: TdmComprasSesiones;
    BusquedaVisual: IBusquedaVisual;
    Vista: TcxGridDBTableView;
    ColumnaColor: TcxGridDBColumn;
    ColumnaColorBasico: TcxGridDBColumn;
    BotonKits: TControl;
    ObtenerGestorTallas: TFunc<TGestorGridTallas>;
    MostrarNombreProveedor: TProc<string>;
    RefrescarVisibilidadTipoIva: TProc;
    AbrirDistribuidor: TProc<string>;
    Registrar: TProc<string>;
  end;

  TCoordinadorProveedorSesion = class
  private
    FEntorno: TEntornoProveedorSesion;
    FBasicosColor: TArray<string>;
    FNombresBasicosColor: TArray<string>;
    FFichaCargada: string;
    FMenuKits: TPopupMenu;
    FCodigosKits: TArray<string>;
    // Opciones del combo, paralelas a FBasicosColor.
    FTextosBasicosColor: TArray<string>;
    function GestorTallas: TGestorGridTallas;
    function CodigoProveedorCabecera: string;
    function EsFormatoDistribuido: Boolean;
    procedure KitDelMenuElegido(ASender: TObject);
    procedure ConstruirMenuKits;
    procedure Anotar(const ATexto: string);
    procedure ConfigurarComboColorBasico;
    procedure PrepararListaColorBasico(Sender: TObject);
    procedure ConfigurarAyudaColorTexto;
    procedure DibujarOpcionColorBasico(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
  public
    constructor Create(const AEntorno: TEntornoProveedorSesion);
    destructor Destroy; override;
    // Codigos de color basico activos; alimentan la paleta de la linea.
    procedure CargarBasicosColor;
    // Acepta codigo o nombre; los nombres repetidos no son identificadores.
    function ResolverColorBasicoLiteral(
      const ALiteral: string; out ACodigo: string): Boolean;
    // Si el texto libre coincide con el codigo o nombre de un basico,
    // asigna su codigo canonico a la linea actual.
    procedure AsignarColorBasicoCoincidente;
    // Clasifica con un literal externo sin sustituir el color proveedor.
    procedure AsignarColorBasicoLiteral(const ALiteral: string);
    // Buscador generico sobre vi_proveedores; vuelca el codigo elegido
    // en la cabecera de la sesion.
    procedure BuscarProveedor;
    procedure ActualizarRotuloProveedor;
    // Reabre ficha y kits solo si cambia el proveedor o si la consulta
    // quedo cerrada tras un ResetForm.
    procedure RecargarProveedorSesion;
    // Copia a la cabecera los defectos de compras del proveedor.
    procedure CopiarDefectosProveedor;
    procedure AplicarKitALineaActual(const ACodigoKit: string);
    // Despliega el popup con los kits del proveedor sobre la linea con
    // foco. False si no hay linea o el proveedor no tiene kits.
    function MostrarMenuKits: Boolean;
    // True si la celda de color basico ya queda pintada aqui.
    function DibujarCeldaColor(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
  end;

implementation

uses
  inLibMensajesVcl,
  Vcl.Dialogs,
  inLibAtributosPaleta,
  inLibComprasSesionesReglas,
  inLibMsgArticulos,
  inLibMsgCompras,
  inLibPresentacionDocumento,
  UniDataComprasSesionesOperaciones;

resourcestring
  STituloBuscarProveedoresSesionCompra = 'Busqueda de proveedores';

const
  // Eje de variacion de color en fza_atributos_valores.
  cIdVaColor = 'CO';
  // Lista del combo de color basico de la linea.
  cFilasComboColorBasico = 15;
  cAnchoComboColorBasico = 260;

constructor TCoordinadorProveedorSesion.Create(
  const AEntorno: TEntornoProveedorSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Datos) then
    raise EArgumentNilException.Create('AEntorno.Datos');
  FEntorno := AEntorno;
end;

destructor TCoordinadorProveedorSesion.Destroy;
begin
  FreeAndNil(FMenuKits);
  inherited Destroy;
end;

function TCoordinadorProveedorSesion.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if Assigned(FEntorno.ObtenerGestorTallas) then
    Result := FEntorno.ObtenerGestorTallas();
end;

procedure TCoordinadorProveedorSesion.Anotar(const ATexto: string);
begin
  if Assigned(FEntorno.Registrar) then
    FEntorno.Registrar(ATexto);
end;

function TCoordinadorProveedorSesion.CodigoProveedorCabecera: string;
begin
  Result := '';
  if FEntorno.Datos.unqryTablaG.Active and
     (not FEntorno.Datos.unqryTablaG.IsEmpty) then
    Result := Trim(FEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_PRV_SES').AsString);
end;

function TCoordinadorProveedorSesion.EsFormatoDistribuido: Boolean;
begin
  Result := (not FEntorno.Datos.unqryTablaG.IsEmpty) and
            (FEntorno.Datos.unqryTablaG.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

procedure TCoordinadorProveedorSesion.CargarBasicosColor;
var
  i: Integer;
  Info: TInfoBasico;
begin
  FBasicosColor := FEntorno.Servicio.ConsultarCodigosBasicosActivos(
    cIdVaColor);
  SetLength(FNombresBasicosColor, Length(FBasicosColor));
  for i := 0 to High(FBasicosColor) do
  begin
    Info := Default(TInfoBasico);
    if ObtenerInfoBasico(
      FEntorno.Conexion, cIdVaColor, FBasicosColor[i], Info) then
      FNombresBasicosColor[i] := Info.Nombre;
  end;
  ConfigurarComboColorBasico;
  ConfigurarAyudaColorTexto;
end;

// Color proveedor: texto libre; la lista ayuda sin completar lo tecleado.
procedure TCoordinadorProveedorSesion.ConfigurarAyudaColorTexto;
var
  i: Integer;
  sNombre: string;
  Propiedades: TcxComboBoxProperties;
begin
  if (FEntorno.ColumnaColor <> nil) and
     (FEntorno.ColumnaColor.Properties is TcxComboBoxProperties) then
  begin
    Propiedades := TcxComboBoxProperties(
      FEntorno.ColumnaColor.Properties);
    Propiedades.BeginUpdate;
    try
      Propiedades.Items.Clear;
      for i := 0 to High(FBasicosColor) do
      begin
        sNombre := Trim(FNombresBasicosColor[i]);
        if sNombre = '' then
          sNombre := FBasicosColor[i];
        if Propiedades.Items.IndexOf(sNombre) < 0 then
          Propiedades.Items.Add(sNombre);
      end;
      Propiedades.DropDownListStyle := lsEditList;
      Propiedades.DropDownRows := cFilasComboColorBasico;
      Propiedades.Sorted := True;
      Propiedades.IncrementalFiltering := False;
      Propiedades.IncrementalSearch := False;
      Propiedades.ImmediateDropDownWhenKeyPressed := False;
    finally
      Propiedades.EndUpdate;
    end;
  end;
end;

// Cada opcion es 'CODIGO - Nombre' para que al teclear se filtre tanto
// por codigo como por nombre; la celda guarda solo el codigo (OnValidate).
procedure TCoordinadorProveedorSesion.ConfigurarComboColorBasico;
var
  i: Integer;
  Propiedades: TcxComboBoxProperties;
begin
  SetLength(FTextosBasicosColor, Length(FBasicosColor));
  for i := 0 to High(FBasicosColor) do
  begin
    FTextosBasicosColor[i] := FBasicosColor[i];
    if (Trim(FNombresBasicosColor[i]) <> '') and
       (not SameText(FNombresBasicosColor[i], FBasicosColor[i])) then
      FTextosBasicosColor[i] := FBasicosColor[i] + ' - ' +
        FNombresBasicosColor[i];
  end;
  if FEntorno.ColumnaColorBasico.Properties is TcxComboBoxProperties then
  begin
    Propiedades := TcxComboBoxProperties(
      FEntorno.ColumnaColorBasico.Properties);
    Propiedades.BeginUpdate;
    try
      Propiedades.Items.Clear;
      for i := 0 to High(FTextosBasicosColor) do
        Propiedades.Items.Add(FTextosBasicosColor[i]);
      Propiedades.DropDownListStyle := lsEditList;
      Propiedades.DropDownRows := cFilasComboColorBasico;
      Propiedades.DropDownAutoWidth := False;
      Propiedades.OnInitPopup := PrepararListaColorBasico;
      Propiedades.Sorted := False;
      Propiedades.IncrementalFiltering := True;
      Propiedades.IncrementalFilteringOptions :=
        [ifoHighlightSearchText, ifoUseContainsOperator];
      Propiedades.ImmediateDropDownWhenKeyPressed := True;
      Propiedades.PostPopupValueOnTab := True;
      Propiedades.OnDrawItem := DibujarOpcionColorBasico;
    finally
      Propiedades.EndUpdate;
    end;
  end;
end;

procedure TCoordinadorProveedorSesion.PrepararListaColorBasico(
  Sender: TObject);
var
  Combo: TcxComboBox;
  Lienzo: TBitmap;
  Texto: string;
  Ancho: Integer;
begin
  if Sender is TcxComboBox then
  begin
    Combo := TcxComboBox(Sender);
    Combo.Style.LookAndFeel.ScrollbarMode := sbmClassic;
    Ancho := Combo.ScaleValue(cAnchoComboColorBasico);
    Lienzo := TBitmap.Create;
    try
      Lienzo.Canvas.Font.Assign(Combo.Style.Font);
      for Texto in FTextosBasicosColor do
        Ancho := System.Math.Max(Ancho,
          Lienzo.Canvas.TextWidth(Texto) + Combo.ScaleValue(64));
    finally
      Lienzo.Free;
    end;
    Combo.ActiveProperties.DropDownWidth := Ancho;
  end;
end;

procedure TCoordinadorProveedorSesion.DibujarOpcionColorBasico(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas; AIndex: Integer;
  const ARect: TRect; AState: TOwnerDrawState);
var
  Info: TInfoBasico;
  HayColor: Boolean;
begin
  // AIndex es el de Items aunque la lista este filtrada.
  if (AIndex >= 0) and (AIndex < Length(FBasicosColor)) then
  begin
    Info := Default(TInfoBasico);
    HayColor := ObtenerInfoBasico(
      FEntorno.Conexion, cIdVaColor, FBasicosColor[AIndex], Info);
    PintarOpcionComboConSwatch(ACanvas, ARect, AState,
      FTextosBasicosColor[AIndex], HayColor, Info);
  end;
end;

function TCoordinadorProveedorSesion.ResolverColorBasicoLiteral(
  const ALiteral: string; out ACodigo: string): Boolean;
var
  i: Integer;
begin
  ACodigo := '';
  Result := Trim(ALiteral) = '';
  // Opcion elegida en el combo ('CODIGO - Nombre').
  i := 0;
  while (not Result) and (i < Length(FTextosBasicosColor)) do
  begin
    if SameText(Trim(ALiteral), FTextosBasicosColor[i]) then
    begin
      ACodigo := FBasicosColor[i];
      Result := True;
    end;
    Inc(i);
  end;
  if not Result then
    Result := ResolverCodigoColorBasico(
      ALiteral, FBasicosColor, FNombresBasicosColor, ACodigo);
end;

procedure TCoordinadorProveedorSesion.AsignarColorBasicoCoincidente;
var
  sLiteral: string;
  Lineas: TDataSet;
begin
  Lineas := FEntorno.Datos.unqrySesionLin;
  if Lineas.Active and (not Lineas.IsEmpty) and
     (Lineas.State in [dsEdit, dsInsert]) then
  begin
    sLiteral := Lineas.FieldByName('COLOR_TEXTO_SESLIN').AsString;
    AsignarColorBasicoLiteral(sLiteral);
  end;
end;

procedure TCoordinadorProveedorSesion.AsignarColorBasicoLiteral(
  const ALiteral: string);
var
  sCodigo: string;
  Lineas: TDataSet;
begin
  Lineas := FEntorno.Datos.unqrySesionLin;
  if Lineas.Active and (not Lineas.IsEmpty) and
     (Lineas.State in [dsEdit, dsInsert]) then
  begin
    if (Trim(ALiteral) <> '') and
      ResolverColorBasicoLiteral(ALiteral, sCodigo) and
      (not SameText(sCodigo, Lineas.FieldByName(
        'CODIGO_ATB_COLOR_SESLIN').AsString)) then
      Lineas.FieldByName(
        'CODIGO_ATB_COLOR_SESLIN').AsString := sCodigo;
  end;
end;

procedure TCoordinadorProveedorSesion.BuscarProveedor;
var
  sCodigo: string;
begin
  if FEntorno.Datos.unqryTablaG.IsEmpty then
    MessageDlg_fza(SErrorSesionElegirProveedorNoSeleccionada,
               mtInformation, [mbOk], 0)
  else if FEntorno.BusquedaVisual.EjecutarBusqueda(
    FEntorno.Conexion,
    STituloBuscarProveedoresSesionCompra,
    'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
    'CODIGO_PRV_PRV',
    sCodigo,
    'frmMtoSesProvSearch') then
  begin
    if not (FEntorno.Datos.unqryTablaG.State in [dsInsert, dsEdit]) then
      FEntorno.Datos.unqryTablaG.Edit;
    FEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_PRV_SES').AsString := sCodigo;
    ActualizarRotuloProveedor;
  end;
end;

procedure TCoordinadorProveedorSesion.ActualizarRotuloProveedor;
begin
  if Assigned(FEntorno.MostrarNombreProveedor) then
    FEntorno.MostrarNombreProveedor(
      TextoProveedorDocumento(
        FEntorno.Datos.unqryTablaG,
        FEntorno.Datos.unqryProveedores,
        'CODIGO_PRV_SES'));
end;

procedure TCoordinadorProveedorSesion.RecargarProveedorSesion;
var
  sProveedor: string;
begin
  sProveedor := CodigoProveedorCabecera;
  if (not SameText(sProveedor, FFichaCargada)) or
     ((sProveedor <> '') and
      (not FEntorno.Datos.unqryPrvFicha.Active)) then
  begin
    FFichaCargada := sProveedor;
    FEntorno.Datos.RecargarProveedorSesion(sProveedor);
  end;
end;

// El margen solo pisa cuando el proveedor tiene valor. El sistema de
// tallas del proveedor no tiene columna en la cabecera: fija el
// tallaje-defecto del documento que propone la siguiente linea nueva.
procedure TCoordinadorProveedorSesion.CopiarDefectosProveedor;
var
  Ficha: TDataSet;
  Cabecera: TDataSet;
begin
  FEntorno.Datos.HeredarDescripcionProveedor;
  Ficha := FEntorno.Datos.unqryPrvFicha;
  Cabecera := FEntorno.Datos.unqryTablaG;
  if Ficha.Active and (not Ficha.IsEmpty) then
  begin
    if Ficha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat > 0 then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat :=
        Ficha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat;
    end;
    if (Ficha.FindField('ID_AC_TALLAS_PRV') <> nil) and
       (Ficha.FieldByName('ID_AC_TALLAS_PRV').AsInteger > 0) then
      FEntorno.Datos.TallajeDefectoActual :=
        Ficha.FieldByName('ID_AC_TALLAS_PRV').AsInteger;
    // Con varios tipos de variación, el proveedor propone el suyo a una
    // sesión aún sin líneas (FZ-ISSUE-420).
    FEntorno.Datos.ProponerVariacionProveedor(
      Trim(Cabecera.FieldByName('CODIGO_PRV_SES').AsString));
    if (Ficha.FindField('CODIGO_FP_PRV') <> nil) and
       (Cabecera.FindField('FORMA_PAGO_SES') <> nil) and
       (Trim(Cabecera.FieldByName('FORMA_PAGO_SES').AsString) = '') and
       (Trim(Ficha.FieldByName('CODIGO_FP_PRV').AsString) <> '') then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('FORMA_PAGO_SES').AsString :=
        Trim(Ficha.FieldByName('CODIGO_FP_PRV').AsString);
    end;
    if (Ficha.FindField('ESVARIOS_TIPOS_IVA_PRV') <> nil) and
       (Cabecera.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString :=
        UpperCase(Trim(Ficha.FieldByName(
          'ESVARIOS_TIPOS_IVA_PRV').AsString));
      if Cabecera.FieldByName(
         'ESVARIOS_TIPOS_IVA_SES').AsString = '' then
        Cabecera.FieldByName(
          'ESVARIOS_TIPOS_IVA_SES').AsString := 'N';
      if Assigned(FEntorno.RefrescarVisibilidadTipoIva) then
        FEntorno.RefrescarVisibilidadTipoIva();
    end;
    if (Ficha.FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PRV') <> nil) and
       (Cabecera.FindField(
         'ESIVA_EXENTO_INTRACOMUNITARIO_SES') <> nil) then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName(
        'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString :=
        UpperCase(Trim(Ficha.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_PRV').AsString));
      if Cabecera.FieldByName(
         'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString = '' then
        Cabecera.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString := 'N';
      FEntorno.Datos.RefrescarTotalesSesion;
    end;
  end;
end;

// Formato distribuido: el kit se aplica desde la matriz de almacenes.
// Formato simple: vuelca las cantidades sobre la linea con foco y
// repinta la fila igual que tras teclear a mano.
procedure TCoordinadorProveedorSesion.AplicarKitALineaActual(
  const ACodigoKit: string);
var
  sProveedor: string;
  sResumen: string;
  iLinea: Integer;
  iFila: Integer;
  Gestor: TGestorGridTallas;
begin
  sProveedor := CodigoProveedorCabecera;
  Gestor := GestorTallas;
  if EsFormatoDistribuido then
  begin
    if ValidarKitSobreLineaActual(
      FEntorno.Datos,
      FEntorno.Servicio,
      sProveedor,
      ACodigoKit,
      sResumen) then
    begin
      Anotar(Format(
        'AplicarKit %s -> distribuidor (formato distribuido)',
        [ACodigoKit]));
      if Assigned(FEntorno.AbrirDistribuidor) then
        FEntorno.AbrirDistribuidor(ACodigoKit);
    end
    else
      MessageDlg_fza(sResumen, mtWarning, [mbOk], 0);
  end
  else if AplicarKitProveedorALinea(
    FEntorno.Datos,
    Gestor,
    FEntorno.Servicio,
    sProveedor,
    ACodigoKit,
    sResumen) then
  begin
    iLinea := FEntorno.Datos.unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    if Assigned(Gestor) then
    begin
      Gestor.RefrescarTotalesLineaActual;
      iFila := FEntorno.Vista.Controller.FocusedRecordIndex;
      if iFila >= 0 then
        Gestor.CargarCantidadesUnaLinea(iFila, iLinea);
    end;
    FEntorno.Datos.RefrescarTotalesSesion;
    Anotar(Format('AplicarKit %s sobre linea %d',
                  [ACodigoKit, iLinea]));
    // Aviso solo si alguna talla del kit no caso con el sistema.
    if sResumen <> '' then
      MessageDlg_fza(sResumen, mtInformation, [mbOk], 0);
  end
  else
    MessageDlg_fza(sResumen, mtWarning, [mbOk], 0);
end;

procedure TCoordinadorProveedorSesion.KitDelMenuElegido(ASender: TObject);
begin
  if ASender is TMenuItem then
  begin
    if (TMenuItem(ASender).Tag >= 0) and
       (TMenuItem(ASender).Tag <= High(FCodigosKits)) then
      AplicarKitALineaActual(FCodigosKits[TMenuItem(ASender).Tag]);
  end;
end;

procedure TCoordinadorProveedorSesion.ConstruirMenuKits;
var
  Item: TMenuItem;
  Kits: TDataSet;
  TituloKit: string;
  SistemaTallas: string;
begin
  // Sin propietario VCL: lo libera el destructor de este colaborador,
  // que corre antes de que el formulario destruya sus componentes.
  if FMenuKits = nil then
    FMenuKits := TPopupMenu.Create(nil);
  FMenuKits.Items.Clear;
  SetLength(FCodigosKits, 0);
  Kits := FEntorno.Datos.unqryPrvKits;
  Kits.DisableControls;
  try
    Kits.First;
    while not Kits.Eof do
    begin
      Item := TMenuItem.Create(FMenuKits);
      TituloKit := Kits.FieldByName('CODIGO_PRVKIT').AsString +
        ' - ' + Kits.FieldByName('NOMBRE_PRVKIT').AsString;
      SistemaTallas := Trim(
        Kits.FieldByName('NOMBRE_TALLAS_PRVKIT').AsString);
      if SistemaTallas <> '' then
        TituloKit := TituloKit + ' - ' + SistemaTallas;
      Item.Caption := StringReplace(
        TituloKit, '&', '&&', [rfReplaceAll]);
      Item.Tag := Length(FCodigosKits);
      Item.OnClick := KitDelMenuElegido;
      FMenuKits.Items.Add(Item);
      SetLength(FCodigosKits, Length(FCodigosKits) + 1);
      FCodigosKits[High(FCodigosKits)] :=
        Kits.FieldByName('CODIGO_PRVKIT').AsString;
      Kits.Next;
    end;
    Kits.First;
  finally
    Kits.EnableControls;
  end;
end;

function TCoordinadorProveedorSesion.MostrarMenuKits: Boolean;
var
  Punto: TPoint;
begin
  Result := False;
  if FEntorno.Datos.unqrySesionLin.IsEmpty then
    MessageDlg_fza(SErrorLineaArticuloSesionNoSeleccionada,
               mtInformation, [mbOk], 0)
  else if (not FEntorno.Datos.unqryPrvKits.Active) or
          FEntorno.Datos.unqryPrvKits.IsEmpty then
    MessageDlg_fza(SErrorProveedorSesionSinKits,
               mtInformation, [mbOk], 0)
  else
  begin
    ConstruirMenuKits;
    Punto := FEntorno.BotonKits.ClientToScreen(
      Point(0, FEntorno.BotonKits.Height));
    FMenuKits.Popup(Punto.X, Punto.Y);
    Result := True;
  end;
end;

function TCoordinadorProveedorSesion.DibujarCeldaColor(
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  sActual: string;
  sTexto: string;
  Info: TInfoBasico;
begin
  Result := False;
  if (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item = FEntorno.ColumnaColorBasico) then
  begin
    sActual := VarToStr(
      AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);
    if Trim(sActual) <> '' then
    begin
      Info := Default(TInfoBasico);
      if ObtenerInfoBasico(FEntorno.Conexion, cIdVaColor, sActual, Info)
         and Info.EsValido then
      begin
        sTexto := sActual;
        if (Trim(Info.Nombre) <> '') and
           (not SameText(sActual, Info.Nombre)) then
          sTexto := sActual + ' - ' + Info.Nombre;
        Result := PintarCeldaConCuadradoColor(
          ACanvas, AViewInfo, Info, sTexto);
      end;
    end;
  end;
end;

end.

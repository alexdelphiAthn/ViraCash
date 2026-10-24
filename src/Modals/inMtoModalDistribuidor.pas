{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalDistribuidor                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.3.0                                                         }
{   Fecha:       24/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal "distribuidor por almacen" para sesiones de compra en modo          }
{    ESFORMATO_DISTRIBUIDO_SES='S'. Pinta un cuadrante almacenes x tallas      }
{    para una linea concreta de la sesion. El usuario reparte cantidades       }
{    por (almacen, talla); al aceptar hace upsert en                           }
{    fza_compras_sesiones_celdas (clave compuesta por serie+numero+linea+      }
{    almacen+id_av_pivot, idfila=0 para distribuidor: el "color/fila" del      }
{    pivote en sesiones vive a nivel de linea, no a nivel de celda).           }
{                                                                              }
{    Implementacion: TcxGrid en band-view donde un dataset en memoria carga    }
{    una fila por almacen activo con columnas T01..T20. Al cargar leemos las   }
{    celdas existentes; al aceptar comparamos contra el snapshot inicial y     }
{    aplicamos INSERT / UPDATE / DELETE para cada cambio.                      }
{                                                                              }
{    Hereda de TfrmModalAceptCancel para reutilizar pnlBody + pnlButton con    }
{    los botones Aceptar/Cancelar (F12/ESC) estandar de la app.                }
{******************************************************************************}
unit inMtoModalDistribuidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls,
  System.Actions, Vcl.ActnList,
  System.Generics.Collections,
  Data.DB, DBClient, Uni,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxButtonEdit, cxLabel, cxButtons, cxClasses,
  cxLocalization,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxStyles,
  dxSkinsCore, dxSkinBlue,
  inMtoModalAceptCancel, inLibGridTallasInline,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab, inLibDistribuidorTallas,
  inLibDistribuidorPersistenciaIntf;

type
  TfrmModalDistribuidor = class(TfrmModalAceptCancel)
    pnlCab        : TPanel;
    lblTitulo     : TcxLabel;
    lblLinea      : TcxLabel;
    edtLinea      : TcxTextEdit;
    pnlCuadrante  : TPanel;
    cdsCuadr      : TClientDataSet;
    dsCuadr       : TDataSource;
    cxgrdCuadr    : TcxGrid;
    cxlvlCuadr    : TcxGridLevel;
    tvCuadr       : TcxGridDBTableView;
    // Modo kit (Visible solo cuando Preparar recibe un kit): aplica la
    // curva del kit a todas las filas/almacenes del cuadrante.
    btnKitTodos   : TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnKitTodosClick(Sender: TObject);
  protected
    // DoShow es dynamic en TCustomForm. Lo overrideamos para mover el
    // foco al grid (el ancestro lo deja en btnAceptar). Asi el usuario
    // teclea numeros y entra en edicion inmediata sobre la primera
    // celda editable (T01 del primer almacen) -> sensacion Excel.
    procedure DoShow; override;
  private
    FUsuario      : string;
    FIdAcPivot    : Integer;
    FPosiciones   : TArrPosConjunto;
    // Snapshot inicial (almacen, posicion) -> cantidad para detectar
    // cambios al aceptar. Solo se persiste lo que cambia.
    FSnapshot     : TDictionary<string, Double>;
    // Modo kit: curva del kit del proveedor mapeada a posiciones del
    // conjunto pivot (posicion 1..N -> cantidad). El tallaje kit=linea
    // viene validado por el form (ValidarKitSobreLineaActual).
    FCodigoPrvKit : string;
    FCodigoKit    : string;
    FKitPorPos    : TDictionary<Integer, Double>;
    FRepositorio  : IRepositorioDistribuidor;
    // Tabla/campos de celdas PARAMETRIZABLES (defaults de sesiones en
    // FormCreate). ConfigurarCeldas permite reutilizar el distribuidor
    // desde otros documentos (PEDCEL / ALBCEL / tabla de pruebas) sin
    // tocar el comportamiento de sesiones.
    FTablaCel     : string;
    FSerieCelFld  : string;
    FNumeroCelFld : string;
    FLineaCelFld  : string;
    FFilaCelFld   : string;
    FAlmCelFld    : string;
    FAvCelFld     : string;
    FCantCelFld   : string;
    procedure PrepararEstructura;
    procedure PoblarFilasYCantidades;
    procedure PersistirCambios;
    function  ClaveCelda(const ACodigoAlm: string;
                         APosicion: Integer): string; inline;
    function  GetConfirmado: Boolean;
    procedure CargarKit;
    procedure AplicarKitEnFilaCds;
    procedure LimpiarFilaCds;
    function  SincronizarCdsConFoco: Boolean;
    function ConfiguracionPersistencia: TConfiguracionCeldasDistribuidor;
    function DocumentoPersistencia: TDocumentoDistribuidor;
    procedure ColKitPropertiesButtonClick(Sender: TObject;
                                          AButtonIndex: Integer);
  public
    SerieSes  : string;
    NumeroSes : string;
    LineaSes  : Integer;
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioDistribuidor); reintroduce;
      overload;
    // CloseQuery se ejecuta al cerrar mediante boton, F12 o codigo.
    function CloseQuery: Boolean; override;
    // Confirmado se deriva de sFicha ('S' tras Aceptar, 'N' tras Cancelar)
    // que gestiona el ancestro TfrmModalAceptCancel.
    property Confirmado: Boolean read GetConfirmado;
    // ACodigoKit <> '' activa el modo kit: columna de acciones con botones
    // "Aplicar" / "Limpiar" por almacen y boton "Aplicar kit en todos los
    // almacenes". Lo persistido sigue siendo lo de siempre: al Aceptar se
    // compara el cuadrante contra el snapshot.
    procedure Preparar(AConn: TUniConnection;
                       const AUsuario, ASerie, ANumero: string;
                       ALinea, AIdAcPivot: Integer;
                       const ACodigoPrvKit: string = '';
                       const ACodigoKit: string = '';
                       const AArticulo: string = '');
    // Redirige el distribuidor a OTRA tabla de celdas (llamar ANTES de
    // Preparar). Sin llamarlo, opera sobre las celdas de sesiones.
    procedure ConfigurarCeldas(const ATabla, ASerie, ANumero, ALinea,
                               AFila, AAlm, AAv, ACant: string);
  end;

function CrearDistribuidorTallasVisualMto:
  IDistribuidorTallasVisual; overload;
function CrearDistribuidorTallasVisualMto(
  const ARepositorio: IRepositorioDistribuidor
): IDistribuidorTallasVisual; overload;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos,
  inLibMsgComun,
  UniDataConfiguracionPantalla,
  UniDataModoTallas;

resourcestring
  SCaptionAlmacenDistribuidorTallas = 'Almacen';
  SCaptionNombreDistribuidorTallas = 'Nombre';

type
  TDistribuidorTallasVisualMto = class(
    TInterfacedObject,
    IDistribuidorTallasVisual)
  private
    FRepositorio: IRepositorioDistribuidor;
  public
    constructor Create(
      const ARepositorio: IRepositorioDistribuidor);
    function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
  end;

function CrearDistribuidorTallasVisualMto: IDistribuidorTallasVisual;
begin
  Result := nil;
  ValidarDependenciaConfiguracion(
    nil,
    'distribución de tallas');
end;

function CrearDistribuidorTallasVisualMto(
  const ARepositorio: IRepositorioDistribuidor
): IDistribuidorTallasVisual;
begin
  Result := TDistribuidorTallasVisualMto.Create(ARepositorio);
end;

constructor TDistribuidorTallasVisualMto.Create(
  const ARepositorio: IRepositorioDistribuidor);
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'distribución de tallas');
  FRepositorio := ARepositorio;
  inherited Create;
end;

function TDistribuidorTallasVisualMto.Ejecutar(
  const AParametros: TParametrosDistribuidorTallas): Boolean;
var
  oFormulario: TfrmModalDistribuidor;
begin
  oFormulario := TfrmModalDistribuidor.Create(
    Application,
    FRepositorio);
  oFormulario.OnClose := nil;
  try
    oFormulario.ConfigurarCeldas(
      AParametros.TablaCeldas,
      AParametros.CampoSerie,
      AParametros.CampoNumero,
      AParametros.CampoLinea,
      AParametros.CampoFila,
      AParametros.CampoAlmacen,
      AParametros.CampoAtributoValor,
      AParametros.CampoCantidad);
    oFormulario.Preparar(
      AParametros.Conexion,
      AParametros.Usuario,
      AParametros.Serie,
      AParametros.Numero,
      AParametros.Linea,
      AParametros.IdConjuntoPivot, '', '', AParametros.CodigoArticulo);
    oFormulario.ShowModal;
    Result := oFormulario.Confirmado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

constructor TfrmModalDistribuidor.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioDistribuidor);
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'distribución de tallas');
  FRepositorio := ARepositorio;
  inherited Create(AOwner);
end;

procedure TfrmModalDistribuidor.FormCreate(Sender: TObject);
begin
  inherited;
  FSnapshot  := TDictionary<string, Double>.Create;
  FKitPorPos := TDictionary<Integer, Double>.Create;
  // Defaults: celdas de SESIONES (comportamiento historico).
  FTablaCel     := 'fza_compras_sesiones_celdas';
  FSerieCelFld  := 'SERIE_SES_SESCEL';
  FNumeroCelFld := 'NUMERO_SES_SESCEL';
  FLineaCelFld  := 'LINEA_SES_SESCEL';
  FFilaCelFld   := 'ID_FILA_SES_SESCEL';
  FAlmCelFld    := 'CODIGO_ALM_SESCEL';
  FAvCelFld     := 'ID_AV_PIVOT_SESCEL';
  FCantCelFld   := 'CANTIDAD_SESCEL';
end;

procedure TfrmModalDistribuidor.ConfigurarCeldas(const ATabla, ASerie,
  ANumero, ALinea, AFila, AAlm, AAv, ACant: string);
begin
  FTablaCel     := ATabla;
  FSerieCelFld  := ASerie;
  FNumeroCelFld := ANumero;
  FLineaCelFld  := ALinea;
  FFilaCelFld   := AFila;
  FAlmCelFld    := AAlm;
  FAvCelFld     := AAv;
  FCantCelFld   := ACant;
end;

function TfrmModalDistribuidor.ConfiguracionPersistencia:
  TConfiguracionCeldasDistribuidor;
begin
  Result.Tabla := FTablaCel;
  Result.CampoSerie := FSerieCelFld;
  Result.CampoNumero := FNumeroCelFld;
  Result.CampoLinea := FLineaCelFld;
  Result.CampoFila := FFilaCelFld;
  Result.CampoAlmacen := FAlmCelFld;
  Result.CampoAtributoValor := FAvCelFld;
  Result.CampoCantidad := FCantCelFld;
end;

function TfrmModalDistribuidor.DocumentoPersistencia:
  TDocumentoDistribuidor;
begin
  Result.Serie := SerieSes;
  Result.Numero := NumeroSes;
  Result.Linea := LineaSes;
end;

procedure TfrmModalDistribuidor.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FKitPorPos);
  FreeAndNil(FSnapshot);
  inherited;
end;

procedure TfrmModalDistribuidor.DoShow;
var
  iCol: Integer;
begin
  // inherited dispara OnShow del ancestro que pone foco en btnAceptar.
  // Acto seguido lo redirigimos al grid: ponemos record activo en 0 y
  // columna activa en la primera focusable (las dos de etiqueta llevan
  // Focusing:=False, asi caemos en T01 = primera talla, fila 1 = primer
  // almacen). Experiencia Excel: el usuario teclea numero -> editor con
  // ImmediateEditor abre directamente.
  inherited;
  if (tvCuadr.DataController.RecordCount > 0) and (tvCuadr.ColumnCount > 0) then
  begin
    tvCuadr.Controller.FocusedRecordIndex := 0;
    // Tag=-1 marca la columna de acciones del modo kit: enfocable para
    // que sus botones reciban el click, pero NO debe ser el foco inicial.
    for iCol := 0 to tvCuadr.ColumnCount - 1 do
      if tvCuadr.Columns[iCol].Options.Focusing and
         (tvCuadr.Columns[iCol].Tag >= 0) then
      begin
        tvCuadr.Controller.FocusedColumnIndex := iCol;
        Break;
      end;
  end;
  if cxgrdCuadr.CanFocus then
    cxgrdCuadr.SetFocus;
end;

function TfrmModalDistribuidor.GetConfirmado: Boolean;
begin
  Result := sFicha = 'S';
end;

procedure TfrmModalDistribuidor.Preparar(AConn: TUniConnection;
                                          const AUsuario, ASerie,
                                                ANumero: string;
                                          ALinea, AIdAcPivot: Integer;
                                          const ACodigoPrvKit: string;
                                          const ACodigoKit: string;
                                          const AArticulo: string);
var
  oGestor : TGestorGridTallas;
  oCfg    : TGridTallasConfig;
begin
  ValidarDependenciaConfiguracion(
    FRepositorio,
    'distribución de tallas');
  FUsuario      := AUsuario;
  SerieSes      := ASerie;
  NumeroSes     := ANumero;
  LineaSes      := ALinea;
  FIdAcPivot    := AIdAcPivot;
  FCodigoPrvKit := ACodigoPrvKit;
  FCodigoKit    := ACodigoKit;
  edtLinea.Text := IntToStr(ALinea);
  // Reusamos el helper de gestor de tallas para obtener las
  // posiciones del conjunto pivot (T01..T20 con su AV).
  oCfg := Default(TGridTallasConfig);
  oCfg.Conexion := AConn;
  oCfg.Persistencia := CrearPersistenciaGridTallasInline(
    AConn, CrearConfigPersistenciaTallasInline(oCfg));
  oGestor := TGestorGridTallas.Create(oCfg);
  try
    FPosiciones := oGestor.GetPosicionesConjunto(AIdAcPivot, AArticulo);
  finally
    FreeAndNil(oGestor);
  end;
  if FCodigoKit <> '' then
  begin
    CargarKit;
    lblTitulo.Caption := Format(SCaptionDistribucionKit, [FCodigoKit]);
    btnKitTodos.Visible := True;
  end;
  PrepararEstructura;
  PoblarFilasYCantidades;
end;

procedure TfrmModalDistribuidor.PrepararEstructura;
var
  i: Integer;
  Columna: TcxGridDBColumn;
  Propiedades: TcxButtonEditProperties;
  Boton: TcxEditButton;
begin
  // Construimos un ClientDataSet en memoria con columnas:
  //   CODIGO_ALM | NOMBRE_ALM | T01..TN (Float)
  // donde N = Length(FPosiciones). Las columnas talla llevan el caption
  // del valor (AV) del conjunto pivot para que el usuario las reconozca.
  cdsCuadr.Close;
  cdsCuadr.FieldDefs.Clear;
  cdsCuadr.FieldDefs.Add('CODIGO_ALM', ftString, 10);
  cdsCuadr.FieldDefs.Add('NOMBRE_ALM', ftString, 100);
  for i := 0 to High(FPosiciones) do
    cdsCuadr.FieldDefs.Add(Format('T%.2d', [i + 1]), ftFloat);
  cdsCuadr.CreateDataSet;
  // Recreamos las columnas del cxGrid bound al cds. La columna almacen
  // es read-only; las tallas editables.
  tvCuadr.ClearItems;
  // Las dos primeras columnas son etiqueta (read-only). Focusing:=False
  // hace que Enter/Tab/Flechas las SALTEN, asi siempre caes en una talla
  // editable. Visualmente siguen apareciendo, solo no se puede aterrizar
  // en ellas via teclado ni click.
  Columna := tvCuadr.CreateColumn;
  Columna.DataBinding.FieldName := 'CODIGO_ALM';
  Columna.Caption := SCaptionAlmacenDistribuidorTallas;
  Columna.Options.Editing := False;
  Columna.Options.Focusing := False;
  Columna.Width := 70;
  Columna := tvCuadr.CreateColumn;
  Columna.DataBinding.FieldName := 'NOMBRE_ALM';
  Columna.Caption := SCaptionNombreDistribuidorTallas;
  Columna.Options.Editing := False;
  Columna.Options.Focusing := False;
  Columna.Width := 160;
  // Modo kit: columna de acciones (no-bound) con dos botones por
  // almacen — "Aplicar" vuelca la curva del kit sobre esa fila y
  // "Limpiar" pone a 0 todas sus tallas. isebAlways pinta los botones
  // en todas las filas sin necesidad de enfocar la celda. OJO: esta
  // version de DevExpress no tiene ButtonsViewStyle (E2003), asi que el
  // ancho de columna debe cubrir los dos botones + el area de texto del
  // editor o el segundo boton sale truncado.
  if FCodigoKit <> '' then
  begin
    Columna := tvCuadr.CreateColumn;
    Columna.Caption := Format(SCaptionColKit, [FCodigoKit]);
    Columna.PropertiesClass := TcxButtonEditProperties;
    Propiedades := TcxButtonEditProperties(Columna.Properties);
    Propiedades.ReadOnly := True;
    Propiedades.Buttons[0].Kind := bkText;
    Propiedades.Buttons[0].Caption := SCaptionAplicar;
    Propiedades.Buttons[0].Default := False;
    Propiedades.Buttons[0].Width := 78;
    Boton := Propiedades.Buttons.Add;
    Boton.Kind := bkText;
    Boton.Caption := SCaptionLimpiar;
    Boton.Width := 78;
    Propiedades.OnButtonClick := ColKitPropertiesButtonClick;
    Columna.Options.ShowEditButtons := isebAlways;
    // Tag=-1: DoShow la salta al decidir el foco inicial (que debe
    // caer en la primera talla, no en los botones).
    Columna.Tag := -1;
    Columna.Width := 190;
  end;
  for i := 0 to High(FPosiciones) do
  begin
    Columna := tvCuadr.CreateColumn;
    Columna.DataBinding.FieldName := Format('T%.2d', [i + 1]);
    Columna.Caption := FPosiciones[i].Valor;
    Columna.Width := 55;
  end;
end;

procedure TfrmModalDistribuidor.PoblarFilasYCantidades;
var
  aAlmacenes: TAlmacenesDistribuidor;
  aCeldas: TCeldasDistribuidor;
  oAlmacen: TAlmacenDistribuidor;
  oCelda: TCeldaDistribuidor;
  i: Integer;
  oPos: TDictionary<Integer, Integer>;
begin
  cdsCuadr.DisableControls;
  try
    aAlmacenes := FRepositorio.ListarAlmacenes;
    for oAlmacen in aAlmacenes do
    begin
      cdsCuadr.Append;
      cdsCuadr.FieldByName('CODIGO_ALM').AsString := oAlmacen.Codigo;
      cdsCuadr.FieldByName('NOMBRE_ALM').AsString := oAlmacen.Nombre;
      for i := 0 to High(FPosiciones) do
      begin
        cdsCuadr.FieldByName(Format('T%.2d', [i + 1])).AsFloat := 0;
      end;
      cdsCuadr.Post;
    end;
    oPos := TDictionary<Integer, Integer>.Create;
    try
      for i := 0 to High(FPosiciones) do
      begin
        oPos.AddOrSetValue(FPosiciones[i].IdAv, i + 1);
      end;
      aCeldas := FRepositorio.ListarCeldas(
        ConfiguracionPersistencia,
        DocumentoPersistencia);
      for oCelda in aCeldas do
      begin
        if (oCelda.CodigoAlmacen <> '') and
           oPos.ContainsKey(oCelda.IdAtributoValor) and
           cdsCuadr.Locate('CODIGO_ALM', oCelda.CodigoAlmacen, []) then
        begin
          cdsCuadr.Edit;
          cdsCuadr.FieldByName(Format(
            'T%.2d',
            [oPos[oCelda.IdAtributoValor]])).AsFloat := oCelda.Cantidad;
          cdsCuadr.Post;
          FSnapshot.AddOrSetValue(
            ClaveCelda(
              oCelda.CodigoAlmacen,
              oPos[oCelda.IdAtributoValor]),
            oCelda.Cantidad);
        end;
      end;
    finally
      FreeAndNil(oPos);
    end;
    cdsCuadr.First;
  finally
    cdsCuadr.EnableControls;
  end;
end;

function TfrmModalDistribuidor.ClaveCelda(const ACodigoAlm: string;
                                            APosicion: Integer): string;
begin
  Result := ACodigoAlm + '|' + IntToStr(APosicion);
end;

// ===========================================================================
//   Modo kit — aplicar / limpiar la curva del kit por almacen
// ===========================================================================

procedure TfrmModalDistribuidor.CargarKit;
var
  aValores: TValoresKitDistribuidor;
  oValor: TValorKitDistribuidor;
  i: Integer;
  sVal: string;
begin
  // Mapea el detalle del kit (texto de talla -> cantidad) a las
  // posiciones del conjunto pivot de la linea. El tallaje kit=linea ya
  // viene validado por el form (ValidarKitSobreLineaActual), asi que
  // practicamente todo casa; lo que no (tallas tecleadas a mano en el
  // kit fuera del conjunto) se ignora.
  FKitPorPos.Clear;
  aValores := FRepositorio.ListarValoresKit(
    FCodigoPrvKit,
    FCodigoKit);
  for oValor in aValores do
  begin
    sVal := Trim(oValor.ValorDestino);
    for i := 0 to High(FPosiciones) do
    begin
      if SameText(Trim(FPosiciones[i].Valor), sVal) then
      begin
        FKitPorPos.AddOrSetValue(i + 1, oValor.Cantidad);
        Break;
      end;
    end;
  end;
end;

procedure TfrmModalDistribuidor.AplicarKitEnFilaCds;
var
  i     : Integer;
  rCant : Double;
begin
  // Vuelca la curva del kit sobre la fila (almacen) actual del cds:
  // solo las tallas que el kit define; las demas se conservan (con
  // "Limpiar" primero se obtiene la curva exacta). La persistencia real
  // ocurre al Aceptar (PersistirCambios contra el snapshot), igual que
  // las cantidades tecleadas a mano.
  cdsCuadr.Edit;
  for i := 0 to High(FPosiciones) do
  begin
    if FKitPorPos.TryGetValue(i + 1, rCant) then
      cdsCuadr.FieldByName(Format('T%.2d', [i + 1])).AsFloat := rCant;
  end;
  cdsCuadr.Post;
end;

procedure TfrmModalDistribuidor.LimpiarFilaCds;
var
  i : Integer;
begin
  cdsCuadr.Edit;
  for i := 0 to High(FPosiciones) do
    cdsCuadr.FieldByName(Format('T%.2d', [i + 1])).AsFloat := 0;
  cdsCuadr.Post;
end;

function TfrmModalDistribuidor.SincronizarCdsConFoco: Boolean;
var
  oCol : TcxGridDBColumn;
  iRec : Integer;
  vVal : Variant;
begin
  // El click en el boton in-cell enfoca antes su fila; localizamos esa
  // fila en el cds (el cursor del cds sigue al foco en vistas DB, el
  // Locate es cinturon de seguridad por si difieren).
  Result := False;
  oCol := tvCuadr.GetColumnByFieldName('CODIGO_ALM');
  iRec := tvCuadr.Controller.FocusedRecordIndex;
  if (oCol <> nil) and (iRec >= 0) then
  begin
    vVal := tvCuadr.DataController.Values[iRec, oCol.Index];
    if not (VarIsNull(vVal) or VarIsEmpty(vVal)) then
      Result := cdsCuadr.Locate('CODIGO_ALM', VarToStr(vVal), []);
  end;
end;

procedure TfrmModalDistribuidor.ColKitPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if SincronizarCdsConFoco then
  begin
    if AButtonIndex = 0 then
      AplicarKitEnFilaCds
    else
      LimpiarFilaCds;
  end;
end;

procedure TfrmModalDistribuidor.btnKitTodosClick(Sender: TObject);
var
  bk : TBookmark;
begin
  inherited;
  // Aplica la curva del kit a TODOS los almacenes del cuadrante. Antes
  // bajamos el editor abierto (si lo hay) para no pisar un tecleo a
  // medias; despues PersistirCambios consolidara, como siempre, solo al
  // Aceptar.
  if (tvCuadr.Controller <> nil) and
     (tvCuadr.Controller.EditingController <> nil) then
    tvCuadr.Controller.EditingController.HideEdit(True);
  bk := cdsCuadr.GetBookmark;
  cdsCuadr.DisableControls;
  try
    cdsCuadr.First;
    while not cdsCuadr.Eof do
    begin
      AplicarKitEnFilaCds;
      cdsCuadr.Next;
    end;
    if cdsCuadr.BookmarkValid(bk) then
      cdsCuadr.GotoBookmark(bk);
  finally
    cdsCuadr.FreeBookmark(bk);
    cdsCuadr.EnableControls;
  end;
end;

procedure TfrmModalDistribuidor.PersistirCambios;
var
  sCod: string;
  i, iRec: Integer;
  iIdAv: Integer;
  rCantN: Double;
  rCantO: Double;
  sKey: string;
  vVal: Variant;
  iColCod: Integer;
  iColT: array of Integer;
  oCambio: TCambioCeldaDistribuidor;
  oCambios: TList<TCambioCeldaDistribuidor>;
begin
  // IMPORTANTE: leemos del DataController del cxGrid (Values[record,col])
  // NO del cds. El cxGrid mantiene el valor tecleado en el buffer de su
  // editor / data controller y no siempre lo baja al cds (especialmente
  // con AlwaysShowEditor=True: la celda en edicion al pulsar Aceptar no
  // hace OnExit y el valor se queda en el buffer del view). Leyendo
  // Values[] directamente cogemos el valor REAL aunque el cds aun lo
  // tenga a 0. Esto fue la causa raiz del bug 'el distribuidor no
  // consolida cambios'.
  // Resolvemos los Index de columnas via GetColumnByFieldName (mas
  // fiable que iterar Items y castear). El Index devuelto es el que
  // espera DataController.Values[recIdx, colIdx].
  iColCod := -1;
  if tvCuadr.GetColumnByFieldName('CODIGO_ALM') <> nil then
    iColCod := tvCuadr.GetColumnByFieldName('CODIGO_ALM').Index;
  SetLength(iColT, Length(FPosiciones));
  for i := 0 to High(FPosiciones) do
  begin
    iColT[i] := -1;
    sKey := Format('T%.2d', [i + 1]);
    if tvCuadr.GetColumnByFieldName(sKey) <> nil then
      iColT[i] := tvCuadr.GetColumnByFieldName(sKey).Index;
  end;
  // DIAGNOSTICO: con appLogAvanzado=True estas lineas salen al log.
  RegistroLog.RegistrarInformacion(Format(
    '[Distribuidor.PersistirCambios] iColCod=%d records=%d posiciones=%d',
    [iColCod, tvCuadr.DataController.RecordCount, Length(FPosiciones)]));
  for i := 0 to High(iColT) do
    RegistroLog.RegistrarInformacion(Format('  iColT[%d]=%d', [i, iColT[i]]));
  if iColCod >= 0 then
  begin
  oCambios := TList<TCambioCeldaDistribuidor>.Create;
  try
    for iRec := 0 to tvCuadr.DataController.RecordCount - 1 do
    begin
      vVal := tvCuadr.DataController.Values[iRec, iColCod];
      if not VarIsNull(vVal) and not VarIsEmpty(vVal) then
      begin
        sCod := VarToStr(vVal);
        if sCod <> '' then
        begin
          for i := 0 to High(FPosiciones) do
          begin
            if iColT[i] >= 0 then
            begin
              iIdAv  := FPosiciones[i].IdAv;
              vVal   := tvCuadr.DataController.Values[iRec, iColT[i]];
              if VarIsNull(vVal) or VarIsEmpty(vVal) then
                rCantN := 0
              else
                rCantN := vVal;
              sKey := ClaveCelda(sCod, i + 1);
              if not FSnapshot.TryGetValue(sKey, rCantO) then
                rCantO := 0;
              RegistroLog.RegistrarInformacion(Format(
                '  rec=%d alm=%s pos=%d (T%.2d) idav=%d ' +
                'val_actual=%g snapshot=%g',
                [iRec, sCod, i + 1, i + 1, iIdAv, rCantN, rCantO]));
              if rCantN <> rCantO then
              begin
                oCambio.CodigoAlmacen := sCod;
                oCambio.IdAtributoValor := iIdAv;
                oCambio.Cantidad := rCantN;
                oCambios.Add(oCambio);
              end;
            end;
          end;
        end;
      end;
    end;
    FRepositorio.GuardarCambios(
      ConfiguracionPersistencia,
      DocumentoPersistencia,
      FUsuario,
      oCambios.ToArray);
  finally
    FreeAndNil(oCambios);
  end;
  end;
end;

function TfrmModalDistribuidor.CloseQuery: Boolean;
begin
  // sFicha ya viene asignado por el ancestro:
  //   'S' tras btnAceptarClick / Action1 (F12)
  //   'N' tras Action2 (ESC)
  // Solo persistimos en confirmacion. La cadena de commits del cxGrid
  // (HideEdit + UpdateData + Post) se hace AQUI: el form aun esta visible
  // y el editor sigue activo, asi que la ultima celda en edicion baja
  // correctamente al DataController antes de leerla.
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    RegistroLog.RegistrarInformacion(Format(
      '[Distribuidor.CloseQuery] sFicha=S serie=%s num=%s lin=%d',
      [SerieSes, NumeroSes, LineaSes]));
    if (tvCuadr.Controller <> nil) and
       (tvCuadr.Controller.EditingController <> nil) then
      tvCuadr.Controller.EditingController.HideEdit(True);
    tvCuadr.DataController.UpdateData;
    tvCuadr.DataController.Post(False);
    if cdsCuadr.State in [dsEdit, dsInsert] then
      cdsCuadr.Post;
    PersistirCambios;
  end;
end;

procedure TfrmModalDistribuidor.btnCancelarClick(Sender: TObject);
begin
  // El ancestro no asigna OnClick a btnCancelar (solo lo cubre via
  // Cancel:=True / Action2 con shortcut ESC); aqui lo enganchamos para
  // que el click del boton tambien cierre con sFicha='N'.
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.

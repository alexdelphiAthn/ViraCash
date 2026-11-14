{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaParam                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de mantenimiento de parametros de caja.                        }
{    Editor tipo inspector con categorias para la configuracion del TPV.       }
{******************************************************************************}
unit inMtoCajaParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections,
  System.Generics.Defaults,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxFilter, dxScrollbarAnnotations, cxEdit,
  cxCheckBox, cxInplaceContainer, cxTextEdit, cxContainer,
  inLibGlobalVar, dxCoreGraphics, cxMaskEdit, cxButtonEdit, cxSpinEdit,
  Vcl.ExtCtrls, inMtoFrmBase, cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons, JvComponentBase, JvInspector, JvExControls, System.Actions,
  Vcl.ActnList, Vcl.Printers, System.UITypes, inLibParametrosIntf,
  inLibAppParamPersistenciaIntf, inLibPermisosIntf,
  inLibCajaPantallaInyeccion;

type
  // Tipos de punteros necesarios para la generación dinámica en JvInspector
  PBoolean = ^Boolean;
  PInteger = ^Integer;
  PString  = ^String;

  TfrmMtoCajaParam = class(TFrmBase)
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    Panel2: TPanel;
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    JvInspector1: TJvInspector;
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;
    ActionList1: TActionList;
    actGuardar: TAction;
    actSalir: TAction;
    actGuardarLayout: TAction;

    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
                                                 AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject;
                                 var Key: Word;
                                 Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
    procedure actGuardarExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject;
                          var Key: Word;
                          Shift: TShiftState);
  private
    // Listas para gestionar la memoria dinámica de los parámetros
    FBools: TList<PBoolean>;
    FInts:  TList<PInteger>;
    FStrs:  TList<PString>;
    FValoresOriginales: TDictionary<string, string>;
    FParametrosEdicion: IParametrosEdicion;
    FRepositorioPersistencia: IRepositorioAppParam;
    procedure CapturarValoresOriginales;
    function  HayCambiosPendientes: Boolean;
    procedure LimpiarMemoria;
    procedure ResetearADefectos;
    function  ObtenerCategoria(
      const AClave, ATexto: string): TJvInspectorCustomCategoryItem;
    function  QuitarTildes(const Texto: string): string;
    function  BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                                  const Nombre: string): TJvCustomInspectorItem;
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    procedure CargarParametros(Grid: TJvInspector;
                               const pUsuario,
                               pGrupo: string);
    function ParametrosVisibles: TArray<TParamInfo>;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure GetAmbitosCanjeValeList(Sender: TJvCustomInspectorItem;
      Strings: TStrings);
    procedure GetTipoImpresionList(Sender: TJvCustomInspectorItem;
                                   Strings: TStrings);
    procedure GetImpresorasList(Sender: TJvCustomInspectorItem;
                                Strings: TStrings);
    procedure GetTarifasList(Sender: TJvCustomInspectorItem;
                             Strings: TStrings);
    procedure GetFormatosTicketList(Sender: TJvCustomInspectorItem;
                                    Strings: TStrings);
    // Fila con botón "..." junto al formato del ticket: abre el selector de
    // formatos 'Ticket...' y el diseñador (como Editar en imprimir factura).
    procedure AnadirEditorFormatosTicket(
      ACategoria: TJvInspectorCustomCategoryItem);
    procedure InspectorItemEdit(Sender: TJvCustomInspector;
      Item: TJvCustomInspectorItem; var DisplayStr: string);
  private
    FEditarFormatosTicket: TProc;
  protected
    procedure ConstruirInspector;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasParametrosCaja); reintroduce;
      overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl, inLibInspectorSkin,
  StrUtils, inLibLayoutForm, inLibMsgCaja, inLibCajaParam,
  inLibTrazabilidad;

const
  cItemEditarFormatosTicket = 'EditarFormatosTicket';

resourcestring
  SDescripcionPersonalizacionParametrosCaja =
    'Personalización Parámetros Caja';

constructor TfrmMtoCajaParam.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasParametrosCaja);
begin
  ADependencias.Validar;
  FParametrosEdicion := ADependencias.Edicion;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FEditarFormatosTicket := ADependencias.EditarFormatosTicket;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoCajaParam.AnadirEditorFormatosTicket(
  ACategoria: TJvInspectorCustomCategoryItem);
var
  pTexto: PString;
  Item: TJvCustomInspectorItem;
begin
  if not Assigned(FEditarFormatosTicket) then
    Exit;
  New(pTexto);
  FStrs.Add(pTexto);
  pTexto^ := SPulsarEditarFormatosTicket;
  Item := TJvInspectorVarData.New(ACategoria, cItemEditarFormatosTicket,
    TypeInfo(string), pTexto);
  Item.DisplayName := SEditarFormatosTicket;
  Item.Flags := Item.Flags + [iifEditButton, iifEditFixed];
  JvInspector1.OnItemEdit := InspectorItemEdit;
end;

procedure TfrmMtoCajaParam.InspectorItemEdit(Sender: TJvCustomInspector;
  Item: TJvCustomInspectorItem; var DisplayStr: string);
begin
  if SameText(Item.Name, cItemEditarFormatosTicket) and
     Assigned(FEditarFormatosTicket) then
  begin
    FEditarFormatosTicket();
    DisplayStr := SPulsarEditarFormatosTicket;
  end;
end;

// ----------------------------------------------------------------------
// GESTIÓN DE MEMORIA Y CICLO DE VIDA
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.FormCreate(Sender: TObject);
var
  Dependencias: TDependenciasParametrosCaja;
begin
  inherited;
  Dependencias.Edicion := FParametrosEdicion;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.Validar;
  if jvntrstb1 <> nil then
    jvntrstb1.EnterAsTab := False;
  FBools := TList<PBoolean>.Create;
  FInts  := TList<PInteger>.Create;
  FStrs  := TList<PString>.Create;
  FValoresOriginales := TDictionary<string, string>.Create;
  AplicarPintorSkin(JvInspector1, JvInspectorDotNETPainter1);
end;

procedure TfrmMtoCajaParam.FormKeyDown(Sender: TObject;
                                       var Key: Word;
                                       Shift: TShiftState);
var
  ControlActivo: TWinControl;
  EsBoton      : Boolean;
  EsInspector  : Boolean;
begin
  if (Key = VK_RETURN) and
     (not (ssCtrl in Shift)) and
     (not (ssAlt in Shift)) then
  begin
    ControlActivo := Screen.ActiveControl;
    EsBoton       := (ControlActivo <> nil) and
                     (ControlActivo is TcxButton);
    EsInspector   := (ControlActivo <> nil) and
                     ((ControlActivo = JvInspector1) or
                      JvInspector1.ContainsControl(ControlActivo));
    if (not EsBoton) and (not EsInspector) then
    begin
      Key := 0;
      if ActiveControl <> nil then
        SelectNext(ActiveControl, not (ssShift in Shift), True)
      else
        SelectNext(Self, True, True);
    end;
  end;
end;

procedure TfrmMtoCajaParam.FormDestroy(Sender: TObject);
begin
  FParametrosEdicion := nil;
  FRepositorioPersistencia := nil;
  LimpiarMemoria;
  FreeAndNil(FBools);
  FreeAndNil(FInts);
  FreeAndNil(FStrs);
  FreeAndNil(FValoresOriginales);
  inherited;
end;

procedure TfrmMtoCajaParam.CapturarValoresOriginales;
var
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorExtraido: string;
begin
  FValoresOriginales.Clear;
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
    begin
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        if ParamItem.Data <> nil then
        begin
          case ParamItem.Data.TypeInfo.Kind of
            tkEnumeration:
              if ParamItem.Data.AsOrdinal <> 0 then ValorExtraido :=
                'True' else ValorExtraido := 'False';
            tkInteger:
              ValorExtraido := IntToStr(ParamItem.Data.AsOrdinal);
            else
              ValorExtraido := ParamItem.Data.AsString;
          end;
          FValoresOriginales.AddOrSetValue(ParamItem.Name, ValorExtraido);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaParam.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoCajaParam.LimpiarMemoria;
var
  pB: PBoolean; pI: PInteger; pS: PString;
begin
  // Liberamos la memoria de los punteros que asignamos a JvInspector.
  // Es vital tiparlos (Dispose) para que los strings decremente su contador de
  // referencias.
  for pB in FBools do Dispose(pB);
  FBools.Clear;

  for pI in FInts do Dispose(pI);
  FInts.Clear;

  for pS in FStrs do Dispose(pS);
  FStrs.Clear;
end;

// ----------------------------------------------------------------------
// CONSTRUCCIÓN DINÁMICA DE LA INTERFAZ
// ----------------------------------------------------------------------

function TfrmMtoCajaParam.ObtenerCategoria(
  const AClave, ATexto: string): TJvInspectorCustomCategoryItem;
begin
  Result := ObtenerCategoriaInspector(JvInspector1, AClave, ATexto);
end;

function TfrmMtoCajaParam.ParametrosVisibles: TArray<TParamInfo>;
var
  Activacion: TActivacionTrazabilidad;
  Param: TParamInfo;
begin
  // F-LOTEC: los parámetros de lotes y series solo aparecen con su
  // interruptor de aplicación encendido. Al no estar en el inspector
  // tampoco se guardan, así que conservan su valor.
  Activacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  Result := [];
  for Param in FParametrosEdicion.ListarDefiniciones do
  begin
    if Activacion.ParametroVisible(Param.Nombre) then
      Result := Result + [Param];
  end;
end;

procedure TfrmMtoCajaParam.ConstruirInspector;
var
  Parametros: TArray<TParamInfo>;
  Param: TParamInfo;
  CatItem: TJvInspectorCustomCategoryItem;
  ItemCombo: TJvCustomInspectorItem;
  DescripcionTraducida: string;
  pBool: PBoolean; pInt: PInteger; pStr: PString;
begin
  LimpiarMemoria;
  Parametros := ParametrosVisibles;
  // Orden canónico: traducir un rótulo no desplaza ni agrupa otras filas.
  TArray.Sort<TParamInfo>(Parametros, TComparer<TParamInfo>.Construct(
    function(const A, B: TParamInfo): Integer
    begin
      Result := CompareText(A.Categoria, B.Categoria);
      if Result = 0 then
        Result := CompareText(A.Descripcion, B.Descripcion);
      if Result = 0 then
        Result := CompareText(A.Nombre, B.Nombre);
    end));
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;

    // La instantánea evita exponer el diccionario interno al editor.
    for Param in Parametros do
    begin
      CatItem := ObtenerCategoria(
        Param.Categoria,
        TraducirCategoriaParametro(
          'inMtoCajaParam',
          Param.Categoria));
      DescripcionTraducida :=
        TraducirDescripcionParametro(
          'inMtoCajaParam',
          Param);

      case Param.Tipo of
        tpBoolean:
          begin
            New(pBool);
            FBools.Add(pBool);
            pBool^ := SameText(Param.ValorPorDefecto,
                               'True') or (Param.ValorPorDefecto = '1');
            ItemCombo := TJvInspectorVarData.New(CatItem,
                                                 Param.Nombre,
                                                 TypeInfo(Boolean),
                                                 pBool);
            ItemCombo.DisplayName := DescripcionTraducida;
          end;
        tpInteger:
          begin
            New(pInt);
            FInts.Add(pInt);
            pInt^ := StrToIntDef(Param.ValorPorDefecto, 0);
            ItemCombo := TJvInspectorVarData.New(CatItem,
                                                 Param.Nombre,
                                                 TypeInfo(Integer),
                                                 pInt);
            ItemCombo.DisplayName := DescripcionTraducida;
          end;
        tpString:
          begin
            New(pStr);
            FStrs.Add(pStr);
            pStr^ := Param.ValorPorDefecto;
            ItemCombo := TJvInspectorVarData.New(CatItem,
                                                 Param.Nombre,
                                                 TypeInfo(string),
                                                 pStr);
            ItemCombo.DisplayName := DescripcionTraducida;
            if SameText(Param.Nombre, 'vgerAmbitoCanjeVale') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetAmbitosCanjeValeList;
            end
            else if SameText(Param.Nombre, 'vgerTipoImpresion') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetTipoImpresionList;
            end
            else if SameText(Param.Nombre, 'vgerDefPrinter') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList,
                                                         iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetImpresorasList;
            end
            else if SameText(Param.Nombre, 'vgerDefTarifa') then
            begin
              // Única definición de la tarifa por defecto del sistema.
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList,
                                                         iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetTarifasList;
            end
            else if SameText(Param.Nombre, cParametroFormatoTicket) then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetFormatosTicketList;
              AnadirEditorFormatosTicket(CatItem);
            end;
          end;
      end;
    end;
  finally
    JvInspector1.EndUpdate;
  end;
end;

// ----------------------------------------------------------------------
// LAYOUT (geometría + divider del inspector)
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarDividerInspector('Divider', JvInspector1);
    if Layout.PreguntarYGrabar(
         SDescripcionPersonalizacionParametrosCaja) then
      ShowMessage_fza(SInfoLayoutCajaGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoCajaParam.RestaurarLayout;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  try
    if Layout.Disponible then
    begin
      Layout.RestaurarGeometria(Self);
      Layout.RestaurarDividerInspector('Divider', JvInspector1);
    end;
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoCajaParam.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayout;
end;

// ----------------------------------------------------------------------
// CARGA Y GUARDADO (LÓGICA GENÉRICA)
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.ResetearADefectos;
var
  Parametros: TArray<TParamInfo>;
  Param: TParamInfo;
  ItemData: TJvCustomInspectorItem;
begin
  // Fuerza a los controles visuales a mostrar el valor por defecto antes de
  // cargar de DB
  Parametros := FParametrosEdicion.ListarDefiniciones;
  for Param in Parametros do
  begin
    ItemData := BuscarItemPorNombre(JvInspector1.Root, Param.Nombre);
    if ItemData <> nil then
      ItemData.DisplayValue := Param.ValorPorDefecto;
  end;
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TJvInspector;
                                            const pUsuario,
                                            pGrupo: string);
var
  Valores: TValoresPerfilAppParam;
  ValorPerfil: TValorPerfilAppParam;
  SubKey, ValorStr: string;
  ItemData: TJvCustomInspectorItem;
begin
  ResetearADefectos;
  Grid.Refresh;
  Valores := FRepositorioPersistencia.CargarValores(
    pUsuario,
    pGrupo,
    'frmMtoCajaParam');
  Grid.BeginUpdate;
  try
    for ValorPerfil in Valores do
    begin
      SubKey := ValorPerfil.Subclave;
      ValorStr := ValorPerfil.Valor;
      ItemData := BuscarItemPorNombre(Grid.Root, SubKey);
      if (ItemData <> nil) and (ItemData.Data <> nil) then
      begin
        try
          if (ValorStr = '') and
             (ItemData.Data.TypeInfo.Kind in [tkInteger, tkFloat]) then
            ValorStr := '0';
          ItemData.DisplayValue := ValorStr;
        except
          // El resto de parametros del perfil se sigue aplicando.
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'CajaParam: no se pudo aplicar el parametro "' +
              SubKey + '": ' + E.Message);
        end;
      end;
    end;
  finally
    Grid.EndUpdate;
  end;
  CapturarValoresOriginales;
end;

procedure TfrmMtoCajaParam.btnGuardarClick(Sender: TObject);
var
  ValoresGuardar: TValoresPerfilAppParam;
  ValorGuardado: TValorPerfilAppParam;
  sUsuarioGrupo: string;
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorAGuardar: string;
  GuardadosCount: Integer;
  CambioReal: Boolean;
begin
  JvInspector1.SaveValues;
  if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    sUsuarioGrupo := cmbGrupoUsuario.Text;
    GuardadosCount := 0;
    SetLength(ValoresGuardar, 0);
    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      NodoPrincipal := JvInspector1.Root.Items[i];
      if NodoPrincipal is TJvInspectorCustomCategoryItem then
      begin
        for j := 0 to NodoPrincipal.Count - 1 do
        begin
          ParamItem := NodoPrincipal.Items[j];
          // La fila del editor de tickets es un botón, no un parámetro.
          if SameText(ParamItem.Name, cItemEditarFormatosTicket) then
            Continue;
          if ParamItem.Data <> nil then
          begin
            case ParamItem.Data.TypeInfo.Kind of
              tkEnumeration:
                if ParamItem.Data.AsOrdinal <> 0 then ValorAGuardar :=
                  'True' else ValorAGuardar := 'False';
              tkInteger:
                ValorAGuardar := IntToStr(ParamItem.Data.AsOrdinal);
              else
                ValorAGuardar := ParamItem.Data.AsString;
            end;
          end
          else
            ValorAGuardar := '';
          CambioReal := True;
          if FValoresOriginales.ContainsKey(ParamItem.Name) then
            CambioReal := not SameText(
              FValoresOriginales[ParamItem.Name],
              ValorAGuardar);
          if CambioReal then
          begin
            SetLength(ValoresGuardar, Length(ValoresGuardar) + 1);
            ValoresGuardar[High(ValoresGuardar)].Subclave :=
              ParamItem.Name;
            ValoresGuardar[High(ValoresGuardar)].Valor :=
              ValorAGuardar;
            Inc(GuardadosCount);
          end;
        end;
      end;
    end;
    if Length(ValoresGuardar) > 0 then
    begin
      FRepositorioPersistencia.GuardarValores(
        sUsuarioGrupo,
        'frmMtoCajaParam',
        ValoresGuardar);
      for ValorGuardado in ValoresGuardar do
      begin
        FValoresOriginales.AddOrSetValue(
          ValorGuardado.Subclave,
          ValorGuardado.Valor);
      end;
    end;
    if GuardadosCount > 0 then
    begin
      ShowMessage_fza(Format(SInfoParametrosCajaGuardados,
                         [GuardadosCount, sUsuarioGrupo]));
      if (sUsuarioGrupo = IdentidadSesion.Usuario) or
         (sUsuarioGrupo = IdentidadSesion.Grupo) or
         (sUsuarioGrupo = oAll) then
        FParametrosEdicion.Recargar(
          IdentidadSesion.Usuario,
          IdentidadSesion.Grupo
        );
    end
    else
    begin
      ShowMessage_fza(SInfoParametrosCajaSinCambios);
    end;
  end;
end;

procedure TfrmMtoCajaParam.FormShow(Sender: TObject);
var
  Ambitos: TCadenasAppParam;
  s: string;
begin
  ConstruirInspector;
  cmbGrupoUsuario.Properties.Items.Clear;
  // Todo usuario gestiona sus propios parametros (IdentidadSesion.Usuario) y
  // los de su
  // grupo (IdentidadSesion.Grupo), y puede consultar los de 'Todos' (oAll) en
  // modo
  // solo lectura (lo aplica cmbGrupoUsuarioPropertiesChange).
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Usuario);
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Grupo);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  // Solo los administradores ven ademas la lista completa de usuarios y
  // grupos del sistema (y pueden editarla).
  if IdentidadSesion.GrupoRaiz = 'S' then
  begin
    Ambitos := FRepositorioPersistencia.ListarAmbitos;
    for s in Ambitos do
    begin
      if cmbGrupoUsuario.Properties.Items.IndexOf(s) < 0 then
      begin
        cmbGrupoUsuario.Properties.Items.Add(s);
      end;
    end;
  end;
  cmbGrupoUsuario.Visible := True;
  cmbGrupoUsuario.ItemIndex := 0;
  btnChangeId.Visible := False;
  RestaurarLayout;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

procedure TfrmMtoCajaParam.GetImpresorasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  i: Integer;
begin
  Strings.Clear;
  Strings.Add('');  // opción vacía: "sin impresora asignada"
  for i := 0 to Printer.Printers.Count - 1 do
    Strings.Add(Printer.Printers[i]);
end;

procedure TfrmMtoCajaParam.GetTipoImpresionList(Sender: TJvCustomInspectorItem;
                                                Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('ESC POS');
  Strings.Add('ESC POS NOQR');
  Strings.Add('EDITOR');
  Strings.Add('DEBUG');
end;

procedure TfrmMtoCajaParam.GetAmbitosCanjeValeList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('TODOS');
  Strings.Add('ALMACEN');
  Strings.Add('CAJA');
end;

procedure TfrmMtoCajaParam.GetFormatosTicketList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  Formato: string;
begin
  Strings.Clear;
  Strings.Add('');  // vacío: ticket ESC/POS de texto
  for Formato in FRepositorioPersistencia.ListarFormatosInforme(
    'frmPrintFac', cPrefijoFormatoTicket) do
    Strings.Add(Formato);
end;

procedure TfrmMtoCajaParam.GetTarifasList(Sender: TJvCustomInspectorItem;
                                          Strings: TStrings);
var
  Tarifas: TCadenasAppParam;
  Tarifa: string;
begin
  Strings.Clear;
  Tarifas := FRepositorioPersistencia.ListarTarifas;
  for Tarifa in Tarifas do
  begin
    Strings.Add(Tarifa);
  end;
end;

function TfrmMtoCajaParam.BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                                              const Nombre: string
): TJvCustomInspectorItem;
var
  i: Integer; Encontrado: TJvCustomInspectorItem;
begin
  Result := nil;
  for i := 0 to ItemPadre.Count - 1 do
  begin
    if Result = nil then
    begin
      if SameText(ItemPadre.Items[i].Name, Nombre) then
        Result := ItemPadre.Items[i]
      else if ItemPadre.Items[i] is TJvInspectorCustomCategoryItem then
      begin
        Encontrado := BuscarItemPorNombre(ItemPadre.Items[i], Nombre);
        if Encontrado <> nil then
          Result := Encontrado;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
  bSoloLectura: Boolean;
begin
  if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    case cmbGrupoUsuario.ItemIndex of
      0: begin sUsuario := IdentidadSesion.Usuario;  sGrupo := '';      end;
      1: begin sUsuario := '';     sGrupo := IdentidadSesion.Grupo;  end;
      2: begin sUsuario := '';     sGrupo := oAll;    end;
    else
      begin
        // Sujeto del desplegable completo (solo visible a administradores):
        // se carga por su nombre tal cual.
        sUsuario := cmbGrupoUsuario.Text;
        sGrupo   := '';
      end;
    end;
    CargarParametros(JvInspector1, sUsuario, sGrupo);
    // Un usuario normal edita lo suyo y lo de su grupo; los parametros de
    // 'Todos' (y cualquier otro sujeto) solo los ve en modo lectura. Los
    // administradores editan todo.
    bSoloLectura := (IdentidadSesion.GrupoRaiz <> 'S') and
                    (not SameText(cmbGrupoUsuario.Text,
                                  IdentidadSesion.Usuario)) and
                    (not SameText(cmbGrupoUsuario.Text, IdentidadSesion.Grupo));
    JvInspector1.ReadOnly := bSoloLectura;
    btnGuardar.Enabled    := not bSoloLectura;
    actGuardar.Enabled    := not bSoloLectura;
  end;
end;

procedure TfrmMtoCajaParam.actGuardarExecute(Sender: TObject);
begin
  inherited;
  btnGuardarClick(Sender);
  Close;
end;

procedure TfrmMtoCajaParam.actSalirExecute(Sender: TObject);
begin
  inherited;
  // Solo pedimos confirmación si hay cambios reales sin guardar
  if not HayCambiosPendientes then
    Close
  else if MessageDlg_fza(SPreguntaSalirParametrosCajaSinGuardar,
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Close;
end;

function TfrmMtoCajaParam.HayCambiosPendientes: Boolean;
var
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorActual: string;
begin
  // Recorremos los items igual que en btnGuardarClick comparando contra los
  // valores capturados al cargar; basta un cambio para devolver True
  Result := False;
  if FValoresOriginales <> nil then
  begin
    JvInspector1.SaveValues;
    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      if not Result then
      begin
        NodoPrincipal := JvInspector1.Root.Items[i];
        if NodoPrincipal is TJvInspectorCustomCategoryItem then
        begin
          for j := 0 to NodoPrincipal.Count - 1 do
          begin
            if not Result then
            begin
              ParamItem := NodoPrincipal.Items[j];
              if ParamItem.Data <> nil then
              begin
                case ParamItem.Data.TypeInfo.Kind of
                  tkEnumeration:
                    if ParamItem.Data.AsOrdinal <> 0 then
                      ValorActual := 'True'
                    else
                      ValorActual := 'False';
                  tkInteger:
                    ValorActual := IntToStr(ParamItem.Data.AsOrdinal);
                else
                  ValorActual := ParamItem.Data.AsString;
                end;
              end
              else
                ValorActual := '';
              if FValoresOriginales.ContainsKey(ParamItem.Name) then
                Result := not SameText(
                  FValoresOriginales[ParamItem.Name], ValorActual)
              else
                Result := ValorActual <> '';
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaParam.btnChangeIdClick(Sender: TObject);
var
  Ambitos: TCadenasAppParam;
  Ambito: string;
  usuarios: TStringList;
  sUsuario: string;
begin
  usuarios := TStringList.Create;
  try
    Ambitos := FRepositorioPersistencia.ListarAmbitos;
    for Ambito in Ambitos do
    begin
      usuarios.Add(Ambito);
    end;

    if usuarios.Count = 0 then
    begin
      ShowMessage_fza(SInfoUsuariosParametrosCajaNoEncontrados);
    end
    else
    begin
      sUsuario := usuarios[0];
      if InputQuery_fza(STituloCambiarUsuarioParametrosCaja,
        Format(SSolicitudCambiarUsuarioParametrosCaja,
          [usuarios.CommaText]), sUsuario) then
      begin
        if usuarios.IndexOf(sUsuario) < 0 then
          ShowMessage_fza(Format(SErrorUsuarioParametrosCajaNoEncontrado,
            [sUsuario]))
        else
        begin
          CargarParametros(JvInspector1, sUsuario, '');
          if cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario) < 0 then
            cmbGrupoUsuario.Properties.Items.Add(sUsuario);
          cmbGrupoUsuario.ItemIndex :=
            cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario);
        end;
      end;
    end;
  finally
    FreeAndNil(usuarios);
  end;
end;

function TfrmMtoCajaParam.QuitarTildes(const Texto: string): string;
var i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
    case Result[i] of
      'á', 'à', 'ä', 'â': Result[i] := 'a';
      'é', 'è', 'ë', 'ê': Result[i] := 'e';
      'í', 'ì', 'ï', 'î': Result[i] := 'i';
      'ó', 'ò', 'ö', 'ô': Result[i] := 'o';
      'ú', 'ù', 'ü', 'û': Result[i] := 'u';
      'Á', 'À', 'Ä', 'Â': Result[i] := 'A';
      'É', 'È', 'Ë', 'Ê': Result[i] := 'E';
      'Í', 'Ì', 'Ï', 'Î': Result[i] := 'I';
      'Ó', 'Ò', 'Ö', 'Ô': Result[i] := 'O';
      'Ú', 'Ù', 'Ü', 'Û': Result[i] := 'U';
    end;
end;

procedure TfrmMtoCajaParam.FiltrarVerticalGrid(Grid: TJvInspector;
                                               Texto: string);
var
  TextoBusquedaLimpio: string;
  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var Coincide, HijoVisible: Boolean; i: Integer;
  begin
    Coincide := (Texto = '') or (AnsiContainsText(QuitarTildes(Row.DisplayName),
                                                  TextoBusquedaLimpio));
    HijoVisible := False;
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    Row.Visible := Coincide or HijoVisible;
    if (Row is TJvInspectorCustomCategoryItem) and HijoVisible
       and (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;
var i: Integer;
begin
  Grid.BeginUpdate;
  try
    TextoBusquedaLimpio := QuitarTildes(Texto);
    for i := 0 to Grid.Root.Count - 1 do
      ProcesarFila(Grid.Root.Items[i]);
  finally
    Grid.EndUpdate;
  end;
end;

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoCajaParam.edtBusquedaKeyDown(Sender: TObject;
                                              var Key: Word;
                                              Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

end.

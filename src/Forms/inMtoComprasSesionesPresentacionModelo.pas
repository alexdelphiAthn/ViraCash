{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionModelo                        }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Busqueda incremental de modelos del proveedor sobre la columna            }
{    "Modelo prov." y reutilizacion de articulos ya existentes al teclear      }
{    codigo o referencia. La familia conserva el codigo ya elegido.           }
{    El debounce y la resolucion diferida viven en                            }
{    inLibComprasSesionesPresentacion; aqui                                   }
{    solo queda el efecto sobre el grid y los datasets.                        }
{                                                                              }
{    Recibe un entorno explicito con las capacidades que usa. No conoce el     }
{    formulario de sesiones ni ningun contexto general de repositorios.        }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionModelo;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  Uni,
  Vcl.Controls,
  cxEdit,
  cxDropDownEdit,
  cxEditRepositoryItems,
  cxDBExtLookupComboBox,
  cxGrid,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPresentacionIntf,
  inLibComprasSesionesPresentacion;

type
  TOrigenGeneracionCodigoArticuloSesion = (
    ogcaFamilia,
    ogcaModelo);

  TGenerarCodigoArticuloSesion = reference to function(
    AOrigen: TOrigenGeneracionCodigoArticuloSesion): Boolean;

  TSolicitarDecisionCodigoSesion = reference to function(
    const ADuplicado: TResolverDuplicadoSesion;
    out ACodigoNuevo: string): string;

  TEntornoModeloProveedorSesion = record
    Propietario: TComponent;
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Vista: TcxGridDBTableView;
    ColumnaModelo: TcxGridDBColumn;
    RefrescarTallas: TProc;
    FijarTallajeDefecto: TProc<Integer>;
    // La línea actual reutiliza el modelo de la línea indicada: se ofrece
    // copiar su distribución de cantidades (fuera del editor in-place).
    OfrecerDistribucion: TProc<Integer>;
    GenerarCodigoArticulo: TGenerarCodigoArticuloSesion;
    SolicitarDecisionCodigo: TSolicitarDecisionCodigoSesion;
    RegistrarAviso: TProc<string>;
  end;

  TBuscadorModeloProveedorSesion = class
  private
    FEntorno: TEntornoModeloProveedorSesion;
    FNucleo: TNucleoBusquedaModeloSesion;
    FConsulta: TUniQuery;
    FFuente: TDataSource;
    FRepositorioVistas: TcxGridViewRepository;
    FVistaModelos: TcxGridDBTableView;
    FColumnaReferencia: TcxGridDBColumn;
    FColumnaCodigoArticulo: TcxGridDBColumn;
    FRepositorioEdicion: TcxEditRepository;
    FCombo: TcxEditRepositoryExtLookupComboBoxItem;
    FPlanificadorCodigo: IPlanificadorDiferido;
    FDuplicadoCodigo: TResolverDuplicadoSesion;
    FSerieCodigo: string;
    FNumeroCodigo: string;
    FEntradaCodigo: string;
    FLineaCodigo: Integer;
    function GenerarCodigoPropuesto(
      AOrigen: TOrigenGeneracionCodigoArticuloSesion): Boolean;
    procedure ComprobarCodigoPropuesto;
    procedure PrepararDecisionCodigo(
      const ADuplicado: TResolverDuplicadoSesion);
    function SolicitarDecisionCodigo(out ACodigoNuevo: string): string;
    procedure ConstruirConsulta;
    procedure ConstruirVistaModelos;
    procedure AnadirColumnaModelos(const ACaption, ACampo: string;
      AAncho: Integer);
    procedure ConstruirCombo;
    procedure ComboCambiado(ASender: TObject);
    procedure ComboCerrado(ASender: TObject);
    procedure ComboValidado(ASender: TObject;
      var ADisplayValue: Variant; var AErrorText: TCaption;
      var AError: Boolean);
    procedure ObtenerPropiedadesCelda(ASender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure AbrirDesplegableFiltrado;
    procedure ResolverPendiente;
    procedure GenerarCodigoPorModelo(const AModelo: string);
    procedure AplicarReferenciaResuelta(const AModelo: string;
      const ADuplicado: TResolverDuplicadoSesion);
    // El modelo ya está en otra línea de la sesión: la línea actual
    // reutiliza su artículo, sin crear otro. ALineaOrigen es esa línea.
    function ReutilizarModeloDeSesion(const AModelo: string;
      out ALineaOrigen: Integer): Boolean;
    procedure CerrarEditorEnCurso;
    procedure RefrescarColumnasTallas;
    function ProveedorCabecera: string;
    function HayLineaEditable: Boolean;
    function PuedeCompletarDescripcion(
      AReemplazar: Boolean = False): Boolean;
    // La descripcion de la linea no es la que puso la familia
    // AFamiliaAnterior: la tecleo el usuario (FZ-ISSUE-438).
    function DescripcionTecleada(const AFamiliaAnterior: string): Boolean;
  public
    constructor Create(const AEntorno: TEntornoModeloProveedorSesion);
    destructor Destroy; override;
    // (Re)abre la lista del desplegable acotada al proveedor de la
    // cabecera. Solo relanza si el proveedor cambia.
    procedure RecargarModelos;
    // Engancha el debounce al editor in-place cuando el editor que abre
    // el grid es el desplegable de busqueda incremental.
    function EngancharEditor(AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit): Boolean;
    // Reutiliza otra linea de la MISMA sesion. True si la linea actual
    // queda pendiente de una decision explicita, sin copiar datos.
    function AplicarDuplicadoDeSesion(const AModelo: string;
      const ACodigoArticulo: string): Boolean;
    procedure ResolverFamiliaTecleada(ASender: TObject);
    procedure ResolverCodigoTecleado(ASender: TObject);
    procedure ConfirmarCodigoTecleado(var ADisplayValue: Variant);
    procedure ConfirmarReferenciaTecleada(const AReferencia: string);
    procedure ExpandirCodigoFamiliaActiva(const ACodigoFamilia: string;
      const ANombreFamilia: string = '';
      AReemplazarDescripcion: Boolean = False);
    // Abre el picker jerarquico de familias y expande la eleccion.
    procedure ElegirFamiliaConModal;
    procedure ResolverCodigoPropuestoPendiente;
    procedure ProponerPrecioVenta;
  end;

implementation

uses
  Vcl.Dialogs,
  inLibComprasSesionesCodigoArticulo,
  inLibMensajesVcl,
  inLibMsgCompras,
  inMtoComprasSesionesPresentacionPlanificador,
  inMtoModalSelFamilia,
  inMtoModalSesionDuplicado,
  UniDataComprasSesionesPresentacionRepositorio;

const
  // Debounce de apertura del desplegable y resolucion inmediata pero
  // fuera del editor in-place (no se puede tocar el dataset mientras el
  // editor se esta cerrando).
  cIntervaloDebounceMs = 350;
  cIntervaloResolucionMs = 1;

constructor TBuscadorModeloProveedorSesion.Create(
  const AEntorno: TEntornoModeloProveedorSesion);
var
  PlanificadorBusqueda: IPlanificadorDiferido;
  PlanificadorResolucion: IPlanificadorDiferido;
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Vista) then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if not Assigned(AEntorno.GenerarCodigoArticulo) then
    raise EArgumentNilException.Create('AEntorno.GenerarCodigoArticulo');
  FEntorno := AEntorno;
  FPlanificadorCodigo := TPlanificadorDiferidoTimer.Create(
    cIntervaloResolucionMs,
    procedure
    begin
      ResolverCodigoPropuestoPendiente;
    end);
  PlanificadorBusqueda := TPlanificadorDiferidoTimer.Create(
    cIntervaloDebounceMs,
    procedure
    begin
      AbrirDesplegableFiltrado;
    end);
  PlanificadorResolucion := TPlanificadorDiferidoTimer.Create(
    cIntervaloResolucionMs,
    procedure
    begin
      ResolverPendiente;
    end);
  FNucleo := TNucleoBusquedaModeloSesion.Create(
    PlanificadorBusqueda,
    PlanificadorResolucion);
  ConstruirConsulta;
  ConstruirVistaModelos;
  ConstruirCombo;
  if Assigned(FEntorno.ColumnaModelo) then
    FEntorno.ColumnaModelo.OnGetProperties := ObtenerPropiedadesCelda;
end;

destructor TBuscadorModeloProveedorSesion.Destroy;
begin
  FPlanificadorCodigo := nil;
  if Assigned(FEntorno.ColumnaModelo) then
    FEntorno.ColumnaModelo.OnGetProperties := nil;
  FreeAndNil(FNucleo);
  FreeAndNil(FRepositorioEdicion);
  FreeAndNil(FRepositorioVistas);
  FreeAndNil(FFuente);
  if Assigned(FConsulta) then
  begin
    if FConsulta.Active then
      FConsulta.Close;
    FConsulta.Connection := nil;
  end;
  FreeAndNil(FConsulta);
  inherited Destroy;
end;

// Un modelo por fila: descripcion, sistema de tallas, colores ya dados
// de alta y ultimo precio de compra. El filtrado "empieza por" mientras
// se teclea lo hace IncrementalFiltering en cliente; :prv lo fija
// RecargarModelos.
procedure TBuscadorModeloProveedorSesion.ConstruirConsulta;
begin
  FConsulta := CrearConsultaModelosProveedorUniDAC(FEntorno.Conexion);
  FFuente := TDataSource.Create(nil);
  FFuente.DataSet := FConsulta;
end;

procedure TBuscadorModeloProveedorSesion.AnadirColumnaModelos(
  const ACaption, ACampo: string; AAncho: Integer);
var
  Columna: TcxGridDBColumn;
begin
  Columna := FVistaModelos.CreateColumn;
  Columna.Caption := ACaption;
  Columna.DataBinding.FieldName := ACampo;
  Columna.Width := AAncho;
end;

// View del desplegable, en su propio repositorio (no en pantalla).
procedure TBuscadorModeloProveedorSesion.ConstruirVistaModelos;
begin
  FRepositorioVistas := TcxGridViewRepository.Create(nil);
  FVistaModelos := FRepositorioVistas.CreateItem(TcxGridDBTableView)
                     as TcxGridDBTableView;
  FVistaModelos.DataController.DataSource := FFuente;
  FVistaModelos.DataController.KeyFieldNames := 'REFPRV';
  FVistaModelos.OptionsView.GroupByBox := False;
  FVistaModelos.OptionsSelection.CellSelect := False;
  FVistaModelos.OptionsBehavior.IncSearch := False;
  FColumnaReferencia := FVistaModelos.CreateColumn;
  FColumnaReferencia.Caption := SCaptionModeloCompra;
  FColumnaReferencia.DataBinding.FieldName := 'REFPRV';
  FColumnaReferencia.Width := 130;
  FColumnaCodigoArticulo := FVistaModelos.CreateColumn;
  FColumnaCodigoArticulo.Caption := SCaptionCodigoCompra;
  FColumnaCodigoArticulo.DataBinding.FieldName := 'CODART';
  FColumnaCodigoArticulo.Width := 110;
  AnadirColumnaModelos('Descripcion', 'DESCRIPCION', 220);
  AnadirColumnaModelos('Tallas', 'SISTEMA', 110);
  AnadirColumnaModelos('Colores', 'COLORES', 180);
  AnadirColumnaModelos('Ult. compra', 'PCOMPRA', 80);
end;

// Item de edicion ExtLookupComboBox que usa ese view. DropDownListStyle
// lsEditList permite teclear modelos nuevos; OnValidate es el unico
// evento fiable cuando el modelo se confirma con Tab/Enter sin pasar
// por el desplegable.
procedure TBuscadorModeloProveedorSesion.ConstruirCombo;
begin
  FRepositorioEdicion := TcxEditRepository.Create(nil);
  FCombo := FRepositorioEdicion.CreateItem(
              TcxEditRepositoryExtLookupComboBoxItem)
              as TcxEditRepositoryExtLookupComboBoxItem;
  FCombo.Properties.View := FVistaModelos;
  FCombo.Properties.KeyFieldNames := 'REFPRV';
  FCombo.Properties.ListFieldItem := FColumnaReferencia;
  FCombo.Properties.DropDownListStyle := lsEditList;
  FCombo.Properties.IncrementalFiltering := True;
  FCombo.Properties.DropDownRows := 15;
  FCombo.Properties.DropDownAutoWidth := True;
  // No abrir el desplegable en cada tecla: lo abre el debounce ya filtrado.
  FCombo.Properties.ImmediateDropDownWhenKeyPressed := False;
  FCombo.Properties.OnCloseUp := ComboCerrado;
  FCombo.Properties.OnValidate := ComboValidado;
end;

procedure TBuscadorModeloProveedorSesion.RecargarModelos;
var
  sProveedor: string;
begin
  if Assigned(FConsulta) then
  begin
    sProveedor := ProveedorCabecera;
    if FNucleo.DebeRecargarLista(sProveedor, FConsulta.Active) then
    begin
      FNucleo.MarcarListaCargada(sProveedor);
      if FConsulta.Active then
        FConsulta.Close;
      FConsulta.ParamByName('prv').AsString := sProveedor;
      FConsulta.Open;
    end;
  end;
end;

// Editor por celda: celda vacia y enfocada -> ExtLookupComboBox; en otro
// caso el editor de texto por defecto de la columna, que confirma el
// valor mediante OnValidate.
procedure TBuscadorModeloProveedorSesion.ObtenerPropiedadesCelda(
  ASender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vValor: Variant;
  bVacia: Boolean;
  bEnfocada: Boolean;
begin
  if (ARecord <> nil) and (FCombo <> nil) then
  begin
    vValor := ARecord.Values[ASender.Index];
    bVacia := VarIsNull(vValor) or (Trim(VarToStr(vValor)) = '');
    bEnfocada := (FEntorno.Vista.Controller.FocusedRecord = ARecord) and
                 (FEntorno.Vista.Controller.FocusedItem = ASender);
    if bVacia and bEnfocada then
      AProperties := FCombo.Properties;
  end;
end;

function TBuscadorModeloProveedorSesion.EngancharEditor(
  AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit): Boolean;
begin
  Result := (AItem = FEntorno.ColumnaModelo) and
            (AEdit is TcxExtLookupComboBox);
  if Result then
    TcxExtLookupComboBox(AEdit).Properties.OnChange := ComboCambiado;
end;

procedure TBuscadorModeloProveedorSesion.ComboCambiado(ASender: TObject);
begin
  FNucleo.RegistrarTecleo;
end;

// Al saltar el debounce abre el desplegable ya filtrado por lo tecleado.
procedure TBuscadorModeloProveedorSesion.AbrirDesplegableFiltrado;
var
  Editor: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
begin
  if FEntorno.Vista.Controller.EditingController.IsEditing then
  begin
    Editor := FEntorno.Vista.Controller.EditingController.Edit;
    if Editor is TcxExtLookupComboBox then
    begin
      Combo := TcxExtLookupComboBox(Editor);
      if (Trim(VarToStr(Combo.EditingValue)) <> '') and
         (not Combo.DroppedDown) then
        Combo.DroppedDown := True;
    end;
  end;
end;

// Al cerrar el desplegable con una eleccion guardamos el modelo y el
// codigo de articulo de la fila elegida; la resolucion se difiere para
// no tocar el dataset mientras se cierra el editor in-place.
procedure TBuscadorModeloProveedorSesion.ComboCerrado(ASender: TObject);
var
  Fila: TcxCustomGridRecord;
  sModelo: string;
  sCodigoArticulo: string;
begin
  if ASender is TcxCustomEdit then
  begin
    sModelo := VarToStr(TcxCustomEdit(ASender).EditValue);
    sCodigoArticulo := '';
    if (FVistaModelos <> nil) and (FColumnaCodigoArticulo <> nil) then
    begin
      Fila := FVistaModelos.Controller.FocusedRecord;
      if Fila <> nil then
        sCodigoArticulo := VarToStr(
          Fila.Values[FColumnaCodigoArticulo.Index]);
    end;
    FNucleo.RegistrarSeleccion(sModelo, sCodigoArticulo);
  end;
end;

// Confirmacion del valor del combo (Tab / Enter / clic fuera). Cubre el
// modelo tecleado a mano que no paso por el desplegable, p. ej. uno que
// solo existe en lineas de ESTA sesion, aun sin materializar.
procedure TBuscadorModeloProveedorSesion.ComboValidado(ASender: TObject;
  var ADisplayValue: Variant; var AErrorText: TCaption;
  var AError: Boolean);
begin
  AError := False;
  AErrorText := '';
  ConfirmarReferenciaTecleada(VarToStr(ADisplayValue));
end;

function TBuscadorModeloProveedorSesion.ProveedorCabecera: string;
begin
  Result := '';
  if Assigned(FEntorno.Cabecera) and FEntorno.Cabecera.Active and
     (not FEntorno.Cabecera.IsEmpty) then
    Result := Trim(FEntorno.Cabecera.FieldByName(
      'CODIGO_PRV_SES').AsString);
end;

function TBuscadorModeloProveedorSesion.HayLineaEditable: Boolean;
begin
  Result := Assigned(FEntorno.Cabecera) and
            Assigned(FEntorno.Lineas) and
            (not FEntorno.Cabecera.IsEmpty) and
            (not FEntorno.Lineas.IsEmpty);
end;

procedure TBuscadorModeloProveedorSesion.RefrescarColumnasTallas;
begin
  if Assigned(FEntorno.RefrescarTallas) then
    FEntorno.RefrescarTallas();
end;

// Cierra el editor in-place para que la celda muestre el valor resuelto.
// El EInvalidOperation del editor es ruido conocido: se registra y se
// sigue, nunca se convierte el fallo en exito silencioso.
// La resolucion llega diferida: el editor abierto suele ser ya el de la
// columna siguiente. Se reabre alli para seguir tecleando (y con F3).
procedure TBuscadorModeloProveedorSesion.CerrarEditorEnCurso;
var
  Controlador: TcxGridTableController;
  Columna: TcxCustomGridTableItem;
  bReabrir: Boolean;
begin
  Controlador := FEntorno.Vista.Controller;
  if Controlador.EditingController.IsEditing then
  begin
    Columna := Controlador.EditingController.EditingItem;
    bReabrir := (Columna <> nil) and
                (Columna <> FEntorno.ColumnaModelo) and
                (Controlador.EditingController.Edit <> nil) and
                Controlador.EditingController.Edit.Focused;
    try
      Controlador.EditingController.HideEdit(True);
    except
      on E: EInvalidOperation do
        if Assigned(FEntorno.RegistrarAviso) then
          FEntorno.RegistrarAviso(
            'ComprasSesiones.ResolverModelo: HideEdit ignorado: ' +
            E.Message);
    end;
    if bReabrir and (not Controlador.EditingController.IsEditing) then
    begin
      Controlador.FocusedItem := Columna;
      Controlador.EditingController.ShowEdit(Columna);
    end;
  end;
end;

function TBuscadorModeloProveedorSesion.AplicarDuplicadoDeSesion(
  const AModelo: string;
  const ACodigoArticulo: string): Boolean;
var
  rDuplicado: TResolverDuplicadoSesion;
  iLinea: Integer;
begin
  Result := False;
  if HayLineaEditable then
  begin
    iLinea := FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    rDuplicado := FEntorno.Servicio.ResolverDuplicadoIntraSesion(
      Trim(FEntorno.Cabecera.FieldByName('SERIE_SES').AsString),
      Trim(FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString),
      iLinea,
      AModelo,
      ACodigoArticulo);
    if rDuplicado.Encontrado then
    begin
      if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
        FEntorno.Lineas.Edit;
      PrepararDecisionCodigo(rDuplicado);
      Result := True;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.AplicarReferenciaResuelta(
  const AModelo: string;
  const ADuplicado: TResolverDuplicadoSesion);
begin
  if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
    FEntorno.Lineas.Edit;
  // El modelo tecleado se conserva como REF de la linea: la rama REF de
  // la resolucion no la toca.
  FEntorno.Lineas.FieldByName('REF_PRV_SESLIN').AsString := AModelo;
  FEntorno.Servicio.AplicarDuplicadoEnLinea(ADuplicado);
  RefrescarColumnasTallas;
end;

function TBuscadorModeloProveedorSesion.ReutilizarModeloDeSesion(
  const AModelo: string; out ALineaOrigen: Integer): Boolean;
var
  rDuplicado: TResolverDuplicadoSesion;
begin
  Result := False;
  ALineaOrigen := 0;
  if HayLineaEditable and (Trim(AModelo) <> '') then
  begin
    rDuplicado := FEntorno.Servicio.ResolverDuplicadoIntraSesion(
      Trim(FEntorno.Cabecera.FieldByName('SERIE_SES').AsString),
      Trim(FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString),
      FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger,
      Trim(AModelo),
      '');
    if rDuplicado.Encontrado then
    begin
      AplicarReferenciaResuelta(Trim(AModelo), rDuplicado);
      if (rDuplicado.IdAcPivot > 0) and
         Assigned(FEntorno.FijarTallajeDefecto) then
        FEntorno.FijarTallajeDefecto(rDuplicado.IdAcPivot);
      ALineaOrigen := rDuplicado.LineaOrigen;
      Result := True;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.GenerarCodigoPorModelo(
  const AModelo: string);
begin
  if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
    FEntorno.Lineas.Edit;
  FEntorno.Lineas.FieldByName(
    'REF_PRV_SESLIN').AsString := AModelo;
  GenerarCodigoPropuesto(ogcaModelo);
end;

procedure TBuscadorModeloProveedorSesion.ResolverPendiente;
var
  sModelo: string;
  sCodigoArticulo: string;
  sProveedor: string;
  bResuelto: Boolean;
  rDuplicado: TResolverDuplicadoSesion;
  iLineaModelo: Integer;
begin
  bResuelto := False;
  iLineaModelo := 0;
  if FNucleo.TomarPendiente(sModelo, sCodigoArticulo) and
     HayLineaEditable then
  begin
    if Trim(sModelo) = '' then
    begin
      GenerarCodigoPorModelo('');
      bResuelto := True;
    end
    else
    begin
      sProveedor := ProveedorCabecera;
      // Mismo modelo en otra línea: un solo artículo para las dos.
      if sProveedor <> '' then
        bResuelto := ReutilizarModeloDeSesion(sModelo, iLineaModelo);
      if (sProveedor <> '') and (not bResuelto) then
        bResuelto := AplicarDuplicadoDeSesion(
          '', sCodigoArticulo);
      if (sProveedor <> '') and (not bResuelto) then
      begin
        rDuplicado := FEntorno.Servicio.ResolverDuplicado(
          sModelo,
          sProveedor,
          True,
          sCodigoArticulo);
        if rDuplicado.Encontrado then
        begin
          AplicarReferenciaResuelta(sModelo, rDuplicado);
          bResuelto := True;
        end;
      end;
      if (sProveedor <> '') and (not bResuelto) then
      begin
        GenerarCodigoPorModelo(sModelo);
        bResuelto := True;
      end;
    end;
  end;
  if bResuelto then
    CerrarEditorEnCurso;
  if (iLineaModelo > 0) and Assigned(FEntorno.OfrecerDistribucion) then
    FEntorno.OfrecerDistribucion(iLineaModelo);
end;

// La familia clasifica la linea; no identifica un articulo repetido.
// El codigo ya elegido se conserva tanto al teclear como al usar F3.
procedure TBuscadorModeloProveedorSesion.ResolverFamiliaTecleada(
  ASender: TObject);
var
  sFamilia: string;
begin
  if (ASender is TcxCustomEdit) and Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    TcxCustomEdit(ASender).PostEditValue;
    sFamilia := Trim(FEntorno.Lineas.FieldByName(
      'CODIGO_FAM_SESLIN').AsString);
    ExpandirCodigoFamiliaActiva(sFamilia);
  end;
end;

procedure TBuscadorModeloProveedorSesion.ResolverCodigoTecleado(
  ASender: TObject);
var
  Editor: TcxCustomEdit;
  vCodigo: Variant;
begin
  if (ASender is TcxCustomEdit) then
  begin
    Editor := TcxCustomEdit(ASender);
    vCodigo := Editor.EditingValue;
    ConfirmarCodigoTecleado(vCodigo);
    Editor.EditValue := vCodigo;
  end;
end;

// La validacion recibe el texto completo confirmado con Enter o Tab.
// Una familia tiene prioridad sobre un articulo con el mismo codigo.
procedure TBuscadorModeloProveedorSesion.ConfirmarCodigoTecleado(
  var ADisplayValue: Variant);
var
  sTecleado: string;
  sNombre: string;
  bPendiente: Boolean;
  rDuplicado: TResolverDuplicadoSesion;
begin
  sTecleado := '';
  if Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    sTecleado := Trim(VarToStr(ADisplayValue));
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    FEntorno.Lineas.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString := sTecleado;
  end;
  bPendiente := sTecleado <> '';
  if bPendiente then
  begin
    sNombre := FEntorno.Servicio.ObtenerNombreFamilia(sTecleado);
    if sNombre <> '' then
    begin
      FEntorno.Lineas.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').Clear;
      ExpandirCodigoFamiliaActiva(sTecleado, sNombre, True);
      ADisplayValue := FEntorno.Lineas.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString;
      bPendiente := False;
    end;
  end;
  if bPendiente and AplicarDuplicadoDeSesion('', sTecleado) then
    bPendiente := False;
  if bPendiente then
  begin
    // El proveedor aporta el ultimo coste. Solo vale el articulo con ese
    // mismo codigo: la busqueda por referencia del proveedor podria
    // devolver otro articulo y sustituir el codigo tecleado.
    rDuplicado := FEntorno.Servicio.ResolverDuplicado(
      sTecleado,
      ProveedorCabecera);
    if rDuplicado.Encontrado and
       SameText(rDuplicado.CodigoArt, sTecleado) then
    begin
      if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
        FEntorno.Lineas.Edit;
      FEntorno.Servicio.AplicarDuplicadoEnLinea(rDuplicado);
      if (rDuplicado.IdAcPivot > 0) and
         Assigned(FEntorno.FijarTallajeDefecto) then
        FEntorno.FijarTallajeDefecto(rDuplicado.IdAcPivot);
      RefrescarColumnasTallas;
      ADisplayValue := FEntorno.Lineas.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString;
    end;
  end;
end;

function TBuscadorModeloProveedorSesion.PuedeCompletarDescripcion(
  AReemplazar: Boolean): Boolean;
var
  CampoCopiar: TField;
begin
  CampoCopiar := FEntorno.Cabecera.FindField(
    'ESCOPIAR_DESCRIPCION_FAM_SES');
  Result := (AReemplazar or (FEntorno.Lineas.FieldByName(
    'DESCRIPCION_SESLIN').AsString = '')) and
    not SameText(FEntorno.Cabecera.FieldByName(
      'ESDESCRIPCION_BLANCO_SES').AsString, 'S');
  if Assigned(CampoCopiar) then
    Result := Result and not SameText(CampoCopiar.AsString, 'N');
end;

function TBuscadorModeloProveedorSesion.DescripcionTecleada(
  const AFamiliaAnterior: string): Boolean;
var
  sActual: string;
begin
  sActual := Trim(FEntorno.Lineas.FieldByName(
    'DESCRIPCION_SESLIN').AsString);
  Result := sActual <> '';
  if Result and (Trim(AFamiliaAnterior) <> '') then
    Result :=
      (not SameText(sActual, Trim(
        FEntorno.Servicio.ObtenerDescripcionFamilia(AFamiliaAnterior))))
      and
      (not SameText(sActual, Trim(
        FEntorno.Servicio.ObtenerNombreFamilia(AFamiliaAnterior))));
end;

procedure TBuscadorModeloProveedorSesion.ConfirmarReferenciaTecleada(
  const AReferencia: string);
begin
  FNucleo.RegistrarConfirmacion(Trim(AReferencia));
end;

// F3 y el tecleo proponen codigo solo si esta vacio. Una familia comun
// no debe sustituir el articulo manual ni activar su reutilizacion.
procedure TBuscadorModeloProveedorSesion.ExpandirCodigoFamiliaActiva(
  const ACodigoFamilia: string;
  const ANombreFamilia: string;
  AReemplazarDescripcion: Boolean);
var
  sNombre: string;
  bReemplazar: Boolean;
begin
  if (Trim(ACodigoFamilia) <> '') and Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    // FZ-ISSUE-438: lo tecleado por el usuario no se sustituye; solo la
    // descripcion que habia puesto la familia anterior de la linea.
    bReemplazar := AReemplazarDescripcion and
      (not DescripcionTecleada(FEntorno.Lineas.FieldByName(
        'CODIGO_FAM_SESLIN').AsString));
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    FEntorno.Lineas.FieldByName('CODIGO_FAM_SESLIN').AsString :=
      ACodigoFamilia;
    if Trim(FEntorno.Lineas.FieldByName(
         'CODIGO_ART_TENTATIVO_SESLIN').AsString) = '' then
      GenerarCodigoPropuesto(ogcaFamilia);
    if PuedeCompletarDescripcion(bReemplazar) then
    begin
      sNombre := FEntorno.Servicio.ObtenerDescripcionFamilia(
        ACodigoFamilia);
      if sNombre = '' then
        sNombre := ANombreFamilia;
      if sNombre = '' then
        sNombre := FEntorno.Servicio.ObtenerNombreFamilia(ACodigoFamilia);
      if sNombre <> '' then
        FEntorno.Lineas.FieldByName('DESCRIPCION_SESLIN').AsString :=
          sNombre;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.ElegirFamiliaConModal;
var
  Modal: TfrmModalSelFamilia;
begin
  Modal := TfrmModalSelFamilia.Create(FEntorno.Propietario);
  try
    if Modal.ShowModal = mrOk then
      ExpandirCodigoFamiliaActiva(Modal.CodigoFamilia, Modal.NombreFamilia);
  finally
    FreeAndNil(Modal);
  end;
end;

// Una formula que no puede evaluarse (p. ej. familia sin contador) es un
// aviso al usuario, no un fallo del programa: el codigo queda vacio para
// que lo teclee y la materializacion no admite lineas sin codigo.
function TBuscadorModeloProveedorSesion.GenerarCodigoPropuesto(
  AOrigen: TOrigenGeneracionCodigoArticuloSesion): Boolean;
begin
  try
    Result := FEntorno.GenerarCodigoArticulo(AOrigen);
  except
    on E: EFormulaCodigoArticuloSesion do
    begin
      Result := False;
      if Assigned(FEntorno.RegistrarAviso) then
        FEntorno.RegistrarAviso(
          'ComprasSesiones.GenerarCodigoPropuesto: ' + E.Message);
      MessageDlg_fza(E.Message, mtWarning, [mbOk], 0);
    end;
  end;
  if Result then
    ComprobarCodigoPropuesto;
end;

procedure TBuscadorModeloProveedorSesion.ComprobarCodigoPropuesto;
var
  sCodigo: string;
  Duplicado: TResolverDuplicadoSesion;
begin
  FPlanificadorCodigo.Cancelar;
  FDuplicadoCodigo := Default(TResolverDuplicadoSesion);
  sCodigo := Trim(FEntorno.Lineas.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString);
  if sCodigo <> '' then
  begin
    FSerieCodigo := FEntorno.Cabecera.FieldByName('SERIE_SES').AsString;
    FNumeroCodigo := FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString;
    FLineaCodigo := FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    Duplicado := FEntorno.Servicio.ResolverDuplicadoIntraSesion(
      FSerieCodigo, FNumeroCodigo, FLineaCodigo, '', sCodigo);
    if not Duplicado.Encontrado then
    begin
      Duplicado := FEntorno.Servicio.ResolverDuplicado(
        sCodigo, ProveedorCabecera);
      Duplicado.Encontrado := Duplicado.Encontrado and
        SameText(Duplicado.CodigoArt, sCodigo);
    end;
    PrepararDecisionCodigo(Duplicado);
  end;
end;

procedure TBuscadorModeloProveedorSesion.PrepararDecisionCodigo(
  const ADuplicado: TResolverDuplicadoSesion);
begin
  FPlanificadorCodigo.Cancelar;
  FDuplicadoCodigo := ADuplicado;
  FSerieCodigo := FEntorno.Cabecera.FieldByName('SERIE_SES').AsString;
  FNumeroCodigo := FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString;
  FLineaCodigo := FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
  FEntradaCodigo := FEntorno.Lineas.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString;
  if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
    FEntorno.Lineas.Edit;
  FEntorno.Lineas.FieldByName('ACCION_DUPLICADO_SESLIN').Clear;
  FEntorno.Lineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').Clear;
  FEntorno.Lineas.FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
  if ADuplicado.Encontrado then
  begin
    FEntorno.Lineas.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
    FPlanificadorCodigo.Rearmar;
  end;
end;

function TBuscadorModeloProveedorSesion.SolicitarDecisionCodigo(
  out ACodigoNuevo: string): string;
var
  Modal: TfrmModalSesionDuplicado;
begin
  ACodigoNuevo := '';
  if Assigned(FEntorno.SolicitarDecisionCodigo) then
    Result := FEntorno.SolicitarDecisionCodigo(
      FDuplicadoCodigo, ACodigoNuevo)
  else
  begin
    Result := '';
    Modal := TfrmModalSesionDuplicado.Create(FEntorno.Propietario);
    try
      Modal.CodigoArt := FDuplicadoCodigo.CodigoArt;
      Modal.Descripcion := FDuplicadoCodigo.DescripcionArt;
      Modal.LineaOrigen := FDuplicadoCodigo.LineaOrigen;
      if Modal.ShowModal = mrOk then
      begin
        Result := Modal.Accion;
        ACodigoNuevo := Modal.CodigoArt;
      end;
    finally
      Modal.Free;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.ResolverCodigoPropuestoPendiente;
var
  sAccion: string;
  sCodigoNuevo: string;
begin
  FPlanificadorCodigo.Cancelar;
  // El usuario puede haber navegado o cambiado el codigo antes del timer.
  if FDuplicadoCodigo.Encontrado and HayLineaEditable and
     SameText(FSerieCodigo,
       FEntorno.Cabecera.FieldByName('SERIE_SES').AsString) and
     SameText(FNumeroCodigo,
       FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString) and
     (FLineaCodigo =
       FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger) and
     SameText(FEntradaCodigo,
       FEntorno.Lineas.FieldByName(
         'CODIGO_ART_TENTATIVO_SESLIN').AsString) then
  begin
    sAccion := SolicitarDecisionCodigo(sCodigoNuevo);
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    if sAccion = 'RENOMBRAR' then
    begin
      sCodigoNuevo := StringReplace(Trim(sCodigoNuevo), '/', '-',
        [rfReplaceAll]);
      if (sCodigoNuevo <> '') and
         (Length(sCodigoNuevo) <= 20) and
         not SameText(sCodigoNuevo, FDuplicadoCodigo.CodigoArt) then
      begin
        FEntorno.Lineas.FieldByName(
          'CODIGO_ART_TENTATIVO_SESLIN').AsString := sCodigoNuevo;
        ComprobarCodigoPropuesto;
      end;
    end
    else if sAccion = 'REUSAR' then
    begin
      // Reusar identidad sin sobrescribir precios, descripcion ni color.
      FEntorno.Lineas.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString := FDuplicadoCodigo.CodigoArt;
      FEntorno.Lineas.FieldByName(
        'ACCION_DUPLICADO_SESLIN').AsString := 'REUSAR';
      FEntorno.Lineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString :=
        FDuplicadoCodigo.CodigoArt;
      FDuplicadoCodigo.Encontrado := False;
      RefrescarColumnasTallas;
    end
    else
      FDuplicadoCodigo.Encontrado := False;
  end
  else
    FDuplicadoCodigo.Encontrado := False;
end;

procedure TBuscadorModeloProveedorSesion.ProponerPrecioVenta;
var
  rCoste: Double;
  rMargen: Double;
  rMultiplo: Double;
  rAjuste: Double;
begin
  if HayLineaEditable then
  begin
    rCoste := FEntorno.Lineas.FieldByName(
      'PRECIO_COMPRA_SESLIN').AsFloat;
    rMargen := FEntorno.Cabecera.FieldByName(
      'PORCENTAJE_MARGEN_SES').AsFloat;
    rMultiplo := FEntorno.Cabecera.FieldByName(
      'MULTIPLO_REDONDEO_SES').AsFloat;
    rAjuste := FEntorno.Cabecera.FieldByName(
      'AJUSTE_FINAL_SES').AsFloat;
    if rMargen > 0 then
    begin
      if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
        FEntorno.Lineas.Edit;
      FEntorno.Lineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat :=
        CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);
    end;
  end;
end;

end.

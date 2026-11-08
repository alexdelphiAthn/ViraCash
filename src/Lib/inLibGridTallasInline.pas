{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridTallasInline                                         }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       18/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Gestor reutilizable para grids cxGrid con tallas pivotadas inline. Los    }
{    clientes compran "en horizontal": una fila por articulo + N columnas de   }
{    cantidad por talla. Este patron aparece en todo el modulo de Compras      }
{    (Sesiones, Pedidos, Albaranes, Facturas) y esta libreria centraliza la    }
{    parte fragil para que cada Mto solo cuide su cabecera y sus campos        }
{    propios.                                                                  }
{                                                                              }
{    Lo que la libreria hace:                                                  }
{      - Cachea las posiciones (ID_AV, VALOR) de cada conjunto pivot.          }
{      - Calcula el numero maximo de columnas talla a mostrar a partir de los  }
{        sistemas referenciados por las lineas del documento.                  }
{      - Muestra / oculta columnas talla segun ese maximo                      }
{        (RecalcularMaxColumnas).                                              }
{      - Actualiza captions al sistema de la linea con foco                    }
{        (ActualizarCaptionsLineaActiva).                                      }
{      - Carga las cantidades desde la tabla de celdas a los Values[] de las   }
{        columnas no-bound del grid con DisableControls + bookmark             }
{        (CargarCantidadesTodasLineas / UnaLinea).                             }
{      - Persiste el cambio de una celda mediante el puerto inyectado.         }
{      - Recalcula totales de la linea sumando la tabla de celdas              }
{        (RefrescarTotalesLinea).                                              }
{      - Valida que el sistema seleccionado no exceda Cfg.MaxColumnas y, si    }
{        lo excede, muestra mtError y limpia el campo                          }
{        (ValidarSistemaSeleccionado).                                         }
{                                                                              }
{    Lo que el Mto consumidor sigue cuidando:                                  }
{      - Cabecera y settings.                                                  }
{      - Crear las N columnas no-bound (Tag = 1..N) y pasarlas al gestor en    }
{        la inicializacion.                                                    }
{      - Handlers de F3/familia, color, PVP, etc.                              }
{      - Eventos del propio grid (OnFocusedRecordChanged, OnInitEdit,          }
{        OnEditKeyDown, OnCustomDrawCell, OnEditValueChanged).                 }
{                                                                              }
{    Parametrizacion via TGridTallasConfig: cada Mto carga su record con los   }
{    nombres de tabla / campos / sufijos especificos:                          }
{      Sesiones:   SESCEL / SESLIN / SES                                       }
{      Pedidos:    PEDCEL / PEDLIN / PED (cuando existan)                      }
{      Albaranes:  ALBCEL / ALBLIN / ALB (cuando existan)                      }
{      Facturas:   FACCEL / FACLIN / FAC (cuando existan)                      }
{                                                                              }
{    Documentacion: DESARROLLOS EN CURSO/compras_sesiones.md                   }
{    (grid tallas inline).                                                     }
{******************************************************************************}
unit inLibGridTallasInline;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.UITypes,
  Data.DB, Uni,
  cxControls, cxClasses, cxEdit, cxTextEdit, cxCurrencyEdit, cxCustomData,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  JvEnterTab,
  inLibAvisoTallasHorizontalVcl,
  inLibContextoSesionIntf, inLibModoTallasIntf;

type
  TPosConjunto = record
    IdAv  : Integer;
    Valor : string;
  end;
  TArrPosConjunto = TArray<TPosConjunto>;

  // Configuracion del gestor. Cada Mto consumidor rellena su instancia
  // con los nombres de tabla / campos especificos antes de crear el
  // gestor. Todos los nombres son SQL crudos (no constantes f*).
  TGridTallasConfig = record
    // -- objetos del form --
    Conexion         : TUniConnection;
    Persistencia     : IPersistenciaGridTallasInline;
    ContextoSesion   : IContextoSesionAplicacion;
    Usuario          : string;
    Grid             : TcxGridDBTableView;
    SourceMaster     : TDataSource;       // cabecera del documento
    SourceLineas     : TDataSource;       // detalle (line items)
    ColumnasTallas   : TArray<TcxGridDBColumn>;
                       // las N columnas no-bound creadas por el form;
                       // Tag = posicion 1..N en el conjunto

    // -- campos del master (cabecera) --
    FieldSerieMaster  : string;   // 'SERIE_SES'
    // NUMERO es OPCIONAL ('' = documento de clave simple, p.ej.
    // fza_documentos_trabajo con ID_DTR): la "serie" lleva la clave
    // completa y el par numero desaparece de los SQL de celdas.
    FieldNumeroMaster : string;   // 'NUMERO_SES' (puede ser '')

    // -- campos del detail (lineas) --
    FieldLinea        : string;   // 'LINEA_SESLIN'
    FieldArticulo     : string;
    FieldConjuntoPivot: string;   // 'ID_AC_PIVOT_SESLIN'
    FieldPrecioBase   : string;   // 'PRECIO_COMPRA_SESLIN'
    FieldTotalUds     : string;   // 'TOTAL_UNIDADES_SESLIN'
    FieldTotalLinea   : string;   // 'TOTAL_LINEA_SESLIN'

    // -- tabla y campos de celdas --
    TablaCeldas      : string;    // 'fza_compras_sesiones_celdas'
    FieldSerieCel    : string;    // 'SERIE_SES_SESCEL'
    FieldNumeroCel   : string;    // 'NUMERO_SES_SESCEL'
    FieldLineaCel    : string;    // 'LINEA_SES_SESCEL'
    FieldFilaCel     : string;    // 'ID_FILA_SES_SESCEL'
    FieldAvPivotCel  : string;    // 'ID_AV_PIVOT_SESCEL'
    FieldCantidadCel : string;    // 'CANTIDAD_SESCEL'
    FieldAlmacenCel  : string;    // 'CODIGO_ALM_SESCEL' (puede ser '')
    // Clave de documento EXTRA (opcional): pares campo del MASTER ->
    // campo de la tabla de CELDAS, para documentos cuya clave excede
    // SERIE+NUMERO (inventarios: empresa y almacen del documento).
    // Arrays paralelos; vacios = comportamiento actual (sesiones).
    CamposDocExtraMaster : TArray<string>;
    CamposDocExtraCel    : TArray<string>;
    IdFilaFijo       : Integer;   // 1 — la prueba/Mtos por ahora usan una
                                  // fila logica por linea

    // -- limites --
    MaxColumnas      : Integer;   // MAX_TALLAS_HORIZONTAL por defecto
    // Linea sin sistema de un articulo sin tallas: una sola columna de
    // unidades (celda con ID_AV pivot 0). Solo sesiones de compra.
    ColumnaUnidadesSinTallaje: Boolean;

    // -- total maximo por linea (FZ-ISSUE-255) --
    // Recibe el total que tendra la linea con la celda nueva, ANTES de
    // grabarla; False = no se graba y la celda vuelve a su valor. nil = sin
    // comprobacion (sesiones de compra, distribuidor...).
    ConfirmarTotalLinea: TFunc<Double, Boolean>;
  end;

  TGestorGridTallas = class
  private
    FCfg         : TGridTallasConfig;
    FConjuntoPos : TDictionary<string, TArrPosConjunto>;
    // Maximo del ultimo recorrido completo de las lineas; sirve mientras
    // la linea activa se edita y no se puede mover el cursor.
    FUltimoMaxConjuntos: Integer;
    FReferenciaCaptions: TArrPosConjunto;
    // La celda rechazada recupera su valor: ese cambio no se procesa.
    FRevirtiendoCelda: Boolean;
    FAvisoTallas: IAvisoTallasHorizontal;
    function  Lineas: TDataSet;
    function HayLineaActiva: Boolean;
    function PuedeRecargarCantidades: Boolean;
    function  LongConjuntoLineaActiva(ADataSet: TDataSet): Integer;
    function  RecorrerMaxLongConjuntos(ADataSet: TDataSet): Integer;
    procedure LogSes(const ATexto: string);
    function ArticuloActual: string;
    function TallasConCantidad(const AArticulo: string): TArray<Integer>;
    function IndicesTallasVisibles(const AArticulo: string;
      const APosiciones: TArray<TPosicionConjuntoTallas>): TArray<Integer>;
    function TieneColumnas(AIdAc: Integer): Boolean;
    function PrecioLineaActual: Double;
    function AceptaCantidadCelda(ALinea, AIdAv: Integer;
      ACantidad: Double; out ACantidadAnterior: Double): Boolean;
    procedure RevertirCelda(AEditor: TcxCustomEdit; ACantidad: Double);
  public
    constructor Create(const ACfg: TGridTallasConfig);
    destructor  Destroy; override;

    // Cache de posiciones por conjunto.
    function GetPosicionesConjunto(AIdAc: Integer): TArrPosConjunto;
      overload;
    function GetPosicionesConjunto(AIdAc: Integer;
      const AArticulo: string): TArrPosConjunto; overload;
    function GetPosicionesRegistro(AIndice: Integer): TArrPosConjunto;
    procedure InvalidarCache;

    // Siembra un conjunto VIRTUAL (id negativo) en la cache de
    // posiciones. Lo usa el pivote de tallas como fallback cuando
    // ningun conjunto real de fza_atributos_conjuntos cubre las tallas
    // de un articulo: el id negativo nunca llega a SQL, solo vive en
    // la cache y GetPosicionesConjunto lo resuelve desde ella.
    procedure RegistrarConjuntoVirtual(AIdAc: Integer;
                                       const APosiciones: TArrPosConjunto);

    // Maximo de valores entre los conjuntos referenciados por
    // alguna linea de la sesion (capado a Cfg.MaxColumnas).
    function MaxLongConjuntos: Integer;

    // Muestra Cfg.ColumnasTallas[0..N-1] segun el maximo del documento
    // y oculta el resto. Setea captions genericos "Talla N" — la
    // captura del sistema activo la hace ActualizarCaptionsLineaActiva.
    procedure RecalcularMaxColumnas;

    // Al cambiar de fila con foco, escribe los valores del conjunto
    // activo en las captions de las columnas talla. Las posiciones
    // que no aplican al conjunto actual quedan con "Talla N" generico.
    procedure ActualizarCaptionsLineaActiva;

    // Lee la tabla de celdas y vuelca CANTIDAD a los Values[] de las
    // columnas no-bound del grid. Usa DisableControls + bookmark para
    // no perder los Values al cambiar de record durante el bucle.
    procedure CargarCantidadesTodasLineas;
    procedure CargarCantidadesUnaLinea(ARecordIndex, ALinea: Integer);

    // Persiste una cantidad mediante el puerto de celdas.
    procedure PersistirCantidad(ALinea, AIdAv: Integer; ACantidad: Double);

    // Recalcula totales de la linea actual: SUM(CANTIDAD) y
    // FieldTotalLinea = SUM * FieldPrecioBase. Solo actualiza el
    // dataset en memoria; el form decide cuando Postear.
    procedure RefrescarTotalesLineaActual;

    // Valida que el conjunto recien seleccionado no excede
    // Cfg.MaxColumnas. Si lo excede muestra mtError, limpia el campo
    // y devuelve False; True en caso correcto.
    function ValidarSistemaSeleccionado: Boolean;

    // Persiste el cambio de la celda talla activa en el grid.
    // Llamarlo desde el OnEditValueChanged de cada columna talla.
    procedure PersistirCeldaActiva(ASender: TObject);

    property Cfg: TGridTallasConfig read FCfg;
  end;

function CrearConfigPersistenciaTallasInline(
  const AConfig: TGridTallasConfig): TConfigPersistenciaTallas;

// =============================================================================
//   Helpers que no necesitan estado pero suelen ir junto al gestor
// =============================================================================

// Apaga / enciende todas las instancias de TJvEnterAsTab encontradas en
// AForm, AForm.Owner y Application.MainForm. Llamarlo desde
// cxGrid.OnEnter (apagar) / OnExit (encender) para que Enter navegue
// celda a celda dentro del grid en vez de saltar al siguiente control.
procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);

// SelectAll en el editor si soporta seleccion de texto. Estilo Excel.
// Llamarlo desde tvLineas.OnInitEdit para que al entrar a una celda
// el contenido quede seleccionado.
procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);

implementation

uses
  inLibMensajesVcl,
  inLibPivoteVentaCalculo,
  inLibMsgArticulos;

{ TGestorGridTallas }

function CrearConfigPersistenciaTallasInline(
  const AConfig: TGridTallasConfig): TConfigPersistenciaTallas;
begin
  Result := Default(TConfigPersistenciaTallas);
  if Assigned(AConfig.SourceMaster) then
    Result.Master := AConfig.SourceMaster.DataSet;
  Result.Usuario := AConfig.Usuario;
  Result.CampoSerieMaster := AConfig.FieldSerieMaster;
  Result.CampoNumeroMaster := AConfig.FieldNumeroMaster;
  Result.CamposDocExtraMaster := AConfig.CamposDocExtraMaster;
  Result.TablaCeldas := AConfig.TablaCeldas;
  Result.CampoSerieCel := AConfig.FieldSerieCel;
  Result.CampoNumeroCel := AConfig.FieldNumeroCel;
  Result.CampoLineaCel := AConfig.FieldLineaCel;
  Result.CampoFilaCel := AConfig.FieldFilaCel;
  Result.CampoAvPivotCel := AConfig.FieldAvPivotCel;
  Result.CampoCantidadCel := AConfig.FieldCantidadCel;
  Result.CampoAlmacenCel := AConfig.FieldAlmacenCel;
  Result.CamposDocExtraCel := AConfig.CamposDocExtraCel;
  Result.IdFilaFijo := AConfig.IdFilaFijo;
end;

constructor TGestorGridTallas.Create(const ACfg: TGridTallasConfig);
begin
  inherited Create;
  FCfg := ACfg;
  if not Assigned(FCfg.Persistencia) then
    raise EArgumentNilException.Create('ACfg.Persistencia');
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := MAX_TALLAS_HORIZONTAL;
  if FCfg.IdFilaFijo  <= 0 then FCfg.IdFilaFijo  := 1;
  FConjuntoPos := TDictionary<string, TArrPosConjunto>.Create;
  FAvisoTallas := CrearAvisoTallasHorizontal;
end;

function TGestorGridTallas.Lineas: TDataSet;
begin
  if Assigned(FCfg.SourceLineas) then
    Result := FCfg.SourceLineas.DataSet
  else
    Result := nil;
end;

function TGestorGridTallas.HayLineaActiva: Boolean;
var
  Datos: TDataSet;
begin
  Datos := Lineas;
  Result := Assigned(Datos) and Datos.Active and
    ((Datos.State in dsEditModes) or not Datos.IsEmpty);
end;

procedure TGestorGridTallas.LogSes(const ATexto: string);
begin
  if Assigned(FCfg.ContextoSesion) then
    FCfg.ContextoSesion.LogSesion(ATexto);
end;

destructor TGestorGridTallas.Destroy;
begin
  FreeAndNil(FConjuntoPos);
  inherited;
end;

procedure TGestorGridTallas.InvalidarCache;
begin
  if FConjuntoPos <> nil then FConjuntoPos.Clear;
end;

procedure TGestorGridTallas.RegistrarConjuntoVirtual(AIdAc: Integer;
  const APosiciones: TArrPosConjunto);
begin
  // AddOrSetValue: el llamante re-registra en cada recarga porque las
  // tallas del articulo pueden crecer (alta de SKU desde una celda).
  if (FConjuntoPos <> nil) and (AIdAc < 0) then
    FConjuntoPos.AddOrSetValue(IntToStr(AIdAc), APosiciones);
end;

function TGestorGridTallas.ArticuloActual: string;
begin
  Result := '';
  if (FCfg.FieldArticulo <> '') and HayLineaActiva then
    Result := Lineas.FieldByName(FCfg.FieldArticulo).AsString;
end;

// Con sistema siempre; sin el, solo si se admite la columna de unidades.
function TGestorGridTallas.TieneColumnas(AIdAc: Integer): Boolean;
begin
  Result := (AIdAc > 0) or
            ((AIdAc = 0) and FCfg.ColumnaUnidadesSinTallaje);
end;

function TGestorGridTallas.GetPosicionesRegistro(
  AIndice: Integer): TArrPosConjunto;
var
  oConjunto, oArticulo, oLinea: TcxGridDBColumn;
  sArticulo: string;
  vConjunto: Variant;
  iConjunto: Integer;
begin
  Result := nil;
  oConjunto := FCfg.Grid.GetColumnByFieldName(FCfg.FieldConjuntoPivot);
  if oConjunto <> nil then
  begin
    vConjunto := FCfg.Grid.DataController.Values[AIndice, oConjunto.Index];
    iConjunto := 0;
    if not VarIsNull(vConjunto) and not VarIsEmpty(vConjunto) then
      iConjunto := vConjunto;
    if (not VarIsNull(vConjunto) and not VarIsEmpty(vConjunto)) or
       TieneColumnas(iConjunto) then
    begin
      sArticulo := '';
      oArticulo := FCfg.Grid.GetColumnByFieldName(FCfg.FieldArticulo);
      if oArticulo <> nil then
        sArticulo := VarToStr(
          FCfg.Grid.DataController.Values[AIndice, oArticulo.Index])
      else if (FCfg.FieldArticulo <> '') and (Lineas <> nil) then
      begin
        // Lookup hace CheckBrowseMode: con la linea en edicion grabaria
        // lo tecleado en cada repintado y el editor volveria a abrirse
        // con todo seleccionado (FZ-ISSUE-105). En edicion solo se lee
        // la fila en curso.
        if Lineas.State in dsEditModes then
        begin
          if AIndice = FCfg.Grid.DataController.FocusedRecordIndex then
            sArticulo := ArticuloActual;
        end
        else
        begin
          oLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
          if oLinea <> nil then
            sArticulo := VarToStr(Lineas.Lookup(FCfg.FieldLinea,
              FCfg.Grid.DataController.Values[AIndice, oLinea.Index],
              FCfg.FieldArticulo));
        end;
      end;
      Result := GetPosicionesConjunto(iConjunto, sArticulo);
    end;
  end;
end;

// Tallas con cantidad en las líneas de este artículo que hay en la
// rejilla. Sin rejilla (distribuidor) no hay líneas que mirar.
function TGestorGridTallas.TallasConCantidad(
  const AArticulo: string): TArray<Integer>;
var
  aCeldas: TArray<TCeldaTallas>;
  oArticulo, oLinea: TcxGridDBColumn;
  oIds: TList<Integer>;
  i, iCelda, iLinea: Integer;
  vLinea: Variant;
begin
  Result := nil;
  oLinea := nil;
  if Assigned(FCfg.Grid) and (FCfg.FieldLinea <> '') then
    oLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if oLinea <> nil then
  begin
    oArticulo := nil;
    if FCfg.FieldArticulo <> '' then
      oArticulo := FCfg.Grid.GetColumnByFieldName(FCfg.FieldArticulo);
    oIds := TList<Integer>.Create;
    try
      for i := 0 to FCfg.Grid.DataController.RecordCount - 1 do
      begin
        vLinea := FCfg.Grid.DataController.Values[i, oLinea.Index];
        iLinea := 0;
        if (not VarIsNull(vLinea)) and (not VarIsEmpty(vLinea)) and
           ((oArticulo = nil) or SameText(VarToStr(
             FCfg.Grid.DataController.Values[i, oArticulo.Index]),
             AArticulo)) then
          iLinea := vLinea;
        if iLinea > 0 then
        begin
          aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(iLinea);
          for iCelda := 0 to High(aCeldas) do
            if (aCeldas[iCelda].Cantidad <> 0) and
               (not oIds.Contains(aCeldas[iCelda].IdAv)) then
              oIds.Add(aCeldas[iCelda].IdAv);
        end;
      end;
      Result := oIds.ToArray;
    finally
      FreeAndNil(oIds);
    end;
  end;
end;

// FZ-ISSUE-405: con más tallas de las que caben no se lanza un error
// (la pantalla no llegaba a abrirse). Se enseñan las que tienen
// cantidades y después las primeras del sistema, y se avisa.
function TGestorGridTallas.IndicesTallasVisibles(const AArticulo: string;
  const APosiciones: TArray<TPosicionConjuntoTallas>): TArray<Integer>;
var
  aConDatos, aIds: TArray<Integer>;
  i: Integer;
begin
  SetLength(aIds, Length(APosiciones));
  for i := 0 to High(APosiciones) do
    aIds[i] := APosiciones[i].IdAv;
  aConDatos := nil;
  if Length(aIds) > FCfg.MaxColumnas then
  begin
    aConDatos := TallasConCantidad(AArticulo);
    FAvisoTallas.Anotar(AArticulo, Length(aIds), FCfg.MaxColumnas);
  end;
  Result := IndicesTallasHorizontal(aIds, aConDatos, FCfg.MaxColumnas);
end;

function TGestorGridTallas.GetPosicionesConjunto(
  AIdAc: Integer): TArrPosConjunto;
begin
  Result := GetPosicionesConjunto(AIdAc, ArticuloActual);
end;

function TGestorGridTallas.GetPosicionesConjunto(AIdAc: Integer;
  const AArticulo: string): TArrPosConjunto;
var
  aPersistidas: TArray<TPosicionConjuntoTallas>;
  aVisibles: TArray<Integer>;
  arr: TArrPosConjunto;
  i: Integer;
  sArticulo, sClave: string;
begin
  // Devuelve la lista ordenada de (ID_AV, VALOR) del conjunto pivot
  // indicado. Cacheado en FConjuntoPos para no re-consultar por cada
  // refresco / edicion.
  Result := nil;
  sArticulo := AArticulo;
  sClave := IntToStr(AIdAc);
  if AIdAc >= 0 then
    sClave := sClave + '|' + sArticulo;
  if FConjuntoPos <> nil then
  begin
    if not FConjuntoPos.TryGetValue(sClave, Result) and
       (AIdAc >= 0) and ((AIdAc > 0) or (sArticulo <> '') or
        FCfg.ColumnaUnidadesSinTallaje) then
    begin
      aPersistidas := FCfg.Persistencia.ConsultarPosicionesConjunto(
        AIdAc, sArticulo);
      aVisibles := IndicesTallasVisibles(sArticulo, aPersistidas);
      SetLength(arr, Length(aVisibles));
      for i := 0 to High(aVisibles) do
      begin
        arr[i].IdAv := aPersistidas[aVisibles[i]].IdAv;
        arr[i].Valor := aPersistidas[aVisibles[i]].Valor;
      end;
      // Articulo sin tallas: sus unidades van en una columna sin talla.
      if (AIdAc = 0) and (Length(arr) = 0) and
         FCfg.ColumnaUnidadesSinTallaje then
      begin
        SetLength(arr, 1);
        arr[0].IdAv := 0;
        arr[0].Valor := SCaptionColUnidadesSinTallaje;
      end;
      FConjuntoPos.Add(sClave, arr);
      Result := arr;
    end;
  end;
end;

function TGestorGridTallas.LongConjuntoLineaActiva(
  ADataSet: TDataSet): Integer;
var
  iAc: Integer;
begin
  Result := 0;
  iAc := ADataSet.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  if TieneColumnas(iAc) then
    Result := Length(GetPosicionesConjunto(iAc));
end;

function TGestorGridTallas.RecorrerMaxLongConjuntos(
  ADataSet: TDataSet): Integer;
var
  bk     : TBookmark;
  iAc    : Integer;
  arr    : TArrPosConjunto;
begin
  // Iterar el dataset abierto (con DisableControls + bookmark) es mucho
  // mas robusto que reformular el SQL: funciona para cualquier query y
  // no asume nombres de parametros del master.
  Result := 0;
  FReferenciaCaptions := nil;
  bk := ADataSet.GetBookmark;
  ADataSet.DisableControls;
  try
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      iAc := ADataSet.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
      if TieneColumnas(iAc) then
      begin
        arr := GetPosicionesConjunto(iAc, ArticuloActual);
        if Length(arr) > Result then
          Result := Length(arr);
        if (iAc <> 0) and
           (Length(arr) > Length(FReferenciaCaptions)) then
          FReferenciaCaptions := Copy(arr);
      end;
      ADataSet.Next;
    end;
  finally
    if Assigned(bk) then
    begin
      if ADataSet.BookmarkValid(bk) then
        ADataSet.GotoBookmark(bk);
      ADataSet.FreeBookmark(bk);
    end;
    ADataSet.EnableControls;
  end;
end;

function TGestorGridTallas.MaxLongConjuntos: Integer;
var
  ds: TDataSet;
  ColumnaLinea: TcxGridDBColumn;
  iRegistro, iLinea: Integer;
  Posiciones: TArrPosConjunto;
  ValorLinea: Variant;
begin
  Result := 0;
  ds := Lineas;
  if Assigned(ds) and ds.Active and ds.IsEmpty then
  begin
    // Una sesion nueva no hereda el maximo ni las cabeceras de la anterior.
    FUltimoMaxConjuntos := 0;
    FReferenciaCaptions := nil;
  end;
  if HayLineaActiva then
  begin
    if ds.State in dsEditModes then
    begin
      Result := LongConjuntoLineaActiva(ds);
      ColumnaLinea := nil;
      if Assigned(FCfg.Grid) then
        ColumnaLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
      if Assigned(ColumnaLinea) and not ds.IsEmpty then
      begin
        FReferenciaCaptions := nil;
        iLinea := ds.FieldByName(FCfg.FieldLinea).AsInteger;
        for iRegistro := 0 to FCfg.Grid.DataController.RecordCount - 1 do
        begin
          ValorLinea := FCfg.Grid.DataController.Values[
            iRegistro, ColumnaLinea.Index];
          if not VarIsNull(ValorLinea) and not VarIsEmpty(ValorLinea) and
             (Integer(ValorLinea) <> iLinea) then
          begin
            Posiciones := GetPosicionesRegistro(iRegistro);
            if Length(Posiciones) > Result then
              Result := Length(Posiciones);
            if (Length(Posiciones) > Length(FReferenciaCaptions)) and
               (Length(Posiciones) > 0) and
               (Posiciones[0].IdAv <> 0) then
              FReferenciaCaptions := Copy(Posiciones);
          end;
        end;
        FUltimoMaxConjuntos := Result;
      end
      else if FUltimoMaxConjuntos > Result then
        Result := FUltimoMaxConjuntos;
    end
    else
    begin
      Result := RecorrerMaxLongConjuntos(ds);
      FUltimoMaxConjuntos := Result;
    end;
  end;
  if Result > FCfg.MaxColumnas then
    Result := FCfg.MaxColumnas;
end;

procedure TGestorGridTallas.RecalcularMaxColumnas;
var
  i, iMax : Integer;
  sClave: string;
begin
  // Refrescar los SKU sin borrar conjuntos virtuales registrados.
  for sClave in FConjuntoPos.Keys.ToArray do
    if (sClave <> '') and (sClave[1] <> '-') then
      FConjuntoPos.Remove(sClave);
  iMax := MaxLongConjuntos;
  for i := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[i] <> nil then
    begin
      FCfg.ColumnasTallas[i].Visible := (i < iMax);
      if i < iMax then
        FCfg.ColumnasTallas[i].Caption :=
          Format(SCaptionColTallaN, [i + 1]);
    end;
  end;
end;

procedure TGestorGridTallas.ActualizarCaptionsLineaActiva;
var
  ds   : TDataSet;
  iAc  : Integer;
  arr  : TArrPosConjunto;
  i, iRegistro: Integer;
  aReferencia: TArrPosConjunto;
begin
  ds := Lineas;
  if HayLineaActiva then
  begin
    iAc := ds.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
    if TieneColumnas(iAc) then
    begin
      arr := GetPosicionesConjunto(iAc);
      if iAc <> 0 then
        FReferenciaCaptions := Copy(arr);
      if (iAc = 0) and FCfg.ColumnaUnidadesSinTallaje and
         (FCfg.Grid <> nil) and not ds.IsEmpty then
      begin
        for iRegistro := 0 to FCfg.Grid.DataController.RecordCount - 1 do
        begin
          aReferencia := GetPosicionesRegistro(iRegistro);
          if (Length(aReferencia) > Length(arr)) or
             ((Length(aReferencia) = 1) and (Length(arr) = 1) and
              (arr[0].IdAv = 0) and (aReferencia[0].IdAv <> 0)) then
          begin
            arr := Copy(aReferencia);
            FReferenciaCaptions := Copy(aReferencia);
          end;
        end;
      end;
      // Al insertar, el grid puede no tener aún las filas publicadas.
      // Se conservan las tallas de las líneas existentes, sin renombrar 80.
      // Pintar cabeceras no recorre el dataset: EnableControls vuelve a
      // notificar el foco del grid y provocaría una recursión sin fin.
      if (iAc = 0) and (FUltimoMaxConjuntos > 1) and
         (Length(FReferenciaCaptions) > 0) then
        arr := Copy(FReferenciaCaptions);
      for i := 0 to High(FCfg.ColumnasTallas) do
      begin
        if (FCfg.ColumnasTallas[i] <> nil) and
           FCfg.ColumnasTallas[i].Visible then
        begin
          if i < Length(arr) then
            FCfg.ColumnasTallas[i].Caption := arr[i].Valor
          else
            FCfg.ColumnasTallas[i].Caption :=
              Format(SCaptionColTallaN, [i + 1]);
        end;
      end;
    end;
  end;
end;

procedure TGestorGridTallas.CargarCantidadesTodasLineas;
var
  i, iLinea : Integer;
  colLinea  : TcxGridDBColumn;
  vLinea    : Variant;
begin
  // Estrategia correcta para columnas no-bound en cxGridDBTableView:
  // iterar el DataController del propio grid, NO el dataset subyacente.
  //   - ds.DisableControls/EnableControls sobre el dataset hace que
  //     cxGrid limpie los Values[] no-bound al EnableControls (resetea
  //     el DataController desde cero).
  //   - DataController.BeginUpdate/EndUpdate suspende solo el cxGrid
  //     sin tocar el dataset; al EndUpdate el grid repinta de una vez
  //     con todos los Values[] que hayamos asignado en memoria.
  //   - Leer LINEA por Values[recordIdx, colLinea.Index] saca el dato
  //     sin tocar el cursor del dataset y sin disparar refrescos.
  if HayLineaActiva and PuedeRecargarCantidades then
  begin
    colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
    if colLinea <> nil then
    begin
      FCfg.Grid.DataController.BeginUpdate;
      try
        for i := 0 to FCfg.Grid.DataController.RecordCount - 1 do
        begin
          vLinea := FCfg.Grid.DataController.Values[i, colLinea.Index];
          if not VarIsNull(vLinea) and not VarIsEmpty(vLinea) then
          begin
            iLinea := vLinea;
            if iLinea > 0 then
              CargarCantidadesUnaLinea(i, iLinea);
          end;
        end;
      finally
        FCfg.Grid.DataController.EndUpdate;
      end;
    end;
  end;
end;

procedure TGestorGridTallas.CargarCantidadesUnaLinea(
  ARecordIndex, ALinea: Integer);
var
  aCeldas: TArray<TCeldaTallas>;
  arr: TArrPosConjunto;
  i, iCelda: Integer;
  rCantidad: Double;
begin
  if PuedeRecargarCantidades and (ARecordIndex >= 0) and
     (ARecordIndex < FCfg.Grid.DataController.RecordCount) then
  begin
    // Values[] es no-bound: antes de reconstruir la fila hay que borrar
    // tambien las posiciones del sistema anterior para no desplazar tallas.
    for i := 0 to High(FCfg.ColumnasTallas) do
      if Assigned(FCfg.ColumnasTallas[i]) then
        FCfg.Grid.DataController.Values[
          ARecordIndex, FCfg.ColumnasTallas[i].Index] := 0;
    // Sin sistema (NULL) tambien hay posiciones si se admite la columna
    // de unidades: las tallas de los SKU del articulo (FZ-ISSUE-140).
    arr := GetPosicionesRegistro(ARecordIndex);
    if Length(arr) > 0 then
    begin
      aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(ALinea);
      for i := 0 to High(arr) do
      begin
        rCantidad := 0;
        for iCelda := 0 to High(aCeldas) do
        begin
          if aCeldas[iCelda].IdAv = arr[i].IdAv then
            rCantidad := rCantidad + aCeldas[iCelda].Cantidad;
        end;
        if (i <= High(FCfg.ColumnasTallas)) and
           Assigned(FCfg.ColumnasTallas[i]) then
          FCfg.Grid.DataController.Values[
            ARecordIndex, FCfg.ColumnasTallas[i].Index] := rCantidad;
      end;
    end;
  end;
end;

function TGestorGridTallas.PuedeRecargarCantidades: Boolean;
var
  Editor: TcxCustomEdit;
begin
  Result := True;
  if FCfg.Grid.Controller.EditingController.IsEditing then
  begin
    Editor := FCfg.Grid.Controller.EditingController.Edit;
    // Una recarga diferida no puede sustituir el texto aun sin confirmar
    // por el valor anterior de la celda (FZ-ISSUE-836). Al confirmar,
    // PersistirCeldaActiva publica las cantidades con IsPosting activo.
    Result := not Assigned(Editor) or not Editor.ModifiedAfterEnter or
      Editor.IsPosting or Editor.IsEditValidating;
  end;
end;

procedure TGestorGridTallas.PersistirCantidad(
  ALinea, AIdAv: Integer; ACantidad: Double);
begin
  LogSes(Format(
    'Tallas.PersistirCantidad: linea=%d idAv=%d cantidad=%g',
    [ALinea, AIdAv, ACantidad]));
  if (ALinea > 0) and
     ((AIdAv > 0) or ((AIdAv = 0) and FCfg.ColumnaUnidadesSinTallaje)) then
    FCfg.Persistencia.FijarCantidadCelda(
      ALinea, AIdAv, ACantidad, '')
  else
    LogSes('  guard: ALinea<=0 o AIdAv<=0, salida');
end;
procedure TGestorGridTallas.RefrescarTotalesLineaActual;
var
  aCeldas: TArray<TCeldaTallas>;
  ds: TDataSet;
  i, iLinea: Integer;
  rPrecio, rTotal: Double;
begin
  ds := Lineas;
  if HayLineaActiva then
  begin
    iLinea := ds.FieldByName(FCfg.FieldLinea).AsInteger;
    if iLinea > 0 then
    begin
      aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(iLinea);
      rTotal := 0;
      for i := 0 to High(aCeldas) do
        rTotal := rTotal + aCeldas[i].Cantidad;
      rPrecio := PrecioLineaActual;
      FCfg.Grid.DataController.BeginUpdate;
      try
        if not (ds.State in [dsEdit, dsInsert]) then
          ds.Edit;
        if (FCfg.FieldTotalUds <> '') and
           Assigned(ds.FindField(FCfg.FieldTotalUds)) then
          ds.FieldByName(FCfg.FieldTotalUds).AsFloat := rTotal;
        if (FCfg.FieldTotalLinea <> '') and
           Assigned(ds.FindField(FCfg.FieldTotalLinea)) then
          ds.FieldByName(FCfg.FieldTotalLinea).AsFloat :=
            rTotal * rPrecio;
      finally
        FCfg.Grid.DataController.EndUpdate;
      end;
    end;
  end;
end;

function TGestorGridTallas.PrecioLineaActual: Double;
begin
  Result := 0;
  if (FCfg.FieldPrecioBase <> '') and
     Assigned(Lineas.FindField(FCfg.FieldPrecioBase)) then
    Result := Lineas.FieldByName(FCfg.FieldPrecioBase).AsFloat;
end;

// Total que tendrá la línea si la celda pasa a ACantidad: las demás celdas
// ya grabadas más la nueva, por el precio (como RefrescarTotalesLineaActual).
function TGestorGridTallas.AceptaCantidadCelda(ALinea, AIdAv: Integer;
  ACantidad: Double; out ACantidadAnterior: Double): Boolean;
var
  aCeldas: TArray<TCeldaTallas>;
  i: Integer;
  rUnidades: Double;
begin
  ACantidadAnterior := 0;
  Result := not Assigned(FCfg.ConfirmarTotalLinea);
  if not Result then
  begin
    rUnidades := ACantidad;
    aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(ALinea);
    for i := 0 to High(aCeldas) do
    begin
      if (aCeldas[i].IdAv = AIdAv) and (Trim(aCeldas[i].Almacen) = '') then
        ACantidadAnterior := aCeldas[i].Cantidad
      else
        rUnidades := rUnidades + aCeldas[i].Cantidad;
    end;
    Result := FCfg.ConfirmarTotalLinea(rUnidades * PrecioLineaActual);
  end;
end;

// El editor sigue mostrando la cantidad rechazada y la volvería a mandar
// al salir de la celda: se le devuelve la grabada.
procedure TGestorGridTallas.RevertirCelda(AEditor: TcxCustomEdit;
  ACantidad: Double);
begin
  FRevirtiendoCelda := True;
  try
    AEditor.EditValue := ACantidad;
    AEditor.PostEditValue;
  finally
    FRevirtiendoCelda := False;
  end;
end;

function TGestorGridTallas.ValidarSistemaSeleccionado: Boolean;
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  Result := True;
  if HayLineaActiva then
  begin
    iAc := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
    if iAc > 0 then
    begin
      arr := GetPosicionesConjunto(iAc);
      if Length(arr) > FCfg.MaxColumnas then
      begin
        MessageDlg_fza(Format(SAvisoSistemaTallasSuperaMaximo,
          [Length(arr), FCfg.MaxColumnas]),
          mtError, [mbOk], 0);
        if not (Lineas.State in [dsEdit, dsInsert]) then
          Lineas.Edit;
        Lineas.FieldByName(FCfg.FieldConjuntoPivot).Clear;
        Result := False;
      end;
    end;
  end;
end;

procedure TGestorGridTallas.PersistirCeldaActiva(ASender: TObject);
var
  ed     : TcxCustomEdit;
  item   : TcxCustomGridTableItem;
  iPos   : Integer;
  iLinea : Integer;
  iAc    : Integer;
  arr    : TArrPosConjunto;
  rCant  : Double;
  rAntes : Double;
  vEdit  : Variant;
  idxRec : Integer;
begin
  if (ASender is TcxCustomEdit) and not FRevirtiendoCelda then
  begin
    ed := TcxCustomEdit(ASender);
    ed.PostEditValue;
    item := FCfg.Grid.Controller.FocusedItem;
    if item <> nil then
    begin
      iPos := item.Tag;
      if (iPos >= 1) and (iPos <= FCfg.MaxColumnas) and
         HayLineaActiva then
      begin
        iLinea := Lineas.FieldByName(FCfg.FieldLinea).AsInteger;
        iAc := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
        arr := GetPosicionesConjunto(iAc);
        LogSes(Format(
          'Tallas.PersistirCeldaActiva: linea=%d pos=%d/%d ' +
          'iAc=%d Lineas.State=%d',
          [iLinea, iPos, Length(arr), iAc, Ord(Lineas.State)]));
        if iPos > Length(arr) then
          LogSes('  guard: iPos fuera del conjunto pivot, salida')
        else
        begin
          vEdit := ed.EditValue;
          if VarIsNull(vEdit) or VarIsClear(vEdit) then
            rCant := 0
          else
            rCant := vEdit;
          idxRec := FCfg.Grid.Controller.FocusedRecordIndex;
          // Rechazada (FZ-ISSUE-255): no se graba y la celda recupera la
          // cantidad que tenía.
          if AceptaCantidadCelda(iLinea, arr[iPos - 1].IdAv, rCant,
                                 rAntes) then
          begin
            PersistirCantidad(iLinea, arr[iPos - 1].IdAv, rCant);
            RefrescarTotalesLineaActual;
          end
          else
            RevertirCelda(ed, rAntes);
          if idxRec >= 0 then
            CargarCantidadesUnaLinea(idxRec, iLinea);
          if Assigned(FCfg.Grid) and Assigned(FCfg.Grid.Site) then
            FCfg.Grid.Site.Invalidate;
        end;
      end;
    end;
  end;
end;

// =============================================================================
//   Helpers libres
// =============================================================================

procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);
  procedure CambiarEn(AOwner: TComponent);
  var
    i : Integer;
  begin
    if Assigned(AOwner) then
    begin
      for i := 0 to AOwner.ComponentCount - 1 do
      begin
        if AOwner.Components[i] is TJvEnterAsTab then
          TJvEnterAsTab(AOwner.Components[i]).EnterAsTab := AActivo;
      end;
    end;
  end;
begin
  CambiarEn(AForm);
  if Assigned(AForm) then
    CambiarEn(AForm.Owner);
  CambiarEn(Application.MainForm);
end;

procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);
begin
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

end.

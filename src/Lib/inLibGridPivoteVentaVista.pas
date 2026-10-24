{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteVentaVista                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vista temporal del pivote de venta (fascículo V4 del anexo SRP): el       }
{    TClientDataSet copia del dataset real con una fila por línea de           }
{    vista/banda, su desvío del DataSource del grid y la redirección del       }
{    Delete al borrado real del grupo. Conoce VCL y datasets; recibe el        }
{    modelo y callbacks tipados.                                               }
{******************************************************************************}
unit inLibGridPivoteVentaVista;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, Data.DB,
  Datasnap.DBClient,
  cxGridDBTableView,
  inLibPivoteVentaModelo;

const
  CAMPO_LINEA_VISTA_PIVOTE = '__LINEA_VISTA_PV';
  CAMPO_PESTANA_VISTA_PIVOTE = '__PESTANA_VISTA_PV';

type
  // DataSource de la copia en memoria que el pivote pone en la rejilla.
  // Recuerda el de las líneas reales, que el pivote mantiene en la línea
  // enfocada: la foto del artículo lo sigue sin depender del modo.
  TDataSourceVistaPivote = class(TDataSource)
  private
    FOriginal: TDataSource;
  public
    property Original: TDataSource read FOriginal write FOriginal;
  end;

  TLogPivoteVentaEvent = procedure(const AMensaje: string) of object;
  // Configuración de la vista temporal: grid, datasets y campos host.
  TConfigVistaPivoteVenta = record
    View              : TcxGridDBTableView;
    SourceLineas      : TDataSource;
    CdsFallback       : TDataSet;
    FieldLinea        : string;
    FieldArt          : string;
    FieldSku          : string;
    FieldTotalUdsGrupo: string;
    FieldImporteLinea : string;
    FieldPrecioBase   : string;
    BandaUnica        : Boolean;
    AlLogWarning      : TLogPivoteVentaEvent;
  end;
  TBorrarGrupoVistaEvent = function(
    ALineaBase: Integer): Integer of object;
  TAvisoVistaPivoteVenta = procedure of object;
  // Valor tecleado en la copia visual sobre una fila ya existente: la
  // presentacion decide si es una columna del documento y lo lleva a
  // las lineas reales del grupo.
  TCampoEditadoVistaEvent = procedure(ALineaVista: Integer;
    AField: TField) of object;
  TVistaPivoteVenta = class
  private
    FCfg           : TConfigVistaPivoteVenta;
    FModelo        : TModeloPivoteVenta;
    FAlBorrarGrupo : TBorrarGrupoVistaEvent;
    FAlRecargar    : TAvisoVistaPivoteVenta;
    FCdsVista      : TClientDataSet;
    FDsVista       : TDataSourceVistaPivote;
    FDataSourceOrig: TDataSource;
    FBorradorAlta  : Boolean;
    // True mientras el View del host apunta a FDsVista. Sin este flag,
    // el destructor tocaba View.DataController con el grid YA
    // destruido (AV en GetProvider al cerrar el Mto, 08/07/26).
    FVistaDesviada : Boolean;
    FAlCampoEditado: TCampoEditadoVistaEvent;
    // Importe de cada línea real por número, para el total del grupo.
    FImportesLinea : TDictionary<Integer, Double>;
    function CdsLineas: TDataSet;
    procedure CargarImportesLineas(ADs: TDataSet);
    function ImporteGrupo(ALineaVista: Integer;
                          out AImporte: Double): Boolean;
    procedure VistaBeforeDelete(DataSet: TDataSet);
    procedure VistaCampoChange(Sender: TField);
    procedure AnadirFilaVacia;
    procedure CopiarLineaVista(AOrigen: TDataSet;
                               ALineaVista: Integer);
  public
    constructor Create(const ACfg: TConfigVistaPivoteVenta;
                        AModelo: TModeloPivoteVenta;
                        AAlBorrarGrupo: TBorrarGrupoVistaEvent;
                        AAlRecargar: TAvisoVistaPivoteVenta);
    destructor Destroy; override;
    procedure Preparar;
    procedure Restaurar;
    procedure Reconstruir;
    procedure IniciarAlta;
    procedure FinalizarAlta;
    function AltaPendiente: Boolean;
    function EsInsercionVacia(ADs: TDataSet): Boolean;
    function FilasVista: Integer;
    // La copia es solo visual: sin este aviso, lo tecleado en precio,
    // IVA, almacen... se quedaba en ella y nunca llegaba a las lineas
    // (FZ-ISSUE-033).
    property AlCampoEditado: TCampoEditadoVistaEvent read FAlCampoEditado
                                                     write FAlCampoEditado;
  end;

// Posiciona ADs en la línea real ALinea probando los formatos de
// numeración según documento: 4 dígitos ('0010'), 3 ('010') y entero.
function LocalizarLineaRealPivote(ADs: TDataSet;
                                  const ACampoLinea: string;
                                  ALinea: Integer): Boolean;

implementation

uses
  inLibMensajesVcl,
  System.UITypes, Vcl.Dialogs, inLibMsgArticulos, inLibPivoteVentaCalculo;

function LocalizarLineaRealPivote(ADs: TDataSet;
  const ACampoLinea: string; ALinea: Integer): Boolean;
begin
  Result := False;
  if (ADs <> nil) and ADs.Active and (ALinea > 0) then
  begin
    Result := ADs.Locate(ACampoLinea, Format('%.4d', [ALinea]), []);
    if not Result then
      Result := ADs.Locate(ACampoLinea, Format('%.3d', [ALinea]), []);
    if not Result then
      Result := ADs.Locate(ACampoLinea, IntToStr(ALinea), []);
  end;
end;

constructor TVistaPivoteVenta.Create(
  const ACfg: TConfigVistaPivoteVenta; AModelo: TModeloPivoteVenta;
  AAlBorrarGrupo: TBorrarGrupoVistaEvent;
  AAlRecargar: TAvisoVistaPivoteVenta);
begin
  inherited Create;
  FCfg := ACfg;
  FModelo := AModelo;
  FAlBorrarGrupo := AAlBorrarGrupo;
  FAlRecargar := AAlRecargar;
  FCdsVista := TClientDataSet.Create(nil);
  FDsVista := TDataSourceVistaPivote.Create(nil);
  FDsVista.DataSet := FCdsVista;
  FImportesLinea := TDictionary<Integer, Double>.Create;
end;

destructor TVistaPivoteVenta.Destroy;
begin
  Restaurar;
  FreeAndNil(FDsVista);
  FreeAndNil(FCdsVista);
  FreeAndNil(FImportesLinea);
  inherited;
end;

procedure TVistaPivoteVenta.CargarImportesLineas(ADs: TDataSet);
var
  oCampoLinea, oCampoImporte: TField;
  iLinea: Integer;
begin
  FImportesLinea.Clear;
  oCampoLinea := ADs.FindField(FCfg.FieldLinea);
  oCampoImporte := nil;
  if FCfg.FieldImporteLinea <> '' then
    oCampoImporte := ADs.FindField(FCfg.FieldImporteLinea);
  // Solo en consulta: recorrer un dataset en edición lo grabaría.
  if (oCampoLinea <> nil) and (oCampoImporte <> nil) and
     (ADs.State = dsBrowse) then
  begin
    ADs.First;
    while not ADs.Eof do
    begin
      iLinea := StrToIntDef(Trim(oCampoLinea.AsString), 0);
      if iLinea > 0 then
        FImportesLinea.AddOrSetValue(iLinea, oCampoImporte.AsFloat);
      ADs.Next;
    end;
  end;
end;

// La fila Pedido de un grupo resume todas sus tallas: antes mostraba el
// importe de la línea representante, es decir, solo la primera talla
// (FZ-ISSUE-317).
function TVistaPivoteVenta.ImporteGrupo(ALineaVista: Integer;
  out AImporte: Double): Boolean;
var
  dImporte: Double;
  sLinea: string;
begin
  AImporte := 0;
  Result := False;
  for sLinea in FModelo.LineasRealesDeGrupo(
                  FModelo.ObtenerLineaBase(ALineaVista)) do
    if FImportesLinea.TryGetValue(StrToIntDef(Trim(sLinea), 0),
                                  dImporte) then
    begin
      AImporte := AImporte + dImporte;
      Result := True;
    end;
end;

function TVistaPivoteVenta.CdsLineas: TDataSet;
begin
  Result := nil;
  if FCfg.SourceLineas <> nil then
    Result := FCfg.SourceLineas.DataSet;
  if Result = nil then
    Result := FCfg.CdsFallback;
end;

procedure TVistaPivoteVenta.VistaBeforeDelete(DataSet: TDataSet);
var
  iLineaBase: Integer;
begin
  // Delete contra la VISTA temporal (Ctrl+Supr, navigator...): la
  // vista es una copia en memoria, borrar su fila no toca las líneas
  // reales y el grupo "reaparecía" al recargar. Se redirige al borrado
  // real del grupo completo y se aborta el delete de la copia.
  iLineaBase := 0;
  if DataSet.FindField(CAMPO_LINEA_VISTA_PIVOTE) <> nil then
    iLineaBase := FModelo.ObtenerLineaBase(
      DataSet.FieldByName(CAMPO_LINEA_VISTA_PIVOTE).AsInteger);
  if iLineaBase = 0 then
    FBorradorAlta := False
  else if Assigned(FAlBorrarGrupo) then
  begin
    if MessageDlg_fza(SPreguntaEliminarLineaTallasVenta,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if (FAlBorrarGrupo(iLineaBase) > 0) and
         Assigned(FAlRecargar) then
        FAlRecargar();
    end;
    Abort;
  end;
end;

procedure TVistaPivoteVenta.VistaCampoChange(Sender: TField);
var
  oCampoLinea: TField;
begin
  // Solo la edicion de una fila existente (dsEdit): las copias de
  // Reconstruir y la fila vacia de alta se escriben en dsInsert.
  if Assigned(FAlCampoEditado) and (FCdsVista.State = dsEdit) then
  begin
    oCampoLinea := FCdsVista.FindField(CAMPO_LINEA_VISTA_PIVOTE);
    if (oCampoLinea <> nil) and (oCampoLinea.AsInteger > 0) then
      FAlCampoEditado(oCampoLinea.AsInteger, Sender);
  end;
end;

procedure TVistaPivoteVenta.AnadirFilaVacia;
begin
  if (FCdsVista <> nil) and FCdsVista.Active then
  begin
    FCdsVista.Append;
    if FCdsVista.FindField(CAMPO_LINEA_VISTA_PIVOTE) <> nil then
      FCdsVista.FieldByName(
        CAMPO_LINEA_VISTA_PIVOTE).AsInteger := 0;
    if FCdsVista.FindField(FCfg.FieldLinea) <> nil then
      FCdsVista.FieldByName(FCfg.FieldLinea).AsString := '0000';
    FCdsVista.Post;
  end;
end;

function TVistaPivoteVenta.EsInsercionVacia(ADs: TDataSet): Boolean;
  function CampoVacio(const ACampo: string): Boolean;
  var
    oCampo: TField;
  begin
    Result := True;
    if (ADs <> nil) and (ACampo <> '') then
    begin
      oCampo := ADs.FindField(ACampo);
      if oCampo <> nil then
        Result := Trim(oCampo.AsString) = '';
    end;
  end;
begin
  Result := (ADs <> nil) and (ADs.State = dsInsert) and
            CampoVacio(FCfg.FieldArt) and CampoVacio(FCfg.FieldSku) and
            CampoVacio('CODIGOPRODPS_PEDLIN');
end;

function TVistaPivoteVenta.FilasVista: Integer;
begin
  Result := 0;
  if (FCdsVista <> nil) and FCdsVista.Active then
    Result := FCdsVista.RecordCount;
end;

procedure TVistaPivoteVenta.Preparar;
var
  oDs: TDataSet;
  oCampo: TField;
  oDef: TFieldDef;
  i: Integer;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and (FCdsVista <> nil) then
  begin
    if FCdsVista.Active then
      FCdsVista.Close;
    FCdsVista.FieldDefs.Clear;
    for i := 0 to oDs.Fields.Count - 1 do
    begin
      oCampo := oDs.Fields[i];
      if oCampo.FieldKind = fkData then
      begin
        oDef := FCdsVista.FieldDefs.AddFieldDef;
        oDef.Name := oCampo.FieldName;
        oDef.DataType := oCampo.DataType;
        oDef.Size := oCampo.Size;
        oDef.Required := False;
      end;
    end;
    oDef := FCdsVista.FieldDefs.AddFieldDef;
    oDef.Name := CAMPO_LINEA_VISTA_PIVOTE;
    oDef.DataType := ftInteger;
    oDef.Required := False;
    oDef := FCdsVista.FieldDefs.AddFieldDef;
    oDef.Name := CAMPO_PESTANA_VISTA_PIVOTE;
    oDef.DataType := ftWideString;
    oDef.Size := 100;
    FCdsVista.CreateDataSet;
    // Intercepta Ctrl+Supr / navigator sobre la vista: redirige al
    // borrado real del grupo y aborta el delete de la copia.
    FCdsVista.BeforeDelete := VistaBeforeDelete;
    for i := 0 to FCdsVista.Fields.Count - 1 do
      if not SameText(FCdsVista.Fields[i].FieldName,
                      CAMPO_LINEA_VISTA_PIVOTE) then
        FCdsVista.Fields[i].OnChange := VistaCampoChange;
    if (FCfg.View <> nil) and
       (FCfg.View.DataController.DataSource <> FDsVista) then
    begin
      FDataSourceOrig := FCfg.View.DataController.DataSource;
      FDsVista.Original := FDataSourceOrig;
      FCfg.View.DataController.DataSource := FDsVista;
    end;
    FVistaDesviada := FCfg.View <> nil;
  end;
end;

procedure TVistaPivoteVenta.Restaurar;
begin
  // Solo se toca el View si la vista temporal sigue montada: tras un
  // Desmontar del host no queda nada que restaurar y el destructor no
  // debe dereferenciar un grid posiblemente destruido.
  if FVistaDesviada then
  begin
    try
      if (FCfg.View <> nil) and
         (not (csDestroying in FCfg.View.ComponentState)) then
        FCfg.View.DataController.DataSource := FDataSourceOrig;
    except
      // Cierre defensivo: si DevExpress ya destruyó el provider no hay
      // nada que restaurar y no debemos impedir cerrar la ficha.
      on E: Exception do
        if Assigned(FCfg.AlLogWarning) then
          FCfg.AlLogWarning(
            'PivoteVista.Restaurar fallo: ' + E.Message);
    end;
    FVistaDesviada := False;
  end;
  FDataSourceOrig := nil;
  FDsVista.Original := nil;
end;

procedure TVistaPivoteVenta.CopiarLineaVista(AOrigen: TDataSet;
  ALineaVista: Integer);
var
  oCampoOri, oCampoDst: TField;
  i: Integer;
  rUds, rImporte: Double;
  oGrupo: TGrupoPivoteVenta;
begin
  if (AOrigen <> nil) and (FCdsVista <> nil) and FCdsVista.Active then
  begin
    FCdsVista.Append;
    for i := 0 to AOrigen.Fields.Count - 1 do
    begin
      oCampoOri := AOrigen.Fields[i];
      oCampoDst := FCdsVista.FindField(oCampoOri.FieldName);
      if (oCampoOri.FieldKind = fkData) and (oCampoDst <> nil) and
         (not (oCampoOri.DataType in [ftBlob, ftGraphic, ftMemo,
                                      ftFmtMemo, ftBytes, ftVarBytes,
                                      ftWideMemo])) then
        oCampoDst.Value := oCampoOri.Value;
    end;
    oCampoDst := FCdsVista.FindField(CAMPO_LINEA_VISTA_PIVOTE);
    if oCampoDst <> nil then
      oCampoDst.AsInteger := ALineaVista;
    // En banda única, la columna Total del host pasa a UNIDADES del
    // grupo: el importe de la línea representante descuadraba con la
    // suma de las celdas (el importe del documento vive en el pie).
    if FCfg.BandaUnica and (FCfg.FieldTotalUdsGrupo <> '') then
    begin
      oCampoDst := FCdsVista.FindField(FCfg.FieldTotalUdsGrupo);
      if oCampoDst <> nil then
      begin
        if FModelo.UdsGrupoDeLineaVista(ALineaVista, rUds) then
          oCampoDst.AsFloat := rUds
        else
          oCampoDst.Clear;
      end;
    end;
    // Con bandas solo la fila Pedido lleva el importe, el del grupo
    // entero: en A albaranar / A recibir y Pendiente repetía el total.
    if (not FCfg.BandaUnica) and (FCfg.FieldImporteLinea <> '') then
    begin
      oCampoDst := FCdsVista.FindField(FCfg.FieldImporteLinea);
      if oCampoDst <> nil then
      begin
        if FModelo.BandaDesdeLinea(ALineaVista) <> bpvPedida then
          oCampoDst.Clear
        else if ImporteGrupo(ALineaVista, rImporte) then
          oCampoDst.AsFloat := rImporte;
      end;
    end;
    // Un coste único sería engañoso cuando cada talla tiene el suyo.
    // Solo se limpia la copia visual; el modo SKU conserva el desglose.
    if (FCfg.FieldPrecioBase <> '') and
       FModelo.Grupo(FModelo.ObtenerLineaBase(ALineaVista), oGrupo) and
       oGrupo.PreciosDistintos then
    begin
      oCampoDst := FCdsVista.FindField(FCfg.FieldPrecioBase);
      if oCampoDst <> nil then
        oCampoDst.Clear;
    end;
    // El número de línea visible ya viene copiado de la línea BASE
    // real: se conserva su formato original.
    if FModelo.Grupo(FModelo.ObtenerLineaBase(ALineaVista), oGrupo) then
      FCdsVista.FieldByName(CAMPO_PESTANA_VISTA_PIVOTE).AsString :=
        oGrupo.PestanaTexto;
    FCdsVista.Post;
  end;
end;

procedure TVistaPivoteVenta.Reconstruir;
var
  oDs: TDataSet;
  oBm: TBookmark;
  iLineaVista, iLineaBase, iLineaActiva: Integer;
  bFiltrado, bAnadida, bLineaActiva: Boolean;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active and (FCdsVista <> nil) and
     FCdsVista.Active then
  begin
    bLineaActiva := (not FCdsVista.IsEmpty) and
      (FCdsVista.FindField(CAMPO_LINEA_VISTA_PIVOTE) <> nil);
    if bLineaActiva then
      iLineaActiva := FCdsVista.FieldByName(
        CAMPO_LINEA_VISTA_PIVOTE).AsInteger
    else
      iLineaActiva := 0;
    FCdsVista.DisableControls;
    try
      FCdsVista.EmptyDataSet;
      if EsInsercionVacia(oDs) or oDs.IsEmpty then
        AnadirFilaVacia
      else
      begin
        oDs.DisableControls;
        oBm := nil;
        bFiltrado := oDs.Filtered;
        try
          if not oDs.IsEmpty then
            oBm := oDs.GetBookmark;
          oDs.Filtered := False;
          CargarImportesLineas(oDs);
          for iLineaVista in FModelo.LineasVista do
          begin
            iLineaBase := FModelo.ObtenerLineaBase(iLineaVista);
            bAnadida := LocalizarLineaRealPivote(oDs, FCfg.FieldLinea,
                                                 iLineaBase);
            if bAnadida then
              CopiarLineaVista(oDs, iLineaVista)
            else if Assigned(FCfg.AlLogWarning) then
              // Error DOCUMENTADO: una fila del pivote se pierde. Sin
              // este aviso la línea "desaparecía" en silencio.
              FCfg.AlLogWarning(Format(
                'PivVenta.Vista: linea base %d NO localizada en el ' +
                'dataset (formatos probados: %.4d / %.3d / %d); la ' +
                'fila pivotada %d se OMITE de la vista temporal',
                [iLineaBase, iLineaBase, iLineaBase, iLineaBase,
                 iLineaVista]));
          end;
          if FCdsVista.IsEmpty and (not oDs.IsEmpty) then
            CopiarLineaVista(oDs, 0);
          if FBorradorAlta then
            AnadirFilaVacia;
          if (oBm <> nil) and oDs.BookmarkValid(oBm) then
            oDs.GotoBookmark(oBm);
        finally
          oDs.Filtered := bFiltrado;
          oDs.EnableControls;
          if oBm <> nil then
            oDs.FreeBookmark(oBm);
        end;
      end;
      if bLineaActiva and (not FCdsVista.IsEmpty) then
        FCdsVista.Locate(
          CAMPO_LINEA_VISTA_PIVOTE, iLineaActiva, []);
    finally
      FCdsVista.EnableControls;
    end;
  end;
end;

procedure TVistaPivoteVenta.IniciarAlta;
begin
  FBorradorAlta := True;
  if (FCdsVista <> nil) and FCdsVista.Active then
  begin
    if FCdsVista.State in dsEditModes then
      FCdsVista.Post;
    if not FCdsVista.Locate(
      CAMPO_LINEA_VISTA_PIVOTE, 0, []) then
      AnadirFilaVacia;
  end;
end;

procedure TVistaPivoteVenta.FinalizarAlta;
begin
  FBorradorAlta := False;
end;

function TVistaPivoteVenta.AltaPendiente: Boolean;
begin
  Result := FBorradorAlta;
end;

end.

{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionCopiaLineas                   }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Copia de lineas de una sesion de compra desde el boton "Otro color".      }
{    Las reglas comerciales viven en inLibGestorCopiaLineasCompra; aqui solo   }
{    queda el efecto sobre el grid, las cantidades y los precios por talla.    }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionCopiaLineas;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  cxEdit,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPresentacionIntf,
  inLibGestorCopiaLineasCompra,
  inLibGridTallasInline;

type
  TEntornoCopiaLineasSesion = record
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Vista: TcxGridDBTableView;
    ColumnasTallas: TArray<TcxGridDBColumn>;
    ColumnaColor: TcxGridDBColumn;
    // Columna de la copa (pestañas); nil con «Tallas y colores».
    ColumnaPestana: TcxGridDBColumn;
    ObtenerGestorTallas: TFunc<TGestorGridTallas>;
    RefrescarTotalesSesion: TProc;
    // Reordena y renumera las líneas; devuelve el número nuevo de la
    // línea indicada (FZ-ISSUE-416).
    ReordenarLineas: TFunc<Integer, Integer>;
    // Tras copiar en otro color (origen, destino): aplica a la
    // copia el coste y PVP por talla de la origen (FZ-ISSUE-638).
    CopiarPreciosTalla: TProc<Integer, Integer>;
  end;

  TCoordinadorCopiaLineasSesion = class
  private
    FEntorno: TEntornoCopiaLineasSesion;
    FGestor: TGestorCopiaLineasCompra;
    FPlanificadorDistribucion: IPlanificadorDiferido;
    FPlanificadorRecarga: IPlanificadorDiferido;
    FLineaOrigenDistribucion: Integer;
    FLineaDestinoDistribucion: Integer;
    FSerieDistribucion: string;
    FNumeroDistribucion: string;
    function GestorTallas: TGestorGridTallas;
    function EsFormatoDistribuido: Boolean;
    function ReordenarTrasCopia(ALineaDestino: Integer): Integer;
    function ObtenerSiguienteLinea(ALineaOrigen: Integer): Integer;
    function LeerCantidadesLineaActiva: TArray<Double>;
    procedure CopiarCeldasDistribuidas(
      ALineaOrigen, ALineaDestino: Integer);
    procedure ReponerCantidadesDuplicado(
      const AResultado: TResultadoCopiaLineaCompra;
      const ACantidades: TArray<Double>);
    procedure ColocarFocoEnCopia(ALineaDestino: Integer);
    procedure RecargarTallasDiferido;
    procedure CopiarPreciosTalla(
      const AResultado: TResultadoCopiaLineaCompra);
    function LineaTieneCantidades(ALinea: Integer): Boolean;
    procedure CopiarCantidadesEntreLineas(
      ALineaOrigen, ALineaDestino: Integer);
    procedure PreguntarDistribucion(ALineaOrigen: Integer);
    function DuplicarConModo(AModo: TModoCopiaLineaCompra;
      const APestana: string): TResultadoCopiaLineaCompra;
    procedure ColocarFoco(ALineaDestino: Integer;
      AColumna: TcxGridDBColumn);
    function PestanasDelModeloYColor: TArray<string>;
    function EsMismoModeloYColor(const AReferencia, AColor: string): Boolean;
  public
    constructor Create(const AEntorno: TEntornoCopiaLineasSesion);
    destructor Destroy; override;
    // Otro color: copia precios, precios por talla y cantidades y deja
    // el color vacio. Los precios distintos por talla se dan con F1.
    procedure DuplicarLineaActiva;
    // Otra copa: copia la línea con su color y deja la copa por teclear.
    procedure DuplicarLineaOtraPestana;
    procedure DuplicarLineaOtroLote;
    // Todas las copas: una línea por cada valor de ATodos que el modelo y
    // color de la línea activa no tengan. Si la activa no tiene copa,
    // toma la primera que falte. Devuelve cuántas líneas se crearon.
    function DuplicarLineaTodasPestanas(
      const ATodos: TArray<string>): Integer;
    // La linea actual reutiliza el modelo de ALineaOrigen: pregunta si se
    // le aplica la misma distribucion de cantidades (normal o por
    // almacen) con sus precios por talla. Diferido: no puede abrirse un
    // modal mientras el grid cierra el editor in-place.
    procedure OfrecerDistribucion(ALineaOrigen: Integer);
  end;

implementation

uses
  System.UITypes,
  Vcl.Dialogs,
  inLibMensajesVcl,
  inLibMsgCompras,
  inMtoComprasSesionesPresentacionPlanificador;

constructor TCoordinadorCopiaLineasSesion.Create(
  const AEntorno: TEntornoCopiaLineasSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Cabecera) then
    raise EArgumentNilException.Create('AEntorno.Cabecera');
  if not Assigned(AEntorno.Lineas) then
    raise EArgumentNilException.Create('AEntorno.Lineas');
  FEntorno := AEntorno;
  FGestor := TGestorCopiaLineasCompra.Create(
    FEntorno.Cabecera,
    FEntorno.Lineas,
    ObtenerSiguienteLinea);
  FPlanificadorDistribucion := TPlanificadorDiferidoTimer.Create(1,
    procedure
    begin
      PreguntarDistribucion(FLineaOrigenDistribucion);
    end);
  FPlanificadorRecarga := TPlanificadorDiferidoTimer.Create(1,
    procedure
    var
      Gestor: TGestorGridTallas;
    begin
      Gestor := GestorTallas;
      if Assigned(Gestor) then
        Gestor.CargarCantidadesTodasLineas;
    end);
end;

destructor TCoordinadorCopiaLineasSesion.Destroy;
begin
  FPlanificadorDistribucion := nil;
  FPlanificadorRecarga := nil;
  FreeAndNil(FGestor);
  inherited Destroy;
end;

function TCoordinadorCopiaLineasSesion.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if Assigned(FEntorno.ObtenerGestorTallas) then
    Result := FEntorno.ObtenerGestorTallas();
end;

function TCoordinadorCopiaLineasSesion.EsFormatoDistribuido: Boolean;
begin
  Result := (not FEntorno.Cabecera.IsEmpty) and
            (FEntorno.Cabecera.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

function TCoordinadorCopiaLineasSesion.ObtenerSiguienteLinea(
  ALineaOrigen: Integer): Integer;
begin
  Result := 0;
  if not FEntorno.Cabecera.IsEmpty then
    Result := FEntorno.Servicio.ObtenerSiguienteLinea(
      FEntorno.Cabecera.FieldByName('SERIE_SES').AsString,
      FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString,
      ALineaOrigen);
end;

// Las cantidades por talla viven en los Values[] no-bound del grid: hay
// que leerlas ANTES de insertar la copia, porque el insert repinta la
// fila y las borra.
function TCoordinadorCopiaLineasSesion.LeerCantidadesLineaActiva:
  TArray<Double>;
var
  iColumna: Integer;
  iFila: Integer;
  vValor: Variant;
begin
  iFila := FEntorno.Vista.Controller.FocusedRecordIndex;
  SetLength(Result, Length(FEntorno.ColumnasTallas));
  for iColumna := 0 to High(FEntorno.ColumnasTallas) do
  begin
    Result[iColumna] := 0;
    if Assigned(FEntorno.ColumnasTallas[iColumna]) and (iFila >= 0) then
    begin
      vValor := FEntorno.Vista.DataController.Values[
        iFila, FEntorno.ColumnasTallas[iColumna].Index];
      if (not VarIsNull(vValor)) and
         (not VarIsEmpty(vValor)) and
         VarIsNumeric(vValor) then
        Result[iColumna] := vValor;
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.CopiarCeldasDistribuidas(
  ALineaOrigen, ALineaDestino: Integer);
begin
  FEntorno.Servicio.CopiarCeldasDistribuidas(
    FEntorno.Cabecera.FieldByName('SERIE_SES').AsString,
    FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString,
    FEntorno.Cabecera.FieldByName('CODIGO_ALM_SES').AsString,
    FEntorno.Usuario,
    ALineaOrigen,
    ALineaDestino);
end;

procedure TCoordinadorCopiaLineasSesion.ReponerCantidadesDuplicado(
  const AResultado: TResultadoCopiaLineaCompra;
  const ACantidades: TArray<Double>);
var
  Posiciones: TArrPosConjunto;
  iPosicion: Integer;
begin
  if EsFormatoDistribuido then
  begin
    CopiarCeldasDistribuidas(
      AResultado.LineaOrigen,
      AResultado.LineaDestino);
    FEntorno.Lineas.Refresh;
    FEntorno.Lineas.Locate(
      'LINEA_SESLIN', AResultado.LineaDestino, []);
  end
  else if AResultado.IdConjuntoPivot > 0 then
  begin
    Posiciones := GestorTallas.GetPosicionesConjunto(
      AResultado.IdConjuntoPivot);
    for iPosicion := 0 to High(Posiciones) do
    begin
      if (iPosicion <= High(ACantidades)) and
         (ACantidades[iPosicion] > 0) then
        GestorTallas.PersistirCantidad(
          AResultado.LineaDestino,
          Posiciones[iPosicion].IdAv,
          ACantidades[iPosicion]);
    end;
  end
  else if (Length(ACantidades) > 0) and (ACantidades[0] > 0) then
    GestorTallas.PersistirCantidad(
      AResultado.LineaDestino, 0, ACantidades[0]);
end;

procedure TCoordinadorCopiaLineasSesion.ColocarFocoEnCopia(
  ALineaDestino: Integer);
begin
  ColocarFoco(ALineaDestino, FEntorno.ColumnaColor);
end;

procedure TCoordinadorCopiaLineasSesion.ColocarFoco(ALineaDestino: Integer;
  AColumna: TcxGridDBColumn);
begin
  if FEntorno.Lineas.Locate('LINEA_SESLIN', ALineaDestino, []) then
    FEntorno.Vista.Controller.FocusedRecordIndex :=
      FEntorno.Lineas.RecNo - 1;
  if AColumna <> nil then
    FEntorno.Vista.Controller.FocusedColumn := AColumna;
  if Assigned(FEntorno.Vista.Controller.EditingController) then
    FEntorno.Vista.Controller.EditingController.ShowEdit;
  RecargarTallasDiferido;
end;

// El repintado del grid puede llegar despues de cargar las cantidades y
// volver a borrar los Values[] no-bound: la recarga diferida tiene la
// ultima palabra.
procedure TCoordinadorCopiaLineasSesion.RecargarTallasDiferido;
begin
  FPlanificadorRecarga.Rearmar;
end;

// Las celdas de la copia ya existen: los precios por talla se casan con
// ellas. Antes de reordenar, mientras la copia conserva su número.
procedure TCoordinadorCopiaLineasSesion.CopiarPreciosTalla(
  const AResultado: TResultadoCopiaLineaCompra);
begin
  if Assigned(FEntorno.CopiarPreciosTalla) then
    FEntorno.CopiarPreciosTalla(
      AResultado.LineaOrigen,
      AResultado.LineaDestino);
end;

// Copia la línea activa (cantidades, precios por talla y totales) y
// reordena; el foco lo coloca quien llama.
function TCoordinadorCopiaLineasSesion.DuplicarConModo(
  AModo: TModoCopiaLineaCompra;
  const APestana: string): TResultadoCopiaLineaCompra;
var
  Cantidades: TArray<Double>;
  Gestor: TGestorGridTallas;
begin
  Result := Default(TResultadoCopiaLineaCompra);
  Gestor := GestorTallas;
  if Assigned(Gestor) and
     (not FEntorno.Lineas.IsEmpty) and
     (not FEntorno.Cabecera.IsEmpty) then
  begin
    Cantidades := LeerCantidadesLineaActiva;
    Result := FGestor.DuplicarLineaActual(AModo, APestana);
    if Result.Aplicada then
    begin
      ReponerCantidadesDuplicado(Result, Cantidades);
      Gestor.RefrescarTotalesLineaActual;
      CopiarPreciosTalla(Result);
      if Assigned(FEntorno.RefrescarTotalesSesion) then
        FEntorno.RefrescarTotalesSesion();
      Gestor.RecalcularMaxColumnas;
      Gestor.CargarCantidadesTodasLineas;
      Result.LineaDestino := ReordenarTrasCopia(Result.LineaDestino);
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.DuplicarLineaActiva;
var
  Resultado: TResultadoCopiaLineaCompra;
begin
  Resultado := DuplicarConModo(mclOtroColor, '');
  if Resultado.Aplicada then
    ColocarFocoEnCopia(Resultado.LineaDestino);
end;

procedure TCoordinadorCopiaLineasSesion.DuplicarLineaOtroLote;
var
  rCopia: TResultadoCopiaLineaCompra;
  sPestana: string;
  sTrazable: string;
begin
  if FEntorno.Lineas.Active and not FEntorno.Lineas.IsEmpty then
  begin
    sPestana := FEntorno.Lineas.FieldByName(
      'PESTANA_TEXTO_SESLIN').AsString;
    sTrazable := FEntorno.Lineas.FieldByName(
      'ESTRAZABLE_SESLIN').AsString;
    rCopia := DuplicarConModo(mclOtroValorPestana, sPestana);
    if rCopia.Aplicada then
    begin
      FEntorno.Lineas.Edit;
      FEntorno.Lineas.FieldByName('ESTRAZABLE_SESLIN').AsString :=
        sTrazable;
      FEntorno.Lineas.Post;
      ColocarFoco(rCopia.LineaDestino, FEntorno.ColumnaColor);
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.DuplicarLineaOtraPestana;
var
  Resultado: TResultadoCopiaLineaCompra;
begin
  Resultado := DuplicarConModo(mclOtroValorPestana, '');
  if Resultado.Aplicada then
  begin
    ColocarFoco(Resultado.LineaDestino, FEntorno.ColumnaPestana);
    if Assigned(FEntorno.Vista.Controller.EditingController) then
      FEntorno.Vista.Controller.EditingController.ShowEdit;
    RecargarTallasDiferido;
  end;
end;

function TCoordinadorCopiaLineasSesion.EsMismoModeloYColor(
  const AReferencia, AColor: string): Boolean;
begin
  Result := SameText(Trim(FEntorno.Lineas.FieldByName(
      'REF_PRV_SESLIN').AsString), AReferencia) and
    SameText(Trim(FEntorno.Lineas.FieldByName(
      'COLOR_TEXTO_SESLIN').AsString), AColor);
end;

// Copas que ya tienen en la sesión las líneas del mismo modelo y color
// que la activa (incluida ella). Deja la activa enfocada.
function TCoordinadorCopiaLineasSesion.PestanasDelModeloYColor:
  TArray<string>;
var
  oMarca: TBookmark;
  sReferencia: string;
  sColor: string;
begin
  Result := nil;
  sReferencia := Trim(FEntorno.Lineas.FieldByName(
    'REF_PRV_SESLIN').AsString);
  sColor := Trim(FEntorno.Lineas.FieldByName('COLOR_TEXTO_SESLIN').AsString);
  oMarca := FEntorno.Lineas.GetBookmark;
  FEntorno.Lineas.DisableControls;
  try
    FEntorno.Lineas.First;
    while not FEntorno.Lineas.Eof do
    begin
      if EsMismoModeloYColor(sReferencia, sColor) then
        Result := Result + [FEntorno.Lineas.FieldByName(
          CAMPO_PESTANA_LINEA_SESION).AsString];
      FEntorno.Lineas.Next;
    end;
  finally
    FEntorno.Lineas.GotoBookmark(oMarca);
    FEntorno.Lineas.FreeBookmark(oMarca);
    FEntorno.Lineas.EnableControls;
  end;
end;

function TCoordinadorCopiaLineasSesion.DuplicarLineaTodasPestanas(
  const ATodos: TArray<string>): Integer;
var
  aFaltan: TArray<string>;
  sValor: string;
  iUltima: Integer;
  Resultado: TResultadoCopiaLineaCompra;
begin
  Result := 0;
  if FEntorno.Lineas.Active and (not FEntorno.Lineas.IsEmpty) then
  begin
    if FEntorno.Lineas.State in [dsEdit, dsInsert] then
      FEntorno.Lineas.Post;
    iUltima := FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    aFaltan := ValoresPestanaQueFaltan(ATodos, PestanasDelModeloYColor);
    if (Length(aFaltan) > 0) and (Trim(FEntorno.Lineas.FieldByName(
         CAMPO_PESTANA_LINEA_SESION).AsString) = '') then
    begin
      FEntorno.Lineas.Edit;
      FEntorno.Lineas.FieldByName(CAMPO_PESTANA_LINEA_SESION).AsString :=
        aFaltan[0];
      FEntorno.Lineas.Post;
      Delete(aFaltan, 0, 1);
    end;
    // Cada copia sale de la anterior (mismas cantidades y precios): el
    // número que devuelve la reordenación es fiable; el de la línea de
    // origen puede cambiar al renumerar.
    for sValor in aFaltan do
      if FEntorno.Lineas.Locate('LINEA_SESLIN', iUltima, []) then
      begin
        Resultado := DuplicarConModo(mclOtroValorPestana, sValor);
        if Resultado.Aplicada then
        begin
          Inc(Result);
          iUltima := Resultado.LineaDestino;
        end;
      end;
    ColocarFoco(iUltima, FEntorno.ColumnaPestana);
    RecargarTallasDiferido;
  end;
end;

function TCoordinadorCopiaLineasSesion.ReordenarTrasCopia(
  ALineaDestino: Integer): Integer;
begin
  Result := ALineaDestino;
  if Assigned(FEntorno.ReordenarLineas) then
    Result := FEntorno.ReordenarLineas(ALineaDestino);
end;

function TCoordinadorCopiaLineasSesion.LineaTieneCantidades(
  ALinea: Integer): Boolean;
var
  Cantidad: TCantidadPivotSesion;
begin
  Result := False;
  for Cantidad in FEntorno.Servicio.ConsultarCantidadesLinea(
    FEntorno.Cabecera.FieldByName('SERIE_SES').AsString,
    FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString,
    ALinea) do
    Result := Result or (Cantidad.Cantidad > 0);
end;

procedure TCoordinadorCopiaLineasSesion.CopiarCantidadesEntreLineas(
  ALineaOrigen, ALineaDestino: Integer);
var
  sSerie: string;
  sNumero: string;
  Cantidad: TCantidadPivotSesion;
  Gestor: TGestorGridTallas;
begin
  sSerie := FEntorno.Cabecera.FieldByName('SERIE_SES').AsString;
  sNumero := FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString;
  Gestor := GestorTallas;
  if EsFormatoDistribuido then
    CopiarCeldasDistribuidas(ALineaOrigen, ALineaDestino)
  else if Assigned(Gestor) then
  begin
    FEntorno.Servicio.BorrarCeldasLinea(sSerie, sNumero, ALineaDestino);
    for Cantidad in FEntorno.Servicio.ConsultarCantidadesLinea(
      sSerie, sNumero, ALineaOrigen) do
      if (Cantidad.Cantidad > 0) and Assigned(Gestor) then
        Gestor.PersistirCantidad(
          ALineaDestino,
          Cantidad.IdValorPivot,
          Cantidad.Cantidad);
  end;
end;

procedure TCoordinadorCopiaLineasSesion.OfrecerDistribucion(
  ALineaOrigen: Integer);
begin
  FPlanificadorDistribucion.Cancelar;
  if FEntorno.Cabecera.Active and FEntorno.Lineas.Active and
     (not FEntorno.Cabecera.IsEmpty) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    FLineaOrigenDistribucion := ALineaOrigen;
    FLineaDestinoDistribucion :=
      FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    FSerieDistribucion :=
      FEntorno.Cabecera.FieldByName('SERIE_SES').AsString;
    FNumeroDistribucion :=
      FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString;
    FPlanificadorDistribucion.Rearmar;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.PreguntarDistribucion(
  ALineaOrigen: Integer);
var
  Resultado: TResultadoCopiaLineaCompra;
  Gestor: TGestorGridTallas;
begin
  Gestor := GestorTallas;
  if FEntorno.Lineas.Active and FEntorno.Cabecera.Active and
     (not FEntorno.Lineas.IsEmpty) and
     (not FEntorno.Cabecera.IsEmpty) and
     (FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger =
       FLineaDestinoDistribucion) and
     (FEntorno.Cabecera.FieldByName('SERIE_SES').AsString =
       FSerieDistribucion) and
     (FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString =
       FNumeroDistribucion) and
     (EsFormatoDistribuido or Assigned(Gestor)) then
  begin
    // La linea tiene que estar grabada para colgarle sus celdas.
    if FEntorno.Lineas.State in [dsEdit, dsInsert] then
      FEntorno.Lineas.Post;
    Resultado := Default(TResultadoCopiaLineaCompra);
    Resultado.LineaOrigen := ALineaOrigen;
    Resultado.LineaDestino :=
      FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    if (Resultado.LineaDestino > 0) and
       (Resultado.LineaDestino <> ALineaOrigen) and
       LineaTieneCantidades(ALineaOrigen) and
       (MessageDlg_fza(Format(SPreguntaDistribucionModeloRepetido,
          [ALineaOrigen]), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    begin
      CopiarCantidadesEntreLineas(ALineaOrigen, Resultado.LineaDestino);
      FEntorno.Lineas.Refresh;
      FEntorno.Lineas.Locate('LINEA_SESLIN', Resultado.LineaDestino, []);
      Gestor := GestorTallas;
      if Assigned(Gestor) then
      begin
        Gestor.RecalcularMaxColumnas;
        Gestor.CargarCantidadesTodasLineas;
        Gestor.RefrescarTotalesLineaActual;
      end;
      CopiarPreciosTalla(Resultado);
      if Assigned(FEntorno.RefrescarTotalesSesion) then
        FEntorno.RefrescarTotalesSesion();
      RecargarTallasDiferido;
    end;
  end;
end;

end.

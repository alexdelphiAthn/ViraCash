{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosConjuntos                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de conjuntos de atributos.                                    }
{    Mantiene fza_atributos_conjuntos y su detalle de valores asociados a      }
{    artículos.                                                                }
{******************************************************************************}
unit UniDataAtributosConjuntos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  // Lo tecleado en la rejilla se resuelve al grabar la fila, sin preguntar
  // nada: si el atributo ya tiene ese valor se reutiliza su ID (el mismo
  // que llevan los SKU, FZ-ISSUE-139); si no, se da de alta. El orden y el
  // atributo básico de la colección son suyos (ORDEN_ACD, ID_ATB_ACD).
  TdmAtributosConjuntos = class(TdmBase)
    unqryConjuntoDetalle: TUniQuery;
    dsConjuntoDetalle: TDataSource;
    unqryArticulosConjunto: TUniQuery;
    dsArticulosConjunto: TDataSource;
    unqryAtributosLookup: TUniQuery;
    dsAtributosLookup: TDataSource;
    unqryAtributosBasicosLookup: TUniQuery;
    dsAtributosBasicosLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleAfterPost(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforeDelete(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforeInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
    procedure unqryConjuntoDetallePostError(DataSet: TDataSet;
      E: EDatabaseError; var Action: TDataAction);
    procedure unqryTablaGConjuntosAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGConjuntosBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGConjuntosBeforePost(DataSet: TDataSet);
  private
    FTransaccionDetalle: Boolean;
    function ConexionDetalle: TUniConnection;
    function CrearValorColeccion(const AIdAtributo, ATexto: string;
      AOrden: Integer): Integer;
    function DetallesPertenecenAtributo(AIdConjunto: Integer;
      const AIdAtributo: string): Boolean;
    function ExisteUso(const ASql: string; AId: Integer): Boolean;
    procedure IniciarTransaccionDetalle;
    procedure LiberarTipoVariacionColeccion(DataSet: TDataSet);
    function ObtenerValorColeccion(const AIdAtributo, ATexto: string;
      AOrden: Integer): Integer;
    function SiguienteOrdenColeccion(AIdConjunto: Integer): Integer;
    procedure TerminarTransaccionDetalle(AConfirmar: Boolean);
    function TextoRepetidoEnConjunto(AIdConjunto, AIdValorActual: Integer;
      const ATexto: string): Boolean;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    // Lanza EValidacionBBDD si hay SKU que usan el valor de la fila
    // actual del detalle: el formulario lo comprueba antes de preguntar.
    procedure ComprobarValorSinUso;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  System.Diagnostics, System.Variants,
  UniDataAperturaConsultas, inLibCodigosSinBarra, inLibErroresBBDD,
  inLibMsgArticulos, UniDataAtributosSkuEnlace;

resourcestring
  SErrorGrabarColeccionAntesValores =
    'Graba primero los datos de la colección antes de modificar sus valores.';
  SErrorValorRepetidoColeccion =
    'Ese valor ya está incluido en la colección.';
  SErrorColeccionValoresOtroAtributo =
    'La colección contiene valores de otro atributo. ' +
    'Elimina primero sus valores antes de cambiar el atributo.';
  SErrorAtributoColeccionObligatorio =
    'Indica el atributo de la colección antes de añadir valores.';
  SErrorColeccionEnUso =
    'La colección está en uso: tiene artículos asignados o SKU con ' +
    'sus valores. No se puede borrar; desactívala en su lugar.';
  SErrorValorColeccionEnUso =
    'Hay SKU que usan este valor. No se puede quitar de la colección.';

const
  // Si el maestro ya tiene el texto repetido (BLANCO 101 y 9201), manda el
  // activo, luego el que llevan SKU y por último el más antiguo.
  SQL_BUSCAR_VALOR_ATRIBUTO =
    'SELECT v.ID_AV, v.ESACTIVO_AV ' +
    '  FROM fza_atributos_valores v ' +
    ' WHERE v.ID_VA_AV = :IDVA ' +
    '   AND TRIM(UPPER(v.AV)) = UPPER(TRIM(:VALOR)) ' +
    ' ORDER BY (v.ESACTIVO_AV = ''S'') DESC, ' +
    '          EXISTS (SELECT 1 FROM fza_atributos_sku s ' +
    '                   WHERE s.ID_AV_SA = v.ID_AV) DESC, ' +
    '          v.ID_AV ' +
    ' LIMIT 1';
  SQL_REACTIVAR_VALOR =
    'UPDATE fza_atributos_valores ' +
    '   SET ESACTIVO_AV = ''S'', INSTANTE_MODIF = NOW(), ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_AV = :ID';
  SQL_SIGUIENTE_ORDEN_CONJUNTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_ACD), 0) / 10) + 1) * 10 ' +
    '       AS SIGUIENTE_ORDEN ' +
    '  FROM fza_atributos_conjuntos_det ' +
    ' WHERE ID_AC_ACD = :IDCONJUNTO';
  SQL_DETALLES_FUERA_ATRIBUTO =
    'SELECT 1 ' +
    '  FROM fza_atributos_conjuntos_det d ' +
    '  JOIN fza_atributos_valores v ON v.ID_AV = d.ID_AV_ACD ' +
    ' WHERE d.ID_AC_ACD = :IDCONJUNTO ' +
    '   AND (:IDVA = '''' OR v.ID_VA_AV <> :IDVA) ' +
    ' LIMIT 1';
  SQL_TEXTO_REPETIDO_CONJUNTO =
    'SELECT 1 ' +
    '  FROM fza_atributos_conjuntos_det d ' +
    '  JOIN fza_atributos_valores v ON v.ID_AV = d.ID_AV_ACD ' +
    ' WHERE d.ID_AC_ACD = :IDCONJUNTO ' +
    '   AND d.ID_AV_ACD <> :IDACTUAL ' +
    '   AND TRIM(UPPER(v.AV)) = UPPER(TRIM(:VALOR)) ' +
    ' LIMIT 1';
  SQL_COLECCION_ASIGNADA =
    'SELECT 1 ' +
    '  FROM fza_articulos_conjuntos_asign ' +
    ' WHERE ID_AC_ACA = :ID ' +
    ' LIMIT 1';
  SQL_COLECCION_CON_SKU =
    'SELECT 1 ' +
    '  FROM fza_atributos_conjuntos_det d ' +
    '  JOIN fza_atributos_sku s ON s.ID_AV_SA = d.ID_AV_ACD ' +
    ' WHERE d.ID_AC_ACD = :ID ' +
    ' LIMIT 1';
  SQL_VALOR_CON_SKU =
    'SELECT 1 ' +
    '  FROM fza_atributos_sku ' +
    ' WHERE ID_AV_SA = :ID ' +
    ' LIMIT 1';

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosConjuntos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection. Los .Open estan en AbrirDetalles y los
  // MasterSource en AsignarMaestroCabecera.
  unqryAtributosLookup.Connection := ConexionPrincipal;
  unqryAtributosBasicosLookup.Connection := ConexionPrincipal;
  unqryConjuntoDetalle.Connection := ConexionPrincipal;
  unqryArticulosConjunto.Connection := ConexionPrincipal;
end;

procedure TdmAtributosConjuntos.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryConjuntoDetalle.MasterSource := ADataSource;
  unqryArticulosConjunto.MasterSource := ADataSource;
end;

// La conexión por la que se graba el detalle (la propia de la ventana):
// las consultas auxiliares y el alta del valor van por ella para quedar
// en la misma transacción que la fila.
function TdmAtributosConjuntos.ConexionDetalle: TUniConnection;
begin
  Result := unqryConjuntoDetalle.Connection;
  if Result = nil then
    Result := ConexionPrincipal;
end;

function TdmAtributosConjuntos.CrearValorColeccion(
  const AIdAtributo, ATexto: string; AOrden: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDetalle;
    Result := AsegurarValorAtributoNormalizado(oConsulta,
      AIdAtributo, ATexto, '', IdentidadSesion.Usuario, AOrden, 0);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// El ID del valor que lleva ya ese texto en el atributo (reactivado si
// estaba de baja) o, si no hay ninguno, uno nuevo.
function TdmAtributosConjuntos.ObtenerValorColeccion(
  const AIdAtributo, ATexto: string; AOrden: Integer): Integer;
var
  bActivo: Boolean;
  oConsulta: TUniQuery;
begin
  Result := 0;
  bActivo := True;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDetalle;
    oConsulta.SQL.Text := SQL_BUSCAR_VALOR_ATRIBUTO;
    oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
    oConsulta.ParamByName('VALOR').AsString := ATexto;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('ID_AV').AsInteger;
      bActivo := oConsulta.FieldByName('ESACTIVO_AV').AsString = 'S';
    end;
    oConsulta.Close;
    if (Result > 0) and not bActivo then
    begin
      oConsulta.SQL.Text := SQL_REACTIVAR_VALOR;
      oConsulta.ParamByName('ID').AsInteger := Result;
      oConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      oConsulta.ExecSQL;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if Result = 0 then
    Result := CrearValorColeccion(AIdAtributo, ATexto, AOrden);
end;

function TdmAtributosConjuntos.DetallesPertenecenAtributo(
  AIdConjunto: Integer; const AIdAtributo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := True;
  if AIdConjunto > 0 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text := SQL_DETALLES_FUERA_ATRIBUTO;
      oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
      oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
      oConsulta.Open;
      Result := oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

// True si la consulta de uso (con un único parámetro :ID) devuelve fila.
function TdmAtributosConjuntos.ExisteUso(const ASql: string;
  AId: Integer): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDetalle;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('ID').AsInteger := AId;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmAtributosConjuntos.TextoRepetidoEnConjunto(
  AIdConjunto, AIdValorActual: Integer; const ATexto: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDetalle;
    oConsulta.SQL.Text := SQL_TEXTO_REPETIDO_CONJUNTO;
    oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
    oConsulta.ParamByName('IDACTUAL').AsInteger := AIdValorActual;
    oConsulta.ParamByName('VALOR').AsString := ATexto;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmAtributosConjuntos.SiguienteOrdenColeccion(
  AIdConjunto: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 10;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDetalle;
    oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_CONJUNTO;
    oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('SIGUIENTE_ORDEN').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmAtributosConjuntos.IniciarTransaccionDetalle;
begin
  // Grabar ya trae su transacción; una fila que se graba al cambiar de
  // fila, no: el valor y la fila se confirman o se deshacen juntos.
  FTransaccionDetalle := not ConexionDetalle.InTransaction;
  if FTransaccionDetalle then
    ConexionDetalle.StartTransaction;
end;

procedure TdmAtributosConjuntos.TerminarTransaccionDetalle(
  AConfirmar: Boolean);
begin
  if FTransaccionDetalle then
  begin
    FTransaccionDetalle := False;
    if AConfirmar then
      ConexionDetalle.Commit
    else
      ConexionDetalle.Rollback;
  end;
end;

procedure TdmAtributosConjuntos.AbrirDetalles;
const
  TAG = 'AtributosConjuntos.AbrirDetalles';
var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConsultaConTiempo(
    unqryAtributosLookup, TAG, 'unqryAtributosLookup', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAtributosBasicosLookup, TAG, 'unqryAtributosBasicosLookup',
    RegistroLog);
  AbrirConsultaConTiempo(
    unqryConjuntoDetalle, TAG, 'unqryConjuntoDetalle', RegistroLog);
  AbrirConsultaConTiempo(
    unqryArticulosConjunto, TAG, 'unqryArticulosConjunto', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforeInsert(
                                                             DataSet: TDataSet);
begin
  inherited;
  // Guarda la cabecera para disponer del ID antes de crear el valor.
  // Si falla su validación, no se inicia el alta del detalle.
  if unqryTablaG.State in [dsEdit, dsInsert] then
    unqryTablaG.Post;
end;

// Quitar de la colección un valor que ya llevan SKU dejaría esos SKU
// fuera de la rejilla de tallas del artículo.
procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforeDelete(
                                                             DataSet: TDataSet);
begin
  inherited;
  ComprobarValorSinUso;
end;

procedure TdmAtributosConjuntos.ComprobarValorSinUso;
begin
  if unqryConjuntoDetalle.Active and
     (unqryConjuntoDetalle.State <> dsInsert) and
     (not unqryConjuntoDetalle.IsEmpty) and
     ExisteUso(SQL_VALOR_CON_SKU,
       unqryConjuntoDetalle.FieldByName('ID_AV_ACD').AsInteger) then
    raise EValidacionBBDD.Create(SErrorValorColeccionEnUso);
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleAfterInsert(
                                                             DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_AC_ACD').AsInteger :=
                                     unqryTablaG.FieldByName('ID_AC').AsInteger;
  // Orden propuesto: 10, 20, 30... (visible ya al insertar).
  DataSet.FieldByName('ORDEN_ACD').AsInteger :=
    SiguienteOrdenColeccion(DataSet.FieldByName('ID_AC_ACD').AsInteger);
end;

// La fila solo trae el texto. Una fila nueva, o una cuyo texto cambia,
// toma el valor del atributo con ese texto o uno nuevo; el valor anterior
// no se toca porque pueden usarlo SKU o documentos ya grabados.
procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforePost(
                                                             DataSet: TDataSet);
var
  bTextoCambiado: Boolean;
  iIdActual: Integer;
  iIdConjunto: Integer;
  sIdAtributo: string;
  sTexto: string;
begin
  inherited;
  if unqryTablaG.State in [dsEdit, dsInsert] then
    raise EValidacionBBDD.Create(SErrorGrabarColeccionAntesValores);
  sIdAtributo := Trim(unqryTablaG.FieldByName('ID_VA_AC').AsString);
  if sIdAtributo = '' then
    raise EValidacionBBDD.Create(SErrorAtributoColeccionObligatorio);
  // Sin barras, como todos los valores de atributo: van dentro del SKU.
  sTexto := SinBarraSku(DataSet.FieldByName('AV').AsString);
  if sTexto = '' then
  begin
    // Deja el cursor en la celda Valor de la fila que se está grabando.
    DataSet.FieldByName('AV').FocusControl;
    raise EValidacionBBDD.Create(SErrorValorColeccionAtributosObligatorio);
  end;
  DataSet.FieldByName('AV').AsString := sTexto;
  iIdActual := 0;
  if DataSet.State = dsEdit then
    iIdActual := StrToIntDef(
      VarToStr(DataSet.FieldByName('ID_AV_ACD').OldValue), 0);
  bTextoCambiado := (DataSet.State = dsInsert) or
    (VarToStr(DataSet.FieldByName('AV').OldValue) <> sTexto);
  iIdConjunto := unqryTablaG.FieldByName('ID_AC').AsInteger;
  if bTextoCambiado and
     TextoRepetidoEnConjunto(iIdConjunto, iIdActual, sTexto) then
    raise EValidacionBBDD.Create(SErrorValorRepetidoColeccion);
  DataSet.FieldByName('ID_AC_ACD').AsInteger := iIdConjunto;
  if DataSet.FieldByName('ORDEN_ACD').AsInteger = 0 then
    DataSet.FieldByName('ORDEN_ACD').AsInteger :=
      SiguienteOrdenColeccion(iIdConjunto);
  ActualizarAuditoria(DataSet);
  if bTextoCambiado then
  begin
    IniciarTransaccionDetalle;
    try
      DataSet.FieldByName('ID_AV_ACD').AsInteger := ObtenerValorColeccion(
        sIdAtributo, sTexto, DataSet.FieldByName('ORDEN_ACD').AsInteger);
    except
      TerminarTransaccionDetalle(False);
      raise;
    end;
  end;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleAfterPost(
                                                             DataSet: TDataSet);
begin
  inherited;
  TerminarTransaccionDetalle(True);
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetallePostError(
  DataSet: TDataSet; E: EDatabaseError; var Action: TDataAction);
begin
  inherited;
  // El error sigue su curso; solo se deshace el valor recién creado.
  TerminarTransaccionDetalle(False);
end;

// Colección nueva: activa y, si existe, con el atributo Talla. La
// colección depende solo de su atributo (FZ-ISSUE-449): ID_VAR_AC sigue en
// la tabla, sin uso, y las altas lo graban vacío.
procedure TdmAtributosConjuntos.unqryTablaGConjuntosAfterInsert(
  DataSet: TDataSet);
begin
  DataSet.FieldByName('ESACTIVO_AC').AsString := 'S';
  LiberarTipoVariacionColeccion(DataSet);
  if unqryAtributosLookup.Active and
     unqryAtributosLookup.Locate('ID_ATB_VA', 'TAL', []) then
    DataSet.FieldByName('ID_VA_AC').AsString := 'TAL';
end;

// La columna es NOT NULL en la tabla; el campo no debe exigirse ni
// viajar en el DML de la cabecera.
procedure TdmAtributosConjuntos.LiberarTipoVariacionColeccion(
  DataSet: TDataSet);
var
  oCampo: TField;
begin
  oCampo := DataSet.FindField('ID_VAR_AC');
  if oCampo <> nil then
  begin
    oCampo.Required := False;
    oCampo.ProviderFlags := [];
  end;
end;

// El guardián de borrado solo llega aquí si se elige borrar en vez de
// desactivar: una colección en uso no se borra, se desactiva.
procedure TdmAtributosConjuntos.unqryTablaGConjuntosBeforeDelete(
  DataSet: TDataSet);
var
  iIdConjunto: Integer;
begin
  inherited;
  iIdConjunto := DataSet.FieldByName('ID_AC').AsInteger;
  if ExisteUso(SQL_COLECCION_ASIGNADA, iIdConjunto) or
     ExisteUso(SQL_COLECCION_CON_SKU, iIdConjunto) then
    raise EValidacionBBDD.Create(SErrorColeccionEnUso);
end;

procedure TdmAtributosConjuntos.unqryTablaGConjuntosBeforePost(
  DataSet: TDataSet);
var
  bAtributoModificado: Boolean;
  iIdConjunto: Integer;
  sIdAtributo: string;
begin
  iIdConjunto := 0;
  if not DataSet.FieldByName('ID_AC').IsNull then
    iIdConjunto := DataSet.FieldByName('ID_AC').AsInteger;
  sIdAtributo := DataSet.FieldByName('ID_VA_AC').AsString;
  bAtributoModificado := DataSet.State = dsEdit;
  if bAtributoModificado then
    bAtributoModificado := not SameText(
      VarToStr(DataSet.FieldByName('ID_VA_AC').OldValue),
      sIdAtributo);
  if bAtributoModificado and
     (not DetallesPertenecenAtributo(
            iIdConjunto, sIdAtributo)) then
    raise EValidacionBBDD.Create(SErrorColeccionValoresOtroAtributo);
  LiberarTipoVariacionColeccion(DataSet);
  inherited unqryTablaGBeforePost(DataSet);
end;

initialization
  RegistrarDataModule(TdmAtributosConjuntos);
  ForceReferenceToClass(TdmAtributosConjuntos);
end.

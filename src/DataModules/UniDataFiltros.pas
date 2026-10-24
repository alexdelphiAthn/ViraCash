{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFiltros                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module transversal de filtros guardados de mantenimientos           }
{    (derivados de inMtoGen). Guarda el filtro de DataController.Filter con   }
{    nombre propio y permite compartirlo con usuarios o grupos, de forma      }
{    independiente al layout de columnas. Instancia unica: dmFiltros,         }
{    creada en TfrmMtoPrincipal junto a dmPerfiles/dmConn.                    }
{******************************************************************************}
unit UniDataFiltros;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni, inLibConexionesIntf,
  inLibContextoSesionIntf, inLibFiltrosGuardadosIntf;

type
  TdmFiltros = class(
    TDataModule,
    IProveedorConexiones,
    IProveedorContextoSesion,
    ILectorFiltrosGuardados,
    IEscritorFiltrosGuardados,
    ICompartidorFiltrosGuardados
  )
    procedure DataModuleCreate(Sender: TObject);
  private
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    function GetConexiones: IServicioConexiones;
    function GetConexionPrincipal: TUniConnection;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
  public
    constructor Create(AOwner: TComponent); override;
    function ListarFiltros(const AMto,
                           AVista: string): TFiltrosGuardadosList;
    function BuscarFiltroPropio(const AMto,
                                AVista,
                                ANombre: string): Int64;
    function GuardarFiltroNuevo(const AMto,
                                AVista,
                                ANombre,
                                ADescripcion,
                                AFiltroBase64: string): Int64;
    procedure SobrescribirFiltro(AIdFiltro: Int64;
                                 const ANombre,
                                 ADescripcion,
                                 AFiltroBase64: string);
    procedure RenombrarFiltro(AIdFiltro: Int64;
                              const ANombre, ADescripcion: string);
    procedure BorrarFiltro(AIdFiltro: Int64);
    function EsPropietario(AIdFiltro: Int64): Boolean;
    function CargarFiltroBase64(AIdFiltro: Int64): string;
    function ListarDestinosCompartidos(
                             AIdFiltro: Int64): TDestinosCompartidosList;
    procedure CompartirConDestino(AIdFiltro: Int64;
                                  const ATipoDestino, ADestino: string);
    procedure QuitarDestinoCompartido(AIdDestino: Int64);
    property Conexiones: IServicioConexiones read GetConexiones;
    property ConexionPrincipal: TUniConnection
      read GetConexionPrincipal;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
    property IdentidadSesion: TIdentidadSesion
      read GetIdentidadSesion;
  end;

implementation

uses
  Vcl.Forms, inLibMsgComun;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

// SQL comun de visibilidad: propios + compartidos conmigo (usuario, mi
// grupo o 'Todos'). El propietario siempre ve su filtro aunque no lo haya
// compartido con nadie.
const
  cSqlVisibilidad =
    ' AND ( F.USUARIO_PROPIETARIO_FILT = :USUARIO ' +
    '    OR EXISTS ( ' +
    '         SELECT 1 ' +
    '           FROM fza_filtros_guardados_compartidos C ' +
    '          WHERE C.ID_FILT_FILTC = F.ID_FILT ' +
    '            AND ( (    C.TIPO_DESTINO_FILTC = ''USUARIO'' ' +
    '                   AND C.USUARIO_GRUPO_FILTC = :USUARIO) ' +
    '               OR (    C.TIPO_DESTINO_FILTC = ''GRUPO'' ' +
    '                   AND C.USUARIO_GRUPO_FILTC = :GRUPO) ' +
    '               OR      C.TIPO_DESTINO_FILTC = ''TODOS'')) ) ';

constructor TdmFiltros.Create(AOwner: TComponent);
begin
  HeredarConexiones(AOwner);
  HeredarContextoSesion(AOwner);
  inherited Create(AOwner);
end;

procedure TdmFiltros.HeredarConexiones(AOwner: TComponent);
var
  Proveedor: IProveedorConexiones;
begin
  FConexiones := nil;
  if Supports(AOwner, IProveedorConexiones, Proveedor) then
    FConexiones := Proveedor.Conexiones;
  if not Assigned(FConexiones) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorConexiones,
       Proveedor) then
    FConexiones := Proveedor.Conexiones;
end;

procedure TdmFiltros.HeredarContextoSesion(AOwner: TComponent);
var
  Proveedor: IProveedorContextoSesion;
begin
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
  if not Assigned(FContextoSesion) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorContextoSesion,
       Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
end;

function TdmFiltros.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

function TdmFiltros.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
  if not Assigned(Result) and
     not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
end;

function TdmFiltros.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TdmFiltros.GetIdentidadSesion: TIdentidadSesion;
begin
  Result := TIdentidadSesion.Crear('', '', '');
  if Assigned(FContextoSesion) then
    Result := FContextoSesion.Identidad
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorContextoSesionFiltrosNoConfigurado);
end;

procedure TdmFiltros.DataModuleCreate(Sender: TObject);
begin
  inherited;
end;

function TdmFiltros.ListarFiltros(const AMto,
                                  AVista: string): TFiltrosGuardadosList;
var
  qry: TUniQuery;
  info: TFiltroGuardadoInfo;
  IdentidadActual: TIdentidadSesion;
begin
  IdentidadActual := IdentidadSesion;
  Result := TFiltrosGuardadosList.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      '  SELECT F.ID_FILT, ' +
      '         F.NOMBRE_FILT, ' +
      '         F.DESCRIPCION_FILT, ' +
      '         F.USUARIO_PROPIETARIO_FILT ' +
      '    FROM fza_filtros_guardados F ' +
      '   WHERE F.MTO_FILT = :MTO ' +
      '     AND F.VISTA_FILT = :VISTA ' +
      cSqlVisibilidad +
      'ORDER BY F.USUARIO_PROPIETARIO_FILT <> :USUARIO, F.NOMBRE_FILT';
    qry.ParamByName('MTO').AsString := AMto;
    qry.ParamByName('VISTA').AsString := AVista;
    qry.ParamByName('USUARIO').AsString := IdentidadActual.Usuario;
    qry.ParamByName('GRUPO').AsString := IdentidadActual.Grupo;
    qry.Open;
    while not qry.Eof do
    begin
      info.Id := qry.FieldByName('ID_FILT').AsLargeInt;
      info.Nombre := qry.FieldByName('NOMBRE_FILT').AsString;
      info.Descripcion := qry.FieldByName('DESCRIPCION_FILT').AsString;
      info.Propietario :=
        qry.FieldByName('USUARIO_PROPIETARIO_FILT').AsString;
      info.EsPropio := SameText(
        info.Propietario,
        IdentidadActual.Usuario);
      Result.Add(info);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.BuscarFiltroPropio(const AMto,
                                       AVista,
                                       ANombre: string): Int64;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT ID_FILT ' +
      '  FROM fza_filtros_guardados ' +
      ' WHERE MTO_FILT = :MTO ' +
      '   AND VISTA_FILT = :VISTA ' +
      '   AND NOMBRE_FILT = :NOMBRE ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('MTO').AsString := AMto;
    qry.ParamByName('VISTA').AsString := AVista;
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('ID_FILT').AsLargeInt;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.GuardarFiltroNuevo(const AMto,
                                       AVista,
                                       ANombre,
                                       ADescripcion,
                                       AFiltroBase64: string): Int64;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'INSERT INTO fza_filtros_guardados ' +
      '  (MTO_FILT, VISTA_FILT, NOMBRE_FILT, DESCRIPCION_FILT, ' +
      '   FILTRO_FILT, USUARIO_PROPIETARIO_FILT, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:MTO, :VISTA, :NOMBRE, :DESCRIPCION, :FILTRO, :USUARIO, ' +
      '   CURRENT_TIMESTAMP, :USUARIO, :USUARIO)';
    qry.ParamByName('MTO').AsString := AMto;
    qry.ParamByName('VISTA').AsString := AVista;
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    // ftMemo explicito: el filtro serializado en Base64 puede superar
    // facilmente el tamano por defecto que UniDAC infiere para un
    // parametro de texto no declarado (igual que pVALUE_TEXT en
    // UniDataPerfiles.GrabarPerfil).
    qry.ParamByName('FILTRO').DataType := ftMemo;
    qry.ParamByName('FILTRO').AsString := AFiltroBase64;
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.Execute;
    qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('ID').AsLargeInt;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.SobrescribirFiltro(AIdFiltro: Int64;
                                        const ANombre,
                                        ADescripcion,
                                        AFiltroBase64: string);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_filtros_guardados ' +
      '   SET NOMBRE_FILT = :NOMBRE, ' +
      '       DESCRIPCION_FILT = :DESCRIPCION, ' +
      '       FILTRO_FILT = :FILTRO, ' +
      '       USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_FILT = :ID ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    qry.ParamByName('FILTRO').DataType := ftMemo;
    qry.ParamByName('FILTRO').AsString := AFiltroBase64;
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.RenombrarFiltro(AIdFiltro: Int64;
                                     const ANombre, ADescripcion: string);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_filtros_guardados ' +
      '   SET NOMBRE_FILT = :NOMBRE, ' +
      '       DESCRIPCION_FILT = :DESCRIPCION, ' +
      '       USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_FILT = :ID ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.BorrarFiltro(AIdFiltro: Int64);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // No hay FK fisica (convencion del proyecto): borramos primero los
    // destinos compartidos y despues la cabecera, en una transaccion.
    ConexionPrincipal.StartTransaction;
    try
      qry.SQL.Text :=
        'DELETE FROM fza_filtros_guardados_compartidos ' +
        ' WHERE ID_FILT_FILTC = :ID';
      qry.ParamByName('ID').AsLargeInt := AIdFiltro;
      qry.Execute;
      qry.SQL.Text :=
        'DELETE FROM fza_filtros_guardados ' +
        ' WHERE ID_FILT = :ID ' +
        '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
      qry.ParamByName('ID').AsLargeInt := AIdFiltro;
      qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      qry.Execute;
      ConexionPrincipal.Commit;
    except
      ConexionPrincipal.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.EsPropietario(AIdFiltro: Int64): Boolean;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_filtros_guardados ' +
      ' WHERE ID_FILT = :ID ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.Open;
    Result := not qry.IsEmpty;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.CargarFiltroBase64(AIdFiltro: Int64): string;
var
  qry: TUniQuery;
begin
  Result := '';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT FILTRO_FILT ' +
      '  FROM fza_filtros_guardados ' +
      ' WHERE ID_FILT = :ID';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('FILTRO_FILT').AsString;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.ListarDestinosCompartidos(
                              AIdFiltro: Int64): TDestinosCompartidosList;
var
  qry: TUniQuery;
  info: TDestinoCompartidoInfo;
begin
  Result := TDestinosCompartidosList.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      '  SELECT ID_FILTC, TIPO_DESTINO_FILTC, USUARIO_GRUPO_FILTC ' +
      '    FROM fza_filtros_guardados_compartidos ' +
      '   WHERE ID_FILT_FILTC = :ID ' +
      'ORDER BY TIPO_DESTINO_FILTC, USUARIO_GRUPO_FILTC';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Open;
    while not qry.Eof do
    begin
      info.Id := qry.FieldByName('ID_FILTC').AsLargeInt;
      info.TipoDestino := qry.FieldByName('TIPO_DESTINO_FILTC').AsString;
      info.UsuarioGrupo := qry.FieldByName('USUARIO_GRUPO_FILTC').AsString;
      Result.Add(info);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.CompartirConDestino(AIdFiltro: Int64;
                                        const ATipoDestino,
                                              ADestino: string);
var
  qry: TUniQuery;
  sDestino: string;
begin
  sDestino := ADestino;
  if SameText(ATipoDestino, 'TODOS') then
  begin
    sDestino := '';
  end;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'INSERT INTO fza_filtros_guardados_compartidos ' +
      '  (ID_FILT_FILTC, USUARIO_GRUPO_FILTC, TIPO_DESTINO_FILTC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:ID, :DESTINO, :TIPO, CURRENT_TIMESTAMP, :USUARIO, :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.ParamByName('DESTINO').AsString := sDestino;
    qry.ParamByName('TIPO').AsString := UpperCase(ATipoDestino);
    qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.QuitarDestinoCompartido(AIdDestino: Int64);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'DELETE FROM fza_filtros_guardados_compartidos ' +
      ' WHERE ID_FILTC = :ID';
    qry.ParamByName('ID').AsLargeInt := AIdDestino;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

initialization
  ForceReferenceToClass(TdmFiltros);
end.

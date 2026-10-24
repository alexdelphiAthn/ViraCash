{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPerfiles                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de perfiles de usuario.                                       }
{    Lectura y grabación de fza_perfiles para preferencias de usuario y grupo. }
{******************************************************************************}
unit UniDataPerfiles;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Classes, DB, MemDS, inLibUser,
  DBAccess, Uni, inLibAuditoriaDatosIntf, inLibConexionesIntf,
  inLibContextoSesionIntf, inLibPerfilesUsuarioIntf, inLibLogIntf;

type
  TdmPerfiles = class(
    TDataModule,
    IProveedorAuditoriaDatos,
    IProveedorConexiones,
    IProveedorContextoSesion,
    ILectorPerfilesUsuario,
    IEscritorPerfilesUsuario,
    ICachePerfilesUsuario
  )
    unqryPerfiles: TUniQuery;
    unstdGrabarPerfil: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
  private
    FCachePerfilesForm: TObjectDictionary<string, TProfileDicc>;
    FCachePrecargada: Boolean;
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    function ClonarPerfilDicc(AOrigen: TProfileDicc): TProfileDicc;
    function CargarPerfilFormDesdeDB(const AFormName: string): TProfileDicc;
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    function GetConexiones: IServicioConexiones;
    function GetConexionPrincipal: TUniConnection;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    procedure HeredarAuditoriaDatos(AOwner: TComponent);
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
    procedure HeredarRegistroLog(AOwner: TComponent);
    procedure ActualizarAuditoria(DataSet: TDataSet);
    function ObtenerPerfilFormCache(
      const AFormName: string;
      out APerfilDic: TProfileDicc): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    procedure PrecargarPerfilesUsuario; overload;
    procedure PrecargarPerfilesUsuario(AConn: TUniConnection); overload;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    procedure ResincronizarPerfilFormulario(const AFormulario: string);
    procedure ActualizarPerfilFormulario(const AFormulario: string;
      APerfil: TProfileDicc);
    procedure InvalidarCachePerfiles;
    property CachePrecargada: Boolean read FCachePrecargada;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
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
  Vcl.Forms, System.SysConst, inLibMsgComun, inLibRegistroLogNulo;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TdmPerfiles.Create(AOwner: TComponent);
begin
  HeredarAuditoriaDatos(AOwner);
  HeredarConexiones(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarRegistroLog(AOwner);
  inherited Create(AOwner);
end;

procedure TdmPerfiles.HeredarRegistroLog(AOwner: TComponent);
var
  Proveedor: IProveedorRegistroLog;
begin
  FRegistroLog := nil;
  if Supports(AOwner, IProveedorRegistroLog, Proveedor) then
    FRegistroLog := Proveedor.RegistroLog;
  if not Assigned(FRegistroLog) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorRegistroLog,
       Proveedor) then
    FRegistroLog := Proveedor.RegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TdmPerfiles.HeredarAuditoriaDatos(AOwner: TComponent);
var
  Proveedor: IProveedorAuditoriaDatos;
begin
  FAuditoriaDatos := nil;
  if Supports(AOwner, IProveedorAuditoriaDatos, Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
  if not Assigned(FAuditoriaDatos) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorAuditoriaDatos,
       Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
end;

function TdmPerfiles.GetAuditoriaDatos: IServicioAuditoriaDatos;
begin
  Result := FAuditoriaDatos;
end;

procedure TdmPerfiles.HeredarConexiones(AOwner: TComponent);
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

procedure TdmPerfiles.HeredarContextoSesion(AOwner: TComponent);
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

function TdmPerfiles.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

function TdmPerfiles.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
  if not Assigned(Result) and
     not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
end;

function TdmPerfiles.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TdmPerfiles.GetIdentidadSesion: TIdentidadSesion;
begin
  Result := TIdentidadSesion.Crear('', '', '');
  if Assigned(FContextoSesion) then
    Result := FContextoSesion.Identidad
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorContextoSesionPerfilesNoConfigurado);
end;

procedure TdmPerfiles.ActualizarAuditoria(DataSet: TDataSet);
begin
  if Assigned(FAuditoriaDatos) then
    FAuditoriaDatos.Actualizar(DataSet)
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioAuditoriaDatosNoConfigurado);
end;

procedure TdmPerfiles.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FCachePerfilesForm := TObjectDictionary<string, TProfileDicc>.Create(
    [doOwnsValues]);
  FCachePrecargada := False;
end;

procedure TdmPerfiles.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FCachePerfilesForm);
end;

function TdmPerfiles.ClonarPerfilDicc(AOrigen: TProfileDicc): TProfileDicc;
var
  oPair: TPair<string, TDictValue>;
begin
  Result := TProfileDicc.Create;
  if AOrigen <> nil then
    for oPair in AOrigen do
      Result.AddOrSetValue(oPair.Key, oPair.Value);
end;

function TdmPerfiles.CargarPerfilFormDesdeDB(
                                   const AFormName: string): TProfileDicc;
var
  qry: TUniQuery;
  v: TDictValue;
  IdentidadActual: TIdentidadSesion;
begin
  IdentidadActual := IdentidadSesion;
  Result := TProfileDicc.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // Mismo criterio de resolución que PRC_GETPERFILFORMULARIO: por cada
    // SUBKEY queda la fila con USUARIO_GRUPO de mayor prioridad. Lo conseguimos
    // ordenando ascendente por prioridad (Todos -> Group -> User) e iterando
    // con AddOrSetValue: la última asignación, que es la de mayor prioridad,
    // sobreescribe a las anteriores.
    qry.SQL.Text :=
      'SELECT SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :key ' +
      '   AND USUARIO_GRUPO_USUPER IN (:u, :g, :a) ' +
      ' ORDER BY SUBKEY_USUPER, ' +
      '          CASE USUARIO_GRUPO_USUPER ' +
      '            WHEN :a THEN 1 ' +
      '            WHEN :g THEN 2 ' +
      '            WHEN :u THEN 3 ' +
      '          END';
    qry.ParamByName('key').AsString := AFormName;
    qry.ParamByName('u').AsString   := IdentidadActual.Usuario;
    qry.ParamByName('g').AsString   := IdentidadActual.Grupo;
    qry.ParamByName('a').AsString   := PERFIL_TODOS;
    qry.Open;
    while not qry.Eof do
    begin
      v.sValue     := qry.FieldByName('VALUE_USUPER').AsString;
      v.sValueText := qry.FieldByName('VALUE_TEXT_USUPER').AsWideString;
      Result.AddOrSetValue(qry.FieldByName('SUBKEY_USUPER').AsString, v);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmPerfiles.PrecargarPerfilesUsuario;
begin
  PrecargarPerfilesUsuario(ConexionPrincipal);
end;

procedure TdmPerfiles.PrecargarPerfilesUsuario(AConn: TUniConnection);
var
  qry: TUniQuery;
  sKeyForm, sSubKey: string;
  v: TDictValue;
  PerfilDic: TProfileDicc;
  iFilas, iForms: Integer;
  IdentidadActual: TIdentidadSesion;
begin
  IdentidadActual := IdentidadSesion;
  if AConn = nil then
    AConn := ConexionPrincipal;
  FRegistroLog.RegistrarInformacion(Format('PrecargarPerfilesUsuario: INICIO ' +
                     'usuario="%s" grupo="%s" todos="%s" ' +
                     'connAssigned=%s connConnected=%s',
                     [IdentidadActual.Usuario, IdentidadActual.Grupo,
                      PERFIL_TODOS,
                      BoolToStr(AConn <> nil, True),
                      BoolToStr((AConn <> nil) and AConn.Connected, True)]));
  FCachePerfilesForm.Clear;
  FCachePrecargada := False;
  if (AConn = nil) or (not AConn.Connected) then
  begin
    FRegistroLog.RegistrarAviso(
      'PrecargarPerfilesUsuario: ABORTADA, conexion no disponible. ' +
                   'FCachePrecargada queda False');
  end;
  if (AConn <> nil) and AConn.Connected then
  begin
  iFilas := 0;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConn;
      qry.SQL.Text :=
        'SELECT KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER ' +
        '  FROM fza_usuarios_perfiles ' +
        ' WHERE USUARIO_GRUPO_USUPER IN (:u, :g, :a) ' +
        ' ORDER BY KEY_USUPER, SUBKEY_USUPER, ' +
        '          CASE USUARIO_GRUPO_USUPER ' +
        '            WHEN :a THEN 1 ' +
        '            WHEN :g THEN 2 ' +
        '            WHEN :u THEN 3 ' +
        '          END';
      qry.ParamByName('u').AsString := IdentidadActual.Usuario;
      qry.ParamByName('g').AsString := IdentidadActual.Grupo;
      qry.ParamByName('a').AsString := PERFIL_TODOS;
      qry.Open;
      while not qry.Eof do
      begin
        sKeyForm := qry.FieldByName('KEY_USUPER').AsString;
        sSubKey  := qry.FieldByName('SUBKEY_USUPER').AsString;
        v.sValue     := qry.FieldByName('VALUE_USUPER').AsString;
        v.sValueText := qry.FieldByName('VALUE_TEXT_USUPER').AsWideString;
        if not FCachePerfilesForm.TryGetValue(sKeyForm, PerfilDic) then
        begin
          PerfilDic := TProfileDicc.Create;
          FCachePerfilesForm.Add(sKeyForm, PerfilDic);
        end;
        PerfilDic.AddOrSetValue(sSubKey, v);
        Inc(iFilas);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    FCachePrecargada := True;
    iForms := FCachePerfilesForm.Count;
    FRegistroLog.RegistrarInformacion(Format('PrecargarPerfilesUsuario: OK ' +
                       'filas=%d forms_distintos=%d FCachePrecargada=True',
                       [iFilas, iForms]));
    // Listar los forms cacheados para saber exactamente qué se precargó
    for sKeyForm in FCachePerfilesForm.Keys do
      FRegistroLog.RegistrarInformacion(
        Format('PrecargarPerfilesUsuario: cache form="%s" claves=%d',
                         [sKeyForm, FCachePerfilesForm[sKeyForm].Count]));
  except
    // Si la precarga falla, dejamos FCachePrecargada=False para que los
    // callers (GetFormUserProfile) caigan al camino SQL/SP anterior y la
    // app siga funcionando.
    on E: Exception do
    begin
      FCachePerfilesForm.Clear;
      FRegistroLog.RegistrarError(
        Format('PrecargarPerfilesUsuario: EXCEPCION %s: %s ' +
                          'filas_leidas_antes_fallo=%d. ' +
                          'FCachePrecargada queda False, cache vacio',
                          [E.ClassName, E.Message, iFilas]));
    end;
  end;
  end;
end;

function TdmPerfiles.ObtenerPerfilFormCache(const AFormName: string;
                                       out APerfilDic: TProfileDicc): Boolean;
var
  Cached: TProfileDicc;
begin
  APerfilDic := nil;
  Result := False;
  if not FCachePrecargada then
  begin
    FRegistroLog.RegistrarAviso(
      Format('ObtenerPerfilFormCache: form="%s" cache NO precargado ' +
                          '(FCachePrecargada=False), devuelve False',
                          [AFormName]));
  end
  else
  begin
    // Servimos siempre un clon: el consumidor libera su copia
    if FCachePerfilesForm.TryGetValue(AFormName, Cached) then
    begin
      APerfilDic := ClonarPerfilDicc(Cached);
      FRegistroLog.RegistrarInformacion(
        Format('ObtenerPerfilFormCache: form="%s" HIT claves=%d',
                         [AFormName, Cached.Count]));
    end
    else
    begin
      APerfilDic := TProfileDicc.Create;
      FRegistroLog.RegistrarAviso(
        Format('ObtenerPerfilFormCache: form="%s" MISS ' +
               '(precargado pero sin entrada), devuelve dicc vacio ' +
               'con Result=True', [AFormName]));
    end;
    Result := True;
  end;
end;

function TdmPerfiles.CargarPerfilFormulario(
  const AFormulario: string;
  out APerfil: TProfileDicc): Boolean;
begin
  Result := ObtenerPerfilFormCache(AFormulario, APerfil);
  if not Result then
  begin
    APerfil := CargarPerfilFormDesdeDB(AFormulario);
    Result := True;
  end;
end;

function TdmPerfiles.CargarPerfilFormulario(
  const AFormulario, AUsuario, AGrupo: string;
  out APerfil: TProfileDicc): Boolean;
var
  IdentidadActual: TIdentidadSesion;
  Perfil: TDictValue;
  Consulta: TUniQuery;
begin
  IdentidadActual := IdentidadSesion;
  if (AUsuario = IdentidadActual.Usuario) and
     (AGrupo = IdentidadActual.Grupo) then
    Result := CargarPerfilFormulario(AFormulario, APerfil)
  else
  begin
    APerfil := TProfileDicc.Create;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := ConexionPrincipal;
      Consulta.SQL.Text := 'CALL PRC_GETPERFILFORMULARIO(:u, :g, :f)';
      Consulta.Params[0].AsString := AUsuario;
      Consulta.Params[1].AsString := AGrupo;
      Consulta.Params[2].AsString := AFormulario;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Perfil.sValue :=
          Consulta.FieldByName('VALUE_USUPER').AsString;
        Perfil.sValueText :=
          Consulta.FieldByName('VALUE_TEXT_USUPER').AsWideString;
        APerfil.AddOrSetValue(
          Consulta.FieldByName('SUBKEY_USUPER').AsString,
          Perfil);
        Consulta.Next;
      end;
      Result := True;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TdmPerfiles.ResincronizarPerfilFormulario(
  const AFormulario: string);
var
  Nuevo: TProfileDicc;
begin
  if not FCachePrecargada then
  begin
    FRegistroLog.RegistrarAviso(
      Format('ResincronizarCachePerfilForm: form="%s" ' +
                          'cache no precargado, ignorado', [AFormulario]));
  end
  else
  begin
    Nuevo := CargarPerfilFormDesdeDB(AFormulario);
    if Nuevo.Count > 0 then
    begin
      FCachePerfilesForm.AddOrSetValue(AFormulario, Nuevo);
      FRegistroLog.RegistrarInformacion(
        Format('ResincronizarCachePerfilForm: form="%s" actualizado ' +
                         'claves=%d', [AFormulario, Nuevo.Count]));
    end
    else
    begin
      FreeAndNil(Nuevo);
      FCachePerfilesForm.Remove(AFormulario);
      FRegistroLog.RegistrarInformacion(
        Format('ResincronizarCachePerfilForm: form="%s" sin filas, ' +
                         'eliminado del cache', [AFormulario]));
    end;
  end;
end;

procedure TdmPerfiles.ActualizarPerfilFormulario(
  const AFormulario: string; APerfil: TProfileDicc);
begin
  if FCachePrecargada then
    FCachePerfilesForm.AddOrSetValue(AFormulario, ClonarPerfilDicc(APerfil));
end;

procedure TdmPerfiles.InvalidarCachePerfiles;
begin
  FRegistroLog.RegistrarInformacion(
    'InvalidarCachePerfiles: limpio cache y marco no precargado');
  FCachePerfilesForm.Clear;
  FCachePrecargada := False;
end;

procedure TdmPerfiles.EliminarPerfil(
  const AUsuarioGrupo, AClave: string;
  const ASubclave: string);
var
  unqryDelete: TUniQuery;
begin
  unqryDelete := TUniQuery.Create(nil);
  try
    unqryDelete.Connection := ConexionPrincipal;
    unqryDelete.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                            ' WHERE USUARIO_GRUPO_USUPER = :UserGroup ' +
                            '   AND KEY_USUPER = :Key';

    // Si pasamos un SubKey, lo añadimos a la condición de borrado
    if ASubclave <> '' then
      unqryDelete.SQL.Add(' AND SUBKEY_USUPER = :SubKey');

    unqryDelete.ParamByName('UserGroup').AsString := AUsuarioGrupo;
    unqryDelete.ParamByName('Key').AsString := AClave;
    if ASubclave <> '' then
      unqryDelete.ParamByName('SubKey').AsString := ASubclave;

    unqryDelete.Execute;
  finally
    FreeAndNil(unqryDelete);
  end;
  ResincronizarPerfilFormulario(AClave);
end;

function TdmPerfiles.ObtenerValorPerfil(
  const AClave, ASubclave, AValorPredeterminado: string): string;
var
  IdentidadActual: TIdentidadSesion;
begin
  IdentidadActual := IdentidadSesion;
  Result := AValorPredeterminado;
  unqryPerfiles.Close;
  // Delegamos la jerarquía al motor SQL. El que quede primero será el de
  // mayor prioridad.
  unqryPerfiles.SQL.Text := '  SELECT VALUE_USUPER ' +
    '    FROM fza_usuarios_perfiles ' +
    '   WHERE KEY_USUPER = :key ' +
    '     AND SUBKEY_USUPER = :subkey ' +
    '     AND USUARIO_GRUPO_USUPER IN (:user, :group, :todos) ' +
    '     AND TYPE_BLOB_USUPER IS NULL ' +
    'ORDER BY CASE USUARIO_GRUPO_USUPER ' +
    '            WHEN :user THEN 1 ' +
    '            WHEN :group THEN 2 ' +
    '            WHEN :todos THEN 3 ' +
    '         END';
  unqryPerfiles.ParamByName('user').AsString := IdentidadActual.Usuario;
  unqryPerfiles.ParamByName('group').AsString := IdentidadActual.Grupo;
  unqryPerfiles.ParamByName('todos').AsString := PERFIL_TODOS;
  unqryPerfiles.ParamByName('key').AsString := AClave;
  unqryPerfiles.ParamByName('subkey').AsString := ASubclave;
  unqryPerfiles.Open;
  // Como está ordenado por prioridad, si hay registros, el primero es el
  // correcto
  if not unqryPerfiles.IsEmpty then
    Result := unqryPerfiles.FieldByName('VALUE_USUPER').AsString;
  unqryPerfiles.Close;
end;

function TdmPerfiles.ObtenerSubclavePerfil(
  const AClave, AValorPredeterminado: string): string;
var
  IdentidadActual: TIdentidadSesion;
begin
  IdentidadActual := IdentidadSesion;
  Result := AValorPredeterminado;
  unqryPerfiles.Close;
  unqryPerfiles.SQL.Text := '  SELECT SUBKEY_USUPER ' +
    '    FROM fza_usuarios_perfiles ' +
    '   WHERE KEY_USUPER = :key ' +
    '     AND USUARIO_GRUPO_USUPER IN (:user, :group, :todos) ' +
    'ORDER BY CASE USUARIO_GRUPO_USUPER ' +
    '            WHEN :user THEN 1 ' +
    '            WHEN :group THEN 2 ' +
    '            WHEN :todos THEN 3 ' +
    '         END';
  unqryPerfiles.ParamByName('key').AsString := AClave;
  unqryPerfiles.ParamByName('user').AsString := IdentidadActual.Usuario;
  unqryPerfiles.ParamByName('group').AsString := IdentidadActual.Grupo;
  unqryPerfiles.ParamByName('todos').AsString := PERFIL_TODOS;
  unqryPerfiles.Open;
  if not unqryPerfiles.IsEmpty then
    Result := unqryPerfiles.FieldByName('SUBKEY_USUPER').AsString;
  unqryPerfiles.Close;
end;

procedure TdmPerfiles.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
begin
  unstdGrabarPerfil.Connection := ConexionPrincipal;
  unstdGrabarPerfil.ParamByName('pUSUARIO').AsString := AUsuarioGrupo;
  unstdGrabarPerfil.ParamByName('pKEY').AsString := AClave;
  unstdGrabarPerfil.ParamByName('pSUBKEY').AsString := ASubclave;
  unstdGrabarPerfil.ParamByName('pVALUE').AsString := AValor;
  unstdGrabarPerfil.ParamByName('pVALUE_TEXT').AsString := AValorTexto;
  unstdGrabarPerfil.ParamByName('pUSUARIO_MODIF').AsString :=
    IdentidadSesion.Usuario;
  unstdGrabarPerfil.Execute;
  ResincronizarPerfilFormulario(AClave);
end;

procedure TdmPerfiles.GrabarPerfiles(const APerfiles: TPerfilList);
const
  BATCH_SIZE = 500;
var
  i, iStart, iEnd: Integer;
  sSQL: TStringBuilder;
  qry: TUniQuery;
  sUsuarioActual: string;
  oClavesAfectadas: TList<string>;
  sClave: string;
begin
  if (APerfiles <> nil) and (APerfiles.Count > 0) then
  begin
  // El usuario que está grabando, para USUARIO_ALTA / USUARIO_MODIF
  sUsuarioActual := IdentidadSesion.Usuario;

  qry := TUniQuery.Create(nil);
  sSQL := TStringBuilder.Create;
  try
    qry.Connection := ConexionPrincipal;

    iStart := 0;
    while iStart < APerfiles.Count do
    begin
      iEnd := iStart + BATCH_SIZE - 1;
      if iEnd >= APerfiles.Count then
        iEnd := APerfiles.Count - 1;

      sSQL.Clear;
      sSQL.Append(
        'INSERT INTO fza_usuarios_perfiles ' +
        '(USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER, ' +
        ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES ');

      for i := iStart to iEnd do
      begin
        if i > iStart then sSQL.Append(',');
        sSQL.AppendFormat(
          '(:u%d, :k%d, :s%d, :v%d, CURRENT_TIMESTAMP, :ua, :ua)',
          [i, i, i, i]);
      end;

      sSQL.Append(
        ' ON DUPLICATE KEY UPDATE ' +
        '  VALUE_USUPER = VALUES(VALUE_USUPER), ' +
        '  USUARIO_MODIF   = VALUES(USUARIO_MODIF)');

      qry.SQL.Text := sSQL.ToString;
      qry.ParamByName('ua').AsString := sUsuarioActual;

      for i := iStart to iEnd do
      begin
        qry.ParamByName(Format('u%d', [i])).AsString :=
          APerfiles[i].UserGroup;
        qry.ParamByName(Format('k%d', [i])).AsString :=
          APerfiles[i].KeyPerfil;
        qry.ParamByName(Format('s%d', [i])).AsString :=
          APerfiles[i].SubKey;
        qry.ParamByName(Format('v%d', [i])).AsString :=
          APerfiles[i].Value;
      end;

      qry.Execute;
      iStart := iEnd + 1;
    end;
  finally
    FreeAndNil(sSQL);
    FreeAndNil(qry);
  end;

  // Resincronizar la caché solo para las KEY tocadas
  oClavesAfectadas := TList<string>.Create;
  try
    for i := 0 to APerfiles.Count - 1 do
      if oClavesAfectadas.IndexOf(APerfiles[i].KeyPerfil) < 0 then
        oClavesAfectadas.Add(APerfiles[i].KeyPerfil);
    for sClave in oClavesAfectadas do
      ResincronizarPerfilFormulario(sClave);
  finally
    FreeAndNil(oClavesAfectadas);
  end;
  end;
end;

procedure TdmPerfiles.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  ActualizarAuditoria(DataSet);
end;

end.

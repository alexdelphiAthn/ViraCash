{ Catálogo y persistencia de las páginas de consultoría de la base activa. }
unit UniDataPaginasExtension;

interface

uses
  System.Classes, System.SysUtils, System.Variants, Data.DB, Uni,
  inLibPermisosIntf;

type
  EValidacionPagina = class(EArgumentException);

  TReferenciaPagina = record
    Campo, Etiqueta, Origen, Clave, Texto, Filtro, Valor: string;
  end;

  TPaginaExtension = record
    Id, Nombre, Tipo, Origen, Campos, Script: string;
    RotulosLista, RotulosFicha, AnchosLista: string;
    MotorImpresion: string;
    Clase, Entrada, AntesGuardar, Selectores: string;
    Mantenimiento, Maestro, Detalle, Proyecto, Grupo: string;
    Referencia: TReferenciaPagina;
    Menu, Publicada, SoloOrigen: Boolean;
    Version: Integer;
    function Serializar: string;
    function UsaFastReport: Boolean;
    function ClavePermiso: string;
    class function Leer(const ANombre, ATexto: string;
      AVersion: Integer): TPaginaExtension; static;
  end;

  TRepositorioPaginas = class(TComponent)
  private
    FConexion: TUniConnection;
    FPermisos: IPermisosAplicacion;
    FUsuario: string;
    function Consulta(const ASql: string): TUniQuery;
    function Listar(Borrador: Boolean; SoloDisponibles: Boolean): TArray<TPaginaExtension>;
    procedure GuardarEstado(var APagina: TPaginaExtension; Modo: Integer);
  public
    constructor Create(AConexion: TUniConnection;
      const APermisos: IPermisosAplicacion; const AUsuario: string;
      AOwner: TComponent = nil); reintroduce;
    function PuedeDisenar: Boolean;
    function Puede(const ANombre, AAccion: string): Boolean;
    function VersionProyecto(const Nombre: string): Integer;
    procedure GuardarProyecto(const Nombre, Archivo: string;
      var Version: Integer; var Elementos: TArray<TPaginaExtension>);
    function Publicaciones: TArray<TPaginaExtension>;
    function Activas: TArray<TPaginaExtension>;
    function Borradores: TArray<TPaginaExtension>;
    procedure GuardarBorrador(var Pagina: TPaginaExtension);
    procedure CambiarPublicacion(var Paginas: TArray<TPaginaExtension>;
      Activar: Boolean);
    procedure Origenes(const ATipo: string; ALista: TStrings;
      const ANombre: string = '');
    procedure Columnas(const ATipo, AOrigen: string; ALista: TStrings);
    procedure Publicar(var APagina: TPaginaExtension);
    function Abrir(const P: TPaginaExtension; AEnFicha: Boolean;
      const AClave: Variant; AParametros: TStrings): TUniQuery;
    function Opciones(Propietario: TComponent; const R: TReferenciaPagina;
      Filtrar: Boolean; const Actual: Variant): TUniQuery;
    procedure ExigirReferencia(const R: TReferenciaPagina; const Valor: Variant);
    procedure Validar(const P: TPaginaExtension);
    procedure ExigirVigente(const P: TPaginaExtension);
  end;

const
  LongitudNombreConsultoria = 53;
  AnchoColumnaConsultoria = 150;
  AnchoMaximoColumnaConsultoria = 10000;
  Tabla = 'Tabla';
  Vista = 'Vista';
  Procedimiento = 'Procedimiento';

implementation

uses
  System.JSON, System.StrUtils, DBAccess;

const
  Prefijo = 'Pagina/';

function TPaginaExtension.ClavePermiso: string;
begin
  if Grupo = '' then Result := Nombre else Result := Grupo + '.' + Nombre;
end;

function TPaginaExtension.UsaFastReport: Boolean;
begin
  Result := not SameText(MotorImpresion, 'DevExpress');
end;

function TPaginaExtension.Serializar: string;
var
  J: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('nombre',Nombre);
    J.AddPair('clase',Clase);
    J.AddPair('entrada',Entrada);
    J.AddPair('evento',AntesGuardar);
    J.AddPair('selectores',Selectores);
    J.AddPair('grupo', Grupo);
    J.AddPair('soloOrigen', SoloOrigen);
    J.AddPair('tipo', Tipo);
    J.AddPair('origen', Origen);
    J.AddPair('campos', Campos);
    J.AddPair('rotulosLista', RotulosLista);
    J.AddPair('rotulosFicha', RotulosFicha);
    J.AddPair('anchosLista', AnchosLista);
    J.AddPair('motorImpresion', MotorImpresion);
    J.AddPair('antesGuardar', Script);
    J.AddPair('menu', Menu);
    J.AddPair('mantenimiento', Mantenimiento);
    J.AddPair('maestro', Maestro);
    J.AddPair('detalle', Detalle);
    J.AddPair('proyectoTMS', Proyecto);
    J.AddPair('refCampo', Referencia.Campo);
    J.AddPair('refEtiqueta', Referencia.Etiqueta);
    J.AddPair('refOrigen', Referencia.Origen);
    J.AddPair('refClave', Referencia.Clave);
    J.AddPair('refTexto', Referencia.Texto);
    J.AddPair('refFiltro', Referencia.Filtro);
    J.AddPair('refValor', Referencia.Valor);
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TPaginaExtension.Leer(const ANombre, ATexto: string;
  AVersion: Integer): TPaginaExtension;
var
  J: TJSONValue;
begin
  J := TJSONObject.ParseJSONValue(ATexto);
  try
    if not (J is TJSONObject) then
      raise EConvertError.CreateFmt('Definición ilegible de «%s».', [ANombre]);
    Result.Grupo := J.GetValue<string>('grupo','');
    Result.SoloOrigen := J.GetValue<Boolean>('soloOrigen',False);
    Result.Id := ANombre;
    Result.Nombre := J.GetValue<string>('nombre',ANombre);
    Result.Clase := J.GetValue<string>('clase','Pantalla');
    Result.Entrada := J.GetValue<string>('entrada','Inicio');
    Result.AntesGuardar := J.GetValue<string>('evento','AntesGuardar');
    Result.Selectores := J.GetValue<string>('selectores','Selectores');
    Result.Version := AVersion;
    Result.Tipo := J.GetValue<string>('tipo');
    Result.Origen := J.GetValue<string>('origen');
    Result.Campos := J.GetValue<string>('campos');
    Result.RotulosLista := J.GetValue<string>('rotulosLista', '');
    Result.RotulosFicha := J.GetValue<string>('rotulosFicha', '');
    Result.AnchosLista := J.GetValue<string>('anchosLista', '');
    Result.MotorImpresion := J.GetValue<string>('motorImpresion', '');
    Result.Script := J.GetValue<string>('antesGuardar');
    Result.Menu := J.GetValue<Boolean>('menu');
    Result.Mantenimiento := J.GetValue<string>('mantenimiento');
    Result.Maestro := J.GetValue<string>('maestro');
    Result.Detalle := J.GetValue<string>('detalle');
    Result.Proyecto := J.GetValue<string>('proyectoTMS','');
    Result.Referencia.Campo := J.GetValue<string>('refCampo','');
    Result.Referencia.Etiqueta := J.GetValue<string>('refEtiqueta','');
    Result.Referencia.Origen := J.GetValue<string>('refOrigen','');
    Result.Referencia.Clave := J.GetValue<string>('refClave','');
    Result.Referencia.Texto := J.GetValue<string>('refTexto','');
    Result.Referencia.Filtro := J.GetValue<string>('refFiltro','');
    Result.Referencia.Valor := J.GetValue<string>('refValor','');
  finally
    J.Free;
  end;
end;

constructor TRepositorioPaginas.Create(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario: string;
  AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FPermisos := APermisos;
  FUsuario := AUsuario;
end;

function TRepositorioPaginas.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TRepositorioPaginas.PuedeDisenar: Boolean;
begin
  Result := Assigned(FPermisos) and FPermisos.TienePermiso(
    'menu.mnuEditorPaginas', paExigirConcesion);
end;

function TRepositorioPaginas.Puede(const ANombre, AAccion: string): Boolean;
begin
  Result := PuedeDisenar or (Assigned(FPermisos) and FPermisos.TienePermiso(
    'consultoria.' + ANombre + '.' + AAccion, paExigirConcesion));
end;

procedure SepararEstado(const Contenido: string; out Borrador, Publicado, Retirado: string);
var
  J: TJSONValue;
begin
  J := TJSONObject.ParseJSONValue(Contenido);
  try
    if not (J is TJSONObject) then
      raise EConvertError.Create('El proyecto guardado es ilegible.');
    Retirado := J.GetValue<string>('origenRetirado','');
    if not J.TryGetValue<string>('borrador',Borrador) then
    begin
      Borrador := Contenido;
      Publicado := Contenido;
    end
    else
      Publicado := J.GetValue<string>('publicado','');
  finally
    J.Free;
  end;
end;

function TRepositorioPaginas.Publicaciones: TArray<TPaginaExtension>;
begin
  Result := Listar(False,True);
end;

function TRepositorioPaginas.Activas: TArray<TPaginaExtension>;
begin
  if not PuedeDisenar then
    raise EInvalidOpException.Create('Falta el permiso de diseño.');
  Result := Listar(False,False);
end;

function TRepositorioPaginas.Borradores: TArray<TPaginaExtension>;
begin
  if not PuedeDisenar then
    raise EInvalidOpException.Create('Falta el permiso de diseño.');
  Result := Listar(True,False);
end;

function TRepositorioPaginas.Listar(Borrador: Boolean; SoloDisponibles: Boolean): TArray<TPaginaExtension>;
var
  Q: TUniQuery;
  Nombre, Texto, Publicado, Retirado: string;
  Pagina, Def: TPaginaExtension;
  Inactivos, Activos: TStringList;
  Candidatas: TArray<TPaginaExtension>;
begin
  Result := nil;
  Q := Consulta('SELECT CODIGO_CPROY, CONTENIDO_CPROY, VERSION_CPROY ' +
    'FROM fza_consultoria_proyectos WHERE CODIGO_CPROY LIKE ''Pagina/%'' ' +
    'ORDER BY CODIGO_CPROY');
  Inactivos := TStringList.Create;
  Activos := TStringList.Create;
  try
    try
      Q.Open;
    except
      on E: EUniError do
        if (E.ErrorCode <> 1146) and (E.ErrorCode <> 1142) then
          raise;
    end;
    while Q.Active and not Q.Eof do
    begin
      Nombre := Copy(Q.Fields[0].AsString, Length(Prefijo) + 1);
      SepararEstado(Q.Fields[1].AsString,Texto,Publicado,Retirado);
      if SoloDisponibles then
      begin
        if Retirado <> '' then
          Inactivos.Add(Retirado);
        if Publicado <> '' then
        begin
          Def := TPaginaExtension.Leer(Nombre,Publicado,Q.Fields[2].AsInteger);
          if Def.SoloOrigen then
            Activos.Add(Def.Grupo+'/'+Def.Tipo+'/'+Def.Origen);
        end;
      end;
      begin
        if not Borrador then
          Texto := Publicado;
        if Texto <> '' then
        begin
          Pagina := TPaginaExtension.Leer(Nombre,Texto,Q.Fields[2].AsInteger);
          Pagina.Publicada := Publicado <> '';
          if Borrador or Puede(Pagina.ClavePermiso,'abrir') then
            Candidatas := Candidatas + [Pagina];
        end;
      end;
      Q.Next;
    end;
    for Pagina in Candidatas do
      if not SoloDisponibles or (not Pagina.SoloOrigen and
        ((Inactivos.IndexOf(Pagina.Grupo+'/'+Pagina.Tipo+'/'+Pagina.Origen)<0) or
         (Activos.IndexOf(Pagina.Grupo+'/'+Pagina.Tipo+'/'+Pagina.Origen)>=0)) and
        ((Inactivos.IndexOf(Pagina.Grupo+'/'+Tabla+'/'+Pagina.Referencia.Origen)<0) or
         (Activos.IndexOf(Pagina.Grupo+'/'+Tabla+'/'+Pagina.Referencia.Origen)>=0)) and
        ((Inactivos.IndexOf(Pagina.Grupo+'/'+Vista+'/'+Pagina.Referencia.Origen)<0) or
         (Activos.IndexOf(Pagina.Grupo+'/'+Vista+'/'+Pagina.Referencia.Origen)>=0))) then
        Result := Result + [Pagina];
  finally
    Inactivos.Free;
    Activos.Free;
    Q.Free;
  end;
end;

procedure TRepositorioPaginas.Origenes(const ATipo: string; ALista: TStrings;
  const ANombre: string);
var
  Q: TUniQuery;
  SQL, ColumnaNombre: string;
begin
  if ATipo = Procedimiento then
  begin
    ColumnaNombre := 'r.ROUTINE_NAME';
    SQL := 'SELECT r.ROUTINE_NAME FROM information_schema.ROUTINES r ' +
      'WHERE r.ROUTINE_SCHEMA=DATABASE() AND r.ROUTINE_TYPE=''PROCEDURE'' ' +
      'AND r.SQL_DATA_ACCESS IN (''READS SQL DATA'',''NO SQL'') AND NOT EXISTS ' +
      '(SELECT 1 FROM information_schema.PARAMETERS p WHERE ' +
      'p.SPECIFIC_SCHEMA=r.ROUTINE_SCHEMA AND p.SPECIFIC_NAME=r.ROUTINE_NAME ' +
      'AND p.ROUTINE_TYPE=r.ROUTINE_TYPE AND p.PARAMETER_MODE<>''IN'')';
  end
  else
  begin
    ColumnaNombre := 't.TABLE_NAME';
    SQL := 'SELECT t.TABLE_NAME FROM information_schema.TABLES t ' +
      'WHERE t.TABLE_SCHEMA=DATABASE() AND t.TABLE_TYPE=:tipo AND EXISTS ' +
      '(SELECT 1 FROM information_schema.COLUMNS c WHERE ' +
      'c.TABLE_SCHEMA=t.TABLE_SCHEMA AND c.TABLE_NAME=t.TABLE_NAME ' +
      'AND FIND_IN_SET(''select'',c.PRIVILEGES)>0)';
  end;
  if ANombre <> '' then
    SQL := SQL + ' AND ' + ColumnaNombre + '=:origen';
  Q := Consulta(SQL + ' ORDER BY ' + ColumnaNombre);
  try
    if ANombre <> '' then
      Q.ParamByName('origen').AsString := ANombre;
    if ATipo <> Procedimiento then
      Q.ParamByName('tipo').AsString := IfThen(ATipo = Tabla, 'BASE TABLE',
        'VIEW');
    Q.Open;
    ALista.Clear;
    while not Q.Eof do
    begin
      ALista.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TRepositorioPaginas.Columnas(const ATipo, AOrigen: string;
  ALista: TStrings);
var
  Q: TUniQuery;
begin
  if ATipo = Procedimiento then
    Q := Consulta('SELECT PARAMETER_NAME FROM information_schema.PARAMETERS ' +
      'WHERE SPECIFIC_SCHEMA=DATABASE() AND SPECIFIC_NAME=:origen ' +
      'AND ROUTINE_TYPE=''PROCEDURE'' ORDER BY ORDINAL_POSITION')
  else
    Q := Consulta('SELECT COLUMN_NAME FROM information_schema.COLUMNS ' +
      'WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=:origen ' +
      'AND FIND_IN_SET(''select'',PRIVILEGES)>0 ORDER BY ORDINAL_POSITION');
  try
    Q.ParamByName('origen').AsString := AOrigen;
    Q.Open;
    ALista.Clear;
    while not Q.Eof do
    begin
      ALista.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function Ident(const S: string): string;
begin
  Result := #96 + StringReplace(S, #96, #96#96, [rfReplaceAll]) + #96;
end;

function TRepositorioPaginas.Opciones(Propietario: TComponent;
  const R: TReferenciaPagina; Filtrar: Boolean; const Actual: Variant): TUniQuery;
begin
  Result := TUniQuery.Create(Propietario);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := 'SELECT ' + Ident(R.Clave) + ' AS clave, ' +
      Ident(R.Texto) + ' AS texto FROM ' + Ident(R.Origen);
    if Filtrar and (R.Filtro <> '') then
    begin
      Result.SQL.Add('WHERE ' + Ident(R.Filtro) + '=:valor');
      Result.ParamByName('valor').AsString := R.Valor;
      if not VarIsNull(Actual) then
      begin
        Result.SQL.Add(' OR ' + Ident(R.Clave) + '=:actual');
        Result.ParamByName('actual').Value := Actual;
      end;
    end;
    Result.SQL.Add('ORDER BY texto,clave');
    Result.ReadOnly := True;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

procedure TRepositorioPaginas.ExigirReferencia(const R: TReferenciaPagina;
  const Valor: Variant);
var
  Q: TUniQuery;
begin
  if Trim(VarToStr(Valor)) = '' then
    raise EDatabaseError.CreateFmt('Seleccione un valor para %s.',[R.Etiqueta]);
  Q := Consulta('SELECT 1 FROM ' + Ident(R.Origen) +
    ' WHERE ' + Ident(R.Clave) + '=:clave');
  try
    Q.ParamByName('clave').Value := Valor;
    if R.Filtro <> '' then
    begin
      Q.SQL.Add('AND ' + Ident(R.Filtro) + '=:valor');
      Q.ParamByName('valor').AsString := R.Valor;
    end;
    Q.Open;
    if Q.IsEmpty then
      raise EDatabaseError.CreateFmt('El valor de %s ya no está disponible.',
        [R.Etiqueta]);
  finally
    Q.Free;
  end;
end;

procedure TRepositorioPaginas.Validar(const P: TPaginaExtension);
var
  Disponibles, Elegidos: TStringList;
  S: string;
begin
  if (Trim(P.Nombre) = '') or (Length(P.Nombre) > LongitudNombreConsultoria) then
    raise EValidacionPagina.Create('Indique un nombre de hasta 53 caracteres.');
  if not P.SoloOrigen and not P.Menu and (P.Mantenimiento = '') then
    raise EValidacionPagina.Create('Elija un destino para la publicación.');
  if (P.Clase = 'Funcionalidad') and (P.Origen = '') and P.Menu then
    Exit;
  if Trim(P.Origen) = '' then
    raise EValidacionPagina.Create('Elija el origen en Proyecto > Datos y publicación > Lista y ficha.');
  if (P.Tipo <> Tabla) and (P.Tipo <> Vista) and (P.Tipo <> Procedimiento) then
    raise EValidacionPagina.Create('Tipo de origen desconocido.');
  Disponibles := TStringList.Create;
  Elegidos := TStringList.Create;
  try
    Origenes(P.Tipo, Disponibles, P.Origen);
    if Disponibles.IndexOf(P.Origen) < 0 then
      raise EValidacionPagina.CreateFmt('El origen «%s» ya no está disponible. Revíselo en Datos y publicación.', [P.Origen]);
    Columnas(P.Tipo, P.Origen, Disponibles);
    if (P.Mantenimiento <> '') and ((P.Maestro = '') or
      (Disponibles.IndexOf(P.Detalle) < 0)) then
      raise EValidacionPagina.Create('Seleccione el campo de enlace.');
    if P.Tipo = Procedimiento then
    begin
      if (P.Mantenimiento <> '') and (Disponibles.Count <> 1) then
        raise EValidacionPagina.Create('La pestaña requiere una sola entrada ' +
          'IN vinculada al registro principal.');
    end
    else
    begin
      Elegidos.CommaText := P.Campos;
      if (P.Referencia.Campo <> '') and ((P.Tipo <> Tabla) or
        (Elegidos.IndexOf(P.Referencia.Campo) < 0) or
        SameText(P.Detalle,P.Referencia.Campo)) then
        raise EValidacionPagina.Create('Marque el campo de la lista de selección ' +
          'y elija un campo de enlace distinto.');
      if (Elegidos.Count = 0) and not P.SoloOrigen then
        raise EValidacionPagina.Create('Marque los campos de la lista y ficha.');
      for S in Elegidos do
        if Disponibles.IndexOf(S) < 0 then
          raise EValidacionPagina.CreateFmt('Campo no disponible: %s.', [S]);
    end;
    if P.Referencia.Campo <> '' then
    begin
      Columnas(Tabla,P.Referencia.Origen,Disponibles);
      if (Disponibles.IndexOf(P.Referencia.Clave) < 0) or
         (Disponibles.IndexOf(P.Referencia.Texto) < 0) or
         ((P.Referencia.Filtro <> '') and
         (Disponibles.IndexOf(P.Referencia.Filtro) < 0)) then
        raise EValidacionPagina.Create('Revise el origen y los campos de la lista de selección.');
    end;
  finally
    Elegidos.Free;
    Disponibles.Free;
  end;
end;

procedure TRepositorioPaginas.GuardarEstado(var APagina: TPaginaExtension; Modo: Integer);
var
  Q: TUniQuery;
  J: TJSONObject;
  Borrador, Publicado, Retirado: string;
  Anterior: TPaginaExtension;
begin
  if not PuedeDisenar then
    raise EInvalidOpException.Create('Falta el permiso de diseño.');
  if (Trim(APagina.Nombre) = '') or (Length(APagina.Nombre) > LongitudNombreConsultoria) then
    raise EArgumentException.Create('Indique un nombre de hasta 53 caracteres.');
  if APagina.Id = '' then
    APagina.Id := TGUID.NewGuid.ToString;
  Publicado := '';
  Retirado := '';
  if APagina.Version > 0 then
  begin
    Q := Consulta('SELECT CONTENIDO_CPROY FROM fza_consultoria_proyectos ' +
      'WHERE CODIGO_CPROY=:id AND VERSION_CPROY=:version');
    try
      Q.ParamByName('id').AsString := Prefijo + APagina.Id;
      Q.ParamByName('version').AsInteger := APagina.Version;
      Q.Open;
      if Q.IsEmpty then
        raise EInvalidOpException.Create('Otra sesión modificó esta consultoría.');
      SepararEstado(Q.Fields[0].AsString,Borrador,Publicado,Retirado);
    finally
      Q.Free;
    end;
  end;
  Borrador := APagina.Serializar;
  case Modo of
    1: begin
      Validar(APagina);
      Publicado := Borrador;
      Retirado := '';
    end;
    2: begin
      if Publicado <> '' then
      begin
        Anterior := TPaginaExtension.Leer(APagina.Id,Publicado,APagina.Version);
        if Anterior.SoloOrigen then
          Retirado := Anterior.Grupo+'/'+Anterior.Tipo+'/'+Anterior.Origen;
      end;
      Publicado := '';
    end;
  end;
  if APagina.Version = 0 then
    Q := Consulta('INSERT INTO fza_consultoria_proyectos (CODIGO_CPROY,' +
      'CONTENIDO_CPROY,VERSION_CPROY,INSTANTE_ALTA,USUARIO_ALTA) ' +
      'VALUES (:id,:json,1,NOW(),:usr)')
  else
    Q := Consulta('UPDATE fza_consultoria_proyectos SET CONTENIDO_CPROY=:json,' +
      ' VERSION_CPROY=VERSION_CPROY+1, INSTANTE_MODIF=NOW(),USUARIO_MODIF=:usr' +
      ' WHERE CODIGO_CPROY=:id AND VERSION_CPROY=:version');
  try
    Q.ParamByName('id').AsString := Prefijo + APagina.Id;
    J := TJSONObject.Create;
    try
      J.AddPair('borrador',Borrador);
      J.AddPair('publicado',Publicado);
      J.AddPair('origenRetirado',Retirado);
      Q.ParamByName('json').AsMemo := J.ToJSON;
    finally
      J.Free;
    end;
    Q.ParamByName('usr').AsString := FUsuario;
    if APagina.Version <> 0 then
      Q.ParamByName('version').AsInteger := APagina.Version;
    try
      Q.ExecSQL;
    except
      on E: EUniError do
        if E.ErrorCode = 1062 then
          raise EInvalidOpException.Create('Ya existe una página con ese nombre.')
        else
          raise;
    end;
    if Q.RowsAffected <> 1 then
      raise EInvalidOpException.Create('Otra sesión modificó esta página. ' +
        'Vuelva a abrirla antes de publicar.');
    APagina.Publicada := Publicado <> '';
    Inc(APagina.Version);
  finally
    Q.Free;
  end;
end;

function TRepositorioPaginas.VersionProyecto(const Nombre: string): Integer;
var
  Q: TUniQuery;
begin
  Q := Consulta('SELECT VERSION_CPROY FROM fza_consultoria_proyectos ' +
    'WHERE CODIGO_CPROY=:id');
  try
    Q.ParamByName('id').AsString := 'TMS/' + Nombre;
    Q.Open;
    if Q.IsEmpty then Result := 0 else Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TRepositorioPaginas.GuardarProyecto(const Nombre, Archivo: string;
  var Version: Integer; var Elementos: TArray<TPaginaExtension>);
var
  Q: TUniQuery;
  Copia: TArray<TPaginaExtension>;
  Nombres: TStringList;
  i: Integer;
begin
  if not PuedeDisenar then
    raise EInvalidOpException.Create('Falta el permiso de diseño.');
  if (Trim(Nombre) = '') or (Length(Nombre) > LongitudNombreConsultoria) then
    raise EArgumentException.Create('Indique un nombre de proyecto de hasta 53 caracteres.');
  if FConexion.InTransaction then
    raise EInvalidOpException.Create('Termine la operación en curso antes de guardar.');
  Copia := Copy(Elementos);
  Nombres := TStringList.Create;
  try
    for i := 0 to High(Copia) do
    begin
      Copia[i].Nombre := Trim(Copia[i].Nombre);
      if (Copia[i].Nombre = '') or
        (Length(Copia[i].Nombre) > LongitudNombreConsultoria) then
        raise EArgumentException.CreateFmt(
          'Indique un nombre de hasta 53 caracteres para el elemento %d (%s).',
          [i+1,Copia[i].Clase]);
      if Nombres.IndexOf(Copia[i].Nombre) >= 0 then
        raise EArgumentException.Create('Cada elemento del proyecto necesita un nombre distinto.');
      Nombres.Add(Copia[i].Nombre);
    end;
  finally
    Nombres.Free;
  end;
  FConexion.StartTransaction;
  try
    if Version = 0 then
      Q := Consulta('INSERT INTO fza_consultoria_proyectos (CODIGO_CPROY,' +
        'CONTENIDO_CPROY,VERSION_CPROY,INSTANTE_ALTA,USUARIO_ALTA) ' +
        'VALUES (:id,:archivo,1,NOW(),:usr)')
    else
      Q := Consulta('UPDATE fza_consultoria_proyectos SET CONTENIDO_CPROY=:archivo,' +
        ' VERSION_CPROY=VERSION_CPROY+1,INSTANTE_MODIF=NOW(),USUARIO_MODIF=:usr' +
        ' WHERE CODIGO_CPROY=:id AND VERSION_CPROY=:ver');
    try
      Q.ParamByName('id').AsString := 'TMS/' + Nombre;
      Q.ParamByName('archivo').AsMemo := Archivo;
      Q.ParamByName('usr').AsString := FUsuario;
      if Version <> 0 then Q.ParamByName('ver').AsInteger := Version;
      Q.ExecSQL;
      if Q.RowsAffected <> 1 then
        raise EInvalidOpException.Create('El proyecto ha cambiado. Vuelva a abrirlo.');
    finally
      Q.Free;
    end;
    for i := 0 to High(Copia) do
    begin
      Copia[i].Grupo := Nombre;
      Copia[i].Proyecto := Archivo;
      GuardarEstado(Copia[i],0);
    end;
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
  Inc(Version);
  Elementos := Copia;
end;

procedure TRepositorioPaginas.GuardarBorrador(var Pagina: TPaginaExtension);
begin
  GuardarEstado(Pagina,0);
end;

procedure TRepositorioPaginas.Publicar(var APagina: TPaginaExtension);
begin
  GuardarEstado(APagina,1);
end;

procedure TRepositorioPaginas.CambiarPublicacion(var Paginas: TArray<TPaginaExtension>;
  Activar: Boolean);
var
  Cambios: TArray<TPaginaExtension>;
  i: Integer;
begin
  if FConexion.InTransaction then
    raise EInvalidOpException.Create('Termine la operación en curso antes de publicar.');
  Cambios := Copy(Paginas);
  FConexion.StartTransaction;
  try
    for i := 0 to High(Cambios) do
      if Activar then
        GuardarEstado(Cambios[i],1)
      else
        GuardarEstado(Cambios[i],2);
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
  Paginas := Cambios;
end;

procedure TRepositorioPaginas.ExigirVigente(const P: TPaginaExtension);
var
  Actual: TPaginaExtension;
begin
  if (P.Version > 0) and (P.Id <> '') then
  begin
    for Actual in Publicaciones do
      if (Actual.Id = P.Id) and (Actual.Serializar = P.Serializar) then
        Exit;
    raise EInvalidOpException.Create('La publicación ha cambiado. Vuelva a abrir el elemento.');
  end;
end;

function TRepositorioPaginas.Abrir(const P: TPaginaExtension;
  AEnFicha: Boolean; const AClave: Variant; AParametros: TStrings): TUniQuery;
var
  Metas, Q: TUniQuery;
  Campos, Claves, Protegidos: TStringList;
  S, ParametrosSQL, Proyeccion: string;
  i: Integer;
  F: TField;
begin
  if not Puede(P.ClavePermiso, 'abrir') then
    raise EInvalidOpException.Create('Falta el permiso de consulta.');
  Validar(P);
  Campos := TStringList.Create;
  Claves := TStringList.Create;
  Protegidos := TStringList.Create;
  Q := Consulta('');
  try
    try
      if P.Tipo = Procedimiento then
      begin
        Columnas(P.Tipo, P.Origen, Campos);
        if not AEnFicha and (Campos.Count > 0) and
          ((AParametros = nil) or (AParametros.Count <> Campos.Count)) then
          raise EArgumentException.Create('Faltan parámetros del procedimiento.');
        ParametrosSQL := '';
        for i := 0 to Campos.Count-1 do
        begin
          if i > 0 then
            ParametrosSQL := ParametrosSQL + ',';
          ParametrosSQL := ParametrosSQL + ':p' + IntToStr(i);
        end;
        Q.SQL.Text := 'CALL ' + Ident(P.Origen) + '(' + ParametrosSQL + ')';
        for i := 0 to Campos.Count-1 do
          if AEnFicha then
            Q.Params[i].Value := AClave
          else
            Q.Params[i].AsString := AParametros[i];
        Q.ReadOnly := True;
      end
      else
      begin
        Campos.CommaText := P.Campos;
        Metas := Consulta('SELECT COLUMN_NAME,COLUMN_KEY,EXTRA,IS_GENERATED,' +
          'PRIVILEGES FROM information_schema.COLUMNS WHERE ' +
          'TABLE_SCHEMA=DATABASE() AND TABLE_NAME=:t ORDER BY ORDINAL_POSITION');
        try
          Metas.ParamByName('t').AsString := P.Origen;
          Metas.Open;
          while not Metas.Eof do
          begin
            S := Metas.Fields[0].AsString;
            if Metas.Fields[1].AsString = 'PRI' then
            begin
              Claves.Add(S);
              if Campos.IndexOf(S) < 0 then
                Campos.Add(S);
            end;
            if ContainsText(Metas.Fields[2].AsString,'auto_increment') or
              SameText(Metas.Fields[3].AsString,'ALWAYS') then
              Protegidos.Add(S);
            Metas.Next;
          end;
        finally
          Metas.Free;
        end;
        if AEnFicha and (Campos.IndexOf(P.Detalle) < 0) then
          Campos.Add(P.Detalle);
        Proyeccion := '';
        for S in Campos do
        begin
          if Proyeccion <> '' then
            Proyeccion := Proyeccion + ',';
          Proyeccion := Proyeccion + Ident(S);
        end;
        Q.SQL.Text := 'SELECT ' + Proyeccion + ' FROM ' + Ident(P.Origen);
        if AEnFicha then
        begin
          Q.SQL.Add('WHERE ' + Ident(P.Detalle) + '=:maestro');
          Q.ParamByName('maestro').Value := AClave;
        end;
        Q.ReadOnly := (P.Tipo <> Tabla) or (Claves.Count = 0) or
          (P.Clase = 'Listado') or (P.Clase = 'Análisis') or
          not Puede(P.ClavePermiso,'editar');
        if not Q.ReadOnly then
        begin
          Q.UpdatingTable := P.Origen;
          Q.KeyFields := string.Join(';',Claves.ToStringArray);
          Q.Options.UpdateAllFields := False;
        end;
      end;
      Q.Open;
      for S in Protegidos do
      begin
        F := Q.FindField(S);
        if Assigned(F) then
        begin
          F.Required := False;
          F.ReadOnly := True;
        end;
      end;
      Result := Q;
    except
      Q.Free;
      raise;
    end;
  finally
    Protegidos.Free;
    Claves.Free;
    Campos.Free;
  end;
end;

end.

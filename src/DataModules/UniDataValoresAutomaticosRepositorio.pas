unit UniDataValoresAutomaticosRepositorio;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni,
  inLibValoresAutomaticosPersistenciaIntf;

type
  TRepositorioValoresAutomaticosUniDAC = class(
    TInterfacedObject, IRepositorioValoresAutomaticos)
  private
    FConexion: TUniConnection;
    procedure ComprobarConexion;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerSeriePropiaAlmacen(const AEmpresa,
      ATipoDocumento, AAlmacen: string): string;
    function ObtenerSerieDefecto(const AEmpresa, ATipoDocumento,
      AAlmacen: string): string;
    procedure CargarSeriesEmpresa(const AEmpresa,
      ATipoDocumento: string; AElementos: TStrings);
    function ObtenerSiguienteContador(const ATipoDocumento,
      AUsuario: string): TResultadoContadorAutomatico;
    function ObtenerValorPorDefecto(const ATabla, ACampo,
      ACampoCondicion: string): string;
    function CargarValoresPorDefecto(const ANombreTabla: string):
      TArray<TValorPorDefectoPersistido>;
  end;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
function ObtenerSerieDefecto(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  const AAlmacen: string = ''): string;
procedure CargarSeriesEmpresa(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  AElementos: TStrings);
function ObtenerSiguienteContador(AConexion: TUniConnection;
  const ATipoDocumento, AUsuario: string): string;
function ObtenerValorPorDefecto(AConexion: TUniConnection;
  const ATabla, ACampo, ACampoCondicion: string): string;
procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);

// La reparación y la reserva participan en la transacción del documento.
procedure EjecutarContadorDocumentoUniDAC(AProcedimiento: TUniStoredProc;
  AEsAdministrador: Boolean;
  const AConfirmar: TFunc<string, Boolean>);

implementation

uses
  System.Generics.Collections, inLibDocumento, inLibDocumentoIntf,
  inLibValoresAutomaticos, inLibMsgVentas;

const
  SQL_VIGENCIA_SERIE =
    '   AND (FECHA_DESDE_EMPSER IS NULL OR ' +
    'FECHA_DESDE_EMPSER <= CURDATE()) ' +
    '   AND (FECHA_HASTA_EMPSER IS NULL OR ' +
    'FECHA_HASTA_EMPSER >= CURDATE()) ';
  // En un mismo ámbito se propone la serie por defecto ('S' > 'N'). A
  // igualdad de marca gana la que ya tiene contador activo para ese
  // documento: proponer otra obligaba a crear un contador que nadie
  // pidió y repartía pedidos y albaranes en dos series (FZ-ISSUE-441).
  SQL_ORDEN_SERIE_DEFECTO =
    ' ORDER BY ESDEFECTO_EMPSER DESC, ' +
    '   (SELECT COUNT(*) FROM fza_contadores CON_SERIE ' +
    '     WHERE CON_SERIE.TIPO_DOC_CON = TIPO_DOC_EMPSER ' +
    '       AND CON_SERIE.EMPRESA_CON = CODIGO_EMP_EMPSER ' +
    '       AND CON_SERIE.SERIE_CON = EMPSER ' +
    '       AND CON_SERIE.ESACTIVO_CON = ''S'') DESC, ' +
    '   EMPSER ';

function ConfiguracionContador(const ATipo: string):
  TConfiguracionDocumento;
var
  Tipo: TTipoDocumento;
  Sentido: TSentidoDocumento;
  Configuracion: TConfiguracionDocumento;
begin
  Result := Default(TConfiguracionDocumento);
  for Tipo := Low(TTipoDocumento) to High(TTipoDocumento) do
    for Sentido := Low(TSentidoDocumento) to High(TSentidoDocumento) do
      if not ((Sentido = sdCompra) and (Tipo = tdPresupuesto)) and
         not ((Sentido = sdVenta) and (Tipo = tdDevolucion)) then
      begin
        Configuracion := CrearConfiguracionDocumento(Tipo, Sentido);
        if SameText(Configuracion.TipoContador, ATipo) then
          Result := Configuracion;
      end;
end;

function NormalizarClaveContador(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Result = '' then
    Result := '-';
end;

procedure RepararContadorDocumento(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ATipo, AEmpresa, ASerie, AUsuario: string);
var
  Siguiente: Int64;
begin
  // Solo identificadores procedentes de la configuración propia del código.
  AConsulta.SQL.Text := Format(
    'SELECT COALESCE(MAX(CAST(%s AS UNSIGNED)), 0) + 1 AS SIGUIENTE ' +
    'FROM %s WHERE %s = :SERIE AND %s REGEXP ''^[0-9]+$''',
    [AConfiguracion.CampoNumeroCabecera, AConfiguracion.TablaCabecera,
     AConfiguracion.CampoSerieCabecera,
     AConfiguracion.CampoNumeroCabecera]);
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.Open;
  Siguiente := AConsulta.FieldByName('SIGUIENTE').AsLargeInt;
  AConsulta.Close;
  if (Siguiente < 1) or (Length(IntToStr(Siguiente)) > 12) then
    raise Exception.Create(SErrorNumeracionDocumentoDemasiadoLarga);
  AConsulta.SQL.Text :=
    'UPDATE fza_contadores SET CON = GREATEST(CON, :SIGUIENTE), ' +
    'NUM_DIGITOS_CON = GREATEST(NUM_DIGITOS_CON, :DIGITOS), ' +
    'ESACTIVO_CON = ''S'', USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() WHERE TIPO_DOC_CON = :TIPO ' +
    'AND EMPRESA_CON = :EMPRESA AND SERIE_CON = :SERIE ' +
    'AND ESACTIVO_CON <> ''S''';
  AConsulta.ParamByName('SIGUIENTE').AsLargeInt := Siguiente;
  AConsulta.ParamByName('DIGITOS').AsInteger := Length(IntToStr(Siguiente));
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('TIPO').AsString := ATipo;
  AConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ExecSQL;
end;

// Hay ya un documento con esa serie y ese número, de la empresa que sea.
// Acceso por la clave primaria de la cabecera (serie y número).
function NumeroDocumentoOcupado(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ASerie, ANumero: string): Boolean;
begin
  // Solo identificadores procedentes de la configuración propia del código.
  AConsulta.SQL.Text := Format(
    'SELECT 1 FROM %s WHERE %s = :SERIE AND %s = :NUMERO LIMIT 1',
    [AConfiguracion.TablaCabecera, AConfiguracion.CampoSerieCabecera,
     AConfiguracion.CampoNumeroCabecera]);
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  Result := not AConsulta.IsEmpty;
  AConsulta.Close;
end;

procedure EjecutarContadorDocumentoUniDAC(AProcedimiento: TUniStoredProc;
  AEsAdministrador: Boolean;
  const AConfirmar: TFunc<string, Boolean>);
const
  // Tope de números ya ocupados que se saltan en una petición.
  MAX_SALTOS_NUMERO_OCUPADO = 1000;
var
  Conexion: TUniConnection;
  Consulta: TUniQuery;
  Reserva: TUniStoredProc;
  Configuracion: TConfiguracionDocumento;
  Tipo, Empresa, Serie, Usuario, Mensaje, Numero: string;
  Propia, Activo, Ocupado: Boolean;
  Saltos: Integer;
  procedure AsignarClave;
  begin
    Consulta.ParamByName('TIPO').AsString := Tipo;
    Consulta.ParamByName('EMPRESA').AsString := Empresa;
    Consulta.ParamByName('SERIE').AsString := Serie;
  end;
begin
  Tipo := AProcedimiento.ParamByName('pTipoDoc').AsString;
  Configuracion := ConfiguracionContador(Tipo);
  if Configuracion.TipoContador = '' then
    AProcedimiento.ExecProc
  else
  begin
    Conexion := AProcedimiento.Connection;
    Empresa := NormalizarClaveContador(
      AProcedimiento.ParamByName('pEMPRESA_CONTADOR').AsString);
    Serie := NormalizarClaveContador(
      AProcedimiento.ParamByName('pserie').AsString);
    Usuario := AProcedimiento.ParamByName('pUSUARIOMODIF').AsString;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := Conexion;
      Consulta.SQL.Text :=
        'SELECT ESACTIVO_CON FROM fza_contadores ' +
        'WHERE TIPO_DOC_CON = :TIPO AND EMPRESA_CON = :EMPRESA ' +
        'AND SERIE_CON = :SERIE';
      AsignarClave;
      Consulta.Open;
      Activo := not Consulta.IsEmpty and
        SameText(Consulta.FieldByName('ESACTIVO_CON').AsString, 'S');
      Consulta.Close;
      Mensaje := Format(SAvisoSerieSinContadorActivo,
        [Serie, Configuracion.NombreSingular]);
      if not Activo then
      begin
        if not AEsAdministrador then
          raise Exception.Create(Mensaje + sLineBreak +
            SAvisoAdministradorActivarContador);
        if not Assigned(AConfirmar) then
          raise Exception.Create(Mensaje);
        if not AConfirmar(Mensaje + sLineBreak +
          SPreguntaActivarContadorDocumento) then
          Abort;
      end;
      Propia := not Conexion.InTransaction;
      if Propia then
        Conexion.StartTransaction;
      try
        if not Activo then
        begin
          // El alta serializa dos reparaciones simultáneas. Si otra sesión
          // ya activó el contador, no se altera su siguiente número.
          Consulta.SQL.Text :=
            'INSERT INTO fza_contadores (TIPO_DOC_CON, EMPRESA_CON, ' +
            'SERIE_CON, CON, NUM_DIGITOS_CON, ESACTIVO_CON, DEFAULT_CON, ' +
            'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
            'VALUES (:TIPO, :EMPRESA, :SERIE, 1, 6, ''N'', ''N'', ' +
            'NOW(), :USUARIO, :USUARIO) ' +
            'ON DUPLICATE KEY UPDATE CON = fza_contadores.CON';
          AsignarClave;
          Consulta.ParamByName('USUARIO').AsString := Usuario;
          Consulta.ExecSQL;
          RepararContadorDocumento(Consulta, Configuracion,
            Tipo, Empresa, Serie, Usuario);
        end;
        // Lectura actual y bloqueo: no reutiliza una instantánea anterior
        // si otra sesión desactivó el contador durante la confirmación.
        Consulta.SQL.Text :=
          'SELECT ESACTIVO_CON, NUM_DIGITOS_CON, CON FROM fza_contadores ' +
          'WHERE TIPO_DOC_CON = :TIPO AND EMPRESA_CON = :EMPRESA ' +
          'AND SERIE_CON = :SERIE FOR UPDATE';
        AsignarClave;
        Consulta.Open;
        if Consulta.IsEmpty or not SameText(
          Consulta.FieldByName('ESACTIVO_CON').AsString, 'S') then
          raise Exception.Create(Mensaje + sLineBreak +
            SAvisoAdministradorRevisarContador);
        if (Consulta.FieldByName('NUM_DIGITOS_CON').AsInteger > 12) or
           (Consulta.FieldByName('CON').AsLargeInt > 999999999999) then
          raise Exception.Create(
            SErrorNumeracionDocumentoDemasiadoLarga);
        Consulta.Close;
        Reserva := TUniStoredProc.Create(nil);
        try
          Reserva.Connection := Conexion;
          Reserva.StoredProcName := 'PRC_GET_NEXT_CONTADOR';
          Reserva.Params.CreateParam(ftString, 'pTipoDoc', ptInput).
            AsString := Tipo;
          Reserva.Params.CreateParam(ftString, 'pEmpresa', ptInput).
            AsString := Empresa;
          Reserva.Params.CreateParam(ftString, 'pSerie', ptInput).
            AsString := Serie;
          Reserva.Params.CreateParam(ftString, 'pUsuario', ptInput).
            AsString := Usuario;
          Reserva.Params.CreateParam(ftString, 'pContador', ptOutput);
          // FZ-ISSUE-390: el contador es por empresa, pero el documento se
          // identifica por serie y número, sin empresa. Si otra empresa
          // comparte la serie, se saltan los números que ya ocupó.
          Saltos := 0;
          repeat
            Reserva.ExecProc;
            Numero := Reserva.ParamByName('pContador').AsString;
            Ocupado := NumeroDocumentoOcupado(Consulta, Configuracion,
              AProcedimiento.ParamByName('pserie').AsString, Numero);
            Inc(Saltos);
          until not Ocupado or (Saltos > MAX_SALTOS_NUMERO_OCUPADO);
          if Ocupado then
            raise Exception.CreateFmt(SErrorNumeracionSerieOcupada,
              [Serie, Configuracion.NombreSingular]);
          AProcedimiento.ParamByName('pcont').AsString := Numero;
        finally
          Reserva.Free;
        end;
        if Propia then
          Conexion.Commit;
      except
        if Propia and Conexion.InTransaction then
          Conexion.Rollback;
        raise;
      end;
    finally
      Consulta.Free;
    end;
  end;
end;

constructor TRepositorioValoresAutomaticosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioValoresAutomaticosUniDAC.ComprobarConexion;
begin
  if not Assigned(FConexion) then
  begin
    raise EValoresAutomaticosPersistencia.Create(
      evaConexionNoDisponible,
      'La conexión de valores automáticos no está activa.');
  end;
  // Tras agotar LocalFailover UniDAC deja Connected=False. Reconectar
  // antes de una petición nueva; nunca repetir una reserva de contador.
  if not FConexion.Connected then
  begin
    try
      FConexion.Connect;
    except
      on E: Exception do
        raise EValoresAutomaticosPersistencia.Create(
          evaConexionNoDisponible, E.Message);
    end;
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSeriePropiaAlmacen(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT EMPSER FROM vi_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER = :tip ' +
        '   AND CODIGO_ALM_EMPSER = :alm ' +
        SQL_VIGENCIA_SERIE +
        SQL_ORDEN_SERIE_DEFECTO +
        ' LIMIT 1';
      oConsulta.ParamByName('emp').AsString := AEmpresa;
      oConsulta.ParamByName('tip').AsString := ATipoDocumento;
      oConsulta.ParamByName('alm').AsString := AAlmacen;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('EMPSER').AsString;
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSerieDefecto(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
  sFiltroAlmacen: string;
begin
  Result := '';
  ComprobarConexion;
  if Trim(AAlmacen) <> '' then
  begin
    Result := ObtenerSeriePropiaAlmacen(
      AEmpresa, ATipoDocumento, AAlmacen);
  end;
  if Result = '' then
  begin
    sFiltroAlmacen := '';
    if Trim(AAlmacen) <> '' then
    begin
      sFiltroAlmacen :=
        '   AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ';
    end;
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT EMPSER FROM vi_empresas_series ' +
          ' WHERE CODIGO_EMP_EMPSER = :emp ' +
          '   AND TIPO_DOC_EMPSER = :tip ' +
          SQL_VIGENCIA_SERIE +
          sFiltroAlmacen +
          SQL_ORDEN_SERIE_DEFECTO +
          ' LIMIT 1';
        oConsulta.ParamByName('emp').AsString := AEmpresa;
        oConsulta.ParamByName('tip').AsString := ATipoDocumento;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          Result := oConsulta.FieldByName('EMPSER').AsString;
      except
        on E: Exception do
        begin
          raise EValoresAutomaticosPersistencia.Create(
            evaLecturaFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioValoresAutomaticosUniDAC.CargarSeriesEmpresa(
  const AEmpresa, ATipoDocumento: string; AElementos: TStrings);
var
  oConsulta: TUniQuery;
begin
  ComprobarConexion;
  AElementos.Clear;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT EMPSER FROM vi_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER = :tip ' +
        SQL_VIGENCIA_SERIE +
        ' GROUP BY EMPSER ' +
        ' ORDER BY MAX(ESDEFECTO_EMPSER) DESC, EMPSER';
      oConsulta.ParamByName('emp').AsString := AEmpresa;
      oConsulta.ParamByName('tip').AsString := ATipoDocumento;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        AElementos.Add(
          oConsulta.FieldByName('EMPSER').AsString);
        oConsulta.Next;
      end;
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSiguienteContador(
  const ATipoDocumento, AUsuario: string):
  TResultadoContadorAutomatico;
var
  oProcedimiento: TUniStoredProc;
  ConexionDisponible: Boolean;
begin
  ConexionDisponible := False;
  try
    ComprobarConexion;
    ConexionDisponible := True;
  except
    on E: EValoresAutomaticosPersistencia do
      Result := TResultadoContadorAutomatico.Fallido(
        E.Error, E.Message);
  end;
  if ConexionDisponible then
  begin
    oProcedimiento := TUniStoredProc.Create(nil);
    try
      oProcedimiento.Connection := FConexion;
      oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT';
      oProcedimiento.Params.Clear;
      oProcedimiento.Params.CreateParam(
        ftString, 'pTipoDoc', ptInput).AsString :=
        ATipoDocumento;
      oProcedimiento.Params.CreateParam(
        ftString, 'pUSUARIO_MODIF', ptInput).AsString :=
        AUsuario;
      oProcedimiento.Params.CreateParam(
        ftString, 'pcont', ptOutput);
      try
        oProcedimiento.Execute;
        Result := TResultadoContadorAutomatico.Correcto(
          oProcedimiento.Params.ParamByName(
            'pcont').AsString);
      except
        on E: Exception do
        begin
          Result := TResultadoContadorAutomatico.Fallido(
            evaGeneracionContadorFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oProcedimiento);
    end;
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerValorPorDefecto(
  const ATabla, ACampo, ACampoCondicion: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := Format(
        'SELECT %s FROM %s WHERE %s = %s LIMIT 1',
        [ACampo, ATabla, ACampoCondicion, QuotedStr('S')]);
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.Fields[0].AsString;
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.CargarValoresPorDefecto(
  const ANombreTabla: string): TArray<TValorPorDefectoPersistido>;
var
  oConsulta: TUniQuery;
  oElemento: TValorPorDefectoPersistido;
  oElementos: TList<TValorPorDefectoPersistido>;
begin
  ComprobarConexion;
  oElementos := TList<TValorPorDefectoPersistido>.Create;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT CAMPO_OBJETIVO_DEF_VD, ' +
          '       VALOR_DEF_VD, ' +
          '       TIPO_DATO_DEF_VD ' +
          '  FROM fza_valores_defecto ' +
          ' WHERE TABLA_OBJETIVO_DEF_VD = :TABLA';
        oConsulta.ParamByName('TABLA').AsString := ANombreTabla;
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          oElemento.Campo := oConsulta.FieldByName(
            'CAMPO_OBJETIVO_DEF_VD').AsString;
          oElemento.Valor := oConsulta.FieldByName(
            'VALOR_DEF_VD').AsString;
          oElemento.TipoDato := oConsulta.FieldByName(
            'TIPO_DATO_DEF_VD').AsString;
          oElementos.Add(oElemento);
          oConsulta.Next;
        end;
      except
        on E: Exception do
        begin
          raise EValoresAutomaticosPersistencia.Create(
            evaLecturaFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := oElementos.ToArray;
  finally
    FreeAndNil(oElementos);
  end;
end;

function CrearRepositorio(AConexion: TUniConnection):
  IRepositorioValoresAutomaticos;
begin
  Result := TRepositorioValoresAutomaticosUniDAC.Create(AConexion);
end;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSeriePropiaAlmacen(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AAlmacen);
end;

function ObtenerSerieDefecto(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSerieDefecto(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AAlmacen);
end;

procedure CargarSeriesEmpresa(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string; AElementos: TStrings);
begin
  inLibValoresAutomaticos.CargarSeriesEmpresa(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AElementos);
end;

function ObtenerSiguienteContador(AConexion: TUniConnection;
  const ATipoDocumento, AUsuario: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSiguienteContador(
    CrearRepositorio(AConexion), ATipoDocumento, AUsuario);
end;

function ObtenerValorPorDefecto(AConexion: TUniConnection;
  const ATabla, ACampo, ACampoCondicion: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerValorPorDefecto(
    CrearRepositorio(AConexion), ATabla, ACampo, ACampoCondicion);
end;

procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet; const ANombreTabla: string);
begin
  inLibValoresAutomaticos.AplicarValoresPorDefecto(
    CrearRepositorio(AConexion), ADataSetDestino, ANombreTabla);
end;

end.

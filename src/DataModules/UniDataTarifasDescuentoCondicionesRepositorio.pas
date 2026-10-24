{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataTarifasDescuentoCondicionesRepositorio                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia transaccional de las condiciones de descuento de tarifa.    }
{******************************************************************************}
unit UniDataTarifasDescuentoCondicionesRepositorio;

interface

uses
  Uni, inLibTarifasDescuentoCondicionesPersistenciaIntf;

function CrearRepositorioCondicionesDescuentoTarifaUniDAC(
  AConexion: TUniConnection): IRepositorioCondicionesDescuentoTarifa;

implementation

uses
  System.SysUtils, Data.DB,
  UniDataPrestaShopEncolado, inLibPrestaShopColaSenal;

const
  SQL_CARGAR_CONDICION =
    'SELECT MODO_TARDCO, CODIGO_PROP_TARDCO, ' +
    'POLITICA_SIN_VALOR_TARDCO ' +
    'FROM fza_tarifas_descuento_condiciones ' +
    'WHERE CODIGO_TAR_TARDCO = :TARIFA';
  SQL_CARGAR_VALORES =
    'SELECT ID_PV_TARDVA FROM fza_tarifas_descuento_valores ' +
    'WHERE CODIGO_TAR_TARDVA = :TARIFA ORDER BY ID_PV_TARDVA';
  SQL_LISTAR_PROPIEDADES =
    'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP ' +
    'FROM fza_propiedades WHERE ESACTIVO_PROP = ''S'' ' +
    'AND TIPO_VALOR_PROP = ''LISTA'' ' +
    'ORDER BY NOMBRE_PROP_PROP, CODIGO_PROP_ARTPROP';
  SQL_LISTAR_VALORES =
    'SELECT ID_PV_ARTPROP, PV FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = :PROPIEDAD AND ESACTIVO_PV = ''S'' ' +
    'ORDER BY PV, ID_PV_ARTPROP';
  SQL_VALIDAR_TARIFA =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas ' +
    'WHERE CODIGO_TAR_ARTTAR = :TARIFA';
  SQL_VALIDAR_PROPIEDAD =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_propiedades ' +
    'WHERE CODIGO_PROP_ARTPROP = :PROPIEDAD ' +
    'AND ESACTIVO_PROP = ''S'' AND TIPO_VALOR_PROP = ''LISTA''';
  SQL_VALIDAR_VALOR =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_propiedades_valores ' +
    'WHERE ID_PV_ARTPROP = :ID_VALOR AND ID_PROP_PV = :PROPIEDAD ' +
    'AND ESACTIVO_PV = ''S''';
  SQL_BORRAR_VALORES =
    'DELETE FROM fza_tarifas_descuento_valores ' +
    'WHERE CODIGO_TAR_TARDVA = :TARIFA';
  SQL_BORRAR_CONDICION =
    'DELETE FROM fza_tarifas_descuento_condiciones ' +
    'WHERE CODIGO_TAR_TARDCO = :TARIFA';
  SQL_GUARDAR_CONDICION =
    'INSERT INTO fza_tarifas_descuento_condiciones (' +
    'CODIGO_TAR_TARDCO, MODO_TARDCO, CODIGO_PROP_TARDCO, ' +
    'POLITICA_SIN_VALOR_TARDCO, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:TARIFA, :MODO, :PROPIEDAD, ' +
    '''NO_APLICAR'', NOW(), :USUARIO_ALTA, :USUARIO_MODIF) ' +
    'ON DUPLICATE KEY UPDATE MODO_TARDCO = VALUES(MODO_TARDCO), ' +
    'CODIGO_PROP_TARDCO = VALUES(CODIGO_PROP_TARDCO), ' +
    'POLITICA_SIN_VALOR_TARDCO = ''NO_APLICAR'', ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_INSERTAR_VALOR =
    'INSERT INTO fza_tarifas_descuento_valores (' +
    'CODIGO_TAR_TARDVA, ID_PV_TARDVA, INSTANTE_ALTA, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:TARIFA, :ID_VALOR, NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';

resourcestring
  SErrorConexionCondicionesDescuento =
    'La conexión es obligatoria para editar condiciones de descuento';
  SErrorTarifaCondicionObligatoria =
    'Seleccione una tarifa antes de guardar la condición de descuento';
  SErrorTarifaCondicionNoExiste =
    'La tarifa seleccionada ya no existe';
  SErrorPropiedadCondicionNoValida =
    'La propiedad debe existir, estar activa y ser de tipo LISTA';
  SErrorValorCondicionNoPertenece =
    'El valor %d no está activo o no pertenece a la propiedad %s';
  SErrorPoliticaSinValorNoValida =
    'Política no admitida para artículos sin valor de propiedad: %s';
  SErrorTransaccionCondicionActiva =
    'No se puede guardar la condición dentro de otra transacción activa';

type
  TRepositorioCondicionesDescuentoTarifaUniDAC = class(
    TInterfacedObject,
    IRepositorioCondicionesDescuentoTarifa)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): TUniQuery;
    procedure ValidarTarifa(const ACodigoTarifa: string);
    procedure ValidarPropiedadYValores(
      const ACondicion: TCondicionDescuentoTarifa);
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar(
      const ACodigoTarifa: string): TCondicionDescuentoTarifa;
    function ListarPropiedades: TPropiedadesListaDescuentoTarifa;
    function ListarValores(
      const ACodigoPropiedad: string): TValoresListaDescuentoTarifa;
    procedure Guardar(
      const ACodigoTarifa: string;
      const ACondicion: TCondicionDescuentoTarifa;
      const AUsuario: string);
  end;

constructor TRepositorioCondicionesDescuentoTarifaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      SErrorConexionCondicionesDescuento);
  FConexion := AConexion;
end;

function TRepositorioCondicionesDescuentoTarifaUniDAC.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TRepositorioCondicionesDescuentoTarifaUniDAC.Cargar(
  const ACodigoTarifa: string): TCondicionDescuentoTarifa;
var
  i: Integer;
  oConsulta: TUniQuery;
  sPolitica: string;
begin
  Result := CondicionDescuentoTodos;
  if Trim(ACodigoTarifa) <> '' then
  begin
    oConsulta := CrearConsulta(SQL_CARGAR_CONDICION);
    try
      oConsulta.ParamByName('TARIFA').AsString := Trim(ACodigoTarifa);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result.Modo := TextoAModoCondicionDescuento(
          oConsulta.FieldByName('MODO_TARDCO').AsString);
        sPolitica := UpperCase(Trim(
          oConsulta.FieldByName('POLITICA_SIN_VALOR_TARDCO').AsString));
        if sPolitica <> 'NO_APLICAR' then
          raise EDataBaseError.CreateFmt(
            SErrorPoliticaSinValorNoValida,
            [sPolitica]);
        if Result.Modo <> mcdTodos then
        begin
          Result.CodigoPropiedad := Trim(
            oConsulta.FieldByName('CODIGO_PROP_TARDCO').AsString);
          oConsulta.Close;
          oConsulta.SQL.Text := SQL_CARGAR_VALORES;
          oConsulta.ParamByName('TARIFA').AsString :=
            Trim(ACodigoTarifa);
          oConsulta.Open;
          i := 0;
          while not oConsulta.Eof do
          begin
            SetLength(Result.IdsValores, i + 1);
            Result.IdsValores[i] :=
              oConsulta.FieldByName('ID_PV_TARDVA').AsInteger;
            Inc(i);
            oConsulta.Next;
          end;
        end;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

function TRepositorioCondicionesDescuentoTarifaUniDAC.ListarPropiedades:
  TPropiedadesListaDescuentoTarifa;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_LISTAR_PROPIEDADES);
  try
    oConsulta.Open;
    i := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, i + 1);
      Result[i].Codigo := Trim(
        oConsulta.FieldByName('CODIGO_PROP_ARTPROP').AsString);
      Result[i].Nombre :=
        oConsulta.FieldByName('NOMBRE_PROP_PROP').AsString;
      Inc(i);
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioCondicionesDescuentoTarifaUniDAC.ListarValores(
  const ACodigoPropiedad: string): TValoresListaDescuentoTarifa;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  if Trim(ACodigoPropiedad) <> '' then
  begin
    oConsulta := CrearConsulta(SQL_LISTAR_VALORES);
    try
      oConsulta.ParamByName('PROPIEDAD').AsString :=
        Trim(ACodigoPropiedad);
      oConsulta.Open;
      i := 0;
      while not oConsulta.Eof do
      begin
        SetLength(Result, i + 1);
        Result[i].Id :=
          oConsulta.FieldByName('ID_PV_ARTPROP').AsInteger;
        Result[i].Nombre := oConsulta.FieldByName('PV').AsString;
        Inc(i);
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

procedure TRepositorioCondicionesDescuentoTarifaUniDAC.ValidarTarifa(
  const ACodigoTarifa: string);
var
  oConsulta: TUniQuery;
begin
  if Trim(ACodigoTarifa) = '' then
    raise EArgumentException.Create(
      SErrorTarifaCondicionObligatoria);
  oConsulta := CrearConsulta(SQL_VALIDAR_TARIFA);
  try
    oConsulta.ParamByName('TARIFA').AsString := Trim(ACodigoTarifa);
    oConsulta.Open;
    if oConsulta.FieldByName('CANTIDAD').AsInteger <> 1 then
      raise EArgumentException.Create(
        SErrorTarifaCondicionNoExiste);
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioCondicionesDescuentoTarifaUniDAC.
  ValidarPropiedadYValores(
  const ACondicion: TCondicionDescuentoTarifa);
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  if ACondicion.Modo <> mcdTodos then
  begin
    oConsulta := CrearConsulta(SQL_VALIDAR_PROPIEDAD);
    try
      oConsulta.ParamByName('PROPIEDAD').AsString :=
        Trim(ACondicion.CodigoPropiedad);
      oConsulta.Open;
      if oConsulta.FieldByName('CANTIDAD').AsInteger <> 1 then
        raise EArgumentException.Create(
          SErrorPropiedadCondicionNoValida);
      oConsulta.Close;
      oConsulta.SQL.Text := SQL_VALIDAR_VALOR;
      for i := 0 to High(ACondicion.IdsValores) do
      begin
        oConsulta.ParamByName('ID_VALOR').AsInteger :=
          ACondicion.IdsValores[i];
        oConsulta.ParamByName('PROPIEDAD').AsString :=
          Trim(ACondicion.CodigoPropiedad);
        oConsulta.Open;
        if oConsulta.FieldByName('CANTIDAD').AsInteger <> 1 then
          raise EArgumentException.CreateFmt(
            SErrorValorCondicionNoPertenece,
            [ACondicion.IdsValores[i], ACondicion.CodigoPropiedad]);
        oConsulta.Close;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

procedure TRepositorioCondicionesDescuentoTarifaUniDAC.Guardar(
  const ACodigoTarifa: string;
  const ACondicion: TCondicionDescuentoTarifa;
  const AUsuario: string);
var
  bEncolarPrestaShop: Boolean;
  i: Integer;
  oConsulta: TUniQuery;
  sCodigoTarifa: string;
  sUsuario: string;
begin
  sCodigoTarifa := Trim(ACodigoTarifa);
  sUsuario := Trim(AUsuario);
  ValidarCondicionDescuentoTarifa(ACondicion);
  ValidarTarifa(sCodigoTarifa);
  ValidarPropiedadYValores(ACondicion);
  if FConexion.InTransaction then
    raise EInvalidOpException.Create(
      SErrorTransaccionCondicionActiva);
  bEncolarPrestaShop := SameText(
    sCodigoTarifa,
    Trim(LeerCodigoTarifaPrestaShop(FConexion, sUsuario)));
  oConsulta := CrearConsulta(SQL_BORRAR_VALORES);
  try
    FConexion.StartTransaction;
    try
      oConsulta.ParamByName('TARIFA').AsString := sCodigoTarifa;
      oConsulta.Execute;
      if ACondicion.Modo = mcdTodos then
      begin
        oConsulta.SQL.Text := SQL_BORRAR_CONDICION;
        oConsulta.ParamByName('TARIFA').AsString := sCodigoTarifa;
        oConsulta.Execute;
      end
      else
      begin
        oConsulta.SQL.Text := SQL_GUARDAR_CONDICION;
        oConsulta.ParamByName('TARIFA').AsString := sCodigoTarifa;
        oConsulta.ParamByName('MODO').AsString :=
          ModoCondicionDescuentoATexto(ACondicion.Modo);
        oConsulta.ParamByName('PROPIEDAD').AsString :=
          Trim(ACondicion.CodigoPropiedad);
        oConsulta.ParamByName('USUARIO_ALTA').AsString := sUsuario;
        oConsulta.ParamByName('USUARIO_MODIF').AsString := sUsuario;
        oConsulta.Execute;
        oConsulta.SQL.Text := SQL_INSERTAR_VALOR;
        for i := 0 to High(ACondicion.IdsValores) do
        begin
          oConsulta.ParamByName('TARIFA').AsString := sCodigoTarifa;
          oConsulta.ParamByName('ID_VALOR').AsInteger :=
            ACondicion.IdsValores[i];
          oConsulta.ParamByName('USUARIO_ALTA').AsString := sUsuario;
          oConsulta.ParamByName('USUARIO_MODIF').AsString := sUsuario;
          oConsulta.Execute;
        end;
      end;
      if bEncolarPrestaShop then
        EncolarTodosWebPrestaShop(
          FConexion, True, False, sUsuario);
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    oConsulta.Free;
  end;
  if bEncolarPrestaShop then
    SolicitarProcesadoPrestaShop;
end;

function CrearRepositorioCondicionesDescuentoTarifaUniDAC(
  AConexion: TUniConnection): IRepositorioCondicionesDescuentoTarifa;
begin
  Result := TRepositorioCondicionesDescuentoTarifaUniDAC.Create(AConexion);
end;

end.

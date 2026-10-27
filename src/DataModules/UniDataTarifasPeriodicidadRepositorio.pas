{ Persistencia de periodicidad de tarifas. FZ-ISSUE-727. }
unit UniDataTarifasPeriodicidadRepositorio;

interface

uses
  Uni, inLibTarifasPeriodicidad;

function CrearRepositorioPeriodicidadTarifa(AConexion: TUniConnection):
  IRepositorioPeriodicidadTarifa;
function SqlPeriodicidadTarifa(const ATarifa, AFecha: string): string;

implementation

uses
  System.SysUtils, System.DateUtils, Data.DB;

type
  TRepositorioPeriodicidadTarifa = class(TInterfacedObject,
    IRepositorioPeriodicidadTarifa)
  private
    FConexion: TUniConnection;
    FComprobado: Boolean;
    FDisponible: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function Disponible: Boolean;
    function Cargar(const ATarifa: string): TPeriodosTarifa;
    procedure Guardar(const ATarifa: string; const APeriodos: TPeriodosTarifa;
      const AUsuario: string);
    function Vigente(const ATarifa: string; AFecha: TDateTime): Boolean;
  end;

function CrearRepositorioPeriodicidadTarifa(AConexion: TUniConnection):
  IRepositorioPeriodicidadTarifa;
begin
  Result := TRepositorioPeriodicidadTarifa.Create(AConexion);
end;

constructor TRepositorioPeriodicidadTarifa.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioPeriodicidadTarifa.Disponible: Boolean;
var
  Consulta: TUniQuery;
begin
  if not FComprobado then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
        'WHERE TABLE_SCHEMA = DATABASE() ' +
        'AND TABLE_NAME = ''fza_tarifas_periodos'' LIMIT 1';
      Consulta.Open;
      FDisponible := not Consulta.IsEmpty;
      FComprobado := True;
    finally
      Consulta.Free;
    end;
  end;
  Result := FDisponible;
end;

function TRepositorioPeriodicidadTarifa.Cargar(
  const ATarifa: string): TPeriodosTarifa;
var
  Consulta: TUniQuery;
  I: Integer;
begin
  Result := nil;
  if Disponible and (Trim(ATarifa) <> '') then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text := 'SELECT TIPO_TPER, DIA_DESDE_TPER, ' +
        'DIA_HASTA_TPER FROM fza_tarifas_periodos ' +
        'WHERE CODIGO_TAR_TPER = :TARIFA ORDER BY NUMERO_LINEA_TPER';
      Consulta.ParamByName('TARIFA').AsString := ATarifa;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        I := Length(Result);
        SetLength(Result, I + 1);
        Result[I].Tipo := TipoPeriodoTarifa(
          Consulta.FieldByName('TIPO_TPER').AsString);
        Result[I].Desde := Consulta.FieldByName('DIA_DESDE_TPER').AsInteger;
        Result[I].Hasta := Consulta.FieldByName('DIA_HASTA_TPER').AsInteger;
        Consulta.Next;
      end;
      ValidarPeriodosTarifa(Result);
    finally
      Consulta.Free;
    end;
  end;
end;

procedure TRepositorioPeriodicidadTarifa.Guardar(const ATarifa: string;
  const APeriodos: TPeriodosTarifa; const AUsuario: string);
var
  Consulta: TUniQuery;
  I: Integer;
begin
  ValidarPeriodosTarifa(APeriodos);
  if Trim(ATarifa) = '' then
    raise EArgumentException.Create('Guarde primero la tarifa.');
  if not Disponible then
    raise EInvalidOpException.Create('Instale la actualización 727.');
  if FConexion.InTransaction then
    raise EInvalidOpException.Create('Hay una transacción en curso.');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      Consulta.SQL.Text := 'SELECT CODIGO_TAR_ARTTAR FROM fza_tarifas ' +
        'WHERE CODIGO_TAR_ARTTAR = :TARIFA FOR UPDATE';
      Consulta.ParamByName('TARIFA').AsString := ATarifa;
      Consulta.Open;
      if Consulta.IsEmpty then
        raise EArgumentException.Create('La tarifa ya no existe.');
      Consulta.Close;
      Consulta.SQL.Text := 'DELETE FROM fza_tarifas_periodos ' +
        'WHERE CODIGO_TAR_TPER = :TARIFA';
      Consulta.ParamByName('TARIFA').AsString := ATarifa;
      Consulta.Execute;
      Consulta.SQL.Text := 'INSERT INTO fza_tarifas_periodos ' +
        '(CODIGO_TAR_TPER, NUMERO_LINEA_TPER, TIPO_TPER, ' +
        'DIA_DESDE_TPER, DIA_HASTA_TPER, INSTANTE_ALTA, ' +
        'USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:TARIFA, :LINEA, :TIPO, :DESDE, :HASTA, ' +
        'CURRENT_TIMESTAMP, :USUARIO, :USUARIO)';
      for I := 0 to High(APeriodos) do
      begin
        Consulta.ParamByName('TARIFA').AsString := ATarifa;
        Consulta.ParamByName('LINEA').AsInteger := I + 1;
        Consulta.ParamByName('TIPO').AsString :=
          TextoTipoPeriodoTarifa(APeriodos[I].Tipo);
        Consulta.ParamByName('DESDE').AsInteger := APeriodos[I].Desde;
        Consulta.ParamByName('HASTA').AsInteger := APeriodos[I].Hasta;
        Consulta.ParamByName('USUARIO').AsString := AUsuario;
        Consulta.Execute;
      end;
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioPeriodicidadTarifa.Vigente(const ATarifa: string;
  AFecha: TDateTime): Boolean;
var
  Periodos: TPeriodosTarifa;
  Consulta: TUniQuery;
  Desde, Hasta: TDateTime;
begin
  if AFecha = 0 then
    AFecha := Date;
  Periodos := Cargar(ATarifa);
  Result := (Length(Periodos) > 0) and
    CumplePeriodicidadTarifa(Periodos, AFecha);
  if Result then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text := 'SELECT FECHA_DESDE_DTO_TAR, ' +
        'FECHA_HASTA_DTO_TAR FROM fza_tarifas ' +
        'WHERE CODIGO_TAR_ARTTAR = :TARIFA AND ESACTIVO_ARTTAR = ''S'' ' +
        'AND ESIMP_INCL_TAR = ''S''';
      Consulta.ParamByName('TARIFA').AsString := ATarifa;
      Consulta.Open;
      Result := not Consulta.IsEmpty;
      if Result then
      begin
        Desde := Consulta.Fields[0].AsDateTime;
        Hasta := Consulta.Fields[1].AsDateTime;
        Result := ((Desde = 0) or (Trunc(AFecha) >= Trunc(Desde))) and
          ((Hasta = 0) or (Trunc(AFecha) <= Trunc(Hasta)));
      end;
    finally
      Consulta.Free;
    end;
  end;
end;

function SqlPeriodicidadTarifa(const ATarifa, AFecha: string): string;
var
  Valor, Rango: string;
begin
  // Expresiones fijas del llamador, nunca valores introducidos por usuario.
  Valor := '(CASE TP.TIPO_TPER ' +
    'WHEN ''SEMANA'' THEN WEEKDAY(' + AFecha + ') + 1 ' +
    'WHEN ''MES'' THEN DAYOFMONTH(' + AFecha + ') ' +
    'WHEN ''ANO'' THEN MONTH(' + AFecha + ') * 100 + DAYOFMONTH(' +
    AFecha + ') END)';
  Rango := '((TP.DIA_DESDE_TPER <= TP.DIA_HASTA_TPER AND ' + Valor +
    ' BETWEEN TP.DIA_DESDE_TPER AND TP.DIA_HASTA_TPER) OR ' +
    '(TP.DIA_DESDE_TPER > TP.DIA_HASTA_TPER AND (' + Valor +
    ' >= TP.DIA_DESDE_TPER OR ' + Valor + ' <= TP.DIA_HASTA_TPER)))';
  Result := '(NOT EXISTS (SELECT 1 FROM fza_tarifas_periodos TP ' +
    'WHERE TP.CODIGO_TAR_TPER = ' + ATarifa + ') OR EXISTS ' +
    '(SELECT 1 FROM fza_tarifas_periodos TP ' +
    'WHERE TP.CODIGO_TAR_TPER = ' + ATarifa + ' AND ' + Rango + '))';
end;

end.

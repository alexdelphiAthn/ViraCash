{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUnidadesMedida                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caché de unidades de medida (fza_unidades_medida) y utilidades de         }
{    formato. Centraliza cuántos decimales muestra cada unidad y la            }
{    conversión a la unidad estándar de su magnitud (cm/mm->m, g->kg...).      }
{    Lo usan ficha de artículo, líneas de documento, tickets e informes.       }
{******************************************************************************}
unit inLibUnidadesMedida;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, System.SysUtils,
  inLibLogIntf, inLibUnidadesMedidaPersistenciaIntf;

type
  TUnidadInfo = class
  public
    Codigo     : string;
    Descripcion: string;
    Decimales  : Integer;
    Magnitud   : string;
    EsBase     : Boolean;
    FactorBase : Double;
  end;

  TUnidadesMedida = class
  private
    FRepositorio: IRepositorioUnidadesMedida;
    FUnidades: TObjectDictionary<string, TUnidadInfo>;
    FDecimalesPorDefecto: Integer;
    FRegistroLog: IRegistroLog;
  public
    constructor Create; overload;
    constructor Create(const ARegistroLog: IRegistroLog); overload;
    constructor Create(
      const ARepositorio: IRepositorioUnidadesMedida;
      const ARegistroLog: IRegistroLog); overload;
    destructor Destroy; override;
    procedure AsignarRepositorio(
      const ARepositorio: IRepositorioUnidadesMedida);
    // (Re)carga la cache desde fza_unidades_medida. Tolera tabla ausente o
    // conexion cerrada: deja la cache vacia y aplican los valores por defecto.
    procedure Cargar;
    function Existe(const ACodigo: string): Boolean;
    // Info de la unidad o nil si no esta en la cache.
    function Info(const ACodigo: string): TUnidadInfo;
    // Decimales de la unidad; DecimalesPorDefecto si no se conoce.
    function Decimales(const ACodigo: string): Integer;
    // Mascara FormatFloat / DisplayFormat: '0', '0.00', '0.000'...
    function Mascara(const ACodigo: string): string;
    // Codigos de las unidades cargadas.
    function Codigos: TArray<string>;
    // FZ-ISSUE-235: DisplayFormat de un total que suma cantidades de
    // AUnidades: el maximo de decimales de las unidades conocidas
    // ('#,##0.00' con m; '#,##0' si todas son Uds). Sin ninguna conocida,
    // AFormatoSinUnidades.
    function MascaraTotales(const AUnidades: array of string;
      const AFormatoSinUnidades: string): string;
    // Cantidad ya formateada con los decimales de su unidad.
    function Formatear(const AValor: Double; const ACodigo: string): string;
    // True si origen y destino pertenecen a la misma magnitud (convertibles).
    function MismaMagnitud(const AOrigen, ADestino: string): Boolean;
    // Convierte un valor entre unidades de la misma magnitud. Si no son
    // convertibles (magnitud distinta o desconocida) devuelve el valor tal
    // cual.
    function Convertir(const AValor: Double;
                       const AOrigen, ADestino: string): Double;
    // Decimales que se aplican cuando la unidad es vacia o desconocida.
    // Por defecto 0 (comportamiento "Unidades", sin decimales).
    property DecimalesPorDefecto: Integer read FDecimalesPorDefecto
                                          write FDecimalesPorDefecto;
  end;
  // Decimales de la unidad de un articulo (FZ-ISSUE-246): lo aporta un
  // repositorio (UniDataDecimalesArticulo) a quien no tiene la unidad.
  TDecimalesArticulo = reference to function(
    const ACodigoArticulo: string): Integer;

  IProveedorUnidadesMedida = interface
    ['{5B714E5F-795D-4DDB-A3C0-6CFB54F535D9}']
    function GetUnidadesMedida: TUnidadesMedida;
    property UnidadesMedida: TUnidadesMedida
      read GetUnidadesMedida;
  end;

implementation

uses
  inLibRegistroLogNulo;

{ TUnidadesMedida }

constructor TUnidadesMedida.Create;
begin
  inherited;
  FRegistroLog := CrearRegistroLogNulo;
  FRepositorio := nil;
  FUnidades := TObjectDictionary<string, TUnidadInfo>.Create(
    [doOwnsValues],
    TIStringComparer.Ordinal);
  FDecimalesPorDefecto := 0;
end;

constructor TUnidadesMedida.Create(
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  FRepositorio := nil;
  // Comparador sin distincion de mayusculas: 'Uds' y 'uds' son la misma unidad.
  FUnidades := TObjectDictionary<string, TUnidadInfo>.Create([doOwnsValues],
                                                  TIStringComparer.Ordinal);
  FDecimalesPorDefecto := 0;
end;

constructor TUnidadesMedida.Create(
  const ARepositorio: IRepositorioUnidadesMedida;
  const ARegistroLog: IRegistroLog);
begin
  Create(ARegistroLog);
  FRepositorio := ARepositorio;
end;

destructor TUnidadesMedida.Destroy;
begin
  FRepositorio := nil;
  FRegistroLog := nil;
  FreeAndNil(FUnidades);
  inherited;
end;

procedure TUnidadesMedida.AsignarRepositorio(
  const ARepositorio: IRepositorioUnidadesMedida);
begin
  FRepositorio := ARepositorio;
end;

procedure TUnidadesMedida.Cargar;
var
  i: Integer;
  oDatos: TArray<TUnidadMedidaPersistida>;
  oInfo: TUnidadInfo;
  sCod: string;
begin
  FUnidades.Clear;
  if Assigned(FRepositorio) then
  begin
    try
      oDatos := FRepositorio.CargarUnidades;
      for i := 0 to Length(oDatos) - 1 do
      begin
        sCod := Trim(oDatos[i].Codigo);
        if sCod <> '' then
        begin
          oInfo := TUnidadInfo.Create;
          oInfo.Codigo := sCod;
          oInfo.Descripcion := oDatos[i].Descripcion;
          oInfo.Decimales := oDatos[i].Decimales;
          oInfo.Magnitud := oDatos[i].Magnitud;
          oInfo.EsBase := oDatos[i].EsBase;
          oInfo.FactorBase := oDatos[i].FactorBase;
          FUnidades.AddOrSetValue(sCod, oInfo);
        end;
      end;
    except
      // Tabla aun no creada o error de lectura: no rompemos el arranque,
      // la cache queda vacia y se usan los decimales por defecto.
      on E: Exception do
      begin
        FRegistroLog.RegistrarAviso(
          'inLibUnidadesMedida.Cargar: ' + E.Message);
      end;
    end;
  end;
end;

function TUnidadesMedida.Existe(const ACodigo: string): Boolean;
begin
  Result := FUnidades.ContainsKey(Trim(ACodigo));
end;

function TUnidadesMedida.Info(const ACodigo: string): TUnidadInfo;
begin
  if not FUnidades.TryGetValue(Trim(ACodigo), Result) then
    Result := nil;
end;

function TUnidadesMedida.Decimales(const ACodigo: string): Integer;
var
  oInfo: TUnidadInfo;
begin
  oInfo := Info(ACodigo);
  if oInfo <> nil then
    Result := oInfo.Decimales
  else
    Result := FDecimalesPorDefecto;
end;

function TUnidadesMedida.Mascara(const ACodigo: string): string;
var
  iDec: Integer;
begin
  iDec := Decimales(ACodigo);
  if iDec <= 0 then
    Result := '0'
  else
    Result := '0.' + StringOfChar('0', iDec);
end;

function TUnidadesMedida.Codigos: TArray<string>;
begin
  Result := FUnidades.Keys.ToArray;
end;

function TUnidadesMedida.MascaraTotales(const AUnidades: array of string;
  const AFormatoSinUnidades: string): string;
var
  i, iDecimales: Integer;
  bConocida: Boolean;
  oInfo: TUnidadInfo;
begin
  iDecimales := 0;
  bConocida := False;
  for i := Low(AUnidades) to High(AUnidades) do
  begin
    oInfo := Info(AUnidades[i]);
    if oInfo <> nil then
    begin
      bConocida := True;
      if oInfo.Decimales > iDecimales then
        iDecimales := oInfo.Decimales;
    end;
  end;
  if not bConocida then
    Result := AFormatoSinUnidades
  else if iDecimales > 0 then
    Result := '#,##0.' + StringOfChar('0', iDecimales)
  else
    Result := '#,##0';
end;

function TUnidadesMedida.Formatear(const AValor: Double;
                                   const ACodigo: string): string;
begin
  Result := FormatFloat(Mascara(ACodigo), AValor);
end;

function TUnidadesMedida.MismaMagnitud(const AOrigen,
                                       ADestino: string): Boolean;
var
  oOri, oDes: TUnidadInfo;
begin
  oOri := Info(AOrigen);
  oDes := Info(ADestino);
  Result := (oOri <> nil) and (oDes <> nil) and
            SameText(oOri.Magnitud, oDes.Magnitud);
end;

function TUnidadesMedida.Convertir(const AValor: Double;
                                   const AOrigen, ADestino: string): Double;
var
  oOri, oDes: TUnidadInfo;
begin
  oOri := Info(AOrigen);
  oDes := Info(ADestino);
  // Solo convertimos dentro de la misma magnitud y con factor destino valido.
  if (oOri = nil) or (oDes = nil) or
     (not SameText(oOri.Magnitud, oDes.Magnitud)) or
     (oDes.FactorBase = 0) then
    Result := AValor
  else
    Result := AValor * oOri.FactorBase / oDes.FactorBase;
end;

end.

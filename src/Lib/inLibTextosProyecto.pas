unit inLibTextosProyecto;

interface

uses
  System.Classes, System.JSON, atScript;

type
  TTextosProyecto = class(TComponent)
  private
    FArchivos: TJSONObject;
  public
    constructor Crear(Motor: TatCustomScripter; Archivos: TJSONObject);
  published
    function Idioma: string;
    function Texto(const Clave, Predeterminado: string): string;
  end;

const
  ClaveIdiomasProyecto = 'idiomas.json';

implementation

uses
  System.TypInfo, System.Rtti, inLibTraduccionesIntf, inLibTraducciones;

constructor TTextosProyecto.Crear(Motor: TatCustomScripter;
  Archivos: TJSONObject);
begin
  inherited Create(Motor);
  FArchivos := Archivos;
  Motor.DefineClassByRTTI(TTextosProyecto, '', [mvPublished]);
  Motor.AddObject('Idiomas', Self);
end;

function TTextosProyecto.Idioma: string;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := ResolverServicioTraducciones(Owner);
  Result := IDIOMA_ESPANOL;
  if Assigned(Servicio) then Result := Servicio.Idioma;
end;

function TTextosProyecto.Texto(const Clave, Predeterminado: string): string;
var
  Catalogo, Fila: TJSONValue;
  Valor: string;
begin
  Result := Predeterminado;
  if Assigned(FArchivos) then
  begin
    Catalogo := FArchivos.GetValue(ClaveIdiomasProyecto);
    if Catalogo is TJSONObject then
    begin
      Fila := TJSONObject(Catalogo).GetValue(Clave);
      if Fila is TJSONObject then
      begin
        Valor := TJSONObject(Fila).GetValue<string>(Idioma, '');
        if Valor = '' then
          Valor := TJSONObject(Fila).GetValue<string>(IDIOMA_ESPANOL, '');
        if Valor <> '' then Result := Valor;
      end;
    end;
  end;
end;

end.

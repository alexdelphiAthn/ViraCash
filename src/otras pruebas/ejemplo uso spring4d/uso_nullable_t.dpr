program uso_nullable_t;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Spring;

// Imprescindible para usar Nullable<T>

type
  TEmpleado = record
    Nombre: string;
    Edad: Nullable<Integer>;
    FechaUltimoAscenso: Nullable<TDateTime>;
  end;

function Bonificacion(dEdad:Nullable<Integer>):Currency;
begin
  // 2. Uso de GetValueOrDefault (muy útil para reportes)
  if dEdad.GetValueOrDefault(0) > 50 then
    Result:= 500
  else
    Result:=0;
end;

procedure ProcesarEmpleados;
var
  Emp: TEmpleado;
begin
  // --- Caso A: Empleado con datos completos ---
  Emp.Nombre := 'Juan Pérez';
  Emp.Edad := 30; // Asignación directa gracias a los operadores implícitos
  Emp.FechaUltimoAscenso := EncodeDate(2023, 05, 10);
  // --- Caso B: Empleado con datos nulos ---
  // Aquí simulamos que no conocemos la edad ni ha tenido ascensos
  var EmpIncompleto: TEmpleado;
  EmpIncompleto.Nombre := 'Ana García';
  EmpIncompleto.Edad := nil; // O simplemente no asignarlo
  EmpIncompleto.FechaUltimoAscenso := nil;
  // --- Lógica de Visualización ---
  var Lista: TArray<TEmpleado> := [Emp, EmpIncompleto];
  for var E in Lista do
  begin
    Writeln('Empleado: ' + E.Nombre);
    // 1. Uso de HasValue
    if E.Edad.HasValue then
      Writeln(' - Edad: ' + E.Edad.Value.ToString)
    else
      Writeln(' - Edad: No especificada');
    Writeln('Bonificación por edad: ' + CurrToStr(Bonificacion(e.Edad)));
    if E.FechaUltimoAscenso.HasValue then
      Writeln(' - Ascenso: ' + E.FechaUltimoAscenso.ToString)
    else
      Writeln(' - Ascenso: No ha tenido ascensos registrados');
    Writeln('-------------------------------');
  end;
end;

begin
  try
    ProcesarEmpleados;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

(*Cálculo de Bono: Crea una función que reciba un Nullable<Integer> (la edad).
  Si el valor existe y es mayor a 50, devuelve un bono de 500. Si es menor o
  nulo, devuelve 0.

  Encadenamiento: Usa el método .GetValueOrDefault(default)
  para mostrar la cadena "Sin fecha" si la FechaUltimoAscenso es nula.*)
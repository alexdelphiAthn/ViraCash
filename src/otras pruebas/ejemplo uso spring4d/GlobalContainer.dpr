program Project2;
{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Spring.Collections,
  Spring.Container,
  Spring;

type
  IDiscountStrategy = interface
    ['{A74DBF88-A791-448D-B5C1-D7B05672746E}']
    function ApplyDiscount(Amount: Double): Double;
    function GetName: string;
  end;

  TVIPDiscount = class(TInterfacedObject, IDiscountStrategy)
  public
    function ApplyDiscount(Amount: Double): Double;
    function GetName: string;
  end;

  TSeasonalDiscount = class(TInterfacedObject, IDiscountStrategy)
  public
    function ApplyDiscount(Amount: Double): Double;
    function GetName: string;
  end;

  TCouponDiscount = class(TInterfacedObject, IDiscountStrategy)
  public
    function ApplyDiscount(Amount: Double): Double;
    function GetName: string;
  end;

  TPriceCalculator = class
  private
    FDiscounts: IList<IDiscountStrategy>;
  public
    constructor Create(const Discounts: IList<IDiscountStrategy>);
    function CalculateFinalPrice(BasePrice: Double): Double;
  end;

{ TVIPDiscount }
function TVIPDiscount.ApplyDiscount(Amount: Double): Double;
begin
  Result := Amount * 0.9;
end;

function TVIPDiscount.GetName: string;
begin
  Result := 'Descuento VIP (10%)';
end;

{ TSeasonalDiscount }
function TSeasonalDiscount.ApplyDiscount(Amount: Double): Double;
begin
  if Amount > 10 then
    Result := Amount - 5
  else
    Result := Amount;
end;

function TSeasonalDiscount.GetName: string;
begin
  Result := 'Descuento Temporada (5€)';
end;

{ TCouponDiscount }
function TCouponDiscount.ApplyDiscount(Amount: Double): Double;
begin
  Result := Amount * 0.95;
end;

function TCouponDiscount.GetName: string;
begin
  Result := 'Descuento Cupón (5%)';
end;

{ TPriceCalculator }
constructor TPriceCalculator.Create(const Discounts: IList<IDiscountStrategy>);
begin
  FDiscounts := Discounts;
end;

function TPriceCalculator.CalculateFinalPrice(BasePrice: Double): Double;
var
  descuento: IDiscountStrategy;
  precioAnterior: Double;
begin
  Result := BasePrice;
  Writeln(Format('Precio base: %.2f€', [BasePrice]));
  Writeln;

  for descuento in FDiscounts do
  begin
    precioAnterior := Result;
    Result := descuento.ApplyDiscount(Result);
    Writeln(Format('  %s: %.2f€ -> %.2f€',
      [descuento.GetName, precioAnterior, Result]));
  end;

  Writeln;
  Writeln(Format('AHORRO TOTAL: %.2f€ (%.1f%%)',
    [BasePrice - Result, ((BasePrice - Result) / BasePrice) * 100]));
end;

var
  dPrice: Double;
  calculator: TPriceCalculator;
begin
  try
    Writeln('╔═══════════════════════════════════════════════════╗');
    Writeln('║     Sistema de Descuentos con Spring4D           ║');
    Writeln('╚═══════════════════════════════════════════════════╝');
    Writeln;

    // ══════════════════════════════════════════════════════════════
    // REGISTRO DE ESTRATEGIAS
    // Para añadir un descuento: añadir UNA línea aquí
    // ══════════════════════════════════════════════════════════════
    GlobalContainer.RegisterType<TVIPDiscount>.Implements<IDiscountStrategy>('VIP');
    GlobalContainer.RegisterType<TSeasonalDiscount>.Implements<IDiscountStrategy>('Seasonal');
    GlobalContainer.RegisterType<TCouponDiscount>.Implements<IDiscountStrategy>('Coupon');

    GlobalContainer.Build;

    // ══════════════════════════════════════════════════════════════
    // CREAR LISTA DE DESCUENTOS DESDE EL CONTENEDOR
    // Para añadir un descuento: añadir UNA línea aquí también
    // ══════════════════════════════════════════════════════════════
    var discounts := TCollections.CreateList<IDiscountStrategy>;
    discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('VIP'));
    discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('Seasonal'));
    discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('Coupon'));

    Writeln(Format('✓ %d descuentos cargados desde el contenedor', [discounts.Count]));
    Writeln;

    // Crear el calculador
    calculator := TPriceCalculator.Create(discounts);

    Writeln('Introduce el precio a cobrar:');
    Write('€ ');
    Readln(dPrice);
    Writeln;
    Writeln('═══════════════════════════════════════════════════');
    Writeln;

    var precioFinal := calculator.CalculateFinalPrice(dPrice);

    Writeln;
    Writeln('═══════════════════════════════════════════════════');
    Writeln(Format('PRECIO FINAL: %.2f€', [precioFinal]));
    Writeln('═══════════════════════════════════════════════════');
    Writeln;
    Writeln('Presiona ENTER para salir...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln;
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
      Writeln;
      Readln;
    end;
  end;
end.

(*
╔═══════════════════════════════════════════════════════════════════╗
║  LA VERDAD SOBRE SPRING4D Y LA INYECCIÓN DE COLECCIONES          ║
╚═══════════════════════════════════════════════════════════════════╝

LO QUE DICE EL LIBRO:
────────────────────────────────────────────────────────────────────
El libro "Coding in Delphi" describe que puedes usar [Inject] para
inyectar automáticamente colecciones de interfaces.

LO QUE FUNCIONA EN LA PRÁCTICA:
────────────────────────────────────────────────────────────────────
✓ [Inject] funciona para PARÁMETROS INDIVIDUALES
✓ InjectConstructor funciona para PARÁMETROS INDIVIDUALES
✗ [Inject] NO funciona para IList<T> o TArray<T> en muchas versiones
✗ ResolveAll<T> devuelve array vacío en muchas versiones
✗ No hay auto-discovery mágico de implementaciones

VERSIONES DE SPRING4D:
────────────────────────────────────────────────────────────────────
La inyección automática de colecciones es una característica que:
- Puede estar en versiones muy nuevas de Spring4D (2.0+)
- Puede no estar implementada completamente en versiones estables
- Puede tener bugs en ciertas configuraciones

TU CÓDIGO ORIGINAL ERA CORRECTO:
────────────────────────────────────────────────────────────────────
La forma en que lo tenías originalmente es la forma ESTÁNDAR y
CONFIABLE de trabajar con Spring4D en Delphi.

═══════════════════════════════════════════════════════════════════

LO QUE SÍ GANAS CON SPRING4D EN ESTE DISEÑO:
────────────────────────────────────────────────────────────────────
✓ Gestión del ciclo de vida (singletons, transient, pooled)
✓ Desacoplamiento (TPriceCalculator no conoce implementaciones)
✓ Las estrategias se crean solo cuando se necesitan
✓ Fácil cambiar entre implementaciones
✓ Testeable (puedes inyectar mocks)
✓ Configuración centralizada

═══════════════════════════════════════════════════════════════════

COMPARACIÓN: TU CÓDIGO vs SIN SPRING4D
────────────────────────────────────────────────────────────────────

SIN SPRING4D (acoplado):
  var calculator := TPriceCalculator.Create;
  // TPriceCalculator internamente hace:
  //   FDiscounts.Add(TVIPDiscount.Create);
  //   FDiscounts.Add(TSeasonalDiscount.Create);

CON SPRING4D (desacoplado):
  var discounts := TCollections.CreateList<IDiscountStrategy>;
  discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('VIP'));
  discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('Seasonal'));
  var calculator := TPriceCalculator.Create(discounts);
  // TPriceCalculator NO conoce las implementaciones concretas

═══════════════════════════════════════════════════════════════════

PARA AÑADIR UN NUEVO DESCUENTO:
────────────────────────────────────────────────────────────────────

1. Crear la clase:
   type
     TBlackFridayDiscount = class(TInterfacedObject, IDiscountStrategy)
       function ApplyDiscount(Amount: Double): Double;
       function GetName: string;
     end;

2. Implementar:
   function TBlackFridayDiscount.ApplyDiscount(Amount: Double): Double;
   begin
     Result := Amount * 0.5;
   end;

3. Añadir DOS líneas (registro y resolución):
   GlobalContainer.RegisterType<TBlackFridayDiscount>.Implements<IDiscountStrategy>('BlackFriday');
   discounts.Add(GlobalContainer.Resolve<IDiscountStrategy>('BlackFriday'));

NO es 100% automático, pero SIGUE SIENDO MEJOR que crear las
instancias manualmente dentro de TPriceCalculator.

╚═══════════════════════════════════════════════════════════════════╝
*)

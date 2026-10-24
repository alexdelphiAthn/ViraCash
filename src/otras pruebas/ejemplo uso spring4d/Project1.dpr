program Project1;

{$APPTYPE CONSOLE}
{$R *.res}
uses
  System.SysUtils,
  Spring.Collections,
  Spring;

type
  TProduct = class
  public
    Name: string;
    Category: string;
    Price: Double;
    InStock: Integer;
    constructor Create(const AName, ACategory: string; APrice: Double; AInStock: Integer);
  end;

{ TProduct }
constructor TProduct.Create(const AName, ACategory: string; APrice: Double;
  AInStock: Integer);
begin
  Name := AName;
  Category := ACategory;
  Price := APrice;
  InStock := AInStock;
end;

procedure ver(Lista : IEnumerable<TProduct>);
begin
  for var pProd in Lista  do
  begin
    Writeln('-----------------');
    writeln('Nombre producto: ' + pProd.Name);
    writeln('Categoría producto: ' + pprod.Category);
    Writeln('Precio producto: ' + CurrToStr(pprod.price));
    Writeln('Stock producto: ' + IntToStr(pProd.InStock));
    Writeln('-----------------');
  end;
  Readln;
end;

var
  Products : IList<TProduct>;

begin
  try
    //Writeln();
    Products := TCollections.CreateObjectList<TProduct>(true);
    (*Cargar los datos*)
    Products.AddRange([
      TProduct.Create('artilugio', 'cacharro', 192.43, 3),
      TProduct.Create('cacharro', 'electrónica', 13.65, 10),
      TProduct.Create('pongo', 'cacharro', 52.22, 0),
      TProduct.Create('cosa', 'electrónica', 11.33, 5),
      TProduct.Create('trasto', 'cacharro', 43.44, 1)
    ]);
    Writeln('PRODUCTOS EN ALMACÉN');
    ver(Products);
    (*Filtrar: Productos con precio superior a 50.00*)
    Writeln('PRODUCTOS CAROS (precio > 50)');
    var Caros := (Products.Where(
      function (const P:TProduct):boolean
      begin
        Result := (P.Price > 50);
      end));
    ver(Caros);
    (*Proyectar: Lista con nombres de productos de categoría "Electrónica"*)
    Writeln('NOMBRES DE PRODUCTOS DE ELECTRÓNICA:');
    Writeln('------------------------------------');
    var Nombres := Products
        .Where(function(const P: TProduct): Boolean
               begin
                 Result := P.Category = 'electrónica';
               end);
    Nombres.ForEach(procedure(const n:TProduct)
    begin
      Writeln('• ' + n.Name);
    end);
    Writeln('Total productos de electrónica: ' + Nombres.Count.ToString);
    Readln;
    (*Ejercicio 3. Sumar todos los stocks y dar la cifra de inventario*)
    var cTotal := TEnumerable.Select<TProduct, currency>(
      Products,
      function(const P: TProduct): currency
      begin
        Result := p.Price * p.InStock;
      end).Sum; // Luego sumamos todos esos subtotales
    Writeln('Total valoración de stock: ' + CurrToStr(cTotal));
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

(*// Range: Secuencia de números
var Numeros := TEnumerable.Range(1, 10);  // 1, 2, 3...10
// Repeat: Repetir un valor
var Repetidos := TEnumerable.Repeat<string>('Hola', 5);  // "Hola" 5 veces
// Empty: Colección vacía
var Vacio := TEnumerable.Empty<TProduct>;
// Concat: Concatenar dos colecciones
var Todos := TEnumerable.Concat<TProduct>(Lista1, Lista2);
// Distinct: Elementos únicos
var Unicos := TEnumerable.Distinct<string>(ListaConDuplicados);
// OrderBy: Ordenar
var Ordenados := TEnumerable.OrderBy<TProduct, Double>(
  Products,
  function(const P: TProduct): Double
  begin
    Result := P.Price;
  end);*)

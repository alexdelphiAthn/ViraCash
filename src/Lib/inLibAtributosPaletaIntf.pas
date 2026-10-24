unit inLibAtributosPaletaIntf;

interface

uses
  System.Generics.Collections, Vcl.Graphics, Uni;

type
  TInfoBasico = record
    HexColor: string;
    Color: TColor;
    Nombre: string;
    EsValido: Boolean;
  end;
  TEntradaCacheBasico = record
    IdVariacion: string;
    Codigo: string;
    Nombre: string;
    Valor: string;
    Descripcion: string;
    Info: TInfoBasico;
  end;
  TValorPaletaArticulo = record
    Valor: string;
    Info: TInfoBasico;
  end;
  ILecturasAtributosPaleta = interface
    ['{B3D88735-FB3D-4C05-8BCA-214853E24B62}']
    function ListarEntradasCache(
      AConexion: TUniConnection): TArray<TEntradaCacheBasico>;
    function ObtenerBasicosArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<string>;
    procedure CargarMapaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo: string;
      ADestino: TDictionary<string, string>);
    procedure CargarMapaGlobal(AConexion: TUniConnection;
      ADestino: TDictionary<string, string>);
    function ListarPaletaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<TValorPaletaArticulo>;
    function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
      const ACodigoArticulo, AIdVariacion, AValor: string;
      out AInfo: TInfoBasico): Boolean;
  end;
  ISelectorAtributoPaleta = interface
    ['{52F4CC49-16B9-4D3E-B858-25E565786B5E}']
    function Seleccionar(
      AConexion: TUniConnection;
      const ALecturas: ILecturasAtributosPaleta;
      const AIdVariacion: string;
      const AValores: array of string;
      const AValorActual: string;
      out AValor: string;
      AScreenLeft, AScreenTop, AWidthHint: Integer;
      const ACodigoArticulo: string): Boolean;
  end;

implementation

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosAtributosBasicosIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de gestión y persistencia de atributos básicos de los SKU.      }
{******************************************************************************}
unit inLibArticulosAtributosBasicosIntf;

interface

type
  TAmbitoAtributoBasico = (
    aabGlobal,
    aabAdHoc
  );

  TEnteroOpcional = record
    TieneValor: Boolean;
    Valor: Integer;
  end;

  TRealOpcional = record
    TieneValor: Boolean;
    Valor: Double;
  end;

  TCadenaOpcional = record
    TieneValor: Boolean;
    Valor: string;
  end;

  TContextoAtributoBasicoSku = record
    CodigoArticulo: string;
    CodigoSku: string;
    IdVariacion: string;
    ValorAtributo: string;
    IdValor: Integer;
    Usuario: string;
  end;

  IRepositorioAtributosBasicosSku = interface
    ['{0C01BE81-72E0-4D27-A340-885661B65DCA}']
    function BuscarCodigoActivo(
      const AIdVariacion, ATexto: string;
      out ACodigo: string): Boolean;
    function AsegurarValorSku(
      const ACodigoSku, AIdVariacion, AValor,
      AUsuario: string): Integer;
    function AsegurarAtributoBasico(
      const AIdVariacion, ACodigo, ANombre,
      AUsuario: string): Integer;
    procedure GuardarOverride(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const AUsuario: string);
    procedure ActualizarNombre(
      AIdBasico: Integer;
      const ANombre, AUsuario: string);
    procedure ActualizarValorNumerico(
      AIdBasico: Integer;
      const AValor: TRealOpcional;
      const AUsuario: string);
    procedure ActualizarUnidad(
      AIdBasico: Integer;
      const AUnidad, AUsuario: string);
    procedure GuardarDescripcion(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const ADescripcion: TCadenaOpcional;
      const AUsuario: string);
    procedure ActualizarHex(
      AIdBasico: Integer;
      const AHex, AUsuario: string);
  end;

  IGestorAtributosBasicosSku = interface
    ['{3412523B-748C-4050-A5C6-F087D49C997F}']
    function BuscarCodigoActivo(
      const AIdVariacion, ATexto: string;
      out ACodigo: string): Boolean;
    function CrearAtributoBasico(
      const AContexto: TContextoAtributoBasicoSku;
      const ANombre: string;
      AAmbito: TAmbitoAtributoBasico): string;
    function AsegurarValorSku(
      const AContexto: TContextoAtributoBasicoSku): Integer;
    function AsegurarBasico(
      const AContexto: TContextoAtributoBasicoSku;
      AAmbito: TAmbitoAtributoBasico): Integer;
    procedure GuardarOverride(
      const AContexto: TContextoAtributoBasicoSku;
      const AIdBasico: TEnteroOpcional);
    procedure ActualizarNombre(
      AIdBasico: Integer;
      const ANombre, AUsuario: string);
    procedure ActualizarValorNumerico(
      AIdBasico: Integer;
      const AValor: TRealOpcional;
      const AUsuario: string);
    procedure ActualizarUnidad(
      AIdBasico: Integer;
      const AUnidad, AUsuario: string);
    procedure GuardarDescripcion(
      const AContexto: TContextoAtributoBasicoSku;
      const AIdBasico: TEnteroOpcional;
      const ADescripcion: TCadenaOpcional);
    procedure ActualizarHex(
      AIdBasico: Integer;
      const AHex, AUsuario: string);
  end;

function EnteroConValor(AValor: Integer): TEnteroOpcional;
function EnteroNulo: TEnteroOpcional;
function RealConValor(AValor: Double): TRealOpcional;
function RealNulo: TRealOpcional;
function CadenaConValor(const AValor: string): TCadenaOpcional;
function CadenaNula: TCadenaOpcional;

implementation

function EnteroConValor(AValor: Integer): TEnteroOpcional;
begin
  Result.TieneValor := True;
  Result.Valor := AValor;
end;

function EnteroNulo: TEnteroOpcional;
begin
  Result := Default(TEnteroOpcional);
end;

function RealConValor(AValor: Double): TRealOpcional;
begin
  Result.TieneValor := True;
  Result.Valor := AValor;
end;

function RealNulo: TRealOpcional;
begin
  Result := Default(TRealOpcional);
end;

function CadenaConValor(const AValor: string): TCadenaOpcional;
begin
  Result.TieneValor := True;
  Result.Valor := AValor;
end;

function CadenaNula: TCadenaOpcional;
begin
  Result := Default(TCadenaOpcional);
end;

end.

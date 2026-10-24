{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompraPersistenciaIntf                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del pivote de documentos de compra.                }
{******************************************************************************}
unit inLibGridPivoteCompraPersistenciaIntf;

interface

uses
  Data.DB;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IConfiguracionGridPivoteCompra = interface
    ['{74BE05D2-B990-46BD-B796-BD73CA1264EA}']
    procedure Configurar(
      const ATablaLineas, ACampoSerie, ACampoNumero, ACampoLinea,
        ACampoArticulo, ACampoSku, ACampoCantidad,
        ACampoCantidadRecibida, ACampoIdConjunto, ACampoAlmacen,
        ACampoColorTexto: string;
      AMaximoColumnas: Integer);
  end;
  IRepositorioColoresPivoteCompra = interface
    ['{EB069B21-D296-40A0-A738-49055F646E96}']
    function BuscarColorBasico(
      const ACodigo: string;
      out AIdBasico: Integer;
      out ANombre: string;
      const AVariacion: string = 'TC'): Boolean;
    function BuscarValorColor(
      const AValor: string;
      out AIdValor: Integer;
      out ATieneBasico: Boolean;
      const AVariacion: string = 'TC'): Boolean;
    procedure VincularValorColor(
      AIdValor, AIdBasico: Integer;
      const AUsuario: string);
    function InsertarValorColor(
      const AValor, ADescripcion, AUsuario: string;
      AIdBasico: Integer;
      const AVariacion: string = 'TC'): Integer;
  end;
  IRepositorioValidacionPivoteCompra = interface
    ['{3C0BF26B-6DD3-40A2-9210-2B6A895839C4}']
    function BuscarArticulosSinSistema(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSistemasConExceso(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSkusFueraSistema(
      const ASerie, ANumero: string): TDataSet;
  end;
  IRepositorioLineasPivoteCompra = interface
    ['{3B151CF3-A165-4CC1-8A18-48D74F25B1FA}']
    function BuscarLineasPivote(
      const ASerie, ANumero: string): TDataSet;
  end;
  IRepositorioSkusPivoteCompra = interface
    ['{826305E6-26B4-4F76-B26E-3F122470C1C6}']
    // SKU activo con esa talla, ese color (si > 0) y ese valor de
    // pestañas (si > 0). Con varios candidatos de un tipo con pestañas
    // lanza ESkuAmbiguo (inLibResolucionSku); '' si no hay ninguno.
    function BuscarSku(
      const ACodigoArticulo: string;
      AIdTalla, AIdColor, AIdPestana: Integer): string;
    function BuscarValorAtributo(AIdValor: Integer): string;
    // Valor de pestañas (copa) del SKU; 0 si no tiene.
    function IdValorPestanaSku(const ACodigoSku: string): Integer;
    // Con un tipo con pestañas exige AIdPestana > 0 (ESkuSinValorPestana).
    procedure AsegurarSkuConAtributos(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor, AIdTalla, AIdPestana: Integer);
    function BuscarTipoVariacion(
      const ACodigoArticulo: string): string;
    procedure AsegurarSkuColor(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor: Integer);
  end;
  TRepositoriosGridPivoteCompra = record
    Configuracion: IConfiguracionGridPivoteCompra;
    Colores: IRepositorioColoresPivoteCompra;
    Validacion: IRepositorioValidacionPivoteCompra;
    Lineas: IRepositorioLineasPivoteCompra;
    Skus: IRepositorioSkusPivoteCompra;
  end;
implementation
end.

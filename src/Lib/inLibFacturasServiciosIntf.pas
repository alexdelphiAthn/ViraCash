{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasServiciosIntf                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de validación y operaciones desacopladas de facturas de venta.  }
{******************************************************************************}
unit inLibFacturasServiciosIntf;

interface

uses
  System.SysUtils, Data.DB,
  inLibArticulosResolverIntf;

type
  TCampoValidacionFac = (
    cvfNinguno,
    cvfSerie,
    cvfRazonSocialCliente,
    cvfRazonSocialEmpresa,
    cvfPais,
    cvfFecha,
    cvfNifCliente,
    cvfNifEmpresa,
    cvfOperacionFiscal,
    cvfTipoIva);
  TResultadoOperacionFactura = record
    FormatoDocumento: string;
    Exito: Boolean;
    Mensaje: string;
    class function Correcto: TResultadoOperacionFactura; static;
    class function Error(
      const AMensaje: string): TResultadoOperacionFactura; static;
  end;
  TResultadoBorradoFactura = record
    Permitido: Boolean;
    Mensaje: string;
    class function Permitir: TResultadoBorradoFactura; static;
    class function Denegar(
      const AMensaje: string): TResultadoBorradoFactura; static;
  end;
  EValidacionFactura = class(EDatabaseError)
  private
    FCampo: TCampoValidacionFac;
  public
    constructor Create(
      const AMensaje: string;
      ACampo: TCampoValidacionFac); reintroduce;
    property Campo: TCampoValidacionFac read FCampo;
  end;
  TResultadoOperacionFacturaEvent = procedure(
    const AResultado: TResultadoOperacionFactura) of object;
  TResultadoBorradoFacturaEvent = procedure(
    const AResultado: TResultadoBorradoFactura) of object;
  TAdvertenciaFacturaEvent = procedure(
    const AMensaje: string) of object;
  TValidacionFacturaEvent = procedure(
    const AError: EValidacionFactura) of object;
  TConfirmarBorradoFacturaEvent = function(
    const ASerie, ANumero: string): Boolean of object;
  TOperacionFiscalFactura = record
    Ambito: string;
    RepercuteIva: Boolean;
  end;
  TSolicitudValidacionFiscalFactura = record
    TipoOperacion: string;
    CodigoPaisCliente: string;
    NifCliente: string;
    TotalImpuestos: Currency;
  end;
  TSolicitudClienteFactura = record
    Codigo: string;
    RazonSocial: string;
    Nif: string;
    Movil: string;
    Email: string;
    Direccion1: string;
    Direccion2: string;
    Poblacion: string;
    Provincia: string;
    CodigoPostal: string;
    NombrePais: string;
    CodigoPais: string;
    EsIntracomunitario: string;
    EsIvaExento: string;
    EsRetenciones: string;
    EsIvaRecargo: string;
    EsRegimenEspecialAgricola: string;
    TarifaArticulo: string;
    Usuario: string;
  end;
  TSolicitudEmpresaFactura = record
    Codigo: string;
    RazonSocial: string;
    Nif: string;
    Movil: string;
    Email: string;
    Direccion1: string;
    Direccion2: string;
    Poblacion: string;
    Provincia: string;
    CodigoPostal: string;
    NombrePais: string;
    CodigoPais: string;
    EsRetenciones: string;
    EsIvaRecargo: string;
    EsRegimenEspecialAgricola: string;
    GrupoZonaIva: string;
    Usuario: string;
  end;
  IRepositorioFacturas = interface
    ['{748A48DF-2A59-460B-856F-C9DE43B74610}']
    function ExisteSerieOtraEmpresa(
      const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
    function EsPaisUE(const ACodigoPais: string): Boolean;
    function ObtenerOperacionFiscal(
      const ACodigo: string;
      out AOperacion: TOperacionFiscalFactura): Boolean;
    function UltimaFechaSerie(
      const ASerie, AEmpresa, ANumero: string): TDateTime;
    function HayHuecoNumeracion(
      const ASerie, AEmpresa, ANumero: string): Boolean;
    procedure GuardarCliente(
      const ASolicitud: TSolicitudClienteFactura);
    procedure GuardarEmpresa(
      const ASolicitud: TSolicitudEmpresaFactura);
  end;
  IValidadorFiscalFactura = interface
    ['{D50746A1-8404-4EB8-93E3-3581AA88C70C}']
    procedure Validar(
      const ASolicitud: TSolicitudValidacionFiscalFactura);
  end;
  ICalculadorFactura = interface
    ['{F46FD8F3-17D1-4B2B-8A02-EFEF44116281}']
    function Calcular(
      ACabecera, ALineas: TDataSet;
      APermiteRecalcular: Boolean): TResultadoOperacionFactura;
  end;
  IServicioBorradoFactura = interface
    ['{35C1550C-F905-4185-BCCB-6B63C81A51A1}']
    function Validar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    function Preparar(
      const ASerie, ANumero, AFase: string;
      const AUsuario: string = ''
    ): TResultadoBorradoFactura;
    procedure Confirmar;
    procedure Revertir;
  end;
  IServicioEfectosFactura = interface
    ['{F015E26D-5792-46B1-917A-C2B3EE4957F5}']
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
  end;
  TSolicitudMovimientosFactura = record
    Serie: string;
    Numero: string;
    Empresa: string;
    Cliente: string;
    Caja: string;
    NumeroOperacion: string;
    // Cero conserva el instante de alta asignado por el servidor.
    Fecha: TDateTime;
    Usuario: string;
  end;
  IServicioMovimientosFactura = interface
    ['{A73BE906-C8F3-412D-9CA6-27CF126A1282}']
    function GenerarSalidas(
      const ASolicitud: TSolicitudMovimientosFactura): Integer;
  end;
  TResultadoConsolidacionFactura = record
    MensajeFiscal: string;
    MovimientosGenerados: Integer;
    // FZ-ISSUE-358: factura recibida grabada en la empresa destino (o por
    // qué no se pudo); vacío si la factura no es interna.
    MensajeRecibida: string;
  end;
  // FZ-ISSUE-358: tras consolidar una factura interna (cliente de traspasos
  // de otra empresa), graba la recibida en la destino. Devuelve el aviso
  // para el usuario, vacío si la factura no es interna.
  IServicioFacturaRecibidaInterna = interface
    ['{6F0B7C42-3A1D-4E58-9C2B-58E3B0A7D911}']
    function Registrar(const ASerie, ANumero, AUsuario: string): string;
  end;
  EConsolidacionFactura = class(Exception);
  EReaperturaBorrador = class(Exception);
  ICasoUsoConsolidacionFactura = interface
    ['{754DE5B5-EC92-467B-960B-8A26BD1DEB90}']
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    function Consolidar(
      const ASerie, ANumero, AUsuario: string
    ): TResultadoConsolidacionFactura;
  end;
  IServicioReaperturaBorrador = interface
    ['{0DD45285-573E-4ECA-A983-B12571EDDEB4}']
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    procedure Reabrir(
      const ASerie, ANumero, AUsuario: string);
  end;
  // Crea el servicio de borrado sobre la conexión de la ventana, la misma
  // por la que el dataset borra la cabecera (FZ-ISSUE-151).
  TFabricaServicioBorradoFactura = reference to function(
    AConexion: TCustomConnection): IServicioBorradoFactura;
  TServiciosFactura = record
    Repositorio: IRepositorioFacturas;
    ArticulosResolver: IArticulosResolver;
    ValidadorFiscal: IValidadorFiscalFactura;
    Calculador: ICalculadorFactura;
    Borrado: IServicioBorradoFactura;
    CrearBorrado: TFabricaServicioBorradoFactura;
    Efectos: IServicioEfectosFactura;
  end;

function EvaluarBorradoFactura(
  const AFase: string;
  ATieneEfectosCobrados: Boolean
): TResultadoBorradoFactura;
function EvaluarConsolidacionFactura(
  const ASerie, ANumero, AFase, ATipoFactura,
  ANifCliente: string;
  ANumeroLineas: Integer;
  const AFormatoDocumento: string = ''
): TResultadoOperacionFactura;
function FacturaDebeGenerarMovimientos(
  const ATipoFactura: string;
  AMueveStock: Boolean
): Boolean;
function EvaluarReaperturaBorrador(
  const ASerie, ANumero, AFase, AEstadoCola: string;
  AConsolidada: Boolean;
  const AFormatoDocumento: string = ''
): TResultadoOperacionFactura;

implementation

uses
  inLibFormatoDocumento,
  inLibMsgFacturas;

class function TResultadoOperacionFactura.Correcto:
  TResultadoOperacionFactura;
begin
  Result.FormatoDocumento := '';
  Result.Exito := True;
  Result.Mensaje := '';
end;

class function TResultadoOperacionFactura.Error(
  const AMensaje: string): TResultadoOperacionFactura;
begin
  Result.FormatoDocumento := '';
  Result.Exito := False;
  Result.Mensaje := AMensaje;
end;

class function TResultadoBorradoFactura.Permitir:
  TResultadoBorradoFactura;
begin
  Result.Permitido := True;
  Result.Mensaje := '';
end;

class function TResultadoBorradoFactura.Denegar(
  const AMensaje: string): TResultadoBorradoFactura;
begin
  Result.Permitido := False;
  Result.Mensaje := AMensaje;
end;

constructor EValidacionFactura.Create(
  const AMensaje: string;
  ACampo: TCampoValidacionFac);
begin
  inherited Create(AMensaje);
  FCampo := ACampo;
end;

function EvaluarBorradoFactura(
  const AFase: string;
  ATieneEfectosCobrados: Boolean
): TResultadoBorradoFactura;
begin
  if (Trim(AFase) <> '') and
     (not SameText(AFase, 'BORRADOR')) then
  begin
    Result := TResultadoBorradoFactura.Denegar(
      Format(SErrorBorrarBorradorFase, [AFase]));
  end
  else if ATieneEfectosCobrados then
  begin
    Result := TResultadoBorradoFactura.Denegar(
      SErrorBorrarBorradorEfectosCobrados);
  end
  else
  begin
    Result := TResultadoBorradoFactura.Permitir;
  end;
end;

function EvaluarConsolidacionFactura(
  const ASerie, ANumero, AFase, ATipoFactura,
  ANifCliente: string;
  ANumeroLineas: Integer;
  const AFormatoDocumento: string
): TResultadoOperacionFactura;
begin
  if (Trim(AFase) <> '') and
     (not SameText(AFase, 'BORRADOR')) then
  begin
    Result := TResultadoOperacionFactura.Error(
      FormatearMensajeDocumentos(
        AFormatoDocumento,
        SErrorBorradorYaLanzadoFiscalmente,
        [ASerie, ANumero, AFase]));
  end
  else if ANumeroLineas = 0 then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorSinLineasLanzar);
  end
  else if SameText(ATipoFactura, 'NORMAL') and
          (Trim(ANifCliente) = '') then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorNormalSinNif);
  end
  else
  begin
    Result := TResultadoOperacionFactura.Correcto;
  end;
  Result.FormatoDocumento := AFormatoDocumento;
end;

function FacturaDebeGenerarMovimientos(
  const ATipoFactura: string;
  AMueveStock: Boolean
): Boolean;
begin
  // La rectificativa mueve stock cuando el usuario lo solicita;
  // el signo de cada línea distingue ventas y devoluciones.
  Result := SameText(ATipoFactura, 'SIMPLIFICADA') or
    ((SameText(ATipoFactura, 'NORMAL') or
      SameText(ATipoFactura, 'RECTIFICATIVA')) and AMueveStock);
end;

function EvaluarReaperturaBorrador(
  const ASerie, ANumero, AFase, AEstadoCola: string;
  AConsolidada: Boolean;
  const AFormatoDocumento: string
): TResultadoOperacionFactura;
begin
  if AConsolidada then
  begin
    Result := TResultadoOperacionFactura.Error(
      FormatearMensajeDocumentos(
        AFormatoDocumento,
        SErrorBorradorConsolidadoNoReabrible,
        [ASerie, ANumero]));
  end
  else if (Trim(AFase) = '') or SameText(AFase, 'BORRADOR') then
  begin
    Result := TResultadoOperacionFactura.Error(
      SInfoBorradorYaEnBorrador);
  end
  else if SameText(AEstadoCola, 'ENVIADA') then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorAltaAeatAceptadaNoReabrible);
  end
  else if SameText(AEstadoCola, 'PROCESANDO') then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorEnProcesoNoReabrible);
  end
  else
  begin
    Result := TResultadoOperacionFactura.Correcto;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturas                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lógica de cálculo y persistencia de facturas.                             }
{    Totales de IVA, recargo de equivalencia y generación de líneas.           }
{******************************************************************************}
unit inLibFacturas;

interface

uses
  Uni, System.StrUtils, System.SysUtils, System.Classes, Data.DB, System.Math,
  Datasnap.DBClient, Datasnap.Provider, inLibMotorFiscalVenta,
  inLibFacturasLecturasIntf, inLibLogIntf;

const
  fnrofaclin = 'NUMERO_FAC_FACLIN';
  fserielin = 'SERIE_FAC_FACLIN';
  fnrolin = 'LINEA_FACLIN';
  fescon = 'ESCONSOLIDADA_FAC';
  fcodart = 'CODIGO_ART_FACLIN';
  fdesart = 'DESCRIPCION_ARTICULO_FACLIN';
  fcodprov = 'CODIGO_PRV_FACLIN';
  frazprov = 'RAZON_SOCIAL_PROVEEDOR_FACLIN';
  fpprov = 'ESPROVEEDORPRINCIPAL_FACLIN';
  fcodfam = 'CODIGO_FAM_FACLIN';
  fnomfam = 'NOMBRE_FAM_FACLIN';
  ffechentr = 'FECHA_ENTREGA_FACLIN';
  ftipocant = 'TIPO_CANTIDAD_ARTICULO_FACLIN';
  fimpcl = 'ESIMP_INCL_TARIFA_FACLIN';
  ftipiva = 'TIPO_IVA_ARTICULO_FACLIN';
  fdescripcion = 'DESCRIPCION_ARTICULO_FACLIN';
  fcodtariflin = 'CODIGO_TAR_FACLIN';
  fcant = 'CANTIDAD_FACLIN';
  fpreciosal = 'PRECIO_SALIDA_FACLIN';
  fprecultc = 'PRECIO_ULT_COMPRA_FACLIN';
  fpordto = 'PORCENTAJE_DTO_FACLIN';
  fdto = 'PRECIO_DTO_FACLIN';
  fpresiva = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN';
  fporiva = 'PORCENTAJE_IVA_FACLIN';
  fpreciva = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN';
  ftotciva = 'TOTAL_FACLIN';
  ftotsiva = 'TOTAL_FAC_SIVA_FACLIN';

  ffechfac = 'FECHA_FAC';
  fnrofac = 'NUMERO_FAC';
  fseriefac = 'SERIE_FAC';
  ftipofac = 'TIPO_FAC';
  ffasefac = 'FASE_FAC';
  fcodemp = 'CODIGO_EMP_FAC';
  fcodcli = 'CODIGO_CLI_FAC';
  factfij = 'ESVENTA_ACTIVO_FIJO_FAC';
  fporivan = 'PORCENTAJE_IVAN_FAC';
  ftotivan = 'TOTAL_IVAN_FAC';
  fporren = 'PORCENTAJE_REN_FAC';
  ftotren = 'TOTAL_REN_FAC';
  ftotbasen = 'TOTAL_BASEI_IVAN_FAC';
  fporivar = 'PORCENTAJE_IVAR_FAC';
  ftotivar = 'TOTAL_IVAR_FAC';
  fporrer = 'PORCENTAJE_RER_FAC';
  ftotrer = 'TOTAL_RER_FAC';
  ftotbaser = 'TOTAL_BASEI_IVAR_FAC';
  fporivas = 'PORCENTAJE_IVAS_FAC';
  ftotivas = 'TOTAL_IVAS_FAC';
  fporres = 'PORCENTAJE_RES_FAC';
  ftotres = 'TOTAL_RES_FAC';
  ftotbases = 'TOTAL_BASEI_IVAS_FAC';
  fporivae = 'PORCENTAJE_IVAE_FAC';
  ftotivae = 'TOTAL_IVAE_FAC';
  fporree = 'PORCENTAJE_REE_FAC';
  ftotree = 'TOTAL_REE_FAC';
  ftotbasee = 'TOTAL_BASEI_IVAE_FAC';
  ftotallifac = 'TOTAL_LIQUIDO_FAC';
  fporirpf = 'PORCENTAJE_RETENCION_FAC';
  ftotirpf = 'TOTAL_RETENCION_FAC';
  ftotimp = 'TOTAL_IMPUESTOS_FAC';
  ftotbasefac = 'TOTAL_BASES_FAC';

type
  TActualizarTotalFacturaEvent = procedure(Sender: TObject;
    ANuevoTotal: Currency) of object;
  TTipoIVA = (tivaNormal, tivaReducido, tivaSuperReducido, tivaExento);

  TTotalesIVA = record
    BaseImponible: Currency;
    PorcentajeIVA: Currency;
    ImporteIVA: Currency;
    PorcentajeRE: Currency;
    ImporteRE: Currency;
  end;

  TTotalesFactura = record
    BaseNormal,
    BaseReducida,
    BaseSuper,
    BaseExenta: Currency;
    CuotaIVANormal,
    CuotaIVAReducida,
    CuotaIVASuper,
    CuotaIVAExenta: Currency;
    CuotaRENormal,
    CuotaREReducida,
    CuotaRESuper,
    CuotaREExenta: Currency;
    TotalBases: Currency;
    TotalImpuestos: Currency;
    TotalRetencion: Currency;
    TotalLiquido: Currency;
    TotalIVANormal: Currency;
    TotalIVAReducido: Currency;
    TotalIVASuperReducido: Currency;
    TotalIVAExento: Currency;
    TotalREcargo: Currency;
    TotalCantidades:Currency;
    IVAN: TTotalesIVA;
    IVAR: TTotalesIVA;
    IVAS: TTotalesIVA;
    IVAE: TTotalesIVA;

    TotalBruto: Currency;
    TotalDescuentosLineas: Currency;
  end;

  TConfiguracionFactura = record
    EsFacturaSimplificada: Boolean;
    EsRegimenAgricolaEmpresa: Boolean;
    EsRegimenAgricolaCliente: Boolean;
    EsIntracomunitario: Boolean;
    EsVentaActivoFijo: Boolean;
    AplicaRecargo: Boolean;
    AplicaRetencionesCliente: Boolean;
    AplicaRetencionesEmpresa: Boolean;
    IVAExento: Boolean;
    IRPFImpuestoIncluido: Boolean;
    IVARecargo: Boolean;
  end;

  TPorcentajesImpuestos = record
    IVANormal: Currency;
    IVAReducido: Currency;
    IVASuperReducido: Currency;
    IVAExento: Currency;
    REcNormal: Currency;
    REcReducido: Currency;
    REcSuperReducido: Currency;
    REcExento: Currency;
  end;

  TFacturaTotales = class;

  TAlcanceRecalculoFactura = (
    arfSoloLinea,
    arfLineaYDocumento);

  TLinFac = class
  private
    _unqryLin: TDataset;
    _unqryFac: TDataset;
    _sImpcl: string;
    _sTipIva: string;
    _sNumLin: String;
    _dPrecioSal: currency;
    _dPorDto: currency;
    _dDto: currency;
    _dPreSiva: currency;
    _dPreCiva: currency;
    _dPoriva: currency;
    _dCant: currency;
    _dTotCiva: currency;
    _dTotSiva: currency;
    _dPorIvaN: currency;
    _dPorIvaR: currency;
    _dPorIvaS: currency;
    _dPorIvaE: currency;
    _sMensajeError: string;
    FCampoNumeroLinea: TField;
    FCampoCantidad: TField;
    FCampoImpuestosIncluidos: TField;
    FCampoTipoIva: TField;
    FCampoPorcentajeIva: TField;
    FCampoPrecioSalida: TField;
    FCampoPorcentajeDto: TField;
    FCampoPrecioDto: TField;
    FCampoPrecioSinIva: TField;
    FCampoPrecioConIva: TField;
    FCampoTotalConIva: TField;
    FCampoTotalSinIva: TField;
    function CampoCurrencyDistinto(
      ACampo: TField; AValor: Currency): Boolean;
    function CampoStringDistinto(
      ACampo: TField; const AValor: string): Boolean;
    function NecesitaActualizarDataSetLin: Boolean;
    procedure CachearCamposLinea;
    function GetPrecioSal: Currency;
    procedure SetPrecioSal(const Value: Currency);
    function GetPorDto: Currency;
    procedure SetPorDto(const Value: Currency);
    function GetDto: Currency;
    procedure SetDto(const Value: Currency);
    function GetPreSiva: Currency;
    procedure SetPreSiva(const Value: Currency);
    function GetPreCiva: Currency;
    procedure SetPreCiva(const Value: Currency);
    function GetCant: Currency;
    procedure SetCant(const Value: Currency);
    function GetPorIva: Currency;
    procedure SetPorIva(const Value: Currency);
    function GetTotCiva: Currency;
    procedure SetTotCiva(const Value: Currency);
    function GetTotSiva: Currency;
    procedure SetTotSiva(const Value: Currency);
    function GetImpcl: String;
    procedure SetImpcl(const Value: String);
    function GetTipoIVa: String;
    procedure SetTipoIva(const Value: String);
  public
    Property PrecioSal: Currency read GetPrecioSal write SetPrecioSal;
    Property PorDto: Currency read GetPorDto write SetPorDto;
    Property Dto: Currency read GetDto write SetDto;
    Property PorIva: Currency read GetPorIva write SetPorIva;
    Property TipoIva: String read GetTipoIVa write SetTipoIva;
    Property PreSiva: Currency read GetPreSiva write SetPreSiva;
    Property PreCiva: Currency read GetPreCiva write SetPreCiva;
    Property Cant: Currency read GetCant write SetCant;
    Property TotCiva: Currency read GetTotCiva write SetTotCiva;
    Property TotSiva: Currency read GetTotSiva write SetTotSiva;
    Property Impcl: String read GetImpcl write SetImpcl;
    Property MensajeError: String read _sMensajeError;
  public
    constructor Create(AUnqryLin: TDataset); overload;
    constructor Create(AUnqryLin, AUnqryFac: TDataset;
                       bCalcularFactura:boolean = false); overload;
    procedure CopyToDataSetLin;
    procedure CopyToDataSetFac;
    procedure CopyToObjectLin;
    procedure CopyToObjectFac;
    procedure SetInit(AUnqryLin: TDataset);
    procedure CalcularLinea;
    procedure RedondearTotalesACentimos;
    function ValidarDatos: Boolean;
    function EsDevolucion: Boolean;
  end;

  TFacturaTotales = class
  private
    _conexion: TUniConnection;
    _unqryFac: TDataset;
    _unqryLineas: TDataset;
    _totales: TTotalesFactura;
    _configuracion: TConfiguracionFactura;
    _porcentajes: TPorcentajesImpuestos;
    _dPorRetencion: Currency;
    _fechaFactura: TDateTime;
    _codigoEmpresa: string;
    _grupoZonaIVA: string;
    _codigoIVA: string;
    _mensajeError: string;
    FDtoComercial: Double;
    FDtoFinanciero: Double;
    _calculoOmitido: Boolean;
    _abortado: Boolean;
    _LineaenEdicion:TLinFac;
    _lineasMotorFiscal: TLineasMotorFiscalVenta;
    FRepositorioLecturas: IRepositorioLecturasFactura;
    FRegistroLog: IRegistroLog;
    function RepositorioLecturas: IRepositorioLecturasFactura;
    function LineaActualPendienteDeResolver: Boolean;
    function ClienteTieneDatosFiscales: Boolean;
    function CrearConfiguracionMotorFiscal:
      TConfiguracionMotorFiscalVenta;
    procedure InicializarTotales;
    procedure InicializarConfiguracion;
    procedure LeerDatosFactura;
    procedure LeerPorcentajesDesdeFactura;
    procedure AplicarReglas;
    procedure PrepararLineaCalculada(ALinea: TLinFac);
    procedure RecorrerYCalcularLineasConClientDataSet;
    procedure AcumularTotalesPorTipoIVA(
      ALinea: TLinFac; AIndice: Integer);
    procedure AplicarResultadoMotorFiscal(
      const AResultado: TResultadoMotorFiscalVenta);
    procedure CalcularTotalesGenerales;
    procedure ValidarConfiguracion;
    procedure VerificarYCompletarDatosEmpresa;
    procedure CargarConfiguracionIVA(sGrupoZona: string);
    procedure RestablecerPorcentajesZonaSiAnulados;
    procedure VerificarYCompletarDatosCliente;
    function ObtenerPorcentajePorTipo(tipo: string): Currency;
    function ObtenerPorcentajeREPorTipo(tipo: string): Currency;
    function BuscarPorcenRetencion(CodEmpresa: string): Currency;
    function BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
  public
    FTieneLineasNegativas:Boolean;
    constructor Create(AConexion: TUniConnection;
                       const ARepositorioLecturas:
                         IRepositorioLecturasFactura;
                       AUnqryFac: TDataset;
                       unqryLineas: TDataset;
                       LineaEnEdicion:TLinFac = nil;
                       const ARegistroLog: IRegistroLog = nil);
    function ProcesarFacturaCompleta: Boolean;
    procedure CalcularTotalesFactura;
    procedure ActualizarTotalesEnDataSet;
    function ValidarFactura: Boolean;
    property Totales: TTotalesFactura read _totales;
    property Configuracion: TConfiguracionFactura read _configuracion;
    property Porcentajes: TPorcentajesImpuestos read _porcentajes;
    property PorcentajeRetencion: Currency
      read _dPorRetencion write _dPorRetencion;
    property MensajeError: string read _mensajeError;
    // True si la línea en edición aún no está resuelta y no se calculó:
    // Totales no es válido y no debe mostrarse (quedaría a cero).
    property CalculoOmitido: Boolean read _calculoOmitido;
    // FZ-ISSUE-322: una validación ya avisó al usuario y abortó (EAbort)
    // en mitad del cálculo; no es un error que haya que mostrar.
    property Abortado: Boolean read _abortado;
    property Cabecera:TDataSet read _unqryFac;
    property Lineas:TDataset read _unqryLineas;
  end;
  function RecalcularLineaFactura(
    ALineas: TDataSet;
    ACabecera: TDataSet;
    const ACampo: string;
    const AValor: Variant): Boolean;
  procedure ActualizarLineaFactura(
    AConexion: TUniConnection;
    const ARepositorioLecturas: IRepositorioLecturasFactura;
    ALineas: TDataSet;
    ACabecera: TDataSet;
    const ACampo: string;
    const AValor: Variant;
    AAlActualizarTotal: TActualizarTotalFacturaEvent = nil);
  function IfThen(AValue: Boolean;
                 const ATrue: string;
                 AFalse: string = ''): string;
  procedure GuardarCambiosPendientesFactura(
    AConexion: TUniConnection;
    ACabecera, ALineas, ARecibos: TDataSet);
  function ArticuloFacturaDebeMostrarSku(
    const ARepositorioLecturas: IRepositorioLecturasFactura;
    const ACodigoArticulo: string): Boolean;
  function ContarLineasFactura(
    const ARepositorioLecturas: IRepositorioLecturasFactura;
    const ASerie, ANumero: string): Integer;


implementation

uses
  System.Variants,
  inLibRegistroLogNulo, inLibMsgFacturas, inLibCajaVentaOperacion,
  inLibRedondeo;

procedure PostearSiPendiente(ADataSet: TDataSet);
begin
  if Assigned(ADataSet) and ADataSet.Active and
     (ADataSet.State in [dsEdit, dsInsert]) then
  begin
    if (ADataSet.State = dsInsert) or ADataSet.Modified then
      ADataSet.Post
    else
      ADataSet.Cancel;
  end;
end;

procedure GuardarCambiosPendientesFactura(
  AConexion: TUniConnection;
  ACabecera, ALineas, ARecibos: TDataSet);
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    if Assigned(ACabecera) and
       (ACabecera.State = dsInsert) then
      PostearSiPendiente(ACabecera);
    PostearSiPendiente(ALineas);
    PostearSiPendiente(ARecibos);
    PostearSiPendiente(ACabecera);
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Commit;
  except
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

function ArticuloFacturaDebeMostrarSku(
  const ARepositorioLecturas: IRepositorioLecturasFactura;
  const ACodigoArticulo: string): Boolean;
begin
  Result := ARepositorioLecturas.ArticuloDebeMostrarSku(ACodigoArticulo);
end;

function ContarLineasFactura(
  const ARepositorioLecturas: IRepositorioLecturasFactura;
  const ASerie, ANumero: string): Integer;
begin
  Result := ARepositorioLecturas.ContarLineas(ASerie, ANumero);
end;

function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure AplicarTotalEditado(ALinea: TLinFac; ATotal: Currency);
var
  nDiferencia: Currency;
  nTotalBruto: Currency;
begin
  nTotalBruto := ALinea.PrecioSal * ALinea.Cant;
  if (nTotalBruto <> 0) and (ALinea.Cant <> 0) then
    nDiferencia := (nTotalBruto - ATotal) / ALinea.Cant
  else
    nDiferencia := 0;
  ALinea.Dto := nDiferencia;
end;

function RecalcularLineaFactura(
  ALineas: TDataSet;
  ACabecera: TDataSet;
  const ACampo: string;
  const AValor: Variant): Boolean;
var
  oLinea: TLinFac;
  nValor: Currency;
begin
  Result := Assigned(ALineas);
  if Result then
    Result := ALineas.Active and ALineas.CanModify;
  if Result then
  begin
    if not (ALineas.State in [dsEdit, dsInsert]) then
      ALineas.Edit;
    nValor := StrToCurrDef(VarToStr(AValor), 0);
    oLinea := TLinFac.Create(ALineas, ACabecera, True);
    try
      if SameText(ACampo, fpreciosal) then
        oLinea.PrecioSal := nValor
      else if SameText(ACampo, fcant) then
        oLinea.Cant := nValor
      else if SameText(ACampo, fpordto) then
        oLinea.PorDto := nValor
      else if SameText(ACampo, fdto) then
        oLinea.Dto := nValor
      else if SameText(ACampo, fpresiva) then
        oLinea.PreSiva := nValor
      else if SameText(ACampo, fpreciva) then
        oLinea.PreCiva := nValor
      else if SameText(ACampo, ftipiva) then
        oLinea.TipoIva := VarToStr(AValor)
      else if SameText(ACampo, ftotciva) or
              SameText(ACampo, ftotsiva) then
        AplicarTotalEditado(oLinea, nValor);
      oLinea.CopyToDataSetLin;
    finally
      FreeAndNil(oLinea);
    end;
  end;
end;

procedure ActualizarLineaFactura(
  AConexion: TUniConnection;
  const ARepositorioLecturas: IRepositorioLecturasFactura;
  ALineas: TDataSet;
  ACabecera: TDataSet;
  const ACampo: string;
  const AValor: Variant;
  AAlActualizarTotal: TActualizarTotalFacturaEvent);
var
  oTotales: TFacturaTotales;
begin
  if RecalcularLineaFactura(
       ALineas,
       ACabecera,
       ACampo,
       AValor) then
  begin
    oTotales := TFacturaTotales.Create(
      AConexion,
      ARepositorioLecturas,
      ACabecera,
      ALineas);
    try
      if not oTotales.ProcesarFacturaCompleta then
      begin
        if oTotales.Abortado then
          Abort;
        raise Exception.CreateFmt(
          SErrorRecalcularTotalesFactura,
          [oTotales.MensajeError]);
      end;
      // Sin cálculo el total quedaría a cero: se conserva el mostrado.
      if Assigned(AAlActualizarTotal) and not oTotales.CalculoOmitido then
      begin
        AAlActualizarTotal(
          nil,
          oTotales.Totales.TotalLiquido);
      end;
    finally
      FreeAndNil(oTotales);
    end;
  end;
end;

{ TLinFac - Implementación completa }

constructor TLinFac.Create(AUnqryLin: TDataset);
begin
  inherited Create;
  SetInit(AUnqryLin);
  Self.CopyToObjectLin;
end;

constructor TLinFac.Create(AUnqryLin, AUnqryFac: TDataset;
                           bCalcularFactura:boolean = false);
begin
  inherited Create;
  SetInit(AUnqryLin);
  _unqryFac := AUnqryFac;
  _sMensajeError := '';
  Self.CopyToObjectLin;
  Self.CopyToObjectFac;
end;

function TLinFac.ValidarDatos: Boolean;
begin
  Result := True;
  _sMensajeError := '';
  if (_dPorIva < 0) or (_dPorIva > 100) then
  begin
    _sMensajeError := SErrorPorcentajeIvaFueraRango;
    raise Exception.Create(_sMensajeError);
  end;
  if (_dPreSiva < 0) or (_dPreCiva < 0) then
  begin
    _sMensajeError := SErrorPrecioFacturaNegativo;
    raise Exception.Create(_sMensajeError);
  end;
end;

function TLinFac.EsDevolucion: Boolean;
begin
  Result := _dCant < 0;
end;

procedure TLinFac.CalcularLinea;
begin
  if not ValidarDatos then
    raise Exception.Create(_sMensajeError);
  if (SameText(_sImpcl, 'S')) then
  begin
    // Precio con IVA incluido
    if (_dPreCiva = 0) and (_dPrecioSal <> 0) then
    begin
      // Línea nueva: calcular precio desde PrecioSalida y descuento porcentual
      _dDto    := _dPrecioSal * (_dPorDto / 100);
      _dPreCiva := _dPrecioSal - _dDto;
    end
    else if (_dPrecioSal <> 0) then
    begin
      // Línea existente: recalcular descuento desde precio actual
      _dDto    := _dPrecioSal - _dPreCiva;
      _dPorDto := (_dDto / _dPrecioSal) * 100;
    end;
    if _dPorIva = 0 then
      _dPreSiva := _dPreCiva
    else
      _dPreSiva := _dPreCiva / (1 + _dPorIva / 100);
    _dTotSiva := _dPreSiva * _dCant;
    _dTotCiva := _dPreCiva * _dCant;
  end
  else
  begin
    // Precio sin IVA
    if (_dPreSiva = 0) and (_dPrecioSal <> 0) then
    begin
      _dDto    := _dPrecioSal * (_dPorDto / 100);
      _dPreSiva := _dPrecioSal - _dDto;
    end
    else if (_dPrecioSal <> 0) then
    begin
      _dDto    := _dPrecioSal - _dPreSiva;
      _dPorDto := (_dDto / _dPrecioSal) * 100;
    end;

    _dPreCiva := _dPreSiva * (1 + _dPorIva / 100);
    _dTotCiva := _dPreCiva * _dCant;
    _dTotSiva := _dPreSiva * _dCant;
  end;
end;

// Mismo criterio que el motor fiscal con RedondearPorLinea: cada linea
// aporta su base a centimos. Con precios de 4 decimales (traspasos
// valorados) las lineas suman lo que la cabecera: 27,2125 + 25,41 +
// 27,2125 son 79,83, no 79,835. FZ-ISSUE-205: con IVA incluido manda el
// PVP (la base sale del total con IVA de la linea; el motor reparte el
// centimo del tipo) y la cuota de la cabecera va por tipo: el total con
// IVA de una linea sin impuestos incluidos es solo informativo.
procedure TLinFac.RedondearTotalesACentimos;
var
  rBase: Double;
  rCuota: Double;
begin
  if SameText(_sImpcl, 'S') then
  begin
    _dTotCiva := RedondearACentimos(_dTotCiva);
    rBase := _dTotCiva;
    if (1 + _dPorIva / 100) <> 0 then
      rBase := RedondearACentimos(_dTotCiva / (1 + _dPorIva / 100));
    _dTotSiva := rBase;
  end
  else
  begin
    rBase := RedondearACentimos(_dTotSiva);
    _dTotSiva := rBase;
    rCuota := RedondearACentimos(rBase * _dPorIva / 100);
    _dTotCiva := rBase + rCuota;
  end;
end;

procedure TLinFac.CopyToDataSetLin;
begin
  if Assigned(_unqryLin) and NecesitaActualizarDataSetLin then
  begin
    if _unqryLin.State = dsBrowse then
      _unqryLin.Edit;
    FCampoCantidad.AsCurrency := _dCant;
    FCampoPrecioSalida.AsCurrency := _dPrecioSal;
    FCampoPorcentajeDto.AsCurrency := _dPorDto;
    FCampoPrecioDto.AsCurrency := _dDto;
    FCampoImpuestosIncluidos.AsString := _sImpcl;
    FCampoTipoIva.AsString := _sTipIva;
    FCampoPorcentajeIva.AsCurrency := _dPorIVa;
    FCampoPrecioSinIva.AsCurrency := _dPreSiva;
    FCampoPrecioConIva.AsCurrency := _dPreCiva;
    FCampoTotalConIva.AsCurrency := _dTotCiva;
    FCampoTotalSinIva.AsCurrency := _dTotSiva;
  end;
end;

function TLinFac.CampoCurrencyDistinto(
  ACampo: TField; AValor: Currency): Boolean;
begin
  Result := ACampo.IsNull or (ACampo.AsCurrency <> AValor);
end;

function TLinFac.CampoStringDistinto(
  ACampo: TField; const AValor: string): Boolean;
begin
  Result := ACampo.IsNull or (ACampo.AsString <> AValor);
end;

function TLinFac.NecesitaActualizarDataSetLin: Boolean;
begin
  Result :=
    CampoCurrencyDistinto(FCampoCantidad, _dCant) or
    CampoCurrencyDistinto(FCampoPrecioSalida, _dPrecioSal) or
    CampoCurrencyDistinto(FCampoPorcentajeDto, _dPorDto) or
    CampoCurrencyDistinto(FCampoPrecioDto, _dDto) or
    CampoStringDistinto(FCampoImpuestosIncluidos, _sImpcl) or
    CampoStringDistinto(FCampoTipoIva, _sTipIva) or
    CampoCurrencyDistinto(FCampoPorcentajeIva, _dPorIVa) or
    CampoCurrencyDistinto(FCampoPrecioSinIva, _dPreSiva) or
    CampoCurrencyDistinto(FCampoPrecioConIva, _dPreCiva) or
    CampoCurrencyDistinto(FCampoTotalConIva, _dTotCiva) or
    CampoCurrencyDistinto(FCampoTotalSinIva, _dTotSiva);
end;

procedure TLinFac.CopyToDataSetFac;
begin
  // Implementar si es necesario para actualizar campos de la factura
end;

procedure TLinFac.CopyToObjectLin;
begin
  _sNumLin := FCampoNumeroLinea.AsString;
  _dCant := FCampoCantidad.AsCurrency;
  if FCampoImpuestosIncluidos.AsString = '' then
    _sImpcl := 'S'
  else
    _sImpcl := FCampoImpuestosIncluidos.AsString;
  _sTipIVA := FCampoTipoIva.AsString;
  _dPorIVa := FCampoPorcentajeIva.AsCurrency;
  _dPrecioSal := FCampoPrecioSalida.AsCurrency;
  _dPorDto := FCampoPorcentajeDto.AsCurrency;
  _dDto := FCampoPrecioDto.AsCurrency;
  _dPreSiva := FCampoPrecioSinIva.AsCurrency;
  _dPreCiva := FCampoPrecioConIva.AsCurrency;
  _dTotCiva := FCampoTotalConIva.AsCurrency;
  _dTotSiva := FCampoTotalSinIva.AsCurrency;
end;

procedure TLinFac.CopyToObjectFac;
begin
  //if not Assigned(_unqryFac) then Exit;
  _dPorIvaN := _unqryFac.FieldByName(fPorIvaN).AsFloat;
  _dPorIvaR := _unqryFac.FieldByName(fPorIVAR).AsFloat;
  _dPorIvaS := _unqryFac.FieldByName(fPorIVAS).AsFloat;
  _dPorIVAE := _unqryFac.FieldByName(fPorIVAE).AsFloat;
end;

procedure TLinFac.SetInit(AUnqryLin: TDataset);
begin
  _unqryLin := AUnqryLin;
  CachearCamposLinea;
end;

procedure TLinFac.CachearCamposLinea;
begin
  FCampoNumeroLinea := _unqryLin.FieldByName(fnrolin);
  FCampoCantidad := _unqryLin.FieldByName(fcant);
  FCampoImpuestosIncluidos := _unqryLin.FieldByName(fimpcl);
  FCampoTipoIva := _unqryLin.FieldByName(ftipiva);
  FCampoPorcentajeIva := _unqryLin.FieldByName(fporiva);
  FCampoPrecioSalida := _unqryLin.FieldByName(fpreciosal);
  FCampoPorcentajeDto := _unqryLin.FieldByName(fpordto);
  FCampoPrecioDto := _unqryLin.FieldByName(fdto);
  FCampoPrecioSinIva := _unqryLin.FieldByName(fpresiva);
  FCampoPrecioConIva := _unqryLin.FieldByName(fpreciva);
  FCampoTotalConIva := _unqryLin.FieldByName(ftotciva);
  FCampoTotalSinIva := _unqryLin.FieldByName(ftotsiva);
end;

// Getters y Setters
function TLinFac.GetCant: Currency;
begin
  Result := _dCant;
end;

procedure TLinFac.SetCant(const Value: Currency);
begin
  _dCant := Value;
  if _dPreSiva <> 0 then
    _dTotSiva := _dCant * _dPreSiva;
  if _dPreCiva <> 0 then
    _dTotCiva := _dCant * _dPreCiva;
end;

function TLinFac.GetDto: Currency;
begin
  Result := _dDto;
end;

procedure TLinFac.SetDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dDto := Value;
  if (_dPrecioSal <> 0) then
  begin
    _dPorDto := (_dDto / _dPrecioSal) * 100;
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetImpcl: String;
begin
  Result := _sImpcl;
end;

procedure TLinFac.SetImpcl(const Value: String);
begin
  _sImpcl := Value;
end;

function TLinFac.GetPorDto: Currency;
begin
  Result := _dPorDto;
end;

procedure TLinFac.SetPorDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dPorDto := Value;
  if _dPrecioSal <> 0 then
  begin
    _dDto := _dPrecioSal * (_dPorDto / 100);
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetPorIva: Currency;
begin
  Result := _dPorIva;
end;

procedure TLinFac.SetPorIva(const Value: Currency);
begin
  _dPorIVa := Value;
end;

function TLinFac.GetPrecioSal: Currency;
begin
  Result := _dPrecioSal;
end;

procedure TLinFac.SetPrecioSal(const Value: Currency);
var
  dPrecioFinal: Currency;
begin
  _dPrecioSal := Value;
  SetPorDto(_dPorDto);   //recalculo el dto
  dPrecioFinal := _dPrecioSal - _dDto;
  if SameText(Impcl, 'S') then
  begin
    SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
  end
  else
  begin
    SetPreSiva(dPrecioFinal);
  end;
end;

function TLinFac.GetPreCiva: Currency;
begin
  Result := _dPreCiva;
end;

procedure TLinFac.SetPreCiva(const Value: Currency);
begin
  _dPreCiva := Value;
  _dPreSiva := _dPreCiva / (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotCiva := _dCant * _dPreCiva;
    _dTotSiva := _dCant * _dPreSiva;
  end;
end;

function TLinFac.GetPreSiva: Currency;
begin
  Result := _dPreSiva;
end;

procedure TLinFac.SetPreSiva(const Value: Currency);
begin
  _dPreSiva := Value;
  _dPreCiva := _dPreSiva * (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotSiva := _dCant * _dPreSiva;
    _dTotCiva := _dCant * _dPreCiva;
  end;
end;

function TLinFac.GetTipoIVa: String;
begin
  Result := _sTipIva;
end;

procedure TLinFac.SetTipoIva(const Value: String);
var
  dPorcen: Currency;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := _unqryFac.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := _unqryFac.FindField(Nombre);
  end;
begin
  _sTipIVa := Value;
  dPorcen := 0;
  if Assigned(_unqryFac) then
  begin
      case IndexStr(_sTipIVA, ['N', 'R', 'S', 'E']) of
        0: if FindField(fPorIvaN) <> nil then
             dPorcen := FieldByName(fPorIvaN).AsCurrency;
        1: if FindField(fPorIVAR) <> nil then
             dPorcen := FieldByName(fPorIVAR).AsCurrency;
        2: if FindField(fPorIVAS) <> nil then
             dPorcen := FieldByName(fPorIVAS).AsCurrency;
        3: if FindField(fPorIVAE) <> nil then
             dPorcen := FieldByName(fPorIVAE).AsCurrency;
      end;
  end;
  Self.PorIva := dPorcen;
end;

function TLinFac.GetTotCiva: Currency;
begin
  Result := _dTotCiva;
end;

procedure TLinFac.SetTotCiva(const Value: Currency);
begin
  _dTotCiva := Value;
end;

function TLinFac.GetTotSiva: Currency;
begin
  Result := _dTotSiva;
end;

procedure TLinFac.SetTotSiva(const Value: Currency);
begin
  _dTotSiva := Value;
end;

{ TFacturaTotales - Implementación completa }

constructor TFacturaTotales.Create(AConexion: TUniConnection;
                                   const ARepositorioLecturas:
                                     IRepositorioLecturasFactura;
                                   AUnqryFac: TDataset;
                                   unqryLineas: TDataset;
                                   LineaEnEdicion:TLinFac;
                                   const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
  _conexion := AConexion;
  FRepositorioLecturas := ARepositorioLecturas;
  _unqryFac := AUnqryFac;
  _unqryLineas := unqryLineas;
  _LineaEnEdicion := LineaEnEdicion;
  //_unqryLineasTemp := nil;
  _dPorRetencion := 0;
  _mensajeError := '';
  //_lineaEnEdicion := '';
  // _excluirLineaEnEdicion := False;

  InicializarTotales;
  InicializarConfiguracion;

  //ProcesarFacturaCompleta;
end;

function TFacturaTotales.RepositorioLecturas:
  IRepositorioLecturasFactura;
begin
  Result := FRepositorioLecturas;
end;

procedure TFacturaTotales.InicializarTotales;
begin
  FillChar(_totales, SizeOf(_totales), 0);
  SetLength(_lineasMotorFiscal, 0);
  FTieneLineasNegativas := False;
end;

procedure TFacturaTotales.InicializarConfiguracion;
begin
  FillChar(_configuracion, SizeOf(_configuracion), 0);
  FillChar(_porcentajes, SizeOf(_porcentajes), 0);
  _grupoZonaIVA := '';
  _codigoIVA := '';
  _codigoEmpresa := '';
  _fechaFactura := 0;
  _mensajeError := '';
end;

procedure TFacturaTotales.LeerDatosFactura;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := _unqryFac.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := _unqryFac.FindField(Nombre);
  end;
begin
    _fechaFactura      := FieldByName('FECHA_FAC').AsDateTime;
    _codigoEmpresa := FieldByName('CODIGO_EMP_FAC').AsString;
    _configuracion.EsFacturaSimplificada :=
                 SameText(FieldByName('TIPO_FAC').AsString, 'SIMPLIFICADA');
    VerificarYCompletarDatosEmpresa;
    VerificarYCompletarDatosCliente;
    _configuracion.EsRegimenAgricolaEmpresa :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString = 'S');
    _configuracion.EsRegimenAgricolaCliente :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString = 'S');
    _configuracion.EsIntracomunitario       :=
             (FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString = 'S');
    _configuracion.EsVentaActivoFijo        :=
                    (FieldByName('ESVENTA_ACTIVO_FIJO_FAC').AsString = 'S');
    _configuracion.AplicaRetencionesCliente :=
                  (FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString = 'S');
    _configuracion.AplicaRetencionesEmpresa :=
                  (FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString = 'S');
    _configuracion.IVAExento  :=
                   (FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString = 'S');
    _configuracion.IVARecargo :=
                  (FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString = 'S');
    if FindField('ESIRPF_IMP_INCL_ZONA_IVA_FAC') <> nil then
       _configuracion.IRPFImpuestoIncluido :=
                (FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString = 'S')
    else
       _configuracion.IRPFImpuestoIncluido := False;
    // La cabecera guarda si la zona de IVA aplica recargo; se lee tal cual,
    // porque cada recálculo crea un motor nuevo con la configuración a cero
    // y solo CargarConfiguracionIVA (primer cálculo) la ponía a verdadero.
    if FindField('ESAPLICA_RE_ZONA_IVA_FAC') <> nil then
       _configuracion.AplicaRecargo :=
         SameText(FindField('ESAPLICA_RE_ZONA_IVA_FAC').AsString, 'S')
    else
       _configuracion.AplicaRecargo := False;
    _grupoZonaIVA := FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
    _CodigoIVA    := FieldByName('CODIGO_IVA_FAC').AsString;
    _dPorRetencion := FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat;
  LeerPorcentajesDesdeFactura;
end;

procedure TFacturaTotales.LeerPorcentajesDesdeFactura;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := _unqryFac.FieldByName(Nombre);
  end;
begin
  if Assigned(_unqryFac) and _unqryFac.Active then
  begin
    _porcentajes.IVANormal := FieldByName('PORCENTAJE_IVAN_FAC').AsFloat;
    _porcentajes.IVAReducido := FieldByName('PORCENTAJE_IVAR_FAC').AsFloat;
    _porcentajes.IVASuperReducido := FieldByName('PORCENTAJE_IVAS_FAC').AsFloat;
    _porcentajes.IVAExento := FieldByName('PORCENTAJE_IVAE_FAC').AsFloat;
    // Leer recargos de equivalencia
    _porcentajes.REcNormal := FieldByName('PORCENTAJE_REN_FAC').AsFloat;
    _porcentajes.REcReducido := FieldByName('PORCENTAJE_RER_FAC').AsFloat;
    _porcentajes.REcSuperReducido := FieldByName('PORCENTAJE_RES_FAC').AsFloat;
    _porcentajes.REcExento := FieldByName('PORCENTAJE_REE_FAC').AsFloat;
  end;
end;

procedure TFacturaTotales.CargarConfiguracionIVA(sGrupoZona: string);
var
  Qry: TDataSet;
begin
  if sGrupoZona <> '' then
  begin
    Qry := RepositorioLecturas.BuscarConfiguracionIva(
      sGrupoZona,
      _fechaFactura);
    try
      if not Qry.IsEmpty then
      begin
        if _unqryFac.State = dsBrowse then
          _unqryFac.Edit;
      // Asignación al DataSet de la Factura (Persistencia)
      _unqryFac.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_NORMAL_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_REN_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_NORMAL_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_REDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_RER_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_REDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAS_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_SUPERREDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_RES_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_SUPERREDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAE_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_EXENTO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_REE_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_EXENTO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString :=
        Qry.FieldByName('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString;
      _unqryFac.FieldByName('ESAPLICA_RE_ZONA_IVA_FAC').AsString     :=
        Qry.FieldByName('ESAPLICA_RE_IVA_IVAGRP').AsString;
      _unqryFac.FieldByName('CODIGO_IVA_FAC').AsString               :=
        Qry.FieldByName('CODIGO_IVA').AsString;
      _unqryFac.FieldByName('ESIVAAGRICOLA_ZONA_IVA_FAC').AsString   :=
        Qry.FieldByName('ESIVAAGRICOLA_IVA_IVAGRP').AsString;
      // Actualizar también la estructura interna de trabajo (_configuracion y
      // _porcentajes)
      _configuracion.AplicaRecargo        :=
        (Qry.FieldByName('ESAPLICA_RE_IVA_IVAGRP').AsString = 'S');
      _configuracion.IRPFImpuestoIncluido :=
        (Qry.FieldByName('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString = 'S');
      _grupoZonaIVA                       := sGrupoZona;
      _codigoIVA := Qry.FieldByName('CODIGO_IVA').AsString;
      // Sincroniza _porcentajes con los nuevos valores del DataSet
        LeerPorcentajesDesdeFactura;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

// FZ-ISSUE-370: con IVA exento se graban en la cabecera los porcentajes
// anulados (normal = reducido = superreducido = exento). Si la factura deja
// de ser exenta (otro cliente o vuelta a venta al contado), se recuperan los
// de la zona de IVA; si no, el total y las líneas nuevas saldrían al 0 %.
// Si las reglas vuelven a declararla exenta (REAGP), se anulan de nuevo.
procedure TFacturaTotales.RestablecerPorcentajesZonaSiAnulados;
begin
  if (not _configuracion.IVAExento) and (_grupoZonaIVA <> '') and
     SameValue(_porcentajes.IVANormal, _porcentajes.IVAExento) and
     SameValue(_porcentajes.IVAReducido, _porcentajes.IVAExento) and
     SameValue(_porcentajes.IVASuperReducido, _porcentajes.IVAExento) then
    CargarConfiguracionIVA(_grupoZonaIVA);
end;

procedure TFacturaTotales.AplicarReglas;
begin
  // 1. Régimen Especial Agrícola Empresa
  if _configuracion.EsRegimenAgricolaEmpresa then
  begin
    _configuracion.AplicaRetencionesEmpresa := True;
    _configuracion.IVARecargo := False;
    if BuscarDatosIVAAgricola(_codigoEmpresa) then
    begin
    end;
  end;
  // 2. Intracomunitario
  if _configuracion.EsIntracomunitario then
  begin
    _configuracion.IVAExento := True;
    _configuracion.AplicaRetencionesCliente := False;
    _configuracion.EsRegimenAgricolaCliente := False;
  end;
  // 3. Venta Activo Fijo + REAGP Empresa
  if ((_configuracion.EsVentaActivoFijo) and
      (_configuracion.EsRegimenAgricolaEmpresa)) then
  begin
    _configuracion.IVAExento := True;
  end;
  // 4. REAGP Empresa + REAGP Cliente
  if ((_configuracion.EsRegimenAgricolaEmpresa) and
      (_configuracion.EsRegimenAgricolaCliente)) then
  begin
    _configuracion.AplicaRetencionesCliente := True;
    _configuracion.IVAExento := True;
  end;
  // 5. REAGP Empresa + Cliente Normal sin retenciones
  if _configuracion.EsRegimenAgricolaEmpresa and
     not _configuracion.EsRegimenAgricolaCliente and
     not _configuracion.AplicaRetencionesCliente then
  begin
    _configuracion.IVAExento := True;
  end;
  if _configuracion.IVAExento then
  begin
    _porcentajes.IVANormal        := _porcentajes.IVAExento;
    _porcentajes.IVAReducido      := _porcentajes.IVAExento;
    _porcentajes.IVASuperReducido := _porcentajes.IVAExento;
    // Anulamos cualquier Recargo de Equivalencia
    _porcentajes.REcNormal        := 0;
    _porcentajes.REcReducido      := 0;
    _porcentajes.REcSuperReducido := 0;
    _porcentajes.REcExento        := 0;
  end;
end;

function TFacturaTotales.ObtenerPorcentajePorTipo(tipo: string): Currency;
begin
  case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
    0: Result := _porcentajes.IVANormal;
    1: Result := _porcentajes.IVAReducido;
    2: Result := _porcentajes.IVASuperReducido;
    3: Result := _porcentajes.IVAExento;
  else
    Result := _porcentajes.IVANormal;
  end;
end;

function TFacturaTotales.ObtenerPorcentajeREPorTipo(tipo: string): Currency;
var
  sNif, sRazon, sDir: string;
  tieneDatosMinimos: Boolean;
begin
  // Primero verificamos los datos mínimos del cliente
  sNif   := Trim(_unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString);
  sRazon := Trim(_unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
  sDir   := Trim(_unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString);
  tieneDatosMinimos := (sNif <> '') and (sRazon <> '') and (sDir <> '');
  // Si es Simplificada O no tiene datos mínimos O no aplica recargo por config:
  // devolvemos 0
  if _configuracion.EsFacturaSimplificada or
     (not tieneDatosMinimos) or
     not (_configuracion.AplicaRecargo and _configuracion.IVARecargo) then
  begin
    Result := 0;
  end
  else
  begin
    case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
      0: Result := _porcentajes.REcNormal;
      1: Result := _porcentajes.REcReducido;
      2: Result := _porcentajes.REcSuperReducido;
      3: Result := _porcentajes.REcExento;
    else
      Result := 0;
    end;
  end;
end;

function TFacturaTotales.LineaActualPendienteDeResolver: Boolean;
var
  CampoCodigo: TField;
  CampoDescripcion: TField;
  CampoNumeroAtributos: TField;
  CampoSku: TField;
begin
  Result := False;
  if Assigned(_unqryLineas) and _unqryLineas.Active and
     (_unqryLineas.State in dsEditModes) then
  begin
    CampoCodigo := _unqryLineas.FindField(fcodart);
    CampoDescripcion := _unqryLineas.FindField(fdesart);
    CampoNumeroAtributos := _unqryLineas.FindField(
      'NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
    CampoSku := _unqryLineas.FindField('CODIGO_UNIDAD_FACLIN');
    if Assigned(CampoCodigo) and Assigned(CampoDescripcion) then
      Result := (Trim(CampoCodigo.AsString) <> '') and
                (Trim(CampoDescripcion.AsString) = '');
    if not Result and Assigned(CampoNumeroAtributos) then
      Result := PrimerAtributoPendienteLineaCaja(_unqryLineas) > 0;
    if not Result and Assigned(CampoNumeroAtributos) and
       Assigned(CampoSku) then
      Result := (CampoNumeroAtributos.AsInteger > 0) and
                (Pos('/', Trim(CampoSku.AsString)) = 0);
  end;
end;

function TFacturaTotales.ClienteTieneDatosFiscales: Boolean;
var
  Direccion: string;
  Nif: string;
  RazonSocial: string;
begin
  Nif := Trim(
    _unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString);
  RazonSocial := Trim(
    _unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
  Direccion := Trim(
    _unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString);
  Result :=
    (Nif <> '') and
    (RazonSocial <> '') and
    (Direccion <> '');
end;

function TFacturaTotales.CrearConfiguracionMotorFiscal:
  TConfiguracionMotorFiscalVenta;
var
  PuedeAplicarRetencion: Boolean;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.RedondearPorLinea := True;
  Result.CalcularIvaIncluidoPorDiferencia := True;
  Result.AplicaRecargo :=
    _configuracion.AplicaRecargo and
    _configuracion.IVARecargo;
  Result.EsFacturaSimplificada :=
    _configuracion.EsFacturaSimplificada;
  Result.ClienteConDatosFiscales :=
    ClienteTieneDatosFiscales;
  Result.RetencionIncluyeImpuestos :=
    _configuracion.IRPFImpuestoIncluido;
  PuedeAplicarRetencion :=
    _configuracion.AplicaRetencionesCliente and
    _configuracion.AplicaRetencionesEmpresa and
    not (
      _configuracion.EsVentaActivoFijo and
      _configuracion.EsRegimenAgricolaEmpresa);
  Result.AplicaRetencion := PuedeAplicarRetencion;
  if _configuracion.EsVentaActivoFijo and
     _configuracion.EsRegimenAgricolaEmpresa then
    _dPorRetencion := 0;
  if PuedeAplicarRetencion and
     not Result.EsFacturaSimplificada and
     Result.ClienteConDatosFiscales and
     (_dPorRetencion = 0) then
    _dPorRetencion :=
      BuscarPorcenRetencion(_codigoEmpresa);
  Result.PorcentajeRetencion := _dPorRetencion;
  if _unqryFac.FindField('PORCENTAJE_DTO_COMERCIAL_FAC') <> nil then
    Result.PorcentajeDtoComercial :=
      _unqryFac.FieldByName('PORCENTAJE_DTO_COMERCIAL_FAC').AsFloat;
  if _unqryFac.FindField('PORCENTAJE_DTO_FINANCIERO_FAC') <> nil then
    Result.PorcentajeDtoFinanciero :=
      _unqryFac.FieldByName('PORCENTAJE_DTO_FINANCIERO_FAC').AsFloat;
end;

function TFacturaTotales.ProcesarFacturaCompleta: Boolean;
begin
  _mensajeError := '';
  _abortado := False;
  Result := True;
  // La búsqueda puede escribir el artículo antes de que el editor termine de
  // resolver la descripción o el SKU con atributos. No se fuerza el Post de
  // esa línea intermedia; el evento final volverá a solicitar el cálculo.
  _calculoOmitido := LineaActualPendienteDeResolver;
  if not _calculoOmitido then
  begin
    try
      // Leer configuración de la factura
      LeerDatosFactura;
      RestablecerPorcentajesZonaSiAnulados;
      // Aplicar reglas de negocio
      AplicarReglas;
      // Validar configuración
      ValidarConfiguracion;
      // Procesar líneas y calcular totales
      RecorrerYCalcularLineasConClientDataSet;
      CalcularTotalesFactura;
      // Actualizar en la base de datos
      if _unqryFac.State <> dsEdit then
        _unqryFac.Edit;
      ActualizarTotalesEnDataSet;
    except
      on E: EAbort do
      begin
        // Aborto silencioso de una validación que ya avisó: no es un error
        _abortado := True;
        _mensajeError := E.Message;
        Result := False;
      end;
      on E: Exception do
      begin
        _mensajeError := E.Message;
        // Se registra la causa original; el llamante decide si aborta
        FRegistroLog.RegistrarError(
          'TFacturaTotales.ProcesarFacturaCompleta (' +
          E.ClassName + '): ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

procedure TFacturaTotales.AcumularTotalesPorTipoIVA(
  ALinea: TLinFac; AIndice: Integer);
var
  LineaMotor: TLineaMotorFiscalVenta;
begin
  FillChar(LineaMotor, SizeOf(LineaMotor), 0);
  LineaMotor.TipoIva := ALinea.TipoIva;
  LineaMotor.Base := ALinea.TotSiva;
  LineaMotor.TotalConIva := ALinea.TotCiva;
  LineaMotor.PorcentajeIva :=
    ObtenerPorcentajePorTipo(ALinea.TipoIva);
  LineaMotor.PorcentajeRecargo :=
    ObtenerPorcentajeREPorTipo(ALinea.TipoIva);
  LineaMotor.Bruto := ALinea.PrecioSal * ALinea.Cant;
  LineaMotor.Descuento := ALinea.Dto * ALinea.Cant;
  LineaMotor.Cantidad := ALinea.Cant;
  LineaMotor.ImpuestosIncluidos :=
    SameText(ALinea.Impcl, 'S');
  _lineasMotorFiscal[AIndice] := LineaMotor;
end;

procedure TFacturaTotales.AplicarResultadoMotorFiscal(
  const AResultado: TResultadoMotorFiscalVenta);
begin
  FDtoComercial := AResultado.TotalDtoComercial;
  FDtoFinanciero := AResultado.TotalDtoFinanciero;
  _totales.IVAN.BaseImponible := AResultado.Normal.Base;
  _totales.IVAN.PorcentajeIVA := AResultado.Normal.PorcentajeIva;
  _totales.IVAN.ImporteIVA := AResultado.Normal.ImporteIva;
  _totales.IVAN.PorcentajeRE :=
    AResultado.Normal.PorcentajeRecargo;
  _totales.IVAN.ImporteRE := AResultado.Normal.ImporteRecargo;
  _totales.IVAR.BaseImponible := AResultado.Reducido.Base;
  _totales.IVAR.PorcentajeIVA := AResultado.Reducido.PorcentajeIva;
  _totales.IVAR.ImporteIVA := AResultado.Reducido.ImporteIva;
  _totales.IVAR.PorcentajeRE :=
    AResultado.Reducido.PorcentajeRecargo;
  _totales.IVAR.ImporteRE := AResultado.Reducido.ImporteRecargo;
  _totales.IVAS.BaseImponible := AResultado.SuperReducido.Base;
  _totales.IVAS.PorcentajeIVA :=
    AResultado.SuperReducido.PorcentajeIva;
  _totales.IVAS.ImporteIVA :=
    AResultado.SuperReducido.ImporteIva;
  _totales.IVAS.PorcentajeRE :=
    AResultado.SuperReducido.PorcentajeRecargo;
  _totales.IVAS.ImporteRE :=
    AResultado.SuperReducido.ImporteRecargo;
  _totales.IVAE.BaseImponible := AResultado.Exento.Base;
  _totales.IVAE.PorcentajeIVA := AResultado.Exento.PorcentajeIva;
  _totales.IVAE.ImporteIVA := AResultado.Exento.ImporteIva;
  _totales.IVAE.PorcentajeRE :=
    AResultado.Exento.PorcentajeRecargo;
  _totales.IVAE.ImporteRE := AResultado.Exento.ImporteRecargo;
  _totales.BaseNormal := AResultado.Normal.Base;
  _totales.BaseReducida := AResultado.Reducido.Base;
  _totales.BaseSuper := AResultado.SuperReducido.Base;
  _totales.BaseExenta := AResultado.Exento.Base;
  _totales.CuotaIVANormal := AResultado.Normal.ImporteIva;
  _totales.CuotaIVAReducida := AResultado.Reducido.ImporteIva;
  _totales.CuotaIVASuper := AResultado.SuperReducido.ImporteIva;
  _totales.CuotaIVAExenta := AResultado.Exento.ImporteIva;
  _totales.CuotaRENormal := AResultado.Normal.ImporteRecargo;
  _totales.CuotaREReducida := AResultado.Reducido.ImporteRecargo;
  _totales.CuotaRESuper :=
    AResultado.SuperReducido.ImporteRecargo;
  _totales.CuotaREExenta := AResultado.Exento.ImporteRecargo;
  _totales.TotalBases := AResultado.TotalBases;
  _totales.TotalIVANormal := AResultado.Normal.ImporteIva;
  _totales.TotalIVAReducido := AResultado.Reducido.ImporteIva;
  _totales.TotalIVASuperReducido :=
    AResultado.SuperReducido.ImporteIva;
  _totales.TotalIVAExento := AResultado.Exento.ImporteIva;
  _totales.TotalREcargo := AResultado.TotalRecargo;
  _totales.TotalImpuestos := AResultado.TotalImpuestos;
  _totales.TotalRetencion := AResultado.TotalRetencion;
  _totales.TotalLiquido := AResultado.TotalLiquido;
  _totales.TotalBruto := AResultado.TotalBruto;
  _totales.TotalDescuentosLineas :=
    AResultado.TotalDescuentos;
  _totales.TotalCantidades := AResultado.TotalCantidades;
  FTieneLineasNegativas := AResultado.TieneImportesNegativos;
end;

procedure TFacturaTotales.CalcularTotalesGenerales;
var
  ConfiguracionMotor: TConfiguracionMotorFiscalVenta;
  ResultadoMotor: TResultadoMotorFiscalVenta;
begin
  ConfiguracionMotor := CrearConfiguracionMotorFiscal;
  ResultadoMotor := CalcularTotalesMotorFiscalVenta(
    _lineasMotorFiscal, ConfiguracionMotor);
  AplicarResultadoMotorFiscal(ResultadoMotor);
end;

procedure TFacturaTotales.CalcularTotalesFactura;
begin
  CalcularTotalesGenerales;
end;

procedure TFacturaTotales.ActualizarTotalesEnDataSet;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := _unqryFac.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := _unqryFac.FindField(Nombre);
  end;
begin
    if _unqryFac.State = dsBrowse then
      _unqryFac.Edit;
    if FindField('TOTAL_DTO_COMERCIAL_FAC') <> nil then
      FieldByName('TOTAL_DTO_COMERCIAL_FAC').AsFloat := FDtoComercial;
    if FindField('TOTAL_DTO_FINANCIERO_FAC') <> nil then
      FieldByName('TOTAL_DTO_FINANCIERO_FAC').AsFloat := FDtoFinanciero;
    // Bases imponibles
    FieldByName('TOTAL_BASEI_IVAN_FAC').AsFloat :=
                                         _totales.IVAN.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAR_FAC').AsFloat :=
                                         _totales.IVAR.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAS_FAC').AsFloat :=
                                         _totales.IVAS.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAE_FAC').AsFloat :=
                                         _totales.IVAE.BaseImponible;
    FieldByName('TOTAL_BASES_FAC').AsFloat := _totales.TotalBases;
    // Importes de IVA
    FieldByName('TOTAL_IVAN_FAC').AsFloat := _totales.TotalIVANormal;
    FieldByName('TOTAL_IVAR_FAC').AsFloat := _totales.TotalIVAReducido;
    FieldByName('TOTAL_IVAS_FAC').AsFloat :=
                                            _totales.TotalIVASuperReducido;
    FieldByName('TOTAL_IVAE_FAC').AsFloat := _totales.TotalIVAExento;
    // Importes de Recargo Equivalencia
    FieldByName('TOTAL_REN_FAC').AsFloat := _totales.IVAN.ImporteRE;
    FieldByName('TOTAL_RER_FAC').AsFloat := _totales.IVAR.ImporteRE;
    FieldByName('TOTAL_RES_FAC').AsFloat := _totales.IVAS.ImporteRE;
    FieldByName('TOTAL_REE_FAC').AsFloat := _totales.IVAE.ImporteRE;
    // Totales generales
    FieldByName('TOTAL_IMPUESTOS_FAC').AsFloat := _totales.TotalImpuestos;
    FieldByName('TOTAL_RETENCION_FAC').AsFloat := _totales.TotalRetencion;
    FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat := _dPorRetencion;
    FieldByName('TOTAL_LIQUIDO_FAC').AsFloat := _totales.TotalLiquido;
    // Actualizar configuración aplicada
    FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString :=
      IfThen(_configuracion.IVAExento, 'S', 'N');
    FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
      IfThen(_configuracion.AplicaRetencionesCliente, 'S', 'N');
    FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString :=
      IfThen(_configuracion.AplicaRetencionesEmpresa, 'S', 'N');
    if FindField('ESAPLICA_RE_ZONA_IVA_FAC') <> nil then
      _configuracion.AplicaRecargo :=
                 SameText(FieldByName('ESAPLICA_RE_ZONA_IVA_FAC').AsString, 'S')
    else
      _configuracion.AplicaRecargo := False;
    // Actualizar porcentajes aplicados
    FieldByName('PORCENTAJE_IVAN_FAC').AsFloat := _porcentajes.IVANormal;
    FieldByName('PORCENTAJE_IVAR_FAC').AsFloat := _porcentajes.IVAReducido;
    FieldByName('PORCENTAJE_IVAS_FAC').AsFloat :=
                                              _porcentajes.IVASuperReducido;
    FieldByName('PORCENTAJE_IVAE_FAC').AsFloat := _porcentajes.IVAExento;
end;

procedure TFacturaTotales.ValidarConfiguracion;
begin
end;

function TFacturaTotales.ValidarFactura: Boolean;
begin
  Result := True;
  _mensajeError := '';
  try
    ValidarConfiguracion;
  except
    on E: Exception do
    begin
      _mensajeError := E.Message;
      Result := False;
    end;
  end;
end;

procedure TFacturaTotales.PrepararLineaCalculada(ALinea: TLinFac);
begin
  ALinea.CopyToObjectLin;
  if _configuracion.IVAExento then
    ALinea.TipoIva := 'E';
  ALinea.PorIva := ObtenerPorcentajePorTipo(ALinea.TipoIva);
  ALinea.CalcularLinea;
  ALinea.RedondearTotalesACentimos;
end;

procedure TFacturaTotales.RecorrerYCalcularLineasConClientDataSet;
var
  bookmark: TBookmark;
  iIndiceMotor: Integer;
  lineaActual: TLinFac;
  aBases: TArray<Double>;
  WasInsert, WasEdit, WasEmptyInsert: Boolean;
begin
  if Assigned(_unqryLineas) and _unqryLineas.Active then
  begin
    _unqryLineas.DisableControls;
    try
      WasInsert := (_unqryLineas.State = dsInsert);
      WasEdit := (_unqryLineas.State = dsEdit);
      WasEmptyInsert := False;
    // ======================================================================
    // 1. PREPARAMOS EL DATASET PARA CALCULAR (SIN ERRORES)
    // ======================================================================
      if WasInsert or WasEdit then
      begin
        if Trim(_unqryLineas.FieldByName(fcodart).AsString) = '' then
        begin
          WasEmptyInsert := True;
          _unqryLineas.Cancel;
        end
        else
          _unqryLineas.Post;
      end
      else
        WasEmptyInsert := False;
      if _unqryLineas.IsEmpty then
      begin
        if WasEmptyInsert then
          _unqryLineas.Append;
      end
      else
      begin
    // ======================================================================
    // 2. HACEMOS LA SUMA FISCAL
    // ======================================================================
        bookmark := _unqryLineas.GetBookmark;
        _unqryLineas.First;
        SetLength(_lineasMotorFiscal, _unqryLineas.RecordCount);
        iIndiceMotor := 0;
        lineaActual := TLinFac.Create(_unqryLineas, _unqryFac, False);
        try
          while not _unqryLineas.Eof do
          begin
            PrepararLineaCalculada(lineaActual);
            AcumularTotalesPorTipoIVA(lineaActual, iIndiceMotor);
            Inc(iIndiceMotor);
            _unqryLineas.Next;
          end;
          SetLength(_lineasMotorFiscal, iIndiceMotor);
          // FZ-ISSUE-205: cada linea guarda la base que le asigna el
          // motor (con IVA incluido, con el centimo de ajuste del tipo),
          // para que las lineas sumen exactamente las bases del pie.
          aBases := CalcularTotalesMotorFiscalVenta(_lineasMotorFiscal,
            CrearConfiguracionMotorFiscal).BasesLinea;
          _unqryLineas.First;
          iIndiceMotor := 0;
          while not _unqryLineas.Eof do
          begin
            PrepararLineaCalculada(lineaActual);
            if iIndiceMotor <= High(aBases) then
              lineaActual.TotSiva := aBases[iIndiceMotor];
            lineaActual.CopyToDataSetLin;
            Inc(iIndiceMotor);
            _unqryLineas.Next;
          end;
        finally
          FreeAndNil(lineaActual);
        end;
        if _unqryLineas.BookmarkValid(bookmark) then
        begin
          _unqryLineas.GotoBookmark(bookmark);
          _unqryLineas.FreeBookmark(bookmark);
        end;
        if WasEmptyInsert then
          _unqryLineas.Append
        else if WasEdit then
          _unqryLineas.Edit;
      end;
    finally
      _unqryLineas.EnableControls;
    end;
  end;
end;

function TFacturaTotales.BuscarPorcenRetencion(CodEmpresa: string): Currency;
begin
  Result := RepositorioLecturas.BuscarPorcentajeRetencion(
    CodEmpresa,
    _FechaFactura);
end;

function TFacturaTotales.BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
var
  Qry: TDataSet;
begin
  Result := False;
  Qry := RepositorioLecturas.BuscarDatosIvaAgricola(
    CodEmpresa,
    _FechaFactura);
  try
    if not Qry.IsEmpty then
    begin
      _GrupoZonaIVA := Qry.FieldByName('IVA_IVAGRP').AsString;
      _CodigoIVA    := Qry.FieldByName('CODIGO_IVA').AsString;
      _porcentajes.IVANormal :=
        Qry.FieldByName('PORCENTAJE_NORMAL_IVA').AsCurrency;
      _porcentajes.IVAExento :=
        Qry.FieldByName('PORCENTAJE_EXENTO_IVA').AsCurrency;
      _porcentajes.IVAReducido :=
                               Qry.FieldByName(
                                 'PORCENTAJE_REDUCIDO_IVA').AsCurrency;
      _porcentajes.IVASuperReducido :=
                          Qry.FieldByName(
                            'PORCENTAJE_SUPERREDUCIDO_IVA').AsCurrency;
      Result := True;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosCliente;
var
  Qry: TDataSet;
  sCodCli: string;
begin
  sCodCli := _unqryFac.FieldByName('CODIGO_CLI_FAC').AsString;
  if (sCodCli <> '') and
     (sCodCli <> '0') and
     (sCodCli <> 'VENTA CONTADO') and
     (_unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString = '') then
  begin
    Qry := RepositorioLecturas.BuscarClienteConTarifa(sCodCli);
    try
      if not Qry.IsEmpty then
      begin
        if _unqryFac.State = dsBrowse then
          _unqryFac.Edit;
      _unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('RAZON_SOCIAL_CLI').AsString;
      _unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString         :=
                                        Qry.FieldByName('NIF_CLI').AsString;
      _unqryFac.FieldByName('MOVIL_CLIENTE_FAC').AsString       :=
                                      Qry.FieldByName('MOVIL_CLI').AsString;
      _unqryFac.FieldByName('EMAIL_CLIENTE_FAC').AsString       :=
                                      Qry.FieldByName('EMAIL_CLI').AsString;
      _unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION1_CLI').AsString;
      _unqryFac.FieldByName('DIRECCION2_CLIENTE_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION2_CLI').AsString;
      _unqryFac.FieldByName('POBLACION_CLIENTE_FAC').AsString   :=
                                  Qry.FieldByName('POBLACION_CLI').AsString;
      _unqryFac.FieldByName('PROVINCIA_CLIENTE_FAC').AsString   :=
                                  Qry.FieldByName('PROVINCIA_CLI').AsString;
      _unqryFac.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString     :=
                                    Qry.FieldByName(
                                      'CODIGO_POSTAL_CLI').AsString;
      _unqryFac.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('NOMBRE_PAI_CLI').AsString;
      _unqryFac.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('CODIGO_PAI_CLI').AsString;
      _unqryFac.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString :=
                              Qry.FieldByName('ESIVA_RECARGO_CLI').AsString;
      _unqryFac.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString  :=
                               Qry.FieldByName('ESIVA_EXENTO_CLI').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_CLI').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
                              Qry.FieldByName('ESRETENCIONES_CLI').AsString;
      _unqryFac.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString :=
                         Qry.FieldByName('ESINTRACOMUNITARIO_CLI').AsString;
      _unqryFac.FieldByName('FORMA_PAGO_FAC').AsString :=
                          Qry.FieldByName('CODIGO_FP_CLI').AsString;
      _unqryFac.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
                            Qry.FieldByName('TARIFA_ARTICULO_CLI').AsString;
        if Qry.FindField('ESIMP_INCL_TAR').AsString <> '' then
          _unqryFac.FieldByName(
            'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
              Qry.FindField('ESIMP_INCL_TAR').AsString;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosEmpresa;
var
  Qry: TDataSet;
begin
  if (_unqryFac.FieldByName(
       'RAZON_SOCIAL_EMPRESA_FAC').AsString = '') and
     (_codigoEmpresa <> '') then
  begin
    Qry := RepositorioLecturas.BuscarEmpresa(_codigoEmpresa);
    try
      if not Qry.IsEmpty then
      begin
        if _unqryFac.State = dsBrowse then
          _unqryFac.Edit;
      _unqryFac.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('RAZON_SOCIAL_EMP').AsString;
      _unqryFac.FieldByName('NIF_EMPRESA_FAC').AsString         :=
                                        Qry.FieldByName('NIF_EMP').AsString;
      _unqryFac.FieldByName('MOVIL_EMPRESA_FAC').AsString       :=
                                      Qry.FieldByName('MOVIL_EMP').AsString;
      _unqryFac.FieldByName('EMAIL_EMPRESA_FAC').AsString       :=
                                      Qry.FieldByName('EMAIL_EMP').AsString;
      _unqryFac.FieldByName('DIRECCION1_EMPRESA_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION1_EMP').AsString;
      _unqryFac.FieldByName('DIRECCION2_EMPRESA_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION2_EMP').AsString;
      _unqryFac.FieldByName('POBLACION_EMPRESA_FAC').AsString   :=
                                  Qry.FieldByName('POBLACION_EMP').AsString;
      _unqryFac.FieldByName('PROVINCIA_EMPRESA_FAC').AsString   :=
                                  Qry.FieldByName('PROVINCIA_EMP').AsString;
      _unqryFac.FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString     :=
                                    Qry.FieldByName(
                                      'CODIGO_POSTAL_EMP').AsString;
      _unqryFac.FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('NOMBRE_PAI_EMP').AsString;
      _unqryFac.FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('CODIGO_PAI_EMP').AsString;
      _unqryFac.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString :=
                             Qry.FieldByName('GRUPO_ZONA_IVA_EMP').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString :=
                              Qry.FieldByName('ESRETENCIONES_EMP').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
      _unqryFac.FieldByName('TEXTO_LEGAL_EMPRESA_FAC').AsString :=
                        Qry.FieldByName('TEXTO_LEGAL_FACTURA_EMP').AsString;
      var sGrupo := _unqryFac.FieldByName(
                                     'GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
        CargarConfiguracionIVA(sGrupo);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;
end.

{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFaseCobroPersistenciaIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para la fase de cobro de caja.                          }
{******************************************************************************}
unit inLibFaseCobroPersistenciaIntf;

interface

uses
  Data.DB;

type
  TAmbitoCanjeVale = (acvTodos, acvAlmacen, acvCaja);

  TRestriccionCanjeVale = record
    Ambito: TAmbitoCanjeVale;
    Empresa: string;
    Almacen: string;
    Caja: string;
    class function Crear(const AValor, AEmpresa, AAlmacen,
      ACaja: string): TRestriccionCanjeVale; static;
    function Permite(const AEmpresa, AAlmacen, ACaja: string): Boolean;
    function MensajeRechazo(const ACodigo, AEmpresa, AAlmacen,
      ACaja: string): string;
  end;

  TSeriesFaseCobro = TArray<string>;

  TSolicitudSeriesFaseCobro = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    Subtipo: string;
    Fecha: TDateTime;
  end;

  TResumenNumeracionFaseCobro = record
    Filas: Int64;
    Minimo: Int64;
    Maximo: Int64;
    Longitud: Integer;
    ExistentesNumero: Int64;
  end;

  TClienteFaseCobro = record
    Nombre: string;
    Email: string;
    PermiteDeuda: Boolean;
    EsClienteVarios: Boolean;
    LimiteCredito: Currency;
    DeudaActual: Currency;
  end;

  TValeOrigenFaseCobro = record
    Codigo: string;
    Importe: Currency;
  end;

  // Vales del ticket de origen de una devolución o rectificación (FZ-363)
  TValesOrigenFaseCobro = record
    // Lo pagado con vales en el origen que aún no se ha devuelto en vale
    ImporteCanjeado: Currency;
    CodigoValeCanjeado: string;
    // Vales emitidos por el origen que siguen pendientes de canje
    ValesPendientes: TArray<TValeOrigenFaseCobro>;
  end;

  IResultadoConsultaFaseCobro = interface
    ['{B113484C-65F7-4E4A-9CED-8538A80AF0CD}']
    function DataSet: TDataSet;
  end;

  IRepositorioFaseCobro = interface
    ['{D42F6F1C-8476-483A-9623-FB493B519C9D}']
    function ListarSeries(
      const ASolicitud: TSolicitudSeriesFaseCobro
    ): TSeriesFaseCobro;
    function ObtenerResumenNumeracion(
      const ACodigoEmpresa, ASerie: string;
      ANumero: Int64
    ): TResumenNumeracionFaseCobro;
    function ConsultarFormasPago: IResultadoConsultaFaseCobro;
    function ObtenerCliente(
      const ACodigoCliente: string;
      out ACliente: TClienteFaseCobro
    ): Boolean;
    function ExisteValePendiente(
      const ACodigoVale: string;
      const ARestriccion: TRestriccionCanjeVale;
      out AMensaje: string
    ): Boolean;
    function ConsultarValesOrigen(
      const AEmpresa, ASerie, ANumero: string
    ): TValesOrigenFaseCobro;
  end;

implementation

uses
  System.SysUtils, inLibErroresBBDD, inLibMsgCaja;

class function TRestriccionCanjeVale.Crear(const AValor, AEmpresa,
  AAlmacen, ACaja: string): TRestriccionCanjeVale;
var
  sValor: string;
begin
  Result := Default(TRestriccionCanjeVale);
  sValor := UpperCase(Trim(AValor));
  if (sValor = '') or (sValor = 'TODOS') then
    Result.Ambito := acvTodos
  else if sValor = 'ALMACEN' then
    Result.Ambito := acvAlmacen
  else if sValor = 'CAJA' then
    Result.Ambito := acvCaja
  else
    raise EValidacionBBDD.Create(SErrorAmbitoCanjeValeNoValido);
  Result.Empresa := Trim(AEmpresa);
  Result.Almacen := Trim(AAlmacen);
  Result.Caja := Trim(ACaja);
  if (Result.Ambito <> acvTodos) and
     ((Result.Empresa = '') or (Result.Almacen = '') or
      ((Result.Ambito = acvCaja) and (Result.Caja = ''))) then
    raise EValidacionBBDD.Create(SErrorUbicacionCanjeValeNoConfigurada);
end;

function TRestriccionCanjeVale.Permite(const AEmpresa, AAlmacen,
  ACaja: string): Boolean;
begin
  Result := (Ambito = acvTodos) or
    (SameText(Trim(AEmpresa), Empresa) and
     SameText(Trim(AAlmacen), Almacen) and
     ((Ambito = acvAlmacen) or SameText(Trim(ACaja), Caja)));
end;

function TRestriccionCanjeVale.MensajeRechazo(const ACodigo,
  AEmpresa, AAlmacen, ACaja: string): string;
var
  sAmbito: string;
begin
  sAmbito := SCanjeValeMismoAlmacen;
  if Ambito = acvCaja then
    sAmbito := SCanjeValeMismaCaja;
  Result := Format(SErrorValeFueraAmbitoCaja,
    [ACodigo, AEmpresa, AAlmacen, ACaja, sAmbito]);
end;

end.

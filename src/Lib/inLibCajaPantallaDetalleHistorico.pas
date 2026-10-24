{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaPantallaDetalleHistorico                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Modelo puro de pestañas y columnas del detalle histórico de Caja.        }
{******************************************************************************}
unit inLibCajaPantallaDetalleHistorico;

interface

type
  TDatosDetalleCaja = (
    ddcOperacion,
    ddcPagos,
    ddcVales,
    ddcMovimientos,
    ddcCliente,
    ddcDepositos,
    ddcFacturaCabecera,
    ddcFacturaLineas);

  TAccionDetalleCaja = (
    adcIrFactura,
    adcIrCliente,
    adcIrArticulo,
    adcIrDeposito,
    adcIrFormaPago,
    adcIrPagoHistorico,
    adcIrMovimiento,
    adcIrVale,
    adcExportarOperacion);

  TColumnaDetalleCaja = record
    Nombre: string;
    Titulo: string;
    Campo: string;
    Ancho: Integer;
    ClasePropiedades: string;
    Formato: string;
    Visible: Boolean;
    class function Crear(
      const ANombre, ATitulo, ACampo: string;
      AAncho: Integer;
      const AClasePropiedades: string = '';
      const AFormato: string = '';
      AVisible: Boolean = True): TColumnaDetalleCaja; static;
  end;

  TVistaDetalleCaja = record
    Nombre: string;
    Datos: TDatosDetalleCaja;
    MostrarPie: Boolean;
    Altura: Integer;
    Columnas: TArray<TColumnaDetalleCaja>;
    class function Crear(
      const ANombre: string;
      ADatos: TDatosDetalleCaja;
      AMostrarPie: Boolean;
      AAltura: Integer;
      const AColumnas: TArray<TColumnaDetalleCaja>): TVistaDetalleCaja;
      static;
  end;

  TSeccionDetalleCaja = record
    Titulo: string;
    Acciones: TArray<TAccionDetalleCaja>;
    Vistas: TArray<TVistaDetalleCaja>;
    class function Crear(
      const ATitulo: string;
      const AAcciones: TArray<TAccionDetalleCaja>;
      const AVistas: TArray<TVistaDetalleCaja>): TSeccionDetalleCaja;
      static;
  end;

  TModeloFichaDetalleCaja = TArray<TSeccionDetalleCaja>;

function CargarModeloFichaDetalleCaja: TModeloFichaDetalleCaja;

implementation

type
  TCargadorModeloFichaDetalleCaja = class
  private
    class function CargarOperacion: TSeccionDetalleCaja; static;
    class function CargarPagos: TSeccionDetalleCaja; static;
    class function CargarVales: TSeccionDetalleCaja; static;
    class function CargarMovimientos: TSeccionDetalleCaja; static;
    class function CargarCliente: TSeccionDetalleCaja; static;
    class function CargarDepositos: TSeccionDetalleCaja; static;
    class function CargarFactura: TSeccionDetalleCaja; static;
    class function CargarColumnasFacturaCabecera:
      TArray<TColumnaDetalleCaja>; static;
    class function CargarColumnasFacturaLineas:
      TArray<TColumnaDetalleCaja>; static;
  public
    class function Cargar: TModeloFichaDetalleCaja; static;
  end;

class function TColumnaDetalleCaja.Crear(
  const ANombre, ATitulo, ACampo: string;
  AAncho: Integer;
  const AClasePropiedades: string;
  const AFormato: string;
  AVisible: Boolean): TColumnaDetalleCaja;
begin
  Result.Nombre := ANombre;
  Result.Titulo := ATitulo;
  Result.Campo := ACampo;
  Result.Ancho := AAncho;
  Result.ClasePropiedades := AClasePropiedades;
  Result.Formato := AFormato;
  Result.Visible := AVisible;
end;

class function TVistaDetalleCaja.Crear(
  const ANombre: string;
  ADatos: TDatosDetalleCaja;
  AMostrarPie: Boolean;
  AAltura: Integer;
  const AColumnas: TArray<TColumnaDetalleCaja>): TVistaDetalleCaja;
begin
  Result.Nombre := ANombre;
  Result.Datos := ADatos;
  Result.MostrarPie := AMostrarPie;
  Result.Altura := AAltura;
  Result.Columnas := AColumnas;
end;

class function TSeccionDetalleCaja.Crear(
  const ATitulo: string;
  const AAcciones: TArray<TAccionDetalleCaja>;
  const AVistas: TArray<TVistaDetalleCaja>): TSeccionDetalleCaja;
begin
  Result.Titulo := ATitulo;
  Result.Acciones := AAcciones;
  Result.Vistas := AVistas;
end;

class function TCargadorModeloFichaDetalleCaja.CargarOperacion:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistOpeFecha', 'Fecha/Hora',
      'FECHA_OPERACION_OPCAJA', 140, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn:ss'),
    TColumnaDetalleCaja.Crear('colHistOpeTipo', 'Tipo',
      'TIPO_OPERACION_OPCAJA', 60),
    TColumnaDetalleCaja.Crear('colHistOpeImporte', 'Importe',
      'IMPORTE_TOTAL_OPCAJA', 110, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistOpeConcepto', 'Concepto',
      'CONCEPTO_GASTO_INGRESO_OPCAJA', 340),
    TColumnaDetalleCaja.Crear('colHistOpeIdDep', 'Id depósito',
      'ID_DEPOSITO_OPCAJA', 160),
    TColumnaDetalleCaja.Crear('colHistOpeSerieRef', 'Serie ref.',
      'SERIE_REF_ORIGEN_OPCAJA', 80),
    TColumnaDetalleCaja.Crear('colHistOpeNroRef', 'Nro ref.',
      'NUMERO_REF_ORIGEN_OPCAJA', 80),
    TColumnaDetalleCaja.Crear('colHistOpeMotivo', 'Motivo dev.',
      'MOTIVO_DEVOLUCION_OPCAJA', 130),
    TColumnaDetalleCaja.Crear('colHistOpeEstadoDev', 'Est.Dev.',
      'ESTADO_DEVOLUCION_OPCAJA', 60));
  Result := TSeccionDetalleCaja.Crear(
    'Operación',
    TArray<TAccionDetalleCaja>.Create(adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaOperacion', ddcOperacion, False, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.CargarPagos:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistPagLinea', 'Línea',
      'NUMERO_LINEA_PAGO', 96),
    TColumnaDetalleCaja.Crear('colHistPagCodigo', 'Código',
      'CODIGO_FP_CFP', 106),
    TColumnaDetalleCaja.Crear('colHistPagForma', 'Forma de pago',
      'DESCRIPCION_FORMA_PAGO_CFP', 142),
    TColumnaDetalleCaja.Crear('colHistPagEntregado', 'Entregado',
      'IMPORTE_ENTREGADO_PAGO', 146, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistPagCambio', 'Cambio',
      'IMPORTE_CAMBIO_PAGO', 96, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistPagNeto', 'Neto',
      'IMPORTE_NETO_PAGO', 87, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistPagDivisa', 'Divisa',
      'CODIGO_DIVISA_PAGO', 97),
    TColumnaDetalleCaja.Crear('colHistPagImpDivisa', 'Imp.divisa',
      'IMPORTE_DIVISA_PAGO', 150, 'TcxCurrencyEditProperties',
      '#,##0.00000000'),
    TColumnaDetalleCaja.Crear('colHistPagBlockchain', 'Red',
      'RED_BLOCKCHAIN_PAGO', 65),
    TColumnaDetalleCaja.Crear('colHistPagReferencia', 'Referencia',
      'REFERENCIA_FACPAG', 131),
    TColumnaDetalleCaja.Crear('colHistPagObs', 'Observaciones',
      'OBSERVACIONES_PAGO', 180));
  Result := TSeccionDetalleCaja.Crear(
    'Pagos',
    TArray<TAccionDetalleCaja>.Create(
      adcIrPagoHistorico,
      adcIrFormaPago,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaPagos', ddcPagos, True, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.CargarVales:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistValRol', 'Rol', 'ROL_VL', 70),
    TColumnaDetalleCaja.Crear('colHistValCodigo', 'Cód. vale',
      'CODIGO_VL', 180),
    TColumnaDetalleCaja.Crear('colHistValPin', 'PIN',
      'PIN_SEGURIDAD_VL', 70),
    TColumnaDetalleCaja.Crear('colHistValEstado', 'Estado',
      'ESTADO_VL', 110),
    TColumnaDetalleCaja.Crear('colHistValNominal', 'Nominal',
      'IMPORTE_NOMINAL_VL', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistValRedimido', 'Redimido',
      'IMPORTE_REDIMIDO_VL', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistValEmision', 'F. Emisión',
      'FECHA_EMISION_VL', 130, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn'),
    TColumnaDetalleCaja.Crear('colHistValCaducidad', 'F. Caducidad',
      'FECHA_CADUCIDAD_VL', 110, 'TcxDateEditProperties', 'dd/mm/yyyy'),
    TColumnaDetalleCaja.Crear('colHistValRedencion', 'F. Redención',
      'FECHA_REDENCION_VL', 130, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn'),
    TColumnaDetalleCaja.Crear('colHistValPadre', 'Vale padre',
      'CODIGO_PADRE_VL', 140),
    TColumnaDetalleCaja.Crear('colHistValObs', 'Observaciones',
      'OBSERVACIONES_VL', 200));
  Result := TSeccionDetalleCaja.Crear(
    'Vales',
    TArray<TAccionDetalleCaja>.Create(
      adcIrVale,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaVales', ddcVales, True, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.CargarMovimientos:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistMovNum', 'Nº Mov',
      'NUMERO_MOV', 94),
    TColumnaDetalleCaja.Crear('colHistMovTipoDoc', 'Tipo Doc',
      'TIPO_DOC_MOV', 132),
    TColumnaDetalleCaja.Crear('colHistMovLinea', 'Línea',
      'LINEA_MOV', 90),
    TColumnaDetalleCaja.Crear('colHistMovAlmacen', 'Almacén',
      'CODIGO_ALM_MOV', 138),
    TColumnaDetalleCaja.Crear('colHistMovAlmacenContra', 'Contra',
      'CODIGO_ALM_CONTRA_MOV', 112),
    TColumnaDetalleCaja.Crear('colHistMovArticulo', 'Artículo',
      'CODIGO_ART_MOV', 88),
    TColumnaDetalleCaja.Crear('colHistMovSku', 'SKU',
      'CODIGO_UNIDAD_MOV', 126),
    TColumnaDetalleCaja.Crear('colHistMovDesc', 'Descripción',
      'DESCRIPCION_ART', 206),
    TColumnaDetalleCaja.Crear('colHistMovTipo', 'E/S', 'TIPO_MOV', 89),
    TColumnaDetalleCaja.Crear('colHistMovCantidad', 'Cantidad',
      'CANTIDAD_MOV', 91, 'TcxCurrencyEditProperties', '#,##0.00'),
    TColumnaDetalleCaja.Crear('colHistMovPMP', 'PMP',
      'PRECIO_MEDIO_MOV', 80, 'TcxCurrencyEditProperties', '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistMovCoste', 'Total coste',
      'TOTAL_COSTE_MOV', 100, 'TcxCurrencyEditProperties', '#,##0.00 €'));
  Result := TSeccionDetalleCaja.Crear(
    'Movimientos',
    TArray<TAccionDetalleCaja>.Create(
      adcIrMovimiento,
      adcIrArticulo,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaMovimientos', ddcMovimientos, False, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.CargarCliente:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistCliCodigo', 'Código',
      'CODIGO_CLI_CLI', 80),
    TColumnaDetalleCaja.Crear('colHistCliRazon', 'Razón social',
      'RAZON_SOCIAL_CLI', 250),
    TColumnaDetalleCaja.Crear('colHistCliNif', 'NIF', 'NIF_CLI', 100),
    TColumnaDetalleCaja.Crear('colHistCliMovil', 'Móvil',
      'MOVIL_CLI', 100),
    TColumnaDetalleCaja.Crear('colHistCliEmail', 'Email',
      'EMAIL_CLI', 180),
    TColumnaDetalleCaja.Crear('colHistCliDir1', 'Dirección',
      'DIRECCION1_CLI', 200),
    TColumnaDetalleCaja.Crear('colHistCliPobl', 'Población',
      'POBLACION_CLI', 130),
    TColumnaDetalleCaja.Crear('colHistCliProv', 'Provincia',
      'PROVINCIA_CLI', 120),
    TColumnaDetalleCaja.Crear('colHistCliCP', 'C.P.',
      'CODIGO_POSTAL_CLI', 60),
    TColumnaDetalleCaja.Crear('colHistCliDeuda', 'Deuda',
      'TOTAL_DEUDA_CLI', 100, 'TcxCurrencyEditProperties', '#,##0.00 €'));
  Result := TSeccionDetalleCaja.Crear(
    'Cliente',
    TArray<TAccionDetalleCaja>.Create(
      adcIrCliente,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaCliente', ddcCliente, False, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.CargarDepositos:
  TSeccionDetalleCaja;
var
  aColumnas: TArray<TColumnaDetalleCaja>;
begin
  aColumnas := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistDepRol', 'Rol',
      'ROL_EN_OPERACION', 110, '', '', False),
    TColumnaDetalleCaja.Crear('colHistDepEstado', 'Estado',
      'ESTADO_DEP', 130),
    TColumnaDetalleCaja.Crear('colHistDepId', 'Id depósito',
      'ID_DEPOSITO_DEP', 160),
    TColumnaDetalleCaja.Crear('colHistDepCli', 'Cliente',
      'CODIGO_CLI_DEP', 110),
    TColumnaDetalleCaja.Crear('colHistDepArt', 'Artículo',
      'CODIGO_ART_DEP', 141),
    TColumnaDetalleCaja.Crear('colHistDepSku', 'SKU',
      'CODIGO_UNIDAD_DEP', 160),
    TColumnaDetalleCaja.Crear('colHistDepAlm', 'Almacén',
      'CODIGO_ALM_DEP', 91),
    TColumnaDetalleCaja.Crear('colHistDepCant', 'Cantidad pdte.',
      'CANTIDAD_PENDIENTE_DEP', 131, 'TcxCurrencyEditProperties',
      '#,##0.00'),
    TColumnaDetalleCaja.Crear('colHistDepPvp', 'Precio venta',
      'PRECIO_VENTA_DEP', 114, 'TcxCurrencyEditProperties', '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistDepPorcIva', '% IVA',
      'PORCENTAJE_IVA_DEP', 55, 'TcxCurrencyEditProperties', '0.00'),
    TColumnaDetalleCaja.Crear('colHistDepAnt', 'Anticipo',
      'IMPORTE_ANTICIPO_DEP', 90, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistDepPendiente', 'Pendiente',
      'IMPORTE_PENDIENTE_DEP', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistDepFecha', 'Fecha alta',
      'FECHA_CREACION_DEP', 120, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn'),
    TColumnaDetalleCaja.Crear('colHistDepFechaEntrega', 'Fecha entrega',
      'FECHA_ENTREGA_DEP', 146, 'TcxDateEditProperties', 'dd/mm/yyyy'),
    TColumnaDetalleCaja.Crear('colHistDepEmpCancel', 'Emp. cancel.',
      'EMPRESA_CANCEL_DEP', 80, '', '', False),
    TColumnaDetalleCaja.Crear('colHistDepAlmCancel', 'Alm. cancel.',
      'ALMACEN_CANCEL_DEP', 80, '', '', False),
    TColumnaDetalleCaja.Crear('colHistDepCajCancel', 'Caja cancel.',
      'CAJA_CANCEL_DEP', 70, '', '', False),
    TColumnaDetalleCaja.Crear('colHistDepNumOpeCancel', 'Op. cancel.',
      'NUMERO_OPERACION_CANCEL_DEP', 100, '', '', False));
  Result := TSeccionDetalleCaja.Crear(
    'Depósitos',
    TArray<TAccionDetalleCaja>.Create(
      adcIrDeposito,
      adcIrCliente,
      adcIrArticulo,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaDepositos', ddcDepositos, True, 0, aColumnas)));
end;

class function TCargadorModeloFichaDetalleCaja.
  CargarColumnasFacturaCabecera: TArray<TColumnaDetalleCaja>;
begin
  Result := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistFacSerie', 'Serie',
      'SERIE_FAC', 80),
    TColumnaDetalleCaja.Crear('colHistFacNro', 'Nº', 'NUMERO_FAC', 80),
    TColumnaDetalleCaja.Crear('colHistFacFecha', 'Fecha',
      'FECHA_FAC', 100, 'TcxDateEditProperties', 'dd/mm/yyyy'),
    TColumnaDetalleCaja.Crear('colHistFacTipo', 'Tipo', 'TIPO_FAC', 110),
    TColumnaDetalleCaja.Crear('colHistFacCliente', 'Cliente',
      'CODIGO_CLI_FAC', 80),
    TColumnaDetalleCaja.Crear('colHistFacRazon', 'Razón social',
      'RAZON_SOCIAL_CLIENTE_FAC', 220),
    TColumnaDetalleCaja.Crear('colHistFacBases', 'Bases',
      'TOTAL_BASES_FAC', 100, 'TcxCurrencyEditProperties', '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistFacImp', 'Impuestos',
      'TOTAL_IMPUESTOS_FAC', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistFacLiq', 'Líquido',
      'TOTAL_LIQUIDO_FAC', 110, 'TcxCurrencyEditProperties',
      '#,##0.00 €'));
end;

class function TCargadorModeloFichaDetalleCaja.
  CargarColumnasFacturaLineas: TArray<TColumnaDetalleCaja>;
begin
  Result := TArray<TColumnaDetalleCaja>.Create(
    TColumnaDetalleCaja.Crear('colHistFlLinea', 'Lín',
      'LINEA_FACLIN', 50),
    TColumnaDetalleCaja.Crear('colHistFlArt', 'Artículo',
      'CODIGO_ART_FACLIN', 110),
    TColumnaDetalleCaja.Crear('colHistFlSku', 'SKU',
      'CODIGO_UNIDAD_FACLIN', 160),
    TColumnaDetalleCaja.Crear('colHistFlDesc', 'Descripción',
      'DESCRIPCION_ARTICULO_FACLIN', 280),
    TColumnaDetalleCaja.Crear('colHistFlCant', 'Cant.',
      'CANTIDAD_FACLIN', 70, 'TcxCurrencyEditProperties', '#,##0.00'),
    TColumnaDetalleCaja.Crear('colHistFlPrSiva', 'P.S.IVA',
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN', 90,
      'TcxCurrencyEditProperties', '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistFlPrCiva', 'P.C.IVA',
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN', 90,
      'TcxCurrencyEditProperties', '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistFlDto', '% Dto',
      'PORCENTAJE_DTO_FACLIN', 60, 'TcxCurrencyEditProperties', '0.00 %'),
    TColumnaDetalleCaja.Crear('colHistFlTipoIva', 'T.IVA',
      'TIPO_IVA_ARTICULO_FACLIN', 50),
    TColumnaDetalleCaja.Crear('colHistFlPorcIva', '% IVA',
      'PORCENTAJE_IVA_FACLIN', 60, 'TcxCurrencyEditProperties', '0.00'),
    TColumnaDetalleCaja.Crear('colHistFlTotSiva', 'Tot. S.IVA',
      'TOTAL_FAC_SIVA_FACLIN', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €'),
    TColumnaDetalleCaja.Crear('colHistFlTotCiva', 'Tot. C.IVA',
      'TOTAL_FACLIN', 100, 'TcxCurrencyEditProperties', '#,##0.00 €'));
end;

class function TCargadorModeloFichaDetalleCaja.CargarFactura:
  TSeccionDetalleCaja;
begin
  Result := TSeccionDetalleCaja.Crear(
    'Borrador',
    TArray<TAccionDetalleCaja>.Create(
      adcIrFactura,
      adcIrCliente,
      adcIrArticulo,
      adcExportarOperacion),
    TArray<TVistaDetalleCaja>.Create(
      TVistaDetalleCaja.Crear(
        'tvHistCajaFacturaCab',
        ddcFacturaCabecera,
        False,
        70,
        CargarColumnasFacturaCabecera),
      TVistaDetalleCaja.Crear(
        'tvHistCajaFacturaLin',
        ddcFacturaLineas,
        False,
        0,
        CargarColumnasFacturaLineas)));
end;

class function TCargadorModeloFichaDetalleCaja.Cargar:
  TModeloFichaDetalleCaja;
begin
  Result := TModeloFichaDetalleCaja.Create(
    CargarOperacion,
    CargarPagos,
    CargarVales,
    CargarMovimientos,
    CargarCliente,
    CargarDepositos,
    CargarFactura);
end;

function CargarModeloFichaDetalleCaja: TModeloFichaDetalleCaja;
begin
  Result := TCargadorModeloFichaDetalleCaja.Cargar;
end;

end.

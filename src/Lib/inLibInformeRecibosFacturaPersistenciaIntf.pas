unit inLibInformeRecibosFacturaPersistenciaIntf;

interface

type
  TCriteriosInformeRecibosFactura = record
    ReciboActual: Boolean;
    Serie: string;
    NumeroFactura: string;
    NumeroRecibo: string;
    // FZ-ISSUE-102.14: recibos de los efectos de cobro de venta mayor
    // (fza_efectos_venta) en vez de fza_recibos. Con ReciboActual se
    // imprimen los efectos de Efectos (CSV de NUMERO_EFV); si no, todos los
    // de la factura.
    EsEfectosVenta: Boolean;
    EsEfectosCompra: Boolean;
    Efectos: string;
  end;

  IPreparadorInformeRecibosFactura = interface
    ['{D76B7E76-267A-47BF-B053-32E7CF0C6391}']
    procedure Preparar(const ACriterios: TCriteriosInformeRecibosFactura);
  end;

implementation

end.

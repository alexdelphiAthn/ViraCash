unit inLibInformeFacturaPersistenciaIntf;

interface

type
  TCriteriosInformeFactura = record
    FacturaActual: Boolean;
    Serie: string;
    Numero: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    // F-LOTEC-016: textos delante del lote, la serie y la caducidad en la
    // descripción impresa de la línea; EtiquetaLote = '' no los imprime.
    EtiquetaLote: string;
    EtiquetaSerie: string;
    EtiquetaCaducidad: string;
  end;

  IPreparadorInformeFactura = interface
    ['{66F296F6-FD03-4172-85E5-2CA49E4C5AF6}']
    procedure Preparar(const ACriterios: TCriteriosInformeFactura);
  end;

implementation

end.

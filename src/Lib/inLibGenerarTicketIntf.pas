unit inLibGenerarTicketIntf;

interface

uses
  inLibGenerarTicketCajaPersistenciaIntf, inLibCajaDatosFactura;

type
  ILecturasImpresionTicket = interface(IGenerarTicketCajaPersistencia)
    ['{5BCB5644-7BB8-4B3A-A14D-0091E7C44B09}']
    function ListarPieCaja(
      const ACodigoEmpresa: string): TArray<string>;
    function ObtenerDiminutivoVendedor(
      const ACodigoEmpleado: string): string;
    function ObtenerCodigoBarras(
      const ASerie, ANumero: string): string;
    // FZ-ISSUE-200: factura rectificada o sustituida por ASerie/ANumero.
    function ObtenerReferenciaRectificacion(
      const ASerie, ANumero: string): TReferenciaRectificacionTicket;
  end;

implementation

end.

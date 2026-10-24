unit inLibContadorLineas;

{
  Tipos y puerto para asignar lineas de documento. La implementacion
  transaccional y el SQL pertenecen al adaptador UniDAC.
}

interface

type
  TInfoContadorLineas = record
    TablaHdr: string;
    ColContador: string;
    ColSerieHdr: string;
    ColNumeroHdr: string;
  end;
  TInfoLineasDoc = record
    TablaLin: string;
    ColSerieLin: string;
    ColNumeroLin: string;
    ColLinea: string;
  end;
  IContadorLineasDocumento = interface
    ['{142185E2-BCE6-49F0-9D92-9FF5DC48F1A5}']
    function GetSiguienteLineaDoc(
      const AInfo: TInfoContadorLineas;
      const ASerie, ANumero: string): Integer;
    function GetSiguienteLineaDocLibre(
      const AInfo: TInfoContadorLineas;
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero: string): Integer;
    function GetSiguienteLineaDocLibreSiguiente(
      const AInfo: TInfoContadorLineas;
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero: string): Integer;
    function LineaDocExiste(
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero, ALinea: string): Boolean;
  end;

const
  CONT_FACTURAS: TInfoContadorLineas = (
    TablaHdr: 'fza_facturas';
    ColContador: 'CONTADOR_LINEAS_FAC';
    ColSerieHdr: 'SERIE_FAC';
    ColNumeroHdr: 'NUMERO_FAC');
  CONT_SESIONES: TInfoContadorLineas = (
    TablaHdr: 'fza_compras_sesiones';
    ColContador: 'CONTADOR_LINEAS_SES';
    ColSerieHdr: 'SERIE_SES';
    ColNumeroHdr: 'NUMERO_SES');
  CONT_PEDIDOS: TInfoContadorLineas = (
    TablaHdr: 'fza_pedidos';
    ColContador: 'CONTADOR_LINEAS_PED';
    ColSerieHdr: 'SERIE_PED';
    ColNumeroHdr: 'NUMERO_PED');
  CONT_PRESUPUESTOS: TInfoContadorLineas = (
    TablaHdr: 'fza_presupuestos';
    ColContador: 'CONTADOR_LINEAS_PRE';
    ColSerieHdr: 'SERIE_PRE';
    ColNumeroHdr: 'NUMERO_PRE');
  LIN_PRESUPUESTOS: TInfoLineasDoc = (
    TablaLin: 'fza_presupuestos_lineas';
    ColSerieLin: 'SERIE_PRE_PRELIN';
    ColNumeroLin: 'NUMERO_PRE_PRELIN';
    ColLinea: 'LINEA_PRELIN');
  CONT_ALBARANES: TInfoContadorLineas = (
    TablaHdr: 'fza_albaranes';
    ColContador: 'CONTADOR_LINEAS_ALB';
    ColSerieHdr: 'SERIE_ALB';
    ColNumeroHdr: 'NUMERO_ALB');
  CONT_ALBARANES_COMPRA: TInfoContadorLineas = (
    TablaHdr: 'fza_albaranes_compra';
    ColContador: 'CONTADOR_LINEAS_ALBC';
    ColSerieHdr: 'SERIE_ALBC';
    ColNumeroHdr: 'NUMERO_ALBC');
  CONT_PEDIDOS_COMPRA: TInfoContadorLineas = (
    TablaHdr: 'fza_pedidos_compra';
    ColContador: 'CONTADOR_LINEAS_PEDC';
    ColSerieHdr: 'SERIE_PEDC';
    ColNumeroHdr: 'NUMERO_PEDC');
  CONT_DEVOLUCIONES_COMPRA: TInfoContadorLineas = (
    TablaHdr: 'fza_devoluciones_compra';
    ColContador: 'CONTADOR_LINEAS_DEVC';
    ColSerieHdr: 'SERIE_DEVC';
    ColNumeroHdr: 'NUMERO_DEVC');
  CONT_FACTURAS_COMPRA: TInfoContadorLineas = (
    TablaHdr: 'fza_facturas_compra';
    ColContador: 'CONTADOR_LINEAS_FACC';
    ColSerieHdr: 'SERIE_FACC';
    ColNumeroHdr: 'NUMERO_FACC');
  LIN_FACTURAS: TInfoLineasDoc = (
    TablaLin: 'fza_facturas_lineas';
    ColSerieLin: 'SERIE_FAC_FACLIN';
    ColNumeroLin: 'NUMERO_FAC_FACLIN';
    ColLinea: 'LINEA_FACLIN');
  LIN_PEDIDOS: TInfoLineasDoc = (
    TablaLin: 'fza_pedidos_lineas';
    ColSerieLin: 'SERIE_PED_PEDLIN';
    ColNumeroLin: 'NUMERO_PED_PEDLIN';
    ColLinea: 'LINEA_PEDLIN');
  LIN_ALBARANES: TInfoLineasDoc = (
    TablaLin: 'fza_albaranes_lineas';
    ColSerieLin: 'SERIE_ALB_ALBLIN';
    ColNumeroLin: 'NUMERO_ALB_ALBLIN';
    ColLinea: 'LINEA_ALBLIN');
  LIN_ALBARANES_COMPRA: TInfoLineasDoc = (
    TablaLin: 'fza_albaranes_compra_lineas';
    ColSerieLin: 'SERIE_ALBC_ALBCLIN';
    ColNumeroLin: 'NUMERO_ALBC_ALBCLIN';
    ColLinea: 'LINEA_ALBCLIN');
  LIN_PEDIDOS_COMPRA: TInfoLineasDoc = (
    TablaLin: 'fza_pedidos_compra_lineas';
    ColSerieLin: 'SERIE_PEDC_PEDCLIN';
    ColNumeroLin: 'NUMERO_PEDC_PEDCLIN';
    ColLinea: 'LINEA_PEDCLIN');
  LIN_DEVOLUCIONES_COMPRA: TInfoLineasDoc = (
    TablaLin: 'fza_devoluciones_compra_lineas';
    ColSerieLin: 'SERIE_DEVC_DEVCLIN';
    ColNumeroLin: 'NUMERO_DEVC_DEVCLIN';
    ColLinea: 'LINEA_DEVCLIN');
  LIN_FACTURAS_COMPRA: TInfoLineasDoc = (
    TablaLin: 'fza_facturas_compra_lineas';
    ColSerieLin: 'SERIE_FACC_FACCLIN';
    ColNumeroLin: 'NUMERO_FACC_FACCLIN';
    ColLinea: 'LINEA_FACCLIN');

function GetSiguienteLineaDoc(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ASerie, ANumero: string): Integer;
function GetSiguienteLineaDocLibre(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
function GetSiguienteLineaDocLibreSiguiente(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
function LineaDocExiste(
  const AContador: IContadorLineasDocumento;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero, ALinea: string): Boolean;

implementation

function GetSiguienteLineaDoc(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ASerie, ANumero: string): Integer;
begin
  Result := 0;
  if AContador <> nil then
    Result := AContador.GetSiguienteLineaDoc(AInfo, ASerie, ANumero);
end;

function GetSiguienteLineaDocLibre(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
begin
  Result := 0;
  if AContador <> nil then
    Result := AContador.GetSiguienteLineaDocLibre(
      AInfo,
      ALineas,
      ASerie,
      ANumero);
end;

function GetSiguienteLineaDocLibreSiguiente(
  const AContador: IContadorLineasDocumento;
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
begin
  Result := 0;
  if AContador <> nil then
    Result := AContador.GetSiguienteLineaDocLibreSiguiente(
      AInfo,
      ALineas,
      ASerie,
      ANumero);
end;

function LineaDocExiste(
  const AContador: IContadorLineasDocumento;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero, ALinea: string): Boolean;
begin
  Result := False;
  if AContador <> nil then
    Result := AContador.LineaDocExiste(
      ALineas,
      ASerie,
      ANumero,
      ALinea);
end;

end.

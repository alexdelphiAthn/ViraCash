unit inLibArticulosCodigosBarras;

{
  Generación de códigos de barras por SKU sin principal.
  Las ejecuciones posteriores respetan los códigos existentes.
}

interface

uses
  inLibArticulosVariacionesIntf,
  inLibArticulosCodigosBarrasPersistenciaIntf;

type
  TResultadoCodigosBarrasArticulo = record
    PrincipalesGenerados: Integer;
    FilasFabricanteCreadas: Integer;
    SkusSinCambios: Integer;
    MarcadoresAntiguosEliminados: Integer;
  end;

function GenerarCodigosBarrasArticulo(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;

function CrearCodigoBarrasInterno(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AUsuario: string): string;

implementation

uses
  System.SysUtils,
  inLibArticulosVariaciones,
  inLibEAN13;

const
  cTipoContadorCodigoBarras = 'BA';
  cPrefijoCodigoBarrasInterno = '21';
  cDigitosContadorCodigoBarras = 10;
  cTipoCodigoBarrasInterno = 'EAN13';
  // Tras adelantar el contador el codigo siguiente ya no puede existir;
  // el tercer intento solo cubre un alta simultanea de otro puesto.
  cIntentosCodigoBarrasLibre = 3;

function NormalizarContadorCodigoBarras(
  const AContador: string): string;
begin
  if Length(AContador) > cDigitosContadorCodigoBarras then
    Result := Copy(
      AContador,
      Length(AContador) - cDigitosContadorCodigoBarras + 1,
      cDigitosContadorCodigoBarras)
  else
    Result := StringOfChar(
      '0',
      cDigitosContadorCodigoBarras - Length(AContador)) +
      AContador;
end;

function CrearCodigoBarrasInterno(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AUsuario: string): string;
var
  iIntento: Integer;
  sCodigoBase: string;
  sContador: string;
begin
  // Las sesiones de compra numeran sus EAN internos a partir de los
  // codigos existentes y no mueven este contador: si el numero que toca
  // ya esta usado, el contador salta por encima de todos ellos
  // (FZ-ISSUE-448).
  iIntento := 0;
  repeat
    if iIntento > 0 then
      APersistencia.AdelantarContador(
        cTipoContadorCodigoBarras, cPrefijoCodigoBarrasInterno,
        cDigitosContadorCodigoBarras, AUsuario);
    sContador := APersistencia.ObtenerSiguienteContador(
      cTipoContadorCodigoBarras, AUsuario);
    sContador := NormalizarContadorCodigoBarras(sContador);
    sCodigoBase := cPrefijoCodigoBarrasInterno + sContador;
    Result := sCodigoBase + CalcularDigitoEAN13(sCodigoBase);
    Inc(iIntento);
  until (iIntento >= cIntentosCodigoBarrasLibre) or
    not APersistencia.ExisteCodigoBarras(Result);
end;

function GenerarCodigosBarrasArticulo(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;
var
  aSkus: TArray<TEstadoCodigoBarrasSku>;
  bTransaccionPropia: Boolean;
  iIndice: Integer;
  sCodigoBarras: string;
begin
  Result := False;
  AResultado := Default(TResultadoCodigosBarrasArticulo);
  if (Trim(ACodigoArticulo) <> '') and Assigned(APersistencia) then
  begin
    bTransaccionPropia := not APersistencia.EnTransaccion;
    if bTransaccionPropia then
      APersistencia.IniciarTransaccion;
    try
      AsegurarSkuArticuloActivo(
        AArticulosVariaciones, ACodigoArticulo, AUsuario);
      AResultado.MarcadoresAntiguosEliminados :=
        APersistencia.EliminarMarcadoresAntiguos(ACodigoArticulo);
      aSkus := APersistencia.ConsultarSkusActivos(ACodigoArticulo);
      Result := Length(aSkus) > 0;
      for iIndice := 0 to High(aSkus) do
      begin
        if not aSkus[iIndice].TienePrincipal then
        begin
          sCodigoBarras := CrearCodigoBarrasInterno(
            APersistencia, AUsuario);
          APersistencia.InsertarCodigoPrincipal(
            aSkus[iIndice].CodigoSku, sCodigoBarras,
            cTipoCodigoBarrasInterno, AUsuario);
          Inc(AResultado.PrincipalesGenerados);
        end
        else
          Inc(AResultado.SkusSinCambios);
      end;
      if Result then
      begin
        if bTransaccionPropia and APersistencia.EnTransaccion then
          APersistencia.ConfirmarTransaccion;
      end
      else if bTransaccionPropia and APersistencia.EnTransaccion then
        APersistencia.RevertirTransaccion;
    except
      if bTransaccionPropia and APersistencia.EnTransaccion then
        APersistencia.RevertirTransaccion;
      raise;
    end;
  end;
end;

end.

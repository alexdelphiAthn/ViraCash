{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidoOcr                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura del JSON de pedidos producido por el extractor OCR Delphi.        }
{    Consolida líneas equivalentes y conserva las referencias a fotos y TIFF.  }
{******************************************************************************}
unit inLibPedidoOcr;

interface

type
  TTallaPedidoOcr = record
    Talla: string;
    Cantidad: Double;
  end;
  TTallasPedidoOcr = TArray<TTallaPedidoOcr>;
  TLineaPedidoOcr = record
    Modelo: string;
    Descripcion: string;
    Color: string;
    ColorDetectado: string;
    CodigoFoto: string;
    FotoAusente: Boolean;
    Tallas: TTallasPedidoOcr;
    Cantidad: Double;
    PrecioCompra: Double;
    Pvp: Double;
    TienePvp: Boolean;
    Moneda: string;
  end;
  TLineasPedidoOcr = TArray<TLineaPedidoOcr>;
  TPedidoOcr = record
    RazonSocialProveedor: string;
    ReferenciaDocumento: string;
    FechaPedido: string;
    FechaTope: string;
    TieneValidacion: Boolean;
    Cuadra: Boolean;
    RequiereRevision: Boolean;
    AdvertenciasValidacion: string;
    InferenciasValidacion: string;
    Lineas: TLineasPedidoOcr;
    PaginasOriginales: TArray<string>;
    FicheroJson: string;
  end;
  TLectorPedidoOcr = class
  private
    class function LeerTextoSeguro(AObjeto: TObject;
      const AClave: string): string; static;
    class function LeerBooleanoSeguro(AObjeto: TObject;
      const AClave: string; ADefecto: Boolean): Boolean; static;
    class function LeerListaTextos(AObjeto: TObject;
      const AClave: string): string; static;
    class function LeerInferencias(AObjeto: TObject): string; static;
    class procedure LeerValidacion(AObjeto: TObject;
      var APedido: TPedidoOcr); static;
    class function LeerLinea(AObjeto: TObject): TLineaPedidoOcr; static;
    class function SonEquivalentes(const APrimera,
      ASegunda: TLineaPedidoOcr): Boolean; static;
    class procedure SumarTalla(var ALinea: TLineaPedidoOcr;
      const ATalla: TTallaPedidoOcr); static;
    class procedure AnadirOConsolidar(var ALineas: TLineasPedidoOcr;
      const ALinea: TLineaPedidoOcr); static;
    class procedure CompletarFotosPorModelo(
      var ALineas: TLineasPedidoOcr); static;
  public
    class function Cargar(const AFicheroJson: string): TPedidoOcr; static;
  end;

function NormalizarTallaPedido(const ATalla: string): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Math,
  System.Generics.Collections,
  inLibJsonSeguro;

resourcestring
  SOrigenTotalLineaCeldaPedidoOcr =
    'total de línea y celda OCR fusionada';
  SOrigenTotalPedidoCeldaPedidoOcr =
    'total del pedido y celda OCR fusionada';
  SOrigenInferenciaPedidoOcr = 'inferencia OCR';
  SFormatoInferenciaPedidoOcr =
    'Línea %s, modelo %s, color %s, talla %s: cantidad %s (%s).';
  SErrorJsonPedidoOcrObjetoInvalido =
    'El fichero no contiene un objeto JSON válido.';
  SErrorBloqueValidacionPedidoOcrInvalido =
    'El bloque de validación del OCR no contiene un objeto válido.';
  SErrorVerificacionCantidadesPedidoOcr =
    'El extractor no pudo verificar las cantidades e importes.';
  SErrorValidacionPedidoOcr =
    'El OCR no ha superado la validación del pedido.' + sLineBreak + '%s';
  SErrorJsonPedidoOcrNoExiste = 'No existe el JSON del pedido: %s';
  SErrorJsonPedidoOcrSinDetalle =
    'El JSON no contiene el array detalle.';
  SErrorPedidoOcrSinLineasImportables =
    'El pedido no contiene líneas importables.';

function NormalizarTallaPedido(const ATalla: string): string;
var
  cCaracter: Char;
  iCaracter: Integer;
begin
  Result := '';
  for iCaracter := 1 to Length(ATalla) do
  begin
    cCaracter := UpCase(ATalla[iCaracter]);
    if not CharInSet(cCaracter, [#9, #10, #13, ' ']) then
    begin
      if cCaracter = ',' then
        Result := Result + '.'
      else
        Result := Result + cCaracter;
    end;
  end;
end;

class function TLectorPedidoOcr.LeerTextoSeguro(AObjeto: TObject;
  const AClave: string): string;
var
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result := '';
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    oValor := oJson.GetValue(AClave);
    if Assigned(oValor) and (not (oValor is TJSONNull)) then
      Result := Trim(oValor.Value);
  end;
end;

class function TLectorPedidoOcr.LeerBooleanoSeguro(AObjeto: TObject;
  const AClave: string; ADefecto: Boolean): Boolean;
var
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result := ADefecto;
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    oValor := oJson.GetValue(AClave);
    if oValor is TJSONBool then
      Result := TJSONBool(oValor).AsBoolean;
  end;
end;

class function TLectorPedidoOcr.LeerListaTextos(AObjeto: TObject;
  const AClave: string): string;
var
  iValor: Integer;
  oJson: TJSONObject;
  oLista: TJSONArray;
  oTextos: TStringList;
  oValor: TJSONValue;
  sTexto: string;
begin
  Result := '';
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    if oJson.GetValue(AClave) is TJSONArray then
    begin
      oLista := TJSONArray(oJson.GetValue(AClave));
      oTextos := TStringList.Create;
      try
        for iValor := 0 to oLista.Count - 1 do
        begin
          oValor := oLista.Items[iValor];
          if Assigned(oValor) and (not (oValor is TJSONNull)) and
             (not (oValor is TJSONObject)) and
             (not (oValor is TJSONArray)) then
          begin
            sTexto := Trim(oValor.Value);
            if sTexto <> '' then
              oTextos.Add(sTexto);
          end;
        end;
        Result := Trim(oTextos.Text);
      finally
        oTextos.Free;
      end;
    end;
  end;
end;

class function TLectorPedidoOcr.LeerInferencias(
  AObjeto: TObject): string;
var
  iInferencia: Integer;
  oInferencia: TJSONObject;
  oInferencias: TJSONArray;
  oJson: TJSONObject;
  oTextos: TStringList;
  sCantidad: string;
  sColor: string;
  sLinea: string;
  sModelo: string;
  sOrigen: string;
  sTalla: string;
begin
  Result := '';
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    if oJson.GetValue('inferencias') is TJSONArray then
    begin
      oInferencias := TJSONArray(oJson.GetValue('inferencias'));
      oTextos := TStringList.Create;
      try
        for iInferencia := 0 to oInferencias.Count - 1 do
        begin
          if oInferencias.Items[iInferencia] is TJSONObject then
          begin
            oInferencia := TJSONObject(oInferencias.Items[iInferencia]);
            sLinea := LeerTextoSeguro(oInferencia, 'linea');
            sModelo := LeerTextoSeguro(oInferencia, 'modelo');
            sColor := LeerTextoSeguro(oInferencia, 'color');
            sTalla := LeerTextoSeguro(oInferencia, 'talla');
            sCantidad := LeerTextoSeguro(oInferencia, 'cantidad');
            sOrigen := LeerTextoSeguro(oInferencia, 'origen');
            if SameText(sOrigen, 'total_linea_y_celda_ocr_fusionada') then
              sOrigen := SOrigenTotalLineaCeldaPedidoOcr
            else if SameText(
              sOrigen, 'total_pedido_y_celda_ocr_fusionada') then
              sOrigen := SOrigenTotalPedidoCeldaPedidoOcr;
            if sLinea = '' then
              sLinea := '?';
            if sModelo = '' then
              sModelo := '?';
            if sColor = '' then
              sColor := '?';
            if sTalla = '' then
              sTalla := '?';
            if sCantidad = '' then
              sCantidad := '?';
            if sOrigen = '' then
              sOrigen := SOrigenInferenciaPedidoOcr;
            oTextos.Add(Format(SFormatoInferenciaPedidoOcr,
              [sLinea, sModelo, sColor, sTalla, sCantidad, sOrigen]));
          end;
        end;
        Result := Trim(oTextos.Text);
      finally
        oTextos.Free;
      end;
    end;
  end;
end;

class procedure TLectorPedidoOcr.LeerValidacion(AObjeto: TObject;
  var APedido: TPedidoOcr);
var
  oRaiz: TJSONObject;
  oValidacion: TJSONObject;
  oValor: TJSONValue;
  sMotivo: string;
begin
  if not (AObjeto is TJSONObject) then
    raise Exception.Create(SErrorJsonPedidoOcrObjetoInvalido);
  oRaiz := TJSONObject(AObjeto);
  oValor := oRaiz.GetValue('validacion');
  if Assigned(oValor) then
  begin
    APedido.TieneValidacion := True;
    if not (oValor is TJSONObject) then
      raise Exception.Create(SErrorBloqueValidacionPedidoOcrInvalido);
    oValidacion := TJSONObject(oValor);
    APedido.Cuadra := LeerBooleanoSeguro(oValidacion, 'cuadra', False);
    APedido.RequiereRevision := LeerBooleanoSeguro(
      oValidacion, 'requiere_revision', False);
    APedido.AdvertenciasValidacion := LeerListaTextos(
      oValidacion, 'advertencias');
    APedido.InferenciasValidacion := LeerInferencias(oValidacion);
    if not APedido.Cuadra then
    begin
      sMotivo := Trim(APedido.AdvertenciasValidacion);
      if sMotivo = '' then
        sMotivo := SErrorVerificacionCantidadesPedidoOcr;
      raise Exception.Create(Format(SErrorValidacionPedidoOcr, [sMotivo]));
    end;
  end;
end;

class function TLectorPedidoOcr.LeerLinea(
  AObjeto: TObject): TLineaPedidoOcr;
var
  iTalla: Integer;
  oJson: TJSONObject;
  oListaTallas: TJSONArray;
  oTalla: TJSONObject;
  oValorFotoAusente: TJSONValue;
  oValorPvp: TJSONValue;
  TallaLeida: TTallaPedidoOcr;
begin
  Result := Default(TLineaPedidoOcr);
  if AObjeto is TJSONObject then
  begin
    oJson := TJSONObject(AObjeto);
    Result.Modelo := LeerTextoSeguro(oJson, 'modelo');
    Result.Descripcion := LeerTextoSeguro(oJson, 'descripcion');
    Result.Color := LeerTextoSeguro(oJson, 'color');
    Result.ColorDetectado := LeerTextoSeguro(
      oJson, 'color_detectado');
    Result.CodigoFoto := LeerTextoSeguro(oJson, 'codigo_foto');
    oValorFotoAusente := oJson.GetValue('foto_ausente');
    Result.FotoAusente := (oValorFotoAusente is TJSONBool) and
      TJSONBool(oValorFotoAusente).AsBoolean;
    Result.PrecioCompra := JsonDoubleODefecto(
      oJson, 'precio_unitario', 0);
    Result.Pvp := JsonDoubleODefecto(oJson, 'pvp', 0);
    oValorPvp := oJson.GetValue('pvp');
    Result.TienePvp := Assigned(oValorPvp) and
      (not (oValorPvp is TJSONNull)) and (Result.Pvp > 0);
    Result.Moneda := LeerTextoSeguro(oJson, 'moneda');
    if oJson.GetValue('tallas') is TJSONArray then
    begin
      oListaTallas := TJSONArray(oJson.GetValue('tallas'));
      for iTalla := 0 to oListaTallas.Count - 1 do
      begin
        if oListaTallas.Items[iTalla] is TJSONObject then
        begin
          oTalla := TJSONObject(oListaTallas.Items[iTalla]);
          TallaLeida := Default(TTallaPedidoOcr);
          TallaLeida.Talla := LeerTextoSeguro(oTalla, 'talla');
          TallaLeida.Cantidad := JsonDoubleODefecto(
            oTalla, 'cantidad', 0);
          SumarTalla(Result, TallaLeida);
        end;
      end;
    end;
  end;
end;

class function TLectorPedidoOcr.SonEquivalentes(
  const APrimera, ASegunda: TLineaPedidoOcr): Boolean;
begin
  Result := SameText(Trim(APrimera.Modelo), Trim(ASegunda.Modelo)) and
    SameText(Trim(APrimera.Color), Trim(ASegunda.Color)) and
    SameValue(APrimera.PrecioCompra, ASegunda.PrecioCompra, 0.000001) and
    (APrimera.TienePvp = ASegunda.TienePvp);
  if Result and APrimera.TienePvp then
    Result := SameValue(APrimera.Pvp, ASegunda.Pvp, 0.000001);
end;

class procedure TLectorPedidoOcr.SumarTalla(
  var ALinea: TLineaPedidoOcr;
  const ATalla: TTallaPedidoOcr);
var
  bEncontrada: Boolean;
  iTalla: Integer;
  iNueva: Integer;
begin
  bEncontrada := False;
  iTalla := 0;
  while (iTalla <= High(ALinea.Tallas)) and (not bEncontrada) do
  begin
    if NormalizarTallaPedido(ALinea.Tallas[iTalla].Talla) =
       NormalizarTallaPedido(ATalla.Talla) then
    begin
      ALinea.Tallas[iTalla].Cantidad :=
        ALinea.Tallas[iTalla].Cantidad + ATalla.Cantidad;
      bEncontrada := True;
    end;
    Inc(iTalla);
  end;
  if (not bEncontrada) and (Trim(ATalla.Talla) <> '') and
     (ATalla.Cantidad > 0) then
  begin
    iNueva := Length(ALinea.Tallas);
    SetLength(ALinea.Tallas, iNueva + 1);
    ALinea.Tallas[iNueva] := ATalla;
  end;
  ALinea.Cantidad := 0;
  for iTalla := 0 to High(ALinea.Tallas) do
    ALinea.Cantidad := ALinea.Cantidad + ALinea.Tallas[iTalla].Cantidad;
end;

class procedure TLectorPedidoOcr.AnadirOConsolidar(
  var ALineas: TLineasPedidoOcr;
  const ALinea: TLineaPedidoOcr);
var
  bConsolidada: Boolean;
  iLinea: Integer;
  iNueva: Integer;
  iTalla: Integer;
begin
  bConsolidada := False;
  iLinea := 0;
  while (iLinea <= High(ALineas)) and (not bConsolidada) do
  begin
    if SonEquivalentes(ALineas[iLinea], ALinea) then
    begin
      for iTalla := 0 to High(ALinea.Tallas) do
        SumarTalla(ALineas[iLinea], ALinea.Tallas[iTalla]);
      if ALineas[iLinea].CodigoFoto = '' then
        ALineas[iLinea].CodigoFoto := ALinea.CodigoFoto;
      if ALineas[iLinea].CodigoFoto <> '' then
        ALineas[iLinea].FotoAusente := False
      else
        ALineas[iLinea].FotoAusente :=
          ALineas[iLinea].FotoAusente or ALinea.FotoAusente;
      if ALineas[iLinea].Descripcion = '' then
        ALineas[iLinea].Descripcion := ALinea.Descripcion;
      if ALineas[iLinea].ColorDetectado = '' then
        ALineas[iLinea].ColorDetectado := ALinea.ColorDetectado;
      bConsolidada := True;
    end;
    Inc(iLinea);
  end;
  if not bConsolidada then
  begin
    iNueva := Length(ALineas);
    SetLength(ALineas, iNueva + 1);
    ALineas[iNueva] := ALinea;
  end;
end;

class procedure TLectorPedidoOcr.CompletarFotosPorModelo(
  var ALineas: TLineasPedidoOcr);
var
  iLinea: Integer;
  oFotosPorModelo: TDictionary<string, string>;
  sCodigoFoto: string;
  sModelo: string;
begin
  oFotosPorModelo := TDictionary<string, string>.Create;
  try
    for iLinea := 0 to High(ALineas) do
    begin
      sModelo := UpperCase(Trim(ALineas[iLinea].Modelo));
      sCodigoFoto := Trim(ALineas[iLinea].CodigoFoto);
      if (sModelo <> '') and (sCodigoFoto <> '') and
         (not oFotosPorModelo.ContainsKey(sModelo)) then
        oFotosPorModelo.Add(sModelo, sCodigoFoto);
    end;
    for iLinea := 0 to High(ALineas) do
    begin
      if (Trim(ALineas[iLinea].CodigoFoto) = '') and
         (not ALineas[iLinea].FotoAusente) then
      begin
        sModelo := UpperCase(Trim(ALineas[iLinea].Modelo));
        if oFotosPorModelo.TryGetValue(sModelo, sCodigoFoto) then
          ALineas[iLinea].CodigoFoto := sCodigoFoto;
      end;
    end;
  finally
    oFotosPorModelo.Free;
  end;
end;

class function TLectorPedidoOcr.Cargar(
  const AFicheroJson: string): TPedidoOcr;
var
  iLinea: Integer;
  iPagina: Integer;
  oDetalle: TJSONArray;
  oPagina: TJSONValue;
  oPaginas: TJSONArray;
  oProveedor: TJSONObject;
  oRaiz: TJSONObject;
  oValor: TJSONValue;
  LineaLeida: TLineaPedidoOcr;
  sContenido: string;
begin
  Result := Default(TPedidoOcr);
  if not TFile.Exists(AFicheroJson) then
    raise Exception.CreateFmt(
      SErrorJsonPedidoOcrNoExiste, [AFicheroJson]);
  sContenido := TFile.ReadAllText(AFicheroJson, TEncoding.UTF8);
  oValor := TJSONObject.ParseJSONValue(sContenido);
  try
    if not (oValor is TJSONObject) then
      raise Exception.Create(SErrorJsonPedidoOcrObjetoInvalido);
    oRaiz := TJSONObject(oValor);
    Result.FicheroJson := TPath.GetFullPath(AFicheroJson);
    Result.ReferenciaDocumento := LeerTextoSeguro(
      oRaiz, 'referencia_doc');
    Result.FechaPedido := LeerTextoSeguro(oRaiz, 'fecha_pedido');
    Result.FechaTope := LeerTextoSeguro(oRaiz, 'fecha_tope');
    if oRaiz.GetValue('proveedor') is TJSONObject then
    begin
      oProveedor := TJSONObject(oRaiz.GetValue('proveedor'));
      Result.RazonSocialProveedor := LeerTextoSeguro(
        oProveedor, 'razon_social');
    end;
    LeerValidacion(oRaiz, Result);
    if not (oRaiz.GetValue('detalle') is TJSONArray) then
      raise Exception.Create(SErrorJsonPedidoOcrSinDetalle);
    oDetalle := TJSONArray(oRaiz.GetValue('detalle'));
    for iLinea := 0 to oDetalle.Count - 1 do
    begin
      if oDetalle.Items[iLinea] is TJSONObject then
      begin
        LineaLeida := LeerLinea(oDetalle.Items[iLinea]);
        if LineaLeida.Cantidad > 0 then
          AnadirOConsolidar(Result.Lineas, LineaLeida);
      end;
    end;
    CompletarFotosPorModelo(Result.Lineas);
    if Length(Result.Lineas) = 0 then
      raise Exception.Create(SErrorPedidoOcrSinLineasImportables);
    if oRaiz.GetValue('paginas_originales') is TJSONArray then
    begin
      oPaginas := TJSONArray(oRaiz.GetValue('paginas_originales'));
      for iPagina := 0 to oPaginas.Count - 1 do
      begin
        oPagina := oPaginas.Items[iPagina];
        if Assigned(oPagina) and (not (oPagina is TJSONNull)) then
        begin
          SetLength(
            Result.PaginasOriginales,
            Length(Result.PaginasOriginales) + 1);
          Result.PaginasOriginales[
            High(Result.PaginasOriginales)] := oPagina.Value;
        end;
      end;
    end;
  finally
    oValor.Free;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComandoImprimirFacturas                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Interpreta el comando de impresión de facturas y aplica sus reglas de     }
{    autorización sin depender de VCL ni de la persistencia.                   }
{******************************************************************************}
unit inLibComandoImprimirFacturas;

interface

uses
  System.SysUtils;

type
  TReferenciaComandoFactura = record
    Serie: string;
    Numero: string;
    class function Crear(
      const ASerie, ANumero: string
    ): TReferenciaComandoFactura; static;
    // Protocolo interno: debe conservar serie y número separables.
    function Texto: string;
  end;
  TReferenciasComandoFactura = TArray<TReferenciaComandoFactura>;
  TObtenerReferenciasComandoFactura = reference to function:
                                                     TReferenciasComandoFactura;
  TErrorComandoImprimirFacturas = (
    ecifNinguno,
    ecifSintaxis,
    ecifListaVacia,
    ecifReferenciaInvalida,
    ecifReferenciaDuplicada,
    ecifFormato,
    ecifDirectorio
  );
  TSolicitudComandoImprimirFacturas = record
    EsComando: Boolean;
    EsValida: Boolean;
    Error: TErrorComandoImprimirFacturas;
    DetalleError: string;
    Referencias: TReferenciasComandoFactura;
    Formato: string;
    DirectorioDestino: string;
  end;
  TDatosAutorizacionComandoFactura = record
    Existe: Boolean;
    Consolidada: Boolean;
    TipoFactura: string;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
  end;
  TContextoAutorizacionComandoFactura = record
    VerifactuOnline: Boolean;
    PuedeImprimirNormal: Boolean;
    PuedeImprimirSimplificada: Boolean;
    EmpresaRestringida: string;
    AlmacenRestringido: string;
    CajaRestringida: string;
  end;
  TRechazoComandoFactura = (
    rcifNinguno,
    rcifNoEncontrada,
    rcifFueraDeAmbito,
    rcifSinPermiso,
    rcifTipoNoAdmitido,
    rcifNoConsolidada
  );

function EsComandoImprimirFacturas(
  const AParametros: TArray<string>
): Boolean;
function InterpretarComandoImprimirFacturas(
  const AParametros: TArray<string>
): TSolicitudComandoImprimirFacturas;
function SerializarReferenciasComandoFacturas(
  const AReferencias: TReferenciasComandoFactura
): string;
function EvaluarAutorizacionComandoFactura(
  const ADatos: TDatosAutorizacionComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura
): TRechazoComandoFactura;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  inLibLineaComandos;

const
  CONMUTADOR_IMPRIMIR_FACTURAS = 'imprimirfacturas';
  FORMATO_PREDETERMINADO = 'Predeterminado';

class function TReferenciaComandoFactura.Crear(
  const ASerie, ANumero: string): TReferenciaComandoFactura;
begin
  Result.Serie := Trim(ASerie);
  Result.Numero := Trim(ANumero);
end;

function TReferenciaComandoFactura.Texto: string;
begin
  Result := Serie + '\' + Numero;
end;

function SerializarReferenciasComandoFacturas(
  const AReferencias: TReferenciasComandoFactura): string;
var
  iReferencia: Integer;
  oLista: TStringList;
begin
  oLista := TStringList.Create;
  try
    oLista.StrictDelimiter := True;
    oLista.Delimiter := ',';
    for iReferencia := 0 to High(AReferencias) do
      oLista.Add(AReferencias[iReferencia].Texto);
    Result := oLista.DelimitedText;
  finally
    FreeAndNil(oLista);
  end;
end;

function EsComandoImprimirFacturas(
  const AParametros: TArray<string>): Boolean;
begin
  Result := Length(AParametros) > 0;
  if Result then
  begin
    Result := SameText(
      NormalizarConmutador(AParametros[0]),
      CONMUTADOR_IMPRIMIR_FACTURAS);
  end;
end;

function IntentarInterpretarReferencia(
  const ATexto: string;
  out AReferencia: TReferenciaComandoFactura): Boolean;
var
  iSeparador: Integer;
  sTexto: string;
begin
  AReferencia := Default(TReferenciaComandoFactura);
  sTexto := Trim(ATexto);
  iSeparador := LastDelimiter('\/', sTexto);
  if iSeparador = 0 then
    iSeparador := LastDelimiter('.', sTexto);
  Result := (iSeparador > 1) and
            (iSeparador < Length(sTexto));
  if Result then
  begin
    AReferencia := TReferenciaComandoFactura.Crear(
      Copy(sTexto, 1, iSeparador - 1),
      Copy(sTexto, iSeparador + 1, MaxInt));
    Result := (AReferencia.Serie <> '') and
              (AReferencia.Numero <> '') and
              (Pos(',', AReferencia.Serie) = 0) and
              (Pos(',', AReferencia.Numero) = 0);
  end;
end;

function ClaveReferencia(
  const AReferencia: TReferenciaComandoFactura): string;
begin
  Result := UpperCase(AReferencia.Serie) + #1 +
            UpperCase(AReferencia.Numero);
end;

procedure InterpretarReferencias(
  const ALista: string;
  var ASolicitud: TSolicitudComandoImprimirFacturas);
var
  iReferencia: Integer;
  oClaves: TStringList;
  oLista: TStringList;
  oReferencia: TReferenciaComandoFactura;
  sClave: string;
begin
  oLista := TStringList.Create;
  oClaves := TStringList.Create;
  try
    oLista.StrictDelimiter := True;
    oLista.Delimiter := ',';
    oLista.DelimitedText := ALista;
    oClaves.CaseSensitive := False;
    if (oLista.Count = 0) or
       ((oLista.Count = 1) and (Trim(oLista[0]) = '')) then
    begin
      ASolicitud.Error := ecifListaVacia;
    end
    else
    begin
      SetLength(ASolicitud.Referencias, oLista.Count);
      iReferencia := 0;
      while (iReferencia < oLista.Count) and
            (ASolicitud.Error = ecifNinguno) do
      begin
        if not IntentarInterpretarReferencia(
          oLista[iReferencia],
          oReferencia) then
        begin
          ASolicitud.Error := ecifReferenciaInvalida;
          ASolicitud.DetalleError := Trim(oLista[iReferencia]);
        end
        else
        begin
          sClave := ClaveReferencia(oReferencia);
          if oClaves.IndexOf(sClave) >= 0 then
          begin
            ASolicitud.Error := ecifReferenciaDuplicada;
            ASolicitud.DetalleError := oReferencia.Texto;
          end
          else
          begin
            oClaves.Add(sClave);
            ASolicitud.Referencias[iReferencia] := oReferencia;
          end;
        end;
        Inc(iReferencia);
      end;
    end;
  finally
    FreeAndNil(oClaves);
    FreeAndNil(oLista);
  end;
end;

function EsDirectorioAbsoluto(const ARuta: string): Boolean;
var
  bEsRutaUnc: Boolean;
  bEsRutaUnidad: Boolean;
  iInicioRecurso: Integer;
  iSeparador: Integer;
  sRuta: string;

  function EsSeparador(ACaracter: Char): Boolean;
  begin
    Result := CharInSet(ACaracter, ['\', '/']);
  end;

begin
  Result := False;
  sRuta := Trim(ARuta);
  try
    if (sRuta <> '') and TPath.IsPathRooted(sRuta) then
    begin
      // TPath.IsPathRooted también acepta rutas relativas a la unidad actual
      // ("C:facturas") y a la raíz actual ("\facturas"). En segundo plano
      // ambas son ambiguas: solo se admiten unidades con raíz y UNC completas.
      bEsRutaUnidad :=
        (Length(sRuta) >= 3) and
        CharInSet(sRuta[1], ['A'..'Z', 'a'..'z']) and
        (sRuta[2] = ':') and
        EsSeparador(sRuta[3]);
      bEsRutaUnc :=
        (Length(sRuta) >= 5) and
        EsSeparador(sRuta[1]) and
        EsSeparador(sRuta[2]);
      Result := bEsRutaUnidad;
      if (not Result) and bEsRutaUnc then
      begin
        // Una UNC válida contiene al menos servidor y recurso compartido.
        iSeparador := 3;
        while (iSeparador <= Length(sRuta)) and
              not EsSeparador(sRuta[iSeparador]) do
        begin
          Inc(iSeparador);
        end;
        if (iSeparador > 3) and
           (iSeparador <= Length(sRuta)) then
        begin
          while (iSeparador <= Length(sRuta)) and
                EsSeparador(sRuta[iSeparador]) do
          begin
            Inc(iSeparador);
          end;
          iInicioRecurso := iSeparador;
          while (iSeparador <= Length(sRuta)) and
                not EsSeparador(sRuta[iSeparador]) do
          begin
            Inc(iSeparador);
          end;
          Result := iSeparador > iInicioRecurso;
        end;
      end;
    end;
  except
    on E: Exception do
      Result := False;
  end;
end;

function InterpretarComandoImprimirFacturas(
  const AParametros: TArray<string>
): TSolicitudComandoImprimirFacturas;
begin
  Result := Default(TSolicitudComandoImprimirFacturas);
  Result.EsComando := EsComandoImprimirFacturas(AParametros);
  if Result.EsComando then
  begin
    if (Length(AParametros) <> 3) and
       (Length(AParametros) <> 4) then
      Result.Error := ecifSintaxis
    else
    begin
      InterpretarReferencias(AParametros[1], Result);
      if Length(AParametros) = 3 then
      begin
        Result.Formato := FORMATO_PREDETERMINADO;
        Result.DirectorioDestino := Trim(AParametros[2]);
      end
      else
      begin
        Result.Formato := Trim(AParametros[2]);
        if Result.Formato = '' then
          Result.Formato := FORMATO_PREDETERMINADO;
        Result.DirectorioDestino := Trim(AParametros[3]);
      end;
      if (Result.Error = ecifNinguno) and
         not EsDirectorioAbsoluto(Result.DirectorioDestino) then
      begin
        Result.Error := ecifDirectorio;
      end;
    end;
    Result.EsValida := Result.Error = ecifNinguno;
  end;
end;

function CoincideDimension(
  const ARestriccion, AValorDocumento: string): Boolean;
begin
  Result := (Trim(ARestriccion) = '') or
            SameText(Trim(ARestriccion), Trim(AValorDocumento));
end;

function EstaDentroDeAmbito(
  const ADatos: TDatosAutorizacionComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura): Boolean;
begin
  Result :=
    CoincideDimension(
      AContexto.EmpresaRestringida,
      ADatos.CodigoEmpresa) and
    CoincideDimension(
      AContexto.AlmacenRestringido,
      ADatos.CodigoAlmacen) and
    CoincideDimension(
      AContexto.CajaRestringida,
      ADatos.CodigoCaja);
end;

function TienePermisoTipoFactura(
  const ADatos: TDatosAutorizacionComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura): Boolean;
begin
  if SameText(Trim(ADatos.TipoFactura), 'SIMPLIFICADA') then
    Result := AContexto.PuedeImprimirSimplificada
  else if SameText(Trim(ADatos.TipoFactura), 'NORMAL') or
          SameText(Trim(ADatos.TipoFactura), 'RECTIFICATIVA') then
  begin
    Result := AContexto.PuedeImprimirNormal;
  end
  else
    Result := False;
end;

function EsTipoFacturaAdmitido(
  const ATipoFactura: string): Boolean;
begin
  Result := SameText(Trim(ATipoFactura), 'NORMAL') or
            SameText(Trim(ATipoFactura), 'SIMPLIFICADA') or
            SameText(Trim(ATipoFactura), 'RECTIFICATIVA');
end;

function EvaluarAutorizacionComandoFactura(
  const ADatos: TDatosAutorizacionComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura
): TRechazoComandoFactura;
begin
  Result := rcifNinguno;
  if not ADatos.Existe then
    Result := rcifNoEncontrada
  else if not EstaDentroDeAmbito(ADatos, AContexto) then
    Result := rcifFueraDeAmbito
  else if not EsTipoFacturaAdmitido(ADatos.TipoFactura) then
    Result := rcifTipoNoAdmitido
  else if not TienePermisoTipoFactura(ADatos, AContexto) then
    Result := rcifSinPermiso
  else if AContexto.VerifactuOnline and
          not ADatos.Consolidada then
  begin
    Result := rcifNoConsolidada;
  end;
end;

end.

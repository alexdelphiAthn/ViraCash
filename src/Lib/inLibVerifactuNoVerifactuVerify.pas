{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuNoVerifactuVerify                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verificación local de ficheros NO VERI*FACTU exportados por ViraCash.     }
{    Comprueba estructura, cadena de eventos, hashes internos y coherencia     }
{    básica de firmas guardadas, sin invocar procesos externos.                }
{******************************************************************************}
unit inLibVerifactuNoVerifactuVerify;

interface

uses
  System.SysUtils, inLibParametrosIntf;

type
  TResultadoVerificacionNoVerifactu = record
    ArchivoEventos:       string;
    ArchivoFacturacion:   string;
    ModoExportacion:      string;
    Eventos:              Integer;
    RegistrosFacturacion: Integer;
    Errores:              Integer;
    Avisos:               Integer;
    Detalle:              string;
  end;

procedure InferirFicherosNoVerifactu(const AArchivoSeleccionado: string;
                                     out AArchivoEventos,
                                     AArchivoFacturacion: string);
function VerificarFicherosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
function NombreInformeErroresNoVerifactu(const AArchivoSeleccionado: string):
                                      string;
function ResumenVerificacionNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AResultado: TResultadoVerificacionNoVerifactu): string;

implementation

uses
  System.Classes, System.Hash, System.IOUtils, System.NetEncoding,
  System.StrUtils, Xml.XMLDoc, Xml.XMLIntf, inLibMsgFacturas,
  inLibMsgVerifactu, inLibVerifactu,
  inLibVerificacionXadesNoVerifactu;

function NombreLocal(const ANodeName: string): string;
var
  iPos: Integer;
begin
  Result := ANodeName;
  iPos := Pos(':', Result);
  if iPos > 0 then
    Result := Copy(Result, iPos + 1, MaxInt);
end;

function EsNodo(const ANode: IXMLNode; const ANombreLocal: string): Boolean;
begin
  Result := (ANode <> nil) and SameText(NombreLocal(ANode.NodeName),
                                        ANombreLocal);
end;

function BuscarHijo(const ANode: IXMLNode; const ANombreLocal: string):
  IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo;
      Inc(i);
    end;
  end;
end;

function BuscarDescendiente(const ANode: IXMLNode;
                            const ANombreLocal: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo
      else
        Result := BuscarDescendiente(oHijo, ANombreLocal);
      Inc(i);
    end;
  end;
end;

function AtributoNodo(const ANode: IXMLNode;
                      const ANombre: string): string;
var
  oAtributo: IXMLNode;
begin
  Result := '';
  if ANode <> nil then
  begin
    oAtributo := ANode.AttributeNodes.FindNode(ANombre);
    if oAtributo <> nil then
      Result := Trim(oAtributo.Text);
  end;
end;

procedure AgregarDetalle(var AResultado: TResultadoVerificacionNoVerifactu;
                         const ATipo, AMensaje: string); forward;

procedure CapturarModoExportacion(var AResultado:
                                  TResultadoVerificacionNoVerifactu;
                                  const ARaiz: IXMLNode;
                                  const AEtiqueta: string);
var
  sModo: string;
begin
  sModo := UpperCase(Trim(AtributoNodo(ARaiz, 'ModoVerifactu')));
  if sModo <> '' then
  begin
    if AResultado.ModoExportacion = '' then
      AResultado.ModoExportacion := sModo
    else if AResultado.ModoExportacion <> sModo then
      AgregarDetalle(AResultado, STextoTipoError,
        Format(SErrorModoExportacionNoCoincide, [AEtiqueta]));
  end;
end;

function TextoHijo(const ANode: IXMLNode; const ANombreLocal: string): string;
var
  oHijo: IXMLNode;
begin
  Result := '';
  oHijo := BuscarHijo(ANode, ANombreLocal);
  if oHijo <> nil then
    Result := Trim(oHijo.Text);
end;

function CargarXmlArchivo(const AArchivo: string): IXMLDocument;
begin
  Result := TXMLDocument.Create(nil);
  Result.LoadFromFile(AArchivo);
  Result.Active := True;
end;

function CargarXmlTexto(const AXml: string; out ADocumento: IXMLDocument):
  Boolean;
begin
  Result := False;
  ADocumento := nil;
  if Trim(AXml) <> '' then
  begin
    try
      ADocumento := TXMLDocument.Create(nil);
      ADocumento.LoadFromXML(AXml);
      ADocumento.Active := True;
      Result := True;
    except
      ADocumento := nil;
    end;
  end;
end;

function TextoEtiquetaXml(const AXml, ANombreLocal: string): string;
var
  oDoc: IXMLDocument;
  oNodo: IXMLNode;
begin
  Result := '';
  if CargarXmlTexto(AXml, oDoc) then
  begin
    oNodo := BuscarDescendiente(oDoc.DocumentElement, ANombreLocal);
    if oNodo <> nil then
      Result := Trim(oNodo.Text);
  end;
end;

function TextoHuellaEventoPropia(const AXml: string): string;
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oEvento: IXMLNode;
  oHuella: IXMLNode;
begin
  Result := '';
  if CargarXmlTexto(AXml, oDoc) then
  begin
    oRaiz := oDoc.DocumentElement;
    if EsNodo(oRaiz, 'RegistroEvento') then
      oEvento := BuscarHijo(oRaiz, 'Evento')
    else if EsNodo(oRaiz, 'Evento') then
      oEvento := oRaiz
    else
      oEvento := nil;
    oHuella := BuscarHijo(oEvento, 'HuellaEvento');
    if oHuella <> nil then
      Result := Trim(oHuella.Text);
  end;
end;

function VerificacionLegalNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AResultado:
                                      TResultadoVerificacionNoVerifactu):
                                      Boolean;
begin
  if AResultado.ModoExportacion <> '' then
    Result := AResultado.ModoExportacion = cModoVerifactuNoVerifactu
  else
    Result := NoVerifactuActivo(AParametrosApp);
end;

function TipoIncidenciaFirmaLegal(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  const AResultado:
                                  TResultadoVerificacionNoVerifactu): string;
begin
  if VerificacionLegalNoVerifactu(AParametrosApp, AResultado) then
    Result := STextoTipoError
  else
    Result := STextoTipoAviso;
end;

function Sha256HexMayus(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(AValor));
end;

function HexABytes(const AHex: string): TBytes;
var
  i: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for i := 0 to Length(Result) - 1 do
    Result[i] := StrToIntDef('$' + Copy(AHex, (i * 2) + 1, 2), 0);
end;

function Sha256Base64(const AValor: string): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(
    HexABytes(THashSHA2.GetHashString(AValor)));
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function EsHashSha256(const AValor: string): Boolean;
var
  i: Integer;
  sValor: string;
begin
  sValor := UpperCase(Trim(AValor));
  Result := Length(sValor) = 64;
  i := 1;
  while Result and (i <= Length(sValor)) do
  begin
    Result := CharInSet(sValor[i], ['0'..'9', 'A'..'F']);
    Inc(i);
  end;
end;

function HayFirmaXml(const AXml: string): Boolean;
begin
  Result := (Pos('<ds:Signature', AXml) > 0) or
            (Pos('<Signature', AXml) > 0);
end;

procedure AgregarDetalle(var AResultado: TResultadoVerificacionNoVerifactu;
                         const ATipo, AMensaje: string);
begin
  if AResultado.Detalle <> '' then
    AResultado.Detalle := AResultado.Detalle + sLineBreak;
  AResultado.Detalle := AResultado.Detalle +
    Format(SFormatoDetalleVerificacion, [ATipo, AMensaje]);
  if SameText(ATipo, STextoTipoError) then
    Inc(AResultado.Errores)
  else
    Inc(AResultado.Avisos);
end;

procedure VerificarPerfilXadesNoVerifactu(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          const AXml, AEtiqueta: string;
                                          AEsEvento: Boolean;
                                          var AResultado:
                                          TResultadoVerificacionNoVerifactu);
var
  i: Integer;
  oPerfil: TResultadoPerfilXadesNoVerifactu;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  oPerfil := inLibVerificacionXadesNoVerifactu.
    VerificarPerfilXadesNoVerifactu(AXml, AEsEvento);
  for i := 0 to Length(oPerfil.Causas) - 1 do
  begin
    AgregarDetalle(AResultado, sTipoFirma,
      MensajeRechazoXadesNoVerifactu(oPerfil.Causas[i], AEtiqueta));
  end;
end;

procedure VerificarEvento(
                          const AParametrosApp: IParametrosAplicacion;
                          const AEvento: IXMLNode; AIndice: Integer;
                          var AHashAnteriorEsperado: string;
                          var AResultado:
                          TResultadoVerificacionNoVerifactu);
var
  sId: string;
  sHashAnterior: string;
  sHashPropio: string;
  sFirmaDigital: string;
  sRegistroXml: string;
  sFirmaXades: string;
  sHuellaXml: string;
  sSignatureValue: string;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  sId := TextoHijo(AEvento, 'Id');
  sHashAnterior := UpperCase(TextoHijo(AEvento, 'HashAnterior'));
  sHashPropio := UpperCase(TextoHijo(AEvento, 'HashPropio'));
  sFirmaDigital := UpperCase(TextoHijo(AEvento, 'FirmaDigital'));
  sRegistroXml := TextoHijo(AEvento, 'RegistroXmlFirmado');
  sFirmaXades := TextoHijo(AEvento, 'FirmaXades');
  if not EsHashSha256(sHashPropio) then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorEventoHashPropioNoSha256, [sId]));
  if AIndice = 1 then
  begin
    if (sHashAnterior <> '') and
       (sHashAnterior <> StringOfChar('0', 64)) then
      AgregarDetalle(AResultado, STextoTipoAviso,
        Format(SAvisoEventoPrimerHashAnteriorNoCero, [sId]));
  end
  else if sHashAnterior <> AHashAnteriorEsperado then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorEventoHashAnteriorNoCoincide, [sId]));
  if Trim(sRegistroXml) = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      Format(SErrorEventoSinRegistroXmlFirmado, [sId]))
  else
  begin
    sHuellaXml := UpperCase(TextoHuellaEventoPropia(sRegistroXml));
    if (sHuellaXml <> '') and (sHuellaXml <> sHashPropio) then
      AgregarDetalle(AResultado, STextoTipoError,
        Format(SErrorEventoHuellaNoCoincide, [sId]));
    if (sFirmaXades <> '') and (not HayFirmaXml(sRegistroXml)) then
      AgregarDetalle(AResultado, sTipoFirma,
        Format(SErrorEventoFirmaGuardadaSinFirmaXml, [sId]));
    if sFirmaXades = '' then
      AgregarDetalle(AResultado, sTipoFirma,
        Format(SErrorEventoSinFirmaXades, [sId]))
    else
    begin
      sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
      if (sSignatureValue <> '') and (sSignatureValue <> sFirmaXades) then
        AgregarDetalle(AResultado, STextoTipoError,
          Format(SErrorEventoSignatureValueNoCoincide, [sId]));
      if (sFirmaDigital <> '') and
         (sFirmaDigital <> Sha256HexMayus(sFirmaXades)) then
        AgregarDetalle(AResultado, STextoTipoError,
          Format(SErrorEventoFirmaDigitalNoCoincide, [sId]));
      VerificarPerfilXadesNoVerifactu(AParametrosApp, sRegistroXml,
        Format(SFormatoEtiquetaEvento, [sId]), True, AResultado);
    end;
  end;
  AHashAnteriorEsperado := sHashPropio;
end;

procedure VerificarRegistroFactura(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   const ARegistro: IXMLNode; AIndice:
                                   Integer; var AResultado:
                                   TResultadoVerificacionNoVerifactu);
var
  sSerie: string;
  sNumero: string;
  sEtiqueta: string;
  sPeticion: string;
  sRegistroXml: string;
  sHashPeticion: string;
  sHashRegistro: string;
  sFirma: string;
  sSignatureValue: string;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  sSerie := TextoHijo(ARegistro, 'Serie');
  sNumero := TextoHijo(ARegistro, 'Numero');
  sEtiqueta := sSerie + '/' + sNumero;
  if Trim(sEtiqueta) = '/' then
    sEtiqueta := Format(STextoRegistroFacturaIndice, [AIndice]);
  sPeticion := TextoHijo(ARegistro, 'PeticionCompletaXml');
  sRegistroXml := TextoHijo(ARegistro, 'RegistroXmlFirmado');
  sHashPeticion := TextoHijo(ARegistro, 'HashPeticionBase64');
  sHashRegistro := TextoHijo(ARegistro, 'HashRegistroXmlBase64');
  sFirma := TextoHijo(ARegistro, 'FirmaDigitalXades');
  if sPeticion = '' then
    AgregarDetalle(AResultado, STextoTipoAviso,
      Format(SAvisoFacturaSinPeticionCompletaXml, [sEtiqueta]))
  else if sHashPeticion <> Sha256Base64(sPeticion) then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorFacturaHashPeticionNoCoincide, [sEtiqueta]));
  if sRegistroXml = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      Format(SErrorFacturaSinRegistroXmlFirmado, [sEtiqueta]))
  else if sHashRegistro <> Sha256Base64(sRegistroXml) then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorFacturaHashRegistroNoCoincide, [sEtiqueta]));
  if (sFirma <> '') and (not HayFirmaXml(sRegistroXml)) then
    AgregarDetalle(AResultado, sTipoFirma,
      Format(SErrorFacturaGuardadaSinFirmaXml, [sEtiqueta]));
  if sFirma = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      Format(SErrorFacturaSinFirmaDigitalXades, [sEtiqueta]))
  else
  begin
    sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
    if (sSignatureValue <> '') and (sSignatureValue <> sFirma) then
      AgregarDetalle(AResultado, STextoTipoError,
        Format(SErrorFacturaSignatureValueNoCoincide, [sEtiqueta]));
    VerificarPerfilXadesNoVerifactu(AParametrosApp, sRegistroXml,
      Format(SFormatoEtiquetaFactura, [sEtiqueta]), False, AResultado);
  end;
end;

procedure VerificarArchivoEventos(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  var AResultado:
                                  TResultadoVerificacionNoVerifactu);
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oNodo: IXMLNode;
  sHashAnterior: string;
  i: Integer;
begin
  if not TFile.Exists(AResultado.ArchivoEventos) then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorFicheroEventosNoExiste,
        [AResultado.ArchivoEventos]))
  else
  begin
    oDoc := CargarXmlArchivo(AResultado.ArchivoEventos);
    oRaiz := oDoc.DocumentElement;
    CapturarModoExportacion(AResultado, oRaiz, STextoEventos);
    if not EsNodo(oRaiz, 'RegistroEventosNoVerifactu') then
      AgregarDetalle(AResultado, STextoTipoError,
        SErrorFicheroEventosRaizIncorrecta);
    sHashAnterior := '';
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'Evento') then
      begin
        Inc(AResultado.Eventos);
        VerificarEvento(AParametrosApp, oNodo, AResultado.Eventos,
          sHashAnterior, AResultado);
      end;
    end;
    if AResultado.Eventos = 0 then
      AgregarDetalle(AResultado, STextoTipoError,
        SErrorFicheroEventosVacio);
  end;
end;

procedure VerificarArchivoFacturacion(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      var AResultado:
                                      TResultadoVerificacionNoVerifactu);
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oNodo: IXMLNode;
  i: Integer;
begin
  if not TFile.Exists(AResultado.ArchivoFacturacion) then
    AgregarDetalle(AResultado, STextoTipoError,
      Format(SErrorFicheroFacturacionNoExiste,
        [AResultado.ArchivoFacturacion]))
  else
  begin
    oDoc := CargarXmlArchivo(AResultado.ArchivoFacturacion);
    oRaiz := oDoc.DocumentElement;
    CapturarModoExportacion(AResultado, oRaiz, STextoFacturacion);
    if not EsNodo(oRaiz, 'RegistroFacturacionNoVerifactu') then
      AgregarDetalle(AResultado, STextoTipoError,
        SErrorFicheroFacturacionRaizIncorrecta);
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'RegistroFactura') then
      begin
        Inc(AResultado.RegistrosFacturacion);
        VerificarRegistroFactura(AParametrosApp, oNodo,
          AResultado.RegistrosFacturacion, AResultado);
      end;
    end;
    if AResultado.RegistrosFacturacion = 0 then
      AgregarDetalle(AResultado, STextoTipoError,
        SErrorFicheroFacturacionVacio);
  end;
end;

procedure InferirFicherosNoVerifactu(const AArchivoSeleccionado: string;
                                     out AArchivoEventos,
                                     AArchivoFacturacion: string);
var
  sDir: string;
  sNombre: string;
  sBase: string;
begin
  sDir := TPath.GetDirectoryName(AArchivoSeleccionado);
  sNombre := TPath.GetFileNameWithoutExtension(AArchivoSeleccionado);
  if EndsText('_eventos', sNombre) then
    sBase := Copy(sNombre, 1, Length(sNombre) - Length('_eventos'))
  else if EndsText('_facturacion', sNombre) then
    sBase := Copy(sNombre, 1, Length(sNombre) - Length('_facturacion'))
  else
    sBase := sNombre;
  AArchivoEventos := TPath.Combine(sDir, sBase + '_eventos.xml');
  AArchivoFacturacion := TPath.Combine(sDir, sBase + '_facturacion.xml');
end;

function NombreInformeErroresNoVerifactu(const AArchivoSeleccionado: string):
  string;
var
  sDir: string;
  sNombre: string;
begin
  sDir := TPath.GetDirectoryName(AArchivoSeleccionado);
  sNombre := TPath.GetFileName(AArchivoSeleccionado);
  Result := TPath.Combine(sDir, 'errores_' + sNombre + '.txt');
end;

function VerificarFicherosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
begin
  Result.ArchivoEventos := AArchivoEventos;
  Result.ArchivoFacturacion := AArchivoFacturacion;
  Result.ModoExportacion := '';
  Result.Eventos := 0;
  Result.RegistrosFacturacion := 0;
  Result.Errores := 0;
  Result.Avisos := 0;
  Result.Detalle := '';
  try
    VerificarArchivoEventos(AParametrosApp, Result);
  except
    on E: Exception do
      AgregarDetalle(Result, STextoTipoError,
        Format(SErrorVerificarEventos, [E.Message]));
  end;
  try
    VerificarArchivoFacturacion(AParametrosApp, Result);
  except
    on E: Exception do
      AgregarDetalle(Result, STextoTipoError,
        Format(SErrorVerificarFacturacion, [E.Message]));
  end;
  if Result.Detalle = '' then
    Result.Detalle := SInfoVerificacionCorrecta;
end;

function ResumenVerificacionNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AResultado: TResultadoVerificacionNoVerifactu): string;
var
  sModo: string;
begin
  sModo := AResultado.ModoExportacion;
  if sModo = '' then
    sModo := Format(SFormatoModoActual,
      [ModoVerifactuTexto(AParametrosApp)]);
  Result := Format(SResumenVerificacionNoVerifactu,
    [sModo, AResultado.Eventos, AResultado.RegistrosFacturacion,
     AResultado.Errores, AResultado.Avisos]);
end;

end.

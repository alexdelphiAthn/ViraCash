unit inLibFormatoDocumento;

interface

uses
  Data.DB;

const
  FORMATO_DOCUMENTO_DEFECTO = 'Serie.NroDocumento';

function FormatearDocumento(const AFormato, ASerie, ANumero: string): string;
function FormatearMensajeDocumentos(const AFormato, AMensaje: string;
  const AArgumentos: array of const): string;
function FormatearDocumentoDataSet(ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string;
  const ACampoFormato: string = 'FORMATO_DOCUMENTO_EMP'): string;

implementation

uses
  System.SysUtils;

function CampoTexto(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if ADataSet <> nil then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.AsString;
  end;
end;

function TieneTokenDocumento(const AFormato: string): Boolean;
var
  sFormato: string;
begin
  sFormato := LowerCase(AFormato);
  Result := (Pos('serie', sFormato) > 0)
    or (Pos('nrodocumento', sFormato) > 0)
    or (Pos('numerodocumento', sFormato) > 0)
    or (Pos('númerodocumento', sFormato) > 0)
    or (Pos('nrofactura', sFormato) > 0)
    or (Pos('nrodoc', sFormato) > 0)
    or (Pos('numero', sFormato) > 0)
    or (Pos('número', sFormato) > 0);
end;

function ReemplazarTokens(const AFormato, ASerie, ANumero: string): string;
begin
  Result := AFormato;
  Result := StringReplace(Result, 'NroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NumeroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NúmeroDocumento', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NroFactura', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NroDoc', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Numero', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Número', ANumero,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Serie', ASerie,
    [rfReplaceAll, rfIgnoreCase]);
end;

function FormatearDocumento(const AFormato, ASerie, ANumero: string): string;
var
  sFormato: string;
  sNumero: string;
  sSerie: string;
begin
  sSerie := Trim(ASerie);
  sNumero := Trim(ANumero);
  if sSerie = '' then
    Result := sNumero
  else
  begin
    if sNumero = '' then
      Result := sSerie
    else
    begin
      sFormato := Trim(AFormato);
      if (sFormato = '') or not TieneTokenDocumento(sFormato) then
        sFormato := FORMATO_DOCUMENTO_DEFECTO;
      Result := ReemplazarTokens(sFormato, sSerie, sNumero);
    end;
  end;
end;

// Mantiene los argumentos de las traducciones existentes y admite índices
// explícitos: %0:s\%1:s. Cada referencia se compone en un único lugar.
function FormatearMensajeDocumentos(const AFormato, AMensaje: string;
  const AArgumentos: array of const): string;
var
  iPosicion: Integer;
  iSiguienteArgumento: Integer;
  sIndicador: string;
  sSerie: string;
  sNumero: string;

  function LeerIndicador: string;
  var
    iInicio: Integer;
    iDosPuntos: Integer;
    iArgumento: Integer;
    iIndice: Integer;
    sIndicadorOriginal: string;
  begin
    iInicio := iPosicion;
    Inc(iPosicion);
    while (iPosicion <= Length(AMensaje)) and
          not CharInSet(AMensaje[iPosicion],
            ['d', 'u', 'e', 'f', 'g', 'n', 'm', 'p', 's', 'x',
             'D', 'U', 'E', 'F', 'G', 'N', 'M', 'P', 'S', 'X']) do
      Inc(iPosicion);
    sIndicadorOriginal := Copy(AMensaje, iInicio + 1,
      iPosicion - iInicio);
    Inc(iPosicion);
    iDosPuntos := Pos(':', sIndicadorOriginal);
    iArgumento := iSiguienteArgumento;
    if iDosPuntos > 0 then
    begin
      iArgumento := StrToInt(Copy(sIndicadorOriginal, 1, iDosPuntos - 1));
      Delete(sIndicadorOriginal, 1, iDosPuntos);
    end;
    iSiguienteArgumento := iArgumento + 1;
    for iIndice := 1 to Length(sIndicadorOriginal) do
      if sIndicadorOriginal[iIndice] = '*' then
        Inc(iSiguienteArgumento);
    Result := '%' + IntToStr(iArgumento) + ':' + sIndicadorOriginal;
  end;

begin
  Result := '';
  iPosicion := 1;
  iSiguienteArgumento := 0;
  while iPosicion <= Length(AMensaje) do
  begin
    if Copy(AMensaje, iPosicion, 2) = '%%' then
    begin
      Result := Result + '%';
      Inc(iPosicion, 2);
    end
    else if AMensaje[iPosicion] = '%' then
    begin
      sIndicador := LeerIndicador;
      if (iPosicion < Length(AMensaje)) and
         (AMensaje[iPosicion] = '\') and
         (AMensaje[iPosicion + 1] = '%') and
         SameText(Copy(sIndicador, Length(sIndicador), 1), 's') then
      begin
        sSerie := Format(sIndicador, AArgumentos);
        Inc(iPosicion);
        sIndicador := LeerIndicador;
        sNumero := Format(sIndicador, AArgumentos);
        Result := Result + FormatearDocumento(AFormato, sSerie, sNumero);
      end
      else
        Result := Result + Format(sIndicador, AArgumentos);
    end
    else
    begin
      Result := Result + AMensaje[iPosicion];
      Inc(iPosicion);
    end;
  end;
end;

function FormatearDocumentoDataSet(ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string;
  const ACampoFormato: string): string;
var
  sFormato: string;
begin
  sFormato := CampoTexto(ADataSet, ACampoFormato);
  Result := FormatearDocumento(sFormato, CampoTexto(ADataSet, ACampoSerie),
    CampoTexto(ADataSet, ACampoNumero));
end;

end.

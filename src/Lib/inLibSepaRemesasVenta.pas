{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSepaRemesasVenta                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación de órdenes SEPA 19.14 para remesas de venta.                  }
{******************************************************************************}
unit inLibSepaRemesasVenta;

interface

uses
  System.SysUtils;

type
  TResultadoSepaRemesaVenta = record
    Archivo: string;
    NumCobros: Integer;
    Total: Currency;
  end;

  // Datos del dialogo SEPA (acreedor, secuencia y mandatos por
  // cliente). Viven aqui para que UniDataRemesasVenta y el modal los
  // compartan sin que el DM dependa de una unidad inMto*.
  TSepaClienteRemesaVenta = record
    CodigoCliente: string;
    NombreCliente: string;
    IdMandato: string;
    FechaFirma: TDateTime;
  end;

  TListaSepaClientesRemesaVenta = array of TSepaClienteRemesaVenta;

  TDatosSepaRemesaVenta = record
    CodigoAcreedor: string;
    TipoSecuencia: string;
    Clientes: TListaSepaClientesRemesaVenta;
  end;

  TEfectoSepaVentaValidado = record
    IdCobro: string;
    Importe: Currency;
    IdMandato: string;
    FechaFirmaMandato: TDateTime;
    NombreCliente: string;
    IbanCliente: string;
    Concepto: string;
  end;

  TRemesaSepaVentaValidada = record
    IdOrdenante: string;
    NombreEmpresa: string;
    IbanEmpresa: string;
    BicEmpresa: string;
    CodigoAcreedor: string;
    FechaCargo: TDateTime;
    TipoSecuencia: string;
    Efectos: TArray<TEfectoSepaVentaValidado>;
  end;

function GenerarSepaRemesaVenta(
  const ARemesa: TRemesaSepaVentaValidada;
  const AArchivo: string): TResultadoSepaRemesaVenta;
function CalcularCodigoAcreedorSepaEspanol(const ANif: string): string;
function CodigoAcreedorSepaValido(const AValor: string): Boolean;

implementation

uses
  inLibDocumentoFiscal, inLibMsgVentas,
  uDJMSepa1914XML;

function SoloAlfanumerico(const AValor: string): string;
var
  i: Integer;
  sValor: string;
begin
  Result := '';
  sValor := UpperCase(Trim(AValor));
  for i := 1 to Length(sValor) do
  begin
    if CharInSet(sValor[i], ['A'..'Z', '0'..'9']) then
      Result := Result + sValor[i];
  end;
end;

function CadenaSepaADigitos(const AValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := AValor[i];
    if CharInSet(c, ['0'..'9']) then
      Result := Result + c
    else if CharInSet(c, ['A'..'Z']) then
      Result := Result + IntToStr(Ord(c) - Ord('A') + 10);
  end;
end;

function Modulo97(const AValor: string): Integer;
var
  sValor: string;
begin
  Result := 0;
  sValor := AValor;
  while sValor <> '' do
  begin
    Result := StrToIntDef(IntToStr(Result) + Copy(sValor, 1, 6), 0) mod 97;
    Delete(sValor, 1, 6);
  end;
end;

function ValorNoEsTodoCeros(const AValor: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(AValor) do
  begin
    if AValor[i] <> '0' then
      Result := True;
  end;
end;

function DosDigitos(AValor: Integer): string;
begin
  Result := IntToStr(AValor);
  while Length(Result) < 2 do
    Result := '0' + Result;
end;

function CodigoAcreedorSepaValido(const AValor: string): Boolean;
var
  sValor: string;
  sReordenado: string;
begin
  sValor := SoloAlfanumerico(AValor);
  Result := (sValor <> '') and (Length(sValor) <= 35) and
    ValorNoEsTodoCeros(sValor);
  if Result and (Copy(sValor, 1, 2) = 'ES') then
  begin
    if Length(sValor) = 16 then
    begin
      sReordenado := Copy(sValor, 5, Length(sValor) - 4) +
        Copy(sValor, 1, 4);
      Result := Modulo97(CadenaSepaADigitos(sReordenado)) = 1;
    end
    else
      Result := False;
  end;
end;

function CalcularCodigoAcreedorSepaEspanol(const ANif: string): string;
var
  iDc: Integer;
  sNif: string;
  sBase: string;
begin
  sNif := LimpiarDocumentoFiscal(ANif);
  if not DocumentoFiscalValido(sNif) then
    raise Exception.CreateFmt(SErrorNifEmpresaAcreedorSepaNoValido, [ANif]);
  sBase := '000' + sNif + 'ES00';
  iDc := 98 - Modulo97(CadenaSepaADigitos(sBase));
  Result := 'ES' + DosDigitos(iDc) + '000' + sNif;
end;

function GenerarSepaRemesaVenta(
  const ARemesa: TRemesaSepaVentaValidada;
  const AArchivo: string): TResultadoSepaRemesaVenta;
var
  bFicheroAbierto: Boolean;
  iIndice: Integer;
  oSepa: TDJMNorma1914XML;
  sArchivo: string;
  sCarpeta: string;
begin
  Result.Archivo := Trim(AArchivo);
  Result.NumCobros := 0;
  Result.Total := 0;
  sArchivo := Result.Archivo;
  if sArchivo = '' then
    raise Exception.Create(SErrorArchivoSalidaSepaNoIndicado);
  sCarpeta := ExtractFilePath(sArchivo);
  if (sCarpeta <> '') and (not DirectoryExists(sCarpeta)) then
    ForceDirectories(sCarpeta);
  oSepa := TDJMNorma1914XML.Create;
  try
    oSepa.SetInfoPresentador(Now, ARemesa.NombreEmpresa,
      ARemesa.CodigoAcreedor, ARemesa.FechaCargo);
    oSepa.SetTipoSecuencia(ARemesa.TipoSecuencia);
    oSepa.AddOrdenante(ARemesa.IdOrdenante, ARemesa.NombreEmpresa,
      ARemesa.IbanEmpresa, ARemesa.BicEmpresa,
      ARemesa.CodigoAcreedor);
    for iIndice := Low(ARemesa.Efectos) to
      High(ARemesa.Efectos) do
    begin
      oSepa.AddCobro(ARemesa.Efectos[iIndice].IdCobro,
        ARemesa.Efectos[iIndice].Importe,
        ARemesa.Efectos[iIndice].IdMandato,
        ARemesa.Efectos[iIndice].FechaFirmaMandato, '',
        ARemesa.Efectos[iIndice].NombreCliente,
        ARemesa.Efectos[iIndice].IbanCliente,
        ARemesa.Efectos[iIndice].Concepto,
        ARemesa.IbanEmpresa);
      Inc(Result.NumCobros);
      Result.Total := Result.Total +
        ARemesa.Efectos[iIndice].Importe;
    end;
    if Result.NumCobros = 0 then
      raise Exception.Create(SErrorRemesaVentaSinEfectosPendientes);
    bFicheroAbierto := False;
    try
      oSepa.CreateFile(sArchivo);
      bFicheroAbierto := True;
    finally
      if bFicheroAbierto then
        oSepa.CloseFile;
    end;
  finally
    FreeAndNil(oSepa);
  end;
end;

end.

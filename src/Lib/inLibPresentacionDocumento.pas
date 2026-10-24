{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPresentacionDocumento                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Textos comunes de presentación para documentos de compra y venta.         }
{******************************************************************************}
unit inLibPresentacionDocumento;

interface

uses
  Data.DB, Vcl.Controls;

type
  TObtenerTotalDocumento = function: Double of object;

function TextoProveedorDocumento(
  ACabecera, AProveedores: TDataSet;
  const ACampoCodigoProveedor: string): string;
function TextoTotalPrendasDocumento(
  ACabecera: TDataSet;
  AObtenerTotal: TObtenerTotalDocumento): string;

// Los controles se reciben como pares porcentaje/importe tras los títulos.
procedure MostrarRecargoDocumento(ADatos: TDataSet;
  const ASufijo: string; const AControles: array of TControl);

implementation

uses
  System.SysUtils;

function TextoProveedorDocumento(
  ACabecera, AProveedores: TDataSet;
  const ACampoCodigoProveedor: string): string;
var
  sCodigo: string;
  sNombre: string;
  sRazon: string;
begin
  Result := '';
  sCodigo := '';
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) then
    sCodigo := Trim(ACabecera.FieldByName(
      ACampoCodigoProveedor).AsString);
  if sCodigo <> '' then
  begin
    Result := sCodigo + ' - (proveedor no encontrado)';
    if Assigned(AProveedores) and AProveedores.Active and
       AProveedores.Locate(
         'CODIGO_PRV_PRV', sCodigo, []) then
    begin
      sRazon := AProveedores.FieldByName(
        'RAZON_SOCIAL_PRV').AsString;
      sNombre := AProveedores.FieldByName(
        'NOMBRE_PRV').AsString;
      if Trim(sNombre) = '' then
        Result := sCodigo + ' - ' + sRazon
      else if not SameText(Trim(sNombre), Trim(sRazon)) then
        Result := sCodigo + ' - ' + sNombre +
          '  (' + sRazon + ')'
      else
        Result := sCodigo + ' - ' + sNombre;
    end;
  end;
end;

function TextoTotalPrendasDocumento(
  ACabecera: TDataSet;
  AObtenerTotal: TObtenerTotalDocumento): string;
begin
  Result := '0';
  if Assigned(ACabecera) and ACabecera.Active and
     (not ACabecera.IsEmpty) and Assigned(AObtenerTotal) then
    Result := FormatFloat('#,##0', AObtenerTotal);
end;

procedure MostrarRecargoDocumento(ADatos: TDataSet;
  const ASufijo: string; const AControles: array of TControl);
const
  TIPOS = 'NRSE';
var
  iTipo: Integer;
  oCampo: TField;
  bVisible, bAlguno: Boolean;
begin
  bAlguno := False;
  for iTipo := 1 to Length(TIPOS) do
  begin
    bVisible := False;
    if Assigned(ADatos) and ADatos.Active and not ADatos.IsEmpty then
    begin
      oCampo := ADatos.FindField('TOTAL_RE' + TIPOS[iTipo] + '_' +
        ASufijo);
      bVisible := Assigned(oCampo) and not oCampo.IsNull and
        (oCampo.AsFloat <> 0);
    end;
    AControles[iTipo * 2].Visible := bVisible;
    AControles[iTipo * 2 + 1].Visible := bVisible;
    bAlguno := bAlguno or bVisible;
  end;
  AControles[0].Visible := bAlguno;
  AControles[1].Visible := bAlguno;
end;

end.

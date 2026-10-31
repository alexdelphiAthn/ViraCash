{******************************************************************************}
{                                                                             }
{  Módulo: inLibTrabajosCortinas                                              }
{  Tipo: Librería                                                             }
{  Versión: 1.0.0                                                             }
{  Fecha: 31/10/2026                                                          }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  SPDX-License-Identifier: MPL-2.0                                           }
{                                                                             }
{  Descripción: Medidas de cortinas y citas de instalación.                   }
{                                                                             }
{******************************************************************************}
unit inLibTrabajosCortinas;

interface

uses
  inLibReparaciones;

const
  CLASE_SERVICIO_TALLER = 'TALLER';
  CLASE_SERVICIO_ALTURA = 'ARREGLO_ALTURA';
  CLASE_SERVICIO_INSTALACION = 'INSTALACION';

function TextoClaseServicio(const AClase: string): string;
function ValidarTrabajoCortina(const ADatos: TDatosTrabajoReparacion): string;
function TextoTrabajoCortina(const ADatos: TDatosTrabajoReparacion): string;

implementation

uses
  System.SysUtils, inLibMsgReparaciones;

function TextoClaseServicio(const AClase: string): string;
begin
  Result := SClaseTaller;
  if AClase=CLASE_SERVICIO_ALTURA then
    Result := SClaseAltura
  else if AClase=CLASE_SERVICIO_INSTALACION then
    Result := SClaseInstalacion;
end;

function ValidarTrabajoCortina(const ADatos: TDatosTrabajoReparacion): string;
begin
  Result := '';
  if ADatos.Clase=CLASE_SERVICIO_ALTURA then
  begin
    if (ADatos.AlturaMedida<=0) or (ADatos.LargoFinal<=0) or
       (Trim(ADatos.Acabado)='') then
      Result := SErrorMedidasCortina;
  end
  else if ADatos.Clase=CLASE_SERVICIO_INSTALACION then
  begin
    if (Trim(ADatos.Direccion)='') or (ADatos.Cita<=0) then
      Result := SErrorCitaInstalacion;
  end
  else if (ADatos.Clase<>'') and (ADatos.Clase<>CLASE_SERVICIO_TALLER) then
    Result := SErrorClaseServicio;
  if (Length(ADatos.Acabado)>2000) or (Length(ADatos.Direccion)>500) then
    Result := SErrorClaseServicio;
end;

function TextoTrabajoCortina(const ADatos: TDatosTrabajoReparacion): string;
begin
  Result := '';
  if ADatos.Clase=CLASE_SERVICIO_ALTURA then
    Result := SAlturaMedida+' '+FormatFloat('0.###',ADatos.AlturaMedida)+
      sLineBreak+SLargoFinal+' '+FormatFloat('0.###',ADatos.LargoFinal)+
      sLineBreak+SAcabadoCortina+' '+ADatos.Acabado
  else if ADatos.Clase=CLASE_SERVICIO_INSTALACION then
  begin
    Result := SDireccionInstalacion+' '+ADatos.Direccion;
    if ADatos.Cita>0 then
      Result := Result+sLineBreak+SCitaInstalacion+' '+
        FormatDateTime('dd/mm/yyyy hh:nn',ADatos.Cita);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaFormatosTicket                                       }
{    Tipo:       Adaptador visual                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formatos FastReport del ticket de caja: data module de impresión de       }
{    facturas listo para usar y edición de los formatos 'Ticket...' desde      }
{    Parámetros de caja, igual que el botón Editar de imprimir factura pero    }
{    con el selector limitado a los formatos de ticket.                        }
{******************************************************************************}
unit inMtoCajaFormatosTicket;

interface

uses
  System.Classes, Uni, UniDataFacturas, inLibParametrosIntf;

function CrearDatosImpresionFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja): TdmFacturas;

procedure EditarFormatosTicket(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja);

implementation

uses
  System.SysUtils, Vcl.Forms,
  inMtoModalImpFac, inLibCajaParam, inLibFacturasComposicion,
  UniDataFacturasRepositorio,
  UniDataFacturasLecturas,
  UniDataFacturasOperaciones,
  UniDataArticulosResolverRepositorio,
  UniDataVerifactuColaRepositorio;

function CrearDatosImpresionFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja): TdmFacturas;
begin
  Result := TdmFacturas.Create(AOwner);
  try
    Result.ConfigurarServicios(
      CrearServiciosFactura(
        AConexion,
        TRepositorioFacturas.Create(AConexion),
        CrearRepositorioLecturasFacturaUniDAC(AConexion),
        CrearPersistenciaFacturasUniDAC(AConexion),
        TRepositorioArticulosResolver.Create(
          AConexion,
          AParametrosCaja),
        CrearServicioVerifactuColaUniDAC(AConexion)));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure EditarFormatosTicket(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja);
var
  DatosFactura: TdmFacturas;
  Formulario: TfrmPrintFac;
begin
  Formulario := nil;
  DatosFactura := CrearDatosImpresionFactura(nil, AConexion, AParametrosCaja);
  try
    Formulario := TfrmPrintFac.Create(Application);
    Formulario.PrefijoFormatos := cPrefijoFormatoTicket;
    Formulario.ConfigurarDataModule(DatosFactura);
    // Mismo flujo que el botón Editar: campos extra, selector y diseñador.
    Formulario.btnEditarClick(Formulario.btnEditar);
  finally
    FreeAndNil(Formulario);
    FreeAndNil(DatosFactura);
  end;
end;

end.

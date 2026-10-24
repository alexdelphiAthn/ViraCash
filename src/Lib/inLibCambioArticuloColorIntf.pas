{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCambioArticuloColorIntf                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para recodificar artículos o colores de forma atómica.          }
{******************************************************************************}
unit inLibCambioArticuloColorIntf;

interface

type
  TMotivoCambioArticuloColor = (
    mcacNinguno,
    mcacDatosInvalidos,
    mcacOrigenNoExiste,
    mcacDestinoYaExiste,
    mcacExistenVentas,
    mcacColisionUnidades,
    mcacDatosInconsistentes,
    mcacIntegracionExterna
  );

  TResultadoCambioArticuloColor = record
    Motivo: TMotivoCambioArticuloColor;
    UnidadesAfectadas: Integer;
    Detalle: string;
    IdOperacion: string;
    class function Correcto(
      AUnidadesAfectadas: Integer;
      const AIdOperacion: string = ''):
      TResultadoCambioArticuloColor; static;
    class function Error(
      AMotivo: TMotivoCambioArticuloColor;
      const ADetalle: string = ''): TResultadoCambioArticuloColor; static;
    function EsCorrecto: Boolean;
  end;

  TCausaReversionHistorico = (
    crhNinguna,
    crhNoEncontrada,
    crhYaRevertida,
    crhNoReversible,
    crhDependenciaPosterior,
    crhVentaFacturada,
    crhEsquemaModificado,
    crhDatosDivergentes,
    crhErrorTecnico
  );

  TResultadoReversionHistorico = record
  private
    FEsCorrecto: Boolean;
    FCausa: TCausaReversionHistorico;
    FIdOperacionReversion: string;
    FMotivo: string;
  public
    class function Correcto(
      const AIdOperacionReversion: string):
      TResultadoReversionHistorico; static;
    class function Error(
      ACausa: TCausaReversionHistorico;
      const AMotivo: string): TResultadoReversionHistorico; static;
    property EsCorrecto: Boolean read FEsCorrecto;
    property Causa: TCausaReversionHistorico read FCausa;
    property IdOperacionReversion: string read FIdOperacionReversion;
    property Motivo: string read FMotivo;
  end;

  IRepositorioCambioArticuloColor = interface
    ['{C7DA3199-13C0-4502-A1CD-D4FE2518AE1D}']
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function RevertirOperacion(
      const AIdOperacion, AUsuario: string):
      TResultadoReversionHistorico;
  end;

  IServicioCambioArticuloColor = interface
    ['{6769C45D-D488-4A04-92AE-CC99AC14714E}']
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function RevertirOperacion(
      const AIdOperacion, AUsuario: string):
      TResultadoReversionHistorico;
  end;

implementation

class function TResultadoCambioArticuloColor.Correcto(
  AUnidadesAfectadas: Integer;
  const AIdOperacion: string): TResultadoCambioArticuloColor;
begin
  Result.Motivo := mcacNinguno;
  Result.UnidadesAfectadas := AUnidadesAfectadas;
  Result.Detalle := '';
  Result.IdOperacion := AIdOperacion;
end;

class function TResultadoCambioArticuloColor.Error(
  AMotivo: TMotivoCambioArticuloColor;
  const ADetalle: string): TResultadoCambioArticuloColor;
begin
  Result.Motivo := AMotivo;
  Result.UnidadesAfectadas := 0;
  Result.Detalle := ADetalle;
  Result.IdOperacion := '';
end;

function TResultadoCambioArticuloColor.EsCorrecto: Boolean;
begin
  Result := Motivo = mcacNinguno;
end;

class function TResultadoReversionHistorico.Correcto(
  const AIdOperacionReversion: string): TResultadoReversionHistorico;
begin
  Result.FEsCorrecto := True;
  Result.FCausa := crhNinguna;
  Result.FIdOperacionReversion := AIdOperacionReversion;
  Result.FMotivo := '';
end;

class function TResultadoReversionHistorico.Error(
  ACausa: TCausaReversionHistorico;
  const AMotivo: string): TResultadoReversionHistorico;
begin
  Result.FEsCorrecto := False;
  Result.FCausa := ACausa;
  Result.FIdOperacionReversion := '';
  Result.FMotivo := AMotivo;
end;

end.

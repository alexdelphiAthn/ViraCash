{******************************************************************************}
{                                                                              }
{  Comprobacion y presentacion de caducidad de certificados al arrancar.       }
{                                                                              }
{******************************************************************************}
unit inMtoPrincipalCertificadosVcl;

interface

uses
  Uni, inLibLogIntf;

procedure MostrarAvisoCaducidadCertificados(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);

implementation

uses
  inLibMensajesVcl,
  System.SysUtils, System.Classes, System.DateUtils, System.UITypes,
  Vcl.Dialogs,
  inLibCertificates, inLibPrincipalCertificadosIntf,
  UniDataPrincipalCertificadosRepositorio, inLibMsgConfiguracion;

const
  DIAS_AVISO_CERTIFICADO = 5;

function TextoDiasCertificado(ADias: Integer): string;
begin
  if ADias <= 0 then
    Result := SCertificadoQuedaMenosUnDia
  else if ADias = 1 then
    Result := SCertificadoQuedaUnDia
  else
    Result := Format(SCertificadoQuedanDias, [ADias]);
end;

procedure MostrarAvisoCaducidadCertificados(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
var
  Avisos: TStringList;
  Certificado: TCertificadoEmpresaActivo;
  Certificados: TCertificadosEmpresasActivos;
  Repositorio: IRepositorioCertificadosEmpresas;
  Empresa: string;
  Serie: string;
  Titular: string;
  TitularReal: string;
  Prefijo: string;
  Caducidad: TDateTime;
  Dias: Integer;
  HayCaducidad: Boolean;

  procedure AgregarAviso(const ATexto: string);
  begin
    Prefijo := '- ' + Empresa + ': ';
    if Trim(TitularReal) <> '' then
      Prefijo := Prefijo + Trim(TitularReal) + ', ';
    Avisos.Add(Prefijo + ATexto);
  end;

begin
  if AConexion <> nil then
  begin
    Avisos := TStringList.Create;
    try
      try
      Repositorio := CrearRepositorioCertificadosEmpresasUniDAC(AConexion);
      Certificados := Repositorio.ListarActivos;
      for Certificado in Certificados do
      begin
        Empresa := Trim(Certificado.Empresa);
        if Empresa = '' then
          Empresa := Trim(Certificado.CodigoEmpresa);
        Serie := Trim(Certificado.Serie);
        Titular := Trim(Certificado.Titular);
        TitularReal := Titular;
        HayCaducidad := ObtenerCaducidadCertificado(
          Serie,
          Titular,
          Caducidad,
          TitularReal);
        if (not HayCaducidad) and Certificado.TieneFechaHasta then
        begin
          Caducidad := Certificado.FechaHasta;
          HayCaducidad := Caducidad > 0;
        end;
        if TitularReal = '' then
          TitularReal := Titular;
        if HayCaducidad then
        begin
          if Caducidad < Now then
            AgregarAviso(Format(
              SAvisoCertificadoCaducado,
              [FormatDateTime('dd/mm/yyyy hh:nn', Caducidad)]))
          else if Caducidad < IncDay(Now, DIAS_AVISO_CERTIFICADO) then
          begin
            Dias := Trunc(Caducidad - Now);
            AgregarAviso(Format(
              SAvisoCertificadoProximoCaducar,
              [FormatDateTime('dd/mm/yyyy hh:nn', Caducidad),
               TextoDiasCertificado(Dias)]));
          end;
        end;
      end;
      if Avisos.Count > 0 then
        MessageDlg_fza(
          Format(SAvisoCertificadosCaducidad, [Avisos.Text]),
          mtWarning,
          [mbOK],
          0);
      except
        on E: Exception do
          if Assigned(ARegistroLog) then
            ARegistroLog.RegistrarAviso(
              'No se pudo comprobar la caducidad de certificados al ' +
              'arrancar: ' + E.Message);
      end;
    finally
      Avisos.Free;
    end;
  end;
end;

end.

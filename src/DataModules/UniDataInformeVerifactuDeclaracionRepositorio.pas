unit UniDataInformeVerifactuDeclaracionRepositorio;

interface

uses
  Uni, inLibInformeVerifactuDeclaracionPersistenciaIntf;

function CrearRepositorioInformeVerifactuDeclaracionUniDAC(
  AConexion: TUniConnection): IRepositorioInformeVerifactuDeclaracion;

implementation

uses
  System.SysUtils;

type
  TRepositorioInformeVerifactuDeclaracionUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeVerifactuDeclaracion)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarEmpresas: TEmpresasInformeVerifactuDeclaracion;
  end;

constructor TRepositorioInformeVerifactuDeclaracionUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeVerifactuDeclaracionUniDAC.ListarEmpresas:
  TEmpresasInformeVerifactuDeclaracion;
var
  iEmpresa: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ESACTIVO_EMP, ' +
      'NUMERO_INSTALACION_EMP, VERSION_INSTALACION_EMP, ' +
      'CODIGO_SIF_INSTALACION_EMP, INSTANTE_INSTALACION_EMP ' +
      'FROM fza_empresas ' +
      'ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      'CODIGO_EMP_EMP';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iEmpresa := Length(Result);
      SetLength(Result, iEmpresa + 1);
      Result[iEmpresa].Codigo :=
        oConsulta.FieldByName('CODIGO_EMP_EMP').AsString;
      Result[iEmpresa].RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
      Result[iEmpresa].Nif := oConsulta.FieldByName('NIF_EMP').AsString;
      Result[iEmpresa].Activa :=
        oConsulta.FieldByName('ESACTIVO_EMP').AsString = 'S';
      Result[iEmpresa].NumeroInstalacion :=
        oConsulta.FieldByName('NUMERO_INSTALACION_EMP').AsString;
      Result[iEmpresa].VersionInstalacion :=
        oConsulta.FieldByName('VERSION_INSTALACION_EMP').AsString;
      Result[iEmpresa].CodigoSif :=
        oConsulta.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString;
      Result[iEmpresa].TieneInstanteInstalacion :=
        not oConsulta.FieldByName('INSTANTE_INSTALACION_EMP').IsNull;
      if Result[iEmpresa].TieneInstanteInstalacion then
        Result[iEmpresa].InstanteInstalacion :=
          oConsulta.FieldByName('INSTANTE_INSTALACION_EMP').AsDateTime;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioInformeVerifactuDeclaracionUniDAC(
  AConexion: TUniConnection): IRepositorioInformeVerifactuDeclaracion;
begin
  Result := TRepositorioInformeVerifactuDeclaracionUniDAC.Create(AConexion);
end;

end.

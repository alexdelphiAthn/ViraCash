unit UniDataInformeBalanceSinTallasRepositorio;

interface

uses
  Uni, inLibInformeBalanceSinTallasPersistenciaIntf;

function CrearRepositorioInformeBalanceSinTallasUniDAC(
  AConexion: TUniConnection): IRepositorioInformeBalanceSinTallas;

implementation

uses
  System.SysUtils, Data.DB, System.Generics.Collections,
  UniDataBalanceUnidades;

type
  TResultadoInformeBalanceSinTallasUniDAC = class(
    TInterfacedObject,
    IResultadoInformeBalanceSinTallas)
  private
    FDataSet: TDataSet;
    FUnidades: TDictionary<string, string>;
  public
    constructor Create(ADataSet: TDataSet;
      AUnidades: TDictionary<string, string>);
    destructor Destroy; override;
    function DataSet: TDataSet;
    function UnidadArticulo(const ACodigoArticulo: string): string;
  end;

  TRepositorioInformeBalanceSinTallasUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeBalanceSinTallas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Preparar(
      const ACriterios: TCriteriosInformeBalanceSinTallas
    ): IResultadoInformeBalanceSinTallas;
  end;

constructor TResultadoInformeBalanceSinTallasUniDAC.Create(
  ADataSet: TDataSet; AUnidades: TDictionary<string, string>);
begin
  inherited Create;
  FDataSet := ADataSet;
  FUnidades := AUnidades;
end;

destructor TResultadoInformeBalanceSinTallasUniDAC.Destroy;
begin
  FreeAndNil(FUnidades);
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TResultadoInformeBalanceSinTallasUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

function TResultadoInformeBalanceSinTallasUniDAC.UnidadArticulo(
  const ACodigoArticulo: string): string;
begin
  if not FUnidades.TryGetValue(UpperCase(Trim(ACodigoArticulo)), Result) then
    Result := '';
end;

constructor TRepositorioInformeBalanceSinTallasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeBalanceSinTallasUniDAC.Preparar(
  const ACriterios: TCriteriosInformeBalanceSinTallas
): IResultadoInformeBalanceSinTallas;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS(' +
      ':pMODO, :pDESDE, :pHASTA, :pALM, :pFAM, :pPRV, :pTMP, :pART, ' +
      ':pTAR, :pDESG, :pBND, :pN1, :pN2, :pN3, :pNFAM)';
    oConsulta.ParamByName('pMODO').AsString := ACriterios.Modo;
    oConsulta.ParamByName('pDESDE').AsDateTime := ACriterios.FechaDesde;
    oConsulta.ParamByName('pHASTA').AsDateTime := ACriterios.FechaHasta;
    oConsulta.ParamByName('pALM').AsString := ACriterios.Almacenes;
    oConsulta.ParamByName('pFAM').AsString := ACriterios.Familias;
    oConsulta.ParamByName('pPRV').AsString := ACriterios.Proveedores;
    oConsulta.ParamByName('pTMP').AsString := ACriterios.Temporadas;
    oConsulta.ParamByName('pART').AsString := ACriterios.Articulos;
    oConsulta.ParamByName('pTAR').AsString := ACriterios.Tarifa;
    oConsulta.ParamByName('pDESG').AsString := ACriterios.Desglosado;
    oConsulta.ParamByName('pBND').AsString := ACriterios.Bandas;
    oConsulta.ParamByName('pN1').AsString := ACriterios.Nivel1;
    oConsulta.ParamByName('pN2').AsString := ACriterios.Nivel2;
    oConsulta.ParamByName('pN3').AsString := ACriterios.Nivel3;
    oConsulta.ParamByName('pNFAM').AsInteger := ACriterios.NivelFamilia;
    oConsulta.Open;
    Result := TResultadoInformeBalanceSinTallasUniDAC.Create(
      oConsulta, PrecargarUnidadesBalance(FConexion, oConsulta));
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function CrearRepositorioInformeBalanceSinTallasUniDAC(
  AConexion: TUniConnection): IRepositorioInformeBalanceSinTallas;
begin
  Result := TRepositorioInformeBalanceSinTallasUniDAC.Create(AConexion);
end;

end.

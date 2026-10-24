unit UniDataInformeDocumentosProveedorRepositorio;

interface

uses
  Uni, inLibInformeDocumentosProveedorPersistenciaIntf;

function CrearRepositorioInformeDocumentosProveedorUniDAC(
  AConexion: TUniConnection): IRepositorioInformeDocumentosProveedor;

implementation

uses
  System.SysUtils, Data.DB, UniDataDocsProveedorSql, inLibMsgCompras;

// FZ-ISSUE-609: TIPO_DOC_NOMBRE sale en el idioma de la sesión.
function NombresTiposDocumentoProveedor: TNombresTiposDocumentoProveedor;
begin
  Result.Pedido := SNombreTipoPedidoInformeProveedor;
  Result.Albaran := SNombreTipoAlbaranInformeProveedor;
  Result.Factura := SNombreTipoFacturaInformeProveedor;
  Result.Devolucion := SNombreTipoDevolucionInformeProveedor;
end;

type
  TResultadoInformeDocumentosProveedorUniDAC = class(
    TInterfacedObject,
    IResultadoInformeDocumentosProveedor)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioInformeDocumentosProveedorUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeDocumentosProveedor)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Preparar(
      const ACriterios: TCriteriosInformeDocumentosProveedor
    ): IResultadoInformeDocumentosProveedor;
  end;

constructor TResultadoInformeDocumentosProveedorUniDAC.Create(
  ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoInformeDocumentosProveedorUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TResultadoInformeDocumentosProveedorUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioInformeDocumentosProveedorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeDocumentosProveedorUniDAC.Preparar(
  const ACriterios: TCriteriosInformeDocumentosProveedor
): IResultadoInformeDocumentosProveedor;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlListadoDocumentosProveedor(
      NombresTiposDocumentoProveedor);
    oConsulta.ParamByName('pDESDE').AsDateTime := ACriterios.FechaDesde;
    oConsulta.ParamByName('pHASTA').AsDateTime := ACriterios.FechaHasta;
    oConsulta.ParamByName('pALM').AsString := ACriterios.Almacenes;
    oConsulta.ParamByName('pPRV').AsString := ACriterios.Proveedores;
    oConsulta.ParamByName('pTMP').AsString := ACriterios.Temporadas;
    oConsulta.ParamByName('pTIP').AsString := ACriterios.Tipos;
    oConsulta.ParamByName('pSER').AsString := ACriterios.Series;
    oConsulta.Open;
    Result := TResultadoInformeDocumentosProveedorUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function CrearRepositorioInformeDocumentosProveedorUniDAC(
  AConexion: TUniConnection): IRepositorioInformeDocumentosProveedor;
begin
  Result := TRepositorioInformeDocumentosProveedorUniDAC.Create(AConexion);
end;

end.

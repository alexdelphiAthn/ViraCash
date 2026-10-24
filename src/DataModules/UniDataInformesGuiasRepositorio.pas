{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataInformesGuiasRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Carga UniDAC para la cache en memoria de guias de informes.               }
{******************************************************************************}
unit UniDataInformesGuiasRepositorio;

interface

uses
  Uni, inLibInformesGuiasCache;

type
  TLectorInformesGuiasUniDAC = class(
    TInterfacedObject,
    ILectorInformesGuias)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar: TArray<TInformeGuiaItem>;
  end;

implementation

uses
  System.SysUtils;

constructor TLectorInformesGuiasUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorInformesGuiasUniDAC.Cargar:
  TArray<TInformeGuiaItem>;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_INFGUI, INFORME_INFGUI, FORMATO_INFGUI, ' +
      '       DATASET_MASTER_INFGUI, TIPO_INFGUI, TABLA_INFGUI, ' +
      '       SQL_INFGUI, MASTER_FIELDS_INFGUI, ' +
      '       DETAIL_FIELDS_INFGUI, ORDEN_INFGUI, ' +
      '       COLUMNAS_VISIBLES_INFGUI ' +
      '  FROM fza_informes_guias ' +
      ' WHERE ESACTIVO_INFGUI = ''S'' ' +
      ' ORDER BY INFORME_INFGUI, ORDEN_INFGUI, CODIGO_INFGUI';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].Codigo :=
        oConsulta.FieldByName('CODIGO_INFGUI').AsString;
      Result[iIndice].Informe :=
        oConsulta.FieldByName('INFORME_INFGUI').AsString;
      Result[iIndice].Formato :=
        oConsulta.FieldByName('FORMATO_INFGUI').AsString;
      Result[iIndice].DatasetMaster :=
        oConsulta.FieldByName('DATASET_MASTER_INFGUI').AsString;
      Result[iIndice].Tipo :=
        oConsulta.FieldByName('TIPO_INFGUI').AsString;
      Result[iIndice].Tabla :=
        oConsulta.FieldByName('TABLA_INFGUI').AsString;
      Result[iIndice].SqlStr :=
        oConsulta.FieldByName('SQL_INFGUI').AsString;
      Result[iIndice].MasterFields :=
        oConsulta.FieldByName('MASTER_FIELDS_INFGUI').AsString;
      Result[iIndice].DetailFields :=
        oConsulta.FieldByName('DETAIL_FIELDS_INFGUI').AsString;
      Result[iIndice].Orden :=
        oConsulta.FieldByName('ORDEN_INFGUI').AsInteger;
      Result[iIndice].ColumnasVisibles :=
        oConsulta.FieldByName('COLUMNAS_VISIBLES_INFGUI').AsString;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.

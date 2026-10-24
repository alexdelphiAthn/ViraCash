{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajasDefectoPersistenciaIntf                            }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura del selector de empresa, almacen y caja.                }
{******************************************************************************}
unit inLibCajasDefectoPersistenciaIntf;

interface

uses
  Data.DB;

type
  TSolicitudCajasDefecto = record
    EmpresaFiltro: string;
    EmpresaRestringida: string;
    AlmacenRestringido: string;
    CajaRestringida: string;
  end;

  IResultadoCajasDefecto = interface
    ['{0FC2162D-B742-473B-8477-A216EF0FB7A4}']
    function DataSet: TDataSet;
  end;

  IRepositorioCajasDefecto = interface
    ['{4FCE0BB9-2822-4333-8F34-F9E407CFE29C}']
    function Consultar(
      const ASolicitud: TSolicitudCajasDefecto
    ): IResultadoCajasDefecto;
  end;

implementation

end.

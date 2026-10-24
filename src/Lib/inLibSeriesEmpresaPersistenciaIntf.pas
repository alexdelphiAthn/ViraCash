{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeriesEmpresaPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para crear series documentales de una empresa.    }
{******************************************************************************}
unit inLibSeriesEmpresaPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TTipoDocumentoEmpresa = record
    Codigo: string;
    UsaCaja: Boolean;
  end;

  TTiposDocumentoEmpresa = TArray<TTipoDocumentoEmpresa>;

  IRepositorioSeriesEmpresa = interface
    ['{B4C6F463-62C4-42AE-A36A-696017F3BED3}']
    function ListarTiposDocumento: TTiposDocumentoEmpresa;
    function CrearSerieSiFalta(
      const AEmpresa, AAlmacen, ACaja, ASerieTokenizada: string;
      const ATipo, ASubtipo: string;
      const AUsuario: string): Boolean;
    // FZ-ISSUE-371: empresa distinta de AEmpresa que ya usa el texto
    // ASerie o la plantilla ASerieTokenizada; vacío si ninguna.
    function EmpresaQueUsaSerie(
      const AEmpresa, ASerie, ASerieTokenizada: string): string;
  end;

implementation

end.

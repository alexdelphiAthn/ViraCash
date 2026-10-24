{******************************************************************************}
{                                                                              }
{  Modulo:       inLibRepositoriosPantallaIntf                                }
{    Tipo:       Contrato                                                      }
{ Version:       2.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Servicios SQL inmutables compartidos por la raiz de composicion.         }
{******************************************************************************}
unit inLibRepositoriosPantallaIntf;

interface

uses
  inLibCatalogoSqlIntf;

type
  TServiciosSqlPantalla = record
    Catalogo: ICatalogoSql;
    Incidencias: IRegistroIncidenciasSql;
  end;

implementation

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionPerfilIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato independiente del motor para describir conexiones de base de     }
{    datos sin credenciales ni dependencias de la tecnología de acceso.        }
{******************************************************************************}
unit inLibConexionPerfilIntf;

interface

type
  TMotorBBDD = (
    mbMariaDB,
    mbPostgreSQL,
    mbSQLServer);
  TModoSSLConexion = (
    sslDesactivado,
    sslPreferido,
    sslRequerido,
    sslVerificarCA,
    sslVerificarCompleto);
  TConfiguracionPoolConexion = record
    Habilitado: Boolean;
    Validar: Boolean;
    MinimoConexiones: Integer;
    MaximoConexiones: Integer;
    TiempoEsperaSeg: Integer;
    TiempoVidaSeg: Integer;
  end;
  TPerfilConexion = record
    Id: string;
    Motor: TMotorBBDD;
    Servidor: string;
    Puerto: Integer;
    BaseDatos: string;
    Esquema: string;
    Usuario: string;
    SSL: TModoSSLConexion;
    TimeoutConexionSeg: Integer;
    TimeoutComandoSeg: Integer;
    Pool: TConfiguracionPoolConexion;
    RutaCertificadoCA: string;
    RutaCertificadoCliente: string;
    RutaClavePrivada: string;
  end;
  TCapacidadesMotorBBDD = record
    Motor: TMotorBBDD;
    SoportaEsquemas: Boolean;
    SoportaReturning: Boolean;
    SoportaJsonNativo: Boolean;
    SoportaSecuencias: Boolean;
    SoportaIdentity: Boolean;
    SoportaLimit: Boolean;
    SoportaBloqueoSkipLocked: Boolean;
    SoportaInformationSchema: Boolean;
    SoportaProcedimientos: Boolean;
  end;

implementation

end.

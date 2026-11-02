{******************************************************************************}
{                                                                              }
{  Programa:     PruebasSincro                                                 }
{    Tipo:       Pruebas de consola                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escenarios deterministas, uno por cada fallo que el protocolo debe        }
{    tolerar. Código de salida 0 si todos pasan.                               }
{******************************************************************************}
program PruebasSincro;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}
{$APPTYPE CONSOLE}

uses
  {$IFDEF FPC}
  SysUtils,
  {$ELSE}
  System.SysUtils,
  {$ENDIF}
  inLibSincroProtocolo in 'inLibSincroProtocolo.pas',
  inLibSincroServidor in 'inLibSincroServidor.pas',
  inLibSincroCliente in 'inLibSincroCliente.pas',
  inLibSincroTransporteSimulado in 'inLibSincroTransporteSimulado.pas';

type
  TEntorno = record
    ServidorObj: TServidorSincro;
    Servidor: IServicioSincro;
    Transporte: TTransporteSimulado;
    Servicio: IServicioSincro;
    Almacen: TAlmacenCliente;
    Cliente: TClienteSincro;
  end;

var
  iPruebas, iFallos: Integer;
  sPrueba: string;

procedure Comprobar(ACondicion: Boolean; const ATexto: string);
begin
  if not ACondicion then
  begin
    Inc(iFallos);
    Writeln('    [FALLO] ', sPrueba, ': ', ATexto);
  end;
end;

procedure Iniciar(const ANombre: string; out AEntorno: TEntorno);
begin
  sPrueba := ANombre;
  Inc(iPruebas);
  AEntorno.ServidorObj := TServidorSincro.Create;
  AEntorno.Servidor := AEntorno.ServidorObj;
  AEntorno.Transporte := TTransporteSimulado.Create(AEntorno.Servidor, 1);
  AEntorno.Servicio := AEntorno.Transporte;
  AEntorno.Almacen := TAlmacenCliente.Create('CAJA1');
  AEntorno.Cliente := TClienteSincro.Create(AEntorno.Almacen,
    AEntorno.Servicio);
end;

procedure Terminar(var AEntorno: TEntorno; AFallosPrevios: Integer);
begin
  AEntorno.Cliente.Free;
  AEntorno.Almacen.Free;
  AEntorno.Servicio := nil;
  AEntorno.Servidor := nil;
  if iFallos = AFallosPrevios then
    Writeln('  [ OK  ] ', sPrueba)
  else
    Writeln('  [FALLO] ', sPrueba);
end;

procedure PruebaVentaSinConexion;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Venta sin conexion queda pendiente y sube al reconectar', oEnt);
  oEnt.Transporte.Conectado := False;
  oEnt.Almacen.RegistrarVenta('T1', 1, 10, 1);
  oEnt.Almacen.RegistrarVenta('T1', 2, 20, 1);
  Comprobar(not oEnt.Cliente.Sincronizar(1), 'el ciclo debia fallar');
  Comprobar(oEnt.Almacen.NumeroPendientes = 2, 'deben quedar 2 pendientes');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 0, 'el servidor no debe tener nada');
  oEnt.Transporte.Conectado := True;
  Comprobar(oEnt.Cliente.Sincronizar(1000), 'el ciclo debia ir bien');
  Comprobar(oEnt.Almacen.NumeroPendientes = 0, 'no deben quedar pendientes');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 2, 'el servidor debe tener 2');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaRespuestaPerdida;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Respuesta perdida: se reenvia y no se duplica', oEnt);
  oEnt.Almacen.RegistrarVenta('T1', 1, 10, 1);
  oEnt.Transporte.ForzarFallo(ffRespuestaPerdida);
  Comprobar(not oEnt.Cliente.Sincronizar(1), 'el ciclo debia fallar');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 1,
    'el servidor si la recibio aunque el terminal no lo sepa');
  Comprobar(oEnt.Almacen.NumeroPendientes = 1,
    'sin acuse, el terminal la mantiene pendiente');
  Comprobar(oEnt.Cliente.Sincronizar(1000), 'el reenvio debia ir bien');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 1, 'no debe duplicarse');
  Comprobar(oEnt.ServidorObj.Estadisticas.VentasRepetidas = 1,
    'el reenvio debe llegar como REPETIDA');
  Comprobar(oEnt.Almacen.NumeroPendientes = 0, 'debe quedar confirmada');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaPeticionPerdidaYEspera;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Peticion perdida: espera exponencial antes de reintentar', oEnt);
  oEnt.Almacen.RegistrarVenta('T1', 1, 10, 1);
  oEnt.Transporte.ForzarFallo(ffPeticionPerdida);
  oEnt.Cliente.Sincronizar(100);
  Comprobar(oEnt.Almacen.Salida[0].Intentos = 1, 'debe contar 1 intento');
  Comprobar(oEnt.Almacen.Salida[0].ProximoIntento = 101,
    'primer reintento a +1');
  oEnt.Transporte.ForzarFallo(ffPeticionPerdida);
  oEnt.Cliente.Sincronizar(101);
  Comprobar(oEnt.Almacen.Salida[0].ProximoIntento = 103,
    'segundo reintento a +2');
  oEnt.Cliente.Sincronizar(102);
  Comprobar(oEnt.ServidorObj.Estadisticas.LotesRecibidos = 0,
    'antes de vencer la espera no debe intentar subir ventas');
  Comprobar(oEnt.Almacen.NumeroPendientes = 1, 'sigue pendiente');
  oEnt.Cliente.Sincronizar(103);
  Comprobar(oEnt.Almacen.NumeroPendientes = 0, 'al vencer la espera sube');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaDuplicadoDeRed;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Duplicado de red: el servidor guarda una sola venta', oEnt);
  oEnt.Almacen.RegistrarVenta('T1', 1, 10, 1);
  oEnt.Transporte.ForzarFallo(ffDuplicado);
  Comprobar(oEnt.Cliente.Sincronizar(1), 'el ciclo debia ir bien');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 1, 'una sola venta');
  Comprobar(oEnt.Almacen.NumeroPendientes = 0, 'confirmada');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaRechazo;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  iLotes: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Venta rechazada no se reintenta y no bloquea a las demas', oEnt);
  oEnt.Almacen.RegistrarVenta('T1', 1, -5, 1);
  oEnt.Almacen.RegistrarVenta('T1', 2, 15, 1);
  oEnt.Cliente.Sincronizar(1);
  Comprobar(oEnt.Almacen.Salida[0].Estado = esRechazada, 'debe estar rechazada');
  Comprobar(oEnt.Almacen.Salida[0].Motivo <> '', 'debe guardar el motivo');
  Comprobar(oEnt.Almacen.Salida[1].Estado = esConfirmada,
    'la siguiente debe confirmarse');
  iLotes := oEnt.ServidorObj.Estadisticas.LotesRecibidos;
  oEnt.Cliente.Sincronizar(1000);
  Comprobar(oEnt.ServidorObj.Estadisticas.LotesRecibidos = iLotes,
    'no debe volver a enviarse');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaReinicioCliente;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Reinicio del terminal conserva pendientes y cursor', oEnt);
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART1', '1,00');
  oEnt.Cliente.Sincronizar(1);
  oEnt.Transporte.Conectado := False;
  oEnt.Almacen.RegistrarVenta('T1', 1, 10, 2);
  oEnt.Cliente.Sincronizar(2);
  oEnt.Cliente.Free; // el proceso muere
  oEnt.Cliente := TClienteSincro.Create(oEnt.Almacen, oEnt.Servicio);
  Comprobar(oEnt.Almacen.Cursor = 1, 'el cursor persiste');
  Comprobar(oEnt.Almacen.NumeroPendientes = 1, 'la venta persiste');
  oEnt.Transporte.Conectado := True;
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART1', '2,00');
  Comprobar(oEnt.Cliente.Sincronizar(1000), 'el ciclo debia ir bien');
  Comprobar(oEnt.ServidorObj.NumeroVentas = 1, 'la venta llega una vez');
  Comprobar(oEnt.Almacen.Catalogo['ART1'] = '2,00', 'precio actualizado');
  Comprobar(oEnt.Cliente.Estadisticas.NovedadesAplicadas = 1,
    'solo debe aplicar la novedad nueva');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaNovedadesRespuestaPerdida;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Novedades: respuesta perdida no aplica nada; reintento si', oEnt);
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART1', '1,00');
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART2', '2,00');
  oEnt.Transporte.ForzarFallo(ffRespuestaPerdida);
  Comprobar(not oEnt.Cliente.Sincronizar(1), 'el ciclo debia fallar');
  Comprobar(oEnt.Almacen.Cursor = 0, 'el cursor no debe moverse');
  Comprobar(oEnt.Cliente.Sincronizar(2), 'el reintento debia ir bien');
  Comprobar(oEnt.Almacen.Cursor = 2, 'cursor en la version 2');
  Comprobar(oEnt.Almacen.Catalogo.Count = 2, 'dos articulos');
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 2,
    'el servidor conoce el acuse');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaAcuseNovedadesPerdido;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Novedades: acuse perdido se repite en el siguiente ciclo', oEnt);
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART1', '1,00');
  oEnt.Cliente.Sincronizar(1);
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART2', '2,00');
  // Sin ventas, el ciclo hace PedirNovedades y ConfirmarNovedades:
  // se deja pasar la petición y se pierde el acuse.
  oEnt.Transporte.ForzarFallo(ffPeticionPerdida, 1);
  Comprobar(not oEnt.Cliente.Sincronizar(2), 'el ciclo debia fallar');
  Comprobar(oEnt.Almacen.Cursor = 2, 'el terminal aplico la version 2');
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 1,
    'el servidor sigue en la version 1');
  Comprobar(oEnt.Cliente.Sincronizar(3), 'el ciclo debia ir bien');
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 2,
    'el siguiente ciclo envia el acuse pendiente');
  Comprobar(oEnt.Cliente.Estadisticas.NovedadesAplicadas = 2,
    'no debe reaplicar la version 2');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaAcuseNoRetrocede;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Un acuse viejo que llega tarde no hace retroceder', oEnt);
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART1', '1,00');
  oEnt.ServidorObj.PublicarNovedad(tnPrecio, 'ART2', '2,00');
  oEnt.ServidorObj.ConfirmarNovedades('CAJA1', 2);
  oEnt.ServidorObj.ConfirmarNovedades('CAJA1', 1);
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 2, 'debe seguir en 2');
  oEnt.ServidorObj.ConfirmarNovedades('CAJA1', 99);
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 2,
    'no puede confirmar versiones que no existen');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaPaginacion;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  iIndice: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Paginacion: 25 novedades en paginas de 10 en un ciclo', oEnt);
  for iIndice := 1 to 25 do
    oEnt.ServidorObj.PublicarNovedad(tnPrecio,
      'ART' + IntToStr(iIndice), IntToStr(iIndice));
  oEnt.ServidorObj.PublicarNovedad(tnBajaArticulo, 'ART3', '');
  oEnt.Cliente.TamanoPagina := 10;
  Comprobar(oEnt.Cliente.Sincronizar(1), 'el ciclo debia ir bien');
  Comprobar(oEnt.ServidorObj.Estadisticas.PeticionesNovedades = 3,
    'deben pedirse 3 paginas');
  Comprobar(oEnt.Almacen.Cursor = 26, 'cursor en la ultima version');
  Comprobar(oEnt.Almacen.Catalogo.Count = 24, 'la baja elimina ART3');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaFalloAMitadDePaginacion;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  iIndice: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Corte a mitad de paginacion: conserva lo aplicado', oEnt);
  for iIndice := 1 to 25 do
    oEnt.ServidorObj.PublicarNovedad(tnPrecio,
      'ART' + IntToStr(iIndice), IntToStr(iIndice));
  oEnt.Cliente.TamanoPagina := 10;
  // Página 1 llega; la página 2 se pierde.
  oEnt.Transporte.ForzarFallo(ffRespuestaPerdida, 1);
  Comprobar(not oEnt.Cliente.Sincronizar(1), 'el ciclo debia fallar');
  Comprobar(oEnt.Almacen.Cursor = 10, 'lo aplicado se conserva');
  Comprobar(oEnt.ServidorObj.CursorConfirmado('CAJA1') = 10,
    'se acusa lo aplicado aunque la bajada no terminase');
  Comprobar(oEnt.Cliente.Sincronizar(2), 'el ciclo debia ir bien');
  Comprobar(oEnt.Almacen.Cursor = 25, 'continua desde la version 10');
  Comprobar(oEnt.Cliente.Estadisticas.NovedadesAplicadas = 25,
    'cada novedad se aplica una sola vez');
  Terminar(oEnt, iPrevios);
end;

begin
  iPruebas := 0;
  iFallos := 0;
  Writeln('Pruebas del protocolo de sincronizacion');
  PruebaVentaSinConexion;
  PruebaRespuestaPerdida;
  PruebaPeticionPerdidaYEspera;
  PruebaDuplicadoDeRed;
  PruebaRechazo;
  PruebaReinicioCliente;
  PruebaNovedadesRespuestaPerdida;
  PruebaAcuseNovedadesPerdido;
  PruebaAcuseNoRetrocede;
  PruebaPaginacion;
  PruebaFalloAMitadDePaginacion;
  Writeln;
  Writeln(Format('%d pruebas, %d comprobaciones fallidas', [iPruebas, iFallos]));
  if iFallos > 0 then
    ExitCode := 1;
end.

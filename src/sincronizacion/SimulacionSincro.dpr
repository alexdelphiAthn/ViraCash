{******************************************************************************}
{                                                                              }
{  Programa:     SimulacionSincro                                              }
{    Tipo:       Simulación de consola                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tres terminales venden y un backoffice publica cambios de precio sobre    }
{    una red que pierde peticiones y respuestas, duplica envíos y se corta.    }
{    Un terminal se reinicia a mitad. Al final se restablece la red y se       }
{    comprueba que no se ha perdido ni duplicado ninguna venta y que todos    }
{    los terminales tienen el mismo catálogo que el servidor.                  }
{                                                                              }
{    Uso: SimulacionSincro [semilla] [ticks]                                   }
{    Código de salida 0 si se cumplen todas las invariantes, 1 si no.          }
{******************************************************************************}
program SimulacionSincro;

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

const
  CTerminales = 3;
  CArticulos = 25;
  CPeriodoSincro = 5;

type
  TTerminalSimulado = record
    Nombre: string;
    Almacen: TAlmacenCliente;
    Transporte: TTransporteSimulado;
    Servicio: IServicioSincro;
    Cliente: TClienteSincro;
    VentasCreadas: Integer;
    Reinicios: Integer;
    CiclosConFallo: Integer;
  end;

var
  oServidorObj: TServidorSincro;
  oServidor: IServicioSincro;
  aTerminales: array[0..CTerminales - 1] of TTerminalSimulado;
  oAzar: TAleatorio;
  iSemilla: UInt64;
  iTicks: Integer;
  iErrores: Integer;

procedure Fallo(const ATexto: string);
begin
  Inc(iErrores);
  Writeln('  [FALLO] ', ATexto);
end;

procedure Correcto(const ATexto: string);
begin
  Writeln('  [ OK  ] ', ATexto);
end;

procedure Registro(ATick: Integer; const ATexto: string);
begin
  Writeln(Format('t=%4d  %s', [ATick, ATexto]));
end;

procedure CrearTerminales;
var
  iIndice: Integer;
begin
  for iIndice := 0 to CTerminales - 1 do
    with aTerminales[iIndice] do
    begin
      Nombre := 'CAJA' + IntToStr(iIndice + 1);
      Almacen := TAlmacenCliente.Create(Nombre);
      Transporte := TTransporteSimulado.Create(
        oServidor, iSemilla * 31 + UInt64(iIndice) + 1);
      Servicio := Transporte; // la interfaz mantiene vivo el objeto
      Transporte.Config := ConfigFallos(0.20, 0.15, 0.05);
      Cliente := TClienteSincro.Create(Almacen, Servicio);
      Cliente.TamanoLote := 8;
      Cliente.TamanoPagina := 10;
      Cliente.EsperaMaxima := 30;
    end;
end;

procedure LiberarTerminales;
var
  iIndice: Integer;
begin
  for iIndice := 0 to CTerminales - 1 do
    with aTerminales[iIndice] do
    begin
      Cliente.Free;
      Servicio := nil;
      Almacen.Free;
    end;
end;

procedure ReiniciarTerminal(var ATerminal: TTerminalSimulado; ATick: Integer);
begin
  // El proceso muere: se pierde todo lo que estaba en memoria del motor
  // de sincronización. La base de datos local (el almacén) se conserva.
  ATerminal.Cliente.Free;
  ATerminal.Cliente := TClienteSincro.Create(
    ATerminal.Almacen, ATerminal.Servicio);
  ATerminal.Cliente.TamanoLote := 8;
  ATerminal.Cliente.TamanoPagina := 10;
  ATerminal.Cliente.EsperaMaxima := 30;
  Inc(ATerminal.Reinicios);
  Registro(ATick, Format('%s se reinicia con %d ventas pendientes y cursor %d',
    [ATerminal.Nombre, ATerminal.Almacen.NumeroPendientes,
     ATerminal.Almacen.Cursor]));
end;

function DebeEstarConectado(AIndice, ATick: Integer): Boolean;
begin
  case AIndice of
    0: Result := not ((ATick >= 400) and (ATick < 430));
    1: Result := not ((ATick >= 100) and (ATick < 260)); // corte largo
  else
    Result := not ((ATick >= 520) and (ATick < 540));
  end;
end;

procedure Simular;
var
  iTick, iIndice: Integer;
  bConectado: Boolean;
  cImporte: Currency;
  sPrecio: string;
begin
  Writeln('--- Fase 1: operacion con red inestable ---');
  for iTick := 1 to iTicks do
  begin
    // Backoffice: cambios de precio y alguna baja
    if oAzar.Probable(0.10) then
    begin
      if oAzar.Probable(0.1) then
        oServidorObj.PublicarNovedad(tnBajaArticulo,
          'ART' + IntToStr(oAzar.Entero(CArticulos)), '')
      else
      begin
        sPrecio := IntToStr(1 + oAzar.Entero(50)) + ',' +
          IntToStr(10 + oAzar.Entero(90));
        oServidorObj.PublicarNovedad(tnPrecio,
          'ART' + IntToStr(oAzar.Entero(CArticulos)), sPrecio);
      end;
    end;

    for iIndice := 0 to CTerminales - 1 do
      with aTerminales[iIndice] do
      begin
        bConectado := DebeEstarConectado(iIndice, iTick);
        if bConectado <> Transporte.Conectado then
        begin
          Transporte.Conectado := bConectado;
          if bConectado then
            Registro(iTick, Format('%s recupera la conexion (%d pendientes)',
              [Nombre, Almacen.NumeroPendientes]))
          else
            Registro(iTick, Nombre + ' pierde la conexion');
        end;

        // Vender no depende de la red
        if oAzar.Probable(0.30) then
        begin
          cImporte := (1 + oAzar.Entero(20000)) / 100;
          if oAzar.Probable(0.01) then
            cImporte := -cImporte; // dato erróneo: el servidor lo rechaza
          Almacen.RegistrarVenta('T' + IntToStr(iIndice + 1),
            Almacen.Salida.Count + 1, cImporte, iTick);
          Inc(VentasCreadas);
        end;

        // Reinicio en plena desconexión, con ventas sin subir
        if (iIndice = 2) and (iTick = 530) then
          ReiniciarTerminal(aTerminales[iIndice], iTick);

        if iTick mod CPeriodoSincro = iIndice then
          if not Cliente.Sincronizar(iTick) then
            Inc(CiclosConFallo);
      end;
  end;
end;

function Drenar: Integer;
var
  iRonda, iIndice: Integer;
  bTodoAlDia: Boolean;
begin
  Writeln;
  Writeln('--- Fase 2: red restablecida, drenaje de colas ---');
  for iIndice := 0 to CTerminales - 1 do
  begin
    aTerminales[iIndice].Transporte.Conectado := True;
    aTerminales[iIndice].Transporte.Config := ConfigSinFallos;
  end;
  Result := 0;
  for iRonda := 1 to 200 do
  begin
    bTodoAlDia := True;
    for iIndice := 0 to CTerminales - 1 do
      with aTerminales[iIndice] do
      begin
        // El reloj avanza lo bastante para vencer cualquier espera.
        Cliente.Sincronizar(iTicks + iRonda * 100);
        if (Almacen.NumeroPendientes > 0) or
           (Almacen.Cursor <> oServidorObj.UltimaVersion) then
          bTodoAlDia := False;
      end;
    Result := iRonda;
    if bTodoAlDia then
      Exit;
  end;
end;

procedure Verificar;
var
  iIndice, iEntrada: Integer;
  iConfirmadas, iRechazadas, iSinEnviar, iEnServidor: Integer;
  oEntrada: TEntradaSalida;
  oVentaServidor: TVentaSincro;
  sClave, sValor: string;
  bCatalogoIgual: Boolean;
begin
  Writeln;
  Writeln('--- Fase 3: verificacion de invariantes ---');
  iEnServidor := 0;
  for iIndice := 0 to CTerminales - 1 do
    with aTerminales[iIndice] do
    begin
      iConfirmadas := 0;
      iRechazadas := 0;
      iSinEnviar := 0;
      for iEntrada := 0 to Almacen.Salida.Count - 1 do
      begin
        oEntrada := Almacen.Salida[iEntrada];
        case oEntrada.Estado of
          esPendiente: Inc(iSinEnviar);
          esRechazada:
            begin
              Inc(iRechazadas);
              if oServidorObj.ExisteVenta(oEntrada.Venta.IdEvento,
                   oVentaServidor) then
                Fallo(Nombre + ': venta rechazada presente en el servidor');
            end;
          esConfirmada:
            begin
              Inc(iConfirmadas);
              if not oServidorObj.ExisteVenta(oEntrada.Venta.IdEvento,
                       oVentaServidor) then
                Fallo(Format('%s: venta %d confirmada que no esta en el servidor',
                  [Nombre, oEntrada.Venta.Secuencia]))
              else if (oVentaServidor.Importe <> oEntrada.Venta.Importe) or
                      (oVentaServidor.Secuencia <> oEntrada.Venta.Secuencia) then
                Fallo(Nombre + ': venta con datos distintos en el servidor');
            end;
        end;
      end;
      Inc(iEnServidor, iConfirmadas);

      if iConfirmadas + iRechazadas = VentasCreadas then
        Correcto(Format('%s: %d ventas creadas = %d confirmadas + %d rechazadas',
          [Nombre, VentasCreadas, iConfirmadas, iRechazadas]))
      else
        Fallo(Format('%s: %d creadas, %d confirmadas, %d rechazadas, %d pendientes',
          [Nombre, VentasCreadas, iConfirmadas, iRechazadas, iSinEnviar]));

      bCatalogoIgual :=
        Almacen.Catalogo.Count = oServidorObj.Catalogo.Count;
      if bCatalogoIgual then
        for sClave in oServidorObj.Catalogo.Keys do
          if not Almacen.Catalogo.TryGetValue(sClave, sValor) or
             (sValor <> oServidorObj.Catalogo[sClave]) then
          begin
            bCatalogoIgual := False;
            Break;
          end;
      if bCatalogoIgual and (Almacen.Cursor = oServidorObj.UltimaVersion) then
        Correcto(Format('%s: catalogo identico al servidor (%d articulos, version %d)',
          [Nombre, Almacen.Catalogo.Count, Almacen.Cursor]))
      else
        Fallo(Format('%s: catalogo divergente (cursor %d de %d)',
          [Nombre, Almacen.Cursor, oServidorObj.UltimaVersion]));

      if oServidorObj.CursorConfirmado(Nombre) = Almacen.Cursor then
        Correcto(Format('%s: el servidor tiene confirmada la version %d',
          [Nombre, oServidorObj.CursorConfirmado(Nombre)]))
      else
        Fallo(Format('%s: acuse de novedades atrasado en el servidor (%d de %d)',
          [Nombre, oServidorObj.CursorConfirmado(Nombre), Almacen.Cursor]));
    end;

  if iEnServidor = oServidorObj.NumeroVentas then
    Correcto(Format('Servidor: %d ventas, ninguna duplicada ni perdida',
      [oServidorObj.NumeroVentas]))
  else
    Fallo(Format('Servidor: %d ventas frente a %d confirmadas en terminales',
      [oServidorObj.NumeroVentas, iEnServidor]));

  if oServidorObj.Estadisticas.VentasRepetidas > 0 then
    Correcto(Format('Idempotencia ejercitada: %d reenvios detectados como REPETIDA',
      [oServidorObj.Estadisticas.VentasRepetidas]))
  else
    Fallo('La simulacion no ha provocado ningun reenvio');
end;

procedure Informe(ARondasDrenaje: Integer);
var
  iIndice: Integer;
begin
  Writeln;
  Writeln('--- Estadisticas ---');
  Writeln(Format('Drenaje completado en %d ronda(s)', [ARondasDrenaje]));
  with oServidorObj.Estadisticas do
    Writeln(Format('Servidor: lotes=%d aceptadas=%d repetidas=%d ' +
      'rechazadas=%d peticiones_novedades=%d acuses_novedades=%d ' +
      'novedades_publicadas=%d',
      [LotesRecibidos, VentasAceptadas, VentasRepetidas, VentasRechazadas,
       PeticionesNovedades, Confirmaciones, oServidorObj.UltimaVersion]));
  for iIndice := 0 to CTerminales - 1 do
    with aTerminales[iIndice] do
    begin
      with Transporte.Estadisticas do
        Writeln(Format('%s red:     llamadas=%d sin_conexion=%d ' +
          'peticiones_perdidas=%d respuestas_perdidas=%d duplicados=%d',
          [Nombre, Llamadas, SinConexion, PeticionesPerdidas,
           RespuestasPerdidas, Duplicados]));
      with Cliente.Estadisticas do
        Writeln(Format('%s cliente: ciclos=%d lotes=%d fallos_envio=%d ' +
          'novedades_aplicadas=%d reinicios=%d (desde el ultimo reinicio)',
          [Nombre, Ciclos, LotesEnviados, FallosEnvio, NovedadesAplicadas,
           Reinicios]));
    end;
end;

var
  iRondas: Integer;
begin
  iSemilla := 2026;
  iTicks := 600;
  if ParamCount >= 1 then
    iSemilla := StrToInt64Def(ParamStr(1), 2026);
  if ParamCount >= 2 then
    iTicks := StrToIntDef(ParamStr(2), 600);
  iErrores := 0;
  Writeln(Format('Simulacion de sincronizacion ViraCash (semilla %d, %d ticks)',
    [Int64(iSemilla), iTicks]));
  Writeln;

  oServidorObj := TServidorSincro.Create;
  oServidor := oServidorObj;
  oAzar := TAleatorio.Create(iSemilla);
  try
    CrearTerminales;
    try
      Simular;
      iRondas := Drenar;
      Verificar;
      Informe(iRondas);
    finally
      LiberarTerminales;
    end;
  finally
    oAzar.Free;
    oServidor := nil;
  end;

  Writeln;
  if iErrores = 0 then
    Writeln('RESULTADO: todas las invariantes se cumplen')
  else
    Writeln(Format('RESULTADO: %d invariante(s) incumplida(s)', [iErrores]));
  if iErrores > 0 then
    ExitCode := 1;
end.

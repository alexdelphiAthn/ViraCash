{******************************************************************************}
{                                                                              }
{                    Módulo: UniDataPresupuestosConversion                     }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataPresupuestosConversion;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni, inLibPresupuestosIntf;

function ConvertirPresupuestoUniDAC(AOwner: TComponent;
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto):
  TResultadoConversionPresupuesto;

implementation

uses
  System.SysUtils, Data.DB,
  inLibDocumento, inLibDocumentoIntf,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataAlbaranes, UniDataPedidos;

function ResolverSerieDestino(AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto): string;
var
  oConsulta: TUniQuery;
  sTipo, sEmpresa: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_EMP_PRE, SERIE_DESTINO_PRE FROM fza_presupuestos ' +
      'WHERE SERIE_PRE = :SERIE AND NUMERO_PRE = :NUMERO FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.Numero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorPresupuestoNoExiste);
    Result := oConsulta.FieldByName('SERIE_DESTINO_PRE').AsString;
    if Result = '' then
    begin
      sEmpresa := oConsulta.FieldByName('CODIGO_EMP_PRE').AsString;
      sTipo := CrearConfiguracionDocumento(
        TipoDestinoPresupuesto(ASolicitud.Destino), sdVenta).TipoContador;
      Result := ObtenerSerieDefecto(AConexion, sEmpresa, sTipo);
      if Result = '' then
        raise Exception.CreateFmt(
          SErrorSerieDestinoPresupuesto,
          [sTipo, sEmpresa]);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CopiarPresupuesto(AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto;
  var AResultado: TResultadoConversionPresupuesto);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_PRE_CONVERTIR(:SERIE, :NUMERO, :TIPO, ' +
      ':DESTINO, :USUARIO, @PRE_NUMERO_DESTINO)';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.Numero;
    oConsulta.ParamByName('TIPO').AsString := CrearConfiguracionDocumento(
      AResultado.TipoDocumento, sdVenta).TipoContador;
    oConsulta.ParamByName('DESTINO').AsString := AResultado.Serie;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT @PRE_NUMERO_DESTINO AS NUMERO';
    oConsulta.Open;
    AResultado.Numero := oConsulta.FieldByName('NUMERO').AsString;
    if AResultado.Numero = '' then
      raise Exception.Create(SErrorDestinoPresupuestoNoCreado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Conversion con los datos del dialogo: almacen, serie, numero (vacio =
// contador), fecha, forma de pago (vacia = la del presupuesto) y, en
// facturas, si genera movimientos de stock.
procedure CopiarPresupuestoConOpciones(AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto;
  var AResultado: TResultadoConversionPresupuesto);
const
  SI_NO: array[Boolean] of string = ('N', 'S');
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_PRE_CONVERTIR_DOCUMENTO(:SERIE, :NUMERO, :TIPO, ' +
      ':DESTINO, :NUMERO_MANUAL, :FECHA, :ALMACEN, :MUEVE, ' +
      ':FORMA_PAGO, :USUARIO, @PRE_NUMERO_DESTINO)';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.Numero;
    oConsulta.ParamByName('TIPO').AsString := CrearConfiguracionDocumento(
      AResultado.TipoDocumento, sdVenta).TipoContador;
    oConsulta.ParamByName('DESTINO').AsString := AResultado.Serie;
    oConsulta.ParamByName('NUMERO_MANUAL').AsString :=
      Trim(ASolicitud.Opciones.NumeroDestino);
    oConsulta.ParamByName('FECHA').AsDate :=
      Trunc(ASolicitud.Opciones.Fecha);
    oConsulta.ParamByName('ALMACEN').AsString :=
      Trim(ASolicitud.Opciones.Almacen);
    oConsulta.ParamByName('MUEVE').AsString :=
      SI_NO[ASolicitud.Opciones.MueveStock];
    oConsulta.ParamByName('FORMA_PAGO').AsString :=
      Trim(ASolicitud.Opciones.FormaPago);
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT @PRE_NUMERO_DESTINO AS NUMERO';
    oConsulta.Open;
    AResultado.Numero := oConsulta.FieldByName('NUMERO').AsString;
    if AResultado.Numero = '' then
      raise Exception.Create(SErrorDestinoPresupuestoNoCreado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// El albaran aun no esta confirmado: el data module temporal nace en
// ConexionPrincipal, que no lo ve (sin salidas de stock ni error) o espera
// sus bloqueos (1205). Lecturas y movimientos van por la conexion de la
// transaccion (FZ-ISSUE-149).
procedure SincronizarAlbaran(AOwner: TComponent;
  AConexion: TUniConnection;
  const AResultado: TResultadoConversionPresupuesto);
var
  oAlbaran: TdmAlbaranes;
begin
  oAlbaran := TdmAlbaranes.Create(AOwner);
  try
    oAlbaran.ReasignarConexion(AConexion);
    oAlbaran.unqryTablaG.SQL.Text :=
      'SELECT NUMERO_ALB, SERIE_ALB, CODIGO_EMP_ALB, CODIGO_CLI_ALB, ' +
      'CODIGO_ALM_ALB, INSTANTE_MOVIMIENTO_ALB, FECHA_ALB ' +
      'FROM fza_albaranes WHERE SERIE_ALB = :SERIE ' +
      'AND NUMERO_ALB = :NUMERO';
    oAlbaran.unqryTablaG.ParamByName('SERIE').AsString := AResultado.Serie;
    oAlbaran.unqryTablaG.ParamByName('NUMERO').AsString := AResultado.Numero;
    oAlbaran.unqryTablaG.Open;
    oAlbaran.GenerarMovimientosSalida;
  finally
    FreeAndNil(oAlbaran);
  end;
end;

procedure RecalcularPedidoCreado(AOwner: TComponent;
  AConexion: TUniConnection;
  const AResultado: TResultadoConversionPresupuesto);
var
  oPedido: TdmPedidos;
begin
  oPedido := TdmPedidos.Create(AOwner);
  try
    oPedido.ReasignarConexion(AConexion);
    oPedido.unqryTablaG.SQL.Add(
      'WHERE SERIE_PED = :SERIE AND NUMERO_PED = :NUMERO');
    oPedido.unqryTablaG.ParamByName('SERIE').AsString := AResultado.Serie;
    oPedido.unqryTablaG.ParamByName('NUMERO').AsString := AResultado.Numero;
    oPedido.unqryTablaG.Open;
    oPedido.unqryPedidosLineas.Open;
    oPedido.CalcularTotalesPedido;
    if oPedido.unqryTablaG.State in dsEditModes then
      oPedido.unqryTablaG.Post;
  finally
    oPedido.Free;
  end;
end;

function ConvertirPresupuestoUniDAC(AOwner: TComponent;
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto):
  TResultadoConversionPresupuesto;
begin
  if AConexion.InTransaction then
    raise Exception.Create(
      SErrorOperacionPendientePresupuesto);
  Result := Default(TResultadoConversionPresupuesto);
  Result.TipoDocumento := TipoDestinoPresupuesto(ASolicitud.Destino);
  Result.Pantalla := PantallaDestinoPresupuesto(ASolicitud.Destino);
  AConexion.StartTransaction;
  try
    if ASolicitud.ConOpciones then
    begin
      Result.Serie := Trim(ASolicitud.Opciones.SerieDestino);
      CopiarPresupuestoConOpciones(AConexion, ASolicitud, Result);
    end
    else
    begin
      Result.Serie := ResolverSerieDestino(AConexion, ASolicitud);
      CopiarPresupuesto(AConexion, ASolicitud, Result);
    end;
    if ASolicitud.Destino = dpPedido then
      RecalcularPedidoCreado(AOwner, AConexion, Result);
    if ASolicitud.Destino = dpAlbaran then
      SincronizarAlbaran(AOwner, AConexion, Result);
    AConexion.Commit;
  except
    if AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

end.

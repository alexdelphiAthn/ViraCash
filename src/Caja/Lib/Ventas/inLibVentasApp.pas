{******************************************************************************}
{  inLibVentasApp: bandeja de borradores de la app para el TPV.                }
{  FZ-ISSUE-353. Copyright (c) Alejandro Laorden Hidalgo.                      }
{******************************************************************************}
unit inLibVentasApp;

interface

uses
  System.SysUtils, System.JSON, inLibParametrosIntf;

type
  TVentaApp = record
    Id: string;
    Descripcion: string;
  end;

  TClienteVentasApp = class
  private
    FParametros: IParametrosAplicacion;
    FPuesto: string;
    FCarpeta: string;
    function Peticion(const AAccion, AId, AReserva: string): TJSONObject;
  public
    constructor Create(const AParametros: IParametrosAplicacion;
      const APuesto: string);
    function Listar: TArray<TVentaApp>;
    function Reservar(const AId: string): TJSONObject;
    // FZ-ISSUE-352: el ticket con la venta ya está grabado. Deja una marca
    // local y la recoge en el servidor; si el acuse falla, Listar reintenta
    // con la marca y la venta no vuelve a ofrecerse.
    procedure MarcarGrabada(const AId, AReserva: string);
    procedure Recoger(const AId, AReserva: string);
    procedure Liberar(const AId, AReserva: string);
  end;

implementation

uses
  System.IOUtils, System.Hash, System.Generics.Collections,
  inLibViraCashApi;

function ExtraerDatos(const ARespuesta: string): TJSONObject;
var
  oRaiz: TJSONValue;
  oDatos: TJSONValue;
begin
  oRaiz := TJSONObject.ParseJSONValue(ARespuesta);
  try
    if not (oRaiz is TJSONObject) then
      raise Exception.Create('Respuesta de bandeja no válida.');
    oDatos := TJSONObject(oRaiz).GetValue('datos');
    if not (oDatos is TJSONObject) then
      raise Exception.Create('Faltan los datos de la bandeja.');
    Result := TJSONObject(oDatos.Clone);
  finally
    oRaiz.Free;
  end;
end;

constructor TClienteVentasApp.Create(
  const AParametros: IParametrosAplicacion; const APuesto: string);
begin
  inherited Create;
  FParametros := AParametros;
  FPuesto := APuesto;
  FCarpeta := TPath.Combine(TPath.GetDocumentsPath, 'ViraCashVentasApp');
  FCarpeta := TPath.Combine(FCarpeta, THashSHA2.GetHashString(
    TClienteViraCashApi.UrlBase(AParametros) + #10 +
    TClienteViraCashApi.Referencia(AParametros) + #10 + APuesto));
  ForceDirectories(FCarpeta);
end;

function TClienteVentasApp.Listar: TArray<TVentaApp>;
var
  rRespuesta: TResultadoViraCashApi;
  sContenido: string;
  oDatos: TJSONObject;
  oVentas: TJSONArray;
  i, n: Integer;
  oCapturada: TJSONValue;
begin
  rRespuesta := TClienteViraCashApi.RecibirJson(FParametros,
    'ventas_app.php', TClienteViraCashApi.ComponerConsulta(
      ['puesto'], [FPuesto]), sContenido);
  if not rRespuesta.Ok then
    raise Exception.Create(rRespuesta.Mensaje);
  oDatos := ExtraerDatos(sContenido);
  try
    oVentas := oDatos.GetValue<TJSONArray>('ventas');
    SetLength(Result, oVentas.Count);
    n := 0;
    for i := 0 to oVentas.Count - 1 do
    begin
      if TFile.Exists(TPath.Combine(FCarpeta,
        oVentas.Items[i].GetValue<string>('id') + '.json')) then
      begin
        oCapturada := TJSONObject.ParseJSONValue(TFile.ReadAllText(
          TPath.Combine(FCarpeta,
            oVentas.Items[i].GetValue<string>('id') + '.json')));
        try
          Recoger(oCapturada.GetValue<string>('id'),
            oCapturada.GetValue<string>('reserva'));
          TFile.Delete(TPath.Combine(FCarpeta,
            oVentas.Items[i].GetValue<string>('id') + '.json'));
        finally
          oCapturada.Free;
        end;
      end
      else
      begin
        Result[n].Id := oVentas.Items[i].GetValue<string>('id');
        Result[n].Descripcion :=
          oVentas.Items[i].GetValue<string>('instante') + ' / ' +
          oVentas.Items[i].GetValue<string>('operario', '') + ' / ' +
          oVentas.Items[i].GetValue<string>('destino', '') + ' / ' +
          oVentas.Items[i].GetValue<string>('dispositivo', '');
        Inc(n);
      end;
    end;
    SetLength(Result, n);
  finally
    oDatos.Free;
  end;
end;

function TClienteVentasApp.Peticion(const AAccion, AId,
  AReserva: string): TJSONObject;
var
  oEnvio: TJSONObject;
  rRespuesta: TResultadoViraCashApi;
begin
  oEnvio := TJSONObject.Create;
  try
    oEnvio.AddPair('accion', AAccion);
    oEnvio.AddPair('id', AId);
    oEnvio.AddPair('puesto', FPuesto);
    oEnvio.AddPair('reserva', AReserva);
    rRespuesta := TClienteViraCashApi.EnviarJson(FParametros,
      'ventas_app.php', oEnvio.ToJSON);
    if not rRespuesta.Ok then
      raise Exception.Create(rRespuesta.Mensaje);
    Result := ExtraerDatos(rRespuesta.Respuesta);
  finally
    oEnvio.Free;
  end;
end;

function TClienteVentasApp.Reservar(const AId: string): TJSONObject;
begin
  Result := Peticion('reservar', AId, '');
end;

procedure TClienteVentasApp.MarcarGrabada(const AId, AReserva: string);
var
  oMarca: TJSONObject;
  sRuta: string;
begin
  sRuta := TPath.Combine(FCarpeta, AId + '.json');
  oMarca := TJSONObject.Create;
  try
    oMarca.AddPair('id', AId);
    oMarca.AddPair('reserva', AReserva);
    TFile.WriteAllText(sRuta + '.tmp', oMarca.ToJSON, TEncoding.UTF8);
  finally
    oMarca.Free;
  end;
  if TFile.Exists(sRuta) then
    TFile.Delete(sRuta);
  TFile.Move(sRuta + '.tmp', sRuta);
  Recoger(AId, AReserva);
  TFile.Delete(sRuta);
end;

procedure TClienteVentasApp.Recoger(const AId, AReserva: string);
begin
  Peticion('recoger', AId, AReserva).Free;
end;

procedure TClienteVentasApp.Liberar(const AId, AReserva: string);
begin
  Peticion('liberar', AId, AReserva).Free;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoApi                                                   }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente REST de la app contra la API común (api/v1/recuentos/*).         }
{    Se autentica con el token API del cliente (Authorization: Bearer); el     }
{    servidor deduce el cliente del token. Respuestas con sobre ok + datos.    }
{******************************************************************************}
unit RecuentoApi;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.NetEncoding, System.Net.HttpClient, System.Net.URLClient,
  RecuentoModelo, RecuentoConfig;

type
  TRecuentoApi = class
  private
    FUltimoError: string;
    procedure PrepararCabeceras(AHttp: THTTPClient);
    function MensajeError(const ABody: string; AStatus: Integer): string;
    function GetJson(const ARuta: string; out ABody: string): Integer;
    function PostJson(const ARuta, ABody: string;
      out ARespuesta: string): Integer;
  public
    function ProbarConexion: Boolean;
    function ListarAlmacenes(out ALista: TArrAlmacen): Boolean;
    function ListarPlantillas(out ALista: TArrPlantilla): Boolean;
    function CrearRecuentoLibre(const ACodigoEmp, ACodigoAlm,
      ADescripcion: string; out AIdRecuento: Int64): Boolean;
    function CrearTraspaso(const ACodigoEmp, AOrigen, ADestino: string;
      out AIdRecuento: Int64): Boolean;
    function DescargarCatalogo(AIdRecuento: Int64;
      out ALista: TArrCatalogo): Boolean;
    function SubirEventos(AIdRecuento: Int64; const AEventos: TArrEvento;
      out AAceptados, ADuplicados: Integer): Boolean;
    function Finalizar(AIdRecuento: Int64): Boolean;
    function Reabrir(AIdRecuento: Int64): Boolean;
    property UltimoError: string read FUltimoError;
  end;

implementation

uses
  TraduccionMovil;

// ============================================================================
//   Helpers JSON
// ============================================================================

function JStr(AObj: TJSONObject; const AClave: string): string;
var
  oVal: TJSONValue;
begin
  Result := '';
  if AObj <> nil then
  begin
    oVal := AObj.GetValue(AClave);
    if (oVal <> nil) and not (oVal is TJSONNull) then
      Result := oVal.Value;
  end;
end;

function TryLeerEnteroJson(AObj: TJSONObject; const AClave: string;
  out AValor: Integer): Boolean;
var
  iValor: Int64;
  oValor: TJSONValue;
begin
  AValor := 0;
  oValor := nil;
  if AObj <> nil then
    oValor := AObj.GetValue(AClave);
  Result := False;
  if oValor is TJSONNumber then
  begin
    if TryStrToInt64(oValor.Value, iValor) then
      Result := (iValor >= 0) and (iValor <= MaxInt);
  end;
  if Result then
    AValor := Integer(iValor);
end;

function JNum(AObj: TJSONObject; const AClave: string): Double;
var
  oVal: TJSONValue;
begin
  Result := 0;
  if AObj <> nil then
  begin
    oVal := AObj.GetValue(AClave);
    if oVal is TJSONNumber then
      Result := TJSONNumber(oVal).AsDouble
    else if (oVal <> nil) and not (oVal is TJSONNull) then
      Result := StrToFloatDef(oVal.Value, 0);
  end;
end;

function StreamAString(AStream: TStream): string;
var
  oSS: TStringStream;
begin
  oSS := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    if AStream.Size > 0 then
      oSS.CopyFrom(AStream, AStream.Size);
    Result := oSS.DataString;
  finally
    FreeAndNil(oSS);
  end;
end;

// La API común responde con un sobre ok + datos: deja solo "datos".
function DatosRespuesta(const ABody: string): string;
var
  oJson, oDatos: TJSONValue;
begin
  Result := ABody;
  oJson := TJSONObject.ParseJSONValue(ABody);
  try
    if oJson is TJSONObject then
    begin
      oDatos := TJSONObject(oJson).GetValue('datos');
      if oDatos <> nil then
        Result := oDatos.ToJSON;
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function ArrayDatos(AJson: TJSONValue; const AClave: string): TJSONArray;
begin
  Result := nil;
  if (AJson is TJSONObject) and
     (TJSONObject(AJson).GetValue(AClave) is TJSONArray) then
    Result := TJSONArray(TJSONObject(AJson).GetValue(AClave));
end;

// ============================================================================
//   Transporte HTTP
// ============================================================================

procedure TRecuentoApi.PrepararCabeceras(AHttp: THTTPClient);
begin
  AHttp.CustomHeaders['Authorization'] := 'Bearer ' + Trim(oConfig.Token);
  AHttp.CustomHeaders['Accept'] := 'application/json';
end;

function TRecuentoApi.MensajeError(const ABody: string;
  AStatus: Integer): string;
var
  oJson: TJSONValue;
  sMsg, sCodigo: string;
begin
  sMsg := '';
  sCodigo := '';
  oJson := TJSONObject.ParseJSONValue(ABody);
  try
    if (oJson is TJSONObject) and
       (TJSONObject(oJson).GetValue('error') is TJSONObject) then
    begin
      sMsg := JStr(TJSONObject(TJSONObject(oJson).GetValue('error')),
        'mensaje');
      sCodigo := UpperCase(JStr(
        TJSONObject(TJSONObject(oJson).GetValue('error')), 'codigo'));
    end;
  finally
    FreeAndNil(oJson);
  end;
  // Se traduce por el código, que es estable; el mensaje del servidor (en
  // español) solo se muestra tal cual si el código es desconocido.
  if sCodigo = 'RECUENTO_NO_ENCONTRADO' then
    sMsg := Tr('Recuento no encontrado.')
  else if sCodigo = 'RECUENTO_CERRADO' then
    sMsg := Tr('El recuento ya está cerrado y no admite esta operación.')
  else if sCodigo = 'TRASPASO_INVALIDO' then
    sMsg := Tr('El almacén de origen y el de destino deben ser distintos.')
  else if sCodigo = 'METODO_NO_PERMITIDO' then
    sMsg := Tr('Método HTTP no permitido.')
  else if sCodigo = 'CUERPO_GRANDE' then
    sMsg := Tr('La petición es demasiado grande.')
  else if sCodigo = 'ERROR_INTERNO' then
    sMsg := Tr('No se pudo completar la operación.')
  else if sCodigo = 'TOKEN_INVALIDO' then
    sMsg := Tr('La credencial no es válida.')
  else if (sCodigo = 'PERMISO_INSUFICIENTE') or
          (sCodigo = 'AMBITO_NO_PERMITIDO') then
    sMsg := Tr('La credencial no permite esta operación.');
  if sMsg = '' then
    sMsg := TrF('Error del servidor (HTTP %d)', [AStatus]);
  Result := sMsg;
end;

function TRecuentoApi.GetJson(const ARuta: string; out ABody: string): Integer;
var
  oHttp: THTTPClient;
  oResp: TMemoryStream;
  oRespHttp: IHTTPResponse;
begin
  Result := 0;
  ABody := '';
  oHttp := THTTPClient.Create;
  oResp := TMemoryStream.Create;
  try
    PrepararCabeceras(oHttp);
    try
      oRespHttp := oHttp.Get(oConfig.UrlBase + ARuta, oResp);
      Result := oRespHttp.StatusCode;
      if Assigned(oConfig.Sesion) then
        oConfig.Sesion.RecibirEstado(Result);
      ABody := StreamAString(oResp);
      if (Result >= 200) and (Result < 300) then
      begin
        Result := 200;
        ABody := DatosRespuesta(ABody);
      end;
    except
      on E: Exception do
      begin
        FUltimoError := TrF('No se pudo conectar: %s', [E.Message]);
        Result := 0;
      end;
    end;
  finally
    FreeAndNil(oResp);
    FreeAndNil(oHttp);
  end;
end;

function TRecuentoApi.PostJson(const ARuta, ABody: string;
  out ARespuesta: string): Integer;
var
  oHttp: THTTPClient;
  oReq: TStringStream;
  oResp: TMemoryStream;
  oRespHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  oHttp := THTTPClient.Create;
  oReq := TStringStream.Create(ABody, TEncoding.UTF8);
  oResp := TMemoryStream.Create;
  try
    PrepararCabeceras(oHttp);
    oHttp.CustomHeaders['Content-Type'] := 'application/json';
    try
      oRespHttp := oHttp.Post(oConfig.UrlBase + ARuta, oReq, oResp);
      Result := oRespHttp.StatusCode;
      if Assigned(oConfig.Sesion) then
        oConfig.Sesion.RecibirEstado(Result);
      ARespuesta := StreamAString(oResp);
      // 201 al crear un recuento: para la app es igual que 200.
      if (Result >= 200) and (Result < 300) then
      begin
        Result := 200;
        ARespuesta := DatosRespuesta(ARespuesta);
      end;
    except
      on E: Exception do
      begin
        FUltimoError := TrF('No se pudo conectar: %s', [E.Message]);
        Result := 0;
      end;
    end;
  finally
    FreeAndNil(oResp);
    FreeAndNil(oReq);
    FreeAndNil(oHttp);
  end;
end;

// ============================================================================
//   API pública
// ============================================================================

function TRecuentoApi.ProbarConexion: Boolean;
var
  sBody: string;
  iStatus: Integer;
begin
  FUltimoError := '';
  iStatus := GetJson('recuentos/almacenes.php', sBody);
  Result := iStatus = 200;
  if (not Result) and (iStatus <> 0) then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.ListarAlmacenes(out ALista: TArrAlmacen): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TAlmacenRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('recuentos/almacenes.php', sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      oArr := ArrayDatos(oJson, 'almacenes');
      if oArr <> nil then
      begin
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.CodigoEmp := JStr(oIt, 'codigo_emp');
            Rec.CodigoAlm := JStr(oIt, 'codigo_alm');
            Rec.Nombre    := JStr(oIt, 'nombre');
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.ListarPlantillas(out ALista: TArrPlantilla): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TPlantillaRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('recuentos/recuentos.php', sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      oArr := ArrayDatos(oJson, 'recuentos');
      if oArr <> nil then
      begin
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.IdRecuento  := Trunc(JNum(oIt, 'id'));
            Rec.CodigoEmp   := JStr(oIt, 'codigo_emp');
            Rec.CodigoAlm   := JStr(oIt, 'codigo_alm');
            Rec.Serie       := JStr(oIt, 'serie');
            Rec.Numero      := JStr(oIt, 'numero');
            Rec.Descripcion := JStr(oIt, 'descripcion');
            Rec.Estado      := JStr(oIt, 'estado');
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.CrearRecuentoLibre(const ACodigoEmp, ACodigoAlm,
  ADescripcion: string; out AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
  oRespJson: TJSONValue;
begin
  Result := False;
  AIdRecuento := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('codigo_emp', ACodigoEmp);
    oReq.AddPair('codigo_alm', ACodigoAlm);
    oReq.AddPair('descripcion', ADescripcion);
    oReq.AddPair('dispositivo', oConfig.Dispositivo);
    iStatus := PostJson('recuentos/recuentos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
        AIdRecuento := Trunc(JNum(TJSONObject(oRespJson), 'id_recuento'));
    finally
      FreeAndNil(oRespJson);
    end;
    Result := AIdRecuento > 0;
    if not Result then
      FUltimoError := Tr('El servidor no devolvió id_recuento');
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.CrearTraspaso(const ACodigoEmp, AOrigen,
  ADestino: string; out AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
  oRespJson: TJSONValue;
begin
  Result := False;
  AIdRecuento := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('tipo', 'TRASPASO');
    oReq.AddPair('codigo_emp', ACodigoEmp);
    oReq.AddPair('codigo_alm', AOrigen);
    oReq.AddPair('codigo_alm_destino', ADestino);
    oReq.AddPair('dispositivo', oConfig.Dispositivo);
    iStatus := PostJson('recuentos/recuentos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
        AIdRecuento := Trunc(JNum(TJSONObject(oRespJson), 'id_recuento'));
    finally
      FreeAndNil(oRespJson);
    end;
    Result := AIdRecuento > 0;
    if not Result then
      FUltimoError := Tr('El servidor no devolvió id_recuento');
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.DescargarCatalogo(AIdRecuento: Int64;
  out ALista: TArrCatalogo): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TItemCatalogoRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('recuentos/catalogo.php?id_recuento=' +
                     IntToStr(AIdRecuento), sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      oArr := ArrayDatos(oJson, 'lineas');
      if oArr <> nil then
      begin
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.CodigoArticulo  := JStr(oIt, 'codigo_articulo');
            Rec.CodigoUnidad    := JStr(oIt, 'codigo_unidad');
            Rec.Descripcion     := JStr(oIt, 'descripcion');
            Rec.CodigoBarras    := JStr(oIt, 'codigo_barras');
            Rec.CantidadTeorica := JNum(oIt, 'cantidad_teorica');
            Rec.EsTrazable      := JStr(oIt, 'estrazable') = 'S';
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.SubirEventos(AIdRecuento: Int64;
  const AEventos: TArrEvento; out AAceptados, ADuplicados: Integer): Boolean;
var
  oReq, oEv: TJSONObject;
  oArr: TJSONArray;
  i, iAceptados, iDuplicados, iStatus: Integer;
  sResp: string;
  oRespJson: TJSONValue;
begin
  Result := False;
  FUltimoError := '';
  AAceptados := 0;
  ADuplicados := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    oReq.AddPair('dispositivo', oConfig.Dispositivo);
    oReq.AddPair('operario', oConfig.Operario);
    oArr := TJSONArray.Create;
    for i := 0 to High(AEventos) do
    begin
      oEv := TJSONObject.Create;
      oEv.AddPair('uuid', AEventos[i].Uuid);
      oEv.AddPair('codigo_barras', AEventos[i].CodigoBarras);
      oEv.AddPair('codigo_articulo', AEventos[i].CodigoArticulo);
      oEv.AddPair('codigo_unidad', AEventos[i].CodigoUnidad);
      oEv.AddPair('cantidad', TJSONNumber.Create(AEventos[i].Cantidad));
      oEv.AddPair('lote', AEventos[i].Lote);
      oEv.AddPair('fecha_caducidad', AEventos[i].FechaCaducidad);
      oEv.AddPair('instante_recuento', AEventos[i].InstanteRecuento);
      oEv.AddPair('zona', AEventos[i].Zona);
      oArr.AddElement(oEv);
    end;
    oReq.AddPair('eventos', oArr);
    iStatus := PostJson('recuentos/eventos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
      begin
        Result := TryLeerEnteroJson(
          TJSONObject(oRespJson), 'aceptados', iAceptados) and
          TryLeerEnteroJson(
            TJSONObject(oRespJson), 'duplicados', iDuplicados) and
          (iAceptados <= Length(AEventos)) and
          (iDuplicados <= Length(AEventos)) and
          (iAceptados + iDuplicados = Length(AEventos));
        if Result then
        begin
          AAceptados := iAceptados;
          ADuplicados := iDuplicados;
        end;
      end;
    finally
      FreeAndNil(oRespJson);
    end;
    if not Result then
      FUltimoError := Tr(
        'El servidor no confirmó íntegramente el lote; ' +
        'la cola local se conserva');
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.Finalizar(AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
begin
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    iStatus := PostJson('recuentos/finalizar.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  Result := iStatus = 200;
  if (not Result) and (iStatus <> 0) then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.Reabrir(AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
begin
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    iStatus := PostJson('recuentos/reabrir.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  Result := iStatus = 200;
  if (not Result) and (iStatus <> 0) then
    FUltimoError := MensajeError(sResp, iStatus);
end;

end.

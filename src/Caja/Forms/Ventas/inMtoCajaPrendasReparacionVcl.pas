{******************************************************************************}
{  Módulo: inMtoCajaPrendasReparacionVcl                                       }
{  Descripción: Relaciona cada servicio cobrado con una prenda de la venta.    }
{******************************************************************************}
unit inMtoCajaPrendasReparacionVcl;

interface

uses
  System.Classes, Data.DB, Uni, inLibReparaciones;

function ElegirPrendasReparacion(AOwner: TComponent; AConexion: TUniConnection;
  ALineas: TDataSet; const AEmpresa, AAlmacen, ACliente: string;
  out APrendas: TArray<TPrendaVentaReparacion>): Boolean;

implementation

uses
  System.SysUtils, System.Math, System.StrUtils,
  UniDataReparacionesVentaTpv, UniDataReparacionesPrendas,
  inMtoModalPrendaReparacion, inMtoModalTrabajoCortina,
  inLibTrabajosCortinas, inMtoModalMedidasCliente,
  inLibMsgReparaciones, inLibMensajesVcl;

procedure RecogerUnidades(AConexion: TUniConnection; ALineas: TDataSet;
  const ACodigos: TArray<string>; ADatos: TReparacionesVentaTpv;
  out APrendas, AServicios: TArray<TPrendaVentaReparacion>);
var
  Marcador: TBookmark;
  Item: TPrendaVentaReparacion;
  iUnidad, i, iUnidades: Integer;
  bServicio, bPiezas: Boolean;
  function Texto(const ACampo: string): string;
  begin
    Result := '';
    if Assigned(ALineas.FindField(ACampo)) then
      Result := ALineas.FieldByName(ACampo).AsString;
  end;
begin
  APrendas := nil;
  AServicios := nil;
  Marcador := ALineas.GetBookmark;
  ALineas.DisableControls;
  try
    ALineas.First;
    while not ALineas.Eof do
    begin
      bServicio := IndexText(Texto('CODIGO_ART_FACLIN'),ACodigos)>=0;
      // FZ-ISSUE-778: el servicio de un depósito ya tiene su orden, con
      // las medidas y la cita que se tomaron al dejar el anticipo.
      if bServicio and (Texto('VIENE_DE_DEPOSITO')='S') and
         ADatos.DepositoConOrden(Texto('ID_DEPOSITO_DEP')) then
        bServicio := False;
      if (ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat>0) and
         PedirDatosServicio(ADatos.ClaseArticuloServicio(
           Texto('CODIGO_ART_FACLIN')), Texto('VIENE_DE_DEPOSITO'),
           Texto('ACCION_DEPOSITO'), False) then
      begin
        iUnidades := Floor(ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat);
        // FZ-ISSUE-786: una tela en metros (o kilos) es una sola prenda,
        // la línea entera, no una por metro.
        bPiezas := True;
        if not bServicio and (Texto('TIPO_ARTICULO_FACLIN')='ESTANDAR') then
          bPiezas := UnidadMedidaPorUnidades(AConexion,
            Texto('TIPO_CANTIDAD_ARTICULO_FACLIN'));
        if not bPiezas then
          iUnidades := 1;
        if bServicio then
          iUnidades := Ceil(ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat);
        for iUnidad := 1 to iUnidades do
        begin
          Item := Default(TPrendaVentaReparacion);
          Item.Descripcion := Texto('DESCRIPCION_ARTICULO_FACLIN');
          if bServicio then
          begin
            Item.Trabajo.Clase := ADatos.ClaseArticuloServicio(
              Texto('CODIGO_ART_FACLIN'));
            Item.ArticuloServicio := Texto('CODIGO_ART_FACLIN');
            Item.LineaServicio := Texto('LINEA_FACLIN');
            Item.UnidadServicio := iUnidad;
            i := Length(AServicios);
            SetLength(AServicios,i+1);
            AServicios[i] := Item;
          end
          else if Texto('TIPO_ARTICULO_FACLIN')='ESTANDAR' then
          begin
            Item.LineaPrenda := Texto('LINEA_FACLIN');
            Item.UnidadPrenda := iUnidad;
            if bPiezas then
              Item.Descripcion := Format('%s [%s] · unidad %d',
                [Item.Descripcion,Texto('CODIGO_UNIDAD_FACLIN'),iUnidad])
            else
              Item.Descripcion := Format('%s [%s] · %s %s',
                [Item.Descripcion,Texto('CODIGO_UNIDAD_FACLIN'),
                FormatFloat('0.###',
                  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat),
                Texto('TIPO_CANTIDAD_ARTICULO_FACLIN')]);
            i := Length(APrendas);
            SetLength(APrendas,i+1);
            APrendas[i] := Item;
          end;
        end;
      end;
      ALineas.Next;
    end;
  finally
    if ALineas.BookmarkValid(Marcador) then
      ALineas.GotoBookmark(Marcador);
    ALineas.FreeBookmark(Marcador);
    ALineas.EnableControls;
  end;
end;

function PedirPrendaCliente(const AServicio: TPrendaVentaReparacion;
  var AEleccion: TPrendaVentaReparacion): Boolean;
var
  Valores: array[0..0] of string;
begin
  Valores[0] := '';
  Result := InputQuery_fza(Format(SPrendaSeleccionar,
    [AServicio.Descripcion, AServicio.UnidadServicio]),
    [SPrendaDescripcionCliente], Valores,
    function(const AValores: array of string): Boolean
    begin
      Result := (Trim(AValores[0]) <> '') and
        (Length(Trim(AValores[0])) <= 200);
      if not Result then
        ShowMessage_fza(SPrendaDescripcionObligatoria);
    end);
  if Result then
    AEleccion.Descripcion := Trim(Valores[0]);
end;

function ElegirUnidadServicio(AOwner: TComponent;
  const AServicio: TPrendaVentaReparacion;
  const ACandidatas: TArray<TPrendaVentaReparacion>;
  out AEleccion: TPrendaVentaReparacion): Boolean;
var
  iSeleccion: Integer;
begin
  Result := True;
  AEleccion := AServicio;
  if Length(ACandidatas)>0 then
  begin
    Result := TfrmModalPrendaReparacion.Elegir(AOwner,
      Format(SPrendaSeleccionar,[AServicio.Descripcion,
        AServicio.UnidadServicio]),ACandidatas,iSeleccion);
    if Result and (iSeleccion>=0) then
    begin
      AEleccion := ACandidatas[iSeleccion];
      AEleccion.LineaServicio := AServicio.LineaServicio;
      AEleccion.UnidadServicio := AServicio.UnidadServicio;
      AEleccion.Trabajo := AServicio.Trabajo;
    end;
  end;
  if Result and ((AServicio.Trabajo.Clase = CLASE_SERVICIO_TALLER) or
    (AServicio.Trabajo.Clase = CLASE_SERVICIO_TRAJE)) and
    (AEleccion.LineaPrenda = '') then
    Result := PedirPrendaCliente(AServicio, AEleccion);
  if Result and ((AServicio.Trabajo.Clase=CLASE_SERVICIO_ALTURA) or
     (AServicio.Trabajo.Clase=CLASE_SERVICIO_INSTALACION)) then
    Result := TfrmModalTrabajoCortina.Editar(AOwner,
      AServicio.Descripcion,AEleccion.Trabajo);
end;

function PrepararAlmacenPrendas(AConexion: TUniConnection;
  const AEmpresa,AAlmacen: string;
  const APrendas: TArray<TPrendaVentaReparacion>): Boolean;
var
  Prenda: TPrendaVentaReparacion;
  bTaller: Boolean;
  oDatos: TDatosPrendasReparacion;
begin
  Result := True;
  bTaller := False;
  for Prenda in APrendas do
    bTaller := bTaller or ((Prenda.LineaPrenda<>'') and
      (Prenda.Trabajo.Clase<>CLASE_SERVICIO_INSTALACION));
  if bTaller then
  begin
    oDatos := TDatosPrendasReparacion.Create(AConexion);
    try
      try
        oDatos.ComprobarPreparacion(AEmpresa,AAlmacen);
      except
        on E: EArgumentException do
        begin
          ShowMessage_fza(E.Message);
          Result := False;
        end;
      end;
    finally
      FreeAndNil(oDatos);
    end;
  end;
end;

function ElegirPrendasReparacion(AOwner: TComponent; AConexion: TUniConnection;
  ALineas: TDataSet; const AEmpresa, AAlmacen, ACliente: string;
  out APrendas: TArray<TPrendaVentaReparacion>): Boolean;
var
  oDatos: TReparacionesVentaTpv;
  Candidatas, Servicios, Ordenes: TArray<TPrendaVentaReparacion>;
  Servicio, Eleccion: TPrendaVentaReparacion;
  sMedicion: string;
  i, j, iSeleccion, iUnidades: Integer;
begin
  Result := True;
  APrendas := nil;
  sMedicion := '';
  oDatos := TReparacionesVentaTpv.Create(AConexion);
  try
    RecogerUnidades(AConexion,ALineas,oDatos.CodigosServicio,oDatos,
      Candidatas,Servicios);
    for Servicio in Servicios do
      if Result then
      begin
        Eleccion := Servicio;
        iSeleccion := -1;
        iUnidades := 0;
        for j := 0 to High(Servicios) do
          if Servicios[j].LineaServicio = Servicio.LineaServicio then
            Inc(iUnidades);
        Ordenes := nil;
        if iUnidades = 1 then
          Ordenes := oDatos.OrdenesPendientes(Servicio.ArticuloServicio,
            ACliente, AAlmacen);
        if Length(Ordenes) > 0 then
        begin
          Result := TfrmModalPrendaReparacion.Elegir(AOwner,
            SOrdenCobrarExistente, Ordenes, iSeleccion, SOrdenCrearNueva);
          if Result and (iSeleccion >= 0) then
          begin
            Eleccion.OrdenExistente := Ordenes[iSeleccion].OrdenExistente;
            Eleccion.LineaOrden := Ordenes[iSeleccion].LineaOrden;
          end;
        end;
        if Result and (Eleccion.OrdenExistente = 0) then
          Result := ElegirUnidadServicio(AOwner,Servicio,Candidatas,Eleccion);
        if Result and (Eleccion.OrdenExistente = 0) and
           (Servicio.Trabajo.Clase = CLASE_SERVICIO_TRAJE) then
        begin
          if sMedicion = '' then
            Result := TfrmModalMedidasCliente.Elegir(AOwner, ACliente,
              sMedicion);
          Eleccion.Trabajo.IdMedicionCliente := sMedicion;
        end;
        if Result then
        begin
          i := Length(APrendas);
          SetLength(APrendas,i+1);
          APrendas[i] := Eleccion;
        end;
      end;
    if Result then
      Result := PrepararAlmacenPrendas(AConexion,AEmpresa,AAlmacen,APrendas);
  finally
    FreeAndNil(oDatos);
  end;
end;

end.

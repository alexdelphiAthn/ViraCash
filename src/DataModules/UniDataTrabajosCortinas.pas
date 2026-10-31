{******************************************************************************}
{                                                                             }
{  Módulo: UniDataTrabajosCortinas                                            }
{  Tipo: Data Module                                                          }
{  Versión: 1.0.0                                                             }
{  Fecha: 31/10/2026                                                          }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  SPDX-License-Identifier: MPL-2.0                                           }
{                                                                             }
{  Descripción: Persistencia de medidas y citas por unidad de la orden.       }
{                                                                             }
{******************************************************************************}
unit UniDataTrabajosCortinas;

interface

uses
  Uni, inLibReparaciones, inLibGarantiasResguardo;

procedure ExigirEsquemaTrabajosCortinas(AConexion: TUniConnection);

type
  TDatosTrabajosCortinas = class
  private
    FConexion: TUniConnection;
    function Consulta(const ASql: string): TUniQuery;
    function Disponible: Boolean;
    procedure GuardarUnidad(AReparacion: Int64;
      const ADetalle: TPrendaVentaReparacion; const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    function Leer(AReparacion: Int64): TArray<TPrendaVentaReparacion>;
    procedure Guardar(AReparacion: Int64;
      const ADetalles: TArray<TPrendaVentaReparacion>; const AUsuario: string);
    procedure GuardarEdicion(AReparacion: Int64;
      const ADetalles: TArray<TPrendaVentaReparacion>; const AUsuario: string);
    procedure GuardarVenta(AReparacion: Int64; const ALinea,AClase: string;
      ACantidad: Double; const AVenta: TVentaServiciosReparacion);
    procedure CompletarResguardo(AReparacion: Int64;
      var AResguardo: TResguardoGarantia);
  end;

implementation

uses
  System.SysUtils, System.Math, Data.DB, inLibTrabajosCortinas,
  inLibMsgReparaciones;

procedure ExigirEsquemaTrabajosCortinas(AConexion: TUniConnection);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=''fza_garantias_tipos'' '+
      'AND COLUMN_NAME=''CLASE_SERVICIO_GARTIP''';
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SErrorDetalleCortina);
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TDatosTrabajosCortinas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TDatosTrabajosCortinas.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TDatosTrabajosCortinas.Disponible: Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA=DATABASE() ' +
    'AND TABLE_NAME=''fza_reparaciones_detalles''');
  try
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosTrabajosCortinas.Leer(AReparacion: Int64):
  TArray<TPrendaVentaReparacion>;
var
  oConsulta: TUniQuery;
  Detalle: TPrendaVentaReparacion;
  i: Integer;
begin
  Result := nil;
  if Disponible then
  begin
    oConsulta := Consulta('SELECT UNIDAD_SERVICIO_GARDET, ' +
      'CLASE_SERVICIO_GARDET,ALTURA_MEDIDA_GARDET,LARGO_FINAL_GARDET, ' +
      'INSTRUCCIONES_ACABADO_GARDET,DIRECCION_INSTALACION_GARDET, ' +
      'FECHA_CITA_GARDET FROM fza_reparaciones_detalles ' +
      'WHERE ID_GAR_GARDET=:ID ORDER BY UNIDAD_SERVICIO_GARDET');
    try
      oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        Detalle := Default(TPrendaVentaReparacion);
        Detalle.UnidadServicio := oConsulta.Fields[0].AsInteger;
        Detalle.Trabajo.Clase := oConsulta.Fields[1].AsString;
        Detalle.Trabajo.AlturaMedida := oConsulta.Fields[2].AsFloat;
        Detalle.Trabajo.LargoFinal := oConsulta.Fields[3].AsFloat;
        Detalle.Trabajo.Acabado := oConsulta.Fields[4].AsString;
        Detalle.Trabajo.Direccion := oConsulta.Fields[5].AsString;
        Detalle.Trabajo.Cita := oConsulta.Fields[6].AsDateTime;
        i := Length(Result);
        SetLength(Result,i+1);
        Result[i] := Detalle;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TDatosTrabajosCortinas.GuardarUnidad(AReparacion: Int64;
  const ADetalle: TPrendaVentaReparacion; const AUsuario: string);
var
  oConsulta: TUniQuery;
  sError: string;
begin
  sError := ValidarTrabajoCortina(ADetalle.Trabajo);
  if sError<>'' then
    raise EArgumentException.Create(sError);
  if ADetalle.UnidadServicio<1 then
    raise EArgumentException.Create(SPrendaVentaInvalida);
  oConsulta := Consulta('INSERT INTO fza_reparaciones_detalles ' +
    '(ID_GAR_GARDET,UNIDAD_SERVICIO_GARDET,CLASE_SERVICIO_GARDET, ' +
    'ALTURA_MEDIDA_GARDET,LARGO_FINAL_GARDET,INSTRUCCIONES_ACABADO_GARDET, ' +
    'DIRECCION_INSTALACION_GARDET,FECHA_CITA_GARDET,INSTANTE_ALTA, ' +
    'USUARIO_ALTA) VALUES (:ID,:UNIDAD,:CLASE,NULLIF(:ALTURA,0), ' +
    'NULLIF(:LARGO,0),:ACABADO,:DIRECCION,:CITA,NOW(6),:USUARIO) ' +
    'ON DUPLICATE KEY UPDATE CLASE_SERVICIO_GARDET=VALUES(' +
    'CLASE_SERVICIO_GARDET), ' +
    'ALTURA_MEDIDA_GARDET=VALUES(ALTURA_MEDIDA_GARDET), ' +
    'LARGO_FINAL_GARDET=VALUES(LARGO_FINAL_GARDET), ' +
    'INSTRUCCIONES_ACABADO_GARDET=VALUES(INSTRUCCIONES_ACABADO_GARDET), ' +
    'DIRECCION_INSTALACION_GARDET=VALUES(DIRECCION_INSTALACION_GARDET), ' +
    'FECHA_CITA_GARDET=VALUES(FECHA_CITA_GARDET),INSTANTE_MODIF=NOW(6), ' +
    'USUARIO_MODIF=:USUARIO');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.ParamByName('UNIDAD').AsInteger := ADetalle.UnidadServicio;
    oConsulta.ParamByName('CLASE').AsString := ADetalle.Trabajo.Clase;
    oConsulta.ParamByName('ALTURA').AsFloat := ADetalle.Trabajo.AlturaMedida;
    oConsulta.ParamByName('LARGO').AsFloat := ADetalle.Trabajo.LargoFinal;
    oConsulta.ParamByName('ACABADO').AsString := ADetalle.Trabajo.Acabado;
    oConsulta.ParamByName('DIRECCION').AsString := ADetalle.Trabajo.Direccion;
    oConsulta.ParamByName('CITA').DataType := ftDateTime;
    if ADetalle.Trabajo.Cita>0 then
      oConsulta.ParamByName('CITA').AsDateTime := ADetalle.Trabajo.Cita
    else
      oConsulta.ParamByName('CITA').Clear;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario,1,50);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosTrabajosCortinas.Guardar(AReparacion: Int64;
  const ADetalles: TArray<TPrendaVentaReparacion>; const AUsuario: string);
var
  oConsulta: TUniQuery;
  Detalle: TPrendaVentaReparacion;
begin
  if not FConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorArticuloServicioTransaccion);
  if not Disponible then
    raise EArgumentException.Create(SErrorDetalleCortina);
  oConsulta := Consulta('SELECT ID_GAR FROM fza_garantias_reclamaciones ' +
    'WHERE ID_GAR=:ID AND FECHA_ENTREGA_CLI_GAR IS NULL ' +
    'AND ESTADO_GAR IN (''ABIERTA'',''EN_SAT'') FOR UPDATE');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SFaseCerrada);
    for Detalle in ADetalles do
      GuardarUnidad(AReparacion,Detalle,AUsuario);
    oConsulta.Close;
    oConsulta.SQL.Text := 'UPDATE fza_garantias_reclamaciones ' +
      'SET FECHA_PREVISTA_GAR=COALESCE((SELECT DATE(MIN(FECHA_CITA_GARDET)) '+
      'FROM fza_reparaciones_detalles WHERE ID_GAR_GARDET=:ID ' +
      'AND CLASE_SERVICIO_GARDET=''INSTALACION''),FECHA_PREVISTA_GAR), ' +
      'USUARIO_MODIF=:USUARIO,INSTANTE_MODIF=NOW(6) WHERE ID_GAR=:ID';
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario,1,50);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosTrabajosCortinas.GuardarEdicion(AReparacion: Int64;
  const ADetalles: TArray<TPrendaVentaReparacion>; const AUsuario: string);
var
  bPropia: Boolean;
  oTransaccion: TUniQuery;
begin
  bPropia := not FConexion.InTransaction;
  oTransaccion := Consulta('SAVEPOINT CORTINA_EDICION');
  try
    if bPropia then
      FConexion.StartTransaction
    else
      oTransaccion.Execute;
    try
      Guardar(AReparacion,ADetalles,AUsuario);
      if bPropia then
        FConexion.Commit
      else
      begin
        oTransaccion.SQL.Text := 'RELEASE SAVEPOINT CORTINA_EDICION';
        oTransaccion.Execute;
      end;
    except
      if bPropia then
        FConexion.Rollback
      else
      begin
        oTransaccion.SQL.Text := 'ROLLBACK TO SAVEPOINT CORTINA_EDICION';
        oTransaccion.Execute;
      end;
      raise;
    end;
  finally
    FreeAndNil(oTransaccion);
  end;
end;

procedure TDatosTrabajosCortinas.GuardarVenta(AReparacion: Int64;
  const ALinea,AClase: string; ACantidad: Double;
  const AVenta: TVentaServiciosReparacion);
var
  Detalle: TPrendaVentaReparacion;
  Detalles: TArray<TPrendaVentaReparacion>;
  i,j: Integer;
begin
  if (AClase=CLASE_SERVICIO_ALTURA) or
     (AClase=CLASE_SERVICIO_INSTALACION) then
  begin
    Detalles := nil;
    for Detalle in AVenta.Prendas do
      if Detalle.LineaServicio=ALinea then
      begin
        if (Detalle.Trabajo.Clase<>AClase) or
           (Detalle.UnidadServicio<1) or
           (Detalle.UnidadServicio>Ceil(ACantidad)) then
          raise EArgumentException.Create(SErrorClaseServicio);
        for j := 0 to High(Detalles) do
          if Detalles[j].UnidadServicio=Detalle.UnidadServicio then
            raise EArgumentException.Create(SPrendaVentaInvalida);
        i := Length(Detalles);
        SetLength(Detalles,i+1);
        Detalles[i] := Detalle;
      end;
    if Length(Detalles)<>Ceil(ACantidad) then
      raise EArgumentException.Create(SErrorClaseServicio);
    Guardar(AReparacion,Detalles,AVenta.Usuario);
  end;
end;

procedure TDatosTrabajosCortinas.CompletarResguardo(AReparacion: Int64;
  var AResguardo: TResguardoGarantia);
var
  Detalle: TPrendaVentaReparacion;
  sTexto: string;
begin
  AResguardo.DetallesServicio := '';
  AResguardo.ClaseServicio := '';
  for Detalle in Leer(AReparacion) do
  begin
    sTexto := TextoTrabajoCortina(Detalle.Trabajo);
    if sTexto<>'' then
    begin
      if AResguardo.DetallesServicio<>'' then
        AResguardo.DetallesServicio := AResguardo.DetallesServicio+sLineBreak;
      AResguardo.DetallesServicio := AResguardo.DetallesServicio+
        Format(SDetalleUnidad,[Detalle.UnidadServicio])+sLineBreak+sTexto;
      AResguardo.ClaseServicio := Detalle.Trabajo.Clase;
    end;
  end;
end;

end.

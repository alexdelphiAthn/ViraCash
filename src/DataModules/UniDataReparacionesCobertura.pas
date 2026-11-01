{******************************************************************************}
{  Módulo: UniDataReparacionesCobertura. Tipo: Persistencia                    }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Acuerdo, reparto por conceptos y cierre técnico de la orden.   }
{******************************************************************************}
unit UniDataReparacionesCobertura;

interface

uses
  Uni, UniDataReparacionesCircuitoBase, inLibReparacionesCircuito;

type
  TRepositorioCoberturaOrden = class(TRepositorioCircuitoOrden)
  private
    procedure PersistirAcuerdo(AOrden: Int64; const AAcuerdo: TAcuerdoOrden);
    procedure PersistirConcepto(AOrden: Int64;
      const ADetalle: TDetalleConceptoOrden);
    procedure ExigirRepartoDocumentado(AOrden: Int64);
  public
    function Acuerdo(AOrden: Int64): TAcuerdoOrden;
    procedure GuardarAcuerdo(AOrden: Int64; const AAcuerdo: TAcuerdoOrden);
    function Concepto(AOrden, ALinea: Int64): TDetalleConceptoOrden;
    procedure GuardarConcepto(AOrden: Int64;
      const ADetalle: TDetalleConceptoOrden);
    function Conceptos(AOrden: Int64): TArray<TConceptoOrden>;
    function Reparto(AOrden: Int64): TArray<TRepartoConceptoOrden>;
    procedure ComprobarEntrega(AOrden: Int64;
      AAceptarPendientes: Boolean = False);
    procedure CerrarTecnico(AOrden: Int64; const AExcepcion: string);
  end;

procedure ComprobarEntregaCircuito(AConexion: TUniConnection;
  AOrden: Int64; const AUsuario: string);

implementation

uses
  System.SysUtils, System.Math, System.StrUtils, Data.DB, inLibReparaciones,
  inLibMsgReparacionesCircuito;

function TRepositorioCoberturaOrden.Acuerdo(AOrden: Int64): TAcuerdoOrden;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TAcuerdoOrden);
  oConsulta := Consulta('SELECT REFERENCIA_RAC,AUTORIZACION_RAC,' +
    'PORCENTAJE_MANO_OBRA_RAC,PORCENTAJE_MATERIAL_RAC,TOTAL_LIMITE_RAC,' +
    'TOTAL_FRANQUICIA_RAC,ESAUTORIZADO_RAC,ESACEPTADO_CLIENTE_RAC,' +
    'REVISION_RAC FROM fza_reparaciones_acuerdos WHERE ID_GAR_RAC=:ID');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AOrden;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Referencia := oConsulta.Fields[0].AsString;
      Result.Autorizacion := oConsulta.Fields[1].AsString;
      Result.PorcentajeManoObra := oConsulta.Fields[2].AsCurrency;
      Result.PorcentajeMaterial := oConsulta.Fields[3].AsCurrency;
      Result.TieneLimite := not oConsulta.Fields[4].IsNull;
      Result.Limite := oConsulta.Fields[4].AsCurrency;
      Result.Franquicia := oConsulta.Fields[5].AsCurrency;
      Result.Autorizado := oConsulta.Fields[6].AsString = 'S';
      Result.ClienteAcepta := oConsulta.Fields[7].AsString = 'S';
      Result.Revision := oConsulta.Fields[8].AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  // Sin acuerdo de pagadores, una orden de pago del cliente se cobra al
  // precio pactado en la recepción: el arreglo sencillo no queda pendiente.
  if Result.Revision = 0 then
  begin
    oConsulta := Consulta('SELECT MODALIDAD_GAR FROM ' +
      'fza_garantias_reclamaciones WHERE ID_GAR=:ID');
    try
      oConsulta.ParamByName('ID').AsLargeInt := AOrden;
      oConsulta.Open;
      Result.ClienteAcepta := not oConsulta.IsEmpty and
        (oConsulta.Fields[0].AsString = MODALIDAD_REPARACION_PAGO);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioCoberturaOrden.PersistirAcuerdo(AOrden: Int64;
  const AAcuerdo: TAcuerdoOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_acuerdos ' +
    '(ID_GAR_RAC,REFERENCIA_RAC,AUTORIZACION_RAC,' +
    'PORCENTAJE_MANO_OBRA_RAC,PORCENTAJE_MATERIAL_RAC,TOTAL_LIMITE_RAC,' +
    'TOTAL_FRANQUICIA_RAC,ESAUTORIZADO_RAC,ESACEPTADO_CLIENTE_RAC,' +
    'REVISION_RAC,USUARIO_ALTA) VALUES (:ID,:REFERENCIA,:AUTORIZACION,' +
    ':MANO_OBRA,:MATERIAL,:LIMITE,:FRANQUICIA,:AUTORIZADO,:ACEPTADO,' +
    ':REVISION+1,:USUARIO) ON DUPLICATE KEY UPDATE ' +
    'REFERENCIA_RAC=VALUES(REFERENCIA_RAC),' +
    'AUTORIZACION_RAC=VALUES(AUTORIZACION_RAC),' +
    'PORCENTAJE_MANO_OBRA_RAC=VALUES(PORCENTAJE_MANO_OBRA_RAC),' +
    'PORCENTAJE_MATERIAL_RAC=VALUES(PORCENTAJE_MATERIAL_RAC),' +
    'TOTAL_LIMITE_RAC=VALUES(TOTAL_LIMITE_RAC),' +
    'TOTAL_FRANQUICIA_RAC=VALUES(TOTAL_FRANQUICIA_RAC),' +
    'ESAUTORIZADO_RAC=VALUES(ESAUTORIZADO_RAC),' +
    'ESACEPTADO_CLIENTE_RAC=VALUES(ESACEPTADO_CLIENTE_RAC),' +
    'REVISION_RAC=VALUES(REVISION_RAC),ESCIERRE_TECNICO_RAC=''N'',' +
    'INSTANTE_MODIF=NOW(),USUARIO_MODIF=VALUES(USUARIO_ALTA)');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AOrden;
    oConsulta.ParamByName('REFERENCIA').AsString := AAcuerdo.Referencia;
    oConsulta.ParamByName('AUTORIZACION').AsString := AAcuerdo.Autorizacion;
    oConsulta.ParamByName('MANO_OBRA').AsCurrency :=
      AAcuerdo.PorcentajeManoObra;
    oConsulta.ParamByName('MATERIAL').AsCurrency := AAcuerdo.PorcentajeMaterial;
    oConsulta.ParamByName('LIMITE').DataType := ftCurrency;
    if AAcuerdo.TieneLimite then
      oConsulta.ParamByName('LIMITE').AsCurrency := AAcuerdo.Limite
    else
      oConsulta.ParamByName('LIMITE').Clear;
    oConsulta.ParamByName('FRANQUICIA').AsCurrency := AAcuerdo.Franquicia;
    oConsulta.ParamByName('AUTORIZADO').AsString :=
      IfThen(AAcuerdo.Autorizado, 'S', 'N');
    oConsulta.ParamByName('ACEPTADO').AsString :=
      IfThen(AAcuerdo.ClienteAcepta, 'S', 'N');
    oConsulta.ParamByName('REVISION').AsInteger := AAcuerdo.Revision;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCoberturaOrden.GuardarAcuerdo(AOrden: Int64;
  const AAcuerdo: TAcuerdoOrden);
begin
  ValidarAcuerdoOrden(AAcuerdo);
  Transaccion(
    procedure
    var
      rAnterior: TAcuerdoOrden;
    begin
      BloquearOrden(AOrden);
      rAnterior := Acuerdo(AOrden);
      if rAnterior.Revision <> AAcuerdo.Revision then
        raise EArgumentException.Create(SCircuitoConflicto);
      PersistirAcuerdo(AOrden, AAcuerdo);
      ExigirRepartoDocumentado(AOrden);
      Historial(AOrden, 0, 'ACUERDO', Format(
        'R%d. %s. Autorización %s. MO %g%% -> %g%%; piezas %g%% -> %g%%.' +
        ' Límite %g; franquicia %g. Aceptado cliente %s.',
        [AAcuerdo.Revision, AAcuerdo.Referencia, AAcuerdo.Autorizacion,
         rAnterior.PorcentajeManoObra, AAcuerdo.PorcentajeManoObra,
         rAnterior.PorcentajeMaterial, AAcuerdo.PorcentajeMaterial,
         AAcuerdo.Limite, AAcuerdo.Franquicia,
         BoolToStr(AAcuerdo.ClienteAcepta, True)]));
    end);
end;

function TRepositorioCoberturaOrden.Concepto(AOrden,
  ALinea: Int64): TDetalleConceptoOrden;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDetalleConceptoOrden);
  Result.Concepto.Linea := ALinea;
  oConsulta := Consulta('SELECT VALOR_HORAS_PREVISTAS_RCC,' +
    'VALOR_HORAS_FACTURABLES_RCC,ESCOBERTURA_PROPIA_RCC,' +
    'PORCENTAJE_COBERTURA_RCC,TOTAL_LIMITE_RCC,TOTAL_TALLER_RCC,' +
    'ESACEPTADO_CLIENTE_RCC,REVISION_RCC ' +
    'FROM fza_reparaciones_conceptos ' +
    'WHERE ID_GAR_RCC=:ORDEN AND ID_GARLIN_RCC=:LINEA');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.HorasPrevistas := oConsulta.Fields[0].AsFloat;
      Result.HorasFacturables := oConsulta.Fields[1].AsFloat;
      Result.PorHoras := not oConsulta.Fields[1].IsNull;
      Result.Concepto.CoberturaPropia := oConsulta.Fields[2].AsString = 'S';
      Result.Concepto.Porcentaje := oConsulta.Fields[3].AsCurrency;
      Result.Concepto.TieneLimite := not oConsulta.Fields[4].IsNull;
      Result.Concepto.Limite := oConsulta.Fields[4].AsCurrency;
      Result.Concepto.Taller := oConsulta.Fields[5].AsCurrency;
      Result.Concepto.ClienteAcepta := oConsulta.Fields[6].AsString = 'S';
      Result.Revision := oConsulta.Fields[7].AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCoberturaOrden.PersistirConcepto(AOrden: Int64;
  const ADetalle: TDetalleConceptoOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_conceptos ' +
    '(ID_GAR_RCC,ID_GARLIN_RCC,VALOR_HORAS_PREVISTAS_RCC,' +
    'VALOR_HORAS_FACTURABLES_RCC,ESCOBERTURA_PROPIA_RCC,' +
    'PORCENTAJE_COBERTURA_RCC,TOTAL_LIMITE_RCC,TOTAL_TALLER_RCC,' +
    'ESACEPTADO_CLIENTE_RCC,REVISION_RCC,' +
    'USUARIO_ALTA) VALUES (:ORDEN,:LINEA,:PREVISTAS,:FACTURABLES,' +
    ':PROPIA,:PORCENTAJE,:LIMITE,:TALLER,:ACEPTADO,' +
    ':REVISION+1,:USUARIO) ON DUPLICATE KEY UPDATE ' +
    'VALOR_HORAS_PREVISTAS_RCC=VALUES(VALOR_HORAS_PREVISTAS_RCC),' +
    'VALOR_HORAS_FACTURABLES_RCC=VALUES(VALOR_HORAS_FACTURABLES_RCC),' +
    'ESCOBERTURA_PROPIA_RCC=VALUES(ESCOBERTURA_PROPIA_RCC),' +
    'PORCENTAJE_COBERTURA_RCC=VALUES(PORCENTAJE_COBERTURA_RCC),' +
    'TOTAL_LIMITE_RCC=VALUES(TOTAL_LIMITE_RCC),' +
    'TOTAL_TALLER_RCC=VALUES(TOTAL_TALLER_RCC),' +
    'ESACEPTADO_CLIENTE_RCC=VALUES(ESACEPTADO_CLIENTE_RCC),' +
    'REVISION_RCC=VALUES(REVISION_RCC),' +
    'INSTANTE_MODIF=NOW(),USUARIO_MODIF=VALUES(USUARIO_ALTA)');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ADetalle.Concepto.Linea;
    oConsulta.ParamByName('PREVISTAS').AsFloat := ADetalle.HorasPrevistas;
    oConsulta.ParamByName('FACTURABLES').DataType := ftFloat;
    if ADetalle.PorHoras then
      oConsulta.ParamByName('FACTURABLES').AsFloat := ADetalle.HorasFacturables
    else
      oConsulta.ParamByName('FACTURABLES').Clear;
    oConsulta.ParamByName('PROPIA').AsString :=
      IfThen(ADetalle.Concepto.CoberturaPropia, 'S', 'N');
    oConsulta.ParamByName('PORCENTAJE').AsCurrency :=
      ADetalle.Concepto.Porcentaje;
    oConsulta.ParamByName('LIMITE').DataType := ftCurrency;
    if ADetalle.Concepto.TieneLimite then
      oConsulta.ParamByName('LIMITE').AsCurrency := ADetalle.Concepto.Limite
    else
      oConsulta.ParamByName('LIMITE').Clear;
    oConsulta.ParamByName('TALLER').AsCurrency := ADetalle.Concepto.Taller;
    oConsulta.ParamByName('ACEPTADO').AsString :=
      IfThen(ADetalle.Concepto.ClienteAcepta, 'S', 'N');
    oConsulta.ParamByName('REVISION').AsInteger := ADetalle.Revision;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCoberturaOrden.GuardarConcepto(AOrden: Int64;
  const ADetalle: TDetalleConceptoOrden);
begin
  if (ADetalle.HorasPrevistas < 0) or (ADetalle.HorasFacturables < 0) then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  Transaccion(
    procedure
    var
      oLinea: TUniQuery;
    begin
      oLinea := BloquearLinea(AOrden, ADetalle.Concepto.Linea);
      try
        if Concepto(AOrden, ADetalle.Concepto.Linea).Revision <>
           ADetalle.Revision then
          raise EArgumentException.Create(SCircuitoConflicto);
        if ADetalle.PorHoras and
           (oLinea.FieldByName('TIPO_LINEA_GARLIN').AsString <>
            LINEA_REPARACION_MANO_OBRA) then
          raise EArgumentException.Create(SCircuitoNoManoObra);
        PersistirConcepto(AOrden, ADetalle);
        Reparto(AOrden);
        ExigirRepartoDocumentado(AOrden);
        Historial(AOrden, ADetalle.Concepto.Linea, 'CONCEPTO',
          Format('R%d. Taller %g; cobertura %g%%; horas facturables %g.',
          [ADetalle.Revision, ADetalle.Concepto.Taller,
           ADetalle.Concepto.Porcentaje, ADetalle.HorasFacturables]));
      finally
        FreeAndNil(oLinea);
      end;
    end);
end;

function TRepositorioCoberturaOrden.Conceptos(
  AOrden: Int64): TArray<TConceptoOrden>;
var
  oConsulta: TUniQuery;
  i: Integer;
begin
  Result := nil;
  oConsulta := Consulta('SELECT L.ID_GARLIN,L.TIPO_LINEA_GARLIN,' +
    'ROUND(COALESCE(C.VALOR_HORAS_FACTURABLES_RCC,L.CANTIDAD_GARLIN)' +
    '*L.PRECIO_CLIENTE_GARLIN,2),COALESCE(C.TOTAL_TALLER_RCC,0),' +
    'C.ESCOBERTURA_PROPIA_RCC,C.PORCENTAJE_COBERTURA_RCC,' +
    'C.TOTAL_LIMITE_RCC,C.ESACEPTADO_CLIENTE_RCC ' +
    'FROM fza_garantias_lineas L LEFT JOIN fza_reparaciones_conceptos C ' +
    'ON C.ID_GARLIN_RCC=L.ID_GARLIN WHERE L.ID_GAR_GARLIN=:ORDEN ' +
    'ORDER BY L.LINEA_GARLIN,L.ID_GARLIN');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      i := Length(Result);
      SetLength(Result, i + 1);
      Result[i].Linea := oConsulta.Fields[0].AsLargeInt;
      Result[i].EsMaterial := oConsulta.Fields[1].AsString =
        LINEA_REPARACION_MATERIAL;
      Result[i].Total := oConsulta.Fields[2].AsCurrency;
      Result[i].Taller := oConsulta.Fields[3].AsCurrency;
      Result[i].CoberturaPropia := oConsulta.Fields[4].AsString = 'S';
      Result[i].Porcentaje := oConsulta.Fields[5].AsCurrency;
      Result[i].TieneLimite := not oConsulta.Fields[6].IsNull;
      Result[i].Limite := oConsulta.Fields[6].AsCurrency;
      Result[i].ClienteAcepta := oConsulta.Fields[7].AsString = 'S';
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCoberturaOrden.Reparto(
  AOrden: Int64): TArray<TRepartoConceptoOrden>;
begin
  Result := RepartirConceptosOrden(Acuerdo(AOrden), Conceptos(AOrden));
end;

procedure TRepositorioCoberturaOrden.ExigirRepartoDocumentado(AOrden: Int64);
var
  oConsulta: TUniQuery;
  rReparto: TRepartoConceptoOrden;
begin
  oConsulta := Consulta('SELECT ID_GARLIN_RCI,' +
    'SUM(IF(TIPO_RCI IN (''CL'',''TC''),TOTAL_RCI,0)) AS CLIENTE,' +
    'SUM(IF(TIPO_RCI=''AS'',TOTAL_RCI,0)) AS ASEGURADORA ' +
    'FROM fza_reparaciones_imputaciones WHERE ID_GAR_RCI=:ORDEN ' +
    'AND TIPO_RCI IN (''CL'',''AS'',''TC'') GROUP BY ID_GARLIN_RCI');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    for rReparto in Reparto(AOrden) do
      if oConsulta.Locate('ID_GARLIN_RCI', rReparto.Linea, []) then
        if (oConsulta.FieldByName('CLIENTE').AsCurrency > rReparto.Cliente) or
           (oConsulta.FieldByName('ASEGURADORA').AsCurrency >
            rReparto.Aseguradora) then
          raise EArgumentException.Create(SCircuitoDocumentado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCoberturaOrden.ComprobarEntrega(AOrden: Int64;
  AAceptarPendientes: Boolean);
var
  rReparto: TRepartoConceptoOrden;
  oConsulta: TUniQuery;
begin
  if (Acuerdo(AOrden).Revision > 0) and not AAceptarPendientes then
    for rReparto in Reparto(AOrden) do
      if rReparto.Pendiente > 0 then
        raise EArgumentException.Create(SCircuitoPendiente);
  oConsulta := Consulta('SELECT 1 FROM fza_reparaciones_tiempos ' +
    'WHERE ID_GAR_RCT=:ORDEN AND INSTANTE_FIN_RCT IS NULL ' +
    'AND ESANULADO_RCT=''N'' UNION ALL ' +
    'SELECT 1 FROM fza_reparaciones_entregas WHERE ID_GAR_RCE=:ORDEN ' +
    'AND CANTIDAD_ENVIADA_RCE>CANTIDAD_RECIBIDA_RCE UNION ALL ' +
    'SELECT 1 FROM fza_garantias_lineas WHERE ID_GAR_GARLIN=:ORDEN ' +
    'AND TIPO_LINEA_GARLIN=''MANO_OBRA'' AND FECHA_FIN_GARLIN IS NULL ' +
    'AND EXISTS (SELECT 1 FROM fza_garantias_reclamaciones G ' +
    'WHERE G.ID_GAR=:ORDEN AND COALESCE(G.ESTADO_PRESUPUESTO_GAR,'''') ' +
    '<>''RECHAZADO'') ' +
    'LIMIT 1');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoPendiente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCoberturaOrden.CerrarTecnico(AOrden: Int64;
  const AExcepcion: string);
begin
  Transaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      BloquearOrden(AOrden);
      ComprobarEntrega(AOrden, Trim(AExcepcion) <> '');
      // Una orden sencilla no tiene acuerdo: se guarda el de por defecto
      // para poder anotar su cierre técnico.
      if Acuerdo(AOrden).Revision = 0 then
        PersistirAcuerdo(AOrden, Acuerdo(AOrden));
      oConsulta := Consulta('UPDATE fza_reparaciones_acuerdos ' +
        'SET ESCIERRE_TECNICO_RAC=''S'',EXCEPCION_ENTREGA_RAC=:MOTIVO,' +
        'INSTANTE_MODIF=NOW(),USUARIO_MODIF=:USUARIO WHERE ID_GAR_RAC=:ID');
      try
        oConsulta.ParamByName('ID').AsLargeInt := AOrden;
        oConsulta.ParamByName('MOTIVO').AsString := AExcepcion;
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> 1 then
          raise EArgumentException.Create(SCircuitoConflicto);
        Historial(AOrden, 0, 'CIERRE_TECNICO', AExcepcion);
      finally
        FreeAndNil(oConsulta);
      end;
    end);
end;

procedure ComprobarEntregaCircuito(AConexion: TUniConnection;
  AOrden: Int64; const AUsuario: string);
var
  oConsulta: TUniQuery;
  oCobertura: TRepositorioCoberturaOrden;
  sExcepcion: string;
begin
  oConsulta := TUniQuery.Create(nil);
  oCobertura := nil;
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA=DATABASE() ' +
      'AND TABLE_NAME=''fza_reparaciones_entregas''';
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      oConsulta.Close;
      oConsulta.SQL.Text := 'SELECT EXCEPCION_ENTREGA_RAC ' +
        'FROM fza_reparaciones_acuerdos WHERE ID_GAR_RAC=:ID ' +
        'AND ESCIERRE_TECNICO_RAC=''S''';
      oConsulta.ParamByName('ID').AsLargeInt := AOrden;
      oConsulta.Open;
      sExcepcion := oConsulta.Fields[0].AsString;
      oCobertura := TRepositorioCoberturaOrden.Create(AConexion, AUsuario);
      oCobertura.ComprobarEntrega(AOrden, Trim(sExcepcion) <> '');
    end;
  finally
    FreeAndNil(oCobertura);
    FreeAndNil(oConsulta);
  end;
end;

end.

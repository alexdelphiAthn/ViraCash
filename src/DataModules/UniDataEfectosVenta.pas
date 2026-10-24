{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEfectosVenta                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de efectos de cobro (vi_efectos_venta).                      }
{******************************************************************************}
unit UniDataEfectosVenta;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn, inLibEfectosCalculo;

type
  TClaveEfectoVenta = record
    SerieFac: string;
    NumeroFac: string;
    NumeroEfec: Integer;
  end;

  TClavesEfectoVenta = TArray<TClaveEfectoVenta>;

  TdmEfectosVenta = class(TdmBase)
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    procedure PrepararClavesFusion(
      AConsulta: TUniQuery;
      const AClaves: TClavesEfectoVenta);
    function LeerResumenFusion(
      AConsulta: TUniQuery): TResumenFusionEfectos;
    procedure ValidarResumenFusion(
      const AResumen: TResumenFusionEfectos;
      ACantidadEsperada: Integer);
    function ObtenerNumeroFusion(
      AConsulta: TUniQuery;
      const ASerie, ANumero: string): Integer;
    procedure InsertarEfectoFusionado(
      AConsulta: TUniQuery;
      const AClaveOrigen: TClaveEfectoVenta;
      ANuevoEfecto: Integer;
      const AReferencia: string);
    function ConciliarEfectosOrigen(
      AConsulta: TUniQuery;
      const ASerie, ANumero: string;
      ANuevoEfecto: Integer;
      const AReferencia: string): Integer;
    procedure RefrescarCartera;
  public
    // Concilia un cobro sobre el efecto y refresca la cartera. Si el cobro es
    // parcial, la BBDD divide el efecto en cobrado y pendiente.
    function RegistrarCobro(const ASerie, ANumero: string; ANumEfec: Integer;
      AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    // Agrupa varios efectos imcobrados en uno unico. Los origenes quedan en
    // estado CONCILIADO y referenciados al efecto resumen.
    function FusionarEfectosPendientes(const AClaves: TClavesEfectoVenta;
      out AReferencia: string): Integer;
  end;

implementation

uses
  inLibMsgVentas;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmEfectosVenta.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  dImporteCobrado: Double;
  sConciliado: string;
  sEstado: string;
  sNumeroRem: string;
  sSerieRem: string;
begin
  inherited;
  sEstado := UpperCase(Trim(DataSet.FieldByName('ESTADO_EFV').AsString));
  sSerieRem := Trim(DataSet.FieldByName('SERIE_REMV_EFV').AsString);
  sNumeroRem := Trim(DataSet.FieldByName('NUMERO_REMV_EFV').AsString);
  sConciliado := Trim(DataSet.FieldByName('ESCONCILIADO_EFV').AsString);
  dImporteCobrado := DataSet.FieldByName('IMPORTE_COBRADO_EFV').AsFloat;
  if (sSerieRem <> '') or (sNumeroRem <> '') or
     (sEstado = 'REMESADO') then
    raise Exception.Create(SErrorBorrarEfectoVentaRemesado);
  if (dImporteCobrado > 0.0001) or (sConciliado = 'S') or
     (sEstado = 'COBRADO') or (sEstado = 'DEVUELTO') or
     (sEstado = 'CONCILIADO') then
    raise Exception.Create(SErrorBorrarEfectoVentaCobrado);
end;

procedure TdmEfectosVenta.PrepararClavesFusion(
  AConsulta: TUniQuery;
  const AClaves: TClavesEfectoVenta);
var
  i: Integer;
begin
  AConsulta.SQL.Text :=
    'CREATE TEMPORARY TABLE IF NOT EXISTS tmp_efv_fusion (' +
    '  SERIE_FAC varchar(20) NOT NULL, ' +
    '  NUMERO_FAC varchar(20) NOT NULL, ' +
    '  NUMERO_EFV int NOT NULL, ' +
    '  PRIMARY KEY (SERIE_FAC, NUMERO_FAC, NUMERO_EFV)) ' +
    'ENGINE=MEMORY';
  AConsulta.ExecSQL;
  AConsulta.SQL.Text := 'DELETE FROM tmp_efv_fusion';
  AConsulta.ExecSQL;
  AConsulta.SQL.Text :=
    'INSERT INTO tmp_efv_fusion ' +
    '  (SERIE_FAC, NUMERO_FAC, NUMERO_EFV) ' +
    'VALUES (:serie, :numero, :efecto)';
  for i := 0 to Length(AClaves) - 1 do
  begin
    AConsulta.ParamByName('serie').AsString := AClaves[i].SerieFac;
    AConsulta.ParamByName('numero').AsString := AClaves[i].NumeroFac;
    AConsulta.ParamByName('efecto').AsInteger := AClaves[i].NumeroEfec;
    AConsulta.ExecSQL;
  end;
end;

function TdmEfectosVenta.LeerResumenFusion(
  AConsulta: TUniQuery): TResumenFusionEfectos;
begin
  AConsulta.SQL.Text :=
    'SELECT COUNT(*) AS VALIDOS, ' +
    '       COUNT(DISTINCT COALESCE(E.CODIGO_EMP_EFV, '''')) ' +
    '         AS EMPRESAS, ' +
    '       COUNT(DISTINCT COALESCE(E.CODIGO_CLI_EFV, '''')) ' +
    '         AS TERCEROS, ' +
    '       COALESCE(SUM(COALESCE(E.IMPORTE_PENDIENTE_EFV, 0)), 0) ' +
    '         AS TOTAL ' +
    '  FROM fza_efectos_venta E ' +
    '  JOIN tmp_efv_fusion T ' +
    '    ON T.SERIE_FAC = E.SERIE_FAC_EFV ' +
    '   AND T.NUMERO_FAC = E.NUMERO_FAC_EFV ' +
    '   AND T.NUMERO_EFV = E.NUMERO_EFV ' +
    ' WHERE COALESCE(E.ESTADO_EFV, '''') IN ('''', ''PENDIENTE'') ' +
    '   AND COALESCE(E.IMPORTE_COBRADO_EFV, 0) <= 0.0001 ' +
    '   AND COALESCE(E.IMPORTE_PENDIENTE_EFV, 0) > 0.0001 ' +
    '   AND COALESCE(E.ESCONCILIADO_EFV, ''N'') <> ''S'' ' +
    '   AND COALESCE(E.SERIE_REMV_EFV, '''') = '''' ' +
    '   AND COALESCE(E.NUMERO_REMV_EFV, '''') = '''' ' +
    '   AND COALESCE(E.SERIE_FAC_CONCILIACION_EFV, '''') = ''''';
  AConsulta.Open;
  Result.CantidadValidos := AConsulta.FieldByName('VALIDOS').AsInteger;
  Result.CantidadEmpresas := AConsulta.FieldByName('EMPRESAS').AsInteger;
  Result.CantidadTerceros := AConsulta.FieldByName('TERCEROS').AsInteger;
  Result.ImportePendiente := AConsulta.FieldByName('TOTAL').AsFloat;
  AConsulta.Close;
end;

procedure TdmEfectosVenta.ValidarResumenFusion(
  const AResumen: TResumenFusionEfectos;
  ACantidadEsperada: Integer);
begin
  case TCalculoFusionEfectos.Validar(AResumen, ACantidadEsperada) of
    efeCantidadInvalida:
      raise Exception.Create(SErrorFusionarEfectosVentaEstado);
    efeOrigenInvalido:
      raise Exception.Create(SErrorFusionarEfectosVentaOrigen);
    efeSinImportePendiente:
      raise Exception.Create(SErrorFusionarEfectosVentaSinPendiente);
  end;
end;

function TdmEfectosVenta.ObtenerNumeroFusion(
  AConsulta: TUniQuery;
  const ASerie, ANumero: string): Integer;
begin
  AConsulta.SQL.Text :=
    'SELECT NUMERO_EFV ' +
    '  FROM fza_efectos_venta ' +
    ' WHERE SERIE_FAC_EFV = :serie ' +
    '   AND NUMERO_FAC_EFV = :numero ' +
    ' FOR UPDATE';
  AConsulta.ParamByName('serie').AsString := ASerie;
  AConsulta.ParamByName('numero').AsString := ANumero;
  AConsulta.Open;
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT COALESCE(MAX(NUMERO_EFV), 0) + 1 AS NUEVO ' +
    '  FROM fza_efectos_venta ' +
    ' WHERE SERIE_FAC_EFV = :serie ' +
    '   AND NUMERO_FAC_EFV = :numero';
  AConsulta.ParamByName('serie').AsString := ASerie;
  AConsulta.ParamByName('numero').AsString := ANumero;
  AConsulta.Open;
  Result := AConsulta.FieldByName('NUEVO').AsInteger;
  AConsulta.Close;
end;

procedure TdmEfectosVenta.InsertarEfectoFusionado(
  AConsulta: TUniQuery;
  const AClaveOrigen: TClaveEfectoVenta;
  ANuevoEfecto: Integer;
  const AReferencia: string);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_efectos_venta ' +
    '  (SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV, ' +
    '   CODIGO_EMP_EFV, CODIGO_CLI_EFV, RAZON_SOCIAL_CLI_EFV, ' +
    '   NIF_CLI_EFV, CODIGO_TEFE_EFV, ESTADO_EFV, ' +
    '   ORDEN_PLAZO_EFV, FECHA_EMISION_EFV, ' +
    '   FECHA_VENCIMIENTO_EFV, FECHA_COBRO_EFV, TIPO_COBRO_EFV, ' +
    '   REFERENCIA_COBRO_EFV, ENTIDAD_COBRO_EFV, ' +
    '   ESCONCILIADO_EFV, IMPORTE_EFV, IMPORTE_COBRADO_EFV, ' +
    '   IMPORTE_PENDIENTE_EFV, SERIE_REMV_EFV, NUMERO_REMV_EFV, ' +
    '   ENTIDAD_EFV, OFICINA_EFV, DIGITO_CONTROL_EFV, ' +
    '   CUENTA_EFV, IBAN_EFV, CODIGO_EMPBAN_EFV, IBAN_EMP_EFV, ' +
    '   DOC_EXTERNO_EFV, REFERENCIA_DOCUMENTO_EFV, ' +
    '   OBSERVACIONES_EFV, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_MODIF) ' +
    'SELECT H.SERIE_FAC_EFV, H.NUMERO_FAC_EFV, :nuevo, ' +
    '       H.CODIGO_EMP_EFV, H.CODIGO_CLI_EFV, ' +
    '       H.RAZON_SOCIAL_CLI_EFV, H.NIF_CLI_EFV, ' +
    '       H.CODIGO_TEFE_EFV, ''PENDIENTE'', H.ORDEN_PLAZO_EFV, ' +
    '       A.FECHA_EMISION, A.FECHA_VENCIMIENTO, NULL, NULL, NULL, ' +
    '       NULL, ''N'', A.TOTAL, 0, A.TOTAL, NULL, NULL, ' +
    '       H.ENTIDAD_EFV, H.OFICINA_EFV, H.DIGITO_CONTROL_EFV, ' +
    '       H.CUENTA_EFV, H.IBAN_EFV, H.CODIGO_EMPBAN_EFV, ' +
    '       H.IBAN_EMP_EFV, H.DOC_EXTERNO_EFV, :referencia, ' +
    '       LEFT(CONCAT(''Agrupa efectos: '', A.REFERENCIAS), 1000), ' +
    '       NOW(), :usuario, NOW(), :usuario ' +
    '  FROM fza_efectos_venta H ' +
    '  JOIN (SELECT MIN(E.FECHA_EMISION_EFV) AS FECHA_EMISION, ' +
    '               MAX(E.FECHA_VENCIMIENTO_EFV) AS FECHA_VENCIMIENTO, ' +
    '               SUM(COALESCE(E.IMPORTE_PENDIENTE_EFV, 0)) ' +
    '                 AS TOTAL, ' +
    '               GROUP_CONCAT(CONCAT(E.SERIE_FAC_EFV, ''/'', ' +
    '                 E.NUMERO_FAC_EFV, ''/'', E.NUMERO_EFV) ' +
    '                 ORDER BY E.FECHA_VENCIMIENTO_EFV, ' +
    '                          E.SERIE_FAC_EFV, E.NUMERO_FAC_EFV, ' +
    '                          E.NUMERO_EFV SEPARATOR '', '') ' +
    '                 AS REFERENCIAS ' +
    '          FROM fza_efectos_venta E ' +
    '          JOIN tmp_efv_fusion T ' +
    '            ON T.SERIE_FAC = E.SERIE_FAC_EFV ' +
    '           AND T.NUMERO_FAC = E.NUMERO_FAC_EFV ' +
    '           AND T.NUMERO_EFV = E.NUMERO_EFV) A ' +
    ' WHERE H.SERIE_FAC_EFV = :serie ' +
    '   AND H.NUMERO_FAC_EFV = :numero ' +
    '   AND H.NUMERO_EFV = :efecto';
  AConsulta.ParamByName('nuevo').AsInteger := ANuevoEfecto;
  AConsulta.ParamByName('referencia').AsString := AReferencia;
  AConsulta.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
  AConsulta.ParamByName('serie').AsString := AClaveOrigen.SerieFac;
  AConsulta.ParamByName('numero').AsString := AClaveOrigen.NumeroFac;
  AConsulta.ParamByName('efecto').AsInteger := AClaveOrigen.NumeroEfec;
  AConsulta.ExecSQL;
end;

function TdmEfectosVenta.ConciliarEfectosOrigen(
  AConsulta: TUniQuery;
  const ASerie, ANumero: string;
  ANuevoEfecto: Integer;
  const AReferencia: string): Integer;
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_efectos_venta E ' +
    '  JOIN tmp_efv_fusion T ' +
    '    ON T.SERIE_FAC = E.SERIE_FAC_EFV ' +
    '   AND T.NUMERO_FAC = E.NUMERO_FAC_EFV ' +
    '   AND T.NUMERO_EFV = E.NUMERO_EFV ' +
    '   SET E.ESTADO_EFV = ''CONCILIADO'', ' +
    '       E.IMPORTE_PENDIENTE_EFV = 0, ' +
    '       E.ESCONCILIADO_EFV = ''S'', ' +
    '       E.REFERENCIA_DOCUMENTO_EFV = :referencia, ' +
    '       E.SERIE_FAC_CONCILIACION_EFV = :serie_dst, ' +
    '       E.NUMERO_FAC_CONCILIACION_EFV = :numero_dst, ' +
    '       E.NUMERO_EFV_CONCILIACION_EFV = :efecto_dst, ' +
    '       E.OBSERVACIONES_EFV = LEFT(CONCAT(' +
    '         COALESCE(NULLIF(E.OBSERVACIONES_EFV, ''''), ''''), ' +
    '         CASE WHEN COALESCE(E.OBSERVACIONES_EFV, '''') = '''' ' +
    '              THEN '''' ELSE '' | '' END, ' +
    '         ''Conciliado en '', :referencia), 1000), ' +
    '       E.INSTANTE_MODIF = NOW(), ' +
    '       E.USUARIO_MODIF = :usuario';
  AConsulta.ParamByName('referencia').AsString := AReferencia;
  AConsulta.ParamByName('serie_dst').AsString := ASerie;
  AConsulta.ParamByName('numero_dst').AsString := ANumero;
  AConsulta.ParamByName('efecto_dst').AsInteger := ANuevoEfecto;
  AConsulta.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
  AConsulta.ExecSQL;
  Result := AConsulta.RowsAffected;
end;

procedure TdmEfectosVenta.RefrescarCartera;
begin
  if Assigned(unqryTablaG) and unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
  end;
end;

function TdmEfectosVenta.FusionarEfectosPendientes(
  const AClaves: TClavesEfectoVenta; out AReferencia: string): Integer;
var
  q: TUniQuery;
  EsTransaccionPropia: Boolean;
  iNuevoEfec: Integer;
  oResumen: TResumenFusionEfectos;
  sNumeroDestino: string;
  sSerieDestino: string;
begin
  Result := 0;
  AReferencia := '';
  if Length(AClaves) >= 2 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      EsTransaccionPropia := not ConexionPrincipal.InTransaction;
      if EsTransaccionPropia then
        ConexionPrincipal.StartTransaction;
      try
        PrepararClavesFusion(q, AClaves);
        oResumen := LeerResumenFusion(q);
        ValidarResumenFusion(oResumen, Length(AClaves));
        sSerieDestino := AClaves[0].SerieFac;
        sNumeroDestino := AClaves[0].NumeroFac;
        iNuevoEfec := ObtenerNumeroFusion(
          q,
          sSerieDestino,
          sNumeroDestino);
        AReferencia := TCalculoFusionEfectos.CrearReferencia(
          sSerieDestino,
          sNumeroDestino,
          iNuevoEfec);
        InsertarEfectoFusionado(
          q,
          AClaves[0],
          iNuevoEfec,
          AReferencia);
        Result := ConciliarEfectosOrigen(
          q,
          sSerieDestino,
          sNumeroDestino,
          iNuevoEfec,
          AReferencia);
        q.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_efv_fusion';
        q.ExecSQL;
        if EsTransaccionPropia then
          ConexionPrincipal.Commit;
      except
        if EsTransaccionPropia and ConexionPrincipal.InTransaction then
          ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
    RefrescarCartera;
  end;
end;

function TdmEfectosVenta.RegistrarCobro(const ASerie, ANumero: string;
  ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  sp: TUniStoredProc;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection     := ConexionPrincipal;
    sp.StoredProcName := 'PRC_EFV_CONCILIAR_COBRO';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString,  'p_SERIE',      ptInput);
    sp.Params.CreateParam(ftString,  'p_NUMERO',     ptInput);
    sp.Params.CreateParam(ftInteger, 'p_NUM_EFV',   ptInput);
    sp.Params.CreateParam(ftDate,    'p_FECHA',      ptInput);
    sp.Params.CreateParam(ftFloat,   'p_IMPORTE',    ptInput);
    sp.Params.CreateParam(ftString,  'p_TIPO',       ptInput);
    sp.Params.CreateParam(ftString,  'p_REFERENCIA', ptInput);
    sp.Params.CreateParam(ftString,  'p_ENTIDAD',    ptInput);
    sp.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
    sp.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
    sp.ParamByName('p_SERIE').AsString      := ASerie;
    sp.ParamByName('p_NUMERO').AsString     := ANumero;
    sp.ParamByName('p_NUM_EFV').AsInteger  := ANumEfec;
    sp.ParamByName('p_FECHA').AsDateTime    := AFecha;
    sp.ParamByName('p_IMPORTE').AsFloat     := AImporte;
    sp.ParamByName('p_TIPO').AsString       := ATipo;
    sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
    sp.ParamByName('p_ENTIDAD').AsString    := '';
    sp.ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
    sp.ExecProc;
    Result := sp.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(sp);
  end;
  if (unqryTablaG <> nil) and unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
  end;
end;

initialization
  RegistrarDataModule(TdmEfectosVenta);
  ForceReferenceToClass(TdmEfectosVenta);
end.



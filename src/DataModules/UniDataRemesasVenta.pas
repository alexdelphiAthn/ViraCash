{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRemesasVenta                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de remesas de cobro (vi_remesas_venta).                      }
{******************************************************************************}
unit UniDataRemesasVenta;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser, UniDataConn, inLibSepaRemesasVenta;

type
  TdmRemesasVenta = class(TdmBase)
    unqryEfectosRemesa: TUniQuery;
    dsEfectosRemesa: TDataSource;
    unqryBancosEmpresa: TUniQuery;
    dsBancosEmpresa: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    function IniciarTransaccionRemesa: Boolean;
    procedure ConfirmarTransaccionRemesa(ATransaccionPropia: Boolean);
    procedure RevertirTransaccionRemesa(ATransaccionPropia: Boolean);
    function AplicarQuitarEfecto: Boolean;
    function AplicarCobroEfectoActual(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function AplicarCobroRemesa(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    procedure ActualizarEstadoRemesa(const ASerie, ANumero: string;
      AFechaCobro: TDateTime);
    function RegistrarCobroEfectoClave(const ASerieFac, ANumeroFac: string;
      ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia, AEntidad: string): Integer;
    procedure RecalcularRemesa(const ASerie, ANumero: string);
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure RefrescarDatos;
    function ActualizarFechaCobro(AFecha: TDateTime): Boolean;
    function AsignarBancoRemesa(const ACodigoEmpban: string): Boolean;
    function CobroRealizadoRemesa: Double;
    function EliminarRemesa: Boolean;
    procedure CargarDatosSepa(var ADatos: TDatosSepaRemesaVenta);
    function GenerarOrdenSepa(const AArchivo: string): Integer;
    function GuardarDatosSepa(
      const ADatos: TDatosSepaRemesaVenta): Boolean;
    function PendienteRemesa: Double;
    function QuitarEfectoActual: Boolean;
    function RegistrarCobroEfectoActual(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function RegistrarCobroRemesa(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function RemesaTieneCobro: Boolean;
  end;

implementation

uses
  inLibMsgVentas, UniDataSepaRemesasVentaRepositorio;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmRemesasVenta.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection := ConexionPrincipal;
  unqryEfectosRemesa.Connection := ConexionPrincipal;
  unqryBancosEmpresa.Connection := ConexionPrincipal;
end;

procedure TdmRemesasVenta.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryEfectosRemesa.MasterSource := ADataSource;
  unqryBancosEmpresa.MasterSource := ADataSource;
end;

procedure TdmRemesasVenta.AbrirDetalles;
begin
  inherited;
  if not unqryBancosEmpresa.Active then
    unqryBancosEmpresa.Open;
  if not unqryEfectosRemesa.Active then
    unqryEfectosRemesa.Open;
end;

procedure TdmRemesasVenta.RefrescarDatos;
var
  bLocalizar: Boolean;
  sSerie: string;
  sNumero: string;
begin
  bLocalizar := unqryTablaG.Active and (not unqryTablaG.IsEmpty);
  if bLocalizar then
  begin
    sSerie := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
  end;
  if unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
    if bLocalizar then
      unqryTablaG.Locate('SERIE_REMV;NUMERO_REMV',
        VarArrayOf([sSerie, sNumero]), []);
  end;
  if unqryBancosEmpresa.Active then
  begin
    unqryBancosEmpresa.Close;
    unqryBancosEmpresa.Open;
  end;
  if unqryEfectosRemesa.Active then
  begin
    unqryEfectosRemesa.Close;
    unqryEfectosRemesa.Open;
  end;
end;

function TdmRemesasVenta.PendienteRemesa: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.FindField('TOTAL_PENDIENTE_REMV') <> nil) then
    Result := unqryTablaG.FieldByName('TOTAL_PENDIENTE_REMV').AsFloat;
end;

function TdmRemesasVenta.CobroRealizadoRemesa: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.FindField('TOTAL_COBRADO_REMV') <> nil) then
    Result := unqryTablaG.FieldByName('TOTAL_COBRADO_REMV').AsFloat;
end;

function TdmRemesasVenta.RemesaTieneCobro: Boolean;
begin
  Result := CobroRealizadoRemesa > 0.0001;
end;

// Cada operación sobre la remesa (cobrar o pagar uno o todos sus efectos,
// quitar un efecto) se confirma entera o nada: los procedimientos de
// conciliación respetan esta transacción desde FZ-ISSUE-143 (FZ-ISSUE-152).
function TdmRemesasVenta.IniciarTransaccionRemesa: Boolean;
begin
  Result := not ConexionPrincipal.InTransaction;
  if Result then
    ConexionPrincipal.StartTransaction;
end;

procedure TdmRemesasVenta.ConfirmarTransaccionRemesa(
  ATransaccionPropia: Boolean);
begin
  if ATransaccionPropia then
    ConexionPrincipal.Commit;
end;

procedure TdmRemesasVenta.RevertirTransaccionRemesa(
  ATransaccionPropia: Boolean);
begin
  if ATransaccionPropia and ConexionPrincipal.InTransaction then
    ConexionPrincipal.Rollback;
end;

procedure TdmRemesasVenta.RecalcularRemesa(const ASerie, ANumero: string);
var
  sp: TUniStoredProc;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection := ConexionPrincipal;
    sp.StoredProcName := 'PRC_REMV_RECALCULAR';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    sp.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    sp.ParamByName('p_SERIE').AsString := ASerie;
    sp.ParamByName('p_NUMERO').AsString := ANumero;
    sp.ExecProc;
  finally
    FreeAndNil(sp);
  end;
end;

procedure TdmRemesasVenta.ActualizarEstadoRemesa(const ASerie,
  ANumero: string; AFechaCobro: TDateTime);
var
  q: TUniQuery;
  sEstado: string;
  iEfectos: Integer;
  fTotal: Double;
  fPendiente: Double;
  fCargado: Double;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'SELECT COUNT(e.NUMERO_EFV) AS EFECTOS, ' +
      '       COALESCE(r.TOTAL_REMV, 0) AS TOTAL, ' +
      '       COALESCE(SUM(COALESCE(e.IMPORTE_PENDIENTE_EFV, 0)), 0) ' +
      '         AS PENDIENTE ' +
      '  FROM fza_remesas_venta r ' +
      '  LEFT JOIN fza_efectos_venta e ' +
      '    ON e.SERIE_REMV_EFV = r.SERIE_REMV ' +
      '   AND e.NUMERO_REMV_EFV = r.NUMERO_REMV ' +
      ' WHERE r.SERIE_REMV = :serie ' +
      '   AND r.NUMERO_REMV = :numero ' +
      ' GROUP BY r.TOTAL_REMV';
    q.ParamByName('serie').AsString := ASerie;
    q.ParamByName('numero').AsString := ANumero;
    q.Open;
    iEfectos := q.FieldByName('EFECTOS').AsInteger;
    fTotal := q.FieldByName('TOTAL').AsFloat;
    fPendiente := q.FieldByName('PENDIENTE').AsFloat;
    fCargado := fTotal - fPendiente;
    sEstado := 'ABIERTA';
    if iEfectos > 0 then
    begin
      if fPendiente <= 0.0001 then
        sEstado := 'COBRADA'
      else if fCargado > 0.0001 then
        sEstado := 'PARCIAL';
    end;
    q.Close;
    if AFechaCobro > 0 then
    begin
      q.SQL.Text :=
        'UPDATE fza_remesas_venta ' +
        '   SET ESTADO_REMV = :estado, ' +
        '       FECHA_CARGO_REMV = :fecha, ' +
        '       INSTANTE_CONTABILIZACION_REMV = ' +
        '         CASE WHEN :estado = ''COBRADA'' THEN NOW() ' +
        '              ELSE INSTANTE_CONTABILIZACION_REMV END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV = :serie ' +
        '   AND NUMERO_REMV = :numero';
      q.ParamByName('fecha').AsDateTime := AFechaCobro;
    end
    else
      q.SQL.Text :=
        'UPDATE fza_remesas_venta ' +
        '   SET ESTADO_REMV = :estado, ' +
        '       INSTANTE_CONTABILIZACION_REMV = ' +
        '         CASE WHEN :estado = ''COBRADA'' THEN NOW() ' +
        '              ELSE INSTANTE_CONTABILIZACION_REMV END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV = :serie ' +
        '   AND NUMERO_REMV = :numero';
    q.ParamByName('estado').AsString := sEstado;
    q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
    q.ParamByName('serie').AsString := ASerie;
    q.ParamByName('numero').AsString := ANumero;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

function SoloAlfanumericoSepa(const AValor: string): string;
var
  i: Integer;
  sValor: string;
begin
  Result := '';
  sValor := UpperCase(Trim(AValor));
  for i := 1 to Length(sValor) do
  begin
    if CharInSet(sValor[i], ['A'..'Z', '0'..'9']) then
      Result := Result + sValor[i];
  end;
end;

function ValorCampoStrSepa(ADataSet: TDataSet; const ACampo: string): string;
begin
  Result := '';
  if (ADataSet.FindField(ACampo) <> nil) and
     (not ADataSet.FieldByName(ACampo).IsNull) then
    Result := Trim(ADataSet.FieldByName(ACampo).AsString);
end;

function ValorCampoFechaSepa(ADataSet: TDataSet; const ACampo: string;
  ADefecto: TDateTime): TDateTime;
begin
  Result := ADefecto;
  if (ADataSet.FindField(ACampo) <> nil) and
     (not ADataSet.FieldByName(ACampo).IsNull) then
    Result := ADataSet.FieldByName(ACampo).AsDateTime;
end;

function TdmRemesasVenta.RegistrarCobroEfectoClave(const ASerieFac,
  ANumeroFac: string; ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia, AEntidad: string): Integer;
var
  sp: TUniStoredProc;
begin
  Result := 0;
  if AImporte > 0 then
  begin
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection := ConexionPrincipal;
      sp.StoredProcName := 'PRC_EFV_CONCILIAR_COBRO';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString, 'p_SERIE', ptInput);
      sp.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      sp.Params.CreateParam(ftInteger, 'p_NUM_EFV', ptInput);
      sp.Params.CreateParam(ftDate, 'p_FECHA', ptInput);
      sp.Params.CreateParam(ftFloat, 'p_IMPORTE', ptInput);
      sp.Params.CreateParam(ftString, 'p_TIPO', ptInput);
      sp.Params.CreateParam(ftString, 'p_REFERENCIA', ptInput);
      sp.Params.CreateParam(ftString, 'p_ENTIDAD', ptInput);
      sp.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
      sp.ParamByName('p_SERIE').AsString := ASerieFac;
      sp.ParamByName('p_NUMERO').AsString := ANumeroFac;
      sp.ParamByName('p_NUM_EFV').AsInteger := ANumEfec;
      sp.ParamByName('p_FECHA').AsDateTime := AFecha;
      sp.ParamByName('p_IMPORTE').AsFloat := AImporte;
      sp.ParamByName('p_TIPO').AsString := ATipo;
      sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
      sp.ParamByName('p_ENTIDAD').AsString := AEntidad;
      sp.ParamByName('p_USUARIO').AsString := IdentidadSesion.Usuario;
      sp.ExecProc;
      Result := sp.ParamByName('p_RESULTADO').AsInteger;
    finally
      FreeAndNil(sp);
    end;
  end;
end;

function TdmRemesasVenta.AplicarCobroEfectoActual(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  ds: TDataSet;
  sSerieRem: string;
  sNumeroRem: string;
  sEntidad: string;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     unqryEfectosRemesa.Active and (not unqryEfectosRemesa.IsEmpty) then
  begin
    ds := unqryEfectosRemesa;
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    sEntidad := unqryTablaG.FieldByName('IBAN_REMV').AsString;
    Result := RegistrarCobroEfectoClave(
      ds.FieldByName('SERIE_FAC_EFV').AsString,
      ds.FieldByName('NUMERO_FAC_EFV').AsString,
      ds.FieldByName('NUMERO_EFV').AsInteger,
      AFecha, AImporte, ATipo, AReferencia, sEntidad);
    if Result > 0 then
      ActualizarEstadoRemesa(sSerieRem, sNumeroRem, AFecha);
  end;
end;

function TdmRemesasVenta.RegistrarCobroEfectoActual(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := IniciarTransaccionRemesa;
  try
    Result := AplicarCobroEfectoActual(AFecha, AImporte, ATipo, AReferencia);
    ConfirmarTransaccionRemesa(bTransaccionPropia);
  except
    RevertirTransaccionRemesa(bTransaccionPropia);
    raise;
  end;
  if Result > 0 then
    RefrescarDatos;
end;

function TdmRemesasVenta.AplicarCobroRemesa(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  q: TUniQuery;
  sSerieRem: string;
  sNumeroRem: string;
  sEntidad: string;
  sSerieFac: string;
  sNumeroFac: string;
  iNumEfec: Integer;
  iCobro: Integer;
  fResto: Double;
  fPendiente: Double;
  fAplicar: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (AImporte > 0) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    sEntidad := unqryTablaG.FieldByName('IBAN_REMV').AsString;
    fResto := AImporte;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'SELECT SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV, ' +
        '       COALESCE(IMPORTE_PENDIENTE_EFV, 0) AS PENDIENTE ' +
        '  FROM fza_efectos_venta ' +
        ' WHERE SERIE_REMV_EFV = :serie ' +
        '   AND NUMERO_REMV_EFV = :numero ' +
        '   AND COALESCE(IMPORTE_PENDIENTE_EFV, 0) > 0 ' +
        ' ORDER BY FECHA_VENCIMIENTO_EFV, SERIE_FAC_EFV, ' +
        '          NUMERO_FAC_EFV, NUMERO_EFV';
      q.ParamByName('serie').AsString := sSerieRem;
      q.ParamByName('numero').AsString := sNumeroRem;
      q.Open;
      while (not q.Eof) and (fResto > 0.0001) do
      begin
        sSerieFac := q.FieldByName('SERIE_FAC_EFV').AsString;
        sNumeroFac := q.FieldByName('NUMERO_FAC_EFV').AsString;
        iNumEfec := q.FieldByName('NUMERO_EFV').AsInteger;
        fPendiente := q.FieldByName('PENDIENTE').AsFloat;
        fAplicar := fResto;
        if fAplicar > fPendiente then
          fAplicar := fPendiente;
        iCobro := RegistrarCobroEfectoClave(sSerieFac, sNumeroFac, iNumEfec,
          AFecha, fAplicar, ATipo, AReferencia, sEntidad);
        if iCobro > 0 then
        begin
          Inc(Result);
          fResto := fResto - fAplicar;
        end
        else
          fResto := 0;
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
    if Result > 0 then
      ActualizarEstadoRemesa(sSerieRem, sNumeroRem, AFecha);
  end;
end;

function TdmRemesasVenta.RegistrarCobroRemesa(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := IniciarTransaccionRemesa;
  try
    Result := AplicarCobroRemesa(AFecha, AImporte, ATipo, AReferencia);
    ConfirmarTransaccionRemesa(bTransaccionPropia);
  except
    RevertirTransaccionRemesa(bTransaccionPropia);
    raise;
  end;
  if Result > 0 then
    RefrescarDatos;
end;

function TdmRemesasVenta.AplicarQuitarEfecto: Boolean;
var
  q: TUniQuery;
  ds: TDataSet;
  sSerieRem: string;
  sNumeroRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     unqryEfectosRemesa.Active and (not unqryEfectosRemesa.IsEmpty) and
     (not RemesaTieneCobro) then
  begin
    ds := unqryEfectosRemesa;
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_efectos_venta ' +
        '   SET SERIE_REMV_EFV = NULL, ' +
        '       NUMERO_REMV_EFV = NULL, ' +
        '       ESTADO_EFV = CASE ' +
        '         WHEN COALESCE(IMPORTE_PENDIENTE_EFV, 0) <= 0 ' +
        '           THEN ''COBRADO'' ' +
        '         ELSE ''PENDIENTE'' END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_FAC_EFV = :serie_fac ' +
        '   AND NUMERO_FAC_EFV = :numero_fac ' +
        '   AND NUMERO_EFV = :num_efec ' +
        '   AND SERIE_REMV_EFV = :serie_rem ' +
        '   AND NUMERO_REMV_EFV = :numero_rem';
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie_fac').AsString :=
        ds.FieldByName('SERIE_FAC_EFV').AsString;
      q.ParamByName('numero_fac').AsString :=
        ds.FieldByName('NUMERO_FAC_EFV').AsString;
      q.ParamByName('num_efec').AsInteger :=
        ds.FieldByName('NUMERO_EFV').AsInteger;
      q.ParamByName('serie_rem').AsString := sSerieRem;
      q.ParamByName('numero_rem').AsString := sNumeroRem;
      q.ExecSQL;
      Result := q.RowsAffected > 0;
    finally
      FreeAndNil(q);
    end;
    if Result then
    begin
      RecalcularRemesa(sSerieRem, sNumeroRem);
      ActualizarEstadoRemesa(sSerieRem, sNumeroRem, 0);
    end;
  end;
end;

function TdmRemesasVenta.QuitarEfectoActual: Boolean;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := IniciarTransaccionRemesa;
  try
    Result := AplicarQuitarEfecto;
    ConfirmarTransaccionRemesa(bTransaccionPropia);
  except
    RevertirTransaccionRemesa(bTransaccionPropia);
    raise;
  end;
  if Result then
    RefrescarDatos;
end;

function TdmRemesasVenta.EliminarRemesa: Boolean;
var
  bTxOwned: Boolean;
  q: TUniQuery;
  sSerieRem: string;
  sNumeroRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (not RemesaTieneCobro) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    bTxOwned := not ConexionPrincipal.InTransaction;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      try
        if bTxOwned then
          ConexionPrincipal.StartTransaction;
        // 1. Desvincular los efectos de la remesa y restaurar su estado.
        q.SQL.Text :=
          'UPDATE fza_efectos_venta ' +
          '   SET SERIE_REMV_EFV = NULL, ' +
          '       NUMERO_REMV_EFV = NULL, ' +
          '       ESTADO_EFV = CASE ' +
          '         WHEN COALESCE(IMPORTE_PENDIENTE_EFV, 0) <= 0 ' +
          '           THEN ''COBRADO'' ' +
          '         ELSE ''PENDIENTE'' END, ' +
          '       INSTANTE_MODIF = NOW(), ' +
          '       USUARIO_MODIF = :usuario ' +
          ' WHERE SERIE_REMV_EFV = :serie ' +
          '   AND NUMERO_REMV_EFV = :numero';
        q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
        q.ParamByName('serie').AsString := sSerieRem;
        q.ParamByName('numero').AsString := sNumeroRem;
        q.ExecSQL;
        // 2. Borrar la cabecera contra la tabla base (la vista vi_remesas_venta
        // es de solo lectura por el JOIN, no admite DELETE).
        q.SQL.Text :=
          'DELETE FROM fza_remesas_venta ' +
          ' WHERE SERIE_REMV = :serie ' +
          '   AND NUMERO_REMV = :numero';
        q.ParamByName('serie').AsString := sSerieRem;
        q.ParamByName('numero').AsString := sNumeroRem;
        q.ExecSQL;
        Result := q.RowsAffected > 0;
        if bTxOwned then
          ConexionPrincipal.Commit;
      except
        if bTxOwned and ConexionPrincipal.InTransaction then
          ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
    if Result then
      RefrescarDatos;
  end;
end;

function TdmRemesasVenta.AsignarBancoRemesa(
  const ACodigoEmpban: string): Boolean;
var
  q: TUniQuery;
  sSerieRem: string;
  sNumeroRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     unqryBancosEmpresa.Active and
     unqryBancosEmpresa.Locate('CODIGO_EMPBAN', ACodigoEmpban, []) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_remesas_venta ' +
        '   SET ENTIDAD_REMV = :entidad, ' +
        '       OFICINA_REMV = :oficina, ' +
        '       DIGITO_CONTROL_REMV = :dc, ' +
        '       CUENTA_REMV = :cuenta, ' +
        '       IBAN_REMV = :iban, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV = :serie ' +
        '   AND NUMERO_REMV = :numero';
      q.ParamByName('entidad').AsString :=
        unqryBancosEmpresa.FieldByName('ENTIDAD_EMPBAN').AsString;
      q.ParamByName('oficina').AsString :=
        unqryBancosEmpresa.FieldByName('OFICINA_EMPBAN').AsString;
      q.ParamByName('dc').AsString :=
        unqryBancosEmpresa.FieldByName('DIGITO_CONTROL_EMPBAN').AsString;
      q.ParamByName('cuenta').AsString :=
        unqryBancosEmpresa.FieldByName('CUENTA_EMPBAN').AsString;
      q.ParamByName('iban').AsString :=
        unqryBancosEmpresa.FieldByName('IBAN_EMPBAN').AsString;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString := sSerieRem;
      q.ParamByName('numero').AsString := sNumeroRem;
      q.ExecSQL;
      q.SQL.Text :=
        'UPDATE fza_efectos_venta ' +
        '   SET CODIGO_EMPBAN_EFV = :codigo, ' +
        '       IBAN_EMP_EFV = :iban, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV_EFV = :serie ' +
        '   AND NUMERO_REMV_EFV = :numero';
      q.ParamByName('codigo').AsString := ACodigoEmpban;
      q.ParamByName('iban').AsString :=
        unqryBancosEmpresa.FieldByName('IBAN_EMPBAN').AsString;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString := sSerieRem;
      q.ParamByName('numero').AsString := sNumeroRem;
      q.ExecSQL;
      Result := True;
    finally
      FreeAndNil(q);
    end;
    if Result then
      RefrescarDatos;
  end;
end;

function TdmRemesasVenta.ActualizarFechaCobro(
  AFecha: TDateTime): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and (AFecha > 0) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_remesas_venta ' +
        '   SET FECHA_CARGO_REMV = :fecha, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV = :serie ' +
        '   AND NUMERO_REMV = :numero';
      q.ParamByName('fecha').AsDateTime := AFecha;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString :=
        unqryTablaG.FieldByName('SERIE_REMV').AsString;
      q.ParamByName('numero').AsString :=
        unqryTablaG.FieldByName('NUMERO_REMV').AsString;
      q.ExecSQL;
      Result := q.RowsAffected > 0;
    finally
      FreeAndNil(q);
    end;
    if Result then
      RefrescarDatos;
  end;
end;

procedure TdmRemesasVenta.CargarDatosSepa(var ADatos: TDatosSepaRemesaVenta);
var
  dFechaRemesa: TDateTime;
  i: Integer;
  q: TUniQuery;
  sCodigoCliente: string;
  sNifEmpresa: string;
begin
  ADatos.CodigoAcreedor := '';
  ADatos.TipoSecuencia := 'RCUR';
  SetLength(ADatos.Clientes, 0);
  if not (unqryTablaG.Active and (not unqryTablaG.IsEmpty)) then
    raise Exception.Create(SErrorRemesaVentaNoSeleccionada);
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'SELECT r.FECHA_REMV, r.TIPO_SECUENCIA_SEPA_REMV, emp.NIF_EMP, ' +
      '       eb.CODIGO_ACREEDOR_SEPA_EMPBAN ' +
      '  FROM fza_remesas_venta r ' +
      '  LEFT JOIN fza_empresas emp ' +
      '    ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMV ' +
      '  LEFT JOIN fza_empresas_bancos eb ' +
      '    ON eb.CODIGO_EMP_EMPBAN = r.CODIGO_EMP_REMV ' +
      '   AND eb.IBAN_EMPBAN = r.IBAN_REMV ' +
      ' WHERE r.SERIE_REMV = :serie ' +
      '   AND r.NUMERO_REMV = :numero';
    q.ParamByName('serie').AsString :=
      unqryTablaG.FieldByName('SERIE_REMV').AsString;
    q.ParamByName('numero').AsString :=
      unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    q.Open;
    if q.IsEmpty then
      raise Exception.Create(SErrorRemesaVentaNoEncontrada);
    ADatos.CodigoAcreedor := UpperCase(ValorCampoStrSepa(q,
      'CODIGO_ACREEDOR_SEPA_EMPBAN'));
    sNifEmpresa := ValorCampoStrSepa(q, 'NIF_EMP');
    if ADatos.CodigoAcreedor = '' then
    begin
      try
        ADatos.CodigoAcreedor :=
          CalcularCodigoAcreedorSepaEspanol(sNifEmpresa);
      except
        ADatos.CodigoAcreedor := '';
      end;
    end;
    ADatos.TipoSecuencia := UpperCase(ValorCampoStrSepa(q,
      'TIPO_SECUENCIA_SEPA_REMV'));
    if ADatos.TipoSecuencia = '' then
      ADatos.TipoSecuencia := 'RCUR';
    dFechaRemesa := ValorCampoFechaSepa(q, 'FECHA_REMV', Date);
    q.Close;
    q.SQL.Text :=
      'SELECT e.CODIGO_CLI_EFV, ' +
      '       COALESCE(NULLIF(cli.RAZON_SOCIAL_CLI, ''''), ' +
      '                NULLIF(e.RAZON_SOCIAL_CLI_EFV, ''''), ' +
      '                e.CODIGO_CLI_EFV) AS NOMBRE_CLI, ' +
      '       cli.ID_MANDATO_SEPA_CLI, ' +
      '       cli.FECHA_FIRMA_MANDATO_SEPA_CLI, ' +
      '       MIN(e.FECHA_EMISION_EFV) AS FECHA_SUGERIDA ' +
      '  FROM fza_efectos_venta e ' +
      '  LEFT JOIN fza_clientes cli ' +
      '    ON cli.CODIGO_CLI_CLI = e.CODIGO_CLI_EFV ' +
      ' WHERE e.SERIE_REMV_EFV = :serie ' +
      '   AND e.NUMERO_REMV_EFV = :numero ' +
      '   AND COALESCE(e.IMPORTE_PENDIENTE_EFV, e.IMPORTE_EFV, 0) > 0 ' +
      ' GROUP BY e.CODIGO_CLI_EFV, cli.RAZON_SOCIAL_CLI, ' +
      '          e.RAZON_SOCIAL_CLI_EFV, cli.ID_MANDATO_SEPA_CLI, ' +
      '          cli.FECHA_FIRMA_MANDATO_SEPA_CLI ' +
      ' ORDER BY NOMBRE_CLI';
    q.ParamByName('serie').AsString :=
      unqryTablaG.FieldByName('SERIE_REMV').AsString;
    q.ParamByName('numero').AsString :=
      unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    q.Open;
    if q.IsEmpty then
      raise Exception.Create(SErrorRemesaVentaSinEfectosPendientes);
    i := 0;
    while not q.Eof do
    begin
      SetLength(ADatos.Clientes, i + 1);
      sCodigoCliente := ValorCampoStrSepa(q, 'CODIGO_CLI_EFV');
      ADatos.Clientes[i].CodigoCliente := sCodigoCliente;
      ADatos.Clientes[i].NombreCliente := ValorCampoStrSepa(q, 'NOMBRE_CLI');
      ADatos.Clientes[i].IdMandato := UpperCase(ValorCampoStrSepa(q,
        'ID_MANDATO_SEPA_CLI'));
      if ADatos.Clientes[i].IdMandato = '' then
        ADatos.Clientes[i].IdMandato := 'CLI-' +
          SoloAlfanumericoSepa(sCodigoCliente);
      ADatos.Clientes[i].FechaFirma := ValorCampoFechaSepa(q,
        'FECHA_FIRMA_MANDATO_SEPA_CLI', 0);
      if ADatos.Clientes[i].FechaFirma <= 0 then
        ADatos.Clientes[i].FechaFirma := ValorCampoFechaSepa(q,
          'FECHA_SUGERIDA', dFechaRemesa);
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TdmRemesasVenta.GuardarDatosSepa(
  const ADatos: TDatosSepaRemesaVenta): Boolean;
var
  bTxOwned: Boolean;
  i: Integer;
  q: TUniQuery;
  sIban: string;
  sNumeroRem: string;
  sSerieRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    sIban := unqryTablaG.FieldByName('IBAN_REMV').AsString;
    bTxOwned := not ConexionPrincipal.InTransaction;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      try
        if bTxOwned then
          ConexionPrincipal.StartTransaction;
        q.SQL.Text :=
          'UPDATE fza_empresas_bancos ' +
          '   SET CODIGO_ACREEDOR_SEPA_EMPBAN = :codigo, ' +
          '       INSTANTE_MODIF = NOW(), ' +
          '       USUARIO_MODIF = :usuario ' +
          ' WHERE CODIGO_EMP_EMPBAN = :empresa ' +
          '   AND IBAN_EMPBAN = :iban';
        q.ParamByName('codigo').AsString := ADatos.CodigoAcreedor;
        q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
        q.ParamByName('empresa').AsString :=
          unqryTablaG.FieldByName('CODIGO_EMP_REMV').AsString;
        q.ParamByName('iban').AsString := sIban;
        q.ExecSQL;
        if q.RowsAffected = 0 then
          raise Exception.Create(SErrorGuardarCodigoAcreedorSepa);
        q.SQL.Text :=
          'UPDATE fza_remesas_venta ' +
          '   SET TIPO_SECUENCIA_SEPA_REMV = :tipo, ' +
          '       INSTANTE_MODIF = NOW(), ' +
          '       USUARIO_MODIF = :usuario ' +
          ' WHERE SERIE_REMV = :serie ' +
          '   AND NUMERO_REMV = :numero';
        q.ParamByName('tipo').AsString := ADatos.TipoSecuencia;
        q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
        q.ParamByName('serie').AsString := sSerieRem;
        q.ParamByName('numero').AsString := sNumeroRem;
        q.ExecSQL;
        i := 0;
        while i < Length(ADatos.Clientes) do
        begin
          q.SQL.Text :=
            'UPDATE fza_clientes ' +
            '   SET ID_MANDATO_SEPA_CLI = :mandato, ' +
            '       FECHA_FIRMA_MANDATO_SEPA_CLI = :fecha, ' +
            '       INSTANTE_MODIF = NOW(), ' +
            '       USUARIO_MODIF = :usuario ' +
            ' WHERE CODIGO_CLI_CLI = :cliente';
          q.ParamByName('mandato').AsString := ADatos.Clientes[i].IdMandato;
          q.ParamByName('fecha').AsDateTime := ADatos.Clientes[i].FechaFirma;
          q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
          q.ParamByName('cliente').AsString :=
            ADatos.Clientes[i].CodigoCliente;
          q.ExecSQL;
          if q.RowsAffected = 0 then
            raise Exception.Create(Format(SErrorGuardarMandatoSepaCliente,
              [ADatos.Clientes[i].CodigoCliente]));
          Inc(i);
        end;
        if bTxOwned then
          ConexionPrincipal.Commit;
        Result := True;
      except
        if bTxOwned and ConexionPrincipal.InTransaction then
          ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmRemesasVenta.GenerarOrdenSepa(const AArchivo: string): Integer;
var
  q: TUniQuery;
  rSepa: TResultadoSepaRemesaVenta;
  sNumeroRem: string;
  sSerieRem: string;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMV').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMV').AsString;
    rSepa := GenerarSepaRemesaVenta(
      CrearSepaRemesasVentaLecturas(ConexionPrincipal).
        CargarRemesaValidada(sSerieRem, sNumeroRem),
      AArchivo);
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_remesas_venta ' +
        '   SET ARCHIVO_REMV = :archivo, ' +
        '       NORMA_REMV = ''19.14'', ' +
        '       ESTADO_REMV = CASE ' +
        '         WHEN COALESCE(ESTADO_REMV, '''') IN ' +
        '              (''ABIERTA'', ''CERRADA'') THEN ''ENVIADA'' ' +
        '         ELSE ESTADO_REMV END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMV = :serie ' +
        '   AND NUMERO_REMV = :numero';
      q.ParamByName('archivo').AsString := rSepa.Archivo;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString := sSerieRem;
      q.ParamByName('numero').AsString := sNumeroRem;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
    Result := rSepa.NumCobros;
    RefrescarDatos;
  end;
end;

initialization
  RegistrarDataModule(TdmRemesasVenta);
  ForceReferenceToClass(TdmRemesasVenta);
end.



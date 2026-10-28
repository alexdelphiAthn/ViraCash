{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRemesasCompra                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de remesas de pago (vi_remesas_compra).                      }
{******************************************************************************}
unit UniDataRemesasCompra;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser, UniDataConn, inLibSepaRemesasCompra;

type
  TdmRemesasCompra = class(TdmBase)
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
    function AplicarPagoEfectoActual(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function AplicarPagoRemesa(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    procedure ActualizarEstadoRemesa(const ASerie, ANumero: string;
      AFechaCargo: TDateTime);
    function RegistrarPagoEfectoClave(const ASerieFac, ANumeroFac: string;
      ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia, AEntidad: string): Integer;
    procedure RecalcularRemesa(const ASerie, ANumero: string);
    procedure RegistrarFicheroSepa(const ARemesa: TRemesaSepaCompraValidada;
      const ASerie, ANumero, AArchivo: string);
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure RefrescarDatos;
    function ActualizarFechaCargo(AFecha: TDateTime): Boolean;
    function AsignarBancoRemesa(const ACodigoEmpban: string): Boolean;
    function CargoRealizadoRemesa: Double;
    function EliminarRemesa: Boolean;
    function PendienteRemesa: Double;
    function QuitarEfectoActual: Boolean;
    function RegistrarPagoEfectoActual(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function RegistrarPagoRemesa(AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function RemesaTieneCargo: Boolean;
    // Fichero de transferencias SEPA (pain.001).
    function GenerarOrdenSepa(const ARemesa: TRemesaSepaCompraValidada;
      const AArchivo: string): TResultadoSepaRemesaCompra;
    function LeerFicheroSepa: TFicheroSepaRemesaCompra;
    function PrepararRemesaSepa(
      AFormato: TFormatoSepaTransferencia): TRemesaSepaCompraValidada;
    function ReabrirRemesa: Boolean;
    function RemesaGenerada: Boolean;
  end;

implementation

uses
  inLibMsgCompras, UniDataSepaRemesasCompraRepositorio;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmRemesasCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection := ConexionPrincipal;
  unqryEfectosRemesa.Connection := ConexionPrincipal;
  unqryBancosEmpresa.Connection := ConexionPrincipal;
end;

procedure TdmRemesasCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryEfectosRemesa.MasterSource := ADataSource;
  unqryBancosEmpresa.MasterSource := ADataSource;
end;

procedure TdmRemesasCompra.AbrirDetalles;
begin
  inherited;
  if not unqryBancosEmpresa.Active then
    unqryBancosEmpresa.Open;
  if not unqryEfectosRemesa.Active then
    unqryEfectosRemesa.Open;
end;

procedure TdmRemesasCompra.RefrescarDatos;
var
  bLocalizar: Boolean;
  sSerie: string;
  sNumero: string;
begin
  bLocalizar := unqryTablaG.Active and (not unqryTablaG.IsEmpty);
  if bLocalizar then
  begin
    sSerie := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
  end;
  if unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
    if bLocalizar then
      unqryTablaG.Locate('SERIE_REMC;NUMERO_REMC',
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

function TdmRemesasCompra.PendienteRemesa: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.FindField('TOTAL_PENDIENTE_REMC') <> nil) then
    Result := unqryTablaG.FieldByName('TOTAL_PENDIENTE_REMC').AsFloat;
end;

function TdmRemesasCompra.CargoRealizadoRemesa: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.FindField('TOTAL_CARGADO_REMC') <> nil) then
    Result := unqryTablaG.FieldByName('TOTAL_CARGADO_REMC').AsFloat;
end;

function TdmRemesasCompra.RemesaTieneCargo: Boolean;
begin
  Result := CargoRealizadoRemesa > 0.0001;
end;

function TdmRemesasCompra.RemesaGenerada: Boolean;
begin
  Result := unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
    SameText(Trim(unqryTablaG.FieldByName('ESTADO_REMC').AsString),
      CEstadoRemesaCompraGenerada);
end;

// Cada operación sobre la remesa (cobrar o pagar uno o todos sus efectos,
// quitar un efecto) se confirma entera o nada: los procedimientos de
// conciliación respetan esta transacción desde FZ-ISSUE-143 (FZ-ISSUE-152).
function TdmRemesasCompra.IniciarTransaccionRemesa: Boolean;
begin
  Result := not ConexionPrincipal.InTransaction;
  if Result then
    ConexionPrincipal.StartTransaction;
end;

procedure TdmRemesasCompra.ConfirmarTransaccionRemesa(
  ATransaccionPropia: Boolean);
begin
  if ATransaccionPropia then
    ConexionPrincipal.Commit;
end;

procedure TdmRemesasCompra.RevertirTransaccionRemesa(
  ATransaccionPropia: Boolean);
begin
  if ATransaccionPropia and ConexionPrincipal.InTransaction then
    ConexionPrincipal.Rollback;
end;

procedure TdmRemesasCompra.RecalcularRemesa(const ASerie, ANumero: string);
var
  sp: TUniStoredProc;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection := ConexionPrincipal;
    sp.StoredProcName := 'PRC_REMC_RECALCULAR';
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

procedure TdmRemesasCompra.ActualizarEstadoRemesa(const ASerie,
  ANumero: string; AFechaCargo: TDateTime);
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
      'SELECT COUNT(e.NUMERO_EFEC) AS EFECTOS, ' +
      '       COALESCE(r.TOTAL_REMC, 0) AS TOTAL, ' +
      '       COALESCE(SUM(COALESCE(e.IMPORTE_PENDIENTE_EFEC, 0)), 0) ' +
      '         AS PENDIENTE ' +
      '  FROM fza_remesas_compra r ' +
      '  LEFT JOIN fza_efectos_compra e ' +
      '    ON e.SERIE_REMC_EFEC = r.SERIE_REMC ' +
      '   AND e.NUMERO_REMC_EFEC = r.NUMERO_REMC ' +
      ' WHERE r.SERIE_REMC = :serie ' +
      '   AND r.NUMERO_REMC = :numero ' +
      ' GROUP BY r.TOTAL_REMC';
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
        sEstado := 'PAGADA'
      else if fCargado > 0.0001 then
        sEstado := 'PARCIAL';
    end;
    q.Close;
    // Sin pagos, una remesa con fichero SEPA sigue GENERADA (no ABIERTA).
    if AFechaCargo > 0 then
    begin
      q.SQL.Text :=
        'UPDATE fza_remesas_compra ' +
        '   SET ESTADO_REMC = CASE ' +
        '         WHEN :estado = ''ABIERTA'' ' +
        '          AND ESTADO_REMC = ''GENERADA'' THEN ''GENERADA'' ' +
        '         ELSE :estado END, ' +
        '       FECHA_CARGO_REMC = :fecha, ' +
        '       INSTANTE_CONTABILIZACION_REMC = ' +
        '         CASE WHEN :estado = ''PAGADA'' THEN NOW() ' +
        '              ELSE INSTANTE_CONTABILIZACION_REMC END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC = :serie ' +
        '   AND NUMERO_REMC = :numero';
      q.ParamByName('fecha').AsDateTime := AFechaCargo;
    end
    else
      q.SQL.Text :=
        'UPDATE fza_remesas_compra ' +
        '   SET ESTADO_REMC = CASE ' +
        '         WHEN :estado = ''ABIERTA'' ' +
        '          AND ESTADO_REMC = ''GENERADA'' THEN ''GENERADA'' ' +
        '         ELSE :estado END, ' +
        '       INSTANTE_CONTABILIZACION_REMC = ' +
        '         CASE WHEN :estado = ''PAGADA'' THEN NOW() ' +
        '              ELSE INSTANTE_CONTABILIZACION_REMC END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC = :serie ' +
        '   AND NUMERO_REMC = :numero';
    q.ParamByName('estado').AsString := sEstado;
    q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
    q.ParamByName('serie').AsString := ASerie;
    q.ParamByName('numero').AsString := ANumero;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

function TdmRemesasCompra.RegistrarPagoEfectoClave(const ASerieFac,
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
      sp.StoredProcName := 'PRC_EFEC_CONCILIAR_PAGO';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString, 'p_SERIE', ptInput);
      sp.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      sp.Params.CreateParam(ftInteger, 'p_NUM_EFEC', ptInput);
      sp.Params.CreateParam(ftDate, 'p_FECHA', ptInput);
      sp.Params.CreateParam(ftFloat, 'p_IMPORTE', ptInput);
      sp.Params.CreateParam(ftString, 'p_TIPO', ptInput);
      sp.Params.CreateParam(ftString, 'p_REFERENCIA', ptInput);
      sp.Params.CreateParam(ftString, 'p_ENTIDAD', ptInput);
      sp.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
      sp.ParamByName('p_SERIE').AsString := ASerieFac;
      sp.ParamByName('p_NUMERO').AsString := ANumeroFac;
      sp.ParamByName('p_NUM_EFEC').AsInteger := ANumEfec;
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

function TdmRemesasCompra.AplicarPagoEfectoActual(AFecha: TDateTime;
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
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
    sEntidad := unqryTablaG.FieldByName('IBAN_REMC').AsString;
    Result := RegistrarPagoEfectoClave(
      ds.FieldByName('SERIE_FACC_EFEC').AsString,
      ds.FieldByName('NUMERO_FACC_EFEC').AsString,
      ds.FieldByName('NUMERO_EFEC').AsInteger,
      AFecha, AImporte, ATipo, AReferencia, sEntidad);
    if Result > 0 then
      ActualizarEstadoRemesa(sSerieRem, sNumeroRem, AFecha);
  end;
end;

function TdmRemesasCompra.RegistrarPagoEfectoActual(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := IniciarTransaccionRemesa;
  try
    Result := AplicarPagoEfectoActual(AFecha, AImporte, ATipo, AReferencia);
    ConfirmarTransaccionRemesa(bTransaccionPropia);
  except
    RevertirTransaccionRemesa(bTransaccionPropia);
    raise;
  end;
  if Result > 0 then
    RefrescarDatos;
end;

function TdmRemesasCompra.AplicarPagoRemesa(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  q: TUniQuery;
  sSerieRem: string;
  sNumeroRem: string;
  sEntidad: string;
  sSerieFac: string;
  sNumeroFac: string;
  iNumEfec: Integer;
  iPago: Integer;
  fResto: Double;
  fPendiente: Double;
  fAplicar: Double;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (AImporte > 0) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
    sEntidad := unqryTablaG.FieldByName('IBAN_REMC').AsString;
    fResto := AImporte;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'SELECT SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC, ' +
        '       COALESCE(IMPORTE_PENDIENTE_EFEC, 0) AS PENDIENTE ' +
        '  FROM fza_efectos_compra ' +
        ' WHERE SERIE_REMC_EFEC = :serie ' +
        '   AND NUMERO_REMC_EFEC = :numero ' +
        '   AND COALESCE(IMPORTE_PENDIENTE_EFEC, 0) > 0 ' +
        ' ORDER BY FECHA_VENCIMIENTO_EFEC, SERIE_FACC_EFEC, ' +
        '          NUMERO_FACC_EFEC, NUMERO_EFEC';
      q.ParamByName('serie').AsString := sSerieRem;
      q.ParamByName('numero').AsString := sNumeroRem;
      q.Open;
      while (not q.Eof) and (fResto > 0.0001) do
      begin
        sSerieFac := q.FieldByName('SERIE_FACC_EFEC').AsString;
        sNumeroFac := q.FieldByName('NUMERO_FACC_EFEC').AsString;
        iNumEfec := q.FieldByName('NUMERO_EFEC').AsInteger;
        fPendiente := q.FieldByName('PENDIENTE').AsFloat;
        fAplicar := fResto;
        if fAplicar > fPendiente then
          fAplicar := fPendiente;
        iPago := RegistrarPagoEfectoClave(sSerieFac, sNumeroFac, iNumEfec,
          AFecha, fAplicar, ATipo, AReferencia, sEntidad);
        if iPago > 0 then
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

function TdmRemesasCompra.RegistrarPagoRemesa(AFecha: TDateTime;
  AImporte: Double; const ATipo, AReferencia: string): Integer;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := IniciarTransaccionRemesa;
  try
    Result := AplicarPagoRemesa(AFecha, AImporte, ATipo, AReferencia);
    ConfirmarTransaccionRemesa(bTransaccionPropia);
  except
    RevertirTransaccionRemesa(bTransaccionPropia);
    raise;
  end;
  if Result > 0 then
    RefrescarDatos;
end;

function TdmRemesasCompra.AplicarQuitarEfecto: Boolean;
var
  q: TUniQuery;
  ds: TDataSet;
  sSerieRem: string;
  sNumeroRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     unqryEfectosRemesa.Active and (not unqryEfectosRemesa.IsEmpty) and
     (not RemesaTieneCargo) then
  begin
    ds := unqryEfectosRemesa;
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_efectos_compra ' +
        '   SET SERIE_REMC_EFEC = NULL, ' +
        '       NUMERO_REMC_EFEC = NULL, ' +
        '       ESTADO_EFEC = CASE ' +
        '         WHEN COALESCE(IMPORTE_PENDIENTE_EFEC, 0) <= 0 ' +
        '           THEN ''PAGADO'' ' +
        '         ELSE ''PENDIENTE'' END, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_FACC_EFEC = :serie_fac ' +
        '   AND NUMERO_FACC_EFEC = :numero_fac ' +
        '   AND NUMERO_EFEC = :num_efec ' +
        '   AND SERIE_REMC_EFEC = :serie_rem ' +
        '   AND NUMERO_REMC_EFEC = :numero_rem';
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie_fac').AsString :=
        ds.FieldByName('SERIE_FACC_EFEC').AsString;
      q.ParamByName('numero_fac').AsString :=
        ds.FieldByName('NUMERO_FACC_EFEC').AsString;
      q.ParamByName('num_efec').AsInteger :=
        ds.FieldByName('NUMERO_EFEC').AsInteger;
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

function TdmRemesasCompra.QuitarEfectoActual: Boolean;
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

function TdmRemesasCompra.EliminarRemesa: Boolean;
var
  bTxOwned: Boolean;
  q: TUniQuery;
  sSerieRem: string;
  sNumeroRem: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (not RemesaTieneCargo) then
  begin
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
    bTxOwned := not ConexionPrincipal.InTransaction;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      try
        if bTxOwned then
          ConexionPrincipal.StartTransaction;
        // 1. Desvincular los efectos de la remesa y restaurar su estado.
        q.SQL.Text :=
          'UPDATE fza_efectos_compra ' +
          '   SET SERIE_REMC_EFEC = NULL, ' +
          '       NUMERO_REMC_EFEC = NULL, ' +
          '       ESTADO_EFEC = CASE ' +
          '         WHEN COALESCE(IMPORTE_PENDIENTE_EFEC, 0) <= 0 ' +
          '           THEN ''PAGADO'' ' +
          '         ELSE ''PENDIENTE'' END, ' +
          '       INSTANTE_MODIF = NOW(), ' +
          '       USUARIO_MODIF = :usuario ' +
          ' WHERE SERIE_REMC_EFEC = :serie ' +
          '   AND NUMERO_REMC_EFEC = :numero';
        q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
        q.ParamByName('serie').AsString := sSerieRem;
        q.ParamByName('numero').AsString := sNumeroRem;
        q.ExecSQL;
        // 2. Borrar la cabecera contra la tabla base (la vista
        // vi_remesas_compra es de solo lectura por el JOIN, no admite DELETE).
        q.SQL.Text :=
          'DELETE FROM fza_remesas_compra ' +
          ' WHERE SERIE_REMC = :serie ' +
          '   AND NUMERO_REMC = :numero';
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

function TdmRemesasCompra.AsignarBancoRemesa(
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
    sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
    sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_remesas_compra ' +
        '   SET ENTIDAD_REMC = :entidad, ' +
        '       OFICINA_REMC = :oficina, ' +
        '       DIGITO_CONTROL_REMC = :dc, ' +
        '       CUENTA_REMC = :cuenta, ' +
        '       IBAN_REMC = :iban, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC = :serie ' +
        '   AND NUMERO_REMC = :numero';
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
        'UPDATE fza_efectos_compra ' +
        '   SET CODIGO_EMPBAN_EFEC = :codigo, ' +
        '       IBAN_EMP_EFEC = :iban, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC_EFEC = :serie ' +
        '   AND NUMERO_REMC_EFEC = :numero';
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

function TdmRemesasCompra.ActualizarFechaCargo(
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
        'UPDATE fza_remesas_compra ' +
        '   SET FECHA_CARGO_REMC = :fecha, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC = :serie ' +
        '   AND NUMERO_REMC = :numero';
      q.ParamByName('fecha').AsDateTime := AFecha;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString :=
        unqryTablaG.FieldByName('SERIE_REMC').AsString;
      q.ParamByName('numero').AsString :=
        unqryTablaG.FieldByName('NUMERO_REMC').AsString;
      q.ExecSQL;
      Result := q.RowsAffected > 0;
    finally
      FreeAndNil(q);
    end;
    if Result then
      RefrescarDatos;
  end;
end;

function TdmRemesasCompra.LeerFicheroSepa: TFicheroSepaRemesaCompra;
begin
  Result := Default(TFicheroSepaRemesaCompra);
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    Result := CrearSepaRemesasCompraLecturas(ConexionPrincipal).
      LeerFicheroGenerado(
        unqryTablaG.FieldByName('SERIE_REMC').AsString,
        unqryTablaG.FieldByName('NUMERO_REMC').AsString);
end;

// Lee y valida la remesa sin escribir nada: la UI puede mostrar avisos
// y el usuario cancelar sin que quede rastro en la base.
function TdmRemesasCompra.PrepararRemesaSepa(
  AFormato: TFormatoSepaTransferencia): TRemesaSepaCompraValidada;
begin
  if not (unqryTablaG.Active and (not unqryTablaG.IsEmpty)) then
    raise Exception.Create(SErrorRemesaCompraNoSeleccionada);
  Result := CrearSepaRemesasCompraLecturas(ConexionPrincipal).
    CargarRemesaValidada(
      unqryTablaG.FieldByName('SERIE_REMC').AsString,
      unqryTablaG.FieldByName('NUMERO_REMC').AsString,
      AFormato, Now);
  ValidarRemesaSepaCompra(Result, Date);
end;

procedure TdmRemesasCompra.RegistrarFicheroSepa(
  const ARemesa: TRemesaSepaCompraValidada;
  const ASerie, ANumero, AArchivo: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    // El MsgId solo se fija si la remesa no tenía otro: protege de dos
    // sesiones generando a la vez.
    q.SQL.Text :=
      'UPDATE fza_remesas_compra ' +
      '   SET ID_MENSAJE_SEPA_REMC = :idmensaje, ' +
      '       FORMATO_SEPA_REMC = :formato, ' +
      '       INSTANTE_FICHERO_SEPA_REMC = :instante, ' +
      '       ARCHIVO_REMC = :archivo, ' +
      '       NORMA_REMC = :norma, ' +
      '       ESTADO_REMC = CASE ' +
      '         WHEN COALESCE(ESTADO_REMC, '''') IN ' +
      '              ('''', ''ABIERTA'', ''CERRADA'') THEN ''GENERADA'' ' +
      '         ELSE ESTADO_REMC END, ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_REMC = :serie ' +
      '   AND NUMERO_REMC = :numero ' +
      '   AND (ID_MENSAJE_SEPA_REMC IS NULL ' +
      '        OR ID_MENSAJE_SEPA_REMC = '''' ' +
      '        OR ID_MENSAJE_SEPA_REMC = :idmensaje)';
    q.ParamByName('idmensaje').AsString := ARemesa.IdMensaje;
    q.ParamByName('formato').AsString :=
      NombreFormatoSepaTransferencia(ARemesa.Formato);
    q.ParamByName('instante').AsDateTime := ARemesa.Instante;
    q.ParamByName('archivo').AsString := Copy(AArchivo, 1, 200);
    q.ParamByName('norma').AsString := CNormaSepaTransferencias;
    q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
    q.ParamByName('serie').AsString := ASerie;
    q.ParamByName('numero').AsString := ANumero;
    q.ExecSQL;
    if q.RowsAffected = 0 then
      raise Exception.Create(SErrorRemesaCompraSepaConcurrente);
  finally
    FreeAndNil(q);
  end;
end;

// Escribe el fichero y después lo anota en la remesa; si la anotación
// falla, borra el fichero para que no quede uno sin MsgId registrado.
function TdmRemesasCompra.GenerarOrdenSepa(
  const ARemesa: TRemesaSepaCompraValidada;
  const AArchivo: string): TResultadoSepaRemesaCompra;
var
  sNumeroRem: string;
  sSerieRem: string;
begin
  if not (unqryTablaG.Active and (not unqryTablaG.IsEmpty)) then
    raise Exception.Create(SErrorRemesaCompraNoSeleccionada);
  sSerieRem := unqryTablaG.FieldByName('SERIE_REMC').AsString;
  sNumeroRem := unqryTablaG.FieldByName('NUMERO_REMC').AsString;
  Result := GenerarSepaRemesaCompra(ARemesa, AArchivo);
  try
    RegistrarFicheroSepa(ARemesa, sSerieRem, sNumeroRem, Result.Archivo);
  except
    System.SysUtils.DeleteFile(Result.Archivo);
    raise;
  end;
  RefrescarDatos;
end;

function TdmRemesasCompra.ReabrirRemesa: Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if RemesaGenerada and (not RemesaTieneCargo) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      // FORMATO_SEPA_REMC se conserva como propuesta del siguiente fichero.
      q.SQL.Text :=
        'UPDATE fza_remesas_compra ' +
        '   SET ESTADO_REMC = ''ABIERTA'', ' +
        '       ID_MENSAJE_SEPA_REMC = NULL, ' +
        '       INSTANTE_FICHERO_SEPA_REMC = NULL, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_REMC = :serie ' +
        '   AND NUMERO_REMC = :numero ' +
        '   AND ESTADO_REMC = ''GENERADA''';
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString :=
        unqryTablaG.FieldByName('SERIE_REMC').AsString;
      q.ParamByName('numero').AsString :=
        unqryTablaG.FieldByName('NUMERO_REMC').AsString;
      q.ExecSQL;
      Result := q.RowsAffected > 0;
    finally
      FreeAndNil(q);
    end;
    if Result then
      RefrescarDatos;
  end;
end;

initialization
  RegistrarDataModule(TdmRemesasCompra);
  ForceReferenceToClass(TdmRemesasCompra);
end.

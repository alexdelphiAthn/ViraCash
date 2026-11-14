{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataClientes                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de clientes.                                                  }
{    Queries de fza_clientes, formas de pago, tarifas, depósitos y facturación }
{    asociada.                                                                 }
{******************************************************************************}
unit UniDataClientes;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn, inLibWin, Forms, Windows,
  Datasnap.DBClient, Datasnap.Provider, frxClass, frxDBSet, frCoreClasses;

type
  TdmClientes = class(TdmBase)
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
    unqryVendedores: TUniQuery;
    dsVendedores: TDataSource;
    dsEmpresasBancos: TDataSource;
    unqryEmpresasBancos: TUniQuery;
    dsTarifas: TDataSource;
    unqryTarifas: TUniQuery;
    dsFacturasClientes: TDataSource;
    unqryFacturasClientes: TUniQuery;
    dsFacturasLineasClientes: TDataSource;
    unqryFacturasLineasClientes: TUniQuery;
    cdsEtiquetas: TClientDataSet;
    dtstprvEtiquetas: TDataSetProvider;
    unqryCliPrint: TUniQuery;
    dsEtiquetas: TDataSource;
    fxdsEtiquetas: TfrxDBDataset;
    dsPaises: TDataSource;
    unqryPaises: TUniQuery;
    dsDepositos: TDataSource;
    unqryDepositos: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
  private
    procedure GuardarParametrosEDocCliente(ADataSet: TDataSet);
    procedure GuardarClienteVarios(ADataSet: TDataSet);
  public
    procedure GetCodigoAutoCliente;
    procedure CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                    sCodCli:String);
    // Override: abre los lookups (Paises, FormaPago, Tarifas). Las
    // queries de detail (FacturasClientes, FacturasLineasClientes,
    // Depositos) son lazy: se abren al activar su sub-pestaña.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure AsegurarHistoriaFacturacionAbierta;
    procedure AsegurarDepositosAbierta;
  end;

//var
//  dmClientes2: TdmClientes;

implementation

uses
  inLibClientesAltaRapida,
  UniDataValoresAutomaticosRepositorio,
  UniDataVendedoresRepositorio,

  System.Diagnostics,
  System.Variants,
  UniDataAperturaConsultas,
  inLibMsgComun, inLibMsgFacturas,
  inLibMsgVentas, inLibErroresBBDD;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmClientes.CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                            sCodCli:String);
var
  i:Integer;
begin
  unqryCliPrint.Connection := ConexionPrincipal;
  unqryCliPrint.SQL.Text := ' SELECT * ' +
                            ' from vi_clientes ' +
                            ' where CODIGO_CLI_CLI = :CODIGO';
  unqryCliPrint.ParamByName('CODIGO').AsString := sCodCli;
  unqryCliPrint.Open;
  cdsEtiquetas.Data := dtstprvEtiquetas.Data;
  cdsEtiquetas.ReadOnly := False;
  cdsEtiquetas.Active := True;
  cdsEtiquetas.First;
  cdsEtiquetas.DisableControls;
  cdsEtiquetas.DisableConstraints;
  fxdsEtiquetas.UpdateBounds;
  //cdsEtiquetas.IndexDefs.Clear;
  for i := 0 to (cdsEtiquetas.Fieldcount-1) do
  begin
    cdsEtiquetas.fields[i].ReadOnly := false;
    cdsEtiquetas.Fields[i].Required := false;
    cdsEtiquetas.FieldDefs[i].Attributes := [];
  end;
  for i := 1 to iNroEspaciosBlanco do
  begin
    cdsEtiquetas.Insert;
    cdsEtiquetas.FieldByName('CODIGO_CLI_CLI').AsString := '0';
    cdsEtiquetas.FieldByName('RAZON_SOCIAL_CLI').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTE_MODIF').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTE_ALTA').AsString := '';
    cdsEtiquetas.FieldByName('USUARIO_MODIF').AsString := '';
    cdsEtiquetas.FieldByName('USUARIO_ALTA').AsString := '';
    cdsEtiquetas.Post;
  end;
end;

procedure TdmClientes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo asignaciones de Connection y MasterSource. Los .Open se han
  // movido a AbrirDetalles (callback main thread con overlay visible)
  // para no congelar la UI durante la creacion del data module.
  unqryFormaPago.Connection := ConexionPrincipal;
  unqryVendedores := CrearConsultaVendedores(Self, ConexionPrincipal);
  dsVendedores := TDataSource.Create(Self);
  dsVendedores.DataSet := unqryVendedores;
  unqryEmpresasBancos.Connection := ConexionPrincipal;
  unqryPerfiles.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unqryFacturasClientes.Connection := ConexionPrincipal;
  unqryFacturasLineasClientes.Connection := ConexionPrincipal;
  unqryPaises.Connection := ConexionPrincipal;
end;

procedure TdmClientes.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryFacturasClientes.MasterSource := ADataSource;
  unqryFacturasLineasClientes.MasterSource := ADataSource;
  unqryDepositos.MasterSource := ADataSource;
end;

procedure TdmClientes.AbrirDetalles;
const
  TAG = 'Clientes.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Solo lookups. Historia (FacturasClientes+Lineas) y Depositos son
  // lazy: se abren al activar la pestaña Historia/Prestamos.
  AbrirConsultaConTiempo(
    unqryPaises, TAG, 'unqryPaises', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormaPago, TAG, 'unqryFormaPago', RegistroLog);
  AbrirConsultaConTiempo(
    unqryVendedores, TAG, 'unqryVendedores', RegistroLog);
  AbrirConsultaConTiempo(
    unqryEmpresasBancos, TAG, 'unqryEmpresasBancos', RegistroLog);
  AbrirConsultaConTiempo(
    unqryTarifas, TAG, 'unqryTarifas', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmClientes.AsegurarHistoriaFacturacionAbierta;
var swQ: TStopwatch;
begin
  if not (unqryFacturasClientes.Active and
          unqryFacturasLineasClientes.Active) then
  begin
  swQ := TStopwatch.StartNew;
  try
    if not unqryFacturasClientes.Active then
      unqryFacturasClientes.Open;
    if not unqryFacturasLineasClientes.Active then
      unqryFacturasLineasClientes.Open;
    RegistroLog.RegistrarRendimiento('Clientes.Lazy',
      'unqryFacturasClientes+Lineas OK', swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Clientes.Lazy',
        'unqryFacturasClientes+Lineas ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmClientes.AsegurarDepositosAbierta;
var swQ: TStopwatch;
begin
  if not unqryDepositos.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryDepositos.Open;
    RegistroLog.RegistrarRendimiento('Clientes.Lazy', 'unqryDepositos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Clientes.Lazy',
        'unqryDepositos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmClientes.DataModuleDestroy(Sender: TObject);
begin
  inherited;
  //unqryTiposIVA.Close;
  unqryPerfiles.Close;
  unqryFormaPago.Close;
  if Assigned(unqryVendedores) and unqryVendedores.Active then
    unqryVendedores.Close;
  unqryTarifas.Close;
  unqryFacturasClientes.Close;
  unqryFacturasLineasClientes.Close;
  unqryPaises.Close;
  unqryDepositos.Close;
end;

procedure TdmClientes.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLI_CLI').AsString = '0') then
  begin
    unqryTablaG.FindField('CODIGO_CLI_CLI').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'CL',
                                                   IdentidadSesion.Usuario);
  end;
  if (unqryTablaG.FindField('ORDEN_CLI').AsString = '0') then
  begin
    unqryTablaG.FindField('ORDEN_CLI').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'CO',
                                                   IdentidadSesion.Usuario);
  end;
end;

procedure TdmClientes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(ConexionPrincipal, unqryTablaG, 'fza_clientes');
  if DataSet.FindField('ESVARIOS_CLI') <> nil then
    DataSet.FieldByName('ESVARIOS_CLI').AsString := 'N';
  unqryTablaG.FindField('CODIGO_FP_CLI').AsString :=
                                            ObtenerValorPorDefecto(
                                              ConexionPrincipal,
                                              'fza_formas_pago',
                                                            'CODIGO_FP_FP',
                                                     'ESDEFAULT_FORMA_PAGO_FP');
  unqryTablaG.FindField('TARIFA_ARTICULO_CLI').AsString :=
    ParametrosCaja.TarifaDefecto;
end;

// Copia un campo de texto al parámetro conservando NULL: el UPDATE se
// repite en cada grabación y no debe convertir en '' campos no rellenados.
procedure AsignarTextoONulo(AParametro: TParam; ACampo: TField);
begin
  AParametro.DataType := ftString;
  if ACampo.IsNull then
    AParametro.Clear
  else
    AParametro.AsString := ACampo.AsString;
end;

procedure TdmClientes.GuardarParametrosEDocCliente(ADataSet: TDataSet);
var
  Qry: TUniQuery;
  bCamposDir3Disponibles: Boolean;
  bCamposPersonaDisponibles: Boolean;
  sCliente: string;
begin
  sCliente := Trim(ADataSet.FieldByName('CODIGO_CLI_CLI').AsString);
  bCamposDir3Disponibles :=
    (ADataSet.FindField('CODIGO_OFICINA_CONTABLE_CLI') <> nil) and
    (ADataSet.FindField('CODIGO_ORGANO_GESTOR_CLI') <> nil) and
    (ADataSet.FindField('CODIGO_UNIDAD_TRAMITADORA_CLI') <> nil);
  bCamposPersonaDisponibles :=
    (ADataSet.FindField('NOMBRE_PERSONA_CLIENTE_CLI') <> nil) and
    (ADataSet.FindField('APELLIDOS_PERSONA_CLIENTE_CLI') <> nil);
  if (bCamposDir3Disponibles or bCamposPersonaDisponibles) and
     (sCliente <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      // Misma conexión que la tabla: se ejecuta en AfterPost, con la fila
      // aún bloqueada por su transacción; otra conexión esperaría al
      // bloqueo hasta agotar el tiempo (error 1205).
      Qry.Connection := unqryTablaG.Connection;
      if bCamposDir3Disponibles then
      begin
        Qry.SQL.Text :=
          ' UPDATE fza_clientes ' +
          ' SET CODIGO_OFICINA_CONTABLE_CLI = :OFICINA, ' +
          '     CODIGO_ORGANO_GESTOR_CLI = :ORGANO, ' +
          '     CODIGO_UNIDAD_TRAMITADORA_CLI = :UNIDAD ' +
          ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
        AsignarTextoONulo(Qry.ParamByName('OFICINA'),
          ADataSet.FieldByName('CODIGO_OFICINA_CONTABLE_CLI'));
        AsignarTextoONulo(Qry.ParamByName('ORGANO'),
          ADataSet.FieldByName('CODIGO_ORGANO_GESTOR_CLI'));
        AsignarTextoONulo(Qry.ParamByName('UNIDAD'),
          ADataSet.FieldByName('CODIGO_UNIDAD_TRAMITADORA_CLI'));
        Qry.ParamByName('CLIENTE').AsString := sCliente;
        Qry.ExecSQL;
      end;
      if bCamposPersonaDisponibles then
      begin
        Qry.SQL.Text :=
          ' UPDATE fza_clientes ' +
          ' SET NOMBRE_PERSONA_CLIENTE_CLI = :NOMBRE_PERSONA, ' +
          '     APELLIDOS_PERSONA_CLIENTE_CLI = :APELLIDOS_PERSONA ' +
          ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
        AsignarTextoONulo(Qry.ParamByName('NOMBRE_PERSONA'),
          ADataSet.FieldByName('NOMBRE_PERSONA_CLIENTE_CLI'));
        AsignarTextoONulo(Qry.ParamByName('APELLIDOS_PERSONA'),
          ADataSet.FieldByName('APELLIDOS_PERSONA_CLIENTE_CLI'));
        Qry.ParamByName('CLIENTE').AsString := sCliente;
        Qry.ExecSQL;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmClientes.GuardarClienteVarios(ADataSet: TDataSet);
var
  Qry: TUniQuery;
  sCliente: string;
  sEsVarios: string;
begin
  // ESVARIOS_CLI no está en el SQL de actualización del dataset: como los
  // campos eDoc, solo se graba si la BBDD ya tiene la columna
  // (20260924_apartados_cliente_varios.sql).
  sCliente := Trim(ADataSet.FieldByName('CODIGO_CLI_CLI').AsString);
  if (ADataSet.FindField('ESVARIOS_CLI') <> nil) and (sCliente <> '') then
  begin
    sEsVarios := 'N';
    if ADataSet.FieldByName('ESVARIOS_CLI').AsString = 'S' then
      sEsVarios := 'S';
    Qry := TUniQuery.Create(nil);
    try
      // Misma conexión que la tabla (ver GuardarParametrosEDocCliente).
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        ' UPDATE fza_clientes ' +
        ' SET ESVARIOS_CLI = :ESVARIOS ' +
        ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
      Qry.ParamByName('ESVARIOS').AsString := sEsVarios;
      Qry.ParamByName('CLIENTE').AsString := sCliente;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmClientes.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  GuardarParametrosEDocCliente(DataSet);
  GuardarClienteVarios(DataSet);
  // Vendedor asignado al cliente: lo proponen sus pedidos, albaranes y
  // facturas. No va en el SQL del DFM; se guarda si la base lo trae.
  GuardarVendedorRegistro(unqryTablaG.Connection, DataSet, 'fza_clientes',
    'CODIGO_VENDEDOR_CLI', ['CODIGO_CLI_CLI']);
end;

procedure TdmClientes.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  if (unqryFacturasClientes.RecordCount > 0) and
     (not SolicitarConfirmacion(
       SPreguntaBorrarClienteConFacturas)) then
      Abort;
end;

procedure TdmClientes.unqryTablaGBeforePost(DataSet: TDataSet);
var
  ConsultaTarifa: TUniQuery;
  Tarifa: string;
  sErrorNif: string;
begin
  // FZ-ISSUE-859: validar antes de auditar o reservar la numeracion.
  // El alta completamente vacia conserva su cancelacion habitual.
  if (Trim(DataSet.FieldByName('RAZON_SOCIAL_CLI').AsString) <> '') and
     (Trim(DataSet.FieldByName('CODIGO_PAI_CLI').AsString) = '') then
  begin
    DataSet.FieldByName('CODIGO_PAI_CLI').FocusControl;
    raise ECampoObligatorioBBDD.Create('CODIGO_PAI_CLI',
      SErrorPaisAltaRapidaCliente);
  end;
  if Trim(DataSet.FieldByName('RAZON_SOCIAL_CLI').AsString) <> '' then
  begin
    sErrorNif := ErrorNifCliente(
      DataSet.FieldByName('NIF_CLI').AsString,
      DataSet.FieldByName('CODIGO_PAI_CLI').AsString,
      DataSet.FieldByName('NOMBRE_PAI_CLI').AsString);
    if sErrorNif <> '' then
    begin
      DataSet.FieldByName('NIF_CLI').FocusControl;
      raise EValidacionBBDD.Create(sErrorNif);
    end;
  end;
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('RAZON_SOCIAL_CLI').AsString) = '') then
    Abort;
  (* if ((unqryRetenciones.State = dsInsert) or
      (unqryRetenciones.State = dsEdit)) then
         unqryRetenciones.Post; *)
  if Trim(unqryTablaG.FindField('RAZON_SOCIAL_CLI').AsString) = '' then
  begin
    raise ERangeError.CreateFmt(SErrorRazonSocialCliente,
      [unqryTablaG.FindField('RAZON_SOCIAL_CLI').AsString]);
  end
  else
  begin
    Tarifa := Trim(DataSet.FieldByName('TARIFA_ARTICULO_CLI').AsString);
    if (Tarifa <> '') and ((DataSet.State = dsInsert) or
       not SameText(Trim(VarToStr(DataSet.FieldByName(
         'TARIFA_ARTICULO_CLI').OldValue)), Tarifa)) then
    begin
      ConsultaTarifa := TUniQuery.Create(nil);
      try
        ConsultaTarifa.Connection := ConexionPrincipal;
        ConsultaTarifa.SQL.Text :=
          'SELECT CODIGO_TAR_ARTTAR FROM fza_tarifas ' +
          'WHERE CODIGO_TAR_ARTTAR = :TARIFA AND ESACTIVO_ARTTAR = ''S''';
        ConsultaTarifa.ParamByName('TARIFA').AsString := Tarifa;
        ConsultaTarifa.Open;
        if ConsultaTarifa.IsEmpty then
          raise ERangeError.CreateFmt(SErrorTarifaClienteNoDisponible,
            [Tarifa]);
      finally
        ConsultaTarifa.Free;
      end;
    end;
    // Las coincidencias se consultan en Cambio de código de cliente.
    GetCodigoAutoCliente;
  end;
end;
initialization
  RegistrarDataModule(TdmClientes);
  ForceReferenceToClass(TdmClientes);
end.

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEmpresas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de empresas.                                                  }
{    Queries de fza_empresas, retenciones, series, IVAs, países y facturación  }
{    emitida.                                                                  }
{******************************************************************************}
unit UniDataEmpresas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser, Datasnap.Provider,
  Datasnap.DBClient, Forms, Windows, Dateutils;

type
  TdmEmpresas = class(TdmBase)
    unqryRetenciones: TUniQuery;
    dsRetenciones: TDataSource;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    dsFacturasEmpresas: TDataSource;
    unqryFacturasEmpresas: TUniQuery;
    dsFacturasLineasEmpresas: TDataSource;
    unqryFacturasLineasEmpresas: TUniQuery;
    unqrySeries: TUniQuery;
    dsSeries: TDataSource;
    unqryBancos: TUniQuery;
    dsBancos: TDataSource;
    dsPaises: TDataSource;
    unqryPaises: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesAfterInsert(DataSet: TDataSet);
    procedure unqryRetencionesBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesBeforeInsert(DataSet: TDataSet);
    procedure unqrySeriesBeforePost(DataSet: TDataSet);
    procedure unqrySeriesAfterPost(DataSet: TDataSet);
    procedure unqrySeriesAfterInsert(DataSet: TDataSet);
    procedure unqryBancosBeforePost(DataSet: TDataSet);
    procedure unqryBancosAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    FEncolarPrecioPrestaShop: Boolean;
    // FZ-ISSUE-354: la casilla de recargo cambió en esta edición.
    FRecargoCambiado: Boolean;
    // Clientes a los que se pueden emitir las facturas internas TA/TV.
    FClientesTraspasos: TUniQuery;
    FDsClientesTraspasos: TDataSource;
    procedure AsegurarClienteTraspasosEnAlta(DataSet: TDataSet);
    procedure GrabarClienteTraspasos(
      DataSet: TDataSet;
      AConexion: TUniConnection);
    procedure GrabarTotalMaximoLinea(
      DataSet: TDataSet;
      AConexion: TUniConnection);
    procedure SincronizarRecargoClienteTraspasos(
      DataSet: TDataSet;
      AConexion: TUniConnection);
    function CampoPrecioPrestaShopCambiado(
      DataSet: TDataSet): Boolean;
    function ConfirmarCambioCriticoEmpresa(const sAccion: string): Boolean;
    function EmpresaAfectaPrestaShop(
      AConexion: TUniConnection;
      const ACodigoActual, ACodigoAnterior: string): Boolean;
    procedure ValidarSerieTokenizada;
    procedure ValidarSerieOtraEmpresa;
    { Private declarations }
  public
    procedure GetCodigoAutoEmpresa;
    procedure GetCodigoAutoRetencion;
    procedure GetCodigoAutoSerie;
    procedure GetCodigoAutoBanco;
//    function GetLastCodeEmpresa:Integer;
//    function GetZonaDefault:String;
    // Override: abre los lookups (Paises, Ivas). Las queries de detail
    // (Retenciones, Series, Historia/Facturacion) son lazy y se abren
    // al activar su sub-pestaña.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure AsegurarRetencionesAbierta;
    procedure AsegurarSeriesAbierta;
    procedure AsegurarBancosAbierta;
    procedure AsegurarHistoriaFacturacionAbierta;
    // Crea el cliente E_<empresa> de la empresa en curso, lo enlaza y graba
    // la ficha. La empresa debe estar ya grabada.
    function CrearClienteTraspasos: string;
    procedure RefrescarClientesTraspasos;
    property DsClientesTraspasos: TDataSource read FDsClientesTraspasos;
  end;

implementation

uses
  inLibCadenas, inLibDatasets, inLibSerieTokenizada,
  UniDataValoresAutomaticosRepositorio,
  System.Diagnostics,
  UniDataAperturaConsultas,
  inLibFormatoDocumento, inLibIBAN, inLibMsgComun,
  inLibMsgFacturas, UniDataPrestaShopEncolado,
  inLibClienteTraspasosEmpresa, UniDataClienteTraspasosEmpresaRepositorio,
  UniDataSeriesEmpresaRepositorio, inLibErroresBBDD;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

resourcestring
  SErrorFormatoDocumentoConComa =
    'El formato de documentos no puede contener una coma. La coma está ' +
    'reservada para separar facturas en los procesos por lotes.';

const
  // Separadores habituales en series (INFOR.26, A/26) que la lista general
  // de símbolos prohíbe
  SIMBOLOS_PERMITIDOS_SERIE = './';

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmEmpresas.ConfirmarCambioCriticoEmpresa(
  const sAccion: string): Boolean;
begin
  Result := SolicitarConfirmacion(
    Format(SPreguntaCambioCriticoEmpresa, [sAccion]));
end;

function TdmEmpresas.CampoPrecioPrestaShopCambiado(
  DataSet: TDataSet): Boolean;

  function Cambio(const ACampo: string): Boolean;
  begin
    Result := not SameText(
      VarToStr(DataSet.FieldByName(ACampo).OldValue),
      VarToStr(DataSet.FieldByName(ACampo).Value));
  end;

begin
  Result := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
    Result :=
      Cambio('CODIGO_EMP_EMP') or
      Cambio('ESACTIVO_EMP') or
      Cambio('GRUPO_ZONA_IVA_EMP');
end;

function TdmEmpresas.EmpresaAfectaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoActual, ACodigoAnterior: string): Boolean;
var
  sEmpresaPrestaShop: string;
begin
  sEmpresaPrestaShop := LeerCodigoEmpresaPrestaShop(
    AConexion,
    IdentidadSesion.Usuario);
  Result := SameText(Trim(ACodigoActual), sEmpresaPrestaShop) or
    SameText(Trim(ACodigoAnterior), sEmpresaPrestaShop);
end;

procedure TdmEmpresas.unqryRetencionesAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString := '0';
end;

procedure TdmEmpresas.unqryRetencionesBeforeInsert(DataSet: TDataSet);
begin
  inherited;
    if ( (unqryTablaG.State = dsInsert) or
         (unqryTablaG.State = dsEdit)
       ) then
      unqryTablaG.Post;
end;

procedure TdmEmpresas.unqryRetencionesBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  bSinErrores:Boolean;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryRetenciones.FindField(ANombre);
  end;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  if (FindField('PORCENTAJE_EMPRET').AsInteger <= 0) or
     FindField('PORCENTAJE_EMPRET').IsNull then
  begin
    raise ERangeError.CreateFmt(SErrorPorcentajeRetencionEmpresa,
      [FindField('PORCENTAJE_EMPRET').AsInteger]);
    bSinErrores := False;
  end;
  if bSinErrores then
  begin
    unqrySol := TUniQuery.Create(nil);
    try
      unqrySol.Connection := ConexionPrincipal;
      unqrySol.SQL.Text := 'SELECT * ' +
        '  FROM vi_empresas_retenciones ' +
        ' WHERE CODIGO_EMP_EMPRET = :CODIGO_EMP_EMP' +
        '   AND CODIGO_RETENCION_EMPRET <> :CODIGO_PROPIO';
      unqrySol.ParamByName('CODIGO_EMP_EMP').AsString :=
        FindField('CODIGO_EMP_EMPRET').AsString;
      // Sin el propio registro: al editar se comparaba consigo mismo
      if DataSet.State = dsEdit then
        unqrySol.ParamByName('CODIGO_PROPIO').AsString :=
          VarToStr(FindField('CODIGO_RETENCION_EMPRET').OldValue)
      else
        unqrySol.ParamByName('CODIGO_PROPIO').AsString := '';
      unqrySol.Open;
      if not ExistePeriodoUnico(
           unqrySol,
           FindField('FECHA_DESDE_EMPRET'),
           FindField('FECHA_HASTA_EMPRET')) then
      begin
        raise ERangeError.CreateFmt(SErrorRetencionesEmpresaConcurrentes,
          [FindField('CODIGO_EMP_EMPRET').AsString]);
        bSinErrores := False;
      end;
    finally
      FreeAndNil(unqrySol);
    end;
  end;
  if (bSinErrores) then
  begin
    ActualizarAuditoria(DataSet);
    GetCodigoAutoRetencion;
  end
  else
    Abort;
end;

procedure TdmEmpresas.unqrySeriesAfterInsert(DataSet: TDataSet);
begin
  inherited;
  Dataset.FindField('CODIGO_SERIE_EMPSER').AsString := '0';
  if Dataset.FindField('ESDEFECTO_EMPSER') <> nil then
    Dataset.FindField('ESDEFECTO_EMPSER').AsString := 'S';
end;

procedure TdmEmpresas.unqrySeriesAfterPost(DataSet: TDataSet);
begin
  AsegurarContadorCompraEmpresa(TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_EMP_EMPSER').AsString,
    IdentidadSesion.Usuario);
end;

procedure TdmEmpresas.unqrySeriesBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  bSinErrores:Boolean;
//  sCodigoSerie:String;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqrySeries.FindField(ANombre);
  end;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  ValidarSerieTokenizada;
  if (FindField('EMPSER').AsString = '') or
     FindField('EMPSER').IsNull or
     SimbolosProhibidos(
       FindField('EMPSER').AsString,
       PerfilesLectura,
       SIMBOLOS_PERMITIDOS_SERIE) then
  begin
    raise ERangeError.CreateFmt(SErrorSerieEmpresa,
      [FindField('EMPSER').AsString]);
    bSinErrores := False;
  end;
  ValidarSerieOtraEmpresa;
//    if (State = dsEdit) then
//      sCodigoSerie := FindField('CODIGO_SERIE_EMPSER').AsString
//    else
//      sCodigoSerie := '';
  if bSinErrores then
  begin
    unqrySol := TUniQuery.Create(nil);
    try
      unqrySol.Connection := ConexionPrincipal;
      unqrySol.SQL.Text := 'SELECT * ' +
        '  FROM vi_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :CODIGO_EMP_EMP';
//      if (sCodigoSerie <> '') then
// unqrySol.SQL.Text := unqrySol.SQL.Text + ' AND CODIGO_SERIE_EMPSER <> ' +
//                                                                 sCodigoSerie;
      unqrySol.ParamByName('CODIGO_EMP_EMP').AsString :=
        FindField('CODIGO_EMP_EMPSER').AsString;
      unqrySol.Open;
    finally
      FreeAndNil(unqrySol);
    end;
  end;
  if (bSinErrores) then
  begin
    ActualizarAuditoria(DataSet);
    GetCodigoAutoSerie;
  end
  else
    Abort;

end;

procedure TdmEmpresas.unqryBancosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Codigo a 0 -> lo asigna el contador 'EB' en el BeforePost.
  DataSet.FindField('CODIGO_EMPBAN').AsString          := '0';
  DataSet.FindField('ESACTIVO_EMPBAN').AsString        := 'S';
  DataSet.FindField('ESDEFECTO_COBRO_EMPBAN').AsString := 'N';
  DataSet.FindField('ESDEFECTO_PAGO_EMPBAN').AsString  := 'N';
end;

procedure TdmEmpresas.unqryBancosBeforePost(DataSet: TDataSet);
var
  sIban, sCCC, sBanco, sDC, sCuenta: string;
  stErr: TStringList;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryBancos.FindField(ANombre);
  end;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit) ) then
    unqryTablaG.Post;
  sIban := Trim(FindField('IBAN_EMPBAN').AsString);
    // El IBAN es opcional, pero si viene se valida y se descompone.
    if (sIban <> '') then
    begin
      stErr := TStringList.Create;
      try
        if (not TIBAN.ValidarIBAN(sIban, stErr)) then
          raise ERangeError.CreateFmt(SErrorIbanEmpresa, [stErr.Text]);
      finally
        FreeAndNil(stErr);
      end;
      sIban := TIBAN.FormatearElectronico(sIban);
      FindField('IBAN_EMPBAN').AsString := sIban;
      // Descomposicion del CCC espanol: entidad(4) + oficina(4) + DC + cuenta.
      sCCC := TIBAN.ExtraerCCC(sIban);
      if (TIBAN.DescomponerCCC(sCCC, sBanco, sDC, sCuenta)) then
      begin
        FindField('ENTIDAD_EMPBAN').AsString        := Copy(sBanco, 1, 4);
        FindField('OFICINA_EMPBAN').AsString        := Copy(sBanco, 5, 4);
        FindField('DIGITO_CONTROL_EMPBAN').AsString := sDC;
        FindField('CUENTA_EMPBAN').AsString         := sCuenta;
        FindField('CODIGO_BAN_EMPBAN').AsString     := Copy(sBanco, 1, 4);
      end;
  end;
  ActualizarAuditoria(DataSet);
  GetCodigoAutoBanco;
end;

procedure TdmEmpresas.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  qryBorrarLineas := TUniQuery.Create(Self);
  qryBorrarLineas.Connection := ConexionPrincipal;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_empresas_retenciones ' +
    ' WHERE CODIGO_EMP_EMPRET = :Empresa ;';
  qryBorrarLineas.Params.ParamByName('Empresa').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_empresas_series ' +
    ' WHERE CODIGO_EMP_EMPSER = :Empresa ;';
  qryBorrarLineas.Params.ParamByName('Empresa').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_empresas_bancos ' +
    ' WHERE CODIGO_EMP_EMPBAN = :Empresa ;';
  qryBorrarLineas.Params.ParamByName('Empresa').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.Free;
  try
    if FEncolarPrecioPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPrecioPrestaShop := False;
  end;
end;

procedure TdmEmpresas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  UniDataValoresAutomaticosRepositorio.AplicarValoresPorDefecto(
    ConexionPrincipal, unqryTablaG, 'fza_empresas');
  unqryTablaG.FindField('GRUPO_ZONA_IVA_EMP').AsString :=
       ObtenerValorPorDefecto(
         ConexionPrincipal,
         'vi_ivas_grupos',
         'IVA_IVAGRP',
         'ESDEFAULT_IVA_IVAGRP');
  if unqryTablaG.FindField('FORMATO_DOCUMENTO_EMP') <> nil then
    unqryTablaG.FindField('FORMATO_DOCUMENTO_EMP').AsString :=
      FORMATO_DOCUMENTO_DEFECTO;
  if unqryTablaG.FindField('ESIVA_RECARGO_COMPRAS_EMP') <> nil then
    unqryTablaG.FindField('ESIVA_RECARGO_COMPRAS_EMP').AsString := 'N';
  unqryTablaG.FieldByName(
    'ESTOKENS_CALENDARIO_NATURAL_EMP').AsString := 'N';
end;

procedure TdmEmpresas.ValidarSerieTokenizada;
var
  sSerieTokenizada: string;
begin
  sSerieTokenizada := Trim(
    unqrySeries.FieldByName('SERIE_TOKENIZADA_EMPSER').AsString);
  unqrySeries.FieldByName('SERIE_TOKENIZADA_EMPSER').AsString :=
    sSerieTokenizada;
  if sSerieTokenizada <> '' then
  begin
    if not EsSerieTokenizadaValida(sSerieTokenizada) then
    begin
      raise ERangeError.CreateFmt(
        SErrorSerieTokenizadaEmpresa,
        [sSerieTokenizada]);
    end;
    if unqryTablaG.FieldByName(
         'ESTOKENS_CALENDARIO_NATURAL_EMP').AsString <> 'S' then
    begin
      raise ERangeError.Create(
        SErrorSerieTokenizadaCalendarioNoNatural);
    end;
    if Trim(unqrySeries.FieldByName('EMPSER').AsString) = '' then
      unqrySeries.FieldByName('EMPSER').AsString :=
        ResolverSerieTokenizada(sSerieTokenizada, Date);
  end;
end;

// FZ-ISSUE-371: el texto de la serie (o su plantilla) no puede estar en
// otra empresa: la segunda factura chocaría con la clave NUMERO + SERIE.
procedure TdmEmpresas.ValidarSerieOtraEmpresa;
var
  sOtraEmpresa: string;
begin
  sOtraEmpresa := EmpresaQueUsaSerie(ConexionPrincipal,
    unqrySeries.FieldByName('CODIGO_EMP_EMPSER').AsString,
    unqrySeries.FieldByName('EMPSER').AsString,
    unqrySeries.FieldByName('SERIE_TOKENIZADA_EMPSER').AsString,
    unqrySeries.FieldByName('TIPO_DOC_EMPSER').AsString,
    unqrySeries.FieldByName('CODIGO_SERIE_EMPSER').AsString);
  // Dato del usuario, no fallo del programa: EValidacionBBDD se muestra
  // como aviso, sin la pantalla de error.
  if sOtraEmpresa <> '' then
    raise EValidacionBBDD.CreateFmt(SErrorSerieUsadaOtraEmpresa,
      [unqrySeries.FieldByName('EMPSER').AsString, sOtraEmpresa]);
end;

procedure TdmEmpresas.unqryTablaGAfterPost(DataSet: TDataSet);
var
  oCampoFormato: TField;
  oCampoPie1: TField;
  oCampoPie2: TField;
  oCampoPie3: TField;
  oCampoPie4: TField;
  sCodigo: string;
  sFormato: string;
  oConexion: TUniConnection;
  unqryPie: TUniQuery;
  unqryFormato: TUniQuery;
begin
  // Usar la conexion del Post evita bloquear la misma fila que la
  // conexion principal.
  oConexion := ConexionPrincipal;
  if DataSet is TUniQuery then
    oConexion := TUniQuery(DataSet).Connection;
  oCampoFormato := DataSet.FindField('FORMATO_DOCUMENTO_EMP');
  if oCampoFormato <> nil then
  begin
    sCodigo := DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
    sFormato := Trim(oCampoFormato.AsString);
    if sFormato = '' then
      sFormato := FORMATO_DOCUMENTO_DEFECTO;
    unqryFormato := TUniQuery.Create(nil);
    try
      unqryFormato.Connection := oConexion;
      unqryFormato.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET FORMATO_DOCUMENTO_EMP = :FORMATO ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      unqryFormato.ParamByName('FORMATO').AsString := sFormato;
      unqryFormato.ParamByName('CODIGO_EMP').AsString := sCodigo;
      unqryFormato.Execute;
    finally
      FreeAndNil(unqryFormato);
    end;
  end;
  oCampoPie1 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_1_EMP');
  oCampoPie2 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_2_EMP');
  oCampoPie3 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_3_EMP');
  oCampoPie4 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_4_EMP');
  if (oCampoPie1 <> nil) and
     (oCampoPie2 <> nil) and
     (oCampoPie3 <> nil) and
     (oCampoPie4 <> nil) then
  begin
    sCodigo := DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
    unqryPie := TUniQuery.Create(nil);
    try
      unqryPie.Connection := oConexion;
      unqryPie.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET TEXTO_PIE_TICKET_CAJA_1_EMP = :PIE1, ' +
        '       TEXTO_PIE_TICKET_CAJA_2_EMP = :PIE2, ' +
        '       TEXTO_PIE_TICKET_CAJA_3_EMP = :PIE3, ' +
        '       TEXTO_PIE_TICKET_CAJA_4_EMP = :PIE4 ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      unqryPie.ParamByName('PIE1').AsString :=
        Copy(Trim(oCampoPie1.AsString), 1, 42);
      unqryPie.ParamByName('PIE2').AsString :=
        Copy(Trim(oCampoPie2.AsString), 1, 42);
      unqryPie.ParamByName('PIE3').AsString :=
        Copy(Trim(oCampoPie3.AsString), 1, 42);
      unqryPie.ParamByName('PIE4').AsString :=
        Copy(Trim(oCampoPie4.AsString), 1, 42);
      unqryPie.ParamByName('CODIGO_EMP').AsString := sCodigo;
      unqryPie.Execute;
    finally
      FreeAndNil(unqryPie);
    end;
  end;
  GrabarClienteTraspasos(DataSet, oConexion);
  AsegurarContadorCompraEmpresa(oConexion,
    DataSet.FieldByName('CODIGO_EMP_EMP').AsString, IdentidadSesion.Usuario);
  GrabarTotalMaximoLinea(DataSet, oConexion);
  SincronizarRecargoClienteTraspasos(DataSet, oConexion);
  try
    if FEncolarPrecioPrestaShop then
      EncolarTodosWebPrestaShop(
        oConexion,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPrecioPrestaShop := False;
  end;
end;

function DatosClienteTraspasos(
  ADataSet: TDataSet): TDatosClienteTraspasosEmpresa;
begin
  Result := Default(TDatosClienteTraspasosEmpresa);
  Result.CodigoEmpresa := ADataSet.FieldByName('CODIGO_EMP_EMP').AsString;
  Result.RazonSocial := ADataSet.FieldByName('RAZON_SOCIAL_EMP').AsString;
  Result.Nif := ADataSet.FieldByName('NIF_EMP').AsString;
  Result.Movil := ADataSet.FieldByName('MOVIL_EMP').AsString;
  Result.Email := ADataSet.FieldByName('EMAIL_EMP').AsString;
  Result.Direccion1 := ADataSet.FieldByName('DIRECCION1_EMP').AsString;
  Result.Direccion2 := ADataSet.FieldByName('DIRECCION2_EMP').AsString;
  Result.CodigoPostal := ADataSet.FieldByName('CODIGO_POSTAL_EMP').AsString;
  Result.Poblacion := ADataSet.FieldByName('POBLACION_EMP').AsString;
  Result.Provincia := ADataSet.FieldByName('PROVINCIA_EMP').AsString;
  Result.CodigoPais := ADataSet.FieldByName('CODIGO_PAI_EMP').AsString;
  Result.NombrePais := ADataSet.FieldByName('NOMBRE_PAI_EMP').AsString;
  Result.EsRegimenAgricola := SameText(
    ADataSet.FieldByName('ESREGIMENESPECIALAGRICOLA_EMP').AsString, 'S');
  if ADataSet.FindField('ESIVA_RECARGO_COMPRAS_EMP') <> nil then
    Result.EsRecargoEquivalencia := SameText(
      ADataSet.FieldByName('ESIVA_RECARGO_COMPRAS_EMP').AsString, 'S');
end;

procedure TdmEmpresas.AsegurarClienteTraspasosEnAlta(DataSet: TDataSet);
var
  oCampo: TField;
begin
  // Toda empresa nueva nace con su cliente de traspasos E_<código>, salvo
  // que el usuario ya haya elegido otro en el desplegable.
  oCampo := DataSet.FindField('CODIGO_CLI_TRASPASOS_EMP');
  if (DataSet.State = dsInsert) and (oCampo <> nil) and
     (Trim(oCampo.AsString) = '') then
  begin
    oCampo.AsString := CrearClienteTraspasosEmpresa(
      TUniQuery(DataSet).Connection,
      DatosClienteTraspasos(DataSet),
      IdentidadSesion.Usuario);
    RefrescarClientesTraspasos;
  end;
end;

procedure TdmEmpresas.GrabarClienteTraspasos(
  DataSet: TDataSet;
  AConexion: TUniConnection);
var
  oCampo   : TField;
  oConsulta: TUniQuery;
begin
  // La columna no está en el SQLUpdate del DFM (como el formato de
  // documentos y el pie del ticket): se graba aquí.
  oCampo := DataSet.FindField('CODIGO_CLI_TRASPASOS_EMP');
  if oCampo <> nil then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET CODIGO_CLI_TRASPASOS_EMP = NULLIF(:CLIENTE, '''') ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      oConsulta.ParamByName('CLIENTE').AsString := Trim(oCampo.AsString);
      oConsulta.ParamByName('CODIGO_EMP').AsString :=
        DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

// FZ-ISSUE-255. Fuera del SQLUpdate del DFM, como el cliente de traspasos:
// sin el script 20261006_empresas_total_maximo_linea.sql la vista no trae
// la columna y no se graba nada. Vacío o 0 = sin límite (NULL).
procedure TdmEmpresas.GrabarTotalMaximoLinea(
  DataSet: TDataSet;
  AConexion: TUniConnection);
var
  oCampo   : TField;
  oConsulta: TUniQuery;
begin
  oCampo := DataSet.FindField('TOTAL_MAXIMO_LINEA_EMP');
  if oCampo <> nil then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET TOTAL_MAXIMO_LINEA_EMP = NULLIF(GREATEST(:TOTAL, 0), 0) ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      oConsulta.ParamByName('TOTAL').AsCurrency := oCampo.AsCurrency;
      oConsulta.ParamByName('CODIGO_EMP').AsString :=
        DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

// FZ-ISSUE-354. El recargo del cliente de traspasos decide si la factura
// TA/TV lleva recargo: si la empresa entra o sale del régimen, su cliente
// la sigue. Sólo cuando cambia la casilla, para no deshacer en cada
// grabación un ajuste hecho a mano en la ficha del cliente.
procedure TdmEmpresas.SincronizarRecargoClienteTraspasos(
  DataSet: TDataSet;
  AConexion: TUniConnection);
var
  oCliente: TField;
begin
  try
    oCliente := DataSet.FindField('CODIGO_CLI_TRASPASOS_EMP');
    if FRecargoCambiado and (oCliente <> nil) then
      ActualizarRecargoClienteTraspasos(
        AConexion,
        oCliente.AsString,
        DatosClienteTraspasos(DataSet).EsRecargoEquivalencia,
        IdentidadSesion.Usuario);
  finally
    FRecargoCambiado := False;
  end;
end;

function TdmEmpresas.CrearClienteTraspasos: string;
begin
  if unqryTablaG.State = dsBrowse then
    unqryTablaG.Edit;
  Result := CrearClienteTraspasosEmpresa(
    unqryTablaG.Connection,
    DatosClienteTraspasos(unqryTablaG),
    IdentidadSesion.Usuario);
  RefrescarClientesTraspasos;
  unqryTablaG.FieldByName('CODIGO_CLI_TRASPASOS_EMP').AsString := Result;
  unqryTablaG.Post;
end;

procedure TdmEmpresas.RefrescarClientesTraspasos;
begin
  if FClientesTraspasos.Active then
    FClientesTraspasos.Refresh;
end;

procedure TdmEmpresas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo asignaciones de Connection y MasterSource. Los .Open se han
  // movido a AbrirDetalles (callback main thread con overlay visible)
  // para no congelar la UI durante la creacion del data module.
  unqryRetenciones.Connection            := ConexionPrincipal;
  unqrySeries.Connection                 := ConexionPrincipal;
  unqryBancos.Connection                 := ConexionPrincipal;
  unqryIvas.Connection                   := ConexionPrincipal;
  unqryFacturasEmpresas.Connection       := ConexionPrincipal;
  unqryFacturasLineasEmpresas.Connection := ConexionPrincipal;
  unqryPaises.Connection                 := ConexionPrincipal;
  unqryTablaG.AfterPost                  := unqryTablaGAfterPost;
  unqryTablaG.BeforeInsert               := unqryTablaGBeforeInsert;
  unqryTablaG.BeforeEdit                 := unqryTablaGBeforeEdit;
  FClientesTraspasos := TUniQuery.Create(Self);
  FClientesTraspasos.Connection := ConexionPrincipal;
  FClientesTraspasos.SQL.Text := SQL_CLIENTES_TRASPASOS_EMPRESA;
  FClientesTraspasos.ReadOnly := True;
  FDsClientesTraspasos := TDataSource.Create(Self);
  FDsClientesTraspasos.DataSet := FClientesTraspasos;
end;

procedure TdmEmpresas.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryFacturasEmpresas.MasterSource := ADataSource;
  unqryFacturasLineasEmpresas.MasterSource := ADataSource;
  unqryRetenciones.MasterSource := ADataSource;
  unqrySeries.MasterSource := ADataSource;
  unqryBancos.MasterSource := ADataSource;
end;

procedure TdmEmpresas.AbrirDetalles;
const
  TAG = 'Empresas.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Solo lookups. Las queries de detail (Retenciones, Series,
  // FacturasEmpresas, FacturasLineasEmpresas) son lazy: se abren al
  // activar su pestaña via AsegurarXxxAbierta.
  AbrirConsultaConTiempo(
    unqryPaises, TAG, 'unqryPaises', RegistroLog);
  AbrirConsultaConTiempo(
    unqryIvas, TAG, 'unqryIvas', RegistroLog);
  AbrirConsultaConTiempo(
    FClientesTraspasos, TAG, 'ClientesTraspasos', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmEmpresas.AsegurarRetencionesAbierta;
var swQ: TStopwatch;
begin
  if not unqryRetenciones.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryRetenciones.Open;
    RegistroLog.RegistrarRendimiento('Empresas.Lazy', 'unqryRetenciones OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Empresas.Lazy',
        'unqryRetenciones ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmEmpresas.AsegurarSeriesAbierta;
var swQ: TStopwatch;
begin
  if not unqrySeries.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqrySeries.Open;
    RegistroLog.RegistrarRendimiento('Empresas.Lazy', 'unqrySeries OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Empresas.Lazy',
        'unqrySeries ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmEmpresas.AsegurarBancosAbierta;
var swQ: TStopwatch;
begin
  if not unqryBancos.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryBancos.Open;
    RegistroLog.RegistrarRendimiento('Empresas.Lazy', 'unqryBancos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Empresas.Lazy',
        'unqryBancos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmEmpresas.AsegurarHistoriaFacturacionAbierta;
var swQ: TStopwatch;
begin
  // Las dos queries van en pareja: cabecera + lineas de facturas
  // emitidas a la empresa.
  if not (unqryFacturasEmpresas.Active and
          unqryFacturasLineasEmpresas.Active) then
  begin
  swQ := TStopwatch.StartNew;
  try
    if not unqryFacturasEmpresas.Active then
      unqryFacturasEmpresas.Open;
    if not unqryFacturasLineasEmpresas.Active then
      unqryFacturasLineasEmpresas.Open;
    RegistroLog.RegistrarRendimiento('Empresas.Lazy',
      'unqryFacturasEmpresas+Lineas OK', swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Empresas.Lazy',
        'unqryFacturasEmpresas+Lineas ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmEmpresas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMP_EMP').AsString = '0' then
  begin
      unqryTablaG.FindField('CODIGO_EMP_EMP').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'EM',
                                                   IdentidadSesion.Usuario);
  end;
  if unqryTablaG.FindField('ORDEN_EMP').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_EMP').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'EO',
                                                   IdentidadSesion.Usuario);
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  if not ConfirmarCambioCriticoEmpresa(SAccionBorrarEmpresa) then
  begin
    Abort;
  end;
  if unqryFacturasEmpresas.RecordCount > 0 then
  begin
    if not SolicitarConfirmacion(
      SPreguntaBorrarEmpresaConFacturas) then
    begin
      Abort;
    end;
  end;
  FEncolarPrecioPrestaShop := EmpresaAfectaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_EMP_EMP').AsString,
    '');
end;

procedure TdmEmpresas.unqryTablaGBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  if not ConfirmarCambioCriticoEmpresa(SAccionEditarEmpresa) then
  begin
    Abort;
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if not ConfirmarCambioCriticoEmpresa(SAccionCrearEmpresa) then
  begin
    Abort;
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  bError:Boolean;
  sCodigoAnterior: string;
  sCodigoEmpresa, sRazonSocial:String;
  sFormatoDocumento: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  FRecargoCambiado := False;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('RAZON_SOCIAL_EMP').AsString) = '') then
    Abort;
  bError := False;
  if ((unqryRetenciones.State = dsInsert) or
      (unqryRetenciones.State = dsEdit)) then
         unqryRetenciones.Post;
  if FindField('FORMATO_DOCUMENTO_EMP') <> nil then
    begin
      sFormatoDocumento := Trim(
        FindField('FORMATO_DOCUMENTO_EMP').AsString);
      if sFormatoDocumento = '' then
        sFormatoDocumento := FORMATO_DOCUMENTO_DEFECTO;
      if Pos(',', sFormatoDocumento) > 0 then
      begin
        raise ERangeError.Create(SErrorFormatoDocumentoConComa);
      end;
      FindField('FORMATO_DOCUMENTO_EMP').AsString :=
        sFormatoDocumento;
    end;
    if FindField('TEXTO_PIE_TICKET_CAJA_1_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_1_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_1_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_2_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_2_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_2_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_3_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_3_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_3_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_4_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_4_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_4_EMP').AsString), 1, 42);
    sCodigoEmpresa := Trim(FindField('CODIGO_EMP_EMP').AsString);
    sRazonSocial := Trim(FindField('RAZON_SOCIAL_EMP').AsString);
    if sRazonSocial = '' then
    begin
      raise ERangeError.CreateFmt(SErrorRazonSocialEmpresa,
                                 [sRazonSocial]);
    end;
    if (sCodigoEmpresa = '') or
       SimbolosProhibidos(sCodigoEmpresa, PerfilesLectura) then
    begin
      raise ERangeError.CreateFmt(SErrorCodigoEmpresa,
                                 [sCodigoEmpresa]);
    end;
  if bError then
    Abort
  else
  begin
    GetCodigoAutoEmpresa;
    AsegurarClienteTraspasosEnAlta(DataSet);
    sCodigoAnterior := '';
    if DataSet.State = dsEdit then
      sCodigoAnterior := VarToStr(
        DataSet.FieldByName('CODIGO_EMP_EMP').OldValue);
    FRecargoCambiado := (DataSet.State = dsEdit) and
      (FindField('ESIVA_RECARGO_COMPRAS_EMP') <> nil) and
      not SameText(
        VarToStr(FindField('ESIVA_RECARGO_COMPRAS_EMP').OldValue),
        FindField('ESIVA_RECARGO_COMPRAS_EMP').AsString);
    FEncolarPrecioPrestaShop :=
      CampoPrecioPrestaShopCambiado(DataSet) and
      EmpresaAfectaPrestaShop(
        TUniQuery(DataSet).Connection,
        DataSet.FieldByName('CODIGO_EMP_EMP').AsString,
        sCodigoAnterior);
  end;
end;

procedure TdmEmpresas.GetCodigoAutoRetencion;
begin
  if unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString = '0' then
  begin
      unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'RT',
                                                   IdentidadSesion.Usuario);
    end;
end;

procedure TdmEmpresas.GetCodigoAutoSerie;
begin
  if unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString = '0' then
  begin
      unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString :=
                         ObtenerSiguienteContador(
                                                  ConexionPrincipal,
                                                  'ES',
                                                  IdentidadSesion.Usuario);
  end;
end;

procedure TdmEmpresas.GetCodigoAutoBanco;
begin
  if unqryBancos.FindField('CODIGO_EMPBAN').AsString = '0' then
  begin
      unqryBancos.FindField('CODIGO_EMPBAN').AsString :=
                         ObtenerSiguienteContador(
                                                  ConexionPrincipal,
                                                  'EB',
                                                  IdentidadSesion.Usuario);
  end;
end;





initialization
  RegistrarDataModule(TdmEmpresas);
  ForceReferenceToClass(TdmEmpresas);
end.

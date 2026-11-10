unit UniDataComprasSesiones;

{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesiones                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos de las sesiones de compra, sus líneas, fotos provisionales y        }
{    consultas auxiliares para materializar artículos y documentos.            }
{******************************************************************************}

interface

uses
  inLibRegistroPantallas,
  inLibComprasSesionesMaterializacionIntf,
  inLibComprasSesionesCodigoArticulo,
  System.Generics.Collections,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  inLibUser, frCoreClasses, inLibTrazabilidad, inLibTrazabilidadAlta;

type
  TGeneracionCodigoArticuloSesion = record
    Codigo: string;
    Huella: string;
    Familia: string;
  end;

  TdmComprasSesiones = class(TdmBase)
    // Cabecera de sesión (lista principal). unqryTablaG ya existe en TdmBase.
    unqrySesionLin: TUniQuery;
    dsSesionLin: TDataSource;
    // Lista de documentos generados al materializar la sesion (PEDC /
    // ALBC). Master/detail con unqryTablaG via SERIE_SES/NUMERO_SES.
    // Alimenta la pestania 'Documentos' del Mto.
    unqrySesDocs: TUniQuery;
    dsSesDocs: TDataSource;
    // Fotos provisionales asociadas a las líneas de la sesión.
    unqrySesionFotos: TUniQuery;
    dsSesionFotos: TDataSource;

    unqrySesionFil: TUniQuery;
    dsSesionFil: TDataSource;

    unqrySesionFilAtr: TUniQuery;
    dsSesionFilAtr: TDataSource;

    unqrySesionCel: TUniQuery;
    dsSesionCel: TDataSource;

    unqrySesionProps: TUniQuery;
    dsSesionProps: TDataSource;

    unqrySesionLinProps: TUniQuery;
    dsSesionLinProps: TDataSource;

    unqrySesionKits: TUniQuery;
    dsSesionKits: TDataSource;

    unqrySesionKitsDet: TUniQuery;
    dsSesionKitsDet: TDataSource;

    // Vista PREVIEW para la pestaña Materialización
    unqryPreviewSkus: TUniQuery;
    dsPreviewSkus: TDataSource;

    // Sub-grid de precios por SKU (solo activo si ESPRECIO_POR_SKU_SES='S')
    unqryLineaSkusPrecios: TUniQuery;
    dsLineaSkusPrecios: TDataSource;

    // Resumen agregado por almacén para la pestaña Materialización
    unqryResumenAlmacen: TUniQuery;
    dsResumenAlmacen: TDataSource;

    // Pestaña Proveedor: ficha completa del proveedor de la sesion (con el
    // nombre de su sistema de tallas por defecto) y su biblioteca de kits
    // de cantidades por talla (fza_proveedores_kits / _det). Se recargan
    // al navegar de sesion o cambiar CODIGO_PRV_SES (RecargarProveedorSesion).
    unqryPrvFicha: TUniQuery;
    dsPrvFicha: TDataSource;
    unqryPrvKits: TUniQuery;
    dsPrvKits: TDataSource;
    unqryPrvKitsDet: TUniQuery;
    dsPrvKitsDet: TDataSource;
    // Etiqueta descriptiva por kit para el desplegable "Aplicar kit" de la
    // cabecera de la sesion: "NOMBRE SISTEMA primera(cant)...ultima(cant)".
    // SQL en DataModuleCreate (evita comillas anidadas en el dfm).
    unqryPrvKitsCombo: TUniQuery;
    dsPrvKitsCombo: TDataSource;

    // Auxiliares (lookups)
    unqryProveedores: TUniQuery;
    dsProveedores: TDataSource;
    unqryFamilias: TUniQuery;
    dsFamilias: TDataSource;
    unqryVariaciones: TUniQuery;
    dsVariaciones: TDataSource;
    unqryVariacionesAtributos: TUniQuery;
    dsVariacionesAtributos: TDataSource;
    unqryAtributosConjuntos: TUniQuery;
    dsAtributosConjuntos: TDataSource;
    unqryAtributosValores: TUniQuery;
    dsAtributosValores: TDataSource;
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    unqryPropiedadesValores: TUniQuery;
    dsPropiedadesValores: TDataSource;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    unqryFormasPago: TUniQuery;
    dsFormasPago: TDataSource;
    // Lookup de temporadas (fza_propiedades_valores con
    // ID_PROP_PV='TEMPORADA').
    // Una por sesion; se propaga a fza_articulos_propiedades al materializar.
    unqryTemporadas: TUniQuery;
    dsTemporadas: TDataSource;
    // Lookup de series de la empresa actual para TIPO_DOC='SE'
    unqryEmpresaSeries: TUniQuery;
    dsEmpresaSeries: TDataSource;

    // Detección de duplicados al teclear código de artículo
    unqryArticuloExiste: TUniQuery;

    // Contador propio: TIPO_DOC_CON = 'SE' (SEsion de compra; varchar(2))
    unstrdprcGetContadorSesion: TUniStoredProc;

    // Stored procs auxiliares (validación, etc.)
    unstrdprcValidarSesion: TUniStoredProc;

    // ------------------------------------------------------------------
    // Impresion FastReport horizontal (compras_sesiones, print)
    // ------------------------------------------------------------------
    // Vista cabecera enriquecida (empresa + proveedor + totales).
    unqryCabSesionPrint:  TUniQuery;
    dsCabSesionPrint:     TDataSource;
    // Lineas con T01..T21 pivotadas desde fza_compras_sesiones_celdas.
    unqryLinSesionPrint:  TUniQuery;
    dsLinSesionPrint:     TDataSource;
    // Guias (leyenda) de los sistemas de tallas usados en la sesion.
    unqryGuiasSesionPrint: TUniQuery;
    dsGuiasSesionPrint:    TDataSource;
    // Datasets FastReport con UserName estable para que el report los
    // resuelva por nombre via RebindReportDataSetsByDataModule.
    fxdsCabSesion:   TfrxDBDataset;
    fxdsLinSesion:   TfrxDBDataset;
    fxdsGuiasSesion: TfrxDBDataset;

    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure AntesBorrarSesionBarras(DataSet: TDataSet);
    procedure unqrySesionLinAfterInsert(DataSet: TDataSet);
    procedure unqrySesionLinBeforePost(DataSet: TDataSet);
    procedure unqrySesionLinAfterPost(DataSet: TDataSet);
    procedure unqrySesionLinAfterDelete(DataSet: TDataSet);
    procedure unqrySesionCelAfterPost(DataSet: TDataSet);
    function TrazabilidadLineaActual: TTrazabilidadAlta;
    procedure RefrescarCeldasLineaActual;
    procedure MarcarArticuloPorLotes(AActivar: Boolean);
  private
    FImportacionMasiva: Boolean;
    FInstanteCargaSesion: TDateTime;
    FPermitirLineasSinCodigoArticulo: Boolean;
    FProximaLineaImportacion: Integer;
    FUltimaLineaImportacion: Integer;
    FUnidadTrabajoImportacionOcr: IUnidadTrabajoMaterializacion;
    FTallajeDefectoActual: Integer;
                        // Sistema de tallas (ID_AC) que se propone a la
                        // siguiente linea NUEVA de la sesion. Arranca en 0
                        // (sin defecto). CopiarDefectosProveedor lo fija al
                        // ID_AC_TALLAS_PRV del proveedor recien elegido;
                        // cuando el usuario cambia el sistema de tallas de
                        // una linea (combo dbcLinTallas) pasa
                        // a ser ese, no el del proveedor: "se cambia el
                        // defecto del documento", no el del proveedor.
                        // RecargarProveedorSesion lo resetea a 0 al navegar
                        // a otra sesion o proveedor.
    FGeneracionesCodigoArticulo: TDictionary<string,
      TGeneracionCodigoArticuloSesion>;
    function ConexionDatos: TUniConnection;
    procedure LogSes(const ATexto: string);
    procedure ConfigurarSqlCabecera;
    function SqlLecturaCabecera: string;
    procedure ConfigurarLecturasCabecera;
    procedure ConectarConsultas;
    procedure ConfigurarConsultaKitsProveedor;
    procedure ConectarCatalogos;
    procedure AbrirCatalogos;
    procedure AjustarCamposDerivadosCabecera;
    procedure ValidarCambioProveedorFormulaCodigo;
    procedure CalcularTotalesLineaActual;
    procedure PrepararLineaSesionParaPost(DataSet: TDataSet);
    procedure NormalizarClasificacionLineaSesion;
    procedure MarcarDuplicadoLineaSesion;
    procedure PersistirTotalesSesion;
    function FormulaCodigoArticuloSesion: string;
    procedure CargarValoresFormulaCodigoArticulo(
      out AValores: TValoresFormulaCodigoArticuloSesion);
    procedure ResolverContadorFormulaCodigoArticulo(
      const AFormula: string;
      var AValores: TValoresFormulaCodigoArticuloSesion);
    function ClaveLineaCodigoArticulo: string;
    function HuellaGeneracionCodigoArticulo(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string;
    function EsMismaGeneracionCodigoArticulo(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion;
      const ACodigo: string): Boolean;
    procedure RegistrarGeneracionCodigoArticulo(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion;
      const ACodigo: string);
    function EsArticuloPersistido(const ACodigo: string): Boolean;
    procedure OlvidarGeneracionCodigoArticulo;
    function EsFamiliaActiva(const ACodigo: string): Boolean;
    procedure AsignarCodigoArticuloLinea(const ACodigo: string);
    procedure LimpiarCodigoArticuloLinea;
    function BuscarColisionCodigoArticulo(
      const ACodigo: string): Integer;
    function GenerarCodigoArticuloDisponible(
      const AFormula: string;
      var AValores: TValoresFormulaCodigoArticuloSesion): string;
    function VariacionInicialSesion: string;
    procedure AsegurarVariacionSesion(ADataSet: TDataSet);
  public
    // F-LOTEC-013: interruptores leídos por la ficha de sesiones (todo
    // apagado por defecto: la materialización no toca lotes).
    ActivacionTrazabilidad: TActivacionTrazabilidad;
    destructor Destroy; override;
    property PermitirLineasSinCodigoArticulo: Boolean
      read FPermitirLineasSinCodigoArticulo
      write FPermitirLineasSinCodigoArticulo;
    property TallajeDefectoActual: Integer read FTallajeDefectoActual
                                            write FTallajeDefectoActual;
    // Tipos de variación activos (fza_variaciones.ESACTIVO_VAR = 'S').
    function VariacionesActivas: Integer;
    // Propone a la cabecera en edición y sin líneas el tipo de variación
    // del proveedor: el de su colección de tallas por defecto o el de su
    // última sesión (FZ-ISSUE-420).
    procedure ProponerVariacionProveedor(const ACodigoProveedor: string);
    class function ResolverCodigoFamiliaConexion(AConn: TUniConnection;
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean; static;
    function GenerarCodigoArticuloLineaActual(
      AReemplazarCodigo: Boolean): Boolean;
    function GenerarCodigoArticuloTrasCambiarFamilia: Boolean;
    function GenerarCodigoArticuloTrasCambiarModelo: Boolean;
    procedure GetCodigoAutoSesion;
    procedure IniciarImportacionMasiva(APrimeraLinea,
      ACantidadLineas: Integer);
    procedure FinalizarImportacionMasiva;
    procedure IniciarUnidadTrabajoImportacionOcr;
    procedure ConfirmarUnidadTrabajoImportacionOcr;
    procedure RevertirUnidadTrabajoImportacionOcr;
    procedure AsegurarSerieEnEmpresasSeries(const AEmpresa, ASerie: string);
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ProponerSerieNuevaSesion;
    procedure ChequearDuplicado(const ACodigoArt: string;
                                 out AExiste: Boolean;
                                 out ADescripcion: string);
    procedure RefrescarTotalesSesion;
    function  DetectarConflictoConcurrencia: Boolean;
    procedure AplicarKitAFila(const AIdKit: string;
                              const ALineaID: Integer;
                              const AIdFila: Integer);
    procedure AplicarKitATodasFilas(const AIdKit: string;
                                    const ALineaID: Integer);
    procedure ReconstruirFilasLinea(const ALineaID: Integer);
    // Reabre la ficha y los kits del proveedor indicado (pestaña Proveedor).
    // Con cadena vacia deja las queries cerradas.
    procedure RecargarProveedorSesion(const ACodigoPrv: string);
    procedure ConfigurarVariacionLinea(const ACodigo: string);
    procedure HeredarDescripcionProveedor;
    function DejarDescripcionEnBlanco: Boolean;
    function DescripcionParaLinea(const ADescripcion: string): string;

    // Abre las tres queries de impresion para una sesion concreta.
    // Usado por TfrmPrintSesion.preparar_consulta.
    procedure PrepararPrint(const ASerie, ANumero: string);
  end;


implementation

uses
  UniDataComprasSesionesOperaciones,
  UniDataCodigosBarrasSesion,
  System.Variants,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inLibCodigosSinBarra,
  inLibComprasSesionesReglas,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibMsgCompras, inLibErroresBBDD,
  UniDataComprasSesionesPresentacionRepositorio,
  UniDataComprasSesionesUnidadTrabajo, UniDataFamilias;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  fdescripcionblanco = 'ESDESCRIPCION_BLANCO_SES';

resourcestring
  SErrorImportacionOcrConUnidadTrabajoActiva =
    'La importación OCR ya tiene una unidad de trabajo activa';
  SErrorImportacionOcrSinUnidadTrabajoActiva =
    'La importación OCR no tiene una unidad de trabajo activa';

function TdmComprasSesiones.ConexionDatos: TUniConnection;
begin
  Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmComprasSesiones.IniciarUnidadTrabajoImportacionOcr;
begin
  if Assigned(FUnidadTrabajoImportacionOcr) then
    raise EInvalidOpException.Create(
      SErrorImportacionOcrConUnidadTrabajoActiva);
  FUnidadTrabajoImportacionOcr :=
    TUnidadTrabajoMaterializacionUniDAC.Create(
      ConexionDatos);
  try
    FUnidadTrabajoImportacionOcr.Iniciar;
  except
    FUnidadTrabajoImportacionOcr := nil;
    raise;
  end;
end;

procedure TdmComprasSesiones.ConfirmarUnidadTrabajoImportacionOcr;
begin
  if not Assigned(FUnidadTrabajoImportacionOcr) then
    raise EInvalidOpException.Create(
      SErrorImportacionOcrSinUnidadTrabajoActiva);
  FUnidadTrabajoImportacionOcr.Confirmar;
  FUnidadTrabajoImportacionOcr := nil;
end;

procedure TdmComprasSesiones.RevertirUnidadTrabajoImportacionOcr;
begin
  if Assigned(FUnidadTrabajoImportacionOcr) then
  begin
    try
      FUnidadTrabajoImportacionOcr.Revertir;
    finally
      FUnidadTrabajoImportacionOcr := nil;
    end;
  end;
end;

procedure TdmComprasSesiones.IniciarImportacionMasiva(
  APrimeraLinea, ACantidadLineas: Integer);
begin
  FImportacionMasiva :=
    (APrimeraLinea > 0) and (ACantidadLineas > 0);
  FProximaLineaImportacion := APrimeraLinea;
  if FImportacionMasiva then
    FUltimaLineaImportacion :=
      APrimeraLinea + ((ACantidadLineas - 1) * 10)
  else
    FUltimaLineaImportacion := 0;
end;

procedure TdmComprasSesiones.FinalizarImportacionMasiva;
begin
  FImportacionMasiva := False;
  FProximaLineaImportacion := 0;
  FUltimaLineaImportacion := 0;
end;

class function TdmComprasSesiones.ResolverCodigoFamiliaConexion(
  AConn: TUniConnection; const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
begin
  Result := ResolverCodigoArticuloFamilia(AConn, ACodigoTecleado,
    AUsuario, ACodigoGenerado);
end;

destructor TdmComprasSesiones.Destroy;
begin
  FreeAndNil(FGeneracionesCodigoArticulo);
  inherited;
end;

function TdmComprasSesiones.FormulaCodigoArticuloSesion: string;
begin
  Result := FORMULA_CODIGO_ARTICULO_SESION_DEFECTO;
  if Assigned(ParametrosApp) then
    Result := ParametrosApp.GetString(
      CLAVE_FORMULA_CODIGO_ARTICULO_SESION);
  Result := TFormulaCodigoArticuloSesion.Normalizar(Result);
end;

procedure TdmComprasSesiones.ValidarCambioProveedorFormulaCodigo;
var
  oCampoProveedor: TField;
  sFormula: string;
begin
  oCampoProveedor := unqryTablaG.FindField('CODIGO_PRV_SES');
  if Assigned(oCampoProveedor) and
     (unqryTablaG.State = dsEdit) and
     (VarToStr(oCampoProveedor.OldValue) <>
      VarToStr(oCampoProveedor.NewValue)) and
     unqrySesionLin.Active and
     (not unqrySesionLin.IsEmpty) then
  begin
    sFormula := FormulaCodigoArticuloSesion;
    if TFormulaCodigoArticuloSesion.UsaModeloProveedor(sFormula) or
       TFormulaCodigoArticuloSesion.UsaCodigoProveedor(sFormula) then
      raise EInvalidOpException.Create(
        SErrorCambiarProveedorSesionConFormula);
  end;
end;

procedure TdmComprasSesiones.CargarValoresFormulaCodigoArticulo(
  out AValores: TValoresFormulaCodigoArticuloSesion);
begin
  AValores := Default(TValoresFormulaCodigoArticuloSesion);
  AValores.CodFamilia := Trim(unqrySesionLin.FieldByName(
    'CODIGO_FAM_SESLIN').AsString);
  AValores.ModeloProv := Trim(unqrySesionLin.FieldByName(
    'REF_PRV_SESLIN').AsString);
  AValores.CodProv := Trim(unqryTablaG.FieldByName(
    'CODIGO_PRV_SES').AsString);
end;

function TdmComprasSesiones.ClaveLineaCodigoArticulo: string;
begin
  Result :=
    unqrySesionLin.FieldByName(
      'SERIE_SES_SESLIN').AsString + #0 +
    unqrySesionLin.FieldByName(
      'NUMERO_SES_SESLIN').AsString + #0 +
    unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsString;
end;

function TdmComprasSesiones.HuellaGeneracionCodigoArticulo(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
begin
  Result :=
    TFormulaCodigoArticuloSesion.Normalizar(AFormula) + #0 +
    AValores.CodFamilia + #0 +
    AValores.ModeloProv + #0 +
    AValores.CodProv;
end;

function TdmComprasSesiones.EsMismaGeneracionCodigoArticulo(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion;
  const ACodigo: string): Boolean;
var
  Generacion: TGeneracionCodigoArticuloSesion;
begin
  Result := Assigned(FGeneracionesCodigoArticulo) and
    FGeneracionesCodigoArticulo.TryGetValue(
      ClaveLineaCodigoArticulo, Generacion);
  if Result then
    Result := SameText(Generacion.Codigo, ACodigo) and
      SameText(
        Generacion.Huella,
        HuellaGeneracionCodigoArticulo(AFormula, AValores));
end;

procedure TdmComprasSesiones.RegistrarGeneracionCodigoArticulo(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion;
  const ACodigo: string);
var
  Generacion: TGeneracionCodigoArticuloSesion;
begin
  if not Assigned(FGeneracionesCodigoArticulo) then
    FGeneracionesCodigoArticulo :=
      TDictionary<string, TGeneracionCodigoArticuloSesion>.Create;
  Generacion.Familia := AValores.CodFamilia;
  Generacion.Codigo := ACodigo;
  Generacion.Huella := HuellaGeneracionCodigoArticulo(
    AFormula, AValores);
  FGeneracionesCodigoArticulo.AddOrSetValue(
    ClaveLineaCodigoArticulo, Generacion);
end;

procedure TdmComprasSesiones.OlvidarGeneracionCodigoArticulo;
begin
  if Assigned(FGeneracionesCodigoArticulo) then
    FGeneracionesCodigoArticulo.Remove(
      ClaveLineaCodigoArticulo);
end;

procedure TdmComprasSesiones.ResolverContadorFormulaCodigoArticulo(
  const AFormula: string;
  var AValores: TValoresFormulaCodigoArticuloSesion);
var
  sCodigoFamiliaContador: string;
  UsaFamilia, UsaArticulo, DatosDisponibles: Boolean;
begin
  UsaFamilia := TFormulaCodigoArticuloSesion.UsaContadorFamilia(AFormula);
  UsaArticulo := TFormulaCodigoArticuloSesion.UsaContadorArticulo(AFormula);
  if UsaFamilia then
    AValores.ContadorFamilia := 'PENDIENTE';
  if UsaArticulo then
    AValores.CodArt := 'PENDIENTE';
  DatosDisponibles :=
    TFormulaCodigoArticuloSesion.PuedeEvaluar(AFormula, AValores);
  AValores.ContadorFamilia := '';
  AValores.CodArt := '';
  if DatosDisponibles then
  begin
    if UsaFamilia then
    begin
      if ResolverCodigoFamiliaConexion(ConexionDatos, AValores.CodFamilia,
        IdentidadSesion.Usuario, sCodigoFamiliaContador) then
        AValores.ContadorFamilia := Copy(sCodigoFamiliaContador,
          Length(AValores.CodFamilia) + 1, MaxInt)
      else
        raise EFormulaCodigoArticuloSesion.CreateFmt(
          SErrorFamiliaSesionSinContador, [AValores.CodFamilia]);
    end;
    if UsaArticulo then
      AValores.CodArt := ObtenerSiguienteContador(ConexionDatos, 'AR',
        IdentidadSesion.Usuario);
  end;
end;

procedure TdmComprasSesiones.AsignarCodigoArticuloLinea(
  const ACodigo: string);
begin
  if not (unqrySesionLin.State in [dsEdit, dsInsert]) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString := ACodigo;
end;

procedure TdmComprasSesiones.LimpiarCodigoArticuloLinea;
begin
  if not (unqrySesionLin.State in [dsEdit, dsInsert]) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').Clear;
  unqrySesionLin.FieldByName(
    'ACCION_DUPLICADO_SESLIN').Clear;
  unqrySesionLin.FieldByName(
    'CODIGO_ART_REUSAR_SESLIN').Clear;
  unqrySesionLin.FieldByName(
    'ESDUPLICADO_SESLIN').AsString := 'N';
  OlvidarGeneracionCodigoArticulo;
end;

function TdmComprasSesiones.EsFamiliaActiva(
  const ACodigo: string): Boolean;
var
  vNombre: Variant;
begin
  Result := False;
  if unqryFamilias.Active and (Trim(ACodigo) <> '') then
  begin
    vNombre := unqryFamilias.Lookup(
      'CODIGO_FAM_FAM',
      Trim(ACodigo),
      'NOMBRE_FAM_FAM');
    Result := not VarIsNull(vNombre);
  end;
end;

function TdmComprasSesiones.GenerarCodigoArticuloLineaActual(
  AReemplazarCodigo: Boolean): Boolean;
var
  Valores: TValoresFormulaCodigoArticuloSesion;
  sCodigoActual: string;
  sFormula: string;
  sGenerado: string;
begin
  Result := False;
  if unqrySesionLin.Active and
     (not unqrySesionLin.IsEmpty) then
  begin
    sCodigoActual := Trim(unqrySesionLin.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString);
    if AReemplazarCodigo or (sCodigoActual = '') then
    begin
      sGenerado := '';
      sFormula := FormulaCodigoArticuloSesion;
      CargarValoresFormulaCodigoArticulo(Valores);
      if AReemplazarCodigo and (sCodigoActual <> '') and
         EsMismaGeneracionCodigoArticulo(
           sFormula, Valores, sCodigoActual) then
        Result := True
      else
      begin
        sGenerado := GenerarCodigoArticuloDisponible(sFormula, Valores);
        if sGenerado <> '' then
        begin
          AsignarCodigoArticuloLinea(sGenerado);
          unqrySesionLin.FieldByName('ACCION_DUPLICADO_SESLIN').Clear;
          unqrySesionLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').Clear;
          unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
          if BuscarColisionCodigoArticulo(sGenerado) <> 0 then
            unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
          RegistrarGeneracionCodigoArticulo(sFormula, Valores, sGenerado);
          Result := True;
        end
        else if AReemplazarCodigo then
        begin
          LimpiarCodigoArticuloLinea;
          Result := True;
        end;
      end;
    end;
  end;
end;

// Consultar sin navegar por el dataset evita un Post dentro del editor.
// -1 identifica un articulo existente; un valor positivo, otra linea.
function TdmComprasSesiones.BuscarColisionCodigoArticulo(
  const ACodigo: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionDatos;
    oConsulta.SQL.Text :=
      'SELECT LINEA_SESLIN AS LINEA ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN <> :l ' +
      '   AND (TRIM(CODIGO_ART_TENTATIVO_SESLIN) = :c ' +
      '        OR TRIM(CODIGO_ART_REUSAR_SESLIN) = :c) ' +
      'UNION ALL ' +
      'SELECT -1 AS LINEA FROM fza_articulos WHERE CODIGO_ART_ART = :c ' +
      'LIMIT 1';
    oConsulta.ParamByName('s').AsString := unqrySesionLin.FieldByName(
      'SERIE_SES_SESLIN').AsString;
    oConsulta.ParamByName('n').AsString := unqrySesionLin.FieldByName(
      'NUMERO_SES_SESLIN').AsString;
    oConsulta.ParamByName('l').AsInteger := unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    oConsulta.ParamByName('c').AsString := ACodigo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('LINEA').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmComprasSesiones.GenerarCodigoArticuloDisponible(
  const AFormula: string;
  var AValores: TValoresFormulaCodigoArticuloSesion): string;
var
  bReintentar: Boolean;
begin
  repeat
    Result := '';
    ResolverContadorFormulaCodigoArticulo(AFormula, AValores);
    if TFormulaCodigoArticuloSesion.PuedeEvaluar(AFormula, AValores) then
      Result := TFormulaCodigoArticuloSesion.Evaluar(AFormula, AValores);
    // El Post sanea las barras: comprobar ya el codigo efectivo.
    Result := StringReplace(Result, '/', '-', [rfReplaceAll]);
    bReintentar := (Result <> '') and
      ((AValores.ContadorFamilia <> '') or (AValores.CodArt <> '')) and
      (BuscarColisionCodigoArticulo(Result) <> 0);
  until not bReintentar;
end;

function TdmComprasSesiones.
  GenerarCodigoArticuloTrasCambiarFamilia: Boolean;
var
  sFormula: string;
begin
  sFormula := FormulaCodigoArticuloSesion;
  Result := GenerarCodigoArticuloLineaActual(
    TFormulaCodigoArticuloSesion.UsaDatosFamilia(sFormula));
end;

function TdmComprasSesiones.EsArticuloPersistido(
  const ACodigo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := ConexionDatos;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ART_ART FROM fza_articulos ' +
      'WHERE CODIGO_ART_ART = :codigo LIMIT 1';
    Consulta.ParamByName('codigo').AsString := ACodigo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    Consulta.Free;
  end;
end;

function TdmComprasSesiones.
  GenerarCodigoArticuloTrasCambiarModelo: Boolean;
var
  Codigo: string;
  Generacion: TGeneracionCodigoArticuloSesion;
  Restaurar: Boolean;
begin
  Result := False;
  if unqrySesionLin.Active and not unqrySesionLin.IsEmpty then
  begin
    Codigo := Trim(unqrySesionLin.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString);
    if Codigo = '' then
      Result := GenerarCodigoArticuloLineaActual(False)
    else if EsArticuloPersistido(Codigo) then
    begin
      Restaurar := Assigned(FGeneracionesCodigoArticulo) and
        FGeneracionesCodigoArticulo.TryGetValue(
          ClaveLineaCodigoArticulo, Generacion);
      if Restaurar then
        Restaurar := SameText(Generacion.Familia,
          unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString) and
          (BuscarColisionCodigoArticulo(Generacion.Codigo) = 0);
      if Restaurar then
      begin
        AsignarCodigoArticuloLinea(Generacion.Codigo);
        unqrySesionLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').Clear;
        unqrySesionLin.FieldByName('ACCION_DUPLICADO_SESLIN').Clear;
        unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
        Result := True;
      end
      else
      begin
        OlvidarGeneracionCodigoArticulo;
        Result := GenerarCodigoArticuloLineaActual(True);
      end;
    end;
  end;
end;

procedure TdmComprasSesiones.LogSes(const ATexto: string);
begin
  if Assigned(ContextoSesion) then
    ContextoSesion.LogSesion(ATexto);
end;

procedure TdmComprasSesiones.AjustarCamposDerivadosCabecera;
const
  CAMPOS_DERIVADOS: array[0..9] of string = (
    'RAZON_SOCIAL_PRV_SES',
    'NOMBRE_PRV_SES',
    'TEMPORADA_SES',
    'FECHA_REALIZACION_SES',
    'FECHA_EFECTO_STOCK_SES',
    'TOTAL_PRENDAS_SES',
    'CANTIDAD_PEDIDA_SES',
    'TOTAL_LINEAS_SES',
    'CANTIDAD_RECIBIDA_SES',
    'CANTIDAD_PENDIENTE_RECEPCION_SES');
var
  i      : Integer;
  oCampo : TField;
begin
  for i := Low(CAMPOS_DERIVADOS) to High(CAMPOS_DERIVADOS) do
  begin
    oCampo := unqryTablaG.FindField(CAMPOS_DERIVADOS[i]);
    if oCampo <> nil then
    begin
      oCampo.Required := False;
      oCampo.ProviderFlags := [];
    end;
  end;
end;

procedure TdmComprasSesiones.ConfigurarSqlCabecera;
const
  CAMPOS_SES: array[0..81] of string = (
    'SERIE_SES',
    'NUMERO_SES',
    'FECHA_SES',
    'FECHA_TOPE_RECEPCION_SES',
    'ESTADO_SES',
    'CODIGO_EMP_SES',
    'CODIGO_PRV_SES',
    'REF_PRV_SES',
    'FORMA_PAGO_SES',
    'CODIGO_FAM_SES',
    'CODIGO_ALM_SES',
    'MONEDA_SES',
    'TIPO_IVA_SES',
    'CODIGO_IVA_SES',
    'ESVARIOS_TIPOS_IVA_SES',
    'ESVARIOS_TIPOS_VARIACION_SES',
    'PORCENTAJE_MARGEN_SES',
    'CODIGO_TAR_SES',
    'ESPRECIOS_SIN_IVA_SES',
    'ESREDONDEO_VENTA_SES',
    'MULTIPLO_REDONDEO_SES',
    'AJUSTE_FINAL_SES',
    'CODIGO_VAR_SES',
    'ID_VA_PIVOT_SES',
    'ID_AC_PIVOT_SES',
    'ID_VA_FILA_SES',
    'ID_AC_FILA_SES',
    'ESVAR_FIJA_SES',
    'PREFIJO_EAN_SES',
    'INSTANTE_MATERIALIZA_SES',
    'USUARIO_MATERIALIZA_SES',
    'ESGENERA_PEDIDO_SES',
    'ESGENERA_ALBARAN_SES',
    'ESFORMATO_DISTRIBUIDO_SES',
    'ESCOPIAR_DESCRIPCION_FAM_SES',
    fdescripcionblanco,
    'SERIE_PEDC_SES',
    'NUMERO_PEDC_SES',
    'SERIE_ALBC_SES',
    'NUMERO_ALBC_SES',
    'MENSAJE_ERROR_SES',
    'CONTADOR_LINEAS_SES',
    'COMENTARIOS_SES',
    'INSTANTE_ALTA',
    'USUARIO_ALTA',
    'INSTANTE_MODIF',
    'USUARIO_MODIF',
    'ESPRECIO_POR_SKU_SES',
    'ID_PV_TEMPORADA_SES',
    'ESIVA_RECARGO_COMPRAS_SES',
    'ESIVA_EXENTO_INTRACOMUNITARIO_SES',
    'PORCENTAJE_IVAN_SES',
    'TOTAL_BASEI_IVAN_SES',
    'TOTAL_IVAN_SES',
    'PORCENTAJE_REN_SES',
    'TOTAL_REN_SES',
    'PORCENTAJE_IVAR_SES',
    'TOTAL_BASEI_IVAR_SES',
    'TOTAL_IVAR_SES',
    'PORCENTAJE_RER_SES',
    'TOTAL_RER_SES',
    'PORCENTAJE_IVAS_SES',
    'TOTAL_BASEI_IVAS_SES',
    'TOTAL_IVAS_SES',
    'PORCENTAJE_RES_SES',
    'TOTAL_RES_SES',
    'PORCENTAJE_IVAE_SES',
    'TOTAL_BASEI_IVAE_SES',
    'TOTAL_IVAE_SES',
    'PORCENTAJE_REE_SES',
    'TOTAL_REE_SES',
    'PORCENTAJE_RETENCION_SES',
    'TOTAL_RETENCION_SES',
    'TOTAL_BRUTO_SES',
    'PORCENTAJE_DTO_COMERCIAL_SES',
    'TOTAL_DTO_COMERCIAL_SES',
    'PORCENTAJE_DTO_FINANCIERO_SES',
    'TOTAL_DTO_FINANCIERO_SES',
    'TOTAL_BASES_SES',
    'TOTAL_IMPUESTOS_SES',
    'TOTAL_SES',
    'TOTAL_LIQUIDO_SES');
var
  i: Integer;
  sCampos: string;
  sValores: string;
  sSet: string;

  procedure AgregarCampo(const ACampo: string);
  begin
    if sCampos = '' then
    begin
      sCampos := '  (' + ACampo;
      sValores := '  (:' + ACampo;
      sSet := '       ' + ACampo + ' = :' + ACampo;
    end
    else
    begin
      sCampos := sCampos + ',' + sLineBreak + '   ' + ACampo;
      sValores := sValores + ',' + sLineBreak + '   :' + ACampo;
      sSet := sSet + ',' + sLineBreak +
        '       ' + ACampo + ' = :' + ACampo;
    end;
  end;

begin
  sCampos := '';
  sValores := '';
  sSet := '';
  for i := Low(CAMPOS_SES) to High(CAMPOS_SES) do
    AgregarCampo(CAMPOS_SES[i]);
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_compras_sesiones ' + sLineBreak +
    sCampos + ')' + sLineBreak +
    'VALUES ' + sLineBreak +
    sValores + ')';
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_compras_sesiones ' + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_compras_sesiones ' + sLineBreak +
    '   SET ' + sLineBreak +
    sSet + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES';
  unqryTablaG.SQLLock.Text :=
    'SELECT * ' + sLineBreak +
    '  FROM fza_compras_sesiones ' + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES ' + sLineBreak +
    ' FOR UPDATE';
end;

function TdmComprasSesiones.SqlLecturaCabecera: string;
begin
  Result :=
    'SELECT s.*, ' +
    '       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES, ' +
    '       prv.NOMBRE_PRV AS NOMBRE_PRV_SES, ' +
    '       t.PV AS TEMPORADA_SES, ' +
    '       s.FECHA_SES AS FECHA_REALIZACION_SES, ' +
    '       COALESCE(alb.INSTANTE_MOVIMIENTO_ALBC, ' +
    '                CAST(alb.FECHA_ALBC AS datetime)) ' +
    '         AS FECHA_EFECTO_STOCK_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS TOTAL_PRENDAS_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS CANTIDAD_PEDIDA_SES, ' +
    '       COALESCE(r.TOTAL_LINEAS_SES, 0) AS TOTAL_LINEAS_SES, ' +
    '       CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '            THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '            ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END ' +
    '          AS CANTIDAD_RECIBIDA_SES, ' +
    '       GREATEST(COALESCE(r.TOTAL_PRENDAS_SES, 0) - ' +
    '         CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '              THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '              ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END, 0) ' +
    '          AS CANTIDAD_PENDIENTE_RECEPCION_SES ' +
    '  FROM fza_compras_sesiones s ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES ' +
    '  LEFT JOIN fza_propiedades_valores t ' +
    '    ON t.ID_PV_ARTPROP = s.ID_PV_TEMPORADA_SES ' +
    '   AND t.ID_PROP_PV = ''TEMPORADA'' ' +
    '  LEFT JOIN fza_albaranes_compra alb ' +
    '    ON alb.SERIE_ALBC = s.SERIE_ALBC_SES ' +
    '   AND alb.NUMERO_ALBC = s.NUMERO_ALBC_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN, ' +
    '                    COALESCE(SUM(l.TOTAL_UNIDADES_SESLIN), 0) ' +
    '                      AS TOTAL_PRENDAS_SES, ' +
    '                    COALESCE(SUM(l.TOTAL_LINEA_SESLIN), 0) ' +
    '                      AS TOTAL_LINEAS_SES ' +
    '               FROM fza_compras_sesiones_lineas l ' +
    '              GROUP BY l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN) r ' +
    '    ON r.SERIE_SES_SESLIN = s.SERIE_SES ' +
    '   AND r.NUMERO_SES_SESLIN = s.NUMERO_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_PEDC_PEDCLIN, l.NUMERO_PEDC_PEDCLIN, ' +
    '                    COALESCE(SUM(l.CANTIDAD_RECIBIDA_PEDCLIN), 0) ' +
    '                      AS CANTIDAD_RECIBIDA_PEDC ' +
    '               FROM fza_pedidos_compra_lineas l ' +
    '              GROUP BY l.SERIE_PEDC_PEDCLIN, ' +
    '                       l.NUMERO_PEDC_PEDCLIN) ped ' +
    '    ON ped.SERIE_PEDC_PEDCLIN = s.SERIE_PEDC_SES ' +
    '   AND ped.NUMERO_PEDC_PEDCLIN = s.NUMERO_PEDC_SES';
end;

procedure TdmComprasSesiones.ConfigurarLecturasCabecera;
begin
  unqryTablaG.SQL.Text := SqlLecturaCabecera +
    ' ORDER BY s.FECHA_SES DESC, s.NUMERO_SES DESC';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT s.*, ' +
    '       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES, ' +
    '       prv.NOMBRE_PRV AS NOMBRE_PRV_SES, ' +
    '       t.PV AS TEMPORADA_SES, ' +
    '       s.FECHA_SES AS FECHA_REALIZACION_SES, ' +
    '       COALESCE(alb.INSTANTE_MOVIMIENTO_ALBC, ' +
    '                CAST(alb.FECHA_ALBC AS datetime)) ' +
    '         AS FECHA_EFECTO_STOCK_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS TOTAL_PRENDAS_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS CANTIDAD_PEDIDA_SES, ' +
    '       COALESCE(r.TOTAL_LINEAS_SES, 0) AS TOTAL_LINEAS_SES, ' +
    '       CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '            THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '            ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END ' +
    '          AS CANTIDAD_RECIBIDA_SES, ' +
    '       GREATEST(COALESCE(r.TOTAL_PRENDAS_SES, 0) - ' +
    '         CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '              THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '              ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END, 0) ' +
    '          AS CANTIDAD_PENDIENTE_RECEPCION_SES ' +
    '  FROM fza_compras_sesiones s ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES ' +
    '  LEFT JOIN fza_propiedades_valores t ' +
    '    ON t.ID_PV_ARTPROP = s.ID_PV_TEMPORADA_SES ' +
    '   AND t.ID_PROP_PV = ''TEMPORADA'' ' +
    '  LEFT JOIN fza_albaranes_compra alb ' +
    '    ON alb.SERIE_ALBC = s.SERIE_ALBC_SES ' +
    '   AND alb.NUMERO_ALBC = s.NUMERO_ALBC_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN, ' +
    '                    COALESCE(SUM(l.TOTAL_UNIDADES_SESLIN), 0) ' +
    '                      AS TOTAL_PRENDAS_SES, ' +
    '                    COALESCE(SUM(l.TOTAL_LINEA_SESLIN), 0) ' +
    '                      AS TOTAL_LINEAS_SES ' +
    '               FROM fza_compras_sesiones_lineas l ' +
    '              GROUP BY l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN) r ' +
    '    ON r.SERIE_SES_SESLIN = s.SERIE_SES ' +
    '   AND r.NUMERO_SES_SESLIN = s.NUMERO_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_PEDC_PEDCLIN, l.NUMERO_PEDC_PEDCLIN, ' +
    '                    COALESCE(SUM(l.CANTIDAD_RECIBIDA_PEDCLIN), 0) ' +
    '                      AS CANTIDAD_RECIBIDA_PEDC ' +
    '               FROM fza_pedidos_compra_lineas l ' +
    '              GROUP BY l.SERIE_PEDC_PEDCLIN, ' +
    '                       l.NUMERO_PEDC_PEDCLIN) ped ' +
    '    ON ped.SERIE_PEDC_PEDCLIN = s.SERIE_PEDC_SES ' +
    '   AND ped.NUMERO_PEDC_PEDCLIN = s.NUMERO_PEDC_SES ' +
    ' WHERE s.SERIE_SES = :SERIE_SES ' +
    '   AND s.NUMERO_SES = :NUMERO_SES';
end;

procedure TdmComprasSesiones.ConectarConsultas;
begin
  unqrySesionLin.Connection         := ConexionPrincipal;
  unqrySesDocs.Connection           := ConexionPrincipal;
  unqrySesionFil.Connection         := ConexionPrincipal;
  unqrySesionFilAtr.Connection      := ConexionPrincipal;
  unqrySesionCel.Connection         := ConexionPrincipal;
  unqrySesionProps.Connection       := ConexionPrincipal;
  unqrySesionLinProps.Connection    := ConexionPrincipal;
  unqrySesionKits.Connection        := ConexionPrincipal;
  unqrySesionKitsDet.Connection     := ConexionPrincipal;
  unqryPreviewSkus.Connection       := ConexionPrincipal;
  unqryResumenAlmacen.Connection    := ConexionPrincipal;
  unqryLineaSkusPrecios.Connection  := ConexionPrincipal;
  unqryPrvFicha.Connection          := ConexionPrincipal;
  unqryPrvKits.Connection           := ConexionPrincipal;
  unqryPrvKitsDet.Connection        := ConexionPrincipal;
  unqryPrvKitsCombo.Connection      := ConexionPrincipal;
end;

procedure TdmComprasSesiones.ConfigurarConsultaKitsProveedor;
begin
  // Etiqueta del desplegable de kits: nombre + sistema de tallas +
  // primera y ultima talla CON cantidad>0, p.ej.
  //   "OPC A  Calzado Hombre EU 39-44  39(1)...44(2)".
  // El formato de cantidad recorta ceros/decimales sobrantes (1, 1.5).
  unqryPrvKitsCombo.SQL.Text :=
    'SELECT K.CODIGO_PRVKIT, ' +
    '  TRIM(CONCAT(K.NOMBRE_PRVKIT, ' +
    '    IFNULL(CONCAT('' '', AC.NOMBRE_AC), ''''), '' '', ' +
    '    IFNULL((SELECT CONCAT(D.VALOR_DESTINO_PRVKITD, ''('', ' +
    '              TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    '                CAST(D.CANTIDAD_PRVKITD AS CHAR))), '')'') ' +
    '         FROM fza_proveedores_kits_det D ' +
    '        WHERE D.CODIGO_PRV_PRVKITD = K.CODIGO_PRV_PRVKIT ' +
    '          AND D.CODIGO_PRVKIT_PRVKITD = K.CODIGO_PRVKIT ' +
    '          AND D.CANTIDAD_PRVKITD > 0 ' +
    '        ORDER BY D.ORDEN_PRVKITD, D.VALOR_DESTINO_PRVKITD LIMIT 1), ' +
    '''''), ' +
    '    ''...'', ' +
    '    IFNULL((SELECT CONCAT(D.VALOR_DESTINO_PRVKITD, ''('', ' +
    '              TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    '                CAST(D.CANTIDAD_PRVKITD AS CHAR))), '')'') ' +
    '         FROM fza_proveedores_kits_det D ' +
    '        WHERE D.CODIGO_PRV_PRVKITD = K.CODIGO_PRV_PRVKIT ' +
    '          AND D.CODIGO_PRVKIT_PRVKITD = K.CODIGO_PRVKIT ' +
    '          AND D.CANTIDAD_PRVKITD > 0 ' +
    '        ORDER BY D.ORDEN_PRVKITD DESC, ' +
    '                 D.VALOR_DESTINO_PRVKITD DESC LIMIT 1), ''''))) ' +
    '    AS ETIQUETA_KIT ' +
    '  FROM fza_proveedores_kits K ' +
    '  LEFT JOIN fza_atributos_conjuntos AC ON AC.ID_AC = ' +
    'K.ID_AC_TALLAS_PRVKIT ' +
    ' WHERE K.CODIGO_PRV_PRVKIT = :prv ' +
    ' ORDER BY K.ORDEN_PRVKIT, K.CODIGO_PRVKIT';
end;

procedure TdmComprasSesiones.ConectarCatalogos;
begin
  unqryProveedores.Connection       := ConexionPrincipal;
  unqryFamilias.Connection          := ConexionPrincipal;
  unqryVariaciones.Connection       := ConexionPrincipal;
  unqryVariacionesAtributos.Connection := ConexionPrincipal;
  unqryAtributosConjuntos.Connection := ConexionPrincipal;
  unqryAtributosValores.Connection  := ConexionPrincipal;
  unqryPropiedades.Connection       := ConexionPrincipal;
  unqryPropiedadesValores.Connection := ConexionPrincipal;
  unqryIvas.Connection              := ConexionPrincipal;
  unqryAlmacenes.Connection         := ConexionPrincipal;
  unqryTarifas.Connection           := ConexionPrincipal;
  unqryEmpresas.Connection          := ConexionPrincipal;
  unqryFormasPago.Connection        := ConexionPrincipal;
  unqryTemporadas.Connection        := ConexionPrincipal;
  unqryEmpresaSeries.Connection     := ConexionPrincipal;
  unqryArticuloExiste.Connection    := ConexionPrincipal;
  unstrdprcGetContadorSesion.Connection := ConexionPrincipal;
  unstrdprcValidarSesion.Connection := ConexionPrincipal;
  unqryCabSesionPrint.Connection    := ConexionPrincipal;
  unqryLinSesionPrint.Connection    := ConexionPrincipal;
  unqryGuiasSesionPrint.Connection  := ConexionPrincipal;
end;

procedure TdmComprasSesiones.AbrirCatalogos;
begin
  // unqryProveedores alimenta tanto el rotulo resuelto de la cabecera
  // (ActualizarLabelProveedor via Locate) como cbbProveedor, el combo de
  // busqueda incremental por nombre.
  unqryProveedores.Open;
  unqryFamilias.Open;
  unqryVariaciones.Open;
  unqryVariacionesAtributos.Open;
  unqryAtributosConjuntos.Open;
  unqryAtributosValores.Open;
  unqryPropiedades.Open;
  unqryPropiedadesValores.Open;
  unqryIvas.Open;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  unqryTarifas.Open;
  unqryEmpresas.Open;
  unqryFormasPago.Open;
  unqryTemporadas.Open;
end;

procedure TdmComprasSesiones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.BeforeDelete := AntesBorrarSesionBarras;
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  FGeneracionesCodigoArticulo :=
    TDictionary<string, TGeneracionCodigoArticuloSesion>.Create;
  ConfigurarSqlCabecera;
  ConfigurarLecturasCabecera;
  ConectarConsultas;
  ConfigurarConsultaKitsProveedor;
  ConectarCatalogos;
  AbrirCatalogos;
end;

procedure TdmComprasSesiones.AntesBorrarSesionBarras(DataSet: TDataSet);
begin
  IniciarBorradoTransaccional;
  try
    BorrarBarrasSesion(unqryTablaG.Connection,
      DataSet.FieldByName('SERIE_SES').AsString,
      DataSet.FieldByName('NUMERO_SES').AsString);
  except
    RevertirBorradoTransaccional;
    raise;
  end;
end;

procedure TdmComprasSesiones.RefrescarAlmacenes(
  const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenes.Active) or
     (not SameText(unqryAlmacenes.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenes.Close;
    unqryAlmacenes.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenes.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_SES', 'CODIGO_ALM_SES');
end;

procedure TdmComprasSesiones.ProponerSerieNuevaSesion;
begin
  // Una sesion guardada conserva su clave. En altas, la ubicacion puede
  // cambiar despues del prerrelleno con los datos del usuario.
  if unqryTablaG.Active and (unqryTablaG.State = dsInsert) then
    unqryTablaG.FieldByName('SERIE_SES').AsString := ObtenerSerieDefecto(
      unqryTablaG.Connection,
      unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString,
      'SE',
      unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString);
end;

procedure TdmComprasSesiones.unqryTablaGAfterInsert(DataSet: TDataSet);
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('FECHA_SES').AsDateTime := Date;
    FieldByName('ESTADO_SES').AsString  := 'BORRADOR';
    FieldByName('MONEDA_SES').AsString  := 'EUR';
    FieldByName('TIPO_IVA_SES').AsString := 'N';
    FieldByName('ESPRECIOS_SIN_IVA_SES').AsString := 'S';
    FieldByName('ESREDONDEO_VENTA_SES').AsString  := 'N';
    // NOT NULL en la tabla: hay que darles valor en cliente o Post falla con
    // 'Field XXX must have a value' antes de llegar al DEFAULT del servidor.
    FieldByName('MULTIPLO_REDONDEO_SES').AsFloat  := 0;
    FieldByName('AJUSTE_FINAL_SES').AsFloat       := 0;
    FieldByName('ESPRECIO_POR_SKU_SES').AsString  := 'N';
    FieldByName('ESVAR_FIJA_SES').AsString        := 'N';
    FieldByName('ESVARIOS_TIPOS_VARIACION_SES').AsString := 'N';
    if FindField('ESVARIOS_TIPOS_IVA_SES') <> nil then
      FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_SES') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString := 'N';
    FieldByName('ESGENERA_PEDIDO_SES').AsString   := 'N';
    FieldByName('ESGENERA_ALBARAN_SES').AsString  := 'N';
    if FindField('ESFORMATO_DISTRIBUIDO_SES') <> nil then
      FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString := 'N';
    if FindField('ESCOPIAR_DESCRIPCION_FAM_SES') <> nil then
      FieldByName('ESCOPIAR_DESCRIPCION_FAM_SES').AsString := 'S';
    FieldByName(fdescripcionblanco).AsString := 'N';
    // Contador de lineas: cada nueva linea hace +10 sobre este valor
    // (mismo patron que facturas/pedidos/albaranes). Arrancar en 0 => la
    // primera linea sera 10, la segunda 20, etc.
    FieldByName('CONTADOR_LINEAS_SES').AsInteger  := 0;
    // Prerelleno empresa/almacen del usuario logueado (igual que inventarios).
    // Sin esto el combo de serie queda vacio porque depende de CODIGO_EMP_SES,
    // y el usuario veria los combos en blanco al pulsar "+".
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_SES').AsString := UbicacionSesion.Empresa;
    if Trim(UbicacionSesion.Almacen) <> '' then
      FieldByName('CODIGO_ALM_SES').AsString := UbicacionSesion.Almacen;
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionDatos), unqryTablaG,
      'CODIGO_EMP_SES', 'ESIVA_RECARGO_COMPRAS_SES');
    AplicarPorcentajesIvaCompra(
      CrearLecturasImpuestos(ConexionDatos), unqryTablaG, 'SES');
    // Tipo de variación: con uno solo activo (la mayoría de instalaciones
    // solo tienen 'TC') se preselecciona; con varios se propone el de la
    // última sesión y el proveedor puede cambiarlo al elegirlo. Grabar
    // exige uno (FZ-ISSUE-420).
    FieldByName('CODIGO_VAR_SES').AsString := VariacionInicialSesion;
    // Temporada por defecto: el parámetro almacena el nombre visible
    // (ej. 'PRIM-VER 2026'); buscamos su ID numérico en el lookup
    var sTemp := ParametrosApp.GetString('appTemporadaDefecto');
    if (sTemp <> '') and unqryTemporadas.Active
       and unqryTemporadas.Locate('PV', sTemp, []) then
      FieldByName('ID_PV_TEMPORADA_SES').AsInteger :=
        unqryTemporadas.FieldByName('ID_PV_ARTPROP').AsInteger;
    // Tarifa sugerida desde parámetros de caja.
    if ParametrosCaja.TarifaDefecto <> '' then
      FieldByName('CODIGO_TAR_SES').AsString :=
        ParametrosCaja.TarifaDefecto;
  FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
  FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_SES').AsString);
  ProponerSerieNuevaSesion;
end;

procedure TdmComprasSesiones.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sSerie, sEmpresa, sNumero : string;
  oFldDist                  : TField;
begin
  AjustarCamposDerivadosCabecera;
  inherited;
  // Validaciones de datos del usuario: EValidacionBBDD para que el gestor
  // global muestre un aviso normal y no la pantalla de error (FZ-ISSUE-120).
  if Trim(DataSet.FieldByName('CODIGO_PRV_SES').AsString) = '' then
  begin
    // Deja el cursor en Proveedor para que el usuario lo elija.
    DataSet.FieldByName('CODIGO_PRV_SES').FocusControl;
    raise EValidacionBBDD.Create(SErrorProveedorSesionObligatorio);
  end;
  // Referencia/modelo del proveedor de la cabecera: sin barras (separador
  // de atributos del SKU), igual que en las lineas.
  QuitarBarraSkuCampo(DataSet, 'REF_PRV_SES');
  AsegurarVariacionSesion(DataSet);
  LogSes(Format(
    'DM.unqryTablaGBeforePost: state=%d, SERIE=%s NUMERO=%s CONTADOR_LINEAS=%d',
                [Ord(unqryTablaG.State),
                 unqryTablaG.FieldByName('SERIE_SES').AsString,
                 unqryTablaG.FieldByName('NUMERO_SES').AsString,
                 unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger]));
  // 'Formato distribuido' solo puede fijarse al crear la sesion. Una
  // vez que la sesion existe (State=dsEdit) el valor no puede cambiar:
  // ya hay celdas asignadas a un almacen y cambiar el modo dejaria
  // datos inconsistentes (modo distribuido vacio o cantidades simples
  // sin almacen). El usuario tiene que crear una sesion nueva si
  // quiere otro modo.
  oFldDist := DataSet.FindField('ESFORMATO_DISTRIBUIDO_SES');
  if (oFldDist <> nil) and (DataSet.State = dsEdit) and
     (VarToStr(oFldDist.OldValue) <> VarToStr(oFldDist.NewValue)) then
    raise EValidacionBBDD.Create(SErrorCambiarFormatoSesion);
  ValidarCambioProveedorFormulaCodigo;
  sNumero  := unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sSerie   := Trim(unqryTablaG.FieldByName('SERIE_SES').AsString);
  sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  // Validacion: para obtener numero hace falta serie y empresa.
  if (sNumero = '') or (sNumero = '0') then
  begin
    if sEmpresa = '' then
      raise EValidacionBBDD.Create(SErrorEmpresaSesionObligatoria);
    if sSerie = '' then
      raise EValidacionBBDD.Create(
        Format(SErrorSerieSesionObligatoria, [sEmpresa]));
    // Si el usuario teclea una serie que no existe en fza_empresas_series,
    // la creamos al vuelo para que el SP PRC_GET_NEXT_CONT_FACT_SERIE
    // pueda devolver el contador. Asi el usuario no tiene que ir antes
    // a Mantenimiento > Empresas > 4_Series.
    AsegurarSerieEnEmpresasSeries(sEmpresa, sSerie);
    GetCodigoAutoSesion;
    if unqryTablaG.FieldByName('NUMERO_SES').AsString = '' then
      raise Exception.Create(Format(SErrorContadorSesion,
                                    [sEmpresa, sSerie]));
  end;
  RefrescarTotalesSesion;
  PersistirTotalesSesion;
  unqryTablaG.FieldByName('USUARIO_MODIF').AsString  := IdentidadSesion.Usuario;
  unqryTablaG.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterInsert(DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqrySesionLin.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqrySesionLin.FindField(ANombre);
  end;
begin
  inherited;
  // Pedimos la siguiente LINEA al helper generico (inLibContadorLineas).
  // El helper hace UPDATE atomico sobre fza_compras_sesiones incrementando
  // CONTADOR_LINEAS_SES en +10 y devuelve el nuevo valor. La persistencia
  // del contador NO depende de que el usuario Postee la cabecera, por lo
  // que ya no hay riesgo de colision si despues Cancela el master con
  // lineas posteadas (caso clasico: Add+navegacion=detail.Post implicito,
  // y Cancelar master rollbackeaba CONTADOR en memoria pero la linea ya
  // estaba en BD; el siguiente Add reasignaba la misma LINEA).
  sSerie  := unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_SES').AsString;
  if FImportacionMasiva and
     (FProximaLineaImportacion <= FUltimaLineaImportacion) then
  begin
    iNuevaLinea := FProximaLineaImportacion;
    Inc(FProximaLineaImportacion, 10);
  end
  else
    iNuevaLinea := GetSiguienteLineaDoc(
      CrearContadorLineasDocumento(ConexionDatos), CONT_SESIONES,
      sSerie, sNumero);
  if iNuevaLinea = 0 then
  begin
    // Cabecera no localizada (caso raro: master aun no posteado, sin
    // SERIE/NUMERO). Fallback al patron antiguo CONTADOR+10 en memoria.
    iNuevaLinea :=
      unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger + 10;
    LogSes(Format(
      '  helper devolvio 0 (cabecera sin SERIE/NUMERO?), fallback LINEA=%d',
                  [iNuevaLinea]));
  end;
  LogSes(Format('DM.unqrySesionLinAfterInsert: nueva LINEA=%d', [iNuevaLinea]));

  // Sincronizar CONTADOR en memoria con el nuevo valor para que los demas
  // handlers que lo leen (LogSes, displays, etc.) vean el valor coherente.
  if not (unqryTablaG.State in [dsEdit, dsInsert]) then
  begin
    LogSes('  master estaba fuera de edit/insert, forzando master.Edit');
    unqryTablaG.Edit;
  end;
  unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger := iNuevaLinea;

  FieldByName('SERIE_SES_SESLIN').AsString  :=
      unqryTablaG.FieldByName('SERIE_SES').AsString;
    FieldByName('NUMERO_SES_SESLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_SES').AsString;
    FieldByName('LINEA_SESLIN').AsInteger     := iNuevaLinea;
    FieldByName('TIPO_LINEA_SESLIN').AsString := 'MATRIZ';
    FieldByName('CODIGO_VAR_SESLIN').AsString :=
      unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString;
    FieldByName('TIPO_ART_SESLIN').AsString   := 'ESTANDAR';
    if FindField('TIPO_IVA_SESLIN') <> nil then
      FieldByName('TIPO_IVA_SESLIN').AsString :=
        unqryTablaG.FieldByName('TIPO_IVA_SES').AsString;
    FieldByName('TIPO_CANTIDAD_SESLIN').AsString := 'Uds';
    FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
    // NOT NULL con DEFAULT en BBDD: hay que darles valor en cliente o Post
    // falla con 'Field XXX must have a value' antes de llegar al DEFAULT.
    FieldByName('ESTRAZABLE_SESLIN').AsString    := 'N';
    FieldByName('PRECIO_COMPRA_SESLIN').AsFloat  := 0;
    FieldByName('PORCENTAJE_DTO_SESLIN').AsFloat := 0;
    FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := 0;
    FieldByName('TOTAL_LINEA_SESLIN').AsFloat    := 0;
    // NOT NULL sin DEFAULT (debe rellenarlos el usuario): default a '' para
    // que Required pase y el usuario los rellene desde el grid.
    FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := '';
    FieldByName('DESCRIPCION_SESLIN').AsString          := '';
    FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    // Sistema de tallas por defecto del documento (ver FTallajeDefectoActual):
    // viene del proveedor al elegirlo, o del ultimo que el usuario eligio a
    // mano en una linea. Solo se propone; el usuario lo puede cambiar en la
    // linea igual que siempre.
  if (FTallajeDefectoActual > 0) and
     (FindField('ID_AC_PIVOT_SESLIN') <> nil) then
    FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := FTallajeDefectoActual;
end;

// Lo primero al confirmar una linea: dejar el SKU sin barras y
// descartar el hueco nuevo que el usuario no llego a rellenar.
procedure TdmComprasSesiones.PrepararLineaSesionParaPost(
  DataSet: TDataSet);
var
  bLineaVacia: Boolean;
begin
  LogSes(Format(
    'DM.unqrySesionLinBeforePost: state=%d, LINEA=%d, COD_TENT=%s, FAM=%s',
                [Ord(unqrySesionLin.State),
                 unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger,
                 unqrySesionLin.FieldByName(
                   'CODIGO_ART_TENTATIVO_SESLIN').AsString,
                 unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString]));
  // La barra es el separador de atributos del SKU: ni el codigo tecleado
  // ni el modelo del proveedor (entra en la formula del codigo) la llevan;
  // se cambia por guion, como hace el migrador.
  QuitarBarraSkuCampo(DataSet, 'CODIGO_ART_TENTATIVO_SESLIN');
  QuitarBarraSkuCampo(DataSet, 'REF_PRV_SESLIN');
  // Solo se descarta el placeholder nuevo completamente vacio. Las lineas
  // importadas pueden no tener codigo hasta que el usuario asigne familia;
  // deben poder postearse y navegarse sin que Cancel + Abort bloquee el grid.
  bLineaVacia :=
    (Trim(unqrySesionLin.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString) = '') and
    (Trim(unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString) = '') and
    (Trim(unqrySesionLin.FieldByName('REF_PRV_SESLIN').AsString) = '') and
    (Trim(unqrySesionLin.FieldByName('DESCRIPCION_SESLIN').AsString) = '') and
    (Trim(unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString) = '') and
    (unqrySesionLin.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat = 0) and
    (unqrySesionLin.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat = 0);
  if (not FPermitirLineasSinCodigoArticulo) and
     (unqrySesionLin.State = dsInsert) and bLineaVacia then
  begin
    LogSes('  linea sin articulo, Cancel diferido + Abort');
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqrySesionLin.Active and
           (unqrySesionLin.State in [dsEdit, dsInsert]) then
          unqrySesionLin.Cancel;
      end);
    Abort;
  end;
end;

// Codigo tentativo, familia, tipo de articulo, tipo de IVA y color
// del proveedor: todo lo que la linea deduce de si misma.
procedure TdmComprasSesiones.NormalizarClasificacionLineaSesion;
var
  sFamilia: string;
  sTecla: string;
begin
  sTecla := Trim(unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString);
  sFamilia := Trim(unqrySesionLin.FieldByName(
    'CODIGO_FAM_SESLIN').AsString);
  if (sTecla <> '') and (sFamilia = '') and
     EsFamiliaActiva(sTecla) then
  begin
    sFamilia := sTecla;
    unqrySesionLin.FieldByName(
      'CODIGO_FAM_SESLIN').AsString := sFamilia;
  end;
  // Sin formula evaluable la linea se graba sin codigo: ya se aviso al
  // elegir la familia y la materializacion rechaza lineas sin codigo.
  if sTecla = '' then
  begin
    try
      GenerarCodigoArticuloLineaActual(False);
    except
      on E: EFormulaCodigoArticuloSesion do
        LogSes('  linea sin codigo propuesto: ' + E.Message);
    end;
  end;
  // Una línea nueva sin colección admite unidades y crea un artículo
  // sin variación. Los servicios y kits conservan su clasificación.
  if (unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger = 0)
     and (unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString =
       'MATRIZ') then
  begin
    unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString := 'ESCALAR';
    // El tipo elegido se conserva hasta seleccionar su coleccion.
    // Sin coleccion la cantidad sigue siendo escalar.

  end;
  if (unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger > 0)
     and (Trim(unqrySesionLin.FieldByName(
       'CODIGO_VAR_SESLIN').AsString) = '') then
  begin
    if Trim(unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString) = '' then
      raise EValidacionBBDD.Create(SErrorVariacionSesionObligatoria);
    unqrySesionLin.FieldByName('CODIGO_VAR_SESLIN').AsString :=
      unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString;
  end;
  // Sincroniza TIPO_ART desde TIPO_LINEA
  if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'SERVICIO' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'SERVICIO'
  else if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'KIT' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'KIT'
  else
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'ESTANDAR';
  if (unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') = nil) or
     (UpperCase(Trim(unqryTablaG.FieldByName(
       'ESVARIOS_TIPOS_IVA_SES').AsString)) <> 'S') or
     (Trim(unqrySesionLin.FieldByName('TIPO_IVA_SESLIN').AsString) = '') then
    unqrySesionLin.FieldByName('TIPO_IVA_SESLIN').AsString :=
      unqryTablaG.FieldByName('TIPO_IVA_SES').AsString;
  // Saneo del color del proveedor al confirmar la linea: el usuario ve ya el
  // token real que ira al SKU (mayusculas, espacios->'-', simbolos prohibidos).
  // Misma regla que aplica el materializador (SanearColorSku) y la foto.
  if Trim(unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString) <> '' then
    unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString :=
      inLibComprasSesionesReglas.SanearColorSku(
        unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString);
end;

// La deteccion nunca decide REUSAR: esa eleccion pertenece al usuario.
procedure TdmComprasSesiones.MarcarDuplicadoLineaSesion;
var
  sTecla: string;
begin
  sTecla := Trim(unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString);
  if SameText(
       unqrySesionLin.FieldByName(
         'ACCION_DUPLICADO_SESLIN').AsString,
       'REUSAR') and
     (not SameText(
       unqrySesionLin.FieldByName(
         'CODIGO_ART_REUSAR_SESLIN').AsString,
       sTecla)) then
  begin
    unqrySesionLin.FieldByName(
      'ACCION_DUPLICADO_SESLIN').Clear;
    unqrySesionLin.FieldByName(
      'CODIGO_ART_REUSAR_SESLIN').Clear;
  end;
  if sTecla <> '' then
  begin
    if BuscarColisionCodigoArticulo(sTecla) <> 0 then
      unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString :=
        'S'
    else
      unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString :=
        'N';
  end;
end;

procedure TdmComprasSesiones.unqrySesionLinBeforePost(DataSet: TDataSet);
var
  LineaRepetida: Integer;
begin
  inherited;
  CalcularPrecioNetoCompra(0,
    DataSet.FieldByName('PORCENTAJE_DTO_SESLIN').AsFloat);
  PrepararLineaSesionParaPost(DataSet);
  NormalizarClasificacionLineaSesion;
  MarcarDuplicadoLineaSesion;
  LineaRepetida := BuscarColorRepetidoSesion(ConexionPrincipal,
    unqryTablaG.FieldByName('SERIE_SES').AsString,
    unqryTablaG.FieldByName('NUMERO_SES').AsString, DataSet);
  if LineaRepetida > 0 then
    raise EValidacionBBDD.Create(Format(
      SErrorColorRepetidoSesion, [LineaRepetida]));
  if not FImportacionMasiva then
    CalcularTotalesLineaActual;
  unqrySesionLin.FieldByName('USUARIO_MODIF').AsString :=
    IdentidadSesion.Usuario;
  unqrySesionLin.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterPost(DataSet: TDataSet);
begin
  inherited;
  LogSes(Format('DM.unqrySesionLinAfterPost: LINEA=%d posteada',
                [unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
  if not FImportacionMasiva then
    RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterDelete(DataSet: TDataSet);
begin
  inherited;
  if Assigned(FGeneracionesCodigoArticulo) then
    FGeneracionesCodigoArticulo.Clear;
  LogSes('DM.unqrySesionLinAfterDelete');
  // Las celdas y filas se borran en cascada por la app (no por FK).
  RefrescarTotalesSesion;
end;

function TdmComprasSesiones.TrazabilidadLineaActual: TTrazabilidadAlta;
var
  sFamilia: string;
  oConsulta: TUniQuery;
begin
  sFamilia := Trim(unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString);
  if sFamilia = '' then
    sFamilia := unqryTablaG.FieldByName('CODIGO_FAM_SES').AsString;
  Result := LeerTrazabilidadFamilia(ConexionPrincipal, sFamilia);
  if (Result.Modo = mtNinguna) and SameText(unqrySesionLin.FieldByName(
    'ESTRAZABLE_SESLIN').AsString, 'S') then
    Result.Modo := mtLote;
  if SameText(unqrySesionLin.FieldByName(
    'ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text :=
        'SELECT TIPO_TRAZABILIDAD_ART, ESCADUCIDAD_ART ' +
        'FROM fza_articulos WHERE CODIGO_ART_ART = :ARTICULO';
      oConsulta.ParamByName('ARTICULO').AsString :=
        unqrySesionLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString;
      oConsulta.Open;
      if not oConsulta.Eof then
      begin
        Result.Modo := ModoDesdeCadena(
          oConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString);
        Result.ExigeCaducidad := SameText(
          oConsulta.FieldByName('ESCADUCIDAD_ART').AsString, 'S');
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmComprasSesiones.MarcarArticuloPorLotes(AActivar: Boolean);
var
  oConsulta: TUniQuery;
  sArticulo: string;
  iLinea: Integer;
  bTransaccionPropia: Boolean;
begin
  sArticulo := Trim(unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString);
  if (sArticulo <> '') and not EsArticuloPersistido(sArticulo) then
  begin
    iLinea := unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    bTransaccionPropia := not ConexionDatos.InTransaction;
    if bTransaccionPropia then
      ConexionDatos.StartTransaction;
    try
      unqrySesionCel.CheckBrowseMode;
      unqrySesionLin.CheckBrowseMode;
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := ConexionDatos;
        oConsulta.SQL.Text :=
          'UPDATE fza_compras_sesiones_lineas ' +
          'SET ESTRAZABLE_SESLIN = :TRAZABLE ' +
          'WHERE SERIE_SES_SESLIN = :SERIE ' +
          'AND NUMERO_SES_SESLIN = :NUMERO ' +
          'AND (CODIGO_ART_TENTATIVO_SESLIN = :ARTICULO ' +
          'OR CODIGO_ART_REUSAR_SESLIN = :ARTICULO)';
        if AActivar then
          oConsulta.ParamByName('TRAZABLE').AsString := 'S'
        else
          oConsulta.ParamByName('TRAZABLE').AsString := 'N';
        oConsulta.ParamByName('SERIE').Value :=
          unqrySesionLin.FieldByName('SERIE_SES_SESLIN').Value;
        oConsulta.ParamByName('NUMERO').Value :=
          unqrySesionLin.FieldByName('NUMERO_SES_SESLIN').Value;
        oConsulta.ParamByName('ARTICULO').AsString := sArticulo;
        oConsulta.ExecSQL;
      finally
        FreeAndNil(oConsulta);
      end;
      if bTransaccionPropia then
        ConexionDatos.Commit;
    except
      if bTransaccionPropia and ConexionDatos.InTransaction then
        ConexionDatos.Rollback;
      raise;
    end;
    unqrySesionLin.Refresh;
    unqrySesionLin.Locate('LINEA_SESLIN', iLinea, []);
  end;
end;

procedure TdmComprasSesiones.RefrescarCeldasLineaActual;
begin
  if unqrySesionCel.State in dsEditModes then
    unqrySesionCel.Post;
  unqrySesionCel.Close;
  if unqrySesionLin.Active and not unqrySesionLin.IsEmpty then
  begin
    unqrySesionCel.ParamByName('SERIE_SES_SESLIN').Value :=
      unqrySesionLin.FieldByName('SERIE_SES_SESLIN').Value;
    unqrySesionCel.ParamByName('NUMERO_SES_SESLIN').Value :=
      unqrySesionLin.FieldByName('NUMERO_SES_SESLIN').Value;
    unqrySesionCel.ParamByName('LINEA_SESLIN').Value :=
      unqrySesionLin.FieldByName('LINEA_SESLIN').Value;
    unqrySesionCel.Open;
  end;
end;

procedure TdmComprasSesiones.unqrySesionCelAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesLineaActual;
  RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.CalcularTotalesLineaActual;
var
  q         : TUniQuery;
  rTotalUds : Double;
  rImporte  : Double;
  rPrecio   : Double;
  iLinea    : Integer;
  sSerie    : string;
  sNumero   : string;
begin
  // Recalcula TOTAL_UNIDADES_SESLIN y TOTAL_LINEA_SESLIN para la línea
  // actualmente en edición sumando las celdas de fza_compras_sesiones_celdas.
  // Se invoca desde unqrySesionLinBeforePost para que los totales se
  // persistan correctamente cuando el usuario graba la sesión.
  if not unqrySesionLin.IsEmpty then
  begin
  iLinea  := unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  sSerie  := unqrySesionLin.FieldByName('SERIE_SES_SESLIN').AsString;
  sNumero := unqrySesionLin.FieldByName('NUMERO_SES_SESLIN').AsString;
  if (iLinea > 0) and (sSerie <> '') and (sNumero <> '') then
  begin
  rPrecio := unqrySesionLin.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionDatos;
    // FZ-ISSUE-638: cada talla con coste propio suma a su precio.
    q.SQL.Text :=
      'SELECT COALESCE(SUM(C.CANTIDAD_SESCEL), 0) AS TOTAL, ' +
      '       COALESCE(SUM(C.CANTIDAD_SESCEL * ' +
      '         COALESCE(P.PRECIO_COMPRA_SESLINSKU, :pre)), 0) AS IMPORTE ' +
      '  FROM fza_compras_sesiones_celdas C ' +
      '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
      '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
      '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
      '   AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
      '   AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
      '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
      ' WHERE C.SERIE_SES_SESCEL = :s AND C.NUMERO_SES_SESCEL = :n ' +
      '   AND C.LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  := sSerie;
    q.ParamByName('n').AsString  := sNumero;
    q.ParamByName('l').AsInteger := iLinea;
    q.ParamByName('pre').AsFloat := rPrecio;
    q.Open;
    rTotalUds := q.FieldByName('TOTAL').AsFloat;
    rImporte := CalcularPrecioNetoCompra(
      q.FieldByName('IMPORTE').AsFloat,
      unqrySesionLin.FieldByName('PORCENTAJE_DTO_SESLIN').AsFloat);
  finally
    FreeAndNil(q);
  end;

  if not (unqrySesionLin.State in [dsInsert, dsEdit]) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := rTotalUds;
  unqrySesionLin.FieldByName('TOTAL_LINEA_SESLIN').AsFloat    := rImporte;
  end;
  end;
end;

procedure TdmComprasSesiones.AsegurarSerieEnEmpresasSeries(
  const AEmpresa, ASerie: string);
var
  q          : TUniQuery;
  sCodigoSer : string;
begin
  // Si el usuario teclea una serie nueva (no existe en fza_empresas_series
  // para esa empresa+TIPO_DOC='SE'), la creamos al vuelo. El campo
  // CODIGO_SERIE_EMPSER es un contador propio que se genera con
  // PRC_GET_NEXT_CONT('ES') -- mismo patron que UniDataEmpresas.
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionDatos;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM vi_empresas_series ' +
      ' WHERE TIPO_DOC_EMPSER = ''SE'' ' +
      '   AND CODIGO_EMP_EMPSER = :emp ' +
      '   AND EMPSER = :ser';
    q.ParamByName('emp').AsString := AEmpresa;
    q.ParamByName('ser').AsString := ASerie;
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
    begin
      q.Close;
      // PK de la nueva fila: contador 'ES' (mismo que pantalla Empresas)
      sCodigoSer := ObtenerSiguienteContador(
        ConexionDatos,
        'ES',
        IdentidadSesion.Usuario);
      if Trim(sCodigoSer) = '' then
        raise Exception.Create(SErrorCodigoSerieEmpresa);
      q.SQL.Text :=
        'INSERT INTO fza_empresas_series ' +
        '  (CODIGO_SERIE_EMPSER, CODIGO_EMP_EMPSER, EMPSER, ' +
        'TIPO_DOC_EMPSER, SUBTIPO_EMPSER, FECHA_DESDE_EMPSER, ' +
        'FECHA_HASTA_EMPSER, INSTANTE_ALTA, USUARIO_ALTA, ' +
        'INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:cod, :emp, :ser, ''SE'', ''NORMAL'', CURDATE(), ' +
        'NULL, NOW(), :u, NOW(), :u)';
      q.ParamByName('cod').AsString := sCodigoSer;
      q.ParamByName('emp').AsString := AEmpresa;
      q.ParamByName('ser').AsString := ASerie;
      q.ParamByName('u').AsString   := IdentidadSesion.Usuario;
      q.ExecSQL;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmComprasSesiones.GetCodigoAutoSesion;
var
  sSerie, sEmpresa : string;
begin
  // Usa PRC_GET_NEXT_CONT_FACT_SERIE (el mismo que facturas/inventarios)
  // para obtener el siguiente numero por (TIPO_DOC, EMPRESA, SERIE).
  // La serie viene de la cabecera (combo alimentado por fza_empresas_series
  // filtrado por TIPO_DOC_EMPSER='SE'). Si por lo que sea esta vacia,
  // dejamos NUMERO_SES sin asignar y la grabacion fallara con un mensaje
  // claro de "elige una serie primero".
  sSerie   := Trim(unqryTablaG.FieldByName('SERIE_SES').AsString);
  sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  if (sSerie <> '') and (sEmpresa <> '') then
  begin
  unstrdprcGetContadorSesion.Params.Clear;
  unstrdprcGetContadorSesion.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorSesion.Params.CreateParam(
    ftString, 'pTipoDoc', ptInput);
  unstrdprcGetContadorSesion.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorSesion.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorSesion.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorSesion.ParamByName('pserie').AsString := sSerie;
  unstrdprcGetContadorSesion.ParamByName('pTipoDoc').AsString := 'SE';
  unstrdprcGetContadorSesion.ParamByName(
    'pEMPRESA_CONTADOR').AsString := sEmpresa;
  unstrdprcGetContadorSesion.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorSesion.ExecProc;
  unqryTablaG.FieldByName('NUMERO_SES').AsString :=
    unstrdprcGetContadorSesion.ParamByName('pcont').AsString;
  end;
end;

procedure TdmComprasSesiones.ChequearDuplicado(const ACodigoArt: string;
  out AExiste: Boolean; out ADescripcion: string);
begin
  AExiste      := False;
  ADescripcion := '';
  unqryArticuloExiste.Close;
  unqryArticuloExiste.SQL.Text :=
    'SELECT CODIGO_ART_ART, DESCRIPCION_ART ' +
    '  FROM fza_articulos ' +
    ' WHERE CODIGO_ART_ART = :p';
  unqryArticuloExiste.ParamByName('p').AsString := ACodigoArt;
  unqryArticuloExiste.Open;
  try
    if not unqryArticuloExiste.IsEmpty then
    begin
      AExiste      := True;
      ADescripcion :=
        unqryArticuloExiste.FieldByName('DESCRIPCION_ART').AsString;
    end;
  finally
    unqryArticuloExiste.Close;
  end;
end;

procedure TdmComprasSesiones.RefrescarTotalesSesion;
var
  EstadoInicial: TDataSetState;
  sCampoTipoIvaLinea: string;
begin
  if Assigned(unqryTablaG) and unqryTablaG.Active and
     Assigned(unqrySesionLin) and unqrySesionLin.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    EstadoInicial := unqryTablaG.State;
    sCampoTipoIvaLinea := '';
    if (unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) and
       (UpperCase(Trim(unqryTablaG.FieldByName(
         'ESVARIOS_TIPOS_IVA_SES').AsString)) = 'S') then
      sCampoTipoIvaLinea := 'TIPO_IVA_SESLIN';
    CalcularTotalesDocumentoCompra(
      CrearLecturasImpuestos(ConexionDatos), unqryTablaG,
      unqrySesionLin, 'SES', 'TOTAL_LINEA_SESLIN',
      sCampoTipoIvaLinea, 'PORCENTAJE_IVA_SESLIN');
    if EstadoInicial <> dsInsert then
      PersistirTotalesSesion;
    if EstadoInicial = dsBrowse then
    begin
      if unqryTablaG.State = dsEdit then
      begin
        unqryTablaG.Cancel;
        unqryTablaG.Refresh;
      end;
    end;
  end;
end;

procedure TdmComprasSesiones.PersistirTotalesSesion;
const
  CAMPOS_TOTALES: array[0..31] of string = (
    'CODIGO_IVA_SES',
    'PORCENTAJE_IVAN_SES', 'TOTAL_BASEI_IVAN_SES', 'TOTAL_IVAN_SES',
    'PORCENTAJE_REN_SES', 'TOTAL_REN_SES',
    'PORCENTAJE_IVAR_SES', 'TOTAL_BASEI_IVAR_SES', 'TOTAL_IVAR_SES',
    'PORCENTAJE_RER_SES', 'TOTAL_RER_SES',
    'PORCENTAJE_IVAS_SES', 'TOTAL_BASEI_IVAS_SES', 'TOTAL_IVAS_SES',
    'PORCENTAJE_RES_SES', 'TOTAL_RES_SES',
    'PORCENTAJE_IVAE_SES', 'TOTAL_BASEI_IVAE_SES', 'TOTAL_IVAE_SES',
    'PORCENTAJE_REE_SES', 'TOTAL_REE_SES',
    'PORCENTAJE_RETENCION_SES', 'TOTAL_RETENCION_SES',
    'TOTAL_BRUTO_SES',
    'PORCENTAJE_DTO_COMERCIAL_SES', 'TOTAL_DTO_COMERCIAL_SES',
    'PORCENTAJE_DTO_FINANCIERO_SES', 'TOTAL_DTO_FINANCIERO_SES',
    'TOTAL_BASES_SES', 'TOTAL_IMPUESTOS_SES',
    'TOTAL_SES', 'TOTAL_LIQUIDO_SES');
var
  q       : TUniQuery;
  oCampo  : TField;
  sCampo  : string;
  sSql    : string;
  iCampos : Integer;
begin
  if (unqryTablaG.State <> dsInsert) and
     (Trim(unqryTablaG.FieldByName('SERIE_SES').AsString) <> '') and
     (Trim(unqryTablaG.FieldByName('NUMERO_SES').AsString) <> '') then
  begin
    sSql := 'UPDATE fza_compras_sesiones SET ';
    iCampos := 0;
    for sCampo in CAMPOS_TOTALES do
    begin
      if unqryTablaG.FindField(sCampo) <> nil then
      begin
        if iCampos > 0 then
          sSql := sSql + ', ';
        sSql := sSql + '`' + sCampo + '` = :' + sCampo;
        Inc(iCampos);
      end;
    end;
    if iCampos > 0 then
    begin
      sSql := sSql +
        ' WHERE `SERIE_SES` = :SERIE AND `NUMERO_SES` = :NUMERO';
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionDatos;
        q.SQL.Text := sSql;
        for sCampo in CAMPOS_TOTALES do
        begin
          oCampo := unqryTablaG.FindField(sCampo);
          if oCampo <> nil then
            q.ParamByName(sCampo).Value := oCampo.Value;
        end;
        q.ParamByName('SERIE').AsString :=
          unqryTablaG.FieldByName('SERIE_SES').AsString;
        q.ParamByName('NUMERO').AsString :=
          unqryTablaG.FieldByName('NUMERO_SES').AsString;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

function TdmComprasSesiones.DetectarConflictoConcurrencia: Boolean;
var
  uxTmp: TUniQuery;
  dt   : TDateTime;
begin
  // Compara INSTANTE_MODIF actual del registro en BBDD contra el cargado.
  Result := False;
  uxTmp  := TUniQuery.Create(nil);
  try
    uxTmp.Connection := ConexionDatos;
    uxTmp.SQL.Text :=
      'SELECT INSTANTE_MODIF FROM fza_compras_sesiones ' +
      'WHERE SERIE_SES = :s AND NUMERO_SES = :n';
    uxTmp.ParamByName('s').AsString :=
      unqryTablaG.FieldByName('SERIE_SES').AsString;
    uxTmp.ParamByName('n').AsString :=
      unqryTablaG.FieldByName('NUMERO_SES').AsString;
    uxTmp.Open;
    if not uxTmp.IsEmpty then
    begin
      dt := uxTmp.FieldByName('INSTANTE_MODIF').AsDateTime;
      Result := (dt > FInstanteCargaSesion);
    end;
  finally
    FreeAndNil(uxTmp);
  end;
end;

procedure TdmComprasSesiones.AplicarKitAFila(const AIdKit: string;
                                             const ALineaID: Integer;
                                             const AIdFila: Integer);
begin
  // Lee fza_compras_sesiones_kits_det del kit indicado y vuelca cantidades
  // sobre la fila ALineaID/AIdFila buscando la columna del eje pivot que
  // case con VALOR_DESTINO_SESKITD. Implementación detallada en
  // inLibComprasSesiones (capa visual de matriz).
end;

procedure TdmComprasSesiones.AplicarKitATodasFilas(const AIdKit: string;
                                                   const ALineaID: Integer);
begin
  // Itera todas las filas de la línea y llama AplicarKitAFila.
end;

procedure TdmComprasSesiones.ReconstruirFilasLinea(const ALineaID: Integer);
begin
  // Cuando cambia ID_AC_FILA_SESLIN (conjunto de colores, p.ej.):
  //   - Borra filas que ya no aplican.
  //   - Inserta filas para valores nuevos del conjunto.
  //   - Borra celdas huérfanas.
end;

function TdmComprasSesiones.VariacionesActivas: Integer;
begin
  Result := 0;
  if unqryVariaciones.Active then
    Result := unqryVariaciones.RecordCount;
end;

// Única variación activa o, con varias, la de la última sesión grabada.
function TdmComprasSesiones.VariacionInicialSesion: string;
begin
  Result := '';
  if VariacionesActivas = 1 then
  begin
    unqryVariaciones.First;
    Result := unqryVariaciones.FieldByName('CODIGO_VAR').AsString;
  end
  else if VariacionesActivas > 1 then
    Result := VariacionPropuestaSesionUniDAC(ConexionDatos, 0, '');
end;

// La cabecera propone el tipo; cada línea puede elegir uno diferente.
procedure TdmComprasSesiones.AsegurarVariacionSesion(ADataSet: TDataSet);
begin
  if (Trim(ADataSet.FieldByName('CODIGO_VAR_SES').AsString) = '') and
     (VariacionesActivas = 1) then
    ADataSet.FieldByName('CODIGO_VAR_SES').AsString :=
      VariacionInicialSesion;
end;

procedure TdmComprasSesiones.ConfigurarVariacionLinea(
  const ACodigo: string);
var
  oConsulta: TUniQuery;
begin
  if not (unqrySesionLin.State in dsEditModes) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName('PESTANA_TEXTO_SESLIN').Clear;
  if ACodigo = '' then
  begin
    unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString := 'ESCALAR';
    unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').Clear;
    unqrySesionLin.FieldByName('ID_VA_PIVOT_SESLIN').Clear;
    unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').Clear;
    unqrySesionLin.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
  end
  else
  begin
    unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString := 'MATRIZ';
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionDatos;
      oConsulta.SQL.Text :=
        'SELECT ID_ATB_VA FROM VI_VARIACIONES_EJES ' +
        'WHERE ID_VAR_VA = :VARIACION AND EJE_VA = ''P''';
      oConsulta.ParamByName('VARIACION').AsString := ACodigo;
      oConsulta.Open;
      unqrySesionLin.FieldByName('ID_VA_PIVOT_SESLIN').AsString :=
        oConsulta.FieldByName('ID_ATB_VA').AsString;
    finally
      oConsulta.Free;
    end;
    unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').Clear;
  end;
  unqrySesionLin.FieldByName('CODIGO_VAR_SESLIN').AsString := ACodigo;
end;

procedure TdmComprasSesiones.ProponerVariacionProveedor(
  const ACodigoProveedor: string);
var
  sPropuesta: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) and
     (VariacionesActivas > 1) and
     unqrySesionLin.Active and unqrySesionLin.IsEmpty then
  begin
    sPropuesta := VariacionPropuestaSesionUniDAC(
      ConexionDatos, FTallajeDefectoActual, ACodigoProveedor);
    if (sPropuesta <> '') and
       (sPropuesta <> unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString)
    then
      unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString := sPropuesta;
  end;
end;

procedure TdmComprasSesiones.RecargarProveedorSesion(const ACodigoPrv: string);
begin
  // Reset del tallaje-defecto-del-documento: se recalcula desde el
  // proveedor (CopiarDefectosProveedor) solo cuando el usuario ESTA
  // cambiando el proveedor de la cabecera; al navegar a otra sesion (o
  // dejar el proveedor en blanco) no debe arrastrarse el de la sesion
  // anterior.
  FTallajeDefectoActual := 0;
  // Ficha + kits del proveedor para la pestaña Proveedor. El detalle de
  // kits es master/detail de unqryPrvKits y sigue solo al master.
  unqryPrvFicha.Close;
  unqryPrvKitsDet.Close;
  unqryPrvKits.Close;
  unqryPrvKitsCombo.Close;
  if Trim(ACodigoPrv) <> '' then
  begin
    unqryPrvFicha.ParamByName('prv').AsString     := ACodigoPrv;
    unqryPrvKits.ParamByName('prv').AsString       := ACodigoPrv;
    unqryPrvKitsCombo.ParamByName('prv').AsString  := ACodigoPrv;
    unqryPrvFicha.Open;
    unqryPrvKits.Open;
    unqryPrvKitsCombo.Open;
    if not unqryPrvKitsDet.Active then
      unqryPrvKitsDet.Open;
  end;
end;

procedure TdmComprasSesiones.HeredarDescripcionProveedor;
var
  sValor: string;
begin
  sValor := 'N';
  if unqryPrvFicha.Active and (not unqryPrvFicha.IsEmpty) and
     SameText(unqryPrvFicha.FieldByName(
       'ESDESCRIPCION_BLANCO_PRV').AsString, 'S') then
    sValor := 'S';
  if not (unqryTablaG.State in [dsInsert, dsEdit]) then
    unqryTablaG.Edit;
  unqryTablaG.FieldByName(fdescripcionblanco).AsString := sValor;
end;

function TdmComprasSesiones.DejarDescripcionEnBlanco: Boolean;
begin
  Result := unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
    SameText(unqryTablaG.FieldByName(
      fdescripcionblanco).AsString, 'S');
end;

function TdmComprasSesiones.DescripcionParaLinea(
  const ADescripcion: string): string;
begin
  if DejarDescripcionEnBlanco then
    Result := ''
  else
    Result := ADescripcion;
end;

procedure TdmComprasSesiones.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabSesionPrint.Close;
  unqryCabSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryCabSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryCabSesionPrint.Open;

  unqryLinSesionPrint.Close;
  unqryLinSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryLinSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryLinSesionPrint.Open;

  unqryGuiasSesionPrint.Close;
  unqryGuiasSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryGuiasSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryGuiasSesionPrint.Open;
end;

initialization
  RegistrarDataModule(TdmComprasSesiones);
end.

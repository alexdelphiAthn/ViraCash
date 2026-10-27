{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionMaterializacion               }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cablea el caso de uso de materializacion de una sesion de compra con      }
{    sus modales y datasets. Recibe un entorno explicito: nunca el             }
{    formulario completo ni un contexto general de repositorios.               }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionMaterializacion;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  Uni,
  inLibComprasSesiones,
  inLibComprasSesionesAplicacionIntf;

type
  // Piezas minimas que necesita el cableado. Cada campo es una
  // capacidad concreta; no hay bolsa de servicios ni referencia visual
  // a la pantalla salvo el propietario de los modales.
  TEntornoMaterializacionCompraSesion = record
    Propietario: TComponent;
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Celdas: TDataSet;
    Documentos: TDataSet;
    FuenteAlmacenes: TDataSource;
    FuenteTarifas: TDataSource;
    FuenteTemporadas: TDataSource;
    Registrar: TProc<string>;
    RefrescarFotos: TProc;
    GuardarPropiedades: TProc;
  end;

function CrearAplicacionMaterializacionCompraSesionVcl(
  const AEntorno: TEntornoMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;

implementation

uses
  inLibMensajesVcl,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  inLibComprasSesionesAplicacion,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesCreacionDataSet,
  inLibComprasSesionesIntf,
  inLibMsgCompras,
  inLibShowMto,
  UniDataValoresAutomaticosRepositorio,
  inMtoComprasSesionesMaterializacionVcl,
  inMtoModalCrearAlbaranSesion,
  inMtoModalDocsCreados,
  inMtoModalIncidencias,
  inMtoModalPreciosTarifaSesion,
  inLibComprasSesionesPreciosTalla,
  UniDataComprasSesionesTarifas,
  inLibMsgOpcionesDocumento,
  System.UITypes,
  System.Variants;

resourcestring
  SMensajeErrorMaterializacionSesionCompra = '[MATERIALIZAR] %s';

// Los callbacks se construyen por bloques para que ninguno supere el
// tamano admitido y para que se lean las cuatro responsabilidades:
// lecturas, escrituras, avisos y dialogos.
// El entorno viaja POR VALOR a proposito: los metodos anonimos capturan
// el parametro y una copia propia evita depender del ciclo de vida del
// registro del llamador.
procedure ComponerLecturas(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.LeerEstado :=
    function: TEstadoSesionCreacion
    begin
      Result := LeerEstadoSesionCreacion(AEntorno.Cabecera);
    end;
  ACallbacks.GuardarEdicion :=
    procedure
    begin
      if AEntorno.Celdas.State in [dsEdit, dsInsert] then
        AEntorno.Celdas.Post;
      if AEntorno.Cabecera.State in [dsEdit, dsInsert] then
        AEntorno.Cabecera.Post;
      if AEntorno.Lineas.State in [dsEdit, dsInsert] then
        AEntorno.Lineas.Post;
      if Assigned(AEntorno.GuardarPropiedades) then
        AEntorno.GuardarPropiedades();
    end;
  ACallbacks.NormalizarDuplicados :=
    function(const AEstado: TEstadoSesionCreacion): Integer
    begin
      Result := AEntorno.Servicio.NormalizarDuplicadosIntraSesion(
        AEntorno.Usuario,
        AEstado.Serie,
        AEstado.Numero);
    end;
  ACallbacks.Validar :=
    function(out AIncidencias: TIncidenciasMaterializacionSesion): Boolean
    var
      iIncidencia: Integer;
      Lista: TStringList;
    begin
      Lista := TStringList.Create;
      try
        Result := AEntorno.Servicio.ValidarSesionDetallado(Lista);
        SetLength(AIncidencias, Lista.Count);
        for iIncidencia := 0 to Lista.Count - 1 do
          AIncidencias[iIncidencia] := Lista[iIncidencia];
      finally
        FreeAndNil(Lista);
      end;
    end;
end;

// Código y nombre del almacén, o solo el código si no está en la lista.
function NombreAlmacenSinSerie(
  const AEntorno: TEntornoMaterializacionCompraSesion;
  const AAlmacen: string): string;
var
  vNombre: Variant;
begin
  Result := AAlmacen;
  if Assigned(AEntorno.FuenteAlmacenes) and
     Assigned(AEntorno.FuenteAlmacenes.DataSet) and
     AEntorno.FuenteAlmacenes.DataSet.Active then
  begin
    vNombre := AEntorno.FuenteAlmacenes.DataSet.Lookup(
      'CODIGO_ALM_ALM', AAlmacen, 'NOMBRE_ALM_ALM');
    if not VarIsNull(vNombre) and (Trim(VarToStr(vNombre)) <> '') then
      Result := AAlmacen + ' - ' + Trim(VarToStr(vNombre));
  end;
end;

// FZ: un documento por almacén. Una línea por almacén y documento.
function TextoSeriesSinPropia(
  const AEntorno: TEntornoMaterializacionCompraSesion;
  const ASeries: TSeriesAlmacenesSinPropia): string;
var
  Sin: TSerieAlmacenSinPropia;
  sDocumento: string;
  Lineas: TStringList;
begin
  Lineas := TStringList.Create;
  try
    for Sin in ASeries do
    begin
      if Sin.TipoDocumento = 'AB' then
        sDocumento := SNombreAlbaranCompraOpcionesDocumento
      else
        sDocumento := SNombrePedidoCompraOpcionesDocumento;
      Lineas.Add(Format(SLineaAlmacenSinSeriePropia,
        [NombreAlmacenSinSerie(AEntorno, Sin.Almacen), sDocumento,
         Sin.Serie]));
    end;
    Result := Format(SAvisoAlmacenesSinSeriePropia, [TrimRight(Lineas.Text)]);
  finally
    FreeAndNil(Lineas);
  end;
end;

procedure ComponerEscrituras(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.CalcularDefectos :=
    function(const AEstado: TEstadoSesionCreacion):
      TDefectosDialogoCreacion
    begin
      Result := CalcularDefectosDialogoCreacion(
        AEstado,
        ObtenerSerieDefecto(
          AEntorno.Conexion,
          AEstado.Empresa,
          'AB'),
        ObtenerSerieDefecto(
          AEntorno.Conexion,
          AEstado.Empresa,
          'PC'));
    end;
  ACallbacks.ActualizarCabecera :=
    procedure(const AAjustes: TAjustesCreacionElegidos)
    var
      Cabecera: TCabeceraSesionActualizada;
    begin
      Cabecera := ComponerCabeceraActualizada(AAjustes);
      EscribirCabeceraSesionCreacion(AEntorno.Cabecera, Cabecera);
    end;
  ACallbacks.SeriesSinPropia :=
    function(
      const AEstado: TEstadoSesionCreacion;
      const AAjustes: TAjustesCreacionElegidos): TSeriesAlmacenesSinPropia
    var
      Parametros: TParametrosMaterializacionSesion;
    begin
      Parametros := ComponerParametrosMaterializacion(
        AEntorno.Usuario,
        AAjustes);
      Result := AEntorno.Servicio.AlmacenesSinSeriePropia(
        Parametros,
        AEstado.Empresa,
        AAjustes.GeneraPedido,
        AAjustes.GeneraAlbaran);
    end;
  ACallbacks.Materializar :=
    function(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean
    var
      Parametros: TParametrosMaterializacionSesion;
    begin
      Parametros := ComponerParametrosMaterializacion(
        AEntorno.Usuario,
        AAjustes);
      Screen.Cursor := crHourGlass;
      try
        Result := AEntorno.Servicio.EjecutarMaterializacion(
          Parametros,
          AResultado);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  // FZ-ISSUE-638: vista previa de las filas de tarifa, con lo ya grabado.
  ACallbacks.CalcularPreciosTarifa :=
    function(const AAjustes: TAjustesCreacionElegidos):
      TArticulosPreciosTarifa
    var
      Estado: TEstadoSesionCreacion;
    begin
      Estado := LeerEstadoSesionCreacion(AEntorno.Cabecera);
      Result := CalcularPreciosTarifaSesion(AEntorno.Conexion,
        Estado.Serie, Estado.Numero, AAjustes.Tarifa);
    end;
  ACallbacks.Refrescar :=
    procedure
    begin
      AEntorno.Cabecera.Refresh;
      if AEntorno.Documentos.Active then
        AEntorno.Documentos.Refresh
      else
        AEntorno.Documentos.Open;
      if Assigned(AEntorno.RefrescarFotos) then
        AEntorno.RefrescarFotos();
    end;
end;

procedure ComponerAvisos(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.Registrar :=
    procedure(const ATexto: string)
    begin
      if Assigned(AEntorno.Registrar) then
        AEntorno.Registrar(ATexto);
    end;
  ACallbacks.MostrarBloqueo :=
    procedure(AMotivo: TMotivoBloqueoCreacion)
    begin
      case AMotivo of
        mbcSinCabecera:
          ShowMessage_fza(SErrorSesionCompraNoActiva);
        mbcYaMaterializada:
          ShowMessage_fza(SErrorSesionYaMaterializada);
      end;
    end;
  ACallbacks.InformarDuplicados :=
    procedure(ACantidad: Integer)
    begin
      ShowMessage_fza(Format(
        SInfoDuplicadosSesionMarcadosReusar,
        [ACantidad]));
      AEntorno.Lineas.Refresh;
    end;
  ACallbacks.MostrarIncidencias :=
    procedure(const AIncidencias: TIncidenciasMaterializacionSesion)
    var
      sIncidencia: string;
      Lista: TStringList;
    begin
      Lista := TStringList.Create;
      try
        for sIncidencia in AIncidencias do
          Lista.Add(sIncidencia);
      TfrmModalIncidencias.Mostrar(
        AEntorno.Propietario,
        STituloIncidenciasMaterializacionSesionCompra,
        Lista);
      finally
        FreeAndNil(Lista);
      end;
    end;
end;

procedure ComponerDialogos(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.SolicitarAjustes :=
    function(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean
    begin
      Result := TfrmModalCrearAlbaranSesion.Solicitar(
        AEntorno.Propietario,
        AEntorno.FuenteAlmacenes,
        AEntorno.FuenteTarifas,
        AEntorno.FuenteTemporadas,
        AEstado,
        ADefectos,
        AAjustes);
    end;
  ACallbacks.MostrarResultado :=
    procedure(const AResultado: TResultadoMaterializacionSesion)
    var
      DocumentoSeleccionado: TDocumentoMaterializado;
    begin
      if Length(AResultado.Documentos) = 0 then
        ShowMessage_fza(SInfoSesionMaterializadaSinDocumentos)
      else if TfrmModalDocsCreados.Seleccionar(
        AEntorno.Propietario,
        AResultado.Documentos,
        DocumentoSeleccionado) then
      begin
        if SameText(DocumentoSeleccionado.Tipo, 'Albaran') then
          ShowMto(
            Application.MainForm,
            'AlbaranesCompra',
            DocumentoSeleccionado.Serie + ',' +
              DocumentoSeleccionado.Numero)
        else if SameText(DocumentoSeleccionado.Tipo, 'Pedido') then
          ShowMto(
            Application.MainForm,
            'PedidosCompra',
            DocumentoSeleccionado.Serie + ',' +
              DocumentoSeleccionado.Numero);
      end;
    end;
  ACallbacks.MostrarError :=
    procedure(const AMensaje: string)
    begin
      TfrmModalIncidencias.MostrarMensaje(
        AEntorno.Propietario,
        STituloErrorMaterializacionSesionCompra,
        Format(SMensajeErrorMaterializacionSesionCompra, [AMensaje]));
    end;
  ACallbacks.ConfirmarSeriesSinPropia :=
    function(const ASeries: TSeriesAlmacenesSinPropia): Boolean
    begin
      Result := MessageDlg_fza(TextoSeriesSinPropia(AEntorno, ASeries),
        mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
    end;
  ACallbacks.ConfirmarPreciosTarifa :=
    function(const ATarifa: string; const APrecios: TArticulosPreciosTarifa;
      var AOpciones: TOpcionesTarifaSesion): Boolean
    begin
      Result := TfrmModalPreciosTarifaSesion.Confirmar(
        AEntorno.Propietario, ATarifa, APrecios, AOpciones);
    end;
  // F-LOTEC-013: la sesión se materializó; solo queda completar lotes.
  ACallbacks.MostrarAviso :=
    procedure(const AMensaje: string)
    begin
      ShowMessage_fza(AMensaje);
    end;
end;

function CrearAplicacionMaterializacionCompraSesionVcl(
  const AEntorno: TEntornoMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;
var
  Callbacks: TCallbacksMaterializacionCompraSesion;
  Adaptador: TAdaptadorMaterializacionCompraSesionVcl;
  Operaciones: IOperacionesMaterializacionCompraSesion;
  Vista: IVistaMaterializacionCompraSesion;
begin
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Cabecera) then
    raise EArgumentNilException.Create('AEntorno.Cabecera');
  Callbacks := Default(TCallbacksMaterializacionCompraSesion);
  ComponerLecturas(AEntorno, Callbacks);
  ComponerEscrituras(AEntorno, Callbacks);
  ComponerAvisos(AEntorno, Callbacks);
  ComponerDialogos(AEntorno, Callbacks);
  Adaptador := TAdaptadorMaterializacionCompraSesionVcl.Create(Callbacks);
  Operaciones := Adaptador;
  Vista := Adaptador;
  Result := CrearAplicacionMaterializacionCompraSesion(
    Operaciones,
    Vista);
end;

end.

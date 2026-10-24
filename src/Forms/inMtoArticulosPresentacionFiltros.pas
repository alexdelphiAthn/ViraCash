{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionFiltros                             }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Persiana de filtros de carga del Mto Articulos: lectura y volcado del     }
{    perfil, composicion del filtro y guardado de la precarga. Recibe los      }
{    controles y los puertos de datos; nunca el formulario.                    }
{******************************************************************************}
unit inMtoArticulosPresentacionFiltros;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.ExtCtrls,
  cxButtons, cxCheckBox, cxCheckComboBox, cxDropDownEdit, cxLookAndFeelPainters,
  inLibPerfilesUsuarioIntf,
  inLibTraduccionesIntf,
  inLibFiltroArticulosPersistenciaIntf,
  inLibArticulosFiltro,
  inLibArticulosPresentacionIntf;

type
  // Controles de la persiana. Se agrupan para no arrastrar seis
  // parametros sueltos por el constructor.
  TControlesFiltroCargaArticulos = record
    Estado: TcxComboBox;
    ConStock: TcxCheckBox;
    Temporadas: TcxCheckComboBox;
    Persiana: TPanel;
    Contenido: TPanel;
    Cabecera: TcxButton;
  end;

  // Relanza la carga en segundo plano de la lista principal.
  TRecargarListaArticulos = reference to procedure;

  TPresentadorFiltrosArticulos = class
  private
    FControles: TControlesFiltroCargaArticulos;
    FCatalogo: IRepositorioFiltroArticulos;
    FLista: IListaArticulosPantalla;
    FPrecarga: IEscrituraPrecargaArticulos;
    FRecargarLista: TRecargarListaArticulos;
    // Bloquea los OnEditValueChanged mientras se inicializan los
    // controles: sin la guarda cada asignacion reaplicaria el filtro.
    FCargando: Boolean;
    // Filtros de sesion del dialogo de precarga (proveedor y familia):
    // arrancan vacios en cada apertura del Mto y no se persisten.
    FProveedoresCsv: string;
    FFamiliasCsv: string;
    function TemporadasMarcadas: TArray<string>;
    procedure DesmarcarTemporadas;
    procedure ActualizarCabecera;
  public
    constructor Create(
      const AControles: TControlesFiltroCargaArticulos;
      const ACatalogo: IRepositorioFiltroArticulos;
      const ALista: IListaArticulosPantalla;
      const APrecarga: IEscrituraPrecargaArticulos;
      const ARecargarLista: TRecargarListaArticulos);
    procedure CargarTemporadas;
    procedure Traducir(const ATraducciones: IServicioTraducciones);
    procedure LeerPerfil(var APerfil: TProfileDicc);
    procedure VolcarPerfil(APerfiles: TPerfilList;
      const APermisos, AClave: string);
    function CsvTemporadas: string;
    function ConstruirFiltro:
      inLibArticulosFiltro.TFiltroArticulos;
    function ConstruirSql:
      inLibArticulosFiltro.TFiltroArticulos;
    procedure AplicarFiltroEnLista;
    procedure AplicarFiltros;
    procedure Colapsar;
    procedure AlternarPersiana;
    procedure ReiniciarParaBusquedaExterna;
    procedure GuardarPrecarga(APropietario: TComponent;
      const ANombrePantalla: string);
    property Cargando: Boolean read FCargando;
  end;

implementation

uses
  inLibMensajesVcl,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImpSave,
  inLibPerfilesUsuarioValores,
  inLibArticulosPresentacion,
  inLibMsgArticulos,
  inLibMsgComun;

resourcestring
  SDescripcionModalGuardarPrecargaArticulos = 'Guardar precarga';

const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 44;

constructor TPresentadorFiltrosArticulos.Create(
  const AControles: TControlesFiltroCargaArticulos;
  const ACatalogo: IRepositorioFiltroArticulos;
  const ALista: IListaArticulosPantalla;
  const APrecarga: IEscrituraPrecargaArticulos;
  const ARecargarLista: TRecargarListaArticulos);
begin
  inherited Create;
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('ACatalogo');
  if not Assigned(ALista) then
    raise EArgumentNilException.Create('ALista');
  FControles := AControles;
  FCatalogo := ACatalogo;
  FLista := ALista;
  FPrecarga := APrecarga;
  FRecargarLista := ARecargarLista;
  FProveedoresCsv := '';
  FFamiliasCsv := '';
end;

procedure TPresentadorFiltrosArticulos.Traducir(
  const ATraducciones: IServicioTraducciones);
const
  CLAVE_FORMULARIO = 'inMtoArticulos.TfrmMtoArticulos.';
var
  iOpcion: Integer;
  iSeleccion: Integer;
  bCargandoAnterior: Boolean;
begin
  if Assigned(ATraducciones) then
  begin
    bCargandoAnterior := FCargando;
    FCargando := True;
    try
      if Assigned(FControles.Estado) then
      begin
        iSeleccion := FControles.Estado.ItemIndex;
        for iOpcion := 0 to FControles.Estado.Properties.Items.Count - 1 do
          FControles.Estado.Properties.Items[iOpcion] :=
            ATraducciones.Traducir(CLAVE_FORMULARIO +
              'cbbFiltroEstadoArt.Properties.Items[' +
              IntToStr(iOpcion) + ']',
              FControles.Estado.Properties.Items[iOpcion]);
        FControles.Estado.ItemIndex := iSeleccion;
      end;
      if Assigned(FControles.Temporadas) then
        FControles.Temporadas.Properties.EmptySelectionText :=
          ATraducciones.Traducir(CLAVE_FORMULARIO +
            'ccbFiltroTemporadaArt.Properties.EmptySelectionText',
            FControles.Temporadas.Properties.EmptySelectionText);
    finally
      FCargando := bCargandoAnterior;
    end;
  end;
end;

procedure TPresentadorFiltrosArticulos.CargarTemporadas;
var
  oTemporadas: TTemporadasFiltroArticulos;
  iTemporada: Integer;
  oItem: TcxCheckComboBoxItem;
begin
  // Las mismas temporadas activas que ofrece la pestanya Propiedades
  // para CODIGO_PROP_ARTPROP = 'TEMPORADA'.
  if FControles.Temporadas <> nil then
  begin
    FControles.Temporadas.Properties.Items.Clear;
    oTemporadas := FCatalogo.ListarTemporadas;
    for iTemporada := 0 to High(oTemporadas) do
    begin
      oItem := FControles.Temporadas.Properties.Items.Add;
      oItem.Description := oTemporadas[iTemporada];
    end;
  end;
end;

function TPresentadorFiltrosArticulos.TemporadasMarcadas: TArray<string>;
var
  iItem: Integer;
  iDestino: Integer;
begin
  SetLength(Result, 0);
  if FControles.Temporadas <> nil then
    for iItem := 0 to FControles.Temporadas.Properties.Items.Count - 1 do
      if FControles.Temporadas.States[iItem] = cbsChecked then
      begin
        iDestino := Length(Result);
        SetLength(Result, iDestino + 1);
        Result[iDestino] :=
          FControles.Temporadas.Properties.Items[iItem].Description;
      end;
end;

procedure TPresentadorFiltrosArticulos.DesmarcarTemporadas;
var
  iItem: Integer;
begin
  if FControles.Temporadas <> nil then
    for iItem := 0 to FControles.Temporadas.Properties.Items.Count - 1 do
      FControles.Temporadas.States[iItem] := cbsUnchecked;
end;

procedure TPresentadorFiltrosArticulos.LeerPerfil(var APerfil: TProfileDicc);
var
  sEstado, sStock, sTemporadasCsv: string;
  oGuardadas: TStringList;
  iItem: Integer;
begin
  FCargando := True;
  try
    // Precarga por defecto: solo activos ('S'), sin exigir stock ('N').
    // Asi las altas nuevas aparecen aunque no tengan movimientos.
    sEstado := Trim(GetPerfilValueDef(APerfil, 'oFiltroEstado', 'S'));
    sStock := Trim(GetPerfilValueDef(APerfil, 'oFiltroConStock', 'N'));
    sTemporadasCsv := GetPerfilValueDef(APerfil, 'oFiltroTemporadas', '');
    if FControles.Estado <> nil then
      FControles.Estado.ItemIndex := IndiceEstadoFiltroDesdeCodigo(sEstado);
    if FControles.ConStock <> nil then
      FControles.ConStock.Checked := SameText(sStock, 'S');
    // Una temporada guardada que ya no exista simplemente se ignora.
    oGuardadas := TStringList.Create;
    try
      oGuardadas.Delimiter := ';';
      oGuardadas.StrictDelimiter := True;
      oGuardadas.DelimitedText := sTemporadasCsv;
      if FControles.Temporadas <> nil then
        for iItem := 0 to
             FControles.Temporadas.Properties.Items.Count - 1 do
          if oGuardadas.IndexOf(
               FControles.Temporadas.Properties.Items[
                 iItem].Description) >= 0 then
            FControles.Temporadas.States[iItem] := cbsChecked
          else
            FControles.Temporadas.States[iItem] := cbsUnchecked;
    finally
      FreeAndNil(oGuardadas);
    end;
  finally
    FCargando := False;
  end;
end;

procedure TPresentadorFiltrosArticulos.VolcarPerfil(APerfiles: TPerfilList;
  const APermisos, AClave: string);
var
  oItem: TPerfilItem;
begin
  // Se vuelca al batch de sbGrabarGridClick para respetar el ambito
  // (APermisos) elegido por el usuario en el dialogo de grabar.
  if (APerfiles <> nil) and (FControles.Estado <> nil) then
  begin
    oItem.UserGroup := APermisos;
    oItem.KeyPerfil := AClave;
    // Estado: T=Todos, S=Solo activos, N=Solo inactivos.
    oItem.SubKey := 'oFiltroEstado';
    oItem.Value :=
      CodigoEstadoFiltroDesdeIndice(FControles.Estado.ItemIndex);
    APerfiles.Add(oItem);
    oItem.SubKey := 'oFiltroConStock';
    if (FControles.ConStock <> nil) and FControles.ConStock.Checked then
      oItem.Value := 'S'
    else
      oItem.Value := 'N';
    APerfiles.Add(oItem);
    oItem.SubKey := 'oFiltroTemporadas';
    oItem.Value := CsvTemporadas;
    APerfiles.Add(oItem);
  end;
end;

function TPresentadorFiltrosArticulos.CsvTemporadas: string;
begin
  Result := ComponerCsvSeleccion(TemporadasMarcadas);
end;

function TPresentadorFiltrosArticulos.ConstruirFiltro:
  inLibArticulosFiltro.TFiltroArticulos;
var
  iIndiceEstado: Integer;
begin
  iIndiceEstado := 0;
  if FControles.Estado <> nil then
    iIndiceEstado := FControles.Estado.ItemIndex;
  Result.Estado := EstadoFiltroArticulosDesdeIndice(iIndiceEstado);
  Result.SoloConStock := (FControles.ConStock <> nil) and
                         FControles.ConStock.Checked;
  Result.TemporadasCsv := CsvTemporadas;
  Result.ProveedoresCsv := FProveedoresCsv;
  Result.FamiliasCsv := FFamiliasCsv;
end;

function TPresentadorFiltrosArticulos.ConstruirSql:
  inLibArticulosFiltro.TFiltroArticulos;
begin
  // Compatibilidad temporal con el trinquete; no compone sentencias.
  Result := ConstruirFiltro;
end;

procedure TPresentadorFiltrosArticulos.AplicarFiltroEnLista;
begin
  FLista.AplicarFiltro(ConstruirFiltro);
  ActualizarCabecera;
end;

procedure TPresentadorFiltrosArticulos.ActualizarCabecera;
var
  bExpandida: Boolean;
  sCabecera: string;
begin
  // FZ-ISSUE-658: plegada, la cabecera dice qué filtros de carga hay
  // puestos; si no, una lista filtrada parece incompleta.
  if FControles.Cabecera <> nil then
  begin
    bExpandida := (FControles.Contenido <> nil) and
                  FControles.Contenido.Visible;
    if bExpandida then
      sCabecera := SCaptionFiltrosCargaExpandido
    else
      sCabecera := SCaptionFiltrosCargaContraido;
    FControles.Cabecera.Caption := CabeceraFiltrosCargaArticulos(
      sCabecera, bExpandida, ConstruirFiltro);
  end;
end;

procedure TPresentadorFiltrosArticulos.AplicarFiltros;
begin
  // Cambio manual de filtros o boton "Cargar ahora": se recarga TODA la
  // lista con el filtro elegido, en segundo plano y con overlay.
  AplicarFiltroEnLista;
  if Assigned(FRecargarLista) then
    FRecargarLista();
end;

procedure TPresentadorFiltrosArticulos.Colapsar;
begin
  // La persiana se deja desplegada en el .dfm para poder editarla en
  // diseno; al arrancar el form se colapsa.
  if FControles.Contenido <> nil then
    FControles.Contenido.Visible := False;
  if FControles.Persiana <> nil then
    FControles.Persiana.Height := ALTO_CABECERA;
  ActualizarCabecera;
end;

procedure TPresentadorFiltrosArticulos.AlternarPersiana;
begin
  if (FControles.Contenido <> nil) and (FControles.Persiana <> nil) and
     (FControles.Cabecera <> nil) then
  begin
    FControles.Contenido.Visible := not FControles.Contenido.Visible;
    if FControles.Contenido.Visible then
      FControles.Persiana.Height := ALTO_CABECERA + ALTO_CONTENIDO
    else
      FControles.Persiana.Height := ALTO_CABECERA;
    ActualizarCabecera;
  end;
end;

procedure TPresentadorFiltrosArticulos.ReiniciarParaBusquedaExterna;
begin
  // Busqueda externa (Ctrl+R desde otro Mto): sin filtros de carga para
  // que salgan todos los articulos. El WHERE lo impone el parser.
  FCargando := True;
  try
    if FControles.Estado <> nil then
      FControles.Estado.ItemIndex := 0;
    if FControles.ConStock <> nil then
      FControles.ConStock.Checked := False;
    DesmarcarTemporadas;
  finally
    FCargando := False;
  end;
  FProveedoresCsv := '';
  FFamiliasCsv := '';
  AplicarFiltroEnLista;
  Colapsar;
end;

procedure TPresentadorFiltrosArticulos.GuardarPrecarga(
  APropietario: TComponent; const ANombrePantalla: string);
// Guarda SOLO los filtros de carga en el perfil. El cambio ya se aplica
// en caliente; este boton lo hace permanente sin pasar por "Grabar Grid"
// (que ademas reescribe anchos de columna y captions).
var
  oModal: TfrmModalGenImpSave;
  sPermisos: string;
  oPerfiles: TPerfilList;
begin
  sPermisos := '';
  oModal := TfrmModalGenImpSave.Create(APropietario);
  try
    oModal.edtDescripcion.Enabled := False;
    oModal.edtNombreOrigen.Text := ANombrePantalla;
    oModal.edtDescripcion.Text := SDescripcionModalGuardarPrecargaArticulos;
    oModal.ShowModal;
    if oModal.sFicha = 'S' then
      sPermisos := oModal.cbbPermisos.Text;
  finally
    FreeAndNil(oModal);
  end;
  // Solo persistimos si el usuario confirmo el ambito en el dialogo.
  if (sPermisos <> '') and Assigned(FPrecarga) then
  begin
    Screen.Cursor := crHourGlass;
    oPerfiles := TPerfilList.Create;
    try
      VolcarPerfil(oPerfiles, sPermisos, ANombrePantalla);
      FPrecarga.GrabarPerfiles(oPerfiles);
    finally
      FreeAndNil(oPerfiles);
      Screen.Cursor := crDefault;
    end;
    ShowMessage_fza(SInfoPrecargaArticuloGuardada);
  end;
end;

end.

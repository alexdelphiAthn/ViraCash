{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionFotos                         }
{    Tipo:       Presentacion                                                  }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la previsualizacion, asignacion y descarga de fotos de sesion.   }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionFotos;

interface

uses
  System.Classes,
  Data.DB,
  Vcl.ActnList, Vcl.Dialogs, Vcl.ExtCtrls,
  cxButtons, cxGridCustomTableView, cxGridDBTableView, cxGroupBox, cxLabel,
  cxPC, cxSplitter,
  inLibFotos,
  inLibParametrosIntf;

type
  TEstadoSeleccionFotoSesion = (
    esfsValida,
    esfsSinSesion,
    esfsSinLinea,
    esfsSinCodigo);

  TSeleccionFotoSesion = record
    Serie: string;
    Numero: string;
    Linea: Integer;
    CodigoArticulo: string;
    CodigoUnidad: string;
  end;

  TEntornoFotosProvisionalesSesion = record
    Propietario: TComponent;
    AccionFoto: TCustomAction;
    BotonAsignar: TcxButton;
    BotonDescargar: TcxButton;
    DialogoFoto: TOpenDialog;
    GrupoCabecera: TcxGroupBox;
    GrupoFoto: TcxGroupBox;
    Imagen: TImage;
    Etiqueta: TcxLabel;
    PaginasFicha: TcxPageControl;
    PaginaPedidoOriginal: TcxTabSheet;
    PaginasDetalle: TcxPageControl;
    PaginaFotos: TcxTabSheet;
    VistaFotos: TcxGridDBTableView;
    FuenteCabecera: TDataSource;
    FuenteLineas: TDataSource;
    FuenteFotos: TDataSource;
    Parametros: IParametrosAplicacion;
    Fotos: TFotosArticulos;
    Usuario: string;
    procedure Validar;
  end;

  TCoordinadorFotosProvisionalesSesion = class
  private
    FEntorno: TEntornoFotosProvisionalesSesion;
    FSplitter: TcxSplitter;
    FEventosConectados: Boolean;
    procedure ConectarEventos;
    procedure DesconectarEventos;
    procedure DesvincularFormularioFlotante;
    procedure ConfigurarDialogo;
    procedure AsignarFoto(Sender: TObject);
    procedure DescargarFotos(Sender: TObject);
    procedure EjecutarAccionFoto(Sender: TObject);
    procedure FotoSesionModificada(Sender: TObject);
    procedure FotosDataChange(Sender: TObject; Field: TField);
    procedure FotoEnfocadaCambiada(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord: TcxCustomGridRecord;
      AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure PublicarMensaje(const AMensaje: string);
    procedure PublicarFoto(const ASeleccion: TSeleccionFotoSesion);
    procedure ResolverFotoSesionActiva(
      out ASerieSesion: string;
      out ANumeroSesion: string;
      out ALinea: Integer;
      out ACodArtTentativo: string;
      out ACodUnidad: string);
    procedure PostearEdicion;
    function DataSetDisponible(AFuente: TDataSource): Boolean;
    function FuenteVinculadaAFormulario(
      AFuente: TDataSource;
      AFormulario: TObject): Boolean;
    function ObtenerSeleccion(
      AUsarFotoActiva: Boolean): TSeleccionFotoSesion;
  public
    constructor Create(
      const AEntorno: TEntornoFotosProvisionalesSesion);
    destructor Destroy; override;
    procedure ConfigurarCabecera;
    procedure ActualizarPaginaDetalle;
    procedure ActualizarPaginaFicha;
    procedure Refrescar;
    procedure RefrescarLista;
    function FuentesVinculadas: TArray<TDataSource>;
  end;

function EvaluarSeleccionFotoSesion(
  const ASeleccion: TSeleccionFotoSesion;
  ARequiereCodigo: Boolean): TEstadoSeleccionFotoSesion;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  Vcl.Controls, Vcl.Forms,
  Vcl.Imaging.pngimage,
  inLibFotosNube,
  inLibMsgCompras,
  inMtoFotoArticulo;

resourcestring
  SErrorPropietarioFotosSesionNoDisponible =
    'No se proporciono el propietario del coordinador de fotos.';
  SErrorControlesFotosSesionNoDisponibles =
    'No se proporcionaron todos los controles de fotos de la sesion.';
  SErrorDatosFotosSesionNoDisponibles =
    'No se proporcionaron todos los datasets de fotos de la sesion.';
  SErrorServicioFotosSesionNoDisponible =
    'No se proporciono el servicio de fotos de la sesion.';
  SFiltroImagenFotosSesion =
    'Imagenes (*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp)|' +
    '*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp';

function EvaluarSeleccionFotoSesion(
  const ASeleccion: TSeleccionFotoSesion;
  ARequiereCodigo: Boolean): TEstadoSeleccionFotoSesion;
begin
  if (ASeleccion.Serie = '') or (ASeleccion.Numero = '') then
    Result := esfsSinSesion
  else if ASeleccion.Linea <= 0 then
    Result := esfsSinLinea
  else if ARequiereCodigo and (Trim(ASeleccion.CodigoArticulo) = '') then
    Result := esfsSinCodigo
  else
    Result := esfsValida;
end;

procedure TEntornoFotosProvisionalesSesion.Validar;
begin
  if Propietario = nil then
  begin
    raise EArgumentNilException.Create(
      SErrorPropietarioFotosSesionNoDisponible);
  end;
  if (AccionFoto = nil) or (BotonAsignar = nil) or
     (BotonDescargar = nil) or (DialogoFoto = nil) or
     (GrupoCabecera = nil) or (GrupoFoto = nil) or
     (Imagen = nil) or (Etiqueta = nil) or
     (PaginasFicha = nil) or (PaginaPedidoOriginal = nil) or
     (PaginasDetalle = nil) or (PaginaFotos = nil) or
     (VistaFotos = nil) then
  begin
    raise EArgumentNilException.Create(
      SErrorControlesFotosSesionNoDisponibles);
  end;
  if (FuenteCabecera = nil) or (FuenteLineas = nil) or
     (FuenteFotos = nil) then
  begin
    raise EArgumentNilException.Create(
      SErrorDatosFotosSesionNoDisponibles);
  end;
  if Fotos = nil then
  begin
    raise EArgumentNilException.Create(
      SErrorServicioFotosSesionNoDisponible);
  end;
end;

constructor TCoordinadorFotosProvisionalesSesion.Create(
  const AEntorno: TEntornoFotosProvisionalesSesion);
begin
  inherited Create;
  FEntorno := AEntorno;
  FEntorno.Validar;
  ConectarEventos;
end;

destructor TCoordinadorFotosProvisionalesSesion.Destroy;
begin
  DesvincularFormularioFlotante;
  DesconectarEventos;
  FreeAndNil(FSplitter);
  FEntorno.Fotos := nil;
  FEntorno.Parametros := nil;
  inherited;
end;

function TCoordinadorFotosProvisionalesSesion.
  FuenteVinculadaAFormulario(
  AFuente: TDataSource;
  AFormulario: TObject): Boolean;
var
  Evento: TMethod;
begin
  Result := False;
  if (AFuente <> nil) and Assigned(AFuente.OnDataChange) then
  begin
    Evento := TMethod(AFuente.OnDataChange);
    Result := Evento.Data = AFormulario;
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.
  DesvincularFormularioFlotante;
var
  Formulario: TfrmFotoArticulo;
begin
  Formulario := FotoFlotanteActual;
  if (Formulario <> nil) and
     (FuenteVinculadaAFormulario(
       FEntorno.FuenteCabecera,
       Formulario) or
      FuenteVinculadaAFormulario(
        FEntorno.FuenteLineas,
        Formulario)) then
  begin
    Formulario.VincularSesion([], nil, nil);
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.ConectarEventos;
begin
  FEntorno.AccionFoto.OnExecute := EjecutarAccionFoto;
  FEntorno.BotonAsignar.OnClick := AsignarFoto;
  FEntorno.BotonDescargar.OnClick := DescargarFotos;
  FEntorno.VistaFotos.OnFocusedRecordChanged :=
    FotoEnfocadaCambiada;
  FEntorno.FuenteFotos.OnDataChange := FotosDataChange;
  FEventosConectados := True;
end;

procedure TCoordinadorFotosProvisionalesSesion.DesconectarEventos;
begin
  if FEventosConectados then
  begin
    FEntorno.AccionFoto.OnExecute := nil;
    FEntorno.BotonAsignar.OnClick := nil;
    FEntorno.BotonDescargar.OnClick := nil;
    FEntorno.VistaFotos.OnFocusedRecordChanged := nil;
    FEntorno.FuenteFotos.OnDataChange := nil;
    FEventosConectados := False;
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.ConfigurarDialogo;
begin
  FEntorno.DialogoFoto.Filter := SFiltroImagenFotosSesion;
  FEntorno.DialogoFoto.Options :=
    FEntorno.DialogoFoto.Options + [ofFileMustExist];
end;

procedure TCoordinadorFotosProvisionalesSesion.ConfigurarCabecera;
begin
  FEntorno.GrupoFoto.Parent := FEntorno.GrupoCabecera.Parent;
  FEntorno.GrupoCabecera.Align := alClient;
  FEntorno.GrupoFoto.Align := alRight;
  FEntorno.GrupoFoto.Constraints.MinWidth := 160;
  FEntorno.GrupoFoto.Constraints.MaxWidth := 0;
  FEntorno.Etiqueta.Align := alBottom;
  FEntorno.Etiqueta.Height := 34;
  FEntorno.Imagen.Align := alClient;
  FEntorno.Imagen.Center := True;
  FEntorno.Imagen.Proportional := True;
  FEntorno.Imagen.Stretch := True;
  if FSplitter = nil then
  begin
    FSplitter := TcxSplitter.Create(FEntorno.Propietario);
    FSplitter.Parent := FEntorno.GrupoCabecera.Parent;
    FSplitter.Width := 8;
    FSplitter.AlignSplitter := salRight;
    FSplitter.Control := FEntorno.GrupoFoto;
  end;
end;

function TCoordinadorFotosProvisionalesSesion.DataSetDisponible(
  AFuente: TDataSource): Boolean;
begin
  Result := (AFuente <> nil) and (AFuente.DataSet <> nil) and
    AFuente.DataSet.Active and not AFuente.DataSet.IsEmpty;
end;

function TCoordinadorFotosProvisionalesSesion.ObtenerSeleccion(
  AUsarFotoActiva: Boolean): TSeleccionFotoSesion;
var
  Datos: TDataSet;
begin
  Result := Default(TSeleccionFotoSesion);
  if DataSetDisponible(FEntorno.FuenteCabecera) then
  begin
    Datos := FEntorno.FuenteCabecera.DataSet;
    Result.Serie := Datos.FieldByName('SERIE_SES').AsString;
    Result.Numero := Datos.FieldByName('NUMERO_SES').AsString;
    if AUsarFotoActiva and
       (FEntorno.PaginasDetalle.ActivePage = FEntorno.PaginaFotos) and
       DataSetDisponible(FEntorno.FuenteFotos) then
    begin
      Datos := FEntorno.FuenteFotos.DataSet;
      Result.Linea := Datos.FieldByName('LINEA_CSF').AsInteger;
      Result.CodigoArticulo := Datos.FieldByName(
        'CODIGO_ART_TENTATIVO_CSF').AsString;
      Result.CodigoUnidad := Datos.FieldByName(
        'CODIGO_UNIDAD_CSF').AsString;
    end
    else if DataSetDisponible(FEntorno.FuenteLineas) then
    begin
      Datos := FEntorno.FuenteLineas.DataSet;
      Result.Linea := Datos.FieldByName('LINEA_SESLIN').AsInteger;
      Result.CodigoArticulo := Datos.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString;
    end;
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.ResolverFotoSesionActiva(
  out ASerieSesion: string;
  out ANumeroSesion: string;
  out ALinea: Integer;
  out ACodArtTentativo: string;
  out ACodUnidad: string);
var
  Seleccion: TSeleccionFotoSesion;
begin
  Seleccion := ObtenerSeleccion(True);
  ASerieSesion := Seleccion.Serie;
  ANumeroSesion := Seleccion.Numero;
  ALinea := Seleccion.Linea;
  ACodArtTentativo := Seleccion.CodigoArticulo;
  ACodUnidad := Seleccion.CodigoUnidad;
end;

procedure TCoordinadorFotosProvisionalesSesion.PublicarFoto(
  const ASeleccion: TSeleccionFotoSesion);
var
  Destino: string;
  Ruta: string;
  Info: TFotoInfo;
  ImagenPng: TPngImage;
  Definitiva: Boolean;
begin
  Info.Clear;
  Definitiva := ASeleccion.CodigoArticulo <> '';
  if Definitiva then
  begin
    Info := FEntorno.Fotos.Resolver(
      ASeleccion.CodigoArticulo,
      ASeleccion.CodigoUnidad);
  end;
  Definitiva := Info.Encontrada;
  if not Definitiva then
  begin
    Info := FEntorno.Fotos.Sesion.Resolver(
      ASeleccion.Serie,
      ASeleccion.Numero,
      ASeleccion.Linea,
      ASeleccion.CodigoUnidad);
  end;
  if Info.Encontrada then
  begin
    Ruta := FEntorno.Fotos.RutaFoto(Info, frPx300);
    if ASeleccion.CodigoUnidad = '' then
      Destino := SCaptionDestinoArticulo
    else
    begin
      Destino := Format(
        SCaptionDestinoSku,
        [ASeleccion.CodigoUnidad]);
    end;
    FEntorno.Etiqueta.Caption := Format(
      SCaptionLineaFotoDetalle,
      [ASeleccion.Linea, ASeleccion.CodigoArticulo, Destino]);
    if Ruta <> '' then
    begin
      ImagenPng := TPngImage.Create;
      try
        ImagenPng.LoadFromFile(Ruta);
        FEntorno.Imagen.Picture.Assign(ImagenPng);
      finally
        FreeAndNil(ImagenPng);
      end;
    end;
  end
  else
  begin
    FEntorno.Etiqueta.Caption := Format(
      SCaptionLineaSinFotoProvisional,
      [ASeleccion.Linea]);
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.Refrescar;
var
  Seleccion: TSeleccionFotoSesion;
begin
  FEntorno.Imagen.Picture.Assign(nil);
  FEntorno.Etiqueta.Caption := SCaptionSeleccioneLineaSesion;
  Seleccion := ObtenerSeleccion(True);
  if EvaluarSeleccionFotoSesion(Seleccion, False) = esfsValida then
    PublicarFoto(Seleccion);
end;

procedure TCoordinadorFotosProvisionalesSesion.RefrescarLista;
var
  Datos: TDataSet;
begin
  Datos := FEntorno.FuenteFotos.DataSet;
  if Datos <> nil then
  begin
    if Datos.Active then
      Datos.Refresh
    else
      Datos.Open;
  end;
  Refrescar;
end;

procedure TCoordinadorFotosProvisionalesSesion.ActualizarPaginaDetalle;
begin
  Refrescar;
end;

procedure TCoordinadorFotosProvisionalesSesion.ActualizarPaginaFicha;
begin
  FEntorno.GrupoFoto.Visible :=
    FEntorno.PaginasFicha.ActivePage <>
    FEntorno.PaginaPedidoOriginal;
  if FEntorno.GrupoFoto.Visible then
    Refrescar;
end;

function TCoordinadorFotosProvisionalesSesion.FuentesVinculadas:
  TArray<TDataSource>;
begin
  Result := [FEntorno.FuenteCabecera, FEntorno.FuenteLineas];
end;

procedure TCoordinadorFotosProvisionalesSesion.FotoEnfocadaCambiada(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord: TcxCustomGridRecord;
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  Refrescar;
end;

procedure TCoordinadorFotosProvisionalesSesion.FotosDataChange(
  Sender: TObject;
  Field: TField);
begin
  if Field = nil then
    Refrescar;
end;

procedure TCoordinadorFotosProvisionalesSesion.FotoSesionModificada(
  Sender: TObject);
begin
  RefrescarLista;
end;

procedure TCoordinadorFotosProvisionalesSesion.PublicarMensaje(
  const AMensaje: string);
begin
  ShowMessage_fza(AMensaje);
end;

procedure TCoordinadorFotosProvisionalesSesion.EjecutarAccionFoto(
  Sender: TObject);
var
  Seleccion: TSeleccionFotoSesion;
  Formulario: TfrmFotoArticulo;
begin
  Seleccion := ObtenerSeleccion(True);
  if EvaluarSeleccionFotoSesion(Seleccion, False) = esfsSinSesion then
    PublicarMensaje(SErrorSesionCompraNoActiva)
  else if EvaluarSeleccionFotoSesion(
    Seleccion, False) = esfsSinLinea then
  begin
    PublicarMensaje(SErrorLineaSesionAsignarFotoNoSeleccionada);
  end
  else
  begin
    Formulario := FotoFlotanteActual;
    if (Formulario <> nil) and Formulario.Visible and
       Formulario.CoincideSesion(
         Seleccion.Serie,
         Seleccion.Numero,
         Seleccion.Linea,
         Seleccion.CodigoUnidad) then
    begin
      Formulario.Hide;
    end
    else
    begin
      MostrarFotoSesionFlotante(
        FEntorno.Propietario,
        Seleccion.Serie,
        Seleccion.Numero,
        Seleccion.Linea,
        Seleccion.CodigoArticulo,
        Seleccion.CodigoUnidad);
      Formulario := FotoFlotanteActual;
      if Formulario <> nil then
      begin
        Formulario.VincularSesion(
          FuentesVinculadas,
          ResolverFotoSesionActiva,
          FotoSesionModificada);
      end;
    end;
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.PostearEdicion;
var
  Datos: TDataSet;
begin
  Datos := FEntorno.FuenteCabecera.DataSet;
  if (Datos <> nil) and (Datos.State in [dsEdit, dsInsert]) then
    Datos.Post;
  Datos := FEntorno.FuenteLineas.DataSet;
  if (Datos <> nil) and (Datos.State in [dsEdit, dsInsert]) then
    Datos.Post;
end;

procedure TCoordinadorFotosProvisionalesSesion.AsignarFoto(
  Sender: TObject);
var
  Seleccion: TSeleccionFotoSesion;
  Estado: TEstadoSeleccionFotoSesion;
  Info: TFotoInfo;
begin
  Seleccion := ObtenerSeleccion(False);
  Estado := EvaluarSeleccionFotoSesion(Seleccion, True);
  if Estado = esfsSinSesion then
    PublicarMensaje(SErrorSesionCompraNoActiva)
  else if Estado = esfsSinLinea then
    PublicarMensaje(SErrorLineaSesionAsignarFotoNoSeleccionada)
  else if Estado = esfsSinCodigo then
    PublicarMensaje(SErrorLineaSesionSinCodigoArticulo)
  else
  begin
    PostearEdicion;
    Seleccion := ObtenerSeleccion(False);
    ConfigurarDialogo;
    if FEntorno.DialogoFoto.Execute then
    begin
      try
        Info := FEntorno.Fotos.Sesion.Guardar(
          Seleccion.Serie,
          Seleccion.Numero,
          Seleccion.Linea,
          Seleccion.CodigoArticulo,
          '',
          FEntorno.DialogoFoto.FileName,
          FEntorno.Usuario);
        if Info.Encontrada then
        begin
          RefrescarLista;
          PublicarMensaje(Format(
            SInfoFotoLineaSesionAsignada,
            [Seleccion.Linea]));
        end
        else
          PublicarMensaje(SErrorAsignarFotoSesion);
      except
        on E: Exception do
        begin
          PublicarMensaje(Format(
            SErrorGuardarFotoSesion,
            [E.Message]));
        end;
      end;
    end;
  end;
end;

procedure TCoordinadorFotosProvisionalesSesion.DescargarFotos(
  Sender: TObject);
var
  Seleccion: TSeleccionFotoSesion;
  Estado: TEstadoSeleccionFotoSesion;
  Mensaje: string;
  Fichero: string;
  Archivos: TArray<string>;
  Correcto: Boolean;
begin
  Seleccion := ObtenerSeleccion(False);
  Estado := EvaluarSeleccionFotoSesion(Seleccion, False);
  if Estado = esfsSinSesion then
    PublicarMensaje(SErrorSesionCompraNoActiva)
  else if Estado = esfsSinLinea then
    PublicarMensaje(SErrorLineaSesionDescargarFotosNoSeleccionada)
  else
  begin
    PostearEdicion;
    Seleccion := ObtenerSeleccion(False);
    Estado := EvaluarSeleccionFotoSesion(Seleccion, True);
    if Estado = esfsSinCodigo then
      PublicarMensaje(SErrorLineaSesionSinCodigoArticulo)
    else
    begin
      Screen.Cursor := crHourGlass;
      try
        Correcto := DescargarFotosArticulo(
          FEntorno.Parametros,
          Seleccion.CodigoArticulo,
          Archivos,
          Mensaje);
      finally
        Screen.Cursor := crDefault;
      end;
      if not Correcto then
      begin
        PublicarMensaje(Format(
          SErrorDescargarFotosArticulo,
          [Seleccion.CodigoArticulo, Mensaje]));
      end
      else
      begin
        Fichero := ElegirFotoRepresentativa(Archivos);
        if Fichero <> '' then
        begin
          FEntorno.Fotos.Sesion.Guardar(
            Seleccion.Serie,
            Seleccion.Numero,
            Seleccion.Linea,
            Seleccion.CodigoArticulo,
            '',
            Fichero,
            FEntorno.Usuario);
          RefrescarLista;
        end;
        LimpiarDescargaTemporal(Archivos);
        PublicarMensaje(Format(
          SInfoFotosArticuloDescargadas,
          [Length(Archivos), Seleccion.CodigoArticulo]));
      end;
    end;
  end;
end;

end.

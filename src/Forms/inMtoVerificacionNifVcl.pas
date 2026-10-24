{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerificacionNifVcl                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Botón «AEAT» junto al NIF de una ficha: verifica el NIF en el censo,      }
{    muestra el resultado y, si se pide, copia la razón social oficial.        }
{    El botón se crea en ejecución para no tocar el DFM de cada ficha.         }
{    FZ-ISSUE-131.                                                             }
{******************************************************************************}
unit inMtoVerificacionNifVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Vcl.Controls, Uni, cxButtons,
  inLibVerificacionNifRoi;

type
  TContextoVerificacionNifVcl = record
    // Editor del NIF: el botón se coloca a su derecha, quitándole ancho.
    EditorNif: TControl;
    DataSource: TDataSource;
    CampoNif: string;
    CampoNombre: string;
    // '' = no se guarda el resultado en el cliente.
    CampoCliente: string;
    // '' = se usa la empresa que devuelve EmpresaDefecto.
    CampoEmpresa: string;
    EmpresaDefecto: TFunc<string>;
    // Reserva si el dataset de la ficha no es UniDAC.
    Conexion: TUniConnection;
    Url: string;
    // Facturas: con el campo a 'S' el botón «AEAT» se cambia por «ROI»
    // (VIES) y consolidar exige el NIF-IVA válido. '' = sin ROI.
    CampoIntracomunitario: string;
    // Código de fza_paises del cliente: prefijo VIES si el NIF no lo
    // lleva.
    CampoPais: string;
    UrlRoi: string;
  end;

  TVerificacionNifVcl = class(TComponent)
  private
    FContexto: TContextoVerificacionNifVcl;
    FBoton: TcxButton;
    FBotonRoi: TcxButton;
    FEnlace: TDataLink;
    procedure CrearBoton;
    procedure CrearBotonRoi;
    procedure ActualizarBotones;
    function EsIntracomunitaria: Boolean;
    function ConsultarRoi: TResultadoVerificacionRoi;
    procedure BotonRoiClick(Sender: TObject);
    function ValorCampo(const ACampo: string): string;
    function EmpresaVerificacion: string;
    function ConexionVerificacion: TUniConnection;
    function PuedeCambiarNombre: Boolean;
    procedure AplicarRazonSocial(const ANombre: string);
    procedure BotonClick(Sender: TObject);
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoVerificacionNifVcl); reintroduce;
    destructor Destroy; override;
    // Antes de consolidar una factura intracomunitaria: True si el
    // NIF-IVA es válido en VIES, o si VIES no responde y el usuario
    // decide seguir. Sin CampoIntracomunitario o sin marcar, True.
    function ComprobarRoiAntesDeConsolidar: Boolean;
  end;

// El componente es propiedad de AOwner (la ficha) y se libera con ella.
function InstalarVerificacionNifVcl(
  AOwner: TComponent;
  const AContexto: TContextoVerificacionNifVcl): TVerificacionNifVcl;

implementation

uses
  Vcl.Dialogs, Vcl.Forms, System.UITypes,
  inLibMensajesVcl, inLibMsgVerificacionNif, inLibVerificacionNifIntf,
  inMtoModalVerificacionNif, UniDataVerificacionNifRepositorio;

const
  // A 96 ppp; se escala con el PPI del editor.
  ANCHO_BOTON = 58;
  SEPARACION = 4;
  // VIES devuelve '---' cuando el Estado no publica nombre ni dirección.
  SIN_DATOS_VIES = '---';

type
  // Cambia «AEAT»/«ROI» al moverse por las facturas o editar la marca.
  TEnlaceVerificacionNif = class(TDataLink)
  private
    FAlCambiar: TProc;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(const AAlCambiar: TProc);
  end;

constructor TEnlaceVerificacionNif.Create(const AAlCambiar: TProc);
begin
  inherited Create;
  FAlCambiar := AAlCambiar;
end;

procedure TEnlaceVerificacionNif.ActiveChanged;
begin
  inherited;
  FAlCambiar();
end;

procedure TEnlaceVerificacionNif.RecordChanged(Field: TField);
begin
  inherited;
  FAlCambiar();
end;

constructor TVerificacionNifVcl.Create(
  AOwner: TComponent;
  const AContexto: TContextoVerificacionNifVcl);
begin
  if not Assigned(AContexto.EditorNif) then
    raise EArgumentNilException.Create('EditorNif');
  if not Assigned(AContexto.DataSource) then
    raise EArgumentNilException.Create('DataSource');
  inherited Create(AOwner);
  FContexto := AContexto;
  CrearBoton;
  if FContexto.CampoIntracomunitario <> '' then
  begin
    CrearBotonRoi;
    FEnlace := TEnlaceVerificacionNif.Create(ActualizarBotones);
    FEnlace.DataSource := FContexto.DataSource;
    ActualizarBotones;
  end;
end;

destructor TVerificacionNifVcl.Destroy;
begin
  // Antes que los botones: el enlace los toca al soltar el DataSource.
  FreeAndNil(FEnlace);
  inherited;
end;

// Mismo sitio y tamaño que «AEAT»: sólo se ve uno de los dos.
procedure TVerificacionNifVcl.CrearBotonRoi;
begin
  FBotonRoi := TcxButton.Create(Self);
  FBotonRoi.Parent := FBoton.Parent;
  FBotonRoi.BoundsRect := FBoton.BoundsRect;
  FBotonRoi.Anchors := FBoton.Anchors;
  FBotonRoi.Caption := SCaptionBotonVerificarRoi;
  FBotonRoi.Hint := SHintBotonVerificarRoi;
  FBotonRoi.ShowHint := True;
  FBotonRoi.TabStop := False;
  FBotonRoi.Visible := False;
  FBotonRoi.OnClick := BotonRoiClick;
end;

function TVerificacionNifVcl.EsIntracomunitaria: Boolean;
begin
  Result := (FContexto.CampoIntracomunitario <> '') and
    SameText(ValorCampo(FContexto.CampoIntracomunitario), 'S');
end;

procedure TVerificacionNifVcl.ActualizarBotones;
var
  bIntracomunitaria: Boolean;
begin
  // Al cerrar la ficha sus paneles liberan los botones antes que a este
  // componente.
  if Assigned(FBotonRoi) and not (csDestroying in ComponentState) then
  begin
    bIntracomunitaria := EsIntracomunitaria;
    FBotonRoi.Visible := bIntracomunitaria;
    FBoton.Visible := not bIntracomunitaria;
  end;
end;

procedure TVerificacionNifVcl.CrearBoton;
var
  oEditor: TControl;
  iAncho: Integer;
  iSeparacion: Integer;
begin
  oEditor := FContexto.EditorNif;
  iAncho := oEditor.ScaleValue(ANCHO_BOTON);
  iSeparacion := oEditor.ScaleValue(SEPARACION);
  FBoton := TcxButton.Create(Self);
  FBoton.Parent := oEditor.Parent;
  oEditor.Width := oEditor.Width - iAncho - iSeparacion;
  FBoton.SetBounds(
    oEditor.Left + oEditor.Width + iSeparacion,
    oEditor.Top,
    iAncho,
    oEditor.Height);
  // Si el editor se estira con la ficha, el botón la acompaña a la
  // derecha.
  if akRight in oEditor.Anchors then
    FBoton.Anchors := [akTop, akRight]
  else
    FBoton.Anchors := [akLeft, akTop];
  FBoton.Caption := SCaptionBotonVerificarNif;
  FBoton.Hint := SHintBotonVerificarNif;
  FBoton.ShowHint := True;
  FBoton.TabStop := False;
  FBoton.OnClick := BotonClick;
end;

function TVerificacionNifVcl.ValorCampo(const ACampo: string): string;
var
  oDataSet: TDataSet;
  oCampo: TField;
begin
  Result := '';
  oDataSet := FContexto.DataSource.DataSet;
  if (ACampo <> '') and Assigned(oDataSet) and oDataSet.Active then
  begin
    oCampo := oDataSet.FindField(ACampo);
    if Assigned(oCampo) then
      Result := Trim(oCampo.AsString);
  end;
end;

function TVerificacionNifVcl.EmpresaVerificacion: string;
begin
  Result := ValorCampo(FContexto.CampoEmpresa);
  if (Result = '') and Assigned(FContexto.EmpresaDefecto) then
    Result := Trim(FContexto.EmpresaDefecto());
end;

// La de la ventana: guardar en el cliente por otra conexión esperaría
// al bloqueo de su propia edición.
function TVerificacionNifVcl.ConexionVerificacion: TUniConnection;
var
  oDataSet: TDataSet;
begin
  Result := nil;
  oDataSet := FContexto.DataSource.DataSet;
  if oDataSet is TCustomUniDataSet then
    Result := TCustomUniDataSet(oDataSet).Connection;
  if not Assigned(Result) then
    Result := FContexto.Conexion;
end;

function TVerificacionNifVcl.PuedeCambiarNombre: Boolean;
var
  oDataSet: TDataSet;
begin
  oDataSet := FContexto.DataSource.DataSet;
  Result := Assigned(oDataSet) and oDataSet.Active and
    (oDataSet.FindField(FContexto.CampoNombre) <> nil) and
    oDataSet.CanModify and
    ((oDataSet.State in dsEditModes) or FContexto.DataSource.AutoEdit);
end;

procedure TVerificacionNifVcl.AplicarRazonSocial(const ANombre: string);
var
  oDataSet: TDataSet;
begin
  oDataSet := FContexto.DataSource.DataSet;
  if not (oDataSet.State in dsEditModes) then
    oDataSet.Edit;
  oDataSet.FieldByName(FContexto.CampoNombre).AsString := Trim(ANombre);
end;

procedure TVerificacionNifVcl.BotonClick(Sender: TObject);
var
  Solicitud: TSolicitudVerificacionNif;
  Resultado: TResultadoVerificacionNif;
  oServicio: IServicioVerificacionNif;
  bVerificado: Boolean;
begin
  Solicitud := Default(TSolicitudVerificacionNif);
  Solicitud.Nif := ValorCampo(FContexto.CampoNif);
  Solicitud.Nombre := ValorCampo(FContexto.CampoNombre);
  Solicitud.CodigoEmpresa := EmpresaVerificacion;
  Solicitud.CodigoCliente := ValorCampo(FContexto.CampoCliente);
  bVerificado := False;
  Screen.Cursor := crHourGlass;
  try
    try
      oServicio := CrearServicioVerificacionNifAeat(
        ConexionVerificacion,
        FContexto.Url);
      Resultado := oServicio.Verificar(Solicitud);
      bVerificado := True;
    except
      // Error de datos, certificado, red o AEAT: se informa y la ficha
      // sigue como estaba.
      on E: EVerificacionNif do
        MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
      on E: Exception do
        MessageDlg_fza(Format(SErrorVerificacionNifFallo, [E.Message]),
          mtError, [mbOK], 0);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  if bVerificado and
     TfrmModalVerificacionNif.Ejecutar(Owner, Resultado,
       PuedeCambiarNombre) then
    AplicarRazonSocial(Resultado.NombreAeat);
end;

// Guarda en el cliente el resultado (válido o no; no el "no disponible").
function TVerificacionNifVcl.ConsultarRoi: TResultadoVerificacionRoi;
var
  oConexion: TUniConnection;
  sPais: string;
begin
  oConexion := ConexionVerificacion;
  Screen.Cursor := crHourGlass;
  try
    sPais := LeerCodigoAlpha2PaisVerificacion(oConexion,
      ValorCampo(FContexto.CampoPais));
    Result := VerificarNifRoi(ValorCampo(FContexto.CampoNif), sPais,
      FContexto.UrlRoi);
    GuardarResultadoVerificacionCliente(oConexion,
      ValorCampo(FContexto.CampoCliente),
      TextoResultadoVerificacionRoi(Result));
  finally
    Screen.Cursor := crDefault;
  end;
end;

function MensajeResultadoRoi(
  const AResultado: TResultadoVerificacionRoi): string;
var
  sNif: string;
begin
  sNif := AResultado.CodigoPais + AResultado.NumeroIva;
  case AResultado.Estado of
    evrValido:
      begin
        Result := Format(SVerificacionRoiValido, [sNif]);
        if (AResultado.Nombre <> '') and
           (AResultado.Nombre <> SIN_DATOS_VIES) then
          Result := Result + sLineBreak + sLineBreak +
            Format(SVerificacionRoiDatos,
              [AResultado.Nombre, AResultado.Direccion]);
      end;
    evrNoValido:
      Result := Format(SVerificacionRoiNoValido, [sNif]);
  else
    Result := Format(SVerificacionRoiNoDisponible,
      [sNif, AResultado.Detalle]);
  end;
end;

procedure TVerificacionNifVcl.BotonRoiClick(Sender: TObject);
var
  Resultado: TResultadoVerificacionRoi;
begin
  try
    Resultado := ConsultarRoi;
    if Resultado.Estado = evrValido then
      MessageDlg_fza(MensajeResultadoRoi(Resultado), mtInformation,
        [mbOK], 0)
    else
      MessageDlg_fza(MensajeResultadoRoi(Resultado), mtWarning,
        [mbOK], 0);
  except
    on E: EVerificacionNif do
      MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
    on E: Exception do
      MessageDlg_fza(Format(SErrorVerificacionNifFallo, [E.Message]),
        mtError, [mbOK], 0);
  end;
end;

function TVerificacionNifVcl.ComprobarRoiAntesDeConsolidar: Boolean;
var
  Resultado: TResultadoVerificacionRoi;
  sNif: string;
begin
  Result := not EsIntracomunitaria;
  if not Result then
  try
    Resultado := ConsultarRoi;
    sNif := Resultado.CodigoPais + Resultado.NumeroIva;
    case Resultado.Estado of
      evrValido:
        Result := True;
      evrNoValido:
        MessageDlg_fza(Format(SConsolidarRoiNoValido, [sNif]), mtError,
          [mbOK], 0);
    else
      Result := MessageDlg_fza(
        Format(SConsolidarRoiNoDisponible, [sNif, Resultado.Detalle]),
        mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes;
    end;
  except
    // Sin NIF o país fuera de la UE: no se consolida.
    on E: EVerificacionNif do
      MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
    on E: Exception do
      MessageDlg_fza(Format(SErrorVerificacionNifFallo, [E.Message]),
        mtError, [mbOK], 0);
  end;
end;

function InstalarVerificacionNifVcl(
  AOwner: TComponent;
  const AContexto: TContextoVerificacionNifVcl): TVerificacionNifVcl;
begin
  Result := TVerificacionNifVcl.Create(AOwner, AContexto);
end;

end.

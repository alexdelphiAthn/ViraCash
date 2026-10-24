{******************************************************************************}
{                                                                              }
{  Modulo:       inLibLectorDocumento                                          }
{    Tipo:       Libreria (controladora VCL)                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       09/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Lector de codigo de barras a nivel de formulario para las pantallas con  }
{    rejilla de lineas (pedidos, albaranes, facturas, documentos de trabajo,  }
{    traspasos). Reune lo que caja hacia a mano:                              }
{      - engancha TLectorScanner a OnKeyDown / OnKeyPress / OnShortCut del    }
{        formulario (KeyPreview) respetando los manejadores previos;          }
{      - al leer un codigo prepara el alta (cabecera persistida, lineas       }
{        abiertas, modo de entrada construido), lo resuelve sobre una linea   }
{        en blanco con el modo de entrada del grid y deja OTRA linea en       }
{        blanco con el editor abierto, lista para la siguiente lectura;       }
{      - avisa si el codigo no existe y, si el articulo pide color/talla,     }
{        deja el editor en esa misma linea sin saltar.                        }
{    El formulario solo aporta cierres con lo que sabe de si mismo            }
{    (TContextoLectorDocumento); la deteccion sigue en TLectorScanner y la    }
{    escritura de la linea en el modo de entrada (IModoEntradaGrid).          }
{    En las pantallas embebidas en pestanas del principal, OnKeyPress y       }
{    OnShortCut no llegan al formulario hijo por si solos: inMtoPrincipal     }
{    se los reenvia (PrevisualizarTeclaEmbebida e IsShortCut de la pestana).  }
{******************************************************************************}
unit inLibLectorDocumento;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Controls, Vcl.Forms,
  Data.DB, cxPC, cxGrid,
  inLibArticulosValidadorIntf, inLibColumnasSkuIntf, inLibLectorScanner,
  inLibLogIntf, inLibTrazabilidad, inLibAsignacionLoteLectura;

type
  TConsultaLectorDocumento = reference to function: Boolean;
  TAccionLectorDocumento = reference to procedure;
  TLineasLectorDocumento = reference to function: TDataSet;
  TValidadorLectorDocumento = reference to function: IArticulosValidador;
  TModoLectorDocumento = reference to function: IModoEntradaGrid;
  TResolverLectorDocumento = reference to function(
    const ACodigo: string): Boolean;
  TAvisoLectorDocumento = reference to procedure(const AMensaje: string);
  TEscribirLoteLectorDocumento = reference to procedure(
    const AAsignacion: TAsignacionLote);

  // F-LOTEC-012: lote o serie de la linea leida. Sin configurar
  // (o con AsignarLote sin valor) el lector se comporta como siempre.
  TTrazabilidadLectorDocumento = record
    // Decide el lote (CrearAsignarLoteLectura). False: no se da de alta
    // la linea (modal cancelado o lectura rechazada, ya avisado).
    AsignarLote: TAsignarLoteLectura;
    // Escribe lote, caducidad y cantidad en la linea actual
    // (EscribirLoteEnLinea con los campos del documento).
    EscribirLote: TEscribirLoteLectorDocumento;
  end;

  // Lo que el formulario sabe de si mismo y el lector necesita. Todo son
  // cierres para que el formulario no entregue sus componentes ni su modulo
  // de datos, que pueden recrearse mientras el lector vive.
  TContextoLectorDocumento = record
    // Formulario con KeyPreview cuyos eventos de teclado se encadenan.
    Formulario: TForm;
    // Rejilla de lineas: dentro de ella el detector por velocidad queda
    // pasivo (la celda de articulo resuelve el tecleo y el codigo+CR).
    Rejilla: TWinControl;
    // Se admite leer ahora (ficha visible, documento editable...).
    PuedeLeer: TConsultaLectorDocumento;
    // Deja el alta lista: cabecera persistida, lineas abiertas, modo de
    // entrada construido y foco en la rejilla. Opcional.
    PrepararAlta: TAccionLectorDocumento;
    // Dataset de lineas.
    Lineas: TLineasLectorDocumento;
    // Campos que, con valor, marcan que la linea actual ya lleva articulo.
    CamposArticulo: TArray<string>;
    // Validador con el que se comprueba el codigo antes de tocar la linea.
    Validador: TValidadorLectorDocumento;
    // Escribe el codigo en la linea actual (modo de entrada del grid).
    Resolver: TResolverLectorDocumento;
    // Como Resolver pero sin acumular en otra linea del mismo SKU: cada
    // lote o serie va en su linea. Opcional (sin el, Resolver).
    ResolverLinea: TResolverLectorDocumento;
    // Deja el editor abierto en la linea en blanco.
    MostrarEditor: TAccionLectorDocumento;
    // Sustituye a AsegurarLineaNuevaDocumento cuando el documento tiene su
    // propia forma de dejar una linea en blanco (traspasos). Opcional.
    PrepararLinea: TAccionLectorDocumento;
    // Sustituye al aviso estandar (pruebas). Opcional.
    MostrarAviso: TAvisoLectorDocumento;
    RegistroLog: IRegistroLog;
    procedure Validar;
  end;

  TLectorDocumento = class(TObject)
  private
    FContexto: TContextoLectorDocumento;
    FLector: TLectorScanner;
    FOnKeyDownPrevio: TKeyEvent;
    FOnKeyPressPrevio: TKeyPressEvent;
    FOnShortCutPrevio: TShortCutEvent;
    FProcesando: Boolean;
    FTrazabilidad: TTrazabilidadLectorDocumento;
    procedure EngancharEventos;
    procedure SoltarEventos;
    procedure FormularioKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormularioKeyPress(Sender: TObject; var Key: Char);
    procedure FormularioShortCut(var Msg: TWMKey; var Handled: Boolean);
    function EsControlRejilla(AControl: TControl): Boolean;
    procedure CodigoLeido(Sender: TObject; const ACodigo: string);
    procedure Avisar(const AMensaje: string);
    procedure RegistrarAviso(const ATexto: string);
    procedure PrepararLinea;
    procedure DarDeAltaLinea(const ACodigo: string);
    procedure DarDeAltaLineasConLote(const ACodigo: string;
      const AResolucion: TArtResolucionEntrada);
    function ResolverLinea(const ACodigo: string): Boolean;
  public
    constructor Create(const AContexto: TContextoLectorDocumento);
    destructor Destroy; override;
    // Da de alta la linea del codigo leido. Publico para las pruebas y para
    // otras vias de lectura del formulario.
    // Solo la trama STX/ETX del lector cuenta como lectura (FZ-ISSUE-230):
    // sin detector por velocidad.
    procedure ProcesarLectura(const ACodigo: string);
    // F-LOTEC-012: activa la asignacion de lote al leer.
    procedure ConfigurarTrazabilidad(
      const ATrazabilidad: TTrazabilidadLectorDocumento);
    // F-LOTEC-013: una linea por asignacion (lote o serie ya decididos),
    // sin acumular, y otra en blanco al final. Requiere la trazabilidad
    // configurada (EscribirLote).
    procedure DarDeAltaConAsignaciones(const ACodigo: string;
      const AAsignaciones: TArray<TAsignacionLote>);
  end;

// True si algun campo de articulo de la linea actual lleva valor.
function LineaDocumentoConArticulo(ALineas: TDataSet;
  const ACamposArticulo: array of string): Boolean;

// Deja la linea actual lista para escribir el siguiente articulo: postea la
// linea en curso si ya lleva articulo y anade una en blanco (sin postearla,
// como el boton "Anadir linea") o reutiliza la que ya este en blanco.
procedure AsegurarLineaNuevaDocumento(ALineas: TDataSet;
  const ACamposArticulo: array of string);

// Codigo que se escribe en la linea: el leido, salvo un GS1 (la cadena
// entera no es un codigo de linea), que se sustituye por su SKU.
function CodigoLineaLectura(const ACodigo: string;
  const AResolucion: TArtResolucionEntrada): string;

// Escribe en la linea actual el lote, la caducidad (vacia si no hay) y la
// cantidad de la asignacion. Un nombre de campo vacio no se escribe.
procedure EscribirLoteEnLinea(ALineas: TDataSet;
  const ACampoLote, ACampoCaducidad, ACampoCantidad: string;
  const AAsignacion: TAsignacionLote);

// True si hay cabecera sobre la que dar de alta lineas: dataset abierto con
// registro o en insercion.
function CabeceraDocumentoDisponible(ACabecera: TDataSet): Boolean;

// Lector para los documentos con pestana de lineas y modo de entrada del
// contrato IModoEntradaGrid: al leer, activa la pestana y enfoca la rejilla
// (cuyo OnEnter ya persiste la cabecera, abre las lineas y construye el
// modo), y resuelve con el modo que devuelva AModo en ese momento.
function CrearLectorDocumentoGrid(
  AFormulario: TForm; APaginas: TcxPageControl; APestana: TcxTabSheet;
  ARejilla: TcxGrid;
  const APuedeLeer: TConsultaLectorDocumento;
  const ALineas: TLineasLectorDocumento;
  const ACamposArticulo: array of string;
  const AValidador: TValidadorLectorDocumento;
  const AModo: TModoLectorDocumento;
  const ARegistroLog: IRegistroLog): TLectorDocumento;

implementation

uses
  inLibMensajesVcl, inLibMsgArticulos;

{ Funciones de dataset }

function LineaDocumentoConArticulo(ALineas: TDataSet;
  const ACamposArticulo: array of string): Boolean;
var
  sCampo: string;
  Campo: TField;
begin
  Result := False;
  if Assigned(ALineas) and ALineas.Active then
  begin
    for sCampo in ACamposArticulo do
    begin
      Campo := ALineas.FindField(sCampo);
      if Assigned(Campo) and (Trim(Campo.AsString) <> '') then
        Result := True;
    end;
  end;
end;

procedure AsegurarLineaNuevaDocumento(ALineas: TDataSet;
  const ACamposArticulo: array of string);
begin
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  if (ALineas.State in [dsEdit, dsInsert]) and
     LineaDocumentoConArticulo(ALineas, ACamposArticulo) then
    ALineas.Post;
  if ALineas.State = dsBrowse then
  begin
    if ALineas.IsEmpty or
       LineaDocumentoConArticulo(ALineas, ACamposArticulo) then
      ALineas.Append
    else
      ALineas.Edit;
  end;
end;

function CodigoLineaLectura(const ACodigo: string;
  const AResolucion: TArtResolucionEntrada): string;
begin
  if AResolucion.EsGs1 and (Trim(AResolucion.CodigoSku) <> '') then
    Result := AResolucion.CodigoSku
  else
    Result := ACodigo;
end;

procedure EscribirLoteEnLinea(ALineas: TDataSet;
  const ACampoLote, ACampoCaducidad, ACampoCantidad: string;
  const AAsignacion: TAsignacionLote);
begin
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  if not (ALineas.State in dsEditModes) then
    ALineas.Edit;
  if ACampoLote <> '' then
    ALineas.FieldByName(ACampoLote).AsString := AAsignacion.Lote;
  if ACampoCaducidad <> '' then
  begin
    if AAsignacion.FechaCaducidad = SIN_FECHA then
      ALineas.FieldByName(ACampoCaducidad).Clear
    else
      ALineas.FieldByName(ACampoCaducidad).AsDateTime :=
        AAsignacion.FechaCaducidad;
  end;
  if (ACampoCantidad <> '') and (AAsignacion.Cantidad <> 0) then
    ALineas.FieldByName(ACampoCantidad).AsFloat := AAsignacion.Cantidad;
end;

function CabeceraDocumentoDisponible(ACabecera: TDataSet): Boolean;
begin
  Result := Assigned(ACabecera) and ACabecera.Active and
    ((not ACabecera.IsEmpty) or (ACabecera.State in dsEditModes));
end;

function CrearLectorDocumentoGrid(
  AFormulario: TForm; APaginas: TcxPageControl; APestana: TcxTabSheet;
  ARejilla: TcxGrid;
  const APuedeLeer: TConsultaLectorDocumento;
  const ALineas: TLineasLectorDocumento;
  const ACamposArticulo: array of string;
  const AValidador: TValidadorLectorDocumento;
  const AModo: TModoLectorDocumento;
  const ARegistroLog: IRegistroLog): TLectorDocumento;
var
  Contexto: TContextoLectorDocumento;
  i: Integer;
begin
  if not Assigned(AModo) then
    raise EArgumentNilException.Create('AModo');
  Contexto := Default(TContextoLectorDocumento);
  Contexto.Formulario := AFormulario;
  Contexto.Rejilla := ARejilla;
  Contexto.PuedeLeer := APuedeLeer;
  Contexto.PrepararAlta :=
    procedure
    begin
      // El OnEnter de la rejilla ya persiste la cabecera, abre las lineas,
      // construye el modo de entrada y apaga el EnterAsTab del formulario.
      if Assigned(APaginas) and Assigned(APestana) then
        APaginas.ActivePage := APestana;
      if Assigned(ARejilla) and ARejilla.CanFocus then
        ARejilla.SetFocus;
    end;
  Contexto.Lineas := ALineas;
  SetLength(Contexto.CamposArticulo, Length(ACamposArticulo));
  for i := 0 to High(ACamposArticulo) do
    Contexto.CamposArticulo[i] := ACamposArticulo[i];
  Contexto.Validador := AValidador;
  Contexto.Resolver :=
    function(const ACodigo: string): Boolean
    var
      Modo: IModoEntradaGrid;
      Lectura: ILecturaModoEntrada;
    begin
      Modo := AModo();
      // FZ-ISSUE-232: la lectura acumula en la linea del mismo SKU.
      if Supports(Modo, ILecturaModoEntrada, Lectura) then
        Result := Lectura.ResolverLectura(ACodigo)
      else
        Result := Assigned(Modo) and Modo.ResolverEntrada(ACodigo);
    end;
  Contexto.ResolverLinea :=
    function(const ACodigo: string): Boolean
    var
      Modo: IModoEntradaGrid;
    begin
      Modo := AModo();
      Result := Assigned(Modo) and Modo.ResolverEntrada(ACodigo);
    end;
  Contexto.MostrarEditor :=
    procedure
    var
      Modo: IModoEntradaGrid;
    begin
      Modo := AModo();
      if Assigned(Modo) then
        Modo.MostrarEditor;
    end;
  Contexto.RegistroLog := ARegistroLog;
  Result := TLectorDocumento.Create(Contexto);
end;

{ TContextoLectorDocumento }

procedure TContextoLectorDocumento.Validar;
begin
  if not Assigned(Formulario) then
    raise EArgumentNilException.Create('Formulario');
  if not Assigned(PuedeLeer) then
    raise EArgumentNilException.Create('PuedeLeer');
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(Validador) then
    raise EArgumentNilException.Create('Validador');
  if not Assigned(Resolver) then
    raise EArgumentNilException.Create('Resolver');
  if not Assigned(MostrarEditor) then
    raise EArgumentNilException.Create('MostrarEditor');
  if (not Assigned(PrepararLinea)) and (Length(CamposArticulo) = 0) then
    raise EArgumentException.Create('CamposArticulo');
end;

{ TLectorDocumento }

constructor TLectorDocumento.Create(
  const AContexto: TContextoLectorDocumento);
begin
  inherited Create;
  AContexto.Validar;
  FContexto := AContexto;
  FLector := TLectorScanner.Create;
  // Modo "consumir": las teclas rapidas de la rafaga no llegan al control
  // con foco. Pasivo dentro de la rejilla: alli la celda de articulo ya
  // resuelve el tecleo y el codigo+CR con su propia logica. La trama
  // STX/ETX se captura siempre a nivel de formulario.
  FLector.ConsumirRafaga := True;
  FLector.OmitirEnRejilla := Assigned(FContexto.Rejilla);
  FLector.OnEsControlRejilla := EsControlRejilla;
  FLector.OnCodigoLeido := CodigoLeido;
  EngancharEventos;
end;

destructor TLectorDocumento.Destroy;
begin
  SoltarEventos;
  FreeAndNil(FLector);
  inherited Destroy;
end;

procedure TLectorDocumento.EngancharEventos;
begin
  FContexto.Formulario.KeyPreview := True;
  FOnKeyDownPrevio := FContexto.Formulario.OnKeyDown;
  FOnKeyPressPrevio := FContexto.Formulario.OnKeyPress;
  FOnShortCutPrevio := FContexto.Formulario.OnShortCut;
  FContexto.Formulario.OnKeyDown := FormularioKeyDown;
  FContexto.Formulario.OnKeyPress := FormularioKeyPress;
  FContexto.Formulario.OnShortCut := FormularioShortCut;
end;

procedure TLectorDocumento.SoltarEventos;
begin
  if Assigned(FContexto.Formulario) and
     not (csDestroying in FContexto.Formulario.ComponentState) then
  begin
    FContexto.Formulario.OnKeyDown := FOnKeyDownPrevio;
    FContexto.Formulario.OnKeyPress := FOnKeyPressPrevio;
    FContexto.Formulario.OnShortCut := FOnShortCutPrevio;
  end;
end;

// El lector va primero: cierra la rafaga por velocidad (consume el Enter)
// antes de que el formulario trate sus teclas de funcion.
procedure TLectorDocumento.FormularioKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  FLector.KeyDown(Key, Shift);
  if (Key <> 0) and Assigned(FOnKeyDownPrevio) then
    FOnKeyDownPrevio(Sender, Key, Shift);
end;

procedure TLectorDocumento.FormularioKeyPress(Sender: TObject;
  var Key: Char);
begin
  FLector.KeyPress(Key);
  if (Key <> #0) and Assigned(FOnKeyPressPrevio) then
    FOnKeyPressPrevio(Sender, Key);
end;

// OnShortCut se dispara en CN_KEYDOWN, antes que CM_DIALOGKEY (jvEnterTab
// convierte Enter en Tab) y que el boton con foco (Enter = clic): el Enter
// del lector se consume aqui para que nadie mas lo vea.
procedure TLectorDocumento.FormularioShortCut(var Msg: TWMKey;
  var Handled: Boolean);
begin
  Handled := FLector.AtajoTeclado(Msg);
  if (not Handled) and Assigned(FOnShortCutPrevio) then
    FOnShortCutPrevio(Msg, Handled);
end;

function TLectorDocumento.EsControlRejilla(AControl: TControl): Boolean;
var
  Control: TControl;
begin
  Result := False;
  Control := AControl;
  while (Control <> nil) and (not Result) do
  begin
    Result := Control = FContexto.Rejilla;
    Control := Control.Parent;
  end;
end;

procedure TLectorDocumento.CodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  ProcesarLectura(ACodigo);
end;

procedure TLectorDocumento.Avisar(const AMensaje: string);
begin
  if Assigned(FContexto.MostrarAviso) then
    FContexto.MostrarAviso(AMensaje)
  else
    ShowMessage_fza(AMensaje);
end;

procedure TLectorDocumento.RegistrarAviso(const ATexto: string);
begin
  if Assigned(FContexto.RegistroLog) then
    FContexto.RegistroLog.RegistrarAviso(ATexto);
end;

procedure TLectorDocumento.PrepararLinea;
begin
  if Assigned(FContexto.PrepararLinea) then
    FContexto.PrepararLinea()
  else
    AsegurarLineaNuevaDocumento(FContexto.Lineas(),
      FContexto.CamposArticulo);
end;

function MensajeCodigoNoEncontrado(
  const AResolucion: TArtResolucionEntrada;
  const ACodigo: string): string;
begin
  if Trim(AResolucion.Mensaje) <> '' then
    Result := AResolucion.Mensaje
  else
    Result := Format(SErrorArticuloEntradaNoEncontrado, [ACodigo]);
end;

// El codigo se comprueba ANTES de tocar la linea: un codigo desconocido no
// debe dejar una linea a medias, y hace falta saber si el articulo pide
// color/talla para decidir si se salta a la linea siguiente (SKU cerrado) o
// el editor se queda en esta para completarla.
procedure TLectorDocumento.DarDeAltaLinea(const ACodigo: string);
var
  Lineas: TDataSet;
  Resolucion: TArtResolucionEntrada;
  sCodigo: string;
begin
  if Assigned(FContexto.PrepararAlta) then
    FContexto.PrepararAlta();
  Lineas := FContexto.Lineas();
  if (not Assigned(Lineas)) or (not Lineas.Active) then
    RegistrarAviso(
      'LectorDocumento: sin lineas abiertas para "' + ACodigo + '"')
  else if not Lineas.CanModify then
    Avisar(SErrorLineasDocumentoNoEditables)
  else
  begin
    Resolucion := FContexto.Validador().Resolver(ACodigo);
    sCodigo := CodigoLineaLectura(ACodigo, Resolucion);
    if not Resolucion.Encontrado then
      Avisar(MensajeCodigoNoEncontrado(Resolucion, ACodigo))
    else if Assigned(FTrazabilidad.AsignarLote) and
            not Resolucion.RequiereSku then
      DarDeAltaLineasConLote(sCodigo, Resolucion)
    else
    begin
      PrepararLinea;
      if FContexto.Resolver(sCodigo) then
      begin
        if not Resolucion.RequiereSku then
          PrepararLinea;
        FContexto.MostrarEditor();
      end;
    end;
  end;
end;

function TLectorDocumento.ResolverLinea(const ACodigo: string): Boolean;
begin
  if Assigned(FContexto.ResolverLinea) then
    Result := FContexto.ResolverLinea(ACodigo)
  else
    Result := FContexto.Resolver(ACodigo);
end;

// F-LOTEC-012: el lote se decide antes de tocar la linea (un modal
// cancelado o una serie rechazada no dejan nada). Sin lote, el alta de
// siempre; con lote, una linea por asignacion sin acumular.
procedure TLectorDocumento.DarDeAltaLineasConLote(const ACodigo: string;
  const AResolucion: TArtResolucionEntrada);
var
  aAsignaciones: TArray<TAsignacionLote>;
begin
  if FTrazabilidad.AsignarLote(AResolucion, aAsignaciones) then
  begin
    if Length(aAsignaciones) = 0 then
    begin
      PrepararLinea;
      if FContexto.Resolver(ACodigo) then
      begin
        PrepararLinea;
        FContexto.MostrarEditor();
      end;
    end
    else
      DarDeAltaConAsignaciones(ACodigo, aAsignaciones);
  end;
end;

procedure TLectorDocumento.DarDeAltaConAsignaciones(const ACodigo: string;
  const AAsignaciones: TArray<TAsignacionLote>);
var
  iAsignacion: Integer;
  EsResuelta: Boolean;
begin
  if not Assigned(FTrazabilidad.EscribirLote) then
    raise EArgumentNilException.Create('EscribirLote');
  EsResuelta := False;
  for iAsignacion := 0 to High(AAsignaciones) do
  begin
    PrepararLinea;
    if ResolverLinea(ACodigo) then
    begin
      FTrazabilidad.EscribirLote(AAsignaciones[iAsignacion]);
      EsResuelta := True;
    end;
  end;
  if EsResuelta then
  begin
    PrepararLinea;
    FContexto.MostrarEditor();
  end;
end;

procedure TLectorDocumento.ConfigurarTrazabilidad(
  const ATrazabilidad: TTrazabilidadLectorDocumento);
begin
  if Assigned(ATrazabilidad.AsignarLote) and
     not Assigned(ATrazabilidad.EscribirLote) then
    raise EArgumentNilException.Create('EscribirLote');
  FTrazabilidad := ATrazabilidad;
end;

procedure TLectorDocumento.ProcesarLectura(const ACodigo: string);
var
  sCodigo: string;
begin
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (not FProcesando) and FContexto.PuedeLeer() then
  begin
    FProcesando := True;
    try
      try
        DarDeAltaLinea(sCodigo);
      except
        // Linea rechazada al grabar (lote, serie...): ya se ha avisado.
        on E: EAbort do
          RegistrarAviso('LectorDocumento: linea no grabada para "' +
            sCodigo + '"');
        on E: Exception do
        begin
          // El alta corre fuera del flujo de teclas (mensaje diferido del
          // lector): el error se ensena aqui, no se pierde.
          RegistrarAviso('LectorDocumento: ' + E.ClassName + ': ' +
            E.Message);
          Avisar(E.Message);
        end;
      end;
    finally
      FProcesando := False;
    end;
  end;
end;

end.

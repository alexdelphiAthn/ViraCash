{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoConteo                                               }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de conteo. Cada escaneo (Intro en el campo) genera un evento     }
{    con su día/hora y se encola en SQLite local. Botones para sincronizar     }
{    (subir la cola) y finalizar el recuento. UI por código (sin .fmx).        }
{******************************************************************************}
unit fRecuentoConteo;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.UITypes,
  System.IOUtils, RecuentoConfig,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.ListBox, FMX.Layouts,
  FMX.Types, FMX.DialogService,
  RecuentoModelo, RecuentoLocal, RecuentoApi, RecuentoSync, inLibGs1;

type
  // Un escaneo ya resuelto: SKU del catálogo (Indice < 0 = no
  // identificado) y, si los hay, lote y caducidad 'aaaa-mm-dd'.
  TLecturaRecuento = record
    Codigo: string;
    Sku: string;
    Articulo: string;
    Descripcion: string;
    Indice: Integer;
    Cantidad: Double;
    Lote: string;
    Caducidad: string;
  end;

  TfrmConteo = class(TForm)
  private
    FModo      : TModoRecuento;
    FIdRecuento: Int64;
    FCatalogo  : TArrCatalogo;
    FScan      : TEdit;
    FCantidad  : TEdit;
    FLista     : TListBox;
    FlblEstado : TLabel;
    function NuevoUuid: string;
    function BuscarEnCatalogo(const ACodigo: string): Integer;
    procedure Construir(const ATitulo: string);
    procedure Procesar(const ACodigo: string);
    function ResolverLectura(const ACodigo: string): TLecturaRecuento;
    function LeerCantidad(out ACantidad: Double): Boolean;
    function FechaCaducidadIso(const ATexto: string): string;
    procedure PedirLote(const ALectura: TLecturaRecuento);
    procedure Registrar(const ALectura: TLecturaRecuento);
    procedure AnadirLinea(const ATexto: string);
    procedure ActualizarEstado;
    procedure OnScanKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
                            Shift: TShiftState);
    procedure OnSincronizarClick(Sender: TObject);
    procedure OnFinalizarClick(Sender: TObject);
    procedure OnVolverClick(Sender: TObject);
  public
    class procedure IniciarAsync(AOwner: TComponent; AModo: TModoRecuento;
      AIdRecuento: Int64; const ACatalogo: TArrCatalogo; const ATitulo: string);
  end;

implementation

uses
  TraduccionMovil;

function TfrmConteo.NuevoUuid: string;
var
  g: TGUID;
begin
  CreateGUID(g);
  // GUIDToString devuelve '{....}': nos quedamos con los 36 chars de dentro.
  Result := LowerCase(Copy(GUIDToString(g), 2, 36));
end;

function TfrmConteo.BuscarEnCatalogo(const ACodigo: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := 0;
  while (Result < 0) and (i <= High(FCatalogo)) do
  begin
    if SameText(FCatalogo[i].CodigoBarras, ACodigo) or
       SameText(FCatalogo[i].CodigoUnidad, ACodigo) or
       SameText(FCatalogo[i].CodigoArticulo, ACodigo) then
      Result := i;
    Inc(i);
  end;
end;

procedure TfrmConteo.Construir(const ATitulo: string);
var
  lblTitulo: TLabel;
  layBotones: TLayout;
  btnVolver, btnSync, btnFin: TButton;
begin
  Self.Caption := ATitulo;
  FCantidad := nil;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 32;
  lblTitulo.Text := ATitulo;
  if FModo = mrCodigosCantidad then
  begin
    FCantidad := TEdit.Create(Self);
    FCantidad.Parent := Self;
    FCantidad.Align := TAlignLayout.Top;
    FCantidad.Height := 40;
    FCantidad.TextPrompt := Tr('Cantidad por escaneo');
    FCantidad.Text := '1';
  end;
  FScan := TEdit.Create(Self);
  FScan.Parent := Self;
  FScan.Align := TAlignLayout.Top;
  FScan.Height := 44;
  FScan.TextPrompt := Tr('Escanea o teclea el código y pulsa Intro');
  FScan.OnKeyDown := OnScanKeyDown;
  FlblEstado := TLabel.Create(Self);
  FlblEstado.Parent := Self;
  FlblEstado.Align := TAlignLayout.Top;
  FlblEstado.Height := 24;
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 56;
  btnVolver := TButton.Create(Self);
  btnVolver.Parent := layBotones;
  btnVolver.Align := TAlignLayout.Left;
  btnVolver.Width := 100;
  btnVolver.Text := Tr('Volver');
  btnVolver.OnClick := OnVolverClick;
  btnSync := TButton.Create(Self);
  btnSync.Parent := layBotones;
  btnSync.Align := TAlignLayout.Left;
  btnSync.Width := 130;
  btnSync.Text := Tr('Sincronizar');
  btnSync.OnClick := OnSincronizarClick;
  btnFin := TButton.Create(Self);
  btnFin.Parent := layBotones;
  btnFin.Align := TAlignLayout.Right;
  btnFin.Width := 130;
  btnFin.Text := Tr('Finalizar');
  btnFin.OnClick := OnFinalizarClick;
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
  ActualizarEstado;
end;

// Lectura resuelta contra el catálogo, con el lote y la caducidad que
// traiga el propio código (GS1-128 / DataMatrix: AI 01, 10, 17, 21).
function TfrmConteo.ResolverLectura(const ACodigo: string): TLecturaRecuento;
var
  Gs1: TResultadoGs1;
begin
  Result := Default(TLecturaRecuento);
  Result.Codigo := ACodigo;
  Result.Sku := ACodigo;
  Result.Descripcion := Tr('(no identificado)');
  Result.Indice := BuscarEnCatalogo(ACodigo);
  if (Result.Indice < 0) and EsLecturaGs1(ACodigo) then
  begin
    Gs1 := InterpretarGs1(ACodigo);
    if Gs1.EsValido then
    begin
      Result.Indice := BuscarEnCatalogo(Gs1.Datos.Gtin);
      if (Result.Indice < 0) and Gs1.Datos.Gtin.StartsWith('0') then
        Result.Indice := BuscarEnCatalogo(Copy(Gs1.Datos.Gtin, 2, 13));
      Result.Lote := Gs1.Datos.Lote;
      if Gs1.Datos.Serie <> '' then
        Result.Lote := Gs1.Datos.Serie;
      if Gs1.Datos.FechaCaducidad > 0 then
        Result.Caducidad := FormatDateTime('yyyy-mm-dd',
          Gs1.Datos.FechaCaducidad);
    end;
  end;
  if Result.Indice >= 0 then
  begin
    Result.Sku := FCatalogo[Result.Indice].CodigoUnidad;
    Result.Articulo := FCatalogo[Result.Indice].CodigoArticulo;
    Result.Descripcion := FCatalogo[Result.Indice].Descripcion;
  end;
  Result.Cantidad := 1;
  if (FModo = mrCodigosCantidad) and Assigned(FCantidad) then
    LeerCantidad(Result.Cantidad);
end;

// Cantidad del modo «con cantidad». Se acepta coma o punto: tras cambiar la
// coma por punto se lee con formato invariante (con la configuración
// española "2.5" daba 1). Texto no numérico, 0 o negativo: no válida.
function TfrmConteo.LeerCantidad(out ACantidad: Double): Boolean;
begin
  ACantidad := 1;
  Result := True;
  if (FModo = mrCodigosCantidad) and Assigned(FCantidad) then
    Result := TryStrToFloat(Trim(FCantidad.Text).Replace(',', '.'),
      ACantidad, TFormatSettings.Invariant) and (ACantidad > 0);
end;

// Fecha corta del idioma (FormatoIdioma), 'dd/mm/aaaa' o 'aaaa-mm-dd'
// a 'aaaa-mm-dd'; vacío si no es fecha.
function TfrmConteo.FechaCaducidadIso(const ATexto: string): string;
var
  dFecha: TDateTime;
  oFormato: TFormatSettings;
begin
  Result := '';
  oFormato := TFormatSettings.Create;
  oFormato.DateSeparator := '/';
  oFormato.ShortDateFormat := 'dd/mm/yyyy';
  if TryStrToDate(Trim(ATexto), dFecha, FormatoIdioma) then
    Result := FormatDateTime('yyyy-mm-dd', dFecha)
  else if TryStrToDate(Trim(ATexto), dFecha, oFormato) then
    Result := FormatDateTime('yyyy-mm-dd', dFecha)
  else if TryISO8601ToDate(Trim(ATexto), dFecha) then
    Result := FormatDateTime('yyyy-mm-dd', dFecha);
end;

// Artículo trazable leído sin lote: se pide antes de contarlo. Cancelar
// no cuenta nada.
procedure TfrmConteo.PedirLote(const ALectura: TLecturaRecuento);
var
  Lectura: TLecturaRecuento;
begin
  Lectura := ALectura;
  TDialogService.InputQuery(Tr('Lote o número de serie'),
    [Tr('Lote / serie'), Tr('Caducidad (dd/mm/aaaa, opcional)')], ['', ''],
    procedure(const AResultado: TModalResult; const AValores: array of string)
    begin
      if (AResultado = mrOk) and (Trim(AValores[0]) <> '') then
      begin
        Lectura.Lote := Trim(AValores[0]);
        Lectura.Caducidad := FechaCaducidadIso(AValores[1]);
        Registrar(Lectura);
      end
      else
      begin
        FScan.Text := '';
        FScan.SetFocus;
      end;
    end);
end;

procedure TfrmConteo.Registrar(const ALectura: TLecturaRecuento);
var
  Ev: TEventoRec;
  dTotal: Double;
  sDescripcion: string;
begin
  Ev := Default(TEventoRec);
  Ev.Uuid := NuevoUuid;
  Ev.CodigoBarras := ALectura.Codigo;
  Ev.CodigoUnidad := ALectura.Sku;
  Ev.CodigoArticulo := ALectura.Articulo;
  Ev.Cantidad := ALectura.Cantidad;
  Ev.Lote := ALectura.Lote;
  Ev.FechaCaducidad := ALectura.Caducidad;
  Ev.InstanteRecuento := FormatDateTime(
    'yyyy-mm-dd"T"hh":"nn":"ss"Z"',
    TDateTime.NowUTC);
  oLocal.Encolar(FIdRecuento, Ev);
  dTotal := oLocal.ContarPorSku(FIdRecuento, ALectura.Sku);
  sDescripcion := ALectura.Descripcion;
  if ALectura.Lote <> '' then
    sDescripcion := sDescripcion + ' · ' + ALectura.Lote;
  AnadirLinea(TrF('%s   +%g   (total %g)   %s',
    [ALectura.Sku, ALectura.Cantidad, dTotal, sDescripcion]));
  FScan.Text := '';
  FScan.SetFocus;
  ActualizarEstado;
end;

procedure TfrmConteo.Procesar(const ACodigo: string);
var
  Lectura: TLecturaRecuento;
  dCantidad: Double;
begin
  if (Trim(ACodigo) <> '') and not LeerCantidad(dCantidad) then
  begin
    // No se cuenta nada: el código queda en el campo para reintentar.
    TDialogService.ShowMessage(TrF(
      'La cantidad "%s" no es válida. Escribe un número mayor que 0.',
      [Trim(FCantidad.Text)]));
    FCantidad.SetFocus;
  end
  else if Trim(ACodigo) <> '' then
  begin
    Lectura := ResolverLectura(Trim(ACodigo));
    if (Lectura.Indice >= 0) and FCatalogo[Lectura.Indice].EsTrazable and
       (Lectura.Lote = '') then
      PedirLote(Lectura)
    else
      Registrar(Lectura);
  end;
end;

procedure TfrmConteo.AnadirLinea(const ATexto: string);
var
  oItem: TListBoxItem;
begin
  oItem := TListBoxItem.Create(FLista);
  oItem.Parent := FLista;
  oItem.Text := ATexto;
  oItem.Index := 0;
end;

procedure TfrmConteo.ActualizarEstado;
begin
  FlblEstado.Text := TrF('Pendientes de subir: %d',
    [oLocal.ContarPendientes(FIdRecuento)]);
end;

procedure TfrmConteo.OnScanKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    Procesar(FScan.Text);
  end;
end;

procedure TfrmConteo.OnSincronizarClick(Sender: TObject);
var
  oSync: TRecuentoSync;
  iSubidos: Integer;
  sMsg: string;
begin
  // TODO: mover a un hilo (TTask) para no bloquear la UI con la red.
  oSync := TRecuentoSync.Create;
  try
    if oSync.Sincronizar(FIdRecuento, iSubidos, sMsg) then
      TDialogService.ShowMessage(TrF('Subidos %d eventos', [iSubidos]))
    else
      TDialogService.ShowMessage(TrF('Error al sincronizar: %s', [sMsg]));
  finally
    FreeAndNil(oSync);
  end;
  ActualizarEstado;
end;

procedure TfrmConteo.OnFinalizarClick(Sender: TObject);
var
  oSync: TRecuentoSync;
  oApi: TRecuentoApi;
  iSubidos: Integer;
  sMsg: string;
begin
  // Subir lo pendiente y, si va bien, marcar el recuento como RECONTADO.
  oSync := TRecuentoSync.Create;
  oApi := TRecuentoApi.Create;
  try
    if not oSync.Sincronizar(FIdRecuento, iSubidos, sMsg) then
      TDialogService.ShowMessage(
        TrF('No se pudo subir todo antes de finalizar: %s', [sMsg]))
    else if oApi.Finalizar(FIdRecuento) then
    begin
      if RecuentoConfig.oConfig.CarpetaSesiones <> '' then
        TFile.Delete(TPath.Combine(RecuentoConfig.oConfig.CarpetaSesiones,
          'recuento_' + IntToStr(FIdRecuento) + '.json'));
      TDialogService.ShowMessage(Tr('Recuento finalizado y enviado'));
      ModalResult := mrOk;
    end
    else
      TDialogService.ShowMessage(
        TrF('No se pudo finalizar: %s', [oApi.UltimoError]));
  finally
    FreeAndNil(oApi);
    FreeAndNil(oSync);
  end;
end;

procedure TfrmConteo.OnVolverClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class procedure TfrmConteo.IniciarAsync(AOwner: TComponent;
  AModo: TModoRecuento; AIdRecuento: Int64; const ACatalogo: TArrCatalogo;
  const ATitulo: string);
var
  frm: TfrmConteo;
begin
  frm := TfrmConteo.CreateNew(AOwner);
  frm.FModo := AModo;
  frm.FIdRecuento := AIdRecuento;
  frm.FCatalogo := ACatalogo;
  frm.Construir(ATitulo);
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      // En Windows este callback corre dentro del cierre del modal: liberar
      // aquí el formulario provoca un access violation. Se difiere.
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.

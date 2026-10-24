{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoMenu                                                 }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Menú principal de la app (formulario principal). Tres opciones:           }
{      1) Recontar códigos de barras (=+1)                                     }
{      2) Recontar códigos de barras + cantidad                                }
{      3) Recoger plantilla de recuento                                        }
{    Las opciones 1/2 preguntan el almacén (recuento libre); la 3 exige        }
{    plantilla. UI por código (sin .fmx); el constructor usa CreateNew.        }
{******************************************************************************}
unit fRecuentoMenu;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  System.JSON, System.IOUtils,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Types,
  FMX.DialogService,
  RecuentoModelo, RecuentoConfig, RecuentoApi,
  fRecuentoSelector, fRecuentoConteo, fRecuentoConfig;

type
  TfrmMenu = class(TForm)
  private
    FAlmacenes : TArrAlmacen;
    FPlantillas: TArrPlantilla;
    function ComprobarConfig: Boolean;
    procedure ContinuarRecuento(Sender: TObject);
    procedure AbrirConteo(AModo: TModoRecuento; AId: Int64;
      const ACatalogo: TArrCatalogo; const ATitulo: string);
    procedure Construir;
    function NuevoBoton(const ATexto: string; AHandler: TNotifyEvent): TButton;
    procedure AccionLibre(AModo: TModoRecuento);
    procedure IniciarLibre(AModo: TModoRecuento; const AValor: string);
    procedure IniciarPlantilla(AId: Int64);
    procedure AbrirPlantilla(AId: Int64);
    procedure AccionTraspaso;
    procedure ElegirDestinoTraspaso(const AOrigen: string);
    procedure IniciarTraspaso(const AOrigen, ADestino: string);
    procedure OnTraspasoClick(Sender: TObject);
    procedure OnModo1Click(Sender: TObject);
    procedure OnModo2Click(Sender: TObject);
    procedure OnModo3Click(Sender: TObject);
    procedure OnConfigClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMenu: TfrmMenu;

implementation

uses
  TraduccionMovil, TextosRecuento;

constructor TfrmMenu.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Construir;
end;

function TfrmMenu.NuevoBoton(const ATexto: string;
  AHandler: TNotifyEvent): TButton;
var
  btn: TButton;
begin
  btn := TButton.Create(Self);
  btn.Parent := Self;
  btn.Align := TAlignLayout.Top;
  btn.Height := 64;
  btn.Margins.Left := 12;
  btn.Margins.Right := 12;
  btn.Margins.Top := 12;
  btn.Text := ATexto;
  btn.OnClick := AHandler;
  Result := btn;
end;

procedure TfrmMenu.Construir;
var
  lblTitulo: TLabel;
begin
  Self.Caption := Tr('Recuento ViraCash');
  // Align=Top: el primero creado queda arriba; este es el orden visible.
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 48;
  lblTitulo.Text := Tr('Recuento de inventarios');
  NuevoBoton(Tr('1 · Recontar códigos de barras'), OnModo1Click);
  NuevoBoton(Tr('2 · Recontar códigos de barras + cantidad'),
    OnModo2Click);
  NuevoBoton(Tr('3 · Recoger plantilla de recuento'), OnModo3Click);
  NuevoBoton(Tr('4 · Traspaso entre almacenes'), OnTraspasoClick);
  if oConfig.CarpetaSesiones <> '' then
    NuevoBoton(Tr('Continuar recuento guardado'), ContinuarRecuento);
  NuevoBoton(Tr('Configuración'), OnConfigClick);
end;

function TfrmMenu.ComprobarConfig: Boolean;
begin
  Result := oConfig.EstaConfigurado;
  if not Result then
    TDialogService.ShowMessage(Tr(
      'Antes configura la URL del servidor y la clave API ' +
      '(botón Configuración).'));
end;

procedure TfrmMenu.AccionLibre(AModo: TModoRecuento);
var
  oApi: TRecuentoApi;
  aCaptions, aValores: TArray<string>;
  i: Integer;
begin
  if ComprobarConfig then
  begin
    // TODO: mover la llamada de red a un hilo (TTask) para no bloquear la UI.
    oApi := TRecuentoApi.Create;
    try
      if not oApi.ListarAlmacenes(FAlmacenes) then
        TDialogService.ShowMessage(
          TrF('Error: %s', [oApi.UltimoError]))
      else if Length(FAlmacenes) = 0 then
        TDialogService.ShowMessage(
          Tr('No hay almacenes sincronizados en el servidor.'))
      else
      begin
        SetLength(aCaptions, Length(FAlmacenes));
        SetLength(aValores, Length(FAlmacenes));
        for i := 0 to High(FAlmacenes) do
        begin
          aCaptions[i] := FAlmacenes[i].CodigoAlm + ' - ' +
                          FAlmacenes[i].Nombre;
          aValores[i] := FAlmacenes[i].CodigoEmp + '|' + FAlmacenes[i].CodigoAlm;
        end;
        TfrmSelector.ElegirAsync(Self, Tr('Elige almacén'),
          aCaptions, aValores,
          procedure(AOk: Boolean; AValor: string)
          begin
            if AOk and (AValor <> '') then
              IniciarLibre(AModo, AValor);
          end);
      end;
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.IniciarLibre(AModo: TModoRecuento; const AValor: string);
var
  oApi: TRecuentoApi;
  aPartes: TArray<string>;
  sEmp, sAlm: string;
  idRec: Int64;
begin
  aPartes := AValor.Split(['|']);
  if Length(aPartes) = 2 then
  begin
    sEmp := aPartes[0];
    sAlm := aPartes[1];
    oApi := TRecuentoApi.Create;
    try
      if oApi.CrearRecuentoLibre(sEmp, sAlm, '', idRec) then
        AbrirConteo( AModo, idRec, [],
          TrF('Almacén %s', [sAlm]))
      else
        TDialogService.ShowMessage(
          TrF('No se pudo crear el recuento: %s', [oApi.UltimoError]));
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.IniciarPlantilla(AId: Int64);
var
  i: Integer;
  bTerminada: Boolean;
begin
  bTerminada := False;
  for i := 0 to High(FPlantillas) do
    if FPlantillas[i].IdRecuento = AId then
      bTerminada := FPlantillas[i].Estado = 'RECONTADO';
  if not bTerminada then
    AbrirPlantilla(AId)
  else
    // Terminada en el móvil y sin recoger: se puede reabrir para seguir.
    TDialogService.MessageDialog(Tr(
      'Este recuento ya está terminado y ViraCash aún no lo ha recogido. ' +
      '¿Reabrirlo para seguir contando?'),
      TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0,
      procedure(const AResultado: TModalResult)
      var
        oApi: TRecuentoApi;
      begin
        if AResultado = mrYes then
        begin
          oApi := TRecuentoApi.Create;
          try
            if oApi.Reabrir(AId) then
              AbrirPlantilla(AId)
            else
              TDialogService.ShowMessage(TrF(
                'No se pudo reabrir el recuento: %s', [oApi.UltimoError]));
          finally
            FreeAndNil(oApi);
          end;
        end;
      end);
end;

procedure TfrmMenu.AbrirPlantilla(AId: Int64);
var
  oApi: TRecuentoApi;
  aCatalogo: TArrCatalogo;
begin
  oApi := TRecuentoApi.Create;
  try
    if oApi.DescargarCatalogo(AId, aCatalogo) then
      AbrirConteo( mrPlantilla, AId, aCatalogo,
        TrF('Plantilla %d', [AId]))
    else
      TDialogService.ShowMessage(
        TrF('No se pudo descargar la plantilla: %s', [oApi.UltimoError]));
  finally
    FreeAndNil(oApi);
  end;
end;

procedure TfrmMenu.AbrirConteo(AModo: TModoRecuento; AId: Int64;
  const ACatalogo: TArrCatalogo; const ATitulo: string);
var
  oSesion, oItem: TJSONObject;
  oCatalogo: TJSONArray;
  rItem: TItemCatalogoRec;
begin
  if oConfig.CarpetaSesiones <> '' then
  begin
    oSesion := TJSONObject.Create;
    try
      oSesion.AddPair('id', TJSONNumber.Create(AId));
      oSesion.AddPair('modo', TJSONNumber.Create(Ord(AModo)));
      oSesion.AddPair('titulo', ATitulo);
      oCatalogo := TJSONArray.Create;
      oSesion.AddPair('catalogo', oCatalogo);
      for rItem in ACatalogo do
      begin
        oItem := TJSONObject.Create;
        oCatalogo.AddElement(oItem);
        oItem.AddPair('articulo', rItem.CodigoArticulo);
        oItem.AddPair('unidad', rItem.CodigoUnidad);
        oItem.AddPair('barras', rItem.CodigoBarras);
        oItem.AddPair('descripcion', rItem.Descripcion);
        oItem.AddPair('teorica', TJSONNumber.Create(rItem.CantidadTeorica));
        oItem.AddPair('trazable', TJSONBool.Create(rItem.EsTrazable));
      end;
      TFile.WriteAllText(TPath.Combine(oConfig.CarpetaSesiones,
        'recuento_' + IntToStr(AId) + '.json'), oSesion.ToJSON,
        TEncoding.UTF8);
    finally
      oSesion.Free;
    end;
  end;
  TfrmConteo.IniciarAsync(Self, AModo, AId, ACatalogo, ATitulo);
end;

procedure TfrmMenu.ContinuarRecuento(Sender: TObject);
var
  aArchivos, aTitulos: TArray<string>;
  i: Integer;
begin
  aArchivos := TDirectory.GetFiles(oConfig.CarpetaSesiones,
    'recuento_*.json');
  SetLength(aTitulos, Length(aArchivos));
  for i := 0 to High(aArchivos) do
    aTitulos[i] := TPath.GetFileNameWithoutExtension(aArchivos[i]);
  if Length(aArchivos) = 0 then
    TDialogService.ShowMessage(Tr('No hay recuentos guardados.'))
  else
    TfrmSelector.ElegirAsync(Self, Tr('Continuar recuento'), aTitulos,
      aArchivos,
      procedure(AOk: Boolean; ARuta: string)
      var
        oSesion: TJSONValue;
        oCatalogo: TJSONArray;
        aCatalogo: TArrCatalogo;
        j: Integer;
      begin
        if AOk then
        begin
          oSesion := TJSONObject.ParseJSONValue(TFile.ReadAllText(ARuta));
          try
            oCatalogo := oSesion.GetValue<TJSONArray>('catalogo');
            SetLength(aCatalogo, oCatalogo.Count);
            for j := 0 to oCatalogo.Count - 1 do
            begin
              aCatalogo[j].CodigoArticulo :=
                oCatalogo.Items[j].GetValue<string>('articulo');
              aCatalogo[j].CodigoUnidad :=
                oCatalogo.Items[j].GetValue<string>('unidad');
              aCatalogo[j].CodigoBarras :=
                oCatalogo.Items[j].GetValue<string>('barras');
              aCatalogo[j].Descripcion :=
                oCatalogo.Items[j].GetValue<string>('descripcion');
              aCatalogo[j].CantidadTeorica :=
                oCatalogo.Items[j].GetValue<Double>('teorica');
              aCatalogo[j].EsTrazable :=
                oCatalogo.Items[j].GetValue<Boolean>('trazable');
            end;
            AbrirConteo(TModoRecuento(oSesion.GetValue<Integer>('modo')),
              oSesion.GetValue<Int64>('id'), aCatalogo,
              oSesion.GetValue<string>('titulo'));
          finally
            oSesion.Free;
          end;
        end;
      end);
end;

procedure TfrmMenu.OnModo1Click(Sender: TObject);
begin
  AccionLibre(mrCodigos);
end;

procedure TfrmMenu.OnModo2Click(Sender: TObject);
begin
  AccionLibre(mrCodigosCantidad);
end;

procedure TfrmMenu.OnModo3Click(Sender: TObject);
var
  oApi: TRecuentoApi;
  aCaptions, aValores: TArray<string>;
  i: Integer;
  sCap: string;
begin
  if ComprobarConfig then
  begin
    oApi := TRecuentoApi.Create;
    try
      if not oApi.ListarPlantillas(FPlantillas) then
        TDialogService.ShowMessage(
          TrF('Error: %s', [oApi.UltimoError]))
      else if Length(FPlantillas) = 0 then
        TDialogService.ShowMessage(
          Tr('No hay plantillas pendientes en el servidor.'))
      else
      begin
        SetLength(aCaptions, Length(FPlantillas));
        SetLength(aValores, Length(FPlantillas));
        for i := 0 to High(FPlantillas) do
        begin
          sCap := FPlantillas[i].Descripcion;
          if Trim(sCap) = '' then
            sCap := FPlantillas[i].Serie + '/' + FPlantillas[i].Numero +
                    ' (' + FPlantillas[i].CodigoAlm + ')';
          if FPlantillas[i].Estado = 'RECONTADO' then
            sCap := sCap + Tr(' (terminado)');
          aCaptions[i] := sCap;
          aValores[i] := IntToStr(FPlantillas[i].IdRecuento);
        end;
        TfrmSelector.ElegirAsync(Self, Tr('Elige plantilla'),
          aCaptions, aValores,
          procedure(AOk: Boolean; AValor: string)
          begin
            if AOk and (AValor <> '') then
              IniciarPlantilla(StrToInt64Def(AValor, 0));
          end);
      end;
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.OnConfigClick(Sender: TObject);
begin
  if oConfig.ConfiguracionCentral then
    TDialogService.ShowMessage(
      Tr('Configuración en el menú de ViraCash móvil.'))
  else
    TfrmConfig.EditarAsync(Self, nil);
end;

// ============================================================================
//   TRASPASO ENTRE ALMACENES (parte del cliente)
// ============================================================================

procedure TfrmMenu.OnTraspasoClick(Sender: TObject);
begin
  AccionTraspaso;
end;

procedure TfrmMenu.AccionTraspaso;
var
  oApi: TRecuentoApi;
  aCaptions, aValores: TArray<string>;
  i: Integer;
begin
  if ComprobarConfig then
  begin
    // TODO: mover la llamada de red a un hilo (TTask) para no bloquear la UI.
    oApi := TRecuentoApi.Create;
    try
      if not oApi.ListarAlmacenes(FAlmacenes) then
        TDialogService.ShowMessage(
          TrF('Error: %s', [oApi.UltimoError]))
      else if Length(FAlmacenes) = 0 then
        TDialogService.ShowMessage(
          Tr('No hay almacenes sincronizados en el servidor.'))
      else
      begin
        SetLength(aCaptions, Length(FAlmacenes));
        SetLength(aValores, Length(FAlmacenes));
        for i := 0 to High(FAlmacenes) do
        begin
          aCaptions[i] := FAlmacenes[i].CodigoAlm + ' - ' +
                          FAlmacenes[i].Nombre;
          aValores[i] := FAlmacenes[i].CodigoEmp + '|' + FAlmacenes[i].CodigoAlm;
        end;
        TfrmSelector.ElegirAsync(Self, Tr('Almacén ORIGEN'),
          aCaptions, aValores,
          procedure(AOk: Boolean; AValor: string)
          begin
            if AOk and (AValor <> '') then
              ElegirDestinoTraspaso(AValor);
          end);
      end;
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.ElegirDestinoTraspaso(const AOrigen: string);
var
  aCaptions, aValores: TArray<string>;
  i: Integer;
begin
  // Reutilizamos FAlmacenes ya cargado en AccionTraspaso.
  SetLength(aCaptions, Length(FAlmacenes));
  SetLength(aValores, Length(FAlmacenes));
  for i := 0 to High(FAlmacenes) do
  begin
    aCaptions[i] := FAlmacenes[i].CodigoAlm + ' - ' + FAlmacenes[i].Nombre;
    aValores[i] := FAlmacenes[i].CodigoEmp + '|' + FAlmacenes[i].CodigoAlm;
  end;
  TfrmSelector.ElegirAsync(Self, Tr('Almacén DESTINO'),
    aCaptions, aValores,
    procedure(AOk: Boolean; AValor: string)
    begin
      if AOk and (AValor <> '') then
        IniciarTraspaso(AOrigen, AValor);
    end);
end;

procedure TfrmMenu.IniciarTraspaso(const AOrigen, ADestino: string);
var
  oApi: TRecuentoApi;
  aOri, aDes: TArray<string>;
  idRec: Int64;
begin
  aOri := AOrigen.Split(['|']);
  aDes := ADestino.Split(['|']);
  if (Length(aOri) = 2) and (Length(aDes) = 2) then
  begin
    if SameText(aOri[1], aDes[1]) then
      TDialogService.ShowMessage(
        Tr('El origen y el destino no pueden ser el mismo almacén.'))
    else
    begin
      oApi := TRecuentoApi.Create;
      try
        // El traspaso se cuenta por cantidad (cajas/unidades a mover).
        if oApi.CrearTraspaso(aOri[0], aOri[1], aDes[1], idRec) then
          AbrirConteo( mrCodigosCantidad, idRec, [],
            TrF('Traspaso %s -> %s', [aOri[1], aDes[1]]))
        else
          TDialogService.ShowMessage(
            TrF('No se pudo crear el traspaso: %s', [oApi.UltimoError]));
      finally
        FreeAndNil(oApi);
      end;
    end;
  end;
end;

end.

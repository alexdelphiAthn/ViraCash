{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasSimplif                                          }
{    Tipo:       Formulario (Mto) descendiente                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de facturas SIMPLIFICADAS (caja / tickets).                      }
{    Descendiente de TfrmMtoFacturasBase: consulta vi_facturas_simplificadas   }
{    en el listado y deja TIPO_FAC = 'SIMPLIFICADA' por defecto al insertar.   }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista (la     }
{    vista completa tardaba demasiado: precargamos solo el año en curso).      }
{******************************************************************************}
unit inMtoFacturasSimplif;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxButtons,
  cxCheckBox, cxCheckComboBox, Uni,
  inLibPerfilesUsuarioIntf, UniDataFacturas, inMtoFacturasBase, cxStyles,
  Data.DB,
  cxDBData, cxCalendar, cxCurrencyEdit, cxTextEdit, cxSpinEdit, cxButtonEdit,
  cxDropDownEdit, cxMemo, cxDBLookupComboBox, cxBlobEdit, Vcl.Menus, JvBaseDlg,
  JvCalc, dxShellDialogs, System.Actions, Vcl.ActnList, JvComponentBase,
  JvEnterTab, cxLocalization, cxRadioGroup, cxNavigator, cxDBNavigator,
  cxSplitter, cxGroupBox, cxDBLabel, cxDBEdit, cxImage, Vcl.Buttons,
  cxLookupEdit, cxDBLookupEdit, cxMaskEdit, cxGridBandedTableView,
  cxGridDBBandedTableView, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxClasses, cxGridCustomView, cxGrid, cxPC,
  inLibVentasPantallaIntf;

type
  TfrmMtoFacturasSimplif = class(TfrmMtoFacturasBase)
    pnlFiltros: TPanel;
    btnToggleFiltros: TcxButton;
    pnlContFiltros: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    // Pestana propia: una factura de caja no lleva recibos, lleva
    // los pagos con los que se liquido la operacion del TPV.
    tsPagosCaja: TcxTabSheet;
    pnlRightPagosCaja: TPanel;
    btnIrAPagosCaja: TcxButton;
    pnlBodyPagosCaja: TPanel;
    cxgrdPagosCaja: TcxGrid;
    tvPagosCaja: TcxGridDBTableView;
    cxgrdlvlPagosCaja: TcxGridLevel;
    colPagoLinea: TcxGridDBColumn;
    colPagoFormaPago: TcxGridDBColumn;
    colPagoDescripcion: TcxGridDBColumn;
    colPagoEntregado: TcxGridDBColumn;
    colPagoCambio: TcxGridDBColumn;
    colPagoDivisa: TcxGridDBColumn;
    colPagoImporteDivisa: TcxGridDBColumn;
    colPagoReferencia: TcxGridDBColumn;
    colPagoObservaciones: TcxGridDBColumn;
    procedure btnIrAPagosCajaClick(Sender: TObject);
    procedure btnToggleFiltrosClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Guarda contra reentrada mientras inicializamos los combos.
    FFiltrosCargando: Boolean;
    // El base engancha pcDetail.OnChange en CrearTablaPrincipal;
    // aqui se encadena para abrir ademas los pagos de caja.
    FCambioDetalleBase: TNotifyEvent;
    // La carga inicial con barra de progreso se hace una sola vez.
    FCargaInicialHecha: Boolean;
    // Evita reentradas si la UI dispara eventos durante la apertura.
    FAbriendoConProgreso: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    FRepositorioListado: IRepositorioFacturasSimplificadasPantalla;
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function RecogerFiltros: TFiltrosFacturasSimplificadas;
    function  ContarFacturas: Integer;
    procedure AplicarFiltrosFacturas;
    procedure AbrirConProgreso;
    procedure MostrarProgresoCarga(const AMax: Integer);
    procedure ActualizarProgresoCarga(const APos, AMax: Integer);
    procedure OcultarProgresoCarga;
    procedure PrepararPestanaPagosCaja;
    procedure CambioDetalleConPagosCaja(Sender: TObject);
  public
    function NombreVistaListado: string; override;
    function TipoFacturaFiltro: string; override;
    function AbrirListadoAlCrear: Boolean; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibUser, inLibMsgComun, inLibMsgFacturas, inLibShowMto,
  UniDataVentasPantallaComposicion;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoFacturasSimplif }

function TfrmMtoFacturasSimplif.NombreVistaListado: string;
begin
  Result := 'vi_facturas_simplificadas';
end;

function TfrmMtoFacturasSimplif.TipoFacturaFiltro: string;
begin
  Result := 'SIMPLIFICADA';
end;

function TfrmMtoFacturasSimplif.AbrirListadoAlCrear: Boolean;
begin
  // No abrimos la vista completa en CrearTablaPrincipal: la abrimos ya
  // filtrada (año en curso por defecto) y con barra de progreso en
  // ResetForm, evitando el SELECT * de toda la vista (decenas de segundos).
  Result := False;
end;

procedure TfrmMtoFacturasSimplif.CrearTablaPrincipal;
var
  Contexto: TContextoFacturasSimplificadasVentasPantalla;
begin
  inherited;
  CrearContextoVentasPantalla(
    dmmFacturas.unqryTablaG.Connection,
    dmmFacturas.unqryTablaG,
    ContextoSesion,
    ParametrosApp,
    Contexto);
  FRepositorioListado := Contexto.Repositorio;
  // Persiana de filtros de carga: arranca colapsada (igual que articulos).
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. La
  // apertura con barra de progreso se hace en ResetForm, ya con el form
  // visible. La conexion ya esta asignada tras 'inherited'.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  FRepositorioListado.ConfigurarListado(RecogerFiltros);
  PrepararPestanaPagosCaja;
end;

procedure TfrmMtoFacturasSimplif.PrepararPestanaPagosCaja;
begin
  // El origen de datos se crea en el modulo de datos, asi que
  // no puede venir puesto desde el DFM.
  tvPagosCaja.DataController.DataSource :=
    dmmFacturas.dsPagosCajaFac;
  FCambioDetalleBase := pcDetail.OnChange;
  pcDetail.OnChange := CambioDetalleConPagosCaja;
end;

procedure TfrmMtoFacturasSimplif.CambioDetalleConPagosCaja(
  Sender: TObject);
begin
  if Assigned(FCambioDetalleBase) then
    FCambioDetalleBase(Sender);
  if pcDetail.ActivePage = tsPagosCaja then
    dmmFacturas.AsegurarPagosCajaFacAbierta;
end;

procedure TfrmMtoFacturasSimplif.btnIrAPagosCajaClick(
  Sender: TObject);
var
  oPagos: TDataSet;
  sClave: string;
begin
  // El historico localiza por su clave completa, seis campos
  // separados por comas y en este orden. Con un solo valor no
  // encuentra nada.
  oPagos := dmmFacturas.unqryPagosCajaFac;
  if (not oPagos.Active) or oPagos.IsEmpty then
  begin
    ShowMessage_fza(SAvisoSinPagosCajaFactura);
    Abort;
  end;
  sClave :=
    oPagos.FieldByName('CODIGO_EMP_PAGO').AsString + ',' +
    oPagos.FieldByName('CODIGO_ALM_PAGO').AsString + ',' +
    oPagos.FieldByName('CODIGO_CAJA_PAGO').AsString + ',' +
    oPagos.FieldByName('SERIE_OPERACION_PAGO').AsString + ',' +
    oPagos.FieldByName('NUMERO_OPERACION_PAGO').AsString + ',' +
    oPagos.FieldByName('NUMERO_LINEA_PAGO').AsString;
  ShowMto(Self.Owner, 'CajaPagosHist', sClave);
end;

procedure TfrmMtoFacturasSimplif.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales (la de busqueda Ctrl+R la maneja PrepararBusquedaExterna).
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoFacturasSimplif.CargarAnyosFiltro;
var
  Anyos: TArray<Integer>;
  iAnyo: Integer;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  Anyos := FRepositorioListado.ListarAnyos;
  for iAnyo := 0 to High(Anyos) do
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := IntToStr(Anyos[iAnyo]);
    if item.Description = sAnyoActual then
      bExisteActual := True;
  end;
  // El año en curso es el valor por defecto: lo añadimos aunque no tenga
  // facturas todavia para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoFacturasSimplif.CargarAlmacenesFiltro;
var
  Almacenes: TAlmacenesFiltroFacturaSimplificada;
  iAlmacen: Integer;
  item: TcxCheckComboBoxItem;
begin
  ccbFiltroAlmacen.Properties.Items.Clear;
  if FCodigosAlmacen = nil then
    FCodigosAlmacen := TStringList.Create
  else
    FCodigosAlmacen.Clear;
  Almacenes := FRepositorioListado.ListarAlmacenes;
  for iAlmacen := 0 to High(Almacenes) do
  begin
    item := ccbFiltroAlmacen.Properties.Items.Add;
    item.Description := Almacenes[iAlmacen].Codigo + ' - ' +
      Almacenes[iAlmacen].Nombre;
    FCodigosAlmacen.Add(Almacenes[iAlmacen].Codigo);
  end;
end;

procedure TfrmMtoFacturasSimplif.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  FFiltrosCargando := True;
  try
    // Por defecto: año en curso marcado; ningun almacen marcado (= todos).
    sAnyosCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAnyos',
                                   IntToStr(YearOf(Date)));
    sAlmCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacenes', '');
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sAnyosCsv;
      for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      begin
        if lst.IndexOf(ccbFiltroAnyo.Properties.Items[i].Description) >= 0 then
          ccbFiltroAnyo.States[i] := cbsChecked
        else
          ccbFiltroAnyo.States[i] := cbsUnchecked;
      end;
      lst.DelimitedText := sAlmCsv;
      for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      begin
        if (i < FCodigosAlmacen.Count) and
           (lst.IndexOf(FCodigosAlmacen[i]) >= 0) then
          ccbFiltroAlmacen.States[i] := cbsChecked
        else
          ccbFiltroAlmacen.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosCargando := False;
  end;
end;

procedure TfrmMtoFacturasSimplif.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  inherited;
  if Assigned(ccbFiltroAnyo) then
  begin
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    sAnyos := '';
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
    begin
      if ccbFiltroAnyo.States[i] = cbsChecked then
      begin
        if sAnyos <> '' then
          sAnyos := sAnyos + ';';
        sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
      end;
    end;
    item.SubKey := 'oFiltroAnyos';
    item.Value := sAnyos;
    oList.Add(item);
    sAlmacenes := '';
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
    begin
      if (ccbFiltroAlmacen.States[i] = cbsChecked) and
         (i < FCodigosAlmacen.Count) then
      begin
        if sAlmacenes <> '' then
          sAlmacenes := sAlmacenes + ';';
        sAlmacenes := sAlmacenes + FCodigosAlmacen[i];
      end;
    end;
    item.SubKey := 'oFiltroAlmacenes';
    item.Value := sAlmacenes;
    oList.Add(item);
  end;
end;

function TfrmMtoFacturasSimplif.RecogerFiltros:
  TFiltrosFacturasSimplificadas;
var
  iFiltro: Integer;
  i: Integer;
begin
  Result := Default(TFiltrosFacturasSimplificadas);
  for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
  begin
    if ccbFiltroAnyo.States[i] = cbsChecked then
    begin
      iFiltro := Length(Result.Anyos);
      SetLength(Result.Anyos, iFiltro + 1);
      Result.Anyos[iFiltro] := StrToIntDef(
        ccbFiltroAnyo.Properties.Items[i].Description,
        0);
    end;
  end;
  for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
  begin
    if (ccbFiltroAlmacen.States[i] = cbsChecked) and
       (i < FCodigosAlmacen.Count) then
    begin
      iFiltro := Length(Result.Almacenes);
      SetLength(Result.Almacenes, iFiltro + 1);
      Result.Almacenes[iFiltro] := FCodigosAlmacen[i];
    end;
  end;
end;

function TfrmMtoFacturasSimplif.ContarFacturas: Integer;
begin
  Result := FRepositorioListado.Contar(RecogerFiltros);
end;

procedure TfrmMtoFacturasSimplif.AplicarFiltrosFacturas;
begin
  if Assigned(FRepositorioListado) and
     FRepositorioListado.ConfigurarListado(RecogerFiltros) then
    AbrirConProgreso;
end;

procedure TfrmMtoFacturasSimplif.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
  MAX_FILAS_CARGA = 200000;
var
  qry: TUniQuery;
  nTotal, nLeidos: Integer;
  cursorPrev: TCursor;
begin
  if (not FAbriendoConProgreso) and
     Assigned(dmmFacturas) and Assigned(dmmFacturas.unqryTablaG) then
  begin
    FAbriendoConProgreso := True;
    try
      qry := dmmFacturas.unqryTablaG;
      cursorPrev := Screen.Cursor;
      Screen.Cursor := crHourGlass;
      MostrarProgresoCarga(0);
      // FetchRows define el tamaño de bloque; al recorrer, UniDAC trae los
      // registros por bloques (FetchAll por defecto es False) y vamos
      // avanzando la barra. DisableControls evita que el grid fuerce el
      // fetch completo de golpe. FetchRows solo se puede fijar con la query
      // cerrada, asi que lo dejamos puesto (no se restaura).
      qry.DisableControls;
      try
        nTotal := ContarFacturas;
        // Tope de seguridad: cargar cientos de miles de filas de golpe
        // bloquea el grid. Si la seleccion es enorme (p.ej. el año "1900" de
        // fechas vacias, o todos), avisamos y NO cargamos.
        if nTotal > MAX_FILAS_CARGA then
        begin
          OcultarProgresoCarga;
          Screen.Cursor := cursorPrev;
          MessageDlg_fza(Format(SAvisoLimiteRegistrosFacturaSimplificada,
            [FormatFloat('#,##0', nTotal)]), mtWarning, [mbOK], 0);
        end
        else
        begin
          if Assigned(FbarProgreso) then
          begin
            if nTotal > 0 then
              FbarProgreso.Max := nTotal
            else
              FbarProgreso.Max := 1;
          end;
          qry.Close;
          qry.FetchRows := TAM_BLOQUE;
          qry.Open;
          nLeidos := 0;
          qry.First;
          while not qry.Eof do
          begin
            Inc(nLeidos);
            if (nLeidos mod 200) = 0 then
              ActualizarProgresoCarga(nLeidos, nTotal);
            qry.Next;
          end;
          qry.First;
        end;
      finally
        qry.EnableControls;
        OcultarProgresoCarga;
        Screen.Cursor := cursorPrev;
      end;
    finally
      FAbriendoConProgreso := False;
    end;
  end;
end;

procedure TfrmMtoFacturasSimplif.MostrarProgresoCarga(const AMax: Integer);
begin
  if FPnlProgreso = nil then
  begin
    FPnlProgreso := TPanel.Create(Self);
    FPnlProgreso.Parent := Self;
    FPnlProgreso.BevelOuter := bvLowered;
    FPnlProgreso.ParentBackground := False;
    FPnlProgreso.Color := clWindow;
    FPnlProgreso.Width := 340;
    FPnlProgreso.Height := 96;
    FlblProgreso := TcxLabel.Create(Self);
    FlblProgreso.Parent := FPnlProgreso;
    FlblProgreso.Left := 16;
    FlblProgreso.Top := 18;
    FlblProgreso.Style.Font.Style := [fsBold];
    FbarProgreso := TProgressBar.Create(Self);
    FbarProgreso.Parent := FPnlProgreso;
    FbarProgreso.Left := 16;
    FbarProgreso.Top := 52;
    FbarProgreso.Width := 308;
    FbarProgreso.Height := 22;
  end;
  FbarProgreso.Min := 0;
  if AMax > 0 then
    FbarProgreso.Max := AMax
  else
    FbarProgreso.Max := 1;
  FbarProgreso.Position := 0;
  FlblProgreso.Caption := SCaptionCargandoBorradores;
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  FPnlProgreso.Update;
end;

procedure TfrmMtoFacturasSimplif.ActualizarProgresoCarga(const APos,
                                                         AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := Format(SCaptionCargandoBorradoresProgreso,
                                   [FormatFloat('#,##0', APos),
                                    FormatFloat('#,##0', AMax)]);
    FPnlProgreso.Update;
  end;
end;

procedure TfrmMtoFacturasSimplif.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

procedure TfrmMtoFacturasSimplif.btnToggleFiltrosClick(Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  pnlContFiltros.Visible := not pnlContFiltros.Visible;
  if pnlContFiltros.Visible then
  begin
    pnlFiltros.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltros.Caption := SCaptionFiltrosCargaExpandido;
  end
  else
  begin
    pnlFiltros.Height := ALTO_CABECERA;
    btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  end;
end;

procedure TfrmMtoFacturasSimplif.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosFacturas;
end;

procedure TfrmMtoFacturasSimplif.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosFacturas;
end;

procedure TfrmMtoFacturasSimplif.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+R): sin filtros de carga para localizar la
  // factura sea del año/almacen que sea.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  if Assigned(FRepositorioListado) then
    FRepositorioListado.ConfigurarListado(RecogerFiltros);
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := SCaptionFiltrosCargaContraido;
  inherited;
end;

procedure TfrmMtoFacturasSimplif.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  if Assigned(pnlFiltros) then
    pnlFiltros.Visible := False;
end;

procedure TfrmMtoFacturasSimplif.FormDestroy(Sender: TObject);
begin
  inherited;
  FRepositorioListado := nil;
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  RegistrarPantalla(TfrmMtoFacturasSimplif);
  ForceReferenceToClass(TfrmMtoFacturasSimplif);
end.

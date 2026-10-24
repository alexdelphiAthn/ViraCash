{******************************************************************************}
{                                                                              }
{  Módulo:       UPrincipal                                                    }
{    Tipo:       Formulario                                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Careta de pruebas del webservice de ventas: envía eventos y los           }
{    recupera después para comprobar el contrato de extremo a extremo.         }
{******************************************************************************}
unit UPrincipal;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, Uni, inLibParametrosIntf;

type
  TfrmPrincipal = class(TForm)
    btnConectar: TButton;
    btnCopiarJson: TButton;
    btnDescargarFactura: TButton;
    btnDescargarTicket: TButton;
    btnDetalle: TButton;
    btnEnviar: TButton;
    btnGenerar: TButton;
    btnListar: TButton;
    btnProbarApi: TButton;
    cbbConTipo: TComboBox;
    cbbTipoEvento: TComboBox;
    edtBaseDatos: TEdit;
    edtConEmpresa: TEdit;
    edtConNumero: TEdit;
    edtConSerie: TEdit;
    edtDesde: TEdit;
    edtEnvNumero: TEdit;
    edtEnvSerie: TEdit;
    edtHasta: TEdit;
    edtLimite: TEdit;
    edtPassword: TEdit;
    edtPuerto: TEdit;
    edtReferencia: TEdit;
    edtSecuencia: TEdit;
    edtServidor: TEdit;
    edtToken: TEdit;
    edtUrl: TEdit;
    edtUsuario: TEdit;
    lblBaseDatos: TLabel;
    lblConEmpresa: TLabel;
    lblConNumero: TLabel;
    lblConSerie: TLabel;
    lblConTipo: TLabel;
    lblDesde: TLabel;
    lblEnvNumero: TLabel;
    lblEnvResultado: TLabel;
    lblEnvSerie: TLabel;
    lblEstado: TLabel;
    lblHasta: TLabel;
    lblJson: TLabel;
    lblLimite: TLabel;
    lblPassword: TLabel;
    lblPuerto: TLabel;
    lblReferencia: TLabel;
    lblSecuencia: TLabel;
    lblServidor: TLabel;
    lblTipoEvento: TLabel;
    lblToken: TLabel;
    lblUrl: TLabel;
    lblUsuario: TLabel;
    lvVentas: TListView;
    mDetalle: TMemo;
    mEnvResultado: TMemo;
    mJson: TMemo;
    pgcPrincipal: TPageControl;
    pnlConfig: TPanel;
    tsConsultar: TTabSheet;
    tsEnviar: TTabSheet;
    procedure btnConectarClick(Sender: TObject);
    procedure btnCopiarJsonClick(Sender: TObject);
    procedure btnDescargarFacturaClick(Sender: TObject);
    procedure btnDescargarTicketClick(Sender: TObject);
    procedure btnDetalleClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure btnGenerarClick(Sender: TObject);
    procedure btnListarClick(Sender: TObject);
    procedure btnProbarApiClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvVentasDblClick(Sender: TObject);
  private
    FConexion: TUniConnection;
    FParametros: IParametrosAplicacion;
    function ComprobarBbdd: Boolean;
    function ConsultaVentaSeleccionada: string;
    function EmpresaDeFactura(const ASerie, ANumero: string): string;
    function HayVentaSeleccionada: Boolean;
    procedure ActualizarParametros;
    procedure DescargarDocumento(const ATipo: string);
    procedure MostrarEstado(const AMensaje: string);
    procedure RellenarLista(const AContenido: string);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  System.SysUtils, System.JSON, System.UITypes, System.IOUtils,
  Vcl.Clipbrd, Vcl.Dialogs, MySQLUniProvider,
  inLibViraCashApi, inLibVentasWsJson, UParametrosPrueba,
  UniDataVentasWsJson;

{$R *.dfm}

const
  cVersionCareta = '1.0.0.PruebaVentasWs';
  cRutaEventos = 'ventas/eventos.php';
  cRutaListar = 'ventas/listar.php';
  cRutaDetalle = 'ventas/detalle.php';
  cRutaDocumento = 'ventas/documento.php';
  cRutaPrueba = 'prueba.php';

resourcestring
  SAvisoConectarBaseDatos =
    'Conecte antes con la base de datos de ViraCash.';
  SAvisoIndicarFactura = 'Indique serie y número de la factura.';
  SAvisoGenerarJsonEvento = 'Genere primero el JSON del evento.';
  SAvisoSeleccionarVenta = 'Seleccione una venta del listado.';

function NuevoUuid: string;
var
  oGuid: TGUID;
  sGuid: string;
begin
  CreateGUID(oGuid);
  sGuid := GUIDToString(oGuid);
  Result := LowerCase(Copy(sGuid, 2, 36));
end;

{ Reindenta el JSON para poder leerlo en el memo. Si el texto no es JSON
  válido se devuelve tal cual, que suele ser el error del servidor. }
function FormatearJson(const ATexto: string): string;
var
  oValor: TJSONValue;
begin
  Result := ATexto;
  oValor := TJSONObject.ParseJSONValue(ATexto);
  if Assigned(oValor) then
  begin
    try
      Result := oValor.Format(2);
    finally
      FreeAndNil(oValor);
    end;
  end;
end;

function TextoDeNodo(AObjeto: TJSONObject; const ANombre: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  if Assigned(AObjeto) then
  begin
    oValor := AObjeto.GetValue(ANombre);
    if Assigned(oValor) and not (oValor is TJSONNull) then
      Result := oValor.Value;
  end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FConexion := TUniConnection.Create(Self);
  FConexion.ProviderName := 'MySQL';
  FConexion.LoginPrompt := False;
  FConexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
  FConexion.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
  FConexion.SpecificOptions.Values['ConnectionTimeout'] := '30';
  edtUrl.Text := 'https://webservice.veryverifactu.com/api/v1/';
  edtServidor.Text := 'localhost';
  edtPuerto.Text := '3306';
  edtBaseDatos.Text := 'factuzam';
  edtUsuario.Text := 'root';
  edtSecuencia.Text := '1';
  edtLimite.Text := '50';
  cbbTipoEvento.ItemIndex := 0;
  cbbConTipo.ItemIndex := 0;
  MostrarEstado('Sin conexión a la base de datos.');
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FParametros := nil;
  if Assigned(FConexion) and FConexion.Connected then
    FConexion.Disconnect;
end;

procedure TfrmPrincipal.MostrarEstado(const AMensaje: string);
begin
  lblEstado.Caption := AMensaje;
end;

{ Recompone los parámetros cada vez que se llama a la API, de forma que
  los cambios en la cabecera surten efecto sin reiniciar la careta. }
procedure TfrmPrincipal.ActualizarParametros;
begin
  FParametros := TParametrosPrueba.Create(
    edtUrl.Text,
    edtToken.Text,
    edtReferencia.Text);
end;

function TfrmPrincipal.ComprobarBbdd: Boolean;
begin
  Result := Assigned(FConexion) and FConexion.Connected;
  if not Result then
    MessageDlg(SAvisoConectarBaseDatos,
      mtWarning, [mbOK], 0);
end;

procedure TfrmPrincipal.btnConectarClick(Sender: TObject);
begin
  btnConectar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    try
      if FConexion.Connected then
        FConexion.Disconnect;
      FConexion.Server := Trim(edtServidor.Text);
      FConexion.Port := StrToIntDef(Trim(edtPuerto.Text), 3306);
      FConexion.Database := Trim(edtBaseDatos.Text);
      FConexion.Username := Trim(edtUsuario.Text);
      FConexion.Password := edtPassword.Text;
      FConexion.Connect;
      MostrarEstado('Conectado a ' + FConexion.Database + ' en ' +
        FConexion.Server + '.');
    except
      on E: Exception do
        MostrarEstado('Error de conexión: ' + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
    btnConectar.Enabled := True;
  end;
end;

procedure TfrmPrincipal.btnProbarApiClick(Sender: TObject);
var
  oResultado: TResultadoViraCashApi;
  sContenido: string;
begin
  ActualizarParametros;
  Screen.Cursor := crHourGlass;
  try
    try
      oResultado := TClienteViraCashApi.RecibirJson(
        FParametros, cRutaPrueba, '', sContenido);
      MostrarEstado('API: ' + oResultado.Mensaje + ' (HTTP ' +
        IntToStr(oResultado.EstadoHttp) + ')');
    except
      on E: Exception do
        MostrarEstado('Error de red: ' + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmPrincipal.EmpresaDeFactura(
  const ASerie, ANumero: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT CODIGO_EMP_FAC FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('CODIGO_EMP_FAC').AsString;
    Qry.Close;
  finally
    FreeAndNil(Qry);
  end;
end;

{ Genera el evento con el mismo serializador que usa la cola real, de
  modo que lo que se prueba aquí es el JSON de producción. }
procedure TfrmPrincipal.btnGenerarClick(Sender: TObject);
var
  iSecuencia: Int64;
  sEmpresa: string;
  sNumero: string;
  sSerie: string;
begin
  sSerie := Trim(edtEnvSerie.Text);
  sNumero := Trim(edtEnvNumero.Text);
  iSecuencia := StrToInt64Def(Trim(edtSecuencia.Text), 1);
  if iSecuencia < 1 then
    iSecuencia := 1;
  if not ComprobarBbdd then
    mEnvResultado.Lines.Text := 'Sin conexión a la base de datos.'
  else if (sSerie = '') or (sNumero = '') then
    MessageDlg(SAvisoIndicarFactura,
      mtWarning, [mbOK], 0)
  else
  begin
    ActualizarParametros;
    Screen.Cursor := crHourGlass;
    try
      try
        sEmpresa := EmpresaDeFactura(sSerie, sNumero);
        if sEmpresa = '' then
          mEnvResultado.Lines.Text :=
            'No existe la factura ' + sSerie + '\' + sNumero + '.'
        else
        begin
          mJson.Lines.Text := FormatearJson(
            TVentasWsJson.ConstruirEvento(
              FParametros,
              cVersionCareta,
              CrearVentasWsJsonUniDAC(FConexion),
              iSecuencia,
              NuevoUuid,
              cbbTipoEvento.Text,
              sEmpresa,
              sSerie,
              sNumero));
          mEnvResultado.Lines.Text :=
            'Evento generado para la empresa ' + sEmpresa +
            '. Revise el JSON y pulse Enviar.';
        end;
      except
        on E: Exception do
          mEnvResultado.Lines.Text := 'Error generando el evento: ' +
            E.Message;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmPrincipal.btnEnviarClick(Sender: TObject);
var
  oResultado: TResultadoViraCashApi;
begin
  if Trim(mJson.Lines.Text) = '' then
    MessageDlg(SAvisoGenerarJsonEvento, mtWarning, [mbOK], 0)
  else
  begin
    ActualizarParametros;
    btnEnviar.Enabled := False;
    Screen.Cursor := crHourGlass;
    try
      try
        oResultado := TClienteViraCashApi.EnviarJson(
          FParametros, cRutaEventos, mJson.Lines.Text);
        mEnvResultado.Lines.Clear;
        mEnvResultado.Lines.Add('HTTP ' +
          IntToStr(oResultado.EstadoHttp) + ' - ' + oResultado.Mensaje);
        if oResultado.IdPeticion <> '' then
          mEnvResultado.Lines.Add('Id de petición: ' +
            oResultado.IdPeticion);
      except
        on E: Exception do
          mEnvResultado.Lines.Text := 'Error de red: ' + E.Message;
      end;
    finally
      Screen.Cursor := crDefault;
      btnEnviar.Enabled := True;
    end;
  end;
end;

procedure TfrmPrincipal.btnCopiarJsonClick(Sender: TObject);
begin
  if Trim(mJson.Lines.Text) <> '' then
    Clipboard.AsText := mJson.Lines.Text;
end;

procedure TfrmPrincipal.btnListarClick(Sender: TObject);
var
  oResultado: TResultadoViraCashApi;
  sConsulta: string;
  sContenido: string;
begin
  ActualizarParametros;
  sConsulta := TClienteViraCashApi.ComponerConsulta(
    ['empresa', 'serie', 'numero', 'tipo_evento', 'desde', 'hasta',
     'limite'],
    [Trim(edtConEmpresa.Text), Trim(edtConSerie.Text),
     Trim(edtConNumero.Text), Trim(cbbConTipo.Text),
     Trim(edtDesde.Text), Trim(edtHasta.Text), Trim(edtLimite.Text)]);
  btnListar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    try
      oResultado := TClienteViraCashApi.RecibirJson(
        FParametros, cRutaListar, sConsulta, sContenido);
      if oResultado.Ok then
        RellenarLista(sContenido)
      else
      begin
        lvVentas.Items.Clear;
        mDetalle.Lines.Text := FormatearJson(sContenido);
      end;
      MostrarEstado('Listado: ' + oResultado.Mensaje + ' (HTTP ' +
        IntToStr(oResultado.EstadoHttp) + ')');
    except
      on E: Exception do
        MostrarEstado('Error de red: ' + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
    btnListar.Enabled := True;
  end;
end;

{ Vuelca el array datos.ventas en el listado. Se comprueba el tipo de
  cada nodo porque la respuesta puede no ser la esperada si un proxy se
  interpone y devuelve HTML. }
procedure TfrmPrincipal.RellenarLista(const AContenido: string);
var
  iVenta: Integer;
  oDatos: TJSONValue;
  oElemento: TListItem;
  oRaiz: TJSONValue;
  oVenta: TJSONValue;
  oVentas: TJSONValue;
begin
  lvVentas.Items.BeginUpdate;
  try
    lvVentas.Items.Clear;
    oRaiz := TJSONObject.ParseJSONValue(AContenido);
    try
      if oRaiz is TJSONObject then
      begin
        oDatos := TJSONObject(oRaiz).GetValue('datos');
        if oDatos is TJSONObject then
        begin
          oVentas := TJSONObject(oDatos).GetValue('ventas');
          if oVentas is TJSONArray then
          begin
            for iVenta := 0 to TJSONArray(oVentas).Count - 1 do
            begin
              oVenta := TJSONArray(oVentas).Items[iVenta];
              if oVenta is TJSONObject then
              begin
                oElemento := lvVentas.Items.Add;
                oElemento.Caption :=
                  TextoDeNodo(TJSONObject(oVenta), 'empresa');
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'serie'));
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'numero'));
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'ultima_secuencia'));
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'ultimo_tipo_evento'));
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'instante_modif'));
                oElemento.SubItems.Add(
                  TextoDeNodo(TJSONObject(oVenta), 'numero_lineas'));
              end;
            end;
          end;
        end;
      end;
    finally
      FreeAndNil(oRaiz);
    end;
  finally
    lvVentas.Items.EndUpdate;
  end;
end;

function TfrmPrincipal.HayVentaSeleccionada: Boolean;
begin
  Result := Assigned(lvVentas.Selected) and
            (lvVentas.Selected.SubItems.Count >= 2);
  if not Result then
    MessageDlg(SAvisoSeleccionarVenta, mtWarning, [mbOK], 0);
end;

function TfrmPrincipal.ConsultaVentaSeleccionada: string;
begin
  Result := TClienteViraCashApi.ComponerConsulta(
    ['empresa', 'serie', 'numero'],
    [lvVentas.Selected.Caption,
     lvVentas.Selected.SubItems[0],
     lvVentas.Selected.SubItems[1]]);
end;

procedure TfrmPrincipal.btnDetalleClick(Sender: TObject);
var
  oResultado: TResultadoViraCashApi;
  sContenido: string;
begin
  if HayVentaSeleccionada then
  begin
    ActualizarParametros;
    Screen.Cursor := crHourGlass;
    try
      try
        oResultado := TClienteViraCashApi.RecibirJson(
          FParametros, cRutaDetalle, ConsultaVentaSeleccionada,
          sContenido);
        mDetalle.Lines.Text := FormatearJson(sContenido);
        MostrarEstado('Detalle: ' + oResultado.Mensaje + ' (HTTP ' +
          IntToStr(oResultado.EstadoHttp) + ')');
      except
        on E: Exception do
          MostrarEstado('Error de red: ' + E.Message);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmPrincipal.lvVentasDblClick(Sender: TObject);
begin
  if Assigned(lvVentas.Selected) then
    btnDetalleClick(Sender);
end;

{ El nombre del archivo se compone con la serie y el número, que pueden
  traer caracteres no válidos para el sistema de archivos: por eso la
  descarga va dentro de un try. }
procedure TfrmPrincipal.DescargarDocumento(const ATipo: string);
var
  oResultado: TResultadoViraCashApi;
  sConsulta: string;
  sDestino: string;
begin
  if HayVentaSeleccionada then
  begin
    ActualizarParametros;
    sDestino := TPath.Combine(TPath.GetDocumentsPath,
      ATipo + '_' + lvVentas.Selected.SubItems[0] + '_' +
      lvVentas.Selected.SubItems[1] + '.pdf');
    sConsulta := ConsultaVentaSeleccionada + '&' +
      TClienteViraCashApi.ComponerConsulta(['tipo'], [ATipo]);
    Screen.Cursor := crHourGlass;
    try
      try
        oResultado := TClienteViraCashApi.DescargarArchivo(
          FParametros, cRutaDocumento, sConsulta, sDestino);
        mDetalle.Lines.Text := oResultado.Mensaje;
        MostrarEstado('Documento: ' + oResultado.Mensaje + ' (HTTP ' +
          IntToStr(oResultado.EstadoHttp) + ')');
      except
        on E: Exception do
          MostrarEstado('Error descargando: ' + E.Message);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmPrincipal.btnDescargarTicketClick(Sender: TObject);
begin
  DescargarDocumento('TICKET_PDF');
end;

procedure TfrmPrincipal.btnDescargarFacturaClick(Sender: TObject);
begin
  DescargarDocumento('FACTURA_PDF');
end;

end.

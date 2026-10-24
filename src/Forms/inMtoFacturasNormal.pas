{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasNormal                                           }
{    Tipo:       Formulario (Mto) descendiente                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de facturas NORMALES (venta mayor).                              }
{    Descendiente de TfrmMtoFacturasBase: cambia el filtro TIPO_FAC y deja     }
{    elegir, opcionalmente, el vendedor que cobra la comisión.                 }
{    Las customizaciones de vista (columnas, anchos, orden) van en el .dfm     }
{    propio o en fza_usuarios_perfiles bajo la clave 'frmMtoFacturasNormal'.   }
{******************************************************************************}
unit inMtoFacturasNormal;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFacturasBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, Data.DB, cxDBData, cxCalendar,
  cxCurrencyEdit, cxTextEdit, cxCheckBox, cxSpinEdit, cxButtonEdit,
  cxDropDownEdit, cxMemo, cxDBLookupComboBox, cxBlobEdit, cxContainer, cxEdit,
  Vcl.Menus, JvBaseDlg, JvCalc, Vcl.ExtCtrls, dxShellDialogs, System.Actions,
  Vcl.ActnList, JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls,
  cxRadioGroup, cxNavigator, cxDBNavigator, cxSplitter, cxGroupBox, cxDBLabel,
  cxDBEdit, cxImage, Vcl.Buttons, cxLookupEdit, cxDBLookupEdit, cxMaskEdit,
  cxLabel, cxButtons, cxGridBandedTableView, cxGridDBBandedTableView,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxPC, cxScrollBox;

type
  TfrmMtoFacturasNormal = class(TfrmMtoFacturasBase)
    btnEmitirEDoc: TcxButton;
    tsParametrosEDoc: TcxTabSheet;
    cxgrpbxParametrosEDoc: TcxGroupBox;
    lblCodigoOficinaContable: TcxLabel;
    txtCODIGO_OFICINA_CONTABLE_FACTURA: TcxDBTextEdit;
    lblCodigoOrganoGestor: TcxLabel;
    txtCODIGO_ORGANO_GESTOR_FACTURA: TcxDBTextEdit;
    lblCodigoUnidadTramitadora: TcxLabel;
    txtCODIGO_UNIDAD_TRAMITADORA_FACTURA: TcxDBTextEdit;
    lblNombrePersonaCliente: TcxLabel;
    txtNOMBRE_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit;
    lblApellidosPersonaCliente: TcxLabel;
    txtAPELLIDOS_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit;
    cbbVendedorFactura: TcxDBLookupComboBox;
    procedure btnEmitirEDocClick(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    function NombreVistaListado: string; override;
    function TipoFacturaFiltro: string; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibFacturae, inLibMsgFacturas, UniDataFacturas,
  UniDataFacturaeRepositorio;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function CampoFacturaStr(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if ADataSet <> nil then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := Trim(oCampo.AsString);
  end;
end;

function NifPersonaFisicaFacturae(const ANif: string): Boolean;
var
  i: Integer;
  sNif: string;
  c: Char;
begin
  sNif := '';
  for i := 1 to Length(ANif) do
  begin
    c := UpCase(ANif[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9']) then
      sNif := sNif + c;
  end;
  Result := (sNif <> '') and
            CharInSet(sNif[1], ['0'..'9', 'X', 'Y', 'Z']);
end;

function FaltanDatosPersonaFisicaFacturae(ADataSet: TDataSet): Boolean;
begin
  Result := NifPersonaFisicaFacturae(
    CampoFacturaStr(ADataSet, 'NIF_CLIENTE_FAC'));
  if Result then
    Result := (CampoFacturaStr(ADataSet,
                 'NOMBRE_PERSONA_CLIENTE_FAC') = '') or
              (CampoFacturaStr(ADataSet,
                 'APELLIDOS_PERSONA_CLIENTE_FAC') = '');
end;

procedure TfrmMtoFacturasNormal.btnEmitirEDocClick(Sender: TObject);
var
  oDialogo: TSaveDialog;
  oResultado: TFacturaeResultado;
  sSerie: string;
  sNumero: string;
begin
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage_fza(SErrorBorradorVentaMayorNoSeleccionado);
    Abort;
  end;
  if (dsTablaG.DataSet.State = dsInsert) or
     (dsTablaG.DataSet.State = dsEdit) then
  begin
    ShowMessage_fza(SErrorGuardarAntesEmitirEdoc);
    Abort;
  end;
  if FaltanDatosPersonaFisicaFacturae(dsTablaG.DataSet) then
  begin
    pcPantalla.ActivePage := tsFicha;
    pcCab.ActivePage := tsParametrosEDoc;
    ShowMessage_fza(SErrorPersonaFisicaEdocSinDatos);
    if txtNOMBRE_PERSONA_CLIENTE_FACTURA.CanFocus then
      txtNOMBRE_PERSONA_CLIENTE_FACTURA.SetFocus;
    Abort;
  end;
  sSerie := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  oDialogo := TSaveDialog.Create(Self);
  try
    oDialogo.Title := STituloEmitirEDoc;
    oDialogo.Filter := SCaptionFiltroFacturae;
    oDialogo.DefaultExt := 'xsig';
    oDialogo.FileName := NombreArchivoFacturae(sSerie, sNumero);
    if oDialogo.Execute then
    begin
      oResultado := EmitirFacturae(
        CrearRepositorioFacturaeUniDAC(ConexionPrincipal),
        ContextoSesion, sSerie, sNumero, oDialogo.FileName);
      dsTablaG.DataSet.Refresh;
      ShowMessage_fza(Format(SInfoEdocEmitido, [oResultado.Archivo]));
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoFacturasNormal.CrearTablaPrincipal;
begin
  inherited;
  // El vendedor es opcional y se elige entre los empleados; sustituye al
  // código de cajero de solo lectura de la base, que queda oculto.
  cbbVendedorFactura.Properties.ListSource := dmmFacturas.dsVendedoresFac;
end;

function TfrmMtoFacturasNormal.NombreVistaListado: string;
begin
  Result := 'vi_facturas_normales';
end;

function TfrmMtoFacturasNormal.TipoFacturaFiltro: string;
begin
  Result := 'NORMAL';
end;

initialization
  RegistrarPantalla(TfrmMtoFacturasNormal);
  ForceReferenceToClass(TfrmMtoFacturasNormal);
end.

{******************************************************************************}
{                                                                             }
{  Módulo: inMtoModalTrabajoCortina                                           }
{  Tipo: Formulario (Modal)                                                   }
{  Versión: 1.0.0                                                             }
{  Fecha: 31/10/2026                                                          }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  SPDX-License-Identifier: MPL-2.0                                           }
{                                                                             }
{  Descripción: Edición de medidas, acabado, dirección y cita.                }
{                                                                             }
{******************************************************************************}
unit inMtoModalTrabajoCortina;

interface

uses
  System.Classes, Uni, Vcl.Controls, Vcl.Forms, cxTextEdit, cxDropDownEdit,
  cxCalendar, cxMemo, cxCurrencyEdit, inMtoModalAceptCancel,
  inLibReparaciones;

type
  TfrmModalTrabajoCortina = class(TfrmModalAceptCancel)
  private
    FClase: TcxComboBox;
    FAltura, FLargo: TcxCurrencyEdit;
    FAcabado, FDireccion: TcxMemo;
    FCita: TcxDateEdit;
    function Datos: TDatosTrabajoReparacion;
    procedure Colocar(const ARotulo: string; AY: Integer; AEditor: TControl);
    procedure CrearControles(const ATrabajo: TDatosTrabajoReparacion);
    procedure CambiarClase(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    function CloseQuery: Boolean; override;
    class procedure EditarOrden(AOwner: TComponent;
      AConexion: TUniConnection; AReparacion: Int64; const AUsuario: string);
    class function Editar(AOwner: TComponent; const ATitulo: string;
      var ATrabajo: TDatosTrabajoReparacion): Boolean;
  end;

implementation

uses
  System.SysUtils, cxLabel, inLibTrabajosCortinas, inLibMsgReparaciones,
  inLibMensajesVcl, UniDataTrabajosCortinas;

procedure TfrmModalTrabajoCortina.Colocar(const ARotulo: string;
  AY: Integer; AEditor: TControl);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Caption := ARotulo;
  oRotulo.SetBounds(ScaleValue(12),ScaleValue(AY),ScaleValue(260),
    ScaleValue(26));
  AEditor.Parent := pnlBody;
  AEditor.SetBounds(ScaleValue(280),ScaleValue(AY),ScaleValue(400),
    ScaleValue(28));
end;

procedure TfrmModalTrabajoCortina.CrearControles(
  const ATrabajo: TDatosTrabajoReparacion);
begin
  FClase := TcxComboBox.Create(Self);
  Colocar(SClaseServicio,12,FClase);
  FClase.Properties.Items.Add(SClaseTaller);
  FClase.Properties.Items.Add(SClaseAltura);
  FClase.Properties.Items.Add(SClaseInstalacion);
  FClase.Properties.DropDownListStyle := lsFixedList;
  FAltura := TcxCurrencyEdit.Create(Self);
  Colocar(SAlturaMedida,52,FAltura);
  FAltura.Properties.DisplayFormat := '0.###';
  FAltura.Properties.DecimalPlaces := 3;
  FAltura.Value := ATrabajo.AlturaMedida;
  FLargo := TcxCurrencyEdit.Create(Self);
  Colocar(SLargoFinal,92,FLargo);
  FLargo.Properties.DisplayFormat := '0.###';
  FLargo.Properties.DecimalPlaces := 3;
  FLargo.Value := ATrabajo.LargoFinal;
  FAcabado := TcxMemo.Create(Self);
  Colocar(SAcabadoCortina,132,FAcabado);
  FAcabado.Height := ScaleValue(80);
  FAcabado.Text := ATrabajo.Acabado;
  FDireccion := TcxMemo.Create(Self);
  Colocar(SDireccionInstalacion,224,FDireccion);
  FDireccion.Height := ScaleValue(70);
  FDireccion.Text := ATrabajo.Direccion;
  FCita := TcxDateEdit.Create(Self);
  Colocar(SCitaInstalacion,306,FCita);
  FCita.Properties.Kind := ckDateTime;
  FCita.Properties.DisplayFormat := 'dd/mm/yyyy hh:nn';
  FCita.Properties.EditFormat := 'dd/mm/yyyy hh:nn';
  if ATrabajo.Cita>0 then
    FCita.Date := ATrabajo.Cita;
  FClase.ItemIndex := 0;
  if ATrabajo.Clase=CLASE_SERVICIO_ALTURA then
    FClase.ItemIndex := 1
  else if ATrabajo.Clase=CLASE_SERVICIO_INSTALACION then
    FClase.ItemIndex := 2;
  FClase.Properties.ReadOnly := FClase.ItemIndex>0;
  FClase.Properties.OnEditValueChanged := CambiarClase;
  CambiarClase(FClase);
end;

procedure TfrmModalTrabajoCortina.CambiarClase(Sender: TObject);
begin
  FAltura.Enabled := FClase.ItemIndex=1;
  FLargo.Enabled := FClase.ItemIndex=1;
  FAcabado.Enabled := FClase.ItemIndex=1;
  FDireccion.Enabled := FClase.ItemIndex=2;
  FCita.Enabled := FClase.ItemIndex=2;
end;

function TfrmModalTrabajoCortina.Datos: TDatosTrabajoReparacion;
begin
  Result := Default(TDatosTrabajoReparacion);
  case FClase.ItemIndex of
    0: Result.Clase := CLASE_SERVICIO_TALLER;
    1:
      begin
        Result.Clase := CLASE_SERVICIO_ALTURA;
        Result.AlturaMedida := FAltura.Value;
        Result.LargoFinal := FLargo.Value;
        Result.Acabado := Trim(FAcabado.Text);
      end;
    2:
      begin
        Result.Clase := CLASE_SERVICIO_INSTALACION;
        Result.Direccion := Trim(FDireccion.Text);
        Result.Cita := FCita.Date;
      end;
  end;
end;

function TfrmModalTrabajoCortina.CloseQuery: Boolean;
var
  sError: string;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha='S') then
  begin
    sError := ValidarTrabajoCortina(Datos);
    if sError<>'' then
    begin
      Result := False;
      ShowMessage_fza(sError);
    end;
  end;
end;

procedure TfrmModalTrabajoCortina.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class procedure TfrmModalTrabajoCortina.EditarOrden(AOwner: TComponent;
  AConexion: TUniConnection; AReparacion: Int64; const AUsuario: string);
var
  oDatos: TDatosTrabajosCortinas;
  Detalles: TArray<TPrendaVentaReparacion>;
  bAceptar: Boolean;
  i: Integer;
begin
  oDatos := TDatosTrabajosCortinas.Create(AConexion);
  try
    Detalles := oDatos.Leer(AReparacion);
    if Length(Detalles)=0 then
    begin
      SetLength(Detalles,1);
      Detalles[0].UnidadServicio := 1;
      Detalles[0].Trabajo.Clase := CLASE_SERVICIO_TALLER;
    end;
    bAceptar := True;
    for i := 0 to High(Detalles) do
      if bAceptar then
        bAceptar := Editar(AOwner,SMedidasCita+' · '+
          Format(SDetalleUnidad,[Detalles[i].UnidadServicio]),
          Detalles[i].Trabajo);
    if bAceptar then
      oDatos.GuardarEdicion(AReparacion,Detalles,AUsuario);
  finally
    FreeAndNil(oDatos);
  end;
end;

class function TfrmModalTrabajoCortina.Editar(AOwner: TComponent;
  const ATitulo: string; var ATrabajo: TDatosTrabajoReparacion): Boolean;
var
  oFormulario: TfrmModalTrabajoCortina;
begin
  oFormulario := TfrmModalTrabajoCortina.Create(AOwner);
  try
    oFormulario.Caption := ATitulo;
    oFormulario.ClientWidth := oFormulario.ScaleValue(700);
    oFormulario.ClientHeight := oFormulario.ScaleValue(360)+
      oFormulario.pnlButton.Height;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.CrearControles(ATrabajo);
    oFormulario.ShowModal;
    Result := oFormulario.sFicha='S';
    if Result then
      ATrabajo := oFormulario.Datos;
  finally
    oFormulario.Free;
  end;
end;

end.

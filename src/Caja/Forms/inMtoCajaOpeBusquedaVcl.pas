{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpeBusquedaVcl                                      }
{    Tipo:       Servicio VCL                                                 }
{ Versión:       1.0.0                                                        }
{   Fecha:       06/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina la búsqueda contextual de vendedor, cliente y artículo.         }
{******************************************************************************}
unit inMtoCajaOpeBusquedaVcl;

interface

uses
  Data.DB,
  Vcl.Controls,
  cxButtonEdit,
  cxGrid,
  cxGridDBTableView,
  inLibCajaVentaIntf,
  inLibParametrosIntf;

type
  TAccionControlBusquedaCajaVcl = reference to procedure(
    Sender: TObject);
  TConsultaTextoBusquedaCajaVcl = reference to function: string;
  TConsultaEnteroBusquedaCajaVcl = reference to function: Integer;
  TConsultaCodigoBusquedaCajaVcl = reference to function(
    const ACodigo: string): Boolean;
  TAccionCodigoBusquedaCajaVcl = reference to procedure(
    const ACodigo: string);
  TConsultaColumnaBusquedaCajaVcl = reference to function(
    ANumero: Integer): TcxGridDBColumn;

  TContextoBusquedaCajaVcl = record
    Lineas: TDataSet;
    Rejilla: TcxGrid;
    VistaLineas: TcxGridDBTableView;
    BotonEmpleado: TcxButtonEdit;
    BotonCliente: TcxButtonEdit;
    ParametrosCaja: IParametrosCaja;
    RepositorioConsultas: IRepositorioConsultasCaja;
    AbrirAtributo: TAccionControlBusquedaCajaVcl;
    BuscarArticulo: TConsultaTextoBusquedaCajaVcl;
    RellenarArticulo: TConsultaCodigoBusquedaCajaVcl;
    ValidarSku: TConsultaCodigoBusquedaCajaVcl;
    ActualizarColumnas: TAccionCodigoBusquedaCajaVcl;
    NumeroAtributos: TConsultaEnteroBusquedaCajaVcl;
    RellenarAtributos: TAccionCodigoBusquedaCajaVcl;
    ObtenerColumna: TConsultaColumnaBusquedaCajaVcl;
    procedure Validar;
  end;

procedure ValidarCodigoClienteCajaVcl(
  AEditor: TcxButtonEdit; const ACodigoAsignado: string);
procedure BuscarClienteCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
procedure BuscarEmpleadoCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
procedure EjecutarBusquedaContextualCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  cxDropDownEdit,
  cxEdit,
  inLibCajaVentaOperacion,
  inLibMsgCaja,
  inLibMsgVentas,
  inMtoGenSearch, cxCurrencyEdit, System.Math, Winapi.Windows,
  inLibPosicionFormulario;

type
  TfrmBusquedaCuentaCliente = class(TfrmMtoSearch)
  protected
    procedure DoShow; override;
  end;

procedure TfrmBusquedaCuentaCliente.DoShow;
const
  Campos: array[0..6] of string = ('Código', 'Razón Social',
    'Deuda Usada', 'Límite Crédito', 'Cuenta Crédito',
    'NIF Cliente', 'Teléfono Cliente');
  Anchos: array[0..6] of Integer = (70, 260, 110, 110, 100, 110, 120);
var
  I: Integer;
  Columna: TcxGridDBColumn;
begin
  inherited;
  cxGrdDBTabPrin.BeginUpdate;
  try
    for I := Low(Campos) to High(Campos) do
    begin
      Columna := cxGrdDBTabPrin.GetColumnByFieldName(Campos[I]);
      if Assigned(Columna) then
      begin
        Columna.Visible := True;
        Columna.Index := I;
        Columna.Width := MulDiv(Anchos[I], CurrentPPI, 96);
        Columna.MinWidth := MulDiv(60, CurrentPPI, 96);
        if I in [2, 3] then
        begin
          Columna.PropertiesClass := TcxCurrencyEditProperties;
          TcxCurrencyEditProperties(Columna.Properties).DisplayFormat :=
            '#,##0.00 €';
        end;
      end;
    end;
    cxGrdDBTabPrin.OptionsView.ColumnAutoWidth := True;
    Width := Min(MulDiv(1150, CurrentPPI, 96),
      Monitor.WorkareaRect.Width);
    AjustarFormularioAreaTrabajo(Self, Owner);
  finally
    cxGrdDBTabPrin.EndUpdate;
  end;
end;

procedure TContextoBusquedaCajaVcl.Validar;
begin
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(Rejilla) then
    raise EArgumentNilException.Create('Rejilla');
  if not Assigned(VistaLineas) then
    raise EArgumentNilException.Create('VistaLineas');
  if not Assigned(BotonEmpleado) then
    raise EArgumentNilException.Create('BotonEmpleado');
  if not Assigned(BotonCliente) then
    raise EArgumentNilException.Create('BotonCliente');
  if not Assigned(RepositorioConsultas) then
    raise EArgumentNilException.Create('RepositorioConsultas');
end;

function EsControlActivo(
  AControlActivo: TWinControl;
  AControl: TWinControl): Boolean;
begin
  Result := AControlActivo = AControl;
  if not Result and Assigned(AControlActivo) then
    Result := AControlActivo.Parent = AControl;
end;

procedure ValidarCodigoClienteCajaVcl(
  AEditor: TcxButtonEdit; const ACodigoAsignado: string);
begin
  // El control puede haber perdido EditModified al confirmar el texto.
  // La cabecera indica si el cliente ya paso por la validacion completa.
  if Trim(AEditor.Text) <> Trim(ACodigoAsignado) then
  begin
    AEditor.ValidateEdit(True);
    AEditor.EditModified := False;
  end;
end;

procedure BuscarClienteCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
var
  oConsulta: IResultadoConsultaCaja;
  oFormulario: TfrmMtoSearch;
begin
  AContexto.Validar;
  oConsulta := AContexto.RepositorioConsultas.ConsultarClientes;
  oFormulario := TfrmBusquedaCuentaCliente.Create(nil);
  try
    oFormulario.Name := 'frmMtoCliSearch';
    oFormulario.Caption := STituloBusquedaClientes;
    oFormulario.dsTablaG.DataSet := oConsulta.DataSet;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      AContexto.BotonCliente.Text :=
        oConsulta.DataSet.FieldByName('Código').AsString;
      if AContexto.BotonCliente.ValidateEdit(True) then
        AContexto.Rejilla.SetFocus;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure BuscarEmpleadoCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
var
  oConsulta: IResultadoConsultaCaja;
  oFormulario: TfrmMtoSearch;
begin
  AContexto.Validar;
  oConsulta := AContexto.RepositorioConsultas.ConsultarEmpleados;
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.Name := 'frmMtoEmpCajSearch';
    oFormulario.Caption := STituloBusquedaEmpleadosCaja;
    oFormulario.dsTablaG.DataSet := oConsulta.DataSet;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      AContexto.BotonEmpleado.Text :=
        oConsulta.DataSet.Fields[0].AsString;
      if AContexto.BotonEmpleado.ValidateEdit(True) then
        AContexto.BotonCliente.SetFocus;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

function IntentarAbrirAtributo(
  const AContexto: TContextoBusquedaCajaVcl): Boolean;
var
  oEditor: TcxCustomEdit;
begin
  Result := False;
  if (AContexto.VistaLineas.Controller.FocusedItem <> nil) and
     (AContexto.VistaLineas.Controller.FocusedItem.Tag > 0) then
  begin
    if AContexto.Lineas.State = dsBrowse then
      AContexto.Lineas.Edit;
    if not AContexto.VistaLineas.Controller.
       EditingController.IsEditing then
    begin
      AContexto.VistaLineas.Controller.EditingController.ShowEdit;
    end;
    if AContexto.VistaLineas.Controller.
       EditingController.IsEditing then
    begin
      oEditor := AContexto.VistaLineas.Controller.
        EditingController.Edit;
      Result := oEditor is TcxComboBox;
      if Result and Assigned(AContexto.AbrirAtributo) then
        AContexto.AbrirAtributo(oEditor);
    end;
  end;
end;

function LineaPermiteBusqueda(ADataSet: TDataSet): Boolean;
var
  sOrigenDeposito: string;
begin
  Result := True;
  if ADataSet.Active and not ADataSet.IsEmpty then
  begin
    sOrigenDeposito := ADataSet.FieldByName(
      'VIENE_DE_DEPOSITO').AsString;
    Result := (sOrigenDeposito <> 'S') and
      (sOrigenDeposito <> 'A');
  end;
end;

procedure PrepararLineaArticulo(ADataSet: TDataSet);
begin
  if ADataSet.State = dsBrowse then
  begin
    if ADataSet.IsEmpty then
      ADataSet.Append
    else
      ADataSet.Edit;
  end;
end;

procedure PrepararSiguienteEntrada(
  const AContexto: TContextoBusquedaCajaVcl;
  ANumeroAtributos: Integer;
  AEsSkuCompleto: Boolean);
var
  bAutoPasarLinea: Boolean;
  oPrimeraColumna: TcxGridDBColumn;
begin
  // Mismo valor por defecto que el registro del parámetro y que el
  // resto de la caja (FZ-ISSUE-455).
  bAutoPasarLinea := AContexto.ParametrosCaja.GetBool(
    'vgerMoverLineaIdentif', True);
  if (ANumeroAtributos > 0) and not AEsSkuCompleto then
  begin
    oPrimeraColumna := AContexto.ObtenerColumna(1);
    if oPrimeraColumna <> nil then
    begin
      oPrimeraColumna.Visible := True;
      AContexto.VistaLineas.Controller.FocusedColumn :=
        oPrimeraColumna;
      AContexto.VistaLineas.Controller.
        EditingController.ShowEdit;
    end;
  end
  else if bAutoPasarLinea then
  begin
    if AContexto.Lineas.State in [dsEdit, dsInsert] then
      AContexto.Lineas.Post;
    AContexto.Lineas.Append;
    AContexto.VistaLineas.Controller.FocusedColumn :=
      AContexto.VistaLineas.GetColumnByFieldName(
        'CODIGO_ART_FACLIN');
    AContexto.VistaLineas.Controller.EditingController.ShowEdit;
  end;
end;

procedure AplicarArticuloBuscado(
  const AContexto: TContextoBusquedaCajaVcl;
  const ACodigoBuscado: string);
var
  bEsSkuCompleto: Boolean;
  iNumeroAtributos: Integer;
  sCodigoArticulo: string;
  sSkuDetectado: string;
begin
  PrepararLineaArticulo(AContexto.Lineas);
  if AContexto.RellenarArticulo(ACodigoBuscado) then
  begin
    sCodigoArticulo := AContexto.Lineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    sSkuDetectado := AContexto.Lineas.FieldByName(
      'CODIGO_UNIDAD_FACLIN').AsString;
    bEsSkuCompleto := (Trim(sSkuDetectado) <> '') and
      (sSkuDetectado <> sCodigoArticulo);
    if bEsSkuCompleto and not AContexto.ValidarSku(sSkuDetectado) then
      EliminarLineaVentaPorValidacion(AContexto.Lineas)
    else
    begin
      AContexto.ActualizarColumnas(sCodigoArticulo);
      iNumeroAtributos := AContexto.NumeroAtributos();
      if bEsSkuCompleto and (iNumeroAtributos > 0) then
        AContexto.RellenarAtributos(sSkuDetectado);
      AContexto.Rejilla.SetFocus;
      PrepararSiguienteEntrada(
        AContexto,
        iNumeroAtributos,
        bEsSkuCompleto);
    end;
  end;
end;

procedure BuscarArticuloCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
var
  sCodigoBuscado: string;
begin
  if LineaPermiteBusqueda(AContexto.Lineas) then
  begin
    sCodigoBuscado := AContexto.BuscarArticulo();
    if sCodigoBuscado <> '' then
      AplicarArticuloBuscado(AContexto, sCodigoBuscado);
  end;
end;

procedure EjecutarBusquedaContextualCajaVcl(
  const AContexto: TContextoBusquedaCajaVcl);
var
  oControlActivo: TWinControl;
begin
  AContexto.Validar;
  if not IntentarAbrirAtributo(AContexto) then
  begin
    oControlActivo := Screen.ActiveControl;
    if EsControlActivo(oControlActivo, AContexto.BotonEmpleado) then
      BuscarEmpleadoCajaVcl(AContexto)
    else if EsControlActivo(oControlActivo, AContexto.BotonCliente) then
      BuscarClienteCajaVcl(AContexto)
    else
      BuscarArticuloCajaVcl(AContexto);
  end;
end;

end.

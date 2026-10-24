{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFormasdePago                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de formas de pago.                                            }
{    Mantenimiento de fza_formas_pago y consulta de facturas/líneas que las    }
{    usan.                                                                     }
{******************************************************************************}
unit UniDataFormasdePago;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmFormasdePago = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryFacturasLineas: TUniQuery;
    unqryFacturas: TUniQuery;
    dsFacturas: TDataSource;
    dsFacturasLineas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoFormasdePago;
    //procedure GetCodigoAutoRetencion;
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  System.Diagnostics, UniDataAperturaConsultas,
  inLibMsgComun, inLibMsgFacturas;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFormasdePago.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  oCampo: TField;
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FP_FP').AsString := '0';
  unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_ANTICIPO_FORMA_PAGO_FP').AsString := '0';
  oCampo := unqryTablaG.FindField('CODIGO_FACTURAE_FP');
  if oCampo <> nil then
    oCampo.AsString := '01';
end;

procedure TdmFormasdePago.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection + MasterSource. Los .Open se han movido a AbrirDetalles.
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryFacturas.Connection := ConexionPrincipal;
  unqryFacturasLineas.Connection := ConexionPrincipal;
end;

procedure TdmFormasdePago.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryFacturas.MasterSource := ADataSource;
  unqryFacturasLineas.MasterSource := ADataSource;
end;

procedure TdmFormasdePago.AbrirDetalles;
const
  TAG = 'FormasdePago.AbrirDetalles';
var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConsultaConTiempo(
    unqryFacturas, TAG, 'unqryFacturas', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFacturasLineas, TAG, 'unqryFacturasLineas', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFormasdePago.GetCodigoAutoFormasdePago;
begin
  if unqryTablaG.FindField('CODIGO_FP_FP').AsString = '0' then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'PG';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('CODIGO_FP_FP').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
  if unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString = '0' then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'GO';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
end;

function CodigoFacturaeFormaPagoValido(const AValor: string): Boolean;
var
  iCodigo: Integer;
begin
  Result := TryStrToInt(AValor, iCodigo) and
            (Length(AValor) = 2) and
            (iCodigo >= 1) and
            (iCodigo <= 19);
end;

procedure NormalizarCodigoFacturaeFormaPago(ADataSet: TDataSet);
var
  oCampo: TField;
  sCodigo: string;
begin
  oCampo := ADataSet.FindField('CODIGO_FACTURAE_FP');
  if oCampo <> nil then
  begin
    sCodigo := Trim(oCampo.AsString);
    if sCodigo = '' then
      sCodigo := '01';
    if Length(sCodigo) = 1 then
      sCodigo := '0' + sCodigo;
    if not CodigoFacturaeFormaPagoValido(sCodigo) then
      raise ERangeError.CreateFmt(SErrorCodigoFacturaeFormaPago,
                                 [oCampo.AsString]);
    oCampo.AsString := sCodigo;
  end;
end;

procedure TdmFormasdePago.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField(
       'DESCRIPCION_FORMA_PAGO_FP').AsString) = '') then
    Abort;
  if Trim(unqryTablaG.FindField(
    'DESCRIPCION_FORMA_PAGO_FP').AsString) = '' then
    raise ERangeError.CreateFmt(SErrorDescripcionFormaPago,
      [unqryTablaG.FindField('DESCRIPCION_FORMA_PAGO_FP').AsString]);
  NormalizarCodigoFacturaeFormaPago(DataSet);
  GetCodigoAutoFormasdePago;
end;

initialization
  RegistrarDataModule(TdmFormasdePago);
  ForceReferenceToClass(TdmFormasdePago);
end.

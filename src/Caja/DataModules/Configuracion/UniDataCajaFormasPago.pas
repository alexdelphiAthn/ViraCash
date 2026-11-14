{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaFormasPago                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de formas de pago de caja.                                    }
{    Mantenimiento de fza_caja_formas_pago para los botones del cobro F12.     }
{******************************************************************************}
unit UniDataCajaFormasPago;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmCajaFormasPago = class(TdmBase)
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibMsgCaja;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmCajaFormasPago.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString := 'N';
  unqryTablaG.FindField('ESCRIPTO_FORMA_PAGO_CFP').AsString         := 'N';
  unqryTablaG.FindField('ESDIVISA_FORMA_PAGO_CFP').AsString         := 'N';
  unqryTablaG.FindField('ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP').AsString := 'S';
  unqryTablaG.FindField('ESABRE_CAJON_FORMA_PAGO_CFP').AsString     := 'N';
  unqryTablaG.FindField('ESACTIVO_FORMA_PAGO_CFP').AsString         := 'S';
  unqryTablaG.FindField('ORDEN_VISUAL_FORMA_PAGO_CFP').AsInteger    := 99;
end;

procedure TdmCajaFormasPago.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField(
       'DESCRIPCION_FORMA_PAGO_CFP').AsString) = '') then
    Abort;
  if Trim(unqryTablaG.FindField('CODIGO_FP_CFP').AsString) = '' then
    raise ERangeError.Create(SErrorCodigoFormaPagoCajaObligatorio);
  if Trim(unqryTablaG.FindField(
    'DESCRIPCION_FORMA_PAGO_CFP').AsString) = '' then
    raise ERangeError.Create(SErrorDescripcionFormaPagoCajaObligatoria);
end;

initialization
  RegistrarDataModule(TdmCajaFormasPago);
  ForceReferenceToClass(TdmCajaFormasPago);
end.

{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComboProveedorDocumentoVcl                               }
{    Tipo:       Libreria VCL                                                  }
{ Version:       1.0.0                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-937: el combo de proveedor de los documentos de compra muestra   }
{    "codigo - nombre"; tras elegir un proveedor o salir del combo el texto    }
{    vuelve al principio para que se vea el codigo. Encadena los eventos que   }
{    ya tuviera el combo, sin sustituirlos.                                   }
{                                                                              }
{    FZ-ISSUE-1002: el combo busca por "codigo - nombre", asi que un codigo    }
{    tecleado solo (QA-PRV1 + Tab) no casaba y se borraba sin aviso. Al        }
{    validar, un codigo exacto se resuelve a su proveedor y un texto que no    }
{    es ningun proveedor se rechaza con un aviso.                              }
{******************************************************************************}
unit inLibComboProveedorDocumentoVcl;

interface

uses
  cxDBLookupComboBox;

procedure ConfigurarComboProveedorDocumento(ACombo: TcxDBLookupComboBox);

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, Data.DB, Vcl.Controls, cxEdit, inLibMsgCompras;

type
  TAjusteComboProveedor = class(TComponent)
  private
    FCombo: TcxDBLookupComboBox;
    FAlSalir: TNotifyEvent;
    FAlCerrar: TNotifyEvent;
    FAlValidar: TcxEditValidateEvent;
    procedure MostrarInicio;
    function ListaProveedores: TDataSet;
    function CampoLista: string;
    procedure ComboExit(Sender: TObject);
    procedure ComboCloseUp(Sender: TObject);
    procedure ComboValidate(Sender: TObject;
      var ADisplayValue: TcxEditValue; var AErrorText: TCaption;
      var AError: Boolean);
  public
    constructor Create(ACombo: TcxDBLookupComboBox); reintroduce;
  end;

constructor TAjusteComboProveedor.Create(ACombo: TcxDBLookupComboBox);
begin
  inherited Create(ACombo);
  FCombo := ACombo;
  FAlSalir := ACombo.OnExit;
  FAlCerrar := ACombo.Properties.OnCloseUp;
  FAlValidar := ACombo.Properties.OnValidate;
  ACombo.OnExit := ComboExit;
  ACombo.Properties.OnCloseUp := ComboCloseUp;
  ACombo.Properties.OnValidate := ComboValidate;
end;

function TAjusteComboProveedor.ListaProveedores: TDataSet;
begin
  Result := nil;
  if (FCombo.Properties.ListSource <> nil) and
     (FCombo.Properties.ListSource.DataSet <> nil) and
     FCombo.Properties.ListSource.DataSet.Active then
    Result := FCombo.Properties.ListSource.DataSet;
end;

function TAjusteComboProveedor.CampoLista: string;
begin
  Result := '';
  if FCombo.Properties.ListColumns.Count > 0 then
    Result := FCombo.Properties.ListColumns[0].FieldName;
end;

// Texto vacio o igual a un "codigo - nombre" de la lista: lo resuelve el
// propio combo. Codigo exacto: se sustituye por su texto de lista para que
// el combo lo resuelva. Cualquier otro texto se rechaza con aviso.
procedure TAjusteComboProveedor.ComboValidate(Sender: TObject;
  var ADisplayValue: TcxEditValue; var AErrorText: TCaption;
  var AError: Boolean);
var
  oLista: TDataSet;
  sCampo: string;
  sClave: string;
  sTexto: string;
begin
  sTexto := Trim(VarToStr(ADisplayValue));
  oLista := ListaProveedores;
  sCampo := CampoLista;
  sClave := FCombo.Properties.KeyFieldNames;
  if (sTexto <> '') and (oLista <> nil) and
     (oLista.FindField(sCampo) <> nil) and
     (oLista.FindField(sClave) <> nil) and
     (not oLista.Locate(sCampo, sTexto, [loCaseInsensitive])) then
  begin
    if oLista.Locate(sClave, sTexto, [loCaseInsensitive]) then
      ADisplayValue := oLista.FieldByName(sCampo).AsString
    else
    begin
      AError := True;
      AErrorText := Format(SErrorProveedorTecleadoNoExiste, [sTexto]);
    end;
  end;
  if Assigned(FAlValidar) then
    FAlValidar(Sender, ADisplayValue, AErrorText, AError);
end;

// Caret al principio: el texto deja de quedar desplazado a la izquierda.
// Se envia en diferido a la caja de texto interna: al cerrar la lista
// DevExpress vuelve a colocar el cursor al final despues de OnCloseUp, y un
// mensaje a una ventana ya destruida simplemente se descarta.
procedure TAjusteComboProveedor.MostrarInicio;
var
  oInterno: TWinControl;
begin
  oInterno := nil;
  if FCombo.InnerControl is TWinControl then
    oInterno := TWinControl(FCombo.InnerControl);
  if (oInterno <> nil) and oInterno.HandleAllocated then
  begin
    PostMessage(oInterno.Handle, EM_SETSEL, 0, 0);
    PostMessage(oInterno.Handle, EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TAjusteComboProveedor.ComboExit(Sender: TObject);
begin
  if Assigned(FAlSalir) then
    FAlSalir(Sender);
  MostrarInicio;
end;

procedure TAjusteComboProveedor.ComboCloseUp(Sender: TObject);
begin
  if Assigned(FAlCerrar) then
    FAlCerrar(Sender);
  MostrarInicio;
end;

procedure ConfigurarComboProveedorDocumento(ACombo: TcxDBLookupComboBox);
var
  iComponente: Integer;
  bConfigurado: Boolean;
begin
  if ACombo = nil then
    raise EArgumentNilException.Create('ACombo');
  bConfigurado := False;
  for iComponente := 0 to ACombo.ComponentCount - 1 do
    bConfigurado := bConfigurado or
      (ACombo.Components[iComponente] is TAjusteComboProveedor);
  if not bConfigurado then
    TAjusteComboProveedor.Create(ACombo);
end;

end.

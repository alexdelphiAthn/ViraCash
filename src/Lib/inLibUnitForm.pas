{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUnitForm                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro de formularios y atajos del programa.                            }
{    Asocia menú, unit, data module y shortcut con cada formulario disponible. }
{******************************************************************************}
unit inLibUnitForm;

interface

uses
  System.Generics.Defaults, System.Generics.Collections, System.Contnrs,
  Classes, Windows, Forms, vcl.Menus, Controls,
  System.SysUtils,
  System.StrUtils, inLibUser, Vcl.Buttons, Types, inLibLogIntf,
  inLibRegistroPantallasPersistenciaIntf;

type

 TfzaForm = class
   private
     FCall:string;
     FCaption:string;
     FPropietario: TComponent;
     FUnitForm:string;
     FMenuItem:string;
     FShortCut:string;
     FDataUnit:string;
     FNumVentanas:Integer;
     FmnMenuItem:TMenuItem;
     function GetCall:string;
     procedure SetCall(Value:string);
     function GetCaption:string;
     procedure SetCaption(Value:string);
     function GetUnitForm:string;
     procedure SetUnitForm(Value:string);
     function GetMenuItem:string;
     procedure SetMenuItem(Value:string);
     function GetShortCut:string;
     procedure SetShortCut(Value:string);
     function GetmnMenuItem:TMenuItem;
     procedure SetmnMenuItem(Value:TMenuItem);
     function GetDataUnit: string;
     procedure SetDataUnit(const Value: string);
     function GetNumVentanas: Integer;
     procedure SetNumVentanas(const Value: Integer);
   public
     constructor Create(ACall,
                        ACaption,
                        AMenuItem,
                        AUnitForm,
                        AShortCut,
                        ADataUnit:string;
                        ANumVentanas:Integer;
                        AOwn:TComponent);
     Property Call   : string read GetCall write SetCall;
     Property Caption   : string read GetCaption write SetCaption;
     Property UnitForm   : string read GetUnitForm write SetUnitForm;
     Property MenuItem   : string read GetMenuItem write SetMenuItem;
     Property mnMenuItem   : TMenuItem read GetmnMenuItem write SetmnMenuItem;
     Property ShortCut     : string read GetShortCut write SetShortCut;
     Property DataUnit     : string read GetDataUnit write SetDataUnit;
     Property NumVentanas  : Integer read GetNumVentanas write SetNumVentanas;
   private
 end;

 TfzaWinF = class(TObject)
 private
   FList:TObjectList<TfzaForm>;
   FOwner:TComponent;
   FRegistroLog: IRegistroLog;
   FLector: ILectorRegistroPantallas;
 public
   constructor Create(Owner:TComponent; const ARegistroLog: IRegistroLog;
     const ALector: ILectorRegistroPantallas);
   destructor Destroy; override;
   procedure Charge;
   function GetDataModuleName(sUnitName:string):String;
   function GetElement(sCall:string):TfzaForm;
   function GetShortCutListOrd:TList<integer>;
   function GetShortCutListString:string;
   function Count: Integer;
   function Item(AIndex: Integer): TfzaForm;
   // Codigo de permiso de un item de menu. Si el item esta registrado
   // (mnMenuItem) devuelve 'menu.<CALL>'; si no, 'menu.<Name>' para que
   // tambien sea controlable. '' si el item no tiene Name. Lo usan la
   // pantalla de permisos y AplicarPermisosMenu (misma regla en ambos).
   function CodigoMenu(AItem: TMenuItem): string;
   // CALL de la pantalla cuyo formulario es AUnit ('unit.Clase'); '' si
   // no esta registrada. Lo usa inMtoGen para los permisos por pantalla.
   function CallDeUnit(const AUnit: string): string;
   // CALL del item de menu si esta registrado (mnMenuItem); '' si no.
   function CallRegistrado(AItem: TMenuItem): string;
   // Comprueba que cada pantalla de fza_winforms tiene su clase (form
   // y data module) en el registro; deja un error en el log por cada
   // una que falte y devuelve cuantas faltan. Llamado en el arranque:
   // el typo-en-BBDD que antes reventaba en runtime queda a la vista.
   function ComprobarRegistradas: Integer;
 end;


implementation

uses
  inLibRegistroPantallas, inLibTraduccionesIntf;

resourcestring
  SErrorLectorRegistroPantallasNoDisponible =
    'El lector del registro de pantallas no está disponible.';


{ TfzaForm }

constructor TfzaForm.Create(ACall,
                            ACaption,
                            AMenuItem,
                            AUnitForm,
                            AShortCut,
                            ADataUnit: string;
                            ANumVentanas: Integer;
                            AOwn:TComponent  );
begin
  FCall := ACall;
  FCaption := ACaption;
  FPropietario := AOwn;
  FUnitForm := AUnitForm;
  FMenuItem := AMenuItem;
  FShortCut := AShortCut;
  FDataUnit := ADataUnit;
  if ANumVentanas < 1 then
    FNumVentanas := 1
  else
    FNumVentanas := ANumVentanas;
  FmnMenuItem := (AOwn.FindComponent(FMenuItem) as TMenuItem);
end;

function TfzaForm.GetCall: string;
begin
  Result := FCall;
end;

function TfzaForm.GetCaption: string;
var
  Proveedor: IProveedorTraducciones;
begin
  Result := FCaption;
  if Assigned(FmnMenuItem) then
    Result := StripHotkey(FmnMenuItem.Caption)
  else if Supports(FPropietario, IProveedorTraducciones, Proveedor) and
          Assigned(Proveedor.Traducciones) then
    Result := Proveedor.Traducciones.Traducir(
      FUnitForm + '.Caption', FCaption);
end;

function TfzaForm.GetDataUnit: string;
begin
  Result := FDataUnit;
end;

function TfzaForm.GetMenuItem: string;
begin
  Result := FMenuItem;
end;

function TfzaForm.GetNumVentanas: Integer;
begin
  Result := FNumVentanas;
end;

function TfzaForm.GetmnMenuItem: TMenuItem;
begin
  Result := FmnMenuItem;
end;

function TfzaForm.GetShortCut: string;
begin
  Result := FShortCut;
end;

function TfzaForm.GetUnitForm: string;
begin
  Result := FUnitForm;
end;

procedure TfzaForm.SetCall(Value: string);
begin
  FCall := Value;
end;

procedure TfzaForm.SetCaption(Value: string);
begin
  Fcaption := Value;
end;

procedure TfzaForm.SetDataUnit(const Value: string);
begin
  FDataUnit := Value;
end;

procedure TfzaForm.SetMenuItem(Value: string);
begin
  FMenuItem := Value;
end;

procedure TfzaForm.SetNumVentanas(const Value: Integer);
begin
  if Value < 1 then
    FNumVentanas := 1
  else
    FNumVentanas := Value;
end;

procedure TfzaForm.SetmnMenuItem(Value: TMenuItem);
begin
  FmnMenuItem := Value;
end;

procedure TfzaForm.SetShortCut(Value: string);
begin
  FShortCut := Value;
end;

procedure TfzaForm.SetUnitForm(Value: string);
begin
  FUnitForm := Value;
end;

{ TfzaWinF }

procedure TfzaWinF.Charge;
var
  aPantallas: TArray<TPantallaRegistrada>;
  oPantalla: TPantallaRegistrada;
  ozaForm: TfzaForm;
begin
  aPantallas := FLector.Cargar;
  for oPantalla in aPantallas do
  begin
    ozaForm := TfzaForm.Create(oPantalla.Llamada,
                               oPantalla.Titulo,
                               oPantalla.ElementoMenu,
                               oPantalla.UnidadFormulario,
                               oPantalla.Atajo,
                               oPantalla.UnidadDatos,
                               oPantalla.NumeroVentanas,
                               Self.FOwner);
    FList.Add(ozaForm);
  end;
end;

function TfzaWinF.ComprobarRegistradas: Integer;
var
  i: Integer;
  ozaForm: TfzaForm;
begin
  Result := 0;
  for i := 0 to Count - 1 do
  begin
    ozaForm := Item(i);
    if (Trim(ozaForm.UnitForm) <> '') and
       (ClasePantalla(ozaForm.UnitForm) = nil) then
    begin
      Inc(Result);
      FRegistroLog.RegistrarError('Pantalla sin clase registrada: ' +
                                  ozaForm.Call + ' -> ' +
                                  ozaForm.UnitForm);
    end;
    if (Trim(ozaForm.DataUnit) <> '') and
       (ClaseDataModule(ozaForm.DataUnit) = nil) then
    begin
      Inc(Result);
      FRegistroLog.RegistrarError('Data module sin clase registrada: ' +
                                  ozaForm.Call + ' -> ' +
                                  ozaForm.DataUnit);
    end;
  end;
end;

function TfzaWinF.Count: Integer;
begin
  Result := FList.Count;
end;

function TfzaWinF.Item(AIndex: Integer): TfzaForm;
begin
  Result := FList[AIndex];
end;

function TfzaWinF.CodigoMenu(AItem: TMenuItem): string;
var
  i: Integer;
  sCall: string;
begin
  sCall := '';
  for i := 0 to FList.Count - 1 do
    if (sCall = '') and (FList[i].mnMenuItem = AItem) then
      sCall := FList[i].Call;
  if sCall <> '' then
    Result := 'menu.' + sCall
  else if AItem.Name <> '' then
    Result := 'menu.' + AItem.Name
  else
    Result := '';
end;

function TfzaWinF.CallDeUnit(const AUnit: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FList.Count - 1 do
    if (Result = '') and SameText(FList[i].UnitForm, AUnit) then
      Result := FList[i].Call;
end;

function TfzaWinF.CallRegistrado(AItem: TMenuItem): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FList.Count - 1 do
    if (Result = '') and (FList[i].mnMenuItem = AItem) then
      Result := FList[i].Call;
end;

constructor TfzaWinF.Create(Owner:TComponent;
  const ARegistroLog: IRegistroLog;
  const ALector: ILectorRegistroPantallas);
begin
  if not Assigned(ALector) then
    raise EInvalidOpException.Create(
      SErrorLectorRegistroPantallasNoDisponible);
  FList := TObjectList<TfzaForm>.Create;
  FOwner := Owner;
  FRegistroLog := ARegistroLog;
  FLector := ALector;
end;

destructor TfzaWinF.Destroy;
begin
  FLector := nil;
  FRegistroLog := nil;
  FreeAndNil(FList);
  inherited;
end;

function TfzaWinF.GetDataModuleName(sUnitName: string): String;
var
  ofzaForm:TfzaForm;
begin
  Result := '';
  for ofzaForm in FList do
  begin
    if (Result = '') and ofzaForm.UnitForm.Contains(sUnitName) then
      Result := ofzaForm.DataUnit;
  end;
end;

function TfzaWinF.GetElement(sCall: string): TfzaForm;
var
  ofzaForm:TfzaForm;
begin
  Result := nil;
  for ofzaForm in FList do
  begin
    if (Result = nil) and (ofzaForm.Call = sCall) then
      Result := ofzaForm;
  end;
end;

function TfzaWinF.GetShortCutListOrd: TList<Integer>;
var
  aList: TList<Integer>;
  ofzaForm: TfzaForm;
  sc: TShortCut;
begin
  aList := TList<Integer>.Create;
  for ofzaForm in FList do
  begin
    if Trim(ofzaForm.ShortCut) <> '' then
    begin
      try
        // TextToShortCut hace toda la magia.
        // Convierte 'Ctrl+F1' en el entero correcto (ej: 16496)
        // Convierte 'F5' en el entero correcto (ej: 116)
        sc := TextToShortCut(ofzaForm.ShortCut);
        if sc <> 0 then
          aList.Add(sc);
      except
        // Si hay un texto mal formado en la BD, lo ignoramos para no
        // romper el programa, pero queda constancia en el log.
        on E: Exception do
          FRegistroLog.RegistrarAviso(
            'Atajo "' + ofzaForm.ShortCut + '" invalido: ' +
            E.Message);
      end;
    end;
  end;
  Result := aList;
end;

function TfzaWinF.GetShortCutListString: string;
var
  sList:string;
  ofzaForm:TfzaForm;
begin
  sList := '';
  for ofzaForm in FList do
  begin
    if (Length(ofzaForm.ShortCut) = 1) then
      sList := sList + ofzaForm.ShortCut[1] + ' ';
  end;
  Result := sList;
end;

end.

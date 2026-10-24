{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUser                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión de perfiles de usuario y grupo.                                   }
{    Diccionarios de propiedades por usuario y filtros de carga.               }
{******************************************************************************}
unit inLibUser;

interface

uses Windows, Classes, System.Hash, System.Generics.Collections,
  System.SysUtils, Generics.Defaults, ShlObj, System.diagnostics,
  System.TimeSpan, vcl.dialogs, inLibPerfilesUsuarioIntf;

type
  TProperty = (User, Group, All);
  TDictUserKey = record
    sUser: string;
    sGroup: string;
    oProperty: TProperty;
    sKey: string;
    sSubkey: string;
  end;
  TComponent_Prop_Value = record
    sKey: string;
    sSubkey: string;
    sValue: string;
  end;
  TDictValue = inLibPerfilesUsuarioIntf.TDictValue;
  TProfileUserDicc = TDictionary<TDictUserKey, TDictValue>;
  TProfileDicc = inLibPerfilesUsuarioIntf.TProfileDicc;
function GetPerfilValue(var APerfilDic: TProfileDicc; ASubKey: string): string;
function GetPerfilValueText(var APerfilDic: TProfileDicc; ASubKey: string):
                                                                     WideString;
procedure FilterProfileUserGroup(var APerfilUserDic: TProfileUserDicc;
                                 out APerfilDic: TProfileDicc);
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
                             AFormName: string;
                             const APerfilesUsuario:
                               ILectorPerfilesUsuario); overload;
function GetPerfilSubKeyValueDef( var APerfilDic: TProfileDicc;
                                  ASubKey: string;
                                  sSubSubKey: string;
                                  sValueDef: string): string;
function GetPerfilValueTextDef( var APerfilDic: TProfileDicc;
                                ASubKey: string;
                                sValueDef: WideString): WideString;
function GetPerfilValueDef( var APerfilDic: TProfileDicc;
                            ASubKey: string;
                            sValueDef: string): string;
procedure GetDictionaryKeySubKey( var APerfilDic: TProfileDicc;
                                var oPerfilKeySub: TList<TComponent_Prop_Value>;
                                sFieldName,
                                sColumnName,
                                sGridViewName: string);
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
                             const AFormName, sUsuario, sGrupo: string;
                             const APerfilesUsuario:
                               ILectorPerfilesUsuario); overload;

implementation

uses
  inLibMensajesVcl,
  inLibDir, inLibPerfilesUsuarioValores, inLibMsgConfiguracion;

// Dentro de inLibUser.pas
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
  const AFormName, sUsuario, sGrupo: string;
  const APerfilesUsuario: ILectorPerfilesUsuario);
begin
  if not Assigned(APerfilesUsuario) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  APerfilesUsuario.CargarPerfilFormulario(
    AFormName,
    sUsuario,
    sGrupo,
    APerfilDic);
end;

procedure FilterProfileUserGroup(var APerfilUserDic: TProfileUserDicc;
  out APerfilDic: TProfileDicc);
var
  oPerfilDicNuevo: TProfileDicc;
  oPerfilUserDicCopy: TProfileUserDicc;
  oDictUKey,
    oDictUKeyCopy   : TDictUserKey;
  oDictValue        : TDictValue;
  //Stopwatch         : TStopwatch;   // PARA MEDIR EL RENDIMIENTO DEL HASH
  //Elapsed           : TTimeSpan;
begin
  //Stopwatch := TStopwatch.StartNew;
  APerfilUserDic.TrimExcess;
  APerfilDic := nil;
  oPerfilDicNuevo := TProfileDicc.Create;
  try
    oPerfilUserDicCopy := TProfileUserDicc.Create
      (
        APerfilUserDic,
        TEqualityComparer<TDictUserKey>.Construct
      (
      function(const Left, Right: TDictUserKey): Boolean
      begin
        Result := (Left.sUser = Right.sUser) and
          (Left.sGroup = Right.sGroup) and
          (Left.sKey = Right.sKey) and
          (Left.sSubkey = Right.sSubkey) and
          (Left.oProperty = Right.oProperty);
      end,
      function(const Value: TDictUserKey): Integer
      begin
        Result := Length(Value.sKey); //este hash da un mayor rendimiento ~35 ms
      end
      )
        );
    try
      for oDictUKey in APerfilUserDic.Keys do
      begin
        oDictUKeyCopy := oDictUKey;
        APerfilUserDic.TryGetValue(oDictUKey, oDictValue);
        if (oDictUKey.oProperty = User) then
          //si hay user, no me lo pienso y lo inserto
        begin
          oPerfilDicNuevo.AddOrSetValue(oDictUKey.sSubkey, oDictValue);
        end
        else if (oDictUKey.oProperty = Group) then
          //si hay grupo, busco el mismo key-subkey para user
        begin
          oDictUKeyCopy.oProperty := User;
          if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
            //si no hay user con el mismo key, lo añado
            oPerfilDicNuevo.AddOrSetValue(oDictUKey.sSubkey, oDictValue)
          //añado al perfil por defecto para el grupo
        end
        else if (oDictUKey.oProperty = All) then
          //si hay todos, y no hay user o grupo, añado
        begin
          oDictUKeyCopy.oProperty := User;
          if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
          begin
            oDictUKeyCopy.oProperty := Group;
            if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
              oPerfilDicNuevo.AddOrSetValue(oDictUKey.sSubkey, oDictValue)
                //añado al perfil por defecto
          end;
        end;
      end;
    finally
      FreeAndNil(oPerfilUserDicCopy);
    end;
    APerfilDic := oPerfilDicNuevo;
    oPerfilDicNuevo := nil;
  finally
    FreeAndNil(oPerfilDicNuevo);
  end;
  //Elapsed := Stopwatch.Elapsed;
  //ShowMessage_fza(Elapsed.TotalMilliseconds.ToString);
end;

procedure GetFormUserProfile(
  var APerfilDic: TProfileDicc;
  AFormName: string;
  const APerfilesUsuario: ILectorPerfilesUsuario);
begin
  if not Assigned(APerfilesUsuario) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  APerfilesUsuario.CargarPerfilFormulario(AFormName, APerfilDic);
end;

// Dentro de inLibUser.pas
function GetPerfilValue(var APerfilDic: TPRofileDicc;
  ASubKey: string): string;
var
  oDictValue: TDictValue;
begin
  APerfilDic.TryGetValue(ASubKey, oDictValue);
  Result:= oDictValue.sValue;
end;

procedure GetDictionaryKeySubKey(var APerfilDic: TProfileDicc;
                                var oPerfilKeySub: TList<TComponent_Prop_Value>;
                                sFieldName,
                                sColumnName,
                                sGridViewName: string);
var
  oDictValue        : TDictValue;
  oDictKey          : string;
  iLastDelimiter    : Integer;
  pCPV              : TComponent_Prop_Value;
  sProperty         : string;
begin
  for oDictKey in APerfilDic.Keys do
  begin
    APerfilDic.TryGetValue(oDictKey, oDictValue);
    if (Pos(sFieldName, oDictKey) > 0) then
    begin
      iLastDelimiter := LastDelimiter('_', oDictKey) + 1;
      sProperty := Copy(oDictKey, iLastDelimiter, Length(oDictKey) -
        iLastDelimiter + 1);
      pCPV.sKey := sColumnName;
      pCPV.sSubkey := sProperty;
      pCPV.sValue := oDictValue.sValue;
      oPerfilKeySub.Add(pCPV);
    end;
  end;
end;

function GetPerfilSubKeyValueDef(var APerfilDic: TPRofileDicc;
  ASubKey: string;
  sSubSubKey: string;
  sValueDef: string): string;
begin
  Result := inLibPerfilesUsuarioValores.GetPerfilSubKeyValueDef(
    APerfilDic, ASubKey, sSubSubKey, sValueDef);
end;

function GetPerfilValueText(var APerfilDic: TPRofileDicc;
  ASubKey: string): WideString;
var
  oDictValue        : TDictValue;
begin
  APerfilDic.TryGetValue(ASubKey,
    oDictValue);
  Result := oDictValue.sValueText;
end;

function GetPerfilValueTextDef(var APerfilDic: TPRofileDicc;
  ASubKey: string;
  sValueDef: WideString): WideString;
begin
  Result := inLibPerfilesUsuarioValores.GetPerfilValueTextDef(
    APerfilDic, ASubKey, sValueDef);
end;

function GetPerfilValueDef(var APerfilDic: TProfileDicc;
  ASubKey: string;
  sValueDef: string): string;
begin
  Result := inLibPerfilesUsuarioValores.GetPerfilValueDef(
    APerfilDic,
    ASubKey,
    sValueDef);
end;

end.


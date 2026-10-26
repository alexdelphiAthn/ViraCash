{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorGuardianBorradoMto                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Guardián de permisos del dataset principal de los mantenimientos:         }
{    exige permiso para insertar, modificar, grabar y borrar, y ofrece         }
{    desactivar el registro en lugar de borrarlo.                              }
{******************************************************************************}
unit inLibGestorGuardianBorradoMto;

interface

uses
  System.Classes, Data.DB, cxDBNavigator, cxGridDBTableView,
  inLibPermisosIntf;

type
  // Resultado del dialogo de borrado: cancelar, desactivar o borrar igual.
  TAccionBorrado = (abContinuar, abDesactivar, abCancelar);

  TPuedeAccionMto = function(
    AAccion: TAccionPermisoMto): Boolean of object;
  TNombreCampoActivoMto = function: string of object;
  TContarHijosActivosMto = function: Integer of object;
  TDescripcionHijosMto = function: string of object;

const
  // Valor de ContarHijosActivos de un mantenimiento que valida y
  // confirma el borrado él mismo (p. ej. Facturas: «¿Borrar la factura
  // ...? Se eliminarán sus líneas...»): el guardián solo exige el
  // permiso y no hace su pregunta genérica, que se sumaría a la propia.
  cBorradoConConfirmacionPropia = -1;

type

  // Encadena los eventos Before* del dataset principal para exigir
  // permisos antes de insertar, modificar, grabar o borrar, y para
  // ofrecer desactivar el registro en lugar de borrarlo.
  TGestorGuardianBorradoMto = class
  private
    FDataSource: TDataSource;
    FNavegador: TcxDBNavigator;
    FVistaPrincipal: TcxGridDBTableView;
    FPuedeAccion: TPuedeAccionMto;
    FNombreCampoActivo: TNombreCampoActivoMto;
    FContarHijosActivos: TContarHijosActivosMto;
    FDescripcionHijos: TDescripcionHijosMto;
    FConfirmacionPersonalizada: TDescripcionHijosMto;
    FBeforeInsertOrig: TDataSetNotifyEvent;
    FBeforeEditOrig: TDataSetNotifyEvent;
    FBeforePostOrig: TDataSetNotifyEvent;
    FBeforeDeleteOrig: TDataSetNotifyEvent;
    FInstalado: Boolean;
    FDesactivandoPorBorrado: Boolean;
    function PreguntarAccionBorrado: TAccionBorrado;
    procedure AntesDeInsertar(DataSet: TDataSet);
    procedure AntesDeEditar(DataSet: TDataSet);
    procedure AntesDeGrabar(DataSet: TDataSet);
    procedure AntesDeBorrar(DataSet: TDataSet);
  public
    constructor Create(
      ADataSource: TDataSource;
      ANavegador: TcxDBNavigator;
      AVistaPrincipal: TcxGridDBTableView;
      APuedeAccion: TPuedeAccionMto;
      ANombreCampoActivo: TNombreCampoActivoMto;
      AContarHijosActivos: TContarHijosActivosMto;
      ADescripcionHijos: TDescripcionHijosMto;
      AConfirmacionPersonalizada: TDescripcionHijosMto = nil);
    procedure Instalar;
    procedure ComprobarPermisoGrabar(AEstado: TDataSetState);
  end;

implementation

uses
  Winapi.Windows, System.SysUtils,
  inLibMensajesVcl, inLibMsgComun, inLibMsgConfiguracion;

constructor TGestorGuardianBorradoMto.Create(
  ADataSource: TDataSource;
  ANavegador: TcxDBNavigator;
  AVistaPrincipal: TcxGridDBTableView;
  APuedeAccion: TPuedeAccionMto;
  ANombreCampoActivo: TNombreCampoActivoMto;
  AContarHijosActivos: TContarHijosActivosMto;
  ADescripcionHijos: TDescripcionHijosMto;
  AConfirmacionPersonalizada: TDescripcionHijosMto);
begin
  inherited Create;
  FDataSource := ADataSource;
  FNavegador := ANavegador;
  FVistaPrincipal := AVistaPrincipal;
  FPuedeAccion := APuedeAccion;
  FNombreCampoActivo := ANombreCampoActivo;
  FContarHijosActivos := AContarHijosActivos;
  FDescripcionHijos := ADescripcionHijos;
  FConfirmacionPersonalizada := AConfirmacionPersonalizada;
  FInstalado := False;
  FDesactivandoPorBorrado := False;
end;

procedure TGestorGuardianBorradoMto.Instalar;
var
  ds: TDataSet;
begin
  if not FInstalado then
  begin
    ds := FDataSource.DataSet;
    if ds <> nil then
    begin
      // Encadenamos los handlers originales del data module.
      FBeforeInsertOrig := ds.BeforeInsert;
      FBeforeEditOrig := ds.BeforeEdit;
      FBeforePostOrig := ds.BeforePost;
      FBeforeDeleteOrig := ds.BeforeDelete;
      ds.BeforeInsert := AntesDeInsertar;
      ds.BeforeEdit := AntesDeEditar;
      ds.BeforePost := AntesDeGrabar;
      ds.BeforeDelete := AntesDeBorrar;
      // Desactivamos el dialogo nativo de confirmacion del navegador para
      // no mostrar dos popups en cascada (el nativo y el nuestro). El
      // cxGrid del listado tiene su propio mini navegador; lo cubrimos
      // tambien si esta presente.
      if Assigned(FNavegador) then
        FNavegador.Buttons.ConfirmDelete := False;
      if Assigned(FVistaPrincipal) then
      begin
        FVistaPrincipal.OptionsData.DeletingConfirmation := False;
        if Assigned(FVistaPrincipal.Navigator) then
          FVistaPrincipal.Navigator.Buttons.ConfirmDelete := False;
      end;
      FInstalado := True;
    end;
  end;
end;

procedure TGestorGuardianBorradoMto.AntesDeInsertar(DataSet: TDataSet);
begin
  if not FPuedeAccion(apmInsertar) then
  begin
    ShowMessage_fza(SErrorPermisoInsertarRegistro);
    Abort;
  end
  else if Assigned(FBeforeInsertOrig) then
    FBeforeInsertOrig(DataSet);
end;

procedure TGestorGuardianBorradoMto.AntesDeEditar(DataSet: TDataSet);
begin
  if (not FDesactivandoPorBorrado) and
     (not FPuedeAccion(apmModificar)) then
  begin
    ShowMessage_fza(SErrorPermisoModificarRegistro);
    Abort;
  end
  else if Assigned(FBeforeEditOrig) then
    FBeforeEditOrig(DataSet);
end;

procedure TGestorGuardianBorradoMto.ComprobarPermisoGrabar(
  AEstado: TDataSetState);
var
  bPermitido: Boolean;
begin
  bPermitido :=
    FDesactivandoPorBorrado or
    ((AEstado = dsInsert) and FPuedeAccion(apmInsertar)) or
    ((AEstado in [dsEdit, dsBrowse]) and FPuedeAccion(apmModificar));
  if not bPermitido then
  begin
    ShowMessage_fza(SErrorPermisoGuardarRegistro);
    Abort;
  end;
end;

procedure TGestorGuardianBorradoMto.AntesDeGrabar(DataSet: TDataSet);
begin
  ComprobarPermisoGrabar(DataSet.State);
  if Assigned(FBeforePostOrig) then
    FBeforePostOrig(DataSet);
end;

procedure TGestorGuardianBorradoMto.AntesDeBorrar(DataSet: TDataSet);
var
  sCampoActivo: string;
begin
  if not FPuedeAccion(apmBorrar) then
  begin
    ShowMessage_fza(SErrorPermisoBorrarRegistro);
    Abort;
  end
  else
  begin
    case PreguntarAccionBorrado of
      abCancelar:
        Abort;
      abDesactivar:
        begin
          sCampoActivo := FNombreCampoActivo;
          if (sCampoActivo <> '') and
             (DataSet.FindField(sCampoActivo) <> nil) then
          begin
            FDesactivandoPorBorrado := True;
            try
              if not (DataSet.State in [dsEdit, dsInsert]) then
                DataSet.Edit;
              DataSet.FieldByName(sCampoActivo).AsString := 'N';
              DataSet.Post;
            finally
              FDesactivandoPorBorrado := False;
            end;
          end;
          Abort;
        end;
      abContinuar:
        if Assigned(FBeforeDeleteOrig) then
          FBeforeDeleteOrig(DataSet);
    end;
  end;
end;

function TGestorGuardianBorradoMto.PreguntarAccionBorrado: TAccionBorrado;
var
  sCampoActivo, sDescHijos, sMsg: string;
  iHijos: Integer;
  bDesactivable: Boolean;
  iResp: Integer;
begin
  iHijos := FContarHijosActivos;
  sCampoActivo := FNombreCampoActivo;
  bDesactivable := (sCampoActivo <> '') and
                   Assigned(FDataSource.DataSet) and
                   (FDataSource.DataSet.FindField(sCampoActivo) <> nil);
  // Si el registro ya esta desactivado, no ofrecemos "desactivar" otra vez:
  // el usuario tendra solo Borrar/Cancelar.
  if bDesactivable and
     SameText(
       FDataSource.DataSet.FieldByName(sCampoActivo).AsString, 'N') then
    bDesactivable := False;
  sDescHijos := FDescripcionHijos;
  if sDescHijos = '' then
    sDescHijos := SDescripcionHijosGenerica;
  sMsg := '';
  if Assigned(FConfirmacionPersonalizada) then
    sMsg := FConfirmacionPersonalizada;
  if sMsg <> '' then
  begin
    if MessageBox_fza(PChar(sMsg), PChar(STituloConfirmarEliminacion),
      MB_YESNO + MB_ICONWARNING + MB_DEFBUTTON2) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
  end
  // Caso 0: el mantenimiento confirma por su cuenta.
  else if iHijos = cBorradoConConfirmacionPropia then
    Result := abContinuar
  // Caso 1: tabla no desactivable y sin hijos -> confirmacion simple Si/No.
  else if (not bDesactivable) and (iHijos = 0) then
  begin
    if MessageBox_fza(
        PChar(SPreguntaEliminarRegistro),
        PChar(STituloConfirmarEliminacion),
        MB_YESNO + MB_ICONWARNING) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
  end
  // Caso 2: tabla no desactivable pero tiene hijos -> avisar y Si/No.
  else if not bDesactivable then
  begin
    sMsg := Format(SPreguntaEliminarRegistroConHijos,
                   [iHijos, sDescHijos]);
    if MessageBox_fza(PChar(sMsg),
        PChar(STituloConfirmarEliminacion),
        MB_YESNO + MB_ICONWARNING + MB_DEFBUTTON2) = ID_YES then
      Result := abContinuar
    else
      Result := abCancelar;
  end
  // Caso 3 y 4: tabla desactivable, con o sin hijos.
  else
  begin
    if iHijos > 0 then
      sMsg := Format(SAvisoDesactivarRegistroConHijos,
                     [iHijos, sDescHijos])
    else
      sMsg := SAvisoDesactivarRegistroSinHijos;
    sMsg := sMsg + STextoOpcionesBorradoRegistro;
    iResp := MessageBox_fza(PChar(sMsg),
               PChar(STituloConfirmarEliminacion),
               MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON1);
    case iResp of
      ID_YES: Result := abDesactivar;
      ID_NO: Result := abContinuar;
    else
      Result := abCancelar;
    end;
  end;
end;

end.

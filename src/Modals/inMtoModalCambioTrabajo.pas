{ Captura y confirmación de cambios de trabajo. TRJ-004, 02/11/2026. }
unit inMtoModalCambioTrabajo;

interface

uses
  System.Classes, Data.DB, inMtoModalAceptCancel;

type
  TfrmModalCambioTrabajo = class(TfrmModalAceptCancel)
  public
    class procedure Ejecutar(AOwner: TComponent;
      ALinea: TDataSet; ARepetir: Boolean);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs,
  inLibCambiosTrabajo, UniDataCambiosTrabajo,
  inLibMensajesVcl, inLibPermisosIntf, inMtoModalDatosOrden;

class procedure TfrmModalCambioTrabajo.Ejecutar(AOwner: TComponent;
  ALinea: TDataSet; ARepetir: Boolean);
var
  oContexto: TfrmModalCambioTrabajo;
  oRepositorio: TRepositorioCambiosTrabajo;
  rCambio: TCambioTrabajo;
  aValores: TArray<string>;
  gId: TGUID;
  iResultado: Int64;
begin
  oContexto := TfrmModalCambioTrabajo.Create(AOwner);
  try
    if not oContexto.Permisos.TienePermiso('reparaciones.cambiarTrabajo',
      paExigirConcesion) then
      raise EInvalidOpException.Create(SCambioTrabajoSinPermiso);
    rCambio := Default(TCambioTrabajo);
    CreateGUID(gId);
    rCambio.Id := Copy(GUIDToString(gId), 2, 36);
    rCambio.Orden := ALinea.FieldByName('ID_GAR_GARLIN').AsLargeInt;
    rCambio.Linea := ALinea.FieldByName('ID_GARLIN').AsLargeInt;
    rCambio.Revision := ALinea.FieldByName('REVISION_CAMBIO').AsString;
    rCambio.Repetir := ARepetir;
    aValores := ['', ALinea.FieldByName('TIPO_EJECUTOR_GARLIN').AsString,
      '', ALinea.FieldByName('CANTIDAD_GARLIN').AsString, '0', ''];
    if TfrmModalDatosOrden.Ejecutar(AOwner, SCambioTrabajoTitulo,
      [SCambioTrabajoMotivo, SCambioTrabajoTipo, SCambioTrabajoCodigo,
       SCambioTrabajoCantidad, SCambioTrabajoCoste,
       SCambioTrabajoResponsable], aValores, [500,20,20,20,20,100]) then
    begin
      rCambio.Motivo := Trim(aValores[0]);
      rCambio.TipoEjecutor := UpperCase(Trim(aValores[1]));
      rCambio.Ejecutor := Trim(aValores[2]);
      rCambio.Cantidad := StrToCurr(aValores[3]);
      rCambio.CosteAdicional := StrToCurr(aValores[4]);
      rCambio.ResponsableCoste := Trim(aValores[5]);
      rCambio.Aceptado := MessageDlg_fza(SCambioTrabajoConfirmar,
        mtConfirmation, [mbYes,mbNo], 0, mbNo) = mrYes;
      if rCambio.Aceptado then
      begin
        oRepositorio := TRepositorioCambiosTrabajo.Create(
          oContexto.ConexionPrincipal, oContexto.IdentidadSesion.Usuario,
          oContexto.Permisos);
        try
          iResultado := oRepositorio.Guardar(rCambio);
          ShowMessage_fza(Format(SCambioTrabajoGrabado, [iResultado]));
        finally
          FreeAndNil(oRepositorio);
        end;
      end;
    end;
  finally
    FreeAndNil(oContexto);
  end;
end;

end.

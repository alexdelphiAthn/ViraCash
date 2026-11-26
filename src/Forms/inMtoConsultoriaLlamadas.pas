{ IDE integrado y proyecto inicial del mantenimiento de llamadas. }
unit inMtoConsultoriaLlamadas;

interface

uses
  System.Classes, Uni, inLibPermisosIntf;


procedure AbrirLlamadas(AOwner: TComponent; AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario, ACliente: string;
  AEditar: Boolean);

implementation

uses
  Winapi.Windows, System.SysUtils, System.JSON, System.Rtti, System.TypInfo,
  System.IOUtils, System.UITypes, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms,
  cxGrid, cxButtons, cxLabel, cxTextEdit, cxMemo, cxCheckBox,
  cxDropDownEdit, cxCalendar, cxSpinEdit, cxCurrencyEdit,
  atScript, IDEMain, IDEDialog, Vcl.ScripterInit, Vcl.ScriptForm, dxSkinsForm,
  ap_Classes, ap_SysUtils, ap_Controls, ap_Forms, ap_Graphics, ap_Dialogs,
  ap_ExtCtrls, ap_StdCtrls, inLibMensajesVcl, UniDataLlamadasCliente,
  inMtoLlamadasAccionesVcl, inLibMenusScripter, inLibMsgScripter;

{$R 'Consultoria\Llamadas.res'}

type
  TProyectoLlamadas = class(TComponent)
  private
    FArchivos: TJSONObject;
    FMotor: TIDEScripter;
    FIde: TIDEEngine;
    FCambios: Boolean;
    FEnDisenador: Boolean;
    procedure Existe(Sender: TObject; ATipo: TIDEFileType;
      ANombre: string; var AExiste: Boolean);
    procedure Leer(Sender: TObject; ATipo: TIDEFileType; ANombre: string;
      var ATexto: string; AUnidad: TIDEProjectFile; var ATratado: Boolean);
    procedure Guardar(Sender: TObject; ATipo: TIDEFileType; ANombre: string;
      ATexto: string; AUnidad: TIDEProjectFile; var ATratado: Boolean);
    procedure ElegirUnidad(Sender: TObject; ATipo: TIDEFileType;
      var ANombre: string; AUnidad: TIDEProjectFile;
      var AAceptado, ATratado: Boolean);
    procedure BuscarUnidad(Sender: TObject; ATipo: TIDEFileType;
      var ANombre: string; var AAceptado, ATratado: Boolean);
    procedure RegistrarPaleta;
  public
    constructor Crear(AOwner: TComponent; const ATexto: string;
      AAcciones: TAccionesLlamadas; AEditar: Boolean = False);
    destructor Destroy; override;
    procedure Ejecutar(AEditar: Boolean);
  end;

const
  ArchivosIniciales: array[0..5] of string = (
    'Llamadas.ssproj',
    'Inicio.psc',
    'Historial.psc',
    'Ficha.psc',
    'Ficha.sfm',
    'Historial.sfm'
  );

  Ejemplos: array[0..3] of string = (
    'AltaRapida', 'EditarResultado', 'InformeLlamadas', 'AgendaSeguimiento'
  );

function RecursoTexto(const ANombre: string): string;
var
  oFlujo: TResourceStream;
  oLector: TStreamReader;
begin
  oFlujo := TResourceStream.Create(HInstance, ANombre, RT_RCDATA);
  try
    oLector := TStreamReader.Create(oFlujo, TEncoding.UTF8);
    try
      Result := oLector.ReadToEnd;
    finally
      oLector.Free;
    end;
  finally
    oFlujo.Free;
  end;
end;

constructor TProyectoLlamadas.Crear(AOwner: TComponent; const ATexto: string;
  AAcciones: TAccionesLlamadas; AEditar: Boolean);
var
  i: Integer;
begin
  inherited Create(AOwner);
  if AEditar then
  begin
    // TMS guarda y restaura WindowProc al cambiar de formulario.
    // Evitar que el skin enganche esa misma ventana durante el diseno.
    TdxSkinIgnoredFormList.Add(TScriptForm, False);
    FEnDisenador := True;
  end;
  if ATexto = '' then
  begin
    FArchivos := TJSONObject.Create;
    for i := Low(ArchivosIniciales) to High(ArchivosIniciales) do
      FArchivos.AddPair(LowerCase(ArchivosIniciales[i]),
        RecursoTexto('LLAMADAS_' + IntToStr(i)));
  end
  else
    FArchivos := TJSONObject.ParseJSONValue(ATexto) as TJSONObject;
  if FArchivos = nil then
    raise EConvertError.Create(SProyectoIlegible);
  FMotor := TIDEScripter.Create(Self);
  FMotor.LibOptions.UseScriptFiles := False;
  FMotor.DefineClassByRTTI(TAccionesLlamadas, '', [mvPublished]);
  FMotor.AddObject('Llamadas', AAcciones);
  FIde := TIDEEngine.Create(Self);
  FIde.Scripter := FMotor;
  FIde.OnCheckValidFile := Existe;
  FIde.OnLoadFile := Leer;
  FIde.OnSaveFile := Guardar;
  FIde.OnSaveDialog := ElegirUnidad;
  FIde.OnOpenDialog := BuscarUnidad;
  RegistrarPaleta;
  if not FIde.OpenProject('Llamadas.ssproj') or (FIde.MainUnit = nil) then
    raise EConvertError.Create(SFaltaInicio);
end;

destructor TProyectoLlamadas.Destroy;
begin
  FIde.Free;
  FMotor.Free;
  FArchivos.Free;
  if FEnDisenador then
    TdxSkinIgnoredFormList.Remove(TScriptForm, False);
  inherited;
end;

procedure TProyectoLlamadas.RegistrarPaleta;

  procedure Registrar(AClase: System.Classes.TComponentClass; const AUnidad: string = '');
  begin
    System.Classes.RegisterClass(AClase);
    FIde.RegisterComponent('ViraCash', AClase, AUnidad);
  end;

begin
  FIde.RegisteredComps.Clear;
  Registrar(TPanel, 'ExtCtrls');
  Registrar(TcxLabel);
  Registrar(TcxTextEdit);
  Registrar(TcxMemo);
  Registrar(TcxSpinEdit);
  Registrar(TcxCurrencyEdit);
  Registrar(TcxDateEdit);
  Registrar(TcxComboBox);
  Registrar(TcxCheckBox);
  Registrar(TcxButton);
  Registrar(TcxGrid);
end;

procedure TProyectoLlamadas.Existe(Sender: TObject; ATipo: TIDEFileType;
  ANombre: string; var AExiste: Boolean);
begin
  AExiste := FArchivos.GetValue(LowerCase(ExtractFileName(ANombre))) <> nil;
end;

procedure TProyectoLlamadas.Leer(Sender: TObject; ATipo: TIDEFileType;
  ANombre: string; var ATexto: string; AUnidad: TIDEProjectFile;
  var ATratado: Boolean);
var
  oArchivo: TJSONValue;
begin
  oArchivo := FArchivos.GetValue(LowerCase(ExtractFileName(ANombre)));
  if not (oArchivo is TJSONString) then
    raise EConvertError.CreateFmt(SFaltaArchivo, [ANombre]);
  ATexto := oArchivo.Value;
  ATratado := True;
end;

procedure TProyectoLlamadas.Guardar(Sender: TObject; ATipo: TIDEFileType;
  ANombre: string; ATexto: string; AUnidad: TIDEProjectFile;
  var ATratado: Boolean);
var
  sClave: string;
  oValor: TJSONValue;
begin
  sClave := LowerCase(ExtractFileName(ANombre));
  if (ATipo = iftProject) and (sClave <> 'llamadas.ssproj') then
    raise EArgumentException.Create(SNombreProyecto);
  oValor := FArchivos.GetValue(sClave);
  if (oValor = nil) or (oValor.Value <> ATexto) then
  begin
    FArchivos.RemovePair(sClave).Free;
    FArchivos.AddPair(sClave, ATexto);
    FCambios := True;
  end;
  ATratado := True;
end;

procedure TProyectoLlamadas.ElegirUnidad(Sender: TObject; ATipo: TIDEFileType;
  var ANombre: string; AUnidad: TIDEProjectFile;
  var AAceptado, ATratado: Boolean);
begin
  ATratado := True;
  AAceptado := True;
  if ATipo = iftProject then
    ANombre := 'Llamadas.ssproj'
  else
  begin
    ANombre := ExtractFileName(ANombre);
    AAceptado := InputQuery(STituloUnidad, SNombre, ANombre);
    if AAceptado then
    begin
      ANombre := ExtractFileName(ANombre);
      if not IsValidIdent(ChangeFileExt(ANombre, '')) then
        raise EArgumentException.Create(SNombreInvalido);
    end;
  end;
end;

procedure TProyectoLlamadas.BuscarUnidad(Sender: TObject; ATipo: TIDEFileType;
  var ANombre: string; var AAceptado, ATratado: Boolean);
var
  sEjemplo, sBase, sCodigo, sFormulario: string;
begin
  ATratado := True;
  if ATipo = iftProject then
  begin
    ANombre := 'Llamadas.ssproj';
    AAceptado := True;
  end
  else
  begin
    AAceptado := InputQuery(SAbrirUnidad,
      SNombre + ' (' + string.Join(', ', Ejemplos) + ')', ANombre);
    if AAceptado then
    begin
      ANombre := ExtractFileName(Trim(ANombre));
      if ExtractFileExt(ANombre) = '' then
        ANombre := ANombre + '.psc';
      for sEjemplo in Ejemplos do
        if SameText(ANombre, sEjemplo + '.psc') then
        begin
          sBase := LowerCase(sEjemplo);
          if (FArchivos.GetValue(sBase + '.psc') = nil) and
             (FArchivos.GetValue(sBase + '.sfm') = nil) then
          begin
            sCodigo := RecursoTexto(UpperCase(sEjemplo) + '_PSC');
            sFormulario := RecursoTexto(UpperCase(sEjemplo) + '_SFM');
            FArchivos.AddPair(sBase + '.psc', sCodigo);
            FArchivos.AddPair(sBase + '.sfm', sFormulario);
          end;
        end;
      ANombre := TPath.Combine(FIde.BasePath, ANombre);
    end;
  end;
end;

procedure TProyectoLlamadas.Ejecutar(AEditar: Boolean);
var
  oDialogo: TIDEDialog;
begin
  if AEditar then
  begin
    oDialogo := TIDEDialog.Create(nil);
    try
      oDialogo.Engine := FIde;
      oDialogo.OnCreateIDEForm := TMenusScripter.AlCrearEditor;
      oDialogo.Title := 'ViraCash | ' + STituloDisenador + ' | %s';
      oDialogo.IDECloseAction := icaNothing;
      repeat
        oDialogo.Execute;
      until FIde.DlgCloseAll;
    finally
      oDialogo.Free;
    end;
  end
  else
    FIde.RunProject;
end;

procedure AbrirLlamadas(AOwner: TComponent; AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario, ACliente: string;
  AEditar: Boolean);
var
  oRepositorio: TRepositorioLlamadas;
  oAcciones: TAccionesLlamadas;
  oProyecto, oValidacion: TProyectoLlamadas;
  iVersion: Integer;
  sContenido, sCopia: string;
begin
  oRepositorio := TRepositorioLlamadas.Create(AConexion, APermisos,
    AUsuario, ACliente);
  try
    if AEditar then
      oRepositorio.ExigirEditor;
    sContenido := oRepositorio.LeerProyecto(iVersion);
    oAcciones := TAccionesLlamadas.Create(oRepositorio);
    try
      oProyecto := TProyectoLlamadas.Crear(AOwner, sContenido, oAcciones,
        AEditar);
      try
        oProyecto.Ejecutar(AEditar);
        if AEditar and oProyecto.FCambios and
          (MessageDlg_fza(SPublicar,
            mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
          sContenido := oProyecto.FArchivos.ToJSON;
          try
            oValidacion := TProyectoLlamadas.Crear(nil, sContenido, oAcciones);
            try
              oValidacion.FIde.CompileProject;
            finally
              oValidacion.Free;
            end;
            oRepositorio.Publicar(sContenido, iVersion);
          except
            sCopia := TPath.Combine(TPath.GetDocumentsPath,
              'Llamadas-' + TGUID.NewGuid.ToString + '.json');
            TFile.WriteAllText(sCopia, sContenido, TEncoding.UTF8);
            ShowMessage_fza(Format(SCopia, [sCopia]));
            raise;
          end;
        end;
      finally
        oProyecto.Free;
      end;
    finally
      oAcciones.Free;
    end;
  finally
    oRepositorio.Free;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorPerfilesMto                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona los perfiles de pantalla de los mantenimientos genéricos.        }
{******************************************************************************}
unit inLibGestorPerfilesMto;

interface

uses
  System.Classes, Vcl.Forms, Data.DB, cxLabel, cxGridCustomTableView,
  inLibPerfilesUsuarioIntf, inLibPerfilesMtoPersistenciaIntf,
  inLibConfigCamposIntf, inLibLogIntf;

type
  TSolicitarDestinoPerfilMto = function(
    const ADescripcion: string;
    ADescripcionEditable: Boolean;
    out APermisos: string
  ): Boolean of object;

  TRecogerPerfilesParticularesMto = procedure(
    var APerfiles: TPerfilList;
    const APermisos: string
  ) of object;

  TResetearGridPerfilMto = procedure(
    const ANombreGrid, ANombreFormulario, APermisos: string
  ) of object;

  TBorrarGuiasPerfilMto = procedure of object;

  TGestorPerfilesMto = class
  private
    FFormulario: TCustomForm;
    FDatos: TDataSource;
    FEtiquetaTabla: TcxLabel;
    FServicioLectura: ILectorPerfilesUsuario;
    FServicioEscritura: IEscritorPerfilesUsuario;
    FPersistencia: IPersistenciaPerfilesMto;
    FConfiguracionCampos: IConfiguracionCampos;
    FRegistroLog: IRegistroLog;
    FSolicitarDestino: TSolicitarDestinoPerfilMto;
    FRecogerParticulares: TRecogerPerfilesParticularesMto;
    FResetearGrid: TResetearGridPerfilMto;
    FBorrarGuias: TBorrarGuiasPerfilMto;
    FPerfil: TProfileDicc;
    procedure AnadirPerfil(
      APerfiles: TPerfilList;
      const APermisos, ASubclave, AValor: string);
    function NombreTablaOrigen: string;
    function DebeAplicarDisenoGuardado(
      AVista: TcxCustomGridTableView): Boolean;
    procedure AnadirPerfilesSeparadores(
      APerfiles: TPerfilList;
      const APermisos: string);
  public
    constructor Create(
      AFormulario: TCustomForm;
      ADatos: TDataSource;
      AEtiquetaTabla: TcxLabel;
      const AServicioLectura: ILectorPerfilesUsuario;
      const AServicioEscritura: IEscritorPerfilesUsuario;
      const AConfiguracionCampos: IConfiguracionCampos;
      const ARegistroLog: IRegistroLog;
      ASolicitarDestino: TSolicitarDestinoPerfilMto;
      ARecogerParticulares: TRecogerPerfilesParticularesMto;
      AResetearGrid: TResetearGridPerfilMto;
      ABorrarGuias: TBorrarGuiasPerfilMto);
    destructor Destroy; override;
    procedure AsignarPersistencia(
      const APersistencia: IPersistenciaPerfilesMto);
    procedure CargarPerfil(
      const AUsuario, AGrupo: string);
    function Valor(
      const ASubclave, AValorPredeterminado: string): string;
    procedure AplicarEtiquetas;
    procedure RestaurarSeparadores;
    procedure CargarPerfilesComunes(
      const AUsuarioGrupo: string = PERFIL_TODOS);
    procedure CargarCaptions;
    procedure CargarColumnas;
    procedure ConstruirPerfilesLayout(
      const APermisos: string;
      APerfiles: TPerfilList);
    procedure GrabarLayout(const ADescripcion: string);
    procedure ResetearLayout(const ADescripcion: string);
    procedure AbrirPerfiles(
      AVisible: Boolean;
      const ANombreDataModule: string);
    procedure RestaurarFoco(AVista: TcxCustomGridTableView);
    property Perfil: TProfileDicc read FPerfil;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Uni,
  Vcl.Controls, cxGridDBTableView, cxSplitter, inLibDevExp, inLibUser,
  inLibDatasets, inLibMsgComun, inLibMsgConfiguracion;

constructor TGestorPerfilesMto.Create(
  AFormulario: TCustomForm;
  ADatos: TDataSource;
  AEtiquetaTabla: TcxLabel;
  const AServicioLectura: ILectorPerfilesUsuario;
  const AServicioEscritura: IEscritorPerfilesUsuario;
  const AConfiguracionCampos: IConfiguracionCampos;
  const ARegistroLog: IRegistroLog;
  ASolicitarDestino: TSolicitarDestinoPerfilMto;
  ARecogerParticulares: TRecogerPerfilesParticularesMto;
  AResetearGrid: TResetearGridPerfilMto;
  ABorrarGuias: TBorrarGuiasPerfilMto);
begin
  inherited Create;
  FFormulario := AFormulario;
  FDatos := ADatos;
  FEtiquetaTabla := AEtiquetaTabla;
  FServicioLectura := AServicioLectura;
  FServicioEscritura := AServicioEscritura;
  FPersistencia := nil;
  FConfiguracionCampos := AConfiguracionCampos;
  FRegistroLog := ARegistroLog;
  FSolicitarDestino := ASolicitarDestino;
  FRecogerParticulares := ARecogerParticulares;
  FResetearGrid := AResetearGrid;
  FBorrarGuias := ABorrarGuias;
  FPerfil := nil;
end;

destructor TGestorPerfilesMto.Destroy;
begin
  FreeAndNil(FPerfil);
  FServicioLectura := nil;
  FServicioEscritura := nil;
  FPersistencia := nil;
  FConfiguracionCampos := nil;
  FRegistroLog := nil;
  inherited;
end;

procedure TGestorPerfilesMto.AsignarPersistencia(
  const APersistencia: IPersistenciaPerfilesMto);
begin
  FPersistencia := APersistencia;
end;

procedure TGestorPerfilesMto.CargarPerfil(
  const AUsuario, AGrupo: string);
begin
  if not Assigned(FServicioLectura) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  FreeAndNil(FPerfil);
  FServicioLectura.CargarPerfilFormulario(
    FFormulario.Name, AUsuario, AGrupo, FPerfil);
  if not Assigned(FPerfil) then
    FPerfil := TProfileDicc.Create;
end;

function TGestorPerfilesMto.Valor(
  const ASubclave, AValorPredeterminado: string): string;
begin
  Result := AValorPredeterminado;
  if Assigned(FPerfil) then
    Result := GetPerfilValueDef(
      FPerfil, ASubclave, AValorPredeterminado);
end;

function TGestorPerfilesMto.NombreTablaOrigen: string;
begin
  Result := '';
  if Assigned(FDatos) and Assigned(FDatos.DataSet) then
  begin
    if FDatos.DataSet is TUniQuery then
      // El extractor RTL toma el primer FROM aunque pertenezca a una
      // subconsulta. El detector propio solo acepta el FROM de nivel cero.
      Result := ExtraerTablaDeSQL(
        TUniQuery(FDatos.DataSet).SQL.Text)
    else if FDatos.DataSet is TUniStoredProc then
      Result := TUniStoredProc(FDatos.DataSet).StoredProcName;
  end;
end;

function TGestorPerfilesMto.DebeAplicarDisenoGuardado(
  AVista: TcxCustomGridTableView): Boolean;
var
  iItem: Integer;
  sCampo: string;
begin
  Result := SameText(
    Trim(Valor(AVista.Name + '__oApplyWidth', 'False')), 'True');
  if Result then
  begin
    // Un diseño marcado para aplicarse pero sin columnas guardadas no
    // describe nada: restaurarlo pondría visibles todas las columnas
    // ocultas del DFM, que es lo que pasaba con los grabados antiguos de
    // pestañas con la consulta cerrada.
    Result := False;
    iItem := 0;
    while (not Result) and (iItem < AVista.ItemCount) do
    begin
      sCampo := GetItemFieldName(AVista.Items[iItem]);
      Result := (sCampo <> '') and
        (Valor(AVista.Name + '_' + sCampo + '_Visible', '') <> '');
      Inc(iItem);
    end;
    if (not Result) and Assigned(FRegistroLog) then
      FRegistroLog.RegistrarAviso(Format(
        'Perfil de %s.%s sin columnas guardadas: se conserva el diseño',
        [FFormulario.Name, AVista.Name]));
  end;
end;

procedure TGestorPerfilesMto.AplicarEtiquetas;
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
  oGrids: TList<TcxCustomGridTableView>;
begin
  if Assigned(FEtiquetaTabla) and
     Assigned(FDatos) and
     Assigned(FDatos.DataSet) then
    FEtiquetaTabla.Caption := NombreTablaOrigen;
  oGrids := TList<TcxCustomGridTableView>.Create;
  try
    for i := 0 to FFormulario.ComponentCount - 1 do
    begin
      if FFormulario.Components[i] is TcxCustomGridTableView then
        oGrids.Add(
          TcxCustomGridTableView(FFormulario.Components[i]));
    end;
    if SameText(
      Trim(Valor('oCreateItems', 'False')), 'True') then
    begin
      for oGrid in oGrids do
      begin
        if SameText(
          Trim(Valor(
            oGrid.Name + '__oCreateItems', 'False')),
          'True') then
        begin
          oGrid.BeginUpdate;
          try
            CrearItemsFaltantes(oGrid, FRegistroLog);
          finally
            oGrid.EndUpdate;
          end;
        end;
      end;
    end;
    if SameText(
      Trim(Valor('oApplyWidth', 'False')), 'True') then
    begin
      for oGrid in oGrids do
      begin
        if DebeAplicarDisenoGuardado(oGrid) then
        begin
          PonerAnchosTitulos(
            oGrid,
            FFormulario.Name,
            FPerfil,
            FConfiguracionCampos,
            FRegistroLog);
          RestaurarFocoGrid(oGrid, FPerfil, FRegistroLog);
        end;
      end;
    end;
  finally
    FreeAndNil(oGrids);
  end;
  // Los perfiles ya no sustituyen textos. La traducción usará su catálogo.
end;

procedure TGestorPerfilesMto.CargarPerfilesComunes(
  const AUsuarioGrupo: string);
begin
  if not Assigned(FServicioEscritura) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oRenameComponents', 'False');
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oCreateItems', 'False');
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oBusqGlobal', 'Grid');
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oApplyWidth', 'True');
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oMostrarPerfil', 'False');
  FServicioEscritura.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oGetSQLFromDB', 'False');
end;

procedure TGestorPerfilesMto.CargarCaptions;
begin
  // Desactivado: los captions no se guardan en perfiles de usuario.
end;

procedure TGestorPerfilesMto.CargarColumnas;
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
begin
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxCustomGridTableView then
    begin
      oGrid := TcxCustomGridTableView(
        FFormulario.Components[i]);
      GetSettingsColumn(
        oGrid, FFormulario.Name, FFormulario.Owner,
        FServicioEscritura);
    end;
  end;
end;

procedure TGestorPerfilesMto.AnadirPerfil(
  APerfiles: TPerfilList;
  const APermisos, ASubclave, AValor: string);
var
  oItem: TPerfilItem;
begin
  oItem.UserGroup := APermisos;
  oItem.KeyPerfil := FFormulario.Name;
  oItem.SubKey := ASubclave;
  oItem.Value := AValor;
  APerfiles.Add(oItem);
end;

procedure TGestorPerfilesMto.ConstruirPerfilesLayout(
  const APermisos: string;
  APerfiles: TPerfilList);
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
begin
  AnadirPerfil(
    APerfiles, APermisos, 'oRenameComponents',
    Valor('oRenameComponents', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oCreateItems',
    Valor('oCreateItems', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oBusqGlobal',
    Valor('oBusqGlobal', 'Grid'));
  AnadirPerfil(
    APerfiles, APermisos, 'oApplyWidth', 'True');
  AnadirPerfil(
    APerfiles, APermisos, 'oMostrarPerfil',
    Valor('oMostrarPerfil', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oGetSQLFromDB',
    Valor('oGetSQLFromDB', 'False'));
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxCustomGridTableView then
    begin
      oGrid := TcxCustomGridTableView(
        FFormulario.Components[i]);
      AnadirPerfil(
        APerfiles, APermisos,
        oGrid.Name + '__oApplyWidth', 'True');
      AnadirPerfil(
        APerfiles, APermisos,
        oGrid.Name + '__oCreateItems',
        Valor(oGrid.Name + '__oCreateItems', 'False'));
      CollectSettingsColumnProfile(
        oGrid, FFormulario.Name, APermisos,
        FServicioEscritura, APerfiles, FRegistroLog);
    end;
  end;
  AnadirPerfilesSeparadores(APerfiles, APermisos);
  if Assigned(FRecogerParticulares) then
    FRecogerParticulares(APerfiles, APermisos);
end;

// Tamaño del control que redimensiona cada TcxSplitter: alto si el
// separador es horizontal y ancho si es vertical. Un separador cerrado
// no se graba para no restaurar el panel a cero.
function ClaveSeparador(ASeparador: TcxSplitter): string;
begin
  Result := 'oSplitter__' + ASeparador.Name;
end;

function EsSeparadorHorizontal(ASeparador: TcxSplitter): Boolean;
begin
  Result := ASeparador.AlignSplitter in [salTop, salBottom];
end;

procedure TGestorPerfilesMto.AnadirPerfilesSeparadores(
  APerfiles: TPerfilList;
  const APermisos: string);
var
  i: Integer;
  oSeparador: TcxSplitter;
  iTamano: Integer;
begin
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxSplitter then
    begin
      oSeparador := TcxSplitter(FFormulario.Components[i]);
      if Assigned(oSeparador.Control) and
         (oSeparador.State = ssOpened) then
      begin
        if EsSeparadorHorizontal(oSeparador) then
          iTamano := oSeparador.Control.Height
        else
          iTamano := oSeparador.Control.Width;
        AnadirPerfil(
          APerfiles, APermisos, ClaveSeparador(oSeparador),
          IntToStr(iTamano));
      end;
    end;
  end;
end;

procedure TGestorPerfilesMto.RestaurarSeparadores;
var
  i: Integer;
  oSeparador: TcxSplitter;
  iTamano: Integer;
begin
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxSplitter then
    begin
      oSeparador := TcxSplitter(FFormulario.Components[i]);
      iTamano := StrToIntDef(
        Valor(ClaveSeparador(oSeparador), '0'), 0);
      if Assigned(oSeparador.Control) and
         (iTamano >= oSeparador.MinSize) then
      begin
        if EsSeparadorHorizontal(oSeparador) then
          oSeparador.Control.Height := iTamano
        else
          oSeparador.Control.Width := iTamano;
      end;
    end;
  end;
end;

procedure TGestorPerfilesMto.GrabarLayout(
  const ADescripcion: string);
var
  sPermisos: string;
  oPerfiles: TPerfilList;
begin
  if Assigned(FSolicitarDestino) and
     FSolicitarDestino(
       ADescripcion, False, sPermisos) then
  begin
    Screen.Cursor := crHourGlass;
    oPerfiles := TPerfilList.Create;
    try
      if not Assigned(FServicioEscritura) then
        raise Exception.Create(
          SErrorServicioPerfilesUsuarioNoConfigurado);
      if not Assigned(FPersistencia) then
        raise Exception.Create(
          SErrorPersistenciaPerfilesNoConfigurada);
      FPersistencia.GuardarAtomico(
        procedure
        begin
          FServicioEscritura.EliminarPerfil(
            sPermisos, FFormulario.Name);
          ConstruirPerfilesLayout(sPermisos, oPerfiles);
          FServicioEscritura.GrabarPerfiles(oPerfiles);
        end);
    finally
      FreeAndNil(oPerfiles);
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TGestorPerfilesMto.ResetearLayout(
  const ADescripcion: string);
var
  sPermisos: string;
begin
  if Assigned(FSolicitarDestino) and
     FSolicitarDestino(
       ADescripcion, True, sPermisos) then
  begin
    if not Assigned(FServicioEscritura) then
      raise Exception.Create(
        SErrorServicioPerfilesUsuarioNoConfigurado);

    // El layout se guarda bajo la clave del formulario, no por grid. Usar
    // el servicio evita depender del data module (los buscadores externos
    // no tienen uno) y resincroniza la cache despues del borrado.
    FServicioEscritura.EliminarPerfil(
      sPermisos, FFormulario.Name);
    if Assigned(FBorrarGuias) then
      FBorrarGuias;
  end;
end;

procedure TGestorPerfilesMto.AbrirPerfiles(
  AVisible: Boolean;
  const ANombreDataModule: string);
begin
  if AVisible then
  begin
    if not Assigned(FPersistencia) then
      raise Exception.Create(
        SErrorPersistenciaPerfilesNoConfigurada);
    FPersistencia.AbrirPerfiles(
      FFormulario.Name, ANombreDataModule);
  end;
end;

procedure TGestorPerfilesMto.RestaurarFoco(
  AVista: TcxCustomGridTableView);
begin
  if Assigned(FPerfil) and Assigned(AVista) then
    RestaurarFocoGrid(AVista, FPerfil, FRegistroLog);
end;

end.

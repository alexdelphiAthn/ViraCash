{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFamilias                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de familias de artículos.                                     }
{    Queries de fza_familias, subfamilias, atributos por familia y artículos   }
{    relacionados.                                                             }
{******************************************************************************}
unit UniDataFamilias;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn, Windows, Dialogs, Variants,
  inLibTrazabilidadAlta;

type
  TdmFamilias = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosFamilias: TUniQuery;
    dsArticulosFamilias: TDataSource;
    unqrySubFamilias: TUniQuery;
    dsSubFamilias: TDataSource;
    unqryFamiliasAtributos: TUniQuery;
    dsFamiliasAtributos: TDataSource;
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryFamiliasAtributosAfterPost(DataSet: TDataSet);
    procedure unqryFamiliasAtributosAfterInsert(DataSet: TDataSet);
    procedure unqryFamiliasAtributosBeforePost(DataSet: TDataSet);
  private
    function PropiedadExisteEnFamilia(sPropiedad, sFamilia:String):Boolean;
  public
    procedure GetCodigoAutoFamilia;
    //procedure GetCodigoAutoRetencion;
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    // Los .Open de los detalles salen de DataModuleCreate: alli el
    // maestro aun no esta cableado (AsignarMaestroCabecera llega justo
    // despues de crear el DM, y AbrirDetalles despues de abrir TablaG).
    procedure AbrirDetalles; override;
  end;

function LeerTrazabilidadFamilia(AConexion: TUniConnection;
  const ACodigoFamilia: string): TTrazabilidadAlta;

function ResolverCodigoArticuloFamilia(AConn: TUniConnection;
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;

implementation

uses
  inLibMsgArticulos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  ftipoTrazabilidadFamilia = 'TIPO_TRAZABILIDAD_FAM';

function ResolverCodigoArticuloFamilia(AConn: TUniConnection;
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
var
  bOcupado: Boolean;
  iContador: Integer;
  iLongitud: Integer;
  iSaltos: Integer;
  oConsulta: TUniQuery;
  sNumero: string;
begin
  Result := False;
  ACodigoGenerado := '';
  if Trim(ACodigoTecleado) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConn;
      oConsulta.SQL.Text :=
        'SELECT CONTADOR_ART_FAM, ESCONTADOR_ART_FAM, ' +
        '       IFNULL(PAD_ART_FAM, 5) AS PAD_ART_FAM ' +
        '  FROM fza_articulos_familias ' +
        ' WHERE CODIGO_FAM_FAM = :p ' +
        '   AND ESACTIVO_FAM = ''S'' ' +
        ' FOR UPDATE';
      oConsulta.ParamByName('p').AsString := ACodigoTecleado;
      oConsulta.Open;
      if not oConsulta.IsEmpty and
         (oConsulta.FieldByName('ESCONTADOR_ART_FAM').AsString = 'S') then
      begin
        iContador :=
          oConsulta.FieldByName('CONTADOR_ART_FAM').AsInteger + 1;
        iLongitud := oConsulta.FieldByName('PAD_ART_FAM').AsInteger;
        if iLongitud < 1 then
          iLongitud := 5;
        oConsulta.Close;
        // FZ-ISSUE-172: si el contador va por detrás de artículos dados de
        // alta a mano, avanza hasta el primer código libre (y lo guarda).
        oConsulta.SQL.Text :=
          'SELECT CODIGO_ART_ART FROM fza_articulos ' +
          ' WHERE CODIGO_ART_ART = :c LIMIT 1';
        iSaltos := 0;
        repeat
          sNumero := IntToStr(iContador);
          while Length(sNumero) < iLongitud do
            sNumero := '0' + sNumero;
          ACodigoGenerado := ACodigoTecleado + sNumero;
          oConsulta.ParamByName('c').AsString := ACodigoGenerado;
          oConsulta.Open;
          bOcupado := not oConsulta.IsEmpty;
          oConsulta.Close;
          if bOcupado then
            Inc(iContador);
          Inc(iSaltos);
        until (not bOcupado) or (iSaltos >= 1000);
        oConsulta.SQL.Text :=
          'UPDATE fza_articulos_familias SET ' +
          '  CONTADOR_ART_FAM = :c, ' +
          '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
          ' WHERE CODIGO_FAM_FAM = :p';
        oConsulta.ParamByName('c').AsInteger := iContador;
        oConsulta.ParamByName('u').AsString := AUsuario;
        oConsulta.ParamByName('p').AsString := ACodigoTecleado;
        oConsulta.ExecSQL;
        Result := True;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;


function LeerTrazabilidadFamilia(AConexion: TUniConnection;
  const ACodigoFamilia: string): TTrazabilidadAlta;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := TrazabilidadAltaFamilia(TRAZABILIDAD_FAMILIA_NINGUNA);
  if Trim(ACodigoFamilia) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT TIPO_TRAZABILIDAD_FAM FROM fza_articulos_familias ' +
        'WHERE CODIGO_FAM_FAM = :FAMILIA';
      oConsulta.ParamByName('FAMILIA').AsString := ACodigoFamilia;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := TrazabilidadAltaFamilia(
          oConsulta.FieldByName(ftipoTrazabilidadFamilia).AsString);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFamilias.unqryFamiliasAtributosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryFamiliasAtributos.FindField('ESREQUERIDO_FA').AsString := 'N';
end;

procedure TdmFamilias.unqryFamiliasAtributosAfterPost(DataSet: TDataSet);
begin
  inherited;
  unqryFamiliasAtributos.Refresh;
end;

procedure TdmFamilias.unqryFamiliasAtributosBeforePost(DataSet: TDataSet);
var
  CampoPropiedad: TField;
  DebeValidar: Boolean;
begin
  // Evitamos llamar a FindField varias veces guardándolo en una variable
  CampoPropiedad := unqryFamiliasAtributos.FindField('CODIGO_PROP_ARTPROP');
  DebeValidar := False;

  // 1. Si es un registro nuevo, validamos siempre
  if DataSet.State = dsInsert then
    DebeValidar := True
  // 2. Si estamos editando, validamos SOLO si el usuario modificó el campo
  else if DataSet.State = dsEdit then
  begin
    // VarToStr previene errores si el OldValue era Null (requiere 'uses
    // Variants')
    if CampoPropiedad.AsString <> VarToStr(CampoPropiedad.OldValue) then
      DebeValidar := True;
  end;

  // 3. Ejecutamos tu validación si se dio alguna de las dos condiciones
  if DebeValidar then
  begin
    if PropiedadExisteEnFamilia(CampoPropiedad.AsString,
                                unqryTablaG.FindField(
                                  'CODIGO_FAM_FAM').AsString) then
    begin
      NotificarAdvertencia(SAvisoPropiedadFamiliaDuplicada);
      Abort;
    end;
  end;
end;

procedure TdmFamilias.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  if unqrySubFamilias.Active then
    unqrySubFamilias.Refresh;
  unqryTablaG.FindField('CODIGO_FAM_FAM').AsString := '0';
  unqryTablaG.FindField('ORDEN_FAM').AsString := '0';
  unqryTablaG.FindField('ESACTIVO_FAM').AsString := 'S';
  unqryTablaG.FindField('ESDEFAULT_FAM').AsString := 'N';
  unqryTablaG.FieldByName(ftipoTrazabilidadFamilia).AsString :=
    TRAZABILIDAD_FAMILIA_NINGUNA;
  unqryTablaG.FindField('ESCONTADOR_ART_FAM').AsString := 'S';
  // PAD_ART_FAM es NOT NULL en BBDD; sin valor el INSERT manda NULL
  // explicito y falla (el DEFAULT solo aplica si se omite la columna)
  unqryTablaG.FindField('PAD_ART_FAM').AsInteger := 5;
end;

procedure TdmFamilias.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := ConexionPrincipal;
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryArticulosFamilias.Connection := ConexionPrincipal;
  unqrySubFamilias.Connection := ConexionPrincipal;
  unqryFamiliasAtributos.Connection := ConexionPrincipal;
end;

procedure TdmFamilias.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryArticulosFamilias.MasterSource := ADataSource;
  unqryFamiliasAtributos.MasterSource := ADataSource;
end;

procedure TdmFamilias.AbrirDetalles;
begin
  inherited;
  if not unqryArticulosFamilias.Active then
    unqryArticulosFamilias.Open;
  if not unqrySubFamilias.Active then
    unqrySubFamilias.Open;
  if not unqryFamiliasAtributos.Active then
    unqryFamiliasAtributos.Open;
  if not unqryPropiedades.Active then
    unqryPropiedades.Open;
end;

procedure TdmFamilias.GetCodigoAutoFamilia;
begin
  if (unqryTablaG.FindField('CODIGO_FAM_FAM').AsString = '0') then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'FA';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('CODIGO_FAM_FAM').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
  if (unqryTablaG.FindField('ORDEN_FAM').AsString = '0') then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'FO';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('ORDEN_FAM').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
end;

function TdmFamilias.PropiedadExisteEnFamilia(sPropiedad,
                                              sFamilia:String): Boolean;
begin
  var unqryFamProp:TUniQuery := TUniQuery.Create(nil);
  try
    unqryFamProp.Connection := ConexionPrincipal;
    unqryFamProp.sql.Text := 'SELECT CODIGO_PROP_ARTPROP '+
                             '  FROM fza_familias_atributos ' +
                             ' WHERE CODIGO_FAM_FAM = :CODIGO_FAM_FAM ' +
                             '   AND CODIGO_PROP_ARTPROP = ' +
                             ':CODIGO_PROP_ARTPROP';
    unqryFamProp.ParamByName('CODIGO_FAM_FAM').AsString := sFamilia;
    unqryFamProp.ParamByName('CODIGO_PROP_ARTPROP').AsString := sPropiedad;
    unqryFamProp.Open;
    Result := (unqryFamProp.RecordCount > 0);
  finally
    FreeAndNil(unqryFamProp);
  end;
end;

procedure TdmFamilias.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  TrazabilidadAltaFamilia(
    DataSet.FieldByName(ftipoTrazabilidadFamilia).AsString);
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('NOMBRE_FAM_FAM').AsString) = '') then
    Abort;
  if Trim(unqryTablaG.FindField('NOMBRE_FAM_FAM').AsString) = '' then
  begin
    raise ERangeError.CreateFmt(SErrorNombreFamilia,
      [unqryTablaG.FindField('NOMBRE_FAM_FAM').AsString]);
  end
  else if unqryTablaG.FindField('CODIGO_FAM_FAM').AsString =
    unqryTablaG.FindField('CODIGO_PADRE_FAM').AsString then
  begin
    raise ERangeError.CreateFmt(SErrorFamiliaPadreIgualHija,
      [unqryTablaG.FindField('CODIGO_PADRE_FAM').AsString]);
  end
  else if unqryTablaG.FindField('CODIGO_FAM_FAM').AsString = '0' then
    GetCodigoAutoFamilia;
end;
initialization
  RegistrarDataModule(TdmFamilias);
  ForceReferenceToClass(TdmFamilias);
end.

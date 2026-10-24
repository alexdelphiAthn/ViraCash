{******************************************************************************}
{                                                                              }
{  Módulo:       inLibData                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de acceso a datos auxiliares.                                  }
{    Lecturas puntuales sobre una conexión proporcionada por el consumidor.   }
{******************************************************************************}
unit inLibData;

interface
uses
  Uni, System.SysUtils, System.Variants, Data.DB,
  inLibAlmacenesEmpresaPersistenciaIntf;

function AlmacenPerteneceEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa, AAlmacen: string): Boolean;
function PrimerAlmacenEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa: string): string;
function ResolverAlmacenEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa, AAlmacen: string): string;
procedure AjustarEmpresaAlmacenDataSet(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
procedure AjustarEmpresasAlmacenesDocumento(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  ADataSet: TDataSet);
procedure SincronizarInstanteMovimientoDocumento(
  ADataSet: TDataSet;
  const ACampoFecha, ACampoInstante: string);
function ObtenerAlmacenDepositoEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa: string): string;
// Locate generico sobre la clave primaria (uno o varios campos
// separados por coma). Lo usan TfrmMtoGen.LocalizarYEnfocar y las
// busquedas externas entre pantallas. Antes vivia en inLibShowMto.
function BuscarTabla(AQuery: TUniQuery;
                     const AClavePrimaria,
                     AValoresBusqueda: string): Boolean;

implementation

uses
  inLibMsgComun, inLibErroresBBDD;

function BuscarTabla(AQuery: TUniQuery;
                     const AClavePrimaria,
                     AValoresBusqueda: string): Boolean;
var
  ValArr: TArray<string>;
  bIsOnlyOne: Boolean;
  i: Integer;
  miArray: array of Variant;
begin
  bIsOnlyOne := False;
  Result := False;
  ValArr := AValoresBusqueda.Split([',']);
  if Length(ValArr) = 1 then
    bIsOnlyOne := True
  else
  begin
    SetLength(miArray, Length(ValArr));
    for i := 0 to Length(ValArr) - 1 do
      miArray[i] := Trim(ValArr[i]);
  end;
  if AQuery.Active then
  begin
    if bIsOnlyOne then
    begin
      if AQuery.Locate(AClavePrimaria, AValoresBusqueda, []) then
        Result := True;
    end
    else
    begin
      if AQuery.Locate(AClavePrimaria, miArray, []) then
      begin
        Finalize(ValArr);
        Finalize(miArray);
        Result := True;
      end;
    end;
  end;
end;

function AlmacenPerteneceEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa, AAlmacen: string): Boolean;
begin
  Result := False;
  if Assigned(ARepositorio) and
     (Trim(AEmpresa) <> '') and
     (Trim(AAlmacen) <> '') then
  begin
    Result := ARepositorio.AlmacenPerteneceEmpresa(
      Trim(AEmpresa), Trim(AAlmacen));
  end;
end;

function PrimerAlmacenEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa: string): string;
begin
  Result := '';
  if Assigned(ARepositorio) and
     (Trim(AEmpresa) <> '') then
  begin
    Result := ARepositorio.PrimerAlmacenEmpresa(
      Trim(AEmpresa));
  end;
end;

function ResolverAlmacenEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa, AAlmacen: string): string;
begin
  Result := Trim(AAlmacen);
  if Assigned(ARepositorio) and
     (Trim(AEmpresa) <> '') and
     (Trim(AEmpresa) <> '0') and
     not AlmacenPerteneceEmpresa(
       ARepositorio, AEmpresa, AAlmacen) then
  begin
    Result := PrimerAlmacenEmpresa(ARepositorio, AEmpresa);
    // Dato de usuario (empresa mal tecleada o sin almacenes): aviso de
    // validación, no la pantalla de error del programa (FZ-ISSUE-389).
    if Result = '' then
      raise EValidacionBBDD.Create(Format(SErrorEmpresaSinAlmacenActivo,
                                          [Trim(AEmpresa)]));
  end;
end;

procedure AjustarEmpresaAlmacenDataSet(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
var
  CampoAlmacen: TField;
  CampoEmpresa: TField;
  AlmacenCorrecto: string;
begin
  if Assigned(ADataSet) and Assigned(ARepositorio) then
  begin
    CampoEmpresa := ADataSet.FindField(ACampoEmpresa);
    CampoAlmacen := ADataSet.FindField(ACampoAlmacen);
    if (CampoEmpresa <> nil) and (CampoAlmacen <> nil) then
    begin
      AlmacenCorrecto := ResolverAlmacenEmpresa(ARepositorio,
        CampoEmpresa.AsString, CampoAlmacen.AsString);
      if not SameText(Trim(CampoAlmacen.AsString), AlmacenCorrecto) then
        CampoAlmacen.AsString := AlmacenCorrecto;
    end;
  end;
end;

procedure AjustarEmpresasAlmacenesDocumento(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  ADataSet: TDataSet);
begin
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_PED', 'CODIGO_ALM_PED');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_FAC', 'CODIGO_ALM_FAC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_ALBC', 'CODIGO_ALM_ALBC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_PEDC', 'CODIGO_ALM_PEDC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_FACC', 'CODIGO_ALM_FACC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_DEVC', 'CODIGO_ALM_DEVC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_SES', 'CODIGO_ALM_SES');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_SESDOC', 'CODIGO_ALM_SESDOC');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_INV', 'CODIGO_ALM_INV');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_DTR', 'CODIGO_ALM_DTR');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_PDR', 'CODIGO_ALM_PDR');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_DEP', 'CODIGO_ALM_DEP');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_ARQ', 'CODIGO_ALM_ARQ');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_PAGO', 'CODIGO_ALM_PAGO');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_OPCAJA', 'CODIGO_ALM_OPCAJA');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_CONTRA_OPCAJA', 'CODIGO_ALM_CONTRA_OPCAJA');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_EMI_VL', 'CODIGO_ALM_EMI_VL');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_RED_VL', 'CODIGO_ALM_RED_VL');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_TRSOL', 'CODIGO_ALM_ORIGEN_TRSOL');
  AjustarEmpresaAlmacenDataSet(ARepositorio, ADataSet,
    'CODIGO_EMP_CONTRA_TRSOL', 'CODIGO_ALM_DESTINO_TRSOL');
end;

procedure SincronizarInstanteMovimientoDocumento(
  ADataSet: TDataSet;
  const ACampoFecha, ACampoInstante: string);
var
  CampoFecha: TField;
  CampoInstante: TField;
begin
  if Assigned(ADataSet) then
  begin
    CampoFecha := ADataSet.FieldByName(ACampoFecha);
    CampoInstante := ADataSet.FieldByName(ACampoInstante);
    if CampoInstante.IsNull then
    begin
      if CampoFecha.IsNull then
        CampoInstante.AsDateTime := Now
      else
        CampoInstante.AsDateTime := Trunc(CampoFecha.AsDateTime);
    end;
    CampoFecha.AsDateTime := Trunc(CampoInstante.AsDateTime);
  end;
end;

function ObtenerAlmacenDepositoEmpresa(
  const ARepositorio: IRepositorioAlmacenesEmpresa;
  const AEmpresa: string): string;
begin
  Result := '';
  if Assigned(ARepositorio) then
  begin
    Result := ARepositorio.ObtenerAlmacenDepositoEmpresa(
      AEmpresa);
  end;
  if Result = '' then
  begin
    raise Exception.Create(Format(
      SErrorAlmacenDepositosEmpresaNoEncontrado,
      [AEmpresa]));
  end;
end;


end.

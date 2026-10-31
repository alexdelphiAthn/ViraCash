{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDatasets                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de claves, metadata y estado de datasets.                      }
{******************************************************************************}
unit inLibDatasets;

interface

uses
  System.Variants, System.Classes, Data.DB,
  inLibDatasetsPersistenciaIntf;

type
  TEdicionDataSetPendiente = record
    DataSet: TDataSet;
    Estado: TDataSetState;
    Campos: TArray<string>;
    Valores: TArray<Variant>;
    Clave: string;
    ValoresClave: Variant;
  end;
  TEdicionesDataSetsPendientes = TArray<TEdicionDataSetPendiente>;

function CapturarEdicionesDataSets(AModulo: TDataModule):
  TEdicionesDataSetsPendientes;
procedure RestaurarEdicionesDataSets(
  const AEdiciones: TEdicionesDataSetsPendientes);

function KeyValuesToStr(const AValores: Variant): string;
function StrToKeyValues(
  const AValor, ACampos: string): Variant;
function ExtraerTablaDeSQL(const ASql: string): string;
function ObtenerClavePrimariaPorMetadatos(const ATabla: string;
  const ARepositorio: IRepositorioMetadatosDatasets): string;
function ObtenerClavePrimaria(ADataSet: TDataSet): string; overload;
function ObtenerClavePrimaria(ADataSet: TDataSet;
  const ARepositorio: IRepositorioMetadatosDatasets): string; overload;
function AsignarCampoTextoSiEditable(ADataSet: TDataSet;
  const ACampo, AValor: string): Boolean;
// Pone al día en cliente un campo que la consulta calcula (subconsulta
// o agregado unido a la tabla). Viene de solo lectura y sin tabla que
// actualizar: se desbloquea y se excluye del DML antes de escribirlo
// (FZ-ISSUE-447: «Field cannot be modified» al grabar la devolución).
procedure AsignarCampoCalculadoEnCliente(ACampo: TField; AValor: Double);
// Transfiere el editor al registro solo si existe una edicion pendiente.
// Devuelve True cuando el llamador debe guardar esa edicion.
function ActualizarRegistroEnEdicion(ADataSet: TDataSet): Boolean;
procedure GrabarDatasets(AModulo: TDataModule);
procedure CancelarDatasets(AModulo: TDataModule); overload;
procedure CancelarDatasets(AModulo: TDataModule;
  APrincipal: TDataSet); overload;
function DataSetTieneCambiosPendientes(ADataSet: TDataSet): Boolean;
function CheckOpenDatasets(AModulo: TDataModule;
  ASoloModificados: Boolean = False): Boolean;
function ExistePeriodoUnico(
  ADataSet: TDataSet;
  ACampoFechaInicio: TField;
  ACampoFechaFin: TField): Boolean;

implementation

uses
  System.SysUtils, System.DateUtils,
  Uni, Datasnap.Provider, Datasnap.DBClient, MidasLib;

function KeyValuesToStr(const AValores: Variant): string;
var
  i: Integer;
begin
  Result := '';
  if not VarIsNull(AValores) and
     not VarIsEmpty(AValores) then
  begin
    if VarIsArray(AValores) then
    begin
      for i := VarArrayLowBound(AValores, 1) to
        VarArrayHighBound(AValores, 1) do
      begin
        if Result <> '' then
          Result := Result + '|';
        Result := Result + VarToStr(AValores[i]);
      end;
    end
    else
      Result := VarToStr(AValores);
  end;
end;

function StrToKeyValues(
  const AValor, ACampos: string): Variant;
var
  i: Integer;
  oCampos: TStringList;
  oValores: TStringList;
begin
  if Pos(';', ACampos) = 0 then
    Result := AValor
  else
  begin
    oCampos := TStringList.Create;
    oValores := TStringList.Create;
    try
      oCampos.Delimiter := ';';
      oCampos.StrictDelimiter := True;
      oCampos.DelimitedText := ACampos;
      oValores.Delimiter := '|';
      oValores.StrictDelimiter := True;
      oValores.DelimitedText := AValor;
      Result := VarArrayCreate(
        [0, oCampos.Count - 1], varVariant);
      for i := 0 to oCampos.Count - 1 do
      begin
        if i < oValores.Count then
          Result[i] := oValores[i]
        else
          Result[i] := Null;
      end;
    finally
      FreeAndNil(oCampos);
      FreeAndNil(oValores);
    end;
  end;
end;

function ExtraerTablaDeSQL(const ASql: string): string;
var
  bEncontrado: Boolean;
  i: Integer;
  iFin: Integer;
  iInicio: Integer;
  iNivel: Integer;
  sMayusculas: string;

  function HayFromEn(APosicion: Integer): Boolean;
  begin
    Result :=
      (APosicion + 3 <= Length(sMayusculas)) and
      (Copy(sMayusculas, APosicion, 4) = 'FROM');
    if Result and
       (APosicion > 1) and
       not CharInSet(
         sMayusculas[APosicion - 1],
         [' ', #9, #10, #13, '(', ')', ',']) then
      Result := False;
    if Result and
       (APosicion + 4 <= Length(sMayusculas)) and
       not CharInSet(
         sMayusculas[APosicion + 4],
         [' ', #9, #10, #13, '(']) then
      Result := False;
  end;

begin
  Result := '';
  sMayusculas := UpperCase(ASql);
  iNivel := 0;
  i := 1;
  iInicio := 0;
  bEncontrado := False;
  while (i <= Length(sMayusculas)) and
        not bEncontrado do
  begin
    if sMayusculas[i] = '(' then
      Inc(iNivel)
    else if (sMayusculas[i] = ')') and
            (iNivel > 0) then
      Dec(iNivel)
    else if (iNivel = 0) and
            HayFromEn(i) then
    begin
      iInicio := i + 4;
      bEncontrado := True;
    end;
    Inc(i);
  end;
  if bEncontrado then
  begin
    while (iInicio <= Length(sMayusculas)) and
          CharInSet(
            sMayusculas[iInicio],
            [' ', #9, #10, #13]) do
      Inc(iInicio);
    iFin := iInicio;
    while (iFin <= Length(sMayusculas)) and
          not CharInSet(
            sMayusculas[iFin],
            [' ', #13, #10, #9, '(', ',', ';']) do
      Inc(iFin);
    Result := Trim(
      Copy(ASql, iInicio, iFin - iInicio));
    if (Length(Result) >= 2) and
       (Result[1] = '`') then
      Result := Copy(
        Result, 2, Length(Result) - 2);
  end;
end;

function ObtenerClavePrimariaPorMetadatos(const ATabla: string;
  const ARepositorio: IRepositorioMetadatosDatasets): string;
var
  i: Integer;
  oColumnas: TArray<string>;
begin
  Result := '';
  if Assigned(ARepositorio) and
     (Trim(ATabla) <> '') then
  begin
    oColumnas := ARepositorio.ObtenerColumnasClavePrimaria(ATabla);
    for i := 0 to Length(oColumnas) - 1 do
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + oColumnas[i];
    end;
  end;
end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;
begin
  Result := ObtenerClavePrimaria(ADataSet, nil);
end;

function ObtenerClavePrimaria(ADataSet: TDataSet;
  const ARepositorio: IRepositorioMetadatosDatasets): string;
var
  i: Integer;
  sTabla: string;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    if ADataSet is TUniQuery then
      Result := TUniQuery(ADataSet).KeyFields;
    if Result = '' then
    begin
      for i := 0 to ADataSet.FieldCount - 1 do
      begin
        if pfInKey in
           ADataSet.Fields[i].ProviderFlags then
        begin
          if Result <> '' then
            Result := Result + ';';
          Result :=
            Result + ADataSet.Fields[i].FieldName;
        end;
      end;
    end;
    if (Result = '') and
       (ADataSet is TUniQuery) and
       Assigned(ARepositorio) then
    begin
      sTabla := ExtraerTablaDeSQL(
        TUniQuery(ADataSet).SQL.Text);
      if sTabla <> '' then
      begin
        Result := ObtenerClavePrimariaPorMetadatos(
          sTabla, ARepositorio);
      end;
    end;
  end;
end;

function AsignarCampoTextoSiEditable(ADataSet: TDataSet;
  const ACampo, AValor: string): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) and
     (ADataSet.State in [dsEdit, dsInsert]) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) then
    begin
      oCampo.AsString := AValor;
      Result := True;
    end;
  end;
end;

procedure AsignarCampoCalculadoEnCliente(ACampo: TField; AValor: Double);
begin
  if Assigned(ACampo) and Assigned(ACampo.DataSet) then
  begin
    ACampo.ReadOnly := False;
    ACampo.Required := False;
    ACampo.ProviderFlags := [];
    if not (ACampo.DataSet.State in dsEditModes) then
      ACampo.DataSet.Edit;
    ACampo.AsFloat := AValor;
  end;
end;

function CapturarEdicionesDataSets(AModulo: TDataModule):
  TEdicionesDataSetsPendientes;
var
  Datos: TDataSet;
  CamposClave: TStringList;
  Edicion: TEdicionDataSetPendiente;
  i, j, n: Integer;
begin
  Result := nil;
  for i := 0 to AModulo.ComponentCount - 1 do
  begin
    if AModulo.Components[i] is TDataSet then
    begin
      Datos := TDataSet(AModulo.Components[i]);
      if Datos.Active and (Datos.State in dsEditModes) then
      begin
        Edicion := Default(TEdicionDataSetPendiente);
        Edicion.DataSet := Datos;
        Edicion.Estado := Datos.State;
        Edicion.Clave := ObtenerClavePrimaria(Datos);
        SetLength(Edicion.Campos, Datos.FieldCount);
        SetLength(Edicion.Valores, Datos.FieldCount);
        n := 0;
        for j := 0 to Datos.FieldCount - 1 do
        begin
          if (Datos.Fields[j].FieldKind = fkData) and
             not Datos.Fields[j].ReadOnly then
          begin
            Edicion.Campos[n] := Datos.Fields[j].FieldName;
            Edicion.Valores[n] := Datos.Fields[j].Value;
            Inc(n);
          end;
        end;
        SetLength(Edicion.Campos, n);
        SetLength(Edicion.Valores, n);
        if (Edicion.Estado = dsInsert) and (Edicion.Clave <> '') then
          Edicion.ValoresClave := Datos.FieldValues[Edicion.Clave];
        if (Edicion.Estado = dsEdit) and (Edicion.Clave <> '') then
        begin
          CamposClave := TStringList.Create;
          try
            CamposClave.Delimiter := ';';
            CamposClave.StrictDelimiter := True;
            CamposClave.DelimitedText := Edicion.Clave;
            Edicion.ValoresClave := VarArrayCreate(
              [0, CamposClave.Count - 1], varVariant);
            for j := 0 to CamposClave.Count - 1 do
              Edicion.ValoresClave[j] :=
                Datos.FieldByName(CamposClave[j]).OldValue;
            if CamposClave.Count = 1 then
              Edicion.ValoresClave := Edicion.ValoresClave[0];
          finally
            FreeAndNil(CamposClave);
          end;
        end;
        n := Length(Result);
        SetLength(Result, n + 1);
        Result[n] := Edicion;
      end;
    end;
  end;
end;

procedure RestaurarEdicionesDataSets(
  const AEdiciones: TEdicionesDataSetsPendientes);
var
  Datos: TDataSet;
  AntesInsertar, DespuesInsertar, NuevoRegistro: TDataSetNotifyEvent;
  AntesEditar, DespuesEditar, DespuesCancelar: TDataSetNotifyEvent;
  CambioCampo: TFieldNotifyEvent;
  Campo: TField;
  i, j: Integer;
begin
  // Si Post llegó a ejecutarse, el cursor contiene datos que el rollback
  // ya deshizo. Releer antes de restaurar la edición evita actualizar una
  // cabecera nueva que ya no existe en el servidor.
  for i := 0 to High(AEdiciones) do
  begin
    Datos := AEdiciones[i].DataSet;
    // Recuperar un guardado fallido no equivale a Cancelar del usuario:
    // AfterCancel puede descartar los detalles pendientes de la cabecera.
    DespuesCancelar := Datos.AfterCancel;
    Datos.AfterCancel := nil;
    try
      if Datos.Active and (Datos.State in dsEditModes) then
        Datos.Cancel;
    finally
      Datos.AfterCancel := DespuesCancelar;
    end;
    if (Datos is TUniQuery) and not TUniQuery(Datos).CachedUpdates and
       (AEdiciones[i].Clave <> '') then
    begin
      Datos.Close;
      Datos.Open;
    end;
    AntesInsertar := Datos.BeforeInsert;
    DespuesInsertar := Datos.AfterInsert;
    NuevoRegistro := Datos.OnNewRecord;
    AntesEditar := Datos.BeforeEdit;
    DespuesEditar := Datos.AfterEdit;
    Datos.DisableControls;
    try
      Datos.BeforeInsert := nil;
      Datos.AfterInsert := nil;
      Datos.OnNewRecord := nil;
      Datos.BeforeEdit := nil;
      Datos.AfterEdit := nil;
      if AEdiciones[i].Estado = dsInsert then
      begin
        // En memoria, Post conserva la fila insertada en el delta. No
        // crear otra copia al recuperar un CDS ya posteado.
        if ((Datos is TClientDataSet) or
            ((Datos is TUniQuery) and TUniQuery(Datos).CachedUpdates)) and
           (AEdiciones[i].Clave <> '') and
           Datos.Locate(AEdiciones[i].Clave,
             AEdiciones[i].ValoresClave, []) then
          Datos.Edit
        else
          Datos.Insert;
      end
      else
      begin
        if (AEdiciones[i].Clave <> '') and
           not Datos.Locate(AEdiciones[i].Clave,
             AEdiciones[i].ValoresClave, []) then
          raise EDatabaseError.Create(
            'No se encuentra el documento para recuperar su edición.');
        Datos.Edit;
      end;
      for j := 0 to High(AEdiciones[i].Campos) do
      begin
        Campo := Datos.FieldByName(AEdiciones[i].Campos[j]);
        CambioCampo := Campo.OnChange;
        try
          Campo.OnChange := nil;
          Campo.Value := AEdiciones[i].Valores[j];
        finally
          Campo.OnChange := CambioCampo;
        end;
      end;
    finally
      Datos.BeforeInsert := AntesInsertar;
      Datos.AfterInsert := DespuesInsertar;
      Datos.OnNewRecord := NuevoRegistro;
      Datos.BeforeEdit := AntesEditar;
      Datos.AfterEdit := DespuesEditar;
      Datos.EnableControls;
    end;
  end;
end;

function ActualizarRegistroEnEdicion(ADataSet: TDataSet): Boolean;
begin
  Result := ADataSet.State in [dsEdit, dsInsert];
  if Result then
    ADataSet.UpdateRecord;
end;

procedure GrabarDatasets(AModulo: TDataModule);
var
  i: Integer;
  oDataSet: TDataSet;
begin
  if Assigned(AModulo) then
  begin
    for i := 0 to AModulo.ComponentCount - 1 do
    begin
      if AModulo.Components[i] is TDataSet then
      begin
        oDataSet :=
          TDataSet(AModulo.Components[i]);
        if oDataSet.Active and
           (oDataSet.State in
             [dsEdit, dsInsert]) then
          oDataSet.Post;
      end;
    end;
  end;
end;

procedure CancelarDatasets(AModulo: TDataModule);
var
  i: Integer;
  oDataSet: TDataSet;
begin
  if Assigned(AModulo) then
  begin
    for i := 0 to AModulo.ComponentCount - 1 do
    begin
      if AModulo.Components[i] is TDataSet then
      begin
        oDataSet :=
          TDataSet(AModulo.Components[i]);
        if oDataSet.Active and
           (oDataSet.State in
             [dsEdit, dsInsert]) then
          oDataSet.Cancel;
      end;
    end;
  end;
end;

procedure CancelarDatasets(AModulo: TDataModule;
  APrincipal: TDataSet);
var
  i: Integer;
  oDataSet: TDataSet;
begin
  if Assigned(AModulo) then
  begin
    for i := AModulo.ComponentCount - 1 downto 0 do
    begin
      if AModulo.Components[i] is TDataSet then
      begin
        oDataSet := TDataSet(AModulo.Components[i]);
        if (oDataSet <> APrincipal) and
           oDataSet.Active and
           (oDataSet.State in [dsEdit, dsInsert]) then
          oDataSet.Cancel;
      end;
    end;
  end;
  if Assigned(APrincipal) then
  begin
    if APrincipal.Active and
       (APrincipal.State in [dsEdit, dsInsert]) then
      APrincipal.Cancel;
  end;
end;

function DataSetTieneCambiosPendientes(ADataSet: TDataSet): Boolean;
begin
  // Entrar en edición por foco no implica haber cambiado el registro.
  Result := Assigned(ADataSet) and ADataSet.Active and
    ((ADataSet.State = dsInsert) or
     ((ADataSet.State = dsEdit) and ADataSet.Modified));
  if Assigned(ADataSet) and ADataSet.Active and
     (ADataSet is TClientDataSet) then
    Result := Result or (TClientDataSet(ADataSet).ChangeCount > 0);
end;

function CheckOpenDatasets(AModulo: TDataModule;
  ASoloModificados: Boolean): Boolean;
var
  i: Integer;
  oDataSet: TDataSet;
begin
  Result := False;
  i := 0;
  while Assigned(AModulo) and
        (i < AModulo.ComponentCount) and
        not Result do
  begin
    if AModulo.Components[i] is TDataSet then
    begin
      oDataSet :=
        TDataSet(AModulo.Components[i]);
      Result :=
        oDataSet.Active and
        (((not ASoloModificados) and
          (oDataSet.State in [dsEdit, dsInsert])) or
         (ASoloModificados and
          DataSetTieneCambiosPendientes(oDataSet)));
    end;
    Inc(i);
  end;
end;

function ExistePeriodoUnico(
  ADataSet: TDataSet;
  ACampoFechaInicio: TField;
  ACampoFechaFin: TField): Boolean;
// ADataSet trae los demas periodos, sin el que se esta grabando.
// Dos periodos solapan si el otro no termina antes del inicio propio y
// empieza antes del fin propio; un fin vacio es un periodo abierto.
var
  bFechasOrdenadas: Boolean;
  bFechaFinNula: Boolean;
  bFechaInicioNula: Boolean;
  bOtroFinNulo: Boolean;
  dFechaFin: TDateTime;
  dFechaInicio: TDateTime;
  oCliente: TClientDataSet;
  oProveedor: TDataSetProvider;
  sCampoFechaFin: string;
  sCampoFechaInicio: string;
begin
  oCliente := nil;
  sCampoFechaInicio := ACampoFechaInicio.FieldName;
  sCampoFechaFin := ACampoFechaFin.FieldName;
  bFechaFinNula := ACampoFechaFin.IsNull;
  bFechaInicioNula := ACampoFechaInicio.IsNull;
  dFechaInicio := ACampoFechaInicio.AsDateTime;
  dFechaFin := ACampoFechaFin.AsDateTime;
  bFechasOrdenadas := True;
  if not ADataSet.IsEmpty then
  begin
    if bFechaInicioNula or
       (not bFechaFinNula and
        (CompareDate(dFechaInicio, dFechaFin) > 0)) then
      bFechasOrdenadas := False;
    try
      if bFechasOrdenadas then
      begin
        oCliente := TClientDataSet.Create(nil);
        oProveedor :=
          TDataSetProvider.Create(oCliente);
        oProveedor.DataSet := ADataSet;
        oCliente.SetProvider(oProveedor);
        oCliente.Open;
        oCliente.First;
      end;
      while Assigned(oCliente) and
            not oCliente.Eof and
            bFechasOrdenadas do
      begin
        bOtroFinNulo := oCliente.FieldByName(
          sCampoFechaFin).IsNull;
        if (bOtroFinNulo or
            (CompareDate(
               oCliente.FieldByName(sCampoFechaFin).AsDateTime,
               dFechaInicio) > 0)) and
           (bFechaFinNula or
            (CompareDate(
               oCliente.FieldByName(sCampoFechaInicio).AsDateTime,
               dFechaFin) < 0)) then
          bFechasOrdenadas := False;
        oCliente.Next;
      end;
    finally
      if Assigned(oCliente) then
      begin
        oCliente.Close;
        FreeAndNil(oCliente);
      end;
    end;
  end;
  Result := bFechasOrdenadas;
end;

end.

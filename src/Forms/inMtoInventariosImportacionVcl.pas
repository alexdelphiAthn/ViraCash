{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosImportacionVcl                               }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la importacion de recuentos desde Excel o CSV. Solo conoce el    }
{    dialogo, el dataset de lineas y callbacks estrechos de persistencia y     }
{    refresco; no recibe el formulario ni el data module de inventarios.       }
{******************************************************************************}
unit inMtoInventariosImportacionVcl;

interface

uses
  inLibMsgArticulos,
  System.Classes,
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  inLibInventariosAplicacionIntf;

type
  TCargarSkusImportacionInventario = reference to procedure(
    const ALista: TStringList);

  TMensajesImportacionInventario = record
    ErrorInventarioCerrado: string;
    ErrorArchivoNoExiste: string;
    ErrorSinDatos: string;
    TituloIncidencias: string;
    TextoIncidencias: string;
    FormatoIncidenciaCantidad: string;
    FormatoIncidenciaPmpNuevo: string;
    FormatoIncidenciaFechaRecuento: string;
    FormatoIncidenciaCaducidad: string;
    FormatoIncidenciaLinea: string;
    IncidenciaIdentidadIncompleta: string;
    IncidenciaIdentidadContradictoria: string;
    FormatoIncidenciaInventarioDistinto: string;
    TextoSkusNoCargados: string;
    InfoLineasCsv: string;
    InfoResultado: string;
  end;

  TImportadorRecuentoInventarioVcl = class
  private
    FPropietario: TComponent;
    FDialogo: TOpenDialog;
    FLineas: TClientDataSet;
    FAsegurarFechaRecuento: TProc;
    FSolicitarFechaRecuento: TSolicitarFechaRecuentoInventario;
    FCargarSkusNuevos: TCargarSkusImportacionInventario;
    FIniciarImportacion: TProc;
    FConfirmarImportacion: TProc;
    FCancelarImportacion: TProc;
    FRefrescar: TProc;
    FMensajes: TMensajesImportacionInventario;
    function LeerFichero(
      const AArchivo: string;
      out AIdentidad: TIdentidadImportacionInventario;
      out ALineas: TLineasImportacionInventario;
      out AIncidencias: TStringList;
      out AMensaje: string): Boolean;
    function CompletarFechasRecuento(
      var ALineas: TLineasImportacionInventario): Boolean;
    function ValidarIdentidadesLineas(
      const ALineas: TLineasImportacionInventario;
      AIncidencias: TStrings): Boolean;
    function ValidarIdentidadExcel(
      const AIdentidad: TIdentidadImportacionInventario;
      const AInventario: TClaveInventario;
      AIncidencias: TStrings): Boolean;
    procedure ImportarLineas(
      const ALineas: TLineasImportacionInventario;
      const AMensaje: string);
  public
    constructor Create(
      APropietario: TComponent;
      ADialogo: TOpenDialog;
      ALineas: TClientDataSet;
      const AAsegurarFechaRecuento: TProc;
      const ASolicitarFechaRecuento: TSolicitarFechaRecuentoInventario;
      const ACargarSkusNuevos: TCargarSkusImportacionInventario;
      const AIniciarImportacion: TProc;
      const AConfirmarImportacion: TProc;
      const ACancelarImportacion: TProc;
      const ARefrescar: TProc;
      const AMensajes: TMensajesImportacionInventario);
    procedure Ejecutar(
      APuedeEditar: Boolean;
      const AInventario: TClaveInventario);
  end;

implementation

uses
  inLibMensajesVcl,
  dxSpreadSheet,
  inLibHojaCalculoDevEx,
  inLibInventarioExcel,
  inLibInventariosAplicacion,
  inMtoModalScriptLog;


constructor TImportadorRecuentoInventarioVcl.Create(
  APropietario: TComponent;
  ADialogo: TOpenDialog;
  ALineas: TClientDataSet;
  const AAsegurarFechaRecuento: TProc;
  const ASolicitarFechaRecuento: TSolicitarFechaRecuentoInventario;
  const ACargarSkusNuevos: TCargarSkusImportacionInventario;
  const AIniciarImportacion: TProc;
  const AConfirmarImportacion: TProc;
  const ACancelarImportacion: TProc;
  const ARefrescar: TProc;
  const AMensajes: TMensajesImportacionInventario);
begin
  inherited Create;
  if APropietario = nil then
    raise EArgumentNilException.Create('APropietario');
  if ADialogo = nil then
    raise EArgumentNilException.Create('ADialogo');
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  if not Assigned(AAsegurarFechaRecuento) then
    raise EArgumentNilException.Create('AAsegurarFechaRecuento');
  if not Assigned(ASolicitarFechaRecuento) then
    raise EArgumentNilException.Create('ASolicitarFechaRecuento');
  if not Assigned(ACargarSkusNuevos) then
    raise EArgumentNilException.Create('ACargarSkusNuevos');
  if not Assigned(AIniciarImportacion) then
    raise EArgumentNilException.Create('AIniciarImportacion');
  if not Assigned(AConfirmarImportacion) then
    raise EArgumentNilException.Create('AConfirmarImportacion');
  if not Assigned(ACancelarImportacion) then
    raise EArgumentNilException.Create('ACancelarImportacion');
  if not Assigned(ARefrescar) then
    raise EArgumentNilException.Create('ARefrescar');
  FPropietario := APropietario;
  FDialogo := ADialogo;
  FLineas := ALineas;
  FAsegurarFechaRecuento := AAsegurarFechaRecuento;
  FSolicitarFechaRecuento := ASolicitarFechaRecuento;
  FCargarSkusNuevos := ACargarSkusNuevos;
  FIniciarImportacion := AIniciarImportacion;
  FConfirmarImportacion := AConfirmarImportacion;
  FCancelarImportacion := ACancelarImportacion;
  FRefrescar := ARefrescar;
  FMensajes := AMensajes;
end;

function TImportadorRecuentoInventarioVcl.LeerFichero(
  const AArchivo: string;
  out AIdentidad: TIdentidadImportacionInventario;
  out ALineas: TLineasImportacionInventario;
  out AIncidencias: TStringList;
  out AMensaje: string): Boolean;
var
  Lista: TStringList;
  LineasExcel: TLineasImportadas;
  IncidenciasExcel: TIncidenciasImportacionInventario;
  Textos: TArray<string>;
  Hoja: TdxSpreadSheet;
  iLinea: Integer;
begin
  AIdentidad := Default(TIdentidadImportacionInventario);
  SetLength(ALineas, 0);
  AIncidencias := TStringList.Create;
  AMensaje := '';
  Lista := nil;
  SetLength(LineasExcel, 0);
  SetLength(IncidenciasExcel, 0);
  try
    if SameText(ExtractFileExt(AArchivo), '.xlsx') or
       SameText(ExtractFileExt(AArchivo), '.xls') then
    begin
      Hoja := TdxSpreadSheet.Create(nil);
      try
        Hoja.LoadFromFile(AArchivo);
        ImportarInventarioDesdeSheet(CrearLectorDevEx(Hoja),
          AIdentidad,
          LineasExcel,
          Lista,
          IncidenciasExcel,
          AMensaje);
      finally
        FreeAndNil(Hoja);
      end;
      if Length(IncidenciasExcel) > 0 then
      begin
        AIncidencias.Add(FMensajes.TextoIncidencias);
        AIncidencias.Add('');
      end;
      for iLinea := 0 to High(IncidenciasExcel) do
        case IncidenciasExcel[iLinea].Campo of
          ciiCantidad:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaCantidad,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
          ciiPmpNuevo:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaPmpNuevo,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
          ciiFechaRecuento:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaFechaRecuento,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
          ciiCaducidad:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaCaducidad,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
        end;
      SetLength(ALineas, Length(LineasExcel));
      for iLinea := 0 to High(LineasExcel) do
      begin
        ALineas[iLinea].CodigoLinea := LineasExcel[iLinea].Linea;
        ALineas[iLinea].CodigoUnidad := LineasExcel[iLinea].Sku;
        ALineas[iLinea].Cantidad := LineasExcel[iLinea].Cantidad;
        ALineas[iLinea].PrecioMedioNuevo := LineasExcel[iLinea].PmpNuevo;
        ALineas[iLinea].FechaRecuento :=
          LineasExcel[iLinea].FechaRecuento;
        ALineas[iLinea].TienePrecioMedio := LineasExcel[iLinea].TienePmp;
        ALineas[iLinea].TieneFechaRecuento :=
          LineasExcel[iLinea].TieneFechaRecuento;
        ALineas[iLinea].Lote := LineasExcel[iLinea].Lote;
        ALineas[iLinea].FechaCaducidad := LineasExcel[iLinea].FechaCaducidad;
        ALineas[iLinea].TextoOriginal := '';
        if (Lista <> nil) and (iLinea < Lista.Count) then
          ALineas[iLinea].TextoOriginal := Lista[iLinea];
      end;
    end
    else
    begin
      Lista := TStringList.Create;
      Lista.LoadFromFile(AArchivo);
      SetLength(Textos, Lista.Count);
      for iLinea := 0 to Lista.Count - 1 do
        Textos[iLinea] := Lista[iLinea];
      ALineas := LeerLineasImportacionCsvInventario(Textos);
      AMensaje := Format(FMensajes.InfoLineasCsv, [Lista.Count]);
    end;
    Result := (AIncidencias.Count = 0) and
      (Lista <> nil) and (Lista.Count > 0);
  finally
    FreeAndNil(Lista);
  end;
end;

function TImportadorRecuentoInventarioVcl.CompletarFechasRecuento(
  var ALineas: TLineasImportacionInventario): Boolean;
begin
  Result := CompletarFechasRecuentoInventario(
    ALineas,
    FSolicitarFechaRecuento);
end;

function TImportadorRecuentoInventarioVcl.ValidarIdentidadesLineas(
  const ALineas: TLineasImportacionInventario;
  AIncidencias: TStrings): Boolean;
var
  Marcador: TBookmark;
  Coincide: Boolean;
  HayMarcador: Boolean;
  iLinea: Integer;
begin
  if AIncidencias = nil then
    raise EArgumentNilException.Create('AIncidencias');
  Result := True;
  HayMarcador := FLineas.Active and (not FLineas.IsEmpty);
  if HayMarcador then
    Marcador := FLineas.GetBookmark;
  FLineas.DisableControls;
  try
    for iLinea := 0 to High(ALineas) do
      if Trim(ALineas[iLinea].CodigoLinea) <> '' then
      begin
        Coincide := FLineas.Active and FLineas.Locate(
          'LINEA_INVLIN',
          ALineas[iLinea].CodigoLinea,
          [loCaseInsensitive]);
        if Coincide then
          Coincide := SameText(
            FLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString,
            ALineas[iLinea].CodigoUnidad);
        if not Coincide then
        begin
          if Result then
          begin
            AIncidencias.Add(FMensajes.TextoIncidencias);
            AIncidencias.Add('');
          end;
          AIncidencias.Add(Format(
            FMensajes.FormatoIncidenciaLinea,
            [ALineas[iLinea].CodigoLinea,
             ALineas[iLinea].CodigoUnidad]));
          Result := False;
        end;
      end;
  finally
    if HayMarcador then
    begin
      if FLineas.BookmarkValid(Marcador) then
        FLineas.GotoBookmark(Marcador);
      FLineas.FreeBookmark(Marcador);
    end;
    FLineas.EnableControls;
  end;
end;

function TImportadorRecuentoInventarioVcl.ValidarIdentidadExcel(
  const AIdentidad: TIdentidadImportacionInventario;
  const AInventario: TClaveInventario;
  AIncidencias: TStrings): Boolean;
var
  Estado: TEstadoIdentidadImportacionInventario;
begin
  if AIncidencias = nil then
    raise EArgumentNilException.Create('AIncidencias');
  Estado := ValidarIdentidadImportacionInventario(
    AIdentidad,
    AInventario);
  Result := Estado = eiiiCorrecta;
  if not Result then
  begin
    if AIncidencias.Count = 0 then
    begin
      AIncidencias.Add(FMensajes.TextoIncidencias);
      AIncidencias.Add('');
    end;
    case Estado of
      eiiiIncompleta:
        AIncidencias.Add(FMensajes.IncidenciaIdentidadIncompleta);
      eiiiContradictoria:
        AIncidencias.Add(FMensajes.IncidenciaIdentidadContradictoria);
      eiiiInventarioDistinto:
        AIncidencias.Add(Format(
          FMensajes.FormatoIncidenciaInventarioDistinto,
          [AIdentidad.Clave.Empresa,
           AIdentidad.Clave.Almacen,
           AIdentidad.Clave.Serie,
           AIdentidad.Clave.Numero,
           AInventario.Empresa,
           AInventario.Almacen,
           AInventario.Serie,
           AInventario.Numero]));
    end;
  end;
end;

procedure TImportadorRecuentoInventarioVcl.ImportarLineas(
  const ALineas: TLineasImportacionInventario;
  const AMensaje: string);
var
  LineasNuevas: TLineasImportacionInventario;
  ListaNuevos: TStringList;
  ListaNoCargados: TStringList;
  Resumen: TResumenImportacionInventario;
  ResumenNuevas: TResumenImportacionInventario;
begin
  Screen.Cursor := crHourGlass;
  ListaNuevos := TStringList.Create;
  ListaNoCargados := TStringList.Create;
  try
    FIniciarImportacion();
    try
      FLineas.DisableControls;
      try
        Resumen := AplicarImportacionInventario(
          ALineas,
          CrearOperacionesImportacionInventario(
            FLineas,
            ListaNuevos,
            FAsegurarFechaRecuento,
            nil));
      finally
        FLineas.EnableControls;
      end;
      if ListaNuevos.Count > 0 then
      begin
        LineasNuevas := ConsolidarLineasNuevasInventario(
          ALineas,
          ListaNuevos);
        FCargarSkusNuevos(ListaNuevos);
        ResumenNuevas := AplicarImportacionInventario(
          LineasNuevas,
          CrearOperacionesImportacionInventario(
            FLineas,
            ListaNoCargados,
            FAsegurarFechaRecuento,
            nil));
        Resumen.Nuevas := ResumenNuevas.Actualizadas;
      end;
      FConfirmarImportacion();
    except
      FCancelarImportacion();
      raise;
    end;
    FRefrescar;
    if ListaNoCargados.Count > 0 then
    begin
      ListaNoCargados.Insert(0, '');
      ListaNoCargados.Insert(0, FMensajes.TextoSkusNoCargados);
      TfrmMtoModalScriptLog.MostrarTexto(
        FPropietario,
        FMensajes.TituloIncidencias,
        ListaNoCargados);
    end;
    ShowMessage_fza(Format(FMensajes.InfoResultado,
      [AMensaje, Resumen.Actualizadas, Resumen.Nuevas]));
  finally
    Screen.Cursor := crDefault;
    FreeAndNil(ListaNoCargados);
    FreeAndNil(ListaNuevos);
  end;
end;

procedure TImportadorRecuentoInventarioVcl.Ejecutar(
  APuedeEditar: Boolean;
  const AInventario: TClaveInventario);
var
  IdentidadExcel: TIdentidadImportacionInventario;
  Lineas: TLineasImportacionInventario;
  Incidencias: TStringList;
  EsExcel: Boolean;
  Importar: Boolean;
  Mensaje: string;
begin
  Incidencias := nil;
  FDialogo.Filter := SFiltroArchivoImportacionRecuentoInventario;
  FDialogo.DefaultExt := 'xlsx';
  try
    if not APuedeEditar then
      ShowMessage_fza(FMensajes.ErrorInventarioCerrado)
    else if FDialogo.Execute then
    begin
      if not FileExists(FDialogo.FileName) then
        ShowMessage_fza(FMensajes.ErrorArchivoNoExiste)
      else
      begin
        EsExcel := SameText(ExtractFileExt(FDialogo.FileName), '.xlsx') or
          SameText(ExtractFileExt(FDialogo.FileName), '.xls');
        if LeerFichero(
             FDialogo.FileName,
             IdentidadExcel,
             Lineas,
             Incidencias,
             Mensaje) then
        begin
          Importar := True;
          if EsExcel then
            Importar := ValidarIdentidadExcel(
              IdentidadExcel,
              AInventario,
              Incidencias);
          if Importar then
          begin
            ResolverCodigosLineaInventario(Lineas, FLineas);
            Lineas := ConsolidarLineasSinIdentidadInventario(Lineas);
            Importar := ValidarIdentidadesLineas(Lineas, Incidencias);
          end;
          if EsExcel and Importar then
            Importar := CompletarFechasRecuento(Lineas);
          if Importar then
            ImportarLineas(Lineas, Mensaje)
          else if (Incidencias <> nil) and
                  (Incidencias.Count > 0) then
            TfrmMtoModalScriptLog.MostrarTexto(
              FPropietario,
              FMensajes.TituloIncidencias,
              Incidencias);
        end
        else if (Incidencias <> nil) and (Incidencias.Count > 0) then
          TfrmMtoModalScriptLog.MostrarTexto(
            FPropietario, FMensajes.TituloIncidencias, Incidencias)
        else if Mensaje <> '' then
          ShowMessage_fza(Mensaje)
        else
          ShowMessage_fza(FMensajes.ErrorSinDatos);
      end;
    end;
  finally
    FreeAndNil(Incidencias);
  end;
end;

end.

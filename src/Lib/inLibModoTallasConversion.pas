{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasConversion                                     }
{    Tipo:       Librería (casos de uso)                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Conversiones del modo tallas: rederivación de líneas heredadas y          }
{    des-pivote al abandonar el modo. Trabajan sobre puertos; no conocen       }
{    controles, datasets ni UniDAC, y conservan el invariante de unidades.     }
{******************************************************************************}
unit inLibModoTallasConversion;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibModoTallasIntf, inLibModoTallasModelo;

type
  // Lineas heredadas de otros modos / documento reabierto: deriva
  // pivote y atributos, vuelca la CANTIDAD del SKU con talla a su celda
  // y fusiona las duplicadas en una sola linea pivotada.
  TRederivacionTallas = class
  private
    FLineas: ILineasRederivacionTallas;
    FPersistencia: IPersistenciaRederivacionTallas;
    FModelo: TModeloTallas;
    FRegistro: TRegistroTallas;
    FOnAtributosEscritos: TAtributosEscritosTallas;
    FDistribuido: Boolean;
    FAlmacenDefecto: string;
    procedure Registrar(const ATexto: string);
    function AlmacenEfectivo(
      const ALinea: TLineaDocumentoTallas): string;
    procedure FusionarDuplicada(const ALinea: TLineaDocumentoTallas;
      AMaestra, AIdAv: Integer; const AAlmacenCelda, AClave: string);
    procedure PromoverMaestra(const ALinea: TLineaDocumentoTallas;
      const AAtributos: TAtributosLineaTallas; AIdAv: Integer;
      const AAlmacenLinea, AAlmacenCelda: string);
  public
    constructor Create(const ALineas: ILineasRederivacionTallas;
      const APersistencia: IPersistenciaRederivacionTallas;
      AModelo: TModeloTallas; ADistribuido: Boolean;
      const AAlmacenDefecto: string; ARegistro: TRegistroTallas;
      AOnAtributosEscritos: TAtributosEscritosTallas);
    destructor Destroy; override;
    procedure Ejecutar;
  end;
  // Des-pivote al abandonar el modo: cada celda con cantidad pasa a una
  // linea por SKU (cantidad plana) y se limpian las celdas.
  TDesmontajeTallas = class
  private
    FLineas: ILineasDesmontajeTallas;
    FPersistencia: IPersistenciaDesmontajeTallas;
    FModelo: TModeloTallas;
    FRegistro: TRegistroTallas;
    FCeldas: TArray<TCeldaTallas>;
    FOrdenTallaPorArticulo: TDictionary<string, Integer>;
    FNombreTallaPorArticulo: TDictionary<string, string>;
    FMaximaLinea: Integer;
    function UnidadesDocumento: Double;
    procedure ResolverTallaArticulo(var ADatos: TDatosLineaExpansion);
    procedure AplicarCelda(const ACelda: TCeldaTallas;
      var ADatos: TDatosLineaExpansion);
    procedure ExpandirCeldas;
    function Expandir: Boolean;
  public
    constructor Create(const ALineas: ILineasDesmontajeTallas;
      const APersistencia: IPersistenciaDesmontajeTallas;
      AModelo: TModeloTallas; ARegistro: TRegistroTallas);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

implementation

constructor TRederivacionTallas.Create(
  const ALineas: ILineasRederivacionTallas;
  const APersistencia: IPersistenciaRederivacionTallas;
  AModelo: TModeloTallas; ADistribuido: Boolean;
  const AAlmacenDefecto: string; ARegistro: TRegistroTallas;
  AOnAtributosEscritos: TAtributosEscritosTallas);
begin
  inherited Create;
  FLineas := ALineas;
  FPersistencia := APersistencia;
  FModelo := AModelo;
  FDistribuido := ADistribuido;
  FAlmacenDefecto := AAlmacenDefecto;
  FRegistro := ARegistro;
  FOnAtributosEscritos := AOnAtributosEscritos;
end;

destructor TRederivacionTallas.Destroy;
begin
  FPersistencia := nil;
  FLineas := nil;
  inherited;
end;

procedure TRederivacionTallas.Registrar(const ATexto: string);
begin
  if Assigned(FRegistro) then
    FRegistro(ATexto);
end;

function TRederivacionTallas.AlmacenEfectivo(
  const ALinea: TLineaDocumentoTallas): string;
begin
  // Almacen EFECTIVO de la linea (fallback de cabecera, como
  // albaranes): las lineas sin almacen asumen el del documento y asi
  // fusionan con las que ya lo llevan puesto.
  Result := '';
  if ALinea.TieneAlmacen then
  begin
    Result := Trim(ALinea.Almacen);
    if Result = '' then
      Result := Trim(FAlmacenDefecto);
  end;
end;

procedure TRederivacionTallas.FusionarDuplicada(
  const ALinea: TLineaDocumentoTallas; AMaestra, AIdAv: Integer;
  const AAlmacenCelda, AClave: string);
begin
  // Si la duplicada YA tiene celdas (era otra maestra) se mueven SUS
  // celdas: su CANTIDAD es el total que mantiene el refresco de
  // totales y sumarla duplicaria.
  if FPersistencia.LineaTieneCeldas(ALinea.Numero) then
    FPersistencia.MoverCeldasALinea(ALinea.Numero, AMaestra)
  else if (AIdAv > 0) and (ALinea.Cantidad > 0) then
    FPersistencia.SumarEnCelda(AMaestra, AIdAv, ALinea.Cantidad,
                               AAlmacenCelda);
  Registrar(Format('ModoTallas.Rederivar: BORRA linea=%d (dup de %d) ' +
    'art=%s clave=%s',
    [ALinea.Numero, AMaestra, ALinea.Articulo, AClave]));
  FLineas.BorrarLineaActual;
end;

procedure TRederivacionTallas.PromoverMaestra(
  const ALinea: TLineaDocumentoTallas;
  const AAtributos: TAtributosLineaTallas; AIdAv: Integer;
  const AAlmacenLinea, AAlmacenCelda: string);
var
  Escritura: TEscrituraLineaTallas;
  bYaConvertida: Boolean;
begin
  Escritura := Default(TEscrituraLineaTallas);
  // En distribuido la linea es multi-almacen: queda el del documento.
  if FDistribuido then
    Escritura.Almacen := Trim(FAlmacenDefecto)
  else
    Escritura.Almacen := AAlmacenLinea;
  Escritura.Valores := AAtributos.Valores;
  Escritura.Nombres := AAtributos.Nombres;
  Escritura.ConjuntoTalla := AAtributos.ConjuntoTalla;
  Escritura.OrdenTalla := AAtributos.OrdenTalla;
  // Maestra YA convertida (tiene celdas): su CANTIDAD es el total que
  // mantiene el refresco de totales; volver a volcarla DUPLICABA las
  // celdas en cada reentrada al modo.
  bYaConvertida := FPersistencia.LineaTieneCeldas(ALinea.Numero);
  Escritura.PonerCantidadCero := (not bYaConvertida) and (AIdAv > 0) and
    (ALinea.Cantidad > 0) and ALinea.TieneCantidad;
  FLineas.EscribirLineaActual(Escritura);
  if Assigned(FOnAtributosEscritos) then
    FOnAtributosEscritos(AAtributos.Valores, AAtributos.Nombres);
  if (not bYaConvertida) and (AIdAv > 0) and (ALinea.Cantidad > 0) then
    FPersistencia.SumarEnCelda(ALinea.Numero, AIdAv, ALinea.Cantidad,
                               AAlmacenCelda);
end;

procedure TRederivacionTallas.Ejecutar;
var
  Maestras: TDictionary<string, Integer>;
  Linea: TLineaDocumentoTallas;
  Atributos: TAtributosLineaTallas;
  Partes: TArray<string>;
  sTalla, sClave, sAlmLinea, sAlmCelda: string;
  iPosicion, idAv, iMaestra: Integer;
  bBorrada: Boolean;
begin
  if FLineas.HayLineas then
  begin
    Maestras := TDictionary<string, Integer>.Create;
    FLineas.SuspenderRefrescoVisual;
    try
      // Recorrido por posicion, NO con while-not-Eof: al borrar la
      // ULTIMA linea el cursor cae en la anterior (no en Eof) y el
      // bucle reprocesaria lineas ya vistas, que estarian en el
      // diccionario como maestras de si mismas y se borrarian como
      // "duplicadas" (borrado total del documento).
      iPosicion := 1;
      while iPosicion <= FLineas.ContarLineas do
      begin
        FLineas.PosicionarEn(iPosicion);
        bBorrada := False;
        Linea := FLineas.LeerLineaActual;
        if Linea.Articulo <> '' then
        begin
          Partes := TModeloTallas.PartesDeSku(Linea.Articulo, Linea.Sku);
          // Silencioso: sin paleta durante la conversion masiva.
          Atributos := FModelo.CalcularAtributosLinea(Linea.Articulo,
                                                      Partes, True);
          sTalla := TModeloTallas.ValorTallaDePartes(Partes,
                                                     Atributos.OrdenTalla);
          idAv := FModelo.IdAvDeTalla(Linea.Articulo,
                                      Atributos.OrdenTalla, sTalla);
          sAlmLinea := AlmacenEfectivo(Linea);
          sClave := TModeloTallas.ClaveConsolidacion(FDistribuido,
            Linea.Articulo, sAlmLinea, Atributos.Valores,
            Linea.TienePrecio, Linea.Precio);
          // Destino de las cantidades heredadas: en distribuido, el
          // almacen efectivo de la linea; si no, celda sin almacen.
          if FDistribuido then
            sAlmCelda := sAlmLinea
          else
            sAlmCelda := '';
          if Maestras.TryGetValue(sClave, iMaestra) then
          begin
            FusionarDuplicada(Linea, iMaestra, idAv, sAlmCelda, sClave);
            bBorrada := True;
          end
          else
          begin
            Maestras.Add(sClave, Linea.Numero);
            Registrar(Format('ModoTallas.Rederivar: MASTER linea=%d ' +
              'art=%s clave=%s',
              [Linea.Numero, Linea.Articulo, sClave]));
            PromoverMaestra(Linea, Atributos, idAv, sAlmLinea,
                            sAlmCelda);
          end;
        end;
        // Tras un borrado NO se avanza: esa posicion ya es otra linea.
        if not bBorrada then
          Inc(iPosicion);
      end;
      FLineas.IrAlPrimero;
    finally
      FreeAndNil(Maestras);
      FLineas.ReanudarRefrescoVisual;
    end;
  end;
end;

constructor TDesmontajeTallas.Create(
  const ALineas: ILineasDesmontajeTallas;
  const APersistencia: IPersistenciaDesmontajeTallas;
  AModelo: TModeloTallas; ARegistro: TRegistroTallas);
begin
  inherited Create;
  FLineas := ALineas;
  FPersistencia := APersistencia;
  FModelo := AModelo;
  FRegistro := ARegistro;
  FOrdenTallaPorArticulo := TDictionary<string, Integer>.Create;
  FNombreTallaPorArticulo := TDictionary<string, string>.Create;
end;

destructor TDesmontajeTallas.Destroy;
begin
  FreeAndNil(FNombreTallaPorArticulo);
  FreeAndNil(FOrdenTallaPorArticulo);
  FPersistencia := nil;
  FLineas := nil;
  inherited;
end;

function TDesmontajeTallas.UnidadesDocumento: Double;
begin
  Result := TModeloTallas.UnidadesDocumento(
    FPersistencia.ConsultarTotalesPorLinea,
    FLineas.CantidadesPorLinea);
end;

procedure TDesmontajeTallas.ResolverTallaArticulo(
  var ADatos: TDatosLineaExpansion);
var
  iOrden: Integer;
  sNombre: string;
begin
  if FOrdenTallaPorArticulo.TryGetValue(ADatos.Articulo, iOrden) then
  begin
    ADatos.OrdenTalla := iOrden;
    FNombreTallaPorArticulo.TryGetValue(ADatos.Articulo,
                                        ADatos.NombreTalla);
  end
  else
  begin
    FModelo.OrdenYNombreTalla(ADatos.Articulo, iOrden, sNombre);
    ADatos.OrdenTalla := iOrden;
    ADatos.NombreTalla := sNombre;
    FOrdenTallaPorArticulo.Add(ADatos.Articulo, iOrden);
    FNombreTallaPorArticulo.Add(ADatos.Articulo, sNombre);
  end;
end;

procedure TDesmontajeTallas.AplicarCelda(const ACelda: TCeldaTallas;
  var ADatos: TDatosLineaExpansion);
var
  sSku, sAlmacen: string;
begin
  if ADatos.Encontrada then
  begin
    sSku := TModeloTallas.ComponerSkuLinea(ADatos.Articulo,
      ADatos.Valores, ADatos.OrdenTalla, ACelda.ValorTalla);
    if ACelda.Almacen <> '' then
      sAlmacen := ACelda.Almacen
    else
      sAlmacen := ADatos.Almacen;
    if ADatos.Primera then
    begin
      FLineas.ActualizarLineaExpandida(ACelda, ADatos, sSku, sAlmacen);
      ADatos.Primera := False;
    end
    else
    begin
      Inc(FMaximaLinea);
      FLineas.CrearLineaExpandida(FMaximaLinea, ACelda, ADatos, sSku,
                                  sAlmacen);
    end;
  end;
end;

procedure TDesmontajeTallas.ExpandirCeldas;
var
  Datos: TDatosLineaExpansion;
  i: Integer;
begin
  FMaximaLinea := FLineas.MaximaLinea;
  Datos := Default(TDatosLineaExpansion);
  for i := 0 to High(FCeldas) do
  begin
    if FCeldas[i].Linea <> Datos.Numero then
    begin
      Datos := FLineas.LeerDatosLinea(FCeldas[i].Linea);
      if Datos.Encontrada then
        ResolverTallaArticulo(Datos);
    end;
    AplicarCelda(FCeldas[i], Datos);
  end;
end;

function TDesmontajeTallas.Expandir: Boolean;
begin
  FCeldas := FPersistencia.ConsultarCeldasDocumento;
  Result := Length(FCeldas) > 0;
  if Result then
  begin
    ExpandirCeldas;
    FPersistencia.BorrarCeldasDocumento;
    if Assigned(FRegistro) then
      FRegistro(Format(
        'ModoTallas.Desmontar: %d celdas expandidas a lineas',
        [Length(FCeldas)]));
  end;
end;

procedure TDesmontajeTallas.Ejecutar;
var
  rUnidadesAntes: Double;
  bTransaccionPropia, bExpandio: Boolean;
begin
  FLineas.IniciarProceso;
  try
    bTransaccionPropia := not FPersistencia.EnTransaccion;
    if bTransaccionPropia then
      FPersistencia.IniciarTransaccion;
    try
      rUnidadesAntes := UnidadesDocumento;
      bExpandio := Expandir;
      // El invariante se mide con el proceso ya cerrado: la lectura de
      // cantidades vuelve a ver el documento como lo vera el usuario.
      FLineas.TerminarProceso;
      if bExpandio then
        TModeloTallas.ComprobarInvarianteUnidades('Desmontar',
          rUnidadesAntes, UnidadesDocumento, FRegistro);
      if bTransaccionPropia then
        FPersistencia.ConfirmarTransaccion;
    except
      if bTransaccionPropia then
        FPersistencia.RevertirTransaccion;
      raise;
    end;
  finally
    FLineas.TerminarProceso;
  end;
  FLineas.NotificarPostsSilenciados;
end;

end.

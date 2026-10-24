{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAplicacionArticuloCompra                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caso de uso para aplicar un artículo a una línea de compra.               }
{******************************************************************************}
unit inLibAplicacionArticuloCompra;

interface

uses
  inLibAplicacionArticuloCompraIntf;

function CrearAplicacionArticuloCompra(
  const ARepositorio: IRepositorioLecturasArticuloCompra;
  const APuerto: IPuertoLineaArticuloCompra): IAplicacionArticuloCompra;

implementation

uses
  System.SysUtils, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf, inLibMsgArticulos;

type
  TAplicacionArticuloCompra = class(
    TInterfacedObject,
    IAplicacionArticuloCompra)
  private
    FRepositorio: IRepositorioLecturasArticuloCompra;
    FPuerto: IPuertoLineaArticuloCompra;
    FAplicando: Boolean;
    FUltimaClaveAvisoProveedor: string;
    function AvisoProveedorDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
    function CrearLinea(
      const AEntrada: TEntradaAplicacionArticuloCompra;
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      const ADatos: TArticuloDatos;
      AIdConjuntoPivote: Integer;
      const AModeloProveedor: string;
      const AActual: TLineaActualArticuloCompra): TLineaArticuloCompra;
    function ResolverAccionPivote(
      const AEntrada: TEntradaAplicacionArticuloCompra;
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      AIdConjuntoPivote: Integer): TAccionPivoteArticuloCompra;
  public
    constructor Create(
      const ARepositorio: IRepositorioLecturasArticuloCompra;
      const APuerto: IPuertoLineaArticuloCompra);
    function Ejecutar(
      const AEntrada: TEntradaAplicacionArticuloCompra;
      ATipoDocumento: TTipoDocumentoArticuloCompra):
      TResultadoAplicacionArticuloCompra;
  end;

function CrearAplicacionArticuloCompra(
  const ARepositorio: IRepositorioLecturasArticuloCompra;
  const APuerto: IPuertoLineaArticuloCompra): IAplicacionArticuloCompra;
begin
  Result := TAplicacionArticuloCompra.Create(ARepositorio, APuerto);
end;

constructor TAplicacionArticuloCompra.Create(
  const ARepositorio: IRepositorioLecturasArticuloCompra;
  const APuerto: IPuertoLineaArticuloCompra);
begin
  if ARepositorio = nil then
    raise EArgumentNilException.Create('ARepositorio');
  if APuerto = nil then
    raise EArgumentNilException.Create('APuerto');
  inherited Create;
  FRepositorio := ARepositorio;
  FPuerto := APuerto;
end;

function TAplicacionArticuloCompra.AvisoProveedorDistinto(
  const ACodigoArticulo, ACodigoProveedor: string): string;
var
  oProveedorDocumento: TArticuloCoste;
  oProveedorOrigen: TArticuloCoste;
  sClave: string;
begin
  Result := '';
  if (Trim(ACodigoArticulo) <> '') and
     (Trim(ACodigoProveedor) <> '') and
     (Trim(ACodigoProveedor) <> '0') then
  begin
    oProveedorDocumento := FRepositorio.ResolverUltimoCoste(
      ACodigoArticulo, ACodigoProveedor);
    if not oProveedorDocumento.Encontrado then
    begin
      oProveedorOrigen := FRepositorio.ResolverUltimoCoste(
        ACodigoArticulo, '');
      if oProveedorOrigen.Encontrado and
         (Trim(oProveedorOrigen.CodigoProveedor) <> '') and
         not SameText(oProveedorOrigen.CodigoProveedor,
           ACodigoProveedor) then
      begin
        sClave := UpperCase(Trim(ACodigoArticulo)) + '|' +
          UpperCase(Trim(ACodigoProveedor));
        if sClave <> FUltimaClaveAvisoProveedor then
        begin
          FUltimaClaveAvisoProveedor := sClave;
          Result := SAvisoArticuloCreadoOtroProveedor;
        end;
      end;
    end;
  end;
end;

function TAplicacionArticuloCompra.CrearLinea(
  const AEntrada: TEntradaAplicacionArticuloCompra;
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  const ADatos: TArticuloDatos;
  AIdConjuntoPivote: Integer;
  const AModeloProveedor: string;
  const AActual: TLineaActualArticuloCompra): TLineaArticuloCompra;
begin
  Result := Default(TLineaArticuloCompra);
  Result.CodigoArticulo := ADatos.CodigoArticulo;
  Result.CodigoSku := ADatos.CodigoSku;
  Result.ReferenciaProveedor := AModeloProveedor;
  Result.CodigoFamilia := ADatos.CodigoFamilia;
  Result.NombreFamilia := ADatos.DescripcionFamilia;
  Result.DescripcionArticulo := ADatos.DescripcionArticulo;
  Result.TipoCantidad := ADatos.TipoCantidad;
  Result.TipoIva := ADatos.TipoIVA;
  Result.CodigoAlmacen := AEntrada.CodigoAlmacen;
  Result.AsignarAlmacen := AEntrada.CodigoAlmacen <> '';
  Result.IdConjuntoPivote := AIdConjuntoPivote;
  Result.Cantidad := AActual.Cantidad;
  if ADatos.RequiereSku and (ADatos.CodigoSku = '') then
  begin
    Result.Cantidad := 0;
    Result.TotalUnidades := 0;
    Result.AsignarCantidad := True;
    Result.AsignarTotalUnidades := True;
  end
  else if Result.Cantidad = 0 then
  begin
    Result.Cantidad := 1;
    Result.TotalUnidades := 1;
    Result.AsignarCantidad := True;
    Result.AsignarTotalUnidades := True;
  end
  else if AConfiguracion.ActualizarTotalUnidadesSiempre then
  begin
    Result.TotalUnidades := Result.Cantidad;
    Result.AsignarTotalUnidades := True;
  end;
  Result.PrecioCompra := ADatos.UltimoCoste.PrecioUltCompra;
  // Al elegir la talla se vuelve a aplicar el mismo artículo: el precio
  // que ya se había tecleado en la línea no se pisa con el último coste
  // (FZ-ISSUE-419: volvía a 0,00 sin aviso). Si se sustituye un SKU
  // concreto por otro, se propone el coste del nuevo (FZ-ISSUE-466).
  if (AActual.PrecioCompra <> 0) and
     SameText(Trim(AActual.CodigoArticulo), Trim(ADatos.CodigoArticulo)) and
     ((Trim(AActual.CodigoSku) = '') or
      SameText(Trim(AActual.CodigoSku), Trim(ADatos.CodigoSku))) then
    Result.PrecioCompra := AActual.PrecioCompra;
  Result.Total := Result.Cantidad * Result.PrecioCompra;
end;

function TAplicacionArticuloCompra.ResolverAccionPivote(
  const AEntrada: TEntradaAplicacionArticuloCompra;
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  AIdConjuntoPivote: Integer): TAccionPivoteArticuloCompra;
begin
  Result := apacNinguna;
  if AConfiguracion.GestionarPivoteAntiguo then
  begin
    if (AIdConjuntoPivote <= 0) and AEntrada.PivoteActivo then
      Result := apacDesactivar
    else if (AIdConjuntoPivote > 0) and
            (AEntrada.PreferenciaPivoteHorizontal <> 'N') then
    begin
      if AEntrada.PivoteActivo then
        Result := apacRecargar
      else
        Result := apacActivarYRecargar;
    end;
  end;
end;

function TAplicacionArticuloCompra.Ejecutar(
  const AEntrada: TEntradaAplicacionArticuloCompra;
  ATipoDocumento: TTipoDocumentoArticuloCompra):
  TResultadoAplicacionArticuloCompra;
var
  oConfiguracion: TConfiguracionCamposArticuloCompra;
  oDatos: TArticuloDatos;
  oLinea: TLineaArticuloCompra;
  oResolucion: TArtResolucionEntrada;
  sEntrada: string;
  sModeloProveedor: string;
  iIdConjuntoPivote: Integer;
  oActual: TLineaActualArticuloCompra;
begin
  Result := Default(TResultadoAplicacionArticuloCompra);
  sEntrada := Trim(AEntrada.CodigoIntroducido);
  if (sEntrada <> '') and (not FAplicando) then
  begin
    if (Trim(AEntrada.CodigoProveedor) = '') or
       (Trim(AEntrada.CodigoProveedor) = '0') then
      Result.Mensaje := SErrorProveedorNoSeleccionadoBuscarArticulos
    else
    begin
      FAplicando := True;
      try
        oConfiguracion := ConfiguracionCamposArticuloCompra(ATipoDocumento);
        if FPuerto.PrepararLinea(oConfiguracion, oActual) then
        begin
          oResolucion := FRepositorio.ResolverEntrada(sEntrada);
          if oResolucion.Encontrado then
          begin
            oDatos := FRepositorio.ResolverDatos(
              oResolucion.CodigoArticulo,
              oResolucion.CodigoSku,
              AEntrada.Fecha,
              AEntrada.CodigoAlmacen,
              AEntrada.CodigoProveedor);
            if oDatos.Encontrado then
            begin
              if oDatos.RequiereSku then
                oDatos.UltimoCoste := FRepositorio.ResolverUltimoCoste(
                  oDatos.CodigoArticulo,
                  AEntrada.CodigoProveedor);
              iIdConjuntoPivote := FRepositorio.BuscarConjuntoPivote(
                oDatos.CodigoArticulo);
              sModeloProveedor := FRepositorio.BuscarModeloProveedor(
                oDatos.CodigoArticulo,
                AEntrada.CodigoProveedor);
              if sModeloProveedor = '' then
                sModeloProveedor := oDatos.UltimoCoste.RefProveedor;
              oLinea := CrearLinea(
                AEntrada,
                oConfiguracion,
                oDatos,
                iIdConjuntoPivote,
                sModeloProveedor,
                oActual);
              FPuerto.AplicarLinea(oConfiguracion, oLinea);
              Result.Aplicado := True;
              Result.RequiereSku :=
                oDatos.RequiereSku and (oDatos.CodigoSku = '');
              Result.Mensaje := AvisoProveedorDistinto(
                oDatos.CodigoArticulo,
                AEntrada.CodigoProveedor);
              Result.IdConjuntoPivote := iIdConjuntoPivote;
              Result.AccionPivote := ResolverAccionPivote(
                AEntrada,
                oConfiguracion,
                iIdConjuntoPivote);
            end
            else
              Result.Mensaje := oDatos.Mensaje;
          end
          else
            Result.Mensaje := oResolucion.Mensaje;
        end;
      finally
        FAplicando := False;
      end;
    end;
  end;
end;

end.

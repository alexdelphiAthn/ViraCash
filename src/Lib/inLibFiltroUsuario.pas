{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFiltroUsuario                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Restricción de consulta por empresa/almacén/caja del usuario.             }
{    Lee el parámetro appRestringirEmpAlmCaja y expone helpers para que        }
{    cada pantalla filtre su precarga o la selección de caja.                  }
{******************************************************************************}
unit inLibFiltroUsuario;

interface

uses
  inLibContextoSesionIntf, inLibParametrosIntf;

// Devuelve True si el usuario actual tiene activo el parámetro
// appRestringirEmpAlmCaja. Los administradores quedan
// siempre exentos, igual que en inLibPermisos.
function RestriccionEmpAlmCajaActiva(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): Boolean;
// Valores a los que queda restringido el usuario. Devuelven '' cuando la
// restricción no está activa o cuando el usuario no tiene ese defecto
// asignado en fza_usuarios (esa dimensión no se filtra).
function EmpresaRestringida(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
function AlmacenRestringido(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
function CajaRestringida(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
// Construye el fragmento SQL ' AND (<col> = ''valor'' OR <col> IS NULL)'
// para inyectar en el WHERE de la precarga de cada pantalla. Se pasa el
// nombre de columna de cada dimensión ('' para omitirla, p. ej. pantallas
// sin caja). El OR IS NULL evita excluir documentos sin esa dimensión
// (p. ej. facturas de mayor con CODIGO_CAJA_FAC NULL).
function SqlFiltroEmpAlmCaja(
                             const AContextoSesion:
                             IContextoSesionAplicacion;
                             const AParametrosApp:
                             IParametrosAplicacion;
                             const AColEmpresa,
                             AColAlmacen,
                             AColCaja: string): string;
// Deriva las columnas estándar de un documento a partir de su sufijo.
// Las facturas de venta pueden incluir además la dimensión de caja.
function SqlFiltroDocumento(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APrefijoCampos: string;
  AIncluirCaja: Boolean = False): string;
// Inyecta AFiltro (fragmentos ' AND col = valor') en el WHERE de nivel
// superior de ASql. Si la SQL no tiene WHERE de nivel superior añade
// ' WHERE 1 = 1' + AFiltro. El punto de inserción es justo antes del
// primer GROUP BY / HAVING / ORDER BY / LIMIT de nivel superior (fuera
// de paréntesis), conservando así el orden de la precarga.
function InyectarFiltroSql(const ASql, AFiltro: string): string;

implementation

uses
  System.SysUtils;

function RestriccionEmpAlmCajaActiva(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  // Los administradores nunca quedan restringidos
  if AContextoSesion.Identidad.EsAdministrador then
    Result := False
  else
    Result := Assigned(AParametrosApp) and
              AParametrosApp.GetBool('appRestringirEmpAlmCaja', False);
end;

function EmpresaRestringida(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if RestriccionEmpAlmCajaActiva(AContextoSesion, AParametrosApp) then
    Result := AContextoSesion.Ubicacion.Empresa
  else
    Result := '';
end;

function AlmacenRestringido(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if RestriccionEmpAlmCajaActiva(AContextoSesion, AParametrosApp) then
    Result := AContextoSesion.Ubicacion.Almacen
  else
    Result := '';
end;

function CajaRestringida(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if RestriccionEmpAlmCajaActiva(AContextoSesion, AParametrosApp) then
    Result := AContextoSesion.Ubicacion.Caja
  else
    Result := '';
end;

function SqlFiltroEmpAlmCaja(
                             const AContextoSesion:
                             IContextoSesionAplicacion;
                             const AParametrosApp:
                             IParametrosAplicacion;
                             const AColEmpresa,
                             AColAlmacen,
                             AColCaja: string): string;
var
  Ubicacion: TUbicacionSesion;

  // Fragmento de una dimensión tolerante a NULL: un documento sin esa
  // dimensión (columna NULL) no se excluye, igual que un defecto vacío
  // del usuario no filtra esa dimensión.
  function Fragmento(const ACol, AValor: string): string;
  begin
    Result := ' AND (' + ACol + ' = ' + QuotedStr(AValor) +
              ' OR ' + ACol + ' IS NULL)';
  end;

begin
  Result := '';
  if not RestriccionEmpAlmCajaActiva(
    AContextoSesion,
    AParametrosApp) then
  begin
    // Sin restricción: fragmento vacío, la precarga no cambia
  end
  else
  begin
    Ubicacion := AContextoSesion.Ubicacion;
    if (AColEmpresa <> '') and (Ubicacion.Empresa <> '') then
      Result := Result + Fragmento(AColEmpresa, Ubicacion.Empresa);
    if (AColAlmacen <> '') and (Ubicacion.Almacen <> '') then
      Result := Result + Fragmento(AColAlmacen, Ubicacion.Almacen);
    if (AColCaja <> '') and (Ubicacion.Caja <> '') then
      Result := Result + Fragmento(AColCaja, Ubicacion.Caja);
  end;
end;

function SqlFiltroDocumento(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APrefijoCampos: string;
  AIncluirCaja: Boolean): string;
var
  sColumnaCaja: string;
begin
  sColumnaCaja := '';
  if AIncluirCaja then
    sColumnaCaja := 'CODIGO_CAJA_' + APrefijoCampos;
  Result := SqlFiltroEmpAlmCaja(
    AContextoSesion, AParametrosApp,
    'CODIGO_EMP_' + APrefijoCampos,
    'CODIGO_ALM_' + APrefijoCampos,
    sColumnaCaja);
end;

function InyectarFiltroSql(const ASql, AFiltro: string): string;
var
  sSql, sMayus: string;
  iNivel, i, iCorte: Integer;
  bTieneWhere: Boolean;
  // Comprueba si en la posición APos de sMayus empieza el token AToken
  // como palabra completa (delimitada por espacios / saltos de línea).
  function EsToken(APos: Integer; const AToken: string): Boolean;
  var
    iFin: Integer;
  begin
    Result := False;
    if Copy(sMayus, APos, Length(AToken)) = AToken then
    begin
      iFin := APos + Length(AToken);
      if ((APos = 1) or CharInSet(sMayus[APos - 1],
                                  [' ', #9, #10, #13, ')'])) and
         ((iFin > Length(sMayus)) or CharInSet(sMayus[iFin],
                                  [' ', #9, #10, #13, '('])) then
        Result := True;
    end;
  end;
begin
  if AFiltro = '' then
    Result := ASql
  else
  begin
    // Sin el ';' final por si lo trae (mismo criterio que
    // TfrmMtoGen.PrepararBusquedaExterna).
    sSql := TrimRight(ASql);
    while (sSql <> '') and (sSql[Length(sSql)] = ';') do
      sSql := TrimRight(Copy(sSql, 1, Length(sSql) - 1));
    sMayus := UpperCase(sSql);
    // Recorremos controlando el nivel de paréntesis: solo cuentan los
    // tokens de nivel superior (los de subconsultas se ignoran).
    iNivel := 0;
    iCorte := Length(sSql) + 1;
    bTieneWhere := False;
    i := 1;
    while i <= Length(sMayus) do
    begin
      if sMayus[i] = '''' then
      begin
        // Literal de cadena: saltar hasta la comilla de cierre para que
        // sus paréntesis o palabras clave no afecten al recorrido.
        Inc(i);
        while (i <= Length(sMayus)) and (sMayus[i] <> '''') do
          Inc(i);
      end
      else if sMayus[i] = '(' then
        Inc(iNivel)
      else if sMayus[i] = ')' then
        Dec(iNivel)
      else if iNivel = 0 then
      begin
        if EsToken(i, 'WHERE') then
          bTieneWhere := True
        else if (iCorte > Length(sSql)) and
                (EsToken(i, 'GROUP BY') or EsToken(i, 'HAVING') or
                 EsToken(i, 'ORDER BY') or EsToken(i, 'LIMIT')) then
          iCorte := i;
      end;
      Inc(i);
    end;
    if bTieneWhere then
      Result := Copy(sSql, 1, iCorte - 1) + AFiltro + ' ' +
                Copy(sSql, iCorte, MaxInt)
    else
      Result := Copy(sSql, 1, iCorte - 1) + ' WHERE 1 = 1' + AFiltro + ' ' +
                Copy(sSql, iCorte, MaxInt);
  end;
end;

end.

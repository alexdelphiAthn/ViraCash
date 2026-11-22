{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesVinculos                                }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vínculo entre una sesión de compra y los documentos que generó: quita     }
{    la referencia al borrar el pedido o el albarán y reabre la sesión         }
{    cuando se queda sin documentos (FZ-ISSUE-1106).                           }
{******************************************************************************}
unit UniDataComprasSesionesVinculos;

interface

uses
  Uni;

const
  cTipoDocSesionPedidoCompra = 'PEDC';
  cTipoDocSesionAlbaranCompra = 'ALBC';

// Devuelve una sesión CERRADA a BORRADOR: sus líneas reutilizan los
// artículos ya creados y la cabecera deja de apuntar a documentos.
procedure ReabrirSesionCompra(AQuery: TUniQuery;
                              const ASerieSesion,
                              ANumeroSesion,
                              AUsuario: string);

// Se llama dentro de la transacción del borrado del documento
// (ATipoDoc = PEDC o ALBC). Borra su fila de
// fza_compras_sesiones_documentos, limpia SERIE/NUMERO_xxx_SES de las
// sesiones que lo apuntan y reabre las que se quedan sin documentos.
procedure DesvincularDocumentoSesionesCompra(AConexion: TUniConnection;
                                             const ATipoDoc,
                                             ASerie,
                                             ANumero,
                                             AUsuario: string);

implementation

uses
  System.SysUtils, System.Generics.Collections;

type
  TClaveSesionCompra = record
    Serie: string;
    Numero: string;
  end;

procedure ReabrirSesionCompra(AQuery: TUniQuery;
                              const ASerieSesion,
                              ANumeroSesion,
                              AUsuario: string);
begin
  // Una sesion cerrada ya inserto sus articulos en la materializacion.
  // Se conservan al revertir y deben reutilizarse en el siguiente intento.
  // Las decisiones REUSAR previas mantienen su codigo de destino.
  AQuery.SQL.Text :=
    'UPDATE fza_compras_sesiones_lineas L ' +
    ' JOIN fza_compras_sesiones S ' +
    ' ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    ' AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' JOIN fza_articulos A ON A.CODIGO_ART_ART = ' +
    ' COALESCE(L.CODIGO_ART_REUSAR_SESLIN, ' +
    '          L.CODIGO_ART_TENTATIVO_SESLIN) ' +
    ' SET L.CODIGO_ART_REUSAR_SESLIN = A.CODIGO_ART_ART, ' +
    ' L.ACCION_DUPLICADO_SESLIN = ''REUSAR'', ' +
    ' L.ESDUPLICADO_SESLIN = ''S'', ' +
    ' L.INSTANTE_MODIF = NOW(), L.USUARIO_MODIF = :u ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    ' AND L.NUMERO_SES_SESLIN = :n ' +
    ' AND S.ESTADO_SES = ''CERRADA'' ' +
    ' AND IFNULL(L.ACCION_DUPLICADO_SESLIN, '''') <> ''REUSAR''';
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
  AQuery.SQL.Text :=
    'UPDATE fza_compras_sesiones SET ' +
    '  ESTADO_SES = ''BORRADOR'', ' +
    '  INSTANTE_MATERIALIZA_SES = NULL, ' +
    '  USUARIO_MATERIALIZA_SES = NULL, ' +
    '  SERIE_PEDC_SES = NULL, ' +
    '  NUMERO_PEDC_SES = NULL, ' +
    '  SERIE_ALBC_SES = NULL, ' +
    '  NUMERO_ALBC_SES = NULL, ' +
    '  MENSAJE_ERROR_SES = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF = :u ' +
    ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

function SufijoColumnaSesion(const ATipoDoc: string): string;
begin
  if SameText(ATipoDoc, cTipoDocSesionAlbaranCompra) then
    Result := 'ALBC'
  else if SameText(ATipoDoc, cTipoDocSesionPedidoCompra) then
    Result := 'PEDC'
  else
    raise EArgumentException.CreateFmt(
      'Tipo de documento de sesión no admitido: %s', [ATipoDoc]);
end;

procedure CargarSesionesVinculadas(AQuery: TUniQuery;
                                   const ATipoDoc,
                                   ASerie,
                                   ANumero: string;
                                   ASesiones: TList<TClaveSesionCompra>);
var
  sSufijo: string;
  rClave: TClaveSesionCompra;
begin
  sSufijo := SufijoColumnaSesion(ATipoDoc);
  AQuery.SQL.Text :=
    'SELECT SERIE_SES, NUMERO_SES ' +
    '  FROM fza_compras_sesiones ' +
    ' WHERE SERIE_' + sSufijo + '_SES = :s ' +
    '   AND NUMERO_' + sSufijo + '_SES = :n ' +
    'UNION ' +
    'SELECT SERIE_SES_SESDOC, NUMERO_SES_SESDOC ' +
    '  FROM fza_compras_sesiones_documentos ' +
    ' WHERE TIPO_DOC_SESDOC = :t ' +
    '   AND SERIE_SESDOC = :s AND NUMERO_SESDOC = :n';
  AQuery.ParamByName('t').AsString := ATipoDoc;
  AQuery.ParamByName('s').AsString := ASerie;
  AQuery.ParamByName('n').AsString := ANumero;
  AQuery.Open;
  try
    while not AQuery.Eof do
    begin
      rClave.Serie := AQuery.Fields[0].AsString;
      rClave.Numero := AQuery.Fields[1].AsString;
      ASesiones.Add(rClave);
      AQuery.Next;
    end;
  finally
    AQuery.Close;
  end;
end;

procedure QuitarReferenciasDocumento(AQuery: TUniQuery;
                                     const ATipoDoc,
                                     ASerie,
                                     ANumero,
                                     AUsuario: string);
var
  sSufijo: string;
begin
  sSufijo := SufijoColumnaSesion(ATipoDoc);
  AQuery.SQL.Text :=
    'DELETE FROM fza_compras_sesiones_documentos ' +
    ' WHERE TIPO_DOC_SESDOC = :t ' +
    '   AND SERIE_SESDOC = :s AND NUMERO_SESDOC = :n';
  AQuery.ParamByName('t').AsString := ATipoDoc;
  AQuery.ParamByName('s').AsString := ASerie;
  AQuery.ParamByName('n').AsString := ANumero;
  AQuery.ExecSQL;
  AQuery.SQL.Text :=
    'UPDATE fza_compras_sesiones SET ' +
    '  SERIE_' + sSufijo + '_SES = NULL, ' +
    '  NUMERO_' + sSufijo + '_SES = NULL, ' +
    '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
    ' WHERE SERIE_' + sSufijo + '_SES = :s ' +
    '   AND NUMERO_' + sSufijo + '_SES = :n';
  AQuery.ParamByName('s').AsString := ASerie;
  AQuery.ParamByName('n').AsString := ANumero;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

function SesionSinDocumentos(AQuery: TUniQuery;
                             const ASerieSesion,
                             ANumeroSesion: string): Boolean;
begin
  AQuery.SQL.Text :=
    'SELECT ' +
    '  (SELECT COUNT(*) FROM fza_compras_sesiones_documentos d ' +
    '    WHERE d.SERIE_SES_SESDOC = s.SERIE_SES ' +
    '      AND d.NUMERO_SES_SESDOC = s.NUMERO_SES) AS DOCUMENTOS, ' +
    '  COALESCE(s.NUMERO_PEDC_SES, '''') AS PEDIDO, ' +
    '  COALESCE(s.NUMERO_ALBC_SES, '''') AS ALBARAN, ' +
    '  s.ESTADO_SES ' +
    '  FROM fza_compras_sesiones s ' +
    ' WHERE s.SERIE_SES = :s AND s.NUMERO_SES = :n ' +
    ' FOR UPDATE';
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.Open;
  try
    Result :=
      (not AQuery.Eof) and
      SameText(AQuery.FieldByName('ESTADO_SES').AsString, 'CERRADA') and
      (AQuery.FieldByName('DOCUMENTOS').AsInteger = 0) and
      (AQuery.FieldByName('PEDIDO').AsString = '') and
      (AQuery.FieldByName('ALBARAN').AsString = '');
  finally
    AQuery.Close;
  end;
end;

procedure DesvincularDocumentoSesionesCompra(AConexion: TUniConnection;
                                             const ATipoDoc,
                                             ASerie,
                                             ANumero,
                                             AUsuario: string);
var
  q: TUniQuery;
  oSesiones: TList<TClaveSesionCompra>;
  rClave: TClaveSesionCompra;
begin
  q := TUniQuery.Create(nil);
  oSesiones := TList<TClaveSesionCompra>.Create;
  try
    q.Connection := AConexion;
    CargarSesionesVinculadas(q, ATipoDoc, ASerie, ANumero, oSesiones);
    QuitarReferenciasDocumento(q, ATipoDoc, ASerie, ANumero, AUsuario);
    for rClave in oSesiones do
    begin
      if SesionSinDocumentos(q, rClave.Serie, rClave.Numero) then
        ReabrirSesionCompra(q, rClave.Serie, rClave.Numero, AUsuario);
    end;
  finally
    FreeAndNil(oSesiones);
    FreeAndNil(q);
  end;
end;

end.

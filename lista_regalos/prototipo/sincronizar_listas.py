"""Prototipo del sincronizador ViraCash ↔ PrestaShop de listas de regalos.

Hace lo que hará ViraCash en Delphi tras la fusión (ver README, «Fusión»),
con los mismos procedimientos y el mismo contrato de la API del módulo:

  catalogo     exporta artículos de una familia y los publica en el
               laboratorio PrestaShop (alta por PHP: la clave de la API del
               laboratorio no permite crear productos).
  sincronizar  1) recoge los regalos web pendientes y los registra con
               PRC_LRG_REGALO_WEB; 2) publica las listas cuya versión no
               tiene la tienda, incluyendo los regalos web ya registrados.

Uso:
  py -3.14 prototipo\\sincronizar_listas.py sincronizar --bbdd fzam_bazar_turnos_listas
  py -3.14 prototipo\\sincronizar_listas.py catalogo --familia QB-P8%
"""
import argparse
import json
import os
import subprocess
import tempfile
import urllib.error
import urllib.request

import pymysql

USUARIO = 'SINCRO-PS'
RAIZ_LAB = r'C:\DISCO_DURO\proyectos\factuzam_ps\prestashop_factuzam_lab'
PUBLICAR_PHP = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), 'pruebas', 'publicar_catalogo_lab.php')
# Mismos códigos que PRC_LRG_REGALO_WEB: 1/2 registrado, 3 ya estaba.
REGISTRADOS = (1, 2, 3)


def normalizar_origen(url_base):
    """Igual que NormalizarOrigenPedidos (inLibImportacionPedidos.pas)."""
    return url_base.strip().lower().rstrip('/')


class ApiTienda:
    def __init__(self, url_tienda, clave):
        self.url = url_tienda.rstrip('/') + \
            '/index.php?fc=module&module=vcashlistaregalos&controller=api'
        self.clave = clave

    def llamar(self, accion, cuerpo=None, extra=''):
        peticion = urllib.request.Request(
            self.url + '&accion=' + accion + extra,
            data=None if cuerpo is None else json.dumps(cuerpo).encode(),
            method='GET' if cuerpo is None else 'POST',
            headers={'X-Vcash-Clave': self.clave,
                     'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(peticion, timeout=30) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            respuesta = json.loads(e.read() or b'{}')
            raise RuntimeError('API %s: %s %s' % (
                accion, e.code, respuesta.get('error'))) from e


def llamar_proc(cur, proc, entrada, salidas):
    marcas = ', '.join(['%s'] * len(entrada) +
                       ['@o%d' % i for i in range(salidas)])
    cur.execute('CALL %s(%s)' % (proc, marcas), entrada)
    while cur.nextset():
        pass
    if not salidas:
        return ()
    cur.execute('SELECT ' + ', '.join('@o%d' % i for i in range(salidas)))
    return cur.fetchone()


def consultar_proc(cur, proc, entrada):
    cur.execute('CALL %s(%s)' % (proc, ', '.join(['%s'] * len(entrada))),
                entrada)
    filas = list(cur.fetchall())
    while cur.nextset():
        pass
    return filas


def pedido_viracash(cur, origen, id_pedido_ps):
    """Serie y número del pedido ya importado, si lo está."""
    cur.execute('SELECT P.SERIE_PED, P.NUMERO_PED FROM fza_pedidos P '
                'WHERE P.ORIGENPS_PED = %s AND P.IDPS_PED = %s LIMIT 1',
                (origen, str(id_pedido_ps)))
    return cur.fetchone() or ('', '')


def recoger_regalos(con, api, origen, informe):
    rechazados = []
    with con.cursor() as cur:
        for regalo in api.llamar('regalos', extra='&desde=0&limite=500')[
                'regalos']:
            serie, numero = pedido_viracash(cur, origen, regalo['id_pedido'])
            _, resultado = llamar_proc(cur, 'PRC_LRG_REGALO_WEB', [
                regalo['lista'], int(regalo['linea']), regalo['sku'],
                int(regalo['cantidad']), regalo['importe'], origen,
                str(regalo['id_pedido']), str(regalo['id_linea_pedido']),
                serie, numero, regalo['nombre'], regalo['email'],
                regalo['mensaje'], USUARIO], 2)
            informe.append('regalo web %s/%s de %s: resultado %s' % (
                regalo['lista'], regalo['linea'], regalo['nombre'],
                resultado))
            if resultado not in REGISTRADOS:
                rechazados.append(int(regalo['id_linea_pedido']))
    if rechazados:
        api.llamar('confirmar', {'ids_linea_pedido': rechazados,
                                 'estado': 'RECHAZADO'})


def leer_lista(cur, codigo, origen):
    """Cabecera, líneas y regalos web incluidos de una misma foto."""
    cur.execute(
        'SELECT L.CODIGO_LRG, L.CLAVE_PUBLICA_LRG, L.TIPO_LRG, L.TITULO_LRG,'
        ' L.NOMBRE_HOMENAJEADO_LRG, L.NOMBRE_TITULARES_LRG, L.MENSAJE_LRG,'
        ' L.FECHA_EVENTO_LRG, L.TIPO_ENTREGA_LRG, L.ESTADO_LRG,'
        ' L.ESPUBLICA_WEB_LRG, L.ESBUSCABLE_LRG, L.VERSION_LRG'
        ' FROM fza_listas_regalos L WHERE L.CODIGO_LRG = %s', (codigo,))
    c = cur.fetchone()
    cur.execute(
        'SELECT E.LINEA_LRGLIN, E.ORDEN_LRGLIN, E.CODIGO_SKU_LRGLIN,'
        ' E.CODIGO_ART_LRGLIN, E.DESCRIPCION_LRGLIN,'
        ' E.CANTIDAD_DESEADA_LRGLIN, E.CANTIDAD_REGALADA_LRGLIN,'
        ' E.ESIMPRESCINDIBLE_LRGLIN, E.ESADMITE_OTRA_VARIANTE_LRGLIN,'
        ' E.OBSERVACIONES_LRGLIN'
        ' FROM VI_LRG_LINEAS_ESTADO E'
        " WHERE E.CODIGO_LRG_LRGLIN = %s AND E.ESACTIVO_LRGLIN = 'S'"
        ' ORDER BY E.ORDEN_LRGLIN, E.LINEA_LRGLIN', (codigo,))
    lineas = [{
        'linea': f[0], 'orden': f[1], 'sku': f[2], 'articulo': f[3],
        'descripcion': f[4], 'cantidad_deseada': int(f[5]),
        'cantidad_regalada': int(f[6]), 'imprescindible': f[7] == 'S',
        'admite_otra_variante': f[8] == 'S', 'observaciones': f[9] or '',
    } for f in cur.fetchall()]
    cur.execute('SELECT R.IDPS_LINEA_LRGREG FROM fza_listas_regalos_regalos R'
                " WHERE R.CODIGO_LRG_LRGREG = %s AND R.CANAL_LRGREG = 'WEB'"
                ' AND R.ORIGENPS_LRGREG = %s', (codigo, origen))
    incluidos = [int(f[0]) for f in cur.fetchall()]
    return {
        'lista': {
            'codigo': c[0], 'clave_publica': c[1], 'tipo': c[2],
            'titulo': c[3], 'homenajeado': c[4] or '', 'titulares': c[5],
            'mensaje': c[6] or '',
            'fecha_evento': c[7].isoformat() if c[7] else None,
            'tipo_entrega': c[8],
            'visible': c[9] == 'ABIERTA' and c[10] == 'S',
            'buscable': c[11] == 'S', 'version': int(c[12])},
        'lineas': lineas,
        'regalos_web_incluidos': incluidos,
    }


def publicar_listas(con, api, empresa, origen, informe):
    with con.cursor() as cur:
        pendientes = consultar_proc(cur, 'PRC_LRG_PUBLICACIONES_PENDIENTES',
                                    [empresa, origen])
        for fila in pendientes:
            # Foto coherente: la versión confirmada es la de estos datos.
            cur.execute('START TRANSACTION WITH CONSISTENT SNAPSHOT')
            datos = leer_lista(cur, fila[0], origen)
            cur.execute('COMMIT')
            respuesta = api.llamar('publicar', datos)
            llamar_proc(cur, 'PRC_LRG_PUBLICACION_CONFIRMAR', [
                fila[0], origen, datos['lista']['version'], USUARIO], 0)
            informe.append('lista %s v%s publicada%s%s' % (
                fila[0], datos['lista']['version'],
                ' (ignorada: la tienda tenía una posterior)'
                if respuesta['ignorada'] else '',
                ' · sin producto en la tienda: '
                + ', '.join(respuesta['skus_sin_producto'])
                if respuesta['skus_sin_producto'] else ''))


def sincronizar(con, api, empresa, origen):
    informe = []
    recoger_regalos(con, api, origen, informe)
    publicar_listas(con, api, empresa, origen, informe)
    return informe


def exportar_catalogo(con, familia):
    with con.cursor() as cur:
        cur.execute(
            'SELECT A.CODIGO_ART_ART, A.DESCRIPCION_ART, A.TIPO_IVA_ART,'
            ' (SELECT CB.CODIGO_BARRAS_CB FROM fza_codigos_barras CB'
            '   WHERE CB.CODIGO_UNIDAD_CB = A.CODIGO_ART_ART'
            '   ORDER BY CB.ESPRINCIPAL_CB DESC LIMIT 1),'
            ' (SELECT T.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas T'
            "   WHERE T.CODIGO_ART_ARTTAR = A.CODIGO_ART_ART"
            "     AND T.CODIGO_TAR_ARTTAR = 'PVP'"
            "     AND T.ESACTIVO_ARTTAR = 'S' LIMIT 1),"
            ' COALESCE((SELECT SUM(K.CANTIDAD_STK)'
            '   FROM fza_articulos_stockactual K'
            '   WHERE K.CODIGO_UNIDAD_STK = A.CODIGO_ART_ART), 0)'
            ' FROM fza_articulos A'
            " WHERE A.CODIGO_FAM_ART LIKE %s AND A.ESACTIVO_ART = 'S'"
            " AND A.ESVARIACION_ART = 'N'"
            ' ORDER BY A.CODIGO_ART_ART', (familia,))
        return [{
            'referencia': f[0], 'nombre': f[1], 'tipo_iva': f[2],
            'ean13': f[3] or '', 'precio_con_iva': float(f[4] or 0),
            'existencias': max(0, int(f[5])),
        } for f in cur.fetchall()]


def publicar_catalogo(articulos, raiz_lab=RAIZ_LAB):
    with tempfile.TemporaryDirectory(prefix='vclr-catalogo-') as carpeta:
        ruta = os.path.join(carpeta, 'articulos.json')
        with open(ruta, 'w', encoding='utf-8') as f:
            json.dump(articulos, f, ensure_ascii=False)
        r = subprocess.run(
            ['php', '-c', os.path.join(raiz_lab, 'php', 'php.ini'),
             PUBLICAR_PHP, os.path.join(raiz_lab, 'www'), ruta],
            capture_output=True, text=True, encoding='utf-8')
    if r.returncode != 0:
        raise RuntimeError('Alta en PrestaShop: ' + r.stderr.strip())
    return r.stdout.strip().splitlines()


def conectar(args):
    return pymysql.connect(host=args.host, port=args.puerto, user='root',
                           database=args.bbdd, charset='utf8mb4',
                           autocommit=True)


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('accion', choices=['catalogo', 'sincronizar'])
    p.add_argument('--host', default='127.0.0.1')
    p.add_argument('--puerto', type=int, default=34712)
    p.add_argument('--bbdd', default='fzam_bazar_turnos_listas')
    p.add_argument('--empresa', default='012')
    p.add_argument('--tienda', default='http://127.0.0.1:8081')
    p.add_argument('--origen', default='http://127.0.0.1:8081/api')
    p.add_argument('--clave', help='clave de la API del módulo')
    p.add_argument('--familia', default='QB-P8%')
    args = p.parse_args()
    con = conectar(args)
    try:
        if args.accion == 'catalogo':
            for linea in publicar_catalogo(exportar_catalogo(con,
                                                             args.familia)):
                print(linea)
        else:
            api = ApiTienda(args.tienda, args.clave)
            for linea in sincronizar(con, api, args.empresa,
                                     normalizar_origen(args.origen)):
                print(linea)
    finally:
        con.close()


if __name__ == '__main__':
    main()

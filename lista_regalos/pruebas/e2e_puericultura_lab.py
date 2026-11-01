"""Prueba de extremo a extremo: ViraCash (copia del bazar) ↔ PrestaShop.

Requisitos:
- Motor de la batería 16 en 127.0.0.1:34712 con la copia
  fzam_bazar_turnos_listas y los scripts sql\\ aplicados.
- Laboratorio PrestaShop en http://127.0.0.1:8081 con el módulo instalado
  y la puericultura publicada (prototipo\\sincronizar_listas.py catalogo).

Crea una lista de bautizo nueva en cada ejecución, regala en caja y en la
web, sincroniza y la cierra. Copia antes el módulo al laboratorio para
probar la versión del proyecto. Deja en el laboratorio el pedido y el
cliente de prueba (vclr.invitado@example.com).

Uso: py -3.14 pruebas\\e2e_puericultura_lab.py
"""
import http.cookiejar
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

import pymysql

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, 'prototipo'))
import sincronizar_listas as sincro  # noqa: E402

RAIZ_LAB = sincro.RAIZ_LAB
TIENDA = 'http://127.0.0.1:8081'
ORIGEN = sincro.normalizar_origen('http://127.0.0.1:8081/api')
EMPRESA = '012'
VALIDAR = os.path.join(RAIZ, 'pruebas', 'validar_pedido_lab.php')
PS = dict(host='127.0.0.1', port=3306, user='ps_factuzam_lab',
          password='FzPsLab_2026_9xT4!', database='prestashop_factuzam_lab',
          autocommit=True)
VC = dict(host='127.0.0.1', port=34712, user='root',
          database='fzam_bazar_turnos_listas', charset='utf8mb4',
          autocommit=True)

fallos = []


def comprobar(condicion, texto):
    print(('ok    ' if condicion else 'FALLO ') + texto)
    if not condicion:
        fallos.append(texto)


class Invitado:
    def __init__(self):
        self.abridor = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def get(self, url):
        with self.abridor.open(url) as r:
            return r.read().decode('utf-8')

    def regalar(self, url, linea, cantidad, nombre, mensaje=''):
        html = self.get(url)
        token = re.search(r'name="token" value="([0-9a-f]+)"', html).group(1)
        datos = urllib.parse.urlencode({
            'token': token, 'nombre': nombre, 'mensaje': mensaje,
            'vclr_linea': linea, 'cantidad_%d' % linea: cantidad}).encode()
        with self.abridor.open(url, data=datos) as r:
            return r.geturl(), r.read().decode('utf-8')


def maximo(html, linea):
    m = re.search(r'name="cantidad_%d"[^>]*max="(\d+)"' % linea, html)
    return int(m.group(1)) if m else 0


def bloque_linea(html, descripcion):
    # El bloque <li> de la línea cuya descripción es la indicada.
    for bloque in re.findall(r'<li class="vclr-linea.*?</li>', html, re.S):
        if descripcion in bloque:
            return bloque
    return ''


def instalar_modulo():
    destino = os.path.join(RAIZ_LAB, 'www', 'modules', 'vcashlistaregalos')
    shutil.rmtree(destino, ignore_errors=True)
    shutil.copytree(os.path.join(RAIZ, 'prestashop', 'vcashlistaregalos'),
                    destino)
    # Smarty compila las plantillas: sin vaciar la caché se vería la vieja.
    shutil.rmtree(os.path.join(RAIZ_LAB, 'www', 'var', 'cache', 'prod',
                               'smarty'), ignore_errors=True)


def crear_lista_bautizo(cur):
    codigo, clave = sincro.llamar_proc(cur, 'PRC_LRG_CREAR', [
        EMPRESA, 'GEN', 'QC05', 'BAUTIZO', 'Bautizo de Mateo', 'Mateo',
        'Elena y Javier', '2026-12-13', 'E2E'], 2)
    for sku, cantidad, precio in (('QT-FAL', 1, 69.90), ('QT-REC', 2, 12.50),
                                  ('QT-CAJ', 25, 1.20)):
        sincro.llamar_proc(cur, 'PRC_LRG_LINEA_AGREGAR',
                           [codigo, sku, cantidad, precio, 'E2E'], 2)
    # Lo que hará el mantenimiento de listas: datos de cabecera + versión.
    cur.execute(
        'UPDATE fza_listas_regalos SET MENSAJE_LRG = %s,'
        ' PORCENTAJE_BONIFICACION_LRG = 5, VERSION_LRG = VERSION_LRG + 1'
        ' WHERE CODIGO_LRG = %s',
        ('¡Gracias por acompañarnos en el bautizo de Mateo!', codigo))
    cur.execute("UPDATE fza_listas_regalos_lineas SET"
                " ESIMPRESCINDIBLE_LRGLIN = 'S' WHERE CODIGO_LRG_LRGLIN = %s"
                " AND CODIGO_SKU_LRGLIN = 'QT-FAL'", (codigo,))
    return codigo, clave


def reponer_catalogo(vc):
    # Cada pasada compra un faldón en la tienda: se vuelve a publicar la
    # puericultura de ViraCash para reponer las existencias del laboratorio.
    sincro.publicar_catalogo(sincro.exportar_catalogo(vc, 'QB-P8%'))


def main():
    instalar_modulo()
    ps = pymysql.connect(**PS)
    vc = pymysql.connect(**VC)
    reponer_catalogo(vc)
    cps = ps.cursor()
    cvc = vc.cursor()
    cps.execute("SELECT value FROM pslab_configuration"
                " WHERE name = 'VCLR_CLAVE_API'")
    api = sincro.ApiTienda(TIENDA, cps.fetchone()[0])
    try:
        sincro.ApiTienda(TIENDA, 'mala').llamar('versiones')
        comprobar(False, 'la API rechaza una clave errónea')
    except RuntimeError as e:
        comprobar('401' in str(e), 'la API rechaza una clave errónea')

    codigo, clave = crear_lista_bautizo(cvc)
    informe = sincro.sincronizar(vc, api, EMPRESA, ORIGEN)
    comprobar(any(codigo in i and 'sin producto' not in i for i in informe),
              'ViraCash publica la lista con todos sus SKU en la tienda')
    comprobar(sincro.sincronizar(vc, api, EMPRESA, ORIGEN) == [],
              'una segunda sincronización no tiene nada que hacer')
    url = TIENDA + '/lista-regalos/' + clave
    html = Invitado().get(url)
    comprobar('Bautizo de Mateo' in html and 'Faldón de bautizo' in html,
              'página pública con los artículos de puericultura')
    comprobar(maximo(html, 10) == 1 and maximo(html, 20) == 2
              and maximo(html, 30) == 25, 'muestra lo pendiente por línea')
    # El formato depende del idioma por defecto (inglés en el laboratorio).
    comprobar('69,90' in html or '69.90' in html,
              'precio de la tienda con IVA')
    comprobar(clave in Invitado().get(TIENDA + '/listas-regalos?q=javier'),
              'el buscador encuentra la lista por los titulares')

    _, res = sincro.llamar_proc(cvc, 'PRC_LRG_REGALO_CAJA', [
        codigo, 20, 'QT-REC', 1, 12.50, EMPRESA, 'GEN', '1', 'E2E-' + codigo,
        10, 'Abuela Carmen', 'Con todo mi cariño', 'N', 'QT-ANA'], 2)
    comprobar(res == 1, 'la caja registra un regalo de recordatorios')
    sincro.sincronizar(vc, api, EMPRESA, ORIGEN)
    comprobar(maximo(Invitado().get(url), 20) == 1,
              'la web descuenta el regalo de caja tras sincronizar')

    marta = Invitado()
    _, html = marta.regalar(url, 10, 2, 'Tía Marta')
    comprobar('Solo quedan 1' in html, 'no deja reservar más de lo pendiente')
    destino, _ = marta.regalar(url, 10, 1, 'Tía Marta', 'Para Mateo')
    comprobar('cart' in destino or 'carrito' in destino,
              'regalar lleva al carrito')
    otro = Invitado().get(url)
    comprobar('Reservado por otro invitado' in bloque_linea(
        otro, 'Faldón de bautizo'), 'otro invitado lo ve reservado')
    cps.execute("SELECT r.id_cart FROM pslab_vclr_reserva r"
                " JOIN pslab_vclr_lista l USING (id_vclr_lista)"
                " WHERE l.codigo = %s", (codigo,))
    id_carrito = cps.fetchone()[0]
    r = subprocess.run(['php', '-c', os.path.join(RAIZ_LAB, 'php', 'php.ini'),
                        VALIDAR, os.path.join(RAIZ_LAB, 'www'),
                        str(id_carrito)], capture_output=True, text=True)
    comprobar(r.returncode == 0, 'el carrito se convierte en pedido '
              + r.stderr.strip()[-200:])
    cps.execute("SELECT g.estado, g.sku FROM pslab_vclr_regalo g"
                " JOIN pslab_vclr_lista l USING (id_vclr_lista)"
                " WHERE l.codigo = %s", (codigo,))
    comprobar(cps.fetchall() == (('PENDIENTE', 'QT-FAL'),),
              'el pedido deja el regalo pendiente de ViraCash')

    informe = sincro.sincronizar(vc, api, EMPRESA, ORIGEN)
    comprobar(any('regalo web' in i and 'resultado 1' in i for i in informe),
              'ViraCash registra el regalo web')
    cvc.execute("SELECT CANAL_LRGREG, NOMBRE_REGALANTE_LRGREG,"
                " IMPORTE_LRGREG FROM fza_listas_regalos_regalos"
                " WHERE CODIGO_LRG_LRGREG = %s ORDER BY ID_LRGREG", (codigo,))
    regalos = [(f[0], f[1], float(f[2])) for f in cvc.fetchall()]
    comprobar(regalos == [('CAJA', 'Abuela Carmen', 12.5),
                          ('WEB', 'Tía Marta', 69.9)],
              'ViraCash tiene los dos regalos con su importe')
    cps.execute("SELECT g.estado FROM pslab_vclr_regalo g"
                " JOIN pslab_vclr_lista l USING (id_vclr_lista)"
                " WHERE l.codigo = %s", (codigo,))
    comprobar(cps.fetchone()[0] == 'REGISTRADO',
              'la publicación marca el regalo web como registrado')
    html = Invitado().get(url)
    bloque = bloque_linea(html, 'Faldón de bautizo')
    comprobar('Ya regalado' in bloque and 'regalados 1' in bloque,
              'el regalo web cuenta una sola vez')
    comprobar(sincro.sincronizar(vc, api, EMPRESA, ORIGEN) == [],
              'tras registrar, no queda nada pendiente')

    total, bonificacion, res = sincro.llamar_proc(
        cvc, 'PRC_LRG_CERRAR', [codigo, 'E2E'], 3)
    comprobar(res == 1 and float(total) == 82.40
              and float(bonificacion) == 4.12,
              'cierre: 82,40 regalados y 4,12 de bonificación (5 %)')
    sincro.sincronizar(vc, api, EMPRESA, ORIGEN)
    try:
        Invitado().get(url)
        comprobar(False, 'la lista cerrada deja de verse')
    except urllib.error.HTTPError as e:
        comprobar(e.code == 404, 'la lista cerrada deja de verse')
    datos = sincro.leer_lista(cvc, codigo, ORIGEN)
    datos['lista']['version'] -= 1
    comprobar(api.llamar('publicar', datos)['ignorada'],
              'la tienda ignora una versión anterior')
    ps.close()
    vc.close()
    print('\n%d fallos' % len(fallos))
    return 1 if fallos else 0


if __name__ == '__main__':
    sys.exit(main())

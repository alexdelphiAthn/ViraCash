"""Prueba de extremo a extremo del sincronizador Delphi de ViraCash.

Compila pruebas\\delphi\\PruebaSincronizacionListas.dpr (las unidades
inLibListasRegalos*, UniDataListasRegalosSincronizacion de ViraCash\\src) y
lo ejecuta contra la copia fzam_bazar_turnos_listas (127.0.0.1:34712) y el
laboratorio PrestaShop (127.0.0.1:8081). Mismos requisitos que
e2e_puericultura_lab.py.

Uso: py -3.14 pruebas\\e2e_sincronizador_delphi.py
"""
import os
import subprocess
import sys
import tempfile
import urllib.error

import pymysql

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, 'pruebas'))
import e2e_puericultura_lab as e2e  # noqa: E402

SRC = os.path.join(os.path.dirname(RAIZ), 'src')
DPR = os.path.join(RAIZ, 'pruebas', 'delphi', 'PruebaSincronizacionListas.dpr')
URL_API = 'http://127.0.0.1:8081/api'


def compilar(carpeta):
    delphi = os.environ['FACTUZAM_DELPHI_ROOT']
    unidac = os.path.join(os.environ['FACTUZAM_UNIDAC_ROOT'], 'Win64')
    rutas = ';'.join([os.path.join(SRC, 'Lib'),
                      os.path.join(SRC, 'DataModules'), unidac,
                      os.path.join(delphi, 'lib', 'win64', 'release')])
    os.makedirs(os.path.join(carpeta, 'dcu'))
    r = subprocess.run(
        [os.path.join(delphi, 'bin', 'dcc64.exe'), '-B', '-Q',
         '-NSSystem;Data;Winapi;Vcl', '-U' + rutas, '-E' + carpeta,
         '-N' + os.path.join(carpeta, 'dcu'), DPR],
        capture_output=True, text=True, cwd=os.path.dirname(DPR))
    if r.returncode != 0:
        raise RuntimeError(r.stdout + r.stderr)
    return os.path.join(carpeta, 'PruebaSincronizacionListas.exe')


def sincronizar(exe, clave):
    r = subprocess.run([exe, '34712', 'fzam_bazar_turnos_listas', e2e.EMPRESA,
                        URL_API, clave], capture_output=True, text=True,
                       encoding='utf-8', errors='replace')
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout.strip().splitlines()


def main():
    e2e.instalar_modulo()
    ps = pymysql.connect(**e2e.PS)
    vc = pymysql.connect(**e2e.VC)
    cps, cvc = ps.cursor(), vc.cursor()
    e2e.reponer_catalogo(vc)
    cps.execute("SELECT value FROM pslab_configuration"
                " WHERE name = 'VCLR_CLAVE_API'")
    clave = cps.fetchone()[0]
    with tempfile.TemporaryDirectory(prefix='vclr-delphi-') as carpeta:
        exe = compilar(carpeta)
        e2e.comprobar(True, 'compila el sincronizador Delphi')
        sincronizar(exe, clave)
        codigo, clave_lista = e2e.crear_lista_bautizo(cvc)
        salida = sincronizar(exe, clave)
        e2e.comprobar(any(codigo in s and 'publicada' in s for s in salida),
                      'Delphi publica la lista nueva: ' + ' | '.join(salida))
        e2e.comprobar(sincronizar(exe, clave)[0].startswith(
            'PUBLICADAS=0 REGISTRADOS=0'), 'sin cambios no publica nada')
        url = e2e.TIENDA + '/lista-regalos/' + clave_lista
        html = e2e.Invitado().get(url)
        e2e.comprobar('Faldón de bautizo' in html and e2e.maximo(html, 20) == 2,
                      'la página muestra lo publicado por Delphi')
        marta = e2e.Invitado()
        marta.regalar(url, 10, 1, 'Tía Marta', 'Desde Delphi')
        cps.execute("SELECT r.id_cart FROM pslab_vclr_reserva r"
                    " JOIN pslab_vclr_lista l USING (id_vclr_lista)"
                    " WHERE l.codigo = %s", (codigo,))
        r = subprocess.run(['php', '-c', os.path.join(e2e.RAIZ_LAB, 'php',
                                                      'php.ini'),
                            e2e.VALIDAR, os.path.join(e2e.RAIZ_LAB, 'www'),
                            str(cps.fetchone()[0])], capture_output=True,
                           text=True)
        e2e.comprobar(r.returncode == 0, 'pedido web del faldón')
        salida = sincronizar(exe, clave)
        e2e.comprobar(salida[0] == 'PUBLICADAS=1 REGISTRADOS=1 RECHAZADOS=0',
                      'Delphi registra el regalo y republica: ' + salida[0])
        cvc.execute("SELECT CANAL_LRGREG, NOMBRE_REGALANTE_LRGREG,"
                    " MENSAJE_LRGREG, IMPORTE_LRGREG FROM"
                    " fza_listas_regalos_regalos WHERE CODIGO_LRG_LRGREG = %s",
                    (codigo,))
        filas = [(f[0], f[1], f[2], float(f[3])) for f in cvc.fetchall()]
        e2e.comprobar(filas == [('WEB', 'Tía Marta', 'Desde Delphi', 69.9)],
                      'regalo web con acentos e importe en ViraCash')
        cps.execute("SELECT g.estado FROM pslab_vclr_regalo g"
                    " JOIN pslab_vclr_lista l USING (id_vclr_lista)"
                    " WHERE l.codigo = %s", (codigo,))
        e2e.comprobar(cps.fetchone()[0] == 'REGISTRADO',
                      'la tienda lo da por registrado')
        bloque = e2e.bloque_linea(e2e.Invitado().get(url), 'Faldón de bautizo')
        e2e.comprobar('Ya regalado' in bloque and 'regalados 1' in bloque,
                      'el regalo cuenta una sola vez')
        e2e.sincro.llamar_proc(cvc, 'PRC_LRG_CERRAR', [codigo, 'E2E'], 3)
        sincronizar(exe, clave)
        try:
            e2e.Invitado().get(url)
            oculta = False
        except urllib.error.HTTPError as error:
            oculta = error.code == 404
        e2e.comprobar(oculta, 'la lista cerrada desaparece de la web')
    ps.close()
    vc.close()
    print('\n%d fallos' % len(e2e.fallos))
    return 1 if e2e.fallos else 0


if __name__ == '__main__':
    sys.exit(main())

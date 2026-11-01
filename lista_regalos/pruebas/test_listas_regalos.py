"""Pruebas de los scripts SQL de listas de regalos.

Levanta un MariaDB desechable en %TEMP% (solo loopback), crea una BBDD con
colación por defecto distinta de la de las tablas, aplica los scripts dos
veces, los revierte, los vuelve a aplicar y ejercita los procedimientos.

Uso (PyMySQL está en Python 3.14 en este equipo):
  py -3.14 -I pruebas\\test_listas_regalos.py -v
"""
import glob
import os
import re
import shutil
import socket
import subprocess
import tempfile
import time
import unittest
import uuid

import pymysql

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_SQL = os.path.join(RAIZ, 'sql')
DIR_PRUEBAS = os.path.join(RAIZ, 'pruebas')
MODELO = r'C:\DISCO_DURO\proyectos\factuzam_web\factuzam_original.sql'
BBDD = 'lr_pruebas'

TABLAS = os.path.join(DIR_SQL, '20261031_listas_regalos.sql')
TABLAS_RB = os.path.join(DIR_SQL, '20261031_listas_regalos_rollback.sql')
PROCS = os.path.join(DIR_SQL, '20261031_listas_regalos_procedimientos.sql')
PROCS_RB = os.path.join(
    DIR_SQL, '20261031_listas_regalos_procedimientos_rollback.sql')

SERVIDOR = {}


def binarios_mariadb():
    candidatos = sorted(glob.glob(r'C:\Program Files\MariaDB *\bin'),
                        reverse=True)
    if not candidatos:
        raise RuntimeError('No se encuentra MariaDB en Program Files')
    return candidatos[0]


def puerto_libre():
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def extraer_del_modelo():
    """Copia del modelo las piezas reales de las que dependen los scripts."""
    with open(MODELO, encoding='utf-8-sig') as f:
        texto = f.read()
    piezas = []
    for tabla in ('fza_contadores', 'fza_articulos_skus'):
        m = re.search(r'CREATE TABLE `%s` \(.*?\) ENGINE=[^;]*;' % tabla,
                      texto, re.S)
        piezas.append(m.group(0))
    m = re.search(r'DELIMITER ;;\s*CREATE PROCEDURE `PRC_GET_NEXT_CONTADOR`'
                  r'.*?END ;;\s*DELIMITER ;', texto, re.S)
    piezas.append(m.group(0))
    return '\n'.join(piezas)


def ejecutar_script(texto):
    """Aplica un script con el cliente de línea de órdenes (DELIMITER)."""
    if texto.startswith('\ufeff'):
        texto = texto[1:]
    cliente = os.path.join(SERVIDOR['bin'], 'mariadb.exe')
    r = subprocess.run(
        [cliente, '--protocol=TCP', '-h127.0.0.1',
         '-P%d' % SERVIDOR['puerto'], '-uroot',
         '--default-character-set=utf8mb4', BBDD],
        input=texto.encode('utf-8'), capture_output=True)
    if r.returncode != 0:
        raise AssertionError(r.stderr.decode('utf-8', 'replace'))


def aplicar(ruta):
    with open(ruta, encoding='utf-8-sig') as f:
        ejecutar_script(f.read())


def conectar():
    return pymysql.connect(host='127.0.0.1', port=SERVIDOR['puerto'],
                           user='root', database=BBDD, charset='utf8mb4',
                           autocommit=True)


def setUpModule():
    SERVIDOR['bin'] = binarios_mariadb()
    SERVIDOR['puerto'] = puerto_libre()
    SERVIDOR['datos'] = os.path.join(
        tempfile.gettempdir(), 'lista-regalos-it-' + uuid.uuid4().hex)
    os.makedirs(SERVIDOR['datos'])
    subprocess.run([os.path.join(SERVIDOR['bin'], 'mariadb-install-db.exe'),
                    '--datadir=' + SERVIDOR['datos'], '--silent'],
                   check=True)
    SERVIDOR['proceso'] = subprocess.Popen(
        [os.path.join(SERVIDOR['bin'], 'mariadbd.exe'),
         '--defaults-file=' + os.path.join(SERVIDOR['datos'], 'my.ini'),
         '--port=%d' % SERVIDOR['puerto'], '--bind-address=127.0.0.1',
         '--skip-grant-tables', '--skip-name-resolve',
         '--innodb-lock-wait-timeout=2', '--console'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(80):
        try:
            pymysql.connect(host='127.0.0.1', port=SERVIDOR['puerto'],
                            user='root', connect_timeout=1).close()
            break
        except pymysql.err.OperationalError:
            time.sleep(0.25)
    else:
        raise RuntimeError('MariaDB no arrancó')
    c = pymysql.connect(host='127.0.0.1', port=SERVIDOR['puerto'],
                        user='root', autocommit=True)
    with c.cursor() as cur:
        # Colación por defecto distinta de la de las tablas a propósito.
        cur.execute('CREATE DATABASE %s CHARACTER SET utf8mb4 '
                    'COLLATE utf8mb4_general_ci' % BBDD)
    c.close()
    ejecutar_script(extraer_del_modelo())
    aplicar(os.path.join(DIR_PRUEBAS, 'esquema_minimo.sql'))


def tearDownModule():
    proceso = SERVIDOR.get('proceso')
    if proceso:
        proceso.kill()
        proceso.wait(10)
    datos = SERVIDOR.get('datos', '')
    if os.path.basename(datos).startswith('lista-regalos-it-'):
        shutil.rmtree(datos, ignore_errors=True)


def llamar(cur, proc, entrada, salidas):
    """CALL con parámetros OUT recogidos en variables de sesión."""
    marcas = ', '.join(['%s'] * len(entrada) +
                       ['@o%d' % i for i in range(salidas)])
    cur.execute('CALL %s(%s)' % (proc, marcas), entrada)
    while cur.nextset():
        pass
    if not salidas:
        return ()
    cur.execute('SELECT ' + ', '.join('@o%d' % i for i in range(salidas)))
    return cur.fetchone()


def objetos_lrg(cur):
    cur.execute("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME LIKE "
                "'fza_listas_regalos%%'", (BBDD,))
    tablas = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES "
                "WHERE ROUTINE_SCHEMA = %s AND ROUTINE_NAME LIKE "
                "'PRC_LRG_%%'", (BBDD,))
    procs = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = "
                "'VI_LRG_LINEAS_ESTADO'", (BBDD,))
    return tablas, procs, cur.fetchone()[0]


class PruebasListasRegalos(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        aplicar(TABLAS)
        aplicar(PROCS)
        cls.conexion = conectar()

    @classmethod
    def tearDownClass(cls):
        cls.conexion.close()

    def setUp(self):
        self.cur = self.conexion.cursor()

    def tearDown(self):
        self.cur.close()

    def crear_lista(self, titulares='Ana y Pedro', bonificacion=0):
        codigo, clave = llamar(self.cur, 'PRC_LRG_CREAR', [
            '1', 'T01', 'C0042', 'NACIMIENTO', '', 'Lucía', titulares,
            '2026-12-01', 'pruebas'], 2)
        self.cur.execute(
            'UPDATE fza_listas_regalos SET PORCENTAJE_BONIFICACION_LRG = %s '
            'WHERE CODIGO_LRG = %s', (bonificacion, codigo))
        return codigo, clave

    def agregar(self, lista, sku, cantidad=1, precio=10):
        return llamar(self.cur, 'PRC_LRG_LINEA_AGREGAR',
                      [lista, sku, cantidad, precio, 'pruebas'], 2)

    def regalo_caja(self, lista, linea, sku, cantidad, operacion,
                    forzar='N', importe=10):
        return llamar(self.cur, 'PRC_LRG_REGALO_CAJA', [
            lista, linea, sku, cantidad, importe, '1', 'T01', 'TPV1',
            operacion, 10, 'Abuela Carmen', 'Con cariño', forzar,
            'pruebas'], 2)

    def regalo_web(self, lista, linea, sku, cantidad, id_linea, importe=10):
        return llamar(self.cur, 'PRC_LRG_REGALO_WEB', [
            lista, linea, sku, cantidad, importe, 'tienda-1', '77',
            id_linea, 'W', '000123', 'Tía Marta', 'marta@example.com',
            'Para Lucía', 'pruebas'], 2)

    def estado_linea(self, lista, linea):
        self.cur.execute(
            'SELECT CANTIDAD_DESEADA_LRGLIN, CANTIDAD_REGALADA_LRGLIN, '
            'CANTIDAD_PENDIENTE_LRGLIN FROM VI_LRG_LINEAS_ESTADO '
            'WHERE CODIGO_LRG_LRGLIN = %s AND LINEA_LRGLIN = %s',
            (lista, linea))
        return tuple(int(v) for v in self.cur.fetchone())

    def version(self, lista):
        self.cur.execute('SELECT VERSION_LRG FROM fza_listas_regalos '
                         'WHERE CODIGO_LRG = %s', (lista,))
        return self.cur.fetchone()[0]

    def test_scripts_idempotentes_y_reversibles(self):
        aplicar(TABLAS)
        aplicar(PROCS)
        self.assertEqual(objetos_lrg(self.cur), (4, 13, 1))
        lista, _ = self.crear_lista('Lista que se pierde')
        aplicar(PROCS_RB)
        aplicar(PROCS_RB)
        aplicar(TABLAS_RB)
        aplicar(TABLAS_RB)
        self.assertEqual(objetos_lrg(self.cur), (0, 0, 0))
        self.cur.execute("SELECT COUNT(*) FROM fza_contadores "
                         "WHERE TIPO_DOC_CON = 'LR'")
        self.assertEqual(self.cur.fetchone()[0], 0)
        aplicar(TABLAS)
        aplicar(PROCS)
        aplicar(TABLAS)
        self.assertEqual(objetos_lrg(self.cur), (4, 13, 1))
        self.cur.execute("SELECT COUNT(*) FROM fza_contadores "
                         "WHERE TIPO_DOC_CON = 'LR'")
        self.assertEqual(self.cur.fetchone()[0], 1)

    def test_crear_lista_numera_y_genera_clave(self):
        uno, clave_uno = self.crear_lista()
        dos, clave_dos = self.crear_lista()
        self.assertRegex(uno, r'^\d{6}$')
        self.assertEqual(int(dos), int(uno) + 1)
        self.assertRegex(clave_uno, r'^[2-9A-HJKMNP-Z]{8}$')
        self.assertNotEqual(clave_uno, clave_dos)
        self.cur.execute('SELECT TITULO_LRG, ESTADO_LRG FROM '
                         'fza_listas_regalos WHERE CODIGO_LRG = %s', (uno,))
        self.assertEqual(self.cur.fetchone(),
                         ('Lista de Ana y Pedro', 'ABIERTA'))

    def test_crear_lista_exige_titulares(self):
        with self.assertRaises(pymysql.err.OperationalError):
            self.crear_lista(titulares='  ')

    def test_agregar_lineas(self):
        lista, _ = self.crear_lista()
        version = self.version(lista)
        self.assertEqual(self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 2),
                         (10, 1))
        self.assertEqual(self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 1),
                         (10, 2))
        self.assertEqual(self.estado_linea(lista, 10), (3, 0, 3))
        self.assertEqual(self.agregar(lista, 'CUNA-NUBE'), (20, 1))
        self.assertEqual(self.version(lista), version + 3)
        self.cur.execute('SELECT DESCRIPCION_LRGLIN FROM '
                         'fza_listas_regalos_lineas WHERE CODIGO_LRG_LRGLIN '
                         '= %s ORDER BY LINEA_LRGLIN', (lista,))
        self.assertEqual([f[0] for f in self.cur.fetchall()],
                         ['Body de algodón (BLANCO/0-3M)', 'Cuna Nube'])
        self.assertEqual(self.agregar(lista, 'NO-EXISTE'), (None, -3))
        self.assertEqual(self.agregar(lista, 'BODY-ALG/ROSA/0-3M'),
                         (None, -3))
        self.assertEqual(self.agregar(lista, 'MANTA-OLD'), (None, -3))
        self.assertEqual(self.agregar(lista, 'CUNA-NUBE', 0), (None, -4))
        self.assertEqual(self.agregar('999999', 'CUNA-NUBE'), (None, -1))

    def test_regalo_caja_respeta_pendiente_y_es_idempotente(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 2)
        id_uno, res = self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M', 1,
                                       'OP1')
        self.assertEqual(res, 1)
        self.assertEqual(self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M',
                                          1, 'OP1'), (id_uno, 3))
        self.assertEqual(self.estado_linea(lista, 10), (2, 1, 1))
        self.assertEqual(self.regalo_caja(
            lista, 10, 'BODY-ALG/BLANCO/0-3M', 2, 'OP2'), (None, -5))
        _, res = self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M', 2,
                                  'OP2', forzar='S')
        self.assertEqual(res, 2)
        self.assertEqual(self.estado_linea(lista, 10), (2, 3, 0))
        self.cur.execute("SELECT ESEXCEDENTE_LRGREG FROM "
                         "fza_listas_regalos_regalos WHERE "
                         "CODIGO_LRG_LRGREG = %s ORDER BY ID_LRGREG",
                         (lista,))
        self.assertEqual([f[0] for f in self.cur.fetchall()], ['N', 'S'])
        self.assertEqual(self.regalo_caja(lista, 99, 'CUNA-NUBE', 1, 'OP3'),
                         (None, -2))
        self.assertEqual(self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M',
                                          0, 'OP4'), (None, -4))

    def test_otra_variante_solo_si_la_linea_lo_admite(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 2)
        self.assertEqual(self.regalo_caja(
            lista, 10, 'BODY-ALG/BLANCO/3-6M', 1, 'OPV1'), (None, -3))
        self.assertEqual(self.regalo_caja(lista, 10, 'NO-EXISTE', 1,
                                          'OPV2'), (None, -3))
        self.cur.execute("UPDATE fza_listas_regalos_lineas SET "
                         "ESADMITE_OTRA_VARIANTE_LRGLIN = 'S' WHERE "
                         "CODIGO_LRG_LRGLIN = %s", (lista,))
        self.assertEqual(self.regalo_caja(
            lista, 10, 'BODY-ALG/BLANCO/3-6M', 1, 'OPV3')[1], 1)
        self.assertEqual(self.regalo_caja(lista, 10, 'CUNA-NUBE', 1,
                                          'OPV4'), (None, -3))
        self.assertEqual(self.estado_linea(lista, 10), (2, 1, 1))

    def test_regalo_web_acepta_excedente_y_es_idempotente(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'CUNA-NUBE', 1)
        id_web, res = self.regalo_web(lista, 10, 'CUNA-NUBE', 1, '501', 300)
        self.assertEqual(res, 1)
        self.assertEqual(self.regalo_web(lista, 10, 'CUNA-NUBE', 1, '501'),
                         (id_web, 3))
        self.assertEqual(self.regalo_web(lista, 10, 'CUNA-NUBE', 1,
                                         '502')[1], 2)
        self.assertEqual(self.estado_linea(lista, 10), (1, 2, 0))
        self.cur.execute("SELECT CANAL_LRGREG, NUMERO_PED_LRGREG, "
                         "EMAIL_REGALANTE_LRGREG FROM "
                         "fza_listas_regalos_regalos WHERE ID_LRGREG = %s",
                         (id_web,))
        self.assertEqual(self.cur.fetchone(),
                         ('WEB', '000123', 'marta@example.com'))

    def test_cambiar_cantidad_de_linea(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 3)
        self.agregar(lista, 'CUNA-NUBE', 1)
        self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M', 2, 'OPC1')
        cambiar = lambda linea, cant: llamar(  # noqa: E731
            self.cur, 'PRC_LRG_LINEA_CANTIDAD',
            [lista, linea, cant, 'pruebas'], 1)[0]
        self.assertEqual(cambiar(10, 1), -5)
        self.assertEqual(cambiar(10, 0), -5)
        self.assertEqual(cambiar(10, 2), 1)
        self.assertEqual(self.estado_linea(lista, 10), (2, 2, 0))
        self.assertEqual(cambiar(20, -1), -4)
        self.assertEqual(cambiar(20, 0), 1)
        self.cur.execute('SELECT COUNT(*) FROM fza_listas_regalos_lineas '
                         'WHERE CODIGO_LRG_LRGLIN = %s AND LINEA_LRGLIN = 20',
                         (lista,))
        self.assertEqual(self.cur.fetchone()[0], 0)
        self.assertEqual(cambiar(20, 1), -2)

    def test_linea_con_regalos_anulados_se_desactiva(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'CUNA-NUBE', 1)
        id_regalo, _ = self.regalo_caja(lista, 10, 'CUNA-NUBE', 1, 'OPD1')
        llamar(self.cur, 'PRC_LRG_REGALO_ANULAR',
               [id_regalo, 'Devuelta', 'pruebas'], 1)
        self.assertEqual(llamar(self.cur, 'PRC_LRG_LINEA_CANTIDAD',
                                [lista, 10, 0, 'pruebas'], 1)[0], 1)
        self.cur.execute('SELECT ESACTIVO_LRGLIN FROM '
                         'fza_listas_regalos_lineas WHERE '
                         'CODIGO_LRG_LRGLIN = %s', (lista,))
        self.assertEqual(self.cur.fetchone()[0], 'N')
        self.assertEqual(self.regalo_caja(lista, 10, 'CUNA-NUBE', 1,
                                          'OPD2'), (None, -2))
        self.assertEqual(self.agregar(lista, 'CUNA-NUBE'), (20, 1))

    def test_anular_y_entregar_regalo(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'CUNA-NUBE', 1)
        id_regalo, _ = self.regalo_caja(lista, 10, 'CUNA-NUBE', 1, 'OPA1')
        anular = lambda: llamar(  # noqa: E731
            self.cur, 'PRC_LRG_REGALO_ANULAR',
            [id_regalo, 'Devolución', 'pruebas'], 1)[0]
        self.assertEqual(anular(), 1)
        self.assertEqual(anular(), 0)
        self.assertEqual(self.estado_linea(lista, 10), (1, 0, 1))
        self.assertEqual(llamar(self.cur, 'PRC_LRG_REGALO_ANULAR',
                                [987654, '', 'pruebas'], 1)[0], -2)
        id_dos, _ = self.regalo_caja(lista, 10, 'CUNA-NUBE', 1, 'OPA2')
        entregar = lambda i: llamar(  # noqa: E731
            self.cur, 'PRC_LRG_REGALO_ENTREGAR', [i, 'pruebas'], 1)[0]
        self.assertEqual(entregar(id_dos), 1)
        self.assertEqual(entregar(id_dos), 0)
        self.assertEqual(entregar(id_regalo), 0)

    def test_cerrar_fija_totales_y_bloquea_cambios(self):
        lista, _ = self.crear_lista(bonificacion=7.5)
        self.agregar(lista, 'BODY-ALG/BLANCO/0-3M', 3)
        self.regalo_caja(lista, 10, 'BODY-ALG/BLANCO/0-3M', 1, 'OPZ1',
                         importe=12.35)
        id_anulado, _ = self.regalo_caja(
            lista, 10, 'BODY-ALG/BLANCO/0-3M', 1, 'OPZ2', importe=50)
        llamar(self.cur, 'PRC_LRG_REGALO_ANULAR',
               [id_anulado, '', 'pruebas'], 1)
        id_web, _ = self.regalo_web(lista, 10, 'BODY-ALG/BLANCO/0-3M', 1,
                                    '901', importe=20)
        total, bonificacion, res = llamar(
            self.cur, 'PRC_LRG_CERRAR', [lista, 'pruebas'], 3)
        self.assertEqual(res, 1)
        self.assertEqual(float(total), 32.35)
        self.assertEqual(float(bonificacion), 2.43)
        self.assertEqual(llamar(self.cur, 'PRC_LRG_CERRAR',
                                [lista, 'pruebas'], 3)[2], -1)
        self.assertEqual(self.regalo_caja(
            lista, 10, 'BODY-ALG/BLANCO/0-3M', 1, 'OPZ3'), (None, -1))
        self.assertEqual(self.regalo_web(
            lista, 10, 'BODY-ALG/BLANCO/0-3M', 1, '902'), (None, -1))
        self.assertEqual(llamar(self.cur, 'PRC_LRG_REGALO_ANULAR',
                                [id_web, '', 'pruebas'], 1)[0], -6)
        self.assertEqual(self.agregar(lista, 'CUNA-NUBE'), (None, -1))

    def test_anular_lista_solo_sin_regalos(self):
        con_regalo, _ = self.crear_lista()
        self.agregar(con_regalo, 'CUNA-NUBE', 1)
        self.regalo_caja(con_regalo, 10, 'CUNA-NUBE', 1, 'OPN1')
        self.assertEqual(llamar(self.cur, 'PRC_LRG_ANULAR',
                                [con_regalo, 'pruebas'], 1)[0], -6)
        vacia, _ = self.crear_lista()
        self.assertEqual(llamar(self.cur, 'PRC_LRG_ANULAR',
                                [vacia, 'pruebas'], 1)[0], 1)
        self.assertEqual(llamar(self.cur, 'PRC_LRG_ANULAR',
                                [vacia, 'pruebas'], 1)[0], -6)

    def test_buscar(self):
        lista, clave = self.crear_lista('Familia Zubizarreta')
        buscar = lambda texto: [  # noqa: E731
            f[0] for f in self.consulta('PRC_LRG_BUSCAR', ['1', texto])]
        self.assertIn(lista, buscar('zubizarreta'))
        self.assertIn(lista, buscar(clave.lower()))
        self.assertIn(lista, buscar(lista))
        self.assertIn(lista, buscar('Pérez'))
        self.assertNotIn(lista, buscar('Inexistente'))
        self.assertEqual(self.consulta('PRC_LRG_BUSCAR',
                                       ['2', 'zubizarreta']), [])
        llamar(self.cur, 'PRC_LRG_ANULAR', [lista, 'pruebas'], 1)
        self.assertNotIn(lista, buscar('zubizarreta'))

    def consulta(self, proc, entrada):
        self.cur.execute('CALL %s(%s)' % (proc, ', '.join(['%s'] *
                                                          len(entrada))),
                         entrada)
        filas = list(self.cur.fetchall())
        while self.cur.nextset():
            pass
        return filas

    def test_publicaciones_pendientes(self):
        self.cur.execute("UPDATE fza_listas_regalos SET ESPUBLICA_WEB_LRG "
                         "= 'N' WHERE CODIGO_EMP_LRG = '1'")
        lista, _ = self.crear_lista()
        oculta, _ = self.crear_lista()
        self.cur.execute("UPDATE fza_listas_regalos SET ESPUBLICA_WEB_LRG "
                         "= 'N' WHERE CODIGO_LRG = %s", (oculta,))
        pendientes = lambda: {  # noqa: E731
            f[0]: (f[1], f[3]) for f in self.consulta(
                'PRC_LRG_PUBLICACIONES_PENDIENTES', ['1', 'tienda-1'])}
        self.assertEqual(pendientes(), {lista: (self.version(lista), 'S')})
        confirmar = lambda v: llamar(  # noqa: E731
            self.cur, 'PRC_LRG_PUBLICACION_CONFIRMAR',
            [lista, 'tienda-1', v, 'pruebas'], 0)
        confirmar(self.version(lista))
        self.assertEqual(pendientes(), {})
        self.agregar(lista, 'CUNA-NUBE', 1)
        self.assertIn(lista, pendientes())
        version = self.version(lista)
        confirmar(version)
        confirmar(version - 1)
        self.assertEqual(pendientes(), {})
        self.assertEqual(self.consulta(
            'PRC_LRG_PUBLICACIONES_PENDIENTES', ['1', 'tienda-2'])[0][0],
            lista)
        llamar(self.cur, 'PRC_LRG_CERRAR', [lista, 'pruebas'], 3)
        self.assertEqual(pendientes()[lista][1], 'N')

    def test_regalo_bloquea_la_linea_frente_a_otra_caja(self):
        lista, _ = self.crear_lista()
        self.agregar(lista, 'CUNA-NUBE', 1)
        otra = conectar()
        try:
            with otra.cursor() as cur_otra:
                cur_otra.execute('START TRANSACTION')
                llamar(cur_otra, 'PRC_LRG_REGALO_CAJA', [
                    lista, 10, 'CUNA-NUBE', 1, 300, '1', 'T01', 'TPV2',
                    'OPL1', 10, '', '', 'N', 'pruebas'], 2)
                with self.assertRaises(pymysql.err.OperationalError) as ctx:
                    self.regalo_caja(lista, 10, 'CUNA-NUBE', 1, 'OPL2')
                self.assertEqual(ctx.exception.args[0], 1205)
                cur_otra.execute('COMMIT')
        finally:
            otra.close()
        self.assertEqual(self.regalo_caja(lista, 10, 'CUNA-NUBE', 1,
                                          'OPL3'), (None, -5))


if __name__ == '__main__':
    unittest.main()

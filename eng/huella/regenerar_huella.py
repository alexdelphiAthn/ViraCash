"""Mantiene al día la huella del esquema que ViraCash lleva embebida.

HuellaEsquema.json/.res (comprobación de integridad al arrancar) tiene que
incluir todo script de esquema de DESARROLLOS EN CURSO; si no, la aplicación
rechaza las bases que ya lo tienen aplicado. Lo llama eng\\compilar.ps1
antes de compilar.

Funcionamiento:
- Candidatos: scripts AAAAMMDD_*.sql de la carpeta oficial, sin _rollback,
  que crean o cambian tablas, columnas, índices, vistas o rutinas (fuera de
  bak_/tmp_, que la huella ignora).
- Si todos están ya en la huella, solo comprueba que el .res corresponde
  al JSON (y lo rehace si no).
- Si hay pendientes, GeneradorEsquemaIdeal genera dos huellas sobre
  modelo_referencia.sql: «control» (modelo + scripts integrados después del
  modelo) y «nuevo» (control + pendientes). La diferencia entre las dos se
  aplica a la huella actual. Así no influyen las pequeñas diferencias del
  modelo con el que se generó la huella original.

Uso: python regenerar_huella.py [--comprobar | --solo-recurso]
       [--carpeta <dir>] [--json <HuellaEsquema.json>]
       [--res <HuellaEsquema.res>]
--comprobar: no escribe nada; sale con 3 si faltan scripts en la huella.
--solo-recurso: rehace HuellaEsquema.res desde el JSON si no coinciden y,
  si faltan scripts, solo avisa (no los integra ni detiene la compilación:
  quien desarrolla un script puede compilar con -SinHuella). Lo ejecuta el
  evento previo a la compilación de vcash.dproj (IDE, MSBuild o
  eng\\compilar.ps1): HuellaEsquema.res no se versiona (.gitignore) y un
  .res viejo junto a un JSON nuevo dejaba el ejecutable con la huella
  anterior (FZ-ISSUE-1066).
Salida 0 correcta, 1 error, 3 huella desfasada (solo con --comprobar).
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from datetime import datetime

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..'))
CARPETA_OFICIAL = r'C:\DISCO_DURO\proyectos\ViraCash_web\DESARROLLOS EN CURSO'
MODELO = os.path.join(AQUI, 'modelo_referencia.sql')
SCRIPTS_EN_MODELO = os.path.join(AQUI, 'modelo_referencia_scripts.txt')
GENERADOR = os.path.join(RAIZ, 'src', 'utlEsquemaIdeal', 'bin', 'Win64',
                         'Release', 'GeneradorEsquemaIdeal.exe')
MARIADB10_MSI = r'C:\DISCO_DURO\proyectos\ViraCash_web\empaquetador' \
                r'\mariadb-10.4.12-winx64.msi'
MYSQL8 = r'C:\DISCO_DURO\proyectos\ViraCash_web\build\mysql841_local' \
         r'\mysql-8.0.41-winx64\bin'
NOMBRE_RECURSO = 'HUELLA_ESQUEMA'
APARTADOS_GLOBAL = ['ESTRUCTURA', 'VISTAS', 'RUTINAS', 'DEFINIDORES']

PATRON_FECHA = re.compile(r'^\d{8}_.*\.sql$', re.IGNORECASE)
# FZ-ISSUE-1048: también vistas con ALGORITHM=... y SQL SECURITY ... (p. ej.
# las que se crean con PREPARE desde una cadena).
PATRON_DDL = re.compile(
    r'\b(?:CREATE\s+(?:OR\s+REPLACE\s+)?(?:ALGORITHM\s*=\s*\w+\s+)?'
    r'(?:DEFINER\s*=\s*\S+\s+)?(?:SQL\s+SECURITY\s+\w+\s+)?'
    r'(?:TABLE|PROCEDURE|FUNCTION|VIEW|TRIGGER)'
    r'(?:\s+IF\s+NOT\s+EXISTS)?|ALTER\s+TABLE|DROP\s+(?:TABLE|PROCEDURE|'
    r'FUNCTION|VIEW|TRIGGER)(?:\s+IF\s+EXISTS)?)\s+[`\'"]?'
    r'([A-Za-z0-9_]+)', re.IGNORECASE)
# En los índices cuenta la tabla («ON tabla»), no el nombre del índice.
PATRON_INDICE = re.compile(
    r'\b(?:CREATE\s+(?:UNIQUE\s+)?INDEX|DROP\s+INDEX)\s+(?:IF\s+(?:NOT\s+)?'
    r'EXISTS\s+)?[`\'"]?[A-Za-z0-9_]+[`\'"]?\s+ON\s+[`\'"]?([A-Za-z0-9_]+)',
    re.IGNORECASE)
PREFIJOS_IGNORADOS = ('bak_', 'tmp_', 'fzu_')


def error(texto):
    print('Huella del esquema: ' + texto)
    sys.exit(1)


def canonico(elementos):
    return '{' + ','.join(
        json.dumps(k, ensure_ascii=False) + ':' +
        json.dumps(elementos[k], ensure_ascii=False)
        for k in sorted(elementos)) + '}'


def sha256(texto):
    return hashlib.sha256(texto.encode('utf-8')).hexdigest()


def sha256_fichero(ruta):
    return hashlib.sha256(open(ruta, 'rb').read()).hexdigest()


def recalcular(huella):
    """Recalcula las huellas a partir de los elementos (como
    inLibHuellaEsquema.CalcularHuellas)."""
    for apartado, elementos in huella['elementos'].items():
        huella['huellas'][apartado] = sha256(canonico(elementos))
    huella['huellas']['GLOBAL'] = sha256(''.join(
        huella['huellas'][a] for a in APARTADOS_GLOBAL))
    for codigo in huella['codigo'].values():
        codigo['huella'] = sha256(canonico(codigo['elementos']))


def coherente(huella):
    copia = json.loads(json.dumps(huella))
    recalcular(copia)
    return (copia['huellas'] == huella['huellas'] and
            all(copia['codigo'][m]['huella'] == huella['codigo'][m]['huella']
                for m in huella['codigo']))


def alinear(datos):
    return datos + b'\0' * ((4 - len(datos) % 4) % 4)


def recurso(datos):
    vacia = struct.pack('<IIHHHHIHHII', 0, 32, 0xFFFF, 0, 0xFFFF, 0,
                        0, 0, 0, 0, 0)
    tipo = struct.pack('<HH', 0xFFFF, 10)  # RT_RCDATA
    nombre = alinear((NOMBRE_RECURSO + '\0').encode('utf-16-le'))
    cola = struct.pack('<IHHII', 0, 0x0030, 0x0C0A, 0, 0)
    cabecera = tipo + nombre + cola
    entrada = struct.pack('<II', len(datos), 8 + len(cabecera)) + cabecera
    return vacia + entrada + alinear(datos)


def es_script_esquema(ruta):
    texto = open(ruta, encoding='utf-8-sig', errors='replace').read()
    texto = re.sub(r'--[^\n]*', '', texto)
    for patron in (PATRON_DDL, PATRON_INDICE):
        for coincidencia in patron.finditer(texto):
            if not coincidencia.group(1).lower().startswith(
                    PREFIJOS_IGNORADOS):
                return True
    return False


def candidatos(carpeta):
    resultado = []
    for nombre in sorted(os.listdir(carpeta)):
        ruta = os.path.join(carpeta, nombre)
        if (PATRON_FECHA.match(nombre) and '_rollback' not in nombre.lower()
                and os.path.isfile(ruta) and es_script_esquema(ruta)):
            resultado.append(nombre)
    return resultado


def generar(destino, scripts, carpeta, temporal):
    salida = os.path.join(temporal, destino + '.json')
    orden = [GENERADOR, salida, '--res', os.path.join(temporal, destino +
             '.res'), '--modelo', MODELO, '--mariadb10-msi', MARIADB10_MSI,
             '--mysql8', MYSQL8]
    if scripts:
        orden += ['--scripts'] + [os.path.join(carpeta, s) for s in scripts]
    print('Huella del esquema: generando «%s» (%d scripts)...' %
          (destino, len(scripts)))
    proceso = subprocess.run(orden, capture_output=True, text=True,
                             encoding='utf-8', errors='replace')
    if proceso.returncode != 0:
        print(proceso.stdout[-3000:])
        error('GeneradorEsquemaIdeal ha fallado (%d).' % proceso.returncode)
    return json.load(open(salida, encoding='utf-8'))


def aplicar_diferencia(base, control, nuevo):
    cambios = []

    def mezclar(destino, antes, despues, etiqueta):
        for clave in sorted(set(antes) | set(despues)):
            if antes.get(clave) != despues.get(clave):
                if clave in despues:
                    destino[clave] = despues[clave]
                else:
                    destino.pop(clave, None)
                cambios.append(etiqueta + ' ' + clave)

    for apartado in nuevo['elementos']:
        mezclar(base['elementos'].setdefault(apartado, {}),
                control['elementos'].get(apartado, {}),
                nuevo['elementos'][apartado], apartado)
    for motor in nuevo['codigo']:
        mezclar(base['codigo'][motor]['elementos'],
                control['codigo'][motor]['elementos'],
                nuevo['codigo'][motor]['elementos'], motor)
    return cambios


def escribir(huella, ruta_json, ruta_res):
    datos = json.dumps(huella, ensure_ascii=False,
                       separators=(',', ':')).encode('utf-8')
    open(ruta_json, 'wb').write(datos)
    open(ruta_res, 'wb').write(recurso(datos))


def main():
    argumentos = argparse.ArgumentParser()
    modos = argumentos.add_mutually_exclusive_group()
    modos.add_argument('--comprobar', action='store_true')
    modos.add_argument('--solo-recurso', action='store_true')
    argumentos.add_argument('--carpeta', default=CARPETA_OFICIAL)
    argumentos.add_argument('--json',
                            default=os.path.join(RAIZ, 'HuellaEsquema.json'))
    argumentos.add_argument('--res',
                            default=os.path.join(RAIZ, 'HuellaEsquema.res'))
    opciones = argumentos.parse_args()

    if not os.path.isdir(opciones.carpeta):
        error('no existe la carpeta de scripts ' + opciones.carpeta)
    base = json.load(open(opciones.json, encoding='utf-8'))
    if not coherente(base):
        error(opciones.json + ' no es coherente (huellas y elementos no '
              'coinciden): no se toca.')
    incluidos = dict(zip(base['scripts'], base['sha256_scripts']))
    if not os.path.isfile(SCRIPTS_EN_MODELO):
        error('falta ' + SCRIPTS_EN_MODELO)
    # Línea base: lo que ya refleja el modelo de referencia (incluidos los
    # scripts anteriores a la huella del 16/11, que venían en su modelo).
    en_modelo = set(l.strip() for l in open(SCRIPTS_EN_MODELO,
                                            encoding='utf-8') if l.strip())
    lista = candidatos(opciones.carpeta)
    # Un script ya incluido que ha cambiado después (y no está en el modelo)
    # se vuelve a integrar: «control» va sin él y «nuevo» con su versión
    # actual, así que sus objetos toman la firma nueva.
    cambiados = [s for s in lista
                 if s in incluidos and s not in en_modelo and
                 incluidos[s] != sha256_fichero(
                     os.path.join(opciones.carpeta, s))]
    for nombre in cambiados:
        print('Huella del esquema: %s ha cambiado desde que se incluyó; se '
              'vuelve a integrar.' % nombre)
    pendientes = [s for s in lista
                  if (s not in incluidos and s not in en_modelo) or
                  s in cambiados]

    datos_json = open(opciones.json, 'rb').read()
    res_al_dia = (os.path.isfile(opciones.res) and
                  open(opciones.res, 'rb').read() == recurso(datos_json))
    if not res_al_dia and opciones.solo_recurso:
        open(opciones.res, 'wb').write(recurso(datos_json))
        print('Huella del esquema: HuellaEsquema.res no correspondía a '
              'HuellaEsquema.json; rehecho.')
        res_al_dia = True
    if not pendientes:
        if not res_al_dia and not opciones.comprobar:
            open(opciones.res, 'wb').write(recurso(datos_json))
            print('Huella del esquema: al día; HuellaEsquema.res rehecho.')
        else:
            print('Huella del esquema: al día (%d scripts).' %
                  len(base['scripts']))
        sys.exit(0)
    print('Huella del esquema: scripts sin incluir: ' + ', '.join(pendientes))
    if opciones.solo_recurso:
        print('AVISO: el ejecutable no aceptará las bases que ya tengan esos '
              'scripts; compila con eng\\compilar.ps1 para integrarlos.')
        sys.exit(0)
    if opciones.comprobar:
        sys.exit(3)
    for ruta in (GENERADOR, MODELO, SCRIPTS_EN_MODELO, MYSQL8, MARIADB10_MSI):
        if not os.path.exists(ruta):
            error('falta ' + ruta)

    previos = [s for s in base['scripts']
               if s not in en_modelo and s not in cambiados]
    for nombre in previos:
        if not os.path.isfile(os.path.join(opciones.carpeta, nombre)):
            error('no se encuentra %s, ya incluido en la huella y posterior '
                  'al modelo de referencia.' % nombre)
    temporal = tempfile.mkdtemp(prefix='huella_viracash_')
    try:
        control = generar('control', previos, opciones.carpeta, temporal)
        nuevo = generar('nuevo', previos + pendientes, opciones.carpeta,
                        temporal)
    finally:
        shutil.rmtree(temporal, ignore_errors=True)
    cambios = aplicar_diferencia(base, control, nuevo)
    for nombre in pendientes:
        huella_script = sha256_fichero(os.path.join(opciones.carpeta,
                                                    nombre))
        if nombre in base['scripts']:
            indice = base['scripts'].index(nombre)
            base['sha256_scripts'][indice] = huella_script
        else:
            base['scripts'].append(nombre)
            base['sha256_scripts'].append(huella_script)
    base['generado'] = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    recalcular(base)
    escribir(base, opciones.json, opciones.res)
    print('Huella del esquema: incluidos %d scripts, %d cambios:' %
          (len(pendientes), len(cambios)))
    for cambio in cambios:
        print('  ' + cambio)
    sys.exit(0)


if __name__ == '__main__':
    main()

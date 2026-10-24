#!/usr/bin/env python3
"""
Sustituye todas las fuentes del proyecto Factuzam por 'Source Sans 3' -17,
excepto componentes monoespaciados (editores SQL, incidencias, errores)
que se unifican a 'Consolas'.
"""
import os
import re
import sys

FUENTE_DESTINO = 'Source Sans 3'
ALTURA_DESTINO = -17
TAMANO_DESTINO = 13  # equivalente a Height -17 a 96 DPI
FUENTE_MONO = 'Consolas'

DIRS_EXCLUIDOS = {'3rdpartyComp', 'vcl', 'vcl37'}

RAIZ = os.path.dirname(os.path.abspath(__file__))

total_archivos = 0
total_cambios = 0


def es_excluido(ruta):
    partes = ruta.replace('\\', '/').split('/')
    for parte in partes:
        if parte in DIRS_EXCLUIDOS:
            return True
    return False


def leer_archivo(ruta):
    for enc in ['utf-8-sig', 'utf-8', 'latin-1']:
        try:
            with open(ruta, 'r', encoding=enc, newline='') as f:
                return f.readlines(), enc
        except (UnicodeDecodeError, UnicodeError):
            continue
    with open(ruta, 'r', encoding='utf-8', errors='replace', newline='') as f:
        return f.readlines(), 'utf-8'


def escribir_archivo(ruta, lineas, enc):
    if enc == 'utf-8-sig':
        enc = 'utf-8-sig'
    with open(ruta, 'w', encoding=enc, newline='') as f:
        f.writelines(lineas)


def es_font_prop(linea_strip):
    """True si la linea es una propiedad Font.* en un .dfm"""
    return bool(re.match(
        r'(Style\.)?(Gutter\.)?(Header\.Default|Footer\.Default)?Font\.\w+\s*=',
        linea_strip))


def encontrar_bloques_mono_dfm(lineas):
    """Indices de lineas Font.* que pertenecen a componentes con fuente mono."""
    indices = set()
    for i, linea in enumerate(lineas):
        s = linea.strip()
        if re.search(r"Font\.Name\s*=\s*'(Consolas|Courier New)'", s):
            indices.add(i)
            for j in range(i - 1, max(-1, i - 10), -1):
                if es_font_prop(lineas[j].strip()):
                    indices.add(j)
                else:
                    break
            for j in range(i + 1, min(len(lineas), i + 10)):
                if es_font_prop(lineas[j].strip()):
                    indices.add(j)
                else:
                    break
    return indices


def procesar_dfm(ruta):
    lineas, enc = leer_archivo(ruta)
    bloques_mono = encontrar_bloques_mono_dfm(lineas)
    cambios = 0
    for i, linea in enumerate(lineas):
        original = linea
        if i in bloques_mono:
            # Unificar Courier New -> Consolas dentro de bloques mono
            if 'Font.Name' in linea and "'Courier New'" in linea:
                linea = linea.replace("'Courier New'", f"'{FUENTE_MONO}'")
            if linea != original:
                lineas[i] = linea
                cambios += 1
            continue
        # Font.Name -> Source Sans 3
        if 'Font.Name' in linea and "= '" in linea:
            linea = re.sub(
                r"(Font\.Name\s*=\s*)'[^']+'",
                rf"\g<1>'{FUENTE_DESTINO}'",
                linea)
        # Font.Height -> -17
        if 'Font.Height' in linea and '=' in linea:
            linea = re.sub(
                r"(Font\.Height\s*=\s*)-?\d+",
                rf"\g<1>{ALTURA_DESTINO}",
                linea)
        if linea != original:
            lineas[i] = linea
            cambios += 1
    if cambios > 0:
        escribir_archivo(ruta, lineas, enc)
    return cambios


def encontrar_bloques_mono_pas(lineas):
    """Indices de lineas con asignaciones Font.* de componentes mono en .pas"""
    indices = set()
    for i, linea in enumerate(lineas):
        # Font.Name := 'Consolas' o 'Courier New'
        if re.search(r"Font\.Name\s*:=\s*'(Consolas|Courier New)'", linea):
            indices.add(i)
            for j in range(i - 1, max(-1, i - 5), -1):
                if 'Font.' in lineas[j] and ':=' in lineas[j]:
                    indices.add(j)
                else:
                    break
            for j in range(i + 1, min(len(lineas), i + 5)):
                if 'Font.' in lineas[j] and ':=' in lineas[j]:
                    indices.add(j)
                else:
                    break
        # StrPCopy(LogFont.lfFaceName, ...) - monoespaciado para tickets
        if 'lfFaceName' in linea and ("'Consolas'" in linea or "'Courier New'" in linea):
            indices.add(i)
    return indices


def procesar_pas(ruta):
    lineas, enc = leer_archivo(ruta)
    bloques_mono = encontrar_bloques_mono_pas(lineas)
    cambios = 0
    for i, linea in enumerate(lineas):
        original = linea
        if i in bloques_mono:
            # Unificar Courier New -> Consolas
            if "'Courier New'" in linea:
                linea = linea.replace("'Courier New'", f"'{FUENTE_MONO}'")
            if linea != original:
                lineas[i] = linea
                cambios += 1
            continue
        # Font.Name := '...'
        if 'Font.Name' in linea and ':=' in linea:
            linea = re.sub(
                r"(Font\.Name\s*:=\s*)'[^']+'",
                rf"\g<1>'{FUENTE_DESTINO}'",
                linea)
        # Font.Height := ...
        if 'Font.Height' in linea and ':=' in linea:
            linea = re.sub(
                r"(Font\.Height\s*:=\s*)-?\d+",
                rf"\g<1>{ALTURA_DESTINO}",
                linea)
        # Font.Size := ...
        if 'Font.Size' in linea and ':=' in linea:
            linea = re.sub(
                r"(Font\.Size\s*:=\s*)\d+",
                rf"\g<1>{TAMANO_DESTINO}",
                linea)
        if linea != original:
            lineas[i] = linea
            cambios += 1
    if cambios > 0:
        escribir_archivo(ruta, lineas, enc)
    return cambios


def recorrer(directorio):
    global total_archivos, total_cambios
    for raiz, dirs, archivos in os.walk(directorio):
        # Excluir directorios
        dirs[:] = [d for d in dirs if d not in DIRS_EXCLUIDOS]
        for archivo in sorted(archivos):
            ruta = os.path.join(raiz, archivo)
            ext = os.path.splitext(archivo)[1].lower()
            cambios = 0
            if ext == '.dfm':
                cambios = procesar_dfm(ruta)
            elif ext == '.pas':
                cambios = procesar_pas(ruta)
            if cambios > 0:
                rel = os.path.relpath(ruta, RAIZ)
                print(f'  {rel} -> {cambios} cambio(s)')
                total_archivos += 1
                total_cambios += cambios


def main():
    global total_archivos, total_cambios
    print('=== Unificador de fuentes Factuzam ===')
    print(f'Fuente destino: {FUENTE_DESTINO}')
    print(f'Altura destino: {ALTURA_DESTINO}')
    print(f'Fuente mono:    {FUENTE_MONO}')
    print()
    directorio = os.path.join(RAIZ, 'src')
    print(f'Directorio: {directorio}')
    print()
    recorrer(directorio)
    # Procesar tambien fzam.dpr (fuentes globales)
    dpr = os.path.join(RAIZ, 'fzam.dpr')
    if os.path.exists(dpr):
        cambios = procesar_pas(dpr)
        if cambios > 0:
            print(f'  fzam.dpr -> {cambios} cambio(s)')
            total_archivos += 1
            total_cambios += cambios
    print()
    print('--- Resumen ---')
    print(f'Archivos modificados: {total_archivos}')
    print(f'Cambios totales:      {total_cambios}')


if __name__ == '__main__':
    main()

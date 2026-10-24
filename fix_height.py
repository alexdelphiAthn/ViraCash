#!/usr/bin/env python3
"""
Unifica Font.Height a -17 en .dfm (excepto caja, Consolas, 3rdparty).
"""
import os
import re

ALTURA_DESTINO = -17
DIRS_EXCLUIDOS = {'3rdpartyComp', 'vcl', 'vcl37'}
RAIZ = os.path.dirname(os.path.abspath(__file__))
total_archivos = 0
total_cambios = 0


def leer_archivo(ruta):
    for enc in ['utf-8-sig', 'utf-8', 'latin-1']:
        try:
            with open(ruta, 'r', encoding=enc, newline='') as f:
                return f.readlines(), enc
        except (UnicodeDecodeError, UnicodeError):
            continue
    with open(ruta, 'r', encoding='utf-8', errors='replace', newline='') as f:
        return f.readlines(), 'utf-8'


def es_font_prop(linea_strip):
    return bool(re.match(
        r'(Style\.)?(Gutter\.)?(Header\.Default|Footer\.Default)?'
        r'(Category|Name|Value|HideSelect|Selected)?Font\.\w+\s*=',
        linea_strip))


def encontrar_bloques_mono(lineas):
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
    bloques_mono = encontrar_bloques_mono(lineas)
    cambios = 0
    for i, linea in enumerate(lineas):
        if i in bloques_mono:
            continue
        original = linea
        if 'Font.Height' in linea and '=' in linea:
            linea = re.sub(
                r'(Font\.Height\s*=\s*)-?\d+',
                rf'\g<1>{ALTURA_DESTINO}',
                linea)
        if linea != original:
            lineas[i] = linea
            cambios += 1
    if cambios > 0:
        with open(ruta, 'w', encoding=enc, newline='') as f:
            f.writelines(lineas)
    return cambios


def recorrer(directorio):
    global total_archivos, total_cambios
    for raiz, dirs, archivos in os.walk(directorio):
        dirs[:] = [d for d in dirs if d not in DIRS_EXCLUIDOS]
        # Excluir carpetas de caja
        partes = raiz.replace('\\', '/').split('/')
        for archivo in sorted(archivos):
            if not archivo.lower().endswith('.dfm'):
                continue
            if 'caja' in archivo.lower():
                continue
            ruta = os.path.join(raiz, archivo)
            cambios = procesar_dfm(ruta)
            if cambios > 0:
                rel = os.path.relpath(ruta, RAIZ)
                print(f'  {rel} -> {cambios} cambio(s)')
                total_archivos += 1
                total_cambios += cambios


def main():
    global total_archivos, total_cambios
    print('=== Unificar Font.Height a -17 ===')
    print()
    recorrer(os.path.join(RAIZ, 'src'))
    print()
    print(f'Archivos modificados: {total_archivos}')
    print(f'Cambios totales:      {total_cambios}')


if __name__ == '__main__':
    main()

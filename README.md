# ViraCash

Aplicación de gestión comercial y punto de venta para Windows, desarrollada
con Delphi/VCL. Este proyecto parte de la copia de Factuzam del 24 de octubre
de 2026.

## Abrir y compilar

Abrir `vcash.dproj` en RAD Studio 13. El ejecutable es `vcash.exe`.
Las configuraciones del IDE generan `Win64/Release/vcash.exe` y
`Win64/Debug/vcash.exe`, respectivamente.

Para compilar por consola:

```powershell
.\eng\compilar.ps1 -Configuracion Release -Plataforma Win64
```

El script deja el ejecutable en
`build/reproducible/bin/Win64/Release/vcash.exe`.
Las dependencias se declaran en `eng/ViraCash.Dependencias.props` mediante
variables `VIRACASH_*_ROOT`. También se admiten las variables
`FACTUZAM_*_ROOT` existentes. Se requieren Delphi, DevExpress VCL, UniDAC,
FastReport y las bibliotecas utilizadas por el proyecto.

## Imagen de marca

- Símbolo: V blanca con rayo lima sobre verde esmeralda.
- Icono de aplicación: `vcash.ico`; vector editable: `viracash.svg`.
- Fondos: `fondo_viracash.png` y `fondo_viracash_oscuro.png`.
- Cartel lateral de cobro: `cartel_cobro_viracash.png`.

Los fondos se incluyen en `fondo.res` a partir de `fondo.rc`. El cartel
queda integrado en el DFM de la fase de cobro. Los SVG correspondientes
permiten editar y volver a exportar los diseños.

## Compatibilidad

El cambio de marca conserva los identificadores de bases de datos,
tablas, formatos de copias, credenciales y servicios existentes. Al iniciar
ViraCash se importan los perfiles INI de la carpeta local de Factuzam que
no existan en la carpeta nueva. La configuración original se conserva.

Los ejecutables, credenciales locales y artefactos de compilación no se
versionan. Las aplicaciones auxiliares tienen sus propios proyectos.

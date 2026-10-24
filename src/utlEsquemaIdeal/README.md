# Generador del esquema ideal

`GeneradorEsquemaIdeal.exe` prepara el esquema ideal que ViraCash lleva
embebido para *Ayuda > Comprobar integridad* (recurso RCDATA
`HUELLA_ESQUEMA` en `ViraCash\HuellaEsquema.res`, enlazado por
`src\Lib\inLibHuellaEsquemaRecurso.pas`).

## Qué hace

1. Levanta un MariaDB 12, un MariaDB 10 y un MySQL 8 de usar y tirar en
   `%TEMP%`, en puertos libres de 127.0.0.1.
2. Carga en cada uno el modelo (`factuzam_original.sql`) y los scripts que se
   le indiquen; para MariaDB 10 y MySQL 8 los convierte antes con
   `DBComparer.exe --convertir`, como el actualizador.
3. Lee el catálogo con `UniDataHuellaEsquema`, el mismo lector que usa
   ViraCash al comprobar, y exige que la parte común dé la misma huella en
   los tres motores. El código de los procedimientos se guarda por motor.
4. Escribe el JSON y el `.res` (sin `brcc32`).

Los servidores se paran y su carpeta se borra al terminar; si algo falla,
la carpeta se queda y la ruta sale en la salida.

## Uso

```
GeneradorEsquemaIdeal <salida.json> --modelo <modelo.sql>
  [--res <HuellaEsquema.res>] [--scripts <a.sql> <b.sql> ...]
  [--comparador <DBComparer.exe>] [--mariadb12 <bin>] [--mariadb10 <bin>]
  [--mariadb10-msi <msi>] [--mysql8 <bin>] [--si-cambia | --comprobar]
```

- Sin modo, regenera siempre (unos 30 s).
- `--si-cambia`: solo regenera si el JSON no es de este modelo, de estos
  scripts y de esta versión de la huella; si solo falta el `.res`, lo
  recompila. Lo usa el Publicador al compilar.
- `--comprobar`: no genera nada; sale con 0 si está al día y con 3 si no. Lo
  usa el Publicador antes de preparar el paquete.
- Salida 1: error.

Rutas por defecto: MariaDB 12 en `C:\Program Files\MariaDB 12.3\bin`, MySQL
8.0.41 en `factuzam_web\build\mysql841_local`, y MariaDB 10 desempaquetando
(`msiexec /a`, sin instalar) `factuzam_web\empaquetador\mariadb-10.4.12-
winx64.msi`.

## Compilar

`compilar.cmd` (dcc64 de RAD Studio 37 con UniDAC) deja el ejecutable en
`bin\Win64\Release`, que es donde lo busca el Publicador
(`[EsquemaIdeal] Generador`).

# Visor web de ayuda

El foro y el manual se muestran mediante `Vcl.Edge.TEdgeBrowser`, incluido
en Delphi, para admitir el HTML, CSS y JavaScript del manual actual dentro
de Factuzam. La ventana ofrece Atrás, Adelante, Recargar y Salir.

## Distribución

El equipo cliente necesita Microsoft Edge WebView2 Runtime. Es un motor
integrado: no abre el navegador de escritorio ni depende de permitir su
ejecución a los empleados. Las políticas del equipo deben permitir WebView2.

`WebView2Loader.dll` viaja dentro de `fzam.exe` como recurso RCDATA
(`WebView2Loader_x86.res` / `WebView2Loader_x64.res`, enlazados por
`inLibWebView2Loader` según la plataforma). Al abrir la ayuda web se escribe
en `%TEMP%\Factuzam\WebView2\<arquitectura>\<16 primeros del SHA-256>\` y se
carga con ruta completa tras comprobar su SHA-256 con la DLL abierta sin
permitir escrituras. Si falta (limpieza de temporales) se vuelve a escribir.
Si no se puede, `Vcl.Edge` busca la DLL junto al ejecutable.

Al actualizar la DLL hay que regenerar los `.res` desde esta carpeta y cambiar
los hashes de `inLibWebView2Loader.pas`; un `.res` que no coincide no se usa:

```
brcc32 -foWebView2Loader_x86.res WebView2Loader_x86.rc
brcc32 -foWebView2Loader_x64.res WebView2Loader_x64.rc
```

`fzam.dproj` copia solo la licencia junto a `fzam.exe`, y el instalador demo
la incluye. El runtime se administra por separado en el equipo cliente.

El perfil se guarda en la carpeta local del usuario que gestiona `TEdgeBrowser`,
separado del navegador de escritorio. «Ventana interna» no implica modo
incógnito: las cookies del foro pueden conservarse entre aperturas.

## Procedencia verificable

- Paquete oficial: Microsoft.Web.WebView2 **1.0.3650.58**.
- Descarga: https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/1.0.3650.58
- Archivos originales: `build/native/x86/WebView2Loader.dll`,
  `build/native/x64/WebView2Loader.dll` y `LICENSE.txt`.
- Ambas DLL tienen firma Authenticode válida de Microsoft Corporation.
- SHA-256 x86:
  `44AB92C2246EBFB5F98AA5726626FB44BEB61543F2EF1803338AF9FD295E63F0`.
- SHA-256 x64:
  `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`.

Documentación de distribución:
https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution

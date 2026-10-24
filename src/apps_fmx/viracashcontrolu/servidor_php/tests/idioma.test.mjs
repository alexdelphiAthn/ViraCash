// Pruebas del idioma de Control U web (FZ-ISSUE-613).
// Uso: node --test src/apps_fmx/fzamcontrolu/servidor_php/tests/idioma.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const publico = new URL("../publico/", import.meta.url);
const privado = new URL("../privado/", import.meta.url);
const idioma = await import(new URL("controlu-idioma.js", publico));
const { resolverIdioma, IDIOMAS, IDIOMA, LOCALE, CLAVES, ERRORES, IDIOMAS_TRADUCIDOS,
  tieneClave, traduccionesDe, traducir, mensajeError, t } = idioma;
const leer = (nombre, carpeta = publico) => readFileSync(new URL(nombre, carpeta), "utf8");
const modulos = readdirSync(publico).filter((nombre) => /^controlu.*\.js$/u.test(nombre));

test("Español, inglés, catalán o chino; cualquier otro idioma, inglés", () => {
  assert.deepEqual(IDIOMAS, { es: "es-ES", ca: "ca-ES", en: "en-GB", zh: "zh-CN" });
  assert.equal(resolverIdioma(["es-MX"]), "es");
  assert.equal(resolverIdioma(["ca"]), "ca");
  assert.equal(resolverIdioma(["en-US"]), "en");
  assert.equal(resolverIdioma(["zh-TW"]), "zh");
  assert.equal(resolverIdioma(["zh_Hans_CN"]), "zh");
  assert.equal(resolverIdioma(["fr-FR"]), "en");
  assert.equal(resolverIdioma(["fr-FR", "ca-ES", "es-ES"]), "ca");
  assert.equal(resolverIdioma(["de", "pt"]), "en");
  assert.equal(resolverIdioma([]), "en");
  assert.equal(resolverIdioma([undefined, ""]), "en");
});

test("Sin página (Node) se conserva el español y su formato", () => {
  assert.equal(IDIOMA, "es");
  assert.equal(LOCALE, "es-ES");
  assert.equal(t("Stock"), "Stock");
  assert.equal(t("Consultando {codigo}…", { codigo: "A1" }), "Consultando A1…");
});

test("En el navegador manda navigator.languages y luego navigator.language", async () => {
  const anterior = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  globalThis.document = { documentElement: { lang: "es" } };
  try {
    const probar = async (navegador, consulta) => {
      Object.defineProperty(globalThis, "navigator",
        { value: navegador, configurable: true });
      return import(new URL("controlu-idioma.js?prueba=" + consulta, publico));
    };
    const zh = await probar({ languages: ["zh-HK", "en"], language: "zh-HK" }, "zh");
    assert.equal(zh.IDIOMA, "zh");
    assert.equal(zh.LOCALE, "zh-CN");
    assert.equal(zh.t("Stock"), "库存");
    const ca = await probar({ languages: [], language: "ca-ES" }, "ca");
    assert.equal(ca.LOCALE, "ca-ES");
    assert.equal(ca.t("Almacenes"), "Magatzems");
    const otro = await probar({ languages: ["fr-FR", "de"], language: "fr-FR" }, "fr");
    assert.equal(otro.LOCALE, "en-GB");
    assert.equal(otro.t("Colores"), "Colours");
    assert.equal(otro.mensajeError("TOKEN_CADUCADO", "x"),
      "Your sign-in has expired. Sign in again.");
  } finally {
    delete globalThis.document;
    if (anterior) Object.defineProperty(globalThis, "navigator", anterior);
    else delete globalThis.navigator;
  }
});

test("Cada clave tiene catalán, inglés y chino con los mismos parámetros", () => {
  const marcas = (texto) => [...texto.matchAll(/\{(\w+)\}/gu)].map((m) => m[1]).sort();
  assert.ok(CLAVES.length > 100);
  for (const clave of CLAVES) {
    const traducciones = traduccionesDe(clave);
    assert.deepEqual(Object.keys(traducciones).sort(), [...IDIOMAS_TRADUCIDOS].sort(), clave);
    for (const id of IDIOMAS_TRADUCIDOS) {
      assert.ok(traducciones[id].trim(), id + ": " + clave);
      assert.deepEqual(marcas(traducciones[id]), marcas(clave), id + ": " + clave);
    }
  }
  assert.equal(traducir("en", "Actualizado a las {hora}", { hora: "10:00" }),
    "Updated at 10:00");
  assert.equal(traducir("zh", "Texto sin clave"), "Texto sin clave");
});

test("Cada clave usada con t() en los módulos existe en el diccionario", () => {
  let usadas = 0;
  for (const nombre of modulos.filter((m) => m !== "controlu-idioma.js")) {
    const fuente = leer(nombre);
    // t("...") y t(condición ? "..." : "...").
    for (const m of fuente.matchAll(/(?<![\w.$#])t\(((?:[^()"]|"(?:\\.|[^"\\])*")*?)(?:,\s*\{|\))/gu)) {
      for (const [, clave] of m[1].matchAll(/"((?:\\.|[^"\\])*)"/gu)) {
        usadas += 1;
        assert.ok(tieneClave(clave), nombre + ": falta «" + clave + "»");
      }
    }
    for (const [, version] of fuente.matchAll(/controlu-idioma\.js\?v=([\w-]+)/gu)) {
      assert.equal(version, "20261020-1", nombre + ": una única versión del diccionario");
    }
  }
  assert.ok(usadas > 60, "Se esperan muchas claves usadas: " + usadas);
});

test("Todos los textos visibles de index.html tienen traducción", () => {
  const html = leer("index.html").replace(/<script[\s\S]*?<\/script>/gu, "")
    .replace(/<noscript[\s\S]*?<\/noscript>/gu, "");
  const ignorar = /^(?:[\s\d.,·×—→‹›▥]*|fz|factuzam|control u)$/u;
  const textos = [...html.matchAll(/>([^<]+)</gu)].map((m) => m[1].trim())
    .filter((texto) => !ignorar.test(texto));
  const atributos = [...html.matchAll(
    /\b(?:aria-label|title|alt|placeholder)="([^"]+)"/gu)].map((m) => m[1]);
  const metas = [...html.matchAll(
    /<meta (?:name="description"|property="og:\w+") content="([^"]+)"/gu)].map((m) => m[1]);
  for (const texto of [...textos, ...atributos, ...metas]) {
    assert.ok(tieneClave(texto), "Sin traducción: «" + texto + "»");
  }
  assert.ok(textos.length > 80);
  assert.doesNotMatch(leer("index.html"), /unsafe-inline|\bstyle="|<script(?![^>]*src=)/u);
});

test("Los códigos de error del hook se traducen; los desconocidos conservan el mensaje", () => {
  const php = [...readdirSync(privado).filter((n) => n.endsWith(".php"))
    .map((n) => leer(n, privado)),
  ...readdirSync(publico).filter((n) => n.endsWith(".php")).map((n) => leer(n))].join("\n");
  const codigos = new Set([...php.matchAll(
    /(?:abortar_api|responder_error)\(\s*\d+,\s*'([A-Z_]+)'/gu)].map((m) => m[1]));
  assert.ok(codigos.size >= 15, [...codigos].join(","));
  for (const codigo of codigos) {
    assert.ok(Object.hasOwn(ERRORES, codigo), "Código sin traducir: " + codigo);
    assert.ok(tieneClave(ERRORES[codigo]), codigo);
  }
  assert.equal(mensajeError("TOKEN_CADUCADO", "El token ha caducado o no es valido."),
    "El acceso ha caducado. Vuelve a entrar.");
  assert.equal(mensajeError("OTRO_CODIGO", "Mensaje del hook"), "Mensaje del hook");
  assert.equal(mensajeError(undefined, "Mensaje del hook"), "Mensaje del hook");
  assert.equal(traducir("ca", ERRORES.CREDENCIALES_INVALIDAS),
    "Usuari o contrasenya no vàlids.");
});

test("Fechas y números usan la configuración regional del idioma", () => {
  for (const nombre of modulos.filter((m) => m !== "controlu-idioma.js")) {
    assert.doesNotMatch(leer(nombre), /"es-ES"|Collator\("es"/u, nombre);
  }
});

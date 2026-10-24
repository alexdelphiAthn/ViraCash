import { t, LOCALE } from "./controlu-idioma.js?v=20261020-1";

// Las claves son valores del protocolo; solo se traduce el texto visible.
export const ESTADOS = Object.freeze({
  stock: t("Stock"), entradas: t("Entradas"), ventas: t("Ventas"),
  pte_recibir: t("Ptes. de recibir"),
});
const formatoCantidad = new Intl.NumberFormat(LOCALE, {
  maximumFractionDigits: 2,
});
const ordenTexto = new Intl.Collator(LOCALE, { sensitivity: "base" });
export const numero = (valor) => formatoCantidad.format(
  Math.abs(valor) < 0.000001 ? 0 : valor);
export const esObjeto = (valor) => valor !== null &&
  typeof valor === "object" && !Array.isArray(valor);

export function codigoValido(valor) {
  return typeof valor === "string" && Boolean(valor.trim()) &&
    [...valor.trim()].length <= 50 && !/[\u0000-\u001f\u007f]/u.test(valor);
}

export function colorHexadecimal(valor) {
  if (typeof valor !== "string") return null;
  const texto = valor.trim();
  if (/^#[0-9a-f]{6}$/iu.test(texto)) return texto.toUpperCase();
  if (/^#[0-9a-f]{3}$/iu.test(texto)) {
    return "#" + [...texto.slice(1)].map((letra) => letra + letra).join("").toUpperCase();
  }
  return null;
}

export function normalizarBasicos(valores, colores) {
  const porNombre = new Map();
  for (const fila of Array.isArray(valores) ? valores : []) {
    if (esObjeto(fila) && typeof fila.color === "string") {
      const clave = fila.color.toLocaleLowerCase("es");
      const basico = {
        codigo: typeof fila.codigo === "string" ? fila.codigo : "",
        nombre: typeof fila.nombre === "string" ? fila.nombre : "",
        hex: colorHexadecimal(fila.hex),
      };
      const anterior = porNombre.get(clave);
      // No elegir arbitrariamente entre dos basicos contradictorios.
      if (porNombre.has(clave) && (anterior === null ||
          anterior.codigo !== basico.codigo || anterior.hex !== basico.hex ||
          anterior.nombre !== basico.nombre)) porNombre.set(clave, null);
      else porNombre.set(clave, basico);
    }
  }
  return new Map(colores.map((color) => [
    color, porNombre.get(color.toLocaleLowerCase("es")) || null,
  ]));
}

// JSON.parse reordena claves numéricas. Conservamos el orden de cada
// combinación del JSON ya validado, también al filtrar un único color.
function ordenDelTexto(texto) {
  const tokens = texto.match(/"(?:\\.|[^"\\])*"|[{}\[\]:,]|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null/gu) || [];
  let posicion = 0;
  const combinaciones = [];
  function recorrer(ruta) {
    if (ruta.length > 20) {
      throw new Error(t("La estructura de la respuesta del hook no es válida."));
    }
    const token = tokens[posicion++];
    if (token === "{") {
      while (tokens[posicion] !== "}") {
        const clave = JSON.parse(tokens[posicion++]);
        posicion += 1;
        const relativa = ruta[0] === "datos" ? ruta.slice(1) : ruta;
        if (relativa.length === 3 && relativa[0] === "detalle") {
          combinaciones.push([relativa[1], relativa[2], clave]);
        }
        recorrer([...ruta, clave]);
        if (tokens[posicion] === ",") posicion += 1;
      }
      posicion += 1;
    } else if (token === "[") {
      while (tokens[posicion] !== "]") {
        recorrer([...ruta, "[]"]);
        if (tokens[posicion] === ",") posicion += 1;
      }
      posicion += 1;
    }
  }
  recorrer([]);
  return combinaciones;
}

export function interpretarStock(texto) {
  const documento = JSON.parse(texto);
  const datos = esObjeto(documento?.datos) ? documento.datos : documento;
  return normalizarStock(datos, [], ordenDelTexto(texto));
}

export function normalizarStock(datos, ordenTallas = [], ordenItems = []) {
  if (!esObjeto(datos) || typeof datos.articulo !== "string" ||
      !datos.articulo.trim() || !esObjeto(datos.detalle) ||
      !Object.hasOwn(ESTADOS, datos.estado || "stock")) {
    throw new Error(t("El hook no ha enviado una consulta de Control U válida."));
  }
  const catalogo = (valores) => Array.isArray(valores) ?
    valores.filter((valor) => typeof valor === "string" && valor.length > 0) : [];
  const colores = new Set(catalogo(datos.colores));
  const almacenes = new Set(catalogo(datos.almacenes));
  const tallas = new Set();
  const items = [];
  for (const [color, porTalla] of Object.entries(datos.detalle)) {
    if (!esObjeto(porTalla)) throw new Error(t("Detalle de colores no válido."));
    colores.add(color);
    const tallasColor = new Set([
      ...ordenTallas.filter((talla) => Object.hasOwn(porTalla, talla)),
      ...Object.keys(porTalla),
    ]);
    for (const talla of tallasColor) {
      const porAlmacen = porTalla[talla];
      if (!esObjeto(porAlmacen)) throw new Error(t("Detalle de tallas no válido."));
      tallas.add(talla);
      for (const [almacen, cantidad] of Object.entries(porAlmacen)) {
        if (!Number.isFinite(cantidad)) {
          throw new Error(t("La consulta contiene una cantidad no válida."));
        }
        almacenes.add(almacen);
        items.push({ color, talla, almacen, cantidad });
      }
    }
  }
  if (ordenItems.length) {
    const posiciones = new Map(ordenItems.map((claves, indice) =>
      [JSON.stringify(claves), indice]));
    const posicion = (item) => posiciones.get(
      JSON.stringify([item.color, item.talla, item.almacen])) ?? Infinity;
    items.sort((a, b) => posicion(a) - posicion(b));
  }
  const cantidadesUnidad = new Map();
  if (esObjeto(datos.cantidad_unidad_consultada_por_almacen)) {
    for (const [almacen, cantidad] of
      Object.entries(datos.cantidad_unidad_consultada_por_almacen)) {
      if (!Number.isFinite(cantidad)) {
        throw new Error(t("La variante consultada tiene una cantidad no válida."));
      }
      cantidadesUnidad.set(almacen, cantidad);
    }
  }
  return {
    articulo: datos.articulo,
    descripcion: typeof datos.descripcion === "string" ? datos.descripcion : "",
    estado: datos.estado || "stock",
    unidad: typeof datos.unidad_consultada === "string" ?
      datos.unidad_consultada : "",
    foto: typeof datos.foto_300_url === "string" ? datos.foto_300_url : "",
    colores: [...colores].sort(ordenTexto.compare),
    basicos: normalizarBasicos(datos.colores_basicos, [...colores]),
    almacenes: [...almacenes].sort(ordenTexto.compare),
    predeterminados: Array.isArray(datos.almacenes_predeterminados) ?
      catalogo(datos.almacenes_predeterminados).filter((a) => almacenes.has(a)) :
      [...almacenes],
    tallas: [...new Set([...items.map((item) => item.talla), ...tallas])],
    cantidadUnidadSinMapa: [datos.cantidad_unidad_consultada_predeterminada,
      datos.cantidad_unidad_consultada, datos.stock_unidad_consultada]
      .find((cantidad) => Number.isFinite(cantidad)) ?? 0,
    cantidadesUnidad, items,
  };
}

export function prepararFiltros(datos, anteriores = null, seleccion = null) {
  if (!anteriores || !seleccion) {
    return { colores: [...datos.colores], almacenes: [...datos.predeterminados] };
  }
  const igual = (a, b) => a.toLocaleLowerCase("es") === b.toLocaleLowerCase("es");
  const contiene = (lista, valor) => lista.some((otro) => igual(otro, valor));
  const conservar = (actuales, previos, elegidos, nuevos) =>
    actuales.filter((valor) => contiene(previos, valor) ?
      contiene(elegidos, valor) : contiene(nuevos, valor));
  return {
    colores: igual(datos.articulo, anteriores.articulo) ?
      conservar(datos.colores, anteriores.colores, seleccion.colores, datos.colores) :
      [...datos.colores],
    almacenes: conservar(datos.almacenes, anteriores.almacenes,
      seleccion.almacenes, datos.predeterminados),
  };
}

export function crearPivot(datos, seleccion, agrupar = "color", ocultar = true) {
  const colores = new Set(seleccion.colores);
  const almacenes = new Set(seleccion.almacenes);
  const visibles = datos.items.filter((item) =>
    colores.has(item.color) && almacenes.has(item.almacen));
  const tallasVisibles = new Set(visibles.filter((item) =>
    !ocultar || Math.abs(item.cantidad) > 0.000001).map((item) => item.talla));
  const tallas = [...new Set(visibles.map((item) => item.talla))]
    .filter((talla) => tallasVisibles.has(talla));
  const padres = new Map();
  const pie = new Map(tallas.map((talla) => [talla, 0]));
  const nuevaFila = (nombre) => ({
    nombre, celdas: new Map(), total: 0, hijos: new Map(),
  });
  const acumular = (fila, item) => {
    fila.total += item.cantidad;
    fila.celdas.set(item.talla,
      (fila.celdas.get(item.talla) || 0) + item.cantidad);
  };
  for (const item of visibles) {
    const nombre = agrupar === "almacen" ? item.almacen : item.color;
    const nombreHijo = agrupar === "almacen" ? item.color : item.almacen;
    if (!padres.has(nombre)) padres.set(nombre, nuevaFila(nombre));
    const padre = padres.get(nombre);
    if (!padre.hijos.has(nombreHijo)) {
      padre.hijos.set(nombreHijo, nuevaFila(nombreHijo));
    }
    acumular(padre, item);
    acumular(padre.hijos.get(nombreHijo), item);
    if (pie.has(item.talla)) {
      pie.set(item.talla, pie.get(item.talla) + item.cantidad);
    }
  }
  const ordenarFilas = (filas) => [...filas].sort((a, b) =>
    ordenTexto.compare(a.nombre, b.nombre));
  const filas = ordenarFilas(padres.values()).map((fila) => ({
    ...fila, hijos: ordenarFilas(fila.hijos.values()),
  }));
  const sumar = (items) => items.reduce((total, item) => total + item.cantidad, 0);
  return {
    tallas, filas, pie, total: sumar(visibles),
    totalArticulo: sumar(datos.items.filter((item) => almacenes.has(item.almacen))),
    totalUnidad: datos.cantidadesUnidad.size ?
      [...datos.cantidadesUnidad].reduce((total, [almacen, cantidad]) =>
        total + (almacenes.has(almacen) ? cantidad : 0), 0) :
      datos.cantidadUnidadSinMapa,
  };
}

export class HistorialArticulos {
  #codigos = [];
  #posicion = -1;
  get codigos() { return [...this.#codigos]; }
  get posicion() { return this.#posicion; }
  get longitud() { return this.#codigos.length; }
  agregar(codigo) {
    if (this.#codigos[this.#posicion]?.toLocaleLowerCase("es") !==
        codigo.toLocaleLowerCase("es")) {
      this.#codigos = this.#codigos.slice(0, this.#posicion + 1);
      this.#codigos.push(codigo);
      if (this.#codigos.length > 30) this.#codigos.shift();
      this.#posicion = this.#codigos.length - 1;
    }
  }
  destino(desplazamiento) {
    return this.#codigos[this.#posicion + desplazamiento] || "";
  }
  mover(desplazamiento) {
    if (this.destino(desplazamiento)) this.#posicion += desplazamiento;
  }
  limpiar() { this.#codigos = []; this.#posicion = -1; }
}

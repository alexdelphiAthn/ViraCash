import { normalizarStock, ESTADOS } from "./controlu-modelo.js?v=20261020-1";
import { t } from "./controlu-idioma.js?v=20261020-1";

// Paleta ficticia: los nombres son de presentación y siguen el idioma.
const PALETA = Object.freeze({
  Plata: "#C0C0C0", Marino: "#192F50", Cuero: "#A56F40",
  Camel: "#C19A6B", Negro: "#000000",
});

/** Color de la demo para el ejemplo de variante (DEMO-001/{color}/40). */
export const colorEjemploDemo = () => t("Marino");

export class ServicioDemo {
  establecerAcceso() {}
  cerrar() {}
  async consultar(codigo, estado, signal) {
    if (signal?.aborted) throw new DOMException(t("Cancelada"), "AbortError");
    const segundo = /002|abrigo/i.test(codigo);
    const articulo = segundo ? "DEMO-002" : "DEMO-001";
    const alms = ["GEN - Almacén Central", "TDA - Tienda", "DEP - Depósito"]
      .map((almacen) => t(almacen));
    const originales = segundo ? ["Camel", "Negro"] : ["Plata", "Marino", "Cuero"];
    const colores = originales.map((color) => t(color));
    const tallas = segundo ? ["S", "M", "L", "XL"] : ["36", "37", "38", "39", "40", "41"];
    const factor = { stock: 1, entradas: 3, ventas: 2, pte_recibir: 0.5 }[estado];
    if (!Object.hasOwn(ESTADOS, estado)) throw new Error(t("Estado no válido."));
    const detalle = {};
    colores.forEach((color, i) => {
      detalle[color] = {};
      tallas.forEach((talla, j) => {
        detalle[color][talla] = {
          [alms[0]]: j === 0 ? 0 : ((i + j) % 4) * factor,
          [alms[1]]: j === 0 ? 0 : ((i + j + 1) % 3) * factor,
          [alms[2]]: j === 0 ? 5 * factor : 0,
        };
      });
    });
    const partes = codigo.split("/");
    // Se acepta el nombre mostrado o el español original de la paleta.
    const colorUnidad = colores.find((color, i) => [color, originales[i]].some(
      (nombre) => nombre.toLocaleLowerCase("es") ===
        partes[1]?.toLocaleLowerCase("es")));
    const tallaUnidad = tallas.find((talla) =>
      talla.toLocaleLowerCase("es") === partes[2]?.toLocaleLowerCase("es"));
    if (partes.length > 1 && (!colorUnidad || !tallaUnidad || partes.length !== 3)) {
      throw new Error(t("Esta variante no está en la demo. Prueba DEMO-001/{color}/40.",
        { color: colorEjemploDemo() }));
    }
    const unidad = colorUnidad ? articulo + "/" + colorUnidad + "/" + tallaUnidad : "";
    return normalizarStock({
      articulo, descripcion: t(segundo ? "Abrigo de paño" : "Sandalia de tiras"),
      estado, unidad_consultada: unidad, colores, almacenes: alms,
      colores_basicos: colores.map((color, i) => ({
        color, codigo: originales[i], nombre: color, hex: PALETA[originales[i]],
      })),
      almacenes_predeterminados: alms.slice(0, 2), detalle,
      cantidad_unidad_consultada_por_almacen: unidad ? detalle[colorUnidad][tallaUnidad] : {},
    }, tallas);
  }
}

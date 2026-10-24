import { codigoValido, interpretarStock, ESTADOS } from "./controlu-modelo.js?v=20261020-1";
import { t, mensajeError } from "./controlu-idioma.js?v=20261020-1";

export class ErrorControlU extends Error {
  constructor(mensaje, estado = 0, codigo = "") {
    super(mensaje);
    this.estado = estado;
    this.codigo = codigo;
  }
}

export function resolverFoto(ruta, base) {
  if (typeof ruta !== "string" || !ruta) return "";
  let url;
  try { url = new URL(ruta, base); } catch { return ""; }
  const esperada = new URL("foto.php", base);
  if (url.origin !== esperada.origin || url.pathname !== esperada.pathname ||
      url.username || url.password || url.hash ||
      !["http:", "https:"].includes(url.protocol)) return "";
  for (const clave of url.searchParams.keys()) {
    if (!["articulo", "unidad"].includes(clave) ||
        url.searchParams.getAll(clave).length !== 1) return "";
  }
  const articulo = url.searchParams.get("articulo");
  const unidad = url.searchParams.get("unidad");
  if (!codigoValido(articulo) || [...articulo].length > 20 ||
      (unidad !== null && !codigoValido(unidad))) return "";
  return url.href;
}

export class ServicioControlU {
  #base;
  #descargar;
  #token = "";
  #vence = 0;
  #limiteMs;
  constructor(base, { descargar = (url, opciones) => fetch(url, opciones),
    limiteMs = 25000 } = {}) {
    this.#base = new URL(base);
    if (!["http:", "https:"].includes(this.#base.protocol) ||
        this.#base.username || this.#base.password) {
      throw new ErrorControlU(t("Abre Control U desde la dirección de tu servidor local."));
    }
    this.#descargar = descargar;
    this.#limiteMs = limiteMs;
  }
  establecerAcceso(acceso) {
    this.#token = acceso.token;
    this.#vence = acceso.vence;
  }
  cerrar() { this.#token = ""; this.#vence = 0; }

  async autenticar(usuario, password, signal) {
    if (typeof usuario !== "string" || !usuario.trim() ||
        [...usuario.trim()].length > 100 || /[\u0000-\u001f\u007f]/u.test(usuario) ||
        typeof password !== "string" || !password ||
        new TextEncoder().encode(password).length > 512) {
      throw new ErrorControlU(t("Indica un usuario y una contraseña válidos."), 400);
    }
    const { documento } = await this.#json("login.php", {
      method: "POST", body: JSON.stringify({ usuario: usuario.trim(), password }),
      headers: { "Content-Type": "application/json" }, signal,
    });
    const datos = documento.datos;
    if (!datos || typeof datos.token !== "string" || !datos.token ||
        datos.token.length > 8192 || /\s/u.test(datos.token) ||
        !Number.isFinite(datos.expira_en) || datos.expira_en <= 0 ||
        datos.expira_en > 86400 || typeof datos.usuario !== "string") {
      throw new ErrorControlU(t("El hook no ha devuelto un acceso válido."), 502);
    }
    return {
      token: datos.token, usuario: datos.usuario,
      vence: Date.now() + datos.expira_en * 1000,
    };
  }

  async consultar(codigo, estado, signal) {
    if (!codigoValido(codigo) || !Object.hasOwn(ESTADOS, estado)) {
      throw new ErrorControlU(t("Indica un artículo, SKU o código de barras válido."), 400);
    }
    const ruta = "stock.php?" + new URLSearchParams({
      articulo: codigo.trim(), estado,
    });
    const { texto } = await this.#json(ruta, {
      headers: this.#cabeceraAcceso(), signal,
    });
    try {
      const datos = interpretarStock(texto);
      if (datos.estado !== estado) {
        throw new Error(t("El hook devolvió un tipo de consulta distinto al solicitado. Comprueba su versión."));
      }
      return datos;
    } catch (error) {
      throw new ErrorControlU(error.message, 502, "STOCK_INVALIDO");
    }
  }

  async foto(ruta, signal) {
    const url = resolverFoto(ruta, this.#base);
    if (!url) throw new ErrorControlU(t("La ruta de la foto no pertenece a este hook."), 422);
    return this.#peticion(url, {
      headers: { ...this.#cabeceraAcceso(), Accept: "image/png" }, signal,
    }, async (respuesta) => {
      if (!respuesta.ok) await this.#errorRespuesta(respuesta);
      const tipo = (respuesta.headers.get("Content-Type") || "")
        .split(";", 1)[0].trim().toLowerCase();
      if (tipo !== "image/png") {
        throw new ErrorControlU(t("El hook no ha enviado una foto PNG válida."), 502);
      }
      const datos = await respuesta.blob();
      if (!datos.size || datos.size > 4 * 1024 * 1024) {
        throw new ErrorControlU(t("La foto está vacía o supera los 4 MiB."), 413);
      }
      return datos;
    });
  }

  #cabeceraAcceso() {
    if (!this.#token || this.#vence <= Date.now()) {
      throw new ErrorControlU(t("El acceso ha caducado. Vuelve a entrar."), 401);
    }
    return { Authorization: "Bearer " + this.#token };
  }

  async #errorRespuesta(respuesta, documento = null) {
    if (!documento) {
      try { documento = await respuesta.json(); } catch {
        documento = null;
      }
    }
    const codigo = typeof documento?.error?.codigo === "string" &&
      documento.error.codigo ? documento.error.codigo : "ERROR_HOOK";
    // El código es estable; el mensaje del hook solo se usa si no se conoce.
    const mensaje = mensajeError(codigo,
      typeof documento?.error?.mensaje === "string" ?
        documento.error.mensaje.slice(0, 500) :
        t("El servidor no pudo atender la consulta (HTTP {estado}).",
          { estado: respuesta.status }));
    throw new ErrorControlU(mensaje, respuesta.status, codigo);
  }

  async #json(ruta, opciones) {
    return this.#peticion(new URL(ruta, this.#base).href, opciones,
      async (respuesta) => {
        const texto = await respuesta.text();
        if (texto.length > 8 * 1024 * 1024) {
          throw new ErrorControlU(t("La respuesta del hook es demasiado grande."), 502);
        }
        let documento;
        try { documento = JSON.parse(texto); } catch {
          throw new ErrorControlU(
            t("El hook no devolvió JSON. Comprueba la dirección y la configuración del servidor."),
            respuesta.status >= 400 ? respuesta.status : 502);
        }
        if (!respuesta.ok || documento?.ok !== true) {
          await this.#errorRespuesta(respuesta, documento);
        }
        return { documento, texto };
      });
  }

  async #peticion(url, opciones, leer) {
    const controlador = new AbortController();
    const abortar = () => controlador.abort();
    if (opciones.signal?.aborted) abortar();
    opciones.signal?.addEventListener("abort", abortar, { once: true });
    const temporizador = setTimeout(abortar, this.#limiteMs);
    try {
      const respuesta = await this.#descargar(url, {
        ...opciones, headers: { Accept: "application/json", ...opciones.headers },
        credentials: "omit", cache: "no-store", redirect: "error",
        referrerPolicy: "no-referrer", signal: controlador.signal,
      });
      return await leer(respuesta);
    } catch (error) {
      if (error instanceof ErrorControlU || opciones.signal?.aborted) throw error;
      throw new ErrorControlU(
        t("No se pudo conectar. Comprueba el servidor y que estás en la red de la tienda."),
        0, "SIN_CONEXION");
    } finally {
      clearTimeout(temporizador);
      opciones.signal?.removeEventListener("abort", abortar);
    }
  }
}

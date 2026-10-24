import { t } from "./controlu-idioma.js?v=20261020-1";

export class AccesoGuardado {
  #almacen;
  #clave;
  constructor(base, almacen = null) {
    this.#clave = "factuzam-controlu:" + new URL(base).pathname;
    this.#almacen = almacen;
  }
  get clave() { return this.#clave; }
  leer(ahora = Date.now()) {
    try {
      const texto = this.#almacen?.getItem(this.#clave);
      if (!texto) return null;
      const acceso = JSON.parse(texto);
      if (typeof acceso?.token !== "string" || !acceso.token ||
          acceso.token.length > 8192 || /\s/u.test(acceso.token) ||
          !Number.isFinite(acceso.vence) || acceso.vence <= ahora ||
          acceso.vence > ahora + 86400000 ||
          typeof acceso.usuario !== "string" || typeof acceso.nombre !== "string") {
        this.#almacen.removeItem(this.#clave);
        return null;
      }
      return { token: acceso.token, vence: acceso.vence,
        usuario: acceso.usuario, nombre: acceso.nombre };
    } catch {
      // El navegador puede bloquear su almacenamiento. No bloquea el acceso.
      return null;
    }
  }
  guardar(acceso) {
    if (!this.#almacen) return false;
    try {
      const { token, vence, usuario, nombre } = acceso;
      this.#almacen.setItem(this.#clave, JSON.stringify({
        token, vence, usuario, nombre,
      }));
      return true;
    } catch { return false; }
  }
  olvidar(token = null) {
    try {
      const actual = this.#almacen?.getItem(this.#clave);
      // Otra pestaña puede haber iniciado un acceso distinto entretanto.
      if (actual && (!token || JSON.parse(actual).token === token)) {
        this.#almacen.removeItem(this.#clave);
      }
      return true;
    } catch { return false; }
  }
  preferencias() {
    try {
      const datos = JSON.parse(this.#almacen?.getItem(this.#clave + ":vista") || "{}");
      return {
        nombre: typeof datos.nombre === "string" ? datos.nombre.slice(0, 80) :
          t("Pruebas"),
        usuario: typeof datos.usuario === "string" ? datos.usuario.slice(0, 100) : "",
        agrupar: datos.agrupar === "almacen" ? "almacen" : "color",
        ocultar: datos.ocultar !== false,
      };
    } catch {
      return { nombre: t("Pruebas"), usuario: "", agrupar: "color", ocultar: true };
    }
  }
  guardarPreferencias(datos) {
    if (!this.#almacen) return false;
    try {
      this.#almacen.setItem(this.#clave + ":vista", JSON.stringify({
        nombre: datos.nombre, usuario: datos.usuario,
        agrupar: datos.agrupar, ocultar: datos.ocultar,
      }));
      return true;
    } catch { return false; }
  }
}

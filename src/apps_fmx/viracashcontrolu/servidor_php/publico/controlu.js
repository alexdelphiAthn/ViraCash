import { t, LOCALE, traducirPagina } from "./controlu-idioma.js?v=20261020-1";
import { ESTADOS, codigoValido, numero, prepararFiltros, crearPivot,
  HistorialArticulos } from "./controlu-modelo.js?v=20261020-1";
import { ServicioControlU } from "./controlu-servicio.js?v=20261020-1";
import { AccesoGuardado } from "./controlu-acceso.js?v=20261020-1";

class AplicacionControlU {
  #base = new URL("./", location.href);
  #demo = new URLSearchParams(location.search).get("demo") === "1";
  #servicio;
  #guardado;
  #acceso = null;
  #datos = null;
  #catalogo = null;
  #seleccion = null;
  #estado = "stock";
  #codigo = "";
  #intencion = null;
  #historial = new HistorialArticulos();
  #expandidos = new Set();
  #controlador = null;
  #revision = 0;
  #ocupada = false;
  #fotoUrl = "";
  #temporizador = 0;
  #suspendida = false;

  elemento(id) { return document.getElementById(id); }

  async iniciar() {
    traducirPagina(document);
    if (!["http:", "https:"].includes(location.protocol)) {
      this.#avisar("error-acceso",
        t("Abre Control U desde la dirección HTTP de tu servidor, no desde el archivo index.html."));
      return;
    }
    let almacenamiento = null;
    try { almacenamiento = localStorage; } catch {
      // Se puede trabajar en memoria si el navegador bloquea el guardado.
    }
    this.#guardado = new AccesoGuardado(this.#base, almacenamiento);
    const preferencias = this.#guardado.preferencias();
    this.elemento("nombre").value = preferencias.nombre;
    this.elemento("usuario").value = preferencias.usuario;
    this.elemento("agrupar").value = preferencias.agrupar;
    this.elemento("ocultar-ceros").checked = preferencias.ocultar;
    this.elemento("servidor-acceso").textContent = this.#base.href;
    this.elemento("aviso-http").hidden = location.protocol !== "http:";
    this.#enlazarEventos();
    if (this.#demo) {
      const { ServicioDemo, colorEjemploDemo } =
        await import("./controlu-demo.js?v=20261020-1");
      this.#servicio = new ServicioDemo();
      this.#acceso = { nombre: t("Pruebas · Tienda de ejemplo"),
        usuario: t("Demostración"), token: "", vence: Infinity };
      this.elemento("aviso-demo").hidden = false;
      this.elemento("ayuda-codigo").textContent =
        t("Prueba DEMO-001 (calzado), DEMO-002 (ropa) o DEMO-001/{color}/40.",
          { color: colorEjemploDemo() });
      this.#mostrarConsulta();
      await this.#consultar("DEMO-001");
    } else {
      this.#servicio = new ServicioControlU(this.#base);
      const acceso = this.#guardado.leer();
      if (acceso) {
        this.#activarAcceso(acceso);
        this.#avisar("aviso-sesion",
          t("Acceso recuperado en este dispositivo. Caduca {fecha}.",
            { fecha: this.#fecha(acceso.vence) }));
      }
    }
    this.elemento("conectar").disabled = false;
    this.elemento("estado-acceso").textContent = "";
  }

  #enlazarEventos() {
    this.elemento("formulario-acceso").addEventListener("submit", (evento) => {
      evento.preventDefault();
      void this.#conectar();
    });
    this.elemento("ver-password").addEventListener("click", () => {
      const visible = this.elemento("password").type === "password";
      this.elemento("password").type = visible ? "text" : "password";
      this.elemento("ver-password").textContent = t(visible ? "Ocultar" : "Ver");
      this.elemento("ver-password").setAttribute("aria-pressed", String(visible));
    });
    this.elemento("formulario-busqueda").addEventListener("submit", (evento) => {
      evento.preventDefault();
      void this.#consultar(this.elemento("codigo").value);
    });
    this.elemento("codigo").addEventListener("focus", () =>
      this.elemento("codigo").select());
    document.querySelectorAll(".barra-estados button").forEach((boton) => {
      boton.addEventListener("click", () => {
        this.#estado = boton.dataset.estado;
        this.#mostrarEstado();
        if (this.#codigo) void this.#consultar(this.#codigo, "conservar");
      });
    });
    this.elemento("actualizar").addEventListener("click", () =>
      void this.#consultar(this.#codigo, "conservar"));
    this.elemento("anterior").addEventListener("click", () =>
      void this.#navegar(-1));
    this.elemento("siguiente").addEventListener("click", () =>
      void this.#navegar(1));
    for (const id of ["agrupar", "ocultar-ceros"]) {
      this.elemento(id).addEventListener("change", () => {
        this.#expandidos.clear();
        this.#guardarPreferencias();
        this.#pintar();
      });
    }
    this.elemento("abrir-filtros").addEventListener("click", () => {
      if (this.#datos) {
        this.#pintarFiltros(this.#seleccion);
        this.#abrirDialogo("filtros");
      }
    });
    document.querySelectorAll("[data-marcar]").forEach((boton) => {
      boton.addEventListener("click", () => {
        this.elemento("filtro-" + boton.dataset.marcar)
          .querySelectorAll("input").forEach((casilla) => {
            casilla.checked = boton.dataset.valor === "si";
          });
      });
    });
    this.elemento("predeterminados").addEventListener("click", () => {
      if (this.#datos) this.#pintarFiltros(prepararFiltros(this.#datos));
    });
    this.elemento("filtros-visuales").addEventListener("click", (evento) => {
      const boton = evento.target.closest("button");
      const grupo = boton?.dataset.grupo || boton?.dataset.seleccionar;
      if (!this.#datos || !["colores", "almacenes"].includes(grupo)) return;
      if (boton.dataset.grupo) {
        const elegidos = new Set(this.#seleccion[grupo]);
        const valor = boton.dataset.valor;
        if (elegidos.has(valor)) elegidos.delete(valor);
        else elegidos.add(valor);
        this.#seleccion[grupo] = this.#datos[grupo].filter((v) => elegidos.has(v));
      } else {
        const conjunto = boton.dataset.conjunto;
        this.#seleccion[grupo] = conjunto === "todos" ? [...this.#datos[grupo]] :
          conjunto === "predeterminados" ? [...this.#datos.predeterminados] : [];
      }
      this.#expandidos.clear();
      this.#pintar();
    });
    this.elemento("formulario-filtros").addEventListener("submit", (evento) => {
      evento.preventDefault();
      if (this.#datos) {
        const marcados = (id) => Array.from(this.elemento(id)
          .querySelectorAll("input")).filter((c) => c.checked).map((c) => c.value);
        this.#seleccion = { colores: marcados("filtro-colores"),
          almacenes: marcados("filtro-almacenes") };
        this.#expandidos.clear();
        this.elemento("filtros").close();
        this.#pintar();
      }
    });
    document.querySelectorAll("[data-cerrar]").forEach((boton) => {
      boton.addEventListener("click", () =>
        this.elemento(boton.dataset.cerrar).close());
    });
    this.elemento("abrir-ajustes").addEventListener("click", () => {
      if (this.#vigente()) {
        this.elemento("conexion-nombre").textContent = this.#acceso.nombre;
        this.elemento("conexion-usuario").textContent = this.#acceso.usuario;
        this.elemento("conexion-servidor").textContent = this.#base.href;
        this.elemento("conexion-vence").textContent = this.#fecha(this.#acceso.vence);
        this.#abrirDialogo("ajustes");
      }
    });
    this.elemento("salir").addEventListener("click", () =>
      this.#cerrarSesion(t("Sesión cerrada. El acceso guardado se ha eliminado.")));
    this.elemento("ampliar-foto").addEventListener("click", () => {
      if (this.#fotoUrl && this.#vigente()) {
        this.elemento("imagen-grande").src = this.#fotoUrl;
        this.elemento("imagen-grande").alt = this.#datos?.descripcion || t("Artículo");
        this.#abrirDialogo("foto-grande");
      }
    });
    this.elemento("foto-grande").addEventListener("close", () =>
      this.elemento("imagen-grande").removeAttribute("src"));
    document.addEventListener("visibilitychange", () => {
      if (document.hidden) this.#suspender();
      else this.#reanudar();
    });
    window.addEventListener("pagehide", () => this.#suspender());
    window.addEventListener("pageshow", () => this.#reanudar());
    window.addEventListener("storage", (evento) => {
      if (!this.#demo && this.#acceso &&
          (evento.key === null || evento.key === this.#guardado.clave)) {
        const actual = this.#guardado.leer();
        if (actual?.token !== this.#acceso.token) {
          this.#cerrarSesion(
            t("El acceso ha cambiado en otra pestaña. Vuelve a entrar."), false);
        }
      }
    });
  }

  async #conectar() {
    if (this.#ocupada || this.#demo) return;
    const usuario = this.elemento("usuario").value.trim();
    const password = this.elemento("password").value;
    const nombre = this.elemento("nombre").value.trim() || t("Pruebas");
    const recordar = this.elemento("recordar").checked;
    this.#cancelar();
    const revision = this.#revision;
    const controlador = new AbortController();
    this.#controlador = controlador;
    this.#ocupada = true;
    this.elemento("conectar").disabled = true;
    this.elemento("estado-acceso").textContent = t("Comprobando el acceso…");
    this.#avisar("error-acceso", "");
    this.#borrarPassword();
    try {
      const respuesta = await this.#servicio.autenticar(
        usuario, password, controlador.signal);
      if (revision !== this.#revision || this.#suspendida) return;
      const acceso = { ...respuesta, nombre };
      const borrado = this.#guardado.olvidar();
      const conservado = recordar && this.#guardado.guardar(acceso);
      this.#activarAcceso(acceso);
      this.#guardarPreferencias();
      this.#avisar("aviso-sesion", recordar && !conservado ?
        t("El navegador no permite guardar este acceso. Puedes consultar; al cerrar la página tendrás que volver a entrar.") :
        conservado ? t("Acceso guardado hasta {fecha}.", { fecha: this.#fecha(acceso.vence) }) :
        t("El acceso solo se mantiene mientras esta página siga abierta."));
      if (!borrado && !conservado) {
        this.#avisar("aviso-sesion",
          t("No se pudo borrar un acceso guardado anterior. Esta sesión funciona en memoria; elimina los datos de este sitio en el navegador para olvidar aquel acceso."));
      }
      this.elemento("codigo").focus();
    } catch (error) {
      if (revision === this.#revision && !controlador.signal.aborted) {
        this.#avisar("error-acceso", error.message);
      }
    } finally {
      if (revision === this.#revision) {
        this.#ocupada = false;
        this.#controlador = null;
        this.elemento("conectar").disabled = false;
        this.elemento("estado-acceso").textContent = "";
        this.#actualizarBotones();
      }
    }
  }

  #activarAcceso(acceso) {
    this.#acceso = acceso;
    this.#servicio.establecerAcceso(acceso);
    clearTimeout(this.#temporizador);
    this.#temporizador = setTimeout(() => this.#cerrarSesion(
      t("El acceso ha caducado. Vuelve a entrar con tu usuario de ViraCash.")),
    Math.max(0, acceso.vence - Date.now()));
    this.#mostrarConsulta();
  }

  #mostrarConsulta() {
    this.elemento("acceso").hidden = true;
    this.elemento("consulta").hidden = false;
    this.elemento("abrir-ajustes").hidden = this.#demo;
    this.elemento("instalacion").textContent = this.#acceso.nombre;
    this.#mostrarEstado();
    this.#actualizarBotones();
  }

  #vigente() {
    if (!this.#acceso) return false;
    if (!this.#demo && this.#acceso.vence <= Date.now()) {
      this.#cerrarSesion(t("El acceso ha caducado. Vuelve a entrar."));
      return false;
    }
    return true;
  }

  #cerrarSesion(mensaje, olvidar = true) {
    const token = this.#acceso?.token;
    this.#cancelar();
    clearTimeout(this.#temporizador);
    let eliminado = true;
    if (olvidar && token && !this.#demo) eliminado = this.#guardado.olvidar(token);
    this.#servicio?.cerrar();
    this.#acceso = null;
    this.#catalogo = null;
    this.#seleccion = null;
    this.#codigo = "";
    this.#intencion = null;
    this.#historial.limpiar();
    this.#limpiarVista();
    this.#borrarPassword();
    this.#cerrarDialogos();
    this.#estado = "stock";
    this.elemento("codigo").value = "";
    this.elemento("instalacion").textContent = "";
    for (const id of ["conexion-nombre", "conexion-usuario",
      "conexion-servidor", "conexion-vence"]) this.elemento(id).textContent = "";
    this.elemento("consulta").hidden = true;
    this.elemento("acceso").hidden = false;
    this.elemento("abrir-ajustes").hidden = true;
    this.#avisar("aviso-sesion", "");
    this.#avisar("error-consulta", "");
    this.#avisar("error-acceso", eliminado ? mensaje :
      mensaje + " " +
      t("No se pudo borrar el guardado: elimina los datos de este sitio en el navegador."));
    this.elemento("estado-acceso").textContent = "";
    this.#actualizarBotones();
  }

  async #navegar(paso) {
    const codigo = this.#historial.destino(paso);
    if (codigo && !this.#ocupada) await this.#consultar(codigo, "mover", paso);
  }

  async #consultar(codigo, historia = "agregar", paso = 0) {
    if (!this.#vigente() || this.#suspendida) return;
    if (!codigoValido(codigo)) {
      this.#avisar("error-consulta",
        t("Indica un artículo, SKU o código de barras de hasta 50 caracteres."));
      return;
    }
    if (historia === "conservar" && this.#intencion?.codigo === codigo.trim()) {
      historia = this.#intencion.historia;
      paso = this.#intencion.paso;
    }
    this.#cancelar();
    this.#cerrarDialogos();
    this.#limpiarVista();
    this.#codigo = codigo.trim();
    this.#intencion = { codigo: this.#codigo, historia, paso };
    const revision = this.#revision;
    const controlador = new AbortController();
    this.#controlador = controlador;
    this.#ocupada = true;
    this.elemento("codigo").value = this.#codigo;
    if (document.activeElement === this.elemento("codigo")) {
      this.elemento("codigo").select();
    }
    this.#avisar("error-consulta", "");
    this.elemento("estado-consulta").textContent =
      t("Consultando {codigo}…", { codigo: this.#codigo });
    this.elemento("espera-inicial").hidden = true;
    this.#actualizarBotones();
    try {
      const datos = await this.#servicio.consultar(
        this.#codigo, this.#estado, controlador.signal);
      if (revision !== this.#revision || this.#suspendida || !this.#vigente()) return;
      this.#seleccion = prepararFiltros(datos, this.#catalogo, this.#seleccion);
      this.#catalogo = { articulo: datos.articulo,
        colores: [...datos.colores], almacenes: [...datos.almacenes] };
      this.#datos = datos;
      if (historia === "agregar") this.#historial.agregar(this.#codigo);
      if (historia === "mover") this.#historial.mover(paso);
      this.#intencion = null;
      this.#pintar();
      const hora = new Intl.DateTimeFormat(LOCALE, {
        hour: "2-digit", minute: "2-digit", second: "2-digit",
      }).format(new Date());
      this.elemento("estado-consulta").textContent = this.#demo ?
        t("Datos de ejemplo · Sin conexión al servidor") :
        t("Actualizado a las {hora}", { hora });
      this.#ocupada = false;
      this.#actualizarBotones();
      await this.#cargarFoto(datos, revision, controlador.signal);
    } catch (error) {
      if (revision === this.#revision && !controlador.signal.aborted) {
        if ([401, 403].includes(error.estado)) this.#cerrarSesion(error.message);
        else {
          this.#avisar("error-consulta", error.message);
          this.elemento("estado-consulta").textContent = t("Consulta no disponible.");
        }
      }
    } finally {
      if (revision === this.#revision) {
        this.#ocupada = false;
        this.#controlador = null;
        this.#actualizarBotones();
      }
    }
  }

  #pintar() {
    if (!this.#datos || !this.#seleccion) return;
    const datos = this.#datos;
    const agrupar = this.elemento("agrupar").value;
    const pivot = crearPivot(datos, this.#seleccion, agrupar,
      this.elemento("ocultar-ceros").checked);
    this.elemento("resultado").hidden = false;
    this.elemento("resultado").dataset.estado = datos.estado;
    this.elemento("espera-inicial").hidden = true;
    this.elemento("articulo").textContent = datos.articulo;
    this.elemento("descripcion").textContent = datos.descripcion || t("Artículo sin descripción");
    this.elemento("titulo-cantidad").textContent = ESTADOS[datos.estado];
    this.elemento("total-articulo").textContent = numero(pivot.totalArticulo);
    this.elemento("unidad").textContent = datos.unidad ?
      t("{unidad} · Cantidad de esta variante: {cantidad}",
        { unidad: datos.unidad, cantidad: numero(pivot.totalUnidad) }) : "";
    const filtros = this.#seleccion;
    this.elemento("resumen-filtros").textContent = t(
      "{colores} de {totalColores} colores · {almacenes} de {totalAlmacenes} almacenes", {
        colores: numero(filtros.colores.length), totalColores: numero(datos.colores.length),
        almacenes: numero(filtros.almacenes.length),
        totalAlmacenes: numero(datos.almacenes.length),
      });
    const omitidos = datos.colores.length + datos.almacenes.length -
      filtros.colores.length - filtros.almacenes.length;
    this.elemento("contador-filtros").textContent = omitidos ?
      "(" + numero(omitidos) + ")" : "";
    this.#pintarFiltrosVisibles();
    const encabezado = this.#nodo("tr");
    const th = (texto, ambito = "col") => {
      const celda = this.#nodo("th", texto);
      celda.scope = ambito;
      return celda;
    };
    encabezado.append(th(agrupar === "color" ? t("Color / almacén") : t("Almacén / color")));
    for (const talla of pivot.tallas) encabezado.append(th(talla || t("Sin talla")));
    encabezado.append(th(t("Total")));
    this.elemento("cabecera-stock").replaceChildren(encabezado);
    const cuerpo = document.createDocumentFragment();
    for (const fila of pivot.filas) {
      const tr = this.#nodo("tr");
      const titulo = th("", "row");
      const boton = this.#nodo("button");
      boton.type = "button";
      boton.className = "desplegar";
      const simbolo = this.#nodo("span");
      simbolo.setAttribute("aria-hidden", "true");
      boton.append(simbolo);
      if (agrupar === "color") boton.append(this.#cuadradoColor(fila.nombre));
      boton.append(document.createTextNode(fila.nombre || t("Sin definir")));
      titulo.append(boton);
      tr.append(titulo, ...this.#celdas(fila, pivot.tallas));
      cuerpo.append(tr);
      const hijos = fila.hijos.map((hijo) => {
        const detalle = this.#nodo("tr");
        detalle.className = "fila-hija";
        const tituloHijo = th("", "row");
        if (agrupar === "almacen") tituloHijo.append(this.#cuadradoColor(hijo.nombre));
        tituloHijo.append(document.createTextNode(hijo.nombre || t("Sin definir")));
        detalle.append(tituloHijo, ...this.#celdas(hijo, pivot.tallas));
        cuerpo.append(detalle);
        return detalle;
      });
      const mostrar = () => {
        const abierta = this.#expandidos.has(fila.nombre);
        boton.setAttribute("aria-expanded", String(abierta));
        simbolo.textContent = abierta ? "▾" : "▸";
        hijos.forEach((hijo) => { hijo.hidden = !abierta; });
      };
      boton.addEventListener("click", () => {
        if (this.#expandidos.has(fila.nombre)) this.#expandidos.delete(fila.nombre);
        else this.#expandidos.add(fila.nombre);
        mostrar();
      });
      mostrar();
    }
    this.elemento("cuerpo-stock").replaceChildren(cuerpo);
    const pie = this.#nodo("tr");
    pie.append(th(t("Total visible"), "row"),
      ...this.#celdas({ celdas: pivot.pie, total: pivot.total }, pivot.tallas));
    this.elemento("pie-stock").replaceChildren(pie);
    this.elemento("tabla-stock").querySelector("caption").textContent =
      t("{estado} de {articulo} por talla",
        { estado: ESTADOS[datos.estado], articulo: datos.articulo });
    this.elemento("tabla-stock").parentElement.hidden = pivot.filas.length === 0;
    this.elemento("sin-cantidades").hidden = pivot.filas.length !== 0;
    this.elemento("sin-cantidades").textContent = datos.items.length === 0 ?
      t("Sin cantidades para este artículo en esta consulta.") :
      t("Sin datos con los filtros seleccionados.");
  }

  #celdas(fila, tallas) {
    return [...tallas.map((talla) => fila.celdas.get(talla) || 0), fila.total]
      .map((cantidad) => {
        const celda = this.#nodo("td", numero(cantidad));
        if (Math.abs(cantidad) < 0.000001) celda.className = "cero";
        else if (cantidad < 0) celda.className = "negativa";
        return celda;
      });
  }

  #pintarFiltros(seleccion) {
    for (const grupo of ["colores", "almacenes"]) {
      const lista = document.createDocumentFragment();
      for (const valor of this.#datos[grupo]) {
        const etiqueta = this.#nodo("label");
        const casilla = this.#nodo("input");
        casilla.type = "checkbox";
        casilla.value = valor;
        casilla.checked = seleccion[grupo].includes(valor);
        etiqueta.append(casilla);
        if (grupo === "colores") etiqueta.append(this.#cuadradoColor(valor));
        etiqueta.append(this.#nodo("span", valor || t("Sin definir")));
        lista.append(etiqueta);
      }
      this.elemento("filtro-" + grupo).replaceChildren(lista);
    }
  }

  #pintarFiltrosVisibles() {
    for (const grupo of ["colores", "almacenes"]) {
      const lista = this.elemento("seleccion-" + grupo);
      const valores = this.#datos[grupo];
      // Mantener los botones existentes conserva el foco al tocar o pulsar.
      if (lista.children.length !== valores.length ||
          [...lista.children].some((boton, i) => boton.dataset.valor !== valores[i])) {
        const botones = valores.map((valor) => {
          const boton = this.#nodo("button");
          boton.type = "button";
          boton.className = "filtro-chip";
          boton.dataset.grupo = grupo;
          boton.dataset.valor = valor;
          const marca = this.#nodo("span");
          marca.className = "marca-filtro";
          marca.setAttribute("aria-hidden", "true");
          boton.append(marca);
          if (grupo === "colores") {
            boton.append(this.#cuadradoColor(valor));
            boton.title = this.#descripcionBasico(valor);
          }
          boton.append(this.#nodo("span", valor || t("Sin definir")));
          return boton;
        });
        lista.replaceChildren(...botones);
      }
      for (const boton of lista.children) {
        const elegido = this.#seleccion[grupo].includes(boton.dataset.valor);
        boton.setAttribute("aria-pressed", String(elegido));
        boton.querySelector(".marca-filtro").textContent = elegido ? "✓" : "·";
      }
    }
  }

  #descripcionBasico(color) {
    const basico = this.#datos?.basicos.get(color);
    return color + " · " + (basico?.nombre ?
      t(basico.hex ? "Básico: {nombre}" : "Básico: {nombre} (sin tono definido)",
        { nombre: basico.nombre }) : t("Sin básico asignado"));
  }

  #cuadradoColor(color) {
    // Canvas permite el tono validado sin estilos en línea ni relajar la CSP.
    const cuadro = this.#nodo("canvas");
    cuadro.className = "cuadrado-color";
    cuadro.width = 24;
    cuadro.height = 24;
    cuadro.setAttribute("aria-hidden", "true");
    cuadro.title = this.#descripcionBasico(color);
    const contexto = cuadro.getContext("2d");
    const hex = this.#datos?.basicos.get(color)?.hex;
    if (contexto) {
      contexto.fillStyle = hex || "#F1F4ED";
      contexto.fillRect(0, 0, 24, 24);
      if (!hex) {
        contexto.strokeStyle = "#9BAB99";
        contexto.lineWidth = 2;
        for (let x = -24; x < 24; x += 8) {
          contexto.beginPath();
          contexto.moveTo(x, 24);
          contexto.lineTo(x + 24, 0);
          contexto.stroke();
        }
      }
    }
    return cuadro;
  }

  async #cargarFoto(datos, revision, signal) {
    if (this.#demo) {
      this.elemento("sustituto-foto").textContent = t("Ejemplo");
      return;
    }
    if (!datos.foto) return;
    this.elemento("sustituto-foto").textContent = t("Cargando foto…");
    try {
      const imagen = await this.#servicio.foto(datos.foto, signal);
      if (revision !== this.#revision || signal.aborted || !this.#vigente()) return;
      const ruta = URL.createObjectURL(imagen);
      this.#fotoUrl = ruta;
      const foto = this.elemento("foto");
      foto.onload = () => {
        if (this.#fotoUrl === ruta && revision === this.#revision) {
          foto.hidden = false;
          this.elemento("sustituto-foto").hidden = true;
          this.elemento("ampliar-foto").disabled = false;
          this.elemento("pie-foto").hidden = false;
        }
      };
      foto.onerror = () => {
        if (this.#fotoUrl === ruta && revision === this.#revision) {
          this.#limpiarFoto(t("Foto no disponible"));
        }
      };
      foto.alt = datos.descripcion || t("Foto del artículo");
      foto.src = ruta;
    } catch (error) {
      if (revision === this.#revision && !signal.aborted) {
        if ([401, 403].includes(error.estado)) this.#cerrarSesion(error.message);
        else this.#limpiarFoto(t(error.estado === 404 ? "Sin foto" : "Foto no disponible"));
      }
    }
  }

  #limpiarFoto(mensaje = t("Sin foto")) {
    const foto = this.elemento("foto");
    foto.onload = null;
    foto.onerror = null;
    foto.removeAttribute("src");
    foto.alt = "";
    foto.hidden = true;
    this.elemento("imagen-grande").removeAttribute("src");
    this.elemento("imagen-grande").alt = t("Foto del artículo");
    this.elemento("sustituto-foto").hidden = false;
    this.elemento("sustituto-foto").textContent = mensaje;
    this.elemento("ampliar-foto").disabled = true;
    this.elemento("pie-foto").hidden = true;
    if (this.#fotoUrl) URL.revokeObjectURL(this.#fotoUrl);
    this.#fotoUrl = "";
  }

  #limpiarVista() {
    this.#datos = null;
    this.#expandidos.clear();
    this.#limpiarFoto();
    this.elemento("resultado").hidden = true;
    this.elemento("espera-inicial").hidden = false;
    for (const id of ["articulo", "descripcion", "unidad", "total-articulo",
      "resumen-filtros", "contador-filtros"]) this.elemento(id).textContent = "";
    for (const id of ["cabecera-stock", "cuerpo-stock", "pie-stock",
      "filtro-colores", "filtro-almacenes", "seleccion-colores",
      "seleccion-almacenes"]) this.elemento(id).replaceChildren();
    this.elemento("tabla-stock").querySelector("caption").textContent =
      t("Existencias del artículo por talla");
    this.elemento("estado-consulta").textContent = t("Introduce un código para consultar.");
  }

  #cancelar() {
    this.#revision += 1;
    this.#controlador?.abort();
    this.#controlador = null;
    this.#ocupada = false;
    this.elemento("conectar").disabled = false;
  }

  #suspender() {
    this.#suspendida = true;
    this.#cancelar();
    this.#cerrarDialogos();
    this.#limpiarVista();
    this.#borrarPassword();
    this.elemento("codigo").value = "";
    this.elemento("estado-acceso").textContent = "";
    this.#avisar("error-consulta", "");
    this.#actualizarBotones();
  }

  #reanudar() {
    if (this.#suspendida && !document.hidden) {
      this.#suspendida = false;
      if (this.#vigente() && this.#codigo) {
        void this.#consultar(this.#codigo, "conservar");
      }
    }
  }

  #actualizarBotones() {
    this.elemento("anterior").disabled = this.#ocupada || !this.#historial.destino(-1);
    this.elemento("siguiente").disabled = this.#ocupada || !this.#historial.destino(1);
    this.elemento("actualizar").disabled = this.#ocupada || !this.#codigo || !this.#acceso;
    this.elemento("posicion-historial").textContent = this.#historial.longitud ?
      numero(this.#historial.posicion + 1) + " / " + numero(this.#historial.longitud) : "";
    this.elemento("consulta").setAttribute("aria-busy", String(this.#ocupada));
  }

  #mostrarEstado() {
    document.querySelectorAll(".barra-estados button").forEach((boton) =>
      boton.setAttribute("aria-pressed", String(boton.dataset.estado === this.#estado)));
  }

  #guardarPreferencias() {
    if (!this.#demo) this.#guardado.guardarPreferencias({
      nombre: this.#acceso?.nombre || this.elemento("nombre").value,
      usuario: this.#acceso?.usuario || this.elemento("usuario").value,
      agrupar: this.elemento("agrupar").value,
      ocultar: this.elemento("ocultar-ceros").checked,
    });
  }

  #borrarPassword() {
    this.elemento("password").value = "";
    this.elemento("password").type = "password";
    this.elemento("ver-password").textContent = t("Ver");
    this.elemento("ver-password").setAttribute("aria-pressed", "false");
  }

  #abrirDialogo(id) {
    if (!this.elemento(id).open) this.elemento(id).showModal();
  }

  #cerrarDialogos() {
    document.querySelectorAll("dialog").forEach((dialogo) => {
      if (dialogo.open) dialogo.close();
    });
  }

  #avisar(id, mensaje) {
    this.elemento(id).textContent = mensaje || "";
    this.elemento(id).hidden = !mensaje;
  }

  #nodo(tipo, texto = "") {
    const nodo = document.createElement(tipo);
    if (texto !== "") nodo.textContent = texto;
    return nodo;
  }

  #fecha(instante) {
    return new Intl.DateTimeFormat(LOCALE, {
      dateStyle: "short", timeStyle: "short",
    }).format(new Date(instante));
  }
}

const aplicacion = new AplicacionControlU();
aplicacion.iniciar().catch(() => {
  const aviso = document.getElementById("error-acceso");
  aviso.textContent = t("No se ha podido iniciar Control U. Recarga la página y comprueba que se han copiado todos los archivos.");
  aviso.hidden = false;
});

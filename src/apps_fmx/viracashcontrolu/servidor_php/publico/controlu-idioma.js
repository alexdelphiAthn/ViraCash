// Idioma de la versión web de Control U (FZ-ISSUE-613).
//
// Regla común a la app nativa y a la web de ventas: español, inglés, catalán
// o chino se muestran en ese idioma (es-ES, en-GB, ca-ES, zh-CN); cualquier
// otro idioma del navegador se muestra en inglés. No hay selector.
//
// La clave es el texto español exacto (el mismo que lleva index.html o el
// código). Los parámetros se escriben {nombre}. Si falta una traducción se
// muestra el español. La terminología sigue a TextosControlU.pas.
// Los valores del protocolo (estados, códigos, claves JSON) no se traducen.

export const IDIOMAS = Object.freeze({
  es: "es-ES", ca: "ca-ES", en: "en-GB", zh: "zh-CN",
});

/** Primer idioma admitido de la lista (navigator.languages); si no, inglés. */
export function resolverIdioma(preferidos = []) {
  for (const etiqueta of preferidos) {
    const base = String(etiqueta || "").trim().toLowerCase().split(/[-_]/u)[0];
    if (Object.hasOwn(IDIOMAS, base)) return base;
  }
  return "en";
}

function idiomaInicial() {
  // Pruebas en Node y utilidades sin página: se conserva el español.
  if (typeof document === "undefined" || typeof navigator === "undefined") {
    return "es";
  }
  const lista = Array.isArray(navigator.languages) && navigator.languages.length ?
    navigator.languages : [navigator.language];
  return resolverIdioma(lista);
}

export const IDIOMA = idiomaInicial();
export const LOCALE = IDIOMAS[IDIOMA];

function traducirEn(idioma, clave) {
  return idioma === "es" ? clave : (DICCIONARIO[clave]?.[idioma] ?? clave);
}

function sustituir(texto, parametros) {
  return texto.replace(/\{(\w+)\}/gu, (coincidencia, nombre) =>
    Object.hasOwn(parametros, nombre) ? String(parametros[nombre]) : coincidencia);
}

export function t(clave, parametros = {}) {
  return sustituir(traducirEn(IDIOMA, clave), parametros);
}

/** Traducción en un idioma concreto, para pruebas y comprobaciones. */
export function traducir(idioma, clave, parametros = {}) {
  return sustituir(traducirEn(idioma, clave), parametros);
}

// Mensaje estable por código de error del hook. Un código desconocido
// conserva el mensaje que envía el servidor.
export const ERRORES = Object.freeze({
  CREDENCIALES_INVALIDAS: "Usuario o contraseña no válidos.",
  CODIGO_INVALIDO: "Indica un artículo, SKU o código de barras válido.",
  ARTICULO_NO_ENCONTRADO: "No existe el artículo indicado.",
  FOTO_NO_ENCONTRADA: "El artículo no tiene foto de 300 px.",
  FOTO_DEMASIADO_GRANDE: "La foto supera el límite permitido.",
  ESTADO_INVALIDO: "El estado de la consulta no es válido.",
  METODO_NO_PERMITIDO: "Método HTTP no permitido.",
  CUERPO_DEMASIADO_GRANDE: "La petición es demasiado grande.",
  JSON_INVALIDO: "El cuerpo JSON no es válido.",
  NO_AUTORIZADO: "Falta el acceso o no es válido. Vuelve a entrar.",
  TOKEN_INVALIDO: "El acceso no es válido. Vuelve a entrar.",
  TOKEN_CADUCADO: "El acceso ha caducado. Vuelve a entrar.",
  USUARIO_INACTIVO: "El acceso ya no está autorizado.",
  DEMASIADOS_INTENTOS: "Demasiados intentos de acceso. Espera antes de reintentarlo.",
  PERMISO_DENEGADO: "El usuario no tiene permiso para consultar el stock.",
  ERROR_INTERNO: "No se pudo completar la operación.",
});

export function mensajeError(codigo, mensajeServidor) {
  return typeof codigo === "string" && Object.hasOwn(ERRORES, codigo) ?
    t(ERRORES[codigo]) : mensajeServidor;
}

const ATRIBUTOS = ["aria-label", "title", "alt", "placeholder"];

/** Traduce los textos estáticos de la página y fija <html lang>. */
export function traducirPagina(documento = document) {
  documento.documentElement.lang = LOCALE;
  if (IDIOMA === "es") return;
  const cambiar = (texto) => {
    const clave = texto.trim();
    if (!clave || !Object.hasOwn(DICCIONARIO, clave)) return texto;
    const inicio = texto.slice(0, texto.indexOf(clave));
    const fin = texto.slice(texto.indexOf(clave) + clave.length);
    return inicio + t(clave) + fin;
  };
  documento.title = cambiar(documento.title);
  documento.querySelectorAll('meta[name="description"], meta[property^="og:"]')
    .forEach((meta) => meta.setAttribute("content", cambiar(meta.content)));
  const recorrido = documento.createTreeWalker(documento.body, 4);
  for (let nodo = recorrido.nextNode(); nodo; nodo = recorrido.nextNode()) {
    if (!nodo.parentElement?.closest("script, style, noscript")) {
      const nuevo = cambiar(nodo.nodeValue);
      if (nuevo !== nodo.nodeValue) nodo.nodeValue = nuevo;
    }
  }
  for (const atributo of ATRIBUTOS) {
    documento.querySelectorAll("[" + atributo + "]").forEach((elemento) => {
      const valor = elemento.getAttribute(atributo);
      const nuevo = cambiar(valor);
      if (nuevo !== valor) elemento.setAttribute(atributo, nuevo);
    });
  }
}

const DICCIONARIO = {
  // Página: cabecera, metadatos y pie.
  "ViraCash Control U": {
    "ca": "ViraCash Control U", "en": "ViraCash Control U", "zh": "ViraCash Control U"
  },
  "Control U de ViraCash: consulta de stock por talla, color y almacén en tu red local.": {
    "ca": "Control U de ViraCash: consulta d'estoc per talla, color i magatzem a la teva xarxa local.",
    "en": "ViraCash Control U: stock enquiry by size, colour and warehouse on your local network.",
    "zh": "ViraCash Control U：在您的局域网内按尺码、颜色和仓库查询库存。"
  },
  "Tu stock, talla por talla. Consulta conectada al servidor de tu tienda.": {
    "ca": "El teu estoc, talla per talla. Consulta connectada al servidor de la teva botiga.",
    "en": "Your stock, size by size. Enquiries connected to your shop's server.",
    "zh": "您的库存，逐个尺码查看。直接连接门店服务器查询。"
  },
  "Ir al contenido": {
    "ca": "Anar al contingut", "en": "Skip to content", "zh": "跳到内容"
  },
  "ViraCash Control U, inicio": {
    "ca": "ViraCash Control U, inici", "en": "ViraCash Control U, home",
    "zh": "ViraCash Control U，首页"
  },
  "Red local · Solo consulta": {
    "ca": "Xarxa local · Només consulta", "en": "Local network · View only",
    "zh": "局域网 · 仅查看"
  },
  "Mi conexión": { "ca": "La meva connexió", "en": "My connection", "zh": "我的连接" },
  "ViraCash Control U · Tus datos permanecen en tu red local.": {
    "ca": "ViraCash Control U · Les teves dades es queden a la teva xarxa local.",
    "en": "ViraCash Control U · Your data stays on your local network.",
    "zh": "ViraCash Control U · 您的数据始终保留在局域网内。"
  },

  // Demostración.
  "Demostración · datos ficticios": {
    "ca": "Demostració · dades fictícies", "en": "Demo · sample data",
    "zh": "演示 · 虚构数据"
  },
  "Prueba los filtros y las tallas. No se conecta a tu instalación.": {
    "ca": "Prova els filtres i les talles. No es connecta a la teva instal·lació.",
    "en": "Try the filters and sizes. It does not connect to your installation.",
    "zh": "试试筛选和尺码。不会连接到您的安装。"
  },
  "Salir de la demo": { "ca": "Surt de la demo", "en": "Exit the demo", "zh": "退出演示" },
  "Probar una demostración sin conectar →": {
    "ca": "Prova una demostració sense connectar →",
    "en": "Try a demo without connecting →", "zh": "无需连接，试用演示 →"
  },
  "Pruebas · Tienda de ejemplo": {
    "ca": "Proves · Botiga d'exemple", "en": "Test · Sample shop", "zh": "测试 · 示例门店"
  },
  "Demostración": { "ca": "Demostració", "en": "Demo", "zh": "演示" },
  "Prueba DEMO-001 (calzado), DEMO-002 (ropa) o DEMO-001/{color}/40.": {
    "ca": "Prova DEMO-001 (calçat), DEMO-002 (roba) o DEMO-001/{color}/40.",
    "en": "Try DEMO-001 (footwear), DEMO-002 (clothing) or DEMO-001/{color}/40.",
    "zh": "试试 DEMO-001（鞋类）、DEMO-002（服装）或 DEMO-001/{color}/40。"
  },
  "Esta variante no está en la demo. Prueba DEMO-001/{color}/40.": {
    "ca": "Aquesta variant no és a la demo. Prova DEMO-001/{color}/40.",
    "en": "This variant is not in the demo. Try DEMO-001/{color}/40.",
    "zh": "演示中没有此款式。试试 DEMO-001/{color}/40。"
  },
  "Datos de ejemplo · Sin conexión al servidor": {
    "ca": "Dades d'exemple · Sense connexió al servidor",
    "en": "Sample data · Not connected to the server",
    "zh": "示例数据 · 未连接服务器"
  },
  "Cancelada": { "ca": "Cancel·lada", "en": "Cancelled", "zh": "已取消" },
  "Estado no válido.": { "ca": "Estat no vàlid.", "en": "Invalid status.", "zh": "状态无效。" },
  "Abrigo de paño": { "ca": "Abric de drap", "en": "Wool cloth coat", "zh": "呢子大衣" },
  "Sandalia de tiras": { "ca": "Sandàlia de tires", "en": "Strappy sandal", "zh": "绑带凉鞋" },
  "GEN - Almacén Central": {
    "ca": "GEN - Magatzem central", "en": "GEN - Central warehouse", "zh": "GEN - 中央仓库"
  },
  "TDA - Tienda": { "ca": "TDA - Botiga", "en": "TDA - Shop", "zh": "TDA - 门店" },
  "DEP - Depósito": { "ca": "DEP - Dipòsit", "en": "DEP - Consignment", "zh": "DEP - 寄售" },
  "Plata": { "ca": "Plata", "en": "Silver", "zh": "银色" },
  "Marino": { "ca": "Marí", "en": "Navy", "zh": "藏青" },
  "Cuero": { "ca": "Cuir", "en": "Tan", "zh": "皮革色" },
  "Camel": { "ca": "Camel", "en": "Camel", "zh": "驼色" },
  "Negro": { "ca": "Negre", "en": "Black", "zh": "黑色" },

  // Presentación y acceso.
  "EL STOCK DE TU TIENDA, A MANO": {
    "ca": "L'ESTOC DE LA TEVA BOTIGA, A MÀ", "en": "YOUR SHOP'S STOCK, AT HAND",
    "zh": "门店库存，触手可及"
  },
  "Cada talla.": { "ca": "Cada talla.", "en": "Every size.", "zh": "每个尺码。" },
  "Cada color.": { "ca": "Cada color.", "en": "Every colour.", "zh": "每种颜色。" },
  "Todo a la vista.": { "ca": "Tot a la vista.", "en": "All in view.", "zh": "一目了然。" },
  "Busca un artículo y consulta sus existencias por color, talla y almacén. El Control U de siempre, ahora en tu navegador.": {
    "ca": "Cerca un article i consulta'n les existències per color, talla i magatzem. El Control U de sempre, ara al teu navegador.",
    "en": "Find an item and check its stock by colour, size and warehouse. The Control U you know, now in your browser.",
    "zh": "搜索商品，按颜色、尺码和仓库查看库存。熟悉的 Control U，现在可在浏览器中使用。"
  },
  "Ejemplo ficticio de una consulta": {
    "ca": "Exemple fictici d'una consulta", "en": "Sample enquiry (fictitious)",
    "zh": "虚构的查询示例"
  },
  "Así se ve tu stock": {
    "ca": "Així es veu el teu estoc", "en": "This is how your stock looks",
    "zh": "您的库存是这样显示的"
  },
  "Ejemplo": { "ca": "Exemple", "en": "Example", "zh": "示例" },
  "Misma conexión local. Mismos permisos. Sin modificar tus datos.": {
    "ca": "La mateixa connexió local. Els mateixos permisos. Sense modificar les teves dades.",
    "en": "Same local connection. Same permissions. Your data is never changed.",
    "zh": "同样的本地连接，同样的权限，不会修改您的数据。"
  },
  "TU INSTALACIÓN": { "ca": "LA TEVA INSTAL·LACIÓ", "en": "YOUR INSTALLATION", "zh": "您的安装" },
  "Vamos a conectar": { "ca": "Connectem-nos", "en": "Let's connect", "zh": "开始连接" },
  "Entra con tu usuario y contraseña de ViraCash.": {
    "ca": "Entra amb el teu usuari i contrasenya de ViraCash.",
    "en": "Sign in with your ViraCash user and password.",
    "zh": "使用您的 ViraCash 用户和密码登录。"
  },
  "Nombre de la instalación": {
    "ca": "Nom de la instal·lació", "en": "Installation name", "zh": "安装名称"
  },
  "Pruebas": { "ca": "Proves", "en": "Test", "zh": "测试" },
  "Usuario ViraCash": { "ca": "Usuari ViraCash", "en": "ViraCash user", "zh": "ViraCash 用户" },
  "Contraseña": { "ca": "Contrasenya", "en": "Password", "zh": "密码" },
  "Ver": { "ca": "Mostra", "en": "Show", "zh": "显示" },
  "Ocultar": { "ca": "Amaga", "en": "Hide", "zh": "隐藏" },
  "Recordar acceso en este dispositivo": {
    "ca": "Recorda l'accés en aquest dispositiu", "en": "Remember sign-in on this device",
    "zh": "在此设备上记住登录"
  },
  "Hasta que caduque el token del servidor. Solo en un dispositivo personal.": {
    "ca": "Fins que caduqui el token del servidor. Només en un dispositiu personal.",
    "en": "Until the server token expires. Only on a personal device.",
    "zh": "直到服务器令牌过期。仅限个人设备。"
  },
  "Esta conexión HTTP no está cifrada. Úsala solo en una red interna de confianza.": {
    "ca": "Aquesta connexió HTTP no està xifrada. Fes-la servir només en una xarxa interna de confiança.",
    "en": "This HTTP connection is not encrypted. Use it only on a trusted internal network.",
    "zh": "此 HTTP 连接未加密，仅限在可信的内部网络中使用。"
  },
  "Entrar a Control U": {
    "ca": "Entra a Control U", "en": "Sign in to Control U", "zh": "登录 Control U"
  },
  "Cargando Control U… Si has abierto un archivo, entra por la dirección HTTP del servidor.": {
    "ca": "Carregant Control U… Si has obert un fitxer, entra per l'adreça HTTP del servidor.",
    "en": "Loading Control U… If you opened a file, use the server's HTTP address instead.",
    "zh": "正在加载 Control U… 如果您打开的是本地文件，请通过服务器的 HTTP 地址访问。"
  },
  "Servidor de esta página": {
    "ca": "Servidor d'aquesta pàgina", "en": "Server for this page", "zh": "本页面的服务器"
  },
  "Abre Control U desde la dirección HTTP de tu servidor, no desde el archivo index.html.": {
    "ca": "Obre Control U des de l'adreça HTTP del teu servidor, no des del fitxer index.html.",
    "en": "Open Control U from your server's HTTP address, not from the index.html file.",
    "zh": "请通过服务器的 HTTP 地址打开 Control U，而不是直接打开 index.html 文件。"
  },
  "No se ha podido iniciar Control U. Recarga la página y comprueba que se han copiado todos los archivos.": {
    "ca": "No s'ha pogut iniciar Control U. Torna a carregar la pàgina i comprova que s'han copiat tots els fitxers.",
    "en": "Control U could not start. Reload the page and check that all the files have been copied.",
    "zh": "无法启动 Control U。请刷新页面，并确认所有文件均已复制。"
  },
  "Comprobando el acceso…": {
    "ca": "Comprovant l'accés…", "en": "Checking sign-in…", "zh": "正在验证登录…"
  },
  "Acceso recuperado en este dispositivo. Caduca {fecha}.": {
    "ca": "Accés recuperat en aquest dispositiu. Caduca {fecha}.",
    "en": "Sign-in restored on this device. Expires {fecha}.",
    "zh": "已在此设备上恢复登录。到期时间：{fecha}。"
  },
  "Acceso guardado hasta {fecha}.": {
    "ca": "Accés desat fins {fecha}.", "en": "Sign-in saved until {fecha}.",
    "zh": "登录已保存至 {fecha}。"
  },
  "El navegador no permite guardar este acceso. Puedes consultar; al cerrar la página tendrás que volver a entrar.": {
    "ca": "El navegador no permet desar aquest accés. Pots consultar; quan tanquis la pàgina hauràs de tornar a entrar.",
    "en": "The browser does not allow this sign-in to be saved. You can carry on; when you close the page you will have to sign in again.",
    "zh": "浏览器不允许保存此登录。您可以继续查询；关闭页面后需要重新登录。"
  },
  "El acceso solo se mantiene mientras esta página siga abierta.": {
    "ca": "L'accés només es manté mentre aquesta pàgina continuï oberta.",
    "en": "Sign-in only lasts while this page stays open.",
    "zh": "登录仅在此页面保持打开时有效。"
  },
  "No se pudo borrar un acceso guardado anterior. Esta sesión funciona en memoria; elimina los datos de este sitio en el navegador para olvidar aquel acceso.": {
    "ca": "No s'ha pogut esborrar un accés desat anterior. Aquesta sessió funciona en memòria; elimina les dades d'aquest lloc al navegador per oblidar aquell accés.",
    "en": "A previously saved sign-in could not be deleted. This session runs in memory; clear this site's data in the browser to forget that sign-in.",
    "zh": "无法删除之前保存的登录。本次会话仅保存在内存中；请在浏览器中清除此网站的数据以忘记该登录。"
  },
  "No se pudo borrar el guardado: elimina los datos de este sitio en el navegador.": {
    "ca": "No s'ha pogut esborrar l'accés desat: elimina les dades d'aquest lloc al navegador.",
    "en": "The saved sign-in could not be deleted: clear this site's data in the browser.",
    "zh": "无法删除已保存的登录：请在浏览器中清除此网站的数据。"
  },
  "Sesión cerrada. El acceso guardado se ha eliminado.": {
    "ca": "Sessió tancada. S'ha eliminat l'accés desat.",
    "en": "Signed out. The saved sign-in has been deleted.",
    "zh": "已退出登录。已删除保存的登录。"
  },
  "El acceso ha cambiado en otra pestaña. Vuelve a entrar.": {
    "ca": "L'accés ha canviat en una altra pestanya. Torna a entrar.",
    "en": "Sign-in changed in another tab. Sign in again.",
    "zh": "登录已在其他标签页中更改，请重新登录。"
  },
  "El acceso ha caducado. Vuelve a entrar con tu usuario de ViraCash.": {
    "ca": "L'accés ha caducat. Torna a entrar amb el teu usuari de ViraCash.",
    "en": "Your sign-in has expired. Sign in again with your ViraCash user.",
    "zh": "登录已过期，请使用您的 ViraCash 用户重新登录。"
  },
  "El acceso ha caducado. Vuelve a entrar.": {
    "ca": "L'accés ha caducat. Torna a entrar.",
    "en": "Your sign-in has expired. Sign in again.", "zh": "登录已过期，请重新登录。"
  },

  // Consulta.
  "Consulta tu stock": { "ca": "Consulta el teu estoc", "en": "Check your stock", "zh": "查询库存" },
  "Artículo, SKU o código de barras. Todo desde la red de tu tienda.": {
    "ca": "Article, SKU o codi de barres. Tot des de la xarxa de la teva botiga.",
    "en": "Item, SKU or barcode. All from your shop's network.",
    "zh": "商品、SKU 或条形码。全部通过门店网络完成。"
  },
  "CONTROL U": { "ca": "CONTROL U", "en": "CONTROL U", "zh": "CONTROL U" },
  "Artículo, SKU o código de barras": {
    "ca": "Article, SKU o codi de barres", "en": "Item, SKU or barcode",
    "zh": "商品、SKU 或条形码"
  },
  "Artículo, SKU o código de barras…": {
    "ca": "Article, SKU o codi de barres…", "en": "Item, SKU or barcode…",
    "zh": "商品、SKU 或条形码…"
  },
  "Consultar": { "ca": "Consulta", "en": "Look up", "zh": "查询" },
  "Escribe el código o utiliza un lector externo que lo introduzca como un teclado.": {
    "ca": "Escriu el codi o fes servir un lector extern que l'introdueixi com un teclat.",
    "en": "Type the code or use an external scanner that enters it like a keyboard.",
    "zh": "输入代码，或使用以键盘方式输入的外接扫描枪。"
  },
  "Tipo de consulta": { "ca": "Tipus de consulta", "en": "Query type", "zh": "查询类型" },
  "Stock": { "ca": "Estoc", "en": "Stock", "zh": "库存" },
  "Entradas": { "ca": "Entrades", "en": "Receipts in", "zh": "入库" },
  "Ventas": { "ca": "Vendes", "en": "Sales", "zh": "销售" },
  "Ptes. de recibir": { "ca": "Pend. de rebre", "en": "To receive", "zh": "待收" },
  "Introduce un código para consultar.": {
    "ca": "Introdueix un codi per consultar.", "en": "Enter a code to look it up.",
    "zh": "请输入代码进行查询。"
  },
  "Artículo anterior": { "ca": "Article anterior", "en": "Previous item", "zh": "上一个商品" },
  "Artículo siguiente": { "ca": "Article següent", "en": "Next item", "zh": "下一个商品" },
  "↻ Actualizar": { "ca": "↻ Actualitza", "en": "↻ Refresh", "zh": "↻ 刷新" },
  "¿Qué artículo necesitas?": {
    "ca": "Quin article necessites?", "en": "Which item do you need?", "zh": "您需要哪个商品？"
  },
  "Escribe su referencia o utiliza un lector de códigos de barras.": {
    "ca": "Escriu-ne la referència o fes servir un lector de codis de barres.",
    "en": "Type its reference or use a barcode scanner.",
    "zh": "输入其编号，或使用条形码扫描枪。"
  },
  "Indica un artículo, SKU o código de barras de hasta 50 caracteres.": {
    "ca": "Indica un article, SKU o codi de barres de fins a 50 caràcters.",
    "en": "Enter an item, SKU or barcode of up to 50 characters.",
    "zh": "请输入不超过 50 个字符的商品、SKU 或条形码。"
  },
  "Consultando {codigo}…": {
    "ca": "Consultant {codigo}…", "en": "Looking up {codigo}…", "zh": "正在查询 {codigo}…"
  },
  "Actualizado a las {hora}": {
    "ca": "Actualitzat a les {hora}", "en": "Updated at {hora}", "zh": "更新于 {hora}"
  },
  "Consulta no disponible.": {
    "ca": "Consulta no disponible.", "en": "Enquiry not available.", "zh": "查询不可用。"
  },

  // Resultado, filtros y tabla.
  "Filtrar la consulta": { "ca": "Filtra la consulta", "en": "Filter the enquiry", "zh": "筛选查询" },
  "Colores": { "ca": "Colors", "en": "Colours", "zh": "颜色" },
  "Almacenes": { "ca": "Magatzems", "en": "Warehouses", "zh": "仓库" },
  "Todos": { "ca": "Tots", "en": "All", "zh": "全部" },
  "Ninguno": { "ca": "Cap", "en": "None", "zh": "全不选" },
  "Habituales": { "ca": "Habituals", "en": "Usual", "zh": "常用" },
  "Cada cuadradito muestra el color básico de ViraCash. El cuadrado rayado indica que no hay un tono definido.": {
    "ca": "Cada quadradet mostra el color bàsic de ViraCash. El quadrat ratllat indica que no hi ha cap to definit.",
    "en": "Each small square shows the ViraCash basic colour. A striped square means no shade is defined.",
    "zh": "每个小方块显示 ViraCash 的基本颜色。条纹方块表示未定义色调。"
  },
  "Agrupar por": { "ca": "Agrupa per", "en": "Group by", "zh": "分组方式" },
  "Color": { "ca": "Color", "en": "Colour", "zh": "颜色" },
  "Almacén": { "ca": "Magatzem", "en": "Warehouse", "zh": "仓库" },
  "Ocultar tallas sin cantidad": {
    "ca": "Amaga les talles sense quantitat", "en": "Hide sizes without quantity",
    "zh": "隐藏无数量的尺码"
  },
  "Filtros": { "ca": "Filtres", "en": "Filters", "zh": "筛选" },
  "en almacenes seleccionados": {
    "ca": "en els magatzems seleccionats", "en": "in selected warehouses",
    "zh": "所选仓库中"
  },
  "Ampliar foto del artículo": {
    "ca": "Amplia la foto de l'article", "en": "Enlarge item photo", "zh": "放大商品照片"
  },
  "Sin foto": { "ca": "Sense foto", "en": "No photo", "zh": "无照片" },
  "Ampliar foto ↗": { "ca": "Amplia la foto ↗", "en": "Enlarge photo ↗", "zh": "放大照片 ↗" },
  "Cargando foto…": { "ca": "Carregant la foto…", "en": "Loading photo…", "zh": "正在加载照片…" },
  "Foto no disponible": { "ca": "Foto no disponible", "en": "Photo not available", "zh": "照片不可用" },
  "Foto del artículo": { "ca": "Foto de l'article", "en": "Item photo", "zh": "商品照片" },
  "Cerrar foto": { "ca": "Tanca la foto", "en": "Close photo", "zh": "关闭照片" },
  "Artículo": { "ca": "Article", "en": "Item", "zh": "商品" },
  "Artículo sin descripción": {
    "ca": "Article sense descripció", "en": "Item without description", "zh": "无描述的商品"
  },
  "Cantidades por talla, desplazable horizontalmente": {
    "ca": "Quantitats per talla, desplaçable horitzontalment",
    "en": "Quantities by size, scrolls horizontally", "zh": "按尺码的数量，可横向滚动"
  },
  "Existencias del artículo por talla": {
    "ca": "Existències de l'article per talla", "en": "Item stock by size",
    "zh": "商品按尺码的库存"
  },
  "{estado} de {articulo} por talla": {
    "ca": "{estado} de {articulo} per talla", "en": "{estado} for {articulo} by size",
    "zh": "{articulo} 按尺码的{estado}"
  },
  "No hay cantidades con estos filtros.": {
    "ca": "No hi ha quantitats amb aquests filtres.", "en": "No quantities with these filters.",
    "zh": "这些筛选条件下没有数量。"
  },
  "Sin cantidades para este artículo en esta consulta.": {
    "ca": "Sense quantitats per a aquest article en aquesta consulta.",
    "en": "No quantities for this item in this enquiry.", "zh": "此查询中该商品没有数量。"
  },
  "Sin datos con los filtros seleccionados.": {
    "ca": "Sense dades amb els filtres seleccionats.", "en": "No data with the selected filters.",
    "zh": "所选筛选条件下没有数据。"
  },
  "Pulsa una fila para ver el detalle. Desliza la tabla para consultar más tallas.": {
    "ca": "Prem una fila per veure'n el detall. Llisca la taula per consultar més talles.",
    "en": "Tap a row to see the detail. Swipe the table to see more sizes.",
    "zh": "点击一行查看明细。左右滑动表格可查看更多尺码。"
  },
  "{unidad} · Cantidad de esta variante: {cantidad}": {
    "ca": "{unidad} · Quantitat d'aquesta variant: {cantidad}",
    "en": "{unidad} · Quantity of this variant: {cantidad}",
    "zh": "{unidad} · 此款式数量：{cantidad}"
  },
  "{colores} de {totalColores} colores · {almacenes} de {totalAlmacenes} almacenes": {
    "ca": "{colores} de {totalColores} colors · {almacenes} de {totalAlmacenes} magatzems",
    "en": "{colores} of {totalColores} colours · {almacenes} of {totalAlmacenes} warehouses",
    "zh": "颜色 {colores}/{totalColores} · 仓库 {almacenes}/{totalAlmacenes}"
  },
  "Color / almacén": { "ca": "Color / magatzem", "en": "Colour / warehouse", "zh": "颜色 / 仓库" },
  "Almacén / color": { "ca": "Magatzem / color", "en": "Warehouse / colour", "zh": "仓库 / 颜色" },
  "Sin talla": { "ca": "Sense talla", "en": "No size", "zh": "无尺码" },
  "Sin definir": { "ca": "Sense definir", "en": "Not defined", "zh": "未定义" },
  "Total": { "ca": "Total", "en": "Total", "zh": "合计" },
  "Total visible": { "ca": "Total visible", "en": "Visible total", "zh": "可见合计" },
  "Básico: {nombre}": { "ca": "Bàsic: {nombre}", "en": "Basic: {nombre}", "zh": "基本色：{nombre}" },
  "Básico: {nombre} (sin tono definido)": {
    "ca": "Bàsic: {nombre} (sense to definit)", "en": "Basic: {nombre} (no shade defined)",
    "zh": "基本色：{nombre}（未定义色调）"
  },
  "Sin básico asignado": {
    "ca": "Sense bàsic assignat", "en": "No basic colour assigned", "zh": "未分配基本色"
  },

  // Diálogos.
  "AFINA LA CONSULTA": { "ca": "AFINA LA CONSULTA", "en": "REFINE THE ENQUIRY", "zh": "细化查询" },
  "Colores y almacenes": { "ca": "Colors i magatzems", "en": "Colours and warehouses", "zh": "颜色和仓库" },
  "Cerrar filtros": { "ca": "Tanca els filtres", "en": "Close filters", "zh": "关闭筛选" },
  "Depósitos, taras y tránsito empiezan desmarcados, como en Control U.": {
    "ca": "Dipòsits, tares i trànsit comencen desmarcats, com a Control U.",
    "en": "Consignment, faulty and in-transit warehouses start unticked, as in Control U.",
    "zh": "寄售、残次和在途仓库默认不勾选，与 Control U 一致。"
  },
  "Restablecer": { "ca": "Restableix", "en": "Reset", "zh": "重置" },
  "Aplicar filtros": { "ca": "Aplica els filtres", "en": "Apply filters", "zh": "应用筛选" },
  "Cerrar conexión": { "ca": "Tanca la connexió", "en": "Close connection", "zh": "关闭连接" },
  "Instalación": { "ca": "Instal·lació", "en": "Installation", "zh": "安装" },
  "Usuario": { "ca": "Usuari", "en": "User", "zh": "用户" },
  "Servidor local": { "ca": "Servidor local", "en": "Local server", "zh": "本地服务器" },
  "Acceso válido hasta": { "ca": "Accés vàlid fins", "en": "Sign-in valid until", "zh": "登录有效期至" },
  "Se conserva la duración del hook actual. La web no guarda tu contraseña ni puede renovar el acceso por su cuenta.": {
    "ca": "Es manté la durada del hook actual. La web no desa la teva contrasenya ni pot renovar l'accés pel seu compte.",
    "en": "The current hook's duration is kept. The web app does not store your password and cannot renew sign-in by itself.",
    "zh": "沿用当前 hook 的有效期。网页不会保存您的密码，也无法自行续期登录。"
  },
  "Cerrar sesión y olvidar este acceso": {
    "ca": "Tanca la sessió i oblida aquest accés", "en": "Sign out and forget this sign-in",
    "zh": "退出登录并忘记此登录"
  },

  // Errores del cliente y del hook.
  "Abre Control U desde la dirección de tu servidor local.": {
    "ca": "Obre Control U des de l'adreça del teu servidor local.",
    "en": "Open Control U from your local server's address.",
    "zh": "请通过本地服务器的地址打开 Control U。"
  },
  "Indica un usuario y una contraseña válidos.": {
    "ca": "Indica un usuari i una contrasenya vàlids.", "en": "Enter a valid user and password.",
    "zh": "请输入有效的用户和密码。"
  },
  "El hook no ha devuelto un acceso válido.": {
    "ca": "El hook no ha retornat un accés vàlid.", "en": "The hook did not return a valid sign-in.",
    "zh": "hook 未返回有效的登录。"
  },
  "Indica un artículo, SKU o código de barras válido.": {
    "ca": "Indica un article, SKU o codi de barres vàlid.",
    "en": "Enter a valid item, SKU or barcode.", "zh": "请输入有效的商品、SKU 或条形码。"
  },
  "El hook devolvió un tipo de consulta distinto al solicitado. Comprueba su versión.": {
    "ca": "El hook ha retornat un tipus de consulta diferent del sol·licitat. Comprova'n la versió.",
    "en": "The hook returned a different query type from the one requested. Check its version.",
    "zh": "hook 返回的查询类型与请求的不一致，请检查其版本。"
  },
  "La ruta de la foto no pertenece a este hook.": {
    "ca": "La ruta de la foto no pertany a aquest hook.",
    "en": "The photo path does not belong to this hook.", "zh": "照片路径不属于此 hook。"
  },
  "El hook no ha enviado una foto PNG válida.": {
    "ca": "El hook no ha enviat una foto PNG vàlida.", "en": "The hook did not send a valid PNG photo.",
    "zh": "hook 未发送有效的 PNG 照片。"
  },
  "La foto está vacía o supera los 4 MiB.": {
    "ca": "La foto és buida o supera els 4 MiB.", "en": "The photo is empty or exceeds 4 MiB.",
    "zh": "照片为空或超过 4 MiB。"
  },
  "El servidor no pudo atender la consulta (HTTP {estado}).": {
    "ca": "El servidor no ha pogut atendre la consulta (HTTP {estado}).",
    "en": "The server could not handle the request (HTTP {estado}).",
    "zh": "服务器无法处理该请求（HTTP {estado}）。"
  },
  "La respuesta del hook es demasiado grande.": {
    "ca": "La resposta del hook és massa gran.", "en": "The hook's response is too large.",
    "zh": "hook 的响应过大。"
  },
  "El hook no devolvió JSON. Comprueba la dirección y la configuración del servidor.": {
    "ca": "El hook no ha retornat JSON. Comprova l'adreça i la configuració del servidor.",
    "en": "The hook did not return JSON. Check the address and the server configuration.",
    "zh": "hook 未返回 JSON，请检查地址和服务器配置。"
  },
  "No se pudo conectar. Comprueba el servidor y que estás en la red de la tienda.": {
    "ca": "No s'ha pogut connectar. Comprova el servidor i que ets a la xarxa de la botiga.",
    "en": "Could not connect. Check the server and that you are on the shop's network.",
    "zh": "无法连接。请检查服务器，并确认您处于门店网络中。"
  },
  "La estructura de la respuesta del hook no es válida.": {
    "ca": "L'estructura de la resposta del hook no és vàlida.",
    "en": "The structure of the hook's response is not valid.", "zh": "hook 响应的结构无效。"
  },
  "El hook no ha enviado una consulta de Control U válida.": {
    "ca": "El hook no ha enviat una consulta de Control U vàlida.",
    "en": "The hook did not send a valid Control U enquiry.", "zh": "hook 未发送有效的 Control U 查询结果。"
  },
  "Detalle de colores no válido.": {
    "ca": "Detall de colors no vàlid.", "en": "Invalid colour detail.", "zh": "颜色明细无效。"
  },
  "Detalle de tallas no válido.": {
    "ca": "Detall de talles no vàlid.", "en": "Invalid size detail.", "zh": "尺码明细无效。"
  },
  "La consulta contiene una cantidad no válida.": {
    "ca": "La consulta conté una quantitat no vàlida.", "en": "The enquiry contains an invalid quantity.",
    "zh": "查询结果包含无效数量。"
  },
  "La variante consultada tiene una cantidad no válida.": {
    "ca": "La variant consultada té una quantitat no vàlida.",
    "en": "The variant looked up has an invalid quantity.", "zh": "所查询的款式数量无效。"
  },
  "Usuario o contraseña no válidos.": {
    "ca": "Usuari o contrasenya no vàlids.", "en": "Invalid user or password.", "zh": "用户或密码无效。"
  },
  "No existe el artículo indicado.": {
    "ca": "No existeix l'article indicat.", "en": "The item entered does not exist.",
    "zh": "所输入的商品不存在。"
  },
  "El artículo no tiene foto de 300 px.": {
    "ca": "L'article no té foto de 300 px.", "en": "The item has no 300 px photo.",
    "zh": "该商品没有 300 px 照片。"
  },
  "La foto supera el límite permitido.": {
    "ca": "La foto supera el límit permès.", "en": "The photo exceeds the allowed limit.",
    "zh": "照片超过允许的大小限制。"
  },
  "El estado de la consulta no es válido.": {
    "ca": "L'estat de la consulta no és vàlid.", "en": "The query status is not valid.",
    "zh": "查询状态无效。"
  },
  "Método HTTP no permitido.": {
    "ca": "Mètode HTTP no permès.", "en": "HTTP method not allowed.", "zh": "不允许的 HTTP 方法。"
  },
  "La petición es demasiado grande.": {
    "ca": "La petició és massa gran.", "en": "The request is too large.", "zh": "请求过大。"
  },
  "El cuerpo JSON no es válido.": {
    "ca": "El cos JSON no és vàlid.", "en": "The JSON body is not valid.", "zh": "JSON 请求体无效。"
  },
  "Falta el acceso o no es válido. Vuelve a entrar.": {
    "ca": "Falta l'accés o no és vàlid. Torna a entrar.",
    "en": "Sign-in is missing or not valid. Sign in again.", "zh": "缺少登录或登录无效，请重新登录。"
  },
  "El acceso no es válido. Vuelve a entrar.": {
    "ca": "L'accés no és vàlid. Torna a entrar.", "en": "Your sign-in is not valid. Sign in again.",
    "zh": "登录无效，请重新登录。"
  },
  "El acceso ya no está autorizado.": {
    "ca": "L'accés ja no està autoritzat.", "en": "Access is no longer authorised.",
    "zh": "访问已不再获得授权。"
  },
  "Demasiados intentos de acceso. Espera antes de reintentarlo.": {
    "ca": "Massa intents d'accés. Espera abans de tornar-ho a provar.",
    "en": "Too many sign-in attempts. Wait before trying again.", "zh": "登录尝试次数过多，请稍后再试。"
  },
  "El usuario no tiene permiso para consultar el stock.": {
    "ca": "L'usuari no té permís per consultar l'estoc.", "en": "The user is not allowed to view stock.",
    "zh": "该用户无权查询库存。"
  },
  "No se pudo completar la operación.": {
    "ca": "No s'ha pogut completar l'operació.", "en": "The operation could not be completed.",
    "zh": "无法完成操作。"
  },
};

export const CLAVES = Object.freeze(Object.keys(DICCIONARIO));
export const IDIOMAS_TRADUCIDOS = Object.freeze(["ca", "en", "zh"]);
export const tieneClave = (clave) => Object.hasOwn(DICCIONARIO, clave);
export const traduccionesDe = (clave) => DICCIONARIO[clave] || null;

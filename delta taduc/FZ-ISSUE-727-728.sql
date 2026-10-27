-- Delta de traducciones FZ-ISSUE-727 / FZ-ISSUE-728.
-- FZ-ISSUE-728 no necesita filas nuevas: reutiliza las traducciones de
-- inLibMsgCompras.SRotuloEjeFilaVariacionSesion / SRotuloEjePivoteVariacionSesion.
-- Tras aplicarlo: utlTraduc > «Sincronizar español» para sembrar es-ES
-- de las dos claves nuevas de inLibMsgCompras.
INSERT INTO fza_traducciones (
  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,
  ESACTIVO_TRAD, INSTANTE_ALTA, USUARIO_ALTA
) VALUES
 ('inMtoModalIncidencias.TfrmModalIncidencias.Caption', 'en-GB',
  'Issues', 'src/Modals/inMtoModalIncidencias.dfm', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inMtoModalIncidencias.TfrmModalIncidencias.Caption', 'zh-CN',
  '问题', 'src/Modals/inMtoModalIncidencias.dfm', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloIncidenciasMaterializacionSesionCompra', 'ca-ES',
  'Hi ha incidències que impedeixen materialitzar la sessió:', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloIncidenciasMaterializacionSesionCompra', 'en-GB',
  'There are issues preventing the session from being materialised:', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloIncidenciasMaterializacionSesionCompra', 'zh-CN',
  '存在问题，无法生成该会话：', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloErrorMaterializacionSesionCompra', 'ca-ES',
  'No s''ha pogut materialitzar la sessió:', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloErrorMaterializacionSesionCompra', 'en-GB',
  'The session could not be materialised:', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727'),
 ('inLibMsgCompras.STituloErrorMaterializacionSesionCompra', 'zh-CN',
  '无法生成该会话：', 'src/Lib/inLibMsgCompras.pas', 'S', CURRENT_TIMESTAMP, 'FZ-ISSUE-727')
ON DUPLICATE KEY UPDATE
  TEXTO_TRAD = VALUES(TEXTO_TRAD),
  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),
  ESACTIVO_TRAD = 'S',
  INSTANTE_MODIF = CURRENT_TIMESTAMP,
  USUARIO_MODIF = VALUES(USUARIO_ALTA);

unit UNormalizerEngine;

{
  Motor de normalización de la base de datos ViraCash.
  Aplica el libro de estilo v1.0 a un fichero SQL de volcado y produce:
    - Un plan de renombrado (lista de TColumnRename)
    - Un script SQL de ALTER TABLE … CHANGE COLUMN
    - Un script SQL de renombrado de índices

  No tiene dependencias de VCL. Se puede invocar desde cualquier UI.
}

interface

uses
  System.Classes, System.SysUtils, System.RegularExpressions,
  System.Generics.Collections, System.Generics.Defaults;

type
  TColumnRename = record
    TableName:    string;
    OldName:      string;
    NewName:      string;
    Definition:   string;  // tipo + atributos (ej: "varchar(20) NOT NULL")
    Changed:      Boolean;
  end;

  TColumnList = TList<TColumnRename>;

  TIndexRename = record
    TableName: string;
    OldName:   string;
    NewName:   string;
    Columns:   TArray<string>;  // ya con los nombres NUEVOS
    IsUnique:  Boolean;
  end;

  TIndexList = TList<TIndexRename>;

  // Pareja (clave, valor) para configuración editable por el usuario
  TKVPair = record
    Key:   string;
    Value: string;
    constructor Create(const AKey, AValue: string);
  end;

  // Excepción: tabla + columna_vieja → columna_nueva
  TExceptionEntry = record
    TableName: string;
    OldColumn: string;
    NewColumn: string;
    constructor Create(const ATable, AOld, ANew: string);
  end;

  TViraCashNormalizer = class
  private
    FTableSuffixes:  TDictionary<string, string>;        // tabla → sufijo
    FConceptToSuffix: TDictionary<string, string>;       // ARTICULO → ART
    FOwnConcepts:    TDictionary<string, TStringList>;   // tabla → set de palabras "concepto propio"
    FAuditRenames:   TDictionary<string, string>;        // INSTANTEALTA → INSTANTE_ALTA
    FAbbreviations:  TList<TKVPair>;                     // lista ordenada de (regex, reemplazo)
    FExceptions:     TList<TExceptionEntry>;             // overrides absolutos
    FLegacySuffixes: TStringList;                        // tokens a barrer del final
    FFKPrefixes:     TStringList;                        // CODIGO, ID, NOMBRE, SERIE, NUMERO, NRO

    procedure InitDefaults;
    procedure ClearOwnConcepts;
    function  ExpandAbbreviations(const Name: string): string;
    function  NormalizeBoolean(const Name: string): string;
    function  StripOwnConcept(const Name, TableName: string): string;
    function  StripLegacyTailTokens(const Name: string): string;
    function  ReplaceFKConcepts(const Core: string): string;
    function  GetFinalNewName(const TableName, OldName: string): string;
    function  GetTableSuffix(const TableName: string): string;
    function  TryGetException(const TableName, OldName: string; out NewName: string): Boolean;
    function  ParseDefinitionLine(const Line: string; out ColName, Definition: string): Boolean;
  public
    constructor Create;
    destructor  Destroy; override;

    // === Configuración ===
    procedure ResetToDefaults;
    procedure SetTableSuffix(const TableName, Suffix: string);
    procedure SetAuditRename(const Old, New: string);
    procedure AddAbbreviation(const RegexPattern, Replacement: string);
    procedure ClearAbbreviations;
    procedure AddException(const TableName, OldColumn, NewColumn: string);
    procedure ClearExceptions;
    procedure AddOwnConcept(const TableName, Concept: string);

    // Acceso para que la UI pueda mostrar/editar
    property TableSuffixes:  TDictionary<string, string> read FTableSuffixes;
    property AuditRenames:   TDictionary<string, string> read FAuditRenames;
    property Abbreviations:  TList<TKVPair> read FAbbreviations;
    property Exceptions:     TList<TExceptionEntry> read FExceptions;

    // === Procesamiento principal ===
    {
      Lee el SQL de volcado y genera el plan de renombrado + el plan de índices.
      OnLog se invoca con mensajes informativos / advertencias.
    }
    procedure GeneratePlan(const SourceSQL: string;
                           AColumnPlan: TColumnList;
                           AIndexPlan: TIndexList;
                           const OnLog: TProc<string> = nil);

    // === Generación de salidas ===
    function  BuildColumnRenameSQL(AColumnPlan: TColumnList): string;
    function  BuildIndexRenameSQL(AIndexPlan: TIndexList): string;
    function  BuildPlanCSV(AColumnPlan: TColumnList): string;
  end;

implementation

uses
  System.StrUtils;

{ TKVPair }

constructor TKVPair.Create(const AKey, AValue: string);
begin
  Key   := AKey;
  Value := AValue;
end;

{ TExceptionEntry }

constructor TExceptionEntry.Create(const ATable, AOld, ANew: string);
begin
  TableName := ATable;
  OldColumn := AOld;
  NewColumn := ANew;
end;

{ TViraCashNormalizer }

constructor TViraCashNormalizer.Create;
begin
  inherited Create;
  FTableSuffixes   := TDictionary<string, string>.Create;
  FConceptToSuffix := TDictionary<string, string>.Create;
  FOwnConcepts     := TDictionary<string, TStringList>.Create;
  FAuditRenames    := TDictionary<string, string>.Create;
  FAbbreviations   := TList<TKVPair>.Create;
  FExceptions      := TList<TExceptionEntry>.Create;
  FLegacySuffixes  := TStringList.Create;
  FLegacySuffixes.CaseSensitive := True;
  FLegacySuffixes.Sorted        := True;
  FLegacySuffixes.Duplicates    := dupIgnore;
  FFKPrefixes      := TStringList.Create;
  FFKPrefixes.CaseSensitive := True;

  InitDefaults;
end;

destructor TViraCashNormalizer.Destroy;
begin
  ClearOwnConcepts;
  FTableSuffixes.Free;
  FConceptToSuffix.Free;
  FOwnConcepts.Free;
  FAuditRenames.Free;
  FAbbreviations.Free;
  FExceptions.Free;
  FLegacySuffixes.Free;
  FFKPrefixes.Free;
  inherited;
end;

procedure TViraCashNormalizer.ClearOwnConcepts;
var
  L: TStringList;
begin
  for L in FOwnConcepts.Values do
    L.Free;
  FOwnConcepts.Clear;
end;

procedure TViraCashNormalizer.ResetToDefaults;
begin
  FTableSuffixes.Clear;
  FConceptToSuffix.Clear;
  ClearOwnConcepts;
  FAuditRenames.Clear;
  FAbbreviations.Clear;
  FExceptions.Clear;
  FLegacySuffixes.Clear;
  FFKPrefixes.Clear;
  InitDefaults;
end;

procedure TViraCashNormalizer.InitDefaults;

  procedure AddSuf(const T, S: string);
  begin
    FTableSuffixes.AddOrSetValue(T, S);
  end;

  procedure AddOwn(const T: string; const Words: array of string);
  var
    L: TStringList;
    W: string;
  begin
    if not FOwnConcepts.TryGetValue(T, L) then
    begin
      L := TStringList.Create;
      L.CaseSensitive := True;
      L.Sorted := True;
      L.Duplicates := dupIgnore;
      FOwnConcepts.Add(T, L);
    end;
    for W in Words do
      L.Add(W);
  end;

begin
  AddSuf('fza_presupuestos', 'PRE');
  AddSuf('fza_presupuestos_lineas', 'PRELIN');
  AddSuf('fza_presupuestos_celdas', 'PRECEL');
  AddOwn('fza_presupuestos', ['PRESUPUESTO']);
  AddOwn('fza_presupuestos_lineas', ['LINEA_PRESUPUESTO']);
  AddOwn('fza_presupuestos_celdas', ['CELDA_PRESUPUESTO']);
  // ========== Sufijos de tabla ==========
  AddSuf('fza_almacenes',                       'ALM');
  AddSuf('fza_almacenes_cajas',                 'ALMCAJ');
  AddSuf('fza_articulos',                       'ART');
  AddSuf('fza_articulos_cambios_historico',     'ACH');
  AddSuf('fza_articulos_conjuntos_asign',       'ACA');
  AddSuf('fza_articulos_familias',              'FAM');
  AddSuf('fza_articulos_lotes',                 'LOT');
  AddSuf('fza_lotes_retiradas',                 'LRET');
  AddSuf('fza_articulos_propiedades',           'ARTPROP');
  AddSuf('fza_articulos_proveedores',           'AP');
  AddSuf('fza_articulos_skus',                  'SKU');
  AddSuf('fza_articulos_skus_costes',           'SKUC');
  AddSuf('fza_articulos_stockactual',           'STK');
  AddSuf('fza_articulos_tarifas',               'ARTTAR');
  AddSuf('fza_articulos_vinculos',              'ARTVIN');
  AddSuf('fza_atributos_basicos',               'ATB');
  AddSuf('fza_atributos_conjuntos',             'AC');
  AddSuf('fza_atributos_conjuntos_det',         'ACD');
  AddSuf('fza_atributos_sku',                   'SA');
  AddSuf('fza_atributos_valores',               'AV');
  AddSuf('fza_atributos_valores_info',          'AVI');
  AddSuf('fza_bancos',                          'BAN');
  AddSuf('fza_caja_formas_pago',                'CFP');
  AddSuf('fza_caja_operaciones',                'OPCAJA');
  AddSuf('fza_caja_pagos',                      'PAGO');
  AddSuf('fza_caja_subsanaciones',              'CJSUB');
  AddSuf('fza_caja_vales',                      'VL');
  AddSuf('fza_clientes',                        'CLI');
  AddSuf('fza_codigos_barras',                  'CB');
  AddSuf('fza_config_campos',                   'CC');
  AddSuf('fza_contadores',                      'CON');
  AddSuf('fza_depositos_cliente',               'DEP');
  AddSuf('fza_documentos_trabajo_compartidos',  'DTC');
  AddSuf('fza_documentos_trabajo',              'DTR');
  AddSuf('fza_documentos_trabajo_lineas',       'DTL');
  AddSuf('fza_efectos_compra',                  'EFEC');
  AddSuf('fza_efectos_venta',                   'EFV');
  AddSuf('fza_empleados',                       'EMPL');
  AddSuf('fza_errores_envios',                  'ERENV');
  AddSuf('fza_empresas',                        'EMP');
  AddSuf('fza_empresas_bancos',                 'EMPBAN');
  AddSuf('fza_empresas_retenciones',            'EMPRET');
  AddSuf('fza_empresas_series',                 'EMPSER');
  AddSuf('fza_facturacion_caja_periodos',       'FACPER');
  AddSuf('fza_facturas',                        'FAC');
  AddSuf('fza_facturas_compra',                 'FACC');
  AddSuf('fza_facturas_compra_celdas',          'FACCCEL');
  AddSuf('fza_facturas_compra_lineas',          'FACCLIN');
  AddSuf('fza_facturas_consolidaciones',        'FACCON');
  AddSuf('fza_facturas_lineas',                 'FACLIN');
  AddSuf('fza_facturas_operaciones_caja',       'FACOP');
  AddSuf('fza_facturas_pagos',                  'FACPAG');
  AddSuf('fza_facturas_traspasos_vendidos',     'FACTV');
  AddSuf('fza_familias_atributos',              'FA');
  AddSuf('fza_familias_atributos_defecto',      'FAD');
  AddSuf('fza_familias_claves_info_defecto',    'FCI');
  AddSuf('fza_filtros_guardados',               'FILT');
  AddSuf('fza_filtros_guardados_compartidos',   'FILTC');
  AddSuf('fza_formas_pago',                     'FP');
  AddSuf('fza_generadorprocesos',               'GP');
  AddSuf('fza_inventarios',                     'INV');
  AddSuf('fza_inventarios_lineas',              'INVLIN');
  AddSuf('fza_inventarios_recuentos',           'INVREC');
  AddSuf('fza_ivas',                            'IVA');
  AddSuf('fza_ivas_grupos',                     'IVAGRP');
  AddSuf('fza_ivas_tipos',                      'IVATIP');
  AddSuf('fza_ivas_zonas',                      'IVAZON');
  AddSuf('fza_metadatos',                       'META');
  AddSuf('fza_movimientos_almacen',             'MOV');
  AddSuf('fza_movimientos_recalculos_pendientes','MOVREC');
  AddSuf('fza_paises',                          'PAI');
  AddSuf('fza_pedidos',                         'PED');
  AddSuf('fza_pedidos_lineas',                  'PEDLIN');
  AddSuf('fza_pedidos_mensajes',                'PEDMSG');
  AddSuf('fza_prestashop_cola',                 'PSCOLA');
  AddSuf('fza_prestashop_cola_eventos',         'PSCEV');
  AddSuf('fza_propiedades',                     'PROP');
  AddSuf('fza_propiedades_valores',             'PV');
  AddSuf('fza_proformas_caja',                  'PROCAJ');
  AddSuf('fza_proformas_caja_lineas',           'PROCLIN');
  AddSuf('fza_proformas_caja_vales',            'PROCVL');
  AddSuf('fza_proveedores',                     'PRV');
  AddSuf('fza_proveedores_familias',            'PF');
  AddSuf('fza_proveedores_familias_conjuntos',  'PFC');
  AddSuf('fza_recibos',                         'REC');
  AddSuf('fza_remesas_compra',                  'REMC');
  AddSuf('fza_remesas_venta',                   'REMV');
  AddSuf('fza_stock_bloqueos',                  'STKBLQ');
  AddSuf('fza_tarifas_periodos', 'TPER');
  AddOwn('fza_tarifas_periodos', ['TARIFA', 'PERIODO']);
  AddSuf('fza_tarifas',                         'TAR');
  AddSuf('fza_tarifas_cambios',                 'TARC');
  AddSuf('fza_tarifas_cambios_lineas',          'TARCLIN');
  AddSuf('fza_tarifas_descuento_condiciones',   'TARDCO');
  AddSuf('fza_tarifas_descuento_valores',       'TARDVA');
  AddSuf('fza_tipos_documentos',                'TD');
  AddSuf('fza_tipos_efecto',                    'TEFE');
  AddSuf('fza_traducciones',                    'TRAD');
  AddSuf('fza_traspasos_propuestas',            'TRPRO');
  AddSuf('fza_traspasos_propuestas_lineas',     'TRPROLIN');
  AddSuf('fza_traspasos_solicitudes',           'TRSOL');
  AddSuf('fza_traspasos_solicitudes_lineas',    'TRSOLLIN');
  AddSuf('fza_traspasos_transito',              'TRTRA');
  AddSuf('fza_traspasos_transito_incidencias',  'TRTINC');
  AddSuf('fza_unidades_medida',                 'UNIMED');
  AddSuf('fza_usuarios',                        'USU');
  AddSuf('fza_usuarios_grupos',                 'USUGRP');
  AddSuf('fza_usuarios_perfiles',               'USUPER');
  AddSuf('fza_valores_defecto',                 'VD');
  AddSuf('fza_variaciones',                     'VAR');
  AddSuf('fza_variaciones_atributos',           'VA');
  AddSuf('fza_facturas_relaciones',             'FACREL');
  AddSuf('fza_ventas_ws_cola',                  'VWSC');
  AddSuf('fza_ventas_ws_cola_intentos',         'VWSCI');
  AddSuf('fza_verifactu_cadena',                'VFCAD');
  AddSuf('fza_verifactu_cola',                  'VFCOLA');
  AddSuf('fza_verifactu_historial',             'VFHIST');
  AddSuf('fza_verifactu_eventos',               'LOG');
  AddSuf('fza_garantias_movimientos',          'GARMOV');
  AddSuf('fza_winforms',                        'WINF');

  // ========== Concepto largo → sufijo corto ==========
  FConceptToSuffix.AddOrSetValue('ARTICULO',  'ART');
  FConceptToSuffix.AddOrSetValue('ALMACEN',   'ALM');
  FConceptToSuffix.AddOrSetValue('CLIENTE',   'CLI');
  FConceptToSuffix.AddOrSetValue('PROVEEDOR', 'PRV');
  FConceptToSuffix.AddOrSetValue('EMPRESA',   'EMP');
  FConceptToSuffix.AddOrSetValue('EMPLEADO',  'EMPL');
  FConceptToSuffix.AddOrSetValue('FAMILIA',   'FAM');
  FConceptToSuffix.AddOrSetValue('TARIFA',    'TAR');
  FConceptToSuffix.AddOrSetValue('PROPIEDAD', 'PROP');
  FConceptToSuffix.AddOrSetValue('CONTADOR',  'CON');
  FConceptToSuffix.AddOrSetValue('USUARIO',   'USU');
  FConceptToSuffix.AddOrSetValue('METADATO',  'META');
  FConceptToSuffix.AddOrSetValue('PAIS',      'PAI');
  FConceptToSuffix.AddOrSetValue('INVENTARIO','INV');
  FConceptToSuffix.AddOrSetValue('PEDIDO',    'PED');
  FConceptToSuffix.AddOrSetValue('FACTURA',   'FAC');
  FConceptToSuffix.AddOrSetValue('BASICO',    'ATB');
  FConceptToSuffix.AddOrSetValue('TIPODOCUMENTO', 'TD');
  FConceptToSuffix.AddOrSetValue('GENERADORPROCESO', 'GP');
  FConceptToSuffix.AddOrSetValue('EFECTO',    'EFEC');
  FConceptToSuffix.AddOrSetValue('REMESA',    'REMC');

  // ========== Concepto propio por tabla (palabras a barrer del nombre) ==========
  // Tablas con sufijo SIMPLE (concepto = una palabra):
  AddOwn('fza_articulos',                      ['ARTICULO']);
  AddOwn('fza_articulos_familias',             ['FAMILIA']);
  AddOwn('fza_articulos_skus',                 ['SKU']);
  AddOwn('fza_almacenes',                      ['ALMACEN']);
  AddOwn('fza_clientes',                       ['CLIENTE']);
  AddOwn('fza_proveedores',                    ['PROVEEDOR']);
  AddOwn('fza_empresas',                       ['EMPRESA']);
  AddOwn('fza_empleados',                      ['EMPLEADO']);
  AddOwn('fza_propiedades',                    ['PROPIEDAD']);
  AddOwn('fza_contadores',                     ['CONTADOR']);
  AddOwn('fza_usuarios',                       ['USUARIO']);
  AddOwn('fza_metadatos',                      ['METADATO']);
  AddOwn('fza_paises',                         ['PAIS']);
  AddOwn('fza_inventarios',                    ['INVENTARIO']);
  AddOwn('fza_pedidos',                        ['PEDIDO']);
  AddOwn('fza_facturas',                       ['FACTURA']);
  AddOwn('fza_tarifas',                        ['TARIFA']);
  AddOwn('fza_variaciones',                    ['VARIACION']);
  AddOwn('fza_tipos_documentos',               ['TIPODOCUMENTO','TIPO_DOCUMENTO']);
  AddOwn('fza_generadorprocesos',              ['GENERADORPROCESO','GENERADOR_PROCESO',
                                                'GENERADORPROCESOS','GENERADOR_PROCESOS']);
  AddOwn('fza_formas_pago',                    ['FORMAPAGO','FORMA_PAGO']);
  AddOwn('fza_usuarios_grupos',                ['GRUPO']);

  // Tablas con sufijo COMPUESTO (varias palabras):
  AddOwn('fza_articulos_tarifas',              ['TARIFA']);
  AddOwn('fza_tarifas_cambios',                ['TARIFA','CAMBIO']);
  AddOwn('fza_tarifas_cambios_lineas',
         ['TARIFA','CAMBIO','LINEA']);
  AddOwn('fza_tarifas_descuento_condiciones',
         ['TARIFA','DESCUENTO','CONDICION']);
  AddOwn('fza_tarifas_descuento_valores',
         ['TARIFA','DESCUENTO','VALOR']);
  AddOwn('fza_traducciones',                    ['TRADUCCION']);
  AddOwn('fza_articulos_proveedores',          ['PROVEEDOR']);
  AddOwn('fza_articulos_skus_costes',          ['COSTE']);
  AddOwn('fza_articulos_vinculos',             ['VINCULO']);
  AddOwn('fza_articulos_cambios_historico',
         ['ARTICULO','ARTICULOS','CAMBIO','CAMBIOS','COLOR','COLORES',
          'HISTORICO']);
  AddOwn('fza_facturas_lineas',                ['FACTURA','LINEA']);
  AddOwn('fza_inventarios_lineas',             ['INVENTARIO','LINEA']);
  AddOwn('fza_pedidos_lineas',                 ['PEDIDO','LINEA']);
  AddOwn('fza_traspasos_solicitudes',          ['TRASPASO','SOLICITUD']);
  AddOwn('fza_traspasos_solicitudes_lineas',   ['TRASPASO','SOLICITUD','LINEA']);
  AddOwn('fza_facturas_pagos',                 ['PAGO','FACTURA']);
  AddOwn('fza_pedidos_mensajes',               ['PEDIDO','MENSAJE','MENSAJES']);
  AddOwn('fza_prestashop_cola',                ['PRESTASHOP','COLA']);
  AddOwn('fza_prestashop_cola_eventos',
         ['PRESTASHOP','COLA','EVENTO']);
  AddOwn('fza_stock_bloqueos',                 ['STOCK','BLOQUEO']);
  AddOwn('fza_proveedores_familias',           ['FAMILIA']);
  AddOwn('fza_proveedores_familias_conjuntos', ['FAMILIA','CONJUNTO']);
  AddOwn('fza_familias_atributos',             ['ATRIBUTO']);
  AddOwn('fza_familias_atributos_defecto',     ['ATRIBUTO']);
  AddOwn('fza_familias_claves_info_defecto',   ['INFO']);
  AddOwn('fza_caja_formas_pago',               ['FORMAPAGO','FORMAP']);
  AddOwn('fza_caja_subsanaciones',             ['SUBSANACION']);
  AddOwn('fza_atributos_basicos',              ['BASICO']);
  AddOwn('fza_atributos_conjuntos',            ['CONJUNTO']);
  AddOwn('fza_atributos_conjuntos_det',        ['CONJUNTO','DET']);
  AddOwn('fza_atributos_valores',              ['VALOR']);
  AddOwn('fza_atributos_valores_info',         ['VALOR','INFO']);
  AddOwn('fza_propiedades_valores',            ['VALOR']);
  AddOwn('fza_empresas_retenciones',           ['RETENCION']);
  AddOwn('fza_empresas_series',                ['SERIE']);
  AddOwn('fza_empresas_bancos',                ['BANCO']);
  AddOwn('fza_bancos',                         ['BANCO']);
  AddOwn('fza_facturas_consolidaciones',       ['CONSOLIDACION']);
  AddOwn('fza_ivas_grupos',                    ['GRUPO','ZONA']);
  AddOwn('fza_ivas_tipos',                     ['TIPO']);
  AddOwn('fza_ivas_zonas',                     ['ZONA']);
  AddOwn('fza_movimientos_almacen',            ['MOVIMIENTO','MOV']);
  AddOwn('fza_movimientos_recalculos_pendientes',
         ['MOVIMIENTO','RECALCULO','PENDIENTE']);
  AddOwn('fza_codigos_barras',                 ['BARRAS','CODIGO_BARRAS']);
  AddOwn('fza_config_campos',                  ['CAMPO']);
  AddOwn('fza_valores_defecto',                ['DEFECTO']);
  AddOwn('fza_facturas_compra',                ['FACTURA','COMPRA']);
  AddOwn('fza_facturas_compra_celdas',         ['FACTURA','COMPRA','CELDA']);
  AddOwn('fza_facturas_compra_lineas',         ['FACTURA','COMPRA','LINEA']);
  AddOwn('fza_efectos_compra',                 ['EFECTO','COMPRA']);
  AddOwn('fza_remesas_compra',                 ['REMESA','COMPRA']);
  AddOwn('fza_efectos_venta',                  ['EFECTO','VENTA']);
  AddOwn('fza_remesas_venta',                  ['REMESA','VENTA']);
  AddOwn('fza_tipos_efecto',                   ['TIPO','EFECTO']);
  AddOwn('fza_ventas_ws_cola',                 ['VENTA','WS','COLA']);
  AddOwn('fza_ventas_ws_cola_intentos',
         ['VENTA','WS','COLA','INTENTO']);

  // ========== Auditoría ==========
  FAuditRenames.AddOrSetValue('INSTANTEALTA',  'INSTANTE_ALTA');
  FAuditRenames.AddOrSetValue('INSTANTEMODIF', 'INSTANTE_MODIF');
  FAuditRenames.AddOrSetValue('USUARIOALTA',   'USUARIO_ALTA');
  FAuditRenames.AddOrSetValue('USUARIOMODIF',  'USUARIO_MODIF');

  // ========== Abreviaturas (regex, reemplazo) ==========
  // El patrón del usuario debe ser una "palabra" sin guion bajo a su izq/dcha
  // (lookarounds: (?<![A-Z0-9]) ... (?![A-Z0-9]))
  FAbbreviations.Add(TKVPair.Create('PORCENSUPERREDUCIDO', 'PORCENTAJE_SUPERREDUCIDO'));
  FAbbreviations.Add(TKVPair.Create('PORCENREDUCIDO',      'PORCENTAJE_REDUCIDO'));
  FAbbreviations.Add(TKVPair.Create('PORCENNORMAL',        'PORCENTAJE_NORMAL'));
  FAbbreviations.Add(TKVPair.Create('PORCENEXENTO',        'PORCENTAJE_EXENTO'));
  FAbbreviations.Add(TKVPair.Create('PORCENRETENCION',     'PORCENTAJE_RETENCION'));
  FAbbreviations.Add(TKVPair.Create('PORCEN',              'PORCENTAJE'));
  FAbbreviations.Add(TKVPair.Create('NRO',                 'NUMERO'));
  FAbbreviations.Add(TKVPair.Create('CPOSTAL',             'CODIGO_POSTAL'));
  FAbbreviations.Add(TKVPair.Create('FORMAPAGO',           'FORMA_PAGO'));
  FAbbreviations.Add(TKVPair.Create('FORMAP',              'FORMA_PAGO'));
  FAbbreviations.Add(TKVPair.Create('RAZONSOCIAL',         'RAZON_SOCIAL'));
  FAbbreviations.Add(TKVPair.Create('TIPODOCUMENTO',       'TIPO_DOCUMENTO'));
  FAbbreviations.Add(TKVPair.Create('TIPODOC',             'TIPO_DOC'));
  FAbbreviations.Add(TKVPair.Create('TIPOIVA',             'TIPO_IVA'));
  FAbbreviations.Add(TKVPair.Create('NUMDIGIT',            'NUM_DIGITOS'));
  FAbbreviations.Add(TKVPair.Create('PRECIOSALIDA',        'PRECIO_SALIDA'));
  FAbbreviations.Add(TKVPair.Create('PRECIOFINAL',         'PRECIO_FINAL'));
  FAbbreviations.Add(TKVPair.Create('PRECIOVENTA',         'PRECIO_VENTA'));
  FAbbreviations.Add(TKVPair.Create('ALMACENDEF',          'ALMACEN_DEFECTO'));
  FAbbreviations.Add(TKVPair.Create('CAJADEF',             'CAJA_DEFECTO'));
  FAbbreviations.Add(TKVPair.Create('EMPRESADEF',          'EMPRESA_DEFECTO'));
  FAbbreviations.Add(TKVPair.Create('TABLAORIGEN',         'TABLA_ORIGEN'));
  FAbbreviations.Add(TKVPair.Create('STADO',               'ESTADO'));
  FAbbreviations.Add(TKVPair.Create('BOCKCHAIN',           'BLOCKCHAIN'));
  FAbbreviations.Add(TKVPair.Create('GENERADORPROCESOS',   'GENERADOR_PROCESOS'));
  FAbbreviations.Add(TKVPair.Create('GENERADORPROCESO',    'GENERADOR_PROCESO'));
  FAbbreviations.Add(TKVPair.Create('ULTIMOLOGIN',         'ULTIMO_LOGIN'));
  // Caso especial: COD al inicio de cadena
  FAbbreviations.Add(TKVPair.Create('__COD_AT_START__',    'CODIGO'));

  // ========== Sufijos legacy a barrer del final ==========
  FLegacySuffixes.Add('FORMAP');
  FLegacySuffixes.Add('FORMAPAGO');
  FLegacySuffixes.Add('BASICO');
  FLegacySuffixes.Add('TIPODOCUMENTO');
  FLegacySuffixes.Add('TIPO_DOCUMENTO');
  FLegacySuffixes.Add('PERFILES');

  // ========== Prefijos FK ==========
  FFKPrefixes.Add('CODIGO');
  FFKPrefixes.Add('ID');
  FFKPrefixes.Add('NOMBRE');
  FFKPrefixes.Add('SERIE');
  FFKPrefixes.Add('NUMERO');
  FFKPrefixes.Add('NRO');

  // ========== EXCEPCIONES por tabla/columna ==========
  AddException('fza_articulos_skus',                      'CODIGO_VAR_SKU',                       'CODIGO_VAR_SKU');
  AddException('fza_atributos_basicos',                   'ID_BASICO',                            'ID_ATB');
  AddException('fza_atributos_basicos',                   'ID_VA_BASICO',                         'ID_VA_ATB');
  AddException('fza_atributos_valores',                   'ID_VA_AV',                             'ID_VA_AV');
  AddException('fza_atributos_valores',                   'ID_VALOR_AV',                          'ID_AV');
  AddException('fza_atributos_valores',                   'CODIGO_ARTICULO_EXTRA',                'CODIGO_ART_EXTRA_AV');
  AddException('fza_caja_pagos',                          'CODIGO_FORMAP',                        'CODIGO_CFP_PAGO');
  AddException('fza_caja_pagos',                          'RED_BLOCKCHAIN',                       'RED_BLOCKCHAIN_PAGO');
  AddException('fza_caja_pagos',                          'CODIGO_EMPRESA_PAGO',                  'CODIGO_EMP_PAGO');
  AddException('fza_caja_pagos',                          'CODIGO_ALMACEN_PAGO',                  'CODIGO_ALM_PAGO');
  AddException('fza_pedidos_mensajes',                    'IDPS_MENSAJES_PEDIDO',                 'IDPS_MENSAJES_PEDMSG');
  AddException('fza_pedidos_mensajes',                    'IDMENSAJEPS_MENSAJE_PEDIDO',           'IDMENSAJEPS_PEDMSG');
  AddException('fza_pedidos_mensajes',                    'IDEMPLEADOPS_MENSAJE_PEDIDO',          'IDEMPLEADOPS_PEDMSG');
  AddException('fza_pedidos_mensajes',                    'MENSAJEPS_MENSAJE_PEDIDO',             'MENSAJEPS_PEDMSG');
  AddException('fza_pedidos_mensajes',                    'FECHAPS_MENSAJE_PEDIDO',               'FECHAPS_PEDMSG');
  AddException('fza_articulos_proveedores',               'CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR',  'CODIGO_PRV_AP');
  AddException('fza_articulos_proveedores',               'CODIGO_ARTICULO_ARTICULO_PROVEEDOR',   'CODIGO_ART_AP');
  AddException('fza_articulos_proveedores',               'REF_PROVEEDOR_ARTICULO_PROVEEDOR',     'REF_PROVEEDOR_AP');
  AddException('fza_articulos_proveedores',               'PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR', 'PRECIO_ULT_COMPRA_AP');
  AddException('fza_articulos_proveedores',               'FECHA_VALIDEZ_ARTICULO_PROVEEDOR',     'FECHA_VALIDEZ_AP');
  AddException('fza_articulos_proveedores',               'ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR', 'ESPROVEEDORPRINCIPAL_AP');
  AddException('fza_recibos',                             'NRO_FACTURA_RECIBO',                   'NUMERO_FAC_REC');
  AddException('fza_recibos',                             'SERIE_FACTURA_RECIBO',                 'SERIE_FAC_REC');
  AddException('fza_recibos',                             'NRO_PLAZO_RECIBO',                     'NUMERO_PLAZO_REC');
  AddException('fza_recibos',                             'CODIGO_CLIENTE_RECIBO',                'CODIGO_CLI_REC');
  AddException('fza_recibos',                             'CODIGO_PAIS_CLIENTE_RECIBO',           'CODIGO_PAI_CLI_REC');
  AddException('fza_recibos',                             'NOMBRE_PAIS_CLIENTE_RECIBO',           'NOMBRE_PAI_CLI_REC');
  AddException('fza_recibos',                             'CPOSTAL_CLIENTE_RECIBO',               'CODIGO_POSTAL_CLI_REC');
  AddException('fza_recibos',                             'POBLACION_CLIENTE_RECIBO',             'POBLACION_CLI_REC');
  AddException('fza_recibos',                             'PROVINCIA_CLIENTE_RECIBO',             'PROVINCIA_CLI_REC');
  AddException('fza_recibos',                             'IBAN_CLIENTE_RECIBO',                  'IBAN_CLI_REC');
  AddException('fza_recibos',                             'RAZONSOCIAL_CLIENTE_RECIBO',           'RAZON_SOCIAL_CLI_REC');
  AddException('fza_usuarios',                            'USUARIO_USUARIO',                      'USUARIO_USU');
  AddException('fza_usuarios_grupos',                     'GRUPO_GRUPO',                          'GRUPO_USUGRP');
  AddException('fza_usuarios_perfiles',                   'USUARIO_GRUPO_PERFILES',               'USUARIO_GRUPO_USUPER');
  AddException('fza_usuarios_perfiles',                   'KEY_PERFILES',                         'KEY_USUPER');
  AddException('fza_usuarios_perfiles',                   'SUBKEY_PERFILES',                      'SUBKEY_USUPER');
  AddException('fza_usuarios_perfiles',                   'VALUE_PERFILES',                       'VALUE_USUPER');
  AddException('fza_usuarios_perfiles',                   'VALUE_TEXT_PERFILES',                  'VALUE_TEXT_USUPER');
  AddException('fza_usuarios_perfiles',                   'TYPE_BLOB_PERFILES',                   'TYPE_BLOB_USUPER');
  AddException('fza_usuarios_perfiles',                   'VALUE_BLOB_PERFILES',                  'VALUE_BLOB_USUPER');
  AddException('fza_facturas_consolidaciones',            'ID_CONSOLIDACION',                     'ID_FACCON');
  AddException('fza_atributos_valores_info',              'ID_INFO',                              'ID_AVI');
  AddException('fza_atributos_valores_info',              'CLAVE_INFO',                           'CLAVE_AVI');
  AddException('fza_atributos_valores_info',              'VALOR_INFO',                           'VALOR_AVI');
  AddException('fza_atributos_valores_info',              'ID_VALOR_AV_INFO',                     'ID_AV_AVI');
  AddException('fza_articulos_vinculos',                  'ID_VINCULO',                           'ID_ARTVIN');
  AddException('fza_articulos_vinculos',                  'CODIGO_ARTICULO_PADRE',                'CODIGO_ART_PADRE_ARTVIN');
  AddException('fza_articulos_vinculos',                  'CODIGO_ARTICULO_HIJO',                 'CODIGO_ART_HIJO_ARTVIN');
  AddException('fza_articulos_vinculos',                  'CANTIDAD',                             'CANTIDAD_ARTVIN');
  AddException('fza_articulos_vinculos',                  'ORDEN_VISUAL',                         'ORDEN_VISUAL_ARTVIN');
  AddException('fza_articulos_vinculos',                  'ES_OBLIGATORIO',                       'ESOBLIGATORIO_ARTVIN');
  AddException('fza_familias_atributos',                  'CODIGO_FAMILIA',                       'CODIGO_FAM_FA');
  AddException('fza_familias_atributos',                  'CODIGO_PROPIEDAD',                     'CODIGO_PROP_FA');
  AddException('fza_familias_atributos',                  'ES_REQUERIDO',                         'ESREQUERIDO_FA');
  AddException('fza_familias_atributos',                  'ORDEN_MOSTRAR',                        'ORDEN_MOSTRAR_FA');
  AddException('fza_familias_atributos_defecto',          'CODIGO_FAMILIA_FAD',                   'CODIGO_FAM_FAD');
  AddException('fza_familias_atributos_defecto',          'ID_VA_BASICO_FAD',                     'ID_VA_ATB_FAD');
  AddException('fza_familias_atributos_defecto',          'OBLIGATORIO_FAD',                      'ESOBLIGATORIO_FAD');
  AddException('fza_familias_claves_info_defecto',        'CODIGO_FAMILIA_FCI',                   'CODIGO_FAM_FCI');
  AddException('fza_familias_claves_info_defecto',        'ID_VA_BASICO_FCI',                     'ID_VA_ATB_FCI');
  AddException('fza_familias_claves_info_defecto',        'OBLIGATORIO_FCI',                      'ESOBLIGATORIO_FCI');
  AddException('fza_propiedades_valores',                 'ID_VALOR_PV',                          'ID_PV');
  AddException('fza_propiedades_valores',                 'ID_PROPIEDAD_PV',                      'ID_PROP_PV');
  AddException('fza_articulos_propiedades',               'CODIGO_ARTICULO',                      'CODIGO_ART_ARTPROP');
  AddException('fza_articulos_propiedades',               'CODIGO_PROPIEDAD',                     'CODIGO_PROP_ARTPROP');
  AddException('fza_articulos_propiedades',               'ID_VALOR_PV',                          'ID_PV_ARTPROP');
  AddException('fza_articulos_propiedades',               'VALOR_LIBRE',                          'VALOR_LIBRE_ARTPROP');
  AddException('fza_proveedores_familias',                'CODIGO_PROVEEDOR_PF',                  'CODIGO_PRV_PF');
  AddException('fza_proveedores_familias',                'CODIGO_FAMILIA_PF',                    'CODIGO_FAM_PF');
  AddException('fza_proveedores_familias',                'TIPO_VARIACION_PF',                    'TIPO_VAR_PF');
  AddException('fza_proveedores_familias_conjuntos',      'CODIGO_PROVEEDOR_PFC',                 'CODIGO_PRV_PFC');
  AddException('fza_proveedores_familias_conjuntos',      'CODIGO_FAMILIA_PFC',                   'CODIGO_FAM_PFC');
  AddException('fza_proveedores_familias_conjuntos',      'ID_CONJUNTO_PFC',                      'ID_AC_PFC');
  AddException('fza_proveedores_familias_conjuntos',      'ES_GENERACION_AUTO',                   'ESGENERACION_AUTO_PFC');
  AddException('fza_atributos_conjuntos_det',             'ID_CONJUNTO_ACD',                      'ID_AC_ACD');
  AddException('fza_atributos_conjuntos_det',             'ID_VALOR_ACD',                         'ID_AV_ACD');
  AddException('fza_atributos_sku',                       'CODIGO_UNIDAD_SA',                     'CODIGO_UNIDAD_SKU_SA');
  AddException('fza_atributos_sku',                       'ID_VALOR_SA',                          'ID_AV_SA');
  AddException('fza_articulos_conjuntos_asign',           'CODIGO_ARTICULO_ACA',                  'CODIGO_ART_ACA');
  AddException('fza_articulos_conjuntos_asign',           'ID_CONJUNTO_ACA',                      'ID_AC_ACA');
  AddException('fza_articulos_conjuntos_asign',           'ID_ATRIBUTO_ACA',                      'ID_VA_ACA');
  AddException('fza_articulos_conjuntos_asign',           'ES_GENERACION_AUTO',                   'ESGENERACION_AUTO_ACA');
  AddException('fza_atributos_conjuntos',                 'ID_CONJUNTO_AC',                       'ID_AC');
  AddException('fza_atributos_conjuntos',                 'ID_VARIACION_AC',                      'ID_VAR_AC');
  AddException('fza_atributos_conjuntos',                 'ID_ATRIBUTO_AC',                       'ID_VA_AC');
  AddException('fza_variaciones_atributos',               'ID_VA',                                'ID_VAR_VA');
  AddException('fza_variaciones_atributos',               'ID_ATRIBUTO_VA',                       'ID_ATB_VA');
  AddException('fza_verifactu_eventos',                   'NRO_FACTURA_LOG',                      'NUMERO_FAC_LOG');
  AddException('fza_verifactu_eventos',                   'SERIE_FACTURA_LOG',                    'SERIE_FAC_LOG');
  AddException('fza_caja_vales',                          'NRO_FACTURA_EMI_VL',                   'NUMERO_FAC_EMI_VL');
  AddException('fza_caja_vales',                          'NRO_FACTURA_RED_VL',                   'NUMERO_FAC_RED_VL');
  AddException('fza_caja_operaciones',                    'NRO_FACTURA_OPCAJA',                   'NUMERO_FAC_OPCAJA');
  AddException('fza_facturas_pagos',                      'NRO_FACTURA_PAGO',                     'NUMERO_FAC_FACPAG');
  AddException('fza_facturas_pagos',                      'SERIE_FACTURA_PAGO',                   'SERIE_FAC_FACPAG');
  AddException('fza_facturas_pagos',                      'LINEA_PAGO',                           'LINEA_FACPAG');
  AddException('fza_facturas_pagos',                      'TIPO_PAGO',                            'TIPO_FACPAG');
  AddException('fza_facturas_pagos',                      'IMPORTE_PAGO',                         'IMPORTE_FACPAG');
  AddException('fza_facturas_pagos',                      'REFERENCIA_PAGO',                      'REFERENCIA_FACPAG');
  AddException('fza_facturas_pagos',                      'DESCRIPCION_PAGO',                     'DESCRIPCION_FACPAG');
  AddException('fza_facturas_pagos',                      'ENTIDAD_PAGO',                         'ENTIDAD_FACPAG');
  AddException('fza_facturas_pagos',                      'FECHA_PAGO',                           'FECHA_FACPAG');
  AddException('fza_movimientos_almacen',                 'NRO_DOC_MOV',                          'NUMERO_DOC_MOV');
  AddException('fza_movimientos_almacen',                 'NRO_DOC_REF_MOV',                      'NUMERO_DOC_REF_MOV');
  AddException('fza_inventarios',                         'NRO_INVENTARIO',                       'NUMERO_INV');
  AddException('fza_inventarios_lineas',                  'CODIGO_EMPRESA_INVENTARIO_LINEA',      'CODIGO_EMP_INVLIN');
  AddException('fza_inventarios_lineas',                  'CODIGO_ALMACEN_INVENTARIO_LINEA',      'CODIGO_ALM_INVLIN');
  AddException('fza_inventarios_lineas',                  'SERIE_INVENTARIO_LINEA',               'SERIE_INV_INVLIN');
  AddException('fza_inventarios_lineas',                  'NRO_INVENTARIO_LINEA',                 'NUMERO_INV_INVLIN');
  AddException('fza_inventarios_lineas',                  'LINEA_INVENTARIO_LINEA',               'LINEA_INVLIN');
  AddException('fza_inventarios_lineas',                  'CODIGO_ARTICULO_INVENTARIO_LINEA',     'CODIGO_ART_INVLIN');
  AddException('fza_inventarios_lineas',                  'TOTAL_COSTE_DIFERENCIA_LINEA',         'TOTAL_COSTE_DIFERENCIA_INVLIN');
  AddException('fza_facturas_lineas',                     'NRO_FACTURA_LINEA',                    'NUMERO_FAC_FACLIN');
  AddException('fza_facturas_lineas',                     'SERIE_FACTURA_LINEA',                  'SERIE_FAC_FACLIN');
  AddException('fza_facturas_lineas',                     'CODIGO_EMPRESA_FACTURA_LINEA',         'CODIGO_EMP_FACLIN');
  AddException('fza_facturas_lineas',                     'LINEA_FACTURA_LINEA',                  'LINEA_FACLIN');
  AddException('fza_facturas_lineas',                     'TOTAL_FACTURA_LINEA',                  'TOTAL_FACLIN');
  AddException('fza_facturas_lineas',                     'TOTAL_FACTURASIVA_LINEA',              'TOTAL_FAC_SIVA_FACLIN');
  AddException('fza_facturas_lineas',                     'NUMERO_MOV_FACTURA_LINEA',             'NUMERO_MOV_FACLIN');
  AddException('fza_pedidos_lineas',                      'NRO_PEDIDO_LINEA',                     'NUMERO_PED_PEDLIN');
  AddException('fza_pedidos_lineas',                      'SERIE_PEDIDO_LINEA',                   'SERIE_PED_PEDLIN');
  AddException('fza_pedidos_lineas',                      'LINEA_PEDIDO_LINEA',                   'LINEA_PEDLIN');
  AddException('fza_pedidos_lineas',                      'TOTAL_PEDIDO_LINEA',                   'TOTAL_PEDLIN');
  AddException('fza_facturas',                            'NRO_FACTURA',                          'NUMERO_FAC');
  AddException('fza_facturas',                            'NRO_FACTURA_ABONO_FACTURA',            'NUMERO_FAC_ABONO_FAC');
  AddException('fza_facturas',                            'SERIE_FACTURA_ABONO_FACTURA',          'SERIE_FAC_ABONO_FAC');
  AddException('fza_pedidos',                             'NRO_PEDIDO',                           'NUMERO_PED');
  AddException('fza_pedidos',                             'NRO_PEDIDO_ABONO_PEDIDO',              'NUMERO_PED_ABONO_PED');
  AddException('fza_pedidos',                             'SERIE_PEDIDO_ABONO_PEDIDO',            'SERIE_PED_ABONO_PED');

  // === Excepciones añadidas tras revisión manual (21 columnas que el motor
  //     omitía por contener dígitos en el nombre - ver fix de ParseDefinitionLine).
  //     De las 21, 18 salen correctas con la regla automática. Estas 3 son
  //     decisiones explícitas que se apartan del libro de estilo automático: ===
  AddException('fza_paises',                              'COD_PAIS_ALPHA3',                      'COD_ALPHA3_PAI');
  AddException('fza_paises',                              'COD_PAIS_ALPHA2',                      'COD_ALPHA2_PAI');
  AddException('fza_pedidos_lineas',                      'CODEAN13PRODPS_PEDIDO_LINEA',          'CODBAR_ART_PEDLIN');
end;

procedure TViraCashNormalizer.SetTableSuffix(const TableName, Suffix: string);
begin
  FTableSuffixes.AddOrSetValue(TableName, Suffix);
end;

procedure TViraCashNormalizer.SetAuditRename(const Old, New: string);
begin
  FAuditRenames.AddOrSetValue(Old, New);
end;

procedure TViraCashNormalizer.AddAbbreviation(const RegexPattern, Replacement: string);
begin
  FAbbreviations.Add(TKVPair.Create(RegexPattern, Replacement));
end;

procedure TViraCashNormalizer.ClearAbbreviations;
begin
  FAbbreviations.Clear;
end;

procedure TViraCashNormalizer.AddException(const TableName, OldColumn, NewColumn: string);
begin
  FExceptions.Add(TExceptionEntry.Create(TableName, OldColumn, NewColumn));
end;

procedure TViraCashNormalizer.ClearExceptions;
begin
  FExceptions.Clear;
end;

procedure TViraCashNormalizer.AddOwnConcept(const TableName, Concept: string);
var
  L: TStringList;
begin
  if not FOwnConcepts.TryGetValue(TableName, L) then
  begin
    L := TStringList.Create;
    L.CaseSensitive := True;
    L.Sorted := True;
    L.Duplicates := dupIgnore;
    FOwnConcepts.Add(TableName, L);
  end;
  L.Add(Concept);
end;

function TViraCashNormalizer.TryGetException(const TableName, OldName: string;
  out NewName: string): Boolean;
var
  E: TExceptionEntry;
begin
  for E in FExceptions do
    if (E.TableName = TableName) and (E.OldColumn = OldName) then
    begin
      NewName := E.NewColumn;
      Exit(True);
    end;
  Result := False;
  NewName := '';
end;

function TViraCashNormalizer.GetTableSuffix(const TableName: string): string;
begin
  if not FTableSuffixes.TryGetValue(TableName, Result) then
    Result := '';
end;

function TViraCashNormalizer.ExpandAbbreviations(const Name: string): string;
var
  Prev:  string;
  Pair:  TKVPair;
  Pat:   string;
begin
  Result := Name;
  repeat
    Prev := Result;
    for Pair in FAbbreviations do
    begin
      if Pair.Key = '__COD_AT_START__' then
      begin
        // Patrón especial: COD al inicio de cadena seguido de _
        Result := TRegEx.Replace(Result, '^COD(?=_)', Pair.Value);
      end
      else
      begin
        // Patrón estándar: palabra completa, no parte de un token mayor
        Pat := '(?<![A-Z0-9])' + Pair.Key + '(?![A-Z0-9])';
        Result := TRegEx.Replace(Result, Pat, Pair.Value);
      end;
    end;
  until Result = Prev;
end;

function TViraCashNormalizer.NormalizeBoolean(const Name: string): string;
begin
  Result := Name;
  // ACTIVO_x → ESACTIVO_x
  if TRegEx.IsMatch(Result, '^ACTIVO(_|$)') then
    Result := 'ES' + Result;
  // ES_FOO_BAR → ESFOO_BAR
  if TRegEx.IsMatch(Result, '^ES_[A-Z]') then
    Result := 'ES' + Copy(Result, 4, MaxInt);
end;

function TViraCashNormalizer.StripOwnConcept(const Name, TableName: string): string;
var
  Own:        TStringList;
  Parts:      TArray<string>;
  Out_:       TList<string>;
  i:          Integer;
  P:          string;
  Protectors: TStringList;
  Suffix:     string;
  ToStrip:    TStringList;
  IsOwnConcept: Boolean;
begin
  if not FOwnConcepts.TryGetValue(TableName, Own) then
    Exit(Name);

  // ToStrip = palabras a barrer.
  // Incluye los conceptos propios (ALMACEN, ARTICULO...) Y la abreviatura del
  // sufijo de la tabla (ALM, ART...). La razón: ExpandAbbreviations corre antes
  // y puede haber convertido ALMACEN -> ALM en medio del nombre.
  ToStrip := TStringList.Create;
  Protectors := TStringList.Create;
  try
    ToStrip.CaseSensitive := True;
    ToStrip.Sorted        := True;
    ToStrip.Duplicates    := dupIgnore;
    for i := 0 to Own.Count - 1 do
      ToStrip.Add(Own[i]);
    Suffix := GetTableSuffix(TableName);
    if Suffix <> '' then
      ToStrip.Add(Suffix);

    // Protectors: palabras delante de las cuales un concepto SE CONSERVA (es FK).
    // CODIGO_CLIENTE_ALM en fza_almacenes -> CLIENTE va precedido de CODIGO,
    //   se conserva (es FK a fza_clientes); resultado: CODIGO_CLI_ALM.
    // OJO: el protector NO aplica al concepto propio de la tabla. Si la
    //   tabla es fza_almacenes y aparece CODIGO_ALMACEN_ALM, ALMACEN es el
    //   concepto propio y SÍ se barre aunque CODIGO esté delante; resultado: CODIGO_ALM.
    Protectors.CaseSensitive := True;
    Protectors.Sorted := True;
    Protectors.Add('CODIGO');
    Protectors.Add('ID');
    Protectors.Add('NOMBRE');
    Protectors.Add('RAZON_SOCIAL');

    Parts := Name.Split(['_']);
    Out_ := TList<string>.Create;
    try
      for i := 0 to Length(Parts) - 1 do
      begin
        P := Parts[i];
        if ToStrip.IndexOf(P) >= 0 then
        begin
          // P es palabra a considerar para barrido.
          // ¿es concepto propio (o su forma abreviada = sufijo de tabla)?
          IsOwnConcept := (Own.IndexOf(P) >= 0) or SameText(P, Suffix);

          if IsOwnConcept then
          begin
            // Concepto propio: SIEMPRE se barre, incluso protegido por CODIGO.
            // (porque el sufijo de tabla ya identifica la propia tabla)
            // No añadimos nada a Out_.
          end
          else if (Out_.Count > 0) and
                  (Protectors.IndexOf(Out_[Out_.Count - 1]) >= 0) then
            // FK protegida por CODIGO/ID/NOMBRE: se conserva
            Out_.Add(P);
          // else: concepto suelto sin protector, se barre.
        end
        else
          Out_.Add(P);
      end;
      Result := string.Join('_', Out_.ToArray);
    finally
      Out_.Free;
    end;
  finally
    Protectors.Free;
    ToStrip.Free;
  end;
end;

function TViraCashNormalizer.StripLegacyTailTokens(const Name: string): string;
var
  Parts: TList<string>;
begin
  Parts := TList<string>.Create;
  try
    Parts.AddRange(Name.Split(['_']));
    while (Parts.Count > 1) and (FLegacySuffixes.IndexOf(Parts[Parts.Count - 1]) >= 0) do
      Parts.Delete(Parts.Count - 1);
    Result := string.Join('_', Parts.ToArray);
  finally
    Parts.Free;
  end;
end;

function TViraCashNormalizer.ReplaceFKConcepts(const Core: string): string;
var
  Parts:    TArray<string>;
  i:        Integer;
  P:        string;
  Next1:    string;
  Next2:    string;
  Out_:     TList<string>;
  Suffix:   string;
begin
  Parts := Core.Split(['_']);
  Out_ := TList<string>.Create;
  try
    i := 0;
    while i < Length(Parts) do
    begin
      P := Parts[i];
      if (FFKPrefixes.IndexOf(P) >= 0) and (i + 1 < Length(Parts)) then
      begin
        Next1 := Parts[i + 1];
        // Caso compuesto: CODIGO_FORMA_PAGO → CODIGO_FP
        if (P = 'CODIGO') and (Next1 = 'FORMA') and (i + 2 < Length(Parts)) then
        begin
          Next2 := Parts[i + 2];
          if Next2 = 'PAGO' then
          begin
            Out_.Add(P);
            Out_.Add('FP');
            Inc(i, 3);
            Continue;
          end;
        end;
        // Caso simple: CODIGO_<concepto>_X → CODIGO_<sufijo>_X
        if FConceptToSuffix.TryGetValue(Next1, Suffix) then
        begin
          Out_.Add(P);
          Out_.Add(Suffix);
          Inc(i, 2);
          Continue;
        end;
      end;
      Out_.Add(P);
      Inc(i);
    end;
    Result := string.Join('_', Out_.ToArray);
    // Limpieza: dobles guiones / guiones colgantes
    Result := TRegEx.Replace(Result, '__+', '_');
    Result := Result.Trim(['_']);
  finally
    Out_.Free;
  end;
end;

function TViraCashNormalizer.GetFinalNewName(const TableName, OldName: string): string;
var
  Suffix:   string;
  AuditNew: string;
  ExcNew:   string;
  N:        string;
  Core:     string;
begin
  // 1) Excepciones explícitas (override absoluto)
  if TryGetException(TableName, OldName, ExcNew) then
    Exit(ExcNew);

  // 2) Auditoría
  if FAuditRenames.TryGetValue(OldName, AuditNew) then
    Exit(AuditNew);

  Suffix := GetTableSuffix(TableName);
  if Suffix = '' then
    Exit(OldName);

  // 3) Expandir abreviaturas
  N := ExpandAbbreviations(OldName);

  // 4) Normalizar booleanos
  N := NormalizeBoolean(N);

  // 5) Si ya termina con el sufijo correcto, separar el sufijo del core
  if N.EndsWith('_' + Suffix) then
    Core := Copy(N, 1, Length(N) - Length(Suffix) - 1)
  else if N = Suffix then
    Core := ''
  else
    Core := N;

  // 6a) Barrer sufijos legacy "neutros" del final (FORMAP, BASICO, …)
  Core := StripLegacyTailTokens(Core);

  // 6b) Quitar concepto propio de la tabla (palabras a barrer en cualquier
  //     posición, salvo cuando van precedidas de un protector como CODIGO/ID)
  Core := StripOwnConcept(Core, TableName);

  // 7) Limpieza de dobles guiones bajos
  Core := TRegEx.Replace(Core, '__+', '_').Trim(['_']);

  // 8) Reemplazar conceptos en posición FK (CODIGO_X_, ID_X_, …) por su
  //    forma abreviada (CODIGO_ART_, ID_AC_, …)
  Core := ReplaceFKConcepts(Core);

  if Core = '' then
    Result := Suffix
  else
    Result := Core + '_' + Suffix;
end;

function TViraCashNormalizer.ParseDefinitionLine(const Line: string;
  out ColName, Definition: string): Boolean;
var
  M:    TMatch;
  Trim: string;
begin
  Result := False;
  ColName := '';
  Definition := '';
  Trim := Line.TrimRight([',', #13]);
  // Patrón: espacios + `NOMBRE` + espacios + resto
  // Importante: el nombre de columna puede contener DIGITOS (ej:
  // DIRECCION1_CLIENTE, COD_PAIS_ALPHA2, QRCODE_BASE64_*). El regex
  // anterior solo aceptaba [A-Za-z_] y se le escapaban casos así.
  M := TRegEx.Match(Trim, '^\s*`([A-Za-z0-9_]+)`\s+(.+?)\s*,?\s*$');
  if M.Success then
  begin
    ColName := M.Groups[1].Value;
    if SameText(ColName, 'PRIMARY') or SameText(ColName, 'KEY') or
       SameText(ColName, 'UNIQUE') or SameText(ColName, 'INDEX') or
       SameText(ColName, 'CONSTRAINT') or SameText(ColName, 'FULLTEXT') then
      Exit(False);
    Definition := M.Groups[2].Value.TrimRight([',']);
    Result := True;
  end;
end;

procedure TViraCashNormalizer.GeneratePlan(const SourceSQL: string;
  AColumnPlan: TColumnList; AIndexPlan: TIndexList;
  const OnLog: TProc<string>);

  procedure Log(const S: string);
  begin
    if Assigned(OnLog) then OnLog(S);
  end;

  procedure ProcessTable(const TableName, Body: string);
  var
    Lines: TArray<string>;
    L:     string;
    Col, Defn: string;
    Rec:   TColumnRename;
  begin
    Lines := Body.Split([#10]);
    for L in Lines do
    begin
      if ParseDefinitionLine(L, Col, Defn) then
      begin
        Rec.TableName  := TableName;
        Rec.OldName    := Col;
        Rec.Definition := Defn;
        Rec.NewName    := GetFinalNewName(TableName, Col);
        Rec.Changed    := Rec.OldName <> Rec.NewName;
        AColumnPlan.Add(Rec);
      end;
    end;
  end;

  function ColShortForIndex(const NewCol, TableSuffix: string): string;
  begin
    if NewCol.EndsWith('_' + TableSuffix) then
      Result := Copy(NewCol, 1, Length(NewCol) - Length(TableSuffix) - 1)
    else
      Result := NewCol;
  end;

  function MapNewCol(const TableName, OldCol: string): string;
  var
    Rec: TColumnRename;
  begin
    for Rec in AColumnPlan do
      if (Rec.TableName = TableName) and (Rec.OldName = OldCol) then
        Exit(Rec.NewName);
    Result := OldCol;
  end;

  function IsDuplicateIndex(APlan: TIndexList;
                            const ATable, ANewName: string): Boolean;
  var
    Rec: TIndexRename;
  begin
    for Rec in APlan do
      if (Rec.TableName = ATable) and (Rec.NewName = ANewName) then
        Exit(True);
    Result := False;
  end;

var
  TablePat:   TRegEx;
  IdxPat:     TRegEx;
  TM, IM:     TMatch;
  TableName:  string;
  Body:       string;
  IdxName, ColsStr: string;
  IsUnique:   Boolean;
  Cols:       TArray<string>;
  NewCols:    TArray<string>;
  ShortCols:  TArray<string>;
  i:          Integer;
  Suffix:     string;
  IdxRec:     TIndexRename;
  Prefix:     string;
  IdxNewName: string;
begin
  AColumnPlan.Clear;
  AIndexPlan.Clear;

  // Encontrar bloques CREATE TABLE … (...)
  // Patrón multilínea con DOTALL emulado vía TRegExOptions = [roMultiLine].
  // Como Delphi TRegEx no soporta directamente DOTALL en algunos casos,
  // usamos lazy matching .*? con flag roSingleLine.
  TablePat := TRegEx.Create('CREATE TABLE `([^`]+)` \((.*?)^\);',
    [roSingleLine, roMultiLine]);
  for TM in TablePat.Matches(SourceSQL) do
  begin
    TableName := TM.Groups[1].Value;
    Body      := TM.Groups[2].Value;
    if not FTableSuffixes.ContainsKey(TableName) then
    begin
      Log(Format('[WARN] Tabla sin sufijo definido: %s (se omite)', [TableName]));
      Continue;
    end;
    ProcessTable(TableName, Body);
  end;
  Log(Format('Procesadas %d columnas en %d tablas',
    [AColumnPlan.Count, FTableSuffixes.Count]));

  // Encontrar índices: ALTER TABLE `t` ADD [UNIQUE] INDEX `name` (cols);
  IdxPat := TRegEx.Create(
    'ALTER TABLE `([^`]+)` ADD (UNIQUE )?INDEX `([^`]+)` \(([^)]+)\);',
    [roIgnoreCase]);
  for IM in IdxPat.Matches(SourceSQL) do
  begin
    TableName := IM.Groups[1].Value;
    IsUnique  := Trim(IM.Groups[2].Value) <> '';
    IdxName   := IM.Groups[3].Value;
    ColsStr   := IM.Groups[4].Value;
    Cols      := ColsStr.Split([',']);
    for i := 0 to Length(Cols) - 1 do
      Cols[i] := Cols[i].Trim([' ', '`']);

    Suffix := GetTableSuffix(TableName);
    if Suffix = '' then
    begin
      Log(Format('[WARN] Índice de tabla sin sufijo: %s.%s', [TableName, IdxName]));
      Continue;
    end;

    SetLength(NewCols, Length(Cols));
    SetLength(ShortCols, Length(Cols));
    for i := 0 to Length(Cols) - 1 do
    begin
      NewCols[i]   := MapNewCol(TableName, Cols[i]);
      ShortCols[i] := ColShortForIndex(NewCols[i], Suffix);
    end;

    if IsUnique then Prefix := 'UQ_' else Prefix := 'IDX_';
    IdxNewName := Prefix + Suffix + '_' + string.Join('_', ShortCols);
    if Length(IdxNewName) > 64 then
      IdxNewName := Copy(IdxNewName, 1, 64);

    IdxRec.TableName := TableName;
    IdxRec.OldName   := IdxName;
    IdxRec.NewName   := IdxNewName;
    IdxRec.Columns   := NewCols;
    IdxRec.IsUnique  := IsUnique;

    // Detección de duplicado: si en la misma tabla ya existe un índice con
    // este NewName (mismo prefijo + mismas columnas), se omite el segundo.
    // Causa típica: el dump original tenía dos índices funcionalmente iguales
    // (mismas columnas, distinto nombre histórico). El nombre nuevo se calcula
    // a partir de las columnas, así que ambos colapsan al mismo identificador.
    // Ignorar el segundo evita el error MySQL "Duplicate key name".
    if IsDuplicateIndex(AIndexPlan, TableName, IdxNewName) then
    begin
      Log(Format('[WARN] Indice duplicado en %s: %s y otro previo apuntan a %s (mismas columnas). Se omite del SQL.',
        [TableName, IdxName, IdxNewName]));
      Continue;
    end;

    AIndexPlan.Add(IdxRec);
  end;
  Log(Format('Procesados %d índices', [AIndexPlan.Count]));
end;

function TViraCashNormalizer.BuildColumnRenameSQL(AColumnPlan: TColumnList): string;
var
  SB:          TStringBuilder;
  Rec:         TColumnRename;
  Count:       Integer;
  ByTable:     TDictionary<string, TList<TColumnRename>>;
  L:           TList<TColumnRename>;
  Tables:      TStringList;
  T:           string;
begin
  ByTable := TDictionary<string, TList<TColumnRename>>.Create;
  Tables := TStringList.Create;
  try
    Tables.CaseSensitive := True;
    Tables.Sorted := True;
    Tables.Duplicates := dupIgnore;

    for Rec in AColumnPlan do
    begin
      if not Rec.Changed then Continue;
      if not ByTable.TryGetValue(Rec.TableName, L) then
      begin
        L := TList<TColumnRename>.Create;
        ByTable.Add(Rec.TableName, L);
        Tables.Add(Rec.TableName);
      end;
      L.Add(Rec);
    end;

    SB := TStringBuilder.Create;
    try
      SB.AppendLine('-- ================================================================');
      SB.AppendLine('-- ViraCash: Migración de nombres de columnas (libro de estilo v1.0)');
      SB.AppendLine('-- Generado por ViraCashNormalizer.exe');
      SB.AppendLine('-- ================================================================');
      SB.AppendLine('-- IMPORTANTE: Ejecutar SOBRE UNA COPIA de la base de datos primero.');
      SB.AppendLine('-- IMPORTANTE: Hacer backup antes de aplicar a producción.');
      SB.AppendLine('-- ================================================================');
      SB.AppendLine;
      SB.AppendLine('SET FOREIGN_KEY_CHECKS=0;');
      SB.AppendLine('START TRANSACTION;');
      SB.AppendLine;

      for T in Tables do
      begin
        L := ByTable[T];
        Count := L.Count;
        SB.AppendLine('-- ----------------------------------------------------------------');
        SB.AppendLine(Format('-- %s (%d columnas a renombrar)', [T, Count]));
        SB.AppendLine('-- ----------------------------------------------------------------');
        for Rec in L do
        begin
          SB.AppendLine(Format(
            'ALTER TABLE `%s` CHANGE COLUMN `%s` `%s` %s;',
            [Rec.TableName, Rec.OldName, Rec.NewName, Rec.Definition]));
        end;
        SB.AppendLine;
      end;

      SB.AppendLine('COMMIT;');
      SB.AppendLine('SET FOREIGN_KEY_CHECKS=1;');
      SB.AppendLine;
      SB.AppendLine('-- Fin del script.');

      Result := SB.ToString;
    finally
      SB.Free;
    end;
  finally
    for L in ByTable.Values do L.Free;
    ByTable.Free;
    Tables.Free;
  end;
end;

function TViraCashNormalizer.BuildIndexRenameSQL(AIndexPlan: TIndexList): string;
var
  SB:   TStringBuilder;
  Rec:  TIndexRename;
  Cols: string;
  C:    string;
  i:    Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('-- ================================================================');
    SB.AppendLine('-- ViraCash: Renombrado de índices (libro de estilo v1.0)');
    SB.AppendLine('-- Generado por ViraCashNormalizer.exe');
    SB.AppendLine('-- ================================================================');
    SB.AppendLine;
    SB.AppendLine('SET FOREIGN_KEY_CHECKS=0;');
    SB.AppendLine('START TRANSACTION;');
    SB.AppendLine;

    for Rec in AIndexPlan do
    begin
      Cols := '';
      for i := 0 to Length(Rec.Columns) - 1 do
      begin
        if i > 0 then Cols := Cols + ', ';
        Cols := Cols + '`' + Rec.Columns[i] + '`';
      end;
      SB.AppendLine(Format('ALTER TABLE `%s` DROP INDEX `%s`;',
        [Rec.TableName, Rec.OldName]));
      if Rec.IsUnique then
        SB.AppendLine(Format('ALTER TABLE `%s` ADD UNIQUE INDEX `%s` (%s);',
          [Rec.TableName, Rec.NewName, Cols]))
      else
        SB.AppendLine(Format('ALTER TABLE `%s` ADD INDEX `%s` (%s);',
          [Rec.TableName, Rec.NewName, Cols]));
    end;

    SB.AppendLine;
    SB.AppendLine('COMMIT;');
    SB.AppendLine('SET FOREIGN_KEY_CHECKS=1;');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TViraCashNormalizer.BuildPlanCSV(AColumnPlan: TColumnList): string;
var
  SB:  TStringBuilder;
  Rec: TColumnRename;

  function CsvEscape(const S: string): string;
  begin
    if S.Contains('"') or S.Contains(',') or S.Contains(#10) or S.Contains(#13) then
      Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
    else
      Result := S;
  end;

begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('tabla,columna_actual,columna_nueva,cambia,definicion');
    for Rec in AColumnPlan do
    begin
      SB.AppendLine(Format('%s,%s,%s,%s,%s',
        [CsvEscape(Rec.TableName),
         CsvEscape(Rec.OldName),
         CsvEscape(Rec.NewName),
         IfThen(Rec.Changed, 'SI', 'NO'),
         CsvEscape(Rec.Definition)]));
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.

unit UniDataContadorLineasRepositorio;

{
  Unidad: inLibContadorLineas
  Helper generico para asignar el siguiente numero de LINEA en documentos
  (facturas, sesiones de compra, pedidos, albaranes).

  Patron unificado: la cabecera de cada documento tiene una columna
  CONTADOR_LINEAS_X (X = FAC, SES, PED, ALB) que actua como contador
  monotono. Cada nueva linea pide al helper el siguiente valor y este
  bloquea la cabecera, calcula CONTADOR_X + 10 y actualiza la cabecera
  dentro de la transaccion activa.

  Equivalente generico al SP PRC_FNC_GET_NEXT_LINEA_FACTURA que ya existia
  solo para facturas; lo sustituye en sesiones desde inicio y queda
  disponible para migrar pedidos / albaranes / facturas cuando interese.

  El campo CONTADOR_LINEAS_X puede ser varchar (FAC/PED/ALB) o int (SES);
  el CAST(... AS UNSIGNED) en el UPDATE absorbe la diferencia.
}

interface

uses
  Uni,
  inLibContadorLineas;

type
  TInfoContadorLineas = inLibContadorLineas.TInfoContadorLineas;
  TInfoLineasDoc = inLibContadorLineas.TInfoLineasDoc;

const
  CONT_FACTURAS : TInfoContadorLineas = (
    TablaHdr     : 'fza_facturas';
    ColContador  : 'CONTADOR_LINEAS_FAC';
    ColSerieHdr  : 'SERIE_FAC';
    ColNumeroHdr : 'NUMERO_FAC'
  );
  CONT_SESIONES : TInfoContadorLineas = (
    TablaHdr     : 'fza_compras_sesiones';
    ColContador  : 'CONTADOR_LINEAS_SES';
    ColSerieHdr  : 'SERIE_SES';
    ColNumeroHdr : 'NUMERO_SES'
  );
  CONT_PEDIDOS : TInfoContadorLineas = (
    TablaHdr     : 'fza_pedidos';
    ColContador  : 'CONTADOR_LINEAS_PED';
    ColSerieHdr  : 'SERIE_PED';
    ColNumeroHdr : 'NUMERO_PED'
  );
  CONT_ALBARANES : TInfoContadorLineas = (
    TablaHdr     : 'fza_albaranes';
    ColContador  : 'CONTADOR_LINEAS_ALB';
    ColSerieHdr  : 'SERIE_ALB';
    ColNumeroHdr : 'NUMERO_ALB'
  );
  CONT_ALBARANES_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_albaranes_compra';
    ColContador  : 'CONTADOR_LINEAS_ALBC';
    ColSerieHdr  : 'SERIE_ALBC';
    ColNumeroHdr : 'NUMERO_ALBC'
  );
  CONT_PEDIDOS_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_pedidos_compra';
    ColContador  : 'CONTADOR_LINEAS_PEDC';
    ColSerieHdr  : 'SERIE_PEDC';
    ColNumeroHdr : 'NUMERO_PEDC'
  );
  CONT_DEVOLUCIONES_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_devoluciones_compra';
    ColContador  : 'CONTADOR_LINEAS_DEVC';
    ColSerieHdr  : 'SERIE_DEVC';
    ColNumeroHdr : 'NUMERO_DEVC'
  );
  CONT_FACTURAS_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_facturas_compra';
    ColContador  : 'CONTADOR_LINEAS_FACC';
    ColSerieHdr  : 'SERIE_FACC';
    ColNumeroHdr : 'NUMERO_FACC'
  );
  LIN_FACTURAS : TInfoLineasDoc = (
    TablaLin     : 'fza_facturas_lineas';
    ColSerieLin  : 'SERIE_FAC_FACLIN';
    ColNumeroLin : 'NUMERO_FAC_FACLIN';
    ColLinea     : 'LINEA_FACLIN'
  );
  LIN_PEDIDOS : TInfoLineasDoc = (
    TablaLin     : 'fza_pedidos_lineas';
    ColSerieLin  : 'SERIE_PED_PEDLIN';
    ColNumeroLin : 'NUMERO_PED_PEDLIN';
    ColLinea     : 'LINEA_PEDLIN'
  );
  LIN_ALBARANES : TInfoLineasDoc = (
    TablaLin     : 'fza_albaranes_lineas';
    ColSerieLin  : 'SERIE_ALB_ALBLIN';
    ColNumeroLin : 'NUMERO_ALB_ALBLIN';
    ColLinea     : 'LINEA_ALBLIN'
  );
  LIN_ALBARANES_COMPRA : TInfoLineasDoc = (
    TablaLin     : 'fza_albaranes_compra_lineas';
    ColSerieLin  : 'SERIE_ALBC_ALBCLIN';
    ColNumeroLin : 'NUMERO_ALBC_ALBCLIN';
    ColLinea     : 'LINEA_ALBCLIN'
  );
  LIN_PEDIDOS_COMPRA : TInfoLineasDoc = (
    TablaLin     : 'fza_pedidos_compra_lineas';
    ColSerieLin  : 'SERIE_PEDC_PEDCLIN';
    ColNumeroLin : 'NUMERO_PEDC_PEDCLIN';
    ColLinea     : 'LINEA_PEDCLIN'
  );
  LIN_DEVOLUCIONES_COMPRA : TInfoLineasDoc = (
    TablaLin     : 'fza_devoluciones_compra_lineas';
    ColSerieLin  : 'SERIE_DEVC_DEVCLIN';
    ColNumeroLin : 'NUMERO_DEVC_DEVCLIN';
    ColLinea     : 'LINEA_DEVCLIN'
  );
  LIN_FACTURAS_COMPRA : TInfoLineasDoc = (
    TablaLin     : 'fza_facturas_compra_lineas';
    ColSerieLin  : 'SERIE_FACC_FACCLIN';
    ColNumeroLin : 'NUMERO_FACC_FACCLIN';
    ColLinea     : 'LINEA_FACCLIN'
  );

function CrearContadorLineasDocumento(
  AConexion: TUniConnection): IContadorLineasDocumento;

implementation

uses
  System.SysUtils;

function GetSiguienteLineaDoc(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const sSerie, sNumero: string): Integer; forward;
function GetSiguienteLineaDocLibre(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero: string): Integer; forward;
function GetSiguienteLineaDocLibreSiguiente(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero: string): Integer; forward;
function LineaDocExiste(
  AConexion: TUniConnection;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero, sLinea: string): Boolean; forward;

type
  TContadorLineasDocumento = class(
    TInterfacedObject,
    IContadorLineasDocumento)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function GetSiguienteLineaDoc(
      const AInfo: TInfoContadorLineas;
      const ASerie, ANumero: string): Integer;
    function GetSiguienteLineaDocLibre(
      const AInfo: TInfoContadorLineas;
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero: string): Integer;
    function GetSiguienteLineaDocLibreSiguiente(
      const AInfo: TInfoContadorLineas;
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero: string): Integer;
    function LineaDocExiste(
      const ALineas: TInfoLineasDoc;
      const ASerie, ANumero, ALinea: string): Boolean;
  end;

function GetSiguienteLineaDoc(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const sSerie, sNumero: string
): Integer;
var
  q             : TUniQuery;
  iFilas        : Integer;
  bTransPropia  : Boolean;
begin
  Result := 0;
  if (sSerie <> '') and (sNumero <> '') then
  begin
  bTransPropia := not AConexion.InTransaction;
  if bTransPropia then
    AConexion.StartTransaction;
  q := TUniQuery.Create(nil);
  try
    try
      q.Connection := AConexion;
      // Bloqueo pesimista de la cabecera: el contador de lineas vive en el
      // propio documento. Si el llamador ya abrio una transaccion, el
      // bloqueo queda dentro de ella.
      q.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(' + Info.ColContador +
        ' AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM ' + Info.TablaHdr + ' ' +
        ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
        '   AND ' + Info.ColNumeroHdr + ' = :pnumero ' +
        ' FOR UPDATE';
      q.ParamByName('pserie').AsString  := sSerie;
      q.ParamByName('pnumero').AsString := sNumero;
      q.Open;
      try
        if not q.Eof then
          Result := q.FieldByName('NV').AsInteger + 10;
      finally
        q.Close;
      end;

      if Result > 0 then
      begin
        q.SQL.Text :=
          'UPDATE ' + Info.TablaHdr + ' ' +
          '   SET ' + Info.ColContador + ' = :pnuevo ' +
          ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
          '   AND ' + Info.ColNumeroHdr + ' = :pnumero';
        q.ParamByName('pnuevo').AsString  := Format('%.8d', [Result]);
        q.ParamByName('pserie').AsString  := sSerie;
        q.ParamByName('pnumero').AsString := sNumero;
        q.ExecSQL;
        iFilas := q.RowsAffected;
        if iFilas = 0 then
          Result := 0;
      end;

      if bTransPropia and AConexion.InTransaction then
        AConexion.Commit;
    except
      if bTransPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
  end;
end;

function MaxLineaDoc(AConexion: TUniConnection;
                     const Lineas: TInfoLineasDoc;
                     const sSerie, sNumero: string): Integer;
var
  q: TUniQuery;
begin
  Result := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'SELECT IFNULL(MAX(CAST(NULLIF(TRIM(' + Lineas.ColLinea +
      '), '''') AS UNSIGNED)), 0) AS NV ' +
      '  FROM ' + Lineas.TablaLin + ' ' +
      ' WHERE ' + Lineas.ColSerieLin  + ' = :pserie ' +
      '   AND ' + Lineas.ColNumeroLin + ' = :pnumero';
    q.ParamByName('pserie').AsString  := sSerie;
    q.ParamByName('pnumero').AsString := sNumero;
    q.Open;
    if not q.Eof then
      Result := q.FieldByName('NV').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

function GetSiguienteLineaDocLibre(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero: string
): Integer;
var
  q             : TUniQuery;
  iFilas        : Integer;
  iMaxLineas    : Integer;
  bTransPropia  : Boolean;
begin
  Result := 0;
  if (sSerie <> '') and (sNumero <> '') then
  begin
  bTransPropia := not AConexion.InTransaction;
  if bTransPropia then
    AConexion.StartTransaction;
  q := TUniQuery.Create(nil);
  try
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(' + Info.ColContador +
        ' AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM ' + Info.TablaHdr + ' ' +
        ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
        '   AND ' + Info.ColNumeroHdr + ' = :pnumero ' +
        ' FOR UPDATE';
      q.ParamByName('pserie').AsString  := sSerie;
      q.ParamByName('pnumero').AsString := sNumero;
      q.Open;
      try
        if not q.Eof then
          Result := q.FieldByName('NV').AsInteger;
      finally
        q.Close;
      end;
      iMaxLineas := MaxLineaDoc(AConexion, Lineas, sSerie, sNumero);
      if iMaxLineas > Result then
        Result := iMaxLineas;
      if Result > 0 then
        Result := Result + 10
      else if iMaxLineas = 0 then
        Result := 10;
      if Result > 0 then
      begin
        q.SQL.Text :=
          'UPDATE ' + Info.TablaHdr + ' ' +
          '   SET ' + Info.ColContador + ' = :pnuevo ' +
          ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
          '   AND ' + Info.ColNumeroHdr + ' = :pnumero';
        q.ParamByName('pnuevo').AsString  := Format('%.8d', [Result]);
        q.ParamByName('pserie').AsString  := sSerie;
        q.ParamByName('pnumero').AsString := sNumero;
        q.ExecSQL;
        iFilas := q.RowsAffected;
        if iFilas = 0 then
          Result := 0;
      end;
      if bTransPropia and AConexion.InTransaction then
        AConexion.Commit;
    except
      if bTransPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
  end;
end;

function GetSiguienteLineaDocLibreSiguiente(
  AConexion: TUniConnection;
  const Info: TInfoContadorLineas;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero: string
): Integer;
var
  q             : TUniQuery;
  iFilas        : Integer;
  iMaxLineas    : Integer;
  iContador     : Integer;
  bTransPropia  : Boolean;
begin
  Result := 0;
  if (sSerie <> '') and (sNumero <> '') then
  begin
  bTransPropia := not AConexion.InTransaction;
  if bTransPropia then
    AConexion.StartTransaction;
  q := TUniQuery.Create(nil);
  try
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(' + Info.ColContador +
        ' AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM ' + Info.TablaHdr + ' ' +
        ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
        '   AND ' + Info.ColNumeroHdr + ' = :pnumero ' +
        ' FOR UPDATE';
      q.ParamByName('pserie').AsString  := sSerie;
      q.ParamByName('pnumero').AsString := sNumero;
      q.Open;
      try
        if not q.Eof then
          iContador := q.FieldByName('NV').AsInteger
        else
          iContador := 0;
      finally
        q.Close;
      end;
      iMaxLineas := MaxLineaDoc(AConexion, Lineas, sSerie, sNumero);
      if iContador <= 0 then
        Result := 10
      else
        Result := iContador;
      if Result <= iMaxLineas then
        Result := iMaxLineas + 10;
      if Result > 0 then
      begin
        q.SQL.Text :=
          'UPDATE ' + Info.TablaHdr + ' ' +
          '   SET ' + Info.ColContador + ' = :pnuevo ' +
          ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
          '   AND ' + Info.ColNumeroHdr + ' = :pnumero';
        q.ParamByName('pnuevo').AsString  := Format('%.8d', [Result + 10]);
        q.ParamByName('pserie').AsString  := sSerie;
        q.ParamByName('pnumero').AsString := sNumero;
        q.ExecSQL;
        iFilas := q.RowsAffected;
        if iFilas = 0 then
          Result := 0;
      end;
      if bTransPropia and AConexion.InTransaction then
        AConexion.Commit;
    except
      if bTransPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
  end;
end;

function LineaDocExiste(
  AConexion: TUniConnection;
  const Lineas: TInfoLineasDoc;
  const sSerie, sNumero, sLinea: string
): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if (sSerie <> '') and (sNumero <> '') and (sLinea <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT 1 AS EXISTE ' +
        '  FROM ' + Lineas.TablaLin + ' ' +
        ' WHERE ' + Lineas.ColSerieLin  + ' = :pserie ' +
        '   AND ' + Lineas.ColNumeroLin + ' = :pnumero ' +
        '   AND ' + Lineas.ColLinea     + ' = :plinea ' +
        ' LIMIT 1';
      q.ParamByName('pserie').AsString  := sSerie;
      q.ParamByName('pnumero').AsString := sNumero;
      q.ParamByName('plinea').AsString  := sLinea;
      q.Open;
      Result := not q.Eof;
    finally
      FreeAndNil(q);
    end;
  end;
end;

constructor TContadorLineasDocumento.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TContadorLineasDocumento.GetSiguienteLineaDoc(
  const AInfo: TInfoContadorLineas;
  const ASerie, ANumero: string): Integer;
begin
  Result := UniDataContadorLineasRepositorio.GetSiguienteLineaDoc(
    FConexion,
    AInfo,
    ASerie,
    ANumero);
end;

function TContadorLineasDocumento.GetSiguienteLineaDocLibre(
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
begin
  Result := UniDataContadorLineasRepositorio.GetSiguienteLineaDocLibre(
    FConexion,
    AInfo,
    ALineas,
    ASerie,
    ANumero);
end;

function TContadorLineasDocumento.GetSiguienteLineaDocLibreSiguiente(
  const AInfo: TInfoContadorLineas;
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero: string): Integer;
begin
  Result :=
    UniDataContadorLineasRepositorio.GetSiguienteLineaDocLibreSiguiente(
      FConexion,
      AInfo,
      ALineas,
      ASerie,
      ANumero);
end;

function TContadorLineasDocumento.LineaDocExiste(
  const ALineas: TInfoLineasDoc;
  const ASerie, ANumero, ALinea: string): Boolean;
begin
  Result := UniDataContadorLineasRepositorio.LineaDocExiste(
    FConexion,
    ALineas,
    ASerie,
    ANumero,
    ALinea);
end;

function CrearContadorLineasDocumento(
  AConexion: TUniConnection): IContadorLineasDocumento;
begin
  Result := TContadorLineasDocumento.Create(AConexion);
end;

end.

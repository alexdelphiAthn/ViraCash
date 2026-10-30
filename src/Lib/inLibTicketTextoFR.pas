{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTicketTextoFR                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Texto ESC/POS desde plantillas editables de reparación.                  }
{******************************************************************************}
unit inLibTicketTextoFR;

interface

uses
  frxClass, inLibFTicket;

// El formato sigue siendo editable, pero la impresora recibe texto ESC/POS.
// AInforme debe tener sus páginas preparadas con los datos actuales.
procedure ComponerTicketTextoDesdeInforme(AInforme: TfrxReport;
  ATicket: TTicketTermico);

implementation

uses
  System.SysUtils, System.Classes, System.Math, System.UITypes,
  System.Generics.Collections, System.Generics.Defaults,
  Vcl.Graphics, frBaseGraphicsTypes;

resourcestring
  SFormatoTicketTextoInvalido = 'El formato de ticket ESC/POS admite ' +
    'texto horizontal con bordes. Revise el objeto %s en Editar.';
  SColumnasTicketSolapadas = 'Hay columnas solapadas en el ticket. ' +
    'Sepárelas en Editar o colóquelas en líneas distintas.';

type
  TCeldaTicket = record
    Inicio: Integer;
    Ancho: Integer;
    Lineas: TArray<string>;
    Negrita: Boolean;
    Subrayado: Boolean;
    Alineacion: TfrxHAlign;
  end;

function TextoSeguro(const ATexto: string): string;
var
  c: Char;
begin
  Result := '';
  for c in ATexto do
    if c = #9 then
      Result := Result + ' '
    else if (c >= ' ') or CharInSet(c, [#13, #10]) then
      Result := Result + c;
end;

function Envolver(const ATexto: string; AAncho: Integer): TArray<string>;
var
  stParrafos: TStringList;
  sResto: string;
  i, iCorte: Integer;
begin
  Result := nil;
  stParrafos := TStringList.Create;
  try
    stParrafos.Text := TextoSeguro(ATexto);
    for i := 0 to stParrafos.Count - 1 do
    begin
      sResto := Trim(stParrafos[i]);
      while Length(sResto) > AAncho do
      begin
        iCorte := AAncho;
        while (iCorte > 1) and (sResto[iCorte + 1] <> ' ') do
          Dec(iCorte);
        if iCorte = 1 then
          iCorte := AAncho;
        Result := Result + [TrimRight(Copy(sResto, 1, iCorte))];
        sResto := TrimLeft(Copy(sResto, iCorte + 1, MaxInt));
      end;
      Result := Result + [sResto];
    end;
  finally
    stParrafos.Free;
  end;
end;

function Celda(AMemo: TfrxMemoView; AAncho: Extended): TCeldaTicket;
begin
  Result.Inicio := Max(0, Floor(AMemo.AbsLeft / AAncho * N_CHAR_LIN));
  Result.Ancho := Max(1, Min(N_CHAR_LIN - Result.Inicio,
    Round(AMemo.Width / AAncho * N_CHAR_LIN)));
  Result.Lineas := Envolver(TrimRight(AMemo.Text), Result.Ancho);
  Result.Negrita := (fsBold in AMemo.Font.Style) or (AMemo.Font.Size >= 12);
  Result.Subrayado := fsUnderline in AMemo.Font.Style;
  Result.Alineacion := AMemo.HAlign;
end;

function AlinearTexto(const ATexto: string; AAncho: Integer;
  AAlineacion: TfrxHAlign): string;
var
  iEspacios: Integer;
begin
  iEspacios := 0;
  if AAlineacion = haRight then
    iEspacios := AAncho - Length(ATexto)
  else if AAlineacion = haCenter then
    iEspacios := (AAncho - Length(ATexto)) div 2;
  Result := StringOfChar(' ', Max(0, iEspacios)) + ATexto;
end;

procedure EscribirFila(ATicket: TTicketTermico;
  const ACeldas: TArray<TCeldaTicket>);
var
  iLinea, iAlto, iPosicion, iCelda: Integer;
  sTexto: string;
  rCelda: TCeldaTicket;
  bNegrita, bSubrayado: Boolean;
begin
  iAlto := 0;
  for rCelda in ACeldas do
    iAlto := Max(iAlto, Length(rCelda.Lineas));
  for iLinea := 0 to iAlto - 1 do
  begin
    iPosicion := 0;
    bNegrita := False;
    bSubrayado := False;
    for rCelda in ACeldas do
    begin
      bNegrita := bNegrita or rCelda.Negrita;
      bSubrayado := bSubrayado or rCelda.Subrayado;
    end;
    ATicket.Negrita(bNegrita);
    ATicket.Subrayado(bSubrayado);
    for iCelda := 0 to High(ACeldas) do
    begin
      rCelda := ACeldas[iCelda];
      if iLinea < Length(rCelda.Lineas) then
      begin
        if rCelda.Inicio < iPosicion then
          raise EArgumentException.Create(SColumnasTicketSolapadas);
        ATicket.EscribirTexto(StringOfChar(' ', rCelda.Inicio - iPosicion));
        sTexto := AlinearTexto(rCelda.Lineas[iLinea], rCelda.Ancho,
          rCelda.Alineacion);
        ATicket.EscribirTexto(sTexto);
        iPosicion := rCelda.Inicio + Length(sTexto);
      end;
    end;
    ATicket.EscribirLinea('');
    ATicket.Negrita(False);
    ATicket.Subrayado(False);
  end;
end;

procedure EscribirGrupo(ATicket: TTicketTermico;
  ATextos: TList<TfrxMemoView>; AInicio, AFin: Integer; AAncho: Extended);
var
  aCeldas: TArray<TCeldaTicket>;
  i: Integer;
  bAntes, bDespues: Boolean;
begin
  bAntes := False;
  bDespues := False;
  SetLength(aCeldas, AFin - AInicio);
  for i := AInicio to AFin - 1 do
  begin
    aCeldas[i - AInicio] := Celda(ATextos[i], AAncho);
    bAntes := bAntes or (ftTop in ATextos[i].Frame.Typ);
    bDespues := bDespues or (ftBottom in ATextos[i].Frame.Typ);
  end;
  if bAntes then
    ATicket.LineaSeparadora;
  EscribirFila(ATicket, aCeldas);
  if bDespues then
    ATicket.LineaSeparadora;
end;

procedure ComponerPagina(APagina: TfrxReportPage; ATicket: TTicketTermico);
var
  oTextos: TList<TfrxMemoView>;
  oObjeto: TfrxComponent;
  oMemo: TfrxMemoView;
  i, iFin: Integer;
  dAncho, dAnterior, dFondo: Extended;
begin
  dAncho := (APagina.PaperWidth - APagina.LeftMargin -
    APagina.RightMargin) * 3.77953;
  oTextos := TList<TfrxMemoView>.Create;
  try
    for i := 0 to APagina.AllObjects.Count - 1 do
    begin
      oObjeto := TfrxComponent(APagina.AllObjects[i]);
      if (oObjeto is TfrxMemoView) and TfrxMemoView(oObjeto).Visible then
      begin
        oMemo := TfrxMemoView(oObjeto);
        if Trim(oMemo.Text) <> '' then
        begin
          if (oMemo.Rotation <> 0) or (oMemo.AbsLeft < -1) or
             (oMemo.AbsLeft + oMemo.Width > dAncho + 2) then
            raise EArgumentException.CreateFmt(SFormatoTicketTextoInvalido,
              [oMemo.Name]);
          oTextos.Add(oMemo);
        end;
      end
      else if (oObjeto is TfrxView) and TfrxView(oObjeto).Visible then
        raise EArgumentException.CreateFmt(SFormatoTicketTextoInvalido,
          [oObjeto.Name]);
    end;
    oTextos.Sort(TComparer<TfrxMemoView>.Construct(
      function(const A, B: TfrxMemoView): Integer
      begin
        Result := CompareValue(A.AbsTop, B.AbsTop, 0.5);
        if Result = 0 then
          Result := CompareValue(A.AbsLeft, B.AbsLeft, 0.5);
      end));
    i := 0;
    dAnterior := 0;
    while i < oTextos.Count do
    begin
      iFin := i + 1;
      dFondo := oTextos[i].AbsTop + oTextos[i].Height;
      while (iFin < oTextos.Count) and
            (Abs(oTextos[iFin].AbsTop - oTextos[i].AbsTop) <= 0.5) do
      begin
        dFondo := Max(dFondo, oTextos[iFin].AbsTop + oTextos[iFin].Height);
        Inc(iFin);
      end;
      if (i > 0) and (oTextos[i].AbsTop - dAnterior > 6) then
        ATicket.SaltarLineas(Min(3,
          Max(1, Round((oTextos[i].AbsTop - dAnterior) / 18))));
      EscribirGrupo(ATicket, oTextos, i, iFin, dAncho);
      dAnterior := dFondo;
      i := iFin;
    end;
  finally
    oTextos.Free;
  end;
end;

procedure ComponerTicketTextoDesdeInforme(AInforme: TfrxReport;
  ATicket: TTicketTermico);
var
  iPagina: Integer;
begin
  ATicket.Inicializar;
  ATicket.SeleccionarFuente(ftRasterA);
  ATicket.Alinear(alIzquierda);
  for iPagina := 0 to AInforme.PreviewPages.Count - 1 do
    ComponerPagina(AInforme.PreviewPages.Page[iPagina], ATicket);
  ATicket.AvanzarYCortarPapel(4);
end;

end.

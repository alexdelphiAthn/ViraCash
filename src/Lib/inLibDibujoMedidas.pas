{ Guías vectoriales para las fichas de taller. }
unit inLibDibujoMedidas;

interface

uses
  Vcl.Graphics, inLibMedidasCliente;

procedure DibujarGuiaMedidas(AImagen: TPicture; AFicha: TFichaMedidas);

implementation

uses
  System.Types, System.SysUtils;

procedure DibujarGuiaMedidas(AImagen: TPicture; AFicha: TFichaMedidas);
const
  Ancho = 300;
  Alto = 230;
  Tinta = $00483E23;
  Acento = $0059571B;
var
  Imagen: TMetafile;
  Lienzo: TMetafileCanvas;

  function Punto(X, Y: Integer): TPoint;
  begin
    if AFicha = fmPieDerecho then X := Ancho - X;
    Result := Point(X, Y);
  end;

  procedure Linea(X1, Y1, X2, Y2: Integer);
  var
    A, B: TPoint;
  begin
    A := Punto(X1, Y1);
    B := Punto(X2, Y2);
    Lienzo.MoveTo(A.X, A.Y);
    Lienzo.LineTo(B.X, B.Y);
  end;

  procedure Marca(X, Y, Numero: Integer);
  var
    P: TPoint;
    S: string;
  begin
    P := Punto(X, Y);
    Lienzo.Brush.Color := Acento;
    Lienzo.Ellipse(P.X - 11, P.Y - 11, P.X + 12, P.Y + 12);
    S := IntToStr(Numero);
    Lienzo.TextOut(P.X - Lienzo.TextWidth(S) div 2,
      P.Y - Lienzo.TextHeight(S) div 2, S);
    Lienzo.Brush.Style := bsClear;
  end;

  procedure Cota(X1, Y1, X2, Y2: Integer);
  begin
    Linea(X1, Y1, X2, Y2);
    if Y1 = Y2 then
    begin
      Linea(X1, Y1 - 4, X1, Y1 + 4);
      Linea(X2, Y2 - 4, X2, Y2 + 4);
    end
    else
    begin
      Linea(X1 - 4, Y1, X1 + 4, Y1);
      Linea(X2 - 4, Y2, X2 + 4, Y2);
    end;
  end;

  procedure Pie;
  begin
    // Vista dorsal. El dedo gordo queda en el borde medial de cada pie.
    Lienzo.PolyBezier([Punto(146,211), Punto(119,212), Punto(113,193),
      Punto(114,169), Punto(116,140), Punto(96,111), Punto(94,89),
      Punto(91,79), Punto(89,64), Punto(95,61), Punto(99,57),
      Punto(102,63), Punto(105,67), Punto(100,55), Punto(99,48),
      Punto(105,45), Punto(111,41), Punto(115,49), Punto(118,53),
      Punto(113,40), Punto(115,34), Punto(121,32), Punto(128,29),
      Punto(131,38), Punto(134,44), Punto(131,28), Punto(134,20),
      Punto(141,19), Punto(149,17), Punto(153,29), Punto(153,38),
      Punto(154,25), Punto(159,12), Punto(169,12), Punto(187,12),
      Punto(186,40), Punto(181,56), Punto(180,73), Punto(175,91),
      Punto(168,107), Punto(156,130), Punto(153,145), Punto(161,165),
      Punto(174,191), Punto(166,208), Punto(146,211)]);
    Lienzo.Pen.Color := Acento;
    Cota(210,12,210,211);
    Linea(185,12,210,12);
    Linea(151,211,210,211);
    Marca(210,183,1);
    Cota(94,82,177,82);
    Linea(72,82,94,82);
    Marca(65,82,2);
    Lienzo.PolyBezier([Punto(104,115),Punto(122,102),
      Punto(152,103),Punto(166,113)]);
    Lienzo.Pen.Style := psDash;
    Lienzo.PolyBezier([Punto(104,115),Punto(122,129),
      Punto(150,127),Punto(166,113)]);
    Lienzo.Pen.Style := psSolid;
    Linea(81,115,104,115);
    Marca(73,115,3);
  end;

  procedure Ropa;
  begin
    Lienzo.Polygon([Punto(125,25),Punto(84,42),Punto(45,153),
      Punto(64,163),Punto(94,98),Punto(89,201),Punto(211,201),
      Punto(206,98),Punto(236,163),Punto(255,153),Punto(216,42),
      Punto(175,25)]);
    if AFicha = fmTraje then
    begin
      Lienzo.Polyline([Punto(125,25),Punto(111,49),Punto(129,54),
        Punto(120,64),Punto(150,100),Punto(150,201)]);
      Lienzo.Polyline([Punto(175,25),Punto(189,49),Punto(171,54),
        Punto(180,64),Punto(150,100),Punto(125,25)]);
      Linea(175,25,150,100);
      Linea(101,153,124,150);
      Linea(177,150,199,153);
    end
    else
      Lienzo.PolyBezier([Punto(125,25),Punto(132,51),
        Punto(168,51),Punto(175,25)]);
    Lienzo.Pen.Color := Acento;
    Cota(84,14,216,14);
    Linea(84,14,84,39);
    Linea(216,14,216,39);
    Marca(150,14,1);
    Cota(95,88,205,88);
    Marca(117,88,2);
    Cota(93,131,207,131);
    Marca(117,131,3);
    Cota(71,42,32,152);
    Marca(48,109,4);
    Cota(272,29,272,201);
    Linea(214,201,272,201);
    Marca(272,119,5);
  end;

begin
  Imagen := TMetafile.Create;
  try
    Imagen.Width := Ancho;
    Imagen.Height := Alto;
    Lienzo := TMetafileCanvas.Create(Imagen, 0);
    try
      Lienzo.Brush.Color := clWhite;
      Lienzo.FillRect(Rect(0, 0, Ancho, Alto));
      Lienzo.Brush.Style := bsClear;
      Lienzo.Pen.Color := Tinta;
      Lienzo.Pen.Width := 2;
      Lienzo.Font.Name := 'Segoe UI';
      Lienzo.Font.Height := -15;
      Lienzo.Font.Style := [fsBold];
      Lienzo.Font.Color := clWhite;
      if AFicha in [fmPieIzquierdo, fmPieDerecho] then Pie else Ropa;
    finally
      Lienzo.Free;
    end;
    AImagen.Assign(Imagen);
  finally
    Imagen.Free;
  end;
end;

end.

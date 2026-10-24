{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComprasSesionesPresentacionPestanas                      }
{    Tipo:       Colaborador VCL                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Copa (eje de pestañas) en las líneas de una sesión de compra: columna     }
{    con sus valores, botones «Otra copa» y «Todas las copas» y pestañas que   }
{    filtran las líneas (tercera dimensión, fase 4). Con un tipo de            }
{    variación sin pestañas todo queda oculto y la pantalla, como siempre.     }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionPestanas;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls,
  Data.DB,
  cxButtons, cxCustomData, cxDropDownEdit, cxFilter, cxGridDBTableView,
  inLibPestanasEje, inLibPestanasEjeVcl, inLibVariacionesRotulos,
  inMtoComprasSesionesPresentacionCopiaLineas;

type
  TEntornoPestanasSesion = record
    Vista: TcxGridDBTableView;
    // Columna enlazada a PESTANA_TEXTO_SESLIN.
    Columna: TcxGridDBColumn;
    Lineas: TDataSet;
    // Los botones nuevos van detrás de BotonReferencia («Otro color»).
    BotonReferencia: TcxButton;
    // Las pestañas van dentro de Contenedor, encima de Rejilla.
    Contenedor: TWinControl;
    Rejilla: TControl;
    ObtenerCopia: TFunc<TCoordinadorCopiaLineasSesion>;
    // Valores del atributo de pestañas, en su orden.
    LeerValores: TFunc<string, TArray<string>>;
    Avisar: TProc<string>;
    RecargarCantidades: TProc;
  end;

  TPresentadorPestanasSesion = class
  private
    FEntorno: TEntornoPestanasSesion;
    FRotulos: TRotulosVariacion;
    FValores: TArray<string>;
    FBotonOtra: TcxButton;
    FBotonTodas: TcxButton;
    FAltoBarraOriginal: Integer;
    FPestanas: TControlPestanasEje;
    function CrearBoton(AIzquierda: Integer;
      AOnClick: TNotifyEvent): TcxButton;
    procedure BotonOtraClick(Sender: TObject);
    procedure BotonTodasClick(Sender: TObject);
    procedure AplicarFiltro(const ACodigo: string);
    procedure CargarValoresColumna;
    function Copia: TCoordinadorCopiaLineasSesion;
  public
    constructor Create(AOwner: TComponent;
      const AEntorno: TEntornoPestanasSesion);
    destructor Destroy; override;
    // Rótulos del tipo de variación de la sesión: muestra u oculta la
    // columna, los botones y las pestañas.
    procedure AplicarRotulos(const ARotulos: TRotulosVariacion);
    // Recalcula las pestañas con las copas y unidades de las líneas;
    // conserva la elegida.
    procedure RefrescarPestanas;
  end;

implementation

uses
  System.Variants, inLibMsgCompras;

const
  CAMPO_PESTANA = 'PESTANA_TEXTO_SESLIN';
  CAMPO_UNIDADES = 'TOTAL_UNIDADES_SESLIN';
  SEPARACION_BOTONES = 6;

constructor TPresentadorPestanasSesion.Create(AOwner: TComponent;
  const AEntorno: TEntornoPestanasSesion);
var
  iIzquierda: Integer;
begin
  inherited Create;
  if AEntorno.Vista = nil then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if AEntorno.Columna = nil then
    raise EArgumentNilException.Create('AEntorno.Columna');
  if AEntorno.Lineas = nil then
    raise EArgumentNilException.Create('AEntorno.Lineas');
  FEntorno := AEntorno;
  FAltoBarraOriginal := FEntorno.BotonReferencia.Parent.Height;
  iIzquierda := 4;
  FBotonOtra := CrearBoton(iIzquierda, BotonOtraClick);
  FBotonTodas := CrearBoton(iIzquierda + FBotonOtra.Width +
    SEPARACION_BOTONES, BotonTodasClick);
  FPestanas := TControlPestanasEje.Create(AOwner, FEntorno.Contenedor,
    procedure(const ACodigo: string)
    begin
      AplicarFiltro(ACodigo);
    end);
  FPestanas.Control.Top := FEntorno.Rejilla.Top - 1;
  FEntorno.Columna.Visible := False;
  FEntorno.Columna.VisibleForCustomization := False;
end;

destructor TPresentadorPestanasSesion.Destroy;
begin
  FreeAndNil(FPestanas);
  FreeAndNil(FBotonOtra);
  FreeAndNil(FBotonTodas);
  FEntorno.BotonReferencia.Parent.Height := FAltoBarraOriginal;
  inherited Destroy;
end;

// Mismo aspecto que «Otro color», al que acompañan.
function TPresentadorPestanasSesion.CrearBoton(AIzquierda: Integer;
  AOnClick: TNotifyEvent): TcxButton;
var
  oReferencia: TcxButton;
begin
  oReferencia := FEntorno.BotonReferencia;
  Result := TcxButton.Create(oReferencia.Owner);
  Result.Parent := oReferencia.Parent;
  Result.SetBounds(AIzquierda, FAltoBarraOriginal + 4, 240,
    oReferencia.Height);
  Result.Colors.Default := oReferencia.Colors.Default;
  Result.Colors.Normal := oReferencia.Colors.Normal;
  Result.LookAndFeel.Assign(oReferencia.LookAndFeel);
  Result.Visible := False;
  Result.OnClick := AOnClick;
end;

function TPresentadorPestanasSesion.Copia: TCoordinadorCopiaLineasSesion;
begin
  Result := nil;
  if Assigned(FEntorno.ObtenerCopia) then
    Result := FEntorno.ObtenerCopia();
end;

procedure TPresentadorPestanasSesion.CargarValoresColumna;
var
  oPropiedades: TcxComboBoxProperties;
  sValor: string;
begin
  FValores := nil;
  if FRotulos.TienePestanas and Assigned(FEntorno.LeerValores) then
    FValores := FEntorno.LeerValores(FRotulos.AtributoPestana);
  if FEntorno.Columna.Properties is TcxComboBoxProperties then
  begin
    oPropiedades := TcxComboBoxProperties(FEntorno.Columna.Properties);
    oPropiedades.Items.BeginUpdate;
    try
      oPropiedades.Items.Clear;
      for sValor in FValores do
        oPropiedades.Items.Add(sValor);
    finally
      oPropiedades.Items.EndUpdate;
    end;
  end;
end;

procedure TPresentadorPestanasSesion.AplicarRotulos(
  const ARotulos: TRotulosVariacion);
var
  bTieneCopas: Boolean;
  iRegistro: Integer;
begin
  bTieneCopas := ARotulos.TienePestanas;
  for iRegistro := 0 to FEntorno.Vista.DataController.RecordCount - 1 do
    if Trim(VarToStr(FEntorno.Vista.DataController.Values[
      iRegistro, FEntorno.Columna.Index])) <> '' then
      bTieneCopas := True;
  if ARotulos.TienePestanas or (not bTieneCopas) then
    FRotulos := ARotulos;
  if bTieneCopas and not FRotulos.TienePestanas then
  begin
    FRotulos.TienePestanas := True;
    FRotulos.EjePestana := 'Copa';
  end;
  FEntorno.Columna.Caption := FRotulos.EjePestana;
  FEntorno.Columna.Visible := bTieneCopas;
  FEntorno.Columna.VisibleForCustomization := bTieneCopas;
  FBotonOtra.Caption := ARotulos.OtroValorPestana;
  FBotonTodas.Caption := ARotulos.TodosValoresPestana;
  FBotonOtra.Visible := ARotulos.TienePestanas;
  FBotonTodas.Visible := ARotulos.TienePestanas;
  if ARotulos.TienePestanas then
    FEntorno.BotonReferencia.Parent.Height := FBotonOtra.Top +
      FBotonOtra.Height + 4
  else
    FEntorno.BotonReferencia.Parent.Height := FAltoBarraOriginal;
  CargarValoresColumna;
  RefrescarPestanas;
end;

procedure TPresentadorPestanasSesion.RefrescarPestanas;
var
  aValores: TArray<string>;
  aUnidades: TArray<Double>;
  oUnidades: TcxGridDBColumn;
  iRegistro: Integer;
  vUnidades: Variant;
begin
  if (not FRotulos.TienePestanas) or (not FEntorno.Lineas.Active) then
  begin
    FPestanas.Ocultar;
    AplicarFiltro('');
  end
  else
  begin
    aValores := nil;
    aUnidades := nil;
    oUnidades := FEntorno.Vista.GetColumnByFieldName(CAMPO_UNIDADES);
    // Recorrer el dataset con DisableControls resetea las columnas no
    // enlazadas de tallas al volver a EnableControls. Leer la rejilla
    // conserva el cursor, las ediciones y las cantidades por medida.
    for iRegistro := 0 to
      FEntorno.Vista.DataController.RecordCount - 1 do
    begin
      aValores := aValores + [VarToStr(FEntorno.Vista.DataController.
        Values[iRegistro, FEntorno.Columna.Index])];
      vUnidades := FEntorno.Vista.DataController.Values[
        iRegistro, oUnidades.Index];
      if VarIsNull(vUnidades) or VarIsEmpty(vUnidades) then
        aUnidades := aUnidades + [0]
      else
        aUnidades := aUnidades + [Double(vUnidades)];
    end;
    FPestanas.Mostrar(ModeloPestanasDeLineas(FRotulos.EjePestana, FValores,
      aValores, aUnidades));
    AplicarFiltro(FPestanas.CodigoSeleccionado);
  end;
end;

// Filtro de la vista, no del dataset: las cantidades por talla van por
// índice de registro y no se mueven al filtrar.
procedure TPresentadorPestanasSesion.AplicarFiltro(const ACodigo: string);
var
  oFiltro: TcxDataFilterCriteria;
begin
  oFiltro := FEntorno.Vista.DataController.Filter;
  oFiltro.BeginUpdate;
  try
    oFiltro.Root.Clear;
    if ACodigo <> '' then
      oFiltro.Root.AddItem(FEntorno.Columna, foEqual, ACodigo, ACodigo);
    oFiltro.Active := ACodigo <> '';
  finally
    oFiltro.EndUpdate;
  end;
  if Assigned(FEntorno.RecargarCantidades) then
    FEntorno.RecargarCantidades();
end;

procedure TPresentadorPestanasSesion.BotonOtraClick(Sender: TObject);
begin
  if Copia <> nil then
  begin
    // La copia nace sin copa: con una pestaña elegida quedaría oculta.
    FPestanas.SeleccionarTodas;
    AplicarFiltro('');
    Copia.DuplicarLineaOtraPestana;
    RefrescarPestanas;
  end;
end;

procedure TPresentadorPestanasSesion.BotonTodasClick(Sender: TObject);
begin
  if Length(FValores) = 0 then
  begin
    if Assigned(FEntorno.Avisar) then
      FEntorno.Avisar(Format(SAvisoSinValoresPestanaSesion,
        [AnsiLowerCase(FRotulos.EjePestana)]));
  end
  else if Copia <> nil then
  begin
    FPestanas.SeleccionarTodas;
    AplicarFiltro('');
    Copia.DuplicarLineaTodasPestanas(FValores);
    RefrescarPestanas;
  end;
end;

end.

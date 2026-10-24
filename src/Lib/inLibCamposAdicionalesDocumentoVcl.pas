{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCamposAdicionalesDocumentoVcl                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Campos propios del diálogo común de creación de documentos, creados en   }
{    ejecución: texto, lista, casilla o código con búsqueda (y alta rápida).  }
{    Crea los controles, los coloca por filas y devuelve sus valores.          }
{******************************************************************************}
unit inLibCamposAdicionalesDocumentoVcl;

interface

uses
  System.Classes, Vcl.Controls,
  cxLabel, cxTextEdit, cxButtonEdit, cxDropDownEdit, cxCheckBox,
  cxEdit, cxButtons,
  inLibOpcionesDocumentoIntf;

type
  TControlesCampoAdicional = record
    Etiqueta: TcxLabel;
    Editor: TWinControl;
    Nombre: TcxLabel;
    BotonBuscar: TcxButton;
    // Códigos de la lista, por índice del combo.
    Codigos: TArray<string>;
  end;

  // Coordenadas en píxeles físicos, tomadas de los controles del DFM.
  TGeometriaCamposAdicionales = record
    IzquierdaEtiqueta: Integer;
    IzquierdaEditor: Integer;
    AnchoEditor: Integer;
    AnchoCodigo: Integer;
    AltoFila: Integer;
    DesfaseEtiqueta: Integer;
  end;

  TCamposAdicionalesDocumentoVcl = class
  private
    FCampos: TCamposAdicionalesOpcionesDocumento;
    FControles: TArray<TControlesCampoAdicional>;
    FGeometria: TGeometriaCamposAdicionales;
    FAlCambiar: TNotifyEvent;
    procedure CrearControles(AOwner: TComponent; AParent: TWinControl;
      AIndice: Integer);
    function CrearEditor(AOwner: TComponent; AParent: TWinControl;
      AIndice: Integer): TWinControl;
    function CrearBusqueda(AOwner: TComponent; AParent: TWinControl;
      AIndice: Integer): TWinControl;
    function IndiceDe(ASender: TObject): Integer;
    procedure BotonBusquedaClick(Sender: TObject; AButtonIndex: Integer);
    procedure EditorCambiado(Sender: TObject);
    procedure BuscarListaClick(Sender: TObject);
    procedure ResolverBusqueda(AIndice: Integer);
    procedure LeerValor(AIndice: Integer);
    procedure MostrarCampo(const AControles: TControlesCampoAdicional;
      AVisible: Boolean);
    procedure ColocarCampo(const AControles: TControlesCampoAdicional;
      var ATop: Integer);
  public
    constructor Create(AOwner: TComponent; AParent: TWinControl;
      const ACampos: TCamposAdicionalesOpcionesDocumento;
      const AGeometria: TGeometriaCamposAdicionales;
      AAlCambiar: TNotifyEvent);
    // Coloca los campos del principio o del final a partir de ATop y oculta
    // los que no se piden con el tipo de documento ATipo.
    procedure Colocar(AlPrincipio: Boolean; var ATop: Integer;
      const ATipo: string);
    procedure Habilitar(AHabilitado: Boolean);
    function Valores: TCamposAdicionalesOpcionesDocumento;
    function Editor(AIndice: Integer): TWinControl;
    // Ctrl+Enter sobre un campo de búsqueda abre su búsqueda.
    function BuscarEnfocado: Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TCamposAdicionalesDocumentoVcl.Create(AOwner: TComponent;
  AParent: TWinControl; const ACampos: TCamposAdicionalesOpcionesDocumento;
  const AGeometria: TGeometriaCamposAdicionales; AAlCambiar: TNotifyEvent);
var
  iIndice: Integer;
begin
  inherited Create;
  FCampos := Copy(ACampos);
  FGeometria := AGeometria;
  FAlCambiar := AAlCambiar;
  SetLength(FControles, Length(FCampos));
  for iIndice := 0 to High(FCampos) do
    CrearControles(AOwner, AParent, iIndice);
end;

// Parent antes que la geometría: el control se reescala al recibirlo y lo
// fijado después va en píxeles físicos.
procedure TCamposAdicionalesDocumentoVcl.CrearControles(AOwner: TComponent;
  AParent: TWinControl; AIndice: Integer);
var
  oEtiqueta: TcxLabel;
begin
  if FCampos[AIndice].Clase <> ccaCasilla then
  begin
    oEtiqueta := TcxLabel.Create(AOwner);
    oEtiqueta.Parent := AParent;
    oEtiqueta.Transparent := True;
    oEtiqueta.Caption := FCampos[AIndice].Etiqueta;
    oEtiqueta.Left := FGeometria.IzquierdaEtiqueta;
    FControles[AIndice].Etiqueta := oEtiqueta;
  end;
  FControles[AIndice].Editor := CrearEditor(AOwner, AParent, AIndice);
end;

function TCamposAdicionalesDocumentoVcl.CrearEditor(AOwner: TComponent;
  AParent: TWinControl; AIndice: Integer): TWinControl;
var
  oCampo: TCampoAdicionalOpcionesDocumento;
  oTexto: TcxTextEdit;
  oLista: TcxComboBox;
  oCasilla: TcxCheckBox;
  oElemento: TElementoOpcionesDocumento;
  iIndice: Integer;
  oBuscar: TcxButton;
begin
  oCampo := FCampos[AIndice];
  case oCampo.Clase of
    ccaTexto:
    begin
      oTexto := TcxTextEdit.Create(AOwner);
      oTexto.Parent := AParent;
      oTexto.Properties.MaxLength := oCampo.LongitudMaxima;
      oTexto.Text := oCampo.Valor;
      oTexto.Properties.OnEditValueChanged := EditorCambiado;
      Result := oTexto;
    end;
    ccaLista:
    begin
      oLista := TcxComboBox.Create(AOwner);
      oLista.Parent := AParent;
      oLista.Properties.DropDownListStyle := lsFixedList;
      oLista.Properties.DropDownRows := 12;
      if oCampo.ConVacio then
      begin
        FControles[AIndice].Codigos := [''];
        oLista.Properties.Items.Add('');
      end;
      for oElemento in oCampo.Elementos do
      begin
        FControles[AIndice].Codigos :=
          FControles[AIndice].Codigos + [oElemento.Codigo];
        oLista.Properties.Items.Add(oElemento.Nombre);
      end;
      oLista.ItemIndex := -1;
      for iIndice := 0 to High(FControles[AIndice].Codigos) do
      begin
        if FControles[AIndice].Codigos[iIndice] = oCampo.Valor then
          oLista.ItemIndex := iIndice;
      end;
      if Assigned(oCampo.Buscar) then
      begin
        oBuscar := TcxButton.Create(AOwner);
        oBuscar.Parent := AParent;
        oBuscar.Caption := '...';
        oBuscar.Tag := AIndice;
        oBuscar.OnClick := BuscarListaClick;
        FControles[AIndice].BotonBuscar := oBuscar;
      end;
      if (oLista.ItemIndex < 0) and oCampo.ConVacio then
        oLista.ItemIndex := 0;
      oLista.Properties.OnEditValueChanged := EditorCambiado;
      Result := oLista;
    end;
    ccaCasilla:
    begin
      oCasilla := TcxCheckBox.Create(AOwner);
      oCasilla.Parent := AParent;
      oCasilla.Transparent := True;
      oCasilla.Caption := oCampo.Etiqueta;
      oCasilla.Checked := oCampo.Valor = 'S';
      oCasilla.Properties.OnEditValueChanged := EditorCambiado;
      Result := oCasilla;
    end;
  else
    Result := CrearBusqueda(AOwner, AParent, AIndice);
  end;
  Result.Left := FGeometria.IzquierdaEditor;
  Result.Width := FGeometria.AnchoEditor;
  // La casilla lleva su texto: ocupa también la columna de las etiquetas.
  if oCampo.Clase = ccaCasilla then
  begin
    Result.Left := FGeometria.IzquierdaEtiqueta;
    Result.Width := FGeometria.IzquierdaEditor + FGeometria.AnchoEditor -
      FGeometria.IzquierdaEtiqueta;
  end;
end;

function TCamposAdicionalesDocumentoVcl.CrearBusqueda(AOwner: TComponent;
  AParent: TWinControl; AIndice: Integer): TWinControl;
var
  oBusqueda: TcxButtonEdit;
  oBoton: TcxEditButton;
  oNombre: TcxLabel;
begin
  oBusqueda := TcxButtonEdit.Create(AOwner);
  oBusqueda.Parent := AParent;
  oBusqueda.Properties.MaxLength := FCampos[AIndice].LongitudMaxima;
  // Sin búsqueda asignada el código sólo se teclea y se resuelve.
  oBusqueda.Properties.Buttons[0].Visible :=
    Assigned(FCampos[AIndice].Buscar);
  if Assigned(FCampos[AIndice].Alta) then
  begin
    oBoton := oBusqueda.Properties.Buttons.Add;
    oBoton.Kind := bkText;
    oBoton.Caption := '+';
  end;
  oBusqueda.Text := FCampos[AIndice].Valor;
  oBusqueda.Properties.OnButtonClick := BotonBusquedaClick;
  oBusqueda.Properties.OnEditValueChanged := EditorCambiado;
  oNombre := TcxLabel.Create(AOwner);
  oNombre.Parent := AParent;
  oNombre.Transparent := True;
  oNombre.Properties.ShowEndEllipsis := True;
  oNombre.AutoSize := False;
  oNombre.Caption := FCampos[AIndice].Descripcion;
  FControles[AIndice].Nombre := oNombre;
  Result := oBusqueda;
end;

procedure TCamposAdicionalesDocumentoVcl.Colocar(AlPrincipio: Boolean;
  var ATop: Integer; const ATipo: string);
var
  iIndice: Integer;
  bVisible: Boolean;
begin
  for iIndice := 0 to High(FCampos) do
  begin
    if FCampos[iIndice].AlPrincipio = AlPrincipio then
    begin
      bVisible := FCampos[iIndice].VisibleConTipo(ATipo);
      MostrarCampo(FControles[iIndice], bVisible);
      if bVisible then
        ColocarCampo(FControles[iIndice], ATop);
    end;
  end;
end;

procedure TCamposAdicionalesDocumentoVcl.MostrarCampo(
  const AControles: TControlesCampoAdicional; AVisible: Boolean);
begin
  if Assigned(AControles.Etiqueta) then
    AControles.Etiqueta.Visible := AVisible;
  AControles.Editor.Visible := AVisible;
  if Assigned(AControles.BotonBuscar) then
    AControles.BotonBuscar.Visible := AVisible;
  if Assigned(AControles.Nombre) then
    AControles.Nombre.Visible := AVisible;
end;

procedure TCamposAdicionalesDocumentoVcl.ColocarCampo(
  const AControles: TControlesCampoAdicional; var ATop: Integer);
begin
  if Assigned(AControles.Etiqueta) then
  begin
    AControles.Etiqueta.Top := ATop + FGeometria.DesfaseEtiqueta;
    // Una etiqueta larga ocupa su propia línea para que el editor
    // no tape su texto, también con fuentes o escala mayores.
    if AControles.Etiqueta.Width >
       FGeometria.IzquierdaEditor - FGeometria.IzquierdaEtiqueta -
       FGeometria.DesfaseEtiqueta * 2 then
    begin
      AControles.Etiqueta.Top := ATop;
      Inc(ATop, AControles.Etiqueta.Height +
        FGeometria.DesfaseEtiqueta * 2);
    end;
  end;
  AControles.Editor.Top := ATop;
  if Assigned(AControles.BotonBuscar) then
  begin
    AControles.BotonBuscar.SetBounds(
      FGeometria.IzquierdaEditor + FGeometria.AnchoEditor -
      FGeometria.AltoFila, ATop, FGeometria.AltoFila,
      AControles.Editor.Height);
    AControles.Editor.Width := FGeometria.AnchoEditor -
      FGeometria.AltoFila - FGeometria.DesfaseEtiqueta;
  end;
  if Assigned(AControles.Nombre) then
  begin
    AControles.Editor.Width := FGeometria.AnchoCodigo;
    AControles.Nombre.Top := ATop + FGeometria.DesfaseEtiqueta;
    AControles.Nombre.Left := FGeometria.IzquierdaEditor +
      FGeometria.AnchoCodigo + FGeometria.DesfaseEtiqueta * 2;
    AControles.Nombre.Width := FGeometria.AnchoEditor -
      FGeometria.AnchoCodigo - FGeometria.DesfaseEtiqueta * 2;
  end;
  Inc(ATop, FGeometria.AltoFila);
end;

procedure TCamposAdicionalesDocumentoVcl.Habilitar(AHabilitado: Boolean);
var
  oControles: TControlesCampoAdicional;
begin
  for oControles in FControles do
  begin
    oControles.Editor.Enabled := AHabilitado;
    if Assigned(oControles.BotonBuscar) then
      oControles.BotonBuscar.Enabled := AHabilitado;
  end;
end;

function TCamposAdicionalesDocumentoVcl.IndiceDe(ASender: TObject): Integer;
var
  iIndice: Integer;
begin
  Result := -1;
  for iIndice := 0 to High(FControles) do
  begin
    if FControles[iIndice].Editor = ASender then
      Result := iIndice;
  end;
end;

procedure TCamposAdicionalesDocumentoVcl.LeerValor(AIndice: Integer);
var
  oEditor: TWinControl;
  oLista: TcxComboBox;
begin
  oEditor := FControles[AIndice].Editor;
  case FCampos[AIndice].Clase of
    ccaTexto:
      FCampos[AIndice].Valor := Trim(TcxTextEdit(oEditor).Text);
    ccaLista:
    begin
      oLista := TcxComboBox(oEditor);
      FCampos[AIndice].Valor := '';
      if (oLista.ItemIndex >= 0) and
         (oLista.ItemIndex < Length(FControles[AIndice].Codigos)) then
        FCampos[AIndice].Valor :=
          FControles[AIndice].Codigos[oLista.ItemIndex];
    end;
    ccaCasilla:
    begin
      FCampos[AIndice].Valor := 'N';
      if TcxCheckBox(oEditor).Checked then
        FCampos[AIndice].Valor := 'S';
    end;
    ccaBusqueda:
      FCampos[AIndice].Valor := Trim(TcxButtonEdit(oEditor).Text);
  end;
end;

// Código tecleado a mano: se busca su nombre; si no existe se vacía.
procedure TCamposAdicionalesDocumentoVcl.ResolverBusqueda(AIndice: Integer);
var
  sDescripcion: string;
begin
  sDescripcion := '';
  if (FCampos[AIndice].Valor <> '') and
     Assigned(FCampos[AIndice].Resolver) and
     (not FCampos[AIndice].Resolver(FCampos[AIndice].Valor,
       sDescripcion)) then
    sDescripcion := '';
  FCampos[AIndice].Descripcion := sDescripcion;
  FControles[AIndice].Nombre.Caption := sDescripcion;
end;

procedure TCamposAdicionalesDocumentoVcl.EditorCambiado(Sender: TObject);
var
  iIndice: Integer;
begin
  iIndice := IndiceDe(Sender);
  if iIndice >= 0 then
  begin
    LeerValor(iIndice);
    if FCampos[iIndice].Clase = ccaBusqueda then
      ResolverBusqueda(iIndice);
    if Assigned(FAlCambiar) then
      FAlCambiar(Self);
  end;
end;

procedure TCamposAdicionalesDocumentoVcl.BuscarListaClick(Sender: TObject);
var
  iCampo, iCodigo: Integer;
  sCodigo, sDescripcion: string;
  oLista: TcxComboBox;
begin
  iCampo := TComponent(Sender).Tag;
  sCodigo := FCampos[iCampo].Valor;
  sDescripcion := FCampos[iCampo].Descripcion;
  if FCampos[iCampo].Buscar(sCodigo, sDescripcion) then
  begin
    oLista := TcxComboBox(FControles[iCampo].Editor);
    for iCodigo := 0 to High(FControles[iCampo].Codigos) do
    begin
      if FControles[iCampo].Codigos[iCodigo] = sCodigo then
        oLista.ItemIndex := iCodigo;
    end;
  end;
end;

procedure TCamposAdicionalesDocumentoVcl.BotonBusquedaClick(
  Sender: TObject; AButtonIndex: Integer);
var
  iIndice: Integer;
  oAccion: TBuscarCampoAdicional;
  sCodigo, sDescripcion: string;
begin
  iIndice := IndiceDe(Sender);
  if iIndice >= 0 then
  begin
    oAccion := FCampos[iIndice].Buscar;
    if AButtonIndex = 1 then
      oAccion := FCampos[iIndice].Alta;
    sCodigo := FCampos[iIndice].Valor;
    sDescripcion := FCampos[iIndice].Descripcion;
    if Assigned(oAccion) and oAccion(sCodigo, sDescripcion) then
    begin
      TcxButtonEdit(FControles[iIndice].Editor).Text := sCodigo;
      FCampos[iIndice].Valor := sCodigo;
      FCampos[iIndice].Descripcion := sDescripcion;
      FControles[iIndice].Nombre.Caption := sDescripcion;
      if Assigned(FAlCambiar) then
        FAlCambiar(Self);
    end;
  end;
end;

function TCamposAdicionalesDocumentoVcl.BuscarEnfocado: Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  for iIndice := 0 to High(FControles) do
  begin
    if (FCampos[iIndice].Clase = ccaBusqueda) and
       FControles[iIndice].Editor.Focused then
    begin
      BotonBusquedaClick(FControles[iIndice].Editor, 0);
      Result := True;
    end
    else if Assigned(FControles[iIndice].BotonBuscar) and
            FControles[iIndice].Editor.Focused then
    begin
      BuscarListaClick(FControles[iIndice].BotonBuscar);
      Result := True;
    end;
  end;
end;

function TCamposAdicionalesDocumentoVcl.Valores:
  TCamposAdicionalesOpcionesDocumento;
var
  iIndice: Integer;
begin
  for iIndice := 0 to High(FCampos) do
  begin
    if FCampos[iIndice].Clase <> ccaBusqueda then
      LeerValor(iIndice);
  end;
  Result := Copy(FCampos);
end;

function TCamposAdicionalesDocumentoVcl.Editor(
  AIndice: Integer): TWinControl;
begin
  Result := FControles[AIndice].Editor;
end;

end.

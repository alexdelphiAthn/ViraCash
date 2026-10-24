unit inLibComboPais;

interface

uses
  cxDBLookupComboBox;

// Presenta códigos alfa-2 antiguos sin cambiarlos en el dataset enlazado.
// El desplegable conserva exclusivamente claves numéricas para seleccionar.
procedure ConfigurarComboPaisNumerico(ACombo: TcxDBLookupComboBox);

implementation

uses
  System.SysUtils,
  System.Variants,
  Data.DB,
  cxEdit;

type
  TPropiedadesComboPais = class(TcxLookupComboBoxProperties)
  protected
    function GetDisplayLookupText(const AClave: TcxEditValue): string;
      override;
  end;

  TRepositorioComboPais = class(TcxEditRepositoryItem)
  protected
    class function GetEditPropertiesClass: TcxCustomEditPropertiesClass;
      override;
  end;

function TPropiedadesComboPais.GetDisplayLookupText(
  const AClave: TcxEditValue): string;
var
  Datos: TDataSet;
  Codigo: string;
  Nombre: Variant;
begin
  Result := inherited GetDisplayLookupText(AClave);
  Codigo := UpperCase(Trim(VarToStr(AClave)));
  if (Result = '') and (Length(Codigo) = 2) and Assigned(ListSource) then
  begin
    Datos := ListSource.DataSet;
    if Assigned(Datos) and Datos.Active and
      Assigned(Datos.FindField('COD_ALPHA2_PAI')) then
    begin
      Nombre := Datos.Lookup('COD_ALPHA2_PAI', Codigo, 'NOMBRE');
      Result := VarToStr(Nombre);
    end;
  end;
end;

class function TRepositorioComboPais.GetEditPropertiesClass:
  TcxCustomEditPropertiesClass;
begin
  Result := TPropiedadesComboPais;
end;

procedure ConfigurarComboPaisNumerico(ACombo: TcxDBLookupComboBox);
var
  Repositorio: TRepositorioComboPais;
begin
  if Assigned(ACombo) then
  begin
    if ACombo.RepositoryItem is TRepositorioComboPais then
      Repositorio := TRepositorioComboPais(ACombo.RepositoryItem)
    else
      Repositorio := TRepositorioComboPais.Create(ACombo);
    Repositorio.Properties.Assign(ACombo.Properties);
    ACombo.RepositoryItem := Repositorio;
  end;
end;

end.

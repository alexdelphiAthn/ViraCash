{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInformesGuiasCache                                       }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       24/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cache en memoria de fza_informes_guias indexada por INFORME_INFGUI.       }
{    Se precarga al login (igual que PrecargarPerfilesUsuario) para que        }
{    AbrirGuiasRuntime en los TfrmPrint no tenga que volver a consultar la     }
{    BBDD en cada click de Imprimir / PDF / Excel / Vista Preliminar /         }
{    Editar. La tabla es pequeña (decenas de filas como mucho), asi que la     }
{    carga completa cuesta lo mismo que una consulta puntual y elimina los     }
{    8 s recurrentes que se veian en log por la primera consulta caliente.    }
{******************************************************************************}
unit inLibInformesGuiasCache;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TInformeGuiaItem = record
    Codigo:        string;
    Informe:       string;
    Formato:       string;
    DatasetMaster: string;
    Tipo:          string;
    Tabla:         string;
    SqlStr:        string;
    MasterFields:  string;
    DetailFields:      string;
    Orden:             Integer;
    ColumnasVisibles:  string;
  end;

  TListaGuias      = TList<TInformeGuiaItem>;
  TGuiasPorInforme = TObjectDictionary<string, TListaGuias>;

  ILectorInformesGuias = interface
    ['{42F49D2B-2A43-4B31-8577-1BB76243586F}']
    function Cargar: TArray<TInformeGuiaItem>;
  end;

  IInformesGuiasCache = interface
    ['{6315909C-BE4B-473A-B544-5B741D3B3135}']
    function GetCargada: Boolean;
    procedure Precargar(
      const ALector: ILectorInformesGuias = nil);
    procedure Invalidar;
    function Obtener(
      const AInforme,
      AFormato: string): TArray<TInformeGuiaItem>;
    property Cargada: Boolean read GetCargada;
  end;

  IProveedorInformesGuiasCache = interface
    ['{66B8ACD5-A749-4F89-BFE5-900284F848A7}']
    function GetInformesGuiasCache: IInformesGuiasCache;
    property InformesGuiasCache: IInformesGuiasCache
      read GetInformesGuiasCache;
  end;

  TInformesGuiasCache = class(
    TInterfacedObject,
    IInformesGuiasCache
  )
  private
    FPorInforme: TGuiasPorInforme;
    FLector: ILectorInformesGuias;
    FCargada:    Boolean;
    function GetCargada: Boolean;
  public
    constructor Create(const ALector: ILectorInformesGuias);
    destructor  Destroy; override;
    procedure Precargar(
      const ALector: ILectorInformesGuias = nil);
    procedure   Invalidar;
    // Devuelve las guias activas que aplican al (Informe, Formato) dado,
    // replicando el filtro del SELECT original: FORMATO_INFGUI = '' (guia
    // global) o FORMATO_INFGUI = aFormato (atada al .frx editado). El
    // resultado viene ordenado por ORDEN_INFGUI, CODIGO_INFGUI.
    function    Obtener(const aInforme,
                        aFormato: string): TArray<TInformeGuiaItem>;
    property    Cargada: Boolean read GetCargada;
  end;

implementation

constructor TInformesGuiasCache.Create(
  const ALector: ILectorInformesGuias);
begin
  inherited Create;
  FLector := ALector;
  FPorInforme := TGuiasPorInforme.Create([doOwnsValues]);
  FCargada    := False;
end;

destructor TInformesGuiasCache.Destroy;
begin
  FreeAndNil(FPorInforme);
  inherited;
end;

function TInformesGuiasCache.GetCargada: Boolean;
begin
  Result := FCargada;
end;

procedure TInformesGuiasCache.Invalidar;
begin
  FPorInforme.Clear;
  FCargada := False;
end;

procedure TInformesGuiasCache.Precargar(
  const ALector: ILectorInformesGuias);
var
  oLector: ILectorInformesGuias;
  arrGuias: TArray<TInformeGuiaItem>;
  item:        TInformeGuiaItem;
  sInformeKey: string;
  lst:         TListaGuias;
begin
  FPorInforme.Clear;
  FCargada := False;
  oLector := ALector;
  if not Assigned(oLector) then
  begin
    oLector := FLector;
  end;
  if Assigned(oLector) then
  begin
    try
      arrGuias := oLector.Cargar;
      for item in arrGuias do
      begin
        sInformeKey := LowerCase(item.Informe);
        if not FPorInforme.TryGetValue(sInformeKey, lst) then
        begin
          lst := TListaGuias.Create;
          FPorInforme.Add(sInformeKey, lst);
        end;
        lst.Add(item);
      end;
      FCargada := True;
    except
      // La impresion puede continuar sin enriquecimiento de guias.
      FPorInforme.Clear;
    end;
  end;
end;

function TInformesGuiasCache.Obtener(const aInforme,
                                     aFormato: string):
                                     TArray<TInformeGuiaItem>;
var
  lst:  TListaGuias;
  i, n: Integer;
  it:   TInformeGuiaItem;
begin
  SetLength(Result, 0);
  if FCargada and
     FPorInforme.TryGetValue(LowerCase(aInforme), lst) then
  begin
    SetLength(Result, lst.Count);
    n := 0;
    for i := 0 to lst.Count - 1 do
    begin
      it := lst[i];
      if (it.Formato = '') or SameText(it.Formato, aFormato) then
      begin
        Result[n] := it;
        Inc(n);
      end;
    end;
    SetLength(Result, n);
  end;
end;

end.

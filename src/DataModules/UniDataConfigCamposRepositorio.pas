unit UniDataConfigCamposRepositorio;

interface

uses
  Uni,
  inLibConfigCamposPersistenciaIntf;

type
  TRepositorioConfigCamposUniDAC = class(
    TInterfacedObject, IRepositorioConfigCampos)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarCampos: TResultadoConfigCampos;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections;

constructor TRepositorioConfigCamposUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioConfigCamposUniDAC.CargarCampos:
  TResultadoConfigCampos;
var
  oConsulta: TUniQuery;
  oElemento: TConfigCampoPersistido;
  oElementos: TList<TConfigCampoPersistido>;
begin
  if not Assigned(FConexion) or
     not FConexion.Connected then
  begin
    Result := TResultadoConfigCampos.Fallido(
      elcConexionNoDisponible,
      'La conexión de configuración de campos no está activa.');
  end
  else
  begin
    oElementos := TList<TConfigCampoPersistido>.Create;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        try
          oConsulta.Connection := FConexion;
          oConsulta.SQL.Text :=
            'SELECT TABLA_OBJETIVO_CC, OBJETIVO_CC, ' +
            '       TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ' +
            '       ORDEN_VISUAL_CC, VISIBLE_CC ' +
            '  FROM fza_config_campos ' +
            ' ORDER BY TABLA_OBJETIVO_CC, ORDEN_VISUAL_CC';
          oConsulta.Open;
          while not oConsulta.Eof do
          begin
            oElemento.Tabla := oConsulta.FieldByName(
              'TABLA_OBJETIVO_CC').AsString;
            oElemento.Campo := oConsulta.FieldByName(
              'OBJETIVO_CC').AsString;
            oElemento.TituloVisual := oConsulta.FieldByName(
              'TITULO_VISUAL_CC').AsString;
            oElemento.AnchoColumna := oConsulta.FieldByName(
              'ANCHO_COLUMNA_CC').AsInteger;
            oElemento.OrdenVisual := oConsulta.FieldByName(
              'ORDEN_VISUAL_CC').AsInteger;
            oElemento.Visible := SameText(
              oConsulta.FieldByName('VISIBLE_CC').AsString, 'S');
            oElementos.Add(oElemento);
            oConsulta.Next;
          end;
          Result := TResultadoConfigCampos.Correcto(
            oElementos.ToArray);
        except
          on E: Exception do
          begin
            Result := TResultadoConfigCampos.Fallido(
              elcConsultaFallida, E.Message);
          end;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    finally
      FreeAndNil(oElementos);
    end;
  end;
end;

end.

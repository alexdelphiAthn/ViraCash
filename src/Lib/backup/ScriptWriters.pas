unit ScriptWriters;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils, Core_Interfaces;

type
  TScriptWriter = class(TInterfacedObject, IScriptWriter)
  private
    FFileName: string;
    FWriter: TStreamWriter;
    FBuffer: TStringList;
  public
    constructor Create(const AFileName: string = '');
    destructor Destroy; override;

    // Implementación de IScriptWriter
    procedure AddComment(const Text: string);
    procedure AddCommand(const SQL: string);
    function GetScript: string;
  end;

implementation

constructor TScriptWriter.Create(const AFileName: string = '');
begin
  inherited Create;
  FFileName := AFileName;
  FBuffer := TStringList.Create;

  // Si nos pasan un nombre de archivo, preparamos la escritura directa a disco
  if FFileName <> '' then
  begin
    // Usamos TEncoding.UTF8 para asegurar que los acentos y caracteres
    // especiales (como la 'ñ' española) se guarden correctamente.
    FWriter := TStreamWriter.Create(FFileName, False, TEncoding.UTF8);
    FWriter.AutoFlush := True; // Fuerza a guardar en disco periódicamente
  end
  else
    FWriter := nil;
end;

destructor TScriptWriter.Destroy;
begin
  // Nos aseguramos de cerrar el archivo y liberar la memoria
  if Assigned(FWriter) then
  begin
    FWriter.Close;
    FWriter.Free;
  end;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TScriptWriter.AddComment(const Text: string);
var
  Line: string;
begin
  if Text = '' then
    Line := ''
  else if StartsText('--', Trim(Text)) or StartsText('/*', Trim(Text)) then
    Line := Text
  else
    Line := '-- ' + Text; // Formatea como comentario SQL si no lo es

  if Assigned(FWriter) then
    FWriter.WriteLine(Line)
  else
    FBuffer.Add(Line);
end;

procedure TScriptWriter.AddCommand(const SQL: string);
begin
  // Escribe la sentencia SQL (CREATE, INSERT, etc.)
  if Assigned(FWriter) then
  begin
    FWriter.WriteLine(SQL);
  end
  else
  begin
    FBuffer.Add(SQL);
  end;
end;

function TScriptWriter.GetScript: string;
begin
  if Assigned(FWriter) then
  begin
    // Si estamos escribiendo a archivo de forma secuencial,
    // devolvemos un aviso indicando dónde está físicamente.
    Result := '-- Script generado directamente en el archivo: ' + FFileName;
  end
  else
  begin
    // Si se instanció sin archivo (modo memoria), devolvemos el texto completo.
    Result := FBuffer.Text;
  end;
end;

end.

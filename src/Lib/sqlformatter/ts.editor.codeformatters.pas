{
  Copyright (C) 2013-2023 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}
unit ts.Editor.CodeFormatters;

interface

uses
  System.Classes, System.SysUtils;

type
  // 1. CAMBIO: Definimos la Interfaz con el nombre correcto "ICodeFormatter"
  ICodeFormatter = interface
    ['{3FD89A57-D3C9-4B85-8BDF-9954C6D30C52}']
    function Format(const AString: string): string;
  end;

  // Función factoría global
  function GetSQLFormatter: ICodeFormatter;

implementation

// 2. Usamos la unidad SQL SOLO aquí en implementation para evitar referencia circular
uses
  ts.Editor.CodeFormatters.SQL;

function GetSQLFormatter: ICodeFormatter;
begin
  // 3. Creamos la instancia de la CLASE concreta que está en la otra unidad
  Result := ts.Editor.CodeFormatters.SQL.TSQLFormatter.Create;
end;

end.

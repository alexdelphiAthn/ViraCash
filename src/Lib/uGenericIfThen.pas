unit uGenericIfThen;

interface

uses
  System.SysUtils;

type
  TGenUtils = record
  public
    /// <summary>
    /// Devuelve ATrue si la condición es verdadera, o AFalse si es falsa.
    /// </summary>
    class function IfThen<T>(const ACondition: Boolean;
                             const ATrue,
                             AFalse: T): T; overload; static;

    /// <summary>
    /// Versión con evaluación perezosa (Lazy Evaluation).
    /// </summary>
    class function IfThen<T>(const ACondition: Boolean;
                             const ATrueFunc,
                             AFalseFunc: TFunc<T>): T; overload; static;
  end;

implementation

class function TGenUtils.IfThen<T>(const ACondition: Boolean;
                                   const ATrue,
                                   AFalse: T): T;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

class function TGenUtils.IfThen<T>(const ACondition: Boolean;
                                   const ATrueFunc,
                                   AFalseFunc: TFunc<T>): T;
begin
  if ACondition then
    Result := ATrueFunc()
  else
    Result := AFalseFunc();
end;

end.

unit Orion.Notations.Processors.Factory;

interface

uses
  Orion.Notations.Interfaces;

type
  TOrionNotationsProcessorsFactory = class(TInterfacedObject, iOrionNotationProcessorsFactory)
  private

  public
    class function New : iOrionNotationProcessorsFactory;
    function Build(aProcessorDataBase : TProcessorDataBase) : iOrionNotationProcessor;
  end;

implementation

uses
  Orion.Notations.Processors.FireDAC.FireBird, Orion.Notations.Processors.FireDAC.SQLite;

{ TOrionNotationsProcessorsFactory }

function TOrionNotationsProcessorsFactory.Build(aProcessorDataBase: TProcessorDataBase): iOrionNotationProcessor;
begin
  case aProcessorDataBase of
    TProcessorDataBase.Firebird : Result := TOrionNotationsProcessorFireDACFirebird.New;
    TProcessorDataBase.SQLite   : Result := TOrionNotationsProcessorFireDACSQLite.New;

  end;
end;

class function TOrionNotationsProcessorsFactory.New: iOrionNotationProcessorsFactory;
begin
  Result := Self.Create;
end;

end.

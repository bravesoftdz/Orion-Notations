unit Orion.Notations.Statements.Insert;

interface

uses
  System.Classes,
  Orion.Notations.Interfaces;

type
  TOrionNotationStatementValueInsert = class(TInterfacedObject, iNotationStatementValue)
  private
    FValue : string;
    FPairs : TStringList;
    FWhere : TStringList;
    [weak]
    FNotation : iOrionNotation;
  public
    constructor Create(aNotation : iOrionNotation);
    destructor Destroy; override;

    class function New(aNotation : iOrionNotation) : iNotationStatementValue;

    procedure AddFields(aValue : TStringList);
    procedure UpdateField(aName, aValue : string);
    procedure AddWhere(aValue : TStringList);
    procedure UpdateWhere(aName, aValue : string);
    procedure AddJoin(aValue : string);
    function GetPairValue(aPairName : string) : string;
    procedure Value(aValue : string); overload;
    function Value : string; overload;
    function Notation : iOrionNotation;
    procedure AddObjectListPropertyName(aValue : string);
    function GetObjectListPropertyName : TStringList;
  end;

implementation

{ TOrionNotationStatementValueInsert }

procedure TOrionNotationStatementValueInsert.AddFields(aValue: TStringList);
begin
  FPairs := aValue;
end;

procedure TOrionNotationStatementValueInsert.AddJoin(aValue: string);
begin

end;

constructor TOrionNotationStatementValueInsert.Create(aNotation: iOrionNotation);
begin
  FNotation := aNotation;
end;

destructor TOrionNotationStatementValueInsert.Destroy;
begin
  if Assigned(FPairs) then
    FPairs.DisposeOf;

  if Assigned(FWhere) then
    FWhere.DisposeOf;
  inherited;
end;

function TOrionNotationStatementValueInsert.GetPairValue(aPairName: string): string;
begin
  Result := FPairs.Values[aPairName];
end;

class function TOrionNotationStatementValueInsert.New(aNotation : iOrionNotation) : iNotationStatementValue;
begin
  Result := Self.Create(aNotation);
end;

function TOrionNotationStatementValueInsert.Notation: iOrionNotation;
begin
  Result := FNotation;
end;

function TOrionNotationStatementValueInsert.GetObjectListPropertyName : TStringList;
begin
  Result := nil;
end;

procedure TOrionNotationStatementValueInsert.AddObjectListPropertyName(aValue: string);
begin

end;

procedure TOrionNotationStatementValueInsert.AddWhere(aValue: TStringList);
begin
  FWhere := aValue;
end;

procedure TOrionNotationStatementValueInsert.UpdateField(aName, aValue: string);
begin
  FPairs.Values[aName] := aValue;
end;

procedure TOrionNotationStatementValueInsert.UpdateWhere(aName, aValue: string);
begin
  FWhere.Values[aName] := aValue;
end;

function TOrionNotationStatementValueInsert.Value: string;
begin
  var lFieldNames := '';
  var lFieldValues := '';
  for var I := 0 to Pred(FPairs.Count) do
  begin
    lFieldNames := lFieldNames + FPairs.Names[I];
    lFieldValues := lFieldValues + FPairs.ValueFromIndex[I];
    if I < Pred(FPairs.Count) then
    begin
      lFieldNames := lFieldNames + ', ';
      lFieldValues := lFieldValues + ', ';
    end;
  end;
  Result := 'insert into ' + FNotation.TableName + ' (' + lFieldNames + ') values (' + lFieldValues + ') ' + FValue;
end;

procedure TOrionNotationStatementValueInsert.Value(aValue: string);
begin
  FValue := aValue;
end;

end.

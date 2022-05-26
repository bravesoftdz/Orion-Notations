unit Orion.Notations.Statements.Delete;

interface

uses
  System.Classes,
  Orion.Notations.Interfaces;

type
  TOrionNotationStatementValueDelete = class(TInterfacedObject, iNotationStatementValue)
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

{ TOrionNotationStatementValueDelete }

procedure TOrionNotationStatementValueDelete.AddFields(aValue: TStringList);
begin
  FPairs := aValue;
end;

procedure TOrionNotationStatementValueDelete.AddJoin(aValue: string);
begin

end;

constructor TOrionNotationStatementValueDelete.Create(aNotation: iOrionNotation);
begin
  FNotation := aNotation;
end;

destructor TOrionNotationStatementValueDelete.Destroy;
begin
  if Assigned(FPairs) then
    FPairs.DisposeOf;

  if Assigned(FWhere) then
    FWhere.DisposeOf;
  inherited;
end;

function TOrionNotationStatementValueDelete.GetPairValue(aPairName: string): string;
begin
  Result := FPairs.Values[aPairname];
end;

class function TOrionNotationStatementValueDelete.New(aNotation : iOrionNotation) : iNotationStatementValue;
begin
  Result := Self.Create(aNotation);
end;

function TOrionNotationStatementValueDelete.Notation: iOrionNotation;
begin
  Result := FNotation;
end;

function TOrionNotationStatementValueDelete.GetObjectListPropertyName : TStringList;
begin
  Result := nil;
end;

procedure TOrionNotationStatementValueDelete.AddObjectListPropertyName(aValue: string);
begin

end;

procedure TOrionNotationStatementValueDelete.AddWhere(aValue: TStringList);
begin
  FWhere := aValue;
end;

procedure TOrionNotationStatementValueDelete.UpdateField(aName, aValue: string);
begin
  FPairs.Values[aName] := aValue;
end;

procedure TOrionNotationStatementValueDelete.UpdateWhere(aName, aValue: string);
begin
  FWhere.Values[aName] := aValue;
end;

function TOrionNotationStatementValueDelete.Value: string;
begin
  var lFields := '';
  for var I := 0 to Pred(FPairs.Count) do
  begin
    if I = 0 then
      lFields := FPairs.Names[i] + ' = ' + FPairs.ValueFromIndex[I]
    else
      lFields := lFields + ' and ' + FPairs.Names[i] + ' = ' + FPairs.ValueFromIndex[I];
  end;
  Result := 'delete from ' + FNotation.TableName + ' where ' + lFields;
end;

procedure TOrionNotationStatementValueDelete.Value(aValue: string);
begin
  FValue := aValue;
end;

end.

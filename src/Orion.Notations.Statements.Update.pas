unit Orion.Notations.Statements.Update;

interface

uses
  System.Classes,
  Orion.Notations.Interfaces;

type
  TOrionNotationStatementValueUpdate = class(TInterfacedObject, iNotationStatementValue)
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
    procedure AddWhere(aValue : TStringList; aIsPair : Boolean = True);
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

{ TOrionNotationStatementValueUpdate }

procedure TOrionNotationStatementValueUpdate.AddFields(aValue: TStringList);
begin
  FPairs := aValue;
end;

procedure TOrionNotationStatementValueUpdate.AddJoin(aValue: string);
begin

end;

constructor TOrionNotationStatementValueUpdate.Create(aNotation: iOrionNotation);
begin
  FNotation := aNotation;
end;

destructor TOrionNotationStatementValueUpdate.Destroy;
begin
  if Assigned(FPairs) then
    FPairs.DisposeOf;

  if Assigned(FWhere) then
    FWhere.DisposeOf;
  inherited;
end;

function TOrionNotationStatementValueUpdate.GetPairValue(aPairName: string): string;
begin
  Result := FPairs.Values[aPairname];
end;

class function TOrionNotationStatementValueUpdate.New(aNotation : iOrionNotation) : iNotationStatementValue;
begin
  Result := Self.Create(aNotation);
end;

function TOrionNotationStatementValueUpdate.Notation: iOrionNotation;
begin
  Result := FNotation;
end;

function TOrionNotationStatementValueUpdate.GetObjectListPropertyName : TStringList;
begin
  Result := nil;
end;

procedure TOrionNotationStatementValueUpdate.AddObjectListPropertyName(aValue: string);
begin

end;

procedure TOrionNotationStatementValueUpdate.AddWhere(aValue : TStringList; aIsPair : Boolean = True);
begin
  FWhere := aValue;
end;

procedure TOrionNotationStatementValueUpdate.UpdateField(aName, aValue: string);
begin
  FPairs.Values[aName] := aValue;
end;

procedure TOrionNotationStatementValueUpdate.UpdateWhere(aName, aValue: string);
begin
  FWhere.Values[aName] := aValue;
end;

function TOrionNotationStatementValueUpdate.Value: string;
begin
  var lFields := '';
  for var I := 0 to Pred(FPairs.Count) do
  begin
    if I = Pred(FPairs.Count) then
      lFields := lFields + FPairs[I]
    else
      lFields := lFields + FPairs[I] + ', ';
  end;
  Result := 'update ' + FNotation.TableName + ' set ' + lFields + ' where ' + FWhere.Text;
end;

procedure TOrionNotationStatementValueUpdate.Value(aValue: string);
begin
  FValue := aValue;
end;

end.

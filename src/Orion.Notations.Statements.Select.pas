unit Orion.Notations.Statements.Select;

interface

uses
  System.Classes,
  System.SysUtils,
  Orion.Notations.Interfaces;

type
  TOrionNotationStatementValueSelect = class(TInterfacedObject, iNotationStatementValue)
  private
    FValue : string;
    FPairs : TStringList;
    FWhere : TStringList;
    FIsPair : Boolean;
    FJoins : TStringList;
    [weak]
    FNotation : iOrionNotation;
    FObjectListPropertyNames : TStringList;
  public
    constructor Create(aNotation : iOrionNotation);
    destructor Destroy; override;

    class function New(aNotation : iOrionNotation) : iNotationStatementValue;

    procedure AddFields(aValue : TStringList);
    procedure UpdateField(aName, aValue : string);
    procedure AddWhere(aValue : TStringList; aIsPair : boolean = True);
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

{ TOrionNotationStatementValueSelect }

procedure TOrionNotationStatementValueSelect.AddFields(aValue: TStringList);
begin
  FPairs := aValue;
end;

procedure TOrionNotationStatementValueSelect.AddJoin(aValue: string);
begin
  FJoins.Add(aValue);
end;

constructor TOrionNotationStatementValueSelect.Create(aNotation: iOrionNotation);
begin
  FNotation := aNotation;
  FJoins := TStringList.Create;
  FObjectListPropertyNames := TStringList.Create;
end;

destructor TOrionNotationStatementValueSelect.Destroy;
begin
  if Assigned(FPairs) then
    FPairs.DisposeOf;

  if Assigned(FWhere) then
    FWhere.DisposeOf;

  FJoins.DisposeOf;
  FObjectListPropertyNames.DisposeOf;
  inherited;
end;

function TOrionNotationStatementValueSelect.GetPairValue(aPairName: string): string;
begin
  Result := FPairs.Values[aPairName];
end;

class function TOrionNotationStatementValueSelect.New(aNotation : iOrionNotation) : iNotationStatementValue;
begin
  Result := Self.Create(aNotation);
end;

function TOrionNotationStatementValueSelect.Notation: iOrionNotation;
begin
  Result := FNotation;
end;

function TOrionNotationStatementValueSelect.GetObjectListPropertyName : TStringList;
begin
  Result := FObjectListPropertyNames;
end;

procedure TOrionNotationStatementValueSelect.AddObjectListPropertyName(aValue: string);
begin
  FObjectListPropertyNames.Add(aValue);
end;

procedure TOrionNotationStatementValueSelect.AddWhere(aValue : TStringList; aIsPair : boolean = True);
begin
  FWhere := aValue;
  FIsPair := aIsPair;
end;

procedure TOrionNotationStatementValueSelect.UpdateField(aName, aValue: string);
begin
  FPairs.Values[aName] := aValue;
end;

procedure TOrionNotationStatementValueSelect.UpdateWhere(aName, aValue: string);
begin
  FWhere.Values[aName] := aValue;
end;

function TOrionNotationStatementValueSelect.Value: string;
begin
  var lFields := '';
  var lJoins := '';
  for var I := 0 to Pred(FPairs.Count) do
  begin
    if I = Pred(FPairs.Count) then
      lFields := lFields + FPairs[I].Split(['='])[0]
    else
      lFields := lFields + FPairs[I].Split(['='])[0] + ', ';
  end;

  for var lJoin in FJoins do
  begin
    lJoins := lJoins + ' ' + lJoin;
  end;
  Result := 'select ' + lFields + ' from ' + FNotation.TableName + ' ' + lJoins + ' where ' + FWhere.Text;
end;

procedure TOrionNotationStatementValueSelect.Value(aValue: string);
begin
  FValue := aValue;
end;

end.

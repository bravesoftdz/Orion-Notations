unit Orion.Notations;

interface

uses
  Orion.Notations.Interfaces,
  Orion.Notations.Types,
  Data.DB,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  System.Variants;

type

  TOrionNotation = class(TInterfacedObject, iOrionNotation)
  private
    FDataset : TDataset;
    FObject : TObject;
    FObjectType : TClass;
    FTableName : string;
    FJoins : TList<string>;
    FNotations : TList<TNotationData>;
    FBuildStatement : TList<iNotationStatementValue>;
    FStatementItens : TList<iNotationStatementValue>;
    FForeingKey : string;
    [weak]
    FOwner : iOrionNotation;
    procedure SetStatementItensInResult(aResult : TList<iNotationStatementValue>);
    procedure AddPair(aProperty : TRttiProperty; aObject : TObject; aNotation : TNotationData; aIsDateField : boolean; aPairs : TStringList; aSQLType : TStatementType);

    function BuildSQLInsert(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TList<iNotationStatementValue>;
    function BuildSQLUpdate(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TList<iNotationStatementValue>;
    function BuildSqLSelect(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TList<iNotationStatementValue>;
    function BuildSqLDelete(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TList<iNotationStatementValue>;
    function GetPKValue(aObject : TObject; aNotations : TList<TNotationData>) : integer;
    procedure BuildSQLInsertList(aObject : TObject; aNotationItem : TNotationData);
    procedure BuildSQLUpdateList(aObject : TObject; aNotationItem : TNotationData);
    procedure BuildSQLSelectList(aObject : TObject; aNotationItem : TNotationData);
    procedure BuildSQLDeleteList(aObject : TObject; aNotationItem : TNotationData);
  public
    constructor Create(aOwner : iOrionNotation = nil);
    destructor Destroy; override;
    class function New(aOwner : iOrionNotation = nil) : iOrionNotation;

    function SetObject(aObject : TObject) : iOrionNotation;
    function GetObject : TObject;
    function ObjectType(aObjectType : TClass) : iOrionNotation; overload;
    function ObjectType : TClass; overload;
    function Owner : iOrionNotation; overload;
    function Owner(aValue : iOrionNotation) : iOrionNotation; overload;
    function SetDataSet(aDataset : TDataset) : iOrionNotation;
    function TableName(aValue : string) : iOrionNotation; overload;
    function TableName : string; overload;
    function ForeignKey(aValue : string) : iOrionNotation; overload;
    function ForeignKey : string; overload;
    function AddNotation(aPropertyName, aTableFieldName : string; aConstraint : TNotacaoConstraints = []) : iOrionNotation; overload;
    function AddNotation(aPropertyName : string; aNotation : iOrionNotation) : iOrionNotation; overload;
    function BuildStatement(aSQLType : TStatementType; aIsOwner : Boolean = True) : TList<iNotationStatementValue>;
    function AddJoin(aValue : string) : iOrionNotation;
    function GetPKTableName : string;
    function GetTableFieldNameByPropertyName(aPropertyName : string) : string;
    function GetNotationsList : TList<TNotationData>;
  end;

implementation

uses
  System.SysUtils,
  Orion.Notations.Statements.Insert,
  Orion.Notations.Statements.Update,
  Orion.Notations.Statements.Select,
  Orion.Notations.Statements.Delete;

{ TOrionNotation }

function TOrionNotation.AddJoin(aValue: string): iOrionNotation;
begin
  Result := Self;
  FJoins.Add(aValue);
end;

function TOrionNotation.AddNotation(aPropertyName, aTableFieldName: string; aConstraint: TNotacaoConstraints): iOrionNotation;
begin
  Result := Self;
  var lNotacaoItem : TNotationData;
  lNotacaoItem.PropertyName     := aPropertyName;
  lNotacaoItem.DataSetFieldName := aTableFieldName;
  lNotacaoItem.Constraints      := aConstraint;
  FNotations.Add(lNotacaoItem);
end;

function TOrionNotation.AddNotation(aPropertyName: string; aNotation: iOrionNotation): iOrionNotation;
begin
  Result := Self;
  aNotation.Owner(Self);
  var lNotacaoItem : TNotationData;
  lNotacaoItem.PropertyName := aPropertyName;
  lNotacaoItem.Notacao      := aNotation;
  FNotations.Add(lNotacaoItem);
end;

procedure TOrionNotation.AddPair(aProperty: TRttiProperty; aObject : TObject; aNotation : TNotationData; aIsDateField : boolean; aPairs: TStringList; aSQLType : TStatementType);
begin
  case aProperty.PropertyType.TypeKind of

    tkInteger     : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsInteger.ToString);
    tkInt64       : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsInt64.ToString);
    tkWChar       : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkLString     : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkWString     : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkUString     : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkString      : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkChar        : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkVariant     : aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(aObject).AsString.QuotedString);
    tkFloat       :
    begin
      if aIsDateField then
      begin
        var lData := FormatDateTime('dd.mm.yyyy', FloatToDateTime(aProperty.GetValue(Pointer(FObject)).AsExtended)).QuotedString;
        aPairs.AddPair(aNotation.DataSetFieldName, lData);
      end
      else
       aPairs.AddPair(aNotation.DataSetFieldName, aProperty.GetValue(Pointer(FObject)).AsExtended.ToString.Replace(',', '.', [rfReplaceAll]));
    end;
    tkClass       :
    begin
      if aProperty.GetValue(Pointer(FObject)).AsObject.ClassName.Contains('TObjectList<') then
      begin
        if aSQLType = TStatementType.Insert then
          BuildSQLInsertList(aProperty.GetValue(aObject).AsObject, aNotation)
        else if aSQLType = TStatementType.Update then
          BuildSQLUpdateList(aProperty.GetValue(aObject).AsObject, aNotation);
      end;
    end;
    tkEnumeration : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkEnumeration não implementado.');
    tkMethod      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkMethod não implementado.');
    tkSet         : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkSet não implementado.');
    tkArray       : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkArray não implementado.');
    tkRecord      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkRecord não implementado.');
    tkInterface   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkInterface não implementado.');
    tkUnknown     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkUnknown não implementado.');
    tkDynArray    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkDynArray não implementado.');
    tkClassRef    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkClassRef não implementado.');
    tkPointer     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkPointer não implementado.');
    tkProcedure   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkProcedure não implementado.');
    tkMRecord     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkRecord não implementado.');
  end;
end;

function TOrionNotation.BuildSqLDelete(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True): TList<iNotationStatementValue>;
begin
  var lType := TRttiContext.Create.GetType(FObject.ClassInfo);
  var lPairs := TStringList.Create;
  try
    for var lNotation in FNotations do
    begin
      for var lConstraint in lNotation.Constraints do
      begin
        if lConstraint = TNotationConstraint.PK then
        begin
          if not aIsOwner then
            lPairs.AddPair(FOwner.ForeignKey, '')
          else
            lPairs.AddPair(lNotation.DataSetFieldName, lType.GetProperty(lNotation.PropertyName).GetValue(FObject).AsInteger.ToString);
          Continue;
        end;
      end;

      if Assigned(lNotation.Notacao) then
      begin
        BuildSQLDeleteList(lType.GetProperty(lNotation.PropertyName).GetValue(FObject).AsObject, lNotation);
      end;
    end;

    var lStatement := TOrionNotationStatementValueDelete.New(Self);
    lStatement.AddFields(lPairs);

    FBuildStatement.Add(lStatement);
    SetStatementItensInResult(FBuildStatement);
    Result := FBuildStatement;

  finally
    lType.DisposeOf;
  end;
end;

procedure TOrionNotation.BuildSQLDeleteList(aObject: TObject; aNotationItem: TNotationData);
begin
  var lObject := aNotationItem.Notacao.ObjectType.Create;
  try
    aNotationItem.Notacao.SetObject(lObject);
    var lStatements := aNotationItem.Notacao.BuildStatement(TStatementType.Delete, False);
    for var lStatement in lStatements do
      FStatementItens.Add(lStatement);
  finally
    lObject.DisposeOf;
  end;
end;

function TOrionNotation.BuildSQLInsert(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean): TList<iNotationStatementValue>;
begin
  var lPairs := TStringList.Create;
  var lType := TRttiContext.Create.GetType(aObject.ClassInfo);
  var lReturning := '';
  try
    FBuildStatement.Clear;
    for var lNotation in FNotations do
    begin
      var lIsAutoInc := False;
      var lIgnore := False;
      var lIsDataField := False;
      for var lConstraint in lNotation.Constraints do
      begin
        if lConstraint = TNotationConstraint.PK then
          lReturning := ' returning ' + lNotation.DataSetFieldName;

        if lConstraint = TNotationConstraint.AutoInc then
          lIsAutoInc := True;

        if lConstraint = TNotationConstraint.DateField then
          lIsDataField := True;

        if lConstraint = TNotationConstraint.IgnoreWriteSQLs then
          lIgnore := True;
      end;

      if lIsAutoInc then
        Continue;

      if lIgnore then
        Continue;

      var lProperty := lType.GetProperty(lNotation.PropertyName);
      if not Assigned(lProperty) then
        raise Exception.Create(ClassName + '.BuildStatementInsert: Property ' + lNotation.PropertyName + ' not found.');

      AddPair(lProperty, aObject, lNotation, lIsDataField, lPairs, TStatementType.Insert);
    end;

    var lStatement := TOrionNotationStatementValueInsert.New(Self);
    lStatement.AddFields(lPairs);
    if aIsOwner then
      lStatement.Value(lReturning);

    FBuildStatement.Add(lStatement);
    SetStatementItensInResult(FBuildStatement);
    Result := FBuildStatement;
  finally
    lType.DisposeOf;
  end;
end;

procedure TOrionNotation.BuildSQLInsertList(aObject: TObject; aNotationItem : TNotationData);
begin
  for var lObject in TObjectList<TObject>(aObject) do
  begin
    aNotationItem.Notacao.SetObject(lObject);
    var lStatements := aNotationItem.Notacao.BuildStatement(TStatementType.Insert, False);
    for var lStatement in lStatements do
    begin
      FStatementItens.Add(lStatement);
    end;
  end;
end;

function TOrionNotation.BuildSqLSelect(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean = True): TList<iNotationStatementValue>;
begin
  if not Assigned(FObjectType) then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: No one object type setted.');

  var lPairs := TStringList.Create;
  var lPKFieldName := '';
  var lPKValue := 0;
  var lObjectListPropertyName : string;
  var lType := TRttiContext.Create.GetType(aObject.ClassInfo);
  var lStatement := TOrionNotationStatementValueSelect.New(Self);
  try
    for var lNotation in FNotations do
    begin
      for var lConstraint in lNotation.Constraints do
      begin
        if lConstraint = TNotationConstraint.PK then
        begin
          lPKFieldName := lNotation.DataSetFieldName;
          lPKValue := lType.GetProperty(lNotation.PropertyName).GetValue(aObject).AsInteger;
        end;
      end;
      if Assigned(lNotation.Notacao) then
      begin
        var lProperty := lType.GetProperty(lNotation.PropertyName);
        BuildSQLSelectList(lProperty.GetValue(aObject).AsObject, lNotation);

        if (aIsOwner) and FForeingKey.IsEmpty then
          raise Exception.Create(Self.QualifiedClassName+'.BuildStatement: No one ForeignKey setted for link with ' + lNotation.PropertyName);

        if aIsOwner then
          lStatement.AddObjectListPropertyName(lNotation.PropertyName);

        Continue;
      end;
      lPairs.AddPair(lNotation.DataSetFieldName, '');
    end;


    lStatement.AddFields(lPairs);
    for var lJoin in FJoins do
      lStatement.AddJoin(lJoin);

    if aIsOwner then
      lStatement.Value(' where ' + lPKFieldName + ' = ' + lPKValue.ToString);

    FBuildStatement.Add(lStatement);
    SetStatementItensInResult(FBuildStatement);
    Result := FBuildStatement;
  finally
    lType.DisposeOf;
  end;
end;

function TOrionNotation.BuildSQLUpdate(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean = True): TList<iNotationStatementValue>;
begin
  var lType := TRttiContext.Create.GetType(aObject.ClassInfo);
  var lPairs := TStringList.Create;
  var lPKValue := 0;
  var lPKFieldName := '';
  try
    for var lNotation in FNotations do
    begin
      var lIgnore := False;
      var lIsDateField := False;
      for var lConstraint in lNotation.Constraints do
      begin
        if lConstraint = TNotationConstraint.PK then
        begin
          var lPropertyPK := lType.GetProperty(lNotation.PropertyName);
          if not Assigned(lPropertyPK) then
            raise Exception.Create(QualifiedClassName + '.BuildStatementUpdate: Property ' + lNotation.PropertyName + 'not found');

          lPKValue := lPropertyPK.GetValue(aObject).AsInteger;
          lPKFieldName := lNotation.DataSetFieldName;
        end;

        if lConstraint = TNotationConstraint.IgnoreWriteSQLs then
          lIgnore := True;

        if lConstraint = TNotationConstraint.DateField then
          lIsDateField := True;
      end;

      if lIgnore then
        Continue;

      var lProperty := lType.GetProperty(lNotation.PropertyName);
      if not Assigned(lProperty) then
        raise Exception.Create(QualifiedClassName + '.BuildStatementUpdate: Property ' + lNotation.PropertyName + 'not found');

      AddPair(lProperty, aObject, lNotation, lIsDateField, lPairs, TStatementType.Update);
    end;

    var lStatement := TOrionNotationStatementValueUpdate.New(Self);
    lStatement.AddFields(lPairs);
    lStatement.Value(' where ' + lPKFieldName + ' = ' + lPKValue.ToString);

    FBuildStatement.Add(lStatement);
    SetStatementItensInResult(FBuildStatement);
    Result := FBuildStatement;
  finally
    lType.DisposeOf;
  end;
end;

procedure TOrionNotation.BuildSQLSelectList(aObject: TObject; aNotationItem: TNotationData);
begin
  var lObject := aNotationItem.Notacao.ObjectType.Create;
  try
    aNotationItem.Notacao.SetObject(lObject);
    var lStatements := aNotationItem.Notacao.BuildStatement(TStatementType.Select, False);
    for var lStatement in lStatements do
      FStatementItens.Add(lStatement);
  finally
    lObject.DisposeOf;
  end;
end;

procedure TOrionNotation.BuildSQLUpdateList(aObject: TObject; aNotationItem: TNotationData);
begin
  var lStatements : TList<iNotationStatementValue>;
  for var lObject in TObjectList<TObject>(aObject) do
  begin
    aNotationItem.Notacao.SetObject(lObject);
    if GetPKValue(lObject, aNotationItem.Notacao.GetNotationsList) <> 0 then
      lStatements := aNotationItem.Notacao.BuildStatement(TStatementType.Update, False)
    else
      lStatements := aNotationItem.Notacao.BuildStatement(TStatementType.Insert, False);

    for var lStatement in lStatements do
    begin
      FStatementItens.Add(lStatement);
    end;
  end;
end;

function TOrionNotation.BuildStatement(aSQLType: TStatementType; aIsOwner : Boolean = True): TList<iNotationStatementValue>;
begin
  Result := nil;
  if FTableName.IsEmpty then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: no one TableName setted.');

  if FNotations.Count = 0 then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: No one Notation setted.');

  if not Assigned(FObject) then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: No one Object setted');

  FBuildStatement.Clear;
  FStatementItens.Clear;
  var SetByPKIsTrue := True;
  case aSQLType of
    TStatementType.Select: Result := BuildSqLSelect(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Update: Result := BuildSQLUpdate(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Insert: Result := BuildSQLInsert(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Delete: Result := BuildSqLDelete(SetByPKIsTrue, FObject, aIsOwner);
  end;
end;

constructor TOrionNotation.Create(aOwner : iOrionNotation);
begin
  FBuildStatement := TList<iNotationStatementValue>.Create;
  FStatementItens := TList<iNotationStatementValue>.Create;
  FNotations      := TList<TNotationData>.Create;
  FJoins          := TList<string>.Create;
  FOwner          := aOwner;
end;

destructor TOrionNotation.Destroy;
begin
  FBuildStatement.DisposeOf;
  FStatementItens.DisposeOf;
  FNotations.DisposeOf;
  FJoins.DisposeOf;
  inherited;
end;

function TOrionNotation.GetNotationsList: TList<TNotationData>;
begin
  Result := FNotations;
end;

function TOrionNotation.GetObject: TObject;
begin
  Result := FObject;
end;

function TOrionNotation.GetPKTableName: string;
begin
  for var lNotacaoItem in FNotations do
  begin
    for var lConstraint in lNotacaoItem.Constraints do
    begin
      if lConstraint = TNotationConstraint.PK then
      begin
        Result := lNotacaoItem.DataSetFieldName;
        Exit;
      end;
    end;
  end;
end;

function TOrionNotation.GetPKValue(aObject: TObject; aNotations : TList<TNotationData>): integer;
begin
  Result := 0;
  for var lNotationItem in aNotations do
  begin
    for var lConstraint in lNotationItem.Constraints do
    begin
      if lConstraint <> TNotationConstraint.PK then
        Continue;

      var lTypeObject := TRttiContext.Create.GetType(aObject.ClassInfo);
      try
        var lProperty := lTypeObject.GetProperty(lNotationItem.PropertyName);
        Result := lProperty.GetValue(aObject).AsInteger;
      finally
        lTypeObject.DisposeOf;
      end;
      Exit;
    end;
  end;
end;

function TOrionNotation.GetTableFieldNameByPropertyName(aPropertyName: string): string;
begin
  for var lNotacaoItem in FNotations do
  begin
    if lNotacaoItem.PropertyName = aPropertyName then
    begin
      Result := lNotacaoItem.DataSetFieldName;
      Break;
    end;
  end;
end;

class function TOrionNotation.New(aOwner : iOrionNotation): iOrionNotation;
begin
  Result := Self.Create(aOwner);
end;

function TOrionNotation.ObjectType: TClass;
begin
  Result := FObjectType;
end;

function TOrionNotation.Owner(aValue: iOrionNotation): iOrionNotation;
begin
  Result := Self;
  FOwner := aValue;
end;

function TOrionNotation.Owner: iOrionNotation;
begin
  Result := FOwner;
end;

function TOrionNotation.SetDataSet(aDataset: TDataset): iOrionNotation;
begin
  Result := Self;
  FDataset := aDataset;
end;

function TOrionNotation.ForeignKey(aValue: string): iOrionNotation;
begin
  Result := Self;
  FForeingKey := aValue;
end;

function TOrionNotation.ForeignKey: string;
begin
  Result := FForeingKey;
end;

function TOrionNotation.SetObject(aObject: TObject): iOrionNotation;
begin
  Result := Self;
  FObject := aObject;
end;

function TOrionNotation.ObjectType(aObjectType: TClass): iOrionNotation;
begin
  FObjectType := aObjectType;
end;

procedure TOrionNotation.SetStatementItensInResult(aResult: TList<iNotationStatementValue>);
begin
  if FStatementItens.Count > 0 then
  begin
    for var I := 0 to Pred(FStatementItens.Count) do
    begin
      aResult.Add(FStatementItens.Items[I]);
    end;
  end;
end;


function TOrionNotation.TableName: string;
begin
  Result := FTableName;
end;

function TOrionNotation.TableName(aValue: string): iOrionNotation;
begin
  Result := Self;
  FTableName := aValue;
end;

end.

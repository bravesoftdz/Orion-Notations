unit Orion.Notations.Data.Engine;

interface

uses
  Orion.Notations.Interfaces,
  System.SysUtils,
  System.Rtti,
  System.Classes,
  System.Generics.Collections,
  Data.DB;

type
  TOrionNotationDataEngine = class(TInterfacedObject, iOrionNotationDataEngine)
  private
    FNotation : iOrionNotation;
    FNotationProcessor : iOrionNotationProcessor;
    FStatementsValues : TList<iNotationStatementValue>;
    FPrimaryKeyValue : string;
    FPersist : boolean;
    procedure ProcessStatementSelect;
    procedure ProcessStatementInsert;
    function ProcessStatementInsertWithReturn : string;
    procedure ProcessStatementUpdate;
    procedure ProcessStatementDelete;
    procedure InternalResolveToObject(aObject : TObject; aNotation : iOrionNotation; aDataset : TDataset);
    procedure InternalResolveToObjectList(aOwnerObject : TObject; aObjectListPropertyName : string; aStatement : iNotationStatementValue; aDataset : TDataset);
  public
    constructor Create(aOrionNotationProcessor : iOrionNotationProcessor; aPersist :boolean = True);
    destructor Destroy; override;
    class function New(aOrionNotationProcessor : iOrionNotationProcessor; aPersist :boolean = True) : iOrionNotationDataEngine;

    function SetNotation(aNotation : iOrionNotation) : iOrionNotationDataEngine;
    function ProcessNotation (aStatementType : TStatementType): string;
    function Statements : TList<iNotationStatementValue>;
  end;

implementation

{ TOrionNotationDataEngine }

constructor TOrionNotationDataEngine.Create(aOrionNotationProcessor : iOrionNotationProcessor; aPersist :boolean);
begin
  FNotationProcessor := aOrionNotationProcessor;
  FPersist := aPersist;
end;

destructor TOrionNotationDataEngine.Destroy;
begin

  inherited;
end;

procedure TOrionNotationDataEngine.InternalResolveToObject(aObject: TObject; aNotation : iOrionNotation; aDataset: TDataset);
begin
  var lContextObject := TRttiContext.Create;
  var lTypeObject    := lContextObject.GetType(aObject.ClassInfo);
  var lPropObject : TRttiProperty;
  var lField :TField;

  for var lNotacaoItem in aNotation.GetNotationsList do
  begin
    if Assigned(lNotacaoItem.Notacao) then
      Continue;

    lPropObject := lTypeObject.GetProperty(lNotacaoItem.PropertyName);
    if not Assigned(lPropObject) then
      raise Exception.Create(Self.QualifiedClassName +  '.InternalResolveToObject: PropertyName ' + lNotacaoItem.PropertyName + ' not found');

    lField := aDataSet.FindField(lNotacaoItem.DataSetFieldName);
    if not Assigned(lField) then
      raise Exception.Create(Self.QualifiedClassName +  '.InternalResolveToObject: TableFieldName ' + lNotacaoItem.DataSetFieldName + ' not found');

    case lPropObject.PropertyType.TypeKind of
      tkInteger     : lPropObject.SetValue(Pointer(aObject), lField.AsInteger);
      tkChar        : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkFloat       : lPropObject.SetValue(Pointer(aObject), lField.AsFloat);
      tkString      : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkWChar       : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkLString     : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkWString     : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkVariant     : lPropObject.SetValue(Pointer(aObject), TValue.FromVariant(lField.AsVariant));
      tkInt64       : lPropObject.SetValue(Pointer(aObject), lField.AsLargeInt);
      tkUString     : lPropObject.SetValue(Pointer(aObject), lField.AsString);
      tkSet         : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkSet not supported.');
      tkClass       : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkClass not supported.');
      tkMethod      : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkMethod not supported.');
      tkArray       : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkArray not supported.');
      tkRecord      : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkRecord not supported.');
      tkInterface   : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkInterface not supported.');
      tkDynArray    : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkDynArray not supported.');
      tkEnumeration : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkEnumeration not supported.');
      tkClassRef    : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkClassRef not supported.');
      tkPointer     : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkPointer not supported.');
      tkProcedure   : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkProcedure not supported.');
      tkMRecord     : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : type tkMRecord not supported.');
    end;
  end;
end;

procedure TOrionNotationDataEngine.InternalResolveToObjectList(aOwnerObject : TObject; aObjectListPropertyName : string; aStatement : iNotationStatementValue; aDataset : TDataset);
begin
  var lType := TRttiContext.Create.GetType(aOwnerObject.ClassInfo);
  try
    var lProperty := lType.GetProperty(aObjectListPropertyName);
    if not Assigned(lProperty) then
      Exit;

    aDataset.First;
    while not aDataset.Eof do
    begin
      var lObject := aStatement.Notation.ObjectType.Create;
      InternalResolveToObject(lObject, aStatement.Notation, aDataset);
      TObjectList<TObject>(lProperty.GetValue(aOwnerObject).AsObject).Add(lObject);
      aDataset.Next;
    end;
  finally
    lType.DisposeOf;
  end;
end;

class function TOrionNotationDataEngine.New(aOrionNotationProcessor : iOrionNotationProcessor; aPersist :boolean) : iOrionNotationDataEngine;
begin
  Result := Self.Create(aOrionNotationProcessor, aPersist);
end;

function TOrionNotationDataEngine.Statements: TList<iNotationStatementValue>;
begin
  Result := FStatementsValues;
end;

function TOrionNotationDataEngine.ProcessNotation(aStatementType : TStatementType): string;
begin
  case aStatementType of
    TStatementType.Select           : ProcessStatementSelect;
    TStatementType.Update           : ProcessStatementUpdate;
    TStatementType.Insert           : ProcessStatementInsert;
    TStatementType.InsertWithReturn : Result := ProcessStatementInsertWithReturn;
    TStatementType.Delete           : ProcessStatementDelete;
  end;
end;

procedure TOrionNotationDataEngine.ProcessStatementDelete;
begin
  FStatementsValues := FNotation.BuildStatement(TStatementType.Delete);
  FPrimaryKeyValue := '';
  try
    if FStatementsValues.Count = 0 then
      Exit;

    FNotationProcessor.StartTransaction;
    FNotationProcessor.StatementType(TDataProcessorStatementType.Write);

    for var I := 0 to Pred(FStatementsValues.Count) do
    begin
      if I > 0 then
      begin
        FStatementsValues.Items[i].UpdateField(FStatementsValues.Items[i].Notation.ForeignKey, FPrimaryKeyValue);
        FNotationProcessor.StatementType(TDataProcessorStatementType.Write);
      end;

      FNotationProcessor.StateMent(FStatementsValues.Items[i].Value);
      FNotationProcessor.Execute;

      if (FStatementsValues.Count > 1) and (I = 0) then
          FPrimaryKeyValue := FStatementsValues.Items[I].GetPairValue(FNotation.GetPKTableName);
    end;

    if FPersist then
      FNotationProcessor.Commit;
  except on E: Exception do
    begin
      FNotationProcessor.RollBack;
      raise Exception.Create(E.Message);
    end;
  end;
end;

procedure TOrionNotationDataEngine.ProcessStatementInsert;
begin
  FStatementsValues := FNotation.BuildStatement(TStatementType.Insert);
  FPrimaryKeyValue := '';
  try
    if FStatementsValues.Count = 0 then
      Exit;

    FNotationProcessor.StartTransaction;
    FNotationProcessor.StatementType(TDataProcessorStatementType.WriteWithReturn);

    for var I := 0 to Pred(FStatementsValues.Count) do
    begin
      if I > 0 then
      begin
        FStatementsValues.Items[i].UpdateField(FStatementsValues.Items[i].Notation.ForeignKey, FPrimaryKeyValue);
        FNotationProcessor.StatementType(TDataProcessorStatementType.Write);
      end;

      FNotationProcessor.StateMent(FStatementsValues.Items[i].Value);
      FNotationProcessor.Execute;

      if FPrimaryKeyValue.IsEmpty then
        FPrimaryKeyValue := FNotationProcessor.Dataset.FieldByName(FNotation.GetPKTableName).AsString;
    end;
    if FPersist then
      FNotationProcessor.Commit;
  except on E: Exception do
    begin
      FNotationProcessor.RollBack;
      raise Exception.Create(E.Message);
    end;
  end;
end;

function TOrionNotationDataEngine.ProcessStatementInsertWithReturn: string;
begin
  ProcessStatementInsert;
  Result := FPrimaryKeyValue;
end;

procedure TOrionNotationDataEngine.ProcessStatementSelect;
begin
  FPrimaryKeyValue := '';
  FStatementsValues := FNotation.BuildStatement(TStatementType.Select);
  try
    if FStatementsValues.Count = 0 then
      Exit;

    FNotationProcessor.StatementType(TDataProcessorStatementType.Read);
    for var I := 0 to Pred(FStatementsValues.Count) do
    begin
      if I > 0 then
      begin
        FStatementsValues.Items[i].UpdateWhere(FStatementsValues.Items[i].Notation.ForeignKey, FPrimaryKeyValue); //(' where ' + FNotation.ForeignKey + ' = ' + FPrimaryKeyValue);
        FNotationProcessor.StateMent(FStatementsValues.Items[i].Value);
        FNotationProcessor.Execute;
        for var lObjectListPropertyName in FStatementsValues.Items[0].GetObjectListPropertyName do
        begin
          InternalResolveToObjectList(FNotation.GetObject, lObjectListPropertyName, FStatementsValues.Items[i], FNotationProcessor.Dataset);
        end;
        Continue;
      end;

      FNotationProcessor.StateMent(FStatementsValues.Items[i].Value);
      FNotationProcessor.Execute;
      InternalResolveToObject(FNotation.GetObject, FNotation, FNotationProcessor.Dataset);

      if FPrimaryKeyValue.IsEmpty then
        FPrimaryKeyValue := FNotationProcessor.Dataset.FieldByName(FNotation.GetPKTableName).AsString;
    end;
  except on E: Exception do
    begin
      FNotationProcessor.RollBack;
      raise Exception.Create(E.Message);
    end;
  end;
end;

procedure TOrionNotationDataEngine.ProcessStatementUpdate;
begin
  FStatementsValues := FNotation.BuildStatement(TStatementType.Update);
  FPrimaryKeyValue := '';
  try
    if FStatementsValues.Count = 0 then
      Exit;

    FNotationProcessor.StartTransaction;
    FNotationProcessor.StatementType(TDataProcessorStatementType.Write);

    for var I := 0 to Pred(FStatementsValues.Count) do
    begin
      if I > 0 then
      begin
        FStatementsValues.Items[i].UpdateField(FStatementsValues.Items[i].Notation.ForeignKey, FPrimaryKeyValue);
        FNotationProcessor.StatementType(TDataProcessorStatementType.Write);
      end;

      FNotationProcessor.StateMent(FStatementsValues.Items[i].Value);
      FNotationProcessor.Execute;

      if (FStatementsValues.Count > 1) and (I = 0) then
          FPrimaryKeyValue := FStatementsValues.Items[I].GetPairValue(FNotation.GetPKTableName);
    end;

    if FPersist then
      FNotationProcessor.Commit;
  except on E: Exception do
    begin
      FNotationProcessor.RollBack;
      raise Exception.Create(E.Message);
    end;
  end;
end;

function TOrionNotationDataEngine.SetNotation(aNotation: iOrionNotation): iOrionNotationDataEngine;
begin
  Result := Self;
  FNotation := aNotation;
end;

end.

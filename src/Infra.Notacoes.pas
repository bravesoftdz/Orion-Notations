unit Infra.Notacoes;

interface

uses
  Infra.Notacoes.Interfaces,
  Data.DB,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  System.Variants;

type

  TNotation = class(TInterfacedObject, iNotation)
  private
    FDataset : TDataset;
    FObject : TObject;
    FTableName : string;
    FJoins : TList<string>;
    FNotacoes : TList<TNotacaoItem>;
    FBuildStatement : TStringList;
    FStatementItens : TObjectList<TStringList>;
    FForeingKey : string;
    procedure InternalResolveToDataSet(aDataSet : TDataSet; aObject : TObject);
    procedure InternalResolveToObject(aObject : TObject; aDataSet : TDataSet);
    procedure PrepareDataSet(aDataset : TDataSet);
    procedure SetStatementItensInResult(aResult : TStringList);

    function BuildSQLInsert(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TStringList;
    function BuildSQLUpdate(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TStringList; overload;
    function BuildSQLUpdate(aDataset : TDataset = nil) : TStringList; overload;
    function BuildSqLSelect(aSetByPK : boolean; aObject : TObject; aIsOwner : boolean = True) : TStringList;
    function BuildSqLDelete(aSetByPK : boolean = True) : TStringList;
    function GetPKValue(aObject : TObject; aNotations : TList<TNotacaoItem>) : integer;
    procedure BuildSQLInsertList(aObject : TObject; aNotationItem : TNotacaoItem);
    procedure BuildSQLUpdateList(aObject : TObject; aNotationItem : TNotacaoItem);
    procedure BuildSQLSelectList(aObject : TObject; aNotationItem : TNotacaoItem);
  public
    constructor Create;
    destructor Destroy; override;
    class function New : iNotation;

    function SetObject(aObject : TObject) : iNotation;
    function SetDataSet(aDataset : TDataset) : iNotation;
    function SetTableName(aValue : string) : iNotation;
    function ForeignKey(aValue : string) : iNotation; overload;
    function ForeingKey : string; overload;
    function AddNotation(aPropertyName, aTableFieldName : string; aConstraint : TNotacaoConstraints = []) : iNotation; overload;
    function AddNotation(aPropertyName : string; aNotation : iNotation) : iNotation; overload;
    function BuildStatement(aSQLType : TStatementType; aIsOwner : Boolean = True) : TStringList;
    function AddJoin(aValue : string) : iNotation;
    function GetPKTableName : string;
    function GetTableFieldNameByPropertyName(aPropertyName : string) : string;
    function GetNotationsList : TList<TNotacaoitem>;
    procedure ResolveToDataset;
    procedure ResolveToObject;
  end;

implementation

uses
  System.SysUtils;

{ TNotation }

function TNotation.AddJoin(aValue: string): iNotation;
begin
  Result := Self;
  FJoins.Add(aValue);
end;

function TNotation.AddNotation(aPropertyName, aTableFieldName: string; aConstraint: TNotacaoConstraints): iNotation;
begin
  Result := Self;
  var lNotacaoItem : TNotacaoItem;
  lNotacaoItem.PropertyName     := aPropertyName;
  lNotacaoItem.DataSetFieldName := aTableFieldName;
  lNotacaoItem.Constraints      := aConstraint;
  FNotacoes.Add(lNotacaoItem);
end;

function TNotation.AddNotation(aPropertyName: string; aNotation: iNotation): iNotation;
begin
  Result := Self;
  var lNotacaoItem : TNotacaoItem;
  lNotacaoItem.PropertyName := aPropertyName;
  lNotacaoItem.Notacao      := aNotation;
  FNotacoes.Add(lNotacaoItem);
end;

function TNotation.BuildSqLDelete(aSetByPK: boolean): TStringList;
begin
  raise Exception.Create('Not Implemented');
end;

function TNotation.BuildSQLInsert(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean): TStringList;
begin
  if not Assigned(aObject) then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatementInsert: No one object setted.');

  var lContext := TRttiContext.Create;
  var lType    := lContext.GetType(aObject.ClassInfo);
  var lValues  := TStringBuilder.Create;
  var lSQLReturning := '';
  var lProperty : TRttiProperty;
  Result := TStringList.Create;
  try
    var lPassou := False;
    Result.Append('insert into ' + FTableName + '(');
    for var lNotacaoItem in FNotacoes do
    begin
      var lAutoInc := False;
      var lIgnore := False;
      var lDateField := False;
      for var lConstraint in lNotacaoItem.Constraints do
      begin
        if lConstraint = TNotationConstraint.PK then
          lSQLReturning := ' returning ' + lNotacaoItem.DataSetFieldName;

        if lConstraint = TNotationConstraint.AutoInc then
          lAutoInc := True;

        if lConstraint = TNotationConstraint.IgnoreWriteSQLs then
          lIgnore := True;

        if lConstraint = TNotationConstraint.DateField then
          lDateField := True;
      end;

      if lAutoInc then
        Continue;

      if lIgnore then
        Continue;

      if lPassou then
      begin
        Result.Append(',');
        lValues.Append(',');
      end;

      Result.Append(lNotacaoItem.DataSetFieldName);

      lProperty := lType.GetProperty(lNotacaoItem.PropertyName);

      if not Assigned(lProperty) then
        raise Exception.Create(Self.QualifiedClassName +  '.BuildStatementInsert: Property '+ lNotacaoItem.PropertyName + ' not Found');

      case lProperty.PropertyType.TypeKind of
        tkInteger     : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsInteger);
        tkChar        : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkFloat       :
        begin
          if lDateField then
          begin
            var lData := FormatDateTime('dd.mm.yyyy', FloatToDateTime(lProperty.GetValue(Pointer(FObject)).AsExtended)).QuotedString;
            lValues.Append(lData);
          end
          else
            lValues.Append(lProperty.GetValue(Pointer(FObject)).AsExtended.ToString.Replace(',', '.', [rfReplaceAll]));
        end;

        tkString      : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkWChar       : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkLString     : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkWString     : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkUString     : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
        tkInt64       : lValues.Append(lProperty.GetValue(Pointer(FObject)).AsInt64);
        tkSet         : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkSet não implementado.');
        tkClass       :
        begin
          if lProperty.GetValue(Pointer(FObject)).AsObject.ClassName.Contains('TObjectList<') then
            BuildSQLInsertList(lProperty.GetValue(Pointer(FObject)).AsObject, lNotacaoItem);
        end;
        tkMethod      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkMethod não implementado.');
        tkUnknown     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkUnknown não implementado.');
        tkEnumeration : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkEnumetarion não implementado.');
        tkVariant     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkVariant não implementado.');
        tkArray       : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkArray não implementado.');
        tkRecord      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkRecord  não implementado.');
        tkInterface   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkInterface não implementado.');
        tkDynArray    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkDynArray não implementado.');
        tkClassRef    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkClassRef não implementado.');
        tkPointer     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkPointer não implementado.');
        tkProcedure   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkProcedure não implementado.');
        tkMRecord     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLInsert : Tipo tkMRecord não implementado.');

      end;

      lPassou := True;
    end;
    Result.Append(') values (');
    Result.Append(lValues.ToString);
    Result.Append(')');
    if aIsOwner then
    begin
      if not lSQLReturning.IsEmpty then
        Result.Append(lSQLReturning);
    end;
    SetStatementItensInResult(Result);
  finally
    lValues.DisposeOf;
  end;
end;

procedure TNotation.BuildSQLInsertList(aObject: TObject; aNotationItem : TNotacaoItem);
begin
  for var lObject in TObjectList<TObject>(aObject) do
  begin
    aNotationItem.Notacao.SetObject(lObject);
     var lStatement := aNotationItem.Notacao.BuildStatement(TStatementType.Insert, False);
     FStatementItens.Add(lStatement);
  end;
end;

function TNotation.BuildSqLSelect(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean = True): TStringList;
begin
  if FNotacoes.Count = 0 then
    raise Exception.Create(Self.QualifiedClassName +  '.BuildSqlSelect : Nenhuma notação adicionada.');

  var lSQL    := TStringBuilder.Create;
  var lPassou := False;
  var lWhere  := '';
  Result      := TStringList.Create;
  try
    lSQL.Append('select ');
    for var lNotacaoItem in FNotacoes do
    begin
      if aSetByPK then
      begin
        for var lConstraint in lNotacaoItem.Constraints do
        begin
          if (lConstraint = TNotationConstraint.PK) and aIsOwner then
            lWhere := ' where ' + lNotacaoItem.DataSetFieldName + ' = ';
        end;
      end;

      if Assigned(lNotacaoItem.Notacao) then
        BuildSQLSelectList(nil, lNotacaoItem);

      if lNotacaoItem.DataSetFieldName.IsEmpty then
        Continue;

      if lPassou then
        lSQL.Append(', ');

      lSQL.Append(FTableName + '.' + lNotacaoItem.DataSetFieldName);
      lPassou := True;
    end;

    lSQL.Append(' from ' + FTableName);

    if FJoins.Count > 0 then
    begin
      for var lJoin in FJoins do
        lSQL.Append(lJoin);
    end;

    if not aIsOwner then
      lWhere := ' where ' + FForeingKey + ' = ';

    if not lWhere.IsEmpty then
      lSQL.Append(lWhere);

    Result.Append(lSQL.ToString);
    SetStatementItensInResult(Result);
  finally
    lSQL.DisposeOf;
  end;
end;

function TNotation.BuildSQLUpdate(aSetByPK: boolean; aObject : TObject; aIsOwner : boolean = True): TStringList;
begin
  if not Assigned(FObject) then
    Exit;

  var lCampo : string;
  var lValor : Variant;
  var lSQL     := TStringBuilder.Create;
  var lType    := TRttiContext.Create.GetType(FObject.ClassInfo);
  var lPassou  := False;
  Result := TStringList.Create;
  try
    lSQL.Append('update ' + FTableName + ' set ');

    for var lNotacaoItem in FNotacoes do
    begin
      var lDateField := False;
      var lProperty := lType.GetProperty(lNotacaoItem.PropertyName);
      var lIgnore := False;
      if Assigned(lProperty) then
      begin
        for var lConstraint in lNotacaoItem.Constraints do
        begin
          if lConstraint = TNotationConstraint.PK then
          begin
            lCampo := lNotacaoItem.DataSetFieldName;
            lValor := lProperty.GetValue(Pointer(FObject)).AsVariant;
            lIgnore := True;
          end;

          if lConstraint = TNotationConstraint.IgnoreWriteSQLs then
            lIgnore := True;

          if lConstraint = TNotationConstraint.DateField then
            lDateField := True;
        end;

        if lIgnore then
          Continue;

        if lPassou then
        begin
          lSQL.Append(',');
        end;

        case lProperty.PropertyType.TypeKind of
          tkInteger     : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsInteger);
          tkInt64       : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsInt64);
          tkChar        : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkFloat       :
          begin
            if lDateField then
            begin
              var lData := FormatDateTime('dd.mm.yyyy', FloatToDateTime(lProperty.GetValue(Pointer(FObject)).AsExtended)).QuotedString;
              lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lData);
            end
            else
             lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsExtended.ToString.Replace(',', '.', [rfReplaceAll]));
          end;
          tkString      : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkWChar       : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkLString     : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkWString     : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkUString     : lSQL.Append(lNotacaoItem.DataSetFieldName).Append('=').Append(lProperty.GetValue(Pointer(FObject)).AsString.QuotedString);
          tkSet         : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkSet não implementado.');
          tkClass       :
          begin
            if lProperty.GetValue(Pointer(FObject)).AsObject.ClassName.Contains('TObjectList<') then
              BuildSQLUpdateList(lProperty.GetValue(Pointer(FObject)).AsObject, lNotacaoItem);
          end;
          tkMethod      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkMethod não implementado.');
          tkUnknown     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkUnknown não implementado.');
          tkEnumeration : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkEnumetarion não implementado.');
          tkVariant     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkVariant não implementado.');
          tkArray       : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkArray não implementado.');
          tkRecord      : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkRecord  não implementado.');
          tkInterface   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkInterface não implementado.');
          tkDynArray    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkDynArray não implementado.');
          tkClassRef    : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkClassRef não implementado.');
          tkPointer     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkPointer não implementado.');
          tkProcedure   : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkProcedure não implementado.');
          tkMRecord     : raise Exception.Create(Self.QualifiedClassName + '.BuildSQLUpdate : Tipo tkMRecord não implementado.');
        end;
        lPassou := True;
      end;
    end;

    if not lCampo.IsEmpty then
    begin
      lSQL.Append(' where ' + lCampo + ' = ' + VarToStr(lValor));
    end;
    Result.Append(lSQL.ToString);
    SetStatementItensInResult(Result);
  finally
    lSQL.DisposeOf;
  end;
end;

procedure TNotation.BuildSQLSelectList(aObject: TObject; aNotationItem: TNotacaoItem);
begin
  var lStatement := aNotationItem.Notacao.BuildStatement(TStatementType.Select, False);
  FStatementItens.Add(lStatement);
end;

function TNotation.BuildSQLUpdate(aDataset: TDataset): TStringList;
begin
  raise Exception.Create('Not Implemented');
end;

procedure TNotation.BuildSQLUpdateList(aObject: TObject; aNotationItem: TNotacaoItem);
begin
  var lStatement : TStringList;
  for var lObject in TObjectList<TObject>(aObject) do
  begin
    aNotationItem.Notacao.SetObject(lObject);
    if GetPKValue(lObject, aNotationItem.Notacao.GetNotationsList) <> 0 then
      lStatement := aNotationItem.Notacao.BuildStatement(TStatementType.Update, False)
    else
      lStatement := aNotationItem.Notacao.BuildStatement(TStatementType.Insert, False);
     FStatementItens.Add(lStatement);
  end;
end;

function TNotation.BuildStatement(aSQLType: TStatementType; aIsOwner : Boolean = True): TStringList;
begin
  if FTableName.IsEmpty then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: TableName not setted.');

  if FNotacoes.Count = 0 then
    raise Exception.Create(Self.QualifiedClassName + '.BuildStatement: No one Notation setted.');

  FBuildStatement.Clear;
  FStatementItens.Clear;
  var SetByPKIsTrue := True;
  case aSQLType of
    TStatementType.Select: Result := BuildSqLSelect(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Update: Result := BuildSQLUpdate(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Insert: Result := BuildSQLInsert(SetByPKIsTrue, FObject, aIsOwner);
    TStatementType.Delete: Result := BuildSqLDelete(SetByPKIsTrue);
  end;
end;

constructor TNotation.Create;
begin
  FBuildStatement := TStringList.Create;
  FStatementItens := TObjectList<TStringList>.Create;
  FNotacoes       := TList<TNotacaoItem>.Create;
  FJoins          := TList<string>.Create;
end;

destructor TNotation.Destroy;
begin
  FBuildStatement.DisposeOf;
  FStatementItens.DisposeOf;
  FNotacoes.DisposeOf;
  FJoins.DisposeOf;
  inherited;
end;

function TNotation.GetNotationsList: TList<TNotacaoitem>;
begin
  Result := FNotacoes;
end;

function TNotation.GetPKTableName: string;
begin
  for var lNotacaoItem in FNotacoes do
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

function TNotation.GetPKValue(aObject: TObject; aNotations : TList<TNotacaoItem>): integer;
begin
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

function TNotation.GetTableFieldNameByPropertyName(aPropertyName: string): string;
begin
  for var lNotacaoItem in FNotacoes do
  begin
    if lNotacaoItem.PropertyName = aPropertyName then
    begin
      Result := lNotacaoItem.DataSetFieldName;
      Break;
    end;
  end;
end;

procedure TNotation.InternalResolveToDataSet(aDataSet: TDataSet; aObject: TObject);
begin
  var lContextObject := TRttiContext.Create;
  var lTypeObject    := lContextObject.GetType(aObject.ClassInfo);
  var lPropObject : TRttiProperty;
  var lField :TField;

  for var lNotacaoItem in FNotacoes do
  begin
    lPropObject := lTypeObject.GetProperty(lNotacaoItem.PropertyName);
    if Assigned(lPropObject) then
      raise Exception.Create(Self.QualifiedClassName +  '.ResolveToObject: PropertyName ' + lNotacaoItem.PropertyName + ' not found');

    lField := aDataSet.FindField(lNotacaoItem.DataSetFieldName);
    if not Assigned(lField) then
      raise Exception.Create(Self.QualifiedClassName +  '.ResolveToObject: TableFieldName ' + lNotacaoItem.DataSetFieldName + ' not found');

    case lField.DataType of
      ftString     : lField.AsString     := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsString;
      ftSmallint   : lField.AsInteger    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsInteger;
      ftInteger    : lField.AsInteger    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsInteger;
      ftBoolean    : lField.AsBoolean    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsBoolean;
      ftFloat      : lField.AsFloat      := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsExtended;
      ftCurrency   : lField.AsCurrency   := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsCurrency;
      ftBCD        : lField.AsVariant    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsVariant;
      ftDate       : lField.AsVariant    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsVariant;
      ftTime       : lField.AsVariant    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsVariant;
      ftDateTime   : lField.AsVariant    := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsVariant;
      ftFixedChar  : lField.AsString     := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsString;
      ftWideString : lField.AsWideString := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsString;
      ftLargeint   : lField.AsLargeInt   := lPropObject.GetValue(Pointer(aObject.ClassInfo)).AsInt64;
      ftBlob: raise Exception.Create('conversores.notacoes.TNotacao.InternalResolveToDataset : Formato Blob não suportado.');
    end;
  end;
end;

procedure TNotation.InternalResolveToObject(aObject: TObject; aDataSet: TDataSet);
begin
  var lContextObject := TRttiContext.Create;
  var lTypeObject    := lContextObject.GetType(aObject.ClassInfo);
  var lPropObject : TRttiProperty;
  var lField :TField;

  for var lNotacaoItem in FNotacoes do
  begin
    lPropObject := lTypeObject.GetProperty(lNotacaoItem.PropertyName);
    if Assigned(lPropObject) then
      raise Exception.Create(Self.QualifiedClassName +  '.ResolveToObject: PropertyName ' + lNotacaoItem.PropertyName + ' not found');

    lField := aDataSet.FindField(lNotacaoItem.DataSetFieldName);
    if not Assigned(lField) then
      raise Exception.Create(Self.QualifiedClassName +  '.ResolveToObject: TableFieldName ' + lNotacaoItem.DataSetFieldName + ' not found');

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
      tkSet         : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkSet não suportado.');
      tkClass       : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkClass não suportado.');
      tkMethod      : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkMethod não suportado.');
      tkArray       : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkArray não suportado.');
      tkRecord      : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkRecord não suportado.');
      tkInterface   : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkInterface não suportado.');
      tkDynArray    : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkDynArray não suportado.');
      tkEnumeration : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkEnumeration não suportado.');
      tkClassRef    : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkClassRef não suportado.');
      tkPointer     : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkPointer não suportado.');
      tkProcedure   : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkProcedure não suportado.');
      tkMRecord     : raise Exception.Create(Self.QualifiedClassName + '.InternalResolveToObject : Formato tkMRecord não suportado.');
    end;
  end;
end;

class function TNotation.New: iNotation;
begin
  Result := Self.Create;
end;

procedure TNotation.PrepareDataSet(aDataset: TDataSet);
begin
  if aDataset.RecordCount > 0 then
    aDataset.Edit
  else
    aDataset.Append;
end;

procedure TNotation.ResolveToDataset;
begin
  if FObject.ClassName = 'TObjectList<T>' then
  begin
    for var lObject in TObjectList<TObject>(FObject) do
    begin
      PrepareDataSet(FDataset);
      InternalResolveToDataSet(FDataset, lObject);
      FDataset.Post;
    end;
    Exit;
  end;
  PrepareDataSet(FDataset);
  InternalResolveToDataSet(FDataset, FObject);
  FDataset.Post;

end;

procedure TNotation.ResolveToObject;
begin
  if FObject.ClassName.Contains('TObjectList') then
  begin
    var lClassType : TClass;
    if TObjectList<TObject>(FObject).Count = 0 then
      Exit;

    lClassType := TObjectList<TObject>(FObject).Items[0].ClassType;
    FDataset.First;
    while not FDataset.Eof do
    begin
      var lObject := lClassType.Create;
      InternalResolveToObject(lObject, FDataset);
      TObjectList<TObject>(FObject).Add(lObject);
      FDataset.Next;
    end;
    Exit;
  end;
  InternalResolveToObject(FObject, FDataset);
end;

function TNotation.SetDataSet(aDataset: TDataset): iNotation;
begin
  Result := Self;
  FDataset := aDataset;
end;

function TNotation.ForeignKey(aValue: string): iNotation;
begin
  Result := Self;
  FForeingKey := aValue;
end;

function TNotation.ForeingKey: string;
begin
  Result := FForeingKey;
end;

function TNotation.SetObject(aObject: TObject): iNotation;
begin
  Result := Self;
  FObject := aObject;
end;

procedure TNotation.SetStatementItensInResult(aResult: TStringList);
begin
  if FStatementItens.Count > 0 then
  begin
    for var I := 0 to Pred(FStatementItens.Count) do
    begin
      aResult.Append(FStatementItens.Items[I].Text);
    end;
  end;
end;

function TNotation.SetTableName(aValue: string): iNotation;
begin
  Result := Self;
  FTableName := aValue;
end;

end.

unit Orion.Notations.Interfaces;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Data.DB;

type
  {$SCOPEDENUMS ON}
  TStatementType = (Select, Update, Insert, InsertWithReturn, Delete);
  TDataProcessorStatementType = (None, Read, Write, WriteWithReturn);
  TNotationConstraint = (PK, AutoInc, IgnoreWriteSQLs, DateField, ObjectCollection);
  TProcessorDataBase = (Firebird, SQLite);
  {$SCOPEDENUMS OFF}

  TNotacaoConstraints = set of TNotationConstraint;

  iOrionNotation = interface;
  iNotationStatementValue = interface;

  TNotationData = record
    PropertyName : string;
    DataSetFieldName : string;
    Constraints : TNotacaoConstraints;
    Notacao : iOrionNotation;
  end;

  iOrionNotation = interface
    ['{99CADB8C-F4EC-4604-AF18-1201B6BFB9F1}']
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
    function AddWhere(aValue : string) : iOrionNotation;
    function GetPKTableName : string;
    function GetTableFieldNameByPropertyName(aPropertyName : string) : string;
    function GetNotationsList : TList<TNotationData>;
  end;

  iOrionNotationProcessor = interface
    ['{9C3B5BEA-D682-4D4B-98A7-39DC294809BE}']
    function Configurations(aPath, aUsername, aPassword, aServer : string; aPort : integer) : iOrionNotationProcessor;
    function StartTransaction : iOrionNotationProcessor;
    function StatementType(aValue : TDataProcessorStatementType) : iOrionNotationProcessor;
    function StateMent(aValue : string) : iOrionNotationProcessor;
    function Execute : iOrionNotationProcessor;
    function Commit : iOrionNotationProcessor;
    function RollBack : iOrionNotationProcessor;
    function Dataset : TDataset;
  end;

  iOrionNotationDataEngine = interface
    ['{98825426-74E8-4539-9414-B4039F1A9591}']
    function SetNotation(aNotation : iOrionNotation) : iOrionNotationDataEngine;
    function ProcessNotation(aStatementType : TStatementType) : string;
    function Statements : TList<iNotationStatementValue>;
  end;

  iOrionNotationProcessorsFactory = interface
    ['{E5670E88-F1F5-4A7D-9D0A-38627C32C3F7}']
    function Build(aProcessorDataBase : TProcessorDataBase) : iOrionNotationProcessor;
  end;

  iNotationStatementValue = interface
    ['{7FB8E95B-63AA-4DA4-A615-5C1AD6A1F9C4}']
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

end.

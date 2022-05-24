unit Infra.Notacoes.Interfaces;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Data.DB;

type
  {$SCOPEDENUMS ON}
  TStatementType = (Select, Update, Insert, Delete);
  TNotationConstraint = (PK, AutoInc, IgnoreWriteSQLs, DateField, ObjectCollection);
  {$SCOPEDENUMS OFF}

  TNotacaoConstraints = set of TNotationConstraint;

  iNotation = interface;

  TNotacaoItem = record
    PropertyName : string;
    DataSetFieldName : string;
    Constraints : TNotacaoConstraints;
    Notacao : iNotation;
  end;


  iNotation = interface
    ['{99CADB8C-F4EC-4604-AF18-1201B6BFB9F1}']
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

end.

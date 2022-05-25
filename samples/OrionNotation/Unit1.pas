unit Unit1;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,

  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  Orion.Notations,
  Orion.Notations.Interfaces,
  Orion.Notations.Data.Engine,
  Orion.Notations.Processors.Factory,
  Rest.JSON,
  entity.user;

type
  TForm1 = class(TForm)
    ButtonInsert: TButton;
    MemoLog: TMemo;
    ButtonUpdate: TButton;
    ButtonSelect: TButton;
    ButtonDelete: TButton;
    procedure ButtonInsertClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ButtonSelectClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
  private
    FUserNotation : iOrionNotation;
    FContactNotation : iOrionNotation;
    FNotationDataEngine : iOrionNotationDataEngine;
    procedure Log;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.ButtonInsertClick(Sender: TObject);
begin
  var User := TUser.Create;
  try
    User.Name := 'Ricardo';
    User.Salary := 100.1;
    User.BirthDate := Now;

    var lContact := TContact.Create;
    lContact.Description := '27999024818';
    User.Contacts.Add(lContact);

    lContact := TContact.Create;
    lContact.Description := 'facebook.com/r.pontes.cunha';
    User.Contacts.Add(lContact);

    FUserNotation.SetObject(User);
    FNotationDataEngine.SetNotation(FUserNotation);
    FNotationDataEngine.ProcessNotation(TStatementType.InsertWithReturn);
    Log;
  finally
    User.DisposeOf;
  end;
end;

procedure TForm1.ButtonUpdateClick(Sender: TObject);
begin
  var User := TUser.Create;
  try
    User.ID        := 2;
    User.Name      := 'Ricardo Alterado';
    User.Salary    := 100.2;
    User.BirthDate := StrToDate('24/06/1987');

    var lContact         := TContact.Create;
    lContact.ID          := 1;
    lContact.Description := '27999024817';
    User.Contacts.Add(lContact);

    lContact             := TContact.Create;
    lContact.ID          := 2;
    lContact.Description := 'facebook.com/rrrrr.pontes.cunha';
    User.Contacts.Add(lContact);

    lContact             := TContact.Create;
    lContact.Description := 'instagram.com/r.pontes.cunha';
    User.Contacts.Add(lContact);

    FUserNotation.SetObject(User);
    FNotationDataEngine.SetNotation(FUserNotation);
    FNotationDataEngine.ProcessNotation(TStatementType.Update);
    Log;
  finally
    User.DisposeOf;
  end;
end;

procedure TForm1.ButtonSelectClick(Sender: TObject);
begin
  var User := TUser.Create;
  try
    User.ID := 2;
    FUserNotation.SetObject(User);
    FNotationDataEngine.SetNotation(FUserNotation);
    FNotationDataEngine.ProcessNotation(TStatementType.Select);

    Log;
    var lJSON := TJson.ObjectToJsonString(User);
    MemoLog.Lines.Add(lJSON);
  finally
    User.DisposeOf;
  end;
end;

procedure TForm1.ButtonDeleteClick(Sender: TObject);
begin
  var User := TUser.Create;
  try
    User.ID := 6;
    FUserNotation.SetObject(User);
    FNotationDataEngine.SetNotation(FUserNotation);
    FNotationDataEngine.ProcessNotation(TStatementType.Delete);

    Log;
    var lJSON := TJson.ObjectToJsonString(User);
  finally
    User.DisposeOf;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FUserNotation := TOrionNotation.New;
  FContactNotation := TOrionNotation.New;

  FContactNotation.TableName('USER_CONTACTS').ObjectType(TContact);
  FContactNotation.AddNotation('ID', 'USER_CONT_ID', [TNotationConstraint.PK, TNotationConstraint.AutoInc]);
  FContactNotation.AddNotation('UserID', 'USER_CONT_ID_USER');
  FContactNotation.AddNotation('Description', 'USER_CONT_DESCRIPTION');

  FUserNotation.TableName('USER').ForeignKey('USER_CONT_ID_USER');
  FUserNotation.AddNotation('ID', 'USER_ID', [TNotationConstraint.PK, TNotationConstraint.AutoInc]);
  FUserNotation.AddNotation('Name', 'USER_NAME');
  FUserNotation.AddNotation('Salary', 'USER_SALARY');
  FUserNotation.AddNotation('BirthDate', 'USER_BIRTH_DATE', [TNotationConstraint.DateField]);
  FUserNotation.AddNotation('Contacts', FContactNotation);

  var Path := 'C:\Projetos\Orion-Notations\samples\OrionNotation\db';
  var UserName := '';
  var Password := '';
  var Server := '';
  var Port := 0;

  var lNotationProcessor := TOrionNotationsProcessorsFactory.New.Build(TProcessorDataBase.SQLite);
  lNotationProcessor.Configurations(Path, UserName, Password, Server, Port);
  FNotationDataEngine := TOrionNotationDataEngine.New(lNotationProcessor);
end;

procedure TForm1.Log;
begin
  MemoLog.Lines.Clear;
  for var lStatement in FNotationDataEngine.Statements do
  begin
    MemoLog.Lines.Add(lStatement.Value);
  end;
end;

end.

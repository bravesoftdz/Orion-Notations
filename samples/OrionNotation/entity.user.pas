unit entity.user;

interface

uses
  System.Generics.Collections;

type
  TContact = class
  private
    FID: integer;
    FDescription: string;
    FUserID: Integer;
  public
    property ID: integer read FID write FID;
    property UserID: Integer read FUserID write FUserID;
    property Description: string read FDescription write FDescription;
  end;

  TUser = class
  private
    FID: integer;
    FName: string;
    FSalary: Extended;
    FBirthDate: TDateTime;
    FContacts: TObjectList<TContact>;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: integer read FID write FID;
    property Name: string read FName write FName;
    property Salary: Extended read FSalary write FSalary;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
    property Contacts: TObjectList<TContact> read FContacts write FContacts;
  end;

implementation

{ TUser }

constructor TUser.Create;
begin
  FContacts := TObjectList<TContact>.Create;
end;

destructor TUser.Destroy;
begin
  FContacts.DisposeOf;
  inherited;
end;

end.

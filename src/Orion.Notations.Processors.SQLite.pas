unit Orion.Notations.Processors.SQLite;

interface

uses
  Orion.Notations.interfaces,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.FMXUI.Wait,
  {$IFDEF FMX}

  {$ELSEIFDEF VCL}
    FireDAC.VCLUI.Wait,
  {$ELSE}
    FireDAC.ConsoleUI.Wait,
  {$ENDIF}
  FireDAC.Comp.UI,
  FireDAC.Phys.IBBase,
  FireDAC.Phys.FB,
  Data.DB,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper;

type
  TOrionNotationsProcessorFireDACSQLite = class(TInterfacedObject, iOrionNotationProcessor)
  private
    FDBConnection : TFDConnection;
    FDriverLink : TFDPhysSQLiteDriverLink;
    FWaitCursor : TFDGUIxWaitCursor;
    FDBQuery : TFDQuery;
    FStatementType : TDataProcessorStatementType;
  public
    constructor Create;
    destructor Destroy; override;
    class function New : iOrionNotationProcessor;

    function Configurations(aPath, aUsername, aPassword, aServer : string; aPort : integer) : iOrionNotationProcessor;
    function StartTransaction : iOrionNotationProcessor;
    function StatementType(aValue : TDataProcessorStatementType) : iOrionNotationProcessor;
    function StateMent(aValue : string) : iOrionNotationProcessor;
    function Execute : iOrionNotationProcessor;
    function Commit : iOrionNotationProcessor;
    function RollBack : iOrionNotationProcessor;
    function Dataset : TDataset;
  end;

implementation

uses
  System.SysUtils;

{ TOrionNotationsProcessorFireDACSQLite }

function TOrionNotationsProcessorFireDACSQLite.Commit: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Commit;
end;

function TOrionNotationsProcessorFireDACSQLite.Configurations(aPath, aUsername, aPassword, aServer: string; aPort: integer): iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Params.DriverID := 'SQLite';
  FDBConnection.Params.Database := aPath;
  FDBConnection.Params.UserName := aUserName;
  FDBConnection.Params.Password := aPassword;
  FDBConnection.Params.AddPair('Port', aPort.ToString);
  FDBConnection.Params.AddPair('LockingMode', 'Normal');
  FDBConnection.Connected := False;
  FDBConnection.Connected := True;
end;

constructor TOrionNotationsProcessorFireDACSQLite.Create;
begin
  FDBConnection       := TFDConnection.Create(nil);
  FDriverLink         := TFDPhysSQLiteDriverLink.Create(nil);
  FDriverLink.EngineLinkage := slDynamic;
  FWaitCursor         := TFDGUIxWaitCursor.Create(nil);
  FDBQuery            := TFDQuery.Create(nil);
  FDBQuery.Connection := FDBConnection;
end;

function TOrionNotationsProcessorFireDACSQLite.Dataset: TDataset;
begin
  Result := FDBQuery;
end;

destructor TOrionNotationsProcessorFireDACSQLite.Destroy;
begin
  FDBQuery.DisposeOf;
  FDBConnection.DisposeOf;
  FDriverLink.DisposeOf;
  FWaitCursor.DisposeOf;
  inherited;
end;

function TOrionNotationsProcessorFireDACSQLite.Execute: iOrionNotationProcessor;
begin
  Result := Self;
  case FStatementType of
    TDataProcessorStatementType.None : raise Exception.Create('Selecione um StatementType');
    TDataProcessorStatementType.Read : FDBQuery.Open;
    TDataProcessorStatementType.Write: FDBQuery.ExecSQL;
    TDataProcessorStatementType.WriteWithReturn : FDBQuery.Open;
  end;
end;

class function TOrionNotationsProcessorFireDACSQLite.New: iOrionNotationProcessor;
begin
  Result := Self.Create;
end;

function TOrionNotationsProcessorFireDACSQLite.RollBack: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Rollback;
end;

function TOrionNotationsProcessorFireDACSQLite.StartTransaction: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.StartTransaction;
  FDBQuery.SQL.Clear;
end;

function TOrionNotationsProcessorFireDACSQLite.StateMent(aValue: string): iOrionNotationProcessor;
begin
  Result := Self;
  FDBQuery.SQL.Text := aValue;
end;

function TOrionNotationsProcessorFireDACSQLite.StatementType(aValue: TDataProcessorStatementType): iOrionNotationProcessor;
begin
  Result := Self;
  FStatementType := aValue;
end;

end.

unit Orion.Notations.Processors.FireDAC.Firebird;

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
  FireDAC.Phys.FBDef,
  {$IFDEF FMX}
    FireDAC.FMXUI.Wait,
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
  FireDAC.Comp.Client;

type
  TOrionNotationsProcessorFireDACFirebird = class(TInterfacedObject, iOrionNotationProcessor)
  private
    FDBConnection : TFDConnection;
    FDriverLink : TFDPhysFBDriverLink;
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

{ TOrionNotationsProcessorFireDACFirebird }

function TOrionNotationsProcessorFireDACFirebird.Commit: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Commit;
end;

function TOrionNotationsProcessorFireDACFirebird.Configurations(aPath, aUsername, aPassword, aServer: string; aPort: integer): iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Params.DriverID := 'FB';
  FDBConnection.Params.Database := aPath;
  FDBConnection.Params.UserName := aUserName;
  FDBConnection.Params.Password := aPassword;
  FDBConnection.Params.AddPair('Port', aPort.ToString);
  FDBConnection.Connected := False;
  FDBConnection.Connected := True;
end;

constructor TOrionNotationsProcessorFireDACFirebird.Create;
begin
  FDBConnection       := TFDConnection.Create(nil);
  FDriverLink         := TFDPhysFBDriverLink.Create(nil);
  FDBQuery            := TFDQuery.Create(nil);
  FDBQuery.Connection := FDBConnection;
end;

function TOrionNotationsProcessorFireDACFirebird.Dataset: TDataset;
begin
  Result := FDBQuery;
end;

destructor TOrionNotationsProcessorFireDACFirebird.Destroy;
begin
  FDBQuery.DisposeOf;
  FDBConnection.DisposeOf;
  FDriverLink.DisposeOf;
  inherited;
end;

function TOrionNotationsProcessorFireDACFirebird.Execute: iOrionNotationProcessor;
begin
  Result := Self;
  case FStatementType of
    TDataProcessorStatementType.None : raise Exception.Create('Selecione um StatementType');
    TDataProcessorStatementType.Read : FDBQuery.Open;
    TDataProcessorStatementType.Write: FDBQuery.ExecSQL;
    TDataProcessorStatementType.WriteWithReturn : FDBQuery.Open;
  end;
end;

class function TOrionNotationsProcessorFireDACFirebird.New: iOrionNotationProcessor;
begin
  Result := Self.Create;
end;

function TOrionNotationsProcessorFireDACFirebird.RollBack: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.Rollback;
end;

function TOrionNotationsProcessorFireDACFirebird.StartTransaction: iOrionNotationProcessor;
begin
  Result := Self;
  FDBConnection.StartTransaction;
end;

function TOrionNotationsProcessorFireDACFirebird.StateMent(aValue: string): iOrionNotationProcessor;
begin
  Result := Self;
  FDBQuery.SQL.Text := aValue;
end;

function TOrionNotationsProcessorFireDACFirebird.StatementType(aValue: TDataProcessorStatementType): iOrionNotationProcessor;
begin
  Result := Self;
  FStatementType := aValue;
end;

end.

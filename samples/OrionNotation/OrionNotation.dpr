program OrionNotation;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  entity.user in 'entity.user.pas',
  Orion.Notations.Data.Engine in '..\..\src\Orion.Notations.Data.Engine.pas',
  Orion.Notations.Interfaces in '..\..\src\Orion.Notations.Interfaces.pas',
  Orion.Notations in '..\..\src\Orion.Notations.pas',
  Orion.Notations.Processors.Factory in '..\..\src\Orion.Notations.Processors.Factory.pas',
  Orion.Notations.Processors.FireDAC.FireBird in '..\..\src\Orion.Notations.Processors.FireDAC.FireBird.pas',
  Orion.Notations.Processors.FireDAC.SQLite in '..\..\src\Orion.Notations.Processors.FireDAC.SQLite.pas',
  Orion.Notations.Statements.Delete in '..\..\src\Orion.Notations.Statements.Delete.pas',
  Orion.Notations.Statements.Insert in '..\..\src\Orion.Notations.Statements.Insert.pas',
  Orion.Notations.Statements.Select in '..\..\src\Orion.Notations.Statements.Select.pas',
  Orion.Notations.Statements.Update in '..\..\src\Orion.Notations.Statements.Update.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

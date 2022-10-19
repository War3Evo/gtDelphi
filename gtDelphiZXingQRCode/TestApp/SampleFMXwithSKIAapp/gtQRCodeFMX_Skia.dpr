program gtQRCodeFMX_Skia;

uses
  System.StartUpCopy,
  FMX.Forms,
  view.main in 'view.main.pas' {viewMain},
  gtQRCodeGenFMX in '..\..\Source\gtQRCodeGenFMX.pas',
  FMX.DelphiZXIngQRCode in '..\..\Source\FMX.DelphiZXIngQRCode.pas',
  gtCommandPrompt in '..\..\..\CommandPrompt\gtCommandPrompt.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TviewMain, viewMain);
  Application.Run;
end.

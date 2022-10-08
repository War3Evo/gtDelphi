program SampleFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  view.main in 'view.main.pas' {viewMain},
  gtQRCodeGenFMX in '..\..\Source\gtQRCodeGenFMX.pas',
  FMX.DelphiZXIngQRCode in '..\..\Source\FMX.DelphiZXIngQRCode.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TviewMain, viewMain);
  Application.Run;
end.

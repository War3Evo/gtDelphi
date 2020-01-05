{
  Created this component based on the information from
  https://stackoverflow.com/users/800214/whosrdaddy:

  For non unicode aware Delphi versions go here:
  https://stackoverflow.com/questions/10598313/communicate-with-command-prompt-through-delphi
}

unit gtCommandPrompt;

interface

uses
  System.SysUtils, System.Classes, Windows;

type
  TTmonitorUpdate = procedure(OutPut: AnsiString) of object;

  TTmonitor = class(TThread)  // pipe monitoring thread for console output
  private
    iThreadSleep: Cardinal;
    TextString: AnsiString;
    FTTmonitorUpdate: TTmonitorUpdate;
    procedure UpdateComponent;
  protected
    procedure Execute; override;
  public
    property OnUpdateComponent: TTmonitorUpdate read FTTmonitorUpdate write FTTmonitorUpdate;
  end;

  TOnReadCommandPrompt = procedure(OutPut: AnsiString) of object;
  TOnWriteCommandPrompt = procedure(OutPut: AnsiString) of object;

  TOnError = procedure(OutPut: AnsiString) of object;

  TCommandPrompt = class(TComponent)
  private
    { Private declarations }
    ThreadDone: Boolean;
    FThreadSleep: Cardinal;

    FComponentThread: TTmonitor;

    FOnError: TOnError;

    FOnReadCommandPrompt : TOnReadCommandPrompt;
    FOnWriteCommandPrompt : TOnWriteCommandPrompt;

    procedure OnThreadUpdate(OutPut: AnsiString);
  protected
    { Protected declarations }
  public
    { Public declarations }
    procedure Start();
    procedure Stop();

    procedure cmdWriteln(text: AnsiString);

    constructor Create(AOwner: TComponent); override;
  published
    { Published declarations }
    property ThreadSleep: Cardinal read FThreadSleep write FThreadSleep default 40;

    property OnReadCommandPrompt: TOnReadCommandPrompt read FOnReadCommandPrompt write FOnReadCommandPrompt;
    property OnWriteCommandPrompt: TOnWriteCommandPrompt read FOnWriteCommandPrompt write FOnWriteCommandPrompt;

    property OnError: TOnError read FOnError write FOnError;

    Destructor Destroy; override;
  end;

procedure Register;

var
  InputPipeRead, InputPipeWrite: THandle;
  OutputPipeRead, OutputPipeWrite: THandle;
  ErrorPipeRead, ErrorPipeWrite: THandle;
  ProcessInfo : TProcessInformation;

implementation

procedure Register;
begin
  RegisterComponents('gtDelphi', [TCommandPrompt]);
end;

constructor TCommandPrompt.Create(AOwner: TComponent);
begin
  inherited;

  ThreadDone := true;
  FThreadSleep := 40;
end;

procedure WritePipeOut(OutputPipe: THandle; InString: AnsiString);
// writes Instring to the pipe handle described by OutputPipe
  var
    byteswritten: Cardinal;
  begin
// most console programs require CR/LF after their input.
    InString := InString + #13#10;
    WriteFile(OutputPipe, Instring[1], Length(Instring), byteswritten, nil);
  end;

function ReadPipeInput(InputPipe: THandle; var BytesRem: Cardinal): AnsiString;
{
  reads console output from InputPipe.  Returns the input in function
  result.  Returns bytes of remaining information to BytesRem
}
var
  cTextBuffer: array[1..32767] of AnsiChar;
  sTextString: AnsiString;
  cBytesRead: Cardinal;
  cPipeSize: Cardinal;
begin
  Result := '';
  cBytesRead := 0;
  cPipeSize := Sizeof(cTextBuffer);
  // check if there is something to read in pipe
  PeekNamedPipe(InputPipe, nil, cPipeSize, @cBytesRead, @cPipeSize, @BytesRem);
  if cBytesRead > 0 then
    begin
      ReadFile(InputPipe, cTextBuffer, cPipeSize, cBytesRead, nil);
      // a requirement for Windows OS system components
      OemToCharA(@cTextBuffer, @cTextBuffer);
      sTextString := AnsiString(cTextBuffer);
      SetLength(sTextString, cBytesRead);
      Result := sTextString;
    end;
end;

procedure TTmonitor.Execute;
{ monitor thread execution for console output.  This must be threaded.
   checks the error and output pipes for information every 40 ms, pulls the
   data in and updates the memo on the form with the output }
var
  BytesRem: Cardinal;
begin
  while not Terminated do
    begin
      // read regular output stream and put on screen.
      TextString := ReadPipeInput(OutputPipeRead, BytesRem);
      if TextString <> '' then
         Synchronize(UpdateComponent);
      // now read error stream and put that on screen.
      TextString := ReadPipeInput(ErrorPipeRead, BytesRem);
      if TextString <> '' then
         Synchronize(UpdateComponent);
      sleep(iThreadSleep);
    end;
end;

procedure TTmonitor.UpdateComponent;
// synchronize procedure for monitor thread
begin
  if assigned(FTTmonitorUpdate) = true then
  begin
    try
      FTTmonitorUpdate(TextString);
    finally
    end;
  end;
end;

procedure TCommandPrompt.OnThreadUpdate(OutPut: AnsiString);
// synchronize procedure for monitor thread
begin
  if assigned(FOnReadCommandPrompt) = true then
  try
    FOnReadCommandPrompt(OutPut);
  finally
  end;
end;

Destructor TCommandPrompt.Destroy;
begin
  WritePipeOut(InputPipeWrite, 'EXIT'); // quit the CMD we started
  if FComponentThread.Terminated = false then FComponentThread.Terminate;
  // close process handles
  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
  // close pipe handles
  CloseHandle(InputPipeRead);
  CloseHandle(InputPipeWrite);
  CloseHandle(OutputPipeRead);
  CloseHandle(OutputPipeWrite);
  CloseHandle(ErrorPipeRead);
  CloseHandle(ErrorPipeWrite);

  // Always call the parent destructor after running your own code
  inherited;
end;


procedure TCommandPrompt.cmdWriteln(text: AnsiString);
begin
  WritePipeOut(InputPipeWrite, text);
  if assigned(FOnWriteCommandPrompt) = true then
  try
    FOnWriteCommandPrompt(text);
  finally

  end;
end;

procedure TCommandPrompt.Stop();
begin
  if FComponentThread.Terminated = false then FComponentThread.Terminate;
  ThreadDone := true;
end;

procedure TCommandPrompt.Start();
 { upon form creation, this calls the command-interpreter, sets up the three
   pipes to catch input and output, and starts a thread to monitor and show
   the output of the command-interpreter }
  var
    DosApp: String;
    DosSize: Byte;   // was integer
    Security : TSecurityAttributes;
    start : TStartUpInfo;
  begin
    if ThreadDone = false then
      begin
        if assigned(FOnError) then
        try
          FOnError('Start Error: Thread already running!');
        finally
        end;
        exit;
      end;

    //CommandText.Clear;
    // get COMSPEC variable, this is the path of the command-interpreter
    SetLength(Dosapp, 255);
    DosSize := GetEnvironmentVariable('COMSPEC', @DosApp[1], 255);
    SetLength(Dosapp, DosSize);

  // create pipes
    With Security do
      begin
        nlength := SizeOf(TSecurityAttributes) ;
        binherithandle := true;
        lpsecuritydescriptor := nil;
      end;
    CreatePipe(InputPipeRead, InputPipeWrite, @Security, 0);
    CreatePipe(OutputPipeRead, OutputPipeWrite, @Security, 0);
    CreatePipe(ErrorPipeRead, ErrorPipeWrite, @Security, 0);

  // start command-interpreter
    FillChar(Start,Sizeof(Start),#0) ;
    start.cb := SizeOf(start) ;
    start.hStdInput := InputPipeRead;
    start.hStdOutput := OutputPipeWrite;
    start.hStdError :=  ErrorPipeWrite;
    start.dwFlags := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
    start.wShowWindow := SW_HIDE;
    if CreateProcess(nil, PChar(DosApp), @Security, @Security, true,
               CREATE_NEW_CONSOLE or SYNCHRONIZE,
               nil, nil, start, ProcessInfo) then
      begin
        FComponentThread := TTmonitor.Create(true);  // don't start yet monitor thread
        FComponentThread.Priority := tpHigher;
        FComponentThread.iThreadSleep := 40;
        FComponentThread.FreeOnTerminate := true;
        FComponentThread.OnUpdateComponent := OnThreadUpdate;
        ThreadDone := false;
        FComponentThread.Start; // start thread;
      end;
 end;

end.

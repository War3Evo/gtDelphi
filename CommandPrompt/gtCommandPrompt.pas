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
  TTmonitorUpdate = procedure(OutPut, Error: AnsiString) of object;

  TTmonitor = class(TThread)  // pipe monitoring thread for console output
  private
    iThreadSleep: Cardinal;
    TextString: AnsiString;
    ErrorString: AnsiString;
    FTTmonitorUpdate: TTmonitorUpdate;
    procedure UpdateComponent;
  protected
    procedure Execute; override;
  public
    property OnUpdateComponent: TTmonitorUpdate read FTTmonitorUpdate write FTTmonitorUpdate;
  end;

  TOnReadCommandPrompt = procedure(OutPut: String) of object;
  TOnWriteCommandPrompt = procedure(OutPut: String) of object;

  TOnError = procedure(OutPut: String) of object;

  TgtCommandPrompt = class(TComponent)
  private
    { Private declarations }
    FThreadDone: Boolean;
    FThreadSleep: Cardinal;

    FComponentThread: TTmonitor;

    FOnError: TOnError;

    FOnReadCommandPrompt : TOnReadCommandPrompt;
    FOnWriteCommandPrompt : TOnWriteCommandPrompt;

    procedure OnThreadUpdate(OutPut, Error: AnsiString);
  protected
    { Protected declarations }
  public
    { Public declarations }
    procedure Start();
    procedure Stop();

    procedure cmdWriteln(text: String);

    // constructors are always public / syntax is always the same
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
  RegisterComponents('gtDelphi', [TgtCommandPrompt]);
end;

constructor TgtCommandPrompt.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);  //ALWAYS do this first!

    FThreadDone := true;
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
  SyncIT: Boolean;
begin
  while not Terminated do
    begin
      SyncIT := false;
      TextString := '';
      ErrorString := '';
      // read regular output stream.
      TextString := ReadPipeInput(OutputPipeRead, BytesRem);
      if TextString <> '' then SyncIT := true;
      // now read error stream.
      ErrorString := ReadPipeInput(ErrorPipeRead, BytesRem);
      if ErrorString <> '' then SyncIT := true;

      if SyncIT = true then Synchronize(UpdateComponent);
      sleep(iThreadSleep);
    end;
end;

procedure TTmonitor.UpdateComponent;
// synchronize procedure for monitor thread
begin
  if assigned(FTTmonitorUpdate) = true then
     FTTmonitorUpdate(TextString, ErrorString);
  // clear buffer
  TextString := '';
  ErrorString := '';
end;

procedure TgtCommandPrompt.OnThreadUpdate(OutPut, Error: AnsiString);
// synchronize procedure for monitor thread
begin
  if assigned(FOnReadCommandPrompt) = true then
      if OutPut <> '' then FOnReadCommandPrompt(String(OutPut));
  if assigned(FOnError) = true then
      if Error <> '' then FOnError(String(Error));
end;

Destructor TgtCommandPrompt.Destroy;
begin
    WritePipeOut(InputPipeWrite, 'EXIT'); // quit the CMD we started

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


procedure TgtCommandPrompt.cmdWriteln(text: String);
begin
  WritePipeOut(InputPipeWrite, AnsiString(text));
  if assigned(FOnWriteCommandPrompt) = true then
    FOnWriteCommandPrompt(text);
end;

procedure TgtCommandPrompt.Stop();
begin
  if FComponentThread.Terminated = false then FComponentThread.Terminate;
  FThreadDone := true;
end;

procedure TgtCommandPrompt.Start();
 { upon form creation, this calls the command-interpreter, sets up the three
   pipes to catch input and output, and starts a thread to monitor and show
   the output of the command-interpreter }
  var
    DosApp: String;
    DosSize: Byte;   // was integer
    Security : TSecurityAttributes;
    start : TStartUpInfo;
  begin
    if FThreadDone = false then
      begin
        if assigned(FOnError) = true then
          FOnError('Start Error: Thread already running!');
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
        try
          FComponentThread.Priority := tpHigher;
          FComponentThread.iThreadSleep := FThreadSleep; // default is 40
          FComponentThread.FreeOnTerminate := true;
          FComponentThread.OnUpdateComponent := OnThreadUpdate;
          FThreadDone := false;
          FComponentThread.Start; // start thread;
        except
          FComponentThread.Free;
          Raise Exception.Create('Could not create monitor thread!');
        end;
      end;
 end;

end.

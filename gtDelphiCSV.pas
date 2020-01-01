unit gtDelphiCSV;

interface

uses
  System.SysUtils, System.Classes;

{
  Created in 2019 by El Diablo using Delphi 10.3.3
  https://github.com/War3Evo

  gtDelphiCSV is a component is meant to break down CSV files
  by reading each line of the csv file.  You can change the CSV file contents
  line by line if the isModified is set to true via the OnProcess procedure.

  Roadmap:

  - Create package files for redistribute for others to use in all delphi platforms

  - Create a demo application with source code

  - Add Multi-Threading ability cross platform

  - OnProgress add PrecentageDone : byte 0 - 100 %

  - Add more ways to process files

  - TPersistent class for multi-threading properties
    https://flixengineering.com/archives/108
    https://stackoverflow.com/questions/8406567/creating-a-component-with-named-sub-components

}

type
  TOnBeforeProcess = procedure of object;
  TOnProcess = procedure(const LineNumber, TotalLines : integer; var Strings : TStringList; var isModified : boolean) of object;
  TOnProcessEnd = procedure(FinalMemoryStream : TMemoryStream) of object;


  TgtDelphiCSV = class(TComponent)
  private
    { Private declarations }
    FBreakString: String;

    FStoppingCount: integer;

    FAutoSaveBeforeOnProcessEnd: Boolean;
    FAutoSaveAsYouModifyData: Boolean;

    FOnProcess : TOnProcess;
    FOnBeforeProcess : TOnBeforeProcess;
    FOnProcessEnd : TOnProcessEnd;

    FisFileLocationAndName : Boolean;
    FisTMemoryStream : Boolean;

    sSaveAsDifferentFileLocationAndName: String;
    FSaveAsDifferentFileLocationAndName: Boolean;

    function gtBreakStringIsStored: Boolean;
    procedure SetBreakString(const Value: String);
  protected
    { Protected declarations }
    procedure ProcessCSV(var gtMemoryStream : TMemoryStream);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure Start(memStream : TMemoryStream); Overload;
  published
    { Published declarations }
    procedure Start(FileLocationAndName, SaveAsDifferentFileLocationAndName : String); Overload;

    property BreakString: String read FBreakString write SetBreakString stored gtBreakStringIsStored;

    property StoppingCount: integer read FStoppingCount write FStoppingCount default -1;

    property AutoSaveBeforeOnProcessEnd: Boolean read FAutoSaveBeforeOnProcessEnd write FAutoSaveBeforeOnProcessEnd;
    property AutoSaveAsYouModifyData: Boolean read FAutoSaveAsYouModifyData write FAutoSaveAsYouModifyData;

    property SaveAsDifferentFileLocationAndName: Boolean read FSaveAsDifferentFileLocationAndName write FSaveAsDifferentFileLocationAndName;

    property isFileLocationAndName: Boolean read FisFileLocationAndName;
    property isTMemoryStream: Boolean read FisTMemoryStream;

    property OnBeforeProcess: TOnBeforeProcess read FOnBeforeProcess write FOnBeforeProcess;
    property OnProcess: TOnProcess read FOnProcess write FOnProcess;
    property OnProcessEnd: TOnProcessEnd read FOnProcessEnd write FOnProcessEnd;
  end;

var
  sFileLocationAndName: String;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('gtDelphi', [TgtDelphiCSV]);
end;

constructor TgtDelphiCSV.Create(AOwner: TComponent);
begin
  Inherited;
  FBreakString := ',';
  FStoppingCount := -1;
end;

procedure TgtDelphiCSV.SetBreakString(const Value: String);
begin
  if FBreakString <> Value then
  begin
    FBreakString := Value;
  end;
end;

function TgtDelphiCSV.gtBreakStringIsStored: Boolean;
begin
  Result := FBreakString <> ',';
end;

function ReverseSplit(BreakString: String; StringList: TStrings): String;
var
  I: integer;
  sString: String;
begin
  sString := StringList[1];
  for I := 1 to StringList.Count-1 do
  begin
    sString := Concat(sString,BreakString,StringList[I]);
  end;
  result := sString;
end;

procedure pSplitIT(BreakString, BaseString: string; StringList: TStrings; ForceRightSideOfBreakString: boolean = false; Offset: integer = 1);
var
  EndOfCurrentString: byte;
  //TempStr: string;
  iLengthenBreakString: integer;
begin
  StringList.Clear;

  iLengthenBreakString := 0;

  // if the BreakString is greater than 1, it will force the break to be on the right side
  // of the BreakString instead of the left side
  if ForceRightSideOfBreakString = true then
    if length(BreakString) > 0 then iLengthenBreakString := length(BreakString);

  repeat
    if Offset = 1 then
      EndOfCurrentString := Pos(BreakString, BaseString) + iLengthenBreakString
    else
      EndOfCurrentString := Pos(BreakString, BaseString, Offset) + iLengthenBreakString;

    if EndOfCurrentString > length(BaseString) then EndOfCurrentString := length(BaseString);

    if EndOfCurrentString = 0 then
      StringList.add(BaseString)
    else
      StringList.add(Copy(BaseString, 1, EndOfCurrentString - 1));
      BaseString := Copy(BaseString, EndOfCurrentString + length(BreakString), length(BaseString) - EndOfCurrentString);
  until EndOfCurrentString = 0;
end;

procedure TgtDelphiCSV.ProcessCSV(var gtMemoryStream : TMemoryStream);
var
  //FinalMemoryStream : TMemoryStream;
  gtStringList, TmpStringList: TStringList;
  StringCount: integer;
  I: Integer;
  isModified : boolean;

  procedure gtSave();
  begin
    if FileExists(sFileLocationAndName) then
    begin
      if SaveAsDifferentFileLocationAndName = true then
      begin
        gtStringList.SaveToFile(sSaveAsDifferentFileLocationAndName);
      end
      else
      begin
        gtStringList.SaveToFile(sFileLocationAndName);
      end;
    end
    else
    begin
      gtStringList.SaveToStream(gtMemoryStream);
    end;
  end;

begin
  if assigned(FOnBeforeProcess) then
  begin
    FOnBeforeProcess();
  end;

  gtStringList := TStringList.Create;
  gtStringList.Clear;
  TmpStringList := TStringList.Create;
  TmpStringList.Clear;

  gtStringList.LoadFromStream(gtMemoryStream);

  StringCount := gtStringList.Count;

  for I := 0 to StringCount-1 do
  begin
    pSplitIT(FBreakString,gtStringList.Strings[I],TmpStringList,false,1);
    isModified := false;
    if assigned(FOnProcess) = true then FOnProcess(I,StringCount,TmpStringList,isModified);
    if isModified = true then
    begin
      gtStringList.Strings[I] := ReverseSplit(FBreakString,TmpStringList);

      if FAutoSaveAsYouModifyData = true then
      begin
        gtSave;
      end;
    end;
    if FStoppingCount = I then break;
    if gtStringList.Count <> StringCount then StringCount := gtStringList.Count;
  end;

  TmpStringList.Free;

  if FAutoSaveBeforeOnProcessEnd = true then
  begin
    gtSave;
  end;

  if FileExists(sFileLocationAndName) then
  begin
    if SaveAsDifferentFileLocationAndName = true then
    begin
      gtStringList.SaveToFile(sSaveAsDifferentFileLocationAndName);
    end;
  end;

  if assigned(FOnProcessEnd) then
  begin
    gtStringList.SaveToStream(gtMemoryStream);
    FOnProcessEnd(gtMemoryStream);
  end;

  gtStringList.Free;
end;


procedure TgtDelphiCSV.Start(memStream : TMemoryStream);
var
  ProcessMemoryStream: TMemoryStream;
begin
  FisTMemoryStream := true;
  FisFileLocationAndName := false;
  sFileLocationAndName := '';
  ProcessMemoryStream := TMemoryStream.Create;
  ProcessMemoryStream.LoadFromStream(memStream);
  ProcessCSV(ProcessMemoryStream);
  ProcessMemoryStream.Free;
end;

procedure TgtDelphiCSV.Start(FileLocationAndName, SaveAsDifferentFileLocationAndName : String);
var
  ProcessMemoryStream: TMemoryStream;
begin
  FisTMemoryStream := false;
  FisFileLocationAndName := true;
  sFileLocationAndName := FileLocationAndName;
  sSaveAsDifferentFileLocationAndName := SaveAsDifferentFileLocationAndName;
  ProcessMemoryStream := TMemoryStream.Create;
  ProcessMemoryStream.LoadFromFile(FileLocationAndName);
  ProcessCSV(ProcessMemoryStream);
  ProcessMemoryStream.Free;
end;

end.


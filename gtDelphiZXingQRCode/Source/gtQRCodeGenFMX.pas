unit gtQRCodeGenFMX;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.DelphiZXIngQRCode,
  FMX.Graphics,
  FMX.Objects;

type
  TQRCodeEncoding = (qrAuto, qrNumeric, qrAlphanumeric, qrISO88591, qrUTF8NoBOM, qrUTF8BOM);

  //TOnGenerate = procedure(Sender: TObject; Tempo: Integer; const aQRCode: TBitmap) of object;

  TOnGenerate = procedure(Sender: TObject; const aQRCode: TBitmap) of object;
  TOnError = procedure(Sender: TObject; Error: String) of object;
  TOnFinish = procedure(Sender: TObject) of object;

  // Add threading
  TTmonitorUpdate = procedure(Phase: integer; Error: String; const aQRCode: TBitmap) of object;

  TThreadingQRCodeGen = class(TThread)  // pipe monitoring thread for console output
  private
    iThreadSleep: Cardinal;
    //TextString: String;
    iPhase: integer;
    ErrorString: String;
    TTFQRBitmap: TBitmap;
    FTTmonitorUpdate: TTmonitorUpdate;

    FQR: TDelphiZXingQRCode;     //where the magic happens

    procedure UpdateComponent;
  protected
    procedure Execute; override;
  public
    property OnUpdateComponent: TTmonitorUpdate read FTTmonitorUpdate write FTTmonitorUpdate;
  end;

  TgtQRCodeGenFMX = class(TComponent)
  private
    FThreadDone: Boolean;
    FThreadSleep: Cardinal;

    FComponentThread: TThreadingQRCodeGen;

    FData: String;           //QR code information
    FEncoding: TQRCodeEncoding;  //Kind of text
    FqrErrorCorrectionLevel: integer;
    FQZone: Integer;             //QR Code "Edge"
    //FQRBitmap: TBitmap;          //LINK - Bitmap for QR code return       // make the program have it's own bitmap & save memory
    FImageControl: TImage;       //LINK - control for displaying the QR Code
    FOnError: TOnError;
    FOnFinish: TOnFinish;
    FOnGenerateBefore: TOnGenerate;
    FOnGenerateDuring: TOnGenerate;
    FOnGenerateAfter: TOnGenerate;
    procedure DoGenQRCode(const aQRCode: TBitmap);
    procedure setImageControl(const Value: TImage);

    procedure OnThreadUpdate(Phase: integer; Error: String; const aQRCode: TBitmap);
  protected
    procedure DoOnError(ErrorMsg: String);
    procedure fDoSetErrorCorrectionLevel(value: integer);
  public
    constructor Create(aOwner: TComponent); override;
    //destructor Destroy; override;
    procedure GenerateQRCode;
    procedure Stop;
  published
    property Data: String read FData write FData;
    property Encoding: TQRCodeEncoding read FEncoding write FEncoding;
    property ErrorCorrectionLevel: integer read FqrErrorCorrectionLevel write fDoSetErrorCorrectionLevel;
    property QuietZone: Integer read FQZone write FQZone;
    property ImageControl: TImage read FImageControl write setImageControl;

    property ThreadSleep: Cardinal read FThreadSleep write FThreadSleep default 40;

    property OnGenerateBefore: TOnGenerate read FOnGenerateBefore write FOnGenerateBefore;   // before execute of thread
    property OnGenerateDuring: TOnGenerate read FOnGenerateDuring write FOnGenerateDuring;   // As the Bitmap is updated
    property OnGenerateAfter: TOnGenerate read FOnGenerateAfter write FOnGenerateAfter;    // Done
    property OnError: TOnError read FOnError write FOnError;
    property OnImageControlFinish: TOnFinish read FOnFinish write FOnFinish;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('gtDelphi', [TgtQRCodeGenFMX]);
end;

{ TThreadingQRCodeGen }

procedure TThreadingQRCodeGen.Execute;
{ Threading the QRCode }
var
  bitdata: TBitmapData;
  Col, Row: Integer;
  PixelC: TAlphaColor;
begin
      try
        TTFQRBitmap := TBitmap.Create;
        iPhase := 1; // before
        Synchronize(UpdateComponent);
        sleep(iThreadSleep);
        //if TTFQRBitmap.Canvas.BeginScene then
        try
          //TTFQRBitmap.Canvas.Clear(TalphaColors.White); //cleaning the bitmap
          TTFQRBitmap.SetSize(FQR.Rows, FQR.Columns);
          iPhase := 2;  // during
          for Row := 0 to Pred(FQR.Rows) do
            begin
              for Col := 0 to Pred(FQR.Columns) do
                begin
                  if FQR.IsBlack[Row,Col] then
                    PixelC := talphacolors.Black
                  else
                    PixelC := talphacolors.White;
                  if TTFQRBitmap.Map(TMapAccess.Write, bitdata) then
                    begin
                      Try
                        bitdata.SetPixel(Col,Row, PixelC);
                      Finally
                        TTFQRBitmap.Unmap(bitdata);
                      End;
                    end;
                    Synchronize(UpdateComponent);
                    sleep(iThreadSleep);
                end;
                Synchronize(UpdateComponent);
                sleep(iThreadSleep);
            end;
            iPhase := 3;  // after
            Synchronize(UpdateComponent);
            sleep(iThreadSleep);
        except on E:Exception do
          ErrorString := 'Code could not be created (' +  E.Message + ')';
        end;
        {else
        begin
          ErrorString := 'TTFQRBitmap.Canvas.BeginScene is false';
          Synchronize(UpdateComponent);
          sleep(iThreadSleep);
        end;}
        Synchronize(UpdateComponent);
        sleep(iThreadSleep);
      finally
        TTFQRBitmap.Free;
        FQR.Free;
      end;
      //Synchronize(UpdateComponent);
      //sleep(iThreadSleep);
    //end;
end;

procedure TThreadingQRCodeGen.UpdateComponent;
// synchronize procedure for thread
begin
  if assigned(FTTmonitorUpdate) = true then
     FTTmonitorUpdate(iPhase, ErrorString, TTFQRBitmap);
  // clear buffer
  ErrorString := '';
end;

procedure TgtQRCodeGenFMX.fDoSetErrorCorrectionLevel(value: integer);
begin
  if (value < 0) then
  begin
    FqrErrorCorrectionLevel:=0;
  end
  else if (value > 3) then
  begin
    FqrErrorCorrectionLevel:=3;
  end
  else FqrErrorCorrectionLevel := value;
end;

{ TgtQRCodeGenFMX & TThreadingQRCodeGen }

procedure TgtQRCodeGenFMX.OnThreadUpdate(Phase: integer; Error: String; const aQRCode: TBitmap);
// synchronize procedure for thread
begin
  if (Phase = 1) and (assigned(FOnGenerateBefore) = true) then
      FOnGenerateBefore(self,aQRCode);
  if (Phase = 2) and (assigned(FOnGenerateDuring) = true) then
      FOnGenerateDuring(self,aQRCode);
  if (Phase = 3) and (assigned(FOnGenerateAfter) = true) then
    begin
      FOnGenerateAfter(self,aQRCode);
      DoGenQRCode(aQRCode);
    end;

  if assigned(FOnError) = true then
      if Error <> '' then FOnError(self, String(Error));
end;

{ TgtQRCodeGenFMX }

constructor TgtQRCodeGenFMX.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FThreadDone := true;
  FThreadSleep := 40;
end;

{destructor TgtQRCodeGenFMX.Destroy;
begin
  inherited;
end;}

procedure TgtQRCodeGenFMX.DoGenQRCode(const aQRCode: TBitmap);
begin
  try
    try
      if Assigned(FImageControl) then  //linked control, so it already displays the result
        begin
          var rSrc: TRectF;
          var rDest: TRectF;
          FImageControl.DisableInterpolation := true;
          FImageControl.WrapMode := TImageWrapMode.Stretch;  // was iwStretch
          FImageControl.Bitmap.SetSize(aQRCode.Width, aQRCode.Height);

          rSrc := TRectF.Create(0, 0, aQRCode.Width, aQRCode.Height);
          rDest := TRectF.Create(0, 0, FImageControl.Bitmap.Width, FImageControl.Bitmap.Height);

          if FImageControl.Bitmap.Canvas.BeginScene then
            try
              FImageControl.Bitmap.Canvas.Clear(TAlphaColors.White);

              FImageControl.Bitmap.Canvas.DrawBitmap(aQRCode, rSrc, rDest, 1);
            finally
              FImageControl.Bitmap.Canvas.EndScene;
            end;
        end;
    except on E:Exception do
      DoOnError('Code could not be created (' +  E.Message + ')');
    end;
  finally
    if Assigned(FOnFinish) = true then
      FOnFinish(Self);
  end;
end;

procedure TgtQRCodeGenFMX.DoOnError(ErrorMsg: String);
begin
  if Assigned(FOnError) = true then
    FOnError(Self, ErrorMsg);
end;

procedure TgtQRCodeGenFMX.GenerateQRCode;
begin
  FComponentThread := TThreadingQRCodeGen.Create(true);  // don't start yet monitor thread;
  try
    FComponentThread.FQR := TDelphiZXingQRCode.Create;
    FComponentThread.FQR.Data := FData;
    FComponentThread.FQR.Encoding := FMX.DelphiZXIngQRCode.TQRCodeEncoding(Ord(FEncoding));
    FComponentThread.FQR.QuietZone := FQZone;
    FComponentThread.FQR.ErrorCorrectionLevel := FqrErrorCorrectionLevel;
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

procedure TgtQRCodeGenFMX.Stop;
begin
  if FComponentThread.Terminated = false then FComponentThread.Terminate;
  FThreadDone := true;
end;

procedure TgtQRCodeGenFMX.setImageControl(const Value: TImage);
begin
  FImageControl := Value;
end;

end.

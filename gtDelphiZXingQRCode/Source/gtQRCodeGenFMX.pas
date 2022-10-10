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

  TQRCodeFileFormat = set of (qrSVG, qrBMP); // choose to create one or both at the same time

  TOnFillColor = procedure(const x,y: integer; var sFillColorSVG: string; var TAlphaColorBMP: TAlphaColor) of object;

  //TOnGenerate = procedure(Sender: TObject; Tempo: Integer; const aQRCode: TBitmap) of object;

  TOnGenerate = procedure(Sender: TObject; const x,y: integer; const aQRCode: TBitmap; const sSVGfile: string) of object;
  TOnError = procedure(Sender: TObject; Error: String) of object;
  TOnFinish = procedure(Sender: TObject) of object;

  TOnLoad = procedure(Sender: TObject) of object;

  // Add threading
  TTmonitorUpdate = procedure(const Phase: integer; const Error: String; const x,y: integer; const aQRCode: TBitmap; const sSVGfile: string) of object;

  TThreadingQRCodeGen = class(TThread)  // pipe monitoring thread for console output
  private
    iThreadSleep: Cardinal;
    iPhase: integer;
    ErrorString: String;
    TTFQRBitmap: TBitmap;
    FTTmonitorUpdate: TTmonitorUpdate;

    sThreadSVGfile: String;
    FThreadQRCodeFileFormat: TQRCodeFileFormat;
    FThreadUseInnerStyleSVG: boolean;
    FTOnFillColor: TOnFillColor;
    FsFillColor: string;
    FiFillColorX: integer;
    FiFillColorY: integer;
    FThreadbCanChangeFillColor: boolean;
    FTAlphaColorBMP: TAlphaColor;

    FQR: TDelphiZXingQRCode;     //where the magic happens

    procedure UpdateComponent;
    procedure UpdateFillColor;
  protected
    procedure Execute; override;
  public
    property OnUpdateComponent: TTmonitorUpdate read FTTmonitorUpdate write FTTmonitorUpdate;
    property OnFillColorUpdateComponent: TOnFillColor read FTOnFillColor write FTOnFillColor;
  end;

  TgtQRCodeGenFMX = class(TComponent)
  private
    FThreadDone: Boolean;
    FThreadSleep: Cardinal;

    FComponentThread: TThreadingQRCodeGen;

    FQRCodeFileFormat: TQRCodeFileFormat;
    FUseInnerStyleSVG: boolean;
    FOnFillColor: TOnFillColor;
    FbCanChangeFillColor: boolean;

    FOnLoad: TOnLoad;

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

    procedure OnThreadUpdate(const Phase: integer; const Error: String; const x,y: integer; const aQRCode: TBitmap; const sSVGfile: string);
    procedure OnThreadFillColorUpdate(const x,y: integer; var sFillColorSVG: string; var TAlphaColorBMP: TAlphaColor);
  protected
    procedure DoOnError(ErrorMsg: String);
    procedure fDoSetErrorCorrectionLevel(value: integer);
  public
    constructor Create(aOwner: TComponent); override;
    //destructor Destroy; override;
    procedure GenerateQRCode;
    procedure Stop;
  published
    property MultiSelectFileFormat: TQRCodeFileFormat read FQRCodeFileFormat write FQRCodeFileFormat;

    property UseInnerStyleSVG: boolean read FUseInnerStyleSVG write FUseInnerStyleSVG;

    property CanChangeFillColor: boolean read FbCanChangeFillColor write FbCanChangeFillColor default false;

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
    property OnGenerateFinally: TOnFinish read FOnFinish write FOnFinish;
    property OnFillColor: TOnFillColor read FOnFillColor write FOnFillColor;   // only if CanChangeFillColor is true
    property OnLoad: TOnLoad read FOnLoad write FOnLoad;
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
  FillString: string;
begin
      sThreadSVGfile := '';
      try
        TTFQRBitmap := TBitmap.Create;
        iPhase := 1; // before
        Synchronize(UpdateComponent);
        sleep(iThreadSleep);
        try
          TTFQRBitmap.SetSize(FQR.Rows, FQR.Columns);
          if qrSVG in FThreadQRCodeFileFormat then
            sThreadSVGfile := sThreadSVGfile + '<svg viewBox="0 0 ' + FQR.Rows.ToString + ' ' + FQR.Columns.ToString + '" xmlns="http://www.w3.org/2000/svg">';
          iPhase := 2;  // during
          for Row := 0 to Pred(FQR.Rows) do
            begin
              if Terminated = true then exit;
              FiFillColorX := Row;
              for Col := 0 to Pred(FQR.Columns) do
                begin
                  if Terminated = true then exit;
                  FiFillColorY := Col;
                  if qrSVG in FThreadQRCodeFileFormat then
                  begin
                    if FQR.IsBlack[Row,Col] then
                      FillString := 'black'
                    else
                      FillString := 'white';
                    // Ability to change Fill Color
                    //if FThreadbCanChangeFillColor = true then    //May use this if the other doesn't work
                    if assigned(FTOnFillColor) then
                    begin
                      // Assign Fill color
                      FsFillColor := FillString;
                      Synchronize(UpdateFillColor);
                      // Reassign Fill color
                      FillString := FsFillColor;
                    end;
                    // Create SVG Rect
                    sThreadSVGfile := sThreadSVGfile + '<rect ';
                    sThreadSVGfile := sThreadSVGfile + 'width="1" ';
                    sThreadSVGfile := sThreadSVGfile + 'height="1" ';
                    sThreadSVGfile := sThreadSVGfile + 'x="' + Row.ToString + '" ';
                    sThreadSVGfile := sThreadSVGfile + 'y="' + Col.ToString + '" ';
                    if FThreadUseInnerStyleSVG = true then
                    begin
                      sThreadSVGfile := sThreadSVGfile + 'style="fill: ' + FillString + '; ';
                      sThreadSVGfile := sThreadSVGfile + 'stroke: ' + FillString + '; ';
                      sThreadSVGfile := sThreadSVGfile + 'stroke-width: 1;" />';
                    end
                    else
                    begin    // To be compatible with Skia4Delphi (Credit to viniciusfbb https://github.com/viniciusfbb)
                      sThreadSVGfile := sThreadSVGfile + 'fill="' + FillString + '" ';
                      sThreadSVGfile := sThreadSVGfile + 'stroke="' + FillString + '" ';
                      sThreadSVGfile := sThreadSVGfile + 'stroke-width="1" />';
                    end;
                  end;

                  if qrBMP in FThreadQRCodeFileFormat then
                  begin
                    if FQR.IsBlack[Row,Col] then
                      PixelC := talphacolors.Black
                    else
                      PixelC := talphacolors.White;
                    if assigned(FTOnFillColor) then
                    begin
                      // Assign Fill color
                      FTAlphaColorBMP := PixelC;
                      Synchronize(UpdateFillColor);
                      // Reassign Fill color
                      PixelC:= FTAlphaColorBMP;
                    end;
                    if TTFQRBitmap.Map(TMapAccess.Write, bitdata) then
                      begin
                        Try
                          bitdata.SetPixel(Col,Row, PixelC);
                        Finally
                          TTFQRBitmap.Unmap(bitdata);
                        End;
                      end;
                  end;
                  Synchronize(UpdateComponent);
                  sleep(iThreadSleep);
                end;
                Synchronize(UpdateComponent);
                sleep(iThreadSleep);
            end;
          if qrSVG in FThreadQRCodeFileFormat then
            sThreadSVGfile := sThreadSVGfile + '</svg>';
        except on E:Exception do
          ErrorString := 'Code could not be created (' +  E.Message + ')';
        end;

        iPhase := 3;  // after
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
     FTTmonitorUpdate(iPhase, ErrorString, FiFillColorX, FiFillColorY, TTFQRBitmap, sThreadSVGfile);
  // clear buffer
  ErrorString := '';
end;

procedure TThreadingQRCodeGen.UpdateFillColor;
// synchronize procedure for thread
begin
  if assigned(FTOnFillColor) = true then
     FTOnFillColor(FiFillColorX,FiFillColorY,FsFillColor,FTAlphaColorBMP);
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

procedure TgtQRCodeGenFMX.OnThreadUpdate(const Phase: integer; const Error: String; const x,y: integer; const aQRCode: TBitmap; const sSVGfile: string);
// synchronize procedure for thread
begin
  if (Phase = 1) and (assigned(FOnGenerateBefore) = true) then
      FOnGenerateBefore(self,x,y,aQRCode,sSVGfile);
  if (Phase = 2) and (assigned(FOnGenerateDuring) = true) then
      FOnGenerateDuring(self,x,y,aQRCode,sSVGfile);
  if (Phase = 3) and (assigned(FOnGenerateAfter) = true) then
    begin
      FOnGenerateAfter(self,x,y,aQRCode,sSVGfile);
      DoGenQRCode(aQRCode);
    end;

  if assigned(FOnError) = true then
      if Error <> '' then FOnError(self, String(Error));
end;

procedure TgtQRCodeGenFMX.OnThreadFillColorUpdate(const x,y: integer; var sFillColorSVG: string; var TAlphaColorBMP: TAlphaColor);
begin
  if assigned(FOnFillColor) = true then
  begin
    FOnFillColor(x,y,sFillColorSVG,TAlphaColorBMP);
  end;
end;

{ TgtQRCodeGenFMX }

constructor TgtQRCodeGenFMX.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FbCanChangeFillColor := false; // unused right now
  FUseInnerStyleSVG := true; // change to false if using Skia4Delphi
  FQRCodeFileFormat := [qrSVG];
  FThreadDone := true;
  FThreadSleep := 40;
  if assigned(FOnLoad) then
    FOnLoad(aOwner);
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
    FComponentThread.FThreadQRCodeFileFormat := FQRCodeFileFormat;
    FComponentThread.FThreadUseInnerStyleSVG := FUseInnerStyleSVG;
    FComponentThread.FThreadbCanChangeFillColor := FbCanChangeFillColor;
    FComponentThread.FQR := TDelphiZXingQRCode.Create;
    FComponentThread.FQR.Data := FData;
    FComponentThread.FQR.Encoding := FMX.DelphiZXIngQRCode.TQRCodeEncoding(Ord(FEncoding));
    FComponentThread.FQR.QuietZone := FQZone;
    FComponentThread.FQR.ErrorCorrectionLevel := FqrErrorCorrectionLevel;
    FComponentThread.Priority := tpHigher;
    FComponentThread.iThreadSleep := FThreadSleep; // default is 40
    FComponentThread.FreeOnTerminate := true;
    FComponentThread.OnUpdateComponent := OnThreadUpdate;
    FComponentThread.OnFillColorUpdateComponent := OnThreadFillColorUpdate;
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

unit view.main;

interface

{

  TviewMain Skia4Delphi source code

  Skia4Delphi: https://github.com/skia4delphi/skia4delphi

  - The Android code maybe outdated

  There's no way with FMX (without a third-party library) that I can figure out how to save a stretched file without blurriness.

  Version 1.0

    - Problems with visualization of qrcode image, set DisableInterpolation := True on TImage control
}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IoUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox,
  FMX.Memo, FMX.Objects, FMX.EditBox, FMX.SpinBox, FMX.ListBox,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Memo.Types,
  gtQRCodeGenFMX, FMX.Layouts, FMX.Effects, FMX.Filter.Effects, FMX.Colors,
  Skia, Skia.FMX, gtCommandPrompt;


type
  TviewMain = class(TForm)
    btnGen: TButton;
    grpConfig: TGroupBox;
    edtEncoding: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    edtQZone: TSpinBox;
    imgQRCode: TImage;
    mLog: TMemo;
    btnSave: TButton;
    SD: TSaveDialog;
    gtQRCodeGenFMX1: TgtQRCodeGenFMX;
    Label4: TLabel;
    WidthEdit: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    HeightEdit: TEdit;
    ScrollBox1: TScrollBox;
    MemoHints: TMemo;
    MemoData: TMemo;
    Label1: TLabel;
    Label7: TLabel;
    SVGcheckbox: TCheckBox;
    BMPcheckbox: TCheckBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    ColorComboBox1: TColorComboBox;
    Label12: TLabel;
    ColorComboBox2: TColorComboBox;
    SkLabel1: TSkLabel;
    SkSvg1: TSkSvg;
    StopButton: TButton;
    DONATE: TButton;
    gtCommandPrompt1: TgtCommandPrompt;
    Label14: TLabel;
    Button1: TButton;
    maxspeedCheckbox: TCheckBox;
    Label13: TLabel;
    Label15: TLabel;
    procedure btnGenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SVGcheckboxChange(Sender: TObject);
    procedure BMPcheckboxChange(Sender: TObject);
    procedure gtQRCodeGenFMX1GenerateFinally(Sender: TObject);
    procedure gtQRCodeGenFMX1GenerateBefore(Sender: TObject; const x,
      y: Integer; const aQRCode: TBitmap; const sSVGfile: string);
    procedure gtQRCodeGenFMX1GenerateDuring(Sender: TObject; const x,
      y: Integer; const aQRCode: TBitmap; const sSVGfile: string);
    procedure gtQRCodeGenFMX1GenerateAfter(Sender: TObject; const x, y: Integer;
      const aQRCode: TBitmap; const sSVGfile: string);
    procedure gtQRCodeGenFMX1FillColor(const x, y: Integer;
      var sFillColorSVG: string; var TAlphaColorBMP: TAlphaColor);
    procedure StopButtonClick(Sender: TObject);
    procedure DONATEClick(Sender: TObject);
    procedure gtCommandPrompt1ReadCommandPrompt(OutPut: string);
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

type
  TMisc = class
    class procedure OpenURL(sCommand: string);
  end;

var
  viewMain: TviewMain;
  myBitmap: TBitmap;
  //myImage: TImage;
  //iCount: integer;
  iHeight, iWidth, iButton: integer;
  sSVGFileContent: string;

implementation

{$R *.fmx}

{$DEFINE USE_SCANLINE}

class procedure TMisc.OpenURL(sCommand: string);
begin
{$IFDEF MSWINDOWS}
  //ShellExecute(0, 'OPEN', PChar(sCommand), '', '', SW_SHOWNORMAL);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  _system(PAnsiChar('open ' + AnsiString(sCommand)));
{$ENDIF POSIX}
end;

procedure TviewMain.btnGenClick(Sender: TObject);
begin
    mLog.Lines.Clear;

  if trim(MemoData.Text) = '' then
    begin
      ShowMessage('Enter with QRCode data');
      MemoData.SetFocus;
      exit;
    end;
  StopButton.Enabled := true;
  btnSave.Enabled := False;
  btnGen.Enabled := false;
  With gtQRCodeGenFMX1 do
    begin
      Data := Trim(MemoData.Text);
      Encoding := TQRCodeEncoding(edtEncoding.Selected.Index);
      QuietZone := StrToIntDef(edtQZone.Text,4);
      GenerateQRCode;
    end;
end;

procedure TviewMain.btnSaveClick(Sender: TObject);
//var tmpS: string;
begin
  if qrSVG in gtQRCodeGenFMX1.MultiSelectFileFormat then
    begin
      SD.DefaultExt := '*.svg';
      SD.Filter := 'SVG (*.svg)|*.svg';
      if SD.Execute then
      begin
        TFile.WriteAllText(SD.FileName, sSVGFileContent);
      end;
    end;

  if ((qrBMP in gtQRCodeGenFMX1.MultiSelectFileFormat) and (not myBitmap.IsEmpty)) then
    begin
      SD.DefaultExt := '*.bmp';
      SD.Filter := 'Bitmap (*.bmp)|*.bmp';
      if SD.Execute then
        begin
          //Currently saves a 32 by 32 pixel file

          //If windows
          //if Pos('windows',TOSVersion.ToString)>0 then
          //begin
            //windows work around
          //end;

          myBitmap.SaveToFile(SD.FileName);
        end;
    end;
end;

procedure TviewMain.Button1Click(Sender: TObject);
begin
  iButton := 2;
  gtCommandPrompt1.Start;
end;

procedure TviewMain.DONATEClick(Sender: TObject);
begin
  iButton := 1;
  gtCommandPrompt1.Start;
end;

procedure TviewMain.FormDestroy(Sender: TObject);
begin
  myBitmap.Free;
end;

procedure TviewMain.FormShow(Sender: TObject);
begin
  iButton := 0;
  myBitmap := TBitmap.Create;
  gtQRCodeGenFMX1.UseInnerStyleSVG := false; ///////////////////////////////////////////////////////////////////////////////

  if qrSVG in gtQRCodeGenFMX1.MultiSelectFileFormat then
    SVGcheckbox.IsChecked := true
  else
    SVGcheckbox.IsChecked := false;
  if qrBMP in gtQRCodeGenFMX1.MultiSelectFileFormat then
    BMPcheckbox.IsChecked := true
  else
    BMPcheckbox.IsChecked := false;
  edtQZone.Value := gtQRCodeGenFMX1.QuietZone;
end;

procedure TviewMain.gtCommandPrompt1ReadCommandPrompt(OutPut: string);
begin
  if iButton = 1 then
    gtCommandPrompt1.cmdWriteln('start https://www.timmons.pro/donate.php')
  else if iButton = 2 then
    gtCommandPrompt1.cmdWriteln('start https://github.com/War3Evo/gtDelphi/tree/master/gtDelphiZXingQRCode');

  gtCommandPrompt1.Stop;
end;

procedure TviewMain.gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
begin
  mLog.Lines.Add('An Error Occur: ' + Error);
end;

procedure TviewMain.gtQRCodeGenFMX1FillColor(const x, y: Integer;
  var sFillColorSVG: string; var TAlphaColorBMP: TAlphaColor);
begin
  //mLog.Lines.Add('sFillColorSVG before ' + sFillColorSVG);
  if ColorComboBox1.ItemIndex > -1 then
    if sFillColorSVG = 'black' then sFillColorSVG := ColorComboBox1.Items[ColorComboBox1.ItemIndex].Trim.ToLower;
  //mLog.Lines.Add('sFillColorSVG after ' + sFillColorSVG);
  if TAlphaColorBMP = TAlphaColorRec.Black then TAlphaColorBMP := ColorComboBox1.Color;

  if ColorComboBox2.ItemIndex > -1 then
    if sFillColorSVG = 'white' then sFillColorSVG := ColorComboBox2.Items[ColorComboBox2.ItemIndex].Trim.ToLower;
  if TAlphaColorBMP = TAlphaColorRec.White then TAlphaColorBMP := ColorComboBox2.Color;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateAfter(Sender: TObject; const x,
  y: Integer; const aQRCode: TBitmap; const sSVGfile: string);
//var rSrc: TRectF;
  //  rDest: TRectF;
begin
  //imgQRCode.Bitmap.Assign(aQRCode);
          //tmpStr := sSVGfile + '</svg>';
          //SkSvg1.Svg.WrapMode := TSkSvgWrapMode.Fit;
          //SkSvg1.Svg.Source := sSVGfile;

            myBitmap.Assign(aQRCode);
            sSVGFileContent := sSVGfile;

            SkSvg1.Svg.WrapMode := TSkSvgWrapMode.Fit;
            //SkSvg1.Svg.
            SkSvg1.Svg.Source := sSVGfile;
            //SkSvg1.Parent := self;

            //MLog.Lines.Add('');
            //MLog.Lines.Add(sSVGfile);

        // RESIZE BITMAP
        {
          try
            iWidth := StrToInt(Trim(WidthEdit.Text));
            iHeight := StrToInt(Trim(HeightEdit.Text));

            myImage.Width := iWidth;
            myImage.Height := iHeight;

            myImage.Size.Width := iWidth;
            myImage.Size.Height := iHeight;

            //myImage.Bitmap.Canvas.SetSize(iWidth,iHeight);

            myImage.DisableInterpolation := true;
            myImage.WrapMode := TImageWrapMode.Stretch;  // was iwStretch
            myImage.Bitmap.SetSize(aQRCode.Width, aQRCode.Height);
            rSrc := TRectF.Create(0, 0, aQRCode.Width, aQRCode.Height);
            rDest := TRectF.Create(0, 0, myImage.Bitmap.Width, myImage.Bitmap.Height);

            if myImage.Bitmap.Canvas.BeginScene then
              try
                myImage.Bitmap.Canvas.Clear(TAlphaColors.White);

                myImage.Bitmap.Canvas.DrawBitmap(aQRCode, rSrc, rDest, 1);
              finally
                myImage.Bitmap.Canvas.EndScene;

                iWidth := StrToInt(Trim(WidthEdit.Text));
                iHeight := StrToInt(Trim(HeightEdit.Text));

                //myImage.Bitmap.Width := iWidth;
                //myImage.Bitmap.Height := iHeight;
                //myImage.Bitmap.Canvas.
                //myImage.Bitmap.Resize(iWidth,iHeight);
              end;

            //tmpImage.Bitmap
            //myBitmap.Resize(1024,1024);
            //myImage.Bitmap.SaveToFile(SD.FileName);
          finally
            //tmpImage.Free;
          end;    }
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateBefore(Sender: TObject; const x,
  y: Integer; const aQRCode: TBitmap; const sSVGfile: string);
begin
            //iCount := 0;

            iWidth := StrToInt(Trim(WidthEdit.Text));
            iHeight := StrToInt(Trim(HeightEdit.Text));

            imgQRCode.Height := iHeight;
            imgQRCode.Width := iWidth;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateDuring(Sender: TObject; const x,
  y: Integer; const aQRCode: TBitmap; const sSVGfile: string);
          var rSrc: TRectF;
              rDest: TRectF;
              tmpStr: string;
begin
  if maxspeedCheckbox.IsChecked = true then
    begin
      //inc(iCount);
      label4.Text := x.ToString;
      Label8.Text := y.ToString;
      exit;
    end;

          imgQRCode.DisableInterpolation := true;
          imgQRCode.WrapMode := TImageWrapMode.Stretch;  // was iwStretch
          imgQRCode.Bitmap.SetSize(aQRCode.Width, aQRCode.Height);

          rSrc := TRectF.Create(0, 0, aQRCode.Width, aQRCode.Height);
          rDest := TRectF.Create(0, 0, imgQRCode.Bitmap.Width, imgQRCode.Bitmap.Height);

          if imgQRCode.Bitmap.Canvas.BeginScene then
            try
              imgQRCode.Bitmap.Canvas.Clear(TAlphaColors.White);

              imgQRCode.Bitmap.Canvas.DrawBitmap(aQRCode, rSrc, rDest, 1);
            finally
              imgQRCode.Bitmap.Canvas.EndScene;
            end;

          tmpStr := sSVGfile + '</svg>';
          //SkSvg1.Svg.Source := tmpStr;

          SkSvg1.Svg.WrapMode := TSkSvgWrapMode.Fit;
          //SkSvg1.Svg.
          SkSvg1.Svg.Source := tmpStr;
          //SkSvg1.Parent := self;

  //inc(iCount);
  label4.Text := x.ToString;
  Label8.Text := y.ToString;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateFinally(Sender: TObject);
begin
  mLog.Lines.Add('QRCode Generated');
  btnSave.Enabled := True;
  btnGen.Enabled := true;
  StopButton.Enabled := false;
end;

procedure TviewMain.StopButtonClick(Sender: TObject);
begin
  mLog.Lines.Add('STOPPED');
  gtQRCodeGenFMX1.Stop;
  StopButton.Enabled := false;
  btnGen.Enabled := true;
end;

procedure TviewMain.SVGcheckboxChange(Sender: TObject);
begin
  if SVGcheckbox.IsChecked = true then
    gtQRCodeGenFMX1.MultiSelectFileFormat := gtQRCodeGenFMX1.MultiSelectFileFormat + [qrSVG]
  else
    gtQRCodeGenFMX1.MultiSelectFileFormat := gtQRCodeGenFMX1.MultiSelectFileFormat - [qrSVG];
end;

procedure TviewMain.BMPcheckboxChange(Sender: TObject);
begin
  if BMPcheckbox.IsChecked = true then
    gtQRCodeGenFMX1.MultiSelectFileFormat := gtQRCodeGenFMX1.MultiSelectFileFormat + [qrBMP]
  else
    gtQRCodeGenFMX1.MultiSelectFileFormat := gtQRCodeGenFMX1.MultiSelectFileFormat - [qrBMP];
end;

end.

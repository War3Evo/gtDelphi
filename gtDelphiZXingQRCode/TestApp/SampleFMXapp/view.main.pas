unit view.main;

interface

{

  There's no way with FMX (without a third-party library) that I can figure out how to save a stretched file without blurriness.

  Version 1.0

    - Problems with visualization of qrcode image, set DisableInterpolation := True on TImage control
}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox,
  FMX.Memo, FMX.Objects, FMX.EditBox, FMX.SpinBox, FMX.ListBox,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Memo.Types,
  gtQRCodeGenFMX, FMX.Layouts, Skia, Skia.FMX, FMX.Effects, FMX.Filter.Effects;


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
    procedure btnGenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
    procedure gtQRCodeGenFMX1ImageControlFinish(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure gtQRCodeGenFMX1GenerateAfter(Sender: TObject;
      const aQRCode: TBitmap);
    procedure gtQRCodeGenFMX1GenerateDuring(Sender: TObject;
      const aQRCode: TBitmap);
    procedure gtQRCodeGenFMX1GenerateBefore(Sender: TObject;
      const aQRCode: TBitmap);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  viewMain: TviewMain;
  myBitmap: TBitmap;
  //myImage: TImage;
  iCount: integer;
  iHeight, iWidth: integer;

implementation

{$R *.fmx}

{$DEFINE USE_SCANLINE}

procedure TviewMain.btnGenClick(Sender: TObject);
begin
    mLog.Lines.Clear;

  if trim(MemoData.Text) = '' then
    begin
      ShowMessage('Enter with QRCode data');
      MemoData.SetFocus;
      exit;
    end;
  btnSave.Enabled := False;
  With gtQRCodeGenFMX1 do
    begin
      Data := Trim(MemoData.Text);
      Encoding := TQRCodeEncoding(edtEncoding.Selected.Index);
      QuietZone := StrToIntDef(edtQZone.Text,4);
      GenerateQRCode;
    end;
end;

procedure TviewMain.btnSaveClick(Sender: TObject);
begin
  if not myBitmap.IsEmpty then
    begin
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

procedure TviewMain.FormDestroy(Sender: TObject);
begin
  myBitmap.Free;
end;

procedure TviewMain.FormShow(Sender: TObject);
begin
  myBitmap := TBitmap.Create;
end;

procedure TviewMain.gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
begin
  mLog.Lines.Add('An Error Occur: ' + Error);
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateAfter(Sender: TObject;
  const aQRCode: TBitmap);
//var rSrc: TRectF;
  //  rDest: TRectF;
begin
  //imgQRCode.Bitmap.Assign(aQRCode);

            myBitmap.Assign(aQRCode);

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

procedure TviewMain.gtQRCodeGenFMX1GenerateBefore(Sender: TObject;
  const aQRCode: TBitmap);
begin
            iCount := 0;

            iWidth := StrToInt(Trim(WidthEdit.Text));
            iHeight := StrToInt(Trim(HeightEdit.Text));

            imgQRCode.Height := iHeight;
            imgQRCode.Width := iWidth;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateDuring(Sender: TObject;
  const aQRCode: TBitmap);
          var rSrc: TRectF;
          var rDest: TRectF;
begin
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

  inc(iCount);
  label4.Text := iCount.ToString;
end;

procedure TviewMain.gtQRCodeGenFMX1ImageControlFinish(Sender: TObject);
begin
  mLog.Lines.Add('QRCode Generated');
  btnSave.Enabled := True;
end;

end.

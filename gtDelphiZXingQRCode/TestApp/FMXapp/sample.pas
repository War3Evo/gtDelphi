unit view.main;

// Suppose to be a visual application, but I'm still working on that part.  At least you have working code here.

interface

{
  Version 1.0

    - Problems with visualization of qrcode image, set DisableInterpolation := True on TImage control
    - Generated QRCode can be saved from JSiQRCodeGenFMX1.QRCode
}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox,
  FMX.Memo, FMX.Objects, FMX.EditBox, FMX.SpinBox, FMX.ListBox,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Memo.Types,
  gtQRCodeGenFMX;

type
  TviewMain = class(TForm)
    btnGen: TButton;
    edtData: TEdit;
    Label1: TLabel;
    grpConfig: TGroupBox;
    edtEncoding: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    edtQZone: TSpinBox;
    lblTime: TLabel;
    imgQRCode: TImage;
    mLog: TMemo;
    btnSave: TButton;
    SD: TSaveDialog;
    gtQRCodeGenFMX1: TgtQRCodeGenFMX;
    Label4: TLabel;
    procedure btnGenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
    procedure gtQRCodeGenFMX1ImageControlFinish(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure gtQRCodeGenFMX1GenerateAfter(Sender: TObject;
      const aQRCode: TBitmap);
    procedure gtQRCodeGenFMX1GenerateDuring(Sender: TObject;
      const aQRCode: TBitmap);
    procedure gtQRCodeGenFMX1GenerateBefore(Sender: TObject;
      const aQRCode: TBitmap);
  private

  public

  end;

var
  viewMain: TviewMain;
  myBitmap: TBitMap;
  iCount: integer;

implementation

{$R *.fmx}

procedure TviewMain.btnGenClick(Sender: TObject);
begin
    mLog.Lines.Clear;

  if trim(edtData.Text) = '' then
    begin
      ShowMessage('Enter with QRCode data');
      edtData.SetFocus;
      exit;
    end;
  btnSave.Enabled := False;
  With gtQRCodeGenFMX1 do
    begin
      Data := Trim(edtData.Text);
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
          myBitmap.SaveToFile(SD.FileName);
        end;
    end;
end;

procedure TviewMain.FormCreate(Sender: TObject);
begin
  //myBitmap := TBitmap.Create;
end;

procedure TviewMain.FormDestroy(Sender: TObject);
begin
  //myBitmap.Free;
end;

procedure TviewMain.gtQRCodeGenFMX1Error(Sender: TObject; Error: string);
begin
  mLog.Lines.Add('An Error Occur: ' + Error);
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateAfter(Sender: TObject;
  const aQRCode: TBitmap);
begin
  //imgQRCode.Bitmap.Assign(aQRCode);
  myBitmap := aQRCode;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateBefore(Sender: TObject;
  const aQRCode: TBitmap);
begin
  iCount := 0;
end;

procedure TviewMain.gtQRCodeGenFMX1GenerateDuring(Sender: TObject;
  const aQRCode: TBitmap);
//          var rSrc: TRectF;
//          var rDest: TRectF;
begin
{          imgQRCode.DisableInterpolation := true;
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
            end;     }
  inc(iCount);
  label4.Text := iCount.ToString;
end;

procedure TviewMain.gtQRCodeGenFMX1ImageControlFinish(Sender: TObject);
begin
  mLog.Lines.Add('QRCode Generated');
  btnSave.Enabled := True;
end;

end.

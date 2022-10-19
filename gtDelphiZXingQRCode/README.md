gtDelphiZXingQRCode
=================

### Threaded version of DelphiZXingQRCode ###

10/19/2022

The Skia4Delphi version compiled application you can download from as gtQRCodeFMX_Skia Freeware

https://www.timmons.pro/opensource.php

10/09/2022

*** COLORing Pixels Work! ***

Many Thanks to Vinícius Felipe Botelho Barbosa of https://github.com/viniciusfbb for the help with developing SVG code that is compatible with Skia4Delphi

Use the SampleFMX.dproj in ./TestApp/SampleFMXapp for example code

* Added OnFillColor event -allows you to change the pixel colors as the QRcode is developed
- with OnFillColor, you can change the variables inside the event to change the colors
- OnFillColor also gives you the x,y cords
* Added MultiSelectFileFormat property - allows you to either generate SVG or BMP or both
* Changed OnImageControlFinish to OnGenerateFinally event
* Added UseInnerStyleSVG (default is true)
- Set to false for Skia4Delphi
* Added OnLoad
- OnLoad happens after OnCreate and all the default values are set

10/08/2022

** Added ability to generate SVG (needs external viewer to see SVG)

10/07/2022

**It's not multi-threaded, just threaded so your application can do other things while it's running in the background.**

You can control how much cpu cycles it is using by increase or decreasing the ThreadSleep integer of gtDelphiZXingQRCode component.  It is default of 40 ms.

**The FMX version works**

**Worked over 10 hours straight to get this threaded version of DelphiZXingQRCode working with all the bug fixes, updates, and errors reported on the original DelphiZXingQRCode page.**

I'll upload a full sample application later, for now I'll just upload a sample.pas.

gtDelphiZXingQRCode uses the code from DelphiZXingQRCode and combines all the pull requests for errors and bug fixes.  gtDelphiZXingQRCode also uses code from the JSiQRCodeGenerator fork for the VCL / FMX non-visual components.  JSiQRCodeGenerator did not have any updates and seemed to only convert the original to components.

# Getting Started #

A sample .pas is provided in the TestApp folder to demonstrate how to use gtDelphiZXingQRCode. 
Simply add or correct the FMX.DelphiZXIngQRCode.pas & gtQRCodeGenFMX.pas paths to the SampleFMX Delphi project and compile.

I'll update this later when I have a better sample project.

--------------------------------------------------

**The original code: https://github.com/foxitsoftware/DelphiZXingQRCode**

The original code hasn't been updated in 9 years and won't accept pull requests!

**From the original code's README.MD:**

DelphiZXingQRCode is a Delphi port of the QR Code functionality from ZXing, an open source 
barcode image processing library. The code was ported to Delphi by Senior Debenu Developer, 
Kevin Newman. The port retains the original Apache License (v2.0).

DelphiZXingQRCode Project

~~http://www.debenu.com/open-source/delphizxingqrcode-open-source-delphi-qr-code-generator/~~
**webpage no longer exists**

ZXing

https://github.com/zxing/zxing

[Provided by Debenu]

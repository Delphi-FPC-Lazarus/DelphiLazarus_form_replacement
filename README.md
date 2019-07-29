# DelphiLazarus_TFormReplacement
Replacement Class for TForm that enables you using vcl forms on lazarus without changes

## What it is 
Using that TFormHook instead of TForm you can cross compile our delphi applications with Lazarus on Ubuntu without changing forms.
If fixes several things like differences in fonts and visual-/non visual differences in componentes.

Usage

type
  TMainform = class({$IFDEF FPC}TFormHook{$ELSE}TForm{$ENDIF}
  
# You found the code useful? Donate!

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=DZUZXE2WCJU4U)


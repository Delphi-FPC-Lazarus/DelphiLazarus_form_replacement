{
  FormCreate Hook für FPC Anpassung

  xx/xxxx FPC Ubuntu

  --------------------------------------------------------------------
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY

  Author: Peter Lorenz
  Is that code useful for you? Donate!
  Paypal webmaster@peter-ebe.de
  --------------------------------------------------------------------

}

{$I ..\share_settings.inc}
unit FPC_Hook_unit;

interface

{$IFDEF FPC}

uses
  LCLIntf, LCLType, LMessages,
  LResources,
  Messages, SysUtils, Variants, Classes,
  Forms, Graphics, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Grids, Buttons;

type
  TPngImage = class(TPortableNetworkGraphic)
  protected
    procedure ReadData(Stream: TStream); override;
  end;

type
  TFormHook = class(TForm)
  private
    procedure FixStringGrid(Stringgrid: TStringGrid);
  public
    constructor Create(AOwner: TComponent); override;

    // iCWInterface
    function GetCaption: String;
  end;

resourcestring
  rsCaptionYes = '&Ja';
  rsCaptionNo = '&Nein';
  rsCaptionOK = '&OK';
  rsCaptionCancel = '&Abbrechen';
  rsCaptionAbort = '&Abbrechen';
  rsCaptionRetry = '&Wiederholen';
  rsCaptionIgnore = '&Ignorieren';
  rsCaptionAll = '&Alle';
  rsCaptionNoToAll = '&Nein Alle';
  rsCaptionYesToAll = '&Ja Alle';
  rsCaptionHelp = '&Hilfe';
  rsCaptionClose = '&Schließen';

{$ENDIF}

implementation

{$IFDEF FPC}

procedure TPngImage.ReadData(Stream: TStream);
var
  NewStream: TMemoryStream;
  iSize: Longint;
  iSizeWrite: Longint;
begin
  Stream.position := 0;

  // Streamaufbau korrigieren, <classnamelen><classname><streamlen><stream>
  // (delphi schreibt bei png TPNGImage als Classname und die stremlen nicht)
  NewStream := TMemoryStream.Create;
  try
    NewStream.CopyFrom(Stream, 1 + length(Self.classname));
    iSize := Stream.Size - Stream.position;
    iSizeWrite := NtoLE(iSize);
    NewStream.Write(iSizeWrite, sizeof(iSizeWrite));
    NewStream.CopyFrom(Stream, iSize);
    NewStream.position := 1 + length(Self.classname);
    inherited ReadData(NewStream);
  finally
    FreeAndNil(NewStream);
  end;
end;

procedure TFormHook.FixStringGrid(Stringgrid: TStringGrid);
var
  orgColCount, c: integer;
begin
  // FPC erlaubt nur das Schreiben der definierten Spaltenanzahl, manchmal sind aber mehr in Verwendung
  orgColCount := Stringgrid.ColCount;
  Stringgrid.ColCount := 10;
  for c := orgColCount to Stringgrid.ColCount - 1 do
    Stringgrid.ColWidths[c] := 0;

  // Focusrectangle (mouseover) ausblenden
  Stringgrid.FocusRectVisible := false;
end;

constructor TFormHook.Create(AOwner: TComponent);
{$IFDEF UNIX}
const
  ciGroupboxFixL_MC = 0;
  ciGroupboxFixT_MC = -12;
const
  ciGroupboxFixL_OC = 0;
  ciGroupboxFixT_OC = -4;
{$ELSE}
const
  ciGroupboxFixL_MC = 0;
  ciGroupboxFixT_MC = -12;
const
  ciGroupboxFixL_OC = 0;
  ciGroupboxFixT_OC = -12;
{$ENDIF}
var
  i, ti, li: integer;
  comp: TControl;
  bcaption: Boolean;
begin
  inherited Create(AOwner);

  if (csDesigning in ComponentState) then
    exit;

  ti := 0;
  li := 0;
  comp := nil;
  try

    for i := 0 to ComponentCount - 1 do
    begin
      if components[i] is TControl then
      begin
        comp := TControl(components[i]);

        // Offsetkorrektur für Groupboxes
        if (comp.Parent is TGroupBox) then
        begin
          // Achtung, Offset abhängig davon, ob die groupbox eine caption hat
          // kann auch negativ werden bei FPC ist die 0 Poisition innerhalb der Groupox sehr tief
          bcaption := TGroupBox(comp.Parent).caption <> '';
          if bcaption then
          begin
            ti := ciGroupboxFixT_MC;
            li := ciGroupboxFixL_MC;
          end
          else
          begin
            ti := ciGroupboxFixT_OC;
            li := ciGroupboxFixL_OC;
          end;

          comp.Left := comp.Left + li;
          comp.Top := comp.Top + ti;
        end;

        // Stringgrid colcount korrektur, unter FPC sind nur so viele Spalten vorhanden wie konfiguriert sind
        if comp is TStringGrid then
        begin
          FixStringGrid(TStringGrid(comp));
        end;

        // BitBtn Gylphs fix/entfernen weil sich die Defaults unterscheiden
        if comp is TBitBtn then
        begin
          // if TBitBtn(comp).NumGlyphs > 1 then
          // TBitBtn(comp).NumGlyphs:= 1;
          if TBitBtn(comp).Kind <> bkCustom then
            TBitBtn(comp).NumGlyphs := 1;
          // if Assigned(TBitBtn(comp).glyph) then
          // TBitBtn(comp).glyph:= nil;
        end;

        // BitBtn Korrektur weil Delphi bei den default Buttons nicht alle Properties mit rein schreibt
        if comp is TBitBtn then
        begin
          // Modalresult
          if TBitBtn(comp).Kind <> bkCustom then
          begin
            case TBitBtn(comp).Kind of
              bkOK:
                TBitBtn(comp).ModalResult := mrOK;
              bkCancel:
                TBitBtn(comp).ModalResult := mrCancel;
              // bkHelp:     TBitBtn(comp).ModalResult:= mr;
              bkYes:
                TBitBtn(comp).ModalResult := mrYes;
              bkNo:
                TBitBtn(comp).ModalResult := mrNo;
              bkClose:
                TBitBtn(comp).ModalResult := mrClose;
              bkAbort:
                TBitBtn(comp).ModalResult := mrAbort;
              bkRetry:
                TBitBtn(comp).ModalResult := mrRetry;
              bkIgnore:
                TBitBtn(comp).ModalResult := mrIgnore;
              bkAll:
                TBitBtn(comp).ModalResult := mrAll;
              bkNoToAll:
                TBitBtn(comp).ModalResult := mrNoToAll;
              bkYesToAll:
                TBitBtn(comp).ModalResult := mrYesToAll;
            end;
          end;

          // Default Caption (wenn keine andere angegeben ist)
          if (TBitBtn(comp).Kind <> bkCustom) and (TBitBtn(comp).caption = '') then
          begin
            // TBitBtn(comp).Caption:= GetButtonCaption(BitBtnImages[TBitBtn(comp).Kind]); immer englisch
            case TBitBtn(comp).Kind of
              bkOK:
                TBitBtn(comp).caption := rsCaptionOK;
              bkCancel:
                TBitBtn(comp).caption := rsCaptionCancel;
              // bkHelp:     TBitBtn(comp).Caption:= rsCaption;
              bkYes:
                TBitBtn(comp).caption := rsCaptionYes;
              bkNo:
                TBitBtn(comp).caption := rsCaptionNo;
              bkClose:
                TBitBtn(comp).caption := rsCaptionClose;
              bkAbort:
                TBitBtn(comp).caption := rsCaptionAbort;
              bkRetry:
                TBitBtn(comp).caption := rsCaptionRetry;
              bkIgnore:
                TBitBtn(comp).caption := rsCaptionIgnore;
              bkAll:
                TBitBtn(comp).caption := rsCaptionAll;
              bkNoToAll:
                TBitBtn(comp).caption := rsCaptionNoToAll;
              bkYesToAll:
                TBitBtn(comp).caption := rsCaptionYesToAll;
            end;
          end;
        end;

        // Trackbar Anzeige
        if comp is TTrackbar then
        begin
          TTrackbar(comp).ScalePos := trLeft;
        end;

        // Font (verschiedene Komponenten)
        if comp.Font.Size >= 10 then
        begin
          comp.Font.Size := comp.Font.Size - 1;
        end;

        // TLabel Prüfung (wordwrap und autosize)
        if comp is TLabel then
        begin
          // if (TLabel(comp).WordWrap) and (TLabel(comp).AutoSize) then
          // begin
          // end;
        end;

      end;
    end;

  except
    on e: exception do
    begin
      //
    end;
  end;

end;

function TFormHook.GetCaption: String;
begin
  Result := caption;
end;

procedure InitExcludeProperties;
begin
  // zusätzliche ExcludeProperties die nicht durch Lazarus/FPC Klassen selbst hinzugefügt werden
  PropertiesToSkip.Add(TForm, 'Padding', '', '');

  PropertiesToSkip.Add(TGroupBox, 'Padding', '', '');
  PropertiesToSkip.Add(TGroupBox, 'ParentBackground', '', '');

  PropertiesToSkip.Add(TPanel, 'Padding', '', '');
  PropertiesToSkip.Add(TPanel, 'ParentBackground', '', '');

  PropertiesToSkip.Add(TButton, 'Style', '', '');

end;

initialization

InitExcludeProperties;

RegisterClass(TPngImage);
TPicture.RegisterFileFormat('png', 'PNG Delphi Type', TPngImage);

{$ENDIF}

end.

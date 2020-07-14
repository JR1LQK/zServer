{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       François PIETTE
Description:  Demonstration for Server program using TWSocket.
EMail:        francois.piette@ping.be  http://www.rtfm.be/fpiette
              francois.piette@rtfm.be
Creation:     8 december 1997
Version:      1.00
WebSite:      http://www.rtfm.be/fpiette/indexuk.htm
Support:      Use the mailing list twsocket@rtfm.be See website for details.
Legal issues: Copyright (C) 1997 by François PIETTE <francois.piette@ping.be>

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

Updates:


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit UCliForm;

interface

uses
  WinTypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, WSocket, StdCtrls, ExtCtrls, zLogGlobal;

const LBCODE = #13{+#10};

type
  TCliForm = class(TForm)
    CliSocket: TWSocket;
    Panel1: TPanel;
    SendEdit: TEdit;
    SendButton: TButton;
    Panel2: TPanel;
    DisconnectButton: TButton;
    ListBox: TListBox;
    Button1: TButton;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CliSocketDataAvailable(Sender: TObject; Error: Word);
    procedure CliSocketSessionClosed(Sender: TObject; Error: Word);
    procedure SendButtonClick(Sender: TObject);
    procedure DisconnectButtonClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    Initialized : Boolean;
    //Buffer : array [0..1023] of char;
    //Count  : Integer;
    LineBuffer : TStringList;
    CommTemp : string; //work string for parsing LineBuffer
  public
    ClientNumber : Integer;
    Bands : array[b19..HiBand] of boolean;
    CurrentBand : TBand;
    CurrentOperator : string;
    procedure ParseLineBuffer;
    procedure SendStr(str : string);
    procedure SetCaption;
    procedure AddConsole(S : string);
  end;

var
  CliForm: TCliForm;

implementation

uses UServerForm;

{$R *.DFM}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF VER80}


procedure SetLength(var S: string; NewLength: Integer);
begin
    S[0] := chr(NewLength);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TrimRight(Str : String) : String;
var
    i : Integer;
begin
    i := Length(Str);
    while (i > 0) and (Str[i] = ' ') do
        i := i - 1;
    Result := Copy(Str, 1, i);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TrimLeft(Str : String) : String;
var
    i : Integer;
begin
    if Str[1] <> ' ' then
        Result := Str
    else begin
        i := 1;
        while (i <= Length(Str)) and (Str[i] = ' ') do
            i := i + 1;
        Result := Copy(Str, i, Length(Str) - i + 1);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function Trim(Str : String) : String;
begin
    Result := TrimLeft(TrimRight(Str));
end;
{$ENDIF}


procedure TCliForm.AddConsole(S : string);
var _VisRows : integer;
    _TopRow : integer;
begin
  ListBox.Items.Add(S);
  _VisRows := ListBox.ClientHeight div ListBox.ItemHeight;
  _TopRow := ListBox.Items.Count - _VisRows + 1;
  if _TopRow > 0 then
    ListBox.TopIndex := _TopRow
  else
    ListBox.TopIndex := 0;
end;

procedure TCliForm.SetCaption;
var S : string;
begin
  S := BandString[CurrentBand];
  if CurrentOperator <> '' then
    S := S + ' by ' + CurrentOperator;
  Caption := S;
end;

procedure TCliForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;


procedure TCliForm.SendStr(str : string);
begin
  CliSocket.SendStr(str);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.FormShow(Sender: TObject);
var B : TBand;
begin
    if not Initialized then begin
        Initialized   := TRUE;
        //DisplayMemo.Clear;
        SendEdit.Text := '';
        ActiveControl := SendEdit;
        LineBuffer := TStringList.Create;
        CurrentBand := b35;
        CurrentOperator := '';
        for B := b19 to HiBand do
          Bands[B] := False;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  LineBuffer.Clear;
  LineBuffer.Free;
  PostMessage(TForm(Owner).Handle, WM_USER, 0, LongInt(Self));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.ParseLineBuffer;
var max , i, j, x : integer;
    str: string;
begin
  max := LineBuffer.Count - 1;
  if max < 0 then exit;
  for i := 0 to max do
    begin
      str := LineBuffer.Strings[0];
      for j := 1 to length(str) do
        begin
          if str[j] = Chr($0D) then
            begin
              x := Pos(ZLinkHeader, CommTemp);
              if x > 0 then
                begin
                  CommTemp := copy(CommTemp, x, 255);
                  ServerForm.CommandQue.Add(FillRight(IntToStr(ClientNumber), 3)+' '+CommTemp);
                end;
              CommTemp := '';
            end
          else
            CommTemp := CommTemp + str[j];
        end;
      LineBuffer.Delete(0);
    end;
end;
(*
procedure TCliForm.ParseLineBuffer;
var max , i, j, x : integer;
    str, work : string;
begin
  max := LineBuffer.Count - 1;
  if max < 0 then exit;
  for i := 0 to max do
    begin
      str := LineBuffer.Strings[0];
      for j := 1 to length(str) do
        begin
          if str[j] = Chr($0D) then
            begin
              x := Pos(ZLinkHeader, CommTemp);
              if x > 0 then
                begin
                  CommTemp := copy(CommTemp, x, 255);
                  ServerForm.CommandQue.Add(FillRight(IntToStr(ClientNumber), 3)+' '+CommTemp);
                end;
              CommTemp := '';
            end
          else
            CommTemp := CommTemp + str[j];
        end;
      LineBuffer.Delete(0);
    end;
end;
*)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.CliSocketDataAvailable(Sender: TObject; Error: Word);
var
    str : string;
begin
    str := CliSocket.ReceiveStr;
    if ServerForm.ChatOnly = False then
      AddConsole(str);

{    if ServerForm.Transparent then
      if str <> '' then
        begin
          ServerForm.SendAllButFrom(str, ClientNumber);
          exit;
        end;     }

    LineBuffer.Add(str);

    ParseLineBuffer;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.CliSocketSessionClosed(Sender: TObject; Error: Word);
var temp : string;
begin
    temp := ZLinkHeader + ' PUTMESSAGE !'+MHzString[CurrentBand]+ ' MHz client disconnected from network.';
    temp := FillRight(IntToStr(ClientNumber), 3)+ ' ' + temp;
    ServerForm.ProcessCommand(temp);
    Close;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.SendButtonClick(Sender: TObject);
var S : string;
begin
    S := ZLinkHeader + ' PUTMESSAGE ZServer> '+SendEdit.Text + LBCODE;
    CliSocket.SendStr(S);
    S := 'ZServer> '+ SendEdit.Text + LBCODE;
    AddConsole(S);
    SendEdit.Clear;
    ActiveControl := SendEdit;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TCliForm.DisconnectButtonClick(Sender: TObject);
begin
    Close;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TCliForm.Button1Click(Sender: TObject);
begin
  Caption := 'Parsing...';
  ParseLineBuffer;
  Caption := 'Done!';
end;

end.


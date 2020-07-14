unit UALLJAMultiForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UBasicMultiForm, zLogGlobal, StdCtrls, checklst, ExtCtrls, ComCtrls;

type
  TKen = (m101,m102,m103,m104,m105,m106,m107,m108,
  m109,m110,m111,m112,m113,m114,
  m02,m03,m04,m05,m06,m07,m08,m09,m10,m11,
  m12,m13,m14,m15,m16,m17,m18,m19,m20,m21,
  m22,m23,m24,m25,m26,m27,m28,m29,m30,m31,
  m32,m33,m34,m35,m36,m37,m38,m39,m40,m41,
  m42,m43,m44,m45,m46,m47,m48,m49,m50);

  TALLJAMultiForm = class(TBasicMultiForm)
    TabControl: TTabControl;
    CheckListBox: TCheckListBox;
    ListBox: TListBox;
    Panel1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure CheckListBoxClickCheck(Sender: TObject);
  private
    { Private declarations }
    MultiArray : array[b19..HiBand, m101..m50] of boolean;
  public
    { Public declarations }
    procedure ResetBand(B : TBand); override;
    procedure Reset; override;
    procedure Add(aQSO : TQSO); override;
    procedure UpdateCheckListBox;
    procedure UpdateListBox;
    //procedure RecalcBand(B : TBand); override;
    procedure RecalcAll; override;
  end;

const KenNames : array[m101..m50] of string[15] =
('101 �@�J','102 ���G','103 ���','104 �ԑ�','105 ��m','106 �Ύ�','107 ����',
 '108 ��u','109 �\��','110 ���H','111 ����','112 �_�U','113 �O�R','114 �n��',
 '02  �X','03  ���','04  �H�c','05  �R�`','06  �{��','07  ����','08  �V��',
 '09  ����','10  ����','11  �_�ސ�','12  ��t','13  ���','14  ���','15  �Ȗ�',
 '16  �Q�n','17  �R��','18  �É�','19  ��','20  ���m','21  �O�d','22  ���s',
 '23  ����','24  �ޗ�','25  ���','26  �a�̎R','27  ����','28  �x�R','29  ����',
 '30  �ΐ�','31  ���R','32  ����','33  �R��','34  ����','35  �L��','36  ����',
 '37  ����','38  ���Q','39  ���m','40  ����','41  ����','42  ����','43  �F�{',
 '44  �啪','45  �{��','46  ������','47  ����','48  ���}��','49  ���m����',
 '50  �쒹��');

var
  ALLJAMultiForm: TALLJAMultiForm;

implementation

uses UServerForm;

{$R *.DFM}

{procedure TALLJAMultiForm.RecalcBand(B : TBand);
var Log : TQSOList;
    i : integer;
    aQSO : TQSO;
begin
  if NotWARC(B) and (B in [b35..b50]) = False then
    exit;
  Log := ServerForm.Stats.Logs[B];
  ResetBand(B);
  aQSO := TQSO.Create;
  for i := 1 to Log.TotalQSO do
    begin
      aQSO.QSO := TQSO(Log.List[i]).QSO;
      Add(aQSO);
      TQSO(Log.List[i]).QSO := aQSO.QSO;
    end;
  aQSO.Free;
end; }

procedure TALLJAMultiForm.RecalcAll;
var i : integer;
    aQSO : TQSO;
begin
  Reset;
  for i := 1 to ServerForm.Stats.MasterLog.TotalQSO do
    begin
      aQSO := TQSO(ServerForm.Stats.MasterLog.List[i]);
      Add(aQSO);
    end;
end;

procedure TALLJAMultiForm.UpdateListBox;
var K : TKen;
    BB : TBand;
    str : string;
begin
  ListBox.Clear;
  for K := m101 to m50 do
    begin
      str := '';
      for BB := b35 to b50 do
        if NotWARC(BB) then
          begin
            if MultiArray[BB, K] then
              str := str + '* '
            else
              str := str + '. ';
          end;
      str := FillRight(KenNames[K], 16) + str;
      ListBox.Items.Add(str);
    end;
end;

procedure TALLJAMultiForm.ResetBand(B : TBand);
var K : TKen;
begin
  for K := m101 to m50 do
    MultiArray[B, K] := False;
  UpdateCheckListBox;
  UpdateListBox;
end;

procedure TALLJAMultiForm.Reset;
var B : TBand;
    K : TKen;
    str : string;
begin
  for B := b19 to HiBand do
    for K := m101 to m50 do
      MultiArray[B, K] := False;
  ListBox.Clear;
  for K := m101 to m50 do
    begin
      str := FillRight(KenNames[K], 16)+'. . . . . .';
      ListBox.Items.Add(str);
    end;
  Update;
end;


procedure TALLJAMultiForm.Add(aQSO : TQSO);
var M : TKen;
    str : string;
    I : integer;
    B : TBand;
begin

  if aQSO.QSO.Dupe then
    exit;

  str := aQSO.QSO.NrRcvd;
  Delete(str, length(str), 1); // delete the last char

  //aQSO.QSO.NewMulti1 := False;
  try
    I := StrToInt(str);
  except
    on EConvertError do
      exit;
  end;

  case I of
    101..114 : M := TKen(I-101);
    2..50 :    M := TKen(I - 2 + ord(m02));
  else
    exit;
  end;

  if MultiArray[aQSO.QSO.Band, M] = False then
    begin
      MultiArray[aQSO.QSO.Band, M] := True;
      //aQSO.QSO.NewMulti1 := True;
      str := '';
      for B := b35 to b50 do
        if NotWARC(B) then
          begin
            if MultiArray[B, M] then
              str := str + '* '
            else
              str := str + '. ';
          end;
      str := FillRight(KenNames[M], 16) + str;
      ListBox.Items.Delete(Ord(M));
      ListBox.Items.Insert(Ord(M), str);
      UpdateCheckListBox;
    end;
end;

procedure TALLJAMultiForm.UpdateCheckListBox;
var B : TBand;
    K : TKen;
begin
  if TabControl.TabIndex = 6 then
    begin
    end
  else
    begin
      B := b19;
      case TabControl.TabIndex of
        0 : B := b35;
        1 : B := b7;
        2 : B := b14;
        3 : B := b21;
        4 : B := b28;
        5 : B := b50;
      end;
      for K := m101 to m50 do
        CheckListBox.Checked[ord(K)] := MultiArray[B, K];
    end;
end;

procedure TALLJAMultiForm.FormCreate(Sender: TObject);
var K : TKen;
begin
  inherited;
  TabControl.TabIndex := 6;
  ListBox.Visible := True;
  CheckListBox.Visible := False;
  ListBox.Align := alClient;
  CheckListBox.Align := alNone;
  for K := m101 to m50 do
    begin
      CheckListBox.Items.Add(KenNames[K]);
    end;
  Reset;
end;

procedure TALLJAMultiForm.TabControlChange(Sender: TObject);
begin
  inherited;
  if TabControl.TabIndex = 6 then
    begin
      CheckListBox.Align := alNone;
      CheckListBox.Visible := False;
      ListBox.Align := alClient;
      ListBox.Visible := True;
    end
  else
    begin
      ListBox.Align := alNone;
      ListBox.Visible := False;
      CheckListBox.Align := alClient;
      CheckListBox.Visible := True;
      UpdateCheckListBox;
    end;
end;

procedure TALLJAMultiForm.CheckListBoxClickCheck(Sender: TObject);
begin
  inherited;
  UpdateCheckListBox;
end;

end.

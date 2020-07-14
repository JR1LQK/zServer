unit UGraph;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  zLogGlobal, ExtCtrls, StdCtrls, Buttons, wsaGraph;

type THourlyData = class
       BeginHour : TDateTime;
       QSOs : array[b19..HiBand] of integer;
       constructor Create(BH : TDateTime);
       function TotalQSOs : integer;
       procedure Reset;
     end;

type
  TGraph = class(TForm)
    Panel1: TPanel;
    G: TwsaGraph;
    BitBtn1: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private

    { Private declarations }
    HourlyDataList : TList;
  public
    procedure AddQSO(aQSO : TQSO);
    procedure AnalyzeLog;
    procedure UpdateGraph;
    { Public declarations }
  end;

var
  Graph: TGraph;

implementation

uses UServerForm;

{$R *.DFM}

constructor THourlyData.Create(BH : TDateTime);
begin
  BeginHour := BH;
  Reset;
end;

procedure THourlyData.Reset;
var b : TBand;
begin
  for b := b19 to HiBand do
    QSOs[b] := 0;
end;

function THourlyData.TotalQSOs;
var TQ : integer;
    b : TBand;
begin
  TQ := 0;
  for b := b19 to HiBand do
    TQ := TQ + QSOs[b];
  Result := TQ;
end;

procedure TGraph.FormCreate(Sender: TObject);
begin
  HourlyDataList := TList.Create;
end;

procedure TGraph.AddQSO(aQSO : TQSO);
var i : integer;
    HD : THourlyData;
    T : TDateTime;
    H, M, S, MS : word;
begin
  for i := 0 to HourlyDataList.Count - 1 do
    begin
      HD := THourlyData(HourlyDataList[i]);
      if (aQSO.QSO.Time >= HD.BeginHour) and (aQSO.QSO.Time < HD.BeginHour + 1/24.0) then
        begin
          inc(HD.QSOs[aQSO.QSO.Band]);
          exit;
        end;
    end;
  DecodeTime(aQSO.QSO.Time, H, M, S, MS);
  T := Int(aQSO.QSO.Time)+EncodeTime(H, 0, 0, 0);
  HD := THourlyData.Create(T);
  inc(HD.QSOs[aQSO.QSO.Band]);
  for i := 0 to HourlyDataList.Count - 1 do
    if THourlyData(HourlyDataList[i]).BeginHour > HD.BeginHour then
      begin
        HourlyDataList.Insert(i, HD);
        exit;
      end;
  HourlyDataList.Add(HD);
end;

procedure TGraph.AnalyzeLog;
var i : integer;
begin
  for i := 0 to HourlyDataList.Count - 1 do
    THourlyData(HourlyDataList[i]).Reset;
  for i := 1 to ServerForm.Stats.MasterLog.TotalQSO do
    AddQSO(TQSO(ServerForm.Stats.MasterLog.List[i]));
  UpdateGraph;
end;

procedure TGraph.UpdateGraph;
var i : integer;
    HD : THourlyData;
begin
  if (Graph.Visible = false) or (HourlyDataList.Count = 0) then
    exit;

  G.ClearGraph;

  for i := 0 to HourlyDataList.Count - 1 do
    begin
      HD := THourlyData(HourlyDataList[i]);
      G.AddData(i, HD.TotalQSOs, IntToStr(GetHour(HD.BeginHour)));
    end;

  if HourlyDataList.Count > 0 then
    G.PlotGraph;
end;

procedure TGraph.FormShow(Sender: TObject);
begin
  UpdateGraph;
end;

procedure TGraph.BitBtn1Click(Sender: TObject);
begin
  AnalyzeLog;
  UpdateGraph;
end;

procedure TGraph.FormResize(Sender: TObject);
begin
  G.Align := alClient;
  //G.Width := Graph.ClientWidth;
  //G.Height := Graph.ClientHeight - Panel1.Height;
  if HourlyDataList.Count > 0 then
    G.PlotGraph;
end;

end.

unit UBasicStats;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  zLogGlobal, Grids, Cologrid;

type
  TBandSet = set of TBand;

  TBandSummary = record
    qso : integer;
    points : integer;
    multi1 : integer;
    multi2 : integer;
    cwqso : integer;
    noncwqso : integer;
  end;

  TBasicStats = class(TForm)
    Grid: TMgrid;
    procedure FormCreate(Sender: TObject);
    procedure GridSetting(ARow, Acol: Integer; var Fcolor: Integer;
      var Bold, Italic, underline: Boolean);
    procedure CreateParams(var Params: TCreateParams); override;
  private
    { Private declarations }
  public
    StatSummary : array[b19..b10g] of TBandSummary;
    UsedBands : array[b19..b10g] of boolean;
    Saved : Boolean;
    MasterLog : TQSOList;
    //Logs : array[b19..HiBand] of TQSOList;
    procedure InitStatSummary;
    procedure UpdateStatSummary;
    procedure Add(aQSO : TQSO);
    procedure AddNoUpdate(aQSO : TQSO);
    procedure Delete(aQSO : TQSO);
    //procedure ClearBand(B : TBand);
    procedure ClearAll;
    procedure UpdateStats; virtual; abstract;
    procedure SaveLogs(Filename : string);
    procedure InitGrid(LBand, HBand : TBand); virtual;
    procedure LoadFile(FileName : string); // resets current log and loads from file
    procedure MergeFile(FileName : string; BandSet : TBandSet); // will only update if band is in BandSet
    { Public declarations }
  end;

var
  BasicStats: TBasicStats;
  CurrentFileName : string;

implementation

uses UServerForm;

{$R *.DFM}

procedure TBasicStats.InitStatSummary;
var b : TBand;
begin
  for b := b19 to b10g do
    begin
      StatSummary[b].qso := 0;
      StatSummary[b].points := 0;
      StatSummary[b].multi1 := 0;
      StatSummary[b].multi2 := 0;
      StatSummary[b].cwqso := 0;
      StatSummary[b].noncwqso := 0;
    end;
end;

procedure TBasicStats.UpdateStatSummary;
var aQSO : TQSO;
    B : TBand;
    i : integer;
begin
  InitStatSummary;
  for i := 1 to MasterLog.TotalQSO do
    begin
      aQSO := TQSO(MasterLog.List[i]);
      B := aQSO.QSO.Band;
      inc(StatSummary[B].qso);
      inc(StatSummary[B].points, aQSO.QSO.points);
      if aQSO.QSO.NewMulti1 then
        inc(StatSummary[B].multi1);
      if aQSO.QSO.NewMulti2 then
        inc(StatSummary[B].multi2);
      if aQSO.QSO.Mode = mCW then
        inc(StatSummary[B].cwqso)
      else
        inc(StatSummary[B].noncwqso);
    end;
end;

procedure TBasicStats.InitGrid(LBand, HBand : TBand);
var i : integer;
    B : TBand;
begin
  with Grid do
    begin
      i := 0;
      for B := LBand to HBand do
        if NotWARC(B) then
          inc(i);
      i := i + 3;
      RowCount := i;

      ColCount := 6;
      Cells[0,0] := 'MHz';
      Cells[1,0] := 'QSOs';
      Cells[2,0] := 'Mult';
      Cells[3,0] := 'CW';
      Cells[4,0] := 'Ph';
      Cells[5,0] := 'CW%';

      i := 1;
      for B := LBand to HBand do
        if NotWARC(B) then
          begin
            Cells[0,i] := MHzString[B];
            inc(i);
          end;
      Cells[0,i] := 'Total';
      Cells[0,i+1] := 'Score';
      Height := DefaultRowHeight*RowCount + 2;
      Width := DefaultColWidth*ColCount + 2;
    end;
end;

procedure TBasicStats.SaveLogs(Filename : string);
var f : file of TQSOdata;
    D : TQSOData;
    i : word;
    back : string;
begin
  back := filename;
  back := copy(back,1,length(back)-4) + '.BAK'; // change the extension
  if FileExists(back) then
    DeleteFile(back);
  RenameFile(filename, back);
  System.assign(f, Filename);
  rewrite(f);
  D.memo := 'ZServer';
  write(f,D);

  MasterLog.SortByTime;
  ServerForm.MultiForm.RecalcAll;

  for i := 1 to MasterLog.TotalQSO do
    write(f, TQSO(MasterLog.List[i]).QSO);

  System.close(f);
  Saved := True;
end;

procedure TBasicStats.AddNoUpdate(aQSO : TQSO);
begin
  MasterLog.Add(aQSO);
  Saved := False;
end;

procedure TBasicStats.Add(aQSO : TQSO);
begin
  MasterLog.Add(aQSO);
  UpdateStats;
  Saved := False;
end;

procedure TBasicStats.Delete(aQSO : TQSO);
begin
  aQSO.QSO.Reserve := actDelete;
  MasterLog.AddQue(aQSO);
  MasterLog.ProcessQue;
  UpdateStats;
  Saved := False;
end;

procedure TBasicStats.ClearAll;
begin
  MasterLog.Clear;
end;

procedure TBasicStats.LoadFile(FileName : string);
var f : file of TQSOdata;
    D : TQSOData;
    Q : TQSO;
begin
  if FileExists(FileName) = False then
    exit;
  System.assign(f, Filename);
  reset(f);
  ClearAll;
  ServerForm.MultiForm.Reset;
  Q := TQSO.Create;
  read(f, D);
  while not(eof(f)) do
    begin
      read(f, D);
      Q.QSO := D;
      MasterLog.Add(Q);
      ServerForm.MultiForm.Add(Q);
    end;
  Q.Free;
  UpdateStats;
  ServerForm.CommandQue.Add('999 '+ZLinkHeader+ ' FILELOADED');
end;

procedure TBasicStats.MergeFile(FileName : string; BandSet : TBandSet);
begin
{
  if FileExists(FileName) = False then
    exit;
  System.assign(f, Filename);
  reset(f);
  for B := b19 to HiBand do
    if B in BandSet then
      ClearBand(B);
  Q := TQSO.Create;
  read(f, D);
  while not(eof(f)) do
    begin
      read(f, D);
      Q.QSO := D;
      if D.Band in BandSet then
        begin
          Logs[D.Band].Add(Q);
          //ServerForm.MultiForm.Add(Q);
        end;
    end;
  for B := b19 to HiBand do
    Logs[B].SortByTime;
  Q.Free;
  UpdateStats;
  ServerForm.MultiForm.RecalcAll;
  ServerForm.CommandQue.Add('999 '+ZLinkHeader+ ' FILELOADED');
}
end;

procedure TBasicStats.FormCreate(Sender: TObject);
var B : TBand;
begin
  Saved := True;
  CurrentFileName := '';
  MasterLog := TQSOList.Create('Z-Server');
  for B := b19 to HiBand do
    begin
      UsedBands[B] := False;
    end;
end;


procedure TBasicStats.GridSetting(ARow, Acol: Integer; var Fcolor: Integer;
  var Bold, Italic, underline: Boolean);
begin
  if ARow = 0 then
    begin
      FColor := clGreen;
      exit;
    end;
  if ACol = 0 then
    begin
      if ARow < Grid.RowCount - 2 then
        FColor := clBlue
      else
        FColor := clNavy;
      exit;
    end;
  FColor := clBlack;
end;

procedure TBasicStats.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

end.

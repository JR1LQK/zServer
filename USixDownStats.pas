unit USixDownStats;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UBasicStats, Grids, Cologrid, zLogGlobal;

type
  TSixDownStats = class(TBasicStats)
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    LowBand, HighBand : TBand;
    procedure InitGrid(LBand, HBand : TBand); override;
    procedure UpdateStats; override;
  end;

var
  SixDownStats: TSixDownStats;

implementation

{$R *.DFM}

procedure TSixDownStats.UpdateStats;
var i, _totalqso, _totalmulti, _totalpoints,  _totalcw, _totalph : integer;
    temp : string;
    B : TBand;
    R : double;
begin
  _totalqso := 0; _totalmulti := 0; _totalpoints := 0; _totalcw := 0; _totalph := 0;
  i := 1;
  UpdateStatSummary;
  for B := LowBand to HighBand do
    begin
      if NotWARC(B) then
        begin
          Grid.Cells[1,i] := IntToStr(StatSummary[B].qso);
          Grid.Cells[2,i] := IntToStr(StatSummary[B].points);
          Grid.Cells[3,i] := IntToStr(StatSummary[B].multi1);
          Grid.Cells[4,i] := IntToStr(StatSummary[B].cwqso);
          Grid.Cells[5,i] := IntToStr(StatSummary[B].noncwqso);
          if  StatSummary[B].qso = 0 then
            R := 0
          else
            R := 100.0*(StatSummary[B].cwqso)/(StatSummary[B].qso);
          Str(R : 3:1, temp);
          Grid.Cells[6,i] := temp;
          inc(_totalqso, StatSummary[B].qso);
          inc(_totalpoints, StatSummary[B].points);
          inc(_totalmulti, StatSummary[B].multi1);
          inc(_totalcw, StatSummary[B].cwqso);
          inc(_totalph, StatSummary[B].noncwqso);
          inc(i);
        end;
    end;
  Grid.Cells[1,i] := IntToStr(_totalqso);
  Grid.Cells[2,i] := IntToStr(_totalpoints);
  Grid.Cells[3,i] := IntToStr(_totalmulti);
  Grid.Cells[4,i] := IntToStr(_totalcw);
  Grid.Cells[5,i] := IntToStr(_totalph);
  if _totalqso = 0 then
    R := 0
  else
    R := 100 * _totalcw / _totalqso;
  Str(R : 3: 1, temp);
  Grid.Cells[6,i] := temp;
  Grid.Cells[3,i+1] := IntToStr(_totalpoints*_totalmulti);
end;

procedure TSixDownStats.InitGrid(LBand, HBand : TBand);
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

      ColCount := 7;
      Cells[0,0] := 'MHz';
      Cells[1,0] := 'QSOs';
      Cells[2,0] := 'Points';
      Cells[3,0] := 'Mult';
      Cells[4,0] := 'CW';
      Cells[5,0] := 'Ph';
      Cells[6,0] := 'CW%';

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

procedure TSixDownStats.FormCreate(Sender: TObject);
begin
  inherited;
  LowBand := b50;
  HighBand := HiBand;
  InitGrid(LowBand, HighBand);
  UpdateStats;
  UsedBands[b50] := True;
  UsedBands[b144] := True;
  UsedBands[b430] := True;
  UsedBands[b1200] := True;
  UsedBands[b2400] := True;
  UsedBands[b5600] := True;
  UsedBands[b10g] := True;
end;

end.

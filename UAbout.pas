unit UAbout;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    label1: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    OKButton: TButton;
    Label2: TLabel;
    procedure OKButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

uses UServerForm;

{$R *.DFM}

procedure TAboutBox.OKButtonClick(Sender: TObject);
begin
  Close;
end;


procedure TAboutBox.FormCreate(Sender: TObject);
begin
  Label1.Caption := UServerForm.VersionString;
end;

end.


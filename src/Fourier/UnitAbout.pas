unit UnitAbout;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, jpeg;

type
  TAboutDlg = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutDlg: TAboutDlg;

implementation

{$R *.dfm}

end.

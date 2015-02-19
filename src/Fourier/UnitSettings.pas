unit UnitSettings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms,
  Dialogs, Grids, StdCtrls, ExtCtrls, ComCtrls,UnitMain,math,IniFiles,
  mmsystem;

type
  TForm2 = class(TMyForm)
    PageControl1: TPageControl;//страницы настроек
    TabSheet1: TTabSheet;   //страница 1
    TabSheet2: TTabSheet;  //страница 2
    Button1: TButton;    //
    Button2: TButton;    //
    Label2: TLabel;      //
    StringGrid1: TStringGrid; //
    GroupBox1: TGroupBox;    //
    Label13: TLabel;       //
    Label14: TLabel;      //
    Bevel2: TBevel;        //
    GroupBox2: TGroupBox;   //
    Label15: TLabel;      //
    GroupBox3: TGroupBox;  //
    Label9: TLabel;       //
    Bevel1: TBevel;       //
    Label1: TLabel;       //
    Button3: TButton;      //
    Button4: TButton;      //
    TabSheet3: TTabSheet;  //
    ListBox1: TListBox;    //
    ListBox2: TListBox;    //
    Button5: TButton;      //
    Button6: TButton;      //
    Label3: TLabel;       //
    Label4: TLabel;        //
    ComboBox3: TComboBox;   //
    ComboBox4: TComboBox;   //
    ComboBox5: TComboBox;   //
    Button7: TButton;     //
    Label5: TLabel;      //

    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure TabSheet1Show(Sender: TObject);
    procedure update_lists;
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure TabSheet3Show(Sender: TObject);
    procedure Button7MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button7MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure ComboBox3Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    NeedUpdate:Boolean;
  end;

var
  Form2: TForm2;
  PlayingNote:integer=-1;
procedure LoadSettings(form:tmyform;settings:TMemIniFile);
procedure SaveSettings(form:tmyform;settings:TMemIniFile);

implementation
var list1,list2:array of byte;
{$R *.dfm}
procedure TForm2.update_lists;
var i:byte;
begin
  ListBox1.Items.Clear;
  ListBox2.Items.Clear;
  setlength(list1,0);
  setlength(list2,0);
  for i:=0 to 127 do
    if i in instr then begin
       setlength(list2,length(list2)+1);
       list2[high(list2)]:=i;
       ListBox2.Items.Add(instruments[i]);
    end else begin
       setlength(list1,length(list1)+1);
       list1[high(list1)]:=i;
       ListBox1.Items.Add(instruments[i]);
    end;
end;
procedure SaveDefSettings(form:tmyform;settings:TMemIniFile);
begin

  settings.WriteInteger('Default','cbxFFTCount',
      Form.cbxFFTCount.ItemIndex);
  settings.WriteInteger('Default','cbxTempo',
      Form.cbxTempo.ItemIndex);
  settings.WriteInteger('Default','rgWindowFuncs',
      Form.rgWindowFuncs.ItemIndex);
  settings.WriteInteger('Default','clbSpectum',
      Form.clbSpectum.Selected);
  settings.WriteInteger('Default','chkAutosave',
      integer(Form.chkAutosave.Checked));
  settings.WriteInteger('Default','cbxInstruments',
      Form.cbxInstruments.ItemIndex);
  settings.WriteInteger('Default','chkWaveform',
      integer(Form.chkWaveform.Checked));
  settings.WriteInteger('Default','clbWaveform',
      form.clbWaveform.Selected);
  try
  settings.WriteInteger('Default','edtWavPoints',strtoint(Form.edtWavPoints.Text));;
  except else
    MessageDlg('Неправильное количество точек!'+
                #13#10+'Значение проигнорировано.',mtWarning,[mbok],0);
  end;
  settings.WriteInteger('Default','chkListSpectr',
      integer(Form.chkListSpectr.Checked));
end;
procedure LoadDefSettings(form:tmyform;settings:TMemIniFile);
begin

  Form.cbxFFTCount.ItemIndex:=
    settings.ReadInteger('Default','cbxFFTCount',3);
  Form.cbxTempo.ItemIndex:=
    settings.ReadInteger('Default','cbxTempo',3);
  Form.rgWindowFuncs.ItemIndex:=
    settings.ReadInteger('Default','rgWindowFuncs',2);
  Form.clbSpectum.Selected:=
    settings.ReadInteger('Default','clbSpectum',clRed);
  Form.chkAutosave.Checked:=
    boolean(settings.ReadInteger('Default','chkAutosave',1));
  Form.cbxInstruments.ItemIndex:=
    settings.ReadInteger('Default','cbxInstruments',0);
  Form.chkWaveform.Checked:=
    boolean(settings.ReadInteger('Default','chkWaveform',1));
  form.clbWaveform.Selected:=
    settings.ReadInteger('Default','clbWaveform',clblue);
  Form.edtWavPoints.Text:=
    inttostr(settings.ReadInteger('Default','edtWavPoints',250));
  Form.chkListSpectr.Checked:=
    boolean(settings.ReadInteger('Default','chkListSpectr',1));

end;

procedure LoadFreqSettings(form:tmyform;settings:TMemIniFile);
var i:byte;
begin
  for i:=1 to 12 do
    form.notes_freq[i]:=settings.ReadFloat('Frequencies',notes_name[i],
                        default_freq[i]);
end;

procedure SaveFreqSettings(form:tmyform;settings:TMemIniFile);
var i:byte;
begin
  for i:=1 to 12 do
    settings.WriteFloat('Frequencies',notes_name[i],form.notes_freq[i]);
end;

procedure SaveInstrSettings(form:tmyform;settings:TMemIniFile);
type pinteger=^integer;
var i:byte; p:pinteger;
begin
p:=addr(form.instr);
for i:=1 to 4 do begin
   settings.WriteInteger('Instruments','Part'+inttostr(i),p^);
   inc(p);
end;
end;

procedure LoadInstrSettings(form:tmyform;settings:TMemIniFile);
type pinteger=^integer;
var i:byte; p:^integer;
begin
p:=addr(form.instr);
for i:=1 to 4 do begin
   p^:=settings.ReadInteger('Instruments','Part'+inttostr(i),-1);
   inc(p);
end;
end;

procedure LoadSettings(form:tmyform;settings:TMemIniFile);
begin
   LoadDefSettings(form,Settings);
   LoadFreqSettings(form,Settings);
   LoadInstrSettings(form,Settings);
end;
procedure SaveSettings(form:tmyform;settings:TMemIniFile);
begin
  SaveDefSettings(form,settings);
  SaveFreqSettings(form,settings);
  SaveInstrSettings(form,settings);
end;
procedure TForm2.Button3Click(Sender: TObject);
var settings:TMemIniFile;
begin
  settings:=TMemIniFile.Create('config.ini');
  case PageControl1.TabIndex of
  0:begin
    SaveDefSettings(form1,settings);
    LoadDefSettings(form2,settings);
    TabSheet1Show(TabSheet1);
  end;
  1: begin
    SaveFreqSettings(form1,settings);
    LoadFreqSettings(form2,settings);
    TabSheet2Show(TabSheet2);
  end;
  2:
  begin
    SaveInstrSettings(form1,settings);
    LoadInstrSettings(form2,settings);
    TabSheet3Show(TabSheet3);
  end;
  end;
  FreeAndNil(settings);

end;

procedure TForm2.Button4Click(Sender: TObject);
var settings:TMemIniFile;
begin
  settings:=TMemIniFile.Create('config.ini');
  case PageControl1.TabIndex of
  0:begin
    SaveDefSettings(form2,settings);
    LoadDefSettings(form1,settings);
    end;
  1: begin
    SaveFreqSettings(form2,settings);
    LoadFreqSettings(form1,settings);
  end;
  2: begin
    SaveInstrSettings(form2,settings);
    LoadInstrSettings(form1,settings);
  end;
  end;
  FreeAndNil(settings);
  self.NeedUpdate:=true;
end;

procedure TForm2.FormShow(Sender: TObject);
var settings:TMemIniFile;
begin
  instr:=[0];
  Self.NeedUpdate:=false;
  settings:=TMemIniFile.Create('config.ini');
  LoadSettings(form2,settings);
  TabSheet2Show(TabSheet2);
  TabSheet1Show(TabSheet1);
  TabSheet3Show(TabSheet3);
  FreeAndNil(settings);
  //midiStatus:=midiOutOpen(@MidiPort,MIDI_MAPPER,0,0,0);
end;

procedure TForm2.TabSheet2Show(Sender: TObject);
var i:byte; var canselect:boolean;
begin
 for i:=1 to 12 do begin
    StringGrid1.Cells[0,i-1]:=notes_name[i];
    StringGrid1.Cells[1,i-1]:=floattostr(notes_freq[i]);
 end;
  canselect:=true;
  StringGrid1SelectCell(StringGrid1,1,0,canselect);

end;

procedure TForm2.StringGrid1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
var i:shortint;
begin
  Label2.Caption:='';
  for i:=-4 to 5 do begin
    label2.Caption:=label2.Caption+
        rus_names[Arow+1]+' '+octaves[i+5]+'октавы: '+
          floattostr(strtofloat(StringGrid1.Cells[1,Arow])*power(2,i))+#13#10;
  end;
end;

procedure TForm2.Button1Click(Sender: TObject);
var settings:TMemIniFile;
begin
  //self.NeedUpdate:=true;
  settings:=TMemIniFile.Create('config.ini');
  SaveSettings(form2,settings);
  settings.UpdateFile;
  //LoadSettings(form1,settings);
  FreeAndNil(settings);

  Self.Close;
end;

procedure TForm2.Button2Click(Sender: TObject);
var settings:TMemIniFile;
begin
  settings:=TMemIniFile.Create('config.ini');
  LoadSettings(form2,settings);
  FreeAndNil(settings);
  Self.Close;
end;

procedure TForm2.FormCreate(Sender: TObject);
var settings:TMemIniFile; i:byte;
begin
  Self.NeedUpdate:=false;
  settings:=TMemIniFile.Create('config.ini');
  LoadSettings(form2,settings);
  FreeAndNil(settings);

  for i:=0 to 127 do
    ComboBox3.Items.Add(instruments[i]);
  ComboBox3.ItemIndex:=0;
  for i:=1 to 12 do
    ComboBox4.Items.Add(rus_names[i]);
  for i:=1 to 10 do
    ComboBox5.Items.Add(octaves[i]+'октавы');
  ComboBox4.ItemIndex:=0; ComboBox5.ItemIndex:=0;
end;


procedure TForm2.StringGrid1SetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
var temp:Double;  canselect:boolean;
begin
  try
    if value<>'' then begin
    temp:=strtofloat(Value);
    notes_freq[ARow+1]:=temp;
    canselect:=true;
    StringGrid1SelectCell(StringGrid1,acol,arow,canselect);
    end;
  except else
    ShowMessage('Ошибка!')
  end;
end;

procedure TForm2.TabSheet1Show(Sender: TObject);
begin
  update_instruments;
end;

procedure TForm2.Button5Click(Sender: TObject);
var i:shortint;
begin
  for i:=0 to ListBox1.Items.Count-1 do
    if ListBox1.Selected[i] then
      instr:=instr+[list1[i]];
  update_lists;
end;

procedure TForm2.Button6Click(Sender: TObject);
var i:shortint;
begin
  for i:=0 to ListBox2.Items.Count-1 do
    if ListBox2.Selected[i] then
      instr:=instr-[list2[i]];
  update_lists;
end;

procedure TForm2.TabSheet3Show(Sender: TObject);
begin
  update_lists;
end;

procedure TForm2.Button7MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var midimsg:record
        case Boolean of
         true:(bytes:array [1..4] of byte);
         false:(l:integer;)
        end;
begin
  if MidiStatus=MMSYSERR_NOERROR then begin
  PlayingNote:=ComboBox4.ItemIndex+ComboBox5.ItemIndex*12;
  Midimsg.bytes[1]:=$90;
  midimsg.bytes[2]:=PlayingNote;
  midimsg.bytes[3]:=127;
  midimsg.bytes[4]:=0;
  midiOutShortMsg (Form1.MIDIKeys.MIDIPort, midimsg.l);
end;
end;

procedure TForm2.Button7MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var midimsg:integer;
begin
  if PlayingNote<>-1 then begin
    midimsg:=$80+PlayingNote*$100;

    midiOutShortMsg(midiport,midimsg);
    PlayingNote:=-1;

  end;
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  midiOutClose(MidiPort);
  list1:=nil;
  list2:=nil;
  instr_indexes:=nil;
end;

procedure TForm2.ComboBox3Change(Sender: TObject);
var midimsg:integer;
begin
  if MidiStatus=MMSYSERR_NOERROR then begin
  Midimsg:=$C0 + (ComboBox3.ItemIndex *$100);
  midiOutShortMsg (midiport, midimsg);
  end;
end;

end.

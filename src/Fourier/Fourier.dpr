program Fourier;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {Form1},
  cmpBarControl in '..\MIDI_Controls\cmpBarControl.pas',
  cmpMidiData in '..\MIDI_Controls\cmpMidiData.pas',
  unitMidiGlobals in '..\MIDI_Controls\unitMidiGlobals.pas',
  unitMidiTrackStream in '..\MIDI_Controls\unitMidiTrackStream.pas',
  unitVirtualMemory in '..\MIDI_Controls\unitVirtualMemory.pas',
  cmpRiffStream in '..\MIDI_Controls\cmpriffStream.pas',
  cmpMidiIterator in '..\MIDI_Controls\cmpMidiIterator.pas',
  cmpTrackOutputs in '..\MIDI_Controls\cmpTrackOutputs.pas',
  cmpMidiOutput in '..\MIDI_Controls\cmpMidiOutput.pas',
  cmpInstrument in '..\MIDI_Controls\cmpInstrument.pas',
  cmpPianoRoll in '..\MIDI_Controls\cmpPianoRoll.pas',
  cmpKeyboard in '..\MIDI_Controls\cmpKeyboard.pas',
  ModuleWav in 'ModuleWAV.pas',
  UnitSettings in 'UnitSettings.pas' {Form2},
  UnitAbout in 'UnitAbout.pas' {AboutDlg};

{$R *.res}

begin
  Application.Initialize;
  Application.HelpFile := '..\doc\help\FOURIER.HLP';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TAboutDlg, AboutDlg);
  Application.Run;
end.

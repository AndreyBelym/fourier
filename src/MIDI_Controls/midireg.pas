unit midireg;

interface

procedure Register;

implementation

uses Classes, cmpMidiData, cmpPianoRoll, cmpMidiOutput,
     cmpTrackOutputs, cmpKeyboard;

procedure Register;
begin
  RegisterComponents('MIDI', [TMidiData, TPianoRoll, TMidiOutputPort,
                              TTrackOutputs, 
                              TKeys, TMidiKeys]);
end;


end.

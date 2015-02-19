unit cmpMidiIterator;

interface

uses classes, cmpMidiData, unitMidiGlobals, windows, cmpTrackOutputs;

type
TOnIterate = procedure (Sender : TObject; trackNo : Integer; const event : TEventData) of object;

TMidiPosition = class (TComponent)
  private
    fMidiData : TMidiData;
    fPosition, fTime : Integer;
    fPPQN : Integer;

    fTempo : Integer;
    fTempoPos, fTempoTime : Integer;

    fBeatDiv, fBeatsPerBar : Integer;
    fTimesigPos, fTimesigBar : Integer;

    fTicksPerBar, fTicksPerBeat : Integer;

    fBar, fBeat, fTick : Integer;
    fInputIndex : Integer;
    fTrack0Index : Integer;

    procedure SetMidiData (value : TMidiData);
    procedure CalcTickConstants;
    procedure AdjustPositionsForTimesig (delta_pos : Integer);
    function GetDuration : Integer;
    procedure CalcNewPosition (pos : Integer);
    function CalcLastNotePosition : Integer;

  protected
    procedure SkipToPosition; virtual;

  public
    constructor Create (AOwner : TComponent); override;
    procedure Assign (source : TPersistent); override;
    procedure Reset; virtual;
    procedure SetBarPosition (bar, beat, tick : Integer);
    procedure SetPosition (pos : Integer);
    procedure SetTime (value : Integer);
    procedure SetEndPosition;
    procedure SetLastNotePosition;
    procedure CalcPositionFromTime (tm : Integer);

    property MidiData : TMidiData read fMidiData write SetMidiData;

    property Bar : Integer read fBar;
    property Beat : Integer read fBeat;
    property Tick : Integer read fTick;
    property Position : Integer read fPosition write SetPosition;
    property Time : Integer read fTime write SetTime;

    property BeatDiv : Integer read fBeatDiv;
    property BeatsPerBar : Integer read fBeatsPerBar;
    property TicksPerBar : Integer read fTicksPerBar;
    property Tempo : Integer read fTempo;

    property Duration : Integer read GetDuration;
end;

TMidiIterator = class (TMidiPosition)
  protected
    fPlayNotes : boolean;
    fTrackOutputs : TTrackOutputs;
    fEndOfSong : boolean;
    procedure SkipToPosition; override;
    procedure SetTrackOutputs (value : TTrackOutputs);
  public
    procedure IterateByTime (delta_time : Integer);
    property TrackOutputs : TTrackOutputs read fTrackOutputs write SetTrackOutputs;
    procedure Reset; override;
    property EndOfSong : boolean read fEndOfSong;
end;

implementation

uses SysUtils, unitMidiTrackStream;

constructor TMidiPosition.Create (AOwner : TComponent);
begin
  inherited create (AOwner);
  Reset;
end;

procedure TMidiPosition.Assign (source : TPersistent);
var
  Another : TMidiPosition;
begin
  Another := source as TMidiPosition;
  fMidiData := Another.fMidiData;
  fPosition := Another.fPosition;
  fTime := Another.fTime;
  fPPQN := Another.fPPQN;

  fTempo := Another.fTempo;
  fTempoPos := Another.fTempoPos;
  fTempoTime := Another.fTempoTime;

  fBeatDiv := Another.fBeatDiv;
  fBeatsPerBar := Another.fBeatsPerBar;
  fTimesigPos := Another.fTimesigPos;
  fTimesigBar := Another.fTimesigBar;

  fTicksPerBar := Another.fTicksPerBar;
  fTicksPerBeat := Another.fTicksPerBeat;

  fBar := Another.fBar;
  fBeat := Another.fBeat;
  fTick := Another.fTick;
  fInputIndex := Another.fInputIndex;
  fTrack0Index := Another.fTrack0Index;
end;

procedure TMidiPosition.SetMidiData (value : TMidiData);
var
  oldPos : Integer;
begin
  if fMidiData <> value then
  begin
    fMidiData := value;
    oldPos := Position;
    Reset;
    SetPosition (oldPos)
  end
end;

procedure TMidiPosition.Reset;
begin
  if not Assigned (fMidiData) then fPPQN := 180 else fPPQN := fMidiData.PPQN;
  fPosition := 0;
  fTime := 0;
  fTempo := 600;
  fTempoPos := 0;
  fTempoTime := 0;
  fbeatDiv := 2;
  fBeatsPerBar := 4;
  fTimesigPos := 0;
  fTimesigBar := 0;
  fBar := 0;
  fBeat := 0;
  fTick := 0;
  fTrack0Index := 0;
  fInputIndex := 0;
  CalcTickConstants
end;

procedure TMidiPosition.CalcTickConstants;
begin
  if fBeatDiv > 2 then
    fTicksPerBeat := fPPQN shr (fBeatDiv - 2)
  else
    if fBeatDiv < 2 then
      fTicksPerBeat := fPPQN shl (2 - fBeatDiv)
    else
      fTicksPerBeat := fPPQN;
  fTicksPerBar := fTicksPerBeat * fBeatsPerBar;
end;

function GetTimesig (p : PMidiEventData; var newBeatsPerBar, newBeatDiv : Integer): boolean;
begin
  if (p^.data.status = $ff) and (p^.data.sysex [0] = #$58) then
  begin
    newBeatsPerBar := Integer (p^.data.sysex [1]);
    newBeatDiv := Integer (p^.data.sysex [2]);
    result := True
  end
  else result := False
end;

function GetTempo (p : PMidiEventData; var newTempo : Integer): boolean;
begin
  if (p^.data.status = $ff) and (p^.data.sysex [0] = #$51) then with p^.data do
  begin
    newTempo := (LongInt (sysex [3]) + 256 * LongInt (sysex [2]) + 65536 * LongInt (sysex [1])) div 1000;
    result := True
  end
  else result := False
end;

procedure TMidiPosition.AdjustPositionsForTimesig (delta_pos : Integer);
begin
  fPosition := fTimesigPos + delta_pos;
  fBeat := delta_pos div fTicksPerBeat;
  fTick := delta_pos mod fTicksPerBeat;
  fBar := fTimesigBar + fBeat div fBeatsPerBar;
  fBeat := fBeat mod fBeatsPerBar;
end;

procedure TMidiPosition.SkipToPosition;
begin
end;

procedure TMidiPosition.CalcNewPosition (pos : Integer);
var
  p : PMidiEventData;
  newBeatsperBar, newBeatDiv, newTempo : Integer;
  delta_b, deltaPos : Integer;
begin
  if pos < fPosition then
    Reset;

  DeltaPos := pos - fTimesigPos;
  if DeltaPos < 0 then Exit;
  if Assigned (fMidiData) then with fMidiData do
    if Assigned (Tracks [0]) then
      while fTrack0Index < Tracks [0].EventCount do
      begin
        p := Tracks [0].Event [fTrack0Index];
        if p^.pos > fTimesigPos + deltaPos then break;
        Inc (fTrack0Index);
        if GetTimesig (p, newBeatsPerBar, newBeatDiv) then
        begin
          delta_b := (p^.pos - fTimesigPos) div fTicksPerBar;
          Dec (deltaPos, (p^.pos - fTimesigPos));
          if ((p^.pos - fTimesigPos) mod fTicksPerBar) > 0 then Inc (delta_b);
          fTimesigPos := p^.pos;
          fTimesigBar := fTimesigBar + delta_b;
          fBeatDiv := newBeatDiv;
          fBeatsPerBar := newBeatsPerBar;
          CalcTickConstants;
        end
        else
          if GetTempo (p, newTempo) then
          begin
            fTempoTime := fTempoTime + ((p^.pos - fTempoPos) * fTempo) div fPPQN;
            fTempoPos := p^.pos;
            fTempo := newTempo
          end
      end;
  AdjustPositionsForTimesig (deltaPos);
  fTime := fTempoTime + ((fPosition - fTempoPos) * fTempo) div fPPQN;
end;

procedure TMidiPosition.SetPosition (pos : Integer);
begin
  CalcNewPosition (pos);
  SkipToPosition
end;

procedure TMidiPosition.CalcPositionFromTime (tm : Integer);
var
  p : PMidiEventData;
  delta_p, newTempo, newBeatsPerBar, newBeatDiv, delta_b : Integer;

begin
  if tm < fTime then
    Reset;
  fTime := tm;
  delta_p := ((fTime - fTempoTime) * fPPQN) div fTempo;
  if Assigned (fMidiData) then with fMidiData do
  begin
    if Assigned (Tracks [0]) then
    begin
      while fTrack0Index < Tracks [0].EventCount do
      begin
        p := Tracks [0].Event [fTrack0Index];
        if p^.pos > fTempoPos + delta_p then break;
        Inc (fTrack0Index);
        if GetTempo (p, newTempo) then
        begin
          fTempoTime := fTempoTime + ((p^.pos - fTempoPos) * fTempo) div ppqn;
          fTempoPos := p^.pos;
          fTempo := newTempo;
          delta_p := ((fTime - fTempoTime) * fPPQN) div fTempo;
        end
        else
          if GetTimesig (p, newBeatsPerBar, newBeatDiv) then
          begin
            delta_b := (p^.pos - fTimesigPos) div fTicksPerBar;
            if ((p^.pos - fTimesigPos) mod fTicksPerBar) > 0 then Inc (delta_b);
            fTimesigPos := p^.pos;
            fTimesigBar := fTimesigBar + delta_b;
            fBeatDiv := newBeatDiv;
            fBeatsPerBar := newBeatsPerBar;
            CalcTickConstants;
          end
      end;
    end;

    delta_p := (fTempoPos + delta_p)- fTimesigPos;
    AdjustPositionsForTimesig (delta_p);

  end   // With MidiData
end;

procedure TMidiPosition.SetTime (value : Integer);
begin
  CalcPositionFromTime (value);
  SkipToPosition
end;

procedure TMidiPosition.SetBarPosition (bar, beat, tick : Integer);
var
  p : PMidiEventData;
  newBeatsperBar, newBeatDiv, newTempo : Integer;
  deltaPos, delta_b : Integer;
begin
  if (bar < fBar) or ((bar = fBar) and (beat < fBeat)) or ((bar = fBar) and (beat = fBeat) and (tick < fTick)) then
    Reset;

  deltaPos := (bar - fTimesigBar) * fTicksPerBar + beat * fTicksPerBeat + Tick;
  if deltaPos < 0 then exit;

  if Assigned (fMidiData) then with fMidiData do
    if Assigned (Tracks [0]) then
      while fTrack0Index < Tracks [0].EventCount do
      begin
        p := Tracks [0].Event [fTrack0Index];
        if p^.pos > fTimesigPos + deltaPos then break;
        Inc (fTrack0Index);
        if GetTimesig (p, newBeatsPerBar, newBeatDiv) then
        begin
          delta_b := (p^.pos - fTimesigPos) div fTicksPerBar;
          if ((p^.pos - fTimesigPos) mod fTicksPerBar) > 0 then Inc (delta_b);
          fTimesigPos := p^.pos;
          fTimesigBar := fTimesigBar + delta_b;
          fBeatDiv := newBeatDiv;
          fBeatsPerBar := newBeatsPerBar;
          CalcTickConstants;
          deltaPos := (bar - fTimesigBar) * fTicksPerBar + beat * fTicksPerBeat + Tick
        end
        else
          if GetTempo (p, newTempo) then
          begin
            fTempoTime := fTempoTime + ((p^.pos - fTempoPos) * fTempo) div fPPQN;
            fTempoPos := p^.pos;
            fTempo := newTempo
          end
      end;

  AdjustPositionsForTimesig (deltaPos);
  fTime := fTempoTime + ((fPosition - fTempoPos) * fTempo) div fPPQN;
  SkipToPosition;
end;

procedure TMidiPosition.SetEndPosition;
var
  i, p, endPos : Integer;
begin
  endPos := 0;
  if Assigned (fMidiData) then
  begin
    for i := 0 to fMidiData.NoTracks - 1 do
    begin
      if fMidiData.Tracks [i].EventCount > 0 then
      begin
        with fMidiData.Tracks [i] do p := Event [EventCount - 1].pos;
        if p > endPos then endPos := p
      end
    end
  end;
  SetPosition (endPos);
end;

function TMidiPosition.CalcLastNotePosition : Integer;
var
  i, p, endPos, endEvent : Integer;
begin
  endPos := 0;
  if Assigned (fMidiData) then
  begin
    for i := 0 to fMidiData.NoTracks - 1 do
    begin
      if fMidiData.Tracks [i].EventCount > 0 then
      begin
        with fMidiData.Tracks [i] do
        begin
          endEvent := EventCount -1;
          while (endEvent > 0) and ((Event [endEvent].data.status and midiSysex) = midiSysex) do
            Dec (endEvent);
          p := Event [endEvent].pos
        end;
        if p > endPos then endPos := p
      end
    end
  end;
  result := endPos;
end;

function TMidiPosition.GetDuration : Integer;
var oldPosition : Integer;
begin
  oldPosition := position;
  CalcNewPosition (CalcLastNotePosition);
  result := time;
  CalcNewPosition (oldPosition)
end;

procedure TMidiPosition.SetLastNotePosition;
begin
  SetPosition (CalcLastNotePosition)
end;

procedure TMidiIterator.Reset;
var
  i : Integer;
begin
  inherited;
  fEndOfSong := True;
  if Assigned (TrackOutputs) then
  begin
    TrackOutputs.ResetEventIndexes;
    TrackOutputs.SetPatchForPosition;

    for i := 0 to TrackOutputs.NoTracks - 1 do
      if TrackOutputs [i].TrackData.EventCount > 0 then
      begin
        fEndOfSong := False;
        break
      end
  end
end;

procedure TMidiIterator.SetTrackOutputs (value : TTrackOutputs);
begin
  fTrackOutputs := value;
  fTrackOutputs.ResetEventIndexes;
  fTrackOutputs.SetPatchForPosition
end;

procedure TMidiIterator.SkipToPosition;
var
  event, i, c, n : Integer;
  p : PMidiEventData;
  track : TMidiTrackStream;
  trackOutput : TTrackOutput;
begin
  fEndOfSong := True;
  if Assigned (TrackOutputs) then
    for i := 0 to TrackOutputs.NoTracks - 1 do
    begin
      trackOutput := TrackOutputs [i];
      track := trackOutput.TrackData;
      c := track.EventCount;
      n := trackOutput.EventIndex;
      while n < c do
      begin
        p := track.Event [n];
        if p^.pos < fPosition then
        begin
          event := p^.data.status and midiStatusMask;
          if (fPlayNotes and not trackOutput.Mute) or ((event <> midiNoteOn) and (event <> midiNoteOff)) then
             if event < midiSysex then
             begin
               trackOutput.Port.OutEvent (p^.data);
               if Assigned (TrackOutputs.OnEvent) and not (csDestroying
in ComponentState) then
                 TrackOutputs.OnEvent (self, i, p^.data)
             end;
//            if event < midiSysex then
//              trackOutput.Port.OutEvent (p^.data);
          Inc (n)
        end
        else break
      end;
      trackOutput.EventIndex := n;
      if n < c then fEndOfSong := False;
    end
end;

procedure TMidiIterator.IterateByTime (delta_time : Integer);
begin
  if csDestroying in ComponentState then
  begin
     fEndOfSong := True;
     exit
  end;

  fPlayNotes := True;
  SetTime (fTime + delta_time);
  fPlayNotes := False;
end;


end.

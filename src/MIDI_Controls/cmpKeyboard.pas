unit cmpKeyboard;

interface

uses Controls, Classes, Graphics;

type
  TKeyboardOrientation = (kbHorizontal, kbVertical);
  TKeyboardNoteEvent = procedure (Sender : TObject;var note, velocity : Integer) of object;

  TKeys = class (TGraphicControl)
    private
      FOrientation : TKeyboardOrientation;
      FNoteWidth : Integer;
      FBaseOctave : Integer;
      FBlackBrush : TBrush;
      FWhiteBrush : TBrush;
      FPen : TPen;
      FVelocityMode : boolean;
      FOnNoteOn : TKeyboardNoteEvent;
      FOnNoteOff : TKeyboardNoteEvent;
      noteMap : set of 0..127;
      currentNote : Integer;

      procedure FnMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure FnMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure FnMouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure SetNoteWidth (width : Integer);
      procedure SetBaseOctave (octave : Integer);
      procedure SetOrientation (orient: TKeyboardOrientation);
      procedure SetBlackBrush (value : TBrush);
      procedure SetWhiteBrush (value : TBrush);
      procedure SetPen (value : TPen);
      procedure StyleChanged (Sender : TObject);
      procedure GetSize (var w, l, blackw, blackl : Integer);
      procedure PaintHorizontal;
      procedure PaintVertical;
    published
      property Orientation : TKeyboardOrientation read FOrientation write SetOrientation default kbHorizontal;
      property NoteWidth : Integer read FNoteWidth write SetNoteWidth default 10;
      property BaseOctave : Integer read FBaseOctave write SetBaseOctave default 3;
      property Height default 50;
      property Width default 200;
      property BlackBrush : TBrush read FBlackBrush write SetBlackBrush;
      property WhiteBrush : TBrush read FWhiteBrush write SetWhiteBrush;
      property Pen : TPen read FPen write SetPen;
      property VelocityMode : boolean read FVelocityMode write FVelocityMode default True;

      property OnNoteOn : TKeyboardNoteEvent read FOnNoteOn write FOnNoteOn;
      property OnNoteOff : TKeyboardNoteEvent read FOnNoteOff write FOnNoteOff;


    protected
      procedure Paint; override;
      procedure InvertNote (note : Integer);

    public
      constructor Create (AOwner : TComponent); override;
      destructor Destroy; override;
      procedure DecodeNote (note : Integer; var octave, key : Integer; var sharp : boolean);
      function NoteAt (x, y : Integer; var velocity : Integer) : Integer;
      procedure PressNote (note, velocity : Integer; GenerateEvent : boolean); virtual;
      procedure ReleaseNote (note, aftertouch : Integer; GenerateEvent : boolean); virtual;
      procedure AllNotesOff (GenerateEvent : boolean);
  end;

  TMIDIChannel = 1..16;
  TMIDIKeys = class (TKeys)

    private
      FMIDIDevice : Integer;
      FMIDIChannel : TMIDIChannel;
      FMIDIPortName : string;
      FMIDIPortOk : Boolean;
      FMIDIPort : Integer;

      procedure SetMIDIDevice (value : Integer);
      procedure NoteOn (Sender : TObject;var note, velocity : Integer);
      procedure NoteOff (Sender : TObject;var note, velocity : Integer);

    published
      property MIDIDevice : Integer read FMIDIDevice write SetMIDIDevice nodefault;
      property MIDIChannel : TMIDIChannel read FMIDIChannel write FMIDIChannel default 1;

      property MIDIPortName : string read FMIDIPortName;
      property MIDIPortOk : boolean read FMIDIPortOk write FMIDIPortOk;

    public
      procedure PressNote (note, velocity : Integer; GenerateEvent : boolean); override;
      procedure ReleaseNote (note, aftertouch : Integer; GenerateEvent : boolean); override;
      constructor Create (AOwner : TComponent); override;
      destructor Destroy; override;
      property MIDIPort : Integer read FMIDIPort write FMIDIPort;

    protected
      procedure SelectMIDIPort;
    end;

implementation

uses WinProcs, WinTypes, SysUtils, MMSystem;

const
  blackOffsets : array [0..6] of Integer = (-1, 1, 0, -1, 0, 1, 0);

constructor TKeys.Create (AOwner : TComponent);
begin
  inherited Create (AOwner);
  ControlStyle := ControlStyle + [csOpaque];

  FBlackBrush := TBrush.Create;
  FWhiteBrush := TBrush.Create;
  FPen := TPen.Create;

  FBlackBrush.OnChange := StyleChanged;
  FWhiteBrush.OnChange := StyleChanged;
  FPen.OnChange := StyleChanged;

  Width := 200;
  Height := 50;
  FNoteWidth := 10;
  FOrientation := kbHorizontal;
  FBaseOctave := 3;
  FVelocityMode := True;

  BlackBrush.Color := clBlack;
  WhiteBrush.Color := clWhite;
  Pen.Color := clBlack;

  noteMap := [];
  currentNote := -1;

  OnMouseDown := fnMouseDown;
  OnMouseUp := fnMouseUp;
  OnMouseMove := fnMouseMove;
  OnNoteOn := Nil;
  OnNoteOff := Nil;

end;

destructor TKeys.Destroy;
begin
  FWhiteBrush.Free;
  FBlackBrush.Free;
  FPen.Free;
  inherited Destroy
end;

procedure TKeys.DecodeNote (note : Integer; var octave, key : Integer; var sharp : boolean);
var k : Integer;
begin
  octave := note div 12;
  k := note mod 12;
  if k >= 5 then Inc (k);
  key := k shr 1;
  sharp := odd (k)
end;

procedure TKeys.GetSize (var w, l, blackw, blackl: Integer);
begin
  if Orientation = kbHorizontal then
  begin
    w := width;
    l := height
  end
  else
  begin
    w := height;
    l := width
  end;
  blackl := l * 3 div 5;
  blackw := NoteWidth * 3 div 5;
  if not odd (blackw) then Inc (blackw);
end;

procedure TKeys.PaintHorizontal;
var
  p, x, keyNo : Integer;
  w, l, BlackLength, BlackWidth, BlackWidth1 : Integer;
begin
  GetSize (w, l, BlackWidth, BlackLength);
  BlackWidth1 := BlackWidth shr 1;

  p := NoteWidth;
  keyNo := 0;
  with canvas do while p < w do
  begin
    MoveTo (p, 0);
    LineTo (p, l);
    if keyNo in [0, 1, 3, 4, 5] then
    begin
      x := p - BlackWidth1 + blackOffsets [keyNo];
      Rectangle (x, 0, x + BlackWidth, BlackLength);
    end;
    Inc (p, NoteWidth);
    keyNo := (keyNo + 1) mod 7
  end
end;

procedure TKeys.PaintVertical;
var
  p, y, keyNo : Integer;
  w, l, BlackLength, BlackWidth, BlackWidth1 : Integer;
begin
  GetSize (w, l, BlackWidth, BlackLength);
  BlackWidth1 := BlackWidth shr 1;

  p := w - NoteWidth - 1;
  keyNo := 0;
  with canvas do while p > 0 do
  begin
    MoveTo (0, p);
    LineTo (l, p);
    if keyNo in [0, 1, 3, 4, 5] then
    begin
      y := p - BlackWidth1 - blackOffsets [keyNo];
      Rectangle (0, y, BlackLength, y + BlackWidth);
    end;
    Dec (p, NoteWidth);
    keyNo := (keyNo + 1) mod 7
  end
end;

procedure TKeys.Paint;
begin
  with Canvas do
  begin
    Brush := FWhiteBrush;
    Pen := FPen;
    Rectangle (0, 0, Width, Height);
    Brush := FBLackBrush;
    if Orientation = kbHorizontal then PaintHorizontal else PaintVertical
  end
end;

procedure TKeys.InvertNote (note : Integer);
var
  Octave, KeyNo, KeyNo1, noteDist : Integer;
  sharp : boolean;
  w, l, BlackLength, BlackWidth, BlackWidth1, BlackDist, BlackDist1 : Integer;
begin
  Dec (note, 12 * baseOctave);
  GetSize (w, l, BlackWidth, BlackLength);
  BlackWidth1 := BlackWidth shr 1;
  DecodeNote (note, Octave, KeyNo, sharp);
  noteDist := (KeyNo + Octave * 7) * NoteWidth;
  if KeyNo = 0 then KeyNo1 := 6 else KeyNo1 := KeyNo - 1;
  with Canvas do if Orientation = kbHorizontal then
  begin
    blackDist := noteDist + noteWidth - BlackWidth1 + BlackOffsets [keyNo];
    blackDist1 := noteDist - BlackWidth1 + BlackOffsets [keyNo1];
    if sharp then
      PatBlt (Handle, blackDist + 1, 1, BlackWidth - 2, BlackLength - 2, DSTINVERT)
    else
    begin
      PatBlt (Handle, noteDist + 2, BlackLength + 1, NoteWidth - 3, l - BlackLength - 3, DSTINVERT);
      case KeyNo of
        0, 3 : PatBlt (Handle, noteDist + 2, 2,
                               blackDist - noteDist - 3,
                               BlackLength - 1, DSTINVERT);
        1, 4, 5 : PatBlt (Handle, BlackDist1 + BlackWidth + 1, 2,
                                  BlackDist - BlackDist1 - BlackWidth - 2,
                                  BlackLength - 1, DSTINVERT);
        2, 6 : PatBlt (Handle, BlackDist1 + BlackWidth + 1, 2,
                               NoteDist + NoteWidth - BlackDist1 - BlackWidth - 2,
                               BlackLength - 1, DSTINVERT);
      end
    end
  end
  else
  begin
    noteDist := Height - noteDist - noteWidth;
    blackDist := noteDist + BlackWidth1 - BlackOffsets [keyNo] - BlackWidth;
    blackDist1 := noteDist + NoteWidth + BlackWidth1 - BlackOffsets [keyNo1] - BlackWidth;
    if sharp then
      PatBlt (Handle, 1, blackDist + 1, BlackLength - 2, BlackWidth - 2, DSTINVERT)
    else
    begin
      PatBlt (Handle, BlackLength + 1, noteDist + 1, l - BlackLength - 3, NoteWidth - 3, DSTINVERT);
      case KeyNo of
        0, 3 : PatBlt (Handle, 2, blackDist + BlackWidth + 1,
                               BlackLength - 1,
                               noteWidth - BlackWidth1 - 4, DSTINVERT);
        1, 4, 5 : PatBlt (Handle, 2, BlackDist + BlackWidth + 1,
                                  BlackLength - 1,
                                  BlackDist1 - BlackDist - BlackWidth - 2, DSTINVERT);
        2, 6 : PatBlt (Handle, 2, noteDist + 1,
                                  BlackLength - 1,
                                  blackDist1 - noteDist - 2, DSTINVERT);
      end
    end
  end
end;

procedure TKeys.SetNoteWidth (Width : Integer);
begin
  if FNoteWidth <> width then
  begin
    FNoteWidth  := Width;
    Invalidate
  end
end;

procedure TKeys.SetOrientation (Orient : TKeyboardOrientation);
begin
  if FOrientation <> Orient then
  begin
    FOrientation := Orient;
    Invalidate
  end
end;

procedure TKeys.SetBaseOctave (octave : Integer);
begin
  if octave <> FBaseOctave then
  begin
    FBaseOctave := octave;
    Repaint
  end
end;

procedure TKeys.SetBlackBrush (value : TBrush);
begin
  FBlackBrush.Assign (value)
end;

procedure TKeys.SetWhiteBrush (value : TBrush);
begin
  FWhiteBrush.Assign (value)
end;

procedure TKeys.SetPen (value : TPen);
begin
  FPen.Assign (value)
end;

procedure TKeys.StyleChanged (Sender : TObject);
begin
  Invalidate
end;

function TKeys.NoteAt (x, y : Integer; var velocity : Integer) : Integer;
var
  KeyNo, KeyNo1, KeyPos, Octave, noteNo, noteDist : Integer;
  sharp : boolean;
  w, l, BlackLength, BlackWidth, BlackWidth1 : Integer;
begin
  GetSize (w, l, BlackWidth, BlackLength);
  BlackWidth1 := BlackWidth shr 1;

  if Orientation = kbHorizontal then
  begin
    KeyPos := x;
    noteDist := y
  end
  else
  begin
    KeyPos := w - y - 1;
    noteDist := x
  end;

  KeyNo := KeyPos div noteWidth;
  KeyPos := KeyPos mod noteWidth;
  Octave := KeyNo div 7;
  KeyNo := KeyNo mod 7;
  if KeyNo = 0 then KeyNo1 := 6 else KeyNo1 := KeyNo - 1;
  sharp := False;
  if noteDist < BlackLength then
    if keyPos >= NoteWidth - BlackWidth1 + blackOffsets [KeyNo] then
      sharp := KeyNo in [0, 1, 3, 4, 5]
    else
      if keyPos < BlackWidth - BlackWidth1 + blackOffsets [KeyNo1] then
      begin
        sharp := KeyNo in [1, 2, 4, 5, 6];
        if sharp then KeyNo := KeyNo1
      end;

  noteNo := KeyNo * 2;
  if noteNo >= 6 then Dec (noteNo);
  if sharp then
  begin
    Inc (noteNo);
    l := BlackLength;
  end;
  if FVelocityMode then
    velocity := noteDist * 127 div l
  else
    velocity := 127;
  noteAt := noteNo + (Octave + BaseOctave) * 12;
end;

procedure TKeys.PressNote (note, velocity : Integer; GenerateEvent : boolean);
begin
  if not (note in noteMap) then
  begin
    InvertNote (note);
    noteMap := noteMap + [note]
  end;
  if GenerateEvent and Assigned (FOnNoteOn) then OnNoteOn (Self, note, velocity);

end;

procedure TMIDIKeys.PressNote (note, velocity : Integer; GenerateEvent : boolean);
begin
  inherited;
  Self.NoteOn(Self, note, velocity);
end;

procedure TKeys.ReleaseNote (note, aftertouch : Integer; GenerateEvent : boolean);
begin
  if note in noteMap then
  begin
    InvertNote (note);
    noteMap := noteMap - [note]
  end;
  if GenerateEvent and Assigned (FOnNoteOff) then OnNoteOff (Self, note, aftertouch);

end;

procedure TMIDIKeys.ReleaseNote (note, aftertouch : Integer; GenerateEvent : boolean);
begin
inherited;
Self.NoteOff(Self, note, aftertouch);
end;

procedure TKeys.AllNotesOff (GenerateEvent : boolean);
var i : Integer;
begin
  for i := 0 to 127 do
    if i in noteMap then
      ReleaseNote (i, 0, GenerateEvent)
end;

procedure TKeys.FnMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var n, velocity : Integer;
begin
  SetCaptureControl (self);
  if Button = mbLeft then
  begin
    n := NoteAt (x, y, velocity);
    if (n >= 0) and (n < 128) then
    begin
      currentNote := n;
      PressNote (currentNote, velocity, True)
    end
  end
end;

procedure TKeys.FnMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetCaptureControl (Nil);
  ReleaseNote (currentNote, 0, True)
end;

procedure TKeys.FnMouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
var Note, velocity : Integer;
begin
  if (ssLeft in Shift) and PtInRect (Rect (0, 0, width - 1, height - 1), Point (x, y)) then
  begin
    note := NoteAt (x, y, velocity);
    if (note >= 0) and (note < 128) and (note <> CurrentNote) then
    begin
      ReleaseNote (CurrentNote, 0, True);
      CurrentNote := note;
      PressNote (CurrentNote, velocity, True)
    end
  end
end;

constructor TMIDIKeys.Create (AOwner : TComponent);
begin
  inherited Create (AOwner);
  OnNoteOn := nil;
  OnNoteOff := nil;;

  FMIDIDevice := -1;
  FMIDIPortName := 'Microsoft MIDI Mapper';
  FMIDIChannel := 1;
end;

destructor TMIDIKeys.Destroy;
begin
  if midiPort <> 0 then
  begin
    midiOutReset (midiPort);
    midiOutClose (midiPort);
  end;
  inherited Destroy
end;

procedure TMIDIKeys.SelectMIDIPort;
var
  rv, noDevs : Longint;
begin
  if midiPort <> 0 then
  begin
    midiOutReset (midiPort);
    midiOutClose (midiPort);
    FMIDIPort := 0;
  end;

  FMIDIportOk := False;

  noDevs := midiOutGetNumDevs;
  if FMIDIDevice < noDevs then
  begin
    rv := midiOutOpen (@FMIDIPort, MIDI_MAPPER, 0, 0, 0);
    if rv = 0 then FMIDIPortOk := True;
  end
end;

procedure TMIDIKeys.SetMIDIDevice (value : Integer);
var
  noDevs : Integer;
  devCaps : TMidiOutCaps;
begin
  if value <> FMIDIDevice then
  begin
    if midiPort <> 0 then
    begin
      midiOutReset (midiPort);
      midiOutClose (midiPort);
      FMIDIPort := 0
    end;

    FMIDIDevice := value;
    noDevs := midiOutGetNumDevs;
    if FMIDIDevice < noDevs then
    begin
      midiOutGetDevCaps (FMIDIDevice, @devCaps, sizeof (devCaps));
      FMIDIPortName := StrPas (devCaps.szPName);
    end
    else FMIDIPortName := '';
  end
end;

procedure TMIDIKeys.NoteOn (Sender : TObject;var note, velocity : Integer);
var
  data : record case boolean of
    True  : (b1, b2, b3, b4 : byte);
    False : (l : LongInt);
  end;
begin
  if midiPort = 0 then SelectMIDIPort;
  if FMIDIPortOk then with data do
  begin
    b1 := $90 + FMIDIChannel - 1;
    b2 := note;
    b3 := velocity;
    b4 := 0;
    midiOutShortMsg (midiPort, l);
  end;
end;

procedure TMIDIKeys.NoteOff (Sender : TObject;var note, velocity : Integer);
var
  data : record case boolean of
    True  : (b1, b2, b3, b4 : byte);
    False : (l : LongInt);
  end;
begin
  if FMIDIPortOk then with data do
  begin
    b1 := $80 + FMIDIChannel - 1;
    b2 := note;
    b3 := velocity;
    b4 := 0;
    midiOutShortMsg (midiPort, l);
  end;
end;

end.

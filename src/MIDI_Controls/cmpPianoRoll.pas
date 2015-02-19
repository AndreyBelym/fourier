unit cmpPianoRoll;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, cmpMidiData, StdCtrls, cmpMidiIterator, unitMidiGlobals, cmpBarControl;

const
  MaxNotes = 1024;
  crHandCursor = 6;

  type
  TNote = object
    fx1, fx2, fy : Integer;
    fNoteOnEvent : PMidiEventData;
    selected : boolean;
    procedure Init (x1, x2, y : Integer; NoteOnEvent : PMidiEventData; isSelected : boolean);
  end;

  TCaptureType = (ctNone, ctLStretching, ctRStretching, ctMoving);

  TOnNoteMoving = procedure (sender : TObject; note, startPos, endPos : Integer) of object;
  TOnNoteMoved = TOnNoteMoving;


  TPianoRoll = class(TCustomBarControl)
  private
    fWhiteNoteHeight : Integer;
    fNoteCursor : TCursor;
    fLeftStretchCursor : TCursor;
    fRightStretchCursor : TCursor;

    fOnNoteMoving : TOnNoteMoving;
    fOnNoteMoved : TOnNoteMoved;
    fOnFocus : TNotifyEvent;

    fOldCursor : TCursor;

    fNoteMap : array [0..MaxNotes - 1] of TNote;
    fNoNotes : Integer;
    FocusedNote : Integer;
    NoteCapture : TCaptureType;
    CapturePt : TPoint;
    LastMovePoint : TPoint;

    procedure SetWhiteNoteHeight (value : Integer);
    function GetNoteFocused : boolean;
    procedure CalcNoteMap;
    procedure MoveCapturedNote (pt : TPoint);

  protected
    procedure CalcBarMap; override;
    procedure DisplayBarMap; override;
    procedure CursorMoved (pt : TPoint); override;
    //procedure WMLButtonDown (var Message : TWmLButtonDown); message WM_LBUTTONDOWN;
    //procedure WMLButtonUp (var Message : TWmLButtonDown); message WM_LBUTTONUP;

  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    procedure DisplayBarMapContents; override;
    function CalcNoteFromY (y : Integer) : Integer;
    procedure CalcNoteValues (x1, x2, y : Integer; var note, startPos, endPos : Integer);
    procedure GetFocusedNote (var NoteOnEvent : PMidiEventData);
    function GetNoteNoAtCursor : Integer;
    property NoteFocused : boolean read GetNoteFocused;

  published
    property WhiteNoteHeight : Integer read fWhiteNoteHeight write SetWhiteNoteHeight;

    property OnNoteMoving : TOnNoteMoving read fOnNoteMoving write fOnNoteMoving;
    property OnNoteMoved : TOnNoteMoved read fOnNoteMoved write fOnNoteMoved;
    property NoteCursor : TCursor read fNoteCursor write fNoteCursor;
    property LeftStretchCursor : TCursor read fLeftStretchCursor write fLeftStretchCursor;
    property RightStretchCursor : TCursor read fRightStretchCursor write fRightStretchCursor;
    property OnFocus : TNotifyEvent read fOnFocus write fOnFocus;

    property MidiData;
    property Track;
    property LeftPosition;
    property ActivePosition;
    property QNWidth;

    property OnStartSelection;
    property OnEndSelection;
    property OnMouseMoved;
    property OnScroll;

    property Align;
    property Color;
    property Cursor;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;
  end;

implementation

uses unitMidiTrackStream;

procedure TNote.Init (x1, x2, y : Integer; NoteOnEvent : PMidiEventData; isSelected : boolean);
begin
  fx1 := x1;
  fx2 := x2;
  fy := y;
  fNoteOnEvent := NoteOnEvent;
  selected := isSelected;
end;

constructor TPianoRoll.Create (AOwner : TComponent);
begin
  inherited Create (AOwner);
  Screen.Cursors [crHandCursor] := LoadCursor (HInstance, 'HANDCURSOR');
  fWhiteNoteHeight := 16;

  fNoteCursor := crHandCursor;
  fLeftStretchCursor := crSizeWE;
  fRightStretchCursor := crSizeWE;
  fOldCursor := -1;
  FocusedNote := -1;
end;

destructor TPianoRoll.Destroy;
begin
  inherited
end;

procedure TPianoRoll.SetWhiteNoteHeight (value : Integer);
begin
  if value <> fWhiteNoteHeight then
  begin
    fWhiteNoteHeight := value;
    Invalidate;
  end
end;

procedure TPianoRoll.CalcNoteMap;
var
  p : PMidiEventData;
  idx, yOffset : Integer;
  s : byte;

  procedure AddNote (note : Integer; ep : PMidiEventData);
  var
    x1, x2, y, Octave : Integer;
    selected : boolean;
    sp : PMidiEventData;
  begin
    if fNoNotes < MaxNotes then
    begin
      sp := ep^.OnOffEvent;
      with MidiData.Tracks [Track] do
      begin
        selected := (sp^.pos >= SelStartPos) and (sp^.pos <= SelEndPos);
        x1 := CalcPosX (sp^.pos);
        x2 := CalcPosX (ep^.pos)
      end;
      Octave := note div 12;
      Note := Note mod 12;
      y := (WhiteNoteHeight * 7 * Octave) + Note * fWhiteNoteHeight div 2;
      if Note >= 5 then Inc (y, fWhiteNoteHeight div 2);
      fNoteMap [fNoNotes].Init (x1, x2, yOffset - y, sp, selected);
      Inc (fNoNotes)
    end
  end;

begin
  fNoNotes := 0;
  yoffset := ActiveHeight + (11 - VertScrollbar.Position) * 7 * WhiteNoteHeight;

  if (Not Assigned (MidiData)) or (not Assigned (MidiData.Tracks [Track])) then Exit;

  idx := MidiData.Tracks [Track].FindEventNo (Iterator.Position, feFirst);
  if idx = -1 then exit;

  while idx < MidiData.Tracks [Track].EventCount do
  begin
    p := MidiData.Tracks [Track].Event [idx];
    if p^.pos > EndPosition then break;

    s := p^.data.status and midiStatusMask;
    if (s = midiNoteOff) or ((s = midiNoteOn) and (p^.data.b3 = 0)) then
      AddNote (p^.data.b2, p);
    Inc (idx);
  end
end;

procedure TPianoRoll.DisplayBarMap;
var
  p : Integer;
begin
  inherited;
  with Canvas do
  begin
    p := ActiveHeight;
    MoveTo (0, p);
    LineTo (ActiveRect.right, p);
    Pen.Style := psDot;
    while True do with Canvas do
    begin
      Dec (p, WhiteNoteHeight * 7);
      if p > 0 then
      begin
        MoveTo (0, p);
        LineTo (ActiveRect.Right, p)
      end
      else break
    end;

    Pen.Style := psSolid
  end
end;


procedure TPianoRoll.DisplayBarMapContents;
var
  n : Integer;
  region : HRgn;
  oldColor : TColor;
begin
  with Canvas do
  begin
    Refresh;
    oldColor := brush.Color;

    region := CreateRectRgn (ActiveRect.left, ActiveRect.Top, ActiveRect.right, ActiveRect.bottom - BottomMargin);
    SelectClipRgn (handle, region);
    DeleteObject (region);

    for n := 0 to fNoNotes -1 do
      with fNoteMap [n] do
      begin
        {if Selected then
          Brush.Color := clSilver
        else }
        Brush.Color := clWhite;
        Rectangle (fx1, fy - WhiteNoteHeight div 2, fx2, fy)
      end;
    Brush.Color := oldColor;
  end
end;


{procedure TPianoRoll.WMLButtonDown (var Message : TWmLButtonDown);
var
  r : TRect;
  region : HRgn;

begin
  if FocusedNote <> -1 then
  begin
    CapturePt := SmallPointToPoint (Message.pos);
    LastMovePoint := CapturePt;
    with fNoteMap [FocusedNote] do
    begin
      r.top := fy - WhiteNoteHeight div 2 + 1;
      r.left := fx1 + 1;
      r.right := fx2 - 1;
      r.bottom := fy - 1;

      with Canvas do
      begin
        region := CreateRectRgn (activeRect.left, activeRect.Top, activeRect.right, activeHeight);
        SelectClipRgn (handle, region);
        DeleteObject (region);

        FillRect (r);
        SelectClipRgn (handle, 0);
      end;

      if CapturePt.x < r.left + 1 then
        NoteCapture := ctLStretching
      else
        if CapturePt.x > r.right - 1 then
          NoteCapture := ctRStretching
        else
          NoteCapture := ctMoving
    end
  end
  else
    inherited;
end;
 }
{procedure TPianoRoll.WMLButtonUp (var Message : TWmLButtonDown);
var
  note, sp, ep, x1, x2, y : Integer;
begin
  if NoteCapture <> ctNone then
  begin
    with fNoteMap [FocusedNote] do
    begin
      if Assigned (OnNoteMoved) then with fNoteMap [FocusedNote] do
      begin
        if NoteCapture = ctMoving then y := fy + (LastMovePoint.y - CapturePt.y) else y := fy;
        if NoteCapture = ctRStretching then x1 := fx1 else x1 := fx1 + (LastMovePoint.x - CapturePt.x);
        if NoteCapture = ctLStretching then x2 := fx2 else x2 := fx2 + (LastMovePoint.x - CapturePt.x);
        CalcNoteValues (x1, x2, y, note, sp, ep);
        OnNoteMoved (self, note, sp, ep)
      end
    end;
    NoteCapture := ctNone;
  end
  else
    inherited
end;
 }

procedure TPianoRoll.GetFocusedNote (var NoteOnEvent : PMidiEventData);
begin
  if FocusedNote <> -1 then with fNoteMap [FocusedNote] do
    NoteOnEvent := fNoteOnEvent
  else
    NoteOnEvent := Nil
end;

function TPianoRoll.CalcNoteFromY (y : Integer) : Integer;
var
  nh2, Octave, YOffset : Integer;
begin
  yoffset := ActiveHeight + (11 - VertScrollbar.Position) * 7 * WhiteNoteHeight;
  y := yOffset - y;
  nh2 := WhiteNoteHeight div 2;

  Octave := y div (7 * WhiteNoteHeight);
  y := y mod (7 * WhiteNoteHeight);
  result := y div nh2;
  if result = 5 then
  begin
    if y mod nh2 < (nh2 div 2) then
      Dec (result)
  end
  else if result > 5 then Dec (result);
  Inc (result, 12 * Octave);
end;

procedure TPianoRoll.CalcNoteValues (x1, x2, y : Integer; var note, startPos, endPos : Integer);
begin
  note := CalcNoteFromY (y);
  startPos := CalcPosFromX (x1);
  endPos := CalcPosFromX (x2);
end;

procedure TPianoRoll.CursorMoved (pt : TPoint);
var
  n : Integer;
  nh : Integer;
  r : TRect;
  oldFocusedNote : Integer;
begin
  if csDesigning in ComponentState then Exit;
  
  if fOldCursor = -1 then
    fOldCursor := Cursor;
  if NoteCapture <> ctNone then
     MoveCapturedNote (pt)
  else
  begin
    nh := WhiteNoteHeight div 2;
    oldFocusedNote := FocusedNote;
    FocusedNote := -1;
    for n := 0 to fNoNotes -1 do
      with fNoteMap [n] do
      begin
        r.top := fy - nh;
        r.left := fx1;
        r.right := fx2;
        r.bottom := fy;
        if PtInRect (r, pt) then
        begin
          FocusedNote := n;
          if pt.x <= r.left + 2 then
            Cursor := fLeftStretchCursor
          else
            if pt.x >= r.right - 2 then
              Cursor := fRightStretchCursor
            else
              Cursor := fNoteCursor;
          break
        end
      end;
    if FocusedNote = -1 then
      Cursor := fOldCursor ;

    if oldFocusedNote <> focusedNote then
      if Assigned (fOnFocus) then
        OnFocus (self);

    inherited

  end
end;

function TPianoRoll.GetNoteFocused : boolean;
begin
  result := FocusedNote <> -1
end;

procedure TPianoRoll.MoveCapturedNote (pt : TPoint);
var
  nh2 : Integer;
  note, sp, ep : Integer;
  x1, x2, y : Integer;
  oldMode : TPenMode;
  oldColor : TColor;
begin
  if (LastMovePoint.x <> pt.x) or (LastMovePoint.y <> pt.y) then with Canvas do
  begin
    nh2 := WhiteNoteHeight div 2;

    oldMode := Pen.Mode;
    oldColor := pen.Color;
    Pen.Mode := pmXOR;
    Pen.Color := clWhite;
    with fNoteMap [FocusedNote] do
    begin
      if NoteCapture = ctMoving then y := fy + (LastMovePoint.y - CapturePt.y) else y := fy;
      if NoteCapture = ctRStretching then x1 := fx1 else x1 := fx1 + (LastMovePoint.x - CapturePt.x);
      if NoteCapture = ctLStretching then x2 := fx2 else x2 := fx2 + (LastMovePoint.x - CapturePt.x);
      MoveTo (x1, y - 1);
      LineTo (x1, y - nh2);
      LineTo (x2, y - nh2);
      MoveTo (x2 - 1, y - nh2 + 1);
      LineTo (x2 - 1, y - 1);
      LineTo (x1, y - 1);
    end;

    LastMovePoint := pt;
    with fNoteMap [FocusedNote] do
    begin
      if NoteCapture = ctMoving then y := fy + (LastMovePoint.y - CapturePt.y) else y := fy;
      if NoteCapture = ctRStretching then x1 := fx1 else x1 := fx1 + (LastMovePoint.x - CapturePt.x);
      if NoteCapture = ctLStretching then x2 := fx2 else x2 := fx2 + (LastMovePoint.x - CapturePt.x);
      MoveTo (x1, y - 1);
      LineTo (x1, y - nh2);
      LineTo (x2, y - nh2);
      MoveTo (x2 - 1, y - nh2 + 1);
      LineTo (x2 - 1, y - 1);
      LineTo (x1, y - 1);
    end;

    LastMovePoint := pt;
    Pen.Color := oldColor;
    Pen.Mode :=oldMode;

    if Assigned (OnNoteMoving) then with fNoteMap [FocusedNote] do
    begin
      CalcNoteValues (x1, x2, y, note, sp, ep);
      OnNoteMoving (self, note, sp, ep)
    end
  end
end;

procedure TPianoRoll.CalcBarMap;
begin
  inherited;
  CalcNoteMap
end;

function TPianoRoll.GetNoteNoAtCursor: Integer;
var
  pt : TPoint;
begin
  GetCursorPos (pt);
  pt := ScreenToClient (pt);
  result := CalcNoteFromY (pt.y);
end;

end.

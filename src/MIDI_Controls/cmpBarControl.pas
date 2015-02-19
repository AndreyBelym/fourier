unit cmpBarControl;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, stdctrls, cmpMidiData, cmpMidiIterator, unitMidiGlobals;

const
  MaxBars = 64;
  BottomMargin = 16;

type
  TOnStartSelection = procedure (sender : TObject; pos : Integer) of object;
  TOnEndSelection = TOnStartSelection;
  TOnMouseMoved = procedure (sender : TObject; bar, beat, tick : Integer) of object;

  TBar = object
    fx : Integer;
    fPosition : Integer;
    fBeatDiv, fBeatsPerBar : Integer;
    fBeatWidth : Integer;
    procedure Assign (Position, BeatsPerBar, BeatDiv, x, BeatWidth : Integer);
  end;

  TCustomBarControl = class(TWinControl)
  private
    FHorzScrollBar: TScrollBar;
    FVertScrollBar: TScrollBar;
    fMidiData : TMidiData;
    fTrack : Integer;
    fCanvas : TControlCanvas;
    fTrackerCanvas : TControlCanvas;
    fTrackerX : Integer;
    fLeftPosition : Integer;
    fActivePosition : Integer;
    fIterator : TMidiPosition;
    fOnScroll : TScrollEvent;
    fOnStartSelection : TOnStartSelection;
    fOnEndSelection : TOnEndSelection;
    fOnMouseMoved : TOnMouseMoved;

    fSelStartPos, fSelEndPos : Integer;

    fEndPosition : Integer;
    fBarMap : array [0..MaxBars - 1] of TBar;
    fNoBars : Integer;
    fFullPaint : boolean;

    fQNWidth: Integer;
    procedure SetQNWidth(const Value: Integer);
    procedure SetActivePosition(const Value: Integer);
    procedure SetLeftPosition(const Value: Integer);
    procedure SetMidiData(const Value: TMidiData);
    procedure SetTrack(const Value: Integer);
    function GetActiveHeight: Integer;
    procedure HorizScrollbarScroll (Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure VertScrollbarScroll (Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure UpdateScrollBars;

  protected
    ActiveRect : TRect;
    procedure Paint;
    procedure CalcBarMap; virtual;
    procedure DisplayBarMap; virtual;
    procedure DisplayBarMapContents; virtual;
    procedure CursorMoved (pt : TPoint); virtual;

    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMPaint (var Msg : TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseMove (var Message : TWmMouseMove); message WM_MOUSEMOVE;
    procedure WMLButtonDown (var Message : TWmLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp (var Message : TWmLButtonDown); message WM_LBUTTONUP;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMKeyDown (var Message : TMessage); message WM_KEYDOWN;
    procedure WMMouseActivate (var Message : TMessage); message WM_MOUSEACTIVATE;
    procedure CreateWnd; override;

    property MidiData : TMidiData read fMidiData write SetMidiData;
    property Track : Integer read fTrack write SetTrack;
    property LeftPosition : Integer read fLeftPosition write SetLeftPosition;
    property ActivePosition : Integer read fActivePosition write SetActivePosition;
    property QNWidth : Integer read fQNWidth write SetQNWidth;
    property Iterator : TMidiPosition read fIterator;
    property EndPosition : Integer read fEndPosition;

    property OnStartSelection : TOnStartSelection read fOnStartSelection write fOnStartSelection;
    property OnEndSelection : TOnEndSelection read fOnEndSelection write fOnEndSelection;
    property OnMouseMoved : TOnMouseMoved read fOnMouseMoved write fOnMouseMoved;

    property OnScroll : TScrollEvent read fOnScroll write fOnScroll;

    property TabStop default True;
  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    procedure Reset;

    function CalcPosX (pos : Integer) : Integer;
    function CalcPosBeatDiv(pos: Integer): Integer;
    function CalcPosFromX (x : Integer) : Integer;
    procedure CalcBarAndBeatFromXY (x, y : Integer; var bar, beat, tick : Integer);

    property Canvas : TControlCanvas read fCanvas;
    property HorzScrollBar : TScrollBar read FHorzScrollBar;
    property VertScrollBar : TScrollBar read FVertScrollBar;
    property ActiveHeight : Integer read GetActiveHeight;
    procedure SetSelStartPos (value : Integer; NoInvalidate : boolean);
    procedure SetSelEndPos (value : Integer; NoInvalidate : boolean);
    property SelStartPos : Integer read fSelStartPos;
    property SelEndPos : Integer read fSelEndPos;
  published
  end;

  TBarControl = class (TCustomBarControl)
  published
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

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MIDI', [TBarControl]);
end;

{ TCustomBarControl }

procedure TCustomBarControl.CalcBarAndBeatFromXY(x, y: Integer; var
  bar, beat, tick: Integer);
begin
  bar := 0;
  while (bar < fNoBars - 1) and (x >= fBarMap [bar + 1].fx) do
    Inc (bar);

  with fBarMap [bar] do
  begin
    beat := (x - fx) div fBeatWidth;
    tick := AdjustForTimesig ((x - fx) * midiData.ppqn div fBeatWidth mod midiData.ppqn, fBeatDiv)
  end;

  bar := bar + fHorzScrollBar.Position + 1;
end;

procedure TCustomBarControl.CalcBarMap;
var
  i : TMidiPosition;
  x : Integer;
  BeatWidth : Integer;
begin
  i := TMidiPosition.Create (Self);
  i.Assign (fIterator);
  x := 0;
  fNoBars := 0;
  while x < ActiveRect.Right do
  begin
    with i do
    begin
      BeatWidth := AdjustForTimesig (QNWidth, BeatDiv);
      fBarMap [fNoBars].Assign (Position, BeatsPerBar, BeatDiv, x, BeatWidth);
      Inc (fNoBars);
      Inc (x, BeatWidth * BeatsPerBar);
      SetBarPosition (Bar + 1, 0, 0);
    end
  end;

  fEndPosition := i.Position + i.TicksPerBar;

  i.Free;

end;

function TCustomBarControl.CalcPosFromX(x: Integer): Integer;
var
  bar : Integer;
begin
  if Assigned (MidiData) then
  begin
    bar := 0;
    while (bar < fNoBars - 1) and (x >= fBarMap [bar + 1].fx) do
      Inc (bar);

    with fBarMap [bar] do
      result := fPosition + AdjustForTimesig ((x - fx) * midiData.ppqn div fBeatWidth, fBeatDiv)
  end
  else
    result := 0;
end;

function TCustomBarControl.CalcPosX(pos: Integer): Integer;
var
  bar : Integer;
begin
  if Assigned (MidiData) then
  begin
    bar := 0;
    while (bar < fNoBars - 1) and (pos > fBarMap [bar + 1].fPosition) do
      Inc (bar);

    with fBarMap [bar] do
      result := fx + UnAdjustForTimesig ((pos - fPosition) * fBeatWidth div MidiData.ppqn, fBeatDiv)
  end
  else
    result := 0;
end;

function TCustomBarControl.CalcPosBeatDiv(pos: Integer): Integer;
var
  bar : Integer;
begin
  if Assigned (MidiData) then
  begin
    bar := 0;
    while (bar < fNoBars - 1) and (pos > fBarMap [bar + 1].fPosition) do
      Inc (bar);

    with fBarMap [bar] do
      result := fBeatDiv
  end
  else
    result := 0;
end;

constructor TCustomBarControl.Create(AOwner: TComponent);
begin
  inherited Create (AOwner);
  controlStyle := controlStyle + [csOpaque];
  Width := 185;
  Height := 41;
  TabStop := True;
  fQNWidth := 32;

  FVertScrollBar := TScrollBar.Create(self);
  FVertScrollBar.Parent := self;
  fVertScrollBar.Kind := sbVertical;
  FVertScrollBar.SmallChange := 1;
  FVertScrollBar.LargeChange := 1;
  FVertScrollBar.SetParams (7, 0, 11);
  FVertScrollBar.OnScroll := VertScrollBarScroll;

  fIterator := TMidiPosition.Create (self);
  fIterator.MidiData := MidiData;
  fIterator.SetEndPosition;

  FHorzScrollBar := TScrollBar.Create (self);
  FHorzScrollBar.Parent := self;
  FHorzScrollBar.Kind := sbHorizontal;
  FHorzScrollBar.SetParams (0, 0, fIterator.Bar);
  FHorzScrollBar.OnScroll := HorizScrollBarScroll;
  FHorzScrollBar.TabStop := False;

  fIterator.SetPosition (0);

  fCanvas := TControlCanvas.Create;
  fCanvas.Control := Self;
  fTrackerCanvas := TControlCanvas.Create;
  fTrackerCanvas.Control := self;
  FVertScrollBar.TabStop := False;
  fTrackerX := -1;

end;

procedure TCustomBarControl.CreateWnd;
var vp : Integer;
begin
  inherited CreateWnd;
  fTrackerCanvas.Pen.Color := clRed;
  fTrackerCanvas.Pen.Mode :=pmNotXor;
  fCanvas.Font := Font;
  fCanvas.Brush.Color := Color;
  if Assigned (fOnScroll) then
  begin
    vp := VertScrollBar.Position;
    fOnScroll (Nil, scPosition, vp)
  end;
  fFullPaint := True;
end;

procedure TCustomBarControl.CursorMoved(pt: TPoint);
var
  bar, beat, tick : Integer;
begin
  if Assigned (fOnMouseMoved) then
  begin
    CalcBarAndBeatFromXY (pt.x, pt.y, bar, beat, tick);
    OnMouseMoved (self, bar, beat, tick)
  end
end;

destructor TCustomBarControl.Destroy;
begin
  fCanvas.Free;
  fTrackerCanvas.Free;
  inherited
end;

procedure TCustomBarControl.DisplayBarMapContents;
begin

end;

procedure TCustomBarControl.DisplayBarMap;
var
  n, p, t : Integer;
  region : HRgn;
  rect : TRect;
  oldColor : TColor;
  s : string;
begin
  rect := ActiveRect;
  Dec (rect.Bottom, BottomMargin);

  with Canvas do
  begin
    Refresh;

    oldColor := brush.Color;
    region := CreateRectRgn (ActiveRect.left, ActiveRect.Top, ActiveRect.right, ActiveRect.bottom);
    SelectClipRgn (handle, region);
    DeleteObject (region);
    FillRect (rect);

    rect.Top := rect.Bottom;
    rect.Bottom := ActiveRect.Bottom;
    Brush.Color := clBtnFace;

    FillRect (rect);

    for n := 0 to fNoBars - 1 do
    begin
      p := fBarMap [n].fx;
      if n > 0 then
      begin
        MoveTo (p, 0);
        LineTo (p, ActiveRect.Bottom);
        s := IntToStr (HorzScrollBar.Position + n);
        TextOut (p - (fBarMap [n-1].fBeatsPerBar * fBarMap [n-1].fBeatWidth) div 2 - TextWidth (s) div 2, rect.top + 3, s);
      end;

      for t := 1 to fBarMap [n].fBeatsPerBar - 1 do
      begin
        Inc (p, fBarMap [n].fBeatWidth);
        MoveTo (p, ActiveHeight + 6);
        LineTo (p, ActiveHeight)
      end
    end;

    p := ActiveHeight;
    MoveTo (0, p);
    LineTo (ActiveRect.right, p);

    Brush.Color := oldColor;
  end
end;

function TCustomBarControl.GetActiveHeight: Integer;
begin
  result := ActiveRect.Bottom - BottomMargin
end;


procedure TCustomBarControl.HorizScrollbarScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  with fIterator do if Bar <> ScrollPos then
  begin
    SetBarPosition (ScrollPos, 0, 0);
    fTrackerX := -1;
    Invalidate
  end
end;

procedure TCustomBarControl.Paint;
var pt : TPoint;
begin
  if fTrackerX <> -1 then
  begin
    fTrackerCanvas.MoveTo (fTrackerX, 0);
    fTrackerCanvas.LineTo (fTrackerX, activeRect.Bottom);
    fTrackerX := -1;
  end;

  CalcBarMap;
  if fFullPaint then
    DisplayBarMap;
  DisplayBarMapContents;
  GetCursorPos (pt);
  pt := ScreenToClient (pt);
  CursorMoved (pt);
  fFullPaint := True
end;

procedure TCustomBarControl.Reset;
begin
  fIterator.Reset;
  fIterator.SetEndPosition;
  fHorzScrollBar.Max := fIterator.Bar;
  fiterator.SetPosition (0);
  Track := 0;
end;

procedure TCustomBarControl.SetActivePosition(const Value: Integer);
var x : Integer;
begin
  if fNoBars = 0 then CalcBarMap;
  if value <> fActivePosition then
  begin
    x := CalcPosX (value);
    if (x < 0) or (x > ActiveRect.right) then
    begin
      LeftPosition := value;
      x := CalcPosX (value)
    end;

    if fTrackerX <> -1 then
    begin
      fTrackerCanvas.MoveTo (fTrackerX, 0);
      fTrackerCanvas.LineTo (fTrackerX, ActiveRect.Bottom)
    end;

    fTrackerCanvas.MoveTo (x, 0);
    fTrackerCanvas.LineTo (x, ActiveRect.Bottom);
    fTrackerX := x;
    fActivePosition := value;
  end
end;

procedure TCustomBarControl.SetLeftPosition(const Value: Integer);
begin
  if value <> fLeftPosition then
  begin
    fLeftPosition := value;
    fIterator.position := value;
    with fIterator do SetBarPosition (Bar, 0, 0);
    HorzScrollBar.Position := fIterator.bar;
    Invalidate;
  end
end;

procedure TCustomBarControl.SetMidiData(const Value: TMidiData);
begin
  if value <> fMidiData then
  begin
    fMidiData := value;
    fIterator.MidiData := value;
    Reset
  end
end;

procedure TCustomBarControl.SetQNWidth(const Value: Integer);
begin
  if (value <> fQNWidth) and (value >= 4) then
  begin
    fQNWidth := value;
    Invalidate
  end
end;

procedure TCustomBarControl.SetSelEndPos(value: Integer;
  NoInvalidate: boolean);
begin
  if value <> fSelEndPos then
  begin
    fSelEndPos := value;
    if NoInvalidate then
    begin
      fFullPaint := False;
      Repaint;
    end
    else Invalidate
  end
end;

procedure TCustomBarControl.SetSelStartPos(value: Integer;
  NoInvalidate: boolean);
begin
  if value <> fSelStartPos then
  begin
    fSelStartPos := value;
    if NoInvalidate then
    begin
      fFullPaint := False;
      Repaint;
    end
    else
      invalidate;
  end
end;

procedure TCustomBarControl.SetTrack(const Value: Integer);
begin
  if fTrack <> value then
  begin
    fTrack := value;
    Refresh
  end
end;

procedure TCustomBarControl.UpdateScrollBars;
begin
  HorzScrollBar.Width := ActiveRect.Right;
  HorzScrollBar.Top := ActiveRect.Bottom;
  VertScrollBar.Left := ActiveRect.Right;
  VertScrollBar.Height := ActiveRect.Bottom;
end;

procedure TCustomBarControl.VertScrollbarScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if ScrollPos <> vertScrollBar.Position then
  begin
    fTrackerX := -1;
    Invalidate;
    if Assigned (fOnScroll) then fOnScroll (sender, ScrollCode, ScrollPos)
  end
end;

procedure TCustomBarControl.WMEraseBkgnd(var Message: TWmEraseBkgnd);
var
  SnibRect : TRect;
  Brush : TBrush;
begin
  Brush := TBrush.Create;
  Brush.Color := clBtnFace;

  SnibRect.Left := ActiveRect.Right;
  SnibRect.Top := ActiveRect.Bottom;
  SnibRect.Right := Width;
  SnibRect.Bottom := Height;
  FillRect (Message.DC, SnibRect, Brush.Handle);

  SnibRect.Top := SnibRect.Bottom;
  SnibRect.Bottom := ActiveRect.Bottom;
  FillRect (Message.DC, SnibRect, Brush.Handle);

  Message.Result := 1;
end;

procedure TCustomBarControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TCustomBarControl.WMKeyDown(var Message: TMessage);
begin
  inherited;
  with Message do
  case wParam of
    VK_UP, VK_DOWN : VertScrollBar.Perform (Msg, wParam, lParam);
    VK_LEFT, VK_RIGHT, VK_HOME, VK_END : HorzScrollBar.Perform (Msg, wParam, lParam);
  end
end;

procedure TCustomBarControl.WMLButtonDown(var Message: TWmLButtonDown);
begin
  if Assigned (fOnStartSelection) then
    OnStartSelection (self, CalcPosFromX (SmallPointToPoint (message.pos).x));
  inherited;
end;

procedure TCustomBarControl.WMLButtonUp(var Message: TWmLButtonDown);
begin
  if Assigned (fOnEndSelection) then
    OnEndSelection (self, CalcPosFromX (SmallPointToPoint (message.pos).x));
  inherited;
end;

procedure TCustomBarControl.WMMouseActivate(var Message: TMessage);
begin
  fFullPaint := True;
  Repaint
end;

procedure TCustomBarControl.WMMouseMove(var Message: TWmMouseMove);
begin
  CursorMoved (SmallPointToPoint (Message.pos));
  inherited;
end;

procedure TCustomBarControl.WMPaint(var Msg: TWMPaint);
var
  DC: HDC;
  PS: TPaintStruct;
  saveIndex : Integer;
begin
  DC := Msg.DC;
  if DC = 0 then DC := BeginPaint(Handle, PS);
  try
    SaveIndex := SaveDC(DC);
    try
      fCanvas.Lock;
      try
        fCanvas.Handle := DC;
        try
          Paint;
        finally
          fCanvas.Handle := 0
        end
      finally
        fCanvas.Unlock
      end
    finally
      RestoreDC(DC, SaveIndex)
    end
  finally
    if Msg.DC = 0 then EndPaint(Handle, PS);
  end
end;

procedure TCustomBarControl.WMSize(var Message: TWMSize);
begin
  inherited;
  ActiveRect := ClientRect;
  Dec (ActiveRect.Bottom, GetSystemMetrics (SM_CYHSCROLL));
  Dec (ActiveRect.right, GetSystemMetrics (SM_CXVSCROLL));
  UpdateScrollBars;
end;

{ TBar }

procedure TBar.Assign(Position, BeatsPerBar, BeatDiv, x,
  BeatWidth: Integer);
begin
  fPosition := Position;
  fBeatsPerBar := BeatsPerBar;
  fBeatDiv := BeatDiv;
  fx := x;
  fBeatWidth := BeatWidth
end;

end.

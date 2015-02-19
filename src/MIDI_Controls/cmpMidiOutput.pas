unit cmpMidiOutput;

(*===========================================================================*
 | Midi Output Component for Delphi 3.0                                      |
 |                                                                           |
 | Copyright (c) Colin Wilson 1996.  All rights reserved.                    |
 |                                                                           |
 | nb.  Caches output ports, so the same port can be opened more than once.  |
 |                                                                           |
 | Version  Date      By    Description                                      |
 | -------  --------  ----  -------------------------------------------------|
 | 1.0      26/8/96   CPWW  Original                                         |
 | 1.01     27/1/98   CPWW  Fixed bug in 'AllNotesOff'.  Better Controller   |
 |                          defaults.  (Thanks to Remko Kramer)              |
 *===========================================================================*)

interface

uses
  Windows, Messages, SysUtils, Classes, Forms, MMSystem, cmpInstrument, unitMidiGlobals;

const

//-------------------------------------------------------------------------
// Default values for controllers...
 ControllerDefaults : array [TController] of Integer = (
   0, 0, 0, 0, 0, 0, 0, 90 {Volume} , 0, 0, 64 {Pan }, 127 {Expression}, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
 );

type

TMidiOutputPort = class;

TPhysicalOutputPort = class
private
  Handle : HMIDIOUT;
  PortID : Integer;
  PortNo : Integer;       // Index in port list
  UserList : TList;
  CurrentBank : array [TChannel] of TBankNo;
  CurrentPatch : array [TChannel] of TPatchNo;
  ControllerArray : array [TChannel, TController] of Integer;
  procedure ResetControllers;
  procedure PatchChange (bank : TBankNo; patch : TPatchNo; channel : TChannel);

  constructor Create (pID : Integer; user : TMidiOutputPort);
  procedure RemoveUser (user : TMidiOutputPort);
  procedure AddUser (user : TMidiOutputPort);
  public
  destructor Destroy; override;
end;

(*--------------------------------------------------------------------------*
 | TMidiOutputPort.                                                         |
 |                                                                          |
 | A virtual MIDI output port.                                              |
 |                                                                          |
 | Properties:                                                              |
 |  (published) property PortId : Integer  // The MIDI port number          |
 |  (published) property Active : boolean  // Turns on or off the port.     |
 |  (public)    property Handle : HMIDIOUT // (ro) - The port handle        |
 |                                                                          |
 | Methods:                                                                 |
 |   (public) procedure OutEvent (const Event : TEventData);                |
 |   (   "  ) AllNotesOff;                                                  |
 |   (   "  ) procedure ResetControllers;                                   |
 |                                                                          |
 |                                                                          |
 |    (prot ) procedure midiOutCallback (uMsg : UINT; dw1, dw2 : LongInt);  |
 |            virtual;                                                      |
 *--------------------------------------------------------------------------*)

  TMidiOutputPort = class(TComponent)
  private
    fPortID : Integer;
    fPhysicalPort : TPhysicalOutputPort;
    fSysexHeaders : TList;

    userNo : Integer;

    NoteArray : array [TChannel, TNote] of Integer;
    fSysexLatency: Integer;

    procedure SetPortId (value : Integer);
    procedure SetActive (value : boolean);
    function getActive : boolean;
    function GetHandle : HMidiOut;
    procedure TidySysexHeaders;

  protected
    procedure midiOutCallback (uMsg : UINT; dw1, dw2 : LongInt); virtual;
    { Protected declarations }
  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    property Handle : HMIDIOUT read GetHandle;
    procedure OutSysex (data : PChar; len : word);
    procedure OutEvent (const Event : TEventData);
    procedure AllNotesOff;
    procedure ResetControllers;
    function GetPatch (bank : TBankNo; Patch : TPatchNo) : TPatch;
    procedure PatchChange (bank : TBankNo; patch : TPatchNo; channel : TChannel);
    procedure NoteOn (channel, note, velocity : Integer);
    procedure NoteOff (channel, note, velocity : Integer);
    procedure WaitForSysex;

  published
    property PortId : Integer read fPortID write SetPortId;
    property Active : boolean read GetActive write SetActive;
    property SysexLatency : Integer read fSysexLatency write fSysexLatency default 50;
  end;

  EMidiOutputPort = class (Exception);

procedure SetOutputPrtInstrument (id : Integer; instrument : TInstrument);

implementation

var
  PortList : TList;
  instrumentCache : array [0..7] of TInstrument;

procedure SetOutputPrtInstrument (id : Integer; instrument : TInstrument);
begin
  instrumentCache [id] := instrument;
end;

procedure MidiOutCallback (handle : HMIDIOUT; uMsg : UINT; dwUser, dw1, dw2 : DWORD); stdcall;
var
  portNo, userNo : word;
  port : TPhysicalOutputPort;
  instance : TMidiOutputPort;
begin
  portNo := LoWord (dwUser);
  userNo := HiWord (dwUser);
  port := TPhysicalOutputPort (PortList.Items [portNo]);
  instance := port.UserList.Items [userNo];
  instance.MidiOutCallback (uMsg, dw1, dw2);
end;

constructor TPhysicalOutputPort.Create (pID : Integer; user : TMidiOutputPort);
var chan : TChannel;
begin
  inherited Create;
  portID := pID;
  if not Assigned (PortList) then PortList := TList.Create;
  PortNo := PortList.Count;
  PortList.Add (self);
  UserList := TList.Create;
  AddUser (user);

  for chan := Low (TChannel) to High (TChannel) do
  begin
    Move (ControllerDefaults [0], ControllerArray [chan, 0], sizeof (Integer) * High (TController));
    CurrentPatch [chan] := 0;
    CurrentBank [chan] := 127;
  end;

  if midiOutOpen (@Handle, portID, DWORD (@MidiOutCallback), MAKELONG (word (PortNo), word (user.userNo)), CALLBACK_FUNCTION) <> MMSYSERR_NOERROR then
    raise EMidiOutputPort.Create ('Unable to open port');
end;

destructor TPhysicalOutputPort.Destroy;
var
  i : Integer;
  keepList : boolean;
begin
  midiOutReset (Handle);
  Application.ProcessMessages;
  midiOutClose (Handle);
  Application.ProcessMessages;
  keepList := False;

  PortList [PortNo] := Nil;

  for i := 0 to PortList.Count - 1 do
    if PortList.items [i] <> Nil then
    begin
      keepList := True;
      break
    end;

  if not KeepList then
  begin
    PortList.Free;
    PortList:= Nil
  end;
  UserList.Free;
  inherited
end;

constructor TMidiOutputPort.Create (AOwner : TComponent);
begin
   inherited Create (AOwner);
   fSysexHeaders := TList.Create;
   fSysexLatency := 50;
end;

destructor TMidiOutputPort.Destroy;
begin
  Active := False;
  WaitForSysex;
  inherited
end;

procedure TPhysicalOutputPort.RemoveUser (user : TMidiOutputPort);
var
  stillInUse : boolean;
  i : Integer;
begin
  stillInUse := False;
  for i := 0 to UserList.Count - 1 do
    if (UserList.items [i] <> Nil) and (i <> user.userNo) then
    begin
      stillInUse := True;
      break
    end;

  if not stillInUse then
  begin
    if user.userNo <> 0 then UserList.Items [0] := userList.Items [user.userNo];
    Free
  end
  else UserList.Items [user.userNo] := Nil;
end;


procedure TPhysicalOutputPort.AddUser (user : TMidiOutputPort);
var
  slotNo, i : Integer;
begin
  slotNo := -1;
  for i := 0 to UserList.Count - 1 do
    if not Assigned (userList.Items [i]) then
    begin
      slotNo := i;
      break
    end;

  if slotNo <> -1 then
  begin
    UserList.Items [slotNo] := user;
    user.userNo := slotNo
  end
  else
  begin
    user.userNo := UserList.Count;
    UserList.Add (user)
  end
end;

procedure TMidiOutputPort.SetPortId (value : Integer);
var oldActive : boolean;
begin
  if value <> fPortID then
  begin
    oldActive := Active;
    Active := False;
    fPortID := value;
    Active := oldActive
  end
end;

function TMidiOutputPort.GetActive : boolean;
begin
  result := Assigned (fPhysicalPort)
end;

procedure TMidiOutputPort.SetActive (value : boolean);
var
  i : Integer;
begin
  if value <> Active then
  case value of
    True :
      begin
        // Try to find the required physical output port in the port list
        if Assigned (PortList) then
          for i := 0 to PortList.Count - 1 do
            if Assigned (PortList.Items [i]) then
              with TPhysicalOutputPort (PortList.Items [i]) do if PortID = self.PortID then
                begin
                  fPhysicalPort := TPhysicalOutputPort (PortList.Items [i]);
                  break
                end;


        // Create the physical port of not found (this adds it to the port list)
        if not Assigned (fPhysicalPort) then
          fPhysicalPort := TPhysicalOutputPort.Create (fPortID, self)
        else
          fPhysicalPort.AddUser (self)

        // Add ourself to the port's user list.  If we're the last user of the
        // port, free the port.
      end;
    False :
      begin
        AllNotesOff;
        ResetControllers;
        // Remove ourself from the port's user list.
        fPhysicalPort.RemoveUser (self);
        fPhysicalPort := Nil
      end
  end
end;

function TMidiOutputPort.GetHandle : HMidiOut;
begin
  if Active then
    result := fPhysicalPort.Handle
  else
    result := 0;
end;

procedure TMidiOutputPort.midiOutCallback (uMsg : UINT; dw1, dw2 : LongInt);
begin
end;

(*----------------------------------------------------------------------*
 | procedure TMidiOutputPort.OutEvent ()                                |
 |                                                                      |
 | Send an event to a port.  Keep track of note-ons/note-offs, and      |
 | controller changes so they can be reset                              |
 *----------------------------------------------------------------------*)
procedure TMidiOutputPort.OutEvent (const Event : TEventData);
var channel : byte;
begin
  if Assigned (fPhysicalPort) then with Event do
  begin
    if status < midiSysex then
    begin
      midiOutShortMsg (handle, PInteger (@status)^);
      channel := status and midiChannelMask;

      case status and midiStatusMask of
        midiNoteOn :        // Note on  (but it's a note-off if the
                            // velocity's 0
          begin
            if b3 = 0 then  // It's a note-off after all...
            begin
              if NoteArray [channel, b2] > 0 then
                Dec (NoteArray [channel, b2])
            end
            else Inc (NoteArray [channel, b2])
          end;

        midiNoteOff : if NoteArray [channel, b2] > 0 then Dec (NoteArray [channel, b2]);

        midiController : fPhysicalPort.ControllerArray [channel, b2] := b3;

        midiProgramChange : fPhysicalPort.CurrentPatch [channel] := b2
      end
    end
  end
end;

(*----------------------------------------------------------------------*
 | procedure TMidiOutputPort.AllNotesOff ()                             |
 |                                                                      |
 | Turn all notes off for a virtual port                                |
 *----------------------------------------------------------------------*)
procedure TMidiOutputPort.AllNotesOff;
var
  channel : TChannel;
  Note : TNote;
  Event : TEventData;

begin
  for channel := Low (TChannel) to High (TChannel) do
  begin
    Event.Status := midiNoteOff + channel;
    Event.b3 := 0;
    for Note := Low (TNote) to High (TNote) do
    begin
      event.b2 := note;
      while NoteArray [channel, note] > 0 do
        OutEvent (event)
    end
  end;

  if Assigned (fPhysicalPort) then
    for channel := Low (TChannel) to High (TChannel) do
      if fPhysicalPort.ControllerArray [channel, 64] <> ControllerDefaults [64] then
      begin
        Event.b3 := ControllerDefaults [64];
        Event.Status := midiController + channel;  // Reset sostenuto
        event.b2 := 64;
        OutEvent (event)
      end
end;

procedure TPhysicalOutputPort.ResetControllers;
var
  channel : TChannel;
  Controller : TController;
  Event : TEventData;
begin
  for channel := Low (TChannel) to High (TChannel) do
  begin
    Event.Status := midiController + channel;
    for Controller := Low (TController) to High (TController) do
      if ControllerArray [channel, controller] <> ControllerDefaults [controller] then
      begin
        event.b2 := controller;
        event.b3 := ControllerDefaults [controller];
        midiOutShortMsg (handle,PInteger (@event.status)^);
        ControllerArray [channel, controller] := ControllerDefaults [controller];
      end
  end
end;

procedure TMidiOutputPort.ResetControllers;
begin
  if Active then fPhysicalPort.ResetControllers
end;

function TMidiOutputPort.GetPatch (bank : TBankNo; Patch : TPatchNo) : TPatch;
var
  i : Integer;
begin
  with instrumentCache [PortID] do
    for i := 0 to ComponentCount - 1 do
      with Components [i] as TPatch do
        if (BankNo = bank) and (PatchNo = patch) then
        begin
          result := TPatch (Components [i]);
          exit
        end;
  result := Nil
end;

procedure TPhysicalOutputPort.PatchChange (bank : TBankNo; patch : TPatchNo; channel : TChannel);
var
  event : TEventData;
  bankChanged : boolean;
begin
  if (bank <> CurrentBank [channel]) and Assigned (InstrumentCache [PortID]) then
  begin
    bankChanged := True;
    CurrentBank [channel] := bank;
    with instrumentCache [PortID].fBankChangeRec do
    case bcType of
      bcControl :
        begin
          Event.status := midiController + Channel;
          Event.b2 := Control;
          Event.b3 := bank;
          midiOutShortMsg (handle, PInteger (@event.status)^);
        end;
      bcProgramChange :
        if bank < 8 then           // Only support 8 banks as program changes - TG77, etc.
        begin
          Event.status := midiProgramChange + Channel;
          Event.b2 := programOffsets [bank];
          Event.b3 := 0;
          midiOutShortMsg (handle, PInteger (@event.status)^)
        end
    end
  end
  else bankChanged := False;

  if bankChanged or (patch <> CurrentPatch [channel]) then
  begin
    Event.status := midiProgramChange + Channel;
    Event.b2 := Patch;
    Event.b3 := 0;
    CurrentPatch [channel] := patch;
    midiOutShortMsg (handle, PInteger (@event.status)^);
  end
end;

procedure TMidiOutputPort.NoteOn (channel, note, velocity : Integer);
var
  event : TEventData;
begin
  Event.status := midiNoteOn + Channel;
  Event.b2 := note;
  Event.b3 := velocity;
  OutEvent (event);
end;

procedure TMidiOutputPort.NoteOff (channel, note, velocity : Integer);
var
  event : TEventData;
begin
  Event.status := midiNoteOff + Channel;
  Event.b2 := note;
  Event.b3 := velocity;
  OutEvent (event);
end;

procedure TMidiOutputPort.PatchChange (bank : TBankNo; patch : TPatchNo; channel : TChannel);
begin
  if Active then fPhysicalPort.PatchChange (bank, patch, channel);
end;

procedure CloseAllPhysicalPorts;
var i : Integer;
begin
  if Assigned (PortList) then
    for i := 0 to PortList.Count - 1 do
      if PortList.items [i] <> Nil then
        with TPhysicalOutputPort (PortList.items [i]) do
          Free
end;

procedure TMidiOutputPort.OutSysex(data: PChar; len: word);
var
  hdr : PMidiHdr;
begin
  TidySysexHeaders;
  GetMem (hdr, sizeof (TMidiHdr));
  ZeroMemory (hdr, sizeof (TMidiHdr));
  GetMem (hdr^.lpData, len);
  hdr^.dwBufferLength := len;
  Move (data^, hdr^.lpData^, len);
  fSysexHeaders.Add (hdr);

  midiOutPrepareHeader (handle, hdr, sizeof (hdr^));
  midiOutLongMsg (handle, hdr, sizeof (hdr^));
end;

procedure TMidiOutputPort.TidySysexHeaders;
var
  i : Integer;
  hdr : PMidiHdr;
begin
  i := 0;
  while i < fSysexHeaders.Count do
  begin
    hdr := PMidiHdr (fSysexHeaders [i]);
    if (hdr^.dwFlags and MHDR_DONE) = MHDR_DONE then
    begin
      MidiOutUnprepareHeader (handle, hdr, sizeof (hdr^));
      FreeMem (hdr^.lpData);
      fSysexHeaders.Delete (i)
    end
    else
      Inc (i)
  end
end;

procedure TMidiOutputPort.WaitForSysex;
begin
  repeat
    TidySysexHeaders;
    Sleep (fSysexLatency);
  until fSysexHeaders.Count = 0;
end;

initialization
finalization
  CloseAllPhysicalPorts;
end.

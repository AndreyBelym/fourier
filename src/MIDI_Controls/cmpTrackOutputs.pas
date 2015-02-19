(*===========================================================================*
 | Track Outputs Component for Delphi 3.0                                    |
 |                                                                           |
 | Copyright (c) Colin Wilson 1996-1997.  All rights reserved.               |
 |                                                                           |
 | Version  Date      By    Description                                      |
 | -------  --------  ----  -------------------------------------------------|
 | 1.7      21/2/98   CPWW  TrackOutput class added                          |
 *===========================================================================*)

unit cmpTrackOutputs;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, cmpMidiOutput, cmpMidiData, unitMidiTrackStream, unitMidiGlobals;

type

//
// TTrackOutput class.  Handles track/output port and playback context.
//

  TTrackOutput = class (TComponent)
  private
    fTrackData : TMidiTrackStream;
    fPort : TMidiOutputPort;
    fEventIndex : Integer;
    fMute: boolean;

    procedure Open (data : TMidiTrackStream; OutputPortNo : Integer);
    procedure Close;

    procedure SetPortID (value : Integer);
    function GetPortID : Integer;
    procedure SetMute(const Value: boolean);

  public
    destructor Destroy; override;
    procedure SetPatchForPosition;
    property Port : TMidiOutputPort read fPort;
    property PortID : Integer read GetPortID write SetPortID;
    property EventIndex : Integer read fEventIndex write fEventIndex;
    property TrackData : TMidiTrackStream read fTrackData;
    property Mute : boolean read fMute write SetMute;
  end;

//
// TTrackOutputs class.  Handles output for the tracks.
//

  TOnEvent=procedure(Sender : TObject; port : Integer; data : TEventData) of object;

  TTrackOutputs = class(TComponent)
  private
    fActive : boolean;
    fMidiData : TMidiData;
    fDefaultOutputPort : Integer;
    fOnEvent : TOnEvent;

    function GetNoTracks : Integer;
    function GetTrackOutput (index : Integer) : TTrackOutput;
    procedure SetMidiData (value : TMidiData);
    procedure SetActive (value : boolean);

    procedure Open;
    procedure Close;

  protected

  public
    procedure AllNotesOff;
    procedure ResetAllControllers;
    property NoTracks : Integer read GetNoTracks;
    property TrackOutput [index : Integer] : TTrackOutput read GetTrackOutput; default;
    function GetTrackPortID (trackNo : Integer) : Integer;
    procedure OpenTrack (data : TMidiTrackStream; prtID : Integer);
    procedure ResetEventIndexes;
    procedure SetPatchForPosition;
    function IndexOf (data : TMidiTrackStream) : Integer;

  published
    property DefaultOutputPort : Integer read fDefaultOutputPort write fDefaultOutputPort;
    property MidiData : TMidiData read fMidiData write SetMidiData;
    property Active : boolean read fActive write SetActive;
    property OnEvent : TOnEvent read fOnEvent write fOnEvent;
  end;

implementation

function TTrackOutputs.GetNoTracks : Integer;
begin
  result := ComponentCount;
end;

function TTrackOutputs.GetTrackOutput (index : Integer) : TTrackOutput;
begin
  if index < ComponentCount then
    result := TTrackOutput (Components [index])
  else
    result := Nil;
end;

procedure TTrackOutputs.SetMidiData (value : TMidiData);
var
  OldActive : boolean;
begin
  if value <> fMidiData then
  begin
    OldActive := Active;
    Active := False;
    fMidiData := Value;
    Active := OldActive
  end
end;

procedure TTrackOutputs.SetActive (value : boolean);
begin
  if value <> fActive then
  begin
    fActive := value;
    if fActive then
      Open
    else
      Close
  end
end;

procedure TTrackOutputs.Open;
var
  i : Integer;
begin
  with fMidiData do
    for i := 0 to NoTracks - 1 do
      OpenTrack (Tracks [i], DefaultOutputPort)
end;

procedure TTrackOutputs.OpenTrack (data : TMidiTrackStream; prtID : Integer);
begin
  with TTrackOutput.Create (self) do
    Open (data, prtID);
end;

procedure TTrackOutputs.Close;
begin
  while ComponentCount > 0 do
    Components [0].Free
end;

procedure TTrackOutputs.AllNotesOff;
var
  i : Integer;
begin
  for i := 0 to NoTracks - 1 do
    TrackOutput [i].Port.AllNotesOff;
end;

procedure TTrackOutputs.ResetAllControllers;
var
  i : Integer;
begin
  for i := 0 to NoTracks - 1 do
    TrackOutput [i].Port.ResetControllers;
end;

function TTrackOutputs.GetTrackPortID (trackNo : Integer) : Integer;
begin
  if trackNo < NoTracks then
    result := TrackOutput [trackNo].Port.PortId
  else
    result := DefaultOutputPort;
end;

procedure TTrackOutputs.ResetEventIndexes;
var
  i : Integer;
begin
  for i := 0 to NoTracks - 1 do
    TrackOutput [i].EventIndex := 0
end;

procedure TTrackOutputs.SetPatchForPosition;
var
  i : Integer;
begin
  for i := 0 to NoTracks - 1 do
    TrackOutput [i].SetPatchForPosition
end;

function TTrackOutputs.IndexOf (data : TMidiTrackStream) : Integer;
var
  i : Integer;
begin
  result := -1;
  for i := 0 to NoTracks -1 do
    if TrackOutput [i].TrackData = data then
    begin
      result := i;
      break
    end
end;

destructor TTrackOutput.Destroy;
begin
  Close;
  inherited
end;

procedure TTrackOutput.Open (data : TMidiTrackStream; OutputPortNo : Integer);
begin
  fPort := TMidiOutputPort.Create (self);
  fTrackData := data;
  fEventIndex := 0;
  fPort.PortID :=OutputPortNo;
  fPort.Active := True
end;

procedure TTrackOutput.Close;
begin
  fPort.Free
end;

procedure TTrackOutput.SetPatchForPosition;
begin
  with fTrackData do
    fPort.PatchChange (bank, patch, channel)
end;

procedure TTrackOutput.SetPortID (value : Integer);
begin
  fPort.PortID := value;
end;

function TTrackOutput.GetPortID : Integer;
begin
  result := fPort.PortID;
end;

procedure TTrackOutput.SetMute(const Value: boolean);
begin
  if fMute <> value then
  begin
    if value then
      Port.AllNotesOff;
    fMute := Value
  end
end;

end.


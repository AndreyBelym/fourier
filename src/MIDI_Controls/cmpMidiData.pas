(*===========================================================================*
 | Midi Data Component for Delphi 3.0                                        |
 |                                                                           |
 | Copyright (c) Colin Wilson 1996-1997.  All rights reserved.               |
 |                                                                           |
 | Version  Date      By    Description                                      |
 | -------  --------  ----  -------------------------------------------------|
 | 1.5      19/2/97   CPWW  Original                                         |
 | 1.51     14/9/97   CPWW  Fixed bug with track name                        |
 | 1.6      11/11/97  CPWW  Riff file reading added                          |
 | 1.7      21/2/98   CPWW  Revised track handling                           |
 *===========================================================================*)

unit cmpMidiData;

interface

uses
  Windows, Messages, SysUtils, Classes, unitMidiGlobals, unitMidiTrackStream;

type
//---------------------------------------------------------------------------
// Type for 'FindEvent'
//   feFirst = find first event at position
//   feLast  = find last event at position
//   feAny   = find any event at position

  SwappedWord = word;

//---------------------------------------------------------------------------
// Midi Data component.
  TMidiData = class(TComponent)
  private
    fTrackList : TList;
    fFileName : string;                   // File (full path) name.
    fHeaderExtra : PChar;                 // Extra bytes from midi file header
    fHeaderExtraSize : LongInt;
    fChanges : boolean;                   // 'Data has changed' flag
    fActive : boolean;                    // True if the data is valid.

    fHeader : packed record               // Midi file header
      format : SwappedWord;
      nTracks : SwappedWord;
      ppqn : SwappedWord;
    end;

    fRiffFlag : boolean;

// Helper functions for properties...

    procedure SetActive (value : boolean);

    function GetPPQN : Integer;           // Unscrambles it from the header
    procedure SetPPQN (value : Integer);

    function GetNoTracks : Integer;       //     "        "   "    "   "

    function GetFileType : Integer;       // Unscrambles it from the 'format' field of the header

    function GetTrack (i : Integer) : TMidiTrackStream;
    function GetShortFileName : string;
    function GetChanges : boolean;
    procedure ClearChanges;


  protected
    procedure ReadHeader (f : TStream);
    procedure ReadTracks (f : TStream);
    procedure WriteHeader (f : TStream);
    procedure WriteTracks ( f : TStream);
    procedure Close;
    procedure Open;

  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;

    procedure New;
    procedure Save;

    property HeaderExtra : PChar read fHeaderExtra;
    property HeaderExtraSize : LongInt read fHeaderExtraSize;

    procedure SetHeaderExtra (value : PChar; size : LongInt);
    procedure RemoveTrack (idx : Integer);
    procedure EraseTrack (idx : Integer);
    function AddNewTrack (i : Integer) : boolean;

    procedure LoadFromStream (data : TStream);

    property NoTracks : Integer read GetNoTracks;
    property FileType : Integer read GetFileType;
    property Changes : boolean read GetChanges;
    property Tracks [index : Integer] : TMidiTrackStream read GetTrack;
    property ShortFileName : string read GetShortFileName;

  published
    property PPQN : Integer read GetPPQN write SetPPQN;
    property FileName : string read fFileName write fFileName;
    property Active : boolean read fActive write SetActive;
  end;

  EMidiData = class (Exception);

implementation

uses cmpriffStream, mmsystem;

(*---------------------------------------------------------------------*
 | constructor TMidiData.Create ();                                    |
 |                                                                     |
 | Create a MidiData component.                                        |
 |                                                                     |
 | Parameters:                                                         |
 |   AOwner : TComponent        // Component's owner                   |
 *---------------------------------------------------------------------*)
constructor TMidiData.Create (AOwner : TComponent);
begin
  inherited Create (AOwner);
  fTrackList := TList.Create;
  fHeader.ppqn := swap (180);        // Set default header record.
  fHeader.format := swap (1);
end;

(*---------------------------------------------------------------------*
 | destructor TMidiData.Destroy;                                       |
 |                                                                     |
 | Delete the data first.                                              |
 *---------------------------------------------------------------------*)
destructor TMidiData.Destroy;
begin
  Close;
  fTrackList.Free;
  inherited Destroy;
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.SetActive ();
 |                                                                     |
 | Activate or deactivate the data.  Load the file if it's being       |
 | activated.  Destroy the data if it's being deactivated.             |
 |                                                                     |
 | Parameters:                                                         |
 |   value : boolean       // New 'active' state.                      |
 *---------------------------------------------------------------------*)
procedure TMidiData.SetActive (value : boolean);
begin
  if value <> fActive then
  begin
    case value of
      True :
        if FileName = '' then
          New                          // Initialise new data
        else
          Open;                        // Load the data
      False :
        Close;                         // Delete the data
    end
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.SetHeaderExtra ();                              |
 |                                                                     |
 | Set extra data in MIDI header rec.                                  |
 |                                                                     |
 | Parameters:                                                         |
 |   value : PChar;                  // The extra data                 |
 |   size : LongInt                  // Size of extra data.            |
 *---------------------------------------------------------------------*)
procedure TMidiData.SetHeaderExtra (value : PChar; size : LongInt);
begin
  if fHeaderExtra <> Nil then        // Free the old extra data
    FreeMem (fHeaderExtra);

  if (value <> Nil) and (size > 0) then
  begin
    fHeaderExtraSize := size;        // Save the data.
    GetMem (fHeaderExtra, size);
    Move (value^, fHeaderExtra^, size);
  end
  else
  begin
    fHeaderExtra := Nil;             // No data to save
    fHeaderExtraSize := 0
  end;
  fChanges := True;
end;

(*---------------------------------------------------------------------*
 | function TMidiData.GetPPQN : Integer;                               |
 |                                                                     |
 | Get resolution of data in PPQN (ticks per crochet)                  |
 |                                                                     |
 | The function returns the resolution.                                |
 *---------------------------------------------------------------------*)
function TMidiData.GetPPQN : Integer;
begin
  result := Swap (fHeader.ppqn);
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.SetPPQN ();                                     |
 |                                                                     |
 | Set the resolution of the data in PPQN (ticks per crochet)          |
 |                                                                     |
 | Parameters:                                                         |
 |   value : Integer                 // The new resoltuion             |
 *---------------------------------------------------------------------*)
procedure TMidiData.SetPPQN (value : Integer);
begin
  if value <> Swap (fHeader.ppqn) then
  begin
    fHeader.ppqn := Swap (value);
    fChanges := True
  end
end;

(*---------------------------------------------------------------------*
 | function TMidiData.GetNoTracks : Integer;                           |
 |                                                                     |
 | Get the number of tracks                                            |
 |                                                                     |
 | The function returns the number of tracks.                          |
 *---------------------------------------------------------------------*)
function TMidiData.GetNoTracks : Integer;
begin
  result := fTrackList.Count
end;

(*---------------------------------------------------------------------*
 | function TMidiData.GetFileType : Integer;                           |
 |                                                                     |
 | Get the file type only file type 1 is supported.                    |
 |                                                                     |
 | The function returns the file type.                                 |
 *---------------------------------------------------------------------*)
function TMidiData.GetFileType : Integer;
begin
  result := Swap (fHeader.format);
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.Close;                                          |
 |                                                                     |
 | Deletes the midi data.  This can cause data logss.  Check the       |
 | Changes property before calling...                                  |
 *---------------------------------------------------------------------*)
procedure TMidiData.Close;
var i : Integer;
begin
  if fHeaderExtra <> Nil then        // Free the extra header info.
  begin
    FreeMem (fHeaderExtra);
    fheaderExtra := Nil
  end;

  for i := 0 to fTrackList.Count - 1 do
    TObject (fTrackList [i]).Free;

  fTrackList.Clear;
                                     // Free the tracks.

                                     // Re-initialise the MIDI header.
  fHeader.ppqn := swap (180);
  fHeader.format := swap (1);
  fHeader.nTracks := swap (0);
  ClearChanges;                      // Clear the changes flag, and make the
  fActive := False                   // data inactive.
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.Open;                                           |
 |                                                                     |
 | Load the MIDI data.                                                 |
 *---------------------------------------------------------------------*)
procedure TMidiData.Open;
var
  f : TStream;
  ext : string;
  p : Integer;
begin
  Close;
  ext := UpperCase (ExtractFileExt (FileName));
  fRiffFlag := (ext = '.RMI') or (ext = '.RIFF');
  if fRiffFlag then
  begin
    f := TRiffFileStream.Create (FileName, fmOpenRead or fmShareDenyWrite);
    with TRiffStream (f) do
    begin
      Descend ('RMID', MMIO_FINDRIFF);
      Descend ('data', MMIO_FINDCHUNK);
    end
  end
  else
  f := TFileStream.Create (FileName, fmOpenRead or fmShareDenyWrite);
  try
    ReadHeader (f);                  // Read the track header
    try
      ReadTracks (f);
      fActive := True;

      if fRiffFlag then     // Always convert to MIDI file for now...
      begin
        p := Pos ('.', FileName);
        if p > 0 then fFileName [p] := #0;
        FileName := PChar (FileName);
        FileName := FileName + '.MID'
      end;


    except                           // We may have allocated memory.  Free it
      Close;                          // with Close
      raise                          // Re-raise the exception
    end
  finally
    f.Free;                          // Get rid of the stream
    ClearChanges
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.Save;                                           |
 |                                                                     |
 | Save the MIDI data.                                                 |
 *---------------------------------------------------------------------*)
procedure TMidiData.Save;
var f : TFileStream;
begin
  f := TFileStream.Create (FileName, fmOpenWrite or fmShareExclusive or fmCreate);
  try
    WriteHeader (f);                 // Write the header.
    WriteTracks (f);                 // Write the tracks.
    ClearChanges
  finally
    f.Free;
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.New;                                            |
 |                                                                     |
 | Initialise new data                                                 |
 *---------------------------------------------------------------------*)
procedure TMidiData.New;
begin
  Close;                            // Delete existing data
  FileName := '';                   // Clear the file name
  fActive := True
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.ReadHeader ();                                  |
 |                                                                     |
 | Read the midi header from the stream.                               |
 |                                                                     |
 | Parameters:                                                         |
 |   f : TStream                     // The stream to read from.       |
 *---------------------------------------------------------------------*)
procedure TMidiData.ReadHeader (f : TStream);
var
  hdr : array [0..3] of char;
  hSize : LongInt;
begin
  f.ReadBuffer (hdr, sizeof (hdr)); // Read the MIDI file signature.
  if StrLComp (hdr, 'MThd', 4) <> 0 then
    raise EMidiData.Create ('Invalid MIDI file ID');

  f.ReadBuffer (hSize, sizeof (hSize));
                                    // Read the header size
  hSize := SwapLong (hSize);
  if hSize < sizeof (fHeader) then
    raise EMidiData.Create ('Invalid MIDI header size');

                                    // Read the MIDI header
  f.ReadBuffer (fHeader, sizeof (fHeader));

  if hSize > sizeof (fHeader) then
  begin                             // Read the extra headr bytes.
    fHeaderExtraSize := hSize - sizeof (fHeader);
    GetMem (fHeaderExtra, fHeaderExtraSize);
    f.ReadBuffer (fHeaderExtra^, fHeaderExtraSize);
  end
  else
  begin                             // No extra header bytes.
   fHeaderExtraSize := 0;
   fHeaderExtra := Nil
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.WriteHeader ();                                 |
 |                                                                     |
 | Write the MIDI header record.                                       |
 |                                                                     |
 | Parameters:                                                         |
 |   f : TStream                     // The stream to write to.        |
 *---------------------------------------------------------------------*)
procedure TMidiData.WriteHeader;
var
  hSize : LongInt;
begin
  f.WriteBuffer ('MThd', 4);         // Write MIDI ID
  hSize := SwapLong (fHeaderExtraSize + sizeof (fHeader));
                                     // Write the header size
  f.WriteBuffer (hSize, sizeof (hSize));
                                     // Write the header data
  f.WriteBuffer (fHeader, sizeof (fHeader));
  if fHeaderExtraSize > 0 then
                                     // Write thea header extra data.
    f.WriteBuffer (fHeaderExtra^, fHeaderExtraSize);
end;


(*---------------------------------------------------------------------*
 | procedure TMidiData.ReadTracks ();                                  |
 |                                                                     |
 | Read the tracks data.  Parse it into our own internal format.       |
 |                                                                     |
 | Parameters:                                                         |
 |   f : TStream                     // The stream to read from.       |
 *---------------------------------------------------------------------*)
procedure TMidiData.ReadTracks (f : TStream);
var
  nTracks, i : Integer;
  track : TMidiTrackStream;
begin
  nTracks := Swap (fHeader.nTracks);
  for i := 0 to nTracks - 1 do
  begin
    track := TMidiTrackStream.Create (100000);  // Reserve 1100000 bytes
    try
      track.LoadFromSMFStream (f);
      fTrackList.Add (track);
    except
      track.Free;
      raise
    end
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.WriteTracks ();                                 |
 |                                                                     |
 | Write data for all tracks                                           |
 |                                                                     |
 | Parameters:                                                         |
 |   f : TStream                     // The stream to write to         |
 *---------------------------------------------------------------------*)
procedure TMidiData.WriteTracks (f : TStream);
var
  i : Integer;
begin
  for i := 0 to NoTracks - 1 do
    Tracks [i].SaveToSMFStream (f);
end;

(*---------------------------------------------------------------------*
 | function TMidiData.GetTrack () : TMidiTrack;                        |
 |                                                                     |
 | Get track 'n'                                                       |
 |                                                                     |
 | Parameters:                                                         |
 |   i : Integer                     // The track to get               |
 |                                                                     |
 | The function returns the specified track                            |
 *---------------------------------------------------------------------*)
function TMidiData.GetTrack (i : Integer) : TMidiTrackStream;
begin
  if i < fTrackList.Count then
    result := TMidiTrackStream (fTrackList [i])
  else
    result := Nil
end;

function TMidiData.AddNewTrack (i : Integer) : boolean;
var
  Track : TMidiTrackStream;
begin
  result := False;
  if (i > 0) and (NoTracks = 0) then
  begin
    AddNewTrack (0);
    result := True
  end;

  track := TMidiTrackStream.Create (100000);
  track.Init;
  fTrackList.Add (track);
  fHeader.nTracks := Swap (NoTracks);
  fChanges := True ;
  result:=true;
end;

(*---------------------------------------------------------------------*
 | function TMidiData.GetShortFileName : string;                       |
 |                                                                     |
 | Gets the short file name for display purposes.                      |
 |                                                                     |
 | The function returns the short file name.                           |
 *---------------------------------------------------------------------*)
function TMidiData.GetShortFileName : string;
begin
  if FileName = '' then
    result := '<Untitled>'
  else
    result := ExtractFileName (FileName)
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.RemoveTrack ();                                 |
 |                                                                     |
 | Completely remove a specified track                                 |
 |                                                                     |
 | Parameters:                                                         |
 |   idx : Integer                   // The track to remove.           |
 *---------------------------------------------------------------------*)
procedure TMidiData.RemoveTrack (idx : Integer);
var track : TMidiTrackStream;
begin
  track := Tracks [idx];
  fChanges := True;
  if idx < NoTracks - 1 then
  begin
    track.Free;
    fTrackList [idx] := TMidiTrackStream.Create (100000);
    track := Tracks [idx];
    track.Init;
  end
  else
  begin
    if Assigned (track) then
    begin
      track.Free;
      fTrackList.Delete (idx)
    end;
    fHeader.nTracks := Swap (NoTracks)
  end
end;

(*---------------------------------------------------------------------*
 | procedure TMidiData.EraseTrack ();                                  |
 |                                                                     |
 | Erase all events from a track except for meta events.               |
 |                                                                     |
 | Parameters:                                                         |
 |   idx : Integer            // The track to remove events from       |
 *---------------------------------------------------------------------*)
procedure TMidiData.EraseTrack (idx : Integer);
begin
  if Assigned (Tracks [idx]) then
    Tracks [idx].EraseNonMetaEvents
end;

function TMidiData.GetChanges : boolean;
var
  i : Integer;
begin
  result := fChanges;
  if not result then
    for i := 0 to NoTracks - 1 do
      if Tracks [i].Changes then
      begin
        result := True;
        break
      end
end;

procedure TMidiData.ClearChanges;
var
  i : Integer;
begin
  fChanges := False;
  for i := 0 to NoTracks -1 do
    Tracks [i].Changes := False
end;

procedure TMidiData.LoadFromStream(data: TStream);
var
  f : TRiffMemoryStream;
  s : TMemoryStream;
  id : array [0..4] of char;
begin
  Active := False;
  if data.Size > 4 then
  begin
    data.Read (id, 4);
    id [4] := #0;
    data.Seek (0, soFromBeginning);
    if CompareText (id, 'RIFF') = 0 then
    begin
      f := Nil;
      s := TMemoryStream.Create;
      try
        s.CopyFrom (data, 0);
        f := TRiffMemoryStream.Create (s.Memory, s.Size);
        f.Descend ('RMID', MMIO_FINDRIFF);
        f.Descend ('data', MMIO_FINDCHUNK);
        ReadHeader (f);                  // Read the track header
        try
          ReadTracks (f);
          fActive := True;
        except
          Close;
          raise
        end
      finally
        s.Free;
        f.Free
      end
    end
    else
    begin
      try
        ReadHeader (data);
        ReadTracks (data);
        fActive := True
      except
        Close;
        raise
      end
    end
  end
end;

initialization
end.

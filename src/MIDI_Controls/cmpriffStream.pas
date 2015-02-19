unit cmpRiffStream;

interface

uses windows, classes, sysutils, mmsystem;

type
TRiffChunkInfo = class
  fID : string;
  fInfo : TMMCKInfo;

  constructor Create (const chunkID : string);
end;

TRiffStream = class (TStream)
private
  fHandle : HMMIO;
  fInfoList : TList;
  function GetChunkType: string;
    function GetChunkSize: integer;

public
  destructor Destroy; override;
  function Read(var Buffer; Count: Longint): Longint; override;
  function Write (const Buffer; count : LongInt) : LongInt; override;
  function Seek (Offset: Longint; Origin: Word): Longint; override;
  procedure Descend (const chunkID : string; flags : Integer);
  procedure Ascend;
  property ChunkType : string read GetChunkType;
  property ChunkSize : integer read GetChunkSize;

end;

TRiffFileStream = class (TRiffStream)
public
  constructor Create (const FileName : string; mode : Integer);
end;

TRiffMemoryStream = class (TRiffStream)
public
  constructor Create (AData : PChar; ADataLen : Integer);
end;

implementation

function mmioFourCCToString (const fourcc : DWORD) : string;
var
  a : array [0..3] of char absolute fourcc;
begin
  result := a [0] + a [1] + a [2] + a [3];
end;

constructor TRiffChunkInfo.Create (const chunkID : string);
begin
  if (Length (ChunkID) <> 4) and (Length (ChunkID) <> 0) then
    raise Exception.Create ('RIFF Chunk ID must be four characters long');

  FillChar (fInfo, Sizeof (fInfo), 0);

  fId := chunkID;
  if (chunkID = 'LIST') or (chunkID = 'RIFF') then
    fInfo.fccType := mmioStringToFourCC (PChar (chunkID), 0)
  else
    if Length (chunkID) = 4 then
      fInfo.ckid := mmioStringToFourCC (PChar (chunkID), 0)

end;

constructor TRiffFileStream.Create (const FileName : string; mode : Integer);
var
  flags : Integer;
begin
  fInfoList := TList.Create;
  if mode = fmCreate then
    flags := MMIO_CREATE
  else
  begin
    if (mode and fmOpenWrite) > 0 then
      flags := MMIO_WRITE
    else
      if (mode and fmOpenReadWrite) > 0 then
        flags := MMIO_READWRITE
      else
        flags := MMIO_READ;

    if (mode and fmShareDenyNone) > 0 then
      flags := flags and MMIO_DENYNONE
    else
      if (mode and fmShareExclusive) > 0 then
      begin
        if (mode and fmShareDenyWrite) > 0 then
          flags := flags and MMIO_DENYREAD
        else
          flags := flags and MMIO_EXCLUSIVE
      end
      else
        if (mode and fmShareDenyWrite) > 0 then
          flags := flags and MMIO_DENYWRITE
  end;

  fHandle := mmioOpen (PChar (fileName), Nil, flags);

  if fHandle = 0 then
    if (flags and MMIO_CREATE) > 0 then
      raise EFCreateError.CreateFmt ('Unable to create %s', [FileName])
    else
      raise EFOpenError.CreateFmt ('Unable to open %s', [FileName]);
end;

destructor TRiffStream.Destroy;
begin
  while fInfoList.Count > 0 do
  begin
    TRiffChunkInfo (fInfoList [0]).Free;
    fInfoList.Delete (0)
  end;
  fInfoList.Free;
  mmioClose (fHandle, 0);
end;

function TRiffStream.Read(var Buffer; Count: Longint) : LongInt;
var
  buff : char absolute buffer;
begin
  result := mmioRead (fHandle, @buff, Count);
  if result = -1 then result := 0
end;

function TRiffStream.Write (const Buffer; count : LongInt) : LongInt;
var
  buff : char absolute buffer;
begin
  result := mmioWrite (fHandle, @buff, Count);
  if result = -1 then result := 0
end;

function TRiffStream.Seek (Offset: Longint; Origin: Word): Longint;
var
  mmOrigin : Integer;
begin
  case Origin of
    soFromBeginning : mmOrigin := SEEK_SET;
    soFromEnd : mmOrigin := SEEK_END;
    soFromCurrent : mmOrigin := SEEK_CUR;
    else mmOrigin := SEEK_SET
  end;

  result := mmioSeek (fHandle, Offset, mmOrigin);
end;

procedure TRiffStream.Descend (const ChunkID : string; flags : Integer);
var
  chunkInfo : TRiffChunkInfo;
  pParentInfo : PMMCKInfo;
begin
  chunkInfo := TRiffChunkInfo.Create (chunkID);
  if fInfoList.Count > 0 then
    pParentInfo := @(TRiffChunkInfo (fInfoList [fInfoList.Count - 1]).fInfo)
  else
    pParentInfo := Nil;

  if mmioDescend (fHandle, @chunkInfo.fInfo, pParentInfo, flags) = MMSYSERR_NOERROR then
  begin
    chunkInfo.fID := mmioFourccToString (chunkInfo.fInfo.fccType);
    fInfoList.Add (chunkInfo)
  end
  else
    raise Exception.CreateFmt ('Unable to descend into ', [ChunkID]);
end;

procedure TRiffStream.Ascend;
var
  chunkInfo : TRiffChunkInfo;
begin
  if fInfoList.Count > 0 then
  begin
    chunkInfo := fInfoList [fInfoList.Count - 1];
    if mmioAscend (fHandle, @chunkInfo.fInfo, 0) = MMSYSERR_NOERROR then
    begin
      chunkInfo.Free;
      fInfoList.Delete (fInfoList.Count - 1)
    end
    else
      raise Exception.CreateFmt ('Unable to ascend from ', [chunkInfo.fID]);
  end
end;
{ TRiffMemoryStream }

constructor TRiffMemoryStream.Create(AData: PChar; ADataLen: Integer);
var
  info : TMMIOInfo;
begin
  fInfoList := TList.Create;
  FillChar (info, SizeOf (info), 0);
  info.fccIOProc := FOURCC_MEM;
  info.pchBuffer := AData;
  info.cchBuffer := ADataLen;
  fHandle := mmioOpen (Nil, @info, MMIO_READ);
end;

function TRiffStream.GetChunkType: string;
begin
  if fInfoList.Count = 0 then
    result := ''
  else
    result := TRiffChunkInfo (fInfoList [fInfoList.Count - 1]).fID
end;

function TRiffStream.GetChunkSize: integer;
begin
  if fInfoList.Count = 0 then
    raise exception.Create ('Can''t get size of non-existant chunk')
  else
    result := TRiffChunkInfo (fInfoList [fInfoList.Count - 1]).fInfo.cksize
end;

end.

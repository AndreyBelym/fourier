unit cmpInstrument;

interface

uses
  Windows, Messages, SysUtils, Classes, unitMidiGlobals;

type
  TBankChangeType = (bcNone, bcControl, bcProgramChange);
  TBankChangeRec = record
  case bcType : TBankChangeType of
    bcControl : (control : TController);
    bcProgramChange : (programOffsets : array [0..7] of byte)
  end;

  TInstrument = class(TComponent)
  private
    fInstrumentName : string;
  protected
    procedure DefineProperties (Filer : TFiler); override;
    procedure GetChildren (Proc : TGetChildProc; Root : TComponent); override; // Grr.  Fixes bug in VCL
    procedure ReadBankChange (Stream : TStream);
    procedure WriteBankChange (Stream : TStream);
  public
    fBankChangeRec : TBankChangeRec;
    { Public declarations }
  published
    property InstrumentName : string read fInstrumentName write fInstrumentName;
    { Published declarations }
  end;

  TPatchType = (ptSynthPad, ptAcousticPiano, ptBrass, ptElectricPiano, ptMusicalEffect, ptWoodwind, ptStrings, ptBass, ptSynthComp, ptSynthLead, ptKeyboard, ptPlucked, ptOrgan, ptPercussion, ptChoir, ptSoundEffects, ptDrums);


  TPatch = class (TComponent)
  private
    fBankNo : TBankNo;
    fPatchNo : TPatchNo;
    fPatchName : string;
    fComment : string;
    fDefaultChannel : TChannel;
    fMandatoryChannel : TChannel;
    fDefaultVolume : TControllerValue;
    fPatchType : TPatchType;
  protected
  public
  published
    property BankNo : TBankNo read fBankNo write fBankNo;
    property PatchNo : TPatchNo read fPatchNo write fPatchNo;
    property PatchName : string read fPatchName write fPatchName;
    property Comment : string read fComment write fComment;
    property DefaultChannel : TChannel read fDefaultChannel write fDefaultChannel;
    property MandatoryChannel : TChannel read fMandatoryChannel write fMandatoryChannel;
    property DefaultVolume : TControllerValue read fDefaultVolume write fDefaultVolume;
    property PatchType : TPatchType read fPatchType write fPatchType;
  end;

const
  PatchTypeNames : array [Low (TPatchType)..High (TPatchType)] of string =
   ('Synth Pad', 'Acoustic Piano', 'Brass', 'Electric Piano', 'Musical Effect', 'Winds',
    'Strings', 'Basses', 'Synth Comp', 'Synth Lead', 'Plucked', 'Keyboards', 'Organ',
    'Percussion', 'Choir', 'Sound Effects', 'Drum Voices');

implementation

procedure TInstrument.ReadBankChange (Stream : TStream);
begin
  Stream.ReadBuffer (fBankChangeRec, sizeof (fBankChangeRec));
end;

procedure TInstrument.WriteBankChange (Stream : TStream);
begin
  Stream.WriteBuffer (fBankChangeRec, sizeof (fBankChangeRec));
end;

procedure TInstrument.DefineProperties (Filer : TFiler);
begin
  inherited DefineProperties (Filer);
  Filer.DefineBinaryProperty ('BankChangeRec', ReadBankChange, WriteBankChange, True);
end;

 // Grr.  Fixes bug in VCL


procedure TInstrument.GetChildren (Proc : TGetChildProc; Root : TComponent);
var i : Integer;
begin
  for i := 0 to ComponentCount - 1 do
    proc (Components [i])
end;

begin
  RegisterClasses ([TInstrument, TPatch]);
end.


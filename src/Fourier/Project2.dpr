program Project2;

{$APPTYPE CONSOLE}

uses
  SysUtils,ModuleComplex,ModuleFFT;

var fourier,temp:TCmxArray; fexp:TCmxArray; index:TIndexArray;
  i:integer;  t:TComplex;
begin
  setlength(fourier,16);
  fexp:=GetFFTExpTable(16); index:=GetArrayIndex(16);
   for i:=0 to 15 do begin
      fourier[i].Re:=index[i];
      Fourier[i].Im:=0
   end;
   FFT(fourier,fexp);
   temp:=copy(fourier,0,16);
   for i:= 0 to 15 do begin
       fourier[i]:=temp[index[i]];
   end;
   fexp:=GetFFTExpTable(16,True);
   FFT(fourier,fexp);
   for i:= 0 to 15 do begin
      fourier[i].RE:=fourier[i].Re/16;fourier[i].im:=fourier[i].im/16;
   end;
   for i:= 0 to 15 do
    Writeln(fourier[i].RE,fourier[i].im);
   Readln;
end.

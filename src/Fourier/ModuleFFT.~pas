Unit ModuleFFT;
Interface
Uses ModuleComplex,math;
type TIndexArray  = array of Integer;
function HannWindow(t,N:integer):Extended;
function HammingWindow(t,N:integer):Extended;
function BlackmanWindow(t,N:integer):Extended;
procedure FFT(var D: TCmxArray; const TableExp: TCmxArray);
function GetFFTExpTable(Count:Integer; Inverse:Boolean=False): TCmxArray;
function GetArrayIndex(Count: Integer): TIndexArray;
implementation
function HammingWindow(t,N:integer):Extended;
begin
  result:=0.53836-0.46164*cos(2*pi*t/(N-1));
end;

function HannWindow(t,N:integer):Extended;
begin
  result:=0.5*(1-cos(2*pi*t/(N-1)));
end;

function BlackmanWindow(t,N:integer):Extended;
const a=0.16;
      a0=(1-a)/2;
      a1=1/2;
      a2=a/2;
begin
  result:=a0-a1*cos(2*pi*t/(N-1))+a2*cos(4*pi*t/(N-1));
end;
(*
FFT преобразует массив отчсетов D в массив БПФ с помощью поворачивающих
множителей TableExp.
Параметры:
D: TCmxArray - массив для БПФ
TableExp: TCmxArray - поворачивающие множители
Локальные переменные:
I,J,K,ti:Integer - счётчики для обработки массивов
i_2:Integer - половина значения i
Temp:TComplex -временная перменная
*)
procedure FFT(var D: TCmxArray; const TableExp: TCmxArray);
var
    I,J,K,ti,i_2:Integer;
    Temp:TComplex;
begin
  i := 2;i_2:=i shr 1;
  while i <= Length(D) do
    begin
      ti:= i_2;
      J:=0;
      while J < i_2 do
        begin
          K:=0;
          while k<Length(D) do
            begin
              Temp       := CmpMul(D[k+J+i_2],TableExp[ti]);
              D[k+J+i_2]  := CmpSub(D[k+J],Temp);
              D[k+J]:= CmpAdd(D[k+J],Temp);
              k            := k+i;
            end;
          Inc(ti);
          Inc(J);
        end;
      i_2 := i;
      i  := i shl 1;
    end;
end;
(*
GetFFTExpTable возвращает массив поворачивающих множителей для
преобразования Фурье длиной Count точек. При истинном значении
параметра Inverse получаются множители для обратного БПФ, иначе - для
прямого.
Параметры:
Count:Integer - количество точек БПФ
Inverse:Boolean - тип преобразования: прямое/обратное
Локальные переменные:
j,i:Intege - счётчики для обработки массивов
w:TComplex - текущий рассчитанный множитель,
wn:TComplex - комплексный коэффициент расчета следующего множителя
k:Double - начальный коэффициент расчета
*)
function GetFFTExpTable(Count:Integer; Inverse:Boolean=False): TCmxArray;
var j,i:Integer;
    w,wn:TComplex;
    k:Double;
begin

  k := -2*Pi;

  if Inverse then
     k:= -k;


  SetLength(Result,Count +1);

  i:=1;

  while i <Count do
    begin
      wn.Re := 0;
      wn.Im := k/(i shl 1);
      wn    := CmpExp(wn);
      w.Re     := 1;
      w.Im     :=0;
      For j:=0 to i-1 do
        begin

          Result[i+j]:=w;
          w:=CmpMul(w,wn);
        end;
    i  := i shl 1;
    end;
end;

(*
GetArrayIndex возвращает массив длиной Count, согласно значениям которого
нужно
перемешивать исходные данные БПФ также длины Count.
Параметры:
Count: Integer - количество точек БПФ
Локальные переменные:
I j k k2:Integer - счётчики для обработки массивов
i_2:Integer - половина значения i
Temp:TIndexArray - часть массива для перемешивания
*)
function GetArrayIndex(Count: Integer): TIndexArray;
Var I,i_2,j,k,k2:Integer;
    Temp:TIndexArray;
begin
  SetLength(Result,Count);
  For I:=0 to count-1 do
      Result[I]:=I;
  i   :=Count;
  i_2  :=i shr 1;
  while i > 2 do
    begin
      j:=0;
      Temp :=Copy(Result,0,Count);
      repeat
        k2 :=j;
        for k:=j to j+i_2-1 do
          begin
            Result[k]          :=Temp[k2];
            Result[k+i_2]:=Temp[k2+1];
            k2 :=k2 +2;
          end;
        j:=j+i;
      Until j >= Count;
      i   :=i shr 1;
      i_2  :=i_2 shr 1;
    end;
  Temp:=Nil;
end;

end.

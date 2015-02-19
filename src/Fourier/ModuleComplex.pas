unit ModuleComplex;
{$H+}

interface
uses
   SysUtils,Math;
  {$ifdef ComplexIsSingle}
    const
      MinComplex  =  1.5e-45;
      MaxComplex  =  3.4e+38;

    Type
      PComplex =^TComplex;
      TComplex = record
         Re,
         Im:Single;
    end;// TComplex = record
  {$else}
    const
      MinComplex  =  5.0e-324;
      MaxComplex  =  1.7e+308;

    Type
      PComplex =^TComplex;
      TComplex = record
         Re,
         Im:Double;
    end;// TComplex = record
  {$endif}
    type
      TCmxArray    = array of TComplex;
    
    function CmpAdd(const a,b:TComplex):TComplex;
    function CmpSub(const a,b:TComplex):TComplex;
    function CmpMul(const a,b:TComplex):TComplex;
    function CmpExp(const X:TComplex): TComplex;
    //function CmpSub(const a,b:TComplex):TComplex;
implementation
    function CmpAdd;
    var c:TComplex;
    begin
        c.Re:=a.Re+b.Re;
        c.Im:=a.Im+b.Im;
        result:=c;
    end;
    
    function CmpSub;
    var c:TComplex;
    begin
        c.Re:=a.Re-b.Re;
        c.Im:=a.Im-b.Im;
        result:=c;
    end;
    
    function CmpMul;
    var c:TComplex;
    begin
        c.Re:=a.Re*b.Re-a.Im*b.Im;
        c.Im:=a.Re*b.Im+a.Im*b.Re;
        result:=c;
    end;
    function CmpExp(const X:TComplex): TComplex; 
var TempExp:Real;
    ImCos,ImSin:Extended;
begin
  TempExp:=Exp(X.Re);
  SinCos(X.Im,ImSin,ImCos);
  Result.Re:=TempExp*ImCos;
  Result.Im:=TempExp*ImSin;
end;
end.


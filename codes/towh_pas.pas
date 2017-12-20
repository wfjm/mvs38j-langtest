(* $Id: towh_pas.pas 964 2017-11-19 08:47:46Z mueller $ *)
(*
(* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> *)
(*
(* This program is free software; you may redistribute and/or modify *)
(* it under the terms of the GNU General Public License version 3.   *)
(* See Licence.txt in distribition directory for further details.    *)
(*                                                                   *)
(*  Revision History:                                                *)
(* Date         Rev Version  Comment                                 *)
(* 2017-09-07   948   0.1    Initial version                         *)

program towh(input,output);
var
   ncall,nmove   : integer;
   curstk,maxstk : integer;
   maxdsk,trace  : integer;
   ndsk          : integer;
   tow           : ARRAY[1 .. 3] of integer;

procedure mov(n,f,t: integer); 
var
   o : integer;
begin
   o := 6-(f+t);
   curstk := curstk + 1;
   ncall  := ncall  + 1;
   if maxstk < curstk then maxstk := curstk;
   if n = 1 then begin
      nmove  := nmove + 1;
      tow[f] := tow[f] - 1;
      tow[t] := tow[t] + 1;
      if trace > 0 then writeln(' ','mov-do: ',curstk:2,
                                ' :',n:3,f:3,t:3,
                                ' :',tow[1]:3,tow[2]:3,tow[3]:3);
   end else begin
      if trace > 0 then writeln(' ','mov-go: ',curstk:2,
                                ' :',n:3,f:3,t:3,
                                ' :',tow[1]:3,tow[2]:3,tow[3]:3);
      mov(n-1,f,o);
      mov(1,f,t);
      mov(n-1,o,t);
   end;
   curstk := curstk - 1;
end;

begin
      
   read(maxdsk);
   read(trace);

   for ndsk := 2 to maxdsk do begin
      ncall  := 0;
      nmove  := 0;
      maxstk := 0;
      curstk := 0;
      tow[1] := ndsk;
      tow[2] := 0;
      tow[3] := 0;
      if trace > 0 then  writeln(' ','STRT ndsk=',ndsk:2);
      mov(ndsk,1,3);
      writeln(' ','DONE ndsk=',ndsk:2,': maxstk=',maxstk:2,
              '  ncall=',ncall:10,'  nmove=',nmove:10);
   end;
   
end.

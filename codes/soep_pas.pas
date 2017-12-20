(* $Id: soep_pas.pas 964 2017-11-19 08:47:46Z mueller $ *)
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

program soep(input,output);
label
   999;
var
   nmax,prnt,imax : integer;
   i,n,n2,imin    : integer;
   np,il,nl       : integer;
   sieve          : ARRAY[1 .. 30000] of boolean;
   
begin
      
   read(nmax);
   read(prnt);

   if (nmax < 10) or (nmax > 60000) then begin
      writeln(' ', 'nmax out of range (10...60000), abort');
      exit(8);
   end;
   
   imax := (nmax-1) div 2;
   for i := 1 to imax do sieve[i] := TRUE;

   n    := 3;
   while n <= nmax do begin
      if sieve[(n-1) div 2] then begin
         n2 := n*n;
         if n2 > nmax then goto 999;
         i := (n2-1) div 2;
         while i <= imax do begin
            sieve[i] := FALSE;
            i := i + n;
         end;
      end;
      n := n + 2;
   end;
   999:
   
   if prnt > 0 then begin
      writeln(' ', 'List of Primes up to ', nmax:8);
      write(2:8);
      np := 1;
      for i := 1 to imax do begin
         if sieve[i] then begin
            write(1+2*i:8);
            np := np + 1;
            if np = 10 then begin
               writeln(' ');
               np := 0;
            end;
         end;
      end;
      if np > 0 then writeln();
   end;

   il :=  4;
   nl := 10;
   np :=  1;
   for i := 1 to imax do begin
      if sieve[i] then np := np + 1;
      if i = il then begin
         nl := 2*il + 2;
         writeln(' ', 'pi(', nl:8, '): ', np:8);
         il := 10*(il+1)-1;
      end;
   end;

   if nl < nmax then writeln(' ', 'pi(', nmax:8, '): ', np:8);
   
end.

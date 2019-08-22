(* $Id: soep_pas.pas 1171 2019-06-28 19:02:57Z mueller $ *)
(* SPDX-License-Identifier: GPL-3.0-or-later                         *)
(* Copyright 2017-2019 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> *)
(*                                                                   *)
(*  Revision History:                                                *)
(* Date         Rev Version  Comment                                 *)
(* 2017-12-25   975   1.2    use sqrt(nmax) as outer loop end        *)
(* 2017-12-25   974   1.1    5M sieve array                          *)
(* 2017-12-23   972   1.0.1  change (n-1)/2 --> n/2                  *)
(* 2017-09-07   948   1.0    Initial version                         *)

program soep(input,output);
var
   nmax,prnt,imax : integer;
   nmsqrt         : integer;
   i,n,imin       : integer;
   np,il,nl       : integer;
   rnmax          : real;
   sieve          : ARRAY[1 .. 5000000] of boolean;
   
begin
      
   read(nmax);
   read(prnt);

   if (nmax < 10) or (nmax > 10000000) then begin
      writeln(' ', 'nmax out of range (10...10000000), abort');
      exit(8);
   end;

   rnmax  := nmax;
   nmsqrt := trunc(sqrt(nmax));
   imax := (nmax-1) div 2;
   for i := 1 to imax do sieve[i] := TRUE;

   n    := 3;
   while n <= nmsqrt do begin
      if sieve[n div 2] then begin
         i := (n*n) div 2;
         while i <= imax do begin
            sieve[i] := FALSE;
            i := i + n;
         end;
      end;
      n := n + 2;
   end;
   
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

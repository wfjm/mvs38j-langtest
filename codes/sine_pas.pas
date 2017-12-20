(* $Id: sine_pas.pas 964 2017-11-19 08:47:46Z mueller $ *)
(*
(* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> *)
(*
(* This program is free software; you may redistribute and/or modify *)
(* it under the terms of the GNU General Public License version 3.   *)
(* See Licence.txt in distribition directory for further details.    *)
(*                                                                   *)
(*  Revision History:                                                *)
(* Date         Rev Version  Comment                                 *)
(* 2017-09-08   949   1.0    Initial version                         *)

program sine(input,output);
var
   i,j,isin,icos    : integer;
   x,xrad,fsin,fcos : real;
   plot             : ARRAY[1 .. 81] of char;
   
begin

   writeln(' ','     x   sin(x)   cos(x)   ',
               '-1                -0.5                  0',
               '                 +0.5                 +1');
   writeln(' ', '                           ',
                '+-------------------.-------------------:',
                 '-------------------.-------------------+');

   for i := 0 to 60 do begin
      x := 6.0 * i;
      xrad := x/57.2957795131;
      fsin := sin(xrad);
      fcos := cos(xrad);
      for j := 1 to 81 do plot[j] := ' ';
      plot[ 1] := '+';
      plot[21] := '.';
      plot[41] := ':';
      plot[61] := '.';
      plot[81] := '+';
      isin := trunc(41.5 + 40.0 * fsin);
      icos := trunc(41.5 + 40.0 * fcos);
      plot[isin] := '*';
      plot[icos] := '#';
      write(' ',x:6:1,fsin:9:5,fcos:9:5,'   ');
      for j := 1 to 81 do write(plot[j]:1);
      writeln(' ');
   end;
   writeln(' ', '                           ',
                '+-------------------.-------------------:',
                 '-------------------.-------------------+');
end.

(* $Id: mcpi_pas.pas 964 2017-11-19 08:47:46Z mueller $ *)
(*
(* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> *)
(*
(* This program is free software; you may redistribute and/or modify *)
(* it under the terms of the GNU General Public License version 3.   *)
(* See Licence.txt in distribition directory for further details.    *)
(*                                                                   *)
(*  Revision History:                                                *)
(* Date         Rev Version  Comment                                 *)
(* 2017-09-17   951   1.0    Initial version                         *)
(* 2017-09-07   948   0.1    First draft                             *)

program mcpi(input,output);
const
   rr32 = 4294967296.0;
   rdiv = 33554432.0;
   pi   = 3.141592653589793;
var
   rseed,rlast          : real;
   ranini               : boolean;
   idbgrr,idbgrn,idbgmc : integer;
   i,ntry,nhit,ngo      : integer;
   piest,pierr          : real;
   rhit,rtry            : real;
   x,y,r                : real;
   rshuf                : ARRAY[0 .. 127] of real;
   
function ranraw(dummy :real) : real; 
var
   rfac,rnew : real;
begin
   rnew := rseed * 69069.0;
   rfac := rnew / rr32;
   rfac := trunc(rfac);
   rnew := rnew - rfac * rr32;
   if idbgrr > 0 then writeln(' ','RR: ',rseed:14:1,rnew:14:1);
   rseed := rnew;
   ranraw := rnew;
end;

function rannum(dummy :real) : real; 
var
   rnew : real;
   i    : integer;
begin
   if not ranini then begin
      for i := 0 to 127 do rshuf[i] := ranraw(0.0);
      ranini := TRUE;
   end;

   i := trunc(rlast/rdiv);
   rlast := rshuf[i];
   rshuf[i] := ranraw(0.0);
   rnew := rlast/rr32;
   if idbgrn > 0 then writeln(' ','RN: ',i:12,rlast:14:1,rnew:14:8);
   rannum := rnew;
end;

begin
   rseed  := 12345.0;
   ranini := FALSE;
   
   read(idbgrr);
   read(idbgrn);
   read(idbgmc);

   while TRUE do begin
      read(ngo);
      if ngo = 0 then exit(0);
      for i := 1 to ngo do begin
         x := 2.0 * rannum(0.0) - 1.0;
         y := 2.0 * rannum(0.0) - 1.0;
         r := x*x + y*y;
         ntry := ntry + 1;
         if r <= 1.0 then nhit := nhit + 1;
         if idbgmc > 0 then writeln(' ','MC: ',
                                    x:12:8,y:12:8,r:12:8,nhit:12);
      end;

      rtry := ntry;
      rhit := nhit;

      piest := 4.0 * (rhit / rtry);
      pierr := piest - pi;
      writeln(' ','PI: ',ntry:12,nhit:12,piest:12:8,pierr:12:8,
                         rlast:14:1);
   end;

end.

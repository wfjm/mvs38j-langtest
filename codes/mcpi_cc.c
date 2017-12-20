/* $Id: mcpi_cc.c 964 2017-11-19 08:47:46Z mueller $ */
/*
/* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> */
/*
/* This program is free software; you may redistribute and/or modify */
/* it under the terms of the GNU General Public License version 3.   */
/* See Licence.txt in distribition directory for further details.    */
/*                                                                   */
/*  Revision History:                                                */
/* Date         Rev Version  Comment                                 */
/* 2017-08-12   938   1.0    Initial version                         */
/* 2017-07-30   931   0.1    First draft                             */

#include <stdio.h>
#include <stdlib.h>

double rseed = 12345.;
double rlast = 0.;
double rshuf[128];
double rr32 = 4294967296.;                 /* 4*1024*1024*1024 */
double rdiv =   33554432.;                 /* rr32 / 128 */
int ranini = 0;
int idbgrr = 0;
int idbgrn = 0;
int idbgmc = 0;

double ranraw()
{
  double rnew,rnew1;
  double rfac;
  int    ifac;
  rnew1 = rseed * 69069.;
  rfac  = rnew1 / rr32;
  ifac  = rfac;
  rfac  = ifac;
  rnew  = rnew1 - rfac * rr32;
  if (idbgrr) printf("RR: %12.0f %12.0f : %16.0f %9d\n",
                     rseed,rnew, rnew1,ifac);
  rseed = rnew;                    
  return rnew;
}

double rannum()
{
  int i;
  double rnew;

  if (ranini == 0) {
    for (i=0; i<128; i++) rshuf[i] = ranraw();
    ranini = 1;
  }

  i = rlast/rdiv;
  rlast = rshuf[i];
  rshuf[i] = ranraw();
  rnew = rlast/rr32;
  if (idbgrn) printf("RN: %12d %12.0f %12.8f\n", i,rlast,rnew);
  return rnew;
}

int main() 
{
  int i;
  int ntry = 0;
  int nhit = 0;
  int ngo;
  double pi = 3.141592653589793;
  double piest;
  double pierr;

  /* JCC on MVS doesn't skip initial white space, add leading ' ' to force */
  if (scanf(" %d %d %d", &idbgrr, &idbgrn, &idbgmc) != 3) {
    printf("conversion error, abort\n");
    return 1;
  }

  while (scanf(" %d", &ngo) == 1 && ngo > 0) {
    for (i=0; i<ngo; i++) {
      double x,y,r;
      x = 2.*rannum() - 1.;
      y = 2.*rannum() - 1.;
      r = x*x + y*y;
      ntry += 1;
      if (r <= 1.) nhit += 1;
      if (idbgmc) printf("MC: %12.8f %12.8f %12.8f %12d\n", x,y,r,nhit);
    }

    piest = 4. * ((double)nhit / (double)ntry);
    pierr = piest - pi;
    if (pierr < 0.) pierr = -pierr;
    printf("PI: %12d %12d %12.8f %12.8f %12.0f\n",
           ntry, nhit, piest, pierr, rlast);
    
  }
  return 0;
}

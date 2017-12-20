/* $Id: sine_cc.c 964 2017-11-19 08:47:46Z mueller $ */
/*
/* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> */
/*
/* This program is free software; you may redistribute and/or modify */
/* it under the terms of the GNU General Public License version 3.   */
/* See Licence.txt in distribition directory for further details.    */
/*                                                                   */
/*  Revision History:                                                */
/* Date         Rev Version  Comment                                 */
/* 2017-07-30   931   0.1    Initial version                         */

#include <stdio.h>
#include <math.h>

int main () 
{
  char  plot[82];
  int i,j,isin,icos;
  double x,xrad,fsin,fcos;
  char* f1 = "     x   sin(x)   cos(x)   "
             "-1                -0.5                  0"
             "                 +0.5                 +1";
  char* f2 = "                           "
             "+-------------------.-------------------:"
             "-------------------.-------------------:";

  plot[81] = 0;
  printf ("%s\n",f1);
  printf ("%s\n",f2);

  for (i=0; i<=60; i++) {
    x    = 6. * i;
    xrad = x/57.2957795131;
    fsin = sin(xrad);
    fcos = cos(xrad);
    for (j=0; j<81; j++) plot[j] = ' ';
    plot[ 0] = '+';
    plot[20] = '.';
    plot[40] = ':';
    plot[60] = '.';
    plot[80] = '+';
    isin = 40.5 + 40. * fsin;
    icos = 40.5 + 40. * fcos;
    plot[isin] = '*';
    plot[icos] = '#';
    printf("%6.0f %8.5f %8.5f   %s\n", x,fsin,fcos,plot);
  }
  printf ("%s\n",f2);
  return 0;
}

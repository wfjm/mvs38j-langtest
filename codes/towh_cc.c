/* $Id: towh_cc.c 964 2017-11-19 08:47:46Z mueller $ */
/*
/* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> */
/*
/* This program is free software; you may redistribute and/or modify */
/* it under the terms of the GNU General Public License version 3.   */
/* See Licence.txt in distribition directory for further details.    */
/*                                                                   */
/*  Revision History:                                                */
/* Date         Rev Version  Comment                                 */
/* 2017-08-09   934   1.0    Initial version                         */
/* 2017-07-30   931   0.1    First draft                             */

#include <stdio.h>

void mov(int n, int f, int t);

int ncall  =  0;
int nmove  =  0;
int curstk =  0;
int maxstk =  0;
int maxdsk =  0;
int trace  =  0;
int tow[4];

int main(argc, argv)
int     argc;
char    *argv[];
{
  int ndsk;

  /* JCC on MVS doesn't skip initial white space, add leading ' ' to force */
  if (scanf(" %d %d", &maxdsk, &trace) != 2) {
    printf("conversion error, abort\n");
    return 1;
  }

  /* avoid | here, lots of fun with ASCII -> EBCDIC mapping */
  /* if (maxdsk < 2 || maxdsk > 32) { */
  if ((maxdsk < 2) + (maxdsk > 32)) {
    printf("maxdsk out of range (2...32), abort\n");
    return 1;
  }
  
  for (ndsk=2; ndsk<=maxdsk; ndsk++) {
    ncall  = 0;
    nmove  = 0;
    maxstk = 0;
    curstk = 0;
    tow[1] = ndsk;
    tow[2] = 0;
    tow[3] = 0;

    if (trace) printf("STRT ndsk=%2d\n", ndsk);
    mov(ndsk,1,3);
    printf("DONE ndsk=%2d:  maxstk=%2d  ncall=%10d  nmove=%10d\n",
           ndsk,maxstk,ncall,nmove);
  }
  return 0;
}

void mov(int n, int f, int t)
{
  int o = 6-(f+t);
  curstk++;
  ncall++;
  if (curstk > maxstk) maxstk = curstk;
  if(n == 1) {
    nmove++;
    tow[f]--;
    tow[t]++;
    if (trace) printf("mov-do: %2d : %2d %2d %2d : %2d %2d %2d\n",
                      curstk,n,f,t,tow[1],tow[2],tow[3]);
  } else {
    if (trace) printf("mov-go: %2d : %2d %2d %2d : %2d %2d %2d\n",
                      curstk,n,f,t,tow[1],tow[2],tow[3]);
    mov(n-1,f,o);
    mov(1,f,t);
    mov(n-1,o,t);
  }
  curstk--;
  return;
}

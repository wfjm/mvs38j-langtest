/* $Id: soeq_cc.c 972 2017-12-23 20:55:41Z mueller $ */
/*
/* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> */
/*
/* This program is free software; you may redistribute and/or modify */
/* it under the terms of the GNU General Public License version 3.   */
/* See Licence.txt in distribition directory for further details.    */
/*                                                                   */
/*  Revision History:                                                */
/* Date         Rev Version  Comment                                 */
/* 2017-12-23   972   1.1.1  change (n-1)/2 --> n/2                  */
/* 2017-11-20   966   1.1    add LOOKUP,STATISTICS ifdefs            */
/* 2017-11-17   962   1.0    Initial version                         */
/* 2017-10-15   956   0.1    First draft                             */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* #define LOOKUP     */
/* #define STATISTICS */

#ifdef LOOKUP
#define TSTMASK(ind) tstmask[ind]
#define CLRMASK(ind) clrmask[ind]
const unsigned char tstmask[] = {0x01,0x02,0x04,0x08,
                                 0x10,0x20,0x40,0x80};
const unsigned char clrmask[] = {0xfe,0xfd,0xfb,0xf7,
                                 0xef,0xdf,0xbf,0x7f};

#else
#define TSTMASK(ind)  (1<<(ind))
#define CLRMASK(ind) ~(1<<(ind))
#endif

#ifdef STATISTICS
#define SCOUNT(var)  var += 1;
double StatOloop = 0.;
double StatIloop = 0.;
#else
#define SCOUNT(var)
#endif


int main() 
{
  int nmax;
  int nmsqrt;
  int prnt;
  int bimax;
  int wimax;
  int i,n;
  int np,il,nl;
  unsigned char *prime;
  unsigned char *p,*pmax;
  
  /* JCC on MVS doesn't skip initial white space, add leading ' ' to force */
  if (scanf(" %d %d", &nmax, &prnt) != 2) {
    printf("conversion error, abort\n");
    return 1;
  }
  if (nmax < 10) {
    printf("nmax must be >= 10, abort\n");
    return 1;
  }
  
  /* prime:  i=(n-1)/2 --> 3->[1], 5->[2]; ... 99-> [49]; ... */
  nmsqrt = sqrt((double)nmax);
  bimax  = (nmax-1)/2;
  wimax  = (bimax+7)/8;
  prime  = malloc(sizeof(char)*(wimax+1));       /* need [1,...,wimax] */
  pmax   = &prime[wimax];
  
  for (p=prime; p<=pmax;) *p++ = 0xff;

  for (n=3; n<=nmsqrt; n+=2) {
    i = n/2;
    if ((prime[i>>3] & TSTMASK(i&0x7)) == 0) continue;
    SCOUNT(StatOloop);
    for (i=(n*n)/2; i<=bimax ; i+=n) {
      prime[i>>3] &= CLRMASK(i&0x7);
      SCOUNT(StatIloop);
    }
  }

  if (prnt) {
    printf("List of Primes up to %d\n",nmax);
    printf(" %7d",2);
    np = 1;
    for (i=1;i<=bimax;i++) {
      if ((prime[i>>3] & TSTMASK(i&0x7)) == 0) continue;
      printf(" %7d",1+2*i);
      np += 1;
      if (np != 10) continue;
      printf("\n");
      np= 0;
    }
    if (np != 0) printf("\n");
  }

  il =  4;
  nl = 10;
  np =  1;
  for (i=1;i<=bimax;i++) {
    if ((prime[i>>3] & TSTMASK(i&0x7))) np += 1;
    if (i != il) continue;
    nl =  2*il+2;
    printf("pi(%10d): %10d\n",nl,np);
    il = 10*(il+1)-1;
  }
  if (nl != nmax) printf("pi(%10d): %10d\n",nmax,np);

#ifdef STATISTICS
  printf("StatOloop: %20.0f\n",StatOloop);
  printf("StatIloop: %20.0f\n",StatIloop);
#endif

return 0;
}

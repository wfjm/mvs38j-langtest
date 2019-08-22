/* $Id: soep_cc.c 1171 2019-06-28 19:02:57Z mueller $ */
/* SPDX-License-Identifier: GPL-3.0-or-later                         */
/* Copyright 2017-2019 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de> */
/*                                                                   */
/*  Revision History:                                                */
/* Date         Rev Version  Comment                                 */
/* 2017-12-23   972   1.0.1  change (n-1)/2 --> n/2                  */
/* 2017-10-15   956   1.0    Initial version                         */
/* 2017-08-17   941   0.1    First draft                             */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main() 
{
  int nmax;
  int nmsqrt;
  int prnt;
  int imax;
  int i,n;
  int np,il,nl;
  char *prime;
  char *p,*pmax;
  
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
  nmsqrt  = sqrt((double)nmax);
  imax    = (nmax-1)/2;
  prime   = malloc(imax+1);              /* need [1,...,imax] */
  pmax    = &prime[imax];

  for (p=prime; p<=pmax;) *p++ = 1;

  for (n=3; n<=nmsqrt; n+=2) {    
    if (prime[n/2] == 0) continue;
    for (p=&prime[(n*n)/2]; p<=pmax; p+=n) *p = 0;
  }

  if (prnt) {
    printf("List of Primes up to %d\n",nmax);
    printf(" %7d",2);
    np = 1;
    for (i=1;i<=imax;i++) {
      if (! prime[i]) continue;
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
  for (i=1;i<=imax;i++) {
    if (prime[i]) np += 1;
    if (i != il) continue;
    nl =  2*il+2;
    printf("pi(%10d): %10d\n",nl,np);
    il = 10*(il+1)-1;
  }
  if (nl != nmax) printf("pi(%10d): %10d\n",nmax,np);

  return 0;
}

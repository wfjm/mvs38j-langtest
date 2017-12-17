*
* OHEX210 --------------------------------------------------
*   print 64 field as two 32 bit hex numbers
*     R1  points to memory location of 64 bit value
*     rendered as "  %8.8x  %8.8x"
*
OHEX210  ST    R14,OHEX210L       save R14
         ST    R1,OHEX210V        save R1
         L     R1,0(R1)           get high part
         BAL   R14,OHEX10         convert
         L     R1,OHEX210V
         L     R1,4(R1)           get low part
         BAL   R14,OHEX10         convert
         L     R14,OHEX210L       restore R14 linkage
         BR    R14                and return
*
OHEX210L DS    F                  save area for R14 (return linkage)
OHEX210V DS    F                  save area for R1 (value ptr)

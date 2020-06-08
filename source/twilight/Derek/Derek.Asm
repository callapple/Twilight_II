

*-------------------------------------------------
* Here is a routine that will quickly draw the
* apple.  Somewhere before this is called,
* set HiRes+2 to $E1.  No other setup is needed.
* Add the word sized dp's offset and RealOffset.
* ("width" is not needed now.)  This routine
* gets its speed from its very tiny inner loop!

DrawApple      anop

               lda   yposition          ; set up the index onto the screen once,
               asl   a                  ; ahead of time....
               tay
               lda   [SLookUp],y
               clc
               adc   xposition
               sta   HiRes
               sta   RealOffset         ; used to compute HiRes inside the loop

               lda   image_height       ; depth of shape
               sta   depth

               ldy   #0                 ; index into the shape and the screen
yloop          ldx   image_wordwidth    ; width (in words) of shape
xloop          lda   Apple,y
               sta   [HiRes],y
               iny                      ; only one register to increment!
               iny
               dex
               bne   xloop

               sty   offset             ; use this to adjust the HiRes pointer

               lda   RealOffset         ; just go line by line like normal
               clc
               adc   #160
               sta   RealOffset
               sec
               sbc   offset             ; then subtract out Y so that
               sta   HiRes              ; HiRes+Y = the start of the next line!

               dec   depth
               bne   yloop

               rts


*-------------------------------------------------
* This should draw Sculley a lot faster.
* Just set "Sculley" to the address of the shape
* (32 bits) and this routine should draw it.
* ("Sculley" should be in the Direct Page.)
* Also: It should not cross banks!  I don't think
* it did originally so it shouldn't be a problem.

DrawSculley    anop
               lda   yposition
               asl   a
               tay
               lda   [SLookUp],y
               clc
               adc   xposition
               sta   HiRes              ; set up the index onto the screen now

               lda   image_height       ; depth of shape
               sta   depth

               clc                      ; Carry will stay clear
;                                       ; throughout the loop.
yloop          ldx   image_wordwidth    ; width (in words) of shape

               ldy   #0
xloop          lda   [Sculley],y
               sta   [HiRes],y
               iny                      ; only one register to increment!
               iny
               dex
               bne   xloop

               lda   Sculley
               adc   image_bytewidth    ; next line of Mr. Sculley
               sta   Sculley

               lda   HiRes              ; next line on the screen
               adc   #160
               sta   HiRes

               dec   depth
               bne   yloop
               rts

*-------------------------------------------------
* I thought you might want to have the random
* number generator I use.  I haven't tested it
* against QuickDraw but there was a demo with Merlin
* that showed it and it was VERY fast and random
* looking. (I could send it if you want.)
* Use this for whatever you want.
*-------------------------------------------------


*=================================================
* RANDOM returns a random number in A
* RANDOMIZE seeds the generator from the clock
* SEED seeds the generator from AXY.
*
* Adapted by Derek Young from RANDOM, from the
* Merlin 16+ package.
*
* X and Y registers preserved, number returned in A

Random         phx
               phy
               clc
               ldx   INDEXI
               ldy   INDEXJ
               lda   ARRAY-2,X
               adc   ARRAY-2,Y
               sta   ARRAY-2,X
               dex
               dex
               bne   DYL7
               ldx   #17*2              ; Cycle index if at end of
DYL7           dey                      ;  the array
               dey
               bne   SETIXL7
               ldy   #17*2
SETIXL7        stx   INDEXI
               sty   INDEXJ
               ply
               plx
               rts

INDEXI         dc    a'17*2'            ; The relative positions of
INDEXJ         dc    a'5*2'             ; these indexes is crucial

ARRAY          dc    a'1,1,2,3,5,8,13,21,54,75,129,204'
               dc    a'323,527,850,1377,2227'

*=================================================
* Randomize sets the random number seed from the
* clock.

Randomize      anop
               pha
               pha
               pha
               pha
               ldx   #$D03              ; ReadTimeHex
               jsl   $E10000            ; (like this so we don't need macros)
               pla
               plx
               ply
               sta   1,S

               ora   #1                 ; At least one must be odd
               sta   ARRAY
               stx   ARRAY+2
               phx                      ; Push index regs on stack
               phy
               ldx   #30
LUPV1          sta   ARRAY+2,X
               dex
               dex
               lda   1,S                ; Was Y
               sta   ARRAY+2,X
               dex
               dex
               lda   3,S                ; Was X
               sta   ARRAY+2,X
               lda   5,S                ; Original A
               dex
               dex
               bne   LUPV1
               lda   #17*2
               sta   INDEXI             ; Init proper indexes
               lda   #5*2               ; into array
               sta   INDEXJ
               jsr   Random             ; Warm the generator up.
               jsr   Random
               ply
               plx
               pla
               rts
               end
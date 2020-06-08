*------------------------------------------------*
*                                                *
*                   Dissolve                     *
*        A T2 blanker by Derek Young, DYA        *
*                                                *
*------------------------------------------------*
 xc
 xc
 mx %00
 rel
 lst off

 cas IN

 use Dissolve.Macs

 dum 0
MovePtr adrl 0
RezFileID da 0
MasterID da 0
MyID da 0

PicHandle adrl 0
pixcount da 0
testbyte da 0
mirror adrl 0
normal adrl 0

DissolveScreen adrl 0
leaveflag da 0
 dend

 dum 1
Bank db 0 ;This is how the stack is set up
rtlAddr adr 0 ;with DP at the top and Result
T2data2 adrl 0 ;occupying the top four bytes
T2data1 adrl 0
T2Message da 0
T2Result adrl 0
T2StackSize adrl 0
 dend


*-------------------------------------------------
* SendRequest sendHow values
stopAfterOne equ $8000
sendToAll equ 0
sendToName equ 1
sendToUserID equ 2

t2GetBuffers = $900B

Screen = $E12000
VBL = $C019

*-------------------------------------------------
* start of the blanker...
* this is a really simple blanker - no setup or
* anything else besides "T2Blank".

Start
 phb
 phk
 plb

 lda T2Message,s
 cmp #2  ;must be BlankT2
 beq :blank
 brl Bye

:blank lda T2Data1,s
 sta MovePtr ;save this in our own DP
 lda T2Data1+2,s
 sta MovePtr+2

 lda T2Data2,s
 sta RezFileID

 ~MMStartUp
 pla
 sta MasterID
 ora #$0100
 sta MyID

*-------------------------------------------------
* The start of the program...

Blank

 PushWord #t2GetBuffers
 PushWord #stopAfterOne+sendToName
 PushLong #toT2String
 PushLong #0
 PushLong #getBuffersOut
 _SendRequest

* To do this effect we black out the screen, then randomly
* add pixels from the source picture.  The trick to making
* it look good is a fast random number generator.
* Only full 320 mode pixels are moved in, otherwise the
* whole thing would be too slow.

 lda shr_main_bufferH
 sta normal
 lda shr_main_bufferH+2
 sta normal+2

 ldy #2
 lda [normal],y
 tax
 lda [normal]
 sta normal
 stx normal+2

 ~NewHandle #32000;MyID;#$8010;#0
 PullLong PicHandle ;can't cross bank boundary!

 ldy #2
 lda [PicHandle]
 sta mirror
 lda [PicHandle],y
 sta mirror+2

* mirror the screen into the handle

 ldal $E19D00
 and #$80
 beq :320

* flip a 640 mode byte (four pixels)

:640
 ldx #0
 ldy #32000-1
 sep $20
]loop ldal Screen,x
 pha
 and #%11 ;flip the pixel over
 asl
 asl
 asl
 asl
 asl
 asl  ;put it in bit 6 and 7
 pha
 lda 2,s
 and #%1100
 asl
 asl  ;bit 4 and 5
 pha
 lda 3,s
 and #%1100_0000
 lsr
 lsr
 lsr
 lsr
 lsr
 lsr  ;bit 0 and 1
 pha
 lda 4,s
 and #%0011_0000
 lsr
 lsr ;bits 2 and 3
 clc
 adc 1,s
 clc
 adc 2,s
 clc
 adc 3,s
 eor #$FF
 sta [mirror],y
 pla
 pla
 pla
 pla
 inx
 dey
 bpl ]loop
 rep $20

 bra Again

* flip a 320 mode byte (two pixels)


:320
 ldx #0
 ldy #32000-1
 sep $20
]loop ldal Screen,x
 pha
 and #$F ;flip the pixel over
 asl
 asl
 asl
 asl
 pha
 lda 2,s
 and #$F0
 lsr
 lsr
 lsr
 lsr
 clc
 adc 1,s
 sta [mirror],y
 pla
 pla
 inx
 dey
 bpl ]loop
 rep $20

* fade in the mirrored screen

Again

 lda mirror
 sta DissolveScreen
 lda mirror+2
 sta DissolveScreen+2

 lda #$FFFF
 sta leaveflag

 jsr DissolveIt
 bcs :aborted ;the dissolve was aborted


 lda normal
 sta DissolveScreen
 lda normal+2
 sta DissolveScreen+2

 lda #$FFFF
 sta leaveflag

 jsr DissolveIt
 bcs :aborted
 bra Again

:aborted
 lda normal
 sta DissolveScreen
 lda normal+2
 sta DissolveScreen+2

 stz leaveflag

** jsr DissolveIt

 ~DisposeHandle PicHandle

Bye rep $30
 lda RTLaddr,s ;move up RTL address
 sta T2data1+3,s
 lda RTLaddr+1,s
 sta T2data1+3+1,s

 lda #0
 sta T2Result,s
 sta T2Result+2,s ;the result (nil for no error)
 plb  ;restore the bank

 tsc ;remove the input parameters.
 clc
 adc #10
 tcs

 clc
 rtl

*-------------------------------------------------
* Dissolve the screen pointed to by
* "DissolveScreen" onto the current screen.
* Exits when movePtr is true only when leaveflag != 0
*-------------------------------------------------

DissolveIt

 lda DissolveScreen
 sta :loadbyte+1
 sta :countbytes+1
 lda DissolveScreen+1
 sta :loadbyte+1+1
 sta :countbytes+1+1

 ldy #0 ;count of bytes
 ldx #32000-1
]loop sep $20
:countbytes ldal $FFFFFF,x
 cmpl Screen,x
 rep $20
 beq :1
 iny
:1 dex
 bpl ]loop
 sty pixcount


:findbyte
 rep $20 ;this is so we can loop here and be 16 bit

:reloop jsr Random

* we have make sure the number is between 0 and 32000-2 (31998)

 and #$7FFF
 cmp #32000
 bge :reloop

 tax ;this is the random number

 sep $20
:loadbyte ldal $FFFFFF,x ;load from the source picture
 cmpl Screen,x
 beq :findbyte ;loop till we get something that hasn't been
   ;copied yet

 stal Screen,x

 lda [MovePtr]
 bne :Bye
:keepgoing rep $20

 dec pixcount ;need to dissolve the whole image
 bne :reloop
 clc  ;no user input
 rts

:Bye rep $30
** lda leaveflag
** beq :keepgoing
 sec  ;user aborted
 rts

*------------------------------------------------*
* Random returns a random number in A            *
* Randomize seeds the generator from the clock   *
*                                                *
* Adapted from the Merlin 16+ package            *
*------------------------------------------------*

Random clc
 phx
 phy
 ldx INDEXI
 ldy INDEXJ
 lda ARRAY-2,X
 adc ARRAY-2,Y
 sta ARRAY-2,X
 dex
 dex
 bne :DY
 ldx #17*2 ;Cycle index if at end of
:DY dey ; the array
 dey
 bne :SETIX
 ldy #17*2
:SETIX stx INDEXI
 sty INDEXJ
 ply
 plx
 rts

INDEXI da 17*2 ;The relative positions of
INDEXJ da 5*2 ; these indexes is crucial

ARRAY da 1,1,2,3,5,8,13,21,54,75,129,204
 da 323,527,850,1377,2227

Seed pha
 ora #1 ;At least one must be odd
 sta ARRAY
 stx ARRAY+2
 phx ;Push index regs on stack
 phy
 ldx #30
]LUP sta ARRAY+2,X
 dex
 dex
 lda 1,S ;Was Y
 sta ARRAY+2,X
 dex
 dex
 lda 3,S ;Was X
 sta ARRAY+2,X
 lda 5,S ;Original A
 dex
 dex
 bne ]LUP
 lda #17*2
 sta INDEXI ;Init proper indexes
 lda #5*2 ; into array
 sta INDEXJ
 jsr Random ;Warm the generator up.
 jsr Random
 jsr Random
 jsr Random
 ply
 plx
 pla
 rts

LineCounter = $E0C02E ;Vertical scanline counter

Randomize pha
 pha
 ldx #$2503
 jsl $E10000
 ply
 pla
 eor #'DY' ;mix X up a bit (it's not as random)
 tax
 ldal LineCounter
 bra Seed

*=================================================
toT2String str 'DYA~Twilight II~'

getBuffersOut
 ds 2 ; receive count
shr_main_bufferH ds 4
shr_aux_bufferH ds 4
palette_bufferH ds 4
*=================================================

 sav Dissolve.l

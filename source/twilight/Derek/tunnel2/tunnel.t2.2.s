*------------------------------------------------*
*                                                *
*                  Hypnotist                     *
*            A Twilight II blanker               *
*                By Derek Young                  *
*                                                *
*                    v1.3                        *
*------------------------------------------------*
 lst off
 rel
 xc
 xc
 mx %00
 use Tunnel.macs


 dum 0
MovePtr adrl 0 ;for twilight

SCREENAD DS 4 ;Pointer
PACKPTR DS 4 ;Address of packed data
LENGTH DS 4 ;Number of bytes to unpack
UNPACKPTR DS 4 ;Address of Unpacked data
RingIndex DS 2 ;Index to ring buffer
Flags DS 2 ;Index to flags

Line1 da 0
Line2 da 0
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

* The RingBuffer is external.  The loader will set aside
* the 4096 bytes needed at the end of the file...

 ext Circles

Speed = 16 ;ticks before color change

stopAfterOne = $8000
sendToAll = %00
sendToName = %01
sendToUserID = %10

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
 bne Bye

 lda T2Data1,s
 sta MovePtr ;save this in our own DP
 lda T2Data1+2,s
 sta MovePtr+2

*-------------------------------------------------
* The start of the program...

Blank sep $30
 lda #0 ;black border - don't need to save it
 stal $C034
 rep $30

 ldx #$8000-2
 lda #0
]loop stal $E12000,x
 dex
 dex
 bpl ]loop

 jsr MakeCircles

 jsr Randomize

 lda #Speed
 sta Timer

:cycle
 jsr WaitVBL

 jsr Cycler

 lda [MovePtr]
 beq :cycle ;wait for an event


Bye lda RTLaddr,s ;move up RTL address
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


WaitVBL
 sep $20
]a ldal $E0C019
 bmi ]a
]b ldal $E0C019
 bpl ]b
 rep $20
 rts

*-------------------------------------------------
* Draw the huge ring of circles on the screen
* (Actually just unpack the screen. I hated QuickDraw :)

MakeCircles
 jsr UnPackIt

* Half the screen has been unpacked - flip it.

 phb
 pea $E1E1
 plb
 plb

 lda #$2000+16000-160
 sta Line1
 lda #$2000+16000
 sta Line2

:flip
 ldy #160-2
]loop lda (Line1),y
 sta (Line2),y
 dey
 dey
 bpl ]loop

 lda Line2
 clc
 adc #160
 sta Line2

 lda Line1
 sec
 sbc #160
 sta Line1
 cmp #$2000-160
 bne :flip

 plb

 ldx #32-2
]loop lda Palette,x
 stal $E19E00,x
 dex
 dex
 bpl ]loop
 brk $00


 rts

*Palette da $000,$111,$222,$333,$444,$555,$666,$777
* da $888,$999,$AAA,$BBB,$CCC,$DDD,$EEE,$FFF

Palette da $000,$777,$841,$72C,$00F,$080,$F70,$D00
 da $FA9,$FF0,$0E0,$4DF,$DAF,$78F,$CCC,$FFF

*
* Unpack the circles
*
* I'll use the top-secret LZSS decompression request to
* decompress the circles :)  This removes a lot of the code
* for the blanker.
*
* datain structure:
*  +00 word eorvalue
*  +02 long inputpointer
*  +06 long outputpointer
*  +10 long outputlength
*  +14 eos
*

reqDLZSS = $8007

UnPackIt
 brk $00

 PushWord #reqDLZSS
 PushWord #stopAfterOne+sendToName
 PushLong #toString
 PushLong #dataIn
 PushLong #0 ;data out
 _SendRequest

 rts

toString str 'DYA~Twilight II'

dataIn da 0 ;there is no eor value
 adrl Circles2+4 ;input data (skip over length long)
 adrl $E12000 ;output data
 adrl $8000 ;length of output   (16000)

*-------------------------------------------------
* Color cycler - new version.
* Pushes in random colors.

Cycler
 ldal $E19E02 ;save this for a second
 sta oldcolor

 phb ;Cycle the 15 first colors
 pea $E1E1
 plb
 plb

 lda $9E04
 sta $9E02
 lda $9E06
 sta $9E04
 lda $9E08
 sta $9E06
 lda $9E0A
 sta $9E08
 lda $9E0C
 sta $9E0A
 lda $9E0E ;move each color down one
 sta $9E0C
 lda $9E10
 sta $9E0E
 lda $9E12
 sta $9E10
 lda $9E14
 sta $9E12
 lda $9E16
 sta $9E14
 lda $9E18
 sta $9E16
 lda $9E1A
 sta $9E18
 lda $9E1C
 sta $9E1A
 lda $9E1E
 sta $9E1C
 plb

:dec dec Timer
 bne :notnew
 lda #Speed
 sta Timer

 jsr Random
 and #$FFF ;make it a color
 stal $E19E1E
 rts

:notnew lda oldcolor
 stal $E19E1E
 rts

Timer da 0
oldcolor da 0

*------------------------------------------------*
* Random returns a random number in A            *
* Randomize seeds the generator from the clock   *
*                                                *
* Adapted from the Merlin 16+ package            *
*------------------------------------------------*

Random clc
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

Randomize
 pha
 pha
 ldx #$2503
 jsl $E10000
 ply
 pla
 eor #'DY' ;mix X up a bit (it's not as random)
 tax
 ldal $E0C02E
 bra Seed

Circles2 = *

* The "filelen" constant is defined in the link file.  It
* is the length of the Circles file.

 sav Tunnel.twlt.l

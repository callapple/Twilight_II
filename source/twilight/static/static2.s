*------------------------------------------------*
*                                                *
*                    Static                      *
*        A T2 blanker by Derek Young, DYA        *
*         Thanks to Dino for a neat idea         *
*                                                *
*------------------------------------------------*
 lst off
 xc
 xc
 mx %00
 rel
 use Static.macs

 case IN

 dum 0
MovePtr adrl 0
RezFileID da 0
MyID da 0
MemID da 0

modeMask da 0
colored da 0

oldvolume da 0
soundstatus da 0
temp adrl 0
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
 lda T2Data2+2,s ;our memory ID
 sta MyID
 clc
 adc #$100
 sta MemID ;need a memory ID

*-------------------------------------------------
* The start of the program...

Blank 

* This is all very easy - set the screen randomly to any values.
* Then set the scbs to point to random color tables.  Then randomly
* fill the color tables with either white and black, or colors.

 ldx #$200-2
 lda #0
]loop stal $E19E00,x ;clear to start
 dex
 dex
 bpl ]loop

* set up the paramaters

 stz modeMask ;set to $8080 for "fine static" (640 mode)

* lda #1
* sta colored ;0=grey static, 1=colored static

 lda #200
 sta soundvolume ;volume of static sound

 jsr Randomize ;get a random seed value to start

* make a random waveform to be the static sound loop
* the loop is one page long.

 ldx #256-1
]loop jsr Random
 sep $20
 cmp #0
 beq :again
 sta wave,x
 dex
:again rep $20
 bpl ]loop

 ~SoundToolStatus
 pla
 sta soundstatus
 bne :nosound

 do 0
 ~NewHandle #$C115;MemID;#$8000;#0
 PullLong temp
 lda [temp]
 pha
 _SoundStartup ;start up the sound manager
 fin
:nosound

 ldx #$7D00-2
]loop jsr Random
 stal $E12000,x ;fill pixel randomly
 dex
 dex
 bpl ]loop

 ~GetTick
 pla
 sta tick+1
 plx
 bit #1
 bne :1

 ~SetAllScbs #$00
 bra :2

:1
 ldx #200-2
]loop jsr Random
 and #$0F0F ;do two at once
 ora modeMask
 stal $E19D00,x ;fill the scbs randomly
 dex
 dex
 bpl ]loop

:2


tick lda #0
 bit #%10
 bne :3

 lda #1
 sta colored ;0=grey static, 1=colored static
 bra :4

:3
 stz colored

:4


* Now just keep filling the color palettes up with greys (or even colors)

 lda soundstatus
 bne :nosound2

 do 0
 ~WriteRamBlock #wave;#0;#$100 ;copy the sound wave into sound ram

 ~GetSoundVolume #13 ;use generator 0 to play the sound
 PullWord oldvolume

 ~SetSoundVolume soundvolume;#13
 fin

* brk $02

* ~FFStartSound #0*256+0;#soundparms ;play the static

:nosound2

Static
 lda [MovePtr] ;check for any movement
 bne soundoff

 lda colored ;does the user want colored static?
 bne :colored

 ldx #$200-2
]loop jsr Random
 and #$F
 asl
 tay
 lda Colors,y
 stal $E19E00,x
 dex
 dex
 bpl ]loop
 bra Static

:colored ldx #$200-2
]loop jsr Random
 and #$FFF
 stal $E19E00,x
 dex
 dex
 bpl ]loop
 bra Static

soundoff
 lda soundstatus
 bne Bye

* brk $00
* ~FFStopSound #%00100000_00000000

* _SoundShutDown

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

Colors da $000,$111,$222,$333,$444,$555,$666,$777
 da $888,$999,$AAA,$BBB,$CCC,$DDD,$EEE,$FFF

soundparms adrl wave ;pointer to wave
 da 256 ;length of sound
 da 100 ;frequency
 da 00 ;DOC address
 da 0 ;buffer size (1 page)
 adrl 0 ;soundparms ;next sound
soundvolume da 0 ;volume

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

wave ds 256

 sav Static.l

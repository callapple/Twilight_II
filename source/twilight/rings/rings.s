**************************************************
*                   Rings Demo                   *
*         By Christopher Martin McKinsey         *
*           Started: December 20, 1991           *
**************************************************
 cas in
 mx %00
 rel
 use macros

 ext MultAX,ShadowOn,ShadowOff,MakeMask,getmem,deref
 ext showcell,loadcells,loadcellspal,readbeam,error
 ext gosubHand,erasebob

 put t2common.equ

Height = $08
Width = Height+4
YLoc = Width+4
XLoc = YLoc+2
YVel = XLoc+2
XVel = YVel+2
Mask = XVel+2
Image = Mask+4
ImgNum = Image+4
Work_Ptr = ImgNum+2
cellRefPtr = Work_Ptr+4
MovePtr = $80

rowBytes = 160
pixsHigh = 200
Left_Arrow = $08
Right_Arrow = $15

not = 0

*-------------------------------------------------
 dum 1
* dp da 0
Bank db 0 ;This is how the stack is set up
rtlAddr adr 0 ;with DP at the top and Result
T2data2 adrl 0 ;occupying the top four bytes
T2data1 adrl 0
T2Message da 0
T2Result adrl 0
T2StackSize adrl 0
 dend
*-------------------------------------------------

Rings_T2 = *
 phb
 phk
 plb
 tdc
 sta OurDP

 do not
 brk 00
 fin

 sep #$30
 ldal $E1C035
 rep #$30
 bit #$08
 bne bad

 lda T2Message,s
 cmp #BlankT2
 beq doBlank

 do 0
 cmp #MakeT2
 beql doMake
 cmp #HitT2
 beql doHit
* cmp #KillT2
* beql doKill
 cmp #SaveT2
 beql doSave
 cmp #LoadSetupT2
 beql doLoadSetup
* cmp #UnloadSetupT2
* beql doUnloadSetup
 fin

bad brl Bye

*-------------------------------------------------
doBlank = *
 LDX #$FE ; init our DP
]lp STZ $00,X
 DEX
 DEX
 BPL ]lp

 lda T2data1,s
 sta MovePtr ;save this in our own DP
 lda T2data1+2,s
 sta MovePtr+2

 ~MMStartUp
 pla
 ora #$0100
 sta MyID
 sta My_ID

 pea 0
 pea 0
 pea 0
 pea #160
 pea #200
 jsl shadowon
 jsl eraseBob
 jsl shadowoff

 do 0
 ldx #768+32-2
 lda #$00
]l stal $E19D00,x
 dex
 dex
 bpl ]l
 fin

*
* load in the cells
*
 phl #cells
 jsl loadcells
 bcsl return
 stx cellRefPtr
 sty cellRefPtr+2

 lda [cellRefPtr]
 sta numFrames

 txa
 clc
 adc #$02
 sta cellRefPtr
 tya
 adc #$00
 sta cellRefPtr+2

 ldx #$20-2
]l lda loadcellspal,x
 stal $E19E00,x
 dex
 dex
 bpl ]l

 jsr init
 do not
 brk 01
 fin

]l
 jsr Animate
 lda [MovePtr]
 beq ]l

 jsl shadowon

 do 0
 ldal $e0c000
 bpl ]l
 stal $e0c010
 and #$007f
 cmp #Right_Arrow
 bne :1
 lda numactors
 cmp #10
 beq ]l
 inc numactors
 bra ]l
:1 cmp #Left_Arrow
 bne :2
 lda numactors
 cmp #$01
 beq ]l
 dec numactors
 bra ]l
:2
 fin

return
 ~DisposeAll MyID

 do 0
 lda MyID
 and #$F0FF
 pha
 _MMShutDown
 fin

Bye = *
skip = *
 plb
 lda 1,s ; move up RTL address
 sta 1+10,s
 lda 2,s
 sta 2+10,s
 tsc ; Remove input parameters.
 clc
 adc #10
 tcs
 clc
 rtl

**************************************************
* This is a GLOBAL data area for the program     *
**************************************************
errorMsg str 'Error loading Rings Demo.'

My_ID ent
 ds 2
oldSP ds 2
backcolor ds 2

cells strl '*:system:cdevs:twilight:Cells'
frame dw 0
numFrames dw 0

MaxActors = 10 ; 20
cellxvel ds 2*MaxActors
cellyvel ds 2*MaxActors
cellxloc ds 2*MaxActors
cellyloc ds 2*MaxActors

NumActors dw MaxActors
origxvel dw +1,+2,+3,+4,+5,+6,+7,+8,+9,+10
origyvel dw +5,+4,+3,+2,+1,+5,+4,+3,+2,+1

*=================================================
MyID ds 2
OurDP ds 2
*=================================================
**************************************************
* Routine to test multiple animations            *
**************************************************
Animate
 jsr Move
 jsr Draw
 jsl shadowon
 jsr Show
 jsl shadowoff
 jsr Erase

 inc frame
 lda frame
 cmp numFrames
 bne :X
 stz frame
:X rts
**************************************************
*                                                *
**************************************************
Move
 lda numActors
 sta :lup
 ldx #$00
]l
 lda frame
 asl
 asl
 asl
 tay

 lda #rowBytes
 sec
 sbc [cellRefPtr],y ;frame byte width
 asl
 sta 0

 lda cellxloc,x
 clc
 adc cellxvel,x
 cmp 0
 blt :Do_Y

 lda #$00
 sec
 sbc cellxvel,x
 sta cellxvel,x
 clc
 adc cellxloc,x
:Do_Y
 sta cellxloc,x

 iny
 iny
 lda #pixsHigh
 sec
 sbc [cellRefPtr],y ;frame height
 sta 0

 lda cellyloc,x
 clc
 adc cellyvel,x
 cmp 0
 blt :Do_Next

 lda #$00
 sec
 sbc cellyvel,x
 sta cellyvel,x
 clc
 adc cellyloc,x
:Do_Next
 sta cellyloc,x

 inx
 inx
 dec :lup
 bne ]l
 rts
:lup dw 0
**************************************************
* Draw the shape                                 *
**************************************************
Draw
 stz ImgNum
]l
 lda frame
 asl
 asl
 asl
 clc
 adc #$04
 tay
 lda [cellRefPtr],y
 pha
 iny
 iny
 lda [cellRefPtr],y
 pha

 lda ImgNum
 asl
 tax
 lda cellyloc-1,x
 lsr
 lsr
 adc cellyloc-1,x
 adc cellxloc,x
 lsr
 clc
 adc #$2000
 ply
 plx
 jsl gosubHand

 inc ImgNum
 lda ImgNum
 cmp NumActors
 blt ]l
 rts
**************************************************
* Show the shapes to the screen                  *
**************************************************
Show
 stz imgnum
]l
 lda imgnum
 asl
 tax
 mvw cellxloc,x;xloc
 mvw cellyloc,x;yloc
 mvw cellxvel,x;xvel
 mvw cellyvel,x;yvel

 lda frame
 asl
 asl
 asl
 tay
 lda [cellRefPtr],y
 sta width
 iny
 iny
 lda [cellRefPtr],y
 sta height

 jsr Show_Image
 inc imgnum
 lda imgnum
 cmp NumActors
 blt ]l
 rts
**************************************************
* Erase the shapes                               *
**************************************************
Erase
 stz ImgNum
]l
 lda backcolor
 pha
 lda ImgNum
 asl
 tax
 lda cellxloc,x
 pha
 lda cellyloc,x
 pha
 lda frame
 asl
 asl
 asl
 tay
 lda [cellRefPtr],y
 pha
 iny
 iny
 lda [cellRefPtr],y
 pha
 jsl eraseBob

 inc ImgNum
 lda ImgNum
 cmp NumActors
 blt ]l
 rts
**************************************************
* init x and y locs, plus vels                   *
**************************************************
init
 stz frame

 lda #160
 sec
 sbc [cellRefPtr]
 sta 0

 ldy #$02
 lda [cellRefPtr],y
 lsr
 sta 2
 lda #100
 sec
 sbc 2
 sta 2

 ldx #$00
 ldy NumActors
]l lda origxvel,x
 sta cellxvel,x
 lda origyvel,x
 sta cellyvel,x
 lda 0
 sta cellxloc,x
 lda 2
 sta cellyloc,x
 inx
 inx
 dey
 bne ]l
 rts
**************************************************
* Show the image here                            *
**************************************************
Show_Image ent

 ldx Xvel
 txa
 lsr
 bcc :Even
 txa
 bmi :neg
 inx
 bra :Even
:neg dex
:Even stx XVel

 lda XVel
 beq :Check_Y
 bpl :Right

:Left sub Width;XVel;Width
 bra :Check_Y

:Right lda Xloc
 sec
 sbc XVel
 cmp #320
 blt :rok
 lda #0
:rok sta Xloc
 add XVel;Width

:Check_Y
 lda YVel
 beq :Show_It
 bpl :Down

:Up sub Height;YVel;Height
 bra :Show_It

:Down lda YLoc
 sec
 sbc YVel
 cmp #200
 blt :dok
 lda #0
:dok sta Yloc
 add YVel;Height

:Show_It
 pei xloc
 pei yloc
 pei width
 pei height
 jsl showcell
 rts
**************************************************
 sav Rings.l

*------------------------------------------------*
*                                                *
*                    Tunnel                      *
*            A Twilight II blanker               *
*                By Derek Young                  *
*                                                *
*------------------------------------------------*
 lst off
 rel
 xc
 xc
 mx %00
 use Tunnel.macs


 dum $00
Color da 0 ;for drawing the circles
i da 0

DP adrl 0

MyID da 0
MemID da 0

MovePtr adrl 0 ;for twilight
 dend

delay = 1
NumCircles = 189

 lda 6,s
 sta MovePtr
 lda 8,s
 sta MovePtr+2

 phk
 plb

 lda #0
 ldx #$7E00-2
]loop stal $E12000,x
 dex
 dex
 bpl ]loop

 ldx #32-2
]loop lda Palette,x
 stal $E19E00,x
 dex
 dex
 bpl ]loop

 sep $20
 ldal $C034
 pha
 and #$F
 sta Border
 pla
 and #$F0
 stal $C034
 rep $20

 lda #$FFF
 sta LastC

 stz CycleColor
 stz VCount

 ~SetHeartBeat #Cycler

 jsr DrawCircles
 bcs :end

:loop lda [MovePtr]
 beq :loop

:end ~DelHeartBeat #Cycler

 sep $20
 ldal $C034
 and #$F0
 ora Border
 stal $C034
 rep $20

 lda 2,s ;move the RTL address up on the stack
 sta 12,s
 lda 1,s
 sta 11,s

 tsc
 clc
 adc #10
 tcs

 rtl

Border db 0

Palette da $000,$777,$841,$72C,$00F,$080,$F70,$D00
 da $FA9,$FF0,$0E0,$4DF,$DAF,$78F,$CCC,$FFF

*-------------------------------------------------
* Draw the huge ring of circles on the screen

DrawCircles
 ~GetPort
 PullLong OldPort

 ~GetMasterSCB
 pla
 sta oldSCB
 and #$FF7F ;go to 320 mode
 pha
 _SetMasterSCB

 ~OpenPort #MyPort ;get a fresh port setup

 lda #160
 sta h1
 sta h2
 lda #100
 sta v1
 sta v2
 lda #1
 sta Color

 lda #NumCircles
 sta i
:Loop
 pei Color
 _SetSolidPenPat
 ;yuck!  QuickDraw :(
 ~FrameOval #CRect

 lda Color
 inc
 and #%1111 ;keep it between 0 and fifteen
 bne :ok
 inc ;skip 0
:ok sta Color

 dec v1
 dec h1
 inc v2
 inc h2

 lda [MovePtr] ;incase the event happens while they're
 bne :abort ;drawing.

 dec i
 bne :Loop
 lda #0

:abort pha
 ~SetMasterSCB oldSCB
 ~SetPort OldPort
 ~ClosePort #MyPort
 pla
 cmp #1
 rts

CRect
v1 da 0
h1 da 0
v2 da 0
h2 da 0

oldSCB da 0
OldPort adrl 0

MyPort ds 170 ;170 bytes.  Hope this doesn't cause a
   ;problem in the future if this length changes.

*-------------------------------------------------
* The color cycler.
* It's a heartbeat task.

Cycler
 adrl 0
Period da delay
 da $A55A

 phk
 plb
 rep $30
 lda #delay
 sta Period

 lda #$FFFF
 sta DoNext

 lda VCount
 inc
 sta VCount
 cmp #91
 bge :bigger
 stz DoNext
:bigger

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

 lda VCount
 cmp #91
 blt :smaller
 stz VCount
:smaller

 lda LastC
 stal $E19E1E

 lda DoNext
 beq :else ;false...

 ldy CycleColor
 cpy #90*2
 blt :ok
 ldy #0
:ok lda CycleTable,y
 sta LastC
 iny
 iny
 sty CycleColor
 stz DoNext

 rtl

:else
 ldal $E19E02
 sta LastC

 rtl

Timer da 0
LastC da 0
DoNext da 0
VCount da 0

CycleColor da 0

CycleTable da $F00,$F10,$F20,$F30,$F40,$F50,$F60,$F70,$F80
 da $F90,$FA0,$FB0,$FC0,$FD0,$FE0,$FF0,$EF0,$DF0
 da $CF0,$BF0,$AF0,$9F0,$8F0,$7F0,$6F0,$5F0,$4F0
 da $3F0,$2F0,$1F0,$0F0,$0F1,$0F2,$0F3,$0F4,$0F5
 da $0F6,$0F7,$0F8,$0F9,$0FA,$0FB,$0FC,$0FD,$0FE
 da $0FF,$0EF,$0DF,$0CF,$0BF,$0AF,$09F,$08F,$07F
 da $06F,$05F,$04F,$03F,$02F,$01F,$00F,$10F,$20F
 da $30F,$40F,$50F,$60F,$70F,$80F,$90F,$A0F,$B0F
 da $C0F,$D0F,$E0F,$F0F,$F0E,$F0D,$F0C,$F0B,$F0A
 da $F09,$F08,$F07,$F06,$F05,$F04,$F03,$F02,$F01


 typ RTL
 sav Tunnel.twlt.l

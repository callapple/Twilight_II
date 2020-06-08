*------------------------------------------------*
*                                                *
*                 Kaleidoscope                   *
*             A Twilight II module               *
*            Derek Young, May 1992               *
*              Originally SHKalid                *
*              by John Stephen III               *
*                                                *
*                version 1.0d                    *
*------------------------------------------------*
 lst off
 rel
 xc
 xc
 mx %00

 dum 1
dp da 0
Bank db 0 ;This is how the stack is set up
rtlAddr adr 0 ;with DP at the top and Result
T2data2 adrl 0 ;occupying the top four bytes
T2data1 adrl 0
T2Message da 0
T2Result adrl 0
T2StackSize adrl 0
 dend

 dum $F0
MovePtr adrl 0 ;keep this out of the way
 dend

*-------------------------------------------------
* start of the blanker...
* this is a really simple blanker - no setup or
* anything else besides "T2Blank".

Start
 phb
 phk
 plb
 phd
 tdc
 sta OurDP
 tsc
 tcd

 ldx T2Data1
 ldy T2Data1+2
 lda T2Message
 sta Mess

 lda Mess  ;Get which setup procedure to call.
 cmp #2
 beq :1
 jmp Bye ;not a message we can handle

:1 lda OurDP
 tcd

 stx MovePtr ;save this in our own DP
 sty MovePtr+2

*-------------------------------------------------
* The start of the program...

Blank sep $30
 lda #0 ;black border - don't need to save it
 stal $C034

 ;for some reason this program
   ;is completely in 8-bit...

 jsr ClrTable
 jsr MakeLookup
 lda #$01
 sta $10
 sta $11
 sta $13
 sta $15
 sta $17
 lda #$11
 sta $14
 lda #$03
 sta $16
 sta $19
 lda #$0A
 sta $18
 lda #$02
 sta $1A
 lda #$00
 sta $1B
 sta $12
 tax
 tay

 jsr Reset
* jsr SetPalette ;temporary!

Loop
 rep $20
 lda [MovePtr] ;check for any movement
 sep $20
 beq :1
 jmp Bye

:1 jsr H3453
]loop tya
 clc
 adc $11
 cmp #160
 bcc H3400
 lda #0
 sec
 sbc $11
 sta $11
 bra ]loop

H3400 tay
H3401 txa
 clc
 adc $10
 cmp #160
 bcc H3412
 lda #$00
 sec
 sbc $10
 sta $10
 bra H3401

H3412 tax
 jsr H343F
 tya
 bne Loop
 txa
 cmp $12
 bne Loop
 inx
 txa
 cmp #$A0
 bcc H3426
 lda #$00
H3426 sta $12
 tax
 phx
 ldx $15
H342C jsr H343F
 dex
 bne H342C
 plx
 jsr H2349
 jsr Cycle
 jsr H3485
 jmp Loop

*-------------------------------------------------
* Time to quit

Bye rep $30 ;reg size is undefined coming in
 pld
 plb
 lda 1,s ; move up RTL address
 sta 1+10,s
 lda 2,s
 sta 2+10,s
 tsc ; Remove input parameters.
 clc
 adc #10
 tcs
 lda #0
 sta 4,s
 sta 6,s ;the result (nil for no error)
 clc
 rtl

Mess da 0
OurDP da 0

*-------------------------------------------------

 mx %11

H2003 lda #$E1
 sta $02
 rep %00100000
 txa
 xba
 lsr
 sta $00
 lsr
 lsr
 clc
 adc $00
 adc #$2000
 sta $00
 sep %00100000
 rts

MakeLookup ldx #$00
]loop jsr H2003
 lda $00
 sta H21A5,X
 lda $01
 sta H20DD,X
 inx
 cpx #$C8
 bne ]loop

 jsr ClearScreen

* jsr Reset ;this eliminates the blank screen beginning.

 lda #0
 sta $03
 sta $04
 sta H23DB+0
 sta H23DB+1
 sta H23DB+2
 sta H23DB+3
 sta H23DB+4
 sta H23DB+5
 sta H23DB+6
 sta H23DB+7
 sta H23DB+8
 sta $0A
 lda #$0F
 sta H23E4
 sta H23E4+1
 sta H23E4+2
 lda #$50
 sta $08
 lda #$05
 sta $07
 lda #$FF
 sta $09
 rts

* Plot a point symetrically
* This is what gives it the kaleidoscope look
* The line number is given in X and the
* horizontal offset in Y.

PlotKalid lda H20DD,X
 sta $01
 lda H21A5,X
 sta $00

 lda $03
 sta [$00],Y
 phy
 tya
 eor #$FF
 clc
 adc #$A0
 tay
 lda $03
 sta [$00],Y
 ply
 rts

* Simply plot a point
* Also to be rewritten

Plot lda H20DD,X
 sta $01
 lda H21A5,X
 sta $00
 lda $03
 sta [$00],Y
 rts

* Plot a row of pixels

Row sta $0B
]loop jsr Plot
 iny
 dec $0B
 bne ]loop
 rts

* Plot a column of pixels

Column sta $0B
]loop jsr Plot
 inx
 dec $0B
 bne ]loop
 rts

* scanline lookup tables

H20DD ds 200 ;hi byte
H21A5 ds 200 ;middle byte

* Cycle the colors in the palette

Cycle inc $04
 lda $04
 and #%1111 ;keep it modula 16
 sta $04
 jsr SetPalette
 rts

* Set the palette

SetPalette phx
 phy
 ldx #0
 lda $04
 asl
 tay
]loop tya
 and #%11111
 tay
 lda InitialPal,Y
 stal $E19E00,X
 iny
 inx
 cpx #32
 bne ]loop
 ply
 plx
 rts

* This is the starting color table

InitialPal da $000,$111,$222,$333,$444,$555,$666,$777
 da $888,$999,$AAA,$BBB,$CCC,$DDD,$EEE,$FFF

 ds 8 ;a little buffer - I think this gets overwritten!
*InitialPal ds 32

ClearScreen rep $30
 ldx #$8000-2
 lda #0
]loop stal $E12000,x
 dex
 dex
 bpl ]loop
 sep $30
 rts

NewPalette
H22DB phx
 phy
 ldx #$00
:loop1 lda H23DE,X
 tay
 lda H23DB,X
 tax
 lda #16
 jsr H2447
 inx
 cpx #$03
 bne :loop1
 ldy #$00
:loop2 ldx #$00
 jsr H24A4
 asl
 asl
 asl
 asl
 sta InitialPal,Y
 inx
 jsr H24A4
 ora InitialPal,Y
 sta InitialPal,Y
 inx
 jsr H24A4
 sta InitialPal+1,Y
 iny
 iny
 bcc :loop2
 ply
 plx
 rts

* Fade from one palette to another

H2317 phx
 phy
 ldx #$00
H231B lda H23E4,X
 cmp H23DE,X
 beq H232E
 bcs H232B
 dec H23DE,X
 jmp H232E

H232B inc H23DE,X
H232E lda H23E1,X
 cmp H23DB,X
 beq H2341
 bcs H233E
 dec H23DB,X
 jmp H2341

H233E inc H23DB,X
H2341 inx
 cpx #$03
 bne H231B
 ply
 plx
 rts

H2349 dec $08
 bne H2386
Reset lda #$03
 sta $08
 phx
 phy
 jsr H2317
 jsr H22DB
 jsr SetPalette
 dec $07
 bne H2384
 lda #$28 ;Reset
 sta $07
H2364 jsr Random
 and #$0F
 beq H2364
 cmp $09
 beq H2364
 sta $09
 tax
 lda H23AB,X
 sta H23E4
 lda H23CB,X
 sta H23E4+1
 lda H23BB,X
 sta H23E4+2
H2384 ply
 plx
H2386 rts

* I think this is a random number generator

Random phx
 ldx #$08
H238A lda $05
 asl
 asl
 asl
 eor $05
 asl
 lda $06
 rol
 sta $06
 lda $05
 rol
 sta $05
 ora $06
 bne H23A4
 lda #$01
 sta $05
H23A4 dex
 bne H238A
 plx
 lda $06
 rts

* Are these for the random number generator?

H23AB hex 00000000
 hex 0F0F0F0F
 hex 0F0F0F0F
 hex 08080808

H23BB hex 00000F0F
 hex 00000F0F
 hex 0F0F0808
 hex 0F0F0808

H23CB hex 000F000F
 hex 000F000F
 hex 0F080F08
 hex 0F080F08

H23DB ds 1
H23DC ds 1
H23DD ds 1
H23DE ds 1
H23DF ds 1
H23E0 ds 1
H23E1 ds 1
H23E2 ds 1
H23E3 ds 1

H23E4 ds 3

ClrTable ldx #$00
 txa
]loop sta H2557,X
 inx
 cpx #32
 bne ]loop
 rts

H2447 pha
 txa
 pha
 ldx #$00
H244C lda H2557,X
 beq H2458 ;find the first zero
 inx
 cpx #32
 bne H244C
 brk $00 ;should never happen
H2458 pla
 sta H24F7,X
 sta H24D7,X
 pla
 sta H25B7,X
 inc
 sta H2537,X
 tya
 sta H2517,X
 sec
 sbc H24F7,X
 beq H2484
 bcs H2490
 eor #$FF
 clc
 adc #$02
 sta H2557,X
 lda #$FF
 sta H2597,X
 bmi H249B
H2484 lda #$01
 sta H2557,X
 stz H2597,X
 bra H249B
H2490 inc
 sta H2557,X
 lda #$01
 sta H2597,X
H249B STz H2577,X
 lda H24D7,X
 rts

H24A4 lda H25B7,X
 beq H24D0
 lda H2577,X
 clc
 adc H2557,X
H24B0 sta H2577,X
 sec
 sbc H2537,X
 bcc H24C8
 pha
 lda H2597,X
 clc
 adc H24D7,X
 sta H24D7,X
 pla
 jmp H24B0

H24C8 dec H25B7,X
 lda H24D7,X
 clc
 rts

H24D0 stz H2557,X
 sec
 rts

H24D7 ds 32
H24F7 ds 32 ;some color tables
H2517 ds 32
H2537 ds 32
H2557 ds 32
H2577 ds 32
H2597 ds 32
H25B7 ds 32

H343F dec $13
 bne H3452
 lda #$01
 sta $13
 lda $03
 clc
 adc $14
 bcc H3450
 lda #$00
H3450 sta $03
H3452 rts

H3453 phx
 phy
 tya
 txy
 tax
 jsr H3461
 ply
 plx
 jsr H3461
 rts

H3461 phx
 txa
 eor #$FF
 clc
 adc #200
 tax
 jsr PlotKalid
 plx
 jsr PlotKalid
 rts

H3485 inc $1B
 lda $1B
 cmp $18
 bcc H3498
 dec $1A
 bne H3494
 jsr H34A3
H3494 lda #$00
 sta $1B
H3498 cmp $19
 lda $16
 bcc H34A0
 lda $17
H34A0 sta $15
 rts

H34A3 jsr Random
 and #$03
 cmp #$04
 bcs H34A3
 cmp #$00
 beq H34A3
 sta $16
H34B2 jsr Random
 and #$03
 cmp #$04
 bcs H34B2
 cmp #$00
 beq H34B2
 sta $17
H34C1 jsr Random
 and #$1F
 cmp #$19
 bcs H34C1
 cmp #$02
 bcc H34C1
 sta $18
H34D0 jsr Random
 and #$1F
 cmp $18
 bcs H34D0
 cmp #$01
 bcc H34D0
 sta $19
H34DF jsr Random
 and #$0F
 beq H34DF
 cmp #$0A
 bcs H34DF
 sta $1A
 rts

 typ $BC
 sav Kaleidoscope.l

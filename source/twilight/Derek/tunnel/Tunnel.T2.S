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

* The RingBuffer is external.  The loader will set aside
* the 4096 bytes needed at the end of the file...

 ext Circles

 lda 6,s
 sta MovePtr
 lda 8,s
 sta MovePtr+2

 phk
 plb

 ldx #$8000-2
 lda #0
]loop stal $E12000,x
 dex
 dex
 bpl ]loop

 sep $20
 ldal $C034
 sta Border
 lda #0
 stal $C034
 rep $20

 jsr MakeCircles

 lda #$FFF
 sta LastC

 stz CycleColor
 stz VCount

]loop
 jsr WaitVBL

 jsr Cycler

 lda [MovePtr]
 beq ]loop ;wait for an event

 sep $20
 lda Border
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

WaitVBL
 sep $20 ;I took this out of the heartbeat task...
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
 bge :flip

 plb

 ldx #32-2
]loop lda Palette,x
 stal $E19E00,x
 dex
 dex
 bpl ]loop

 rts

Palette da $000,$111,$222,$333,$444,$555,$666,$777
 da $888,$999,$AAA,$BBB,$CCC,$DDD,$EEE,$FFF

*Palette da $000,$777,$841,$72C,$00F,$080,$F70,$D00
* da $FA9,$FF0,$0E0,$4DF,$DAF,$78F,$CCC,$FFF

*
* Unpack a section of memory
*

RINGSIZE = 4096 ;/* size of ring buffer */
MATCHMAX = 18 ;/* upper limit for match_length */
THRESHOLD = 2 ;/* encode string into position and length

UnPackIt
 lda #16000 ;just half of the pixel data is stored
 sta LENGTH

 lda #$E12000
 sta UNPACKPTR
 lda #^$E12000
 sta UNPACKPTR+2

 lda #Circles+4 ;skip over the length long word
 sta PACKPTR
 lda #^Circles+4
 sta PACKPTR+2

 SEC
 LDA #0
 SBC LENGTH
 STA LENGTH

 LDX #RINGSIZE-MATCHMAX-1
 SEP #$20
]A STZ RingBuffer,X ;First fill the ring buffer
 DEX
 BPL ]A
 REP #$20
 LDA #RINGSIZE-MATCHMAX ;Set the index to the end of the buffer
 STA RingIndex
 STZ Flags ;Kill my flags

*
* Loop here
* Get a byte in flags to know if the next 8 samples are either
* words or bytes
*

]A LSR Flags ;Shift out a byte flag
 LDA Flags
 BIT #$100 ;Empty?
 BNE :FLAGSOK
 JSR GETBYTE ;Get new flags
 ORA #$FF00 ;Or in $FF for an 8 bit count
 STA Flags ;Save

:FLAGSOK BIT #1 ;Is this a raw byte or a pack string?
 BEQ :DLZZ
 JSR GETBYTE ;Get raw byte
 JSR PUTBYTE ;Save it
 LDX RingIndex ;Get ring buffer index
 SEP #$20
 STA RingBuffer,X ;Save data in ring buffer
 REP #$20
 INX ;Next index
 TXA
 AND #RINGSIZE-1 ;Keep in ring buffer!
 STA RingIndex ;Save
 BRA ]A ;Get another char!

*
* Decompress from ring buffer
*

:DLZZ JSR GETWORD ;Get count/index to buffer
 TAY ;Save word
 AND #$FFF ;Mask index
 TAX ;Save as index to ring buffer
 TYA
 ROL ;Move upper 4 bits to lowest 4 bits
 ROL
 ROL
 ROL
 ROL
 AND #$F ;Mask
 INC ;Add threshold (2)
 INC
 STA SCREENAD
 LDY RingIndex ;Get ring buffer index
]B LDA RingBuffer,X ;Get char from buffer
 JSR PUTBYTE ;Save in decompressed buffer
 SEP #$20
 STA RingBuffer,Y
 REP #$20
 INY
 TYA
 AND #RINGSIZE-1
 TAY
 INX ;Next index
 TXA
 AND #RINGSIZE-1 ;Keep in buffer
 TAX
 DEC SCREENAD ;All bytes done?
 BPL ]B ;Loop
 STY RingIndex
 BRA ]A ;Keep decompressing!

*
* Save byte in finished buffer
*

PUTBYTE SEP #$20
 STA [UNPACKPTR] ;Save byte
 REP #$20
 INC UNPACKPTR ;Inc pointer
 BNE :AA
 INC UNPACKPTR+2
:AA INC LENGTH ;Dec length
 BNE :BB
 PLA ;Kill JSR to abort
:BB rts ;EXIT whole routine

*
* Get a byte of packed data
*

GETBYTE LDA [PACKPTR] ;Get byte
 AND #$FF ;Mask
 INC PACKPTR ;Inc pointer
 BNE :AA
 INC PACKPTR+2
:AA RTS

*
* Get a word of packed data
*

GETWORD LDA [PACKPTR] ;Get the word
 INC PACKPTR ;Inc pointer twice
 BNE :AA
 INC PACKPTR+2
:AA INC PACKPTR
 BNE :BB
 INC PACKPTR+2
:BB RTS ;Exit

*-------------------------------------------------
* The color cycler.

Cycler
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

* The loader makes a zero-filled 4096 byte buffer here.
* The "filelen" constant is defined in the link file.  It
* is the length of the Circles file.

RingBuffer = *+filelen

 typ RTL
 sav Tunnel.twlt.l

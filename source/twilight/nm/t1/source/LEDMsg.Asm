	keep	Led.Msg
	mcopy	LedMsg.macs

LedMessage	Start
Speed	equ	2	;1/20 second

	phb		;Store old data bank

	short	M
	lda	#$E1
	pha
	plb

	lda	$C034
	and	#$0F
	sta	>OldBorder
	lda	$C034
	and	#$F0
	sta	$C034

Wait1	lda	$C019	;wait for start of next refresh
	bpl	Wait1	;so no-blink screen clear
Wait2	lda	$C019
	bmi	Wait2

	long	M

	ldx   #$7FFE
nextBlnk	stz   $2000,x
	dex
	dex
	bpl   nextBlnk

	mov	#$F00,$9e02
	stz	OnColor
	phk
	plb		;now set current bank for program

	phd
	tsc
	inc	a
	tcd

	LongResult
	_GetPort
	WordResult
	_GetMasterSCB

MemId	equ	6	;passed in on stack
DeRef	equ	12	;just a value to fry
	PushLong DeRef	;save values!

	LongResult
	ldx	#0
	phx		;upper word of length
	PushWord #$AA	;length of a GrafPort
	PushWord MemId	;user ID
	PushWord #$C010	;locked, fixed, no cross bank
	phx
	phx		;no special address, so 0
	_NewHandle

	lda	1,s
	sta	DeRef
	lda	3,s
	sta	DeRef+2
	lda	[DeRef]
	tax
	ldy	#2
	lda	[DeRef],y
	pha
	phx
	pha
	phx		;push the pointer twice
	pushword #0
	_SetMasterSCB
	_OpenPort
	_SetPort
	PushLlcl #MyPortLoc
	_SetPortLoc
	plx
	ply
	PullLong DeRef
	phy
	phx

	PushWord #1	;mode or
	_SetPenMode
	PushWord #1	;color #
	_SetSolidPenPat
	lda	[12]	;len of pascal string
	and	#$FF	;in lo byte only
	inc	a	;account for len byte
	sta	MsgLen

NewMessage	WordResult
	_Random
	pla
	and	#$7F
	clc
	adc	#4	;center from top to bottom of the screen
	sta	TopY
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	pha
	asl	a
	asl	a
	clc
	adc	1,s
	adc	#$2000	;start of row on screen
	sta	LineTarget	;save for MVN later
	inc	a
	inc	a
	sta	LineStart
	plx
	mov	#8,PartOfChar
	stz	PlaceInMsg
	lda	TopY
	clc
	adc	#310	;scan lines start at 256, 60 line wait
	sta	WaitFor	;when to start the MVNs
	stz	WasAbove

MainLoop	anop
	lda	[8]
	bne	Done
	lda	>$01C02E	;vertical counter, upper 8 bits of it
	and	#$FF	;dump horiz count in upper 8 bits of a
	rol	a	;insert a 0 or 1, for full 9 bits
	cmp	WaitFor
	blt	LessThan

	lda	WasAbove	;check position on screen
	beq	MainLoop	;check if we've already displayed it...
	stz	WasAbove
NextCol	ldx	OnColor
	inx
	inx
	cpx	#ColorsLen
	blt	OkOffset
	ldx	#0
OkOffset	stx	OnColor
	lda	Colors,x
	sta	>$E19e02	;to next color
	jsr	ScrollMsg
	bcc	MainLoop	;branch if still in message
	brl	NewMessage
LessThan	mov	#1,WasAbove
	bra	MainLoop

done	_DisposeHandle
	_SetMasterSCB
	_SetPort

         short M
         lda   >$E0C034
         and   #$F0
         ora   OldBorder
         sta   >$E0C034
         long  M

         pld
         plb
         lda   2,s
         sta   12,s
         lda   1,s
         sta   11,s
         pla
         pla
         pla
         pla
         pla

         rtl
WaitFor	ds	2
WasAbove	ds	2

ScrollMsg	anop
*
* Handles the scrolling of the message
*
*
	phb
	lda	#64	;lines to move
	ldx	LineStart
	ldy	LineTarget
	PushWord #$E1E1
	plb
	plb		;pull bank byte twice (word pushed!)
MoveLines	pha
	phy
	phx
	lda	#$a0-3	;# bytes to move
	dc	h'54e1e1'	;Mvn e1e1
	plx
*	stz	|$0098,x
	stz	|$009A,x
	pla
	clc
	adc	#$a0
	tay
	txa
	clc
	adc	#$a0
	tax
	pla
	dec	a
	bne	MoveLines
	plb
	lda	posn
	eor	#1
	sta	Posn
	beq	AnRts	;draw every other time (every 4 bytes of scroll)

	lda	ScrollingOff ;scrolling message off the screen
	bmi	DoRun	;if not, go on
	dec	ScrollingOff
	bpl	NotOffYet
	sec		;flag all off screen
	rts
NotOffYet	clc
AnRts	rts
Posn	ds	2

DoRun	inc	PartOfChar
	lda	PartOfChar
	cmp	#9
	blt	StillInChar	;in same character

	mov	#1,PartOfChar ;restart bit-shift ops
	inc	PlaceInMsg
	lda	PlaceInMsg
	cmp	MsgLen
	blt	StillInIt	;still within message, no wrap
	mov	#41,ScrollingOff ;41 chars to move off
	clc		;still in message
	rts
StillInIt	ldy	PlaceInMsg
	lda	[12],y
	and	#$FF
	cmp	#127
	bge	BadChar	;ignore IIGS special chars (accents, etc)
	cmp	#32
	bge	GoodChar	;branch if in 32-127
BadChar	lda	#32	;replace illegal stuff by space
GoodChar	sec
	sbc	#32	;first char defined is space
	asl	a
	asl	a
	asl	a	;each char bitmap is 8 bytes long
	adc	#CharSet
	sta	CharStart+1	;and save its place

StillInChar ldy	#0	;now, time to display a part of the char
	mov	TopY,Oval2Make ;top coord of first one
	clc
	adc	#7
	sta	Oval2Make+4 ;bottom of first
	mov	#307,Oval2Make+2 ;left coord
	clc
	adc	#8
	sta	Oval2Make+6	;right coord
DoRows	sty	RowNum
CharStart	lda	|0000,y	;self-modified, start of char+y
	ldx	PartOfChar
GetBit	lsr	a	;shift bits
	dex
	bne	GetBit	;get part of char
	bcc	Ready4Next	;cc=don't draw pixel
	PushLlcl #Oval2Make
	_PaintOval	;and draw it
	Short	M
	sta	>$01c030
	Long	M
Ready4Next	lda	Oval2Make
	clc
	adc	#8
	sta	Oval2Make	;move next top down
	clc
	adc	#7	;bottom of next square
	sta	Oval2Make+4
	lda	Oval2Make+2
	dec	a
	sta	Oval2Make+2	;adjust left
	lda	Oval2Make+6
	dec	a
	sta	Oval2Make+6	;adjust Right
	ldy	RowNum
	iny
	cpy	#8
	blt	DoRows
	clc		;flag good results
	rts

;................................................................

MyPortLoc anop
ScreenMode dc  i'0'
         dc	   i4'$E12000'
         dc	   i'160'
         dc	   i'0,0,200,320'
OldBorder ds   2

MsgLen	ds	2
PlaceInMsg	ds	2
PartOfChar	ds	2
Oval2Make	ds	8
Count	dc	i'2'
TopY	ds	2
ScrollingOff dc	i'-1'
LineStart	ds	2
LineTarget	ds	2

RowNum	ds	2
OnColor	ds	2

CharSet	anop
 dc h'00000000000000000404040400040400'
 dc h'1B1B12120000000000123F12123F1200'
 dc h'083E011E201F080027251708043A2939'
 dc h'0C1E021E01011E0C0303020000000000'
 dc h'0C02010101020C000304080808040300'
 dc h'150E1B0E150000000004041F04040000'
 dc h'00000000000303020000001F00000000'
 dc h'00000000000303000020100804020100'
 dc h'1E31292523211E000605040404040400' ;'0'
 dc h'1F20201E01003F003F10001C20201F00'
 dc h'080C0A003F0808003F001F2020201F00'
 dc h'1008041E21211E003F00100804020100'
 dc h'1E21211E21211E001E21211E08040200'
 dc h'00000303000303000000030300030302'
 dc h'000402010204000000001F001F000000'
 dc h'00010204020100000F10100C04000400'
 dc h'000F101615150E001F2020213F212100'
 dc h'1F20201F21211F003C02010101023C00' ;'@'
 dc h'0F10212121110F003F00003F01013F00'
 dc h'3F00003F010101003C02013901221C00'
 dc h'2121212F212121000700020202020700'
 dc h'1C000808080807002111090509112100'
 dc h'0101010101013F001F21252525252500'
 dc h'1F212121212121001E21212121211E00'
 dc h'1F20201F010101001E2121212121023C' ;'P'
 dc h'1F20201F212121003E01011E20201F00'
 dc h'3F000404040404002121212121213E00'
 dc h'21212112120C0C002525252525213A00'
 dc h'21120C0C0C1221001111110E00040400'
 dc h'3F00100804023F000F0101010101010F'
 dc h'00010204081020000F0808080808080F'
 dc h'0000040A11000000000000000000007F'
 dc h'0303020000000000 00003E2121212600' ;'`a'
 dc h'01011D2121211F0000003E0101013E00'
 dc h'20202E2121213E0000003E1109013E00'
 dc h'0E01010F0101010000001E212126201F'
 dc h'01011D21212121000400040404040400' ;'hi'
 dc h'04000404040404030101110907091100'
 dc h'040404040404040000001B2525252500'
 dc h'00001F212121210000001E2121211E00'
 dc h'00001F2121211D0100003E2121212E20'
 dc h'00001C020202020000003E011E201F00' ;'rs'
 dc h'01010F0101010E000000212121211E00'
 dc h'00001111110A04000000252525253A00'
 dc h'0000110A040A11000000192122140807'
 dc h'00003F100C023F000000000000000001'

Colors	anop
 dc i'$F00,$F10,$F20,$F30,$F40,$F50,$F60,$F70,$F80,$F90,$FA0,$FB0,$FC0,$FD0,$FE0'
 dc i'$FF0,$EF0,$DF0,$CF0,$BF0,$AF0,$9F0,$8F0,$7F0,$6F0,$5F0,$4F0,$3F0,$2F0,$1F0'
 dc i'$0F0,$0F1,$0F2,$0F3,$0F4,$0F5,$0F6,$0F7,$0F8,$0F9,$0FA,$0FB,$0FC,$0FD,$0FE'
 dc i'$0FF,$0EF,$0DF,$0CF,$0BF,$0AF,$09F,$08F,$07F,$06F,$05F,$04F,$03F,$02F,$01F'
 dc i'$00F,$10F,$20F,$30F,$40F,$50F,$60F,$70F,$80F,$90F,$A0F,$B0F,$C0F,$D0F,$E0F'
 dc i'$F0F,$F0E,$F0D,$F0C,$F0B,$F0A,$F09,$F08,$F07,$F06,$F05,$F04,$F03,$F02,$F01'
ColorsLen	equ	*-Colors
	end
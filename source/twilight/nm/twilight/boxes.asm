	keep	Clocks
	mcopy	Clocks.Macs
	copy	T2Common.equ
	copy	18/e16.memory

DigitalClock Start
WaitForVBLd	equ	254
WaitForVBLa	equ	256+30
DestByte	equ	18
	phb		;Store old data bank
	phk
	plb

	phd
	tsc
	inc	a
	tcd

	lda	T2Message	;action code?
	cmp	#2
	beq	StartBlank
	brl	Setup


StartBlank	anop
	_ShowPen		;default state for MY stuff...
	PushWord	#2	;mode Xor
	_SetPenMode

	lda	>$00c035
	and	#8	;shadowing on?
	bne	NoShadow
	lda	#$0101	;if so, faster draw to bank 01
	dc	h'cf'
NoShadow	lda	#$E1E1
	sta	MvnLoc+1	;most important-- fast mvn if available
	sta	MvnLoc2+1	;most important-- fast mvn if available

	lda	DClockPrefs
	and	#$FF
	sta	ClockType
	cmp	#3
	blt	DoDefType
	
GetClockType WordResult
	_Random
	pla
	and	ClockType	;mask to 0-3...
DoDefType	dec	a
	bmi	GotoASClock
	dec	a
	bmi	GotoAClock
	beq	DoDClock	;0 now means was 2=DClock
	bra	GetClockType	;3= still random
	
GotoAClock	brl	DoAClock
GotoASClock	brl	DoASClock
ClockType	ds	2

DoDClock	mov	#$F00,>$e19e02
	stz	OnColor	;now in current bank

	PushWord #1	;color #
	_SetSolidPenPat
	PushWord #0
	_SetSolidBackPat

NewLoc	LongResult
	WordResult
	_Random		;random #
	PushWord	#160	;divide by
	_UDivide
	pla
	pla		;modulo
	lsr	a
	asl	a	;make it on an even byte boundary
	sta	Left	;left edge of stuff to draw
	clc
	adc	#40
	sta	WipeRect+6	;for erasing hours
GetNewY	LongResult	;for Division
	WordResult
	_Random
	PushWord	#171	;to divide by
	_UDivide
	pla		;quotient
	pla		;modulo result (0-170)
	sta	Top
	clc
	adc	#29
	sta	WipeRect+4
	jsr	GetTimed
	jsr	Buf2Digs
	lda	Top
	clc
	adc	#6
	sta	Circle
	clc
	adc	#4
	sta	Circle+4
	lda	Left
	clc
	adc	#46
	sta	Circle+2
	clc
	adc	#5
	sta	Circle+6
	PushLlcl #Circle
	_PaintOval
	lda	Circle
	clc
	adc	#13
	sta	Circle
	clc
	adc	#4
	sta	Circle+4
	PushLlcl #Circle
	_PaintOval
	stz	LastDigits
	stz	LastDigits+2
	stz	LastDigits+4	;clean up after last time...

	jsr	DrawAll

LessThan	mov	#1,WasAbove

WaitAround	lda	[T2Data1]	;check done ptr in long mode just in case
	bne	Done

	lda	>$E0C02E	;vertical counter, upper 8 bits of it
	and	#$00FF
	rol	a
	cmp	WaitFor
	blt	LessThan

	lda	WasAbove	;check position on screen
	beq	WaitAround	;check if we've already displayed it...
	stz	WasAbove	;flag below
	dec	CountTwo
	bpl	WaitAround
	lda	DClockPrefs
	xba
	and	#$FF
	sta	CountTwo

	jsr	MoveIt
	jsr	GetTimed

*	short	M	
*Wait1d	lda	>$e1C019	;wait for start of next refresh
*	bpl	Wait1d	;so no-blink screen clear
*Wait2d	lda	>$E1C019
*	bmi	Wait2d
*	Long	M	;force at least 1 full wait

	lda	Buffer+$F
	cmp	Digits+4	;seconds changed yet?
	beq	WaitAround
	ldx	OnColor
	lda	Colors,x	;next color
	sta	>$e19e02
	inx
	inx
	cpx	#ColorsLen
	blt	OkColor
	ldx	#0
OkColor	stx	OnColor
DontJump	jsr	Buf2Digs
	jsr	DrawAll
	bra	WaitAround

done	anop
	stz	<16
	stz	<18	;return w/no error
Bye	anop
	pld
	plx
	ply		;return address & bank
	pla
	pla		;T2data2
	pla
	pla		;T2data1
	pla		;Message
	phy
	phx
	plb
	rtl

GetTimed	PushLlcl #Buffer
	_ReadAsciiTime
	ldx	#18
ToLowAscii	lda	Buffer,x
	and	#$7F7F
	sta	Buffer,x
	dex
	dex
	bpl	ToLowAscii
	rts

Buf2Digs	lda	Buffer+9
	cmp	Digits	;hours changed?
	beq	Min2Digs
	sta	Digits	;update in memory
	stz	LastDigits	;and screen update list
            lda	Top
	clc
	adc	#29
	sta	WipeRect+4
	lda	Left
	clc
	adc	#40
	sta	WipeRect+6
	          
	PushLlcl	#WipeRect
	_EraseRect
Min2Digs	lda	Buffer+$C
	sta	Digits+2
	lda	Buffer+$F
	sta	Digits+4
AnRts	long	I,m
	rts

DrawSeconds lda	Left
	clc
	adc	#140
	sta	CharSX
	lda	Digits+5	;fall into DrawDigit
	ldx	#5	;correct place

DrawDigit	and	#$FF	;clear a's hob
	Short	M
	cmp	#$20	;space
	beq	AnRts	;quit if a space
	sec
	sbc	#$30	;mask into 0-9
	bmi	AnRts	;in case out of range
	cmp	#$A
	bge	AnRts
	tay
	lda	DigitBars,y
	eor	LastDigits,x ;get real set of bars to change
	beq	AnRts	;don't draw when nothing to update
	sta	ToDraw
	lda	DigitBars,y	;really what's on now
	sta	LastDigits,x
	Long	I,m	;long mode for tools
	stz	TblOffset
	ldy	#8
DrawStuff	phy		;save counter
	lsr	ToDraw
	bcc	NextBar	;branch if nothing to draw
	ldx	TblOffset
	PushWord Line3EDX,x
	PushWord Line3EDY,x
	PushWord Line3SX,x
	PushWord Line3SY,x
	PushWord Line2EDX,x
	PushWord Line2EDY,x
	PushWord Line2SX,x
	PushWord Line2SY,x
	PushWord Line1EDX,x
	PushWord Line1EDY,x
	PushWord Line1SX,x
	PushWord Line1SY,x
	jsr	ToTL
	_Move
	_Line		;draw 1st line
	jsr	ToTl
	_Move
	_Line		;draw 2nd line
	jsr	ToTl
	_Move
	_Line		;draw 3rd line
NextBar	inc	TblOffset
	inc	TblOffset
	ply
	dey
	beq	AnRts2
	brl	DrawStuff

ToTl	PushWord CharSX
	PushWord Top
	_MoveTo
AnRts2	rts

DrawAll	ldx	#0	;6 digits to put on screen, counting up
	mov	Left,CharSX
DrawEm	phx
	lda	Digits,x
	jsr	DrawDigit
	plx
	txa
	asl	a
	tay
	lda	CharSX
	clc
	adc	Widths,y	;adjust start of next one
	sta	CharSX
	inx
	cpx	#6
	blt	DrawEm
	rts

MoveIt	anop
	Long	I,m
	lda	Left
	cmp	#2
	bge	NotTooLeft
	mov	#1,MoveDirectX
NotTooLeft	lda	Left
	cmp	#319-158
	blt	NotTooRight
	mov	#-1,MoveDirectX
NotTooRight	lda	Top
	cmp	#2
	bge	NotTooHigh
	mov	#1,MoveDirectY
NotTooHigh	lda	Top
	cmp	#199-29
	blt	NotTooLow
	mov	#-1,MoveDirectY
NotTooLow	lda	Top	;y coord
	dec	a	;move one blank line above it for safety
	xba
	lsr	a	;now, y* 128
	pha
	lsr	a	;*64
	lsr	a	;*32
	clc
	adc	1,s
	adc	#$2000
	sta	1,s
	lda	Left
	lsr	a	;320-pixel to byte conv
	dec	a	;minus one for erase area
	clc
	adc	1,s
	sta	TopLeftByte
	pla
	lda	MoveDirectY
	bmi	MovingUp
	lda	#160	;next row is +160 bytes away
	dc	h'cf'	;skip next 3 bytes
MovingUp	lda	#-160
	clc
	adc	MoveDirectX	;could be negative, so keep carry ok
	sta	<DestByte
	lda	MoveDirectY
	bmi	SetMovingUp
	lda	#-160
	sta	AddPos1+1
	lda	TopLeftByte
	clc
	adc	#31*160
	sta	TopLeftByte
	bra	DoDrawing
SetMovingUp lda	#160
	sta	AddPos1+1

DoDrawing	anop

	phb
	php
	sei		;NO interrupts during drawing
	mov	#32,<16	;lines to move
	lda	TopLeftByte
MoveLines	anop
	pha
	tax
	clc
	adc	<DestByte
	tay
	lda	#84	;# bytes to move
MvnLoc	dc	h'54e1e1'	;Mvn e1e1
	pla
	clc
AddPos1	adc	#$a0
	dec	<16	;row counter on dp
	bne	MoveLines
	plp
	plb
	
	lda	Top
	clc
	adc	MoveDirectY
	sta	Top
	clc
	adc	#WaitForVBLd
	sta	WaitFor
	lda	Left
	clc
	adc	MoveDirectX
	clc		;account for wraps
	adc	MoveDirectX	;twice for pixel offsets
	sta	Left
	Long	I,m
	rts



;................................................................
Widths	dc	i'20,40,20,40,20,20'
RowNum	ds	2
OnColor	ds	2
Buffer	ds	20
Digits	ds	6
WipeRect	anop		;has top & left as part of it
Circle	ds	8	;circles to draw
CharSX	ds	2

ToDraw	ds	2
TblOffset	ds	2
LastDigits	ds	6	;last set of them-- for eor purposes
OurDp	ds	2


DigitBars	dc	h'77245d6d2e6b7b257f6f'	;bits show which bars are on
Line1SY	dc	i'0,1,3,12,14,16,24'
Line1SX	dc	i'2,0,13,3,0,13,4'
Line1EDY	dc	i'0,11,7,0,11,7,0'
Line1EDX	dc	i'11,0,0,9,0,0,7'

Line2SY	dc	i'1,2,2,13,15,15,25'
Line2SX	dc	i'3,1,14,2,1,14,3'
Line2EDY	dc	i'0,9,9,0,9,9,0'
Line2EDX	dc	i'9,0,0,11,0,0,9'

Line3SY	dc	i'2,3,1,14,16,14,26'
Line3SX	dc	i'4,2,15,3,2,15,2'
Line3EDY	dc	i'0,7,11,0,7,11,0'
Line3EDX	dc	i'7,0,0,9,0,0,11'


Colors	anop
 dc i'$F00,$F10,$F20,$F30,$F40,$F50,$F60,$F70,$F80,$F90,$FA0,$FB0,$FC0,$FD0,$FE0'
 dc i'$FF0,$EF0,$DF0,$CF0,$BF0,$AF0,$9F0,$8F0,$7F0,$6F0,$5F0,$4F0,$3F0,$2F0,$1F0'
 dc i'$0F0,$0F1,$0F2,$0F3,$0F4,$0F5,$0F6,$0F7,$0F8,$0F9,$0FA,$0FB,$0FC,$0FD,$0FE'
 dc i'$0FF,$0EF,$0DF,$0CF,$0BF,$0AF,$09F,$08F,$07F,$06F,$05F,$04F,$03F,$02F,$01F'
 dc i'$00F,$10F,$20F,$30F,$40F,$50F,$60F,$70F,$80F,$90F,$A0F,$B0F,$C0F,$D0F,$E0F'
 dc i'$F0F,$F0E,$F0D,$F0C,$F0B,$F0A,$F09,$F08,$F07,$F06,$F05,$F04,$F03,$F02,$F01'
ColorsLen	equ	*-Colors

*
*
Setup	anop
*
* Handle the Setup and all. Entry: Accum=T2Message
*
*
	cmp	#MakeT2
	beq	doMake
	cmp	#HitT2
	jeq	doHit
*	cmp	#KillT2
*	jeq	doKill
	cmp	#SaveT2
	jeq	doSave
	cmp	#LoadSetupT2
	jeq	doLoadSetup
*	cmp	#UnloadSetupT2
*	jeq	doUnloadSetup
	brl	Done

*=================================================
*
*	Create	all	the	buttons	in	the	window
*
doMake	anop

	lda	T2data1+2
	sta	WindPtr+2
	lda	T2data1
	sta	WindPtr
	lda	T2data2
	sta	RezFileID
	WordResult
	_MMStartUp
	PullWord	MyID

	LongResult
	PushLong	WindPtr
	PushWord	#9	;resource 2 resource
	PushLong	#1	;resource item ID=1
	_NewControl2
	plx
	plx		;chuck result out

* Make sure we're dealing with the T2pref file.

	WordResult
	_GetCurResourceFile
	PushWord	RezFileID
	_SetCurResourceFile

	jsr	load_setup

noShapes1	anop
MoveOn	_SetCurResourceFile

	lda	DClockPrefs
	xba
	and	#$FF
	clc
	adc	#$12B	;first item id #-1 (1=12c)

	pha
	LongResult
	PushLong	WindPtr
	PushLong	#1	;speed control #
	_GetCtlHandleFromID
	_SetCtlValue

	lda	DClockPrefs
	and	#$FF
	clc
	adc	#$132	;first item id #

	pha
	LongResult
	PushLong	WindPtr
	PushLong	#2	;type control #
	_GetCtlHandleFromID
	_SetCtlValue

	lda	#4
	sta	T2Result
	brl	Bye

*=================================================



temp	ds	4

rDClockPrefs	str	'Clocks:      Prefs'
DClockPrefs	ds	2

* Format: Upper byte=clock type (ignored for now)
*                   0=DClock; 1= AClock; 2=Random on Entry
*         Lower byte=Refreshes between movement...

*=================================================
doLoadSetup	anop

	jsr	load_setup
	brl	Bye

load_setup	anop

*	Load	the	fps/maxzoom/delay	resource.

	LongResult
	Pushword	#rT2ModuleWord ;type
	PushLong	#rDClockPrefs
	_RMLoadNamedResource
	bcc	PrefsThere
	plx
	plx		;setup not saved yet...
	lda	#$0203	;Random Clock Type; Normal Speed
	sta	DClockPrefs
	bra	NoPrefs

PrefsThere	anop
	makePdp
	lda	[3]
	sta	DClockPrefs
	killLdp

	PushWord	#3	;purge levek
	PushWord	#rT2ModuleWord	;rtype for release

	LongResult
	PushWord	#rT2ModuleWord
	PushLong	#rDClockPrefs
	PushLong	#Temp	;don't care about filenum, but toolbox does
	_RMFindNamedResource	;get it
	_ReleaseResource	;and throw it out. We have a copy now :)

NoPrefs	rts

*========
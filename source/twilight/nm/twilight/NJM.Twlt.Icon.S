SharkXYRts	anop
	ply		;for getting out in a hurry
	plx
	rts

NormalMove	ldx	NumMoves	;x-reg for random #ing
	beq	SharkXYRts	;if no moves available, do nothing
	jsr	RandomX
	asl	a
	tax		;offset in Table
	lda	FreeYPlaces,x
	tay
	lda	FreeXPlaces,x
	tax
NewSharkPos	lda	#Shark
	jsr	DrawIt	;draw shark in new place
	lda	SharkData
	and	#$FF	;breed bits
	cmp	SharkBreed	;time for shark to breed?
	bge	BreedShark
	inc	a
	pha
	lda	SharkData
	and	#$FF00	;mask out breed bits
	ora	1,s	;and put new ones in
	ora	#$8000	;make it a shark
	jsr	PutInField	;in new place
	pla
	ply
	plx		;original place
	lda	#0	;free
	jsr	PutInFieldC
	lda	#Water
	brl	DrawIt	;put water in old place
BreedShark	lda	SharkData
	and	#$8F00	;clean out breed bits
	ora	#$8001	;just bred
	inc	NumSharks
	jsr	PutInField
	ply
	plx		;original place
	brl	PutInFieldC

EvalCenter	ds	2
EvalAround	stz	NumMoves
	stz	NumFood
	phx
	phy		;save for safety
	jsr	GetOffset
	stx	EvalCenter
	lda	3,s	;x
	tax
	iny
	cpy	#24
	blt	CanChkDown
	ldy	#0	;wrap to top of screen
	jsr	ChkPlace
	bra	DoneChkDown
CanChkDown	lda	EvalCenter
	clc
	adc	#64	;one row down
	tax
	lda	3,s	;x-value
	jsr	ChkPlace2	;and faster ops
DoneChkDown	lda	1,s
	tay		;restore value
	lda	3,s
	tax		;restore values
	dey
	bpl	CanChkUp
	ldy	#23	;wrap to bottom
	jsr	ChkPlace
	bra	DoneChkUp
CanChkUp	lda	EvalCenter
	sec
	sbc	#64
	tax
	lda	3,s	;x-value
	jsr	ChkPlace2	;faster ops
DoneChkUp	lda	1,s
	tay		;restore value
	lda	3,s
	tax		;restore values
	inx
	cpx	#32	;off right?
	blt	CanChkRight
	ldx	#0
	jsr	ChkPlace
	bra	DoneChkRight
CanChkRight	lda	EvalCenter
	inc	a
	inc	a	;one square to the right
	tax
	lda	3,s	;x-value
	inc	a
	jsr	ChkPlace2
DoneChkRight lda	3,s
	tax		;restore value
	lda	1,s
	tay
	dex
	bpl	CanChkLeft
	ldx	#31	;off top.
	jsr	ChkPlace
	bra	FishXYRts	;get out of here
CanChkleft	lda	EvalCenter
	dec	a
	dec	a
	tax
	lda	3,s
	dec	a	;proper x-value
	jsr	ChkPlace2
FishXYRts	ply		;don't change this area!
	plx		;clean up stack
	rts

HandleFish	phx
	phy		;for safety
	jsr	EvalAround
	lda	NumMoves	;x-reg for random #ing
	beq	FishXYRts	;if no moves available, do nothing
	jsr	GetFromFieldC ;get time till breed
	pha
	ldx	NumMoves	;value to restrict to
	jsr	RandomX
	asl	a
	tax		;offset in Table
	lda	FreeYPlaces,x
	tay
	lda	FreeXPlaces,x
	tax
	lda	#Fish
	jsr	DrawIt	;draw fish in new place
	pla
	cmp	FishBreed	;time for fish to breed?
	bge	BreedEm
	inc	a
	jsr	PutInField	;in new place
	ply
	plx		;original place
	lda	#Water
	jsr	DrawIt	;put water in old place
	lda	#0	;free
	brl	PutInFieldC
BreedEm	lda	#1	;just bred
	jsr	PutInField
	ply
	plx		;original place
	jsr	PutInFieldC
	inc	NumFish
	lda	#Fish
	brl	DrawIt

NumMoves	ds	2
NumFood	ds	2
FreeXPlaces	ds	10	;space for positions
FreeYPlaces	ds	10
FoodXPlaces	ds	10
FoodYPlaces	ds	10


RandomX	LongResult
	jsr	Random
	cpx	#1	;modulo 1 (==> 0)?
	beq	Return0
	cpx	#2	;mod 2 ==> 0 or 1
	beq	Return01
	pha
	phx
	_UDivide
	pla
	pla		;modulo result
	rts
Return0	pla
	pla		;clean up stack
	lda	#0	;anything mod 1 is 0
	rts
Return01	plx
	plx		;clean up stack
	and	#$1	;real fast mod 2
	rts

RandomXY	anop
	LongResult
	WordResult
	_Random		;random #
	PushWord	#32	;divide by
	_UDivide
	pla		;leave modulo on stack
	LongResult
	WordResult
	_Random		;random #
	PushWord	#24	;divide by
	_UDivide
	pla		;leave modulo on stack
	ply		;0-23
	plx		;0-32
	jsr	GetFromField
	cmp	#0	;check a-reg
	bne	RandomXY	;loop back until empty space
	rts
                                                        
done	anop
Bye	anop
	lda	EntryStack
	tcs
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

JustMoved	ds	2
Random	lda	[10]
	bne	Done
	stz	JustMoved
	lda	>$E0C02E
	xba		;volatile bits in low byte
	cmp	LastVCtr
	blt	NewPals
	sta	LastVCtr	;store updated position
QuitRandom	rts		;return with highly variable results
NewPals	inc	JustMoved
	sta	LastVCtr	;keep updating position
	dec	WaitVBLs
	bpl	QuitRandom
	mov	#15,WaitVBLs
	phx
	lda	ScreenBank	;depends on shadowing...
	pha
	plb
	plb
	ldx	#PalLen
PalRef	lda	>Pal1,x
	sta	$9e00,x
	dex
	dex
	bpl	PalRef
	phk
	plb		;back to program bank
	lda	PalRef+1	;address of palette
	clc
	adc	#32	;next palette in program
	cmp	#Pal4+1	;past last one?
	blt	SetNewPal
	lda	#Pal1	;if so, go back to 1st
SetNewPal	sta	PalRef+1
	plx		;restore value
	lda	LastVCtr	;and random #
	rts

DrawIt	pha
	phx
	phy		;save values
	tya
	asl	a
	asl	a
	asl	a	;*8
	clc
	adc	#256
	pha		;max of what to wait for
	sec
	sbc	#30	;minimum
	pha
ChkVblDraw	jsr	Random	;keep random #s up
	lda	>$e0c02e
	and	#$FF
	rol	a	;make proper counter
	cmp	1,s	;min
	blt	DoDraw
	cmp	3,s	;max
	blt	ChkVblDraw
DoDraw	pla
	pla

	tya		;start plot at y*1280+x*5+$2000
	xba
	pha		;*256
	asl	a
	asl	a	;*1024
	clc
	adc	1,s
	sta	1,s	;keep on stack
	lda	5,s	;x posn
	asl	a
	asl	a
	clc
	adc	5,s	;x*5
	adc	1,s	;y*1280
	adc	#$2000	;start of screen in bank
	ply		;temp value
	tax		;target location
	lda	5,s	;pic to draw
	asl	a
	tay
	lda	BMGTbl,y
	sta	SourceLoc1+1	;now, ready to draw
	sta	SourceLoc2+1	;now, ready to draw
	sta	SourceLoc3+1	;now, ready to draw
	ldy	#0
SourceLoc1	lda	|0,y
TargetLoc1	sta	>$e10000,x
	iny
	iny
SourceLoc2	lda	|0,y
TargetLoc2	sta	>$e10002,x
	iny
SourceLoc3	lda	|0,y
TargetLoc3	sta	>$e10003,x	;5 bytes/row to move in
	txa
	clc
	adc	#$A0	;go on to next row
	tax
	iny
	iny
	cpy	#40
	blt	SourceLoc1
	ply
	plx
	pla
	rts

OutOfRange	brk	$95
GetOffset	pha		;save a-reg
*	cpx	#32
*	bge	OutOfRange
*	cpy	#24
*	bge	OutOfRange

	tya		;offset= 64 * y + 2*x
	xba		;*256
	lsr	a
	lsr	a	;now * 64
	pha		;save on stack
	txa
	asl	a	;double it for word offsets
	clc
	adc	1,s
	tax
	pla		;temp value
	pla		;orig value
	rts

GetFromField phx
	jsr	GetOffset
	lda	Moved,x
	bne	BadLoc
	lda	TheField,x
	clc
	plx
	rts

BadLoc	sec
	lda	TheField,x
	plx
	rts

PutInField	phx
	jsr	GetOffset
	sta	TheField,x
	inc	Moved,x
	plx
	rts

GetFromFieldC phx
	ldx	CenterOffset
	lda	Moved,x
	bne	BadLoc
	lda	TheField,x
	clc
	plx
	rts

PutInFieldC	phx
	ldx	CenterOffset
	sta	TheField,x
	inc	Moved,x
	plx
	rts

LastVCtr	ds	2
ScreenBank	ds	2
OldBorder	ds	2
WaitVBLs	ds	2
FishBreed	dc	i'3'
SharkBreed	dc	i'4'
Starve	dc	i'3'
StNumFish	dc	i'380'
StNumSharks	dc	i'40'
NumFish	ds	2
NumSharks	ds	2
EntryStack	ds	2
TheField	ds	32*24*2+8
Moved	ds	32*24*2+8
CenterOffset ds	2
OnColor	dc	i'StartBlue'

*
*
* Bit-Mapped Graphics
*
*
BMGTbl	dc	a'H2OBMG,SharkBMG,FishBMG'

H2OBMG	anop
 dc h'4432114321'
 dc h'3321443214'
 dc h'2214332143'
 dc h'1143221432'
 dc h'4432114321'
 dc h'3321443214'
 dc h'2214332143'
 dc h'1143221432'

FishBMG	anop
 dc h'4662614321'
 dc h'6776743214'
 dc h'7667632143'
 dc h'1773721432'
 dc h'4432118828'
 dc h'3321489989'
 dc h'2214398898'
 dc h'1143229939'

SharkBMG	anop
 dc h'4432114321'
 dc h'3321F43214'
 dc h'F214CF2143'
 dc h'CDDDCCDDD2'
 dc h'4CCCCCCCEF'
 dc h'3BBBBBBBBB'
 dc h'B214332143'
 dc h'1143221432'

Pal1	anop
 dc i'$000,$007,$009,$00C,$00F,$0FFF'	;water colors  0
 dc i'$77F,$009,$009,$88F,$00F'		;fish colors   12
 dc i'$00F,$777,$999,$E00,$BBB'		;shark colors  22
PalLen	equ	*-Pal1-2

Pal2	anop
 dc i'$000,$00F,$007,$009,$00C,$0FFF'	;water colors
 dc i'$00F,$88F,$00C,$99F,$00F'		;fish colors
 dc i'$00C,$787,$9A9,$D00,$BAA'		;shark colors

Pal3	anop
 dc i'$000,$00C,$00F,$007,$009,$0FFF'	;water colors
 dc i'$00F,$77F,$88F,$007,$00F'		;fish colors
 dc i'$787,$9A9,$00F,$00E,$00C'		;shark colors

Pal4	anop
 dc i'$000,$009,$00C,$00F,$007,$0FFF'	;water colors
 dc i'$88F,$007,$99F,$008,$00F'		;fish colors
 dc i'$777,$999,$00F,$00E,$00C'		;shark colors

MaxColor	ds	2
Red	ds	2
Green	ds	2
Blue	ds	2
WaitInc	ds	2
NewColors	anop
	jsr	PrintStats
	lda	Prefs
	beq	NoNewColors
	dec	WaitInc
	bmi	CanInc
	mov	#2,WaitInc
NoNewColors	rts
	
CanInc	ldx	OnColor
	lda	Colors,x	;next color
	sta	MaxColor
	inx
	inx
	cpx	#ColorsLen
	blt	OkColor
	ldx	#0
OkColor	stx	OnColor
	short	M
Wait1u	lda	>$e0C019	;wait for start of next refresh
	bpl	Wait1u	;so no-blink screen color change
Wait2u	lda	>$e0C019
	bmi	Wait2u
	Long	M

	lda	MaxColor
	sta	Pal1+20
	sta	Pal2+20
	sta	Pal3+20
	sta	Pal4+20	;text color at bottom of screen

	tax		;save for a while
	and	#$F	;blue bits
	sta	Blue
	txa
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	and	#$F
	sta	Green
	txa
	xba
	and	#$F
	sta	Red
	lda	#FullTbl
	jsr	RestrictColor
	sta	Pal1+8
	sta	Pal2+2
	sta	Pal3+4
	sta	Pal4+6
	sta	Pal1+22
	sta	Pal1+28
	sta	Pal2+12
	sta	Pal3+12
	sta	Pal3+26
	sta	Pal3+28
	sta	Pal4+26
	sta	Pal4+28
	ora	#$AAA
	sta	Pal1+12
	sta	Pal1+18
	sta	Pal2+14
	sta	Pal2+18
	sta	Pal3+14
	sta	Pal3+16
	sta	Pal4+12
	sta	Pal4+16
	
	lda	#TQTbl
	jsr	RestrictColor
	sta	Pal1+6
	sta	Pal2+8
	sta	Pal3+2
	sta	Pal4+4
	sta	Pal2+16
	sta	Pal2+22
	sta	Pal2+28
	sta	Pal3+30
	sta	Pal4+30

	lda	#HalfTbl
	jsr	RestrictColor
	sta	Pal1+4
	sta	Pal2+6
	sta	Pal3+8
	sta	Pal4+2
	sta	Pal1+14
	sta	Pal1+16

	lda	#OneQTbl
	jsr	RestrictColor
	sta	Pal1+2
	sta	Pal2+4
	sta	Pal3+6
	sta	Pal4+8
	sta	Pal3+18
	sta	Pal4+14
	sta	Pal4+18
	rts

NRed	ds	2
NGreen	ds	2
NBlue	ds	2

RestrictColor sta	Restrict1+1
	sta	Restrict2+1
	sta	Restrict3+1
	lda	Red
	asl	a
	tax
Restrict1	lda	|0,x
	sta	NRed
	lda	Green
	asl	a
	tax
Restrict2	lda	|0,x
	sta	NGreen
	lda	Blue
	asl	a
	tax
Restrict3	lda	|0,x
	sta	NBlue
	lda	NRed
	asl	a
	asl	a
	asl	a
	asl	a
	ora	NGreen
	asl	a
	asl	a
	asl	a
	asl	a
	ora	NBlue
	rts
	

Colors	anop
 dc i'$F00,$F10,$F20,$F30,$F40,$F50,$F60,$F70,$E70,$E80,$D80,$D90,$C90,$CA0'
 dc i'$BA0,$BB0,$AB0,$AC0,$9C0,$9D0,$8D0'
 dc i'$8E0,$7F0,$6F0,$5F0,$4F0,$3F0,$2F0,$1F0'
 dc i'$0F0,$0F1,$0F2,$0F3,$0F4,$0F5,$0F6,$0F7,$0E7,$0E8,$0D8,$0D9,$0C9,$0CA'
 dc i'$0BA,$0BB,$0AB,$0AC,$09C,$09D,$08D'                                   
 dc i'$08E,$07F,$06F,$05F,$04F,$03F,$02F,$01F'
StartBlue	equ	*-Colors
 dc i'$00F,$10F,$20F,$30F,$40F,$50F,$60F,$70F,$70E,$80E,$80D,$90D,$90C,$A0C'
 dc i'$A0B,$B0B,$B0A,$C0A,$C09,$D09,$D08'
 dc i'$E08,$F07,$F06,$F05,$F04,$F03,$F02,$F0
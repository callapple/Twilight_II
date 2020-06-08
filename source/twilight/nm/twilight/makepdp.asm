	keep	SNF
	mcopy	SNF.Macs
	copy	T2Common.equ
	copy	18/e16.memory

SNF	Start
Water	equ	0
Shark	equ	1
Fish	equ	2
WaitHz	equ	40
	phb		;Store old data bank
	phk
	plb

	phd
	tsc
	inc	a
	tcd
	tsc
	sta	EntryStack

	lda	T2Message	;action code?
	cmp	#2
	beq	StartBlank
	brl	Setup


StartBlank	anop
	stz	16
	stz	18	;return w/no error

	lda	>$00c035
	and	#8	;shadowing on?
	bne	NoShadow
	lda	#$0101	;if so, faster draw to bank 01
	dc	h'cf'
NoShadow	lda	#$E1E1
	sta	ScreenBank
	short	M
	sta	TargetLoc1+3	;bank to draw to
	sta	TargetLoc2+3	;bank to draw to
	sta	TargetLoc3+3	;bank to draw to
	Long	M

	jsr	Random	;update screen pallettes

NewScreen	jsr	WipeAllText
	lda	#CreateTxt
	ldx	#$7800+48
	jsr	PrintTxt

	ldx	#0
MakeNewCol	ldy	#0
CreateCol	lda	#0
	jsr	PutInField
	jsr	DrawIt
	jsr	Random	;animate screen
	iny
	cpy	#24
	blt	CreateCol
	inx
	cpx	#32
	blt	MakeNewCol	;do whole screen

	ldx	StNumFish
	stx	NumFish
MakeFish	phx
	jsr	RandomXY
	lda	#Fish
	jsr	DrawIt
	phx
	phy		;save thru toolbox
	ldx	FishBreed
	inx
	jsr	RandomX	;get a random #
	inc	a
	ply
	plx
	jsr	PutInField
	plx
	dex
	bne	MakeFish

	ldx	StNumSharks
	stx	NumSharks
MakeSharks	phx
	jsr	RandomXY
	l
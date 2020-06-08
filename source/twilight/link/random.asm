
*------------------------------------------------*
* "random" returns a random number in A          *
* "set_seed" seeds the generator from the clock  *
*                                                *
* Adapted from the Merlin 16+ package by Derek   *
* Young.                                         *
*------------------------------------------------*

	case	on

random	Start
	clc
	phx
	phy
	ldx	INDEXI
	ldy	INDEXJ
	lda	ARRAY-2,X
	adc	ARRAY-2,Y
	sta	ARRAY-2,X
	dex
	dex
	bne	DY
	ldx	#17*2 ;Cycle index if at end of
DY	dey	; the array
	dey
	bne	SETIX
	ldy	#17*2
SETIX	stx	INDEXI
	sty	INDEXJ
	ply
	plx
	rtl

INDEXI	dc	i'17*2' ;The relative positions of
INDEXJ	dc	i'5*2' ; these indexes is crucial

ARRAY	dc	i'1,1,2,3,5,8,13,21,54,75,129,204'
	dc	i'323,527,850,1377,2227'

seed	anop
	pha
	ora	#1	;At least one must be odd
	sta	ARRAY
	stx	ARRAY+2
	phx	;Push index regs on stack
	phy
	ldx	#30
loop	sta	ARRAY+2,X
	dex
	dex
	lda	1,S	;Was Y
	sta	ARRAY+2,X
	dex
	dex
	lda	3,S	;Was X
	sta	ARRAY+2,X
	lda	5,S	;Original A
	dex
	dex
	bne	loop
	lda	#17*2
	sta	INDEXI	;Init proper indexes
	lda	#5*2 ; into array
	sta	INDEXJ
	jsl	random	;Warm the generator up.
	jsl	random
	jsl	random
	jsl	random
	ply
	plx
	pla
	rtl

VERTCNT	equ	>$E0C02E	;Vertical scanline counter

* Set random number seed

set_random_seed entry
	pha
	pha
	ldx	#$2503	;_GetTick
	jsl	$E10000
	ply
	pla
	eor	#'DY'	;mix X up a bit (it's not as random)
	tax
	lda	VERTCNT
	bra	seed

	End
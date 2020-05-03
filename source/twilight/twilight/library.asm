         setcom 80
	mcopy	library.mac
	keep	library
	copy	equates
	copy	debug.equ
*-----------------------------------------------------------------------------*
* Twilight II's LIBRARY.ASM Source Code Segment (Part of the INIT.)
* Segmented: 18 January 1993 - JRM.
*-----------------------------------------------------------------------------*
* Random routines... v1.0
*-----------------------------------------------------------------------------*
random	Start
	debug	'random'

	copy	22:debug.asm

	phb
	phk
	plb
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
	bne	JM_DY
	ldx	#17*2	;Cycle index if at end of
JM_DY	dey		; the array
	dey
	bne	SETIX
	ldy	#17*2
SETIX	stx	INDEXI
	sty	INDEXJ
	ply
	plx
	plb
	rtl

INDEXI	dc	i'17*2'	;The relative positions of
INDEXJ	dc	i'5*2'	; these indexes is crucial

ARRAY	dc	i'1,1,2,3,5,8,13,21,54,75,129,204'
	dc	i'323,527,850,1377,2227'

seed	anop
	pha
	ora	#1	;At least one must be odd
	sta	ARRAY
	stx	ARRAY+2
	phx		;Push index regs on stack
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
	lda	#5*2	; into array
	sta	INDEXJ
	jsl	random	;Warm the generator up.
	jsl	random
	jsl	random
	jsl	random
	ply
	plx
	pla
	plb
	rtl

* Set random number seed
* v1.0.1 JRM 29 Nov 1992 - more random :-)  (readtimehex)            (v1.0.1b1)
* v1.0.2 JRM 19 Dec 1992 - yet more random. much better.             (v1.0.1b3)
* v1.0.3 JRM 30 Dec 1992 - hopefully fixed fINALLY                   (v1.0.1b3)

set_random_seed entry
	debug	'set_random_seed'
	phb
	phk
	plb

	~GetTick
	pla
	sta	fill1+1
	pla
	sta	fill2+1

	~ReadTimeHex
	lda	7,s	; day of week | filler
;	and	#$FFF0	; isolate day of week + hi nib fill
	ror	a
	ror	a
	ror	a
	ror	a
	sta	7,s

	lda	1,s	; minute | second
	and	#$F0FF	; isolate hi nib min + second
	rol	a	
	rol	a
	rol	a
	rol	a
	tax
	lda	$FF0000,x
	xba
	eor	1,s
	eor	5,s	; month | date
	eor	7,s
fill1	eor	#0
	eor	VERTCNT
	tay

	lda	7,s
	xba
	sta	7,s

	lda	1,s	; minute | second
	and	#$0FFF	; isolate lo nib min + second
	xba
	tax
	lda	$FE0000,x
	xba
;	ora	5,s
;	and	3,s	; current year | hour
	eor	7,s
	eor	1,s
fill2	eor	#0
	eor	VERTCNT

	tyx
	ply
	ply
	ply
	ply		
	brl	seed

	lda	1,s	; minute | second
	xba
	eor	1,s
	eor	5,s	; month | date
	eor	7,s
	tax

	lda	7,s
	xba
	sta	7,s

	lda	1,s	; minute | second
;	and	#$00FF	; isolate second
	ora	5,s
;;	eor	3,s	; current year | hour
	and	3,s	; current year | hour
	eor	7,s
	eor	1,s

	End
*-----------------------------------------------------------------------------*
* Plot Routines:
* v1.0 - 17-8 Jan 1993 - JRM - coded
*-----------------------------------------------------------------------------*
setup_plot	Start

dbr	equ	1
rtlAddr	equ	dbr+1
screenPtr	equ	rtlAddr+3
lookupPtr	equ	screenPtr+4

	phb
	phk
	plb

	lda	lookupPtr,s
	sta	patchLook+1
	lda	lookupPtr+2,s
	shortm
	sta	patchLook+3
	longm

	lda	screenPtr,s
	sta	screen1+1
	sta	screen2+1
	lda	screenPtr+2,s
	shortm
	sta	screen1+3
	sta	screen2+3
;	lda	#$C1
;	sta	$e1c029
	longm

	plb
	lda	1,s
	sta	1+8,s
	lda	2,s
	sta	2+8,s
	plx
	plx
	plx
	plx
	rtl

	End
*-----------------------------------------------------------------------------*
set_pixel	Start

dbr	equ	1
rtlAddr	equ	dbr+1
x_coord	equ	rtlAddr+3
y_coord	equ	x_coord+2
color	equ	y_coord+2

	phb
	phk
	plb

	lda	y_coord,s
	cmp	#200
	bge	return
	lda	x_coord,s
	cmp	#320
	bge	return

	lda	x_coord,s
	lsr	a
	sta	x_div2+1

	lda	y_coord,s
	jsr	getLookup
	clc
x_div2	adc	#0	;x_div2
	tax

	lda	x_coord,s
	bit	#1
	bne	loNibble

hiNibble	anop
	lda	color,s
	asl   a
	asl	a
	asl	a
	asl	a
	shortm
	sta	color_ls4+1

	jsr	readPixel
	and	#$0F
color_ls4	ora	#0	;color_ls4
	jsr	writePixel
	bra	all_set

loNibble	anop
	shortm
	jsr	readPixel
	and	#$F0
	ora	color,s
	jsr	writePixel

all_set	longm

return	plb
	lda	1,s
	sta	1+6,s
	lda	2,s
	sta	2+6,s
	plx
	plx
	plx
	rtl

	End
*-----------------------------------------------------------------------------*
get_pixel	Start

dbr	equ	1
rtlAddr	equ	dbr+1
x_coord	equ	rtlAddr+3
y_coord	equ	x_coord+2

	phb
	phk
	plb

	lda	y_coord,s
	cmp	#200
	blt	y_good
	ldy	#$F
	bra	return
x_bad	anop
	ldy	#0
	bra	return
y_good	lda	x_coord,s
	cmp	#320
	bge	x_bad

	lda	x_coord,s
	lsr	a
	sta	x_div2+1

	lda	y_coord,s
	jsr	getLookup
	clc
x_div2	adc	#0	;x_div2
	tax

	lda	x_coord,s
	bit	#1
	bne	loNibble

hiNibble	anop
	shortm
	jsr	readPixel
	and	#$F0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	bra	all_set

loNibble	anop
	shortm
	jsr	readPixel
;	and	#$0F

all_set	longm
	and	#$000F
	tay
return	plb
	lda	1,s
	sta	1+4,s
	lda	2,s
	sta	2+4,s
	plx
	plx
	tya
	rtl

	End
*-----------------------------------------------------------------------------*
readPixel	Start

screen1	entry
	lda	>0,x
	rts

	End
*-----------------------------------------------------------------------------*
writePixel	Start

screen2	entry
	sta	>0,x
	rts

	End
*-----------------------------------------------------------------------------*
getset_pixel	Start

dbr	equ	1
rtlAddr	equ	dbr+1
x_coord	equ	rtlAddr+3
y_coord	equ	x_coord+2
color	equ	y_coord+2

	phb
	phk
	plb

	lda	#0
	sta	returnPixel+1

	lda	y_coord,s
	cmp	#200
	blt	y_good
	lda	#$F
	sta	returnPixel+1
	bra	return
y_good	lda	x_coord,s
	cmp	#320
	bge	return	; x is bad

	lda	x_coord,s
	lsr	a
	sta	x_div2+1

	lda	y_coord,s
	jsr	getLookup
	clc
x_div2	adc	#0	;x_div2
	tax

	lda	x_coord,s
	bit	#1
	bne	loNibble

hiNibble	anop
	lda	color,s
	asl   a
	asl	a
	asl	a
	asl	a
	shortm
	sta	color_ls4+1

	jsr	readPixel
	pha
	and	#$F0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	sta	returnPixel+1
	pla
	and	#$0F
color_ls4	ora	#0	;color_ls4
	jsr	writePixel
	bra	all_set

loNibble	anop
	shortm
	jsr	readPixel
	pha
	and	#$0F
	sta	returnPixel+1
	pla
	and	#$F0
	ora	color,s
	jsr	writePixel

all_set	longm

return	plb
	lda	1,s
	sta	1+6,s
	lda	2,s
	sta	2+6,s
	plx
	plx
	plx
returnPixel	lda	#0
	rtl

	End
*-----------------------------------------------------------------------------*
getLookup	Start

	asl	a
	tax
patchLook	entry
	lda	>0,x
	rts

	End
*-----------------------------------------------------------------------------*

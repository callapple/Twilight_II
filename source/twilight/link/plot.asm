
	mcopy	plot.mac
	keep	plot.c
	case	on
	objcase on

init_plot	Start

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

set_pixel	Start

dbr	equ	1
rtlAddr	equ	dbr+1
x_coord	equ	rtlAddr+3
y_coord	equ	x_coord+2
color	equ	y_coord+2

	phb
	phk
	plb

;	brk

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

readPixel	Start

screen1	entry
	lda	>0,x
	rts

	End

writePixel	Start

screen2	entry
	sta	>0,x
	rts

	End

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

getLookup	Start

	asl	a
	tax
patchLook	entry
	lda	>0,x
	rts

	End
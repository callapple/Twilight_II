
	mcopy	meltplot.mac
	keep	meltplot.c
	case	on
	objcase on
*-----------------------------------------------------------------------------*
SHADOW	gequ	>$E0C035
*-----------------------------------------------------------------------------*
* extern void init_save_restore(char * screenPtr, char * lookupPtr);

init_save_restore Start

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
* extern void save_pixels(char * buffer, int line, int byte_offset, int byte_width);

save_pixels	Start

dbr	equ	1
rtlAddr	equ	dbr+1
buffer	equ	rtlAddr+3
line	equ	buffer+4
byte_offset	equ	line+2
byte_width	equ	byte_offset+2

	phb
	phk
	plb

	lda	line,s
	cmp	#200
	bge	return
	lda	byte_offset,s
	cmp	#160
	bge	return
	lda	byte_width,s
	cmp	#160+1
	bge	return	

;	lda	x_coord,s
;	lsr	a
;	sta	x_div2+1

	lda	buffer,s
	sta	bufferFill+1
	lda	buffer+2,s
	xba
	sta	bankFill+1

	lda	byte_width,s
	sta	widthFill+1

	lda	line,s
	jsr	getLookup
	clc
	adc	byte_offset,s
	tax


bankFill	pea	0
	plb
	plb

	ldy	#0
copyBuffer	jsr	readPixel
bufferFill	sta	|$0000,y
	iny
	iny
	inx
	inx
	cpx	#$9D00
	bge	return
widthFill	cpy	#0
	blt	copyBuffer

return	plb
	lda	1,s
	sta	1+10,s
	lda	2,s
	sta	2+10,s
	plx
	plx
	plx
	plx
	plx
	rtl

	End
*-----------------------------------------------------------------------------*
* extern void restore_pixels(char * buffer, int line, int byte_offset, int byte_width);

restore_pixels	Start

dbr	equ	1
rtlAddr	equ	dbr+1
buffer	equ	rtlAddr+3
line	equ	buffer+4
byte_offset	equ	line+2
byte_width	equ	byte_offset+2

	phb
	phk
	plb

	lda	line,s
	cmp	#200
	bge	return
	lda	byte_offset,s
	cmp	#160
	bge	return
	lda	byte_width,s
	cmp	#160+1
	bge	return

	lda	buffer,s
	sta	bufferFill+1
	lda	buffer+2,s
	xba
	sta	bankFill+1

	lda	line,s
	jsr	getLookup
	clc
	adc	byte_offset,s
	tax

	lda	byte_width,s
	sta	widthFill+1

bankFill	pea	0
	plb
	plb

	ldy	#0
copyBuffer	anop
bufferFill	lda	|$0000,y
	jsr	writePixel
	iny
	iny
	inx
	inx
	cpx	#$9D00
	bge	return
widthFill	cpy	#0
	blt	copyBuffer

return	plb
	lda	1,s
	sta	1+10,s
	lda	2,s
	sta	2+10,s
	plx
	plx
	plx
	plx
	plx
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
getLookup	Start

	asl	a
	tax
patchLook	entry
	lda	>0,x
	rts

	End
*-----------------------------------------------------------------------------*
* extern void scroll_rect(rect * rect, char * buffer);
* Limits:
*  - will only scroll one line down..
*  - will only work with word aligned rects..
*  - rect "bottom" will be assumed TO BE 199

scroll_rect	Start

dpr	equ	1
dbr	equ	dpr+2
rtlAddr	equ	dbr+1
rect	equ	rtlAddr+3
buffer	equ	rect+4

oTop	equ	0
oLeft	equ	oTop+2
oBottom	equ	oLeft+2
oRight	equ	oBottom+2

	phb
	phk
	plb
	phd
	tsc
	tcd

;	ldy	#oTop
	lda	[rect]	; top
	cmp	#199
	bge	return
	ldy	#oRight
	lda	[rect],y
	cmp	#160
	bge	return

	ldy	#oRight
	lda	[rect],y
	ldy	#oLeft
	sec
	sbc	[rect],y
	sta	byte_width

;	ldy	#oLeft
	lda	[rect],y
	sta	start_byte_offset

	lda	[rect]	; top
	sta	top
;	ldy	#oBottom
;	lda	[rect],y	; will be 199
;	dec	a	; down to 198
	lda	#198
	sta	bottom

scroll_loop	PushWord byte_width
	PushWord start_byte_offset
	PushWord bottom
	pei	buffer+2
	pei	buffer
	jsl	save_pixels

	PushWord byte_width
	PushWord start_byte_offset
	lda	bottom
	inc	a
	pha
	pei	buffer+2
	pei	buffer
	jsl	restore_pixels

	dec	bottom
	lda	bottom
	bmi	return
	cmp	top
;	beq	return	; neu
	bge	scroll_loop

return	pld
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

byte_width	ds	2
start_byte_offset ds	2
top	ds	2
bottom	ds	2

	End
*-----------------------------------------------------------------------------*
restore_screen	Start

dpr	equ	1
dbr	equ	dpr+2
rtlAddr	equ	dbr+1
savedScreenP	equ	rtlAddr+3

	phb
	phk
	plb
	phd
	tsc
	tcd

;	brk

	lda	flitter+1
	eor	#1
	sta	flitter+1

flitter	lda	#0
	bne	backwards

	shortm
	lda	SHADOW
	longm
	bit	#$08
	bne	restoreE1

restore01	anop
	ldy	#$7D00-2+200
rest01_loop	anop
	tyx
	lda	[savedScreenP],y
	sta	>$012000,x
	dey
	dey
	bpl	rest01_loop
	bra	done

restoreE1	anop
	ldy	#$7D00-2+200
restE1_loop	anop
	tyx
	lda	[savedScreenP],y
	sta	>$E12000,x
	dey
	dey
	bpl	restE1_loop
	bra	done

backwards	anop
	lda	#$E120
	sta	shrAddr+2
	shortm
	lda	#$E1
	sta	zayro+3
	longm




	ldx	#200-2
fixSCB	lda	>$E19D00,x
	and	#$F0F0
	sta	>$E19D00,x
	dex
	dex
	bpl	fixSCB








	shortm
	lda	SHADOW
	longm
	bit	#$08
	bne	restoreE1_back
restore01_back	anop
	lda	#$0120
	sta	shrAddr+2
	shortm
	lda	#$01
	sta	zayro+3
	longm

restoreE1_back	anop
	ldx	#0
	ldy	#198	;199
copyEm	phx
	phy
	jsr	copyLine
	ply
	plx
	inx
	dey
	bpl	copyEm


;	brk
;	ldy	#$7D00	;-2+200
;	ldx	#200-2
;revSCB_loop	anop
;	lda	[savedScreenP],y
;	xba
;	sta	>$E19D00,x
;	iny
;	iny
;	dex
;	dex
;	bpl	revSCB_loop

done	anop

	ldx	#160-2
	lda	#0
zayro	sta	>$E12000,x
	dex
	dex
	bpl	zayro	

	pld
	plb
	lda	1,s
	sta	1+4,s
	lda	2,s
	sta	2+4,s
	plx
	plx
	rtl

x160	anop
	asl	a	;x2
	asl	a	;x4
	asl	a	;x8
	asl	a	;x16
	asl	a	;x32
	sta	fillAdd+1
	asl	a	;x64
	asl	a	;x128
	clc
fillAdd	adc	#0	;+x32 = x160
	rts

copyLine	anop
	txa
	inc	a
	jsr	x160
	tax
	dex
	dex
	tya
	jsr	x160
	tay

	lda	#80
	sta	counter

copyIt	lda	[savedScreenP],y
	jsr	swap
shrAddr	sta	$012000,x
	iny
	iny
	dex
	dex
	dec	counter
	bne	copyIt	
	rts

counter	ds	2

swap	anop
;	brk

	pha
	lda	$E19D00
	bit	#$80
	bne	use640

	pla
	shortm
	jsr	swapNibbles
	sta	endResult+2
	longm
	xba
	shortm
	jsr	swapNibbles
	sta	endResult+1
	longm
endResult	lda	#0
	rts

use640	anop
	pla
	shortm
	jsr	mode640
	sta	endResult+2
	longm
	xba
	shortm
	jsr	mode640
	sta	endResult+1
	longm
	bra	endResult

swapNibbles	anop
	longa	off
	pha
	and	#$0F
	asl	a
	asl	a
	asl	a
	asl	a
	sta	f1+1
	pla
	and	#$F0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
f1	ora	#00
	rts
	longa	on

mode640	anop
	longa	off
	sta	temp
	and	#%11
	clc
	ror	a
	ror	a
	ror	a
	sta	ora1+1
	lda	temp
	and	#%1100
	asl	a
	asl	a
;	and	#%00110000
	sta	ora2+1
	lda	temp
	and	#%110000
	lsr	a
	lsr	a
	sta	ora3+1
	lda	temp
	and	#%11000000
	clc
	rol	a
	rol	a
	rol	a
ora1	ora	#0
ora2	ora	#0
ora3	ora	#0
	longa	on
	rts

temp	ds	1

	End
*-----------------------------------------------------------------------------*
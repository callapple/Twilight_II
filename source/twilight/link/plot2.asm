
	mcopy	plot2.mac
	keep	plot2.c
	case	on
	objcase on
	copy	13/ainclude/e16.locator
	copy	22:t2common.equ

* void init_plot(char * screenPtr, char * lookupPtr, char * targetStr)

init_plot	Start

dpr	equ	1
dbr	equ	dpr+2
rtlAddr	equ	dbr+1
screenPtr	equ	rtlAddr+3
lookupPtr	equ	screenPtr+4
targetStr	equ	lookupPtr+4

	phb
	phk
	plb
	phd
	tsc
	tcd

	PushWord #t2PrivGetProcs
	PushWord #stopAfterOne+sendToName
	pei	<targetStr+2
	pei	<targetStr
	PushWord #8	; start (3rd proc)
	PushWord #24	; end (thru 6th proc)
	PushLong #plotDataOut
	_SendRequest

	pei	<lookupPtr+2
	pei	<lookupPtr
	pei	<screenPtr+2
	pei	<screenPtr
	jsl	setup_plot

	pld
	plb
	lda	1,s
	sta	1+12,s
	lda	2,s
	sta	2+12,s
	tsc
	clc
	adc	#12
	tcs
	rtl

plotDataOut	anop
	ds	2
setup_plot	entry
	rtl
	ds	3
get_pixel	entry
	rtl
	ds	3
set_pixel	entry
	rtl
	ds	3
getset_pixel	entry
	rtl
	ds	3

	End
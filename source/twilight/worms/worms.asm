
*-----------------------------------------------------------------------------*
! Twilight II Worms Module.                                                   !
!                                                                             !
!  By Jim Maricondo and Jonah Stich.                                          !
!                                                                             !
! Copyright (c) 1991-1993 Jim Maricondo.  All rights reserved.                !
*-----------------------------------------------------------------------------*
               mcopy worms.mac
	copy	22:t2common.equ
	copy	22:dsdb.equ
	copy	13:ainclude:e16.quickdraw
	keep	worms.d
*-----------------------------------------------------------------------------*
movePtr	gequ	<0
*-----------------------------------------------------------------------------*
Worms          Start
               using WormsDATA
	kind  $1000	; no special memory

	copy	22:dsdb.asm

               phb
	phd
               phk
               plb

	lda	T2Message,s
	cmp	#BlankT2	;must be BlankT2
	jne	skip

;	~InitColorTable #wormsPalette
;	~SetColorTable #0,#wormsPalette

	lda	#0
	sta	T2Result,s
	sta	T2Result+2,s

	PushLong #toT2String
	jsl	init_random

	lda	T2data1,s
	sta	movePtr
	lda	T2data1+2,s
	sta	movePtr+2

	ldx	#200-1
forcePal0	phx
	phx
	phd
	phx
	_GetSCB
	pla
	and	#$F0
	pha
	_SetSCB
	plx
	dex
	bpl	forcePal0

	~GetMasterSCB
	pla
	bit	#mode640
	beq	on320
	lda	#310
	sta	modeFill0+1
	lda	#330
	sta	modeFill1+1
	lda	#640
	sta	horizFill+1
	lda	#6	; was 6
	sta	modew
	asl	a
	sta	modew2
	bra	allFilled

on320	anop
	lda	#155
	sta	modeFill0+1
	lda	#165
	sta	modeFill1+1
	lda	#320
	sta	horizFill+1
	lda	#3
	sta	modew
	sta	modew2

allFilled	anop

	lda	#15
	sta	initTop+1
	lda	#25
	sta	initTop2+1

	ldx	#0
initTop        lda   #15
	sta	CircRects,x	; top
initTop2	lda   #25
	sta	CircRects+4,x	; bottom
modeFill0      lda   #155
	sta	CircRects+2,x	; left
modeFill1      lda   #165
	sta	CircRects+6,x	; right
	lda	initTop+1
	clc
	adc	#10
	sta	initTop+1
	lda	initTop2+1
	clc
	adc	#10
	sta	initTop2+1
	txa
	clc
	adc	#8
	tax
	cmp	#8*16
	blt	initTop
	
again          anop
               ~Set640Color #0
               ~PaintOval #CircRect1
;               ~Set640Color #0
;               ~FrameOval #CircRect1

               ~Set640Color #1
               ~PaintOval #CircRect2
;               ~Set640Color #0
;               ~FrameOval #CircRect2

               ~Set640Color #2
               ~PaintOval #CircRect3
;               ~Set640Color #0
;               ~FrameOval #CircRect3

               ~Set640Color #3
               ~PaintOval #CircRect4
;               ~Set640Color #0
;               ~FrameOval #CircRect4

               ~Set640Color #4
               ~PaintOval #CircRect5
;	~Set640Color #0
;               ~FrameOval #CircRect5

               ~Set640Color #5
               ~PaintOval #CircRect6
;	~Set640Color #0
;               ~FrameOval #CircRect6

               ~Set640Color #6
               ~PaintOval #CircRect7
;	~Set640Color #0
;               ~FrameOval #CircRect7

               ~Set640Color #7
               ~PaintOval #CircRect8
;	~Set640Color #0
;               ~FrameOval #CircRect8

               ~Set640Color #8
               ~PaintOval #CircRect9

               ~Set640Color #9
               ~PaintOval #CircRect10

               ~Set640Color #10
               ~PaintOval #CircRect11

               ~Set640Color #11
               ~PaintOval #CircRect12

               ~Set640Color #12
               ~PaintOval #CircRect13

               ~Set640Color #13
               ~PaintOval #CircRect14

               ~Set640Color #14
               ~PaintOval #CircRect15

               ~Set640Color #15
               ~PaintOval #CircRect16

               ldx   #0
bigLoop        phx

               WordResult
               WordResult
	jsl	random
	pha
               PushWord #3
               _UDivide
               pla
               PullWord XInc

               WordResult
               WordResult
	jsl	random
	pha
               PushWord #3
               _UDivide
               pla
               PullWord YInc

               plx

               lda   YInc
;               cmp   #0
               bne   tryDown
               lda   CircRects,x
               sec
               sbc   modew	;#3
;               bmi   doHoriz
	bpl	doUp	;neu
	cmp	#-2	;neu
	blt	doHoriz            ;neu
doUp	sta   CircRects,x
               lda   CircRects+4,x
               sec
               sbc   modew
               sta   CircRects+4,x
               bra   doHoriz

tryDown        cmp   #1
               bne   doHoriz
               lda   CircRects,x
               clc
               adc   modew
               cmp   #200
               bge   doHoriz
               sta   CircRects,x
               lda   CircRects+4,x
               clc
               adc   modew
               sta   CircRects+4,x

doHoriz        lda   XInc
;               cmp   #0
               bne   tryRight
               lda   CircRects+2,x
               sec
               sbc   modew2
;               bmi   doneCirc
	bpl	doLeft	; neu
	cmp	#-2	;neu
	blt	doneCirc           ;neu   - should it be try Right?
doLeft	sta   CircRects+2,x
               lda   CircRects+6,x
               sec
               sbc   modew2
               sta   CircRects+6,x
               bra   doneCirc

tryRight       cmp   #1
               bne   doneCirc
               lda   CircRects+2,x
               clc
               adc   modew2
horizFill      cmp   #320
               bge   doneCirc
               sta   CircRects+2,x
               lda   CircRects+6,x
               clc
               adc   modew2
               sta   CircRects+6,x

doneCirc       txa
               clc
               adc   #8
               cmp   #8*16
               bge   doneLoop
               tax
               brl   bigLoop

doneLoop       lda   [movePtr]
	jeq	again

;	brk

skip	anop
               pld
               plb
               lda   2,s
               sta   2+10,s
               lda   1,s
               sta   1+10,s
               tsc                      Remove input paramaters
               clc
               adc   #10
               tcs
               clc
               rtl

               End
*-----------------------------------------------------------------------------*
WormsDATA	Data
;	kind  $1000	; no special memory

CircRects      anop
CircRect1      QDRect
CircRect2      QDRect
CircRect3      QDRect
CircRect4      QDRect
CircRect5      QDRect
CircRect6      QDRect
CircRect7      QDRect
CircRect8      QDRect
CircRect9      QDRect
CircRect10     QDRect
CircRect11     QDRect
CircRect12     QDRect
CircRect13     QDRect
CircRect14     QDRect
CircRect15     QDRect
CircRect16     QDRect

XInc           ds    2
YInc           ds    2

;wormsPalette	ds	32

;ColorTable     dc    i'$000,$777,$841,$72C,$00f,$080,$f70,$d00,$fa9,$ff0,$0e0'
;               dc    i'$4df,$DAF,$78f,$CCC,$fff'

modew	ds	2	;3 for 320, 6 for 640
modew2	ds	2	;3 for 320, 12 for 640

toT2String	str	'DYA~Twilight II~'

               End
*-----------------------------------------------------------------------------*
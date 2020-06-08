
*-----------------------------------------------------------------------------*
! Twilight II Strobe Module.                                                  !
!                                                                             !
!  By Jim Maricondo and Jonah Stich.                                          !
!                                                                             !
! Copyright (c) 1991-1993 Jim Maricondo.  All rights reserved.                !
*-----------------------------------------------------------------------------*
               mcopy strobe.mac
	copy	22:t2common.equ
	copy	22:dsdb.equ
	copy	13:ainclude:e16.quickdraw
	keep	strobe.d
*-----------------------------------------------------------------------------*
movePtr	gequ	<0
*-----------------------------------------------------------------------------*
Strobe         Start
	kind  $1000	; no special memory
	debug	'Strobe'

	copy	22:dsdb.asm

               phb
	phd
               phk
               plb

	lda	T2Message,s
	cmp	#BlankT2	;must be BlankT2
	jne	skip

	PushLong #toT2String
	jsl	init_random

	lda	T2data1,s
	sta	movePtr
	lda	T2data1+2,s
	sta	movePtr+2

	stz	anchorDelayPt

GetNumber      anop
	jsl	random
               cmp   #50	;100
               bge   CheckQuit
	cmp	#40
	blt	stayBlack

               lda   #$0FFF
               sta   PALETTES
               shortm
               lda   CLOCKCTL
               and   #$F0
               ora   #$0F
               sta   CLOCKCTL
               longm

	~WaitUntil anchorDelayPt,#960/24 ; delay 1/16 second
	PullWord anchorDelayPt
	bra	CheckQuit

stayBlack	anop
	shortm
               lda   CLOCKCTL
               and   #$F0
               sta   CLOCKCTL
               longm
               lda   #$0000
               sta   PALETTES

	~WaitUntil anchorDelayPt,#960/24 ; delay 1/16 second
	PullWord anchorDelayPt

CheckQuit      lda   [movePtr]
               beq   GetNumber

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

anchorDelayPt	ds	2
toT2String	str	'DYA~Twilight II~'

               End
*-----------------------------------------------------------------------------*

*-----------------------------------------------------------------------------*
! Twilight II Little Puzzling Module.                                         !
!                                                                             !
!  By Jim Maricondo and Jonah Stich.                                          !
!                                                                             !
! v1.0 for Twilight II - 10/24/92 JRM                                         !
! v1.0f1 - 1/2/93 JRM                                                         !
!                                                                             !
! Copyright (c) 1991-1993 Jim Maricondo.  All rights reserved.                !
*-----------------------------------------------------------------------------*
               mcopy Puzzling.MAC
	copy	22:t2common.equ
	copy	22:dsdb.equ
	copy	13:ainclude:e16.memory
	copy	13:ainclude:e16.quickdraw
	keep	puzzling.d
*-----------------------------------------------------------------------------*
MyID	gequ	<0
ScreenW	gequ	MyID+2
MovePtr	gequ	ScreenW+2
*-----------------------------------------------------------------------------*
Puzzling       Start
	kind  $1000	; no special memory
	debug	'Puzzling'
               using PuzzDATA

	copy	22:dsdb.asm

               phb                      Store old data bank
               phk
               plb
               phd
;	tdc
;	sta	OurDP
;               tsc
;               tcd

;	dbrk	$0f

               lda   T2Message,s         ; Get which setup procedure to call.
	cmp	#BlankT2
	jne	notSupported

	lda	T2data1,s	; movePtr
	sta	MovePtr
	lda	T2data1+2,s
	sta	MovePtr+2

;	lda	T2data2+2,s
;	ora	#$0100
;	sta	MyID

	~MMStartUp
	pla
	ora	#$0100
	sta	MyID


;	dbrk	$55

;	PushWord #t2PrivGetProcs
;	PushWord #stopAfterOne+sendToName
;	PushLong #toString
;	PushLong #8
;	PushLong #dataOut
;	_SendRequest
;
;	jsl	set_random_seed

	PushLong #toT2String
	jsl	init_random

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

               lda   #640
               sta   ScreenW

               ~GetMasterSCB
               PullWord StoreLoc
               bit   #mode640
               bne   screenOk

               lda   #320
               sta   ScreenW

screenOk       anop
               ~GetPort

               ~GetWMgrPort
               _SetPort

               ~GetPortLoc #SourceLoc

               ~UDivide ScreenW,#5
               pullword Inc
               pla

               ldx   #0
               lda   #0
nextX          sta   RectTable+2,x
               sta   RectTable+42,x
               sta   RectTable+82,x
               sta   RectTable+122,x
               clc
               adc   Inc
               sta   RectTable+6,x
               sta   RectTable+46,x
               sta   RectTable+86,x
               sta   RectTable+126,x
               tay
               txa
               clc
               adc   #8
               tax
               tya
               cpx   #40
               bne   nextX

               longresult
               pushlong #32*51
	pei	MyID
               pushword #attrLocked+attrFixed
               pushlong #0
               _NewHandle
	jsr	makePdp
	pld
	PullLong MemPtr

event_loop	anop
	wordresult
               wordresult
	jsl	random
;               wordresult
;               _Random
	pha
               pushword #20
               _UDivide
               pla
               pla

               asl   a
               asl   a
               asl   a
               tax
               ldy   #0
nextRect1      lda  RectTable,x
               sta   SourceRect,y
               inx
               inx
               iny
               iny
               cpy   #8
               bne   nextRect1

               wordresult
               wordresult
;               wordresult
;               _Random
	jsl	random
	pha
               pushword #20
               _UDivide
               pla
               pla

               asl   a
               asl   a
               asl   a
               tax
               ldy   #0
nextRect2      lda  RectTable,x
               sta   DestRect,y
               inx
               inx
               iny
               iny
               cpy   #8
               bne   nextRect2

               ~PaintPixels #StoreParams
               ~PaintPixels #MoveParams
               ~PaintPixels #RestoreParams

               lda   [MovePtr]
	jeq	event_loop

	_SetPort

	~DisposeAll MyID

	lda	MyID
	and	#$F0FF
	pha
	_MMShutDown

notSupported	anop
	pld
               plb
               lda   1,s                ; move up RTL address
               sta   1+10,s
               lda   2,s
               sta   2+10,s
               tsc                      ; Remove input parameters.
               clc
               adc   #10
               tcs
	clc
               rtl

               End
*-----------------------------------------------------------------------------*
PuzzDATA       Data
	debug	'PuzzDATA'

toT2String	str	'DYA~Twilight II~'

SourceRect     ds    8
DestRect       ds    8

SourceLoc      ds    16

StoreLoc       ds    2
MemPtr         ds    4
               dc    i'32'
StoreRect      dc    i'0,0,50'
Inc            ds    2

StoreParams    anop
               dc    i4'SourceLoc'
               dc    i4'StoreLoc'
               dc    i4'DestRect'
               dc    i4'StoreRect'
               dc    i'0'
               dc    i4'0'

MoveParams     anop
               dc    i4'SourceLoc'
               dc    i4'SourceLoc'
               dc    i4'SourceRect'
               dc    i4'DestRect'
               dc    i'0'
               dc    i4'0'

RestoreParams  anop
               dc    i4'StoreLoc'
               dc    i4'SourceLoc'
               dc    i4'StoreRect'
               dc    i4'SourceRect'
               dc    i'0'
               dc    i4'0'

RectTable      anop
Rect1          dc    i'0,0,50,0'
Rect2          dc    i'0,0,50,0'
Rect3          dc    i'0,0,50,0'
Rect4          dc    i'0,0,50,0'
Rect5          dc    i'0,0,50,0'
Rect6          dc    i'50,0,100,0'
Rect7          dc    i'50,0,100,0'
Rect8          dc    i'50,0,100,0'
Rect9          dc    i'50,0,100,0'
Rect10         dc    i'50,0,100,0'
Rect11         dc    i'100,0,150,0'
Rect12         dc    i'100,0,150,0'
Rect13         dc    i'100,0,150,0'
Rect14         dc    i'100,0,150,0'
Rect15         dc    i'100,0,150,0'
Rect16         dc    i'150,0,200,0'
Rect17         dc    i'150,0,200,0'
Rect18         dc    i'150,0,200,0'
Rect19         dc    i'150,0,200,0'
Rect20         dc    i'150,0,200,0'

               End
*-----------------------------------------------------------------------------*
	copy	22:makePdp.ASM
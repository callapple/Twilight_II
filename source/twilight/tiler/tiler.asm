
	mcopy tiler.mac
	keep	tiler.d
	copy  2:ainclude:e16.quickdraw
;	copy	tiler.equ
	copy  2:ainclude:e16.control
	copy  2:ainclude:e16.types
	copy	2:ainclude:e16.memory
	copy	2:ainclude:e16.event
	copy	22:t2common.equ
	copy	22:dsdb.equ
*-----------------------------------------------------------------------------*
! Twilight II Tiler Module.
!
! Based on an early version of Jim Mensch's cool TILEX NDA, discovered on an
!  Apple IIgs floor computer at the Apple Central Expo July 1991.
! Special thanks to Jim Mensch for allowing me to use his disassembled code,
!  and for providing me with the source to the final version (which I decided
!  not to use as I don't like it as well as this :-)
! Modified to include slow/fast speeds, and selectable tile sizes by Jim
!  Maricondo, August 1991.  Also modified to work with 320 mode.
!
! Revision history:
!  V1.00 - August 1991 - Initial version.
!  V1.10 - May ~8, 1992 - Revised for new Generation II Module Format.
!  V1.00b7 - May 23, 1992 - Revised doBlank with SmartMacros.
!                           Now use wantGrafPort bit of T2ModuleFlags.
!                           Revised to comply with G2MF ERS v1.1.1. (v1.0d32)
!  v1.0.1b1 - October 24, 1992 - Revised to use private ipc for random.
!  v1.0.1b2 - December 13, 1992 - Revised to respect mfOverrideSound. (v1.0.1b2)
!                                 Fixed dumb bug in doHit that screwed it up.
!
! Versions: 10x10 tile matrix FAST 640/320
!           10x10 tile matrix SLOW 640/320
!           5x5 tile matrix FAST 640/320
!           5x5 tile matrix SLOW 640/320
!
! Copyright (c) 1991, 1992 Jim Maricondo.  All rights reserved.
*-----------------------------------------------------------------------------*
Tiler_CtlLst	gequ	$101
*-----------------------------------------------------------------------------*
Tiler          Start
	debug 'Tiler'
	Using	TilerDATA

	copy	22:dsdb.asm

               phb
               phk
               plb
               phd
	tdc
	sta	OurDP
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#HitT2+1
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (TilerActions,x)   ; JSR to the appropriate action handler.

notSupported   pld
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
TilerDATA	Data
               debug 'TilerDATA'

;decr	ds	2

rTilerSoundFX	str	'Tiler SoundFX'	; rezName of boolean sound flag
rTilerSize	str	'Tiler TileSize'	; rezName of size flag (large/small)
rTilerSpeed	str	'Tiler TileSpeed'	; rezName of speed flag (fast/slow)

TilerActions   anop
               dc    i'doMake'          ; MakeT2 procedure	0
               dc    i'doSave'          ; SaveT2 procedure	1
	dc	i'doBlank'	; BlankT2 procedure	2
	dc	i'doLoadSetup'	; LoadSetupT2 procedure	3
	dc	i'doNothing'    	; UnloadSetupT2 procedure 4
	dc	i'doNothing'	; KillT2 procedure	5
	dc	i'doHit'	; HitT2 procedure	6

WindPtr	ds	4
RezFileID	ds	2
;MyID	ds	2
OurDP	ds	2
temp	ds	4

               End
*-----------------------------------------------------------------------------*
doHit	Start
	debug	'doHit'

	stz	<T2Result+2
	lda	<t2data2+2	; hi word of ctl id must be zero!
	bne	noEnable
	lda	<t2data2
	cmp	#6
	blt	enableUpdate
noEnable	stz	<T2Result
	rts

enableUpdate	anop
	lda	#TRUE
	sta	<T2Result
	rts

               End
*-----------------------------------------------------------------------------*
doLoadSetup	Start
	debug	'doLoadSetup'
	Using	TilerDATA

;	dbrk	$9d


	~RMLoadNamedResource #rT2ModuleWord,#rTilerSoundFX
	bcc	SoundOK
	plx
	plx
	stz	SoundFlag	; default sound: off
	bra	SoundOK2

SoundOK	anop
	jsr	makePdp
	lda	[3]
	killLdp
	sta	SoundFlag

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSoundFX,#temp ; rID
	_ReleaseResource
SoundOK2	anop


	lda	<t2Data2	; (lo) - get flag word
	bit	#lmiOverrideSound
	beq	noOverride	
	stz	SoundFlag	; turn off sound..


noOverride	anop
	~RMLoadNamedResource #rT2ModuleWord,#rTilerSize
	bcc	SizeOK
	plx
	plx
	stz	SizeFlag	; default size: small
	bra	SizeOK2

SizeOK	anop
               jsr   makePdp
               lda   [3]                ; Get the word in the resource...
               killLdp
	sta	SizeFlag

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSize,#temp ; rID
	_ReleaseResource
SizeOK2	anop


	~RMLoadNamedResource #rT2ModuleWord,#rTilerSpeed
	bcc	SpeedOK
	plx
	plx
	stz	SpeedFlag	; default speed: fast
	bra	SpeedOK2

SpeedOK	anop
               jsr   makePdp
               lda   [3]                ; Get the word in the resource...
               killLdp
	sta	SpeedFlag

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSpeed,#temp ; rID
	_ReleaseResource
SpeedOK2	anop

	clc
	rts

               End
*-----------------------------------------------------------------------------*
doNothing	Start
	debug	'doNothing'

;	dbrk	$a0

	clc		; don't do anything!
	rts

               End
*-----------------------------------------------------------------------------*
doMake         Start
               Using TilerDATA
	debug 'doMake'

               lda   <T2data1+2
               sta   WindPtr+2
               lda   <T2data1
               sta   WindPtr
               lda   <T2data2
               sta   RezFileID
;               lda   <T2data2+2
;               sta   MyID
;
; Create our controls.

               LongResult
               pei   <T2data1+2
               pei   <T2data1
               PushWord #resourceToResource
               PushLong #Tiler_CtlLst
               _NewControl2
               plx
               plx

; Make sure we're dealing with the T2pref file.

               ~GetCurResourceFile

               pei   <T2data2
               _SetCurResourceFile


; Load, set, and create if necessary, the sound flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSoundFX
               bcs   soundNotThere
               jsr   makePdp
               lda   [$03]
	killLdp
               brl   soundThere

soundNotThere	anop		; result space already on stack
	PushLong #2
;               pei   <T2data2+2
	~GetCurResourceApp
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   #$0000
               sta   [$03]
	killLdp

	PushLong temp	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2ModuleWord	; rtype
	~UniqueResourceID #$FFFF,#rT2ModuleWord ; rID
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	_AddResource

	PushWord #rT2ModuleWord	; rType
	PushLong temp	; rID
	PushLong #rTilerSoundFX	; ptr to name str
	_RMSetResourceName

               pei   <T2data2
               _UpdateResourceFile


               lda   #$0000
SoundThere	pha
	LongResult
               pei   <T2data1+2
               pei   <T2data1
	PushLong #1	; soundFXctlID
               _GetCtlHandleFromID
               _SetCtlValue
	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSoundFX,#temp ; rID
	_ReleaseResource


; Load, set, and create if necessary, the size flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSize
               bcs   sizeNotThere
               jsr   makePdp
               lda   [$03]
	killLdp
               brl   SizeThere

sizeNotThere	anop		; result space already on stack
	PushLong #2
;               pei   <T2data2+2
	~GetCurResourceApp
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   #$0000
               sta   [$03]
	killLdp

	PushLong temp	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2ModuleWord	; rtype
	~UniqueResourceID #$FFFF,#rT2ModuleWord ; rID
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	_AddResource

	PushWord #rT2ModuleWord	; rType
	PushLong temp	; rID
	PushLong #rTilerSize   	; ptr to name str
	_RMSetResourceName

               pei   <T2data2
               _UpdateResourceFile


               lda   #$0000
SizeThere      clc
               adc   #$0004
               tax
               pea   $FFFF
	LongResult
               pei   <T2data1+2	; grafPortPtr
               pei   <T2data1
	PushWord #0	; ctlID
               phx
               _GetCtlHandleFromID
               _SetCtlValue
	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSize,#temp ; rID
	_ReleaseResource


; Load, set, and create if necessary, the speed flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSpeed
               bcs   SpeedNotThere
               jsr   makePdp
               lda   [$03]
	killLdp
               brl   SpeedThere

SpeedNotThere	anop		; result space already on stack
	PushLong #2
;               pei   T2data2+2
	~GetCurResourceApp
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   #$0000
               sta   [$03]
              	killLdp

	PushLong temp	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2ModuleWord	; rtype
	~UniqueResourceID #$FFFF,#rT2ModuleWord ; rID
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	_AddResource

	PushWord #rT2ModuleWord	; rType
	PushLong temp	; rID
	PushLong #rTilerSpeed  	; ptr to name str
	_RMSetResourceName

               pei   <T2data2
               _UpdateResourceFile


               lda   #$0000
SpeedThere     clc
               adc   #$0002
               tax
               pea   $FFFF
	LongResult
               pei   <T2data1+2	; grafPortPtr
               pei   <T2data1
	PushWord #0	; ctlID
               phx
               _GetCtlHandleFromID
               _SetCtlValue
	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSpeed,#temp ; rID
	_ReleaseResource


               _SetCurResourceFile

	lda	#9
	sta	<T2Result
               rts

               End
*-----------------------------------------------------------------------------*
doSave         Start
               Using TilerDATA
	debug 'doSave'

               ~GetCurResourceFile
               ~SetCurResourceFile RezFileID

; Get state of sound check box.

	WordResult
	~GetCtlHandleFromID WindPtr,#1
               _GetCtlValue
	PullWord temp

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSoundFX
               jsr   makePdp
               lda   temp
               sta   [$03]
	killLdp

	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSoundFX,#temp ; rID
	_MarkResourceChange

; Get size radio button.

	~FindRadioButton WindPtr,#0
	PullWord temp

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSize
               jsr   makePdp
               lda   temp
               sta   [$03]
	killLdp

	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSize,#temp ; rID
	_MarkResourceChange

; Get speed radio button.

	~FindRadioButton WindPtr,#1
	PullWord temp

	~RMLoadNamedResource #rT2ModuleWord,#rTilerSpeed
               jsr   makePdp
               lda   temp
               sta   [$03]
	killLdp

	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rTilerSpeed,#temp ; rID
	_MarkResourceChange

; Update the file and restore original rezFile.

               ~UpdateResourceFile RezFileID

               _SetCurResourceFile
               rts

               End
*-----------------------------------------------------------------------------*
doBlank	Start
	debug	'doBlank'
	Using	TilerDATA

	phd
	lda	OurDP
	tcd



;	lda	#20
;	sta	decr



               ~SetBackPat #Pattern
;               ~ShowPen

;               ~ReadTimeHex
;               _SetRandSeed
;               plx
;               plx

	PushLong #toT2String
	jsl	init_random

;	ldx	#200-1
;forcePal0	phx
;	phx
;	phd
;	phx
;	_GetSCB
;	pla
;	and	#$F0
;	pha
;	_SetSCB
;	plx
;	dex
;	bpl	forcePal0

               ~GetMasterSCB
               pla
               bit   #mode640
               jne   Tiler640
               brl   Tiler320

exitHere2       entry
;	dbrk 00
	lda	#bmrNextModule 	;bmrLeavesUsableScreen
	sta	<T2result+2
	stz	<T2result	
	rts

exitHere       entry
	stz	<T2result+2
	stz	<T2result	
	rts

pattern        dc    32h'00'

soundFlag	entry	                   ; 0 = default
	ds	2                  ; 0 = no sound, 1 = sound
sizeFlag	entry                    ; 0 = default
	ds	2	; 0 = small, 1 = large
speedFlag	entry                    ; 0 = default
	ds	2                  ; 0 = fast, 1 = slow

toT2String	str	'DYA~Twilight II~'

               End
*-----------------------------------------------------------------------------*
Tiler320       Start
	debug 'Tiler 320'

	lda	SizeFlag
	beq	Tiler100_320
	brl	Tiler25_320

	End
*-----------------------------------------------------------------------------*
Tiler100_320	Start
	debug 'Tiler100 320'
	Using	TilerDATA

               stz   VERT1
               stz   HORIZ1
               stz   VERT2
               stz   HORIZ2


	lda	SpeedFlag
	beq	fast

slow	anop
	lda	#-1
	sta	f1+1
	lda	#20
	sta	f2+1
	lda	#1
	sta	f3+1
	lda	#20
	sta	f4+1
	lda	#-2
	sta	f5+1
	lda	#16
	sta	f6+1
	lda	#2
	sta	f7+1
	lda	#16
	sta	f8+1

	bra	doneSpeedMod

fast	anop
	lda	#-2
	sta	f1+1
	lda	#10
	sta	f2+1
	lda	#2
	sta	f3+1
	lda	#10
	sta	f4+1
	lda	#-4
	sta	f5+1
	lda	#8
	sta	f6+1
	lda	#4
	sta	f7+1
	lda	#8
	sta	f8+1

doneSpeedMod	anop

loop320        anop
               jsr   Randomize
               lda   RoutineNum
               asl   a
               tax
               jsr   (JMPTbl320,x)

	pld		; restore DP aligned with stack
               lda   [T2data1]	; movePtr
               jne   exitHere
;	lda	decr
;	dec	a
;	sta	decr
;	jeq	exitHere2
	phd		; save DP aligned with stack
	lda	OurDP	; restore our DP space
	tcd
               bra   loop320

JMPTbl320      dc    i'DOWN'
               dc    i'RIGHT'
               dc    i'UP'
               dc    i'LEFT'

Randomize      anop
;               WordResult
;               _Random                  get a random number
;               pla
	jsl	random
               and   #$0003             make it a # ranged 0 thru 3
               tax
               eor   #$0002
               cmp   RoutineNum
               beq   Randomize
               txa
               sta   RoutineNum         that will be our new direction
               beq   willBeDOWN
               dec   a
               beq   willBeRIGHT
               dec   a
               beq   willBeUP
willBeLEFT     lda   HORIZ1
               cmp   #9                 0 thru 8 only
               bge   Randomize          if >= 9, re-randomize
               inc   a                  HORIZ2 = HORIZ1 + 1
LRCommon       sta   HORIZ2
               lda   VERT1              VERT1 = VERT2
               sta   VERT2
               rts

willBeRIGHT    lda   HORIZ1
               beq   Randomize
               dec   a                  HORIZ2 = HORIZ1 - 1
               bra   LRCommon

willBeUP       lda   VERT1
               cmp   #9                 0 thru 8 only
               bge   Randomize          if >= 9, re-randomize
               inc   a                  VERT2 = VERT1 + 1
UDCommon       sta   VERT2
               lda   HORIZ1             HORIZ1 = HORIZ2
               sta   HORIZ2
               rts

willBeDOWN     lda   VERT1
               beq   Randomize          if = 0, re-randomize
               dec   a                  VERT2 = VERT1 - 1
               bra   UDCommon

V1isV2_H1isH2  lda   HORIZ2
               sta   HORIZ1
               lda   VERT2
               sta   VERT1
               rts

UP             stz   repeatNum          first we get what block
               lda   VERT1              we're moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           line number of the top line
               clc                      add 40 to get the bottom
               adc   #40                line of the block directly
               sta   Rect_bottom        below the one to move
               lda   HORIZ1             get which block we're moving
               jsr   x32                (horizontally)
               sta   Rect_left          add 32 to get the far right
               clc                      column of our block
               adc   #32                (32 is 1/10th the horiz screen)
               sta   Rect_right
f1	anop
upLoop         ldy   #-2                [-2] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 2 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 20 lines
               sta   repeatNum          moved total, which is 1/10th
f2	anop
               cmp   #10                the height of the SHR screen
               blt   upLoop
	jsr	Click
               brl   V1isV2_H1isH2

DOWN           stz   repeatNum          first, get what block we're
               lda   VERT2              moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           line number of the top of the
               clc                      block to move
               adc   #40                add 40 to get the bottom line
               sta   Rect_bottom        of the block directly below us
               lda   HORIZ2             get which block we're moving
               jsr   x32                (horizontally)
               sta   Rect_left          x32 to get the start column
               clc                      of the block. add 32 to get
               adc   #32                the end column of the block.
               sta   Rect_right
f3	anop
downLoop       ldy   #2                 [+2] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 2 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 20 lines
               sta   repeatNum          moved, which is 1/10th the
f4	anop
               cmp   #10                height of the SHR screen
               blt   downLoop
	jsr	Click
               brl   V1isV2_H1isH2

LEFT           stz   repeatNum          first, get which block we're
               lda   VERT1              moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           top line of the block
               clc                      add 20 to get the bottom
               adc   #20                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ1             moving (horizontally)
               jsr   x32                multiply by 32 to get the
               sta   Rect_left          start column of the block
               clc                      add 64 to get the end column
               adc   #64                of the block next to us
               sta   Rect_right
leftLoop       ldy   #0                 [00] vertical scroll
f5	anop
               ldx   #-4                [-4] horizontal scroll
               jsr   ScrollIt           move it 4 of 320 pixels over
               lda   repeatNum
               inc   a                  move it 4 pixels 8 times
               sta   repeatNum          for 32 pixels distance moved
f6	anop
               cmp   #8                 this is 1/10th of the screen
               blt   leftLoop           across
	jsr	Click
               brl   V1isV2_H1isH2

RIGHT          stz   repeatNum          first, get which block we're
               lda   VERT2              moving (horizontally)
               jsr   x20                multiply by 20 to get the top
               sta   Rect_top           line of the block
               clc                      then add 20 to get the bottom
               adc   #20                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ2             moving (vertically)
               jsr   x32                multiply by 32 to get the
               sta   Rect_left          start column of the block
               clc                      add 64 to get the end column
               adc   #64                of the block next to us
               sta   Rect_right
rightLoop      ldy   #0                 [00] vertical scroll
f7	anop
               ldx   #4                 [+4] horizontal scroll
               jsr   ScrollIt           move it 4 of 320 pixels over
               lda   repeatNum          move it over 8 times
               inc   a                  so by the end it will have
               sta   repeatNum          moved 32 pixels which is
f8	anop
               cmp   #8                 1/10th of the width of a
               blt   rightLoop          320 mode screen
	jsr	Click
               brl   V1isV2_H1isH2

ScrollIt       anop
               PushLong #Rect_top       rect to scroll in
               phx                      horizontal scroll
               phy                      vertical scroll
               PushLong #0              updateRgnHndl
               _ScrollRect
               rts

x32            asl   a                  x2
               asl   a                  x4
               asl   a                  x8
               asl   a                  x16
               asl   a                  x32
               rts

x20            asl   a                  x2
               pha
               asl   a                  x4
               asl   a                  x8
               clc
               adc   1,s                +x2
               plx
               asl   a                  x20 total
               rts

repeatNum      ds    2
VERT1          ds    2
HORIZ1         ds    2
VERT2          ds    2
HORIZ2         ds    2
RoutineNum     dc    i'1'
Rect_top       ds    2
Rect_left      ds    2
Rect_bottom    dc    i'20-1'
Rect_right     dc    i'32-1'

               End
*-----------------------------------------------------------------------------*
Tiler25_320    Start
	debug 'Tiler25 320'
	Using	TilerDATA

               stz   VERT1
               stz   HORIZ1
               stz   VERT2
               stz   HORIZ2



	lda	SpeedFlag
	beq	fast

slow	anop
	lda	#-2
	sta	f1+1
	lda	#20
	sta	f2+1
	lda	#2
	sta	f3+1
	lda	#20
	sta	f4+1
	lda	#-4
	sta	f5+1
	lda	#16
	sta	f6+1
	lda	#4
	sta	f7+1
	lda	#16
	sta	f8+1

	bra	doneSpeedMod

fast	anop
	lda	#-4
	sta	f1+1
	lda	#10
	sta	f2+1
	lda	#4
	sta	f3+1
	lda	#10
	sta	f4+1
	lda	#-8
	sta	f5+1
	lda	#8
	sta	f6+1
	lda	#8
	sta	f7+1
	lda	#8
	sta	f8+1

doneSpeedMod	anop

loop320        anop
               jsr   Randomize
               lda   RoutineNum
               asl   a
               tax
               jsr   (JMPTbl320,x)

	pld		; restore DP aligned with stack
               lda   [T2data1]	; movePtr
               jne   exitHere
;	lda	decr
;	dec	a
;	sta	decr
;	jeq	exitHere2
	phd		; save DP aligned with stack
	lda	OurDP	; restore our DP space
	tcd
               bra   loop320

JMPTbl320      dc    i'DOWN'
               dc    i'RIGHT'
               dc    i'UP'
               dc    i'LEFT'

Randomize      anop
;               WordResult
;               _Random                  get a random number
;               pla
	jsl	random
               and   #$0003             make it a # ranged 0 thru 3
               tax
               eor   #$0002
               cmp   RoutineNum
               beq   Randomize
               txa
               sta   RoutineNum         that will be our new direction
               beq   willBeDOWN
               dec   a
               beq   willBeRIGHT
               dec   a
               beq   willBeUP
willBeLEFT     lda   HORIZ1
               cmp   #4                 0 thru 3 only
               bge   Randomize          if >= 4, re-randomize
               inc   a                  HORIZ2 = HORIZ1 + 1
LRCommon       sta   HORIZ2
               lda   VERT1              VERT1 = VERT2
               sta   VERT2
               rts

willBeRIGHT    lda   HORIZ1
               beq   Randomize
               dec   a                  HORIZ2 = HORIZ1 - 1
               bra   LRCommon

willBeUP       lda   VERT1
               cmp   #4                 0 thru 3 only
               bge   Randomize          if >= 4, re-randomize
               inc   a                  VERT2 = VERT1 + 1
UDCommon       sta   VERT2
               lda   HORIZ1             HORIZ1 = HORIZ2
               sta   HORIZ2
               rts

willBeDOWN     lda   VERT1
               beq   Randomize          if = 0, re-randomize
               dec   a                  VERT2 = VERT1 - 1
               bra   UDCommon

V1isV2_H1isH2  lda   HORIZ2
               sta   HORIZ1
               lda   VERT2
               sta   VERT1
               rts

UP             stz   repeatNum          first we get what block
               lda   VERT1              we're moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           line number of the top line
               clc                      add 80 to get the bottom
               adc   #80                line of the block directly
               sta   Rect_bottom        below the one to move
               lda   HORIZ1             get which block we're moving
               jsr   x64                (horizontally)
               sta   Rect_left          add 64 to get the far right
               clc                      column of our block
               adc   #64                (64 is 1/5th the horiz screen)
               sta   Rect_right
f1	anop
upLoop         ldy   #-4                [-4] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 4 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 40 lines
               sta   repeatNum          moved total, which is 1/5th
f2	anop
               cmp   #10                the height of the SHR screen
               blt   upLoop
	jsr	Click
               brl   V1isV2_H1isH2

DOWN           stz   repeatNum          first, get what block we're
               lda   VERT2              moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           line number of the top of the
               clc                      block to move
               adc   #80                add 80 to get the bottom line
               sta   Rect_bottom        of the block directly below us
               lda   HORIZ2             get which block we're moving
               jsr   x64                (horizontally)
               sta   Rect_left          x64 to get the start column
               clc                      of the block. add 64 to get
               adc   #64                the end column of the block.
               sta   Rect_right
f3	anop
downLoop       ldy   #4                 [+4] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 4 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 40 lines
               sta   repeatNum          moved, which is 1/5th the
f4	anop
               cmp   #10                height of the SHR screen
               blt   downLoop
	jsr	Click
               brl   V1isV2_H1isH2

LEFT           stz   repeatNum          first, get which block we're
               lda   VERT1              moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           top line of the block
               clc                      add 40 to get the bottom
               adc   #40                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ1             moving (horizontally)
               jsr   x64                multiply by 64 to get the
               sta   Rect_left          start column of the block
               clc                      add 128 to get the end column
               adc   #128               of the block next to us
               sta   Rect_right
leftLoop       ldy   #0                 [00] vertical scroll
f5	anop
               ldx   #-8                [-8] horizontal scroll
               jsr   ScrollIt           move it 8 of 320 pixels over
               lda   repeatNum
               inc   a                  move it 8 pixels 8 times
               sta   repeatNum          for 64 pixels distance moved
f6	anop
               cmp   #8                 this is 1/5th of the screen
               blt   leftLoop           across
	jsr	Click
               brl   V1isV2_H1isH2

RIGHT          stz   repeatNum          first, get which block we're
               lda   VERT2              moving (horizontally)
               jsr   x40                multiply by 40 to get the top
               sta   Rect_top           line of the block
               clc                      then add 40 to get the bottom
               adc   #40                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ2             moving (vertically)
               jsr   x64                multiply by 64 to get the
               sta   Rect_left          start column of the block
               clc                      add 128 to get the end column
               adc   #128               of the block next to us
               sta   Rect_right
rightLoop      ldy   #0                 [00] vertical scroll
f7	anop
               ldx   #8                 [+8] horizontal scroll
               jsr   ScrollIt           move it 8 of 320 pixels over
               lda   repeatNum          move it over 8 times
               inc   a                  so by the end it will have
               sta   repeatNum          moved 64 pixels which is
f8	anop
               cmp   #8                 1/5th of the width of a
               blt   rightLoop          320 mode screen
	jsr	Click
               brl   V1isV2_H1isH2

ScrollIt       anop
               PushLong #Rect_top       rect to scroll in
               phx                      horizontal scroll
               phy                      vertical scroll
               PushLong #0              updateRgnHndl
               _ScrollRect
               rts

x64            asl   a                  x2
               asl   a                  x4
               asl   a                  x8
               asl   a                  x16
               asl   a                  x32
               asl   a                  x64
               rts

x40            asl   a                  x2
               pha
               asl   a                  x4
               asl   a                  x8
               clc
               adc   1,s                +x2
               plx
               asl   a                  x20
               asl   a                  x40
               rts

repeatNum      ds    2
VERT1          ds    2
HORIZ1         ds    2
VERT2          ds    2
HORIZ2         ds    2
RoutineNum     dc    i'1'
Rect_top       ds    2
Rect_left      ds    2
Rect_bottom    dc    i'40-1'
Rect_right     dc    i'64-1'

               End
*-----------------------------------------------------------------------------*
Tiler640       Start
	debug 'Tiler 640'

	lda	SizeFlag
	beq	Tiler100_640
	brl	Tiler25_640

	End                               
*-----------------------------------------------------------------------------*
Tiler100_640	Start
	debug 'Tiler100 640'
	Using	TilerDATA

               stz   VERT1
               stz   HORIZ1
               stz   VERT2
               stz   HORIZ2


	lda	SpeedFlag
	beq	fast

slow	anop
	lda	#-1
	sta	f1+1
	lda	#20
	sta	f2+1
	lda	#1
	sta	f3+1
	lda	#20
	sta	f4+1
	lda	#-4
	sta	f5+1
	lda	#16
	sta	f6+1
	lda	#4
	sta	f7+1
	lda	#16
	sta	f8+1

	bra	doneSpeedMod

fast	anop
	lda	#-2
	sta	f1+1
	lda	#10
	sta	f2+1
	lda	#2
	sta	f3+1
	lda	#10
	sta	f4+1
	lda	#-8
	sta	f5+1
	lda	#8
	sta	f6+1
	lda	#8
	sta	f7+1
	lda	#8
	sta	f8+1

doneSpeedMod	anop

loop640        anop
               jsr   Randomize
               lda   RoutineNum
               asl   a
               tax
               jsr   (JMPTbl640,x)

	pld		; restore DP aligned with stack
               lda   [T2data1]	; movePtr
               jne   exitHere
;	lda	decr
;	dec	a
;	sta	decr
;	jeq	exitHere2
	phd
	lda	OurDP
	tcd
               bra   loop640

JMPTbl640      dc    i'DOWN'
               dc    i'RIGHT'
               dc    i'UP'
               dc    i'LEFT'

Randomize      anop
;               WordResult
;               _Random                  get a random number
;               pla
	jsl	random
               and   #$0003             make it a # ranged 0 thru 3
               tax
               eor   #$0002
               cmp   RoutineNum
               beq   Randomize
               txa
               sta   RoutineNum         that will be our new direction
               beq   willBeDOWN
               dec   a
               beq   willBeRIGHT
               dec   a
               beq   willBeUP
willBeLEFT     lda   HORIZ1
               cmp   #9                 0 thru 8 only
               bge   Randomize          if >= 9, re-randomize
               inc   a                  HORIZ2 = HORIZ1 + 1
LRCommon       sta   HORIZ2
               lda   VERT1              VERT1 = VERT2
               sta   VERT2
               rts

willBeRIGHT    lda   HORIZ1
               beq   Randomize
               dec   a                  HORIZ2 = HORIZ1 - 1
               bra   LRCommon

willBeUP       lda   VERT1
               cmp   #9                 0 thru 8 only
               bge   Randomize          if >= 9, re-randomize
               inc   a                  VERT2 = VERT1 + 1
UDCommon       sta   VERT2
               lda   HORIZ1             HORIZ1 = HORIZ2
               sta   HORIZ2
               rts

willBeDOWN     lda   VERT1
               beq   Randomize          if = 0, re-randomize
               dec   a                  VERT2 = VERT1 - 1
               bra   UDCommon

V1isV2_H1isH2  lda   HORIZ2
               sta   HORIZ1
               lda   VERT2
               sta   VERT1
               rts

UP             stz   repeatNum          first we get what block
               lda   VERT1              we're moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           line number of the top line
               clc                      add 40 to get the bottom
               adc   #40                line of the block directly
               sta   Rect_bottom        below the one to move
               lda   HORIZ1             get which block we're moving
               jsr   x64                (horizontally)
               sta   Rect_left          add 64 to get the far right
               clc                      column of our block
               adc   #64                (64 is 1/10th the horiz screen)
               sta   Rect_right
f1	anop
upLoop         ldy   #-2                [-2] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 2 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 20 lines
               sta   repeatNum          moved total, which is 1/10th
f2	anop
               cmp   #10                the height of the SHR screen
               blt   upLoop
	jsr	Click
               brl   V1isV2_H1isH2

DOWN           stz   repeatNum          first, get what block we're
               lda   VERT2              moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           line number of the top of the
               clc                      block to move
               adc   #40                add 40 to get the bottom line
               sta   Rect_bottom        of the block directly below us
               lda   HORIZ2             get which block we're moving
               jsr   x64                (horizontally)
               sta   Rect_left          x64 to get the start column
               clc                      of the block. add 64 to get
               adc   #64                the end column of the block.
               sta   Rect_right
f3	anop
downLoop       ldy   #2                 [+2] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 2 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 20 lines
               sta   repeatNum          moved, which is 1/10th the
f4	anop
               cmp   #10                height of the SHR screen
               blt   downLoop
	jsr	Click
               brl   V1isV2_H1isH2

LEFT           stz   repeatNum          first, get which block we're
               lda   VERT1              moving (vertically)
               jsr   x20                multiply by 20 to get the
               sta   Rect_top           top line of the block
               clc                      add 20 to get the bottom
               adc   #20                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ1             moving (horizontally)
               jsr   x64                multiply by 64 to get the
               sta   Rect_left          start column of the block
               clc                      add 128 to get the end column
               adc   #128               of the block next to us
               sta   Rect_right
leftLoop       ldy   #0                 [00] vertical scroll
f5	anop
               ldx   #-8                [-8] horizontal scroll
               jsr   ScrollIt           move it 8 of 640 pixels over
               lda   repeatNum
               inc   a                  move it 8 pixels 8 times
               sta   repeatNum          for 64 pixels distance moved
f6	anop
               cmp   #8                 this is 1/10th of the screen
               blt   leftLoop           across
	jsr	Click
               brl   V1isV2_H1isH2

RIGHT          stz   repeatNum          first, get which block we're
               lda   VERT2              moving (horizontally)
               jsr   x20                multiply by 20 to get the top
               sta   Rect_top           line of the block
               clc                      then add 20 to get the bottom
               adc   #20                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ2             moving (vertically)
               jsr   x64                multiply by 64 to get the
               sta   Rect_left          start column of the block
               clc                      add 128 to get the end column
               adc   #128               of the block next to us
               sta   Rect_right
rightLoop      ldy   #0                 [00] vertical scroll
f7	anop
               ldx   #8                 [+8] horizontal scroll
               jsr   ScrollIt           move it 8 of 640 pixels over
               lda   repeatNum          move it over 8 times
               inc   a                  so by the end it will have
               sta   repeatNum          moved 64 pixels which is
f8	anop
               cmp   #8                 1/10th of the width of a
               blt   rightLoop          640 mode screen
	jsr	Click
               brl   V1isV2_H1isH2

ScrollIt       anop
               PushLong #Rect_top       rect to scroll in
               phx                      horizontal scroll
               phy                      vertical scroll
               PushLong #0              updateRgnHndl
               _ScrollRect
               rts

x64            asl   a                  x2
               asl   a                  x4
               asl   a                  x8
               asl   a                  x16
               asl   a                  x32
               asl   a                  x64
               rts

x20            asl   a                  x2
               pha
               asl   a                  x4
               asl   a                  x8
               clc
               adc   1,s                +x2
               plx
               asl   a                  x20 total
               rts

repeatNum      ds    2
VERT1          ds    2
HORIZ1         ds    2
VERT2          ds    2
HORIZ2         ds    2
RoutineNum     dc    i'1'
Rect_top       ds    2
Rect_left      ds    2
Rect_bottom    dc    i'20-1'
Rect_right     dc    i'64-1'

               End
*-----------------------------------------------------------------------------*
Tiler25_640    Start
	debug 'Tiler25 640'
	Using	TilerDATA

               stz   VERT1
               stz   HORIZ1
               stz   VERT2
               stz   HORIZ2



	lda	SpeedFlag
	beq	fast

slow	anop
	lda	#-2
	sta	f1+1
	lda	#20
	sta	f2+1
	lda	#2
	sta	f3+1
	lda	#20
	sta	f4+1
	lda	#-8
	sta	f5+1
	lda	#16
	sta	f6+1
	lda	#8
	sta	f7+1
	lda	#16
	sta	f8+1

	bra	doneSpeedMod

fast	anop
	lda	#-4
	sta	f1+1
	lda	#10
	sta	f2+1
	lda	#4
	sta	f3+1
	lda	#10
	sta	f4+1
	lda	#-16
	sta	f5+1
	lda	#8
	sta	f6+1
	lda	#16
	sta	f7+1
	lda	#8
	sta	f8+1

doneSpeedMod	anop

loop640        anop
               jsr   Randomize
               lda   RoutineNum
               asl   a
               tax
               jsr   (JMPTbl640,x)
           
	pld		; restore DP aligned with stack
               lda   [T2data1]	; movePtr
               jne   exitHere
;	lda	decr
;	dec	a
;	sta	decr
;	jeq	exitHere2
	phd		; save DP aligned with stack
	lda	OurDP	; restore our DP space
	tcd
               bra   loop640

JMPTbl640      dc    i'DOWN'
               dc    i'RIGHT'
               dc    i'UP'
               dc    i'LEFT'

Randomize      anop
;               WordResult
;               _Random                  get a random number
;               pla
	jsl	random
               and   #$0003             make it a # ranged 0 thru 3
               tax
               eor   #$0002
               cmp   RoutineNum
               beq   Randomize
               txa
               sta   RoutineNum         that will be our new direction
               beq   willBeDOWN
               dec   a
               beq   willBeRIGHT
               dec   a
               beq   willBeUP
willBeLEFT     lda   HORIZ1
               cmp   #4                 0 thru 3 only
               bge   Randomize          if >= 4, re-randomize
               inc   a                  HORIZ2 = HORIZ1 + 1
LRCommon       sta   HORIZ2
               lda   VERT1              VERT1 = VERT2
               sta   VERT2
               rts

willBeRIGHT    lda   HORIZ1
               beq   Randomize          if = 0, re-randomize
               dec   a                  HORIZ2 = HORIZ1 - 1
               bra   LRCommon

willBeUP       lda   VERT1
               cmp   #4                 0 thru 3 only
               bge   Randomize          if >= 4, re-randomize
               inc   a                  VERT2 = VERT1 + 1
UDCommon       sta   VERT2
               lda   HORIZ1             HORIZ1 = HORIZ2
               sta   HORIZ2
               rts

willBeDOWN     lda   VERT1
               beq   Randomize          if = 0, re-randomize
               dec   a                  VERT2 = VERT1 - 1
               bra   UDCommon

V1isV2_H1isH2  lda   HORIZ2
               sta   HORIZ1
               lda   VERT2
               sta   VERT1
               rts

UP             stz   repeatNum          first we get what block
               lda   VERT1              we're moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           line number of the top line
               clc                      add 80 to get the bottom
               adc   #80                line of the block directly
               sta   Rect_bottom        below the one to move
               lda   HORIZ1             get which block we're moving
               jsr   x128               (horizontally)
               sta   Rect_left          add 128 to get the far right
               clc                      column of our block
               adc   #128               (128 is 1/5th the horiz screen)
               sta   Rect_right
f1	anop
upLoop         ldy   #-4                [-4] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 4 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 40 lines
               sta   repeatNum          moved total, which is 1/5th
f2	anop
               cmp   #10                the height of the SHR screen
               blt   upLoop
	jsr	Click
               brl   V1isV2_H1isH2

DOWN           stz   repeatNum          first, get what block we're
               lda   VERT2              moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           line number of the top of the
               clc                      block to move
               adc   #80                add 80 to get the bottom line
               sta   Rect_bottom        of the block directly below us
               lda   HORIZ2             get which block we're moving
               jsr   x128               (horizontally)
               sta   Rect_left          x128 to get the start column
               clc                      of the block. add 128 to get
               adc   #128               the end column of the block.
               sta   Rect_right
f3	anop
downLoop       ldy   #4                 [+4] vertical scroll
               ldx   #0                 [00] horizontal scroll
               jsr   ScrollIt           move it 4 lines
               lda   repeatNum          move it 10 times
               inc   a                  for a total of 40 lines
               sta   repeatNum          moved, which is 1/5th the
f4	anop
               cmp   #10                height of the SHR screen
               blt   downLoop
	jsr	Click
               brl   V1isV2_H1isH2

LEFT           stz   repeatNum          first, get which block we're
               lda   VERT1              moving (vertically)
               jsr   x40                multiply by 40 to get the
               sta   Rect_top           top line of the block
               clc                      add 40 to get the bottom
               adc   #40                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ1             moving (horizontally)
               jsr   x128               multiply by 128 to get the
               sta   Rect_left          start column of the block
               clc                      add 256 to get the end column
               adc   #256               of the block next to us
               sta   Rect_right
leftLoop       ldy   #0                 [00] vertical scroll
f5	anop
               ldx   #-16               [-16] horizontal scroll
               jsr   ScrollIt           move it 16 of 640 pixels over
               lda   repeatNum
               inc   a                  move it 16 pixels 8 times
               sta   repeatNum          for 128 pixels distance moved
f6	anop
               cmp   #8                 this is 1/5th of the screen
               blt   leftLoop           across
	jsr	Click
               brl   V1isV2_H1isH2

RIGHT          stz   repeatNum          first, get which block we're
               lda   VERT2              moving (horizontally)
               jsr   x40                multiply by 40 to get the top
               sta   Rect_top           line of the block
               clc                      then add 40 to get the bottom
               adc   #40                line of the block
               sta   Rect_bottom        then get which block we're
               lda   HORIZ2             moving (vertically)
               jsr   x128               multiply by 128 to get the
               sta   Rect_left          start column of the block
               clc                      add 256 to get the end column
               adc   #256               of the block next to us
               sta   Rect_right
rightLoop      ldy   #0                 [00] vertical scroll
f7	anop
               ldx   #16                [+16] horizontal scroll
               jsr   ScrollIt           move it 16 of 640 pixels over
               lda   repeatNum          move it over 8 times
               inc   a                  so by the end it will have
               sta   repeatNum          moved 128 pixels which is
f8	anop
               cmp   #8                 1/5th of the width of a
               blt   rightLoop          640 mode screen
	jsr	Click
               brl   V1isV2_H1isH2

ScrollIt       anop
               PushLong #Rect_top       rect to scroll in
               phx                      horizontal scroll
               phy                      vertical scroll
               PushLong #0              updateRgnHndl
               _ScrollRect
               rts

x128           asl   a                  x2
               asl   a                  x4
               asl   a                  x8
               asl   a                  x16
               asl   a                  x32
               asl   a                  x64
               asl   a                  x128
               rts

x40            asl   a                  x2
               pha
               asl   a                  x4
               asl   a                  x8
               clc
               adc   1,s                +x2
               plx
               asl   a                  x20
               asl   a                  x40
               rts

repeatNum      ds    2
VERT1          ds    2
HORIZ1         ds    2
VERT2          ds    2
HORIZ2         ds    2
RoutineNum     dc    i'1'
Rect_top       ds    2
Rect_left      ds    2
Rect_bottom    dc    i'40-1'
Rect_right     dc    i'128-1'

               End
*-----------------------------------------------------------------------------*
* Here's a little sound routine.  It's a modified white
* noise generator Derek found in Nibble.  You can play modify
* the frequency/duration/volume if you want.
Click	Start
	debug 'Click'

DUR            equ	50
FREQ           equ	200
VOL            equ	60

	lda	soundFlag
	beq	noClick

               shortmx
               lda   #DUR
               sta   temp

LoopL6         lda   SPKR
               ldy   #VOL
YLoopL6        dey
               bne   YLoopL6
               lda   SPKR
               ldx   temp
               lda   $FFF000,x          ;this is neat.  It reads the Applesoft
               clc                      ;ROM and uses it as random values!
               adc   #FREQ
               tax
xloopL6        dex
               bne   xloopL6
               dec   temp
               bne   LoopL6
               longmx
noClick        rts

temp           ds    1                  ;temporary loop-counter

	End
*-----------------------------------------------------------------------------*
	copy	22:makepdp.asm
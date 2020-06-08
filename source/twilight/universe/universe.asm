
               mcopy Universe.Mac
	keep	Universe.d
	copy  2:ainclude:e16.control
	copy  2:ainclude:e16.types
	copy	2:ainclude:e16.memory
	copy	2:ainclude:e16.event
	copy	2:ainclude:e16.resources
	copy	22:t2common.equ
	copy	22:dsdb.equ
*-----------------------------------------------------------------------------*
! Twilight II Universe Module.
!
!  By Jim Maricondo.  Thanks to Shawn G. Quick.
!
!  v1.0b1 - 08 August 91 - Initial Version.
!  v1.0b2 - 24 May 92 - Updated for G2MF ERS v1.1.1. (T2 v1.0d32-v1.0d33)
!  v1.0b3 - 17 Sept 92 - Options partially implemented!
!  v1.0b4 - 24 October 92 - Uses priv ipc (for random.)  (T2 v1.0.1b1)
!  v1.0b5 - 12 December 92 - Fixed Greg Templeman's bugs :-) (T2 v1.0.1b2)
!  v1.0.1f1 - 1 Jan 93 - Smoothened everything for release. (T2 v1.0.1b3)
!
! Copyright (c) 1991, 1992, 1993 Jim Maricondo.  All rights reserved.
*-----------------------------------------------------------------------------*
! You can experiment with this program to give faster motion through
! the galaxy by increasing the ZDEC (startspeed) variable. You may also want to
! increase/decrease the number of stars (INITSTARS) or the viewing
! angle (XYSPAN) and reassembling the program
*-----------------------------------------------------------------------------*
left           gequ  -160               full screen position
right          gequ  160
top            gequ  -100
bottom         gequ  100
org_v          gequ  160                center of universe, vertical
org_h          gequ  100                center of universe, horizontal

startstars	gequ	165	max # of possible stars at beginning
initstars	gequ	30	number of stars to display at start
autostars	gequ	100	number of stars to zoom to
;maxstars	gequ	190	maximum number of stars possible
;xyspan	gequ	$4000          ; defines viewing angle, MUST be power of 2
;zspan	gequ	255	farthest visible point, MUST be < 256
screenbank	gequ	$00E1	bank number of where to draw
;startspeed     gequ  $06	speed at which stars approach viewer
!                                       bigger is faster, 0 is stop

* offsets into star record
;xpos           gequ  0                  X position of star in space
;ypos           gequ  2                  Y position of star in space
;zpos           gequ  4                  Z position of star in space
;xdraw          gequ  6                  last drawn x position
;ydraw          gequ  8                  last drawn y pos
;zdraw          gequ  10                 last drawn z pos
;starfill       gequ  12                 bytes 12-15 undefined

screenptr      gequ  <128               pointer used to access screen
newx           gequ  screenptr+4        temp storage of star (used by drawstar)
newy           gequ  newx+2
newz           gequ  newy+2
sLookup        gequ  newz+2
galaxy_xpos	gequ	sLookup+4
galaxy_ypos	gequ	galaxy_xpos+4
galaxy_zpos	gequ	galaxy_ypos+4
galaxy_xdraw	gequ	galaxy_zpos+4
galaxy_ydraw	gequ	galaxy_xdraw+4
galaxy_zdraw	gequ	galaxy_ydraw+4
movePtr	gequ	galaxy_zdraw+4
*-----------------------------------------------------------------------------*
Universe       Start
	debug	'Universe'
               Using MainDATA
	kind	$1000	; no special memory!

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
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (Actions,x)   	; JSR to the appropriate action handler.

exitHere	entry
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
DrawStars	Start
doBlank	Entry
	debug	'Unv:DrawStars'
	debug	'Unv:doBlank'
	Using	MainDATA

	phd		; save Dp aligned with stack frame

               ldx   <T2data1	; movePtr
               ldy   <T2data1+2	; movePtr
	lda	OurDP
	tcd
	stx	movePtr
	sty	movePtr+2

	stz	eraseOverride
	stz	exitDelay

	stz	numstars
	stz	counter
	stz	galaxyinit

               jsr  StartUp

loopL4         Entry
               longmx
nuLoop         anop
               jsr  showstars           do the animation
               lda  counter
	cmp	u_maxstars
;               cmp  u_autostarsM2
;               cmp  #autostars*2
               bge  sepL4
               inc  counter
               lda  counter
               lsr  a
               jcs  up

sepL4	anop
;	pld		; restore DP aligned with stack
;               lda   [T2data1]	; movePtr
	lda	exitDelay
	beq	noDelay
	dec	a
	sta	exitDelay
	beq	exitHere2
	bra	nuLoop

noDelay	lda	[movePtr]
	beq	nuLoop

;	lda	#TRUE
	sta	eraseOverride

	WordResult
	WordResult
	PushWord #80	; numerator
	lda	u_zdec	; starspeed
	pha
	_UDivide
	pla		; quotient
	plx		; chuck remainder
	sta	exitDelay
;	lda	#20
;	sta	exitDelay
	bra	nuLoop

;               bne   exitHere2
;	phd		; save DP aligned with stack
;	lda	OurDP	; restore our DP space
;	tcd
;               bra   nuLoop

exitHere2	anop
	pld
	rts

               End
*-----------------------------------------------------------------------------*
ShowStars      Start
	debug	'Unv:ShowStars'
               Using MainDATA

               php                      routine to animate the stars

               longmx

               lda  numstars            get the number of stars
               sta  starctL0            save in temp location

! main loop starts here...1 time per star
loopL0         lda  starctL0            get the star number
               bne  dostarL0            done if $0000
               brl  exitL0
dostarL0       anop
               dec  a                   index starts at zero
               asl  a
               asl  a
               asl  a
               asl  a                   *16 bytes per star
               sta  offset              save in global star offset
;               tax                      put in index register
;               lda  galaxy+zpos,x       get the current Z position
	tay		; neu
	tax		; neu / needed?
	lda	[galaxy_zpos],y	; neu
               sec
               sbc  u_zdec                move the star toward viewer...
!                                       smaller result means closer.
;               sta  galaxy+zpos,x       save the result in star record
	sta	[galaxy_zpos],y	; neu
               bcc  newstarL0           <=0???
               beq  newstarL0           if yes...we have passed the star...
!                                       so we need to create a new one at
               bra  posstarL0           go position this star

newstarL0      lda  numstars            get number of last star
               cmp  starctL0            is it our current star?
               bne  newstar1L0
               lda  deletestars         any stars to delete?
               beq  newstar1L0
               dec  deletestars
               dec  numstars
               bne  newstar1L0
               stz  deletestars

newstar1L0     lda  u_zspan              put new star at origin
               jsr  newstar             go create the new star



posstarL0      ldy  offset              get our offset back
               stz  negflag             clear negative flag

!                                       the reason we use the neg flag byte
!                                       instead of the the processor register
!                                       is because we want to allow for
!                                       smaller X,Y maximums than $8000.

!                                       we use the formulas
!                                       for our 3D --> 2D transform:

!                                       screenX=spaceX/spaceZ
!                                       screenY=spaceY/spaceZ

;               lda  galaxy+zpos,y       get the Z position in space
	lda	[galaxy_zpos],y	; neu
               tax                      put in X (divisor) for divide
;               lda  galaxy+xpos,y       get the X space of star
	lda	[galaxy_xpos],y	; neu
               cmp  u_xyspanD2          > 1/2 of xyspan?
!                                       (which indicates negative condition)
               blt  nonegL0             no..so we're positive
               sec                      set bit 15 of NEGFLAG
               ror  negflag
               sec
               sbc  u_xyspanD2           subtract 1/2 of XYSPAN to make positive
!                                       for divide.
nonegL0        anop
               jsr  divide              newx=xpos/zpos
               cpx  #$8000              is remainder>0.5??
               blt  testneg1L0          no..so no rounding
               inc  a                   round off result

testneg1L0     bit  negflag             was the original value negative?
               bpl  pos1L0              no..so we're OK!
               eor  #$FFFF              otherwise make two's complement
               inc  a
pos1L0         sta  newx                save our screen X position
!                                       (3DX --> 2DX)

!                                       now...let's convert our Y coordinate
               ldy  offset              get offset into galaxy of current star
               stz  negflag             clear NEGFLAG from above
;               lda  galaxy+zpos,y       get the Z space value in X (divisor)
	lda	[galaxy_zpos],y	; neu
               tax
;               lda  galaxy+ypos,y       get the Y space
	lda	[galaxy_ypos],y	; neu
               cmp  u_xyspanD2           is it negative?
               blt  noneg1L0            no..so do nothing with it
               sec
               ror  negflag             set our neg flag
               sec                      and convert to positive
               sbc  u_xyspanD2           by subtracting 1/2 of XYSPAN

noneg1L0       jsr  divide              newy=ypos/zpos
               cpx  #$8000
               blt  testneg2L0          should we round off?
               inc  a                   round the A reg larger

testneg2L0     bit  negflag             was it negative?
               bpl  pos2L0
               eor  #$FFFF              yes..so take 2's complement
               inc  a
pos2L0         sta  newy                now save our screen Y location

;               ldx  offset              again...get our offset to star rec
;               lda  galaxy+zpos,x       put the Z space into our new Z var
	ldy	offset	; neu
	tyx		; neu / needed?
	lda	[galaxy_zpos],y	; neu
               sta  newz

!                                       at this point we want to check to
!                                       see if the star has changed position
!                                       on the screen or if the Z position
!                                       changes it's appearance.
!                                  ; If nothing needs updating...we do nothing!

;               lda  galaxy+xdraw,x      test last drawn X position...
	lda	[galaxy_xdraw],y	; neu
               cmp  newx
               bne  drawL0
;               lda  galaxy+ydraw,x      test last drawn Y position...
	lda	[galaxy_ydraw],y	; neu
               cmp  newy
               bne  drawL0

!                                       I changed the code slightly to get the
!                                       program working properly..so this code
!                                       looks unnessary since the Z will ALWAYS
!                                       have changed...bear with me!!!

;               lda  galaxy+zdraw,x      test last Z condition vs. new condition
	lda	[galaxy_zdraw],y	; neu
               cmp  newz
               bne  drawL0
               brl  nextstarL0 ; the star hasn't moved/changed so don't draw it

drawL0         bit  galaxyinit          if the galaxy has just been initialized
               bpl  draw1L0             we don't have anything to erase
!                                       because no stars have been drawn.

               pei  newx                save our NEW variables
               pei  newy                since DRAWSTAR requires the star info in
               pei  newz                NEWX..NEWZ and we don't want to lose
!                                       this info just to erase!!
!                                       THIS IS A GOOD PLACE TO OPTIMIZE
;               ldx  offset
;               lda  galaxy+xdraw,x      get the star's last position into
	ldy	offset	; neu
	tyx		; neu / needed?
	lda	[galaxy_xdraw],y	; neu
               sta  newx                NEWX,NEWY,NEWZ
;               lda  galaxy+ydraw,x
	lda	[galaxy_ydraw],y	; neu
               sta  newy
               stz  newz                zero in NEWZ means erase
               jsr  drawstar            DRAW (erase) the old star

               pla                      restore the new values....
               sta  newz
               pla
               sta  newy
               pla
               sta  newx

draw1L0        anop
;	ldx  offset              now get ready to draw the star in it's
	ldy	offset	; neu
	tyx		; neu / needed?
!                                       new position and format.
               lda  newx                put new values into the last drawn part
!                                       of the star record
;               sta  galaxy+xdraw,x
	sta	[galaxy_xdraw],y	; neu
               lda  newy
;               sta  galaxy+ydraw,x
	sta	[galaxy_ydraw],y	; neu
               lda  newz
;               sta  galaxy+zdraw,x
	sta	[galaxy_zdraw],y	; neu

               jsr  drawstar            all the parameters are there already
!                                       so just draw the star
               bcc  nextstarL0 ; if carry clear the star is still on the screen

               lda  numstars            get number of last star
               cmp  starctL0            is it our current star?
               bne  nextstarL0
               lda  deletestars         any stars to delete?
               beq  nextstarL0
               dec  deletestars
               dec  numstars
               bne  nsL0
               stz  deletestars
nsL0           lda  u_zspan         ; if it has left the screen...we need a new
               jsr  newstar             star on the horizon to replace it.


nextstarL0     dec  starctL0            whew!! do it all again for more stars.
               brl  loopL0

exitL0         lda  maxstar
               sec
               sbc  numstars
               sta  starctL0
lupV1          lda  starctL0
               beq  exit1L0
               dec  starctL0
               brl  lupV1
exit1L0        sec
               ror  galaxyinit          the galaxy has been drawn so set the
!                                       init flag to false.
               plp
               rts

               End
*-----------------------------------------------------------------------------*
NewStar        Start
	debug	'Unv:NewStar'
               Using MainDATA

               php                      enters with new Z position in A
               longmx
;               ldx  offset              get global offset to current star rec
;               sta  galaxy+zpos,x       save the new Z value.
	ldy	offset	; neu
	tyx		; neu / needed?
	sta	[galaxy_zpos],y	; neu

;               WordResult
;               _Random
;               pla                      get the number
	jsl	random
               and  u_xyspanS1           force into range...
               pha                      save for later..

;               WordResult               get another random number
;               _Random
;               pla
	jsl	random
               and  u_xyspanS1           force into range

;               ldx  offset              get our offset
;               sta  galaxy+xpos,x       save 1 random number into X pos
	ldy	offset	; neu
	tyx		; neu / needed?
	sta	[galaxy_xpos],y	; neu
               pla                      get the other number
;               sta  galaxy+ypos,x       and put it in star's Y position
	sta	[galaxy_ypos],y	; neu
               plp
               rts

               End

*-----------------------------------------------------------------------------*
DrawStar       Start
	debug	'Unv:DrawStar'
               Using MainDATA

               php
               longmx

               stz  colorL2             set color bytes to 0

               lda  newz         ; are we drawing (NEWZ<>0) or erasing (NEWZ=0)
;               beq  nocolorL2
	bne	drawIt
	ldx	eraseOverride
	beq	noColorL2
	plp
	rts

drawIt	anop
               and  #$00F0             do some tricks to get color number from
               eor  #$00F0             high nybble of the low byte of Z position.
               lsr  a                  the EOR is done so that higher Z pos
               lsr  a                  numbers (farther away) return lower
               lsr  a                  color numbers (blacker).

               tax                     thus, the stars get brighter as they move
!                                      toward the viewer

               lda  tblL2,x             get the color word from table
               sta  colorL2             and save it

nocolorL2      anop

               lda  newx                check to see if X screen is within
               cmp  #left               our range (-160..159)
               bge  xokL2
               cmp  #right
               bge  newL2               out of range..so signal this star
!                                       has moved off of screen
xokL2          clc                      normalize the screen X so that origin
               adc  #org_v              is at center of CRT
               sta  xL2                 and save it.
               
               lda  newy                now check for in range Y (-100..99)
               cmp  #top
               bge  yokL2
               cmp  #bottom
               bge  newL2               it's not..so signal off screen

yokL2          clc
               adc  #org_h              normalize origin at line 100 of CRT
               
               asl  a                   create an index into scanline table
               tax                      and remember it in X

               ldy  #$00                now see if X position is even or odd
               lsr  xL2                 shift our pixel count to convert to
!                              bytes (remember 320 mode has 2 pixels per byte!)

               bcc  noinyL2             even/odd flag is now in carry
               iny                      put carry into byte/mask index
noinyL2        anop

               phy

               txy

!              lda   screentbl,x        get the start address of this scanline
               lda   [SLookUp],y        get the start address of this scanline

               tyx

               ply

               clc
               adc  xL2                 add in shifted X byte
               sta  screenptr           save in DP pointer
               lda  #screenbank         get the bank number we are currently
               sta  screenptr+2         drawing to..and save in DP too.
               
               shortm                   we only need 8 bit here
               lda  [screenptr]         get the current screen byte
               and  masktbl,y    ; mask off which ever pixel we're dealing with
               ora  colorL2,y           OR in color value
               sta  [screenptr]         and put back on screen
               longm                    back to 16 bit
xitL2          plp
               clc                      carry clear indicates star OK and drawn
               rts
newL2          plp
               sec                      indicate this star is off screen
               rts

               End
*-----------------------------------------------------------------------------*
Divide         Start
	debug	'Unv:Divide'
               Using MainDATA

               longa on
               longi on

               cpx  #$0000              check for zero division
               beq  zeroL11
               cpx  #$0001              check for divide by 1
               beq  byoneL11

! you could check here for other special cases...like power of two divisors
! where you could do LSR's

               sta  dividend            save our stuff
               stx  divisor

               ldx  #0                  Start scale counter
               
               lda  divisor             put the divisor in A
               bmi  divL11              divisor > $7fff

*--------------------------------------
* Scale the divisor. Allign divisor to the left until > dividend
* or until bit 15 is set. Count in x.
*--------------------------------------

scaleL11       cmp  dividend
               bcs  scaledL11
               inx
               asl  a
               bpl  scaleL11
scaledL11      anop
               sta  divisor             Scaled divisor

* Start Subtracting

divL11         lda  dividend
               stz  quotient            Clear quotient

div1L11        tay                      save the A
div2L11        sec
               sbc  divisor             Repeated conditional subtract
               bcs  rol1L11             subtraction successful?
rol0L11        tya                      restore old A (before subtact)
               rol  quotient            ROL in a 0
               lsr  divisor
               dex
               bpl  div2L11             Y already has copy of A

               tax                      same exit code as below
               lda  quotient            duplicated here to avoid a jmp/bra
               rts

rol1L11        rol  quotient            ROL in a 1
               lsr  divisor
               dex
               bpl  div1L11             back to div1 to save new A in Y

exitL11        tax                      put remainder in X
               lda  quotient            get the Quotient in A
               rts                      return to caller

zeroL11        ldx  #$FFFF
               txa                      division by 0 returns $FFFF/$FFFF
               rts

byoneL11       ldx  #$00                zero remainder, A already has quotient
               rts

               End
*-----------------------------------------------------------------------------*
up	Start
	debug	'Unv:up'
               Using MainDATA

               longmx
               lda  numstars
               cmp  maxstar
               jge  loopL4
               inc  numstars
               lda  numstars
               dec  a
               asl  a
               asl  a
               asl  a
               asl  a
               sta  offset
               lda  u_zspan
               jsr  newstar
               brl  loopL4

               End
*-----------------------------------------------------------------------------*
StartUp        Start
	debug	'Unv:StartUp'
               Using MainDATA

               ~GetAddress #1	; get lookup table
               PullLong SLookUp         get pointer to table

;               ldx   #$7D00+198         zero pixel data and SCB's only
;               lda   #0
;nextScr        sta   SHR,x
;               dex
;               dex
;               bpl   nextScr

               ldx  #$0000              make color table a gray scale
               txa
grey           sta  PALETTES,x
               clc
               adc  #$222               grays...
               inx
               inx
               cpx  #$10
               blt  grey

	PushLong #toT2String
	jsl	init_random

;               ~ReadTimeHex	; set random seed
;               _SetRandSeed
;               plx
;               plx

               LongResult
	PushWord #0	; hi word
	lda	u_maxstars
	asl	a	; x2
	asl	a	; x4
	asl	a	; x8
	asl	a	; x16
	pha
;               lda   <T2Data2+2	; memory ID
	~MMStartUp
	pla
	ora	#$0100
	pha
	sta	MyID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	jsr	makePdp
	pld
	pla
	sta	galaxy_xpos
	inc   a
	inc	a	; +2
	sta	galaxy_ypos
	inc	a
	inc	a	; +4
	sta	galaxy_zpos
	inc	a
	inc	a	; +6
	sta	galaxy_xdraw
	inc	a
	inc	a	; +8
	sta	galaxy_ydraw
	inc	a
	inc	a	; +10
	sta	galaxy_zdraw
	pla
	sta	galaxy_xpos+2
	sta	galaxy_ypos+2
	sta	galaxy_zpos+2
	sta	galaxy_xdraw+2
	sta	galaxy_ydraw+2
	sta	galaxy_zdraw+2
               rts

               End
*-----------------------------------------------------------------------------*
MainDATA       Data
	debug	'Unv:MainDATA'

toT2String	str	'DYA~Twilight II~'

rUnivFieldVis	str	'Univ: Vision Depth'
rUnivMaxStars	str	'Univ: Max Stars'
rUnivViewAngle	str	'Univ: Viewing Angle'
rUnivStarSpeed	str	'Univ: Star Speed'

;u_autostarsM2	ds	2
u_zspan	ds	2
u_xyspan	ds	2
u_zdec	ds	2	; starspeed
u_maxstars	ds	2
u_xyspanD2	ds	2
u_xyspanS1	ds	2

OurDP	ds	2

! Color table...each entry consists of a color code for even pixels (lowest
! memory address) and for odd pixels (highest memory address)
tblL2          dc   h'0000'             colors increase from black to white
               dc   h'0000'
               dc   h'1001'
               dc   h'1001'
               dc   h'2002'
               dc   h'2002'
               dc   h'3003'
               dc   h'3003'
               dc   h'4004'
               dc   h'4004'
               dc   h'5005'
               dc   h'5005'
               dc   h'6006'
               dc   h'6006'
               dc   h'7007'
               dc   h'7007'

masktbl        dc   h'0FF0'             used for masking individual pixels

xL2            ds    2
yL2            ds    2
colorL2        ds    4

starctL0       ds    2                  temporary counter
starctL10      ds    2                  temporary counter

offset         ds    2                  offset into galaxy of current star
divisor        ds    2                  some Direct Page location for division
dividend       anop
quotient       ds    2             ; same address as dividend, used for clarity
negflag        ds    2                  flag indication pos/neg of X,Y of star

numstars       ds    2                  number of currently active stars
galaxyinit     ds    2                  bit 15 clear=galaxy just initialized
deletestars    ds    2                  number of stars to delete
counter        ds    2
;galaxy         ds    16*maxstars        the galaxy array (16 bytes*maxstars)

maxstar        dc    i'startstars'      maximum number of stars at start
;zdec           dc    i'startspeed'      speed at which stars approach viewer
!                                       bigger is faster, 0 is stop

Actions   	anop
               dc    i'doMake'          ; MakeT2 procedure	0
               dc    i'doSave'          ; SaveT2 procedure	1
	dc	i'doBlank'	; BlankT2 procedure	2
	dc	i'doLoadSetup'	; LoadSetupT2 procedure	3
	dc	i'doNothing'    	; UnloadSetupT2 procedure 4
	dc	i'doKill'	; KillT2 procedure	5
	dc	i'doHit'	; HitT2 procedure	6

WindPtr	ds	4
RezFileID	ds	2
MyID	ds	2
temp	ds	4
tempWord	ds	2
ExtraInfoPtr	ds	4
dfDefProc	ds	4

eraseOverride	ds	2
exitDelay	ds	2

               End
*-----------------------------------------------------------------------------*
doMake         Start
               Using MainDATA
;	dbrk	$00
	debug 'Unv:doMake'

               lda   <T2data1+2
               sta   WindPtr+2
               lda   <T2data1
               sta   WindPtr
;               lda   <T2data2+2
	~MMStartUp
	pla
	ora	#$0200
               sta   MyID

	LongResult
	pei	<T2data1+2
	pei	<T2data1
	_GetWRefCon
	PullLong extraInfoPtr

* Create our non-custom controls.

               LongResult
               pei   <T2data1+2
               pei   <T2data1
               PushWord #resourceToResource
               PushLong #1	;univCtlLst
               _NewControl2
               plx
               plx

* Make sure all the setup data is loaded.

; First make sure we're dealing with the T2pref file.
               ~GetCurResourceFile
               lda   <T2data2
               sta   RezFileID
	pha
               _SetCurResourceFile
; load it
	jsr	doLoadSetup
; restore old rfile (module's rfork)
	_SetCurResourceFile

* // -- FIELD OF VISION DATAFIELD CONTROL TEMPLATE

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#1
	jsr	makePdp
	PushLong extraInfoPtr
	makeDP
	ldy	#2
	lda	[3],y
	sta	dfDefProc+2
	tax
	lda	[3]
	sta	dfDefProc
	killLdp
	ldy	#$0E	; procRef
	sta	[3],y
	iny
	iny
	txa
	sta	[3],y
	pld
	_NewControl2
;	plx
;	plx
               PushWord #SetFieldValue
	PushWord u_zspan
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


* // -- MAX STARS DATAFIELD CONTROL TEMPLATE

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#4
	jsr	makePdp
	ldy	#$0E	; procRef
	lda	dfDefProc
	sta	[3],y
	iny
	iny
	lda	dfDefProc+2
	sta	[3],y
	pld
	_NewControl2
;	plx
;	plx
               PushWord #SetFieldValue
	PushWord u_maxstars
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


* // -- VIEWING ANGLE DATAFIELD CONTROL TEMPLATE

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#5
	jsr	makePdp
	ldy	#$0E	; procRef
	lda	dfDefProc
	sta	[3],y
	iny
	iny
	lda	dfDefProc+2
	sta	[3],y
	pld
	_NewControl2
;	plx
;	plx
               PushWord #SetFieldValue
	PushWord u_xyspan
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


* // -- STAR SPEED DATAFIELD CONTROL TEMPLATE

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#6
	jsr	makePdp
	ldy	#$0E	; procRef
	lda	dfDefProc
	sta	[3],y
	iny
	iny
	lda	dfDefProc+2
	sta	[3],y
	pld
	_NewControl2
	lda	3,s
	pha	
	lda	3,s
	pha
	_MakeThisCtlTarget
               PushWord #SetFieldValue
	PushWord u_zdec
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


	lda	#10
	sta	<T2Result
               rts

               End
*-----------------------------------------------------------------------------*
doSave         Start
               Using MainDATA
	dbrk	$00
	debug 'Unv:doSave'

* Make sure we're dealing with the T2pref file.

               ~GetCurResourceFile
               ~SetCurResourceFile RezFileID

* Get new Field of Vision

	LongResult
	~GetCtlHandleFromID WindPtr,#1
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               pla	                	;this is the current tag
	sta	tempWord
               plx		;always zero

; Load (& create if necessary) and set to new value the flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rUnivFieldVis
               bcs   visionNotThere
               jsr   makePdp
	lda	tempWord
               sta   [3]
	killLdp
	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivFieldVis,#temp ; rID
	_MarkResourceChange
               bra   visionThere

visionNotThere	anop		; result space already on stack
	PushLong #2
	~GetCurResourceApp
;	PushWord MyID
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   tempWord
               sta   [3]
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
	PushLong #rUnivFieldVis	; ptr to name str
	_RMSetResourceName

visionThere	anop

* Get new Max Stars

	LongResult
	~GetCtlHandleFromID WindPtr,#2
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               pla	                	;this is the current tag
	sta	tempWord
               plx		;always zero

; Load (& create if necessary) and set to new value the flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rUnivMaxStars
               bcs   starsNotThere
               jsr   makePdp
	lda	tempWord
               sta   [3]
	killLdp
	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivMaxStars,#temp ; rID
	_MarkResourceChange
               bra   starsThere

starsNotThere	anop		; result space already on stack
	PushLong #2
	~GetCurResourceApp
;	PushWord MyID
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   tempWord
               sta   [3]
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
	PushLong #rUnivMaxStars	; ptr to name str
	_RMSetResourceName

starsThere	anop

* Get new viewing angle

	LongResult
	~GetCtlHandleFromID WindPtr,#3
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               pla	                	;this is the current tag
	sta	tempWord
               plx		;always zero

; Load (& create if necessary) and set to new value the flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rUnivViewAngle
               bcs   angleNotThere
               jsr   makePdp
	lda	tempWord
               sta   [3]
	killLdp
	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivViewAngle,#temp ; rID
	_MarkResourceChange
               bra   angleThere

angleNotThere	anop		; result space already on stack
	PushLong #2
	~GetCurResourceApp
;	PushWord MyID
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   tempWord
               sta   [3]
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
	PushLong #rUnivViewAngle	; ptr to name str
	_RMSetResourceName

angleThere	anop

* Get new star speed.

	LongResult
	~GetCtlHandleFromID WindPtr,#4
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               pla	                	;this is the current tag
	sta	tempWord
               plx		;always zero

; Load (& create if necessary) and set to new value the flag resource.

	~RMLoadNamedResource #rT2ModuleWord,#rUnivStarSpeed
               bcs   speedNotThere
               jsr   makePdp
	lda	tempWord
               sta   [3]
	killLdp
	PushWord #TRUE	; changeflag: true
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivStarSpeed,#temp ; rID
	_MarkResourceChange
               bra   speedThere

speedNotThere	anop		; result space already on stack
	PushLong #2
	~GetCurResourceApp
;	PushWord MyID
	PushWord #attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               lda   1,s
               sta   temp
               lda   1+2,s
               sta   temp+2
               jsr   makePdp
               lda   tempWord
               sta   [3]
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
	PushLong #rUnivStarSpeed	; ptr to name str
	_RMSetResourceName

speedThere	anop

* Update the file and restore original rezFile.

               ~UpdateResourceFile RezFileID

               _SetCurResourceFile
               rts

               End
*-----------------------------------------------------------------------------*
doHit	Start
	debug	'Unv:doHit'

	lda	<t2data2+2	; ctlID - hi word MUST BE ZERO
	bne	dontEnable
	lda	<t2data2
	cmp	#5
	blt	enableUpdate
dontEnable	stz	<T2Result
	rts

enableUpdate	anop		; enable for ids 1 thru 4
	lda	#TRUE
	sta	<T2Result
	rts

               End
*-----------------------------------------------------------------------------*
doLoadSetup	Start
	debug	'doLoadSetup'
	dbrk	$00
;	debug	'doLoadSetup'
	Using MainDATA

	~RMLoadNamedResource #rT2ModuleWord,#rUnivFieldVis
	bcc	visionOK
	plx
	plx
	lda	#255	; default zspan
	sta	u_zspan
	bra	visionOK2

visionOK	anop
	jsr	makePdp
	lda	[3]
	killLdp
	sta	u_zspan

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivFieldVis,#temp ; rID
	_ReleaseResource
visionOK2	anop


	~RMLoadNamedResource #rT2ModuleWord,#rUnivMaxStars
	bcc	starsOK
	plx
	plx
	lda	#200	; default maximum stars
	sta	u_maxstars
	bra	starsOK2

starsOK	anop
               jsr   makePdp
               lda   [3]                ; Get the word in the resource...
               killLdp
	sta	u_maxstars

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivMaxStars,#temp ; rID
	_ReleaseResource
starsOK2	anop


	~RMLoadNamedResource #rT2ModuleWord,#rUnivViewAngle
	bcc	angleOK
	plx
	plx
	lda	#$4000	; default viewing angle
	sta	u_xyspan
	bra	angleOK2

angleOK	anop
               jsr   makePdp
               lda   [3]                ; Get the word in the resource...
               killLdp
	sta	u_xyspan

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivViewAngle,#temp ; rID
	_ReleaseResource
angleOK2	anop
	lda	u_xyspan
	tax
	lsr	a
	sta	u_xyspanD2
	txa
	dec	a
	sta	u_xyspanS1


	~RMLoadNamedResource #rT2ModuleWord,#rUnivStarSpeed
	bcc	speedOK
	plx
	plx
	lda	#4	; default viewing angle
	sta	u_zdec
	bra	speedOK2

speedOK	anop
               jsr   makePdp
               lda   [3]                ; Get the word in the resource...
               killLdp
	sta	u_zdec

	PushWord #3	; purge level 3
	PushWord #rT2ModuleWord	; rtype
	~RMFindNamedResource #rT2ModuleWord,#rUnivStarSpeed,#temp ; rID
	_ReleaseResource
speedOK2	anop

	clc
	rts

               End
*-----------------------------------------------------------------------------*
doNothing	Start
	debug	'Unv:doNothing'

	clc		; don't do anything!
	rts

               End
*-----------------------------------------------------------------------------*
doKill	Start
	debug	'Unv:doKill'

;	brk	$00

               ~ReleaseResource #3,#rControlTemplate,#1
               ~ReleaseResource #3,#rControlTemplate,#4
               ~ReleaseResource #3,#rControlTemplate,#5
               ~ReleaseResource #3,#rControlTemplate,#6
	clc	
	rts

               End
*-----------------------------------------------------------------------------*
	copy	22:makepdp.asm
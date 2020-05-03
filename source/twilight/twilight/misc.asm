         setcom 80
	keep	misc
	mcopy	misc.mac
	copy	13:ainclude:e16.window
	copy	13:ainclude:e16.resources
	copy	13:ainclude:e16.control
	copy	13:ainclude:e16.adb
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.quickdraw
	copy	v1.2.equ
	copy	equates
	copy	tii.equ
	copy	cdev.equ
	copy	debug.equ
*-----------------------------------------------------------------------------*
* LoadModuleErr - v1.0 - 1 Jan 93 - Jim R Maricondo (tc) - T2 v1.0.1b3
* If an error occurs trying to load the module, display an error
* alert listing the error code and module pathname.  This will be a stop
* alert and will have one button - cancel.
* Call:
*   PushWord Error (error number)
*   PushLong PathPtr (pointer to module w-string pathname)
*   jsr LoadModuleErr

LoadModuleErr	Start
	debug	'LoadModuleErr'

	copy	22:debug.asm

rtsAdr	equ	1
pathPtr	equ	rtsAdr+2
error	equ	pathPtr+4

	lda	error,s
	LongResult
	pha
	_HexIt	; convert error to ascii
	PullLong convErr

	lda	pathPtr+2,s
	tax
	lda	pathPtr,s
	phx
	pha
	makeDP

; temporarily convert the pathname w-str into a p-str to pass to alertwindow

	lda	3,s
	inc	a
	sta	pathnamePStr
	lda	3+2,s
	sta	pathnamePStr+2
	lda	[3]
	xba
	sta	[3]

	~InitCursor
 ~AlertWindow #awPString+awResource+awButtonLayout,#lmeErrSub,#awErrLoadModuleCancel
	plx		; get button hit
	lda	[3]	; change the pathname back into a
	xba		; w-string
	sta	[3]
	killLdp
	ply
	plx
	plx
	plx
	phy
               rts

* loadmoduleerror subsitution error alert string array

lmeErrSub	dc    i4'errorPStr'
pathnamePStr	ds	4
errorPStr	anop
	dc	h'04'	; length byte (pstring)
convErr	ds	4

               End
*-----------------------------------------------------------------------------*
EnsureT2Active	Start
	debug	'EnsureT2Active'
	kind	$1000
	Using	BlankNowDATA
	Using	GlobalDATA

;	PushWord #t2GetInfo
;	PushWord #stopAfterOne+sendToUserID
;               ldy   #$0000
;               phy                      ; target (hi)
;               lda   MyID
;               ora   #requestAuxID
;               pha                      ; target (lo)
;               phy
;               phy                      ; dataIn (none)
;               PushLong #stateWordDataOut ; dataOut
;	_SendRequest
;
;	lda	stateWord
;	bit	#%10000	; is T2 currently on?
;	beq	T2On
;
;	PushWord #t2TurnOn
;	PushWord #stopAfterOne+sendToUserID
;               ldy   #$0000
;               phy                      ; target (hi)
;               lda   MyID
;               ora   #requestAuxID
;               pha                      ; target (lo)
;               phy
;               phy                      ; dataIn (none)
;	phy
;	phy		; dataOut (none)
;	_SendRequest

	PushLong OnFlagPtr
	makeDP
	lda	[3]
	sta	oldOnFlagFill+1
	lda	#$FF
	sta	[3]
	ldy	#2
	lda	[3],y
	sta	oldIPCT2OffFill+1
	lda	#0
	sta	[3],y
	killLdp

T2On	anop
	rts

               End
*-----------------------------------------------------------------------------*
DesureT2Active	Start
	debug	'DesureT2Active'
	kind	$1000
	Using	GlobalDATA
	Using	BlankNowDATA

;	lda	stateWord
;	bit	#%10000	; was T2 on at first?
;	beq	T2WasOn

	PushLong OnFlagPtr
	makeDP
oldOnFlagFill	entry
	lda	#0
	sta	[3]
	ldy	#2
oldIPCT2OffFill entry
	lda	#0
	sta	[3],y
	killLdp

;	PushWord #t2TurnOff
;	PushWord #stopAfterOne+sendToUserID
;               ldy   #$0000
;               phy                      ; target (hi)
;               lda   MyID
;               ora   #requestAuxID
;               pha                      ; target (lo)
;               phy
;               phy                      ; dataIn (none)
;	phy
;	phy		; dataOut (none)
;	_SendRequest
T2WasOn	anop
	rts

               End
*-----------------------------------------------------------------------------*
SendBlankNow	Start
	kind	$1000
	Using GlobalDATA
	Using	BlankNowDATA
	debug	'SendBlankNow'

* Make sure T2 is active. (i.e. shift clear stuff)

	jsr	EnsureT2Active

* tell the SHR heartbeat to ignore the mouse for the first 1 second

	PushLong IgnMouseTimePtr
	makeDP
	lda	#2	; 1 second
	sta	[3]
	killLdp

               PushWord #reqBlankScreen
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong #BlankScreenDataIn ; dataIn
               phy
               phy                      ; dataOut (none)
               _SendRequest

               ~FlushEvents #keyDownMask+mUpMask+mDownMask+autoKeyMask,#0
               pla

* if we had to enable T2, then disable it again to make it like before

	jsr	DesureT2Active
	rts

               End
*-----------------------------------------------------------------------------*
* Check for our nifty Easter Egg Type #2 (If the last 3 keys pressed were DYA)
* Requires rom01 or rom03 with ADB keyboard.
* by Jim Maricondo, December 24, 1992.. v1.0
* Enter with adb version in A..
* Exit with carry flag set = egg good.  clear = egg bad.

CheckDYA	Start
	debug	'CheckDYA'

;	lda	adbVersion
	cmp	#4
	beq	rom01
	cmp	#5
	bne	noRom01
rom01	mvw	#33,ramOffToBuffer+1 ; rom01
	lda	#15	; keybuffoffset for rom01
	bra	readBuffOff

noRom01	cmp	#6
	bne	unsupported
	lda	#22	; keybuffoffset for rom03
readBuffOff	jsr	readADB
	inc	a	; transform it - make it last key buffer offset
	and	#$0f
	sta	temp2

	jsr	GetKeyFromBuffer
	cmp	#"A"	
	beq	ok0
	cmp	#"a"
	bne	noEgg2
ok0	lda	temp2
	inc	a
	and	#$0F
	sta	temp2
	jsr	GetKeyFromBuffer
	cmp	#"Y"	
	beq	ok1
	cmp	#"y"
	bne	noEgg2
ok1	lda	temp2
	inc	a
	and	#$0F
	sta	temp2
	jsr	GetKeyFromBuffer
	cmp	#"D"	
	beq	ok2
	cmp	#"d"
	bne	noEgg2
ok2	sec		; yes!
	rts

noEgg2	anop
unsupported	anop
	clc		; no!
	rts

temp2	ds	2

GetKeyFromBuffer anop
	clc
ramOffToBuffer	adc	#40	; rom03
	jsr	readADB
	and	#$FF
	rts

               End
*-----------------------------------------------------------------------------*
AppleII	Start
	debug	'AppleII'
	Using	GlobalDATA

	LongResult
	LongResult
	lda	#0
	pha
	pha
	pha
	PushWord #$fe1f	; IDROUTINE
	_FWEntry
	pla		; y register
	ply
	ply
	ply
	and	#$FF
	cmp	#3	; rom03 only!
	bne	skipSound2

               ~SoundToolStatus
               pla
               bne   skipSound2

	PushWord #t2StartupTools
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
	tax
               ora   #requestAuxID
               pha                      ; target (lo)
	txa
	ora	#miscAuxID
	pha		; dataIn (hi)
	PushWord #%10	; startup snd mgr (datain - lo)
               PushLong #startupDataOut ; dataOut
	_SendRequest
	bcs	skipSound
	lda	errors
skipSound2	bne	skipSound

               ~FFStopSound #$7FFF

	shortm
               lda   >$E100CA
	pha
               ora   #$08
               sta   >$E100CA
	longm

               ~FFStartSound #1,#$FE080C

loop	~FFSoundDoneStatus #0
	pla
	beq	loop

	shortm
	pla
               sta   >$E100CA
	longm

	PushWord #t2ShutdownTools
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
	phy		; dataIn (hi)
	PushWord #%10	; shutdown snd mgr (datain - lo)
	phy
               phy		; dataOut (none)
	_SendRequest

skipSound	rts

;a2sndprmblk    dc    i4'$00FF1000'      ;addr
;               dc    i2'$000C'          ;pages
;               dc    i2'$00F6'          ;sample rate
;               dc    i2'$0000'          ;buffer start addr
;               dc    i2'$000F'          ;buffer size
;               dc    i4'$00FE081E'      ;next wave's parm block
;               dc    i2'$00FF'          ;volume
;a2sndprmblk2   dc    i4'$00FF1D00'      ;addr
;               dc    i2'$001F'          ;pages
;               dc    i2'$00F6'          ;sample rate
;               dc    i2'$0000'          ;buffer start addr
;               dc    i2'$000F'          ;buffer size
;               dc    i4'$00000000'      ;next wave's parm block
;               dc    i2'$00FF'          ;volume

startupDataOut	anop
recvCount	ds	2	; count
errors	ds	2

               End
*-----------------------------------------------------------------------------*
* makePdp.  V1.00 - 12/08/91 by JRM.
*
* Dereference handle (make a pointer) on the stack.
*
* Inputs:
*
* |previous contents|
* |-----------------|
* |     handle      |  Long - Handle to dereference.
* |-----------------|
* |     rtsAddr     |  Word - Return address.
* |-----------------|
*
* Outputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |     pointer     |  Long - Dereferenced handle.
* |-----------------|
* |     rtsAddr     |  Word - Return address.
* |-----------------|
*

makePdp        Start
               debug 'makePdp'

TheHandle      equ   DP+2
DP             equ   1

               plx                      ; yank return address
               phd
               tsc
               tcd
               ldy   #2
               lda   [TheHandle],y
               tay
               lda   [TheHandle]
               sta   <TheHandle
               sty   <TheHandle+2
               phx                      ; push back return address
               rts

               End
*-----------------------------------------------------------------------------*
LogInCodeResConv Start
               debug 'LogInCodeResourceConv'

               ~GetCodeResConverter
               PushWord #rCodeResource
               PushWord #resLogIn+resLogApp ; install in app converter list
               _ResourceConverter
               rts

               End
*-----------------------------------------------------------------------------*
LogOutCodeResConv Start
               debug 'LogOutCodeResConv'

               ~GetCodeResConverter
               PushWord #rCodeResource
               PushWord #resLogOut+resLogApp ; remove from app converter list
               _ResourceConverter
               rts
                                                                               
               End
*-----------------------------------------------------------------------------*
DimAbout	Start
	Using	GlobalDATA
	debug	'DimAbout'

	lda	AboutDisabled+1
	bne	AlreadyDisabled

               PushWord #inactiveHilite ; for HilightControl
               ~GetCtlHandleFromID T2WindP,#AboutCtl
               _HiliteControl           ; Dim the about ctl
	mvw	#TRUE,AboutDisabled+1
AlreadyDisabled rts

               End
*-----------------------------------------------------------------------------*
EnableAbout	Start
	Using	GlobalDATA
	Using	SetupDATA	; for setupWindOpen
	debug	'EnableAbout'

;	~GetMasterSCB
;	pla
;	bit	#mode640
;	beq	DimAbout	; 320 mode, can't have it enabled!

	ldx	setupWindOpen
	bne	DimAbout	; setup open! can't have about enabled.

* If warning alerts are ON and we're in 320 mode, than allow about module
* to be enabled...

	~GetMasterSCB
	pla
	bit	#mode640
	bne	enableIt
	lda	OptionsFlag
	bit	#fWarningAlerts
	beq	DimAbout
;	bra	enableIt

enableIt	anop
AboutDisabled	entry
	lda	#0
	beq	alreadyEnabled
	PushWord #noHilite
               ~GetCtlHandleFromID T2WindP,#AboutCtl
               _HiliteControl           ; enable the about ctl
;	lda	#FALSE
	stz	AboutDisabled+1
alreadyEnabled	rts

               End
*-----------------------------------------------------------------------------*
DimBlankNow	Start
	Using	GlobalDATA
	debug	'DimBlankNow'

	lda	BlankNowDisabled+1
	bne	AlreadyDisabled

               PushWord #inactiveHilite
               ~GetCtlHandleFromID T2WindP,#BlankBtn
               _HiliteControl
	mvw	#TRUE,BlankNowDisabled+1
AlreadyDisabled rts

               End
*-----------------------------------------------------------------------------*
EnableBlankNow	Start
	Using	GlobalDATA
	debug	'EnableBlankNow'

	lda	OptionsFlag	; neu!
	bit	#fRandomize
	bne	DimBlankNow

BlankNowDisabled entry
	lda	#0
	beq	AlreadyEnabled

               PushWord #noHilite
               ~GetCtlHandleFromID T2WindP,#BlankBtn
               _HiliteControl
;	lda	#FALSE
	stz	BlankNowDisabled+1
AlreadyEnabled	rts

               End
*-----------------------------------------------------------------------------*
EnableTest	Start
	Using	SetupDATA
	debug	'EnableTest'

* enable the test control

               PushWord #noHilite
               ~GetCtlHandleFromID setupWindPtr,#T2SetupTestCtlID
               _HiliteControl
	rts

               End
*-----------------------------------------------------------------------------*
DimTest	Start
	Using	SetupDATA
	debug	'DimTest'

* dim the test control

               PushWord #inactiveHilite
               ~GetCtlHandleFromID setupWindPtr,#T2SetupTestCtlID
               _HiliteControl
	rts

	End
*-----------------------------------------------------------------------------*
DimToggle	Start
	Using	GlobalDATA
	debug	'DimToggle'

	lda	ToggleDisabled+1
	bne	AlreadyDisabled

               PushWord #inactiveHilite ; for HilightControl
               ~GetCtlHandleFromID T2WindP,#ToggleCtl
               _HiliteControl           ; Dim the about ctl
	mvw	#TRUE,ToggleDisabled+1
AlreadyDisabled rts

               End
*-----------------------------------------------------------------------------*
EnableToggle	Start
	Using	GlobalDATA
	debug	'EnableToggle'

ToggleDisabled	entry
	lda	#0
	beq	alreadyEnabled
	PushWord #noHilite
               ~GetCtlHandleFromID T2WindP,#ToggleCtl
               _HiliteControl           ; enable the about ctl
;	lda	#FALSE
	stz	ToggleDisabled+1
alreadyEnabled	rts

               End
*-----------------------------------------------------------------------------*
readADB	Start
	kind	$1000
	debug	'readADB'
	Using	ADBDATA

	sta	dataIn	; register
	PushLong #dataOut
	PushLong #dataIn
	PushWord #readMicroMem
	_ReadKeyMicroMemory
	lda	dataOut	; memory value
	rts

               End
*-----------------------------------------------------------------------------*
ADBDATA	Data

adbVersion	ds	2
dataIn	ds	2
dataOut	ds	2

               End
*-----------------------------------------------------------------------------*
initAdbVersion	Start
	kind	$1000
	debug	'initAdbVers'
	Using	ADBDATA

	~ReadKeyMicroData #1,#adbVersion,#readVersionNum
	lda	adbVersion
	rts

               End
*-----------------------------------------------------------------------------*

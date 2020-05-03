         setcom 80
	mcopy	request.mac
	keep	request
	copy  13:ainclude:e16.memory
	copy  13:ainclude:e16.quickdraw
	copy  13:ainclude:e16.resources
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.window
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.gsos
	copy	equates
	copy	tii.equ
	copy	v1.2.equ
	copy	debug.equ
*-----------------------------------------------------------------------------*
* The init request handler!  (DYA~Twilight II~)

iRequestProc   Start
	kind  $1000	; no special memory
	Using RequestDATA
	Using InitDATA
	debug 'iRequestProc'
	copy	22:debug.asm

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	phb
	phk
	plb
	phd
	tsc
	tcd

	lda   <request
	cmp	#firstT2IPC	; $9000
	blt	notT2IPC
	cmp	#lastT2IPC
	bge	notSupportedIpc
;	bork
	sec
	sbc	#firstT2IPC	; $9000
	asl	a
	tax
	jsr	(T2IPC,x)
	brl	requestHandled

notSupportedIpc anop
	cmp	#firstT2PrivIPC	; $9020
	jlt	notSupported	
	cmp	#lastT2PrivIPC
	jge	notSupported
	sec
	sbc	#firstT2PrivIPC
	asl	a
	tax
	jsr	(T2PrivIPC,x)
	brl	requestHandled

notT2IPC	cmp   #$8000
	blt   notT2Message
	cmp   #lastRequestNum
	bge   notT2Message
	asl   a
	tax
	jsr   (Requests,x)
	brl	requestHandled

notT2Message	anop
	cmp	#systemSaysDeskStartUp
	jeq	unBlank_exit
	cmp	#systemSaysDeskShutDown
	jne	checkNDAStupf

* Desk ShutDown Time...


         	~QDStatus                      ;QuickDraw started?
         	pla
         	bne   doZilch                  ;->Yes, so don't do anything
	~FindHandle #$012000
         	lda   3,s
         	ora   1,s                      ;Any handle there?
         	beq   alloc                    ;->No, allocate one
         	_PurgeHandle                   ;Try evicting current tenant
         	bcs   doZilch                  ;->Can't do it...

* Discard our handle from last time..
* (We don't have to worry about discarding this when T2 is purged because
*  we automatically dispose all handles belonging to us..)

	LongResult
alloc	PushLong #$8000	; size
	lda	MyID
	ora	#bufferMemAuxID
	pha
;	pea	$2050
	PushWord #attrFixed+attrPurge2+attrBank+attrAddr
	PushLong #$012000
	~DisposeHandle bankOneH
	_NewHandle
	plx
	ply
	bcc	gotIt
	ldx	#0	
	tay
gotIt	anop
	stx	bankOneH
	sty	bankOneH+2

doZilch	anop

	stz	EventStatus
	stz	QuickStatus
	stz	MenuStatus

	lda	iTE_dp_handle
	ora	iTE_dp_handle+2
	beq	skipTE

	~TEShutDown
	~DisposeHandle iTE_dp_handle
	stz	iTE_dp_handle
	stz	iTE_dp_handle+2

skipTE	anop
	brl	notSupported

;	lda	NDAInstalled
;	bne	unblank_exit
;	brk	$11
;	~InstallNDA #T2_NDA
;	lda	#TRUE
;	sta	NDAInstalled
unblank_exit	anop		; DESK STARTUP TIME
;	brk	$ea
;	debug	'deskstart'

	mvw	#2*11,DontTextBlankDelay

               ~MenuStatus              ; Is the menu manager started up?
               pla
               bcs   noMMgr             ; No, so skip the box!
               beq   noMMgr
	sta	MenuStatus
	bra	checkEMgr
noMMgr	stz	MenuStatus
checkEMgr	anop
	~EMStatus
	PullWord EventStatus
	~QDStatus
	PullWord QuickStatus
	brl	notSupported

CheckNDAStupf	name		; DESK SHUTDOWN TIME!
	cmp   #systemSaysFixedAppleMenu
               beq   addIcon
	cmp	#systemSaysMenuKey
	beq	doMenuKey
	cmp	#systemSaysForceUndim
	bne	noUnblank
	inc	KbdChangedFlg
	bra	requestHandled
noUnblank	cmp   #srqGoAway
               jne   exitReq
               ldy   #$0002             ; fill in resultID with our ID
               lda   MyID
	ora	#ndaAuxID
               sta   [dataOut],y
               iny
               iny
               lda   #$0000             ; resultFlags: not ok to be shut down
               sta   [dataOut],y
               bra   requestHandled
doMenuKey	anop
	ldy	#oMessage
	lda	[dataIn],y
	and	#$00FF
	cmp	#"~"
	beq	CallIt
	cmp	#"`"
	beq	CallIt
;	and	#$00DF
	cmp	#$14	; control-t
	bne	notSupported
CallIt	jsr	CallCDev
	bra	requestHandled

addIcon        anop

	PushLong NDAHandle
	jsr	makePdp
	ldy	#26
	lda	[3],y
	killLdp

               PushWord #refIsPointer   ; itemStruct is ptr
	PushLong #IconMItemStruct
;	PushWord NDA_ID
	pha
               _SetMItemStruct
	mvl	#T2String,itemTitleRef
;	~CalcMenuSize #0,#0,#1

requestHandled	mvw   #$8000,<result     ; request handled
	bra   exitReq

notSupported	anop
	stz   <result	; request not handled

exitReq        pld
	plb
	lda   2,s
	sta   2+10,s
	lda   1,s
	sta   1+10,s
	tsc
	clc
	adc   #10
	tcs
	rtl

IconMItemStruct dc   i2'$8000'          ; itemFlag2: icon associated with struct
itemTitleRef   dc    i4'T2String'       ; itemTitleRef: menu item name
itemIconRef    dc    i4'theIcon'        ; itemIconRef: pointer to icon

T2String	str	'Twilight II'

TheIcon       	dc	i'$8000'         	; iconType
	dc	i'36'	; iconSize
       	dc	i'$0009'	; iconHeight
       	dc	i'$0008'	; iconWidth

	dc	h'00000000'
       	dc	h'0FFFFFF0'
       	dc	h'0F1144F0'
       	dc	h'0F11EEF0'
       	dc	h'0FBBEEF0'
       	dc	h'0FFFFFF0'
       	dc	h'00000000'
       	dc	h'F0FFFF0F'
       	dc	h'F000000F'

       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'FFFFFFFF'
       	dc	h'0FFFFFF0'
       	dc	h'0FFFFFF0'

	End
*-----------------------------------------------------------------------------*
RequestDATA    Data
	debug 'RequestDATA'

RequestStr	dc	i1'str_end-str_start'
str_start	dc	c'DYA~Twilight II~'
RequestMemID	dc	c'????~'
str_end	anop

Requests       anop
	dc	a'OpenT2PrefFile'	; request number 0
	dc	a'FadeOut'	; 1
	dc	a'FadeIn'	; 2
	dc	a'Blank_Screen'	; 3
	dc	a'Load_Module'	; 4
	dc	a'Install_NDA'	; 5
	dc	a'Remove_NDA'	; 6
	dc	a'dlzss_main'	; 7
	dc	a'ConcatenatePathStrings' ; 8
	dc	a'randomize_module' ; 9
	dc	a'removeT2'	; A
	dc	a'SetBuffers'	; B

T2IPC	anop
	dc	a'ipcTurnOn'	; $9000
	dc	a'ipcTurnOff'	; 1
	dc	a'ipcBoxOverrideOff' ; 2
	dc	a'ipcBoxOverrideOn' ; 3
	dc	a'ipcGetInfo'	; 4
	dc	a'ipcStartupTools'	; 5
	dc	a'ipcShutdownTools' ; 6
	dc	a'ipcShareMemory'	; 7
	dc	a'ipcSetBlinkProc'	; 8
	dc	a'ipcForceBkgBlank'	; ipcGetNoBlankCursors' ; 9
	dc	a'ipcBkgBlankNow'	; A (10)
	dc	a'ipcGetBuffers'	; B (11)
	dc	a'0'	; ipcGetVersion'	; C (12)
	dc	a'ipcCalcFreqOffset' ; D (13)

T2PrivIPC	anop
	dc	a'privGetProcs'	; $9020

OpenPrefsDataOut anop	; DataOut (for sendRequest)
               ds    2                  ; count
PrefFileID	ds    2                  ; rezFile id of pref rezFile
PrefErrCode	ds	2	; error code (if applicable)

ErrorDataOut	anop		; DataOut (for reqLoadModule)
	ds	2	; count
loadErr	ds	2	; any errors

	End
*-----------------------------------------------------------------------------*
* OpenT2PrefFile.  V1.00 - 12/31/91 by JRM. - initial version
*   V1.10 - 01/21/92 by JRM. - added error code returning
*   V1.11 - 01/24/92 by JRM. - even better error returning
*   V1.12 - 05/25/92 by JRM. - optimized dataOut access (1.0d33)
*
* Open the T2 preference file (currently "Twilight.Setup").
* If it doesn't exist, create it.
* Return ID of the rezFile if opened successfully, else return error code.
*
* DataIn = NIL.
*
* DataOut = 2 word field - REQUIRED (both words)
* (@+02): Resource file ID of preferences resource file. (From OpenResFile)
* (@+04): Error code, if any errors occurred.  Zero if no errors.
*

OpenT2PrefFile Start
	kind  $1000	; no special memory
	Using InitDATA
	Using RequestDATA
	debug 'OpenT2PrefFile'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

;	dbrk	$94

* First try to open the resource fork of the preferences file.

OpenPrefFile	anop
	WordResult	; Try to open rez fork of Twilight II
	PushWord #readWriteEnable ; Read/Write file access!
	lda   #$0000
	pha
	pha		; pointer to resource map in memory
	PushLong SetupPathPtr	; pointer to C1 pathname
	_OpenResourceFile        ; of resource file
	plx
	stx	OpenedID
	bcc	FileExists
;	cmp	#fileBusy
;	beq	PrefError
	cmp	#fileNotFound
	bne	PrefError

* If the file doesn't exist, then create a new one.

	PushLong #setup_auxtype	; auxtype
	PushWord #setup_filetype	; filetype (configuration file)
	PushWord #setup_access	; fileaccess (IMPLEMENT: invisible?)
	PushLong SetupPathPtr	; filename
	_CreateResourceFile
	bcc	FileCreated
	bra	PrefError

FileCreated	anop
	WordResult	; Try to open rez fork of Twilight II
	PushWord #readWriteEnable ; Read/Write file access!
	lda   #$0000
	pha
	pha		; pointer to resource map in memory
	PushLong SetupPathPtr	; pointer to C1 pathname
	_OpenResourceFile        ; of resource file
	plx
	bcc	noOpenError

PrefError	stz	OpenedID
	ldy   #4
	sta   [dataOut],y	; store error code in output buffer
	lda	#0
	dey
	dey
	sta   [dataOut],y	; store 0 for rezFile ID in output buff
	rts

noOpenError	anop
	stx	OpenedID
	jsr	CopyNewPrefs
	bcs	PrefError
	~UpdateResourceFile OpenedID

FileExists	anop
	lda   OpenedID           ; store resource fileNum
	ldy   #2
	sta   [dataOut],y        ; store in output buffer
	lda	#0
	iny
	iny
	sta   [dataOut],y        ; store 0 for error code in output buff
	rts

OpenedID	ds	2

	End
*-----------------------------------------------------------------------------*
* Copy default T2 preferences as found in the Twilight.II rfork under a type of
* rT2Setup1 to the newly created Twilight.Setup file, under a type
* of rT2ExtSetup1 (rT2Setup1+$1000).
*
* Carry set = A has error
* Carry clear = no error  (01/24/92 - JRM)
*
* Optimized 1/1/93 - v1.0.1b3 - JRM

CopyNewPrefs	Start
	debug 'CopyNewPrefs'

	stz	rID

copyRez	lda	rID
	asl	a
	asl	a
	tax
	lda	rIDs+2,x
	pha
	lda	rIDs,x
	pha
	PushWord #rT2Setup1
	jsl   CopyRezPref
	bcs	abortCopy

	lda	rID
	inc	a
	sta	rID
	cmp	#5
	blt	copyRez
	clc
	rts

abortCopy	sec
	rts

rIDs	dc	i4'Options2Rez,OptionsRez,TimeRez,CornersRez,SwapTimeRez'
rID	ds	2

	End
*-----------------------------------------------------------------------------*
* CopyPrefRez.  V1.00 - 01/01/92 by JRM. - coded
*               V1.05 - 01/24/92 by JRM. - better error returning
*
* Copy a preferences resource from the Twilight.II rfork to the Twilight.Setup
* rfork.
*
* Inputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |      rezID      |  Long - ID of resource to work with
* |-----------------|
* |     rezType     |  Word - Type of resource to work with
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*
* Outputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*
* Carry Set = A has error code.
* Carry Clear = no errors.
*

CopyRezPref    Start
	kind  $1000	; no special memory
	debug 'CopyRezPref'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
rezType        word
rezID          long

	phb
	phd
	tsc
	tcd

	LongResult
	pei	<rezType
	peil	<rezID
	_LoadResource
	bcs	exitProcError

;	bcc   noError
;	dbrk	$03	; IMPLEMENT: better error handling!
;noError	anop

	pei	<rezType
	peil	<rezID
	_DetachResource
	bcs	exitProcError
	
	PushWord #attrNoSpec+attrNoCross ; implement: attrfixed?
	lda	<rezType
	clc
	adc	#$1000
	pha
	peil	<rezID
	_AddResource
	bcs	exitProcError

exitProc       pld
	plb
	lda   1,s
	sta   1+6,s
	lda   2,s
	sta   2+6,s
	tsc
	clc
	adc   #6
	tcs
	clc
	rtl

exitProcError	pld
	plb
	lda   1,s
	sta   1+6,s
	lda   2,s
	sta   2+6,s
	tsc
	clc
	adc   #6
	tcs
	sec
	rtl

	End
*-----------------------------------------------------------------------------*
* FadeOut. V1.00 - 10 May 1992 by JRM. coded (from Fader) (1.0d32)
*          V1.01 - 28 May 1992 by JRM. memory allocated dynamically (1.0d33)
*
* Fade the SHR screen out (modifying bank $e1 palettes)
*
* DataIn = NIL.
*
* DataOut = NIL.
*

FadeOut	Start
	kind  $1000	; no special memory
	debug 'FadeOut'
	Using	FadeDATA

	DefineStack
TempLong1  	long
TempLong2	long
stkFrameSize   EndLocals
dp2	word
rtsaddr	word
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

	jsr	AllocFadeMem

	longi on
	php
	shortm
	ldx   #$01FF
	ldy   #$03FF
repeat0        lda   PALETTES,x
	and   #$F0
	sta   [TempLong1],y	;buffer1,y
	lsr   a
	lsr   a
	lsr   a
	lsr   a
	sta   [TempLong2],y	;buffer2,y
	dey
	lda   PALETTES,x
	and   #$0F
	sta   [TempLong2],y	;buffer2,y
	asl   a
	asl   a
	asl   a
	asl   a
	sta   [TempLong1],y	;buffer1,y
	dey
	dex
	bpl   repeat0

	mvw   #16,amount

fade           jsr   prepare
	jsr   fadeIt
	dec   amount
	bne   fade

quit           anop
	plp
	longa	on
	longi	on
	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	~DisposeHandle FadeHandle
	rts

	longa	off
	longi	on
prepare        ldy   #$03FF
repeat         lda   [TempLong1],y	;buffer1,y
	sec
	sbc   [TempLong2],y	;buffer2,y
	sta   [TempLong1],y	;buffer1,y
	dey
	bpl   repeat
	rts

fadeIt         anop
w1             lda   RDVBLBAR
	bmi   w1
w2             lda   RDVBLBAR
	bpl   w2

	ldx   #$01FF
	ldy   #$03FE
more           lda   [TempLong1],y	;buffer1,y
	lsr   a
	lsr   a
	lsr   a
	lsr   a
	sta   temp
	iny
	lda   [TempLong1],y	;buffer1+1,y
	dey
	and   #$F0
	ora   temp
	sta   PALETTES,x
	dey
	dey
	dex
	bpl   more
	rts
	longa	on
	longi	on

	End
*-----------------------------------------------------------------------------*
* AllocFadeMem. V1.00 - 28 May 1992 by JRM. coded (1.0d33)
*
* Dynamically allocate memory for fadeIn and fadeOut (at fade time)
*

AllocFadeMem	Start
	debug	'AllocFadeMem'
	Using	FadeDATA
	Using	InitDATA

	DefineStack	; defineDP
TempLong1  	long
TempLong2	long
dp2	word
rtsaddr	word
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

               LongResult
               PushLong #$800
               lda   MyID
               ora   #miscAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
	bcc	Good
	plx
	plx
	sec
	rts
Good	lda	1,s
	sta	FadeHandle
	lda	1+2,s
	sta	FadeHandle+2
	jsr	makePdp
	pld
	pla
	sta	<TempLong1
	clc
	adc	#$400
	sta	<TempLong2
	pla
	sta	<TempLong1+2
	sta	<TempLong2+2

	ldy	#$800-2
	lda	#0
zeroBuffers	sta	[TempLong1],y
	dey
	dey
	bpl	zeroBuffers
	clc
	rts

               End
*-----------------------------------------------------------------------------*
FadeDATA	Data
	debug	'FadeDATA'

temp           ds    2
amount         ds    2
FadeHandle	ds	4

	End
*-----------------------------------------------------------------------------*
* FadeIn. V1.00 - 11 May 1992 by JRM. coded (from Fader) (1.0d32)
*         V1.01 - 28 May 1992 by JRM. memory allocated dynamically (1.0d33)
*
* Fade the SHR screen in (modifying bank $e1 palettes)
*
* DataIn = Pointer to $200 bytes of destination palettes.
*
* DataOut = NIL.
*

FadeIn         Start
	debug	'FadeIn'
	Using	FadeDATA

	DefineStack	; defineDP
TempLong1  	long
TempLong2	long
stkFrameSize   EndLocals
dp2	word
rtsaddr	word
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

	jsr	AllocFadeMem

	lda	<dataIn
	sta	patch1+1
	sta	patch2+1
	lda	<dataIn+2
	shortm
	sta	patch1+3
	sta	patch2+3
	longm

;	peil	dataOut
;	makeDP
;	ldy   #2
;	lda   [3],y              ; store in output buffer
;	sta	patch1+1
;	sta	patch2+1
;	iny
;	iny
;	lda   [3],y              ; store 0 for error code in output buff
;	shortm
;	sta	patch1+3
;	sta	patch2+3
;	longm
;	killLdp

	php       	save old processor status register
	longi on
	shortm
	ldx   #$01FF
	ldy   #$03FF
patch1	anop
repeat0        lda   >$0,x	; copy palettes into buffer
	and   #$F0
	lsr   a
	lsr   a
	lsr   a
	lsr   a
	sta   [TempLong2],y	;buffer2,y
	dey
patch2	anop
	lda   >$0,x
	and   #$0F
	sta   [TempLong2],y	;buffer2,y
	asl   a
	asl   a
	asl   a
	asl   a
	dey
	dex
	bpl   repeat0

	lda   #16
	sta   amount

fade           anop
	jsr   prepare            fade palettes in buffer
	jsr   fadeIt             store buffer data to palettes
	dec   amount             done 16 times yet?
	bne   fade

quit           anop
	plp       	restore old processor status register
	longa	on
	longi	on
	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	~DisposeHandle FadeHandle
	rts

	longi	on
	longa	off
prepare        ldy   #$03FF
repeat         lda   [TempLong1],y	;buffer1,y
	clc
	adc   [TempLong2],y	;buffer2,y
	sta   [TempLong1],y	;buffer1,y
	dey
	bpl   repeat
	rts

fadeIt         anop
w1             lda   RDVBLBAR
	bmi   w1
w2             lda   RDVBLBAR
	bpl   w2

	ldx   #$01FF
	ldy   #$03FE
more           lda   [TempLong1],y	;buffer1,y
	lsr   a
	lsr   a
	lsr   a
	lsr   a
	sta   temp
	iny
	lda   [TempLong1],y	;buffer1+1,y
	dey
	and   #$F0
	ora   temp
	sta   PALETTES,x
	dey
	dey
	dex
	bpl   more
	rts
	longa	on
	longi	on

	End
*-----------------------------------------------------------------------------*
* load_module.
*  v1.00 - 1 June 1992 JRM - coded - initial version (1.0d33)
*  v1.01 - 26 December 1992 JRM - handles renamed volumes better (1.0.1b3)
*        - also handles errors better with new dataOut defined.
*
* Old module MUST have already been unloaded, and UnloadSetupT2 called, if
* necessary.
*
* DataIn = handle to module pathname.
*
* DataOut = pointer to following structure:
*  +00 - word - receive count
*  +02 - word - errors (0 if none)
*  +04 - eos  - end of structure
*

load_module	Start
	kind  $1000	; no special memory
               Using InitDATA
	Using LoadDATA
	Using	RequestDATA
               debug 'load module'

	DefineStack	; defineDP
dpageptr	word
dbank	byte
retaddr	block 3
dataOut	long
dataIn	long
request	word
result	word

;	dbrk	04

* check for internal modules..

	lda	<datain+2
	ora	<datain
	beq	frg	; if no module, use frg blank now

	peil	<datain	; hndl to W-str
	jsr	makePdp
	lda	3,s
	sta	pathPtr
	lda	3+2,s
	sta	pathPtr+2
	ldy	#2
	lda	[3],y
	killLdp
	cmp	#"aB"	;BkgFadeWStr+2
	beq	bkg
	cmp	#"oF"	;FrgFadeWStr+2
	jne	external
frg	anop

               lda   #DefaultB
               sta   BlankRtn+1
               lda   #^DefaultB
               shortm
               sta   BlankRtn+3
               longm
	lda	#fInternal+fForeground+fFadeIn+fFadeOut
	sta	ModuleFlags
               brl   store

bkg	anop
               lda   #0
               sta   BlankRtn+1
               sta   BlankRtn+2
	lda	#fInternal+fBackground+fFadeIn+fFadeOut
	sta	ModuleFlags
	brl	store

external	anop

* First try to open the resource fork of the module..

	brl	TryToLoadRFork

* New! 12/26-27/92 v1.0.1b3 JRM (tc)

do_volnotfound_alert	anop

* Find out how long the volume name and delimiter are.

	PushLong pathPtr
	makeDP
	ldy	#3	; skip past length word and first ":"
	ldx	#1	; start at 1 because of the first ":"
	shortm
search	lda	[3],y
	cmp	#":"
	beq	donesearch
	inx
	iny
	bra	search
donesearch	anop

* use curName_textLen as a temporary place to hold the volName pString

	txa
	sta	curName_textLen	; store length byte
copyVolName	lda	[3],y
	sta	curName_textLen+1,x
	dey
	dex
	bpl	copyVolName
	longm
	killLdp

* Pass this volume name to alert window to be displayed in an alert.

	~InitCursor
 ~AlertWindow #awPString+awResource+awButtonLayout,#volNameSub,#AlertInsertT2Disk
	plx		; get button hit
	bne	TryToLoadRFork	; OK hit
cancel	anop		; cancel hit

* [Cancel hit] - exit returning an error of $FFFF.

error_exitLM	anop
	lda	#-1
	ldy	#2
	sta	[dataOut],y
	rts

TryToLoadRFork	anop
;	brk	05
;	debug	'trytoloadrfork'

* Find out if we're being called during boot or not.

;	_GetNameGS p_getName

* open the module's rfork.
*
* If an error occurs here during boot, beep and deactivate T2 and draw a red
* X over our icon.
*
* FYI-If OpenResourceFile can't find the volume specified during boot,
*     it will display a text box asking the user to insert it.  If the user
*     selects CANCEL, it will return volNotFound.
*
* If volNotFound occurs in the desktop environment, display an error alert
* (above) telling the user the disk needed, and giving the user an
* opportunity to click cancel.  If cancel is clicked, return error -1, which
* will eventually result in T2 purging itself from memory.
* (See the revision ERS for more info!)

               WordResult
               PushWord #readEnable     ; file access
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
	PushLong pathPtr	; pointer to C1 pathname of rez file
               _OpenResourceFile	; leave rezfileid on stack
	jcc	rezFileOk	; TEMPORARY !!!!!!!!! change to bcc
	plx		; cleanup stack
	cmp	#volNotFound
	beq	volErr
	pha		; save error number

	brk	05
	ldx	pathPtr
	ldy	pathPtr+2	

	~WindStatus
	plx
	beq	err_exitLM2_pla
	bcs	err_exitLM2_pla

;	lda	curName_textLen	; if we're during boot then error exit
;	beq	err_exitLM2	; and remove ourselves from memory

	pla		; get error num back

* If a different error occurs in the desktop environment, display an error
* alert listing the error code and module pathname.  This will be a warning
* alert and will have one button - continue.  After continuing, error -1 will
* be returned, again resulting in T2 purging itself from memory.

	LongResult
	pha
	_HexIt	; convert error to ascii
	PullLong convErr

	lda	pathPtr+2	; temporarily change the w-string
	pha		; pathname into a pstring to pass to
	sta	pathnamePStr+2	; alertWindow
	lda	pathPtr
	pha
	inc	a
	sta	pathnamePStr
	makeDP
	lda	[3]
	xba
	sta	[3]

	~InitCursor
 ~AlertWindow #awPString+awResource+awButtonLayout,#lmOrfErrSub,#awErrLoadModuleCont
	plx		; chuck button hit
	lda	[3]	; change the pathname back into a
	xba		; w-string
	sta	[3]
	killLdp
err_exitLM2	brl	error_exitLM
err_exitLM2_pla anop
	pla
	bra	err_exitLM2

* if volume STILL isn't found after the user just hit OK, (way up above)
* then bring up the SAME alert!  (only if we're not during boot)

volErr	anop
;	_GetNameGS p_getName
;	lda	curName_textLen	; if we're during boot then error exit
;	beq	err_exitLM2	; and remove ourselves from memory
	~WindStatus
	plx
	beq	err_exitLM2
	bcs	err_exitLM2
	brl	do_volnotfound_alert

* No problems!

rezFileOk	anop
;               WordResult
;               PushLong #1
;               PushWord #rT2ModuleFlags
;               jsl   GetRezWord
;	PullWord ModuleFlags

               ~LoadResource #rT2ModuleFlags,#1 ; get module flags resource,
	bcc	flagOk
	PushWord #$1000
	PushLong #1
	_LoadResource
	bcc	flagOk
	plx
	plx
	dbrk	$ff
	dbrk	$fe
	brk	$fd
flagOk	jsr	makePdp
	ldy	#oMF_flags
	lda	[3],y
	sta	ModuleFlags
	killLdp
	~ReleaseResource #3,#rT2ModuleFlags,#1
	~ReleaseResource #3,#$1000,#1

	_CloseResourceFile	; rezFileID already on stack
	errorbrk

* Load the module into memory.

               WordResult
               WordResult
               LongResult
               WordResult
               PushWord iModuleID
	PushLong pathPtr
               PushWord #TRUE
               PushWord #1
               _InitialLoad2
               bcc   ValidLoad
               plx
               plx
               plx
               plx
               plx
               brl   UseDefault
ValidLoad      pla
               pla                      ;and store it's address into the
               sta   BlankRtn+1         ;doBlank routine, so that when it's time
               pla                      ;to blank, it'll be called
               shortm
               sta   BlankRtn+3
               longm
               pla
               pla

	stz	LSResult
	stz	LSResult+2

	lda	ModuleFlags
	bit	#fLoadSetupBlank
	bne	noLoadSetup
	bit	#fLoadSetupBoot
	bne	loadSetup

* if t2 volume is non-removable then skip loading setup now - 1.1f4
* because it will be loaded right before blanking

	lda	nonremovableT2Vol
	bne	noLoadSetup

;	lda	pVolume_deviceID
;	cmp	#5	; SCSI hard disk
;	beq	noLoadSetup

loadSetup	anop

;	debug	'snd2'
	lda	OptionsFlag
	bit	#fNoSound
	bne	noSound
	lda	#1
	trb	LSFlags	; sound can be used
	bra	goSound
noSound	anop
	lda	#1
	tsb	LSFlags	; sound shouldn't be used!
goSound	anop

* Tell module to load setup data now.

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #LoadSetupT2    ; T2message = load setup data
	phy
	phy		; reserved [T2Data1]
	phy		; reserved T2data2 (hi)
	PushWord LSFlags  	; T2data2 (lo) = flag word (see 1.2.6)
               jsl   BlankRtn           ; run it
	PullLong LSResult	; T2result = new flags

noLoadSetup	anop
store          anop
	lda	#0
	ldy	#2
	sta	[dataOut],y
               rts

UseDefault     lda   #DefaultB
               sta   BlankRtn+1
               lda   #^DefaultB
               shortm
               sta   BlankRtn+3
               longm
	stz	ModuleFlags
               bra   store

pathPtr	ds	4
volNameSub	dc	i4'curName_textLen'

* loadmodule openresourcefile error alert substitution array

lmOrfErrSub    dc    i4'errorPStr'
pathnamePStr	ds	4
errorPStr	anop
	dc	h'04'	; length byte (pstring)
convErr	ds	4

               End
*-----------------------------------------------------------------------------*
Install_NDA	Start
	kind  $1000	; no special memory
	debug	'Install NDA'
	Using	InitDATA

	DefineStack	; defineDP
dpageptr	word
dbank	byte
retaddr	block 3
dataOut	long
dataIn	long
request	word
result	word

* since we could be called during boot, we need to install the NDA from
* a scheduler task.  (as we can't install it during bootCDev 'cuz the DM is
* busy)
* also, doing this from a scheduler task has an added benefit of setting up
* the resource path correctly so we don't get a dumbass sysfailmgr rez error!

;	dbrk	$56	;tmp

	~SchAddTask #InstallNDA
	pla
	bne	schOk	; installed ok
	lda	#2
	tsb	addSchTask
schOk	rts


InstallNDA	ename
	phb
	phk
	plb
	lda	InstalledNDA
	bne	already_did
	~InstallNDA NDAHandle
	errorbrk $ec
;	bcc	noErrInst
;	dbrk	$ec
;noErrInst	anop
	mvw	#TRUE,InstalledNDA
	jsr	fixNDAMenu

already_did	plb
	rtl


fixNDAMenu	name
	~DeskStatus
	pla
	bne	iFixTheDamnMenu
	rts

; It's time.  First, send it a "startup" code, then do the futz to refix the Apple
; menu without leaving the application.

iFixTheDamnMenu name
	~GetSysBar
	jsr	makePdp	; ptr to menu bar record on stack
	
	ldy 	#$28	; offset to list of menu handles
	lda 	[3],y
	tax
	iny
	iny
	lda 	[3],y
	sta	<3+2
	stx	<3	; stack now has handle of first menu
	pld
	jsr	makePdp	; stack now has ptr to first menu
	
	~GetNumNDAs
	pla
	dec	a	; don't count the NDA we just installed!
	sta	Temp2
	
; By the way, this also depends on the fact that all the NDAs have menu items
; that are numbered from 1 to GetNumNDAs.

FutzLoop	anop
	~DeleteMItem Temp2
	dec	Temp2
	bne	FutzLoop

	lda	[3]	; id of the apple (1st) menu
	pha
	_FixAppleMenu
	
	lda #0
	pha		; calculate width
	pha		; calculate height
	lda	[3]
	pha		; id of the apple menu
	_CalcMenuSize

	killLdp
	rts
	
Temp2	ds	2

               End
*-----------------------------------------------------------------------------*
Remove_NDA	Start
	kind  $1000	; no special memory
	debug	'Remove NDA'
	Using	InitDATA

	DefineStack	; defineDP
dpageptr	word
dbank	byte
retaddr	block 3
dataOut	long
dataIn	long
request	word
result	word

;	lda	InstalledNDA
;	beq	already_removed

* we do this from a scheduler task for the added benefit of setting up
* the resource path correctly so we don't get a dumbass sysfailmgr rez error!

	~SchAddTask #RemoveNDA
	pla
	bne	schOk	; installed ok
	lda	#4
	tsb	addSchTask

schOk	anop
;already_removed anop
	rts

RemoveNDA	ename
;	brk	$9a

	phb
	phk
	plb

disposeFill	entry
	lda	#0	; this will be made true by reqRemoveT2
	beq	skipRemReq	; so we can remove ourselves after the NDA

* Finally remove our request procedure..
* (this can't be done from the removeT2 request)

	ldy	#$0000
	phy
	phy		; nameString
               lda   MyID
               ora   #requestAuxID
               pha		; userID
	phy
	phy		; requestProc (remove procedure)
               _AcceptRequests

skipRemReq	anop

	lda	InstalledNDA
	beq	notInstalled
	~RemoveNDA NDAHandle
	stz	InstalledNDA
	jsr	rFixTheDamnMenu
notInstalled	anop

	lda	disposeFill+1	; this will be made true by reqRemoveT2
	beq	skipIDjunk	; so we can remove ourselves after the NDA

;	lda	#FALSE
	stz	disposeFill+1

	php
	sei
* Deallocate all our memory.. including the memory we're running from NOW.
* (this can't be done from the removeT2 request either.)

	lda	MyID
;	ora	#codeRezAuxID	; must be F!
	pha
	_DisposeAll
	~DeleteID MyID
	plp

skipIDjunk	anop
	plb
	rtl

rFixTheDamnMenu name
	~GetSysBar
	jsr	makePdp	; ptr to menu bar record on stack
	
	ldy 	#$28	; offset to list of menu handles
	lda 	[3],y
	tax
	iny
	iny
	lda 	[3],y
	sta	<3+2
	stx	<3	; stack now has handle of first menu
	pld
	jsr	makePdp	; stack now has ptr to first menu
	
	~GetNumNDAs
	pla
	inc	a	; plus the t2 nda we just removed!
	sta	Temp2
	
; By the way, this also depends on the fact that all the NDAs have menu items
; that are numbered from 1 to GetNumNDAs.

FutzLoop	anop
	~DeleteMItem Temp2
	dec	Temp2
	bne	FutzLoop

	lda	[3]
	pha		; id of the 1st (apple) menu
	_FixAppleMenu
	
	lda #0
	pha		; calculate width
	pha		; calculate height
	lda	[3]
	pha		; id of the menu
	_CalcMenuSize

	killLdp
	rts
	
Temp2	ds	2

               End
*-----------------------------------------------------------------------------*
* dlzss_main.  september 9 1992 by jim maricondo (1.0d37)
* datain structure:
*  +00 word- eorvalue
*  +02 long- inputpointer - bit 15 set means that T2 will check MovePtr
*  +06 long- outputpointer
*  +10 long- outputlength
*  +14 eos= IF bit 15 clear above.  ELSE:
*  +14 word- true if dlzss exited because of movePtr becoming true
*  +16 eos=

dlzss_main	Start
	kind  $1000	; no special memory
	debug	'dlzss main'
	Using	InitDATA

	DefineStack	; defineDP
dpageptr	word
dbank	byte
retaddr	block 3
dataOut	long
dataIn	long
request	word
result	word

	ldy	#4	; get hi word of input pointer
	lda	[dataIn],y
	bit	#$8000
	bne	realMovePtr
	PushLong #fakeMovePtr
	bra	skip
realMovePtr	PushLong #BlankFlag
skip	anop
	lda	[dataIn]	; eor value
	pha
	ldy	#4	; input pointer
	lda	[dataIn],y
	pha
	dey
	dey
	lda	[dataIn],y
	pha
	ldy	#8	; output pointer
	lda	[dataIn],y
	pha
	dey
	dey
	lda	[dataIn],y
	pha
	ldy	#12	; output length
	lda	[dataIn],y
	pha
	dey
	dey
	lda	[dataIn],y
	pha

;	ldy	#0
;gogogo	lda	[dataIn],y
;	pha
;	iny
;	iny
;	cpy	#14
;	blt	gogogo

	jsl	Dlzss
	php

	ldy	#4	; get hi word of input pointer
	lda	[dataIn],y
	bit	#$8000
	bne	not_done	; extra boolean field at +14
	plp
	bra	done
not_done	anop
	lda	#FALSE
	ldy	#14
	sta	[dataIn],y
	plp
	bcc	done	; it's already false so leave it..
	lda	#TRUE
	sta	[dataIn],y
done	rts

fakeMovePtr	dc	i'0'

	End
*-----------------------------------------------------------------------------*
* Unpack a section of memory
*
DLzss	Start
	debug	'DLzss'
	Using	RequestDATA
	Using	InitDATA

RINGSIZE	equ	4096	;/* size of ring buffer */
MATCHMAX	equ	18	;/* upper limit for match_length */
THRESHOLD	equ	2	;/* encode string into position and length

	DefineStack
SCREENAD	long		;Pointer
RingIndex	word		;Index to ring buffer
Flags	word		;Index to flags
eorval	word
RingPtr	long
stkFrameSize   EndLocals
dpageptr       word
retaddr        block 3
outputlength	long		; number of bytes to unpack
outputpointer	long
inputpointer	long
eorvalue	word
movePtr	long

               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

;	debug	'getoutlen'
;	lda	outputlength
;	ldx	outputlength+2
;	debug	'getoutptr'
;	lda	outputpointer
;	ldx	outputpointer+2
;	debug	'getinptr'
;	lda	inputpointer
;	ldx	inputpointer+2
;	debug	'geteorval'

	jsr	GetRingMemory

	lda	eorvalue
	xba
	ora	eorvalue
	sta	eorvalue

	SEC
	LDA	#0
	SBC	outputlength
	STA	outputlength
	LDA	#0
	SBC	outputlength+2
	STA	outputlength+2

	LDy	#RINGSIZE-MATCHMAX-1
	shortm
	lda	#0
zero	STa	[RingPtr],y 	;First fill the ring buffer
	DEy
	BPL	zero
	longm
	LDA	#RINGSIZE-MATCHMAX	;Set the index to the end of the buffer
	STA	RingIndex
	STZ	Flags	;Kill my flags

	bra	loop

exit	anop
	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	~DisposeHandle RingHandle
	lda	0,s
	sta	0+18,s
	lda	2,s
	sta	2+18,s
	tsc
	clc
	adc	#18
	tcs
	sec
	RTL		;EXIT whole routine

*
* Loop here
* Get a byte in flags to know if the next 8 samples are either
* words or bytes
*

loop	anop
	lda	[movePtr]
	bne	exit

	LSR	Flags	;Shift out a byte flag
	LDA	Flags
	BIT	#$100	;Empty?
	BNE	FLAGSOK
	JSR	GETBYTE	;Get new flags
	ORA	#$FF00	;Or in $FF for an 8 bit count
	STA	Flags	;Save

FLAGSOK	BIT	#1	;Is this a raw byte or a pack string?
	BEQ	DLZZ
	JSR	GETBYTE	;Get raw byte
	JSR	PUTBYTE	;Save it
	LDX	RingIndex	;Get ring buffer index
	phy
	txy
	shortm
;	STA	RingBuffer,X	;Save data in ring buffer
	STA	[RingPtr],y	;Save data in ring buffer
	longm
	ply
	INX		;Next index
	TXA
	AND	#RINGSIZE-1	;Keep in ring buffer!
	STA	RingIndex	;Save
	BRA	loop	;Get another char!

*
* Decompress from ring buffer
*

DLZZ	JSR	GETWORD	;Get count/index to buffer
	TAY		;Save word
	AND	#$FFF	;Mask index
	TAX		;Save as index to ring buffer
	TYA
	ROL	a	;Move upper 4 bits to lowest 4 bits
	ROL	a
	ROL   a
	ROL   a
	ROL   a
	AND	#$F	;Mask
	INC	a	;Add threshold (2)
	INC   a
	STA	SCREENAD
	LDY	RingIndex	;Get ring buffer index
loop2	anop
	phy
	txy
	LDA	[RingPtr],y	;Get char from buffer
;	LDA	RingBuffer,X	;Get char from buffer
	ply
	JSR	PUTBYTE	;Save in decompressed buffer
	shortm
	STA	[RingPtr],Y
	longm
	INY
	TYA
	AND	#RINGSIZE-1
	TAY
	INX		;Next index
	TXA
	AND	#RINGSIZE-1	;Keep in buffer
	TAX
	DEC	SCREENAD	;All bytes done?
	BPL	loop2	;Loop
	STY	RingIndex
	BRA	loop	;Keep decompressing!

*
* Save byte in finished buffer
*

PUTBYTE	shortm
	STA	[outputpointer]	;Save byte
	longm
	INC	outputpointer	;Inc pointer
	BNE	AA
	INC	outputpointer+2
AA	INC	outputlength	;Dec outputlength
	BNE	BB
	INC	outputlength+2
	BNE	BB
	PLA		;Kill JSR to abort

return	anop
	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	~DisposeHandle RingHandle

	lda	0,s
	sta	0+18,s
	lda	2,s
	sta	2+18,s
	tsc
	clc
	adc	#18
	tcs
	clc
	RTL		;EXIT whole routine

BB	RTS		;Exit

*
* Get a byte of packed data
*

GETBYTE	LDA	[inputpointer]	;Get byte
	eor	eorvalue
	AND	#$FF	;Mask
	INC	inputpointer	;Inc pointer
	BNE	Ab
	INC	inputpointer+2
Ab	RTS

*
* Get a word of packed data
*

GETWORD	LDA	[inputpointer]	;Get the word
	eor	eorvalue
	INC	inputpointer	;Inc pointer twice
	BNE	AAA
	INC	inputpointer+2
AAA	INC	inputpointer
	BNE	BBB
	INC	inputpointer+2
BBB	RTS		;Exit

;RingBuffer	DS	RINGSIZE	;Ring buffer

GetRingMemory	name

               LongResult
               PushLong #RINGSIZE
               lda   MyID
               ora   #miscAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
	bcc	Good
	plx
	plx
	sec
	rts
Good	lda	1,s
	sta	RingHandle
	lda	1+2,s
	sta	RingHandle+2
	jsr	makePdp
	pld
	PullLong RingPtr

;	ldy	#RINGSIZE-2
;	lda	#0
;zeroBuffers	sta	[RingPtr],y
;	dey
;	dey
;	bpl	zeroBuffers
	clc
	rts

RingHandle	ds	4

               End
*-----------------------------------------------------------------------------*
* ConcatenatePathStrings - combine 2 pathnames, the former a folder and the
*  latter a filename.  Adjust the number of delimters and everything.
*
* V1.00 - 1.0d37 - September 11, 1992 Jim R. Maricondo.
*
* dataIn - ptr to special structure:
*  +00 long folderpathptr - GS/OS C1InputString of folder pathname
*  +04 long filenameptr - GS/OS C1InputString of filename
*  +08 word memoryid - memory id to use to allocate new path handle
*  +10 eos
*
* filename can't have a leading delimiter - you've been warned!
*
* dataOut - ptr to:
*  +00 word count - count
*  +02 long newpathnamehandle - handle of new path name created
*
ConcatenatePathStrings Start
	kind  $1000	; no special memory
               Using RequestDATA
	Using InitDATA
	debug 'ConcatenatePathStrings'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

dp	equ	1
Filename	equ	dp+2
Pathname	equ	Filename+4

	ldy	#8
	lda	[dataIn],y
	sta	Id

	ldy	#2
	lda	[dataIn],y	; folder pathname
	pha
	lda	[dataIn]
	pha
	ldy	#6
	lda	[dataIn],y	; filename
	pha
	dey
	dey
	lda	[dataIn],y
	pha
	makeDP

	lda	[Pathname]	; get length word
	tay
	iny		; Y now is offset to last char
	lda	[Pathname],y	; get last character
	and	#$FF
	cmp	#":"
	bne	noEndDelimiter
	lda	[Pathname]
	sta	NewStrLength	
	bra	p1done

noEndDelimiter	anop
	lda	[Pathname]
	inc	a	; add one 'cuz we need to add a delim.
	sta	NewStrLength	
	
p1done	anop
	ldy	#2
	lda	[Filename],y	; get first char of filename
	and	#$FF
	cmp	#":"	; make sure it's not a delimiter
	bne	notDelimiter
	brk	$EA

notDelimiter	anop
	lda	[Filename]
	clc
	adc	NewStrLength
	inc	a
	inc	a	; add 2 for length word
	sta	NewStrLength
	pld

	LongResult
	PushWord #0
	PushWord NewStrLength
;	lda   MyID
;	ora   #pathBuffAuxID
;	pha
	PushWord Id
	PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	errorbrk $EB
;	bcc   HandleOK
;	brk	$EB
;HandleOK	anop
	lda	1,s
	sta	NewStrHandle
	lda	1+2,s
	sta	NewStrHandle+2
;	pld
	jsr	makePdp

dp2	equ	1
Resultname	equ	dp2+2
Filename2	equ	Resultname+4
Pathname2	equ	Filename2+4


	lda	[Pathname2]	; get length word
	tay
	iny		; Y now is offset to last char
	lda	[Pathname2],y	; get last character
	and	#$FF
	cmp	#":"
	bne	noEndDelimit
	lda	[Pathname2]
	inc	a
	inc	a	; +2 for length word
	sta	NewStrLength	

* copy whole pathname string, length word and all for now

	ldy	#0	;2
	shortm
more	lda	[Pathname2],y
	sta	[Resultname],y
	iny
	cpy	NewStrLength
	blt	more
	longm

;	lda	[Pathname2]	; copy length word
;	sta	[Resultname]

	bra	p2done

noEndDelimit	anop
	lda	[Pathname2]
;	inc	a	; add one 'cuz we need to add a delim.
	inc	a
	inc	a	; +2 for length word
	sta	NewStrLength	
	
	ldy	#2
	shortm
more2	lda	[Pathname2],y
	sta	[Resultname],y
	iny	
	cpy	NewStrLength
	blt	more2
	lda	#":"
	sta	[Resultname],y
	longm

	lda	[Pathname2]	; copy length word
	inc	a	; +1 for tailing delimiter
	sta	[Resultname]

	inc	NewStrLength	; +1 for added delimiter

p2done	anop

	lda	[Filename2]	; get length word
	clc
	adc	[Resultname]	; add to existing length word
	sta	[Resultname]

	lda	Resultname
	clc
	adc	NewStrLength
	sta	ResultName
	lda	Resultname+2
	adc	#0
	sta	Resultname+2	

	lda	[Filename2]
	sta	NewStrLength

	inc	Filename2
	inc	Filename2

	ldy	#0
	shortm
more3	lda	[Filename2],y
	sta	[Resultname],y
	iny
	cpy	NewStrLength
	blt	more3
	longm

	killLdp	; get rid of result ptr + dp
	plx
	plx
	plx
	plx

	lda	NewStrHandle
	ldy	#2
	sta	[dataOut],y
	iny
	iny
	lda	NewStrHandle+2
	sta	[dataOut],y

	rts

NewStrLength	ds	2
NewStrHandle	ds	4
Id	ds	2

	End
*-----------------------------------------------------------------------------*
* randomize_module - pick a new random module and make it current
*  while this does not check if random mode is on or off, if there is only
*  one saved pathname, it will always use it.
*
* V1.00 - 1.0d38 - September 27-8, 1992 Jim R. Maricondo.
* V1.01 - 1.0.1b3 - December 26, 1992 Jim R. Maricondo - error dataOut
*
* dataIn - reserved.
* dataOut - pointer to following structure:
*  +00 - word - receive count
*  +02 - word - errors (0 if none)
*  +04 - eos  - end of structure
*

randomize_module Start
	kind  $1000	; no special memory
	debug	'randomize_module'
	Using	InitDATA
	Using	RequestDATA
	Using	LoadDATA

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

;	dbrk	00

;* Find out if we're being called during boot or not.
;	_GetNameGS p_getName
;	lda	curName_textLen
;	beq	skipCursor1
;
;	~WaitCursor
;
skipCursor1	lda	ThisModuleNum
	sta	LastModuleNum

	jsr	UnloadOldModule	; unload the existing module
	bcs	skip

* Get a new ID and stuff it in [the init.]

               ~GetNewID #$A000         ; Get an ID to InitialLoad2 the modules
               pla                      ; with.
	sta	iModuleID

skip           anop

	~GetCurResourceFile
	~GetCurResourceApp

* Open the T2 preference file (Twilight.Setup).  If it's missing, create a new
* file for us.  How convenient.

               PushWord #reqOpenT2PrefFile
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
               PushLong #OpenPrefsDataOut ; dataOut
               _SendRequest
	bcs	PrefErr
	lda	PrefErrCode	
	beq	NoPrefErr
PrefErr	anop
	cmp	#fileBusy
	beq	alreadyOpen
break	anop
	dbrk	$ee
	stz	PrefErrCode
	bra	NoPrefErr

alreadyOpen	anop
	~SetCurResourceApp PrefRezAppID
	~SetCurResourceFile PrefRezFileID

NoPrefErr	anop

	~LoadResource #rT2String,#1
	bcc	countFound
	plx
	plx
	lda	#1
	sta	ThisModuleNum
	bra	noCount

countFound	jsr	makePdp
	lda	[3]
	killLdp
	sta	ThisModuleNum
	sta	NumRandModules

	~ReleaseResource #3,#rT2String,#1

noCount	anop

	lda	ThisModuleNum
	cmp	#1
	beq	onlyOne

findNew	anop
	LongResult
	jsl	random
	pha
	lda	ThisModuleNum
	pha
	_UDivide
	plx
	pla		; remainder
	inc	a
	cmp	LastModuleNum
	beq	findNew
	sta	ThisModuleNum

onlyOne	anop
	LongResult
	PushWord #rT2String
	PushWord #0
	lda	ThisModuleNum
	inc	a
	pha
	_LoadResource
	PullLong PathnameH

;	dbrk	02

               PushWord #reqLoadModule
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong PathnameH	; dataIn
	PushLong #errorDataOut	; dataOut
               _SendRequest
;	dbrk	03
;;;;;;;;;!	brk
	lda	loadErr
	beq	dontLoad
	ldy	#2
	sta	[dataOut],y
	bra	exitLM

dontLoad       anop

	PushWord #3
	PushWord #rT2String
	PushWord #0
	lda	ThisModuleNum
	inc	a
	pha
	_ReleaseResource

	lda	PrefErrCode
	bne	skipClose
	~CloseResourceFile PrefFileID
	errorbrk

skipClose	anop
	ldy	#2
	lda	#0
	sta	[dataOut],y

exitLM	_SetCurResourceApp
	_SetCurResourceFile

;	lda	curName_textLen
;	beq	skipCursor2
;	~InitCursor
skipCursor2	rts

BlankRtn       entry
               jml   >0	; address of loaded module patched in

PathnameH	ds	4
ThisModuleNum	ds	2
LastModuleNum	ds	2
TempPtr	ds	4

UnloadOldModule entry
	lda	BlankRtn+1
               sta   TempPtr            ; 0   1  2   3
	lda	BlankRtn+3
               and   #$00FF
               sta   TempPtr+2
	ora	TempPtr	; has a module been loaded yet?
	beq	return_fast	; if not, return and don't alloc newID!

	lda	ModuleFlags	; current module's flags word
	bit	#fInternal
	bne	skip_unload

	bit	#fLoadSetupBlank
	bne	skip_unload
	bit	#fLoadSetupBoot
	bne	unload_now

* if t2 volume is non-removable then skip unloading setup now - 1.0d38
* because it has already been unloaded right after blanking

	lda	nonremovableT2Vol
	bne	skip_unload

unload_now	anop
* Tell the old module to unload setup data NOW.

	ldy	#0
	phy
	phy		; reserved [T2Result]
               PushWord #UnloadSetupT2	; T2message = unload setup data
	phy
	phy		; reserved [T2data1]
	phy
;	PushWord iModuleID	; T2data2 (hi) = mem id for modl to use
	phy		; reserved [T2data2 (lo)]
               jsl   BlankRtn        	; run it
               plx
               plx                      ; T2result = reserved

skip_unload	anop

               WordResult               ; for SetHandleId
               PushWord #0              ; for SetHandleId (don't change id)
               ~FindHandle TempPtr
               _SetHandleId             ; get the id (legally!)
               pla
               cmp   MyID               ; If it's our ID, then it's the default
               bne   noskip             ; module, then DON'T dispose of it!
return_fast	sec		; don't allocate a new ID!
	rts

noskip	anop
* Set the module's static load segs as purgable, and discard dynamic segments.
* And delete ModuleID.

	WordResult
	lda	iModuleID
	pha
	PushWord #$0000
               _UserShutDown
               plx                      ; chuck memID
	clc
	rts

	End
*-----------------------------------------------------------------------------*
* removeT2 - Remove most traces of T2 from the system.
*
* V1.00 - v1.0.1b2 - December 6, 1992 - Jim R. Maricondo.
*         coded
* V1.01 - v1.0.1b2 - December 10, 1992 - Jim R. Maricondo
*         fixed bug where I forgot to remove the T2 toolpatches!
* v1.02 - v1.2d1 - 3 Jan 1994 - JRM
*         toolpatches now removed in CDev instead so warning alert can be
*         put up when patches can't be removed
*
* dataIn - reserved.
* dataOut - reserved.
*

removeT2	Start
	kind  $1000	; no special memory
	debug	'removeT2'
	Using	InitDATA
	Using	RequestDATA

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

* First remove the heartbeats..

               ~DelHeartBeat #SHR_beat
               ~DelHeartBeat #text_beat
               ~DelHeartBeat #control_beat

* Then get rid of the notifyproc (p8->gsos switch)

	_DelNotifyProcGS npParms

* Next take care of the runQ's.

               ~RemoveFromRunQ #BlankRunQ
               ~RemoveFromRunQ #NowBlankRunQ
               ~RemoveFromRunQ #NowUnBlankRunQ
	lda	cccpActive
	beq	not_active
	~RemoveFromRunQ #cccpRunQ
not_active	anop

* Unload the current module..  This also should delete ModuleID.

	jsr	UnloadOldModule

* Make sure our NDA is gone too (if installed.)
* (this will also dispose all memory with our xFxx ID (i.e. the coderesource)
* and delete the ID after disposing the DA)

;			; tell it to disposeall and deleteid
	mvw	#TRUE,disposeFill+1 ; (normally it won't)

;install	~SchAddTask #RemoveNDA
;	pla
;	beq	install	; installed ok

               PushWord #reqRemoveNDA
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
	phy
               phy		; dataOut (none)
               _SendRequest

* Remove our message from the messageCenter:

               ~MessageByName #FALSE,#MyMessage
         	plx                      ; pull the Message's ID
               pla                      ; into X

               PushWord #deleteMessage
               phx
               PushLong #0
               _MessageCenter	; get rid of it!

* The rest of the removal procedure will be accomplished by the RemoveNDA
* Scheduler task.  Mainly it will dispose our [code] memory and remove
* the T2 request procedure.  We can't do either here because it would be very
* very bad..

	rts

	End
*-----------------------------------------------------------------------------*
*-----------------------------------------------------------------------------*
* T2PrivGetProcs - return handles to the two 64k SHR memory buffers
*
* V1.00 - T2 v1.0.1b1 - October 24, 1992 Jim R. Maricondo.
* v1.10 - T2 v1.0.1b4 - January 17, 1993 Jim R. Maricondo
*    
* Return pointers to confidential T2 routines... Available pointer list: (-=to)
*  1: 00-04 = set_random_seed
*  2: 04-08 = random
*  3: 08-12 = setup_plot
*  4: 12-16 = get_pixel
*  5: 16-20 = set_pixel
*  6: 20-24 = getset_pixel
*
* dataIn -
* HI WORD:
*  start byte offset (see above) - must be multiple of 4!
*
* LO WORD:
*  end byte offset (see above) - must be multiple of 4!
*
* dataOut - pointer to structure
*  +00 - word - count
*  +02 - long - [x numLongs]
*  +06 - long - [example]
*  +10 - long - [example]
*  +2+NumLongs*4 - eos  - end of structure

privGetProcs	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'T2PrivGetProcs'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

;	lda	<dataIn+2
;	bne	exit
;	lda	<dataIn
;	cmp	#8
;	bne	exit

	lda	<dataIn+2	; get start offset
	cmp	#4*5+1	; greater than what we support?
	bge	exit	
;	lda	<dataIn	; get end offset
;	cmp	#4*6+1
;	bge	exit	; greater than what we support

	ldx	<dataIn+2	; start offset into proctbl
	ldy	#2	; start offset into dataout
copyProcs	lda	procs,x
	sta	[dataOut],y
	iny
	iny
	inx
	inx
	lda	procs,x
	sta	[dataOut],y
	iny
	iny
	inx
	inx
	cpx	#4*6+1	; past end of table?
	bge	exit	; yes, so stop
	cpx	<dataIn
	blt	copyProcs

exit	rts

procs	anop
	jml	set_random_seed
	jml	random
	jml	setup_plot
	jml	get_pixel
	jml	set_pixel
	jml	getset_pixel

	End
*-----------------------------------------------------------------------------*
* T2SetBuffers - return handles to the two 64k SHR memory buffers, etc
*
* V1.00 - T2 v1.0.1b3 - January 1, 1993 - Jim R. Maricondo.
*
* dataIn - pointer to structure
*  +00 - long - handle to E1 buffer ($8000 bytes). -1= use existing (no change)
*  +04 - long - handle to 01 buffer ($8000 bytes). -1= use existing (no change)
*  +08 - eos  - end of structure
*
* dataOut - reserved.

SetBuffers	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'SetBuffers'

	DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
dataOut        long
dataIn         long
request        word
result         word

	lda	[dataIn]	; change E1 buffer?
	cmp	#-1
	bne	changeE1
	ldy	#2
	lda	[dataIn],y
	cmp	#-1
	beq	noE1Change

changeE1	lda	[dataIn]
	sta	Screen1Hndl
	ldy	#2
	lda	[dataIn],y
	sta	Screen1Hndl+2

noE1Change	anop
	ldy	#4
	lda	[dataIn],y
	cmp	#-1
	bne	change01	
	iny
	iny
	lda	[dataIn],y
	cmp	#-1
	beq	no01Change

change01	ldy	#6
	lda	[dataIn],y
	sta	Screen2Hndl+2
	dey
	dey
	lda	[dataIn],y
	sta	Screen2Hndl

no01Change	anop
	rts

	End
*-----------------------------------------------------------------------------*

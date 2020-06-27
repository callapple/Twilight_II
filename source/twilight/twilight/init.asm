         setcom 80
	mcopy	init.mac
	copy  13:ainclude:e16.memory
	copy  13:ainclude:e16.control
	copy  13:ainclude:e16.quickdraw
	copy  13:ainclude:e16.gsos
	copy  13:ainclude:e16.resources
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.finder
	copy	13:ainclude:e16.misctool
	copy	13:ainclude:e16.adb
	copy	13:ainclude:e16.cccp
	keep  init
	copy	equates
         copy  TII.equ
	copy	v1.2.equ
	copy	debug.equ
*-----------------------------------------------------------------------------*
T2_InitSeg     Start
	kind  $1000	; no special memory
               Using InitDATA
               Using LoadDATA
               Using RequestDATA
               debug 'T2 InitSeg'

	copy	22:debug.asm

               php
               phb
               phk
               plb
               sta   MyID
               stx   iModuleID

	jsl	set_random_seed

* new, but only if we're being doubleclicked on from the finder
* and we weren't installed during boot..
	~GetNameGS p_getName
	lda	curName_textLen
	sta	bootVolNameTextLen
	beq	weAreBooting

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

weAreBooting	anop
* Get the full pathname of our resource fork.

               WordResult               ; for GetOpenFileRefNum
               ~GetCurResourceFile
               _GetOpenFileRefNum
               pla
               sta   pRefInfo_refNum
               _GetRefInfoGS pRefInfo

	jsr	MakeModulePath	; Setup normal module pathname.
	jsr	MakePrefPath	; Setup preference pathname.

* Load in the init rectlist

	WordResult
	lda	MyID
	ora	#miscAuxID
	pha		; for setHandleID
               ~LoadResource #rRectList,#T2_Init_RectList ; load in our rects
               ~DetachResource #rRectList,#T2_Init_RectList ; make the handle ours
	lda	1,s
	sta	RectHandle
	lda	1+2,s
	sta	RectHandle+2
	_SetHandleID
	plx

	PushLong RectHandle
	jsr	makePdp
	pld
	PullLong RectPtr


* Install our request procedure.

	~Int2Hex MyID,#RequestMemID,#4

               PushLong #RequestStr
               lda   MyID
               ora   #requestAuxID
               pha
               PushLong #iRequestProc
               _AcceptRequests




* Load in the pathname to look for the preferences under

	WordResult
	lda	MyID
	ora	#miscAuxID
	pha		; for setHandleID
               ~LoadResource #rWString,#Setup_Path ; load in setup path
               ~DetachResource #rWString,#Setup_Path ; make the handle ours
	lda	1,s
	sta	SetupPathHndl
	lda	1+2,s
	sta	SetupPathHndl+2
	_SetHandleID
	plx

	~HLock SetupPathHndl

	PushLong SetupPathHndl
	jsr	makePdp
	pld
	PullLong cfile	; filename

	lda	MyID
               ora   #miscAuxID
	sta	concatId

	mvl	ConfigPathPtr,cpath
	
	PushWord #reqConcatenate
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong #concatDataIn   ; dataIn
               PushLong #concatDataOut	; dataOut
               _SendRequest

	~DisposeHandle SetupPathHndl

	lda	concathandle+2
	sta	SetupPathHndl+2
	pha
	lda	concathandle
	sta	SetupPathHndl
	pha
	jsr	makePdp
	pld
	PullLong SetupPathPtr



	stz	PrefID

* Open/create pref file.

               PushWord #reqOpenT2PrefFile
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
               PushLong #OpenPrefDataOut ; dataOut (none)
               _SendRequest
	bcs	PrefError
	lda	PrefErrorCode	
	beq	NoPrefError

* If there is an error opening/creating the preffile, then deactivate.

PrefError	anop
	lda	#fT2Active
	trb	OptionsFlag
;	lda	curName_textLen
	lda	bootVolNameTextLen
	bne	notDuringBoot
	~SysBeep2 #sbAlertCaution
notDuringBoot  anop
	ldy	PrefErrorCode
	brl	notActive

NoPrefError	anop

* Find out if Twilight is active by checking the options saved preference.
* If it's not, then we can skip all of the memory stuff and skip installing
* the heartbeat task.

               WordResult               ; Get options word.
               PushLong #OptionsRez     ; Are we activated?
               PushWord #rT2ExtSetup1
               jsl   GetRezWord
	pla
	bcc	NoErr1
	lda	#0	; (all options 0)
NoErr1	anop
               sta   OptionsFlag
	lda	nonremovableT2Vol
	bne	yesItIs	; nonremovable, so allow random mode
	lda	#fRandomize
	trb	OptionsFlag	; clear randomize bit if removable
yesItIs	anop
	lda	OptionsFlag
	bit	#fT2Active
;               jeq   notActive          ; skip the allocations, etc
	bne	weBeActive
	ldy	#0	; no specific error
	brl	notActive

weBeActive	anop

* Load options2 word..

               WordResult               ; Get options2 word.
               PushLong #Options2Rez
               PushWord #rT2ExtSetup1
               jsl   GetRezWord
	pla
	bcc	NoErr0
	lda	#0	; (all options 0)
NoErr0	anop
               sta   Options2Flag
	bit	#fNewModulePath	; did the user request a different path?
	beq	normalPath

	~LoadResource #rWString,#T2_module_path
	bcc	loadOk2
	plx
	plx
	bra	normalPath

loadOk2	~DetachResource #rWString,#T2_module_path

	WordResult	; for SetHandleID
	lda	MyID
	ora	#miscAuxID
	pha
	lda	7,s	; handle..
	pha
	lda	7,s
	pha		
	_SetHandleID
	plx		; discard old memID

	lda	3,s	; duplicate handle again..
	pha
	lda	3,s
	pha		; sourceHandle
	PushLong #ModulePath_textLen
	LongResult
	lda	11,s	; duplicate handle again..
	pha
	lda	11,s
	pha
	_GetHandleSize
	_HandToPtr

	_DisposeHandle

normalPath	anop
* Get adb hardware version number..

	~ReadKeyMicroData #1,#adbVersion,#readVersionNum

* Load cool noblank cursor..

	WordResult
	lda	MyID
	ora	#miscAuxID
	pha		; for setHandleID
               ~LoadResource #rCursor,#NoBlank640Cursor
               ~DetachResource #rCursor,#NoBlank640Cursor
	lda	1,s
	sta	Cursor640Hndl
	lda	1+2,s
	sta	Cursor640Hndl+2
	_SetHandleID
	plx

	WordResult
	lda	MyID
	ora	#miscAuxID
	pha		; for setHandleID
               ~LoadResource #rCursor,#NoBlank320Cursor
               ~DetachResource #rCursor,#NoBlank320Cursor
	lda	1,s
	sta	Cursor320Hndl
	lda	1+2,s
	sta	Cursor320Hndl+2
	_SetHandleID
	plx

	PushLong Cursor320Hndl
	jsr	makePdp
	pld
	PullLong Cursor320Ptr

	PushLong Cursor640Hndl
	jsr	makePdp
	LongResult
	ldy	#2
	lda	[3]
	asl	a	; x2 for mask
	pha	
	lda	[3],y	; get width (words)
	asl	a	; x2 for width in bytes
	pha
	_Multiply
	ply
	plx
	iny
	iny
	iny
	iny
	sty	HotOffset
	lda	[3],y
	sta 	MaxHotY
	iny
	iny
	lda	[3],y
	sta 	MaxHotX
	pld
	PullLong Cursor640Ptr

* Get memory to store the screen in.  Movable memory block.

               LongResult
               PushLong #$8000
               lda   MyID
               ora   #bufferMemAuxID
               pha
               PushWord #attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
               PullLong Screen1Hndl	; normal buffer

	stz	Screen2Hndl
	stz	Screen2Hndl+2

	lda	Options2Flag
	bit	#fLowMemoryMode
	bne	skipShadowMalloc

               LongResult
               PushLong #$8000
               lda   MyID
               ora   #bufferMemAuxID
               pha
               PushWord #attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
               PullLong Screen2Hndl	; shadow buffer

skipShadowMalloc anop

* Get memory to store palette1/scbs in.  Movable memory block.
               
               LongResult
               PushLong #$200
               lda   MyID
               ora   #bufferMemAuxID
               pha
               PushWord #attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
               PullLong NowHndl

* Load options..

               WordResult               ; Get swap delay. (Seconds)
               PushLong #SwapTimeRez
               PushWord #rT2ExtSetup1
               jsl   GetRezWord
	pla
	bcc	NoErr20
	lda	#120	; 2 minute default
NoErr20	anop
               sta	SwapDelay

               WordResult               ; Get blank delay. (minutes * 120)
               PushLong #TimeRez
               PushWord #rT2ExtSetup1
               jsl   GetRezWord
	pla
	bcc	NoErr2
	lda	#720*2	; 12 minutes (whY??????)
NoErr2	anop
               sta	BlankWait

               WordResult
               PushLong #CornersRez
               PushWord #rT2ExtSetup1
               jsl   GetRezWord
	pla
	bcc	NoErr5
	lda	#0	; everything OFF
NoErr5	anop
               sta	CornersFlag

* If we're inactive, then don't post the message or requestProc.

;               lda   OptionsFlag
;	bit	#fT2Active
;               jeq   abort

               jsr   loadModule         ; Load the selected module.
	bcc	loadOk

* If there was an error loading (an error in reqRandomize or reqLoadModule)
* which could be because the module pathname is invalid, then remove ourselves
* cleanly and exit with T2 removed from the system.

               lda   MyID
               ora   #bufferMemAuxID
               pha
	_DisposeAll
               lda   MyID
               ora   #miscAuxID
               pha
	_DisposeAll
	brl	PrefError	; go beep!

loadOk	anop
	jsl	DisPatch	; install our tool dispatcher patches

* Post our vital message to the messageCenter.

               ~MessageByName #TRUE,#MyMessage
               pla
               pla

	~CloseResourceFile PrefID ; Close the Twilight.Setup file.
	errorbrk

               ~SetHeartBeat #SHR_beat ; Add blank check proc heartbeat.
               ~SetHeartBeat #text_beat
               ~SetHeartBeat #control_beat

	_AddNotifyProcGS npParms
	errorbrk

;	dbrk	$55	; tmp

	stz	addSchTask
	~SchAddTask #addRunQs
	pla
	bne	schTaskGood
	lda	#1	; need to add addRunQ scheduler task
	tsb	addSchTask
schTaskGood	stz	InstalledNDA

	PushLong #T2_NDA	; source (for ptrtohand)
               LongResult
               PushLong #nda_end-t2_nda
               lda   MyID
               ora   #ndaAuxID
               pha
               PushWord #attrNoSpec+attrNoCross+attrLocked
               phd
               phd
               _NewHandle
	lda	1,s
	sta	NDAHandle
	lda	1+2,s
	sta	NDAHandle+2
	PushLong #nda_end-t2_nda
	_PtrToHand

	lda	OptionsFlag
	bit	#fInstallNDA
	beq	nda_done

               PushWord #reqInstallNDA
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

	ldy	#0	; no errors
nda_done	anop
               lda   OptionsFlag
;abort	anop
	plb
               plp
               rtl

addRunQs	ename
	phb
	phk
	plb
               ~AddToRunQ #BlankRunQ
               ~AddToRunQ #NowBlankRunQ
               ~AddToRunQ #NowUnBlankRunQ

;	lda	#FALSE
	stz	cccpActive

               PushWord #cccpAreYouThere
               PushWord #stopAfterOne+sendToName
	PushLong #cccpStr
               ldy   #$0000
               phy
               phy                      ; dataIn (none)
               PushLong #cccpThereOut	; dataOut
               _SendRequest
	bcs	no_cccp
	lda	cccpRecvCount
	beq	no_cccp

	mvw	#TRUE,cccpActive
               ~AddToRunQ #cccpRunQ

no_cccp	anop
	plb
	rtl

cccpThereOut	anop
cccpRecvCount	ds	2	; recvCount
cccpID	ds	2	; memID of cccp
cccpVersion	ds	4	; version of cccp

****************************************
notActive      name
	phy		; save error code
	lda	PrefID
	beq	setupNeverOpened
	~CloseResourceFile PrefID ; make sure twilight.setup is closed
	errorbrk

setupNeverOpened anop

* remove our request procedure

	ldy	#$0000
	phy
	phy		; nameString
               lda   MyID
               ora   #requestAuxID
               pha		; userID
	phy
	phy		; requestProc (remove procedure)
               _AcceptRequests

* dipose handles we allocated

	~DisposeHandle RectHandle
	~DisposeHandle concathandle
	ply		; restore error code
	brl	nda_done

               End
*-----------------------------------------------------------------------------*
	copy	dispatch.asm	; tool dispatcher patch code
*-----------------------------------------------------------------------------*
loadModule     Start
	kind  $1000	; no special memory
               Using InitDATA
	Using LoadDATA
               debug 'loadModule'

* load in the module's path
;	~RMLoadNamedResource #rWString,#Module_Path
;               PullLong PathHandle

*	~LoadResource #rT2String,#2
*	PullLong PathHandle
*
*               PushWord #reqLoadModule
*               PushWord #stopAfterOne+sendToUserID
*               ldy   #$0000
*               phy                      ; target (hi)
*               lda   MyID
*               ora   #requestAuxID
*               pha                      ; target (lo)
*               PushLong PathHandle	; dataIn
*	phy
*	phy		; dataOut (none)
*               _SendRequest
*
*	~ReleaseResource #3,#rT2String,#2

               PushWord #reqRandomize
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
	PushLong #randomDataOut	; dataOut
               _SendRequest
	lda	randomErr
	beq	noErr
	sec
	rts

;	PushWord #3	; purge level 3
;	PushWord #rWString	; rtype
;	~RMFindNamedResource #rWString,#Module_Path,#TempWord ; rID
;	_ReleaseResource
noErr	clc
	rts

               End
*-----------------------------------------------------------------------------*
LoadDATA       Data
               Using InitDATA
               debug 'LoadDATA'

* Usually set to ":Jim1:System:CDevs:", this contains the pathname where we
* will write Twilight.Data and Twilight.Setup!
* Must be same size as iNameBuffer!
SavePath	C1Result 256

ModulePath     C1Result 256             ; Full pathname of module folder
FolderStrPtr   ptr   0
FolderStrLen   ds    2

PathHandle     handle

pRefInfo       RefInfoRecGS (0,0,iNameBuffer)
iNameBuffer    C1Result 256
iNameEnd       anop

* For setting up the preferences path and finding out the characteristics
* of the device twilight ii is located on.

pVolume	VolumeRecGS (bootDevName_textLen,curName,0,0,0,0,0,0)
pGetUserPath	GetUserPathRec (appleShareFSID,8,0)

pGetDevNumber	DevNumRecGS (ModulePath_textLen,0)
pDInfo	DInfoRecGS (0,bootDevName,0,0,0,0,0,0)
bootDevName	C1Result 40

* for getting our name

p_getName	GetNameRecGS curName
curName	C1Result MaxFSTLen
bootVolNameTextLen ds 2

               End
*-----------------------------------------------------------------------------*
InitDATA	Data
               Using LoadDATA
               debug 'InitDATA'

* swapdelay must be immediately after blankwait!

TempWord	ds	2	; temporary variable
BlankWait      ds    2                  ; time to wait before blanking (12=s)
SwapDelay	ds	2	; seconds before swapping modules..
BlankTimer     ds    2                  ; This is the counter itself
BlankFlag      boolean TRUE             ; boolean: we should blank
;			; TRUE = unblank. FALSE = stay as is.

* OptionsFlag Format:  (14 June 1992 - v1.0d34 - JRM)
* ___ __________            _ _____________ ____
* BIT ALLOCATION            | DEFAULT/VALID BITS
*                           |
* bit 0: T2Active           | 1 (default) - on, 0 - off
* bit 1: BlinkingBox        | 1 (default) - on, 0 - off
* bit 2: CapsLockLock       | 1 - on, 0 (default) - off
* bit 3: WarningAlerts      | 1 (default) - on, 0 - off
* bit 4: installNDA         | 1 (default) - yes, 0 - no
* bit 5: randomize          | 1 - on, 0 (default) - off
* bit 6: LetMouseRestore    | 1 (default) - yes, 0 - no
* bit 7: noSound            | 1 - no sound, 0 (default) - sound
* bits 8-9: watchBkgBlank   | 00 (default)
*           watchDontBlank  | 01                  _11 is illegal!_
*           watchNormBlank  | 10
* bits 10-11: dclickpreview | 00 (default)
*             dclickclose   | 01
*             dclicksetup   | 10
*             dclickignore  | 11
* bits 12-13: textBkgBlank  | 00 (default)
*             textGSOSBlank | 01                  _11 is illegal!_
*             textDontBlank | 10
* bit 14: sysBeepsUnblank   | 1 (default) - yes, 0 - no
* bit 15: useIntelliKey     | 1 (default) - yes, 0 - no
*
* Options2Flag Format:
* ___ __________            _ _____________ ____
* BIT ALLOCATION            | DEFAULT/VALID BITS
*                           |
* bit 0: fLowMemoryMode     | 1 - on, 0 (default) - off
* bit 1: fSHRCorners        | 1 - on, 0 (default) - off
* bit 2: fSwapModules       | 1 - on, 0 (default) - off
* bit 3: fPassword	       | 1 - on, 0 (default) - off
* bit 4: fNewModulePath     | 1 - on, 0 (default) - off
*                           ~
* See 'equates' for bit equates for these flags..

OptionsFlag    ds	2                  ; options flag word
Options2Flag	ds	2	; options2 flag (must be after optflg)

* CornersFlag Format:  (12 June 1992 - v1.0d34 - JRM)
* ___ __________               _____ ____                   _______ ______
* BIT ALLOCATION               VALID BITS                   DEFAULT VALUES
*
* bits 0, 1, 2: top left     | 000 - off                  | 000 (off)
* bits 3, 4, 5: bottom left  | 001 - don't blank          | 010 (bkg blank now)
* bits 6, 7, 8: top right    | 010 - background blank now | 011 (blank now)
* bits 9, A, B: bottom right | 011 - foreground blank now | 001 (don't blank)
*

CornersFlag	ds	2	; status of all corners

MyMessage      anop
               dc    i'MessageEnd-MyMessage'
*              str  'Digital Youth Alliance: Twilight II'
*              str  'Jim Maricondo: Twilight II'
*              str  'DYA: Twilight II'
*              str  'DYA (JRM): Twilight II'
*	str	'Digital Creations: Twilight II (JRM)'
               str  'DigiSoft Innovations: Twilight II (DYA)'
               ptr   BlankRtn           ; Pointer to the blanker entry point
MyID	ds    2
;ModuleIDPtr	ptr   iModuleID	; pointer to module memory Id
               ptr   ModulePath_textLen ; Ptr to full GS path of module folder
               ptr   iNameBuffer_textLen ; Ptr to our full pathname & filename.
               ptr   DefaultB
               dc    h'5c'              ; jmp long
               dc    a3'GetRezWord'
ConfigPathPtr	ptr   0
	dc	i4'ModuleFlags'
nonremovableT2Vol ds	2
	ptr	PrefRezFileID	; ptr to rezFileID and rezAppID of pref
	ptr	OptionsFlag
	ptr	CornersFlag
	ptr	iTE_dp_handle
	ptr	BlankWait	; delay time (180 = 1min)
	ptr	IgnMouseTime	; ignore mouse time (2 = 1sec)
	ptr	OnFlag	; t2 currently on/off
               dc    h'5c'              ; jmp long
               dc    a3'RemoveIt'
MessageEnd     anop

Screen1Hndl	handle                   ; Handle to SHR screen buff ($8000)
Screen2Hndl	handle	; handle to shadow screen buff ($8000)
NowHndl        handle                   ; Handle to palettes (size=$200)

ImmediateBkgBlank dc	i'FALSE'

iModuleID      ds    2                  ; ID for InitialLoad2ing the modules
ModuleFlags	ds	2

IgnMouseTime	ds	2

iTE_dp_handle	ds	4

NewY           ds    2                  ; New and old mouse X & Y positions
NewX           ds    2
OldX           dc    i'0'
OldY           dc    i'0'
OldKey         ds    2
NewKey         ds    2
ButStat        ds    2

OldBorder      ds    1                  ; Old border color
OldText        ds    1                  ; Old text color
TxtClrFlag	ds    2
OnFlag         dc    i'$FF'
* ipcT2Off MUST be immediately after OnFlag right here!!!!!
ipcT2Off	boolean FALSE	; 0 = T2 is on, 1 = T2 is off
TempTurnOff	ds	2	; turn off T2 temporarily...
BlinkFlag      boolean FALSE            ; boolean: blinking menubox on
BlinkBord      ds    1
BoxOverride	boolean FALSE

NowCount       ds    2
NowFlag        boolean TRUE             ; boolean: blank NOW

* Used to prevent the text screen from blanking for a period of time, like
* when quitting from P8 to GS/OS - lockout time is in 5/60ths of a second.

DontTextBlankDelay ds 2	; boolean: force restore text scrn NOW

* Used to reinstall our heartbeat, in case it was removed under P8 when someone
* hit Ctl-Reset (MTReset).

NPParms	NotifyRecGS NotifyProc

* DataOut structure to get the rezfile ID of the preference rezFile.

OpenPrefDataOut anop		; DataOut (for sendRequest)
               ds    2                  ; count
PrefID         ds    2                  ; rezFile id of pref rezFile
PrefErrorCode	ds	2	; error code (if applicable)

RectHandle	handle
RectPtr	      ptr   0
SetupPathHndl	handle
SetupPathPtr	ptr   0

* Current mouse clamp values

YMax	ds	2
YMin	ds	2
XMax	ds	2
XMin	ds	2

* resource names

;Module_Path	str	'T2 Module Path'

* datain for blank_screen (init)

BlankScreenDataIn anop
* This first flag signifies that we're not calling blank_screen from the "blank
* now" control.  It means to play the SysBeep2's, don't always call LoadSetupT2
* and UnloadSetupT2, and also pass a flag to the module telling it that we're
* not calling it from "blank now".
	dc	i'FALSE'	; blankNowFlag
ModuleMemID	ds	2
ModuleFlgs	ds	2
ModuleEntryPt	ds	4
PrefRezFileID	ds	2
PrefRezAppID	ds	2
* Result from LoadSetupT2 call.  See "equates" for bit defines.
LSResult	ds	4

NDAHandle	ds	4
InstalledNDA	ds	2

kbdChangedFlg	ds	2

quickStatus	ds	2
eventStatus	ds	2
menuStatus	ds	2


Cursor320Hndl	ds	4
Cursor640Hndl	ds	4


* This stuff returned by T2GetInfo...(ipc request) *ROJAC '93*

GetInfoBuffer	anop
statusword	ds	2	; state word
NumRandModules	ds	2	; number of currently selected modules
	dc	i'T2Version'	; Twilight II version (1.2 delta)
Cursor320Ptr	ds	4
Cursor640Ptr	ds	4
GetInfoBufferEnd anop

MaxHotX	ds	2
MaxHotY	ds	2
HotOffset	ds	2


* concat stuff

concatDataIn	anop
cpath	dc	i4'0'
cfile	dc	i4'0'
concatId	ds	2

concatDataOut	anop
	ds	2	; count
concathandle	ds	4	; new pathhndl

* DataOut for reqRandomize

randomDataOut	anop
	ds	2	; count
randomErr	ds	2	; error code (0 if none)

* Flag word passed to modules at loadsetupT2 time...
* mfOverrideSound = $0001 = bit 0. 1=override sound, 0=sound ok

LSFlags	dc	i'0'	; flag word for loadsetupt2

* misc

addSchTask	ds	2	; which scheduler tasks we need to add
adbVersion	ds	2	; version of adb firmware
BeepOverride	dc	i'FALSE'
swap_count	dc	i'0'	; module swapping timer. 2 = 1 second
SwapNow	dc	i'FALSE'	; module swap needed? (after timer runs out, this is set)

* should we force a bkg blank? (ipc)

ForceBkgFlag	dc	i'FALSE'	; initially, do not.

* screenSaverAware stuff (T2 v1.0.1b4)

ssaStr	str	'ScreenSaverAware~'

ssaDataOut	anop
ssaCount	ds	2
ssaReturnFlag	ds	2

* Bank 01 screen handle that we try to keep allocated all the time, but
* purgable so that programs and data don't get loaded into 01 SHR..

bankOneH	handle


* for cccp stuff

cccpStr	str	'EGO Systems~Cool Cursor~'
cccpActive	dc	i'FALSE'

cccpCursorOut	anop
	ds	2	; recvCount
cccpCursorType	ds	2	

* $0000 cccpPointer	Cursor is the pointer (arrow) cursor
* $0001 cccpWait	Cursor is the watch cursor or currently animating
* $0002 cccpIBeam	Cursor is the I-Beam cursor
* $0003 cccpCustom	Cursor is animating because of the cccpAnimateCursor request
* $0004 cccpOther	Cursor is an unknown application-specific cursor

               End
*-----------------------------------------------------------------------------*
* CheckSHRCorner - V1.1 January 1992 by JRM.
*
* Inputs:
*  Accumulator - corner to check
*     1 = UL
*     2 = UR
*     3 = LR
*     4 = LL
*  NewY - point to check
*
* Outputs:
*  Accumulator - boolean - point in rect.
*
* 320/640 mode is taken into account (1st SCB @ $E19D00 is checked)
*

CheckSHRCorner	Start
	kind  $1000	; no special memory
	Using InitDATA
	debug 'CheckSHRCorner'

               cmp   #$0001
               bne   notUL
	lda	RectPtr
	clc
	adc	#(oULRect*8)+2
               bra   CheckRect

notUL          cmp   #$0004
               bne   notLL
	lda	RectPtr
	clc
	adc	#(oLLRect*8)+2
               bra   CheckRect

notLL          tax
               lda   >$E19D00           ; SCB for line 0
               bit   #mode640
               bne   its640

its320         cpx   #$0002
               bne   notUR320
	lda	RectPtr
	clc
	adc	#(oURRect320*8)+2
               bra   CheckRect

notUR320       anop
	lda	RectPtr
	clc
	adc	#(oLRRect320*8)+2
               bra   CheckRect

its640         cpx   #$0002
               bne   notUR640
	lda	RectPtr
	clc
	adc	#(oURRect640*8)+2
               bra   CheckRect

notUR640       anop
	lda	RectPtr
	clc
	adc	#(oLRRect640*8)+2

CheckRect	anop
	ldy	RectPtr+2
	phy		; rect ptr (hi)
	pha

	makeDP
oldDPR	equ	1
rect	equ	oldDPR+2
; point	equ	rect+4

* I ripped this code out of ROM03 (@220F) to minimize overhead

;	lda	[point]	; get top
	lda	NewY
	cmp	[rect]	; cmp top of rect.
	bmi	falso	; point is left of (before) rect
	ldy	#4
	cmp	[rect],y	; cmp bottom of rect
	bpl	falso	; point is past (too far to right) rect
	dey
	dey
;	lda	[point],y	; get left
	lda	NewX
	cmp	[rect],y	; cmp left of rect
	bmi	falso	; before it
	ldy	#6
	cmp	[rect],y	; cmp right of rect
	bpl	falso	; past it
	lda	#TRUE
	bra	return
falso	lda	#FALSE
return	anop
	killLdp
	rts

*220F: A7 0B       LDA [point]
*2211: C7 07       CMP [rect]
*2213: 30 1E       BMI 2233 {
*2215: A0 04 00    LDY #0004
*2218: D7 07       CMP [rect],Y
*221A: 10 17       BPL 2233 {
*221C: 88          DEY
*221D: 88          DEY
*221E: B7 0B       LDA [point],Y
*2220: D7 07       CMP [rect],Y
*2222: 30 0F       BMI 2233 {
*2224: A0 06 00    LDY #0006
*2227: D7 07       CMP [rect],Y
*2229: 10 08       BPL 2233 {
*222B: A9 FF FF    LDA #FFFF
*222E: 85 0F       STA 0F
*2230: 4C 3A FC    JMP FC3A

	End	
*-----------------------------------------------------------------------------*
* DefaultB.  V1.00 - 11/29/91 by Jim R Maricondo.
*                    Initial version.
*            V2.00 - 05/07/92 by Jim R Maricondo.
*                    Updated for Generation 2 Module Format. (v1.0d31)
* 
* Default blanker used when no modules can be found in the Twilight folder,
* or the module path configuration resource in Twilight.Setup is empty or
* invalid.
*
* Inputs:
*
* |previous contents|
* |-----------------|
* |    T2Result     |  Long - Result space.  (currently reserved)
* |-----------------|
* |    T2Message    |  Word - Action to perform.
* |-----------------|
* |     T2data1     |  Long - Action specific input.
* |-----------------|
* |     T2data2     |  Long - Action specific input.
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*
* Outputs:
*
* |previous contents|
* |-----------------|
* |    T2Result     |  Long - Result space.  (reserved at this time)
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*

DefaultB       Start
	kind  $1000	; no special memory
               debug 'DefaultB'

	DefineStack
dpageptr       word
dbank          byte
rtlAddr	block	3
T2data2	long
T2data1	long
T2message	word
T2result	long

               phb
               phd
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#BlankT2
	bne	notSupported

               lda   CLOCKCTL
               and   #$FFF0
               sta   CLOCKCTL

               lda   #0
               ldx   #$200-2
nextBlank      sta   SHR+$7E00,x
               dex
               dex
               bpl   nextBlank

again          lda   [T2data1]	; movePtr
               beq   again

notSupported   anop
               pld
               plb
               lda   1,s
               sta   1+10,s
               lda   2,s
               sta   2+10,s
               tsc
               clc
               adc   #10
               tcs
               clc
               rtl

               End
*-----------------------------------------------------------------------------*
* GetRezWord.  V1.00 - 11/29/91 by JRM.
*
* Get the first word of any resource.
*
* Inputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |      Space      |  Word - space for result
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
* |      value      |  Word - First 2 bytes of resource specified.
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*

GetRezWord     Start
	kind  $1000	; no special memory
               debug 'GetRezWord'

               DefineStack
dpageptr       word
dbank          byte
retaddr        block 3
rezType        word
rezID          long
result         word

               phb
               phd

               lda   rezID,s
               tay
               lda   rezID+2,s
               tax
               lda   rezType,s

               LongResult
               pha
               phx
               phy
               _LoadResource
               bcc   noError
               jsr   makePdp
               lda   #0
               killLdp
               sta   result,s
               pld
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

noError        jsr   makePdp
               lda   [3]
               killLdp
               sta   result,s

               lda   rezID,s
               tay
               lda   rezID+2,s
               tax
               lda   rezType,s

               PushWord #3              ; And release it now that we know what
               pha                      ; it is.
               phx
               phy
               _ReleaseResource

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
	kind  $1000	; no special memory
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
MakePrefPath	Start
	kind  $1000	; no special memory
               Using InitDATA
               Using LoadDATA
               Using RequestDATA
	debug 'MakePrefPath'

	_GetDevNumberGS pGetDevNumber

	lda	pGetDevNumber_devNum
	sta	pDInfo_devNum

	_DInfoGS pDInfo

	_VolumeGS pVolume

* setup nonremovableT2Vol boolean flag.
* if the volume containing t2 is either nonremovable or a removable SCSI hard
* disk then set the flag to equal TRUE.  else set it to false.
* the flag will be used to know when to load setup, and to know if random
* mode should be enabled or not.

;!	lda	#FALSE	; start out removable
;	stz	nonremovableT2Vol
;
;	lda	pVolume_characteristics
;	bit	#$0004	; removable media?
;	bne	removable
;	sta	nonremovableT2Vol	; save that t2 vol is not removable
;	bra	done
;
;removable	anop
;	lda	pVolume_deviceID
;	cmp	#5	; SCSI hard disk
;	bne	real_removable
;	sta	nonremovableT2Vol	; save that t2 vol is not removable

	mvw	#TRUE,nonremovableT2Vol	; TEMPORARY HACK!!

done	anop
real_removable	anop
;	lda	pVolume_deviceID
;	sta	t2VolDevID

* Setup preferences path.

	lda	pVolume_fileSysID
               cmp	#appleShareFSID
               beq	GoAShare

AShareError	anop
	mvl	#SavePath_textLen,ConfigPathPtr
               bra	ConfigPathDone

GoAShare	anop
	_FSTSpecific pGetUserPath
               bcs	AShareError

	mvl	pGetUserPath_prefixPtr,ConfigPathPtr
ConfigPathDone	anop
	rts

               End
*-----------------------------------------------------------------------------*
MakeModulePath	Start
	kind  $1000	; no special memory
               Using InitDATA
               Using LoadDATA
               Using RequestDATA
	debug 'MakeModulePath'

* Load in the filename of the folder to look for modules in.

               ~LoadResource #rWString,#Module_Folder ; load in module folder
               jsr   makePdp
               lda   [3]                ; get length word
               sta   FolderStrLen
               pld
               PullLong FolderStrPtr

* Take the pathname of our resource fork, and strip off all the characters
* past the last delimiter, then append the W-String in the Module_Folder 
* configuration resource to get the full pathname
* of the folder where we will look for modules from (put in the message).
* I.E. Given ":Jim1:System:CDevs:Twilight.II", it first will be stripped down
* to ":Jim1:System:CDevs:", then it will become ":Jim1:System:CDevs:Twilight",
* IFF Module_Folder is still the default W-String of "Twilight".

* At the same time, setup SavePath, which will be ":Jim1:System:CDevs:"

               ldx   #iNameEnd-iNameBuffer-2
CopyT2Path     lda   iNameBuffer,x
               sta   ModulePath,x
	sta	SavePath,x
               dex
               dex
               bpl   CopyT2Path

               lda   ModulePath_textLen ; get length word
               dec   a                  ; make it offset to last char in str
               tax
               shortm
CheckNextChar  lda   ModulePath_text,x
               and   #$7F
               msb   off
               cmp   #":"
               beq   FoundLastSep
               dex
               bra   CheckNextChar

FoundLastSep   anop
               inx
               stx   ModulePath_textLen
	stx	SavePath_textLen

               longm
               PushLong FolderStrPtr
               makeDP
               inc   <3
               inc   <3                 ; +2 to skip length word
               shortm
               ldy   #0                 ; init offset into folder name
CopyFolderStr  lda   [3],y              ;T2GSStr+2,y
               sta   ModulePath_text,x
               inc   ModulePath_textLen
               inx
               iny
               cpy   FolderStrLen
               bne   copyFolderStr
               longm
               killLdp

               ~ReleaseResource #3,#rWString,#Module_Folder ; release folder rez
	rts

	End	
*-----------------------------------------------------------------------------*
NotifyProc     Start
	Using	InitDATA

               ds    4                  ; Reserved (link to next task in queue)
               ds    2                  ; Reserved
               dc    i'$A55A'           ; signature
               dc    i4'%110'           ; event_flags, 2: P8 -> GSOS & 1: vice versa
Event_code     ds    4

Proc_Entry     anop
               php

               longmx

	lda	>Event_code
	cmp	#%10
	beq	gsos2p8
	cmp	#%100
	beq	p82gsos
	dbrk	$EF
	bra	exit_np

p82gsos	name
               ~DelHeartBeat #SHR_beat
               ~DelHeartBeat #text_beat
               ~DelHeartBeat #control_beat
               ~SetHeartBeat #SHR_beat
               ~SetHeartBeat #text_beat
               ~SetHeartBeat #control_beat
	bra	exit_np

gsos2p8	name
	mvw	#15*2,>TempTurnOff	; 15 seconds

exit_np	plp
               clc
               rtl

               END
*-----------------------------------------------------------------------------*
T2_NDA	Start

; implement: doClose!

               dc    i4'doOpenNDA'	; open routine	
               dc    i4'doNothingNDA'	; close routine
               dc    i4'doNothingNDA'	; action routine
               dc    i4'doNothingNDA'	; init routine
               dc    i2'$FFFF'          ; period
               dc    i2'$FFFF'          ; event mask
NDATitleStr	dc    c'##T2\H'
	dc	c'**'
               dc    h'00'
NDA_end	entry

               End
*-----------------------------------------------------------------------------*
doNothingNDA	Start
	debug	'doNothingNDA'

               rtl

               End
*-----------------------------------------------------------------------------*
doOpenNDA	Start
	Using	LoadDATA
	debug	'doOpenNDA'

               phb
               phk
               plb

	jsr	callCDev

               lda   #$0000
               sta   7,s
               sta   5,s

               plb
               rtl


callCDev	entry
	debug	'callCdev'

               _WaitCursor
;               lda   reqInstalledFlg
;               beq   exit

	PushWord #finderSaysBeforeOpen ;$9000	; cpOpenCDev
	PushWord #stopAfterOne+sendToName
	PushLong #toString
	PushLong #dataIn
	PushLong #0
	_SendRequest
;	~SendRequest #$9000,#stopAfterOne+sendToName,#toString,#dataIn,#0

;exit	anop	
               _InitCursor
	rts

toString       str	'Apple~Control Panel~'
dataIn         dc    i2'$0007'          ; pcount
               ptr   iNameBuffer_textLen ; Ptr to our full C1I pathname.
               dc    i4'$00000000'      ; ptr to rect to zoom out from
               dc    i2'$00C7'          ; filetype
               dc    i4'$00000000'      ; auxtype
               dc    i2'$0000'          ; modifiers
	dc	i4'$00000000'	; icon object
	dc	i2'$0000'	; print flag (0 = open)
                            
               End
*-----------------------------------------------------------------------------*

	
	mcopy	phantom.mac
	keep	phantom.d
	copy	22:t2common.equ
;	copy	22:dsdb.equ
	copy	2:ainclude:e16.control
	copy	2:ainclude:e16.memory
	copy	2:ainclude:e16.resources
	copy	2:ainclude:e16.types	
	copy	2:ainclude:e16.gsos
	copy	2:ainclude:e16.window
	copy	2:ainclude:e16.locator
*-----------------------------------------------------------------------------*
* Inputs:
*
* |previous contents|
* |-----------------|
* |    T2Result     |  Long - Result space.
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
* |    T2Result     |  Long - Result space.
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*
*-----------------------------------------------------------------------------*
debugSymbols	gequ	$F
debugBreaks	gequ	$C
debugCode	gequ	TRUE

effectPathStrCtl gequ 4

* constants
PLAY	gequ	1
STOP	gequ	2
DEMO	gequ	3
CONFIGURE	gequ	4
DEMOLIMIT	gequ	200

movePtr	gequ	<0

* Resources, ids, etc within T2..
AlertUnknownError GEQU $07FEFFFD
T2SetupUpdateCtlID gequ $07FEFFFE	; save control in setup window
*-----------------------------------------------------------------------------*
phantom	Start
	kind  $1000	; no special memory
	debug	'phantom'
	Using	MainDATA

	DefineStack
dpageptr       word
dbank          byte
rtlAddr	block	3
T2data2	long
T2data1	long
T2message	word
T2result	long

               phb
	phk
	plb
               phd
	tdc
	sta	OurDP
               tsc
               tcd

               lda   <T2Message	; Get which setup procedure to call.
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (T2Actions,x)	; JSR to the appropriate action handler

notSupported   anop
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
doBlank	Start
;	brk
	Using	MainDATA
	debug	'doBlank'

	DefineStack
dpr	word
rtsAddr	word
dpageptr	word
dbank          byte
rtlAddr	block	3
T2data2	long
T2data1	long
T2message	word
T2result	long

	phd
	lda	OurDP
	tcd

	lda	T2data1,s
	sta	movePtr	;save this in our own DP
	sta	movement+1
	lda	T2data1+2,s
	sta	movePtr+2
	shortm
	sta	movement+3
	longm

	lda	ErrorMsg
	jne	ErrorMaker

	jsl	DisPatch

	lda	#PLAY
	jsr	Phantasm

	jsl	RemoveIt

	pld
	rts

	End
*-----------------------------------------------------------------------------*
Phantasm	Start
	debug	'Phantasm'
	Using	MainDATA

	sta	>action+1

	phb		;save everything in case the blanker does
	phd		;something it's not supposed to.
	php

	shortm
	lda	>EntryPt+3
	pha
	plb
	longm

action	PushWord #0	; action code
	PushLong >workH	; workspace pointer
	jsr	makePdp
	pld
	lda	>pModuleID
	ora	#$0100
	jsl	EntryPt

	plp
	pld
	plb
	rts

EntryPt	entry
	jml	>0

	End
*-----------------------------------------------------------------------------*
MainDATA	Data
	debug	'MainDATA'

T2Actions	anop
               dc    i'doMake'          ; MakeT2 procedure	0
               dc    i'doSave'          ; SaveT2 procedure	1
	dc	i'doBlank'	; BlankT2 procedure	2
	dc	i'doLoadSetup'	; LoadSetupT2 procedure	3
	dc	i'doUnloadSetup'	; UnloadSetupT2 procedure 4
	dc	i'doKill'	; KillT2 procedure  	5
	dc	i'doHit'	; HitT2	procedure	6

OldX	ds	2
OldY	ds	2
OldStat	ds	2

RealError	ds	2
ErrorMsg	ds	2

pathH	ds	4
workH	ds	4

MasterID	ds	2
MyID	ds	2
pModuleID	ds	2

WindPtr	ds	4
RezFileID	ds	2
OurDP	ds	2
temp	ds	4
PathHandle	ds	4
;PicHandle	ds	4
;ErrorHandle	ds	4

pathname	ds	4

rEffectPath	str	'Phantom Path'	; rezName of wstring path rez

tempH	ds	4
ZeroString	str	''

NamePStrP	ds	4	; pointer to module's filename pstr

filenameH	ds	4

OurPort	ds	$AA

	End
*-----------------------------------------------------------------------------*
DisPatch 	start
	kind  $1000	; no special memory
	debug 'DisPatch'
	Using	MainDATA

disptch1 equ   $E10000
disptch2 equ   $E10004

         longa on
         longi on

* Assumes entry in long mode via JSL
         phb
         phk
         plb
         php                            ;(to fill out an even 2 words)
         phk
         per   MyPatch                  ;3 byte address of your patch
         jsr   Install
         pla
         pla                            ;Remove our longword from the stack

         plb
         rtl


RemoveIt	entry
	debug	'RemoveIt!'

         longa on
         longi on

* Assumes entry in long mode via JSL
         phb
         phk
         plb
         php                            ;(to fill out an even 2 words)
         phk
         per   MyPatch                  ;3 byte address of your patch
         jsr   Remove
         pla
         pla                            ;Remove our longword from the stack

         plb
         rtl


Install  	entry
	debug	'Install'

oldPatch equ   1
rtszp    equ   oldPatch+4
zpsize   equ   rtszp-oldPatch
newPatch equ   rtszp+2

         tsc
         sec
         sbc   #zpsize
         tcs
         phd                            ;Allocate some Direct-page space
         tcd                            ; off the stack
         php
         sei                            ;Important: don't leave interrupts on!

         ldy   #6
loop1    tyx                            ;Copy the current two tool vectors
         lda   >disptch1,x              ; into our patch's header section
         sta   [newPatch],y
         dey
         dey
         bpl   loop1

         lda   >disptch1+3
         and   #$00FF
         sta   oldPatch+2               ;Set up address of previous patch (or
         pha                            ; the actual dispatcher if no other
         lda   >disptch1+1              ; patches are installed)
         sec
         sbc   #$0011
         sta   oldPatch
         pha
         jsr   ChkPatch                 ;Anyone else patching the Dispatcher?
         plx
         plx
         bcs   First                    ;->No, we're the first!

         ldy   #8
loop2    lda   [oldPatch],y             ;Set up the linked-list
         sta   [newPatch],y
         iny
         iny
         cpy   #$F
         blt   loop2
         bra   PatchIt

First    ldy   #$E                      ;Set up the linked-list
         ldx   #6
loop3    lda   >disptch1,x
         sta   [newPatch],y
         dey
         dey
         dex
         dex
         bpl   loop3

PatchIt  clc                            ;Now patch us into the Dispatch vectors
         lda   newPatch
         adc   #$0015
         sta   newPatch
         xba
         and   #$FF00
         ora   #$005C
         sta   >disptch2
         lda   newPatch+1
         sta   >disptch2+2
         sec
         lda   newPatch
         sbc   #$0004
         sta   newPatch
         xba
         and   #$FF00
         ora   #$005C
         sta   >disptch1
         lda   newPatch+1
         sta   >disptch1+2

         plp                            ;Re-enable interrupts
         pld                            ; and put everything back
         tsc
         clc
         adc   #zpsize
         tcs
         clc
         rts


Remove   	entry
	debug 'Remove'

patchDsp equ   1
prevHdr  equ   patchDsp+5
zprts    equ   prevHdr+4
sizezp   equ   zprts-patchDsp
patchRmv equ   zprts+2

         tsc
         sec
         sbc   #sizezp
         tcs
         phd
         tcd                            ;Allocate DP space off the stack
         php
         sei                            ;Leave the phone off the hook

         pei   patchRmv+2
         pei   patchRmv
         jsr   ChkPatch                 ;Make sure it's a valid patch
         plx
         plx
         bcs   goerrRmv                 ;->Uh-oh, something bad's going on...

         lda   patchRmv
         adc   #$0011                   ;(carry is clear after BCS fails)
         sta   patchDsp+1
         lda   patchRmv+2
         sta   patchDsp+3
         lda   patchDsp
         and   #$FF00
         ora   #$005C
         sta   patchDsp
         cmp   >disptch1
         bne   notFirst
         lda   >disptch1+2
         cmp   patchDsp+2
         bne   notFirst

         ldy   #6
nxt1     tyx
         lda   [patchRmv],y
         sta   >disptch1,x
         dey
         dey
         bpl   nxt1
         bra   alldone

notFirst sec
         lda   >disptch1+1
         sbc   #$0011
         sta   prevHdr
         lda   >disptch1+3
         and   #$00FF
         sta   prevHdr+2
nxt2     pei   prevHdr+2
         pei   prevHdr
         jsr   ChkPatch
         plx
         plx
goerrRmv bcs   errRmv
         lda   [prevHdr]
         cmp   patchDsp
         bne   nope
         ldy   #2
         lda   [prevHdr],y
         cmp   patchDsp+2
         bne   nope

         ldy   #6
nxt3     lda   [patchRmv],y
         sta   [prevHdr],y
         dey
         dey
         bpl   nxt3
         bra   alldone

nope     ldy   #2
         lda   [prevHdr],y
         tax
         lda   [prevHdr]
         sta   prevHdr
         stx   prevHdr+2
         sec
         lda   prevHdr+1
         sbc   #$11
         sta   prevHdr
         lda   prevHdr+3
         and   #$00FF
         sta   prevHdr+2
         bra   nxt2

alldone  ldy   #0
getout   plp
         pld
         tsc
         clc
         adc   #sizezp
         tcs
         tya
         cmp   #0001                    ;Check for errors, set carry if so
         rts
errRmv   ldy   #1
         bra   getout



ChkPatch	entry
	debug 'ChkPatch'

dprts    equ   1
nwPtchAd equ   dprts+2

         tsc
         phd
         tcd
         lda   nwPtchAd+2
         and   #$FF00
         bne   BadPatch
         ldy   #0
check    jsr   chkValue                 ;Check 1st JML
         bne   BadPatch
         cpy   #0016                    ;Checked 4 JML's?
         bcc   check

         lda   [nwPtchAd],y             ;Get rtl/phk opcodes
         cmp   #$4B6B
         bne   BadPatch
         iny
         lda   [nwPtchAd],y             ;Get phk/pea opcodes
         cmp   #$F44B
         bne   BadPatch
         clc
         lda   nwPtchAd
         adc   #$000F
         ldy   #$13
         cmp   [nwPtchAd],y
         bne   BadPatch
         pld
         clc
         rts

BadPatch pld
         sec
         rts

chkValue lda   [nwPtchAd],y
         iny
         iny
         iny
         iny
         and   #$00FF
         cmp   #$005C
         rts



MyPatch  anop                           ;Header for a Dispatcher patch
next1vct jml   next1vct
next2vct jml   next2vct
disp1vct jml   disp1vct
disp2vct jml   disp2vct
anRTL    rtl

NewDsp1  phk                            ;Don't change these two lines; they
         pea   anRTL-1                  ; are required by the patch protocol

NewDsp2  anop                           ;Your patch code goes here!

	cpx	#$0e1e	; loadResource
	beq	LoadResource
;	cpx	#$1604
;	beq	SetMasterSCB
	cpx	#$1905	; systemTask
	bne	next2vct

*************************************
SystemTask	name

rtl1_st	equ	1
rtl2_st	equ	rtl1_st+3

	phb
	phk
	plb

indemo	entry
	lda	#0
	beq	movement	; not in demo
	~ReadMouse
	pla
	cmp	OldStat
	beq	sameStat
	plx
	plx
	bra	stopIt
sameStat	anop
	pla
	cmp	OldY
	beq	sameY
	plx
	bra	stopIt
sameY	anop
	pla
	cmp	OldX
	bne	stopIt

	shortm
               lda   KEYMODREG
	longm
               and   #%11011011	; OA, opt, shift, ctrl, repeat, keypad
	bne	stopIt

	shortm
	lda	KBD
	longm
	and	#$80
	beq	return_now
	bra	stopIt

movement	entry
	lda	>0
	beq	return_now

stopIt	anop
	lda	#STOP
	jsr	Phantasm

return_now	anop
	plb
	lda	#0	; we called waitcursor ourselves
	clc		; so just return!
	rtl


	ago	.past
*************************************
SetMasterSCB	anop
	brk
	lda	5,s
	sta	5+2,s
	lda	3,s
	sta	3+2,s
	lda	1,s
	sta	1+2,s
	pla
	clc
	rtl
.past
*************************************
LoadResource	name

rtl1_lr	equ	1
rtl2_lr	equ	rtl1_lr+3
rID_lr	equ	rtl2_lr+3
type_lr	equ	rID_lr+4
result_lr	equ	type_lr+2

	lda	type_lr,s
	cmp	#rTextBlock
	bne	next
	lda	rID_lr+2,s
	bne	next
	lda	rID_lr,s
	cmp	#$360
	bne	next

               PushWord #t2GetBuffers
               PushWord #stopAfterOne+sendToName
	PushLong #toT2String	; target
               phy
               phy                      ; dataIn (none)
               PushLong #getBufferDataOut ; dataOut
               _SendRequest

;	shortm
;	lda	SHADOW
;	longm
;	bit	#$08
;	bne	shadow_off
;
;	lda	>buffer01
;	sta	result_lr,s
;	lda	>buffer01+2
;	sta	result_lr+2,s
;	bra	strip6_return
;
;shadow_off	anop
	lda	>bufferE1
	sta	result_lr,s
	lda	>bufferE1+2
	sta	result_lr+2,s

strip6_return	lda	5,s
	sta	5+6,s
	lda	3,s
	sta	3+6,s
	lda	1,s
	sta	1+6,s
	pla
	pla
	pla
	clc
	rtl

next	brl	next2vct

toT2String	str	'DYA~Twilight II~'

getBufferDataOut anop
	ds	2
bufferE1	ds	4
buffer01	ds	4
	ds	4	; palBuffer

	End
*-----------------------------------------------------------------------------*
doMake         Start
	Using	MainDATA
	debug 'doMake'

               lda   <T2data1+2
               sta   WindPtr+2
               lda   <T2data1
               sta   WindPtr
               lda   <T2data2
               sta   RezFileID
	~MMStartUp
	pla
               sta   MyID

; Create our controls.

               LongResult
               pei   <T2data1+2
               pei   <T2data1
               PushWord #resourceToResource
               PushLong #1
               _NewControl2
               plx
               plx

; Make sure we're dealing with the T2pref file.

               ~GetCurResourceFile
	lda	1,s
	sta	fill+1

               pei   <T2data2
               _SetCurResourceFile

; Load the module path resource.

	~RMLoadNamedResource #rWString,#rEffectPath
               bcc   pathThere
	plx
	plx
	stz	PathHandle
	stz	PathHandle+2
;	lda	#UnknownStr
;	sta	PathPtr
;	lda	#^UnknownStr
;	sta	PathPtr+2

fill	PushWord #0
	_SetCurResourceFile

               PushWord #inactiveHilite 
               ~GetCtlHandleFromID WindPtr,#3
               _HiliteControl           ; Dim the demo ctl
	
               PushWord #inactiveHilite 
               ~GetCtlHandleFromID WindPtr,#2
               _HiliteControl           ; Dim the config ctl
	
               pei   <T2data2
               _SetCurResourceFile

	PushLong #UnknownStr
	makeDP
	bra	moveOn

PathThere	anop
	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rEffectPath,#temp ; rID
	_DetachResource

	lda	1,s
	sta	PathHandle
	lda	1+2,s
	sta	PathHandle+2
	jsr	makePdp
moveOn	anop
	lda	[3]
	xba
	sta	[3]
	inc	<3
	pld		; ptr to source string
	PullLong PathPtr

               _SetCurResourceFile

	jsr	substitute

	lda	#6
	sta	<T2Result
               rts

CompileHandle	ds	4
ControlHandle	ds	4
LETextHandle	ds	4

UnknownStr	GSStr	'(Unknown.)'

SubArray	anop
PathPtr	entry
	ds	4



substitute	entry
	debug	'substitute'

	LongResult
	PushWord #1	; pascal substitution strings
	PushLong #SubArray

	~LoadResource #rTextForLETextBox2,#1
	lda	1,s
	sta	LETextHandle
	lda	1+2,s
	sta	LETextHandle+2
	jsr	makePdp	
	pld

	~GetHandleSize LETextHandle
	pla
	plx		; chuck hi word
	pha
doCall	_CompileText
	PullLong CompileHandle

	~ReleaseResource #3,#rTextForLETextBox2,#1

	PushLong PathPtr
	makeDP
	dec	<3
	lda	[3]
	xba
	sta	[3]
	killLdp

	~LoadResource #rControlTemplate,#effectPathStrCtl
	lda	1,s
	sta	ControlHandle	
	lda	1+2,s
	sta	ControlHandle+2
	jsr	makePdp
	ldy	#$1A	; textRef
	lda	CompileHandle
	sta	[3],y
	iny
	iny
	lda	CompileHandle+2
	sta	[3],y

	ldy	#$14	; moreFlags
	lda	[3],y
	and	#$FFFC
	ora	#refIsHandle
	sta	[3],y
	killLdp

               LongResult
	PushLong WindPtr
               PushWord #singleHandle
               PushLong ControlHandle
               _NewControl2
               plx
               plx

	rts

               End
*-----------------------------------------------------------------------------*
doHit	Start
	debug	'doHit'
	Using	MainDATA

	stz	<T2Result+2
	stz	<T2Result
	lda	<t2data2+2	; ctlID hi word must be zero
	bne	nothingHit
	lda	<t2data2
	cmp	#1
	beq	pathBtnHit
	cmp	#2
	jeq	configHit
	cmp	#3
	jeq	demoHit
	bge	nothingHit
	lda	#TRUE
	sta	<T2Result
nothingHit	rts

pathBtnHit	anop
               ~LoadOneTool #$17,#$0303

               ~SFStatus
               pla
               sta   SFStatus
               bne   Active

        ~NewHandle #$100,MyID,#attrLocked+attrFixed+attrPage+attrBank,#$0000000
               plx
               stx   ToolDP
               plx
               stx   ToolDP+2
	bcc	memOK
;	pha
;               ~UnloadOneTool #$17
;	pla
	brl	DoUnknownErrorAlert

memOK	anop
               PushWord MyID
	PushLong ToolDP
	jsr	makePdp
	pld
	pla
	plx
	pha
               _SFStartUp
	bcc	SFOK
	pha
	~DisposeHandle ToolDP
;               ~UnloadOneTool #$17
	pla
	brl	DoUnknownErrorAlert

SFOK	anop
active         anop

               stz   PrefixHndl
               stz   PrefixHndl+2

               ~GetCurResourceFile
               ~SetCurResourceFile RezFileID

	~RMLoadNamedResource #rWString,#rEffectPath
	bcc	PathOK
	plx
	plx
	brl	skipSetPath

PathOK	anop
	lda	1,s
	sta	pathH
	lda	1+2,s
	sta	pathH+2
	lda	3,s
	pha
	lda	3,s
	pha
	_HLock
	jsr	makePdp
;	lda	[3]
;	xba
;	sta	[3]
;	inc	<3
;	pld
;	PullLong pathP
	lda	3,s
;	sta	pathP
	sta	pSPfx_prefix
	lda	3+2,s
;	sta	pathP+2
	sta	pSPfx_prefix+2

	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rEffectPath,#temp ; rID
	_DetachResource

	shortm
	lda	[3]
	tay
	iny
searchDelim	lda	[3],y
	cmp	#":"
	beq	foundDelim
	dey
	cpy	#2
	bge	searchDelim
	longm
;	~DisposeHandle pathH
	brl	exitSetPath
foundDelim	anop
	dey
	tya
	sta	[3]
	longm
	killLdp


               lda   #255               ; Set the length of the output buffer
               sta   BufLength
               stz   BufLength+2

getMem         anop                     ; Get a handle that size.
               LongResult
               PushLong BufLength
               lda   MyID
	ora	#$0F00
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               bcc   HandleOK
               plx
               plx
	brl	exitSetPath

HandleOK       makeDP
               ldy   #2                 ; Derefrence it
               lda   <3
               sta   PrefixHndl
               lda   <5
               sta   PrefixHndl+2
               lda   [3]
               sta   pGPfx_prefix
               tax
               lda   [3],y
               sta   pGPfx_prefix+2
               sta   <5
               stx   <3
               lda   BufLength          ; and initialize it to be a GSOS output
               sta   [3]                ; buffer (ie. With a length word at the
               killLdp                  ; beginning.)

               _GetPrefixGS pGPfx       ; get the current prefix 31.
               bcc   prefixOk           ; if no errors, then go on
               cmp   #buffTooSmall
               beq   BiggerBuffer
	bra	exitSetPath

BiggerBuffer   PushLong pGPfx_prefix    ; else, get the length the buffer
               makeDP                   ; SHOULD have been.
               lda   [3]
               sta   BufLength
               killLdp

               ~HUnlock PrefixHndl
               ~SetHandleSize BufLength,PrefixHndl
               ~HLock PrefixHndl

prefixOk       anop
setprefix	anop
	_SetPrefixGS pSPfx

exitSetPath	anop
	~DisposeHandle pathH

skipSetPath	anop

	_SetCurResourceFile
               PushWord #120            whereX  640
               PushWord #50             whereY  640
               PushWord #refIsPointer   promptRefDesc
               PushLong #OpenString     promptRef
	ldy	#0
	phy
               phy                      filterProcPrt
               PushLong #TypeList       typeListPtr
               PushLong #SFReply        replyPtr
               _SFGetFile2

	lda	PrefixHndl
	ora	PrefixHndl+2
	beq	noRestore

               inc   pGPfx_prefix       ; set prefix 31 back to what it was
               inc   pGPfx_prefix       ; before (skipping buffer length word)
               _SetPrefixGS pGPfx
               ~DisposeHandle PrefixHndl ; and get rid of the prefix handle

noRestore	anop
               lda   SFStatus
               bne   noShutIt
               _SFShutDown
               ~UnloadOneTool #$17

               ~DisposeHandle ToolDP

noShutIt       anop
               lda   SFReply            See if user clicked cancel
	bne	noCancel
               rts

noCancel	anop
	lda	#TRUE
	sta	<T2Result

	PushLong Path
	jsr	makePdp
	inc	<3
	inc	<3	; past buff size word
	pld
	PushLong Path
	~GetHandleSize Path
	lda	1,s	; lo word
	dec	a
	dec	a
	sta	1,s
	_PtrToHand

	~GetHandleSize Path
	lda	1,s	; lo word
	dec	a
	dec	a
	sta	1,s
	PushLong Path
	_SetHandleSize

	~DisposeHandle PathHandle

	~HLock Path

	lda	Path
	sta	PathHandle
	lda	Path+2
	sta	PathHandle+2

;               ~DisposeHandle Path
               ~DisposeHandle Nom

	PushLong PathHandle
	jsr	makePdp
	lda	[3]
	xba
	sta	[3]
	inc	<3
	pld		; ptr to source string
	PullLong PathPtr

               LongResult               ; for disposecontrol
	~GetCtlHandleFromID WindPtr,#effectPathStrCtl
               lda   1,s
               sta   5,s
               lda   1+2,s
               sta   5+2,s
               _HideControl
               _DisposeControl

	jsr	substitute
	rts

SFStatus       ds    2

OpenString     str   'Use which Phantasm effect?'

TypeList       anop
               dc    i'1'               number of types
               dc    i'$8000'           flags: normal.. :-)
               dc    i'$B5'             fileType
               dc    i4'$0000'          auxType

SFReply        anop
               ds    2
fileType       ds    2
auxType        ds    4
               dc    i'3'
Nom            ds    4
               dc    i'3'
Path           ds    4

ToolDP	ds	4

;pathP	ds	4
pathH	ds	4

PrefixHndl     handle                   ; handle to the old prefix 31
BufLength      dc    i4'255'

pGPfx          PrefixRecGS (8,0)
pSPfx          PrefixRecGS (8,0)

               End
*-----------------------------------------------------------------------------*
configHit	Start
;	brk
	debug	'configHit'
	Using	MainDATA

	jsr	doSave2	; save active effect (DOCUMENT THIS)

	~GetCurResourceFile
	~SetCurResourceFile RezFileID

	jsr	doLoadSetup

	~GetPort
	~OpenPort #OurPort
	~SetPort #OurPort

	lda	#CONFIGURE
	jsr	Phantasm

	_SetPort	; old port already on stack
	~ClosePort #OurPort

	jsr	doUnloadSetup2	; don't dispose workH or pathH

* weird, but it has to be done or else 1e11 will come down below @ rmsetrname
;               ~UpdateResourceFile RezFileID
;	errorbrk $60

	PushLong pathH
	jsr	makePdp
	lda	[3]
	inc	a
	tay
	ldx	#0
	shortm
keepSearching	lda	[3],y
	inx
	cmp	#":"
	beq	foundDelim
	dey
	bpl	keepSearching
	brk	$f0
foundDelim	anop
	longm
	sty	fill+1
	lda	<3
fill	adc	#0
	sta	<3
	dec	<3
	dex
	txa
	shortm
	sta	[3]
	longm
	pld
	PullLong NamePStrP

;	brk

	PushWord #rByteArray	; for RMSetResourceName
	~RMFindNamedResource #rByteArray,NamePStrP,#temp ; rID
	bcc	found
	plx
	plx
	plx
	bra	new
found	PushWord #rByteArray	; rType
	lda	5,s	
	pha
	lda	5,s
	pha
	_RemoveResource
	errorbrk 1
	PushLong #ZeroString	; no rezName
	_RMSetResourceName
	errorbrk 2

new	anop
	WordResult
	~GetCurResourceApp
	PushLong workH
	_SetHandleID
	plx

;	brk

	PushLong workH	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rByteArray	; rType
	~UniqueResourceID #$FFFF,#rByteArray ; rID
	errorbrk 3
	lda	1,s
	sta	tempH
	lda	1+2,s
	sta	tempH+2
	_AddResource
	errorbrk 4

	PushWord #rByteArray	; rType
	PushLong tempH	; rID
	PushLong NamePStrP 	; ptr to name str
	_RMSetResourceName
	errorbrk 5

; Update the file and restore original rezFile.

               ~UpdateResourceFile RezFileID
	errorbrk 6



	~LoadResource #rByteArray,tempH ;n
	errorbrk 7
	PullLong workH           ;n

	PushWord #rByteArray	; rtype
	PushLong tempH
;	~RMFindNamedResource #rByteArray,NamePStrP,#temp ; rID
	_DetachResource
	errorbrk 8




	_SetCurResourceFile

* finally release pathH

	~DisposeHandle pathH
	rts

               End
*-----------------------------------------------------------------------------*
demoHit	Start
	debug	'demoHit'
	Using	MainDATA

	jsr	doSave2	; save active effect (DOCUMENT THIS)

	~GetCurResourceFile
	~SetCurResourceFile RezFileID

;	_HideMenuBar
	_HideCursor


               LongResult
               PushLong #$300+($A0*13)
               lda   MyID
               ora   #$0500
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
	lda	3,s
	pha
	lda	3,s
	pha
	jsr	makePdp
	ldx	#$300-2
copySCBs	txy
	lda	$E19D00,x
	sta	[3],y
	dex
	dex
	bpl	copySCBs
	ldx	#($A0*13)-2
	ldy	#$300+($A0*13)-2
copyMenu	lda	$E12000,x
	sta	[3],y
	dey
	dey
	dex
	dex
	bpl	copyMenu

	jsr	doLoadSetup

	~ReadMouse
	PullWord OldStat
	PullWord OldY
	PullWord OldX

	lda	#TRUE
	sta	indemo+1

	jsl	DisPatch

	shortmx
	lda   CLOCKCTL
	tax
	and   #$0F
	pha		; save original color
	txa
	and	#$F0
	sta	CLOCKCTL
	longmx

	~GetPort
	~OpenPort #OurPort
	~SetPort #OurPort

	~GetMasterSCB
	lda	1,s
	bit	#$8000
	bne	shad
noshad	lda	#$E120
	sta	shadfill+2
	bra	goahead
shad	lda	#$0120  
	sta	shadfill+2
goahead	lda	1,s
	and	#$7FFF	; no shadowing
	pha
	_SetMasterSCB

	lda	#DEMO
	jsr	Phantasm

	_SetMasterSCB

	_SetPort	; old port already on stack
	~ClosePort #OurPort

               shortm
              	lda	CLOCKCTL
	and	#$F0
	ora	1,s
	sta	CLOCKCTL
	pla
               longm

	jsl	RemoveIt

;	lda	#FALSE
	stz	indemo+1

	jsr	doUnloadSetup

	ldx	#$300-2
restSCBs	txy
	lda	[3],y
	sta	$E19D00,x
	dex
	dex
	bpl	restSCBs
	ldx	#($A0*13)-2
	ldy	#$300+($A0*13)-2
restMenu	anop
	lda	[3],y
shadfill	sta	$E12000,x
	dey
	dey
	dex
	dex
	bpl	restMenu

	killLdp
	_DisposeHandle
	_SetCurResourceFile
	~RefreshDesktop #0
	_ShowCursor
;	_ShowMenuBar
	rts

               End
*-----------------------------------------------------------------------------*
doLoadSetup	Start
	debug	'doLoadSetup'
	Using	MainDATA

	~MMStartUp
	pla
	sta	MasterID
	ora	#$0100
	sta	MyID

	stz	ErrorMsg
	stz	RealError

	~RMLoadNamedResource #rWString,#rEffectPath
	bcc	PathOK2
	plx
	plx
	sta	RealError
	stz	workH
	stz	workH+2
	lda	#1
	sta	ErrorMsg
	rts

PathOK2	anop
	lda	1,s
	sta	pathH
	lda	1+2,s
	sta	pathH+2
	jsr	makePdp
	pld
	PullLong pathname

	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rEffectPath,#temp ; rID
	_DetachResource


	WordResult	;n
	lda	MasterID
	ora	#$0300
	pha
	PushLong pathH
	_SetHandleID
	plx



;	brk

	PushLong pathH	; for handtohand
	LongResult
	~GetHandleSize pathH
	~SetHandleID #0,pathH
	PushWord #attrLocked+attrNoSpec+attrNoCross
	phd
	phd
	_NewHandle
	lda	1,s
	sta	filenameH
	lda	1+2,s
	sta	filenameH+2
	~GetHandleSize pathH	; for handtohand
	_HandToHand


* get the module's config data...

	PushLong filenameH
	jsr	makePdp
	lda	[3]
	inc	a
	tay
	ldx	#0
	shortm
keepSearching	lda	[3],y
	inx
	cmp	#":"
	beq	foundDelim
	dey
	bpl	keepSearching
	brk	$f0
foundDelim	anop
	longm
	sty	fill+1
	lda	<3
fill	adc	#0
	sta	<3
	dec	<3
	dex
	txa
	shortm
	sta	[3]
	longm
	pld
	PullLong NamePStrP



	~RMLoadNamedResource #rByteArray,NamePStrP
	bcc	PathOK

	PushLong #32	;64 - result space already on stack
	lda	MasterID
	ora	#$0200
	pha
	PushWord #attrNoCross+attrNoSpec+attrLocked
	phd
	phd
	_NewHandle
	lda	1,s
	sta	workH
	lda	3,s
	sta	workH+2
	jsr	makePdp
	lda	#0
	ldy	#32-2
zero	sta	[3],y
	dey
	dey
	bpl	zero	
	killLdp
	bra	doneThat

PathOK	anop
	PullLong workH

	PushWord #rByteArray	; rtype
	~RMFindNamedResource #rByteArray,NamePStrP,#temp ; rID
	_DetachResource

	WordResult
	lda	MasterID
	ora	#$0200
	pha
	PushLong workH
	_SetHandleID
	plx

doneThat	anop

	~DisposeHandle filenameH

	~GetNewID #$5000
	PullWord pModuleID


* Load the module into memory.

               WordResult
               WordResult
               LongResult
               WordResult
               PushWord pModuleID
	PushLong pathname
               PushWord #TRUE
               PushWord #1
               _InitialLoad2
               bcc   ValidLoad
               plx
               plx
               plx
               plx
               plx
* error! display an error message...
	sta	RealError
	lda	#2
	sta	ErrorMsg
	~DeleteID pModuleID
	rts
ValidLoad      pla
               pla                      ;and store it's address into the
               sta   EntryPt+1	;doBlank routine, so that when it's time
               pla                      ;to blank, it'll be called
               shortm
               sta	EntryPt+3
               longm
               pla
               pla

	rts

               End
*-----------------------------------------------------------------------------*
doUnloadSetup	Start
	debug	'doUnloadSetup'
	Using	MainDATA

	~DisposeHandle workH
	~DisposeHandle pathH
doUnloadSetup2	entry

	lda	pModuleID
	beq	skipShut
	WordResult
	pha
	PushWord #$0000
               _UserShutDown
               plx                      ; chuck memID

skipShut	anop
	rts

               End
*-----------------------------------------------------------------------------*
doSave         Start
               Using MainDATA
	debug 'doSave'


	lda	PathHandle
	ora	PathHandle+2
	bne	notNIL
	rts

notNIL	~GetCurResourceFile
               ~SetCurResourceFile RezFileID
;fuck
;	brk

	PushWord #rWString	; for RMSetResourceName
	~RMFindNamedResource #rWString,#rEffectPath,#temp ; rID
	bcc	found
	plx
	plx
	plx
	bra	new
found	PushWord #rWString	; rType
	lda	5,s	
	pha
	lda	5,s
	pha
	_RemoveResource
	errorbrk $10
	PushLong #ZeroString	; no rezName
	_RMSetResourceName
	errorbrk $11

new	anop

* new!!!!!!!!! 12/30/92 JRM

	WordResult
	~GetCurResourceApp
	PushLong PathHandle
	_SetHandleID
	plx

;	brk

	PushLong PathHandle	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rWString	; rType
	~UniqueResourceID #$FFFF,#rWString ; rID
	errorbrk $12
	lda	1,s
	sta	tempH
	lda	1+2,s
	sta	tempH+2
	_AddResource
	errorbrk $13

	PushWord #rWString	; rType
	PushLong tempH	; rID
	PushLong #rEffectPath 	; ptr to name str
	_RMSetResourceName
	errorbrk $14

; Update the file and restore original rezFile.

               ~UpdateResourceFile RezFileID
	errorbrk $15

	~LoadResource #rWString,tempH ;n
	errorbrk $17
	PullLong PathHandle           ;n

	PushWord #rWString	; rtype
	PushLong tempH
;	~RMFindNamedResource #rWString,#rEffectPath,#temp ; rID
	_DetachResource
	errorbrk $16

skipSave	anop

               _SetCurResourceFile


               PushWord #noHilite
               ~GetCtlHandleFromID WindPtr,#3
               _HiliteControl           ; enable the demo ctl

               PushWord #noHilite
               ~GetCtlHandleFromID WindPtr,#2
               _HiliteControl           ; enable the config ctl
               rts

doSave2	ename
* Is the save control enabled?
               ~GetCtlHandleFromID WindPtr,#T2SetupUpdateCtlID
	jsr	makePdp
	ldy	#oCtlHilite
	lda	[3],y
	killLdp
	and	#$00FF
	cmp	#inactiveHilite
	beq	updateDisabled

* Re-disable update control.
               PushWord #inactiveHilite
               ~GetCtlHandleFromID WindPtr,#T2SetupUpdateCtlID
               _HiliteControl
	brl	doSave	; save the pathname

updateDisabled	anop
	rts

               End
*-----------------------------------------------------------------------------*
doKill	Start
	debug	'doKill'
	Using	MainDATA

	~DisposeHandle PathHandle
	rts

               End
*-----------------------------------------------------------------------------*
DoUnknownErrorAlert Start
	kind	$1000
	debug 'DoUnknownErrorAlert'

	LongResult	; convert error to ascii
	pha
	_HexIt
	PullLong asciiErr

	~InitCursor

* Create an alert informing the user that there was an error.

 ~AlertWindow #awPString+awResource+awButtonLayout,#errorSub,#AlertUnknownError
               plx                      ; chuck button hit
	rts

* Alert string substitution array for error alert dialogs.

errorSub       dc    i4'errorStr'
errorStr	anop
	dc	h'04'	; length byte (pstring)
asciiErr	ds	4

               End
*-----------------------------------------------------------------------------*
ErrorMaker	Start
	debug	'ErrorMaker'
	kind	$1000
	Using	MainDATA

	pld

	~HexIt RealError
	pla
	sta	ascii0
	sta	ascii1
	pla
	sta	ascii0+2
	sta	ascii1+2

	lda	ErrorMsg
	cmp	#3	;errors 1 through 2 are good
	blt	known
	stz	<T2Result
	stz	<T2Result+2
	rts

known	anop
	dec	a	;make that 0 through 1
	asl	a
	tax
	phx		;save this for a moment

	LongResult
	PushWord #0
	lda	ErrorLengths,x	;size
	pha
	~MMStartUp
	pla	
	ora	#$0300
	pha
	PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	PullLong <T2Result

	plx
	PushWord #Errors|-16
	lda	Errors,x
	pha		;pointer
	pei	<T2Result+2
	pei	<T2Result
	PushWord #0
	lda	ErrorLengths,x
	pha		;size
	_PtrToHand	;copy the string into the handle
	rts

Errors	dc	a'PathRezErrMsg'	; error 1
	dc	a'ilErrMsg'	; error 2 (initialload error)

ErrorLengths	dc	i'PathRezErrLen,ilErrLen'

PathRezErrMsg	anop
	dc	c'Twilight II '
	dc	h'd2',c'Phantom',h'd3'
	dc	c' Module Error:',h'0d'
	dc	c'No effect has been selected! ($'
ascii0	dc	c'????)',h'00'
PathRezErrEnd	anop
PathRezErrLen	equ	PathRezErrEnd-PathRezErrMsg

ilErrMsg	anop
	dc	c'Twilight II '
	dc	h'd2',c'Phantom',h'd3'
	dc	c' Module Error:',h'0d'
	dc	c'Could not load Phantasm',h'aa',c' effect! ($'
ascii1	dc	c'????)',h'00'
ilErrEnd	anop
ilErrLen   	equ	ilErrEnd-ilErrMsg

               End
*-----------------------------------------------------------------------------*
	copy	22:makePdp.asm
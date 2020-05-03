         setcom 80
	mcopy	blank.mac
	keep	blank
	copy	13:ainclude:e16.misctool
	copy  13:ainclude:e16.memory
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.gsos
	copy	13:ainclude:e16.quickdraw
	copy	equates
	copy	v1.2.equ
	copy	debug.equ
*-----------------------------------------------------------------------------*
oBlankNowFlag	gequ	0
oModuleMemID	gequ	oBlankNowFlag+2
oT2moduleFlags	gequ	oModuleMemID+2
oModuleEntryPt	gequ	oT2moduleFlags+2
oPrefRezFileID	gequ	oModuleEntryPt+4
oPrefRezAppID	gequ	oPrefRezFileID+2
oLSResult	gequ	oPrefRezAppID+2
Parms_Size	gequ	oLSResult+4
*-----------------------------------------------------------------------------*
* Blank_Screen. V1.00 - 05/24/92 by JRM. coded - initial version -T2 1.0d33
* v1.1 - 1 June 1992 JRM - updated for new setup load times -T2 1.0d33
* v1.11 - 2 June 1992 JRM - added openPrefFile -T2 1.0d33
* v1.2 - June 92 - January 93 JRM - various!
* v1.3 - 22 Feb 93 - rewrote save/rest, subrodized!, seperate source seg -T2 1.1f3
* v1.4 - 28 Feb 93 - nextModule stuff - T2 1.1f3
*
* DataIn = Pointer to special structure:
*
*  +00 blankNowFlag:  boolean -
*    IF TRUE, we are being called from the "blank now" control:
*       = do NOT call SysBeep2 for screen is blanking/unblanking
*       = DO _force_ setup to be loaded and unloaded
*       = DO pass a flag to the module telling it we're calling it like this
*    IF FALSE, we are being called from the init:
*       = DO call SysBeep2 for screen is blanking/unblanking
*       = do NOT _force_ setup to be loaded and unloaded
*       = DO pass a flag to the module telling it we're calling it like this
*  +02 moduleMemID:   word    - memory ID to pass to module
*  +04 T2moduleFlags: word    - t2moduleflags for module
*  +06 moduleEntryPt: long    - JML MODULE_START (h'5c', i3'module_start')
*  +10 prefRezFileID: word    - resource file ID of opened pref resource file
*                               only used if preffile is already open
*  +12 prefRezAppID:  word    - resource application id pref rezfile opened
*                               previously under
*                               IF ZERO then the rezApp won't be set (only the
*                               currfile will be when preffile is already open)
*  +14 LSResult:      long    - result from loadsetupt2 of module
*                               or NIL if setup hasn't been loaded yet..
*  +18 size
*
*  prefRezFileID and prefRezAppID are not needed if the prefFile is not already
*   open.
*
* DataOut = undefined.
*

Blank_Screen   Start
	kind	$1000	; no special memory
	Using	RequestDATA
	Using	InitDATA
	Using	LoadDATA
	Using	BlankDATA
	debug	'Blank Screen'
	copy	22:debug.asm

	DefineStack
buff_norm  	long
buff_aux	long
stkFrameSize   EndLocals
dpr2	word
rtsaddr	word
dpageptr	word
dbank	byte
rtladdr	block 3
dataOut	long
dataIn	long
request	word
result	word

               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

* Make a copy of the input params..

	ldy	#Parms_Size-2
copy_parms	lda	[dataIn],y
	sta	Local_Parms,y
	dey
	dey
	bpl	copy_parms

* Setup the flag passed at BlankT2 time that tells the module if it is being
* called from "blank now" control or not..

	lda	Local_Parms+oBlankNowFlag
	bne	yes_bn	; yes we are called from blank now

no_bn	anop
	stz	blank_flags
	bra	done_bf_setup

yes_bn	anop
	mvw	#bmiBlankNow,blank_flags

done_bf_setup	anop

* Patch the entry point in..

 	mvl	Local_Parms+oModuleEntryPt,JML_Module

* Save border color...

	shortmx
	lda   CLOCKCTL
	tax
	and   #$0F
	pha		; save original color
	txa
	and	#$F0
	sta	CLOCKCTL
	longmx

	jsr	startFont	; if necessary, start font manager
	jsr	Alloc_DP	; get module DP space (1 page)

* If we're being called from the "blank now" control, skip the beep..

	lda	Local_Parms+oBlankNowFlag
	bne	skipBeep
	~SysBeep2 #sbSilence+sbScreenBlanking
skipBeep	anop

	~HideCursor              ; Hide the cursor
	~HideCursor	; (twice for point-pieceofshit-less)
	~HidePen	; hide the pen

	stz	shadowH	; init shadowH to null (important!)
	stz	shadowH+2

	shortm	; save original contents of
	lda	SHADOW	; shadow softswitch
	longm
	and	#$FF
	sta	SavedSHADOW


* Lock down and deref Screen1Hndl (normal buffer)..

	lda	Screen1Hndl+2
	sta	<buff_norm+2
	pha
	lda	Screen1Hndl
	sta	<buff_norm
	pha
	lda	[buff_norm]
	tax
	ldy	#2
	lda	[buff_norm],y
	sta	<buff_norm+2
	stx	<buff_norm	
	_HLock

	lda	Options2Flag
	bit	#fLowMemoryMode
	beq	noLowMem

* Low memory mode is ON... zero auxillary buffer ptr

	stz	<buff_aux
	stz	<buff_aux+2
	bra	deref_done

noLowMem	anop

* Lock down and deref Screen2Hndl (auxilliary buffer)..
* Screen2Hndl is only used when shadowing is off but allocated initially.
* (In that case both E1 and 01 screens are saved..)

	lda	Screen2Hndl+2
	sta	<buff_aux+2
	pha
	lda	Screen2Hndl
	sta	<buff_aux
	pha
	lda	[buff_aux]
	tax
	ldy	#2
	lda	[buff_aux],y
	sta	<buff_aux+2
	stx	<buff_aux	
	_HLock	; lock shadow buffer down

deref_done	anop

** BY NOW ** Screen all saved!

	~GetMasterSCB	; save original masterSCB (on stack)
	lda	1,s
	sta	SavedMasterSCB
	~GetPort	; save old port
	~OpenPort #OurPort	; open new port
;	~SetPort #OurPort	; make our new port current

	jsr	save_screen	; save the screen.. nice 'n easy

	shortm	; fuck!!
	lda	SHADOW
	longm
	bit	#$08
	bne	noShad
	~GetPortLoc #MyPortLoc
	lda	#$0001
	sta	ptrToPixImage+2
	lda	#$2000
	sta	ptrToPixImage
	~SetPortLoc #MyPortLoc
* if shadowing is on, make banks 01 and E1 equal...
	phb
	ldx	#$2000	; x= source address
	txy		; y= dest address
	lda	#$8000-1	; length minus 1
	mvn	$E12000,$012000
	plb
noShad	anop

	jsr	load_setup	; if necessary
	jsr	fade_out	; if necessary

top            anop
	jsr	force_grafport	; if necessary
	jsr	mcp	; if necessary

	~GetCurResourceApp
	lda	Local_Parms+oPrefRezAppID
	beq	skipSet
	pha	
	_SetCurResourceApp
skipSet	anop

	jsr	ZERO_BUSY	; make busy flag = 0

;	lda	BUSYFLG
;	and	#$FF
;	beq	zero
;	_SysBeep
;	shortm
;	lda	CLOCKCTL
;	inc	a
;	inc	a
;	sta	CLOCKCTL
;	longm
;zero	anop

	debug	'jjj'
	lda	Local_Parms+oBlankNowFlag
	bne	skip_swap_init	; from "blank now" - yes
;	brk	$56
	lda	Options2Flag	; swapping modules ON?
	bit	#fSwapModules
	beq	skip_swap_init	; no!
	lda	NumRandModules	; if only one module is selected
	cmp	#1	; then don't swap!
	beq	skip_swap_init
	mvw	SwapDelay,swap_count ; else init swap count to (15 seconds)
;	mvw	#20,swap_count
skip_swap_init	anop

	tdc
	sta	oldDP+1
	phb
	phb
	pla
	sta	oldDBR+1

	ldy	#0
	phy
	phy		; result space [T2Result]
	PushWord #BlankT2	; T2message = blank screen
	PushLong #BlankFlag	; T2data1 = ptr to blnk flg (movePtr)
	makeDP
	lda   #0  	; init movePtr to FALSE (0)
	sta   [3]
	pld
	phy		; reserved [T2data2 - hi]
	PushWord blank_flags
;	phy		; reserved [T2data2 - lo]
	lda	module_dp
	tcd
	jsl	JML_MODULE

oldDP	lda	#0	; restore our dp
	tcd
oldDBR	pea	0	; restore our dbr
	plb
	plb

	jsr	REST_BUSY	; restore busy flag to what it was..
	stz	SwapNow	; module swap no longer needed
	stz	swap_count

	lda	1,s
	sta	blank_result
	lda	1+2,s
	sta	blank_result+2
	
	lda	1+2,s
	and	#$FF
	sta	1+2,s	
checkHandle	lda	1,s
	sta	ErrorHandle
	lda	1+2,s
	sta	ErrorHandle+2
	_CheckHandle
	bcs	noError

	stz	blank_result
	stz	blank_result+1

* Got an error message.. display it!

	PushLong #BlankFlag	; ptr to blnk flg (movePtr)
	makeDP
	lda   #0  	; init movePtr to FALSE (0)
	sta   [3]
	pld
	PushLong ErrorHandle
	jsr	makePdp
	pld		; ptr to c-string
	jsl	DrawString	; display the error

	~DisposeHandle ErrorHandle ; dispose the err string handle

NoError	anop
	_SetCurResourceApp	; restore resource App

	jsr	unload_setup	; if necessary


	lda	blank_result+2
	bit	#bmrNextModule
	bne	run_next_module

	lda	BlankFlag
	cmp	#2	; 2 = module was swapped out
	beq	run_next_module

;	lda	Local_Parms+oT2ModuleFlags
;	bit	#fPrematureExit
;	bne	run_next_module

;neu	brk	02
	jsr	restore_all
	jsr	randomize	; if necessary
	bra	restored_exit


run_next_module anop

*** bmrNextModule has been set!  We're gonna have to do another module! ***

* Use the BlankNowFlag to tell us if we're being called from "blank now" button
* or not..  if we are, we're done.

	lda	Local_Parms+oBlankNowFlag
	bne	normal_exit	; from "blank now" - yes

* get the next module loaded into memory..

	jsr	randomize	; if necessary
	jsr	load_setup	; if necessary

* does the new module require a usable screen?

	lda	Local_Parms+oLSResult
	bit	#lmrReqUsableScreen
	bne	required

	lda	ModuleFlags
;	sta	Local_Parms+oT2ModuleFlags
	bit	#fReqUsableScreen
	beq	screen_ok 	; usable screen not required!

required	anop
* new module _requires_ usable screen..
* did the old module leave a usable screen?
* does the old module always leave a usable screen?

	lda	old_mFlags
	bit	#fLeavesUsableScreen
	bne	screen_ok	

* did the module say that it left a usable screen this time?

	lda	blank_result+2
	bit	#bmrLeavesUsableScreen
	bne	screen_ok

***	jsr	restore_all
	jsr	restPals	; restore the palettes
ass	jsr	rest_port_shr	; restore the pixel data - must be rest_port_shr!!!
	jsr	restSCBs	; restore the SCBs
	bra	all_set

screen_ok	anop
* If the module didn't want the screen to be faded out; it won't be faded
	jsr	fade_out	; if necessary

all_set	anop
	~ClosePort #OurPort
	~OpenPort #OurPort	; open new port & make it current port
;	~SetPort #OurPort	; make our new port current
noFade	brl	top



normal_exit	anop
* Unblank the screen!
	jsr	restore_all

restored_exit	anop
	~DisposeHandle shadowH	; dispose the shadow mem if allocated

	lda	SavedSHADOW
	shortm
	sta	SHADOW
	longm

* Unlock our handles.. (if LMM is on and Screen2Hndl is NULL, it won't hurt)

	~HUnlock Screen1Hndl
	~HUnlock Screen2Hndl

	_SetPort	; old port already on stack
	~ClosePort #OurPort
	_SetMasterSCB	; old masterSCB already on stack
	~ShowPen	; Show the pen
	~ShowCursor              ; Show the cursor
	~ShowCursor	; for pointpieceofshitless

* If we're being called from the "blank now" control, skip the beep..

	lda	Local_Parms+oBlankNowFlag
	bne	skipBeep2
	~SysBeep2 #sbSilence+sbScreenUnblanking ; screen unblanking
skipBeep2	anop

	~DisposeHandle module_dp_H ; dispose module's DP page
	jsr	endFont	; if necessary

* restore border color

               shortm
              	lda	CLOCKCTL
	and	#$F0
	ora	1,s
	sta	CLOCKCTL
	pla
               longm

	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	rts



*************************************
restore_all	name
	lda	blank_result+2
	bit	#bmrFadeIn
	bne	fade_in

	lda	Local_Parms+oT2ModuleFlags
	bit	#fFadeIn
	beq	SkipFadeIn1

fade_in	anop
	jsr	blackPalettes	; black out the palettes
	jsr	restSCBs	; restore original SCBs
	jsr	restore_screen	; restore the pixel data
	jsr	fadein_palettes	; fadein the original palettes
	bra	done_restore	; done!

SkipFadeIn1	anop
	jsr	restPals	; restore the palettes
	jsr	restore_screen	; restore the pixel data
	jsr	restSCBs	; restore the SCBs

done_restore	anop
	rts


*************************************
randomize	name
	lda	Local_Parms+oT2ModuleFlags
	sta	old_mFlags

* We should never be able to be called from "blank now" when random mode is on...

;	lda	OptionsFlag	; don't pick a new module
;	bit	#fRandomize	; if random mode is off
;	beq	noRnd
	lda	NumRandModules	; if only one module is selected
	cmp	#1	; then don't load a new one..
	beq	noRnd

               PushWord #reqRandomize
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
               phy
               phy                      ; dataOut (none)
               _SendRequest

	lda	ModuleFlags
	sta	Local_Parms+oT2ModuleFlags

	lda	BlankRtn
	sta	JML_MODULE
	lda	BlankRtn+2
	sta	JML_MODULE+2

noRnd	anop
	rts

*************************************
*************************************
ZERO_BUSY	name

* OR, should I just save BUSYFLG and zero it myself?
* Then no scheduler tasks would get executed..

	stz	BusyDec	; we didn't dec it yet!
dec_again	lda	BUSYFLG	; zero?
	and	#$FF
	beq	DontDec	; yes, so don't dec it..
	jsl	DECBUSY	; dec it (hopefully down to zero)
	inc	BusyDec	; note that we dec'd it
	bra	dec_again	; see if we have to dec it again
DontDec	anop
	rts

*************************************
REST_BUSY	name
	lda	BusyDec	; do we need to inc it at all?
	beq	DontInc
inc_again	jsl	INCBUSY	; inc it back to where it was
	dec	BusyDec
	bne	inc_again	; do we need to inc it again?
DontInc	anop
	rts

*************************************
BusyDec	ds	2

	End
*-----------------------------------------------------------------------------*
BlankDATA	Data
	debug	'BlankDATA'

attr_01	ds	2

blank_flags	ds	2	; flags passed at BlankT2 time

old_mFlags	ds	2	; T2ModuleFlags of last module

blank_result	ds	4

Pal640	dc	h'00 00 00 0F F0 00 FF 0F  00 00 0F 00 F0 0F FF 0F'
Pal320	dc	h'00 00 77 07 41 08 2C 07  0F 00 80 00 70 0F 00 0D'
	dc	h'A9 0F F0 0F E0 00 DF 04  AF 0D 8F 07 CC 0C FF 0F'

JML_MODULE	ds	4	; 5c i3'modulestart'
loadedSetup	ds	2	; boolean. did we load setup now?
shadowH	ds	4	; h to shad scrn if we had to alloc it
SavedSHADOW	ds	2	; original SHADOW softswitch
SavedMasterSCB	ds	2	; original master SCB
module_dp	ds	2	; ptr to module's DP space in bank 1
module_dp_H	ds	4	; handle to module's DP space

FM_dp_handle	ds	4	; handle to FM dp space

MyPortLoc	entry
masterSCB      ds    2                  ; portSCB
ptrToPixImage	ds    4
               dc    i'$A0'             ; byteWidth of each line in image
rect           dc    i'0,0,200'	; boundary rectangle
mode      	ds	2
                                                                               
RgnHandle	ds	4
ErrorHandle	ds	4

OurPort	ds	$AA
Local_Parms	ds	18	; ds Parms_Size
RegularColTbl	ds	32

	End
*-----------------------------------------------------------------------------*
SaveCoreProcs	Start
	Using	BlankDATA
	Using	InitDATA

	DefineStack
buff_norm  	long
buff_aux	long
stkFrameSize   EndLocals
dpr2	word
rtsaddr	word
dpageptr	word
dbank	byte
rtladdr	block 3
dataOut	long
dataIn	long
request	word
result	word


*************************************
save_port_shr	ename

* If shadowing is ON and was _not_ requested through QDII, then override
* the masterSCB, and save 012000-019fff instead...

	lda	SavedSHADOW
	bit	#$08
	beq	qd_shadow	; shadowing on initially

	lda	SavedMasterSCB
	bit	#fUseShadowing
	beq	qd_no_shadow	; shadowing not requested thru QDII

* shadowing was ON and/or requested thru qdii, so save bank $01 SHR only...

qd_shadow	anop

;	lda	#$2000
;	sta	shradr+1
	lda	#$0120
	sta	shradr+2
	bra	save_it

* shadowing was off so save bank $E1 right now..

qd_no_shadow	anop

;	lda	#$2000
;	sta	shradr+1
	lda	#$E120
	sta	shradr+2

;noSpecial	anop
;	~GetPort
;	makeDP
;	ldy	#oPtrToPixImage
;	lda	[3],y
;	tax
;	iny
;	iny
;	lda	[3],y
;	killLdp
;	stx	shradr+1
;	shortm
;	sta	shradr+3
;	longm

save_it	ldx   #$7d00-2           ; Store the screen
savme          txy
shradr	lda   >$E12000,x
	sta   [buff_norm],y
	dex
	dex
	bpl   savme

	jsr	SavePalsSCBs
	rts


*************************************
save_screen	ename

* First save the $8000 byte SHR screen that the current port's ptrToPixImage
* points to..
* Unless shadowing was ON but not allocated thru QDII.  Then save bank 01 SHR.
* Also save the palettes and SCBs to the normal buffer.

	jsr	save_port_shr

* If shadowing is already enabled, then we're done!

	lda	SavedSHADOW
	bit	#$08
	beq	screen_saved

* If Low Memory Mode is on, then we're also done!

	lda	Options2Flag
	bit	#fLowMemoryMode
;	bne	screen_saved
	beq	notdoneyet
screen_saved	rts

notdoneyet	anop
* Else see if we can allocate shadowing for the module to use..
* By this point, shadowing has been determined to be off...

	~FindHandle #$012000
	lda	1,s
	ora	3,s
	beq	notAllocated
	makeDP
	ldy	#4
	lda	[3],y	; get attributes of handle
	pld
	bit	#attrAddr	; is attrAddr set?
	beq	notAllocated	; if not, we can't use this memory..
	lda	3,s
	pha
	lda	3,s
	pha
	_GetHandleSize
	plx
	pla
	bne	screen_saved	;cannotUse	; >=64k
	cpx	#$8000	
	bne	screen_saved	;cannotUse	; handle size too small or big

* If the 01 SHR buffer we allocated at deskShutDown time (purge level 2)
* is still not purged and shadowing is off, then we don't have to save bank 01.

	WordResult
	PushWord #0
	~FindHandle #$012000
	_SetHandleID
	lda	MyID
	ora	#bufferMemAuxID
	cmp	1,s
	bne	notOurAlloc
	plx
	bra	skip_save_shad

notOurAlloc	anop
	plx

* Note that shadowing was previously allocated but was off..
* This means we have to save and restore both banks E1 and 01..

	jsr	save_shadow	; save bank 01

skip_save_shad	~FindHandle #$012000
	makeDP
	ldy	#4
	lda	[3],y
	sta	attr_01
	ora	#attrLocked
	sta	[3],y
	killLdp

	bra	okToUseIt_off

notAllocated	anop
               PushLong #$8000	; result space already on stack
               lda   MyID
               ora   #miscAuxID
               pha
               PushWord #attrNoCross+attrFixed+attrLocked+attrAddr
	PushLong #$012000
               _NewHandle
	plx
	ply
	jcs	screen_saved	;cannotUse

	stx	shadowH
	sty	shadowH+2

* We don't have to save bank 01 now because we just allocated it ourselves!

okToUseIt_off	anop

;* shadowing was off, so bank 01 is probably different than e1, so make them
;* equal so modules don't have to worry about all this crap.
;
;	phb
;	ldx	#$2000	; x= source address
;	txy		; y= dest address
;	lda	#$8000-1	; length minus 1
;	mvn	$E12000,$012000
;	plb

	shortm
	lda	SHADOW
	and	#$F7	; turn on shadowing
	sta	SHADOW
	longm

** BY NOW ** bank e1 == bank 01, Shadowing = ON

okToUseIt_on	anop		
	rts

*-----------------------------------
save_shadow	anop
	ldx   #$7d00-2           ; Store the screen
sav2           txy
	lda   SHADOWSHR,x
	sta   [buff_aux],y
	dex
	dex
	bpl   sav2
	rts

save_normal	anop
	ldx   #$7d00-2           ; Store the screen
sav1           txy
	lda   SHR,x
	sta   [buff_norm],y
	dex
	dex
	bpl   sav1
	rts

	End
*-----------------------------------------------------------------------------*
RestCoreProcs	Start
	Using	BlankDATA
	Using	InitDATA

	DefineStack
buff_norm  	long
buff_aux	long
stkFrameSize   EndLocals
dpr2	word
rtsaddr	word
dpageptr	word
dbank	byte
rtladdr	block 3
dataOut	long
dataIn	long
request	word
result	word


*************************************
rest_port_shr	ename

* If shadowing is ON and was _not_ requested through QDII, then override
* the masterSCB, and restore to 012000-019fff instead...

	shortm
	lda	SHADOW
	longm
;2.0b4	lda	SavedSHADOW
	bit	#$08
;2.0b4	beq	qd_shadow	; shadowing on initially
	bne	qd_no_shadow

;2.0b4	lda	SavedMasterSCB
;2.0b4	bit	#fUseShadowing
;2.0b4	beq	qd_no_shadow	; shadowing not requested thru QDII

* shadowing was ON and/or requested thru qdii, so restore to bank $01 SHR only...

qd_shadow	anop
	lda	#$0120
	sta	shradr+2
	bra	rest_it

* shadowing was off so restore bank $E1 right now..

qd_no_shadow	anop
	lda	#$E120
	sta	shradr+2

rest_it	anop
	ldx   #$7d00-2           ; Restore the screen
restoreshr     txy
	lda   [buff_norm],y
shradr	sta   >$E12000,x
	dex
	dex
	bpl   restoreshr
	rts


*************************************
restore_screen	ename

* First restore the $8000 byte SHR screen that the current port's ptrToPixImage
* points to..
* Unless shadowing was ON but not allocated thru QD2. Then restore bank 01 SHR.

	jsr	rest_port_shr

* If Low Memory Mode is on, then we're also done!

	lda	Options2Flag
	bit	#fLowMemoryMode
	bne	screen_restored

* If we allocated shadow memory, then we're done.
* (We don't have to save and restore it..)

	lda	shadowH
	ora	shadowH+2
	bne	screen_restored

* If shadowing was initially enabled, then we're done!

	lda	SavedSHADOW
	bit	#$08
	beq	screen_restored

* By process of elimination, shadowing was initially off but allocated.
* Therefore we must restore bank 01, after turning off shadowing.

	shortm
	lda	SHADOW
	longm
	bit	#$08
	bne	screen_restored

	shortm
	lda	SHADOW
	ora	#$08	; turn off shadowing
	sta	SHADOW
	longm

* If the 01 SHR buffer we allocated at deskShutDown time (purge level 2)
* is still not purged and shadowing is off, then we don't have to
* restore bank 01 shr.

	WordResult
	PushWord #0
	~FindHandle #$012000
	_SetHandleID
	lda	MyID
	ora	#bufferMemAuxID
	cmp	1,s
	bne	notOurAlloc
	plx
	bra	skip_rest_shad

notOurAlloc	anop
	plx
	jsr	restore_shadow

skip_rest_shad	anop
	~FindHandle #$012000
	makeDP
	ldy	#4
	lda	attr_01
	sta	[3],y
	killLdp

screen_restored rts

*------------------------------------
restore_shadow	anop
	ldx   #$7d00-2           ; If shadowing is off or if it wasn't
rs01           txy       	; requested through QuickDraw, then
	lda   [buff_aux],y        ; restore the screen to bank $E1.
	sta   SHADOWSHR,x
	dex
	dex
	bpl   rs01
	rts

;restore_normal	anop
;	ldx   #$7d00-2           ; If shadowing is off or if it wasn't
;nextRest0      txy       	; requested through QuickDraw, then
;	lda   [buff_norm],y        ; restore the screen to bank $E1.
;	sta   SHR,x
;	dex
;	dex
;	bpl   nextRest0
;	rts

	End
*-----------------------------------------------------------------------------*
SetupCoreProcs	Start
	Using	BlankDATA
	Using	InitDATA
	Using	RequestDATA


*************************************
load_setup	ename
	stz	loadedSetup	; indicate setup was not loaded

* If we're being called from the "blank now" control, force Load & Unload Setup

	lda	Local_Parms+oBlankNowFlag ; force load setup?
	bne	loadSetup   	; YES.

	lda	Local_Parms+oT2ModuleFlags
	bit	#fLoadSetupBlank
	bne	loadSetup
	bit	#fLoadSetupBoot
	jne	noLoadSetup

* if t2 volume is non-removable then load setup now - 1.0d38
* otherwise it has already been loaded

	lda	nonremovableT2Vol
	jeq	noLoadSetup	

;	lda	pVolume_deviceID
;	cmp	#5	; SCSI hard disk
;	jne	noLoadSetup
loadSetup	anop

	lda	#TRUE
	sta	loadedSetup	; indicate setup was loaded

	~GetCurResourceFile
	~GetCurResourceApp
	jsr	open_t2_prefs

* Tell module to load setup data now.

	lda	OptionsFlag
	bit	#fNoSound
	bne	noSound
	lda	#lmiOverrideSound
	trb	LSFlags	; sound can be used
	bra	goSound
noSound	anop
	lda	#lmiOverrideSound
	tsb	LSFlags	; sound shouldn't be used!
goSound	anop

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #LoadSetupT2    ; T2message = load setup data
	phy
	phy		; reserved [T2data1]
	phy		; T2data2 (hi) is RESERVED
	PushWord LSFlags  	; T2data2 (lo) = flag word (see G2mF)
	jsl	JML_Module
	plx		; get new lmr flags
	stx	Local_Parms+oLSResult
	ply
	sty	Local_Parms+oLSResult+2

* IF we're being called from blank now, then don't make the new lmr
* "permanent"...

	lda	Local_Parms+oBlankNowFlag
	bne	noMakePermanent

	stx	LSResult
	sty	LSResult+2
noMakePermanent anop

	jsr	close_t2_prefs
	_SetCurResourceApp
	_SetCurResourceFile

noLoadSetup	anop
	rts


*************************************
unload_setup	ename
	lda	loadedSetup
	beq	just_exit

	~GetCurResourceFile
	~GetCurResourceApp
	jsr	open_t2_prefs

* Tell the module to unload setup data NOW.

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #UnloadSetupT2	; T2message = unload setup data
	phy
	phy		; reserved [T2data1]
	phy		; T2data2 hi is RESERVED
	phy		; reserved [T2data2 - lo]
               jsl   JML_MODULE	; run it
               plx
               plx                      ; T2result = reserved

	jsr	close_t2_prefs
	_SetCurResourceApp
	_SetCurResourceFile

just_exit	rts


*************************************
open_t2_prefs	entry

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
	dbrk	$ea
	stz	PrefErrCode
	bra	NoPrefErr

alreadyOpen	anop
	lda	Local_Parms+oPrefRezAppID
	beq	skipApp
	~SetCurResourceApp Local_Parms+oPrefRezAppID
skipApp	~SetCurResourceFile Local_Parms+oPrefRezFileID

NoPrefErr	anop
	clc
	rts


*************************************
close_t2_prefs	entry
	lda	PrefErrCode
	bne	skipClose
	~CloseResourceFile PrefFileID
	errorbrk
skipClose	anop
	rts


	End
*-----------------------------------------------------------------------------*
PaletteCoreProcs Start
	Using	BlankDATA
	Using	InitDATA


*************************************
mcp	ename

* do we need to set the most common palette?

	lda	Local_Parms+oLSResult
	bit	#lmrMostCommonPalette
	bne	yes_mcp

	lda	Local_Parms+oT2ModuleFlags
	bit	#fMostCommonPalette
	beq	mcpSkip

yes_mcp	anop
	ldx	#16-2	;Clear palette-use counts
	txa		;CLEAR HIGH BYTE OF A!
clrcnt	stz	palcnt,x
	dex
	dex
	bpl	clrcnt

	shortm
	ldy	#200-1	;Find most common palette:
cntpals	tyx
	lda	>$E19D00,x	;Read an SCB
	and	#$0F	;Only keep palette part
	tax
	inc	palcnt,x	;Count this palette
	dey
	bpl	cntpals	;->Not yet, keep counting

	ldx	#0015	;Start with last palette
	lda	#0	;Anything beats 0
find	cmp	palcnt,x	;This palette used more?
	blt	newpal	;->Yes, new "best" palette
	bne	nxtpal	;->No (greater than)
newpal	lda	palcnt,x	;Get new "best" count
	txy		;This is new "best"
nxtpal	dex
	bpl	find	;->Keep looking
	sty	palcnt	;This is the "best" palette
	sty	palcnt+1

	longm
	ldx	#200-2
setpal	lda	>$E19D00,x
	and	#$F0F0	;Kill palette info
	ora	palcnt	;Mask in "best" palette
	sta	>$E19D00,x
	dex
	dex
	bpl	setpal	;->Set all palettes

mcpSkip	rts       

palcnt	ds	16

*************************************
fade_out	ename

* Do we need to fade out?

	lda	Local_Parms+oLSResult
	bit	#lmrFadeOut
	bne	doIt

	lda	Local_Parms+oT2ModuleFlags
	bit	#fFadeOut
	beq	SkipFadeOut

doIt	PushWord #reqFadeOut
	PushWord #stopAfterOne+sendToUserID
	ldy   #$0000
	phy       	; target (hi)
	lda   MyID
	ora   #requestAuxID
	pha       	; target (lo)
	phy
	phy       	; dataIn (none)
	phy
	phy       	; dataOut (none)
	_SendRequest

	~ClearScreen #0
	~SetAllSCBs #0
	~InitColorTable #RegularColTbl
	~SetColorTable #0,#RegularColTbl
SkipFadeOut	rts


*************************************
fadein_palettes ename

* make destination (i.e. e19e00) palettes black

;	jsr	blackPalettes
;	jsr	restSCBs	; restore original SCBs

* fade in to the original palettes

	jsr	fadeInScreen

	ldy	#0
loped3	phy
	phy		; table #
;	pei	<5
	PushWord #$E1
	tya
	asl	a	; x2
	asl	a	; x4
	asl	a	; x8
	asl	a	; x16
	asl	a	; x32
	clc
;	adc	<3
	adc	#$2000
	adc	#$7E00
	pha		; @SrcTbl
	_SetColorTable
	ply
	iny
	cpy	#16
	blt	loped3
	rts


*************************************
BlackPalettes	ename		; make e1 palettes black
	PushLong NowHndl
	makeDP
	ldy   #4
	lda   [3],y
	ora   #attrLocked        ; lock down the $200byte palette buffer
	sta   [3],y
	dey
	dey
	lda   [3],y              ; and dereference
	tax
	lda   [3]
	sta   <3
	stx   <5

	ldy	#32-2
	lda	#0
zero32	sta	[3],y
	dey
	dey
	bpl	zero32

	lda	#$F
zeroNext	pha
	pha
	pei 5
	pei 3
	_SetColorTable

	pla
	dec	a
	bpl	zeroNext

               lda   NowHndl
	sta   <3
	lda   NowHndl+2
	sta   <5
	ldy   #4
	lda   [3],y
	and   #$7FFF             ; unlock the savedScreen buffer
	sta   [3],y
	killLdp   	;dispose of the screen memory
	rts


*************************************
FadeInScreen	ename
	PushWord #reqFadeIn
	PushWord #stopAfterOne+sendToUserID
	ldy   #$0000
	phy       	; target (hi)
;	tay
	lda   MyID
	ora   #requestAuxID
	pha       	; target (lo)
;	phx
;	phy
	PushLong Screen1Hndl
	jsr	makePdp
	pld		; dataIn
	lda	1,s
	clc
	adc	#$7e00
	sta	1,s
	ldy	#0
	phy
	phy       	; dataOut (none)
	_SendRequest
	rts

	End
*-----------------------------------------------------------------------------*
PortProcs	Start
	Using	BlankDATA
	Using	InitDATA


*************************************
force_grafport	ename

	lda	Local_Parms+oT2ModuleFlags
	bit	#fGrafPort640
	beq	noWant640

	jsr	force640Mode

noWant640	lda	Local_Parms+oT2ModuleFlags
	bit	#fGrafPort320
	beq	wantAnyMode

* Make all lines use 320 mode

	ldx	#200-2
nukeSCBs_320	lda	SCBS,x
	and	#$7F7F
	sta	SCBS,x
	dex
	dex
	bpl	nukeSCBs_320

	~GetMasterSCB
	pla
	and	#$FF7F	; take out 640 mode
	pha
	_SetMasterSCB

	~GetPortLoc #MyPortLoc
	lda	#320
	sta	Mode
	lda	MasterSCB
	and	#$FF7F	; take out 640 mode!
	sta	MasterSCB
	~SetPortLoc #MyPortLoc

	~SetColorTable #$00,#Pal320

	jsr	forcePortMode

WantAnyMode	anop
	rts


*************************************
forcePortMode	name                      

* Set the visRgn equal to the size of the GrafPort so that drawing operations
* don't get clipped.

               ~NewRgn
               PullLong RgnHandle
               _OpenRgn
               ~FrameRect #rect
               ~CloseRgn RgnHandle
               ~SetVisHandle RgnHandle
               ~SetPortRect #rect
	rts


*************************************
force640Mode	ename

;	~SetAllSCBs #$80

* Make all lines use 640 mode

	ldx	#200-2
nukeSCBs	lda	SCBS,x
	ora	#$8080
	sta	SCBS,x
	dex
	dex
	bpl	nukeSCBs

	~GetPortLoc #MyPortLoc
	lda	#640
	sta	Mode
	lda	MasterSCB
	ora	#mode640
	sta	MasterSCB
	~SetPortLoc #MyPortLoc

	ldx	#16-2
setPal0	lda	Pal640,x
	sta	$E19E00,x
	sta	$E19E10,x
	dex
	dex
	bpl	setPal0

	~GetMasterSCB
	pla
;	sta	OrgMasterSCB
	ora	#mode640
	pha
	_SetMasterSCB

	jsr	forcePortMode
	rts

	End
*-----------------------------------------------------------------------------*
SaveRestPalsSCBsProcs Start
	Using	BlankDATA
	Using	InitDATA

	DefineStack
buff_norm  	long
buff_aux	long
stkFrameSize   EndLocals
dpr2	word
rtsaddr	word
dpageptr	word
dbank	byte
rtladdr	block 3
dataOut	long
dataIn	long
request	word
result	word


*************************************
savePalsSCBs	ename

	ldy	#0
looped	phy
	phy		; table #
	pei	<buff_norm+2	5
	tya
	asl	a	; x2
	asl	a	; x4
	asl	a	; x8
	asl	a	; x16
	asl	a	; x32
	clc
	adc	<buff_norm	3
	adc	#$7E00
	pha		; @DestTbl
	_GetColorTable
	ply
	iny
	cpy	#16
	blt	looped

	ldx	#0
	ldy	#$7d00
looped2	anop
	phx
	phy
	WordResult
	phx
	_GetSCB
	pla
	ply
	plx
	shortm
	sta	[buff_norm],y
	longm
	inx
	iny
	cpx	#200
	blt	looped2	
               rts


*************************************
restSCBs	ename
	ldx	#0
	ldy	#$7D00
setthescbs	phx
	phy
	lda	[buff_norm],y
	and	#$00FF
	phx
	pha	
	_SetSCB
	ply
	plx
	inx
	iny
	cpx	#200
	blt	settheSCBs
	rts


*************************************
restPals	ename
	ldy	#0
looped3	phy
	phy		; table #
	pei	<buff_norm+2	5
	tya
	asl	a	; x2
	asl	a	; x4
	asl	a	; x8
	asl	a	; x16
	asl	a	; x32
	clc
	adc	<buff_norm	3
	adc	#$7E00
	pha		; @SrcTbl
	_SetColorTable
	ply
	iny
	cpy	#16
	blt	looped3
	rts

	End
*-----------------------------------------------------------------------------*
Alloc_DP Start
	Using	BlankDATA                ; get module's DP space (1 page)
	Using	InitDATA
	debug	'Alloc DP'	; AV 202005

* Get another handle to give the module it's own direct page.

	LongResult
	PushLong #$100
	lda   MyID
	ora   #moduleDPAuxID
	pha
	PushWord #attrLocked+attrFixed+attrPage+attrBank
	lda   #$0000
	pha
	pha
	_NewHandle
	errorbrk
	makeDP	; IMPLEMENT ERROR HANDLING!!?!!!?
	lda   [3]
	sta	module_dp
	pld
	PullLong module_dp_H
	rts

	End
*-----------------------------------------------------------------------------*
FontMgrProcs	Start
	Using	BlankDATA
	Using	InitDATA


*************************************
startFont	ename
	stz	FM_dp_handle
	stz	FM_dp_handle+2
               ~FMStatus                ;If so, then do we need to start the
               pla                      ;font manager as well?
               beq   doFont
               bcs   doFont
	rts

doFont         anop
               LongResult
	ldy	#0
	phy
	PushWord #$100
               lda   MyID
               ora   #toolAuxID
               pha
               PushWord #attrLocked+attrFixed+attrPage+attrBank
               phy
               phy
               _NewHandle
	makeDP
               lda   [3]
               tay
               pld
	PullLong FM_dp_handle

	lda	MyID
	ora	#toolAuxID
	pha
	phy
	_FMStartUp
	rts


*************************************
endFont	ename
	lda	FM_dp_handle
	ora	FM_dp_handle+2
	beq	jet

	~FMShutDown
	~DisposeHandle FM_dp_handle
jet	rts

	End
*-----------------------------------------------------------------------------*
* DrawString.  V1.00 - 28 May 1992 - coded by Jim Maricondo. (T2 1.0d33)
*
* Internal error module, called when there is an error during normal blanking.
* Just pass it a C-String.  C-String can have up to 1 carriage return. ($0D)
*
* Inputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |     MovePtr     |  Long - Pointer to movement flag.
* |-----------------|
* |   ErrorStrPtr   |  Word - Ptr to c-string with error message. (max 1 CR)
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

DrawString     Start
	Using	BlankDATA
	debug	'DrawString'

	DefineStack
dpageptr       word
dbank          byte
rtlAddr	block	3
ErrorStrPtr	long
MovePtr	long

               phb
               phd
               tsc
               tcd

	stz	anchorDelayPt

* In general, we don't have to worry about saving the old state of QD
* aspects because we're drawing in our own new port.

	~ClearScreen #0
	jsr	force640Mode
	~InitColorTable #RegularColTbl
	~SetColorTable #0,#RegularColTbl

	~LoadSysFont	; make sysFont current

	ldy	#$FFFF
	stz	String2Ptr
	stz	String2Ptr+2
	shortm
parse_loop	iny
	lda	[ErrorStrPtr],y
	beq	doneCRParse
	cmp	#$0D
	bne	parse_loop
	lda	#$00
	sta	[ErrorStrPtr],y	; replace CR with an 00
	iny
	longm
	tya
	clc
	adc	ErrorStrPtr
	sta	String2Ptr
	lda	ErrorStrPtr+2
	sta	String2Ptr+2
doneCRParse	anop
	longm	

               ~MoveTo #0,#0
	peil	ErrorStrPtr
               PushLong #R_top
               _CStringBounds

	lda	String2Ptr
	beq	skip2

               ~CStringBounds String2Ptr,#R3_Top

	lda	r3_top
	eor	#$FFFF
	inc	a
	clc
	adc	r3_bottom
;	stz	r3_top
	sta	r3_bottom
	clc
	adc	r_bottom
	sta	r_bottom

	lda	r3_bottom
	sec
	sbc	#4
	sta	r3_bottom


	lda	r_right
	cmp	r3_right
	bge	skip2
	lda	r3_right
	sta	r_right

skip2	~SetBackColor #0
               ~SetForeColor #$F
               ~SetSolidPenPat #0

loop           anop
               lda   R_top
               clc
               adc   horiz
               sta   r2_top
               lda   R_left
               clc
               adc   vert
               sta   r2_left
               lda   R_Bottom
               clc
               adc   horiz
	inc	a	;new!!
               sta   r2_bottom
               lda   R_Right
               clc
               adc   vert
               sta   r2_right
               PushLong #r2_top
               _PaintRect

	LongResult
	jsl	random
	pha
	lda	#640
	sec
	sbc	r_right
	pha
               _UDivide
               pla
               pla
               sta   vert

	LongResult
	jsl	random
	pha
	lda	#199
	sec
	sbc	r_bottom
	pha
               _UDivide
               pla
               pla
	clc
	adc	r3_bottom
               sta   horiz

               ~MoveTo vert,horiz
               peil	ErrorStrPtr
               _DrawCString

	lda	String2Ptr
	beq	skip4

	PushWord vert
	lda	horiz
	clc
	adc	#9
	pha
	_MoveTo
	~DrawCString String2Ptr

skip4	anop
	ldy	#20	; delay 5 seconds (20 * 1/4)
delayLoop      lda   [MovePtr]
               bne   Exit
	phy
	~WaitUntil anchorDelayPt,#960/4 ; delay 1/4 second
	PullWord anchorDelayPt
	ply
	dey
	bne	delayLoop
               brl   loop

Exit           anop
;	~SetMasterScb OrgMasterSCB

               pld
               plb
               lda   1,s
               sta   1+8,s
               lda   2,s
               sta   2+8,s
	plx
	plx
	plx
	plx
               clc
               rtl

anchorDelayPt	ds	2

r	QDRect
r2	QDRect
r3	QDRect

vert           ds    2
horiz          ds    2

String2Ptr	ds	4

               End
*-----------------------------------------------------------------------------*

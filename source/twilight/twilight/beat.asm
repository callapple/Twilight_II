         setcom 80
	mcopy	beat.mac
	keep	beat
	copy  13:ainclude:e16.control
	copy  13:ainclude:e16.quickdraw
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.memory
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.misctool
	copy	13:ainclude:e16.adb
	copy	13:ainclude:e16.cccp
	copy	equates
	copy	debug.equ
*-----------------------------------------------------------------------------*
* graphics handler

shr_beat	Start
	kind  $1000	; no special memory
               Using InitDATA
	Using	DispatchDATA

	copy	22:debug.asm

               ds	4
shr_beat_count entry
               dc    i'0'
               dc    i'$A55A'

               longa off
               longi off

	debug	'HB:SHR'

               php                      ; save processor status register
               phb                      ; save old DBR
               phk                      ; data bank==code bank
               plb
	longmx

	lda	addSchTask
	beq	noSchTasks
	jsr	doScheduler

noSchTasks	lda   OnFlag             ; Check if twilight is on
               beq   goAbort	; goto end of heartbeat
	lda	ipcT2Off
	bne	goAbort

	lda	TempTurnOff
	beq	noOff
	dec	a
	sta	TempTurnOff
goAbort	brl	abort

noOff	anop
	lda	NEWVIDEO
	bit	#$80
	bne	still_shr

	mvw	#1,text_beat_count	; execute text handler immediately
               plb
               plp
               rtl

splitter	dc	i'0'

still_shr	anop
;	jsr	adb_magic

	lda	splitter
	eor	#1
	sta	splitter
	jeq	MOUSE_STUFF

;	lda	$e12000
;	clc
;	adc	#$1111
;	sta	$e12000

* We're also being used as a timer for the swap module feature.
* After the screen has been blanked, we will count down the time until
* it is time to swap modules.  OK?

	debug	'prob!!'
	lda	swap_count	; are we counting down?
	beq	finished	; no!
	dec	swap_count	; else count down.. (1/2 second)
	bne	finished	; have we reached zero?  no.
	mvw	#TRUE,SwapNow	; indicate that a swap is needed
	inc	KbdChangedFlg
finished	anop

* Check if the cursor is a watchcursor and we're supposed to not blank
* when it's a watch..

	lda	OptionsFlag
	and	#fWatchDontBlank+fWatchNormBlank
	cmp	#fWatchDontBlank
	bne	no_flag
	lda	WaitCursorNow	; don't blank if watchcursor..
	jne	abort

no_flag	anop

* if blanked, skip the blinking box..

               lda   BlankFlag          ; (BlankFlag = 0 if screen is blanked)
               jeq   skipBox

* Do not blink the box if the box was turned off via a T2 EXTERNAL IPC
* request.
* The External IPC handler does not simply clear a bit in OptionsFlag to turn
* off the box when a t2BlinkBoxOff request is received because that would fuck
* with setup and that is not good.
* By using an override flag, we also guarantee that the box will not be turned
* on by any applications if the user has it turned off in setup.

* check for external blink procedure..

	lda	CustomBlinkProc+1
	ora	CustomBlinkProc+2
	beq	noCustomProc

CustomBlinkProc entry
	jsl	>$0

noCustomProc	anop

* check if we should REALLY blink the box..

	lda	BoxOverride
	bne	skipBox

               lda   OptionsFlag        ; don't blink it if we're not supposed
	bit	#fBlinkingBox
               beq   skipBox            ; to

               lda   BUSYFLG            ; Check if system is busy.
               and   #$00FF             ; Is it busy?
               bne   skipBox            ; Yep, so skip the box!

	lda	MenuStatus
	beq	skipBox

	jsr	BLINK_BOX
skipBox	anop

* check for caps lock lock..

	lda   OptionsFlag        ; Caps lock lock on?
	bit	#fCapsLockLock
               beq   noCaps             ; Nope.
               shortm
               lda   KEYMODREG          ; if so, don't change state (blanked
	longm
               bit   #%00000100         ; or unblanked)
               jne   abort	; so abort!
noCaps	anop

** mouse_stuff used to go here **
* (now it's called every other time this interrupt is called)

* if keys were hit, hop to changed (which re-inits the timer to 0, checks
* if the screen must be unblanked, etc.)

	lda	KbdChangedFlg
	bne	changed

* else check if we've already blanked.. (then we're done)

               lda   BlankFlag	; if we're blanked normally
               jeq   abort	;  then we're done
               lda   NowFlag	; if we're blanked now then we're done
               jeq   abort

* else check if it's time to blank..

               inc   BlankTimer	; ELSE: no activity!  closer to blank!
               lda   BlankTimer
               cmp   BlankWait	; time to blank?
               jlt   abort	; no!

* It's time to blank the SHR screen!!!!! Yippee..

* have we received an ipc request to force bkg blanking?

	lda	ForceBkgFlag
	bne	force_bkg1	; yes!

* are we blanking during a watchCursor, and the user wants us to bkg blank?

	lda	OptionsFlag
	and	#fWatchDontBlank+fWatchNormBlank
;	cmp	#fWatchBkgBlank
	bne	no_bkg_flag1
	lda	WaitCursorNow
	bne	force_bkg1	; yes!

no_bkg_flag1	lda	ModuleFlags
	bit	#fInternal
	beq	externalModule
	bit	#fBackground
	beq	externalModule
force_bkg1	anop
	mvw	#TRUE,BkgBlank	; initiate and denote background blank
	mvw	#2+1,NowCount
	brl	cornerOk	; go background blank..

externalModule	anop
	stz	BlankRunQPeriod	; activate first SHR blank runQ
               stz   BlankFlag          ; Indicate that we're blanking
               bra   abort	; we're done! the screen will blank soon

*----------------------
* a key has been hit, or other movement observed
* reset the timer so the screen doesn't blank, and unblank the screen if needed

changed        anop
	stz	KbdChangedFlg	; mark that change has been observed

               lda   #TRUE	; denote that we're not blanked
               sta   NowFlag	; and not blanked now
               sta   BlankFlag

               stz   BlankTimer         ; Reset the timer.
               stz   NowCount	; Reset the now timer.

abort          mvw   #30,shr_beat_count	; most importantly, reset our trigger

	debug	'prob'
	lda	SwapNow	; time to swap modules?
	beq	skipIt
	mvw	#2,BlankFlag	; BlankFlag now = 2 (as per G2MF)
               lda   #TRUE	; denote that we're not blanked
               sta   NowFlag	; and not blanked now
;	DebugBorder

skipIt	anop

absolute_exit	plb
               plp
               rtl


************************************
newMouse	entry
	ds	2
bkgblank	entry
	ds	2
OldCursorPtr	ds	4

************************************
doNoBlankCursor anop
	stz	BlankTimer	; init it back to 0 so we don't blank..

	phx
	phy

	~GetCursorAdr
	pla
	plx
	cmp	Cursor640Ptr
	bne	FirstTime
	cpx	Cursor640Ptr+2
	bne	FirstTime
returnQuick	pla
	pla
	rts

FirstTime	anop
	cmp	Cursor320Ptr
	bne	FirstTime2
	cpx	Cursor320Ptr+2
	beq	returnQuick

FirstTime2	anop
	lda	BUSYFLG
	beq	itsClear
	pla
	pla
	rts

itsClear	anop
	ply
	plx

	lda	$e19d00
	bit	#mode640
	bne	ok640
	txa
	lsr	a
	tax
	PushLong Cursor320Ptr
	makeDP
	tya
	ldy	HotOffset
	sta	[3],y
	iny
	iny
	txa
	sta	[3],y
	pld
	bra	commonCursor

ok640	anop
	PushLong Cursor640Ptr
	makeDP
	tya
	ldy	HotOffset
	sta	[3],y
	iny
	iny
	txa
	sta	[3],y
	pld

commonCursor	anop
	~GetCursorAdr
	PullLong OldCursorPtr

	_SetCursor
	rts

************************************
MOUSE_STUFF	name

;	lda	$e12640
;	clc
;	adc	#$1111
;	sta	$e12640

* ignore the mouse if the screen is blanked, and the right bit is set
* in options

	lda	NowFlag
	beq	scrNowBlanked	; screen is blanked now
	lda	BlankFlag
	bne	scrNotBlanked	; screen is not blanked in any way
scrNowBlanked	lda	OptionsFlag
	bit	#fLetMouseRestore
	jeq	abort
scrNotBlanked	anop

	stz	BkgBlank	; assume non background blank corner

* if internal module, force background blank..

no_bkg_flag	lda	ModuleFlags
	bit	#fInternal
	beq	externalMod
	bit	#fBackground
	beq	externalMod
force_bkg	anop
	mvw	#TRUE,BkgBlank
externalMod	anop

* check for a forced immediate background blank..

	lda	ImmediateBkgBlank
	beq	noImmediate
	stz	ImmediateBkgBlank
	mvw	#TRUE,BkgBlank
	stz	KbdChangedFlg
	brl	doItNow
noImmediate	anop

* if we're supposed to ignore the mouse for a few secs, then do it!

	lda	IgnMouseTime
	beq	noIgnore
	bmi	noIgnore
	dec	a
;	dec	a
	sta	IgnMouseTime
               stz   BlankFlag
               ~GetMouse #NewY          ; Mouse movement?
	jcs	abort	; No mouse data!
               ~LocalToGlobal #NewY
	mvw	NewY,OldY
	mvw	NewX,OldX
;FUCK	DebugBorder
	brl	abort

noIgnore	anop
               ~Button #0               ; Button press?
               pla
	beq	noButton
	inc	KbdChangedFlg	; Yeah!
	brl	abort
noButton	~GetMouse #NewY          ; Mouse movement?
	jcs	abort	; No mouse data!
               ~LocalToGlobal #NewY

	lda	BlankFlag	; if we're blanked, skip the corners?
	jeq	notnow

	lda	CornersFlag
	and	#%111	; isolate top left (bits 0,1,2)
!              cmp   #off
               beq   noUL	;;noCorner
	pha
	lda	#1	; ul
	jsr	CheckSHRCorner
	plx
	tay
	beq	noUL	
	cpx	#blanknow
	beq	go1
               cpx   #bkgblanknow
	beq	dobkg1

	ldx	#1
	ldy	#1
	jsr	doNoBlankCursor
	brl	abort

dobkg1	mvw	#TRUE,BkgBlank	; indicate blank type to be bkg blank now
go1            inc   NowCount
               brl	cornerOk

noUL	anop
	lda	CornersFlag
	and	#%111000000	; isolate top right (bits 6,7,8)
!              cmp   #off|6
               beq   noUR	;;noCorner
	pha
	lda	#2	; ur
	jsr	CheckSHRCorner
	plx
	tay
	beq	noUR
	cpx	#blanknow|6
	beq	go1	;2jj
               cpx   #bkgblanknow|6
	beq	dobkg1	;2jj

	ldy	#1
	ldx	MaxHotX
	jsr	doNoBlankCursor
               brl   abort

noUR	anop
	lda	CornersFlag
	and	#%111000000000	; isolate bottom right (bits 9,a,b)
!              cmp   #off|9
               beq   noLR	;;noCorner
	pha
	lda	#3	; lr
	jsr	CheckSHRCorner
	plx
	tay
	beq	noLR
	cpx	#blanknow|9
	beq	go3
               cpx   #bkgblanknow|9
	beq	dobkg3

	ldx	MaxHotX
	ldy	MaxHotY
	jsr	doNoBlankCursor
	brl	abort

dobkg3	mvw	#TRUE,BkgBlank
go3            inc   NowCount
               bra   cornerOk
	
noLR	anop
	lda	CornersFlag
	and	#%111000	; isolate bottom left (bits 3,4,5)
!              cmp   #off|3
               beq   noCorner
	pha
	lda	#4	; ll
	jsr	CheckSHRCorner
	plx
	tay
	beq	noCorner
	cpx	#blanknow|3
	beq	go3	;4jj
               cpx   #bkgblanknow|3
	beq	dobkg3	;4jj

	ldy	MaxHotY
	ldx	#1
	jsr	doNoBlankCursor
               brl   abort

noCorner       stz   NowCount

* HaveWeChangedTheCursorToOurCursorIndicatingWeAreInADontBlankCorner (kfest '92)

* check if we've changed the cursor to the no blank cursor..

	~GetCursorAdr
	pla
	plx
	cmp	Cursor320Ptr
	bne	keepChecking1
	cpx	Cursor320Ptr+2
	beq	setIt
keepChecking1	cmp	Cursor640Ptr
	bne	cornerOk	; we haven't changed the cursor
	cpx	Cursor640Ptr+2
	bne	cornerOk

setIt	~SetCursor OldCursorPtr	; restore old cursor..

cornerOk       lda   NowFlag	; if we already blank now'd then
               beq   notNow	; don't blank now again!
               lda   NowCount	; enough time elapsed to blank now?
	beq	notNow	; NEU!
doItNow        anop

	stz	KbdChangedFlg	; zero activity flag

	lda	BkgBlank	; foreground or background blank?
	bne	Yes	; background

	stz	BlankRunQPeriod	; activate foreground blank runQ
               stz   BlankFlag          ; Indicate that we're blanking
	bra	different2	; exit

Yes            anop
	stz	NowFlag	; indicate that we're background blanking
	stz	NowBlankRunQPeriod	; activate background blank runQ
	bra	different2	; exit

notNow         anop

* check if mouse has changed..

         	lda   NewX
               cmp   OldX
               bne   different
               lda   NewY
               cmp   OldY
               bne   different
	brl	abort	; mouse hasn't changed..

different	anop		; mouse has changed..
	inc	KbdChangedFlg

different2     mvw   NewX,OldX
               mvw   NewY,OldY
	brl	abort

************************************
BLINK_BOX	name
               ~GetSysBar	; get the menu bar handle
	lda	1,s
	ora	3,s
	bne	ThereIsABar	; not a nil handle (no menu bar)
	ply
	ply
	bra	skip_Box	; nil handle, no menu bar, so skip it
ThereIsABar    jsr   makePdp
               ldy   #oCtlFlag          ; is the menu bar visible?
               lda   [3],y
	killLdp
               bit   #$0080
               bne   skip_Box            ; Skip the box!

itVisible      anop                     ; menu bar visible
         	lda   $E12000+(160*4)+157 ; else flash the box in the menu bar
         	eor   #$FFFF
         	sta   $E12000+(160*4)+157
	lda   $E12000+(160*5)+157
	eor   #$FFFF
	sta   $E12000+(160*5)+157
	lda   $E12000+(160*6)+157
	eor   #$FFFF
	sta   $E12000+(160*6)+157
	lda   $E12000+(160*7)+157
	eor   #$FFFF
	sta   $E12000+(160*7)+157
skip_Box	anop
	rts

               End
*-----------------------------------------------------------------------------*
text_beat	Start
	kind  $1000	; no special memory
               Using InitDATA

               ds	4
text_beat_count entry
               dc    i'0'
               dc    i'$A55A'

               longa off
               longi off

	debug	'HB:Text'

               php                      ; save processor status register
               phb                      ; save old DBR
               phk                      ; data bank==code bank
               plb
	longmx

* do we have to add any scheduler tasks?

	lda	addSchTask
	beq	noSchTasks
	jsr	doScheduler

* check if we are turned off... if so, abort.

noSchTasks	lda   OnFlag             ; Check if twilight is on
               beq   goAbort
	lda	ipcT2Off	; check if we've been deactivated by
	bne	goAbort	; t2TurnOff ipc request
	lda	TempTurnOff	; decrement temporary turnoff flag
	beq	noOff
	dec	a
	sta	TempTurnOff
goAbort	brl	abort
noOff	anop

* Make sure that the SHR screen hasn't been turned on..

	shortm
	lda	NEWVIDEO
	longm
	bit	#$80
	beq	still_txt

* make sure text screen is unblanked and stays so for 1 second

	mvw	#2*1,DontTextBlankDelay
	jsl	later_entry
	stz	DontTextBlankDelay

	stz	text_beat_count	; turn off text handler heartbeat

* if EventMgr and QDII are not active then turn off both heartbeats
* else if they're active then switch to SHR heartbeat (1.0.1b2)

	lda	EventStatus
	beq	neither
	lda	QuickStatus
	bne	yes_shr
neither	anop
	stz	shr_beat_count	; turn off SHR handler
	bra	exit_here
yes_shr	mvw	#1,shr_beat_count	; execute SHR handler immediately
exit_here      plb
               plp
               rtl

later_entry	entry
               php                      ; save processor status register
               phb                      ; save old DBR
               phk                      ; data bank==code bank
               plb
	longmx

still_txt	anop
;	jsr	adb_magic

* Check if we're in P8 and P8 text blanking is off...

	lda   OptionsFlag
	and	#fTextGSOSBlank+fTextDontBlank ; isolate text bits
	cmp	#fTextGSOSBlank
	bne	anytime_txt	; we can text blank anytime? yes.
* We're not supposed to blank in P8, so check if we're in P8...
	tay
	lda	OS_KIND	; 1 = gsos, 0 = p8
	and	#$FF
	bne	gsos
do_abort	brl	abort	; we're in prodos 8, disable text blanking
gsos	tya
anytime_txt	anop

* Check if Text blanking is turned off alltogether..

	cmp	#fTextDontBlank
	beq	do_abort	; if so, abort!

* check for caps lock lock..

	lda   OptionsFlag        ; Caps lock lock on?
	bit	#fCapsLockLock
               beq   noCaps             ; Nope.
               shortm
               lda   KEYMODREG          ; if so, don't change state (blanked
	longm
               bit   #%00000100         ; or unblanked)
               bne	do_abort
noCaps	anop

* decrement don't text blank delay flag, if it's not already zero.
* (used to prevent the text screen from blanking for a period of time, like
* when quitting from P8 to GS/OS)

	lda	DontTextBlankDelay
	beq	skip_dec
	dec	DontTextBlankDelay
skip_dec	anop

* Look at DontTextBlankDelay to see if text blanking is temporarily disabled.

	lda	DontTextBlankDelay
	bne	RestoreTextScr

	~ReadMouse
               pla
               ply
               plx
               bit   #$8000             button down?
               bne   MouseBeingUsed
               tya
               cmp   OldY
               bne   MouseBeingUsed
               txa
               cmp   OldX
               bne   MouseBeingUsed
               stz	newMouse	; ignore
	bra	GoAhead
MouseBeingUsed	sty   OldY
               stx   OldX
RestoreTextScr	mvw	#TRUE,newMouse

GoAhead	anop
	lda	KbdChangedFlg	; any keys been hit?
	ora	newMouse	; mouse been moved?
	bne	changed	; yes, so unblank screen if needed,etc

!	lda	newMouse
!	bne	changed
!	lda	KbdChangedFlg
!	beq	nochange
!	lda	$e00400
!	inc	a
!	sta	$e00400
!	bra	changed
!nochange	anop

               lda   BlankFlag	; if we're blanked, then just ABORT
	beq	abort
               inc   BlankTimer	; no activity!  closer to blank!
               lda   BlankTimer
               cmp   BlankWait
               blt   abort
	brl	BLANK_TEXT_MODE

changed	longmx
	stz	KbdChangedFlg	; mark that change has been observed

! BlankFlag == 0 THEN Screen == blank
! if we're not blanked, then don't try to restore
               lda   BlankFlag          ; If this flag is CLEAR then we're
               jeq   UNBLANK_TEXT_MODE  ; blanked, and should unblank.

               stz   BlankTimer         ; Reset the timer back to 0

abort	longm
	mvw   #30,text_beat_count ; most importantly, reset our trigger
               plb
               plp
               rtl


************************************
BLANK_TEXT_MODE name

	lda	OS_KIND
	and	#$FF
	beq	skip_beep1
	lda	BeepOverride
	bne	skip_beep1
	~SysBeep2 #sbSilence+sbDefer+sbScreenBlanking ; [text] screen is blanking
skip_beep1	anop
	stz	BeepOverride

	shortm
               lda   TBCOLOR
               sta   OldText
               lda   #$00
               sta   TBCOLOR
               lda   CLOCKCTL
               and   #$0F
               sta   OldBorder
               lda   CLOCKCTL
               and   #$F0
               sta   CLOCKCTL

	longa	off
	lda	#0
	sta	TxtClrFlag	;+1

* blank the DHR and LGR and HGR screens by turning on the text screen..

	lda	RDTEXT
	bmi 	text_on
	lda	TXTSET
	lda	#-1	;TRUE
	sta	TxtClrFlag	;ill+1
text_on	anop
               longm

	lda	OS_KIND
	and	#$FF
	beq	skipSch	; we're in prodos 8
;	lda	#FALSE	; make sure ssaScreenBlanking
	stz	ScrewItB+1	; can be sent
	lda	#TRUE	; make sure ssaScreenUnblanking
	sta	ScrewItU+1	; does not get sent
	~SchAddTask #ssaTextBlanked
	plx

skipSch	anop
               stz   BlankFlag
               brl   abort	; screen blanked, get out of here!

************************************
UNBLANK_TEXT_MODE name
	lda	OS_KIND
	and	#$FF
	beq	skip_beep2
	lda	BeepOverride
	bne	skip_beep2

* [text] screen is unblanking

	~SysBeep2 #sbSilence+sbDefer+sbScreenUnblanking
skip_beep2	anop
	stz	BeepOverride
	shortm

               lda   OldText
	bne	notBlack

	longm
* if we're supposed to restore the screen to black on black, then get the
* colors from BRAM instead. [James Smith] v1.0.1b2 12/13/92

	~ReadBParam #dspTxtColor
	~ReadBParam #dspBckColor
	lda	3,s	; get text color
	asl	a	; put it in hi nibble, lo byte
	asl	a
	asl	a
	asl	a
	ora	1,s	; combine it w/ bck color in lo nibble
	plx
	plx		; clean up stack
	shortm
	sta	TBCOLOR
	longm

	~ReadBParam #dspBrdColor
	shortm
	lda	CLOCKCTL
	and	#$F0
	ora	1,s
	sta	CLOCKCTL
	plx		; clean stack
	bra	doNow

	longa	off
notBlack       sta   TBCOLOR
               lda   CLOCKCTL
               and   #$F0
               ora   OldBorder
               sta   CLOCKCTL
doNow          anop

	longa	off
	lda	TxtClrFlag	;#0 ; txtClrFill
	beq	textWasOn
	lda	TXTCLR
	stz	TxtClrFlag
textWasOn	anop
	longm

	lda	OS_KIND
	and	#$FF
	beq	skipSch2	; we're in prodos 8
;	lda	#FALSE	; make sure ssaScreenUnblanking
	stz	ScrewItU+1	; can be sent
	lda	#TRUE	; make sure ssaScreenBlanking
	sta	ScrewItB+1	; does not get sent
	~SchAddTask #ssaTextUnblanked
	plx

skipSch2	anop
	mvw   #TRUE,BlankFlag	; denote that we're NOT blanked
               stz   BlankTimer         ; Reset the timer.
	brl	abort
************************************

               End
*-----------------------------------------------------------------------------*
control_beat   Start
	kind  $1000	; no special memory
               Using InitDATA

               ds	4
control_beat_count entry
               dc    i'2'
               dc    i'$A55A'

               longa off
               longi off

	debug	'HB:Ctl'

               php                      ; save processor status register
               phb                      ; save old DBR
               phk                      ; data bank==code bank
               plb

	inc	blinkTime
	lda	blinkTime
	cmp	#4	;7	;4
	blt	skipBlink
	stz	blinkTime

               lda   BlinkFlag          ; are we blinking the border?
               beq   noBlink	; (to indicate shift-clear)
               lda   CLOCKCTL
               and   #$F0
               ora   BlinkBord
               sta   CLOCKCTL
               stz   BlinkFlag

noBlink        lda   KEYMODREG
               and   #$11	; isolate shift + keypad bits
               cmp   #$11
               bne   notSwtch	; not shift-keypad so exit
               lda   KBD
               cmp   #$18	; control-x
               bne   notSwtch
               lda   OnFlag	; toggle if T2 is temporarily off
               eor   #$FF
               sta   OnFlag
	lsr	a	; put onFlag (boolean) in carry
               lda   #TRUE	; set flag to flash border (YES)
               sta   BlinkFlag
               lda   CLOCKCTL	; save current border color
               and   #$0F
               sta   BlinkBord
               bcc   borderOn	; set which color we'll flash the
               inc   a	; border based on if we're gonna
               inc   a	; turn it off or on
               and   #$0F
               bra   setBord	; ENABLED border color
borderOn       anop
               eor   #$0F	; DISABLED border color
setBord        pha
               lda   CLOCKCTL	; set the appropriate color
               and   #$F0
               ora   1,s
               sta   CLOCKCTL
               pla
skipblink	anop

notSwtch	anop

;	lda	OnFlag
;	beq	skipStuff	
;	lda	BUSYFLG
;	beq	black
;	lda	#$01
;	sta	color+1
;	bra	setIt
;black	lda	#0
;	sta	color+1
;
;setIt	anop
;               lda   CLOCKCTL	; set the appropriate color
;               and   #$F0
;color          ora   #0
;               sta   CLOCKCTL
;skipStuff	anop

* check shr/text

	lda	NEWVIDEO
	longmx
	bit	#$0080
	bne	shr_on

	lda	text_beat_count	; text heartbeat count
	bne	done_enabling

	stz	shr_beat_count	; turn off SHR heartbeat
	mvw	#1,text_beat_count	; activate txt heartbeat right now!
	bra	done_enabling

shr_on	anop
	lda	EventStatus
	beq	nothing

	lda	QuickStatus
	bne	shr_all_good

nothing	stz	shr_beat_count
	stz	text_beat_count
	bra	done_enabling

shr_all_good	anop	
	lda	shr_beat_count	; SHR heartbeat count
	bne	done_enabling

	stz	text_beat_count	; turn off text heartbeat
	mvw	#1,shr_beat_count	; activate SHR heartbeat right now!

	mvw	#2*1,DontTextBlankDelay
	jsl	later_entry
	stz	DontTextBlankDelay

	stz	text_beat_count

done_enabling	anop		

* check kbd

	shortm
	lda	IgnMouseTime	; if we're ignoring the mouse
;	bne	noModifiers	; then ignore modifiers too.
	beq	checkEm
               stz   BlankFlag
	bra	noModifiers

checkEm	lda	BUTN0
	bmi   it_changed
	lda	BUTN1
	bmi	it_changed

               lda   KEYMODREG
               and   #%11011011	; OA, opt, shift, ctrl, repeat, keypad
	beq	noModifiers
it_changed	inc	KbdChangedFlg
	bra	done_check

noModifiers	anop

* if intellikey is on, then don't check KBD...
*
*	lda	OptionsFlag
*	bit	#fUseIntelliKey
*	bne	done_check

* if key pressed, and/or if different than last time then inc

               lda   KBD
               sta   NewKey
	bmi	changed
               cmp   OldKey
               beq	nochange

changed	anop
	inc	KbdChangedFlg
nochange	anop
               lda   NewKey
               sta   OldKey
done_check	anop

* If we just detected a keypress that will end up restoring the text screen,
* restore the text screen NOW so that if the keypress we just hit causes
* the program to change the border color, we won't delay so much that the
* prog changes the border color and then we go and restore the old, now
* incorrect color over the new one! (Don't ask - Greg Templeman convinced
* me to implement this! - d37 Sun 6 Sept 92 10pm)

	lda	KbdChangedFlg
	beq	abort
	lda	NEWVIDEO
	bit	#$80
	bne	abort	; shr is on
	lda	BlankFlag	; already unblanked?
	bne	abort	; if so, skip trying to restore
	jsl	later_entry	; call text hndlr so it can restore now

abort          longm
               mvw   #4,control_beat_count ; (2) most importantly, reset our trigger

	dec	adb_magic_count
	bne	finished
	mvw	#13,adb_magic_count ; 13*4 = every 52/60ths of a second
	jsr	adb_magic
finished	anop

               plb
               plp
               rtl

blinktime	ds	2
adb_magic_count dc	i'13'

               End
*-----------------------------------------------------------------------------*
NowBlankRunQ	Start
	kind  $1000	; no special memory
               Using InitDATA

               ds	4
NowBlankRunQPeriod entry
               dc    i'$FFFF'
               dc    i'$A55A'
               ds    4

NowBlankRunQEntry entry

               phb
               phk
               plb

	mvw	#-1,NowBlankRunQPeriod	; turn it off!

               lda   NowFlag
	bne	abort2_brl

	stz	ssaReturnFlag

	PushWord #ssaSHRBlanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaBackgroundBlank ; dataIn- lo
	PushLong #ssaDataOut	; dataOut
	_SendRequest

	lda	ssaReturnFlag
	bit	#1
abort2	jnel	abort

	lda	BeepOverride
	bne	skip_beep1

* [shr] screen is [background] blanking

	~SysBeep2 #sbSilence+sbScreenBlanking
skip_beep1	anop
	stz	BeepOverride

               PushLong NowHndl
               pha
               pha
               makeDP
               ldy   #4
               lda   [7],y
               ora   #attrLocked        ; lock it down
               sta   [7],y
               dey
               dey
               lda   [7],y
               sta   <5
               lda   [7]
               sta   <3

               ldx   #$200-2
nextPal        txy
               lda   PALETTES,x
               sta   [3],y
               dex
               dex
               bpl   nextPal

               ldy   #4
               lda   [7],y
               and   #$7FFF             ; unlock it.
               sta   [7],y
               killLdp
               pla
               pla

               shortm
               lda   CLOCKCTL
               and   #$0F
               sta   OldBorder
               lda   CLOCKCTL
               and   #$F0
               sta   CLOCKCTL
               longm

               PushWord #reqFadeOut
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

	stz	NowUnBlankRunQPeriod
abort          anop
               plb
               rtl

               End
*-----------------------------------------------------------------------------*
NowUnBlankRunQ	Start
	kind  $1000	; no special memory
               Using InitDATA

               ds	4
NowUnBlankRunQPeriod	Entry
               dc    i'-1'
               dc    i'$A55A'
               ds    4

NowUnBlankRunQEntry entry

               lda   >NowFlag
               jeq   abort

               phb
               phk
               plb

; should this line be above nowflag/abort?

	mvw	#-1,NowUnBlankRunQPeriod	; turn it off!

	PushWord #ssaSHRUnblanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaBackgroundBlank ; dataIn- lo
	ldy	#0
	phy
	phy		; dataOut
	_SendRequest

	lda	BeepOverride
	bne	skip_beep2

	~SysBeep2 #sbSilence+sbScreenUnblanking ; [shr] screen is unblanking
skip_beep2	anop
	stz	BeepOverride

               PushLong NowHndl
               makeDP
               ldy   #4
               lda   [3],y
               ora   #attrLocked        ; lock it down
               sta   [3],y

               PushWord #reqFadeIn
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
	PushLong NowHndl
	jsr	makePdp
	pld		; dataIn
	ldy	#$0000
               phy
               phy                      ; dataOut (none)
               _SendRequest

               ldy   #4
               lda   [3],y
               and   #$7FFF             ; unlock it.
               sta   [3],y
               killLdp

               shortm
               lda   CLOCKCTL
               and   #$F0
               ora   OldBorder
               sta   CLOCKCTL
               longm

               plb
abort          rtl

               End
*-----------------------------------------------------------------------------*
BlankRunQ      Start
	kind  $1000	; no special memory
               Using InitDATA

               ds	4
BlankRunQPeriod entry
       	dc    i'-1'
               dc    i'$A55A'
               ds    4

BlankRunQEntry	ename		;entry

               php
               phb
               phk
               plb
               longmx

	mvw	#-1,BlankRunQPeriod ; turn it off!

               lda   BlankFlag          ; Make sure the blank flag hasn't
               jne   abort              ; changed in the time it took to call
;                                       ; our task
               shortm                   ; Also, make sure interrupts aren't
               lda   2,s                ; disabled, as that would majorly screw
               and   #%00000100         ; things up.
               jne   abort
               longm

	stz	ssaReturnFlag

	PushWord #ssaSHRBlanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaForegroundBlank ; dataIn- lo
	PushLong #ssaDataOut	; dataOut
	_SendRequest

	lda	ssaReturnFlag
	bit	#1
	jne	abort


	mvw	iModuleID,ModuleMemID
	mvw	ModuleFlags,ModuleFlgs
	mvl	BlankRtn,ModuleEntryPt

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

dontDo	anop
	PushWord #ssaSHRUnblanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaForegroundBlank ; dataIn- lo
	ldy	#0
	phy
	phy		; dataOut
	_SendRequest

abort          anop
               plb                      ;yank all of the stuff off of the
               plp                      ;stack and exit
               rtl

               End
*-----------------------------------------------------------------------------*
* Coded: 11 December 1992 JRM T2 v1.0.1b2
doScheduler	Start
	Using	InitDATA
	debug	'doScheduler'

* input: A - addSchTask word.
*          bit 0 = add "addRunQs" scheduler task
*          bit 1 = add "installNDA" scheduler task
*          bit 2 = add "removeNDA" scheduler task

	bit	#1
	beq	done1Sch

	~SchAddTask #addRunQs
	pla
	beq	done1Sch
	lda	#1
	trb	addSchTask
done1Sch	anop

	lda	addSchTask
	beq	noSchTasks
	bit	#2
	beq	done2Sch

	~SchAddTask #InstallNDA
	pla
	beq	done2Sch
	lda	#2
	trb	addSchTask
done2Sch	anop

	lda	addSchTask
	beq	noSchTasks
	bit	#4
	beq	done3Sch

	~SchAddTask #RemoveNDA
	pla
	beq	done3Sch
	lda	#4
	trb	addSchTask
done3Sch	anop

noSchTasks	anop
	rts

               End
*-----------------------------------------------------------------------------*
* Coded: 12 December 1992 JRM T2 T2 v1.0.1b2
* Ignore Flag Checked: 3 Jan 1993 JRM T2 v1.0.1b4
* v4 ADB support Added: 29 Jan 1993 (Thanks G. Templeman) JRM T2 v1.0.1f1
adb_magic	Start
	Using	InitDATA
	debug	'adb magic'

	lda	OptionsFlag
	bit	#fUseIntelliKey
	beq	noKey

	lda	adbVersion
	cmp	#$0006
	beq	rom03
	cmp	#$0004
	beq	rom01
	cmp	#$0005
	bne	noKey	; bad version number! we're not prepared
rom01	mvw	#15,kDataIn	; v4 or v5
	bra	readIt
rom03	anop
	mvw	#22,kDataIn	; v6

readIt	~ReadKeyMicroMemory #kDataOut,#kDataIn,#readMicroMem

	lda	kDataOut
	and	#$FF
	sta	kDataOut

	ldx	IgnMouseTime
	beq	noIgnore
	sta	lastOffset

noIgnore	anop
	cmp	lastOffset
	beq	noKey
	sta	lastOffset

	lda	IgnMouseTime	; neu! 1.1f3!
	bne	noKey

	inc	KbdChangedFlg

!temporary_ok	lda	$e12000
!	clc
!	adc	#$1111
!	sta	$e12000
!	lda	$e10400
!	inc	a
!	sta	$e10400
	
noKey	rts

kDataOut	ds	2
kDataIn	dc	i'22'	; register to read
lastOffset	ds	2

               End
*-----------------------------------------------------------------------------*
* v1.0 (T2 v1.0.1b4) - 16 Jan '93 JRM - Coded

ssaTextBlanked	Start
	kind	$1000
	debug	'ssaTextBlanked'
	Using	InitDATA

screwItB	entry
	lda	#0
	bne	skip_ssaB

	PushWord #ssaTextBlanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaBackgroundBlank ; dataIn- lo
	ldy	#0
	phy
	phy		; dataOut
	_SendRequest
skip_ssaB	rtl

               End
*-----------------------------------------------------------------------------*
* v1.0 (T2 v1.0.1b4) - 17 Jan '93 JRM - Coded

ssaTextUnblanked Start
	kind	$1000
	debug	'ssaTextUnblanked'
	Using	InitDATA

screwItU	entry
	lda	#0
	bne	skip_ssaU

	PushWord #ssaTextUnblanking
	PushWord #sendToName
	PushLong #ssaStr
	PushWord #T2	; dataIn- hi
	PushWord #ssaBackgroundBlank ; dataIn- lo
	ldy	#0
	phy
	phy		; dataOut
	_SendRequest
skip_ssaU	rtl

               End
*-----------------------------------------------------------------------------** cccpRunQ - handle the watchcursor goodies for cccp systems
* v1.0 - 2 Jan 94 - JRM - initial version
*
* $0000 cccpPointer	Cursor is the pointer (arrow) cursor
* $0001 cccpWait	Cursor is the watch cursor or currently animating
* $0002 cccpIBeam	Cursor is the I-Beam cursor
* $0003 cccpCustom	Cursor is animating because of the cccpAnimateCursor request
* $0004 cccpOther	Cursor is an unknown application-specific cursor
*
cccpRunQ	Start
	kind  $1000	; no special memory
               Using InitDATA
	Using	DispatchDATA

               ds	4
cccpRunQPeriod	Entry
               dc    i'60*5'	; every 5 seconds
               dc    i'$A55A'
               ds    4

	lda   >cccpActive
	bne   cccpPresent
	mvw	#-1,>cccpRunQPeriod ; never allow us to be called again!
	brl	abort

cccpPresent	anop
               phb
               phk
               plb

* reset period
	mvw	#60*5,cccpRunQPeriod

	stz	cccpCursorType

               PushWord #cccpGetCursorType
               PushWord #stopAfterOne+sendToName
	PushLong #cccpStr
               ldy   #$0000
               phy
               phy                      ; dataIn (none)
               PushLong #cccpCursorOut	; dataOut
               _SendRequest
	bcs	no_cccp

* $0000 cccpPointer	Cursor is the pointer (arrow) cursor
* $0001 cccpWait	Cursor is the watch cursor or currently animating
* $0002 cccpIBeam	Cursor is the I-Beam cursor
* $0003 cccpCustom	Cursor is animating because of the cccpAnimateCursor request
* $0004 cccpOther	Cursor is an unknown application-specific cursor

	lda	cccpCursorType
	cmp	#cccpWait
	beq	watch_now
	cmp	#cccpCustom
	beq	watch_now
;	lda	#FALSE
	stz	WaitCursorNow

no_cccp	plb
abort          rtl

watch_now	mvw	#TRUE,WaitCursorNow
	plb
	rtl

               End
*-----------------------------------------------------------------------------*

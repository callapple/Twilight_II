         setcom 80
*-----------------------------------------------------------------------------*
DisPatch 	start
	kind  $1000	; no special memory
	debug 'DisPatch'
	Using	InitDATA
	Using	DispatchDATA

*************************************
* Misc. equates

disptch1	equ	$E10000
disptch2	equ	$E10004

	longa	on
	longi on

*************************************
* patch the tool dispatch vector

	phb
	phk
	plb

	ldx	#^MyPatch
	ldy	#MyPatch
	jsr	Install

	~GetVector #bellVector
	pla
	sta	oldBellVect+1
	pla
	shortm
	sta	oldBellVect+3
	longm

	PushLong #BellVectPatch	; source pointer
	LongResult	; destionation handle space
	PushLong #bPatchEnd-bPatchStart
	~GetNewID #$2000	; get new control program ID
	PushWord #attrLocked+attrFixed+attrNoSpec+attrNoCross
	phd
	phd
	_NewHandle
	lda	1,s
	sta	patchH
	lda	1+2,s
	sta	patchH+2	; destination handle
	PushLong #bPatchEnd-bPatchStart ; count
	_PtrToHand

	PushWord #bellVector
	PushLong patchH
	jsr	makePdp
	pld
	_SetVector

	plb
	rtl


*************************************
patchH	ds	4
BellRecursion	entry
	ds	2

	debug	'BellVectPatch'
bPatchStart	anop
BellVectPatch	anop
	php		; +0-
	longmx	; +1-
	pha		; +3-
disablePatch	lda	#0	; +4- t2 still installed?
	bne	skipPatch	; nope.

	jsl	realPatch

skipPatch	anop
	pla
	plp
oldBellVect	jmp	>0
bPatchEnd	anop



realPatch	name
	lda	>NowFlag
	bne	returnY

	lda	>OptionsFlag
	bit	#fSysBeepsUnblank
	beq	returnY	; sysbeeps don't unblank

	lda	>KbdChangedFlg
	inc	a
	sta	>KbdChangedFlg

returnY	rtl



*************************************
RemoveIt	ename

	longa on
	longi	on

	phb
	phk
	plb

	ldx	#^MyPatch
	ldy	#MyPatch
	jsr	Remove
	php		; save carry flag

	PushLong patchH	; invalidate bell patch
	jsr	makePdp
	ldy	#5
	lda	#-1
	sta	[3],y
	killLdp

	plp
	plb
	rtl

*************************************
*************************************

**************************************************
* Name: Install by Greg Templeman
*   Installs the specified tool patch.
* Note: Install doesn't verify you have passed a
*   valid header, so just MAKE SURE YOU DO!
* Note: The patch header must not cross bank
*   boundaries.  While code segments virtually
*   never cross bank boundaries, it is possible to
*   deliberately make one do so (and work), but it
*   won't work here!
* Note: Install assumes that disptch1/disptch
*   already contain JML's.  Pretty safe bet.
**************************************************
* Inputs:
*   A = Unused
*   X = Pointer to patch header, high
*   Y = Pointer to patch header, low
**************************************************
* Outputs:
*   A = scrambled
*   X = scrambled
*   Y = scrambled
*  patchptr: Pointer to patch header
**************************************************
* Volatile:
*  tmptr
*

Install	name

	DefineStack
tmptr	long
patchptr	long
stkFrameSize   EndLocals

               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

	jsr	TPsetup	;Set things up, disable IRQ
* bcs :xt ;->Invalid patch header

	ldx	|disptch1+3	;Get address of first patch (or the actual
	lda	|disptch1+1	; dispatcher if no other patches are installed)
	sec
	sbc	#$0011
	tay
	jsr	ChkPatch	;Anyone else patching the Dispatcher? (sets up tmptr)
	bcc	not1st	;->Yes, we're not the first

yes1st	ldx	#^disptch1-8	;Copy original dispatcher
	ldy	#disptch1-8	; stuff into linked-list
	stx	tmptr+2
	sty	tmptr

not1st	ldy	#$10-2
_loop1	lda	[tmptr],y	;Set up the linked-list
	sta	[patchptr],y
	dey
	dey
	cpy	#8
	bge	_loop1
_loop2	lda	|disptch1,y	;Copy the current patch vectors
	sta	[patchptr],y	; into our patch's header section
	dey
	dey
	bpl	_loop2

	lda	patchptr+1	;Now patch us into the Dispatch vectors
	sta	|disptch1+2
	sta	|disptch2+2	;Set up Dispatch bank bytes
	lda	patchptr
	adc	#$0011	;(c=0 after BGE=BCS fails)
	sta	|disptch1+1	;Set up disptch1
	adc	#$0004	;(c=0 after ADC)
	sta	|disptch2+1	; and finish disptch2

* asl  ;Save carry status
xt	plp		;Re-enable interrupts
* lsr  ;Restore carry status
	plb		;Back to previous bank

	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	rts


**************************************************
* Name: Remove by Greg Templeman
*   Removes the specified (installed) tool patch.
* Note: If an error occurs, your patch has _NOT_
*   been removed.  Under these circumstances, IT
*   IS NOT SAFE TO SHUT DOWN YOUR APPLICATION OR
*   DISPOSE OF ITS MEMORY!  Doing so will leave
*   your tool patch dangling and crash the system.
**************************************************
* Inputs:
*   A = Unused
*   X = Pointer to patch header, high
*   Y = Pointer to patch header, low
**************************************************
* Outputs:
*   A = scrambled
*   X = scrambled
*   Y = scrambled
*   c = SET if error, CLEAR if successful
*  patchptr: Pointer to patch header
**************************************************
* Volatile:
*  tmptr
*

Remove	name
               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

	jsr	TPsetup	;Set things up, disable IRQ
	bcs	_out	;->Uh-oh, something bad's going on...

	lda	patchptr
	adc	#$0011	;(carry is clear after BCS fails)
	sta	patchptr
	cmp	|disptch1+1
	bne	_not1st	;->Not 1st item in list
	lda	patchptr+1
	cmp	|disptch1+2
	bne	_not1st

_1st	ldx	#^disptch1	;There is no previous item in this linked list--
	ldy	#disptch1	; copy our "next items" into the Dispatch vectors
	stx	tmptr+2
	sty	tmptr
	lda	patchptr	;Set up for later
	bra	_remove	;->Remove us from list (c=1 after CMP, BNE fails!)

_not1st	ldx	|disptch1+3	;Get address of first patch (or the actual
	lda	|disptch1+1	; dispatcher if no other patches are installed)
_loop	sec
	sbc	#$0011
	tay
	jsr	ChkPatch	;Check for valid patch (also sets up tmptr)
	bcs	_out
	sep	#$70	;Short mode + set V
	ldy	#3
	lda	[tmptr],y
	tax		;Save bank address
	ldy	#1
	cpx	patchptr+2	;(doesn't change V flag)
	longmx
	bne	_skip	;->Patch not yet found
	clv		;This might be it...
_skip	lda	[tmptr],y
	bvs	_loop	;->Not our patch yet
	cmp	patchptr
	bne	_loop	;->Not our patch yet

_remove	sbc	#$0011	;(c=1 after CMP, BNE fails)
	sta	patchptr	;We've located our patch in
	ldy	#8-2	; the linked list.
_unlink	lda	[patchptr],y	;Now remove it.
	sta	[tmptr],y
	dey
	dey
	bpl	_unlink

	clc		;=No errors
_out	asl	a	;Save carry bit
	plp		;Restore IRQ state
	lsr	a	;Restore carry bit
	plb

	tsc
               clc
               adc   #stkFrameSize
               tcs
	pld
	rts


**************************************************
* Name: TPsetup by Greg Templeman
*   Stores the patch header pointer in patchptr,
* saves the DBR and P-register on the stack (under
* the RTS), then sets the bank to $E1 (the
* dispatcher bank) and disables interrupts.
**************************************************
* Inputs:
*   A = Unused
*   X = Pointer to patch header, high
*   Y = Pointer to patch header, low
**************************************************
* Outputs:
*   A = scrambled
*   X = scrambled
*   Y = scrambled
*   i = Set (interrupts disabled)
*   c = CLEAR if valid patch, SET if invalid patch
*  patchptr: Pointer to patch header
*  tmptr: Pointer to patch header
* Stack:
*  byte: Old data-bank register (DBR)
*  byte: Old processor status register (P)
**************************************************
* Volatile:
*  tmptr
*

TPsetup	pla		;Pull RTS
	stx	patchptr+2
	sty	patchptr
	phb
;	pea	disptch1|-12
	pea	$e1e1
	plb
	plb
	php
	sei		;Important: don't leave interrupts on!
	pha		;Restore RTS

**************************************************
* Name: ChkPatch by Greg Templeman
*   Checks an apparent patch to see if it has the
* correct header format to be a real patch.
**************************************************
* Inputs:
*   A = Unused
*   X = Pointer to patch header, high
*   Y = Pointer to patch header, low
**************************************************
* Outputs:
*   A = scrambled
*   X = scrambled
*   Y = scrambled
*   c = CLEAR if valid patch, SET if invalid patch
*  tmptr: Pointer to patch header
**************************************************
* Volatile:
*

ChkPatch	stx	tmptr+2
	sty	tmptr	;New patch address

	shortmx	;Short mode briefly
	ldy	#16-4	;Check 4 JML's
_check	lda	[tmptr],y
	cmp	#$5C
	bne	_bad2	;->Not a JML, bad header
	tya		;(c=1 after CMP, BNE fails)
	sbc	#4
	tay
	bpl	_check

	ldy	#16
	lda	[tmptr],y	;Get rtl opcode
	cmp	#$6B
	bne	_bad2	;->Not an RTL, bad header
	iny
	longmx	;Back to long mode
	lda	[tmptr],y	;Get phk/pea opcodes
	cmp	#$F44B
	bne	_bad	;->Wrong form, bad header
	lda	tmptr	;(c=1 after CMP, BNE fails)
	adc	#$000F-1	;(c=1, so effectively + $F)
	ldy	#$13
	cmp	[tmptr],y
	clc		;We're done if this compares
	beq	_xt	;->Yes, we're outta here

_bad2	longmx	;(for people entering here)
_bad	sec
_xt	rts


*************************************

MyPatch	anop		;Header for a Dispatcher patch
next1vct	jml	next1vct
next2vct	jml	next2vct
disp1vct	jml	disp1vct
disp2vct	jml	disp2vct
anRTL	rtl

NewDsp1	phk		;Don't change these two lines; they
	pea	anRTL-1	; are required by the patch protocol

NewDsp2	anop
	cpx	#$1406	; postEvent
	beq	T2PostEvent
	cpx	#$0a06
	beq	Go_GNE
;	blt	next2vct
	cpx	#$ca04
	beq	Go_InitC
;	bge	next2vct
	cpx	#$0a12
	beq	Go_WaitC
	cpx	#$8e04
	beq	Go_SetC	

	lda	>NowFlag	; if we haven't bkg blank now'd
	bne	next2vct	; then don't patch out these calls!

*0E04  (FE15B9)  SetColorTable(Tab#,@SrcTab)
*1004  (FE1617)  SetColorEntry(Tab#,Ent#,NewCol)
*0F04  (FE15E8)  GetColorTable(Tab#,@DestTbl)
*1104  (FE164E)  GetColorEntry(Tab#,Ent#):Color

	cpx	#$0E04	; SetColorTable
	beq	Go_SetColTbl
	cpx	#$1004	; SetColorEntry
	beq	Go_SetColEnt
	cpx	#$0F04	; GetColorTable
	beq	Go_GetColTbl
	cpx	#$1104	; GetColorEntry
	beq	Go_GetColEnt

*2C03  (FEBF01)  SysBeep()
*3803  (03BF2F) *%SysBeep2(beepKind)

	cpx	#$2C03	; SysBeep
	beq	Go_SysBeep
	cpx	#$3803	; Sysbeep2
	beq	Go_SysBeep2

	bra	next2vct

*************************************

Go_GNE	bra	T2GetNextEvent
Go_WaitC	brl	T2WaitCursor
Go_InitC	brl	T2InitCursor
Go_SetC	brl	T2SetCursor
Go_SetColTbl	brl	T2SetColorTable
Go_SetColEnt	brl	T2SetColorEntry
Go_GetColTbl	brl	T2GetColorTable
Go_GetColEnt	brl	T2GetColorEntry
Go_SysBeep	brl	T2SysBeep
Go_SysBeep2	brl	T2SysBeep2


*************************************
T2PostEvent	name

rtl1_pe	equ	1
rtl2_pe	equ	rtl1_pe+3
eventMsg_pe	equ	rtl2_pe+3
eventCode_pe	equ	eventMsg_pe+4
result_pe	equ	eventCode_pe+2

* if intellikey is on, skip the postevent patch..

	lda	>OptionsFlag
	bit	#fUseIntelliKey
	bne	next2vct2

	lda	eventCode_pe,s
	cmp	#mouseDownEvt	; 1
	blt	next2vct2
	cmp	#autoKeyEvt+1	; = updateEvt (6)
	bge	next2vct2
	cmp	#4
	bne	pastl
next2vct2	brl	next2vct
pastl	anop

* event codes : will be acted upon
*  mouseDownEvt - 1
*  mouseUpEvt - 2
*  keyDownEvt - 3        (what the fuck happened to 4? :)
*  autoKeyEvt - 5

	lda	#TRUE
	sta	>KbdChangedFlg

* If we just detected a keypress that will end up restoring the text screen,
* restore the text screen NOW so that if the keypress we just hit causes
* the program to change the border color, we won't delay so much that the
* prog changes the border color and then we go and restore the old, now
* incorrect color over the new one! (Don't ask - Greg Templeman convinced
* me to implement this! - d37 Sun 6 Sept 92 10pm)

	lda	NEWVIDEO
	bit	#$80
	bne	shr_on	; shr is on
	lda	NowFlag	; already blanked?
	bne	shr_on	; if no, skip trying to restore
	phx
	jsl	later_entry	; call text hndlr so it can restore now
	plx

shr_on	brl	next2vct


*************************************
T2GetNextEvent	name

	phx
	shortm
	lda	NEWVIDEO
	longm
	and	#$FF
	bit	#$80
	beq	exit_gne	; SHR off!!

	lda	>NowBlankRunQPeriod
	beq	callST
	lda	>NowUnBlankRunQPeriod
	beq	callST
	lda	>BlankRunQPeriod
	bne	exit_gne

callST	_SystemTask

exit_gne	anop
	plx
	brl	next2vct


*************************************
T2WaitCursor	name

	lda	>cccpActive	; if cool cursor is active
	bne	skip_find_adr	; then skip any cursor stuff

	lda	#TRUE
	sta	>nabIt+1

	mvw	#TRUE,>WaitCursorNow

skip_find_adr	brl	next2vct


*************************************
T2SetCursor	name
;	dbrk	02
;	debug	'setC'

rtl1_sc	equ	1
rtl2_sc	equ	rtl1_sc+3
cursorAdr_sc	equ	rtl2_sc+3

	lda	>cccpActive	; if cool cursor is active
	bne	leave	; then skip any cursor stuff

nabIt	lda	#0
	beq	dontNabIt
	mvw	#0,>nabIt+1	; stop nabbing it
	lda	cursorAdr_sc,s
	sta	>WaitCursorAdr
	lda	cursorAdr_sc+2,s
	sta	>WaitCursorAdr+2
	bra	yes_leave

dontNabIt	anop
	lda	cursorAdr_sc,s
	cmp	>WaitCursorAdr
	bne	no_set_waitcursor
	lda	cursorAdr_sc+2,s
	cmp	>WaitCursorAdr+2
	bne	no_set_waitcursor

yes_leave	anop
	mvw	#TRUE,>WaitCursorNow
	bra	leave

no_set_waitcursor anop
	mvw	#FALSE,>WaitCursorNow
leave	brl	next2vct


*************************************
T2InitCursor	name
;	dbrk	03
;	debug	'initC'

	lda	>cccpActive	; if cool cursor is active
	bne	leave	; then skip any cursor stuff

	mvw	#FALSE,>WaitCursorNow
	brl	next2vct


*************************************
* SetColorTable Patch:
* Coded    - October '92    (1.0.1b1)
* Debugged - Dec 4 '92. JRM (1.0.1b2)

T2SetColorTable name

;	lda	>NowFlag	; if we haven't blank now'd
;	jne	next2vct	; then don't patch out the call!

rtl1_sct0	equ	1
rtl2_sct0	equ	rtl1_sct0+3
srctblptr_sct0	equ	rtl2_sct0+3
tblnum_sct0	equ	srctblptr_sct0+4

	lda	tblnum_sct0,s
	cmp	#16
	blt	valid_ok_sct	
	ldx	#badTableNum	
	bra	strip6_return

valid_ok_sct	anop
	phb
	phk
	plb

dbr_sct	equ	1
rtl1_sct	equ	dbr_sct+1
rtl2_sct	equ	rtl1_sct+3
srctblptr_sct	equ	rtl2_sct+3
tblnum_sct	equ	srctblptr_sct+4

	lda	srctblptr_sct+2,s
	pha
	lda	srctblptr_sct+2,s
	pha
	PushLong NowHndl
	jsr	makePdp
	pld
	lda	tblnum_sct+$08,s
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a	; x32 bytes per color table
	clc
	adc	1,s
	sta	1,s
	PushLong #32	; count
	_BlockMove

	ldx	#0	; ignore the call! :-) - no errors
	plb

strip6_return	lda	5,s
	sta	5+6,s
	lda	3,s
	sta	3+6,s
	lda	1,s
	sta	1+6,s
	pla
	pla
	pla
	txa
	cmp	#1
	rtl


*************************************
* SetColorEntry Patch:
* V1.0 - Coded - Dec 4 '92. JRM (1.0.1b2)

T2SetColorEntry name

rtl1_sce0	equ	1
rtl2_sce0	equ	rtl1_sce0+3
newColor_sce0	equ	rtl2_sce0+3
entrynum_sce0	equ	newColor_sce0+2
tblnum_sce0	equ	entrynum_sce0+2

	lda	tblnum_sce0,s
	cmp	#16
	blt	valid_ok1	
	ldx	#badTableNum	
	bra	strip6_return

valid_ok1	anop
	lda	entrynum_sce0,s
	cmp	#16
	blt	valid_ok2	
	ldx	#badColorNum	
	bra	strip6_return

valid_ok2	anop
	phb
	phk
	plb

dbr_sce	equ	1
rtl1_sce	equ	dbr_sce+1
rtl2_sce	equ	rtl1_sce+3
newColor_sce	equ	rtl2_sce+3
entrynum_sce	equ	newColor_sce+2
tblnum_sce	equ	entrynum_sce+2

	lda	tblnum_sce,s
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a	; x32 bytes per color table
	clc
	adc	entrynum_sce,s
	pha

	PushLong NowHndl
	jsr	makePdp

	lda	7,s	; get at phx above
	tay
	lda	newColor_sce+8,s
	sta	[3],y

	killLdp
	ply
	
	ldx	#0	; ignore the call! :-) - no errors
	plb
	brl	strip6_return


*************************************
* GetColorEntry Patch:
* V1.0 - Coded - Dec 4 '92. JRM (1.0.1b2)

T2GetColorEntry name

rtl1_gce0	equ	1
rtl2_gce0	equ	rtl1_gce0+3
entrynum_gce0	equ	rtl2_gce0+3
tblnum_gce0	equ	entrynum_gce0+2
result_gce0	equ	tblnum_gce0+2

	lda	tblnum_gce0,s
	cmp	#16
	blt	valid_ok3	
	ldx	#badTableNum	
	bra	strip4_return

valid_ok3	anop
	lda	entrynum_gce0,s
	cmp	#16
	blt	valid_ok4	
	ldx	#badColorNum	
	bra	strip4_return

valid_ok4	anop
	phb
	phk
	plb

dbr_gce	equ	1
rtl1_gce	equ	dbr_gce+1
rtl2_gce	equ	rtl1_gce+3
entrynum_gce	equ	rtl2_gce+3
tblnum_gce	equ	entrynum_gce+2
result_gce	equ	tblnum_gce+2

	lda	tblnum_gce,s
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a	; x32 bytes per color table
	clc
	adc	entrynum_gce,s
	adc	entrynum_gce,s
	pha

	PushLong NowHndl
	jsr	makePdp

	lda	7,s	; get at phx above
	tay
	lda	[3],y
	sta	result_gce+8,s

	killLdp
	ply
	
	ldx	#0	; ignore the call! :-) - no errors
	plb

strip4_return	lda	5,s
	sta	5+4,s
	lda	3,s
	sta	3+4,s
	lda	1,s
	sta	1+4,s
	pla
	pla
	txa
	cmp	#1
	rtl


*************************************
* GetColorTable Patch:
* V1.0 - Coded - Dec 4 '92. JRM (1.0.1b2)

T2GetColorTable name

rtl1_gct0	equ	1
rtl2_gct0	equ	rtl1_gct0+3
desttblptr_gct0 equ	rtl2_gct0+3
tblnum_gct0	equ	desttblptr_gct0+4

	lda	tblnum_gct0,s
	cmp	#16
	blt	valid_ok_gct	
	ldx	#badTableNum	
	brl	strip6_return

valid_ok_gct	anop
	phb
	phk
	plb

dbr_gct	equ	1
rtl1_gct	equ	dbr_gct+1
rtl2_gct	equ	rtl1_gct+3
desttblptr_gct equ	rtl2_gct+3
tblnum_gct	equ	desttblptr_gct+4

	PushLong NowHndl
	jsr	makePdp
	pld
	lda	desttblptr_gct+2+4,s
	pha
	lda	desttblptr_gct+2+4,s
	pha
	lda	tblnum_gct+8,s
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a	; x32 bytes per color table
	clc
	adc	5,s
	sta	5,s
	PushLong #32	; count
	_BlockMove

	ldx	#0	; ignore the call! :-) - no errors
	plb

	brl	strip6_return

*************************************
T2SysBeep2	name

rtl1_sb2	equ	1
rtl2_sb2	equ	rtl1_sb2+3
beepKind_sb2	equ	rtl2_sb2+3

	lda	beepKind_sb2,s
	and	#$3FFF
	cmp	#sbScreenUnblanking
	beq	ignore
	cmp	#sbScreenBlanking
	beq	ignore
	bra	fakeKey

*************************************
T2SysBeep	name

fakeKey	lda	>OptionsFlag
	bit	#fSysBeepsUnblank
	beq	ignore	; sysbeeps don't unblank

	lda	>KbdChangedFlg
	inc	a
	sta	>KbdChangedFlg

	mvw	#TRUE,>BeepOverride

ignore	anop
	brl	next2vct

	End
*-----------------------------------------------------------------------------*
DispatchDATA	Data
	debug	'DispatchDATA'

WaitCursorNow	dc	i'FALSE'
WaitCursorAdr	ds	4

	End
*-----------------------------------------------------------------------------*

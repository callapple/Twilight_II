* T2 Common Module Equates.  By Jim Maricondo.
* v1.0 - 05/24/92 - Initial Version.
* v1.1 - 05/29/92 - Revised 'cuz of new t2common.rez. - T2 v1.0d33
* v1.2 - 10/24/92 - IPC equates added - T2 v1.0.1b1. - datafield added
* v1.3 - 12/13/92 - mfOverrideSound added - T2 v1.0.1b2
* v1.4 - 01/31/93 - bf bits added. - T2 v1.0.1f2.
* v1.5 - 02/03/93 - (ROJAC!!) new IPC revised - T2 v1.0.1f2
* v1.6 - 02/07/93 - $D001 - T2 v1.0.1f2
* v1.7 - 03/02/93 - bmr, lmr, etc - T2 v1.1f3
* v1.7a - 03/06/93 - bmi, lmi, etc - T2 v1.1f3

* Resources types.

rT2ModuleFlags	gequ	$D001
rT2ExtSetup1 	gequ	$1001
rT2ModuleWord	gequ	$1002	; reztype for module words in T2 setup

* These have been changed to be things on the dp'd stack, so they're
* commented out. Therefore, you will get an error when you first try to
* use them to make sure you change these

* SUBLIMINAL MESSGAE: SEND ME THE ORIGINAL VALUES, JIM! :)

*T2Result	gequ	16
*T2Message	gequ	14
*T2Data1	gequ	10
*T2Data2	gequ	6

* Action message codes sent to modules.

MakeT2	gequ  0	; Make module-specific ctls.
SaveT2	gequ  1		   ; Save new preferences
BlankT2	gequ	2	; Blank the screen.
LoadSetupT2	gequ	3	; Load any resources from yo' fork
UnloadSetupT2	gequ	4	; Dispose of any resources from yo' fk.
KillT2	gequ	5	; Module setup being closed.
HitT2	gequ	6	; Setup window control hit.

* How the stack is setup when a module gets called.

*dp	    gequ	 1		 ; This is how the stack is set up
*Bank	    gequ	 dp+2		 ; with DP at the top and Result
*rtlAddr	    gequ	 Bank+1		 ; occuping the top 4 bytes
*T2data2	    gequ	 rtlAddr+3
*T2data1	    gequ	 T2data2+4
*T2Message	    gequ	 T2data1+4
*T2Result	    gequ	 T2Message+2
*T2StackSize    gequ	 T2Result+4

* Softswitches

KBD	gequ	>$E0C000
KBDSTRB	gequ	>$E0C010
RDVBLBAR	   gequ	>$E0C019		; bit 7 = 1 if not VBL
TBCOLOR	   gequ	>$E0C022
KEYMODREG	   gequ	>$E0C025		; keyboard modifier register
NEWVIDEO	   gequ	>$E0C029
VERTCNT	   gequ	>$E0C02E
SPKR	   gequ	>$E0C030
CLOCKCTL	   gequ	>$E0C034		; border color / rtc register
SHADOW	gequ	>$E0C035
INCBUSYFLG	   gequ	>$E10064		; increment busy flag
DECBUSYFLG	   gequ	>$E10068		; decrement busy flag
SHR	   gequ	>$E12000
SCBS	gequ	>$E19D00
PALETTES	   gequ	>$E19E00

* Boolean logic

FALSE	   gequ	0
TRUE	   gequ	1

* T2 External IPC

t2TurnOn		gequ	$9000
t2TurnOff		gequ	$9001
t2BoxOverrideOff	gequ	$9002
t2BoxOverrideOn	gequ	$9003
t2GetInfo		gequ	$9004
t2StartupTools	gequ	$9005
t2ShutdownTools	gequ	$9006
t2ShareMemory	gequ	$9007
t2SetBlinkProc	gequ	$9008
t2ForceBkgBlank	gequ	$9009
t2BkgBlankNow	gequ	$900A
t2GetBuffers 	gequ	$900B
t2Reserved1		gequ	$900C	; was t2GetVersion
t2CalsFreqOffset	gequ	$900D

* T2 Private IPC

reqDLZSS	gequ	$8007
t2PrivGetProcs	gequ	$9020

* DataField equates.

SetFieldValue	gequ	$8000	   0	0 ;custom control messages that are
GetFieldValue	gequ	$8001		  ; accepted by DataField

* Flag word passed to modules at loadsetupT2 time in T2data2 (lo)
* (lmi = loadMessageInput)
lmiOverrideSound gequ $0001	; bit 0. 1=override sound, 0=sound ok

* Flag word passed to mdoules at blankT2 time in T2Data2 (lo)
* (bmi = blankMessageInput)
bmiBlankNow	gequ	$0001

* bits of BlankT2's T2Result - hi word (blankmessageresult)
bmrNextModule	gequ	$0100
bmrFadeIn	gequ	$0200
bmrLeavesUsableScreen gequ $0400

* bits of LoadSetupT2's T2Result - lo word (loadmessageresult)
lmrReqUsableScreen gequ $0001	; requires usable screen
lmrFadeOut	gequ	$0002	; fade out after all

**********************************
**********************************
**********************************

*
*
* General T2 module code (at least for my modules) by Nathan Mates
* Based heavily on source sent to me by Jim Maricondo; I made functions
* out of a lot of things that got used a lot.
*
* Entry points in your code that need to be supported:
*   DoMakeT2,DoSaveT2,DoBlankT2,DoLoadSetupT2,DoUnloadT2,DoKillT2,DoHitT2
*
* A number of callbacks for common operations are given, with a _2 name.
* See the included codefor their code and use.
*
* Code assumptions:
* 1. You have at most 65535 item IDs in a setup window. Thus, the high word is
*    zero. If you want more, you know enough to make the necessary changes.
* 2. There is only 1 code segment for the blanker.
*    Thus, if you use object-named segments (such as "Label start NukeIraq"),
*    you'll have to delete the names or make all the functions here with your
*    name.
*    This allows:
*       -jsr/rts around in the code
*       -words to be passed around for pointers to things. This is for things
*        like passing pointers to resName strings; the upper word is the
*        current bank.
* 3. You have Orca, and have some understanding of my macros.
*
* You may use this code freely in your modules as long as this source file
* retains my name in it. This is in the CommonData data segment; please don't
* touch it.

* Equates used in here or one of my modules. From the e16.xxx files by
* The Byteworks, Orca/M 2.0 disks. All rights reserved.

attrNoSpec	GEQU	$0008 ; may not use special memory
attrNoCross	GEQU	$0010 ; may not cross banks
singlePtr	GEQU	$0000
rControlTemplate GEQU $8004 ; Control template type
rC1OutputString GEQU $8023 ; GS/OS class 1 output string



Entry	start
	using	CommonData

T2Message	equ	13

	phb		;Store old data bank
	phk
	plb

	phd
	tsc
	sta	EntryStack
	inc	a
	inc	a	;account for phd on stack...
	tcd

	lda	<T2Message	;action code?
	cmp	#7
	bge	GetOut
	asl	a
	tax
	jsr	(Actions,x)
GetOut	lda	EntryStack
	tcs
	pld
	plx		;this form is time-consuming, but bytes
*			;shorter
	ply		;return address & bank
	pla
	pla		;T2data2
	pla
	pla		;T2data1
	pla		;Message
	phy
	phx
	plb
	rtl

Actions	dc	a'DoMakeT2,DoSaveT2,DoBlankT2,DoLoadSetupT2'
	dc	a'DoUnloadSetupT2,DoKillT2,DoHitT2'
	end

*
*
CommonData	data
*
* Common data to be accessed by things. Rename to suit your needs.
*
*
MyID	ds	2	;variables used in various setup stuff...
WindPtr	ds	4
RezFileID	ds	2
temp	ds	4
ResIOType	ds	2
StringPtr	ds	2
extraInfoPtr ds	4
ResValue	ds	2
dfDefProc	ds	4
ThisProgBnk ds	2
ResToLoadID	ds	2
EntryStack	ds	2	;so can get out in hurry from things

*
* Some stuff about the author and all; please don't touch.
*
	dc	c'Common T2 funtions by Nathan Mates. Dedicated '
	dc	c'to Ah-Ram Kim.'	;
	end

*
*
DoBlankT2_2 start
*
*    Beta entry method for BlankT2, one that puts the move ptr on dp 4,
* and gives you the regular DP. (Other functions have the stackframe as
* as a DP). Integrate into DoBlankT2 if you want for speed, but this is for
* all your calls.
*    I was too lazy to re-write one of my programs that uses DP of 0 (hard-
* coded, not equates), so that's why it's at DP 4... :)
*
	using	CommonData

T2Data1	equ	9	;on stacked dp
T2Result	equ	15
MovePtr	gequ	4

	stz	T2Result
	stz	T2Result+2	;clear result ptr...
	ldx	<T2Data1
	ldy	<T2Data1+2
	sty	Temp	;in CommonData
	pla		;return address 1: DoBlackT2
	ply		;return address 2: Setup...
	pld		;Blanker's DP
	phd		;put back on DP to keep everybody happy
	stx	<MovePtr
	ldx	Temp	;other byte
	stx	<MovePtr+2	;change these if you want...
	phy
	pha
	rts
	end

*
*
DoHitT2_2	start
*
* Decides whether a item has been hit based on its item ids. Uses a
* "MaxDHitable gequ [int]"; I use item ids 1-MaxDHitable as items that
* can be hit; MaxDHitable+1->EndDItems are unhitable

* If there are special conditions, or whatever, make your own

T2Data2	equ	5
T2Result	equ	15

	lda	T2data2+2	;ctlID hi word must be zero
	bne	nothingHit
	lda	T2data2	;get ctlID
	cmp	#MaxDHitable
	beq	HitIt
	blt	HitIt
	stz	T2Result	;don't need to make "saveable"
nothingHit	rts

HitIt	lda	#TRUE
	sta	T2Result
	rts
	end

*
*
DoMakeT2_2	start
*
* Entry code for make, which sets up variables that are used in a lot of
* other setup places. If you use any other functions in here related to
* setup and preferences, USE THIS FUNCTION BEFORE OTHERS!!!
*
	using	CommonData
T2Data1	equ	9	;on stacked dp
T2Data2	equ	5	;	"
T2Result	equ	15	;	"

	lda	T2data1+2
	sta	WindPtr+2
	lda	T2data1
	sta	WindPtr
	lda	T2data2
	sta	RezFileID
	lda	#MaxDItemNum ;defined in your source
	sta	T2Result
	phb
	phb		;get the current program bank
	pla
	and	#$FF	;make it 8-bits only
	sta	ThisProgBnk

	PushWord
	_MMStartUp
	PullWord	MyID

	LongResult
	pei	<T2data1+2
	pei	<T2data1
	_GetWRefCon
	PullLong extraInfoPtr

	rts
	end

*
*
LoadCtrlsByID start
*
* Load the controls by a passed in resource ID. This loads the the control
* template with resource ID XXXXYYYY.
*
	using	CommonData

	LongResult
	PushLong	WindPtr
	PushWord	#9	;resource 2 resource
	phx
	phy		;resource ID # (long)
	_NewControl2
	plx
	plx		;chuck result out
	jmp	MainErrChk	;jmp and MainErrChk will do our rts if
*			; it's ok to do so
	end

*
*
MainErrChk	start
*
* Simple Error Handler-- calls SysFailMgr.... Modify as to your liking
*
*
	bcs	UhOh	;UhOh is kinda putting it mildly
	rts

UhOh	pha		;save error # for SysDeath
	PushLong #0	;normal message
	_SysFailMgr	;or brk into GSBug or whatever...
	end

*
*
SetCtlToVal start
*
* Sets a control with ID #0000YYYY to AAAA
* Used a lot.
*
	using	CommonData

	pha		;value to set it to
	LongResult
	PushLong	WindPtr
	PushWord #0	;high word of ID
	phy		;low word of ID
	_GetCtlHandleFromID
	_SetCtlValue
	jmp	MainErrChk	;jmp and MainErrChk will do our rts if
*			; it's ok to do so
	end

*
*
GetACtlVal	start
*
* Gets the value from a control with id #0000YYYY, returns it in the A-register
* The A-Reg is the last thing changed, so tests (beq and all) after this
* function are ok.
*
	using	CommonData

	WordResult
	LongResult
	PushLong WindPtr
	PushWord #0	;high word of ItemID
	phy
	_GetCtlHandleFromID
	_GetCtlValue
	pla
	jmp	MainErrChk	;jmp and MainErrChk will do our rts if
*			; it's ok to do so
	end

*
*
makePdp	start
*
* From Jim Maricondo: Makes a pointer from the handle on the dp, and
* makes a dp for easy access. See its use for details
*

TheHandle	equ   3

	plx		   ; yank return address
	phd
	tsc
	tcd
	ldy   #2
	lda   [TheHandle],y
	tay
	lda   [TheHandle]
	sta   <TheHandle
	sty   <TheHandle+2
	phx		   ; push back return address
	rts
	end

*
*
LoadAPref	start
*
* Loads a preference from disk and handles its not being there.

* Stack Just before Calling
*    Word : In1	Input #1
*    Word : In2	Input #2
*    <Stack Pointer>

* Also: Registers to pass in:
*  AAAA: Resource Type to load
*  XXXX: Pointer to rName pascal string
*  YYYY: Flag whether this is a 1-word resource
*

* YYYY=1 = Not Word Resource
*   In1: Pointer to Function handling resource loaded from disk
*        When called, a pointer to the loaded resource is at
*        DP 3, so lda [3] is the first word of that resource.
*        Take nothing from the stack, put nothing on it, and
*        end with an rts. Also, don't mess with the DP.
*   In2: Pointer to Function handling first time (resource not yet created)
*        Called when the resource told to load is not around.
*        No defined DP, or whatever. End with an rts
*
* YYYY=0 = Word Resource
*   In1: Default value (for when resource is not on disk)
*   In2: Pointer to word variable to store the parameter in (output)
*
* See the included code for details.
*
* On exit, parameters are cleaned up from the stack, and the carry flag is
* set according to whether the resource existed on disk (cc=yes, cs=no)

	using	CommonData
	sta	ResIOType
	stx	StringPtr
	sty	DataType

	phb		;have to define on entry!
	phb		;get the current program bank
	pla
	and	#$FF	;make it 8-bits only
	sta	ThisProgBnk

	LongResult
	PushWord	ResIOType	;resource type
	PushWord ThisProgBnk	;upper word of long pointer
	phx		;lower word of long pointer to rName string.
	_RMLoadNamedResource
	bcc	IsOnDisk	;cc=was on disk...

	plx		;not on disk here
	plx		;remove result from stack...
	ldy	DataType
	bne	NotDiskFcn
	lda	5,s	;default value
	sta	(3,s),y	;Y guaranteed to be 0 coming in here
	bra	DoneNotDisk

NotDiskFcn	per	DoneNotDisk-1 ;"rts" address
	lda	5,s	;"not loaded" function handler
	dec	a	;-1 to make an rts pointer from it
	pha
	rts
DoneNotDisk sec		;flag not on disk...
DoneLoad	pla		;return address
	plx
	plx		;remove
	pha
	rts

IsOnDisk	jsr	MakePDp	;make pointer to loaded resource on stack...
	ldy	DataType
	bne	OnDiskFcn	;passed in function ptr to handle loading
	lda	[3]	;get what the pointer is pointing at
	sta	(9,s),y	;y=0
	bra	DoneDisk	;and handle the rest of the disk access...

OnDiskFcn	per	DoneDisk-1  ;"rts" address
	lda	13,s
	dec	a	;-1 to make a rts pointer from it
	pha
	rts		;rts to the callback
DoneDisk	KillLDp		;pld/pla/pla or similar

	PushWord	#3	;purge level
	PushWord ResIOType	;rtype for release

	LongResult
	PushWord	ResIOType
	PushWord ThisProgBnk	;upper word of long pointer
	PushWord StringPtr
	PushLong	#Temp	;don't care about filenum, but toolbox does
	_RMFindNamedResource	;get it
	_ReleaseResource	;and throw it out. We have a copy now :)
	clc
	bra	DoneLoad	;get out of here...

DataType	ds	2
	end

*
*
SaveAPref	start
*
* Saves a preference to disk, handles its not being there...

* Stack Just before Calling
*    Word : Length of resource
*    Word : In2
*    <Stack Pointer>

* Also: Registers to pass in:
*  AAAA: Resource Type to load
*  XXXX: Pointer to rName pascal string
*

* Based on the Length of the resource, In2 should be:
*   Length=2 (1 word)
*     In2 should be the actual value to store.
*   Length not 2
*     In2 should be a pointer to a function
*     When called, a pointer to where to store the resource is at DP 3.
*     It is your responsibility not to touch the stack, and not write
*     beyond the size you specified for the resource. End your routine
*     with an rts.
*
* See the included code for details.
*
* On exit, parameters are cleaned up from the stack, and the carry flag is
* set according to whether the resource existed on disk (cc=yes, cs=no)

	using	CommonData
	sta	ResIOType
	stx	StringPtr

	phb		;have to define on entry!
	phb		;get the current program bank
	pla
	and	#$FF	;make it 8-bits only
	sta	ThisProgBnk

	LongResult
	PushWord	ResIOType	;resource type
	PushWord ThisProgBnk	;upper word of long pointer
	phx		;StringPtr
	_RMLoadNamedResource
	jcc	HavePrefs1

*			;use trashed result from _RMLoadNamedResource
*			;as space for output from _NewHandle
	PushWord #0	;high word of
	PushWord 11,s	;length of block in bytes
	WordResult
	_GetCurResourceApp
	PushWord	#attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	jsr	MakePdp

	lda	11,s	;length on stack...
	cmp	#2	;word resource?
	bne	FcnPtr1
	lda	9,s	;value to save to disk
	sta	[3]
	bra	FirstTime	;and go about getting out of here

FcnPtr1	per	FirstTime-1
	lda	11,s
	dec	a
	pha
	rts
FirstTime	KillLdp		;pld pla pla. Same # bytes as a jsr...

	PushLong	temp		;handle
	PushWord	#attrNoSpec+attrNoCross	;attr
	PushWord	ResIOType	;rtype
	LongResult
	PushWord	#$FFFF
	PushWord	ResIOType
	_UniqueResourceID
	lda	1,s
	sta	temp
	lda	1+2,s
	sta	temp+2
	_AddResource

	PushWord	ResIOType	;rType
	PushLong	temp		;rID
	PushWord ThisProgBnk	;upper word of long pointer
	PushWord StringPtr
	_RMSetResourceName
	plx		;return address
	pla
	pla		;get stacked stuff off
	phx
	sec		;flag resource wasn't on disk
	rts		;out of here...

HavePrefs1	anop
	jsr	MakePdp
	lda	11,s	;length byte on stack
	cmp	#2
	bne	FcnPtr2
	lda	09,s	 ;value to save to disk
	sta	[3]
	bra	AlreadyThere ;and go about getting out of here

FcnPtr2	per	AlreadyThere-1
	lda	11,s
	dec	a
	pha
	rts
AlreadyThere KillLdp		 ;pld pla pla. Same # bytes as a jsr...

	PushWord	#TRUE	;changeflag:	true
	PushWord	ResIOType	;rtype

	LongResult
	pha		;ResIOType from 2 lines up
	PushWord ThisProgBnk	;upper word of long pointer
	PushWord StringPtr
	PushLong	#Temp	;don't care about filenum, but toolbox does
	_RMFindNamedResource	;get it
	_MarkResourceChange
	plx		;return address
	pla
	pla		;get stacked stuff off
	phx
	rts
	end
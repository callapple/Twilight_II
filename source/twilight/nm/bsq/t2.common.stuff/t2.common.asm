	mcopy	t2.common.macs
	copy	18/e16.t2
	copy	18/e16.memory

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
* See the included code for their code and use.
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
	cmp	#7	;is it outside of the type we know?
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

	ldx	#True	;assume hit something worthwile.
	lda	T2data2+2	;ctlID hi word must be zero
	bne	nothingHit
	lda	T2data2	;get ctlID
	cmp	MaxDHitable
	beq	HitIt
	blt	HitIt
	ldx	#0	;didn't hit anything worthwile; no need to save
HitIt	stx	T2Result
nothingHit	rts
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
	lda	MaxDItemNum ;defined in your source
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
         setcom 80
	mcopy	setup.mac
               copy  tii.equ	; get all the equates
	copy	v1.2.equ
	copy	equates
	copy	cdev.equ
	copy	debug.equ
               copy  13:ainclude:e16.memory
               copy  13:ainclude:e16.types
               copy  13:ainclude:e16.window
               copy  13:ainclude:e16.control
               copy  13:ainclude:e16.resources
               copy  13:ainclude:e16.gsos
               copy  13:ainclude:e16.locator
	copy	13:ainclude:e16.quickdraw
	keep	setup
*-----------------------------------------------------------------------------*
; Special thanks to Jim Murphy for helping with all the auxwindinfo stuffs.
; Special thanks to Dave Lyons too.  "What does tool.setup do on sys 6?" :)
; Special thanks to Matt Deatherage as well.
; Thanks guys!!  I owe ya one.
doSetup        Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
	Using	ListDATA
               debug 'doSetup'

	copy	22:debug.asm

               ~GetMasterSCB
               pla
               bit   #mode640
	bne	okay640

* if we've reached this far in 320 mode then "warning alerts" are on..

       ~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertSetup320Error
	plx
	rts

okay640	anop

;               ~WaitCursor

* If random mode is on then always open setup with corners current
* (versus the intellisetup (tm) handling we normally do)

;	lda	OptionsFlag
;	bit	#fRandomize
;	bne	random_goCorners

* First, if the user double clicked on a module that no setup exists for,
* then open up to corners.

               ~NextMember2 #0,ListHandle ; Get the active member in the list
               pla
	beq	random_goCorners
               LongResult
               dec   a                  ; make it into an offset
               pha
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #13                ; get T2 moduleflags offset
               tay
               PushLong ListPtr
               makeDP
               lda   [3],y
               killLdp
	bit	#fSetup
	bne	supported
openToCorners	anop

* Create an alert (if alert warnings is ON) telling the user that no setup
* exists for that module.

	lda	OptionsFlag
	bit	#fWarningAlerts
	beq	skipWarning	; user doesn't want any warning alerts

 ~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertModuleNoSupportSetup
	pla
	beq	skipWarning	; okay hit
	rts		; cancel hit

random_goCorners anop
skipWarning	lda	#0
	brl	go_simulate	

supported	anop
* If a setup exists for the module double clicked upon, then simulate a
* command-S keypress to activate the setup control.

setup_closed	anop

* The X-th module in the list is the Y-th module to support setup.

               ~NextMember2 #0,ListHandle ; Get the active member in the list
               pla
	dec	a
	pha		; X-th module in the list (base 0)

	stz	curListItem	; current module in the list
	stz	curSetupListItem	; cur modl in the lst supporting setup

go_search	~Multiply curListItem,#ListMemberSize
               pla
               plx                      ; discard hi word of 0000
               adc   #13                ; get T2 moduleflags offset
               tay
               PushLong ListPtr
               makeDP
               lda   [3],y
               killLdp
	bit	#fSetup
	bne	found_a_setup
	inc	curListItem
	bra	go_search

found_a_setup	anop
	lda	curListItem
	cmp	1,s	; have we reached the selected item?
	beq	reached_it	; yes, we're done!
	inc	curListItem	; no, so keep searching
	inc	curSetupListItem
	bra	go_search

reached_it	lda	curSetupListItem
	plx		; clean up stack
	clc
	adc	#$100	; module setup menu item offset

* set the high bit to indicate that there is no old setup to kill
* (i.e. the setup window was previously closed) IF the setup window is closed
* right now.

;               ldx   setupWindOpen
;	beq	go_simulate	; there's an old setup to kill! msboff!
;
;	ora	#$8000	; setup is closed now!  msb on!
go_simulate	sta	SetupAction	; make a note to open this setup first






               lda   setupWindOpen
               beq   notOpenYet

	~SelectWindow SetupWindPtr

	lda	SetupAction
	beq	noSpecificSetup

	jsr	EnableTest

noSpecificSetup anop

;	lda	SetupAction	; find out what to do.
;	beq	nothing	; don't do anything special
;
;               ~GetCurResourceFile      ; save old file
;	lda	RezID
;	bne	setIt
;	brk	$ea
;setIt	~SetCurResourceFile RezID
;
;	lda	SetupAction
;	stz	SetupAction	; kill old setup NOW!!!
;	sta	LastPopID
;	jsr	HandleModuleSetup
;
;	PushWord LastPopID
;	~GetCtlHandleFromID setupWindPtr,#$07FEFFFD
;	_SetCtlValue		
;	
;	_SetCurResourceFile
;nothing	anop
;
;	~InitCursor
	rts

notOpenYet	anop
	~WaitCursor

; Setup the memoryID field in the
; auxWindInfo record..

	mvw	OurRezApp,SetupID

* Open the setup modeless window.

               LongResult               ; Open the setup window
               lda   #$0000
               pha
               pha                      ; ptr to replacement title
               pha
               pha                      ; replacement refCon
               PushLong #ContentDraw    ; ptr to replacement contentDraw proc
               pha
               pha                      ; ptr to replacement window draw proc
               PushWord #refIsResource
               PushLong #T2_Setup_Window
               PushWord #rWindParam1
               _NewWindow2
               lda   1,s
               sta   setupWindPtr
               lda   1+2,s
               sta   setupWindPtr+2
               _SetPort
               ~SetFontFlags #$0004     ; use dithered color text in window...

* Since we're going to be letting this window hang around as a System window,
* we need a NDA-type structure attached to it so we can handle events associated
* with it. To accomplish this, the window first needs an auxWindInfo record so
* we can hook the struct in there. Allrighty?

               ~GetAuxWindInfo setupWindPtr ; get the ptr to the aux info
               PullLong TempPtr

               PushLong #NDAWindStruct  ; [source] here's our default NDA struct

* Get a new fixed block for the NDA struct to tie to this window.

               LongResult
               PushLong #NDAWindStructEnd-NDAWindStruct
               lda   MyID
               ora   #NDAStructAuxID
               pha
               PushWord #attrLocked+attrFixed+attrNoSpec
               phd
               phd
               _NewHandle
               jsr   makePdp
               pld                      ; [destptr] on stack and in Y/A
               tax                      ; in X/Y

* Now attach this NDA structure to the auxWindInfo record where it belongs.

               lda   TempPtr+2
               pha
               lda   TempPtr
               pha
               makeDP                   ; pointer to aux window record
               tya
               ldy   #26                ; nda structure pointer high + 2
               sta   [3],y
               dey
               dey
               txa
               sta   [3],y
               killLdp

               PushLong #NDAWindStructEnd-NDAWindStruct ; copy our defaults
               _BlockMove               ; to the NDA struct

               ~SetSysWindow setupWindPtr ; make it a system window.

* dim the about module control to prevent problems of setup
* and about module using the same icons

	jsr	DimAbout

* Create the very complex popup menu of the T2 generated items plus the module
* names of all the modules supporting configuration.

               jsr   BuildComplexPopup

               mvw   #TRUE,setupWindOpen

	lda	SetupAction	; find out what to do.
	beq	normal	; don't do anything special

* The very first time, when the setup window is opened,
* create the defaultly selected controls.

	sta	LastPopID
	jsr	HandleModuleSetup

	PushWord SetupAction
	~GetCtlHandleFromID setupWindPtr,#T2SetupPopupCtlID
	_SetCtlValue		
	stz	SetupAction
	bra	return

normal	anop		; just pop up corners controls
* dim the test control for internal setup items (corners, options)
	jsr	DimTest

               jsr   T2Corners1stTime
               stz	RezID
	mvw	#$200,LastPopID	; corners menu item ID

return	~InitCursor
               rts

               End
*-----------------------------------------------------------------------------*
BuildComplexPopup Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
               Using ListDATA
               debug 'BuildComplexPopup'

* Ok, the first step we have to do in building our popup on the fly from
* scratch (yes, I am emphasizing that :-) is to load in the "blank" menu
* template in the resource fork.  This template contains only one menu item
* reference; that of NIL to indicate the last menu item in the itemList.
* Now, we are going to get enough room so that we will have enough space
* for NumSupportSetup worth of menu item pointers, + 1 for the NIL that must be
* at the end.
* So we build a new handle in memory with the same control format, but with
* all the space we need for the menu item list.

               LongResult               ; for GetHandleSize
               ~LoadResource #rMenu,#T2SetupModuleMenu
               ~DetachResource #rMenu,#T2SetupModuleMenu ; make the handle ours
               lda   1,s
               sta   PopupMenuHandle
               lda   1+2,s
               sta   PopupMenuHandle+2
               _GetHandleSize           ; size/4
               lda   NumSupportSetup
               asl   a
               asl   a                  ; *4
               adc   1,s                ; plus exisiting resource size
               sta   1,s
               PushLong PopupMenuHandle ; H
               _SetHandleSize

               WordResult
               lda   MyID
               ora   #setupAuxID
               pha
               PushLong PopupMenuHandle
               _SetHandleID             ; new ID
               pla                      ; chuck old id

* Next we load in the control template and patch it so that the menuRef
* is the handle of the structure we were just building above.

               ~LoadResource #rControlTemplate,#T2SetupPopupCtl
               lda   1,s
               sta   PopupCtlHandle
               lda   1+2,s
               sta   PopupCtlHandle+2
               jsr   makePdp
               ldy   #oMenuRef          ; (refIsHandle already)
               lda   PopupMenuHandle
               sta   [3],y
               iny
               iny
               lda   PopupMenuHandle+2
               sta   [3],y
               killLdp

               lda   NumSupportSetup    ; Any modules support setup?
               bne   SomeSupportSetup   ; Some do, yes.

               jsr   makeShortPopup     ; trunicate menu to only T2 cdev items

               stz   ItemTempHandle
               stz   ItemTempHandle+2
               stz   ItemTempPtr
               stz   ItemTempPtr+2
               stz   MenuItemHandle
               stz   MenuItemHandle+2

               brl   makeTheCtl

SomeSupportSetup anop

* Now allocate a block of memory that will house all the menu item templates.

               LongResult

* Multiply NumSupportSetup+1 times menu item rec size of 14 bytes.
	lda	NumSupportSetup
	inc	a
               asl	a	; x2
               pha
               asl	a	; x4
	pha
               asl	a	; x8
               clc
	adc	1,s	; x8+x4 = x12
               adc	3,s	; x12+x2 = x14
               sta	1,s
               lda	#0
               sta	3,s

               lda   MyID
               ora   #setupAuxID
               pha
               PushWord #attrLocked+attrFixed+attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
               lda   1,s
               sta   ItemTempHandle
               lda   1+2,s
               sta   ItemTempHandle+2
               jsr   makePdp
               pld
               PullLong ItemTempPtr

* Now create the itemRefArray.  All the menu item templates are stored back
* to back in the block of memory we just allocated above.  Patch the template
* to reflect these new pointers of the menu items that we're creating.

* First load in the 3 resource based menu items and change them to pointers.

               lda   #0
               jsr   MItemRezToPtr

               lda   #1
               jsr   MItemRezToPtr

               lda   #2	; advanced options (NEU!!!)
               jsr   MItemRezToPtr

               stz   NumDone
               PushLong PopupMenuHandle
               jsr   makePdp
               ldy   #oItemRefArray+8+4
keepGoing      lda   ItemTempPtr
               sta   [3],y
               clc
               adc   #14                ; 14 bytes per record
               sta   ItemTempPtr
               iny
               iny
               lda   ItemTempPtr+2
               sta   [3],y
               iny
               iny
               inc   NumDone
               lda   NumDone
               cmp   NumSupportSetup
               blt   keepGoing
               lda   #$0000
               sta   [3],y
               iny
               iny
               sta   [3],y
               killLdp

* Build ALL the menu item templates on the FLY. (12/21-25/91 by JRM)
* This is a very complex routine.  First load in a blank menu item template
* to model the rest off of.  Then patch the pointers to the item strings,
* and the item IDs, looking at our list control's list structure to find the
* pointers to the strings..

               ~LoadResource #rMenuItem,#T2MenuItem
               PullLong MenuItemHandle

               PushLong ItemTempHandle
               jsr   makePdp
               pld
               lda   1,s
               sta   ItemTempPtr
               lda   1+2,s
               sta   ItemTempPtr+2
               PullLong ItemTempPtr2

* ItemTempPtr will change and point to the start of the current item being
* worked on.
* ItemTempPtr2 will never change and always points to the start of the first
* item.

               stz   NumMItemDone
               stz   NumListDone
keepGoing2     ~HandToPtr MenuItemHandle,ItemTempPtr,#14

               PushLong ItemTempPtr2
               makeDP
             	lda	NumMItemDone
               asl	a	; x2    
               pha
               asl	a	; x4    
	pha
               asl	a	; x8  
               clc
	adc	1,s	; x8+x4 = x12
               adc	3,s	; x12+x2 = x14
               adc   #$02               ; + 2 = oItemID
               plx
               plx
               tay
               lda   NumMItemDone
               clc
               adc   #$0100             ; start with a base of $100.
               sta   [3],y
               pld

               PushLong ListPtr
               makeDP
tryNextListItem ~Multiply NumListDone,#ListMemberSize
               pla
               plx
               sta   listOffset

             	lda	NumMItemDone
               asl	a	; x2    
               pha
               asl	a	; x4    
	pha
               asl	a	; x8  
               clc
	adc	1,s	; x8+x4 = x12
               adc	3,s	; x12+x2 = x14
               adc   #oItemTitleRef
               plx
               plx
               sta   itemOffset         ; put offset into items on stack

               lda   listOffset         ; get offset into list memory
               clc
               adc   #13                ; t2 module flag offset
               tay
               lda   [3],y
               bit   #fSetup
	beq	notSupported
	phy
	tya
	sec
	sbc	#9	; position ourselves at flags byte
	tay
	lda	[3],y
	ply
	and	#$FF	; get flags byte
	cmp	#$60	; disabled & inactive
	bne	supported
notSupported	inc   NumListDone
               lda   NumListDone
               cmp   NumModules
               blt   tryNextListItem

               pld                      ; restore dpr
               plx
               plx                      ; pointer to list item
               plx
               plx                      ; pointer to menu item
               bra   allBuilt

supported      anop
               tya
               sec
               sbc   #13
               tay
               lda   [3],y              ; string ptr
               tax
               lda   itemOffset         ; get offset into item memory
               tay
               txa
               sta   [7],y

               lda   listOffset         ; get offset into list memory
               tay
               iny
               iny
               lda   [3],y              ; string ptr
               tax
               lda   itemOffset         ; get offset into item memory
               tay
               txa
               iny
               iny
               sta   [7],y

               pld                      ; restore dpr
               plx
               plx                      ; pointer to list item
               plx
               plx                      ; pointer to menu item

               lda   ItemTempPtr
               clc
               adc   #14                ; go to next template
               sta   ItemTempPtr
               inc   NumMItemDone
               inc   NumListDone
               lda   NumListDone        ; gone thru whole list?
               cmp   NumModules
               jlt   keepGoing2

allBuilt       anop

* Release the menu item template resource now that we've internally copied
* to elsewhere in memory.

               ~ReleaseResource #3,#rMenuItem,#T2MenuItem

makeTheCtl     anop

* Make the popup control.

               ~NewControl2 setupWindPtr,#singleHandle,PopupCtlHandle
               plx
               plx

* Release the control template handle.

               ~ReleaseResource #3,#rControlTemplate,#T2SetupPopupCtl
               rts

*---------------------------------------------
* Make an itemArray containing only the current three t2 cdev menu items
* (corners + options + advanced options).

MakeShortPopup anop
               lda   #0                 ; turn item #1 into a pointer
               jsr   MItemRezToPtr

               lda   #1                 ; turn item #2 into a pointer
               jsr   MItemRezToPtr

               lda   #2                 ; turn item #3 into a pointer
               jsr   MItemRezToPtr	; NEU!!!

* Make NULL list terminator.

               PushLong PopupMenuHandle
               jsr   makePdp
               ldy   #oItemRefArray+8+4
               lda   #$0000
               sta   [3],y
               iny
               iny
               sta   [3],y
               killLdp
               rts

*---------------------------------------------
* Inputs: A = MItemNumber (base 0)
*
* Given the item number offset into the itemRefArray attached to the resource,
* convert the item at that offset from a resource to a pointer.

MItemRezToPtr  anop
               asl   a
               asl   a
               clc
               adc   #oItemRefArray
               sta   patch1+1
               sta   patch2+1

               PushLong PopupMenuHandle
               jsr   makePdp

* Load in the resource based menu items and change them to pointers.

patch1         ldy   #oItemRefArray     ; (item #x)
               lda   [3],y
               tax
               iny
               iny
               lda   [3],y
               tay

               WordResult
               lda   MyID
               ora   #setupAuxID
               pha

               PushWord #rMenuItem
               phy
               phx

               LongResult
               PushWord #rMenuItem
               phy
               phx
               _LoadResource
               PullLong TempHandle

* Detach it and change it to our ID so that we can dispose of it when the
* window is closed.

               _DetachResource

               PushLong TempHandle
               _SetHandleID             ; new ID
               pla                      ; chuck old id

               PushLong TempHandle
               jsr   makePdp
               pld
patch2         ldy   #oItemRefArray     ; (item #x)
               pla
               sta   [3],y
               iny
               iny
               pla
               sta   [3],y
               killLdp
               rts

               End
*-----------------------------------------------------------------------------*
ContentDraw    Start
	kind  $1000	; no special memory
               debug 'ContentDraw'

               ~GetPort
               _DrawControls
               rtl

               End
*-----------------------------------------------------------------------------*
CloseProc      Start
	kind  $1000	; no special memory
               Using SetupDATA
               Using GlobalDATA
               debug 'CloseProc'

               phb
               phk
               plb

	sta	temp	; save alert flag

               lda   setupWindOpen
	jeq	notOpen

               ~GetCurResourceFile      ; save old file
	lda	RezID
	beq	SetT2ID
	PushWord RezID
	bra	SetFile
SetT2ID	PushWord OurFileNum
SetFile	_SetCurResourceFile

* Update button enabled?

	jsr	GetUpdateHilite
	bcs	updateDisabled

* Preferences weren't saved.  Warn the user?

	lda	OptionsFlag
	bit	#fWarningAlerts
	beq	dontWarn	; nope

	~InitCursor

	lda	temp
	cmp	#$BABE
	bne	closingSetup

* make an alert without cancel..

	~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertWarnPrefsNoSave2
	pla
	beq	dontSave	; don't save (0) clicked on
	jsr	UpdateHit	; save (1) clicked on
	bra	dontSave

closingSetup	~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertWarnPrefsNoSave
	pla
	beq	dontSave  	; don't save clicked on (0)
	cmp	#1
	beq	abortClose	; cancel clicked on (1)
	jsr 	UpdateHit	; save clicked on (2)
	
dontSave	anop
dontWarn	anop
updateDisabled	anop

* Kill the old setup controls (send a KillT2 message to the current
* codeResource being set up) if there are any.

               jsr   KillOldSetup

               PushLong setupWindPtr
               LongResult
               lda   7,s
               pha
               lda   7,s
               pha
               _GetAuxWindInfo

* We have to manually dispose of the NDA structure that's tied to this window.

	makeDP

               LongResult
               ldy   #26
               lda   [3],y
               pha
               dey
               dey
               lda   [3],y
               pha
               _FindHandle
               _DisposeHandle

               killLdp                  ; yank the auxWindRecPtr

               _CloseWindow

               stz   setupWindOpen      ; setup window is closed!

* Re-enable about module control if we're not in random mode.
* (this will never get called in 320 mode)

;	lda	OptionsFlag
;	bit	#fRandomize
;	bne	rModeOn
	jsr	doList
;	jsr	EnableAbout

;rModeOn	anop
* Dispose the memory of all the structures belonging to the popup menu.

               lda   MyID
               ora   #setupAuxID
               pha
               _DisposeAll

* Now enable and disable the blank now and about module controls depending
* on the module selected currently.
* We have to do this again because we disabled the About Module control when
* we opened up the setup window.

;	jsr	doList

abortClose	anop
               _SetCurResourceFile      ; restore original file num.

notOpen        anop
               plb
               rtl

temp	ds	2

               End
*-----------------------------------------------------------------------------*
ActionProc     Start
	kind  $1000	; no special memory
               Using SetupDATA
               debug 'ActionProc'

               phb
               phk
               plb

               cmp   #11                ;do we know about this action code?
               bge   ExitActionProc     ;nope, ignore it

               phx                      ;save possible EventRec ptr
               dec   a                  ;setup the table index
               asl   a
               tax
               pla
               jsr   (ActionTable,x)

ExitActionProc anop
               plb
               rtl

DoIgnore       anop
               rts

ActionTable    anop
               dc    i'DoSetupEvent'    ; NDA Event
               dc    i'DoIgnore'        ; NDA Run
               dc    i'DoIgnore'        ; NDA Cursor
               dc    i'DoIgnore'        ; NDA Menu
               dc    i'DoIgnore'        ; NDA Undo
               dc    i'DoIgnore'        ; NDA Cut
               dc    i'DoIgnore'        ; NDA Copy
               dc    i'DoIgnore'        ; NDA Paste
               dc    i'DoIgnore'        ; NDA Clear
               dc    i'DoIgnore'        ; ? ? ?

               End
*-----------------------------------------------------------------------------*
DoSetupEvent   Start
	kind  $1000	; no special memory
               Using SetupDATA
               Using GlobalDATA
               debug 'DoSetupEvent'

EventRecordPtr equ   $1

               phd
               phy                      ; event record ptr
               pha
               tsc
               tcd

               ~GetCurResourceFile      ; save old file

* Right here the resource searth path will look something like this:
*
* > Control.Panel <
* > Sys.Resources <
*
* [aug 30 '92 note: rezpath may be: twlt.setup, t2, cp nda, sys.rez or similar]
*
* If T2Options or T2Corners or any other "internal" setup is open, then set
* Twilight.II at the top of the search path.
* If an external setup is open (one of the module's setups is selected
* presently), then put that module's resource fork at the top of the search
* path.  This has the side affect of adding Twilight.II as the second deepest
* resource in the search path.

	lda	RezID
	beq	SetT2ID
	PushWord RezID
	bra	SetFile
SetT2ID	PushWord OurFileNum
SetFile	_SetCurResourceFile

	lda	SetupAction
	beq	nothing_special

	lda	SetupAction
	stz	SetupAction	; kill old setup NOW!!!
	sta	LastPopID
	jsr	HandleModuleSetup

	PushWord LastPopID
	~GetCtlHandleFromID setupWindPtr,#T2SetupPopupCtlID
	_SetCtlValue		
	
nothing_special anop

               lda   [EventRecordPtr]   ; get what
               jeq   ExitDoEvent        ; null event, so ignore it
               cmp   #ActivateEvt+1     ; do we support the event?
               jge   ExitDoEvent        ; nope, so exit.

* Copy the non-extended event record passed to us into an extended event rec.

               ldy   #16
copyRecord     tyx
               lda   [EventRecordPtr],y
               sta   SetupTaskRec,x
               dey
               dey
               bpl   copyRecord

	mvl	#$001FFFFF,setupTaskMask

               ~TaskMasterDA #0,#SetupTaskRec
               pla
               cmp   #wInControl
               jne   ExitDoEvent

	lda	SetupTaskData4
	cmp	#T2SetupTestCtlID
	bne	noTestHit
	lda	SetupTaskData4+2
	cmp	#^T2SetupTestCtlID
               bne	noTestHit
               jsr	TestHit
	bra	goExit
noTestHit	anop
               lda   SetupTaskData4     ; ID of pressed control
               cmp   #T2SetupPopupCtlID
               bne   noPopupHit
               lda   SetupTaskData4+2
               cmp   #^T2SetupPopupCtlID
               beq   PopupHit
noPopupHit	anop
	lda	SetupTaskData4
	cmp	#T2SetupUpdateCtlID
	bne	noUpdateHit
	lda	SetupTaskData4+2
	cmp	#^T2SetupUpdateCtlID
               bne	noUpdateHit
               jsr	UpdateHit
goExit	brl	ExitDoEvent
noUpdateHit	anop
	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #HitT2	; T2message = control hit!
  ~GetCtlHandleFromID setupWindPtr,SetupTaskData4 ; T2data1 = handle to ctl hit
               PushLong SetupTaskData4	; T2data2 = ID of ctl hit
               jsl   SetupModuleAdr         ; run it
	pla		; T2result (lo) = boolean:enable update
	plx		; T2result (hi) = must be 0 (reserved)
	cmp	#0
	beq	dontEnable	; FALSE updateflag

* Enable update control.

               PushWord #noHilite
               ~GetCtlHandleFromID setupWindPtr,#T2SetupUpdateCtlID
               _HiliteControl

dontEnable	brl	ExitDoEvent

PopupHit	anop
               WordResult
               ~GetCtlHandleFromId setupWindPtr,#T2SetupPopupCtlID
               _GetCtlValue
               pla
	cmp	LastPopID
	jeq	ExitDoEvent
	ldx	LastPopID
	sta	LastPopID
               cmp   #$100
               jlt   ExitDoEvent        ; $0 thru $FF -> ignore
               cmp   #$300              
               jge   ExitDoEvent        ; $300 thru $FFFF -> ignore
	pha
	phx

* Update button enabled?

	jsr	GetUpdateHilite
	bcs	updateDisabled

* Preferences weren't saved.  Warn the user?

	lda	OptionsFlag
	bit	#fWarningAlerts
	beq	dontWarn	; nope

	~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertWarnPrefsNoSave
	pla
	cmp	#1
	bne	noCancel	; cancel clicked on (1)

	lda	1,s
	sta	LastPopID
;               PushWord LastPopID
               ~GetCtlHandleFromId setupWindPtr,#T2SetupPopupCtlID
               _SetCtlValue

	pla
	bra	abortChange

noCancel	cmp	#0	; don't save clicked on (0)
	beq	dontSave
	jsr 	UpdateHit	; save clicked on (2)
	
dontSave	anop
dontWarn	anop
updateDisabled	anop

	plx
	pla
               cmp   #$200
               bge   T2Internal         ; $200 thru $2FF -> goto T2Internal
	jsr	HandleModuleSetup	; $100 thru $1FF -> external module

* enable the test control for external module setup items

	jsr	EnableTest
	bra	ExitDoEvent

T2Internal     anop
               cmp   #$203
               bge   ExitDoEvent        ; >$202 not supported
               pha

               ~WaitCursor

* dim the test control for internal setup items (corners, options)

               PushWord #inactiveHilite
               ~GetCtlHandleFromID setupWindPtr,#T2SetupTestCtlID
               _HiliteControl

               pla
               cmp   #$201
               beq   itsOptions
	cmp	#$202
	beq	itsOptions2
               jsr   DoT2Corners
               bra   JetFromHere
itsOptions2	anop
	jsr	DoT2Options2
	bra	JetFromHere
itsOptions     anop
               jsr   DoT2Options
JetFromHere    ~InitCursor

abortChange	anop
ExitDoEvent    entry
               _SetCurResourceFile      ; restore original file num.
               pla
               pla
               pld
               rts

               End
*-----------------------------------------------------------------------------*
TestHit	Start
	kind  $1000	; no special memory
	Using SetupDATA
	Using GlobalDATA
	Using FileDATA
	Using	BlankNowDATA
	debug 'TestHit'

	jsr	GetUpdateHilite
	bcs	updateDisabled
	jsr	UpdateHit

updateDisabled	anop

	lda	OptionsFlag
	bit	#fCapsLockLock
	beq	skipWarning	; caps lock lock off
	bit	#fWarningAlerts
	beq	skipWarning	; user doesn't want any warning alerts

               shortm
               lda   KEYMODREG
	longm
               bit   #%00000100
               beq	skipWarning	; caps lock key up

 ~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertCapsLockError
	plx
	rts

skipWarning	anop
                
	mvw	PrefID,PrefRezFileID
	mvw	SetupModuleID,ModuleMemID
	mvl	SetupModuleAdr,ModuleEntryPt
	mvw	lastModuleFlags,ModuleFlgs

* Make sure T2 is active. (i.e. shift clear stuff)
* tell the SHR heartbeat to ignore the mouse for the first 1 second
* blank now (test the module)
* flush all pending key events
* stop ignoring the mouse if the user hit a key before 1 second
* if we had to enable T2, then disable it again to make it like before
                                 
	jsr	SendBlankNow

* make sure the SHR heartbeat isn't ignoring the mouse anymore

	PushLong IgnMouseTimePtr
	makeDP
	lda	#0
	sta	[3]
	killLdp
	rts

               End
*-----------------------------------------------------------------------------*
* GetUpdateHilite - v1.0 - 1 Jan 93 - T2 1.0.1b3 - Jim R Maricondo (tc)
* Check if update button enabled.
* Return carry set if disabled, or carry clear if enabled.

GetUpdateHilite Start
	kind  $1000	; no special memory
	debug	'GetUpdateHilite'
	Using	SetupDATA

               ~GetCtlHandleFromID setupWindPtr,#T2SetupUpdateCtlID
	jsr	makePdp
	ldy	#oCtlHilite
	lda	[3],y
	killLdp
	and	#$00FF
	cmp	#inactiveHilite
	beq	updateDisabled
	clc
	rts

updateDisabled	anop
	sec
	rts

               End
*-----------------------------------------------------------------------------*
UpdateHit      Start
	kind  $1000	; no special memory
               Using SetupDATA
	Using GlobalDATA
	Using FileDATA
               debug 'UpdateHit'

* Send a message to the setup codeResource telling it to update its saved
* configuration data.

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #SaveT2         ; T2message : save setup
	phy
	phy		; reserved [T2data1]
	phy
	phy		; reserved [T2data2]
	jsl   SetupModuleAdr	; run the coderesource
	plx
	plx                      ; T2result = reserved

* Re-disable update control.

dimUpdateCtl	ename
               PushWord #inactiveHilite
               ~GetCtlHandleFromID setupWindPtr,#T2SetupUpdateCtlID
               _HiliteControl
	rts

               End
*-----------------------------------------------------------------------------*
KillOldSetup   Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
               debug 'KillOldSetup'

* first, if we are handling the doubleclick = setup module option, then
* we will be called here with no old setup to kill.  so skip the kill.

	lda	SetupAction	; is there any old setup to kill?
	beq	stuff2kill
	rts

stuff2kill	anop

* Send a message to the setup codeResource telling it to erase and dispose of
* its controls.

               ldy   #1
killLoop       phy
               jsr   KillCtl
               ply
               iny
               cpy   hiCtlID
               blt   killLoop

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #KillT2	; T2message = kill kill!
	phy		
               phy		; T2data1 = reserved
	phy
               phy		; T2data2 = reserved
               jsl   SetupModuleAdr	; run it
               plx
               plx                      ; T2result = reserved

* Make sure we don't try to unload T2Corners and T2Options which are both
* internal.

               WordResult               ; for SetHandleId
               PushWord #0              ; for SetHandleId (don't change id)
               LongResult               ; for FindHandle
               lda   SetupModuleAdr+3
               and   #$00FF
               pha
               lda   SetupModuleAdr+1
               pha
               _FindHandle              ; Get the handle of the module code.
               _SetHandleId
               pla                      ; get the ID of the module code's hndl
               cmp   OurRezApp      ; is it us? (i.e. corners, options)
               beq   skip               ; if yes, don't unload it!

* Set the module's static load segs as purgable, and discard dynamic segments.
* And delete SetupModuleID.

               ~UserShutDown SetupModuleID,#$0000
               plx                      ; chuck memID

	jsr	close_rfork
	sec
	rts

skip	anop

* And lastly, if an external codeResource was loaded (e.g. one of the modules
* was selected, not options or corners which are internal), close the module's
* resource fork.

;	jsr	close_rfork
	clc
	rts

close_rfork	anop
	lda	RezID
	beq	skipClose
	~CloseResourceFile RezID
	errorbrk
	stz	RezID
skipClose      anop
	rts

               End
*-----------------------------------------------------------------------------*
SetupDATA      Data
               debug 'SetupDATA'

curListItem	ds	2
curSetupListItem ds	2

SetupAction	ds	2	; r we to open a specific modl's setup?

hiCtlID	ds	2

LastPopID	ds	2	; menu item id of last selected mitem
SupportNum	ds	2	; used to find module path

SetupModuleID	ds	2

setupWindPtr   ds    4                  ; the windPtr to the setup window
setupWindOpen  boolean FALSE            ; boolean: setup window is open

* extra info!

extraInfo	anop
sDataFieldPtr	ds	4

NDAWindStruct  anop
               dc    i'0'               ; status
               dc    i4'0'              ; openProc
               dc    i4'CloseProc'      ; closeProc
               dc    i4'ActionProc'     ; actionProc
               dc    i4'0'              ; initProc
               dc    i'0'               ; period
 dc i'mDownMask+mUpMask+keyDownMask+autoKeyMask+updateMask+activeMask' ; eventMask
               dc    i4'0'              ; lastServiced
               dc    i4'0'              ; windowPtr
               dc    i4'0'              ; ndaHandle
setupID        ds    2                  ; memoryID
NDAWindStructEnd anop

SetupTaskRec   anop
               ds    2                  ; wmWhat
               ds    4                  ; wmMessage
               ds    4                  ; wmWhen
               ds    4                  ; wmWhere
               ds    2                  ; wmModifiers
               ds    4                  ; wmTaskData
setupTaskMask  dc    i4'$001FFFFF'      ; wmTaskMask
               ds    4                  ; wmLastClickTick
               ds    2                  ; wmClickCount
               ds    4                  ; wmTaskData2
               ds    4                  ; wmTaskData3
setupTaskData4 ds    4                  ; wmTaskData4
               ds    4                  ; wmLastClickPt

* setup handlers

T2result       ds    4
T2data1        ds    4
T2data2        ds    4
SetupHandle    ds    4

* For building the popup control...

MenuItemHandle ds    4                  ; handle of a blank menu item
PopupMenuHandle ds   4                  ; handle of the popup menu
PopupCtlHandle ds    4                  ; handle of the popup control
NumDone        ds    2                  ; number of items processed
ItemTempPtr2   ds    4                  ; start of menu item memory
ItemTempPtr    ds    4                  ; somewhere within menu item memory
ItemTempHandle ds    4                  ; handle to menu item memory

NumListDone    ds    2                  ; number of list records gone thru
NumMItemDone   ds    2                  ; number of menu items gone thru
listOffset     ds    2                  ; current offset into list memory
itemOffset     ds    2                  ; current offset into item memory

lastModuleFlags ds	2	; module currently being setup's flags

               End
*-----------------------------------------------------------------------------*
HandleModuleSetup Start
	kind  $1000	; no special memory
               Using SetupDATA
               Using GlobalDATA
	Using ListDATA
	debug 'HandleModuleSetup'

	pha		; save menuItemID

* First kill the old setup controls (send a KillT2 message to the current
* codeResource being set up) if there are any.

               jsr   KillOldSetup
;	bcc	skipID
;
;               ~GetNewID #$5000         ; Get an ID to InitialLoad2 the module
;               PullWord SetupModuleID   ; to blank now with.

skipID	pla

* Given a menu item ID number, first make it into an offset telling us which
* module with a setup was selected.  If menu item $100 was selected, than we
* know the first module supporting setup was selected, and so on.
* Well, now that we know which setup supporting module (x) was selected, look
* at the list record structure.  Find the Xth module supporting setup, and
* get the handle to the pathname of that module.  Then open the module's rfork,
* load its setup codeResource.

               sec
	sbc	#$100	; make into offset
	inc	a
               pha
	stz	SupportNum
               PushLong ListPtr
               makeDP
               ldy	#13	; T2 module flags offset
FindPathHndl1  lda	[3],y
               bit   #fSetup	; does it support setup?
	sta	lastModuleFlags
               bne	SupportsSetup
KeepLooking    tya
               clc
               adc	#ListMemberSize
               tay
               bra	FindPathHndl1
SupportsSetup  inc	SupportNum
	lda	SupportNum
	cmp	7,s
               beq	FoundTheOne
               bra	KeepLooking
FoundTheOne	anop
	tya
               sec
               sbc	#4	; now at string handle offset
               tay
               lda	[3],y
	tax
               iny
               iny
               lda	[3],y
               killLdp
               ply

	pha		; push hi word of handle
	phx		; push lo word of handle

* Open the module's resource fork for it...

               WordResult	; (parms for OpenResourceFile)
	lda	lastModuleFlags	; get flags word of the selected modl
	bit	#fOpenRForkWriteEnabled
	beq	readEnableOnly
	PushWord #readWriteEnable ; Read/Write file access!
	bra	hop
readEnableOnly	PushWord #readEnable
hop	ldy   #$0000
               phy
               phy                      ; pointer to resource map in memory (NIL)
	lda	11,s	; get hi word of handle
               pha		; push hi word
               phx	                   ; push lo word of handle to C1 pathname
	jsr	makePdp	; make it a pointer
	pld
               _OpenResourceFile
               PullWord RezID

               ~GetNewID #$A000         ; Get an ID to InitialLoad2 the module
               PullWord SetupModuleID   ; to blank now with.

	plx
	pla		; retrieve pathname handle

* Load the module into memory.

               WordResult
               WordResult
               LongResult
               WordResult
	ldy	SetupModuleID
	phy
               pha
               phx	                   ; handle to C1 pathname
	jsr	makePdp	; make it a ptr
	pld
	lda	1,s
	sta	fillPathPtr2+1
	lda	1+2,s
	sta	fillPathPtr1+1
               PushWord #TRUE
               PushWord #1
               _InitialLoad2
               bcc   ValidLoad
               plx
               plx
               plx
               plx
               plx

* Create an alert informing the user that there was an error loading the module

	pha
fillPathPtr1	pea	0
fillPathPtr2	pea	0
	jsr	LoadModuleErr	
               rts

ValidLoad      pla
               pla                      ; store it's address into the
               sta   SetupModuleAdr+1
               pla
               shortm
               sta   SetupModuleAdr+3
               longm
               pla                      ;doBlank routine, so that when it's time
               pla                      ;to blank, it'll be called

SendMakeT2	entry
	debug	'SendMakeT2'

	~SetWRefCon #extraInfo,setupWindPtr

* Send a message to the module telling it to make its setup controls.

	ldy	#0
	phy
	phy		; result space [T2Result]
               PushWord #MakeT2         ; T2message = make the controls
               PushLong setupWindPtr    ; T2data1 = wind ptr
;	lda	MyID
;	ora	#setupAuxID
;	pha		; T2data2 (hi) = mem id
	phy
	PushWord PrefID	; T2data2 (lo) = rezFile ID of prefFile
               jsl   SetupModuleAdr	; run the coderesource
	pla		; T2result (lo) = highest ctlID
	inc	a	; add 1 to get the highest ID + 1
               sta	hiCtlID
               plx                      ; T2result (hi) = reserved

	~SetWRefCon #0,setupWindPtr

* Disable update control.

	jsr	dimUpdateCtl

	~InvalCtls SetupWindPtr
               rts

SetupModuleAdr	entry
               jml   $0BABE0

               End
*-----------------------------------------------------------------------------*
DoT2Options    Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
               debug 'DoT2Options'

               jsr   KillOldSetup

	lda	#T2_Options
	sta	SetupModuleAdr+1
	lda	#^T2_Options
	shortm
	sta	SetupModuleAdr+3
	longm
               brl	SendMakeT2

               End
*-----------------------------------------------------------------------------*
DoT2Options2	Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
               debug 'DoT2Options2'

               jsr   KillOldSetup

	lda	#T2_Options2
	sta	SetupModuleAdr+1
	lda	#^T2_Options2
	shortm
	sta	SetupModuleAdr+3
	longm
               brl	SendMakeT2

               End
*-----------------------------------------------------------------------------*
DoT2Corners    Start
	kind  $1000	; no special memory
               Using GlobalDATA
               Using SetupDATA
               debug 'DoT2Corners'

               jsr   KillOldSetup

T2Corners1stTime entry
               debug 'T2Corners1stTime'

* The very first time, when the setup window is opened, we will jsr here to
* create the defaultly selected T2 corners controls.

	lda	#T2_Corners
	sta	SetupModuleAdr+1
	lda	#^T2_Corners
	shortm
	sta	SetupModuleAdr+3
	longm
	brl	SendMakeT2

               End
*-----------------------------------------------------------------------------*
KillCtl        Start
	kind  $1000	; no special memory
               Using	SetupDATA
	debug 'KillCtl'

               LongResult               ; for disposecontrol
               LongResult               ; for getctlhandlefromid/hidecontrol
               PushLong setupWindPtr
               PushWord #0
               phy
               _GetCtlHandleFromID
               lda   1,s
               sta   5,s
               lda   1+2,s
               sta   5+2,s
               _HideControl
               _DisposeControl
               rts

               End
*-----------------------------------------------------------------------------*
* Constants to set up our stack frame
phd_	gequ  1                  ; This is how the stack is set up
phb_	gequ  phd_+2	; with DP at the top and Result
rtl_	gequ  phb_+1	; occuping the top 4 bytes
T2data2        gequ  rtl_+3
T2data1        gequ  T2data2+4
T2Message      gequ  T2data1+4
T2Result       gequ  T2Message+2
T2StackSize    gequ  T2Result+4
*-----------------------------------------------------------------------------*
T2_Corners	Start
               Using T2CornersDATA
               debug 'T2 Corners'

	longa	on
	longi	on

               phb
               phk
               plb
               phd
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (T2CSetups,x)	; JSR to the appropriate action handler.

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
T2CornersDATA  Data
               debug 'T2CornersDATA'

T2CSetups	anop
               dc    i'doMakeC'         ; MakeT2 procedure	0
               dc    i'doSaveC'         ; SaveT2 procedure	1
	dc	i'doNothing'	; BlankT2 procedure	2
	dc	i'doNothing'  	; LoadSetupT2 procedure	3
	dc	i'doNothing'    	; UnloadSetupT2 procedure 4
	dc	i'doNothing'	; KillT2 procedure	5
	dc	i'doHitC'	; HitT2 procedure	6

TempCorners	ds	2
cRezFileID	ds	2

               End
*-----------------------------------------------------------------------------*
doNothing	Start
               debug 'doNothing'

	rts

               End
*-----------------------------------------------------------------------------*
doHitC	Start
	debug	'doHitC'

	stz	<T2Result+2

	lda	<t2data2+2	; ctlID - hi word MUST BE ZERO
	bne	dontEnable
	lda	<t2data2
	cmp	#5
	blt	enableUpdate
dontEnable	stz	<T2Result
	rts

enableUpdate	anop
	mvw	#TRUE,<T2Result
	rts

               End
*-----------------------------------------------------------------------------*
doMakeC	Start
               Using T2CornersDATA
	Using GlobalDATA
               debug 'doMakeC'

               mvw   <T2data2,cRezFileID

               LongResult
               peil	<T2data1
               PushWord #resourceToResource
               PushLong #T2Setup_Corner_CtlLst
               _NewControl2
               plx
               plx

	PushLong CornersFlagPtr
	makeDP
	lda	[3]
	sta	TempCorners
	killLdp

;	lda	TempCorners
	and	#%111	; isolate top left (bits 0,1,2)
	clc
	adc	#$300	; base menu item ID for UpperLeft

	pha
	LongResult
	peil	<t2data1
	PushLong #4	; UL Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	TempCorners	; get corners status word
	and	#%111000000	; isolate top right (bits 6,7,8)
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$308	; base menu item ID for UpperRight

	pha
	LongResult
	peil	<t2data1
	PushLong #2	; UR Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	TempCorners	; get corners status word
	and	#%111000000000	; isolate bottom right (bits 9,a,b)
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$304	; base menu item ID for LowerRight

	pha
	LongResult
	peil	<t2data1
	PushLong #1	; LR Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	TempCorners	; get corners status word
	and	#%111000	; isolate bottom left (bits 3,4,5)
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$30c	; base menu item ID for LowerLeft

	pha
	LongResult
	peil	<t2data1
	PushLong #3	; LL Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	mvw	#6,<T2Result
               rts

               End
*-----------------------------------------------------------------------------*
doSaveC        Start
               Using T2CornersDATA
	Using	SetupDATA
	Using GlobalDATA
               debug 'doSaveC'

               ~GetCurResourceFile
               ~SetCurResourceFile cRezFileID

	WordResult
	~GetCtlHandleFromID setupWindPtr,#4 ; UL popup
	_GetCtlValue		
	pla
	sec
	sbc	#$300
	sta	TempCorners

	WordResult
	~GetCtlHandleFromID setupWindPtr,#2 ; UR popup
	_GetCtlValue		
	pla
	sec
	sbc	#$308
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	ora	TempCorners
	sta	TempCorners

	WordResult
	~GetCtlHandleFromID setupWindPtr,#1 ; LR popup
	_GetCtlValue		
	pla
	sec
	sbc	#$304
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	ora	TempCorners
	sta	TempCorners

	WordResult
	~GetCtlHandleFromID setupWindPtr,#3 ; LL popup
	_GetCtlValue		
	pla
	sec
	sbc	#$30c
	asl	a
	asl	a
	asl	a
	ora	TempCorners
	sta	TempCorners

	PushLong CornersFlagPtr
	makeDP
	lda	TempCorners
	sta	[3]
	killLdp

	~LoadResource #rT2ExtSetup1,#CornersRez
               jsr   makePdp
               lda   TempCorners
               sta   [3]
	killLdp

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#CornersRez

; Update the file and restore original rezFile.

               ~UpdateResourceFile cRezFileID

               _SetCurResourceFile
               rts

               End
*-----------------------------------------------------------------------------*
T2_Options	Start
               Using T2OptionsDATA
               debug 'T2 Options'

               phb
               phk
               plb
               phd
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (T2OSetups,x)      ; JSR to the appropriate action handler.

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
T2OptionsDATA  Data
               debug 'T2OptionsDATA'

T2OSetups      anop
               dc    i'doMakeO'         ; MakeT2 procedure	0
               dc    i'doSaveO'         ; SaveT2 procedure	1
	dc	i'doNothing'	; BlankT2 procedure	2
	dc	i'doNothing'  	; LoadSetupT2 procedure	3
	dc	i'doNothing'    	; UnloadSetupT2 procedure 4
	dc	i'doKillO'	; KillT2 procedure	5
	dc	i'doHitO'	; HitT2 procedure	6

oRezFileID	ds	2
dfCtlH	ds	4

               End
*-----------------------------------------------------------------------------*
doKillO	Start
	debug	'doKillO'

               ~ReleaseResource #3,#rControlTemplate,#OptBlankDelayDFCtl
	rts

               End
*-----------------------------------------------------------------------------*
doHitO	Start
	debug	'doHitO'

	lda	<t2data2+2	; ctlID - hi word MUST BE ZERO
	bne	dontEnable
	lda	<t2data2
	cmp	#7
	beq	dontEnable
	cmp	#14+1
	blt	enableUpdate
dontEnable	stz	<T2Result
	rts

enableUpdate	anop
	mvw	#TRUE,<T2Result
	rts

               End
*-----------------------------------------------------------------------------*
doNewOptions	Start
	debug	'doNewOptions'
	Using	GlobalDATA

               PushWord #t2GetBuffers
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               phy
               phy                      ; dataIn (none)
               PushLong #getBufferDataOut ; dataOut
               _SendRequest

	lda	Options2Flag
	bit	#fLowMemoryMode
	jne	conserveMem

* don't conserve memory!

* is the 01 buffer currently allocated?

	lda	buffer01
	ora	buffer01+2
	jne	Go2	; yep, so we're done!

* else we've got to allocate it

               LongResult
               PushLong #$8000
               lda   MyID
               ora   #bufferMemAuxID
               pha
               PushWord #attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
	bcc	allocOk
	plx
	plx

	LongResult
	pha
	_HexIt	; convert error to ascii
	PullLong asciiErr

    ~AlertWindow #awPString+awResource+awButtonLayout,#errorSub,#awErrMemoryLMM
	plx

* turn low memory mode back on so that the init doesn't try to blank and use
* bank 01 when we never were able to allocate it

	lda	#fLowMemoryMode
	tsb	Options2Flag

	lda	OptionsFlagPtr+2
	pha
	lda	OptionsFlagPtr
	inc	a
	inc	a
	pha
	makeDP
	lda	Options2Flag
	sta	[3]
	killLdp

	bra	Go2

allocOk	PullLong new01	; normal buffer
	
	lda	#-1	; don't change the E1 handle
	sta	newE1
	sta	newE1+2
	bra	setNewBuffers

conserveMem	anop

* is the 01 buffer currently allocated?

	lda	buffer01
	ora	buffer01+2
	beq	no01Buffer 	; nope, so we're done!

* Else we've got to deallocate it.

	~DisposeHandle buffer01	; deallocate it

	lda	#-1	; don't change the E1 handle
	sta	newE1
	sta	newE1+2

	stz	new01	; mark that it can't be used.
	stz	new01+2

setNewBuffers	PushWord #reqSetBuffers
               PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong #newBuffersDataIn ; dataIn (none)
	phy
               phy		; dataOut (none)
               _SendRequest

no01Buffer	anop
Go2	anop
	lda	OptionsFlag
	bit	#fInstallNDA
	beq	Remove

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
	rts

Remove	anop
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
	rts

newBuffersDataIn anop
newE1	ds	4
new01	ds	4
	
getBufferDataOut anop
	ds	2
bufferE1	ds	4
buffer01	ds	4
	ds	4	; palBuffer
	
               End
*-----------------------------------------------------------------------------*
doMakeO        Start
               Using T2OptionsDATA
	Using GlobalDATA
	Using SetupDATA
               debug 'doMake'

               mvw   <T2data2,oRezFileID

               LongResult
               peil	<T2data1
               PushWord #resourceToResource
               PushLong #T2Setup_Options_CtlLst
               _NewControl2
               plx
               plx

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	peil	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#OptBlankDelayDFCtl
	jsr	makePdp	; deref ctl handle
;	PushLong DataFieldHandle
;	jsr	makePdp	; deref datafield defproc handle
;	pld
;	pla
;	plx
	lda	sDataFieldPtr
	ldy	#$0E	; procRef
	sta	[3],y
	iny
	iny
;	txa
	lda	sDataFieldPtr+2
	sta	[3],y
	pld
	_NewControl2
	lda	3,s	; control handle (for callctldefproc)
	sta	dfCtlH+2
	pha
	lda	3,s
	sta	dfCtlH
	pha
	_MakeThisCtlTarget

               PushWord #SetFieldValue
	PushLong BlankTimePtr
	makeDP
	lda	[3]
	killLdp
	ldy	#0
	sec
divide	iny
	sbc	#120
	bne	divide
	phy
;	lsr	a	; /2      60   120  240
;	lsr	a	; /4      30    60  120
;	lsr	a	; /8   7,s
;	pha                                15    30   60
;	lsr	a	; /16  5,s
;	pha                                7     15   30
;	lsr	a	; /32  3,s
;	pha                                3     7    15
;	lsr	a	; /64  1,s
;	pha                                1     3     7
;	lda	7,s                           15    30   60
;	sec                                 
;	sbc	5,s                           -7    -15  -30
;	sbc	3,s                           -3    -7   -15
;	sbc	1,s                           -1    -3   -7
;	sbc	#4
;	lsr	a
;	lsr	a
;	sec
;	sbc	1,s	; /128 - /8 = /120
;	plx
;	plx
;	plx
;	sta	1,s
;               PushWord #45	;new tag value for this field
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


	lda	OptionsFlag
	and	#fBlinkingBox
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #5	; optMenuBoxCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fCapsLockLock
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #6	; optCapsLockLockCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fWarningAlerts
	lsr	a
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #1	; optWarningAlertsCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fInstallNDA
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #3	; optInstallNDACtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fLetMouseRestore
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a	; bit 6!
	pha
	LongResult
	peil	<T2data1
	PushLong #10	; optLetMouseRestoreDeskCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fNoSound	; bit 7
	xba		; put it into bit 15
	clc
	rol	a	; bit 15->carry
	rol	a	; carry->bit 0
	pha
	LongResult
	peil	<T2data1
	PushLong #11	; optProhibitSndCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fSysBeepsUnblank	; bit 14
	asl	a	; put it into bit 15
	clc
	rol	a	; bit 15->carry
	rol	a	; carry->bit 0
	pha
	LongResult
	peil	<T2data1
	PushLong #12	; optSysBeepsUnblankCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fUseIntelliKey	; bit 15
	clc
	rol	a	; bit 15->carry
	rol	a	; carry->bit 0
	pha
	LongResult
	peil	<T2data1
	PushLong #13	; optUseIntelliKeyCtlID
	_GetCtlHandleFromID
	_SetCtlValue


	lda	OptionsFlag
	and	#fWatchDontBlank+fWatchNormBlank ; isolate watch bits
	xba
	clc
	adc	#$400	; base menu item ID for watch

	pha
	LongResult
	peil	<t2data1
	PushLong #9	; watch Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	OptionsFlag
	and	#fTextGSOSBlank+fTextDontBlank ; isolate text bits
	xba
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$500	; base menu item ID for text

	pha
	LongResult
	peil	<t2data1
	PushLong #4	; text Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	OptionsFlag
	and	#fDClickToggle	; isolate doubleclick bits
	xba
	lsr	a
	lsr	a
	clc
	adc	#$300	; base menu item ID for dclick

	pha
	LongResult
	peil	<t2data1
	PushLong #2	; doubleclick Popup ctl ID
	_GetCtlHandleFromID
	_SetCtlValue		


	lda	Options2Flag
	and	#fLowMemoryMode
	pha
	LongResult
	peil	<T2data1
	PushLong #14	; optLowMemoryModeCtlID
	_GetCtlHandleFromID
	_SetCtlValue



	mvw	#14,<T2Result
               rts

               End
*-----------------------------------------------------------------------------*
doSaveO        Start
               Using T2OptionsDATA
	Using GlobalDATA
	Using	SetupDATA
               debug 'doSaveO'

               ~GetCurResourceFile
               ~SetCurResourceFile oRezFileID

	lda	OptionsFlag
	and	#fRandomize+fT2Active
	sta	OptionsFlag

	WordResult
	~GetCtlHandleFromID setupWindPtr,#5 ; optMenuBoxCtlID
	_GetCtlValue
	pla
	asl	a
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#6 ; optCapsLockLockCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#1 ; optWarningAlertsCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	asl	a
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#3 ; optInstallNDACtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	asl	a
	asl	a
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#10 ; optLetMouseRestoreDeskCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#11 ; optProhibitSndCtlID
	_GetCtlValue
	pla
	xba		; bit 0 -> bit 8
	lsr	a	; bit 8 -> bit 7
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#12 ; optSysBeepsUnblankCtlID
	_GetCtlValue
	pla
	clc
	ror	a	; bit 0 -> carry
	ror	a	; carry -> bit 15
	lsr	a	; bit 15 -> bit 14
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#13 ; optUseIntelliKeyCtlID
	_GetCtlValue
	pla
	clc
	ror	a	; bit 0 -> carry
	ror	a	; carry -> bit 15
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#9 ; watch popup ctl id
	_GetCtlValue		
	pla
	sec
	sbc	#$400
	xba
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#4 ; text popup ctl id
	_GetCtlValue		
	pla
	sec
	sbc	#$500	; base menu item ID for text
	asl	a
	asl	a
	asl	a
	asl	a
	xba
	ora	OptionsFlag
	sta	OptionsFlag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#2 ; doubleclick popup ctl id
	_GetCtlValue		
	pla
	sec
	sbc	#$300	; base menu item ID for dclick
	asl	a
	asl	a
	xba
	ora	OptionsFlag
	sta	OptionsFlag


	lda	Options2Flag
	and	#$FFFE	; clear out low memory mode bit
	sta	Options2Flag

	WordResult
	~GetCtlHandleFromID setupWindPtr,#14 ; optLowMemoryModeCtlID
	_GetCtlValue
	pla
	ora	Options2Flag
	sta	Options2Flag


	PushLong OptionsFlagPtr
	makeDP
	lda	OptionsFlag
	sta	[3]
	lda	Options2Flag
	ldy	#2
	sta	[3],y
	killLdp

	~LoadResource #rT2ExtSetup1,#OptionsRez
               jsr   makePdp
               lda   OptionsFlag
               sta   [3]
	killLdp

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#OptionsRez

	~LoadResource #rT2ExtSetup1,#Options2Rez
               jsr   makePdp
               lda   Options2Flag
               sta   [3]
	killLdp

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#Options2Rez


	LongResult
               PushLong dfCtlH
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               pla	                	;this is the current tag
               plx		;always zero
	asl	a	; x2
	asl	a	; x4
	asl	a	; x8
	pha		;  5,s
	asl	a	; x16
	pha		;  3,s
	asl	a	; x32
	pha		;  1,s
	asl	a	; x64
	clc
	adc	1,s	; x64 + x32 = x96
	adc	3,s	; x96 + x16 = x112
	adc	5,s	; x112 + x8 = x120
	plx
	plx
	plx

	pha
	PushLong BlankTimePtr
	makeDP
	lda	7,s
;	lsr	a	; TEMPORARY !!!!!!!!!!!!
	sta	[3]
	killLdp

	~LoadResource #rT2ExtSetup1,#TimeRez
               jsr   makePdp
	lda	7,s
               sta   [3]
	killLdp
	pla

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#TimeRez


; Update the file and restore original rezFile.

               ~UpdateResourceFile oRezFileID

               _SetCurResourceFile

	jsr	doNewOptions	; handle NDA remove/install

               rts

               End
*-----------------------------------------------------------------------------*
T2_Options2	Start
               Using T2Options2DATA
               debug 'T2 Options2'

               phb
               phk
               plb
               phd
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (T2O2Setups,x)      ; JSR to the appropriate action handler.

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
T2Options2DATA  Data
               debug 'T2Options2DATA'

T2O2Setups     anop
               dc    i'doMakeO2'        ; MakeT2 procedure	0
               dc    i'doSaveO2'        ; SaveT2 procedure	1
	dc	i'doNothing'	; BlankT2 procedure	2
	dc	i'doNothing'  	; LoadSetupT2 procedure	3
	dc	i'doNothing'    	; UnloadSetupT2 procedure 4
	dc	i'doKillO2'	; KillT2 procedure	5
	dc	i'doHitO2'	; HitT2 procedure	6

o2RezFileID	ds	2
o2dfCtlH	ds	4

MPathHandle	ds	4

************************************
CompileHandle	ds	4
ControlHandle	ds	4
LETextHandle	ds	4

DefaultStr	GSStr	'(Default)'

SubArray	anop
PathPtr	entry
	ds	4

************************************
SFStatus       ds    2

OpenString     str   'Open an effect module in the directory you want.'

TypeList       anop
               dc    i'2'               number of types
               dc    i'$0000'           flags: normal.. :-)
               dc    i'$BC'             fileType
               dc    i4'$4004'          auxType
;              dc    i'$A000'           flags: dim all $C1 file entries
;              dc    i'$C1'             fileType
;              dc    i4'0'              auxType
               dc    i'$2000'           flags: dim all $bc $c004 disabled mdls
               dc    i'$BC'             fileType
               dc    i4'$C004'          auxType
;              dc    i'$2000'           flags: dim all $C0 $0001 pics 
;              dc    i'$C1'             fileType
;              dc    i4'$0001'          auxType

SFReply        anop
               ds    2
fileType       ds    2
auxType        ds    4
               dc    i'3'
Nom            ds    4
               dc    i'3'
Path           ds    4

ToolDP	ds	4

pathH	ds	4

               End
*-----------------------------------------------------------------------------*
doKillO2	Start
	debug	'doKillO2'
	Using	T2Options2DATA

               ~ReleaseResource #3,#rControlTemplate,#Opt2DataFieldTimeCtl

* dispose the path handle (it's kept around 'till now)

	~DisposeHandle MPathHandle
	stzl	MPathHandle
	rts

               End
*-----------------------------------------------------------------------------*
doHitO2	Start
	debug	'doHitO2'
	Using	T2Options2DATA
	Using	SetupDATA

	lda	<t2data2+2	; ctlID - hi word MUST BE ZERO
	bne	dontEnable
	lda	<t2data2
	cmp	#7	; datafield was hit..
	beq	checkSwap
	blt	enableUpdate
	cmp	#9	; minutes statText was hit..
	beq	checkSwap
dontEnable	stz	<T2Result
	rts

enableUpdate	anop
	cmp	#1	; set password "set it" control id
	bne	no1
;	jsr	SetPassword
;	bcs	dontEnable
;	bcc	doEnable
	bra	dontEnable
no1	anop
	cmp	#6	; set path "set it" control id
	bne	no2
	jsr	SetPath
	bcc	noError
	~DisposeHandle MPathHandle
	stzl	MPathHandle
noError	anop
no2	anop
doEnable	mvw	#TRUE,<T2Result
	rts

checkSwap	anop
* when the dataField control is hit, check the swap checkbox..
	PushWord #TRUE
	LongResult
	PushLong SetupWindPtr
	PushLong #3	; opt2SwapCtlID
	_GetCtlHandleFromID
	_SetCtlValue
	bra	enableUpdate

               End
*-----------------------------------------------------------------------------*
doMakeO2       Start
               Using T2Options2DATA
	Using GlobalDATA
	Using SetupDATA
               debug 'doMakeO2'

               mvw   <T2data2,o2RezFileID

;	brk	$fe
;               debug 'doMakeO2'

* denote that the T2 module path hasn't been changed..

	stzl	MPathHandle

               LongResult
               peil	<T2data1
               PushWord #resourceToResource
               PushLong #T2Setup_Options2_CtlLst
               _NewControl2
               plx
               plx

* make the datafield control..

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	peil	<T2data1
	PushWord #singlePtr
               ~LoadResource #rControlTemplate,#Opt2DataFieldTimeCtl
	jsr	makePdp	; deref ctl handle
	lda	sDataFieldPtr
	ldy	#$0E	; procRef
	sta	[3],y
	iny
	iny
	lda	sDataFieldPtr+2
	sta	[3],y
	pld
	_NewControl2
	lda	3,s	; control handle (for callctldefproc)
	sta	o2dfCtlH+2
	pha
	lda	3,s
	sta	o2dfCtlH
	pha
	_MakeThisCtlTarget

* and set the right initial value...

               PushWord #SetFieldValue

	LongResult
	PushLong BlankTimePtr
	makeDP
	ldy	#2
	lda	[3],y	; get swap delay (seconds)
	killLdp
	pha
	PushWord #60	; denomerator
	_UDivide
	pla		; minutes
	sta	temp
;	ply		; seconds (remainder)
; leave seconds topmost on stack..
               PushWord #35	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same

	LongResult
	PushLong o2dfCtlH
               PushWord #SetFieldValue
	PushWord temp	; push minutes..
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc
               plx		;always zero
               plx		;same


* do the current path control..

; Load the module path resource.

	~LoadResource #rWString,#T2_module_path
               bcc   pathThere
	plx
	plx
	stz	MPathHandle
	stz	MPathHandle+2
;	lda	#DefaultStr
;	sta	PathPtr
;	lda	#^DefaultStr
;	sta	PathPtr+2
	PushLong #DefaultStr
	makeDP
	bra	moveOn

PathThere	anop
	~DetachResource #rWString,#T2_module_path
	_DisposeHandle

	~LoadResource #rWString,#T2_module_path
	~DetachResource #rWString,#T2_module_path

	lda	1,s
	sta	MPathHandle
	lda	1+2,s
	sta	MPathHandle+2
	jsr	makePdp
moveOn	anop
	lda	[3]
	xba
	sta	[3]
	inc	<3
	pld		; ptr to source string
	PullLong PathPtr

	jsr	substitute

* we keep MPathHandle around so that it can be saved at SaveT2 time
* or killed at KillT2 time..

*	~DisposeHandle MPathHandle ; it's now been substituted so we don't need it anymore


	lda	Options2Flag
	and	#fSHRCorners
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #4	; opt2SHRCornersActiveCtlID
	_GetCtlHandleFromID
	_SetCtlValue

	lda	Options2Flag
	and	#fSwapModules
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #3	; opt2SwapModulesCtlID
	_GetCtlHandleFromID
	_SetCtlValue

	lda	Options2Flag
	and	#fPassword
	lsr	a
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #2	; optPassProtCtlID
	_GetCtlHandleFromID
	_SetCtlValue

	lda	Options2Flag
	and	#fNewModulePath
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	pha
	LongResult
	peil	<T2data1
	PushLong #5	; opt2UseDiffPathCtlID
	_GetCtlHandleFromID
	_SetCtlValue

	mvw	#10,<T2Result
               rts

temp	ds	2

               End
*-----------------------------------------------------------------------------*
doSaveO2       Start
               Using T2Options2DATA
	Using GlobalDATA
	Using	SetupDATA
               debug 'doSaveO2'

;	brk	$fd
;               debug 'doSaveO2'

* rez search path will be set to: T2 on top

	lda	MPathHandle	; has t2 module path been changed?
	ora	MPathHandle+2
	jeq	skipPathSave	; no!

* warn user that change won't take effect until reboot..

	~AlertWindow #awResource+awButtonLayout,#0,#Opt2ChangePathAlert
	plx		; chuck button hit

* set proper size..

	PushLong MPathHandle
	jsr	makePdp
	lda	[3]
	killLdp
	inc	a
	inc	a
	pea	0
	pha
	PushLong MPathHandle
	_SetHandleSize

* save module path... MPathHandle will be zero if no module path is set
* or some kind of bizarre error occurred..

	~RemoveResource #rWString,#T2_module_path

* set the right owner of the handle..

	WordResult
	~GetCurResourceApp
	PushLong MPathHandle
	_SetHandleID
	plx

	PushLong MPathHandle	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rWString	; rType
	PushLong #T2_module_path
	_AddResource

	~GetCurResourceFile
	_UpdateResourceFile

skipPathSave	anop

* Put Twilight.Setup at the top of the rez search path.. (followed by T2)

               ~GetCurResourceFile
               ~SetCurResourceFile o2RezFileID

* save the other options...

	lda	Options2Flag	; clear out all the other bits..
	and	#fLowMemoryMode	; (we'll reset them right below)
	sta	Options2Flag

	WordResult
	~GetCtlHandleFromID setupWindPtr,#4	; opt2SHRCornersActiveCtlID
	_GetCtlValue
	pla
	asl	a
	ora	Options2Flag
	sta	Options2Flag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#3	; opt2SwapModulesCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	ora	Options2Flag
	sta	Options2Flag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#2	; optPassProtCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	asl	a
	ora	Options2Flag
	sta	Options2Flag


	WordResult
	~GetCtlHandleFromID setupWindPtr,#5	; opt2UseDiffPathCtlID
	_GetCtlValue
	pla
	asl	a
	asl	a
	asl	a
	asl	a
	ora	Options2Flag
	sta	Options2Flag


	PushLong OptionsFlagPtr
	makeDP
	lda	Options2Flag
	ldy	#2
	sta	[3],y
	killLdp

	~LoadResource #rT2ExtSetup1,#Options2Rez
               jsr   makePdp
               lda   Options2Flag
               sta   [3]
	killLdp

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#Options2Rez

	LongResult
               PushLong o2dfCtlH
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #34	;field number - they start at 34
	_CallCtlDefProc	; GET MINUTES...
;               pla	                	;this is the current tag -- result space
;               plx		;always zero -- leave for result space
	lda	1,s	; get MINUTES
	pha
	PushWord #60
	_Multiply
	pla		; get low word
	sta	1,s	; overwrite high word
	

	LongResult
               PushLong o2dfCtlH
               PushWord #GetFieldValue
               PushWord #0	;not used for GetFieldValue
               PushWord #35	;field number - they start at 34
	_CallCtlDefProc	; GET SECONDS...
               pla	                	;this is the current tag -- result space
               plx		;always zero -- leave for result space
	adc	1,s	; add to multiply result above..
	plx		; clean up stack..
* A = seconds 'till swap time..

	pha
	PushLong BlankTimePtr
	makeDP
	lda	7,s
	ldy	#2	; offset to SwapDelay..
	sta	[3],y
	killLdp

	~LoadResource #rT2ExtSetup1,#SwapTimeRez
               jsr   makePdp
	lda	7,s
               sta   [3]
	killLdp
	pla

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#SwapTimeRez


; Update the file and restore original rezFile.

               ~UpdateResourceFile o2RezFileID

               _SetCurResourceFile
               rts

               End
*-----------------------------------------------------------------------------*
 ago .skip
SetPassword	Start
	debug	'SetPassword'
	Using	GlobalDATA
               Using T2Options2DATA
	Using	SetupDATA

* open set password window..

               LongResult
               lda   #$0000
               pha
               pha                      ; ptr to replacement title
               pha
               pha                      ; replacement refCon
               PushLong #ContentDraw	; ptr to replacement contentDraw proc
               pha
               pha                      ; ptr to replacement window draw proc
               PushWord #refIsResource
               PushLong #Opt2EnterPassWind
               PushWord #rWindParam1
               _NewWindow2
               lda   1,s
               sta   TempPtr
               lda   1+2,s
               sta   TempPtr+2
               _SetPort
               ~SetFontFlags #$0004     ; use dithered color text in window...

TLoop         	~TaskMaster #$FFFF,#PassTRecord
         	pla
	cmp	#wInControl
	bne	TLoop

	lda	PTaskData4	; get control ID
	cmp	#2	; cancel?
	bne	noCancel
	sec
	brl	return
noCancel	cmp	#1	; OK?
	bne	TLoop

* OK hit..
* check the password checkbox..

	PushWord #TRUE
	LongResult
	PushLong SetupWindPtr
	PushLong #2	; opt2PassProtCtlID
	_GetCtlHandleFromID
	_SetCtlValue

	brk	2

* get the old password text entered..

	PushLong TempPtr
	PushLong #5	; old pass field (ctl ID)
	PushLong #AuxPass
	_GetLETextByID

;fuck
;	jsr		

* zero buffers so the compare below will work...

	ldx	#12-2
zeroPass	stz	NewPass,x
	stz	AuxPass,x
	dex
	dex
	bpl	zeroPass

* get the new password texts entered..

	PushLong TempPtr
	PushLong #3	; new pass field 1 (ctl ID)
	PushLong #NewPass
	_GetLETextByID

	PushLong TempPtr
	PushLong #4	; new pass field 2 (ctl ID)
	PushLong #AuxPass
	_GetLETextByID

* pass must be entered twice exactly the same..

	ldx	#12-2
checkPass	lda	NewPass,x
	cmp	AuxPass,x
	bne	errorNotSame
	dex
	dex
	bpl	checkPass

* pass must be at least 4 chars long..

	lda	NewPass
	and	#$FF
	cmp	#4
	blt	errorTooShort

* okay, we got a good new password!
* encrypt it..

	jsr	encrypt
	clc
	bra	return

errorTooShort	anop	
	~AlertWindow #awResource+awButtonLayout,#0,#Opt2Pass4LengthAlert
	plx		; chuck button hit
	brl	TLoop

errorNotSame	anop		; new passes don't match..
	~AlertWindow #awResource+awButtonLayout,#0,#Opt2BadNewPassAlert
	plx		; chuck button hit
	brl	TLoop

return	anop
	php
               ~CloseWindow TempPtr	; close status window
	plp
               rts


************************************
encrypt	name
	shortmx
	mvw	#$4A,eorVal
	mvw	NewPass,length
	mvw	NewPass,Password	; move length byte

	ldx	#0
encryptIt	lda	NewPass+1,x
	tay
	eor	eorVal
	sta	Password+1,x
	sty	eorVal		
	inx
	cpx	length
	blt	encryptIt
	longmx

* NewPass now encrypted into Password

	rts



* just testing..

decrypt	name
	shortmx
	mvw	#$4A,eorVal
	mvw	Password,length
	mvw	Password,NewPass	; move length byte

	ldx	#0
decryptIt	lda	Password+1,x
	eor	eorVal
	sta	NewPass+1,x
	sta	eorVal		
	inx
	cpx	length
	blt	decryptIt
	longmx

* Password now encrypted into NewPass

	rts

************************************
NewPass	ds	10+2	; unencrypted version
AuxPass	ds	10+2	; aux unencrypted version
Password	ds	10+1	; encrypted version
eorVal	ds	1
length	ds	1

PassTRecord	anop
PWhat	ds    2
PMessage	ds    4
PWhen	ds    4
PWhere	ds    4
PModifiers	ds  	2
PTData	ds	4
 dc i4'tmUpdate+tmFindW+tmCRedraw+tmContentControls+tmControlKey+tmMultiClick+tmIdleEvents+tmControlMenu'
PLastClickTick	ds	4
PClickCount	ds	2
PTaskData2	ds  	4
PTaskData3	ds  	4
PTaskData4	ds  	4
PLastClickPoint ds 	4

               End
.skip
*-----------------------------------------------------------------------------*
SetPath	Start
	debug	'SetPath'
	Using	SetupDATA
	Using	T2Options2DATA
	Using	GlobalDATA	; for myID

* dispose the old path handle...

	~DisposeHandle MPathHandle
	stzl	MPathHandle

* Load Standard file toolset..

               ~LoadOneTool #$17,#$0303

               ~SFStatus
               pla
               sta   SFStatus
               bne   Active

	LongResult
	PushLong #$100
	lda	MyID
	ora	#toolAuxID
	pha
	PushWord #attrLocked+attrFixed+attrPage+attrBank
	lda	#0
	pha
	pha
	_NewHandle
               plx
               stx   ToolDP
               plx
               stx   ToolDP+2
	bcc	memOK
	jsr	DoUnknownErrorAlert
	sec
	rts

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
	pla
	jsr	DoUnknownErrorAlert
	sec
	rts

SFOK	anop
active         anop

               stz   PrefixHndl
               stz   PrefixHndl+2

	~LoadResource #rWString,#T2_module_path
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
	lda	3,s
	sta	pSPfx_prefix
	lda	3+2,s
	sta	pSPfx_prefix+2

	~DetachResource #rWString,#T2_module_path

*	shortm
*	lda	[3]
*	tay
*	iny
*searchDelim	lda	[3],y
*	cmp	#":"
*	beq	foundDelim
*	dey
*	cpy	#2
*	bge	searchDelim
*;	longm
*;	~DisposeHandle pathH
*;	sec
*;	rts
*;	brl	exitSetPath
*	bra	leaveAsIs
*foundDelim	anop
*	dey
*	tya
*	sta	[3]
*leaveAsIs	longm
*	killLdp


               lda   #255               ; Set the length of the output buffer
               sta   BufLength
               stz   BufLength+2

getMem         anop                     ; Get a handle that size.
               LongResult
               PushLong BufLength
               lda   MyID
               ora   #pathBuffAuxID
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
	clc
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

	~HLock Path

	lda	Path
	sta	MPathHandle
	lda	Path+2
	sta	MPathHandle+2

;               ~DisposeHandle Path
               ~DisposeHandle Nom

	PushLong MPathHandle
	jsr	makePdp
	lda	#0	; put a 0 in high byte of accum

* strip off the module's name to get the pathname..
	shortm
	lda	[3]
	tay
	iny
searchDelim1	lda	[3],y
	cmp	#":"
	beq	foundDelim1
	dey
	cpy	#2
	bge	searchDelim1
	longm
	~DisposeHandle Path
	sec
	rts
foundDelim1	anop
	dey
	tya
	sta	[3]
	longm

	lda	[3]
	xba
	sta	[3]
	inc	<3
	pld		; ptr to source string
	PullLong PathPtr

               LongResult               ; for disposecontrol
	~GetCtlHandleFromID SetupWindPtr,#8 ; pathctl id (stattext)
               lda   1,s
               sta   5,s
               lda   1+2,s
               sta   5+2,s
               _HideControl
               _DisposeControl

	jsr	substitute

* We leave MPathHandle around so that it can be saved to disk when the user
* clicks "save"...
* It will be disposed of at KillT2 time.. or the next time we're called..

;	~DisposeHandle Path	; it's now been substituted so we don't need it anymore


* check the use different path checkbox..

	PushWord #TRUE
	LongResult
	PushLong SetupWindPtr
	PushLong #5	; opt2UseDiffPathCtlID
	_GetCtlHandleFromID
	_SetCtlValue
	clc
	rts




************************************
substitute	ename

	LongResult
	PushWord #1	; pascal substitution strings
	PushLong #SubArray

	~LoadResource #rTextForLETextBox2,#Opt2CurPath_LText
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
	_CompileText
	PullLong CompileHandle

	~ReleaseResource #3,#rTextForLETextBox2,#Opt2CurPath_LText

	PushLong PathPtr
	makeDP
	dec	<3
	lda	[3]
	xba
	sta	[3]
	killLdp

	~LoadResource #rControlTemplate,#Opt2CurPathStrCtl
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
	PushLong SetupWindPtr
               PushWord #singleHandle
               PushLong ControlHandle
               _NewControl2
               plx
               plx
	rts

************************************
PrefixHndl     handle                   ; handle to the old prefix 31
BufLength      dc    i4'255'

pGPfx          PrefixRecGS (8,0)
pSPfx          PrefixRecGS (8,0)

               End
*-----------------------------------------------------------------------------*

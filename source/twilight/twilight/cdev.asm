               setcom 80
               mcopy cdev.mac
               copy  13:ainclude:e16.quickdraw
               copy  13:ainclude:e16.control
               copy  13:ainclude:e16.memory
               copy  13:ainclude:e16.types
               copy  13:ainclude:e16.window
               copy  13:ainclude:e16.gsos
               copy  13:ainclude:e16.resources
	copy	13:ainclude:e16.locator
	keep	cdev
	copy	cdev.equ
               copy  tii.equ	; get all the equates
	copy	v1.2.equ
	copy	equates
	copy	debug.equ
*-----------------------------------------------------------------------------*
* ActiveRez      = Whether Twilight is installed properly
* TimeRez        = Minutes until Twilight blanks x 180
* BoxRez         = Whether there's a box in the menu bar
* CapsRez        = Whether the caps lock lock is in use
* CornersRez     = Configurations of all 4 corners.

* Constants to set up our stack frame
DPage          gequ  1                  ; This is how the stack is set up
Bank           gequ  DPage+2            ; with DPage at the top and Result
rtlAddr        gequ  Bank+1             ; occuping the top 4 bytes
Data2          gequ  rtlAddr+3
Data1          gequ  Data2+4
Message        gequ  Data1+4
Result         gequ  Message+2
StackSize      gequ  Result+4
*-----------------------------------------------------------------------------*
; This is the main procedure. It sets the stack up so we can access the passed
; variables as if they were in the DP, and calls the appropriate procedure.
; Then it cleans up the stack and exits back to the Control Panel.
Twilight_II    Start
               Using GlobalDATA
               debug 'Twilight II'

	copy	22:debug.asm

               phb
               phk
               plb
               phd
               tsc
               tcd

               lda   <Message           ; Get which CDev procedure to call.
               dec   a
               asl   a                  ; Tranform into offset.
               tax
               jsr   (CDevs,x)          ; JSR to the appropriate action handler.

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
               rtl

               End
*-----------------------------------------------------------------------------*
GlobalDATA     Data
;	Using	FileDATA
               debug 'GlobalDATA'

CDevs          anop
               dc    i'Ignore'          ; MachineCDev procedure - notUsed
               dc    i'doBoot'          ; BootCDev procedure
               dc    i'Ignore'          ; Reserved procedure - notUsed
               dc    i'doInit'          ; InitCDev procedure
               dc    i'doClose'         ; CloseCDev procedure
               dc    i'doEvents'        ; EventsCDev procedure
               dc    i'doCreate'        ; CreateCDev procedure
               dc    i'doAbout'         ; AboutCDev procedure
               dc    i'Ignore'          ; RectCDev procedure
               dc    i'Ignore'          ; HitCDev procedure - notUsed
               dc    i'Ignore'          ; RunCDev procedure - notUsed

MessageLoc     anop
               handle                   ; Handle to the next Message
               ds    2                  ; ID of this message
MyMessage      anop
               dc    i'MessageEnd-MyMessage'
*              str  'Jim Maricondo: Twilight II'
*              str  'DYA: Twilight II'
*              str  'DYA (JRM): Twilight II'
*	str	'Digital Creations: Twilight II (JRM)'
               str  'DigiSoft Innovations: Twilight II (DYA)'
BlankPtr       ptr  0                   ; Pointer to the blanker entry point
MyID           ds    2                  ; Our memory ID
ModulePath     ptr   0                  ; Ptr to full GS path of module folder
T2Pathname     ptr   0                  ; Ptr to our full pathname & filename
DefaultB       ptr   0		; Ptr to default blanker.
GetRezWord     ptr   0                  ; Ptr to GetRezWord routine.
ConfigPathPtr  ptr   0                  ; Ptr to path for setup/data files.
CurMdlFlgPtr	ds	4	; module flags of active module
nonremovableT2Vol ds	2
PrefRezInfo	ptr   0		; ptr to rezFileID/rezAppID of prefFIle
OptionsFlagPtr	ptr   0
CornersFlagPtr	ptr   0
TE_dp_init_ptr	ptr   0		; dp space alloc'd for starting TextEdit
BlankTimePtr	ptr   0		; ptr to how long to blank word
IgnMouseTimePtr ptr   0		; how long we should temp ignore mouse
OnFlagPtr	ptr   0		; t2 currently on/off
RemoveIt	ds	4	; JML to toolpatch remove routine
MessageEnd     anop

ModuleID	ds	2

TempHandle     handle                   ; handle used for lots of stuff
TempPtr        ptr   0                  ; pointer used for lots of stuff
HndlSize       ds    4                  ; size of a given handle

BlankTime      ds    2                  ; Number of minutes to blank * 720
Minutes        ds    2                  ; Number of minutes to blank
TimeTxt        ds    2                  ; Text string version of Minutes
                     
T2WindP        ptr   0                  ; Pointer to the CDev window (Data1)

FM_dp_handle	handle                   ; handle to the dp block we allocate
TE_dp_handle	handle                   ; handle to the dp block we allocate
FM_startAddr	ds    2                  ; Where in bank $0 the tool DP begins.
TE_startAddr	ds    2                  ; Where in bank $0 the tool DP begins.
QDAuxStartFlag boolean FALSE            ; boolean: we had to start QD Aux
ListMStartFlag	boolean FALSE	; boolean: we had to start list manager

noOpen         boolean FALSE            ; boolean: CDev's main controls created
;errorType      ds    4                  ; Error reported to cantOpen.

PathHandle     handle                   ; handle to a module's pathname
OurRezFileID	ds    2                  ; rezID of our resource fork.
NowModuleID    ds    2                  ; ID assigned to blank now'd module
RezID          ds    2                  ; rez ID of opened rfiles
OurFileNum     ds    2                  ; resource fileNum of Twilight II rfork
OurRezApp	ds 	2	; resource App of ctl panel nda

OptionsFlag	ds	2	; current T2 options
Options2Flag	ds	2	; current T2 options2 word

PurgeT2	ds	2	; tells doclose to purge or not

DataFieldH	handle	; handle to df ctldefproc

* DataOut structure to get the rezfile ID of the preference rezFile.

OpenPrefDataOut anop		; DataOut (for sendRequest)
               ds    2                  ; count
PrefID         ds    2                  ; rezFile id of pref rezFile
PrefErrorCode	ds	2	; error code (if applicable)

* DataOut for reqRandomize

randomDataOut	anop
	ds	2	; count
randomErr	ds	2	; error code (0 if none)

* Alert string substitution array for error alert dialogs.

errorSub       dc    i4'errorStr'
errorStr	anop
	dc	h'04'	; length byte (pstring)
asciiErr	ds	4

* concat stuff

concatDataIn	anop
mpath_fill	ds	4
fname_fill	ds	4	;c	i4'FileName_textLen'
concatId	ds	2

concatDataOut	anop
	ds	2	; count
concatH	ds	4	; new pathhndl

concatP	ds	4

* current list item's display flags

dispFlags	ds	2

* misc

max_modules	ds	2	; list has enough memory for X modules
NumToggled	dc	i'0'	; number of modules currently toggled
BkgToggled	dc	i'FALSE'	; is background fader toggled??

               End
*-----------------------------------------------------------------------------*
; For those messages we don't care about, we call Ignore. It just sets the
; Result field to 0 and exits. It should never be called, but it might, so
; we have to be careful.
Ignore         Start
               debug 'Ignore'

               lda   #0                 ;Store 0 as the result
               sta   <Result
               sta   <Result+2
               rts

               End
*-----------------------------------------------------------------------------*
; Our own event handler.  With this, we don't need to receive Hit events from
; the CP NDA.  We take the small taskRecord @data1 and then copy it to our own
; extended record, and call TaskMasterDA ourselves.  Then we tell the CP NDA
; that nothing ever happened :-)
; This is so I can track doubleclicks on the list control.
doEvents       Start
	Using GlobalDATA
               Using EventDATA
               Using SetupDATA
               debug 'doEvents'

* Right here the resource searth path will look something like this:
*
* > Twilight.II <
* > Control.Panel <
* > Sys.Resources <
*
* We need to add Twilight.Setup to the top, but preserving the way it was
* originally.

	~GetCurResourceFile
	~SetCurResourceFile PrefID

* Copy the small event record passed to us.

               ldy   #16
copyRecord     tyx
               lda   [data1],y
               sta   T2TaskRec,x
               dey
               dey
               bpl   copyRecord

               ldy   #oWhat
               lda   [data1],y
               jeq   exitEvents         ; if nullEvt, exit
	tax

               ldy   #oWhat             ; otherwise tell the CP NDA it was a
               lda   #nullEvt           ; nullEvt
               sta   [data1],y

	txa
	cmp	#keyDownEvt
	bne	noKey
	ldy	#oMessage
	lda	[data1],y
	and	#$7F
	cmp	#$0D
;	bne	noKey
	beq	DClick_Yes

noKey	anop
	mvl	#$001FFFFF,TaskMask ; reInit the taskMask

               ~TaskMasterDA #0,#T2TaskRec
               pla
               cmp   #wInControl
               jne   exitEvents

               lda   ClickCount
               cmp   #2
	bge	DClick
noListDClick	brl   notListDClick

DClick	anop
               lda   TaskData4
               cmp   #ModuleListCtl
               bne   noListDClick

DClick_Yes	anop

* We got a list item double clicked!!  So act upon it!!

	lda	OptionsFlag
	and	#fDClickToggle	; isolate bits 10-11
;	cmp	#fDClickPreview
	beq	simulate_blank_now	; simulate blank now being pressed
	cmp	#fDClickToggle
	bne	noToggle
* If toggle button is disbled then ignore the doubleclick.
               ~GetCtlHandleFromID T2WindP,#ToggleCtl
	jsr	makePdp
	ldy	#oCtlHilite
	lda	[3],y
	killLdp
	and	#$00FF
	cmp	#inactiveHilite
	beq	exitEvents
	jsr	doToggle
	bra	exitEvents
noToggle	cmp	#fDClickSetup
	beq	simulate_command_s
	cmp	#fDClickClose
	bne	exitEvents

simulate_command_w anop
	~PostEvent #keyDownEvt,#$01000057
	plx
	bra	exitEvents

simulate_blank_now anop
* If blank now button is disbled then ignore the doubleclick.

               ~GetCtlHandleFromID T2WindP,#BlankBtn
	jsr	makePdp
	ldy	#oCtlHilite
	lda	[3],y
	killLdp
	and	#$00FF
	cmp	#inactiveHilite
	beq	exitEvents

	mvl	#BlankBtn,TaskData4

notListDClick  anop
turnIntoHit	anop
	mvl	TaskData2,<data1	; controlHandle
	mvl	TaskData4,<data2	; controlID
               jsr   doHit              ; handle the control hit
exitEvents     anop
	_SetCurResourceFile
	rts

simulate_command_s anop
	mvl	#SetupCtl,TaskData4
	bra	turnIntoHit

               End
*-----------------------------------------------------------------------------*
EventDATA      Data
               debug 'EventDATA'

T2TaskRec      anop
What           ds    2                  ; wmWhat
Message        ds    4                  ; wmMessage
When           ds    4                  ; wmWhen
Where          ds    4                  ; wmWhere
Modifiers      ds    2                  ; wmModifiers
TaskData       ds    4                  ; wmTaskData
TaskMask       dc    i4'$001FFFFF'      ; wmTaskMask
LastClickTick  ds    4                  ; wmLastClickTick
ClickCount     ds    2                  ; wmClickCount
TaskData2      ds    4                  ; wmTaskData2
TaskData3      ds    4                  ; wmTaskData3
TaskData4      ds    4                  ; wmTaskData4
LastClickPt    ds    4                  ; wmLastClickPt
 
               End
*-----------------------------------------------------------------------------*
; This procedure loads our code resource, simplifing our boot initialization.
doBoot         Start
               Using GlobalDATA
               Using FileDATA
               debug 'doBoot'

* If control is down, don't install twilight.

               shortm
;	lda	KBDSTRB
;	lda	KBD
;	bmi	noControl	; can't have any normal keys pressed
               lda   KEYMODREG
               bit   #%00000010	; control
;              bit   #%01000000	; option
               beq   noControl
               bit   #%11000001	; OA, Opt, Shift = ignore ctl
	bne	noControl
               longm

* If control is down, also draw an X over the T2 icon to show the user we
* are not installing T2.

* The data1 parameter to the BootCDEV message is now defined.  It points to a
* data word that is initially zero.  If you set bit 0 of this word while
* handling the BootCDEV message, the Control Panel NDA will draw an X over your
* icon (but it will not call SysBeep2 for you; do that yourself if appropriate)

	peil	<data1
	makeDP
	lda	[3]
	ora	#1
	sta	[3]
	killLdp
               rts

noControl      longm

* Get the full pathname of our resource fork.
               WordResult               ; for GetOpenFileRefNum
               ~GetCurResourceFile
               _GetOpenFileRefNum
               PullWord pRefInfo_refNum
               _GetRefInfoGS pRefInfo

* Open the resource fork.  (Make sure it's opened!)
               WordResult               ; Try to open rez fork of Twilight II
               PushWord #readEnable     ; file access
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
               PushLong #NameBuffer_textLen ; pointer to C1 pathname
               _OpenResourceFile        ; of resource file
               PullWord OurRezFileID

bootEntry2     entry
* Get new memory IDs to use.
               ~GetNewID #$A000         ; Get a new ID so that our init doesn't
               PullWord MyID            ; get purged.
               ~GetNewID #$A000         ; Get an ID to InitialLoad2 the modules
               PullWord ModuleID        ; with.

               jsr   LogInCodeResConv

               ~LoadResource #rCodeResource,#T2_Init ; load in the init coderez
               PullLong TempHandle
               ~DetachResource #rCodeResource,#T2_Init ; make the handle ours

               jsr   LogOutCodeResConv

               WordResult
               lda   MyID
               ora   #codeRezAuxID
               pha
               PushLong TempHandle
               _SetHandleID             ; new ID - it must not get purged!!
               pla                      ; chuck old id

               PushLong TempHandle      ; Patch a JSL to the init rCodeResource
               makeDP                   ; just loaded.
               ldy   #1
               lda   [3]
               sta   jumpLoc+1
               lda   [3],y
               sta   jumpLoc+2
               killLdp

               lda   MyID               ; Pass our ID to the Init part.
               ldx   ModuleID           ; And pass the module ID too.
jumpLoc        jsl   >$0BABE0           ; and execute the codeResource.
	bit	#fT2Active	; Accum. has optionsRez
	beq	inactive
	clc
	rts

inactive	anop

	phy		; save error code

* If we're inactive, also draw an X over the T2 icon to show the user we
* are not installing T2.

	peil	<data1
	makeDP
	lda	[3]
	ora	#1
	sta	[3]
	killLdp

* And dispose of the init code resource..

               ~DisposeHandle TempHandle
               stzl	TempHandle

* and release the IDs we allocated..

	lda	MyID
	pha
	pha	
	_DisposeAll
	_DeleteID
	~DeleteID ModuleID

	pla		; restore error code
	sec
	rts

               End
*-----------------------------------------------------------------------------*
; This procedure checks the MessageCenter, and if everything is cool there
; it starts up the necessary tools, builds the list, and then creates all of
; the controls.
doCreate       Start
               Using FileDATA
               Using ListDATA
               Using GlobalDATA
               debug 'doCreate'

	mvl	<Data1,T2WindP

               ~GetCurResourceApp       ; Use the control panel's ID for now
	PullWord OurRezApp	; (as we'll be disposing it in a sec)

               ~GetCurResourceFile
               PullWord OurFileNum

reCreate       anop

* Get some memory to load the message into.

               ~NewHandle #MessageEnd-MessageLoc,OurRezApp,#0,#0
               bcc   hndlOk             ;if we can't get it then display the
               plx                      ;noMem message and exit right away
               plx
               lda   #T2CantGetMemory_LText
               ldx   #^T2CantGetMemory_LText
               jsr   cantOpen
               rts
hndlOk         PullLong TempHandle

* Find the message that the init made..

               ~MessageByName #FALSE,#MyMessage
               bcc   messOk             ;if it's there then everything is cool.

* If the message is not there, then assume the user double-clicked on the
* Twilight II CDev from the 6.0 Finder, and the Twilight II CDev was not
* called during boot because it was not in the CDev folder; it was who knows
* where.  But now the user wants to see it, so emulate the boot process by
* installing the init and our message center message.  This is really cool,
* so now you don't have to have Twilight II in the CDev folder during boot;
* if you want you can just doubleclick it from the 6.0 Finder whenever you
* want it istalled...

	debugBorder
               plx
               plx

               ~DisposeHandle TempHandle

               jsr   bootEntry2         ; run the T2 init
	bcc	okInstallation
	cmp	#drvrWrtProt	; device write protected error?
	lda	#T2WriteProtect_LText
	ldx	#^T2WriteProtect_LText
	bra	goCant
               lda   #T2CantFindSetup_LText
               ldx   #^T2CantFindSetup_LText
goCant	jsr   cantOpen
               rts
okInstallation	brl   reCreate           ; to install ourselves in the system

messOk         plx                      ;if it was there, pull the Message's ID
               pla                      ;into X

               PushWord #getMessage     ;now, get that message from the
               phx                      ;MessageCenter, yanking it into
               PushLong TempHandle      ;the handle we just got.
               _MessageCenter

* Copy the message into our CDev's message space at the beginning of this file.

               ~HandToPtr TempHandle,#MessageLoc,#MessageEnd-MessageLoc

               ~DisposeHandle TempHandle ; and dispose of the handle we got
               stzl	TempHandle

* Patch the CP NDA rezFileApp # into the init.

	PushLong PrefRezInfo
	makeDP
	ldy	#2	; offset to PrefRezAppID
	lda	OurRezApp
	sta	[3],y
	killLdp

* Patch pointer to module path in open parm block.

	mvl	ModulePath,pOpenT2Dir_pathName

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
               PushLong #OpenPrefDataOut ; dataOut
               _SendRequest
	bcs	PrefError
	lda	PrefErrorCode	
	beq	NoPrefError

* If there is an error opening/creating the preffile, then deactivate.

PrefError	anop
	~HexIt PrefErrorCode	; convert error to ascii
	PullLong asciiErr

	~InitCursor

* Create an alert informing the user that there was an error.

   ~AlertWindow #awPString+awResource+awButtonLayout,#errorSub,#AlertOpenError
               plx                      ; chuck button hit

               lda   #T2CantFindSetup_LText
               ldx   #^T2CantFindSetup_LText
               jsr   cantOpen
               rts

NoPrefError	anop

	PushLong PrefRezInfo
	makeDP
	lda	PrefID
	sta	[3]	; offset to prefRezFileID
	killLdp

* Load any needed tools.

	stz	ListMStartFlag
               stz   QDAuxStartFlag     ;any of the tools yet
	stzl	FM_dp_handle
	stzl	TE_dp_handle
	PushLong TE_dp_init_ptr
	makeDP
	lda	#0
	sta	[3]
	ldy	#2
	sta	[3],y
	killLdp

               ~FMStatus                ;If so, then do we need to start the
               pla                      ;font manager as well?
               beq   doFont
               bcs   doFont
               bra	skipFontM

doFont         anop
	jsr	AllocToolDP
	bcs	cantStart1_brl
	sty	FM_startAddr
	sta	FM_dp_handle
	stx	FM_dp_handle+2

skipFontM	anop
	~TEStatus
	pla
	beq	doTE
	bcs	doTE
	bra	skipTE

doTE	anop
	jsr	AllocToolDP
cantStart1	jcsl	CantStartTools
	sty	TE_startAddr
	sta	TE_dp_handle
	stx	TE_dp_handle+2
	tay
	PushLong TE_dp_init_ptr
	makeDP
	tya
	sta	[3]
	ldy	#2
	txa
	sta	[3],y
	killLdp

skipTE	anop
               ~QDAuxStatus             ;Check to see if we need to load QDAux
               pla
               bne   noQDAux            ;if not, skip the QDAux load
               bcc   noQDAux

* Try to load QuickDraw Auxillary.

               ~LoadOneTool #$12,#0     ;if it doesn't load for some reason,
	bcs	cantStart1_brl	; tell the user and make T2 unusable

	~QDAuxStartup            ;Start it up
	bcs	cantStart1_brl

* indicate that we started QD aux

	mvw	#TRUE,QDAuxStartFlag

noQDAux        lda   FM_dp_handle       ;If we're not loading the FM, then this
	ora	FM_dp_handle+2
               beq   noFont             ;flag won't be set, and we'll know not

* Try to load the font manager.

               ~LoadOneTool #$1B,#0     ;if err, tell usr and make t2 unusable
cantStart2	jcsl	CantStartTools

	lda	MyID
	ora	#toolAuxID
	pha
	PushWord FM_startAddr
	_FMStartUp
	bcs	cantStart2_brl

noFont         anop                     

* Try to load the list manager.

               ~LoadOneTool #$1C,#0     ;if it doesn't load for some reason,
               bcs   cantStart2_brl     ;tell the user and make T2 unusable

	~ListStatus
	pla
	bne	ListON

	~ListStartUp	; Start it up after loading
	bcs	cantStart2_brl

	mvw	#TRUE,ListMStartFlag

ListON	anop
	lda   TE_dp_handle       ;If we're not loading TE, then this
	ora	TE_dp_handle+2
               beq   noTextEdit	;flag won't be set, and we'll know not

* Try to load textedit.

               ~LoadOneTool #$22,#0     ;if it doesn't load for some reason,
               bcs   cantStart3_brl     ;tell the user and make T2 unusable

* If textedit has to be started up, it can either have the first or second
* page of DP space we allocate depending on if we had to start up the font
* manager too.

	lda	MyID
	ora	#toolAuxID
	pha
	PushWord TE_startAddr
	_TEStartUp
cantStart3	jcsl	CantStartTools
noTextEdit	anop


;	brk	01
	jsr	CHECK_REBUILD
	bcc	all_ok
	dbrk	$FE
	cmp	#-1	; error processed already by CantOpen?
	bne	notCantOpenError	; no.
	rts		; yes, so return..
notCantOpenError anop
	debugBorder
	jsr	MAKE_LIST_OLD_WAY
	bra	list_made

all_ok	anop
	jsr	CONVERT_DATA_TO_LIST

list_made	anop
* Make the CDev's controls from a rControlList resource.

               ~NewControl2 T2WindP,#resourceToResource,#T2_CDev_CtlLst
               plx                      ; discard the handle, as it's
               plx                      ; junk, anyway

;	lda	#FALSE
	stz	AboutDisabled+1
	stz	BlankNowDisabled+1

               lda   #$0000
               pha
               pha                      ; use default member drawing routine
               PushWord #1              ; item # of 1st displayed lst member
               PushLong ListPtr         ; reference to list
               PushWord #refIsPointer   ; reference is pointer
               PushWord NumModules      ; number of items in list
               ~GetCtlHandleFromID T2WindP,#ModuleListCtl ; hndl of list ctl
               lda   1,s
               sta   ListHandle
               lda   1+2,s
               sta   ListHandle+2
               _NewList2                ; Make the CDev's list control

               ~GetCtlHandleFromID T2WindP,#ModuleListCtl ; hndl of list ctl
	jsr	makePdp
	ldy	#oCtlMemDraw
	lda	#T2ListDraw
	sta	[3],y
	iny
	iny
	lda	#^T2ListDraw
	sta	[3],y
	killLdp

               ~SortList2 #1,ListHandle ; now sort the list (case insensitive)

               stz   noOpen             ; and indicate that we are open!
               rts



allocToolDP	name

* Get 1 page of DP space for the tool(s).

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
               bcc   dpMemOk            ;if we got the mem than everything's
               pla                      ;cool. Otherwise we HAVE to exit.
               pla
	sec
               rts
dpMemOk        makeDP                   ;Get a pointer to the DP mem and store
               lda   [3]                ;it in ToolMem, for the time being
               tay
               pld
               pla
	plx
	clc
	rts

CantStartTools	anop
               lda   #T2CantStartTools_LText
               ldx   #^T2CantStartTools_LText
               jsr   cantOpen
	rts

               End
*-----------------------------------------------------------------------------*
DoUnknownErrorAlert Start
	Using GlobalDATA
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

               End
*-----------------------------------------------------------------------------*
; This routine is called if the CreateCDEV routine has any problems creating
; itself. An error type is passed in A. This is used as a resourceID to
; create a statTextControl control in the window.
cantOpen       Start
               Using GlobalDATA
               Using ListDATA
               Using FileDATA
               debug 'cantOpen'

;               sta   errorType
;               stx   errorType+2

	sta	textRef0+1
	stx	textRef2+1

               ~DisposeHandle TempHandle
               stzl	TempHandle
               ~DisposeHandle ListMem
               stzl	ListMem

               lda   QDAuxStartFlag
               beq   skipQDAux
               ~QDAuxShutDown

skipQDAux      lda   FM_dp_handle
	ora	FM_dp_handle+2
               beq   skipFM
               ~FMShutDown
	~DisposeHandle FM_dp_handle
	stzl	FM_dp_handle

skipFM         anop
	lda	ListMStartFlag
	beq	skipLstMgr
	~ListShutDown

skipLstMgr	anop

	~LoadResource #rControlTemplate,#T2GenericCantOpenMsgCtl
	lda	1,s
	sta	hand0+1
	lda	1+2,s
	sta	hand2+1
	jsr	makePdp

	ldy	#oStatText_textRef
textRef0	lda	#0
	sta	[3],y
	iny
	iny
textRef2	lda	#0
	sta	[3],y
	killLdp

	LongResult
               PushLong T2WindP
	PushWord #singleHandle
hand2	pea	0
hand0	pea	0
               _NewControl2
	plx
               pla                      ; discard the result

               LongResult               ; And make a cool little STOP icon
               PushLong T2WindP         ; above the error text.
               PushWord #refIsResource
               ~GetMasterSCB
               pla
               bit   #mode640
               bne   its640modenow
               PushLong #T2StopIcon320Ctl
               bra   makeTheIcon
its640modenow  PushLong #T2StopIcon640Ctl
makeTheIcon    _NewControl2
               pla                      ; discard the handle
               pla

	mvw	#TRUE,noOpen
               rts

               End
*-----------------------------------------------------------------------------*
; This routine sets up the values for all of the controls in the CDev window.
doInit         Start
               Using GlobalDATA
               Using HitDATA
               Using ListDATA
               Using SetupDATA
               debug 'doInit'

               lda   noOpen             ; Check whether the CDev opened properly
               beq   openOk
               rts

openOk         anop

	WordResult
	lda	MyID
	ora	#codeRezAuxID
	pha
               ~LoadResource #rCtlDefProc,#1 ; load in the datafield defproc
               ~DetachResource #rCtlDefProc,#1
	lda	1,s
	sta	DataFieldH
	lda	1+2,s
	sta	DataFieldH+2
	_SetHandleId
	plx

	PushLong DataFieldH
	jsr	makePdp
	pld	
	PullLong sDataFieldPtr

* Right here the resource searth path will look something like this:
*
* > Twilight.II <
* > Control.Panel <
* > Sys.Resources <
*
* We need to add Twilight.Setup to the top, but preserving the way it was
* originally.

             	~GetCurResourceFile
	~SetCurResourceFile PrefID



	PushLong OptionsFlagPtr
	makeDP
	lda	[3]
	sta	OptionsFlag
	ldy	#2
	lda	[3],y
	sta	Options2Flag
	killLdp

;* If T2 is inactive, then disable the blank now button...
;
;               lda   OptionsFlag
;	bit	#fT2Active
;               bne   active
;	jsr	DimBlankNow
;active	anop

* Check/uncheck the T2Active checkbox.

	PushLong OnFlagPtr
	makeDP
	lda	[3]
;	and	#$FF
	killLdp
	cmp	#0
	beq	setActive
	lda	#1
setActive	pha
	~GetCtlHandleFromID T2WindP,#ActiveCtl
	_SetCtlValue

;	lda	nonremovableT2Vol
;	bne	yesItIs	; it's nonremovable, so continue
;               PushWord #inactiveHilite ; else
;               ~GetCtlHandleFromID T2WindP,#RandomizeCtl
;               _HiliteControl           ; Dim the random mode ctl
;yesItIs	anop

* Check/uncheck the the Random Mode checkbox.

************** REWRITE **************

;	lda	OptionsFlag
;	and	#fRandomize
;	pha
;	~GetCtlHandleFromID T2WindP,#RandomizeCtl
;	_SetCtlValue

;	lda	OptionsFlag
;	bit	#fRandomize
;	beq	singleSelect
;multiSelect	anop
;	jsr	doRandomize	; toggle single (default)_ to multi

	stz	NumToggled	; set # of modules toggled to zero
;	lda	#FALSE
	stz	BkgToggled	; background fader isn't toggled (yet)

* If we're not in 640 mode then disable the setup and about controls...

               ~GetMasterSCB
               pla
               bit   #mode640
               bne   ItsOkWeAre640

* if the user has requested warning alerts, then leave setup and about module
* enabled in 320 mode programs and when clicked upon, make an alert. (v1.0.1b3)

	lda	OptionsFlag
	bit	#fWarningAlerts
	bne	skipdisable

               PushWord #inactiveHilite ; for HilightControl
               ~GetCtlHandleFromID T2WindP,#SetupCtl
               _HiliteControl           ; Dim the setup control!
	jsr	DimAbout
skipdisable	anop
ItsOkWeAre640  stz   setupWindOpen      ; Setup window is closed.
	_SetCurResourceFile


;* Make sure something is always selected.
;* There's a bug where sometimes nothing gets selected!  I'm not sure if this
;* fixes it though..
;
;	~SelectMember2 #1,ListHandle

	jsr	toggle_saved_modules	; self explanatory :-)

	jsr	initAdbVersion
	jsr	CheckDYA
	bcc	noDYA

	jsr	AppleII

noDYA	anop
               rts

               End
*-----------------------------------------------------------------------------*
; Puts up one of the two about boxes, depending on the state of the Apple key.
doAbout        Start
               Using GlobalDATA
	Using	ADBDATA
               debug 'doAbout'

	~LoadResource #rControlTemplate,#T2HelpTECtl
	lda	1,s
	sta	CtlHandle
	lda	1+2,s
	sta	CtlHandle+2
	jsr	makePdp


	jsr	initAdbVersion
;	lda	adbVersion
	cmp	#4
	beq	rom00_reset
	cmp	#5
	beq	rom01_reset
	cmp	#6
	bne	Egg2Check
rom03_reset	anop
	lda	#11
	bra	goCheckReset
rom00_reset	anop
	lda	#10
	bra	goCheckReset
rom01_reset	anop
	lda	#50
goCheckReset	jsr	readADB
	and	#$00FF
	bit	#$08
	beq	noReset	

	ldy	#$38	; textRef
	lda	#T2Help_EE1_LText
	sta	[3],y
	iny
	iny
	lda	#^T2Help_EE1_LText
	sta	[3],y

	~GetResourceSize #rTextForLETextBox2,#T2Help_EE1_LText
	brl	StuffIt

Egg2Check	anop
noReset	anop

	lda	adbVersion
	jsr	CheckDYA
	bcc	noDYA

	jsr	AppleII

noDYA	~GetResourceSize #rTextForLETextBox2,#T2Help_LText

StuffIt	ldy	#$3C	; length of initial text (textLength)
	pla
	sta	[3],y
	iny
	iny
	pla
	sta	[3],y

	killLdp

	LongResult
               peil	<Data1             ; (pointer to window to make controls)
	PushWord #singleHandle
	PushLong CtlHandle
               _NewControl2
	plx
	plx
	rts


CtlHandle	ds	4


;               LongResult               ;Make the control in the window
;               pei   <Data1+2           ;pointed to by Data1
;               pei   <Data1             ; (pointer to window to make controls)
;               PushWord #refIsResource
;               shortm
;               lda   KEYMODREG          ;Now see if the Apple key is down
;               and   #$80
;               beq   noApple
;               PushLong #T2CommandHelpStrCtl ; if so, do the shareware box
;               bra   pushed
;noApple        PushLong #T2HelpStrCtl   ; otherwise bring up standard About box
;pushed         longm
;               _NewControl2             ;And finally create the control
;               pla                      ;and throw away the handle
;               pla
;               rts

               End
*-----------------------------------------------------------------------------*
; Called every time an item in the window is hit, this routine calls a procedure
; to do some extra, cool stuff for the controls I care about (blank now,
; options, about).
doHit          Start
               Using HitDATA
               Using GlobalDATA
               debug 'doHit'

               lda   noOpen	; did we open up the cdev successfully?
               bne   done	; nope, so exit.

               lda   <Data2	; Get the ID of the control hit.
               beq   done	; if zero, exit!
               cmp   #10	; make sure it iss within limits
               bge   done
               dec   a	; subtract one (they start at 0)
               asl   a	; make into an offset
               tax
               jsr   (HitItems,x)	; and run that bit of code...
done           anop
               rts

               End
*-----------------------------------------------------------------------------*
HitDATA        Data
               debug 'HitDATA'

HitItems       anop
               dc    i'doBlankNow'	; 1= Blank now control
               dc    i'noHit'           ; 2= "Twilight.. the ult.." string
               dc    i'doSetup'         ; 3= Setup control
               dc    i'doList'	; 4= List control
               dc    i'doAboutModule'   ; 5= About module
	dc	i'doActivate'	; 6= T2 Active
	dc	i'Ignore'	; 7= Randomize Modules (gone)
	dc	i'doPurgeT2'	; 8= Purge Twilight II
	dc	i'doToggle'	; 9= Toggle Module

               End
*-----------------------------------------------------------------------------*
; When we don't care what happens when we hit a button, we call this routine
; which does nothing.
noHit          Start
               debug 'noHit'

               rts

               End
*-----------------------------------------------------------------------------*
doPurgeT2      Start
               debug 'doPurgeT2'
	Using	GlobalDATA

	lda	OptionsFlag
	bit	#fWarningAlerts
	beq	skipWarning	; user doesn't want any warning alerts

      ~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertPurgeT2Warning
               pla                      ; get button hit
	beq	skipWarning	; purge
exit	rts		; don't purge

skipWarning	anop

	jsr	remove_patches
	bcs	exit

	~PostEvent #keyDownEvt,#$01000057	; command-w
	plx

	mvw	#TRUE,PurgeT2
               rts

* Remove our toolpatches!

remove_patches	ename
	lda	RemoveIt	; we may have been called before our
	ora	RemoveIt+2	; message has been retrieved.  if so,
	beq	removed_ok	; RemoveIt will be NULL and no patches will have been made yet
	jsl	RemoveIt
	bcc	removed_ok
	~AlertWindow #awResource+awButtonLayout,#0,#awCantPurge
	plx
	sec
	rts
removed_ok	anop
	clc
	rts

               End
*-----------------------------------------------------------------------------*
doActivate	Start
	debug	'doActivate'

	rts

	End
*-----------------------------------------------------------------------------*
; When the about module button is hit, we load a rVersion with an id
; of one from the currently hilighted module and display an about screen.
doAboutModule  Start
               Using GlobalDATA
               Using ListDATA
               Using AboutMDATA
               debug 'doAboutModule'

               ~GetMasterSCB
               pla
               bit   #mode640
	bne	okay640

* if we've reached this far in 320 mode then "warning alerts" are on..

       ~AlertWindow #awPString+awResource+awButtonLayout,#0,#AlertAbout320Error
	plx
	rts

okay640	anop
	stz	MemNum
               jsr   GetPathHandle      ; get pathhandle of active list member
	bit	#fInternal
	beq	nonono

	jsr	DimAbout
	rts

nonono	anop
* Open the about module window.

               LongResult
               lda   #$0000
               pha
               pha                      ; ptr to replacement title
               pha
               pha                      ; replacement refCon
               PushLong #AbtContentDraw	; ptr to replacement contentDraw proc
               pha
               pha                      ; ptr to replacement window draw proc
               PushWord #refIsResource
               PushLong #T2_About_Module_Window
               PushWord #rWindParam1
               _NewWindow2
               lda   1,s
               sta   TempPtr
               lda   1+2,s
               sta   TempPtr+2
               _SetPort
               ~SetFontFlags #$0004     ; use dithered color text in window...

* Create version string with versions of module and Twilight II.

               ldx   #10-2              ; init the space for the version
               msb   off                ; numbers to space characters ($20)
               lda   #"  "
spaceInit      sta   T2VersionRec,x
               sta   ModVersionRec,x
               dex
               dex
               bpl   spaceInit

               ~LoadResource #rVersion,#T2_Version ; load in T2's version resource
               jsr   makePdp
               lda   [3]                ; Save the longword value.
               sta   Ver
               ldy   #2
               lda   [3],y
               sta   Ver+2
               killLdp

               ~ReleaseResource #3,#rVersion,#T2_Version ; release the T2 ver rez

* Convert the longword value to an ascii string representing it.

               ~VersionString #0,Ver,#T2VersionRec

               shortm                   ; nuke pascal length byte
               msb   off                ; from versionstring
               lda   #" "               ; (make into space)
               sta   T2VersionRec
               longm

               WordResult
               PushWord #readEnable     ; file access
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
               PushLong PathHandle
               jsr   makePdp
               pld                      ; pointer to C1 pathname of rez file
               _OpenResourceFile
               PullWord RezID

               ~LoadResource #rVersion,#$00000001 ; load in ver rez from module
               bcc   gotOne
               plx                      ; no version resource
               plx
               brl   skipModVer
gotOne         lda   1,s
               sta   ModVerHandle
               lda   1+2,s
               sta   ModVerHandle+2
               jsr   makePdp
               lda   [3]
               sta   Ver
               ldy   #2
               lda   [3],y
               sta   Ver+2
               killLdp

	~HLock ModVerHandle

               ~DetachResource #rVersion,#1	; make the handle ours

               ~VersionString #0,Ver,#ModVersionRec ; convert to ASCII

               shortm                   ; nuke pascal length bytes
               msb   off                ; from versionstring
               lda   #" "               ; (make them into spaces)
               sta   ModVersionRec
               sta   T2VersionRec
               longm

* Load and draw help text resource from the module, if it exists.

skipModVer     ~LoadResource #rTextForLETextBox2,#$0010DD01
               bcc   itsCool
               plx
               plx
               bra   skipLE2
itsCool	anop
	PullLong ModTextHandle
	~DetachResource #rTextForLETextBox2,#$0010DD01	; our handle

skipLE2        anop

* Load and draw icon resource from the module, if it exists.

               ~LoadResource #rIcon,#$0010DD01
               bcc   itsCool2
               plx
               plx
               bra   noIcon
itsCool2	PullLong ModIconHandle
	~DetachResource #rIcon,#$0010DD01

* Draw the window's controls, and wait for a mouseclick.

noIcon         anop

* Get rid of any pending clicks/keypresses.

               ~FlushEvents #keyDownMask+mUpMask+mDownMask+autoKeyMask,#0
               pla

nextTask	anop
	~TaskMaster #$FFFF,#AbtTaskRec
         	pla
	beq	nextTask
	cmp	#mouseDownEvt
	beq	closeAbt
	cmp	#mouseUpEvt
	beq	closeAbt
	cmp	#keyDownEvt
	beq	closeAbt
	cmp	#autoKeyEvt
	bne	nextTask

closeAbt	anop

* Shut things down and return.

	~DisposeHandle ModVerHandle
	~DisposeHandle ModTextHandle
	~DisposeHandle ModIconHandle

               ~CloseWindow TempPtr

               ~CloseResourceFile RezID ; Close the module's resource fork.
	errorbrk
               rts

               End
*-----------------------------------------------------------------------------*
AbtContentDraw	Start
	Using	AboutMDATA
               debug	'AbtContentDraw'

* Draw versions text.

               ~MoveTo #20,#52          ; (52,20) [algebraically (x,y)]
               ~DrawCString #VersionsCStr

* Draw product name string.

               ~MoveTo #92,#12          ; (12,92) [algebraically (x,y)]

               PushLong ModVerHandle
               jsr   makePdp
               lda   3,s                ; increment pointer by 6 to make it
               clc                      ; point at the
               adc   #6                 ; name offset
               sta   3,s
               lda   [3]                ; get length byte
               and   #$00FF
               sta   TempLength
               pld                      ; now there's a pointer to the name
               _DrawString              ; on the stack

* Draw additional info string.
* (Use LETextBox for its wordwrapping capabilities.)

               PushLong ModVerHandle
               jsr   makePdp
               lda   3,s                ; increment pointer by 7 + the length
               clc                      ; of the name to make it point at the
               adc   #7                 ; moreInfo offset
               adc   TempLength         ; START OF PSTRING
               sta   3,s
               lda   [3]
               and   #$00FF
               sta   TempLength
               pld
               lda   1,s
               inc   a                  ; START OF TEXT
               sta   1,s
               PushWord TempLength
               PushLong #InfoTextRect
               PushWord #0              ; leJustLeft
               _LETextBox

* Load and draw help text resource from the module, if it exists.

               PushLong ModTextHandle
               jsr   makePdp
               pld                      ; ModTextHandle now derefed on stack
               ~GetHandleSize ModTextHandle
               pla                      ; discard hi word and keep the lo
               sta   1,s                ; word on the stack
               PushLong #HelpTextRect
               PushWord #0              ; left justification
               _LETextBox2

* Load and draw icon resource from the module, if it exists.

	PushLong ModIconHandle
               jsr   makePdp
               pld                      ; handle now derefed on stack
               PushWord #%1111000000000000 ; mode
               PushWord #$12            ; x
               PushWord #$08            ; y
               _DrawIcon

               ~GetPort
               _DrawControls
               rtl

               End
*-----------------------------------------------------------------------------*
AboutMDATA     Data
               debug 'AboutMDATA'

Ver            ds    4                  ; Current version longint.

HelpTextRect   dc    i'53,20,81+11,360+7'    ; Rect for help text.
InfoTextRect   dc    i'13,92,36,360+7'    ; Rect for info text.

ModIconHandle	ds	4
ModTextHandle	ds	4
ModVerHandle	ds	4
TempLength     ds    2                  ; Temp length of version fields.

VersionsCStr   anop
               dc    c'Twilight II Ver:'
T2VersionRec   anop
               dc    10i1'$20'          ; ASCII T2 version inserted here.
               dc    c'Module Ver:'
ModVersionRec  anop
               dc    10i1'$20'          ; ASCII module version inserted here.
               dc    h'00'

AbtTaskRec	anop
         	ds    2
         	ds    4
         	ds    4
         	ds    4
         	ds    2
         	ds    4
            dc i4'tmIdleEvents+tmControlKey+tmContentControls+tmFindW+tmUpdate'
         	ds    4
         	ds    2
         	ds    4
         	ds    4
  	ds    4
         	ds    4

               End
*-----------------------------------------------------------------------------*
; The procedure blanks the screen when the 'Blank now' button is hit. It allows
; the user to test out the various modules without having to wait for the
; specified time to elapse.
doBlankNow	Start
               Using GlobalDATA
               Using ListDATA
	Using	BlankNowDATA
               debug 'doBlankNow'

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

* is any module selected at all??? (this shouldn't happen but it might)

	~NextMember2 #0,ListHandle
	pla
	bne	something_selected

	jsr	DimBlankNow	 ; if not, dim blank now and abort!
	rts

something_selected anop
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
	bit	#fBackground
	beq	notBkg

               ~FlushEvents #keyDownMask+mUpMask+mDownMask+autoKeyMask,#0
               pla

	PushWord #t2BkgBlankNow
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy		; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha		; target (lo)
               phy
               phy		; dataIn (none)
               phy
               phy		; dataOut (none)
	_SendRequest
	rts

notBkg	anop
               ~GetNewID #$A000	; Get an ID to InitialLoad2 the module
               PullWord NowModuleID	; to blank now with.

	stz	MemNum
               jsr   GetPathHandle	; get pathhandle of active list member
	sta	T2ModuleFlags

* if internal + foreground, then continue

	bit	#fInternal
	beq	normal
	bit	#fBackground
	bne	normal	

               ~DeleteID NowModuleID
               lda   DefaultB
               sta   BlankRtn+1
               lda   DefaultB+1
               sta   BlankRtn+2
;	stz	T2ModuleFlags
               brl   top

normal	anop

* Load the module into memory.

               WordResult
               WordResult
               LongResult
               WordResult
               PushWord NowModuleID
               PushLong PathHandle
               jsr   makePdp
               pld
               PushWord #TRUE
               PushWord #1
               _InitialLoad2
               bcc   ValidLoad
               plx
               plx
               plx
               plx
               plx

	pha
               PushLong PathHandle
               jsr   makePdp
	pld
	jsr	LoadModuleErr	
	brl	skip

ValidLoad      pla
               pla                      ; store it's address into the
               sta   BlankRtn+1
               pla
               shortm
               sta   BlankRtn+3
               longm
               plx                      ;doBlank routine, so that when it's time
               plx                      ;to blank, it'll be called

top            anop

	mvw	NowModuleID,ModuleMemID
	mvw	T2ModuleFlags,ModuleFlgs
	mvl	BlankRtn,ModuleEntryPt
	mvw	PrefID,PrefRezFileID
;	lda	OurRezApp
;	sta	PrefRezAppID

* Make sure T2 is active. (i.e. shift clear stuff)
* tell the SHR heartbeat to ignore the mouse for the first 1 second
* blank now (test the module)
* flush all pending key events
* stop ignoring the mouse if the user hit a key before 1 second
* if we had to enable T2, then disable it again to make it like before
                                 
	jsr	SendBlankNow

               WordResult               ; for SetHandleId
               PushWord #0              ; for SetHandleId (don't change id)
               LongResult               ; for FindHandle
               lda   BlankRtn+3
               and   #$00FF
               pha
               lda   BlankRtn+1
               pha
               _FindHandle              ; Get the handle of the module code.
               _SetHandleId
               pla                      ; get the ID of the module code's hndl
               cmp   MyID               ; is it that of our code resource?
               beq   skip               ; if yes, it's deflt mod- don't unload

* Set the module's static load segs as purgable, and discard dynamic segments.
* And delete NowModuleID.

               ~UserShutDown NowModuleID,#$0000
               plx                      ; chuck memID

skip           anop

* make sure the SHR heartbeat isn't ignoring the mouse anymore

	PushLong IgnMouseTimePtr
	makeDP
	lda	#0
	sta	[3]
	killLdp
               rts

UseDefault     anop
               ~DeleteID NowModuleID
               lda   DefaultB
               sta   BlankRtn+1
               lda   DefaultB+1
               sta   BlankRtn+2
	stz	T2ModuleFlags
               brl   top

BlankRtn       entry
               jml   $0BABE0

               End
*-----------------------------------------------------------------------------*
BlankNowDATA	Data

;stateWordDataOut anop
;	ds	2	; count
;	dc	i'0'	; start buffer offset
;	dc	i'2'	; end buffer offset
;stateWord	ds	2

BlankScreenDataIn anop
* This first flag signifies that we're calling blank_screen from the "blank
* now" control.  It means to skip the SysBeep2's, always call LoadSetupT2
* and UnloadSetupT2, and also pass a flag to the module telling it that we're
* calling it from "blank now".
	dc	i'TRUE'	; blankNowFlag
ModuleMemID	ds	2
ModuleFlgs	ds	2
ModuleEntryPt	ds	4
PrefRezFileID	ds	2
	dc	i'0'	; PrefRezAppID
	dc	i4'0'	; LSResult=0 cuz blnkscr'll load setup

               End
*-----------------------------------------------------------------------------*
doClose        Start
               Using ListDATA
               Using GlobalDATA
               debug 'doClose'

* Commentary: 12/26/92 JRM (tc) v1.0.1b3 Special Thanx Seth Ober!

* If an error was incurred during startup, then make sure we purge ourselves
* from memory!  We will need to do this only sometimes, (i.e. sometimes we
* will be installed before the error occurred, and sometimes the error will
* have occurred while we were trying to install T2) but calling removeT2
* all the time shouldn't hurt (I HOpe :-)

* Cases where we could be called with noOpen = TRUE:
* (- means we aren't installed before, = we were previously installed)
*
*  -/= look at all the jsr cantOpen's in the above code!
*  -/= if twilight.setup is hosed or we have problems loading it.
*    (= if we were loaded during boot ok, but after boot the setup file got
*    hosed and now the user is trying to bring up the main T2 window)
*    (- if t2 wasn't loaded during boot and now the user is trying to get us
*    to install now but we can't since twilight.setup is hosed)
*  = if the user renamed the volume Twilight II is on, after twilight II
*    had been installed into memory, and then doubleclicks on Twilight II.

               lda   noOpen             ;If we didn't open the window, don't
	beq	dont_purge

	jsr	remove_patches
	brl	purge

dont_purge	anop
* CloseProc will set the curresourcefile to OurRezFileID, so give it OurRezFileID.

              	~GetCurResourceFile
               PullWord OurRezFileID

* Right here the resource searth path will look something like this:
*
* > Twilight.II <
* > Control.Panel <
* > Sys.Resources <
*
* We need to add Twilight.Setup to the top, but preserving the way it was
* originally.

	~SetCurResourceFile PrefID

	lda	#$BABE
               jsl   CloseProc          ; close the setup window if its open

	jsr	save_module_selection

* Tell the init to stop trying to set the rezApp to the CP NDA at blankT2
* time...

	PushLong PrefRezInfo
	makeDP
	lda	#0
	ldy	#2	; offset to PrefRezAppID
	sta	[3]
	sta	[3],y
	killLdp

	~LoadResource #rT2ExtSetup1,#OptionsRez
               jsr   makePdp

	WordResult                  
	~GetCtlHandleFromID T2WindP,#ActiveCtl
	_GetCtlValue
	pla
	bne	activeTrue
	ldx	#$0000
	bra	aa1
activeTrue	anop
	ldx	#$FFFF
aa1	anop
	PushLong OnFlagPtr
	makeDP
	txa
;	shortm
	sta	[3]
;	longm
	killLdp


;	WordResult
;	~GetCtlHandleFromID T2WindP,#RandomizeCtl
;	_GetCtlValue
;	pla
;	bne	randomTrue
;	lda	#fRandomize
;	trb	OptionsFlag
;	bra	a2
;
;randomTrue	lda	#fRandomize
;	tsb	OptionsFlag

a2	anop
               lda   OptionsFlag
               sta   [3]
	killLdp

	~MarkResourceChange #TRUE,#rT2ExtSetup1,#OptionsRez

	PushLong OptionsFlagPtr
	makeDP
	lda	OptionsFlag
	sta	[3]
	killLdp

	~DisposeHandle DataFieldH
	stzl	DataFieldH

* Dispose all of the pathname string handles.

               lda   MyID
               ora   #pathMemAuxID
               pha
               _DisposeAll

* Dispose all of the module name string handles.

               lda   MyID
               ora   #modNameAuxID
               pha
               _DisposeAll

               ~DisposeHandle ListMem   ; Get rid of the list's memory
               stzl	ListMem

	~UpdateResourceFile PrefID

contClose      anop
	lda   PurgeT2
	bne	dontLoad

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
	beq	dontLoad
	sta	PurgeT2
	dbrk	05
	jsr	remove_patches	; remove our toolpatches

dontLoad	anop
* Update and close Twilight.Setup.

	lda	PrefID
	ora	#$8000	; close no matter what!
	pha
	_CloseResourceFile
	bcc	GreatITWorks

	LongResult	; convert error to ascii
	pha
	_HexIt
	PullLong asciiErr

	~InitCursor

* Create an alert informing the user that there was an error.

   ~AlertWindow #awPString+awResource+awButtonLayout,#errorSub,#AlertCloseError
               plx                      ; chuck button hit

;	jsr	DoUnknownErrorAlert

GreatITWorks	anop

* Shut down any started tools.

               lda   FM_dp_handle
	ora	FM_dp_handle+2
               beq   noFM
               ~FMShutDown
	~DisposeHandle FM_dp_handle
	stzl	FM_dp_handle

noFM           lda   QDAuxStartFlag
               beq   noQDAux
               ~QDAuxShutDown

noQDAux        anop
	lda	ListMStartFlag
	beq	noLstMgr
	~ListShutDown

noLstMgr	anop

	lda	PurgeT2	; should we purge ourselves?
	bne	purge
	rts		; nope
purge	stz	PurgeT2

* Call our cool handydandy request to do all the dirty work for us!
* (well, except removing our toolpatches)

	PushWord #reqRemoveT2
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
	phy
               phy		; dataIn
	phy
               phy		; dataOut
               _SendRequest
	rts

               End
*-----------------------------------------------------------------------------*

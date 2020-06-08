
         	KEEP  patch.d
         	mcopy patch.mac
         	copy  patch.equ
	copy	13:ainclude:e16.memory
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.window
	copy	13:ainclude:e16.event
	copy	13:ainclude:e16.resources
	copy	13:ainclude:e16.misctool
	copy	13:ainclude:e16.gsos
	copy	22:dsdb.equ
*-----------------------------------------------------------------------------*
TRUE     	gequ  1
FALSE    	gequ  0

TempHandle	gequ	<0
TempPtr	gequ	TempHandle+4
TempDP	gequ	TempPtr+4

MaxFSTLen      gequ  32                 ; Maximum filename length supported
*-----------------------------------------------------------------------------*
Patcher	Start
	kind	$1000
	Using	GlobalDATA
	debug	'Patcher'

	copy	22:dsdb.asm

         phk
         plb
         jsr   Startup                    ;Set things up
         jsr   MainEvent                ;do the main program
         jsr   Shutdown                 ;then shut them down again

         _QUIT QuitParms               ;And quit

         End
*-----------------------------------------------------------------------------*
GlobalDATA Data

QuitParms anop
         dc    i4'0'
         dc    i'0'

MasterID     ds    2                        ;UserID
MyID    ds    2                        ;auxiliary UserID
QuitFlag dc    i'0'
EnableFlag dc  i'$FFFF'                 ;wether the edit menu is enabled

SSRecRefRet ds 4                       ;returned by StartUpTools

NewPtr   ds    4                        ;The pointer to window's grafport

         End
*-----------------------------------------------------------------------------*
Startup    Start
         Using GlobalDATA
         Using FileDATA
	debug	'Startup'

         ~TLStartUp                     ;Start the Tool Locator

         ~MMStartUp
         PullWord MasterID
         ora   #$0100                   ;And create an aux ID
         sta   MyID                    ;  for getting memory with

         ~StartUpTools MasterID,#refIsResource,#toolTable
         PullLong SSRecRefRet

         jsr   SetUpMenus               ;And draw the menu

         ~InitCursor                    ;Show the arrow cursor
         rts

         End
*-----------------------------------------------------------------------------*
SetUpMenus Start
	Using GlobalDATA
	debug	'SetUpMenus'

         ~NewMenuBar2 #refIsResource,#menuBar,#0
         _SetSysBar                     ;  and make it the current system bar

         ~SetMenuBar #0

         ~FixAppleMenu #1	; install desk accs

         ~FixMenuBar		; calculate menu sizes
         pla

         ~DrawMenuBar                   ;And draw the bar
         rts

         End
*-----------------------------------------------------------------------------*
MenuDATA Data
	debug	'MenuDATA'

MenuHandlers	anop
         dc    i'doClose'               ;Close: 255
         dc    i'doAbout'               ;About: 256
         dc    i'doQuit'                ;Quit: 257
         dc    i'doPatch'                ;Patch: 258
         dc    i'doHelp'                ;Help: 259

         End
*-----------------------------------------------------------------------------*
MainEvent Start
         Using TaskDATA
         Using GlobalDATA
	debug	'MainEvent'

	jsr	doPatch

again    anop
         ~TaskMaster #$FFFF,#TaskRecord
         pla
         asl   a
         tax
         jsr   (TaskHandlers,x)
         lda   QuitFlag
         beq   again
         rts

         End
*-----------------------------------------------------------------------------*
TaskDATA Data

TaskRecord anop
What     ds    2
Message  ds    4
When     ds    4
Where    ds    4
Modifiers ds   2
TData    ds    4
         dc    i4'$001FFFFF'
LastClickTick ds 4
ClickCount ds  2
TaskDATA2 ds   4
TaskDATA3 ds   4
TaskDATA4 ds   4
LastClickPoint ds 4

TaskHandlers anop
         dc    i'doNull'                ;NullEvt
         dc    i'Ignore'                ;MouseDownEvt
         dc    i'Ignore'                ;MouseUpEvt
         dc    i'Ignore'                ;KeyDownEvt
         dc    i'Ignore'                ;Undefined
         dc    i'Ignore'                ;AutoKeyEvt
         dc    i'Ignore'                ;UpdateEvt
         dc    i'Ignore'                ;Undefined
         dc    i'Ignore'                ;ActivateEvt
         dc    i'Ignore'                ;SwitchEvt
         dc    i'Ignore'                ;DeskAccEvt
         dc    i'Ignore'                ;DriverEvt
         dc    i'Ignore'                ;App1Evt
         dc    i'Ignore'                ;App2Evt
         dc    i'Ignore'                ;App3Evt
         dc    i'Ignore'                ;App4Evt
         dc    i'Ignore'                ;wInDesk
         dc    i'doMenus'               ;wInMenuBar
         dc    i'Ignore'                ;wClickCalled
         dc    i'Ignore'                ;wInContent
         dc    i'Ignore'                ;wInDrag
         dc    i'Ignore'                ;wInGrow
         dc    i'doClose'               ;wInGoAway
         dc    i'Ignore'                ;wInZoom
         dc    i'Ignore'                ;wInInfo
         dc    i'doMenus'               ;wInSpecial
         dc    i'Ignore'                ;wInDeskItem
         dc    i'Ignore'                ;wInFrame
         dc    i'Ignore'                ;wInactMenu
         dc    i'Ignore'                ;wClosedNDA
         dc    i'Ignore'                ;wCalledSysEdit
         dc    i'Ignore'                ;wTrackZoom
         dc    i'Ignore'                ;wHitFrame
         dc    i'Ignore'                ;wInControl
         dc    i'Ignore'                ;wInControlMenu

         End
*-----------------------------------------------------------------------------*
doNull   Start
         Using GlobalDATA

         ~FrontWindow
	pla
	ora	1,s
	plx
	cmp	#0
	bne	enableClose

         lda   EnableFlag               ;see if we're already disabled
         beq   done                     ;if so, then exit

         ~DisableMItem #255	; otherwise, disable close item

         ~SetMenuFlag #$0080,#3	; and edit menu

         _DrawMenuBar                   ;redraw the menu bar (so Edit will be
;                                       ;dimmed)
;	lda	#FALSE
         stz   EnableFlag               ;and indicate that things are disabled
         rts                            ;Exit

enableClose	lda   EnableFlag               ;see if things are already enabled
         bne   done                     ;and if so, exit

         ~EnableMItem #255	; enable close item

         ~SetMenuFlag #$FF7F,#3	; and the edit menu

         _DrawMenuBar                   ;redraw the menu bar

         lda   #TRUE                    ;and indicate that things are enabled
         sta   EnableFlag

done     rts

         End
*-----------------------------------------------------------------------------*
Ignore   Start

         rts                            ;Ignore all of these

         End
*-----------------------------------------------------------------------------*
doMenus  Start
	Using GlobalDATA
         Using MenuDATA
         Using TaskDATA
	debug	'doMenus'

         lda   TData                    ;Find out which menu it was
         sec                            ;transform into a jump table offset
         sbc   #255
         asl   a
         tax
         jsr   (MenuHandlers,x)         ;and jump

         ~HiliteMenu #FALSE,TData+2	; then unhilite it when done
         rts

         End
*-----------------------------------------------------------------------------*
doClose  	Start
         	Using GlobalDATA
         	Using MenuDATA
	debug	'doClose'

               ~FrontWindow
	bcs	leave
               lda   1,s                check if there is a front window
               ora   3,s
               bne   ThereIsAWindow
         	~DisableMItem #255	; disable close
leave          pla                      if there isn't, then abort close op
               pla                      clean up stack
               rts                      and return

thereIsAWindow anop
               PullLong TempDP          pointer to active window's GrafPort

               WordResult
               pei   TempDP+2
               pei   TempDP
               _GetSysWFlag
               pla
               bne   SystemWindow       TRUE=system window

               pei   TempDP+2           close our window
               pei   TempDP
               _CloseWindow
               rts

SystemWindow   anop
               pei   TempDP+2           pointer to window to close
               pei   TempDP
               _CloseNDAbyWinPtr        close system (NDA) window
               rts

               ~FrontWindow
	bcs	leave2
	lda   1,s                check if there is a front window
               ora   3,s
               bne   leave2
         	~DisableMItem #255	; disable close
leave2         plx                      if there isn't, then abort close op
               plx                      clean up stack
               rts                      and return

         	End
*-----------------------------------------------------------------------------*
doAbout  	Start
	Using	GlobalDATA
	debug	'doAbout'

	~AlertWindow #awPString+awResource+awButtonLayout,#0,#awAbout
         	plx
         	rts

         	End
*-----------------------------------------------------------------------------*
doPatch   Start
         Using FileDATA
         Using GlobalDATA
	debug	'doPatch'

;         lda   SavedFlag                ;if the window has hever been saved,
;         beq   skip                     ;then skip this

;         ~DisposeHandle Name            ;dispose name and path strings
;         ~DisposeHandle Path

;skip	anop

	_GetNameGS p_getName

	_GetDevNumberGS pGetDevNumber

	lda	pGetDevNumber_devNum
	sta	pDInfo_devNum

	_DInfoGS pDInfo

	_VolumeGS pVolume

	lda	pVolume_fileSysID
               cmp	#appleShareFSID
               beq	GoAShare	; skip setting the path

	_SetPrefixGS pSPfx

GoAShare	anop
               PushWord #120            whereX  640
               PushWord #50             whereY  640
               PushWord #refIsPointer   promptRefDesc
               PushLong #OpenString     promptRef
               PushLong #0              filterProcPrt
               PushLong #TypeList       typeListPtr
               PushLong #SFReply        replyPtr
               _SFGetFile2

         lda   SFReply                  ;See if we should proceed
         bne   ok
         brl   abort

ok	anop
;	~GetCurResourceFile

	lda   Path                     ;Transfer the path to a dp location
         	sta   TempHandle
         	lda   Path+2
         	sta   TempHandle+2

               WordResult
	PushWord #readWriteEnable ; Read/Write file access!
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
         	ldy   #2                       ;Load the pointer to the name
         	lda   [TempHandle]
         	clc                            ;  adding two to skip over the length
         	adc   #2                       ;  of buffer word
	tax
         	lda   [TempHandle],y
         	adc   #0
	pha
	phx
	_OpenResourceFile
	plx
	stx	rFileID
	php
	pha
         ~DisposeHandle Name            ;dispose name and path strings
         ~DisposeHandle Path
	pla
	plp
	bcc	openOk
	brl	error_mgr

openOk	anop

               ~LoadResource #rTaggedStrings,#1
	plx
	stx	TaggedH
	stx	TempDP
	plx
	stx	TaggedH+2
	stx	TempDP+2
	bcc	taggedOk
	~CloseResourceFile rFileID
	clc
	lda	#1	; bad sound control panel
	brl	error_mgr

taggedOk	anop

* are you sure?

	~AlertWindow #awPString+awResource+awButtonLayout,#0,#awAreYouSure
         	pla
	beq	sureThing	; patch (0)
;			; cancel (1)

	~CloseResourceFile rFileID
	brl	abort

sureThing	anop
	~HLock TaggedH

         	ldy   #2	; deref it
         	lda   [TempDP]
	tax
         	lda   [TempDP],y
	stx	TempDP
	sta	TempDP+2	

* get count word..

	lda	[TempDP]
	sta	string_count

* check if it already has strings for screen blanking and unblanking...
* if a string is found for either, then refuse to patch this cdev.

	ldy	#2	; skip past count word
keep_checking	lda	[TempDP],y
	cmp	#sbScreenBlanking
	beq	ya_patched	; already patched
	cmp	#sbScreenUnblanking
	beq	ya_patched
	iny
	iny
	lda	[TempDP],y
	and	#$FF	; get length byte
	sta	addToY+1
	iny
	tya
	clc
addToY	adc	#0
	tay
	dec	string_count
	bne	keep_checking
	beq	not_patched

ya_patched	anop
	~CloseResourceFile rFileID
	clc
	lda	#2	; already patched
	brl	error_mgr

not_patched	anop

	~HUnlock TaggedH

* get room to house the new tagged strings

	~GetHandleSize TaggedH
	lda	1,s
	sta	end_offset+1
	clc
	adc	#strSize
	sta	1,s
	lda	3,s
	adc	#0
	sta	3,s
	PushLong TaggedH
	_SetHandleSize
	bcc	handleOk
	pha
;	~ReleaseResource #3,#rTaggedStrings,#1
	~CloseResourceFile rFileID
	pla
	sec
	brl	error_mgr

handleOk	anop

	lda	TaggedH+2
	sta	TempDP+2
	pha
	lda	TaggedH
	sta	TempDP
	pha
	_HLock

         	ldy   #2	; deref it again
         	lda   [TempDP]
	tax
         	lda   [TempDP],y
	stx	TempDP
	sta	TempDP+2	

* append our data to the end of it

end_offset	ldy	#0
	ldx	#0
	shortm
keep_copying	lda	NewTaggedStrs,x
	sta	[TempDP],y
	iny
	inx
	cpx	#strSize
	blt	keep_copying
	longm

* increment string count

	lda	[TempDP]
	inc	a
	inc	a
	sta	[TempDP]

* we're just about done!

	~MarkResourceChange #TRUE,#rTaggedStrings,#1

;	~ReleaseResource #3,#rTaggedStrings,#1
	~CloseResourceFile rFileID

        ~AlertWindow #awPString+awResource+awButtonLayout,#0,#awPatchSuccessful
	plx

abort	rts

newTaggedStrs	anop
strSizeStart	anop
screenBlanking anop
	dc	i'sbScreenBlanking'
	str	'Screen Blanking'
screenUnblanking anop
	dc	i'sbScreenUnblanking'
	str	'Screen Unblanking'
strSizeEnd	anop
strSize	equ	strSizeEnd-strSizeStart

rFileID	ds	2
TaggedH	ds	4
string_count	ds	2

         	End
*-----------------------------------------------------------------------------*
FileDATA Data
	debug	'FileDATA'

OpenString str 'Locate the Sound control panel:'

TypeList	anop
               dc    i'1'               number of types
               dc    i'$8000'           flags: don't match auxtype
               dc    i'$C7'             fileType
               dc    i4'$0000'          auxType

SFReply  anop
         ds    2
type     ds    2
auxType  ds    4
         dc    i'3'
Name     ds    4
         dc    i'3'
Path     ds    4

p_getName	GetNameRecGS curName
curName	C1Result MaxFSTLen
pGetDevNumber	DevNumRecGS (curName_textLen,0)
pDInfo	DInfoRecGS (0,bootDevName,0,0,0,0,0,0)
bootDevName	C1Result 40
pVolume	VolumeRecGS (bootDevName_textLen,curName,0,0,0,0,0,0)
pSPfx          PrefixRecGS (8,CDevPfx)
CDevPfx	GSStr	'*:System:CDevs'

         End
*-----------------------------------------------------------------------------*
error_mgr	Start
	debug	'error_mgr'
	Using	ErrorDATA

	bcs	UnknownError
	dec	a
	asl	a
	asl	a
	tax
	WordResult
	PushWord #awPString+awResource+awButtonLayout
	lda	#0
	pha
	pha		; sub array
	lda	alert_ids+2,x
	pha
	lda	alert_ids,x
	pha
	_AlertWindow
	plx
	rts

UnknownError	anop
	LongResult
	pha
	_HexIt
	PullLong asciiErr

* Create an alert informing the user that there was an error.

 ~AlertWindow #awPString+awResource+awButtonLayout,#errorSub,#awUnknownErr
	plx
	rts

	End
*-----------------------------------------------------------------------------*
ErrorDATA	Data
	debug	'ErrorDATA'

* Alert string substitution array for error alert dialogs.

errorSub       dc    i4'errorStr'
errorStr	anop
	dc	h'04'	; length byte (pstring)
asciiErr	ds	4

* custom alert ids..

alert_ids	anop
	dc	i4'awBadCDev,awAlreadyPatched'

	End
*-----------------------------------------------------------------------------*
doQuit   Start
         Using GlobalDATA
	debug	'doQuit'

         lda   #TRUE                    ;Indicate that it's time to quit
         sta   QuitFlag

         rts

         End
*-----------------------------------------------------------------------------*
doHelp   Start
         Using HelpDATA
         Using GlobalDATA
	debug	'doHelp'

         LongResult                     ;open a window with the Help in it
	ldy	#0
	phy
	phy
	phy
	phy
         PushLong #drawContent
	phy
	phy
         PushWord #refIsResource
         PushLong #help_Window
         PushWord #rWindParam1
         _NewWindow2
         PullLong HelpPtr

wait           anop

; then wait for the person to hit the close box, filtering out all other events

         ~TaskMaster #$FFFF,#HelpTRecord
         pla
	cmp	#autoKeyEvt
	beq	noWKey
	cmp	#keyDownEvt
	bne	noKey
	lda	HMessage
	and	#$5F
	cmp	#"W"
	bne	noWKey
	lda	HModifiers
	bit	#appleKey
;	beq	noKey
	bne	goClose
noWKey	~SendEventToCtl #FALSE,HelpPtr,#HelpTRecord
	pla
	bra	wait

noKey	cmp   #wInGoAway
         bne   wait

goClose	~CloseWindow HelpPtr	; close Help window
         	rts

         End
*-----------------------------------------------------------------------------*
DrawContent    Start
	debug	'DrawContent'

               phb
               phk
               plb
               LongResult
               _GetPort
               _DrawControls
               plb
               rtl

	End
*-----------------------------------------------------------------------------*
HelpDATA  Data

HelpPtr   ds    4

HelpTRecord anop
HWhat    ds    2
HMessage ds    4
HWhen    ds    4
HWhere   ds    4
HModifiers ds  2
HTData    ds   4
         dc    i4'$0011A106'	;+tmControlKey'
HLastClickTick ds 4
HClickCount ds 2
HTaskData2 ds  4
HTaskData3 ds  4
HTaskData4 ds  4
HLastClickPoint ds 4

         End
*-----------------------------------------------------------------------------*
Shutdown Start
	debug	'Shutdown'
         Using GlobalDATA

         ~ShutDownTools #refIsHandle,SSRecRefRet ; shutdown most of the tools
         ~MMShutDown MasterID
         ~TLShutDown                    ;  then the Tool Locator
         rts

         End
*-----------------------------------------------------------------------------*

               mcopy YDI.Mac
	copy	YDI.Equ
	copy	22:t2common.equ
	copy	13:ainclude:e16.memory
	copy	13:ainclude:e16.event
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.resources
	copy	13:ainclude:e16.control
	copy	13:ainclude:e16.window
	copy	13:ainclude:e16.gsos
	copy	22:dsdb.equ
	keep	YDI.d
debugSymbols	gequ	TRUE
*-----------------------------------------------------------------------------*
* You Draw It!
*  V1.0b1- 05/25/92: Original new version, complying with G2MF 1.1.1. (1.0d33)
*          05/31/92: Updated to use T2 internal DrawString error module.
*  v1.0b2- 06/03/92: Fixed little bug where "Update" was getting enabled even
*                    when the user hit Cancel in the SFGetFile2 box. (1.0d34)
*  v1.0b3- 06/10/92: Updated for new HitT2 parms.
*                    Larger pathnames can be viewed (sticky space added)
*          06/14/92: Error now displayed if path rez can't be found. (1.0d34)
*  v1.0.1b1- 11/28/92: Fixed bug where unpack size was being set incorrectly
*                      (passed to unpackbytes).  T2v1.0.1b1.  Thanks GregT!
*            11/29/92: Handle of ATF unpacked pix data is always set to L=7d00.
*                      Handle of EATF unpacked pix data should be L=fa00.
*  v1.0.1f2- 1/12/92: GetFile path now set to folder of last frame file.
*                     (GregT, DinoB) - T2v1.0.1b4
*
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
Shape1Start    gequ  $00A2              +$2000 not included
Shape2Start    gequ  $00C0
Shape3Start    gequ  $00DE
Shape4Start    gequ  $00FC
Shape5Start    gequ  $011A
Shape6Start    gequ  $2442
Shape7Start    gequ  $2460
Shape8Start    gequ  $247E
Shape9Start    gequ  $249C
Shape10Start   gequ  $24BA
Shape11Start   gequ  $47E2
Shape12Start   gequ  $4800
Shape13Start   gequ  $481E
Shape14Start   gequ  $483C
Shape15Start   gequ  $00A2+$7D00        +$2000 not included
Shape16Start   gequ  $00C0+$7D00
Shape17Start   gequ  $00DE+$7D00
Shape18Start   gequ  $00FC+$7D00
Shape19Start   gequ  $011A+$7D00
Shape20Start   gequ  $2442+$7D00
Shape21Start   gequ  $2460+$7D00
Shape22Start   gequ  $247E+$7D00
Shape23Start   gequ  $249C+$7D00
Shape24Start   gequ  $24BA+$7D00
Shape25Start   gequ  $47E2+$7D00
Shape26Start   gequ  $4800+$7D00
Shape27Start   gequ  $481E+$7D00
Shape28Start   gequ  $483C+$7D00
LastShape5     gequ  $6A3A-$2000        +$E12000 not included
LastShape6     gequ  $71BA-$2000
LastShape7     gequ  $793A-$2000
LastShape8     gequ  $80BA-$2000
LastShape9     gequ  $883A-$2000
LastShape10    gequ  $6A4F-$2000
LastShape11    gequ  $71CF-$2000
LastShape12    gequ  $794F-$2000
LastShape13    gequ  $80CF-$2000
LastShape14    gequ  $884F-$2000

AlertUnknownError GEQU $07FEFFFD
*-----------------------------------------------------------------------------*
YDI            Start
   	debug	'You Draw It!'
	kind	$1000
	Using	YDIDATA

	copy	22:dsdb.asm

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
               tsc
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#7
	bge	notSupported
               asl   a                  ; Tranform into offset.
               tax
               jsr   (YDIActions,x)	; JSR to the appropriate action handler

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
YDIDATA	Data
               debug 'YDIDATA'

rYDIPathname	str	'YouDrawIt Path'	; rezName of wstring path rez

YDIActions	anop
               dc    i'doMake'          ; MakeT2 procedure	0
               dc    i'doSave'          ; SaveT2 procedure	1
	dc	i'doBlank'	; BlankT2 procedure	2
	dc	i'doLoadSetup'	; LoadSetupT2 procedure	3
	dc	i'doUnloadSetup'	; UnloadSetupT2 procedure 4
	dc	i'doKill'	; KillT2 procedure  	5
	dc	i'doHit'	; HitT2	procedure	6

WindPtr	ds	4
RezFileID	ds	2
MyID	ds	2
OurDP	ds	2
temp	ds	4
PathHandle	ds	4
PicHandle	ds	4
ErrorHandle	ds	4

OSErrorNum	ds	2
APFErrorNum	ds	2
MemErrorNum	ds	2

               End
*-----------------------------------------------------------------------------*
doLoadSetup	Start
;	dbrk	$0a
	debug	'doLoadSetup'
	Using	YDIData

;	dbrk	$cc

	stz	OSErrorNum
	stz	MemErrorNum
	stz	APFErrorNum

	~RMLoadNamedResource #rWString,#rYDIPathname
	bcc	PathOK
	plx
	plx
	stz	PackedHandle
	stz	PackedHandle+2
	stz	PicHandle
	stz	PicHandle+2
	lda	#$C0D
	sta	OSErrorNum
	rts

PathOK	anop
	jsr	makePdp
	pld
	PullLong pathname

	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rYDIPathname,#temp ; rID
	_DetachResource


; Load Picture
               _OpenGS openParams
	bcc	openOK
;	stz	PackedHandle
;	stz	PackedHandle+2
	stz	PicHandle
	stz	PicHandle+2
	brl	OSError

openOK         lda   OpenID
               sta   ReadID
               sta   CloseID

               lda   eof
               sta   readLength

               LongResult
               PushLong eof
               lda   <T2Data2+2	; memory ID
	pha
	sta	MyID
               PushWord #attrLocked+attrNoCross+attrNoSpec
               PushLong #0
               _NewHandle
               plx
               stx   PackedHandle
               plx
               stx   PackedHandle+2
	bcc	MemoryOK
	pha
               _CloseGS CloseParams     close picture
;	stz	PackedHandle
;	stz	PackedHandle+2
	stz	PicHandle
	stz	PicHandle+2
	pla
	brl	MemError

MemoryOK	PushLong PackedHandle
	jsr	makePdp
	pld
	pla
	sta	PicDestIN
	sta	PackedPtr
	pla
	sta	PicDestIN+2
	sta	PackedPtr+2

               _ReadGS ReadParams
	php
	pha
               _CloseGS CloseParams     close picture
	pla
	plp
	bcc	readOK
	pha
	~DisposeHandle PackedHandle
;	stz	PackedHandle
;	stz	PackedHandle+2
	stz	PicHandle
	stz	PicHandle+2
	pla
	brl	OSError

readOK	anop

; Unpack Picture

               lda   eof                load filesize
               clc                       and add to it the beginning
               adc   PackedPtr           of the file buffer
               sta   endfile            so we have the END of the file

               lda   eof+2
               clc                      just do the same for the high
               adc   PackedPtr+2           byte
               sta   endfile+2

checkmain      anop
	PushLong PackedPtr
	makeDP
	ldy   #5                 load the 5th byte of the data
               lda   [3],y
               and   #$7F7F             mask off the HIGH bits
               cmp   #$414D             is it a "MA"?
               jne   notpref            nope, this isn't the correct block
               iny                       or file
               iny
               lda   [3],y              get the next two bytes
               cmp   #$4E49             is it a "IN"?
               jne   notpref            nope

               ldy   #11                (pixelsperscanline)
               lda   [3],y              get the width of the picture
               sta   width

               cmp   #320               is it 320 mode?
               beq   pref2              yes
               cmp   #640               is it 640 mode?
               beq   pref2              yes

	killLdp
	brl	APFError

pref2          anop
               LongResult
               ldy   #13                get the number of palettes
               lda   [3],y
               pha                      multiply it by 32 bytes, which is
               PushWord #$0020          how many bytes per palette
               _Multiply
               pla                      pull the result
               sta   palettenum         store it as the byte offset past the
;               clc                      palettes information
;               adc   #17                add 17 to it to make it correct
;               sta   preftemp           store it as the preferred temp area
               plx
;
;               lda   palettenum         load the pointer to the SCBs
               sta   preftemp           and store it for future reference

               ldx   #0
               ldy   #13                initialize counters
pref5          iny
               iny
               lda   [3],y              we're just going to move the
	sta	Palette,x
               inx                      actual palettes area ($E19E00)
               inx  
	cpx	#$20
	bge	allDone
               lda   palettenum         decrement the palette size
               dec   a
               dec   a
               sta   palettenum         are we done yet?
               bne   pref5              no

allDone	anop
;	dbrk	$f0

               lda   preftemp           we're done
               clc                      adjust the SCBs pointer to skip
               adc   #15                the first bytes
               tay
               lda   [3],y              load the number of SCBs
	pha
               iny
               iny
	sty	ypatch+1
	asl	a
	asl	a
	clc
ypatch	adc	#$0000
;              adc   #4                 and adjust the pointer to
;              dex                      skip the entire SCBs area since
;              bne   pref6              we've already worked with it
               sta   preftemp           and finally point to the packed data!

	pla       	; get # scanlines

               LongResult               get memory for unpacked pic
	LongResult	; for multiply
	pha
	PushWord #160
	_Multiply
;               PushLong #$7D00*2
	lda	1,s
	sta	ScreenLength
;               pei   <T2Data2+2	; memory ID
	PushWord MyID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
               plx
               stx   PicHandle
               plx
               stx   PicHandle+2
	bcc	memOK1
	pha
	~DisposeHandle PackedHandle
	stz	PicHandle
	stz	PicHandle+2
	killLdp
	pla
	brl	MemError

memOK1	anop
	PushLong PicHandle
	jsr	makePdp
	pld
	PullLong ScreenHandle



;	dbrk	$f0

* bug squashed! 28 nov 92 v1.0.1b1 JRM! thanks GregT!
;               lda   #$7D00*2           the size of the screen for
;               sta   |ScreenLength       unpacking purposes

               WordResult
               PushWord |PackedPtr+2    push hi byte of buffer containing
;                                        the packed data
               lda   |PackedPtr         load the original buffer
               clc
               adc   preftemp           add the number of bytes to skip
               pha
               lda   eof                load the filesize
               sec                       and subtract from it the
               sbc   preftemp            number of bytes to skip
               pha
               PushLong #ScreenHandle   push handle to screen
               PushLong #ScreenLength   push pointer to screen size word
               _UnPackBytes
               pla                      discard result

               ~DisposeHandle PackedHandle ; get rid of packed data buffer
	killLdp	; get rid of PackedPtr (on stack)

* Old format ATF files should always have 200 lines of picture ($7d00 bytes)
* We set it to make sure, because sometimes the paint program the user was
* using will save the picture with 396 or 400 lines.  Since only the first 200
* are actually used for ATF format, the rest is a waste of memory.

	PushLong PicHandle
	jsr	makePdp
	lda	[3]
	killLdp
               cmp   #$D2FE             ID byte
               beq   NewFormat
	PushLong #$7D00
	PushLong PicHandle
	_SetHandleSize
	
NewFormat	anop
	~HUnLock PicHandle
	rts


! This routine helps us find the MAIN block in the APF file..
notpref        anop
               ldy   #2                   we're merely
               lda   [3],y                   going to add
               tay                        the block size of this "chunk"
               lda   [3]                     which is held in the
               clc                        first 4 bytes of
               adc   PackedPtr               the apple preferred format
               sta   PackedPtr               to the buffer address, and
               tya                        if we've reached
               adc   PackedPtr+2             the end of the
               sta   PackedPtr+2             file, we are
               lda   PackedPtr               done!
               cmp   endfile
               lda   PackedPtr+2
               sbc   endfile+2
               bcs   chunkErr           if no MAIN chunk found, there is no
;                                        picture data, so abort

	killLdp
	brl	checkmain

chunkErr	anop
	~DisposeHandle PackedHandle
	stz	PicHandle
	stz	PicHandle+2
	killLdp
	brl	APFError	

screenHandle   dc    i4'0'
screenLength   dc    i2'0'

openParams     anop
               dc    i'12'              pcount
openID         ds    2                  reference number
pathname       dc    i4'0'
               dc    i'0'               request_access
               dc    i'0'               resource_num
               ds    2                  access
               ds    2                  file_type
               ds    4                  aux_type
               ds    2                  storage_type
               ds    8                  create_td
               ds    8                  modify_td
               ds    4                  option_list
eof            ds    4

readParams     anop
               dc    i'4'
readID         ds    2                  reference number
picDestIN      ds    4                  pointer to DATA buffer
readLength     ds    4                  this many bytes
               ds    4                  how many xfered

closeParams    anop
               dc    i'1'
closeID        ds    2                  reference number

palettenum     ds 2                     ; offset into palettes from preferred
width          ds 2                     ; width of preferred file
preftemp       ds 2                     ; temporary Apple Preferred format cntr
scbnum         ds 2                     ; number of SCB we're on
endfile        ds 4                     ; end of buffer for Preferred

PackedHandle	ds	4
PackedPtr	ds	4

OSError	anop
	sta	OSErrorNum
	rts

APFError	anop
	lda	#-1
	sta	APFErrorNum
	rts

MemError	anop
	sta	MemErrorNum
	rts

               End
*-----------------------------------------------------------------------------*
doUnloadSetup	Start
;	dbrk	$a0
	debug	'doUnloadSetup'
	Using	YDIDATA

;	dbrk	$01

;	~DisposeHandle PathHandle
	~DisposeHandle PicHandle
	clc		; no setup to unload!
	rts

               End
*-----------------------------------------------------------------------------*
doMake         Start
	Using	YDIDATA
	debug 'doMake'

;	dbrk	$02

               lda   <T2data1+2
               sta   WindPtr+2
               lda   <T2data1
               sta   WindPtr
               lda   <T2data2
               sta   RezFileID
               lda   <T2data2+2
               sta   MyID

; Create our controls.

               LongResult
               pei   <T2data1+2
               pei   <T2data1
               PushWord #resourceToResource
               PushLong #YDI_CtlLst
               _NewControl2
               plx
               plx

; Make sure we're dealing with the T2pref file.

               ~GetCurResourceFile

               pei   <T2data2
               _SetCurResourceFile


; Load the animation path resource.

	~RMLoadNamedResource #rWString,#rYDIPathname
               bcc   pathThere
	plx
	plx
	stz	PathHandle
	stz	PathHandle+2
;	lda	#UnknownStr
;	sta	PathPtr
;	lda	#^UnknownStr
;	sta	PathPtr+2
	PushLong #UnknownStr
	makeDP
	bra	moveOn

PathThere	anop
	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rYDIPathname,#temp ; rID
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

	lda	#4
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

	~LoadResource #rTextForLETextBox2,#AnimPath_LText
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

	~ReleaseResource #3,#rTextForLETextBox2,#AnimPath_LText

	PushLong PathPtr
	makeDP
	dec	<3
	lda	[3]
	xba
	sta	[3]
	killLdp

	~LoadResource #rControlTemplate,#YDIAnimPathStrCtl
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
doSave         Start
               Using YDIDATA
	debug 'doSave'

;	dbrk	$03

	lda	PathHandle
	ora	PathHandle+2
	bne	notNIL
	rts

notNIL	~GetCurResourceFile
               ~SetCurResourceFile RezFileID

	PushWord #rWString	; for RMSetResourceName
	~RMFindNamedResource #rWString,#rYDIPathname,#temp ; rID
	PushWord #rWString	; rType
	lda	5,s	
	pha
	lda	5,s
	pha
	_RemoveResource
	PushLong #ZeroString	; no rezName
	_RMSetResourceName

* new!!!!!!!!! 12/30/92 JRM

	WordResult
	~GetCurResourceApp
	PushLong PathHandle
	_SetHandleID
	plx

	PushLong PathHandle	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rWString	; rType
	~UniqueResourceID #$FFFF,#rWString ; rID
	lda	1,s
	sta	tempHandle
	lda	1+2,s
	sta	tempHandle+2
	_AddResource

	PushWord #rWString	; rType
	PushLong tempHandle	; rID
	PushLong #rYDIPathname 	; ptr to name str
	_RMSetResourceName

; Update the file and restore original rezFile.

               ~UpdateResourceFile RezFileID

	~RMLoadNamedResource #rWString,#rYDIPathname
	PullLong PathHandle

	PushWord #rWString	; rtype
	~RMFindNamedResource #rWString,#rYDIPathname,#temp ; rID
	_DetachResource

skipSave	anop

               _SetCurResourceFile
               rts

tempHandle	ds	4
ZeroString	str	''

               End
*-----------------------------------------------------------------------------*
doHit	Start
	debug	'doHit'
	Using	YDIDATA

	stz	<T2Result+2
	stz	<T2Result
	lda	<t2data2+2	; ctlID hi word must be zero
	bne	nothingHit
	lda	<t2data2
	cmp	#1
	beq	pathBtnHit
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
	pha
               ~UnloadOneTool #$17
	pla
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
               ~UnloadOneTool #$17
	pla
	brl	DoUnknownErrorAlert

SFOK	anop
active         anop

	brk
	brk

               stz   PrefixHndl
               stz   PrefixHndl+2

               ~GetCurResourceFile
               ~SetCurResourceFile RezFileID

	~RMLoadNamedResource #rWString,#rYDIPathname
	bcc	PathOK
	plx
	plx
	brl	skipSetPath

PathOK	anop
	lda	1,s
	sta	pathH
	lda	1+2,s
	sta	pathH+2
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
	~RMFindNamedResource #rWString,#rYDIPathname,#temp ; rID
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
;               ora   #pathBuffAuxID
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
	~GetCtlHandleFromID WindPtr,#2 ; animpathctl id
               lda   1,s
               sta   5,s
               lda   1+2,s
               sta   5+2,s
               _HideControl
               _DisposeControl

	jsr	substitute

	rts

SFStatus       ds    2

OpenString     str   'Use which animation file?'

TypeList       anop
               dc    i'4'               number of types
               dc    i'$0000'           flags: normal.. :-)
               dc    i'$C0'             fileType
               dc    i4'$0002'          auxType
               dc    i'$A000'           flags: dim all $C1 file entries
               dc    i'$C1'             fileType
               dc    i4'0'              auxType
               dc    i'$2000'           flags: dim all $C0 $0000 pics
               dc    i'$C0'             fileType
               dc    i4'$0000'          auxType
               dc    i'$2000'           flags: dim all $C0 $0001 pics 
               dc    i'$C1'             fileType
               dc    i4'$0001'          auxType

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
doKill	Start
	debug	'doKill'
	Using	YDIDATA

;	dbrk	$04

	~DisposeHandle PathHandle
	rts

               End
*-----------------------------------------------------------------------------*
doBlank	Start
;	dbrk	$BA
	debug	'doBlank'
	Using	YDIDATA

PicPtr         equ  <0
SLookUp        equ  PicPtr+4
x              equ  SLookUp+4
y              equ  x+2
CurrX          equ  y+2
CurrY          equ  CurrX+2
CurrShape      equ  CurrY+2
YSave          equ  CurrShape+2
NumShapes      equ  YSave+2
depth          equ  NumShapes+2
Action         equ  depth+2
twice          equ  Action+2
bottom         equ  twice+2

	lda	APFErrorNum
	beq	noAPF
	brl	doAPFerr
noAPF	lda	OSErrorNum
	beq	noOS
	brl	doOSerr
noOS	lda	MemErrorNum
	beq	noLoadSetupErr
	brl	doMemErr

noLoadSetupErr	phd
	lda	|OurDP
	tcd

;	dbrk	$10

;	lda	CLOCKCTL
;	and	#$FFF0
;	sta	CLOCKCTL

               ~GetAddress #1
               PullLong <SLookUp         get pointer to table

	~HLock PicHandle

;               ldx   #$7E00-2           make screen black; zero pixel data
;               lda   #0
;nextZero       sta   $E12000,x
;               dex
;               dex
;               bpl   nextZero


	PushLong |PicHandle
	jsr	makePdp
	pld
	PullLong <PicPtr

               lda   [PicPtr]
               cmp   #$D2FE             ID byte
               jeq   NewFormat

; Check how many frames are in animation

               ldy   #lastshape5
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last5
               ldy   #lastshape6
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last6
               ldy   #lastshape7
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last7
               ldy   #lastshape8
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last8
               ldy   #lastshape9
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last9
               ldy   #lastshape10
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last10
               ldy   #lastshape11
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last11
               ldy   #lastshape12
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last12
               ldy   #lastshape13
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last13
               ldy   #lastshape14
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   last14

               brl   BadATFFile
*               brl   exitWithBeep       user messed up...
;	brl	exitHere

last5          anop
               lda   #5
               sta   numShapes
               brl   cont
last6          anop
               lda   #6
               sta   numShapes
               brl   cont
last7          anop
               lda   #7
               sta   numShapes
               brl   cont
last8          anop
               lda   #8
               sta   numShapes
               brl   cont
last9          anop
               lda   #9 
               sta   numShapes
               brl   cont
last10         anop
               lda   #10
               sta   numShapes
               brl   cont
last11         anop
               lda   #11
               sta   numShapes
               brl   cont
last12         anop
               lda   #12
               sta   numShapes
               brl   cont
last13         anop
               lda   #13
               sta   numShapes
               brl   cont
last14         anop
               lda   #14
               sta   numShapes
               brl   Cont


NewFormat      anop
               ldy   #lastshape5
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast10
               ldy   #lastshape6
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast12
               ldy   #lastshape7
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast14
               ldy   #lastshape8
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast16
               ldy   #lastshape9
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast18
               ldy   #lastshape10
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast20
               ldy   #lastshape11
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast22
               ldy   #lastshape12
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast24
               ldy   #lastshape13
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast26
               ldy   #lastshape14
               lda   [PicPtr],y
               cmp   #$EEEE
               bne   aLast28

               brl   BadATFFile
*               brl   exitWithBeep       user messed up...
;	brl	exitHere

aLast10        anop
               lda   #10
               sta   numShapes
               bra   cont
aLast12        anop
               lda   #12
               sta   numShapes
               bra   cont
aLast14        anop
               lda   #14
               sta   numShapes
               bra   cont
aLast16        anop
               lda   #16
               sta   numShapes
               bra   cont
aLast18        anop
               lda   #18
               sta   numShapes
               bra   cont
aLast20        anop
               lda   #20
               sta   numShapes
               bra   cont
aLast22        anop
               lda   #22
               sta   numShapes
               bra   cont
aLast24        anop
               lda   #24
               sta   numShapes
               bra   cont
aLast26        anop
               lda   #26
               sta   numShapes
               bra   cont
aLast28        anop
               lda   #28
               sta   numShapes
               bra   Cont


cont           anop

; Zero variables
               stz   CurrShape
               stz   y
               stz   x
               stz   Action
               stz   twice

	
           	ldx	#$20-2
copyPals	lda	Palette,x
	sta	$E19E00,x
	dex
	dex
	bpl	copyPals


; Main animation loop
mainloop       anop
               lda   CurrShape
               asl   a                  times two
               tax
               lda   AddrTable,x        get start addr from table
               sta   YSave

               lda   y
               clc
               adc   #50
               lsr   a
               clc
               adc   #$80
               sta   Bottom
               shortm
wait2          lda   >$E0C02E
               cmp   Bottom
               bne   wait2
               longm
               jsr   CopyShape

	pld		; restore DP aligned with stack parms
               lda   [T2data1]	; movePtr
               jne   exitHere
	phd		; save DP aligned with stack
	lda	OurDP	; restore our DP space
	tcd

               lda   Action
               beq   down_right
               cmp   #1
               beq   up_right
               cmp   #2
               beq   down_left
               cmp   #3
               beq   up_left

up_left        anop
               lda   y
               dec   a
               jeq   downLeftNext
               sta   y

               lda   x
               dec   a
               jeq   upRightNext
               sta   x
               bra   next

down_left      anop
               lda   y
               inc   a
               cmp   #199-56
               jeq   upLeftNext
               sta   y

               lda   x
               dec   a
               jeq   downRightNext
               sta   x
               bra   next

up_right       anop
               lda   y
               dec   a
               jeq   downRightNext
               sta   y

               lda   x
               inc   a
               cmp   #160-28
               jeq   upLeftNext
               sta   x
               bra   next

down_right     anop
               lda   y
               inc   a
               cmp   #199-56
               jeq   upRightNext
               sta   y

               lda   x
               inc   a
               cmp   #160-28
               jeq   downLeftNext
               sta   x

next           anop

               lda   twice
               beq   noIncShape

               lda   CurrShape
               inc   a
               cmp   numShapes
               bne   fine
               lda   #0
fine           sta   CurrShape
               stz   twice
               brl   mainloop

noIncShape     anop
               lda   #1
               sta   twice
               brl   mainloop




upRightNext    anop
               lda   #1
               sta   Action
               brl   next
downLeftNext   lda   #2
               sta   Action
               brl   next
downRightNext  stz   Action
               brl   next
upLeftNext     lda   #3     
               sta   Action
               brl   Next

CopyShape      anop
               lda   y
               sta   CurrY
               lda   x
               sta   CurrX

               lda   #56
               sta   Depth

copyLoop       anop
               lda   CurrY              y = y coordinate
               asl   a                  multipy by 2 to get index into table
               tay
               lda   [SLookUp],y        get address from table
               clc                      add x to base address
               adc   CurrX              x = horizontal position (in bytes)
               sta   Fill+1

               ldx   #0
               ldy   YSave
copyLine       lda   [PicPtr],y
fill           sta   $E12000,x
               iny
               iny
               inx
               inx
               cpx   #28                28 bytes wide
               bne   copyLine

               lda   YSave
               clc
               adc   #$A0               1 line down into shape
               sta   YSave

               inc   CurrY              store 1 line down into SHR

               dec   depth
               bne   copyLoop
               rts


AddrTable      anop
               dc    i'Shape1start,shape2start,shape3start,shape4start'
               dc    i'shape5start,shape6start,shape7start,shape8start'
               dc    i'shape9start,shape10start,shape11start,shape12start'
               dc    i'shape13start,shape14start'
               dc    i'shape15start,shape16start,shape17start,shape18start'
               dc    i'shape19start,shape20start,shape21start,shape22start'
               dc    i'shape23start,shape24start,shape25start,shape26start'
               dc    i'shape27start,shape28start'

;NotFoundString str   '$8000: Animation template file loading error.'
;BadCountString str   '$8001: Number of frames not marked correctly.'
;BadAPFString   str   '$8002: APF animation picture is unusable.'
;MemoryString   str   '$8003: Unable to allocate necessary memory.'
;StartupString  str   '$8004: Unable to startup StandardFile tool.'


exitHere       entry
	~HUnLock PicHandle
	rts

Palette	entry
	ds	32


doOSerr	anop
	lda	OSErrorNum
	cmp	#$C0D
	jeq	PathRezErr

	~HexIt OSErrorNum	; convert error to ascii
	PullLong asciiOSErr

               LongResult
               PushLong #OSErrLen
               pei   <T2Data2+2	; memory ID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	PullLong <T2Result

	PushLong #OSErrMsg
	pei	<T2Result+2
	pei	<T2Result
	PushLong #OSErrLen
	_PtrToHand
	rts

OSErrMsg	dc	c'Attention: Twilight II YouDrawIt! Module Error!',h'0d'
	dc	c'Could not read/find animation template file! ($'
asciiOSErr	dc	c'????)',h'00'
OSErrEnd	anop
OSErrLen   	equ	OSErrEnd-OSErrMsg


pathRezErr	LongResult
               PushLong #PathRezErrLen
               pei   <T2Data2+2	; memory ID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	PullLong <T2Result

	PushLong #PathRezErrMsg
	pei	<T2Result+2
	pei	<T2Result
	PushLong #PathRezErrLen
	_PtrToHand
	rts

PathRezErrMsg	dc	c'Attention: Twilight II YouDrawIt! Module Error!',h'0d'
	dc	c'Could not read/find animation pathname resource!',h'00'
PathRezErrEnd	anop
PathRezErrLen	equ	PathRezErrEnd-PathRezErrMsg


doMemErr	anop
	~HexIt MemErrorNum	; convert error to ascii
	PullLong asciiMemErr

               LongResult
               PushLong #MemErrLen
               pei   <T2Data2+2	; memory ID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	PullLong <T2Result

	PushLong #MemErrMsg
	pei	<T2Result+2
	pei	<T2Result
	PushLong #MemErrLen
	_PtrToHand
	rts

MemErrMsg	dc	c'Attention: Twilight II YouDrawIt! Module Error!',h'0d'
	dc	c'Could not allocate enough memory to run! ($'
asciiMemErr	dc	c'????)',h'00'
MemErrEnd	anop
MemErrLen   	equ	MemErrEnd-MemErrMsg



doAPFerr	anop
               LongResult
               PushLong #APFErrLen
               pei   <T2Data2+2	; memory ID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	PullLong <T2Result

	PushLong #APFErrMsg
	pei	<T2Result+2
	pei	<T2Result
	PushLong #APFErrLen
	_PtrToHand
	rts

APFErrMsg	dc	c'Attention: Twilight II YouDrawIt! Module Error!',h'0d'
	dc	c'Bad animation (Apple Preferred Format) file!'
APFErrEnd	anop
APFErrLen   	equ	APFErrEnd-APFErrMsg


badATFFile	anop
               LongResult
               PushLong #ATFErrLen
               pei   <T2Data2+2	; memory ID
               PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
               _NewHandle
	PullLong <T2Result

	PushLong #ATFErrMsg
	pei	<T2Result+2
	pei	<T2Result
	PushLong #ATFErrLen
	_PtrToHand

	~HUnLock PicHandle
	pld
	rts

ATFErrMsg	dc	c'Attention: Twilight II YouDrawIt! Module Error!',h'0d'
	dc	c'Bad anim template file (number of frames marked bad)!'
ATFErrEnd	anop
ATFErrLen   	equ	ATFErrEnd-ATFErrMsg

               End
*-----------------------------------------------------------------------------*
	copy	22:makePdp.ASM
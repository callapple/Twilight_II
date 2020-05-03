         setcom 80
               mcopy list.mac
               copy  13:ainclude:e16.memory
               copy  13:ainclude:e16.gsos
	copy	13:ainclude:e16.locator
	copy	13:ainclude:e16.types
	copy	13:ainclude:e16.resources
	copy	13:ainclude:e16.quickdraw
	keep	list
	copy	v1.2.equ
	copy	equates
	copy	debug.equ
*-----------------------------------------------------------------------------*
* ======Twilight II======
* list.asm source code segment
*
* All routines dealing with the module list...
*
* Created: 4 Jan 94, JRM.
*-----------------------------------------------------------------------------*
t2dir_prefix	Start
	Using	FileDATA
	Using	GlobalDATA

	copy	22:debug.asm

set_t2save_pfx ename
	mvl	ConfigPathPtr,pSPfx_prefix	
	bra	common

set_t2module_pfx ename
	mvl	ModulePath,pSPfx_prefix

common	anop
               stzl	PrefixHndl

               mvw   #255,BufLength	; Set the length of the output buffer
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

skipSetPath	anop
	rts

***************************************

restore_prefix	ename
	lda	PrefixHndl
	ora	PrefixHndl+2
	beq	noRestore

               inc   pGPfx_prefix       ; set prefix back to what it was
               inc   pGPfx_prefix       ; before (skipping buffer length word)
               _SetPrefixGS pGPfx
               ~DisposeHandle PrefixHndl ; and get rid of the prefix handle

noRestore	anop
	rts

	End
*-----------------------------------------------------------------------------*
CHECK_REBUILD	Start
	Using	FileDATA
	Using	GlobalDATA	; for myID
	debug	'CHECK_REBUILD'

	stzl	dataH

	jsr	set_t2save_pfx

	_OpenGS pOpenData
	bcc	found
	pha
	jsr	restore_prefix
	pla
	cmp	#fileNotFound
	jeq	REBUILD

	dbrk	$61
	jsr	restore_prefix
	lda	#0
	sec
	rts

found	anop
	jsr	restore_prefix
	jsr	set_t2module_pfx

	lda	pOpenData_refNum
	sta	pGetEOFData_refNum
	sta	pCloseData_refNum
	sta	pReadWriteData_refNum

	_GetEOFGS pGetEOFData
	errorbrk

               LongResult
               PushLong pGetEOFData_eof
               lda   MyID
               ora   #pathBuffAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               bcc   allocOK
               plx
               plx
               lda   #T2CantGetMemory_LText
               ldx   #^T2CantGetMemory_LText
               jsr   cantOpen
	lda	#-1
	sec
               rts

allocOK	anop
	makeDP
               ldy   #2                 ; Dereference it
               lda   <3
               sta   dataH
               lda   <5
               sta   dataH+2
               lda   [3]
               tax
               lda   [3],y
               sta   <5
	sta	pReadWriteData_dataBuffer+2
               stx   <3
	stx	pReadWriteData_dataBuffer

	mvl	pGetEOFData_eof,pReadWriteData_requestCount

	_ReadGS pReadWriteData
	errorbrk
	_CloseGS pCloseData
	errorbrk

;	ldy	#odata_Signature
	lda	[3]
	cmp	#"2T"
	jne	go_rebuild
	ldy	#odata_Version
	lda	[3],y
	cmp	#2
	jne	go_rebuild

	mvw	#odata_dirInfo,dataOffset

               stz   num_modules

               _OpenGS pOpenT2Dir	; Try to open the Twilight directory
               bcc   openOk

* ADD: X out T2, display error with showbootinfo

	~DisposeHandle dataH
	stzl	dataH

               lda   #T2CantDoFileStuff_LText ; and put the file error in the
               ldx   #^T2CantDoFileStuff_LText ; window
               jsr   cantOpen
	lda	#-1
	sec
               rts

openOk         anop
               lda   pOpenT2Dir_refNum
               sta   pCloseDir_refNum
               sta   pEntry_refNum

* first check the modification time on the directory..
* if it's the same as the time stored in twilight.data, then assume that
*  all the modules are the same and twilight.data is current and doesn't
*  have to be rebuilt
* if it's different, than manually check if twilight.data needs rebuilding

;	brk	$54	; shit (temp)
	ldy	#odata_t2dir_mod_TD
	lda	pOpenT2Dir_modifyTD
	cmp	[3],y
	bne	nextFile	; check manually
	iny
	iny
	lda	pOpenT2Dir_modifyTD+2
	cmp	[3],y
	bne	nextFile	; check manually
	iny
	iny
	lda	pOpenT2Dir_modifyTD+4
	cmp	[3],y
	bne	nextFile	; check manually
	iny
	iny
	lda	pOpenT2Dir_modifyTD+6
	cmp	[3],y
	bne	nextFile	; check manually
	brl	abs_no_rebuild	; t2.data is perfectly current!

nextFile       anop
;	debug	'nextFile'
	ldx	#34-2	; (MaxFSTLen+2)-2
zeroFile	stz	FileName+2,x
	dex
	dex
	bpl	zeroFile

	_GetDirEntryGS pEntry    ;Now get the name of the next file
               bcc   dirOk              ;in the Twilight folder. If we're
               cmp   #endOfDir          ;at the end then goto done. Otherwise
               jeq   done_Scan          ;check to see if there was an error
               _CloseGS pCloseDir	;other than EndOfDir.Yes? we be screwed

* ADD: X out T2, display error with showbootinfo

	~DisposeHandle dataH
	stzl	dataH

               lda   #T2CantDoFileStuff_LText ; and put the file error in the
               ldx   #^T2CantDoFileStuff_LText ; window
               jsr   cantOpen
	lda	#-1
	sec
               rts

dirOk          anop
	lda   pEntry_filetype    ;see if the file was a Twilight module
               cmp   #$BC               ;if not, then this one doesn't count
               bne   nextFile           ;--go find the next one
               lda   pEntry_auxType
               cmp   #$4004
	bne   nextFile
               lda   pEntry_auxType+2
;	cmp   #$0000
               bne   nextFile

               inc   num_modules         ;Now increment the number of files and

	ldy	dataOffset
	ldx	#0
testInfo	anop
	lda	[3],y
	cmp	pEntry_fileType,x
	bne	go_rebuild
	iny
	iny
	inx
	inx
	cpx	#32
	blt	testInfo

	tya		; y at odata_moduleFlags now
	clc
	adc	#34
;	sta	dataOffset	; now at odata_moduleFName+30

	tay
	ldx	#0
testName	anop
	lda	[3],y
	cmp	fileName_textlen,x
	bne	go_rebuild
	iny
	iny
	inx
	inx
	cpx	#34	; maxFSTLen+2
	blt	testName

	sty	dataOffset
	brl	nextFile

go_rebuild	anop
	killLdp
	~DisposeHandle dataH
	stzl	dataH
	_CloseGS pCloseDir	; Now that we're done, close the dir.
	errorbrk
	jsr	restore_prefix
	brl	REBUILD

done_scan	anop
	ldy	#odata_num_modules
	lda	[3],y
	cmp	num_modules
	bne	go_rebuild

no_rebuild	anop
* If, after all that checking work, we determined that the twilight.data
* file doesn't need to be rebuilt, then update the time field in the header
* so next time we can hopefully skip all this work.
* For instance, finder.data could keep changing in */system/cdevs/twilight,
* causing the folder modTD to keep changing... if this happened, our shortcut
* of checking the time (before going thru a whole long search above) will
* never be allowed to work, because we will always do the long search and then
* always conclude the file doesn't have to be rebuilt, but we will never update
* it with the new time!  So update it with the new time...

* update modTD of T2 module dir in header...
	mvl	pOpenT2Dir_modifyTD,t2dir_modTD
	mvl	pOpenT2Dir_modifyTD+4,t2dir_modTD+4
* make sure other header fields are correct
	ldy	#odata_num_modules
	lda	[3],y
	sta	num_modules
	ldy	#odata_num_support_setup
	lda	[3],y
	sta	num_support_setup

* header is now revised!  let's write it out..
	jsr	restore_prefix	; get rid of t2module prefix
	jsr	set_t2save_pfx	; set t2save prefix

	_OpenGS pOpenData
	errorbrk $aa
               mvw   pOpenData_refNum,pCloseData_refNum
	jsr	write_header
	_CloseGS pCloseData

	PushLong dataH
	jsr	makePdp
	pld
	PullLong pReadWriteData_dataBuffer

abs_no_rebuild	anop

* kill [3]
	killLdp

;	~DisposeHandle dataH	; save it so we don't have to reload it

	jsr	restore_prefix

	_CloseGS pCloseDir	; Now that we're done, close the dir.
	errorbrk

	clc
	rts

	End
*-----------------------------------------------------------------------------*
FileDATA	DATA
	Using	GlobalDATA	; for modulePath
	debug	'FileDATA'

PrefixHndl     handle                   ; handle to the old prefix 31
BufLength      dc    i4'255'
pGPfx          PrefixRecGS (0,0)
pSPfx          PrefixRecGS (0,0)

header	anop		; 16 byte header (v2)
	dc	c'T2'	; t2 signature
	dc	i'2'	; version 1
num_modules	ds	2
num_support_setup ds	2
t2dir_modTD	ds	8	; mod date/time of T2 module dir

* new (v2) file format:
* 00-01: signature - "T2" ascii
* 02-03: version - 0002 - v2 (version number)
* 04-05: num_modules - to follow
* 06-07: num_support_setup - (cannot exceed num_modules)
* 08-15: t2dir_mod_TD - modification time/date of t2 directory (8 bytes)
* start of module_data
* 16-47: dirInfo - (32 bytes) directory entry info, module 1
* 48-81: moduleFlags - (34 bytes) rT2moduleFlags, module 1
* 82-115: moduleFName (34 bytes, MaxFSTLen+2) - filename of module
* etc.

* old file format: (version 1)
* 00-01: signature - "T2" ascii
* 02-03: version - 0001 version number
* 04-05: num_modules - to follow
* 06-07: num_support_setup - (cannot exceed num_modules)
* start of module_data
* 08-39: dirInfo - (32 bytes) directory entry info, module 1
* 40-73: moduleFlags - (34 bytes) rT2moduleFlags, module 1
* 74-105: moduleFName (32 bytes, MaxFSTLen) - filename of module
* etc.

dataH	handle	; handle to twilight.data buffer

ThermoCtlH	handle	; handle to thermometer control..

module_data	anop		; 100 bytes
infoBuffer	ds	32	; dirInfo - 32 bytes
flagBuffer	ds	34	; moduleFlags - 34 bytes
moduleFName	ds	34	; maxFSTlen+2 - 32 bytes

pDestroyData	NameRecGS (t2dataWStr)
t2DataWStr	GSStr 'Twilight.Data'
pCreateData	CreateRecGS (t2dataWStr,$E3,$F8,$00000000)
pOpenData	OpenRecGS (0,t2DataWStr,readWriteEnable)
pReadWriteData	IORecGS (0,0,0,0)
pCloseData	RefNumRecGS (0)
pSetMarkData	SetPositionRecGS (0,startPlus,0) ; base = displacement
pSetEOFData	SetPositionRecGS (0,startPlus,header_size) ; set EOF to header_size
pGetEOFData	EOFRecGS (0,0)


*** set prefix to module directory
* error during write ....... etc.

* +0 fileType dc i2' & parameters(7)'
* +2 eof dc i4' & parameters(8)'
* +6 blockCount dc i4' & parameters(9)'
* +10 createTD dc i8' & parameters(10)'
* +18 modifyTD dc i8' & parameters(11)'
* +26 access dc i2' & parameters(12)'
* +28 auxType dc i4' & parameters(13)'
* +32 end.

dataOffset	ds	2	; offset into twilight.data
FileName       C1Result MaxFSTLen+4
pOpenT2Dir	OpenRecGS (0,ModulePath+2,readEnable,0,0,0,0,0,0,0)
pEntry         DirEntryRecGS (0,0,1,1,FileName,0,0,0,0,0,0,0,0)
pCloseDir	RefNumRecGS (0)

* for getting our pathname at BootCDEV time...
pRefInfo       RefInfoRecGS (0,0,NameBuffer)
NameBuffer     C1Result 256

	End
*-----------------------------------------------------------------------------*
REBUILD	Start
	Using	GlobalDATA	; for RezID
	Using	FileDATA
	debug	'REBUILD'

* REBUILD MUST _NOT_ be entered with prefix 8 set to the t2 module folder!!!
* prefix 8 should now be undisturbed!

	jsr	set_t2save_pfx

	_DestroyGS pDestroyData

	_CreateGS pCreateData
	bcc	create_ok
	dbrk	$60
	lda	#0
	sec
	rts	

create_ok	anop
	_OpenGS pOpenData
	bcc	open_ok
	dbrk	$61
	lda	#0
	sec
	rts	

open_ok	anop
	jsr	restore_prefix
	jsr	set_t2module_pfx

               lda   pOpenData_refNum
               sta   pCloseData_refNum
               sta   pReadWriteData_refNum
	sta	pSetMarkData_refNum
	sta	pSetEOFData_refNum

	_SetEOFGS pSetEOFData	; set EOF to header_size
	bcc	seteof_ok
	dbrk	$62
	_CloseGS pCloseData
	lda	#0
	sec
	rts	

seteof_ok	anop
	mvl	#header_size,pSetMarkData_displacement
	_SetMarkGS pSetMarkData	; set mark to header_size
	bcc	setmark_ok
	dbrk	$63
	_CloseGS pCloseData
	lda	#0
	sec
	rts	

setmark_ok	anop
               stz   num_modules	; zero some vars
               stz   num_support_setup

               _OpenGS pOpenT2Dir            ; Try to open the Twilight directory
               bcc   openOk

* ADD: X out T2, display error with showbootinfo

               lda   #T2CantDoFileStuff_LText ; and put the file error in the
               ldx   #^T2CantDoFileStuff_LText ; window
               jsr   cantOpen
	lda	#-1
	sec
               rts

openOk         anop
               lda   pOpenT2Dir_refNum
               sta   pCloseDir_refNum
               sta   pEntry_refNum

* open new status window!

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
               PushLong #T2_Wait_Window
               PushWord #rWindParam1
               _NewWindow2
               lda   1,s
               sta   TempPtr
               lda   1+2,s
               sta   TempPtr+2
               _SetPort
               ~SetFontFlags #$0004     ; use dithered color text in window...

* in 320 mode we'll have to move the window before making it visible..

	~GetMasterSCB
	pla
	bit	#mode640
	bne	make_visible
	~MoveWindow #23,#53,TempPtr

make_visible	anop
	~ShowWindow TempPtr

	jsl	ContentDraw	; draw the controls..

* get how many files are in the directory, so we can set the scale of the
* thermometer..

	mvw	#1,scale	; init scale to 1

	stz	pEntry_base	; make 'em both 0 so GS/OS will tell us
	stz	pEntry_displacement	; how many files are in the dir

	_GetDirEntryGS pEntry
	bcs	skip_scale	; leave scale at 1 if there's an error

	mvw	pEntry_entryNum,scale ; get count of files
skip_scale	anop

	lda	#1	; restore back to original values
	sta	pEntry_base
	sta	pEntry_displacement

* Get the control handle of the thermometer control..

	~GetCtlHandleFromID TempPtr,#1	; id = 1
	PullLong ThermoCtlH

* Set the scale of the thermometer..

	PushWord #0	; high word must be 0
	PushWord scale
	PushLong ThermoCtlH
	_SetCtlTitle

* update modTD of T2 module dir in header...

	mvl	pOpenT2Dir_modifyTD,t2dir_modTD
	mvl	pOpenT2Dir_modifyTD+4,t2dir_modTD+4

nextFile       anop
;	debug	'nextFile'

	ldx	#34-2	; (MaxFSTLen+2)-2
zeroFile	stz	FileName+2,x
	dex
	dex
	bpl	zeroFile

	jsr	inc_mercury	; update thermometer

	_GetDirEntryGS pEntry    ;Now get the name of the next file
               bcc   dirOk              ;in the Twilight folder. If we're
               cmp   #endOfDir          ;at the end then goto done. Otherwise
               jeq   done               ;check to see if there was an error
               _CloseGS pCloseDir	;other than EndOfDir.Yes? we be screwed

               ~CloseWindow TempPtr	; close status window

* ADD: X out T2, display error with showbootinfo

               lda   #T2CantDoFileStuff_LText ; and put the file error in the
               ldx   #^T2CantDoFileStuff_LText ; window
               jsr   cantOpen
	lda	#-1
	sec
               rts

dirOk          lda   pEntry_filetype    ;see if the file was a Twilight module
               cmp   #$BC               ;if not, then this one doesn't count
               bne   nextFile           ;--go find the next one
               lda   pEntry_auxType
               cmp   #$4004
               bne   nextFile
               lda   pEntry_auxType+2
;	cmp   #$0000
               bne   nextFile

	ldx	#32-2
copyInfo	lda	pEntry_fileType,x
	sta	infoBuffer,x
	dex
	dex
	bpl	copyInfo

	ldx	#34-2	; (MaxFSTLen+2)-2
copyName	lda	fileName_textLen,x
	sta	moduleFName,x
	dex
	dex
	bpl	copyName

	anop		; Open the file whose name we just
               WordResult
               PushWord #readEnable     ; file access
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
	PushLong #fileName_textLen ; pointer to C1 pathname of rez file
               _OpenResourceFile
	bcc	no_err
	brl	nextFile	; no resource fork!!!!! OH NO!
no_err         PullWord RezID

               ~LoadResource #rT2ModuleFlags,#1 ; get module flags resource,
	bcc	flagThere
	plx
	plx
               ~CloseResourceFile RezID ; and close the file
	errorbrk $63
	brl	nextFile

flagThere	anop		; srcH already on stack
	PushLong #flagBuffer
	PushLong #34	; rT2ModuleFlags are 34 bytes long
	_HandToPtr

	~ReleaseResource #3,#rT2ModuleFlags,#1

               ~CloseResourceFile RezID ; and close the file
	errorbrk $64

;	ldx	#oMV_version
	lda	flagBuffer
	and	#$FF
	cmp	#1
	beq	good_version
bad_version	anop
	brl	nextFile

good_version	anop
	ldx	#oMF_flags
	lda	flagBuffer,x
;	sta	T2ModuleFlags
               bit   #fSetup	; does it support setup?
               beq   noImportance       ; no.
               inc   num_support_setup    ; yes, so inc the setup count.
noImportance	anop

               inc   num_modules         ;Now increment the number of files and

	mvw	#100,pReadWriteData_requestCount
;	lda	#0
	stz	pReadWriteData_requestCount+2
	mvl	#module_data,pReadWriteData_dataBuffer

	_WriteGS pReadWriteData
	bcc	write_ok
	dbrk	$65
	_CloseGS pCloseData
               ~CloseWindow TempPtr	; close status window
	lda	#0
	sec
	rts	

write_ok	anop
	brl	nextFile


done           anop
	_CloseGS pCloseDir          ; Now that we're done, close the dir.
	errorbrk $66

* write out the header, now that we know its values
	jsr	write_header

	_CloseGS pCloseData
	errorbrk $69

	jsr	restore_prefix

               ~CloseWindow TempPtr	; close status window

	clc
	rts


************************************
write_header	ename
               lda   pOpenData_refNum	; make sure all the refNums are set..
               sta   pReadWriteData_refNum
	sta	pSetMarkData_refNum

	stzl	pSetMarkData_displacement
	_SetMarkGS pSetMarkData	; set mark to beginning of file
	errorbrk $67

	mvw	#header_size,pReadWriteData_requestCount
	stz	pReadWriteData_requestCount+2

	mvl	#header,pReadWriteData_dataBuffer

	_WriteGS pReadWriteData
	errorbrk $68
	rts

************************************
scale	ds	2

	End
*-----------------------------------------------------------------------------*
inc_mercury	Start
	debug	'inc_mercury'
	Using	FileDATA

	~GetCtlValue ThermoCtlH
	pla
	inc	a
	pha
	PushLong ThermoCtlH
	_SetCtlValue
	rts

	End
*-----------------------------------------------------------------------------*
CONVERT_DATA_TO_LIST Start
	Using	GlobalDATA
	Using	ListDATA
	Using	FileDATA
	debug	'CONVERT_DATA_TO_LIST'

	stz	num_processed

* DataH will be nonzero if we already loaded the file into memory and found
* that there was no need to rebuild it..

	lda	dataH
	ora	dataH+2
	jne	already_loaded

	jsr	set_t2save_pfx

	_OpenGS pOpenData
	bcc	found

	pha
	jsr	restore_prefix
	pla

	cmp	#fileNotFound
	jeq	REBUILD	; rebuild entered with prefix 8 set
	errorbrk $61

found	anop
	jsr	restore_prefix

	lda	pOpenData_refNum
	sta	pGetEOFData_refNum
	sta	pCloseData_refNum
	sta	pReadWriteData_refNum

	_GetEOFGS pGetEOFData
	errorbrk

               LongResult
               PushLong pGetEOFData_eof
               lda   MyID
               ora   #pathBuffAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               bcc   allocOK
               plx
               plx
	_CloseGS pCloseData
               lda   #T2CantGetMemory_LText
               ldx   #^T2CantGetMemory_LText
               jsr   cantOpen
	sec
               rts

allocOK	anop
	makeDP
               ldy   #2                 ; Dereference it
               lda   <3
               sta   dataH
               lda   <5
               sta   dataH+2
               lda   [3]
	sta	pReadWriteData_dataBuffer
               lda   [3],y
	sta	pReadWriteData_dataBuffer+2
	killLdp

	mvl	pGetEOFData_eof,pReadWriteData_requestCount

	_ReadGS pReadWriteData
	errorbrk
	_CloseGS pCloseData
	errorbrk

already_loaded	anop
	PushLong pReadWriteData_dataBuffer ; push ptr to T2.data
	makeDP
	ldy	#odata_num_modules
	lda	[3],y
; down below!	inc	a	; background fader
; not here!!	inc	a	; foreground fader
	sta	NumModules
	ldy	#odata_num_support_setup
	lda	[3],y
	sta	NumSupportSetup
	pld		; leave ptr on stack

	LongResult
	LongResult	; for multiply
	lda	NumModules
	inc	a	; bkg fader
	inc	a	; fg fader
	pha
	PushWord #ListMemberSize
	_Multiply
               lda   MyID
               ora   #listMemAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               bcc   lMemOk
               pla
               pla
	plx
	plx
	~DisposeHandle dataH
	stzl	dataH
               lda   #T2CantGetMemory_LText
               ldx   #^T2CantGetMemory_LText
               jsr   cantOpen
               rts
lMemOk         makeDP
               lda   <3                 ;First get the handle from the stack and
               sta   ListMem            ;store it into ListMem
               lda   <5
               sta   ListMem+2
               ldy   #2                 ; then, load the pointer and store it
               lda   [3]                ; into both ListPtr and the stack
               sta   ListPtr
               tax
               lda   [3],y
               sta   ListPtr+2
               sta   <5
               stx   <3                 ; leave pointer on the stack!!!

* pointer to t2.data is now at dp 7 and 9!

               stz   ListOff            ; Zero listOff
	mvw	#odata_moduleFName,dataOffset

;	brk	$55

* check for an empty data file (e.g. no modules installed, so NumModules will
* be 0 (later it will be 2 because of bkg/fg faders))

	lda	NumModules
	jeq	end_of_data

nextFile	anop
	debug 'nextFile'

	lda	<7
	clc
	adc	dataOffset	; offset to module filename
	sta	fname_fill
	lda	<9
	sta	fname_fill+2

	mvl	ModulePath,mpath_fill

	lda	MyID
               ora   #pathMemAuxID
	sta	concatId

	PushWord #reqConcatenate
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong #concatDataIn   ; dataIn
               PushLong #concatDataOut	; dataOut
               _SendRequest

	PushLong concatH
	jsr	makePdp
	pld
	PullLong concatP


	lda	dataOffset
	sec
	sbc	#odata_moduleFName-odata_moduleFlags
	sta	dataOffset	; go back to module flags offset

	ldy	dataOffset
	lda	[7],y	; get oMV_version
	and	#$FF
	cmp	#1
	beq	good_version
bad_version    anop
	~DisposeHandle concatH
	errorbrk
	brl	nextFile

good_version	anop
	debug 'good_vers'
	lda	dataOffset
	clc
	adc	#oMF_flags
	tay
	lda	[7],y
	sta	T2ModuleFlags

	LongResult
	PushWord #0
	lda	dataOffset
	clc
	adc	#oMF_module_name
	tay
	lda	[7],y	; get length byte
	and	#$FF
	inc	a	; plus one for length of whole pstr
	pha
               lda   MyID               ; (current resource app) to ours.
               ora   #modNameAuxID
               pha
	PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	lda	1,s
	sta	StringH
	lda	1+2,s
	sta	StringH+2
	jsr	makePdp
	pld
	PullLong StringP

	lda	<7
	clc
	adc	dataOffset
	adc	#oMF_module_name
	tax
	lda	<7+2
	adc	#0
	pha
	phx
	PushLong StringH
	PushWord #0
	lda	dataOffset
	clc
	adc	#oMF_module_name
	tay
	lda	[7],y	; get length byte
	and	#$FF
	inc	a	; plus one for length of whole pstr
	pha
	_PtrToHand

	stz	dispFlags



	lda	#T2Version+1
	and	#$7FFF
	pha

	lda	dataOffset
	clc
	adc	#oMF_min_ver
	tay
	lda	[7],y
	and	#$7FFF
	cmp	1,s	
	blt	make_visible	
	mvw	#$60,dispFlags	; disabled AND inactive (bits 5+6)


;	lda	dataOffset
;	clc
;	adc	#oMF_min_ver
;	tay
;	lda	[7],y
;	and	#$7FFF
;	cmp	#T2Version+1
;	blt	make_visible	
;	mvw	#$60,dispFlags	; disabled AND inactive (bits 5+6)

make_visible	anop
;	debug 'make_vis'
	plx

               ldy   ListOff            ;then move the info into the list
               lda   StringP            ;record. It's set up something like
               sta   [3],y              ;this:
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   StringP+2	; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   dispFlags	;#0
               sta   [3],y              ; flags
               iny
               longm
               lda   StringH
               sta   [3],y              ; string handle (lo)
               iny
               iny
               lda   StringH+2
               sta   [3],y              ; string handle (hi)
               iny
               iny
	lda	concatH	; path handle (lo)
               sta   [3],y
               iny
               iny
	lda	concatH+2	; path handle (hi)
               sta   [3],y
               iny
               iny
;               lda   T2ModuleFlags      ; T2 Module Flags
;               bit   #fSetup	; does it support setup?
;               beq   noImportance       ; no.
;	ldx	dispFlags
;	cpx	#$60	; disabled AND inactive (bits 5+6)
;	beq	noImportance
;               inc   NumSupportSetup    ; yes, so inc the setup count.

	phy
	lda	dataOffset
	clc
	adc	#oMF_flags
	tay
	lda	[7],y
	ply

noImportance   sta   [3],y
               iny
               iny
               sty   ListOff            ;store the offset into the list record

	lda	dataOffset	; at module flags offset right now
	clc
	adc	#odata_end-odata_moduleFlags ; add length of flags+fname
	adc	#odata_moduleFName-odata_dirInfo ; add length of dir+flags
	sta	dataOffset	; now at next module's filename

               inc   num_processed         ;Now increment the number of files and
               lda   num_processed         ;make sure we haven't done too many
               cmp   NumModules       ;if not, try to do another
               jlt   nextFile

end_of_data	name
	_CloseGS pCloseDir          ; Now that we're done, close the dir.
;                                       ; this dp is the active one from before
               ldy   ListOff
               lda   #BkgFadeStr
               sta   [3],y
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   #^BkgFadeStr       ; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   #0
               sta   [3],y              ; flags
               iny
               longm
               lda   #0
               sta   [3],y              ; string handle (lo)
               iny
               iny
               sta   [3],y              ; string handle (hi)
               iny
               iny
	phy

               LongResult
	PushLong #BkgFadeWStrLen
               lda   MyID
               ora   #pathMemAuxID
               pha
               PushWord #attrNoCross+attrNoSpec+attrLocked
               phd
               phd
               _NewHandle
               PullLong PathHandle

               PushLong #BkgFadeWStr    ; ptr to start of bytes to be copied
               PushLong PathHandle      ; handle to copy them to
               PushLong #BkgFadeWStrLen ; size
               _PtrToHand

	ply
	lda	PathHandle
               sta   [3],y              ; path handle (lo)
               iny
               iny
	lda	PathHandle+2
               sta   [3],y              ; path handle (hi)
               iny
               iny
	lda	#fInternal+fBackground+fFadeIn+fFadeOut
	sta   [3],y
               iny
               iny

               lda   #FrgFadeStr
               sta   [3],y
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   #^FrgFadeStr       ; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   #0
               sta   [3],y              ; flags
               iny
               longm
               lda   #0
               sta   [3],y              ; string handle (lo)
               iny
               iny
               sta   [3],y              ; string handle (hi)
               iny
               iny
	phy

               LongResult
	PushLong #FrgFadeWStrLen
               lda   MyID
               ora   #pathMemAuxID
               pha
               PushWord #attrNoCross+attrNoSpec+attrLocked
               phd
               phd
               _NewHandle
               PullLong PathHandle

               PushLong #FrgFadeWStr    ; ptr to start of bytes to be copied
               PushLong PathHandle      ; handle to copy them to
               PushLong #FrgFadeWStrLen ; size
               _PtrToHand

	ply
	lda	PathHandle
               sta   [3],y              ; path handle (lo)
               iny
               iny
	lda	PathHandle+2
               sta   [3],y              ; path handle (hi)
               iny
               iny
	lda	#fInternal+fForeground+fFadeIn+fFadeOut
	sta   [3],y
               iny
               iny
	sty	ListOff

	inc	NumModules	; bkg and fg faders
	inc	NumModules

	ply
	ply		; yank off listptr and t2.data ptr
               killLdp                  ; we got the list mem. The extra space
;                                       ; is the pointer to the list mem.
	~DisposeHandle dataH	; get rid of handle to t2.data
	rts


num_processed	ds	2	; number of modules done so far

	End
*-----------------------------------------------------------------------------*
MAKE_LIST_OLD_WAY Start
	debug	'MAKE_LIST_OLD'
	Using	FileDATA
	Using	ListDATA
	Using	GlobalDATA

* (only if not enough room for data file, or boot volume is locked ?)

* init the amount of memory we will initially request to hold the structure
* for the available module list..

	mvw	#startListMem,max_modules ; start with 10!

* Get a handle that has enough room for MAX_FILES list entries.

	LongResult
*	~Multiply max_modules,#ListMemberSize
	PushLong #startListMem*ListMemberSize
               lda   MyID
               ora   #listMemAuxID
               pha
               PushWord #attrLocked+attrNoCross+attrNoSpec
               phd
               phd
               _NewHandle
               bcc   lMemOk
               pla
               pla
               lda   #T2CantGetMemory_LText
               ldx   #^T2CantGetMemory_LText
               jsr   cantOpen
	sec
               rts
lMemOk         makeDP
               lda   <3                 ;First get the handle from the stack and
               sta   ListMem            ;store it into ListMem
               lda   <5
               sta   ListMem+2
               ldy   #2                 ; then, load the pointer and store it
               lda   [3]                ; into both ListPtr and the stack
               sta   ListPtr
               tax
               lda   [3],y
               sta   ListPtr+2
               sta   <5
               stx   <3                 ; leave pointer on the stack!!!

               stz   ListOff            ; Zero some variables
               stz   NumModules
               stz   NumSupportSetup

               _OpenGS pOpenT2Dir            ; Try to open the Twilight directory
               bcc   openOk
               killLdp                  ; if not, kill the DP we made up above
               lda   #T2CantDoFileStuff_LText ; and put the file error in the
               ldx   #^T2CantDoFileStuff_LText ; window
               jsr   cantOpen
               rts

openOk         anop
               lda   pOpenT2Dir_refNum
               sta   pCloseDir_refNum
               sta   pEntry_refNum

nextFile       _GetDirEntryGS pEntry    ;Now get the name of the next file
               bcc   dirOk              ;in the Twilight folder. If we're
               cmp   #endOfDir          ;at the end then goto done. Otherwise
               jeq   done               ;check to see if there was an error
               _CloseGS pCloseDir
               killLdp                  ; kill dp from above (@~lmemok)
               lda   #T2CantDoFileStuff_LText ; other than EOF. If so,
               ldx   #^T2CantDoFileStuff_LText ; than we're screwed
               jsr   cantOpen
               rts

dirOk          lda   pEntry_filetype    ;see if the file was a Twilight module
               cmp   #$BC               ;if not, then this one doesn't count
               bne   nextFile           ;--go find the next one
               lda   pEntry_auxType
               cmp   #$4004
               bne   nextFile
               lda   pEntry_auxType+2
;	cmp   #$0000
               bne   nextFile

	lda	MyID
               ora   #pathMemAuxID
	sta	concatId

	mvl	ModulePath,mpath_fill
	mvl	#FileName_textLen,fname_fill

	PushWord #reqConcatenate
	PushWord #stopAfterOne+sendToUserID
               ldy   #$0000
               phy                      ; target (hi)
               lda   MyID
               ora   #requestAuxID
               pha                      ; target (lo)
               PushLong #concatDataIn   ; dataIn
               PushLong #concatDataOut	; dataOut
               _SendRequest

	PushLong concatH
	jsr	makePdp
	pld
	PullLong concatP

;	                   ; Open the file whose name we just
               WordResult               ; concattenated
               PushWord #readEnable     ; file access
               lda   #$0000
               pha
               pha                      ; pointer to resource map in memory
	PushLong concatP	; pointer to C1 pathname of rez file
               _OpenResourceFile
	bcc	no_err
	dbrk	$eb
no_err         PullWord RezID

               ~LoadResource #rT2ModuleFlags,#1 ; get module flags resource,
	bcc	flagThere
	PushWord #$1000
	PushLong #1
	_LoadResource
	bcc	flagThere
	plx
	plx
	~DisposeHandle concatH
               ~CloseResourceFile RezID ; and close the file
	errorbrk $11
	brl	nextFile
flagThere	lda	1,s
	sta	hFill0+1
	lda	1+2,s
	sta	hFill2+1
	jsr	makePdp

	LongResult
hFill2	pea	0
hFill0	pea	0
	_GetHandleSize
	pla
	plx
	cmp	#2
	beq	bad_version

;	ldy	#oMV_version
	lda	[3]
	and	#$FF
	cmp	#1
	beq	good_version
bad_version	killLdp
	~DisposeHandle concatH
;	~ReleaseResource #3,#rT2ModuleFlags,#1
               ~CloseResourceFile RezID ; and close the file
	errorbrk
	brl	nextFile

good_version	anop
	ldy	#oMF_flags
	lda	[3],y
	sta	T2ModuleFlags

	LongResult
	PushWord #0
	ldy	#oMF_module_name
	lda	[3],y	; get length byte
	and	#$FF
	inc	a	; plus one for length of whole pstr
	pha
               lda   MyID               ; (current resource app) to ours.
               ora   #modNameAuxID
               pha
	PushWord #attrLocked+attrNoCross+attrNoSpec
	phd
	phd
	_NewHandle
	lda	1,s
	sta	StringH
	lda	1+2,s
	sta	StringH+2
	jsr	makePdp
	pld
	PullLong StringP

	lda	<3
	clc
	adc	#oMF_module_name
	tax
	lda	<3+2
	adc	#0
	pha
	phx
	PushLong StringH
	PushWord #0
	ldy	#oMF_module_name
	lda	[3],y	; get length byte
	and	#$FF
	inc	a	; plus one for length of whole pstr
	pha
	_PtrToHand

	stz	dispFlags

	ldy	#oMF_min_ver
	lda	[3],y
	and	#$7FFF
	cmp	#T2Version+1
	blt	make_visible	
	mvw	#$60,dispFlags	; disabled AND inactive (bits 5+6)

make_visible	anop

	killLdp

;	~ReleaseResource #3,#rT2ModuleFlags,#1
               ~CloseResourceFile RezID ; and close the file
	errorbrk

               ldy   ListOff            ;then move the info into the list
               lda   StringP          ;record. It's set up something like
               sta   [3],y              ;this:
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   StringP+2	; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   dispFlags	;#0
               sta   [3],y              ; flags
               iny
               longm
               lda   StringH
               sta   [3],y              ; string handle (lo)
               iny
               iny
               lda   StringH+2
               sta   [3],y              ; string handle (hi)
               iny
               iny
	lda	concatH	; path handle (lo)
               sta   [3],y
               iny
               iny
	lda	concatH+2	; path handle (hi)
               sta   [3],y
               iny
               iny
               lda   T2ModuleFlags      ; T2 Module Flags
               bit   #fSetup	; does it support setup?
               beq   noImportance       ; no.
	ldx	dispFlags
	cpx	#$60	; disabled AND inactive (bits 5+6)
	beq	noImportance
               inc   NumSupportSetup    ; yes, so inc the setup count.
noImportance   sta   [3],y
               iny
               iny
               sty   ListOff            ;store the offset into the list record

               inc   NumModules         ;Now increment the number of files and
               lda   NumModules         ;make sure we haven't done too many
               cmp   max_modules        ;if not, try to do another
               jlt   nextFile

	lda	max_modules
	clc
	adc	#10
	sta	max_modules

	~HUnlock ListMem

	~Multiply max_modules,#ListMemberSize
	PushLong ListMem
	_SetHandleSize
	bcs	done

	lda	ListMem+2
	ldx	ListMem
	pha
	phx
	pha
	phx
	_HLock
	jsr	makePdp
	pld
	pla
	sta	ListPtr
	sta	<3
	pla
	sta	ListPtr+2
	sta	<5
	brl	nextFile

done           _CloseGS pCloseDir          ; Now that we're done, close the dir.
;                                       ; this dp is the active one from before
               ldy   ListOff
               lda   #BkgFadeStr
               sta   [3],y
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   #^BkgFadeStr       ; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   #0
               sta   [3],y              ; flags
               iny
               longm
               lda   #0
               sta   [3],y              ; string handle (lo)
               iny
               iny
               sta   [3],y              ; string handle (hi)
               iny
               iny
	phy

               LongResult
	PushLong #BkgFadeWStrLen
               lda   MyID
               ora   #pathMemAuxID
               pha
               PushWord #attrNoCross+attrNoSpec+attrLocked
               phd
               phd
               _NewHandle
               PullLong PathHandle

               PushLong #BkgFadeWStr    ; ptr to start of bytes to be copied
               PushLong PathHandle      ; handle to copy them to
               PushLong #BkgFadeWStrLen ; size
               _PtrToHand

	ply
	lda	PathHandle
               sta   [3],y              ; path handle (lo)
               iny
               iny
	lda	PathHandle+2
               sta   [3],y              ; path handle (hi)
               iny
               iny
	lda	#fInternal+fBackground+fFadeIn+fFadeOut
	sta   [3],y
               iny
               iny

               lda   #FrgFadeStr
               sta   [3],y
               iny
               iny                      ; String Ptr    (long) +00 / +15
               lda   #^FrgFadeStr       ; Flags         (byte) +04 / +19
               sta   [3],y              ; String Handle (long) +05 / +20
               iny                      ; Path Handle   (long) +09 / +24
               iny                      ; T2 Mdl Flags  (word) +13 / +28
               shortm
               lda   #0
               sta   [3],y              ; flags
               iny
               longm
               lda   #0
               sta   [3],y              ; string handle (lo)
               iny
               iny
               sta   [3],y              ; string handle (hi)
               iny
               iny
	phy

               LongResult
	PushLong #FrgFadeWStrLen
               lda   MyID
               ora   #pathMemAuxID
               pha
               PushWord #attrNoCross+attrNoSpec+attrLocked
               phd
               phd
               _NewHandle
               PullLong PathHandle

               PushLong #FrgFadeWStr    ; ptr to start of bytes to be copied
               PushLong PathHandle      ; handle to copy them to
               PushLong #FrgFadeWStrLen ; size
               _PtrToHand

	ply
	lda	PathHandle
               sta   [3],y              ; path handle (lo)
               iny
               iny
	lda	PathHandle+2
               sta   [3],y              ; path handle (hi)
               iny
               iny
	lda	#fInternal+fForeground+fFadeIn+fFadeOut
	sta   [3],y
               iny
               iny
	sty	ListOff

	inc	NumModules
	inc	NumModules

               killLdp                  ; we got the list mem. The extra space
;                                       ; is the pointer to the list mem.
	rts

	End
*-----------------------------------------------------------------------------*
* GetPathHandle.  V1.00 - 12/08/91 (92??) by JRM.
*
* Get the pathname handle of the active list member.  Put it in PathHandle.
*
* No inputs or outputs (on the stack.)
* Output Accumulator = T2 module flags word.

GetPathHandle  Start
               Using GlobalDATA
               Using ListDATA
               debug 'GetPathHandle'

               ~NextMember2 MemNum,ListHandle ; Get the active member in the list
               pla
	sta	MemNum
	bne	notAtEnd
	sec		; nothing selected
	rts
notAtEnd	LongResult
               dec   a                  ; make it into an offset
               pha
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #9                 ; get path handle offset
               tay
               PushLong ListPtr
               makeDP
               lda   [3],y
               sta   PathHandle
               iny
               iny
               lda   [3],y
               sta   PathHandle+2
	iny
	iny
	lda	[3],y	; get T2 module flags word
               killLdp
               clc                      ; no errors!
               rts

               End
*-----------------------------------------------------------------------------*
* GetNextChecked.  V1.00 - 1 Jan 94 by JRM.
*
* Return the pathhandle of the next checked module in the list.
*
* Input: A - list member offset to start search (base 1)
* Output: A - new list member offset (base 1)
*         PathHandle - duh
*         carry - set if nothing was found to be checked

GetNextChecked	Start
               Using	GlobalDATA
               Using ListDATA
               debug 'GetNextChecked'

	sta	our_position

keep_looking	anop
	LongResult
	lda	our_position
;	dec	a
               pha
	inc	our_position	; bump it over for next time
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #13	; modl flags offset
               tay

               PushLong ListPtr
               makeDP
	lda	[3],y
	bit	#fChecked
	beq	not_checked
	dey
	dey		; now at pathhandle + 2
               lda   [3],y
               sta   PathHandle+2
	dey
	dey		; get to path handle offset
               lda   [3],y
               sta   PathHandle
               killLdp

	lda	our_position
;	inc	a
               clc                      ; no errors!
               rts

not_checked	anop
	killLdp

;	inc	our_position
	lda	our_position	; base zero
	inc	a	; make it base 1
	cmp	NumModules
	blt	keep_looking

	lda	#0
	sec
	rts

our_position	ds	2	; base 1 list item offset

               End
*-----------------------------------------------------------------------------*
; This routine draws a list member if any part of the member's
; rectangle is inside the current clipRgn.
T2ListDraw	Start
	debug	'T2ListDraw'

top        	equ   0
left       	equ   top+2
bottom     	equ   left+2
right      	equ   bottom+2
rgnBounds  	equ   2

oldB	equ	1
oldDPage   	equ   oldB+1
theRTL     	equ   oldDPage+2
listHand   	equ   theRTL+3
memPtr     	equ   listHand+4
theRect    	equ	memPtr+4

           	phd
	phb
	phk
	plb
           	tsc
           	tcd

;	brk	$55

           	~GetClipHandle
           	PullLong listHand

           	ldy    #2
           	lda    [listhand],y
           	tax
           	lda    [listhand]
           	sta    listhand
           	stx    listhand+2

           	lda   [therect]	; now test the top
           	dec   a	; adjust and give a little slack
           	ldy   #rgnbounds+bottom
           	cmp   [listhand],y       ; rgnRectBottom>=top?
           	blt   skip2
           	brl   NoDraw             ; if not don't draw..
Skip2      	ldy   #bottom     ; now see if the bottom is higher than the top
           	inc   a                 ; give a little slack
           	lda   [therect],y
           	ldy   #rgnBounds+top
           	cmp   [listhand],y
           	jlt   NoDraw
NoTest	anop

           	~EraseRect theRect	; erase the old rectangle

	~GetTextFace

	ldy	#13
	lda	[memptr],y	; oT2ModuleFlags
	pha
	bit	#fInternal
	beq	notInternal
	bit	#fBackground
	beq	foreground

;	~SetTextFace #%110	; underline, italic
	~SetTextFace #%10	; italic
	bra	notInternal

foreground	~SetTextFace #%10	; italic

notInternal	ldy   #left
           	lda   [theRect],y
	clc
	adc	#8	; (min 2)
           	tax
           	ldy   #bottom
           	lda   [theRect],y
           	dec   a
	dec	a
           	phx
           	pha
           	_MoveTo

	~GetCharExtra

           	ldy   #2
           	lda   [memptr],y
           	pha
           	lda   [memptr]
           	pha
	PushLong #rect
	_StringBounds

	lda	rect_right
	sec
	sbc	rect_left
	pha

	ldy	#right
	lda	[theRect],y
	ldy	#left
	sec
	sbc	[theRect],y
	clc
	adc	#8	; everything is pushed over by 8
	cmp	1,s
	bge	will_fit

	~Long2Fix #-1
	_SetCharExtra

will_fit	anop
	pla

           	ldy   #2
           	lda   [memptr],y
           	pha
           	lda   [memptr]
           	pha
           	_DrawString

	_SetCharExtra	; restore original

	lda	1,s
	bit	#fChecked
	beq	notChecked

	jsr	checkItem

notChecked	anop
	pla
	bit	#fInternal
	beq	not_bkg	; FIX!!!!
	bit	#fBackground
	beq	not_bkg	; FIX!!!!

           	ldy   #2
           	lda   [memptr],y
           	pha
           	lda   [memptr]
           	pha
               PushLong #rect
               _StringBounds

	~GetPenSize #point
	~SetPenSize #1,#1

           	ldy   #bottom
           	lda   [theRect],y
	tax
	dex
	dex
	ldy   #left
           	lda   [theRect],y
;	inc	a
;	inc	a
	clc
	adc	#8	; (min 2)
	pha
	phx
           	pha
           	phx
           	_MoveTo

	lda	rect_right
	sec
	sbc	rect_left
	clc
	adc	3,s
	sta	3,s

;	lda	1,s	; fix it?????????????
;	clc
;	adc	rect_right
;	sta	1,s
	_LineTo
	
	~SetPenSize point_y,point_x

not_bkg	anop

	_SetTextFace

           	ldy   #4
           	lda   [memPtr],y
           	and   #$00C0         	; strip to the 6 and 7 bits
           	beq   memDrawn       	; if they are both 0 the member is drawn
           	cmp   #$0080         	; member selected?
           	bne	noSelect	; member not selectable
           	~InvertRect theRect
           	bra    memDrawn

; if we get here the member is disabled

noSelect	~SetPenMask #DimMask
           	~EraseRect theRect
           	~SetPenMask #NorMask
memDrawn	anop

NoDraw	anop		; NEU!

; exit here

	plb
           	pld
	shortm
           	pla
           	ply

           	plx
           	plx
           	plx
           	plx
           	plx
           	plx
           	phy
           	pha
	longm
           	rtl


checkItem	anop
           	ldy   #bottom
           	lda   [theRect],y
;	dec	a
	sec
	sbc	#4
	sta	rect_bottom
;	sec
;	sbc	#8
	dec	a
	dec	a
	dec	a
	sta	rect_top

	ldy   #left
           	lda   [theRect],y
	inc	a
	inc	a
	sta	rect_left
	clc
	adc	#5
	sta	rect_right

	~FillRect #rect,#patt
	rts

DimMask    	dc    i1'$55,$AA,$55,$AA,$55,$AA,$55,$AA'
NorMask    	dc    i1'$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF'

rect	QDRect
point	QDPoint

patt	dc	32h'44'

	End
*-----------------------------------------------------------------------------*
ListDATA       Data
               debug 'ListDATA'

MemNum	ds	2
NameID	ds	4

ListHandle     handle                   ;Handle to list control
ListMem        handle                   ;Handle to list records' memory
StringP	ptr   0                  ;Pointer to the PString
StringH	handle                   ;Handle to the current PString's memory

T2ModuleFlags  ds    2                  ; T2 module flags of current module
NumSupportSetup ds   2                  ; number of modules supporting setup

ListItemNumber ds    2                  ; for selecting the active module
ListOff        ds    2                  ; current offset into list record mem

NumModules     ds    2                  ; number of modules in the T2 directory
ListPtr        ptr   0                  ; Pointer to list records' memory

BkgFadeStr	str	'Background Fader'
FrgFadeStr	str	'Foreground Fader'

BkgFadeWStr	GSStr	'Background Fader'
bkg_end	anop
BkgFadeWStrLen	equ	bkg_end-BkgFadeWStr

FrgFadeWStr	GSStr	'Foreground Fader'
frg_end	anop
FrgFadeWStrLen	equ	frg_end-FrgFadeWStr

               End
*-----------------------------------------------------------------------------*
toggle_saved_modules Start
	Using	GlobalDATA
	Using	ListDATA
	debug	'toggl_sv_mdl'

* Select the first item in the list...  It might be changed later..

               ~SelectMember2 #1,ListHandle

* Load in the w-string pathname of the first currently selected module and
* temporarily turn it into a P-String for ConvertStrings..

	~LoadResource #rT2String,#1
	bcc	countFound
	plx
	plx
;	mvw	#1,NameID

* don't toggle anything, but select the first item in the list
* if nothing is toggled by the time the CDev is closed, frg fader will be
* automatically toggled and saved to disk.

;               ~SelectMember2 #1,ListHandle	; selected already above.. /\
	rts

;	bra	selectLoop

countFound	jsr	makePdp
	lda	[3]
	killLdp
	sta	NameID

	~ReleaseResource #3,#rT2String,#1

               stz	NameID+2
selectLoop	anop
	jsr	selectMember

	inc	NameID+2
	lda	NameID+2
	cmp	NameID
	blt	selectLoop
	rts



selectMember	name

	LongResult
	PushWord #rT2String
	PushWord #0
	lda	NameID+2
	inc	a	; filename strs start at id 2
	inc	a
	pha
	_LoadResource

* load in the module's path
;	~RMLoadNamedResource #rWString,#Module_Path
;	~LoadResource #rT2String,#2
	pla
	sta	TempHandle
	pla
	sta	TempHandle+2
	bcs	frg
	ora	TempHandle
	bne	validHandle

;	brk	$20
;	jsr	dimBlankNow
	bra	frg

validHandle	anop
               stz   ListItemNumber     ; init item number counter

	PushLong TempHandle
	jsr	makePdp
	ldy	#2
	lda	[3],y
	killLdp
	cmp	BkgFadeWStr+2
	beq	bkg
	cmp	FrgFadeWStr+2
	jne	external
;	beq	frg
;	dbrk	$10
frg	anop

	PushLong ListPtr
	makeDP
	ldy	#13	; oT2ModuleFlags
search1	lda	[3],y
	bit	#fInternal
	beq	notInternal1
	bit	#fBackground
	bne	notInternal1

* internal module, so dim the about control (v1.0d38)
	jsr	DimAbout
	brl	FOUNDIT

notInternal1	anop
	inc	ListItemNumber
	tya
	clc
	adc	#15
	tay
	bra	search1

bkg	anop

	PushLong ListPtr
	makeDP
	ldy	#13	; oT2ModuleFlags
search2	lda	[3],y
	bit	#fInternal
	beq	notInternal2
	bit	#fBackground
	beq	notInternal2
	jsr	DimAbout	;BlankNow
	brl	FOUNDIT
notInternal2	anop
	inc	ListItemNumber
	tya
	clc
	adc	#15
	tay
	bra	search2
	
external	anop
;	killLdp

               PushLong ListPtr
               makeDP
               ldy   #9                 ; Path Handle offset
findLoop       lda   [3],y              ; get next path handle (lo)
               tax
               stx   PathHandle
               iny
               iny
               lda   [3],y              ; get next path handle (hi)
               sta   PathHandle+2
               sty   ListOff
               WordResult               ; word - result space
               PushWord #0              ; word - flags (use 0)
               pha                      ; long - pointer to first p-string
               phx
               jsr   makePdp            ; dereference handle into pointer
               lda   [3]                ; get length WORD of path ascii
               xba                      ; swap it
               sta   [3]
               lda   3,s                ; add 1 to make it point to P-String
               inc   a
               sta   3,s
               pld                      ; stack now has ptr to P-String path 1
               PushLong TempHandle
               jsr   makePdp            ; dereference handle into pointer
               lda   [3]                ; get length WORD of saved path ascii
               xba                      ; swap it
               sta   [3]
               lda   3,s                ; add 1 to make it point to P-String
               inc   a
               sta   3,s
               pld                      ; stack now has ptr to P-String path 2
               _CompareStrings          ; compare them ! ! !

* Make current PathHandle pathname back into a W-String.

               PushLong PathHandle
               jsr   makePdp            ; dereference handle into pointer
               lda   [3]                ; get length byte+1st of path ascii
               xba                      ; swap it to make it a lenght WORD again
               sta   [3]
               lda   3,s                ; minus 1 to make it point to 00+PLength
               dec   a
               sta   3,s
               killLdp

* Convert loaded saved path resource back into a W-String.

               PushLong TempHandle
               jsr   makePdp            ; dereference handle into pointer
               lda   [3]                ; get length byte+1st of path ascii
               xba                      ; swap it to make it a lenght WORD again
               sta   [3]
               lda   3,s                ; minus 1 to make it point to 00+PLength
               dec   a
               sta   3,s
               killLdp

               pla                      ; get result of comparison
               beq   FOUNDIT
               lda   ListOff
               clc
               adc   #ListMemberSize-2  ; offset to next path handle
               tay
               inc   ListItemNumber
               lda   NumModules
               cmp   ListItemNumber
               jge   findLoop
;alreadySelecteD!stz   ListItemNumber     ; select the first in the list.
	killLdp	; don't select anything...
	bra	skipEverything
FOUNDIT        anop
               killLdp

* Select the right list item.

;               lda   ListItemNumber
;               inc   a
;               pha
;               PushLong ListHandle
;               _SelectMember2

	lda	NameID+2
	bne	not1stTime

               lda   ListItemNumber
               inc   a
               pha
               PushLong ListHandle
               _SelectMember2
	jsr	doToggle

not1stTime	anop

	LongResult
	PushWord ListItemNumber
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #13	; get modl flags offset
               tay
               PushLong ListPtr
               makeDP
	lda	[3],y	; get T2 module flags word
	ora	#fChecked
	sta	[3],y
               killLdp

;	~DrawMember2 ListItemNumber,ListHandle

               lda   ListItemNumber
               inc   a
               pha
               PushLong ListHandle
               _DrawMember2

skipEverything	anop
* Release the saved module path resource.

;	PushWord #3	; purge level 3
;	PushWord #rWString	; rtype
;	~RMFindNamedResource #rWString,#Module_Path,#tempHandle ; rID
;	_ReleaseResource

;	~ReleaseResource #3,#rT2String,#2

	PushWord #3
	PushWord #rT2String
	PushWord #0
	lda	NameID+2
	inc	a	; filename strs start at id 2
	inc	a
	pha
	_ReleaseResource
	rts

               End
*-----------------------------------------------------------------------------*
check_ForeFade	Start
	Using	ListDATA
	Using	GlobalDATA
	debug	'check_ForeFade'

noSelection	stz	ListItemNumber
	PushLong ListPtr
	makeDP
	ldy	#13	; oT2ModuleFlags
search01	lda	[3],y
	bit	#fInternal
	beq	notInternal01
	bit	#fBackground
	bne	notInternal01

* NOPE111 >>> internal module, so dim the about control (v1.0d38)
	killLdp

               lda   ListItemNumber
	LongResult
;               dec   a                  ; make it into an offset
               pha
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #13	; get modl flags offset
               tay
               PushLong ListPtr
               makeDP
	lda	[3],y	; get T2 module flags word
	ora	#fChecked
	sta	[3],y
               killLdp

	~DrawMember2 ListItemNumber,ListHandle
	rts

notInternal01	anop
	inc	ListItemNumber
	tya
	clc
	adc	#15
	tay
	bra	search01

	End
*-----------------------------------------------------------------------------*
doList         Start
               debug 'doList'
	Using	GlobalDATA
	Using	ListDATA

               ~NextMember2 #0,ListHandle ; Get the active member in the list
               pla
	bne	something_selected

	jsr	DimAbout
	jsr	DimBlankNow
	rts

something_selected anop
               LongResult
               dec   a                  ; make it into an offset
               pha
	jsr	EnableBlankNow
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
	bit	#fInternal
	bne	disable

;	lda	OptionsFlag
;	bit	#fRandomize
;	bne	skip

	jsr	EnableAbout

	lda	BkgToggled	; is bkg fader toggled?
	beq	skipIt	; no, so don't disable toggle module
	jsr	DimToggle
	rts

skipIt	jsr	EnableToggle
	rts

disable	anop
	bit	#fBackground
	beq	skip
;	brk   05
	debug	'NumTog'
	lda	NumToggled	; anything else toggled?
	beq	skip	; if not, allow bkg fader to be toggled
	debug	'bkgTog'
	lda	BkgToggled	; bkg fader ALREADY toggled?
	beq	dimTog
	jsr	EnableToggle	; if so, allow it to be untoggled
	bra	skip
dimTog	jsr	DimToggle	; else disable background fader toggle
skip	anop
	jsr	DimAbout
	rts

               End
*-----------------------------------------------------------------------------*
doToggle	Start
	Using	GlobalDATA
	Using	ListDATA
	debug	'doToggle'

	stz	list_member

toggle_next	anop
               ~NextMember2 list_member,ListHandle ; Get the active member in the list
               pla
	sta	list_member
	beq	all_done

	LongResult
	lda	list_member
               dec   a                  ; make it into an offset
               pha
               PushWord #ListMemberSize ; size of each entry
               _Multiply
               pla
               plx                      ; discard hi word of 0000
               adc   #13	; get modl flags offset
               tay
               PushLong ListPtr
               makeDP
	lda	[3],y	; get T2 module flags word
	bit	#fBackground
	beq	no_bkg

;	ldx	SomethingChecked	; if anything else is checked,
;	bne	skip_check	; then don't let bkg fader be checked

;	brk	05

	eor	#fChecked
	sta	[3],y
	bit	#fChecked
	beq	unCheck_bkg

;	jsr	DimToggle	; bkg fader was just checked
	mvw	#TRUE,BkgToggled
	bra	inc_it
unCheck_bkg	anop
	jsr	EnableToggle	; bkg fader was just unchecked
;	lda	#FALSE
	stz	BkgToggled
	bra	dec_it
	
no_bkg	eor	#fChecked
	sta	[3],y
	bit	#fChecked
	beq	dec_it

inc_it	anop
	inc	NumToggled	; something was just toggled
	bra	skip_check
dec_it	lda	NumToggled	; something was just untoggled
	beq	skip_check
	dec	NumToggled
skip_check	killLdp

	~DrawMember2 list_member,ListHandle
	brl	toggle_next

all_done	rts

list_member	ds	2

	End
*-----------------------------------------------------------------------------*
save_module_selection Start
	debug	'save_module_selection'
	Using	GlobalDATA
	Using	ListDATA

	~LoadResource #rT2String,#1	; count
	bcc	fine
	plx
	plx
	bra	allRemoved

fine	jsr	makePdp
	lda	[3]
	killLdp

	sta	NameID

alup	PushWord #rT2String
	PushWord #0
	lda	NameID	; filenames start at ID 2
	inc	a
	pha
	_RemoveResource

	dec	NameID
	bpl	alup

allRemoved	anop

	stz	NameID+2
	stz	MemNum
	mvw	#2,NameID

	lda	MemNum
               jsr   GetNextChecked      ; get pathhandle of next checked mem
	sta	MemNum
	bcc	something_checked

* this is rather a roundabout way to do it
* why not just make a routine that returns the pathhandle of foreground fader?

	jsr	check_foreFade
	stz	MemNum
	lda	MemNum
	jsr	GetNextChecked
	sta	MemNum

something_checked anop

* Change the ID of the module pathname handle to that of the CP NDA so that
* we don't dispose of it down below, as it is the RezMgr's job to do that.

               WordResult
               ~GetCurResourceApp
               PushLong PathHandle
               _SetHandleID
               pla                      ; chuck old id

	PushLong PathHandle	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2String	; rType
	PushLong NameID
	_AddResource
	inc	NameID

addNameLoop	anop
	lda	MemNum
               jsr   GetNextChecked      ; get pathhandle of next checked mem
	sta	MemNum
	bcs	AtEnd

* Change the ID of the module pathname handle to that of the CP NDA so that
* we don't dispose of it down below, as it is the RezMgr's job to do that.

               WordResult
               ~GetCurResourceApp
               PushLong PathHandle
               _SetHandleID
               pla                      ; chuck old id

	PushLong PathHandle	; handle
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2String	; rType
	PushLong NameID	; rID
	_AddResource

	inc	NameID
	bra	addNameLoop

AtEnd	anop

               LongResult
               PushLong #2
               ~GetCurResourceApp
               PushWord #attrNoSpec+attrNoCross
               phd
               phd
               _NewHandle
	lda	3,s
	pha
	lda	3,s
	pha
	jsr	makePdp
	lda	NameID
	dec	a
	dec	a
	sta	[3]
	killLdp
	PushWord #attrNoSpec+attrNoCross ; attr
	PushWord #rT2String	; rType
	PushLong #1	; rID
	_AddResource
	rts

               End
*-----------------------------------------------------------------------------*

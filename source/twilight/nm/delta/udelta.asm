*
* Asm part of delta cruncher.
* By Nathan Mates, 2/12/94
*
* Reads in file, crunches it, and writes it back to disk.
*
*

	mcopy	macros/udelta.macs

	copy	18:e16.memory
	copy	18:e16.gsos


Temp	gequ	1
LastVal	gequ	5

	case	on
*
*
DoDelta	start
*
* Does the delta compression stuff...
*
*
	case	off
	using	Globals

	phk
	phk
	plb
	lda	4+1,s
	sta	InString
	lda	6+1,s
	sta	InString+2
	phd
	pha
	pha
	pha
	tsc
	tcd
	stz	Err
	jsr	loadit
	lda	Err
	bne	Exit
	jsr	DeltaIt	;don't bother delta'ing if had error in loading
	jsr	saveit
Exit	pla
	pla
	pla
	lda	Err	;error code to be returned
	pld
	lda	1,s
	sta	5,s
	lda	3,s
	sta	7,s
	plx
	plx		;clean up off stack
	plb
	rtl
	end

*
*
Globals	data
*
* Asm globals
*
*
gReadRec	dc	i'4'	;pCount
gReadRefNum	ds	2	;input
gReadPtr	ds	4	;where to load ptr
gReadSize	ds	4	;load $8000 bytes of data
	ds	4	;how many bytes were loaded

gCloseRec	dc	i'1'	;pCount
gCloseRefNum ds	2	;refNum to close

gOpenRecGS	anop
	dc	i'12'	;pCount
gOpenRefNum	ds	2	;output
	dc	i4'CStringBuf'	;ptr to pathname
	dc	i'readwriteEnable' ;we'll need read & write access...
	dc	i'$0000'	;open data fork
	ds	2	;returned access
gOpenFileType ds	2	;returned file type
	ds	4	;returned aux
	ds	2            ;returned storage type
	ds	8	;returned create time
	ds	8	;returned mod time
	dc	i4'0'	;optionlist ptr
gOpenEOF	ds	4	;data fork's eof

Err	ds	2
InString	ds	4

CStringBuf	ds	500	;enough for most pathnames
LoadHndl	ds	4

	end


*
*
LoadIt	start
*
* Loads the picture in from disk...
*
*
	using	Globals

	stz	LoadHndl
	stz	LoadHndl+2

	mov	InString,Temp
	mov	InString+2,temp+2	;move ptr to c-string in to DP loc...

	shortm
	ldy	#0
C2OSStr	lda	[Temp],y
	sta	CStringBuf+2,y
	beq	DoneCopy
	iny
	cpy	#498
	blt	C2OSStr
DoneCopy	sty	CStringBuf
	longm

	_OpenGS gOpenRecGS
	bcs	IOErr

	lda	gOpenRefNum
	sta	gReadRefNum
	sta	gCloseRefNum

	LongResult
	lda	gOpenEOF+2
	sta      gReadSize+2
	pha
	lda	gOpenEOF
	sta      gReadSize
	pha               	;size/4
	WordResult
	_MMStartup	;get my memory ID
	PushWord	#attrNoPurge+attrLocked	;locked until we dump things in it
	PushLong	#0	;@loc
	_NewHandle
	plx
	ply
	bcs	CloseErr	;store error message & close file

            stx	LoadHndl
	sty	LoadHndl+2
	stx	Temp
	sty	Temp+2
	lda	[temp]
	tax
	ldy	#2
            lda	[temp],y
	sta	gReadPtr+2
	stx	gReadPtr

	_ReadGS	gReadRec
	bcc	CloseIt
CloseErr	sta	Err
CloseIt	_CloseGS	gCloseRec
	rts

IOErr	sta	Err
	rts
	end

*
*
DeltaIt	start
*
* Delta's the file...
*
*
	using	Globals
	mov	gReadPtr,temp	;ptr to start
	mov	gReadPtr+2,temp+2

	stz	Count
	stz	Count+2
	shortm
	lda	[temp]
	sta	LastVal
NextByte    longm
	inc	temp	;increment 32 bit address...
	bne	NextCount
	inc	temp+2	;bump high word too, it seems
NextCount	inc	Count
	bne	ChkEnd
	inc	Count+2
ChkEnd	lda      Count+2
	cmp	gReadSize+2	;how do the high words compare?
	blt      GetDelta	;don't match yet. can keep going
	lda	Count
	cmp	gReadSize
*	beq	GetDelta	;if low words =, on last byte (do it also)
	bge	Done	;low words >=, so time to quit

GetDelta	lda	#0	;clear all bits
	shortm
	lda	[temp]
	clc
	adc	LastVal	;make by knowing delta from last byte
	sta	[temp]
	sta	LastVal
	bra	NextByte

Done	longm
	rts

Count	ds	4
	end

*
*
SaveIt	start
*
* Loads the picture in from disk...
*
*
	using	Globals

	_OpenGS gOpenRecGS
	bcs	IOErr

	lda	gOpenRefNum
	sta	gReadRefNum
	sta	gCloseRefNum

	_WriteGS	gReadRec
	bcc	CloseIt
CloseErr	sta	Err
CloseIt	_CloseGS	gCloseRec
DumpHandle	PushLong	LoadHndl
	_DisposeHandle	;dump the handle we allocated
	rts

IOErr	sta	Err
	bra	DumpHandle
	end
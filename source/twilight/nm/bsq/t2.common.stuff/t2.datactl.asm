	mcopy	t2.datactl.macs
	copy	18/e16.t2
	copy	18/e16.memory

*
*
Mk1stDatactl start
*
* Makes the first (or only) Datactl; once it's made, subsequent calls can be
* made to LoadDataCtl for the others.
*
* Pass In:
*    XXXX: Lower word of resource ID for control template of DataCrl to load
*          Upper word must be 0
*    YYYY: Value to set this control to after it's made.
*
	using	Globals
	using	CommonData
T2Data1	equ	9

	stx	ResToLoadId
	sty	ResValue

	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
	LongResult
	PushWord	#rControlTemplate
	PushWord	#0	;upper word of res id #
	PushWord	ResToLoadID
	_LoadResource
	jsr	makePdp
	PushLong extraInfoPtr
	makeDP		;phd/tsc/tcd
	ldy	#2
	lda	[3],y
	sta	dfDefProc+2
	tax
	lda	[3]
	sta	dfDefProc
	pld
	ply
	ply		;keep a,x registers intact
	ldy	#$0E	; procRef
	sta	[3],y
	iny
	iny
	txa
	sta	[3],y
	pld
	_NewControl2
;	plx
;	plx
	PushWord #SetFieldValue
	PushWord ResValue
	PushWord #34	;field number - they start at 34
	_CallCtlDefProc
	plx		;always zero
	plx		;same
	rts
	end

*
*
LoadDataCtl	start
*
* Loads subsequent DataCtls into memory.
* Pass In:
*    XXXX: Lower word of resource ID for control template of DataCrl to load
*          Upper word must be 0
*    YYYY: Value to set this control to after it's made.
*
	using	Globals
	using	CommonData
T2Data1	equ	9

	stx	ResToLoadId
	sty	ResValue
	LongResult	; for CallCtlDefProc
	LongResult	; for NewControl2
	pei	<T2data1+2
	pei	<T2data1
	PushWord #singlePtr
	LongResult
	PushWord	#rControlTemplate
	PushWord	#0	;upper word of res id #
	PushWord	ResToLoadId
	_LoadResource
	jsr	makePdp
	ldy	#$0E	; procRef
	lda	dfDefProc
	sta	[3],y
	iny
	iny
	lda	dfDefProc+2
	sta	[3],y
	pld
	_NewControl2
	lda	3,s
	pha	
	lda	3,s
	pha
	_MakeThisCtlTarget
	PushWord #SetFieldValue
	PushWord ResValue
	PushWord #34	;field number - they start at 34
	_CallCtlDefProc
	plx		;always zero
	plx		;same

	rts
	end

*
*
ReadDataCtl	start
*
* Reads a DataCtl's value.
* Inputs:
*   YYYY: Low word of item ID for the DataCtl
* Outputs:
*   AAAA: Current Value of DataCtl
* Registers trashed in the process...
	using	CommonData

	LongResult
	LongResult
	PushLong WindPtr
	PushWord	#0	;upper word of DataCtl ID
	phy		;lower word
	_GetCtlHandleFromID
	PushWord #GetFieldValue
	PushWord #0	;not used for GetFieldValue
	PushWord #34	;field number - they start at 34
	_CallCtlDefProc
	pla	                	;this is the current tag
	plx		;always zero
	rts
	end